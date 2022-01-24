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
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Set;

import org.apache.log4j.Logger;
import org.openbravo.base.expression.Evaluator;
import org.openbravo.base.util.Check;
import org.openbravo.base.validation.PropertyValidator;
import org.openbravo.base.validation.ValidationException;

/**
 * Together with {@link Entity Entity}, the Property is the main part of the in-memory model. A
 * property can be a primitive type, a reference or a list (one-to-many) property.
 * 
 * @author mtaal
 */
// TODO: consider subclasses for different types of properties
public class Property {
  private static final Logger log = Logger.getLogger(Property.class);

  private boolean oneToOne;
  private boolean oneToMany;
  private Entity entity;
  private Entity targetEntity;
  private boolean id;
  private boolean primitive;
  private boolean isInactive;
  private Class<?> primitiveType;
  private Property referencedProperty;
  private String name;
  private String columnName;
  private boolean isActiveColumn = false;
  private String nameOfColumn; // AD_COLUMN.NAME
  // note defaultValue contains the value as it exists in the db, for booleans
  // this for example Y or N
  private String defaultValue;
  private String minValue;
  private int fieldLength;
  private String maxValue;
  private boolean mandatory;
  private boolean identifier;
  private boolean parent;
  private boolean isUuid;
  private boolean isUpdatable;
  private Property idBasedOnProperty;
  private boolean isPartOfCompositeId;
  private boolean isOrderByProperty;
  private Set<String> allowedValues;
  private Boolean allowDerivedRead;
  private boolean isClientOrOrganization;

  private PropertyValidator validator;

  private boolean isCompositeId;
  private List<Property> idParts = new ArrayList<Property>();

  private boolean isAuditInfo;
  private boolean isTransient;

  private String transientCondition;

  private Module module;

  private boolean isDatetime;
  private boolean isDate;

  // keeps track of the index of this property in the entity.getProperties()
  // gives a lot of performance/memory improvements when getting property values
  private int indexInEntity;

  /**
   * Initializes this Property using the information from the Column.
   * 
   * @param fromColumn
   *          the column used to initialize this Property.
   */
  public void initializeFromColumn(Column fromColumn) {
    fromColumn.setProperty(this);
    setId(fromColumn.isKey());
    setPrimitive(fromColumn.isPrimitiveType());
    setPrimitiveType(fromColumn.getPrimitiveType());
    setDatetime(fromColumn.getReference().isDatetime());
    setDate(fromColumn.getReference().isDate());
    setIdentifier(fromColumn.isIdentifier());
    setParent(fromColumn.isParent());
    setColumnName(fromColumn.getColumnName());
    setNameOfColumn(fromColumn.getName());

    setDefaultValue(fromColumn.getDefaultValue());

    // use of the mandatory is restricted because there are many cases whereby it is set to
    // true while the underlying db column allows null, this because the mandatory value
    // is used in the ui
    // setMandatory(overrideMandatoryCustom(fromColumn));
    setMandatory(fromColumn.isMandatory());

    setMinValue(fromColumn.getValueMin());
    setMaxValue(fromColumn.getValueMax());
    setUuid(fromColumn.getReference().getName().equals("ID")
        && fromColumn.getReference().getId().equals("13"));
    setUpdatable(fromColumn.isUpdatable());
    setFieldLength(fromColumn.getFieldLength());
    setAllowedValues(fromColumn.getAllowedValues());
    final String columnname = fromColumn.getColumnName().toLowerCase();
    if (columnname.equals("line") || columnname.equals("seqno") || columnname.equals("lineno")) {
      setOrderByProperty(true);
    } else {
      setOrderByProperty(false);
    }

    setTransient(fromColumn.isTransient());
    setTransientCondition(fromColumn.getIsTransientCondition());

    setInactive(!fromColumn.isActive());

    setModule(fromColumn.getModule());
  }

