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
 * All portions are Copyright (C) 2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.wad.validation;

import org.openbravo.database.ConnectionProvider;
import org.openbravo.wad.validation.WADValidationResult.WADValidationType;

/**
 * Performs a series of validations for WAD tabs. It does not use DAL but sqlc not to have to init
 * DAL for each compilation.
 * 
 */
public class WADValidator {
  private String modules;
  private ConnectionProvider conn;
  private String checkAll;
  private boolean friendlyWarnings;

  /**
   * Constructor
   * 
   * @param conn
   *          Database ConnectionProvider
   * @param moduleId
   *          Module to check
   */
  public WADValidator(ConnectionProvider conn, String modules, boolean friendlyWarnings) {
    checkAll = (modules == null || modules.equals("%") || modules.equals("")) ? "Y" : "N";
    this.modules = "'"
        + (checkAll.equals("Y") ? "%" : modules.replace(", ", ",").replace(",", "', '")) + "'";
    this.conn = conn;
    this.friendlyWarnings = friendlyWarnings;
  }

  /**
   * Performs the validations on the assigned tabs
   * 
   * @return the result of the validations
   */
  public WADValidationResult validate() {
    WADValidationResult result = new WADValidationResult();
    validateIdentifier(result);
    validateKey(result);
    validateModelObject(result);
    //validateModelObjectMapping(result);
    validateColumnNaming(result);
    validateAuxiliarInput(result);
    return result;
  }

  /**
   * Validates tables have at least one column set as identifier
   */
  private void validateIdentifier(WADValidationResult result) {
    try {
      WADValidatorData data[] = WADValidatorData.checkIdentifier(conn, modules, checkAll);
      for (WADValidatorData issue : data) {
        result.addError(WADValidationType.MISSING_IDENTIFIER, "Table " + issue.objectname
            + " has not identifier.");
        result.addModule(issue.modulename);
      }
    } catch (Exception e) {
      result.addWarning(WADValidationType.SQL,
          "Error when executing query for validating identifiers: " + e.getMessage());
    }
  }

  /**
   * Validates tables have a primary key column
   */
  private void validateKey(WADValidationResult result) {
    try {
      WADValidatorData data[] = WADValidatorData.checkKey(conn, modules, checkAll);
      for (WADValidatorData issue : data) {
        result.addError(WADValidationType.MISSING_KEY, "Table " + issue.objectname
            + " has not primary key.");
        result.addModule(issue.modulename);
      }
    } catch (Exception e) {
      result.addWarning(WADValidationType.SQL,
          "Error when executing query for validating primary keys: " + e.getMessage());
    }
  }

  /**
   * Validates all classes defined in model object are inside the module package
   */
  private void validateModelObject(WADValidationResult result) {
    try {
      WADValidatorData data[] = WADValidatorData.checkModelObject(conn, modules, checkAll);
      //for (WADValidatorData issue : data) {
      //  result.addError(WADValidationType.MODEL_OBJECT, issue.objecttype + " " + issue.objectname
      //      + " has classname: " + issue.currentvalue + ". But it should be in "
      //      + issue.expectedvalue + " package.");
      //  result.addModule(issue.modulename);
      //}
    } catch (Exception e) {
      result.addWarning(WADValidationType.SQL,
          "Error when executing query for validating moel object: " + e.getMessage());
    }
  }

  /**
   * Validates all mappings for modules start by the java package
   */
  private void validateModelObjectMapping(WADValidationResult result) {
    try {
      WADValidatorData data[] = WADValidatorData.checkModelObjectMapping(conn, modules, checkAll);
      for (WADValidatorData issue : data) {
        result.addError(WADValidationType.MODEL_OBJECT_MAPPING, issue.objecttype + " "
            + issue.objectname + " has mapping: " + issue.currentvalue
            + ". But it should start with /" + issue.expectedvalue + ".");
        result.addModule(issue.modulename);
      }
    } catch (Exception e) {
      result.addWarning(WADValidationType.SQL,
          "Error when executing query for validating moel object: " + e.getMessage());
    }
  }

  /**
   * Validates names and columnnames in columns
   */
  private void validateColumnNaming(WADValidationResult result) {
    try {
      WADValidatorData data[] = WADValidatorData.checkColumnName(conn, modules, checkAll);
      for (WADValidatorData issue : data) {
        result.addError(WADValidationType.COLUMN_NAME, issue.objecttype + " " + issue.objectname
            + " has value: " + issue.currentvalue + ". But it should start with "
            + issue.expectedvalue);
        result.addModule(issue.modulename);
      }
    } catch (Exception e) {
      result.addWarning(WADValidationType.SQL,
          "Error when executing query for validating moel object: " + e.getMessage());
    }
  }

  /**
   * Validates names of auxiliar inputs columns
   */
  private void validateAuxiliarInput(WADValidationResult result) {
    try {
      WADValidatorData data[] = WADValidatorData.checkAuxiliarInput(conn, modules, checkAll);
      for (WADValidatorData issue : data) {
        result.addError(WADValidationType.AUXILIARINPUT, issue.objectname
            + " does not start by its module's DBPrefix: " + issue.expectedvalue);
      }
    } catch (Exception e) {
      result.addWarning(WADValidationType.SQL,
          "Error when executing query for validating moel object: " + e.getMessage());
    }
  }
}
