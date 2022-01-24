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
 * All portions are Copyright (C) 2001-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.wad;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Properties;
import java.util.StringTokenizer;
import java.util.Vector;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.Sqlc;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.wad.controls.WADControl;
import org.openbravo.xmlEngine.XmlEngine;

public class WadUtility {
  static Logger log4j = Logger.getLogger(WadUtility.class);
  static final int IMAGE_EDITION_WIDTH = 200;
  static final int IMAGE_EDITION_HEIGHT = 200;
  static final int IMAGE_BUTTON_WIDTH = 16;
  static final int IMAGE_BUTTON_HEIGHT = 16;
  static String[][] comparations = { { "==", " == " }, { "=", " == " }, { "!", " != " },
      { "^", " != " }, { "-", " != " } };
  static String[][] unions = { { "|", " || " }, { "&", " && " } };

  public WadUtility() {
    PropertyConfigurator.configure("log4j.lcf");
  }

  public static String columnIdentifier(ConnectionProvider conn, String tableName,
      boolean required, FieldsData fields, int ilist, int itable, boolean translated,
      Vector<Object> vecFields, Vector<Object> vecTable, Vector<Object> vecWhere,
      Vector<Object> vecParameters, Vector<Object> vecTableParameters, String sqlDateFormat)
      throws ServletException {
    if (fields == null)
      return "";
    StringBuffer texto = new StringBuffer();
    if (fields.reference.equals("17")) { // List
      ilist++;
      if (tableName != null && tableName.length() != 0) {
        vecTable.addElement("left join ad_ref_list_v list" + ilist + " on (" + tableName + "."
            + fields.name + " = list" + ilist + ".value and list" + ilist + ".ad_reference_id = '"
            + fields.referencevalue + "' and list" + ilist + ".ad_language = ?) ");
        vecTableParameters.addElement("<Parameter name=\"paramLanguage\"/>");
      } else {
        vecTable.addElement("ad_ref_list_v list" + ilist);
        vecWhere.addElement(fields.referencevalue + " = " + "list" + ilist + ".ad_reference_id");
        vecWhere.addElement("list" + ilist + ".ad_language = ? ");
        vecParameters.addElement("<Parameter name=\"paramLanguage\"/>");
      }
      texto.append("list").append(ilist).append(".name");
      vecFields.addElement(texto.toString());
    } else if (fields.reference.equals("18")) { // Table
      itable++;
      TableRelationData trd[] = TableRelationData.selectRefTable(conn, fields.referencevalue);
      if (log4j.isDebugEnabled())
        log4j.debug(" number of TableRelationData: " + trd.length);
      vecTable
          .addElement("left join (select "
              + trd[0].keyname
              + ((trd[0].isvaluedisplayed.equals("Y") && !trd[0].keyname.equalsIgnoreCase("value")) ? ", value"
                  : "")
              + (!trd[0].keyname.equalsIgnoreCase(trd[0].name) ? (", " + trd[0].name) : "")
              + " from " + trd[0].tablename + ") table" + itable + " on (" + tableName + "."
              + fields.name + " = table" + itable + "." + trd[0].keyname + ") ");
      FieldsData fieldsAux = new FieldsData();
      fieldsAux.name = trd[0].name;
      fieldsAux.tablename = trd[0].tablename;
      fieldsAux.reference = trd[0].reference;
      fieldsAux.referencevalue = trd[0].referencevalue;
      fieldsAux.required = trd[0].required;
      fieldsAux.istranslated = trd[0].istranslated;
      if (trd[0].isvaluedisplayed.equals("Y"))
        texto.append("table" + itable + ".value || ' - ' || ");
      texto.append(columnIdentifier(conn, "table" + itable, required, fieldsAux, ilist, itable,
          translated, vecFields, vecTable, vecWhere, vecParameters, vecTableParameters,
          sqlDateFormat));
    } else if (fields.reference.equals("19")) { // TableDir
      itable++;
      int ilength = fields.name.length();
      String tableDirName = fields.name.substring(0, ilength - 3);
      FieldsData fdi[] = FieldsData.identifierColumns(conn, tableDirName);
      vecTable.addElement("left join " + tableDirName + " on (" + tableName + "." + fields.name
          + " = " + tableDirName + "." + fields.name + ") ");
      for (int i = 0; i < fdi.length; i++) {
        if (i > 0)
          texto.append(" || ' - ' || ");
        texto.append(columnIdentifier(conn, tableDirName, required, fdi[i], ilist, itable,
            translated, vecFields, vecTable, vecWhere, vecParameters, vecTableParameters,
            sqlDateFormat));
      }
    } else if (fields.reference.equals("30")) {
      itable++;
      EditionFieldsData[] dataSearchs = EditionFieldsData.selectSearchs(conn, "",
          fields.referencevalue);
      String tableDirName = "", fieldId = "";
      if (dataSearchs == null || dataSearchs.length == 0) {
        int ilength = fields.name.length();
        if (fields.reference.equals("25"))
          tableDirName = "C_ValidCombination";
        else if (fields.reference.equals("31"))
          tableDirName = "M_Locator";
        else if (fields.reference.equals("800011"))
          tableDirName = "M_Product";
        else
          tableDirName = fields.name.substring(0, ilength - 3);
        if (fields.reference.equals("25"))
          fieldId = "C_ValidCombination_ID";
        else if (fields.reference.equals("31"))
          fieldId = "M_Locator_ID";
        else if (fields.reference.equals("800011"))
          fieldId = "M_Product_ID";
        else
          fieldId = fields.name;
      } else {
        tableDirName = dataSearchs[0].reference;
        fieldId = dataSearchs[0].columnname;
      }
      FieldsData fdi[] = FieldsData.identifierColumns(conn, tableDirName);
      vecTable.addElement("left join " + tableDirName + " on (" + tableName + "." + fields.name
          + " = " + tableDirName + "." + fieldId + ")");
      for (int i = 0; i < fdi.length; i++) {
        if (i > 0)
          texto.append(" || ' - ' || ");
        texto.append(columnIdentifier(conn, tableDirName, required, fdi[i], ilist, itable,
            translated, vecFields, vecTable, vecWhere, vecParameters, vecTableParameters,
            sqlDateFormat));
      }
    } else if (fields.reference.equals("31") || fields.reference.equals("35")
        || fields.reference.equals("25") || fields.reference.equals("800011")) { // Search y Locator
      itable++;
      int ilength = fields.name.length();
      String tableDirName = "";
      if (fields.reference.equals("25"))
        tableDirName = "C_ValidCombination";
      else if (fields.reference.equals("31"))
        tableDirName = "M_Locator";
      else if (fields.reference.equals("35"))
        tableDirName = "M_AttributeSetInstance";
      else if (fields.reference.equals("800011"))
        tableDirName = "M_Product";
      else
        tableDirName = fields.name.substring(0, ilength - 3);
      String fieldId = "";
      if (fields.reference.equals("25"))
        fieldId = "C_ValidCombination_ID";
      else if (fields.reference.equals("31"))
        fieldId = "M_Locator_ID";
      else if (fields.reference.equals("35"))
        fieldId = "M_AttributeSetInstance_ID";
      else if (fields.reference.equals("800011"))
        fieldId = "M_Product_ID";
      else
        fieldId = fields.name;
      FieldsData fdi[] = FieldsData.identifierColumns(conn, tableDirName);
      vecTable.addElement("left join " + tableDirName + " on (" + tableName + "." + fields.name
          + " = " + tableDirName + "." + fieldId + ")");
      for (int i = 0; i < fdi.length; i++) {
        if (i > 0)
          texto.append(" || ' - ' || ");
        texto.append(columnIdentifier(conn, tableDirName, required, fdi[i], ilist, itable,
            translated, vecFields, vecTable, vecWhere, vecParameters, vecTableParameters,
            sqlDateFormat));
      }
    } else {
      if (fields.istranslated.equals("Y")
          && TableRelationData.existsTableColumn(conn, fields.tablename + "_TRL", fields.name)) {
        FieldsData fdi[] = FieldsData.tableKeyColumnName(conn, fields.tablename);
        if (fdi == null || fdi.length == 0) {
          vecFields.addElement(applyFormat(tableName + "." + fields.name, fields.reference,
              sqlDateFormat));
          texto.append(applyFormat(tableName + "." + fields.name, fields.reference, sqlDateFormat));
        } else {
          vecTable.addElement("left join (select " + fdi[0].name + ", AD_Language"
              + (!fdi[0].name.equalsIgnoreCase(fields.name) ? (", " + fields.name) : "") + " from "
              + fields.tablename + "_TRL) tableTRL" + itable + " on (" + tableName + "."
              + fdi[0].name + " = tableTRL" + itable + "." + fdi[0].name + " and tableTRL" + itable
              + ".AD_Language = ?) ");
          vecTableParameters.addElement("<Parameter name=\"paramLanguage\"/>");
          vecFields.addElement(applyFormat("(CASE WHEN tableTRL" + itable + "." + fields.name
              + " IS NULL THEN TO_CHAR(" + tableName + "." + fields.name
              + ") ELSE TO_CHAR(tableTRL" + itable + "." + fields.name + ") END)",
              fields.reference, sqlDateFormat));
          texto.append(applyFormat("(CASE WHEN tableTRL" + itable + "." + fields.name
              + " IS NULL THEN TO_CHAR(" + tableName + "." + fields.name
              + ") ELSE TO_CHAR(tableTRL" + itable + "." + fields.name + ") END)",
              fields.reference, sqlDateFormat));
        }
      } else {
        vecFields.addElement(applyFormat(tableName + "." + fields.name, fields.reference,
            sqlDateFormat));
        texto.append(applyFormat(tableName + "." + fields.name, fields.reference, sqlDateFormat));
      }
    }
    return texto.toString();
  }

  public static String applyFormat(String text, String reference, String sqlDateFormat) {
    if (isDateField(reference))
      return "TO_CHAR(" + text + ", '" + sqlDateFormat + "')";
    else if (isTimeField(reference))
      return "TO_CHAR(" + text + ", 'HH24:MM:SS')";
    else if (isDateTimeField(reference))
      return "TO_CHAR(" + text + ", '" + sqlDateFormat + " HH24:MM:SS')";
    else
      text = "TO_CHAR(COALESCE(TO_CHAR(" + text + "), ''))";
    return text;
  }

