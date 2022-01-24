/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
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

public class DocPayment extends AcctServer {
  private static final long serialVersionUID = 1L;
  static Logger log4j = Logger.getLogger(DocPayment.class);

  private String SeqNo = "0";
  private String SettlementType = "";
  static final BigDecimal ZERO = BigDecimal.ZERO;

  /**
   * Constructor
   * 
   * @param AD_Client_ID
   *          AD_Client_ID
   */
  public DocPayment(String AD_Client_ID, String AD_Org_ID, ConnectionProvider connectionProvider) {
    super(AD_Client_ID, AD_Org_ID, connectionProvider);
  }

  public void loadObjectFieldProvider(ConnectionProvider conn, String AD_Client_ID, String Id)
      throws ServletException {
    setObjectFieldProvider(DocPaymentData.selectRegistro(conn, AD_Client_ID, Id));
  }

  /**
   * Load Specific Document Details
   * 
   * @return true if loadDocumentType was set
   */
  public boolean loadDocumentDetails(FieldProvider[] data, ConnectionProvider conn) {
    DateDoc = data[0].getField("DateTrx");
    ChargeAmt = data[0].getField("ChargedAmt");
    SettlementType = data[0].getField("settlementtype");
    // Contained Objects
    p_lines = loadLines(conn);
    if (log4j.isDebugEnabled())
      log4j.debug("DocPayment - loadDocumentDetails - Lines=" + p_lines.length);
    return false;
  } // loadDocumentDetails

  /**
   * Load Payment Line. Settlement Cancel
   * 
   * @return DocLine Array
   */
  private DocLine[] loadLines(ConnectionProvider conn) {
    ArrayList<Object> list = new ArrayList<Object>();
    DocLinePaymentData[] data = null;
    try {
      data = DocLinePaymentData.select(connectionProvider, Record_ID);
      for (int i = 0; i < data.length; i++) {
        String Line_ID = data[i].cDebtPaymentId;
        DocLine_Payment docLine = new DocLine_Payment(DocumentType, Record_ID, Line_ID);
        docLine.Amount = data[i].getField("amount");
        docLine.WriteOffAmt = data[i].getField("writeoffamt");
        docLine.isReceipt = data[i].getField("isreceipt");
        docLine.isManual = data[i].getField("ismanual");
        docLine.isPaid = data[i].getField("ispaid");
        docLine.loadAttributes(data[i], this);
        docLine.m_Record_Id2 = data[i].cDebtPaymentId;
        docLine.C_Settlement_Generate_ID = data[i].getField("cSettlementGenerateId");
        docLine.C_Settlement_Cancel_ID = data[i].getField("cSettlementCancelId");
        docLine.C_GLItem_ID = data[i].getField("cGlitemId");
        docLine.IsDirectPosting = data[i].getField("isdirectposting");
        docLine.C_Currency_ID_From = data[i].getField("cCurrencyId");
        docLine.conversionDate = data[i].getField("conversiondate");
        docLine.C_INVOICE_ID = data[i].getField("C_INVOICE_ID");
        docLine.C_BPARTNER_ID = data[i].getField("C_BPARTNER_ID");
        docLine.DiscountAmt = data[i].getField("discountamt");
        docLine.C_BANKSTATEMENTLINE_ID = data[i].getField("C_BANKSTATEMENTLINE_ID");
        docLine.C_CASHLINE_ID = data[i].getField("C_CASHLINE_ID");
        try {
          docLine.dpStatus = DocLinePaymentData.getDPStatus(connectionProvider, Record_ID, data[i]
              .getField("cDebtPaymentId"));
        } catch (ServletException e) {
          log4j.error(e);
          docLine.dpStatus = "";
        }
        if (log4j.isDebugEnabled())
          log4j.debug("DocPayment - loadLines - docLine.IsDirectPosting - "
              + docLine.IsDirectPosting);
        list.add(docLine);
      }
    } catch (ServletException e) {
      log4j.warn(e);
    }
    // Return Array
    DocLine[] dl = new DocLine[list.size()];
    list.toArray(dl);
    return dl;
  } // loadLines

