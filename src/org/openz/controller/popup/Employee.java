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

public class Employee  extends HttpSecureAppServlet {
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
      // Only Planned Employees schoud not be selectable in these Windows.
      if ((windowId.equals("130")||windowId.equals("A2BEBB9B07564D2AAA372B4CB2D01165"))) {// Project and Production Order
        strOnlyResourcePlan="Y";
      }
      String strOrg = vars.getStringParameter("inpadOrgId");
      if (strOrg.isEmpty())
        strOrg =  vars.getSessionValue(getServletInfo() + ".adOrgId");
      else
        vars.setSessionValue(getServletInfo() + ".adOrgId", strOrg);
      // Read Parameters
      String strName=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "name");
      if (strName.isEmpty())
        strName="%";
      String strValue=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "value");
      if (strValue.isEmpty())
        strValue="%";
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
      if (vars.getStringParameter("newFilter").equals("1") || vars.commandIn("KEY")) {
        removePageSessionVariables(vars);
      }
      
      try {
        grid.initGridByAD("EmployeeSearch", vars, this);
        if (uiCommand.equals("BUILDUI")) {
          // Configure Structure
          strOutput = ConfigureSelectionPopup.doConfigure(this,vars,"Employee",grid,"buttonSearch",isMulti,"../org.openbravo.zsoft.smartui.Employee/PersonalDataC9B028F8723040C8A2BE9C26E125FA22_Relation.html" );
          strGrid=ConfigureDataGrid.doConfigure(this,vars,"../info/Employee.html",isMulti,"middle" );
          // Load the UI Components
          strHeaderFG=fh.prepareFieldgroup(this, vars, script,"EmployeeFilter", null, false);  
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
          String strBegin=null;
          String strEnd=null;
          String strProjecttaskid=null;
          strOrg="";
          if (windowId.equals("130")) {
            strProjecttaskid=vars.getSessionValue(windowId + "|c_projecttask_id");
            strBegin=EmployeeData.getBegin(this, strProjecttaskid);
            strEnd=EmployeeData.getEnd(this, strProjecttaskid);
            strOrg = vars.getSessionValue(getServletInfo() + ".adOrgId");
          }
          // Select the Data
          FieldProvider[] data;
          String pgLimit = ConfigureDataGrid.getLimit(getServletInfo(), strOffset, vars);
          String strNumRows ="";
          strNumRows = EmployeeData.countRows(this, strOnlyResourcePlan,strName, strValue, strOrg, pgLimit);
          if (strNumRows.equals(""))
            strNumRows="0";
          vars.setSessionValue(getServletInfo() + ".numrows", strNumRows);
          data=EmployeeData.select(this, strEnd,strBegin,strProjecttaskid, strOnlyResourcePlan,strName, strValue,strOrg, pgLimit, strOrderBy);
          if (vars.commandIn("KEY") && data.length == 1)
            strOutput=ConfigureSelectionPopup.printPageKey(vars, this, data,  grid, "adUserId");
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
    }
    public String getServletInfo() {
      return this.getClass().getName();
    } 
}
