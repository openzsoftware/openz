package org.zsoft.ecommerce.logistic;

import java.net.URL;

import org.openbravo.database.ConnectionProvider;
import org.openbravo.scheduling.ProcessBundle;

public interface LogisticClientAPIRequest {
  public void processInOut(String mInoutId, ConnectionProvider connP) throws Exception ;
}
