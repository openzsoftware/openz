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
public class ConfigureButton{
 
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String buttonname, int leadingemptycols,int colspan,boolean readonly,String flavour,String action, String currentvalue, String elementId) throws Exception{
    return doConfigureAll(servlet, vars, script, buttonname, leadingemptycols, colspan, readonly, flavour, action, currentvalue, elementId,null, null);
  }
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String buttonname, int leadingemptycols,int colspan,boolean readonly,String flavour,String action, String currentvalue, String elementId,String onchangeevent) throws Exception{
	    return doConfigureAll(servlet, vars, script, buttonname, leadingemptycols, colspan, readonly, flavour, action, currentvalue, elementId,onchangeevent,null);
	  }
  public static StringBuilder doConfigureNew(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String buttonname, int leadingemptycols,int colspan,boolean readonly,String flavour,String action, String currentvalue, String elementId,String onchangeevent, String style) throws Exception{
	    return doConfigureAll(servlet, vars, script, buttonname, leadingemptycols, colspan, readonly, flavour, action, currentvalue, elementId,null, style);
	  }
  public static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String buttonname, int leadingemptycols,int colspan,boolean readonly,String flavour,String action, String currentvalue, String elementId, String onchangeevent, String style) throws Exception{
    StringBuilder retval= new StringBuilder();
    String text ="";
    String straction =action;
    if (elementId.equals(""))
      text = LocalizationUtils.getElementTextByElementName(servlet, buttonname, vars.getLanguage());
    else
      text=LocalizationUtils.getElementTextById(servlet,elementId, vars.getLanguage());
    // Special Columns Docction and Posted have own Translations on Button Text Calculated from Curent Value and List Reference
    if (buttonname.equalsIgnoreCase("posted")) {
      text=LocalizationUtils.getListTextByValue(servlet,"All_Posted Status",vars.getLanguage(),currentvalue);
    }
    if (buttonname.equalsIgnoreCase("docaction")) {
      text=LocalizationUtils.getListTextByValue(servlet,"All_Document Action",vars.getLanguage(),currentvalue);
    }
    if (buttonname.equalsIgnoreCase("processed")  && ! servlet.getWindowId().equals("800027")) { // Abschreibung erstellen ausgenommen ...(ASSET)
      text=LocalizationUtils.getListTextByValue(servlet,"All_Processed_Status",vars.getLanguage(),currentvalue);
    }
    final String directory= servlet.strBasePath;
    for (int i = 0; i < leadingemptycols; i++) {
      retval=retval.append("<td class=\"leadingemptycolsbutton\"></td>");
    }
    Object template =  servlet.getServletContext().getAttribute("buttonTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Button.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("buttonTEMPLATE", template);
    }
    retval=retval.append(template.toString());
    Replace.replace(retval, "@NAME@", buttonname);
    Replace.replace(retval, "@DISABLED@", readonly ? "disabled=\"true\"" : "");
    if (readonly)
      Replace.replace(retval, "class=\"ButtonLink\"","class=\"ButtonLink ButtonLink_hover\"");
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colspan));
    // @FLAVOUR@ : process , back, lock, expand, contract, password, download, save, scanUpdates, search, html, pdf, clear, cancel, next, back, process
    Replace.replace(retval, "@FLAVOUR@", flavour);
    Replace.replace(retval, "@TEXT@", text);
    // @ACTION@ : z.B.: submitCommandForm('DEFAULT', true, "frmMain",'http://localhost:8080/openz/ProcessRequest/ProcessRequest_Relation.html', 'appFrame', false, true);
    //                  submitCommandForm('FIND', true, null, null, '_self')
    if(style==null)
    	style="";
    	Replace.replace(retval, "@STYLE@", style);
    	Replace.replace(retval, "@STYLE@", style);
    	Replace.replace(retval, "@STYLE@", style);
    
    if (onchangeevent!=null)
      straction=onchangeevent +action;
    Replace.replace(retval, "@ACTION@", straction);
    Replace.replace(retval, "@TITLE@", text);
    script.addHiddenfield("inp"+buttonname, currentvalue);
    return retval;
  }
    
}
