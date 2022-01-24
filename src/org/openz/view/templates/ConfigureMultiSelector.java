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
import org.openz.view.SelectBoxhelper;
import org.openbravo.data.FieldProvider;
import org.openz.view.Scripthelper;

public class ConfigureMultiSelector {
 
  
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String selector,String currentvalue,String tooltip,String elementId, String callout) throws Exception{
    StringBuilder retval= new StringBuilder();
    final String directory= servlet.strBasePath;
    String strupper=Utility.messageBD(servlet, "JSMultiselUpper", vars.getLanguage());
    String strmiddle=Utility.messageBD(servlet, "JSMultiselMiddle", vars.getLanguage());
    String strlower=Utility.messageBD(servlet, "JSMultiselLower", vars.getLanguage());
    String strrequired=Utility.messageBD(servlet, "JSMissing", vars.getLanguage());
    String url= ".." + SelectBoxhelper.getSelectorURL(servlet,vars,selector);
    String strbuttons=FileUtils.readFile("MultiselectorButtons.xml", directory + "/src-loc/design/org/openz/view/templates/");
    String strCurrenSelects="";
    String formname="frmMain";
    for (int i = 0; i < leadingemptycols; i++) {
      retval.append("<td class=\"leadingemptycolsmultiselector\"></td>");
    }
    retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"TitleCell","",elementId,""));
    Object template =  servlet.getServletContext().getAttribute("multiselectorTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Multiselector.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("multiselectorTEMPLATE", template);
    }
    retval.append(template.toString());
    if (readonly)
      Replace.replace(retval, "@BUTTONS@", "<td></td>");
    else
      Replace.replace(retval, "@BUTTONS@", strbuttons);
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));
    Replace.replace(retval, "@TITLE@", tooltip);
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    //Looks over Nameconvention _id in tables 
    strCurrenSelects=SelectBoxhelper.fields2option2(servlet, fieldname,currentvalue,false,false,fieldname,currentvalue,vars.getLanguage());
    Replace.replace(retval, "@CURRENTVALUE@", strCurrenSelects);
    
    Replace.replace(retval, "@UPPERMESSAGE@",strupper);
    Replace.replace(retval, "@MIDDLEMESSAGE@",strmiddle);
    Replace.replace(retval, "@LOWERMESSAGE@",strlower);
    
    Replace.replace(retval, "@REQUIREDMESSAGE@",strrequired);
    if (required){
      Replace.replace(retval, "@REQUIREDTAG@", "required=\"true\"");
      Replace.replace(retval, "@REQUIRED@", "required");
    } else {
      Replace.replace(retval, "@REQUIREDTAG@", "");
      if (readonly)
        Replace.replace(retval, "@REQUIRED@", "cellreadonly");
      else
        Replace.replace(retval, "@REQUIRED@", "");
    }
    
    Replace.replace(retval, "@SELECTORURL@",url);
    Replace.replace(retval, "@SELECTORNAME@",selector);
    Replace.replace(retval, "@FORMNAME@",formname);
    Replace.replace(retval, "@CALLOUT@", callout);
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\"  disabled=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    
    script.addmultiselected(fieldname);
    return retval;
  }
    
}
