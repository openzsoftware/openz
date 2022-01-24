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
package org.openbravo.zsoft.manufac;


import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import org.apache.log4j.Logger;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.base.session.OBPropertiesProvider;



public class CopyProductWithAttService implements org.openbravo.scheduling.Process {
  private static final Logger log = Logger.getLogger(CopyProductWithAttService.class);

  public void execute(ProcessBundle bundle) throws Exception {

 

    log.debug("Starting CopyProductWithAttService.\n");
    try {
      // For Background process execution at system level
     
       
      final String newName = (String) bundle.getParams().get("name");
      final String newKey = (String) bundle.getParams().get("value");
      String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
      final String mProductID = (String) bundle.getParams().get("M_Product_ID");
      String adUserId=bundle.getContext().getUser();
      String result="";
      String uid="";
      String link="";  
      // Get Product-ID 
      ConnectionProvider connp = bundle.getConnection();
      Connection conn = connp.getConnection();
      Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,ResultSet.CONCUR_READ_ONLY);
      String sql = "select get_uuid() as plresult from dual";
      ResultSet res = stmt.executeQuery(sql);
      if (res.first())
        uid = res.getString("plresult");
      sql = "select zsmf_copyproduct('" + mProductID + "','"
                 + newKey + "','" + newName.replace("'", "''") +"','" + adUserId + "','" + uid + "') as plresult from dual";
      res = stmt.executeQuery(sql);
      if (res.first())
        result = res.getString("plresult");
      else
        result = "@zsse_DataNotExists@";
      
      // Throw if SQL not OK
      if (!result.startsWith("SUCCESS"))
        throw new Exception ("@SQLErrorExcecution@: " + result); // Runtime error in SQL-Procedure
      
      if ( (result.indexOf("<a href") > 0) && (result.indexOf("</a>") > 0) )  {
        link = "</br>" + result.substring(result.indexOf("<a href"), result.indexOf("</a>")+4);  
      }
      
      log.debug(" Copy Product-SQL-Procedure finished with:  " + result + "\n");
      sql = "SELECT  AD_CLIENT_ID,  AD_ORG_ID, ISACTIVE, NAME, C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID from c_file where AD_RECORD_ID='" + mProductID + "'";
      res = stmt.executeQuery(sql);
      while (res.next()) {
        // Copy File First
        
          final File toDir = new File(fileDir + "/" + res.getString("AD_TABLE_ID") + "-" + uid);
          final File fromDir = new File(fileDir + "/" + res.getString("AD_TABLE_ID") + "-" + mProductID);
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
      
      log.debug("Copy Files Successfully finished\n");
      // Do insert File Table.
      sql = "select zsmf_copyproductfiles('" + mProductID + "','"  + uid + "','" + adUserId + "') as plresult from dual";
      res = stmt.executeQuery(sql);
      if (res.first())
        result = res.getString("plresult");
      else
        result = "@zsse_DataNotExists@";
      // Throw if SQL not OK
      if (!result.equals("SUCCESS"))
        throw new Exception ("Error in Copy Files - SQL-Procedure" + result);
      conn.close();
      final OBError msg = new OBError();
      if (!result.equals("SUCCESS")) {
        msg.setType("Error");
        msg.setMessage(result);
      } 
      else {
        msg.setType("Success");
        msg.setMessage("@zsse_SuccessfullCopyProduct@" + newName + " " + link);
      }
      msg.setTitle("Done");
      bundle.setResult(msg);
      
    } catch (final Exception e) {
      log.error(e.getMessage(), e);
      final OBError msg = new OBError();
      msg.setType("Error");
      msg.setMessage(e.getMessage());
      msg.setTitle("@DoneWithErrors@");
      bundle.setResult(msg);
    }

  }

}