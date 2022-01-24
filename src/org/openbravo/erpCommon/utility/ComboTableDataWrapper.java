/*
***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 
 Wrapper to Fill ComboTables in a more comfortable way.

Two Constructors, first reads references, second is Direct Table access with validation
 
 */
package org.openbravo.erpCommon.utility;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.database.ConnectionProvider;
public class ComboTableDataWrapper extends ComboTableData {
  /**
   * Gets a Table Reference  Combo
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param ReferenceName
   *          String with the Name of the Table Reference to search.
   *          Must be equally defined in the Data Dictionary
   * @param validation
   *          String with the ID of the Validation to search.
   * @param windowid
   *          String with  the calling window.
   *          Used to evaluate Session Vars for validations. 
  * @param currentvalue
   *          Need it to see If it is not selectable, then put ** in the List-Item
   * @param dataset
   *          complete dataset of a  Fieldgroup in a Tab or Process used to evaluate @field@ Parameters in Expressions of where Clause and validations 
   */
  public ComboTableDataWrapper(ConnectionProvider _conn, VariablesSecureApp _vars,String ReferenceName, String validation, String windowid, String currentvalue,FieldProvider dataset) throws Exception
  {
    // ReferenceName equal to Application Dictionary || Reference  ||  Reference || name
    super(_vars,_conn,ComboTableWrapperData.selectRefType(_conn, ReferenceName),"",ReferenceName,validation,Utility.getContext(_conn, _vars, "#AccessibleOrgTree",
        ""),Utility.getContext(_conn, _vars, "#User_Client",
            ""),0);
    Utility.fillSQLParameters(_conn, _vars, dataset, this,
        windowid, currentvalue);
    
  }
  /**
   * Gets a Direct Table Combo 
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param TableNameIDField
   *          String with the Name of the ID Field in the Table.
   *          Must Be <Tablename_ID>
   * @param windowid
   *          String with  the calling window.
   *          Used to evaluate Session Vars for validations. 
   * @param currentvalue
   *          Need it to see If it is not selectable, then put ** in the List-Item
   * @param dummy
   *          .. Just to get another constructor
   * @param dataset
   *          complete dataset of a  Fieldgroup in a Tab or Process used to evaluate @field@ Parameters in Expressions of where Clause and validations 
   */
  public ComboTableDataWrapper(ConnectionProvider _conn, VariablesSecureApp _vars,String TableNameIDField,String  validation, String windowid,String currentvalue, String dummy,FieldProvider dataset) throws Exception
  {
    // TableNameIDField - Example M_Warehouse_ID
    super(_vars,_conn,"TABLEDIR",TableNameIDField,"",validation,Utility.getContext(_conn, _vars, "#AccessibleOrgTree",
        ""),Utility.getContext(_conn, _vars, "#User_Client",""),0);
    Utility.fillSQLParameters(_conn, _vars, dataset, this,
        windowid, currentvalue);
  }
  /**
   * Gets a List Reference Combo 
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param ReferenceName
   *          String with the Name of the Reference to search.
   *          Must be equally defined in the Data Dictionary
   * @param currentvalue
   *          Need it to see If it is deactivated, then put ** in the List-Item
   */
  public ComboTableDataWrapper(ConnectionProvider _conn, VariablesSecureApp _vars,String ReferenceName, String currentvalue) throws Exception
  {
    // Load ID of Reference while Constructing from super
    super(_vars,_conn,"17",ReferenceName,ComboTableWrapperData.selectReferenceID(_conn, ReferenceName),"",Utility.getContext(_conn, _vars, "#AccessibleOrgTree",
        ""),Utility.getContext(_conn, _vars, "#User_Client",
            ""),0);
    Utility.fillSQLParameters(_conn, _vars, null, this,
        "", currentvalue);
  }
}
