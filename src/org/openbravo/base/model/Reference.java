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
 * All portions are Copyright (C) 2008-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.base.model;

import java.math.*;
import java.sql.Timestamp;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

/**
 * Used by the {@link ModelProvider ModelProvider}, maps the AD_Reference table in the in-memory
 * model.
 * 
 * @author iperdomo
 */

@SuppressWarnings("unchecked")
public class Reference extends ModelObject {

  // Ids of ReferenceTypes
  public static final String TABLE = "18";
  public static final String TABLEDIR = "19";
  public static final String SEARCH = "30";
  public static final String IMAGE = "32";
  public static final String IMAGE_BLOB = "4AA6C3BE9D3B4D84A3B80489505A23E5";
  public static final String RESOURCE_ASSIGNMENT = "33";
  public static final String PRODUCT_ATTRIBUTE = "35";
  public static final String NO_REFERENCE = "-1";

  // Validation Types
  public static final char TABLE_VALIDATION = 'T';
  public static final char SEARCH_VALIDATION = 'S';
  public static final char LIST_VALIDATION = 'L';

  private static HashMap<String, Class> primitiveTypes;

  static {
    // Mapping reference id with a Java type
    primitiveTypes = new HashMap<String, Class>();

    primitiveTypes.put("10", String.class);
    primitiveTypes.put("11", Long.class);
    primitiveTypes.put("12", BigDecimal.class);
    primitiveTypes.put("13", String.class);
    primitiveTypes.put("14", String.class);
    primitiveTypes.put("15", Date.class);
    primitiveTypes.put("16", Date.class);
    primitiveTypes.put("17", String.class);
    primitiveTypes.put("20", Boolean.class);
    primitiveTypes.put("22", BigDecimal.class);
    primitiveTypes.put("23", byte[].class); // Binary/Blob Data
    primitiveTypes.put("24", Timestamp.class);
    primitiveTypes.put("26", Object.class); // RowID is not used
    primitiveTypes.put("27", Object.class); // Color is not used
    primitiveTypes.put("28", Boolean.class);
    primitiveTypes.put("29", BigDecimal.class);
    primitiveTypes.put("34", String.class);
    primitiveTypes.put("800008", BigDecimal.class);
    primitiveTypes.put("800019", BigDecimal.class);
    primitiveTypes.put("800101", String.class);
  }

  private char validationType;
  private Set<String> allowedValues = new HashSet<String>();

  public char getValidationType() {
    return validationType;
  }

  public void setValidationType(char validationType) {
    this.validationType = validationType;
  }

  public static Class getPrimitiveType(String id) {
    if (primitiveTypes.containsKey(id))
      return primitiveTypes.get(id);
    return Object.class;
  }

  public void addAllowedValue(String value) {
    allowedValues.add(value);
  }

  public Set<String> getAllowedValues() {
    return allowedValues;
  }

  public boolean isDatetime() {
    return getId().equals("16");
  }

  public boolean isDate() {
    return getId().equals("15");
  }
}
