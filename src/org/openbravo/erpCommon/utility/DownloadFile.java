/*
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 */

// Generic Download of Files from the File-System
package org.openbravo.erpCommon.utility;

import java.io.File;
import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.utils.FileUtility;

public class DownloadFile extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    String dfile = vars.getStringParameter("dfile");
    String fdir = vars.getStringParameter("fdir");
    downloadFile(vars, response, dfile, fdir);
  }

  private void downloadFile(VariablesSecureApp vars, HttpServletResponse response, String dfile, String fdir)
      throws IOException, ServletException {

    if (dfile.contains("..") || dfile.contains(File.separator))
      throw new ServletException("Invalid report name");

    FileUtility f = new FileUtility(globalParameters.strFTPDirectory + fdir, dfile, false, true);
    if (!f.exists())
      throw new ServletException("File Not Found");
    
    String extension = dfile.substring(dfile.lastIndexOf("."));
    if (extension.equalsIgnoreCase(".pdf")) {
      response.setContentType("application/pdf");
    } else if (extension.equalsIgnoreCase(".csv")) {
      response.setContentType("text/csv");
    } else if (extension.equalsIgnoreCase(".xls")) {
      response.setContentType("application/vnd.ms-excel");
    } else {
      response.setContentType("application/x-download");
    }
    response.setHeader("Content-Disposition", "attachment; filename=" + dfile);
    f.dumpFile(response.getOutputStream());
    response.getOutputStream().flush();
    response.getOutputStream().close();
  }
}
