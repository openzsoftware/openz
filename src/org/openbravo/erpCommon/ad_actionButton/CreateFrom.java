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
import java.math.*;
import java.sql.Connection;
import java.util.StringTokenizer;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.Tax;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.TreeData;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.FormatUtils;
import org.openz.util.UtilsData;
import org.openbravo.utils.FormatUtilities;

public class CreateFrom extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  private static final BigDecimal ZERO = BigDecimal.ZERO;

  @Override
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  @Override
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    final VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      final String strKey = vars.getGlobalVariable("inpKey", "CreateFrom|key");
      final String strTableId = vars.getGlobalVariable("inpTableId", "CreateFrom|tableId");
      final String strProcessId = vars
          .getGlobalVariable("inpProcessId", "CreateFrom|processId", "");
      final String strPath = vars.getGlobalVariable("inpPath", "CreateFrom|path", strDireccion
          + request.getServletPath());
      final String strWindowId = vars.getGlobalVariable("inpWindowId", "CreateFrom|windowId", "");
      final String strTabName = vars.getGlobalVariable("inpTabName", "CreateFrom|tabName", "");
      final String strDateInvoiced = vars.getDateParameterGlobalVariable("inpDateInvoiced",
          "CreateFrom|dateInvoiced", vars.getSessionValue("CreateFrom|dateInvoiced"),this);
      final String strBPartnerLocation = vars.getGlobalVariable("inpcBpartnerLocationId",
          "CreateFrom|bpartnerLocation", "");
      final String strMPriceList = vars.getGlobalVariable("inpMPricelist", "CreateFrom|pricelist",
          "");
      final String strBPartner = vars
          .getGlobalVariable("inpcBpartnerId", "CreateFrom|bpartner", "");
      final String strStatementDate = vars.getDateParameterGlobalVariable("inpstatementdate",
          "CreateFrom|statementDate", vars.getSessionValue("CreateFrom|statementDate"),this);
      final String strBankAccount = vars.getGlobalVariable("inpcBankaccountId",
          "CreateFrom|bankAccount", "");
      final String strOrg = vars.getGlobalVariable("inpadOrgId", "CreateFrom|adOrgId", "");
      final String strIsreceipt = vars
          .getGlobalVariable("inpisreceipt", "CreateFrom|isreceipt", "");

      if (log4j.isDebugEnabled())
        log4j.debug("doPost - inpadOrgId = " + strOrg);
      if (log4j.isDebugEnabled())
        log4j.debug("doPost - inpisreceipt = " + strIsreceipt);

      // 26-06-07
      vars.setSessionValue("CreateFrom|default", "1");

      printPage_FS(response, vars, strPath, strKey, strTableId, strProcessId, strWindowId,
          strTabName, strDateInvoiced, strBPartnerLocation, strMPriceList, strBPartner,
          strStatementDate, strBankAccount, strOrg, strIsreceipt);
    } else if (vars.commandIn("FRAME1")) {
      final String strTableId = vars.getGlobalVariable("inpTableId", "CreateFrom|tableId");
      final String strType = pageType(strTableId);
      final String strKey = vars.getGlobalVariable("inpKey", "CreateFrom" + strType + "|key");
      final String strProcessId = vars.getGlobalVariable("inpProcessId", "CreateFrom" + strType
          + "|processId", "");
      final String strPath = vars.getGlobalVariable("inpPath", "CreateFrom" + strType + "|path",
          strDireccion + request.getServletPath());
      final String strWindowId = vars.getGlobalVariable("inpWindowId", "CreateFrom" + strType
          + "|windowId");
      final String strTabName = vars.getGlobalVariable("inpTabName", "CreateFrom" + strType
          + "|tabName");
      final String strDateInvoiced = vars.getDateParameterGlobalVariable("inpDateInvoiced", "CreateFrom"
          + strType + "|dateInvoiced", UtilsData.selectDisplayDatevalue(this,vars.getSessionValue("CreateFrom"
          + strType + "|dateInvoiced"), "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")),this);
      final String strBPartnerLocation = vars.getGlobalVariable("inpcBpartnerLocationId",
          "CreateFrom" + strType + "|bpartnerLocation", "");
      final String strPriceList = vars.getGlobalVariable("inpMPricelist", "CreateFrom" + strType
          + "|pricelist", "");
      final String strBPartner = vars.getGlobalVariable("inpcBpartnerId", "CreateFrom" + strType
          + "|bpartner", "");
      final String strStatementDate = vars.getDateParameterGlobalVariable("inpstatementdate", "CreateFrom"
          + strType + "|statementDate", UtilsData.selectDisplayDatevalue(this,vars.getSessionValue("CreateFrom|statementDate"), "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")),this);
      final String strBankAccount = vars.getGlobalVariable("inpcBankaccountId", "CreateFrom"
          + strType + "|bankAccount", "");
      final String strOrg = vars.getGlobalVariable("inpadOrgId", "CreateFrom" + strType
          + "|adOrgId", "");
      final String strIsreceipt = vars.getGlobalVariable("inpisreceipt", "CreateFrom" + strType
          + "|isreceipt", "");
      

      if (log4j.isDebugEnabled())
        log4j.debug("doPost - inpadOrgId = " + strOrg);
      if (log4j.isDebugEnabled())
        log4j.debug("doPost - inpisreceipt = " + strIsreceipt);

      vars.removeSessionValue("CreateFrom" + strType + "|key");
      vars.removeSessionValue("CreateFrom" + strType + "|processId");
      vars.removeSessionValue("CreateFrom" + strType + "|path");
      vars.removeSessionValue("CreateFrom" + strType + "|windowId");
      vars.removeSessionValue("CreateFrom" + strType + "|tabName");
      vars.removeSessionValue("CreateFrom" + strType + "|dateInvoiced");
      vars.removeSessionValue("CreateFrom" + strType + "|bpartnerLocation");
      vars.removeSessionValue("CreateFrom" + strType + "|pricelist");
      vars.removeSessionValue("CreateFrom" + strType + "|bpartner");
      vars.removeSessionValue("CreateFrom" + strType + "|statementDate");
      vars.removeSessionValue("CreateFrom" + strType + "|bankAccount");
      vars.removeSessionValue("CreateFrom" + strType + "|adOrgId");
      vars.removeSessionValue("CreateFrom" + strType + "|isreceipt");

      callPrintPage(response, vars, strPath, strKey, strTableId, strProcessId, strWindowId,
          strTabName, strDateInvoiced, strBPartnerLocation, strPriceList, strBPartner,
          strStatementDate, strBankAccount, strOrg, strIsreceipt);
    } else if (vars.commandIn("FIND_PO", "FIND_INVOICE", "FIND_SHIPMENT", "FIND_BANK",
        "FIND_SETTLEMENT")) {
      final String strKey = vars.getRequiredStringParameter("inpKey");
      final String strTableId = vars.getStringParameter("inpTableId");
      final String strProcessId = vars.getStringParameter("inpProcessId");
      final String strPath = vars.getStringParameter("inpPath", strDireccion
          + request.getServletPath());
      final String strWindowId = vars.getStringParameter("inpWindowId");
      final String strTabName = vars.getStringParameter("inpTabName");
      final String strDateInvoiced = vars.getDateParameter("inpDateInvoiced",this);
      final String strBPartnerLocation = vars.getStringParameter("inpcBpartnerLocationId");
      final String strPriceList = vars.getStringParameter("inpMPricelist");
      final String strBPartner = vars.getStringParameter("inpcBpartnerId");
      final String strStatementDate = vars.getDateParameter("inpstatementdate",this);
      final String strBankAccount = vars.getStringParameter("inpcBankaccountId");
      final String strOrg = vars.getStringParameter("inpadOrgId");
      final String strIsreceipt = vars.getStringParameter("inpisreceipt");
      if (log4j.isDebugEnabled())
        log4j.debug("doPost - inpadOrgId = " + strOrg);
      if (log4j.isDebugEnabled())
        log4j.debug("doPost - inpisreceipt = " + strIsreceipt);

      callPrintPage(response, vars, strPath, strKey, strTableId, strProcessId, strWindowId,
          strTabName, strDateInvoiced, strBPartnerLocation, strPriceList, strBPartner,
          strStatementDate, strBankAccount, strOrg, strIsreceipt);
    } else if (vars.commandIn("SAVE")) {
      final String strProcessId = vars.getStringParameter("inpProcessId");
      final String strKey = vars.getRequiredStringParameter("inpKey");
      final String strTableId = vars.getStringParameter("inpTableId");
      final String strWindowId = vars.getStringParameter("inpWindowId");
      final OBError myMessage = saveMethod(vars, strKey, strTableId, strProcessId, strWindowId);
      final String strTabId = vars.getGlobalVariable("inpTabId", "CreateFrom|tabId");
      vars.setMessage(strTabId, myMessage);
      printPageClosePopUp(response, vars);
      vars.removeSessionValue("CreateFrom|key");
      vars.removeSessionValue("CreateFrom|processId");
      vars.removeSessionValue("CreateFrom|path");
      vars.removeSessionValue("CreateFrom|windowId");
      vars.removeSessionValue("CreateFrom|tabName");
      vars.removeSessionValue("CreateFrom|dateInvoiced");
      vars.removeSessionValue("CreateFrom|bpartnerLocation");
      vars.removeSessionValue("CreateFrom|pricelist");
      vars.removeSessionValue("CreateFrom|bpartner");
      vars.removeSessionValue("CreateFrom|statementDate");
      vars.removeSessionValue("CreateFrom|bankAccount");
      vars.removeSessionValue("CreateFrom|adOrgId");
      vars.removeSessionValue("CreateFrom|isreceipt");
      // response.sendRedirect(strPath);
    } else
      pageErrorPopUp(response);
  }

  private void printPage_FS(HttpServletResponse response, VariablesSecureApp vars, String strPath,
      String strKey, String strTableId, String strProcessId, String strWindowId, String strTabName,
      String strDateInvoiced, String strBPartnerLocation, String strPriceList, String strBPartner,
      String strStatementDate, String strBankAccount, String strOrg, String strIsreceipt)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: FrameSet");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_actionButton/CreateFrom_FS").createXmlDocument();
    final String strType = pageType(strTableId);
    vars.setSessionValue("CreateFrom" + strType + "|path", strPath);
    vars.setSessionValue("CreateFrom" + strType + "|key", strKey);
    vars.setSessionValue("CreateFrom" + strType + "|processId", strProcessId);
    vars.setSessionValue("CreateFrom" + strType + "|windowId", strWindowId);
    vars.setSessionValue("CreateFrom" + strType + "|tabName", strTabName);
    vars.setSessionValue("CreateFrom" + strType + "|dateInvoiced", strDateInvoiced);
    vars.setSessionValue("CreateFrom" + strType + "|bpartnerLocation", strBPartnerLocation);
    vars.setSessionValue("CreateFrom" + strType + "|pricelist", strPriceList);
    vars.setSessionValue("CreateFrom" + strType + "|bpartner", strBPartner);
    vars.setSessionValue("CreateFrom" + strType + "|statementDate", strStatementDate);
    vars.setSessionValue("CreateFrom" + strType + "|bankAccount", strBankAccount);
    vars.setSessionValue("CreateFrom" + strType + "|adOrgId", strOrg);
    vars.setSessionValue("CreateFrom" + strType + "|isreceipt", strIsreceipt);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private String pageType(String strTableId) {
    if (strTableId.equals("392"))
      return "Bank";
    else if (strTableId.equals("318"))
      return "Invoice";
    else if (strTableId.equals("319"))
      return "Shipment";
    else if (strTableId.equals("426"))
      return "Pay";
    else if (strTableId.equals("800019"))
      return "Settlement";
    else
      return "";
  }

  void callPrintPage(HttpServletResponse response, VariablesSecureApp vars, String strPath,
      String strKey, String strTableId, String strProcessId, String strWindowId, String strTabName,
      String strDateInvoiced, String strBPartnerLocation, String strPriceList, String strBPartner,
      String strStatementDate, String strBankAccount, String strOrg, String strIsreceipt)
      throws IOException, ServletException {
    if (strTableId.equals("392") || strTableId.equals("4AF9D81E51A04F2B987CD91AA9EE99F4")) { // C_BankStatement or zsfi_macctline
      printPageBank(response, vars, strPath, strKey, strTableId, strProcessId, strWindowId,
          strTabName, strStatementDate, strBankAccount);
    } else if (strTableId.equals("318")) { // C_Invoice
      printPageInvoice(response, vars, strPath, strKey, strTableId, strProcessId, strWindowId,
          strTabName, strDateInvoiced, strBPartnerLocation, strPriceList, strBPartner);
    } else if (strTableId.equals("319")) { // M_InOut
      printPageShipment(response, vars, strPath, strKey, strTableId, strProcessId, strWindowId,
          strTabName, strBPartner);
    } else if (strTableId.equals("800019")) { // C_Settlement
      printPageSettlement(response, vars, strPath, strKey, strTableId, strProcessId, strWindowId,
          strTabName, strBPartner);
    } else {
      pageError(response);
    }
  }

  protected void printPageBank(HttpServletResponse response, VariablesSecureApp vars,
      String strPath, String strKey, String strTableId, String strProcessId, String strWindowId,
      String strTabName, String strStatementDate, String strBank) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Bank");
    final String strcBPartner = vars.getStringParameter("inpcBpartnerId");
    final String strPaymentRule = vars.getStringParameter("inppaymentrule");
    final String strPlannedDateFrom = vars.getDateParameter("inpplanneddateFrom",this);
    final String strPlannedDateTo = vars.getDateParameter("inpplanneddateTo",this);
    final String strAmountFrom = vars.getNumericParameter("inpamountFrom");
    final String strAmountTo = vars.getNumericParameter("inpamountTo");
    String strIsReceipt = vars.getStringParameter("inpisreceipt");
    final String isSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
    final String strBankAccount = vars.getStringParameter("inpcBankaccountId");
    final String strOrg = vars.getStringParameter("inpadOrgId");
    final String strCharge = vars.getStringParameter("inpCharge");
    final String strIsapproved = vars.getStringParameter("inpIsapproved");
    String strPlannedDate = vars.getDateParameter("inpplanneddate", this);
    if (!strPlannedDate.isEmpty()) 
    	strStatementDate=strPlannedDate;
    final String strCost = vars.getNumericParameter("inpcost", "0.00");
    final String strProposed = vars.getNumericParameter("inpproposed", "0.00");
    final String strDiscount = vars.getNumericParameter("inpdiscount", "0.00");
    final String strDocumentNo = vars.getStringParameter("inpDocumentNo");
    final String strBpOrderNo = vars.getStringParameter("inpBpOrderNo");
    CreateFromBankData[] data = null;
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_actionButton/CreateFrom_Bank").createXmlDocument();

    final int numRows = Integer.valueOf(CreateFromBankData.countRows(this, Utility.getContext(this,
        vars, "#User_Client", strWindowId), Utility
        .getContext(this, vars, "#User_Org", strWindowId), strcBPartner, strPaymentRule,
        strPlannedDateFrom, strPlannedDateTo, strAmountFrom, strAmountTo, strIsReceipt, strBank,
        strOrg, strCharge, strIsapproved, strDocumentNo,strBpOrderNo));
    final int maxRows = Integer.valueOf(vars.getSessionValue("#RECORDRANGEINFO"));

    if (numRows > maxRows) {
      final OBError obError = new OBError();
      String strMsg = Utility.messageBD(this, "MAX_RECORDS_REACHED", vars.getLanguage());
      strMsg = strMsg.replaceAll("%returned%", String.valueOf(numRows));
      strMsg = strMsg.replaceAll("%shown%", String.valueOf(maxRows));
      obError.setMessage(strMsg);
      obError.setTitle("");
      obError.setType("WARNING");
      vars.setMessage("CreateFrom", obError);
    }

    //
    if (strTableId.equals("4AF9D81E51A04F2B987CD91AA9EE99F4")) {
     String strBdtID=CreateFromBankData.selectBankStmtIdFromMacctline(this, strKey);
     if (strStatementDate.isEmpty())
        strStatementDate=CreateFromBankData.selectMacctAcctDate(this, strKey);
     data = CreateFromBankData.select(this, vars.getLanguage(), strBdtID, strStatementDate,Utility
    	          .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this, vars,
    	          "#User_Org", strWindowId), strcBPartner, strPaymentRule, strPlannedDateFrom,
    	          strPlannedDateTo, strAmountFrom, strAmountTo, strIsReceipt, strBank, strOrg, strCharge, strIsapproved,
    	          strDocumentNo, strBpOrderNo,String.valueOf(maxRows));
    } else {
      data = CreateFromBankData.select(this, vars.getLanguage(), strKey, strStatementDate,Utility
          .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this, vars,
          "#User_Org", strWindowId), strcBPartner, strPaymentRule, strPlannedDateFrom,
          strPlannedDateTo, strAmountFrom, strAmountTo, strIsReceipt, strBank, strOrg, strCharge, strIsapproved,
          strDocumentNo, strBpOrderNo,String.valueOf(maxRows));
    }
    String read=CreateFromBankData.readable(this,strBank,strDocumentNo);
    
    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("path", strPath);
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("tableId", strTableId);
    xmlDocument.setParameter("processId", strProcessId);
    xmlDocument.setParameter("windowId", strWindowId);
    xmlDocument.setParameter("tabName", strTabName);
    xmlDocument.setParameter("statementDate", UtilsData.selectDisplayDatevalue(this,strStatementDate, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("paramCBankaccountID", null);  //Voreinstellung strBank 
    
    xmlDocument.setParameter("paramplanneddate", UtilsData.selectDisplayDatevalue(this,strPlannedDate, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("planneddatedisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("planneddatedisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("paramcost", strCost);
    xmlDocument.setParameter("paramproposed", strProposed);
    xmlDocument.setParameter("documentNo", strDocumentNo);
    xmlDocument.setParameter("bpOrderNo", strBpOrderNo);
    xmlDocument.setParameter("rw", read);
    xmlDocument.setParameter("paymentRule", strPaymentRule);
    
    // On Manual Acct Lines: Set Total Goal from macctline amt
    if (strTableId.equals("4AF9D81E51A04F2B987CD91AA9EE99F4")) {
	    String mlamt=CreateFromBankData.selectMacctLineAmt(this, strKey);
	    mlamt=FormatUtils.formatNumber(mlamt, vars, "euroEdition");
	    xmlDocument.setParameter("paramTotalGoal",mlamt);
	    xmlDocument.setParameter("paraminpTotalGoal",mlamt);
    }
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "LIST", "",
          "All_Payment Rule", "", Utility
              .getContext(this, vars, "#AccessibleOrgTree", "CreateFrom"), Utility.getContext(this,
              vars, "#User_Client", "CreateFrom"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "CreateFrom", strPaymentRule);
      xmlDocument.setData("reportPaymentRule", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (final Exception ex) {
      throw new ServletException(ex);
    }
    xmlDocument.setParameter("cbpartnerId", strcBPartner);

    xmlDocument.setParameter("cbpartnerId_DES", CreateFromBankData.bpartner(this, strcBPartner));
    xmlDocument.setParameter("plannedDateFrom", UtilsData.selectDisplayDatevalue(this,strPlannedDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("plannedDateFromdisplayFormat", vars
        .getSessionValue("#AD_SqlDateFormat"));
    xmlDocument
        .setParameter("plannedDateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("plannedDateTo", UtilsData.selectDisplayDatevalue(this,strPlannedDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("plannedDateTodisplayFormat", vars
        .getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("plannedDateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("amountFrom", strAmountFrom);
    {
      final OBError myMessage = vars.getMessage("CreateFrom");
      vars.removeMessage("CreateFrom");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }
    xmlDocument.setParameter("amountTo", strAmountTo);
    xmlDocument.setParameter("isreceiptPago", strIsReceipt);
    xmlDocument.setParameter("isreceiptCobro", strIsReceipt);
    xmlDocument.setParameter("adOrgId", strOrg);
    xmlDocument.setParameter("charge", strCharge);
    xmlDocument.setParameter("isapproved", strIsapproved);

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR",
          "C_BankAccount_ID", "", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              strWindowId), Utility.getContext(this, vars, "#User_Client", strWindowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, strWindowId, strBank);
      xmlDocument.setData("reportC_BankAccount_ID", "liststructure", comboTableData.select(false)); 
      comboTableData = null;
    } catch (final Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_Org_ID", "",
          "", Utility.getContext(this, vars, "#AccessibleOrgTree", strWindowId), Utility
              .getContext(this, vars, "#User_Client", strWindowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, strWindowId, strOrg);
      xmlDocument.setData("reportAD_Org_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (final Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setData("structure1", data);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    String Outgoing=xmlDocument.print();
    Outgoing=Outgoing.replace("readonly=\"FALSE\"","");
    Outgoing=Outgoing.replace("readonly=\"TRUE\"","readonly=\"\"");
    out.println(Outgoing);
    out.close();
  }

  protected void printPageInvoice(HttpServletResponse response, VariablesSecureApp vars,
      String strPath, String strKey, String strTableId, String strProcessId, String strWindowId,
      String strTabName, String strDateInvoiced, String strBPartnerLocation, String strPriceList,
      String strBPartner) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Invoice");
    CreateFromInvoiceData[] data = null;
    XmlDocument xmlDocument;
    String strPO = vars.getStringParameter("inpPurchaseOrder");
    String strShipment = vars.getStringParameter("inpShipmentReciept");
    String strDocTypeTargetId= "";
    // SZ Load Doctype to Determin Credit Memo (AR) - Only on Sales Invoice (167) Window, Vendor - AP CreditMemo on Purchase Invoice (183)
    if (strWindowId.equals("167"))
        strDocTypeTargetId= vars.getGlobalVariable("inpcDoctypeTargetId", "167" + "|C_DOCTYPETARGET_ID", "");
    if (strWindowId.equals("183"))
      strDocTypeTargetId= vars.getGlobalVariable("inpcDoctypeTargetId", "183" + "|C_DOCTYPETARGET_ID", "");

    final String isSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
    if (vars.commandIn("FIND_PO"))
      strShipment = "";
    else if (vars.commandIn("FIND_SHIPMENT"))
      strPO = "";
    if (strPO.equals("") && strShipment.equals("")) {
      final String[] discard = { "sectionDetail" };
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_actionButton/CreateFrom_Invoice", discard)
          .createXmlDocument();
      data = CreateFromInvoiceData.set();
    } else {
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_actionButton/CreateFrom_Invoice").createXmlDocument();
      // Select from Order
      if (strShipment.equals("")) {
        // Sales Order / Purchase Order
        if (! strDocTypeTargetId.equals("3CD24CAE0D074B8FA9918178780D50FB") && ! strDocTypeTargetId.equals("A4277AD679DF4DD8A9C2BB9F3C2F2C92"))
          data = CreateFromInvoiceData.selectFromPOTrlSOTrx(this, vars.getLanguage(), Utility
              .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this,
              vars, "#User_Org", strWindowId), strPO);
        // Credit Memo Doctype (Vendor or Customer)
        if (strDocTypeTargetId.equals("3CD24CAE0D074B8FA9918178780D50FB") || strDocTypeTargetId.equals("A4277AD679DF4DD8A9C2BB9F3C2F2C92")) 
          data = CreateFromInvoiceData.selectFromOrderCreditMemo(this, vars.getLanguage(), Utility
              .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this,
              vars, "#User_Org", strWindowId), strPO);
      // Select from Shipment
      } else {
         
           // Credit Memo Doctype and Normal have equal Lines, (Whole Shipment), because in The Combo
           // Only Correct Items (Shipment Return) are selectable
            data = CreateFromInvoiceData.selectFromShipmentTrlSOTrx(this, vars.getLanguage(),isSOTrx,
                Utility.getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(
                    this, vars, "#User_Org", strWindowId), strShipment);
      }
    }

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("path", strPath);
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("tableId", strTableId);
    xmlDocument.setParameter("processId", strProcessId);
    xmlDocument.setParameter("dateInvoiced",  UtilsData.selectDisplayDatevalue(this,strDateInvoiced, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("bpartnerLocation", strBPartnerLocation);
    xmlDocument.setParameter("pricelist", strPriceList);
    xmlDocument.setParameter("cBpartnerId", strBPartner);
    xmlDocument.setParameter("BPartnerDescription", CreateFromShipmentData.selectBPartner(this,
        strBPartner));
    xmlDocument.setParameter("PurchaseOrder", strPO);
    xmlDocument.setParameter("Shipment", strShipment);
    xmlDocument.setParameter("pType", (!strShipment.equals("") ? "SHIPMENT"
        : (!strPO.equals("")) ? "PO" : ""));
    xmlDocument.setParameter("windowId", strWindowId);
    xmlDocument.setParameter("tabName", strTabName);

    if (strBPartner.equals("")) {
      xmlDocument.setData("reportShipmentReciept", "liststructure", new CreateFromInvoiceData[0]);
      xmlDocument.setData("reportPurchaseOrder", "liststructure", new CreateFromInvoiceData[0]);
    } else {
      // Normal Sales Invoice
      if (! strDocTypeTargetId.equals("3CD24CAE0D074B8FA9918178780D50FB") && ! strDocTypeTargetId.equals("A4277AD679DF4DD8A9C2BB9F3C2F2C92")) {
        xmlDocument.setData("reportShipmentReciept", "liststructure", CreateFromInvoiceData
            .selectFromShipmentSOTrxCombo(this, vars.getLanguage(),isSOTrx, Utility.getContext(this, vars,
                "#User_Client", strWindowId), Utility.getContext(this, vars, "#User_Org",
                strWindowId), strBPartner));
        xmlDocument.setData("reportPurchaseOrder", "liststructure", CreateFromInvoiceData
            .selectFromPOSOTrxCombo(this, vars.getLanguage(), Utility.getContext(this, vars,
                "#User_Client", strWindowId), Utility.getContext(this, vars, "#User_Org",
                strWindowId), strBPartner,isSOTrx));

      } 
      // Credit Memo Doctypes (AP and AR)
      if (strDocTypeTargetId.equals("3CD24CAE0D074B8FA9918178780D50FB") || strDocTypeTargetId.equals("A4277AD679DF4DD8A9C2BB9F3C2F2C92")) {
        xmlDocument.setData("reportShipmentReciept", "liststructure", CreateFromInvoiceData
            .selectFromShipmentCreditReturnCombo(this, vars.getLanguage(),isSOTrx, Utility.getContext(this, vars,
                "#User_Client", strWindowId), Utility.getContext(this, vars, "#User_Org",
                strWindowId), strBPartner));
        xmlDocument.setData("reportPurchaseOrder", "liststructure", CreateFromInvoiceData
            .selectFromOrderCreditReturnCombo(this, vars.getLanguage(), isSOTrx,Utility.getContext(this, vars,
                "#User_Client", strWindowId), Utility.getContext(this, vars, "#User_Org",
                strWindowId), strBPartner));
        final OBError arcmessage = new OBError();
        arcmessage.setType("Info");
        arcmessage.setMessage(Utility.messageBD(this, "ARCInvoicedNOTdelivered", vars.getLanguage()));
        vars.setMessage("CreateFrom",  arcmessage);
      } 
    }
    {
      final OBError myMessage = vars.getMessage("CreateFrom");
      vars.removeMessage("CreateFrom");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setData("structure1", data);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void printPageShipment(HttpServletResponse response, VariablesSecureApp vars,
      String strPath, String strKey, String strTableId, String strProcessId, String strWindowId,
      String strTabName, String strBPartner) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Shipment");
    CreateFromShipmentData[] data = null;
    XmlDocument xmlDocument;
    String strPO = vars.getStringParameter("inpPurchaseOrder");
    String strInvoice = vars.getStringParameter("inpInvoice");
    String strDocTypeId= "";
    // SZ Load Doctype to Determin Material Returns - Only on Shipment (169) Window
    if (strWindowId.equals("169"))
        strDocTypeId= vars.getGlobalVariable("inpcDoctypeTargetId", "169" + "|C_DOCTYPE_ID", "");
    // Material Receipt, 
    if (strWindowId.equals("184"))
      strDocTypeId= vars.getGlobalVariable("inpcDoctypeTargetId", "184" + "|C_DOCTYPE_ID", "");
    final String strLocator = vars.getStringParameter("inpmLocatorId");
    final String isSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
    if (vars.commandIn("FIND_PO"))
      strInvoice = "";
    else if (vars.commandIn("FIND_INVOICE"))
      strPO = "";
    if (strPO.equals("") && strInvoice.equals("")) {
      final String[] discard = { "sectionDetail" };
      if (isSOTrx.equals("Y"))
        xmlDocument = xmlEngine.readXmlTemplate(
            "org/openbravo/erpCommon/ad_actionButton/CreateFrom_Shipment", discard)
            .createXmlDocument();
      else
        xmlDocument = xmlEngine.readXmlTemplate(
            "org/openbravo/erpCommon/ad_actionButton/CreateFrom_ShipmentPO", discard)
            .createXmlDocument();
      data = CreateFromShipmentData.set();
    } else {
      if (isSOTrx.equals("Y"))
        xmlDocument = xmlEngine.readXmlTemplate(
            "org/openbravo/erpCommon/ad_actionButton/CreateFrom_Shipment").createXmlDocument();
      else
        xmlDocument = xmlEngine.readXmlTemplate(
            "org/openbravo/erpCommon/ad_actionButton/CreateFrom_ShipmentPO").createXmlDocument();
      // Select from Order
      if (strInvoice.equals("")) {
        // Normal Shipment/Receipt
        if ( ! strDocTypeId.equals("2317023F9771481696461C5EAF9A0915") && ! strDocTypeId.equals("2E1E735AA91A49F8BC7181D31B09B370"))
          data = CreateFromShipmentData.selectFromPOTrlSOTrx(this, vars.getLanguage(), Utility
              .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this,
              vars, "#User_Org", strWindowId), strPO);
        // Shipment (Return) or Receipt (Vendor Return)
        if (strDocTypeId.equals("2317023F9771481696461C5EAF9A0915") || strDocTypeId.equals("2E1E735AA91A49F8BC7181D31B09B370"))
          data = CreateFromShipmentData.selectFromOrderReturn(this, vars.getLanguage(), Utility
              .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this,
              vars, "#User_Org", strWindowId), strPO);
      } else {    
        // In Shipment-Returns it is Shure that no Invoice is Selected.
        // Invoice Combo in Shipment-Returns  is always empty
        data = CreateFromShipmentData.selectFromInvoiceTrx(this, vars.getLanguage(), Utility
              .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this,
              vars, "#User_Org", strWindowId), strInvoice);
      }
    }

    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("path", strPath);
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("tableId", strTableId);
    xmlDocument.setParameter("processId", strProcessId);
    xmlDocument.setParameter("cBpartnerId", strBPartner);
    xmlDocument.setParameter("BPartnerDescription", CreateFromShipmentData.selectBPartner(this,
        strBPartner));
    xmlDocument.setParameter("PurchaseOrder", strPO);
    xmlDocument.setParameter("M_Locator_ID", strLocator);
    xmlDocument.setParameter("M_Locator_ID_DES", CreateFromShipmentData.selectLocator(this,
        strLocator));
    xmlDocument.setParameter("Invoice", strInvoice);
    xmlDocument.setParameter("pType", (!strInvoice.equals("") ? "INVOICE"
        : (!strPO.equals("")) ? "PO" : ""));
    xmlDocument.setParameter("windowId", strWindowId);
    xmlDocument.setParameter("tabName", strTabName);

    if (strBPartner.equals("")) {
      xmlDocument.setData("reportInvoice", "liststructure", new CreateFromShipmentData[0]);
      xmlDocument.setData("reportPurchaseOrder", "liststructure", new CreateFromShipmentData[0]);
    } else {
      // normal Shipment/Receipt
      if ( ! strDocTypeId.equals("2E1E735AA91A49F8BC7181D31B09B370") && !  strDocTypeId.equals("2317023F9771481696461C5EAF9A0915")) {
        xmlDocument.setData("reportInvoice", "liststructure", CreateFromShipmentData
            .selectFromInvoiceTrxCombo(this, vars.getLanguage(), Utility.getContext(this, vars,
                "#User_Client", strWindowId), Utility.getContext(this, vars, "#User_Org",
                strWindowId), strBPartner,isSOTrx));
        xmlDocument.setData("reportPurchaseOrder", "liststructure", CreateFromShipmentData
            .selectFromPOSOTrxCombo(this, vars.getLanguage(), Utility.getContext(this, vars,
                "#User_Client", strWindowId), Utility.getContext(this, vars, "#User_Org",
                strWindowId), strBPartner,isSOTrx));
      }
      // Shipment Return Doctype
      // Contains no Invoices, Only selectable from Orders
      if (strDocTypeId.equals("2E1E735AA91A49F8BC7181D31B09B370") ||  strDocTypeId.equals("2317023F9771481696461C5EAF9A0915")) {
        xmlDocument.setData("reportInvoice", "liststructure",new CreateFromShipmentData[0]);
        xmlDocument.setData("reportPurchaseOrder", "liststructure", CreateFromShipmentData
            .selectFromOrderReturnCombo(this, vars.getLanguage(), Utility.getContext(this, vars,
                "#User_Client", strWindowId), Utility.getContext(this, vars, "#User_Org",
                strWindowId), strBPartner,isSOTrx));
      }
    }

    {
      final OBError myMessage = vars.getMessage("CreateFrom");
      vars.removeMessage("CreateFrom");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    if (isSOTrx.equals("N")) {
      final CreateFromShipmentData[][] dataUOM = new CreateFromShipmentData[data.length][];

      for (int i = 0; i < data.length; i++) {
        // Obtain the specific units for each product

        dataUOM[i] = CreateFromShipmentData.selectUOM(this, data[i].mProductId);

        // Check the hidden fields

        final String strhavesec = data[i].havesec;

        if ("0".equals(strhavesec)) {
          data[i].havesec = "hidden";
          data[i].havesecuom = "none";
        } else {
          data[i].havesec = "text";
          data[i].havesecuom = "block";
        }
      }
      xmlDocument.setDataArray("reportM_Product_Uom_To_ID", "liststructure", dataUOM);
    }
    xmlDocument.setData("structure1", data);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

 
  protected void printPageSettlement(HttpServletResponse response, VariablesSecureApp vars,
      String strPath, String strKey, String strTableId, String strProcessId, String strWindowId,
      String strTabName, String strBPartner) throws IOException, ServletException {

    if (log4j.isDebugEnabled())
      log4j.debug("Output: Settlement");
    if (log4j.isDebugEnabled())
      log4j.debug(vars.commandIn("DEFAULT"));

    String strcBPartner = vars.getStringParameter("inpcBpartnerId");
    final String strPaymentRule = vars.getStringParameter("inppaymentrule");
    final String strPlannedDateFrom = vars.getDateParameter("inpplanneddateFrom",this);
    final String strPlannedDateTo = vars.getDateParameter("inpplanneddateTo",this);
    final String strAmountFrom = vars.getNumericParameter("inpamountFrom");
    final String strAmountTo = vars.getNumericParameter("inpamountTo");
    final String strTotalAmount = vars.getNumericParameter("inpamount");
    String strIsReceipt = vars.getStringParameter("inpisreceipt");
    if (log4j.isDebugEnabled())
      log4j.debug("IsReceipt: " + strIsReceipt);
    final String isSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
    String strAutoCalc = vars.getStringParameter("inpAutoClaculated");
    String strAutoCalcSelect = "AMOUNT";

    if (strAutoCalc.equals("")) {
      strAutoCalcSelect = "WRITEOFFAMT";
      if (vars.commandIn("FRAME1"))
      strAutoCalc="Y";
    }

    final String strOrg = vars.getStringParameter("inpadOrgId");
    final String strMarcarTodos = vars.getStringParameter("inpTodos", "N");

    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_actionButton/CreateFrom_Settlement").createXmlDocument();
    CreateFromSettlementData[] data = null;

    if (vars.getSessionValue("CreateFrom|default").equals("1")) {

      vars.removeSessionValue("CreateFrom|default");

      /*
       * if (strcBPartner.equals("") && strPaymentRule.equals("") && strPlannedDateFrom.equals("")
       * && strPlannedDateTo.equals("") && strIsReceipt.equals("") && strTotalAmount.equals("") &&
       * strOrg.equals("")) {
       */

      // Modified 26-06-07
      if (log4j.isDebugEnabled())
        log4j.debug("strIsReceipt: \"\"");

      data = new CreateFromSettlementData[0];

      if (vars.commandIn("FRAME1")) {
        strcBPartner = strBPartner;
        strIsReceipt = isSOTrx;
      }
    } else {

      // Modified 26-06-07
      if (log4j.isDebugEnabled())
        log4j.debug("strIsReceipt: " + strIsReceipt);

      final int numRows = Integer.valueOf(CreateFromSettlementData.countRows(this, Utility
          .getContext(this, vars, "#User_Client", strWindowId), Utility.getContext(this, vars,
          "#User_Org", strWindowId), strcBPartner, strPaymentRule, strPlannedDateFrom,
          strPlannedDateTo, strIsReceipt, strAmountFrom, strAmountTo, strTotalAmount, strOrg));
      final int maxRows = Integer.valueOf(vars.getSessionValue("#RECORDRANGEINFO"));

      if (numRows > maxRows) {
        final OBError obError = new OBError();
        String strMsg = Utility.messageBD(this, "MAX_RECORDS_REACHED", vars.getLanguage());
        strMsg = strMsg.replaceAll("%returned%", String.valueOf(numRows));
        strMsg = strMsg.replaceAll("%shown%", String.valueOf(maxRows));
        obError.setMessage(strMsg);
        obError.setTitle("");
        obError.setType("WARNING");
        vars.setMessage("CreateFrom", obError);
      }

      if (this.myPool.getRDBMS().equalsIgnoreCase("ORACLE")) {
        data = CreateFromSettlementData.select(this, vars.getLanguage(), strMarcarTodos, "ROWNUM",
            strAutoCalcSelect, Utility.getContext(this, vars, "#User_Client", strWindowId), Utility
                .getContext(this, vars, "#User_Org", strWindowId), strcBPartner, strPaymentRule,
            strPlannedDateFrom, strPlannedDateTo, strIsReceipt, strAmountFrom, strAmountTo,
            strTotalAmount, strOrg, String.valueOf(maxRows), null);
      } else {
        data = CreateFromSettlementData.select(this, vars.getLanguage(), strMarcarTodos, "1",
            strAutoCalcSelect, Utility.getContext(this, vars, "#User_Client", strWindowId), Utility
                .getContext(this, vars, "#User_Org", strWindowId), strcBPartner, strPaymentRule,
            strPlannedDateFrom, strPlannedDateTo, strIsReceipt, strAmountFrom, strAmountTo,
            strTotalAmount, strOrg, null, String.valueOf(maxRows));
      }

    }

    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("path", strPath);
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("tableId", strTableId);
    xmlDocument.setParameter("processId", strProcessId);
    xmlDocument.setParameter("windowId", strWindowId);
    xmlDocument.setParameter("tabName", strTabName);
    xmlDocument.setParameter("autoCalculated", strAutoCalc);
    xmlDocument.setParameter("amountFrom", strAmountFrom);
    xmlDocument.setParameter("amountTo", strAmountTo);
    xmlDocument.setParameter("totalAmount", strTotalAmount);
    xmlDocument.setParameter("adOrgId", strOrg);
    xmlDocument.setParameter("marcarTodos", strMarcarTodos);

    xmlDocument.setParameter("paymentRule", strPaymentRule);

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "LIST", "",
          "All_Payment Rule", "",
          Utility.getContext(this, vars, "#AccessibleOrgTree", strWindowId), Utility.getContext(
              this, vars, "#User_Client", strWindowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, strWindowId, strPaymentRule);
      xmlDocument.setData("reportPaymentRule", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (final Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_Org_ID", "",
          "", Utility.getContext(this, vars, "#AccessibleOrgTree", strWindowId), Utility
              .getContext(this, vars, "#User_Client", strWindowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, strWindowId, strOrg);
      xmlDocument.setData("reportAD_Org_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (final Exception ex) {
      throw new ServletException(ex);
    }

    if (log4j.isDebugEnabled())
      log4j.debug("strcBPartner: " + strcBPartner);
    if (log4j.isDebugEnabled())
      log4j.debug("strPlannedDateFrom: " + strPlannedDateFrom);
    if (log4j.isDebugEnabled())
      log4j.debug("strPlannedDateTo: " + strPlannedDateTo);

    xmlDocument.setParameter("inpcBpartnerId", strcBPartner);
    xmlDocument.setParameter("inpBpartnerId_DES", CreateFromSettlementData.bpartner(this,
        strcBPartner));

    xmlDocument.setParameter("plannedDateFromdisplayFormat", vars
        .getSessionValue("#AD_SqlDateFormat"));
    xmlDocument
        .setParameter("plannedDateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("plannedDateFromValue", UtilsData.selectDisplayDatevalue(this,strPlannedDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));

    xmlDocument.setParameter("plannedDateTodisplayFormat", vars
        .getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("plannedDateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("plannedDateToValue", UtilsData.selectDisplayDatevalue(this,strPlannedDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));

    xmlDocument.setParameter("isreceiptPago", strIsReceipt);
    xmlDocument.setParameter("isreceiptCobro", strIsReceipt);

    {
      final OBError myMessage = vars.getMessage("CreateFrom");
      vars.removeMessage("CreateFrom");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setData("structure1", data);

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

 

 

  OBError saveMethod(VariablesSecureApp vars, String strKey, String strTableId,
      String strProcessId, String strWindowId) throws IOException, ServletException {
    if (strTableId.equals("392")||strTableId.equals("4AF9D81E51A04F2B987CD91AA9EE99F4"))
      return saveBank(vars, strKey, strTableId, strProcessId);
    else if (strTableId.equals("318"))
      return saveInvoice(vars, strKey, strTableId, strProcessId, strWindowId);
    else if (strTableId.equals("319"))
      return saveShipment(vars, strKey, strTableId, strProcessId, strWindowId);
    else if (strTableId.equals("800019"))
      return saveSettlement(vars, strKey, strTableId, strProcessId);
    else
      return null;
  }

  public OBError saveBank(VariablesSecureApp vars, String strKey, String strTableId,
      String strProcessId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Save: Bank");
    String strPayment = vars.getInStringParameter("inpcPaymentId", IsIDFilter.instance);
    String strStatementDate = vars.getDateParameter("inpstatementdate",this);
    String strDateplanned = "";
    String strChargeamt = "";
    String strProposedAmt = "";
    String strDiscount="";
    String strvwz1 = "";
    String strvwz2 = "";
    String strvwz3 = "";
    String strvwz4 = "";
    String strmemo = "";
    String message="Success";
    String strBankstatementId ="";
    BigDecimal acctdsum = BigDecimal.ZERO;
    if (strPayment.equals(""))
      return null;
    OBError myMessage = null;
    Connection conn = null;

    try {
      if (strStatementDate.isEmpty()) {
        	strStatementDate=CreateFromBankData.selectMacctAcctDate(this, strKey);
      }
      conn = this.getTransactionConnection();
      if (strPayment.startsWith("("))
        strPayment = strPayment.substring(1, strPayment.length() - 1);
      if (!strPayment.equals("")) {
        strPayment = Replace.replace(strPayment, "'", "");
        final StringTokenizer st = new StringTokenizer(strPayment, ",", false);
        while (st.hasMoreTokens()) {
          String strDebtPaymentId = st.nextToken().trim();
          if (!CreateFromBankData.NotIsReconcilied(conn, this, strDebtPaymentId)) {
            releaseRollbackConnection(conn);
            log4j
                .warn("CreateFrom.saveBank - debt_payment " + strDebtPaymentId + " is reconcilied");
            myMessage = Utility.translateError(this, vars, vars.getLanguage(),
                "DebtPaymentReconcilied");
            return myMessage;
          }
          strDateplanned = vars.getDateParameter("inpplanneddate" + strDebtPaymentId.trim(),this);
          strChargeamt = vars.getNumericParameter("inpcost" + strDebtPaymentId.trim());
          strProposedAmt = vars.getNumericParameter("inpproposed" + strDebtPaymentId.trim());
          String strConvertedAmt = vars.getNumericParameter("inpconverted" + strDebtPaymentId.trim());
          strDiscount = vars.getNumericParameter("inpdiscount" + strDebtPaymentId.trim());
          acctdsum=acctdsum.add(new BigDecimal(strProposedAmt).add(new BigDecimal(strChargeamt)));
          strvwz1 = FormatUtilities.padRight(vars.getStringParameter("inpvwz1" + strDebtPaymentId.trim()),35);
          strvwz2 = FormatUtilities.padRight(vars.getStringParameter("inpvwz2" + strDebtPaymentId.trim()),35);
          strvwz3 = FormatUtilities.padRight(vars.getStringParameter("inpvwz3" + strDebtPaymentId.trim()),35);
          strvwz4 = FormatUtilities.padRight(vars.getStringParameter("inpvwz4" + strDebtPaymentId.trim()),35);
          strmemo = (strvwz1 + strvwz2 +  strvwz3 +  strvwz4);
          // Amount + writeoff amount = FinalAmount to be paid/collected
          String strFinalAmount = CreateFromBankData.selectPaymentFinalAmount(this,
              strDebtPaymentId.trim());
          BigDecimal finalAmount = new BigDecimal(strFinalAmount);
          BigDecimal discountAmount = BigDecimal.ZERO;
          BigDecimal compareAmt = BigDecimal.ZERO;
          if (strDiscount != null && !strDiscount.equals("")
              && new BigDecimal(strDiscount).signum() != 0) {
            discountAmount = new BigDecimal(strDiscount);
          }
          // SZ made modifications for discounts....
          // If Bankstatement-Line doen't Match Due AMT (Discount or DEB left)
          // Fixed Issue 448
          // TODO Reverse Order: First Create Bankstatementline, then Settlement. create a Database constraint between settlement and bankstmtline after this. 
          final String strSequence = SequenceIdData.getUUID();
          if (strProposedAmt != null && !strProposedAmt.equals("")
              && new BigDecimal(strProposedAmt).signum() != 0
              && new BigDecimal(strProposedAmt).compareTo(finalAmount) != 0) {
                final String strSettlement = SequenceIdData.getUUID();
                final String strDocNo = Utility.getDocumentNoConnection(conn, this, vars.getClient(),
                    "C_Settlement", true);
                CreateFromBankData.insertSettlement(conn, this, strSettlement, vars.getUser(),
                    strDocNo, strDateplanned.equals("") ? strStatementDate : strDateplanned, strSequence,strDebtPaymentId);
                final String strNewPayment = SequenceIdData.getUUID();
                // New Payment with Partly payd amt - Create it and Cancel It!
                CreateFromBankData.insertPayment(conn, this, strNewPayment, vars.getUser(),
                    strSettlement, strProposedAmt, strDebtPaymentId);
                CreateFromBankData.cancelOriginalPayment(conn, this, strSettlement, strDebtPaymentId);
                // DEB left - remains open
                if (new BigDecimal(strProposedAmt).add(discountAmount).compareTo(finalAmount) != 0){
                CreateFromBankData.insertSecondPayment(conn, this, vars.getUser(), strSettlement,
                    strProposedAmt,strDiscount, strDebtPaymentId);
                }
                // Discount
                if (discountAmount.compareTo(BigDecimal.ZERO) !=0){
                  // Create a new settlement for discount
                  final String strNewSettlement = SequenceIdData.getUUID();
                  final String strNewDocNo = Utility.getDocumentNoConnection(conn, this, vars.getClient(),
                      "C_Settlement", true);
                  CreateFromBankData.insertSettlement(conn, this, strNewSettlement, vars.getUser(),
                      strNewDocNo, strDateplanned.equals("") ? strStatementDate : strDateplanned, strSequence, strDebtPaymentId);
                  // Create the Payment
                  CreateFromBankData.insertDiscountPayment(conn, this, vars.getUser(),
                      strSettlement,strNewSettlement, strDiscount, strDebtPaymentId);
                  // Cancel it.
                  // Do not Post. Settlement is POosted together with BstMt.
                  //CreateFromBankData.processSettlement(conn, this, strNewSettlement);
                }
                strDebtPaymentId = strNewPayment;
                //CreateFromBankData.processSettlement(conn, this, strSettlement);
          }
          
          
          try {
        	if (strTableId.equals("392")) { // BANK
	            // Insert Discount, too for better GUI-Representation
	            CreateFromBankData.insert(conn, this, strSequence, vars.getClient(), vars.getUser(),
	                strKey, strDateplanned.equals("") ? strStatementDate : strDateplanned,
	                strChargeamt, strDiscount,strmemo,strConvertedAmt,strDebtPaymentId);
        	}
        	if (strTableId.equals("4AF9D81E51A04F2B987CD91AA9EE99F4")) { // Manual Accounting Line
        		strBankstatementId=CreateFromBankData.selectBankStmtIdFromMacctline(this, strKey);
        		strmemo=CreateFromBankData.selectMacctDescription(this, strKey);
        		if (strBankstatementId!=null && ! strBankstatementId.isEmpty()) {
        			CreateFromBankData.insert(conn, this, strSequence, vars.getClient(), vars.getUser(),
        				strBankstatementId, strDateplanned.equals("") ? strStatementDate : strDateplanned,
    	                strChargeamt, strDiscount,strmemo,strConvertedAmt,strDebtPaymentId);
        		}
        	}
          } catch (final ServletException ex) {
            myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
            releaseRollbackConnection(conn);
            return myMessage;
          }
        } // while (st.hasMoreTokens()
        // Delete Manual Accounting Line
        if (strTableId.equals("4AF9D81E51A04F2B987CD91AA9EE99F4")) {
        	if (strBankstatementId!=null && ! strBankstatementId.isEmpty()) {
        		if (new BigDecimal(CreateFromBankData.selectMacctLineAmt(this, strKey)).compareTo(acctdsum)==0) {
        			CreateFromBankData.deleteMacctLineafterBST(conn, this, strKey);
        			message="AccLineDispatched";
        		} else {
        			CreateFromBankData.UpdateMacctLineAmt(conn,this, acctdsum.toString(),strKey);
        			message="AccLinePartlyDispatched";
        		}
        			
        	}
        }
      } // !strPayment.equals("")

      releaseCommitConnection(conn);
      myMessage = new OBError();
      if (strTableId.equals("4AF9D81E51A04F2B987CD91AA9EE99F4") && ! (strBankstatementId!=null && ! strBankstatementId.isEmpty())) {
    	  myMessage.setType("WARNING");
    	  message="NoBankstatementMatches";
      } else
    	  if (message.equals("AccLinePartlyDispatched"))
    		  myMessage.setType("WARNING");
    	  else
    		  myMessage.setType("Success");
      myMessage.setTitle("");
      myMessage.setMessage(Utility.messageBD(this, message, vars.getLanguage()));
    } catch (final Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (final Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage = Utility.translateError(this, vars, vars.getLanguage(), "Error:" + e.getMessage());
    }
    return myMessage;
  }

  protected OBError saveInvoice(VariablesSecureApp vars, String strKey, String strTableId,
      String strProcessId, String strWindowId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Save: Invoice");
  
    final String strType = vars.getRequiredStringParameter("inpType");
    final String strClaves = Utility.stringList(vars.getRequiredInParameter("inpcOrderId",
        IsIDFilter.instance));
    final String isSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
    String strPO = "";
    CreateFromInvoiceData[] data = null;
    OBError myMessage = null;
    Connection conn = null;
    String strDocTypeTargetId= "";
    // SZ Load Doctype to Determin Credit Memo (AR) - Only on Sales Invoice (167)/Purchase Invoice (183) Window
    if (strWindowId.equals("167"))
        strDocTypeTargetId= vars.getGlobalVariable("inpcDoctypeTargetId", "167" + "|C_DOCTYPETARGET_ID", "");
    if (strWindowId.equals("183"))
        strDocTypeTargetId= vars.getGlobalVariable("inpcDoctypeTargetId", "183" + "|C_DOCTYPETARGET_ID", "");
    try {
      conn = this.getTransactionConnection();
      // Created from Shipment
      if (strType.equals("SHIPMENT")) {
        
        data = CreateFromInvoiceData.selectFromShipmentUpdateSOTrx(conn, this, strClaves);
        
      // Created From ORDER
      } else {
        strPO = vars.getStringParameter("inpPurchaseOrder");
        // Creating Normal Sales or Purchase Invoice
        if (! strDocTypeTargetId.equals("3CD24CAE0D074B8FA9918178780D50FB") && ! strDocTypeTargetId.equals("A4277AD679DF4DD8A9C2BB9F3C2F2C92") )
          data = CreateFromInvoiceData.selectFromPOUpdateSOTrx(conn, this, strClaves);
        // Creating Credit Memo 
        if (strDocTypeTargetId.equals("3CD24CAE0D074B8FA9918178780D50FB") || strDocTypeTargetId.equals("A4277AD679DF4DD8A9C2BB9F3C2F2C92") )
          data = CreateFromInvoiceData.selectLoopFromOrderCreditMemo(conn, this, strClaves);
      }
      if (data != null) {
        for (int i = 0; i < data.length; i++) {
          final String strSequence = SequenceIdData.getUUID();
          final String strPriceList = vars.getRequiredStringParameter("inpMPricelist");
          final String strBPartnerLocation = vars.getRequiredStringParameter("inpcBpartnerLocationId");
          final String strBPartner = vars.getRequiredStringParameter("inpcBpartnerId");
          final String strDateInvoiced = vars.getDateParameter("inpDateInvoiced",this);
          String cTaxID=data[i].cTaxId;
          String strPriceStd=data[i].pricestd;
          String strPriceActual=data[i].priceactual;
          String strPriceLimit="0";
          String strListPrice=data[i].pricelist;
          if (cTaxID.equals("")){
            cTaxID = Tax.get(this, data[i].mProductId, strDateInvoiced, data[i].adOrgId, vars.getWarehouse(), strBPartnerLocation, strBPartnerLocation, CreateFromInvoiceData.selectProject(this, strKey), isSOTrx.equals("Y") ? true : false);
            CreateFromInvoiceData[] dataAux = null;
            dataAux = CreateFromInvoiceData.selectPrices(conn, this, data[i].mProductId,strPriceList,strDateInvoiced,strBPartner,data[i].pendingqty);
            strPriceStd=dataAux[0].pricestd;
            strPriceActual=dataAux[0].priceactual;
            strPriceLimit=dataAux[0].pricelimit;
            strListPrice=dataAux[0].pricelist;
            if (strPriceStd.equals(""))
              strPriceStd="0";
            if (strPriceActual.equals(""))
              strPriceActual="0";
            if (strPriceLimit.equals(""))
              strPriceLimit="0";
            if (strListPrice.equals(""))
              strListPrice="0";
          }
          
          try {
            CreateFromInvoiceData.insert(conn, this, strSequence, strKey, vars.getClient(),
                data[i].adOrgId, vars.getUser(), data[i].cOrderlineId, data[i].mInoutlineId,
                data[i].description, data[i].mProductId, data[i].cUomId, data[i].pendingqty, strListPrice,
                strPriceActual, strPriceLimit,"0", cTaxID, data[i].quantityorder,
                data[i].mProductUomId, data[i].mAttributesetinstanceId, strPriceStd,data[i].cProjectId,data[i].cProjecttaskId,
                data[i].aAssetId);
          } catch (final ServletException ex) {
            myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
            releaseRollbackConnection(conn);
            return myMessage;
          }
        }
      }

      if (!strPO.equals("")) {
        try {
          final int total = CreateFromInvoiceData.deleteC_Order_ID(conn, this, strKey, strPO);
          if (total == 0)
            CreateFromInvoiceData.updateC_Order_ID(conn, this, strPO, strKey);
        } catch (final ServletException ex) {
          myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
          releaseRollbackConnection(conn);
          return myMessage;
        }

      }

      releaseCommitConnection(conn);
      if (log4j.isDebugEnabled())
        log4j.debug("Save commit");
      myMessage = new OBError();
      myMessage.setType("Success");
      myMessage.setTitle("");
      myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    } catch (final Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (final Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
    }
    return myMessage;
  }

  protected OBError saveShipment(VariablesSecureApp vars, String strKey, String strTableId,
      String strProcessId, String strWindowId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Save: Shipment");
    final String isSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
    if (isSOTrx.equals("Y"))
      return saveShipmentSO(vars, strKey, strTableId, strProcessId, strWindowId);
    else
      return saveShipmentPO(vars, strKey, strTableId, strProcessId, strWindowId);
  }

  protected OBError saveShipmentPO(VariablesSecureApp vars, String strKey, String strTableId,
      String strProcessId, String strWindowId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Save: Shipment");
    final String strLocatorCommon = vars.getStringParameter("inpmLocatorId");
//  final String strType = vars.getRequiredStringParameter("inpType");
    final String strClaves = Utility.stringList(vars.getRequiredInParameter("inpId",
        IsIDFilter.instance));
    String strInvoice = "", strPO = "";
    CreateFromShipmentData[] data = null;
    OBError myMessage = null;
    Connection conn = null;
    try {
      conn = this.getTransactionConnection();
    //  if (strType.equals("INVOICE")) {
    //    strInvoice = vars.getStringParameter("inpInvoice");
    //    data = CreateFromShipmentData.selectFromInvoiceUpdate(conn, this, strClaves);
    //  } else {
        strPO = vars.getStringParameter("inpPurchaseOrder");
        data = CreateFromShipmentData.selectFromPOUpdate(conn, this, strClaves);
     // }
      if (data != null) {
        for (int i = 0; i < data.length; i++) {

          // Obtain the values from the window

          String strLineId = "";

       //   if (strType.equals("INVOICE")) {
       //     strLineId = data[i].cInvoicelineId;
       //   } else {
            strLineId = data[i].cOrderlineId;
       //   }

          final String strMovementqty = vars.getRequiredStringParameter("inpmovementqty"
              + strLineId);
          String strQuantityorder = "";
          String strProductUomId = "";
          String strLocator = vars.getStringParameter("inpmLocatorId" + strLineId);
          final String strmAttributesetinstanceId = vars
              .getStringParameter("inpmAttributesetinstanceId" + strLineId);
          final String strcUomIdConversion = "";
          String strbreakdown = "";
          CreateFromShipmentData[] dataUomIdConversion = null;

          if ("".equals(strLocator)) {
            strLocator = strLocatorCommon;
          }

          if ("".equals(data[i].mProductUomId)) {
            strQuantityorder = "";
            strProductUomId = "";
          } else {
            strQuantityorder = vars.getRequiredStringParameter("inpquantityorder" + strLineId);
            strProductUomId = vars.getRequiredStringParameter("inpmProductUomId" + strLineId);
            dataUomIdConversion = CreateFromShipmentData.selectcUomIdConversion(this,
                strProductUomId);

            if (dataUomIdConversion == null || dataUomIdConversion.length == 0) {
              dataUomIdConversion = CreateFromShipmentData.set();
              strbreakdown = "N";
            } else {
              strbreakdown = dataUomIdConversion[0].breakdown;
            }
          }

          //

          String strMultiplyRate = "";
          int stdPrecision = 0;
          if ("Y".equals(strbreakdown)) {
            if (dataUomIdConversion[i].cUomIdConversion.equals("")) {
              releaseRollbackConnection(conn);
              myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
              return myMessage;
            }
            final String strInitUOM = dataUomIdConversion[i].cUomIdConversion;
            final String strUOM = data[i].cUomId;
            if (strInitUOM.equals(strUOM))
              strMultiplyRate = "1";
            else
              strMultiplyRate = CreateFromShipmentData.multiplyRate(this, strInitUOM, strUOM);
            if (strMultiplyRate.equals(""))
              strMultiplyRate = CreateFromShipmentData.divideRate(this, strUOM, strInitUOM);
            if (strMultiplyRate.equals("")) {
              strMultiplyRate = "1";
              releaseRollbackConnection(conn);
              myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
              return myMessage;
            }
            stdPrecision = Integer.valueOf(dataUomIdConversion[i].stdprecision).intValue();
            BigDecimal quantity, qty, multiplyRate;
            
            multiplyRate = new BigDecimal(strMultiplyRate);
            qty = new BigDecimal(strMovementqty);
            boolean qtyIsNegative = false;
            if (qty.compareTo(ZERO) < 0) {
              qtyIsNegative = true;
              qty = qty.negate();
            }
            quantity = qty.multiply(multiplyRate);
            if (quantity.scale() > stdPrecision)
              quantity = quantity.setScale(stdPrecision, RoundingMode.HALF_UP);
            while (qty.compareTo(ZERO) > 0) {
              String total = "1";
              BigDecimal conversion;
              if (quantity.compareTo(BigDecimal.ONE) < 0) {
                total = quantity.toString();
                conversion = qty;
                quantity = ZERO;
                qty = ZERO;
              } else {
                conversion = multiplyRate;
                if (conversion.compareTo(qty) > 0) {
                  conversion = qty;
                  qty = ZERO;
                } else
                  qty = qty.subtract(conversion);
                quantity = quantity.subtract(BigDecimal.ONE);
              }
              final String strConversion = conversion.toString();
              final String strSequence = SequenceIdData.getUUID();
              try {
                CreateFromShipmentData.insert(conn, this, strSequence, strKey, vars.getClient(),
                    data[i].adOrgId, vars.getUser(), data[i].description, data[i].mProductId,
                    data[i].cUomId, (qtyIsNegative ? "-" + strConversion : strConversion),
                    data[i].cOrderlineId, strLocator, CreateFromShipmentData.isInvoiced(conn, this,
                        data[i].cInvoicelineId), (qtyIsNegative ? "-" + total : total),
                    data[i].mProductUomId, strmAttributesetinstanceId,
                    CreateFromShipmentData.selectProjectId(this, data[i].cOrderlineId), 
                    CreateFromShipmentData.selectProjectTaskId(this, data[i].cOrderlineId),
                    CreateFromShipmentData.selectAssetId(this, data[i].cOrderlineId));
                if (!strInvoice.equals(""))
                  CreateFromShipmentData.updateInvoice(conn, this, strSequence,
                      data[i].cInvoicelineId);
                else
                  CreateFromShipmentData.updateInvoiceOrder(conn, this, strSequence,
                      data[i].cOrderlineId);
              } catch (final ServletException ex) {
                myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
                releaseRollbackConnection(conn);
                return myMessage;
              }
            }
          } else {
            final String strSequence = SequenceIdData.getUUID();
            try {
              CreateFromShipmentData.insert(conn, this, strSequence, strKey, vars.getClient(),
                  data[i].adOrgId, vars.getUser(), data[i].description, data[i].mProductId,
                  data[i].cUomId, strMovementqty, data[i].cOrderlineId, strLocator,
                  CreateFromShipmentData.isInvoiced(conn, this, data[i].cInvoicelineId),
                  strQuantityorder, strProductUomId, strmAttributesetinstanceId,
                  CreateFromShipmentData.selectProjectId(this, data[i].cOrderlineId),
                  CreateFromShipmentData.selectProjectTaskId(this, data[i].cOrderlineId),
                  CreateFromShipmentData.selectAssetId(this, data[i].cOrderlineId));
              if (!strInvoice.equals(""))
                CreateFromShipmentData.updateInvoice(conn, this, strSequence,
                    data[i].cInvoicelineId);
              else
                CreateFromShipmentData.updateInvoiceOrder(conn, this, strSequence,
                    data[i].cOrderlineId);
            } catch (final ServletException ex) {
              myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
              releaseRollbackConnection(conn);
              return myMessage;
            }
          }
        }
      }

      if (!strPO.equals("")) {
        try {
          final int total = CreateFromShipmentData.deleteC_Order_ID(conn, this, strKey, strPO);
          if (total == 0)
            CreateFromShipmentData.updateC_Order_ID(conn, this, strPO, strKey);
        } catch (final ServletException ex) {
          myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
          releaseRollbackConnection(conn);
          return myMessage;
        }
      }
      if (!strInvoice.equals("")) {
        try {
          final int total = CreateFromShipmentData.deleteC_Invoice_ID(conn, this, strKey,
              strInvoice);
          if (total == 0)
            CreateFromShipmentData.updateC_Invoice_ID(conn, this, strInvoice, strKey);
        } catch (final ServletException ex) {
          myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
          releaseRollbackConnection(conn);
          return myMessage;
        }
      }

      releaseCommitConnection(conn);
      if (log4j.isDebugEnabled())
        log4j.debug("Save commit");
      myMessage = new OBError();
      myMessage.setType("Success");
      myMessage.setTitle("");
      myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    } catch (final Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (final Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
    }
    return myMessage;
  }

  protected OBError saveShipmentSO(VariablesSecureApp vars, String strKey, String strTableId,
      String strProcessId, String strWindowId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Save: Shipment");
    // SZ: Locator schould not be required
    // TODO : Get the Locator from reserved Inventory 
    final String strLocator = vars.getStringParameter("inpmLocatorId");
    final String strType = vars.getRequiredStringParameter("inpType");
    final String strClaves = Utility.stringList(vars.getRequiredInParameter("inpId",
        IsIDFilter.instance));
    String strInvoice = "", strPO = "";
    CreateFromShipmentData[] data = null;
    OBError myMessage = null;
    Connection conn = null;
    // SZ Load Doctype to Determin Credit Memo (AR) - Only on Shipment (169) Window
    String strDocTypeId= "";
    if (strWindowId.equals("169"))
        strDocTypeId= vars.getGlobalVariable("inpcDoctypeTargetId", "169" + "|C_DOCTYPE_ID", "");
    try {
      conn = this.getTransactionConnection();
      if (strType.equals("INVOICE")) {
        strInvoice = vars.getStringParameter("inpInvoice");
        // Normal Shipment selected from Sales Invoice
        // Material Return  is not possible on Invoices
        data = CreateFromShipmentData.selectFromInvoiceTrxUpdate(conn, this, strClaves);
      } else {
        strPO = vars.getStringParameter("inpPurchaseOrder");
        if (! strDocTypeId.equals("2317023F9771481696461C5EAF9A0915"))
          // Normal Shipment selected from Sales Order
          data = CreateFromShipmentData.selectFromPOUpdateSOTrx(conn, this, strClaves);
        else
          // Material Return selected from Sales Order
          data = CreateFromShipmentData.selectLoopFromOrderReturn(conn, this, strClaves);
      }
      if (data != null) {
        for (int i = 0; i < data.length; i++) {
          String strMultiplyRate = "";
          int stdPrecision = 0;
          if (data[i].breakdown.equals("Y")) {
            if (data[i].cUomIdConversion.equals("")) {
              releaseRollbackConnection(conn);
              myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
              return myMessage;
            }
            final String strInitUOM = data[i].cUomIdConversion;
            final String strUOM = data[i].cUomId;
            if (strInitUOM.equals(strUOM))
              strMultiplyRate = "1";
            else
              strMultiplyRate = CreateFromShipmentData.multiplyRate(this, strInitUOM, strUOM);
            if (strMultiplyRate.equals(""))
              strMultiplyRate = CreateFromShipmentData.divideRate(this, strUOM, strInitUOM);
            if (strMultiplyRate.equals("")) {
              strMultiplyRate = "1";
              releaseRollbackConnection(conn);
              myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
              return myMessage;
            }
            stdPrecision = Integer.valueOf(data[i].stdprecision).intValue();
            BigDecimal quantity, qty, multiplyRate;

            multiplyRate = new BigDecimal(strMultiplyRate);
            qty = new BigDecimal(data[i].id);
            boolean qtyIsNegative = false;
            if (qty.compareTo(ZERO) < 0) {
              qtyIsNegative = true;
              qty = qty.negate();
            }
            quantity = qty.multiply(multiplyRate);
            if (quantity.scale() > stdPrecision)
              quantity = quantity.setScale(stdPrecision, RoundingMode.HALF_UP);
            while (qty.compareTo(ZERO) > 0) {
              String total = "1";
              BigDecimal conversion;
              if (quantity.compareTo(BigDecimal.ONE) < 0) {
                total = quantity.toString();
                conversion = qty;
                quantity = ZERO;
                qty = ZERO;
              } else {
                conversion = multiplyRate;
                if (conversion.compareTo(qty) > 0) {
                  conversion = qty;
                  qty = ZERO;
                } else
                  qty = qty.subtract(conversion);
                quantity = quantity.subtract(BigDecimal.ONE);
              }
              final String strConversion = conversion.toString();
              final String strSequence = SequenceIdData.getUUID();
              try {
                CreateFromShipmentData.insert(conn, this, strSequence, strKey, vars.getClient(),
                    data[i].adOrgId, vars.getUser(), data[i].description, data[i].mProductId,
                    data[i].cUomId, (qtyIsNegative ? "-" + strConversion : strConversion),
                    data[i].cOrderlineId, strLocator, CreateFromShipmentData.isInvoiced(conn, this,
                        data[i].cInvoicelineId), (qtyIsNegative ? "-" + total : total),
                    data[i].mProductUomId, data[i].mAttributesetinstanceId,
                    CreateFromShipmentData.selectProjectId(this, data[i].cOrderlineId),
                    CreateFromShipmentData.selectProjectTaskId(this, data[i].cOrderlineId),
                    CreateFromShipmentData.selectAssetId(this, data[i].cOrderlineId));
                if (!strInvoice.equals(""))
                  CreateFromShipmentData.updateInvoice(conn, this, strSequence,
                      data[i].cInvoicelineId);
                else
                  CreateFromShipmentData.updateInvoiceOrder(conn, this, strSequence,
                      data[i].cOrderlineId);
              } catch (final ServletException ex) {
                myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
                releaseRollbackConnection(conn);
                return myMessage;
              }
            }
          } else {
            final String strSequence = SequenceIdData.getUUID();
            try {
              CreateFromShipmentData.insert(conn, this, strSequence, strKey, vars.getClient(),
                  data[i].adOrgId, vars.getUser(), data[i].description, data[i].mProductId,
                  data[i].cUomId, data[i].id, data[i].cOrderlineId, strLocator,
                  CreateFromShipmentData.isInvoiced(conn, this, data[i].cInvoicelineId),
                  data[i].quantityorder, data[i].mProductUomId, data[i].mAttributesetinstanceId,
                  CreateFromShipmentData.selectProjectId(this, data[i].cOrderlineId),
                  CreateFromShipmentData.selectProjectTaskId(this, data[i].cOrderlineId),
                  CreateFromShipmentData.selectAssetId(this, data[i].cOrderlineId));
              if (!strInvoice.equals(""))
                CreateFromShipmentData.updateInvoice(conn, this, strSequence,
                    data[i].cInvoicelineId);
              else
                CreateFromShipmentData.updateInvoiceOrder(conn, this, strSequence,
                    data[i].cOrderlineId);
            } catch (final ServletException ex) {
              myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
              releaseRollbackConnection(conn);
              return myMessage;
            }
          }
        }
      }

      if (!strPO.equals("")) {
        try {
          final int total = CreateFromShipmentData.deleteC_Order_ID(conn, this, strKey, strPO);
          if (total == 0)
            CreateFromShipmentData.updateC_Order_ID(conn, this, strPO, strKey);
        } catch (final ServletException ex) {
          myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
          releaseRollbackConnection(conn);
          return myMessage;
        }
      }
      if (!strInvoice.equals("")) {
        try {
          final int total = CreateFromShipmentData.deleteC_Invoice_ID(conn, this, strKey,
              strInvoice);
          if (total == 0)
            CreateFromShipmentData.updateC_Invoice_ID(conn, this, strInvoice, strKey);
        } catch (final ServletException ex) {
          myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
          releaseRollbackConnection(conn);
          return myMessage;
        }
      }

      releaseCommitConnection(conn);
      if (log4j.isDebugEnabled())
        log4j.debug("Save commit");
      myMessage = new OBError();
      myMessage.setType("Success");
      myMessage.setTitle("");
      myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    } catch (final Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (final Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
    }
    return myMessage;
  }

 

  protected OBError saveSettlement(VariablesSecureApp vars, String strKey, String strTableId,
      String strProcessId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Save: Settlement");
    String strDebtPayment = vars.getInStringParameter("inpcDebtPaymentId", IsIDFilter.instance);
    if (strDebtPayment.equals(""))
      return null;
    OBError myMessage = null;
    Connection conn = null;
    try {
      conn = this.getTransactionConnection();
      if (strDebtPayment.startsWith("("))
        strDebtPayment = strDebtPayment.substring(1, strDebtPayment.length() - 1);
      if (!strDebtPayment.equals("")) {
        strDebtPayment = Replace.replace(strDebtPayment, "'", "");
        final StringTokenizer st = new StringTokenizer(strDebtPayment, ",", false);
        while (st.hasMoreTokens()) {
          final String strDebtPaymentId = st.nextToken().trim();
          final String strWriteOff = vars.getNumericParameter("inpwriteoff" + strDebtPaymentId);
          final String strIsPaid = vars.getStringParameter("inpispaid" + strDebtPaymentId, "N");
          if (!CreateFromSettlementData.NotIsCancelled(conn, this, strDebtPaymentId)) {
            releaseRollbackConnection(conn);
            log4j.warn("CreateFrom.saveSettlement - debt_payment " + strDebtPaymentId
                + " is cancelled");
            myMessage = Utility.translateError(this, vars, vars.getLanguage(),
                "DebtPaymentCancelled");
            return myMessage;
          }
          try {
            CreateFromSettlementData.update(conn, this, vars.getUser(), strKey, strWriteOff,
                strIsPaid, strDebtPaymentId);
          } catch (final ServletException ex) {
            myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
            releaseRollbackConnection(conn);
            return myMessage;
          }
        }
      }
      releaseCommitConnection(conn);
      myMessage = new OBError();
      myMessage.setType("Success");
      myMessage.setTitle("");
      myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    } catch (final Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (final Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage = Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
    }
    return myMessage;
  }
  

  @Override
  public String getServletInfo() {
    return "Servlet that presents the button of CreateFrom";
  } // end of getServletInfo() method
}
