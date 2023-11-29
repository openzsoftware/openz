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

package org.openbravo.erpCommon.security;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.utils.FormatUtilities;

import org.openbravo.base.secureApp.HttpSecureAppServlet;

/**
 * 
 * @author adrianromero
 */
public class Logout extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  /** Creates a new instance of Logout */
  public Logout() {
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {

      // delete (keep me logged in) permsession cookie on logout
      Cookie[] cooks=request.getCookies();
      if (cooks!=null) {
         for (int i=0;i<cooks.length;i++) {
             if (cooks[i].getName().equals("permsession")) {
                 final String permsessionId = cooks[i].getValue();
                 // delete permsession cookie if permsession id is not set in adUser Settings --> delete only keep me logged in cookie
                 // legacy support for old non hashed permsession cookies
                 if(!SessionLoginData.isPermsession(this, FormatUtilities.sha1Base64(permsessionId)) && !SessionLoginData.isPermsession(this, permsessionId)) {
                     cooks[i].setMaxAge(0);
                     cooks[i].setPath(request.getContextPath());
                     response.addCookie(cooks[i]);
                 }
             }
         }
      }

      logout(request, response);
  }
}
