package org.openbravo.erpCommon.info;
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

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.data.FieldProvider;
import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.utils.Replace;
import org.openz.view.Scripthelper;
import org.openz.view.SelectBoxhelper;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.templates.*;
import org.openz.util.*;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.base.filter.RequestFilter;
import org.openbravo.base.filter.ValueListFilter;
import org.openz.view.Scripthelper;

public class Product extends HttpSecureAppServlet {
	private static final long serialVersionUID = 1L;

	public void init(ServletConfig config) {
		super.init(config);
		boolHist = false;
	}

	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		// Initializing the Grid Structure
		// String[] colWidths,colNames,colDataTypes;
		// boolean[] colSort;
		VariablesSecureApp vars = new VariablesSecureApp(request);
		// Prepare Datagrid Structure
		// In all selectors, Fields name and rowkey are required!
		DataGrid grid = new DataGrid();
		try {

			grid.initGridByAD("ProductSearch", vars, this);
		} catch (Exception e) {
			log4j.error("Error in : " + this.getClass().getName() + "\n" + e.getMessage());
			e.printStackTrace();
			throw new ServletException(e);
		}

		// Get and Set Session Variables
		String isUserPurchaser = PriceListVersionComboData.isUserPurchaser(this, vars.getUser());
		if (isUserPurchaser==null)
			isUserPurchaser="N";
		// Windw ID and issotrx can only be read in the first call, in subsequent calls
		// it is empty.
		String windowId = vars.getStringParameter("WindowID");
		String tabId = vars.getStringParameter("TabID");
		if (!windowId.isEmpty()) {
			// Forget the Persisted Product Category when window changes.
			if ((!windowId.equals(vars.getSessionValue("Product.windowId")))
					|| (!tabId.equals("375773FAA7444EE08B21FB8A3DEDD131")
							&& vars.getSessionValue("Product.tabId").equals("375773FAA7444EE08B21FB8A3DEDD131"))) {
				vars.setSessionValue(getServletInfo() + "|m_Product_Category_Id", "");
				vars.setSessionValue("Product.PersistedCategory", "");
				vars.setSessionValue(getServletInfo() + "|typeofproduct", "");
			}
			vars.setSessionValue("Product.windowId", windowId);
			vars.setSessionValue("Product.tabId", tabId);
		}
		windowId = vars.getSessionValue("Product.windowId");
		String strIssotrx = Utility.getContext(this, vars, "isSOTrx", windowId);
		String strOrg = Utility.getContext(this, vars, "Ad_Org_ID", windowId);
		String strBpartner = "";
		String strCategory = "";
		String strType = "";
		String strBusinessPartnerProducts = null;
		String strWarehouse = "";
		String ismulti = vars.getStringParameter("isMultiLine");
		String strPriceListVersion = "";
		String strSelectMachines = "Y";
		String strActivatePOBPartnerPreselection = ProductData.getActivatePOBPartnerPreselection(this, strOrg); // Y/N;
		if (windowId.equals("E98863010C6541D5BBDEE3990B70148D")) {
			strIssotrx = "N";
		}
		// Remove session-vars, if filter changes
		if (vars.getStringParameter("newFilter").equals("1") || vars.commandIn("KEY") || vars.commandIn("DEFAULT")) {
			removePageSessionVariables(vars);
		}
		// Remove session-vars, if BPartner changes
		if (!Utility.getContext(this, vars, "C_Bpartner_ID", windowId)
				.equals(vars.getSessionValue("Product.PersistedVendor")) && !windowId.equals("")) {
			removePageSessionVariables(vars);
			vars.removeSessionValue("Product.SelectMachines");
			vars.setSessionValue("Product.PersistedVendor", Utility.getContext(this, vars, "C_Bpartner_ID", windowId)); // save
																														// window-values
			if (strIssotrx.equals("N") && strActivatePOBPartnerPreselection.equals("Y")&&!windowId.equals("130")) {
				strBpartner = Utility.getContext(this, vars, "C_Bpartner_ID", windowId);
				vars.setSessionValue(getServletInfo() + "|vendor_id", strBpartner);
			}
		}