  // TODO: remove this hack when possible
  // there are four columns in the Application Dictionary which have been set
  // to mandatory, while on database level the columns are not-mandatory.
  // This because it is not possible to define in a field if a field should
  // be mandatory. So these columns are hidden on windows/tabs where they
  // should not be entered.
  // private boolean overrideMandatoryCustom(Column c) {
  // final boolean columnMandatory = c.isMandatory();
  // if (c.getTable().getTableName().equalsIgnoreCase("AD_User")
  // && c.getColumnName().equalsIgnoreCase("username")) {
  // return false;
  // }
  // if (!c.getTable().getTableName().equalsIgnoreCase("M_ProductionPlan")
  // && !c.getTable().getTableName().equalsIgnoreCase("M_Production")) {
  // return columnMandatory;
  // }
  // if (c.getColumnName().equalsIgnoreCase("endtime")) {
  // return false;
  // } else if (c.getColumnName().equalsIgnoreCase("ma_costcenteruse")) {
  // return false;
  // } else if (c.getColumnName().equalsIgnoreCase("MA_Wrphase_ID")) {
  // return false;
  // } else if (c.getColumnName().equalsIgnoreCase("neededquantity")) {
  // return false;
  // } else if (c.getColumnName().equalsIgnoreCase("rejectedquantity")) {
  // return false;
  // } else {
  // return columnMandatory;
  // }
  // }

  /**
   * Initializes the name of the property. This is done separately from the
   * {@link #initializeFromColumn(Column) initializeFromColumn} method because to initialize the
   * name also information from other properties is required.
   */
  protected void initializeName() {

    // if not set compute a sensible name
    if (getName() == null) {
      setName(NamingUtil.getPropertyMappingName(this));
    }

    // correct the name with the static constant in the generated entity
    // class
    setName(NamingUtil.getStaticPropertyName(getEntity().getMappingClass(), getName()));

    getEntity().addPropertyByName(this);

    if (getName().toLowerCase().equals("creationdate") && isPrimitive()
        && Date.class.isAssignableFrom(getPrimitiveType())) {
      setAuditInfo(true);
      // ensure that the casing is correct
      setName("creationDate");
    } else if (getName().toLowerCase().equals("updated") && isPrimitive()
        && Date.class.isAssignableFrom(getPrimitiveType())) {
      setAuditInfo(true);
    } else if (getName().toLowerCase().equals("updatedby") && !isPrimitive()) {
      setAuditInfo(true);
      setName("updatedBy");
    } else if (getName().toLowerCase().equals("createdby") && !isPrimitive()) {
      setAuditInfo(true);
      setName("createdBy");
    } else {
      setAuditInfo(false);
    }
    if (getName().equals("client")) {
      setClientOrOrganization(true);
      getEntity().setClientEnabled(true);
    }
    if (getName().equals("organization")) {
      setClientOrOrganization(true);
      getEntity().setOrganizationEnabled(true);
      if (isId() || isPartOfCompositeId()) {
        getEntity().setOrganizationPartOfKey(true);
      }
    }
    if (getName().equalsIgnoreCase("active") && isPrimitive()) {
      getEntity().setActiveEnabled(true);
      setActiveColumn(true);
    }
  }

  public boolean isBoolean() {
    return isPrimitive()
        && (getPrimitiveType().getName().compareTo("boolean") == 0 || Boolean.class == getPrimitiveType());
  }

  public Entity getEntity() {
    return entity;
  }

  public void setEntity(Entity entity) {
    this.entity = entity;
  }

  public boolean isId() {
    return id;
  }

  public void setId(boolean id) {
    this.id = id;
  }

  public boolean isPrimitive() {
    return primitive;
  }

  public void setPrimitive(boolean primitive) {
    this.primitive = primitive;
  }

  /**
   * In case of an association, returns the property in the associated {@link Entity Entity} to
   * which this property refers. Returns null if there is no referenced property this occurs in case
   * of a reference to the primary key of the referenced Entity.
   * 
   * @return the associated property on the other side of the association.
   */
  public Property getReferencedProperty() {
    return referencedProperty;
  }

  /**
   * Sets the referenced property and also the {@link Property#setTargetEntity(Entity) targetEntity}
   * .
   * 
   * @param referencedProperty
   *          the property referenced by this property
   */
  public void setReferencedProperty(Property referencedProperty) {
    this.referencedProperty = referencedProperty;
    setTargetEntity(referencedProperty.getEntity());
  }

  public Entity getTargetEntity() {
    return targetEntity;
  }

  public void setTargetEntity(Entity targetEntity) {
    this.targetEntity = targetEntity;
  }

  public Class<?> getPrimitiveType() {
    return primitiveType;
  }

  public void setPrimitiveType(Class<?> primitiveType) {
    this.primitiveType = primitiveType;
  }

