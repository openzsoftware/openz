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
package org.openbravo.erpCommon.ad_actionButton;

//import com.sun.mail.smtp.SMTPMessage;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.EmailData;
import org.openbravo.erpCommon.reference.ActionButtonData;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;

public class RequestAction extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strProcessId = vars.getStringParameter("inpProcessId");
      String strWindow = vars.getStringParameter("inpwindowId");
      String strTab = vars.getStringParameter("inpTabId");
      String strKey = vars.getRequiredGlobalVariable("inprRequestId", strWindow + "|R_Request_ID");
      printPage(response, vars, strKey, strWindow, strTab, strProcessId);
    } else if (vars.commandIn("SAVE")) {
      String strWindow = vars.getStringParameter("inpwindowId");
      String strKey = vars.getRequestGlobalVariable("inprRequestId", strWindow + "|R_Request_ID");
      String strTab = vars.getStringParameter("inpTabId");

      ActionButtonDefaultData[] tab = ActionButtonDefaultData.windowName(this, strTab);
      String strTabName = "";
      if (tab != null && tab.length != 0) {
        strTabName = FormatUtilities.replace(tab[0].name);
      }
      String strWindowPath = Utility.getTabURL(this, strTab, "R");
      if (strWindowPath.equals(""))
        strWindowPath = strDefaultServlet;

      processButton(vars, strKey, strWindow);

      String pinstance = SequenceIdData.getUUID();
      PInstanceProcessData.insertPInstance(this, pinstance, "158", strKey, "N", vars.getUser(),
          vars.getClient(), vars.getOrg());

      ActionButtonData.process158(this, pinstance);

      PInstanceProcessData[] pinstanceData = PInstanceProcessData.select(this, pinstance);
      String messageResult = "";
      if (pinstanceData != null && pinstanceData.length > 0) {
        if (!pinstanceData[0].errormsg.equals("")) {
          String message = pinstanceData[0].errormsg;
          if (message.startsWith("@") && message.endsWith("@")) {
            message = message.substring(1, message.length() - 1);
            if (message.indexOf("@") == -1)
              messageResult = Utility.messageBD(this, message, vars.getLanguage());
            else
              messageResult = Utility.parseTranslation(this, vars, vars.getLanguage(), "@"
                  + message + "@");
          } else {
            messageResult = Utility.parseTranslation(this, vars, vars.getLanguage(), message);
          }
        } else if (!pinstanceData[0].pMsg.equals("")) {
          String message = pinstanceData[0].pMsg;
          messageResult = Utility.parseTranslation(this, vars, vars.getLanguage(), message);
        } else if (pinstanceData[0].result.equals("1")) {
          messageResult = Utility.messageBD(this, "Success", vars.getLanguage());
        } else {
          messageResult = Utility.messageBD(this, "Error", vars.getLanguage());
        }
      }
      messageResult = Replace.replace(messageResult, "'", "\\'");
      if (log4j.isDebugEnabled())
        log4j.debug(messageResult);
      vars.setSessionValue(strWindow + "|" + strTabName + ".message", messageResult);
      printPageClosePopUp(response, vars, strWindowPath);
    } else
      pageErrorPopUp(response);
  }

  private String processButton(VariablesSecureApp vars, String strKey, String windowId) {
    int i = 0;
    Connection conn = null;
    try {
      conn = getTransactionConnection();
      RequestActionData[] data = RequestActionData.select(conn, this, strKey);
      if (data == null || data.length == 0) {
        releaseRollbackConnection(conn);
        log4j.warn("Rollback in transaction");
        return Utility.messageBD(this, "ProcessRunError", vars.getLanguage());
      }
      vars.removeSessionValue("#User_EMail");
      vars.removeSessionValue("#User_EMailUser");
      vars.removeSessionValue("#User_EMailUserPw");
      vars.removeSessionValue("#Request_EMail");
      vars.removeSessionValue("#Request_EMailUser");
      vars.removeSessionValue("#Request_EMailUserPw");

      if (data[0].actiontype.equals("E")) {
        String smtpHost = EmailData.selectSMTPHost(conn, this, data[0].adClientId);
        String from = "";
        EmailData[] mails = EmailData.selectEmail(conn, this, data[0].salesrepId);
        if (mails == null || mails.length == 0) {
          mails = EmailData.selectEmailRequest(conn, this, data[0].adClientId);
          if (mails != null && mails.length > 0) {
            from = mails[0].email;
            from = from.trim().toLowerCase();
            for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" "))
              from = from.substring(0, pos) + from.substring(pos + 1);
            vars.setSessionValue("#Request_EMail", from);
            vars.setSessionValue("#Request_EMailUser", mails[0].emailuser);
            vars.setSessionValue("#Request_EMailUserPw", mails[0].emailuserpw);
          }
        } else {
          from = mails[0].email;
          from = from.trim().toLowerCase();
          for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" "))
            from = from.substring(0, pos) + from.substring(pos + 1);
          vars.setSessionValue("#User_EMail", from);
          vars.setSessionValue("#User_EMailUser", mails[0].emailuser);
          vars.setSessionValue("#User_EMailUserPw", mails[0].emailuserpw);
        }

        if (from.equals("")) {
          from = System.getProperty("user.name") + "@"
              + Utility.getContext(this, vars, "#AD_Client_Name", windowId) + ".com";
          from = from.trim().toLowerCase();
          for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" "))
            from = from.substring(0, pos) + from.substring(pos + 1);
        }
        String to = RequestActionData.selectEmailTo(conn, this, (data[0].adUserId.equals("0") ? ""
            : data[0].adUserId), data[0].cBpartnerId);
        String msg = "OK";
        if (log4j.isDebugEnabled())
          log4j
              .debug("*************************************************************************************************");
        if (log4j.isDebugEnabled())
          log4j.debug(smtpHost + "\n" + from + "\n" + to + "\n" + data[0].mailsubject + "\n"
              + data[0].mailtext);
        if (log4j.isDebugEnabled())
          log4j
              .debug("*************************************************************************************************");
        EmailData[] maildata=EmailData.selectEmailRequest(conn, myPool, vars.getClient());
      //  EMail email = new EMail(vars, smtpHost, from, to, null,data[0].mailsubject, data[0].mailtext,maildata[0].usetls,maildata[0].usessl,maildata[0].smtpport);
      //  msg = email.send();
        if ("OK".equals(msg)) {
          RequestActionData.update(conn, this, Utility.messageBD(this, "RequestActionEMailOK", vars
              .getLanguage()), strKey);
        } else {
          RequestActionData.update(conn, this, Utility.messageBD(this, "RequestActionEMailError",
              vars.getLanguage())
              + " - " + msg, strKey);
        }
      } else if (data[0].actiontype.equals("T")) {
        String subject = Utility.messageBD(this, "RequestActionTransfer", vars.getLanguage());

        RequestActionData.update(conn, this, subject, strKey);
        String smtpHost = EmailData.selectSMTPHost(conn, this, data[0].adClientId);
        String to = "";
        EmailData[] dataTo = EmailData.selectEmail(conn, this, data[0].adUserId);
        if (dataTo != null && dataTo.length > 0) {
          to = dataTo[0].email;
        }
        to = to.trim().toLowerCase();
        for (int pos = to.indexOf(" "); pos != -1; pos = to.indexOf(" "))
          to = to.substring(0, pos) + to.substring(pos + 1);

        if (to.equals("")) {
          to = System.getProperty("user.name") + "@"
              + Utility.getContext(this, vars, "#AD_Client_Name", windowId) + ".com";
          to = to.trim().toLowerCase();
          for (int pos = to.indexOf(" "); pos != -1; pos = to.indexOf(" "))
            to = to.substring(0, pos) + to.substring(pos + 1);
        }
        String from = "";
        EmailData[] mails = EmailData.selectEmail(conn, this, data[0].updatedby);
        if (mails == null || mails.length == 0) {
          mails = EmailData.selectEmailRequest(conn, this, data[0].adClientId);
          if (mails != null && mails.length > 0) {
            from = mails[0].email;
            from = from.trim().toLowerCase();
            for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" "))
              from = from.substring(0, pos) + from.substring(pos + 1);
            vars.setSessionValue("#Request_EMail", from);
            vars.setSessionValue("#Request_EMailUser", mails[0].emailuser);
            vars.setSessionValue("#Request_EMailUserPw", mails[0].emailuserpw);
          }
        } else {
          from = mails[0].email;
          from = from.trim().toLowerCase();
          for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" "))
            from = from.substring(0, pos) + from.substring(pos + 1);
          vars.setSessionValue("#User_EMail", from);
          vars.setSessionValue("#User_EMailUser", mails[0].emailuser);
          vars.setSessionValue("#User_EMailUserPw", mails[0].emailuserpw);
        }

        if (from.equals("")) {
          from = System.getProperty("user.name") + "@"
              + Utility.getContext(this, vars, "#AD_Client_Name", windowId) + ".com";
          from = from.trim().toLowerCase();
          for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" "))
            from = from.substring(0, pos) + from.substring(pos + 1);
        }
        String message = subject + "\n" + data[0].summary;
        if (log4j.isDebugEnabled())
          log4j
              .debug("*************************************************************************************************");
        if (log4j.isDebugEnabled())
          log4j.debug(smtpHost + "\n" + from + "\n" + to + "\n" + subject + "\n" + message);
        if (log4j.isDebugEnabled())
          log4j
              .debug("*************************************************************************************************");
      //  EmailData[] maildata=EmailData.selectEmailRequest(conn, myPool, vars.getClient());
      //  EMail email = new EMail(vars, smtpHost, from, to, null,subject, message,maildata[0].usetls,maildata[0].usessl,maildata[0].smtpport);
      //  email.send();
      }

      releaseCommitConnection(conn);
    } catch (Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      return Utility.messageBD(this, "ProcessRunError", vars.getLanguage());
    }
    return (Utility.messageBD(this, "RecordsCopied", vars.getLanguage()) + i);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strKey,
      String windowId, String strTab, String strProcessId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Button process Copy from Invoice");

    ActionButtonDefaultData[] data = null;
    String strHelp = "", strDescription = "";
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
        "org/openbravo/erpCommon/ad_actionButton/RequestAction", discard).createXmlDocument();
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("window", windowId);
    xmlDocument.setParameter("tab", strTab);
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("question", Utility.messageBD(this, "StartProcess?", vars
        .getLanguage()));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("description", strDescription);
    xmlDocument.setParameter("help", strHelp);

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet Copy from invoice";
  } // end of getServletInfo() method
}
