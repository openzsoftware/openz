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
package org.openbravo.erpCommon.ad_reports;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.*;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.AccountingSchemaMiscData;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.TreeData;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.info.SelectorUtilityData;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.UtilsData;

public class ReportGeneralLedger extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportGeneralLedger|Org", vars.getOrg());
      String strcAcctSchemaId = vars.getGlobalVariable("inpcAcctSchemaId",
          "ReportGeneralLedger|cAcctSchemaId", "");
      if (strcAcctSchemaId.isEmpty()) 
        strcAcctSchemaId =ReportGeneralLedgerData.getAcctSchemaOfOrg(this, strOrg);
      if (strcAcctSchemaId == null || strcAcctSchemaId.isEmpty()) 
        strcAcctSchemaId =ReportGeneralLedgerData.getAcctSchemaDefault(this);
      String strDateFrom = vars.getDateParameter("inpDateFrom", this);
      if (strDateFrom.isEmpty())
    	  strDateFrom = vars.getSessionValue("ReportGeneralLedger|DateFrom");
      else
    	  vars.setSessionValue("ReportGeneralLedger|DateFrom", strDateFrom);
      String strDateTo = vars.getDateParameter("inpDateTo",this);
      if (strDateTo.isEmpty())
    	  strDateTo = vars.getSessionValue("ReportGeneralLedger|DateTo");
      else
    	  vars.setSessionValue("ReportGeneralLedger|DateTo", strDateTo);
      String strAmtFrom = vars.getNumericGlobalVariable("inpAmtFrom",
          "ReportGeneralLedger|AmtFrom", "");
      String strAmtTo = vars.getNumericGlobalVariable("inpAmtTo", "ReportGeneralLedger|AmtTo", "");
      String strcelementvaluefrom = vars.getGlobalVariable("inpcElementValueIdFrom",
          "ReportGeneralLedger|C_ElementValue_IDFROM", "");
      String strcelementvalueto = vars.getGlobalVariable("inpcElementValueIdTo",
          "ReportGeneralLedger|C_ElementValue_IDTO", "");
      String strcelementvaluefromdes = "", strcelementvaluetodes = "";
      if (!strcelementvaluefrom.equals(""))
        strcelementvaluefromdes = ReportGeneralLedgerData.selectSubaccountDescription(this,
            strcelementvaluefrom);
      if (!strcelementvalueto.equals(""))
        strcelementvaluetodes = ReportGeneralLedgerData.selectSubaccountDescription(this,
            strcelementvalueto);
      strcelementvaluefromdes = (strcelementvaluefromdes.equals("null")) ? ""
          : strcelementvaluefromdes;
      strcelementvaluetodes = (strcelementvaluetodes.equals("null")) ? "" : strcelementvaluetodes;
      vars.setSessionValue("inpElementValueIdFrom_DES", strcelementvaluefromdes);
      vars.setSessionValue("inpElementValueIdTo_DES", strcelementvaluetodes);
      
      String strcBpartnerId = vars.getInGlobalVariable("inpcBPartnerId_IN",
          "ReportGeneralLedger|cBpartnerId", "", IsIDFilter.instance);
      String strmProductId = vars.getInGlobalVariable("inpmProductId_IN",
          "ReportGeneralLedger|mProductId", "", IsIDFilter.instance);
      String strcProjectId = vars.getInGlobalVariable("inpcProjectId_IN",
          "ReportGeneralLedger|cProjectId", "", IsIDFilter.instance);
      String strGroupBy = vars.getGlobalVariable("inpGroupBy", "ReportGeneralLedger|GroupBy", "");
      String strHide = vars.getGlobalVariable("inpHideMatched", "ReportGeneralLedger|HideMatched",
          "");
      String strAccountMatch = vars.getGlobalVariable("inpAccountMatch", "ReportGeneralLedger|AccountMatch", "");
      String displayBalance = vars.getGlobalVariable("inpDisplaybalance", "ReportGeneralLedger|displayBalance","N");
      String suminvlines = vars.getGlobalVariable("inpSuminvlines", "ReportGeneralLedger|Suminvlines","N");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strAmtFrom, strAmtTo,
          strcelementvaluefrom, strcelementvalueto, strOrg, strcBpartnerId, strmProductId,
          strcProjectId, strGroupBy, strHide, strcAcctSchemaId, strcelementvaluefromdes,
          strcelementvaluetodes,strAccountMatch,displayBalance,suminvlines);
    } else if (vars.commandIn("FIND")) {
      String strAccountMatch = vars.getGlobalVariable("inpAccountMatch", "ReportGeneralLedger|AccountMatch", "");
      String strcAcctSchemaId = vars.getRequestGlobalVariable("inpcAcctSchemaId",
          "ReportGeneralLedger|cAcctSchemaId");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportGeneralLedger|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportGeneralLedger|DateTo",this);
      String strAmtFrom = vars.getNumericRequestGlobalVariable("inpAmtFrom",
          "ReportGeneralLedger|AmtFrom");
      String strAmtTo = vars.getNumericRequestGlobalVariable("inpAmtTo",
          "ReportGeneralLedger|AmtTo");
      String strcelementvaluefrom = vars.getRequestGlobalVariable("inpcElementValueIdFrom",
          "ReportGeneralLedger|C_ElementValue_IDFROM");
      String strcelementvalueto = vars.getRequestGlobalVariable("inpcElementValueIdTo",
          "ReportGeneralLedger|C_ElementValue_IDTO");
      String strcelementvaluefromdes = "", strcelementvaluetodes = "";
      if (!strcelementvaluefrom.equals(""))
        strcelementvaluefromdes = ReportGeneralLedgerData.selectSubaccountDescription(this,
            strcelementvaluefrom);
      if (!strcelementvalueto.equals(""))
        strcelementvaluetodes = ReportGeneralLedgerData.selectSubaccountDescription(this,
            strcelementvalueto);
      vars.setSessionValue("inpElementValueIdFrom_DES", strcelementvaluefromdes);
      vars.setSessionValue("inpElementValueIdTo_DES", strcelementvaluetodes);
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportGeneralLedger|Org", "0");
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportGeneralLedger|cBpartnerId", IsIDFilter.instance);
      String strmProductId = vars.getInGlobalVariable("inpmProductId_IN",
          "ReportGeneralLedger|mProductId", "", IsIDFilter.instance);
      String strcProjectId = vars.getInGlobalVariable("inpcProjectId_IN",
          "ReportGeneralLedger|cProjectId", "", IsIDFilter.instance);
      String strGroupBy = vars
          .getRequestGlobalVariable("inpGroupBy", "ReportGeneralLedger|GroupBy");
      String strHide = vars.getStringParameter("inpHideMatched");
      if (strHide.equals(""))
        vars.removeSessionValue("ReportGeneralLedger|HideMatched");
      else
        strHide = vars.getGlobalVariable("inpHideMatched", "ReportGeneralLedger|HideMatched");
      if (log4j.isDebugEnabled())
        log4j.debug("##################### DoPost - Find - strcBpartnerId= " + strcBpartnerId);
      if (log4j.isDebugEnabled())
        log4j.debug("##################### DoPost - XLS - strcelementvaluefrom= "
            + strcelementvaluefrom);
      if (log4j.isDebugEnabled())
        log4j.debug("##################### DoPost - XLS - strcelementvalueto= "
            + strcelementvalueto);
      vars.setSessionValue("ReportGeneralLedger.initRecordNumber", "0");
      
      String displayBalance=vars.getStringParameter("inpDisplaybalance");
      if (displayBalance.isEmpty())
    	  displayBalance="N";
      vars.setSessionValue("ReportGeneralLedger|displayBalance",displayBalance);
      String suminvlines = vars.getStringParameter("inpSuminvlines");
      if (suminvlines.isEmpty())
    	  suminvlines="N";
      vars.setSessionValue("ReportGeneralLedger|Suminvlines",suminvlines);
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strAmtFrom, strAmtTo,
          strcelementvaluefrom, strcelementvalueto, strOrg, strcBpartnerId, strmProductId,
          strcProjectId, strGroupBy, strHide, strcAcctSchemaId, strcelementvaluefromdes,
          strcelementvaluetodes,strAccountMatch,displayBalance,suminvlines);
    } else if (vars.commandIn("PREVIOUS_RELATION")) {
      String strInitRecord = vars.getSessionValue("ReportGeneralLedger.initRecordNumber");
      String strRecordRange = Utility.getContext(this, vars, "#RecordRange", "ReportGeneralLedger");
      int intRecordRange = strRecordRange.equals("") ? 0 : Integer.parseInt(strRecordRange);
      if (strInitRecord.equals("") || strInitRecord.equals("0"))
        vars.setSessionValue("ReportGeneralLedger.initRecordNumber", "0");
      else {
        int initRecord = (strInitRecord.equals("") ? 0 : Integer.parseInt(strInitRecord));
        initRecord -= intRecordRange;
        strInitRecord = ((initRecord < 0) ? "0" : Integer.toString(initRecord));
        vars.setSessionValue("ReportGeneralLedger.initRecordNumber", strInitRecord);
      }
      response.sendRedirect(strDireccion + request.getServletPath());
    } else if (vars.commandIn("NEXT_RELATION")) {
      String strInitRecord = vars.getSessionValue("ReportGeneralLedger.initRecordNumber");
      String strRecordRange = Utility.getContext(this, vars, "#RecordRange", "ReportGeneralLedger");
      int intRecordRange = strRecordRange.equals("") ? 0 : Integer.parseInt(strRecordRange);
      int initRecord = (strInitRecord.equals("") ? 0 : Integer.parseInt(strInitRecord));
      // if (initRecord == 0)
      // initRecord = 1; Removed by DAL 30/4/09
      initRecord += intRecordRange;
      strInitRecord = ((initRecord < 0) ? "0" : Integer.toString(initRecord));
      vars.setSessionValue("ReportGeneralLedger.initRecordNumber", strInitRecord);
      response.sendRedirect(strDireccion + request.getServletPath());
    } else if (vars.commandIn("PDF", "XLS")) {
      String strcAcctSchemaId = vars.getRequestGlobalVariable("inpcAcctSchemaId",
          "ReportGeneralLedger|cAcctSchemaId");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportGeneralLedger|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportGeneralLedger|DateTo",this);
      String strAmtFrom = vars.getNumericRequestGlobalVariable("inpAmtFrom",
          "ReportGeneralLedger|AmteFrom");
      String strAmtTo = vars.getNumericRequestGlobalVariable("inpAmtTo",
          "ReportGeneralLedger|AmtTo");
      String strcelementvaluefrom = vars.getRequestGlobalVariable("inpcElementValueIdFrom",
          "ReportGeneralLedger|C_ElementValue_IDFROM");
      String strcelementvalueto = vars.getRequestGlobalVariable("inpcElementValueIdTo",
          "ReportGeneralLedger|C_ElementValue_IDTO");
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportGeneralLedger|Org", "0");
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportGeneralLedger|cBpartnerId", IsIDFilter.instance);
      String strmProductId = vars.getInGlobalVariable("inpmProductId_IN",
          "ReportGeneralLedger|mProductId", "", IsIDFilter.instance);
      String strcProjectId = vars.getInGlobalVariable("inpcProjectId_IN",
          "ReportGeneralLedger|cProjectId", "", IsIDFilter.instance);
      String strGroupBy = vars
          .getRequestGlobalVariable("inpGroupBy", "ReportGeneralLedger|GroupBy");
      String strHide = vars.getStringParameter("inpHideMatched");
      String strAccountMatch = vars.getGlobalVariable("inpAccountMatch", "ReportGeneralLedger|AccountMatch", "");
      String displayBalance=vars.getStringParameter("inpDisplaybalance");
      if (displayBalance.isEmpty())
    	  displayBalance="N";
      vars.setSessionValue("ReportGeneralLedger|displayBalance",displayBalance);
      String suminvlines = vars.getStringParameter("inpSuminvlines");
      if (suminvlines.isEmpty())
    	  suminvlines="N";
      if (vars.commandIn("PDF"))
        printPageDataPDF(request, response, vars, strDateFrom, strDateTo, strAmtFrom, strAmtTo,
            strcelementvaluefrom, strcelementvalueto, strOrg, strcBpartnerId, strmProductId,
            strcProjectId, strGroupBy, strHide, strcAcctSchemaId,strAccountMatch,displayBalance,suminvlines);
      else
        printPageDataXLS(request, response, vars, strDateFrom, strDateTo, strAmtFrom, strAmtTo,
            strcelementvaluefrom, strcelementvalueto, strOrg, strcBpartnerId, strmProductId,
            strcProjectId, strGroupBy, strHide, strcAcctSchemaId,strAccountMatch,suminvlines);
    } else
      pageError(response);
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strAmtFrom, String strAmtTo,
      String strcelementvaluefrom, String strcelementvalueto, String strOrg, String strcBpartnerId,
      String strmProductId, String strcProjectId, String strGroupBy, String strHide,
      String strcAcctSchemaId, String strcelementvaluefromdes, String strcelementvaluetodes, String strAccountMatch,String displayBalance, String suminvlines)
      throws IOException, ServletException {
    String strRecordRange = Utility.getContext(this, vars, "#RecordRange", "ReportGeneralLedger");
    int intRecordRange = (strRecordRange.equals("") ? 0 : Integer.parseInt(strRecordRange));
    String strInitRecord = vars.getSessionValue("ReportGeneralLedger.initRecordNumber");
    int initRecordNumber = (strInitRecord.equals("") ? 0 : Integer.parseInt(strInitRecord));
    // built limit/offset parameters for oracle/postgres
    String rowNum = "0";
    
    String pgLimit = null;
    
        rowNum = "0";
        pgLimit = intRecordRange + " OFFSET " + initRecordNumber;
      
    log4j.debug("offset= " + initRecordNumber + " pageSize= " + intRecordRange);
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    if (log4j.isDebugEnabled())
      log4j.debug("Date From:" + strDateFrom + "- To:" + strDateTo + " - Schema:"
          + strcAcctSchemaId);
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = null;
    ReportGeneralLedgerData[] data = null;
    String strTreeOrg = TreeData.getTreeOrg(this, vars.getClient());
    // String strTreeAccount = ReportTrialBalanceData.treeAccount(this, vars.getClient());
    String strOrgFamily = getFamily(strTreeOrg, strOrg);
 
    String toDatePlusOne = DateTimeData.nDaysAfter(this, strDateTo, "1");

    String strGroupByText = (strGroupBy.equals("BPartner") ? Utility.messageBD(this, "BusPartner",
        vars.getLanguage()) : (strGroupBy.equals("Product") ? Utility.messageBD(this, "Product",
        vars.getLanguage()) : (strGroupBy.equals("Project") ? Utility.messageBD(this, "Project",
        vars.getLanguage()) : "")));

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportGeneralLedger", false, "", "",
        "imprimir();return false;", false, "ad_reports", strReplaceWith, false, true);
    String strcBpartnerIdAux = strcBpartnerId;
    String strmProductIdAux = strmProductId;
    String strcProjectIdAux = strcProjectId;
    if (strDateFrom.equals("") && strDateTo.equals("")) {
      String discard[] = { "sectionAmount", "sectionPartner" };
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportGeneralLedger", discard).createXmlDocument();
      toolbar
          .prepareRelationBarTemplate(false, false,
              "submitCommandForm('XLS', false, frmMain, 'ReportGeneralLedgerExcel.xls', 'EXCEL');return false;");
      data = ReportGeneralLedgerData.set();
    } else {
      String[] discard = { "discard" };
      if (strGroupBy.equals(""))
        discard[0] = "sectionPartner";
      else
        discard[0] = "sectionAmount";
      BigDecimal previousDebit = BigDecimal.ZERO;
      BigDecimal previousCredit = BigDecimal.ZERO;
      BigDecimal totalsubadded = BigDecimal.ZERO;
      if (strHide.equals(""))
        strHide = "N";
      String strAllaccounts = "Y";
      if (strcelementvaluefrom != null && !strcelementvaluefrom.equals("")) {
        if (strcelementvalueto.equals("")) {
          strcelementvalueto = strcelementvaluefrom;
          strcelementvaluetodes = ReportGeneralLedgerData.selectSubaccountDescription(this,
              strcelementvalueto);
          vars.setSessionValue("inpElementValueIdTo_DES", strcelementvaluetodes);

        }
        strAllaccounts = "N";
        if (log4j.isDebugEnabled())
          log4j.debug("##################### strcelementvaluefrom= " + strcelementvaluefrom);
        if (log4j.isDebugEnabled())
          log4j.debug("##################### strcelementvalueto= " + strcelementvalueto);
      } else {
        strcelementvalueto = "";
        strcelementvaluetodes = "";
        vars.setSessionValue("inpElementValueIdTo_DES", strcelementvaluetodes);
      }
      if (strAccountMatch.equals(""))
        strAccountMatch="%";
      if (suminvlines.equals("Y")) suminvlines="FACT_ACCT_GROUP_ID"; else  suminvlines="FACT_ACCT_ID";
      data = ReportGeneralLedgerData.select(this, rowNum, vars.getLanguage(),strGroupByText, suminvlines,strGroupBy, strDateFrom,
          toDatePlusOne, strAllaccounts, strcelementvaluefrom, strcelementvalueto, Utility
              .getContext(this, vars, "#AccessibleOrgTree", "ReportGeneralLedger"), Utility
              .getContext(this, vars, "#User_Client", "ReportGeneralLedger"), strHide,
          strcAcctSchemaId, strDateFrom, toDatePlusOne, strAccountMatch,strOrgFamily, strcBpartnerId,
          strmProductId, strcProjectId, strAmtFrom, strAmtTo, null, null, null, pgLimit, "","");
      if (log4j.isDebugEnabled())
        log4j.debug("RecordNo: " + initRecordNumber);
      // In case this is not the first screen to show, initial balance may need to include amounts
      // of previous screen, so same sql -but from the beginning of the fiscal year- is executed

      ReportGeneralLedgerData[] dataTotal = null;
      if (data != null && data.length > 1 && initRecordNumber>0) {
    	pgLimit = Integer.toString(initRecordNumber);
        dataTotal = ReportGeneralLedgerData.select(this, rowNum, vars.getLanguage(),strGroupByText,suminvlines, strGroupBy, strDateFrom,
                toDatePlusOne, strAllaccounts, strcelementvaluefrom, strcelementvalueto, Utility
                .getContext(this, vars, "#AccessibleOrgTree", "ReportGeneralLedger"), Utility
                .getContext(this, vars, "#User_Client", "ReportGeneralLedger"), strHide,
            strcAcctSchemaId, strDateFrom, toDatePlusOne, strAccountMatch,strOrgFamily, strcBpartnerId,
            strmProductId, strcProjectId, strAmtFrom, strAmtTo, null, null, null, pgLimit, "","");
      }
      // Now dataTotal is covered adding debit and credit amounts
      for (int i = 0; dataTotal != null && i < dataTotal.length; i++) {
    	if (data[0].id.equals(dataTotal[i].id)) {
	        previousDebit = previousDebit.add(new BigDecimal(dataTotal[i].amtacctdr));
	        previousCredit = previousCredit.add(new BigDecimal(dataTotal[i].amtacctcr));
    	}
        totalsubadded = BigDecimal.ZERO;
      }
      String strOld = "";
      int j = 0;
      ReportGeneralLedgerData[] subreportElement = new ReportGeneralLedgerData[1];
      ReportGeneralLedgerData[] subreportElement2 = new ReportGeneralLedgerData[1];
      BigDecimal balcr=new BigDecimal("0.00");
      BigDecimal baldr=new BigDecimal("0.00");
      BigDecimal balt=new BigDecimal("0.00");
      for (int i = 0; data != null && i < data.length; i++) {
		if (displayBalance.equals("Y") && (!strOld.equals(data[i].groupbyid + data[i].id))) {
			String bedate=ReportGeneralLedgerData.BalanceBeginDate(this,strOrg,data[i].id, strDateTo);
			subreportElement2 = ReportGeneralLedgerData.selectTotal(this, bedate,
					strDateFrom, (strGroupBy.equals("BPartner") ? "('" + data[i].groupbyid + "')"
	                    : strcBpartnerId), (strGroupBy.equals("Product") ? "('" + data[i].groupbyid
	                    + "')" : strmProductId), (strGroupBy.equals("Project") ? "('"
	                    + data[i].groupbyid + "')" : strcProjectId), strcAcctSchemaId, data[i].id,
	                bedate, strDateFrom, strOrgFamily);
			balcr=new BigDecimal(subreportElement2[0].totalacctcr);
			baldr=new BigDecimal(subreportElement2[0].totalacctdr);
			balt=new BigDecimal(subreportElement2[0].total);
		}
        if (!strOld.equals(data[i].groupbyid + data[i].id)) {
          
          subreportElement = new ReportGeneralLedgerData[1];
          if (i == 0 && initRecordNumber > 0) {
            subreportElement = new ReportGeneralLedgerData[1];
            subreportElement[0] = new ReportGeneralLedgerData();
            subreportElement[0].totalacctdr = previousDebit.toPlainString();
            subreportElement[0].totalacctcr = previousCredit.toPlainString();
            if (data[i].accounttype.equals("A")) {
            	subreportElement[0].total = previousDebit.subtract(previousCredit).multiply(new BigDecimal("-1")).toPlainString();
            	totalsubadded =previousDebit.subtract(previousCredit).multiply(new BigDecimal("-1"));
            }else{
            	subreportElement[0].total = previousDebit.subtract(previousCredit).toPlainString();
            	totalsubadded =previousDebit.subtract(previousCredit);
            }
          } else
            subreportElement = ReportGeneralLedgerData.selectTotal(this, strDateFrom,
                toDatePlusOne, (strGroupBy.equals("BPartner") ? "('" + data[i].groupbyid + "')"
                    : strcBpartnerId), (strGroupBy.equals("Product") ? "('" + data[i].groupbyid
                    + "')" : strmProductId), (strGroupBy.equals("Project") ? "('"
                    + data[i].groupbyid + "')" : strcProjectId), strcAcctSchemaId, data[i].id,
                strDateFrom, strDateFrom, strOrgFamily);
          
          data[i].totalacctdr = new BigDecimal(subreportElement[0].totalacctdr).add(baldr).toPlainString();
          data[i].totalacctcr = new BigDecimal(subreportElement[0].totalacctcr).add(balcr).toPlainString();
          data[i].totalacctsub = new BigDecimal(subreportElement[0].total).add(balt).toPlainString();
          j++;
        }
        data[i].previousdebit =  new BigDecimal(subreportElement[0].totalacctdr).add(baldr).toPlainString();
        data[i].previouscredit =new BigDecimal( subreportElement[0].totalacctcr).add(balcr).toPlainString();
        data[i].previoustotal = new BigDecimal(subreportElement[0].total).add(balt).toPlainString();
        strOld = data[i].groupbyid + data[i].id;
      }
      String strTotal = "";
      int g = 0;
      subreportElement = new ReportGeneralLedgerData[1];
      for (int i = 0; data != null && i < data.length; i++) {
        if (!strTotal.equals(data[i].groupbyid + data[i].id)) {
          if (g>0)
          	totalsubadded = BigDecimal.ZERO; 
          g++;
          subreportElement = new ReportGeneralLedgerData[1];
          subreportElement = ReportGeneralLedgerData.selectTotal(this, strDateFrom, toDatePlusOne,
              (strGroupBy.equals("BPartner") ? "('" + data[i].groupbyid + "')" : strcBpartnerId),
              (strGroupBy.equals("Product") ? "('" + data[i].groupbyid + "')" : strmProductId),
              (strGroupBy.equals("Project") ? "('" + data[i].groupbyid + "')" : strcProjectId),
              strcAcctSchemaId, data[i].id,strDateFrom, toDatePlusOne, strOrgFamily);
          
          if (displayBalance.equals("Y")) {
  			String bedate=ReportGeneralLedgerData.BalanceBeginDate(this,strOrg,data[i].id, strDateTo);
  			subreportElement2 = ReportGeneralLedgerData.selectTotal(this, bedate,
  	                toDatePlusOne, (strGroupBy.equals("BPartner") ? "('" + data[i].groupbyid + "')"
  	                    : strcBpartnerId), (strGroupBy.equals("Product") ? "('" + data[i].groupbyid
  	                    + "')" : strmProductId), (strGroupBy.equals("Project") ? "('"
  	                    + data[i].groupbyid + "')" : strcProjectId), strcAcctSchemaId, data[i].id,
  	                bedate, strDateFrom, strOrgFamily);
  			balcr=new BigDecimal(subreportElement2[0].totalacctcr);
  			baldr=new BigDecimal(subreportElement2[0].totalacctdr);
  			balt=new BigDecimal(subreportElement2[0].total);
  			totalsubadded = totalsubadded.add(balt);
  		  }
          
        }
        data[i].finaldebit = new BigDecimal(subreportElement[0].totalacctdr).add(baldr).toPlainString();
        data[i].finalcredit = new BigDecimal(subreportElement[0].totalacctcr).add(balcr).toPlainString();
        data[i].finaltotal = new BigDecimal(subreportElement[0].total).add(balt).toPlainString();
        totalsubadded=totalsubadded.add( new BigDecimal(data[i].total));
        data[i].totalsubadded=totalsubadded.toPlainString();
        strTotal = data[i].groupbyid + data[i].id;
      }

      boolean hasPrevious = !(data == null || data.length == 0 || initRecordNumber <= 1);
      boolean hasNext = !(data == null || data.length == 0 || data.length < intRecordRange);
      toolbar
          .prepareRelationBarTemplate(hasPrevious, hasNext,
              "submitCommandForm('XLS', true, frmMain, 'ReportGeneralLedgerExcel.xls', 'EXCEL');return false;");
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportGeneralLedger", discard).createXmlDocument();
    }
    xmlDocument.setParameter("toolbar", toolbar.toString());

    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_reports.ReportGeneralLedger");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(), "ReportGeneralLedger.html",
          classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb(), vars);
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "ReportGeneralLedger.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportGeneralLedger");
      vars.removeMessage("ReportGeneralLedger");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_ORG_ID", "",
          "", Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportGeneralLedger"), Utility
              .getContext(this, vars, "#User_Client", "ReportGeneralLedger"), '*');
      comboTableData.fillParameters(null, "ReportGeneralLedger", "");
      xmlDocument.setData("reportAD_ORGID", "liststructure", comboTableData.select(false));
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("dateFrom",  UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTo",  UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("amtFrom", strAmtFrom);
    xmlDocument.setParameter("amtTo", strAmtTo);
    xmlDocument.setParameter("adOrgId", strOrg);
    xmlDocument.setParameter("cAcctschemaId", strcAcctSchemaId);
    xmlDocument.setParameter("paramElementvalueIdTo", strcelementvalueto);
    xmlDocument.setParameter("paramElementvalueIdFrom", strcelementvaluefrom);
    xmlDocument.setParameter("inpElementValueIdTo_DES", strcelementvaluetodes);
    xmlDocument.setParameter("inpElementValueIdFrom_DES", strcelementvaluefromdes);
    xmlDocument.setParameter("AccountMatch",strAccountMatch);
    xmlDocument.setParameter("paramHide0", !strHide.equals("Y") ? "0" : "1");
    xmlDocument.setParameter("groupbyselected", strGroupBy);
    // nach Kontenklassen sortieren
    xmlDocument.setParameter("paramBalance", !displayBalance.equals("Y") ? "0" : "1");
    xmlDocument.setParameter("paramSums", !suminvlines.equals("FACT_ACCT_GROUP_ID") ? "0" : "1");
    xmlDocument.setData("reportCBPartnerId_IN", "liststructure", SelectorUtilityData
        .selectBpartner(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility
            .getContext(this, vars, "#User_Client", ""), strcBpartnerIdAux));
    xmlDocument.setData("reportMProductId_IN", "liststructure", SelectorUtilityData.selectMproduct(
        this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility.getContext(this,
            vars, "#User_Client", ""), strmProductIdAux));
    xmlDocument.setData("reportCProjectId_IN", "liststructure", SelectorUtilityData.selectProject(
        this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility.getContext(this,
            vars, "#User_Client", ""), strcProjectIdAux));
    xmlDocument.setData("reportC_ACCTSCHEMA_ID", "liststructure", AccountingSchemaMiscData
        .selectC_ACCTSCHEMA_ID(this, Utility.getContext(this, vars, "#AccessibleOrgTree",
            "ReportGeneralLedger"), Utility.getContext(this, vars, "#User_Client",
            "ReportGeneralLedger"), strcAcctSchemaId));

    if (log4j.isDebugEnabled())
      log4j.debug("data.length: " + data.length);

    if (strGroupBy.equals(""))
      xmlDocument.setData("structure1", data);
    else
      xmlDocument.setData("structure2", data);

    /*
     * if (strcBpartnerId.equals("") && strAll.equals("")) xmlDocument.setDataArray("reportTotals",
     * "structure", subreport); else xmlDocument.setDataArray("reportTotals2", "structure",
     * subreport); if (strcBpartnerId.equals("") && strAll.equals(""))
     * xmlDocument.setDataArray("reportAll", "structure", subreport2); else
     * xmlDocument.setDataArray("reportAll2", "structure", subreport2);
     */

    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageDataPDF(HttpServletRequest request, HttpServletResponse response,
      VariablesSecureApp vars, String strDateFrom, String strDateTo, String strAmtFrom,
      String strAmtTo, String strcelementvaluefrom, String strcelementvalueto, String strOrg,
      String strcBpartnerId, String strmProductId, String strcProjectId, String strGroupBy,
      String strHide, String strcAcctSchemaId,String strAccountMatch,String displayBalance, String suminvlines) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: PDF");
    response.setContentType("text/html; charset=UTF-8");
    ReportGeneralLedgerData[] data = null;
    ReportGeneralLedgerData[] subreport = null;
    String strTreeOrg = TreeData.getTreeOrg(this, vars.getClient());
    String strOrgFamily = "";
    strOrgFamily = getFamily(strTreeOrg, strOrg);
   
    String toDatePlusOne = DateTimeData.nDaysAfter(this, strDateTo, "1");

    String strGroupByText = (strGroupBy.equals("BPartner") ? Utility.messageBD(this, "BusPartner",
        vars.getLanguage()) : (strGroupBy.equals("Product") ? Utility.messageBD(this, "Product",
        vars.getLanguage()) : (strGroupBy.equals("Project") ? Utility.messageBD(this, "Project",
        vars.getLanguage()) : "")));
    String strAllaccounts = "Y";

    if (!strDateFrom.equals("") && !strDateTo.equals("")) {
      strOrgFamily = getFamily(strTreeOrg, strOrg);
      if (!strHide.equals("Y"))
        strHide = "N";
      if (strcelementvaluefrom != null && !strcelementvaluefrom.equals("")) {
        if (strcelementvalueto.equals(""))
          strcelementvalueto = strcelementvaluefrom;
        strAllaccounts = "N";
      }
      if (strAccountMatch.equals(""))
        strAccountMatch="%";
      if (suminvlines.equals("Y")) suminvlines="FACT_ACCT_GROUP_ID"; else  suminvlines="FACT_ACCT_ID";
      data = ReportGeneralLedgerData.select(this, "0", vars.getLanguage(),strGroupByText, suminvlines,strGroupBy, strDateFrom,
          toDatePlusOne, strAllaccounts, strcelementvaluefrom, strcelementvalueto, Utility
              .getContext(this, vars, "#AccessibleOrgTree", "ReportGeneralLedger"), Utility
              .getContext(this, vars, "#User_Client", "ReportGeneralLedger"), strHide,
          strcAcctSchemaId, strDateFrom, toDatePlusOne,strAccountMatch, strOrgFamily, strcBpartnerId,
          strmProductId, strcProjectId, strAmtFrom, strAmtTo, null, null, null, null, null, null);
    }
    if (data == null || data.length == 0) {
      advisePopUp(request, response, "WARNING", Utility.messageBD(this, "NoDataFound", vars
          .getLanguage()));
    } else {
      String strOld = "";
      BigDecimal totalDebit = BigDecimal.ZERO;
      BigDecimal totalCredit = BigDecimal.ZERO;
      BigDecimal subTotal = BigDecimal.ZERO;

      subreport = new ReportGeneralLedgerData[data.length];
      for (int i = 0; data != null && i < data.length; i++) {
        if (!strOld.equals(data[i].groupbyid + data[i].id)) {
        	String bedate=strDateFrom;
          if (displayBalance.equals("Y"))
         	bedate=ReportGeneralLedgerData.BalanceBeginDate(this,strOrg,data[i].id, strDateTo);
          subreport = ReportGeneralLedgerData.selectTotal(this, bedate, DateTimeData
              .nDaysAfter(this, strDateTo, "1"), (strGroupBy.equals("BPartner") ? "('"
              + data[i].groupbyid + "')" : strcBpartnerId), (strGroupBy.equals("Product") ? "('"
              + data[i].groupbyid + "')" : strmProductId), (strGroupBy.equals("Project") ? "('"
              + data[i].groupbyid + "')" : strcProjectId), strcAcctSchemaId, data[i].id,
              bedate, strDateFrom, strOrgFamily);
          totalDebit = BigDecimal.ZERO;
          totalCredit = BigDecimal.ZERO;
          subTotal = BigDecimal.ZERO;
        }
        totalDebit = totalDebit.add(new BigDecimal(data[i].amtacctdr));
        data[i].totalacctdr = new BigDecimal(subreport[0].totalacctdr).add(totalDebit).toString();
        totalCredit = totalCredit.add(new BigDecimal(data[i].amtacctcr));
        data[i].totalacctcr = new BigDecimal(subreport[0].totalacctcr).add(totalCredit).toString();
        subTotal = subTotal.add(new BigDecimal(data[i].total));
        data[i].totalacctsub = new BigDecimal(subreport[0].total).add(subTotal).toString();
        data[i].previousdebit = subreport[0].totalacctdr;
        data[i].previouscredit = subreport[0].totalacctcr;
        data[i].previoustotal = subreport[0].total;
        if (displayBalance.equals("Y")) {
	        data[i].startcr=subreport[0].totalacctcr;
	        data[i].startdr=subreport[0].totalacctdr;
	        data[i].starttotal=subreport[0].total;
        }
        strOld = data[i].groupbyid + data[i].id;
      }

      String strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportGeneralLedger.jrxml";
      response.setHeader("Content-disposition", "inline; filename=ReportGeneralLedgerPDF.pdf");

      HashMap<String, Object> parameters = new HashMap<String, Object>();

      String strLanguage = vars.getLanguage();

      parameters.put("ShowGrouping", Boolean.valueOf(!strGroupBy.equals("")));
      parameters.put("Title", classInfo.name);
      StringBuilder strSubTitle = new StringBuilder();
      strSubTitle.append(Utility.messageBD(this, "DateFrom", strLanguage) + ": " +  UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat"))
          + " - " + Utility.messageBD(this, "DateTo", strLanguage) + ": " +UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat"))  + " - ");
      // strSubTitle.append(ReportGeneralLedgerData.selectCompany(this, vars.getClient()) + " - ");
      strSubTitle.append(ReportGeneralLedgerData.selectOrganization(this, strOrg));
      parameters.put("REPORT_SUBTITLE", strSubTitle.toString());
      parameters.put("Previous", Utility.messageBD(this, "Initial Balance", strLanguage));
      parameters.put("Total", Utility.messageBD(this, "Total", strLanguage));
      if (displayBalance.equals("Y"))
    	  parameters.put("BeginBalance",Utility.messageBD(this, "BeginBalance", strLanguage));
      else
    	  parameters.put("BeginBalance",null);
      String strDateFormat;
      strDateFormat = vars.getJavaDateFormat();
      parameters.put("strDateFormat", strDateFormat);
      

      renderJR(vars, response, strReportName, "pdf", parameters, data, null);
    }
  }

  private void printPageDataXLS(HttpServletRequest request, HttpServletResponse response,
      VariablesSecureApp vars, String strDateFrom, String strDateTo, String strAmtFrom,
      String strAmtTo, String strcelementvaluefrom, String strcelementvalueto, String strOrg,
      String strcBpartnerId, String strmProductId, String strcProjectId, String strGroupBy,
      String strHide, String strcAcctSchemaId, String strAccountMatch, String suminvlines) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: XLS");
    response.setContentType("text/html; charset=UTF-8");
    ReportGeneralLedgerData[] data = null;
    String strTreeOrg = TreeData.getTreeOrg(this, vars.getClient());
    String strOrgFamily = "";
    strOrgFamily = getFamily(strTreeOrg, strOrg);
   
    String toDatePlusOne = DateTimeData.nDaysAfter(this, strDateTo, "1");

    String strAllaccounts = "Y";

    if (!strDateFrom.equals("") && !strDateTo.equals("")) {
      if (!strHide.equals("Y"))
        strHide = "N";
      if (strcelementvaluefrom != null && !strcelementvaluefrom.equals("")) {
        if (strcelementvalueto.equals(""))
          strcelementvalueto = strcelementvaluefrom;
        strAllaccounts = "N";
      }
      if (strAccountMatch.equals(""))
        strAccountMatch="%";
      String grpbyprd="m_product.m_product_id";
      String grpbyprn="m_product.name";
      if (suminvlines.equals("Y")) {
    	  suminvlines="FACT_ACCT_GROUP_ID";
    	  grpbyprd="''";
    	  grpbyprn="''";
      } else  suminvlines="FACT_ACCT_ID";
      
      data = ReportGeneralLedgerData.selectXLS(this, vars.getLanguage(),suminvlines,grpbyprd,grpbyprn,strDateFrom, toDatePlusOne, strAllaccounts,
          strcelementvaluefrom, strcelementvalueto, Utility.getContext(this, vars,
              "#AccessibleOrgTree", "ReportGeneralLedger"), Utility.getContext(this, vars,
              "#User_Client", "ReportGeneralLedger"), strHide, strcAcctSchemaId, strDateFrom,
          toDatePlusOne,strAccountMatch, strOrgFamily, strcBpartnerId, strmProductId, strcProjectId, strAmtFrom,
          strAmtTo);
    }
    if (data == null || data.length == 0) {
      advisePopUp(request, response, "WARNING", Utility.messageBD(this, "NoDataFound", vars
          .getLanguage()));
    } else {

      String strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportGeneralLedgerExcel.jrxml";

      HashMap<String, Object> parameters = new HashMap<String, Object>();

      String strLanguage = vars.getLanguage();

      parameters.put("Title", classInfo.name);
      StringBuilder strSubTitle = new StringBuilder();
      strSubTitle.append(Utility.messageBD(this, "DateFrom", strLanguage) + ": " + UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat"))
          + " - " + Utility.messageBD(this, "DateTo", strLanguage) + ": " + UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")) + " - ");
      // strSubTitle.append(ReportGeneralLedgerData.selectCompany(this, vars.getClient()) + " - ");
      strSubTitle.append(ReportGeneralLedgerData.selectOrganization(this, strOrg));
      parameters.put("REPORT_SUBTITLE", strSubTitle.toString());
      String strDateFormat;
      strDateFormat = vars.getJavaDateFormat();
      parameters.put("strDateFormat", strDateFormat);

      renderJR(vars, response, strReportName, "xls", parameters, data, null);
    }
  }

  private String getFamily(String strTree, String strChild) throws IOException, ServletException {
    return Tree.getMembers(this, strTree, strChild);
  }

  public String getServletInfo() {
    return "Servlet ReportGeneralLedger. This Servlet was made by Pablo Sarobe";
  } // end of getServletInfo() method
}