		if (windowId.equals("FF1F6A9FFC16491896AD11FABA646DEE")
				|| windowId.equals("A7AF6B7EA2A04616BACD889B62835E17")) {// Direct Purchase // G/L Batch - Pre-select
																			// Product Categorys with isdirectpurchase
																			// Stays in Filter, If Category is never changed by User
			if (vars.getSessionValue(getServletInfo() + "|m_Product_Category_Id").isEmpty()
					&& vars.getSessionValue("Product.PersistedCategory").isEmpty()) {
				vars.setSessionValue(getServletInfo() + "|m_Product_Category_Id",
						ProductData.getDirectPurchaseCategory(this, vars.getOrg()));
				vars.setSessionValue("Product.PersistedCategory",
						ProductData.getDirectPurchaseCategory(this, vars.getOrg()));
				vars.setSessionValue("Product.PresetCategoryType","Y");    	
			}
		}
		if (windowId.equals("181") || windowId.equals("E98863010C6541D5BBDEE3990B70148D") || windowId.equals("183")
				|| tabId.equals("375773FAA7444EE08B21FB8A3DEDD131")
				|| tabId.equals("91AD0EF6558640FCBB4A23BF66F61C91")) {// Footwaretail/Purchase Order / Purchase Invoice
																		// / Tab Vendor Service in Projects: Pre-select
																		// Product Categorys with ispurchasedefault
																		//Stays in Filter, If Category is never changed by User (Not working with Business Partner Preselection - In that case Category is only at first time in filter) 
			if (vars.getSessionValue(getServletInfo() + "|m_Product_Category_Id").isEmpty()
					&& vars.getSessionValue("Product.PersistedCategory").isEmpty()) {
				vars.setSessionValue(getServletInfo() + "|m_Product_Category_Id",
						ProductData.getPurchaseDefaultCategory(this, vars.getOrg()));
				vars.setSessionValue("Product.PersistedCategory",
						ProductData.getPurchaseDefaultCategory(this, vars.getOrg()));
				vars.setSessionValue("Product.PresetCategoryType","Y");    	

			}
		}

		if (windowId.equals("143") || windowId.equals("167")) {// Sales Order / Sales Invoice- Pre-select Product
																// Categorys with issalesdefault - Stays in Filter, If Category is never changed by User 
			if (vars.getSessionValue(getServletInfo() + "|m_Product_Category_Id").isEmpty()
					&& vars.getSessionValue("Product.PersistedCategory").isEmpty()) {
				vars.setSessionValue(getServletInfo() + "|m_Product_Category_Id",
						ProductData.getSalesDefaultCategory(this, vars.getOrg()));
				vars.setSessionValue("Product.PersistedCategory",
						ProductData.getSalesDefaultCategory(this, vars.getOrg()));
				vars.setSessionValue("Product.PresetCategoryType","Y");    	
			}
		}
		if (windowId.equals("143") || windowId.equals("167")) {// Sales Order / Sales Invoice- Select ONLY Business
																// Partner Products
			try {
				if (ProductData.isBPProductSelection(myPool, Utility.getContext(this, vars, "C_Bpartner_ID", windowId))
						.equals("Y"))
					strBusinessPartnerProducts = Utility.getContext(this, vars, "C_Bpartner_ID", windowId);
			} catch (Exception ign) {
			}
		}
		// Custom Fields
		String strAuxfield1 = vars.getStringParameter("inpauxfield1");
		String strAuxfield2 = vars.getStringParameter("inpauxfield2");
		String strAuxfield3 = vars.getStringParameter("inpauxfield3");
		String strAuxfield4 = vars.getStringParameter("inpauxfield4");
		// Get Name, Vendor Product Filters
		String strName = vars.getStringParameter("inpname");
		String strVendorProduct = vars.getStringParameter("inpvendorproductno");
		String strValue = vars.getStringParameter("inpvalue");
		if (strValue.equals("") && !(vars.commandIn("DEFAULT"))) {
			strValue = vars.getStringParameter("inpNameValue");
		}
		// Value Filter - set session var in KEY command
		if (vars.commandIn("KEY")) {
			String strIDValue = vars.getStringParameter("inpIDValue");
			strValue = vars.getStringParameter("inpNameValue") + "%";
			if (!strIDValue.equals("") && strValue.equals(""))
				strValue = ProductData.getValue(this, strIDValue);
			// Test , if there is something with this name
			if (ProductData.getValueCount(this, strValue).equals("0")
					&& !ProductData.getNameCount(this, strValue).equals("0")) {
				strValue = "";
				strName = vars.getStringParameter("inpNameValue") + "%";
			}
			// In KEY command the Value is persisted in session
			vars.setSessionValue(getServletInfo() + "|value", strValue);
			vars.setSessionValue(getServletInfo() + "|name", strName);
		}

