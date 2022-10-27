/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011-2012 Stefan Zimmermann
****************************************************************************************************************************************************
*/
package org.openbravo.erpCommon.utility;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.math.*;
import java.sql.Connection;
import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.StringTokenizer;
import java.util.Vector;

import javax.servlet.ServletException;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.engine.xml.JRXmlLoader;

import org.apache.commons.io.FilenameUtils;
import org.apache.log4j.Logger;
import org.apache.tools.ant.types.FileList.FileName;
import org.hibernate.Query;
import org.openbravo.base.HttpBaseServlet;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.OrgTree;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.service.OBDal;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.Sqlc;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.model.ad.ui.Window;
import org.openbravo.uiTranslation.TranslationHandler;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.utils.Replace;

import org.openbravo.zsoft.smartui.Smartprefs;
import org.openz.view.FormDisplayLogic;
import org.openz.view.Formhelper;
import org.openz.view.SelectBoxhelper;

/**
 * @author Fernando Iriazabal
 * 
 *         Utility class
 */
public class Utility {
  static Logger log4j = Logger.getLogger(Utility.class);

  private static List<String> autosaveExcludedPackages = null;
  private static List<String> autosaveExcludedClasses = null;

  // List of excludes packages and classes from Autosave
  // TODO: Define the autosave behavior at object level
  static {
    autosaveExcludedPackages = new ArrayList<String>();
    autosaveExcludedClasses = new ArrayList<String>();
    autosaveExcludedPackages.add("org.openbravo.erpCommon.info");
    autosaveExcludedPackages.add("org.openbravo.erpCommon.ad_callouts");
    autosaveExcludedClasses.add("org.openbravo.erpCommon.utility.PopupLoading");
  }

  /**
   * Checks if a class is excluded from the autosave process
   * 
   * @param canonicalName
   * @return True is the class is excluded or false if not.
   */
  public static boolean isExcludedFromAutoSave(String canonicalName) {
    final int lastPos = canonicalName.lastIndexOf(".");
    final String packageName = canonicalName.substring(0, lastPos);
    return autosaveExcludedPackages.contains(packageName)
        || autosaveExcludedClasses.contains(canonicalName);
  }

  /**
   * Checks if a getNumericParameters is needed based on a reference
   * 
   * @param reference
   * @return true if the passed reference represents a numeric type, false otherwise.
   */
  public static boolean isNumericParameter(String reference) {
    return (!Utility.isID(reference) && (Utility.isDecimalNumber(reference) || Utility
        .isIntegerNumber(reference)));
  }

  /**
   * Checks if the reference is an ID
   * 
   * @param reference
   *          String with the reference
   * @return True if is a ID reference
   */
  public static boolean isID(String reference) {
    if (reference == null || reference.equals("")) {
      return false;
    }
    return Integer.valueOf(reference).intValue() == 13;
  }

  /**
   * Checks if the references is a decimal number type.
   * 
   * @param reference
   *          String with the reference.
   * @return True if is a decimal or false if not.
   */
  public static boolean isDecimalNumber(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    switch (Integer.valueOf(reference).intValue()) {
    case 12:
    case 22:
    case 29:
    case 80008:
      return true;
    }
    return false;
  }

  /**
   * Checks if the references is an integer number type.
   * 
   * @param reference
   *          String with the reference.
   * @return True if is an integer or false if not.
   */
  public static boolean isIntegerNumber(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    switch (Integer.valueOf(reference).intValue()) {
    case 11:
    case 13:
    case 25:
      return true;
    }
    return false;
  }

  /**
   * Checks if the references is a datetime type.
   * 
   * @param reference
   *          String with the reference.
   * @return True if is a datetime or false if not.
   */
  public static boolean isDateTime(String reference) {
    if (reference == null || reference.equals(""))
      return false;
    switch (Integer.valueOf(reference).intValue()) {
    case 15:
    case 16:
    case 24:
      return true;
    }
    return false;
  }

  /**
   * Returns an String with the date in the specified format
   * 
   * @param date
   *          Date to be formatted.
   * @param pattern
   *          Format expected for the output.
   * @return String formatted.
   */
  public static String formatDate(Date date, String pattern) {
    final SimpleDateFormat dateFormatter = new SimpleDateFormat(pattern);
    return dateFormatter.format(date);
  }

  /**
   * Checks if the record has attachments associated.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param strTab
   *          String with the tab id.
   * @param recordId
   *          String with the record id.
   * @return True if the record has attachments or false if not.
   * @throws ServletException
   */
  public static boolean hasTabAttachments(ConnectionProvider conn, VariablesSecureApp vars,
      String strTab, String recordId) throws ServletException {
    return UtilityData.hasTabAttachments(conn, Utility.getContext(conn, vars, "#User_Client", ""),
        Utility.getContext(conn, vars, "#AccessibleOrgTree", ""), strTab, recordId);
  }

  /**
   * Translate the given code into some message from the application dictionary.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param strCode
   *          String with the code to search.
   * @param strLanguage
   *          String with the translation language.
   * @return String with the translated message.
   */
  public static String messageBD(ConnectionProvider conn, String strCode, String strLanguage) {
    String strMessage = "";
    if (strLanguage == null || strLanguage.equals(""))
      strLanguage = "en_US";

    try {
        strMessage = MessageBDData.messageLanguage(conn, strCode, strLanguage);
    } catch (final Exception ignore) {
    }
    log4j.debug("Utility.messageBD - Message description: " + strMessage);
    if (strMessage == null || strMessage.equals(strCode)) {
      try {
          strMessage = MessageBDData.columnnameLanguage(conn, strCode, strLanguage);
      } catch (final Exception e) {
        strMessage = strCode;
      }
    }
    if (strMessage == null || strMessage.equals(""))
      strMessage = strCode;
    return Replace.replace(Replace.replace(strMessage, "\n", "\\n"), "\"", "&quot;");
  }

  /**
   * 
   * Formats a message String into a String for html presentation. Escapes the &, <, >, " and ®, and
   * replace the \n by <br/>
   * and \r for space.
   * 
   * IMPORTANT! : this method is designed to transform the output of Utility.messageBD method, and
   * this method replaces \n by \\n and \" by &quote. Because of that, the first replacements revert
   * this previous replacements.
   * 
   * @param message
   *          message with java formating
   * @return html format message
   */
  public static String formatMessageBDToHtml(String message) {
    return Replace.replace(Replace.replace(Replace.replace(Replace.replace(Replace.replace(Replace
        .replace(Replace.replace(Replace.replace(Replace.replace(Replace.replace(Replace.replace(
            message, "\\n", "\n"), "&quot", "\""), "&", "&amp;"), "\"", "&quot;"), "<", "&lt;"),
            ">", "&gt;"), "\n", "<br/>"), "\r", " "), "®", "&reg;"), "&lt;![CDATA[", "<![CDATA["),
        "]]&gt;", "]]>");
  }

  /**
   * Gets the value of the given preference.
   * 
   * @param vars
   *          Handler for the session info.
   * @param context
   *          String with the preference.
   * @param window
   *          String with the window id.
   * @return String with the value.
   */
  public static String getPreference(VariablesSecureApp vars, String context, String window) {
    if (context == null || context.equals(""))
      throw new IllegalArgumentException("getPreference - require context");
    String retValue = "";

    retValue = vars.getSessionValue("P|" + window + "|" + context);
    if (retValue.equals(""))
      retValue = vars.getSessionValue("P|" + context);

    return (retValue);
  }

  /**
   * Gets the transactional range defined.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param window
   *          String with the window id.
   * @return String with the value.
   */
  public static String getTransactionalDate(ConnectionProvider conn, VariablesSecureApp vars,
      String window) {
    String retValue = "";

    try {
      retValue = getContext(conn, vars, "Transactional$Range", window);
    } catch (final IllegalArgumentException ignored) {
    }

    if (retValue.equals(""))
      return "1";
    return retValue;
  }

  /**
   * Gets a value from the context. For client 0 is always added (used for references), to check if
   * it must by added or not use the getContext with accesslevel method.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param context
   *          String with the parameter to search.
   * @param window
   *          String with the window id.
   * @return String with the value.
   */
  public static String getContext(ConnectionProvider conn, VariablesSecureApp vars, String context,
      String window) {
    if (context == null || context.equals(""))
      throw new IllegalArgumentException("getContext - require context");
    String retValue = "";
 
    if (!context.startsWith("#") && !context.startsWith("$")) {
      retValue = getPreference(vars, context, window);
      if (!window.equals("") && retValue.equals(""))
        retValue = vars.getSessionValue(window + "|" + context);
      if (retValue.equals(""))
        retValue = vars.getSessionValue("#" + context);
      if (retValue.equals(""))
        retValue = vars.getSessionValue("$" + context);
      // SZ: Get the Value directly from The Session, if none found Yet
      if (retValue.equals(""))
        retValue = vars.getSessionValue(context);
    } else {
      try {
        if (context.equalsIgnoreCase("#Date"))
          return DateTimeData.today(conn);
      } catch (final ServletException e) {
      }
      retValue = vars.getSessionValue(context);

      final String userLevel = vars.getSessionValue("#User_Level");

      if (context.equalsIgnoreCase("#AccessibleOrgTree")) {
        if (!retValue.equals("'0'") && !retValue.startsWith("'0',")
            && retValue.indexOf(",'0'") == -1) {// add *
          retValue = "'0'" + (retValue.equals("") ? "" : ",") + retValue;
        }
      }

      if (context.equalsIgnoreCase("#User_Org")) {
        if (userLevel.contains("S") || userLevel.equals(" C"))
          return "'0'"; // force org *

        if (userLevel.equals("  O")) { // remove *
          if (retValue.equals("'0'"))
            retValue = "";
          else if (retValue.startsWith("'0',"))
            retValue = retValue.substring(4);
          else
            retValue = retValue.replace(",'0'", "");
        } else { // add *
          if (!retValue.equals("0") && !retValue.startsWith("'0',")
              && retValue.indexOf(",'0'") == -1) {// Any: current
            // list and *
            retValue = "'0'" + (retValue.equals("") ? "" : ",") + retValue;
          }
        }
      }

      if (context.equalsIgnoreCase("#User_Client")) {
        if (retValue != "'0'" && !retValue.startsWith("'0',") && retValue.indexOf(",'0'") == -1) {
          retValue = "'0'" + (retValue.equals("") ? "" : ",") + retValue;
        }
      }
    }

    return retValue;
  }