  public static String columnIdentifier(ConnectionProvider conn, String tableName,
      boolean required, FieldsData fields, Vector<Object> vecCounters, boolean translated,
      Vector<Object> vecFields, Vector<Object> vecTable, Vector<Object> vecWhere,
      Vector<Object> vecParameters, Vector<Object> vecTableParameters, String sqlDateFormat)
      throws ServletException {
    if (fields == null)
      return "";
    StringBuffer texto = new StringBuffer();
    int ilist = Integer.valueOf(vecCounters.elementAt(1).toString()).intValue();
    int itable = Integer.valueOf(vecCounters.elementAt(0).toString()).intValue();
    if (fields.reference.equals("13")) { // ID
      FieldsData fdi[] = FieldsData.identifierColumns(conn, tableName);
      for (int i = 0; i < fdi.length; i++) {
        if (i > 0)
          texto.append(" || ' - ' || ");
        vecCounters.set(0, Integer.toString(itable));
        vecCounters.set(1, Integer.toString(ilist));
        texto.append(columnIdentifier(conn, tableName, required, fdi[i], vecCounters, translated,
            vecFields, vecTable, vecWhere, vecParameters, vecTableParameters, sqlDateFormat));
        ilist = Integer.valueOf(vecCounters.elementAt(1).toString()).intValue();
        itable = Integer.valueOf(vecCounters.elementAt(0).toString()).intValue();
      }
      if (texto.toString().equals("")) {
        vecFields.addElement(((tableName != null && tableName.length() != 0) ? (tableName + ".")
            : "")
            + fields.name);
        texto.append(((tableName != null && tableName.length() != 0) ? (tableName + ".") : "")
            + fields.name);
      }
    } else if (fields.reference.equals("17")) { // List
      ilist++;
      if (tableName != null && tableName.length() != 0) {
        vecTable.addElement("left join ad_ref_list_v list" + ilist + " on (" + tableName + "."
            + fields.name + " = list" + ilist + ".value and list" + ilist + ".ad_reference_id = '"
            + fields.referencevalue + "' and list" + ilist + ".ad_language = ?) ");
        vecTableParameters.addElement("<Parameter name=\"paramLanguage\"/>");
      } else {
        vecTable.addElement("ad_ref_list_v list" + ilist);
        vecWhere.addElement(fields.referencevalue + " = " + "list" + ilist + ".ad_reference_id ");
        vecWhere.addElement("list" + ilist + ".ad_language = ? ");
        vecParameters.addElement("<Parameter name=\"paramLanguage\"/>");
      }
      texto.append("list").append(ilist).append(".name");
      vecFields.addElement(texto.toString());
      vecCounters.set(0, Integer.toString(itable));
      vecCounters.set(1, Integer.toString(ilist));
    } else if (fields.reference.equals("18")) { // Table
      itable++;
      TableRelationData trd[] = TableRelationData.selectRefTable(conn, fields.referencevalue);
      if (log4j.isDebugEnabled())
        log4j.debug(" number of TableRelationData: " + trd.length);

      if (tableName != null && tableName.length() != 0) {
        vecTable
            .addElement("left join (select "
                + trd[0].keyname
                + ((trd[0].isvaluedisplayed.equals("Y") && !trd[0].keyname
                    .equalsIgnoreCase("value")) ? ", value" : "")
                + (!trd[0].keyname.equalsIgnoreCase(trd[0].name) ? (", " + trd[0].name) : "")
                + " from " + trd[0].tablename + ") table" + itable + " on (" + tableName + "."
                + fields.name + " = " + " table" + itable + "." + trd[0].keyname + ")");
      } else {
        vecTable.addElement(trd[0].tablename + " table" + itable);
      }
      FieldsData fieldsAux = new FieldsData();
      fieldsAux.name = trd[0].name;
      fieldsAux.tablename = trd[0].tablename;
      fieldsAux.reference = trd[0].reference;
      fieldsAux.referencevalue = trd[0].referencevalue;
      fieldsAux.required = trd[0].required;
      fieldsAux.istranslated = trd[0].istranslated;
      vecCounters.set(0, Integer.toString(itable));
      vecCounters.set(1, Integer.toString(ilist));
      if (trd[0].isvaluedisplayed.equals("Y"))
        texto.append("table" + itable + ".value || ' - ' || ");
      texto.append(columnIdentifier(conn, "table" + itable, required, fieldsAux, vecCounters,
          translated, vecFields, vecTable, vecWhere, vecParameters, vecTableParameters,
          sqlDateFormat));
      ilist = Integer.valueOf(vecCounters.elementAt(1).toString()).intValue();
      itable = Integer.valueOf(vecCounters.elementAt(0).toString()).intValue();
    } else if (fields.reference.equals("32")) { // Image
      ilist++;
      if (tableName != null && tableName.length() != 0) {
        vecTable.addElement("left join (select AD_Image_ID, ImageURL from AD_Image) list" + ilist
            + " on (" + tableName + "." + fields.name + " = list" + ilist + ".AD_Image_ID) ");
      } else {
        vecTable.addElement("AD_Image list" + ilist);
      }
      texto.append("list").append(ilist).append(".ImageURL");
      vecFields.addElement(texto.toString());
      vecCounters.set(0, Integer.toString(itable));
      vecCounters.set(1, Integer.toString(ilist));
    } else if (fields.reference.equals("19") || fields.reference.equals("30")
        || fields.reference.equals("31") || fields.reference.equals("35")
        || fields.reference.equals("25") || fields.reference.equals("800011")) { // TableDir, Search
      // y
      // Locator
      itable++;
      EditionFieldsData[] dataSearchs = null;
      if (fields.reference.equals("30"))
        dataSearchs = EditionFieldsData.selectSearchs(conn, "", fields.referencevalue);
      String tableDirName = "", fieldId = "";
      if (dataSearchs == null || dataSearchs.length == 0) {
        int ilength = fields.name.length();
        if (fields.reference.equals("25"))
          tableDirName = "C_ValidCombination";
        else if (fields.reference.equals("31"))
          tableDirName = "M_Locator";
        else if (fields.reference.equals("35"))
          tableDirName = "M_AttributeSetInstance";
        else if (fields.reference.equals("800011"))
          tableDirName = "M_Product";
        else if (fields.name.equalsIgnoreCase("C_SETTLEMENT_CANCEL_ID"))
          tableDirName = "C_Settlement";
        else if (fields.name.equalsIgnoreCase("SUBSTITUTE_ID"))
          tableDirName = "M_Product";
        else
          tableDirName = fields.name.substring(0, ilength - 3);
        if (fields.reference.equals("25"))
          fieldId = "C_ValidCombination_ID";
        else if (fields.reference.equals("31"))
          fieldId = "M_Locator_ID";
        else if (fields.reference.equals("35"))
          fieldId = "M_AttributeSetInstance_ID";
        else if (fields.reference.equals("800011"))
          fieldId = "M_Product_ID";
        else if (fields.name.equalsIgnoreCase("C_SETTLEMENT_CANCEL_ID"))
          fieldId = "C_Settlement_ID";
        else if (fields.name.equalsIgnoreCase("SUBSTITUTE_ID"))
          fieldId = "M_Product_ID";
        else
          fieldId = fields.name;
      } else {
        tableDirName = dataSearchs[0].reference;
        fieldId = dataSearchs[0].columnname;
      }
      FieldsData fdi[] = FieldsData.identifierColumns(conn, tableDirName);
      if (tableName != null && tableName.length() != 0) {
        StringBuffer fieldsAux = new StringBuffer();
        for (int i = 0; i < fdi.length; i++) {
          if (!fdi[i].name.equalsIgnoreCase(fieldId))
            fieldsAux.append(", ").append(fdi[i].name);
        }
        vecTable.addElement("left join (select " + fieldId + fieldsAux.toString() + " from "
            + tableDirName + ") table" + itable + " on (" + tableName + "." + fields.name
            + " = table" + itable + "." + fieldId + ")");
      } else {
        vecTable.addElement(tableDirName + " table" + itable);
      }
      int tableId = itable;
      for (int i = 0; i < fdi.length; i++) {
        if (i > 0)
          texto.append(" || ' - ' || ");
        vecCounters.set(0, Integer.toString(itable));
        vecCounters.set(1, Integer.toString(ilist));
        texto.append(columnIdentifier(conn, "table" + tableId, required, fdi[i], vecCounters,
            translated, vecFields, vecTable, vecWhere, vecParameters, vecTableParameters,
            sqlDateFormat));
        ilist = Integer.valueOf(vecCounters.elementAt(1).toString()).intValue();
        itable = Integer.valueOf(vecCounters.elementAt(0).toString()).intValue();
      }
    } else {
      if (fields.istranslated.equals("Y")
          && TableRelationData.existsTableColumn(conn, fields.tablename + "_TRL", fields.name)) {
        FieldsData fdi[] = FieldsData.tableKeyColumnName(conn, fields.tablename);
        if (fdi == null || fdi.length == 0) {
          vecFields.addElement(applyFormat(
              ((tableName != null && tableName.length() != 0) ? (tableName + ".") : "")
                  + fields.name, fields.reference, sqlDateFormat));
          texto.append(applyFormat(
              ((tableName != null && tableName.length() != 0) ? (tableName + ".") : "")
                  + fields.name, fields.reference, sqlDateFormat));
        } else {
          vecTable.addElement("left join (select " + fdi[0].name + ",AD_Language"
              + (!fdi[0].name.equalsIgnoreCase(fields.name) ? (", " + fields.name) : "") + " from "
              + fields.tablename + "_TRL) tableTRL" + itable + " on (" + tableName + "."
              + fdi[0].name + " = tableTRL" + itable + "." + fdi[0].name + " and tableTRL" + itable
              + ".AD_Language = ?) ");
          vecTableParameters.addElement("<Parameter name=\"paramLanguage\"/>");
          vecFields.addElement(applyFormat("(CASE WHEN tableTRL" + itable + "." + fields.name
              + " IS NULL THEN TO_CHAR(" + tableName + "." + fields.name
              + ") ELSE TO_CHAR(tableTRL" + itable + "." + fields.name + ") END)",
              fields.reference, sqlDateFormat));
          texto.append(applyFormat("(CASE WHEN tableTRL" + itable + "." + fields.name
              + " IS NULL THEN TO_CHAR(" + tableName + "." + fields.name
              + ") ELSE TO_CHAR(tableTRL" + itable + "." + fields.name + ") END)",
              fields.reference, sqlDateFormat));
        }
      } else {
        vecFields
            .addElement(applyFormat(
                ((tableName != null && tableName.length() != 0) ? (tableName + ".") : "")
                    + fields.name, fields.reference, sqlDateFormat));
        texto
            .append(applyFormat(((tableName != null && tableName.length() != 0) ? (tableName + ".")
                : "")
                + fields.name, fields.reference, sqlDateFormat));
      }
    }
    vecCounters.set(0, Integer.toString(itable));
    vecCounters.set(1, Integer.toString(ilist));
    return texto.toString();
  }

  /**
   * Establece el tipo de class que le corresponde a un campo determinado de la edición
   * 
   * @param efd
   *          - Estructura de tipo EditionFieldsData
   * @return Devuelve un String con el parámetro class completo o un String vacío en caso de no
   *         tener class asociado para el campo indicado.
   */
  public static String classRequiredUpdateable(EditionFieldsData efd, boolean isupdateable,
      boolean tabIsReadOnly) {
    StringBuffer htmltext = new StringBuffer();
    String strAux = "";
    try {
      if (isDecimalNumber(efd.reference) || isPriceNumber(efd.reference)
          || isIntegerNumber(efd.reference) || isGeneralNumber(efd.reference)
          || isQtyNumber(efd.reference)) {
        strAux = " number";
      }
      String strType = "dojoValidateValid";
      String classType = "TextBox";
      if (isSelectType(efd.reference)) {
        strType = "Combo";
        classType = "Combo";
      }

      if (efd.required.equals("Y") && !efd.columnname.equalsIgnoreCase("Value")) {
        if (efd.isreadonly.equals("Y") || tabIsReadOnly) {
          htmltext.append(" class=\"").append(strType).append(" required ").append(classType)
              .append("_OneCell_width").append(strAux).append(" readonly\" ");
        } else if (!isupdateable) {
          htmltext.append(" class=\"").append(strType).append(" required ").append(classType)
              .append("_OneCell_width").append(strAux).append(" readonly\" ");
        } else {
          htmltext.append(" class=\"").append(strType).append(" required ").append(classType)
              .append("_OneCell_width").append(strAux).append("\" ");
        }
      } else if (efd.isreadonly.equals("Y") || tabIsReadOnly) {
        htmltext.append(" class=\"").append(strType).append(" ").append(classType).append(
            "_OneCell_width").append(strAux).append(" readonly\" ");
      } else if (!isupdateable) {
        htmltext.append(" class=\"").append(strType).append(" ").append(classType).append(
            "_OneCell_width").append(strAux).append(" readonly\" ");
      } else {
        htmltext.append(" class=\"").append(strType).append(" ").append(classType).append(
            "_OneCell_width").append(strAux).append("\" ");
      }
    } catch (Exception e) {
      return "";
    }
    return htmltext.toString();
  }

  public static String buildSQL(String clause, Vector<Object> vecParameters) {
    StringBuffer where = new StringBuffer();
    if (!clause.equals("")) {
      if (clause.indexOf('@') > -1) {
        where.append(getSQLWadContext(clause, vecParameters));
      } else {
        where.append(clause);
      }
    }
    return where.toString();
  }

  public static String columnRelationType(String reference) {
    if (isDateField(reference))
      return "DATE";
    else if (isTimeField(reference))
      return "TIME";
    else if (isDateTimeField(reference))
      return "DATETIME";
    else if (reference.equals("20"))
      return "YN";
    else if (isDecimalNumber(reference))
      return "DECIMAL";
    else if (isQtyNumber(reference))
      return "DECIMAL";
    else if (isPriceNumber(reference))
      return "DECIMAL";
    else if (isIntegerNumber(reference))
      return "INTEGER";
    else if (isGeneralNumber(reference))
      return "NUMBER";
    else if (reference.equals("32"))
      return "IMAGE";
    else if (isLinkType(reference))
      return "LINK";
    else
      return "TEXT";
  }

  public static boolean columnRelationFormat(FieldsData data, boolean header, int maxColSize)
      throws IOException, ServletException {
    if (data == null)
      return false;
    if (data.reference.equals("28"))
      return false;
    if (maxColSize > 0) {
      if (Integer.valueOf(data.displaylength).intValue() > maxColSize)
        data.displaylength = Integer.toString(maxColSize);
      if (header && data.name.length() > Integer.valueOf(data.displaylength).intValue()) {
        data.name = data.name.substring(0, Integer.valueOf(data.displaylength).intValue());
      }
    }
    return true;
  }

  public static void xmlFormatAttribute(FieldsData data) {
    if (data == null)
      return;
    if (data.isdisplayed.equals("Y")) {
      if (isIntegerNumber(data.reference))
        data.xmlFormat = "INTEGER";
      else if (isDecimalNumber(data.reference))
        data.xmlFormat = "EURO";
      else if (isQtyNumber(data.reference))
        data.xmlFormat = "QTY";
      else if (isPriceNumber(data.reference))
        data.xmlFormat = "PRICE";
      else if (isGeneralNumber(data.reference))
        data.xmlFormat = "GENERALQTY";
      else
        data.xmlFormat = "REPLACECHARACTERS";
    }
  }

