/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html 
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License. 
 * The Original Code is Openbravo ERP. 
 * The Initial Developer of the Original Code is Openbravo SL 
 * All portions are Copyright (C) 2008 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.base.validation;

/**
 * Defines the interface for a propertyvalidator.
 * 
 * @author mtaal
 */

public interface PropertyValidator {

  /**
   * Validate the value against constraints implemented in the validator. If the validation fails a
   * message is returned. If validation passes then null is returned.
   * 
   * @param value
   *          the value to check
   * @return null if validation passes, otherwise a validation message is returned
   */
  public String validate(Object value);
}