/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
***************************************************************************************************************************************************
 */
package org.openbravo.erpCommon.utility;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Hashtable;
import java.util.Vector;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.openbravo.base.exception.OBException;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.UtilSql;
import org.openbravo.database.ConnectionProvider;

/**
 * @author Fernando Iriazabal
 * 
 *         This class builds the queries for populating the different kind of combos in the
 *         application.
 */
public class ComboTableData {
  private static Logger log4j = Logger.getLogger(ComboTableData.class);
  private final String internalPrefix = "@@";
  private static final String FIELD_CONCAT = " || ' - ' || ";
  private static final String INACTIVE_DATA = "**";
  private VariablesSecureApp vars;
  private ConnectionProvider pool;
  private Hashtable<String, String> parameters = new Hashtable<String, String>();
  private Vector<QueryParameterStructure> paramSelect = new Vector<QueryParameterStructure>();
  private Vector<QueryParameterStructure> paramFrom = new Vector<QueryParameterStructure>();
  private Vector<QueryParameterStructure> paramWhere = new Vector<QueryParameterStructure>();
  private Vector<QueryParameterStructure> paramOrderBy = new Vector<QueryParameterStructure>();
  private Vector<QueryFieldStructure> select = new Vector<QueryFieldStructure>();
  private Vector<QueryFieldStructure> from = new Vector<QueryFieldStructure>();
  private Vector<QueryFieldStructure> where = new Vector<QueryFieldStructure>();
  private Vector<QueryFieldStructure> orderBy = new Vector<QueryFieldStructure>();
  private int index = 0;
  private String readonlyidselect=""; 

  /**
   * Constructor
   */
  public ComboTableData() {
  }

  public void addreadonlyIDselect (String idvalue){
    readonlyidselect=idvalue;
  }
  /**
   * Constructor
   * 
   * @param _conn
   *          Object with the database connection methods.
   * @param _referenceType
   *          String with the type of reference.
   * @param _name
   *          String with the Object name.
   * @param _objectReference
   *          String with id to the reference value.
   * @param _validation
   *          String with the id to the validation.
   * @param _orgList
   *          String with the list of granted organizations.
   * @param _clientList
   *          String with the list of granted clients.
   * @param _index
   *          String with the id of the default value for the combo.
   * @throws Exception
   */
  public ComboTableData(ConnectionProvider _conn, String _referenceType, String _name,
      String _objectReference, String _validation, String _orgList, String _clientList, int _index)
      throws Exception {
    this(null, _conn, _referenceType, _name, _objectReference, _validation, _orgList, _clientList,
        _index);
  }

  /**
   * Constructor
   * 
   * @param _vars
   *          Object with the session methods.
   * @param _conn
   *          Object with the database connection methods.
   * @param _referenceType
   *          String with the type of reference.
   *            case 17: // List
                case 18: // Table
                case 19: // TableDir
                case 30: // Search
                case 31: // Locator
                case 35: ???
                case 25: // Account
                case 800011: // Product Search
   * @param _name
   *          String with the Object name.
   * @param _objectReference
   *          String with id to the reference value.
   * @param _validation
   *          String with the id to the validation.
   * @param _orgList
   *          String with the list of granted organizations.
   * @param _clientList
   *          String with the list of granted clients.
   * @param _index
   *          String with the id of the default value for the combo.
   * @throws Exception
   */
  public ComboTableData(VariablesSecureApp _vars, ConnectionProvider _conn, String _referenceType,
      String _name, String _objectReference, String _validation, String _orgList,
      String _clientList, int _index) throws Exception {
    if (_vars != null)
      setVars(_vars);
    setPool(_conn);
    setReferenceType(_referenceType);
    setObjectName(_name);
    setObjectReference(_objectReference);
    setValidation(_validation);
    setOrgList(_orgList);
    setClientList(_clientList);
    setIndex(_index);
    generateSQL();
    parseNames();
  }

  /**
   * Setter for the session object.
   * 
   * @param _vars
   *          New session object.
   * @throws Exception
   */
  private void setVars(VariablesSecureApp _vars) throws Exception {
    if (_vars == null)
      throw new Exception("The session vars is null");
    this.vars = _vars;
  }

  /**
   * Getter for the session object.
   * 
   * @return Session object.
   */
  private VariablesSecureApp getVars() {
    return this.vars;
  }

  /**
   * Setter for the database handler object.
   * 
   * @param _conn
   *          New database handler object.
   * @throws Exception
   */
  private void setPool(ConnectionProvider _conn) throws Exception {
    if (_conn == null)
      throw new Exception("The pool is null");
    this.pool = _conn;
  }

  /**
   * Getter for the database handler object.
   * 
   * @return Database handler object.
   */
  private ConnectionProvider getPool() {
    return this.pool;
  }

  /**
   * Setter for the reference type id.
   * 
   * @param _reference
   *          String with the new reference
   * @throws Exception
   */
  private void setReferenceType(String _reference) throws Exception {
    if (_reference != null && !_reference.equals("")) {
      try {
        Integer.valueOf(_reference).intValue();
      } catch (Exception ignore) {
        if (!Utility.isUUIDString(_reference))
          _reference = ComboTableQueryData.getReferenceID(getPool(), _reference, "D");
      }
    }
    setParameter(internalPrefix + "reference", _reference);
  }

  /**
   * Getter for the reference type id.
   * 
   * @return String with the reference type id.
   */
  private String getReferenceType() {
    return getParameter(internalPrefix + "reference");
  }

  /**
   * Setter for the object name.
   * 
   * @param _name
   *          String with the new object name.
   * @throws Exception
   */
  private void setObjectName(String _name) throws Exception {
    setParameter(internalPrefix + "name", _name);
  }

  /**
   * Getter for the object name.
   * 
   * @return String with the object name.
   */
  private String getObjectName() {
    return getParameter(internalPrefix + "name");
  }

