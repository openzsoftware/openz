package org.zsoft.ecommerce;

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;

public interface FilePollingAPI {
  
  public void fetchAndProcess(ConnectionProvider conn,String apikey,String secret,String shop) throws Exception;
  // TODO enable with Java 8  
  /*
   * public default void fetchAndProcess(ConnectionProvider conn,String apikey,String secret,String shop) throws Exception {
   * throw new UnsupportedOperationException();
  };
  */
  
  public void fetchAndProcess(ConnectionProvider conn, VariablesSecureApp vars, String baseDesignPath, String filePath) throws Exception;
  // TODO enable with Java 8 
  /*
   * public default void fetchAndProcess(String baseDesignPath, String filePath) {
   *  throw new UnsupportedOperationException();
   *  };
   */
}
