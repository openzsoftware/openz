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
import java.util.StringTokenizer;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.filter.IsPositiveIntFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.ad_combos.OrganizationComboData;
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

public class ReportInvoiceCustomerDimensionalAnalyses extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT", "DEFAULT_COMPARATIVE")) {
      String strDateFrom = vars.getGlobalVariable("inpDateFrom",
          "ReportInvoiceCustomerDimensionalAnalyses|dateFrom", "");
      String strDateTo = vars.getGlobalVariable("inpDateTo",
          "ReportInvoiceCustomerDimensionalAnalyses|dateTo", "");
      String strDateFromRef = vars.getGlobalVariable("inpDateFromRef",
          "ReportInvoiceCustomerDimensionalAnalyses|dateFromRef", "");
      String strDateToRef = vars.getGlobalVariable("inpDateToRef",
          "ReportInvoiceCustomerDimensionalAnalyses|dateToRef", "");
      String strPartnerGroup = vars.getGlobalVariable("inpPartnerGroup",
          "ReportInvoiceCustomerDimensionalAnalyses|partnerGroup", "");
      String strcBpartnerId = vars.getInGlobalVariable("inpcBPartnerId_IN",
          "ReportInvoiceCustomerDimensionalAnalyses|partner", "", IsIDFilter.instance);
      String strProductCategory = vars.getGlobalVariable("inpProductCategory",
          "ReportInvoiceCustomerDimensionalAnalyses|productCategory", "");
      String strmProductId = vars.getInGlobalVariable("inpmProductId_IN",
          "ReportInvoiceCustomerDimensionalAnalyses|product", "", IsIDFilter.instance);
      // ad_ref_list.value for refercence_id 800087
      String strNotShown = vars.getInGlobalVariable("inpNotShown",
          "ReportInvoiceCustomerDimensionalAnalyses|notShown", "", IsPositiveIntFilter.instance);
      String strShown = vars.getInGlobalVariable("inpShown",
          "ReportInvoiceCustomerDimensionalAnalyses|shown", "", IsPositiveIntFilter.instance);
      String strOrg = vars.getGlobalVariable("inpOrg",
          "ReportInvoiceCustomerDimensionalAnalyses|org", "0");
      String strsalesrepId = vars.getGlobalVariable("inpSalesrepId",
          "ReportInvoiceCustomerDimensionalAnalyses|salesrep", "");
      String strcProjectId = vars.getGlobalVariable("inpcProjectId",
          "ReportInvoiceCustomerDimensionalAnalyses|project", "");
      String strProducttype = vars.getGlobalVariable("inpProducttype",
          "ReportInvoiceVendorDimensionalAnalyses|producttype", "");
      String strOrder = vars.getGlobalVariable("inpOrder",
          "ReportInvoiceCustomerDimensionalAnalyze|order", "Normal");
      String strMayor = vars.getNumericGlobalVariable("inpMayor",
          "ReportInvoiceCustomerSalesDimensionalAnalyze|mayor", "");
      String strMenor = vars.getNumericGlobalVariable("inpMenor",
          "ReportInvoiceCustomerDimensionalAnalyze|menor", "");
      String strPartnerSalesRepId = vars.getGlobalVariable("inpPartnerSalesrepId",
          "ReportInvoiceCustomerDimensionalAnalyses|partnersalesrep", "");
      String strComparative = "";
      if (vars.commandIn("DEFAULT_COMPARATIVE"))
        strComparative = vars.getRequestGlobalVariable("inpComparative",
            "ReportInvoiceCustomerDimensionalAnalyses|comparative");
      else
        strComparative = vars.getGlobalVariable("inpComparative",
            "ReportInvoiceCustomerDimensionalAnalyses|comparative", "N");
      printPageDataSheet(response, vars, strComparative, strDateFrom, strDateTo, strPartnerGroup,
          strcBpartnerId, strProductCategory, strmProductId, strNotShown, strShown, strDateFromRef,
          strDateToRef, strOrg, strsalesrepId, strcProjectId, strProducttype, strOrder, strMayor,
          strMenor, strPartnerSalesRepId);
    } else if (vars.commandIn("EDIT_HTML", "EDIT_HTML_COMPARATIVE")) {
      String strDateFrom = vars.getRequestGlobalVariable("inpDateFrom",
          "ReportInvoiceCustomerDimensionalAnalyses|dateFrom");
      String strDateTo = vars.getRequestGlobalVariable("inpDateTo",
          "ReportSInvoiceCustomerDimensionalAnalyses|dateTo");
      String strDateFromRef = vars.getRequestGlobalVariable("inpDateFromRef",
          "ReportInvoiceCustomerDimensionalAnalyses|dateFromRef");
      String strDateToRef = vars.getRequestGlobalVariable("inpDateToRef",
          "ReportSInvoiceCustomerDimensionalAnalyses|dateToRef");
      String strPartnerGroup = vars.getRequestGlobalVariable("inpPartnerGroup",
          "ReportInvoiceCustomerDimensionalAnalyses|partnerGroup");
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportInvoiceCustomerDimensionalAnalyses|partner", IsIDFilter.instance);
      String strProductCategory = vars.getRequestGlobalVariable("inpProductCategory",
          "ReportInvoiceCustomerDimensionalAnalyses|productCategory");
      String strmProductId = vars.getRequestInGlobalVariable("inpmProductId_IN",
          "ReportInvoiceCustomerDimensionalAnalyses|product", IsIDFilter.instance);
      // ad_ref_list.value for refercence_id 800087
      String strNotShown = vars.getInStringParameter("inpNotShown", IsPositiveIntFilter.instance);
      String strShown = vars.getInStringParameter("inpShown", IsPositiveIntFilter.instance);
      String strOrg = vars.getGlobalVariable("inpOrg",
          "ReportInvoiceCustomerDimensionalAnalyses|org", "0");
      String strsalesrepId = vars.getRequestGlobalVariable("inpSalesrepId",
          "ReportInvoiceCustomerDimensionalAnalyses|salesrep");
      String strcProjectId = vars.getRequestGlobalVariable("inpcProjectId",
          "ReportInvoiceCustomerDimensionalAnalyses|project");
      String strProducttype = vars.getRequestGlobalVariable("inpProducttype",
          "ReportInvoiceVendorDimensionalAnalyses|producttype");
      String strOrder = vars.getRequestGlobalVariable("inpOrder",
          "ReportSalesDimensionalAnalyze|order");
      String strMayor = vars.getNumericParameter("inpMayor", "");
      String strMenor = vars.getNumericParameter("inpMenor", "");
      String strComparative = vars.getStringParameter("inpComparative", "N");
      String strPartnerSalesrepId = vars.getRequestGlobalVariable("inpPartnerSalesrepId",
          "ReportInvoiceCustomerDimensionalAnalyses|partnersalesrep");
      printPageHtml(response, vars, strComparative, strDateFrom, strDateTo, strPartnerGroup,
          strcBpartnerId, strProductCategory, strmProductId, strNotShown, strShown, strDateFromRef,
          strDateToRef, strOrg, strsalesrepId, strcProjectId, strProducttype, strOrder, strMayor,
          strMenor, strPartnerSalesrepId);
    } else
      pageErrorPopUp(response);
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strComparative, String strDateFrom, String strDateTo, String strPartnerGroup,
      String strcBpartnerId, String strProductCategory, String strmProductId, String strNotShown,
      String strShown, String strDateFromRef, String strDateToRef, String strOrg,
      String strsalesrepId, String strcProjectId, String strProducttype, String strOrder,
      String strMayor, String strMenor, String strPartnerSalesrepId) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    String discard[] = { "selEliminarHeader1" };
    if (strComparative.equals("Y")) {
      discard[0] = "selEliminarHeader2";
    }
    XmlDocument xmlDocument = null;
    xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_reports/ReportInvoiceCustomerDimensionalAnalysesFilter",
        discard).createXmlDocument();

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(),
        "ReportInvoiceCustomerDimensionalAnalysesFilter", false, "", "", "", false, "ad_reports",
        strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());
    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_reports.ReportInvoiceCustomerDimensionalAnalyses");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(),
          "ReportInvoiceCustomerDimensionalAnalyses.html", classInfo.id, classInfo.type,
          strReplaceWith, tabs.breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(),
          "ReportInvoiceCustomerDimensionalAnalyses.html", strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportInvoiceCustomerDimensionalAnalyses");
      vars.removeMessage("ReportInvoiceCustomerDimensionalAnalyses");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("dateFrom", strDateFrom);
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTo", strDateTo);
    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromRef", strDateFromRef);
    xmlDocument.setParameter("dateFromRefdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromRefsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateToRef", strDateToRef);
    xmlDocument.setParameter("dateToRefdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateToRefsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    /*
     * xmlDocument.setParameter("paramBPartnerId", strcBpartnerId);
     * xmlDocument.setParameter("bPartnerDescription",
     * ReportInvoiceCustomerDimensionalAnalysesData.selectBpartner(this, strcBpartnerId));
     * xmlDocument.setParameter("mProduct", strmProductId);
     * xmlDocument.setParameter("productDescription",
     * ReportInvoiceCustomerDimensionalAnalysesData.selectMproduct(this, strmProductId));
     */
    xmlDocument.setParameter("cBpGroupId", strPartnerGroup);
    xmlDocument.setParameter("mProductCategoryId", strProductCategory);
    xmlDocument.setParameter("adOrgId", strOrg);
    xmlDocument.setParameter("salesRepId", strsalesrepId);
    xmlDocument.setParameter("normal", strOrder);
    xmlDocument.setParameter("amountasc", strOrder);
    xmlDocument.setParameter("amountdesc", strOrder);
    xmlDocument.setParameter("mayor", strMayor);
    xmlDocument.setParameter("menor", strMenor);
    xmlDocument.setParameter("comparative", strComparative);
    xmlDocument.setParameter("cProjectId", strcProjectId);
    xmlDocument.setParameter("producttype", strProducttype);
    xmlDocument.setParameter("partnerSalesRepId", strPartnerSalesrepId);
    xmlDocument.setParameter("projectName", ReportInvoiceCustomerDimensionalAnalysesData
        .selectProject(this, strcProjectId));
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "C_BP_Group_ID",
          "", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportInvoiceCustomerDimensionalAnalyses"), Utility.getContext(this, vars,
              "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData,
          "ReportInvoiceCustomerDimensionalAnalyses", strPartnerGroup);
      xmlDocument.setData("reportC_BP_GROUPID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR",
          "M_Product_Category_ID", "", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportInvoiceCustomerDimensionalAnalyses"), Utility.getContext(this, vars,
              "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData,
          "ReportInvoiceCustomerDimensionalAnalyses", strProductCategory);
      xmlDocument.setData("reportM_PRODUCT_CATEGORYID", "liststructure", comboTableData
          .select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setData("reportAD_ORGID", "liststructure", OrganizationComboData.selectCombo(this,
        vars.getRole()));
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLE", "SalesRep_ID",
          "AD_User SalesRep", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportSalesDimensionalAnalyze"), Utility.getContext(this, vars, "#User_Client",
              "ReportSalesDimensionalAnalyze"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData,
          "ReportInvoiceCustomerDimensionalAnalyses", strsalesrepId);
      xmlDocument.setData("reportSalesRep_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setData("reportCBPartnerId_IN", "liststructure", SelectorUtilityData
        .selectBpartner(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility
            .getContext(this, vars, "#User_Client", ""), strcBpartnerId));
    xmlDocument.setData("reportMProductId_IN", "liststructure", SelectorUtilityData.selectMproduct(
        this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility.getContext(this,
            vars, "#User_Client", ""), strmProductId));

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "LIST", "",
          "M_Product_ProductType", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportInvoiceCustomerDimensionalAnalyses"), Utility.getContext(this, vars,
              "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData,
          "ReportInvoiceCustomerDimensionalAnalyses", "");
      xmlDocument.setData("reportProductType", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLE", "",
          "C_BPartner SalesRep", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "ReportInvoiceCustomerDimensionalAnalyses"), Utility.getContext(this, vars,
              "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData,
          "ReportInvoiceCustomerDimensionalAnalyses", strPartnerSalesrepId);
      xmlDocument
          .setData("reportPartnerSalesRep_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    if (vars.getLanguage().equals("en_US")) {
      xmlDocument.setData("structure1", ReportInvoiceCustomerDimensionalAnalysesData
          .selectNotShown(this, strShown));
      xmlDocument.setData("structure2",
          strShown.equals("") ? new ReportInvoiceCustomerDimensionalAnalysesData[0]
              : ReportInvoiceCustomerDimensionalAnalysesData.selectShown(this, strShown));
    } else {
      xmlDocument.setData("structure1", ReportInvoiceCustomerDimensionalAnalysesData
          .selectNotShownTrl(this, vars.getLanguage(), strShown));
      xmlDocument.setData("structure2",
          strShown.equals("") ? new ReportInvoiceCustomerDimensionalAnalysesData[0]
              : ReportInvoiceCustomerDimensionalAnalysesData.selectShownTrl(this, vars
                  .getLanguage(), strShown));
    }

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageHtml(HttpServletResponse response, VariablesSecureApp vars,
      String strComparative, String strDateFrom, String strDateTo, String strPartnerGroup,
      String strcBpartnerId, String strProductCategory, String strmProductId, String strNotShown,
      String strShown, String strDateFromRef, String strDateToRef, String strOrg,
      String strsalesrepId, String strcProjectId, String strProducttype, String strOrder,
      String strMayor, String strMenor, String strPartnerSalesrepId) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print html");
    XmlDocument xmlDocument = null;
    String strOrderby = "";
    String[] discard = { "", "", "", "", "", "", "", "", "", "" };
    String[] discard1 = { "selEliminarBody1", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard" };
    if (strComparative.equals("Y"))
      discard1[0] = "selEliminarBody2";
    String strTitle = "";
    strTitle = Utility.messageBD(this, "From", vars.getLanguage()) + " " + strDateFrom + " "
        + Utility.messageBD(this, "To", vars.getLanguage()) + " " + strDateTo;
    if (!strPartnerGroup.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "ForBPartnerGroup", vars.getLanguage())
          + " " + ReportInvoiceCustomerDimensionalAnalysesData.selectBpgroup(this, strPartnerGroup);

    if (!strProductCategory.equals(""))
      strTitle = strTitle
          + ", "
          + Utility.messageBD(this, "ProductCategory", vars.getLanguage())
          + " "
          + ReportInvoiceCustomerDimensionalAnalysesData.selectProductCategory(this,
              strProductCategory);
    if (!strcProjectId.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "Project", vars.getLanguage()) + " "
          + ReportInvoiceCustomerDimensionalAnalysesData.selectProject(this, strcProjectId);
    if (!strProducttype.equals(""))
      strTitle = strTitle
          + ", "
          + Utility.messageBD(this, "PRODUCTTYPE", vars.getLanguage())
          + " "
          + ReportInvoiceCustomerDimensionalAnalysesData.selectProducttype(this, "270", vars
              .getLanguage(), strProducttype);
    if (!strsalesrepId.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "TheClientSalesRep", vars.getLanguage())
          + " " + ReportInvoiceCustomerDimensionalAnalysesData.selectSalesrep(this, strsalesrepId);
    if (!strPartnerSalesrepId.equals(""))
      strTitle = strTitle + " " + Utility.messageBD(this, "And", vars.getLanguage()) + " "
          + Utility.messageBD(this, "TheClientSalesRep", vars.getLanguage()) + " "
          + ReportInvoiceCustomerDimensionalAnalysesData.selectSalesrep(this, strPartnerSalesrepId);

    ReportInvoiceCustomerDimensionalAnalysesData[] data = null;
    String[] strShownArray = { "", "", "", "", "", "", "", "", "", "" };
    if (strShown.startsWith("("))
      strShown = strShown.substring(1, strShown.length() - 1);
    if (!strShown.equals("")) {
      strShown = Replace.replace(strShown, "'", "");
      strShown = Replace.replace(strShown, " ", "");
      StringTokenizer st = new StringTokenizer(strShown, ",", false);
      int intContador = 0;
      while (st.hasMoreTokens()) {
        strShownArray[intContador] = st.nextToken();
        intContador++;
      }

    }
    String[] strTextShow = { "", "", "", "", "", "", "", "", "", "" };
    int intDiscard = 0;
    int intOrder = 0;
    int intAuxDiscard = -1;
    for (int i = 0; i < 10; i++) {
      if (strShownArray[i].equals("1")) {
        strTextShow[i] = "C_BP_GROUP.NAME";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("2")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER(to_char('C_Bpartner'), to_char( C_BPARTNER.C_BPARTNER_ID), to_char('"
            + vars.getLanguage() + "'))";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("3")) {
        strTextShow[i] = "M_PRODUCT_CATEGORY.NAME";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("4")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER(to_char('M_Product'), to_char( M_PRODUCT.M_PRODUCT_ID), to_char('"
            + vars.getLanguage() + "'))||' ('||UOMSYMBOL||')'";
        intAuxDiscard = i;
        intOrder++;
      } else if (strShownArray[i].equals("5")) {
        strTextShow[i] = "C_INVOICE.DOCUMENTNO";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("6")) {
        strTextShow[i] = "C_INVOICE.schedtransactiondate";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("8")) {
        strTextShow[i] = "C_PROJECT.NAME";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("9")) {
        strTextShow[i] = "AD_USER.FIRSTNAME||' '||' '||AD_USER.LASTNAME"
            + vars.getLanguage() + "'))";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("10")) {
        strTextShow[i] = "AD_ORG.NAME";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("11")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER(to_char('C_Bpartner_Location'), to_char( M_INOUT.C_BPARTNER_LOCATION_ID), to_char('"
            + vars.getLanguage() + "'))";
        intDiscard++;
        intOrder++;
      } else {
        strTextShow[i] = "''";
        discard[i] = "display:none;";
      }
    }
    if (intOrder != 0 || intAuxDiscard != -1) {
      int k = 1;
      if (intOrder == 1) {
        strOrderby = " ORDER BY NIVEL" + k + ",";
      } else {
        strOrderby = " ORDER BY ";
      }
      while (k < intOrder) {
        strOrderby = strOrderby + "NIVEL" + k + ",";
        k++;
      }
      if (k == 1) {
        if (strOrder.equals("Normal")) {
          strOrderby = " ORDER BY NIVEL" + k;
        } else if (strOrder.equals("Amountasc")) {
          strOrderby = " ORDER BY LINENETAMT ASC";
        } else if (strOrder.equals("Amountdesc")) {
          strOrderby = " ORDER BY LINENETAMT DESC";
        } else {
          strOrderby = "1";
        }
      } else {
        if (strOrder.equals("Normal")) {
          strOrderby += "NIVEL" + k;
        } else if (strOrder.equals("Amountasc")) {
          strOrderby += "LINENETAMT ASC";
        } else if (strOrder.equals("Amountdesc")) {
          strOrderby += "LINENETAMT DESC";
        } else {
          strOrderby = "1";
        }
      }

    } else {
      strOrderby = " ORDER BY 1";
    }
    String strHaving = "";
    if (!strMayor.equals("") && !strMenor.equals("")) {
      strHaving = " HAVING SUM(LINENETAMT) > " + strMayor + " AND SUM(LINENETAMT) < " + strMenor;
    } else if (!strMayor.equals("") && strMenor.equals("")) {
      strHaving = " HAVING SUM(LINENETAMT) > " + strMayor;
    } else if (strMayor.equals("") && !strMenor.equals("")) {
      strHaving = " HAVING SUM(LINENETAMT) < " + strMenor;
    } else {
      strHaving = " HAVING SUM(LINENETAMT) <> 0 OR SUM(LINENETREF) <> 0";
    }
    strOrderby = strHaving + strOrderby;
    if (strComparative.equals("Y")) {
      data = ReportInvoiceCustomerDimensionalAnalysesData.select(this, strTextShow[0],
          strTextShow[1], strTextShow[2], strTextShow[3], strTextShow[4], strTextShow[5],
          strTextShow[6], strTextShow[7], strTextShow[8], strTextShow[9], Tree.getMembers(this,
              TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility.getContext(this, vars,
              "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"), strDateFrom,
          DateTimeData.nDaysAfter(this, strDateTo, "1"), strPartnerGroup, strcBpartnerId,
          strProductCategory, strmProductId, strsalesrepId, strPartnerSalesrepId, strcProjectId,
          strProducttype, strDateFromRef, DateTimeData.nDaysAfter(this, strDateToRef, "1"),
          strOrderby);
    } else {
      data = ReportInvoiceCustomerDimensionalAnalysesData.selectNoComparative(this, strTextShow[0],
          strTextShow[1], strTextShow[2], strTextShow[3], strTextShow[4], strTextShow[5],
          strTextShow[6], strTextShow[7], strTextShow[8], strTextShow[9], Tree.getMembers(this,
              TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility.getContext(this, vars,
              "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"), strDateFrom,
          DateTimeData.nDaysAfter(this, strDateTo, "1"), strPartnerGroup, strcBpartnerId,
          strProductCategory, strmProductId, strsalesrepId, strPartnerSalesrepId, strcProjectId,
          strProducttype, strOrderby);
    }
    if (data.length == 0 || data == null) {
      // discard1[0] = "selEliminar1";
      data = ReportInvoiceCustomerDimensionalAnalysesData.set();
    } else {
      int contador = intDiscard;
      if (intAuxDiscard != -1)
        contador = intAuxDiscard;
      int k = 1;
      if (strComparative.equals("Y")) {
        for (int j = contador; j > 0; j--) {
          discard1[k] = "fieldTotalQtyNivel" + String.valueOf(j);
          discard1[k + 10] = "fieldTotalRefQtyNivel" + String.valueOf(j);
          discard1[k + 20] = "fieldTotalQty" + String.valueOf(j);
          // discard1[k+27] =
          // "fieldTotalWeightNivel"+String.valueOf(j);
          // discard1[k+36] =
          // "fieldTotalRefWeightNivel"+String.valueOf(j);
          // discard1[k+18] = "fieldUomsymbol"+String.valueOf(j);
          k++;
        }
      } else {
        for (int j = contador; j > 0; j--) {
          discard1[k] = "fieldNoncomparativeTotalQtyNivel" + String.valueOf(j);
          discard1[k + 20] = "fieldNoncomparativeTotalQty" + String.valueOf(j);
          // discard1[k+27] =
          // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(j);
          // discard1[k+18] =
          // "fieldNoncomparativeUomsymbol"+String.valueOf(j);
          k++;
        }
      }

    }
    xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_reports/ReportInvoiceCustomerDimensionalAnalysesEdition",
        discard1).createXmlDocument();
    xmlDocument.setParameter("eliminar2", discard[1]);
    xmlDocument.setParameter("eliminar3", discard[2]);
    xmlDocument.setParameter("eliminar4", discard[3]);
    xmlDocument.setParameter("eliminar5", discard[4]);
    xmlDocument.setParameter("eliminar6", discard[5]);
    xmlDocument.setParameter("eliminar7", discard[6]);
    xmlDocument.setParameter("eliminar8", discard[7]);
    xmlDocument.setParameter("eliminar9", discard[8]);
    xmlDocument.setParameter("eliminar10", discard[9]);
    xmlDocument.setParameter("total", ReportInvoiceCustomerDimensionalAnalysesData.selectTotal(
        this, Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility
            .getContext(this, vars, "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"),
        strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), strPartnerGroup,
        strcBpartnerId, strProductCategory, strmProductId, strsalesrepId, strPartnerSalesrepId,
        strcProjectId, strProducttype));
    xmlDocument.setParameter("title", strTitle);
    xmlDocument.setParameter("constante", "100");
    if (strComparative.equals("Y")) {
      xmlDocument.setData("structure1", data);
    } else {
      xmlDocument.setData("structure2", data);
    }

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet ReportInvoiceCustomerDimensionalAnalyses. This Servlet was made by Jon Alegría";
  } // end of getServletInfo() method
}
