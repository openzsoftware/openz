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
import org.openz.util.LocalizationUtils;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openz.view.Scripthelper;

public class ConfigureFieldgroup {
 
  
  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script, String fieldname, String numcols,  String labeltext, String fielgroupid) throws Exception{
    String retval="";
    String button = "";
    String text=labeltext;
    if (text.equals(""))
      text = LocalizationUtils.getElementTextByElementName(servlet, fieldname, vars.getLanguage());
    final String directory= servlet.strBasePath;
    Object template =  servlet.getServletContext().getAttribute("fieldgroupTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Fieldgroup.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("fieldgroupTEMPLATE", template);
    }
    retval=retval + template.toString();
    retval=Replace.replace(retval, "@NUMCOLS@", numcols);
    retval=Replace.replace(retval, "@FIELDGROUPTEXT@", text);
    retval=Replace.replace(retval, "@FIELDNAME@", fieldname);
    if (!fielgroupid.isEmpty())
      button="<button onclick=\"zeige('"+fielgroupid+"')\" type=\"button\">+</button>";
    retval=Replace.replace(retval, "@GROUPBUTTON@", button);
    return retval;
  }
    
}
