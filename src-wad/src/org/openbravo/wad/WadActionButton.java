/*
 <!--
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2010 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
-->
 */
package org.openbravo.wad;

import java.io.File;
import java.io.IOException;
import java.util.Enumeration;
import java.util.Properties;
import java.util.Vector;

import javax.servlet.ServletException;

import org.openbravo.data.Sqlc;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.wad.controls.WADControl;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.xmlEngine.XmlEngine;

/**
 * Utility class used by Wad.java and WadActionButton.java
 * 
 * @author Fernando Iriazabal
 * 
 */
public class WadActionButton {
  static final int IMAGE_EDITION_WIDTH = 16;
  static final int IMAGE_EDITION_HEIGHT = 16;

  /**
   * Checks if the given reference is a numeric type
   * 
   * @param reference
   *          The reference to check.
   * @return Boolean that indicates if the reference is a numeric type or not.
   */
  public static boolean isNumericType(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    if (WadUtility.isGeneralNumber(reference) || WadUtility.isDecimalNumber(reference)
        || WadUtility.isPriceNumber(reference) || WadUtility.isIntegerNumber(reference)
        || WadUtility.isQtyNumber(reference)) {
      return true;
    }
    return false;
  }

  /**
   * Checks if the given reference is a date type
   * 
   * @param reference
   *          The reference to check.
   * @return Boolean that indicates if the reference is a date type or not.
   */
  public static boolean isDateType(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    if (WadUtility.isDateTimeField(reference)) {
      return true;
    }
    return false;
  }

  /**
   * Generates the action button call for the java of the window.
   * 
   * @param conn
   *          Object with the database connection implementation.
   * @param strTab
   *          Id of the tab
   * @param tabName
   *          The tab name.
   * @param keyName
   *          The name of the key.
   * @param isSOTrx
   *          If is a sales tab.
   * @param window
   *          The id of the window.
   * @return Array of ActionButtonRelationData with the info to build the source.
   */
  public static ActionButtonRelationData[] buildActionButtonCall(ConnectionProvider conn,
      String strTab, String tabName, String keyName, String isSOTrx, String window) {
    ActionButtonRelationData[] fab = null;
    try {
      fab = ActionButtonRelationData.select(conn, strTab);
    } catch (final ServletException e) {
      return null;
    }
    if (fab != null) {
      for (int i = 0; i < fab.length; i++) {
        final Vector<Object> vecFields = new Vector<Object>();
        final Vector<Object> vecParams = new Vector<Object>();
        final Vector<Object> vecTotalFields = new Vector<Object>();
        if (fab[i].realname.equalsIgnoreCase("DocAction")
            || fab[i].realname.equalsIgnoreCase("PaymentRule")
            || (fab[i].realname.equalsIgnoreCase("Posted") && fab[i].adProcessId.equals(""))
            || (fab[i].realname.equalsIgnoreCase("CreateFrom") && fab[i].adProcessId.equals(""))
            || fab[i].realname.equalsIgnoreCase("ChangeProjectStatus"))
          fab[i].xmlid = "";
        fab[i].realname = FormatUtilities.replace(fab[i].realname);
        fab[i].columnname = Sqlc.TransformaNombreColumna(fab[i].columnname);
        fab[i].setsession = getFieldsSession(fab[i]);
        fab[i].htmltext = getFieldsLoad(fab[i], vecFields, vecTotalFields);
        fab[i].javacode = getPrintPageJavaCode(conn, fab[i], vecFields, vecParams, isSOTrx, window,
            tabName, false, fab[i].adProcessId,keyName);
        fab[i].comboparacode = getComboParaCode(conn, fab[i].adProcessId, strTab);
        final StringBuffer fields = new StringBuffer();
        final StringBuffer fieldsHeader = new StringBuffer();
        for (int j = 0; j < vecFields.size(); j++) {
          fields.append(", " + vecFields.elementAt(j));
          fieldsHeader.append(", String " + vecFields.elementAt(j));
        }
        fab[i].htmlfields = fields.toString();
        fab[i].htmlfieldsHeader = fieldsHeader.toString();
        ProcessRelationData[] data = null;
        if (!fab[i].adProcessId.equals("") && !fab[i].adProcessId.equals("177")) {
          try {
            data = ProcessRelationData.selectParameters(conn, "", fab[i].adProcessId);
          } catch (final ServletException e) {
          }
          if (fab[i].realname.equalsIgnoreCase("ChangeProjectStatus")) {
            fab[i].processParams = "PInstanceProcessData.insertPInstanceParam(this, pinstance, \"0\", \"ChangeProjectStatus\", strchangeprojectstatus, vars.getClient(), vars.getOrg(), vars.getUser());\n";
            vecParams.addElement("changeprojectstatus");
          } else
            fab[i].processParams = "";
          fab[i].processParams += getProcessParamsJava(data, fab[i], vecParams, false);
          fab[i].processCode = "ActionButtonData.process" + fab[i].adProcessId
              + "(this, pinstance);\n";
        }
        fab[i].additionalCode = getAdditionalCode(fab[i], tabName, keyName);
      }
    }
    return fab;
  }

  /**
   * Generates the action button call for java processes of the window.
   * 
   * @param conn
   *          Object with the database connection implementation.
   * @param strTab
   *          Id of the tab
   * @param tabName
   *          The tab name.
   * @param keyName
   *          The name of the key.
   * @param isSOTrx
   *          If is a sales tab.
   * @param window
   *          The id of the window.
   * @return Array of ActionButtonRelationData with the info to build the source.
   */
  public static ActionButtonRelationData[] buildActionButtonCallJava(ConnectionProvider conn,
      String strTab, String tabName, String keyName, String isSOTrx, String window) {
    ActionButtonRelationData[] fab = null;
    try {
      fab = ActionButtonRelationData.selectJava(conn, strTab);
    } catch (final ServletException e) {
      return null;
    }
    if (fab != null) {
      for (int i = 0; i < fab.length; i++) {
        final Vector<Object> vecFields = new Vector<Object>();
        final Vector<Object> vecParams = new Vector<Object>();
        final Vector<Object> vecTotalFields = new Vector<Object>();
        if (fab[i].realname.equalsIgnoreCase("DocAction")
            || fab[i].realname.equalsIgnoreCase("PaymentRule")
            || (fab[i].realname.equalsIgnoreCase("Posted") && fab[i].adProcessId.equals(""))
            || (fab[i].realname.equalsIgnoreCase("CreateFrom") && fab[i].adProcessId.equals(""))
            || fab[i].realname.equalsIgnoreCase("ChangeProjectStatus"))
          fab[i].xmlid = "";
        fab[i].realname = FormatUtilities.replace(fab[i].realname);
        fab[i].columnname = Sqlc.TransformaNombreColumna(fab[i].columnname);
        fab[i].htmltext = getFieldsLoad(fab[i], vecFields, vecTotalFields);
        fab[i].setsession = getFieldsSession(fab[i]);
        fab[i].javacode = getPrintPageJavaCode(conn, fab[i], vecFields, vecParams, isSOTrx, window,
            tabName, false, fab[i].adProcessId,keyName);
        fab[i].comboparacode = getComboParaCode(conn, fab[i].adProcessId, strTab);
        final StringBuffer fields = new StringBuffer();
        final StringBuffer fieldsHeader = new StringBuffer();
        for (int j = 0; j < vecFields.size(); j++) {
          fields.append(", " + vecFields.elementAt(j));
          fieldsHeader.append(", String " + vecFields.elementAt(j));
        }
        fab[i].htmlfields = fields.toString();
        fab[i].htmlfieldsHeader = fieldsHeader.toString();
        ProcessRelationData[] data = null;
        if (!fab[i].adProcessId.equals("") && !fab[i].adProcessId.equals("177")) {
          try {
            data = ProcessRelationData.selectParameters(conn, "", fab[i].adProcessId);
          } catch (final ServletException e) {
          }

          fab[i].processParams = "";
          fab[i].processParams += getProcessParamsJava(data, fab[i], vecParams, true);
          fab[i].processCode = "new " + fab[i].classname + "().execute(pb);";
        }
      }
    }
    return fab;
  }

