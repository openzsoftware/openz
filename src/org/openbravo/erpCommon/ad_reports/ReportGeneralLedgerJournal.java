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
package org.openbravo.erpCommon.ad_reports;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.AccountingSchemaMiscData;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.TreeData;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.LocalizationUtils;
import org.openz.util.UtilsData;

public class ReportGeneralLedgerJournal extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  /**
   * Keeps a comma-separated list of the accounting entries that has been shown, from the newest one
   * to the oldest one. Used for navigation purposes
   */
  private static final String PREVIOUS_ACCTENTRIES = "ReportGeneralLedgerJournal.previousAcctEntries";

  /**
   * Keeps a comma-separated list of the line's range that has been shown, from the newest one to
   * the oldest one. Used for navigation purposes
   */
  private static final String PREVIOUS_RANGE = "ReportGeneralLedgerJournal.previousRange";

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (log4j.isDebugEnabled())
      log4j.debug("Command: " + vars.getStringParameter("Command"));

    if (vars.commandIn("DEFAULT")) {
      String strcAcctSchemaId = vars.getGlobalVariable("inpcAcctSchemaId",
          "ReportGeneralLedger|cAcctSchemaId", "");
      String strDateFrom = vars.getDateParameter("inpDateFrom", this);
      if (strDateFrom.isEmpty())
    	  strDateFrom = vars.getSessionValue("ReportGeneralLedgerJournal|DateFrom");
      else
    	  vars.setSessionValue("ReportGeneralLedgerJournal|DateFrom", strDateFrom);
      String strDateTo = vars.getDateParameter("inpDateTo",this);
      if (strDateTo.isEmpty())
    	  strDateTo = vars.getSessionValue("ReportGeneralLedgerJournal|DateTo");
      else
    	  vars.setSessionValue("ReportGeneralLedgerJournal|DateTo", strDateTo);
      String strDocument = vars.getGlobalVariable("inpDocument",
          "ReportGeneralLedgerJournal|Document", "");
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportGeneralLedgerJournal|Org", vars.getOrg());
      String strShowClosing = vars.getGlobalVariable("inpShowClosing",
          "ReportGeneralLedgerJournal|ShowClosing", "");
      // SZ Hide Matched Payments
      String strHideMatched = vars.getGlobalVariable("inpHideMatched",
          "ReportGeneralLedgerJournal|HideMatched", "");
      String strAccountFilter = vars.getGlobalVariable("inpAccountMatch","ReportGeneralLedgerJournal|AccountMatch","");
      String strShowReg = vars.getGlobalVariable("inpShowReg",
          "ReportGeneralLedgerJournal|ShowReg", "");
      String strShowOpening = vars.getGlobalVariable("inpShowOpening",
          "ReportGeneralLedgerJournal|ShowOpening", "");
      String strRecord = vars.getGlobalVariable("inpRecord", "ReportGeneralLedgerJournal|Record",
          "");
      String strTable = vars.getGlobalVariable("inpTable", "ReportGeneralLedgerJournal|Table", "");
      log4j.debug("********DEFAULT***************  strShowClosing: " + strShowClosing);
      log4j.debug("********DEFAULT***************  strShowReg: " + strShowReg);
      log4j.debug("********DEFAULT***************  strShowOpening: " + strShowOpening);
      if (vars.getSessionValue("ReportGeneralLedgerJournal.initRecordNumber", "0").equals("0")) {
        vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", "0");
        vars.setSessionValue(PREVIOUS_ACCTENTRIES, "0");
        vars.setSessionValue(PREVIOUS_RANGE, "");
      }
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strDocument, strOrg, strTable,
          strRecord, "", strcAcctSchemaId, strShowClosing, strHideMatched, strShowReg,
          strShowOpening,strAccountFilter);
    } else if (vars.commandIn("DIRECT")) {
      String strTable = vars.getGlobalVariable("inpTable", "ReportGeneralLedgerJournal|Table");
      String strRecord = vars.getGlobalVariable("inpRecord", "ReportGeneralLedgerJournal|Record");
      setHistoryCommand(request, "DIRECT");
      vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", "0");
      printPageDataSheet(response, vars, "", "", "", "", strTable, strRecord, "", "", "", "", "",
          "","");
    } else if (vars.commandIn("DIRECT2")) {
      String strFactAcctGroupId = vars.getGlobalVariable("inpFactAcctGroupId",
          "ReportGeneralLedgerJournal|FactAcctGroupId");
      setHistoryCommand(request, "DIRECT2");
      vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", "0");
      printPageDataSheet(response, vars, "", "", "", "", "", "", strFactAcctGroupId, "", "", "",
          "", "","");
    } else if (vars.commandIn("FIND")) {
      String strcAcctSchemaId = vars.getRequestGlobalVariable("inpcAcctSchemaId",
          "ReportGeneralLedger|cAcctSchemaId");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportGeneralLedgerJournal|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo",
          "ReportGeneralLedgerJournal|DateTo",this);
      String strDocument = vars.getRequestGlobalVariable("inpDocument",
          "ReportGeneralLedgerJournal|Document");
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportGeneralLedgerJournal|Org", "0");
      String strShowClosing = vars.getRequestGlobalVariable("inpShowClosing",
          "ReportGeneralLedgerJournal|ShowClosing");
      String strShowReg = vars.getRequestGlobalVariable("inpShowReg",
          "ReportGeneralLedgerJournal|ShowReg");
      String strShowOpening = vars.getRequestGlobalVariable("inpShowOpening",
          "ReportGeneralLedgerJournal|ShowOpening");
      // SZ Hide Matched Payments
      String strHideMatched = vars.getStringParameter("inpHideMatched");
      if (strHideMatched.equals("")) {
        vars.removeSessionValue("ReportGeneralLedgerJournal|HideMatched");
      } else
        strHideMatched = vars.getGlobalVariable("inpHideMatched",
            "ReportGeneralLedgerJournal|HideMatched");
      String strAccountFilter = vars.getStringParameter("inpAccountMatch");
      if (strAccountFilter.equals("")) {
        vars.removeSessionValue("ReportGeneralLedgerJournal|AccountMatch");
      } else
        strAccountFilter = vars.getGlobalVariable("inpAccountMatch",
            "ReportGeneralLedgerJournal|AccountMatch");

      String strShowClosing1 = vars.getStringParameter("inpShowClosing");
      String strShowReg1 = vars.getStringParameter("inpShowReg");
      String strShowOpening1 = vars.getStringParameter("inpShowOpening");
      log4j.debug("********FIND***************  strShowClosing: " + strShowClosing);
      log4j.debug("********FIND***************  strShowReg: " + strShowReg);
      log4j.debug("********FIND***************  strShowOpening: " + strShowOpening);
      log4j.debug("********FIND***************  strShowClosing1: " + strShowClosing1);
      log4j.debug("********FIND***************  strShowReg1: " + strShowReg1);
      log4j.debug("********FIND***************  strShowOpening1: " + strShowOpening1);
      vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", "0");
      vars.setSessionValue(PREVIOUS_ACCTENTRIES, "0");
      vars.setSessionValue(PREVIOUS_RANGE, "");
      setHistoryCommand(request, "DEFAULT");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strDocument, strOrg, "", "", "",
          strcAcctSchemaId, strShowClosing, strHideMatched, strShowReg, strShowOpening,strAccountFilter);
    } else if (vars.commandIn("PDF", "XLS")) {
      if (log4j.isDebugEnabled())
        log4j.debug("PDF");
      String strcAcctSchemaId = vars.getRequestGlobalVariable("inpcAcctSchemaId",
          "ReportGeneralLedger|cAcctSchemaId");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportGeneralLedgerJournal|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo",
          "ReportGeneralLedgerJournal|DateTo",this);
      String strDocument = vars.getRequestGlobalVariable("inpDocument",
          "ReportGeneralLedgerJournal|Document");
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportGeneralLedgerJournal|Org", "0");
      String strShowClosing = vars.getRequestGlobalVariable("inpShowClosing",
          "ReportGeneralLedgerJournal|ShowClosing");
      String strShowReg = vars.getRequestGlobalVariable("inpShowReg",
          "ReportGeneralLedgerJournal|ShowReg");
      String strShowOpening = vars.getRequestGlobalVariable("inpShowOpening",
          "ReportGeneralLedgerJournal|ShowOpening");
      // SZ Hide Matched Payments
      String strHideMatched = vars.getStringParameter("inpHideMatched");
      String strAccountFilter = vars.getStringParameter("inpAccountMatch");

      // String strRecord = vars.getGlobalVariable("inpRecord",
      // "ReportGeneralLedgerJournal|Record");
      // String strTable = vars.getGlobalVariable("inpTable",
      // "ReportGeneralLedgerJournal|Table");
      String strTable = vars.getStringParameter("inpTable");
      String strRecord = vars.getStringParameter("inpRecord");
      // vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", "0");
      setHistoryCommand(request, "DEFAULT");
      printPagePDF(response, vars, strDateFrom, strDateTo, strDocument, strOrg, strTable,
          strRecord, "", strcAcctSchemaId, strShowClosing, strShowReg, strShowOpening,
          strHideMatched,strAccountFilter);
    } else if (vars.commandIn("PREVIOUS_RELATION")) {
      String strInitRecord = vars.getSessionValue("ReportGeneralLedgerJournal.initRecordNumber");
      String strPreviousRecordRange = vars.getSessionValue(PREVIOUS_RANGE);

      String[] previousRecord = strPreviousRecordRange.split(",");
      strPreviousRecordRange = previousRecord[0];
      int intRecordRange = strPreviousRecordRange.equals("") ? 0 : Integer
          .parseInt(strPreviousRecordRange);
      strPreviousRecordRange = previousRecord[1];
      intRecordRange += strPreviousRecordRange.equals("") ? 0 : Integer
          .parseInt(strPreviousRecordRange);

      // Remove parts of the previous range
      StringBuffer sb_previousRange = new StringBuffer();
      for (int i = 2; i < previousRecord.length; i++) {
        sb_previousRange.append(previousRecord[i] + ",");
      }
      vars.setSessionValue(PREVIOUS_RANGE, sb_previousRange.toString());

      // Remove parts of the previous accounting entries
      String[] previousAcctEntries = vars.getSessionValue(PREVIOUS_ACCTENTRIES).split(",");
      StringBuffer sb_previousAcctEntries = new StringBuffer();
      for (int i = 2; i < previousAcctEntries.length; i++) {
        sb_previousAcctEntries.append(previousAcctEntries[i] + ",");
      }

      if (strInitRecord.equals("") || strInitRecord.equals("0"))
        vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", "0");
      else {
        int initRecord = (strInitRecord.equals("") ? 0 : Integer.parseInt(strInitRecord));
        initRecord -= intRecordRange;
        strInitRecord = ((initRecord < 0) ? "0" : Integer.toString(initRecord));
        vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", strInitRecord);
        vars.setSessionValue(PREVIOUS_ACCTENTRIES, sb_previousAcctEntries.toString());
      }

      response.sendRedirect(strDireccion + request.getServletPath());
    } else if (vars.commandIn("NEXT_RELATION")) {
      response.sendRedirect(strDireccion + request.getServletPath());
    } else
      pageError(response);
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strDocument, String strOrg, String strTable,
      String strRecord, String strFactAcctGroupId, String strcAcctSchemaId, String strShowClosing,
      String strHideMatched, String strShowReg, String strShowOpening, String strAccountFilter) throws IOException,
      ServletException {
    String strRecordRange = Utility.getContext(this, vars, "#RecordRange",
        "ReportGeneralLedgerJournal");
    int intRecordRangePredefined = (strRecordRange.equals("") ? 0 : Integer
        .parseInt(strRecordRange));
    String strInitRecord = vars.getSessionValue("ReportGeneralLedgerJournal.initRecordNumber");
    int initRecordNumber = (strInitRecord.equals("") ? 0 : Integer.parseInt(strInitRecord));
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = null;
    ReportGeneralLedgerJournalData[] data = null;
    ReportGeneralLedgerJournalData[] dataCountLines = null;
    String strPosition = "0";
    String strTreeOrg = TreeData.getTreeOrg(this, vars.getClient());
    String strOrgFamily = getFamily(strTreeOrg, strOrg);
    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportGeneralLedgerJournal", false,
        "", "", "imprimir();return false;", false, "ad_reports", strReplaceWith, false, true);
    toolbar.setEmail(false);
    int totalAcctEntries = 0;
    int lastRecordNumber = 0;
    if (vars.commandIn("FIND") || vars.commandIn("DEFAULT")
        && !vars.getSessionValue("ReportGeneralLedgerJournal.initRecordNumber").equals("0")) {
      String strCheck = buildCheck(strShowClosing, strShowReg, strShowOpening);
      if (strRecord.equals("")) {
        // Stores the number of lines per accounting entry
        dataCountLines = ReportGeneralLedgerJournalData.selectCountGroupedLines(this,vars.getLanguage(), Utility
            .getContext(this, vars, "#User_Client", "ReportGeneralLedger"), Utility.getContext(
            this, vars, "#AccessibleOrgTree", "ReportGeneralLedger"), strDateFrom, DateTimeData
            .nDaysAfter(this, strDateTo, "1"), strDocument, strcAcctSchemaId, strAccountFilter,strOrgFamily,
            strCheck, strHideMatched);
        String strInitAcctEntries = vars.getSessionValue(PREVIOUS_ACCTENTRIES);
        int acctEntries = (strInitAcctEntries.equals("") ? 0 : Integer.parseInt(strInitAcctEntries
            .split(",")[0]));

        for (ReportGeneralLedgerJournalData i : dataCountLines)
          totalAcctEntries += Integer.parseInt(i.groupedlines);

        int groupedLines[] = new int[intRecordRangePredefined+1];
        int i = 1;
        while (groupedLines[i - 1] <= intRecordRangePredefined
            && dataCountLines.length >= acctEntries) {
          if (dataCountLines.length > acctEntries) {
            try {
              groupedLines[i] = groupedLines[i - 1]
                + Integer.parseInt(dataCountLines[acctEntries].groupedlines);
              i++;
            } catch (Exception ignore) {  }
          }
          acctEntries++;
        }

        int intRecordRangeUsed;
        if (dataCountLines.length != acctEntries - 1) {
          if (i == 2) {
            // The first entry is bigger than the predefined range
            intRecordRangeUsed = groupedLines[i - 1];
            acctEntries++;
          } else {
            intRecordRangeUsed = groupedLines[i - 2];
          }
        } else {
          // Include also the last entry
          intRecordRangeUsed = groupedLines[i - 1];
        }

        // Hack for sqlC first record
        if (initRecordNumber == 0) {
          lastRecordNumber = initRecordNumber + intRecordRangeUsed + 1;
        } else {
          lastRecordNumber = initRecordNumber + intRecordRangeUsed;
        }
        vars.setSessionValue("ReportGeneralLedgerJournal.initRecordNumber", String
            .valueOf(lastRecordNumber));

        // Stores historical for navigation purposes
        vars.setSessionValue(PREVIOUS_ACCTENTRIES, String.valueOf(acctEntries - 1) + ","
            + vars.getSessionValue(PREVIOUS_ACCTENTRIES));
        vars.setSessionValue(PREVIOUS_RANGE, String.valueOf(intRecordRangeUsed) + ","
            + vars.getSessionValue(PREVIOUS_RANGE));

        data = ReportGeneralLedgerJournalData.select(this, vars.getLanguage(),Utility.getContext(this, vars,
            "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
            "#AccessibleOrgTree", "ReportGeneralLedger"), strDateFrom, DateTimeData.nDaysAfter(
            this, strDateTo, "1"), strDocument, strcAcctSchemaId,strAccountFilter, strOrgFamily, strCheck,
            strHideMatched, initRecordNumber, intRecordRangeUsed);
        if (data != null && data.length > 0)
          strPosition = ReportGeneralLedgerJournalData.selectCount(this, Utility.getContext(this,
              vars, "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
              "#AccessibleOrgTree", "ReportGeneralLedger"), strDateFrom, DateTimeData.nDaysAfter(
              this, strDateTo, "1"), strDocument, strcAcctSchemaId, strAccountFilter,strOrgFamily, strCheck,
              strHideMatched, data[0].dateacct, data[0].identifier);
      } else {
        data = ReportGeneralLedgerJournalData.selectDirect(this, vars.getLanguage(),Utility.getContext(this, vars,
            "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
            "#AccessibleOrgTree", "ReportGeneralLedger"), strTable, strRecord, initRecordNumber,
            intRecordRangePredefined);
        if (data != null && data.length > 0)
          strPosition = ReportGeneralLedgerJournalData.selectCountDirect(this, Utility.getContext(
              this, vars, "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
              "#AccessibleOrgTree", "ReportGeneralLedger"), strTable, strRecord, data[0].dateacct,
              data[0].identifier);
      }
    } else if (vars.commandIn("DIRECT")) {
      data = ReportGeneralLedgerJournalData.selectDirect(this, vars.getLanguage(),Utility.getContext(this, vars,
          "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
          "#AccessibleOrgTree", "ReportGeneralLedger"), strTable, strRecord, initRecordNumber,
          intRecordRangePredefined);
      if (data != null && data.length > 0)
        strPosition = ReportGeneralLedgerJournalData.selectCountDirect(this, Utility.getContext(
            this, vars, "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
            "#AccessibleOrgTree", "ReportGeneralLedger"), strTable, strRecord, data[0].dateacct,
            data[0].identifier);
    } else if (vars.commandIn("DIRECT2")) {
      data = ReportGeneralLedgerJournalData.selectDirect2(this, vars.getLanguage(),Utility.getContext(this, vars,
          "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
          "#AccessibleOrgTree", "ReportGeneralLedger"), strFactAcctGroupId, initRecordNumber,
          intRecordRangePredefined);
      if (data != null && data.length > 0)
        strPosition = ReportGeneralLedgerJournalData.selectCountDirect2(this, Utility.getContext(
            this, vars, "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
            "#AccessibleOrgTree", "ReportGeneralLedger"), strFactAcctGroupId, data[0].dateacct,
            data[0].identifier);
    }
    if (data == null || data.length == 0) {
      String discard[] = { "sectionSchema" };
      toolbar
          .prepareRelationBarTemplate(false, false,
              "submitCommandForm('XLS', false, null, 'ReportGeneralLedgerJournal.xls', 'EXCEL');return false;");
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportGeneralLedgerJournal", discard)
          .createXmlDocument();
      data = ReportGeneralLedgerJournalData.set("0");
      data[0].rownum = "0";
    } else {
      boolean hasPrevious = !(data == null || data.length == 0 || initRecordNumber <= 1);
      boolean hasNext = !(data == null || data.length == 0 || lastRecordNumber >= totalAcctEntries);
      toolbar
          .prepareRelationBarTemplate(true, true,
              "submitCommandForm('XLS', false, null, 'ReportGeneralLedgerJournal.xls', 'EXCEL');return false;");
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportGeneralLedgerJournal").createXmlDocument();

      String jsDisablePreviousNext = "function checkPreviousNextButtons(){";
      if (!hasPrevious)
        jsDisablePreviousNext += "disableToolBarButton('linkButtonPrevious');";
      if (!hasNext)
        jsDisablePreviousNext += "disableToolBarButton('linkButtonNext');";
      jsDisablePreviousNext += "}";
      xmlDocument.setParameter("jsDisablePreviousNext", jsDisablePreviousNext);
    }
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "LIST", "",
          "C_DocType DocBaseType", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportGeneralLedgerJournal"), Utility.getContext(this, vars, "#User_Client",
              "ReportGeneralLedgerJournal"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "ReportGeneralLedgerJournal",
          strDocument);
      xmlDocument.setData("reportDocument", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    xmlDocument.setParameter("toolbar", toolbar.toString());
    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_reports.ReportGeneralLedgerJournal");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(),
          "ReportGeneralLedgerJournal.html", classInfo.id, classInfo.type, strReplaceWith, tabs
              .breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(),
          "ReportGeneralLedgerJournal.html", strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportGeneralLedgerJournal");
      vars.removeMessage("ReportGeneralLedgerJournal");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("document", strDocument);
    xmlDocument.setParameter("cAcctschemaId", strcAcctSchemaId);

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_ORG_ID", "",
          "", Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportGeneralLedgerJournal"),
          Utility.getContext(this, vars, "#User_Client", "ReportGeneralLedgerJournal"), '*');
      comboTableData.fillParameters(null, "ReportGeneralLedgerJournal", "");
      xmlDocument.setData("reportAD_ORGID", "liststructure", comboTableData.select(false));
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    // SZ: Calculate the real Position in the whole Jounal
    // GOBS-Conform Requirement
    String strGeneralOffset=ReportGeneralLedgerJournalData.selectStartFactNo(this, strOrgFamily, strDateFrom);
    int calcPosition=Integer.valueOf(strPosition)+Integer.valueOf(strGeneralOffset);
    strPosition=Integer.toString(calcPosition);
    xmlDocument.setData("reportC_ACCTSCHEMA_ID", "liststructure", AccountingSchemaMiscData
        .selectC_ACCTSCHEMA_ID(this, Utility.getContext(this, vars, "#AccessibleOrgTree",
            "ReportGeneralLedger"), Utility.getContext(this, vars, "#User_Client",
            "ReportGeneralLedger"), strcAcctSchemaId));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("dateFrom",  UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTo",  UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("AccountMatch", strAccountFilter);
    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("adOrgId", strOrg);
    xmlDocument.setParameter("groupId", strPosition);
    xmlDocument.setParameter("paramRecord", strRecord);
    xmlDocument.setParameter("paramTable", strTable);
    vars.setSessionValue("ReportGeneralLedgerJournal|Record", strRecord);
    vars.setSessionValue("ReportGeneralLedgerJournal|Table", strTable);
    xmlDocument.setParameter("showClosing", strShowClosing.equals("") ? "0" : "1");
    xmlDocument.setParameter("showReg", strShowReg.equals("") ? "0" : "1");
    xmlDocument.setParameter("showOpening", strShowOpening.equals("") ? "0" : "1");
    xmlDocument.setData("structure1", data);
    xmlDocument.setParameter("paramHide0", !strHideMatched.equals("Y") ? "0" : "1");
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPagePDF(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strDocument, String strOrg, String strTable,
      String strRecord, String strFactAcctGroupId, String strcAcctSchemaId, String strShowClosing,
      String strShowReg, String strShowOpening, String strHideMatched, String strAccountFilter) throws IOException,
      ServletException {

    ReportGeneralLedgerJournalData[] data = null;

    String strTreeOrg = TreeData.getTreeOrg(this, vars.getClient());
    String strOrgFamily = getFamily(strTreeOrg, strOrg);
     // SZ: Calculate the real Position in the whole Jounal
    // GOBS-Conform Requirement
    String strGeneralOffset=ReportGeneralLedgerJournalData.selectStartFactNo(this, strOrgFamily, strDateFrom);
    
    if (strRecord.equals("")) {
      String strCheck = buildCheck(strShowClosing, strShowReg, strShowOpening);
      data = ReportGeneralLedgerJournalData.select(this, vars.getLanguage(),Utility.getContext(this, vars,
          "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
          "#AccessibleOrgTree", "ReportGeneralLedger"), strDateFrom, DateTimeData.nDaysAfter(this,
          strDateTo, "1"), strDocument, strcAcctSchemaId, strAccountFilter,strOrgFamily, strCheck, strHideMatched);
    } else
      data = ReportGeneralLedgerJournalData.selectDirect(this, vars.getLanguage(),Utility.getContext(this, vars,
          "#User_Client", "ReportGeneralLedger"), Utility.getContext(this, vars,
          "#AccessibleOrgTree", "ReportGeneralLedger"), strTable, strRecord);

    String strSubtitle;
    try {
      strSubtitle = LocalizationUtils.getElementTextByElementName(this,"ad_org_id", vars.getLanguage()) + ": "
          + ReportGeneralLedgerJournalData.selectCompany(this, strOrg);
    } catch (Exception e) {
      strSubtitle ="";
    }

      if (strDateFrom.equals("") && strDateTo.equals(""))
        strSubtitle += " - " + Utility.messageBD(this, "Period", vars.getLanguage()) + ": "
            + strDateFrom + " - " + strDateTo;
  
      String strOutput = vars.commandIn("PDF") ? "pdf" : "xls";
      String strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportGeneralLedgerJournal.jrxml";
  
      HashMap<String, Object> parameters = new HashMap<String, Object>();
      parameters.put("Subtitle", strSubtitle);
      parameters.put("InitPosition",strGeneralOffset);
      
      renderJR(vars, response, strReportName, strOutput, parameters, data, null);
   
  }

  private String getFamily(String strTree, String strChild) throws IOException, ServletException {
    return Tree.getMembers(this, strTree, (strChild == null || strChild.equals("")) ? "0"
        : strChild);
    /*
     * ReportGeneralLedgerData [] data = ReportGeneralLedgerData.selectChildren(this, strTree,
     * strChild); String strFamily = ""; if(data!=null && data.length>0) { for (int i =
     * 0;i<data.length;i++){ if (i>0) strFamily = strFamily + ","; strFamily = strFamily +
     * data[i].id; } return strFamily += ""; }else return "'1'";
     */
  }

  private String buildCheck(String strShowClosing, String strShowReg, String strShowOpening) {
    if (strShowClosing.equals("") && strShowReg.equals("") && strShowOpening.equals(""))
      return "'C','N','O','R'";
    String[] strElements = { strShowClosing.equals("") ? "" : "'C'",
        strShowReg.equals("") ? "" : "'R'", strShowOpening.equals("") ? "" : "'O'" };
    int no = 0;
    String strCheck = "";
    for (int i = 0; i < strElements.length; i++) {
      if (!strElements[i].equals("")) {
        if (no != 0)
          strCheck = strCheck + ", ";
        strCheck = strCheck + strElements[i];
        no++;
      }
    }
    return strCheck;
  }

  public String getServletInfo() {
    return "Servlet ReportGeneralLedgerJournal. This Servlet was made by Pablo Sarobe modified by everybody";
  } // end of getServletInfo() method
}