  /**
   * Get Source Currency Balance - always zero
   * 
   * @return Zero (always balanced)
   */
  public BigDecimal getBalance() {
    BigDecimal retValue = ZERO;
    return retValue;
  } // getBalance
  

  /**
   * Create Facts (the accounting logic) for STT, APP.
   * 
   * <pre>
   * 
   *  Flow:
   *    1. Currency conversion variations
   *    2. Non manual DPs in settlement
   *       2.1 Cancelled
   *       2.2 Generated
   *    3. Manual DPs in settlement
   *       3.1 Transitory account
   *    4. Conceptos contables (manual sett and cancelation DP)
   *    5. Writeoff
   *    6. Discount
   *    6. Bank in transit
   * 
   * </pre>
   * 
   * @param as
   *          accounting schema
   * @return Fact
   */
  public Fact createFact(AcctSchema as, ConnectionProvider conn, Connection con,
      VariablesSecureApp vars) throws ServletException {
   
    if (log4j.isDebugEnabled())
      log4j.debug("DocPayment - createFact - p_lines.length - " + p_lines.length);
    Fact fact = new Fact(this, as, Fact.POST_Actual);
    String Fact_Acct_Group_ID = SequenceIdData.getUUID();

    // Loop to cover C_Debt_Payment in settlement (SttType != 'I' ||
    // directPosting=Y)
    for (int i = 0; p_lines != null && i < p_lines.length; i++) {
      DocLine_Payment line = (DocLine_Payment) p_lines[i];

      if (log4j.isDebugEnabled())
        log4j.debug("DocPayment - createFact - line.conversionDate - " + line.conversionDate);
      // SZ: we don't use manual Payment or settlement.
      // For manual payment with direct posting = 'N' (no posting occurred at payment creation so no
      // conversion, for currency gain-loss, is needed)
      String convertedAmt = "";
      String finalConvertedAmt = "";
     
     
        // 1. Cancelled Lines are Booked reverse to Bank, If they are Paid. Or 
        // 2. Cancelled Lines are Booked reverse to Writeoffs&Discounts, if any
        // 3. If none of that, a cancelled Line is not Booked. Such a cancelled Line has generated a new settlement. This has to be made shure by preceeding processes!
        // 4. There are NO cancelled Lines that have writeoff or discount and are paid. This has to be made shure by preceeding processes!
        // DR if RECEIPT   , CR if PAYABLE
        // REceivabal      , Liabil.
        // Forderungen     , Verbindlichkeiten
      // TODO Compare to 0 - not with seperator..
        if (line.C_Settlement_Cancel_ID.equals(Record_ID) &&
            (line.isPaid.equals("Y") ||
            ((line.WriteOffAmt != null && !line.WriteOffAmt.equals("") && !line.WriteOffAmt.equals("0") && !line.WriteOffAmt.equals("0.00")) ||
            (line.DiscountAmt != null && !line.DiscountAmt.equals("") && !line.DiscountAmt.equals("0") && !line.DiscountAmt.equals("0.00")))))
        {
          // 1* Amount is calculated and if there is currency conversion
          // variations between dates this change is accounted!!!! See in Method!
          convertedAmt = convertAmount(line.Amount, line.isReceipt.equals("Y"), DateAcct,
              line.conversionDate, line.C_Currency_ID_From, C_Currency_ID, null, as, fact,
              Fact_Acct_Group_ID, conn,line.C_BANKSTATEMENTLINE_ID);

          if (!C_Currency_ID.equals(as.m_C_Currency_ID)) {
            this.MultiCurrency = true;
            // Final conversion needed when currency of the document and currency of the accounting
            // schema are different
            // Conversion-Rounding-Amts
            // If currency-variations between dates this change is accounted!!!! See in Method!
            // if this is a foreign currency Bank Account, never use amts from the Bank - Statement.
            if (DocLinePaymentData.getBabnkAcctCurrency(conn, line.C_BANKSTATEMENTLINE_ID)!=null && !DocLinePaymentData.getBabnkAcctCurrency(conn, line.C_BANKSTATEMENTLINE_ID).equals(as.m_C_Currency_ID))
              finalConvertedAmt = convertAmount(convertedAmt.toString(), line.isReceipt.equals("Y"),
                DateAcct, line.conversionDate, C_Currency_ID, as.m_C_Currency_ID, null, as, fact,
                Fact_Acct_Group_ID, conn,"");
            else
              finalConvertedAmt = convertAmount(convertedAmt.toString(), line.isReceipt.equals("Y"),
                  DateAcct, line.conversionDate, C_Currency_ID, as.m_C_Currency_ID, null, as, fact,
                  Fact_Acct_Group_ID, conn,line.C_BANKSTATEMENTLINE_ID);
          } else
            finalConvertedAmt = convertedAmt.toString();
          // Create the Fact Line
          fact.createLine(line, getAccountBPartner(line.m_C_BPartner_ID, as, line.isReceipt
              .equals("Y"), line.dpStatus, conn), as.m_C_Currency_ID, (line.isReceipt.equals("Y") ? ""
              : finalConvertedAmt), (line.isReceipt.equals("Y") ? finalConvertedAmt : ""),
              Fact_Acct_Group_ID, nextSeqNo(SeqNo), DocumentType, conn);
        }
        else {
          //If none of that, a cancelled Line is not Booked. Such a null-Line is OK
          fact.setNullLinesAllowed(true);
        }
        
        
        if (log4j.isDebugEnabled())
          log4j.debug("DocPayment - createFact - No manual  - isReceipt: " + line.isReceipt);

        // SZ commented out - We don't use manual settlement
    
      // 5* WRITEOFF and Discount calculations
      if (!line.isPaid.equals("Y") && line.C_Settlement_Cancel_ID.equals(Record_ID)) { 
        // Cancelled
        // Offener Posten schließen
        // debt-payments
        String taxAmt;
        String taxAcct="";
        String wodiAcct;
        if (line.WriteOffAmt != null && !line.WriteOffAmt.equals("")
            && !line.WriteOffAmt.equals("0") && !line.WriteOffAmt.equals("0.00")) {
          wodiAcct=DocPaymentData.selectWDAccount(conn,"3",line.C_INVOICE_ID,as.m_C_AcctSchema_ID);
          // Tax-Due(UST) if RECEIPT, Tax-Cred (VSt) if Payable
          if (line.isReceipt.equals("Y")) 
            taxAcct=DocPaymentData.selectWDAccount(conn,"4",line.C_INVOICE_ID,as.m_C_AcctSchema_ID);
          else
            taxAcct=DocPaymentData.selectWDAccount(conn,"5",line.C_INVOICE_ID,as.m_C_AcctSchema_ID);
          taxAmt=DocPaymentData.selectTaxAmount(conn,line.C_INVOICE_ID,line.WriteOffAmt,C_Currency_ID);
          if (taxAmt!= null && !taxAmt.equals("")){
            // Calculation
            BigDecimal WriteoffAmt = new BigDecimal(line.WriteOffAmt).subtract(new BigDecimal(taxAmt));
            //Both Lines:  CR if RECEIPT, DR if PAYABLE
            //Writeoffs
              fact.createLine(line, Account.getAccount(conn, wodiAcct),
                  C_Currency_ID, (line.isReceipt.equals("Y") ? WriteoffAmt.toString() : ""), (line.isReceipt
                      .equals("Y") ? "" : WriteoffAmt).toString(), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
                  DocumentType, conn);
           // Tax
              fact.createLine(line, Account.getAccount(conn,taxAcct),
                  C_Currency_ID, (line.isReceipt.equals("Y") ? taxAmt : ""), (line.isReceipt
                      .equals("Y") ? "" : taxAmt), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
                  DocumentType, conn);
          }
          else
            // The Whole-Writeoff Amount without tax
            fact.createLine(line, Account.getAccount(conn, wodiAcct),
                C_Currency_ID, (line.isReceipt.equals("Y") ? line.WriteOffAmt : ""), (line.isReceipt
                    .equals("Y") ? "" : line.WriteOffAmt), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
                DocumentType, conn);
        }
        //
        // Discounts
        if (line.DiscountAmt != null && !line.DiscountAmt.equals("")
            && !line.DiscountAmt.equals("0") && !line.DiscountAmt.equals("0.00"))  {
          // Tax-Due(UST) if RECEIPT, Tax-Cred (VSt) if Payable
          if (line.isReceipt.equals("Y")) {
            taxAcct=DocPaymentData.selectWDAccount(conn,"4",line.C_INVOICE_ID,as.m_C_AcctSchema_ID);
            wodiAcct=DocPaymentData.selectWDAccount(conn,"1",line.C_INVOICE_ID,as.m_C_AcctSchema_ID);
          }
          else{
            taxAcct=DocPaymentData.selectWDAccount(conn,"5",line.C_INVOICE_ID,as.m_C_AcctSchema_ID);
            wodiAcct=DocPaymentData.selectWDAccount(conn,"2",line.C_INVOICE_ID,as.m_C_AcctSchema_ID);
          }
          taxAmt=DocPaymentData.selectTaxAmount(conn,line.C_INVOICE_ID,line.DiscountAmt,C_Currency_ID);
          if (taxAmt!= null && !taxAmt.equals("")){
            // Calculation
            BigDecimal DiscountAmt = new BigDecimal(line.DiscountAmt).subtract(new BigDecimal(taxAmt));
            //Both Lines:  CR if RECEIPT, DR if PAYABLE
            //Discounts
              fact.createLine(line, Account.getAccount(conn, wodiAcct),
                  C_Currency_ID, (line.isReceipt.equals("Y") ? DiscountAmt.toString() : ""), (line.isReceipt
                      .equals("Y") ? "" : DiscountAmt).toString(), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
                  DocumentType, conn);
             // Get Bpartner UUID-Into Discount Fact
              DocInvoiceData[] cLocId=DocInvoiceData.selectRegistro(conn, "C726FEC915A54A0995C568555DA5BB3C", line.C_INVOICE_ID);
              if (cLocId!=null && cLocId.length==1) {
            	  String loc=cLocId[0].cBpartnerLocationId;   
            	  FactLine[] fLines = fact.getLines();
            	  for (int ii = 0; ii < fLines.length; ii++) {
			            	  if (line.isReceipt.equals("Y")) {
			            		  fLines[ii].setLocationFromOrg(AD_Org_ID, true, conn);// from Loc
			            		  fLines[ii].setLocationFromBPartner(loc, false, conn); // to Loc
			            	  } else {
			            		  fLines[ii].setLocationFromBPartner(loc, true, conn); // from Loc
			            		  fLines[ii].setLocationFromOrg(AD_Org_ID, false, conn); // to Loc
			            	  }
            	  }
              }   
           // Tax
              fact.createLine(line, Account.getAccount(conn,taxAcct),
                  C_Currency_ID, (line.isReceipt.equals("Y") ? taxAmt : ""), (line.isReceipt
                      .equals("Y") ? "" : taxAmt), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
                  DocumentType, conn);
          }
          else
            // The Whole-Discount Amount without tax
            fact.createLine(line, Account.getAccount(conn, wodiAcct),
                C_Currency_ID, (line.isReceipt.equals("Y") ? line.DiscountAmt : ""), (line.isReceipt
                    .equals("Y") ? "" : line.DiscountAmt), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
                DocumentType, conn);
        }
      }

      // 6* PPA - Bank in transit default, paid DPs, 
      // We don't use manual posting....
      // The Real Payment goes to Transit
      if (line.isPaid.equals("Y") && line.C_Settlement_Cancel_ID.equals(Record_ID)) {
        BigDecimal finalLineAmt = new BigDecimal(line.Amount);
        
        // SZ: Payd Lines do not have discount or writeoff! This has to be made shure by preceeding processes!
        // Logic is: 
        // If received: Bank in Transit CR
        // if paid:     Bank in Transit DR
        
        String finalAmtTo = "";
        if (line.isManual.equals("N") && ! line.C_BANKSTATEMENTLINE_ID.isEmpty()) {         
          // if this is a foreign currency Bank Account, never use amts from the Bank - Statement.
          if (DocLinePaymentData.getBabnkAcctCurrency(conn, line.C_BANKSTATEMENTLINE_ID).equals(as.m_C_Currency_ID))
            finalAmtTo = DocLinePaymentData.getConvertedAmtFromBankstatementline(conn, line.C_BANKSTATEMENTLINE_ID);
          else
            finalAmtTo = getConvertedAmt(finalLineAmt.toString(), line.C_Currency_ID_From,as.m_C_Currency_ID, DateAcct, "", AD_Client_ID, AD_Org_ID, conn);
        } else { // For manual payment with direct posting = 'N' (no posting occurred at payment
          // creation so no conversion, for currency gain-loss, is needed)
          if (line.isManual.equals("N") && ! line.C_CASHLINE_ID.isEmpty())
            finalAmtTo = getConvertedAmt(finalLineAmt.toString(), line.C_Currency_ID_From,as.m_C_Currency_ID, DateAcct, "", AD_Client_ID, AD_Org_ID, conn);
          else
            finalAmtTo = finalLineAmt.toString();
        }
        finalLineAmt = new BigDecimal(finalAmtTo);
        if (finalLineAmt.compareTo(new BigDecimal("0.00")) != 0) {
          if (line.C_BANKSTATEMENTLINE_ID != null && !line.C_BANKSTATEMENTLINE_ID.equals("")) {
            fact.createLine(line,
                getAccountBankStatementLine(line.C_BANKSTATEMENTLINE_ID, as, conn), as.m_C_Currency_ID,
                (line.isReceipt.equals("Y") ? finalAmtTo : ""), (line.isReceipt.equals("Y") ? ""
                    : finalAmtTo), Fact_Acct_Group_ID, "999999", DocumentType, conn);
          }// else if(line.C_CASHLINE_ID!=null &&
          // !line.C_CASHLINE_ID.equals("")) fact.createLine(line,
          // getAccountCashLine(line.C_CASHLINE_ID,
          // as,conn),strcCurrencyId,
          // (line.isReceipt.equals("Y")?finalAmtTo:""),(line.isReceipt.equals("Y")?"":finalAmtTo),
          // Fact_Acct_Group_ID, "999999", DocumentType,conn);
          else
            fact.createLine(line, getAccount(AcctServer.ACCTTYPE_BankInTransitDefault, as, conn),
                as.m_C_Currency_ID, (line.isReceipt.equals("Y") ? finalAmtTo : ""), (line.isReceipt
                    .equals("Y") ? "" : finalAmtTo), Fact_Acct_Group_ID, "999999", DocumentType,
                conn);
        }
      }
    } // END of the C_Debt_Payment loop
    SeqNo = "0";
    if (log4j.isDebugEnabled())
      log4j.debug("DocPayment - createFact - finish");

    return fact;
  }

