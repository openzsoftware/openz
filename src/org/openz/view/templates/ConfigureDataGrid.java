package org.openz.view.templates;
/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
import java.io.IOException;
import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openz.util.LocalizationUtils;

import java.util.Vector;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.data.FieldProvider;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.erpCommon.utility.SQLReturnObject;
import org.openbravo.erpCommon.utility.TableSQLData;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.erpCommon.utility.OBError;
import java.math.*;
import java.text.DecimalFormat;
import org.openz.view.DataGrid;

public class ConfigureDataGrid {
 
  
  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,String url, Boolean ismulti, String gridid) throws Exception{
    String retval="";
    final String directory= servlet.strBasePath;
    retval=FileUtils.readFile("DataGrid.xml", directory + "/src-loc/design/org/openz/view/templates/");
    retval=Replace.replace(retval, "@URL@", url);
    //TODO: Get more than one Grid on a screen
    retval=Replace.replace(retval, "@GRIDID@", "grid");
    if (gridid.isEmpty()) {
      retval=Replace.replace(retval, "@CLIENT@", "client");
    } else {
      //retval=Replace.replace(retval, "@GRIDID@", gridid);
      retval=Replace.replace(retval, "@CLIENT@", "client_" + gridid);
    }
    String multi = ismulti ?  "multipleRowSelection=\"true\"" : "multipleRowSelection=\"false\"";
    retval=Replace.replace(retval, "@MULTISELECTION@", multi);
    return retval;
  }
    
  public static void printGridStructure(HttpServletResponse response, VariablesSecureApp vars, DataGrid gridstruct,HttpSecureAppServlet servlet)
      throws Exception {
    
    XmlDocument xmlDocument = servlet.xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/utility/DataGridStructure").createXmlDocument();

    SQLReturnObject[] data = getHeaders(vars,gridstruct,servlet);
    String type = "Hidden";
    String title = "";
    String description = "";

    xmlDocument.setParameter("type", type);
    xmlDocument.setParameter("title", title);
    xmlDocument.setParameter("description", description);
    xmlDocument.setParameter("backendPageSize", String.valueOf(TableSQLData.maxRowsPerGridPage));
    xmlDocument.setData("structure1", data);
    response.setContentType("text/xml; charset=UTF-8");
    response.setHeader("Cache-Control", "no-cache");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private static SQLReturnObject[] getHeaders(VariablesSecureApp vars, DataGrid gridstruct, HttpSecureAppServlet servlet) throws Exception {
    SQLReturnObject[] data = null;
    Vector<SQLReturnObject> vAux = new Vector<SQLReturnObject>();
     
    for (int i = 0; i < gridstruct.columns.length; i++) {
      SQLReturnObject dataAux = new SQLReturnObject();
      dataAux.setData("columnname", gridstruct.columns[i].name);
      dataAux.setData("gridcolumnname", gridstruct.columns[i].name);
      dataAux.setData("adReferenceId", "AD_Reference_ID");
      dataAux.setData("adReferenceValueId", "AD_ReferenceValue_ID");
      dataAux.setData("isidentifier", (gridstruct.columns[i].name.equals("rowkey") ? "true" : "false"));
      dataAux.setData("iskey", (gridstruct.columns[i].name.equals("rowkey") ? "true" : "false"));
      dataAux.setData("isvisible",
          (gridstruct.columns[i].name.endsWith("_id") || gridstruct.columns[i].name.equals("rowkey") ? "false" : "true"));
      String name = "";
      if (gridstruct.columns[i].elementid.equals(""))
        name = LocalizationUtils.getElementTextByElementName(servlet, gridstruct.columns[i].name, vars.getLanguage());
      else
        name = LocalizationUtils.getElementTextById(servlet, gridstruct.columns[i].elementid, vars.getLanguage());
      dataAux.setData("name",name);
      dataAux.setData("type", "string");
      dataAux.setData("width", gridstruct.columns[i].width);
      dataAux.setData("issortable",gridstruct.columns[i].issortcol  ? "true" : "false");
      vAux.addElement(dataAux);
    }
    data = new SQLReturnObject[vAux.size()];
    vAux.copyInto(data);
    return data;
  }
  public static String getLimit(String windowname,String strOffset,VariablesSecureApp vars) throws Exception {
    int page=0;
      page = TableSQLData.calcAndGetBackendPage(vars, windowname + ".currentPage");
      int offset = Integer.valueOf(strOffset).intValue();
      offset = (page * TableSQLData.maxRowsPerGridPage) + offset;
      String pgLimit = TableSQLData.maxRowsPerGridPage + " OFFSET " + offset;
      return pgLimit;
  }
  
  public static String printGridData(VariablesSecureApp vars, DataGrid gridstruct,HttpSecureAppServlet servlet,HttpServletResponse response, String windowname,String strOffset,
      FieldProvider[] data) throws Exception {
  
    final String directory= servlet.strBasePath;
    SQLReturnObject[] headers = getHeaders( vars, gridstruct, servlet);
    String type = "Hidden";
    String title = "";
    String description = "";
    String strNumRows = "0";
    int page = 0;
    int offset = Integer.valueOf(strOffset).intValue();

    
    
    if (headers != null) {
      try {
        
        page = TableSQLData.calcAndGetBackendPage(vars, windowname + ".currentPage");
        offset = (page * TableSQLData.maxRowsPerGridPage) + offset;
        strNumRows = vars.getSessionValue( windowname + ".numrows");

          
          
      } catch (ServletException e) {
        e.printStackTrace();
        OBError myError = Utility.translateError(servlet, vars, vars.getLanguage(), e.getMessage());
        
          type = myError.getType();
          title = myError.getTitle();
          if (!myError.getMessage().startsWith("<![CDATA["))
            description = "<![CDATA[" + myError.getMessage() + "]]>";
          else
            description = myError.getMessage();
      } catch (Exception e) {
        
        type = "Error";
        title = "Error";
        if (e.getMessage().startsWith("<![CDATA["))
          description = "<![CDATA[" + e.getMessage() + "]]>";
        else
          description = e.getMessage();
        e.printStackTrace();
      }
    }

    final DecimalFormat df = Utility.getFormat(vars, "priceEdition");
    final DecimalFormat qdf = Utility.getFormat(vars, "qtyEdition");

    if (!type.startsWith("<![CDATA["))
      type = "<![CDATA[" + type + "]]>";
    if (!title.startsWith("<![CDATA["))
      title = "<![CDATA[" + title + "]]>";
    if (!description.startsWith("<![CDATA["))
      description = "<![CDATA[" + description + "]]>";
    StringBuilder strRowsData = new StringBuilder();
    strRowsData.append("<xml-data>\n");
    strRowsData.append("  <status>\n");
    strRowsData.append("    <type>").append(type).append("</type>\n");
    strRowsData.append("    <title>").append(title).append("</title>\n");
    strRowsData.append("    <description>").append(description).append("</description>\n");
    strRowsData.append("  </status>\n");
    strRowsData.append("  <rows numRows=\"").append(strNumRows).append(
        "\" backendPage=\"" + page + "\">\n");
    if (data != null && data.length > 0) {
      for (int j = 0; j < data.length; j++) {
        strRowsData.append("    <tr>\n");
        for (int k = 0; k < headers.length; k++) {
          strRowsData.append("      <td><![CDATA[");
          String columnname = headers[k].getField("columnname");

          // Building rowKey
          if (columnname.equalsIgnoreCase("rowkey")) {
            final StringBuilder rowKey = new StringBuilder();
            rowKey.append(data[j].getField(gridstruct.keycolumname)).append("#");
            // apply, value + name to rowkey
            rowKey.append(data[j].getField("value") + " - " + data[j].getField("name")).append("#");
            if (gridstruct.rowKeys!=null){
              for (int l = 0; l < gridstruct.rowKeys.length; l++) {
                if (gridstruct.rowKeys[l].getDatatype().equals("DECIMAL"))
                  rowKey.append(qdf.format(new BigDecimal(data[j].getField(gridstruct.rowKeys[l].name)))).append("#");
                else 
                  if (gridstruct.rowKeys[l].getDatatype().equals("PRICE")) 
                       rowKey.append(df.format(new BigDecimal(data[j].getField(gridstruct.rowKeys[l].name)))).append("#");
                     else 
                       rowKey.append(data[j].getField(gridstruct.rowKeys[l].name)).append("#");
              }
            }
            
            strRowsData.append(rowKey);
          } else if (gridstruct.columns[k].getDatatype().equals("PRICE")){
            strRowsData.append(df.format(new BigDecimal(data[j].getField(columnname))));
          } else if (gridstruct.columns[k].getDatatype().equals("DECIMAL")){
            strRowsData.append(qdf.format(new BigDecimal(data[j].getField(columnname))));
          } else if ((data[j].getField(columnname)) != null) {
            if (headers[k].getField("adReferenceId").equals("32"))
              strRowsData.append(directory + "/web/").append("/images/");
            strRowsData.append(data[j].getField(columnname).replace("<b>", "").replace("<B>",
                "").replace("</b>", "").replace("</B>", "").replace("<i>", "").replace(
                "<I>", "").replace("</i>", "").replace("</I>", "")
                .replace("<p>", "&nbsp;").replace("<P>", "&nbsp;").replace("<br>",
                    "&nbsp;").replace("<BR>", "&nbsp;"));
          } else {
            if (headers[k].getField("adReferenceId").equals("32")) {
              strRowsData.append(directory + "/web/").append("/images/blank.gif");
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
 
    return strRowsData.toString();
  }
  
  /**
   * Prints the response for the getRowsIds command.
   * 
   * @param response
   *          Handler for the response Object.
   * @param vars
   *          Handler for the session info.
   * @param tableSQL
   *          Object handler of tab's query.
   * @throws IOException
   * @throws ServletException
   */
  public static String printPageDataId(VariablesSecureApp vars, DataGrid gridstruct,HttpSecureAppServlet servlet,HttpServletResponse response, String windowname,String strOffset,
      FieldProvider[] data) throws IOException, ServletException {
   
    int minOffset = Integer.valueOf(vars.getStringParameter("minOffset")).intValue();
    int maxOffset = Integer.valueOf(vars.getStringParameter("maxOffset")).intValue();
    String type = "Hidden";
    String title = "";
    String description = "";

    // get current page
    final DecimalFormat df = Utility.getFormat(vars, "priceEdition");
    final DecimalFormat qdf = Utility.getFormat(vars, "qtyEdition");
    int page = TableSQLData.calcAndGetBackendPage(vars, windowname + ".currentPage");
    minOffset = (page * TableSQLData.maxRowsPerGridPage) + minOffset;
    maxOffset = (page * TableSQLData.maxRowsPerGridPage) + maxOffset;

 
    StringBuffer strRowsData = new StringBuffer();
    strRowsData.append("<xml-rangeid>\n");
    strRowsData.append("  <status>\n");
    strRowsData.append("    <type>").append(type).append("</type>\n");
    strRowsData.append("    <title>").append(title).append("</title>\n");
    strRowsData.append("    <description>").append(description).append("</description>\n");
    strRowsData.append("  </status>\n");
    strRowsData.append("<ids> \n");
    for (int i = 0; i < data.length; i++) {
      if (i>=minOffset && i<=maxOffset) {
        strRowsData.append("<id>");
        strRowsData.append(data[i].getField(gridstruct.keycolumname)).append("#");
        strRowsData.append(data[i].getField("name")).append("#");
        if (gridstruct.rowKeys!=null){
          for (int l = 0; l < gridstruct.rowKeys.length; l++) {
            if (gridstruct.rowKeys[l].getDatatype().equals("DECIMAL"))
              strRowsData.append(qdf.format(new BigDecimal(data[i].getField(gridstruct.rowKeys[l].name)))).append("#");
            else 
              if (gridstruct.rowKeys[l].getDatatype().equals("PRICE")) 
                strRowsData.append(df.format(new BigDecimal(data[i].getField(gridstruct.rowKeys[l].name)))).append("#");
              else 
               strRowsData.append(data[i].getField(gridstruct.rowKeys[l].name)).append("#");
          }
        }  
        strRowsData.append("</id> \n");
      }
    }
    strRowsData.append("</ids> \n");  
    strRowsData.append("</xml-rangeid>\n");
  

    
    return Replace.replace(strRowsData.toString(),"&","&#252;");
  }

}
