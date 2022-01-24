/*
***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 */

package org.openbravo.erpCommon.ad_reports;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
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
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.erpCommon.utility.PreparedXmlWithWindowTabToolbar;
import org.openz.util.LocalizationUtils;
import org.openz.util.UtilsData;

public class ReportSalesDimensionalAnalyzeJR extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    // Get user Client's base currency
    String strUserCurrencyId = Utility.stringBaseCurrencyId(this, vars.getClient());
    // Get all the Vars for all kinds off Calls
    String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
        "ReportSalesDimensionalAnalyzeJR|dateFrom", "",this);
    String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo",
        "ReportSalesDimensionalAnalyzeJR|dateTo", "",this);
   
    String strPartnerGroup = vars.getStringParameter("inpPartnerGroup");
    //String strcBpartnerId = vars.getInGlobalVariable("inpcBPartnerId_IN",
    //    "ReportSalesDimensionalAnalyzeJR|partner", "", IsIDFilter.instance);
    String strcBpartnerId = vars.getInStringParameter("inpcBPartnerId_IN");
    
    String strProductCategory = vars.getStringParameter("inpProductCategory");
    String strmProductId = vars.getInStringParameter("inpmProductId_IN");
    String strcProjectId = vars.getInStringParameter("inpcProjectId_IN");
    String strmWarehouseId = vars.getStringParameter("inpmWarehouseId");
    // ad_ref_list.value for reference_id = 800087
    
    String strOrg = vars.getStringParameter("inpOrg");
    String strsalesrepId = vars.getStringParameter("inpSalesrepId");
    // Order By amount radio buttons
    String strOrder = vars.getGlobalVariable("inpOrder", "ReportSalesDimensionalAnalyzeJR|order","Normal");
    // Amount from amount to
    String strMayor = vars.getNumericGlobalVariable("inpMayor", "ReportSalesDimensionalAnalyzeJR|mayor", "");
    String strMenor = vars.getNumericGlobalVariable("inpMenor","ReportSalesDimensionalAnalyzeJR|menor", "");
    String strCurrencyId = vars.getGlobalVariable("inpCurrencyId", "ReportSalesDimensionalAnalyzeJR|currency", strUserCurrencyId);
    String strReportType = vars.getGlobalVariable("inpReportType", "ReportSalesDimensionalAnalyzeJR|inpEstInvoices","OrdersContracted");
    String strNotShown="";
    String strShown="";
    if (vars.commandIn("DEFAULT")) {
      strNotShown = vars.getInGlobalVariable("inpNotShown",
             "ReportSalesDimensionalAnalyzeJR|notShown", "", IsPositiveIntFilter.instance);
      strShown = vars.getInGlobalVariable("inpShown",
             "ReportSalesDimensionalAnalyzeJR|shown", "", IsPositiveIntFilter.instance);
    }
    else {
      strNotShown = vars.getInStringParameter("inpNotShown", IsPositiveIntFilter.instance);
      strShown = vars.getInStringParameter("inpShown", IsPositiveIntFilter.instance);
    }
    if (vars.commandIn("DEFAULT")) { 
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strPartnerGroup,strReportType,
          strcBpartnerId, strProductCategory, strmProductId, strmWarehouseId, strNotShown,
          strShown,  strOrg, strsalesrepId, strOrder, strMayor,
          strMenor,  strCurrencyId,strcProjectId);
    } else if (vars.commandIn("EDIT_HTML")) {
      
      try {
		printPageHtml(request, response, vars,  strDateFrom, strDateTo,strReportType,
		      strPartnerGroup, strcBpartnerId, strProductCategory, strmProductId, strmWarehouseId,
		      strNotShown, strShown,  strOrg, strsalesrepId, strOrder,
		      strMayor, strMenor,  strCurrencyId,strcProjectId, "html");
	} catch (Exception e) {
        if (log4j.isDebugEnabled())
            log4j.debug("JR: Error: " + e);
          e.printStackTrace();
		  throw new ServletException(e.getMessage(), e);

	}
    } else if (vars.commandIn("EDIT_PDF")) {
     
      try {
		printPageHtml(request, response, vars,  strDateFrom, strDateTo,strReportType,
		      strPartnerGroup, strcBpartnerId, strProductCategory, strmProductId, strmWarehouseId,
		      strNotShown, strShown, strOrg, strsalesrepId, strOrder,
		      strMayor, strMenor,  strCurrencyId,strcProjectId, "pdf");
	} catch (Exception e) {
        if (log4j.isDebugEnabled())
            log4j.debug("JR: Error: " + e);
          e.printStackTrace();
		  throw new ServletException(e.getMessage(), e);

	}
    } else if (vars.commandIn("EDIT_EXCEL")) {
      
      try {
		printPageHtml(request, response, vars,  strDateFrom, strDateTo,strReportType,
		      strPartnerGroup, strcBpartnerId, strProductCategory, strmProductId, strmWarehouseId,
		      strNotShown, strShown,  strOrg, strsalesrepId, strOrder,
		      strMayor, strMenor,  strCurrencyId,strcProjectId, "xls");
	} catch (Exception e) {
        if (log4j.isDebugEnabled())
            log4j.debug("JR: Error: " + e);
          e.printStackTrace();
		  throw new ServletException(e.getMessage(), e);

	}
    } else
      pageErrorPopUp(response);
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strPartnerGroup,String strReportType,
      String strcBpartnerId, String strProductCategory, String strmProductId,
      String strmWarehouseId, String strNotShown, String strShown,  String strOrg, String strsalesrepId, String strOrder, String strMayor,
      String strMenor,  String strCurrencyId,String strcProjectId) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    String discard[] = { "selEliminarHeader1" };
    
    try {
      // Prepare XML-Document generic
      //String url,String filename,String classname,String packagename, 
      //String discard[],VariablesSecureApp vars,String replacewith,ClassInfoData classinfo, 
      //ConnectionProvider conn, xmlengine)
      PreparedXmlWithWindowTabToolbar pwtd= new PreparedXmlWithWindowTabToolbar("org/openbravo/erpCommon/ad_reports/ReportSalesDimensionalAnalyzeJRFilter",
                                    "ReportSalesDimensionalAnalyzeJRFilter.html","org.openbravo.erpCommon.ad_reports.ReportSalesDimensionalAnalyzeJR",
                                    "ad_reports",discard,vars,strReplaceWith,classInfo,this,xmlEngine);
      XmlDocument xmlDocument=pwtd.getxmlDocument();
   
    
    
    
    // Fill Form-Specific discrete Parameters
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));

    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));

    xmlDocument.setParameter("dateFromRefdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromRefsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));

    xmlDocument.setParameter("dateToRefdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateToRefsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    
    xmlDocument.setParameter("dateTo", strDateTo);
    xmlDocument.setParameter("dateFrom", strDateFrom);
    xmlDocument.setParameter("mWarehouseId", strmWarehouseId);
    xmlDocument.setParameter("salesRepId", strsalesrepId);
    xmlDocument.setParameter("cBpGroupId", strPartnerGroup);
    xmlDocument.setParameter("mProductCategoryId", strProductCategory);
    xmlDocument.setParameter("adOrgId", strOrg);
    xmlDocument.setParameter("normal", strOrder);
    xmlDocument.setParameter("amountasc", strOrder);
    xmlDocument.setParameter("amountdesc", strOrder);
    xmlDocument.setParameter("mayor", strMayor);
    xmlDocument.setParameter("menor", strMenor);
    // Report Type Radio Button Group
    xmlDocument.setParameter("paramOrdersContracted", strReportType);
    xmlDocument.setParameter("paramEstInvoice", strReportType);
    xmlDocument.setParameter("paramProjectMargins", strReportType);
    xmlDocument.setParameter("paramOffersOpen", strReportType);
    xmlDocument.setParameter("paramOffersOpenEI", strReportType);
    xmlDocument.setParameter("paramOffersLost", strReportType);
    
    xmlDocument.setParameter("ccurrencyid", strCurrencyId);

    // Fill Combo Boxes
    // Sales Representative (table-reference access)
    ComboTableDataWrapper comboTableData = new ComboTableDataWrapper(this, vars, "AD_User all Sales Rep", null,"ReportSalesDimensionalAnalyzeJR", strsalesrepId,null);
    xmlDocument.setData("reportSalesRep_ID", "liststructure", comboTableData.select(false));
    // Warehouse (direct Table access)
    comboTableData = new ComboTableDataWrapper(this, vars, "M_Warehouse_ID", null,"ReportSalesDimensionalAnalyzeJR", strmWarehouseId,"",null);
    xmlDocument.setData("reportM_WAREHOUSEID", "liststructure", comboTableData.select(false));
    // Business-Partner Group (direct Table access)
    comboTableData = new ComboTableDataWrapper(this, vars, "C_BP_Group_ID", null,"ReportSalesDimensionalAnalyzeJR", strPartnerGroup,"",null);
    xmlDocument.setData("reportC_BP_GROUPID", "liststructure", comboTableData.select(false));
    
    comboTableData = new ComboTableDataWrapper(this, vars, "M_Product_Category_ID", null,"ReportSalesDimensionalAnalyzeJR", strProductCategory,"",null);
    xmlDocument.setData("reportM_PRODUCT_CATEGORYID", "liststructure", comboTableData.select(false));
   
    comboTableData = new ComboTableDataWrapper(this, vars, "C_Currency_ID", null,"ReportSalesDimensionalAnalyzeJR", strCurrencyId,"",null);
    xmlDocument.setData("reportC_Currency_ID", "liststructure", comboTableData.select(false));
    // Combo Directly filled from a query
    xmlDocument.setData("reportAD_ORGID", "liststructure", OrganizationComboData.selectCombo(this,
        vars.getRole()));
    
    // Fill Selectors
    xmlDocument.setData("reportCBPartnerId_IN", "liststructure", SelectorUtilityData.selectBpartner(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility
            .getContext(this, vars, "#User_Client", ""), strcBpartnerId));
    
    xmlDocument.setData("reportMProductId_IN", "liststructure", SelectorUtilityData.selectMproduct(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility.getContext(this,
            vars, "#User_Client", ""), strmProductId));
    
    xmlDocument.setData("reportCProjectId_IN", "liststructure", SelectorUtilityData.selectProject(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility.getContext(this,
        vars, "#User_Client", ""), strcProjectId));
    
    // Fill dimensions Selector  
    xmlDocument.setData("structure1", ReportSalesDimensionalAnalyzeJRData.selectNotShown(this,vars.getLanguage(), strShown));
    
    xmlDocument.setData("structure2",strShown.equals("") ? new ReportSalesDimensionalAnalyzeJRData[0]: ReportSalesDimensionalAnalyzeJRData.selectShown(this, vars.getLanguage(),strShown));


    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
    } catch (Exception ex) {
        if (log4j.isDebugEnabled())
            log4j.debug("JR: Error: " + ex);
          ex.printStackTrace();
		  throw new ServletException(ex.getMessage(), ex);

	
    }
  }

  private void printPageHtml(HttpServletRequest request, HttpServletResponse response,
      VariablesSecureApp vars,  String strDateFrom, String strDateTo,String strReportType,
      String strPartnerGroup, String strcBpartnerId, String strProductCategory,
      String strmProductId, String strmWarehouseId, String strNotShown, String strShown,
      String strOrg, String strsalesrepId,
      String strOrder, String strMayor, String strMenor, 
      String strCurrencyId,String strcProjectId, String strOutput) throws Exception {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print html");
    String strOrderby = "";
    String[] discard = { "", "", "", "", "", "", "", "", "" };
   
    if (strOrg.equals(""))
      strOrg = vars.getOrg();
   
    String strTitle = "";
    strTitle = Utility.messageBD(this, "From", vars.getLanguage()) + " " + UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")) + " "
        + Utility.messageBD(this, "To", vars.getLanguage()) + " " + UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat"));
    if (!strPartnerGroup.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "ForBPartnerGroup", vars.getLanguage())
          + " " + ReportSalesDimensionalAnalyzeJRData.selectBpgroup(this, strPartnerGroup);
    if (!strProductCategory.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "ProductCategory", vars.getLanguage())
          + " "
          + ReportSalesDimensionalAnalyzeJRData.selectProductCategory(this, strProductCategory);
    if (!strsalesrepId.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "TheSalesRep", vars.getLanguage()) + " "
          + ReportSalesDimensionalAnalyzeJRData.selectSalesrep(this, strsalesrepId);
    
    if (!strmWarehouseId.equals(""))
      strTitle = strTitle + " " + Utility.messageBD(this, "And", vars.getLanguage()) + " "
          + Utility.messageBD(this, "TheWarehouse", vars.getLanguage()) + " "
          + ReportSalesDimensionalAnalyzeJRData.selectMwarehouse(this, strmWarehouseId);

    ReportSalesDimensionalAnalyzeJRData[] data = null;
    String[] strShownArray = { "", "", "", "", "", "", "", "", "" };
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
    ReportSalesDimensionalAnalyzeJRData[] dimensionLabel = null;
   
    dimensionLabel = ReportSalesDimensionalAnalyzeJRData.selectNotShown(this, vars.getLanguage(), "");

    String[] strLevelLabel = { "", "", "", "", "", "", "", "", "" };
    String[] strTextShow = { "", "", "", "", "", "", "", "", "" };
    strOrderby = " ORDER BY ";
    int intProductLevel = 10;
    int intOrderLevel =10;
    int intProjectLevel =10;
    int intDiscard = 0;
    for (int i = 0; i < 9; i++) {
      if (strOrder.equals("Amountasc") && i==0)
         strOrderby +=  " ROW1, ";
      if (strOrder.equals("Amountdesc") && i==0)
         strOrderby += " ROW1 desc, ";      
      if (strShownArray[i].equals("1")) {
        strTextShow[i] = "C_BP_GROUP.NAME";
        strLevelLabel[i] = dimensionLabel[0].name;
        strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
        intDiscard++;
      } else if (strShownArray[i].equals("2")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER(to_char('C_Bpartner'), to_char( C_BPARTNER.C_BPARTNER_ID), to_char('"
            + vars.getLanguage() + "'))||'-'||C_BPARTNER.value";
        strLevelLabel[i] = dimensionLabel[1].name;
        strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
        intDiscard++;
      } else if (strShownArray[i].equals("3")) {
        if (!strReportType.equals("ProjectMargins")){
          strTextShow[i] = "M_PRODUCT_CATEGORY.NAME";
          strLevelLabel[i] = dimensionLabel[2].name;
          strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
          intDiscard++;
        } else
        {
          strLevelLabel[i] = "";
          strTextShow[i] = "to_char('')";
          strOrderby += i==0 ? "1" : "," + "1";
          intDiscard++;
        }
      } else if (strShownArray[i].equals("4")) {
        if (!strReportType.equals("ProjectMargins")){
          strTextShow[i] = "AD_COLUMN_IDENTIFIER(to_char('M_Product'), to_char( M_PRODUCT.M_PRODUCT_ID), to_char('"
              + vars.getLanguage() + "'))||' ('||zssi_getuom(C_ORDERLINE.C_UOM_ID,'" + vars.getLanguage() + "')||')'";
          intProductLevel = i + 1;
          strLevelLabel[i] = dimensionLabel[3].name;
          strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
          intDiscard++;
        } else {
          strLevelLabel[i] = "";
          strTextShow[i] = "to_char('')";
          strOrderby += i==0 ? "1" : "," + "1";
          intDiscard++;
        }
      } else if (strShownArray[i].equals("5")) {
        if (strReportType.equals("OffersLost"))
          strTextShow[i] = "C_ORDER.DOCUMENTNO||'-'||coalesce(C_ORDER.NAME,'')||'-:'||zssi_getListRefText('B51F770E9FA84F5B8FC0FFD7B3848317',C_ORDER.lostproposalfixedreason,'" + vars.getLanguage() + "')||'. Chance war: '||coalesce(C_ORDER.estpropability,'0')||'% zum '||coalesce(to_char(C_ORDER.datepromised),'')";
        else if (strReportType.equals("OffersOpen"))
          strTextShow[i] = "C_ORDER.DOCUMENTNO||'-'||coalesce(C_ORDER.NAME,'')||'- Chance: '||coalesce(C_ORDER.estpropability,'0')||'% zum '||coalesce(to_char(C_ORDER.datepromised),'')";
        else
          strTextShow[i] = "C_ORDER.DOCUMENTNO||'-'||coalesce(C_ORDER.NAME,'')||'- zum: '||coalesce(to_char(C_ORDER.datepromised),'')";
        intOrderLevel= i + 1;
        strLevelLabel[i] = dimensionLabel[4].name;
        strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
        intDiscard++;
      } else if (strShownArray[i].equals("6")) {
        strTextShow[i] = "coalesce(to_char(C_ORDER.datepromised),'')";
        strLevelLabel[i] = dimensionLabel[5].name;
        strOrderby += i==0 ? "to_date(NIVEL" + String.valueOf(i+1) + ")" : "," + "to_date(NIVEL" + String.valueOf(i+1) + ")";
        intDiscard++;
      } else if (strShownArray[i].equals("7")) {
        strTextShow[i] = "M_WAREHOUSE.NAME";
        strLevelLabel[i] = dimensionLabel[6].name;
        strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
        intDiscard++;
      } else if (strShownArray[i].equals("8")) {
        strTextShow[i] = "C_PROJECT.value||'-'||C_PROJECT.NAME";
        strLevelLabel[i] = dimensionLabel[7].name;
        intProjectLevel= i + 1;
        strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
        intDiscard++;
      } else if (strShownArray[i].equals("9")) {
        strTextShow[i] = "AD_USER.NAME";
        strLevelLabel[i] = dimensionLabel[8].name;
        strOrderby += i==0 ? "NIVEL" + String.valueOf(i+1) : "," + "NIVEL" + String.valueOf(i+1);
        intDiscard++;
      } else {
        strTextShow[i] = "''";
        discard[i] = "display:none;";
      }
    }
    
    String strAmtColumn="";;
    String daterangeorder="" ;
    String report_title="";
    if (strReportType.equals("OrdersContracted")){
      daterangeorder = "C_ORDER.DOCSTATUS in ('CO') AND C_ORDER.dateordered >= to_date('" +  strDateFrom + "') and C_ORDER.dateordered <= to_date('" +  strDateTo + "')";
      report_title ="Dimensionsanalyse Verkauf: Auftragsbestand nach Auftragsdatum";
      strAmtColumn="AMOUNT";
    }      
    else if (strReportType.equals("EstInvoice")){
      daterangeorder = "C_ORDER.DOCSTATUS in ('CO') ";
      report_title ="Auftragsbestand nach vorraussichtlichem Rechnungsdatum";
      strAmtColumn="estinvamount";
    }
    else if (strReportType.equals("ProjectMargins")){
      daterangeorder = "coalesce(C_PROJECT.startdate,'infinity'::date) >= to_date('" +  strDateFrom + "') and coalesce(C_PROJECT.startdate,'-infinity'::date) <= to_date('" +  strDateTo + "')";
      report_title ="Dimensionsanalyse Projekte und Margen";
      strAmtColumn="projectrevenue";
    }
    else if (strReportType.equals("OffersOpen")){
      daterangeorder = "case c_order.proposalstatus when 'OP' then (c_order.docstatus='CO' and c_isofferrelevant(c_order.c_order_id)='Y') " +
      		"                                   when 'AC' then (c_order.docstatus='CL' and c_order.updated >= to_date('" +  strDateTo + "')) "+
      		"                                   when 'LO' then (c_order.docstatus='CL' and c_order.updated >= to_date('" +  strDateTo + "') and c_isofferrelevant (c_order.c_order_id)='Y') "+
                       "else  (1=0)  end  and " +
                       "C_ORDER.dateordered >= to_date('" +  strDateFrom + "') and C_ORDER.dateordered <= to_date('" +  strDateTo + "')";
      report_title ="Offene Angebote";
      strAmtColumn="AMOUNT";
    }
    else if (strReportType.equals("OffersOpenEI")){
      daterangeorder = "case c_order.proposalstatus when 'OP' then (c_order.docstatus='CO' and c_isofferrelevant(c_order.c_order_id)='Y') " +
                "                                   when 'AC' then (c_order.docstatus='CL' and c_order.updated >= to_date('" +  strDateTo + "')) "+
                "                                   when 'LO' then (c_order.docstatus='CL' and c_order.updated >= to_date('" +  strDateTo + "') and c_isofferrelevant(c_order.c_order_id)='Y') "+
                       "else  (1=0)  end  and " +
                       "coalesce(C_ORDERLINE.datepromised,'infinity'::date) >= to_date('" +  strDateFrom + "') and coalesce(C_ORDERLINE.datepromised,'-infinity'::date) <= to_date('" +  strDateTo + "')";
      report_title ="Offene Angebote nach vorraussichtlichem Rechnungsdatum";
      strAmtColumn="AMOUNT";
    }
    else if (strReportType.equals("OffersLost")){
      daterangeorder = "C_ORDER.DOCSTATUS in ('CL') AND c_order.proposalstatus='LO' AND C_ORDER.dateordered >= to_date('" +  strDateFrom + "') and C_ORDER.dateordered <= to_date('" +  strDateTo + "')";
      report_title ="Dimensionsanalyse verlorene Angebote";
      strAmtColumn="AMOUNT";
    }
    String strHaving = "";
    if (!strMayor.equals("") && !strMenor.equals("")) {
      strHaving = " HAVING (SUM("+strAmtColumn+") > " + strMayor + " AND SUM("+strAmtColumn+") < " + strMenor
          + ")";
    } else if (!strMayor.equals("") && strMenor.equals("")) {
      strHaving = " HAVING (SUM("+strAmtColumn+") > " + strMayor + ")";
    } else if (strMayor.equals("") && !strMenor.equals("")) {
      strHaving = " HAVING (SUM("+strAmtColumn+") < " + strMenor + ")";
    } else {
      strHaving = " HAVING (SUM("+strAmtColumn+") <> 0)";
    }
    strOrderby = strHaving + strOrderby;
    // Checks if there is a conversion rate for each of the transactions of
    // the report
    String strConvRateErrorMsg = "";
    OBError myMessage = null;
    myMessage = new OBError();
    String strReportPath="";
    if (strLevelLabel[0].equals(""))
      throw new ServletException("@NeedtoSelectDimension@");
    HashMap<String, Object> parameters = new HashMap<String, Object>();
        try {
          if (strReportType.equals("OrdersContracted")||strReportType.equals("EstInvoice")){
            strReportPath = "@basedesign@/org/openbravo/erpCommon/ad_reports/DimensionalReport4Rows.jrxml";
            data = ReportSalesDimensionalAnalyzeJRData.selectOrder(this, strCurrencyId,
                  strTextShow[0], strTextShow[1], strTextShow[2], strTextShow[3], strTextShow[4],
                  strTextShow[5], strTextShow[6], strTextShow[7], strTextShow[8], strDateFrom,strDateTo,daterangeorder,Tree.getMembers(this,
                      TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility.getContext(this,
                      vars, "#User_Client", "ReportSalesDimensionalAnalyzeJR"),  strPartnerGroup, strcBpartnerId,
                  strProductCategory, strmProductId, strmWarehouseId, strsalesrepId,strcProjectId,
                  strOrderby);
            parameters.put("ROW1_HEADER", LocalizationUtils.getElementTextByElementName(this, "Auftragswert", vars.getLanguage()));
            parameters.put("ROW2_HEADER", LocalizationUtils.getElementTextByElementName(this, "Vorauss. Rech.", vars.getLanguage()));
            parameters.put("ROW3_HEADER", LocalizationUtils.getElementTextByElementName(this, "Tats. Rechnung", vars.getLanguage()));
            parameters.put("ROW4_HEADER", LocalizationUtils.getElementTextByElementName(this, "Menge", vars.getLanguage()));
            parameters.put("ROW1_LEVEL", Integer.valueOf(intOrderLevel));
            parameters.put("ROW2_LEVEL", Integer.valueOf(intOrderLevel));
            parameters.put("ROW3_LEVEL", Integer.valueOf(intOrderLevel));
            parameters.put("ROW4_LEVEL", Integer.valueOf(intProductLevel));
            parameters.put("ISROW4AVERAGE","N");
          } 
          if (strReportType.equals("OffersOpen")||strReportType.equals("OffersLost")||strReportType.equals("OffersOpenEI")){
            strReportPath = "@basedesign@/org/openbravo/erpCommon/ad_reports/DimensionalReport3Rows.jrxml";
            data = ReportSalesDimensionalAnalyzeJRData.selectOffer(this, strCurrencyId,
                strTextShow[0], strTextShow[1], strTextShow[2], strTextShow[3], strTextShow[4],
                strTextShow[5], strTextShow[6], strTextShow[7], strTextShow[8], strDateFrom,strDateTo,strReportType.startsWith("OffersOpen")?new String("OP"):new String("LO"),daterangeorder,Tree.getMembers(this,
                    TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility.getContext(this,
                    vars, "#User_Client", "ReportSalesDimensionalAnalyzeJR"),  strPartnerGroup, strcBpartnerId,
                strProductCategory, strmProductId, strmWarehouseId, strsalesrepId,strcProjectId,
                strOrderby);
            parameters.put("ROW1_HEADER",LocalizationUtils.getElementTextByElementName(this, "Angebotswert", vars.getLanguage()));
            parameters.put("ROW2_HEADER", LocalizationUtils.getElementTextByElementName(this, "Chance Wert", vars.getLanguage()));
            parameters.put("ROW4_HEADER", LocalizationUtils.getElementTextByElementName(this, "Menge", vars.getLanguage()));
            parameters.put("ROW1_LEVEL", Integer.valueOf(intOrderLevel));
            parameters.put("ROW2_LEVEL", Integer.valueOf(intOrderLevel));
            parameters.put("ROW3_LEVEL", Integer.valueOf(intOrderLevel));
            parameters.put("ROW4_LEVEL", Integer.valueOf(intProductLevel));
            parameters.put("ISROW4AVERAGE","N");
          } 
          if (strReportType.equals("ProjectMargins")) {
            strReportPath = "@basedesign@/org/openbravo/erpCommon/ad_reports/DimensionalReport4Rows.jrxml";
            data = ReportSalesDimensionalAnalyzeJRData.selectProject(this, strCurrencyId,strDateFrom,strDateTo,
              strTextShow[0], strTextShow[1], strTextShow[2], strTextShow[3], strTextShow[4],
              strTextShow[5], strTextShow[6], strTextShow[7], strTextShow[8], daterangeorder,Tree.getMembers(this,
                  TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility.getContext(this,
                  vars, "#User_Client", "ReportSalesDimensionalAnalyzeJR"),  strPartnerGroup, strcBpartnerId,
              strmWarehouseId, strsalesrepId,strcProjectId,
              strOrderby);
            parameters.put("ROW1_HEADER", LocalizationUtils.getElementTextByElementName(this, "Auftragswert", vars.getLanguage()));
            parameters.put("ROW2_HEADER", LocalizationUtils.getElementTextByElementName(this, "Tats. Rechnung", vars.getLanguage()));
            parameters.put("ROW3_HEADER", LocalizationUtils.getElementTextByElementName(this, "Gesamtkosten", vars.getLanguage()));
            parameters.put("ROW4_HEADER", LocalizationUtils.getElementTextByElementName(this, "% Marge" , vars.getLanguage()));
            parameters.put("ROW1_LEVEL", Integer.valueOf(intOrderLevel));
            parameters.put("ROW2_LEVEL", Integer.valueOf(intProjectLevel));
            parameters.put("ROW3_LEVEL", Integer.valueOf(intProjectLevel));
            parameters.put("ROW4_LEVEL", Integer.valueOf(intProjectLevel));
            parameters.put("ISROW4AVERAGE","Y");
          }
        } catch (ServletException ex) {
          myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
          if (log4j.isDebugEnabled())
              log4j.debug("JR: Error: " + ex);
            ex.printStackTrace();
  		  throw new ServletException(ex.getMessage(), ex);

  	
        }
    

    strConvRateErrorMsg = myMessage.getMessage();
    // If a conversion rate is missing for a certain transaction, an error
    // message window pops-up.
    if (!strConvRateErrorMsg.equals("") && strConvRateErrorMsg != null) {
      advisePopUp(request, response, "ERROR",myMessage.getTitle() ,myMessage.getMessage() );
    } else { // Otherwise, the report is launched
      
      
      


      if (data == null) {
        data = ReportSalesDimensionalAnalyzeJRData.set();
        strReportPath = "@basedesign@/org/openbravo/erpCommon/ad_reports/DimensionalReport4Rows.jrxml";
      }
      
      parameters.put("LEVEL1_LABEL", strLevelLabel[0]);
      parameters.put("LEVEL2_LABEL", strLevelLabel[1]);
      parameters.put("LEVEL3_LABEL", strLevelLabel[2]);
      parameters.put("LEVEL4_LABEL", strLevelLabel[3]);
      parameters.put("LEVEL5_LABEL", strLevelLabel[4]);
      parameters.put("LEVEL6_LABEL", strLevelLabel[5]);
      parameters.put("LEVEL7_LABEL", strLevelLabel[6]);
      parameters.put("LEVEL8_LABEL", strLevelLabel[7]);
      parameters.put("LEVEL9_LABEL", strLevelLabel[8]);
      parameters.put("DIMENSIONS", Integer.valueOf(intDiscard));
      parameters.put("REPORT_SUBTITLE", strTitle);
      String strRepTitle=LocalizationUtils.getElementTextByElementName(this, "Report Sales Dimensional Analyses", vars.getLanguage());
      parameters.put("REPORT_TITLE", strRepTitle);
      
      
      renderJR(vars, response, strReportPath, strOutput, parameters, data, null);
          }
  }

  public String getServletInfo() {
    return "Servlet ReportSalesDimensionalAnalyzeJR.";
  } // end of getServletInfo() method
}