  private static String getComboParaCode(ConnectionProvider conn, String processId, String tabId) {
    String result = "";
    ActionButtonRelationData[] params = null;
    try {
      params = ActionButtonRelationData.selectComboParams(conn, tabId, processId);
    } catch (final ServletException e) {
      return "";
    }
    for (ActionButtonRelationData para : params) {
      result += "p.put(\"" + para.columnname + "\", vars.getStringParameter(\"inp"
          + Sqlc.TransformaNombreColumna(para.columnname) + "\"));\n";
    }
    return result;
  }

  /**
   * Generates the action button call for the java of the menu processes.
   * 
   * @param conn
   *          Object with the database connection implementation.
   * @return Array of ActionButtonRelationData with the info to build the source.
   */
  public static ActionButtonRelationData[] buildActionButtonCallGenerics(ConnectionProvider conn) {
    ActionButtonRelationData[] fab = null;
    try {
      fab = ActionButtonRelationData.selectGenerics(conn);
    } catch (final ServletException e) {
      return null;
    }
    if (fab != null) {
      for (int i = 0; i < fab.length; i++) {
        final Vector<Object> vecFields = new Vector<Object>();
        final Vector<Object> vecParams = new Vector<Object>();
        final Vector<Object> vecTotalFields = new Vector<Object>();
        if (fab[i].realname.equalsIgnoreCase("DocAction")
            || fab[i].realname.equalsIgnoreCase("PaymentRule")
            || (fab[i].realname.equalsIgnoreCase("Posted") && fab[i].adProcessId.equals(""))
            || (fab[i].realname.equalsIgnoreCase("CreateFrom") && fab[i].adProcessId.equals(""))
            || fab[i].realname.equalsIgnoreCase("ChangeProjectStatus"))
          fab[i].xmlid = "";
        fab[i].realname = FormatUtilities.replace(fab[i].realname);
        fab[i].columnname = Sqlc.TransformaNombreColumna(fab[i].columnname);
        fab[i].htmltext = getFieldsLoad(fab[i], vecFields, vecTotalFields);
        fab[i].javacode = getPrintPageJavaCode(conn, fab[i], vecFields, vecParams, "", "", "",
            true, "", "");
        final StringBuffer fields = new StringBuffer();
        final StringBuffer fieldsHeader = new StringBuffer();
        for (int j = 0; j < vecFields.size(); j++) {
          fields.append(", " + vecFields.elementAt(j));
          fieldsHeader.append(", String " + vecFields.elementAt(j));
        }
        fab[i].htmlfields = fields.toString();
        fab[i].htmlfieldsHeader = fieldsHeader.toString();
        ProcessRelationData[] data = null;
        if (!fab[i].adProcessId.equals("") && !fab[i].adProcessId.equals("177")) {
          try {
            data = ProcessRelationData.selectParameters(conn, "", fab[i].adProcessId);
          } catch (final ServletException e) {
          }
          if (fab[i].realname.equalsIgnoreCase("ChangeProjectStatus")) {
            fab[i].processParams = "PInstanceProcessData.insertPInstanceParam(this, pinstance, \"0\", \"ChangeProjectStatus\", strchangeprojectstatus, vars.getClient(), vars.getOrg(), vars.getUser());\n";
            vecParams.addElement("changeprojectstatus");
          } else
            fab[i].processParams = "";
          fab[i].processParams += getProcessParamsJava(data, fab[i], vecParams, false);
          fab[i].processCode = "ActionButtonData.process" + fab[i].adProcessId
              + "(this, pinstance);\n";
        }
        fab[i].additionalCode = getAdditionalCode(fab[i], "", "");
      }
    }
    return fab;
  }

  public static ActionButtonRelationData[] buildActionButtonCallGenericsJava(ConnectionProvider conn) {
    ActionButtonRelationData[] fab = null;
    try {
      fab = ActionButtonRelationData.selectGenericsJava(conn);
    } catch (final ServletException e) {
      return null;
    }
    if (fab != null) {
      for (int i = 0; i < fab.length; i++) {
        final Vector<Object> vecFields = new Vector<Object>();
        final Vector<Object> vecParams = new Vector<Object>();
        final Vector<Object> vecTotalFields = new Vector<Object>();

        fab[i].realname = FormatUtilities.replace(fab[i].realname);
        fab[i].columnname = Sqlc.TransformaNombreColumna(fab[i].columnname);
        fab[i].htmltext = getFieldsLoad(fab[i], vecFields, vecTotalFields);
        fab[i].javacode = getPrintPageJavaCode(conn, fab[i], vecFields, vecParams, "", "", "",
            true, "", "");
        final StringBuffer fields = new StringBuffer();
        final StringBuffer fieldsHeader = new StringBuffer();
        for (int j = 0; j < vecFields.size(); j++) {
          fields.append(", " + vecFields.elementAt(j));
          fieldsHeader.append(", String " + vecFields.elementAt(j));
        }
        fab[i].htmlfields = fields.toString();
        fab[i].htmlfieldsHeader = fieldsHeader.toString();
        ProcessRelationData[] data = null;
        // SZ added Generic Response
        if (!fab[i].adProcessId.equals("") && !fab[i].adProcessId.equals("177")) {
          try {
            data = ProcessRelationData.selectParameters(conn, "", fab[i].adProcessId);
            if (ActionButtonRelationData.isManualResponse(conn,fab[i].adProcessId).equals("Y")){
                  fab[i].processCode = "new " + fab[i].classname + "().execute(pb,this,response);";
                  fab[i].processbuttonhelper = "";
            }
             else {
                  fab[i].processCode = "new " + fab[i].classname + "().execute(pb);";
                  fab[i].processbuttonhelper = "processButtonHelper(request, response, vars, myMessage);";
             }
          } catch (final ServletException e) {
          }
          fab[i].processParams = getProcessParamsJava(data, fab[i], vecParams, true);
        }
        
      }
    }
    return fab;
  }

  /**
   * Adds some fields to the vector of tab's fields, depending on the column that it is processing.
   * 
   * @param columnname
   *          The name of the column.
   * @param vecFields
   *          Vector with the fields.
   */
  public static void getFieldsLoad(String columnname, Vector<Object> vecFields) {
    if (columnname.equalsIgnoreCase("DocAction")) {
      vecFields.addElement("DocStatus");
      vecFields.addElement("AD_Table_ID");
    } else if (columnname.equalsIgnoreCase("CreateFrom")) {
      vecFields.addElement("AD_Table_ID");
    } else if (columnname.equalsIgnoreCase("Posted")) {
      vecFields.addElement("AD_Table_ID");
      vecFields.addElement("Posted");
    } else if (columnname.equalsIgnoreCase("ChangeProjectStatus")) {
      vecFields.addElement("ProjectStatus");
    }
  }

