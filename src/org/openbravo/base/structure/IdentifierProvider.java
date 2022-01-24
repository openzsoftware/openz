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

package org.openbravo.base.structure;

import java.util.List;

import org.openbravo.base.model.Entity;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.model.Property;
import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.provider.OBSingleton;

/**
 * Provides the identifier/title of an object using the {@link Entity#getIdentifierProperties()
 * identifierProperties} of the {@link Entity Entity}.
 * 
 * Note: the getIdentifier can also be generated in the java entity but the current approach makes
 * it possible to change the identifier definition at runtime.
 * 
 * @author mtaal
 */

public class IdentifierProvider implements OBSingleton {

  private static IdentifierProvider instance;

  public static synchronized IdentifierProvider getInstance() {
    if (instance == null) {
      instance = OBProvider.getInstance().get(IdentifierProvider.class);
    }
    return instance;
  }

  public static synchronized void setInstance(IdentifierProvider instance) {
    IdentifierProvider.instance = instance;
  }

  /**
   * Returns the identifier of the object. The identifier is computed using the identifier
   * properties of the Entity of the object.
   * 
   * @param o
   *          the object for which the identifier is generated
   * @return the identifier
   */
  public String getIdentifier(Object o) {
    return getIdentifier(o, true);
  }

  // identifyDeep determines if refered to objects are used
  // to identify the object
  private String getIdentifier(Object o, boolean identifyDeep) {
    // TODO: add support for null fields
    final StringBuilder sb = new StringBuilder();
    final DynamicEnabled dob = (DynamicEnabled) o;
    final String entityName = ((Identifiable) dob).getEntityName();
    final List<Property> identifiers = ModelProvider.getInstance().getEntity(entityName)
        .getIdentifierProperties();

    for (final Property identifier : identifiers) {
      if (sb.length() > 0) {
        sb.append(" ");
      }
      final Object value = dob.get(identifier.getName());

      if (value instanceof Identifiable && identifyDeep) {
        sb.append(getIdentifier(value, false));
      } else if (value != null) {
        sb.append(value);
      }
    }
    if (identifiers.size() == 0) {
      return entityName + " (" + ((Identifiable) dob).getId() + ")";
    }
    return sb.toString();
  }
}