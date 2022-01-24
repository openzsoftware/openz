/*
 ******************************************************************************
 * The contents of this file are subject to the   Compiere License  Version 1.1
 * ("License"); You may not use this file except in compliance with the License
 * You may obtain a copy of the License at http://www.compiere.org/license.html
 * Software distributed under the License is distributed on an  "AS IS"  basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 * The Original Code is                  Compiere  ERP & CRM  Business Solution
 * The Initial Developer of the Original Code is Jorg Janke  and ComPiere, Inc.
 * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke, parts
 * created by ComPiere are Copyright (C) ComPiere, Inc.;   All Rights Reserved.
 * Parts created by Openbravo are Copyright (C) 2001-2006 Openbravo SL
 * Contributor:  Stefan Zimmermann, 01/2011, sz@zimmermann-software.de (SZ)
 * Parts created by Stefan Zimmermann are Copyright (C) 2011 Stefan Zimmermann
 ******************************************************************************
 */
package org.openbravo.erpCommon.ad_forms;

import java.math.*;
import java.sql.Connection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;

public class Fact {
  static Logger log4jFact = Logger.getLogger(Fact.class);

  /** Document */
  private AcctServer m_doc = null;

  /** Accounting Schema */
  private AcctSchema m_acctSchema = null;

  /** Posting Type */
  private String m_postingType = null;

  public final BigDecimal ZERO = new BigDecimal("0");

  /** Actual Balance Type */
  public static final String POST_Actual = "A";
  /** Budget Balance Type */
  public static final String POST_Budget = "B";
  /** Encumbrance Posting */
  public static final String POST_Commitment = "C";

  /** Lines */
  private ArrayList<Object> m_lines = new ArrayList<Object>();
  /** Null-Lines allowed?
   * This is to avoid Logging of null-Lines
   * Some facts do not create lines
   * normally null lines are errors an so they are logged*/
  private boolean nullinesAllowed = false;

  /**
   * Constructor
   * 
   * @param document
   *          pointer to document
   * @param acctSchema
   *          Account Schema to create accounts
   * @param defaultPostingType
   *          the default Posting type (actual,..) for this posting
   */
  public Fact(AcctServer document, AcctSchema acctSchema, String defaultPostingType) {
    m_doc = document;
    m_acctSchema = acctSchema;
    m_postingType = defaultPostingType;
    //
    log4jFact.debug("Fact[" + m_doc.DocumentNo + "," + "AcctSchema["
        + m_acctSchema.m_C_AcctSchema_ID + "-" + m_acctSchema.m_Name + ",PostType=" + m_postingType
        + "]");
  } // Fact

  /**
   * Dispose
   */
  public void dispose() {
    for (int i = 0; i < m_lines.size(); i++)
      ((FactLine) m_lines.get(i)).dispose();
    m_lines.clear();
    m_lines = null;
  } // dispose

