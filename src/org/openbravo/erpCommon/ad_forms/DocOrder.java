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
 * Contributor: Openbravo SL (C) 2001-2006 Openbravo S.L.
 * Parts created by Openbravo are Copyright (C) 2001-2006 Openbravo SL
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

public class DocOrder extends AcctServer {
  private static final long serialVersionUID = 1L;
  static Logger log4jDocOrder = Logger.getLogger(DocOrder.class);



  /**
   * Constructor
   * 
   * @param AD_Client_ID
   *          client
   */
  public DocOrder(String AD_Client_ID, String AD_Org_ID, ConnectionProvider connectionProvider) {
    super(AD_Client_ID, AD_Org_ID, connectionProvider);
  }

  public void loadObjectFieldProvider(ConnectionProvider conn, String AD_Client_ID, String Id)
      throws ServletException {
    setObjectFieldProvider(DocOrderData.selectRegistro(conn, AD_Client_ID, Id));
  }

  /**
   * Load Specific Document Details
   * 
   * @return true if loadDocumentType was set
   */
  public boolean loadDocumentDetails(FieldProvider[] data, ConnectionProvider conn) {
    DateDoc = data[0].getField("DateOrdered");
    TaxIncluded = data[0].getField("IsTaxIncluded");

    // Amounts
    Amounts[AcctServer.AMTTYPE_Gross] = data[0].getField("GrandTotal");
    if (Amounts[AcctServer.AMTTYPE_Gross] == null)
      Amounts[AcctServer.AMTTYPE_Gross] = ZERO.toString();
    Amounts[AcctServer.AMTTYPE_Net] = data[0].getField("TotalLines");
    if (Amounts[AcctServer.AMTTYPE_Net] == null)
      Amounts[AcctServer.AMTTYPE_Net] = ZERO.toString();
    Amounts[AcctServer.AMTTYPE_Charge] = data[0].getField("ChargeAmt");
    if (Amounts[AcctServer.AMTTYPE_Charge] == null)
      Amounts[AcctServer.AMTTYPE_Charge] = ZERO.toString();
    loadDocumentType(); // lines require doc type
    // Contained Objects
    p_lines = loadLines(conn);
    // Log.trace(Log.l5_DData, "Lines=" + p_lines.length + ", Taxes=" +
    // m_taxes.length);
    return true;
  } // loadDocumentDetails

  /**
   * Load Invoice Line
   * 
   * @return DocLine Array
   */
  public DocLine[] loadLines(ConnectionProvider conn) {
    ArrayList<Object> list = new ArrayList<Object>();
    DocLineOrderData[] data = null;
    try {
      data = DocLineOrderData.select(conn, Record_ID);

      //
      for (int i = 0; i < data.length; i++) {
        String Line_ID = data[i].getField("cOrderlineId");
        DocLine docLine = new DocLine(DocumentType, Record_ID, Line_ID);
        docLine.loadAttributes(data[i], this);
        String Qty = data[i].getField("qtyordered");
        docLine.setQty(Qty);
        String LineNetAmt = data[i].getField("linenetamt");
        // BigDecimal PriceList = rs.getBigDecimal("PriceList");
        docLine.setAmount(LineNetAmt);
        list.add(docLine);
      }
      //
    } catch (ServletException e) {
      log4jDocOrder.warn(e);
    }

    // Return Array
    DocLine[] dl = new DocLine[list.size()];
    list.toArray(dl);
    return dl;
  } // loadLines

  
  

  /**
   * Create Facts (the accounting logic) for SOO, POO, POR.
   * 
   * <pre>
   * </pre>
   * 
   * @param as
   *          accounting schema
   * @return Fact
   */
  public Fact createFact(AcctSchema as, ConnectionProvider conn, Connection con,
      VariablesSecureApp vars) throws ServletException {
    
    // Purchase Order
    // SZ: Update auf Produkt/Einkauf (Preis) in c_order_post
    // SZ No Action- Order has no Accounting
   

    // create Fact Header
    Fact fact = new Fact(this, as, Fact.POST_Actual);
    // No Fact Lines  created - that's OK
    fact.setNullLinesAllowed(true);
    return fact;
  } // createFact

  /**
   * @return the log4jDocOrder
   */
  public static Logger getLog4jDocOrder() {
    return log4jDocOrder;
  }

  /**
   * @param log4jDocOrder
   *          the log4jDocOrder to set
   */
  public static void setLog4jDocOrder(Logger log4jDocOrder) {
    DocOrder.log4jDocOrder = log4jDocOrder;
  }

  

  /**
   * @return the serialVersionUID
   */
  public static long getSerialVersionUID() {
    return serialVersionUID;
  }

  /**
   * Update Product Info. - Costing (PriceLastPO) - PO (PriceLastPO)
   * 
   * @param C_AcctSchema_ID
   *          accounting schema
   */
  
  /**
   * Get Document Confirmation
   * 
   * not used
   */
  public boolean getDocumentConfirmation(ConnectionProvider conn, String strRecordId) {
    return true;
  }
  
 public BigDecimal getBalance() {
    return new BigDecimal(0);
  }
  public String getServletInfo() {
    return "Servlet for the accounting";
  } // end of getServletInfo() method
}
