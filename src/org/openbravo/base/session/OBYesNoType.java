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

package org.openbravo.base.session;

import org.hibernate.type.YesNoType;
import org.hibernate.util.EqualsHelper;

/**
 * Extends the hibernate yesno type, handles null values as false. As certain methods can not be
 * extended the solution is to catch the isDirty check by reimplementing the isEqual method.
 * 
 * @author mtaal
 */
public class OBYesNoType extends YesNoType {
  private static final long serialVersionUID = 1L;

  /**
   * The isEqual has been overridden from the standard Hibernate YesNo type. The main difference
   * (with the implementation in the superclass) is that null is considered to be equal to false
   * here.
   */
  @Override
  public boolean isEqual(Object x, Object y) {
    if (x == y) {
      return true;
    }
    if (x == null && y != null && y instanceof Boolean) {
      return ((Boolean) y).booleanValue() == false;
    } else if (y == null && x != null && x instanceof Boolean) {
      return ((Boolean) x).booleanValue() == false;
    }

    return EqualsHelper.equals(x, y);
  }

}