  /**
   * Create and convert Fact Line. Used to create a DR and/or CR entry
   * 
   * @param docLine
   *          the document line or null
   * @param account
   *          if null, line is not created
   * @param C_Currency_ID
   *          the currency
   * @param debitAmt
   *          debit amount, can be null
   * @param creditAmt
   *          credit amount, can be null
   * @return Fact Line
   */
  // SZ Due to ERROR in Core Financials:
  // Booking-Engine booked on Wrong Side
  // Solution: Toggled CrditAmt and DebitAmt Parameter here
  public FactLine createLine(DocLine docLine, Account account, String C_Currency_ID,
      String creditAmt, String debitAmt, String Fact_Acct_Group_ID, String SeqNo,
      String DocBaseType, ConnectionProvider conn) {

    String strNegate = "";
    try {
      strNegate = AcctServerData.selectNegate(conn, m_acctSchema.m_C_AcctSchema_ID, DocBaseType);
      if (strNegate.equals(""))
        strNegate = AcctServerData.selectDefaultNegate(conn, m_acctSchema.m_C_AcctSchema_ID);
    } catch (ServletException e) {
    }
    if (strNegate.equals(""))
      strNegate = "Y";
    BigDecimal DebitAmt = new BigDecimal(debitAmt.equals("") ? "0.00" : debitAmt);
    BigDecimal CreditAmt = new BigDecimal(creditAmt.equals("") ? "0.00" : creditAmt);
    if (strNegate.equals("N") && (DebitAmt.compareTo(ZERO) < 0 || CreditAmt.compareTo(ZERO) < 0)) {
      return createLine(docLine, account, C_Currency_ID, CreditAmt.abs().toString(), DebitAmt.abs()
          .toString(), Fact_Acct_Group_ID, SeqNo, DocBaseType, conn);
    }

    log4jFact.debug("createLine - " + account + " - Dr=" + debitAmt + ", Cr=" + creditAmt);
    log4jFact.debug("Starting createline");
    // Data Check
    if (account == null) {
      log4jFact.debug("end of create line");
      return null;
    }
    //
    log4jFact.debug("createLine - Fact_Acct_Group_ID = " + Fact_Acct_Group_ID);
    FactLine line = new FactLine(m_doc.AD_Table_ID, m_doc.Record_ID, docLine == null ? ""
        : docLine.m_TrxLine_ID, Fact_Acct_Group_ID, SeqNo, DocBaseType);
    log4jFact.debug("createLine - line.m_Fact_Acct_Group_ID = " + line.m_Fact_Acct_Group_ID);
    log4jFact.debug("Object created");
    line.setDocumentInfo(m_doc, docLine);
    line.setAD_Org_ID(m_doc.AD_Org_ID);
    // if (docLine!=null) line.setAD_Org_ID(docLine.m_AD_Org_ID);
    log4jFact.debug("document info set");
    line.setAccount(m_acctSchema, account);
    log4jFact.debug("account set");

    log4jFact.debug("C_Currency_ID: " + C_Currency_ID + " - debitAmt: " + debitAmt
        + " - creditAmt: " + creditAmt);
    // Amounts - one needs to be both not zero
    if (!line.setAmtSource(C_Currency_ID, debitAmt, creditAmt))
      return null;
    log4jFact.debug("C_Currency_ID: " + m_acctSchema.getC_Currency_ID() + " - DateAcct: "
        + m_doc.DateAcct + " - CurrencyRateType: " + m_acctSchema.getCurrencyRateType());
    // Convert
    line.convert(m_acctSchema.getC_Currency_ID(), m_doc.DateAcct,
        m_acctSchema.getCurrencyRateType(), conn);
    // Optionally overwrite Acct Amount
    if (docLine != null && !docLine.m_AmtAcctDr.equals("") && !docLine.m_AmtAcctCr.equals(""))
      line.setAmtAcct(docLine.m_AmtAcctDr, docLine.m_AmtAcctCr);
    // Info
    line.setJournalInfo(m_doc.GL_Category_ID);
    line.setPostingType(m_postingType);
    // Set Info
    line.setDocumentInfo(m_doc, docLine);
    //
    log4jFact.debug("createLine - " + m_doc.DocumentNo);
    log4jFact.debug("********************* Fact - createLine - DocumentNo - " + m_doc.DocumentNo
        + " -  m_lines.size() - " + m_lines.size());
    m_lines.add(line);
    return line;
  } // createLine

  /**
   * Add Fact Line
   * 
   * @param line
   *          fact line
   */
  void add(FactLine line) {
    m_lines.add(line);
  } // add

  /**
   * Create and convert Fact Line. Used to create either a DR or CR entry
   * 
   * @param docLine
   *          Document Line or null
   * @param accountDr
   *          Account to be used if Amt is DR balance
   * @param accountCr
   *          Account to be used if Amt is CR balance
   * @param C_Currency_ID
   *          Currency
   * @param Amt
   *          if negative Cr else Dr
   * @return FactLine
   */
  public FactLine createLine(DocLine docLine, Account accountDr, Account accountCr,
      String C_Currency_ID, String Amt, String Fact_Acct_Group_ID, String SeqNo,
      String DocBaseType, ConnectionProvider conn) {
    BigDecimal m_Amt = ZERO;
    try {
      if (!Amt.equals(""))
        m_Amt = new BigDecimal(Amt);
    } catch (Exception ex) {
      ex.printStackTrace();
    }
    if (m_Amt.compareTo(ZERO) < 0)
      return createLine(docLine, accountCr, C_Currency_ID, "", m_Amt.abs().toString(),
          Fact_Acct_Group_ID, SeqNo, DocBaseType, conn);
    else
      return createLine(docLine, accountDr, C_Currency_ID, m_Amt.toString(), "",
          Fact_Acct_Group_ID, SeqNo, DocBaseType, conn);
  } // createLine

