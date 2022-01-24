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
import org.openz.util.UtilsData;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openz.view.Scripthelper;

public class ConfigureDatebox {
 
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String currentvalue,String callout, String tooltip, String elementId, String style, Boolean isListBased) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,required,readonly,currentvalue,callout, "", false, "",tooltip,elementId,style,isListBased);
    
  }
  public static StringBuilder doConfigureGrid(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int colspan,boolean required,boolean readonly,String currentvalue,String callout, String jssettings, String tooltip,String style, Boolean isListBased) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, 0,colspan+1,required,readonly,currentvalue,callout, "", true, jssettings,tooltip,"",style,isListBased);
  }
  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String currentvalue,String callout, String labeltext, boolean isGrid, String jssettings,String title,String elementId,String style, Boolean isListBased) throws Exception{
    StringBuilder retval= new StringBuilder();
    String formname="frmMain";
    if (jssettings==null)
      jssettings="";
    if (style==null)
      style="";
    final String directory= servlet.strBasePath;
    String strinvalid=Utility.messageBD(servlet, "JSInvalid", vars.getLanguage());
    String strrequired=Utility.messageBD(servlet, "JSMissing", vars.getLanguage());
    String stdJSSettings = jssettings;
    if (jssettings.equals(""))
      stdJSSettings = "onfocus=\"isGridFocused = false;\" onkeyup=\"autoCompleteDate(this);\" onkeydown=\"changeToEditingMode('onkeydown');\" onkeypress=\"changeToEditingMode('onkeypress');\" oncut=\"changeToEditingMode('oncut');\" onpaste=\"changeToEditingMode('onpaste');\" oncontextmenu=\"changeToEditingMode('oncontextmenu');\" onblur=\"expandDateYear(this.id);\" onchange=\"validateDateTextBox(this.id);logChanges(this); @CALLOUT@ displayLogic(); return true;\"";
    for (int i = 0; i < leadingemptycols; i++) {
      retval=retval.append("<td class=\"leadingemptycolsdatebox\"></td>");
    }
    if (isListBased) {
    	String targetvalue=UtilsData.selectDisplayDatevalue(servlet,currentvalue, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat"));
	    retval=retval.append(ConfigureListBasedEntry.doConfigure(servlet,vars,script,fieldname,elementId,targetvalue,isGrid,colstotal,callout,style));
	    return retval;
    }
    if (! isGrid && ! readonly)
      retval=retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"TitleCell",labeltext,elementId,""));
    if (! isGrid &&  readonly)
      retval=retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"Label_ContentCell",labeltext,elementId,""));
    Object template;
    if ( isGrid)
    	template=  servlet.getServletContext().getAttribute("dateboxTEMPLATEGRID");
    else
    	template=  servlet.getServletContext().getAttribute("dateboxTEMPLATE");
    if (template==null) {
      if ( isGrid) {
    	  template = new String(FileUtils.readFile("DateboxGRID.xml", directory + "/src-loc/design/org/openz/view/templates/"));
    	  servlet.getServletContext().setAttribute("dateboxTEMPLATEGRID", template);
      } else {
    	  template = new String(FileUtils.readFile("Datebox.xml", directory + "/src-loc/design/org/openz/view/templates/"));
    	  servlet.getServletContext().setAttribute("dateboxTEMPLATE", template);
      }
    }    
    retval=retval.append(template.toString());
    Object template2 =  servlet.getServletContext().getAttribute("dateboxButtonTEMPLATE");
    if (template2==null) {
      template2 = new String(FileUtils.readFile("DateboxButton.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("dateboxButtonTEMPLATE", template2);
    }
    String button = template2.toString();
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
      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    Replace.replace(retval, "@CLASS@", "inputWidth");
    Replace.replace(retval, "@JSSETTINGS@",stdJSSettings);
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@FORMNAME@", formname);
    String targetvalue=UtilsData.selectDisplayDatevalue(servlet,currentvalue, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat"));
    Replace.replace(retval, "@CURRENTVALUE@", targetvalue);
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));    
    // Callout Example : calloutSL_Order_Amt(this.name);
    Replace.replace(retval, "@CALLOUT@", callout);
    Replace.replace(retval, "@TITLE@", title);
    Replace.replace(retval, "@STYLE@", style);
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
    Replace.replace(retval, "@MAXLENGTH@", "10");
    String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
    Replace.replace(retval, "@FORMAT@", strDateFormat);
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    
    return retval;
  }
    
}
