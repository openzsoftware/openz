package org.openz.view.templates;
/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/


import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openz.view.Scripthelper;

public class ConfigureFileUpload {
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,String tooltip,String elementId) throws Exception{
   
    StringBuilder retval= new StringBuilder();
    final String directory= servlet.strBasePath;
    String strinvalid=Utility.messageBD(servlet, "JSInvalid", vars.getLanguage());
    String strrequired=Utility.messageBD(servlet, "JSMissing", vars.getLanguage());
   
    retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"Label_ContentCell","",elementId,""));
    Object template =  servlet.getServletContext().getAttribute("fileuploadTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("FileUpload.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("fileuploadTEMPLATE", template);
    }
    retval.append(template.toString());
      //FileUtils.readFile("Textbox.xml", directory + "/src-loc/design/org/openz/view/templates/");

      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
   
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));
    Replace.replace(retval, "@FIELDNAME@", fieldname);
 //   Replaces the real characters > " so saving and loading is possible. dh
    
    Replace.replace(retval, "@TITLE@", "");
   
    return retval;
  }
    
}
