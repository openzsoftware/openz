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
import org.openz.util.FormatUtils;
import org.openz.util.LocalizationUtils;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openz.view.Scripthelper;
import org.openz.view.SelectBoxhelper;

public class ConfigurePAttribute {
 
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String currentidvalue,String callout, String tooltip, String elementId, Boolean isListBased) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,required,readonly,currentidvalue,callout, "", false, "",tooltip,elementId,isListBased);
    
  }
  public static StringBuilder doConfigureGrid(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int colspan,boolean required,boolean readonly,String currentidvalue,String callout, String jssettings, String tooltip, Boolean isListBased) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, 0,colspan+1,required,readonly,currentidvalue,callout, "", true, jssettings,tooltip,"",isListBased);
  }
  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String currentidvalue,String callout, String labeltext, boolean isGrid, String jssettings,String title,String elementId, Boolean isListBased) throws Exception{
    StringBuilder retval= new StringBuilder();
    String formname="frmMain";
    if (jssettings==null)
      jssettings="";
    final String directory= servlet.strBasePath;
    String strinvalid=Utility.messageBD(servlet, "JSInvalid", vars.getLanguage());
    String strrequired=Utility.messageBD(servlet, "JSMissing", vars.getLanguage());
    String stdJSSettings = jssettings;
    String currenttextvalue=SelectBoxhelper.getAttributeNameByID(servlet,vars,currentidvalue);
    if (jssettings.equals(""))
      stdJSSettings = "onkeydown=\"changeToEditingMode('onkeydown');\" onkeypress=\"changeToEditingMode('onkeypress');\" oncut=\"changeToEditingMode('oncut');\" onpaste=\"changeToEditingMode('onpaste');\" oncontextmenu=\"changeToEditingMode('oncontextmenu');\" onchange=\"validateTextBox(this.id);logChanges(this); @CALLOUT@ return true;\"";
    for (int i = 0; i < leadingemptycols; i++) {
      retval=retval.append("<td class=\"leadingemptycolsattri\"></td>");
    }
    if (isListBased) {
	    retval=retval.append(ConfigureListBasedEntry.doConfigure(servlet,vars,script,fieldname,elementId,currenttextvalue,isGrid,colstotal,callout,null));
	    return retval;
    }
    if (! isGrid && ! readonly)
      retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"TitleCell",labeltext,elementId,""));
    if (! isGrid &&  readonly)
      retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"Label_ContentCell",labeltext,elementId,""));
    Object template;
    if ( isGrid)
    	template=  servlet.getServletContext().getAttribute("attributeFieldTEMPLATEGRID");
    else
    	template=  servlet.getServletContext().getAttribute("attributeFieldTEMPLATE");
    if (template==null) {
      if ( isGrid) {
    	  template = new String(FileUtils.readFile("AttributeFieldGRID.xml", directory + "/src-loc/design/org/openz/view/templates/"));
    	  servlet.getServletContext().setAttribute("attributeFieldTEMPLATEGRID", template);
      } else {
    	  template = new String(FileUtils.readFile("AttributeField.xml", directory + "/src-loc/design/org/openz/view/templates/"));
    	  servlet.getServletContext().setAttribute("attributeFieldTEMPLATE", template);
      }
    }    
    
    retval.append(template.toString());
    template =  servlet.getServletContext().getAttribute("attributeFieldButtonTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("AttributeFieldButton.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("attributeFieldButtonTEMPLATE", template);
    }
    String button = template.toString();
    if (readonly || isGrid){
       Replace.replace(retval, "@CONTENTWIDTH@","97%");
       
       if (readonly==true){
         Replace.replace(retval, "@CONTENTWIDTH@","97%");
         Replace.replace(retval, "@CLASS@", "inputWidth cellreadonly");
         Replace.replace(retval, "@BUTTON@","");
       }else{
         Replace.replace(retval, "@BUTTON@",button);
         Replace.replace(retval, "@BUTTONWIDTH@","27px");
       }
    }
    else{
      Replace.replace(retval, "@BUTTON@", button);
      Replace.replace(retval, "@CONTENTWIDTH@","97%");
      Replace.replace(retval, "@BUTTONWIDTH@","27px");
    }
    if (isGrid)
      Replace.replace(retval, "@CONTENTCELLCLASS@","DataGrid_Content");
    else
      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    Replace.replace(retval, "@CLASS@", "inputWidth cellreadonly");
    Replace.replace(retval, "@JSSETTINGS@",stdJSSettings);
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@FORMNAME@", formname);
    Replace.replace(retval, "@CURRENTTEXTVALUE@", currenttextvalue);
    Replace.replace(retval, "@CURRENTIDVALUE@", currentidvalue);
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
      //if (readonly)
      //  Replace.replace(retval, "@REQUIRED@", "cellreadonly");
      //else
        Replace.replace(retval, "@REQUIRED@", "");
    }
    Replace.replace(retval, "@MAXLENGTH@", "10");
    /*
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    */
    return retval;
  }
    
}