  /**
   * @return the log4j
   */
  public static Logger getLog4j() {
    return log4j;
  }

  /**
   * @param log4j
   *          the log4j to set
   */
  public static void setLog4j(Logger log4j) {
    DocPayment.log4j = log4j;
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
   * @return the settlementType
   */
  public String getSettlementType() {
    return SettlementType;
  }

  /**
   * @param settlementType
   *          the settlementType to set
   */
  public void setSettlementType(String settlementType) {
    SettlementType = settlementType;
  }

  /**
   * @return the serialVersionUID
   */
  public static long getSerialVersionUID() {
    return serialVersionUID;
  }

  /**
   * @return the zERO
   */
  public static BigDecimal getZERO() {
    return ZERO;
  }

  public String convertAmount(String Amount, boolean isReceipt, String DateAcct,
      String conversionDate, String C_Currency_ID_From, String C_Currency_ID, DocLine line,
      AcctSchema as, Fact fact, String Fact_Acct_Group_ID, ConnectionProvider conn, String bankstatementlineID)
      throws ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Amount:" + Amount + " curr from:" + C_Currency_ID_From + " Curr to:"
          + C_Currency_ID + " convDate:" + conversionDate + " DateAcct:" + DateAcct);
    if (Amount == null || Amount.equals(""))
      Amount = "0";
    if (C_Currency_ID_From.equals(C_Currency_ID))
      return Amount;
    else
      MultiCurrency = true;
    String Amt = getConvertedAmt(Amount, C_Currency_ID_From, C_Currency_ID, conversionDate, "",
        AD_Client_ID, AD_Org_ID, conn);
    if (log4j.isDebugEnabled())
      log4j.debug("Amt:" + Amt);

