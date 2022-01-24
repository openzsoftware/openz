/*
 ************************************************************************************
 * Copyright (C) 2001-2009 Openbravo S.L.
 * Licensed under the Apache Software License version 2.0
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to  in writing,  software  distributed
 * under the License is distributed  on  an  "AS IS"  BASIS,  WITHOUT  WARRANTIES  OR
 * CONDITIONS OF ANY KIND, either  express  or  implied.  See  the  License  for  the
 * specific language governing permissions and limitations under the License.
 ************************************************************************************
 */

package org.openbravo.authentication.basic;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.openbravo.authentication.AuthenticationException;
import org.openbravo.authentication.AuthenticationManager;
import org.openbravo.base.HttpBaseUtils;
import org.openbravo.base.secureApp.VariablesHistory;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.Utility;

/**
 * 
 * @author adrianromero
 * 
 * SZ: Only Checks against user id
 *     Session ID checks are done Later by hhtpsecureappServlet.
 */
public class DefaultAuthenticationManager implements AuthenticationManager {

  private ConnectionProvider conn = null;
  private String strServletSinIdentificar = null;
  private Logger log4j = Logger.getLogger(DefaultAuthenticationManager.class);

  /** Creates a new instance of DefaultAuthenticationManager */
  public DefaultAuthenticationManager() {
  }

  public void init(HttpServlet s) throws AuthenticationException {
    if (s instanceof ConnectionProvider) {
      conn = (ConnectionProvider) s;
      strServletSinIdentificar = s.getServletConfig().getServletContext().getInitParameter(
          "ServletSinIdentificar");
    } else {
      throw new AuthenticationException("Connection provider required for default authentication");
    }
  }

  public String authenticate(HttpServletRequest request, HttpServletResponse response)
      throws AuthenticationException, ServletException, IOException {
    String sUserId =null;
    try {
     sUserId = (String) request.getSession(false).getAttribute("#Authenticated_user");
    } catch (Exception ignored) {
      sUserId =null;
    }
    if (sUserId == null || sUserId.equals("")) {
      String strAjax = "";
      // strHidden and strPopUp not implemented
      /*
       * String strHidden = ""; String strPopUp = "";
       */
      try {
        strAjax = request.getParameter("IsAjaxCall");
      } catch (Exception ignored) {
      }
      /*
       * try { strHidden = request.getParameter("IsHiddenCall"); } catch (Exception ignored) {} try
       * { strPopUp = request.getParameter("IsPopUpCall"); } catch (Exception ignored) {}
       */
      VariablesHistory variables = new VariablesHistory(request);

      // redirects to the menu or the menu with the target
      String strTarget = request.getRequestURL().toString();
      if (!strTarget.endsWith("/security/Menu.html")) {
        variables.setSessionValue("targetmenu", strTarget);
      }

      String qString = request.getQueryString();

      String strDireccionLocal = HttpBaseUtils.getLocalAddress(request);

      // Storing target string to redirect after a successful login
      variables.setSessionValue("target", strDireccionLocal + "/security/Menu.html"
          + (qString != null && !qString.equals("") ? "?" + qString : ""));

      if (strAjax != null && !strAjax.equals(""))
        bdErrorAjax(response, "Error", "", Utility.messageBD(this.conn, "NotLogged", variables
            .getLanguage()));
      else
        response.sendRedirect(strDireccionLocal + strServletSinIdentificar);
      return null;
    } else {
      return sUserId;
    }
  }

  private void bdErrorAjax(HttpServletResponse response, String strType, String strTitle,
      String strText) throws IOException {
    response.setContentType("text/xml; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
    out.println("<xml-structure>\n");
    out.println("  <status>\n");
    out.println("    <type>" + strType + "</type>\n");
    out.println("    <title>" + strTitle + "</title>\n");
    out.println("    <description><![CDATA[" + strText + "]]></description>\n");
    out.println("  </status>\n");
    out.println("</xml-structure>\n");
    out.close();
  }

  public void logout(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {

    // if HttpSession is still valid, then 'logout' by removing #Authenticated_user from it
	try {  
	    HttpSession session = request.getSession(true);
	    if (session != null) {
	      session.removeAttribute("#Authenticated_user");
	    }
	
	    if (!response.isCommitted())
	      response.sendRedirect(HttpBaseUtils.getLocalAddress(request));
	} catch (Exception ignored) {}
  }

}
