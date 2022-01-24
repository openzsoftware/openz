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
import java.io.IOException;
import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

public class ConfigureTableStructure {
 
  
  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,String numcols,String height, String flavor) throws Exception{
    StringBuilder retval= new StringBuilder();
    String header="";
    String popupheader="";
    String popupfooter="";
    final String directory= servlet.strBasePath;
    String strclass="";
    if (flavor.equals("Popup")){
      popupheader="<div class=\"Popup_ContentPane_Client\" style=\"overflow: auto; auto; height:@HEIGHT@;\" id=\"client_top\">\n";
      strclass="Popup_Table";
      popupfooter="</div>\n";
    } else {
      strclass="Form_Table";
    }
    Object template =  servlet.getServletContext().getAttribute("tableStructureTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("TableStructure.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("tableStructureTEMPLATE", template);
    }
    retval.append(popupheader+ template.toString());
    Replace.replace(retval, "@HEIGHT@", height);
    header=header+ " <colgroup span=\""+ numcols + "\"></colgroup>";
    header=header+ "<tr><td colspan=\"" +numcols + "\"></td></tr>";
    Replace.replace(retval, "@HEADER@", header);
    Replace.replace(retval, "@CLASS@",strclass );
    return retval.append(popupfooter).toString();
  }
    
}
 
