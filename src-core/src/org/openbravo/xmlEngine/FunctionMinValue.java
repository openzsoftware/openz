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

import java.math.BigDecimal;

import org.apache.log4j.Logger;

class FunctionMinValue extends FunctionEvaluationValue {

  static Logger log4jFunctionMinValue = Logger.getLogger(FunctionMinValue.class);

  public FunctionMinValue(FunctionTemplate functionTemplate, XmlDocument xmlDocument) {
    super(functionTemplate, xmlDocument);
  }

  public String print() {
    if (arg1Value.print().equals(XmlEngine.strTextDividedByZero)
        || arg2Value.print().equals(XmlEngine.strTextDividedByZero)) {
      return XmlEngine.strTextDividedByZero;
    } else {
      return functionTemplate.printFormatOutput(new BigDecimal(arg1Value.printSimple())
          .min(new BigDecimal(arg2Value.printSimple())));
    }
  }

  public String printSimple() {
    if (arg1Value.print().equals(XmlEngine.strTextDividedByZero)
        || arg2Value.print().equals(XmlEngine.strTextDividedByZero)) {
      return XmlEngine.strTextDividedByZero;
    } else {
      return functionTemplate.printFormatSimple(new BigDecimal(arg1Value.printSimple())
          .min(new BigDecimal(arg2Value.printSimple())));
    }
  }

}
