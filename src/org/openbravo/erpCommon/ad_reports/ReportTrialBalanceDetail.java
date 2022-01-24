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

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;

public class ReportTrialBalanceDetail extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strDateFrom = vars.getGlobalVariable("inpDateFrom",
          "ReportTrialBalanceDetailDetail|DateFrom", "");
      String strDateTo = vars.getGlobalVariable("inpDateTo",
          "ReportTrialBalanceDetailDetail|DateTo", "");
      String strOrg = vars.getGlobalVariable("inpOrg", "ReportTrialBalanceDetailDetail|Org", "");
      String strLevel = vars.getGlobalVariable("inpLevel", "ReportTrialBalanceDetailDetail|Level",
          "");
      String strId = vars.getGlobalVariable("inpcElementValueId",
          "ReportTrialBalanceDetailDetail|Id", "");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strOrg, strLevel, strId);
    } else if (vars.commandIn("FIND")) {
      String strDateFrom = vars.getRequestGlobalVariable("inpDateFrom",
          "ReportTrialBalanceDetailDetail|DateFrom");
      String strDateTo = vars.getRequestGlobalVariable("inpDateTo",
          "ReportTrialBalanceDetailDetail|DateTo");
      String strOrg = vars.getRequestGlobalVariable("inpOrg", "ReportTrialBalanceDetailDetail|Org");
      String strLevel = vars.getRequestGlobalVariable("inpLevel",
          "ReportTrialBalanceDetailDetail|Level");
      String strId = vars.getRequestGlobalVariable("inpcElementValueId",
          "ReportTrialBalanceDetailDetail|Id");
      printPageDataSheet(response, vars, strDateFrom, strDateTo, strOrg, strLevel, strId);
    } else
      pageError(response);
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strDateFrom, String strDateTo, String strOrg, String strLevel, String strId)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    String discard[] = { "sectionDiscard" };
    XmlDocument xmlDocument = null;
    String strTreeOrg = ReportTrialBalanceDetailData.treeOrg(this, vars.getClient());
    String strOrgFamily = getFamily(strTreeOrg, strOrg);
    String strTreeAccount = ReportTrialBalanceDetailData.treeAccount(this, vars.getClient());
    ReportTrialBalanceDetailData[] data = null;
    if (strDateFrom.equals("") && strDateTo.equals("") || strId.equals("")) {
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportTrialBalanceDetail", discard)
          .createXmlDocument();
      data = ReportTrialBalanceDetailData.set();
    } else {
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/ad_reports/ReportTrialBalanceDetail").createXmlDocument();
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - getFamily - strTreeAccount = " + strTreeAccount);
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - getFamily - strId = " + strId);
      String strIdFamily = "'" + strId + "'";
          //getFamily(strTreeAccount, strId);
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - select - strOrgFamily = " + strOrgFamily);
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - select - #User_Client = "
            + Utility.getContext(this, vars, "#User_Client", "ReportTrialBalanceDetail"));
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - select - #AccessibleOrgTree = "
            + Utility.getContext(this, vars, "#AccessibleOrgTree", "ReportTrialBalanceDetail"));
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - select - strDateFrom = " + strDateFrom);
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - select - strDateTo = "
            + DateTimeData.nDaysAfter(this, strDateTo, "1"));
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - select - strIdFamily = " + strIdFamily);
      if (log4j.isDebugEnabled())
        log4j.debug("printPageDataSheet - select - strId = " + strId);
      data = ReportTrialBalanceDetailData.select(this, strOrgFamily, Utility.getContext(this, vars,
          "#User_Client", "ReportTrialBalanceDetail"), Utility.getContext(this, vars,
          "#AccessibleOrgTree", "ReportTrialBalanceDetail"), strDateFrom, DateTimeData.nDaysAfter(
          this, strDateTo, "1"), strIdFamily, strId);
    }

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ReportTrialBalanceDetail", false, "",
        "", "", false, "ad_reports", strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());
    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_reports.ReportTrialBalanceDetail");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(),
          "ReportTrialBalanceDetail.html", classInfo.id, classInfo.type, strReplaceWith, tabs
              .breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "ReportTrialBalanceDetail.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("ReportTrialBalanceDetail");
      vars.removeMessage("ReportTrialBalanceDetail");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument
        .setParameter("account", ReportTrialBalanceDetailData.selectAccountName(this, strId));
    xmlDocument.setData("structure1", data);
    out.println(xmlDocument.print());
    out.close();
  }

  private String getFamily(String strTree, String strChild) throws IOException, ServletException {
    return Tree.getMembers(this, strTree, strChild);
    /*
     * ReportGeneralLedgerData [] data = ReportGeneralLedgerData.selectChildren(this, strTree,
     * strChild); TreeData [] data = Tree.getMembers(this, strTree, strChild); String strFamily =
     * ""; if(data!=null && data.length>0) { for (int i = 0;i<data.length;i++){ if (i>0) strFamily =
     * strFamily + ","; strFamily = strFamily + data[i].id; } return strFamily; }else return "'1'";
     */
  }

  public String getServletInfo() {
    return "Servlet ReportTrialBalanceDetail. This Servlet was made by Eduardo Argal";
  } // end of getServletInfo() method
}
