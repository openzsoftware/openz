package org.openz.controller.popup;
import java.io.IOException;
import java.io.PrintWriter;


import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.SessionUtils;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureDataGrid;
import org.openz.view.templates.ConfigureSelectionPopup;

public class Batchnumber  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;
    
    
    public void init(ServletConfig config) {
      super.init(config);
      boolHist = false;
    }
    
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
    ServletException {
      // Initialize global structure
      VariablesSecureApp vars = new VariablesSecureApp(request);
      DataGrid grid = new DataGrid();
      Scripthelper script = new Scripthelper(); // Injects Javascript, hidden fields, etc into the generated html
      Formhelper fh = new Formhelper();         // Injects the styles of fields, grids, etc
      String strOutput = "" ;                   // Resulting html output
      String strHeaderFG = "";                  // Header fieldgroup (defined in AD)
      String strGrid="";
      String strActionButtons="";               // Bottom Fieldgroup (defined in AD)
      String strOnlyResourcePlan="N";
      // Global Session Vars
      String windowId = vars.getStringParameter("WindowID");
      if (windowId.isEmpty())
         windowId = vars.getSessionValue(getServletInfo() + ".windowId");

             
      else
        vars.setSessionValue(getServletInfo() + ".windowId", windowId);

      String strOrg = vars.getStringParameter("inpadOrgId");
      if (strOrg.isEmpty())
        strOrg =  vars.getSessionValue(getServletInfo() + ".adOrgId");
      else
        vars.setSessionValue(getServletInfo() + ".adOrgId", strOrg);
      // Read Parameters
      String strName=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "name");
      if (strName.isEmpty())
        strName="%";
      String strValue=vars.getStringParameter("inpvalue");
      if (strValue.isEmpty())
        strValue=vars.getSessionValue(getServletInfo() + "|" + "value");
      String strProduct=vars.getStringParameter("inpmProductId");
      if ( !  strProduct.isEmpty()) {
        strValue=BatchnumbersData.getValueProduct(this, strProduct);
        vars.setSessionValue(getServletInfo() + "|" + "value",strValue);
      }
      if (strValue.isEmpty())
        strValue="%";
      String strBatchnumber=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "batchnumber");
      if (strBatchnumber.isEmpty())
        strBatchnumber="%";
      String strLocator=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "locator");
      if (strLocator.isEmpty())
        strLocator="%";
      // Technical Parameter offset
      String strOffset = vars.getStringParameter("offset");
      if (strOffset.equals(""))
        strOffset="0";
      // Technical Parameters for Sort
      String strSortCols = vars.getInStringParameter("sort_cols", grid.columnfilter);
      String strSortDirs = vars.getInStringParameter("sort_dirs", grid.directionfilter);
      String strOrderBy = "1";
      if (!strSortCols.equals("") && ! strSortDirs.equals(""))
        strOrderBy = SelectorUtility.buildOrderByClause(strSortCols, strSortDirs);
      // Determin, how the UI behaves and wich Function is triggered.
      String uiCommand="";
      boolean isMulti=false;
      if (vars.commandIn("DEFAULT") || vars.commandIn("KEY"))
        uiCommand="BUILDUI";
      if (vars.getStringParameter("isMultiLine").equals("Y") )
        isMulti=true;
      // Remove session-vars, if filter changes      
      if (vars.getStringParameter("newFilter").equals("1") || vars.commandIn("KEY")||vars.commandIn("CANCEL")) {
        removePageSessionVariables(vars);
      }
      
      try {
        grid.initGridByAD("BatchnumberSearch", vars, this);
        if (uiCommand.equals("BUILDUI")) {
          // Configure Structure
          strOutput = ConfigureSelectionPopup.doConfigure(this,vars,"Batchnumber",grid,"buttonSearch",isMulti,"../org.zsoft.serial.BatchNumberTracking/BatchOnhandQuantitiesCC0B9B01312F499C9849B6842923DCCB_Relation.html" );
          strGrid=ConfigureDataGrid.doConfigure(this,vars,"../info/Batchnumber.html",isMulti,"middle" );
          // Load the UI Components
          strHeaderFG=fh.prepareFieldgroup(this, vars, script,"BatchnumberFilter", null, false);  
          strHeaderFG="<div class=\"Popup_ContentPane_Client\" style=\"overflow: auto; auto; height:120px;\" id=\"client_top\">\n" +
              strHeaderFG +"</div>"; 
          strActionButtons=fh.prepareFieldgroup(this, vars, script,"SearchPopUpAction", null, false);  
          strActionButtons="<div class=\"Popup_ContentPane_Client\" style=\"overflow: auto; auto; height:90px;\" id=\"client_bottom\">\n" +
              strActionButtons + "</div>"; 
          
         
          // Replace Filter,GRID and Actionbuttons in Skeleton 
          strOutput = Replace.replace(strOutput, "@FILTERCONTENT@", strHeaderFG);
          strOutput = Replace.replace(strOutput, "@DATAGRIDCONTENT@",strGrid); 
          strOutput = Replace.replace(strOutput, "@ACTIONBUTTONS@",strActionButtons); 
          strOutput = script.doScript(strOutput, "",this,vars);
          response.setContentType("text/html; charset=UTF-8");
        }
        if (vars.commandIn("STRUCTURE")) {
          ConfigureDataGrid.printGridStructure(response, vars, grid, this);
        }
        if (vars.commandIn("DATA") || vars.commandIn("KEY")) {
          // In Projects we select only Employees of Org * and Current ORG
          // Also The Projects Planned are Selected.
          strOrg="";
          // Select the Data
          FieldProvider[] data;
          String pgLimit = ConfigureDataGrid.getLimit(getServletInfo(), strOffset, vars);
          String strNumRows ="";
          strNumRows = BatchnumbersData.countRows(this, strName, strValue, strBatchnumber,strLocator, strOrg, pgLimit);
          if (strNumRows.equals(""))
            strNumRows="0";
          vars.setSessionValue(getServletInfo() + ".numrows", strNumRows);
          data=BatchnumbersData.select(this,vars.getLanguage(), strName, strValue, strBatchnumber,strLocator,strOrg, pgLimit,  " "+strOrderBy);
          if (vars.commandIn("KEY") && data.length == 1)
            strOutput=ConfigureSelectionPopup.printPageKey(vars, this, data,  grid, "snr_batchlocator_id");
          if (vars.commandIn("DATA")) {
            strOutput=ConfigureDataGrid.printGridData(vars, grid, this, response, getServletInfo(), strOffset, data);
            response.setContentType("text/xml; charset=UTF-8");
            response.setHeader("Cache-Control", "no-cache");
          }
        }
      }
      catch (Exception e) { 
          log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
          e.printStackTrace();
          throw new ServletException(e);
      }
      PrintWriter out = response.getWriter();
      out.println(strOutput);
      out.close(); 
    }
    private void removePageSessionVariables(VariablesSecureApp vars) {
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "name");
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "value");
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "batchnumber");
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "locator");
    }
    public String getServletInfo() {
      return this.getClass().getName();
    } 
}
