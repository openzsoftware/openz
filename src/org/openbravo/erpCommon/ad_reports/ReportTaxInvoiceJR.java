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
import java.text.SimpleDateFormat;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperReport;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.ad_combos.OrganizationComboData;
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

public class ReportTaxInvoiceJR extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    String strUserCurrencyId = Utility.stringBaseCurrencyId(this, vars.getClient());
    if (vars.commandIn("DEFAULT")) {
      String strCurrencyId = vars.getGlobalVariable("inpCurrencyId","ReportTaxInvoiceJR|currency", strUserCurrencyId);
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom", "ReportTaxInvoiceJR|DateFrom", "",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTaxInvoiceJR|DateTo", "",this);
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportTaxInvoiceJR|Org", "");
      String strDetail = vars.getStringParameter("inpDetalle", "-1");
      String strSales = vars.getStringParameter("inpSales", "S");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strOrg, strDetail, strSales,strCurrencyId);
    } else if (vars.commandIn("PRINT_HTML")) {
      String strCurrencyId = vars.getRequestGlobalVariable("inpCurrencyId","ReportTaxInvoiceJR|currency");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportTaxInvoiceJR|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTaxInvoiceJR|DateTo",this);
      String strOrg = vars.getRequestGlobalVariable("inpOrg", "ReportTaxInvoiceJR|Org");
      String strDetail = vars.getStringParameter("inpDetalle");
      String strSales = vars.getStringParameter("inpSales");
      printPageDataHtml(response, vars, strDateFrom, strDateTo, strOrg, strDetail, strSales, "html",strCurrencyId);
    } else if (vars.commandIn("PRINT_PDF")) {
      String strCurrencyId = vars.getRequestGlobalVariable("inpCurrencyId","ReportTaxInvoiceJR|currency");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportTaxInvoiceJR|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTaxInvoiceJR|DateTo",this);
      String strOrg = vars.getRequestGlobalVariable("inpOrg", "ReportTaxInvoiceJR|Org");
      if (strOrg.equals(""))
        strOrg = "0";
      String strDetail = vars.getStringParameter("inpDetalle");
      String strSales = vars.getStringParameter("inpSales");
      printPageDataHtml(response, vars, strDateFrom, strDateTo, strOrg, strDetail, strSales, "pdf",strCurrencyId);
    } else if (vars.commandIn("RELATION_XLS")) {
      String strCurrencyId = vars.getRequestGlobalVariable("inpCurrencyId","ReportTaxInvoiceJR|currency");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportTaxInvoiceJR|DateFrom",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportTaxInvoiceJR|DateTo",this);
      String strOrg = vars.getRequestGlobalVariable("inpOrg", "ReportTaxInvoiceJR|Org");
      String strDetail = vars.getStringParameter("inpDetalle");
      String strSales = vars.getStringParameter("inpSales");
      printPageDataHtml(response, vars, strDateFrom, strDateTo, strOrg, strDetail, strSales, "xls",strCurrencyId);
    } else
      pageError(response);
  }

  private void printPageDataHtml(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strOrg, String strDetail, String strSales,
      String strOutput,String strCurrencyId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    String strSale = "";
    String strPurchase = "";
    if (strOrg.equals(""))
      strOrg = vars.getOrg();
    if (log4j.isDebugEnabled())
      log4j.debug("****** strSales: " + strSales + " fecha desde: " + strDateFrom
          + " fecha hasta: " + strDateTo + " detalle: " + strDetail);
    /*
     * if (strSales.equals("S")) strSalesAux = "Y"; else strSalesAux = "N";
     */
    if (strDateFrom.equals("") && strDateTo.equals("") && strDetail.equals("-1")) {
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strOrg, strDetail, strSales,strCurrencyId);
    } else if (!strDetail.equals("-1")) {
      if (log4j.isDebugEnabled())
        log4j.debug("****** not datailed");
      if (strSales.equals("S")) {
        strSale = Utility.messageBD(this, "Sale", vars.getLanguage());
      } else if (strSales.equals("P")) {
        strPurchase = Utility.messageBD(this, "Purchase", vars.getLanguage());
      } else {
        strSale = Utility.messageBD(this, "Sale", vars.getLanguage());
        strPurchase = Utility.messageBD(this, "Purchase", vars.getLanguage());
      }
    } else {
      if (log4j.isDebugEnabled())
        log4j.debug("****** detailed");
      if (strSales.equals("S")) {
        strSale = Utility.messageBD(this, "Sale", vars.getLanguage());
      } else if (strSales.equals("P")) {
        strPurchase = Utility.messageBD(this, "Purchase", vars.getLanguage());
      } else {
        strSale = Utility.messageBD(this, "Sale", vars.getLanguage());
        strPurchase = Utility.messageBD(this, "Purchase", vars.getLanguage());
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug("****** strSale: " + strSale + " strPurchase: " + strPurchase);

    String strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportTaxInvoice.jrxml";

    HashMap<String, Object> parameters = new HashMap<String, Object>();
    parameters.put("DETAIL", strDetail.equals("-1") ? "Y" : "N");
    parameters.put("cCountryId", new String(Utility.getContext(this, vars, "C_Country_Id",
        "ReportTaxInvoiceJR")));
    parameters.put("SALE", strSale);
    parameters.put("PURCHASE", strPurchase);
    parameters.put("PARAM_ORG", Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()),
        strOrg));
    parameters.put("PARAM_CURRENCY", strCurrencyId);
    String strDateFormat;
    strDateFormat = vars.getJavaDateFormat();
    SimpleDateFormat dateFormat = new SimpleDateFormat(strDateFormat);
    try {
      parameters.put("parDateFrom", strDateFrom);
      parameters.put("parDateTo", DateTimeData.nDaysAfter(this, strDateTo, "1"));
    } catch (Exception e) {
      throw new ServletException(e.getMessage());
    }
    JasperReport jasperSale;
    JasperReport jasperSaleForeign;
    JasperReport jasperPurchase;
    JasperReport jasperPurchaseForeign;

    String strLanguage = vars.getLanguage();
    String strBaseDesign = getBaseDesignPath(strLanguage);
    try {
      jasperSale = Utility.getTranslatedJasperReport(this, strBaseDesign
          + "/org/openbravo/erpCommon/ad_reports/ReportTaxInvoiceSale.jrxml", vars.getLanguage(),
          strBaseDesign);
      jasperSaleForeign = Utility.getTranslatedJasperReport(this, strBaseDesign
          + "/org/openbravo/erpCommon/ad_reports/ReportTaxInvoiceSaleForeign.jrxml", vars
          .getLanguage(), strBaseDesign);
      jasperPurchase = Utility.getTranslatedJasperReport(this, strBaseDesign
          + "/org/openbravo/erpCommon/ad_reports/ReportTaxInvoicePurchase.jrxml", vars
          .getLanguage(), strBaseDesign);
      jasperPurchaseForeign = Utility.getTranslatedJasperReport(this, strBaseDesign
          + "/org/openbravo/erpCommon/ad_reports/ReportTaxInvoicePurchaseForeign.jrxml", vars
          .getLanguage(), strBaseDesign);

    } catch (JRException e) {
      e.printStackTrace();
      throw new ServletException(e.getMessage());
    }
    parameters.put("SR_SALE", jasperSale);
    parameters.put("SR_SALEFOREIGN", jasperSaleForeign);
    parameters.put("SR_PURCHASE", jasperPurchase);
    parameters.put("SR_PURCHASEFOREIGN", jasperPurchaseForeign);

    renderJR(vars, response, strReportName, strOutput, parameters, null, null);
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strOrg, String strDetail, String strSales,String strCurrencyId)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = null;

    String strTitle = "FACTURAS CON EL EXTRANJERO";
    String strSale = "";
    String strPurchase = "";
    String discard[] = { "discard", "discard", "discard", "discard" };
    if (log4j.isDebugEnabled())
      log4j.debug("****** strSales: " + strSales + " fecha desde: " + strDateFrom
          + " fecha hasta: " + strDateTo + " detalle: " + strDetail);

    if (log4j.isDebugEnabled())
      log4j.debug("****** xmlDocument");
    xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/ad_reports/ReportTaxInvoice",
        discard).createXmlDocument();

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportTaxInvoiceJR", false, "", "",
        "", false, "ad_reports", strReplaceWith, false, true);
    toolbar
        .prepareSimpleExcelToolBarTemplate("submitCommandForm('RELATION_XLS', false, null, 'ReportTaxInvoice_Excel.xls', 'EXCEL');return false;");
    xmlDocument.setParameter("toolbar", toolbar.toString());

    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_reports.ReportTaxInvoiceJR");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(), "ReportTaxInvoice.html",
          classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "ReportTaxInvoice.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportTaxInvoiceJR");
      vars.removeMessage("ReportTaxInvoiceJR");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }
    xmlDocument.setParameter("ccurrencyid", strCurrencyId);
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "C_Currency_ID",
          "", "", Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTaxInvoiceJR"),
          Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoiceJR"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "ReportTaxInvoiceJR",
          strCurrencyId);
      xmlDocument.setData("reportC_Currency_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("dateFrom", strDateFrom);
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTo", strDateTo);
    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("detalle", strDetail);
    xmlDocument.setParameter("psale", strSales);
    xmlDocument.setParameter("ppurchase", strSales);
    xmlDocument.setParameter("pboth", strSales);
    xmlDocument.setParameter("adOrgId", strOrg);
    xmlDocument.setParameter("titleSale", strTitle);
    xmlDocument.setParameter("titlePurchase", strTitle);
    xmlDocument.setParameter("sale", strSale);
    xmlDocument.setParameter("purchase", strPurchase);
    if (log4j.isDebugEnabled())
      log4j.debug("****** setData reportAD_ORGID");
    /*
     * String strTreeNode = ReportTaxInvoiceData.selectTreeNode(this, Utility.getContext(this, vars,
     * "#User_Client", "ReportTaxInvoice")); xmlDocument
     * .setData("reportAD_ORGID","liststructure",AdOrgTreeComboData .select(this, strTreeNode,
     * vars.getOrg()));
     */
    xmlDocument.setData("reportAD_ORGID", "liststructure", OrganizationComboData.selectCombo(this,
        vars.getRole()));

    out.println(xmlDocument.print());
    out.close();
  }

  /*
   * void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars, String
   * strDateFrom, String strDateTo, String strOrg, String strDetail, String strSales) throws
   * IOException, ServletException { if (log4j.isDebugEnabled()) log4j.debug("Output: dataSheet");
   * response.setContentType("text/html; charset=UTF-8"); PrintWriter out = response.getWriter();
   * XmlDocument xmlDocument=null; ReportTaxInvoiceData[] dataSale=null; ReportTaxInvoiceData[]
   * data2Sale=null; ReportTaxInvoiceData[] dataPurchase=null; ReportTaxInvoiceData[]
   * data2Purchase=null; String strSalesAux; String strTitle = "FACTURAS CON EL EXTRANJERO"; String
   * strSale = ""; String strPurchase = ""; String discard[] = {"discard", "discard", "discard",
   * "discard"}; if (log4j.isDebugEnabled()) log4j.debug("****** strSales: " + strSales +
   * " fecha desde: " + strDateFrom + " fecha hasta: " + strDateTo + " detalle: " + strDetail);
   * 
   * if (strDateFrom.equals("") && strDateTo.equals("") && strDetail.equals("-1")) { if
   * (log4j.isDebugEnabled()) log4j.debug("****** all null"); discard[0] = "sectionTaxSale";
   * discard[1] = "sectionTaxForeignSale"; discard[2] = "sectionTaxPurchase"; discard[3] =
   * "sectionTaxForeignPurchase"; strTitle = ""; dataSale = ReportTaxInvoiceData.set(); data2Sale =
   * ReportTaxInvoiceData.set(); dataPurchase = ReportTaxInvoiceData.set(); data2Purchase =
   * ReportTaxInvoiceData.set(); } else if (!strDetail.equals("-1")){ if (log4j.isDebugEnabled())
   * log4j.debug("****** not datailed"); discard[0] = "selEliminarSale"; discard[1] =
   * "selEliminar1Sale"; discard[2] = "selEliminarPurchase"; discard[3] = "selEliminar1Purchase"; if
   * (strSales.equals("S")) { dataSale = ReportTaxInvoiceData.select(this, Utility.getContext(this,
   * vars, "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
   * "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "Y",
   * Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg)); data2Sale =
   * ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "Y", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); strSale = Utility.messageBD(this,
   * "Sale", vars.getLanguage()); } else if (strSales.equals("P")) { dataPurchase =
   * ReportTaxInvoiceData.select(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); data2Purchase =
   * ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); strPurchase = Utility.messageBD(this,
   * "Purchase", vars.getLanguage()); } else { dataSale = ReportTaxInvoiceData.select(this,
   * Utility.getContext(this, vars, "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this,
   * vars, "#User_Client", "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this,
   * strDateTo,"1"), "Y", Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()),
   * strOrg)); data2Sale = ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars,
   * "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
   * "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "Y",
   * Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg)); dataPurchase =
   * ReportTaxInvoiceData.select(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); data2Purchase =
   * ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); strSale = Utility.messageBD(this,
   * "Sale", vars.getLanguage()); strPurchase = Utility.messageBD(this, "Purchase",
   * vars.getLanguage()); } } else { if (log4j.isDebugEnabled()) log4j.debug("****** detailed"); if
   * (strSales.equals("S")) { dataSale = ReportTaxInvoiceData.select(this, Utility.getContext(this,
   * vars, "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
   * "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "Y",
   * Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg)); data2Sale =
   * ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "Y", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); strSale = Utility.messageBD(this,
   * "Sale", vars.getLanguage()); } else if (strSales.equals("P")) { dataPurchase =
   * ReportTaxInvoiceData.select(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); data2Purchase =
   * ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); strPurchase = Utility.messageBD(this,
   * "Purchase", vars.getLanguage()); } else { dataSale = ReportTaxInvoiceData.select(this,
   * Utility.getContext(this, vars, "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this,
   * vars, "#User_Client", "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this,
   * strDateTo,"1"), "Y", Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()),
   * strOrg)); data2Sale = ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars,
   * "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
   * "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "Y",
   * Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg)); dataPurchase =
   * ReportTaxInvoiceData.select(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); data2Purchase =
   * ReportTaxInvoiceData.selectForeign(this, Utility.getContext(this, vars, "C_Country_Id",
   * "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"),
   * strDateFrom, DateTimeData.nDaysAfter(this, strDateTo,"1"), "N", Tree.getMembers(this,
   * TreeData.getTreeOrg(this, vars.getClient()), strOrg)); strSale = Utility.messageBD(this,
   * "Sale", vars.getLanguage()); strPurchase = Utility.messageBD(this, "Purchase",
   * vars.getLanguage()); } } if (log4j.isDebugEnabled()) log4j.debug("****** strSale: " + strSale +
   * " strPurchase: " + strPurchase); if (log4j.isDebugEnabled()) log4j.debug("****** check nulls");
   * if (dataSale == null || dataSale.length == 0){ discard [0] = "sectionTaxSale"; dataSale =
   * ReportTaxInvoiceData.set(); } if (data2Sale == null || data2Sale.length == 0){ discard [1] =
   * "sectionTaxForeignSale"; strTitle = ""; data2Sale = ReportTaxInvoiceData.set(); } if
   * (dataPurchase == null || dataPurchase.length == 0){ discard [2] = "sectionTaxPurchase";
   * dataPurchase = ReportTaxInvoiceData.set(); } if (data2Purchase == null || data2Purchase.length
   * == 0){ discard [3] = "sectionTaxForeignPurchase"; strTitle = ""; data2Purchase =
   * ReportTaxInvoiceData.set(); } if (log4j.isDebugEnabled()) log4j.debug("****** xmlDocument");
   * xmlDocument = xmlEngine .readXmlTemplate("org/openbravo/erpCommon/ad_reports/ReportTaxInvoice",
   * discard).createXmlDocument();
   * 
   * ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportTaxInvoice", false, "", "",
   * "",false, "ad_reports", strReplaceWith, false, true);toolbar.prepareSimpleExcelToolBarTemplate(
   * "submitCommandForm('RELATION_XLS', false, null, 'ReportTaxInvoice_Excel.xls', 'EXCEL');return false;"
   * ); xmlDocument.setParameter("toolbar", toolbar.toString());
   * 
   * try { WindowTabs tabs = new WindowTabs(this, vars,
   * "org.openbravo.erpCommon.ad_reports.ReportTaxInvoice");
   * xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
   * xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
   * xmlDocument.setParameter("childTabContainer", tabs.childTabs());
   * xmlDocument.setParameter("theme", vars.getTheme()); NavigationBar nav = new NavigationBar(this,
   * vars.getLanguage(), "ReportTaxInvoice.html", classInfo.id, classInfo.type, strReplaceWith,
   * tabs.breadcrumb()); xmlDocument.setParameter("navigationBar", nav.toString()); LeftTabsBar lBar
   * = new LeftTabsBar(this, vars.getLanguage(), "ReportTaxInvoice.html", strReplaceWith);
   * xmlDocument.setParameter("leftTabs", lBar.manualTemplate()); } catch (Exception ex) { throw new
   * ServletException(ex); } { OBError myMessage = vars.getMessage("ReportTaxInvoice");
   * vars.removeMessage("ReportTaxInvoice"); if (myMessage!=null) {
   * xmlDocument.setParameter("messageType", myMessage.getType());
   * xmlDocument.setParameter("messageTitle", myMessage.getTitle());
   * xmlDocument.setParameter("messageMessage", myMessage.getMessage()); } }
   * 
   * xmlDocument.setParameter("calendar", vars.getLanguage().substring(0,2));
   * xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
   * xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
   * xmlDocument.setParameter("dateFrom", strDateFrom);
   * xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
   * xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
   * xmlDocument.setParameter("dateTo", strDateTo); xmlDocument.setParameter("dateTodisplayFormat",
   * vars.getSessionValue("#AD_SqlDateFormat")); xmlDocument.setParameter("dateTosaveFormat",
   * vars.getSessionValue("#AD_SqlDateFormat")); xmlDocument.setParameter("detalle", strDetail);
   * xmlDocument.setParameter("psale", strSales); xmlDocument.setParameter("ppurchase", strSales);
   * xmlDocument.setParameter("pboth", strSales); xmlDocument.setParameter("adOrgId", strOrg);
   * xmlDocument.setParameter("titleSale", strTitle); xmlDocument.setParameter("titlePurchase",
   * strTitle); xmlDocument.setParameter("sale", strSale); xmlDocument.setParameter("purchase",
   * strPurchase); if (log4j.isDebugEnabled()) log4j.debug("****** setData reportAD_ORGID");
   * 
   * xmlDocument.setData("reportAD_ORGID", "liststructure", OrganizationComboData.selectCombo(this,
   * vars.getRole()));
   * 
   * if (log4j.isDebugEnabled()) log4j.debug("****** setData dataSale");
   * xmlDocument.setData("structure1Sale", dataSale); if (log4j.isDebugEnabled())
   * log4j.debug("****** setData data2Sale"); xmlDocument.setData("structure2Sale", data2Sale); if
   * (log4j.isDebugEnabled()) log4j.debug("****** setData dataPurchase");
   * xmlDocument.setData("structure1Purchase", dataPurchase); if (log4j.isDebugEnabled())
   * log4j.debug("****** setData data2Purchase"); xmlDocument.setData("structure2Purchase",
   * data2Purchase); out.println(xmlDocument.print()); out.close(); }
   */

  private void printPageDataExcel(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strOrg, String strDetail, String strSales,String strCurrencyId)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("application/xls");
    PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = null;
    ReportTaxInvoiceData[] dataSale = null;
    ReportTaxInvoiceData[] data2Sale = null;
    ReportTaxInvoiceData[] dataPurchase = null;
    ReportTaxInvoiceData[] data2Purchase = null;
    String strSale = "";
    String strPurchase = "";
    String discard[] = { "discard", "discard", "discard", "discard" };
    if (log4j.isDebugEnabled())
      log4j.debug("****** strSales: " + strSales + " fecha desde: " + strDateFrom
          + " fecha hasta: " + strDateTo + " detalle: " + strDetail);
    /*
     * if (strSales.equals("S")) strSalesAux = "Y"; else strSalesAux = "N";
     */
    if (strDateFrom.equals("") && strDateTo.equals("")) {
      if (log4j.isDebugEnabled())
        log4j.debug("****** all null");
      discard[0] = "sectionDetailSale";
      discard[1] = "sectionDetail1Sale";
      discard[2] = "sectionDetailPurchase";
      discard[3] = "sectionDetail1Purchase";
      dataSale = ReportTaxInvoiceData.set();
      data2Sale = ReportTaxInvoiceData.set();
      dataPurchase = ReportTaxInvoiceData.set();
      data2Purchase = ReportTaxInvoiceData.set();
    } else {
      if (log4j.isDebugEnabled())
        log4j.debug("****** detailed");
      if (strSales.equals("S")) {
        dataSale = ReportTaxInvoiceData.select(this,strCurrencyId,Utility.getContext(this, vars, "C_Country_Id",
            "ReportTaxInvoice"),
            Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"), strDateFrom,
            DateTimeData.nDaysAfter(this, strDateTo, "1"), "Y", Tree.getMembers(this, TreeData
                .getTreeOrg(this, vars.getClient()), strOrg));
        data2Sale = ReportTaxInvoiceData.selectForeign(this,strCurrencyId, Utility.getContext(this, vars,
            "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
            "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), "Y",
            Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg));
        strSale = Utility.messageBD(this, "Sale", vars.getLanguage());
      } else if (strSales.equals("P")) {
        dataPurchase = ReportTaxInvoiceData.select(this,strCurrencyId,Utility.getContext(this, vars,
            "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
            "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), "N",
            Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg));
        data2Purchase = ReportTaxInvoiceData.selectForeign(this,strCurrencyId, Utility.getContext(this, vars,
            "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
            "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), "N",
            Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg));
        strPurchase = Utility.messageBD(this, "Purchase", vars.getLanguage());
      } else {
        dataSale = ReportTaxInvoiceData.select(this,strCurrencyId,Utility.getContext(this, vars, "C_Country_Id",
            "ReportTaxInvoice"),
            Utility.getContext(this, vars, "#User_Client", "ReportTaxInvoice"), strDateFrom,
            DateTimeData.nDaysAfter(this, strDateTo, "1"), "Y", Tree.getMembers(this, TreeData
                .getTreeOrg(this, vars.getClient()), strOrg));
        data2Sale = ReportTaxInvoiceData.selectForeign(this,strCurrencyId, Utility.getContext(this, vars,
            "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
            "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), "Y",
            Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg));
        dataPurchase = ReportTaxInvoiceData.select(this,strCurrencyId,Utility.getContext(this, vars,
            "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
            "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), "N",
            Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg));
        data2Purchase = ReportTaxInvoiceData.selectForeign(this,strCurrencyId, Utility.getContext(this, vars,
            "C_Country_Id", "ReportTaxInvoice"), Utility.getContext(this, vars, "#User_Client",
            "ReportTaxInvoice"), strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), "N",
            Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg));
        strSale = Utility.messageBD(this, "Sale", vars.getLanguage());
        strPurchase = Utility.messageBD(this, "Purchase", vars.getLanguage());
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug("****** strSale: " + strSale + " strPurchase: " + strPurchase);
    if (log4j.isDebugEnabled())
      log4j.debug("****** check nulls");
    if (dataSale == null || dataSale.length == 0) {
      discard[0] = "sectionDetailSale";
      dataSale = ReportTaxInvoiceData.set();
    }
    if (data2Sale == null || data2Sale.length == 0) {
      discard[1] = "sectionDetail1Sale";
      data2Sale = ReportTaxInvoiceData.set();
    }
    if (dataPurchase == null || dataPurchase.length == 0) {
      discard[2] = "sectionDetailPurchase";
      dataPurchase = ReportTaxInvoiceData.set();
    }
    if (data2Purchase == null || data2Purchase.length == 0) {
      discard[3] = "sectionDetail1Purchase";
      data2Purchase = ReportTaxInvoiceData.set();
    }
    if (log4j.isDebugEnabled())
      log4j.debug("****** xmlDocument");
    xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_reports/ReportTaxInvoice_Excel", discard).createXmlDocument();

    xmlDocument.setData("structure1Sale", dataSale);
    xmlDocument.setData("structure2Sale", data2Sale);
    xmlDocument.setData("structure1Purchase", dataPurchase);
    xmlDocument.setData("structure2Purchase", data2Purchase);
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet ReportTaxInvoice.";
  } // end of getServletInfo() method
}
