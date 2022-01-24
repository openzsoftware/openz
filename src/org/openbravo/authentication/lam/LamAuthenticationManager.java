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

package org.openbravo.authentication.lam;

import java.io.IOException;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.xmlrpc.XmlRpcException;
import org.openbravo.authentication.AuthenticationData;
import org.openbravo.authentication.AuthenticationException;
import org.openbravo.authentication.AuthenticationManager;
import org.openbravo.base.HttpBaseUtils;
import org.openbravo.database.ConnectionProvider;

import com.spikesource.lam.bindings.LamClient;

/**
 * 
 * @author adrian
 */
public class LamAuthenticationManager implements AuthenticationManager {

  private ConnectionProvider conn = null;

  /** Creates a new instance of LamAuthenticationManager */
  public LamAuthenticationManager() {
  }

  public void init(HttpServlet s) throws AuthenticationException {

    // TODO: Read LAM configuration.
    if (s instanceof ConnectionProvider) {
      conn = (ConnectionProvider) s;
    } else {
      throw new AuthenticationException("Connection provider required for LAM authentication");
    }
  }

  public String authenticate(HttpServletRequest request, HttpServletResponse response)
      throws AuthenticationException, ServletException, IOException {

    try {
      LamClient LC = new LamClient(); // TODO: configure LamClient

      String sUserName = LC.force_authenticate(request, response);
      if (sUserName == null || sUserName.equals("")) {
        return null;
      } else {
        String sUserId = AuthenticationData.getUserId(conn, sUserName);
        if ("-1".equals(sUserId)) {
          throw new AuthenticationException("Authenticated user is not an Openbravo ERP user: "
              + sUserName);
        }
        return sUserId;
      }
    } catch (XmlRpcException e) {
      throw new ServletException("Cannot authenticate user.", e);
    } catch (NoSuchAlgorithmException e) {
      throw new ServletException("Cannot authenticate user.", e);
    } catch (KeyManagementException e) {
      throw new ServletException("Cannot authenticate user.", e);
    }
  }

  public void logout(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {

    try {
      LamClient LC = new LamClient(); // TODO: configure LamClient
      LC.logout(request, response, HttpBaseUtils.getLocalAddress(request) + "/security/Menu.html");
    } catch (XmlRpcException e) {
      throw new ServletException("Cannot close user session.", e);
    }
  }
}