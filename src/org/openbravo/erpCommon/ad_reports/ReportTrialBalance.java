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
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Vector;

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
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.FormatUtils;
import org.openz.util.LocalizationUtils;
import org.openz.util.UtilsData;

public class ReportTrialBalance extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strcAcctSchemaId = vars.getGlobalVariable("inpcAcctSchemaId", "ReportTrialBalance|cAcctSchemaId", ReportTrialBalanceData.selectAcctSchemadefault(this, vars.getOrg()));
      //String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom", "ReportTrialBalance|DateFrom", "",this);
      //String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTrialBalance|DateTo", "",this);
      String strDateFrom = vars.getGlobalVariable("inpDateFrom", "ReportTrialBalance|DateFrom","");
      String strDateTo = vars.getGlobalVariable("inpDateTo", "ReportTrialBalance|DateTo","");
      String strOnly = "-1"; //Obsolete
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportTrialBalance|Org", vars.getOrg());
      String strLevel = "C"; // Obsolete
      String strAccountFrom = vars.getGlobalVariable("inpAccountFrom", "ReportTrialBalance|AccountFrom", "");
      String strAccountTo = vars.getGlobalVariable("inpAccountTo", "ReportTrialBalance|AccountTo", ReportTrialBalanceData.selectLastAccount(this, Utility.getContext(this, vars, "#AccessibleOrgTree", "Account"), Utility.getContext(this, vars, "#User_Client", "Account")));

      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN", "ReportTrialBalance|cBpartnerId", IsIDFilter.instance);
      String strAll = vars.getStringParameter("inpAll");
      String sortBy = vars.getGlobalVariable("inpSortbyacctcat", "ReportTrialBalance|SortBy","N");

      printPageDataSheet(response, vars, strDateFrom, strDateTo, strOrg, strLevel, strOnly, strAccountFrom, strAccountTo, strAll, strcBpartnerId, strcAcctSchemaId,sortBy);
    } else if (vars.commandIn("FIND")) {
      String strcAcctSchemaId = vars.getRequestGlobalVariable("inpcAcctSchemaId", "ReportTrialBalance|cAcctSchemaId");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom", "ReportTrialBalance|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTrialBalance|DateTo",this);
      String strOnly = "-1"; //Obsolete
      String strOrg = vars.getRequestGlobalVariable("inpOrg", "ReportTrialBalance|Org");
      String strLevel = "C"; // Obsolete
      String strAccountFrom = vars.getRequestGlobalVariable("inpAccountFrom", "ReportTrialBalance|AccountFrom");
      String strAccountTo = vars.getRequestGlobalVariable("inpAccountTo", "ReportTrialBalance|AccountTo");
      String sortBy=vars.getStringParameter("inpSortbyacctcat");
      if (sortBy.isEmpty())
    	  sortBy="N";
      vars.setSessionValue("ReportTrialBalance|SortBy",sortBy);
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN", "ReportTrialBalance|cBpartnerId", IsIDFilter.instance);
      String strAll = vars.getStringParameter("inpAll");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strOrg, strLevel, strOnly, strAccountFrom, strAccountTo, strAll, strcBpartnerId, strcAcctSchemaId,sortBy);
    } else if (vars.commandIn("PDF")) {
      String strcAcctSchemaId = vars.getRequestGlobalVariable("inpcAcctSchemaId", "ReportTrialBalance|cAcctSchemaId");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom", "ReportTrialBalance|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTrialBalance|DateTo",this);
      String strOnly = "-1"; //Obsolete
      String strOrg = vars.getRequestGlobalVariable("inpOrg", "ReportTrialBalance|Org");
      String strLevel = "C"; // Obsolete
      String strAccountFrom = vars.getRequestGlobalVariable("inpAccountFrom", "ReportTrialBalance|AccountFrom");
      String strAccountTo = vars.getRequestGlobalVariable("inpAccountTo", "ReportTrialBalance|AccountTo");
      String sortBy=vars.getStringParameter("inpSortbyacctcat");
      if (sortBy.isEmpty())
    	  sortBy="N";
      vars.setSessionValue("ReportTrialBalance|SortBy",sortBy);
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN", "ReportTrialBalance|cBpartnerId", IsIDFilter.instance);
      String strAll = vars.getStringParameter("inpAll");
      printPageDataPDF(request, response, vars, strDateFrom, strDateTo, strOrg, strLevel, strOnly, strAccountFrom, strAccountTo, strAll, strcBpartnerId, strcAcctSchemaId,sortBy);
    } else if (vars.commandIn("PRINTPDFCOMP")||vars.commandIn("PRINTEXCELCOMP")) {
      String strcAcctSchemaId = vars.getRequestGlobalVariable("inpcAcctSchemaId", "ReportTrialBalance|cAcctSchemaId");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom", "ReportTrialBalance|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTrialBalance|DateTo",this);
      String strOrg = vars.getRequestGlobalVariable("inpOrg", "ReportTrialBalance|Org");
      String strOutput = "";
      String strReportName = "";
      if (vars.commandIn("PRINTPDFCOMP")) {
        strOutput ="pdf";
        strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportTrialBalanceComparative.jrxml";
      }
      else {
        strOutput ="xls"; 
        strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportTrialBalanceComparativeXLS.jrxml";
      }
      String sortBy=vars.getStringParameter("inpSortbyacctcat");
      if (sortBy.isEmpty())
    	  sortBy="N";
      vars.setSessionValue("ReportTrialBalance|SortBy",sortBy);
      ReportTrialBalanceData[] data;
      if (sortBy.equals("N"))
    	  data=ReportTrialBalanceData.selectComparative(this, strOrg, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(),Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"));
      else
    	  data=ReportTrialBalanceData.selectComparativeSorted(this, strOrg, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(),Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"));

      HashMap<String, Object> parameters = new HashMap<String, Object>();
      parameters.put("IS_SORTBY_ACCTCAT", sortBy);

      renderJR(vars, response, strReportName, strOutput, parameters, data, null);
    } else
      pageError(response);
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars, String strDateFrom, String strDateTo, String strOrg, String strLevel, String strOnly, String strAccountFrom, 
		  							String strAccountTo, String strAll, String strcBpartnerId, String strcAcctSchemaId,String sortBy) throws IOException, ServletException {
    String strMessage = "";
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    if (log4j.isDebugEnabled())
      log4j.debug("strAll:" + strAll + " - strLevel:" + strLevel + " - strOnly:" + strOnly);
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    String discard[] = new String[3];
    if (strLevel.equalsIgnoreCase("C")) {
      discard[0] = "sectionDiscard";
      discard[1] = "sectionBP";
      discard[2] = "fieldId";
    } else {
      discard[0] = "sectionDiscard";
      discard[1] = "sectionBP";
      discard[2] = "fieldSpanAccount";
    }

    XmlDocument xmlDocument = null;
    String strTreeOrg = TreeData.getTreeOrg(this, vars.getClient());
    String strOrgFamily = getFamily(strTreeOrg, strOrg);
    String strTreeAccount = ReportTrialBalanceData.treeAccount(this, vars.getClient());
    String strcBpartnerIdAux = strcBpartnerId;

    ReportTrialBalanceData[] data = null;

    if (strDateFrom.equals("") && strDateTo.equals("")) {
      xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/ad_reports/ReportTrialBalance", discard).createXmlDocument();
      data = ReportTrialBalanceData.set();
      if (vars.commandIn("FIND")) {
        strMessage = Utility.messageBD(this, "BothDatesCannotBeBlank", vars.getLanguage());
        log4j.warn("Both dates are blank");
      }
    } else {
      if (!strLevel.equals("S"))
        discard[0] = "selEliminarField";
      else
        discard[0] = "discard";

      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - strOrgFamily = " + strOrgFamily);

      if (strLevel.equals("S") && strOnly.equals("-1")) {

        if (log4j.isDebugEnabled())
          log4j.debug("strcBpartnerId:" + strcBpartnerId + " - strAll:" + strAll);
        if (!(strAll.equals("") && (strcBpartnerId.equals("")))) {
          if (log4j.isDebugEnabled())
            log4j.debug("Select BP, strcBpartnerId:" + strcBpartnerId + " - strAll:" + strAll);
          if (!strAll.equals(""))
            strcBpartnerId = "";
          discard[1] = "sectionNoBP";
          data = ReportTrialBalanceData.selectBP(this, strDateFrom, strDateTo,strOrg, strOrgFamily, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), strAccountFrom, strAccountTo, strcBpartnerId, strcAcctSchemaId);
        } else {
        	if (sortBy.equals("N"))
        		data = ReportTrialBalanceData.select(this, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(), strTreeAccount, strOrg, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, strDateTo,strAccountFrom, strAccountTo);
        	else
        		data = ReportTrialBalanceData.selectSorted(this, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(), strTreeAccount, strOrg, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, strDateTo,strAccountFrom, strAccountTo);
        }
      } else {
    	  if (sortBy.equals("N"))
    		  data = ReportTrialBalanceData.select(this, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(), strTreeAccount, strOrg, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, strDateTo, "", "");
    	  else
      		data = ReportTrialBalanceData.selectSorted(this, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(), strTreeAccount, strOrg, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, strDateTo,strAccountFrom, strAccountTo);
      }

      if (log4j.isDebugEnabled())
        log4j.debug("Calculating tree...");
     // data = calculateTree(data, null, new Vector<Object>());
     // data = levelFilter(data, null, false, strLevel);
     // data = dataFilter(data);
      if (log4j.isDebugEnabled())
        log4j.debug("Tree calculated");
    }
    //ReportTrialBalanceData[] new_data = null;
    //if (strOnly.equals("-1") && data != null && data.length > 0)
    //  new_data = filterTree(data, strLevel);
    //else
    //  new_data = data;
    if (log4j.isDebugEnabled())
      log4j.debug("Creating xmlengine");
    xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/ad_reports/ReportTrialBalance", discard).createXmlDocument();
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "LIST", "", "C_ElementValue level", "", Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "ReportTrialBalance", "");
    //  xmlDocument.setData("reportLevel", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportTrialBalance", false, "", "", "imprimir();return false;", false, "ad_reports", strReplaceWith, false, true);
    toolbar.setEmail(false);
    toolbar.prepareSimpleToolBarTemplate();

    xmlDocument.setParameter("toolbar", toolbar.toString());

    try {
      WindowTabs tabs = new WindowTabs(this, vars, "org.openbravo.erpCommon.ad_reports.ReportTrialBalance");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(), "ReportTrialBalance.html", classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "ReportTrialBalance.html", strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportTrialBalance");
      vars.removeMessage("ReportTrialBalance");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setData("reportAccountFrom_ID", "liststructure", ReportTrialBalanceData.selectAccount(this, Utility.getContext(this, vars, "#AccessibleOrgTree", "Account"), Utility.getContext(this, vars, "#User_Client", "Account"), "", strcAcctSchemaId));
    xmlDocument.setData("reportAccountTo_ID", "liststructure", ReportTrialBalanceData.selectAccount(this, Utility.getContext(this, vars, "#AccessibleOrgTree", "Account"), Utility.getContext(this, vars, "#User_Client", "Account"), "", strcAcctSchemaId));

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_ORG_ID", "", "", Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), '*');
      comboTableData.fillParameters(null, "ReportTrialBalance", "");
      xmlDocument.setData("reportAD_ORGID", "liststructure", comboTableData.select(false));
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setData("reportC_ACCTSCHEMA_ID", "liststructure", AccountingSchemaMiscData.selectC_ACCTSCHEMA_ID(this, Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), strcAcctSchemaId));
    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("dateFrom",  UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTo",  UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
   // xmlDocument.setParameter("Only", strOnly);
    xmlDocument.setParameter("adOrgId", strOrg);
   // xmlDocument.setParameter("Level", strLevel);
    xmlDocument.setParameter("cAcctschemaId", strcAcctSchemaId);
    // nach Kontenklassen sortieren
    xmlDocument.setParameter("paramSortby", !sortBy.equals("Y") ? "0" : "1");
    xmlDocument.setParameter("accountFrom", strAccountFrom);
    xmlDocument.setParameter("accountTo", strAccountTo);
    xmlDocument.setParameter("paramMessage", (strMessage.equals("") ? "" : "alert('" + strMessage + "');"));
    xmlDocument.setParameter("paramAll0", strAll.equals("") ? "0" : "1");
    xmlDocument.setData("reportCBPartnerId_IN", "liststructure", SelectorUtilityData.selectBpartner(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility.getContext(this, vars, "#User_Client", ""), strcBpartnerIdAux));
    // SZ commented out - Is not needed and causes a performance problem..
    /*
     * xmlDocument.setParameter("accounFromArray", Utility.arrayDobleEntrada("arrAccountFrom",
     * ReportTrialBalanceData.selectAccountDouble(this, Utility.getContext(this, vars,
     * "#AccessibleOrgTree", "Account"), Utility.getContext(this, vars, "#User_Client", "Account"),
     * ""))); xmlDocument.setParameter("accounToArray", Utility.arrayDobleEntrada("arrAccountTo",
     * ReportTrialBalanceData.selectAccountDouble(this, Utility.getContext(this, vars,
     * "#AccessibleOrgTree", "Account"), Utility.getContext(this, vars, "#User_Client", "Account"),
     * "")));
     */
    if (data == null || data.length == 0)
        data = ReportTrialBalanceData.set();
    xmlDocument.setData("structure1", data);
    /*
    if (new_data == null || new_data.length == 0)
      new_data = ReportTrialBalanceData.set();
    if (log4j.isDebugEnabled())
      log4j.debug("filling structure, data.length:" + new_data.length);
    if (discard[1].equals("sectionNoBP")) {
      if (log4j.isDebugEnabled())
        log4j.debug("without BPs");
      xmlDocument.setData("structure2", new_data);
    } else {
      if (log4j.isDebugEnabled())
        log4j.debug("with BPs");
      if (strOnly.equals("-1"))
        Arrays.sort(new_data, new ReportTrialBalanceDataComparator());
      for (int i = 0; i < new_data.length; i++) {
        new_data[i].rownum = "" + i;
      }
      if (log4j.isDebugEnabled())
        log4j.debug("Rownum calculated");
      xmlDocument.setData("structure1", new_data);

    }
    */
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageDataPDF(HttpServletRequest request, HttpServletResponse response, VariablesSecureApp vars, String strDateFrom, String strDateTo, String strOrg, String strLevel, String strOnly, String strAccountFrom, String strAccountTo, String strAll, String strcBpartnerId, String strcAcctSchemaId, String sortBy) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    /*
     * response.setContentType("text/html; charset=UTF-8"); PrintWriter out = response.getWriter();
     */
    String discard[] = { "selEliminar", "sectionBP" };

    XmlDocument xmlDocument = null;
    String strTreeOrg = TreeData.getTreeOrg(this, vars.getClient());
    String strOrgFamily = getFamily(strTreeOrg, strOrg);
    String strTreeAccount = ReportTrialBalanceData.treeAccount(this, vars.getClient());
    ReportTrialBalanceData[] data = null;
    if (strDateFrom.equals("") && strDateTo.equals("")) {
      xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/ad_reports/ReportTrialBalancePDF", discard).createXmlDocument();
      data = ReportTrialBalanceData.set();
    } else {
      if (!strLevel.equals("S"))
        discard[0] = "selEliminarField";
      else
        discard[0] = "discard";

      if (strLevel.equals("S") && strOnly.equals("-1")) {

        if (!(strAll.equals("") && (strcBpartnerId.equals("")))) {
          if (log4j.isDebugEnabled())
            log4j.debug("Select BP, strcBpartnerId:" + strcBpartnerId + " - strAll:" + strAll);
          if (!strAll.equals(""))
            strcBpartnerId = "";
          discard[1] = "sectionNoBP";
          data = ReportTrialBalanceData.selectBP(this, strDateFrom, strDateTo, strOrg, strOrgFamily, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), strAccountFrom, strAccountTo, strcBpartnerId, strcAcctSchemaId);
        } else {
          data = ReportTrialBalanceData.select(this, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(), strTreeAccount, strOrg, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), strAccountFrom, strAccountTo);
        }
      } else {
    	  if (sortBy.equals("N"))
    		  data = ReportTrialBalanceData.select(this, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(), strTreeAccount, strOrg, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, strDateTo, "", "");
    	  else
    		data = ReportTrialBalanceData.selectSorted(this, strcAcctSchemaId, strDateFrom, strDateTo, vars.getLanguage(), strTreeAccount, strOrg, Utility.getContext(this, vars, "#User_Client", "ReportTrialBalance"), Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalance"), strDateFrom, strDateTo,strAccountFrom, strAccountTo);
      }
    }
    
