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
 * All portions are Copyright (C) 2009-2010 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.service.system;

import java.math.*;
import java.sql.Timestamp;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.ddlutils.model.Check;
import org.apache.ddlutils.model.Database;
import org.apache.ddlutils.model.ForeignKey;
import org.apache.ddlutils.model.Index;
import org.apache.ddlutils.model.Reference;
import org.apache.ddlutils.model.Unique;
import org.apache.ddlutils.model.View;
import org.hibernate.criterion.Expression;
import org.openbravo.base.model.Entity;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.model.Property;
import org.openbravo.dal.service.OBCriteria;
import org.openbravo.dal.service.OBDal;
import org.openbravo.model.ad.datamodel.Column;
import org.openbravo.model.ad.datamodel.Table;
import org.openbravo.model.ad.module.Module;
import org.openbravo.model.ad.module.ModuleDBPrefix;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.common.enterprise.Organization;
import org.openbravo.service.system.SystemValidationResult.SystemValidationType;

/**
 * Validates the database model against the application dictionary and checks that columns are
 * inline with the application dictionary.
 * 
 * @author mtaal
 */

// check naming rule of a table, use ad_exceptions table
public class DatabaseValidator implements SystemValidator {
  private Database database;
  private boolean dbsmExecution = false;

  private static int MAX_OBJECT_NAME_LENGTH = 30;

  private StringBuilder updateSql = new StringBuilder();

  // if this is set then only module specific things are checked.
  private Module validateModule;

  public String getCategory() {
    return "Database Model";
  }

  public SystemValidationResult validate() {
    final SystemValidationResult result = new SystemValidationResult();

    // read the tables

    final OBCriteria<Table> tcs = OBDal.getInstance().createCriteria(Table.class);
    tcs.add(Expression.eq(Table.PROPERTY_ISVIEW, false));
    final List<Table> adTables = tcs.list();
    final Map<String, Table> adTablesByName = new HashMap<String, Table>();
    for (Table adTable : adTables) {
      adTablesByName.put(adTable.getTableName(), adTable);
    }

    // the following cases are checked:
    // 1) table present in ad, but not in db
    // 2) table present in db, not in ad
    // 3) table present on both sides, column match check

    final org.apache.ddlutils.model.Table[] dbTables = getDatabase().getTables();

    final Map<String, org.apache.ddlutils.model.Table> dbTablesByName = new HashMap<String, org.apache.ddlutils.model.Table>();
    for (org.apache.ddlutils.model.Table dbTable : dbTables) {
      dbTablesByName.put(dbTable.getName().toUpperCase(), dbTable);
    }
    final Map<String, org.apache.ddlutils.model.Table> tmpDBTablesByName = new HashMap<String, org.apache.ddlutils.model.Table>(
        dbTablesByName);

    final Map<String, View> dbViews = new HashMap<String, View>();
    final View[] views = getDatabase().getViews();
    for (View view : views) {
      dbViews.put(view.getName().toUpperCase(), view);
    }

    final String moduleId = (getValidateModule() == null ? null : getValidateModule().getId());
    for (Table adTable : adTables) {
      final org.apache.ddlutils.model.Table dbTable = dbTablesByName.get(adTable.getTableName()
          .toUpperCase());
      final View view = dbViews.get(adTable.getTableName().toUpperCase());
      if (view == null && dbTable == null) {
        // in Application Dictionary not in Physical Table
        if (moduleId == null
            || (adTable.getPackage().getModule() != null && adTable.getPackage()
                .getModule().getId().equals(moduleId))) {
          result.addError(SystemValidationResult.SystemValidationType.NOT_EXIST_IN_DB, "Table "
              + adTable.getTableName() + " defined in the Application Dictionary"
              + " but is not present in the database");
        }
      } else if (view != null) {
        dbViews.remove(view.getName().toUpperCase());
      } else {
        if (moduleId == null
            || (adTable.getPackage().getModule() != null && adTable.getPackage()
                .getModule().getId().equals(moduleId))) {
          checkTableWithoutPrimaryKey(dbTable, result);
          checkMaxObjectNameLength(dbTable, result);
        }
        matchColumns(adTable, dbTable, result);
        tmpDBTablesByName.remove(dbTable.getName().toUpperCase());
      }
    }
    for (int i = 0; i < database.getTableCount(); i++) {
      checkForeignKeys(database.getTable(i), result);
    }
    for (int i = 0; i < database.getModifiedTableCount(); i++) {
      checkForeignKeys(database.getModifiedTable(i), result);
    }

    // only check this one if the global validate check is done
    for (org.apache.ddlutils.model.Table dbTable : tmpDBTablesByName.values()) {
      // ignore errors related to C_TEMP_SELECTION
      if (!dbTable.getName().toUpperCase().startsWith("C_TEMP_SELECTION")) {
        result.addWarning(SystemValidationResult.SystemValidationType.NOT_EXIST_IN_AD, "Table "
            + dbTable.getName() + " present in the database "
            + " but not defined in the Application Dictionary");
      }
    }

    if (getValidateModule() == null) {
      for (View view : dbViews.values()) {
        // ignore errors related to C_TEMP_SELECTION
        if (!view.getName().toUpperCase().startsWith("C_TEMP_SELECTION")) {
          result.addWarning(SystemValidationResult.SystemValidationType.NOT_EXIST_IN_AD, "View "
              + view.getName() + " present in the database "
              + " but not defined in the Application Dictionary");
        }
      }
    }

    checkIncorrectClientOrganizationName(result);

    checkDBObjectsName(result);

    return result;
  }

