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
 * All portions are Copyright (C) 2001-2006 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.ws.externalSales;

public class Order {

  private OrderIdentifier orderId;
  private OrderLine[] lines;
  private int state;
  private BPartner businessPartner;
  private Payment[] payments;

  /** Creates a new instance of Order */
  public Order() {
  }

  public OrderIdentifier getOrderId() {
    return orderId;
  }

  public void setOrderId(OrderIdentifier orderId) {
    this.orderId = orderId;
  }

  public OrderLine[] getLines() {
    return lines;
  }

  public void setLines(OrderLine[] lines) {
    this.lines = lines;
  }

  public int getState() {
    return state;
  }

  public void setState(int state) {
    this.state = state;
  }

  public BPartner getBusinessPartner() {
    return businessPartner;
  }

  public void setBusinessPartner(BPartner businessPartner) {
    this.businessPartner = businessPartner;
  }

  public Payment[] getPayment() {
    return payments;
  }

  public void setPayment(Payment[] payments) {
    this.payments = payments;
  }

}
