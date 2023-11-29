/*
 ******************************************************************************
 * The contents of this file are subject to the   Compiere License  Version 1.1
 * ("License"); You may not use this file except in compliance with the License
 * You may obtain a copy of the License at http://www.compiere.org/license.html
 * Software distributed under the License is distributed on an  "AS IS"  basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 * The Original Code is                  Compiere  ERP & CRM  Business Solution
 * The Initial Developer of the Original Code is Jorg Janke  and ComPiere, Inc.
 * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke, parts
 * created by ComPiere are Copyright (C) ComPiere, Inc.;   All Rights Reserved.
 * Contributor(s): Openbravo SL
 * Contributions are Copyright (C) 2001-2009 Openbravo S.L.
 ******************************************************************************
 */
package org.openbravo.erpCommon.ad_process;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;

import javax.mail.Session;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.FileUtils;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.ad_actionButton.ActionButtonDefaultData;
import org.openbravo.erpCommon.businessUtility.EmailData;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.erpCommon.utility.poc.EmailManager;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.UtilsData;

public class SendMailText extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  private enum resultEnum {
    SUCCESS, INFO, ERRORS
  };

  private resultEnum mailResult = resultEnum.SUCCESS;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    OBError myMessage = new OBError();
    vars.setMessage("SendMailText", myMessage);

    if (vars.commandIn("DEFAULT")) {
      String strMailTemplate = vars.getGlobalVariable("inpMailTemplate",
          "SendMailText|mailTemplate", "");
      String strInterestArea = vars.getGlobalVariable("inpInterestArea",
          "SendMailText|interestArea", "");
      String strBPGroup = vars.getGlobalVariable("inpBPGroup", "SendMailText|bpGroup", "");
      String strUser = vars.getGlobalVariable("inpUser", "SendMailText|user", "");
      printPage(response, vars, strMailTemplate, strInterestArea, strBPGroup, strUser);
    } else if (vars.commandIn("SEND")) {
      String strMailTemplate = vars.getRequiredGlobalVariable("inpMailTemplate",
          "SendMailText|mailTemplate");
      String strInterestArea = vars.getRequestGlobalVariable("inpInterestArea",
          "SendMailText|interestArea");
      String strBPGroup = vars.getRequestGlobalVariable("inpBPGroup", "SendMailText|bpGroup");
      String strUser = vars.getRequestGlobalVariable("inpUser", "SendMailText|user");

      vars.removeMessage("SendMailText");
      String strMessage = processSend(vars, strMailTemplate, strInterestArea, strBPGroup, strUser);
      // New message system
      myMessage = new OBError();
      String result = getResult();
      myMessage.setType(result);
      myMessage.setTitle(result);
      myMessage.setMessage(strMessage);
      vars.setMessage("SendMailText", myMessage);

      printPage(response, vars, strMailTemplate, strInterestArea, strBPGroup, strUser);
    } else
      pageErrorPopUp(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars,
      String strMailTemplate, String strInterestArea, String strBPGroup, String strUser)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: SendMailText select page");

    ActionButtonDefaultData[] data = null;
    String strHelp = "", strDescription = "", strProcessId = "209";
    String[] discard = { "" };
    if (vars.getLanguage().equals("en_US"))
      data = ActionButtonDefaultData.select(this, strProcessId);
    else
      data = ActionButtonDefaultData.selectLanguage(this, vars.getLanguage(), strProcessId);
    if (data != null && data.length != 0) {
      strDescription = data[0].description;
      strHelp = data[0].help;
    }
    if (strHelp.equals(""))
      discard[0] = new String("helpDiscard");

    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_process/SendMailText", discard).createXmlDocument();

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "SendMailText", false, "", "", "",
        false, "ad_process", strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("question", Utility.messageBD(this, "StartProcess?", vars
        .getLanguage()));
    xmlDocument.setParameter("description", strDescription);
    xmlDocument.setParameter("help", strHelp);
    xmlDocument.setParameter("mailTemplate", strMailTemplate);
    xmlDocument.setParameter("interestArea", strInterestArea);
    xmlDocument.setParameter("bpGroup", strBPGroup);
    xmlDocument.setParameter("user", strUser);
    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_process.SendMailText");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(), "SendMailText.html",
          classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb(), vars);
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "SendMailText.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("SendMailText");
      vars.removeMessage("SendMailText");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "R_MailText_ID",
          "", "", Utility.getContext(this, vars, "#AccessibleOrgTree", "SendMailText"), Utility
              .getContext(this, vars, "#User_Client", "SendMailText"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "SendMailText", strMailTemplate);
      xmlDocument.setData("reportMailTemplate", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR",
          "R_InterestArea_ID", "", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "SendMailText"), Utility.getContext(this, vars, "#User_Client", "SendMailText"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "SendMailText", strInterestArea);
      xmlDocument.setData("reportInterestArea", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "C_BP_Group_ID",
          "", "", Utility.getContext(this, vars, "#AccessibleOrgTree", "SendMailText"), Utility
              .getContext(this, vars, "#User_Client", "SendMailText"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "SendMailText", strBPGroup);
      xmlDocument.setData("reportBPGroup", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLE", "User",
          "AD_User - Employee", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "SendMailText"), Utility.getContext(this, vars, "#User_Client", "SendMailText"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "SendMailText", strUser);
      xmlDocument.setData("reportUser", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private String processSend(VariablesSecureApp vars, String strMailTemplate,
      String strInterestArea, String strBPGroup, String strUser) throws IOException,
      ServletException {
    String client = vars.getClient();
    long start = 0;
    int counter = 0;
    int errors = 0;
    StringBuffer g_log = new StringBuffer();
    String language = vars.getLanguage();
    Connection conn = null;
    try {
      conn = getTransactionConnection();
      EmailManager mailman = new EmailManager();
      final Session session = mailman.newMailSession(this, client, vars.getOrg());
      String bcc="";
      if (UtilsData.getOrgConfigOption(this, "addbccemail2alerts", vars.getOrg()).equals("Y"))
        bcc=AlertProcessData.getBccAddress(this, client, vars.getOrg());
      if (log4j.isDebugEnabled())
        log4j.debug("processSend - R_MailText_ID=" + strMailTemplate);
      if (strMailTemplate.equals(""))
        return (Utility.messageBD(this, "NotFound", language) + " " + Utility.messageBD(this,
            "R_MailText_ID", language));
      if (log4j.isDebugEnabled())
        log4j.debug("processSend - AD_Client_ID=" + client);
      if (client.equals("0"))
        return (Utility.messageBD(this, "NotFound", language) + " - " + Utility.messageBD(this,
            "AD_Client_ID", language));
     
      String from = "";
      String fromID = "";
      String fromPW = "";
      SendMailTextData[] mailTextData = SendMailTextData
          .selectMailData(conn, this, strMailTemplate);
      if (mailTextData == null || mailTextData.length == 0)
        return (Utility.messageBD(this, "NotFound", language) + " "
            + Utility.messageBD(this, "R_MailText_ID", language) + ": " + strMailTemplate);
      String subject = mailTextData[0].mailheader;
      String message = mailTextData[0].mailtext;
      String attchmnts = SendMailTextData.selectMailAttachments(this, globalParameters.strFTPDirectory, strMailTemplate);
      EmailData[] mails = null;
      if (!strUser.equals("")) {
        mails = EmailData.selectEmail(conn, this, strUser);
        if (mails == null || mails.length == 0)
          return ("From EMail not complete - " + from + "(" + fromID + "/" + fromPW + ")");
        // EMail Sender Replace (Only namesd Sender)
        String salesrep = mails[0].name;
        message = message.replaceAll("@sal_nam@", salesrep);
        from = mails[0].email;
        from = from.trim().toLowerCase();
        for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" ")) {
          from = from.substring(0, pos) + from.substring(pos + 1);
        }
        fromID = mails[0].emailuser;
        fromPW = FormatUtilities.encryptDecrypt(mails[0].emailuserpw, false);
      } else {
        mails = EmailData.selectEmailRequest(conn, this, vars.getClient());
        if (mails == null || mails.length == 0)
          return ("From EMail not complete - " + from + "(" + fromID + "/" + fromPW + ")" + " - selectEmailRequest");
        from = mails[0].email;
        from = from.trim().toLowerCase();
        for (int pos = from.indexOf(" "); pos != -1; pos = from.indexOf(" ")) {
          from = from.substring(0, pos) + from.substring(pos + 1);
        }
        fromID = mails[0].emailuser;
        fromPW = FormatUtilities.encryptDecrypt(mails[0].emailuserpw, false);
      }
      if (from.equals(""))
        return ("From EMail not complete - " + from + "(" + fromID + "/" + fromPW + ")" + " - from/fromId/fromPW is empty.");
      if (log4j.isDebugEnabled())
        log4j.debug("processSend - from " + from + "(" + fromID + "/" + fromPW + ")");

      SendMailTextData[] mailData;
      start = System.currentTimeMillis();
      if (strInterestArea != null && !strInterestArea.equals("")) {
        log4j.info("processSend - Send to R_InterestArea_ID=" + strInterestArea);
        mailData = SendMailTextData.select(conn, this, strInterestArea);
        Boolean OK;
        if (mailData != null && mailData.length > 0) {
          if (log4j.isDebugEnabled())
            log4j.debug("number of emails to send: " + mailData.length);
          for (int i = 0; i < mailData.length; i++) {
            if (log4j.isDebugEnabled())
              log4j.debug("attempt to send email to: " + mailData[i].email);
            
            try {
              // Send the mail, last param could be Attchment :-)
              mailman.sendSimpleEmail(session, from, mailData[i].email, bcc,  subject, message.replaceAll("@cus_nam@", mailData[i].name),attchmnts);
              if (UtilsData.getOrgConfigOption(this, "addnewslettermail2crm", vars.getOrg()).equals("Y")) {
            	  // Add CRM Entry
            	  String uuid=UtilsData.getUUID(this);
            	  SendMailTextData.insertCRMEntry(this, uuid, vars.getUser(), message.replaceAll("@cus_nam@", mailData[i].name), strUser,mailData[i].adUserId);
            	  String attachments[] = attchmnts.split(",");
            	  boolean isatt=false;
                  for (String attachment : attachments) {
                	  if (!attachment.isEmpty()) {
                	      File f = new File(globalParameters.strFTPDirectory + "/2E7422E821194637ADFB67204011EC15-" +uuid);
                	      if (! f.exists())
                		      f.mkdirs();
                		  File destFile=new File(globalParameters.strFTPDirectory + "/2E7422E821194637ADFB67204011EC15-" +uuid +"/" +attachment.substring(attachment.lastIndexOf("/")));
                		  File srcFile = new File(attachment);
                		  FileUtils.copyFile(srcFile, destFile);
                		  isatt=true;
                	  }
                  }
                  if (isatt) 
                	  SendMailTextData.copyMailAttachments2CRMEntry(this, vars.getUser(), uuid, strMailTemplate);  
              }
              counter++;
              OK=true;
            }
            catch (Exception e) {
              errors++;
              mailResult = resultEnum.ERRORS;
              log4j.error(e.getMessage());
              OK=false;
            }                 
            g_log.append(Utility.messageBD(this, "EMailAddress", vars.getLanguage()) + ": " + mailData[i].email
                + " " + Utility.messageBD(this, (OK ? "OK" : "ERROR"), vars.getLanguage()) + "<br>");
            
          }
        }
      }
      
      if (counter > 0 && errors == 0)
        mailResult = resultEnum.INFO;
      releaseCommitConnection(conn);
    } catch (Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      mailResult = resultEnum.ERRORS;
      return (Utility.messageBD(this, "ProcessRunError", language));
    }
    return (g_log.toString() + "\n" + Utility.messageBD(this, "Created", language) + "=" + counter
        + ", " + Utility.messageBD(this, "Errors", language) + "=" + errors + " - "
        + (System.currentTimeMillis() - start) + "ms");
  }


  private String getResult() {
    String result = "Success";
    if (mailResult == resultEnum.INFO) {
      result = "Info";
    } else if (mailResult == resultEnum.ERRORS) {
      result = "Error";
    }
    return result;
  }

  public String getServletInfo() {
    return "Servlet SendMailText";
  } // end of getServletInfo() method
}
