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

import java.io.IOException;
import java.math.*;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Vector;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.exception.NoConnectionAvailableException;

public abstract class AcctServer {
  static Logger log4j = Logger.getLogger(AcctServer.class);

  protected ConnectionProvider connectionProvider;

  public String batchSize = "100";

  public BigDecimal ZERO = new BigDecimal("0");

  public String groupLines = "";
  public String Qty = null;
  public String tableName = "";
  public String strDateColumn = "";
  public String AD_Table_ID = "";
  public String AD_Client_ID = "";
  public String AD_Org_ID = "";
  public String Status = "";
  public String C_BPartner_ID = "";
  public String C_BPartner_Location_ID = "";
  public String M_Product_ID = "";
  public String AD_OrgTrx_ID = "";
  public String C_SalesRegion_ID = "";
  public String C_Project_ID = "";
  public String C_Campaign_ID = "";
  public String C_Activity_ID = "";
  public String C_LocFrom_ID = "";
  public String C_LocTo_ID = "";
  public String User1_ID = "";
  public String User2_ID = "";
  public String Name = "";
  public String DocumentNo = "";
  public String Errm="";
  public String DateAcct = "";
  public String DateDoc = "";
  public String C_Period_ID = "";
  public String C_Currency_ID = "";
  public String C_DocType_ID = "";
  public String C_Charge_ID = "";
  public String ChargeAmt = "";
  public String C_BankAccount_ID = "";
  public String C_CashBook_ID = "";
  public String M_Warehouse_ID = "";
  public String Posted = "";
  public String DocumentType = "";
  public String TaxIncluded = "";
  public String GL_Category_ID = "";
  public String Record_ID = "";
  /** No Currency in Document Indicator */
  protected static final String NO_CURRENCY = "-1";
  // This is just for the initialization of the accounting
  public String m_IsOpening = "N";

  public Fact[] m_fact = null;
  public AcctSchema[] m_as = null;

  private FieldProvider objectFieldProvider[];

  public String[] Amounts = new String[4];

  public DocLine[] p_lines = new DocLine[0];
  public DocLine_Payment[] m_debt_payments = new DocLine_Payment[0];

  /**
   * Is (Source) Multi-Currency Document - i.e. the document has different currencies (if true, the
   * document will not be source balanced)
   */
  public boolean MultiCurrency = false;

  /** Amount Type - Invoice */
  public static final int AMTTYPE_Gross = 0;
  public static final int AMTTYPE_Net = 1;
  public static final int AMTTYPE_Charge = 2;
  /** Amount Type - Allocation */
  public static final int AMTTYPE_Invoice = 0;
  public static final int AMTTYPE_Allocation = 1;
  public static final int AMTTYPE_Discount = 2;
  public static final int AMTTYPE_WriteOff = 3;

  /** Document Status */
  public static final String STATUS_NotPosted = "N";
  /** Document Status */
  public static final String STATUS_NotBalanced = "b";
  /** Document Status */
  public static final String STATUS_NotConvertible = "c";
  /** Document Status */
  public static final String STATUS_PeriodClosed = "p";
  /** Document Status */
  public static final String STATUS_InvalidAccount = "i";
  /** Document Status */
  public static final String STATUS_PostPrepared = "y";
  /** Document Status */
  public static final String STATUS_Posted = "Y";
  /** Document Status */
  public static final String STATUS_Error = "E";
  /** Document Status */
  public static final String STATUS_InvalidCost = "C";
  /** Document Status */
  public static final String STATUS_DocumentLocked = "L";

  /** AR Invoices */
  public static final String DOCTYPE_ARInvoice = "ARI";
  /** AR Credit Memo */
  public static final String DOCTYPE_ARCredit = "ARC";
  /** AR Receipt */
  public static final String DOCTYPE_ARReceipt = "STT";// antes ARR
  /** AR ProForma */
  public static final String DOCTYPE_ARProForma = "ARF";

  /** AP Invoices */
  public static final String DOCTYPE_APInvoice = "API";
  /** AP Credit Memo */
  public static final String DOCTYPE_APCredit = "APC";
  /** AP Payment */
  public static final String DOCTYPE_APPayment = "APP";

  /** CashManagement Bank Statement */
  public static final String DOCTYPE_BankStatement = "CMB";
  /** CashManagement Cash Journals */
  public static final String DOCTYPE_CashJournal = "CMC";
  /** CashManagement Allocations */
  public static final String DOCTYPE_Allocation = "CMA";

  /** Amortization */
  public static final String DOCTYPE_Amortization = "AMZ";

  /** Material Shipment */
  public static final String DOCTYPE_MatShipment = "MMS";
  /** Material Receipt */
  public static final String DOCTYPE_MatReceipt = "MMR";
  /** Material Inventory */
  public static final String DOCTYPE_MatInventory = "MMI";
  /** Material Movement */
  public static final String DOCTYPE_MatMovement = "MMM";
  /** Material Production */
  public static final String DOCTYPE_MatProduction = "MMP";

  /** Match Invoice */
  public static final String DOCTYPE_MatMatchInv = "MXI";
  /** Match PO */
  public static final String DOCTYPE_MatMatchPO = "MXP";

  /** GL Journal */
  public static final String DOCTYPE_GLJournal = "GLJ";

  /** Purchase Order */
  public static final String DOCTYPE_POrder = "POO";
  /** Sales Order */
  public static final String DOCTYPE_SOrder = "SOO";

  // DPManagement
  public static final String DOCTYPE_DPManagement = "DPM";

  /*************************************************************************/

  /** Account Type - Invoice */
  public static final String ACCTTYPE_Charge = "0";
  public static final String ACCTTYPE_C_Receivable = "1";
  public static final String ACCTTYPE_V_Liability = "2";
  public static final String ACCTTYPE_V_Liability_Services = "3";
  public static final String ACCTTYPE_DownPayClearing = "4";

  /** Account Type - Payment */
  public static final String ACCTTYPE_UnallocatedCash = "10";
  public static final String ACCTTYPE_BankInTransit = "11";
  public static final String ACCTTYPE_PaymentSelect = "12";
  public static final String ACCTTYPE_WriteOffDefault = "13";
  public static final String ACCTTYPE_BankInTransitDefault = "14";
  public static final String ACCTTYPE_ConvertChargeDefaultAmt = "15";
  public static final String ACCTTYPE_ConvertGainDefaultAmt = "16";

  /** Account Type - Cash */
  public static final String ACCTTYPE_CashAsset = "20";
  public static final String ACCTTYPE_CashTransfer = "21";
  public static final String ACCTTYPE_CashExpense = "22";
  public static final String ACCTTYPE_CashReceipt = "23";
  public static final String ACCTTYPE_CashDifference = "24";

  /** Account Type - Allocation */
  public static final String ACCTTYPE_DiscountExp = "30";
  public static final String ACCTTYPE_DiscountRev = "31";
  public static final String ACCTTYPE_WriteOff = "32";