  /**
   * Setter for the object reference id.
   * 
   * @param _reference
   *          String with the new object reference id.
   * @throws Exception
   */
  private void setObjectReference(String _reference) throws Exception {
    if (_reference != null && !_reference.equals("")) {
      try {
        Integer.valueOf(_reference).intValue();
      } catch (Exception ignore) {
        if (!Utility.isUUIDString(_reference)) {
          // Looking reference by name! This shouldn't be used, name is prone to change. It only
          // looks in core names
          _reference = ComboTableQueryData.getReferenceID(getPool(), _reference,
              (getReferenceType().equals("17") ? "L" : "T"));
          if (_reference == null || _reference.equals("")) {
            throw new OBException(Utility.messageBD(pool, "ReferenceNotFound", vars.getLanguage())
                + " " + _reference);
          }
        }
      }
    }
    setParameter(internalPrefix + "objectReference", _reference);
  }

  /**
   * Getter for the object reference id.
   * 
   * @return String with the object reference id.
   */
  private String getObjectReference() {
    return getParameter(internalPrefix + "objectReference");
  }

  /**
   * Setter for the validation id.
   * 
   * @param _reference
   *          String for the new validation id.
   * @throws Exception
   */
  private void setValidation(String _reference) throws Exception {
    if (_reference != null && !_reference.equals("")) {
      try {
        Integer.valueOf(_reference).intValue();
      } catch (Exception ignore) {
        if (!Utility.isUUIDString(_reference))
          _reference = ComboTableQueryData.getValidationID(getPool(), _reference);
      }
    }
    setParameter(internalPrefix + "validation", _reference);
  }

  /**
   * Getter for the validation id.
   * 
   * @return String with the validation id.
   */
  private String getValidation() {
    return getParameter(internalPrefix + "validation");
  }

  /**
   * Setter for the granted organizations list.
   * 
   * @param _orgList
   *          String with the new granted organizations list.
   * @throws Exception
   */
  private void setOrgList(String _orgList) throws Exception {
    setParameter(internalPrefix + "orgList", _orgList);
  }

  /**
   * Getter for the granted organizations list.
   * 
   * @return String with the granted organizations list.
   */
  private String getOrgList() {
    return getParameter(internalPrefix + "orgList");
  }

  /**
   * Setter for the granted clients list.
   * 
   * @param _clientList
   *          String with the new granted clients list.
   * @throws Exception
   */
  private void setClientList(String _clientList) throws Exception {
    setParameter(internalPrefix + "clientList", _clientList);
  }

  /**
   * Getter for the granted clients list.
   * 
   * @return String with the granted clients list.
   */
  private String getClientList() {
    return getParameter(internalPrefix + "clientList");
  }

  /**
   * Adds new field to the select section of the query.
   * 
   * @param _field
   *          String with the field.
   * @param _alias
   *          String with the alias for this field.
   */
  private void addSelectField(String _field, String _alias) {
    QueryFieldStructure p = new QueryFieldStructure(_field, " AS ", _alias, "SELECT");
    if (this.select == null)
      this.select = new Vector<QueryFieldStructure>();
    select.addElement(p);
  }

  /**
   * Gets the defined fields for the select section of the query.
   * 
   * @return Vector with the select's fields.
   */
  private Vector<QueryFieldStructure> getSelectFields() {
    return this.select;
  }

  /**
   * Adds new field to the from section of the query.
   * 
   * @param _field
   *          String with the field.
   * @param _alias
   *          String with the alias for the field.
   */
  private void addFromField(String _field, String _alias) {
    QueryFieldStructure p = new QueryFieldStructure(_field, " ", _alias, "FROM");
    if (this.from == null)
      this.from = new Vector<QueryFieldStructure>();
    from.addElement(p);
  }

  /**
   * Gets the defined fields for the from section of the query.
   * 
   * @return Vector with the from's fields.
   */
  private Vector<QueryFieldStructure> getFromFields() {
    return this.from;
  }

  /**
   * Adds new field to the where section of the query.
   * 
   * @param _field
   *          String with the field.
   * @param _type
   *          String for group fields.
   */
 private void addWhereField(String _field, String _type) {
    QueryFieldStructure p = new QueryFieldStructure(_field, "", "", _type);
    if (this.where == null)
      this.where = new Vector<QueryFieldStructure>();
    where.addElement(p);
  }

  /**
   * Gets the defined fields for the where section of the query.
   * 
   * @return Vector with the where's fields.
   */
  private Vector<QueryFieldStructure> getWhereFields() {
    return this.where;
  }

  /**
   * Adds new field to the order by section of the query.
   * 
   * @param _field
   *          String with the field.
   */
  private void addOrderByField(String _field) {
    QueryFieldStructure p = new QueryFieldStructure(_field, "", "", "ORDERBY");
    if (this.orderBy == null)
      this.orderBy = new Vector<QueryFieldStructure>();
    orderBy.addElement(p);
  }

  /**
   * Gets the defined fields for the order by section of the query.
   * 
   * @return Vector with the order by's fields.
   */
  private Vector<QueryFieldStructure> getOrderByFields() {
    return this.orderBy;
  }

  /**
   * Adds a new parameter to the select section of the query.
   * 
   * @param _parameter
   *          String with the parameter.
   * @param _fieldName
   *          String with the name of the field.
   */
  private void addSelectParameter(String _parameter, String _fieldName) {
    if (this.paramSelect == null)
      this.paramSelect = new Vector<QueryParameterStructure>();
    QueryParameterStructure aux = new QueryParameterStructure(_parameter, _fieldName, "SELECT");
    paramSelect.addElement(aux);
  }

  /**
   * Gets all the defined parameters for the select section.
   * 
   * @return Vector with the parameters.
   */
  private Vector<QueryParameterStructure> getSelectParameters() {
    return this.paramSelect;
  }

