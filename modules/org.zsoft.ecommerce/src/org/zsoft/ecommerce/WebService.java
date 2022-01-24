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
package org.zsoft.ecommerce;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServlet;

import org.apache.axis.MessageContext;
import org.apache.axis.transport.http.HTTPConstants;
import org.openbravo.base.ConnectionProviderContextListener;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.utils.FormatUtilities;
import org.apache.log4j.Logger;
import org.openbravo.base.session.OBPropertiesProvider;

public abstract class WebService {
  private static Logger log4j = Logger.getLogger(WebService.class);
  protected static ConnectionProvider pool;
  protected String clientId; 
  protected String userId; 
  protected static String sqlDateFormat = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("dateFormat.java");;
  
  public WebService() {
    initPool();
  }
  
  protected final boolean access(String username, String password, String orgId) {
    try {
      clientId =  WebServicesData.getClient(pool, orgId);
      userId = WebServicesData.getUserId(pool, username);
      int aut=Integer.parseInt(WebServicesData.hasAccess(pool, username, password,orgId));
      if (aut==0) {
    	  final String hashedPassword = FormatUtilities.sha1Base64(password);
    	  aut=Integer.parseInt(WebServicesData.hasAccess(pool, username, hashedPassword,orgId));
      }
      if (aut==0)
    	  return false;
      else
    	  return true;
    } catch (Exception e) {
      return false;
    }
  }
  
  private final void initPool() {
    if (log4j.isDebugEnabled())
      log4j.debug("init");
    try {
      HttpServlet srv = (HttpServlet) MessageContext.getCurrentContext().getProperty(
          HTTPConstants.MC_HTTP_SERVLET);
      ServletContext context = srv.getServletContext();
      pool = ConnectionProviderContextListener.getPool(context);
    } catch (Exception e) {
      log4j.error("Error : initPool");
      log4j.error(e.getStackTrace());
    }
  }

  protected final void destroyPool() {
    if (log4j.isDebugEnabled())
      log4j.debug("destroy");
  }
}
