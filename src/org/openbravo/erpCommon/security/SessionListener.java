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

package org.openbravo.erpCommon.security;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.util.Vector;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import org.apache.log4j.Logger;
import org.openbravo.database.ConnectionProvider;

public class SessionListener implements HttpSessionListener, ServletContextListener {

  private static final Logger log = Logger.getLogger(SessionListener.class);

  private static Vector<String> sessionsInContext = new Vector<String>();
  private static ServletContext context = null;

  /**
   * This method is called whenever the session is destroyed because of user action or time out.
   * 
   * It deactivates the session in db
   */
  @Override
  public void sessionDestroyed(HttpSessionEvent event) {
    log.debug("Destroying session");
    String sessionId = (String) event.getSession().getAttribute("#AD_SESSION_ID");
    if (sessionId != null) {
      deactivateSession(sessionId);

    }
  }

  /**
   * This method is invoked when the server is shot down, it deactivates all sessions in this
   * context.
   */
  @Override
  public void contextDestroyed(ServletContextEvent event) {
    log.info("Destroy context");

    for (String sessionId : sessionsInContext) {
      try {
        // cannot use dal at this point, use sqlc
        SessionLoginData.deactivate((ConnectionProvider) event.getServletContext().getAttribute(
            "openbravoPool"), sessionId);
        this.context = null;
        log.info("Deactivated session:" + sessionId);
      } catch (ServletException e1) {
        log.error(e1.getMessage(), e1);
      }
    }

  }

  /**
   * Add a session to session tracking. This will be used when shut dowing the server
   * 
   * @param sessionId
   *          db id for the session to keep track
   */
  public static void addSession(String sessionId) {
    sessionsInContext.add(sessionId);
  }

  /**
   * Sets the current context and deactivates orphan sessions.
   * 
   * Orphan sessions occur after a wrong context shutdown.
   */
  @Override
  public void contextInitialized(ServletContextEvent event) {
    SessionListener.context = event.getServletContext();

    // Look orphan sessions and close them, these sessions are:
    // -All the ones in the current context that will generate a time out when querying the servlet
    // -The ones in other contexts that are no longer active

    // SZ Deactivated Function 
    // Ticket 795: If you have more than 1 Server, sessions are invalidated on Server restart
    // This is not nesessary: Server will automatically invalidate own sessions after crash on restart.
    // checkSessionIsLocalContext was rewritten
    // if we suppose to need a function like this , we must determin the Server URL and check sessions against this url
    
    /*SessionLoginData activeSessions[];
    try {
      activeSessions = SessionLoginData.activeSessions((ConnectionProvider) SessionListener.context
          .getAttribute("openbravoPool"));

      for (SessionLoginData session : activeSessions) {
        if (checkSessionIsLocalContext(session.adSessionId, session.serverUrl)) {
          deactivateSession(session.adSessionId);
        }
      }
    } catch (ServletException e) {
      log.error("Error checking orphan sessions", e);
    }*/
  }

  private boolean checkSessionIsLocalContext(String sessionId, String serverUrl) {
    try {
      String islocal = SessionLoginData.isLocalSession((ConnectionProvider) SessionListener.context
          .getAttribute("openbravoPool"), sessionId, serverUrl);
      if (islocal.equals("Y"))
        return true;
      else
        return false;
    } catch (Exception e) {
      log.error("Error checking remote session " + sessionId + " in context " + serverUrl, e);
    }
    return false;
  }

  @Override
  public void sessionCreated(HttpSessionEvent event) {
    // do nothing
  }

  private void deactivateSession(String sessionId) {
    try {
      sessionsInContext.remove(sessionId);

      // Do not use DAL here
      SessionLoginData.deactivate((ConnectionProvider) context.getAttribute("openbravoPool"),
          sessionId);
      log.info("Closed session" + sessionId);
    } catch (Exception e) {
      log.error("Error closing session:" + sessionId, e);
    }
  }

  /**
   * Check whether a session is in the current context and it is active
   * 
   * @param sessionId
   *          session to check
   * @return true in case it is in the context and active
   */
  public static boolean isSessionActiveInContext(String sessionId) {
    boolean isInContext = sessionsInContext.contains(sessionId);

    if (!isInContext) {
      return false;
    }

    try {
      return SessionLoginData.isSessionActive((ConnectionProvider) context
          .getAttribute("openbravoPool"), sessionId);
    } catch (ServletException e) {
      log.error("Error checking active session " + sessionId, e);
      return false;
    }
  }

}
