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
import org.openbravo.erpCommon.utility.Utility;
import org.openz.view.Scripthelper;
import org.openz.util.FormatUtils;
import org.openz.util.UtilsData;

public class ConfigureNumberbox {
 
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,int maxlength,boolean required,boolean readonly,String callout,  String format,String currentvalue,String tooltip,String elementId, String style,Boolean isListBased,Boolean isBuscador, int refcolcount) throws Exception{
    String strformat="";
    if (format.equals("DECIMAL")||format.equals("SQLFIELDDECIMAL"))
      strformat="qtyEdition";
    if (format.equals("INTEGER")||format.equals("SQLFIELDINTEGER"))
      strformat="integerEdition";
    if (format.equals("PRICE")||format.equals("SQLFIELDPRICE"))
      strformat="priceEdition";
    if (format.equals("EURO")||format.equals("SQLFIELDEURO"))
      strformat="euroEdition";
    if (strformat.equals(""))
      strformat=format;
    return doConfigureAll(servlet,vars,script,fieldname,leadingemptycols,colstotal, maxlength,required,readonly,callout,strformat,currentvalue, "",false,"",tooltip,elementId,style,isListBased,isBuscador,refcolcount);
  }
  public static StringBuilder doConfigureGrid(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int colspan,int maxlength,boolean required,boolean readonly,String callout, String flavor,String currentvalue,String jssettings,String tooltip, String style,Boolean isListBased) throws Exception{
    String strformat="";
    if (flavor.equals("DECIMAL"))
      strformat="qtyEdition";
    if (flavor.equals("INTEGER"))
      strformat="integerEdition";
    if (flavor.equals("PRICE"))
      strformat="priceEdition";
    if (flavor.equals("EURO"))
      strformat="euroEdition";
    
    return doConfigureAll(servlet,vars,script,fieldname,0,colspan+1, maxlength,required,readonly, callout,strformat,currentvalue, "",true,jssettings,tooltip,"",style,isListBased,false,0);
  }
  
  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,int maxlength,boolean required,boolean readonly,String callout,  String format,String currentvalue,String labeltext, boolean isGrid, String jssettings, String title,String elementId,String style,Boolean isListBased,Boolean isBuscador,int refcolcount) throws Exception{
    StringBuilder retval= new StringBuilder();
    if (jssettings==null)
      jssettings="";
    final String directory= servlet.strBasePath;
    String strinvalid=Utility.messageBD(servlet, "JSInvalid", vars.getLanguage());
    String strrequired=Utility.messageBD(servlet, "JSMissing", vars.getLanguage());
    String formname="frmMain";
    String stdJSSettings = jssettings;
    if (jssettings.equals(""))
      stdJSSettings="onkeydown=\"changeToEditingMode('onkeydown'); numberInputEvent('onkeydown', this, event);\" onkeypress=\"changeToEditingMode('onkeypress');\" oncut=\"changeToEditingMode('oncut');\" onpaste=\"changeToEditingMode('onpaste');\" oncontextmenu=\"changeToEditingMode('oncontextmenu');\" onchange=\"logChanges(this); numberInputEvent('onchange', this); @CALLOUT@; displayLogic();return true;\"  onfocus=\"numberInputEvent('onfocus', this);this.oldvalue = this.value;isGridFocused = false;\" onblur=\"numberInputEvent('onblur', this);\"";
    for (int i = 0; i < leadingemptycols; i++) {
      retval=retval.append("<td class=\"leadingemptycolsnumber\"></td>");
    }
    if (isListBased) {
    	String targetvalue=FormatUtils.formatNumber(currentvalue, vars, format);
	    retval=retval.append(ConfigureListBasedEntry.doConfigure(servlet,vars,script,fieldname,elementId,targetvalue,isGrid,colstotal,callout,style));
	    return retval;
    }
    if (! isGrid && ! readonly)
      retval=retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"TitleCell",labeltext,elementId,""));
    if (! isGrid &&  readonly)
      retval=retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"Label_ContentCell",labeltext,elementId,""));
    Object template;
    String tmplname="";
    String filename="";
    // The Mobile Session VAR acesses Number Boxes with a On-Screen Numpad
    if (vars.getSessionValue("#ISMOBILE").equals("TRUE")||vars.getSessionValue("#ISMOBILE").equals("MANUAL")) {
    	template=  servlet.getServletContext().getAttribute("numberboxTEMPLATEMOBILE");
    	tmplname="numberboxTEMPLATEMOBILE";
    	filename="NumberboxMOBILE.xml";
    	if (!readonly) {
    		if (vars.getSessionValue("#ISMOBILE").equals("TRUE"))
    			script.addJScript("window.addEventListener(\"load\", function(){numpad.attach({id : \"" + fieldname + "\"},\"Y\");});");    		
    	}
    	stdJSSettings="";
    	
    } else if ( isGrid) {
    	template=  servlet.getServletContext().getAttribute("numberboxTEMPLATEGRID");
    	tmplname="numberboxTEMPLATEGRID";
    	filename="NumberboxGRID.xml";
    } else {
    	template=  servlet.getServletContext().getAttribute("numberboxTEMPLATE");
    	tmplname="numberboxTEMPLATE";
    	filename="Numberbox.xml";
    }
    
    if (template==null) {
    	  template = new String(FileUtils.readFile(filename, directory + "/src-loc/design/org/openz/view/templates/"));
    	  servlet.getServletContext().setAttribute(tmplname, template);
    } 
    retval=retval.append(template.toString());
    template =  servlet.getServletContext().getAttribute("numberboxButtonTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("NumberboxButton.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("numberboxButtonTEMPLATE", template);
    }
    String button = template.toString();
    // in Grid no Button
    // refcolcount>=10 means buscador direct filter  
    if (readonly || isGrid || (isBuscador && refcolcount>=10)){
      Replace.replace(retval, "@BUTTON@","");
      Replace.replace(retval, "@CONTENTWIDTH@","100%");
    }
    else{
      Replace.replace(retval, "@BUTTON@", button);
      Replace.replace(retval, "@CONTENTWIDTH@","100%");
      Replace.replace(retval, "@BUTTONWIDTH@","27px");
    }
    if (style==null){
      style="";
    }
    if (isGrid)
      Replace.replace(retval, "@CONTENTCELLCLASS@","DataGrid_Content");
    else
      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    Replace.replace(retval, "@CLASS@", "inputWidth");
    Replace.replace(retval, "@JSSETTINGS@",stdJSSettings);
    Replace.replace(retval, "@CLASS@", "TextBox_btn_OneCell_width");
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@FORMNAME@", formname);
    Replace.replace(retval, "@CURRENTVALUE@", FormatUtils.formatNumber(currentvalue, vars, format));
    Replace.replace(retval, "@TITLE@", title);
    Replace.replace(retval, "@STYLE@", style);
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));    
    // Callout Example : calloutSL_Order_Amt(this.name);
    Replace.replace(retval, "@CALLOUT@", callout);
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
    // Format Example qtyEdition priceEdition integerEdition
    Replace.replace(retval, "@FORMAT@", format);
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    
    return retval;
  }
    
}