  /**
   * Create and convert Fact Line. Used to create either a DR or CR entry
   * 
   * @param docLine
   *          Document line or null
   * @param account
   *          Account to be used
   * @param C_Currency_ID
   *          Currency
   * @param Amt
   *          if negative Cr else Dr
   * @return FactLine
   */
  public FactLine createLine(DocLine docLine, Account account, String C_Currency_ID, String Amt,
      String Fact_Acct_Group_ID, String SeqNo, String DocBaseType, ConnectionProvider conn) {
    BigDecimal m_Amt = ZERO;
    try {
      if (!Amt.equals(""))
        m_Amt = new BigDecimal(Amt);
    } catch (Exception ex) {
      ex.printStackTrace();
    }
    if (m_Amt.compareTo(ZERO) < 0)
      return createLine(docLine, account, C_Currency_ID, "", m_Amt.abs().toString(),
          Fact_Acct_Group_ID, SeqNo, DocBaseType, conn);
    else
      return createLine(docLine, account, C_Currency_ID, Amt.toString(), "", Fact_Acct_Group_ID,
          SeqNo, DocBaseType, conn);
  } // createLine

  /**
   * Are the lines Source Balanced
   * 
   * @return true if source lines balanced
   */
  public boolean isSourceBalanced() {
    log4jFact.debug("Starting isSourceBalanced");
    // No lines -> balanded
    if (m_lines == null || m_lines.size() == 0)
      return true;
    BigDecimal balance = getSourceBalance();
    boolean retValue = balance.compareTo(ZERO) == 0;
    if (retValue)
      log4jFact.debug("isSourceBalanced - ");
    else
      log4jFact.warn("isSourceBalanced NO - Balance=" + balance);
    return retValue;
  } // isSourceBalanced

  /**
   * Return Source Balance
   * 
   * @return source balance
   */
  protected BigDecimal getSourceBalance() {
    BigDecimal result = new BigDecimal("0");
    for (int i = 0; i < m_lines.size(); i++) {
      FactLine line = (FactLine) m_lines.get(i);
      result = result.add(line.getSourceBalance());
    }
    // log.debug ("getSourceBalance - " + result.toString());
    return result;
  } // getSourceBalance

  /**
   * Create Source Line for Suspense Balancing. Only if Suspense Balancing is enabled and not a
   * multi-currency document (double check as otherwise the rule should not have fired) If not
   * balanced create balancing entry in currency of the document
   * 
   * @return FactLine
   */
  public FactLine balanceSource(ConnectionProvider conn) {
    if (!m_acctSchema.isSuspenseBalancing() || m_doc.MultiCurrency)
      return null;
    if (m_lines.size() == 0) {
      log4jFact.error("balanceSouce failed.");
      return null;
    }
    FactLine fl = (FactLine) m_lines.get(0);
    BigDecimal diff = getSourceBalance();
    log4jFact.debug("balanceSource = " + diff);
    // new line
    FactLine line = new FactLine(m_doc.AD_Table_ID, m_doc.Record_ID, "", fl.m_Fact_Acct_Group_ID,
        fl.m_SeqNo, fl.m_DocBaseType);// antes
    // "0".
    line.setDocumentInfo(m_doc, null);
    line.setJournalInfo(m_doc.GL_Category_ID);
    line.setPostingType(m_postingType);
    // Amount
    if (diff.compareTo(ZERO) < 0) // negative balance => DR
      line.setAmtSource(m_doc.C_Currency_ID, diff.abs().toString(), ZERO.toString());
    else
      // positive balance => CR
      line.setAmtSource(m_doc.C_Currency_ID, ZERO.toString(), diff.toString());
    // Convert
    line.convert(m_acctSchema.getC_Currency_ID(), m_doc.DateAcct,
        m_acctSchema.getCurrencyRateType(), conn);
    line.setAccount(m_acctSchema, m_acctSchema.getSuspenseBalancing_Acct());
    //
    log4jFact.debug("balanceSource - ");
    log4jFact
        .debug("****************** fact - balancesource -  m_lines.size() - " + m_lines.size());
    m_lines.add(line);
    return line;
  } // balancingSource