  /**
   * Adds a new parameter to the from section of the query.
   * 
   * @param _parameter
   *          String with the parameter.
   * @param _fieldName
   *          String with the name od the field.
   */
  private void addFromParameter(String _parameter, String _fieldName) {
    if (this.paramFrom == null)
      this.paramFrom = new Vector<QueryParameterStructure>();
    QueryParameterStructure aux = new QueryParameterStructure(_parameter, _fieldName, "FROM");
    paramFrom.addElement(aux);
  }

  /**
   * Gets the defined parameters for the from section.
   * 
   * @return Vector with the parameters.
   */
  private Vector<QueryParameterStructure> getFromParameters() {
    return this.paramFrom;
  }

  /**
   * Adds a new parameter to the where section of the query.
   * 
   * @param _parameter
   *          String with the parameter.
   * @param _fieldName
   *          String with the name of the field.
   * @param _type
   *          String with a group name.
   */
  private void addWhereParameter(String _parameter, String _fieldName, String _type) {
    if (this.paramWhere == null)
      this.paramWhere = new Vector<QueryParameterStructure>();
    QueryParameterStructure aux = new QueryParameterStructure(_parameter, _fieldName, _type);
    paramWhere.addElement(aux);
  }

  /**
   * Gets the parameters defined for the where section.
   * 
   * @return Vector with the parameters.
   */
  private Vector<QueryParameterStructure> getWhereParameters() {
    return this.paramWhere;
  }

  /**
   * Adds a new parameter to the order by section of the query.
   * 
   * @param _parameter
   *          String with the parameter.
   * @param _fieldName
   *          String with the name of the field.
   */
  private void addOrderByParameter(String _parameter, String _fieldName) {
    if (this.paramOrderBy == null)
      this.paramOrderBy = new Vector<QueryParameterStructure>();
    QueryParameterStructure aux = new QueryParameterStructure(_parameter, _fieldName, "ORDERBY");
    paramOrderBy.addElement(aux);
  }

  /**
   * Gets the parameters for the order by section.
   * 
   * @return Vector with the parameters.
   */
  private Vector<QueryParameterStructure> getOrderByParameters() {
    return this.paramOrderBy;
  }

  /**
   * Setter for the parameters value.
   * 
   * @param name
   *          The name of the field defined for the parameter.
   * @param value
   *          The value for this parameter.
   * @throws Exception
   */
  void setParameter(String name, String value) throws Exception {
    if (name == null || name.equals(""))
      throw new Exception("Invalid parameter name");
    if (this.parameters == null)
      this.parameters = new Hashtable<String, String>();
    if (value == null || value.equals(""))
      this.parameters.remove(name.toUpperCase());
    else
      this.parameters.put(name.toUpperCase(), value);
  }

  /**
   * Getter for the parameters value.
   * 
   * @param name
   *          The name of the field defined for the parameter.
   * @return String with the value.
   */
  private String getParameter(String name) {
    if (name == null || name.equals(""))
      return "";
    else if (this.parameters == null)
      return "";
    else
      return this.parameters.get(name.toUpperCase());
  }

  /**
   * Gets the values for all of the defined parameters in the query.
   * 
   * @return Vector with the values.
   */
  Vector<String> getParameters() {
    Vector<String> result = new Vector<String>();
    if (log4j.isDebugEnabled())
      log4j.debug("Obtaining parameters");
    Vector<QueryParameterStructure> vAux = getSelectParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        String strAux = getParameter(aux.getName());
        if (strAux == null || strAux.equals(""))
          result.addElement(aux.getName());
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug("Select parameters obtained");
    vAux = getFromParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        String strAux = getParameter(aux.getName());
        if (strAux == null || strAux.equals(""))
          result.addElement(aux.getName());
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug("From parameters obtained");
    vAux = getWhereParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        String strAux = getParameter(aux.getName());
        if (strAux == null || strAux.equals(""))
          result.addElement(aux.getName());
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug("Where parameters obtained");
    vAux = getOrderByParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        String strAux = getParameter(aux.getName());
        if (strAux == null || strAux.equals(""))
          result.addElement(aux.getName());
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug("Order by parameters obtained");
    result.addElement("#AD_LANGUAGE");
    return result;
  }

  /**
   * Setter for the table alias index.
   * 
   * @param _index
   *          Integer with the new index.
   */
  private void setIndex(int _index) {
    this.index = _index;
  }

  /**
   * Getter for the table alias index.
   * 
   * @return Integer with the index.
   */
  private int getIndex() {
    return this.index;
  }

  /**
   * Main method to build the query.
   * 
   * @throws Exception
   */
  private void generateSQL() throws Exception {
    if (getPool() == null)
      throw new Exception("No pool defined for database connection");
    else if (getReferenceType().equals(""))
      throw new Exception("No reference type defined");

    identifier("", null);
  }

