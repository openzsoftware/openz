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
package org.openbravo.xmlEngine;

import java.text.DecimalFormat;

import org.apache.log4j.Logger;

class FunctionModuleTemplate extends FunctionTemplate {

  static Logger log4jFunctionModuleTemplate = Logger.getLogger(FunctionModuleTemplate.class);

  public FunctionModuleTemplate(String fieldName, DecimalFormat formatOutput,
      DecimalFormat formatSimple, DataTemplate dataTemplate, XmlComponentTemplate arg1,
      XmlComponentTemplate arg2) {
    super(fieldName, formatOutput, formatSimple, dataTemplate, arg1, arg2);
  }

  public FunctionValue createFunctionValue(XmlDocument xmlDocument) {
    FunctionValue functionValue = searchFunction(xmlDocument);
    if (functionValue == null) {
      if (log4jFunctionModuleTemplate.isDebugEnabled())
        log4jFunctionModuleTemplate.debug("New FunctionModuleValue");
      functionValue = new FunctionModuleValue(this, xmlDocument);
    }
    return functionValue;
  }

}
