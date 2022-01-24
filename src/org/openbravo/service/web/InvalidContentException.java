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

package org.openbravo.service.web;

import org.openbravo.base.exception.OBException;

/**
 * This exception is thrown when the posted content is not valid.
 * 
 * @author mtaal
 */
public class InvalidContentException extends OBException {

  private static final long serialVersionUID = 1L;

  public InvalidContentException() {
    super();
  }

  public InvalidContentException(String message, Throwable cause) {
    super(message, cause);
  }

  public InvalidContentException(String message) {
    super(message);
  }

  public InvalidContentException(Throwable cause) {
    super(cause);
  }
}
