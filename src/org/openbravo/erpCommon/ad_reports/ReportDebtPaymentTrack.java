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

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.info.SelectorUtilityData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.UtilsData;

public class ReportDebtPaymentTrack extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom", "ReportDebtPaymentTrack|DateFrom",
          "",this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpDateTo", "ReportDebtPaymentTrack|DateTo", "",this);
      String strcBpartnerId = vars.getInGlobalVariable("inpcBPartnerId_IN",
          "ReportDebtPaymentTrack|cBpartnerId", "", IsIDFilter.instance);
      String strAmtFrom = vars.getNumericGlobalVariable("inpAmtFrom",
          "ReportDebtPaymentTrack|AmtFrom", "");
      String strAmtTo = vars.getNumericGlobalVariable("inpAmtTo", "ReportDebtPaymentTrack|AmtTo",
          "");
      String strInvoice = vars.getGlobalVariable("inpInvoice", "ReportDebtPaymentTrack|Invoice",
          "I");
      String strDPCNA = vars.getGlobalVariable("inpDPCNA", "ReportDebtPaymentTrack|DPCNA", "C");
      String strDPCA = vars.getGlobalVariable("inpDPCA", "ReportDebtPaymentTrack|DPCA", "A");
      String strDPGNA = vars.getGlobalVariable("inpDPGNA", "ReportDebtPaymentTrack|DPGNA", "G");
      String strDPGA = vars.getGlobalVariable("inpDPGA", "ReportDebtPaymentTrack|DPGA", "J");
      String strDPM = vars.getGlobalVariable("inpDPM", "ReportDebtPaymentTrack|DPM", "M");
      String strDPC = vars.getGlobalVariable("inpDPC", "ReportDebtPaymentTrack|DPC", "K");
      String strDPB = vars.getGlobalVariable("inpDPB", "ReportDebtPaymentTrack|DPB", "B");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strcBpartnerId, strAmtFrom,
          strAmtTo, strInvoice, strDPCNA, strDPCA, strDPGNA, strDPGA, strDPM, strDPC, strDPB);
    } else if (vars.commandIn("FIND")) {
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportDebtPaymentTrack|DateFrom",this);
      String strDateTo = vars
          .getDateParameterGlobalVariable("inpDateTo", "ReportDebtPaymentTrack|DateTo",this);
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportDebtPaymentTrack|cBpartnerId", IsIDFilter.instance);
      String strAmtFrom = vars.getNumericRequestGlobalVariable("inpAmtFrom",
          "ReportDebtPaymentTrack|AmtFrom");
      String strAmtTo = vars.getNumericRequestGlobalVariable("inpAmtTo",
          "ReportDebtPaymentTrack|AmtTo");
      String strInvoice = vars.getRequestGlobalVariable("inpInvoice",
          "ReportDebtPaymentTrack|Invoice");
      String strDPCNA = vars.getRequestGlobalVariable("inpDPCNA", "ReportDebtPaymentTrack|DPCNA");
      String strDPCA = vars.getRequestGlobalVariable("inpDPCA", "ReportDebtPaymentTrack|DPCA");
      String strDPGNA = vars.getRequestGlobalVariable("inpDPGNA", "ReportDebtPaymentTrack|DPGNA");
      String strDPGA = vars.getRequestGlobalVariable("inpDPGA", "ReportDebtPaymentTrack|DPGA");
      String strDPM = vars.getRequestGlobalVariable("inpDPM", "ReportDebtPaymentTrack|DPM");
      String strDPC = vars.getRequestGlobalVariable("inpDPC", "ReportDebtPaymentTrack|DPC");
      String strDPB = vars.getRequestGlobalVariable("inpDPB", "ReportDebtPaymentTrack|DPB");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strcBpartnerId, strAmtFrom,
          strAmtTo, strInvoice, strDPCNA, strDPCA, strDPGNA, strDPGA, strDPM, strDPC, strDPB);
      // setHistoryCommand(request, "FIND");
    } else if (vars.commandIn("PRINT_PDF")) {
      String strDateFrom = vars.getDateParameterGlobalVariable("inpDateFrom",
          "ReportDebtPaymentTrack|DateFrom",this);
      String strDateTo = vars
          .getDateParameterGlobalVariable("inpDateTo", "ReportDebtPaymentTrack|DateTo",this);
      String strcBpartnerId = vars.getRequestInGlobalVariable("inpcBPartnerId_IN",
          "ReportDebtPaymentTrack|cBpartnerId", IsIDFilter.instance);
      String strAmtFrom = vars.getNumericRequestGlobalVariable("inpAmtFrom",
          "ReportDebtPaymentTrack|AmtFrom");
      String strAmtTo = vars.getNumericRequestGlobalVariable("inpAmtTo",
          "ReportDebtPaymentTrack|AmtTo");
      String strInvoice = vars.getRequestGlobalVariable("inpInvoice",
          "ReportDebtPaymentTrack|Invoice");
      String strDPCNA = vars.getRequestGlobalVariable("inpDPCNA", "ReportDebtPaymentTrack|DPCNA");
      String strDPCA = vars.getRequestGlobalVariable("inpDPCA", "ReportDebtPaymentTrack|DPCA");
      String strDPGNA = vars.getRequestGlobalVariable("inpDPGNA", "ReportDebtPaymentTrack|DPGNA");
      String strDPGA = vars.getRequestGlobalVariable("inpDPGA", "ReportDebtPaymentTrack|DPGA");
      String strDPM = vars.getRequestGlobalVariable("inpDPM", "ReportDebtPaymentTrack|DPM");
      String strDPC = vars.getRequestGlobalVariable("inpDPC", "ReportDebtPaymentTrack|DPC");
      String strDPB = vars.getRequestGlobalVariable("inpDPB", "ReportDebtPaymentTrack|DPB");
      printPageDataPdf(response, vars, strDateFrom, strDateTo, strcBpartnerId, strAmtFrom,
          strAmtTo, strInvoice, strDPCNA, strDPCA, strDPGNA, strDPGA, strDPM, strDPC, strDPB);
      // setHistoryCommand(request, "FIND");
    } else
      pageError(response);
  }

  private void printPageDataPdf(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strcBpartnerId, String strAmtFrom,
      String strAmtTo, String strInvoice, String strDPCNA, String strDPCA, String strDPGNA,
      String strDPGA, String strDPM, String strDPC, String strDPB) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    ReportDebtPaymentTrackData[] data = null;

    String strDocTypes = "'" + strInvoice + "','" + strDPCNA + "','" + strDPCA + "','" + strDPGNA
        + "','" + strDPGA + "','" + strDPM + "','" + strDPC + "','" + strDPB + "'";
    data = ReportDebtPaymentTrackData.select(this, vars.getLanguage(), Utility.getContext(this,
        vars, "#User_Client", "ReportDebtPayment"), Utility.getContext(this, vars,
        "#AccessibleOrgTree", "ReportDebtPayment"), strcBpartnerId, strDateFrom, strDateTo,
        strAmtFrom, strAmtTo, strDocTypes);
    String strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportDebtPaymentTracker.jrxml";
    renderJR(vars, response, strReportName, "pdf", null, data, null);

  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strcBpartnerId, String strAmtFrom,
      String strAmtTo, String strInvoice, String strDPCNA, String strDPCA, String strDPGNA,
      String strDPGA, String strDPM, String strDPC, String strDPB) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = null;
    ReportDebtPaymentTrackData[] data = null;
    String discard[] = { "" };
    if ((strDateFrom.equals("") && strDateTo.equals("") && strcBpartnerId.equals("")
        && strAmtFrom.equals("") && strAmtTo.equals("") && strInvoice.equals("")
        && strDPCNA.equals("") && strDPCA.equals("") && strDPGNA.equals("") && strDPGA.equals("")
        && strDPM.equals("") && strDPC.equals("") && strDPB.equals(""))) {
      data = ReportDebtPaymentTrackData.set();
      discard[0] = "sectionPartner";
    } else {
      String strDocTypes = "'" + strInvoice + "','" + strDPCNA + "','" + strDPCA + "','" + strDPGNA
          + "','" + strDPGA + "','" + strDPM + "','" + strDPC + "','" + strDPB + "'";
      data = ReportDebtPaymentTrackData.select(this, vars.getLanguage(), Utility.getContext(this,
          vars, "#User_Client", "ReportDebtPayment"), Utility.getContext(this, vars,
          "#AccessibleOrgTree", "ReportDebtPayment"), strcBpartnerId, strDateFrom, strDateTo,
          strAmtFrom, strAmtTo, strDocTypes);
    }
    xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_reports/ReportDebtPaymentTrack", discard).createXmlDocument();

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportDebtPaymentTrack", false, "",
        "", "", false, "ad_reports", strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());
    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_reports.ReportDebtPaymentTrack");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(),
          "ReportDebtPaymentTrack.html", classInfo.id, classInfo.type, strReplaceWith, tabs
              .breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "ReportDebtPaymentTrack.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportDebtPaymentTrack");
      vars.removeMessage("ReportDebtPaymentTrack");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("dateFrom",  UtilsData.selectDisplayDatevalue(this,strDateFrom, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateFromdisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateFromsaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTo",  UtilsData.selectDisplayDatevalue(this,strDateTo, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("dateTodisplayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("dateTosaveFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("AmtFrom", strAmtFrom);
    xmlDocument.setParameter("AmtTo", strAmtTo);
    xmlDocument.setParameter("DPCNA", strDPCNA);
    xmlDocument.setParameter("DPCA", strDPCA);
    xmlDocument.setParameter("DPGNA", strDPGNA);
    xmlDocument.setParameter("DPGA", strDPGA);
    xmlDocument.setParameter("DPM", strDPM);
    xmlDocument.setParameter("DPC", strDPC);
    xmlDocument.setParameter("DPB", strDPB);
    xmlDocument.setParameter("Invoice", strInvoice);
    xmlDocument.setData("reportCBPartnerId_IN", "liststructure", SelectorUtilityData
        .selectBpartner(this, Utility.getContext(this, vars, "#AccessibleOrgTree", ""), Utility
            .getContext(this, vars, "#User_Client", ""), strcBpartnerId));
    xmlDocument.setData("structure1", data);
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet ReportDebtPaymentTrack. This Servlet was made by Eduardo Argal";
  } // end of getServletInfo() method
}