    String AmtTo =  "";
    if (!bankstatementlineID.isEmpty())
      AmtTo =DocLinePaymentData.getConvertedAmtFromBankstatementline(conn, bankstatementlineID);
    else
      AmtTo =getConvertedAmt(Amount, C_Currency_ID_From, C_Currency_ID, DateAcct, "",AD_Client_ID, AD_Org_ID, conn);
    if (log4j.isDebugEnabled())
      log4j.debug("AmtTo:" + AmtTo);

    BigDecimal AmtDiff = (new BigDecimal(AmtTo)).subtract(new BigDecimal(Amt));
    if (log4j.isDebugEnabled())
      log4j.debug("AmtDiff:" + AmtDiff);

    if (log4j.isDebugEnabled()) {
      log4j.debug("curr from:" + C_Currency_ID_From + " Curr to:" + C_Currency_ID + " convDate:"
          + conversionDate + " DateAcct:" + DateAcct);
      log4j.debug("Amt:" + Amt + " AmtTo:" + AmtTo + " Diff:" + AmtDiff.toString());
    }
      if ((isReceipt && AmtDiff.compareTo(new BigDecimal("0.00")) == 1)
          || (!isReceipt && AmtDiff.compareTo(new BigDecimal("0.00")) == -1)) {
        fact.createLine(line, getAccount(AcctServer.ACCTTYPE_ConvertGainDefaultAmt, as, conn),
            C_Currency_ID, "", AmtDiff.abs().toString(), Fact_Acct_Group_ID, nextSeqNo(SeqNo),
            DocumentType, conn);
      } else {
        fact.createLine(line, getAccount(AcctServer.ACCTTYPE_ConvertChargeDefaultAmt, as, conn),
            C_Currency_ID, AmtDiff.abs().toString(), "", Fact_Acct_Group_ID, nextSeqNo(SeqNo),
            DocumentType, conn);
      }

