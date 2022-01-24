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

public class ReportInvoiceCustomerDimensionalPDF extends HttpSecureAppServlet {
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
      // hardcoded to numeric in switch in the code
      String strNotShown = vars.getInStringParameter("inpNotShown", IsPositiveIntFilter.instance);
      String strShown = vars.getInStringParameter("inpShown", IsPositiveIntFilter.instance);
      String strOrg = vars.getGlobalVariable("inpOrg",
          "ReportInvoiceCustomerDimensionalAnalyses|org", "0");
      String strsalesrepId = vars.getRequestGlobalVariable("inpSalesrepId",
          "ReportInvoiceCustomerDimensionalAnalyses|salesrep");
      String strOrder = vars.getRequestGlobalVariable("inpOrder",
          "ReportInvoiceCustomerDimensionalAnalyses|order");
      String strcProjectId = vars.getRequestGlobalVariable("inpcProjectId",
          "ReportInvoiceCustomerDimensionalAnalyses|project");
      String strProducttype = vars.getRequestGlobalVariable("inpProducttype",
          "ReportInvoiceVendorDimensionalAnalyses|producttype");
      String strMayor = vars.getStringParameter("inpMayor", "");
      String strMenor = vars.getStringParameter("inpMenor", "");
      String strComparative = vars.getStringParameter("inpComparative", "N");
      String strPartnerSalesrepId = vars.getRequestGlobalVariable("inpPartnerSalesrepId",
          "ReportInvoiceCustomerDimensionalAnalyses|partnersalesrep");
      printPagePdf(response, vars, strComparative, strDateFrom, strDateTo, strPartnerGroup,
          strcBpartnerId, strProductCategory, strmProductId, strNotShown, strShown, strDateFromRef,
          strDateToRef, strOrg, strsalesrepId, strOrder, strcProjectId, strProducttype, strMayor,
          strMenor, strPartnerSalesrepId);
    } else
      pageErrorPopUp(response);
  }

  private void printPagePdf(HttpServletResponse response, VariablesSecureApp vars,
      String strComparative, String strDateFrom, String strDateTo, String strPartnerGroup,
      String strcBpartnerId, String strProductCategory, String strmProductId, String strNotShown,
      String strShown, String strDateFromRef, String strDateToRef, String strOrg,
      String strsalesrepId, String strOrder, String strcProjectId, String strProducttype,
      String strMayor, String strMenor, String strPartnerSalesrepId) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print pdf");
    XmlDocument xmlDocument = null;
    String strPage = "basicPSMSecond";
    String strOrderby = "";
    String[] discard = { "", "", "", "", "", "", "", "", "", "" };
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
          + " " + ReportInvoiceCustomerDimensionalAnalysesData.selectBpgroup(this, strPartnerGroup);
    // if (!strcBpartnerId.equals("")) strTitle =
    //strTitle+", para el tercero "+ReportRefundInvoiceCustomerDimensionalAnalysesData.selectBpartner
    // (this,
    // strcBpartnerId);
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
      strTitle = strTitle + ", " + Utility.messageBD(this, "TheSalesRep", vars.getLanguage()) + " "
          + ReportInvoiceCustomerDimensionalAnalysesData.selectSalesrep(this, strsalesrepId);
    if (!strPartnerSalesrepId.equals(""))
      strTitle = strTitle + ", " + Utility.messageBD(this, "TheClientSalesRep", vars.getLanguage())
          + " "
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
    String strEliminateQty = " ";
    String strEliminateQtyRef = " ";
    String strEliminateQtyAvg = " ";
    // String strEliminateWeight = " ";
    // String strEliminateWeightRef = " ";
    for (int i = 0; i < 10; i++) {
      if (strShownArray[i].equals("1")) {
        strTextShow[i] = "C_BP_GROUP.NAME";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("2")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER('C_Bpartner', TO_CHAR(C_BPARTNER.C_BPARTNER_ID), '"
            + vars.getLanguage() + "')";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("3")) {
        strTextShow[i] = "M_PRODUCT_CATEGORY.NAME";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("4")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER('M_Product', TO_CHAR(M_PRODUCT.M_PRODUCT_ID), '"
            + vars.getLanguage() + "')||' ('||UOMSYMBOL||')'";
        discard[i] = "10";
        strEliminateQty = "Cant";
        strEliminateQtyRef = "Cant ref";
        strEliminateQtyAvg = "%cant";
        // strEliminateWeight = "Peso";
        // strEliminateWeightRef = "Peso ref";
        intAuxDiscard = i;
        intOrder++;
      } else if (strShownArray[i].equals("5")) {
        strTextShow[i] = "C_INVOICE.DOCUMENTNO";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("6")) {
        strTextShow[i] = "AD_USER.FIRSTNAME||' '||' '||AD_USER.LASTNAME";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("8")) {
        strTextShow[i] = "AD_ORG.NAME";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("9")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER('C_Bpartner', TO_CHAR(CB.C_BPARTNER_ID), '"
            + vars.getLanguage() + "')";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("10")) {
        strTextShow[i] = "C_PROJECT.NAME";
        discard[i] = "10";
        intDiscard++;
        intOrder++;
      } else if (strShownArray[i].equals("11")) {
        strTextShow[i] = "AD_COLUMN_IDENTIFIER('C_Bpartner_Location', TO_CHAR(M_INOUT.C_BPARTNER_LOCATION_ID), '"
            + vars.getLanguage() + "')";
        intDiscard++;
        intOrder++;
      } else {
        strTextShow[i] = "''";
        discard[i] = "0.1";
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
              "#User_Client", "ReportInvoiceCustomerDimensionalPDF"), strDateFrom, DateTimeData
              .nDaysAfter(this, strDateTo, "1"), strPartnerGroup, strcBpartnerId,
          strProductCategory, strmProductId, strsalesrepId, strPartnerSalesrepId, strcProjectId,
          strProducttype, strDateFromRef, DateTimeData.nDaysAfter(this, strDateToRef, "1"),
          strOrderby);
    } else {
      data = ReportInvoiceCustomerDimensionalAnalysesData.selectNoComparative(this, strTextShow[0],
          strTextShow[1], strTextShow[2], strTextShow[3], strTextShow[4], strTextShow[5],
          strTextShow[6], strTextShow[7], strTextShow[8], strTextShow[9], Tree.getMembers(this,
              TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility.getContext(this, vars,
              "#User_Client", "ReportInvoiceCustomerDimensionalPDF"), strDateFrom, DateTimeData
              .nDaysAfter(this, strDateTo, "1"), strPartnerGroup, strcBpartnerId,
          strProductCategory, strmProductId, strsalesrepId, strPartnerSalesrepId, strcProjectId,
          strProducttype, strOrderby);
    }

    if (data.length == 0 || data == null) {
      data = ReportInvoiceCustomerDimensionalAnalysesData.set();
    } else {
      int contador = intDiscard;
      if (intAuxDiscard == -1) {
        if (strComparative.equals("Y")) {
          for (int j = 1; j < 11; j++) {
            discard1[j] = "fieldTotalQtyNivel" + String.valueOf(j);
            discard1[j + 10] = "fieldTotalRefQtyNivel" + String.valueOf(j);
            discard1[j + 20] = "fieldTotalQty" + String.valueOf(j);
            // discard1[j+27] =
            // "fieldTotalWeightNivel"+String.valueOf(j);
            // discard1[j+36] =
            // "fieldTotalRefWeightNivel"+String.valueOf(j);
            // discard1[j+18] = "fieldUomsymbol"+String.valueOf(j);
          }
          int count = 10;
          while (count > contador) {
            // discard1[count+24] =
            // "fieldTotalNivel"+String.valueOf(count);
            // discard1[count+30] =
            // "fieldTotalRefNivel"+String.valueOf(count);
            discard1[count + 40] = "fieldTotal" + String.valueOf(count);
            count--;
          }
        } else {
          for (int j = 1; j < 11; j++) {
            discard1[j] = "fieldNoncomparativeTotalQtyNivel" + String.valueOf(j);
            // discard1[j+27] =
            // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(j);
            // discard1[j+18] =
            // "fieldNoncomparativeUomsymbol"+String.valueOf(j);
          }
          /*
           * while(count>contador){ discard1[count+24] =
           * "fieldNoncomparativeTotalNivel"+String.valueOf(count); count--; }
           */
        }

      } else {
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
          int count = 10;
          while (count > intDiscard + 1) {
            discard1[count + 30] = "fieldTotal" + String.valueOf(count);
            // discard1[count+30] =
            // "fieldTotalNivel"+String.valueOf(count);
            // discard1[count+36] =
            // "fieldTotalRefNivel"+String.valueOf(count);
            discard1[count + 40] = "fieldTotalQtyNivel" + String.valueOf(count);
            discard1[count + 50] = "fieldTotalRefQtyNivel" + String.valueOf(count);
            discard1[count + 60] = "fieldTotalQty" + String.valueOf(count);
            // discard1[count+63] =
            // "fieldTotalWeightNivel"+String.valueOf(count);
            // discard1[count+72] =
            // "fieldTotalRefWeightNivel"+String.valueOf(count);
            // discard1[count+60] =
            // "fieldUomsymbol"+String.valueOf(count);
            count--;
          }
        } else {
          for (int j = contador; j > 0; j--) {
            discard1[k] = "fieldNoncomparativeTotalQtyNivel" + String.valueOf(j);
            // discard1[k+27] =
            // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(j);
            // discard1[k+18] =
            // "fieldNoncomparativeUomsymbol"+String.valueOf(j);
            k++;
          }
          int countNon = 10;
          while (countNon > intDiscard + 1) {
            // discard1[countNon+24] =
            // "fieldNoncomparativeTotalNivel"+String.valueOf(countNon);
            discard1[countNon + 40] = "fieldNoncomparativeTotalQtyNivel" + String.valueOf(countNon);
            // discard1[k+27] =
            // "fieldNoncomparativeTotalWeightNivel"+String.valueOf(countNon);
            // discard1[countNon+36] =
            // "fieldNoncomparativeUomsymbol"+String.valueOf(countNon);
            countNon--;
          }
        }
      }
    }
    xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_reports/ReportInvoiceCustomerDimensionalPDF", discard1)
        .createXmlDocument();
    xmlDocument.setParameter("eliminar2", discard[1]);
    xmlDocument.setParameter("eliminar3", discard[2]);
    xmlDocument.setParameter("eliminar4", discard[3]);
    xmlDocument.setParameter("eliminar5", discard[4]);
    xmlDocument.setParameter("eliminar6", discard[5]);
    xmlDocument.setParameter("eliminar7", discard[6]);
    xmlDocument.setParameter("eliminar8", discard[7]);
    xmlDocument.setParameter("eliminar9", discard[8]);
    xmlDocument.setParameter("eliminar10", discard[9]);
    xmlDocument.setParameter("eliminateQty", strEliminateQty);
    xmlDocument.setParameter("eliminateQtyRef", strEliminateQtyRef);
    xmlDocument.setParameter("eliminateQtyAvg", strEliminateQtyAvg);
    // xmlDocument.setParameter("eliminateWeight", strEliminateWeight);
    // xmlDocument.setParameter("eliminateWeightRef",
    // strEliminateWeightRef);
    xmlDocument.setParameter("total", ReportInvoiceCustomerDimensionalAnalysesData.selectTotal(
        this, Tree.getMembers(this, TreeData.getTreeOrg(this, vars.getClient()), strOrg), Utility
            .getContext(this, vars, "#User_Client", "ReportInvoiceCustomerDimensionalAnalyses"),
        strDateFrom, DateTimeData.nDaysAfter(this, strDateTo, "1"), strPartnerGroup,
        strcBpartnerId, strProductCategory, strmProductId, strsalesrepId, strPartnerSalesrepId,
        strcProjectId, strProducttype));
    xmlDocument.setParameter("title", strTitle);
    xmlDocument.setParameter("page", strPage);
    xmlDocument.setParameter("entity", ReportInvoiceCustomerDimensionalAnalysesData.selectEntity(
        this, vars.getClient()));
    xmlDocument.setParameter("constante", "100");
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
