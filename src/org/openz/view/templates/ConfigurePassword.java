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
import org.openbravo.data.Sqlc;
import org.openbravo.erpCommon.utility.Utility;
import org.openz.view.Scripthelper;
import org.openz.view.SelectBoxhelper;

public class ConfigurePassword {
 
  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String currentidvalue,String callout, String tooltip, String elementId) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,required,readonly,currentidvalue,callout, "", "",tooltip,elementId);
    
  }
  
  private static String doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String currentidvalue,String callout, String labeltext, String jssettings,String title,String elementId) throws Exception{
    String retval="";
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
      retval=retval + "<td class=\"leadingemptycolspassw\"></td>";
    }
    if ( ! readonly)
      retval=retval +   ConfigureLabel.doConfigure(servlet,vars, Sqlc.TransformaNombreColumna(fieldname),"TitleCell",labeltext,elementId,"");
    if ( readonly)
      retval=retval +   ConfigureLabel.doConfigure(servlet,vars, Sqlc.TransformaNombreColumna(fieldname),"Label_ContentCell",labeltext,elementId,"");
    Object template =  servlet.getServletContext().getAttribute("passwordFieldTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Passwordfield.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("passwordFieldTEMPLATE", template);
    }
    retval=retval + template.toString();
    
    retval=Replace.replace(retval, "@CONTENTWIDTH@","100%");
    retval=Replace.replace(retval, "@BUTTONWIDTH@","27px");
    
    retval=Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    retval=Replace.replace(retval, "@CLASS@", "inputWidth");
    retval=Replace.replace(retval, "@JSSETTINGS@",stdJSSettings);
    retval=Replace.replace(retval, "@FIELDNAME@", Sqlc.TransformaNombreColumna(fieldname));
    retval=Replace.replace(retval, "@FIELDNAMEORG@", fieldname);
    retval=Replace.replace(retval, "@FORMNAME@", formname);
    retval=Replace.replace(retval, "@CURRENTTEXTVALUE@", currenttextvalue);
    retval=Replace.replace(retval, "@CURRENTIDVALUE@", currentidvalue);
    retval=Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));    
    // Callout Example : calloutSL_Order_Amt(this.name);
    retval=Replace.replace(retval, "@CALLOUT@", callout);
    retval=Replace.replace(retval, "@TITLE@", title);
    retval=Replace.replace(retval, "@INVALIDMESSAGE@",strinvalid);
    retval=Replace.replace(retval, "@REQUIREDMESSAGE@",strrequired);
    String clasname=servlet.getClass().getName();
    clasname=clasname.substring(clasname.lastIndexOf(".")+1, clasname.length());
    retval=Replace.replace(retval, "@MAPPING@",clasname);
    if (required){
      retval=Replace.replace(retval, "@REQUIREDTAG@", "required=\"true\"");
      retval=Replace.replace(retval, "@REQUIRED@", "required");
    } else {
      retval=Replace.replace(retval, "@REQUIREDTAG@", "");
      if (readonly)
        retval=Replace.replace(retval, "@REQUIRED@", "cellreadonly");
      else
        retval=Replace.replace(retval, "@REQUIRED@", "");
    }
    retval=Replace.replace(retval, "@MAXLENGTH@", "10");
    
    if (readonly)
      retval=Replace.replace(retval, "@READONLY@", "readonly=\"true\"");
    else
      retval=Replace.replace(retval, "@READONLY@", "");
    
    return retval;
  }
    
}
