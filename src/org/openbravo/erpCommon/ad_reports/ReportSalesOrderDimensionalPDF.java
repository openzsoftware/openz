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
import java.util.StringTokenizer;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.filter.IsPositiveIntFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.TreeData;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;

public class ReportSalesOrderDimensionalPDF extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strDateFrom = vars.getRequestGlobalVariable("inpDateFrom",
          "ReportSalesDimensionalAnalyses|dateFrom");
      String strDateTo = vars.getRequestGlobalVariable("inpDateTo",
          "ReportSalesDimensionalAnalyses|dateTo");
      String strDateFromRef = vars.getRequestGlobalVariable("inpDateFromRef",
          "ReportSalesDimensionalAnalyses|dateFromRef");
      String strDateToRef = vars.getRequestGlobalVariable("inpDateToRef",
          "ReportSalesDimensionalAnalyses|dateToRef");
      String strPartnerGroup = vars.getRequestGlobalVariable("inpPartnerGroup",
          "ReportSalesDimensionalAnalyses|partnerGroup");
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportSalesDimensionalAnalyses|partner", IsIDFilter.instance);
      String strProductCategory = vars.getRequestGlobalVariable("inpProductCategory",
          "ReportSalesDimensionalAnalyses|productCategory");
      String strmProductId = vars.getRequestInGlobalVariable("inpmProductId_IN",
          "ReportSalesDimensionalAnalyses|product", IsIDFilter.instance);
      String strmWarehouseId = vars.getRequestGlobalVariable("inpmWarehouseId",
          "ReportSalesDimensionalAnalyze|warehouse");
      // hardcoded to numeric in switch in the code
      String strNotShown = vars.getInStringParameter("inpNotShown", IsPositiveIntFilter.instance);
      String strShown = vars.getInStringParameter("inpShown", IsPositiveIntFilter.instance);
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportSalesDimensionalAnalyses|org", "0");
      String strsalesrepId = vars.getRequestGlobalVariable("inpSalesrepId",
          "ReportSalesDimensionalAnalyses|salesrep");
      String strOrder = vars.getRequestGlobalVariable("inpOrder",
          "ReportSalesDimensionalAnalyze|order");
      String strMayor = vars.getStringParameter("inpMayor", "");
      String strMenor = vars.getStringParameter("inpMenor", "");
      String strComparative = vars.getStringParameter("inpComparative", "N");
      String strPartnerSalesrepId = vars.getRequestGlobalVariable("inpPartnerSalesrepId",
          "ReportSalesDimensionalAnalyses|partnersalesrep");
      printPagePdf(response, vars, strComparative, strDateFrom, strDateTo, strPartnerGroup,
          strcBpartnerId, strProductCategory, strmProductId, strmWarehouseId, strNotShown,
          strShown, strDateFromRef, strDateToRef, strOrg, strsalesrepId, strOrder, strMayor,
          strMenor, strPartnerSalesrepId);
    } else
      pageErrorPopUp(response);
  }

  private void printPagePdf(HttpServletResponse response, VariablesSecureApp vars,
      String strComparative, String strDateFrom, String strDateTo, String strPartnerGroup,
      String strcBpartnerId, String strProductCategory, String strmProductId,
      String strmWarehouseId, String strNotShown, String strShown, String strDateFromRef,
      String strDateToRef, String strOrg, String strsalesrepId, String strOrder, String strMayor,
      String strMenor, String strPartnerSalesrepId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print html");
    XmlDocument xmlDocument = null;
    String strOrderby = "";
    String strPage = "basicPSMSecond";
    String[] discard = { "", "", "", "", "", "", "", "", "" };
    String[] discard1 = { "selEliminarBody1", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard", "discard", "discard", "discard", "discard", "discard",
        "discard", "discard", "discard" };
    if (strComparative.equals("Y")) {
      discard1[0] = "selEliminarBody2";
      strPage = "basicPSM";
    }
    String strTitle = "";
    strTitle = Utility.messageBD(this, "From", vars.getLanguage()) + " " + strDateFrom + " "
        + Utility.messageBD(this, "To", vars.getLanguage()) + " " + strDateTo;
    if (!strPartnerGroup.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "ForBPartnerGroup", vars.getLanguage())
          + " " + ReportSalesDimensionalAnalyzeData.selectBpgroup(this, strPartnerGroup);
    if (!strProductCategory.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "ProductCategory", vars.getLanguage())
          + " " + ReportSalesDimensionalAnalyzeData.selectProductCategory(this, strProductCategory);
    if (!strsalesrepId.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "TheSalesRep", vars.getLanguage()) + " "
          + ReportSalesDimensionalAnalyzeData.selectSalesrep(this, strsalesrepId);
    if (!strPartnerSalesrepId.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "TheClientSalesRep", vars.getLanguage())
          + " " + ReportSalesDimensionalAnalyzeData.selectSalesrep(this, strPartnerSalesrepId);
    if (!strmWarehouseId.equals(""))
      strTitle = strTitle + " " + Utility.messageBD(this, "And", vars.getLanguage()) + " "
          + Utility.messageBD(this, "TheWarehouse", vars.getLanguage()) + " "
          + ReportSalesDimensionalAnalyzeData.selectMwarehouse(this, strmWarehouseId);

    ReportSalesDimensionalAnalyzeData[] data = null;
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
    String[] strTextShow = { "", "", "", "", "", "", "", "", "" };
    int intDiscard = 0;
    int intAuxDiscard = -1;
    String strEliminateQty = " ";
    String strEliminateQtyRef = " ";
    String strEliminateQtyAvg = " ";
    // String strEliminateWeight = " ";
    // String strEliminateWeightRef = " ";
    for (int i = 0; i < 9; i++) {
      if (strShownArray[i].equals("1")) {
        strTextShow[i] = "C_BP_GROUP.NAME";
        intDiscard++;
      } else if (strShownArray[i].equals("2")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER('C_Bpartner', TO_CHAR(C_BPARTNER.C_BPARTNER_ID), '"
            + vars.getLanguage() + "')";
        intDiscard++;
      } else if (strShownArray[i].equals("3")) {
        strTextShow[i] = "M_PRODUCT_CATEGORY.NAME";
        intDiscard++;
      } else if (strShownArray[i].equals("4")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER('M_Product', TO_CHAR(M_PRODUCT.M_PRODUCT_ID), '"
            + vars.getLanguage() + "')";
        strEliminateQty = "Cantidad";
        strEliminateQtyRef = "Cantidad ref";
        strEliminateQtyAvg = "%cantidad";

        intAuxDiscard = i;
      } else if (strShownArray[i].equals("5")) {
        strTextShow[i] = "C_ORDER.DOCUMENTNO";
        intDiscard++;
      } else if (strShownArray[i].equals("6")) {
        strTextShow[i] = "AD_USER.FIRSTNAME||' '||' '||AD_USER.LASTNAME";
        intDiscard++;
      } else if (strShownArray[i].equals("7")) {
        strTextShow[i] = "M_WAREHOUSE.NAME";
        intDiscard++;
      } else if (strShownArray[i].equals("8")) {
        strTextShow[i] = "AD_ORG.NAME";
        intDiscard++;
      } else if (strShownArray[i].equals("9")) {
        strTextShow[i] = "CB.NAME";
        intDiscard++;
      } else {
        strTextShow[i] = "''";
        discard[i] = "0.1";
      }
    }
    if (intDiscard != 0 || intAuxDiscard != -1) {
      int k = 1;
      if (intDiscard == 1) {
        strOrderby = " ORDER BY NIVEL" + k + ",";
      } else {
        strOrderby = " ORDER BY ";
      }
      while (k < intDiscard) {
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
      data = ReportSalesDimensionalAnalyzeData.select(this, strTextShow[0], strTextShow[1],
          strTextShow[2], strTextShow[3], strTextShow[4], strTextShow[5], strTextShow[6],
          strTextShow[7], strTextShow[8], Tree.getMembers(this, TreeData.getTreeOrg(this, vars
              .getClient()), strOrg), Utility.getContext(this, vars, "#User_Client",
              "ReportSalesDimensionalAnalyze"), strDateFrom, DateTimeData.nDaysAfter(this,
              strDateTo, "1"), strPartnerGroup, strcBpartnerId, strProductCategory, strmProductId,
          strmWarehouseId, strsalesrepId, strPartnerSalesrepId, strDateFromRef, DateTimeData
              .nDaysAfter(this, strDateToRef, "1"), strOrderby);
    } else {
      data = ReportSalesDimensionalAnalyzeData.selectNoComparative(this, strTextShow[0],
          strTextShow[1], strTextShow[2], strTextShow[3], strTextShow[4], strTextShow[5],
          strTextShow[6], strTextShow[7], strTextShow[8], Tree.getMembers(this, TreeData
              .getTreeOrg(this, vars.getClient()), strOrg), Utility.getContext(this, vars,
              "#User_Client", "ReportSalesDimensionalAnalyze"), strDateFrom, DateTimeData
              .nDaysAfter(this, strDateTo, "1"), strPartnerGroup, strcBpartnerId,
          strProductCategory, strmProductId, strmWarehouseId, strsalesrepId, strPartnerSalesrepId,
          strOrderby);
    }
    if (data.length == 0 || data == null) {

      data = ReportSalesDimensionalAnalyzeData.set();
    } else {
      int contador = intDiscard;
      if (intAuxDiscard == -1) {
        if (strComparative.equals("Y")) {
          for (int j = 1; j < 10; j++) {
            discard1[j] = "fieldTotalQtyNivel" + String.valueOf(j);
            discard1[j + 9] = "fieldTotalRefQtyNivel" + String.valueOf(j);
            discard1[j + 18] = "fieldTotalQty" + String.valueOf(j);
            discard1[j + 27] = "fieldUomsymbol" + String.valueOf(j);
            // discard1[j+36] =
            // "fieldTotalWeightNivel"+String.valueOf(j);
            // discard1[j+45] =
            // "fieldTotalRefWeightNivel"+String.valueOf(j);
          }
          int count = 7;
          while (count > contador) {
            discard1[count + 54] = "fieldTotalNivel" + String.valueOf(count);
            discard1[count + 63] = "fieldTotalRefNivel" + String.valueOf(count);
            discard1[count + 72] = "fieldTotal" + String.valueOf(count);
            // discard1[count+81] =
            // "fieldTotalWeightNivel"+String.valueOf(count);
            // discard1[count+90] =
            // "fieldTotalRefWeightNivel"+String.valueOf(count);
            count--;
          }
        } else {
          for (int j = 1; j < 10; j++) {
            discard1[j] = "fieldNoncomparativeTotalQtyNivel" + String.valueOf(j);
            discard1[j + 27] = "fieldNoncomparativeUomsymbol" + String.valueOf(j);
            // discard1[j+36] =
            // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(j);
          }
          int count = 9;
          while (count > contador) {
            discard1[count + 45] = "fieldNoncomparativeTotalNivel" + String.valueOf(count);
            // discard1[count+54] =
            // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(count);
            count--;
          }
        }

      } else {
        contador = intAuxDiscard;
        int k = 1;
        if (strComparative.equals("Y")) {
          for (int j = contador; j > 0; j--) {
            discard1[k] = "fieldTotalQtyNivel" + String.valueOf(j);
            discard1[k + 9] = "fieldTotalRefQtyNivel" + String.valueOf(j);
            discard1[k + 18] = "fieldTotalQty" + String.valueOf(j);
            discard1[k + 27] = "fieldUomsymbol" + String.valueOf(j);
            // discard1[k+36] =
            // "fieldTotalWeightNivel"+String.valueOf(j);
            // discard1[k+45] =
            // "fieldTotalRefWeightNivel"+String.valueOf(j);
            k++;
          }
          int count = 9;
          while (count > intDiscard + 1) {
            discard1[count + 54] = "fieldTotal" + String.valueOf(count);
            discard1[count + 63] = "fieldTotalNivel" + String.valueOf(count);
            discard1[count + 72] = "fieldTotalRefNivel" + String.valueOf(count);
            discard1[count + 81] = "fieldTotalQtyNivel" + String.valueOf(count);
            discard1[count + 90] = "fieldTotalRefQtyNivel" + String.valueOf(count);
            discard1[count + 99] = "fieldTotalQty" + String.valueOf(count);
            discard1[count + 108] = "fieldUomsymbol" + String.valueOf(count);
            // discard1[count+117] =
            // "fieldTotalWeightNivel"+String.valueOf(count);
            // discard1[count+126] =
            // "fieldTotalRefWeightNivel"+String.valueOf(count);
            count--;
          }
        } else {
          for (int j = contador; j > 0; j--) {
            discard1[k] = "fieldNoncomparativeTotalQtyNivel" + String.valueOf(j);
            discard1[k + 27] = "fieldNoncomparativeUomsymbol" + String.valueOf(j);
            // discard1[k+36] =
            // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(j);
            k++;
          }
          int countNon = 9;
          while (countNon > intDiscard + 1) {
            discard1[countNon + 45] = "fieldNoncomparativeTotalNivel" + String.valueOf(countNon);
            discard1[countNon + 54] = "fieldNoncomparativeTotalQtyNivel" + String.valueOf(countNon);
            discard1[countNon + 63] = "fieldNoncomparativeUomsymbol" + String.valueOf(countNon);
            // discard1[countNon+72] =
            // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(countNon);
            countNon--;
          }
        }
      }

    }
    xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_reports/ReportSalesOrderDimensionalPDF", discard1)
        .createXmlDocument();
    xmlDocument.setParameter("eliminar2", discard[1]);
    xmlDocument.setParameter("eliminar3", discard[2]);
    xmlDocument.setParameter("eliminar4", discard[3]);
    xmlDocument.setParameter("eliminar5", discard[4]);
    xmlDocument.setParameter("eliminar6", discard[5]);
    xmlDocument.setParameter("eliminar7", discard[6]);
    xmlDocument.setParameter("eliminar8", discard[7]);
    xmlDocument.setParameter("eliminar9", discard[8]);
    xmlDocument.setParameter("eliminateQty", strEliminateQty);
    xmlDocument.setParameter("eliminateQtyRef", strEliminateQtyRef);
    xmlDocument.setParameter("eliminateQtyAvg", strEliminateQtyAvg);
    // xmlDocument.setParameter("eliminateWeight", strEliminateWeight);
    // xmlDocument.setParameter("eliminateWeightRef",
    // strEliminateWeightRef);
    xmlDocument.setParameter("constante", "100");
    xmlDocument.setParameter("title", strTitle);
    xmlDocument.setParameter("entity", ReportSalesDimensionalAnalyzeData.selectEntity(this, vars
        .getClient()));
    xmlDocument.setParameter("page", strPage);
    if (strComparative.equals("Y")) {
      xmlDocument.setData("structure1", data);
    } else {
      xmlDocument.setData("structure2", data);
    }
    String strResult = xmlDocument.print();
    renderFO(strResult, response);
  }

  public String getServletInfo() {
    return "Servlet ReportRefundInvoiceCustomerDimensionalAnalyses. This Servlet was made by Jon Alegría";
  } // end of getServletInfo() method
}
