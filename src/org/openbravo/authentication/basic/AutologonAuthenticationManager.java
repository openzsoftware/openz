/*
 ************************************************************************************
 * Copyright (C) 2001-2006 Openbravo S.L.
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

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.authentication.AuthenticationData;
import org.openbravo.authentication.AuthenticationException;
import org.openbravo.authentication.AuthenticationManager;
import org.openbravo.base.ConfigParameters;
import org.openbravo.base.HttpBaseUtils;
import org.openbravo.database.ConnectionProvider;

/**
 * 
 * @author adrianromero
 */
public class AutologonAuthenticationManager implements AuthenticationManager {

  private String m_sAutologonUsername;
  private String m_sUserId = null;

  /** Creates a new instance of FixedAuthenticationManager */
  public AutologonAuthenticationManager() {
  }

  public void init(HttpServlet s) throws AuthenticationException {

    if (s instanceof ConnectionProvider) {
      ConnectionProvider conn = (ConnectionProvider) s;
      m_sAutologonUsername = ConfigParameters.retrieveFrom(s.getServletContext()).getOBProperty(
          "authentication.autologon.username");
      try {
        m_sUserId = AuthenticationData.getUserId(conn, m_sAutologonUsername);
      } catch (ServletException e) {
        throw new AuthenticationException("Cannot authenticate user: " + m_sAutologonUsername, e);
      }

    } else {
      throw new AuthenticationException("Connection provider required for Autologon authentication");
    }
  }

  public String authenticate(HttpServletRequest request, HttpServletResponse response)
      throws AuthenticationException, ServletException, IOException {

    if (m_sUserId == null || m_sUserId.equals("") || m_sUserId.equals("-1")) {
      if (m_sAutologonUsername == null || m_sAutologonUsername.equals("")) {
        throw new AuthenticationException("Autologon user emtpy.");
      } else {
        throw new AuthenticationException("Autologon user is not an Openbravo ERP user: "
            + m_sAutologonUsername);
      }
    } else {
      return m_sUserId;
    }
  }

  public void logout(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    // Never logs out this manager, just go to menu.
    response.sendRedirect(HttpBaseUtils.getLocalAddress(request) + "/security/Menu.html");
  }
}