  /**
   * Gets a value from the context. Access level values: 1 Organization 3 Client/Organization 4
   * System only 6 System/Client 7 All
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param context
   *          String with the parameter to search.
   * @param strWindow
   *          String with the window id.
   * @param accessLevel
   * @return String with the value.
   */
  public static String getContext(ConnectionProvider conn, VariablesSecureApp vars, String context,
      String strWindow, int accessLevel) {
    if (context == null || context.equals(""))
      throw new IllegalArgumentException("getContext - require context");
    String retValue = "";

    if (!context.startsWith("#") && !context.startsWith("$")) {
      retValue = getPreference(vars, context, strWindow);
      if (!strWindow.equals("") && retValue.equals(""))
        retValue = vars.getSessionValue(strWindow + "|" + context);
      if (retValue.equals(""))
        retValue = vars.getSessionValue("#" + context);
      if (retValue.equals(""))
        retValue = vars.getSessionValue("$" + context);
    } else {
      try {
        if (context.equalsIgnoreCase("#Date"))
          return DateTimeData.today(conn);
      } catch (final ServletException e) {
      }

      retValue = vars.getSessionValue(context);

      final String userLevel = vars.getSessionValue("#User_Level");
      if (context.equalsIgnoreCase("#AccessibleOrgTree")) {
        if (!retValue.equals("0") && !retValue.startsWith("'0',") && retValue.indexOf(",'0'") == -1) {// add
          // *
          retValue = "'0'" + (retValue.equals("") ? "" : ",") + retValue;
        }
      }
      if (context.equalsIgnoreCase("#User_Org")) {
        if (accessLevel == 4 || accessLevel == 6)
          return "'0'"; // force to be org *

        String window="X";
       // final boolean prevMode = OBContext.getOBContext().setInAdministratorMode(true);
        try {
          try {
          window = WindowAccessData.getWindowType(conn, strWindow);
          } catch (final ServletException e) {
          }
              //org.openbravo.dal.service.OBDal.getInstance().get(Window.class, strWindow);
          if (window.equals("T")) {
            String transactionalOrgs = Replace.replace(retValue, "'0'", "''");   
            //OrgTree.getTransactionAllowedOrgs(retValue); // Old-Code,  Macht einen riesen Speicher-Leck
            if (transactionalOrgs.equals(""))
              // Will show no organizations into the organization's field of the transactional
              // windows
              return "'-1'";
            else
              return transactionalOrgs;
          } else {
            if ((accessLevel == 1) || (userLevel.equals("  O"))) { // No
              // *:
              // remove
              // 0
              // from
              // current
              // list
              if (retValue.equals("'0'"))
                retValue = "";
              else if (retValue.startsWith("'0',"))
                retValue = retValue.substring(4);
              else
                retValue = retValue.replace(",'0'", "");
            } else {// Any: add 0 to current list
              if (!retValue.equals("'0'") && !retValue.startsWith("'0',")
                  && retValue.indexOf(",'0'") == -1) {// Any:
                // current
                // list
                // and *
                retValue = "'0'" + (retValue.equals("") ? "" : ",") + retValue;
              }
            }
          }
        } finally {
         // OBContext.getOBContext().setInAdministratorMode(prevMode);
        }
      }

      if (context.equalsIgnoreCase("#User_Client")) {
        if (accessLevel == 4) {
          if (userLevel.contains("S"))
            return "'0'"; // force client 0
          else
            return "";
        }

        if ((accessLevel == 1) || (accessLevel == 3)) { // No 0
          if (userLevel.contains("S"))
            return "";
          if (retValue.equals("'0'"))
            retValue = "";
          else if (retValue.startsWith("'0',"))
            retValue = retValue.substring(2);
          else
            retValue = retValue.replace(",'0'", "");
        } else if (userLevel.contains("S")) { // Any: add 0
          if (retValue != "'0'" && !retValue.startsWith("'0',") && retValue.indexOf(",'0'") == -1) {
            retValue = "'0'" + (retValue.equals("") ? "" : ",") + retValue;
          }
        }
      }
    }
    log4j.debug("getContext(" + context + "):.. " + retValue);
    return retValue;
  }

  /**
   * Returns the list of referenceables organizations from the current one. This includes all its
   * ancestors and descendants.
   * 
   * @param vars
   * @param currentOrg
   * @return comma delimited Stirng of referenceable organizations.
   */
  public static String getReferenceableOrg(VariablesSecureApp vars, String currentOrg) {
    final OrgTree tree = (OrgTree) vars.getSessionObject("#CompleteOrgTree");
    return tree.getLogicPath(currentOrg).toString();
  }

  /**
   * Returns the list of referenceables organizations from the current one. This includes all its
   * ancestors and descendants. This method takes into account accessLevel and user level: useful to
   * calculate org list for child tabs
   * 
   * @param conn
   * @param vars
   * @param currentOrg
   * @param window
   * @param accessLevel
   * @return the list of referenceable organizations, comma delimited
   */
  public static String getReferenceableOrg(ConnectionProvider conn, VariablesSecureApp vars,
      String currentOrg, String window, int accessLevel) {
    if (accessLevel == 4 || accessLevel == 6)
      return "'0'"; // force to be org *
    final Vector<String> vComplete = getStringVector(getReferenceableOrg(vars, currentOrg));
    final Vector<String> vAccessible = getStringVector(getContext(conn, vars, "#User_Org", window,
        accessLevel));
    return getVectorToString(getIntersectionVector(vComplete, vAccessible));
  }

  /**
   * Returns the organization list for selectors, two cases are possible: <br>
   * <li>Organization is empty (null or ""): accessible list of organizations will be returned. This
   * case is used in calls from filters to selectors. <li>Organization is not empty: referenceable
   * from current organization list of organizations will be returned. This is the way it is called
   * from wad windows.
   * 
   * @param conn
   *          Handler for the database connection
   * @param vars
   * @param currentOrg
   * @return the organization list for selectors
   */
  public static String getSelectorOrgs(ConnectionProvider conn, VariablesSecureApp vars,
      String currentOrg) {
    if ((currentOrg == null) || (currentOrg.equals("")))
      return getContext(conn, vars, "#AccessibleOrgTree", "Selectors");
    else
      return getReferenceableOrg(vars, currentOrg);
  }

  /**
   * Gets a default value.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param columnname
   *          String with the column name.
   * @param context
   *          String with the parameter.
   * @param window
   *          String with the window id.
   * @param defaultValue
   *          with the default value.
   * @param sessionData
   *          FieldProvider with the data stored in session
   * @return String with the value.
   */
  public static String getDefault(HttpSecureAppServlet conn, VariablesSecureApp vars,
      String columnname, String context, String window,String tab, String defaultValue,
      FieldProvider sessionData) {
    if (columnname == null || columnname.equals(""))
      return "";
    try {
      if (sessionData != null) {
        final String sessionValue = sessionData.getField(columnname);
        if (sessionValue != null) {
          return sessionValue;
        }
      }  
      // Switched to FormDisplay Logic to get Default Value
      String fieldId=UtilityData.getTabFieldID(conn, columnname, tab);
      String retVal=FormDisplayLogic.getFieldDefaultValue(conn, vars, fieldId);
      
      // Special Case Docaction - Set to Complete by default
      if (columnname.equalsIgnoreCase("docaction") && retVal.isEmpty())
        retVal="CO";
      // Special Case Org id on Windows with acess Level=ORG an a user logged in with ORG='*'
      if (columnname.equalsIgnoreCase("ad_org_id") && 
          Formhelper.getTabAccessLevel(conn, vars, tab).equals("1") &&
          retVal.equals("0")) {
        String test=vars.getUserOrg();
        String org="";
        int i,beg,en=0;
        retVal="";
        i=0;
        while (i<test.length()) {
          beg=test.indexOf("'", i);
          en=test.indexOf("'", i+beg+1);
          org=test.substring(beg+1,en);
          if (!org.equals("0") && ! org.equals(",")) {
            retVal=org;
            break;
          }
          i=en+1;
        }
      }
      return retVal;
    }
    catch (final Exception e) {
      return "";
    }
 }
/* 
    // SZ added Smartpref-Values
    Smartprefs temp = new Smartprefs();
    String szdef = temp.getSmartprefs(conn, vars, columnname, window);
    if (!szdef.equals(""))
      return szdef;
    // SZ added Tab-Specific-Values
        String tabfielddef = UtilityData.getTabFieldDefault(conn, tab, columnname);
        if (!tabfielddef.equals(""))
          return tabfielddef;
    } catch (final Exception e) {
    }
    

    String defStr = getPreference(vars, columnname, window);
    if (!defStr.equals(""))
      return defStr;

    if (context.indexOf("@") == -1) // Tokenize just when contains @
      defStr = context;
    else {
      final StringTokenizer st = new StringTokenizer(context, ",;", false);
      while (st.hasMoreTokens()) {
        final String token = st.nextToken().trim();
        if (token.indexOf("@") == -1)
          defStr = token;
        else
          defStr = parseContext(conn, vars, token, window);
        if (!defStr.equals(""))
          return defStr;
      }
    }
    if (defStr.equals(""))
      defStr = vars.getSessionValue("#" + columnname);
    if (defStr.equals(""))
      defStr = vars.getSessionValue("$" + columnname);
    if (defStr.equals("") && defaultValue != null)
      defStr = defaultValue;
    log4j.debug("getDefault(" + columnname + "): " + defStr);
    return defStr;
  }

  /**
   * Overloaded method for backwards compatibility
   
  public static String getDefault(ConnectionProvider conn, VariablesSecureApp vars,
      String columnname, String context, String window,String tab, String defaultValue) {
    return Utility.getDefault(conn, vars, columnname, context, window,tab, defaultValue, null);
  }
*/
  /**
   * Returns a Vector<String> composed by the comma separated elements in String s
   * 
   * @param s
   * @return the list of String obtained by converting the comma delimited String
   */
  public static Vector<String> getStringVector(String s) {
    final Vector<String> v = new Vector<String>();
    final StringTokenizer st = new StringTokenizer(s, ",", false);
    while (st.hasMoreTokens()) {
      final String token = st.nextToken().trim();
      if (!v.contains(token))
        v.add(token);
    }
    return v;
  }

