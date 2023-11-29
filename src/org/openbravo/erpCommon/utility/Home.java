/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html 
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License. 
 * The Original Code is Openbravo ERP. 
 * The Initial Developer of the Original Code is Openbravo SL 
 * All portions are Copyright (C) 2001-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.utility;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.security.SessionLoginData;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;

public class Home extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      printPage(response, vars);
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/utility/Home")
        .createXmlDocument();
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());
    LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "Home.html", strReplaceWith);
    xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();

    String output = xmlDocument.print();
    String navBarLogoId = SessionLoginData.getCustomizedNavBarLogo(this);
    String navBarLogoIdOrg = SessionLoginData.getCustomizedNavBarLogoFromOrg(this, vars.getOrg());
    // org logo overwrites client logo overwrites standard logo
    if(!navBarLogoIdOrg.isEmpty()) {
        navBarLogoId = navBarLogoIdOrg;
    }
    if(navBarLogoId.isEmpty()) {
        output = Replace.replace(output, "@openbravonavbarlogo@",
                  "<TD class=\"Popup_NavBar_bg_logo\" width=\"1\" onclick=\"openNewBrowser('http://www.openbravo.com', 'Openbravo');return false;\"><IMG src=\"../web/images/blank.gif\" alt=\"Openbravo\" title=\"Openbravo\" border=\"0\" id=\"openbravoLogo\" class=\"Popup_NavBar_logo\"></TD>");
    }else {
        output = Replace.replace(output, "@openbravonavbarlogo@",
                  "<td class=\"Main_NavBar_bg_logo\" width=\"1\"><div class=\"Main_NavBar_logo_custom\" alt=\"NavBarLogo\" title=\"NavBarLogo\" border=\"0\" id=\"NavBarLogo\">"
                + "<img src=\"../utility/ShowImage?id=" + navBarLogoId +"\" alt=\"NavBarLogo\">"
                + "</div></td>");
    }

    out.println(output);
    out.close();
  }
}