  private void checkMaxObjectNameLength(org.apache.ddlutils.model.Table dbTable,
      SystemValidationResult result) {
    checkNameLength("Table", dbTable.getName(), result);
    for (org.apache.ddlutils.model.Column dbColumn : dbTable.getColumns()) {
      checkNameLength("(table: " + dbTable.getName() + ") Column ", dbColumn.getName(), result);
    }
    for (ForeignKey fk : dbTable.getForeignKeys()) {
      checkNameLength("(table: " + dbTable.getName() + ") Foreign Key ", fk.getName(), result);
    }
    for (Unique unique : dbTable.getuniques()) {
      checkNameLength("(table: " + dbTable.getName() + ") Unique Constraint ", unique.getName(),
          result);
    }
    for (Index index : dbTable.getIndices()) {
      checkNameLength("(table: " + dbTable.getName() + ") Index ", index.getName(), result);
    }
  }

  private void checkNameLength(String type, String name, SystemValidationResult result) {
    if (name.length() > MAX_OBJECT_NAME_LENGTH) {
      result.addError(SystemValidationResult.SystemValidationType.NAME_TOO_LONG, "The name of "
          + type + " " + name + " is too long, the maximum allowed length is: "
          + MAX_OBJECT_NAME_LENGTH);
    }
  }

  private void checkTableWithoutPrimaryKey(org.apache.ddlutils.model.Table dbTable,
      SystemValidationResult result) {
    if (dbTable.getPrimaryKeyColumns().length == 0) {
      result.addError(SystemValidationResult.SystemValidationType.NO_PRIMARY_KEY_COLUMNS, "Table "
          + dbTable.getName() + " has no primary key columns.");
    }
  }

  private Property getProperty(String tableName, String columnName) {
    final Entity entity = ModelProvider.getInstance().getEntityByTableName(tableName);
    if (entity == null) {
      // can happen with mismatches
      return null;
    }
    for (Property property : entity.getProperties()) {
      if (property.getColumnName() != null && property.getColumnName().equalsIgnoreCase(columnName)) {
        return property;
      }
    }
    return null;
  }

  private void checkForeignKeys(org.apache.ddlutils.model.Table table, SystemValidationResult result) {
    final Entity entity = ModelProvider.getInstance().getEntityByTableName(table.getName());
    if (entity == null) {
      // can happen with mismatches
      return;
    }
    for (Property property : entity.getProperties()) {
      if (!property.isPrimitive() && !property.isOneToMany() && !property.isAuditInfo()) {
        // check if the property column is present in a foreign key

        // special case that a property does not have a column, if it is
        // like a virtual property see ClientInformation.client
        if (property.getColumnName() == null) {
          continue;
        }

        final String colName = property.getColumnName().toUpperCase();

        // ignore this specific case
        if (entity.getTableName().equalsIgnoreCase("ad_module_log")
            && colName.equalsIgnoreCase("ad_module_id")) {
          continue;
        }

        boolean found = false;
        for (ForeignKey fk : table.getForeignKeys()) {
          for (Reference reference : fk.getReferences()) {
            if (reference.getLocalColumnName().toUpperCase().equals(colName)) {
              found = true;
              break;
            }
          }
          if (found) {
            break;
          }
        }
        if (!found) {
          result.addWarning(SystemValidationResult.SystemValidationType.NOT_PART_OF_FOREIGN_KEY,
              "Foreign Key Column " + table.getName() + "." + property.getColumnName()
                  + " is not part of a foreign key constraint.");
        }
      }
    }
  }

