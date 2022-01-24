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
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;

public class SE_Proposal_BPartner extends HttpSecureAppServlet {
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
      String strBPartner = vars.getStringParameter("inpcBpartnerId");
      String strLocation = vars.getStringParameter("inpcBpartnerId_LOC");
      String strContact = vars.getStringParameter("inpcBpartnerId_CON");
      String strWindowId = vars.getStringParameter("inpwindowId");
      String strTabId = vars.getStringParameter("inpTabId");

      try {
        printPage(response, vars, strBPartner, strWindowId, strLocation, strContact, strTabId);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strBPartner,
      String strWindowId, String strLocation, String strContact, String strTabId)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();

    StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='SE_Order_BPartner';\n\n");
    resultado.append("var respuesta = new Array(");
    String strPaymentRule = SEProposalBPartnerData.selectPaymentRule(this, strBPartner);
    resultado.append("new Array(\"inppaymentrule\", \"" + strPaymentRule + "\"),");
    String strPaymentTerm = SEProposalBPartnerData.selectPaymentTerm(this, strBPartner);
    resultado.append("new Array(\"inpcPaymenttermId\", \"" + strPaymentTerm + "\"),");
    FieldProvider[] tdv = null;
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR",
          "C_BPartner_Location_ID", "", "C_BPartner Location - Ship To", Utility.getContext(this,
              vars, "#AccessibleOrgTree", strWindowId), Utility.getContext(this, vars,
              "#User_Client", strWindowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, strWindowId, "");
      tdv = comboTableData.select(false);
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    resultado.append("new Array(\"inpcBpartnerLocationId\", ");
    if (tdv != null && tdv.length > 0) {
      resultado.append("new Array(");
      for (int i = 0; i < tdv.length; i++) {
        resultado.append("new Array(\"" + tdv[i].getField("id") + "\", \""
            + FormatUtilities.replaceJS(tdv[i].getField("name")) + "\", \""
            + (tdv[i].getField("id").equalsIgnoreCase(strLocation) ? "true" : "false") + "\")");
        if (i < tdv.length - 1)
          resultado.append(",\n");
      }
      resultado.append("\n)");
    } else
      resultado.append("null");
    resultado.append("\n),");
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_User_ID", "",
          "AD_User C_BPartner User/Contacts", Utility.getContext(this, vars, "#AccessibleOrgTree",
              strWindowId), Utility.getContext(this, vars, "#User_Client", strWindowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, strWindowId, "");
      tdv = comboTableData.select(false);
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    resultado.append("new Array(\"inpadUserId\", ");
    if (tdv != null && tdv.length > 0) {
      resultado.append("new Array(");
      for (int i = 0; i < tdv.length; i++) {
        resultado.append("new Array(\"" + tdv[i].getField("id") + "\", \""
            + FormatUtilities.replaceJS(tdv[i].getField("name")) + "\", \""
            + (tdv[i].getField("id").equalsIgnoreCase(strContact) ? "true" : "false") + "\")");
        if (i < tdv.length - 1)
          resultado.append(",\n");
      }
      resultado.append("\n)");
    } else
      resultado.append("null");
    resultado.append("\n)");

    resultado.append(");");
    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }
}
