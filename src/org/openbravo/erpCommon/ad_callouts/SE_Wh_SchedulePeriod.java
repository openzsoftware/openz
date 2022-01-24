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
package org.openbravo.erpCommon.ad_callouts;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;

public class SE_Wh_SchedulePeriod extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strChanged = vars.getStringParameter("inpLastFieldChanged");
      if (log4j.isDebugEnabled())
        log4j.debug("CHANGED: " + strChanged);
      String strWhSchedule = vars.getStringParameter("inpmWhScheduleId");
      String strTabId = vars.getStringParameter("inpTabId");

      try {
        printPage(response, vars, strWhSchedule, strTabId);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars,
      String strWhSchedule, String strTabId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();

    InvoicingScheduleData[] data = InvoicingScheduleData.selectM_WH_Period_ID(this, Utility
        .getContext(this, vars, "#AccessibleOrgTree", "SE_Wh_SchedulePeriod"), Utility.getContext(
        this, vars, "#User_Client", "SE_Wh_SchedulePeriod"), strWhSchedule);
    StringBuffer resultado = new StringBuffer();
    if (data == null || data.length == 0)
      resultado.append("var respuesta = null;");
    else {
      resultado.append("var calloutName='SE_Wh_SchedulePeriod';\n\n");
      resultado.append("var respuesta = new Array(");
      resultado.append("new Array(\"inpPeriodFromId\", ");
      if (data != null && data.length > 0) {
        resultado.append("new Array(");
        for (int i = 0; i < data.length; i++) {
          resultado.append("new Array(\"" + data[i].id + "\", \""
              + FormatUtilities.replaceJS(data[i].name) + "\")");
          if (i < data.length - 1)
            resultado.append(",\n");
        }
        resultado.append("\n)");
      } else
        resultado.append("null");
      resultado.append("\n),");
      resultado.append("new Array(\"inpPeriodToId\", ");
      if (data != null && data.length > 0) {
        resultado.append("new Array(");
        for (int i = 0; i < data.length; i++) {
          resultado.append("new Array(\"" + data[i].id + "\", \""
              + FormatUtilities.replaceJS(data[i].name) + "\")");
          if (i < data.length - 1)
            resultado.append(",\n");
        }
        resultado.append("\n)");
      } else
        resultado.append("null");
      resultado.append("\n)");

      resultado.append(");");
    }
    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }
}
