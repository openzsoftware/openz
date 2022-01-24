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
package org.openbravo.erpCommon.info;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.RequestFilter;
import org.openbravo.base.filter.ValueListFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SQLReturnObject;
import org.openbravo.erpCommon.utility.TableSQLData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;

public class Project extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  private static final String[] colNames = { "value", "name", "bpartner", "projectstatus", "rowkey" };
  private static final RequestFilter columnFilter = new ValueListFilter(colNames);
  private static final RequestFilter directionFilter = new ValueListFilter("asc", "desc");

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
    	
      String strNameValue = vars.getRequestGlobalVariable("inpKeyValue", "Project.name");
      String strKey = vars.getGlobalVariable("inpName", "Project.name", "");

      removePageSessionVariables(vars);
      String strWindow = vars.getGlobalVariable("WindowID", "Project.windowId", "");
      final Boolean ismulti = vars.getStringParameter("isMultiLine").equals("Y") ? true : false;
      String strBpartner = "";
      //vars.getGlobalVariable("inpBpartnerId", "Project.bpartner", "");
      //vars.getGlobalVariable("inpNameValue", "Project.key", "");
      vars.setSessionValue("Project.adorgid", vars.getStringParameter("inpAD_Org_ID", ""));
      vars.getGlobalVariable("TabID", "Project.tabId", "");
      vars.removeSessionValue("Project.key");
      if (!strNameValue.equals("")) {
        int guion = strNameValue.indexOf(" - ");
        if (guion != -1) {
          strKey = strNameValue.substring(0, guion).trim();
          strNameValue = strNameValue.substring(guion + 3).trim();
          vars.setSessionValue("Project.key", strKey);
        }
        vars.setSessionValue("Project.name", strNameValue + "%");
      }
      
      //String focusedField = "paramKey";
      //if(strKey.equals("%") || strKey.equals("")) {
    //	  focusedField = "paramName";
     // }

      printPage(response, vars, strKey, strNameValue + "%", strBpartner, strWindow, "paramName", ismulti);

    } else if (vars.commandIn("KEY")) {
      reactOnKeyPress(response, vars);
		
    } else if (vars.commandIn("STRUCTURE")) {
      printGridStructure(response, vars);

    } else if (vars.commandIn("DATA")) {
      if (vars.getStringParameter("newFilter").equals("1")) {
        removePageSessionVariables(vars);
      }
      // String strWindowId = vars.getGlobalVariable("inpWindowId", "Project.windowId", "");
      String strKey = vars.getGlobalVariable("inpKey", "Project.key", "");
      String strName = vars.getGlobalVariable("inpName", "Project.name", "");
      String strBpartners = vars.getGlobalVariable("inpBpartnerId", "Project.bpartner", "");
      
      // benötigt nicht die gleiche Behandlung von issotrx wie Product- oder BusinessPartner.java
      // String strIsSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
      String strOrg = vars.getGlobalVariable("inpAD_Org_ID", "Project.adorgid", "");

      String strNewFilter = vars.getStringParameter("newFilter");
      String strOffset = vars.getStringParameter("offset");
      String strPageSize = vars.getStringParameter("page_size");
      String strSortCols = vars.getInStringParameter("sort_cols", columnFilter);
      String strSortDirs = vars.getInStringParameter("sort_dirs", directionFilter);
      printGridData(response, vars, strKey, strName, strBpartners, strSortCols, strSortDirs,
          strOffset, strPageSize, strNewFilter, strOrg);
    } else
      pageError(response);
  }
  
  private void reactOnKeyPress(HttpServletResponse response, VariablesSecureApp vars) throws ServletException, IOException {
 
	    String searchValue = getSearchValue(vars);
		removePageSessionVariables(vars);

		SearchVariablesBuilder svBuilder = createSearchVariablesBuilder(vars, searchValue);
		String org = vars.getGlobalVariable("inpAD_Org_ID", "Project.adorgid", "");

		printOneOrAll(response, vars, svBuilder, org);
  }
  
  private String getSearchValue(VariablesSecureApp vars) throws ServletException {
	  
		String searchValue = vars.getGlobalVariable("inpNameValue", "Project.key", "");
		// getGlobalVariable only used to store request value into session, not to read it from there

		return searchValue + "%";
  }

  private void removePageSessionVariables(VariablesSecureApp vars) {
	  
    vars.removeSessionValue("Project.key");
    vars.removeSessionValue("Project.name");
    vars.removeSessionValue("Project.bpartner");
    vars.removeSessionValue("Project.currentPage");
    // remove saved adorgid only when called from DEFAULT,KEY
    // but not when called by clicking search in the selector
    if (!vars.getStringParameter("newFilter").equals("1")) {
      vars.removeSessionValue("Project.adorgid");
    }
  }

  private SearchVariablesBuilder createSearchVariablesBuilder(VariablesSecureApp vars, String searchValue) throws NumberFormatException, ServletException {
	  
		int namesFound = Integer.parseInt(ProjectData.getNameCount(this, searchValue));
		int valuesFound = Integer.parseInt(ProjectData.getValueCount(this, searchValue));

		return new SearchVariablesBuilder(vars, "Project", searchValue, valuesFound, namesFound);
  }
  
  private void printOneOrAll(HttpServletResponse response, VariablesSecureApp vars, SearchVariablesBuilder svBuilder, String org) throws ServletException, IOException {
	  
	  	String keySearch = svBuilder.getKeySearch();
	  	String nameSearch = svBuilder.getNameSearch();
		final ProjectData[] data = getProjectData(vars, org, keySearch, nameSearch, svBuilder.isSearchByKey());

		if (data != null && data.length == 1) {
		  printOneEntry(response, vars, data);

		} else {
		  printAllEntries(response, vars, keySearch, nameSearch, svBuilder.getFocusedField());
		}
  }

  private ProjectData[] getProjectData(
		  VariablesSecureApp vars,
		  String strOrg,
		  String strKeySearch,
		  String strNameSearch,
		  boolean isSearchByKey
		  ) throws ServletException {
	  
	  	if (isSearchByKey) {
	  		return ProjectData.selectKey(this, Utility.getContext(this, vars,
	  			"#User_Client", "Project"), Utility.getSelectorOrgs(this, vars, strOrg), strKeySearch);

	  	} else {
	  		return ProjectData.selectName(this, Utility.getContext(this, vars,
	  			"#User_Client", "Project"), Utility.getSelectorOrgs(this, vars, strOrg), strNameSearch);
	  	}
  }
  
  private void printAllEntries(HttpServletResponse response, VariablesSecureApp vars, String valSearch, String nameSearch, String focusedField) throws IOException, ServletException {

		  String strWindow = vars.getGlobalVariable("WindowID", "Project.windowId", "");
		  String strBpartner = vars.getGlobalVariable("inpBpartnerId", "Project.bpartner", "");
		  printPage(response, vars, valSearch, nameSearch, strBpartner, strWindow, focusedField, false);
  }
  

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strKeyValue,
      String strNameValue, String strBpartners, String strWindow, String focusedId, Boolean isMulti)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Frame 1 of the projects seeker");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/info/Project")
        .createXmlDocument();
    if (strKeyValue.equals("") && strNameValue.equals("")) {
      xmlDocument.setParameter("key", "%");
    } else {
      xmlDocument.setParameter("key", strKeyValue);
    }
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("windowId", strWindow);
    xmlDocument.setParameter("name", strNameValue);
    xmlDocument.setParameter("claveTercero", strBpartners);
    xmlDocument.setParameter("tercero", ProjectData.selectTercero(this, strBpartners));

    xmlDocument.setParameter("grid", "20");
    xmlDocument.setParameter("grid_Offset", "");
    xmlDocument.setParameter("grid_SortCols", "1");
    xmlDocument.setParameter("grid_SortDirs", "ASC");
    xmlDocument.setParameter("grid_Default", "0");
    xmlDocument.setParameter("grid_IsMulti", isMulti ? "true" : "false");

    xmlDocument.setParameter("jsFocusOnField", Utility.focusFieldJS(focusedId));

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printOneEntry(HttpServletResponse response, VariablesSecureApp vars,
      ProjectData[] data) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Project seeker Frame Set");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/info/SearchUniqueKeyResponse").createXmlDocument();

    xmlDocument.setParameter("script", generateSelector(data));
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();

    out.println(xmlDocument.print());
    out.close();
  }

  private String generateSelector(ProjectData[] data) throws IOException, ServletException {
    StringBuffer html = new StringBuffer();

    html.append("\nfunction validateSelector() {\n");
    html.append("var key = \"" + data[0].cProjectId + "\";\n");
html.append("var text = \""
	+ Replace.replace((data[0].value + " - " + data[0].name), "\"", "\\\"") + "\";\n");
    html.append("parent.opener.closeSearch(\"SAVE\", key, text);\n");
    html.append("}\n");
    return html.toString();
  }

  private void printGridStructure(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print page structure");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/utility/DataGridStructure").createXmlDocument();

    SQLReturnObject[] data = getHeaders(vars);
    String type = "Hidden";
    String title = "";
    String description = "";

    xmlDocument.setParameter("type", type);
    xmlDocument.setParameter("title", title);
    xmlDocument.setParameter("description", description);
    xmlDocument.setData("structure1", data);
    xmlDocument.setParameter("backendPageSize", String.valueOf(TableSQLData.maxRowsPerGridPage));
    response.setContentType("text/xml; charset=UTF-8");
    response.setHeader("Cache-Control", "no-cache");
    PrintWriter out = response.getWriter();
    if (log4j.isDebugEnabled())
      log4j.debug(xmlDocument.print());
    out.println(xmlDocument.print());
    out.close();
  }

  private SQLReturnObject[] getHeaders(VariablesSecureApp vars) {
    SQLReturnObject[] data = null;
    Vector<SQLReturnObject> vAux = new Vector<SQLReturnObject>();
    // String[] gridNames = {"Key", "Name","Disp. Credit","Credit used",
    // "Contact", "Phone no.", "Zip", "City", "Income", "c_bpartner_id",
    // "c_bpartner_contact_id", "c_bpartner_location_id", "rowkey"};
    String[] colWidths = { "160", "300", "250", "120", "0" }; // 98
    for (int i = 0; i < colNames.length; i++) {
      SQLReturnObject dataAux = new SQLReturnObject();
      dataAux.setData("columnname", colNames[i]);
      dataAux.setData("gridcolumnname", colNames[i]);
      dataAux.setData("adReferenceId", "AD_Reference_ID");
      dataAux.setData("adReferenceValueId", "AD_ReferenceValue_ID");
      dataAux.setData("isidentifier", (colNames[i].equals("rowkey") ? "true" : "false"));
      dataAux.setData("iskey", (colNames[i].equals("rowkey") ? "true" : "false"));
      dataAux.setData("isvisible",
          (colNames[i].endsWith("_id") || colNames[i].equals("rowkey") ? "false" : "true"));
      String name = Utility.messageBD(this, "PJS_" + colNames[i].toUpperCase(), vars.getLanguage());
      dataAux.setData("name", (name.startsWith("PJS_") ? colNames[i] : name));
      dataAux.setData("type", "string");
      dataAux.setData("width", colWidths[i]);
      vAux.addElement(dataAux);
    }
    data = new SQLReturnObject[vAux.size()];
    vAux.copyInto(data);
    return data;
  }

  private void printGridData(HttpServletResponse response, VariablesSecureApp vars, String strKey,
      String strName, String strBpartners, String strOrderCols, String strOrderDirs,
      String strOffset, String strPageSize, String strNewFilter, String strOrg) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print page rows");
    int page = 0;
    SQLReturnObject[] headers = getHeaders(vars);
    FieldProvider[] data = null;
    String type = "Hidden";
    String title = "";
    String description = "";
    String strNumRows = "0";
    int offset = Integer.valueOf(strOffset).intValue();
    int pageSize = Integer.valueOf(strPageSize).intValue();

    if (headers != null) {
      try {
        // build sql orderBy clause from parameters
        String strOrderBy = SelectorUtility.buildOrderByClause(strOrderCols, strOrderDirs);
        page = TableSQLData.calcAndGetBackendPage(vars, "Project.currentPage");
        if (vars.getStringParameter("movePage", "").length() > 0) {
        // on movePage action force executing countRows again
        	strNewFilter = "";
        }
        int oldOffset = offset;
        offset = (page * TableSQLData.maxRowsPerGridPage) + offset;
        log4j.debug("relativeOffset: " + oldOffset + " absoluteOffset: " + offset);
        String strWindow=vars.getGlobalVariable("WindowID", "Project.windowId", "");
        String strDraftStatus="xx";
        // Not Stared Projects in Sales and Purchase Orders
        if (strWindow.equals("143")||strWindow.equals("181"))
          strDraftStatus="OP";
        // Includuing Closed Projects when using in Projects Window
        if (strWindow.equals("130"))
          strDraftStatus="OC";
        // Including OPen when copying a Task
        String strTab=vars.getSessionValue("Project.tabid");
        if (strTab.equals("490"))
          strDraftStatus="OP";
        if (strNewFilter.equals("1") || strNewFilter.equals("")) { // New
          // filter
          // or
          // first
          // load
        String  pgLimit = null;
        
        	pgLimit = TableSQLData.maxRowsPerGridPage + " OFFSET " + offset;
        
        strNumRows = ProjectData.countRows(this,  vars.getLanguage(), strDraftStatus, Utility.getContext(this, vars,
              "#User_Client", "Project"), Utility.getSelectorOrgs(this, vars, strOrg), strKey,
              strName, strBpartners, pgLimit); 
          //strNumRows = String.valueOf(data.length);
          vars.setSessionValue("ProjectData.numrows", strNumRows);
        } else {
          strNumRows = vars.getSessionValue("ProjectData.numrows");
        }

        // Filtering result
       
          String pgLimit = pageSize + " OFFSET " + offset;
          data = ProjectData.select(this, vars.getLanguage(), strDraftStatus, Utility.getContext(this, vars,
              "#User_Client", "Project"), Utility.getSelectorOrgs(this, vars, strOrg), strKey,
              strName, strBpartners, strOrderBy,  pgLimit);

      } catch (ServletException e) {
        log4j.error("Error in print page data: " + e);
        e.printStackTrace();
        OBError myError = Utility.translateError(this, vars, vars.getLanguage(), e.getMessage());
        if (!myError.isConnectionAvailable()) {
          bdErrorAjax(response, "Error", "Connection Error", "No database connection");
          return;
        } else {
          type = myError.getType();
          title = myError.getTitle();
          if (!myError.getMessage().startsWith("<![CDATA["))
            description = "<![CDATA[" + myError.getMessage() + "]]>";
          else
            description = myError.getMessage();
        }
      } catch (Exception e) {
        if (log4j.isDebugEnabled())
          log4j.debug("Error obtaining rows data");
        type = "Error";
        title = "Error";
        if (e.getMessage().startsWith("<![CDATA["))
          description = "<![CDATA[" + e.getMessage() + "]]>";
        else
          description = e.getMessage();
        e.printStackTrace();
      }
    }

    if (!type.startsWith("<![CDATA["))
      type = "<![CDATA[" + type + "]]>";
    if (!title.startsWith("<![CDATA["))
      title = "<![CDATA[" + title + "]]>";
    if (!description.startsWith("<![CDATA["))
      description = "<![CDATA[" + description + "]]>";
    StringBuffer strRowsData = new StringBuffer();
    strRowsData.append("<xml-data>\n");
    strRowsData.append("  <status>\n");
    strRowsData.append("    <type>").append(type).append("</type>\n");
    strRowsData.append("    <title>").append(title).append("</title>\n");
    strRowsData.append("    <description>").append(description).append("</description>\n");
    strRowsData.append("  </status>\n");
    strRowsData.append("  <rows numRows=\"").append(strNumRows).append("\" backendPage=\"" + page + "\">\n");
    if (data != null && data.length > 0) {
      for (int j = 0; j < data.length; j++) {
        strRowsData.append("    <tr>\n");
        for (int k = 0; k < headers.length; k++) {
          strRowsData.append("      <td><![CDATA[");
          String columnname = headers[k].getField("columnname");

          /*
           * if (( (headers[k].getField("iskey").equals("false") && !headers
           * [k].getField("gridcolumnname").equalsIgnoreCase("keyname" )) ||
           * !headers[k].getField("iskey").equals("true")) && !tableSQL.getSelectField(columnname +
           * "_R").equals("")) { columnname += "_R"; }
           */

          if ((data[j].getField(columnname)) != null) {
            if (headers[k].getField("adReferenceId").equals("32"))
              strRowsData.append(strReplaceWith).append("/images/");
            strRowsData.append(data[j].getField(columnname).replaceAll("<b>", "").replaceAll("<B>",
                "").replaceAll("</b>", "").replaceAll("</B>", "").replaceAll("<i>", "").replaceAll(
                "<I>", "").replaceAll("</i>", "").replaceAll("</I>", "")
                .replaceAll("<p>", "&nbsp;").replaceAll("<P>", "&nbsp;").replaceAll("<br>",
                    "&nbsp;").replaceAll("<BR>", "&nbsp;"));
          } else {
            if (headers[k].getField("adReferenceId").equals("32")) {
              strRowsData.append(strReplaceWith).append("/images/blank.gif");
            } else
              strRowsData.append("&nbsp;");
          }
          strRowsData.append("]]></td>\n");
        }
        strRowsData.append("    </tr>\n");
      }
    }
    strRowsData.append("  </rows>\n");
    strRowsData.append("</xml-data>\n");

    response.setContentType("text/xml; charset=UTF-8");
    response.setHeader("Cache-Control", "no-cache");
    PrintWriter out = response.getWriter();
    if (log4j.isDebugEnabled())
      log4j.debug(strRowsData.toString());
    out.print(strRowsData.toString());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet that presents the project seeker";
  } // end of getServletInfo() method
}