		// Session VAR Only if set via KEY - the value must appear in the following DATA
		// command
		if (strValue.equals(""))
			strValue = vars.getSessionValue(getServletInfo() + "|value");
		if (strName.equals(""))
			strName = vars.getSessionValue(getServletInfo() + "|name");
		// Set Rest of persisted Filters (all Dropdown Boxes)
		if (vars.commandIn("DATA")) {
			if (vars.getStringParameter("newFilter").equals("1")) {
				// Read the Content of Dropdown Boxes and persist values in session, If Filter
				// changes
				strBpartner = vars.getRequestGlobalVariable("inpvendorId", getServletInfo() + "|vendor_id");
				strCategory = vars.getRequestGlobalVariable("inpmProductCategoryId",
						getServletInfo() + "|m_Product_Category_Id");
				strType = vars.getRequestGlobalVariable("inptypeofproduct", getServletInfo() + "|typeofproduct");
				strWarehouse = vars.getRequestGlobalVariable("inpmWarehouseId", "Product.warehouse");
				strPriceListVersion = vars.getRequestGlobalVariable("inpmPricelistVersionId",
						getServletInfo() + "|m_Pricelist_Version_Id");
			}
		}
		if (strActivatePOBPartnerPreselection.equals("Y")) {
			// Set the Content of Dropdown Boxes with persisted values from session
			strBpartner = vars.getSessionValue(getServletInfo() + "|vendor_id");
		}
		strCategory = vars.getSessionValue(getServletInfo() + "|m_Product_Category_Id");
		strType = vars.getSessionValue(getServletInfo() + "|typeofproduct");
		strPriceListVersion = vars.getSessionValue(getServletInfo() + "|m_Pricelist_Version_Id");
		// Pricelist may be changed - It could be read from dropdown or from Window
		// Get the Price List from the Calling Window - Only In the 1st call (DEFAULT) ,
		// window ID is filled. The Pricelist-Version is persisted later, so in
		// Subsequent calls the pricelist itself is not evaluated.
		String strPriceList = "";
		// These windows are SO Transactions but change to purchase here for product
		// selection.
		// Here is no vendor persisted - therefore window must be SO, but Products in
		// BOMS schoulde be purchaseble.
		// Also, the Customer Tab in Business-Partner Window is recognized as sales
		// Also machines schoud not be selectable in these Windows. (Project and
		// Production Order and Direct Sales)
		if (windowId.equals("ReportPurchaseDimensionalAnalysesFilterJR")
				|| windowId.equals("ReportInvoiceVendorDimensionalAnalysesJR")
				|| windowId.equals("ReportMaterialDimensionalAnalysesJR")
				|| windowId.equals("ReportSalesDimensionalAnalyzeJR")
				|| windowId.equals("ReportInvoiceCustomerDimensionalAnalysesJR") || windowId.equals("130")
				|| windowId.equals("A2BEBB9B07564D2AAA372B4CB2D01165")
				|| windowId.equals("0C646E51BF1C4C95B34B5D80642C4F29")
				|| tabId.equals("50B59804E9B3426DAEF10DC7170EEF11")) {
			if (windowId.equals("ReportSalesDimensionalAnalyzeJR")
					|| windowId.equals("ReportInvoiceCustomerDimensionalAnalysesJR")
					|| windowId.equals("0C646E51BF1C4C95B34B5D80642C4F29")
					|| tabId.equals("50B59804E9B3426DAEF10DC7170EEF11"))
				strIssotrx = "Y";
			else {
				strIssotrx = "N";
				vars.setSessionValue("Product.SelectMachines", "N"); // Do not select Products that have Serials associated to a Machine (Production Ressources)
			}
		} else {
			strPriceList = vars.getSessionValue(windowId + "|M_Pricelist_ID");
		}