    return Amt;
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
        log4j.debug("DocPayment - getAccountBPartner - DocumentType = " + DocumentType);
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
      log4j.warn("DocPayment - getAccountBPartner - NO account BPartner=" + cBPartnerId
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
   * Get the account for Accounting Schema
   * 
   * @param strcBankstatementlineId
   *          Line
   * @param as
   *          accounting schema
   * @return Account
   */
  public final Account getAccountBankStatementLine(String strcBankstatementlineId, AcctSchema as,
      ConnectionProvider conn) {
    DocPaymentData[] data = null;
    try {
      data = DocPaymentData.selectBankStatementLineAcct(conn, strcBankstatementlineId, as
          .getC_AcctSchema_ID());
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
      log4j.warn("DocPayment - getAccountBankStatementLine - NO account BankStatementLine="
          + strcBankstatementlineId + ", Record=" + Record_ID);
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
   * Get the account for Accounting Schema
   * 
   * @param strcCashlineId
   *          Line Id
   * @param as
   *          accounting schema
   * @return Account
   */
  public final Account getAccountCashLine(String strcCashlineId, AcctSchema as,
      ConnectionProvider conn) {
    DocPaymentData[] data = null;
    try {
      data = DocPaymentData.selectCashLineAcct(conn, strcCashlineId, as.getC_AcctSchema_ID());
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
      log4j.warn("DocPayment - getAccountCashLine - NO account CashLine=" + strcCashlineId
          + ", Record=" + Record_ID);
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

  public String nextSeqNo(String oldSeqNo) {
    if (log4j.isDebugEnabled())
      log4j.debug("DocPayment - oldSeqNo = " + oldSeqNo);
    BigDecimal seqNo = new BigDecimal(oldSeqNo);
    SeqNo = (seqNo.add(new BigDecimal("10"))).toString();
    if (log4j.isDebugEnabled())
      log4j.debug("DocPayment - nextSeqNo = " + SeqNo);
    return SeqNo;
  }
 
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
