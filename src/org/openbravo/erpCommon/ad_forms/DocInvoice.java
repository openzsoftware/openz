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
 * Contributor: Openbravo SL (C) 2001-2009 Openbravo S.L. 
 * Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
 * Contributor:  Stefan Zimmermann, 01/2011, sz@zimmermann-software.de (SZ)
 * Parts created by Stefan Zimmermann are Copyright (C) 2011 Stefan Zimmermann
 ******************************************************************************
 */
package org.openbravo.erpCommon.ad_forms;

import java.math.*;
import java.sql.Connection;
import java.util.ArrayList;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.SequenceIdData;

public class DocInvoice extends AcctServer {
  private static final long serialVersionUID = 1L;
  static Logger log4jDocInvoice = Logger.getLogger(DocInvoice.class);

  DocTax[] m_taxes = null;
  String SeqNo = "0";

  /**
   * Constructor
   * 
   * @param AD_Client_ID
   *          AD_Client_ID
   */
  public DocInvoice(String AD_Client_ID, String AD_Org_ID, ConnectionProvider connectionProvider) {
    super(AD_Client_ID, AD_Org_ID, connectionProvider);
  }

  public void loadObjectFieldProvider(ConnectionProvider conn, String AD_Client_ID, String Id)
      throws ServletException {
    setObjectFieldProvider(DocInvoiceData.selectRegistro(conn, AD_Client_ID, Id));
  }

  public boolean loadDocumentDetails(FieldProvider[] data, ConnectionProvider conn) {
    DateDoc = data[0].getField("DateInvoiced");
    TaxIncluded = data[0].getField("IsTaxIncluded");
    C_BPartner_Location_ID = data[0].getField("C_BPartner_Location_ID");
    // Amounts
    Amounts[AMTTYPE_Gross] = data[0].getField("GrandTotal");
    if (Amounts[AMTTYPE_Gross] == null)
      Amounts[AMTTYPE_Gross] = "0";
    Amounts[AMTTYPE_Net] = data[0].getField("TotalLines");
    if (Amounts[AMTTYPE_Net] == null)
      Amounts[AMTTYPE_Net] = "0";
    Amounts[AMTTYPE_Charge] = data[0].getField("ChargeAmt");
    if (Amounts[AMTTYPE_Charge] == null)
      Amounts[AMTTYPE_Charge] = "0";

    loadDocumentType(); // lines require doc type
    // Contained Objects
    p_lines = loadLines();
    m_taxes = loadTaxes();
    m_debt_payments = loadDebtPayments();
    return true;

  }

  private DocLine[] loadLines() {
    ArrayList<Object> list = new ArrayList<Object>();
    DocLineInvoiceData[] data = null;
    try {
      if (DocLineInvoiceData.isGrossInvoice(connectionProvider, Record_ID).equals("Y")) {
        data = DocLineInvoiceData.selectGross(connectionProvider, Record_ID);
      } else {
        log4jDocInvoice.debug("############### groupLines = " + groupLines);
        if (groupLines.equals("Y"))
          data = DocLineInvoiceData.selectTotal(connectionProvider, Record_ID);
        else
          data = DocLineInvoiceData.select(connectionProvider, Record_ID);
      }
    } catch (ServletException e) {
      log4jDocInvoice.warn(e);
    }
    if (data == null || data.length == 0)
      return null;
    for (int i = 0; i < data.length; i++) {
      String Line_ID = data[i].cInvoicelineId;
      DocLine_Invoice docLine = new DocLine_Invoice(DocumentType, Record_ID, Line_ID);
      docLine.loadAttributes(data[i], this);
      String Qty = data[i].qtyinvoiced;
      docLine.setQty(Qty);
      String LineNetAmt = data[i].linenetamt;
      String PriceList = data[i].pricelist;
      docLine.setAmount(LineNetAmt, PriceList, Qty);

      list.add(docLine);
    }
    // Return Array
    DocLine[] dl = new DocLine[list.size()];
    list.toArray(dl);
    return dl;
  } // loadLines

  /**
   * @return the log4jDocInvoice
   */
  public static Logger getLog4jDocInvoice() {
    return log4jDocInvoice;
  }

  /**
   * @param log4jDocInvoice
   *          the log4jDocInvoice to set
   */
  public static void setLog4jDocInvoice(Logger log4jDocInvoice) {
    DocInvoice.log4jDocInvoice = log4jDocInvoice;
  }