		strSelectMachines = vars.getSessionValue("Product.SelectMachines");
		if (strSelectMachines.isEmpty())
			strSelectMachines = "Y";
		// Utility.getContext(this, vars, "M_Pricelist_ID", windowId);
		if (strPriceList.equals("")) {
			strPriceList = ProductData.priceListDefault(this, Utility.getContext(this, vars, "#User_Client", "Product"),
					Utility.getContext(this, vars, "#AccessibleOrgTree", "Product"), strIssotrx);
		}
		if (strPriceListVersion.equals("") || vars.commandIn("DEFAULT")) {
			// IN Invoice and Order Windows , get order or Invoice Date
			String strDate = vars.getSessionValue(windowId + "|DateOrdered");
			if (strDate.isEmpty())
				strDate = vars.getSessionValue(windowId + "|DateInvoiced");
			if (strDate.isEmpty())
				strDate = DateTimeData.today(this);
			strPriceListVersion = getPriceListVersion(vars, strPriceList, strDate);
		}
		vars.setSessionValue("Product.priceList", strPriceList);
		vars.setSessionValue(getServletInfo() + "|m_Pricelist_Version_Id", strPriceListVersion);
		// Warehouse could be read from dropdown or from Window
		strWarehouse = vars.getSessionValue("Product.warehouse");
		if (strWarehouse.equals(""))
			strWarehouse = Utility.getContext(this, vars, "M_Warehouse_ID", windowId);
		vars.setSessionValue("Product.warehouse", strWarehouse);
		// Technical Parameters
		String strOffset = vars.getStringParameter("offset");
		if (strOffset.equals(""))
			strOffset = "0";
		String strSortCols = vars.getInStringParameter("sort_cols", grid.columnfilter);
		String strSortDirs = vars.getInStringParameter("sort_dirs", grid.directionfilter);
		String strOrderBy = "1";
		if (!strSortCols.equals("") && !strSortDirs.equals(""))
			strOrderBy = SelectorUtility.buildOrderByClause(strSortCols, strSortDirs);
		// Setting Wildcards for searching
		if (strName.equals(""))
			strName = "%";
		if (strVendorProduct.equals(""))
			strVendorProduct = "%";
		if (strBpartner.equals(""))
			strBpartner = "%";
		if (strCategory.equals(""))
			strCategory = "%";

