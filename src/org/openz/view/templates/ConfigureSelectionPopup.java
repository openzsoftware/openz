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
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.security.SessionLoginData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import java.math.*;
import java.text.DecimalFormat;
import org.openz.view.SelectBoxhelper;
import org.openz.view.DataGrid;

public class ConfigureSelectionPopup {
 
  
  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,   String name, DataGrid grid, String focusfield, Boolean ismulti, String stdTargetURL) throws Exception{
    String retval="";
    String hide="";
    String scriptset="";
    String rowkeyscript="";
    String formname=servlet.getClass().getName().substring(servlet.getClass().getName().lastIndexOf(".")+1,servlet.getClass().getName().length());
    final String directory= servlet.strBasePath;
    String msgbox="";
    String theme=vars.getTheme();
    String language=vars.getLanguage();
    String icon = SelectBoxhelper.getSelectorPopupICON(servlet,vars,name);
    String title = LocalizationUtils.getWindowTitle(servlet, name, vars.getLanguage());
    Object template =  servlet.getServletContext().getAttribute("popupWindowTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("PopupWindow.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("popupWindowTEMPLATE", template);
    }
    retval=template.toString();   
    template =  servlet.getServletContext().getAttribute("scriptsetTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Scriptset.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("scriptsetTEMPLATE", template);
    }
    scriptset=template.toString();   
    template =  servlet.getServletContext().getAttribute("messageBoxTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("MessageBox.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("messageBoxTEMPLATE", template);
    }
    msgbox=template.toString();   
    
    String initscript;
    if (ismulti) {
      template =  servlet.getServletContext().getAttribute("searchJSMultiTEMPLATE");
      if (template==null) {
        template = new String(FileUtils.readFile("SearchJSMulti.xml", directory + "/src-loc/design/org/openz/view/templates/"));
        servlet.getServletContext().setAttribute("searchJSMultiTEMPLATE", template);
      }
      initscript=template.toString();   
    }
    else {
      template =  servlet.getServletContext().getAttribute("searchJSTEMPLATE");
      if (template==null) {
        template = new String(FileUtils.readFile("SearchJS.xml", directory + "/src-loc/design/org/openz/view/templates/"));
        servlet.getServletContext().setAttribute("searchJSTEMPLATE", template);
      }
      initscript=template.toString();   
    }

    String navBarLogoId = SessionLoginData.getCustomizedNavBarLogo(servlet);
    String navBarLogoIdOrg = SessionLoginData.getCustomizedNavBarLogoFromOrg(servlet, vars.getOrg());
    // org logo overwrites client logo overwrites standard logo
    if(!navBarLogoIdOrg.isEmpty()) {
        navBarLogoId = navBarLogoIdOrg;
    }
    if(navBarLogoId.isEmpty()) {
        retval = Replace.replace(retval, "@openbravonavbarlogo@",
                  "<TD class=\"Popup_NavBar_bg_logo\" width=\"1\" onclick=\"openNewBrowser('http://www.openbravo.com', 'Openbravo');return false;\"><IMG src=\"../web/images/blank.gif\" alt=\"Openbravo\" title=\"Openbravo\" border=\"0\" id=\"openbravoLogo\" class=\"Popup_NavBar_logo\"></TD>");
    }else {
        retval = Replace.replace(retval, "@openbravonavbarlogo@",
                  "<td class=\"Main_NavBar_bg_logo\" width=\"1\"><div class=\"Main_NavBar_logo_custom\" alt=\"NavBarLogo\" title=\"NavBarLogo\" border=\"0\" id=\"NavBarLogo\">"
                + "<img src=\"../utility/ShowImage?id=" + navBarLogoId +"\" alt=\"NavBarLogo\">"
                + "</div></td>");
    }
    retval=Replace.replace(retval, "@INITSCRIPT@",initscript);
    retval=Replace.replace(retval, "@SCRIPTSET@",scriptset);
    retval=Replace.replace(retval, "@THEME@", theme);
    retval=Replace.replace(retval, "@LANGUAGE@", language);
    retval=Replace.replace(retval, "@FORMNAME@", formname);
    retval=Replace.replace(retval, "@TITLE@", title);
    retval=Replace.replace(retval, "@ICON@", icon);
    retval=Replace.replace(retval, "@MESSAGEBOX@", msgbox);
    retval=Replace.replace(retval, "@STDTARGET@", stdTargetURL);
    
   
    
    if (grid == null){
      rowkeyscript="null;";
    } else {
      for (int i = 0; i < grid.rowKeys.length; i++) {
        if (i>0)
          rowkeyscript=rowkeyscript + ",";
        rowkeyscript=rowkeyscript + "new SearchElements(\"" + grid.rowKeys[i].suffix + "\", true, keys[" + Integer.toString(i+2) + "])";
      }
    }   
    retval=Replace.replace(retval, "@ROWKEYS@", rowkeyscript );
    retval=Replace.replace(retval, "@FOCUSFIELD@", focusfield );
    return retval;
  }

  
  public static String printPageKey( VariablesSecureApp vars,HttpSecureAppServlet servlet,
      FieldProvider[] data,  DataGrid grid, String keycolumname) throws Exception {
    
    XmlDocument xmlDocument = servlet.xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/info/SearchUniqueKeyResponse").createXmlDocument();

    final DecimalFormat df = Utility.getFormat(vars, "priceEdition");
    final DecimalFormat qdf = Utility.getFormat(vars, "qtyEdition");
    StringBuilder html = new StringBuilder();
    html.append("\nfunction validateSelector() {\n");
    html.append("var key = \"" + data[0].getField(keycolumname) + "\";\n");
    html.append("var text = \"" + Replace.replace(data[0].getField("value") + " - " + data[0].getField("name"), "\"", "\\\"") + "\";\n");
    html.append("var parameter = new Array(\n");
    if (grid.rowKeys!=null){
      for (int l = 0; l < grid.rowKeys.length; l++) {
        if (l>0)
          html.append(",\n");
        if (grid.rowKeys[l].datatype.equals("DECIMAL"))
          html.append("new SearchElements(\"" + grid.rowKeys[l].suffix + "\", true, \"" + qdf.format(new BigDecimal(data[0].getField(grid.rowKeys[l].name))) + "\")");
        else 
          if (grid.rowKeys[l].datatype.equals("PRICE")) 
            html.append("new SearchElements(\"" +grid.rowKeys[l].suffix + "\", true, \"" + df.format(new BigDecimal(data[0].getField(grid.rowKeys[l].name))) + "\")");
             else 
               html.append("new SearchElements(\"" + grid.rowKeys[l].suffix + "\", true, \"" + data[0].getField(grid.rowKeys[l].name) + "\")");
      }
    }
    html.append(");\n");
    html.append("parent.opener.closeSearch(\"SAVE\", key, text, parameter);\n");
    html.append("}\n");
   
    xmlDocument.setParameter("script", html.toString());
    
    return xmlDocument.print();
  }
  
  public static String filterheight(HttpSecureAppServlet servlet,VariablesSecureApp vars,String filterfields, String filterheight) throws Exception {
	   String heighttable=ConfigureTableStructure.doConfigure(servlet, vars, "6", "", "Main");
	   heighttable = Replace.replace(heighttable, "@CONTENT@", filterfields);
	   String strTableStructure = "<div class=\"Popup_ContentPane_Client\" style=\"overflow: auto; auto; height:"
				+ filterheight + ";\" id=\"client_top\">\n" + heighttable + "</div>";
	   return strTableStructure;	   
	  }

}
