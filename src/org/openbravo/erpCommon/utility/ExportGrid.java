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

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.LinkedList;
import java.util.UUID;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.jasperreports.engine.JRException;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.OrgTree;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.Sqlc;
import org.openbravo.utils.FileUtility;
import org.openz.util.LocalizationUtils;

public class ExportGrid extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
   private static final int CHAR_WIDTH = 10;
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    String strTabId = vars.getRequiredStringParameter("inpTabId");
    String strWindowId = vars.getRequiredStringParameter("inpWindowId");
    String strAccessLevel = vars.getRequiredStringParameter("inpAccessLevel");
    if (log4j.isDebugEnabled())
      log4j.debug("Export grid, tabID: " + strTabId);
    ServletOutputStream os = null;
    InputStream is = null;

    String strLanguage = vars.getLanguage();
    String strBaseDesign = getBaseDesignPath(strLanguage);
    String fileName = "";
    if (log4j.isDebugEnabled())
      log4j.debug("*********************Base design path: " + strBaseDesign);

    try {
      GridReportVO gridReportVO = createGridReport(vars, strTabId, strWindowId, strAccessLevel,
          false,null);
      os = response.getOutputStream();
      is = getInputStream(strBaseDesign + "/org/openbravo/erpCommon/utility/"
          + gridReportVO.getJrxmlTemplate());

      if (log4j.isDebugEnabled())
        log4j.debug("Create report, type: " + vars.getCommand());
      UUID reportId = UUID.randomUUID();
      String strOutputType = vars.getCommand().toLowerCase();
      if (strOutputType.equals("excel")) {
        strOutputType = "xls";
      }
      fileName = "ExportGrid-" + (reportId) + "." + strOutputType;
      if (vars.commandIn("HTML"))
        GridBO.createHTMLReport(is, gridReportVO, globalParameters.strFTPDirectory, fileName);
      else if (vars.commandIn("PDF")) {
        GridBO.createPDFReport(is, gridReportVO, globalParameters.strFTPDirectory, fileName);
      } else if (vars.commandIn("EXCEL")) {
        GridBO.createXLSReport(is, gridReportVO, globalParameters.strFTPDirectory, fileName);
      } else if (vars.commandIn("CSV")) {
        GridBO.createCSVReport(is, gridReportVO, globalParameters.strFTPDirectory, fileName);
      }
      printPagePopUpDownload(os, fileName);
    } catch (JRException e) {
      e.printStackTrace();
      throw new ServletException(e.getMessage());
    } catch (IOException ioe) {
      try {
        FileUtility f = new FileUtility(globalParameters.strFTPDirectory, fileName, false, true);
        if (f.exists())
          f.deleteFile();
      } catch (IOException ioex) {
        log4j.error("Error trying to delete temporary report file " + fileName + " : "
            + ioex.getMessage());
      }
    } finally {
      if (is!=null)
        is.close();
      if (os!=null)
        os.close();
    }
  }

  public String dumpReport2csv(String strBaseDesign,String strAttachPath,String strFileName,VariablesSecureApp vars, String filterClause) {
	  try {
		GridReportVO gridReportVO = createGridReport(vars, this.getTabId(), this.getWindowId(), "2",
		          false,filterClause,true);
		InputStream is = null;
		is = getInputStream(strBaseDesign + "/org/openbravo/erpCommon/utility/"
		          + gridReportVO.getJrxmlTemplate());
		GridBO.createCSVReport(is, gridReportVO, strAttachPath, strFileName);
	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	  return "";
  }
  private GridReportVO createGridReport(VariablesSecureApp vars, String strTabId, String strWindowId,
	      String strAccessLevel, boolean useFieldLength, String _filter) throws ServletException {
	  return  createGridReport(	 vars, strTabId,strWindowId,strAccessLevel,useFieldLength,_filter,false);
  }
  
  private GridReportVO createGridReport(VariablesSecureApp vars, String strTabId, String strWindowId,
      String strAccessLevel, boolean useFieldLength, String _filter, boolean ignMaxRows) throws ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Create Grid Report, tabID: " + strTabId);
    LinkedList<GridColumnVO> columns = new LinkedList<GridColumnVO>();
    FieldProvider[] data = null;
    TableSQLData tableSQL = null;
    String sumtext;
    try {
      String orglist=Utility.getContext(this, vars,"#AccessibleOrgTree", strWindowId, Integer.valueOf(strAccessLevel).intValue());
      if (vars.getSessionValue("#AccessibleOrgTree").isEmpty()  && ignMaxRows) {
    	  // Background Process
      	  OrgTree tree = new OrgTree(this, "C726FEC915A54A0995C568555DA5BB3C");
      	  orglist= tree.toString();
      }
      tableSQL = new TableSQLData(vars, this, strTabId, orglist, "'C726FEC915A54A0995C568555DA5BB3C'", Utility.getContext(this, vars,
          "ShowAudit", strWindowId).equals("Y"),_filter);
      sumtext=LocalizationUtils.getElementTextByElementName(this, "Sum", vars.getLanguage());
    } catch (Exception ex) {
      ex.printStackTrace();
      log4j.error(ex.getMessage());
      throw new ServletException(ex.getMessage());
    }
    SQLReturnObject[] headers = tableSQL.getHeaders(true, useFieldLength);

    if (tableSQL != null && headers != null) {
      try {
        if (log4j.isDebugEnabled())
          log4j.debug("Geting the grid data.");
        vars.setSessionValue(strTabId + "|newOrder", "1");
        String strSQL = ModelSQLGeneration.generateSQL(this, vars, tableSQL, "",
            new Vector<String>(), new Vector<String>(), 0, 0);
        if (log4j.isDebugEnabled())
          log4j.debug("SQL: " + strSQL);
        ExecuteQuery execquery = new ExecuteQuery(this, strSQL, tableSQL.getParameterValues());
        data = execquery.select();
        if (!ignMaxRows)
        	if (data.length>Integer.parseInt(vars.getSessionValue("P|MAXEXCELROWS")))
        		throw new Exception("Too many Rows");
      } catch (Exception e) {
        if (log4j.isDebugEnabled())
          log4j.debug("Error obtaining rows data");
        e.printStackTrace();
        throw new ServletException(e.getMessage());
      }
    }
    int totalWidth = 0;
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].getField("isvisible").equals("true")) {
        String columnname = headers[i].getField("columnname");
        if (!tableSQL.getSelectField(columnname + "_R").equals(""))
          columnname += "_R";
        if (log4j.isDebugEnabled())
          log4j.debug("Add column: " + columnname + " width: " + headers[i].getField("width")
              + " reference: " + headers[i].getField("adReferenceId"));
        int intColumnWidth = Integer.valueOf(headers[i].getField("width"));
        if (intColumnWidth>500)
          intColumnWidth=500;
        String headertext;
        try {
          headertext=LocalizationUtils.getElementTextByElementName(this, columnname, vars.getLanguage());
        
          if (intColumnWidth<headertext.length()*5)
            intColumnWidth=headertext.length()*5;
        } catch (Exception e) {
          throw new ServletException(e.getMessage());
        }
        /*
        if (headers[i].getField("name") != null) {
          if (headers[i].getField("name").length() * CHAR_WIDTH > intColumnWidth) {
            intColumnWidth = headers[i].getField("name").length() * CHAR_WIDTH;
            if (log4j.isDebugEnabled())
              log4j.debug("            New width: " + intColumnWidth);
          }
        } */
        totalWidth += intColumnWidth;
        Class<?> fieldClass = String.class;
        if (headers[i].getField("adReferenceId").equals("22")
            || headers[i].getField("adReferenceId").equals("12")
            || headers[i].getField("adReferenceId").equals("11")
            || headers[i].getField("adReferenceId").equals("800008")
            || headers[i].getField("adReferenceId").equals("800019")
            || headers[i].getField("template").equals("SQLFIELDEURO")
            || headers[i].getField("template").equals("SQLFIELDPRICE")
            || headers[i].getField("template").equals("SQLFIELDINTEGER")
            || headers[i].getField("template").equals("SQLFIELDDECIMAL"))
          fieldClass = java.math.BigDecimal.class;
        if (headers[i].getField("adReferenceId").equals("15") && vars.commandIn("EXCEL") && vars.getSessionValue("P|EXCELEXPORTDATEDATATYPE").equals("Y"))
        	fieldClass = java.util.Date.class;
        if (columnname.equalsIgnoreCase("updated") || columnname.equalsIgnoreCase("updatedby_r") || columnname.equalsIgnoreCase("created") || columnname.equalsIgnoreCase("createdby_r")){
          try {
          columns.add(new GridColumnVO(headertext, columnname, intColumnWidth,
              fieldClass,0));
          } catch (Exception e) {
            throw new ServletException(e.getMessage());
          }
        } else {
          int prec=0;
          if (headers[i].getField("adReferenceId").equals("22")|| headers[i].getField("template").equals("SQLFIELDDECIMAL"))
            prec=3;
          if (headers[i].getField("adReferenceId").equals("800008")|| headers[i].getField("template").equals("SQLFIELDPRICE"))
            prec=4;
          if (headers[i].getField("adReferenceId").equals("12")|| headers[i].getField("template").equals("SQLFIELDEURO"))
            prec=2;
          // If The Field is a picture, do not export
          if (! headers[i].getField("adReferenceId").equals("4AA6C3BE9D3B4D84A3B80489505A23E5"))
        	  columns.add(new GridColumnVO(headers[i].getField("name"), columnname, intColumnWidth,
            fieldClass,prec));
        }
      }
    }
    // SZ : Format Title with Parent If we are in a Sub-Tab of a window.
    String strTitle="";
    
    strTitle = ExportGridData.getTitle(this, "ad_tab",strTabId, vars.getLanguage());
    strTitle = strTitle.substring(0,strTitle.indexOf("-"));
    try {  
      if (!ExportGridData.isFirstLevel(this, strTabId).equals("0"))
      {
        String strCurrTab; 
        String strTabTitle;
        final String strWindow = vars.getStringParameter("inpwindowId");
        String strTableId = vars.getRequiredStringParameter("inpTableId");
        String strKeyColumn = ExportGridData.getKeyColumName(this, strTabId,  strTableId);
        for (int i=0;i< Integer.parseInt(ExportGridData.isFirstLevel(this, strTabId));i++)
        {  
            
            //final String strKeyColumn = vars.getRequiredStringParameter("inpkeyColumnId");
            
            
            final String strColumnName = Sqlc.TransformaNombreColumna(strKeyColumn);
            final String strKeyId = vars.getGlobalVariable("inp" + strColumnName, strWindow + "|"
                + strKeyColumn);
            strTableId=ExportGridData.getTablenameFromKeycolumn(this, strKeyColumn);
            strCurrTab=ExportGridData.getTabIDFromTableandWindow(this, strWindowId, strTableId);
            
            strTabTitle=ExportGridData.getTitle(this, "ad_tab",strCurrTab, vars.getLanguage());
            strTabTitle=strTabTitle.substring(0,strTabTitle.indexOf("-"));
            strTitle = strTitle + " - " + strTabTitle + ": " +
            UsedByLinkData.selectIdentifier(this, strKeyId, vars.getLanguage(), strTableId);
            strKeyColumn=ExportGridData.getKeyColumName(this, null,  strTableId);
        }
      }
    }
    catch (Exception e) {
    }
    if (log4j.isDebugEnabled())
      log4j.debug("GridReport, totalwidth: " + totalWidth + " title: " + strTitle);
    GridReportVO gridReportVO = new GridReportVO("plantilla.jrxml", data, strTitle, columns,
        strReplaceWithFull, totalWidth, vars.getJavaDateFormat(),sumtext);
    return gridReportVO;
  }

  private InputStream getInputStream(String reportFile) throws IOException {
    if (log4j.isDebugEnabled())
      log4j.debug("Get input stream file: " + reportFile);
    return (new FileInputStream(reportFile));
  }
}