  /**
   * Returns a Vector<String> with the elements that appear in both v1 and v2 Vectors
   * 
   * @param v1
   * @param v2
   * @return the combination of v1 and v2 without duplicates
   */
  public static Vector<String> getIntersectionVector(Vector<String> v1, Vector<String> v2) {
    final Vector<String> v = new Vector<String>();
    for (int i = 0; i < v1.size(); i++) {
      if (v2.contains(v1.elementAt(i)) && !v.contains(v1.elementAt(i)))
        v.add(v1.elementAt(i));
    }
    return v;
  }

  /**
   * Returns the elements in Vector v as an String separating with commas the elements
   * 
   * @param v
   * @return a comma delimited String
   */
  public static String getVectorToString(Vector<String> v) {
    final StringBuffer s = new StringBuffer();
    for (int i = 0; i < v.size(); i++) {
      if (s.length() != 0)
        s.append(", ");
      s.append(v.elementAt(i));
    }
    return s.toString();
  }

  /**
   * Parse the given string searching the @ elements to translate with the correct values.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param context
   *          String to parse.
   * @param window
   *          String with the window id.
   * @return String parsed.
   */
  public static String parseContext(ConnectionProvider conn, VariablesSecureApp vars,
      String context, String window) {
    if (context == null || context.equals(""))
      return "";
    final StringBuffer strOut = new StringBuffer();
    String value = new String(context);
    String token, defStr;
    int i = value.indexOf("@");
    while (i != -1) {
      strOut.append(value.substring(0, i));
      value = value.substring(i + 1);
      final int j = value.indexOf("@");
      if (j == -1) {
        strOut.append(value);
        return strOut.toString();
      }
      token = value.substring(0, j);
      defStr = getContext(conn, vars, token, window);
      if (defStr.equals(""))
        return "";
      strOut.append(defStr);
      value = value.substring(j + 1);
      i = value.indexOf("@");
    }
    return strOut.toString();
  }

  /**
   * Gets the document number from the database.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param WindowNo
   *          Window id.
   * @param TableName
   *          Table name.
   * @param C_DocTypeTarget_ID
   *          Id of the doctype target.
   * @param C_DocType_ID
   *          id of the doctype.
   * @param onlyDocType
   *          Search only for doctype.
   * @param updateNext
   *          Save the new sequence in database.
   * @return String with the new document number.
   */
  public static String getDocumentNo(ConnectionProvider conn, VariablesSecureApp vars,
      String WindowNo, String TableName, String C_DocTypeTarget_ID, String C_DocType_ID,
      boolean onlyDocType, boolean updateNext) {
    if (TableName == null || TableName.length() == 0)
      throw new IllegalArgumentException("Utility.getDocumentNo - required parameter missing");
    final String AD_Org_ID = vars.getOrg();

    final String cDocTypeID = (C_DocTypeTarget_ID.equals("") ? C_DocType_ID : C_DocTypeTarget_ID);
    if (cDocTypeID.equals(""))
      return getDocumentNo(conn, AD_Org_ID, TableName, updateNext);

    //if (AD_Client_ID.equals("0"))
    //  throw new UnsupportedOperationException("Utility.getDocumentNo - Cannot add System records");

    CSResponse cs = null;
    try {
      cs = DocumentNoData.nextDocType(conn, cDocTypeID, AD_Org_ID, (updateNext ? "Y" : "N"));
    } catch (final ServletException e) {
    }

    if (cs == null || cs.razon == null || cs.razon.equals("")) {
      if (!onlyDocType)
        return getDocumentNo(conn, AD_Org_ID, TableName, updateNext);
      else
        return "0";
    } else
      return cs.razon;
  }

  public static String getDocumentNo(Connection conn, ConnectionProvider con,
      VariablesSecureApp vars, String WindowNo, String TableName, String C_DocTypeTarget_ID,
      String C_DocType_ID, boolean onlyDocType, boolean updateNext) {
    if (TableName == null || TableName.length() == 0)
      throw new IllegalArgumentException("Utility.getDocumentNo - required parameter missing");
    final String AD_Org_ID = vars.getOrg();

    final String cDocTypeID = (C_DocTypeTarget_ID.equals("") ? C_DocType_ID : C_DocTypeTarget_ID);
    if (cDocTypeID.equals(""))
      return getDocumentNo(con, AD_Org_ID, TableName, updateNext);

   // if (AD_Client_ID.equals("0"))
   //   throw new UnsupportedOperationException("Utility.getDocumentNo - Cannot add System records");

    CSResponse cs = null;
    try {

      cs = DocumentNoData.nextDocTypeConnection(conn, con, cDocTypeID, AD_Org_ID,
          (updateNext ? "Y" : "N"));
    } catch (final ServletException e) {
    }

    if (cs == null || cs.razon == null || cs.razon.equals("")) {
      if (!onlyDocType)
        return getDocumentNoConnection(conn, con, AD_Org_ID, TableName, updateNext);
      else
        return "0";
    } else
      return cs.razon;
  }

  /**
   * Gets the document number from database.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param AD_Client_ID
   *          String with the client id.
   * @param TableName
   *          Table name.
   * @param updateNext
   *          Save the new sequence in database.
   * @return String with the new document number.
   */
  public static String getDocumentNo(ConnectionProvider conn, String AD_Org_ID,
      String TableName, boolean updateNext) {
    if (TableName == null || TableName.length() == 0)
      throw new IllegalArgumentException("Utility.getDocumentNo - required parameter missing");

    CSResponse cs = null;
    try {
      cs = DocumentNoData.nextDoc(conn, "DocumentNo_" + TableName, AD_Org_ID, (updateNext ? "Y"
          : "N"));
    } catch (final ServletException e) {
    }

    if (cs == null || cs.razon == null)
      return "";
    else
      return cs.razon;
  }

  /**
   * Gets the document number from database.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param AD_Client_ID
   *          String with the client id.
   * @param TableName
   *          Table name.
   * @param updateNext
   *          Save the new sequence in database.
   * @return String with the new document number.
   */
  public static String getDocumentNoConnection(Connection conn, ConnectionProvider con,
      String AD_Org_ID, String TableName, boolean updateNext) {
    if (TableName == null || TableName.length() == 0)
      throw new IllegalArgumentException("Utility.getDocumentNo - required parameter missing");

    CSResponse cs = null;
    try {
      cs = DocumentNoData.nextDocConnection(conn, con, "DocumentNo_" + TableName, AD_Org_ID,
          (updateNext ? "Y" : "N"));
    } catch (final ServletException e) {
    }

    if (cs == null || cs.razon == null)
      return "";
    else
      return cs.razon;
  }

  /**
   * Adds the system element to the given list.
   * 
   * @param list
   *          String with the list.
   * @return String with the modified list.
   */
  public static String addSystem(String list) {
    String retValue = "";

    final Hashtable<String, String> ht = new Hashtable<String, String>();
    ht.put("0", "0");

    final StringTokenizer st = new StringTokenizer(list, ",", false);
    while (st.hasMoreTokens())
      ht.put(st.nextToken(), "x");

    final Enumeration<String> e = ht.keys();
    while (e.hasMoreElements())
      retValue += e.nextElement() + ",";

    retValue = retValue.substring(0, retValue.length() - 1);
    return retValue;
  }

  /**
   * Checks if the user can make modifications in the window.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param AD_Client_ID
   *          Id of the client.
   * @param AD_Org_ID
   *          Id of the organization.
   * @param window
   *          Window id.
   * @return True if has permission, false if not.
   * @throws ServletException
   */
  public static boolean canUpdate(ConnectionProvider conn, VariablesSecureApp vars,
      String AD_Client_ID, String AD_Org_ID, String window) throws ServletException {
    final String User_Level = getContext(conn, vars, "#User_Level", window);

    if (User_Level.indexOf("S") != -1)
      return true;

    boolean retValue = true;
    String whatMissing = "";

    if (AD_Client_ID.equals("0") && AD_Org_ID.equals("0") && User_Level.indexOf("S") == -1) {
      retValue = false;
      whatMissing += "S";
    } else if (!AD_Client_ID.equals("0") && AD_Org_ID.equals("0") && User_Level.indexOf("C") == -1) {
      retValue = false;
      whatMissing += "C";
    } else if (!AD_Client_ID.equals("0") && !AD_Org_ID.equals("0") && User_Level.indexOf("O") == -1) {
      retValue = false;
      whatMissing += "O";
    }

    if (!WindowAccessData.hasWriteAccess(conn, window, vars.getRole()))
      retValue = false;

    return retValue;
  }

  /**
   * Parse the text searching @ parameters to translate.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param language
   *          String with the language to translate.
   * @param text
   *          String with the text to translate.
   * @return String translated.
   */
  public static String parseTranslation(ConnectionProvider conn, VariablesSecureApp vars,
      String language, String text) {
    return parseTranslation(conn, vars, null, language, text);
  }

  /**
   * Parse the text searching @ parameters to translate. If replaceMap is not null and contains a
   * replacement value for a token then it will be used, otherwise the return value of the translate
   * method will be used for the translation.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param replaceMap
   *          optional Map containing replacement values for the tokens
   * @param language
   *          String with the language to translate.
   * @param text
   *          String with the text to translate.
   * @return String translated.
   */
  public static String parseTranslation(ConnectionProvider conn, VariablesSecureApp vars,
      Map<String, String> replaceMap, String language, String text) {
    if (text == null || text.length() == 0)
      return text;

    String inStr = text;
    String token;
    final StringBuffer outStr = new StringBuffer();

    int i = inStr.indexOf("@");
    while (i != -1) {
      outStr.append(inStr.substring(0, i));
      inStr = inStr.substring(i + 1, inStr.length());

      final int j = inStr.indexOf("@");
      if (j < 0) {
        inStr = "@" + inStr;
        break;
      }

      token = inStr.substring(0, j);
      if (replaceMap != null && replaceMap.containsKey(token)) {
        outStr.append(replaceMap.get(token));
      } else {
        outStr.append(translate(conn, vars, token, language));
      }

      inStr = inStr.substring(j + 1, inStr.length());
      i = inStr.indexOf("@");
    }

    outStr.append(inStr);
    return outStr.toString();
  }

