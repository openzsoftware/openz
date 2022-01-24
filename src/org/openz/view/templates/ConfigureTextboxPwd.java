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

public class ConfigureTextboxPwd {
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,int maxlength,boolean required,boolean readonly,String callout,String currentvalue,String tooltip,String elementId) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,maxlength,required,readonly,callout,currentvalue,"", false, "",tooltip,elementId);
    
  }
 
  public static StringBuilder doConfigureGrid(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int colspan,int maxlength,boolean required,boolean readonly,String callout,String currentvalue,String jssettings, String tooltip) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, 0,colspan+1,maxlength,required,readonly,callout,currentvalue,"", true,jssettings, tooltip,"");
    
  }
  
  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,int maxlength,boolean required,boolean readonly,String callout,String currentvalue,String labeltext, boolean isGrid, String jssettings, String title,String elementId) throws Exception{
    StringBuilder retval= new StringBuilder();
    final String directory= servlet.strBasePath;
    String strinvalid=Utility.messageBD(servlet, "JSInvalid", vars.getLanguage());
    String strrequired=Utility.messageBD(servlet, "JSMissing", vars.getLanguage());
    if (jssettings==null)
      jssettings="";
    String stdJSSettings = jssettings;
    if (jssettings.equals(""))
      stdJSSettings =  "onkeydown=\"changeToEditingMode('onkeydown');\" onkeypress=\"changeToEditingMode('onkeypress');\" oncut=\"changeToEditingMode('oncut');\" onpaste=\"changeToEditingMode('onpaste');\" oncontextmenu=\"changeToEditingMode('oncontextmenu');\" onchange=\"validateTextBox(this.id);logChanges(this); @CALLOUT@ displayLogic();return true;\"";
    for (int i = 0; i < leadingemptycols; i++) {
      retval.append("<td class=\"leadingemptycolspw\"></td>");
    }
    if (! isGrid)
      retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"Label_ContentCell",labeltext,elementId,""));
    Object template =  servlet.getServletContext().getAttribute("textboxTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Textbox.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("textboxTEMPLATE", template);
    }
    retval.append(template.toString());
      //FileUtils.readFile("Textbox.xml", directory + "/src-loc/design/org/openz/view/templates/");
    if (! isGrid)
      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    else
      Replace.replace(retval, "@CONTENTCELLCLASS@","DataGrid_Content");
    Replace.replace(retval, "@CLASS@","dojoValidateValid @REQUIRED@ inputWidth");
    Replace.replace(retval, "@JSSETTINGS@",stdJSSettings);
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));
    Replace.replace(retval, "@FIELDNAME@", fieldname);
 //   Replaces the real characters > " so saving and loading is possible. dh
    if (currentvalue!=null) {
        if (currentvalue.contains("\"")){
        currentvalue= currentvalue.replace("\"", "&quot;");
        title= title.replace("\"", "&quot;");
        }
        if (currentvalue.contains(">")){
        currentvalue= currentvalue.replace(">", "&gt;");
        title= title.replace(">", "&gt;");
        }
    }
    Replace.replace(retval, "@CURRENTVALUE@", currentvalue);
    Replace.replace(retval, "@CALLOUT@", callout);
    Replace.replace(retval, "@INVALIDMESSAGE@",strinvalid);
    Replace.replace(retval, "@TITLE@", title);
    Replace.replace(retval, "@REQUIREDMESSAGE@",strrequired);
    Replace.replace(retval, "type=\"text\"","type=\"password\"");
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
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
    Replace.replace(retval, "@MAXLENGTH@", Integer.toString(maxlength));
    return retval;
  }
    
}