  public static String xmlFields(FieldsData fd, String completeName, int maxTextboxLength,
      boolean forcedAttribute, boolean tabIsReadOnly) {
    StringBuffer html = new StringBuffer();
    String strSystemSeparator = System.getProperty("file.separator");

    if (forcedAttribute) {
      html.append("<FIELD ");
      html.append("id=\"" + fd.name + completeName + "\" ");
      html.append("attribute=\"value\"");
      if (isDecimalNumber(fd.reference))
        html.append(" format=\"euroEdition\"");
      else if (isQtyNumber(fd.reference))
        html.append(" format=\"qtyEdition\"");
      else if (isPriceNumber(fd.reference))
        html.append(" format=\"priceEdition\"");
      else if (isIntegerNumber(fd.reference))
        html.append(" format=\"integerEdition\"");
      else if (isGeneralNumber(fd.reference))
        html.append(" format=\"generalQtyEdition\"");
      else
        html.append(" replaceCharacters=\"htmlPreformated\"");
      html.append(">");
      html.append(fd.name + completeName + "</FIELD>");
    } else if (fd.reference.equals("17") || fd.reference.equals("18") || fd.reference.equals("19")) { // List
      html.append(xmlFields(fd, completeName, maxTextboxLength, true, tabIsReadOnly));
      if (fd.isdisplayed.equals("Y")) {
        html.append("\n<SUBREPORT id=\"report" + fd.name + completeName + "\" name=\"report"
            + fd.name + completeName + "\"");
        html.append(" report=\"org" + strSystemSeparator + "openbravo" + strSystemSeparator
            + "erpCommon" + strSystemSeparator + "reference" + strSystemSeparator + "List\">\n");
        html.append("  <ARGUMENT name=\"parameterListSelected\" withId=\"" + fd.name + completeName
            + "\"/>\n");
        html.append("</SUBREPORT>\n");
      }
      if (fd.isreadonly.equals("Y") || !fd.isupdateable.equals("Y") || tabIsReadOnly) {
        html.append("<FIELD ");
        html.append("id=\"report" + fd.name + completeName + "_S\" ");
        html.append(" attribute=\"onchange\" replace=\"xx\"");
        html.append(">");
        html.append(fd.name + completeName + "</FIELD>");
      }
    } else if (fd.reference.equals("32")) { // Image
      html.append(xmlFields(fd, "", maxTextboxLength, true, tabIsReadOnly));
      if (fd.isdisplayed.equals("Y")) {
        html.append("<FIELD id=\"" + fd.name + completeName + "\" name=\"" + fd.name + completeName
            + "\" attribute=\"src\" replace=\"xx\">");
        html.append(fd.name).append(completeName);
        html.append("</FIELD>");
      }
    } else if (isLinkType(fd.reference)) {
      html.append("<FIELD ");
      html.append("id=\"" + fd.name + completeName + "\" ");
      html.append("attribute=\"value\"");
      html.append(" replaceCharacters=\"htmlPreformated\"");
      html.append(">");
      html.append(fd.name + completeName + "</FIELD>");
    } else if (fd.reference.equals("20") && fd.isdisplayed.equals("Y")) { // YesNo
      html.append("<FIELD ");
      html.append("id=\"" + fd.name + completeName + "\" ");
      html.append("boolean=\"checked\" withId=\"paramCheck\"");
      html.append(">");
      html.append(fd.name + completeName + "</FIELD>");
    } else if (fd.reference.equals("28") && fd.isdisplayed.equals("Y")
        && !fd.referencevalue.equals("") && !fd.columnname.equals("ChangeProjectStatus")) { // Button
      html.append("<FIELD ");
      html.append("id=\"" + fd.name + completeName + "\" ");
      html.append("replaceCharacters=\"htmlPreformated\" ");
      html.append(" attribute=\"value\">");
      html.append(fd.name + completeName + "</FIELD>");
      html.append("<FIELD ");
      html.append("replaceCharacters=\"htmlPreformated\" ");
      html.append("id=\"" + fd.name + completeName + "_BTN\">");
      html.append(fd.name + completeName + "_BTN</FIELD>");
    } else if (Integer.valueOf(fd.fieldlength).intValue() > maxTextboxLength
        && fd.isdisplayed.equals("Y")) {
      html.append("<FIELD ");
      html.append("id=\"" + fd.name + completeName + "\" ");
      if (isDecimalNumber(fd.reference))
        html.append(" format=\"euroEdition\"");
      else if (isQtyNumber(fd.reference))
        html.append(" format=\"qtyEdition\"");
      else if (isPriceNumber(fd.reference))
        html.append(" format=\"priceEdition\"");
      else if (isIntegerNumber(fd.reference))
        html.append(" format=\"integerEdition\"");
      else if (isGeneralNumber(fd.reference))
        html.append(" format=\"generalQtyEdition\"");
      else
        html.append(" replaceCharacters=\"htmlPreformatedTextarea\"");
      html.append(">");
      html.append(fd.name + completeName + "</FIELD>");
    } else {
      html.append("<FIELD ");
      html.append("id=\"" + fd.name + completeName + "\" ");
      html.append("attribute=\"value\"");
      if (isDecimalNumber(fd.reference))
        html.append(" format=\"euroEdition\"");
      else if (isQtyNumber(fd.reference))
        html.append(" format=\"qtyEdition\"");
      else if (isPriceNumber(fd.reference))
        html.append(" format=\"priceEdition\"");
      else if (isIntegerNumber(fd.reference))
        html.append(" format=\"integerEdition\"");
      else if (isGeneralNumber(fd.reference))
        html.append(" format=\"generalQtyEdition\"");
      else
        html.append(" replaceCharacters=\"htmlPreformated\"");
      html.append(">");
      html.append(fd.name + completeName + "</FIELD>");
    }

    return html.toString();
  }