  /**
   * Get Lines
   * 
   * @return FactLine Array
   */
  public FactLine[] getLines() {
    FactLine[] temp = new FactLine[m_lines.size()];
    m_lines.toArray(temp);
    return temp;
  } // getLines

  /**
   * Save Fact
   * 
   * @param con
   *          connection
   * @return true if all lines were saved
   */
  public boolean save(Connection con, ConnectionProvider conn, VariablesSecureApp vars)
      throws ServletException {
    // save Lines
    log4jFact.debug(" Fact - save() - m_lines.size - " + m_lines.size());
    if (m_lines.size() == 0)
      return true;
    for (int i = 0; i < m_lines.size(); i++) {
      FactLine fl = (FactLine) m_lines.get(i);
      if (!fl.save(con, conn, vars)) { // abort on first error
        log4jFact.warn("Save (fact): aborted. i=" + i);
        return false;
      }
    }
    return true;
  } // commit

  /**
   * SZ: If null-Lines are explicitly no ERROR
   * 
   * @return true if null-Lines are explicitly no ERROR
   */
  public boolean isNullLinesAllowed() {
      return nullinesAllowed;
  }
  /**
   * SZ: If null-Lines are explicitly no ERROR
   * 
   * @return true if null-Lines are explicitly no ERROR
   */
  public void setNullLinesAllowed(boolean isallowed) {
         nullinesAllowed=isallowed;
  }
  /**
   * Are all segments balanced
   * 
   * @return true if segments are balanced
   */
  public boolean isSegmentBalanced(ConnectionProvider conn) {
    if (m_lines.size() == 0)
      return true;

    ArrayList<Object> elementList = m_acctSchema.m_elementList;
    int size = elementList.size();
    // check all balancing segments
    for (int i = 0; i < size; i++) {
      AcctSchemaElement ase = (AcctSchemaElement) elementList.get(i);
      if (ase.m_balanced.equals("Y") && !isSegmentBalanced(ase.m_segmentType, conn))
        return false;
    }
    return true;
  } // isSegmentBalanced

  /**
   * Is Source Segment balanced.
   * 
   * @param segmentType
   *          - see AcctSchemaElement.SEGMENT_* Implemented only for Org Other sensible candidates
   *          are Project, User1/2
   * @return true if segments are balanced
   */
  public boolean isSegmentBalanced(String segmentType, ConnectionProvider conn) {
    if (segmentType.equals(AcctSchemaElement.SEGMENT_Org)) {
      log4jFact.debug("Starting isSegmentBalanced");
      HashMap<String, BigDecimal> map = new HashMap<String, BigDecimal>();
      // Add up values by key
      for (int i = 0; i < m_lines.size(); i++) {
        FactLine line = (FactLine) m_lines.get(i);
        String key = line.getAD_Org_ID(conn);
        BigDecimal bal = line.getSourceBalance();
        BigDecimal oldBal = map.get(key);
        if (oldBal != null)
          bal = bal.add(oldBal);
        map.put(key, bal);
        // log4jFact.debug("Add Key=" + key + ", Bal=" + bal + " <- " +
        // line);
      }
      // check if all keys are zero
      Iterator<BigDecimal> values = map.values().iterator();
      while (values.hasNext()) {
        BigDecimal bal = values.next();
        if (bal.compareTo(ZERO) != 0) {
          map.clear();
          log4jFact.warn("isSegmentBalanced (" + segmentType + ") NO - " + toString()
              + ", Balance=" + bal);
          return false;
        }
      }
      map.clear();
      log4jFact.debug("isSegmentBalanced (" + segmentType + ") - " + toString());
      return true;
    }
    log4jFact.debug("isSegmentBalanced (" + segmentType + ") (not checked) - " + toString());
    return true;
  } // isSegmentBalanced