		//
		// Build User Interface
		String strSkeleton = "";
		String strOutput = "";
		String strTableStructure2 = "";
		String strTableCells = "";
		String strGrid = "";
		String strActionButtons = "";
		Scripthelper script = new Scripthelper();
		Formhelper fh = new Formhelper();
		response.setContentType("text/html; charset=UTF-8");
		try {
			if (vars.commandIn("DEFAULT") || vars.commandIn("KEY")) {

				if (vars.commandIn("DEFAULT")) {
					removePageSessionVariables(vars);
					if (strIssotrx.equals("N") && strActivatePOBPartnerPreselection.equals("Y")&& !windowId.equals("130")) {
						strBpartner = Utility.getContext(this, vars, "C_Bpartner_ID", windowId);
						vars.setSessionValue(getServletInfo() + "|vendor_id", strBpartner);
					}
				}

				strSkeleton = ConfigureSelectionPopup.doConfigure(this, vars, "Product", grid, "buttonSearch",
						ismulti.equals("Y") ? true : false, "../Product/Product_Relation.html");
				// In Vertical Menue All Pricelists are Loaded if User is Purchaser.
				if (windowId.equals("VERTICALMENU")) {
					if (isUserPurchaser.equals("Y"))
						vars.setSessionValue("Product.ispurcaser", "Y");
					else
						vars.setSessionValue("Product.ispurcaser", "N");
					vars.setSessionValue("Product.verticalmenue", "Y");
					vars.setSessionValue("Product.Pricelist", "");
				} else
					vars.setSessionValue("Product.verticalmenue", "N");
				// BUILD FILTER
				strTableCells = fh.prepareFieldgroup(this, vars, script, "ProductSelectorFilter", null, false);
				// Direct Filter Functions
				strTableCells = Replace.replace(strTableCells, "changeToEditingMode('onkeypress');", "aceptar(event);");
				script.addFilterAction4ManualServlets("setFilters();");
				// Method to establish Filter Height and grid height derived from in Popups
				strTableCells =ConfigureSelectionPopup.filterheight(this, vars, strTableCells, "185");
				//
				// Build GRID-Structure
				strGrid = ConfigureDataGrid.doConfigure(this, vars, "../info/Product.html",
						ismulti.equals("Y") ? true : false, "middle");
				// Build Action Buttons
				strTableStructure2 = ConfigureTableStructure.doConfigure(this, vars, "6", "", "Main");
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
				strOutput = Replace.replace(strSkeleton, "@FILTERCONTENT@", strTableCells);
				strOutput = Replace.replace(strOutput, "@DATAGRIDCONTENT@", strGrid);
				strOutput = Replace.replace(strOutput, "@ACTIONBUTTONS@", strTableStructure2);
				strOutput = script.doScript(strOutput, "", this, vars);
			}

			if (vars.commandIn("STRUCTURE")) {
				ConfigureDataGrid.printGridStructure(response, vars, grid, this);
			}
			if (vars.commandIn("DATA") || vars.commandIn("KEY")) {
				String isPurchase;
				String isSold;
				String isSales = ProductData.isSOPricelist(this, strPriceListVersion);
				if (isSales == null || isSales.equals("Y")) {
					isPurchase = "'Y','N'";
					isSold = "'Y'";
					// Purchase: Only Purchasing Items
				} else if (isSales.equals("N")) {
					isPurchase = "'Y'";
					isSold = "'Y','N'";
					// All Others: Any Item
				} else {
					isPurchase = "'Y','N'";
					isSold = "'Y','N'";
				}
				//
				// Set Dynamic Fields
				String strAux1 = grid.getDynSQL("auxfield1");
				String strAux1Filter = grid.getDynFilter("auxfield1", strAuxfield1);
				String strAux2 = grid.getDynSQL("auxfield2");
				String strAux2Filter = grid.getDynFilter("auxfield2", strAuxfield2);
				String strAux3 = grid.getDynSQL("auxfield3");
				String strAux3Filter = grid.getDynFilter("auxfield3", strAuxfield3);
				String strAux4 = grid.getDynSQL("auxfield4");
				String strAux4Filter = grid.getDynFilter("auxfield4", strAuxfield4);
				// Select the Data
				if (strType.equals(""))
					strType = "%";
				String pgLimit = ConfigureDataGrid.getLimit("Product", strOffset, vars);
				String strNumRows = "";
				String strRoleCategories = ProductData.getRoleCategories(myPool, vars.getRole());
				if (strBusinessPartnerProducts != null)
					strNumRows = ProductData.countRowspartner(this, vars.getLanguage(), strBusinessPartnerProducts,
							strPriceListVersion, strValue, strName,
							Utility.getContext(this, vars, "#User_Client", "Product"),
							Utility.getSelectorOrgs(this, vars, vars.getOrg()), strCategory, strVendorProduct, strType,
							windowId, strRoleCategories, strAux1Filter, strAux2Filter, strAux3Filter, strAux4Filter,
							pgLimit);
				else
					strNumRows = ProductData.countRows(this, vars.getLanguage(), strPriceListVersion, strValue, strName,
							Utility.getContext(this, vars, "#User_Client", "Product"),
							Utility.getSelectorOrgs(this, vars, vars.getOrg()), isPurchase, isSold, strBpartner,
							strCategory, strSelectMachines, strVendorProduct, strType, windowId, strRoleCategories,
							strAux1Filter, strAux2Filter, strAux3Filter, strAux4Filter, pgLimit);
				if (strNumRows.equals(""))
					strNumRows = "0";
				vars.setSessionValue("Product.numrows", strNumRows);
				FieldProvider[] data;
				if (strBusinessPartnerProducts != null)
					data = ProductData.selectpartner(this, strWarehouse, strPriceListVersion, strAux1, strAux2, strAux3,
							strAux4, strBusinessPartnerProducts, vars.getLanguage(), strValue, strName,
							Utility.getContext(this, vars, "#User_Client", "Product"),
							Utility.getSelectorOrgs(this, vars, vars.getOrg()), strCategory, strVendorProduct, strType,
							windowId, strRoleCategories, strAux1Filter, strAux2Filter, strAux3Filter, strAux4Filter,
							pgLimit, strOrderBy);
				else
					data = ProductData.select(this, strPriceListVersion, strWarehouse, strAux1, strAux2, strAux3,
							strAux4, vars.getLanguage(), strValue, strName,
							Utility.getContext(this, vars, "#User_Client", "Product"),
							Utility.getSelectorOrgs(this, vars, vars.getOrg()), isPurchase, isSold, strBpartner,
							strCategory, strSelectMachines, strVendorProduct, strType, windowId, strRoleCategories,
							strAux1Filter, strAux2Filter, strAux3Filter, strAux4Filter, pgLimit, strOrderBy);
				if (vars.commandIn("KEY") && data.length == 1)

					// hier wird der einzelne Eintrag rausgesucht und irgendwo statisch eine
					// Session-Variable gesetzt
					strOutput = ConfigureSelectionPopup.printPageKey(vars, this, data, grid, "mProductId");
				if (vars.commandIn("DATA")) {
					String action = vars.getStringParameter("action");
					if (action.equalsIgnoreCase("getIdsInRange"))
						strOutput = ConfigureDataGrid.printPageDataId(vars, grid, this, response, "Product", strOffset,
								data);
					else // getRows
						strOutput = ConfigureDataGrid.printGridData(vars, grid, this, response, "Product", strOffset,
								data);
					response.setContentType("text/xml; charset=UTF-8");
					response.setHeader("Cache-Control", "no-cache");
				}
			}
		} catch (Exception e) {
			log4j.error("Error in : " + this.getClass().getName() + "\n" + e.getMessage());
			e.printStackTrace();
			throw new ServletException(e);
		}
		PrintWriter out = response.getWriter();
		out.println(strOutput);
		out.close();
	}

	private void removePageSessionVariables(VariablesSecureApp vars) {
		vars.removeSessionValue(getServletInfo() + "|value");
		vars.removeSessionValue("Product.warehouse");
		vars.removeSessionValue(getServletInfo() + "|m_Pricelist_Version_Id");
		vars.removeSessionValue("Product.currentPage");
		vars.removeSessionValue(getServletInfo() + "|vendor_id");
		if (vars.getSessionValue("Product.PresetCategoryType").isEmpty()) {
			vars.removeSessionValue(getServletInfo() + "|m_Product_Category_Id");
			vars.removeSessionValue(getServletInfo() + "|typeofproduct");
		} else if (vars.commandIn("DATA") || vars.commandIn("KEY"))
			vars.removeSessionValue("Product.PresetCategoryType");
		// vars.removeSessionValue(getServletInfo() + "|value");
		vars.removeSessionValue(getServletInfo() + "|name");
		// remove saved adorgid only when called from DEFAULT,KEY
		// but not when called by clicking search in the selector
		if (!vars.getStringParameter("newFilter").equals("1")) {
			vars.removeSessionValue("Product.adorgid");
		}
	}

	private String getPriceListVersion(VariablesSecureApp vars, String strPriceList, String strDate)
			throws IOException, ServletException {
		PriceListVersionComboData[] data = PriceListVersionComboData.selectActual(this, strPriceList, strDate,
				Utility.getContext(this, vars, "#User_Org", "Product"));
		if (log4j.isDebugEnabled())
			log4j.debug("Selecting pricelistversion date:" + strDate + " - pricelist:" + strPriceList);
		if (data == null || data.length == 0)
			return "";
		return data[0].mPricelistVersionId;
	}

	public String getServletInfo() {
		return this.getClass().getName();
	}
}