  /**
   * For each token found in the parseTranslation method, this method is called to find the correct
   * translation.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param token
   *          String with the token to translate.
   * @param language
   *          String with the language to translate.
   * @return String with the token translated.
   */
  public static String translate(ConnectionProvider conn, VariablesSecureApp vars, String token,
      String language) {
    String strTranslate = token;
    strTranslate = vars.getSessionValue(token);
    if (!strTranslate.equals(""))
      return strTranslate;
    strTranslate = messageBD(conn, token, language);
    if (strTranslate.equals(""))
      return token;
    return strTranslate;
  }

  /**
   * Checks if the value exists in the given array of FieldProviders.
   * 
   * @param data
   *          Array of FieldProviders.
   * @param fieldName
   *          Name of the field to search.
   * @param key
   *          The value to search.
   * @return True if exists or false if not.
   */
  public static boolean isInFieldProvider(FieldProvider[] data, String fieldName, String key) {
    if (data == null || data.length == 0)
      return false;
    else if (fieldName == null || fieldName.trim().equals(""))
      return false;
    else if (key == null || key.trim().equals(""))
      return false;
    String f = "";
    for (int i = 0; i < data.length; i++) {
      try {
        f = data[i].getField(fieldName);
      } catch (final Exception e) {
        log4j.error("Utility.isInFieldProvider - " + e);
        return false;
      }
      if (f != null && f.equalsIgnoreCase(key))
        return true;
    }
    return false;
  }

  /**
   * Deprecated. Used in the old order by window.
   * 
   * @deprecated
   * @param SQL
   * @param fields
   */
  @Deprecated
  public static String getOrderByFromSELECT(String[] SQL, Vector<String> fields) {
    if (SQL == null || SQL.length == 0)
      return "";
    else if (fields == null || fields.size() == 0)
      return "";
    final StringBuffer script = new StringBuffer();
    for (int i = 0; i < fields.size(); i++) {
      String token = fields.elementAt(i);
      token = token.trim();
      boolean isnegative = false;
      if (token.startsWith("-")) {
        token = token.substring(1);
        isnegative = true;
      }
      if (Integer.valueOf(token).intValue() > SQL.length)
        log4j.error("Field not found in select - at position: " + token);
      if (!script.toString().equals(""))
        script.append(", ");
      String strAux = SQL[Integer.valueOf(token).intValue() - 1];
      strAux = strAux.toUpperCase().trim();
      final int pos = strAux.indexOf(" AS ");
      if (pos != -1)
        strAux = strAux.substring(0, pos);
      strAux = strAux.trim();
      script.append(strAux);
      if (isnegative)
        script.append(" DESC");
    }
    return script.toString();
  }

  /**
   * Gets the window id for a tab.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param strTabID
   *          Id of the tab.
   * @return String with the id of the window.
   * @throws ServletException
   */
  public static String getWindowID(ConnectionProvider conn, String strTabID)
      throws ServletException {
    return UtilityData.getWindowID(conn, strTabID);
  }

  /*
   * public static String getRegistryKey(String key) { RegistryKey aKey = null; RegStringValue
   * regValue = null;
   * 
   * try{ aKey =com.ice.jni.registry.Registry.HKEY_LOCAL_MACHINE.openSubKey(
   * "SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"); regValue =
   * (RegStringValue)aKey.getValue("PATH"); } catch(NoSuchValueException e) { //Key value does not
   * exist. } catch(RegistryException e) { //Any other registry API error. } return
   * regValue.toString(); }
   */

  /**
   * Saves the content into a fisical file.
   * 
   * @param strPath
   *          path for the file.
   * @param strFile
   *          name of the file.
   * @param data
   *          content of the file.
   * @return true if everything is ok or false if not.
   */
  public static boolean generateFile(String strPath, String strFile, String data) {
    try {
      final File fileData = new File(strPath, strFile);
      final FileWriter fileWriterData = new FileWriter(fileData);
      final PrintWriter printWriterData = new PrintWriter(fileWriterData);
      printWriterData.print(data);
      fileWriterData.close();
    } catch (final IOException e) {
      e.printStackTrace();
      log4j.error("Problem of IOExceptio in file: " + strPath + " - " + strFile);
      return false;
    }
    return true;
  }

  /*
   * public static String sha1Base64(String text) throws ServletException { if (text==null ||
   * text.trim().equals("")) return ""; String result = text; result =
   * CryptoSHA1BASE64.encriptar(text); return result; }
   * 
   * public static String encryptDecrypt(String text, boolean encrypt) throws ServletException { if
   * (text==null || text.trim().equals("")) return ""; String result = text; if (encrypt) result =
   * CryptoUtility.encrypt(text); else result = CryptoUtility.decrypt(text); return result; }
   */
  /**
   * Checks if the tab is declared as a tree tab.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param stradTabId
   *          Id of the tab.
   * @return True if is a tree tab or false if isn't.
   * @throws ServletException
   */
  public static boolean isTreeTab(ConnectionProvider conn, String stradTabId)
      throws ServletException {
    return UtilityData.isTreeTab(conn, stradTabId);
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
   * @param cmb
   *          ComboTableData object.
   * @param window
   *          Window id.
   * @param actual_value
   *          actual value for the combo.
   * @throws ServletException
   * @see org.openbravo.erpCommon.utility.ComboTableData#fillParameters(FieldProvider, String,
   *      String)
   */
  public static void fillSQLParameters(ConnectionProvider conn, VariablesSecureApp vars,
      FieldProvider data, ComboTableData cmb, String window, String actual_value)
      throws ServletException {
    cmb.fillSQLParameters(conn, vars, data, "", window, actual_value, false);
  }

  /**
   * Fill the parameters of the sql with the session values or FieldProvider values. Used in the
   * combo relation's grids.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param data
   *          FieldProvider with the columns values.
   * @param cmb
   *          TableSQLData object.
   * @param window
   *          Window id.
   * @throws ServletException
   */
  public static void fillTableSQLParameters(ConnectionProvider conn, VariablesSecureApp vars,
      FieldProvider data, TableSQLData cmb, String window) throws ServletException {
    final Vector<String> vAux = cmb.getParameters();
    if (vAux != null && vAux.size() > 0) {
      if (log4j.isDebugEnabled())
        log4j.debug("Combo Parameters: " + vAux.size());
      for (int i = 0; i < vAux.size(); i++) {
        final String strAux = vAux.elementAt(i);
        try {
          final String value = parseParameterValue(conn, vars, data, strAux, "", window, "", false);
          if (log4j.isDebugEnabled())
            log4j.debug("Combo Parameter: " + strAux + " - Value: " + value);
          cmb.setParameter(strAux, value);
        } catch (final Exception ex) {
          throw new ServletException(ex);
        }
      }
    }
  }

