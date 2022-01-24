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
package org.openbravo.zsoft.datev;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import java.io.File;

import javax.servlet.http.HttpServletResponse;

import java.io.FileOutputStream;
import java.io.PrintStream;
import org.apache.log4j.Logger;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.base.session.OBPropertiesProvider;

import org.openbravo.base.secureApp.HttpSecureAppServlet;

public class DatevExportService  {
  private static final Logger log = Logger.getLogger(DatevExportService.class);

  public void execute(ProcessBundle bundle, HttpSecureAppServlet servlet,HttpServletResponse response) throws Exception {

    log.debug("Starting DatevExportService.\n");
 
    String file= processRequest(bundle);

    servlet.printPagePopUpDownloadFile(response.getOutputStream(), file, "/DatevExport");
    final OBError msg = new OBError();
    msg.setType("Success");
    msg.setMessage("Datev-Service Successful execution.");
    msg.setTitle("Done");
    bundle.setResult(msg);
  }

private String processRequest(ProcessBundle bundle) throws Exception {
 
    final String orgID = (String) bundle.getParams().get("adOrgId");
    final String datefrom = (String) bundle.getParams().get("dateFrom");
    final String dateto = (String) bundle.getParams().get("dateTo");
    final String isComplete = (String) bundle.getParams().get("iscomplete");
    final String exportType = (String) bundle.getParams().get("exporttype");
    final String allnew = (String) bundle.getParams().get("allnew");
    final String datelaterthen = (String) bundle.getParams().get("datelaterthan");
    String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
    String adUserId=bundle.getContext().getUser();
    String result="";
    String sql;
    String filename;
    String uuid="";
    // Get SQL Prepared..
    ConnectionProvider connp = bundle.getConnection();
    Connection conn = connp.getConnection();
    Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,ResultSet.CONCUR_READ_ONLY);
    ResultSet res;
    // Make shure Dir exists
    final File toDir = new File(fileDir + "/DatevExport");
    if (!toDir.exists())
      toDir.mkdirs();
    //Sachkonten
    if (exportType.equals("SK")) {
      //"select 'KTONR____Kontenbeschriftung______________________EULand_UstID___' as datensatz union all " +
      // "select  rpad(value,9,' ')||rpad(description,40,' ')||rpad(' ',15,' ') as datensatz  from c_elementvalue where exists (select 0 from fact_acct where fact_acct.account_id=c_elementvalue.c_elementvalue_id)";
      sql = "select  substr(value,1,9)||';\"'||substr(name,1,40)||'\"' as datensatz  from c_elementvalue where exists (select 0 from fact_acct where fact_acct.account_id=c_elementvalue.c_elementvalue_id)";
      filename="Kontenbeschriftung.txt";
      res = stmt.executeQuery(sql);
      File exfile = new File(fileDir + "/DatevExport/" + filename);
      FileOutputStream outStream = new FileOutputStream(exfile);
      PrintStream pstream =  new PrintStream(outStream,true,"Cp850");
      while (res.next()) {
         pstream.println(res.getString("datensatz"));         
      }
      pstream.close();
      outStream.close();
      return filename;
    }
    if (exportType.equals("BS")) {
    // Get uuid from database
    sql = "select get_uuid() as dbuuid from dual";
    res = stmt.executeQuery(sql);
    if (res.first())
      uuid = res.getString("dbuuid");
    sql = "select zsdv_insertDatevExport('" + orgID + "','"
               + datefrom + "','" + dateto +"','" + adUserId + "','" + uuid + "','" + isComplete + "','" + allnew + "','" + datelaterthen + "') as plresult from dual";
    
    res = stmt.executeQuery(sql);
    if (res.first())
      result = res.getString("plresult");
    // Throw if SQL not OK
    if (!result.startsWith("SUCCESS"))
      throw new Exception ("Error in Datev-Procedure:" + result);
    log.debug(" Datev-Export-SQL-Procedure finished with:  " + result + "\n");   
    }
    sql = "select filename from ZSDV_DATEV_EXPORT where ZSDV_DATEV_EXPORT_id = '" + uuid + "'";
    res = stmt.executeQuery(sql);
    if (res.first())
      filename = res.getString("filename");
    else
      throw new Exception ("No Export File found.");
    sql = "select export_data as datensatz from zsdv_datev_exportlines where zsdv_datev_export_id= '" + uuid + "' order by lineno";
    res = stmt.executeQuery(sql);
    File exfile = new File(fileDir + "/DatevExport/" + filename);
    FileOutputStream outStream = new FileOutputStream(exfile);
    //PrintStream pstream =  new PrintStream(outStream,true,"Cp850");
    PrintStream pstream =  new PrintStream(outStream,true,"ISO-8859-15");
    while (res.next()) {
       pstream.println(res.getString("datensatz"));         
    }
    pstream.close();
    outStream.close();
    log.debug("Creation of File Successfully finished\n");
    return filename;
    
 
}
  
 
}