  /**
   * Auxiliar method to build the query for list types.
   * 
   * @param tableName
   *          Name of the table
   * @param fieldName
   *          Name of the field.
   * @param referenceValue
   *          Id of the reference value.
   * @throws Exception
   */
  private void setListQuery(String tableName, String fieldName, String referenceValue)
      throws Exception {
    int myIndex = this.index++;
    addSelectField("td" + myIndex + ".value", "id");
    addSelectField("((CASE td" + myIndex + ".isActive WHEN 'N' THEN '" + INACTIVE_DATA
        + "' ELSE '' END) || td" + myIndex
        + ".name)", "NAME");
    addSelectField("td" + myIndex+ ".description", "DESCRIPTION");
    String tables = "ad_ref_list_v td" + myIndex;
    if (tableName != null && tableName.length() != 0 && fieldName != null
        && fieldName.length() != 0){
      if (tableName.equalsIgnoreCase("ad_ref_list"))
        tableName="ad_ref_list_v";
      tables += " on " + tableName + "." + fieldName + " = td" + myIndex + ".value ";
    }
    addFromField(tables, "td" + myIndex);
    //addFromField("ad_ref_list_trl td_trl" + myIndex + " on td" + myIndex
    //    + ".ad_ref_list_id = td_trl" + myIndex + ".ad_ref_list_id AND td_trl" + myIndex
    //    + ".ad_language = ?", "td_trl" + myIndex);
    //addFromParameter("#AD_LANGUAGE", "LANGUAGE");
    addWhereField("td" + myIndex + ".ad_language = (?)", "LANGUAGE");
    addWhereParameter("LANGUAGE", "LANGUAGE", "KEY");
    setParameter("LANGUAGE",vars.getLanguage());
    addWhereField("td" + myIndex + ".ad_reference_id = (?)", "KEY");
    if (referenceValue == null || referenceValue.equals("")) {
      addWhereParameter("AD_REFERENCE_ID", "KEY", "KEY");
      setParameter("AD_REFERENCE_ID", getObjectReference());
    } else {
      addWhereParameter("TD" + myIndex + ".AD_REFERENCE_ID", "KEY", "KEY");
      setParameter("TD" + myIndex + ".AD_REFERENCE_ID", referenceValue);
    }
    if (tableName == null || tableName.length() == 0) {
      parseValidation();
      addWhereField("(td" + myIndex + ".isActive = 'Y' OR td" + myIndex + ".Value = ? )",
          "ISACTIVE");
      addWhereParameter("@ACTUAL_VALUE@", "ACTUAL_VALUE", "ISACTIVE");
    }
    addOrderByField("td" + myIndex + ".seqno");
  }

  /**
   * Auxiliar method to build the query for the Table type
   * 
   * @param tableName
   *          Name of the table
   * @param fieldName
   *          Name of the field.
   * @param referenceValue
   *          Id of the reference value.
   * @throws Exception
   */
  private void setTableQuery(String tableName, String fieldName, String referenceValue)
      throws Exception {
    int myIndex = this.index++;
    ComboTableQueryData trd[] = ComboTableQueryData.selectRefTable(getPool(),
        ((referenceValue != null && !referenceValue.equals("")) ? referenceValue
            : getObjectReference()));
    if (trd == null || trd.length == 0)
      return;
    addSelectField("td" + myIndex + "." + trd[0].keyname, "ID");
    if (trd[0].isvaluedisplayed.equals("Y"))
      addSelectField("td" + myIndex + ".VALUE", "NAME");
    ComboTableQueryData fieldsAux = new ComboTableQueryData();
    fieldsAux.name = trd[0].name;
    fieldsAux.tablename = trd[0].tablename;
    fieldsAux.reference = trd[0].reference;
    fieldsAux.referencevalue = trd[0].referencevalue;
    fieldsAux.required = trd[0].required;
    String tables = trd[0].tablename + " td" + myIndex;
    if (tableName != null && !tableName.equals("") && fieldName != null && !fieldName.equals("")) {
      tables += " on " + tableName + "." + fieldName + " = td" + myIndex + "." + trd[0].keyname
          + " \n";
      tables += "AND td" + myIndex + ".AD_Client_ID IN (" + getClientList() + ") \n";
      tables += "AND td" + myIndex + ".AD_Org_ID IN (" + getOrgList() + ")";
    } else {
      addWhereField("td" + myIndex + ".AD_Client_ID IN (" + getClientList() + ")", "CLIENT_LIST");
      if (getOrgList() != null)
        addWhereField("td" + myIndex + ".AD_Org_ID IN (" + getOrgList() + ")", "ORG_LIST");
    }
    addFromField(tables, "td" + myIndex);
    String strSQL = trd[0].whereclause;
    if (strSQL == null)
      strSQL = "";

    if (!strSQL.equals("")) {
      if (strSQL.indexOf("@") != -1)
        strSQL = parseContext(strSQL, "WHERE");
      addWhereField(strSQL, "FILTER");
    }
    if (tableName == null || tableName.equals("")) {
      parseValidation();
      addWhereField("(td" + myIndex + ".isActive = 'Y' OR td" + myIndex + "." + trd[0].keyname
          + " = (?) )", "ISACTIVE");
      addWhereParameter("@ACTUAL_VALUE@", "ACTUAL_VALUE", "ISACTIVE");
    }
    String orderByAux = (trd[0].orderbyclause.equals("") ? "2" : trd[0].orderbyclause);
    if (orderByAux.indexOf("@") != -1)
      orderByAux = parseContext(orderByAux, "ORDERBY");
    identifier("td" + myIndex, fieldsAux);
    addOrderByField(orderByAux);
  }

