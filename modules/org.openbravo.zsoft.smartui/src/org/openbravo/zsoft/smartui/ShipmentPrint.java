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
package org.openbravo.zsoft.smartui;

import java.io.IOException;
import java.util.HashMap;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.xml.JRXmlLoader;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

public class ShipmentPrint extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  private static Logger log4j = Logger.getLogger(Smartprefs.class);

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
        String   strcMinoutId = vars.getSessionValue("ShipmentPrint.inpMinoutId");
        strcMinoutId =strcMinoutId.replace("(", "");
        strcMinoutId =strcMinoutId.replace("'","");
        strcMinoutId =strcMinoutId.replace(")","");
      if (log4j.isDebugEnabled())
        log4j.debug("strcMinoutId" + strcMinoutId);
      printPagePartePDF(response, vars, strcMinoutId);
    } else
      pageError(response);
  }

  private void printPagePartePDF(HttpServletResponse response, VariablesSecureApp vars,
      String strcMinoutId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: pdf");
    String strLanguage = vars.getLanguage();
    String strBaseDesign = getBaseDesignPath(strLanguage);

    HashMap<String, Object> parameters = new HashMap<String, Object>();
    
    parameters.put("DOCUMENT_ID", strcMinoutId);
    
    String strReportName = strBaseDesign + "/org/openbravo/zsoft/smartui/printing/ShipmentPrint.jrxml";
    response.setHeader("Content-disposition", "inline; filename=ShipmentPrint.pdf");
    renderJR(vars, response, strReportName, "pdf", parameters, null, null);
    
  }

  public String getServletInfo() {
    return "Servlet that presents the Shipments Prinout";
  } // End of getServletInfo() method
}