  /**
   * Adds some fields to the vector of tab's fields, depending on the column that it is processing.
   * 
   * @param fd
   *          Object with the column info.
   * @param vecFields
   *          Vector of fields in vars format.
   * @param vecTotalFields
   *          Vector of fields.
   * @return String with the java call.
   */
  public static String getFieldsLoad(ActionButtonRelationData fd, Vector<Object> vecFields,
      Vector<Object> vecTotalFields) {
    if (fd == null)
      return "";
    String processId = fd.adProcessId;
    final StringBuffer html = new StringBuffer();
    if (fd.columnname.equalsIgnoreCase("DocAction")) {
      html.append("String strdocstatus = vars.getSessionValue(\"button").append(processId).append(
          ".inpdocstatus\");\n");
      vecFields.addElement("strdocstatus");
      vecTotalFields.addElement("DocStatus");
      html.append("String stradTableId = \"" + fd.adTableId + "\";\n");
      vecFields.addElement("stradTableId");
      vecTotalFields.addElement("AD_Table_ID");
    } else if (fd.columnname.equalsIgnoreCase("CreateFrom") && fd.adProcessId.equals("")) {
      html.append("String stradTableId = \"" + fd.adTableId + "\";\n");
      vecFields.addElement("stradTableId");
      vecTotalFields.addElement("AD_Table_ID");
    } else if (fd.columnname.equalsIgnoreCase("Posted") && fd.adProcessId.equals("")) {
      html.append("String stradTableId = \"" + fd.adTableId + "\";\n");
      vecFields.addElement("stradTableId");
      vecTotalFields.addElement("AD_Table_ID");
    } else if (fd.columnname.equalsIgnoreCase("ChangeProjectStatus")) {
      html.append("String strprojectstatus = vars.getSessionValue(\"button").append(processId)
          .append(".inpprojectstatus\");\n");
      vecFields.addElement("strprojectstatus");
      vecTotalFields.addElement("ProjectStatus");
    }
    return html.toString();
  }

  private static String getFieldsSession(ActionButtonRelationData fd) {
    if (fd == null)
      return "";
    String processId = fd.adProcessId;
    final StringBuffer result = new StringBuffer();
    if (fd.columnname.equalsIgnoreCase("DocAction")) {
      result.append("vars.setSessionValue(\"button").append(processId).append(
          ".inpdocstatus\", vars.getRequiredStringParameter(\"inpdocstatus\"));\n");
    } else if (fd.columnname.equalsIgnoreCase("ChangeProjectStatus")) {
      result.append("vars.setSessionValue(\"button").append(processId).append(
          ".inpprojectstatus\", vars.getRequiredStringParameter(\"inpprojectstatus\"));\n");
    }
    return result.toString();
  }

  /**
   * Auxiliar method that generates the printPage java code of the action button.
   * 
   * @param conn
   *          Object with the database connection.
   * @param fd
   *          Object with the button column info
   * @param vecFields
   *          Vector with the fields.
   * @param vecParams
   *          Vector with the parameters.
   * @param isSOTrx
   *          If is sales tab.
   * @param window
   *          Id of the window.
   * @param tabName
   *          Name of the tab.
   * @param genericActionButton
   *          Indicates whether it is generic or column action button
   * @param processId
   *          Id for the current process
   * @return String with the java code.
   */
  public static String getPrintPageJavaCode(ConnectionProvider conn, ActionButtonRelationData fd,
      Vector<Object> vecFields, Vector<Object> vecParams, String isSOTrx, String window,
      String tabName, boolean genericActionButton, String processId, String key) {
    if (fd == null)
      return "";

    final StringBuffer html = new StringBuffer();
    for (int i = 0; i < vecFields.size(); i++) {
      String field = vecFields.elementAt(i).toString();
      field = field.substring(3);
      html.append("xmlDocument.setParameter(\"" + field + "\", str" + field + ");\n");
    }

    if (!fd.adProcessId.equals("")) {
      try {
        final ProcessRelationData[] data = ProcessRelationData.selectParameters(conn, "",
            fd.adProcessId);
        boolean hasComboParameter = false;
        html.append("    try {\n");
        for (int i = 0; i < data.length; i++) {
          if (data[i].adReferenceId.equals("17") || data[i].adReferenceId.equals("18")
              || data[i].adReferenceId.equals("19"))
            hasComboParameter = true;
        }
        if (hasComboParameter) {
          html.append("    ComboTableData comboTableData = null;\n");
        }
        for (int i = 0; i < data.length; i++) {
          String strDefault = "";
          html.append("    xmlDocument.setParameter(\"");
          // html.append(Sqlc.TransformaNombreColumna(data[i].columnname));
          html.append(data[i].columnname);
          html.append("\", ");
          if (data[i].defaultvalue.equals("") || data[i].defaultvalue.indexOf("@") == -1) {
            strDefault = "\"" + data[i].defaultvalue + "\"";
          } else if (data[i].defaultvalue.startsWith("@SQL=")) {
            strDefault = (tabName.equals("") ? "ActionButtonSQLDefault" : tabName)
                + "Data.selectActP" + data[i].id + "_"
                + FormatUtilities.replace(data[i].columnname);
            strDefault += "(this"
                + WadUtility.getWadContext(data[i].defaultvalue, vecFields, vecParams, null, false,
                    isSOTrx, window);
            strDefault += ")";
          } else {
            strDefault = WadUtility.getTextWadContext(data[i].defaultvalue, vecFields, vecParams,
                null, false, isSOTrx, window);
          }
          html.append(strDefault).append(");\n");
          if (data[i].adReferenceId.equals("17") || data[i].adReferenceId.equals("18")
              || data[i].adReferenceId.equals("19")) {
            html.append("    comboTableData = new ComboTableData(vars, this, \"");
            html.append(data[i].adReferenceId).append("\", \"");
            html.append(data[i].columnname).append("\", \"");
            html.append(data[i].adReferenceValueId).append("\", \"");
            html.append(data[i].adValRuleId).append("\", ");

            html.append("Utility.getContext(this, vars, \"#AccessibleOrgTree\", \"\"), ");

            html.append("Utility.getContext(this, vars, \"#User_Client\", \"\"), 0");
            html.append(");\n");
            html.append("    Utility.fillSQLParameters(this, vars, ").append(
                genericActionButton ? "null" : "(FieldProvider) vars.getSessionObject(\"button"
                    + processId + ".originalParams\")").append(", comboTableData, \"\", ").append(
                strDefault).append(");\n");
            html.append("    xmlDocument.setData(\"report");
            // html.append(Sqlc.TransformaNombreColumna(data[i].columnname));
            html.append(data[i].columnname);
            html.append("\", \"liststructure\", comboTableData.select(false));\n");
            html.append("comboTableData = null;\n");
          } else if (data[i].adReferenceId.equals("15")) {
            html.append("    xmlDocument.setParameter(\"").append(data[i].columnname).append(
                "_Format\", vars.getSessionValue(\"#AD_SqlDateFormat\"));\n");
          } else if (data[i].adReferenceId.equals("30") || data[i].adReferenceId.equals("35")
              || data[i].adReferenceId.equals("25") || data[i].adReferenceId.equals("31")
              || data[i].adReferenceId.equals("800011")) {
            html.append("    xmlDocument.setParameter(\"");
            // html.append(Sqlc.TransformaNombreColumna(data[i].columnname));
            html.append(data[i].columnname);
            html.append("R\", ");
            if (!tabName.equals("")) {
              html.append(tabName);
              html.append("Data.selectActDef");
              html.append(FormatUtilities.replace(data[i].columnname));
              html.append("(this, ");
              html
                  .append(((data[i].defaultvalue.equals("") || data[i].defaultvalue.indexOf("@") == -1) ? "\""
                      + data[i].defaultvalue + "\""
                      : WadUtility.getWadContext(data[i].defaultvalue, vecFields, vecParams, null,
                          false, isSOTrx, window)));
              html.append(")");
            } else {
              html.append("\"\"");
            }
            html.append(");\n");
          }
          vecParams.addElement(data[i].columnname);
        }
        html.append("    } catch (Exception ex) {\n");
        html.append("      throw new ServletException(ex);\n");
        html.append("    }\n");
      } catch (final ServletException e) {
      }
    }
    if (fd.columnname.equalsIgnoreCase("DocAction")) {
      html.append("xmlDocument.setParameter(\"processId\", \"" + fd.adProcessId + "\");\n");
      String strAux = "";
      try {
        strAux = ActionButtonRelationData.processDescription(conn, fd.adProcessId);
      } catch (final ServletException e) {
      }
      html.append("xmlDocument.setParameter(\"processDescription\", \"" + strAux + "\");\n");
      html
          .append("xmlDocument.setParameter(\"docaction\", (strdocaction.equals(\"--\")?\"CL\":strdocaction));\n");
      html
          .append("FieldProvider[] dataDocAction = ActionButtonUtility.docAction(this, vars, strdocaction, \""
              + fd.adReferenceValueId + "\", strdocstatus, strProcessing, stradTableId, str" + key + ");\n");
      html.append("xmlDocument.setData(\"reportdocaction\", \"liststructure\", dataDocAction);\n");
      html.append("StringBuffer dact = new StringBuffer();\n");
      html.append("if (dataDocAction!=null) {\n");
      html.append("  dact.append(\"var arrDocAction = new Array(\\n\");\n");
      html.append("  for (int i=0;i<dataDocAction.length;i++) {\n");
      html
          .append("    dact.append(\"new Array(\\\"\" + dataDocAction[i].getField(\"id\") + \"\\\", \\\"\" + dataDocAction[i].getField(\"name\") + \"\\\", \\\"\" + dataDocAction[i].getField(\"description\") + \"\\\")\\n\");\n");
      html.append("    if (i<dataDocAction.length-1) dact.append(\",\\n\");\n");
      html.append("  }\n");
      html.append("  dact.append(\");\");\n");
      html.append("} else dact.append(\"var arrDocAction = null\");\n");
      html.append("xmlDocument.setParameter(\"array\", dact.toString());\n");
    } else if (fd.columnname.equalsIgnoreCase("ChangeProjectStatus")) {
      String strAux = "";
      html.append("xmlDocument.setParameter(\"processId\", \"" + fd.adProcessId + "\");\n");
      try {
        strAux = ActionButtonRelationData.processDescription(conn, fd.adProcessId);
      } catch (final ServletException e) {
      }
      html.append("xmlDocument.setParameter(\"processDescription\", \"" + strAux + "\");\n");
      html.append("xmlDocument.setParameter(\"projectaction\", strchangeprojectstatus);\n");
      html
          .append("FieldProvider[] dataProjectAction = ActionButtonUtility.projectAction(this, vars, strchangeprojectstatus, \""
              + fd.adReferenceValueId + "\", strprojectstatus);\n");
      html
          .append("xmlDocument.setData(\"reportprojectaction\", \"liststructure\", dataProjectAction);\n");
      html.append("StringBuffer dact = new StringBuffer();\n");
      html.append("if (dataProjectAction!=null) {\n");
      html.append("  dact.append(\"var arrProjectAction = new Array(\\n\");\n");
      html.append("  for (int i=0;i<dataProjectAction.length;i++) {\n");
      html
          .append("    dact.append(\"new Array(\\\"\" + dataProjectAction[i].getField(\"id\") + \"\\\", \\\"\" + dataProjectAction[i].getField(\"name\") + \"\\\", \\\"\" + dataProjectAction[i].getField(\"description\") + \"\\\")\\n\");\n");
      html.append("    if (i<dataProjectAction.length-1) dact.append(\",\\n\");\n");
      html.append("  }\n");
      html.append("  dact.append(\");\");\n");
      html.append("} else dact.append(\"var arrProjectAction = null\");\n");
      html.append("xmlDocument.setParameter(\"array\", dact.toString());\n");
    } else if (fd.columnname.equalsIgnoreCase("PaymentRule")) {
    }
    return html.toString();
  }

