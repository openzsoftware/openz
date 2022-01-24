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
 * All portions are Copyright (C) 2008-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.ad_callouts;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.xmlEngine.XmlDocument;

public class SE_PeriodNo extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strOrgId = vars.getStringParameter("inpadOrgId");
      String strCalendarId = vars.getStringParameter("inpcCalendarId");
      String strChanged = vars.getStringParameter("inpLastFieldChanged");
      String strYearId = vars.getStringParameter("inpcYearId");
      String strWindowId = vars.getStringParameter("inpwindowId");
      try {
        printPage(response, vars, strYearId, strWindowId, strOrgId, strCalendarId, strChanged);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strYearId,
      String strWindowId, String strOrgId, String strCalendarId, String strChanged)
      throws IOException, ServletException {

    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();

    StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='SE_PeriodNo';\n\n");
    resultado.append("var respuesta = new Array(");

    if (strChanged.equals("inpcYearId") && !strYearId.equals("")) {
      SEPeriodNoData[] tdv = null;
      // Update the Periods
      try {
        tdv = SEPeriodNoData.getPeriodNo(this, strYearId);
      } catch (Exception ex) {
        throw new ServletException(ex);
      }

      resultado.append("new Array(\"inpperiodno\", ");
      if (tdv != null && tdv.length > 0) {
        resultado.append("new Array(");
        for (int i = 0; i < tdv.length; i++) {
          resultado.append("new Array(\"" + tdv[i].getField("id") + "\", \""
              + tdv[i].getField("Name") + "\")");
          if (i < tdv.length - 1)
            resultado.append(",\n");
        }
        resultado.append("\n)");
      } else
        resultado.append("null");
      resultado.append("\n)");
    } else if (!strOrgId.equals("")) {
      SEPeriodNoData[] tdv = null;
      // Update the Calendar
      try {
        tdv = SEPeriodNoData.getCalendar(this, strOrgId);
      } catch (Exception ex) {
        throw new ServletException(ex);
      }
      resultado.append("new Array(\"inpcCalendarId\", ");
      if (tdv != null && tdv.length > 0) {
        resultado.append("new Array(");
        for (int i = 0; i < tdv.length; i++) {
          resultado.append("new Array(\"" + tdv[i].getField("id") + "\", \""
              + tdv[i].getField("Name") + "\")");
          strCalendarId = tdv[i].getField("id");
          if (i < tdv.length - 1)
            resultado.append(",\n");
        }
        resultado.append("\n)");
      } else
        resultado.append("null");
      resultado.append("\n),");

      // Update the years
      try {
        tdv = SEPeriodNoData.getYears(this, strCalendarId);
      } catch (Exception ex) {
        throw new ServletException(ex);
      }

      String strLastYear = "";
      resultado.append("new Array(\"inpcYearId\", ");
      if (tdv != null && tdv.length > 0) {
        resultado.append("new Array(");
        for (int i = 0; i < tdv.length; i++) {
          resultado.append("new Array(\"" + tdv[i].getField("id") + "\", \""
              + tdv[i].getField("Name") + "\", \"" + (i == 0 ? "true" : "false") + "\")");
          if (i == 0)
            strLastYear = tdv[i].getField("id");
          if (i < tdv.length - 1)
            resultado.append(",\n");
        }
        resultado.append("\n)");
      } else
        resultado.append("null");
      resultado.append("\n),");

      // Update the Periods
      try {
        tdv = SEPeriodNoData.getPeriodNo(this, strLastYear);
      } catch (Exception ex) {
        throw new ServletException(ex);
      }

      resultado.append("new Array(\"inpperiodno\", ");
      if (tdv != null && tdv.length > 0) {
        resultado.append("new Array(");
        for (int i = 0; i < tdv.length; i++) {
          resultado.append("new Array(\"" + tdv[i].getField("id") + "\", \""
              + tdv[i].getField("Name") + "\")");
          if (i < tdv.length - 1)
            resultado.append(",\n");
        }
        resultado.append("\n)");
      } else
        resultado.append("null");
      resultado.append("\n)");
    }

    resultado.append(");");
    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

}