  /**
   * Balance all segments. - For all balancing segments - For all segment values - If balance <> 0
   * create dueTo/dueFrom line overwriting the segment value
   */
  public void balanceSegments(ConnectionProvider conn) {
    log4jFact.debug("balanceSegments");
    //
    ArrayList<Object> elementList = m_acctSchema.m_elementList;
    int size = elementList.size();
    // check all balancing segments
    for (int i = 0; i < size; i++) {
      AcctSchemaElement ase = (AcctSchemaElement) elementList.get(i);
      if (ase.m_balanced.equals("Y"))
        balanceSegment(ase.m_segmentType, conn);
    }
  } // balanceSegments

  /**
   * Balance Source Segment
   * 
   * @param segmentType
   *          segment type
   */
  private void balanceSegment(String segmentType, ConnectionProvider conn) {
    // no lines -> balanced
    if (m_lines.size() == 0)
      return;
    log4jFact.debug("balanceSegment (" + segmentType + ") - ");
    // Org
    if (segmentType.equals(AcctSchemaElement.SEGMENT_Org)) {
      HashMap<String, BigDecimal> map = new HashMap<String, BigDecimal>();
      // Add up values by key
      for (int i = 0; i < m_lines.size(); i++) {
        FactLine line = (FactLine) m_lines.get(i);
        String key = line.getAD_Org_ID(conn);
        BigDecimal bal = line.getSourceBalance();
        BigDecimal oldBal = map.get(key);
        if (oldBal != null)
          bal = bal.add(oldBal);
        map.put(key, bal);
      }
      // Create entry for non-zero element
      Iterator<String> keys = map.keySet().iterator();
      while (keys.hasNext()) {
        String key = keys.next();
        BigDecimal diff = map.get(key);
        //
        if (diff.compareTo(ZERO) != 0) {
          // Create Balancing Entry
          if (m_lines.size() == 0) {
            log4jFact.error("balanceSegment failed.");
            return;
          }
          FactLine fl = (FactLine) m_lines.get(0);
          FactLine line = new FactLine(m_doc.AD_Table_ID, m_doc.Record_ID, "",
              fl.m_Fact_Acct_Group_ID, fl.m_SeqNo, fl.m_DocBaseType);
          line.setDocumentInfo(m_doc, null);
          line.setJournalInfo(m_doc.GL_Category_ID);
          line.setPostingType(m_postingType);
          // Amount & Account
          if (diff.compareTo(ZERO) < 0) {
            line.setAmtSource(m_doc.C_Currency_ID, diff.abs().toString(), ZERO.toString());
            line.setAccount(m_acctSchema, m_acctSchema.m_DueFrom_Acct);
          } else {
            line.setAmtSource(m_doc.C_Currency_ID, ZERO.toString(), diff.abs().toString());
            line.setAccount(m_acctSchema, m_acctSchema.m_DueTo_Acct);
          }
          line.convert(m_acctSchema.getC_Currency_ID(), m_doc.DateAcct,
              m_acctSchema.getCurrencyRateType(), conn);
          line.setAD_Org_ID(key);
          log4jFact.debug("balanceSegment (" + segmentType + ") - ");
          log4jFact.debug("************* fact - balanceSegment - m_lines.size() - "
              + m_lines.size() + " - line.ad_org_id - " + line.getAD_Org_ID(conn));
          m_lines.add(line);
        }
      }
      map.clear();
    }
  } // balanceSegment

