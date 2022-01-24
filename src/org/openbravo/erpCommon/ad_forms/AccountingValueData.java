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
import java.io.InputStream;

import org.apache.log4j.Logger;
import org.openbravo.base.MultipartRequest;
import org.openbravo.base.VariablesBase;
import org.openbravo.data.FieldProvider;

class AccountingValueData extends MultipartRequest implements FieldProvider {
  static Logger log4j = Logger.getLogger(AccountingValueData.class);
  public String accountValue = "";
  public String accountName = "";
  public String accountDescription = "";
  public String accountType = "";
  public String accountSign = "";
  public String accountDocument = "";
  public String accountSummary = "";
  public String defaultAccount = "";
  public String accountParent = "";
  public String elementLevel = "";
  public String operands = "";
  public String balanceSheet = "";
  public String balanceSheetName = "";
  public String uS1120BalanceSheet = "";
  public String uS1120BalanceSheetName = "";
  public String profitAndLoss = "";
  public String profitAndLossName = "";
  public String uS1120IncomeStatement = "";
  public String uS1120IncomeStatementName = "";
  public String cashFlow = "";
  public String cashFlowName = "";
  public String cElementValueId = "";

  public AccountingValueData() {
  }

  public AccountingValueData(VariablesBase _vars, String _filename, boolean _firstLineHeads,
      String _format) throws IOException {
    super(_vars, _filename, _firstLineHeads, _format, null);
  }

  public AccountingValueData(VariablesBase _vars, InputStream _in, boolean _firstLineHeads,
      String _format) throws IOException {
    super(_vars, _in, _firstLineHeads, _format, null);
  }

  public String getField(String fieldName) {
    if (fieldName.equalsIgnoreCase("ACCOUNT_VALUE") || fieldName.equals("accountValue"))
      return accountValue;
    else if (fieldName.equalsIgnoreCase("ACCOUNT_NAME") || fieldName.equals("accountName"))
      return accountName;
    else if (fieldName.equalsIgnoreCase("ACCOUNT_DESCRIPTION")
        || fieldName.equals("accountDescription"))
      return accountDescription;
    else if (fieldName.equalsIgnoreCase("ACCOUNT_TYPE") || fieldName.equals("accountType"))
      return accountType;
    else if (fieldName.equalsIgnoreCase("ACCOUNT_SIGN") || fieldName.equals("accountSign"))
      return accountSign;
    else if (fieldName.equalsIgnoreCase("ACCOUNT_DOCUMENT") || fieldName.equals("accountDocument"))
      return accountDocument;
    else if (fieldName.equalsIgnoreCase("ACCOUNT_SUMMARY") || fieldName.equals("accountSummary"))
      return accountSummary;
    else if (fieldName.equalsIgnoreCase("DEFAULT_ACCOUNT") || fieldName.equals("defaultAccount"))
      return defaultAccount;
    else if (fieldName.equalsIgnoreCase("ACCOUNT_PARENT") || fieldName.equals("accountParent"))
      return accountParent;
    else if (fieldName.equalsIgnoreCase("ELEMENT_LEVEL") || fieldName.equals("elementLevel"))
      return elementLevel;
    else if (fieldName.equalsIgnoreCase("OPERANDS") || fieldName.equals("operands"))
      return operands.trim();
    else if (fieldName.equalsIgnoreCase("BALANCE_SHEET") || fieldName.equals("balanceSheet"))
      return balanceSheet;
    else if (fieldName.equalsIgnoreCase("BALANCE_SHEET_NAME")
        || fieldName.equals("balanceSheetName"))
      return balanceSheetName;
    else if (fieldName.equalsIgnoreCase("US_1120_BALANCE_SHEET")
        || fieldName.equals("uS1120BalanceSheet"))
      return uS1120BalanceSheet;
    else if (fieldName.equalsIgnoreCase("US_1120_BALANCE_SHEET_NAME")
        || fieldName.equals("uS1120BalanceSheetName"))
      return uS1120BalanceSheetName;
    else if (fieldName.equalsIgnoreCase("PROFIT_AND_LOSS") || fieldName.equals("profitAndLoss"))
      return profitAndLoss;
    else if (fieldName.equalsIgnoreCase("PROFIT_AND_LOSS_NAME")
        || fieldName.equals("profitAndLossName"))
      return profitAndLossName;
    else if (fieldName.equalsIgnoreCase("US_1120_INCOME_STATEMENT")
        || fieldName.equals("uS1120IncomeStatement"))
      return uS1120IncomeStatement;
    else if (fieldName.equalsIgnoreCase("US_1120_INCOME_STATEMENT_NAME")
        || fieldName.equals("uS1120IncomeStatementName"))
      return uS1120IncomeStatementName;
    else if (fieldName.equalsIgnoreCase("CASH_FLOW") || fieldName.equals("cashFlow"))
      return cashFlow;
    else if (fieldName.equalsIgnoreCase("CASH_FLOW_NAME") || fieldName.equals("cashFlowName"))
      return cashFlowName;
    else if (fieldName.equalsIgnoreCase("C_ELEMENT_VALUE_ID")
        || fieldName.equalsIgnoreCase("CELEMENTVALUEID"))
      return cElementValueId;
    else {
      if (log4j.isDebugEnabled())
        log4j.debug("AccountingValueData - getField - Field does not exist: " + fieldName);
      return null;
    }
  }

