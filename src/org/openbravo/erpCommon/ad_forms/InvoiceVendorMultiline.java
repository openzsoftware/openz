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

package org.openbravo.erpCommon.ad_forms;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;

public class InvoiceVendorMultiline extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  private static final String formClassName = "org.openbravo.erpCommon.ad_forms.InvoiceVendorMultiline";

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    String windowId = "";
    String tabId = "";
    String tableId = "";
    String tabName = "";
    String windowName = "";
    String windowNameEnUS = "";
    String tabNameEnUS = "";

    {
      InvoiceVendorMultilineData[] data = InvoiceVendorMultilineData.selectWindowData(this, vars
          .getLanguage(), formClassName);
      if (data == null || data.length == 0) {
        throw new ServletException(formClassName + ": Error on window data");
      }
      windowId = data[0].adWindowId;
      tabId = data[0].adTabId;
      tableId = data[0].adTableId;
      tabName = data[0].tabname;
      windowName = data[0].windowname;
      tabNameEnUS = data[0].tabnameEnUs;
      windowNameEnUS = data[0].windownameEnUs;
    }

    if (vars.commandIn("DEFAULT", "EDIT")) {
      String strC_Invoice_ID = vars.getGlobalVariable("inpcInvoiceId", windowId + "|C_Invoice_ID",
          "");
      if (strC_Invoice_ID.equals(""))
        response.sendRedirect(strDireccion + "/" + FormatUtilities.replace(windowNameEnUS) + "/"
            + FormatUtilities.replace(tabNameEnUS) + "_Relation.html?Command=RELATION");
      else
        printPageDataSheet(response, vars, strC_Invoice_ID, windowName, tabName, windowId, tabId,
            tableId, windowNameEnUS, tabNameEnUS);
    } else if (vars.commandIn("NEW")) {
      vars.removeSessionValue(windowId + "|C_Invoice_ID");
      printPageDataSheet(response, vars, "", windowName, tabName, windowId, tabId, tableId,
          windowNameEnUS, tabNameEnUS);
    } else if (vars.commandIn("SAVE_NEW_RELATION", "SAVE_NEW_NEW", "SAVE_NEW_EDIT")) {
      InvoiceVendorMultilineData data = getEditVariables(vars, windowId);
      String strSequence = SequenceIdData.getUUID();
      log4j.info("Sequence: " + strSequence);
      data.cInvoiceId = strSequence;
      if (data.insert(this) == 0) {
        bdError(request, response, "DBExecuteError", vars.getLanguage());
      } else {
        vars.setSessionValue(windowId + "|C_Invoice_ID", data.cInvoiceId);
        if (vars.commandIn("SAVE_NEW_NEW"))
          response.sendRedirect(strDireccion + request.getServletPath() + "?Command=NEW");
        else if (vars.commandIn("SAVE_NEW_EDIT"))
          response.sendRedirect(strDireccion + request.getServletPath() + "?Command=EDIT");
        else
          response.sendRedirect(strDireccion + "/" + FormatUtilities.replace(windowNameEnUS) + "/"
              + FormatUtilities.replace(tabNameEnUS) + "_Relation.html?Command=RELATION");
      }
    } else if (vars.commandIn("SAVE_EDIT_RELATION", "SAVE_EDIT_NEW", "SAVE_EDIT_EDIT")) {
      vars.getRequiredGlobalVariable("inpcInvoiceId", windowId + "|C_Invoice_ID");
      InvoiceVendorMultilineData data = getEditVariables(vars, windowId);
      if (data.update(this) == 0) {
        bdError(request, response, "DBExecuteError", vars.getLanguage());
      } else {
        if (vars.commandIn("SAVE_EDIT_NEW"))
          response.sendRedirect(strDireccion + request.getServletPath() + "?Command=NEW");
        else if (vars.commandIn("SAVE_EDIT_EDIT"))
          response.sendRedirect(strDireccion + request.getServletPath() + "?Command=EDIT");
        else
          response.sendRedirect(strDireccion + "/" + FormatUtilities.replace(windowNameEnUS) + "/"
              + FormatUtilities.replace(tabNameEnUS) + "_Relation.html?Command=RELATION");
      }
    } else if (vars.commandIn("DELETE")) {
      String strC_Invoice_ID = vars.getRequiredStringParameter("inpcInvoiceId");
      InvoiceVendorMultilineData.delete(this, strC_Invoice_ID);
      vars.removeSessionValue(windowId + "|C_Invoice_ID");
      response.sendRedirect(strDireccion + "/" + FormatUtilities.replace(windowNameEnUS) + "/"
          + FormatUtilities.replace(tabNameEnUS) + "_Relation.html?Command=RELATION");
    } else if (vars.commandIn("RELATION")) {
      vars.getGlobalVariable("inpcInvoiceId", windowId + "|C_Invoice_ID", "");
      response.sendRedirect(strDireccion + "/" + FormatUtilities.replace(windowNameEnUS) + "/"
          + FormatUtilities.replace(tabNameEnUS) + "_Relation.html?Command=RELATION");
    } else
      pageError(response);
  }

  private InvoiceVendorMultilineData getEditVariables(VariablesSecureApp vars, String windowId)
      throws IOException, ServletException {
    InvoiceVendorMultilineData data = new InvoiceVendorMultilineData();

    data.processing = vars.getStringParameter("inpprocessing", "N");
    data.issotrx = vars.getRequiredInputGlobalVariable("inpissotrx", windowId + "|IsSOTrx", "N");
    data.cInvoiceId = vars.getRequestGlobalVariable("inpcInvoiceId", windowId + "|C_Invoice_ID");
    data.dateprinted = vars.getStringParameter("inpdateprinted");
    data.isprinted = vars.getStringParameter("inpisprinted", "N");
    data.isselfservice = vars.getStringParameter("inpisselfservice", "N");
    data.processed = vars.getStringParameter("inpprocessed", "N");
    data.istaxincluded = vars.getStringParameter("inpistaxincluded", "N");
    data.adClientId = vars.getGlobalVariable("inpadClientId", windowId + "|AD_Client_ID", vars
        .getClient());
    data.adOrgId = vars.getRequiredGlobalVariable("inpadOrgId", windowId + "|AD_Org_ID");
    data.cOrderId = vars.getStringParameter("inpcOrderId");
    data.dateordered = vars.getStringParameter("inpdateordered");
    data.documentno = vars.getStringParameter("inpdocumentno", "<>");
    data.poreference = vars.getStringParameter("inpporeference");
    data.description = vars.getStringParameter("inpdescription");
    data.isactive = vars.getStringParameter("inpisactive", "Y");
    data.dateinvoiced = vars.getStringParameter("inpdate");
    data.dateacct = vars.getRequiredStringParameter("inpdate");
    data.cBpartnerId = vars
        .getRequiredGlobalVariable("inpcBpartnerId", windowId + "|C_BPartner_ID");
    data.cBpartnerLocationId = vars.getRequiredStringParameter("inpcBpartnerLocationId");
    data.adUserId = vars.getStringParameter("inpadUserId");
    data.salesrepId = vars.getStringParameter("inpsalesrepId");
    data.isdiscountprinted = vars.getStringParameter("inpisdiscountprinted", "N");
    data.cChargeId = vars.getStringParameter("inpcChargeId");
    data.chargeamt = vars.getNumericParameter("inpchargeamt");
    data.paymentrule = vars.getRequiredStringParameter("inppaymentrule");
    data.cPaymenttermId = vars.getRequiredStringParameter("inpcPaymenttermId");
    data.createfrom = vars.getStringParameter("inpcreatefrom", "N");
    data.generateto = vars.getStringParameter("inpgenerateto", "N");
    data.cProjectId = vars.getStringParameter("inpcProjectId");
    data.cActivityId = vars.getStringParameter("inpcActivityId");
    data.cCampaignId = vars.getStringParameter("inpcCampaignId");
    data.adOrgtrxId = vars.getStringParameter("inpadOrgtrxId");
    data.user1Id = vars.getStringParameter("inpuser1Id");
    data.user2Id = vars.getStringParameter("inpuser2Id");
    data.copyfrom = vars.getStringParameter("inpcopyfrom", "N");
    data.posted = vars.getStringParameter("inpposted", "N");
    data.docstatus = vars.getStringParameter("inpdocstatus", "DR");
    data.docaction = vars.getStringParameter("inpdocaction", "CO");

    data.cDoctypetargetId = vars.getStringParameter("inpcDoctypetargetId");
    data.mPricelistId = vars.getGlobalVariable("inpmPricelistId", windowId + "|M_PriceList_ID", "");
    data.cCurrencyId = vars.getGlobalVariable("inpcCurrencyId", windowId + "|C_Currency_ID", "");
    data.cDoctypeId = vars.getGlobalVariable("inpcDoctypeId", windowId + "|C_DocType_ID", "");

    data.createdby = vars.getUser();
    data.updatedby = vars.getUser();

    if (data.cDoctypetargetId.equals(""))
      data.cDoctypetargetId = InvoiceVendorMultilineData.selectDocTypeTarget(this, Utility
          .getContext(this, vars, "#AccessibleOrgTree", windowId), Utility.getContext(this, vars,
          "#User_Client", windowId), Utility.getContext(this, vars, "#AD_Client_ID", windowId),
          data.issotrx);

    if (data.cDoctypeId.equals(""))
      data.cDoctypeId = InvoiceVendorMultilineData.selectDocType(this, Utility.getContext(this,
          vars, "#AccessibleOrgTree", windowId), Utility.getContext(this, vars, "#User_Client",
          windowId));

    if (data.mPricelistId.equals(""))
      data.mPricelistId = InvoiceVendorMultilineData.selectPriceList(this, Utility.getContext(this,
          vars, "#AccessibleOrgTree", windowId), Utility.getContext(this, vars, "#User_Client",
          windowId));

    if (data.cCurrencyId.equals(""))
      data.cCurrencyId = InvoiceVendorMultilineData.selectCurrency(this, Utility.getContext(this,
          vars, "#AccessibleOrgTree", windowId), Utility.getContext(this, vars, "#User_Client",
          windowId));

    if (data.documentno.startsWith("<"))
      data.documentno = Utility.getDocumentNo(this, vars, windowId, "C_Invoice",
          data.cDoctypetargetId, data.cDoctypeId, false, true);

    return data;
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strC_Invoice_ID, String windowName, String tabName, String windowId, String tabId,
      String tableId, String windowNameEnUS, String tabNameEnUS) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    String[] discard = { "newDiscard", "" };
    String strCommand = "EDIT";
    String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
    InvoiceVendorMultilineData[] data = InvoiceVendorMultilineData.select(this, strDateFormat, vars
        .getLanguage(), strC_Invoice_ID);
    if (data == null || data.length == 0) {
      discard[0] = new String("editDiscard");
      strCommand = "NEW";
      data = InvoiceVendorMultilineData.set(vars.getOrg(), vars.getClient(), DateTimeData
          .today(this), "DR", "CO", InvoiceVendorMultilineData.selectDocAction(this, vars
          .getLanguage(), "CO"), "0", "0");
    }

    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_forms/InvoiceVendorMultiline", discard).createXmlDocument();

    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("command", strCommand);
    xmlDocument.setParameter("commandType", strCommand);
    xmlDocument.setParameter("windowName", windowName);
    xmlDocument.setParameter("tabName", tabName);
    xmlDocument.setParameter("windowId", windowId);
    xmlDocument.setParameter("tabId", tabId);
    xmlDocument.setParameter("tableId", tableId);
    xmlDocument.setParameter("windowPath", Utility.getTabURL(this, tabId, "E"));

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "Expenseinvoice", (strCommand
        .equals("NEW") || (data == null || data.length == 0)), "document.frmMain.inpcInvoiceId",
        "", "", "".equals("Y"), "ExpenseInvoice", strReplaceWith, true);
    toolbar.prepareEditionTemplate("N".equals("Y"), false, vars.getSessionValue("#ShowTest", "N")
        .equals("Y"), "STD", false);
    xmlDocument.setParameter("toolbar", toolbar.toString());

    try {
      WindowTabs tabs = new WindowTabs(this, vars, tabId, windowId);
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(),
          "../ExpenseInvoice/ExpenseInvoice_Relation.html", classInfo.id, classInfo.type,
          strReplaceWith, tabs.breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(),
          "../ExpenseInvoice/ExpenseInvoice_Relation.html", strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.editionTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    {
      OBError myMessage = vars.getMessage(tabId);
      vars.removeMessage(tabId);
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "LIST", "",
          "All_Payment Rule", "", Utility.getContext(this, vars, "#AccessibleOrgTree", windowId),
          Utility.getContext(this, vars, "#User_Client", windowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, windowId, data[0].paymentrule);
      xmlDocument.setData("reportPaymentRule", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_Org_ID", "",
          "AD_Org Trx Security validation", Utility.getContext(this, vars, "#User_Org", windowId),
          Utility.getContext(this, vars, "#User_Client", windowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, windowId, data[0].adOrgId);
      xmlDocument.setData("reportAD_Org_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_Org_ID", "",
          "AD_Org Trx Security validation", Utility.getContext(this, vars, "#User_Org", windowId),
          Utility.getContext(this, vars, "#User_Client", windowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, windowId, data[0].adOrgId);
      xmlDocument.setData("reportAD_Org_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR",
          "C_PaymentTerm_ID", "", "", Utility
              .getContext(this, vars, "#AccessibleOrgTree", windowId), Utility.getContext(this,
              vars, "#User_Client", windowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, windowId, data[0].cPaymenttermId);
      xmlDocument.setData("reportC_PaymentTerm_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR",
          "C_BPartner_Location_ID", "", "C_BPartner Location - Bill To", Utility.getContext(this,
              vars, "#AccessibleOrgTree", windowId), Utility.getContext(this, vars, "#User_Client",
              windowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, windowId, data[0].cBpartnerId);
      xmlDocument.setData("reportC_BPartner_Location_ID", "liststructure", comboTableData
          .select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setData("structure1", data);

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "InvoiceVendorMultiline Servlet";
  } // end of getServletInfo() method
}
