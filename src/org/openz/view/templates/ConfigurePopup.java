package org.openz.view.templates;
/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A Heuduk.
***************************************************************************************************************************************************
*/
import java.io.IOException;
import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openz.util.LocalizationUtils;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.security.SessionLoginData;
import org.openz.view.Scripthelper;
import org.openz.util.LocalizationUtils;
import java.sql.Connection;
public class ConfigurePopup{
 
  
	  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script, String title, String focusfield) throws Exception{
	        String retval="";
		    Connection conn = null;
		    String scriptset="";
		    String msgbox="";
		    String theme=vars.getTheme();
		    String language=vars.getLanguage();
		    final String directory= servlet.strBasePath;
		    Object template =  servlet.getServletContext().getAttribute("popupTEMPLATE");
		    if (template==null) {
		      template = new String(FileUtils.readFile("Popup.xml", directory + "/src-loc/design/org/openz/view/templates/"));
		      servlet.getServletContext().setAttribute("popupTEMPLATE", template);
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

            title=LocalizationUtils.getElementTextByElementName(servlet, title, vars.getLanguage());

		    retval=Replace.replace(retval, "@TITLE@", title);
		    retval=Replace.replace(retval, "@SCRIPTSET@",scriptset);
		    retval=Replace.replace(retval, "@THEME@", theme);
		    retval=Replace.replace(retval, "@LANGUAGE@", language);
		    retval=Replace.replace(retval, "@MESSAGEBOX@", msgbox);
		    retval=Replace.replace(retval, "@FOCUSFIELD@", focusfield );
		   // retval=Replace.replace(retval, "@ADDITIONALSCRIPTS@", additionalscripts );
		    return retval;
		  }
		    
		}