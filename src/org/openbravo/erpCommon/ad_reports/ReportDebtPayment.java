/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011-2012 Stefan Zimmermann
****************************************************************************************************************************************************
 */
package org.openbravo.erpCommon.ad_reports;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter; 
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.info.SelectorUtilityData;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.view.templates.*;
import org.openz.controller.businessprocess.BprocessCommonData;
import org.openz.util.UtilsData;

public class ReportDebtPayment extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    String strsalesrepId = vars.getGlobalVariable("inpSalesrepId", "ReportDebtPayment|SalesrepId", "");
    String strupdatedby = vars.getGlobalVariable("inpupdatedby", "ReportDebtPayment|updatedby", "");
    if (vars.commandIn("DEFAULT", "DIRECT")) {
      String strcbankaccount = vars.getGlobalVariable("inpmProductId","ReportDebtPayment|C_Bankaccount_ID", "");
      String strC_BPartner_ID;
      String strDateFrom;
      String strDateTo;
      String strAD_Org_ID = vars.getSessionValue("ReportDebtPayment|AD_Org_ID");
      
      if (strAD_Org_ID.isEmpty()) {
        strAD_Org_ID=vars.getOrg();
        vars.setSessionValue("ReportDebtPayment|AD_Org_ID", strAD_Org_ID);
      }
      
      // When the Business Partner Multiple Selector is added to this
      // report, it will continue supporting the previous BP selector
      String strcBpartnerId; // BP Multiple Selector Variable
      // If this report is reached through the AgingBalance Report, some
      // session variables are ignored, so Aging Balance data is readden
      if (vars.getStringParameter("inpFlagFromAging").equals("Y")) {
        strC_BPartner_ID = vars.getStringParameter("inpBpartnerId");
        strDateFrom = vars.getDateParameter("inpDateFrom",this);
        strDateTo = vars.getDateParameter("inpDateTo",this);
        if (strC_BPartner_ID.length() > 0) {
          strcBpartnerId = "('" + strC_BPartner_ID + "')";
        } else {
          // strcBpartnerId =
          // vars.getInStringParameter("inpcBPartnerId_IN");
          strcBpartnerId = vars.getInGlobalVariable("inpcBPartnerId_IN",
              "ReportAgingBalance|cBpartnerId", "", IsIDFilter.instance);
          vars.setSessionValue("ReportDebtPayment|C_BPartner_ID", strcBpartnerId);
        }
      } else {
        strC_BPartner_ID = vars.getGlobalVariable("inpBpartnerId",
            "ReportDebtPayment|C_BPartner_ID", "");
        strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom", "ReportDebtPayment|DateFrom", "",this);
        strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportDebtPayment|DateTo", "",this);
        strcBpartnerId = vars.getGlobalVariable("inpcBPartnerId_IN",
            "ReportDebtPayment|inpcBPartnerId_IN", "");
      }
      String strCal1 = vars.getNumericGlobalVariable("inpCal1", "ReportDebtPayment|Cal1", "");
      String strCal2 = vars.getNumericGlobalVariable("inpCal2", "ReportDebtPayment|Cal2", "");
      String strPaymentRule = vars.getGlobalVariable("inpCPaymentRuleId",
          "ReportDebtPayment|PaymentRule", "");
      String strSettle = vars.getGlobalVariable("inpSettle", "ReportDebtPayment|Settle", "");
      String strConciliate = vars.getGlobalVariable("inpConciliate",
          "ReportDebtPayment|Conciliate", "");
      String strStatus = vars.getGlobalVariable("inpStatus", "ReportDebtPayment|Status", "");
      String strGroup = vars.getGlobalVariable("inpGroup", "ReportDebtPayment|Group", "isGroup");
      String strPending = "";
      String strReceipt = "";
      
     
      
      if (vars.commandIn("DIRECT")) {
        strReceipt = vars.getGlobalVariable("inpReceipt", "ReportDebtPayment|Receipt", "N");
        strPending = vars.getGlobalVariable("inpPending", "ReportDebtPayment|Pending", "");
      } else {
        strReceipt = vars.getGlobalVariable("inpReceipt", "ReportDebtPayment|Receipt", "Y");
        strPending = vars.getGlobalVariable("inpPending", "ReportDebtPayment|Pending", "isPending");
      }
      // String strEntry = vars.getGlobalVariable("inpEntry",
      // "ReportDebtPayment|Entry","0");
      setHistoryCommand(request, "DIRECT");
      String strGroupBA = vars.getRequestGlobalVariable("inpGroupBA", "ReportDebtPayment|Group");
      try {
        printPageDataSheet(response, vars,strAD_Org_ID, strcBpartnerId, strDateFrom, strDateTo, strCal1, strCal2,
            strPaymentRule, strSettle, strConciliate, strReceipt, strPending, strcbankaccount,
            strStatus, strGroup, strGroupBA, strsalesrepId, strupdatedby);
      } catch (Exception e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    } else if (vars.commandIn("FIND") || vars.commandIn("SAVE")) {
      String strcbankaccount = vars.getRequestGlobalVariable("inpcBankAccountId",
          "ReportDebtPayment|C_Bankaccount_ID");
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportDebtPayment|inpcBPartnerId_IN", IsIDFilter.instance);
      String strAD_Org_ID = vars.getRequestGlobalVariable("inpAdOrgId",
          "ReportDebtPayment|AD_Org_ID");
      // String strC_BPartner_ID =
      // vars.getRequestGlobalVariable("inpBpartnerId",
      // "ReportDebtPayment|C_BPartner_ID");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportDebtPayment|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportDebtPayment|DateTo",this);
      String strCal1 = vars.getNumericRequestGlobalVariable("inpCal1", "ReportDebtPayment|Cal1");
      String strCal2 = vars.getNumericRequestGlobalVariable("inpCal2", "ReportDebtPayment|Cal2");
      String strPaymentRule = vars.getRequestGlobalVariable("inpCPaymentRuleId",
          "ReportDebtPayment|PaymentRule");
      String strSettle = vars.getRequestGlobalVariable("inpSettle", "ReportDebtPayment|Settle");
      String strConciliate = vars.getRequestGlobalVariable("inpConciliate",
          "ReportDebtPayment|Conciliate");
      String strPending = vars.getRequestGlobalVariable("inpPending", "ReportDebtPayment|Pending");
      String strGroup = vars.getRequestGlobalVariable("inpGroup", "ReportDebtPayment|Group");
      String strStatus = vars.getRequestGlobalVariable("inpStatus", "ReportDebtPayment|Status");
      // String strReceipt = vars.getRequestGlobalVariable("inpReceipt",
      // "ReportDebtPayment|Receipt");
      String strReceipt = vars.getStringParameter("inpReceipt").equals("") ? "N" : vars
          .getStringParameter("inpReceipt");
      vars.setSessionValue("ReportDebtPayment|Receipt", strReceipt);
      // String strEntry = vars.getGlobalVariable("inpEntry",
      // "ReportDebtPayment|Entry","1");
      setHistoryCommand(request, "DIRECT");
      String strGroupBA = vars.getRequestGlobalVariable("inpGroupBA", "ReportDebtPayment|Group");

      strsalesrepId = vars.getRequestGlobalVariable("inpSalesrepId", "ReportDebtPayment|SalesrepId");
      strupdatedby = vars.getRequestGlobalVariable("inpupdatedby", "ReportDebtPayment|updatedby");
      if (vars.commandIn("SAVE")){
          String strAllLines = vars.getRequiredInStringParameter("inpHiddenID", IsIDFilter.instance);
          String strSelectedLines = vars.getInStringParameter("inpSelected", IsIDFilter.instance);
          String helperAllLines = strAllLines.replace("(", "").replace(")", "").replace("'", "").replace(" ", "");
          String helperSelectedLines = strSelectedLines.replace("(", "").replace(")", "").replace("'", "").replace(" ", "");
          String[] AllLines = helperAllLines.split(",");
          String[] SelectedLines = helperSelectedLines.split(",");
          String strNotSelectedLines = "(";
          for (int i = 0; i < AllLines.length; i++) {
            if (!Arrays.asList(SelectedLines).contains(AllLines[i])) {
              strNotSelectedLines = strNotSelectedLines + "'" + AllLines[i] + "', ";
            }
          }
          if (!strNotSelectedLines.equals("(")) strNotSelectedLines = strNotSelectedLines.substring(0, strNotSelectedLines.length() - 2) + ")";
          String struser=vars.getUser();
          int approved = 0;
          int unapproved = 0;
          if (!strSelectedLines.equals("")) approved = ReportDebtPaymentData.approve(myPool, struser, strSelectedLines);
          if (!strNotSelectedLines.equals("(")) unapproved = ReportDebtPaymentData.unapprove(myPool, struser, strNotSelectedLines);
          OBError myMessage = new OBError();         
          myMessage.setType("SUCCESS");
          myMessage.setTitle("Genehmigung");
          myMessage.setMessage("Zahlung(en) genehmigt");
          vars.setMessage("ReportDebtPayment", myMessage);
          BprocessCommonData.updateAlertrule(this, null);
      }
      try {
        printPageDataSheet(response, vars,strAD_Org_ID, strcBpartnerId, strDateFrom, strDateTo, strCal1, strCal2,
            strPaymentRule, strSettle, strConciliate, strReceipt, strPending, strcbankaccount,
            strStatus, strGroup, strGroupBA, strsalesrepId, strupdatedby);
      } catch (Exception e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    } else if (vars.commandIn("PRINT_PDF")) {
      String strcbankaccount = vars.getRequestGlobalVariable("inpcBankAccountId",
          "ReportDebtPayment|C_Bankaccount_ID");
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportDebtPayment|inpcBPartnerId_IN", IsIDFilter.instance);
      String strAD_Org_ID = vars.getSessionValue("ReportDebtPayment|AD_Org_ID");
      if (strAD_Org_ID.isEmpty()) {
        strAD_Org_ID=vars.getOrg();
        //vars.setSessionValue("ReportDebtPayment|AD_Org_ID", strAD_Org_ID);
      }
      // String strC_BPartner_ID = vars.getRequestGlobalVariable("inpBpartnerId",
      // "ReportDebtPayment|C_BPartner_ID");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportDebtPayment|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportDebtPayment|DateTo",this);
      String strCal1 = vars.getNumericRequestGlobalVariable("inpCal1", "ReportDebtPayment|Cal1");
      String strCal2 = vars.getNumericRequestGlobalVariable("inpCal2", "ReportDebtPayment|Cal2");
      String strPaymentRule = vars.getRequestGlobalVariable("inpCPaymentRuleId",
          "ReportDebtPayment|PaymentRule");
      String strSettle = vars.getRequestGlobalVariable("inpSettle", "ReportDebtPayment|Settle");
      String strConciliate = vars.getRequestGlobalVariable("inpConciliate",
          "ReportDebtPayment|Conciliate");
      String strPending = vars.getRequestGlobalVariable("inpPending", "ReportDebtPayment|Pending");
      String strGroup = vars.getRequestGlobalVariable("inpGroup", "ReportDebtPayment|Group");
      String strGroupBA = vars.getRequestGlobalVariable("inpGroupBA", "ReportDebtPayment|Group");
      String strStatus = vars.getRequestGlobalVariable("inpStatus", "ReportDebtPayment|Status");
      String strTreeOrg = ReportDebtPaymentData.treeOrg(this, vars.getClient());
      // String strReceipt = vars.getRequestGlobalVariable("inpReceipt",
      // "ReportDebtPayment|Receipt");
      String strReceipt = vars.getStringParameter("inpReceipt").equals("") ? "N" : vars
          .getStringParameter("inpReceipt");
      vars.setSessionValue("ReportDebtPayment|Receipt", strReceipt);
      // String strEntry = vars.getGlobalVariable("inpEntry", "ReportDebtPayment|Entry","1");
      setHistoryCommand(request, "DIRECT");
      printPageDataPdf(response, vars, strAD_Org_ID,strcBpartnerId, strDateFrom, strDateTo, strCal1, strCal2,
          strPaymentRule, strSettle, strConciliate, strReceipt, strPending, strcbankaccount,
          strStatus, strGroup, strsalesrepId, strupdatedby, strGroupBA);
    } else
      pageError(response);
  }

  private void printPageDataPdf(HttpServletResponse response, VariablesSecureApp vars,
      String strAD_Org_ID, String strC_BPartner_ID, String strDateFrom, String strDateTo, String strCal1,
      String strCalc2, String strPaymentRule, String strSettle, String strConciliate,
      String strReceipt, String strPending, String strcbankaccount, String strStatus,
      String strGroup, String strsalesrepId, String strupdatedby, String strGroupBA) throws IOException, ServletException {
    String strAux = "";
    if (log4j.isDebugEnabled())
      log4j.debug("strGroup = " + strGroup);
 
    if (strConciliate.equals("isConciliate"))
      strAux="'N','Y'";
    else
      strAux = "'N'";
    String strTreeOrg = ReportDebtPaymentData.treeOrg(this, vars.getClient());
    ReportDebtPaymentData[] data = null;
    String strReportName = null;
    if (strAD_Org_ID.equals("0"))
      strAD_Org_ID=Tree.getMembers(this, strTreeOrg, strAD_Org_ID);
    else
      strAD_Org_ID="'"+ strAD_Org_ID+"'";
    if (!strGroup.equals("")) {

      data = ReportDebtPaymentData.selectReport(this, vars.getLanguage(), Utility.getContext(this, vars,
          "#User_Client", "ReportDebtPayment"), strAD_Org_ID, strC_BPartner_ID, strDateFrom, DateTimeData
          .nDaysAfter(this, strDateTo, "1"), strCal1, strCalc2, strPaymentRule, strReceipt,
          strStatus,  strcbankaccount, strsalesrepId, strupdatedby,strAux, "BPARTNER, BANKACC");
      if (!strGroupBA.equals("")) {
        strReportName = this.strBasePath + "/src-loc/design/org/openbravo/erpCommon/ad_reports/ReportDebtPayment_BankAcc.jrxml";
      } else {
        strReportName = this.strBasePath + "/src-loc/design/org/openbravo/erpCommon/ad_reports/ReportDebtPayment.jrxml";
      }
 
    } else {
      data = ReportDebtPaymentData.selectReportNoBPartner(this, vars.getLanguage(), Utility.getContext(this, vars,
          "#User_Client", "ReportDebtPayment"), strAD_Org_ID, strC_BPartner_ID, strDateFrom, DateTimeData
          .nDaysAfter(this, strDateTo, "1"), strCal1, strCalc2, strPaymentRule, strReceipt,
          strStatus,  strcbankaccount, strsalesrepId, strupdatedby,strAux, "BPARTNER, BANKACC");
      if (!strGroupBA.equals("")) {
        strReportName = this.strBasePath + "/src-loc/design/org/openbravo/erpCommon/ad_reports/ReportDebtPayment_NoBP_BankAcc.jrxml";
      } else {
        strReportName = this.strBasePath + "/src-loc/design/org/openbravo/erpCommon/ad_reports/ReportDebtPayment_NoBP.jrxml";
      }
    }
    String title=ReportDebtPaymentData.getHeader(this, vars.getLanguage(), strDateFrom, strDateTo, strReceipt,strAD_Org_ID);
    HashMap<String, Object> parameters = new HashMap<String, Object>();
    parameters.put("group", "no"); 
    parameters.put("HEADER", title);
    renderJR(vars, response, strReportName, "pdf", parameters, data, null);

  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strAD_Org_ID, String strC_BPartner_ID, String strDateFrom, String strDateTo, String strCal1,
      String strCalc2, String strPaymentRule, String strSettle, String strConciliate,
      String strReceipt, String strPending, String strcbankaccount, String strStatus,
      String strGroup, String strGroupBA, String strsalesrepId, String strupdatedby) throws Exception {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    String discard[] = { "discard", "discard2", "discard3", "discard4", "discard5", "discard6",
        "discard7", "discard8" };
    String strAux = "";
    if (log4j.isDebugEnabled())
      log4j.debug("strGroup = " + strGroup);
    if (strPending.equals("") && strConciliate.equals("") && strSettle.equals("")) {
      strAux = "";
    } else {
      if (strPending.equals("isPending")) {
        strAux = "'P'";
      }
      if (strConciliate.equals("isConciliate")) {
        if (!strAux.equals("")) {
          strAux = strAux + ",";
        }
        strAux = strAux + "'C'";
      }
      if (strSettle.equals("isSettle")) {
        if (!strAux.equals("")) {
          strAux = strAux + ",";
        }
        strAux = strAux + "'A'";
      }
      strAux = "(" + strAux + ")";
    }
    XmlDocument xmlDocument;
    ReportDebtPaymentData[] data = null;
    String strTreeOrg = ReportDebtPaymentData.treeOrg(this, vars.getClient());
    String  strAD_Org_Sel=strAD_Org_ID;
    if (strAD_Org_ID.equals("0"))
      strAD_Org_Sel=Tree.getMembers(this, strTreeOrg, strAD_Org_ID);
    else
      strAD_Org_Sel="'"+ strAD_Org_ID+"'";
    if (!strGroup.equals(""))
      data = ReportDebtPaymentData.select(this, vars.getLanguage(), Utility.getContext(this, vars,
          "#User_Client", "ReportDebtPayment"), strAD_Org_Sel, strC_BPartner_ID, strDateFrom, DateTimeData
          .nDaysAfter(this, strDateTo, "1"), strCal1, strCalc2, strPaymentRule, strReceipt,
          strStatus, strAux, strcbankaccount, strsalesrepId, strupdatedby, "BPARTNER, BANKACC");
    else
      data = ReportDebtPaymentData.selectNoBpartner(this, vars.getLanguage(), Utility.getContext(
          this, vars, "#User_Client", "ReportDebtPayment"), strAD_Org_Sel, strC_BPartner_ID, strDateFrom, DateTimeData
          .nDaysAfter(this, strDateTo, "1"), strCal1, strCalc2, strPaymentRule, strReceipt,
          strStatus, strAux, strcbankaccount, strsalesrepId, strupdatedby,  "BANKACC, BPARTNER");
    
    if (data == null || data.length == 0) {
      data = ReportDebtPaymentData.set();
      discard[0] = "sectionBpartner";
      discard[1] = "sectionStatus2";
      discard[2] = "sectionTotal2";
      discard[3] = "sectionBankAcc";
      discard[4] = "sectionTotal3";
      discard[5] = "sectionTotal4";
      discard[6] = "sectionAll";
      if (!strGroup.equals("")) {
        discard[7] = "sectionDetail2";
      } else {
        discard[7] = "sectionTotal";
      }
    } else {
      if (!strGroupBA.equals("") && !strGroup.equals("")) {
        discard[0] = "sectionDetail2";
        discard[1] = "sectionStatus2";
        discard[2] = "sectionTotal2";
        discard[3] = "sectionBpartner";
        discard[4] = "sectionTotal";
        discard[5] = "sectionBankAcc";
        discard[6] = "sectionTotal3";
      } else if (!strGroupBA.equals("")) {
        discard[0] = "sectionDetail2";
        discard[1] = "sectionStatus2";
        discard[2] = "sectionTotal2";
        discard[3] = "sectionBpartner";
        discard[4] = "sectionTotal";
        discard[5] = "sectionTotal4";
      } else if (!strGroup.equals("")) {
        discard[0] = "sectionDetail2";
        discard[1] = "sectionStatus2";
        discard[2] = "sectionTotal2";
        discard[3] = "sectionBankAcc";
        discard[4] = "sectionTotal3";
        discard[5] = "sectionTotal4";

      } else {
        discard[0] = "sectionBpartner";
        discard[1] = "sectionTotal";
        discard[2] = "sectionTotal2";
        discard[3] = "sectionTotal3";
        discard[4] = "sectionTotal4";
      }
    }
    if (vars.commandIn("DEFAULT")) {
      discard[0] = "sectionBpartner";
      discard[1] = "sectionStatus2";
      discard[2] = "sectionTotal2";
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportDebtPayment", discard).createXmlDocument();
      data = ReportDebtPaymentData.set();
    } else {
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportDebtPayment", discard).createXmlDocument();
    }
    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportDebtPayment", false, "", "", "",
        false, "ad_reports", strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());

    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_reports.ReportDebtPayment");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(), "ReportDebtPayment.html",
          classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "ReportDebtPayment.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportDebtPayment");
      vars.removeMessage("ReportDebtPayment");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }
    String isApprover=ReportDebtPaymentData.isDPapprover(myPool, vars.getUser());
    if (strReceipt.equals("N")) 
      xmlDocument.setParameter("parambuttonmode",isApprover);
    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("cBankAccount", strcbankaccount);
    xmlDocument.setData("reportC_ACCOUNTNUMBER", "liststructure", AccountNumberComboData.select(
        this, vars.getLanguage(), Utility.getContext(this, vars, "#User_Client",
            "ReportDebtPayment"), Utility.getContext(this, vars, "#AccessibleOrgTree",
            "ReportDebtPayment")));
    xmlDocument.setData("reportCBPartnerId_IN", "liststructure", SelectorUtilityData
        .selectBpartner(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility
            .getContext(this, vars, "#User_Client", ""), strC_BPartner_ID));
    // xmlDocument.setParameter("paramBPartnerId", strC_BPartner_ID);
    xmlDocument.setParameter("dateFrom",  UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTo",  UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("amountFrom", strCal1);
    xmlDocument.setParameter("amountTo", strCalc2);
    xmlDocument.setParameter("adOrgId", strAD_Org_ID);
    xmlDocument.setParameter("paymentRule", strPaymentRule);
    xmlDocument.setParameter("settle", strSettle);
    xmlDocument.setParameter("conciliate", strConciliate);
    xmlDocument.setParameter("pending", strPending);
    xmlDocument.setParameter("receipt", strReceipt);
    xmlDocument.setParameter("payable", strReceipt);
    xmlDocument.setParameter("status", strStatus);
    xmlDocument.setParameter("group", strGroup);
    xmlDocument.setParameter("groupBA", strGroupBA);
    xmlDocument.setParameter("salesrepId", strsalesrepId);
    xmlDocument.setParameter("updatedby", strupdatedby);
    
    if (log4j.isDebugEnabled())
      log4j.debug("diacard = " + discard[0] + " - " + discard[1] + " - " + discard[2]);
    // xmlDocument.setParameter("paramBPartnerDescription",
    // ReportDebtPaymentData.bPartnerDescription(this, strC_BPartner_ID));
    if (log4j.isDebugEnabled())
      log4j.debug("ListData.select PaymentRule:" + strPaymentRule);
    try {
      ComboTableDataWrapper comboTableData = new ComboTableDataWrapper(this, vars, "AD_User all Sales Rep",null, "ReportDebtPayment", strsalesrepId,null);
      xmlDocument.setData("reportSalesRep_ID", "liststructure", comboTableData.select(false));
      
      ComboTableDataWrapper comboTableDataappby = new ComboTableDataWrapper(this, vars, "AD_User All Approver",null, "ReportDebtPayment", strupdatedby,null);
      xmlDocument.setData("reportappby", "liststructure", comboTableDataappby.select(false));
      
      ComboTableData comboTableData1 = new ComboTableData(vars, this, "LIST", "",
          "All_Payment Rule", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportDebtPayment"), Utility.getContext(this, vars, "#User_Client",
              "ReportDebtPayment"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData1, "ReportDebtPayment",
          strPaymentRule);
      /*
      ComboTableData comboTableData3 = new ComboTableData(vars, this, "TABLEDIR", "AD_Org_ID", "",
          "AD_Org Security validation", Utility.getContext(this, vars, "#User_Org",
              "GenerateInvoicesmanual"), Utility.getContext(this, vars, "#User_Client",
              "GenerateInvoicesmanual"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData3, "ReportDebtPayment",
          strAD_Org_ID);
          */
      xmlDocument.setData("reportPaymentRule", "liststructure", comboTableData1.select(false));
      
      ComboTableDataWrapper comboTableDataOrg = new ComboTableDataWrapper(this, vars, "ad_org_id","AD_Org Security validation","ReportDebtPayment", strAD_Org_ID,null,null);
      xmlDocument.setData("reportAD_Org_ID", "liststructure", comboTableDataOrg.select(false));
      comboTableData1 = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    if (log4j.isDebugEnabled())
      log4j.debug("ListData.select Status:" + strPaymentRule);
    
    try {
      ComboTableData comboTableData1 = new ComboTableData(vars, this, "LIST", "",
          "C_DP_Management_Status", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportDebtPayment"), Utility.getContext(this, vars, "#User_Client",
              "ReportDebtPayment"), 0);
      
      Utility.fillSQLParameters(this, vars, null, comboTableData1, "ReportDebtPayment", strStatus);
      
      xmlDocument.setData("reportStatus", "liststructure", comboTableData1.select(false));
      
      comboTableData1 = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    
    if (!strGroup.equals("") && !strGroupBA.equals("")) {
      xmlDocument.setData("structure4", data);
    } else if (!strGroupBA.equals("")) {
      xmlDocument.setData("structure3", data);
    } else if (!strGroup.equals("")) {
      xmlDocument.setData("structure1", data);
    } else {
      xmlDocument.setData("structure2", data);
    }

    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet ReportDebtPayment. This Servlet was made by Pablo Sarobe";
  } // end of getServletInfo() method
}
