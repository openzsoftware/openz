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

class FormatCouple {
  DecimalFormat formatOutput;
  DecimalFormat formatSimple;

  public FormatCouple() {
    this.formatOutput = null;
    this.formatSimple = null;
  }

  public FormatCouple(DecimalFormat formatOutput, DecimalFormat formatSimple) {
    this.formatOutput = formatOutput;
    this.formatSimple = formatSimple;
  }

}

/*
 * In XmlEngine, load FormatCouple's in the put. In TemplateConfiguration, pass the FormatCouple to
 * the addField and AddFunction functions In DataTemplate, call the constructors of FieldTemplate
 * and Function... In los constructors, read both formats, in the printSimple use the formatSimple
 */
