/******************************************************************************
 * The contents of this file are subject to the   Compiere License  Version 1.1
 * ("License"); You may not use this file except in compliance with the License
 * You may obtain a copy of the License at http://www.compiere.org/license.html
 * Software distributed under the License is distributed on an  "AS IS"  basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 * The Original Code is                  Compiere  ERP & CRM  Business Solution
 * The Initial Developer of the Original Code is Jorg Janke  and ComPiere, Inc.
 * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke, parts
 * created by ComPiere are Copyright (C) ComPiere, Inc.;   All Rights Reserved.
 * Contributor(s): Openbravo SL
 * Contributions are Copyright (C) 2001-2009 Openbravo S.L.
 ******************************************************************************/
package org.openbravo.erpCommon.ad_forms;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.sql.ResultSet;
import java.sql.Statement;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * Class for import/export languages.
 * 
 * The tree of languages is:
 * 
 * {attachmentsDir} {laguageFolder} {moduleFolder}
 * 
 * Example: /opt/attachments/ en_US/ <trl tables from core> module1/ <trl tables from module1>
 * 
 */
public class Translation extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  /** XML Element Tag */
  static final String XML_TAG = "compiereTrl";
  /** XML Attribute Table */
  static final String XML_ATTRIBUTE_TABLE = "table";
  /** XML Attribute Language */
  static final String XML_ATTRIBUTE_LANGUAGE = "language";
  /** XML row attribute original language */
  static final String XML_ATTRIBUTE_BASE_LANGUAGE = "baseLanguage";
  /** XML Attribute Version */
  static final String XML_ATTRIBUTE_VERSION = "version";
  /** XML Row Tag */

  static final String XML_ROW_TAG = "row";
  /** XML Row Attribute ID */
  static final String XML_ROW_ATTRIBUTE_ID = "id";
  /** XML Row Attribute Translated */
  static final String XML_ROW_ATTRIBUTE_TRANSLATED = "trl";

  /** XML Value Tag */
  static final String XML_VALUE_TAG = "value";
  /** XML Value Column */
  static final String XML_VALUE_ATTRIBUTE_COLUMN = "column";
  /** XML Value Original */
  static final String XML_VALUE_ATTRIBUTE_ORIGINAL = "original";
  /** XML Value Original */
  static final String XML_VALUE_ATTRIBUTE_ISTRL = "isTrl";

  static final String CONTRIBUTORS_FILENAME = "CONTRIBUTORS";
  static final String XML_CONTRIB = "Contributors";

  private static Logger translationlog4j;
  private static ConnectionProvider cp;

  @Override
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    final VariablesSecureApp vars = new VariablesSecureApp(request);
    System.setProperty("javax.xml.transform.TransformerFactory",
        "com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl"); // added
    // for
    // JDK1.5
    setLog4j(log4j);
    setConnectionProvicer(this);
    if (vars.commandIn("DEFAULT")) {
      printPageDataSheet(response, vars);
    } else if (vars.commandIn("EXPORT")) {

      final String strLang = vars.getRequestGlobalVariable("language", "translation.lang");
      // import/export translation is currently always on system level
      final String strClient = "0";
      if (log4j.isDebugEnabled())
        log4j.debug("Lang " + strLang + " Client " + strClient);

      // New message system
      final OBError myMessage = exportTrl(strLang, strClient, vars);

      if (log4j.isDebugEnabled())
        log4j.debug("message:" + myMessage.getMessage());
      vars.setMessage("Translation", myMessage);
      response.sendRedirect(strDireccion + request.getServletPath());

    } else {
      final String strLang = vars.getRequestGlobalVariable("language", "translation.lang");
      // import/export translation is currently always on system level
      final String strClient = "0";
      if (log4j.isDebugEnabled())
        log4j.debug("Lang " + strLang + " Client " + strClient);

      final String directory = globalParameters.strFTPDirectory + "/lang/" + strLang + "/";
      final OBError myMessage = importTrlDirectory(directory, strLang, strClient, vars);
      if (log4j.isDebugEnabled())
        log4j.debug("message:" + myMessage.getMessage());
      vars.setMessage("Translation", myMessage);
      response.sendRedirect(strDireccion + request.getServletPath());

    }
  }

  public static void setConnectionProvicer(ConnectionProvider conn) {
    cp = conn;
  }

  public static void setLog4j(Logger logger) {
    translationlog4j = logger;
  }

  /**
   * Export all the trl tables that refers to tables with ad_module_id column or trl tables that
   * refers to tables with a parent table with ad_module_id column
   * 
   * For example: If a record from ad_process is in module "core", the records from ad_process_trl
   * and ad_process_para_trl are exported in "core" module
   * 
   * @param strLang
   *          Language to export.
   * @param strClient
   *          Client to export.
   * @param vars
   *          Handler for the session info.
   * @return Message with the error or with the success
   */
  private OBError exportTrl(String strLang, String strClient, VariablesSecureApp vars) {
    final String AD_Language = strLang;
    OBError myMessage = null;

    myMessage = new OBError();
    myMessage.setTitle("");
    final int AD_Client_ID = Integer.valueOf(strClient);

    final String strFTPDirectory = globalParameters.strFTPDirectory;

    if (new File(strFTPDirectory).canWrite()) {
      if (log4j.isDebugEnabled())
        log4j.debug("can write...");
    } else {
      log4j.error("Can't write on directory: " + strFTPDirectory);
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, "CannotWriteDirectory", vars.getLanguage())
          + " " + strFTPDirectory);
      return myMessage;
    }

    (new File(strFTPDirectory + "/lang")).mkdir();
    final String rootDirectory = strFTPDirectory + "/lang/";
    final String directory = strFTPDirectory + "/lang/" + AD_Language + "/";
    (new File(directory)).mkdir();

    if (log4j.isDebugEnabled())
      log4j.debug("directory " + directory);

    try {
      final TranslationData[] modulesTables = TranslationData.trlModulesTables(this);

      for (int i = 0; i < modulesTables.length; i++) {
        exportModulesTrl(rootDirectory, AD_Client_ID, AD_Language, modulesTables[i].c);
      }
      // We need to also export translations for some tables which are considered reference data
      // and are imported using datasets (such as Masterdata: UOMs, Currencies, ...)
      exportReferenceData(rootDirectory, AD_Language);

      exportContibutors(directory, AD_Language);
    } catch (final Exception e) {
      log4j.error(e);
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, "Error", vars.getLanguage()));
      return myMessage;
    }
    myMessage.setType("Success");
    myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    return myMessage;
  }

  /**
   * 
   * The import process insert in database all the translations found in the folder of the defined
   * language RECURSIVELY. It don't take into account if a module is marked o no as isInDevelopment.
   * Only search for trl's xml files corresponding with trl's tables in database.
   * 
   * 
   * @param directory
   *          Directory for trl's xml files
   * @param strLang
   *          Language to import
   * @param strClient
   *          Client to import
   * @param vars
   *          Handler for the session info.
   * @return Message with the error or with the success
   */
  public static OBError importTrlDirectory(String directory, String strLang, String strClient,
      VariablesSecureApp vars) {
    final String AD_Language = strLang;

    OBError myMessage = null;
    myMessage = new OBError();
    myMessage.setTitle("");

    final String UILanguage = vars == null ? "en_US" : vars.getLanguage();

    if ((new File(directory).exists()) && (new File(directory).canRead())) {
      if (translationlog4j.isDebugEnabled())
        translationlog4j.debug("can read " + directory);
    } else {
      translationlog4j.error("Can't read on directory: " + directory);
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(cp, "CannotReadDirectory", UILanguage) + " "
          + directory);
      return myMessage;
    }

    final int AD_Client_ID = Integer.valueOf(strClient);
    try {
      final TranslationData[] tables = TranslationData.trlTables(cp);
      for (int i = 0; i < tables.length; i++)
        importTrlFile(directory, AD_Client_ID, AD_Language, tables[i].c);
      importContributors(directory, AD_Language);
    } catch (final Exception e) {
      translationlog4j.error(e.toString());
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(cp, "Error", UILanguage));
      return myMessage;
    }

    final File file = new File(directory);
    final File[] list = file.listFiles();
    for (int f = 0; f < list.length; f++) {
      if (list[f].isDirectory()) {
        final OBError subDirError = importTrlDirectory(list[f].toString() + "/", strLang,
            strClient, vars);
        if (!"Success".equals(subDirError.getType()))
          return subDirError;
      }
    }

    myMessage.setType("Success");
    myMessage.setMessage(Utility.messageBD(cp, "Success", UILanguage));
    return myMessage;
  }

  private void exportContibutors(String directory, String AD_Language) {
    final File out = new File(directory, CONTRIBUTORS_FILENAME + "_" + AD_Language + ".xml");
    try {
      @SuppressWarnings( "deprecation" )
      final DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      final DocumentBuilder builder = factory.newDocumentBuilder();
      final Document document = builder.newDocument();
      final Element root = document.createElement(XML_CONTRIB);
      root.setAttribute(XML_ATTRIBUTE_LANGUAGE, AD_Language);
      document.appendChild(root);
      root.appendChild(document.createTextNode(TranslationData
          .selectContributors(this, AD_Language)));
      final DOMSource source = new DOMSource(document);
      @SuppressWarnings( "deprecation" )
      final TransformerFactory tFactory = TransformerFactory.newInstance();
      final Transformer transformer = tFactory.newTransformer();
      // Output
      out.createNewFile();
      final StreamResult result = new StreamResult(out);
      // Transform
      transformer.transform(source, result);
    } catch (final Exception e) {
      log4j.error("exportTrl", e);
    }
  }

  private void exportReferenceData(String rootDirectory, String AD_Language) {
    try {
      // Export translations for reference data (do not take into account
      // client data, only system)
      final TranslationData[] referenceTrlData = TranslationData.referenceDataTrl(this);
      for (final TranslationData refTrl : referenceTrlData) {
        exportTable(AD_Language, true, refTrl.isindevelopment.equals("Y"), refTrl.tablename
            .toUpperCase(), refTrl.adTableId, rootDirectory, refTrl.adModuleId, refTrl.adLanguage,
            refTrl.value, true);
      }
    } catch (final Exception e) {
      e.printStackTrace();
    }
  }

  private String exportModulesTrl(String rootDirectory, int AD_Client_ID, String AD_Language,
      String Trl_Table) {
    try {
      final TranslationData[] modules = TranslationData.modules(this);
      for (int mod = 0; mod < modules.length; mod++) {
        final String moduleLanguage = TranslationData.selectModuleLang(this,
            modules[mod].adModuleId);
        if (moduleLanguage != null && !moduleLanguage.equals("")) {
          // only
          // languages
          // different
          // than the
          // modules's
          // one

          final String tableName = Trl_Table;
          final int pos = tableName.indexOf("_TRL");
          final String Base_Table = Trl_Table.substring(0, pos);
          boolean trl = true;

          if (moduleLanguage.equals(AD_Language))
            trl = false;
          exportTable(AD_Language, false, false, Base_Table, "0", rootDirectory,
              modules[mod].adModuleId, moduleLanguage, modules[mod].value, trl);

        } // translate or not (if)
      }
    } catch (final Exception e) {
      log4j.error("exportTrl", e);
    }
    return "";
  } // exportModulesTrl

  /**
   * Exports a single trl table in a xml file
   * 
   * @param AD_Language
   *          Language to export
   * @param exportReferenceData
   *          Defines whether exporting reference data
   * @param exportAll
   *          In case it is reference data if it should be exported all data or just imported
   * @param table
   *          Base table
   * @param tableID
   *          Base table id
   * @param rootDirectory
   *          Root directory to the the exportation
   * @param moduleId
   *          Id for the module to export to
   * @param moduleLanguage
   *          Base language for the module
   * @param javaPackage
   *          Java package for the module
   */
  private void exportTable(String AD_Language, boolean exportReferenceData, boolean exportAll,
      String table, String tableID, String rootDirectory, String moduleId, String moduleLanguage,
      String javaPackage, boolean trl) {

    Statement st = null;
    try {
      String trlTable = table;
      if (trl && !table.endsWith("_TRL"))
        trlTable = table + "_TRL";
      final TranslationData[] trlColumns = getTrlColumns(table);
      final String keyColumn = table + "_ID";

      boolean m_IsCentrallyMaintained = false;
      try {
        m_IsCentrallyMaintained = !(TranslationData.centrallyMaintained(cp, table).equals("0"));
        if (m_IsCentrallyMaintained)
          log4j.debug("table:" + table + " IS centrally maintained");
        else
          log4j.debug("table:" + table + " is NOT centrally maintained");
      } catch (final Exception e) {
        translationlog4j.error("getTrlColumns (IsCentrallyMaintained)", e);
      }

      // Prepare query to retrieve translated rows
      final StringBuffer sql = new StringBuffer("SELECT ");
      if (trl)
        sql.append("t.IsTranslated,");
      else
        sql.append("'N', ");
      sql.append("t.").append(keyColumn);

      for (int i = 0; i < trlColumns.length; i++) {
        sql.append(", t.").append(trlColumns[i].c).append(",o.").append(trlColumns[i].c).append(
            " AS ").append(trlColumns[i].c).append("O");
      }

      sql.append(" FROM ").append(trlTable).append(" t").append(", ").append(table).append(" o");

      if (exportReferenceData && !exportAll) {
        sql.append(", AD_REF_DATA_LOADED DL");
      }

      sql.append(" WHERE ");
      if (trl)
        sql.append("t.AD_Language='" + AD_Language + "'").append(" AND ");
      sql.append("o.").append(keyColumn).append("= t.").append(keyColumn);

      if (m_IsCentrallyMaintained) {
        sql.append(" AND ").append("o.IsCentrallyMaintained='N'");
      }
      // AdClient !=0 not supported
      sql.append(" AND o.AD_Client_ID='0' ");

      if (!exportReferenceData) {
        String strParentTable = null;
        String tempTrlTableName = trlTable;
        if (!tempTrlTableName.toLowerCase().endsWith("_trl"))
          tempTrlTableName = tempTrlTableName + "_Trl";
        final TranslationData[] parentTable = TranslationData.parentTable(this, tempTrlTableName);
        if (parentTable.length > 0) {
          strParentTable = parentTable[0].tablename;
        }
        if (strParentTable == null) {
          sql.append(" AND ").append(" o.ad_module_id='").append(moduleId).append("'");
        } else {
          /** Search for ad_module_id in the parent table */
          sql.append(" AND ");
          sql.append(" exists ( select 1 from ").append(strParentTable).append(" p ");
          sql.append("   where p.").append(strParentTable + "_ID").append("=").append(
              "o." + strParentTable + "_ID");
          sql.append("   and p.ad_module_id='").append(moduleId).append("')");
        }
      }
      if (exportReferenceData && !exportAll) {
        sql.append(" AND DL.GENERIC_ID = o.").append(keyColumn).append(" AND DL.AD_TABLE_ID = '")
            .append(tableID).append("'").append(" AND DL.AD_MODULE_ID = '").append(moduleId)
            .append("'");
      }

      sql.append(" ORDER BY t.").append(keyColumn);
      //

      if (log4j.isDebugEnabled())
        log4j.debug("SQL:" + sql.toString());
      st = this.getStatement();
      if (log4j.isDebugEnabled())
        log4j.debug("st");

      final ResultSet rs = st.executeQuery(sql.toString());
      if (log4j.isDebugEnabled())
        log4j.debug("rs");
      int rows = 0;
      boolean hasRows = false;

      DocumentBuilder builder = null;
      Document document = null;
      Element root = null;
      File out = null;

      // Create xml file

      String directory = "";
      @SuppressWarnings( "deprecation" )
      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      builder = factory.newDocumentBuilder();
      document = builder.newDocument();
      // Root
      root = document.createElement(XML_TAG);
      root.setAttribute(XML_ATTRIBUTE_LANGUAGE, AD_Language);
      root.setAttribute(XML_ATTRIBUTE_TABLE, table);
      root.setAttribute(XML_ATTRIBUTE_BASE_LANGUAGE, moduleLanguage);
      root.setAttribute(XML_ATTRIBUTE_VERSION, TranslationData.version(this));
      document.appendChild(root);

      if (moduleId.equals("0"))
        directory = rootDirectory + AD_Language + "/";
      else
        directory = rootDirectory + AD_Language + "/" + javaPackage + "/";
      if (!new File(directory).exists())
        (new File(directory)).mkdir();

      String fileName = directory + trlTable + "_" + AD_Language + ".xml";
      log4j.info("exportTrl - " + fileName);
      out = new File(fileName);

      while (rs.next()) {
        if (!hasRows && !exportReferenceData) { // Create file only in
          // case it has contents
          // or it is not rd
          hasRows = true;
          @SuppressWarnings( "deprecation" )
          DocumentBuilderFactory factory2 = DocumentBuilderFactory.newInstance();
          builder = factory2.newDocumentBuilder();
          document = builder.newDocument();
          // Root
          root = document.createElement(XML_TAG);
          root.setAttribute(XML_ATTRIBUTE_LANGUAGE, AD_Language);
          root.setAttribute(XML_ATTRIBUTE_TABLE, table);
          root.setAttribute(XML_ATTRIBUTE_BASE_LANGUAGE, moduleLanguage);
          root.setAttribute(XML_ATTRIBUTE_VERSION, TranslationData.version(this));
          document.appendChild(root);

          if (moduleId.equals("0"))
            directory = rootDirectory + AD_Language + "/";
          else
            directory = rootDirectory + AD_Language + "/" + javaPackage + "/";
          if (!new File(directory).exists())
            (new File(directory)).mkdir();

          fileName = directory + trlTable + "_" + AD_Language + ".xml";
          log4j.info("exportTrl - " + fileName);
          out = new File(fileName);
        }

        final Element row = document.createElement(XML_ROW_TAG);
        row.setAttribute(XML_ROW_ATTRIBUTE_ID, String.valueOf(rs.getString(2))); // KeyColumn
        row.setAttribute(XML_ROW_ATTRIBUTE_TRANSLATED, rs.getString(1)); // IsTranslated
        for (int i = 0; i < trlColumns.length; i++) {
          final Element value = document.createElement(XML_VALUE_TAG);
          value.setAttribute(XML_VALUE_ATTRIBUTE_COLUMN, trlColumns[i].c);
          String origString = rs.getString(trlColumns[i].c + "O"); // Original
          String isTrlString = "Y";
          // Value
          if (origString == null) {
            origString = "";
            isTrlString = "N";
          }
          String valueString = rs.getString(trlColumns[i].c); // Value
          if (valueString == null) {
            valueString = "";
            isTrlString = "N";
          }
          if (origString.equals(valueString))
            isTrlString = "N";
          value.setAttribute(XML_VALUE_ATTRIBUTE_ISTRL, isTrlString);
          value.setAttribute(XML_VALUE_ATTRIBUTE_ORIGINAL, origString);
          value.appendChild(document.createTextNode(valueString));
          row.appendChild(value);
        }
        root.appendChild(row);
        rows++;
      }
      rs.close();

      log4j.info("exportTrl - Records=" + rows + ", DTD=" + document.getDoctype());

      final DOMSource source = new DOMSource(document);
      @SuppressWarnings( "deprecation" )
      final TransformerFactory tFactory = TransformerFactory.newInstance();
      tFactory.setAttribute("indent-number", Integer.valueOf(2));
      final Transformer transformer = tFactory.newTransformer();
      transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
      transformer.setOutputProperty(OutputKeys.INDENT, "yes");
      // Output
      out.createNewFile();
      // Transform
      final OutputStreamWriter osw = new OutputStreamWriter(new FileOutputStream(out), "UTF-8");
      transformer.transform(source, new StreamResult(osw));
      osw.close();
    } catch (final Exception e) {
      log4j.error("exportTrl", e);
    } finally {
      try {
        if (st != null)
          releaseStatement(st);
      } catch (final Exception ignored) {
      }
    }

  }

  private static String importContributors(String directory, String AD_Language) {
    final String fileName = directory + File.separator + CONTRIBUTORS_FILENAME + "_" + AD_Language
        + ".xml";
    final File in = new File(fileName);
    if (!in.exists()) {
      final String msg = "File does not exist: " + fileName;
      translationlog4j.debug(msg);
      return msg;
    }
    try {
      final TranslationHandler handler = new TranslationHandler(cp);
      @SuppressWarnings( "deprecation" )
      final SAXParserFactory factory = SAXParserFactory.newInstance();
      final SAXParser parser = factory.newSAXParser();
      parser.parse(in, handler);
      return "";
    } catch (final Exception e) {
      translationlog4j.error("importContrib", e);
      return e.toString();
    }
  }

  private static String importTrlFile(String directory, int AD_Client_ID, String AD_Language,
      String Trl_Table) {
    final String fileName = directory + File.separator + Trl_Table + "_" + AD_Language + ".xml";
    translationlog4j.debug("importTrl - " + fileName);
    final File in = new File(fileName);
    if (!in.exists()) {
      final String msg = "File does not exist: " + fileName;
      translationlog4j.debug("importTrl - " + msg);
      return msg;
    }

    try {
      final TranslationHandler handler = new TranslationHandler(AD_Client_ID, cp);
      @SuppressWarnings( "deprecation" )
      final SAXParserFactory factory = SAXParserFactory.newInstance();
      // factory.setValidating(true);
      final SAXParser parser = factory.newSAXParser();
      parser.parse(in, handler);
      translationlog4j.info("importTrl - Updated=" + handler.getUpdateCount() + " - from file "
          + fileName);
      // return Msg.getMsg(Env.getCtx(), "Updated") + "=" +
      // handler.getUpdateCount();
      return "";
    } catch (final Exception e) {
      translationlog4j.error("importTrlFile - error parsing file: " + fileName, e);
      return e.toString();
    }
  } // importTrl

  private TranslationData[] getTrlColumns(String Base_Table) {

    TranslationData[] list = null;

    try {
      list = TranslationData.trlColumns(cp, Base_Table + "_TRL");
    } catch (final Exception e) {
      translationlog4j.error("getTrlColumns", e);
    }
    return list;
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = null;

    xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/ad_forms/Translation")
        .createXmlDocument();
    final ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "Translation", false, "", "", "",
        false, "ad_forms", strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());
    try {
      final WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_forms.Translation");
      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      final NavigationBar nav = new NavigationBar(this, vars.getLanguage(), "Translation.html",
          classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      final LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "Translation.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (final Exception ex) {
      throw new ServletException(ex);
    }
    {
      final OBError myMessage = vars.getMessage("Translation");
      vars.removeMessage("Translation");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }

      if (log4j.isDebugEnabled() && myMessage != null)
        log4j.debug("datasheet message:" + myMessage.getMessage());

      xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
      xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
      xmlDocument.setParameter("paramSelLanguage", vars.getSessionValue("translation.lang"));
      xmlDocument.setData("structure1", LanguageComboData.select(this));

      out.println(xmlDocument.print());
      out.close();
    }
  }
} // Translation