  /**
   * @return the m_taxes
   */
  public DocTax[] getM_taxes() {
    return m_taxes;
  }

  /**
   * @param m_taxes
   *          the m_taxes to set
   */
  public void setM_taxes(DocTax[] m_taxes) {
    this.m_taxes = m_taxes;
  }

  /**
   * @return the seqNo
   */
  public String getSeqNo() {
    return SeqNo;
  }

  /**
   * @param seqNo
   *          the seqNo to set
   */
  public void setSeqNo(String seqNo) {
    SeqNo = seqNo;
  }

  /**
   * @return the serialVersionUID
   */
  public static long getSerialVersionUID() {
    return serialVersionUID;
  }

  private DocTax[] loadTaxes() {
    ArrayList<Object> list = new ArrayList<Object>();
    DocInvoiceData[] data = null;
    try {
      data = DocInvoiceData.select(connectionProvider, Record_ID);
    } catch (ServletException e) {
      log4jDocInvoice.warn(e);
    }
    log4jDocInvoice.debug("############### Taxes.length = " + data.length);
    //
    for (int i = 0; i < data.length; i++) {
      String C_Tax_ID = data[i].cTaxId;
      String name = data[i].name;
      String rate = data[i].rate;
      String taxBaseAmt = data[i].taxbaseamt;
      String amount = data[i].taxamt;
      String rcAmount = data[i].reversetaxamt;
      //
      DocTax taxLine = new DocTax(C_Tax_ID, name, rate, taxBaseAmt, amount,rcAmount);
      list.add(taxLine);
    }
    // Return Array
    DocTax[] tl = new DocTax[list.size()];
    list.toArray(tl);
    return tl;
  } // loadTaxes

  private DocLine_Payment[] loadDebtPayments() {
    ArrayList<Object> list = new ArrayList<Object>();
    DocInvoiceData[] data = null;
    try {
      data = DocInvoiceData.selectDebtPayments(connectionProvider, Record_ID);
      log4jDocInvoice.debug("############### DebtPayments.length = " + data.length);
      for (int i = 0; i < data.length; i++) {
        //
        String Line_ID = data[i].cDebtPaymentId;
        DocLine_Payment dpLine = new DocLine_Payment(DocumentType, Record_ID, Line_ID);
        log4jDocInvoice.debug(" dpLine.m_Record_Id2 = " + data[i].cDebtPaymentId);
        dpLine.m_Record_Id2 = data[i].cDebtPaymentId;
        dpLine.C_Currency_ID_From = data[i].cCurrencyId;
        dpLine.dpStatus = data[i].status;
        dpLine.isReceipt = data[i].isreceipt;
        dpLine.isPaid = data[i].ispaid;
        dpLine.isManual = data[i].ismanual;
        dpLine.WriteOffAmt = data[i].writeoffamt;
        dpLine.Amount = data[i].amount;
        list.add(dpLine);
      }
    } catch (ServletException e) {
      log4jDocInvoice.warn(e);
    }

    // Return Array
    DocLine_Payment[] tl = new DocLine_Payment[list.size()];
    list.toArray(tl);
    return tl;
  } // loadTaxes