  /**
   * Auxiliar method to build the query for the TableDir type.
   * 
   * @param tableName
   *          Name of the table.
   * @param fieldName
   *          Name of the field.
   * @param parentFieldName
   *          Real name of the parent column.
   * @throws Exception
   */
  private void setTableDirQuery(String tableName, String fieldName, String parentFieldName)
      throws Exception {
    int myIndex = this.index++;
    String name = ((fieldName != null && !fieldName.equals("")) ? fieldName : getObjectName());

    String tableDirName;
    if (name.equalsIgnoreCase("createdby") || name.equalsIgnoreCase("updatedby")) {
      tableDirName = "AD_User";
      name = "AD_User_ID";
    } else {
      tableDirName = name.substring(0, name.length() - 3);
    }
    ComboTableQueryData trd[] = ComboTableQueryData.identifierColumns(getPool(), tableDirName);
    addSelectField("td" + myIndex + "." + name, "ID");

    String tables = tableDirName + " td" + myIndex;
    if (tableName != null && !tableName.equals("") && parentFieldName != null
        && !parentFieldName.equals("")) {
      tables += " on " + tableName + "." + parentFieldName + " = td" + myIndex + "." + name + "\n";
      tables += "AND td" + myIndex + ".AD_Client_ID IN (" + getClientList() + ") \n";
      tables += "AND td" + myIndex + ".AD_Org_ID IN (" + getOrgList() + ")";
    } else {
      addWhereField("td" + myIndex + ".AD_Client_ID IN (" + getClientList() + ")", "CLIENT_LIST");
      if (getOrgList() != null)
        addWhereField("td" + myIndex + ".AD_Org_ID IN (" + getOrgList() + ")", "ORG_LIST");
    }
    addFromField(tables, "td" + myIndex);
    if (tableName == null || tableName.equals("")) {
      parseValidation();
      addWhereField("(td" + myIndex + ".isActive = 'Y' OR td" + myIndex + "." + name + " = (?) )",
          "ISACTIVE");
      addWhereParameter("@ACTUAL_VALUE@", "ACTUAL_VALUE", "ISACTIVE");
    }
    for (int i = 0; i < trd.length; i++)
      identifier("td" + myIndex, trd[i]);
    addOrderByField("2");
  }

  /**
   * Method to fix the names of the fields. Searchs all the fields in the where clause and order by
   * clause to change the names with correct aliases. This intends to fix the problem of the names
   * in the whereclauses, filterclauses and orderbyclauses fields of the tab's table, where the user
   * doesn´t know the alias of the referenced field.
   */
  private void parseNames() {
    Vector<QueryFieldStructure> tables = getFromFields();
    if (tables == null || tables.size() == 0)
      return;
    if (where != null && where.size() > 0) {
      for (int i = 0; i < where.size(); i++) {
        QueryFieldStructure auxStructure = where.elementAt(i);
        if (auxStructure.getType().equalsIgnoreCase("FILTER")) {
          String strAux = auxStructure.getField();
          for (int j = 0; j < tables.size(); j++) {
            QueryFieldStructure auxTable = tables.elementAt(j);
            String strTable = auxTable.getField();
            int p = strTable.indexOf(" ");
            if (p != -1)
              strTable = strTable.substring(0, p).trim();
            strAux = replaceIgnoreCase(strAux, strTable + ".", auxTable.getAlias() + ".");
          }
          if (!strAux.equalsIgnoreCase(auxStructure.getField())) {
            auxStructure.setField(strAux);
            if (log4j.isDebugEnabled())
              log4j.debug("Field replaced: " + strAux);
            where.set(i, auxStructure);
          }
        }
      }
    }
    if (orderBy != null && orderBy.size() > 0) {
      for (int i = 0; i < orderBy.size(); i++) {
        QueryFieldStructure auxStructure = orderBy.elementAt(i);
        String strAux = auxStructure.getField();
        for (int j = 0; j < tables.size(); j++) {
          QueryFieldStructure auxTable = tables.elementAt(j);
          String strTable = auxTable.getField();
          int p = strTable.indexOf(" ");
          if (p != -1)
            strTable = strTable.substring(0, p).trim();
          strAux = replaceIgnoreCase(strAux, strTable + ".", auxTable.getAlias() + ".");
        }
        if (!strAux.equalsIgnoreCase(auxStructure.getField())) {
          auxStructure.setField(strAux);
          if (log4j.isDebugEnabled())
            log4j.debug("Field replaced: " + strAux);
          orderBy.set(i, auxStructure);
        }
      }
    }
  }

  /**
   * Auxiliar method to make a replace ignoring the case.
   * 
   * @param data
   *          String with the text.
   * @param replaceWhat
   *          The string to search.
   * @param replaceWith
   *          The new string to replace with.
   * @return String with the text replaced.
   */
  private String replaceIgnoreCase(String data, String replaceWhat, String replaceWith) {
    if (data == null || data.equals(""))
      return "";
    if (log4j.isDebugEnabled())
      log4j.debug("parsing data: " + data + " - replace: " + replaceWhat + " - with: "
          + replaceWith);
    StringBuffer text = new StringBuffer();
    int i = data.toUpperCase().indexOf(replaceWhat.toUpperCase());
    while (i != -1) {
      text.append(data.substring(0, i)).append(replaceWith);
      data = data.substring(i + replaceWhat.length());
      i = data.toUpperCase().indexOf(replaceWhat.toUpperCase());
    }
    text.append(data);
    return text.toString();
  }

  /**
   * Parse the validation string searching the @ elements and replacing them with the correct
   * values, adding the needed parameters.
   * 
   * @throws Exception
   */
  private void parseValidation() throws Exception {
    if (getValidation() == null || getValidation().equals(""))
      return;
    if (log4j.isDebugEnabled())
      log4j.debug("Validation id: " + getValidation());
    String val = ComboTableQueryData.getValidation(getPool(), getValidation());
    if (log4j.isDebugEnabled())
      log4j.debug("Validation text: " + val);
    if (val.indexOf("@") != -1)
      val = parseContext(val, "WHERE");
    if (!val.equals(""))
      addWhereField(val, "FILTER");
    if (log4j.isDebugEnabled())
      log4j.debug("Validation parsed: " + val);
  }