  /** Account Type - Bank Statement */
  public static final String ACCTTYPE_BankAsset = "40";
  public static final String ACCTTYPE_InterestRev = "41";
  public static final String ACCTTYPE_InterestExp = "42";
  public static final String ACCTTYPE_ConvertChargeLossAmt = "43";
  public static final String ACCTTYPE_ConvertChargeGainAmt = "44";

  /** Inventory Accounts */
  public static final String ACCTTYPE_InvDifferences = "50";
  public static final String ACCTTYPE_NotInvoicedReceipts = "51";

  /** Project Accounts */
  public static final String ACCTTYPE_ProjectAsset = "61";
  public static final String ACCTTYPE_ProjectWIP = "62";

  /** GL Accounts */
  public static final String ACCTTYPE_PPVOffset = "60";

  // Reference (to find SalesRegion from BPartner)
  public String BP_C_SalesRegion_ID = ""; // set in FactLine

  public int errors = 0;
  int success = 0;

  /**
   * Cosntructor
   * 
   * @param m_AD_Client_ID
   *          Client ID of these Documents
   * @param connectionProvider
   *          Provider for db connections.
   */
  public AcctServer(String m_AD_Client_ID, String m_AD_Org_ID, ConnectionProvider connectionProvider) {
    AD_Client_ID = m_AD_Client_ID;
    AD_Org_ID = m_AD_Org_ID;
    this.connectionProvider = connectionProvider;
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - LOADING ARRAY: " + m_AD_Client_ID);
    m_as = AcctSchema.getAcctSchemaArray(connectionProvider, m_AD_Client_ID, m_AD_Org_ID);
  } //

  /*
   * Empty constructor to initialize the class using reflexion, set() method should be called
   * afterwards.
   */

  public AcctServer() {

  }

  public void setBatchSize(String newbatchSize) {
    batchSize = newbatchSize;
  }

  public void run(VariablesSecureApp vars) throws IOException, ServletException {
    if (AD_Client_ID.equals(""))
      AD_Client_ID = vars.getClient();
    try {
      Connection con = connectionProvider.getTransactionConnection();
      String strIDs = "";

      if (log4j.isDebugEnabled()) {
        log4j.debug("AcctServer - Run - TableName = " + tableName);
      }

      log4j.debug("AcctServer.run - AD_Client_ID: " + AD_Client_ID);
      AcctServerData[] data = AcctServerData.select(connectionProvider, tableName, AD_Client_ID,
          AD_Org_ID, strDateColumn, 0, Integer.valueOf(batchSize).intValue());

      if (data != null && data.length > 0) {
        if (log4j.isDebugEnabled()) {
          log4j.debug("AcctServer - Run -Select inicial realizada N = " + data.length + " - Key: "
              + data[0].id);
        }
      }

      for (int i = 0; data != null && i < data.length; i++) {
        strIDs += data[i].getField("ID") + ", ";
        if (!post(data[i].getField("ID"), false, vars, connectionProvider, con)) {
          connectionProvider.releaseRollbackConnection(con);
          return;
        } else {
          connectionProvider.releaseCommitConnection(con);
          con = connectionProvider.getTransactionConnection();
        }
      }
      if (log4j.isDebugEnabled() && data != null)
        log4j.debug("AcctServer - Run -" + data.length + " IDs [" + strIDs + "]");
      // Create Automatic Matching
      // match (vars, this,con);
    } catch (NoConnectionAvailableException ex) {
      throw new ServletException("@CODE=NoConnectionAvailable", ex);
    } catch (SQLException ex2) {
      throw new ServletException("@CODE=" + Integer.toString(ex2.getErrorCode()) + "@"
          + ex2.getMessage(), ex2);
    } catch (Exception ex3) {
      log4j.error(ex3.getMessage(), ex3);
    }
  }

