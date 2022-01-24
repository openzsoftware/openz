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


import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Writer;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.scheduling.Process;



import org.apache.commons.fileupload.FileItem;
import org.apache.log4j.Logger;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openz.util.FormatUtils;
import org.openz.util.FileUtils;

public class DatevSuSaImportService implements Process {
  private static final Logger log = Logger.getLogger(DatevSuSaImportService.class);

  public void execute(ProcessBundle bundle) throws Exception {

    log.debug("Starting DatevExportService.\n");
    VariablesSecureApp vars = bundle.vars;
    OBError msg = new OBError();
    String suSaID=vars.getMultiParameter("inpKey");
    String user=vars.getUser();
    final File uploadedDir = new File("/tmp");
    final FileItem file = vars.getMultiFile("inpfile");
        //vars.getMultiFile("inpFile");
    final File uploadedFile = new File(uploadedDir, file.getName());
    if (file.getName().isEmpty())
      throw new ServletException("Empty file");
    if (uploadedFile.exists())
      uploadedFile.delete();
    try {
      file.write(uploadedFile);
      // Copy Uploaded File to Attachment
      String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
      FileUtils.copyFile("/"+uploadedDir.getName(), fileDir + "/364C2EEFD2254894AA8C96ECC0A38908-" + suSaID +"/", file.getName(), file.getName());
      FileUtils.attachFile(bundle.getConnection(), file.getName(),"364C2EEFD2254894AA8C96ECC0A38908", suSaID, user, vars.getOrg(), "Datev Summen und Saldenliste");
      // File 2 UTF8
      File tempfile=new File(uploadedDir, file.getName() + ".tmp");
      uploadedFile.renameTo(tempfile);
      InputStreamReader in = new InputStreamReader (new FileInputStream(tempfile), "ISO-8859-15");
      BufferedReader inr = new BufferedReader(in);
      FileOutputStream fos = new FileOutputStream(uploadedFile);
      OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
      Writer out = new BufferedWriter(osw);
      String line;
      int i=0;
      while ((line= inr.readLine())!=null) {
        if (i>5){
          out.write(line);
          out.write("\r\n");
        }
        i++;   
      }
      out.close();
      in.close();
      tempfile.delete();
      // Import File
      String result=DatevData.importSuSa(bundle.getConnection(), "/tmp/" + file.getName(), user, suSaID);
      if (!result.startsWith("SUCCESS")) 
        throw new Exception (result);
      msg.setType("Success");
      msg.setMessage("Datev-Service Successful execution.");
      msg.setTitle("Done");
      bundle.setResult(msg);
    } catch (Exception e) {
      e.printStackTrace();
      msg.setType("Error");
      msg.setMessage("Error in Datev-Procedure:" + e.getMessage());
      msg.setTitle("Done");
      bundle.setResult(msg);
      //throw new ServletException ("Error in Datev-Procedure." );  
    }   
  } 
}

