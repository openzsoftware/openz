/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Danny Heuduk, dh@zimmermann-software.de (DH) Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************

 */
package org.openbravo.erpCommon.info;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.*;
import java.text.DecimalFormat;
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
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SQLReturnObject;
import org.openbravo.erpCommon.utility.TableSQLData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.FileUtils;
import org.openz.util.SessionUtils;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.SelectBoxhelper;
import org.openz.view.templates.ConfigureButton;
import org.openz.view.templates.ConfigureDataGrid;
import org.openz.view.templates.ConfigureSelectionPopup;
import org.openz.view.templates.ConfigureTableStructure;

public class BusinessPartner extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

//"so_creditavailable","so_creditused","income",
  @Override
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }
  
  @Override
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
      String strSkeleton;
      Boolean isKeyMultipleOrNone=false;
      // Global Session Vars and Parameters (All Commands)
      String windowId = vars.getStringParameter("WindowID");
      if (windowId.isEmpty())
         windowId = vars.getSessionValue(getServletInfo() + ".windowId");
      else
        vars.setSessionValue(getServletInfo() + ".windowId", windowId);
      String ismulti = vars.getStringParameter("isMultiLine");
	  String strOrg = Utility.getContext(this, vars, "Ad_Org_ID", windowId);
      String strName=vars.getStringParameter("inpname");
      String strValue=vars.getStringParameter("inpvalue");
      String strcontact=vars.getStringParameter("inpcontact");
      String strcity=vars.getStringParameter("inpcity");
      String strzip=vars.getStringParameter("inpzip");
      String strorg=vars.getStringParameter("inporg");
      String strbpartnerradio=vars.getStringParameter("inpbpartner");
      String strauxfield1=vars.getStringParameter("inpauxfield1");
      String strauxfield2=vars.getStringParameter("inpauxfield2");
      String strauxfield3=vars.getStringParameter("inpauxfield3");
      String strauxfield4=vars.getStringParameter("inpauxfield4");
      // Technical Parameters
   	  String strOffset = vars.getStringParameter("offset");
   	  if (strOffset.equals(""))
   			strOffset = "0";
   	  String strSortCols = vars.getInStringParameter("sort_cols", grid.columnfilter);
      String strSortDirs = vars.getInStringParameter("sort_dirs", grid.directionfilter);
   	  String strOrderBy = "1";
   	  if (!strSortCols.equals("") && !strSortDirs.equals(""))
   			strOrderBy = SelectorUtility.buildOrderByClause(strSortCols, strSortDirs);
      // Value Filter - set session var in KEY command
   	  if (vars.commandIn("KEY")) {
   			String strIDValue = vars.getStringParameter("inpIDValue");
   			strValue = vars.getStringParameter("inpNameValue") + "%";
   			if (!strIDValue.equals("") && strValue.equals(""))
   				strValue = BusinessPartnerData.getValue(this, strIDValue);
   			String strValc=BusinessPartnerData.getValueCount(this, strValue);
   			String strnam=BusinessPartnerData.getNameCount(this, strValue);
   			// Test , if there is something with this name
   			if (strValc.equals("0")
   					&& !strnam.equals("0")) {
   				strValue = "";
   				strName = vars.getStringParameter("inpNameValue") + "%";
   			}
   			// In KEY command the Value is persisted in session
   			if ((Integer.parseInt(strValc)>1 || Integer.parseInt(strnam)>1)||(Integer.parseInt(strValc)==0 && Integer.parseInt(strnam)==0)) {
   				isKeyMultipleOrNone=true;
   				vars.setSessionValue(getServletInfo() + "|KeyMultipleOrNone", "Y");
   				vars.setSessionValue(getServletInfo() + "|value", strValue);
   	   			vars.setSessionValue(getServletInfo() + "|name", strName);
   			}
   				
   	   }  
   	try {
   	   grid.initGridByAD("Business PartnerSearch", vars, this);
       if (vars.commandIn("DEFAULT")||isKeyMultipleOrNone) {
	      // Set Windows TRxs Selection
	      if(windowId.equals("ReportSalesDimensionalAnalyzeJR") || windowId.equals("ReportInvoiceCustomerDimensionalAnalysesJR")) 
	    	  strbpartnerradio = "customers";
	      else if (windowId.equals("ReportPurchaseDimensionalAnalysesFilterJR") || windowId.equals("ReportInvoiceVendorDimensionalAnalysesJR") ||
	    		  windowId.equals("ReportMaterialDimensionalAnalysesJR")) 
	    	  strbpartnerradio = "vendors";
	      else if (windowId.equals("VERTICALMENU")||isKeyMultipleOrNone) 
	    	  strbpartnerradio = "all"; 
	      String isSoTrx= BusinessPartnerData.issotrxwindow(this, windowId);
	      if (strbpartnerradio.isEmpty()) 
	    	  if (isSoTrx.equals("Y")) strbpartnerradio = "customers"; else strbpartnerradio = "vendors";
	      vars.setSessionValue(getServletInfo() + "|bpartner", strbpartnerradio);
	      // Build the GUI
	      strSkeleton = ConfigureSelectionPopup.doConfigure(this, vars, "Business Partner", grid, "buttonsearch",
					ismulti.equals("Y") ? true : false, "../BusinessPartner/BusinessPartner_Edition.html");
	      // BUILD Filter
	      strHeaderFG = fh.prepareFieldgroup(this, vars, script, "Business PartnerSelectorFilter", null, false);
		  // Direct Filter Functions
	      strHeaderFG = Replace.replace(strHeaderFG, "changeToEditingMode('onkeypress');", "aceptar(event);");
		  script.addFilterAction4ManualServlets("setFilters();");
		  // Method to establish Filter Height and grid height derived from in Popups
		  strHeaderFG =ConfigureSelectionPopup.filterheight(this, vars, strHeaderFG, "185");
		  // Build GRID-Structure
		  strGrid = ConfigureDataGrid.doConfigure(this, vars, "../info/BusinessPartner.html",
					ismulti.equals("Y") ? true : false, "middle");
		  // Build Action Buttons
		  String strTableStructure2 = ConfigureTableStructure.doConfigure(this, vars, "6", "", "Main");
		  strActionButtons = "<tr>";
		  strActionButtons = strActionButtons + ConfigureButton.doConfigure(this, vars, script, "buttonOK", 2, 1,
					false, "ok", "validateSelector('SAVE')", "", "");
		  strActionButtons = strActionButtons + ConfigureButton.doConfigure(this, vars, script, "buttonCancel", 0,
					1, false, "cancel", "validateSelector('CLEAR')", "", "");
		  strActionButtons = strActionButtons + "</tr>";
		  strTableStructure2 = Replace.replace(strTableStructure2, "@CONTENT@", strActionButtons);
		  strTableStructure2 = "<div class=\"Popup_ContentPane_Client\" style=\"overflow: auto; auto; height:50px;\" id=\"client_bottom\">\n"
					+ strTableStructure2 + "</div>";
		  // Replace Filter,GRID and Actionbuttons in Skeleton
		  strOutput = Replace.replace(strSkeleton, "@FILTERCONTENT@", strHeaderFG); 
		  strOutput = Replace.replace(strOutput, "@DATAGRIDCONTENT@", strGrid);
		  strOutput = Replace.replace(strOutput, "@ACTIONBUTTONS@", strTableStructure2);
		  strOutput = script.doScript(strOutput, "", this, vars);
		  // Set Focus
		  strOutput = Replace.replace(strOutput, "setWindowElementFocus('buttonsearch', 'id');","setWindowElementFocus('name', 'id')");
	      // GUI DONE
		  response.setContentType("text/html; charset=UTF-8");
       }
       if (vars.commandIn("STRUCTURE")) {
           ConfigureDataGrid.printGridStructure(response, vars, grid, this);
       }
       if (vars.commandIn("DATA") || (vars.commandIn("KEY")&& !isKeyMultipleOrNone)) {
    	  if (strbpartnerradio.isEmpty())
    		  strbpartnerradio=vars.getSessionValue(getServletInfo() + "|bpartner");
    	  if (vars.commandIn("KEY"))
    		  strbpartnerradio="all"; 
    	  // Set Dynamic Fields
		  String strAux1 = grid.getDynSQL("auxfield1");
		  String strAux1Filter = grid.getDynFilter("auxfield1", strauxfield1);
		  String strAux2 = grid.getDynSQL("auxfield2");
		  String strAux2Filter = grid.getDynFilter("auxfield2", strauxfield2);
		  String strAux3 = grid.getDynSQL("auxfield3");
		  String strAux3Filter = grid.getDynFilter("auxfield3", strauxfield3);
		  String strAux4 = grid.getDynSQL("auxfield4");
		  String strAux4Filter = grid.getDynFilter("auxfield4", strauxfield4);
		  // Key Command with Multiple Results
		  if (vars.getSessionValue(getServletInfo() + "|KeyMultipleOrNone").equals("Y") && vars.commandIn("DATA")) {
			  strName=vars.getSessionValue(getServletInfo() + "|name");	  
			  strValue=	vars.getSessionValue(getServletInfo() + "|value");	  
		  }
		  // Remove Session values
		  vars.removeSessionValue(getServletInfo() + "|KeyMultipleOrNone");
		  vars.removeSessionValue(getServletInfo() + "|name");
		  vars.removeSessionValue(getServletInfo() + "|value");
		  // Technical Parameters (Paging)
		  String pgLimit = ConfigureDataGrid.getLimit("BusinessPartnerSelector", strOffset, vars);
		  String strNumRows = BusinessPartnerData.countRows(this, 
	              (strbpartnerradio.equals("customers") && strcontact.isEmpty() ? "xclients" : ""),
	              (strbpartnerradio.equals("vendors") && strcontact.isEmpty() ? "xvendors" : ""),
	              Utility.getContext(this, vars,"#User_Client", "BusinessPartner"), 
	              Utility.getSelectorOrgs(this, vars, strOrg),strorg,
	              strValue, strName, strcontact, strzip, 
	              (strbpartnerradio.equals("customers") ? "clients" : ""),
	              (strbpartnerradio.equals("vendors") ? "vendors" : ""), strcity,
	              strAux1Filter,strAux2Filter,strAux3Filter,strAux4Filter,pgLimit);
		  if (strNumRows.equals(""))
				strNumRows = "0";
		  vars.setSessionValue("BusinessPartner.numrows", strNumRows); 
		  // Fetch the Data
		  FieldProvider[] data = null;
		  data = BusinessPartnerData.select(this, strAux1,strAux2,strAux3,strAux4,
	              (strbpartnerradio.equals("customers") && strcontact.isEmpty() ? "xclients" : ""),
	              (strbpartnerradio.equals("vendors") && strcontact.isEmpty() ? "xvendors" : ""),
	              Utility.getContext(this, vars,"#User_Client", "BusinessPartner"), 
	              Utility.getSelectorOrgs(this, vars, strOrg),strorg,
	              strValue, strName, strcontact, strzip,
	              (strbpartnerradio.equals("customers") ? "clients" : ""),
	              (strbpartnerradio.equals("vendors") ? "vendors" : ""), strcity, 
	              strAux1Filter,strAux2Filter,strAux3Filter,strAux4Filter,
	              strOrderBy, pgLimit);
		  if (vars.commandIn("KEY"))
			  strOutput = ConfigureSelectionPopup.printPageKey(vars, this, data, grid, "cBpartnerId");
		  if (vars.commandIn("DATA")) {
				String action = vars.getStringParameter("action");
				if (action.equalsIgnoreCase("getIdsInRange"))
					strOutput = ConfigureDataGrid.printPageDataId(vars, grid, this, response, "BusinessPartner", strOffset,data);
				else // getRows
					strOutput = ConfigureDataGrid.printGridData(vars, grid, this, response, "BusinessPartner", strOffset,data);
				response.setContentType("text/xml; charset=UTF-8");
				response.setHeader("Cache-Control", "no-cache");
			}
       }
     }	catch (Exception e) {
			log4j.error("Error in : " + this.getClass().getName() + "\n" + e.getMessage());
			e.printStackTrace();
			throw new ServletException(e);
	 }  
     PrintWriter out = response.getWriter();
	 out.println(strOutput);
	 out.close();
  }
   

  @Override
  public String getServletInfo() {
	  return this.getClass().getName();
  } // end of getServletInfo() method
}
