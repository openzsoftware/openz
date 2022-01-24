package org.zsoft.ecommerce.order.client;

import org.openbravo.database.ConnectionProvider;

public interface OrderClientAPIRequest {
  public void processOrder(String porder,ConnectionProvider conn) throws Exception ;
}
