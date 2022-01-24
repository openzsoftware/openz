package org.zsoft.ecommerce;

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.OBError;

public interface FilePollingTAB {
		  
		 
  public OBError fetchAndProcess(ConnectionProvider conn, VariablesSecureApp vars, String filePath, String fileName, String tableId,String _key) throws Exception;
	
}
