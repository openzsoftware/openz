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

import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openz.util.LocalizationUtils;
import org.openz.view.*;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.*;


public class ConfigureContentPage {
 
  

  public static String doConfigureContentPage(HttpSecureAppServlet servlet,VariablesSecureApp vars, String name, String strcontent) throws Exception{
    StringBuilder retval= new StringBuilder();
    String scriptset="";
    String formname=servlet.getClass().getName().substring(servlet.getClass().getName().lastIndexOf(".")+1,servlet.getClass().getName().length());
    String theme=vars.getTheme();
    String language=vars.getLanguage();
    if (language.isEmpty())
    	language="de_DE";
  
    String title=LocalizationUtils.getWindowTitle(servlet, name, vars.getLanguage());
    final String directory= servlet.strBasePath;
    Object template; 
    template = new String(FileUtils.readFile("ContentPage.xml", directory + "/src-loc/design/org/openz/view/templates/"));
    retval.append(template.toString());   
    template =  servlet.getServletContext().getAttribute("scriptsetTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Scriptset.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("scriptsetTEMPLATE", template);
    }
    scriptset=template.toString();   
    
    Replace.replace(retval, "@SCRIPTSET@",scriptset);
    Replace.replace(retval, "@THEME@", theme);
    Replace.replace(retval, "@LANGUAGE@", language);
    Replace.replace(retval, "@FORMNAME@", formname);

    String initHiddenFields="";

    Replace.replace(retval, "@TITLE@", title);
    Replace.replace(retval, "@INITHIDDENFIELDS@", initHiddenFields);
    Replace.replace(retval, "@CONTENT@",strcontent);
    return retval.toString();
  }

}
