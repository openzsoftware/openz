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


import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openz.util.LocalizationUtils;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openz.view.Scripthelper;

public class ConfigureCheckbox {
 
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,String callout,String value,boolean checked, boolean readonly, String tooltip, String elementId, Boolean isListBased) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,callout,value,checked, readonly, "", false,"",tooltip, elementId,isListBased);
  }
  public static StringBuilder doConfigureGrid(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname,int colstotal,String callout,String value,boolean checked, boolean readonly, String jssettings, String elementId, Boolean isListBased) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, 0,colstotal,callout,value,checked, readonly, "", true,jssettings,"", elementId,isListBased);
  }
  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,String callout,String value,boolean checked, boolean readonly, String labeltext, boolean isgrid, String jssettings,String tooltip, String elementId,Boolean isListBased) throws Exception{
    StringBuilder retval= new StringBuilder();
    final String directory= servlet.strBasePath;
    if (jssettings==null)
      jssettings="";
    String stdJSSettings = jssettings;
    if (jssettings.equals("") && ! isgrid)
      stdJSSettings = "onchange=\"@CALLOUT@ logChanges(this);displayLogic(); return true;\" onclick=\"changeToEditingMode('force');logChanges(this);return true;\" required=\"true\"";
    if (jssettings.equals("") &&  isgrid)
      stdJSSettings = "onchange=\"@CALLOUT@ logChanges(this);displayLogic(); return true;\" onclick=\"changeToEditingMode('force');yn(this);logChanges(this);return true;\" required=\"true\"";
    for (int i = 0; i < leadingemptycols; i++) {
      retval=retval.append("<td class=\"leadingemptycolscheckbox\"></td>");
    }
    if (isListBased) {
    	String targetvalue=LocalizationUtils.getMessageText(servlet,checked ? "Y":"N" , vars.getLanguage());
	    retval=retval.append(ConfigureListBasedEntry.doConfigure(servlet,vars,script,fieldname,elementId,targetvalue,isgrid,1,callout,null));
	    return retval;
    }
    if (! isgrid)
      retval=retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"TitleCell",labeltext,elementId,""));
    Object template =  servlet.getServletContext().getAttribute("checkboxTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Checkbox.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("checkboxTEMPLATE", template);
    }
    retval=retval.append(template.toString());
    if (! isgrid)
      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    else
      Replace.replace(retval, "@CONTENTCELLCLASS@","DataGrid_Content");
    Replace.replace(retval, "@JSSETTINGS@",stdJSSettings); 
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@NUMCOLS@", "1");
    Replace.replace(retval, "@VALUE@", value);
    Replace.replace(retval, "@TITLE@", tooltip);
    if (checked)
         Replace.replace(retval, "@CHECKED@", "checked");
    else
         Replace.replace(retval, "@CHECKED@", "");
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\" disabled=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    Replace.replace(retval, "@CALLOUT@", callout);
    
    return retval;
  }
    
}