  public String getColumnName() {
    return columnName;
  }

  public void setColumnName(String columnName) {
    this.columnName = columnName;
  }

  /**
   * Is used by the code generation of entities. It will return a String which can be used to set in
   * the generated source code to initialize a property. For example if this is a boolean and the
   * default value in the database for the column is 'Y' then this method will return "true".
   * 
   * @return the java-valid default
   */
  public String getFormattedDefaultValue() {
    Check
        .isTrue(
            isPrimitive() || isCompositeId() || isOneToMany(),
            "Default value is only supported for composite ids, primitive types, and one-to-many properties: property "
                + this);
    if (isCompositeId()) {
      return " new Id()";
    }

    if (isOneToMany()) {
      return " new java.util.ArrayList<Object>()";
    }

    if (defaultValue == null && isBoolean()) {
      if (getName().equalsIgnoreCase("isactive")) {
        log
            .debug("Property "
                + this
                + " is probably the active column but does not have a default value set, supplying default value Y");
        defaultValue = "Y";
      } else {
        defaultValue = "N";
      }
    }

    if (defaultValue != null && isPrimitive()) {
      if (defaultValue.startsWith("@")) {
        return null;
      }
      if (defaultValue.toLowerCase().equals("sysdate")) {
        return " new java.util.Date()";
      }

      // ignore all other Date defaults for now
      if (getPrimitiveType() != null && Date.class.isAssignableFrom(getPrimitiveType())) {
        return null;
      }

      if (getPrimitiveType() == BigDecimal.class) {
        return " new java.math.BigDecimal(" + defaultValue + ")";
      }
      if (getPrimitiveType() == Float.class || getPrimitiveType() == float.class) {
        return defaultValue + "f";
      }
      if (getPrimitiveType() == Long.class || getPrimitiveType() == long.class) {
        return "(long)" + defaultValue;
      }
      if (getPrimitiveType() == String.class) {
        if (defaultValue.length() > 1
            && (defaultValue.startsWith("'") || defaultValue.startsWith("\""))) {
          defaultValue = defaultValue.substring(1);
        }
        if (defaultValue.length() > 1
            && (defaultValue.endsWith("'") || defaultValue.endsWith("\""))) {
          defaultValue = defaultValue.substring(0, defaultValue.length() - 1);
        }

        return "\"" + defaultValue + "\"";
      } else if (isBoolean()) {
        if (defaultValue.equals("Y")) {
          return "true";
        } else if (defaultValue.equals("'Y'")) {
          return "true";
        } else if (defaultValue.equals("'N'")) {
          return "false";
        } else if (defaultValue.equals("N")) {
          return "false";
        } else {
          log.error("Illegal default value for boolean property " + this
              + ", value should be Y or N and it is: " + defaultValue);
          return "false";
        }
      }
    }

    return defaultValue;
  }

  /**
   * @return true if the class of the primitive type ({@link #getPrimitiveObjectType()}) is a number
   *         (extends {@link Number}).
   */
  public boolean isNumericType() {
    final Class<?> typeClass = getPrimitiveObjectType();
    if (typeClass == null) {
      return false;
    }
    return Number.class.isAssignableFrom(typeClass);
  }

  /**
   * Returns the Object value of the default, for example a Date property with default value of
   * today will return a new Date() object.
   * 
   * @return the java object which can be used to initialize the java member corresponding to this
   *         property.
   */
  public Object getActualDefaultValue() {
    if (defaultValue == null && isBoolean()) {
      if (getName().equalsIgnoreCase("isactive")) {
        log
            .debug("Property "
                + this
                + " is probably the active column but does not have a default value set, supplying default value Y");
        setDefaultValue("Y");
      } else {
        setDefaultValue("N");
      }
    }

    if (defaultValue != null && isPrimitive()) {
      // strip the ' and ;
      if (defaultValue.startsWith("'") && defaultValue.endsWith("'")) {
        defaultValue = defaultValue.substring(1, defaultValue.length() - 1);
      }

      if (defaultValue.startsWith("@")) {
        return null;
      }
      if (defaultValue.toLowerCase().equals("sysdate")) {
        return new Date();
      }
      if (getPrimitiveType() == BigDecimal.class) {
        return new BigDecimal(defaultValue);
      }
      if (getPrimitiveType() == Float.class || getPrimitiveType() == float.class) {
        return Float.valueOf(defaultValue);
      }
      if (getPrimitiveType() == String.class) {
        return defaultValue;
      } else if (isBoolean()) {
        if (defaultValue.equals("Y")) {
          return true;
        } else if (defaultValue.equals("N")) {
          return false;
        } else {
          log.error("Illegal default value for boolean property " + this
              + ", value should be Y or N and it is: " + defaultValue);
          return false;
        }
      }
    }

    return null;
  }

