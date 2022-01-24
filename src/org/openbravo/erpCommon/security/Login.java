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

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.HttpBaseServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.view.MobileHelper;

public class Login extends HttpBaseServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    //String test=request.getQueryString(); //request.getRequestURI();
    //localhost:8080/openz/security/Login_FS.html?impa=1&inpb=2
    if (vars.commandIn("LOGIN")) {
      if (log4j.isDebugEnabled())
        log4j.debug("Command: Login");
      String strTheme = SessionLoginData.selectDefaultTheme(this);
      strTheme = "ltr/" + strTheme;
      vars.clearSession(false);
      printPageIdentificacion(response,request, strTheme);

      // } else if (vars.commandIn("OPTIONS")) {
      // if (vars.getUser().equals("")) printPageIdentificacion(response);
      // else printPageOptions(response, vars);

    } else if (vars.commandIn("BLANK")) {
      printPageBlank(response, vars);
    } else if (vars.commandIn("CHECK")) {
      String checkString = "success";
      response.setContentType("text/plain; charset=UTF-8");
      response.setHeader("Cache-Control", "no-cache");
      PrintWriter out = response.getWriter();
      out.print(checkString);
      out.close();
    } else if (vars.commandIn("WELCOME")) {
      String strTheme = SessionLoginData.selectDefaultTheme(this);
      strTheme = "ltr/" + strTheme;
      if (log4j.isDebugEnabled())
        log4j.debug("Command: Welcome");
      printPageWelcome(response, strTheme);
    } else if (vars.commandIn("LOGO")) {
      printPageLogo(response, vars);

      // } else if (vars.commandIn("LOGED")) {
      // String target = vars.getSessionValue("target");
      // printPageFrameIdentificacion(response,
      // "../utility/VerticalMenu.html",
      // (target.equals("")?"../utility/Home.html":target));
      //
      // } else if (vars.commandIn("CLOSE_SESSION")) {
      // vars.clearSession(true);
      // if (log4j.isDebugEnabled()) log4j.debug("Cerrando session");
      // if (!vars.getDBSession().equals(""))
      // SessionLoginData.saveProcessed(this, vars.getUser(),
      // vars.getDBSession());
      // response.sendRedirect(strDireccion + request.getServletPath());

    } else {
      String textDirection = vars.getSessionValue("#TextDirection", "LTR");
      String strDidl=request.getRequestURI();
      printPageFrameIdentificacion(response, "Login_Welcome.html?Command=WELCOME",
          "Login_F1.html?Command=LOGIN", textDirection,strDidl);
    }
  }

  private void printPageFrameIdentificacion(HttpServletResponse response, String strMenu,
      String strDetalle, String textDirection, String didl) throws IOException, ServletException {

    XmlDocument xmlDocument;
    if (textDirection.equals("RTL")) {
      xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/security/Login_FS_RTL")
          .createXmlDocument();
      xmlDocument.setParameter("frameMenu", strMenu);
      xmlDocument.setParameter("frameMenuLoading", strDetalle);
      xmlDocument.setParameter("frame1", strMenu);
    } else {
      if (didl.contains("Login_FX.html"))
    	  xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/security/Login_FX")
          .createXmlDocument();
      else
    	  xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/security/Login_FS")
          .createXmlDocument();
      xmlDocument.setParameter("frameMenu", strMenu);
      xmlDocument.setParameter("frameMenuLoading", strMenu);
      xmlDocument.setParameter("frame1", strDetalle);
    }

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageBlank(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {
    XmlDocument xmlDocument = xmlEngine
        .readXmlTemplate("org/openbravo/erpCommon/security/Login_F0").createXmlDocument();

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageWelcome(HttpServletResponse response, String strTheme) throws IOException,
      ServletException {
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/security/Login_Welcome").createXmlDocument();

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", strTheme);

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageLogo(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/security/Login_Logo").createXmlDocument();

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageIdentificacion(HttpServletResponse response,HttpServletRequest request, String strTheme)
      throws IOException, ServletException {
	XmlDocument xmlDocument;
	if (MobileHelper.isMobile(request))
        xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/security/Login_F1_mobile").createXmlDocument();
	else
		xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/security/Login_F1").createXmlDocument();
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", strTheme);
    xmlDocument.setParameter("itService", SessionLoginData.selectSupportContact(this));
    xmlDocument.setParameter("versionNo", SessionLoginData.selectVersion(this));

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void goToRetry(HttpServletResponse res) throws IOException {
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/HtmlErrorLogin").createXmlDocument();

    res.setContentType("text/html");
    PrintWriter out = res.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  // public void printPageOptions(HttpServletResponse response,
  // VariablesSecureApp vars) throws IOException, ServletException {
  // XmlDocument xmlDocument =
  // xmlEngine.readXmlTemplate("org/openbravo/erpCommon/security/Login_Options_F1").createXmlDocument
  // ();
  //    
  // RoleComboData[] data = RoleComboData.select(this, vars.getUser());
  // if (data==null || data.length==0) {
  // goToRetry(response);
  // return;
  // }
  // xmlDocument.setParameter("language", "defaultLang=\"" +
  // vars.getLanguage() + "\";");
  // ClientData[] clients = null;
  // {
  // ClientData[] data1 = ClientData.select(this);
  // if (data1==null || data1.length==0) {
  // bdError(response, "NoClientLogin", vars.getLanguage());
  // return;
  // } else {
  // Vector<Object> vecClients = new Vector<Object>();
  // for (int i=0;i<data.length;i++) {
  // StringTokenizer st = new StringTokenizer(data[i].clientlist, ",", false);
  //    
  // while (st.hasMoreTokens()) {
  // String token = st.nextToken().trim();
  // ClientData auxClient = new ClientData();
  // auxClient.padre = data[i].adRoleId;
  // auxClient.id = token;
  // auxClient.name = getDescriptionFromArray(data1, token);
  // vecClients.addElement(auxClient);
  // }
  // }
  // clients = new ClientData[vecClients.size()];
  // vecClients.copyInto(clients);
  // }
  // xmlDocument.setParameter("clientes", arrayDobleEntrada("arrClientes",
  // clients));
  // }
  // {
  // OrganizationData[] data1 = OrganizationData.select(this);
  // if (data1==null || data1.length==0) {
  // bdError(response, "NoOrgLogin", vars.getLanguage());
  // return;
  // }
  // xmlDocument.setParameter("organizaciones", arrayDobleEntrada("arrOrgs",
  // data1));
  // }
  // xmlDocument.setParameter("warehouses", arrayDobleEntrada("arrWare",
  // WarehouseData.select(this)));
  // xmlDocument.setData("structureRol", data);
  // ClientComboData[] clientCombo = null;
  // {
  // Vector<Object> vecClientCombo = new Vector<Object>();
  // for (int i=0;i<clients.length;i++) {
  // if (clients[i].padre.equals(data[0].adRoleId)) {
  // ClientComboData auxCombo = new ClientComboData();
  // auxCombo.adClientId = clients[i].id;
  // auxCombo.name = clients[i].name;
  // vecClientCombo.addElement(auxCombo);
  // }
  // }
  // clientCombo = new ClientComboData[vecClientCombo.size()];
  // vecClientCombo.copyInto(clientCombo);
  // }
  // xmlDocument.setData("structureCliente", clientCombo);
  // xmlDocument.setData("structureOrganizacion",
  // OrganizationComboData.select(this, data[0].adRoleId));
  // xmlDocument.setData("structureAlmacen", WarehouseComboData.select(this,
  // data[0].adRoleId, data[0].adClientId));
  //
  // response.setContentType("text/html; charset=UTF-8");
  // PrintWriter out = response.getWriter();
  // out.println(xmlDocument.print());
  // out.close();
  // }

  private void bdError(HttpServletResponse response, String strCode, String strLanguage)
      throws IOException {
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/base/secureApp/Error")
        .createXmlDocument();

    xmlDocument.setParameter("ParamTitulo", strCode);
    xmlDocument.setParameter("ParamTexto", Utility.messageBD(this, strCode, strLanguage));
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Login servlet";
  }
}
