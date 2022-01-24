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
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openz.view.Scripthelper;

public class ConfigureUrlbox {
 
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,int maxlength,boolean required,boolean readonly,String currentvalue,String callout, String tooltip,String elementId) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,maxlength,required,readonly,currentvalue,callout, "", false, "",tooltip,elementId);
    
  }
  public static StringBuilder doConfigureGrid(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int colspan,int maxlength,boolean required,boolean readonly,String currentvalue, String jssettings, String tooltip) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, 0,colspan+1,maxlength, required,readonly,currentvalue,"", "", true, jssettings,tooltip,"");
  }
  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,int maxlength,boolean required,boolean readonly,String currentvalue,String callout, String labeltext, boolean isGrid, String jssettings,String title,String elementId) throws Exception{
    StringBuilder retval= new StringBuilder();
    String formname="frmMain";
    if (jssettings==null)
      jssettings="";
    final String directory= servlet.strBasePath;
    String strinvalid=Utility.messageBD(servlet, "JSInvalid", vars.getLanguage());
    String strrequired=Utility.messageBD(servlet, "JSMissing", vars.getLanguage());
    String stdJSSettings = jssettings;
    String hiddenJSSettings = "";
    String InpJSSettings = "";
    if (jssettings.equals(""))
      //stdJSSettings = "onkeyup=\"autoCompleteDate(this);\" onkeydown=\"changeToEditingMode('onkeydown');\" onkeypress=\"changeToEditingMode('onkeypress');\" oncut=\"changeToEditingMode('oncut');\" onpaste=\"changeToEditingMode('onpaste');\" oncontextmenu=\"changeToEditingMode('oncontextmenu');\" onblur=\"expandDateYear(this.id);\" onchange=\"validateDateTextBox(this.id);logChanges(this);displayLogic(); @CALLOUT@ return true;\"";
      hiddenJSSettings = "onclick=\"window.open(document.getElementById('@FIELDNAME@').value);return false;\" onkeyup=\"this.className='FieldButtonLink_focus'; return true;\" onkeypress=\"this.className='FieldButtonLink_active'; return true;\" onblur=\"window.status=''; return true;\" onfocus=\"setWindowElementFocus(this); window.status='@FIELDNAME@'; return true;\"";
      stdJSSettings = "onmouseout=\"this.className='FieldButton'; window.status=''; return true;\" onmouseover=\"this.className='FieldButton_hover'; window.status='@FIELDNAME@'; return true;\" onmouseup=\"this.className='FieldButton'; return true;\" onmousedown=\"this.className='FieldButton_active'; return true;\"";     
      InpJSSettings = "onchange=\"validateUrlTextBox(this.id);logChanges(this);return true;\" oncontextmenu=\"changeToEditingMode('oncontextmenu');\" onpaste=\"changeToEditingMode('onpaste');\" oncut=\"changeToEditingMode('oncut');\" onkeypress=\"changeToEditingMode('onkeypress');\" onkeydown=\"changeToEditingMode('onkeydown');\" onkeyup=\"\""; 
    for (int i = 0; i < leadingemptycols; i++) {
      retval.append("<td class=\"leadingemptycolsurl\"></td>");
    }
    if (! isGrid && ! readonly)
      retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"TitleCell",labeltext,elementId,""));
    if (! isGrid &&  readonly)
      retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"Label_ContentCell",labeltext,elementId,""));
    Object template =  servlet.getServletContext().getAttribute("urlboxTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Urlbox.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("urlboxTEMPLATE", template);
    }
    retval.append(template.toString());
    template =  servlet.getServletContext().getAttribute("urlboxButtonTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("UrlboxButton.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("urlboxButtonTEMPLATE", template);
    }
    String button = template.toString();
    if (readonly || isGrid){
       Replace.replace(retval, "@BUTTON@","");
       Replace.replace(retval, "@CONTENTWIDTH@","100%");
    }
    else{
      Replace.replace(retval, "@BUTTON@", button);
      Replace.replace(retval, "@CONTENTWIDTH@","100%");
      Replace.replace(retval, "@BUTTONWIDTH@","27px");
    }
    if (isGrid)
      Replace.replace(retval, "@CONTENTCELLCLASS@","DataGrid_Content");
    else
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
      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    Replace.replace(retval, "@CLASS@", "inputWidth");
    Replace.replace(retval, "@JSSETTINGS@",stdJSSettings);
    Replace.replace(retval, "@hiddenJSSETTINGS@",hiddenJSSettings);
    Replace.replace(retval, "@InpJSSETTINGS@",InpJSSettings);
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@FORMNAME@", formname);
    Replace.replace(retval, "@CURRENTVALUE@", currentvalue);
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));    
    // Callout Example : calloutSL_Order_Amt(this.name);
    Replace.replace(retval, "@CALLOUT@", callout);
    Replace.replace(retval, "@TITLE@", title);
    Replace.replace(retval, "@INVALIDMESSAGE@",strinvalid);
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
    Replace.replace(retval, "@MAXLENGTH@", Integer.toString(maxlength));
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    
    return retval;
  }
    
}