  /**
   * Are the lines Accounting Balanced
   * 
   * @return true if accounting lines are balanced
   */
  public boolean isAcctBalanced() {
    // no lines -> balanced
    if (m_lines == null || m_lines.size() == 0)
      return true;
    BigDecimal balance = getAcctBalance();
    boolean retValue = balance.compareTo(ZERO) == 0;
    if (retValue)
      log4jFact.debug("isAcctBalanced - ");
    else
      log4jFact.warn("isAcctBalanced NO - Balance=" + balance);
    return retValue;
  } // isAcctBalanced

  /**
   * Return Accounting Balance
   * 
   * @return true if accounting lines are balanced
   */
  protected BigDecimal getAcctBalance() {
    BigDecimal result = ZERO;
    for (int i = 0; i < m_lines.size(); i++) {
      FactLine line = (FactLine) m_lines.get(i);
      BigDecimal balance = new BigDecimal(line.getAcctBalance());
      result = result.add(balance);
    }
    return result;
  } // getAcctBalance

  /**
   * Balance Accounting Currency. If the accounting currency is not balanced, if Currency balancing
   * is enabled create a new line using the currency balancing account with zero source balance or
   * adjust the line with the largest balance sheet account or if no balance sheet account exist,
   * the line with the largest amount
   * 
   * @return FactLine
   */
  public FactLine balanceAccounting(ConnectionProvider conn) {
    BigDecimal diff = getAcctBalance();
    log4jFact.debug("balanceAccounting - Balance=" + diff);
    FactLine line = null;
    // Create Currency Entry
    if (m_acctSchema.isCurrencyBalancing()) {
      if (m_lines.size() == 0) {
        log4jFact.error("balanceAccounting failed.");
        return null;
      }
      FactLine fl = (FactLine) m_lines.get(0);
      line = new FactLine(m_doc.AD_Table_ID, m_doc.Record_ID, "", fl.m_Fact_Acct_Group_ID,
    		  "999998", fl.m_DocBaseType);
      line.setDocumentInfo(m_doc, null);
      line.setJournalInfo(m_doc.GL_Category_ID);
      line.setPostingType(m_postingType);
      // Amount
      line.setAmtSource(m_doc.C_Currency_ID, ZERO.toString(), ZERO.toString());
      line.convert(m_acctSchema.getC_Currency_ID(), m_doc.DateAcct,
          m_acctSchema.getCurrencyRateType(), conn);
      if (diff.compareTo(ZERO) < 0)
        line.setAmtAcct(diff.abs().toString(), ZERO.toString());
      else
        line.setAmtAcct(ZERO.toString(), diff.abs().toString());
      line.setAccount(m_acctSchema, m_acctSchema.getCurrencyBalancing_Acct());
      log4jFact.debug("balanceAccounting - " + line.toString());
      log4jFact
          .debug("************* fact - balanceAccounting - m_lines.size() - " + m_lines.size());
      m_lines.add(line);
    } else { // Adjust biggest (Balance Sheet) line amount
      BigDecimal BSamount = ZERO;
      FactLine BSline = null;
      BigDecimal PLamount = ZERO;
      FactLine PLline = null;

      // Find line
      for (int i = 0; i < m_lines.size(); i++) {
        FactLine l = (FactLine) m_lines.get(i);
        BigDecimal amt = new BigDecimal(l.getAcctBalance());
        amt = amt.abs();
        if (l.isBalanceSheet() && amt.compareTo(BSamount) > 0) {
          BSamount = amt;
          BSline = l;
        } else if (!l.isBalanceSheet() && amt.compareTo(PLamount) > 0) {
          PLamount = amt;
          PLline = l;
        }
      }
      if (BSline != null)
        line = BSline;
      else
        line = PLline;

      if (line == null)
        log4jFact.error("balanceAccounting - No Line found");
      else {
        log4jFact.debug("Adjusting Amt=" + diff.toString() + "; Line=" + line.toString());
        line.currencyCorrect(diff);
        log4jFact.debug("balanceAccounting - " + line.toString());
      }
    } // correct biggest amount

    // Debug info only
    this.isAcctBalanced();

    return line;
  } // balanceAccounting

  public AcctSchema getM_acctSchema() {
    return m_acctSchema;
  }

  public void setM_acctSchema(AcctSchema schema) {
    m_acctSchema = schema;
  }

}
