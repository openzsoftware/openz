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

public class SL_Request_Action extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strWindowId = vars.getStringParameter("inpwindowId");
      String strActionType = vars.getStringParameter("inpactiontype");
      String strCBPartnerID = vars.getRequestGlobalVariable("inpcBpartnerId", strWindowId
          + "|C_BPartner_ID");
      String strTabId = vars.getStringParameter("inpTabId");
      try {
        printPage(response, vars, strCBPartnerID, vars.getClient(), vars.getUser(), strActionType,
            strTabId);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }

    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars,
      String strCBPartnerID, String strClient, String strUser, String strActionType, String strTabId)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();

    StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='SL_Request_Action';\n\n");
    resultado.append("var respuesta = new Array(");

    String strMessage = "";
    if (strActionType.equals("E")) {
      String strSMTPHost = SLRequestActionData.SMTPHost(this, strClient);
      if (strSMTPHost.equals(""))
        strMessage += Utility.messageBD(this, "SMTPHostError", vars.getLanguage());

      String strBPemail = SLRequestActionData.BPemail(this, strCBPartnerID, strUser);
      if (strBPemail.equals(""))
        strMessage += Utility.messageBD(this, "BPemailError", vars.getLanguage());

      SLRequestActionData[] data = SLRequestActionData.select(this, strUser);
      if (data == null || data.length == 0)
        strMessage += Utility.messageBD(this, "UserMailInfoError", vars.getLanguage());
      else {
        if (data[0].email == null || data[0].email.equals(""))
          strMessage += Utility.messageBD(this, "UserMailError", vars.getLanguage());
        if (data[0].emailuser == null || data[0].emailuser.equals(""))
          strMessage += Utility.messageBD(this, "eMailUserError", vars.getLanguage());
        if (data[0].emailuserpw == null || data[0].emailuserpw.equals(""))
          strMessage += Utility.messageBD(this, "eMailUserPWError", vars.getLanguage());
      }

      if (strMessage != null && !strMessage.equals(""))
        resultado.append("new Array(\"MESSAGE\", \"" + FormatUtilities.replaceJS(strMessage)
            + "\")");
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
