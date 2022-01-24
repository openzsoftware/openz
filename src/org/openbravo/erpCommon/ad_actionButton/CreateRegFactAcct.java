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
package org.openbravo.erpCommon.ad_actionButton;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.*;
import java.sql.Connection;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;

public class CreateRegFactAcct extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  private BigDecimal ExpenseAmtDr = new BigDecimal("0");
  private BigDecimal ExpenseAmtCr = new BigDecimal("0");
  private BigDecimal RevenueAmtDr = new BigDecimal("0");
  private BigDecimal RevenueAmtCr = new BigDecimal("0");

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strProcessId = vars.getStringParameter("inpProcessId");
      String strWindow = vars.getStringParameter("inpwindowId");
      String strTab = vars.getStringParameter("inpTabId");
      String strKey = vars.getRequiredGlobalVariable("inpcYearId", strWindow + "|C_Year_ID");
      printPage(response, vars, strKey, "", strWindow, strTab, strProcessId);
    } else if (vars.commandIn("SAVE")) {
      String strWindow = vars.getStringParameter("inpwindowId");
      String strOrgId = vars.getStringParameter("inpadOrgId", "");
      String strKey = vars.getRequiredGlobalVariable("inpcYearId", strWindow + "|C_Year_ID");
      String strTab = vars.getStringParameter("inpTabId");

      String strWindowPath = Utility.getTabURL(this, strTab, "R");
      if (strWindowPath.equals(""))
        strWindowPath = strDefaultServlet;

      OBError myError = processButton(vars, strKey, strOrgId, strWindow);
      vars.setMessage(strTab, myError);
      printPageClosePopUp(response, vars, strWindowPath);
    } else
      pageErrorPopUp(response);
  }

  private synchronized OBError processButton(VariablesSecureApp vars, String strKey,
      String strOrgId, String windowId) {

    Connection conn = null;
    OBError myError = null;
    try {
      conn = this.getTransactionConnection();
      String strRegId = SequenceIdData.getUUID();
      String strCloseId = SequenceIdData.getUUID();
      String strOpenId = SequenceIdData.getUUID();
      String strDivideUpId = SequenceIdData.getUUID();
      CreateRegFactAcctData[] data = CreateRegFactAcctData
          .treeOrg(this, vars.getClient(), strOrgId);
      CreateRegFactAcctData[] acctSchema = CreateRegFactAcctData.treeAcctSchema(this, vars
          .getClient());
      for (int j = 0; j < acctSchema.length; j++) {
        for (int i = 0; i < data.length; i++) {
          if (log4j.isDebugEnabled())
            log4j.debug("Output: Before buttonReg");
          String strRegOut = processButtonReg(conn, vars, strKey, windowId, data[i].org, strRegId,
              acctSchema[j].id);
          String strCloseOut = processButtonClose(conn, vars, strKey, windowId, data[i].org,
              strCloseId, strOpenId, strDivideUpId, acctSchema[j].id);
          if (log4j.isDebugEnabled())
            log4j.debug("Output: After buttonClose - strRegOut:" + strRegOut);
          if (log4j.isDebugEnabled())
            log4j.debug("Output: After buttonClose - strCloseOut:" + strCloseOut);
          if (!strRegOut.equals("Success")) {
            return Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
          } else if (!strCloseOut.equals("Success")) {
            return Utility.translateError(this, vars, vars.getLanguage(), Utility.messageBD(this,
                "ProcessRunError_CreateNextPeriod", vars.getLanguage()));
          }
          ExpenseAmtDr = new BigDecimal("0");
          ExpenseAmtCr = new BigDecimal("0");
          RevenueAmtDr = new BigDecimal("0");
          RevenueAmtCr = new BigDecimal("0");
          String strOrgSchemaId = CreateRegFactAcctData.orgAcctschema(this, data[i].org,
              acctSchema[j].id);
          if (strOrgSchemaId != null && !strOrgSchemaId.equals("")) {
            if (CreateRegFactAcctData.insertOrgClosing(conn, this, vars.getClient(), data[i].org,
                vars.getUser(), strKey, strOrgSchemaId, strRegId, strCloseId, strDivideUpId,
                strOpenId) == 0
                || CreateRegFactAcctData.updateClose(conn, this, vars.getUser(), strKey,
                    data[i].org) == 0)
              return Utility.translateError(this, vars, vars.getLanguage(), "ProcessRunError");
          }
        }
      }
      releaseCommitConnection(conn);
      myError = new OBError();
      myError.setType("Success");
      myError.setTitle("");
      myError.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    } catch (Exception e) {
      log4j.warn(e);
      try {
        releaseRollbackConnection(conn);
      } catch (Exception ignored) {
      }
      myError = Utility.translateError(this, vars, vars.getLanguage(), e.getMessage());
    }
    return myError;
  }

  private synchronized String processButtonReg(Connection conn, VariablesSecureApp vars,
      String strKey, String windowId, String stradOrgId, String strID, String strAcctSchema)
      throws ServletException {

    CreateRegFactAcctData[] expense = CreateRegFactAcctData.getAmounts(this, strKey, "E",
        stradOrgId, strAcctSchema);
    CreateRegFactAcctData[] revenue = CreateRegFactAcctData.getAmounts(this, strKey, "R",
        stradOrgId, strAcctSchema);
    String Fact_Acct_ID = "";
    String Fact_Acct_Group_ID = strID;
    String strPediodId = CreateRegFactAcctData.getLastPeriod(this, strKey);
    String strRegEntry = Utility.messageBD(this, "RegularizationEntry", vars.getLanguage());
    int i;
    for (i = 0; i < expense.length; i++) {
      ExpenseAmtDr = ExpenseAmtDr.add(new BigDecimal(expense[i].totalamtdr));
      ExpenseAmtCr = ExpenseAmtCr.add(new BigDecimal(expense[i].totalamtcr));
      Fact_Acct_ID = SequenceIdData.getUUID();
      if (!expense[i].totalamtdr.equals("0") || !expense[i].totalamtcr.equals("0"))
        CreateRegFactAcctData.insert(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars
            .getUser(), strAcctSchema, expense[i].accountId, CreateRegFactAcctData.getEndDate(this,
            strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
            CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), expense[i].totalamtdr,
            expense[i].totalamtcr, expense[i].totalamtdr, expense[i].totalamtcr,
            Fact_Acct_Group_ID, Integer.toString((i + 3) * 10), expense[i].acctdescription,
            expense[i].acctvalue, expense[i].cBpartnerId, expense[i].recordId2,
            expense[i].mProductId, expense[i].aAssetId, strRegEntry);
    }
    for (int j = 0; j < revenue.length; j++) {
      RevenueAmtDr = RevenueAmtDr.add(new BigDecimal(revenue[j].totalamtdr));
      RevenueAmtCr = RevenueAmtCr.add(new BigDecimal(revenue[j].totalamtcr));
      Fact_Acct_ID = SequenceIdData.getUUID();
      if (!revenue[j].totalamtdr.equals("0") || !revenue[j].totalamtcr.equals("0"))
        CreateRegFactAcctData.insert(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars
            .getUser(), strAcctSchema, revenue[j].accountId, CreateRegFactAcctData.getEndDate(this,
            strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
            CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), revenue[j].totalamtdr,
            revenue[j].totalamtcr, revenue[j].totalamtdr, revenue[j].totalamtcr,
            Fact_Acct_Group_ID, Integer.toString((i + j + 3) * 10), revenue[j].acctdescription,
            revenue[j].acctvalue, revenue[j].cBpartnerId, revenue[j].recordId2,
            revenue[j].mProductId, revenue[j].aAssetId, strRegEntry);
    }
    CreateRegFactAcctData[] account = CreateRegFactAcctData.incomesummary(this, strAcctSchema);
    if (ExpenseAmtDr.add(RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr).signum() > 0) {
      Fact_Acct_ID = SequenceIdData.getUUID();
      CreateRegFactAcctData.insert(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars
          .getUser(), strAcctSchema, account[0].accountId, CreateRegFactAcctData.getEndDate(this,
          strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
          CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), "0", ExpenseAmtDr.add(
              RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr).toString(), "0",
          ExpenseAmtDr.add(RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr).toString(),
          Fact_Acct_Group_ID, "10", account[0].name, account[0].value, account[0].cBpartnerId,
          account[0].recordId2, account[0].mProductId, account[0].aAssetId, strRegEntry);
    } else if (ExpenseAmtDr.add(RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr)
        .signum() < 0) {
      Fact_Acct_ID = SequenceIdData.getUUID();
      CreateRegFactAcctData.insert(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars
          .getUser(), strAcctSchema, account[0].accountId, CreateRegFactAcctData.getEndDate(this,
          strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
          CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), ExpenseAmtCr.add(RevenueAmtCr)
              .subtract(RevenueAmtDr).subtract(ExpenseAmtDr).toString(), "0", ExpenseAmtCr.add(
              RevenueAmtCr).subtract(RevenueAmtDr).subtract(ExpenseAmtDr).toString(), "0",
          Fact_Acct_Group_ID, "10", account[0].name, account[0].value, account[0].cBpartnerId,
          account[0].recordId2, account[0].mProductId, account[0].aAssetId, strRegEntry);
    }
    return "Success";
  }

  private synchronized String processButtonClose(Connection conn, VariablesSecureApp vars,
      String strKey, String windowId, String stradOrgId, String strCloseID, String strOpenID,
      String strDivideUpId, String strAcctSchema) throws ServletException {
    BigDecimal assetAmtDr = new BigDecimal("0");
    BigDecimal assetAmtCr = new BigDecimal("0");
    BigDecimal liabilityAmtDr = new BigDecimal("0");
    BigDecimal liabilityAmtCr = new BigDecimal("0");
    String Fact_Acct_ID = "";
    String Fact_Acct_Group_ID = strCloseID;
    String strPediodId = CreateRegFactAcctData.getLastPeriod(this, strKey);
    String newPeriod = CreateRegFactAcctData.getNextPeriod(this, strPediodId);
    String strOpeningEntry = Utility.messageBD(this, "OpeningEntry", vars.getLanguage());
    String strClosingEntry = Utility.messageBD(this, "ClosingEntry", vars.getLanguage());
    if (newPeriod.equals("")) {
      return "ProcessRunError";
    }
    CreateRegFactAcctData[] account2 = CreateRegFactAcctData.retainedearning(this, strAcctSchema);
    CreateRegFactAcctData[] account = null;
    if (account2 != null && account2.length > 0) {
      account = CreateRegFactAcctData.incomesummary(this, strAcctSchema);
      if (ExpenseAmtDr.add(RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr).signum() > 0) {
        Fact_Acct_ID = SequenceIdData.getUUID();
        CreateRegFactAcctData.insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId,
            vars.getUser(), strAcctSchema, account[0].accountId, CreateRegFactAcctData.getEndDate(
                this, strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
            CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), ExpenseAmtDr.add(RevenueAmtDr)
                .subtract(RevenueAmtCr).subtract(ExpenseAmtCr).toString(), "0", ExpenseAmtDr.add(
                RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr).toString(), "0",
            strDivideUpId, "10", "C", account[0].name, account[0].value, account[0].cBpartnerId,
            account[0].recordId2, account[0].mProductId, account[0].aAssetId, strClosingEntry);
        Fact_Acct_ID = SequenceIdData.getUUID();
        CreateRegFactAcctData
            .insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars.getUser(),
                strAcctSchema, account2[0].accountId, CreateRegFactAcctData.getEndDate(this,
                    strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
                CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), "0", ExpenseAmtDr.add(
                    RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr).toString(), "0",
                ExpenseAmtDr.add(RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr)
                    .toString(), strDivideUpId, "10", "C", account2[0].name, account2[0].value,
                account2[0].cBpartnerId, account2[0].recordId2, account2[0].mProductId,
                account2[0].aAssetId, strClosingEntry);
      } else if (ExpenseAmtDr.add(RevenueAmtDr).subtract(RevenueAmtCr).subtract(ExpenseAmtCr)
          .signum() < 0) {
        Fact_Acct_ID = SequenceIdData.getUUID();
        CreateRegFactAcctData
            .insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars.getUser(),
                strAcctSchema, account[0].accountId, CreateRegFactAcctData.getEndDate(this,
                    strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
                CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), "0", ExpenseAmtCr.add(
                    RevenueAmtCr).subtract(RevenueAmtDr).subtract(ExpenseAmtDr).toString(), "0",
                ExpenseAmtCr.add(RevenueAmtCr).subtract(RevenueAmtDr).subtract(ExpenseAmtDr)
                    .toString(), strDivideUpId, "10", "C", account[0].name, account[0].value,
                account[0].cBpartnerId, account[0].recordId2, account[0].mProductId,
                account[0].aAssetId, strClosingEntry);
        Fact_Acct_ID = SequenceIdData.getUUID();
        CreateRegFactAcctData.insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId,
            vars.getUser(), strAcctSchema, account2[0].accountId, CreateRegFactAcctData.getEndDate(
                this, strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
            CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), ExpenseAmtCr.add(RevenueAmtCr)
                .subtract(RevenueAmtDr).subtract(ExpenseAmtDr).toString(), "0", ExpenseAmtCr.add(
                RevenueAmtCr).subtract(RevenueAmtDr).subtract(ExpenseAmtDr).toString(), "0",
            strDivideUpId, "10", "C", account2[0].name, account2[0].value, account2[0].cBpartnerId,
            account2[0].recordId2, account2[0].mProductId, account2[0].aAssetId, strClosingEntry);
      }
    }
    CreateRegFactAcctData[] asset = CreateRegFactAcctData.getAmountsClose(conn, this, strKey,
        "'A'", stradOrgId, strAcctSchema);
    CreateRegFactAcctData[] liability = CreateRegFactAcctData.getAmountsClose(conn, this, strKey,
        "'L','O'", stradOrgId, strAcctSchema);
    int i;
    for (i = 0; i < asset.length; i++) {
      assetAmtDr = assetAmtDr.add(new BigDecimal(asset[i].totalamtdr));
      assetAmtCr = assetAmtCr.add(new BigDecimal(asset[i].totalamtcr));
      Fact_Acct_ID = SequenceIdData.getUUID();
      if (!asset[i].totalamtdr.equals("0") || !asset[i].totalamtcr.equals("0"))
        CreateRegFactAcctData.insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId,
            vars.getUser(), strAcctSchema, asset[i].accountId, CreateRegFactAcctData.getEndDate(
                this, strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
            CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), asset[i].totalamtdr,
            asset[i].totalamtcr, asset[i].totalamtdr, asset[i].totalamtcr, Fact_Acct_Group_ID,
            Integer.toString((i + 3) * 10), "C", asset[i].acctdescription, asset[i].acctvalue,
            asset[i].cBpartnerId, asset[i].recordId2, asset[i].mProductId, asset[i].aAssetId,
            strClosingEntry);
    }
    for (int j = 0; j < liability.length; j++) {
      liabilityAmtDr = liabilityAmtDr.add(new BigDecimal(liability[j].totalamtdr));
      liabilityAmtCr = liabilityAmtCr.add(new BigDecimal(liability[j].totalamtcr));
      Fact_Acct_ID = SequenceIdData.getUUID();
      if (!liability[j].totalamtdr.equals("0") || !liability[j].totalamtcr.equals("0"))
        CreateRegFactAcctData
            .insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars.getUser(),
                strAcctSchema, liability[j].accountId, CreateRegFactAcctData.getEndDate(this,
                    strPediodId), strPediodId, CreateRegFactAcctData.adTableId(this), "A",
                CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), liability[j].totalamtdr,
                liability[j].totalamtcr, liability[j].totalamtdr, liability[j].totalamtcr,
                Fact_Acct_Group_ID, Integer.toString((i + j + 3) * 10), "C",
                liability[j].acctdescription, liability[j].acctvalue, liability[j].cBpartnerId,
                liability[j].recordId2, liability[j].mProductId, liability[j].aAssetId,
                strClosingEntry);
    }

    String Fact_Acct_Group_ID2 = strOpenID;
    i = 0;
    for (i = 0; i < asset.length; i++) {
      assetAmtDr = assetAmtDr.add(new BigDecimal(asset[i].totalamtdr));
      assetAmtCr = assetAmtCr.add(new BigDecimal(asset[i].totalamtcr));
      Fact_Acct_ID = SequenceIdData.getUUID();
      if (!asset[i].totalamtdr.equals("0") || !asset[i].totalamtcr.equals("0"))
        CreateRegFactAcctData.insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId,
            vars.getUser(), strAcctSchema, asset[i].accountId, CreateRegFactAcctData.getStartDate(
                this, newPeriod), newPeriod, CreateRegFactAcctData.adTableId(this), "A",
            CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), asset[i].totalamtcr,
            asset[i].totalamtdr, asset[i].totalamtcr, asset[i].totalamtdr, Fact_Acct_Group_ID2,
            Integer.toString((i + 3) * 10), "O", asset[i].acctdescription, asset[i].acctvalue,
            asset[i].cBpartnerId, asset[i].recordId2, asset[i].mProductId, asset[i].aAssetId,
            strOpeningEntry);
    }
    for (int j = 0; j < liability.length; j++) {
      liabilityAmtDr = liabilityAmtDr.add(new BigDecimal(liability[j].totalamtdr));
      liabilityAmtCr = liabilityAmtCr.add(new BigDecimal(liability[j].totalamtcr));
      Fact_Acct_ID = SequenceIdData.getUUID();
      if (!liability[j].totalamtdr.equals("0") || !liability[j].totalamtcr.equals("0"))
        CreateRegFactAcctData
            .insertClose(conn, this, Fact_Acct_ID, vars.getClient(), stradOrgId, vars.getUser(),
                strAcctSchema, liability[j].accountId, CreateRegFactAcctData.getStartDate(this,
                    newPeriod), newPeriod, CreateRegFactAcctData.adTableId(this), "A",
                CreateRegFactAcctData.cCurrencyId(this, strAcctSchema), liability[j].totalamtcr,
                liability[j].totalamtdr, liability[j].totalamtcr, liability[j].totalamtdr,
                Fact_Acct_Group_ID2, Integer.toString((i + j + 3) * 10), "O",
                liability[j].acctdescription, liability[j].acctvalue, liability[j].cBpartnerId,
                liability[j].recordId2, liability[j].mProductId, liability[j].aAssetId,
                strOpeningEntry);
    }

    return "Success";
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strKey,
      String strOrgId, String windowId, String strTab, String strProcessId) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Button process Create Close Fact Acct");

    ActionButtonDefaultData[] data = null;
    String strHelp = "", strDescription = "";
    if (vars.getLanguage().equals("es_ES"))
      data = ActionButtonDefaultData.select(this, strProcessId);
    else
      data = ActionButtonDefaultData.selectLanguage(this, vars.getLanguage(), strProcessId);

    if (data != null && data.length != 0) {
      strDescription = data[0].description;
      strHelp = data[0].help;
    }
    String[] discard = { "" };
    if (strHelp.equals(""))
      discard[0] = new String("helpDiscard");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_actionButton/CreateRegFactAcct", discard).createXmlDocument();
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("window", windowId);
    xmlDocument.setParameter("tab", strTab);
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("question", Utility.messageBD(this, "StartProcess?", vars
        .getLanguage()));
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("description", strDescription);
    xmlDocument.setParameter("help", strHelp);

    xmlDocument.setData("reportadOrgId", "liststructure", CreateRegFactAcctData.select(this, vars
        .getClient(), Utility.getContext(this, vars, "#User_Org", "CreateRegFactAcct")));

    xmlDocument.setParameter("adOrgId", strOrgId);

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet Project close fact acct";
  } // end of getServletInfo() method
}
