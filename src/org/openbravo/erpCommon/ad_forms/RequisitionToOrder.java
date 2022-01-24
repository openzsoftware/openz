/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2010 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
 */

package org.openbravo.erpCommon.ad_forms;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.*;
import java.sql.Connection;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.businessUtility.WindowTabsData;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.FormatUtils;
import org.openz.util.UtilsData;
import org.openz.view.*;
import org.openz.view.templates.*;

public class RequisitionToOrder extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    try {
      VariablesSecureApp vars = new VariablesSecureApp(request);

      if (vars.commandIn("FIND"))
        // New Filter defined: Remove old Session Vars
        removeSessionValues(vars);
      // Set session  and read filter
      String strProductId = vars.getGlobalVariable("inpmProductId",
          getServletInfo()  + "|M_Product_ID", "");
      String strDateFrom = vars.getDateParameterGlobalVariable("inpdatefrom", getServletInfo()  + "|DateFrom", this);
      String strDateTo = vars.getDateParameterGlobalVariable("inpdateto", getServletInfo()  + "|DateTo",this);
      String strRequesterId = vars.getGlobalVariable("inprequestor",
          getServletInfo()  + "|requestor", "");
      String strVendorId = vars.getGlobalVariable("inpvendorId",
          getServletInfo()  + "|vendor_id", "");
      String strIncludeVendor = vars.getGlobalVariable("inplineswithoutvendor",
          getServletInfo()  + "|lineswithoutvendor","");
      String strProject=vars.getGlobalVariable("inpcProjectId",
              getServletInfo()  + "|c_project_id","");
      String strProductDesc=vars.getStringParameter("inpdescription");
      if (FormatUtils.isNix(strProductDesc))
    	  strProductDesc="%";
      else
    	  if (!strProductDesc.contains("%"))
    		  strProductDesc=strProductDesc + "%";
      vars.setSessionValue(getServletInfo()  + "|description", strProductDesc);
      String strtypeofproduct=vars.getGlobalVariable("inptypeofproduct",
              getServletInfo()  + "|typeofproduct","");
      String strProductCategory=vars.getGlobalVariable("inpmProductCategoryId",
              getServletInfo()  + "|m_product_category_id","");
      if (strIncludeVendor.equals("")){
        strIncludeVendor="N";
      }
      String strShowReceted = vars.getGlobalVariable("inprejectedlines",
          getServletInfo()  + "|rejectedlines","");
      if (strShowReceted.equals(""))
        strShowReceted="N";
      String strOrgId = vars.getGlobalVariable("inpadOrgId", getServletInfo()  + "|ad_org_id", vars
          .getOrg());
    if (vars.commandIn("DEFAULT")) {
      String strIncVendor = vars.getStringParameter("inplineswithoutvendor");
      if (strIncVendor.equals(""))
        vars.setSessionValue(getServletInfo()  + "|lineswithoutvendor", "Y"); 
      // Generate GUI
      printPageDataSheet(response, vars, strProductId, strDateFrom, strDateTo, strRequesterId,
          strVendorId, strIncludeVendor, strOrgId,strShowReceted,strProject,strProductDesc,strProductCategory,strtypeofproduct);
    } else if (vars.commandIn("FIND")) {
      
      updateLockedLines(vars, strOrgId);
      printPageDataSheet(response, vars, strProductId, strDateFrom, strDateTo, strRequesterId,
          strVendorId, strIncludeVendor, strOrgId,strShowReceted,strProject,strProductDesc,strProductCategory,strtypeofproduct);
    } else if (vars.commandIn("ADD")) {
      // Approve Lines - ADD them to Lower Grid - LOCK em
      EditableGrid grid = new EditableGrid("Requsiton2OrderUpperGrid",vars,this);
      String strRequisitionLines = FormatUtils.vector2sqlForm(grid.getSelectedIds(this, vars, "m_requisitionline_id"));
      updateLockedLines(vars, strOrgId);
      lockRequisitionLines(strOrgId,vars.getUser(), strRequisitionLines);
      printPageDataSheet(response, vars, strProductId, strDateFrom, strDateTo, strRequesterId,
          strVendorId, strIncludeVendor, strOrgId,strShowReceted,strProject,strProductDesc,strProductCategory,strtypeofproduct);
    } else if (vars.commandIn("REMOVE")) {
      // Unapprove Lines - UNLOCK
      // We need the Grid Structure - It generates  Fieldnames  
      EditableGrid grid = new EditableGrid("Requsiton2OrderLowerGrid",vars,this);
      // Read the selected lines
      String strSelectedLines = FormatUtils.vector2sqlForm(grid.getSelectedIds(this, vars, "m_requisitionline_id"));
      unlockRequisitionLines(vars, strSelectedLines);
      updateLockedLines(vars, strOrgId);
      printPageDataSheet(response, vars, strProductId, strDateFrom, strDateTo, strRequesterId,
          strVendorId, strIncludeVendor, strOrgId,strShowReceted,strProject,strProductDesc,strProductCategory,strtypeofproduct);
    } else if (vars.commandIn("SAVE")) {
        // Save Locked LINES for later use
    	updateLockedLines(vars, strOrgId);
        printPageDataSheet(response, vars, strProductId, strDateFrom, strDateTo, strRequesterId,
            strVendorId, strIncludeVendor, strOrgId,strShowReceted,strProject,strProductDesc,strProductCategory,strtypeofproduct);
      }else if (vars.commandIn("REJECT")) {
      EditableGrid grid = new EditableGrid("Requsiton2OrderUpperGrid",vars,this);
      String strRequisitionLines = FormatUtils.vector2sqlForm(grid.getSelectedIds(this, vars, "m_requisitionline_id"));
      //
      updateLockedLines(vars, strOrgId);
      RequisitionToOrderData.reject(this, vars.getUser(), strRequisitionLines);
      printPageDataSheet(response, vars, strProductId, strDateFrom, strDateTo, strRequesterId,
          strVendorId, strIncludeVendor, strOrgId,strShowReceted,strProject,strProductDesc,strProductCategory,strtypeofproduct);
    } else if (vars.commandIn("OPEN_CREATE")) {
      EditableGrid grid = new EditableGrid("Requsiton2OrderLowerGrid",vars,this);
      String strSelectedLines = FormatUtils.vector2sqlForm(grid.getSelectedIds(this, vars, "m_requisitionline_id"));
      updateLockedLines(vars, strOrgId);
      checkSelectedRequisitionLines(response, vars, strSelectedLines);
    } else if (vars.commandIn("GENERATE")) {
      // Get selected Lines, Vendor etc..
      String strSelectedLines = vars.getRequiredGlobalVariable("inpSelected",
          "RequisitionToOrderCreate|SelectedLines");
      String strOrderDate = vars.getDateParameter("inpOrderDate",this);
      if (strOrderDate.isEmpty())
    	  strOrderDate = vars.getSessionValue("RequisitionToOrderCreate|OrderDate");
      String strVendor = vars.getRequiredGlobalVariable("inpOrderVendorId",
          "RequisitionToOrderCreate|OrderVendor");
      String strPriceListId = vars.getRequiredGlobalVariable("inpPriceListId",
          "RequisitionToOrderCreate|PriceListId");
      String strOrg = vars.getRequiredGlobalVariable("inpOrderOrg", "RequisitionToOrderCreate|Org");
      String strWarehouse = vars.getRequiredGlobalVariable("inpWarehouse",
          "RequisitionToOrderCreate|Warehouse");
      OBError myMessage = processPurchaseOrder(vars, strSelectedLines, strOrderDate, strVendor,
          strPriceListId, strOrg, strWarehouse);
      // Closing the Popup - Refresh Main Window
      Scripthelper script = new Scripthelper(); 
      script.addOnload("window.opener.delstash();");
      script.addOnload(" window.onunload = reloadOpener;");
      script.addOnload("top.close();");
      String strOutput = ConfigurePopup.doConfigure(this,vars,script,"CreateDocumentfromRequisition","");
      strOutput=Replace.replace(strOutput, "@CONTENT@",  "");
      strOutput = script.doScript(strOutput, "",this,vars);
      response.setContentType("text/html; charset=UTF-8");
      PrintWriter out = response.getWriter();
      out.println(strOutput);
      out.close(); 
      // Display Message in Main Window
      vars.setMessage(this.getServletInfo(), myMessage);
    } else
      pageError(response);
    }
    catch (Exception e) { 
      log4j.error("Error in : " + getServletInfo()  +"\n" + e.getMessage());
      e.printStackTrace();
      throw new ServletException(e);
    }
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strProductId, String strDateFrom, String strDateTo, String strRequesterId,
      String strVendorId, String strIncludeVendor, String strOrgId,String strShowReceted, String strProject,String strProductDesc,String strProductCategory,String strtypeofproduct) throws IOException,
      ServletException {
 
    // Reimplemented with OPenZ - GUI Engine
    response.setContentType("text/html; charset=UTF-8");
    //
    String strTreeOrg = RequisitionToOrderData.treeOrg(this, vars.getClient());
    // Check if Approval Workflow is required 
    String isPRapprovalworkflow = RequisitionToOrderData.isPRapprovalworkflow(this,strOrgId);
    if (isPRapprovalworkflow == null)
      isPRapprovalworkflow="N";
    // Check if User is approver or Purchaser
    String isPRapprover=RequisitionToOrderData.isPRapprover(this, vars.getUser());
    // Prepare query-string for rejected lines
    String strQyeryRejected;
    if (strShowReceted.equals("Y") )
      strQyeryRejected="'N','Y'";
    else
      strQyeryRejected="'N'";
    // Get the Lines
    RequisitionToOrderData[] datalines = RequisitionToOrderData.selectLines(this, vars
        .getLanguage(), Utility.getContext(this, vars, "#User_Client", "RequisitionToOrder"), Tree
        .getMembers(this, strTreeOrg, strOrgId), strQyeryRejected,strDateFrom, DateTimeData.nDaysAfter(this,
        strDateTo, "1"), strProductId, strRequesterId, (strIncludeVendor.equals("Y") ? strVendorId
        : null), (strIncludeVendor.equals("Y") ? null : strVendorId),strProject,strProductDesc,strProductCategory,strtypeofproduct);
    
    // SZ an Approver can see every locked Line, other Persons only their own locked Lines
    // The selected Lines depends on wether the logged in person is an approver or not.
    // and if workflow is active or not
    RequisitionToOrderData[] dataselected = RequisitionToOrderData.selectSelected(this, vars
        .getLanguage(), 
        isPRapprovalworkflow.equals("Y") ? "Y" : "N",
        isPRapprover.equals("Y") ? "Y" : "N",   
         vars.getUser(),
         Utility.getContext(this, vars, "#User_Client",
        "RequisitionToOrder"), Tree.getMembers(this, strTreeOrg, strOrgId));
    
    // BUILD the GUI with OpenZ GUI Engine 
    Scripthelper script= new Scripthelper();
    script.addOnload("setProcessingMode('window', false);");
    Formhelper fh = new Formhelper();
    String strOutput="";
    try{
      // Load Breadcrumb
      WindowTabs tabs = new WindowTabs(this, vars,getServletInfo() );
      // Load Window Skeleton
      String strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"buttonSearch",tabs.breadcrumb(), "Requisition To Order", null,"NONE",null);
      
      // Filter structure
      String filterStructure=fh.prepareFieldgroup(this, vars, script, "Requisition2OrderFilter", null,false);
      //direct Filter Functions - Add Event 
      //TODO  Move Filter to Scripthelper
      //script.addFilterAction4ManualServlets("submitCommandForm('FIND',true,null,null,'_self');");
      script.addFilterAction4ManualServlets("document.getElementById('buttonsearch').click();");
      filterStructure=Replace.replace(filterStructure, "changeToEditingMode('onkeypress'); return true;", ""); // Remove for PopupSelector
      filterStructure=Replace.replace(filterStructure, "changeToEditingMode('onkeypress');", "aceptar(event);"); // add on all others
      // Load Upper Grid
      EditableGrid grid = new EditableGrid("Requsiton2OrderUpperGrid",vars,this);
      String upperGrid=grid.printGrid(this, vars, script, datalines);
      // Load workflow Buttons
      // Implements Approval Workflow
      String approveButtonGroup=ConfigureTableStructure.doConfigure(this,vars,"8","100%" ,"Main");
      String approveButtons="<tr>";
      if (isPRapprovalworkflow.equals("Y")) {
        if (isPRapprover.equals("Y")){
          // Show Buttons required for Approval
          approveButtons=approveButtons + ConfigureButton.doConfigure(this, vars,script, "approve", 1, 1,false, "lock", "setProcessingMode('window', true);submitCommandForm('ADD', true, null, null, '_self', true);return false;", "", "");
          approveButtons=approveButtons + ConfigureButton.doConfigure(this, vars,script, "reject", 1, 1,false, "erase", "setProcessingMode('window', true);submitCommandForm('REJECT', true, null, null, '_self', true);return false;", "", "");
          approveButtons=approveButtons + ConfigureButton.doConfigure(this, vars,script, "remove", 1, 1,false, "cancel", "setProcessingMode('window', true);submitCommandForm('REMOVE', true, null, null, '_self', true);return false;", "", "");
        }
       }
       else {
         //show Buttons for selection and generation
         approveButtons=approveButtons + ConfigureButton.doConfigure(this, vars,script, "add", 1, 1,false, "lock", "setProcessingMode('window', true);submitCommandForm('ADD', true, null, null, '_self', true);return false;", "", "");
         approveButtons=approveButtons + ConfigureButton.doConfigure(this, vars,script, "remove", 1, 1,false, "cancel", "setProcessingMode('window', true);submitCommandForm('REMOVE', true, null, null, '_self', true);return false;", "", "");
       }
      approveButtons=approveButtons +"</tr>" ;
      approveButtonGroup = Replace.replace(approveButtonGroup, "@CONTENT@", approveButtons);  
      // Load Lower Grid
      grid=new EditableGrid("Requsiton2OrderLowerGrid",vars,this);
      String lowerGrid=grid.printGrid(this, vars, script, dataselected);
      // Add create Button
      String createButtonSructure=ConfigureTableStructure.doConfigure(this,vars,"8","100%" ,"Main") + "<tr>";
      StringBuilder createButton=ConfigureButton.doConfigure(this, vars,script, "create", 1, 1,false, "edit", "setProcessingMode('window', true);openServletNewWindow('OPEN_CREATE', true, 'RequisitionToOrderCreate.html', 'CreatePurchaseOrder', null, false, '600', '800');return false;", "", "");
      createButton.append(ConfigureButton.doConfigure(this, vars,script, "save", 1, 1,false, "save", "setProcessingMode('window', true);submitCommandForm('SAVE', true, null, null, '_self', true);return false;", "", ""));
      createButtonSructure= Replace.replace(createButtonSructure, "@CONTENT@",createButton.toString() + "</tr>");
      // Build the complete Srtructure of the Window
      strOutput=Replace.replace(strSkeleton, "@CONTENT@", filterStructure + upperGrid + approveButtonGroup + lowerGrid + createButtonSructure);  
      strOutput = script.doScript(strOutput, "",this,vars);
    }
    catch (Exception e) { 
      log4j.error("Error in : " + getServletInfo()  +"\n" + e.getMessage());
      e.printStackTrace();
      throw new ServletException(e);
    }
    PrintWriter out = response.getWriter();
    out.println(strOutput);
    out.close(); 

   
  }

  private void lockRequisitionLines(String strOrgId,String strUserId, String strRequisitionLines)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Locking requisition lines: " + strRequisitionLines);
    // SZ Locked By is in Case of centralized Purchase Dept. The Person that currently Logged in
    // In case of PRapprovalworkflow it is the Requestor.
    // If a PR is approved the Requestor can Purchse 
    String isPRapprovalworkflow = RequisitionToOrderData.isPRapprovalworkflow(this,strOrgId);
    if (isPRapprovalworkflow == null)
      isPRapprovalworkflow="N";
   // if (isPRapprovalworkflow.equals("Y")){
   //   RequisitionToOrderData.lockbyRequestor(this,strRequisitionLines);
   // }
   // else
      RequisitionToOrderData.lock(this,strUserId, strRequisitionLines);
  }

  private void unlockRequisitionLines(VariablesSecureApp vars, String strRequisitionLines)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Unlocking requisition lines: " + strRequisitionLines);
    RequisitionToOrderData.unlock(this, strRequisitionLines);
  }

  private void updateLockedLines(VariablesSecureApp vars, String strOrgId) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Update locked lines");
    String isPRapprovalworkflow = RequisitionToOrderData.isPRapprovalworkflow(this,strOrgId);
    if (isPRapprovalworkflow == null)
      isPRapprovalworkflow="N";
    // Check if User is approver or Purchaser
    String isPRapprover=RequisitionToOrderData.isPRapprover(this, vars.getUser());
    String strTreeOrg = RequisitionToOrderData.treeOrg(this, vars.getClient());
    RequisitionToOrderData[] dataselected = RequisitionToOrderData.selectSelected(this, vars
        .getLanguage(),
        isPRapprovalworkflow.equals("Y") ? "Y" : "N",
        isPRapprover.equals("Y") ? "Y" : "N", 
        vars.getUser(), 
        Utility.getContext(this, vars, "#User_Client",
        "RequisitionToOrder"), Tree.getMembers(this, strTreeOrg, strOrgId));
    for (int i = 0; dataselected != null && i < dataselected.length; i++) {
      String strLockQty = vars.getNumericParameter("inpLOCKQty" + dataselected[i].mRequisitionlineId);
      String strLockPrice = vars.getNumericParameter("inpLOCKPrice"
          + dataselected[i].mRequisitionlineId);
      RequisitionToOrderData.updateLock(this, strLockQty, strLockPrice,
          dataselected[i].mRequisitionlineId);
    }
  }
  

  private void checkSelectedRequisitionLines(HttpServletResponse response, VariablesSecureApp vars,
      String strSelected) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Check selected requisition lines");

    // Check unique partner
    String strVendorId = "";
    String strOrderDate = DateTimeData.today(this);
    String strPriceListId = "";
    String strOrgId = "";
    String strMessage = "";
    if (!strSelected.equals("")) {
      RequisitionToOrderData[] vendor = RequisitionToOrderData.selectVendor(this, strSelected);
      if (vendor != null && vendor.length == 1) {
        strVendorId = vendor[0].vendorId;
        strMessage = Utility.messageBD(this, "AllLinesSameVendor", vars.getLanguage())
            + ": "
            + RequisitionToOrderData.bPartnerDescription(this, vendor[0].vendorId, vars
                .getLanguage());
      } else if (vendor != null && vendor.length > 1) {
        // Error, the selected lines are of different vendors, it is
        // necessary to set one.
        strMessage = Utility.messageBD(this, "MoreThanOneVendor", vars.getLanguage());
      } else {
        // Error, it is necessary to select a vendor.
        strMessage = Utility.messageBD(this, "AllLinesNullVendor", vars.getLanguage());
      }
      // Check unique pricelist
      RequisitionToOrderData[] pricelist = RequisitionToOrderData.selectPriceList(this, vars
          .getLanguage(), strSelected);
      if (pricelist != null && pricelist.length == 1) {
        strPriceListId = pricelist[0].mPricelistId;
        strMessage += "<br>" + Utility.messageBD(this, "AllLinesSamePricelist", vars.getLanguage())
            + ": " + pricelist[0].pricelistid;
      } else if (pricelist != null && pricelist.length > 1) {
        // Error, the selected lines are of different pricelists, it is
        // necessary to set one.
        strMessage += "<br>" + Utility.messageBD(this, "MoreThanOnePricelist", vars.getLanguage());
      } else {
        // Error, it is necessary to select a pricelist.
        strMessage += "<br>" + Utility.messageBD(this, "AllLinesNullVendor", vars.getLanguage());
      }

      // Check unique org
      RequisitionToOrderData[] org = RequisitionToOrderData.selectOrg(this, vars.getLanguage(),
          strSelected);
      if (org != null && org.length == 1) {
        strOrgId = org[0].adOrgId;
        strMessage += "<br>" + Utility.messageBD(this, "AllLinesSameOrg", vars.getLanguage())
            + ": " + org[0].org;
      } else {
        // Error, the selected lines are of different orgs, it is
        // necessary to set one.
        strMessage += "<br>" + Utility.messageBD(this, "MoreThanOneOrg", vars.getLanguage());
      }
      OBError myMessage = new OBError();
      myMessage.setTitle("");
      myMessage.setType("Info");
      myMessage.setMessage(strMessage);
      vars.setMessage("RequisitionToOrderCreate", myMessage);
    } else {
      OBError myMessage = new OBError();
      myMessage.setTitle("");
      myMessage.setType("Info");
      myMessage.setMessage(Utility.messageBD(this, "MustSelectLines", vars.getLanguage()));
      vars.setMessage("RequisitionToOrderCreate", myMessage);
    }

    printPageCreate(response, vars, strOrderDate, strVendorId, strPriceListId, strOrgId,
        strSelected);
  }

  private void printPageCreate(HttpServletResponse response, VariablesSecureApp vars,
      String strOrderDate, String strVendorId, String strPriceListId, String strOrgId,
      String strSelected) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Print Create Purchase order");
    String strDescription = Utility.messageBD(this, "RequisitionToOrderCreate", vars.getLanguage());
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_forms/RequisitionToOrderCreate").createXmlDocument();
    xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\r\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("help", Replace.replace(strDescription, "\\n", "\n"));
    {
      OBError myMessage = vars.getMessage("RequisitionToOrderCreate");
      vars.removeMessage("RequisitionToOrderCreate");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }
    xmlDocument.setParameter("paramSelected", strSelected);
    xmlDocument.setParameter("paramOrderVendorId", strVendorId);
    xmlDocument.setParameter("paramOrderVendorDescription", strVendorId.equals("") ? ""
        : RequisitionToOrderData.bPartnerDescription(this, strVendorId, vars.getLanguage()));
    xmlDocument.setParameter("orderDate", UtilsData.selectDisplayDatevalue(this,strOrderDate, "DD-MM-YYYY", vars.getSessionValue("#AD_SqlDateFormat")));
    xmlDocument.setParameter("displayFormat", vars.getSessionValue("#AD_SqlDateFormat"));
    xmlDocument.setParameter("paramOrderOrgId", strOrgId);
    xmlDocument.setParameter("arrayWarehouse", Utility.arrayDobleEntrada("arrWarehouse",
        RequisitionToOrderData.selectWarehouseDouble(this, vars.getClient(), Utility.getContext(
            this, vars, "#AccessibleOrgTree", "RequisitionToOrder"), Utility.getContext(this, vars,
            "#User_Client", "RequisitionToOrder"))));
    xmlDocument.setParameter("paramPriceListId", strPriceListId);
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_Org_ID", "",
          "AD_Org Trx Security validation", Utility.getContext(this, vars, "#User_Org",
              "RequisitionToOrder"), Utility.getContext(this, vars, "#User_Client",
              "RequisitionToOrder"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "RequisitionToOrder", strOrgId);
      xmlDocument.setData("reportOrderOrg_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "M_Pricelist_ID",
          "", "Purchase Pricelist", Utility.getContext(this, vars, "#AccessibleOrgTree",
              "RequisitionToOrder"), Utility.getContext(this, vars, "#User_Client",
              "RequisitionToOrder"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "RequisitionToOrder",
          strPriceListId);
      xmlDocument.setData("reportPriceList_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private OBError processPurchaseOrder(VariablesSecureApp vars, String strSelected,
      String strOrderDate, String strVendor, String strPriceListId, String strOrg,
      String strWarehouse) throws IOException, ServletException {
    StringBuffer textMessage = new StringBuffer();
    Connection conn = null;

    OBError myMessage = null;
    myMessage = new OBError();
    myMessage.setTitle("");

   
//  SZ: Price not found must be possible    
//    RequisitionToOrderData[] noprice = RequisitionToOrderData.selectNoPrice(this, vars
//        .getLanguage(), strPriceListVersionId, strSelected);
//    if (noprice != null && noprice.length > 0) {
//      textMessage.append(Utility.messageBD(this, "LinesWithNoPrice", vars.getLanguage())).append(
//          "<br><ul>");
//      for (int i = 0; i < noprice.length; i++) {
//        textMessage.append("<li>").append(noprice[i].product);
//      }
//      textMessage.append("</ul>");
//      myMessage.setType("Error");
//      myMessage.setMessage(textMessage.toString());
//      return myMessage;
//    }

    RequisitionToOrderData[] data1 = RequisitionToOrderData.selectVendorData(this, strVendor);
    if (data1[0].poPaymenttermId == null || data1[0].poPaymenttermId.equals("")) {
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, "VendorWithNoPaymentTerm", vars.getLanguage()));
      return myMessage;
    }

    try {
      conn = getTransactionConnection();
      String strCOrderId = SequenceIdData.getUUID();
      // PO (Normal)
      String docTargetType ="B342FD5CA1C64E8BA25A0A6F6C98C7DA";
        // SZ TODO : Configure Doctypes Correctly
        //RequisitionToOrderData.cDoctypeTarget(conn, this, vars.getClient(),strOrg);
      String strDocumentNo = Utility.getDocumentNo(this, vars, "", "C_Order", docTargetType,
          docTargetType, false, true);
      String cCurrencyId = RequisitionToOrderData.selectCurrency(this, strPriceListId);
      try {
        RequisitionToOrderData.insertCOrder(conn, this, strCOrderId, vars.getClient(), strOrg, vars
            .getUser(), strDocumentNo, "DR", "CO", "0", docTargetType, strOrderDate, strOrderDate,
            strOrderDate, strVendor, RequisitionToOrderData.cBPartnerLocationId(this, strVendor),
            RequisitionToOrderData.billto(this, strVendor).equals("") ? RequisitionToOrderData
                .cBPartnerLocationId(this, strVendor) : RequisitionToOrderData.billto(this,
                strVendor), cCurrencyId, data1[0].paymentrulepo, data1[0].poPaymenttermId,
            data1[0].invoicerule.equals("") ? "I" : data1[0].invoicerule, data1[0].deliveryrule
                .equals("") ? "A" : data1[0].deliveryrule, "I",
            data1[0].deliveryviarule.equals("") ? "D" : data1[0].deliveryviarule, strWarehouse,
            strPriceListId,RequisitionToOrderData.selectproject(myPool, strSelected),
            RequisitionToOrderData.selecttask(myPool, strSelected));
      } catch (ServletException ex) {
        myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
        releaseRollbackConnection(conn);
        return myMessage;
      }

      int line = 0;
      String strCOrderlineID = "";
      BigDecimal qty = new BigDecimal("0");
      BigDecimal qtyOrder = new BigDecimal("0");
      boolean insertLine = false;

      RequisitionToOrderData[] lines = RequisitionToOrderData.linesToOrder(this, 
          RequisitionToOrderData.billto(this, strVendor),strOrg,  strSelected);
      String cAssetID="";
      String c_ProjectID="";
      String cProjectphaseid="";
      String cProjecttaskId="";
      for (int i = 0; lines != null && i < lines.length; i++) {
        if (!lines[i].cProjectId.equals("") || !lines[i].aAssetId.equals("")){
          cAssetID=lines[i].aAssetId;
          c_ProjectID=lines[i].cProjectId;
          cProjectphaseid=lines[i].cProjectphaseId;
          cProjecttaskId=lines[i].cProjecttaskId;
        }
        if (i == 0)
          strCOrderlineID = SequenceIdData.getUUID();
        if (i == lines.length - 1) {
          insertLine = true;
          qtyOrder = qty;
        } else if (!lines[i + 1].mProductId.equals(lines[i].mProductId)
            || !lines[i + 1].mAttributesetinstanceId.equals(lines[i].mAttributesetinstanceId)
            || !lines[i + 1].note.equals(lines[i].note)
            || !lines[i + 1].priceactual.equals(lines[i].priceactual)) {
          insertLine = true;
          qtyOrder = qty;
          qty = new BigDecimal(0);
        } else {
          qty = qty.add(new BigDecimal(lines[i].lockqty));
        }
        lines[i].cOrderlineId = strCOrderlineID;
        if (insertLine) {
          insertLine = false;
          line += 10;
          BigDecimal qtyAux = new BigDecimal(lines[i].lockqty);
          qtyOrder = qtyOrder.add(qtyAux);
          if (log4j.isDebugEnabled())
            log4j.debug("Lockqty: " + lines[i].lockqty + " qtyorder: " + qtyOrder.toPlainString()
                + " new BigDecimal: " + (new BigDecimal(lines[i].lockqty)).toString() + " qtyAux: "
                + qtyAux.toString());

          try {
            String plvid=RequisitionToOrderData.selectPricelistversion(this, strPriceListId);
            RequisitionToOrderData.insertCOrderline(conn, this, strCOrderlineID, vars.getClient(),
                strOrg, vars.getUser(), strCOrderId, Integer.toString(line), strVendor,
                RequisitionToOrderData.cBPartnerLocationId(this, strVendor), strOrderDate,
                strOrderDate, lines[i].note, lines[i].mProductId,
                lines[i].mAttributesetinstanceId, strWarehouse, lines[i].cUomId, qtyOrder
                    .toPlainString(), cCurrencyId, plvid,lines[i].priceactual,
                    strPriceListId, lines[i].tax, lines[i].discount,
                lines[i].aAssetId,lines[i].cProjectId,lines[i].cProjectphaseId,lines[i].cProjecttaskId);
          } catch (ServletException ex) {
            myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
            releaseRollbackConnection(conn);
            return myMessage;
          }

          strCOrderlineID = SequenceIdData.getUUID();
        }
      }
      //unlockRequisitionLines(vars, strSelected);
      for (int i = 0; lines != null && i < lines.length; i++) {
        String strRequisitionOrderId = SequenceIdData.getUUID();
        try {
          RequisitionToOrderData.insertRequisitionOrder(conn, this, strRequisitionOrderId, vars
              .getClient(), strOrg, vars.getUser(), lines[i].mRequisitionlineId,
              lines[i].cOrderlineId, lines[i].lockqty);
        } catch (ServletException ex) {
          myMessage = Utility.translateError(this, vars, vars.getLanguage(), ex.getMessage());
          releaseRollbackConnection(conn);
          return myMessage;
        }
        if (lines[i].toClose.equals("Y"))
          RequisitionToOrderData.requisitionStatus(conn, this, lines[i].mRequisitionlineId, vars
              .getUser());
      }
      // SZ Set Reference for new Order.
      // If more than one reference to Asset or Project exists, the one on the last line was selected.
      RequisitionToOrderData.updateOrderReference(this, cAssetID, c_ProjectID, cProjectphaseid, cProjecttaskId, strCOrderId);
      // SZ: A new Order schould not be closed. 
      //     OBError myMessageAux = cOrderPost(conn, vars, strCOrderId);

      releaseCommitConnection(conn);
      String strWindowName = WindowTabsData.selectWindowInfo(this, vars.getLanguage(), "181");
      textMessage.append(strWindowName).append(" : ");
      textMessage.append(RequisitionToOrderData.getDocLink(this, strCOrderId, strDocumentNo));
//      if (myMessageAux.getMessage().equals(""))
        textMessage.append(Utility.messageBD(this, "Success", vars.getLanguage()));
//      else
//        textMessage.append(myMessageAux.getMessage());

//      myMessage.setType(myMessageAux.getType());
      myMessage.setMessage(textMessage.toString());
      myMessage.setType("Success");
      return myMessage;
    } catch (Exception e) {
      try {
        if (conn != null)
          releaseRollbackConnection(conn);
      } catch (Exception ignored) {
      }
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, "ProcessRunError", vars.getLanguage()));
      return myMessage;
    }
  }

 

  private void removeSessionValues(VariablesSecureApp vars ){
    vars.removeSessionValue(getServletInfo()  + "|M_Product_ID");
    vars.removeSessionValue(getServletInfo()  + "|DateFrom");
    vars.removeSessionValue(getServletInfo()  + "|DateTo");
    vars.removeSessionValue(getServletInfo()  + "|requestor");
    vars.removeSessionValue(getServletInfo()  + "|vendor_id");
    vars.removeSessionValue(getServletInfo()  + "|lineswithoutvendor");
    vars.removeSessionValue(getServletInfo()  + "|rejectedlines");
    vars.removeSessionValue(getServletInfo()  + "|ad_org_id");
    vars.removeSessionValue(getServletInfo()  + "|ad_org_id");
    vars.removeSessionValue(getServletInfo()  + "|m_product_category_id");
    vars.removeSessionValue(getServletInfo()  + "|c_project_id");
    vars.removeSessionValue(getServletInfo()  + "|description");
    vars.removeSessionValue(getServletInfo()  + "|typeofproduct");
  }
  public String getServletInfo() {
    return this.getClass().getName() ;
  } // end of getServletInfo() method
}
