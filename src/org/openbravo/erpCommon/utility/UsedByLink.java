/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2012 Stefan Zimmermann
* 
****************************************************************************************************************************************************
 */
package org.openbravo.erpCommon.utility;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.Sqlc;
import org.openbravo.xmlEngine.XmlDocument;

public class UsedByLink extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  @Override
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  @Override
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    final VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      final String strWindow = vars.getStringParameter("inpwindowId");
      final String strTabId = vars.getRequiredStringParameter("inpTabId");
      final String strKeyColumn = vars.getRequiredStringParameter("inpkeyColumnId");
      final String strTableId = vars.getRequiredStringParameter("inpTableId");
      final String strColumnName = Sqlc.TransformaNombreColumna(strKeyColumn);
      String strKeyId = vars.getGlobalVariable("inp" + strColumnName, strWindow + "|"
          + strKeyColumn);
      printPage(response, vars, strWindow, strTabId, strKeyColumn, strKeyId, strTableId);
    } else if (vars.commandIn("LINKS")) {
      final String strWindow = vars.getStringParameter("inpwindowId");
      final String strTabId = vars.getRequiredStringParameter("inpTabId");
      final String strKeyColumn = vars.getRequiredStringParameter("inpkeyColumnId");
      final String strKeyId = vars.getRequiredStringParameter("inp"
          + Sqlc.TransformaNombreColumna(strKeyColumn));
      final String strAD_TAB_ID = vars.getRequiredStringParameter("inpadTabIdKey");
      final String strTABLENAME = vars.getRequiredStringParameter("inptablename");
      final String strCOLUMNNAME = vars.getRequiredStringParameter("inpcolumnname");
      final String strTableId = vars.getRequiredStringParameter("inpTableId");
      printPageDetail(request, response, vars, strWindow, strTabId, strKeyColumn, strKeyId,
          strAD_TAB_ID, strTABLENAME, strCOLUMNNAME, strTableId);
    } else
      throw new ServletException();
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strWindow,
      String TabId, String keyColumn, String keyId, String tableId) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: UsedBy links for tab: " + TabId);

    // Special case: convert FinancialMgmtDebtPaymentGenerateV view into its
    // FinancialMgmtDebtPayment table. Fixes issue #0009973
    if (tableId.equals("800021")) {
      tableId = "800018";
    }

    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/utility/UsedByLink").createXmlDocument();
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("tabID", TabId);
    xmlDocument.setParameter("windowID", strWindow);
    xmlDocument.setParameter("keyColumn", keyColumn);
    xmlDocument.setParameter("tableId", tableId);
    xmlDocument.setParameter("keyName", "inp" + Sqlc.TransformaNombreColumna(keyColumn));
    xmlDocument.setParameter("keyId", keyId);
    xmlDocument.setParameter("recordIdentifier", UsedByLinkData.selectIdentifier(this, keyId, vars
        .getLanguage(), tableId));

    boolean nonAccessible = false;

    UsedByLinkData[] data = null;
    keyColumn=UsedByLinkData.keyColumn(myPool, TabId, keyColumn);
    if (vars.getLanguage().equals("en_US"))
      data = UsedByLinkData.select(this, vars.getClient(), vars.getLanguage(), vars.getRole(),
          keyColumn, tableId);
    else
      data = UsedByLinkData.selectLanguage(this, vars.getClient(), vars.getLanguage(), vars
          .getRole(), keyColumn, tableId);

    if (data != null && data.length > 0) {
      final Vector<Object> vecTotal = new Vector<Object>();
      for (int i = 0; i < data.length; i++) {
        if (log4j.isDebugEnabled())
          log4j.debug("***Referenced tab: " + data[i].adTabId);
        final UsedByLinkData[] dataRef = UsedByLinkData.windowRef(this, data[i].adTabId);
        if (dataRef == null || dataRef.length == 0 )
          continue;
        String strWhereClause = getWhereClause(vars, strWindow, dataRef[0].whereclause);
        if (log4j.isDebugEnabled())
          log4j.debug("***   Referenced where clause (1): " + strWhereClause);
        strWhereClause += getAditionalWhereClause(vars, strWindow, data[i].adTabId,
            data[i].tablename, keyColumn, data[i].columnname, UsedByLinkData.getTabTableName(this,
                tableId));
        if (log4j.isDebugEnabled())
          log4j.debug("***   Referenced where clause (2): " + strWhereClause);
        if (!nonAccessible) {
          final String strNonAccessibleWhere = strWhereClause + " AND AD_ORG_ID NOT IN ("
              + vars.getUserOrg() + ")";
          if (!UsedByLinkData.countLinks(this, data[i].tablename, data[i].columnname, keyId,
              strNonAccessibleWhere).equals("0"))
            nonAccessible = true;
        }
        strWhereClause += " AND AD_ORG_ID IN (" + vars.getUserOrg() + ") AND AD_CLIENT_ID IN ("
            + vars.getUserClient() + ")";
        // How to Find out long running querys
        //  long millis = System.currentTimeMillis();
        int total = Integer.valueOf(
            UsedByLinkData.countLinks(this, data[i].tablename, data[i].columnname, keyId,
                strWhereClause)).intValue();
        long millis2 = System.currentTimeMillis();
        //  if (millis2-millis >1000) 
        //  	System.out.print(data[i].tablename);
        if (log4j.isDebugEnabled())
          log4j.debug("***   Count: " + total);
        data[i].total = Integer.toString(total);

        if (data[i].accessible.equals("N") && total > 0) {
          nonAccessible = true;
        } else if (total > 0) {
          vecTotal.addElement(data[i]);
        }
      }
      data = new UsedByLinkData[vecTotal.size()];
      vecTotal.copyInto(data);
    }

    if (nonAccessible) {
      final OBError myMessage = new OBError();
      myMessage.setType("Warning");
      myMessage.setMessage(Utility.messageBD(this, "NonAccessibleRecords", vars.getLanguage()));
      myMessage.setTitle(Utility.messageBD(this, "Warning", vars.getLanguage()));
      xmlDocument.setParameter("messageType", myMessage.getType());
      xmlDocument.setParameter("messageTitle", myMessage.getTitle());
      xmlDocument.setParameter("messageMessage", myMessage.getMessage());
    }
    xmlDocument.setData("structure1", data);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageDetail(HttpServletRequest request, HttpServletResponse response,
      VariablesSecureApp vars, String strWindow, String TabId, String keyColumn, String keyId,
      String strAD_TAB_ID, String strTABLENAME, String strCOLUMNNAME, String adTableId)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: UsedBy links for tab: " + TabId);
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/utility/UsedByLink_Detail").createXmlDocument();
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("tabID", TabId);
    xmlDocument.setParameter("windowID", strWindow);
    xmlDocument.setParameter("keyColumn", keyColumn);
    xmlDocument.setParameter("adTabId", strAD_TAB_ID);
    xmlDocument.setParameter("tableName", strTABLENAME);
    xmlDocument.setParameter("tableId", adTableId);
    // We have to check whether we have self reference or not
    String selfReferenceCount = UsedByLinkData.getCountOfSelfReference(this, adTableId,
        strTABLENAME);
    if (selfReferenceCount.equals("0")) {
      xmlDocument.setParameter("keyName", "inp" + Sqlc.TransformaNombreColumna(keyColumn));
      xmlDocument.setParameter("keyId", keyId);
      xmlDocument.setParameter("columnName", strCOLUMNNAME);
    } else {
      xmlDocument.setParameter("columnName", keyColumn);
    }

    xmlDocument.setParameter("recordIdentifier", UsedByLinkData.selectIdentifier(this, keyId, vars
        .getLanguage(), adTableId));
    if (vars.getLanguage().equals("en_US")) {
      xmlDocument.setParameter("paramName", UsedByLinkData.tabName(this, strAD_TAB_ID));
    } else {
      xmlDocument.setParameter("paramName", UsedByLinkData.tabNameLanguage(this,
          vars.getLanguage(), strAD_TAB_ID));
    }

    final UsedByLinkData[] data = UsedByLinkData.keyColumns(this, strAD_TAB_ID);
    if (data == null || data.length == 0) {
      bdError(request, response, "RecordError", vars.getLanguage());
      return;
    }
    final StringBuffer strScript = new StringBuffer();
    final StringBuffer strHiddens = new StringBuffer();
    final StringBuffer strSQL = new StringBuffer();
    strScript.append("function windowSelect() {\n");
    strScript.append("var frm = document.forms[0];\n");
    for (int i = 0; i < data.length; i++) {
      if (i > 0) {
        strSQL.append(" || ', ' || ");
      }
      strScript.append("frm.inp").append(Sqlc.TransformaNombreColumna(data[i].name)).append(
          ".value = arguments[").append(i).append("];\n");
      strSQL.append("'''' || ").append(data[i].name).append(" || ''''");
      strHiddens.append("<input type=\"hidden\" name=\"inp").append(
          Sqlc.TransformaNombreColumna(data[i].name)).append("\">\n");
    }
    final UsedByLinkData[] dataRef = UsedByLinkData.windowRef(this, strAD_TAB_ID);
    if (dataRef == null || dataRef.length == 0) {
      bdError(request, response, "RecordError", vars.getLanguage());
      return;
    }
    final String windowRef = Utility.getTabURL(this, strAD_TAB_ID, "E");
    strScript.append("top.opener.submitFormGetParams('DIRECT', '").append(windowRef).append(
        "', getParamsScript(document.forms[0]));\n");
    strScript.append("top.close();\n");
    strScript.append("return true;\n");
    strScript.append("}\n");

    xmlDocument.setParameter("hiddens", strHiddens.toString());
    xmlDocument.setParameter("script", strScript.toString());

    String whereClause = getWhereClause(vars, strWindow, dataRef[0].whereclause);
    whereClause += getAditionalWhereClause(vars, strWindow, strAD_TAB_ID, strTABLENAME, keyColumn,
        strCOLUMNNAME, UsedByLinkData.getTabTableName(this, strAD_TAB_ID));
    whereClause += " AND AD_ORG_ID IN (" + vars.getUserOrg() + ") AND AD_CLIENT_ID IN ("
        + vars.getUserClient() + ")";

    xmlDocument.setData("structure1", UsedByLinkData.selectLinks(this, strSQL.toString(),
        strTABLENAME, data[0].name, vars.getLanguage(), strCOLUMNNAME, keyId, whereClause));
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getWhereClause(VariablesSecureApp vars, String window, String strWhereClause)
      throws ServletException {
    String strWhere = strWhereClause;
    if (strWhere.equals("") || strWhere.indexOf("@") == -1)
      return ((strWhere.equals("") ? "" : " AND ") + strWhere);
    if (log4j.isDebugEnabled())
      log4j.debug("WHERE CLAUSE: " + strWhere);
    final StringBuffer where = new StringBuffer();
    String token = "", fin = "";
    int i = 0;
    i = strWhere.indexOf("@");
    while (i != -1) {
      where.append(strWhere.substring(0, i));
      if (log4j.isDebugEnabled())
        log4j.debug("WHERE ACTUAL: " + where.toString());
      strWhere = strWhere.substring(i + 1);
      if (log4j.isDebugEnabled())
        log4j.debug("WHERE COMPARATION: " + strWhere);
      if (strWhere.startsWith("SQL")) {
        fin += ")";
        strWhere.substring(4);
        where.append("(");
      } else {
        i = strWhere.indexOf("@");
        if (i == -1) {
          log4j.error("Unable to parse the following string: " + strWhereClause + "\nNow parsing: "
              + where.toString());
          throw new ServletException("Unable zo parse the following string: " + strWhereClause
              + "\nNow parsing: " + where.toString());
        }
        token = strWhere.substring(0, i);
        strWhere = (i == strWhere.length()) ? "" : strWhere.substring(i + 1);
        if (log4j.isDebugEnabled())
          log4j.debug("TOKEN: " + token);
        final String tokenResult = "'" + Utility.getContext(this, vars, token, window) + "'";
        if (log4j.isDebugEnabled())
          log4j.debug("TOKEN PARSED: " + tokenResult);
        if (tokenResult.equalsIgnoreCase(token)) {
          log4j.error("Unable to parse the String " + strWhereClause + "\nNow parsing: "
              + where.toString());
          throw new ServletException("Unable to parse the string: " + strWhereClause
              + "\nNow parsing: " + where.toString());
        }
        where.append(tokenResult);
      }
      i = strWhere.indexOf("@");
    }
    ;
    where.append(strWhere);
    return " AND " + where.toString();
  }

  private String getAditionalWhereClause(VariablesSecureApp vars, String strWindow, String adTabId,
      String tableName, String keyColumn, String columnName, String parentTableName)
      throws ServletException {
    String result = "";
    if (log4j.isDebugEnabled())
      log4j.debug("getAditionalWhereClause - ad_Tab_ID: " + adTabId);
    final UsedByLinkData[] data = UsedByLinkData.parentTabTableName(this, adTabId);
    if (data != null && data.length > 0) {
      if (log4j.isDebugEnabled())
        log4j.debug("getAditionalWhereClause - parent tab: " + data[0].adTabId);
      UsedByLinkData[] dataColumn = UsedByLinkData
          .parentsColumnName(this, adTabId, data[0].adTabId);
      if (dataColumn == null || dataColumn.length == 0) {
        if (log4j.isDebugEnabled())
          log4j.debug("getAditionalWhereClause - searching parent Columns Real");
        dataColumn = UsedByLinkData.parentsColumnReal(this, adTabId, data[0].adTabId);
      }
      if (dataColumn == null || dataColumn.length == 0) {
        if (log4j.isDebugEnabled())
          log4j.debug("getAditionalWhereClause - no parent columns found");
        return result;
      }
      result += " AND EXISTS (SELECT 1 FROM " + data[0].tablename + " WHERE " + data[0].tablename
          + "." + ((!dataColumn[0].name.equals("")) ? dataColumn[0].name : keyColumn) + " = "
          + tableName + "." + ((!dataColumn[0].name.equals("")) ? dataColumn[0].name : columnName);
      final UsedByLinkData[] dataRef = UsedByLinkData.windowRef(this, data[0].adTabId);
      String strAux = "";
      if (dataRef != null && dataRef.length > 0)
        strAux = getWhereClause(vars, strWindow, dataRef[0].whereclause);
      result += strAux;
      // Check where clause for parent tabs
      result += getAditionalWhereClause(vars, strWindow, data[0].adTabId, data[0].tablename, "",
          "", parentTableName);
      result += ")";
    }
    if (log4j.isDebugEnabled())
      log4j.debug("getAditionalWhereClause - result: " + result);
    return result;
  }

  @Override
  public String getServletInfo() {
    return "Servlet that presents the usedBy links";
  } // end of getServletInfo() method
}
