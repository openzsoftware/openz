/*
 ************************************************************************************
 * Copyright (C) 2009 Openbravo S.L.
 * Licensed under the Apache Software License version 2.0
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to  in writing,  software  distributed
 * under the License is distributed  on  an  "AS IS"  BASIS,  WITHOUT  WARRANTIES  OR
 * CONDITIONS OF ANY KIND, either  express  or  implied.  See  the  License  for  the
 * specific language governing permissions and limitations under the License.
 ************************************************************************************
 */
package org.openbravo.base.filter;

/**
 * Filter to check, if the input value is an uuid.
 * 
 * @author huehner
 * 
 */
public class IsIDFilter extends RegexFilter {

  public final static IsIDFilter instance = new IsIDFilter();

  public IsIDFilter() {
    super("[a-fA-F0-9]*");
  }

}