  /**
   * Auxiliar method to replace the variable sections of the clauses.
   * 
   * @param context
   *          String with the variable.
   * @param type
   *          String with the type of the clause (WHERE, ORDER...)
   * @return String with the text replaced.
   */
  private String parseContext(String context, String type) {
    if (context == null || context.equals(""))
      return "";
    StringBuffer strOut = new StringBuffer();
    String value = new String(context);
    String token, defStr;
    int i = value.indexOf("@");
    while (i != -1) {
      strOut.append(value.substring(0, i));
      value = value.substring(i + 1);
      int j = value.indexOf("@");
      if (j == -1) {
        strOut.append(value);
        return strOut.toString();
      }
      token = value.substring(0, j);
      if (token.equalsIgnoreCase("#User_Client"))
        defStr = getClientList();
      else if (token.equalsIgnoreCase("#User_Org"))
        defStr = getOrgList();
      else
        defStr = "?";

      if (defStr.equals("?")) {
        if (type.equalsIgnoreCase("WHERE"))
          addWhereParameter(token, "FILTER", "FILTER");
        else if (type.equalsIgnoreCase("ORDERBY"))
          addOrderByParameter(token, "FILTER");
      }
      strOut.append(defStr);
      value = value.substring(j + 1);
      i = value.indexOf("@");
    }
    strOut.append(value);
    return strOut.toString().replace("'?'", "?");
  }

  /**
   * Support method for the generateSQL method, to build the query.
   * 
   * @param tableName
   *          String with the name of the table.
   * @param field
   *          String with the name of the field.
   * @throws Exception
   */
  private void identifier(String tableName, FieldProvider field) throws Exception {
    String reference;
    if (field == null)
      reference = getReferenceType();
    else
      reference = field.getField("reference");
    switch (Integer.valueOf(reference).intValue()) {
    case 17: // List
      setListQuery(tableName, ((field == null) ? "" : field.getField("name")),
          ((field == null) ? "" : field.getField("referencevalue")));
      break;
    case 18: // Table
      setTableQuery(tableName, ((field == null) ? "" : field.getField("name")),
          ((field == null) ? "" : field.getField("referencevalue")));
      break;
    case 19: // TableDir
      setTableDirQuery(tableName, ((field == null) ? "" : field.getField("name")),
          ((field == null) ? "" : field.getField("name")));
      break;
    case 30: // Search
      setTableDirQuery(tableName, ((field == null) ? "" : field.getField("name")),
          ((field == null) ? "" : field.getField("name")));
      break;
    case 31: // Locator
      setTableDirQuery(tableName, "M_Locator_ID", ((field == null) ? getObjectName() : field
          .getField("name")));
      break;
    case 35:
      setTableDirQuery(tableName, ((field == null) ? "" : field.getField("name")),
          ((field == null) ? "" : field.getField("name")));
      break;
    case 25: // Account
      setTableDirQuery(tableName, "C_ValidCombination_ID", ((field == null) ? getObjectName()
          : field.getField("name")));
      break;
    case 800011: // Product Search
      setTableDirQuery(tableName, "M_Product_ID", ((field == null) ? getObjectName() : field
          .getField("name")));
      break;
    default:
      if (!checkTableTranslation(tableName, field, reference)) {
        addSelectField(formatField(
            (((tableName != null && tableName.length() != 0) ? (tableName + ".") : "") + field
                .getField("name")), reference), "NAME");
      }
      break;
    }
  }

  /**
   * Checks if the table has a translated table, making the joins to the translated one.
   * 
   * @param tableName
   *          Name of the table.
   * @param field
   *          Name of the field.
   * @param reference
   *          Id of the reference.
   * @return Boolean to indicate if the translated table has been found.
   * @throws Exception
   */
  private boolean checkTableTranslation(String tableName, FieldProvider field, String reference)
      throws Exception {
    if (tableName == null || tableName.equals("") || field == null)
      return false;
    ComboTableQueryData[] data = ComboTableQueryData.selectTranslatedColumn(getPool(), field
        .getField("tablename"), field.getField("name"));
    if (data == null || data.length == 0)
      return false;
    int myIndex = this.index++;
    addSelectField("(CASE WHEN td_trl" + myIndex + "." + data[0].columnname + " IS NULL THEN "
        + formatField((tableName + "." + field.getField("name")), reference) + " ELSE "
        + formatField(("td_trl" + myIndex + "." + data[0].columnname), reference) + " END)", "NAME");
    addFromField(data[0].tablename + " td_trl" + myIndex + " on " + tableName + "."
        + data[0].reference + " = td_trl" + myIndex + "." + data[0].reference + " AND td_trl"
        + myIndex + ".AD_Language = ?", "td_trl" + myIndex);
    addFromParameter("#AD_LANGUAGE", "LANGUAGE");
    return true;
  }

  /**
   * Formating method to add the correct functions to the fields for the presentation. It depends on
   * the type of field (DATE, NUMBER...).
   * 
   * @param field
   *          Name of the field.
   * @param reference
   *          Id of the reference type.
   * @return String with the format applied.
   */
  private String formatField(String field, String reference) {
    String result = "";
    if (field == null || field.length() == 0)
      return "";
    else if (reference == null || reference.length() == 0)
      return field;
    switch (Integer.valueOf(reference).intValue()) {
    case 11: // INTEGER
      result = "CAST(" + field + " AS INTEGER)";
      break;
    case 12: // AMOUNT
    case 22: // NUMBER
    case 26: // ROWID
    case 29: // QUANTITY
    case 800008: // PRICE
    case 800019: // GENERAL QUANTITY
      result = "TO_NUMBER(" + field + ")";
      break;
    case 15: // DATE
      result = "TO_CHAR("
          + field
          + (getVars() == null ? ""
              : (", '" + getVars().getSessionValue("#AD_SqlDateFormat") + "'")) + ")";
      break;
    case 16: // DATETIME
      result = "TO_CHAR(" + field + ")";
      break;
    case 24: // TIME
      result = "TO_CHAR(" + field + ", 'HH24:MI:SS')";
      break;
    default:
      result = "TO_CHAR(" + field + ")";
      break;
    }
    return result;
  }

