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

package org.openbravo.authentication;

/**
 * 
 * @author adrianromero
 */
public class AuthenticationException extends java.lang.Exception {
  private static final long serialVersionUID = 1L;

  /**
   * Creates a new instance of <code>AuthenticationException</code> without detail message.
   */
  public AuthenticationException() {
  }

  /**
   * Constructs an instance of <code>AuthenticationException</code> with the specified detail
   * message.
   * 
   * @param msg
   *          the detail message.
   */
  public AuthenticationException(String msg) {
    super(msg);
  }

  public AuthenticationException(String msg, Throwable t) {
    super(msg, t);
  }
}