  /**
   * Identifier and Id properties are derived readable, all other properties are not derived
   * readable.
   * 
   * @return true if derived readable for the current user, false otherwise.
   */
  public boolean allowDerivedRead() {
    if (allowDerivedRead == null) {
      allowDerivedRead = isActiveColumn() || isAuditInfo() || isId() || isIdentifier()
          || isClientOrOrganization();
    }
    return allowDerivedRead;
  }

  public boolean hasDefaultValue() {
    if (isCompositeId() || isOneToMany()) {
      return true;
    }
    if (!isPrimitive()) {
      return false;
    }
    return getFormattedDefaultValue() != null;
  }

  public void setDefaultValue(String defaultValue) {
    this.defaultValue = defaultValue;
  }

  public boolean isMandatory() {
    return mandatory;
  }

  public void setMandatory(boolean mandatory) {
    this.mandatory = mandatory;
  }

  public boolean isIdentifier() {
    return identifier;
  }

  public void setIdentifier(boolean identifier) {
    this.identifier = identifier;
  }

  public boolean isParent() {
    return parent;
  }

  public void setParent(boolean parent) {
    this.parent = parent;
  }

  /**
   * Returns the primitive type name or the class name of the referenced type. Used by the entity
   * code generation.
   * 
   * @return a String denoting the class name of values of this property
   */
  public String getTypeName() {
    final String typeName;
    if (isCompositeId) {
      typeName = getEntity().getClassName() + ".Id";
    } else if (isPrimitive()) {
      if (getPrimitiveType().isArray()) {
        typeName = getPrimitiveType().getComponentType().getName() + "[]";
      } else {
        typeName = getPrimitiveType().getName();
      }
    } else if (getTargetEntity() == null) {
      log.warn("ERROR NO REFERENCETYPE " + getEntity().getName() + "." + getColumnName());
      return "java.lang.Object";
    } else {
      typeName = getTargetEntity().getClassName();
    }
    return typeName;
  }

  /**
   * The last part of the class name of the type of the property. Used by the entity code
   * generation.
   */
  public String getSimpleTypeName() {
    final String typeName = getTypeName();
    if (typeName.indexOf(".") == -1) {
      return typeName;
    }
    return typeName.substring(1 + typeName.lastIndexOf("."));
  }

  /**
   * Returns the typename of the object type of this property. So a property with type int will
   * return "java.lang.Integer". Used by the entity code generation.
   * 
   * @return the class name of the object type of this property.
   */
  public String getObjectTypeName() {
    if (isPrimitive()) {
      final String typeName = getTypeName();
      if (typeName.indexOf('.') != -1) {
        return typeName;
      }
      return getPrimitiveObjectType().getName();
    } else {
      return getTypeName();
    }
  }

  /**
   * Returns the class of the type of this property, will translate primitive type classes (int) to
   * their object type (java.lang.Long for example). Used by the entity code generation.
   * 
   * @return the Object class for the primitive type
   */
  public Class<?> getPrimitiveObjectType() {
    Check.isTrue(isPrimitive(), "Only primitive types supported here");
    final String typeName = getTypeName();
    if (typeName.indexOf('.') != -1) {
      return getPrimitiveType();
    }
    if ("boolean".equals(typeName)) {
      return Boolean.class;
    }
    if ("int".equals(typeName)) {
      return Integer.class;
    }
    if ("long".equals(typeName)) {
      return Long.class;
    }
    if ("byte".equals(typeName)) {
      return Byte.class;
    }
    if ("float".equals(typeName)) {
      return Float.class;
    }
    if ("double".equals(typeName)) {
      return Double.class;
    }
    if ("byte[]".equals(typeName)) {
      return byte[].class;
    }
    Check.fail("Type " + typeName + " not supported as object type");
    // never gets here
    return null;
  }