/*
      data = calculateTree(data, null, new Vector<Object>());
      data = levelFilter(data, null, false, strLevel);
      data = dataFilter(data);

    }
    ReportTrialBalanceData[] new_data = null;
    if (strOnly.equals("-1") && data != null && data.length > 0)
      new_data = filterTree(data, strLevel);
    else
      new_data = data;
*/
    xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/ad_reports/ReportTrialBalancePDF", discard).createXmlDocument();
    xmlDocument.setParameter("companyName", ReportTrialBalanceData.selectCompany(this, vars.getClient()));
    xmlDocument.setParameter("orgName", ReportTrialBalanceData.selectOrgName(this, strOrg));
    xmlDocument.setParameter("date",  UtilsData.selectDisplayDatevalue(this,vars.getSessionValue("#DATE"), "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("period",  UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")) + " - " +  UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("accountingSchema", ReportTrialBalanceData.selectAcctSchemaName(this, strcAcctSchemaId));
    if (strLevel.equals("S"))
      xmlDocument.setParameter("accounting", Utility.messageBD(this, "FromAccount", vars.getLanguage()) + ": " + ReportTrialBalanceData.selectAccountingName(this, strAccountFrom) + " - " + Utility.messageBD(this, "ToAccount", vars.getLanguage()) + ": " + ReportTrialBalanceData.selectAccountingName(this, strAccountTo));
    else
      xmlDocument.setParameter("accounting", "");

    if (log4j.isDebugEnabled())
      log4j.debug("filling structure, data.length:");
    if (log4j.isDebugEnabled())
      log4j.debug("discard:" + discard[0] + "," + discard[1]);
    
    if (data == null || data.length == 0)
      data = ReportTrialBalanceData.set();
    if (discard[1].equals("sectionNoBP"))
      xmlDocument.setData("structure2", data);
    else {
    //  if (strOnly.equals("-1"))
    //    Arrays.sort(data, new ReportTrialBalanceDataComparator());
      xmlDocument.setData("structure1", data);
    }
    String strResult = xmlDocument.print();
    try {
      strResult = Replace.replace(strResult, "Organization", LocalizationUtils.getElementTextByElementName(this, "ad_org_id", vars.getLanguage()));
      strResult = Replace.replace(strResult, "Date", LocalizationUtils.getElementTextByElementName(this, "Date", vars.getLanguage()));
      strResult = Replace.replace(strResult, "Conditions", LocalizationUtils.getElementTextByElementName(this, "Filter", vars.getLanguage()));
      strResult = Replace.replace(strResult, "Period", LocalizationUtils.getElementTextByElementName(this, "Timeperiod", vars.getLanguage()));
      strResult = Replace.replace(strResult, "Accounting schema", LocalizationUtils.getElementTextByElementName(this, "C_AcctSchema_ID", vars.getLanguage()));
      strResult = Replace.replace(strResult, "SUM", LocalizationUtils.getElementTextByElementName(this, "Sum", vars.getLanguage()));

    } catch (Exception ex) {

    }

    renderFO(strResult, request, response);
    /*
     * out.println(xmlDocument.print()); out.close();
     */
  }

  private ReportTrialBalanceData[] filterTree(ReportTrialBalanceData[] data, String strLevel) {
    ArrayList<Object> arrayList = new ArrayList<Object>();
    for (int i = 0; data != null && i < data.length; i++) {
      if (data[i].elementlevel.equals(strLevel))
        arrayList.add(data[i]);
    }
    ReportTrialBalanceData[] new_data = new ReportTrialBalanceData[arrayList.size()];
    arrayList.toArray(new_data);
    return new_data;
  }

  private ReportTrialBalanceData[] calculateTree(ReportTrialBalanceData[] data, String indice, Vector<Object> vecTotal) {
    if (data == null || data.length == 0)
      return data;
    if (indice == null)
      indice = "0";
    ReportTrialBalanceData[] result = null;
    Vector<Object> vec = new Vector<Object>();
    // if (log4j.isDebugEnabled())
    // log4j.debug("ReportTrialBalanceData.calculateTree() - data: " +
    // data.length);
    if (vecTotal == null)
      vecTotal = new Vector<Object>();
    if (vecTotal.size() == 0) {
      vecTotal.addElement("0");
      vecTotal.addElement("0");
      vecTotal.addElement("0");
      vecTotal.addElement("0");
    }
    BigDecimal totalDR = new BigDecimal((String) vecTotal.elementAt(0));
    BigDecimal totalCR = new BigDecimal((String) vecTotal.elementAt(1));
    BigDecimal totalInicial = new BigDecimal((String) vecTotal.elementAt(2));
    BigDecimal totalFinal = new BigDecimal((String) vecTotal.elementAt(3));
    boolean encontrado = false;
    for (int i = 0; i < data.length; i++) {
      if (data[i].parentId.equals(indice)) {
        encontrado = true;
        Vector<Object> vecParcial = new Vector<Object>();
        vecParcial.addElement("0");
        vecParcial.addElement("0");
        vecParcial.addElement("0");
        vecParcial.addElement("0");
        ReportTrialBalanceData[] dataChilds = calculateTree(data, data[i].id, vecParcial);
        BigDecimal parcialDR = new BigDecimal((String) vecParcial.elementAt(0));
        BigDecimal parcialCR = new BigDecimal((String) vecParcial.elementAt(1));
        BigDecimal parcialInicial = new BigDecimal((String) vecParcial.elementAt(2));
        BigDecimal parcialFinal = new BigDecimal((String) vecParcial.elementAt(3));
        data[i].amtacctdr = (new BigDecimal(data[i].amtacctdr).add(parcialDR)).toPlainString();
        data[i].amtacctcr = (new BigDecimal(data[i].amtacctcr).add(parcialCR)).toPlainString();
        data[i].saldoInicial = (new BigDecimal(data[i].saldoInicial).add(parcialInicial)).toPlainString();
        data[i].saldoFinal = (new BigDecimal(data[i].saldoFinal).add(parcialFinal)).toPlainString();

        totalDR = totalDR.add(new BigDecimal(data[i].amtacctdr));
        totalCR = totalCR.add(new BigDecimal(data[i].amtacctcr));
        totalInicial = totalInicial.add(new BigDecimal(data[i].saldoInicial));
        totalFinal = totalFinal.add(new BigDecimal(data[i].saldoFinal));

        vec.addElement(data[i]);
        if (dataChilds != null && dataChilds.length > 0) {
          for (int j = 0; j < dataChilds.length; j++)
            vec.addElement(dataChilds[j]);
        }
      } else if (encontrado)
        break;
    }
    vecTotal.set(0, totalDR.toPlainString());
    vecTotal.set(1, totalCR.toPlainString());
    vecTotal.set(2, totalInicial.toPlainString());
    vecTotal.set(3, totalFinal.toPlainString());
    result = new ReportTrialBalanceData[vec.size()];
    vec.copyInto(result);
    return result;
  }

  private ReportTrialBalanceData[] dataFilter(ReportTrialBalanceData[] data) {
    if (data == null || data.length == 0)
      return data;
    Vector<Object> dataFiltered = new Vector<Object>();
    for (int i = 0; i < data.length; i++) {
      if (new BigDecimal(data[i].amtacctdr).compareTo(BigDecimal.ZERO) != 0 || new BigDecimal(data[i].amtacctcr).compareTo(BigDecimal.ZERO) != 0 || new BigDecimal(data[i].saldoInicial).compareTo(BigDecimal.ZERO) != 0 || new BigDecimal(data[i].saldoFinal).compareTo(BigDecimal.ZERO) != 0) {
        dataFiltered.addElement(data[i]);
      }
    }
    ReportTrialBalanceData[] result = new ReportTrialBalanceData[dataFiltered.size()];
    dataFiltered.copyInto(result);
    return result;
  }

  private ReportTrialBalanceData[] levelFilter(ReportTrialBalanceData[] data, String indice, boolean found, String strLevel) {
    if (data == null || data.length == 0 || strLevel == null || strLevel.equals(""))
      return data;
    ReportTrialBalanceData[] result = null;
    Vector<Object> vec = new Vector<Object>();
    // if (log4j.isDebugEnabled())
    // log4j.debug("ReportTrialBalanceData.levelFilter() - data: " +
    // data.length);

    if (indice == null)
      indice = "0";
    for (int i = 0; i < data.length; i++) {
      if (data[i].parentId.equals(indice) && (!found || data[i].elementlevel.equalsIgnoreCase(strLevel))) {
        ReportTrialBalanceData[] dataChilds = levelFilter(data, data[i].id, (found || data[i].elementlevel.equals(strLevel)), strLevel);
        vec.addElement(data[i]);
        if (dataChilds != null && dataChilds.length > 0)
          for (int j = 0; j < dataChilds.length; j++)
            vec.addElement(dataChilds[j]);
      }
    }
    result = new ReportTrialBalanceData[vec.size()];
    vec.copyInto(result);
    vec.clear();
    return result;
  }

  private String getFamily(String strTree, String strChild) throws IOException, ServletException {
    return Tree.getMembers(this, strTree, strChild);
    /*
     * ReportGeneralLedgerData [] data = ReportGeneralLedgerData.selectChildren(this, strTree,
     * strChild); String strFamily = ""; if(data!=null && data.length>0) { for (int i =
     * 0;i<data.length;i++){ if (i>0) strFamily = strFamily + ","; strFamily = strFamily +
     * data[i].id; } return strFamily; }else return "'1'";
     */
  }

  public String getServletInfo() {
    return "Servlet ReportTrialBalance. This Servlet was made by Eduardo Argal";
  } // end of getServletInfo() method
}
