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
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.sql.Connection;

import org.apache.log4j.Logger;
import org.zsoft.ecommerce.*;


public class OrderServiceV100  extends WebService {
  private static Logger log4j = Logger.getLogger(OrderServiceV100.class);
  
  public OrderResponse submitOrder(String orgId, String username, String password,OrderV100 porder)  throws Exception {
    
    if (!access(username, password,orgId)) {
      if (log4j.isDebugEnabled())
        log4j.debug("Access denied for user: " + username);
      throw new Exception("Access denied for user: " + username); 
    }
    
    String orderid=null;
    String issuccess=null;
    OrderResponse or= new OrderResponse();
    Connection con=pool.getTransactionConnection();
    con.setAutoCommit(false);
    try {
         orderid = OrderData.InsertOrderHeader(con,pool,orgId,username,porder.getCBpartnerId(),porder.getPaymentrule(),porder.getDeliveryviarule(),porder.getCBpartnerLocationId(),porder.getCBpartnerContactId());
         if (!orderid.contains("ERR")){
           Orderline[] orderlines = new Orderline[porder.getOrderlines().length];
           orderlines=porder.getOrderlines();
           for (int i = 0; i < orderlines.length; i++) {
             issuccess = OrderData.InsertOrderLine(con,pool,orderid,orderlines[i].getMProductId(),orderlines[i].getQtyordered().toString(),orderlines[i].getPriceactual().toString(),orderlines[i].getDescription());
             if (issuccess.contains("ERR"))
                 //Raise...
               throw new Exception("Error Creating Orderline: " + issuccess); 
           }
           issuccess= OrderData.CommitOrder(con,pool, orderid);
           if (issuccess.contains("ERR"))
             //@TODO Raise...
           throw new Exception("Error Submitting Order: " + issuccess); 
         } else
           throw new Exception("Error Creating Order: " + orderid); 
           
    } catch (Exception e) {
      log4j.error(e.getMessage());
      con.rollback();
      throw new Exception("Exception in Webservice: " + e.getMessage()); 
    } finally {
      pool.releaseCommitConnection(con);
      con=null;
      destroyPool();
    }
    or.setCOrderId(orderid);
    or.setMessage("Order Created");
    return or;
  }
  public OrderV100 getOrder(String orgId, String username, String password,String cOrderId) throws Exception  {
    if (!access(username, password,orgId)) {
      if (log4j.isDebugEnabled())
        log4j.debug("Access denied for user: " + username);
      throw new Exception("Access denied for user: " + username); 
    }
    OrderV100 order = new OrderV100();
    SimpleDateFormat sdf= new SimpleDateFormat(sqlDateFormat);
    try {

      OrderData[] data = OrderData.select(pool, cOrderId);
      if (data.length > 0) {
        order.setCOrderId(data[0].cOrderId);
        order.setDocumentno(data[0].documentno);
        order.setDocstatus(data[0].docstatus);
        order.setIsdelivered(data[0].isdelivered);
        order.setIsinvoiced(data[0].isinvoiced);
        order.setCBpartnerId(data[0].cBpartnerId);
        order.setPaymentrule(data[0].paymentrule);
        order.setDeliveryviarule(data[0].deliveryviarule);
        // Get the lines
        OrderlineData[] data2 = OrderlineData.select(pool, cOrderId);
        Orderline[] orderlines = new Orderline[data2.length];
        for (int i = 0; i < orderlines.length; i++) {
          orderlines[i] = new Orderline();
          orderlines[i].setCOrderlineId(data2[i].cOrderlineId);
          orderlines[i].setCOrderId(data2[i].cOrderId);
          orderlines[i].setLine(new BigDecimal(data2[i].line));
          if (!data2[i].datepromised.equals(""))
               orderlines[i].setDatepromised(sdf.parse(data2[i].datepromised));
          if (!data2[i].datedelivered.equals(""))
               orderlines[i].setDatedelivered(sdf.parse(data2[i].datedelivered));
          if (!data2[i].dateinvoiced.equals(""))
               orderlines[i].setDateinvoiced(sdf.parse(data2[i].dateinvoiced));
          orderlines[i].setDescription(data2[i].description);
          orderlines[i].setMProductId(data2[i].mProductId);
          orderlines[i].setQtyordered(new BigDecimal(data2[i].qtyordered));
          orderlines[i].setQtydelivered(new BigDecimal(data2[i].qtydelivered));
          orderlines[i].setQtyinvoiced(new BigDecimal(data2[i].qtyinvoiced));
          orderlines[i].setPriceactual(new BigDecimal(data2[i].priceactual));
        }
        order.setOrderlines(orderlines);
      }  
    } catch (Exception e) {
      log4j.error(e.getMessage());
      throw new Exception("Exception in Webservice: " + e.getMessage()); 
    } finally {
      destroyPool();
    }
    
    return order;
  }
  
  
}
