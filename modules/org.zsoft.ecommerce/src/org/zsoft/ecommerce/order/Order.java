/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.zsoft.ecommerce.order;
import java.util.Date;
import java.math.BigDecimal;
import org.zsoft.ecommerce.*;

public class Order {
  private String  cOrderId;
  
  public String getCOrderId() {
       return cOrderId;
  }
 
  public void setCOrderId(String pcOrderId) {
       cOrderId = pcOrderId;
  }
 
    private String  documentno;
 
  public String getDocumentno() {
       return documentno;
  }
 
  public void setDocumentno(String pdocumentno) {
       documentno = pdocumentno;
  }
 
    private String  docstatus;
 
  public String getDocstatus() {
       return docstatus;
  }
 
  public void setDocstatus(String pdocstatus) {
       docstatus = pdocstatus;
  }
 
    private String  isdelivered;
 
  public String getIsdelivered() {
       return isdelivered;
  }
 
  public void setIsdelivered(String pisdelivered) {
       isdelivered = pisdelivered;
  }
 
    private String  isinvoiced;
 
  public String getIsinvoiced() {
       return isinvoiced;
  }
 
  public void setIsinvoiced(String pisinvoiced) {
       isinvoiced = pisinvoiced;
  }
 
    private String  cBpartnerId;
 
  public String getCBpartnerId() {
       return cBpartnerId;
  }
 
  public void setCBpartnerId(String pcBpartnerId) {
       cBpartnerId = pcBpartnerId;
  }
 
  private String  cBpartnerLocationId;
  
  public String getCBpartnerLocationId() {
       return cBpartnerLocationId;
  }
 
  public void setCBpartnerLocationId(String pcLocationId) {
    cBpartnerLocationId = pcLocationId;
  }
  private String  paymentrule;
  
  public String getPaymentrule() {
       return paymentrule;
  }
 
  public void setPaymentrule(String ppaymentrule) {
       paymentrule = ppaymentrule;
  }
 
    private String  deliveryviarule;
 
  public String getDeliveryviarule() {
       return deliveryviarule;
  }
 
  public void setDeliveryviarule(String pdeliveryviarule) {
       deliveryviarule = pdeliveryviarule;
  }
  private Orderline[]  orderlines;
  
  public Orderline[] getOrderlines() {
       return orderlines;
  }
 
  public void setOrderlines(Orderline[] porderlines) {
    orderlines = porderlines;
  }

}