  /**
   * Returns the process call needed to fill the ad_pinstance's tables to execute the procedure.
   * 
   * @param data
   *          Array with the parameters of the process.
   * @param fd
   *          Object with the column information.
   * @param vecParams
   *          Vector of parameters.
   * @return String with all the calls.
   */
  public static String getProcessParamsJava(ProcessRelationData[] data,
      ActionButtonRelationData fd, Vector<Object> vecParams, boolean isGenericJava) {
    if (fd == null)
      return "";
    final StringBuffer html = new StringBuffer();

    if (data != null) {
      for (int i = 0; i < data.length; i++) {
        if (data[i].template.equals("FILE")) {
          html.append("FileItem str" + Sqlc.TransformaNombreColumna(data[i].columnname));
          html.append(" = vars.getMultiFile");
        } else {
            html.append("String str" + Sqlc.TransformaNombreColumna(data[i].columnname));
            if (WadActionButton.isNumericType(data[i].reference)) {
            html.append(" = vars.getNumericParameter");
            } else {
             if (WadActionButton.isDateType(data[i].reference)) 
               html.append(" = vars.getDateParameter");
            else
              html.append(" = vars.getStringParameter");
            }
        }

        html.append("(\"inp" + Sqlc.TransformaNombreColumna(data[i].columnname) + "\"");
        if (data[i].adReferenceId.equals("20"))
          html.append(", \"N\"");
         if (WadActionButton.isDateType(data[i].reference)) 
            html.append(", this");
        html.append(");\n");
        if (isGenericJava) {
          html.append("params.put(\"").append(Sqlc.TransformaNombreColumna(data[i].columnname))
              .append("\", str").append(Sqlc.TransformaNombreColumna(data[i].columnname)).append(
                  ");\n");
        } else {
          html.append("PInstanceProcessData.insertPInstanceParam"
              + (isNumericType(data[i].adReferenceId) ? "Number"
                  : (isDateType(data[i].adReferenceId) ? "Date" : "")) + "(this, pinstance, \""
              + data[i].seqno + "\", \"" + data[i].columnname + "\", str"
              + Sqlc.TransformaNombreColumna(data[i].columnname)
              + ", vars.getClient(), vars.getOrg(), vars.getUser());\n");
        }
        vecParams.addElement(Sqlc.TransformaNombreColumna(data[i].columnname));
      }
    }
    return html.toString();
  }

  /**
   * Generates the aditional code needed for some specifics processes.
   * 
   * @param fd
   *          Object with the column info.
   * @param tabName
   *          Name of the tab.
   * @param keyName
   *          Name of the key.
   * @return String with the specific code.
   */
  public static String getAdditionalCode(ActionButtonRelationData fd, String tabName, String keyName) {
    if (fd == null)
      return "";
    final StringBuffer html = new StringBuffer();
    if (fd.columnname.equalsIgnoreCase("DocAction")) {
      html.append(tabName + "Data.updateDocAction(this, strdocaction, str" + keyName + ");\n");
      /*
       * } else if (fd.columnname.equalsIgnoreCase("ChangeProjectStatus")) { html.append(tabName +
       * "Data.updateChangeProjectStatus(this, strchangeprojectstatus, str" + keyName + ");\n");
       */
    } else if (fd.columnname.equalsIgnoreCase("PaymentRule")) {
    }
    return html.toString();
  }

  /**
   * Generates the info to create the sql for the action button
   * 
   * @param conn
   *          Object with the database connection.
   * @param strTab
   *          Id of the tab.
   * @return Array of ActionButtonRelationData objects with the info.
   */
  public static ActionButtonRelationData[] buildActionButtonSQL(ConnectionProvider conn,
      String strTab) {
    ActionButtonRelationData[] fab = null;
    try {
      fab = ActionButtonRelationData.selectDocAction(conn, strTab);
    } catch (final ServletException e) {
      return null;
    }
    if (fab == null)
      return null;
    for (int i = 0; i < fab.length; i++) {
      fab[i].realname = FormatUtilities.replace(fab[i].realname);
      fab[i].columnname = Sqlc.TransformaNombreColumna(fab[i].columnname);
    }
    return fab;
  }