  /**
   * Factory - Create Posting document
   * 
   * @param AD_Table_ID
   *          Table ID of Documents
   * @param AD_Client_ID
   *          Client ID of Documents
   * @param connectionProvider
   *          Database connection provider
   * @return Document
   */
  public static AcctServer get(String AD_Table_ID, String AD_Client_ID, String AD_Org_ID,
      ConnectionProvider connectionProvider) throws ServletException {
    AcctServer acct = null;
    if (log4j.isDebugEnabled())
      log4j.debug("get - table: " + AD_Table_ID);
    if (AD_Table_ID.equals("318") || AD_Table_ID.equals("800060") 
        || AD_Table_ID.equals("407") || AD_Table_ID.equals("392") || AD_Table_ID.equals("259")
        || AD_Table_ID.equals("800019") || AD_Table_ID.equals("319") || AD_Table_ID.equals("321")
        || AD_Table_ID.equals("323") || AD_Table_ID.equals("325") 
        || AD_Table_ID.equals("472")) {
      switch (Integer.parseInt(AD_Table_ID)) {
      case 318:
        acct = new DocInvoice(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "C_Invoice";
        acct.AD_Table_ID = "318";
        acct.strDateColumn = "DateAcct";
        acct.reloadAcctSchemaArray();
        acct.groupLines = AcctServerData.selectGroupLines(acct.connectionProvider, AD_Client_ID);
        break;
      /*
       * case 390: acct = new DocAllocation (AD_Client_ID); acct.strDateColumn = "";
       * acct.AD_Table_ID = "390"; acct.reloadAcctSchemaArray(); acct.break;
       */
      case 800060:
        acct = new DocAmortization(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "A_Amortization";
        acct.AD_Table_ID = "800060";
        acct.strDateColumn = "DateAcct";
        acct.reloadAcctSchemaArray();
        break;

     
      case 407:
        acct = new DocCash(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "C_Cash";
        acct.strDateColumn = "DateAcct";
        acct.AD_Table_ID = "407";
        acct.reloadAcctSchemaArray();
        break;
      case 392:
        acct = new DocBank(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "C_Bankstatement";
        acct.strDateColumn = "StatementDate";
        acct.AD_Table_ID = "392";
        acct.reloadAcctSchemaArray();
        break;
      case 259:
        acct = new DocOrder(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "C_Order";
        acct.strDateColumn = "DateAcct";
        acct.AD_Table_ID = "259";
        acct.reloadAcctSchemaArray();
        break;
      case 800019:
        acct = new DocPayment(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "C_Settlement";
        acct.strDateColumn = "Dateacct";
        acct.AD_Table_ID = "800019";
        acct.reloadAcctSchemaArray();
        break;
      case 319:
        acct = new DocInOut(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "M_InOut";
        acct.strDateColumn = "DateAcct";
        acct.AD_Table_ID = "319";
        acct.reloadAcctSchemaArray();
        break;
      case 321:
        acct = new DocInventory(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "M_Inventory";
        acct.strDateColumn = "MovementDate";
        acct.AD_Table_ID = "321";
        acct.reloadAcctSchemaArray();
        break;
      case 323:
        acct = new DocMovement(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "M_Movement";
        acct.strDateColumn = "MovementDate";
        acct.AD_Table_ID = "323";
        acct.reloadAcctSchemaArray();
        break;
      case 325:
        acct = new DocProduction(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "M_Production";
        acct.strDateColumn = "MovementDate";
        acct.AD_Table_ID = "325";
        acct.reloadAcctSchemaArray();
        break;
      case 472:
        acct = new DocMatchInv(AD_Client_ID, AD_Org_ID, connectionProvider);
        acct.tableName = "M_MatchInv";
        acct.strDateColumn = "DateTrx";
        acct.AD_Table_ID = "472";
        acct.reloadAcctSchemaArray();
        break;
      
      }
    } else {
      AcctServerData[] acctinfo = AcctServerData.getTableInfo(connectionProvider, AD_Table_ID);
      if (acctinfo != null && acctinfo.length != 0) {
        if (!acctinfo[0].acctclassname.equals("") && !acctinfo[0].acctdatecolumn.equals("")) {
          try {
            acct = (AcctServer) Class.forName(acctinfo[0].acctclassname).getConstructor().newInstance();
            acct.set(AD_Table_ID, AD_Client_ID, AD_Org_ID, connectionProvider,
                acctinfo[0].tablename, acctinfo[0].acctdatecolumn);
            acct.reloadAcctSchemaArray();
          } catch (Exception e) {
            log4j.error("Error while creating new instance for AcctServer - " + e, e);
          }
        }
      }
    }

    if (acct == null)
      log4j.warn("AcctServer - get - Unknown AD_Table_ID=" + AD_Table_ID);
    else if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - get - AcctSchemaArray length=" + (acct.m_as).length);
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - get - AD_Table_ID=" + AD_Table_ID);
    return acct;
  } // get

  public void set(String m_AD_Table_ID, String m_AD_Client_ID, String m_AD_Org_ID,
      ConnectionProvider connectionProvider, String tablename, String acctdatecolumn) {
    AD_Client_ID = m_AD_Client_ID;
    AD_Org_ID = m_AD_Org_ID;
    this.connectionProvider = connectionProvider;
    tableName = tablename;
    strDateColumn = acctdatecolumn;
    AD_Table_ID = m_AD_Table_ID;
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - LOADING ARRAY: " + m_AD_Client_ID);
    m_as = AcctSchema.getAcctSchemaArray(connectionProvider, m_AD_Client_ID, m_AD_Org_ID);
  }

  public void reloadAcctSchemaArray() throws ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - reloadAcctSchemaArray - " + AD_Table_ID);
    AcctSchema acct = null;
    ArrayList<Object> new_as = new ArrayList<Object>();
    for (int i = 0; i < (this.m_as).length; i++) {
      acct = m_as[i];
      if (AcctSchemaData.selectAcctSchemaTable(connectionProvider, acct.m_C_AcctSchema_ID,
          AD_Table_ID)) {
        new_as.add(new AcctSchema(connectionProvider, acct.m_C_AcctSchema_ID));
      }
    }
    AcctSchema[] retValue = new AcctSchema[new_as.size()];
    new_as.toArray(retValue);
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - RELOADING ARRAY: " + retValue.length);
    this.m_as = retValue;
  }

  private void reloadAcctSchemaArray(String adOrgId) throws ServletException {
    if (log4j.isDebugEnabled())
      log4j
          .debug("AcctServer - reloadAcctSchemaArray - " + AD_Table_ID + ", AD_ORG_ID: " + adOrgId);
    AcctSchema acct = null;
    ArrayList<Object> new_as = new ArrayList<Object>();
    // We reload again all the acct schemas of the client
    m_as = AcctSchema.getAcctSchemaArray(connectionProvider, AD_Client_ID, AD_Org_ID);
    // Filter the right acct schemas for the organization
    for (int i = 0; i < (this.m_as).length; i++) {
      acct = m_as[i];
      if (AcctSchemaData.selectAcctSchemaTable2(connectionProvider, acct.m_C_AcctSchema_ID,
          AD_Table_ID, adOrgId)) {
        new_as.add(new AcctSchema(connectionProvider, acct.m_C_AcctSchema_ID));
      }
    }
    AcctSchema[] retValue = new AcctSchema[new_as.size()];
    new_as.toArray(retValue);
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - RELOADING ARRAY: " + retValue.length);
    this.m_as = retValue;
  }

  public boolean post(String strClave, boolean force, VariablesSecureApp vars,
      ConnectionProvider conn, Connection con) throws ServletException {
    Record_ID = strClave;
    
    if (log4j.isDebugEnabled())
      log4j.debug("post " + strClave + " tablename: " + tableName);
    try {
      if (AcctServerData.update(conn, tableName, strClave) != 1) {
        log4j.warn("AcctServer - Post -Cannot lock Document - ignored: " + tableName + "_ID="
            + strClave);
        // SZ: Added Accounting Error-Log
        Connection econ=conn.getTransactionConnection();
        AcctServerData.insertFactError(econ, conn,AD_Client_ID,AD_Org_ID,"0",DocumentNo,DateAcct,C_DocType_ID,STATUS_DocumentLocked,tableName,strClave,"AcctServer - Post -Cannot lock Document - ignored: " + tableName + "_ID=");
        econ.commit();
        econ.close();
        setStatus(STATUS_DocumentLocked); // Status locked document
        return false;
      } else
        AcctServerData.delete(connectionProvider, AD_Table_ID, Record_ID);
      if (log4j.isDebugEnabled())
        log4j.debug("AcctServer - Post -TableName -" + tableName + "- ad_client_id -"
            + AD_Client_ID + "- " + tableName + "_id -" + strClave);
      try {
        loadObjectFieldProvider(connectionProvider, AD_Client_ID, strClave);
      } catch (ServletException e) {
        log4j.warn(e);
      }
      FieldProvider data[] = getObjectFieldProvider();
      if (getDocumentConfirmation(conn, Record_ID) && post(data, force, vars, conn, con)) {
        success++;
      } else {
        // SZ: Added Accounting Error-Log
        Connection econ=conn.getTransactionConnection();
        AcctServerData.insertFactError(econ, conn,AD_Client_ID,AD_Org_ID,"0",DocumentNo,DateAcct,C_DocType_ID,Status,tableName,strClave,Errm);
        econ.commit();
        econ.close();
        errors++;
        // Status = AcctServer.STATUS_Error;
        save(conn);
      }
      
    } catch (Exception e) {
      log4j.error(e);
      // SZ: Added Accounting Error-Log
      try {
      Connection econ=conn.getTransactionConnection();
      AcctServerData.insertFactError(econ, conn,AD_Client_ID,AD_Org_ID,"0",DocumentNo,DateAcct,C_DocType_ID,Status,tableName,strClave,e.getMessage());
      econ.commit();
      econ.close();
      }
      catch (Exception ex) {
        log4j.error(ex);
      }
      return false;
    } 
    return true;
  }

  private boolean post(FieldProvider[] data, boolean force, VariablesSecureApp vars,
      ConnectionProvider conn, Connection con) throws ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("post data" + C_Currency_ID);
    if (!loadDocument(data, force, conn, con)) {
      log4j.warn("AcctServer - post - Error loading document");
      return false;
    }
    if (data == null || data.length == 0)
      return false;
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - Post - Antes de getAcctSchemaArray - C_CURRENCY_ID = "
    // + C_Currency_ID);
    // Create Fact per AcctSchema
    // if (log4j.isDebugEnabled()) log4j.debug("POSTLOADING ARRAY: " +
    // AD_Client_ID);
    if (!DocumentType.equals(DOCTYPE_GLJournal))
      // m_as = AcctSchema.getAcctSchemaArray(conn, AD_Client_ID, AD_Org_ID);
      reloadAcctSchemaArray(AD_Org_ID);
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - Post - Antes de new Fact - C_CURRENCY_ID = "
    // + C_Currency_ID);
    m_fact = new Fact[m_as.length];

    // for all Accounting Schema
    boolean OK = true;
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - Post -Beforde the loop - C_CURRENCY_ID = " + C_Currency_ID);
    for (int i = 0; OK && i < m_as.length; i++) {
      if (log4j.isDebugEnabled())
        log4j.debug("AcctServer - Post - Before the postLogic - C_CURRENCY_ID = " + C_Currency_ID);
      Status = postLogic(i, conn, con, vars, m_as[i]);
      if (log4j.isDebugEnabled())
        log4j.debug("AcctServer - Post - After postLogic");
      if (!Status.equals(STATUS_Posted))
        return false;
    }
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - Post - Before the postCommit - C_CURRENCY_ID = " + C_Currency_ID);
    for (int i = 0; i < m_fact.length; i++){
      if (m_fact[i] != null && (m_fact[i].getLines() == null || (m_fact[i].getLines().length == 0 && m_fact[i].isNullLinesAllowed()==false)))
        return false;
      //if (m_fact[i].getLines().length == 0 && m_fact[i].isNullLinesAllowed()==true)
      //  return Status.equals(STATUS_Posted);
    }
    // commitFact
    Status = postCommit(Status, conn, vars, con);

    // Create Note
    if (!Status.equals(STATUS_Posted)) {
      // Insert Note
      String AD_Message = "PostingError-" + Status;
      // Text - Only Status
      String Text = Status;
      // API - DocNo - 2000-01-31
      String Reference = DocumentType + " - " + DocumentNo + " - " + DateDoc;
      String AD_User_ID = "0";
      insertNote(AD_Client_ID, AD_Org_ID, AD_User_ID, AD_Table_ID, Record_ID, AD_Message, Text,
          Reference, vars, conn, con);
    }

    // dispose facts
    for (int i = 0; i < m_fact.length; i++)
      if (m_fact[i] != null)
        m_fact[i].dispose();
    p_lines = null;

    return Status.equals(STATUS_Posted);
  } // post

  /**
   * Post Commit. Save Facts & Document
   * 
   * @param status
   *          status
   * @return Posting Status
   */
  private final String postCommit(String status, ConnectionProvider conn, VariablesSecureApp vars,
      Connection con) throws ServletException {
    log4j.debug("AcctServer - postCommit Sta=" + status + " DT=" + DocumentType + " ID="
        + Record_ID);
    Status = status;
    try {
      // *** Transaction Start ***
      // Commit Facts
      if (Status.equals(AcctServer.STATUS_Posted)) {
        if (m_fact != null && m_fact.length != 0) {
          log4j.debug("AcctServer - postCommit - m_fact.length = " + m_fact.length);
          for (int i = 0; i < m_fact.length; i++) {
            if (m_fact[i] != null && m_fact[i].save(con, conn, vars))
              ;
            else {
              // conn.releaseRollbackConnection(con);
              unlock(conn);
              Status = AcctServer.STATUS_Error;
            }
          }
        }
      }
      // Commit Doc
      if (!save(conn)) { // contains unlock
        // conn.releaseRollbackConnection(con);
        unlock(conn);
        // Status = AcctServer.STATUS_Error;
      }
      // conn.releaseCommitConnection(con);
      // *** Transaction End ***
    } catch (Exception e) {
      log4j.warn("AcctServer - postCommit" + e);
      Errm=e.getMessage();
      Status = AcctServer.STATUS_Error;
      // conn.releaseRollbackConnection(con);
      unlock(conn);
    }
    return Status;
  } // postCommit

  /**
   * Save to Disk - set posted flag
   * 
   * @param con
   *          connection
   * @return true if saved
   */
  private final boolean save(ConnectionProvider conn) {
    // if (log4j.isDebugEnabled()) log4j.debug ("AcctServer - save - ->" +
    // Status);
    int no = 0;
    try {
      no = AcctServerData.updateSave(conn, tableName, Status, Record_ID);
    } catch (ServletException e) {
      log4j.warn(e);
    }
    return no == 1;
  } // save

  /**
   * Unlock Document
   */
  private void unlock(ConnectionProvider conn) {
    try {
      AcctServerData.updateUnlock(conn, tableName, Record_ID);
    } catch (ServletException e) {
      log4j.warn("AcctServer - Document locked: -" + e);
    }
  } // unlock

 

  public boolean loadDocument(FieldProvider[] data, boolean force, ConnectionProvider conn,
      Connection con) {
    if (log4j.isDebugEnabled())
      log4j.debug("loadDocument " + data.length);

    setStatus(STATUS_Error);
    Name = "";
    AD_Client_ID = data[0].getField("AD_Client_ID");
    AD_Org_ID = data[0].getField("AD_Org_ID");
    C_BPartner_ID = data[0].getField("C_BPartner_ID");
    M_Product_ID = data[0].getField("M_Product_ID");
    AD_OrgTrx_ID = data[0].getField("AD_OrgTrx_ID");
    C_SalesRegion_ID = data[0].getField("C_SalesRegion_ID");
    C_Project_ID = data[0].getField("C_Project_ID");
    C_Campaign_ID = data[0].getField("C_Campaign_ID");
    C_Activity_ID = data[0].getField("C_Activity_ID");
    C_LocFrom_ID = data[0].getField("C_LocFrom_ID");
    C_LocTo_ID = data[0].getField("C_LocTo_ID");
    User1_ID = data[0].getField("User1_ID");
    User2_ID = data[0].getField("User2_ID");

    Name = data[0].getField("Name");
    DocumentNo = data[0].getField("DocumentNo");
    DateAcct = data[0].getField("DateAcct");
    DateDoc = data[0].getField("DateDoc");
    C_Period_ID = data[0].getField("C_Period_ID");
    C_Currency_ID = data[0].getField("C_Currency_ID");
    C_DocType_ID = data[0].getField("C_DocType_ID");
    C_Charge_ID = data[0].getField("C_Charge_ID");
    ChargeAmt = data[0].getField("ChargeAmt");
    C_BankAccount_ID = data[0].getField("C_BankAccount_ID");
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - loadDocument - C_BankAccount_ID : " + C_BankAccount_ID);
    Posted = data[0].getField("Posted");
    if (!loadDocumentDetails(data, conn))
      loadDocumentType();
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - loadDocument - DocumentDetails Loaded");
    if ((DateAcct == null || DateAcct.equals("")) && (DateDoc != null && !DateDoc.equals("")))
      DateAcct = DateDoc;
    else if ((DateDoc == null || DateDoc.equals("")) && (DateAcct != null && !DateAcct.equals("")))
      DateDoc = DateAcct;
    // DocumentNo (or Name)
    if (DocumentNo == null || DocumentNo.length() == 0)
      DocumentNo = Name;
    // if (DocumentNo == null || DocumentNo.length() ==
    // 0)(DateDoc.equals("") && !DateAcct.equals(""))
    // DocumentNo = "";

    // Check Mandatory Info
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - loadDocument - C_Currency_ID : " +
    // C_Currency_ID);
    String error = "";
    if (AD_Table_ID == null || AD_Table_ID.equals(""))
      error += " AD_Table_ID";
    if (Record_ID == null || Record_ID.equals(""))
      error += " Record_ID";
    if (AD_Client_ID == null || AD_Client_ID.equals(""))
      error += " AD_Client_ID";
    if (AD_Org_ID == null || AD_Org_ID.equals(""))
      error += " AD_Org_ID";
    if (C_Currency_ID == null || C_Currency_ID.equals(""))
      error += " C_Currency_ID";
    if (DateAcct == null || DateAcct.equals(""))
      error += " DateAcct";
    if (DateDoc == null || DateDoc.equals(""))
      error += " DateDoc";
    if (error.length() > 0) {
      log4j.warn("AcctServer - loadDocument - " + DocumentNo + " - Mandatory info missing: "
          + error);
      return false;
    }

    // Delete existing Accounting
    if (force) {
      if (Posted.equals("Y") && !isPeriodOpen()) { // already posted -
        // don't delete if
        // period closed
        log4j.warn("AcctServer - loadDocument - " + DocumentNo
            + " - Period Closed for already posted document");
        return false;
      }
      // delete it
      try {
        AcctServerData.delete(connectionProvider, AD_Table_ID, Record_ID);
      } catch (ServletException e) {
        log4j.warn(e);
      }
      // if (log4j.isDebugEnabled()) log4j.debug("post - deleted=" + no);
    } else if (Posted.equals("Y")) {
      log4j.warn("AcctServer - loadDocument - " + DocumentNo + " - Document already posted");
      return false;
    }
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - loadDocument -finished");
    return true;
  } // loadDocument

  public void loadDocumentType() {
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - loadDocumentType - DocumentType: " +
    // DocumentType + " - C_DocType_ID : " + C_DocType_ID);
    try {
      if (/* DocumentType.equals("") && */C_DocType_ID != null && C_DocType_ID != "") {
        AcctServerData[] data = AcctServerData.selectDocType(connectionProvider, C_DocType_ID);
        DocumentType = data[0].docbasetype;
        GL_Category_ID = data[0].glCategoryId;
      }
      // We have a document Type, but no GL info - search for DocType
      if (GL_Category_ID != null && GL_Category_ID.equals("")) {
        AcctServerData[] data = AcctServerData.selectGLCategory(connectionProvider, AD_Client_ID,
            DocumentType);
        if (data != null && data.length != 0)
          GL_Category_ID = data[0].glCategoryId;
      }
      if (DocumentType != null && DocumentType.equals(""))
        log4j.warn("AcctServer - loadDocumentType - No DocType for GL Info");
      if (GL_Category_ID != null && GL_Category_ID.equals("")) {
        AcctServerData[] data = AcctServerData.selectDefaultGLCategory(connectionProvider,
            AD_Client_ID);
        GL_Category_ID = data[0].glCategoryId;
      }
    } catch (ServletException e) {
      log4j.warn(e);
    }
    if (GL_Category_ID != null && GL_Category_ID.equals(""))
      log4j.warn("AcctServer - loadDocumentType - No GL Info");
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - loadDocumentType -" + tableName + "_ID : "
    // + Record_ID + " - C_DocType_ID: " + C_DocType_ID +
    // " - DocumentType: " + DocumentType);
  }

  public boolean insertNote(String AD_Client_ID, String AD_Org_ID, String AD_User_ID,
      String AD_Table_ID, String Record_ID, String AD_MessageValue, String Text, String Reference,
      VariablesSecureApp vars, ConnectionProvider conn, Connection con) {

    if (AD_MessageValue.equals("") || AD_MessageValue.length() == 0)
      throw new IllegalArgumentException(
          "AcctServer - insertNote - required parameter missing - AD_Message");

    // Database limits
    if (Text == null)
      Text = "";
    if (Text.length() > 2000)
      Text = Text.substring(0, 1999);
    if (Reference == null)
      Reference = "";
    if (Reference.length() > 60)
      Reference = Reference.substring(0, 59);
    //
    // if (log4j.isDebugEnabled()) log4j.debug("AcctServer - insertNote - "
    // + AD_MessageValue + " - " + Reference);
    //
    int no = 0;
    try {
      String AD_Note_ID = SequenceIdData.getUUID();

      // Create Entry
      no = AcctServerData.insertNote(con, conn, AD_Note_ID, AD_Client_ID, AD_Org_ID, AD_User_ID,
          Text, Reference, AD_Table_ID, Record_ID, AD_MessageValue);

      // AD_Message must exist, so if not created, it is probably
      // due to non-existing AD_Message
      if (no == 0) {
        // Try again
        no = AcctServerData.insertNote(con, conn, AD_Note_ID, AD_Client_ID, AD_Org_ID, AD_User_ID,
            Text, Reference, AD_Table_ID, Record_ID, "NoMessageFound");
      }
    } catch (ServletException e) {
      log4j.warn(e);
    }

    return no == 1;
  } // insertNote

  /**
   * Posting logic for Accounting Schema index
   * 
   * @param index
   *          Accounting Schema index
   * @return posting status/error code
   */
  private final String postLogic(int index, ConnectionProvider conn, Connection con,
      VariablesSecureApp vars, AcctSchema as) throws ServletException {
    // rejectUnbalanced
    if (!m_as[index].isSuspenseBalancing() && !isBalanced())
      return STATUS_NotBalanced;

    // rejectUnconvertible
    if (!isConvertible(m_as[index], conn))
      return STATUS_NotConvertible;

    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - Before isPeriodOpen");
    // rejectPeriodClosed
    if (!isPeriodOpen())
      return STATUS_PeriodClosed;
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - After isPeriodOpen");
    // createFacts
    try {
      m_fact[index] = createFact(m_as[index], conn, con, vars);
    } catch (Exception e) {
      log4j.error(e);
      Errm=e.getMessage();
    }
    // SZ If No Lines created  - This is an Error - It happens for example when no account was found
    if (m_fact[index] == null || (m_fact[index].getLines().length==0 && m_fact[index].isNullLinesAllowed()==false)) {
    	Errm="No Lines Created." + Errm;
    	return STATUS_Error;
    }
    if (Status.equals(STATUS_InvalidCost))
      return Status;
    Status = STATUS_PostPrepared;

    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - Before balanceSource");
    // balanceSource
    if (!m_fact[index].isSourceBalanced() && !MultiCurrency)
      m_fact[index].balanceSource(conn);
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - After balanceSource");

    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - Before isSegmentBalanced");
    // balanceSegments
    if (!m_fact[index].isSegmentBalanced(conn) && !MultiCurrency)
      m_fact[index].balanceSegments(conn);
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - After isSegmentBalanced");

    // balanceAccounting
    if (!m_fact[index].isAcctBalanced()){
      // Currency Differences etc..
      m_fact[index].balanceAccounting(conn);     
      //log4j.error("Accounting is not Balanced!! Aborting Acct. " );
      //return AcctServer.STATUS_Error;
    }
      

    // Here processes defined to be executed at posting time, when existing, will be executed
    // SZ removed...

    return STATUS_Posted;
  } // postLogic

  /**
   * Is the Source Document Balanced
   * 
   * @return true if (source) balanced
   */
  public boolean isBalanced() {
    // Multi-Currency documents are source balanced by definition
    if (MultiCurrency)
      return true;
    //
    boolean retValue = (getBalance().compareTo(new BigDecimal("0.00")) == 0);
    if (retValue)
      if (log4j.isDebugEnabled())
        log4j.debug("AcctServer - isBalanced - " + DocumentNo);
      else
        log4j.warn("AcctServer - is not Balanced - " + DocumentNo);
    return retValue;
  } // isBalanced

  /**
   * Is Document convertible to currency and Conversion Type
   * 
   * @param acctSchema
   *          accounting schema
   * @return true, if vonvertable to accounting currency
   */
  public boolean isConvertible(AcctSchema acctSchema, ConnectionProvider conn)
      throws ServletException {
    // No Currency in document
    if (C_Currency_ID.equals("-1")) {
      // if (log4j.isDebugEnabled())
      // log4j.debug("AcctServer - isConvertible (none) - " + DocumentNo);
      return true;
    }
    // Get All Currencies
    Vector<Object> set = new Vector<Object>();
    set.addElement(C_Currency_ID);
    for (int i = 0; p_lines != null && i < p_lines.length; i++) {
      String currency = p_lines[i].m_C_Currency_ID;
      if (currency != null && !currency.equals(""))
        set.addElement(currency);
    }

    // just one and the same
    if (set.size() == 1 && acctSchema.m_C_Currency_ID.equals(C_Currency_ID)) {
      // if (log4j.isDebugEnabled()) log4j.debug
      // ("AcctServer - isConvertible (same) Cur=" + C_Currency_ID + " - "
      // + DocumentNo);
      return true;
    }
    boolean convertible = true;
    for (int i = 0; i < set.size() && convertible == true; i++) {
      // if (log4j.isDebugEnabled()) log4j.debug
      // ("AcctServer - get currency");
      String currency = (String) set.elementAt(i);
      if (currency == null)
        currency = "";
      // if (log4j.isDebugEnabled()) log4j.debug
      // ("AcctServer - currency = " + currency);
      if (!currency.equals(acctSchema.m_C_Currency_ID)) {
        // if (log4j.isDebugEnabled()) log4j.debug
        // ("AcctServer - get converted amount (init)");
        String amt = getConvertedAmt("1", currency, acctSchema.m_C_Currency_ID, DateAcct,
            acctSchema.m_CurrencyRateType, AD_Client_ID, AD_Org_ID, conn);
        // if (log4j.isDebugEnabled()) log4j.debug
        // ("get converted amount (end)");
        if (amt == null) {
          convertible = false;
          log4j.warn("AcctServer - isConvertible NOT from " + currency + " - " + DocumentNo);
        } else if (log4j.isDebugEnabled())
          log4j.debug("AcctServer - isConvertible from " + currency);
      }
    }
    // if (log4j.isDebugEnabled()) log4j.debug
    // ("AcctServer - isConvertible=" + convertible + ", AcctSchemaCur=" +
    // acctSchema.m_C_Currency_ID + " - " + DocumentNo);
    return convertible;
  } // isConvertible

  /**
   * Get the Amount (loaded in loadDocumentDetails)
   * 
   * @param AmtType
   *          see AMTTYPE_*
   * @return Amount
   */
  public String getAmount(int AmtType) {
    if (AmtType < 0 || Amounts == null || AmtType >= Amounts.length)
      return null;
    return (Amounts[AmtType].equals("")) ? "0" : Amounts[AmtType];
  } // getAmount

  /**
   * Get Amount with index 0
   * 
   * @return Amount (primary document amount)
   */
  public String getAmount() {
    return Amounts[0];
  } // getAmount

  /**
   * Convert an amount
   * 
   * @param CurFrom_ID
   *          The C_Currency_ID FROM
   * @param CurTo_ID
   *          The C_Currency_ID TO
   * @param ConvDate
   *          The Conversion date - if null - use current date
   * @param RateType
   *          The Conversion rate type - if null/empty - use Spot
   * @param Amt
   *          The amount to be converted
   * @return converted amount
   */
  public static String getConvertedAmt(String Amt, String CurFrom_ID, String CurTo_ID,
      String ConvDate, String RateType, ConnectionProvider conn) {
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - getConvertedAmount no client nor org");
    return getConvertedAmt(Amt, CurFrom_ID, CurTo_ID, ConvDate, RateType, "", "", conn);
  }

  public static String getConvertedAmt(String Amt, String CurFrom_ID, String CurTo_ID,
      String ConvDate, String RateType, String client, String org, ConnectionProvider conn) {
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - getConvertedAmount - starting method - Amt : " + Amt
          + " - CurFrom_ID : " + CurFrom_ID + " - CurTo_ID : " + CurTo_ID + "- ConvDate: "
          + ConvDate + " - RateType:" + RateType + " - client:" + client + "- org:" + org);

    if (Amt.equals(""))
      throw new IllegalArgumentException(
          "AcctServer - getConvertedAmt - required parameter missing - Amt");
    if (CurFrom_ID.equals(CurTo_ID) || Amt.equals("0"))
      return Amt;
    AcctServerData[] data = null;
    try {
      if (ConvDate != null && ConvDate.equals(""))
        ConvDate = DateTimeData.today(conn);
      // ConvDate IN DATE
      if (RateType == null || RateType.equals(""))
        RateType = "S";
      data = AcctServerData.currencyConvert(conn, Amt, CurFrom_ID, CurTo_ID, ConvDate, RateType,
          client, org);
    } catch (ServletException e) {
      log4j.warn(e);
    }
    if (data == null || data.length == 0) {
      /*
       * log4j.error("No conversion ratio"); throw new
       * ServletException("No conversion ratio defined!");
       */
      return "";
    } else {
      if (log4j.isDebugEnabled())
        log4j.debug("getConvertedAmount - converted:" + data[0].converted);
      return data[0].converted;
    }
  } // getConvertedAmt

  /**
   * Is Period Open
   * 
   * @return true if period is open
   */
  public boolean isPeriodOpen() {
    // if (log4j.isDebugEnabled())
    // log4j.debug(" ***************************** AD_Client_ID - " +
    // AD_Client_ID + " -- DateAcct - " + DateAcct + " -- DocumentType - " +
    // DocumentType);
    setC_Period_ID();
    boolean open = (!C_Period_ID.equals(""));
    if (open) {
      if (log4j.isDebugEnabled())
        log4j.debug("AcctServer - isPeriodOpen - " + DocumentNo);
    } else {
      log4j.warn("AcctServer - isPeriodOpen NO - " + DocumentNo);
    }
    return open;
  } // isPeriodOpen

  /**
   * Calculate Period ID. Set to -1 if no period open, 0 if no period control
   */
  public void setC_Period_ID() {
    if (C_Period_ID != null)
      return;
    if (log4j.isDebugEnabled())
      log4j.debug("AcctServer - setC_Period_ID - AD_Client_ID - " + AD_Client_ID + "--DateAcct - "
          + DateAcct + "--DocumentType -" + DocumentType);
    AcctServerData[] data = null;
    try {
      if (log4j.isDebugEnabled())
        log4j.debug("setC_Period_ID - inside try - AD_Client_ID - " + AD_Client_ID
            + " -- DateAcct - " + DateAcct + " -- DocumentType - " + DocumentType);
      data = AcctServerData.periodOpen(connectionProvider, AD_Client_ID, DocumentType, AD_Org_ID,
          DateAcct);
      C_Period_ID = data[0].period;
      if (log4j.isDebugEnabled())
        log4j.debug("AcctServer - setC_Period_ID - " + AD_Client_ID + "/" + DateAcct + "/"
            + DocumentType + " => " + C_Period_ID);
    } catch (ServletException e) {
      log4j.warn(e);
    }
  } // setC_Period_ID

  /**
   * Matching
   * 
   * <pre>
   *  Derive Invoice-Receipt Match from PO-Invoice and PO-Receipt
   *  Purchase Order (20)
   *  - Invoice1 (10)
   *  - Invoice2 (10)
   *  - Receipt1 (5)
   *  - Receipt2 (15)
   *  (a) Creates Directs
   *      - Invoice1 - Receipt1 (5)
   *      - Invoice2 - Receipt2 (10)
   *  (b) Creates Indirects
   *      - Invoice1 - Receipt2 (5)
   *  (Not imlemented)
   * 
   * 
   * </pre>
   * 
   * @return number of records created
   */
  public int match(VariablesSecureApp vars, ConnectionProvider conn, Connection con) {
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - Match--Starting");
    int counter = 0;
    // (a) Direct Matches
    AcctServerData[] data = null;
    try {
      data = AcctServerData.selectMatch(conn, AD_Client_ID);
      for (int i = 0; i < data.length; i++) {
        BigDecimal qty1 = new BigDecimal(data[i].qty1);
        BigDecimal qty2 = new BigDecimal(data[i].qty2);
        BigDecimal Qty = qty1.min(qty2);
        if (Qty.toString().equals("0"))
          continue;
        // if (log4j.isDebugEnabled())
        // log4j.debug("AcctServer - Match--dateTrx1 :->" + data[i].datetrx1
        // + "Match--dateTrx2: ->" + data[i].datetrx2);
        String dateTrx1 = data[i].datetrx1;
        String dateTrx2 = data[i].datetrx2;
        String compare = "";
        try {
          compare = DateTimeData.compare(conn, dateTrx1, dateTrx2);
        } catch (ServletException e) {
          log4j.warn(e);
        }
        String DateTrx = dateTrx1;
        if (compare.equals("-1"))
          DateTrx = dateTrx2;
        //
        String strQty = Qty.toString();
        String strDateTrx = DateTrx;
        String AD_Client_ID = data[i].adClientId;
        String AD_Org_ID = data[i].adOrgId;
        String C_InvoiceLine_ID = data[i].cInvoicelineId;
        String M_InOutLine_ID = data[i].mInoutlineId;
        String M_Product_ID = data[i].mProductId;
        //
        if (createMatchInv(AD_Client_ID, AD_Org_ID, M_InOutLine_ID, C_InvoiceLine_ID, M_Product_ID,
            strDateTrx, strQty, vars, conn, con) == 1)
          counter++;
      }
    } catch (ServletException e) {
      log4j.warn(e);
    }
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - Matcher.match - Client_ID=" + AD_Client_ID
    // + ", Records created=" + counter);
    return counter;
  } // match

  /**
   * Create MatchInv record
   * 
   * @param AD_Client_ID
   *          Client
   * @param AD_Org_ID
   *          Org
   * @param M_InOutLine_ID
   *          Receipt
   * @param C_InvoiceLine_ID
   *          Invoice
   * @param M_Product_ID
   *          Product
   * @param DateTrx
   *          Date
   * @param Qty
   *          Qty
   * @return true if record created
   */
  private int createMatchInv(String AD_Client_ID, String AD_Org_ID, String M_InOutLine_ID,
      String C_InvoiceLine_ID, String M_Product_ID, String DateTrx, String Qty,
      VariablesSecureApp vars, ConnectionProvider conn, Connection con) {
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - createMatchInv - InvLine=" +
    // C_InvoiceLine_ID + ",Rec=" + M_InOutLine_ID + ", Qty=" + Qty + ", " +
    // DateTrx);
    int no = 0;
    try {
      String M_MatchInv_ID = SequenceIdData.getUUID();
      //
      no = AcctServerData.insertMatchInv(con, conn, M_MatchInv_ID, AD_Client_ID, AD_Org_ID,
          M_InOutLine_ID, C_InvoiceLine_ID, M_Product_ID, DateTrx, Qty);
    } catch (ServletException e) {
      log4j.warn(e);
    }
    return no;
  } // createMatchInv

  /**
   * Get the account for Accounting Schema
   * 
   * @param AcctType
   *          see ACCTTYPE_*
   * @param as
   *          accounting schema
   * @return Account
   */
  public final Account getAccount(String AcctType, AcctSchema as, ConnectionProvider conn) {
    BigDecimal AMT = null;
    AcctServerData[] data = null;
    // if (log4j.isDebugEnabled())
    // log4j.debug("*******************************getAccount 1: AcctType:-->"
    // + AcctType);
    try {
      /** Account Type - Invoice */
      if (AcctType.equals(ACCTTYPE_Charge)) { // see getChargeAccount in
        // DocLine
        // if (log4j.isDebugEnabled())
        // log4j.debug("AcctServer - *******************amount(AMT);-->"
        // + getAmount(AMTTYPE_Charge));
        AMT = new BigDecimal(getAmount(AMTTYPE_Charge));
        // if (log4j.isDebugEnabled())
        // log4j.debug("AcctServer - *******************AMT;-->" + AMT);
        int cmp = AMT.compareTo(BigDecimal.ZERO);
        // if (log4j.isDebugEnabled())
        // log4j.debug("AcctServer - ******************* CMP: " + cmp);
        if (cmp == 0)
          return null;
        else if (cmp < 0)
          data = AcctServerData.selectExpenseAcct(conn, C_Charge_ID, as.getC_AcctSchema_ID());
        else
          data = AcctServerData.selectRevenueAcct(conn, C_Charge_ID, as.getC_AcctSchema_ID());
        // if (log4j.isDebugEnabled())
        // log4j.debug("AcctServer - *******************************getAccount 2");
      } else if (AcctType.equals(ACCTTYPE_V_Liability)) {
        data = AcctServerData.selectLiabilityAcct(conn, C_BPartner_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_V_Liability_Services)) {
        data = AcctServerData.selectLiabilityServicesAcct(conn, C_BPartner_ID, as
            .getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_C_Receivable)) {
        data = AcctServerData.selectReceivableAcct(conn, C_BPartner_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_DownPayClearing)) {
          data = AcctServerData.selectDownPaymentClearingAcct(conn, C_BPartner_ID, as.getC_AcctSchema_ID());  
      } else if (AcctType.equals(ACCTTYPE_UnallocatedCash)) {
        /** Account Type - Payment */
        data = AcctServerData.selectUnallocatedCashAcct(conn, C_BankAccount_ID, as
            .getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_BankInTransit)) {
        data = AcctServerData.selectInTransitAcct(conn, C_BankAccount_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_BankInTransitDefault)) {
        data = AcctServerData.selectInTransitDefaultAcct(conn, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_ConvertChargeDefaultAmt)) {
        data = AcctServerData.selectConvertChargeDefaultAmtAcct(conn, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_ConvertGainDefaultAmt)) {
        data = AcctServerData.selectConvertGainDefaultAmtAcct(conn, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_PaymentSelect)) {
        data = AcctServerData.selectPaymentSelectAcct(conn, C_BankAccount_ID, as
            .getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_WriteOffDefault)) {
        data = AcctServerData.selectWriteOffDefault(conn, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_DiscountExp)) {
        /** Account Type - Allocation */
        data = AcctServerData.selectDiscountExpAcct(conn, C_BPartner_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_DiscountRev)) {
        data = AcctServerData.selectDiscountRevAcct(conn, C_BPartner_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_WriteOff)) {
        data = AcctServerData.selectWriteOffAcct(conn, C_BPartner_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_ConvertChargeLossAmt)) {
        /** Account Type - Bank Statement */
        data = AcctServerData.selectConvertChargeLossAmt(conn, C_BankAccount_ID, as
            .getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_ConvertChargeGainAmt)) {
        data = AcctServerData.selectConvertChargeGainAmt(conn, C_BankAccount_ID, as
            .getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_BankAsset)) {
        data = AcctServerData.selectAssetAcct(conn, C_BankAccount_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_InterestRev)) {
        data = AcctServerData
            .selectInterestRevAcct(conn, C_BankAccount_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_InterestExp)) {
        data = AcctServerData
            .selectInterestExpAcct(conn, C_BankAccount_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_CashAsset)) {
        /** Account Type - Cash */
        data = AcctServerData.selectCBAssetAcct(conn, C_CashBook_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_CashTransfer)) {
        data = AcctServerData.selectCashTransferAcct(conn, C_CashBook_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_CashExpense)) {
        data = AcctServerData.selectCBExpenseAcct(conn, C_CashBook_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_CashReceipt)) {
        data = AcctServerData.selectCBReceiptAcct(conn, C_CashBook_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_CashDifference)) {
        data = AcctServerData.selectCBDifferencesAcct(conn, C_CashBook_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_InvDifferences)) {
        /** Inventory Accounts */
        data = AcctServerData.selectWDifferencesAcct(conn, M_Warehouse_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_NotInvoicedReceipts)) {
        if (log4j.isDebugEnabled())
          log4j.debug("AcctServer - getAccount - ACCTYPE_NotInvoicedReceipts - C_BPartner_ID - "
              + C_BPartner_ID);
        data = AcctServerData.selectNotInvoicedReceiptsAcct(conn, C_BPartner_ID, as
            .getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_ProjectAsset)) {
        /** Project Accounts */
        data = AcctServerData.selectPJAssetAcct(conn, C_Project_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_ProjectWIP)) {
        data = AcctServerData.selectPJWIPAcct(conn, C_Project_ID, as.getC_AcctSchema_ID());
      } else if (AcctType.equals(ACCTTYPE_PPVOffset)) {
        /** GL Accounts */
        data = AcctServerData.selectPPVOffsetAcct(conn, as.getC_AcctSchema_ID());
      } else {
        log4j.warn("AcctServer - getAccount - Not found AcctType=" + AcctType);
        return null;
      }
      // if (log4j.isDebugEnabled())
      // log4j.debug("AcctServer - *******************************getAccount 3");
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
      log4j.warn("AcctServer - getAccount - NO account Type=" + AcctType + ", Record=" + Record_ID);
      return null;
    }
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - *******************************getAccount 4");
    // Return Account
    Account acct = null;
    try {
      acct = Account.getAccount(conn, Account_ID);
    } catch (ServletException e) {
      log4j.warn(e);
    }
    return acct;
  } // getAccount

  public FieldProvider[] getObjectFieldProvider() {
    return objectFieldProvider;
  }

  public void setObjectFieldProvider(FieldProvider[] fieldProvider) {
    objectFieldProvider = fieldProvider;
  }

  public abstract void loadObjectFieldProvider(ConnectionProvider conn, String AD_Client_ID,
      String Id) throws ServletException;

  public abstract boolean loadDocumentDetails(FieldProvider[] data, ConnectionProvider conn);

  /**
   * Get Source Currency Balance - subtracts line (and tax) amounts from total - no rounding
   * 
   * @return positive amount, if total header is bigger than lines
   */
  public abstract BigDecimal getBalance();

  /**
   * Create Facts (the accounting logic)
   * 
   * @param as
   *          accounting schema
   * @return Fact
   */
  public abstract Fact createFact(AcctSchema as, ConnectionProvider conn, Connection con,
      VariablesSecureApp vars) throws ServletException;

  public abstract boolean getDocumentConfirmation(ConnectionProvider conn, String strRecordId);

  public String getInfo(VariablesSecureApp vars) {
    return (Utility.messageBD(connectionProvider, "Created", vars.getLanguage()) + "=" + success
    // + ", " + Utility . messageBD ( this , "Errors" , vars . getLanguage ( ) ) + "=" + errors
    );
  } // end of getInfo() method

  /**
   * @param language
   * @return a String representing the result of created
   */
  public String getInfo(String language) {
    return (Utility.messageBD(connectionProvider, "Created", language) + "=" + success);
  }

  public boolean checkDocuments() throws ServletException {
    if (m_as.length == 0)
      return false;
    AcctServerData[] docTypes = AcctServerData.selectDocTypes(connectionProvider, AD_Table_ID,
        AD_Client_ID);
    // if (log4j.isDebugEnabled())
    // log4j.debug("AcctServer - AcctSchema length-" + (this.m_as).length);
    for (int i = 0; i < docTypes.length; i++) {
      AcctServerData data = AcctServerData.selectDocuments(connectionProvider, tableName,
          AD_Client_ID, AD_Org_ID, docTypes[i].name, strDateColumn);

      if (data != null) {
        if (data.id != null && !data.id.equals("")) {
          if (log4j.isDebugEnabled()) {
            log4j.debug("AcctServer - not posted - " + docTypes[i].name + " document id: "
                + data.id);
          }
          return true;
        }
      }
    }
    return false;
  } // end of checkDocuments() method

  public String getServletInfo() {
    return "Servlet for the accounting";
  } // end of getServletInfo() method

  public String getStatus() {
    return Status;
  }

  public void setStatus(String strStatus) {
    Status = strStatus;
  }

  public ConnectionProvider getConnectionProvider() {
    return connectionProvider;
  }
}