  private void matchColumns(Table adTable, org.apache.ddlutils.model.Table dbTable,
      SystemValidationResult result) {

    final Map<String, org.apache.ddlutils.model.Column> dbColumnsByName = new HashMap<String, org.apache.ddlutils.model.Column>();
    for (org.apache.ddlutils.model.Column dbColumn : dbTable.getColumns()) {
      dbColumnsByName.put(dbColumn.getName().toUpperCase(), dbColumn);
    }

    final String moduleId = (getValidateModule() == null ? null : getValidateModule().getId());
    for (Column column : adTable.getADColumnList()) {
      final boolean checkColumn = moduleId == null || (column.getModule().getId().equals(moduleId));
      if (!checkColumn) {
        continue;
      }
      final org.apache.ddlutils.model.Column dbColumn = dbColumnsByName.get(column
          .getColumnName().toUpperCase());
      if (dbColumn == null) {
        result.addError(SystemValidationResult.SystemValidationType.NOT_EXIST_IN_DB, "Column "
            + adTable.getTableName() + "." + column.getColumnName()
            + " defined in the Application Dictionary but not present in the database.");
      } else {
        checkDataType(column, dbColumn, result, dbTable);

        checkNameLength("(table: " + dbTable.getName() + ") Column ", dbColumn.getName(), result);

        dbColumnsByName.remove(column.getColumnName().toUpperCase());

        checkDefaultValue(column, dbColumn, result);
      }
    }

    if (moduleId == null
        || (adTable.getPackage().getModule() != null && adTable.getPackage().getModule()
            .getId().equals(moduleId))) {
      for (org.apache.ddlutils.model.Column dbColumn : dbColumnsByName.values()) {
        result.addError(SystemValidationResult.SystemValidationType.NOT_EXIST_IN_AD, "Column "
            + dbTable.getName() + "." + dbColumn.getName() + " present in the database "
            + " but not defined in the Application Dictionary.");
      }
    }
  }

  private void checkDefaultValue(Column adColumn, org.apache.ddlutils.model.Column dbColumn,
      SystemValidationResult result) {
    if (true) {
      // disable this test until the following issues are all solved:
      // https://issues.openbravo.com/view.php?id=9054
      // https://issues.openbravo.com/view.php?id=9053
      // https://issues.openbravo.com/view.php?id=9052
      // https://issues.openbravo.com/view.php?id=9051
      // https://issues.openbravo.com/view.php?id=9050
      // these cover the differences in default values
      return;
    }
    if (adColumn.getDefaultValue() == null || adColumn.getDefaultValue().startsWith("@")) {
      return;
    } else if (false && dbColumn.getDefaultValue() == null) {
      // this check is disabled for now
      result.addWarning(SystemValidationType.UNEQUAL_DEFAULTVALUE, "Column "
          + adColumn.getTable().getName() + "." + adColumn.getName() + " has default value "
          + adColumn.getDefaultValue()
          + " in the Application Dictionary but no default value in the database");
    } else if (dbColumn.getDefaultValue() != null
        && !dbColumn.getDefaultValue().equals(adColumn.getDefaultValue())) {
      result.addWarning(SystemValidationType.UNEQUAL_DEFAULTVALUE, "Column "
          + adColumn.getTable().getName() + "." + adColumn.getName()
          + ": the Application Dictionary and the database have differing default values,"
          + " AD: " + adColumn.getDefaultValue() + " DB: " + dbColumn.getDefaultValue());
    }
  }

