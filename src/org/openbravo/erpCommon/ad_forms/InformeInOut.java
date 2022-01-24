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
package org.openbravo.erpCommon.ad_forms;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.xmlEngine.XmlDocument;

public class InformeInOut extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strDesde = vars.getStringParameter("inpDesde", DateTimeData.today(this));
      String strHasta = vars.getStringParameter("inpHasta", DateTimeData.today(this));
      printPageSelector(response, vars, strDesde, strHasta);
    } else if (vars.commandIn("FIND")) {
      String strDesde = vars.getStringParameter("inpDesde");
      String strHasta = vars.getStringParameter("inpHasta");
      setHistoryCommand(request, "DEFAULT");
      String strCategoriaProducto = vars.getStringParameter("inpClaveCategoriaProducto", "");
      printPage(response, vars, strDesde, strHasta, strCategoriaProducto);
    } else
      pageError(response);
  }

  private void printPageSelector(HttpServletResponse response, VariablesSecureApp vars,
      String strDesde, String strHasta) throws IOException, ServletException {
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_forms/InformeInOut").createXmlDocument();
    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("fechaDesde", strDesde);
    xmlDocument.setParameter("fechaHasta", strHasta);
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setData("reportCategoriaProducto", "structure1", CategoriaProductoComboData
        .select(this));
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strDesde,
      String strHasta, String strCategoriaProducto) throws IOException, ServletException {
    response.setContentType("application/xls");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_forms/InformeInOut_Excel").createXmlDocument();
    xmlDocument.setData("structure1", InformeInOutData.select(this, vars.getSqlDateFormat(),
        strHasta, strDesde, strCategoriaProducto));

    response.setContentType("application/xls");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet for the media reports generation";
  } // end of getServletInfo() method
}