  /**
   * Returns the generated query.
   * 
   * @param onlyId
   *          Boolean to indicate if the select clause must have only the key field.
   * @param discard
   *          Array of field groups to remove from the query.
   * @return String with the query.
   */
  private String getQuery(boolean onlyId, String[] discard) {
    StringBuffer text = new StringBuffer();
    Vector<QueryFieldStructure> aux = getSelectFields();
    String idName = "";
    boolean hasWhere = false;
    if (aux != null) {
      StringBuffer name = new StringBuffer();
      String description = "";
      String id = "";
      text.append("SELECT ");
      for (int i = 0; i < aux.size(); i++) {
        QueryFieldStructure auxStructure = aux.elementAt(i);
        if (!isInArray(discard, auxStructure.getType())) {
          if (auxStructure.getData("alias").equalsIgnoreCase("ID")) {
            if (id.equals("")) {
              id = auxStructure.toString(true);
              idName = auxStructure.toString();
            }
          } else if (auxStructure.getData("alias").equalsIgnoreCase("DESCRIPTION")) {
            if (description.equals(""))
              description = auxStructure.toString(true);
          } else {
            if (name.toString().equals(""))
              name.append("(");
            else
              name.append(FIELD_CONCAT);
            name.append("COALESCE(TO_CHAR(").append(auxStructure.toString()).append("),'')");
          }
        }
      }
      if (!name.toString().equals(""))
        name.append(") AS NAME");
      text.append(id).append(", ").append(name.toString());
      if (description != null && !description.equals(""))
        text.append(", ").append(description);
      else
        text.append(", '' AS DESCRIPTION");
      text.append(" \n");
    }

    aux = getFromFields();
    if (aux != null) {
      StringBuffer txtAux = new StringBuffer();
      text.append("FROM ");
      for (int i = 0; i < aux.size(); i++) {
        QueryFieldStructure auxStructure = aux.elementAt(i);
        if (!isInArray(discard, auxStructure.getType())) {
          if (!txtAux.toString().equals(""))
            txtAux.append("left join ");
          txtAux.append(auxStructure.toString()).append(" \n");
        }
      }
      text.append(txtAux.toString());
    }

    aux = getWhereFields();
    if (aux != null) {
      StringBuffer txtAux = new StringBuffer();
      for (int i = 0; i < aux.size(); i++) {
        QueryFieldStructure auxStructure = aux.elementAt(i);
        if (!isInArray(discard, auxStructure.getType())) {
          hasWhere = true;
          if (!txtAux.toString().equals(""))
            txtAux.append("AND ");
          txtAux.append(auxStructure.toString()).append(" \n");
        }
      }
      if (hasWhere)
        text.append("WHERE ").append(txtAux.toString());
    }

    if (!onlyId) {
      aux = getOrderByFields();
      if (aux != null) {
        StringBuffer txtAux = new StringBuffer();
        text.append("ORDER BY ");
        for (int i = 0; i < aux.size(); i++) {
          QueryFieldStructure auxStructure = aux.elementAt(i);
          if (!isInArray(discard, auxStructure.getType())) {
            if (!txtAux.toString().equals(""))
              txtAux.append(", ");
            txtAux.append(auxStructure.toString());
          }
        }
        text.append(txtAux.toString());
      }
    } else {
      if (!hasWhere)
        text.append("WHERE ");
      else
        text.append("AND ");
      text.append(idName).append(" = ? ");
    }
    return text.toString();
  }

  /**
   * Auxiliar method to search a value in an array.
   * 
   * @param data
   *          Array with the data.
   * @param element
   *          String to search in the array.
   * @return Boolean to indicate if the element was found in the array.
   */
  private boolean isInArray(String[] data, String element) {
    if (data == null || data.length == 0 || element == null || element.equals(""))
      return false;
    for (int i = 0; i < data.length; i++) {
      if (data[i].equalsIgnoreCase(element))
        return true;
    }
    return false;
  }