  /**
   * Create Facts (the accounting logic) for ARI, ARC, ARF, API, APC.
   * SZ: corrected :DR/CR interchanged
   * <pre>
   *  ARI, ARF
   *      Receivables     CR
   *      Charge                  DR
   *      TaxDue                  DR
   *      Revenue                 DR
   *  ARC
   *      Receivables             DR
   *      Charge          CR
   *      TaxDue          CR
   *      Revenue         CR
   *  API
   *      Payables                DR
   *      Charge          CR
   *      TaxCredit       CR
   *      Expense         CR
   *  APC
   *      Payables        CR
   *      Charge                  DR
   *      TaxCredit               DR
   *      Expense                 DR
   * </pre>
   * 
   * @param as
   *          accounting schema
   * @return Fact
   */
  public Fact createFact(AcctSchema as, ConnectionProvider conn, Connection con,
      VariablesSecureApp vars) throws ServletException {
    
    log4jDocInvoice.debug("Starting create fact");
    // create Fact Header
    Fact fact = new Fact(this, as, Fact.POST_Actual);
    String Fact_Acct_Group_ID = SequenceIdData.getUUID();
    // Cash based accounting
    if (!as.isAccrual())
      return null;

    // Implementation of Down Payments
    if(DocInvoiceData.isDownPayment(connectionProvider, Record_ID).equals("Y") &&
    		getAccount(AcctServer.ACCTTYPE_DownPayClearing, as, conn)!=null) {
       return createFactDownPayment(as,conn,con,vars);
    }
    // ARI, ARF
    if (DocumentType.equals(AcctServer.DOCTYPE_ARInvoice)
        || DocumentType.equals(AcctServer.DOCTYPE_ARProForma)) {
      log4jDocInvoice.debug("Point 1");
      // Receivables CR
      for (int i = 0; m_debt_payments != null && i < m_debt_payments.length; i++) {
        log4jDocInvoice.debug("m_debt_payments.length : " + m_debt_payments.length);
        if (m_debt_payments[i].isReceipt.equals("Y"))
          fact.createLine(m_debt_payments[i], getAccountBPartner(C_BPartner_ID, as, true,
              m_debt_payments[i].dpStatus, conn), this.C_Currency_ID, getConvertedAmt(
              m_debt_payments[i].Amount, m_debt_payments[i].C_Currency_ID_From, this.C_Currency_ID,
              DateAcct, "", conn), "", Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
//        else
          // SZ 
          // Receivable DR => Schould NOT happen-That must be ARC
//          fact.createLine(m_debt_payments[i], getAccountBPartner(C_BPartner_ID, as, false,
//              m_debt_payments[i].dpStatus, conn), this.C_Currency_ID, "", getConvertedAmt(
//              m_debt_payments[i].Amount, m_debt_payments[i].C_Currency_ID_From, this.C_Currency_ID,
//              DateAcct, "", conn), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
      }
      // Charge DR
      log4jDocInvoice.debug("The first create line");
      fact.createLine(null, getAccount(AcctServer.ACCTTYPE_Charge, as, conn), C_Currency_ID, "",
          getAmount(AcctServer.AMTTYPE_Charge), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType,
          conn);
      // TaxDue DR
      log4jDocInvoice.debug("m_taxes.length: " + m_taxes);
      for (int i = 0; m_taxes != null && i < m_taxes.length; i++) {
        // Normal Tax accounting
        // Reverse Charge only applies on API
        // New docLine created to assign C_Tax_ID value to the entry (DR)
        DocLine docLine = new DocLine(DocumentType, Record_ID, "");
        docLine.m_C_Tax_ID = m_taxes[i].m_C_Tax_ID;
        fact.createLine(docLine, m_taxes[i].getAccount(DocTax.ACCTTYPE_TaxDue, as, conn),
            C_Currency_ID, "", m_taxes[i].m_amount, Fact_Acct_Group_ID, nextSeqNo(SeqNo),
            DocumentType, conn);
      }
      // Revenue DR
      if (p_lines != null && p_lines.length > 0) {
        // Implementing Gross invoices
        if (DocLineInvoiceData.isGrossInvoice(connectionProvider, Record_ID).equals("Y")) {
          for (int i = 0; i < p_lines.length; i++) {
            Account acc = null;
            String validCombination_ID;
            validCombination_ID=DocLineInvoiceData.getPAccountFromTax(conn, p_lines[i].m_C_Tax_ID,p_lines[i].m_AD_Org_ID);
            acc = Account.getAccount(conn, validCombination_ID);
            fact.createLine(p_lines[i], acc, this.C_Currency_ID, "", p_lines[i]
                .getAmount(), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
          }
        } else {
          for (int i = 0; i < p_lines.length; i++)
            fact.createLine(p_lines[i], ((DocLine_Invoice) p_lines[i]).getAccount(
                ProductInfo.ACCTTYPE_P_Revenue, as, conn), this.C_Currency_ID, "", p_lines[i]
                .getAmount(), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
        }
      }
      // Set Locations
      FactLine[] fLines = fact.getLines();
      for (int i = 0; i < fLines.length; i++) {
        if (fLines[i] != null) {
          fLines[i].setLocationFromOrg(fLines[i].getAD_Org_ID(conn), true, conn); // from Loc
          fLines[i].setLocationFromBPartner(C_BPartner_Location_ID, false, conn); // to Loc
        }
      }
    }
    // ARC
    else if (this.DocumentType.equals(AcctServer.DOCTYPE_ARCredit)) {
      log4jDocInvoice.debug("Point 2");
      // Receivables DR
      for (int i = 0; m_debt_payments != null && i < m_debt_payments.length; i++) {
        BigDecimal amount = new BigDecimal(m_debt_payments[i].Amount);
        BigDecimal ZERO = BigDecimal.ZERO;
        fact.createLine(m_debt_payments[i], getAccountBPartner(C_BPartner_ID, as, true,
            m_debt_payments[i].dpStatus, conn), this.C_Currency_ID, "", getConvertedAmt(((amount
            .negate())).toPlainString(), m_debt_payments[i].C_Currency_ID_From, this.C_Currency_ID,
            DateAcct, "", conn), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
      }

      // fact.createLine(null,
      // getAccount(AcctServer.ACCTTYPE_C_Receivable, as,
      // conn),this.C_Currency_ID, "",
      // getAmount(AcctServer.AMTTYPE_Gross), Fact_Acct_Group_ID,
      // nextSeqNo(SeqNo), DocumentType,conn);
      // Charge CR
      fact.createLine(null, getAccount(AcctServer.ACCTTYPE_Charge, as, conn), this.C_Currency_ID,
          getAmount(AcctServer.AMTTYPE_Charge), "", Fact_Acct_Group_ID, nextSeqNo(SeqNo),
          DocumentType, conn);
      // TaxDue CR
      for (int i = 0; m_taxes != null && i < m_taxes.length; i++) {
        // New docLine created to assign C_Tax_ID value to the entry
        DocLine docLine = new DocLine(DocumentType, Record_ID, "");
        docLine.m_C_Tax_ID = m_taxes[i].m_C_Tax_ID;
        fact.createLine(docLine, m_taxes[i].getAccount(DocTax.ACCTTYPE_TaxDue, as, conn),
            this.C_Currency_ID, m_taxes[i].getAmount(), "", Fact_Acct_Group_ID, nextSeqNo(SeqNo),
            DocumentType, conn);
      }
      // Revenue CR
      if (DocLineInvoiceData.isGrossInvoice(connectionProvider, Record_ID).equals("Y")) {
        for (int i = 0; p_lines != null && i < p_lines.length; i++) {
         // Implementing Gross Invoice - Credit Memo
          Account acc = null;
          String validCombination_ID;
          validCombination_ID=DocLineInvoiceData.getPAccountFromTax(conn, p_lines[i].m_C_Tax_ID,p_lines[i].m_AD_Org_ID);
          acc = Account.getAccount(conn, validCombination_ID);
          fact.createLine(p_lines[i], acc, this.C_Currency_ID, p_lines[i].getAmount(),
              "", Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
        }
      } else {
        for (int i = 0; p_lines != null && i < p_lines.length; i++)
          fact.createLine(p_lines[i], ((DocLine_Invoice) p_lines[i]).getAccount(
              ProductInfo.ACCTTYPE_P_Revenue, as, conn), this.C_Currency_ID, p_lines[i].getAmount(),
              "", Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
      }
      // Set Locations
      FactLine[] fLines = fact.getLines();
      for (int i = 0; fLines != null && i < fLines.length; i++) {
        if (fLines[i] != null) {
          fLines[i].setLocationFromOrg(fLines[i].getAD_Org_ID(conn), true, conn); // from Loc
          fLines[i].setLocationFromBPartner(C_BPartner_Location_ID, false, conn); // to Loc
        }
      }
    }
    // API
    else if (this.DocumentType.equals(AcctServer.DOCTYPE_APInvoice)) {
      log4jDocInvoice.debug("Point 3");
      // Liability DR
      for (int i = 0; m_debt_payments != null && i < m_debt_payments.length; i++) {
       // SZ commented out
       // Liability CR => Schould NOT happen-That must be APC
        /* if (m_debt_payments[i].isReceipt.equals("Y"))
           
          fact.createLine(m_debt_payments[i], getAccountBPartner(C_BPartner_ID, as, true,
              m_debt_payments[i].dpStatus, conn), this.C_Currency_ID, getConvertedAmt(
              m_debt_payments[i].Amount, m_debt_payments[i].C_Currency_ID_From, this.C_Currency_ID,
              DateAcct, "", conn), "", Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
        else*/
       // Liability DR
          fact.createLine(m_debt_payments[i], getAccountBPartner(C_BPartner_ID, as, false,
              m_debt_payments[i].dpStatus, conn), this.C_Currency_ID, "", getConvertedAmt(
              m_debt_payments[i].Amount, m_debt_payments[i].C_Currency_ID_From, this.C_Currency_ID,
              DateAcct, "", conn), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
      }

      // fact.createLine(null, getAccount(AcctServer.ACCTTYPE_V_Liability,
      // as, conn),this.C_Currency_ID, "",
      // getAmount(AcctServer.AMTTYPE_Gross), Fact_Acct_Group_ID,
      // nextSeqNo(SeqNo), DocumentType,conn);
      // Charge CR
      fact.createLine(null, getAccount(AcctServer.ACCTTYPE_Charge, as, conn), this.C_Currency_ID,
          getAmount(AcctServer.AMTTYPE_Charge), "", Fact_Acct_Group_ID, nextSeqNo(SeqNo),
          DocumentType, conn);
      // TaxCredit CR
      for (int i = 0; m_taxes != null && i < m_taxes.length; i++) {
        // SZ implemented Reverse Charge of Taxes
        // Applies if reversecharge-Attribute is set.
        String revc = m_taxes[i].getReversecharge(conn,m_taxes[i].m_C_Tax_ID);
        if (revc.equals("Y")) {
       // New docLine created to Hold the Tax-Due-ACCT (USt) , booked reverse (Debit!!)
          DocLine docLine = new DocLine(DocumentType, Record_ID, "");
          docLine.m_C_Tax_ID = m_taxes[i].m_C_Tax_ID;
          fact.createLine(docLine, m_taxes[i].getAccount(DocTax.ACCTTYPE_TaxDue, as, conn),
              C_Currency_ID, "", m_taxes[i].rc_amount, Fact_Acct_Group_ID, nextSeqNo(SeqNo),
              DocumentType, conn);
       // New docLine created to Hold the Tax-Credit-ACCT (VSt) , booked as usual (Credit!!)
          DocLine docLine2 = new DocLine(DocumentType, Record_ID, "");
          docLine2.m_C_Tax_ID = m_taxes[i].m_C_Tax_ID;
          fact.createLine(docLine2, m_taxes[i].getAccount(DocTax.ACCTTYPE_TaxCredit, as, conn),
              C_Currency_ID, m_taxes[i].rc_amount, "", Fact_Acct_Group_ID, nextSeqNo(SeqNo),
              DocumentType, conn);
        } else {
          // New docLine created to assign C_Tax_ID value to the entry
          DocLine docLine = new DocLine(DocumentType, Record_ID, "");
          docLine.m_C_Tax_ID = m_taxes[i].m_C_Tax_ID;
          fact.createLine(docLine, m_taxes[i].getAccount(DocTax.ACCTTYPE_TaxCredit, as, conn),
              C_Currency_ID, m_taxes[i].m_amount, "", Fact_Acct_Group_ID, nextSeqNo(SeqNo),
              DocumentType, conn);
        }
      }
      // Expense CR      
      if (p_lines != null && p_lines.length > 0) {
        // Implementing Gross invoices
        if (DocLineInvoiceData.isGrossInvoice(connectionProvider, Record_ID).equals("Y")) {
          for (int i = 0; i < p_lines.length; i++) {
            Account acc = null;
            String validCombination_ID;
            validCombination_ID=DocLineInvoiceData.getPExpenseAccountFromTaxandFirstProduct(conn,Record_ID, p_lines[i].m_C_Tax_ID,p_lines[i].m_AD_Org_ID);
            acc = Account.getAccount(conn, validCombination_ID);
            fact.createLine(p_lines[i], acc, this.C_Currency_ID,p_lines[i]
                .getAmount(), "",  Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
          }
        } else {
          for (int i = 0; i < p_lines.length; i++)
            fact.createLine(p_lines[i], ((DocLine_Invoice) p_lines[i]).getAccount(
                ProductInfo.ACCTTYPE_P_Expense, as, conn), this.C_Currency_ID, p_lines[i].getAmount(),
                "", Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
        }
      }
      //
      // Set Locations
      FactLine[] fLines = fact.getLines();
      for (int i = 0; fLines != null && i < fLines.length; i++) {
        if (fLines[i] != null) {
          fLines[i].setLocationFromBPartner(C_BPartner_Location_ID, true, conn); // from Loc
          fLines[i].setLocationFromOrg(fLines[i].getAD_Org_ID(conn), false, conn); // to Loc
        }
      }
      updateProductInfo(as.getC_AcctSchema_ID(), conn, con); // only API
    }
    // APC
    else if (this.DocumentType.equals(AcctServer.DOCTYPE_APCredit)) {
      log4jDocInvoice.debug("Point 4");
      // Liability (Verb) CR
      for (int i = 0; m_debt_payments != null && i < m_debt_payments.length; i++) {
        BigDecimal amount = new BigDecimal(m_debt_payments[i].Amount);
        BigDecimal ZERO = BigDecimal.ZERO;
        fact.createLine(m_debt_payments[i], getAccountBPartner(C_BPartner_ID, as, false,
            m_debt_payments[i].dpStatus, conn), this.C_Currency_ID, getConvertedAmt(((amount
            .negate())).toPlainString(), m_debt_payments[i].C_Currency_ID_From, this.C_Currency_ID,
            DateAcct, "", conn), "", Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
      }

      // fact.createLine (null,
      // getAccount(AcctServer.ACCTTYPE_V_Liability, as,
      // conn),this.C_Currency_ID,"", getAmount(AcctServer.AMTTYPE_Gross),
      // Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType,conn);
      // Charge DR
      fact.createLine(null, getAccount(AcctServer.ACCTTYPE_Charge, as, conn), this.C_Currency_ID,
          "", getAmount(AcctServer.AMTTYPE_Charge), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
          DocumentType, conn);
      // TaxCredit DR
      for (int i = 0; m_taxes != null && i < m_taxes.length; i++) {
        // New docLine created to assign C_Tax_ID value to the entry
        DocLine docLine = new DocLine(DocumentType, Record_ID, "");
        docLine.m_C_Tax_ID = m_taxes[i].m_C_Tax_ID;
        fact.createLine(docLine, m_taxes[i].getAccount(DocTax.ACCTTYPE_TaxCredit, as, conn),
            this.C_Currency_ID, "", m_taxes[i].getAmount(), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
            DocumentType, conn);
      }
      // Expense DR
      if (DocLineInvoiceData.isGrossInvoice(connectionProvider, Record_ID).equals("Y")) {
        // Implementing Gross Invoice - Credit Memo
        for (int i = 0; i < p_lines.length; i++) {
          Account acc = null;
          String validCombination_ID;
          validCombination_ID=DocLineInvoiceData.getPExpenseAccountFromTaxandFirstProduct(conn,Record_ID, p_lines[i].m_C_Tax_ID,p_lines[i].m_AD_Org_ID);
          acc = Account.getAccount(conn, validCombination_ID);
          fact.createLine(p_lines[i], acc, this.C_Currency_ID, "", p_lines[i]
              .getAmount(), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn); 
        }
      } else { 
        for (int i = 0; p_lines != null && i < p_lines.length; i++)
          fact.createLine(p_lines[i], ((DocLine_Invoice) p_lines[i]).getAccount(
              ProductInfo.ACCTTYPE_P_Expense, as, conn), this.C_Currency_ID, "", p_lines[i]
              .getAmount(), Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
      }
      // Set Locations
      FactLine[] fLines = fact.getLines();
      for (int i = 0; fLines != null && i < fLines.length; i++) {
        if (fLines[i] != null) {
          fLines[i].setLocationFromBPartner(C_BPartner_Location_ID, true, conn); // from Loc
          fLines[i].setLocationFromOrg(fLines[i].getAD_Org_ID(conn), false, conn); // to Loc
        }
      }
    } else {
      log4jDocInvoice.warn("Doc_Invoice - DocumentType unknown: " + this.DocumentType);
      fact = null;
    }
    SeqNo = "0";
    // Book Down Payments To revenue
    if (DocInvoiceData.isDownPaymentRevenue(conn, Record_ID).equals("Y"))
    	DocInvoiceData.bookDownPayments2Revenue(con, conn, Record_ID, as.getC_AcctSchema_ID(), vars.getUser());
    return fact;
  }// createFact
  
  // Implementing Down Payments
  public Fact createFactDownPayment(AcctSchema as, ConnectionProvider conn, Connection con,
	      VariablesSecureApp vars) throws ServletException {
	// create Fact Header
	Fact fact = new Fact(this, as, Fact.POST_Actual);
	String Fact_Acct_Group_ID = SequenceIdData.getUUID();
	// Down Payments only for ARI Types
	if (DocumentType.equals(AcctServer.DOCTYPE_ARInvoice)||DocumentType.equals(AcctServer.DOCTYPE_ARCredit)) {
	  String cramt="";
	  String dramt="";
	  // ARI: Receivables CR, ARC: Payabvles DR
	  for (int i = 0; m_debt_payments != null && i < m_debt_payments.length; i++) {
	     log4jDocInvoice.debug("m_debt_payments.length : " + m_debt_payments.length);
	     if (m_debt_payments[i].isReceipt.equals("Y")) {
	       String invamt=getConvertedAmt(m_debt_payments[i].Amount, m_debt_payments[i].C_Currency_ID_From, 
	    		                         this.C_Currency_ID,DateAcct, "", conn);
	       if (DocumentType.equals(AcctServer.DOCTYPE_ARInvoice)) 
	    	   cramt= invamt;
	       if (DocumentType.equals(AcctServer.DOCTYPE_ARCredit)) 
	    	   dramt=invamt;
	       fact.createLine(m_debt_payments[i], getAccountBPartner(C_BPartner_ID, as, true,
	    		   m_debt_payments[i].dpStatus, conn), this.C_Currency_ID, cramt, dramt, Fact_Acct_Group_ID,nextSeqNo(SeqNo), DocumentType, conn);
	     }
	   }
	   cramt="";
	   dramt="";
	   // Charges are Irrelevant, 
	   // Tax ACCT is booked when Receipt is done
	   // Tax is booked on Down Payment, too here
	   for (int i = 0; m_taxes != null && i < m_taxes.length; i++) {
	       if (DocumentType.equals(AcctServer.DOCTYPE_ARInvoice)) 
		    	dramt= m_taxes[i].getAmount();
		   if (DocumentType.equals(AcctServer.DOCTYPE_ARCredit)) 
		    	cramt=m_taxes[i].getAmount();
		   DocLine docLine = new DocLine(DocumentType, Record_ID, "");
		   docLine.m_description=docLine.m_description + "Tax Amt";
		   docLine.m_C_Tax_ID = m_taxes[i].m_C_Tax_ID;
		   fact.createLine(docLine, getAccount(AcctServer.ACCTTYPE_DownPayClearing, as, conn), 
           		this.C_Currency_ID, cramt, dramt, Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
		   cramt="";
		   dramt="";
       }
	   // Revenue DR, Expense CR
	   if (p_lines != null && p_lines.length > 0) {
          for (int i = 0; i < p_lines.length; i++) { 
        	  if (DocumentType.equals(AcctServer.DOCTYPE_ARInvoice)) 
   	    	   dramt= p_lines[i].getAmount();
   	          if (DocumentType.equals(AcctServer.DOCTYPE_ARCredit)) 
   	    	   cramt=p_lines[i].getAmount();
            fact.createLine(p_lines[i], getAccount(AcctServer.ACCTTYPE_DownPayClearing, as, conn), 
            		this.C_Currency_ID, cramt, dramt, Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
          }
        }
        // Set Locations
        FactLine[] fLines = fact.getLines();
        for (int i = 0; i < fLines.length; i++) {
          if (fLines[i] != null) {
            fLines[i].setLocationFromOrg(fLines[i].getAD_Org_ID(conn), true, conn); // from Loc
            fLines[i].setLocationFromBPartner(C_BPartner_Location_ID, false, conn); // to Loc
          }
        }
        SeqNo = "0";
        return fact;
	  }
	  else
		  log4jDocInvoice.warn("Doc_Invoice - DocumentType Down Payment unknown: " + DocumentType);
		  return null;
  }

  /**
   * Update Product Info. - Costing (PriceLastInv) - PO (PriceLastInv)
   * 
   * @param C_AcctSchema_ID
   *          accounting schema
   */
  public void updateProductInfo(String C_AcctSchema_ID, ConnectionProvider conn, Connection con) {
    log4jDocInvoice.debug("updateProductInfo - C_Invoice_ID=" + this.Record_ID);

    /**
     * @todo Last.. would need to compare document/last updated date would need to maintain
     *       LastPriceUpdateDate on _PO and _Costing
     */

    // update Product PO info
    // should only be once, but here for every AcctSchema
    // ignores multiple lines with same product - just uses first
    int no = 0;
    try {
      no = DocInvoiceData.updateProductPO(con, conn, Record_ID);
      log4jDocInvoice.debug("M_Product_PO - Updated=" + no);

    } catch (ServletException e) {
      log4jDocInvoice.warn(e);
    }
  } // updateProductInfo

  /**
   * Get Source Currency Balance - subtracts line and tax amounts from total - no rounding
   * 
   * @return positive amount, if total invoice is bigger than lines
   */
  public BigDecimal getBalance() {
    BigDecimal ZERO = new BigDecimal("0");
    BigDecimal retValue = ZERO;
    StringBuffer sb = new StringBuffer(" [");
    // Total
    retValue = retValue.add(new BigDecimal(getAmount(AcctServer.AMTTYPE_Gross)));
    sb.append(getAmount(AcctServer.AMTTYPE_Gross));
    // - Charge
    retValue = retValue.subtract(new BigDecimal(getAmount(AcctServer.AMTTYPE_Charge)));
    sb.append("-").append(getAmount(AcctServer.AMTTYPE_Charge));
    // - Tax
    for (int i = 0; i < m_taxes.length; i++) {
      retValue = retValue.subtract(new BigDecimal(m_taxes[i].getAmount()));
      sb.append("-").append(m_taxes[i].getAmount());
    }
    // - Lines
    for (int i = 0; i < p_lines.length; i++) {
      retValue = retValue.subtract(new BigDecimal(p_lines[i].getAmount()));
      sb.append("-").append(p_lines[i].getAmount());
    }
    sb.append("]");
    //
    log4jDocInvoice.debug("Balance=" + retValue + sb.toString());
    return retValue;
  } // getBalance

  public String nextSeqNo(String oldSeqNo) {
    log4jDocInvoice.debug("DocInvoice - oldSeqNo = " + oldSeqNo);
    BigDecimal seqNo = new BigDecimal(oldSeqNo);
    SeqNo = (seqNo.add(new BigDecimal("10"))).toString();
    log4jDocInvoice.debug("DocInvoice - nextSeqNo = " + SeqNo);
    return SeqNo;
  }

  /**
   * Get the account for Accounting Schema
   * 
   * @param cBPartnerId
   *          business partner id
   * @param as
   *          accounting schema
   * @return Account
   */
  public final Account getAccountBPartner(String cBPartnerId, AcctSchema as, boolean isReceipt,
      String dpStatus, ConnectionProvider conn) {
    DocPaymentData[] data = null;
    try {
      if (log4j.isDebugEnabled())
        log4j.debug("DocInvoice - getAccountBPartner - DocumentType = " + DocumentType);
      if (isReceipt) {
        data = DocPaymentData.selectBPartnerCustomerAcct(conn, cBPartnerId,
            as.getC_AcctSchema_ID());
      } else {
        data = DocPaymentData.selectBPartnerVendorAcct(conn, cBPartnerId, as.getC_AcctSchema_ID());
      }
    } catch (ServletException e) {
      log4j.warn(e);
    }
    // Get Acct
    String Account_ID = "";
    if (data != null && data.length != 0) {
      Account_ID = data[0].accountId;
    } else
      return null;
    // No account
    if (Account_ID.equals("")) {
      log4j.warn("DocInvoice - getAccountBPartner - NO account BPartner=" + cBPartnerId
          + ", Record=" + Record_ID + ", status " + dpStatus);
      return null;
    }
    // Return Account
    Account acct = null;
    try {
      acct = Account.getAccount(conn, Account_ID);
    } catch (ServletException e) {
      log4j.warn(e);
    }
    return acct;
  } // getAccount

  /**
   * Get Document Confirmation
   * 
   * not used
   */
  public boolean getDocumentConfirmation(ConnectionProvider conn, String strRecordId) {
    return true;
  }

  public String getServletInfo() {
    return "Servlet for the accounting";
  } // end of getServletInfo() method
}
