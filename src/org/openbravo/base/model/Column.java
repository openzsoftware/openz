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

package org.openbravo.base.model;

import java.util.Collections;
import java.util.Set;

import org.apache.log4j.Logger;

/**
 * Used by the {@link ModelProvider ModelProvider}, maps the AD_Column table in the application
 * dictionary.
 * 
 * @author iperdomo
 * @author mtaal
 */

public class Column extends ModelObject {
  private static final Logger log = Logger.getLogger(Column.class);

  private Property property;
  private String columnName;
  private Table table;
  private Reference reference;
  private Reference referenceValue;
  private Column referenceType = null;
  private int fieldLength;
  private String defaultValue;
  private boolean key;
  private boolean secondaryKey;
  private boolean parent;
  private boolean mandatory;
  private boolean updatable;
  private boolean identifier;
  private String valueMin;
  private String valueMax;
  private String developmentStatus;
  private Boolean isTransient;
  private String isTransientCondition;
  private Integer position;

  private Module module;

  public boolean isBoolean() {
    return isPrimitiveType()
        && (getPrimitiveType().getName().compareTo("boolean") == 0 || Boolean.class == getPrimitiveType());
  }

  public String getColumnName() {
    return columnName;
  }

  public void setColumnName(String columnName) {
    this.columnName = columnName;
  }

  public Table getTable() {
    return table;
  }

  public void setTable(Table table) {
    this.table = table;
  }

  public Reference getReference() {
    return reference;
  }

  public void setReference(Reference reference) {
    this.reference = reference;
  }

  public Reference getReferenceValue() {
    return referenceValue;
  }

  public void setReferenceValue(Reference referenceValue) {
    this.referenceValue = referenceValue;
  }

  public int getFieldLength() {
    return fieldLength;
  }

  public void setFieldLength(int fieldLength) {
    this.fieldLength = fieldLength;
  }

  public String getDefaultValue() {
    return defaultValue;
  }

  public void setDefaultValue(String defaultValue) {
    this.defaultValue = defaultValue;
  }

  public boolean isKey() {
    return key;
  }

  public void setKey(Boolean key) {
    this.key = key;
  }

  public boolean isSecondaryKey() {
    return secondaryKey;
  }

  public void setSecondaryKey(boolean secondaryKey) {
    this.secondaryKey = secondaryKey;
  }

  public boolean isParent() {
    return parent;
  }

  public void setParent(Boolean parent) {
    this.parent = parent;
  }

  public boolean isMandatory() {
    return mandatory;
  }

  public void setMandatory(Boolean mandatory) {
    this.mandatory = mandatory;
  }

  public boolean isUpdatable() {
    return updatable;
  }

  public void setUpdatable(Boolean updatable) {
    this.updatable = updatable;
  }

  public boolean isIdentifier() {
    return identifier;
  }

  public void setIdentifier(Boolean identifier) {
    this.identifier = identifier;
  }

  public String getValueMin() {
    return valueMin;
  }

  public void setValueMin(String valueMin) {
    this.valueMin = valueMin;
  }

  public String getValueMax() {
    return valueMax;
  }

  public void setValueMax(String valueMax) {
    this.valueMax = valueMax;
  }

  public String getDevelopmentStatus() {
    return developmentStatus;
  }

  public void setDevelopmentStatus(String developmentStatus) {
    this.developmentStatus = developmentStatus;
  }

  public boolean isPrimitiveType() {
    if (!reference.getId().equals(Reference.TABLE) && !reference.getId().equals(Reference.TABLEDIR)
        && !reference.getId().equals(Reference.SEARCH)
        && !reference.getId().equals(Reference.IMAGE)
        && !reference.getId().equals(Reference.IMAGE_BLOB)
        && !reference.getId().equals(Reference.PRODUCT_ATTRIBUTE)
        && !reference.getId().equals(Reference.RESOURCE_ASSIGNMENT))
      return true;
    return false;
  }

  @SuppressWarnings("unchecked")
  public Class getPrimitiveType() {
    if (isPrimitiveType()) {
      final Class<?> clz = Reference.getPrimitiveType(reference.getId());
      if (clz == Boolean.class && getReferenceValue() != null) {
        // a string list
        return String.class;
      }
      return clz;
    }
    return null;
  }

  public Column getReferenceType() {
    if (!isPrimitiveType())
      return referenceType;
    return null;
  }

  public void setReferenceType(Column column) {
    this.referenceType = column;
  }