  public FieldProvider lineFixedSize(String linea) {
    return null;
  }

  public FieldProvider lineSeparatorFormated(String linea) {
    if (linea.length() < 1)
      return null;
    AccountingValueData AccountingValueData = new AccountingValueData();
    int siguiente = 0;
    int anterior = 0;
    String texto = "";
    for (int i = 0; i < 21; i++) {
      if (siguiente >= linea.length())
        break;
      if ((anterior + 1) < linea.length() && linea.substring(anterior, anterior + 1).equals("\"")) {
        int aux = linea.indexOf("\"", anterior + 1);
        if (aux != -1)
          siguiente = aux;
      }
      siguiente = linea.indexOf(",", siguiente + 1);
      if (siguiente == -1)
        siguiente = linea.length();
      texto = linea.substring(anterior, siguiente);
      // if (anterior==siguiente || anterior==(siguiente-1)) texto="";
      // Comentado por que no sabemos para que sirve
      if (texto.length() > 0) {
        if (texto.charAt(0) == '"')
          texto = texto.substring(1);
        if (texto.charAt(texto.length() - 1) == '"')
          texto = texto.substring(0, texto.length() - 1);
      }
      if (log4j.isDebugEnabled())
        log4j.debug("AccountingValueData - lineSeparatorFormated - i: " + i);
      if (log4j.isDebugEnabled())
        log4j.debug("AccountingValueData - lineSeparatorFormated - texto: " + texto);
      switch (i) {
      case 0:
        AccountingValueData.accountValue = texto;
        break;
      case 1:
        AccountingValueData.accountName = texto;
        break;
      case 2:
        AccountingValueData.accountDescription = texto;
        break;
      case 3:
        AccountingValueData.accountType = texto;
        break;
      case 4:
        AccountingValueData.accountSign = texto;
        break;
      case 5:
        AccountingValueData.accountDocument = texto;
        break;
      case 6:
        AccountingValueData.accountSummary = texto;
        break;
      case 7:
        AccountingValueData.defaultAccount = texto;
        break;
      case 8:
        AccountingValueData.accountParent = texto;
        break;
      case 9:
        AccountingValueData.elementLevel = texto;
        break;
      case 10:
        AccountingValueData.operands = texto;
        break;
      case 11:
        AccountingValueData.balanceSheet = texto;
        break;
      case 12:
        AccountingValueData.balanceSheetName = texto;
        break;
      case 13:
        AccountingValueData.uS1120BalanceSheet = texto;
        break;
      case 14:
        AccountingValueData.uS1120BalanceSheetName = texto;
        break;
      case 15:
        AccountingValueData.profitAndLoss = texto;
        break;
      case 16:
        AccountingValueData.profitAndLossName = texto;
        break;
      case 17:
        AccountingValueData.uS1120IncomeStatement = texto;
        break;
      case 18:
        AccountingValueData.uS1120IncomeStatementName = texto;
        break;
      case 19:
        AccountingValueData.cashFlow = texto;
        break;
      case 20:
        AccountingValueData.cashFlowName = texto;
        break;
      }
      anterior = siguiente + 1;
    }
    return AccountingValueData;
  }
}