  /**
   * Generates the xml file for the action button
   * 
   * @param conn
   *          Object with the database connection.
   * @param xmlEngine
   *          The XmlEngine object to manage the templates.
   * @param fileDir
   *          Path where is gonna be created the xml file.
   * @param fd
   *          Object with the column info.
   * @param vecFields
   *          Vector with the fields.
   * @param max_textbox_length
   *          Max length for the textbox controls.
   * @throws ServletException
   * @throws IOException
   */
  public static void buildXml(ConnectionProvider conn, XmlEngine xmlEngine, File fileDir,
      FieldsData fd, Vector<Object> vecFields, int max_textbox_length) throws ServletException,
      IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/wad/Configuration_ActionButton").createXmlDocument();
    xmlDocument.setParameter("class", (fd.columnname + fd.reference) + ".html");
    final ProcessRelationData[] data = ProcessRelationData.selectParameters(conn, "", fd.reference);

    {
      final StringBuffer html = new StringBuffer();
      if (vecFields != null) {
        for (int i = 0; i < vecFields.size(); i++) {
          html.append("<PARAMETER id=\"" + vecFields.elementAt(i) + "\" name=\""
              + vecFields.elementAt(i) + "\" attribute=\"value\"/>\n");
        }
      }
      xmlDocument.setParameter("additionalFields", html.toString());
    }

    final StringBuffer html = new StringBuffer();
    final StringBuffer labelsHTML = new StringBuffer();
    if (data != null) {
      for (int i = 0; i < data.length; i++) {
        WADControl auxControl = null;
        try {
          auxControl = WadUtility.getControl(conn, data[i], false, (fd.columnname + fd.reference),
              "", xmlEngine, false, false, false, false);
          auxControl.setData("IsParameter", "Y");
        } catch (final Exception ex) {
          throw new ServletException(ex);
        }
        html.append(auxControl.toXml()).append("\n");

        final String labelXML = auxControl.toLabelXML();
        if (!labelXML.trim().equals(""))
          labelsHTML.append(auxControl.toLabelXML()).append("\n");
      }
    }