  @Override
  public boolean isActive() {
    if (super.isActive() && !isPrimitiveType()) {
      final Column thatColumn = getReferenceType();

      // note calls isSuperActive(), if it would call isActive there is a danger
      // for infinite looping, see issue:
      // https://issues.openbravo.com/view.php?id=8632
      // SZ: Removed the Following line For Generating References to Views 
      // || thatColumn.getTable().isView()
      if (thatColumn != null
          && (!thatColumn.isSuperActive() || !thatColumn.getTable().isActive() )) {
        log.error("Column " + this + " refers to a non active table or column or to a view"
            + thatColumn);
      }
    }
    return super.isActive();
  }

  // method to prevent infinite looping checking for exceptions. See this issue:
  // https://issues.openbravo.com/view.php?id=8632
  private boolean isSuperActive() {
    return super.isActive();
  }

  protected void setReferenceType(ModelProvider modelProvider) {

    // reference type does not need to be set
    if (isPrimitiveType()) {
      return;
    }

    try {
      final String referenceId = reference.getId();
      final String referenceValueId = (referenceValue != null ? referenceValue.getId()
          : Reference.NO_REFERENCE);
      final char validationType = (referenceValue != null ? referenceValue.getValidationType()
          : reference.getValidationType());
      final Column c = modelProvider.getColumnByReference(referenceId, referenceValueId,
          validationType, getColumnName());
      if (c != null)
        setReferenceType(c);
    } catch (final Exception e) {
      System.out.println("Error >> tableName: " + table.getTableName() + " - columnName: "
          + getColumnName());
      e.printStackTrace();
    }
  }

  // returns the primitive type name or the class of the
  // referenced type
  public String getTypeName() {
    final String typeName;
    if (isPrimitiveType()) {
      typeName = getPrimitiveType().getName();
    } else if (getReferenceType() == null) {
      log.warn("ERROR NO REFERENCETYPE " + getTable().getName() + "." + getColumnName());
      return "java.lang.Object";
    } else {
      typeName = getReferenceType().getTable().getNotNullClassName();
    }
    return typeName;
  }

  // the last part of the class name
  public String getSimpleTypeName() {
    final String typeName = getTypeName();
    if (typeName.indexOf(".") == -1) {
      return typeName;
    }
    return typeName.substring(1 + typeName.lastIndexOf("."));
  }

  /**
   * Returns the classname of the object which maps to the type of this column. For example if this
   * column is an int then this method will return java.lang.Integer (the object version of the
   * int).
   * 
   * @return the name of the class of the type of this column
   */
  public String getObjectTypeName() {
    if (isPrimitiveType()) {
      final String typeName = getTypeName();
      if (typeName.indexOf('.') != -1) {
        return typeName;
      }
      if ("boolean".equals(typeName)) {
        return Boolean.class.getName();
      }
      if ("int".equals(typeName)) {
        return Integer.class.getName();
      }
      if ("long".equals(typeName)) {
        return Long.class.getName();
      }
      if ("byte".equals(typeName)) {
        return Byte.class.getName();
      }
      if ("float".equals(typeName)) {
        return Float.class.getName();
      }
      if ("double".equals(typeName)) {
        return Double.class.getName();
      }
      // TODO: maybe throw an exception
      return typeName;
    } else {
      return getTypeName();
    }
  }

  public Property getProperty() {
    return property;
  }

  public void setProperty(Property property) {
    this.property = property;
  }

  /**
   * Returns the concatenation of the table and column name.
   */
  @Override
  public String toString() {
    return getTable() + "." + getColumnName();
  }

  /**
   * Is used when this column denotes an enum. This method returns all allowed String values.
   * 
   * @return the set of allowed values for this Column.
   */
  @SuppressWarnings("unchecked")
  public Set<String> getAllowedValues() {
    // TODO: discrepancy with the application dictionary, solve this later
    if (getColumnName().equalsIgnoreCase("changeprojectstatus")) {
      return Collections.EMPTY_SET;
    }
    if (getReferenceValue() != null) {
      return getReferenceValue().getAllowedValues();
    }
    return Collections.EMPTY_SET;
  }

  public Boolean isTransient() {
    return isTransient;
  }

  public void setTransient(Boolean isTransient) {
    if (isTransient == null) {
      this.isTransient = Boolean.valueOf(false);
    } else {
      this.isTransient = isTransient;
    }
  }

  public String getIsTransientCondition() {
    return isTransientCondition;
  }

  public void setIsTransientCondition(String isTransientCondition) {
    this.isTransientCondition = isTransientCondition;
  }

  public Integer getPosition() {
    return position;
  }

  public void setPosition(Integer position) {
    this.position = position;
  }

  public Module getModule() {
    return module;
  }

  public void setModule(Module module) {
    this.module = module;
  }
}