  /**
   * Fills the query parameter's values.
   * 
   * @param st
   *          PreparedStatement object.
   * @param iParameter
   *          Index of the parameter.
   * @param discard
   *          Array with the groups to discard.
   * @return Integer with the next parameter's index.
   */
  private int setSQLParameters(PreparedStatement st, int iParameter, String[] discard) {
    Vector<QueryParameterStructure> vAux = getSelectParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        if (!isInArray(discard, aux.getType())) {
          String strAux = getParameter(aux.getName());
          if (log4j.isDebugEnabled())
            log4j.debug("Parameter - " + iParameter + " - " + aux.getName() + ": " + strAux);
          UtilSql.setValue(st, ++iParameter, 12, null, strAux);
        }
      }
    }
    vAux = getFromParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        if (!isInArray(discard, aux.getType())) {
          String strAux = getParameter(aux.getName());
          if (log4j.isDebugEnabled())
            log4j.debug("Parameter - " + iParameter + " - " + aux.getName() + ": " + strAux);
          UtilSql.setValue(st, ++iParameter, 12, null, strAux);
        }
      }
    }
    vAux = getWhereParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        if (!isInArray(discard, aux.getType())) {
          String strAux = getParameter(aux.getName());
          if (log4j.isDebugEnabled())
            log4j.debug("Parameter - " + iParameter + " - " + aux.getName() + ": " + strAux);
          UtilSql.setValue(st, ++iParameter, 12, null, strAux);
        }
      }
    }
    vAux = getOrderByParameters();
    if (vAux != null) {
      for (int i = 0; i < vAux.size(); i++) {
        QueryParameterStructure aux = vAux.elementAt(i);
        if (!isInArray(discard, aux.getType())) {
          String strAux = getParameter(aux.getName());
          if (log4j.isDebugEnabled())
            log4j.debug("Parameter - " + iParameter + " - " + aux.getName() + ": " + strAux);
          UtilSql.setValue(st, ++iParameter, 12, null, strAux);
        }
      }
    }
    return iParameter;
  }

  /**
   * Executes the query in the database and returns the data.
   * 
   * @param includeActual
   *          Boolean that indicates if the actual selected value must be included in the result,
   *          even if it doesn´t exists in the new query.
   * @return Array of FieldProvider with the data.
   * @throws Exception
   */
  public FieldProvider[] select(boolean includeActual) throws Exception {
    String strSql = getQuery(false, null);
    if (! readonlyidselect.isEmpty())
      strSql= "select id,name,description from (" + strSql + ") a where a.id = '" + readonlyidselect +"'";
    if (log4j.isDebugEnabled())
      log4j.debug("SQL: " + strSql);
    PreparedStatement st = getPool().getPreparedStatement(strSql);
    ResultSet result;
    Vector<Object> vector = new Vector<Object>(0);

    try {
      int iParameter = 0;
      iParameter = setSQLParameters(st, iParameter, null);
      boolean idFound = false;
      String actual = getParameter("@ACTUAL_VALUE@");
      result = st.executeQuery();
      while (result.next()) {
        SQLReturnObject sqlReturnObject = new SQLReturnObject();
        sqlReturnObject.setData("ID", UtilSql.getValue(result, "ID"));
        sqlReturnObject.setData("NAME", UtilSql.getValue(result, "NAME"));
        sqlReturnObject.setData("DESCRIPTION", UtilSql.getValue(result, "DESCRIPTION"));
        if (includeActual && actual != null && !actual.equals("")) {
          if (actual.equals(sqlReturnObject.getData("ID"))) {
            if (!idFound) {
              vector.addElement(sqlReturnObject);
              idFound = true;
            }
          } else
            vector.addElement(sqlReturnObject);
        } else
          vector.addElement(sqlReturnObject);
      }
      result.close();

      if (includeActual && actual != null && !actual.equals("") && !idFound) {
        getPool().releasePreparedStatement(st);
        String[] discard = { "filter", "orderBy", "CLIENT_LIST", "ORG_LIST" };
        strSql = getQuery(true, discard);
        if (log4j.isDebugEnabled())
          log4j.debug("SQL Actual ID: " + strSql);
        st = getPool().getPreparedStatement(strSql);
        iParameter = setSQLParameters(st, 0, discard);
        UtilSql.setValue(st, ++iParameter, 12, null, actual);
        result = st.executeQuery();
        while (result.next()) {
          SQLReturnObject sqlReturnObject = new SQLReturnObject();
          sqlReturnObject.setData("ID", UtilSql.getValue(result, "ID"));
          String strName = UtilSql.getValue(result, "NAME");
          if (!strName.startsWith(INACTIVE_DATA))
            strName = INACTIVE_DATA + strName;
          sqlReturnObject.setData("NAME", strName);
          vector.addElement(sqlReturnObject);
          idFound = true;
        }
        result.close();
        if (!idFound) {
          SQLReturnObject sqlReturnObject = new SQLReturnObject();
          sqlReturnObject.setData("ID", actual);
          sqlReturnObject.setData("NAME", INACTIVE_DATA
              + Utility.messageBD(getPool(), "NotFound", getParameter("#AD_LANGUAGE")));
          vector.addElement(sqlReturnObject);
        }
      }
    } catch (SQLException e) {
      log4j.error("Error of SQL in query: " + strSql + "Exception:" + e);
      throw new Exception("@CODE=" + Integer.toString(e.getErrorCode()) + "@" + e.getMessage());
    } finally {
      getPool().releasePreparedStatement(st);
    }
    FieldProvider objectListData[] = new FieldProvider[vector.size()];
    vector.copyInto(objectListData);
    return (objectListData);
  }

  /**
   * Special fill parameters function to be used from the search popup (servlet).
   * 
   * It flags the combo to be used from a search popup changing the logic to get the needed
   * parameters for a possible where clause: it uses the pattern inpParam<columnName> to get the
   * values from the request and does not use the preferences for fields to preset a search filter
   */
  public void fillParametersFromSearch(String tab, String window) throws ServletException {
    fillSQLParameters(pool, vars, null, tab, window, "", true);
  }

  /**
   * Fill the parameters of the sql with the session values or FieldProvider values. Used in the
   * combo fields.
   * 
   * @param data
   *          optional FieldProvider which can be used to get the needed parameter values from. If
   *          the FieldProvider has a filed named after a parameter, then its value will be used if
   *          the value could not be already obtained from the request parameters.
   * @param window
   *          Window id.
   * @param actual_value
   *          actual value for the combo.
   * @throws ServletException
   */
  public void fillParameters(FieldProvider data, String window, String actual_value)
      throws ServletException {
    fillSQLParameters(pool, vars, data, "", window, actual_value, false);
  }

  /**
   * Fill the parameters of the sql with the session values or FieldProvider values. Used in the
   * combo fields.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param data
   *          FieldProvider with the columns values.
   * @param window
   *          Window id.
   * @param actual_value
   *          actual value for the combo.
   * @throws ServletException
   */
  void fillSQLParameters(ConnectionProvider conn, VariablesSecureApp vars, FieldProvider data,
      String tab, String window, String actual_value, boolean fromSearch) throws ServletException {
    final Vector<String> vAux = getParameters();
    if (vAux != null && vAux.size() > 0) {
      if (log4j.isDebugEnabled())
        log4j.debug("Combo Parameters: " + vAux.size());
      for (int i = 0; i < vAux.size(); i++) {
        final String strAux = vAux.elementAt(i);
        try {
          final String value = Utility.parseParameterValue(conn, vars, data, strAux, tab, window,
              actual_value, fromSearch);
          if (log4j.isDebugEnabled())
            log4j.debug("Combo Parameter: " + strAux + " - Value: " + value);
          setParameter(strAux, value);
        } catch (final Exception ex) {
          throw new ServletException(ex);
        }
      }
    }
  }

}