  private void checkDataType(Column adColumn, org.apache.ddlutils.model.Column dbColumn,
      SystemValidationResult result, org.apache.ddlutils.model.Table dbTable) {

    final Property property = getProperty(dbTable.getName(), dbColumn.getName());

    // disabled because mandatory is always false
    // if (property != null && !property.isMandatory() && dbColumn.isRequired()) {
    // result.addError(
    // SystemValidationResult.SystemValidationType.NOT_NULL_IN_DB_NOT_MANDATORY_IN_AD, "Column "
    // + dbTable.getName() + "." + dbColumn.getName()
    // + " is required (not-null) but in the Application Dictonary"
    // + " it is set as non-mandatory");
    //
    // final Property p = getProperty(dbTable.getName(), dbColumn.getName());
    // updateSql
    // .append("update ad_column set ismandatory='Y' where ad_column_id in (select c.ad_column_id from ad_column c, ad_table t "
    // + "where c.ad_table_id=t.ad_table_id and t.tablename='"
    // + p.getEntity().getTableName() + "' and c.columnname='" + p.getColumnName() + "');\n");
    //
    // }

    // disabled this check, will be done in 2.60
    // if (property != null && property.isMandatory() && !dbColumn.isRequired()) {
    // result.addError(SystemValidationType.MANDATORY_IN_AD_NULLABLE_IN_DB, "Column "
    // + dbTable.getName() + "." + dbColumn.getName()
    // + " is not-required (null-allowed) but in the Application Dictonary"
    // + " it is set as mandatory");
    // }

    // check the default value
    if (property != null && property.getActualDefaultValue() != null) {
      try {
        property.checkIsValidValue(property.getActualDefaultValue());
      } catch (Exception e) {
        // actually a ValidationException is thrown but this is not
        // accepted by the compiler
        result.addError(SystemValidationType.INCORRECT_DEFAULT_VALUE, e.getMessage());
      }
    }

    if (dbColumn.isPrimaryKey()) {
      // there is a special case, the ad_script_sql has a
      // seqno has key
      if (!dbTable.getName().equalsIgnoreCase("ad_script_sql")) {
        checkType(dbColumn, dbTable, result, "VARCHAR");
        checkLength(dbColumn, dbTable, result, 32);
      }
    } else if (property != null && property.getAllowedValues().size() > 0) {
      checkType(dbColumn, dbTable, result, "VARCHAR");
      checkLength(dbColumn, dbTable, result, 60);
    } else if (property != null && property.isOneToMany()) {
      // ignore those
    } else if (property != null && !property.isPrimitive()) {

      checkType(dbColumn, dbTable, result, "VARCHAR");
      if (property.getReferencedProperty() != null) {
        checkLength(dbColumn, dbTable, result, property.getReferencedProperty().getFieldLength());
      } else {
        checkLength(dbColumn, dbTable, result, 32);
      }
    } else if (property != null && property.getPrimitiveObjectType() != null) {
      final Class<?> prim = property.getPrimitiveObjectType();
      if (prim == String.class) {
        checkType(dbColumn, dbTable, result, new String[] { "VARCHAR", "NVARCHAR", "CHAR", "NCHAR",
            "CLOB" });
        // there are too many differences which make this check not relevant/practical at the moment
        // checkLength(dbColumn, dbTable, result, property.getFieldLength());
      } else if (prim == Long.class) {
        checkType(dbColumn, dbTable, result, "DECIMAL");
      } else if (prim == Integer.class) {
        checkType(dbColumn, dbTable, result, "DECIMAL");
      } else if (prim == BigDecimal.class) {
        checkType(dbColumn, dbTable, result, "DECIMAL");
      } else if (prim == Date.class) {
        checkType(dbColumn, dbTable, result, "TIMESTAMP");
      } else if (prim == Boolean.class) {
        checkType(dbColumn, dbTable, result, "CHAR");
        checkLength(dbColumn, dbTable, result, 1);
      } else if (prim == Float.class) {
        checkType(dbColumn, dbTable, result, "DECIMAL");
      } else if (prim == Object.class) {
        // nothing to check...
      } else if (prim == Timestamp.class) {
        checkType(dbColumn, dbTable, result, "TIMESTAMP");
      }
    }
  }

  private void checkType(org.apache.ddlutils.model.Column dbColumn,
      org.apache.ddlutils.model.Table dbTable, SystemValidationResult result, String[] expectedTypes) {
    boolean found = false;
    final StringBuilder sb = new StringBuilder();
    for (String expectedType : expectedTypes) {
      sb.append(expectedType + " ");
      found = dbColumn.getType().equals(expectedType);
      if (found) {
        break;
      }
    }
    if (!found) {
      result.addError(SystemValidationType.WRONG_TYPE, "Column " + dbTable.getName() + "."
          + dbColumn.getName() + " has incorrect type, expecting " + sb.toString() + "but was "
          + dbColumn.getType());
    }
  }

