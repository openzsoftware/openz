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
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openz.view.Scripthelper;

public class ConfigureRadioButton {
 
  
  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname,String groupid, boolean checked,boolean readonly,String callout, String labeltext,String elementId) throws Exception{
    String retval="";
    final String directory= servlet.strBasePath;
    
    retval=retval +  ConfigureLabel.doConfigure(servlet,vars,fieldname,"TitleCell " + groupid,labeltext,elementId,"");
    Object template =  servlet.getServletContext().getAttribute("radioButtonTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("RadioButton.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("radioButtonTEMPLATE", template);
    }
    retval=retval + template.toString();
    retval=Replace.replace(retval, "@FIELDNAME@", fieldname);
    if (checked)
         retval=Replace.replace(retval, "@CHECKED@", "checked");
    else
         retval=Replace.replace(retval, "@CHECKED@", "");
    retval=Replace.replace(retval, "@CALLOUT@", callout);
    retval=Replace.replace(retval, "@GROUPID@",groupid);
    if (readonly)
      retval=Replace.replace(retval, "@READONLY@", "readonly=\"true\" disabled=\"true\"");
    else
      retval=Replace.replace(retval, "@READONLY@", "");
    
    return retval;
  }
    
}
