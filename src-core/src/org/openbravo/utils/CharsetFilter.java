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
package org.openbravo.utils;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;

public class CharsetFilter implements Filter {
  private String encoding;

  public void init(FilterConfig config) throws ServletException {
    encoding = config.getInitParameter("requestEncoding");
    if (encoding == null)
      encoding = "UTF-8";
  }

  public void doFilter(ServletRequest request, ServletResponse response, FilterChain next)
      throws IOException, ServletException {
    request.setCharacterEncoding(encoding);
    next.doFilter(request, response);
  }

  public void destroy() {
  }
}