  private void checkType(org.apache.ddlutils.model.Column dbColumn,
      org.apache.ddlutils.model.Table dbTable, SystemValidationResult result, String expectedType) {
    if (!dbColumn.getType().equals(expectedType)) {
      if (dbColumn.getName().toUpperCase().equals("USER1_ID")
          || dbColumn.getName().toUpperCase().equals("USER2_ID")) {
        final Property p = getProperty(dbTable.getName(), dbColumn.getName());
        updateSql
            .append("update ad_column set ad_reference_id='10', ad_reference_value_id=NULL where ad_column_id in (select c.ad_column_id from ad_column c, ad_table t "
                + "where c.ad_table_id=t.ad_table_id and t.tablename='"
                + p.getEntity().getTableName()
                + "' and c.columnname='"
                + p.getColumnName()
                + "');\n");
      }

      result.addError(SystemValidationType.WRONG_TYPE, "Column " + dbTable.getName() + "."
          + dbColumn.getName() + " has incorrect type, expecting " + expectedType + " but was "
          + dbColumn.getType());
    }
  }

  private void checkLength(org.apache.ddlutils.model.Column dbColumn,
      org.apache.ddlutils.model.Table dbTable, SystemValidationResult result, int expectedLength) {
    // special case no length check
    if ("AD_SCRIPT_SQL.SEQNO".equalsIgnoreCase(dbTable.getName() + "." + dbColumn.getName())) {
      return;
    }

    if (dbColumn.getSizeAsInt() != expectedLength) {
      result.addError(SystemValidationType.WRONG_LENGTH, "Column " + dbTable.getName() + "."
          + dbColumn.getName() + " has incorrect length, expecting " + expectedLength + " but was "
          + dbColumn.getSizeAsInt() + ". If this a foreign key column then the expected "
          + "length is either 32 (a uuid) or based on"
          + " the fieldLength (so not the db columnlength) of the referenced column"
          + ", as defined in AD_COLUMN.");
    }
  }

  // checks for all entities if the reference to the client indeed has the name client
  // and the same for the organization property
  private void checkIncorrectClientOrganizationName(SystemValidationResult result) {
    final Entity orgEntity = ModelProvider.getInstance().getEntity(Organization.ENTITY_NAME);
    final Entity clientEntity = ModelProvider.getInstance().getEntity(Client.ENTITY_NAME);
    for (Entity entity : ModelProvider.getInstance().getModel()) {
      boolean hasClientReference = false;
      boolean hasOrgReference = false;
      boolean hasValidOrg = false;
      String invalidOrgName = null;
      boolean hasValidClient = false;
      String invalidClientName = null;
      for (Property p : entity.getProperties()) {
        if (!p.isPrimitive() && p.getTargetEntity() == orgEntity && !hasValidOrg) {
          hasOrgReference = true;
          hasValidOrg = p.getName().equals(Client.PROPERTY_ORG);
          if (!hasValidOrg) {
            invalidOrgName = p.getName();
          }
        }
        if (!p.isPrimitive() && p.getTargetEntity() == clientEntity && !hasValidClient) {
          hasClientReference = true;
          hasValidClient = p.getName().equals(Organization.PROPERTY_CLIENT);
          if (!hasValidClient) {
            invalidClientName = p.getName();
          }
        }
        if (p.isPrimitive() && p.getPrimitiveObjectType() != null
            && Date.class.isAssignableFrom(p.getPrimitiveObjectType())
            && p.getName().toLowerCase().equals("created") && !entity.isTraceable()) {
          result
              .addWarning(
                  SystemValidationType.WRONG_NAME,
                  "The table has a column created, Note that the audit column which stores the creation time MUST be called: creation Date");
        }
      }
      // can this ever be false?
      if (hasClientReference && !hasValidClient) {
        result.addError(SystemValidationType.INCORRECT_CLIENT_ORG_PROPERTY_NAME, "Table  "
            + entity.getTableName() + " has a column referencing AD_Client. "
            + " The AD_Column.name (note: different from AD_Column.columnname!) of this column "
            + "should have the value " + Organization.PROPERTY_CLIENT + ", it currently has "
            + invalidClientName);
      }
      if (hasOrgReference && !hasValidOrg) {
        result.addError(SystemValidationType.INCORRECT_CLIENT_ORG_PROPERTY_NAME, "Table  "
            + entity.getTableName() + " has a column referencing AD_Org. "
            + " The AD_Column.name (note: different from AD_Column.columnname!) of this column "
            + "should have the value " + Client.PROPERTY_ORG + ", it currently has "
            + invalidOrgName);
      }
    }
  }