    xmlDocument.setParameter("column", html.toString());
    xmlDocument.setParameter("labels", labelsHTML.toString());
    WadUtility.writeFile(fileDir, (fd.columnname + fd.reference) + ".xml",
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + xmlDocument.print());
  }

  /**
   * Generates the html file for the action button.
   * 
   * @param conn
   *          Object with the database connection.
   * @param xmlEngine
   *          XmlEngine object to manage the templates.
   * @param fileDir
   *          Path where is gonna be created the file.
   * @param fd
   *          Object with the column info.
   * @param vecFields
   *          Vector with the fields.
   * @param max_textbox_length
   *          Max length for the textbox controls.
   * @param max_size_edition_1_columns
   *          Max size for the one column in the edition mode.
   * @param strLanguage
   *          Language to translate.
   * @param isGeneric
   *          Indicates if is a generic action button or not.
   * @param calendarDescription
   *          String with the description for the calendar controls.
   * @param clockDescription
   *          String with the description for the clock controls.
   * @param calculatorDescription
   *          String with the description for the calc controls.
   * @param jsDateFormat
   *          Date format for js.
   * @param vecReloads
   * @throws ServletException
   * @throws IOException
   */
  public static void buildHtml(ConnectionProvider conn, XmlEngine xmlEngine, File fileDir,
      FieldsData fd, Vector<Object> vecFields, int max_textbox_length,
      int max_size_edition_1_columns, String strLanguage, boolean isGeneric,
      String calendarDescription, String clockDescription, String calculatorDescription,
      String jsDateFormat, Vector<Object> vecReloads) throws ServletException, IOException {
    final String[] discard = { "", "isGeneric", "fieldDiscardProcess" };
    if (fd.xmltext.equals(""))
      discard[0] = "helpDiscard";
    if (isGeneric)
      discard[1] = "isNotGeneric";
    if (fd.isjasper.equals("Y"))
      discard[2] = "fieldDiscardJasper";
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/wad/Template_ActionButton", discard).createXmlDocument();
    final ProcessRelationData[] efd = ProcessRelationData.selectParameters(conn, strLanguage,
        fd.reference);
    xmlDocument.setParameter("tab", fd.realname);
    xmlDocument.setParameter("columnname", fd.columnname + fd.reference);
    xmlDocument.setParameter("processDescription", fd.tablename);
    xmlDocument.setParameter("processHelp", fd.xmltext);
    xmlDocument.setParameter("adProcessId", fd.reference);

    {
      final StringBuffer html = new StringBuffer();
      xmlDocument.setParameter("additionalFields", html.toString());
    }

    if (efd != null) {

      vecFields.addElement(fd.columnname);
      for (int i = 0; i < efd.length; i++)
        vecFields.addElement(efd[i].columnname);

      final Properties importsCSS = new Properties();
      final Properties importsJS = new Properties();
      final Properties javaScriptFunctions = new Properties();
      final StringBuffer validations = new StringBuffer();
      final StringBuffer onload = new StringBuffer();
      final StringBuffer html = new StringBuffer();
      for (int i = 0; i < efd.length; i++) {
        WADControl auxControl = null;
        try {
          auxControl = WadUtility.getControl(conn, efd[i], false, (fd.columnname + fd.reference),
              strLanguage, xmlEngine, false, WadUtility.isInVector(vecReloads, efd[i]
                  .getField("columnname")), false, false);
        } catch (final Exception ex) {
          throw new ServletException(ex);
        }

        html.append("<tr><td class=\"TitleCell\">").append(auxControl.toLabel().replace("\n", ""))
            .append("</td>\n");
        html.append("<td class=\"").append(auxControl.getType()).append("_ContentCell\"");
        if (Integer.valueOf(auxControl.getData("DisplayLength")).intValue() > (max_size_edition_1_columns / 2)) {
          html.append(" colspan=\"2\"");
          auxControl.setData("CssSize", "TwoCells");
        } else {
          auxControl.setData("CssSize", "OneCell");
        }
        html.append(">");
        html.append(auxControl.toString());
        html.append("</td>\n");
        if (auxControl.getData("CssSize").equals("OneCell"))
          html.append("<td></td>\n");
        html.append("<td></td>\n");
        html.append("</tr>\n");
        // Getting JavaScript
        {
          final Vector<String[]> auxJavaScript = auxControl.getJSCode();
          if (auxJavaScript != null) {
            for (int j = 0; j < auxJavaScript.size(); j++) {
              final String[] auxObj = auxJavaScript.elementAt(j);
              javaScriptFunctions.setProperty(auxObj[0], auxObj[1]);
            }
          }
        } // End getting JavaScript
        // Getting css imports
        {
          final Vector<String[]> auxCss = auxControl.getCSSImport();
          if (auxCss != null) {
            for (int j = 0; j < auxCss.size(); j++) {
              final String[] auxObj = auxCss.elementAt(j);
              importsCSS.setProperty(auxObj[0], auxObj[1]);
            }
          }
        } // End getting css imports
        // Getting js imports
        {
          final Vector<String[]> auxJs = auxControl.getImport();
          if (auxJs != null) {
            for (int j = 0; j < auxJs.size(); j++) {
              final String[] auxObj = auxJs.elementAt(j);
              importsJS.setProperty(auxObj[0], auxObj[1]);
            }
          }
        } // End getting js imports
        if (!auxControl.getValidation().equals(""))
          validations.append(auxControl.getValidation()).append("\n");
        if (!auxControl.getOnLoad().equals(""))
          onload.append(auxControl.getOnLoad()).append("\n");
      }
      xmlDocument.setParameter("fields", html.toString());
      final StringBuffer sbImportCSS = new StringBuffer();
      for (final Enumeration<?> e = importsCSS.propertyNames(); e.hasMoreElements();) {
        final String _name = (String) e.nextElement();
        sbImportCSS.append("<link rel=\"stylesheet\" type=\"text/css\" href=\"").append(
            importsCSS.getProperty(_name)).append("\"/>\n");
      }
      xmlDocument.setParameter("importCSS", sbImportCSS.toString());
      final StringBuffer sbImportJS = new StringBuffer();
      boolean hasCalendar = false;
      boolean calendarInserted = false;
      boolean calendarLangInserted = false;
      for (final Enumeration<?> e = importsJS.propertyNames(); e.hasMoreElements();) {
        final String _name = (String) e.nextElement();
        if (_name.startsWith("calendar"))
          hasCalendar = true;
        if (!_name.equals("calendarLang") || calendarInserted) {
          sbImportJS.append("<script language=\"JavaScript\" src=\"").append(
              importsJS.getProperty(_name)).append("\" type=\"text/javascript\"></script>\n");
          if (_name.equals("calendarLang"))
            calendarLangInserted = true;
        }
        if (_name.equals("calendar"))
          calendarInserted = true;
      }
      if (hasCalendar && !calendarLangInserted)
        sbImportJS.append("<script language=\"JavaScript\" src=\"").append(
            importsJS.getProperty("calendarLang"))
            .append("\" type=\"text/javascript\"></script>\n");
      xmlDocument.setParameter("importJS", sbImportJS.toString());
      final StringBuffer script = new StringBuffer();
      for (final Enumeration<?> e = javaScriptFunctions.propertyNames(); e.hasMoreElements();) {
        final String _name = (String) e.nextElement();
        script.append(javaScriptFunctions.getProperty(_name)).append("\n");
      }
      script.append("\nfunction validateClient(action, form, value) {\n");
      script.append("  var frm=document.frmMain;\n");
      script.append(validations);
      script.append("  setProcessingMode('popup', true);\n");
      script.append("  return true;\n");
      script.append("}\n");

      script.append("\nfunction onloadClient() {\n");
      script.append("  var frm=document.frmMain;\n");
      script.append("  var key = frm.inpKey;");
      script.append(onload);
      script.append("  return true;\n");
      script.append("}\n");

      script.append("\nfunction reloadComboReloads").append(fd.reference).append(
          "(changedField) {\n");
      script
          .append("  submitCommandForm(changedField, false, null, '../ad_callouts/ComboReloadsProcessHelper.html', 'hiddenFrame', null, null, true);\n");
      script.append("  return true;\n");
      script.append("}\n");

      xmlDocument.setParameter("script", script.toString());
    }
    WadUtility.writeFile(fileDir, (fd.columnname + fd.reference) + ".html", xmlDocument.print());
  }

  /*
   * ########################################################################## #############
   */
  /**
   * Sets the correct format parameter for the xml, which depends on the column type.
   * 
   * @param data
   *          Object with the column info.
   */
  public static void xmlFormatAttribute(ProcessRelationData data) {
    if (data == null)
      return;
    if (WadUtility.isIntegerNumber(data.adReferenceId))
      data.xmlFormat = "INTEGER";
    else if (WadUtility.isDecimalNumber(data.adReferenceId))
      data.xmlFormat = "EURO";
    else if (WadUtility.isQtyNumber(data.adReferenceId))
      data.xmlFormat = "QTY";
    else if (WadUtility.isPriceNumber(data.adReferenceId))
      data.xmlFormat = "PRICE";
  }

  /**
   * Returns the string with the xml fields for the xml file.
   * 
   * @param fd
   *          Object with the column info.
   * @param completeName
   *          Complete name of the column.
   * @param maxTextboxLength
   *          Maximum size for a textbox control.
   * @param forcedAttribute
   *          Indicates if the column is a parameter or not.
   * @return String with the xml code.
   */
  public static String xmlFields(ProcessRelationData fd, String completeName, int maxTextboxLength,
      boolean forcedAttribute) {
    final StringBuffer html = new StringBuffer();
    final String strSystemSeparator = System.getProperty("file.separator");

    if (forcedAttribute) {
      html.append("<PARAMETER ");
      html.append("id=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("name=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("attribute=\"value\"");
      if (WadUtility.isDecimalNumber(fd.adReferenceId))
        html.append(" format=\"euroEdition\"");
      else if (WadUtility.isQtyNumber(fd.adReferenceId))
        html.append(" format=\"qtyEdition\"");
      else if (WadUtility.isPriceNumber(fd.adReferenceId))
        html.append(" format=\"priceEdition\"");
      else if (WadUtility.isIntegerNumber(fd.adReferenceId))
        html.append(" format=\"integerEdition\"");
      else if (WadUtility.isGeneralNumber(fd.adReferenceId))
        html.append(" format=\"generalQtyEdition\"");
      html.append(">");
      html.append("</PARAMETER>");
    } else if (fd.adReferenceId.equals("17") || fd.adReferenceId.equals("18")
        || fd.adReferenceId.equals("19")) { // List
      html.append(xmlFields(fd, completeName, maxTextboxLength, true));
      if (fd.isdisplayed.equals("Y")) {
        html.append("\n<SUBREPORT id=\"report" + Sqlc.TransformaNombreColumna(fd.columnname)
            + completeName + "\" name=\"report" + Sqlc.TransformaNombreColumna(fd.columnname)
            + completeName + "\"");
        html.append(" report=\"org" + strSystemSeparator + "openbravo" + strSystemSeparator
            + "erpCommon" + strSystemSeparator + "reference" + strSystemSeparator + "List\">\n");
        html.append("  <ARGUMENT name=\"parameterListSelected\" withId=\""
            + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\"/>\n");
        html.append("</SUBREPORT>\n");
      }
    } else if (fd.adReferenceId.equals("20") && fd.isdisplayed.equals("Y")) { // YesNo
      html.append("<PARAMETER ");
      html.append("id=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("name=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("boolean=\"checked\" withId=\"paramCheck\"");
      html.append(">");
      html.append("</PARAMETER>");
    } else if (fd.adReferenceId.equals("28") && fd.isdisplayed.equals("Y")
        && !fd.adReferenceValueId.equals("")) { // Button
      html.append("<PARAMETER ");
      html.append("id=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("name=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append(" attribute=\"value\">");
      html.append(Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "</PARAMETER>");
      html.append("<PARAMETER ");
      html.append("id=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "_BTN\" ");
      html.append("name=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\">");
      html.append("</PARAMETER>");
    } else if ((fd.adReferenceId.equals("34") || fd.adReferenceId.equals("14"))
        && fd.isdisplayed.equals("Y")) {
      html.append("<PARAMETER ");
      html.append("id=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("name=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append(">");
      html.append("</PARAMETER>");
    } else if (Integer.valueOf(fd.fieldlength).intValue() > maxTextboxLength
        && fd.isdisplayed.equals("Y")) {
      html.append("<PARAMETER ");
      html.append("id=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("name=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      if (WadUtility.isDecimalNumber(fd.adReferenceId))
        html.append(" format=\"euroEdition\"");
      else if (WadUtility.isQtyNumber(fd.adReferenceId))
        html.append(" format=\"qtyEdition\"");
      else if (WadUtility.isPriceNumber(fd.adReferenceId))
        html.append(" format=\"priceEdition\"");
      else if (WadUtility.isIntegerNumber(fd.adReferenceId))
        html.append(" format=\"integerEdition\"");
      else if (WadUtility.isGeneralNumber(fd.adReferenceId))
        html.append(" format=\"generalQtyEdition\"");
      html.append(">");
      html.append("</PARAMETER>");
    } else {
      html.append("<PARAMETER ");
      html.append("id=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("name=\"" + Sqlc.TransformaNombreColumna(fd.columnname) + completeName + "\" ");
      html.append("attribute=\"value\"");
      if (WadUtility.isDecimalNumber(fd.adReferenceId))
        html.append(" format=\"euroEdition\"");
      else if (WadUtility.isQtyNumber(fd.adReferenceId))
        html.append(" format=\"qtyEdition\"");
      else if (WadUtility.isPriceNumber(fd.adReferenceId))
        html.append(" format=\"priceEdition\"");
      else if (WadUtility.isIntegerNumber(fd.adReferenceId))
        html.append(" format=\"integerEdition\"");
      else if (WadUtility.isGeneralNumber(fd.adReferenceId))
        html.append(" format=\"generalQtyEdition\"");
      html.append(">");
      html.append("</PARAMETER>");
    }

    return html.toString();
  }

  /**
   * Returns the specific class for the column.
   * 
   * @param efd
   *          Object with the column info.
   * @return String with the class.
   */
  public static String classRequiredUpdateable(ProcessRelationData efd) {
    final StringBuffer htmltext = new StringBuffer();
    String strAux = "";
    if (WadUtility.isGeneralNumber(efd.adReferenceId)
        || WadUtility.isDecimalNumber(efd.adReferenceId)
        || WadUtility.isQtyNumber(efd.adReferenceId) || WadUtility.isPriceNumber(efd.adReferenceId)
        || WadUtility.isIntegerNumber(efd.adReferenceId)) {
      strAux = " number";
    }
    String strType = "dojoValidateValid";
    String classType = "TextBox";
    if (WadUtility.isSelectType(efd.adReferenceId)) {
      strType = "Combo";
      classType = "Combo";
    }
    if (efd.required.equals("Y"))
      htmltext.append(" class=\"").append(strType).append(" required").append(strAux).append(" ")
          .append(classType).append("_OneCell_width\" ");
    else if (!strAux.equals(""))
      htmltext.append(" class=\"").append(strType).append(strAux).append(" ").append(classType)
          .append("_OneCell_width\" ");

    return htmltext.toString();
  }

  /**
   * Returns the code of a control in html.
   * 
   * @param efd
   *          Object with the column info.
   * @param completeName
   *          Suffix for the name.
   * @param completeID
   *          Suffix for the id.
   * @param isupdateable
   *          If is an updateable column.
   * @param maxTextboxLength
   *          Maximum size for the textbox control.
   * @param forcedAttribute
   *          If is an attribute.
   * @param isdesigne
   *          If is a design control.
   * @return String with the html code.
   */
  public static String htmlFields(ProcessRelationData efd, String completeName, String completeID,
      boolean isupdateable, int maxTextboxLength, boolean forcedAttribute, boolean isdesigne) {
    final StringBuffer html = new StringBuffer();

    if (forcedAttribute) {
      html.append("<input type=\"hidden\"");
      html.append(" name=\"inp" + Sqlc.TransformaNombreColumna(efd.columnname) + completeName);
      html.append("\" id=\"" + Sqlc.TransformaNombreColumna(efd.columnname) + completeID
          + "\" value=\"");
      if (!isdesigne)
        html.append("xxV");
      if (WadUtility.isGeneralNumber(efd.adReferenceId)
          || WadUtility.isDecimalNumber(efd.adReferenceId)
          || WadUtility.isQtyNumber(efd.adReferenceId)
          || WadUtility.isPriceNumber(efd.adReferenceId))
        html.append("\" onkeydown=\"autoCompleteNumber(this, true, true, event);return true;");
      else if (WadUtility.isIntegerNumber(efd.adReferenceId))
        html.append("\" onkeydown=\"autoCompleteNumber(this, false, true, event);return true;");
      html.append("\">");
    } else if ((efd.adReferenceId.equals("17") || efd.adReferenceId.equals("18") || efd.adReferenceId
        .equals("19"))
        && efd.isdisplayed.equals("Y")) { // List or Table or TableDir
      html.append("<select name=\"inp" + Sqlc.TransformaNombreColumna(efd.columnname)
          + completeName + "\"");
      html.append(classRequiredUpdateable(efd));
      html.append(" id=\"report");
      html.append(efd.columnname + completeID + "_S\"");
      html.append(">");
      if (!efd.required.equals("Y"))
        html.append("<option value=\"\"></option>");
      html.append("<div id=\"report");
      html.append(Sqlc.TransformaNombreColumna(efd.columnname) + completeID + "\"></div>");
      html.append("</select>");
    } else if ((efd.adReferenceId.equals("34") || efd.adReferenceId.equals("14") || (!efd.adReferenceId
        .equals("20") && (Integer.valueOf(efd.fieldlength).intValue() > maxTextboxLength)))
        && efd.isdisplayed.equals("Y")) { // TEXTAREA
      html.append("<textarea cols=\"" + efd.fieldlength + "\" rows=\"3\" name=\"inp"
          + Sqlc.TransformaNombreColumna(efd.columnname));
      html.append(completeName + "\" id=\"" + Sqlc.TransformaNombreColumna(efd.columnname)
          + completeID + "\" ");
      html.append(classRequiredUpdateable(efd));
      html.append(">");
      if (!isdesigne)
        html.append("xxV");
      html.append("</textarea>");
    } else {
      html.append("<input type=\"");
      if (efd.isdisplayed.equals("N")) {
        html.append("hidden\"");
      } else if (efd.adReferenceId.equals("20")) { // YesNo
        html.append("checkbox\"");
      } else {
        html.append("text\"");
        if (WadUtility.isGeneralNumber(efd.adReferenceId)
            || WadUtility.isDecimalNumber(efd.adReferenceId)
            || WadUtility.isQtyNumber(efd.adReferenceId)
            || WadUtility.isPriceNumber(efd.adReferenceId))
          html.append(" onkeydown=\"autoCompleteNumber(this, true, true, event);return true;\"");
        else if (WadUtility.isIntegerNumber(efd.adReferenceId))
          html.append(" onkeydown=\"autoCompleteNumber(this, false, true, event);return true;\"");
        html.append(" size=\"" + efd.fieldlength + "\" ");
        html.append(classRequiredUpdateable(efd));
        if (!WadUtility.isSearchType(efd.adReferenceId))
          html.append(" maxlength=\"" + efd.fieldlength + "\"");
      }
      html.append(" name=\"inp" + Sqlc.TransformaNombreColumna(efd.columnname) + completeName);
      html.append("\" id=\"" + Sqlc.TransformaNombreColumna(efd.columnname) + completeID + "\" ");
      html.append("value=\"");
      if (efd.isdisplayed.equals("N")) {
        if (!isdesigne)
          html.append("xxV");
      } else if (efd.adReferenceId.equals("20")) {
        html.append("Y");
      } else {
        if (!isdesigne)
          html.append("xxV");
      }
      html.append("\"");
      if (efd.isdisplayed.equals("Y") && isupdateable && WadUtility.isDateField(efd.adReferenceId)) { // Date.
        // Put
        // a
        // calendar
        html.append(" onkeyup=\"auto_completar_fecha(this);return true;\"");
      } else if (efd.isdisplayed.equals("Y") && isupdateable
          && WadUtility.isTimeField(efd.adReferenceId)) { // Time. Put
        // a clock
        html.append(" onkeyup=\"auto_completar_hora(this, true);return true;\"");
      }
      html.append(">");
    }

    return html.toString();
  }

  /**
   * Searchs a field in a vector.
   * 
   * @param vecFields
   *          Vector with the fields.
   * @param token
   *          The field to search.
   * @return String with the name of the field.
   */
  public static String findField(Vector<Object> vecFields, String token) {
    if (vecFields == null)
      return "";
    for (int i = 0; i < vecFields.size(); i++) {
      final String field = vecFields.elementAt(i).toString();
      if (field.equalsIgnoreCase(token))
        return field;
    }
    return "";
  }

  /**
   * Generates the js command for the searchs.
   * 
   * @param efd
   *          Object with the column info.
   * @param fromButton
   *          Boolean that indicates if is a button.
   * @param vecFields
   *          Vector with the fields.
   * @param conn
   *          Object with the database connection.
   * @return String with the js command.
   */
  public static String searchsCommand(ProcessRelationData efd, boolean fromButton,
      Vector<Object> vecFields, ConnectionProvider conn) {
    final StringBuffer params = new StringBuffer();
    final StringBuffer html = new StringBuffer();
    final String strName = FormatUtilities.replace(efd.searchname.trim());
    if (!fromButton) {
      params.append(", 'Command'");
      params.append(", 'KEY'");
    }
    params.append(", 'WindowID'");
    params.append(", document.frmMain.inpwindowId.value");
    String searchName = ((efd.reference != null && efd.reference.equals("31")) ? "/info/Locator"
        : "/info/" + strName)
        + "_FS.html";
    EditionFieldsData[] fieldsSearch = null;
    try {
      if (efd.reference != null && efd.reference.equals("30") && efd.adReferenceValueId != null
          && !efd.adReferenceValueId.equals(""))
        fieldsSearch = EditionFieldsData.selectSearchs(conn, "I", efd.adReferenceValueId);
    } catch (final ServletException ex) {
      ex.printStackTrace();
    }
    if (fieldsSearch != null && fieldsSearch.length > 0) {
      searchName = fieldsSearch[0].mappingname;
      if (!fieldsSearch[0].referencevalue.equals("")) {
        for (int i = 0; i < fieldsSearch.length; i++) {
          final String field = findField(vecFields, fieldsSearch[i].referencevalue);
          if (!field.equals("")) {
            params.append(", 'inp").append(fieldsSearch[i].columnnameinp).append("'");
            params
                .append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
          }
        }
      }
    } else {
      if (efd.name.equalsIgnoreCase("PRODUCT")) {
        String field = findField(vecFields, "m_pricelist_id");
        if (!field.equals("")) {
          params.append(", 'inpPriceList'");
          params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
        }
        field = findField(vecFields, "m_warehouse_id");
        if (!field.equals("")) {
          params.append(", 'inpWarehouse'");
          params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
        }
        field = findField(vecFields, "dateordered");
        if (!field.equals("")) {
          params.append(", 'inpDate'");
          params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
        }
      }
    }
    html.append("openSearch(null, null, '..").append(searchName).append(
        "', null, false, 'frmMain', 'inp").append(Sqlc.TransformaNombreColumna(efd.columnname))
        .append("', 'inp").append(Sqlc.TransformaNombreColumna(efd.columnname)).append(
            "_R', document.frmMain.inp").append(Sqlc.TransformaNombreColumna(efd.columnname))
        .append("_R.value").append(params.toString()).append(");");
    return html.toString();
  }

  /**
   * Generates the html code of the search button.
   * 
   * @param efd
   *          Object with the column info.
   * @param maxTextboxLength
   *          Maximum size for a textbox control.
   * @param vecFields
   *          Vector with the fields.
   * @param conn
   *          Object with the database connection.
   * @return String with the button code.
   */
  public static String searchs(ProcessRelationData efd, int maxTextboxLength,
      Vector<Object> vecFields, ConnectionProvider conn) {
    final StringBuffer html = new StringBuffer();
    String strName = FormatUtilities.replace(efd.searchname.trim());
    if (efd.adReferenceId.equals("31")) {
      strName = "Locator";
    } else if (efd.name.toUpperCase().indexOf("BUSINESS") != -1) {
      html.append(htmlFields(efd, "_LOC", "_LOC", true, maxTextboxLength, true, true));
      html.append(htmlFields(efd, "_CON", "_CON", true, maxTextboxLength, true, true));
    } else if (efd.name.equalsIgnoreCase("PRODUCT")) {
      html.append(htmlFields(efd, "_PLIST", "_PLIST", true, maxTextboxLength, true, true));
      html.append(htmlFields(efd, "_PSTD", "_PSTD", true, maxTextboxLength, true, true));
      html.append(htmlFields(efd, "_UOM", "_UOM", true, maxTextboxLength, true, true));
      html.append(htmlFields(efd, "_PLIM", "_PLIM", true, maxTextboxLength, true, true));
      html.append(htmlFields(efd, "_CURR", "_CURR", true, maxTextboxLength, true, true));
    }
    html.append("<a href=\"#\"");
    html.append("onClick=\"" + searchsCommand(efd, true, vecFields, conn) + "return false;\" ");
    html.append("onMouseOut=\"window.status='';return true;\"");
    html.append("onMouseOver=\"window.status='").append(efd.referenceName).append(
        "';return true;\" class=\"windowbutton\"><img width=\"").append(IMAGE_EDITION_WIDTH)
        .append("\" height=\"").append(IMAGE_EDITION_HEIGHT).append("\" alt=\"").append(efd.name)
        .append("\" title=\"").append(efd.name).append("\"");
    html.append(" border=\"0\" src=\"../../../../../web/images/" + strName + ".jpg\" id=\"button"
        + strName + "\"></a>");
    return html.toString();
  }

  /**
   * Generates the html code of the product search button.
   * 
   * @param efd
   *          Object with the column info.
   * @param maxTextboxLength
   *          Maximum size of the textbox control.
   * @param vecFields
   *          Vector with the fields.
   * @param conn
   *          Object with the database connection.
   * @return String with the control code.
   */
  public static String productSearch(ProcessRelationData efd, int maxTextboxLength,
      Vector<Object> vecFields, ConnectionProvider conn) {
    final StringBuffer html = new StringBuffer();
    efd.searchname = "Product Complete";
    html.append(htmlFields(efd, "_LOC", "_LOC", true, maxTextboxLength, true, true));
    html.append(htmlFields(efd, "_ATR", "_ATR", true, maxTextboxLength, true, true));
    html.append(htmlFields(efd, "_PQTY", "_PQTY", true, maxTextboxLength, true, true));
    html.append(htmlFields(efd, "_PUOM", "_PUOM", true, maxTextboxLength, true, true));
    html.append(htmlFields(efd, "_QTY", "_QTY", true, maxTextboxLength, true, true));
    html.append(htmlFields(efd, "_UOM", "_UOM", true, maxTextboxLength, true, true));

    html.append("<a href=\"#\"");
    html.append("onClick=\"" + searchsCommand(efd, true, vecFields, conn) + "return false;\" ");
    html.append("onMouseOut=\"window.status='';return true;\"");
    html.append("onMouseOver=\"window.status='").append(efd.referenceName).append(
        "';return true;\" class=\"windowbutton\"><img width=\"").append(IMAGE_EDITION_WIDTH)
        .append("\" height=\"").append(IMAGE_EDITION_HEIGHT).append("\" alt=\"").append(efd.name)
        .append("\" title=\"").append(efd.name).append("\"");
    html.append(" border=\"0\" src=\"../../../../../web/images/"
        + FormatUtilities.replace(efd.searchname.trim()) + ".jpg\" id=\"button"
        + FormatUtilities.replace(efd.searchname.trim()) + "\"></a>");
    return html.toString();
  }
}