  /**
   * @return true if the property potentially allows null values because it is an object type. Used
   *         by code generation of entities.
   */
  public boolean allowNullValues() {
    if (!isPrimitive()) {
      return true;
    }
    return (getPrimitiveType().getName().indexOf('.') != -1);
  }

  public String getName() {
    return name;
  }

  /**
   * @return the name used for creating a getter/setter in generated code.
   */
  public String getGetterSetterName() {
    if (isBoolean() && getName().startsWith("is")) {
      return getName().substring(2);
    }
    return getName();
  }

  /**
   * Checks if for an instance of the Entity a value can be written in this property. If not then a
   * ValidationException is thrown.
   * 
   * @throws ValidationException
   */
  public void checkIsWritable() {
    if (isInactive()) {
      final ValidationException ve = new ValidationException();
      ve.addMessage(this, "Property " + this + " is inactive and can therefore not be changed.");
      throw ve;
    }
  }

  /**
   * Checks if the value of the object is of the correct type and it is not null if the property is
   * mandatory. Throws a ValidationException if the value does not fit the definition of the
   * property.
   * 
   * @param value
   *          the value to check
   * @throws ValidationException
   */
  // null
  public void checkIsValidValue(Object value) {
    // note id's maybe set to null to force the creation of a new one
    // this assumes ofcourse that all ids are generated
    // also client and organization may be nullified as they are set
    // automatically

    // disabled because isMandatory should not be used right now
    // if (value == null && isMandatory() && !isId() && !isClientOrOrganization()) {
    // final ValidationException ve = new ValidationException();
    // ve.addMessage(this, "Property " + this + " is mandatory, null values are not allowed.");
    // throw ve;
    // }

    if (value == null) {
      return;
    }

    if (isOneToMany() && (value instanceof List)) {
      return;
    }

    if (!isPrimitive() && !(value instanceof BaseOBObjectDef)) {
      final ValidationException ve = new ValidationException();
      ve.addMessage(this, "Property " + this + " only allows reference instances of type "
          + BaseOBObjectDef.class.getName() + " but the value is an instanceof "
          + value.getClass().getName());
      throw ve;
    } else if (isPrimitive()) {
      // this specific conversion is allowed
      final boolean intToLong = getPrimitiveObjectType().isAssignableFrom(Long.class)
          && value.getClass().isAssignableFrom(Integer.class);

      if (!intToLong && !getPrimitiveObjectType().isInstance(value)) {
        final ValidationException ve = new ValidationException();
        ve.addMessage(this, "Property " + this + " only allows instances of "
            + getPrimitiveObjectType().getName() + " but the value is an instanceof "
            + value.getClass().getName());
        throw ve;
      }

      final PropertyValidator v = getValidator();
      if (v != null) {
        final String msg = v.validate(value);
        if (msg != null && ! msg.contains("is too long") ) {
          final ValidationException ve = new ValidationException();
          ve.addMessage(this, msg);
          throw ve;
        }
      }
    }
  }

  public void setName(String name) {
    Check.isNotNull(name, "Name property can not be null, property " + this);
    this.name = name;
  }

  public String getMinValue() {
    return minValue;
  }

  public void setMinValue(String minValue) {
    this.minValue = minValue;
  }

  public String getMaxValue() {
    return maxValue;
  }

  public void setMaxValue(String maxValue) {
    this.maxValue = maxValue;
  }

  @Override
  public String toString() {
    if (getName() == null) {
      return getEntity() + "." + getColumnName();
    }
    return getEntity() + "." + getName();
  }

  public Property getIdBasedOnProperty() {
    return idBasedOnProperty;
  }

  public void setIdBasedOnProperty(Property idBasedOnProperty) {
    this.idBasedOnProperty = idBasedOnProperty;
  }

  public boolean isOneToOne() {
    return oneToOne;
  }

  public void setOneToOne(boolean oneToOne) {
    this.oneToOne = oneToOne;
  }

  public boolean isOneToMany() {
    return oneToMany;
  }

  public void setOneToMany(boolean oneToMany) {
    this.oneToMany = oneToMany;
  }

  public boolean isUuid() {
    return isUuid;
  }

  public void setUuid(boolean isUuid) {
    this.isUuid = isUuid;
  }

  public boolean isUpdatable() {
    return isUpdatable;
  }

