/*
 ***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
 */
package org.openbravo.erpCommon.security;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Enumeration;

import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.HttpBaseServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.view.MobileHelper;

public class Login_ResetPassword extends HttpBaseServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
      // reset password only allowed when mfa is enabled
      if(!SessionLoginData.isMFAActivated(this, "").equals("Y")) {
          response.sendRedirect(response.encodeRedirectURL(strDireccion + "/security/Login_FS.html"));
          return;
      }
    VariablesSecureApp vars = new VariablesSecureApp(request);
    Cookie[] cooks=request.getCookies();
    String permsession="";
    if (cooks!=null) {
	    for (int i=0;i<cooks.length;i++) {
	    	if (cooks[i].getName().equals("permsession")) {
	    		permsession=cooks[i].getValue();
	    	}
	    }
    }

    if (log4j.isDebugEnabled())
      log4j.debug("Command: Login");
    String strTheme = SessionLoginData.selectDefaultTheme(this);
    strTheme = "ltr/" + strTheme;
    vars.clearSession(false);
    printPageIdentificacion(response, request, strTheme, permsession);

  }


  private void printPageIdentificacion(HttpServletResponse response,HttpServletRequest request, String strTheme, String permsession)
      throws IOException, ServletException {
	XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/security/Login_ResetPassword").createXmlDocument();
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", strTheme);
    xmlDocument.setParameter("itService", SessionLoginData.selectSupportContact(this));
    xmlDocument.setParameter("versionNo", SessionLoginData.selectVersion(this));
    xmlDocument.setParameter("permsession",permsession);

    final String lang = SessionLoginData.getDefaultLanguage(this);
    String xmloutput = xmlDocument.print();
    // translation
    xmloutput = xmloutput
                  .replaceAll("@requestPasswordResetText@", Utility.messageBD(this, "requestPasswordResetText", lang))
                  .replaceAll("@username@", Utility.messageBD(this, "username", lang))
                  .replaceAll("@email@", Utility.messageBD(this, "email", lang))
                  .replaceAll("@back@", Utility.messageBD(this, "back", lang))
                  .replaceAll("@reset@", Utility.messageBD(this, "reset", lang));

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmloutput);
    out.close();
  }


  public String getServletInfo() {
    return "Login servlet";
  }
}