  /**
   * Auxiliar method, used by fillSQLParameters and fillTableSQLParameters to get the values for
   * each parameter.
   * 
   * Deprecated as only internal utility function for ComboTableData and TableSQLData code, should
   * never be used directly by other code.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param data
   *          FieldProvider with the columns values.
   * @param name
   *          Name of the parameter.
   * @param window
   *          Window id.
   * @param actual_value
   *          Actual value.
   * @return String with the parsed parameter.
   * @throws Exception
   */
  @Deprecated
  public static String parseParameterValue(ConnectionProvider conn, VariablesSecureApp vars,
      FieldProvider data, String name, String window, String actual_value) throws Exception {
    String strAux = null;
    if (name.equalsIgnoreCase("@ACTUAL_VALUE@"))
      return actual_value;
    if (data != null)
      strAux = data.getField(name);
    if (strAux == null) {
      strAux = vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(name));
      if (log4j.isDebugEnabled())
        log4j.debug("parseParameterValues - getStringParameter(inp"
            + Sqlc.TransformaNombreColumna(name) + "): " + strAux);
      if (strAux == null || strAux.equals(""))
        strAux = getContext(conn, vars, name, window);
    }
    return strAux;
  }

  /**
   * Auxiliary method, used by fillSQLParameters and fillTableSQLParameters to get the values for
   * each parameter.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param data
   *          FieldProvider with the columns values.
   * @param name
   *          Name of the parameter.
   * @param window
   *          Window id.
   * @param actual_value
   *          Actual value.
   * @param fromSearch
   *          If the combo is used from the search popup (servlet). If true, then the pattern for
   *          obtaining the parameter values if changed to conform with the search popup naming.
   * @return String with the parsed parameter.
   * @throws Exception
   */
  static String parseParameterValue(ConnectionProvider conn, VariablesSecureApp vars,
      FieldProvider data, String name, String tab, String window, String actual_value,
      boolean fromSearch) throws Exception {
    String strAux = null;
    if (name.equalsIgnoreCase("@ACTUAL_VALUE@"))
      return actual_value;
    if (data != null)
      strAux = data.getField(name);
    if (strAux == null) {
      if (fromSearch) {
        // search popup has different incoming parameter name pattern
        // also preferences (getContext) should not be used for combos in the search popup,
        strAux = vars.getStringParameter("inpParam" + name);
        log4j.debug("parseParameterValues - getStringParameter(inpParam" + name + "): " + strAux);
        // but as search popup 'remembers' old values via the session the read from there needs
        // to be made here, as we disabled getContext (where it was before)
        if (strAux == null || strAux.equals(""))
          strAux = vars.getSessionValue(tab + "|param" + name);

        // Do not use context values for the fields that are in the search pop up
        String strAllFields = vars.getSessionValue("buscador.searchFilds");
        if (strAllFields == null) {
          strAllFields = "";
        }
        if ((strAux == null || strAux.equals("")) && !strAllFields.contains("|" + name + "|")) {
          strAux = Utility.getContext(conn, vars, name, window);
        }
      } else {
        strAux = vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(name));
        if (log4j.isDebugEnabled())
          log4j.debug("parseParameterValues - getStringParameter(inp"
              + Sqlc.TransformaNombreColumna(name) + "): " + strAux);
        if (strAux == null || strAux.equals(""))
          strAux = Utility.getContext(conn, vars, name, window);
        if ((strAux == null || strAux.equals("")) && name.equals("#AD_LANGUAGE"))
        	strAux = vars.getLanguage();
      }
    }
    return strAux;
  }

  /**
   * Gets the Message for the instance of the processes.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param pinstanceData
   *          Array with the instance information.
   * @return Object with the message.
   * @throws ServletException
   */
  public static OBError getProcessInstanceMessage(ConnectionProvider conn, VariablesSecureApp vars,
      PInstanceProcessData[] pinstanceData) throws ServletException {
    OBError myMessage = new OBError();
    if (pinstanceData != null && pinstanceData.length > 0) {
      String message = "";
      String title = "Error";
      String type = "Error";
      if (!pinstanceData[0].errormsg.equals("")) {
        message = pinstanceData[0].errormsg;
      } else if (!pinstanceData[0].pMsg.equals("")) {
        message = pinstanceData[0].pMsg;
      }

      if (pinstanceData[0].result.equals("1")) {
        type = "Success";
        title = Utility.messageBD(conn, "Success", vars.getLanguage());
      } else if (pinstanceData[0].result.equals("0")) {
        type = "Error";
        title = Utility.messageBD(conn, "Error", vars.getLanguage());
      } else {
        type = "Warning";
        title = Utility.messageBD(conn, "Warning", vars.getLanguage());
      }

      final int errorPos = message.indexOf("@ERROR=");
      if (errorPos != -1) {
        myMessage = Utility.translateError(conn, vars, vars.getLanguage(), "@CODE=@"
            + message.substring(errorPos + 7));
        if (log4j.isDebugEnabled())
          log4j.debug("Error Message returned: " + myMessage.getMessage());
        if (message.substring(errorPos + 7).equals(myMessage.getMessage())) {
          myMessage.setMessage(parseTranslation(conn, vars, vars.getLanguage(), myMessage
              .getMessage()));
        }
        if (errorPos > 0)
          message = message.substring(0, errorPos);
        else
          message = "";
      }
      if (!message.equals("") && message.indexOf("@") != -1)
        message = Utility.parseTranslation(conn, vars, vars.getLanguage(), message);
      myMessage.setType(type);
      myMessage.setTitle(title);
      myMessage.setMessage(message + ((!message.equals("") && errorPos != -1) ? " <br> " : "")
          + myMessage.getMessage());
    }
    return myMessage;
  }

  /**
   * Translate the message, searching the @ parameters, and making use of the ErrorTextParser class
   * to get the appropiated message.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param vars
   *          Handler for the session info.
   * @param strLanguage
   *          Language to translate.
   * @param message
   *          Strin with the message to translate.
   * @return Object with the message.
   */
  public static OBError translateError(ConnectionProvider conn, VariablesSecureApp vars,
      String strLanguage, String message) {
    final OBError myError = new OBError();
    myError.setType("Error");
    if (message == null) {
    	myError.setMessage("Error: Null value Exception");
    	return myError;
    }
    myError.setMessage(message);
    if (message.startsWith("javax.servlet.ServletException: @CODE="))
      message = message.substring(32);
    // TODO: Translate Wobei: - This is german installation of Postgres
    if (vars.getSessionValue("P|SHOWDBERRORS").equals("") && message.contains(" Wobei:"))
      message=message.substring(0, message.indexOf(" Wobei:")-2);
    if (message != null && !message.equals("")) {
      String code = "";
      if (log4j.isDebugEnabled())
        log4j.debug("translateError - message: " + message);
      if (message.startsWith("@CODE=@"))
        message = message.substring(7);
      else if (message.startsWith("@CODE=")) {
        message = message.substring(6);
        final int pos = message.indexOf("@");
        if (pos == -1) {
          code = message;
          message = "";
        } else {
          code = message.substring(0, pos);
          message = message.substring(pos + 1);
        }
      }
      myError.setMessage(message);
      if (log4j.isDebugEnabled())
        log4j.debug("translateError - code: " + code + " - message: " + message);

      // BEGIN Checking if is a pool problem
      if (code != null && code.equals("NoConnectionAvailable")) {
        myError.setType("Error");
        myError.setTitle("Critical Error");
        myError.setConnectionAvailable(false);
        myError.setMessage("No database connection available");
        return myError;
      }
      // END Checking if is a pool problem

      // BEGIN Parsing message text
      if (message != null && !message.equals("")) {
        final String rdbms = conn.getRDBMS();
        ErrorTextParser myParser = null;
        try {
          final Class<?> c = Class.forName("org.openbravo.erpCommon.utility.ErrorTextParser"
              + rdbms.toUpperCase());
          myParser = new org.openbravo.erpCommon.utility.ErrorTextParserPOSTGRE();
        } catch (final ClassNotFoundException ex) {
          log4j.warn("Couldn´t find class: org.openbravo.erpCommon.utility.ErrorTextParser"
              + rdbms.toUpperCase());
          myParser = null;
        } catch (final Exception ex1) {
          log4j.warn("Couldn´t initialize class: org.openbravo.erpCommon.utility.ErrorTextParser"
              + rdbms.toUpperCase());
          myParser = null;
        }
        if (myParser != null) {
          myParser.setConnection(conn);
          myParser.setLanguage(strLanguage);
          myParser.setMessage(message);
          myParser.setVars(vars);
          try {
            final OBError myErrorAux = myParser.parse();
            if (myErrorAux != null
                && !myErrorAux.getMessage().equals("")
                && (code == null || code.equals("") || code.equals("0") || !myErrorAux.getMessage()
                    .equalsIgnoreCase(message)))
              return myErrorAux;
          } catch (final Exception ex) {
            log4j.error("Error while parsing text: " + ex);
          }
        }
      } else
        myError.setMessage(code);
      // END Parsing message text

      // BEGIN Looking for error code in AD_Message
      if (code != null && !code.equals("") && vars.getSessionValue("P|SHOWDBERRORS").equals("")) {
        final FieldProvider fldMessage = locateMessage(conn, code, strLanguage);
        if (fldMessage != null) {
          String strMessage=fldMessage.getField("msgtext");
          int fbegin=message.indexOf("»");
          int fend=message.indexOf("«");
          if (fbegin==-1 && fend ==-1) {
            fbegin=message.indexOf("\"");
            fend=message.indexOf("\"", fbegin +1);
          }
          if (fbegin>0 && fend>0 && fend>fbegin)
            strMessage=strMessage.replaceAll("@@",message.substring(fbegin+1, fend ));
          myError.setType((fldMessage.getField("msgtype").equals("E") ? "Error" : (fldMessage
              .getField("msgtype").equals("I") ? "Info" : (fldMessage.getField("msgtype").equals(
              "S") ? "Success" : "Warning"))));
          myError.setMessage(strMessage);
          return myError;
        }
      }
      // END Looking for error code in AD_Message
    }
    return myError;
  }

  /**
   * Search a message in the database.
   * 
   * @param conn
   *          Handler for the database connection.
   * @param strCode
   *          Message to search.
   * @param strLanguage
   *          Language to translate.
   * @return FieldProvider with the message info.
   */
  public static FieldProvider locateMessage(ConnectionProvider conn, String strCode,
      String strLanguage) {
    FieldProvider[] fldMessage = null;

    try {
      if (log4j.isDebugEnabled())
        log4j.debug("Utility.messageBD - Message Code: " + strCode);
      fldMessage = MessageBDData.messageInfo(conn,  strCode,strLanguage);
    } catch (final Exception ignore) {
    }
    if (fldMessage != null && fldMessage.length > 0)
      return fldMessage[0];
    else
      return null;
  }

  public String getServletInfo() {
    return "This servlet add some functions";
  }

  /**
   * Checks if an element is in a list. List is an string like "(e1, e2, e3,...)" where en are
   * elements. It is inteeded to be used for checking user client and organizations.
   * 
   * @param strList
   *          List to check in
   * @param strElement
   *          Element to check in the list
   * @return true in case the element is in the list
   */
  public static boolean isElementInList(String strList, String strElement) {
    strList = strList.replace("(", "").replace(")", "");
    final StringTokenizer st = new StringTokenizer(strList, ",", false);
    strElement = strElement.replaceAll("'", "");

    while (st.hasMoreTokens()) {
      final String token = st.nextToken().trim().replaceAll("'", "");
      if (token.equals(strElement))
        return true;
    }
    return false;
  }

  /**
   * Returns a JavaScript function to be used on selectors Depending on what element you want to
   * focus, you pass the id
   * 
   * @param id
   *          the html tag id to focus on
   * @return a String JavaScript function
   */
  public static String focusFieldJS(String id) {
    final String r = "\n function focusOnField() { \n" + " setWindowElementFocus('" + id
        + "', 'id'); \n" + " return true; \n" + "} \n";
    return r;
  }

  /**
   * Write the output to a file. It creates a file in the file location writing the content of the
   * outputstream.
   * 
   * @param fileLocation
   *          the file where you are going to write
   * @param outputstream
   *          the data source
   */
  public static void dumpFile(String fileLocation, OutputStream outputstream) {
    final byte dataPart[] = new byte[4096];
    try {
      final BufferedInputStream bufferedinputstream = new BufferedInputStream(new FileInputStream(
          new File(fileLocation)));
      int i;
      while ((i = bufferedinputstream.read(dataPart, 0, 4096)) != -1)
        outputstream.write(dataPart, 0, i);
      bufferedinputstream.close();
    } catch (final Exception exception) {
    }
  }

  /**
   * Returns a string list comma separated as SQL strings.
   * 
   * @param list
   * @return comma delimited quoted string
   */
  public static String stringList(String list) {
    String ret = "";
    final boolean hasBrackets = list.startsWith("(") && list.endsWith(")");
    if (hasBrackets)
      list = list.substring(1, list.length() - 1);
    final StringTokenizer st = new StringTokenizer(list, ",", false);
    while (st.hasMoreTokens()) {
      String token = st.nextToken().trim();
      if (!ret.equals(""))
        ret += ", ";
      if (!(token.startsWith("'") && token.endsWith("'")))
        token = "'" + token + "'";
      ret += token;
    }
    if (hasBrackets)
      ret = "(" + ret + ")";
    return ret;
  }

  /**
   * Determines if a string of characters is an Openbravo UUID (Universal Unique Identifier), i.e.,
   * if it is a 32 length hexadecimal string.
   * 
   * @param CharacterString
   *          A string of characters.
   * @return Returns true if this string of characters is an UUID.
   */
  public static boolean isUUIDString(String CharacterString) {
    if (CharacterString.length() == 32) {
      for (int i = 0; i < CharacterString.length(); i++) {
        if (!isHexStringChar(CharacterString.charAt(i)))
          return false;
      }
      return true;
    }
    return false;
  }

  /**
   * Returns true if the input argument character is A-F, a-f or 0-9.
   * 
   * @param c
   *          A single character.
   * @return Returns true if this character is hexadecimal.
   */
  public static final boolean isHexStringChar(char c) {
    return (("0123456789abcdefABCDEF".indexOf(c)) >= 0);
  }

  /**
   * Deletes recursively a (non-empty) array of directories
   * 
   * @param f
   * @return true in case the deletion has been successful
   */
  public static boolean deleteDir(File[] f) {
    for (int i = 0; i < f.length; i++) {
      if (!deleteDir(f[i]))
        return false;
    }
    return true;
  }

  /**
   * Deletes recursively a (non-empty) directory
   * 
   * @param f
   * @return true in case the deletion has been successful
   */
  public static boolean deleteDir(File f) {
    if (f.isDirectory()) {
      final File elements[] = f.listFiles();
      for (int i = 0; i < elements.length; i++) {
        if (!deleteDir(elements[i]))
          return false;
      }
    }
    return f.delete();
  }

  /**
   * Generates a String representing the file in a path
   * 
   * @param strPath
   * @return file to a String
   */
  public static String fileToString(String strPath) throws FileNotFoundException {
    StringBuffer strMyFile = new StringBuffer("");
    try {
      File f = new File(strPath);
      FileInputStream fis = new FileInputStream(f);
      InputStreamReader isr = new InputStreamReader(fis, "UTF-8");

      final BufferedReader mybr = new BufferedReader(isr);

      String strTemp = mybr.readLine();
      strMyFile.append(strTemp);
      while (strTemp != null) {
        strTemp = mybr.readLine();
        if (strTemp != null)
          strMyFile.append("\n").append(strTemp);
        else {
          mybr.close();
          fis.close();
        }
      }
    } catch (final IOException e) {
      e.printStackTrace();
    }
    return strMyFile.toString();
  }

  /**
   * Generates a String representing the wikified name from source
   * 
   * @param strSource
   * @return strTarget: wikified name
   */
  public static String wikifiedName(String strSource) throws FileNotFoundException {
    if (strSource == null || strSource.equals(""))
      return strSource;
    strSource = strSource.trim();
    if (strSource.equals(""))
      return strSource;
    final StringTokenizer source = new StringTokenizer(strSource, " ", false);
    String strTarget = "";
    String strTemp = "";
    int i = 0;
    while (source.hasMoreTokens()) {
      strTemp = source.nextToken();
      if (i != 0)
        strTarget = strTarget + "_" + strTemp;
      else {
        final String strFirstChar = strTemp.substring(0, 1);
        strTemp = strFirstChar.toUpperCase() + strTemp.substring(1, strTemp.length());
        strTarget = strTarget + strTemp;
      }
      i++;
    }
    return strTarget;
  }

  public static String getButtonName(ConnectionProvider conn, VariablesSecureApp vars,
      String reference, String currentValue, String buttonId,
      HashMap<String, String> usedButtonShortCuts, HashMap<String, String> reservedButtonShortCuts) {
    try {
      final UtilityData[] data = UtilityData.selectReference(conn, vars.getLanguage(), reference);
      String retVal = "";
      if (currentValue.equals("--"))
        currentValue = "CL";
      if (data == null)
        return retVal;
      for (int j = 0; j < data.length; j++) {
        int i = 0;
        final String name = data[j].name;
        while ((i < name.length())
            && (name.substring(i, i + 1).equals(" ") || reservedButtonShortCuts.containsKey(name
                .substring(i, i + 1).toUpperCase()))) {
          if (data[j].value.equals(currentValue))
            retVal += name.substring(i, i + 1);
          i++;
        }
        if ((i == name.length()) && (data[j].value.equals(currentValue))) {
          i = 1;
          while (i <= 10 && reservedButtonShortCuts.containsKey(Integer.valueOf(i).toString()))
            i++;
          if (i < 10) {
            if (data[j].value.equals(currentValue)) {
              retVal += "<span>(<u>" + i + "</u>)</span>";
              reservedButtonShortCuts.put(Integer.valueOf(i).toString(), "");
              usedButtonShortCuts.put(Integer.valueOf(i).toString(), "executeWindowButton('" + buttonId
                  + "');");
            }
          }
        } else {

          if (data[j].value.equals(currentValue)) {
            if (i < name.length())
              reservedButtonShortCuts.put(name.substring(i, i + 1).toUpperCase(), "");
            usedButtonShortCuts.put(name.substring(i, i + 1).toUpperCase(), "executeWindowButton('"
                + buttonId + "');");
            retVal += "<u>" + name.substring(i, i + 1) + "</u>" + name.substring(i + 1);
          }
        }
      }

      return retVal;
    } catch (final Exception e) {
      log4j.error(e.toString());
      return currentValue;
    }
  }

  public static String getButtonName(ConnectionProvider conn, VariablesSecureApp vars,
      String fieldId, String buttonId, HashMap<String, String> usedButtonShortCuts,
      HashMap<String, String> reservedButtonShortCuts) {
    try {
      final UtilityData data = UtilityData.selectFieldName(conn, vars.getLanguage(), fieldId);
      String retVal = "";
      if (data == null)
        return retVal;
      final String name = data.name;
      int i = 0;
      while ((i < name.length())
          && (name.substring(i, i + 1).equals(" ") || reservedButtonShortCuts.containsKey(name
              .substring(i, i + 1).toUpperCase()))) {
        retVal += name.substring(i, i + 1);
        i++;
      }

      if (i == name.length()) {
        i = 1;
        while (i <= 10 && reservedButtonShortCuts.containsKey(Integer.valueOf(i).toString()))
          i++;
        if (i < 10) {
          retVal += "<span>(<u>" + i + "</u>)</span>";
          reservedButtonShortCuts.put(Integer.valueOf(i).toString(), "");
          usedButtonShortCuts.put(Integer.valueOf(i).toString(), "executeWindowButton('" + buttonId
              + "');");
        }
      } else {
        if (i < name.length())
          reservedButtonShortCuts.put(name.substring(i, i + 1).toUpperCase(), "");
        usedButtonShortCuts.put(name.substring(i, i + 1).toUpperCase(), "executeWindowButton('"
            + buttonId + "');");
        retVal += "<u>" + name.substring(i, i + 1) + "</u>" + name.substring(i + 1);
      }

      return retVal;
    } catch (final Exception e) {
      log4j.error(e.toString());
      return "";
    }
  }

  /**
   * Returns the ID of the base currency of the given client
   * 
   * @param strClientId
   *          ID of client.
   * @return Returns String strBaseCurrencyId with the ID of the base currency.
   * @throws ServletException
   */
  public static String stringBaseCurrencyId(ConnectionProvider conn, String strClientId)
      throws ServletException {
    final String strBaseCurrencyId = UtilityData.getBaseCurrencyId(conn, strClientId);
    return strBaseCurrencyId;
  }

  /**
   * Build a JavaScript variable used for prompting a confirmation on changes
   * 
   * @param vars
   *          Helper to access the user context
   * @param windowId
   *          Identifier of the window
   * @return A string containing a JavaScript variable to be used by the checkForChanges function
   *         (utils.js)
   */
  public static String getJSConfirmOnChanges(VariablesSecureApp vars, String windowId) {
    String jsString = "var confirmOnChanges = ";
    String showConfirmation = getPreference(vars, "ShowConfirmation", windowId);

    if (showConfirmation == null || showConfirmation.equals(""))
      showConfirmation = vars.getSessionValue("#ShowConfirmation");
    jsString = jsString + (showConfirmation.equalsIgnoreCase("Y") ? "true" : "false") + ";";
    return jsString;
  }

  /**
   * Transforms an ArrayList to a String comma separated.
   * 
   * @param list
   * @return a comma separated String containing the contents of the array.
   */
  public static String arrayListToString(ArrayList<String> list, boolean addQuotes) {
    String rt = "";
    for (int i = 0; i < list.size(); i++) {
      rt += rt.equals("") ? "" : ", " + (addQuotes ? "'" : "") + list.get(i)
          + (addQuotes ? "'" : "");
    }
    return rt;
  }

  /**
   * Transforms a comma separated String into an ArrayList
   * 
   * @param list
   * @return the list representation of the comma delimited String
   */
  public static ArrayList<String> stringToArrayList(String list) {
    final ArrayList<String> rt = new ArrayList<String>();
    final StringTokenizer st = new StringTokenizer(list, ",");
    while (st.hasMoreTokens()) {
      final String token = st.nextToken().trim();
      rt.add(token);
    }
    return rt;
  }

  /**
   * Transforms a String[] into an ArrayList
   * 
   * @param list
   * @return the list representation of the array
   */
  public static ArrayList<String> stringToArrayList(String[] list) {
    final ArrayList<String> rt = new ArrayList<String>();
    if (list == null)
      return rt;
    for (int i = 0; i < list.length; i++)
      rt.add(list[i]);
    return rt;
  }

  /**
   * Returns the ISO code plus the symbol of the given currency in the form (ISO-SYM), e.g., (USD-$)
   * 
   * @param strCurrencyID
   *          ID of the currency.
   * @return Returns String strISOSymbol with the ISO code plus the symbol of the currency.
   * @throws ServletException
   */
  public static String stringISOSymbol(ConnectionProvider conn, String strCurrencyID)
      throws ServletException {
    final String strISOSymbol = UtilityData.getISOSymbol(conn, strCurrencyID);
    return strISOSymbol;
  }

  @Deprecated
  public static boolean hasFormAccess(ConnectionProvider conn, VariablesSecureApp vars,
      String process) {
    return hasFormAccess(conn, vars, process, "");
  }

  @Deprecated
  public static boolean hasFormAccess(ConnectionProvider conn, VariablesSecureApp vars,
      String process, String processName) {
    try {
      if (process.equals("") && processName.equals(""))
        return true;
      else if (!process.equals("")) {

        if (!WindowAccessData.hasFormAccess(conn, vars.getRole(), process))
          return false;
      } else {
        if (!WindowAccessData.hasFormAccessName(conn, vars.getRole(), processName))
          return false;
      }
    } catch (final ServletException e) {
      return false;
    }
    return true;
  }

  @Deprecated
  public static boolean hasProcessAccess(ConnectionProvider conn, VariablesSecureApp vars,
      String process) {
    return hasProcessAccess(conn, vars, process, "");
  }

  @Deprecated
  public static boolean hasProcessAccess(ConnectionProvider conn, VariablesSecureApp vars,
      String process, String processName) {
    try {
      if (process.equals("") && processName.equals(""))
        return true;
      else if (!process.equals("")) {
        if (!WindowAccessData.hasProcessAccess(conn, vars.getRole(), process))
          return false;
      } else {
        if (!WindowAccessData.hasProcessAccessName(conn, vars.getRole(), processName))
          return false;
      }
    } catch (final ServletException e) {
      return false;
    }
    return true;
  }

  @Deprecated
  public static boolean hasTaskAccess(ConnectionProvider conn, VariablesSecureApp vars, String task) {
    return hasTaskAccess(conn, vars, task, "");
  }

  @Deprecated
  public static boolean hasTaskAccess(ConnectionProvider conn, VariablesSecureApp vars,
      String task, String taskName) {
    try {
      if (task.equals("") && taskName.equals(""))
        return true;
      else if (!task.equals("")) {
        if (!WindowAccessData.hasTaskAccess(conn, vars.getRole(), task))
          return false;
      } else if (!WindowAccessData.hasTaskAccessName(conn, vars.getRole(), taskName))
        return false;
    } catch (final ServletException e) {
      return false;
    }
    return true;
  }

  @Deprecated
  public static boolean hasWorkflowAccess(ConnectionProvider conn, VariablesSecureApp vars,
      String workflow) {
    try {
      if (workflow.equals(""))
        return true;
      else {
        if (!WindowAccessData.hasWorkflowAccess(conn, vars.getRole(), workflow))
          return false;
      }
    } catch (final ServletException e) {
      return false;
    }
    return true;
  }

  @Deprecated
  public static boolean hasAccess(ConnectionProvider conn, VariablesSecureApp vars,
      String TableLevel, String AD_Client_ID, String AD_Org_ID, String window, String tab) {
    final String command = vars.getCommand();
    try {
      if (!canViewInsert(conn, vars, TableLevel, window))
        return false;
      else if (!WindowAccessData.hasWindowAccess(conn, vars.getRole(), window))
        return false;
      else if (WindowAccessData.hasNoTableAccess(conn, vars.getRole(), tab))
        return false;
      else if (command.toUpperCase().startsWith("SAVE")) {
        if (!canUpdate(conn, vars, AD_Client_ID, AD_Org_ID, window))
          return false;
      } else if (command.toUpperCase().startsWith("DELETE")) {
        if (!canUpdate(conn, vars, AD_Client_ID, AD_Org_ID, window))
          return false;
      }
    } catch (final ServletException e) {
      return false;
    }
    return true;
  }

  @Deprecated
  public static boolean canViewInsert(ConnectionProvider conn, VariablesSecureApp vars,
      String TableLevel, String window) {
    final String User_Level = getContext(conn, vars, "#User_Level", window);

    boolean retValue = true;

    if (TableLevel.equals("4") && User_Level.indexOf("S") == -1)
      retValue = false;
    else if (TableLevel.equals("1") && User_Level.indexOf("O") == -1)
      retValue = false;
    else if (TableLevel.equals("3")
        && (!(User_Level.indexOf("C") != -1 || User_Level.indexOf("O") != -1)))
      retValue = false;
    else if (TableLevel.equals("6")
        && (!(User_Level.indexOf("S") != -1 || User_Level.indexOf("C") != -1)))
      retValue = false;

    if (retValue)
      return retValue;

    return retValue;
  }

  @Deprecated
  // in 2.50
  public static boolean hasAttachments(ConnectionProvider conn, String userClient, String userOrg,
      String tableId, String recordId) throws ServletException {
    if (tableId.equals("") || recordId.equals(""))
      return false;
    else
      return UtilityData.select(conn, userClient, userOrg, tableId, recordId);
  }

  /**
   * Determines the labor days between two dates
   * 
   * @param strDate1
   *          Date 1.
   * @param strDate2
   *          Date 2.
   * @param DateFormatter
   *          Format of the dates.
   * @return strLaborDays as the number of days between strDate1 and strDate2.
   */
  public static String calculateLaborDays(String strDate1, String strDate2, DateFormat DateFormatter)
      throws ParseException {
    String strLaborDays = "";
    if (strDate1 != null && !strDate1.equals("") && strDate2 != null && !strDate2.equals("")) {
      Integer LaborDays = 0;
      if (Utility.isBiggerDate(strDate1, strDate2, DateFormatter)) {
        do {
          strDate2 = Utility.addDaysToDate(strDate2, "1", DateFormatter); // Adds a day to the Date
          // 2 until it
          // reaches the Date 1
          if (!Utility.isWeekendDay(strDate2, DateFormatter))
            LaborDays++; // If it is not a weekend day, it adds a
          // day to the labor days
        } while (!strDate2.equals(strDate1));
      } else {
        do {
          strDate1 = Utility.addDaysToDate(strDate1, "1", DateFormatter); // Adds a day to the Date
          // 1 until it
          // reaches the Date 2
          if (!Utility.isWeekendDay(strDate1, DateFormatter))
            LaborDays++; // If it is not a weekend day, it adds a
          // day to the labor days
        } while (!strDate1.equals(strDate2));
      }
      strLaborDays = LaborDays.toString();
    }
    return strLaborDays;
  }

  /**
   * Adds an integer number of days to a given date
   * 
   * @param strDate
   *          Start date.
   * @param strDays
   *          Number of days to add.
   * @param DateFormatter
   *          Format of the date.
   * @return strFinalDate as the sum of strDate plus strDays.
   */
  public static String addDaysToDate(String strDate, String strDays, DateFormat DateFormatter)
      throws ParseException {
    String strFinalDate = "";
    if (strDate != null && !strDate.equals("") && strDays != null && !strDays.equals("")) {
      final Calendar FinalDate = Calendar.getInstance();
      FinalDate.setTime(DateFormatter.parse(strDate)); // FinalDate equals
      // to strDate
      FinalDate.add(Calendar.DATE, Integer.parseInt(strDays)); // FinalDate
      // equals
      // to
      // strDate
      // plus one
      // day
      strFinalDate = DateFormatter.format(FinalDate.getTime());
    }
    return strFinalDate;
  }

  /**
   * Determines the format of the date
   * 
   * @param vars
   *          Global variables.
   * @return DateFormatter as the format of the date.
   */
  public static DateFormat getDateFormatter(VariablesSecureApp vars) {
    String strFormat = vars.getSessionValue("#AD_SqlDateFormat").toString();
    strFormat = strFormat.replace('Y', 'y'); // Java accepts 'yy' for the
    // year
    strFormat = strFormat.replace('D', 'd'); // Java accepts 'dd' for the
    // day of the date
    final DateFormat DateFormatter = new SimpleDateFormat(strFormat);
    return DateFormatter;
  }

  /**
   * Determines if a day is a day of the weekend, i.e., Saturday or Sunday
   * 
   * @param strDay
   *          Given Date.
   * @param DateFormatter
   *          Format of the date.
   * @return true if the date is a Sunday or a Saturday.
   */
  public static boolean isWeekendDay(String strDay, DateFormat DateFormatter) throws ParseException {
    final Calendar Day = Calendar.getInstance();
    Day.setTime(DateFormatter.parse(strDay));
    final int weekday = Day.get(Calendar.DAY_OF_WEEK); // Gets the number of
    // the day of the
    // week: 1-Sunday,
    // 2-Monday,
    // 3-Tuesday,
    // 4-Wednesday,
    // 5-Thursday,
    // 6-Friday,
    // 7-Saturday
    if (weekday == 1 || weekday == 7)
      return true; // 1-Sunday, 7-Saturday
    return false;
  }

  /**
   * Determines if a date 1 is bigger than a date 2
   * 
   * @param strDate1
   *          Date 1.
   * @param strDate2
   *          Date 2.
   * @param DateFormatter
   *          Format of the dates.
   * @return true if strDate1 is bigger than strDate2.
   */
  public static boolean isBiggerDate(String strDate1, String strDate2, DateFormat DateFormatter)
      throws ParseException {
    final Calendar Date1 = Calendar.getInstance();
    Date1.setTime(DateFormatter.parse(strDate1));
    final long MillisDate1 = Date1.getTimeInMillis();
    final Calendar Date2 = Calendar.getInstance();
    Date2.setTime(DateFormatter.parse(strDate2));
    final long MillisDate2 = Date2.getTimeInMillis();
    if (MillisDate1 > MillisDate2)
      return true; // Date 1 is bigger than Date 2
    return false;
  } 

  // Logik A ohne JasperReportnamen <- Legacy-Methode
  public static JasperReport getTranslatedJasperReport(ConnectionProvider conn,
		  String reportName,
		  String language,
		  String baseDesignPath) throws JRException {

    log4j.debug("translate report: " + reportName + " for language: " + language);

    File reportFile = new File(reportName);
	InputStream reportInputStream = createTranslatedStream(reportFile, conn,
				reportName, language, baseDesignPath); 

    return createReport(reportName, language, reportInputStream); 
  }

  private static JasperReport createReport(String reportName,
		  String language,
		  InputStream reportInputStream) throws JRException {


      String newReportName = FilenameUtils.removeExtension(reportName) + "_" + language + ".jasper"; 
      String fileExtension = FilenameUtils.getExtension(reportName);
      
      if(fileExtension.equals("jasper")) {
		return createJasperReport(reportName);
      }
      else if(new File(newReportName).isFile()) {
		return createJasperReport(newReportName);
      }
      else if(fileExtension.equals("jrxml")) {
		return createJRXMLReport(reportName, newReportName, language, reportInputStream);
      }

      return null;
  }
  
  // Logik B mit JasperReportnamen
  public static JasperReport getTranslatedJasperReport(ConnectionProvider conn,
		  String reportName,
		  String newReportName,
		  String language,
		  String baseDesignPath) throws JRException {

    log4j.debug("translate report: " + reportName + " for language: " + language);

    File reportFile = new File(reportName);
	InputStream reportInputStream = createTranslatedStream(reportFile, conn,
				reportName, language, baseDesignPath); 

    return createReport(reportName, newReportName, language, reportInputStream); 
  }

  private static InputStream createTranslatedStream(File reportFile, ConnectionProvider conn, 
		  String reportName, String language, String baseDesignPath) {

    if (reportFile.exists()) {
      TranslationHandler handler = new TranslationHandler(conn);
      handler.prepareFile(reportName, language, reportFile, baseDesignPath);
      return handler.getInputStream();
    }

    return null;
  }

  // der newReportName wird nur gebraucht wenn eine jrxml-Datei in eine jasper-Datei compiliert wird
  private static JasperReport createReport(String reportName,
		  String newReportName,
		  String language,
		  InputStream reportInputStream) throws JRException {

      String fileExtension = FilenameUtils.getExtension(reportName);

      if(fileExtension.equals("jrxml")) {
		return createJRXMLReport(reportName, newReportName, language, reportInputStream);
      }
      else if(fileExtension.equals("jasper")) {
		return createJasperReport(reportName);
      }

      return null;
  }

  private static JasperReport createJRXMLReport(String oldReportName,
		  String newReportName,
		  String language,
		  InputStream reportInputStream) throws JRException {

    JasperDesign jasperDesign;

    if (reportInputStream != null) {
      log4j.debug("Jasper design being created with inputStream.");
      jasperDesign = JRXmlLoader.load(reportInputStream);
    } else {
      log4j.debug("Jasper design being created with strReportName.");
      jasperDesign = JRXmlLoader.load(oldReportName);
    }

    writeJasperReportToFile(newReportName, jasperDesign);
    return createJasperReport(newReportName);
  }
  
  private static void writeJasperReportToFile(String newReportName, JasperDesign jasperDesign) throws JRException {
    JasperCompileManager.compileReportToFile(jasperDesign, newReportName);
  }

  private static JasperReport createJasperReport(String reportName) throws JRException {

      log4j.debug("Jasper report being created with strReportName.");
       return(JasperReport)JRLoader.loadObjectFromFile(reportName);
  }


  /**
   * Returns the complete URL for a tab
   * 
   * @param servlet
   * @param tabId
   *          Id for the tab to obtain the url for
   * @param type
   *          "R" -> Relation, "E" -> Edition, "X" -> Excel
   * @return the complete URL for a tab.
   */
  public static String getTabURL(HttpSecureAppServlet servlet, String tabId, String type) {
    return getTabURL((ConnectionProvider) servlet, tabId, type);
  }

  public static String getTabURL(ConnectionProvider conn, String tabId, String type) {
    if (!(type.equals("R") || type.equals("E") || type.equals("X")))
      type = "E";
    try {
      return HttpBaseServlet.strDireccion  + TabData.selectUrl(conn, tabId, type);
    } catch (Exception e) {
      log4j.error(e.getMessage());
      return "";
    }
  }

  /**
   * Determine if a String can be parsed into a BigDecimal.
   * 
   * @param str
   *          a String
   * @return true if the string can be parsed
   */
  public static boolean isBigDecimal(String str) {
    try {
      new BigDecimal(str.trim());
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * When updating core it is necessary to update Openbravo properties maintaining already assigned
   * properties. Thus properties in original file are preserved but the new ones in
   * Openbravo.properties.template file are added with the default value.
   * 
   * @throws IOException
   * @throws FileNotFoundException
   * @return false in case no changes where needed, true in case the merge includes some changes and
   *         the original file is modified
   */
  public static boolean mergeOpenbravoProperties(String originalFile, String newFile)
      throws FileNotFoundException, IOException {
    Properties origOBProperties = new Properties();
    Properties newOBProperties = new Properties();
    boolean modified = false;

    // load both files
    origOBProperties.load(new FileInputStream(originalFile));
    newOBProperties.load(new FileInputStream(newFile));

    Enumeration<?> newProps = newOBProperties.propertyNames();
    while (newProps.hasMoreElements()) {
      String propName = (String) newProps.nextElement();
      String origValue = origOBProperties.getProperty(propName);

      // try to get original value for new property, if it does not exist add it to original
      // properties with its default value
      if (origValue == null) {
        String newValue = newOBProperties.getProperty(propName);
        origOBProperties.setProperty(propName, newValue);
        modified = true;
      }
    }

    // save original file only in case it has modifications
    if (modified) {
      origOBProperties
          .store(new FileOutputStream(originalFile), "Automatically updated properties");
    }
    return modified;
  }

  /**
   * Returns the name for a value in a list reference in the selected language.
   * 
   * @param ListName
   *          Name for the reference list to look in
   * @param value
   *          Value to look for
   * @param lang
   *          Language, if null the default language will be returned
   * @return Name for the value, in case the value is not found in the list the return is not the
   *         name but the passed value
   */
  public static String getListValueName(String ListName, String value, String lang) {
    // Try to obtain the translated value
    String hql = "  select rlt.name as name " + " from ADReference r, " + "      ADList rl,"
        + "      ADListTrl rlt" + " where rl.reference = r" + "  and rlt.listReference = rl"
        + "  and rlt.language.language = '" + lang + "'" + "  and r.name =  '" + ListName + "'"
        + "  and rl.searchKey = '" + value + "'";
    Query q = OBDal.getInstance().getSession().createQuery(hql);

    if (q.list().size() > 0) {
      return (String) q.list().get(0);
    }

    // No translated value obtained, get the standard one
    hql = "  select rl.name " + " from ADReference r, " + "      ADList rl"
        + " where rl.reference = r" + "  and r.name =  '" + ListName + "'"
        + "  and rl.searchKey = '" + value + "'";
    q = OBDal.getInstance().getSession().createQuery(hql);

    if (q.list().size() > 0) {
      return (String) q.list().get(0);
    } else {
      // Nothing found, return the value
      return value;
    }
  }

  /**
   * Constructs and returns a two dimensional array of the data passed. Array definition is
   * constructed according to Javascript syntax. Used to generate data storage of lists or trees
   * within some manual windows/reports.
   * 
   * @param strArrayName
   *          String with the name of the array to be defined.
   * @param data
   *          FieldProvider object with the data to be included in the array with the following
   *          three columns mandatory: padre | id | name.
   * @return String containing array definition according to Javascript syntax.
   */
  public static String arrayDobleEntrada(String strArrayName, FieldProvider[] data) {
    String strArray = "var " + strArrayName + " = ";
    if (data.length == 0) {
      strArray = strArray + "null";
      return strArray;
    }
    strArray = strArray + "new Array(";
    for (int i = 0; i < data.length; i++) {
      strArray = strArray + "\nnew Array(\"" + data[i].getField("padre") + "\", \""
          + data[i].getField("id") + "\", \"" + FormatUtilities.replaceJS(data[i].getField("name"))
          + "\")";
      if (i < data.length - 1)
        strArray = strArray + ", ";
    }
    strArray = strArray + ");";
    return strArray;
  }

  /**
   * Constructs and returns a two dimensional array of the data passed. Array definition is
   * constructed according to Javascript syntax. Used to generate data storage of lists or trees
   * within some manual windows/reports.
   * 
   * @param strArrayName
   *          String with the name of the array to be defined.
   * @param data
   *          FieldProvider object with the data to be included in the array with the following two
   *          columns mandatory: id | name.
   * @return String containing array definition according to Javascript syntax.
   */
  public static String arrayEntradaSimple(String strArrayName, FieldProvider[] data) {
    String strArray = "var " + strArrayName + " = ";
    if (data.length == 0) {
      strArray = strArray + "null";
      return strArray;
    }
    strArray = strArray + "new Array(";
    for (int i = 0; i < data.length; i++) {
      strArray = strArray + "\nnew Array(\"" + data[i].getField("id") + "\", \""
          + FormatUtilities.replaceJS(data[i].getField("name")) + "\")";
      if (i < data.length - 1)
        strArray = strArray + ", ";
    }
    strArray = strArray + ");";
    return strArray;
  }

  /**
   * Gets the reference list for a particular reference id
   * 
   * @param connectionProvider
   * @param language
   * @param referenceId
   * @return refValues string array containing reference values
   * @throws ServletException
   */
  public static String[] getReferenceValues(ConnectionProvider connectionProvider, String language,
      String referenceId) throws ServletException {
    String[] refValues = null;
    if (referenceId != null) {
      UtilityData[] datas = UtilityData.selectReference(connectionProvider, language, referenceId);
      if (datas != null) {
        int i = 0;
        refValues = new String[datas.length];
        for (UtilityData reference : datas) {
          refValues[i++] = reference.getField("value");
        }
      }
    }
    return refValues;
  }

  /**
   * Returns a DecimalFormat for the given formatting type contained in the Format.xml file
   */
  public static DecimalFormat getFormat(VariablesSecureApp vars, String typeName) {
    String format = vars.getSessionValue("#FormatOutput|" + typeName);
    String decimal = vars.getSessionValue("#DecimalSeparator|" + typeName);
    String group = vars.getSessionValue("#GroupSeparator|" + typeName);
    DecimalFormat numberFormatDecimal = null;
    if (format != null && !format.equals("") && decimal != null && !decimal.equals("")
        && group != null && !group.equals("")) {
      DecimalFormatSymbols dfs = new DecimalFormatSymbols();
      dfs.setDecimalSeparator(decimal.charAt(0));
      dfs.setGroupingSeparator(group.charAt(0));
      numberFormatDecimal = new DecimalFormat(format, dfs);
    }
    return numberFormatDecimal;
  }

}
