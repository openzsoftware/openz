/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.openbravo.zsoft.smartui;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.text.MessageFormat;
import java.util.Vector;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import org.apache.log4j.Logger;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.base.session.OBPropertiesProvider;

public class CopyOrderTemplateAttService implements org.openbravo.scheduling.Process {
  private static final Logger log = Logger.getLogger(CopyOrderTemplateAttService.class);

  public void execute(ProcessBundle bundle) throws Exception {

    log.debug("Starting CopyOrderTemplateAttService.java\n");
    Vector<String> v_messages = new Vector<String>();
    
    try {
      ConnectionProvider connp = bundle.getConnection();
      Connection conn = connp.getConnection();
      Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,ResultSet.CONCUR_READ_ONLY);
      try {
      //final String newKey = (String) bundle.getParams().get("value");
        final String adUserId = bundle.getContext().getUser();
        final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
        final String mTemplateID = (String) bundle.getParams().get("C_Order_ID");
        ResultSet res = null;
        String sql = null;
        String mSqlProc = null;        
        String mTargetID = "";
        String mDocIdNew = "";
        String mSqlProcMsg;
        String result;
        String mLink;
        
        mSqlProc = "c_generateorderfromtemplate";
        result = "";
        sql = "SELECT " + mSqlProc + "('" + mTemplateID +"','" + adUserId + "') as plresult from dual";
        res = stmt.executeQuery(sql);
        if (res.first()) {
          result = res.getString("plresult");
          if (result.toUpperCase().contains("SUCCESS")) { 
            String[] splitResult = result.split(" ");
            mSqlProcMsg = (splitResult.length-1 >= 1) ? splitResult[1] : "";
            mDocIdNew   = (splitResult.length-1 >= 2) ? splitResult[2] : "";          
            mTargetID   = (splitResult.length-1 >= 3) ? splitResult[3] : "";
            mLink = MessageFormat.format(
                "<a href=\"#\" onclick=\"submitCommandFormParameter(''DIRECT'',document.frmMain.inpcOrderId, ''{0}'', false, document.frmMain, ''../SalesOrder/Header_Relation.html'', null, false, true);return false;\" class=\"LabelLink\">{1}</a>",
                mTargetID, mDocIdNew); 
            v_messages.add(mSqlProcMsg + " " + mLink); // "@GenerateOrderFromTemplate@", "50..."
          } else {
            v_messages.add(result);
          }
        }
        else {
          result = "@zsse_DataNotExists@" + " " + mTemplateID;
          v_messages.add(result);
        }

        if (!result.toUpperCase().contains("SUCCESS")) {
          throw new Exception (MessageFormat.format("{0}: {1}.","@SQLErrorExcecution@", result));
        }
        log.debug(" SQL-Procedure "+ mSqlProc + " finished with:  " + result + "\n");
        
        // copy all attached files depending on order-template
        sql = "SELECT ad_client_id, ad_org_id, isactive, name, c_datatype_id, seqno, text, ad_table_id FROM c_file WHERE ad_record_id='" + mTemplateID + "'";
        res = stmt.executeQuery(sql);
        while (res.next()) {
          final File fromDir = new File(fileDir + "/" + res.getString("AD_TABLE_ID") + "-" + mTemplateID);
          final File toDir = new File(fileDir + "/" + res.getString("AD_TABLE_ID") + "-" + mTargetID);
          if (!toDir.exists())
            toDir.mkdirs();
          final File inputFile = new File(fromDir, res.getString("NAME"));
          final File outputFile = new File(toDir, res.getString("NAME"));
          FileInputStream in = new FileInputStream(inputFile);
          FileOutputStream out = new FileOutputStream(outputFile);
          byte[] buf = new byte[1024];
          int len;
          while ((len = in.read(buf)) >= 0)
            out.write(buf, 0, len);
          in.close();
          out.flush();
          out.close();
        }
        log.debug("Copy files on directory system finished\n");

        // insert all attached files depending on order-template
        mSqlProc = "zsse_CopyAttachmentFile";
        result = "";
        mSqlProcMsg = "";
        String mSqlCount = "";
        sql = "SELECT " + mSqlProc + "('" + mTemplateID + "','" + mTargetID  + "','" + adUserId + "') as plresult from dual";
        res = stmt.executeQuery(sql);
        if (res.first()) {
          result = res.getString("plresult");
          String[] splitResult = result.split(" ");
          if (result.toUpperCase().contains("SUCCESS")) { 
            mSqlProcMsg = (splitResult.length-1 >= 1) ? splitResult[1] : ""; // @800020@
            mSqlCount = (splitResult.length-1 >= 2) ? splitResult[2] : "";   // count records copied 
            v_messages.add(mSqlProcMsg + " " + mSqlCount);
          } else { 
            v_messages.add(result);
          } 
        }
        else {
          result = "@zsse_DataNotExists@" + " " + mTemplateID;
          v_messages.add(result);
        }
        if (!result.toUpperCase().contains("SUCCESS")) {
          throw new Exception (MessageFormat.format("{0}: {1}.","@SQLErrorExcecution@", result));
        }
        log.debug("executeQuery" + mSqlProc + " finished\n");
  
       // user-message-handling 
        final OBError msg = new OBError();
          if (v_messages.toString().toUpperCase().contains("ERROR")) {
          msg.setType("Error");
          msg.setTitle("@ProcessRunError@");
        } else {
          msg.setTitle("@zsse_SuccessfullCopyOrderTemplate@");
          msg.setType("Success");
        }
        String xmlString = ""; 
        String xmlBracket = "";
        for (String mess : v_messages) {
          xmlBracket = (xmlString.length() == 0) ? "" : "</br>"; // @800020@
          xmlString = xmlString + xmlBracket + mess;
        } 
        msg.setMessage(xmlString);
        bundle.setResult(msg);
      } finally {
        conn.close();
      }      
      
    } catch (final Exception e) {
      log.error(e.getMessage(), e);
      final OBError msg = new OBError();
      msg.setType("Error");
      msg.setMessage(e.getMessage());
      msg.setTitle("@ProcessRunError@");
      bundle.setResult(msg);
    }

  }

}