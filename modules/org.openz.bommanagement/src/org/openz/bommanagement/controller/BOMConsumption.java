/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Stefan Zimmermann.
***************************************************************************************************************************************************
*/
package org.openz.bommanagement.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.bommanagement.BOMMainDialogueData;
import org.openz.pdc.controller.PdcCommonData;
import org.openz.pdc.controller.PdcMaterialConsumptionData;
import org.openz.pdc.controller.PdcStatusBar;
import org.openz.pdc.controller.SerialNumberData;
import org.openz.pdc.controller.TimeFeedbackData;
import org.openz.util.*;


public class BOMConsumption  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      Vector <String> retval;
      
      Scripthelper script= new Scripthelper();
      Formhelper fh = new Formhelper();    
      PdcCommonData[] data;
      script.addHiddenfield("inpadOrgId", vars.getOrg());
      script.addHiddenfield("inpadClientId", vars.getClient());
      response.setContentType("text/html; charset=UTF-8");
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");
      //if (vars.getCommand().equals("DEFAULT"))
        //removePageSessionVariables(vars);
      // Getting Session VARS
      String strConsumptionid=vars.getSessionValue(getServletInfo()   + "|" +"pdcConsumptionID");
      String strpdcWorkstepID=vars.getSessionValue(getServletInfo()   + "|" +"workstepid");
      String strpdcAssemblyID=vars.getSessionValue(getServletInfo()   + "|" +"assemblyid");
      String strpdcUserID=vars.getSessionValue(getServletInfo()   + "|" +"userid"); 
      if (strpdcUserID.isEmpty())
    	  strpdcUserID=vars.getSessionValue("pdcUserID");
      String strProductID=vars.getSessionValue(getServletInfo()   + "|" +"productid");
      String strLocatorID=vars.getSessionValue(getServletInfo()   + "|" +"locatorid");
      String strSnrID=vars.getSessionValue(getServletInfo()   + "|" +"serialno");
      String strBatchID=vars.getSessionValue(getServletInfo()   + "|" +"batchno");
      // Getting Form Fields
      String strBarcode=vars.getStringParameter("inpbarcode");
      String strQty=vars.getStringParameter("inpqty");
      String text1=vars.getStringParameter("inptext1");
      String text2=vars.getStringParameter("inptext2");
      // Initialize GUI Elements
      String strPdcInfobar="";
      String strPdcInfobox="°";
      String strpdcAssemblyProductID="";
      
      
      try{
       // If a barcode was scanned, look at the result
       if (vars.commandIn("SAVE_NEW_NEW") && (!strBarcode.isEmpty() || ! strQty.isEmpty())) {
         if (!strBarcode.isEmpty()) {
           data = PdcCommonData.selectbarcode(this, strBarcode);
           // In this Servlet CONTROL, EMPLOYEE or PRODUCT or CALCULATION, LOCATOR, WORKSTEP can be scanned,
           // The First found will be used...
           String bctype="UNKNOWN";
           String bcid="";
           for (int i=0;i<data.length;i++){
             if (data[i].type.equals("KOMBI")||data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("PRODUCT")||data[i].type.equals("LOCATOR")||data[i].type.equals("WORKSTEP")) {
               bcid=data[i].id;  
               bctype=data[i].type;
               if (data[i].type.equals("KOMBI")) {
                 strSnrID=data[i].snrmasterdataId;
                 strBatchID=data[i].batchmasterdataId;
               }
               break;
             }  else
               strPdcInfobox=Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage());
           } 
           
           if (strpdcUserID.isEmpty() && bctype.equals("EMPLOYEE")) {
             vars.setSessionValue(getServletInfo()   + "|" +"userid",bcid);
             strpdcUserID=bcid;
           } else if (strpdcWorkstepID.isEmpty() && bctype.equals("WORKSTEP") &&
               UtilsData.getOrgConfigOption(myPool, "directbomscanonlywithworkstep", vars.getOrg()).equals("Y")) {
                 vars.setSessionValue(getServletInfo()   + "|" +"workstepid",bcid);
                 strpdcWorkstepID=bcid;
                 // Lagerort/Assembly ggf. ergänzen
             } else if (! strpdcUserID.isEmpty() && strLocatorID.isEmpty() && bctype.equals("LOCATOR")) {
               vars.setSessionValue(getServletInfo()   + "|" +"locatorid",bcid);
               strLocatorID=bcid;
             } else if (!strLocatorID.isEmpty() && strpdcAssemblyID.isEmpty() && bctype.equals("KOMBI")) {
               if (BOMManagementData.isAssembly(this, BOMMainDialogueData.getproductidfromserial(this, strSnrID)).equals("Y")) {
                 vars.setSessionValue(getServletInfo()   + "|" +"assemblyid",strSnrID);
                 strpdcAssemblyID=strSnrID;
                 strpdcAssemblyProductID=BOMMainDialogueData.getproductidfromserial(this, strSnrID);
               } else
                 strPdcInfobox=Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage());
             } else if (!strLocatorID.isEmpty()  && !strpdcAssemblyID.isEmpty() && strProductID.isEmpty() && bctype.equals("KOMBI")) {
               vars.setSessionValue(getServletInfo()   + "|" +"productid",bcid);
               vars.setSessionValue(getServletInfo()   + "|" +"serialno",strSnrID);
               vars.setSessionValue(getServletInfo()   + "|" +"batchno",strBatchID);
               if (!bcid.equals(strpdcAssemblyID)){
                 strProductID=bcid;
                 if (!strSnrID.isEmpty())
                   strQty="1";
               } else
                 strPdcInfobox=Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage());
               // Lagerort ggf. ergänzen
             } else if (!strLocatorID.isEmpty()  && !strpdcAssemblyID.isEmpty() && strProductID.isEmpty() && bctype.equals("PRODUCT")) {
               if (SerialNumberData.pdc_getSerialBatchType4product(this, bcid).equals("NONE")) {
                 vars.setSessionValue(getServletInfo()   + "|" +"productid",bcid);
                 strProductID=bcid;
               } else
                 strPdcInfobox=Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage());
             }
          else
            strPdcInfobox=Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage());
           
           
           
          
         }
       }
      // Evaluating the other Actions 
      if (vars.commandIn("CANCEL")){
         PdcCommonData.deleteAllMaterialLines( this, strConsumptionid);
         PdcCommonData.deleteMaterialTransaction( this, strConsumptionid);
         removePageSessionVariables(vars);
         vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
         response.sendRedirect(strDireccion + vars.getSessionValue("PDCFORMERDIALOGUE"));
       }
       if (vars.commandIn("DONE")){
         OBError mymess=null;
         boolean iserror=false;
         String msgtext="\n";
         if (!strConsumptionid.equals("")) {

           if (! strpdcWorkstepID.isEmpty() && TimeFeedbackData.isWorstepStarted(this, strpdcWorkstepID).equals("N")) {
             TimeFeedbackData[] res=TimeFeedbackData.beginWorkstepNoMat(this, strpdcWorkstepID, strpdcUserID, vars.getOrg());
             if (res.length>0){
               msgtext=Replace.replace(res[0].outMessagetext,"@","");
               msgtext=Utility.messageBD(this, msgtext,vars.getLanguage());
               }
           }
           // Start internal Consumption Post Process directly - Process Internal Consumption
           ProcessUtils.startProcessDirectly(strConsumptionid, "800131", vars, this); 
           // PdcCommonData.doConsumptionPost(this, strConsumptionid);
           vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MaterialGotSucessful",vars.getLanguage())+msgtext);
           // If the Process brings an error, stay in this servlet and diplay the message to the user
           mymess=vars.getMessage(getServletInfo());
           if (mymess!=null) {
             if (mymess.getType().equals("Error")) {
               iserror=true;
               script.addMessage(this, vars, mymess);
             }
           } 
         } else {
           vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NoData",vars.getLanguage()));
         }
         if (! iserror) {
           response.sendRedirect(strDireccion + vars.getSessionValue("PDCFORMERDIALOGUE"));
           vars.setSessionValue("pdcLASTConsumptionID",strConsumptionid);
           removePageSessionVariables(vars);
         }
       }
       // Save the Data, if all Necessary Data was entered
       if (! strQty.isEmpty()) {
         try {
             if (strConsumptionid.equals("")) {
               strConsumptionid = UtilsData.getUUID(this);
               PdcMaterialConsumptionData.insertConsumption(
                   this,
                   strConsumptionid,
                   vars.getClient(),
                   vars.getOrg(),
                   strpdcUserID,
                   PdcCommonData.getProductionOrderFromWorkstep(this,strpdcWorkstepID),
                   strpdcWorkstepID,null);
               vars.setSessionValue(getServletInfo()   + "|" +"pdcConsumptionID", strConsumptionid);
             }
            // Check if Value Updates a line or deletes a line
             String sameline=BOMManagementData.getIDWhenScannedSameLinewSNR(this,strConsumptionid, strProductID, strLocatorID,strSnrID,strBatchID);
             if (sameline==null) sameline="";
             // Qty > 0 and new line
             if (sameline.equals("")) {
               String strConsumptionLineId = UtilsData.getUUID(this);
               BOMManagementData.insertMaterialLine(this,strConsumptionLineId, vars.getClient(), vars.getOrg(), 
                   strpdcUserID,strConsumptionid,strLocatorID,strProductID,
                   PdcCommonData.getNextLineFromConsumption(this, strConsumptionid),
                   strQty,PdcCommonData.getProductStdUOM(this, strProductID),PdcCommonData.getProductionOrderFromWorkstep(this,strpdcWorkstepID),
                   strpdcWorkstepID,strpdcAssemblyID,text1,text2);
               if (! strSnrID.isEmpty() || ! strBatchID.isEmpty()){
                 BOMManagementData.insertSerialLine(this, vars.getClient(), vars.getOrg(),
                     strpdcUserID, strConsumptionLineId, strQty,BOMManagementData.getBATCHfromMaster(this, strBatchID), BOMManagementData.getSNRfromMaster(this, strSnrID));      
               }
               strPdcInfobox=Utility.messageBD(this, "pdc_ProductScannedCorrectly",vars.getLanguage());
             }
             else {
               strPdcInfobox="Fehler: Artikel " + BOMMainDialogueData.getproductname(this, strProductID) + " wurde in diesem Vorgang bereits erfasst.";
             }
             
             vars.removeSessionValue(getServletInfo()   + "|" +"productid");
             strProductID="";
             vars.removeSessionValue(getServletInfo()   + "|" +"showqty");
             vars.removeSessionValue(getServletInfo()   + "|" +"serialno");
             vars.removeSessionValue(getServletInfo()   + "|" +"batchno");
             strSnrID="";
             strBatchID="";
             strQty="";
         }
         catch (Exception e) { 
           log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
           e.printStackTrace();
           vars.removeSessionValue(getServletInfo()   + "|" +"productid");
           vars.removeSessionValue(getServletInfo()   + "|" +"showqty");
           vars.removeSessionValue(getServletInfo()   + "|" +"serialno");
           vars.removeSessionValue(getServletInfo()   + "|" +"batchno");
           throw new Exception(e.getMessage());
         } 
       }
       
       // Determing the Status in which the Servlet is.. setting infobar
       vars.setSessionValue(getServletInfo()   + "|" +"showqty","N");
       if (strpdcUserID.isEmpty())
         strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, "bom_ScanUser",vars.getLanguage()), "font-size: 32pt; color: #000000;");
       else if (strpdcWorkstepID.isEmpty() && UtilsData.getOrgConfigOption(myPool, "directbomscanonlywithworkstep", vars.getOrg()).equals("Y"))
         strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, "bom_ScanWorkstep",vars.getLanguage()), "font-size: 32pt; color: #000000;");
       else if (strLocatorID.isEmpty())
         strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, "bom_ScanLocator",vars.getLanguage()), "font-size: 32pt; color: #000000;");
       else if (strpdcAssemblyID.isEmpty())
         strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, "bom_ScanAssembly",vars.getLanguage()), "font-size: 32pt; color: #000000;");
       else if (strProductID.isEmpty())
         strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, "bom_ScanProduct",vars.getLanguage()), "font-size: 32pt; color: #000000;");
       else if (strQty.isEmpty()) {
         strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, "bom_ScanQty",vars.getLanguage()), "font-size: 32pt; color: #000000;");
         vars.setSessionValue(getServletInfo()   + "|" +"showqty","Y");
       }
       // Display a message, if applicable
       vars.setSessionValue(getServletInfo()   + "|" +"label",strPdcInfobox);
       // Fill the Status BOX
       String strStatus="";

       if (!strpdcUserID.isEmpty())
         strStatus=LocalizationUtils.getElementTextByElementName(this, "Employee", vars.getLanguage()).concat("                                        ").substring(0, 40) +
                   ":     " + BOMMainDialogueData.getusername(this, strpdcUserID) + "\n";
       if (!strLocatorID.isEmpty())
         strStatus=strStatus+LocalizationUtils.getElementTextByElementName(this, "M_Locator_ID", vars.getLanguage()).concat("                                           ").substring(0, 40)  +
                   ":     " + BOMMainDialogueData.getlocatorname(this, strLocatorID) + "\n";
       if (!strpdcAssemblyID.isEmpty())
         strStatus=strStatus+LocalizationUtils.getElementTextByElementName(this, "Assembly", vars.getLanguage()).concat("/ SN").concat("                                        ").substring(0, 34) +
                   ":     " + BOMMainDialogueData.getproductnamefromserial(this, strpdcAssemblyID) + "/ " + 
                              BOMMainDialogueData.getserialorbatch(this, strpdcAssemblyID,null)+ "\n";
       if (!strProductID.isEmpty())
         strStatus=strStatus+LocalizationUtils.getElementTextByElementName(this, "m_product_id", vars.getLanguage()).concat("                                        ").substring(0, 42) +
                   ":     " + BOMMainDialogueData.getproductname(this, strProductID) + "\n";
                   
       vars.setSessionValue(getServletInfo()   + "|" +"status",strStatus);
       //
       FieldProvider[] upperGridData;    // Data for the upper grid
       FieldProvider[] lowerGridData;    // Data for the lower grid
       // Build the GUI       
       String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
       //Window Tabs (Default Declaration)
       WindowTabs tabs;                  //The Servlet Name generated automatically
       tabs = new WindowTabs(this, vars, this.getClass().getName());
       //Configuring the Structure                                                
       // Load UPPER grid structure only when Workstep is set.
       EditableGrid uppergrid = new EditableGrid("PdcMaterialConsumptionUpperGrid", vars, this);  // Load upper grid structure from AD (use AD name)
       upperGridData = PdcMaterialConsumptionData.selectupper(this, vars.getLanguage(),"1","1",strConsumptionid, strpdcWorkstepID);   // Load upper grid date with language for translation
       String strUpperGrid = "";
       if (!strpdcWorkstepID.isEmpty())
         strUpperGrid =uppergrid.printGrid(this, vars, script, upperGridData);                    
       
       EditableGrid lowergrid = new EditableGrid("PdcMaterialConsumptionLowerGrid", vars, this);  // Load lower grid structure from AD (use AD name)
       lowerGridData = PdcMaterialConsumptionData.selectlower(this, vars.getLanguage(),strConsumptionid);
       //lowerGridData = PdcMaterialReturnData.selectlower(this, vars.getLanguage(),GlobalConsumptionID);
       String strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate low
       //Make the Grids scrollable with these lines
       //we are going to the old table structure into a scrollable area, if the table is bigger than the provided area
       strUpperGrid=Replace.replace(strUpperGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
       strUpperGrid=Replace.replace(strUpperGrid, "</TABLE>","</TABLE>\n</DIV>");
       strLowerGrid=Replace.replace(strLowerGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
       strLowerGrid=Replace.replace(strLowerGrid, "</TABLE>","</TABLE>\n</DIV>"); 
       
       
       String strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inpmProductId",null, "BOM Consumption",strToolbar,"NONE",tabs);
       String strPdcNavigationFG=fh.prepareFieldgroup(this, vars, script, "BOMCosumptionReturnFG", null,false);
       String strOutput=Replace.replace(strSkeleton, "@CONTENT@",strPdcInfobar+ strPdcNavigationFG + strUpperGrid + strLowerGrid);
       script.addHiddenShortcut("linkButtonSave_New");
       script.enableshortcuts("EDITION");
       //Creating the Output
       strOutput = script.doScript(strOutput, "",this,vars);

       
       //Sending the Output
         PrintWriter out = response.getWriter();
         out.println(strOutput);
         out.close();
      }  
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
         throw new ServletException(e.getMessage());
 
      } 
}
    
    private void removePageSessionVariables(VariablesSecureApp vars) { //Removing the Sessionvariables
      vars.removeSessionValue(getServletInfo()   + "|" +"pdcConsumptionID");
      vars.removeSessionValue(getServletInfo()   + "|" +"assemblyid");
      vars.removeSessionValue(getServletInfo()   + "|" +"workstepid");
      vars.removeSessionValue(getServletInfo()   + "|" +"userid");     
      vars.removeSessionValue(getServletInfo()   + "|" +"productid");
      vars.removeSessionValue(getServletInfo()   + "|" +"showqty");
      vars.removeSessionValue(getServletInfo()   + "|" +"locatorid");
      vars.removeSessionValue(getServletInfo()   + "|" +"serialno");
      vars.removeSessionValue(getServletInfo()   + "|" +"batchno");
     
    }

    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