  public void setUpdatable(boolean isUpdatable) {
    this.isUpdatable = isUpdatable;
  }

  public boolean isCompositeId() {
    return isCompositeId;
  }

  public void setCompositeId(boolean isCompositeId) {
    this.isCompositeId = isCompositeId;
  }

  public List<Property> getIdParts() {
    return idParts;
  }

  public boolean isPartOfCompositeId() {
    return isPartOfCompositeId;
  }

  public void setPartOfCompositeId(boolean isPartOfCompositeId) {
    this.isPartOfCompositeId = isPartOfCompositeId;
  }

  public int getFieldLength() {
    return fieldLength;
  }

  public void setFieldLength(int fieldLength) {
    this.fieldLength = fieldLength;
  }

  public boolean doCheckAllowedValue() {
    return allowedValues != null && allowedValues.size() > 0;
  }

  public boolean isAllowedValue(String value) {
    return allowedValues.contains(value);
  }

  /**
   * @return a comma delimited list of allowed values, is used for enums.
   */
  public String concatenatedAllowedValues() {
    final StringBuffer sb = new StringBuffer();
    for (final String s : allowedValues) {
      if (sb.length() > 0) {
        sb.append(", ");
      }
      sb.append(s);
    }
    return sb.toString();
  }

  /**
   * Checks if the property is transient. It uses the business object and the
   * {@link #getTransientCondition() transientCondition} to compute if the property is transient
   * (won't be exported to xml).
   * 
   * @param bob
   *          the business object used to compute if the property is transient
   * @return true if the property is transient and does not need to be exported
   */
  public boolean isTransient(BaseOBObjectDef bob) {
    if (isTransient()) {
      return true;
    }

    if (getTransientCondition() != null) {
      final Boolean result = Evaluator.getInstance().evaluateBoolean(bob, getTransientCondition());
      return result;
    }
    return false;
  }

  public Set<String> getAllowedValues() {
    return allowedValues;
  }

  public void setAllowedValues(Set<String> allowedValues) {
    this.allowedValues = allowedValues;
  }

  public PropertyValidator getValidator() {
    return validator;
  }

  public void setValidator(PropertyValidator validator) {
    this.validator = validator;
  }

  public String getJavaName() {
    return NamingUtil.getSafeJavaName(getName());
  }

  public void setOrderByProperty(boolean isOrderByProperty) {
    this.isOrderByProperty = isOrderByProperty;
  }

  public boolean isOrderByProperty() {
    return isOrderByProperty;
  }

  public boolean isTransient() {
    return isTransient;
  }

  public void setTransient(boolean isTransient) {
    this.isTransient = isTransient;
  }

  public boolean isAuditInfo() {
    return isAuditInfo;
  }

  public void setAuditInfo(boolean isAuditInfo) {
    this.isAuditInfo = isAuditInfo;
  }

  public String getTransientCondition() {
    return transientCondition;
  }

  public void setTransientCondition(String transientCondition) {
    this.transientCondition = transientCondition;
  }

  public boolean isClientOrOrganization() {
    return isClientOrOrganization;
  }

  public void setClientOrOrganization(boolean isClientOrOrganization) {
    this.isClientOrOrganization = isClientOrOrganization;
  }

  public boolean isInactive() {
    return isInactive;
  }

  public void setInactive(boolean isInactive) {
    this.isInactive = isInactive;
  }

  public Module getModule() {
    return module;
  }

  public void setModule(Module module) {
    this.module = module;
  }

  public String getNameOfColumn() {
    return nameOfColumn;
  }

  public void setNameOfColumn(String nameOfColumn) {
    this.nameOfColumn = nameOfColumn;
  }

  public int getIndexInEntity() {
    return indexInEntity;
  }

  public void setIndexInEntity(int indexInEntity) {
    this.indexInEntity = indexInEntity;
  }

  public boolean isDatetime() {
    return isDatetime;
  }

  public void setDatetime(boolean isDatetime) {
    this.isDatetime = isDatetime;
  }

  public boolean isDate() {
    return isDate;
  }

  public void setDate(boolean isDate) {
    this.isDate = isDate;
  }

  public boolean isActiveColumn() {
    return isActiveColumn;
  }

  public void setActiveColumn(boolean isActiveColumn) {
    this.isActiveColumn = isActiveColumn;
  }
}
