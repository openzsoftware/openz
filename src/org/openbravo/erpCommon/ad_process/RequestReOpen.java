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
package org.openbravo.erpCommon.ad_process;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.ad_actionButton.ActionButtonDefaultData;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;

public class RequestReOpen extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      printPage(response, vars);
    } else if (vars.commandIn("SAVE")) {
      String strRequest = vars.getRequiredStringParameter("inprRequestId");
      // new message system
      OBError myMessage = processSave(vars, strRequest);
      // if (!strMessage.equals(""))
      // vars.setSessionValue("RequestReOpen.message", strMessage);
      vars.setMessage("RequestReOpen", myMessage);
      printPage(response, vars);
    } else
      pageErrorPopUp(response);
  }

  private OBError processSave(VariablesSecureApp vars, String strRequest) {
    OBError myMessage = null;
    myMessage = new OBError();
    myMessage.setTitle("");
    if (log4j.isDebugEnabled())
      log4j.debug("Save: RequestReOpen");
    if (strRequest.equals("")) {
      myMessage.setType("Success");
      myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
      return myMessage;
      // return "";
    }
    try {
      String pinstance = SequenceIdData.getUUID();
      PInstanceProcessData.insertPInstance(this, pinstance, "195", strRequest, "N", vars.getUser(),
          vars.getClient(), vars.getOrg());
      PInstanceProcessData.insertPInstanceParam(this, pinstance, "10", "R_Request_ID", strRequest,
          vars.getClient(), vars.getOrg(), vars.getUser());
      RequestReOpenData.processRequest(this, pinstance);
    } catch (ServletException e) {
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, "ProcessRunError", vars.getLanguage()));
      return myMessage;
      // return Utility.messageBD(this, "ProcessRunError",
      // vars.getLanguage());
    }
    myMessage.setType("Success");
    myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    return myMessage;
    // return Utility.messageBD(this, "Success", vars.getLanguage());
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: process RequestReOpen");
    ActionButtonDefaultData[] data = null;
    String strHelp = "", strDescription = "", strProcessId = "195";
    if (vars.getLanguage().equals("en_US"))
      data = ActionButtonDefaultData.select(this, strProcessId);
    else
      data = ActionButtonDefaultData.selectLanguage(this, vars.getLanguage(), strProcessId);
    if (data != null && data.length != 0) {
      strDescription = data[0].description;
      strHelp = data[0].help;
    }
    String[] discard = { "" };
    if (strHelp.equals(""))
      discard[0] = new String("helpDiscard");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_process/RequestReOpen").createXmlDocument();

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "RequestReOpen", false, "", "", "",
        false, "ad_process", strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());

    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("question", Utility.messageBD(this, "StartProcess?", vars
        .getLanguage()));
    xmlDocument.setParameter("description", strDescription);
    xmlDocument.setParameter("help", strHelp);
    // new message system
    /*
     * String strMessage = vars.getSessionValue("RequestReOpen.message"); if
     * (!strMessage.equals("")) { vars.removeSessionValue("RequestReOpen.message"); strMessage =
     * "alert('" + Replace.replace(strMessage, "'", "\'") + "');"; }
     * xmlDocument.setParameter("body", strMessage);
     */
    {
      OBError myMessage = vars.getMessage("RequestReOpen");
      vars.removeMessage("RequestReOpen");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet RequestReOpen";
  } // end of getServletInfo() method
}
