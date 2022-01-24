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
 * All portions are Copyright (C) 2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.base;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.security.SessionLoginData;

public class SystemStatusListener implements ServletContextListener {
  private static final Logger logger = Logger.getLogger(SystemStatusListener.class);

  @Override
  public void contextDestroyed(ServletContextEvent arg0) {

  }

  /*
   * This context listener checks if the last build went well, and if it did, it updates the status
   * to reflect that Tomcat was restarted
   */
  @Override
  public void contextInitialized(ServletContextEvent sce) {
    ConnectionProvider cp = ConnectionProviderContextListener.getPool(sce.getServletContext());
    try {
    	// Deactivate old Sessions
        SessionLoginData.deactivateAll(cp);
    } catch (ServletException e) {
      logger.error("Error while updating system status", e);
    }

  }
}
