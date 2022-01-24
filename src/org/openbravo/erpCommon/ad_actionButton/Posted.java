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
package org.openbravo.erpCommon.ad_actionButton;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.ad_forms.AcctServer;
import org.openbravo.erpCommon.reference.ActionButtonData;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;

public class Posted extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Posted: doPost");

    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strKey = vars.getGlobalVariable("inpKey", "Posted|key");
      String strTableId = vars.getGlobalVariable("inpTableId", "Posted|tableId");
      String strTabId = vars.getGlobalVariable("inpTabId", "Posted|tabId");
      String strPosted = vars.getGlobalVariable("inpPosted", "Posted|posted");
      String strProcessId = vars.getGlobalVariable("inpProcessId", "Posted|processId", "");
      String strPath = vars.getGlobalVariable("inpPath", "Posted|path", strDireccion
          + request.getServletPath());
      String strWindowId = vars.getGlobalVariable("inpWindowId", "Posted|windowId", "");
      String strTabName = vars.getGlobalVariable("inpTabName", "Posted|tabName", "");

      printPage(response, vars, strKey, strWindowId, strTabId, strProcessId, strTableId, strPath,
          strTabName, strPosted);
    } else if (vars.commandIn("SAVE")) {

      String strKey = vars.getRequiredGlobalVariable("inpKey", "Posted|key");
      String strTableId = vars.getRequiredGlobalVariable("inpTableId", "Posted|tableId");
      String strTabId = vars.getRequestGlobalVariable("inpTabId", "Posted|tabId");
      String strPosted = vars.getRequiredGlobalVariable("inpPosted", "Posted|posted");
      vars.getRequestGlobalVariable("inpProcessId", "Posted|processId");
      vars.getRequestGlobalVariable("inpPath", "Posted|path");
      vars.getRequestGlobalVariable("inpWindowId", "Posted|windowId");
      vars.getRequestGlobalVariable("inpTabName", "Posted|tabName");

      if (log4j.isDebugEnabled())
        log4j.debug("SAVE, strPosted: " + strPosted );

      if (strPosted.equals("N")) {
        OBError messageResult = processButton(vars, strKey, strTableId);
        if (!messageResult.getType().equals("Success")) {
          vars.setMessage(strTabId, messageResult);
          printPageClosePopUp(response, vars);
        } else {
          PostedData[] data = PostedData.select(this, strKey, strTableId);
          if (data == null || data.length == 0 || data[0].id.equals("")) {
            // vars.setSessionValue(strWindowId + "|" + strTabName +
            // ".message", messageResult);
            vars.setMessage(strTabId, messageResult);
            printPageClosePopUp(response, vars);
          } else {
            printPageClosePopUp(response, vars, (strDireccion
                + "/ad_reports/ReportGeneralLedgerJournal.html?Command=DIRECT&inpTable="
                + strTableId + "&inpRecord=" + strKey + "&inpOrg=" + data[0].org));
          }
        }
      // SZ ACTION =  UNPOST AND no other Action
      // Delete always Accounting Entrys! (strEliminar removed)
      } else {
      //  if (strEliminar.equals("N")) {
          PostedData[] data = PostedData.select(this, strKey, strTableId);
          if (data == null || data.length == 0 || data[0].id.equals("")) {
            // Nothing to Reset
            // Set Posed='N' in Document
            String tablename=PostedData.selectTableName(this, strTableId);
            String sql="update " + tablename + " set posted ='N' where " +  tablename + "_id='" + strKey +"'";
            try {
              Connection conn = this.getConnection();    
              Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);
              int i = stmt.executeUpdate(sql);
              conn.close();
          
              OBError myMessage = new OBError();
              String msg=org.openz.util.LocalizationUtils.getMessageText(this,"NoFactAcct", vars.getLanguage());
              myMessage.setMessage(msg);
              myMessage.setType("Success");
              vars.setMessage(strTabId, myMessage);
            } catch (Exception e) {
              // catch any possible exception and throw it as Servlet Ex
              throw new ServletException(e.getMessage(), e);
            }
            
            printPageClosePopUp(response, vars);
          
        } else {
          // Reset Accounting Entrys
          if (log4j.isDebugEnabled())
            log4j.debug("SAVE, delete");
          OBError myMessage = processButtonDelete(vars, strKey, strTableId);
          vars.setMessage(strTabId, myMessage);
          printPageClosePopUp(response, vars);
        }
      }
    } else
      pageErrorPopUp(response);
  }

  
  private OBError processButton(VariablesSecureApp vars, String strKey, String strTableId)
      throws ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("ProcessButton strKey: " + strKey + "strTableId: " + strTableId);
    String strOrg;
    Connection con = null;
    OBError myMessage = null;

    strOrg = PostedData.selectDocOrg(this, PostedData.selectTableName(this, strTableId), strKey);
    if (strOrg == null)
      strOrg = "0";

    try {
      con = getTransactionConnection();
      AcctServer acct = AcctServer.get(strTableId, vars.getClient(), strOrg, this.myPool);
      if (acct == null) {
        releaseRollbackConnection(con);
        myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
        return myMessage;
      } else if (!acct.post(strKey, false, vars, this, con) || acct.errors != 0) {
        releaseRollbackConnection(con);
        String strStatus = acct.getStatus();
        myMessage = Utility.translateError(this, vars, vars.getLanguage(), strStatus
            .equals(AcctServer.STATUS_DocumentLocked) ? "@OtherPostingProcessActive@" : strStatus
            .equals(AcctServer.STATUS_InvalidCost) ? "@InvalidCost@" : "@ProcessRunError@");
        if (strStatus.equals(AcctServer.STATUS_DocumentLocked))
          myMessage.setType("Warning");
        myMessage.setMessage(myMessage.getMessage());
        return myMessage;
      }
      releaseCommitConnection(con);
    } catch (Exception e) {
      log4j.error(e);
      myMessage = Utility.translateError(this, vars, vars.getLanguage(), e.getMessage());
      try {
        releaseRollbackConnection(con);
      } catch (Exception ignored) {
      }
    }

    if (myMessage == null) {
      myMessage = new OBError();
      myMessage.setType("Success");
      myMessage.setTitle("");
      myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    }
    return myMessage;
  }

  private OBError processButtonDelete(VariablesSecureApp vars, String strKey, String strTableId)
      throws ServletException {
    OBError myMessage = null;

    try {

      String strClient = PostedData.selectClient(this,
          PostedData.selectTableName(this, strTableId), strKey);
      String pinstance = SequenceIdData.getUUID();
      PInstanceProcessData.insertPInstance(this, pinstance, "176", strKey, "N", vars.getUser(),
          vars.getClient(), vars.getOrg());
      PInstanceProcessData.insertPInstanceParam(this, pinstance, "10", "AD_Client_ID", strClient,
          vars.getClient(), vars.getOrg(), vars.getUser());
      PInstanceProcessData.insertPInstanceParam(this, pinstance, "20", "AD_Table_ID", strTableId,
          vars.getClient(), vars.getOrg(), vars.getUser());
     
      if (log4j.isDebugEnabled())
        log4j.debug("delete, pinstance " + pinstance);
      ActionButtonData.process176(this, pinstance);

      PInstanceProcessData[] pinstanceData = PInstanceProcessData.select(this, pinstance);
      myMessage = Utility.getProcessInstanceMessage(this, vars, pinstanceData);
    } catch (ServletException ex) {
      myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
    }
    if (myMessage == null) {
      myMessage = new OBError();
      myMessage.setType("Success");
      myMessage.setTitle("");
      myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    }
    return myMessage;
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strKey,
      String windowId, String strTab, String strProcessId, String strTableId, String strPath,
      String strTabName, String strPosted) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Button process Posted");

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
    String[] discard = { "", "" };
    if (strHelp.equals(""))
      discard[0] = new String("helpDiscard");
    if (strPosted.equals("N"))
      discard[1] = new String("selEliminar");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_actionButton/Posted", discard).createXmlDocument();
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("window", windowId);
    xmlDocument.setParameter("tab", strTab);
    xmlDocument.setParameter("process", strProcessId);
    xmlDocument.setParameter("table", strTableId);
    xmlDocument.setParameter("posted", strPosted);
    xmlDocument.setParameter("path", strPath);
    xmlDocument.setParameter("tabname", strTabName);

    {
      OBError myMessage = vars.getMessage("Posted");
      vars.removeMessage("Posted");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("question", Utility.messageBD(this, "StartProcess?", vars
        .getLanguage()));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("description", strDescription);
    xmlDocument.setParameter("help", strHelp);

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet Posted";
  } // end of getServletInfo() method
}