  /**
   * Checks DB objects naming rules for: <li>
   * Primary Keys <li>
   * Foreign Keys <li>
   * Check Constraints <li>
   * Unique Constraints <li>
   * Indexes
   * 
   */
  private void checkDBObjectsName(SystemValidationResult result) {
    if (getValidateModule() == null) {
      return;
    }

    for (org.apache.ddlutils.model.Table table : getDatabase().getTables()) {
      // Primary Key
      if (table.getPrimaryKey() != null && !table.getPrimaryKey().equals("")
          && !nameStartsByDBPrefix(table.getPrimaryKey())) {
        String errorMsg = "Table  " + table.getName() + " has primary key named "
            + table.getPrimaryKey()
            + ", which does not start with the database prefix of the module.";
        if (isDbsmExecution()) {
          result.addWarning(SystemValidationType.INCORRECT_PK_NAME, errorMsg);
        } else {
          result.addError(SystemValidationType.INCORRECT_PK_NAME, errorMsg);
        }
      }

      // Foreign Key
      for (ForeignKey fk : table.getForeignKeys()) {
        if (!nameStartsByDBPrefix(fk.getName())) {
          String errorMsg = "Table  " + table.getName() + " has foreign key named " + fk.getName()
              + ", which does not starts by module's DBPrefix.";
          if (isDbsmExecution()) {
            result.addWarning(SystemValidationType.INCORRECT_FK_NAME, errorMsg);
          } else {
            result.addError(SystemValidationType.INCORRECT_FK_NAME, errorMsg);
          }
        }
      }

      // Check constraints
      for (Check check : table.getChecks()) {
        if (!nameStartsByDBPrefix(check.getName())) {
          String errorMsg = "Table  " + table.getName() + " has check constraint key named "
              + check.getName() + ", which does not starts by module's DBPrefix.";
          if (isDbsmExecution()) {
            result.addWarning(SystemValidationType.INCORRECT_CHECK_NAME, errorMsg);
          } else {
            result.addError(SystemValidationType.INCORRECT_CHECK_NAME, errorMsg);
          }
        }
      }

      // Unique constraints
      for (Unique unique : table.getuniques()) {
        if (!nameStartsByDBPrefix(unique.getName())) {
          String errorMsg = "Table  " + table.getName() + " has unique constraint key named "
              + unique.getName() + ", which does not starts by module's DBPrefix.";
          if (isDbsmExecution()) {
            result.addWarning(SystemValidationType.INCORRECT_UNIQUE_NAME, errorMsg);
          } else {
            result.addError(SystemValidationType.INCORRECT_UNIQUE_NAME, errorMsg);
          }
        }
      }

      // Indexes
      for (Index index : table.getIndices()) {
        if (!nameStartsByDBPrefix(index.getName())) {
          String errorMsg = "Table  " + table.getName() + " has index named " + index.getName()
              + ", which does not starts by module's DBPrefix.";
          if (isDbsmExecution()) {
            result.addWarning(SystemValidationType.INCORRECT_INDEX_NAME, errorMsg);
          } else {
            result.addError(SystemValidationType.INCORRECT_INDEX_NAME, errorMsg);
          }
        }
      }
    }
  }

  private boolean nameStartsByDBPrefix(String name) {
    if (name.toUpperCase().startsWith("EM_")) {
      // belongs to another module
      return true;
    }
    for (ModuleDBPrefix dbprefix : getValidateModule().getModuleDBPrefixList()) {
      if (name.toUpperCase().startsWith(dbprefix.getName().toUpperCase() + "_")) {
        return true;
      }
    }
    return false;
  }

  public Database getDatabase() {
    return database;
  }

  public void setDatabase(Database database) {
    this.database = database;
  }

  public Module getValidateModule() {
    return validateModule;
  }

  public void setValidateModule(Module module) {
    this.validateModule = module;
  }

  public boolean isDbsmExecution() {
    return dbsmExecution;
  }

  public void setDbsmExecution(boolean dbsmExecution) {
    this.dbsmExecution = dbsmExecution;
  }

}