  public static String htmlFields(EditionFieldsData efd, String completeName, String completeID,
      boolean isupdateable, int maxTextboxLength, boolean forcedAttribute, boolean isdesigne,
      Vector<Object> vecCallOuts, String tabName, Vector<Object> vecDisplayLogic,
      Vector<Object> vecReloads, boolean tabIsReadOnly, int textareaLength) {
    StringBuffer html = new StringBuffer();
    String onChange = ((isInVector(vecDisplayLogic, efd.columnname) && !tabIsReadOnly) ? "displayLogic();"
        : "");
    String logChanges = "logChanges(this);";
    if (vecReloads != null && vecReloads.size() > 0 && efd.calloutname.equals("") && !tabIsReadOnly
        && isInVector(vecReloads, efd.columnname)) {
      efd.calloutname = "ComboReloads" + efd.tabid;
      onChange += callouts(efd, vecCallOuts, maxTextboxLength, true);
      // efd.callout="";
    }
    if (!forcedAttribute && efd.isdisplayed.equals("Y") && !efd.displaylogic.equals("")) {
      html.append("<span id=\"" + efd.columnname + "_inp\">");
    }
    if (forcedAttribute) {
      html.append("<input type=\"hidden\"");
      html.append(" name=\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp) + completeName);
      html.append("\" id=\"" + efd.columnname + completeID + "\" value=\"");
      if (!isdesigne)
        html.append("xxV");
      if (isDecimalNumber(efd.reference) || isPriceNumber(efd.reference)
          || isGeneralNumber(efd.reference) || isQtyNumber(efd.reference))
        html.append("\" onkeydown=\"autoCompleteNumber(this, true, true, event);return true;");
      else if (isIntegerNumber(efd.reference))
        html.append("\" onkeydown=\"autoCompleteNumber(this, false, true, event);return true;");
      html.append("\"");
      html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
      html.append(" ></input>");
    } else if ((efd.reference.equals("17") || efd.reference.equals("18") || efd.reference
        .equals("19"))
        && efd.isdisplayed.equals("Y")) { // List or Table or TableDir
      StringBuffer html1 = new StringBuffer();
      html.append("<select name=\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
          + completeName + "\"");
      onChange = callouts(efd, vecCallOuts, maxTextboxLength) + onChange;
      // if (efd.isparent.equals("Y") || !isupdateable || tabIsReadOnly) {
      if (log4j.isDebugEnabled())
        log4j.debug("column: " + efd.columnname + "isUpdateable: " + isupdateable
            + " tabReadOnly: " + tabIsReadOnly + " isUpdateable field: " + efd.isupdateable);
      if (!isupdateable || tabIsReadOnly) {
        html.append(" readonly=\"true\"");
        onChange = "selectCombo(this, 'xx');";
      }
      html.append(" onchange=\"").append(logChanges).append(onChange).append("return true;\"");
      html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
      html.append(" id=\"report");
      html.append(efd.columnname + completeID + "_S\"");
      html.append(">");
      if (!efd.required.equals("Y"))
        html.append("<option value=\"\"></option>");
      html.append("<div id=\"report");
      html.append(efd.columnname + completeID + "\"></div>");
      html.append("</select>");
      html.append(html1);
    } else if (efd.reference.equals("23")) {
      html.append("<input type=\"file\" ");
      html.append(" size=\"" + efd.displaysize + "\" ");
      html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
      html.append(" name=\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp) + completeName);
      html.append("\" id=\"" + efd.columnname + completeID + "\" ");
      html.append("value=\"");
      if (!isdesigne)
        html.append("xxV");
      html.append("\"");
      if (!tabIsReadOnly)
        onChange = callouts(efd, vecCallOuts, maxTextboxLength) + onChange;
      if (!onChange.equals(""))
        onChange = onChange + "return true;";
      html.append(" onchange=\"").append(logChanges).append(onChange).append("\"");
      if (!isupdateable || tabIsReadOnly) {
        html.append(" readonly=\"true\"");
      }
      html.append("></input>");
    } else if (efd.reference.equals("32")) {
      if (!tabIsReadOnly && isupdateable) {
        html.append("<a href=\"#\" onclick=\"");
        html.append("openSearch(null, null, '../info/ImageInfo.html', null, false, 'frmMain', 'inp"
            + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "', 'inp"
            + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "_R', document.frmMain.inp"
            + Sqlc.TransformaNombreColumna(efd.columnnameinp) + ".value);");
        html.append("return false;\" onmouseover=\"window.status='").append(efd.referenceName)
            .append("';return true;\" onmouseout=\"window.status='';return true;\">");
      }
      html.append("<img src=\"../../../../../web/images/xx\" border=\"0\"");
      html.append(" width=\"").append(
          (efd.displaysize.equals("") || IMAGE_EDITION_WIDTH < Integer.valueOf(efd.displaysize)
              .intValue()) ? Integer.toString(IMAGE_EDITION_WIDTH) : efd.displaysize).append("\"");
      html.append(" height=\"").append(
          (efd.displaysize.equals("") || IMAGE_EDITION_HEIGHT < Integer.valueOf(efd.displaysize)
              .intValue()) ? Integer.toString(IMAGE_EDITION_HEIGHT) : efd.displaysize)
          .append("\" ");
      html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
      html.append(" name=\"inp").append(Sqlc.TransformaNombreColumna(efd.columnnameinp)).append(
          completeName);
      html.append("\" id=\"").append(efd.columnname).append(completeID).append("\" alt=\"").append(
          efd.name).append("\" title=\"").append(efd.name).append("\"");
      if (!tabIsReadOnly)
        onChange = callouts(efd, vecCallOuts, maxTextboxLength) + onChange;
      if (!onChange.equals(""))
        onChange = onChange + "return true;";
      html.append(" onchange=\"").append(logChanges).append(onChange).append("\"");
      if (!isupdateable || tabIsReadOnly) {
        html.append(" readonly=\"true\"");
      }
      html.append("></img>");
      if (!tabIsReadOnly && isupdateable) {
        html.append("</a>");
      }
    } else if (efd.reference.equals("34") && efd.isdisplayed.equals("Y")) { // MEMO
      StringBuffer html1 = new StringBuffer();
      double rowLength = ((Integer.valueOf(efd.fieldlength).intValue() * 20) / 4000);
      if (rowLength < 3.0)
        rowLength = 3.0;
      html.append("<textarea cols=\"").append(textareaLength).append("\" rows=\"").append(
          Double.toString(rowLength)).append("\" name=\"inp").append(
          Sqlc.TransformaNombreColumna(efd.columnnameinp));
      html.append(completeName).append("\" id=\"").append(efd.columnname).append(completeID)
          .append("\" ");
      onChange = callouts(efd, vecCallOuts, maxTextboxLength) + onChange;
      html.append(" onclick=\"").append(logChanges).append(onChange).append("return true;\"");
      html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
      if (!isupdateable || tabIsReadOnly) {
        html.append(" readonly=\"true\"");
      }
      html.append(" onkeypress=\"return handleFieldMaxLength(this, ").append(efd.fieldlength)
          .append(");").append("\"");
      html.append(">");
      if (!isdesigne)
        html.append("xxV");
      html.append("</textarea>");
      html.append(html1);
    } else if (isLinkType(efd.reference)) {
      html.append("<input type=\"text\" name=\"inp").append(
          Sqlc.TransformaNombreColumna(efd.columnnameinp));
      html.append(completeName).append("\" id=\"").append(efd.columnname).append(completeID)
          .append("\" ");
      onChange = callouts(efd, vecCallOuts, maxTextboxLength) + onChange;
      html.append(" onchange=\"").append(logChanges).append(onChange).append("return true;\"");
      html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
      if (!isupdateable || tabIsReadOnly) {
        html.append(" readonly=\"true\"");
      }
      html.append(" size=\"").append(efd.displaysize).append("\" ");
      html.append(" maxlength=\"").append(efd.fieldlength).append("\" ");
      html.append("value=\"");
      if (!isdesigne)
        html.append("xxV");
      html.append("\">");
    } else if (!efd.reference.equals("20")
        && (Integer.valueOf(efd.fieldlength).intValue() > maxTextboxLength)
        && efd.isdisplayed.equals("Y")) { // TEXTAREA
      StringBuffer html1 = new StringBuffer();
      double rowLength = ((Integer.valueOf(efd.fieldlength).intValue() * 20) / 4000);
      if (rowLength < 3.0)
        rowLength = 3.0;
      html.append("<textarea cols=\"").append(textareaLength).append("\" rows=\"").append(
          Double.toString(rowLength)).append("\" name=\"inp").append(
          Sqlc.TransformaNombreColumna(efd.columnnameinp));
      html.append(completeName).append("\" id=\"").append(efd.columnname).append(completeID)
          .append("\" ");
      onChange = callouts(efd, vecCallOuts, maxTextboxLength) + onChange;
      html.append(" onclick=\"").append(logChanges).append(onChange).append("return true;\"");
      html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
      if (!isupdateable || tabIsReadOnly) {
        html.append(" readonly=\"true\"");
      }
      html.append(" onkeypress=\"return handleFieldMaxLength(this, ").append(efd.fieldlength)
          .append(");").append("\"");
      html.append(">");
      if (!isdesigne)
        html.append("xxV");
      html.append("</textarea>");
      html.append(html1);
    } else if (efd.reference.equals("28") && efd.isdisplayed.equals("Y")) {
      html
          .append("<table border=\"1\" cellpadding=\"0\" cellspacing=\"0\" summary=\"\" class=\"ActionButton\" onClick=\"");
      html.append(buttonsCommand(efd, tabName + "_Edition.html") + "\">");
      html.append("<tr class=\"ActionButton\"><td>");
      html
          .append("<img src=\"../../../../../web/images/ButtonProcess.gif\" border=\"0\" height=\"25\" width=\"25\" id=\"buttonProcess\"></td>");
      html.append("<td class=\"Medio\">");
      html.append(htmlFields(efd, completeName, completeID, isupdateable, maxTextboxLength, true,
          isdesigne, vecCallOuts, tabName, vecDisplayLogic, vecReloads, tabIsReadOnly,
          textareaLength));
      html.append("<span id=\"" + efd.columnname + completeID + "_BTN\">");
      html
          .append((efd.referencevalue.equals("") || efd.columnname.equals("ChangeProjectStatus")) ? efd.name
              : "xx");
      html.append("</span>&nbsp;</td>");
      html.append("</tr></table>");
    } else {
      StringBuffer html1 = new StringBuffer();
      html.append("<input type=\"");
      if (efd.isdisplayed.equals("N")) {
        html.append("hidden\"");
      } else if (efd.reference.equals("20")) { // YesNo
        html.append("checkbox\"");
      } else {
        if (efd.isencrypted.equals("Y") || efd.iscolumnencrypted.equals("Y"))
          html.append("password\"");
        else
          html.append("text\"");
        if (isDecimalNumber(efd.reference) || isPriceNumber(efd.reference)
            || isGeneralNumber(efd.reference) || isQtyNumber(efd.reference))
          html.append(" onkeydown=\"autoCompleteNumber(this, true, true, event);return true;\"");
        else if (isIntegerNumber(efd.reference))
          html.append(" onkeydown=\"autoCompleteNumber(this, false, true, event);return true;\"");
        html.append(" size=\"" + efd.displaysize + "\" ");
        html.append(classRequiredUpdateable(efd, isupdateable, tabIsReadOnly));
        if (!isSearchType(efd.reference))
          html.append(" maxlength=\"" + efd.fieldlength + "\"");
      }
      html.append(" name=\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp) + completeName);
      html.append("\" id=\"" + efd.columnname + completeID + "\" ");
      html.append("value=\"");
      if (efd.isdisplayed.equals("N")) {
        if (!isdesigne)
          html.append("xxV");
      } else if (efd.reference.equals("20")) {
        html.append("Y");
      } else {
        if (!isdesigne)
          html.append("xxV");
      }
      html.append("\"");
      if (!tabIsReadOnly)
        onChange = callouts(efd, vecCallOuts, maxTextboxLength) + onChange;
      onChange = logChanges + onChange + "return true;";

      if (efd.reference.equals("14")
          && Integer.valueOf(efd.fieldlength).intValue() > maxTextboxLength) {
        html.append((!onChange.equals("") ? (" onblur=\"" + onChange + "\"") : ""));
      } else if (efd.reference.equals("20")) {
        if (!isupdateable || tabIsReadOnly)
          onChange = "return false;";
        html.append((!onChange.equals("") ? (" onclick=\"" + onChange + "\"") : ""));
      } else {
        html.append((!onChange.equals("") ? (" onchange=\"" + onChange + "\"") : ""));
      }
      if (efd.isdisplayed.equals("Y") && isupdateable
          && (isDateField(efd.reference) || isTimeField(efd.reference))) { // Date.
        // Put
        // a
        // calendar
        html.append(" onkeyup=\"auto_completar_");
        if (isDateField(efd.reference))
          html.append("fecha(this");
        else
          html.append("hora(this, true");
        html.append(");return true;\"");
      }
      if (!isupdateable || tabIsReadOnly) {
        html.append(" readonly=\"true\"");
      }
      html.append("></input>");
      html.append(html1);
    }

    if (!forcedAttribute && efd.isdisplayed.equals("Y") && !efd.displaylogic.equals("")) {
      html.append("</span>");
    }

    return html.toString();
  }

  public static void setLabel(ConnectionProvider conn, WADControl auxControl, boolean isSOTrx,
      String keyName) throws ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("processing WadUtility.setLabel() - field name: " + auxControl.getData("Name"));
    String strTableID = "", strColumnName = "", strTableName = "";
    if (auxControl.getData("AD_Reference_ID").equals("18")) {
      strTableID = TableLinkData.tableId(conn, auxControl.getData("AD_Reference_Value_ID"));
      strColumnName = TableLinkData.columnName(conn, auxControl.getData("AD_Reference_Value_ID"));
    } else if (auxControl.getData("AD_Reference_ID").equals("19")
        || auxControl.getData("AD_Reference_ID").equals("30")
        || auxControl.getData("AD_Reference_ID").equals("800011")) {
      EditionFieldsData[] dataSearchs = null;
      if (auxControl.getData("AD_Reference_ID").equals("30"))
        dataSearchs = EditionFieldsData.selectSearchs(conn, "", auxControl
            .getData("AD_Reference_Value_ID"));
      if (auxControl.getData("AD_Reference_ID").equals("800011")) {
        strTableName = "M_Product";
        strColumnName = TableLinkData.keyColumnName(conn, strTableName);
      } else if (dataSearchs != null && dataSearchs.length != 0) {
        strTableName = dataSearchs[0].reference;
        strColumnName = dataSearchs[0].columnname;
      } else {
        strTableName = auxControl.getData("ColumnNameSearch");
        strTableName = strTableName.substring(0, (strTableName.length() - 3));
        strColumnName = TableLinkData.keyColumnName(conn, strTableName);
      }
      strTableID = TableLinkData.tableNameId(conn, strTableName);
    } else {
      auxControl.setData("IsLinkable", "N");
      return;
    }

    if ((strTableID.equals("") || strColumnName.equals(""))
        && !(auxControl.getData("ColumnName").equalsIgnoreCase("updatedBy") || auxControl.getData(
            "ColumnName").equalsIgnoreCase("createdBy"))) {
      log4j.warn("There're no table name or column name for: " + auxControl.getData("ColumnName")
          + " - TABLE_NAME: " + strTableName + " - COLUMN_NAME: " + strColumnName);
    }

    TableLinkData[] data1 = TableLinkData.selectWindow(conn, strTableID);
    if (data1 == null || data1.length == 0) {
      auxControl.setData("IsLinkable", "N");
      return;
    }

    String strWindowId = data1[0].adWindowId;
    if (!isSOTrx && !data1[0].poWindowId.equals(""))
      strWindowId = data1[0].poWindowId;
    TableLinkData[] data = TableLinkData.select(conn, strWindowId, strTableID);
    if (data == null || data.length == 0) {
    //System.out.println("__________xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" + strTableID + "-"+strColumnName+"-"+strTableName + "-" + strWindowId + "-" + auxControl.getData("ColumnName"));
      auxControl.setData("IsLinkable", "N");
      return;
    }

    auxControl.setData("IsLinkable", "Y");
    auxControl.setData("ColumnNameLabel", strColumnName);
    auxControl.setData("KeyColumnName", keyName);
    auxControl.setData("AD_Table_ID", strTableID);
    auxControl.setData("ColumnLabelText", strColumnName);
  }

  public static void comboReloadScript(EditionFieldsData efd, Vector<Object> vecCallOuts,
      Vector<Object> vecReloads, int maxTextboxLength, String strTab) {
    if (vecReloads == null)
      return;
    if (isInVector(vecReloads, efd.columnnameinp)) {
      if (efd.isdisplayed.equals("Y")
          && (efd.reference.equals("21") || efd.reference.equals("30")
              || efd.reference.equals("31") || efd.reference.equals("35")
              || efd.reference.equals("25") || efd.reference.equals("800011"))
          && efd.calloutname.equals("")) {
        efd.calloutname = "ComboReloads" + strTab;
        callouts(efd, vecCallOuts, maxTextboxLength, true);
      }
    }
  }

  public static String callouts(EditionFieldsData efd, Vector<Object> vecCallOuts,
      int maxTextboxLength) {
    return callouts(efd, vecCallOuts, maxTextboxLength, false);
  }

  public static String callouts(EditionFieldsData efd, Vector<Object> vecCallOuts,
      int maxTextboxLength, boolean isReload) {
    StringBuffer html = new StringBuffer();
    boolean existCallOut = false;
    if (!efd.calloutname.equals("")) {
      if (efd.calloutname.startsWith("ComboReload"))
        isReload = true;
      String calloutName = FormatUtilities.replace(efd.calloutname);
      if (efd.reference.equals("30") || efd.reference.equals("31") || efd.reference.equals("35")
          || efd.reference.equals("25") || efd.reference.equals("800011")) {
        boolean existDebug = false;
        int i;
        for (i = 0; i < vecCallOuts.size(); i++) {
          CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
          if (data.name.equals("debugSearch")) {
            existDebug = true;
            break;
          }
        }
        StringBuffer script = new StringBuffer();
        if (existDebug) {
          script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
              + "\") {\n");
          /*
           * if (isReload) { script.append("    submitCommandForm('" + efd.columnname +
           * "', false, null, '../ad_callouts/ComboReloads' + document.frmMain.inpTabId.value + '.html', 'hiddenFrame');"
           * ); }
           */
          script.append("    " + (isReload ? "reload" : "callout") + calloutName + "(keyField);\n");
          script.append("  }\n");
          CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
          if (data.method.indexOf(script.toString()) == -1) {
            StringBuffer complete = new StringBuffer();
            String header = "function debugSearch(key, text, keyField) {\n";
            int init = data.method.indexOf(header);
            complete.append(data.method.substring(0, init + header.length()));
            complete.append(script.toString());
            complete.append(data.method.substring(init + header.length(), data.method.length()));
            CallOutsStructure data1 = new CallOutsStructure();
            data1.name = "debugSearch";
            data1.method = complete.toString();
            vecCallOuts.remove(i);
            vecCallOuts.addElement(data1);
          }
        } else {
          script.append("\nfunction debugSearch(key, text, keyField) {\n");
          script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
              + "\") {\n");
          script.append("    " + (isReload ? "reload" : "callout") + calloutName + "(keyField);\n");
          script.append("  }\n");
          script.append("return true;\n}");
          CallOutsStructure data = new CallOutsStructure();
          data.name = "debugSearch";
          data.method = script.toString();
          vecCallOuts.addElement(data);
        }
      } else {
        if (isDateField(efd.reference)) { // Calendar
          boolean existDebug = false;
          int i;
          for (i = 0; i < vecCallOuts.size(); i++) {
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.name.equals("debugCalendar")) {
              existDebug = true;
              break;
            }
          }
          StringBuffer script = new StringBuffer();
          if (existDebug) {
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.method.indexOf(script.toString()) == -1) {
              StringBuffer complete = new StringBuffer();
              String header = "function debugCalendar(date, keyField) {\n";
              int init = data.method.indexOf(header);
              complete.append(data.method.substring(0, init + header.length()));
              complete.append(script.toString());
              complete.append(data.method.substring(init + header.length(), data.method.length()));
              CallOutsStructure data1 = new CallOutsStructure();
              data1.name = "debugCalendar";
              data1.method = complete.toString();
              vecCallOuts.remove(i);
              vecCallOuts.addElement(data1);
            }
          } else {
            script.append("\nfunction debugCalendar(date, keyField) {\n");
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            script.append("return true;\n}");
            CallOutsStructure data = new CallOutsStructure();
            data.name = "debugCalendar";
            data.method = script.toString();
            vecCallOuts.addElement(data);
          }
        } else if (isTimeField(efd.reference)) { // Clock
          boolean existDebug = false;
          int i;
          for (i = 0; i < vecCallOuts.size(); i++) {
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.name.equals("debugClock")) {
              existDebug = true;
              break;
            }
          }
          StringBuffer script = new StringBuffer();
          if (existDebug) {
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.method.indexOf(script.toString()) == -1) {
              StringBuffer complete = new StringBuffer();
              String header = "function debugClock(time, keyField) {\n";
              int init = data.method.indexOf(header);
              complete.append(data.method.substring(0, init + header.length()));
              complete.append(script.toString());
              complete.append(data.method.substring(init + header.length(), data.method.length()));
              CallOutsStructure data1 = new CallOutsStructure();
              data1.name = "debugClock";
              data1.method = complete.toString();
              vecCallOuts.remove(i);
              vecCallOuts.addElement(data1);
            }
          } else {
            script.append("\nfunction debugClock(time, keyField) {\n");
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            script.append("return true;\n}");
            CallOutsStructure data = new CallOutsStructure();
            data.name = "debugClock";
            data.method = script.toString();
            vecCallOuts.addElement(data);
          }
        } else if (isDecimalNumber(efd.reference) || isPriceNumber(efd.reference)
            || isIntegerNumber(efd.reference) || isGeneralNumber(efd.reference)
            || isQtyNumber(efd.reference)) { // Calculator
          boolean existDebug = false;
          int i;
          for (i = 0; i < vecCallOuts.size(); i++) {
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.name.equals("debugCalculator")) {
              existDebug = true;
              break;
            }
          }
          StringBuffer script = new StringBuffer();
          if (existDebug) {
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.method.indexOf(script.toString()) == -1) {
              StringBuffer complete = new StringBuffer();
              String header = "function debugCalculator(num, keyField) {\n";
              int init = data.method.indexOf(header);
              complete.append(data.method.substring(0, init + header.length()));
              complete.append(script.toString());
              complete.append(data.method.substring(init + header.length(), data.method.length()));
              CallOutsStructure data1 = new CallOutsStructure();
              data1.name = "debugCalculator";
              data1.method = complete.toString();
              vecCallOuts.remove(i);
              vecCallOuts.addElement(data1);
            }
          } else {
            script.append("\nfunction debugCalculator(num, keyField) {\n");
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            script.append("return true;\n}");
            CallOutsStructure data = new CallOutsStructure();
            data.name = "debugCalculator";
            data.method = script.toString();
            vecCallOuts.addElement(data);
          }
        } else if (isLikeType(efd.reference)) { // Keyboard
          boolean existDebug = false;
          int i;
          for (i = 0; i < vecCallOuts.size(); i++) {
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.name.equals("debugKeyboard")) {
              existDebug = true;
              break;
            }
          }
          StringBuffer script = new StringBuffer();
          if (existDebug) {
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
            if (data.method.indexOf(script.toString()) == -1) {
              StringBuffer complete = new StringBuffer();
              String header = "function debugKeyboard(text, keyField) {\n";
              int init = data.method.indexOf(header);
              complete.append(data.method.substring(0, init + header.length()));
              complete.append(script.toString());
              complete.append(data.method.substring(init + header.length(), data.method.length()));
              CallOutsStructure data1 = new CallOutsStructure();
              data1.name = "debugKeyboard";
              data1.method = complete.toString();
              vecCallOuts.remove(i);
              vecCallOuts.addElement(data1);
            }
          } else {
            script.append("\nfunction debugKeyboard(text, keyField) {\n");
            script.append("  if (keyField==\"inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "\") {\n");
            script.append("    " + (isReload ? "reload" : "callout") + calloutName
                + "(keyField);\n");
            script.append("  }\n");
            script.append("return true;\n}");
            CallOutsStructure data = new CallOutsStructure();
            data.name = "debugKeyboard";
            data.method = script.toString();
            vecCallOuts.addElement(data);
          }
        }
        html.append((isReload ? "reload" : "callout") + calloutName + "(this.name);");
      }

      for (int i = 0; i < vecCallOuts.size(); i++) {
        CallOutsStructure data = (CallOutsStructure) vecCallOuts.elementAt(i);
        if (data.name.equals(calloutName)) {
          existCallOut = true;
          break;
        }
      }
      if (!existCallOut) {
        StringBuffer strCallOut = new StringBuffer();
        if (isReload) {
          strCallOut.append("\nfunction reload" + calloutName + "(changedField) {\n");
          strCallOut
              .append("    submitCommandForm(changedField, false, null, '../ad_callouts/ComboReloads' + document.frmMain.inpTabId.value + '.html', 'hiddenFrame', null, null, true);\n");
        } else {
          strCallOut.append("\nfunction callout" + calloutName + "(changedField) {\n");
          strCallOut
              .append(
                  "submitCommandFormParameter('DEFAULT', frmMain.inpLastFieldChanged, changedField, false, null, '..")
              .append(efd.mappingnameCallout).append("', 'hiddenFrame', null, null, true);\n");
        }
        strCallOut.append("return true;\n");
        strCallOut.append("}\n");
        CallOutsStructure data = new CallOutsStructure();
        data.name = efd.calloutname;
        data.method = strCallOut.toString();
        vecCallOuts.addElement(data);
      }
    }
    return html.toString();
  }

  public static String findField(ConnectionProvider conn, EditionFieldsData[] fields,
      EditionFieldsData[] auxiliars, String fieldName) {
    if (fields == null)
      return "";
    for (int i = 0; i < fields.length; i++)
      if (fields[i].columnname.equalsIgnoreCase(fieldName))
        return fields[i].columnnameinp;
    if (auxiliars == null)
      return "";
    for (int i = 0; i < auxiliars.length; i++)
      if (auxiliars[i].columnname.equalsIgnoreCase(fieldName))
        return auxiliars[i].columnnameinp;
    return "";
  }

  public static String searchsCommand(EditionFieldsData efd, boolean fromButton, String tabId,
      ConnectionProvider conn, String windowId, EditionFieldsData[] fieldsData,
      EditionFieldsData[] auxiliarsData) {
    StringBuffer params = new StringBuffer();
    StringBuffer html = new StringBuffer();
    String strMethodName = "openSearch";
    if (!fromButton) {
      params.append(", 'Command'");
      params.append(", 'KEY'");
    }
    params.append(", 'WindowID'");
    params.append(", '" + windowId + "'");
    String field = findField(conn, fieldsData, auxiliarsData, "issotrxtab");
    if (!field.equals("")) {
      params.append(", 'inpisSOTrxTab'");
      params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
    }
    String searchName = (efd.reference.equals("25") ? "/info/Account" : ("/info/" + FormatUtilities
        .replace(efd.searchname.trim())))
        + "_FS.html";
    EditionFieldsData[] fieldsSearch = null;
    try {
      fieldsSearch = EditionFieldsData.selectSearchs(conn, "I", efd.referencevalue);
    } catch (ServletException ex) {
      ex.printStackTrace();
    }
    if (fieldsSearch != null && fieldsSearch.length > 0) {
      searchName = fieldsSearch[0].mappingname;
      if (!fieldsSearch[0].referencevalue.equals("")) {
        for (int i = 0; i < fieldsSearch.length; i++) {
          field = findField(conn, fieldsData, auxiliarsData, fieldsSearch[i].referencevalue);
          if (!field.equals("")) {
            params.append(", 'inp").append(fieldsSearch[i].columnnameinp).append("'");
            params
                .append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
          }
        }
      }
    } else if (efd.searchname.equalsIgnoreCase("PRODUCT COMPLETE")) {
      field = findField(conn, fieldsData, auxiliarsData, "m_warehouse_id");
      if (!field.equals("")) {
        params.append(", 'inpWarehouse'");
        params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
      }
      field = findField(conn, fieldsData, auxiliarsData, "c_bpartner_id");
      if (!field.equals("")) {
        params.append(", 'inpBPartner'");
        params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
      }
    } else if (efd.searchname.toUpperCase().startsWith("ATTRIBUTE")) {
      strMethodName = "openPAttribute";
      params.append(", 'inpKeyValue'");
      params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp)
          + ".value");
      params.append(", 'inpwindowId'");
      params.append(", document.frmMain.inpwindowId.value");
      field = findField(conn, fieldsData, auxiliarsData, "m_product_id");
      if (!field.equals("")) {
        params.append(", 'inpProduct'");
        params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
      }
      field = findField(conn, fieldsData, auxiliarsData, "m_locator_id");
      if (!field.equals("")) {
        params.append(", 'inpLocatorId'");
        params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
      }
    } else if (efd.reference.equals("25")) {
      field = findField(conn, fieldsData, auxiliarsData, "c_acctschema_id");
      if (!field.equals("")) {
        params.append(", 'inpAcctSchema'");
        params.append(", inputValue(document.frmMain.inp" + Sqlc.TransformaNombreColumna(field)
            + ")");
      }
    }
    /*
     * if (efd.searchname.equalsIgnoreCase("PRODUCT")) { field=findField(conn, fieldsData,
     * auxiliarsData, "m_pricelist_id"); if (!field.equals("")) { params.append(", 'inpPriceList'");
     * params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value"); }
     * field=findField(conn, fieldsData, auxiliarsData, "m_warehouse_id"); if (!field.equals("")) {
     * params.append(", 'inpWarehouse'"); params.append(", document.frmMain.inp" +
     * Sqlc.TransformaNombreColumna(field) + ".value"); } field=findField(conn, fieldsData,
     * auxiliarsData, "dateordered"); if (!field.equals("")) { params.append(", 'inpDate'");
     * params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value"); } }
     * else if (efd.searchname.equalsIgnoreCase("PROJECT")) { field=findField(conn, fieldsData,
     * auxiliarsData, "c_bpartner_id"); if (!field.equals("")) { params.append(", 'inpBPartner'");
     * params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value"); } }
     * else if (efd.searchname.equalsIgnoreCase("PRODUCT COMPLETE")) { field=findField(conn,
     * fieldsData, auxiliarsData, "m_warehouse_id"); if (!field.equals("")) {
     * params.append(", 'inpWarehouse'"); params.append(", document.frmMain.inp" +
     * Sqlc.TransformaNombreColumna(field) + ".value"); } field=findField(conn, fieldsData,
     * auxiliarsData, "c_bpartner_id"); if (!field.equals("")) { params.append(", 'inpBPartner'");
     * params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value"); } }
     * else if (efd.searchname.equalsIgnoreCase("SALES ORDER LINE")) { field=findField(conn,
     * fieldsData, auxiliarsData, "c_bpartner_id"); if (!field.equals("")) {
     * params.append(", 'inpBPartner'"); params.append(", document.frmMain.inp" +
     * Sqlc.TransformaNombreColumna(field) + ".value"); } field=findField(conn, fieldsData,
     * auxiliarsData, "m_product_id"); if (!field.equals("")) { params.append(", 'inpProduct'");
     * params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value"); } }
     * else if (efd.searchname.equalsIgnoreCase("SHIPMENT/RECEPIT LINE")) { field=findField(conn,
     * fieldsData, auxiliarsData, "c_bpartner_id"); if (!field.equals("")) {
     * params.append(", 'inpBPartner'"); params.append(", document.frmMain.inp" +
     * Sqlc.TransformaNombreColumna(field) + ".value"); } field=findField(conn, fieldsData,
     * auxiliarsData, "m_product_id"); if (!field.equals("")) { params.append(", 'inpProduct'");
     * params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value"); } }
     * else if (efd.searchname.toUpperCase().startsWith("ATTRIBUTE")) { strMethodName =
     * "openPAttribute"; params.append(", 'inpKeyValue'"); params.append(", document.frmMain.inp" +
     * Sqlc.TransformaNombreColumna(efd.columnnameinp) + ".value");
     * params.append(", 'inpwindowId'"); params.append(", document.frmMain.inpwindowId.value");
     * field=findField(conn, fieldsData, auxiliarsData, "m_product_id"); if (!field.equals("")) {
     * params.append(", 'inpProduct'"); params.append(", document.frmMain.inp" +
     * Sqlc.TransformaNombreColumna(field) + ".value"); } field=findField(conn, fieldsData,
     * auxiliarsData, "m_locator_id"); if (!field.equals("")) { params.append(", 'inpLocatorId'");
     * params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value"); } }
     * else if (efd.reference.equals("25")) { field=findField(conn, fieldsData, auxiliarsData,
     * "c_acctschema_id"); if (!field.equals("")) { params.append(", 'inpAcctSchema'");
     * params.append(", inputValue(document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) +
     * ")"); } }
     */
    html.append(strMethodName + "(null, null, '.." + searchName + "', null, "
        + ((efd.calloutname.equals("")) ? "false" : "true") + ", 'frmMain', 'inp"
        + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "', 'inp"
        + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "_R', document.frmMain.inp"
        + Sqlc.TransformaNombreColumna(efd.columnnameinp)
        + "_R.value, 'inpIDValue', document.frmMain.inp"
        + Sqlc.TransformaNombreColumna(efd.columnnameinp) + ".value" + params.toString() + ");");
    return html.toString();
  }

  public static String productSearch(EditionFieldsData efd, int maxTextboxLength,
      Vector<Object> vecCallOuts, String tabId, ConnectionProvider conn, String windowId,
      EditionFieldsData[] fieldsData, EditionFieldsData[] auxiliarsData) {
    StringBuffer html = new StringBuffer();
    Vector<Object> vec = new Vector<Object>();
    efd.searchname = "Product Complete";
    html.append(htmlFields(efd, "_LOC", "_LOC", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_ATR", "_ATR", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_PQTY", "_PQTY", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_PUOM", "_PUOM", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_QTY", "_QTY", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_UOM", "_UOM", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_PLIST", "_PLIST", true, maxTextboxLength, true, true,
        vecCallOuts, "", vec, null, false, 0));
    html.append(htmlFields(efd, "_PSTD", "_PSTD", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_PLIM", "_PLIM", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    html.append(htmlFields(efd, "_CURR", "_CURR", true, maxTextboxLength, true, true, vecCallOuts,
        "", vec, null, false, 0));
    if (!efd.displaylogic.equals("")) {
      html.append("<span id=\"" + efd.columnname + "_btt\">");
    }
    html.append("<a href=\"#\"");
    html.append("onClick=\""
        + searchsCommand(efd, true, tabId, conn, windowId, fieldsData, auxiliarsData)
        + "return false;\" ");
    html.append("onMouseOut=\"window.status='';return true;\"");
    html.append("onMouseOver=\"window.status='").append(efd.referenceName).append(
        "';return true;\" class=\"windowbutton\"><img alt=\"").append(efd.name).append(
        "\" title=\"").append(efd.name).append("\"");
    html.append(" width=\"").append(IMAGE_BUTTON_WIDTH).append("\" height=\"").append(
        IMAGE_BUTTON_HEIGHT).append("\" ");
    html.append("border=\"0\" src=\"../../../../../web/images/"
        + FormatUtilities.replace(efd.searchname.trim()) + ".jpg\" id=\"button"
        + FormatUtilities.replace(efd.searchname.trim()) + "\"></a>");
    if (!efd.displaylogic.equals("")) {
      html.append("</span>");
    }
    return html.toString();
  }

  public static String searchs(EditionFieldsData efd, int maxTextboxLength,
      Vector<Object> vecCallOuts, String tabId, ConnectionProvider conn, String windowId,
      EditionFieldsData[] fieldsData, EditionFieldsData[] auxiliarsData) {
    StringBuffer html = new StringBuffer();
    Vector<Object> vec = new Vector<Object>();
    EditionFieldsData[] fieldsSearch = null;
    try {
      fieldsSearch = EditionFieldsData.selectSearchs(conn, "O", efd.referencevalue);
    } catch (ServletException ex) {
      ex.printStackTrace();
    }
    if (fieldsSearch != null && fieldsSearch.length > 0) {
      if (!fieldsSearch[0].columnnameinp.equals("")) {
        String columnnameinp = efd.columnnameinp;
        for (int i = 0; i < fieldsSearch.length; i++) {
          efd.columnnameinp = fieldsSearch[i].columnnameinp;
          html.append(htmlFields(efd, fieldsSearch[i].columnnameEnd, fieldsSearch[i].columnnameEnd,
              true, maxTextboxLength, true, true, vecCallOuts, "", vec, null, false, 0));
        }
        efd.columnnameinp = columnnameinp;
      }
    }
    /*
     * if (efd.searchname.toUpperCase().indexOf("BUSINESS")!=-1) { html.append(htmlFields(efd,
     * "_LOC", "_LOC", true, maxTextboxLength, true, true, vecCallOuts, "", vec, null, false, 0));
     * html.append(htmlFields(efd, "_CON", "_CON", true, maxTextboxLength, true, true, vecCallOuts,
     * "", vec, null, false, 0)); } else if (efd.searchname.equalsIgnoreCase("PRODUCT")) {
     * html.append(htmlFields(efd, "_LOC", "_LOC", true, maxTextboxLength, true, true, vecCallOuts,
     * "", vec, null, false, 0)); html.append(htmlFields(efd, "_ATR", "_ATR", true,
     * maxTextboxLength, true, true, vecCallOuts, "", vec, null, false, 0));
     * html.append(htmlFields(efd, "_PQTY", "_PQTY", true, maxTextboxLength, true, true,
     * vecCallOuts, "", vec, null, false, 0)); html.append(htmlFields(efd, "_PUOM", "_PUOM", true,
     * maxTextboxLength, true, true, vecCallOuts, "", vec, null, false, 0));
     * html.append(htmlFields(efd, "_QTY", "_QTY", true, maxTextboxLength, true, true, vecCallOuts,
     * "", vec, null, false, 0)); html.append(htmlFields(efd, "_PLIST", "_PLIST", true,
     * maxTextboxLength, true, true, vecCallOuts, "", vec, null, false, 0));
     * html.append(htmlFields(efd, "_PSTD", "_PSTD", true, maxTextboxLength, true, true,
     * vecCallOuts, "", vec, null, false, 0)); html.append(htmlFields(efd, "_UOM", "_UOM", true,
     * maxTextboxLength, true, true, vecCallOuts, "", vec, null, false, 0));
     * html.append(htmlFields(efd, "_PLIM", "_PLIM", true, maxTextboxLength, true, true,
     * vecCallOuts, "", vec, null, false, 0)); html.append(htmlFields(efd, "_CURR", "_CURR", true,
     * maxTextboxLength, true, true, vecCallOuts, "", vec, null, false, 0)); }
     */
    if (!efd.displaylogic.equals("")) {
      html.append("<span id=\"" + efd.columnname + "_btt\">");
    }
    html.append("<a href=\"#\"");
    html.append("onClick=\""
        + searchsCommand(efd, true, tabId, conn, windowId, fieldsData, auxiliarsData)
        + "return false;\" ");
    html.append("onMouseOut=\"window.status='';return true;\"");
    html.append("onMouseOver=\"window.status='").append(efd.referenceName).append(
        "';return true;\" class=\"windowbutton\"><img alt=\"").append(efd.name).append(
        "\" title=\"").append(efd.name).append("\"");
    html.append(" width=\"").append(IMAGE_BUTTON_WIDTH).append("\" height=\"").append(
        IMAGE_BUTTON_HEIGHT).append("\" ");
    html.append("border=\"0\" src=\"../../../../../web/images/"
        + (efd.reference.equals("25") ? "Account" : FormatUtilities.replace(efd.searchname.trim()))
        + ".jpg\" id=\"button" + FormatUtilities.replace(efd.searchname.trim()) + "\"></a>");
    if (!efd.displaylogic.equals("")) {
      html.append("</span>");
    }
    return html.toString();
  }

  public static String locatorCommands(EditionFieldsData efd, boolean fromButton, String tabId,
      ConnectionProvider conn, String windowId, EditionFieldsData[] fieldsData,
      EditionFieldsData[] auxiliarsData) {
    StringBuffer params = new StringBuffer();
    StringBuffer html = new StringBuffer();
    if (!fromButton) {
      params.append(", 'Command'");
      params.append(", 'KEY'");
    }
    params.append(", 'WindowID'");
    params.append(", '" + windowId + "'");
    String field = findField(conn, fieldsData, auxiliarsData, "m_warehouse_id");
    if (!field.equals("")) {
      params.append(", 'inpmWarehouseId'");
      params.append(", document.frmMain.inp" + Sqlc.TransformaNombreColumna(field) + ".value");
    }
    html.append("openSearch(null, null, '../info/Locator").append(
        (efd.reference.equals("800013") ? "_Detail" : ""))
        .append(
            "_FS.html', null, " + ((efd.calloutname.equals("")) ? "false" : "true")
                + ", 'frmMain', 'inp" + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "', 'inp"
                + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "_R', document.frmMain.inp"
                + Sqlc.TransformaNombreColumna(efd.columnnameinp)
                + "_R.value, 'inpIDValue', document.frmMain.inp"
                + Sqlc.TransformaNombreColumna(efd.columnnameinp) + ".value" + params.toString()
                + ");");
    return html.toString();
  }

  public static String locator(EditionFieldsData efd, int maxTextboxLength,
      Vector<Object> vecCallOuts, String tabId, ConnectionProvider conn, String windowId,
      EditionFieldsData[] fieldsData, EditionFieldsData[] auxiliarsData) {
    StringBuffer html = new StringBuffer();

    if (!efd.displaylogic.equals("")) {
      html.append("<span id=\"" + efd.columnname + "_btt\">");
    }
    html.append("<a href=\"#\"");
    html.append("onClick=\""
        + locatorCommands(efd, true, tabId, conn, windowId, fieldsData, auxiliarsData)
        + "return false;\" ");
    html.append("onMouseOut=\"window.status='';return true;\"");
    html.append("onMouseOver=\"window.status='").append(efd.referenceName).append(
        "';return true;\" class=\"windowbutton\"><img alt=\"").append(efd.name).append(
        "\" title=\"").append(efd.name).append("\"");
    html.append(" width=\"").append(IMAGE_BUTTON_WIDTH).append("\" height=\"").append(
        IMAGE_BUTTON_HEIGHT).append("\" ");
    html
        .append("border=\"0\" src=\"../../../../../web/images/Locator.jpg\" id=\"buttonLocator\"></a>");
    if (!efd.displaylogic.equals("")) {
      html.append("</span>");
    }
    return html.toString();
  }

  public static String locationCommands(EditionFieldsData efd) {
    StringBuffer html = new StringBuffer();

    html.append("openLocation(null, null, '../info/Location_FS.html', null, "
        + ((efd.calloutname.equals("")) ? "false" : "true") + ", 'frmMain', 'inp"
        + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "', 'inp"
        + Sqlc.TransformaNombreColumna(efd.columnnameinp) + "_R', document.frmMain.inp"
        + Sqlc.TransformaNombreColumna(efd.columnnameinp)
        + ".value, 'inpwindowId', document.frmMain.inpwindowId.value);");
    return html.toString();
  }

  public static String location(EditionFieldsData efd) {
    StringBuffer html = new StringBuffer();

    if (!efd.displaylogic.equals("")) {
      html.append("<span id=\"" + efd.columnname + "_btt\">");
    }
    html.append("<a href=\"#\"");
    html.append("onClick=\"" + locationCommands(efd) + "return false;\" ");
    html.append("onMouseOut=\"window.status='';return true;\"");
    html.append("onMouseOver=\"window.status='").append(efd.referenceName).append(
        "';return true;\" class=\"windowbutton\"><img alt=\"").append(efd.name).append(
        "\" title=\"").append(efd.name).append("\"");
    html.append(" width=\"").append(IMAGE_BUTTON_WIDTH).append("\" height=\"").append(
        IMAGE_BUTTON_HEIGHT).append("\" ");
    html
        .append("border=\"0\" src=\"../../../../../web/images/Location.jpg\" id=\"buttonLocation\"></a>");
    if (!efd.displaylogic.equals("")) {
      html.append("</span>");
    }
    return html.toString();
  }

  public static String buttonsCommand(EditionFieldsData efd, String servletName) {
    StringBuffer html = new StringBuffer();
    if (efd.javaClassName.equals("")) {
      html.append("openServletNewWindow('BUTTON" + FormatUtilities.replace(efd.columnname)
          + efd.adProcessId + "', false, '" + servletName + "', 'BUTTON', null, true"
          + (efd.columnname.equalsIgnoreCase("CreateFrom") ? ",600, 900" : "") + ");return false;");
    } else {
      html.append("openServletNewWindow('DEFAULT', false, '.."
          + (efd.javaClassName.startsWith("/") ? "" : "/") + efd.javaClassName + "', 'BUTTON', '"
          + efd.adProcessId + "', true" + ",600, 900" + ");return false;");
    }
    return html.toString();
  }

  public static String getSQLWadContext(String code, Vector<Object> vecParameters) {
    if (code == null || code.trim().equals(""))
      return "";
    String token;
    String strValue = code;
    StringBuffer strOut = new StringBuffer();

    int i = strValue.indexOf("@");
    String strAux, strAux1;
    while (i != -1) {
      if (strValue.length() > (i + 5) && strValue.substring(i + 1, i + 5).equalsIgnoreCase("SQL=")) {
        strValue = strValue.substring(i + 5, strValue.length());
      } else {
        // Delete the chain symbol
        strAux = strValue.substring(0, i).trim();
        if (strAux.substring(strAux.length() - 1).equals("'")) {
          strAux = strAux.substring(0, strAux.length() - 1);
          strOut.append(strAux);
        } else
          strOut.append(strValue.substring(0, i));
        strAux1 = strAux;
        if (strAux.substring(strAux.length() - 1).equals("("))
          strAux = strAux.substring(0, strAux.length() - 1).toUpperCase().trim();
        if (strAux.length() > 3
            && strAux.substring(strAux.length() - 3, strAux.length()).equals(" IN")) {
          strAux = " type=\"replace\" optional=\"true\" after=\"" + strAux1 + "\" text=\"'" + i
              + "'\"";
        } else {
          strAux = "";
        }
        strValue = strValue.substring(i + 1, strValue.length());

        int j = strValue.indexOf("@");
        if (j < 0)
          return "";

        token = strValue.substring(0, j);

        String modifier = ""; // holds the modifier (# or $) for the session value
        if (token.substring(0, 1).indexOf("#") > -1 || token.substring(0, 1).indexOf("$") > -1) {
          modifier = token.substring(0, 1);
          token = token.substring(1, token.length());
        }
        if (strAux.equals(""))
          strOut.append("?");
        else
          strOut.append("'" + i + "'");
        String parameter = "<Parameter name=\"" + token + "\"" + strAux + "/>";
        String paramElement[] = { parameter, modifier };
        vecParameters.addElement(paramElement);
        strValue = strValue.substring(j + 1, strValue.length());
        strAux = strValue.trim();
        if (strAux.length() > 0 && strAux.substring(0, 1).indexOf("'") > -1)
          strValue = strAux.substring(1, strValue.length());
      }
      i = strValue.indexOf("@");
    }
    strOut.append(strValue);
    return strOut.toString();
  }

  public static String getWadContext(String code, Vector<Object> vecFields,
      Vector<Object> vecAuxiliarFields, FieldsData[] parentsFieldsData, boolean isDefaultValue,
      String isSOTrx, String windowId) {
    if (code == null || code.trim().equals(""))
      return "";
    String token;
    String strValue = code;
    StringBuffer strOut = new StringBuffer();

    int i = strValue.indexOf("@");
    String strAux;
    while (i != -1) {
      if (strValue.length() > (i + 5) && strValue.substring(i + 1, i + 5).equalsIgnoreCase("SQL=")) {
        strValue = strValue.substring(i + 5, strValue.length());
      } else {
        strValue = strValue.substring(i + 1, strValue.length());

        int j = strValue.indexOf("@");
        if (j < 0)
          return "";

        token = strValue.substring(0, j);
        strAux = getWadContextTranslate(token, vecFields, vecAuxiliarFields, parentsFieldsData,
            isDefaultValue, isSOTrx, windowId, true);
        if (!strAux.trim().equals("") && strOut.toString().indexOf(strAux) == -1)
          strOut.append(", " + strAux);

        strValue = strValue.substring(j + 1, strValue.length());
      }
      i = strValue.indexOf("@");
    }
    return strOut.toString();
  }

  public static String getWadComboReloadContext(String code, String isSOTrx) {
    if (code == null || code.trim().equals(""))
      return "";
    String token;
    String strValue = code;
    StringBuffer strOut = new StringBuffer();

    int i = strValue.indexOf("@");
    String strAux;
    while (i != -1) {
      if (strValue.length() > (i + 5) && strValue.substring(i + 1, i + 5).equalsIgnoreCase("SQL=")) {
        strValue = strValue.substring(i + 5, strValue.length());
      } else {
        strValue = strValue.substring(i + 1, strValue.length());

        int j = strValue.indexOf("@");
        if (j < 0)
          return "";

        token = strValue.substring(0, j);
        strAux = getWadComboReloadContextTranslate(token, isSOTrx);
        if (!strAux.trim().equals("") && strOut.toString().indexOf(strAux) == -1)
          strOut.append(", " + strAux);

        strValue = strValue.substring(j + 1, strValue.length());
      }
      i = strValue.indexOf("@");
    }
    return strOut.toString();
  }

  public static String getWadComboReloadContextTranslate(String token, String isSOTrx) {
    String result = "";
    if (token.substring(0, 1).indexOf("#") > -1 || token.substring(0, 1).indexOf("$") > -1) {
      if (token.equalsIgnoreCase("#DATE"))
        result = "DateTimeData.today(this)";
      // else result = "vars.getSessionValue(\"" + token + "\")";
      else
        result = "Utility.getContext(this, vars, \"" + token + "\", windowId)";
    } else {
      String aux = Sqlc.TransformaNombreColumna(token);
      if (token.equalsIgnoreCase("ISSOTRX"))
        result = ("\"" + isSOTrx + "\"");
      else
        result = "vars.getStringParameter(\"inp" + aux + "\")";
    }
    return result;
  }

  public static String getTextWadContext(String code, Vector<Object> vecFields,
      Vector<Object> vecAuxiliarFields, FieldsData[] parentsFieldsData, boolean isDefaultValue,
      String isSOTrx, String windowId) {
    if (code == null || code.trim().equals(""))
      return "";
    String token;
    String strValue = code;
    StringBuffer strOut = new StringBuffer();

    int h = strValue.indexOf(";");
    if (h != -1) {
      StringBuffer total = new StringBuffer();
      String strFirstElement = getTextWadContext(strValue.substring(0, h), vecFields,
          vecAuxiliarFields, parentsFieldsData, isDefaultValue, isSOTrx, windowId);
      total.append("(");
      if (strValue.substring(0, h).indexOf("@") == -1)
        total.append("(\"");
      total.append(strFirstElement);
      if (strValue.substring(0, h).indexOf("@") == -1)
        total.append("\")");
      total.append(".equals(\"\")?(");
      if (strValue.substring(h + 1).indexOf("@") == -1)
        total.append("\"");
      total.append(getTextWadContext(strValue.substring(h + 1), vecFields, vecAuxiliarFields,
          parentsFieldsData, isDefaultValue, isSOTrx, windowId));
      if (strValue.substring(h + 1).indexOf("@") == -1)
        total.append("\"");
      total.append("):(");
      if (strValue.substring(0, h).indexOf("@") == -1)
        total.append("\"");
      total.append(strFirstElement);
      if (strValue.substring(0, h).indexOf("@") == -1)
        total.append("\"");
      total.append("))");
      return total.toString();
    }

    int i = strValue.indexOf("@");
    while (i != -1) {
      strOut.append(strValue.substring(0, i));
      strValue = strValue.substring(i + 1, strValue.length());

      int j = strValue.indexOf("@");
      if (j < 0)
        return "";

      token = strValue.substring(0, j);
      strOut.append(getWadContextTranslate(token, vecFields, vecAuxiliarFields, parentsFieldsData,
          isDefaultValue, isSOTrx, windowId, true));

      strValue = strValue.substring(j + 1, strValue.length());

      i = strValue.indexOf("@");
    }
    strOut.append(strValue);
    return strOut.toString();
  }

  public static String transformFieldName(String field) {
    if (field == null || field.trim().equals(""))
      return "";
    int aux = field.toUpperCase().indexOf(" AS ");
    if (aux != -1)
      return field.substring(aux + 3).trim();
    aux = field.lastIndexOf(".");
    if (aux != -1)
      return field.substring(aux + 1).trim();

    return field.trim();
  }

  public static boolean findField(Vector<Object> vecFields, String field) {
    String strAux;
    for (int i = 0; i < vecFields.size(); i++) {
      strAux = transformFieldName((String) vecFields.elementAt(i));
      if (strAux.equalsIgnoreCase(field))
        return true;
    }
    return false;
  }

  public static String getWadContextTranslate(String token, Vector<Object> vecFields,
      Vector<Object> vecAuxiliarFields, FieldsData[] parentsFieldsData, boolean isDefaultValue,
      String isSOTrx, String windowId, boolean dataMultiple) {
    if (token.substring(0, 1).indexOf("#") > -1 || token.substring(0, 1).indexOf("$") > -1) {
      if (token.equalsIgnoreCase("#DATE"))
        return "DateTimeData.today(this)";
      // else return "vars.getSessionValue(\"" + token + "\")";
      else
        return "Utility.getContext(this, vars, \"" + token + "\", windowId)";
    } else {
      String aux = Sqlc.TransformaNombreColumna(token);
      if (token.equalsIgnoreCase("ISSOTRX"))
        return ("\"" + isSOTrx + "\"");
      if (parentsFieldsData != null) {
        for (int i = 0; i < parentsFieldsData.length; i++) {
          if (parentsFieldsData[i].name.equalsIgnoreCase(token))
            return "strP" + parentsFieldsData[i].name;
        }
      }
      if (!isDefaultValue) {
        if (vecFields != null && findField(vecFields, token)) {
          return (dataMultiple ? "((dataField!=null)?dataField.getField(\"" + aux
              + "\"):((data==null || data.length==0)?\"\":data[0]." : "((data==null)?\"\":data.")
              + aux + "))";
        } else if (vecAuxiliarFields != null && findField(vecAuxiliarFields, token)) {
          return "str" + token;
        }
      }
      return "Utility.getContext(this, vars, \"" + token + "\", \"" + windowId + "\")";
    }
  }

  public static String getWadDefaultValue(FieldsData fd) {
    if (fd == null)
      return "";
    if (fd.referencevalue.equals("28") && !fd.name.toUpperCase().endsWith("_ID"))
      return "N"; // Button
    else if (fd.referencevalue.equals("20"))
      return "N"; // YesNo
    else if (fd.required.equals("Y")) {
      if (isDecimalNumber(fd.referencevalue) || isPriceNumber(fd.referencevalue)
          || isIntegerNumber(fd.referencevalue) || isGeneralNumber(fd.referencevalue)
          || isQtyNumber(fd.referencevalue))
        return "0";
      // FIXME: It makes no sense that the default value for an ID or
      // reference is zero
    }
    return "";
  }

  public static String displayLogic(String code, Vector<Object> vecDL,
      FieldsData[] parentsFieldsData, Vector<Object> vecAuxiliar, Vector<Object> vecFields,
      String windowId, Vector<Object> vecContext) {
    if (code == null || code.trim().equals(""))
      return "";
    String token, token2;
    String strValue = code;
    StringBuffer strOut = new StringBuffer();

    String strAux;
    StringTokenizer st = new StringTokenizer(strValue, "|&", true);
    while (st.hasMoreTokens()) {
      strAux = st.nextToken().trim();
      int i[] = getFirstElement(unions, strAux);
      if (i[0] != -1) {
        strAux = strAux.substring(0, i[0]) + unions[i[1]][1]
            + strAux.substring(i[0] + unions[i[1]][0].length());
      }

      int pos[] = getFirstElement(comparations, strAux);
      token = strAux;
      token2 = "";
      if (pos[0] >= 0) {
        token = strAux.substring(0, pos[0]);
        token2 = strAux.substring(pos[0] + comparations[pos[1]][0].length(), strAux.length());
        strAux = strAux.substring(0, pos[0]) + comparations[pos[1]][1]
            + strAux.substring(pos[0] + comparations[pos[1]][0].length(), strAux.length());
      }

      strOut.append(getDisplayLogicText(token, vecFields, parentsFieldsData, vecAuxiliar, vecDL,
          windowId, vecContext, true));
      if (pos[0] >= 0)
        strOut.append(comparations[pos[1]][1]);
      strOut.append(getDisplayLogicText(token2, vecFields, parentsFieldsData, vecAuxiliar, vecDL,
          windowId, vecContext, false));
    }
    return strOut.toString();
  }

  public static int[] getFirstElement(String[][] array, String token) {
    int min[] = { -1, -1 }, aux;
    for (int i = 0; i < array.length; i++) {
      aux = token.indexOf(array[i][0]);
      if (aux != -1 && (aux < min[0] || min[0] == -1)) {
        min[0] = aux;
        min[1] = i;
      }
    }
    return min;
  }

  public static boolean isInVector(Vector<Object> vec, String field) {
    if (field == null || field.trim().equals(""))
      return false;
    for (int i = 0; i < vec.size(); i++) {
      String aux = (String) vec.elementAt(i);
      if (aux.equalsIgnoreCase(field))
        return true;
    }
    return false;
  }

  public static void saveVectorField(Vector<Object> vec, String field) {
    if (field == null || field.trim().equals(""))
      return;
    if (!isInVector(vec, field))
      vec.addElement(field);
  }

  public static String getComboReloadText(String token, Vector<Object> vecFields,
      FieldsData[] parentsFieldsData, Vector<Object> vecComboReload, String prefix) {
    return getComboReloadText(token, vecFields, parentsFieldsData, vecComboReload, prefix, "");
  }

  public static String getComboReloadText(String token, Vector<Object> vecFields,
      FieldsData[] parentsFieldsData, Vector<Object> vecComboReload, String prefix,
      String columnname) {
    StringBuffer strOut = new StringBuffer();
    int i = token.indexOf("@");
    while (i != -1) {
      // strOut.append(token.substring(0,i));
      token = token.substring(i + 1);
      if (!token.startsWith("SQL")) {
        i = token.indexOf("@");
        if (i != -1) {
          String strAux = token.substring(0, i);
          token = token.substring(i + 1);
          if (!strOut.toString().trim().equals(""))
            strOut.append(", ");
          strOut.append(getComboReloadTextTranslate(strAux, vecFields, parentsFieldsData,
              vecComboReload, prefix, columnname));
        }
      }
      i = token.indexOf("@");
    }
    // strOut.append(token);
    return strOut.toString();
  }

  public static String getComboReloadTextTranslate(String token, Vector<Object> vecFields,
      FieldsData[] parentsFieldsData, Vector<Object> vecComboReload, String prefix,
      String columnname) {
    if (token == null || token.trim().equals(""))
      return "";
    if (!token.equalsIgnoreCase(columnname))
      saveVectorField(vecComboReload, token);
    if (parentsFieldsData != null) {
      for (int i = 0; i < parentsFieldsData.length; i++) {
        if (parentsFieldsData[i].name.equalsIgnoreCase(token))
          return ((prefix.equals("")) ? ("\"" + parentsFieldsData[i].name + "\"") : ("\"" + prefix
              + Sqlc.TransformaNombreColumna(parentsFieldsData[i].name) + "\""));
      }
    }
    if (vecFields != null && findField(vecFields, token)) {
      return ((prefix.equals("")) ? ("\"" + token + "\"") : ("\"" + prefix
          + Sqlc.TransformaNombreColumna(token) + "\""));
    }
    return ((prefix.equals("")) ? ("\"" + FormatUtilities.replace(token) + "\"") : ("\"" + prefix
        + Sqlc.TransformaNombreColumna(token) + "\""));
  }

  public static String getDisplayLogicText(String token, Vector<Object> vecFields,
      FieldsData[] parentsFieldsData, Vector<Object> vecAuxiliar, Vector<Object> vecDisplayLogic,
      String windowId, Vector<Object> vecContext, boolean save) {
    StringBuffer strOut = new StringBuffer();
    int i = token.indexOf("@");
    while (i != -1) {
      strOut.append(token.substring(0, i));
      token = token.substring(i + 1);
      i = token.indexOf("@");
      if (i != -1) {
        String strAux = token.substring(0, i);
        token = token.substring(i + 1);
        strOut.append(getDisplayLogicTextTranslate(strAux, vecFields, parentsFieldsData,
            vecAuxiliar, vecDisplayLogic, windowId, vecContext, save));
      }
      i = token.indexOf("@");
    }
    strOut.append(token);
    return strOut.toString();
  }

  public static String getDisplayLogicTextTranslate(String token, Vector<Object> vecFields,
      FieldsData[] parentsFieldsData, Vector<Object> vecAuxiliar, Vector<Object> vecDisplayLogic,
      String windowId, Vector<Object> vecContext, boolean save) {
    if (token == null || token.trim().equals(""))
      return "";
    String aux = Sqlc.TransformaNombreColumna(token);
    if (save)
      saveVectorField(vecDisplayLogic, token);
    if (parentsFieldsData != null) {
      for (int i = 0; i < parentsFieldsData.length; i++) {
        if (parentsFieldsData[i].name.equalsIgnoreCase(token))
          return "inputValue(document.frmMain.inp"
              + Sqlc.TransformaNombreColumna(parentsFieldsData[i].name) + ")";
      }
    }
    if (vecAuxiliar != null && findField(vecAuxiliar, token)) {
      return ("inputValue(document.frmMain.inp" + aux + ")");
    }
    if (vecFields != null && findField(vecFields, token)) {
      return ("inputValue(document.frmMain.inp" + aux + ")");
    }
    saveVectorField(vecContext, token);
    return "str" + FormatUtilities.replace(token);
  }

  public static String getDisplayLogicComparation(String token) {
    String aux = token.trim();
    for (int i = 0; i < comparations.length; i++) {
      if (comparations[i][0].equals(aux))
        return comparations[i][1];
    }
    return aux;
  }

  public static boolean isInFieldList(FieldsData[] fields, String columnName) {
    if (fields == null || fields.length == 0)
      return false;
    for (int i = 0; i < fields.length; i++) {
      if (fields[i].name.equalsIgnoreCase(columnName))
        return true;
    }
    return false;
  }

  public static boolean isDecimalNumber(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return (reference.equals("12") || reference.equals("22"));
  }

  public static boolean isGeneralNumber(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("800019");
  }

  public static boolean isQtyNumber(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("29");
  }

  public static boolean isPriceNumber(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("800008");

  }

  public static boolean isIntegerNumber(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("11");
  }

  public static boolean isDateField(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("15");
  }

  public static boolean isTimeField(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("24");
  }

  public static boolean isDateTimeField(String reference) {
    if (reference == null || reference.equals(""))
      return false;

    return reference.equals("15") || reference.equals("16") || reference.equals("24");
  }

  public static boolean isLikeType(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("10") || reference.equals("14") || reference.equals("34");
  }

  public static boolean isTextData(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("15") || reference.equals("20") || reference.equals("17");

  }

  public static boolean isSearchValueColumn(String name) {
    if (name == null || name.equals(""))
      return false;
    return (name.equalsIgnoreCase("Value") || name.equalsIgnoreCase("DocumentNo"));
  }

  public static boolean isSelectType(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("17") || reference.equals("18") || reference.equals("19");
  }

  public static boolean isSearchType(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("21") || reference.equals("25") || reference.equals("30")
        || reference.equals("31") || reference.equals("32") || reference.equals("35")
        || reference.equals("800013") || reference.equals("800011");
  }

  public static boolean isLinkType(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    return reference.equals("800101");
  }

  public static String sqlCasting(ConnectionProvider conn, String reference, String referencevalue) {
    if (reference == null || reference.equals(""))
      return "";
    else if (isDateTimeField(reference))
      return "TO_DATE";
    else if (reference.equals("19") || isSearchType(reference))
      return "";
    else if (isIntegerNumber(reference) || isPriceNumber(reference) || isQtyNumber(reference)
        || isGeneralNumber(reference) || isDecimalNumber(reference))
      return "TO_NUMBER";
    else if (reference.equals("27") || reference.equals("33"))
      return "TO_NUMBER";
    else if (reference.equals("28") && (referencevalue.equals("11")))
      return "TO_NUMBER";
    else if (reference.equals("18")) {
      if (referencevalue == null)
        return "";
      try {
        TableRelationData trd[] = TableRelationData.selectRefTable(conn, referencevalue);
        if (trd == null || trd.length == 0)
          return "";
        return sqlCasting(conn, trd[0].referencekey, trd[0].referencevaluekey);
      } catch (ServletException ex) {
        log4j.error("sqlCasting: " + ex);
        return "";
      }
    } else
      return "";
  }

  public static void setPropertyValue(Properties _prop, FieldProvider _field, String _name,
      String _fieldName, String _defaultValue) throws Exception {
    String aux = "";
    try {
      aux = _field.getField(_fieldName);
      if (aux == null || aux.equals(""))
        aux = _defaultValue;
    } catch (Exception ex) {
      if (_defaultValue == null)
        throw new Exception("Inexistent field: " + _fieldName);
      else
        aux = _defaultValue;
    }
    if (aux != null)
      _prop.setProperty(_name, aux);
  }

  public static WADControl getControl(ConnectionProvider conn, FieldProvider field,
      boolean isreadonly, String tabName, String adLanguage, XmlEngine xmlEngine,
      boolean isDisplayLogic, boolean isReloadObject, boolean isReadOnlyLogic,
      boolean hasParentsFields) throws Exception {
    return getControl(conn, field, isreadonly, tabName, adLanguage, xmlEngine, isDisplayLogic,
        isReloadObject, isReadOnlyLogic, hasParentsFields, false);
  }

  public static WADControl getControl(ConnectionProvider conn, FieldProvider field,
      boolean isreadonly, String tabName, String adLanguage, XmlEngine xmlEngine,
      boolean isDisplayLogic, boolean isReloadObject, boolean isReadOnlyLogic,
      boolean hasParentsFields, boolean isReadOnlyDefinedTab) throws Exception {
    if (field == null)
      return null;
    Properties prop = new Properties();
    setPropertyValue(prop, field, "ColumnName", "columnname", null);
    prop.setProperty("ColumnNameInp", Sqlc.TransformaNombreColumna(field.getField("columnname")));
    setPropertyValue(prop, field, "Name", "name", null);
    setPropertyValue(prop, field, "AD_Field_ID", "adFieldId", null);
    setPropertyValue(prop, field, "IsMandatory", "required", "N");
    setPropertyValue(prop, field, "AD_Reference_ID", "reference", null);
    setPropertyValue(prop, field, "ReferenceName", "referenceName", null);
    setPropertyValue(prop, field, "ReferenceNameTrl", "referenceNameTrl", "");
    setPropertyValue(prop, field, "AD_Reference_Value_ID", "referencevalue", "");
    setPropertyValue(prop, field, "AD_Val_Rule_ID", "adValRuleId", "");
    setPropertyValue(prop, field, "DisplayLength", "displaysize", "0");
    setPropertyValue(prop, field, "IsSameLine", "issameline", "N");
    setPropertyValue(prop, field, "IsDisplayed", "isdisplayed", "N");
    setPropertyValue(prop, field, "IsUpdateable", "isupdateable", "N");
    setPropertyValue(prop, field, "IsParent", "isparent", "N");
    setPropertyValue(prop, field, "FieldLength", "fieldlength", "0");
    setPropertyValue(prop, field, "AD_Column_ID", "adColumnId", "null");
    setPropertyValue(prop, field, "ColumnNameSearch", "realname", "");
    setPropertyValue(prop, field, "SearchName", "searchname", "");
    setPropertyValue(prop, field, "AD_CallOut_ID", "adCalloutId", "");
    setPropertyValue(prop, field, "CallOutName", "calloutname", "");
    setPropertyValue(prop, field, "CallOutMapping", "mappingnameCallout", "");
    setPropertyValue(prop, field, "CallOutClassName", "classnameCallout", "");
    setPropertyValue(prop, field, "AD_Process_ID", "adProcessId", "");
    setPropertyValue(prop, field, "IsReadOnly", "isreadonly", "N");
    setPropertyValue(prop, field, "DisplayLogic", "displaylogic", "");
    setPropertyValue(prop, field, "IsEncrypted", "isencrypted", "N");
    setPropertyValue(prop, field, "AD_FieldGroup_ID", "fieldgroup", "");
    setPropertyValue(prop, field, "AD_Tab_ID", "tabid", null);
    setPropertyValue(prop, field, "ValueMin", "valuemin", "");
    setPropertyValue(prop, field, "ValueMax", "valuemax", "");
    setPropertyValue(prop, field, "MappingName", "javaClassName", "");
    setPropertyValue(prop, field, "IsColumnEncrypted", "iscolumnencrypted", "");
    setPropertyValue(prop, field, "IsDesencryptable", "isdesencryptable", "");
    setPropertyValue(prop, field, "ReadOnlyLogic", "readonlylogic", "");
    setPropertyValue(prop, field, "isdirectservletcall", "isdirectservletcall", "");
    prop.setProperty("TabName", tabName);
    prop.setProperty("IsReadOnlyTab", (isreadonly ? "Y" : "N"));
    prop.setProperty("AD_Language", adLanguage);
    prop.setProperty("IsDisplayLogic", (isDisplayLogic ? "Y" : "N"));
    prop.setProperty("IsReadOnlyLogic", (isReadOnlyLogic ? "Y" : "N"));
    prop.setProperty("IsComboReload", (isReloadObject ? "Y" : "N"));
    prop.setProperty("isReadOnlyDefinedTab", (isReadOnlyDefinedTab ? "Y" : "N"));
    prop.setProperty("hasParentsFields", (hasParentsFields ? "Y" : "N"));

    String classname = "org.openbravo.wad.controls.WAD"
        + FormatUtilities.replace(field.getField("referenceName"));
    WADControl _myClass = null;
    try {
      Class<?> c = Class.forName(classname);
      _myClass = (WADControl) c.getConstructor().newInstance();
    } catch (ClassNotFoundException ex) {
      log4j.warn("Couldn´t find class: " + classname);
      _myClass = new WADControl();
    }
    _myClass.setConnection(conn);
    _myClass.setReportEngine(xmlEngine);
    _myClass.setInfo(prop);
    _myClass.initialize();
    _myClass.setConnection(null);

    return _myClass;
  }

  public static boolean isNewGroup(WADControl control, String strFieldGroup) {
    if (control == null)
      return false;
    String fieldgroup = control.getData("AD_FieldGroup_ID");
    return (control.getData("IsDisplayed").equals("Y") && fieldgroup != null
        && !fieldgroup.equals("") && !fieldgroup.equals(strFieldGroup));
  }

  public static String getReadOnlyLogic(WADControl auxControl, Vector<Object> vecDL,
      FieldsData[] parentsFieldsData, Vector<Object> vecAuxiliar, Vector<Object> vecFields,
      String windowId, Vector<Object> vecContext, boolean isreadonly) {
    String code = auxControl.getData("ReadOnlyLogic");
    if (code == null || code.equals(""))
      return "";
    StringBuffer _displayLogic = new StringBuffer();
    String element = auxControl.getData("ColumnName");
    if (auxControl.getType().equals("Combo"))
      element = "report" + element + "_S";

    _displayLogic.append("  readOnlyLogicElement('").append(element).append("', (").append(
        displayLogic(code, vecDL, parentsFieldsData, vecAuxiliar, vecFields, windowId, vecContext))
        .append("));\n");

    return _displayLogic.toString();
  }

  public static String getbuttonShortcuts(HashMap<String, String> sc) {
    StringBuffer shortcuts = new StringBuffer();
    Iterator<String> ik = sc.keySet().iterator();
    Iterator<String> iv = sc.values().iterator();
    while (ik.hasNext() && iv.hasNext()) {
      // shortcuts.append("keyArray[keyArray.length] = new keyArrayItem(\"").append(ik.next()).append("\", \"").append(iv.next()).append("\", null, \"altKey\", false, \"onkeydown\");\n");
      shortcuts.append("keyArray[keyArray.length] = new keyArrayItem(\"").append(ik.next()).append(
          "\", \"").append(iv.next()).append("\", null, \"altKey\", false, \"onkeydown\");\n");
    }
    return shortcuts.toString();
  }

  public static String getDisplayLogicForGroups(String strFieldGroup, StringBuffer code) {
    if ((code == null) || (code.length() == 0))
      return "";
    StringBuffer _displayLogic = new StringBuffer();
    _displayLogic.append("if ").append(code).append("{\n");
    _displayLogic.append("  displayLogicElement('fldgrp").append(strFieldGroup).append(
        "', true);\n");
    _displayLogic.append("} else {\n");
    _displayLogic.append("  displayLogicElement('fldgrp").append(strFieldGroup).append(
        "', false);\n");
    _displayLogic.append("}\n");
    return _displayLogic.toString();
  }

  public static String getDisplayLogic(WADControl auxControl, Vector<Object> vecDL,
      FieldsData[] parentsFieldsData, Vector<Object> vecAuxiliar, Vector<Object> vecFields,
      String windowId, Vector<Object> vecContext, boolean isreadonly) {
    String code = auxControl.getData("DisplayLogic");
    if (code == null || code.equals(""))
      return "";
    StringBuffer _displayLogic = new StringBuffer();
    _displayLogic.append("if (");
    _displayLogic.append(displayLogic(code, vecDL, parentsFieldsData, vecAuxiliar, vecFields,
        windowId, vecContext));
    _displayLogic.append(") {\n");
    _displayLogic.append("displayLogicElement('");
    _displayLogic.append(auxControl.getData("ColumnName"));
    _displayLogic.append("_inp_td', true);\n");
    _displayLogic.append("displayLogicElement('");
    _displayLogic.append(auxControl.getData("ColumnName"));
    _displayLogic.append("_inp', true);\n");
    if (!auxControl.getData("AD_Reference_ID").equals("28")) {
      _displayLogic.append("displayLogicElement('");
      _displayLogic.append(auxControl.getData("ColumnName"));
      _displayLogic.append("_lbl_td', true);\n");
      _displayLogic.append("displayLogicElement('");
      _displayLogic.append(auxControl.getData("ColumnName"));
      _displayLogic.append("_lbl', true);\n");
    }
    if ((isGeneralNumber(auxControl.getData("AD_Reference_ID"))
        || isDateField(auxControl.getData("AD_Reference_ID"))
        || isTimeField(auxControl.getData("AD_Reference_ID"))
        || isLikeType(auxControl.getData("AD_Reference_ID"))
        || isDecimalNumber(auxControl.getData("AD_Reference_ID"))
        || isQtyNumber(auxControl.getData("AD_Reference_ID"))
        || isPriceNumber(auxControl.getData("AD_Reference_ID"))
        || isIntegerNumber(auxControl.getData("AD_Reference_ID"))
        || auxControl.getData("AD_Reference_ID").equals("21")
        || auxControl.getData("AD_Reference_ID").equals("25")
        || auxControl.getData("AD_Reference_ID").equals("30")
        || auxControl.getData("AD_Reference_ID").equals("800011")
        || auxControl.getData("AD_Reference_ID").equals("31")
        || auxControl.getData("AD_Reference_ID").equals("32")
        || auxControl.getData("AD_Reference_ID").equals("35") || isLinkType(auxControl
        .getData("AD_Reference_ID")))
        && !auxControl.getData("IsReadOnly").equals("Y") && !isreadonly) {
      _displayLogic.append("displayLogicElement('");
      _displayLogic.append(auxControl.getData("ColumnName"));
      _displayLogic.append("_btt', true);\n");
    }
    _displayLogic.append("} else {\n");
    _displayLogic.append("displayLogicElement('");
    _displayLogic.append(auxControl.getData("ColumnName"));
    _displayLogic.append("_inp_td', false);\n");
    _displayLogic.append("displayLogicElement('");
    _displayLogic.append(auxControl.getData("ColumnName"));
    _displayLogic.append("_inp', false);\n");
    if (!auxControl.getData("AD_Reference_ID").equals("28")) {
      _displayLogic.append("displayLogicElement('");
      _displayLogic.append(auxControl.getData("ColumnName"));
      _displayLogic.append("_lbl_td', false);\n");
      _displayLogic.append("displayLogicElement('");
      _displayLogic.append(auxControl.getData("ColumnName"));
      _displayLogic.append("_lbl', false);\n");
    }
    if ((isGeneralNumber(auxControl.getData("AD_Reference_ID"))
        || isDateField(auxControl.getData("AD_Reference_ID"))
        || isTimeField(auxControl.getData("AD_Reference_ID"))
        || isLikeType(auxControl.getData("AD_Reference_ID"))
        || isDecimalNumber(auxControl.getData("AD_Reference_ID"))
        || isQtyNumber(auxControl.getData("AD_Reference_ID"))
        || isPriceNumber(auxControl.getData("AD_Reference_ID"))
        || isIntegerNumber(auxControl.getData("AD_Reference_ID"))
        || auxControl.getData("AD_Reference_ID").equals("21")
        || auxControl.getData("AD_Reference_ID").equals("25")
        || auxControl.getData("AD_Reference_ID").equals("30")
        || auxControl.getData("AD_Reference_ID").equals("800011")
        || auxControl.getData("AD_Reference_ID").equals("31")
        || auxControl.getData("AD_Reference_ID").equals("35")
        || auxControl.getData("AD_Reference_ID").equals("32") || isLinkType(auxControl
        .getData("AD_Reference_ID")))
        && !auxControl.getData("IsReadOnly").equals("Y") && !isreadonly) {
      _displayLogic.append("displayLogicElement('");
      _displayLogic.append(auxControl.getData("ColumnName"));
      _displayLogic.append("_btt', false);\n");
    }
    _displayLogic.append("}\n");
    return _displayLogic.toString();
  }

  public static void writeFile(File path, String filename, String text) throws IOException {
    File fileData = new File(path, filename);
    FileOutputStream fileWriterData = new FileOutputStream(fileData);
    OutputStreamWriter printWriterData = new OutputStreamWriter(fileWriterData, "UTF-8");
    printWriterData.write(text);
    printWriterData.flush();
    fileWriterData.close();
  }

  /**
   * Replaces special characters in str to make it a valid java string
   * 
   * @param str
   * @return String with special characters replaced
   */
  public static String toJavaString(String str) {
    return (str.replace("\n", "\\n").replace("\"", "\\\""));
  }

  /**
   * Returns a where parameter, this parameter can contain a modifier to decide which level of
   * session value is (# or $).
   * <p>
   * This method returns the parameter applying the modifier if exists. It can return the complete
   * parameter to be used in xsql files or just the name for the parameter with the modifier.
   * 
   * @param parameter
   *          parameter for the where clause to parse
   * @param complete
   *          return the complete parameter or just the name
   * @return the paresed parameter
   */
  public static String getWhereParameter(Object parameter, boolean complete) {
    String strParam = "";
    if (parameter instanceof String) {
      // regular parameter without modifier
      strParam = (String) parameter;
      if (!complete) {
        strParam = strParam.substring(17, strParam.lastIndexOf("\""));
      }
    } else {
      // parameter with modifier, used for session values (#, $)
      String paramElement[] = (String[]) parameter;
      if (complete) {
        strParam = paramElement[0];
      } else {
        strParam = paramElement[1]
            + paramElement[0].substring(17, paramElement[0].lastIndexOf("\""));
      }
    }
    return strParam;
  }

  public static String columnName(String name, String tableModule, String columnModule) {
    // If the column is in a different module than the table it will start with EM_
    String columnName;
    if (tableModule != null && columnModule != null && !tableModule.equals(columnModule)
        && name.toLowerCase().startsWith("em_")) {
      columnName = name.substring(3);
    } else {
      columnName = name;
    }
    return columnName;
  }
}
