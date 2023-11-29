/*_****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Stefan Zimmermann.
***************************************************************************************************************************************************
*/

package org.openz.internallogistic;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.pdc.controller.PdcCommonData;
import org.openz.pdc.controller.PdcMaterialConsumptionData;
import org.openz.pdc.controller.PdcStatusBar;
import org.openz.pdc.controller.SerialNumberData;
import org.openz.util.ProcessUtils;
import org.openz.util.UtilsData;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.util.*;
import java.math.BigDecimal;

public class InternalTransportOutbound extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);      
    try {
      // Define AD fieldgroup names
      String HeaderADName = "InternalTransportHeader";
      String UpperGridADName = "InternalTransportGrid";
      String ButtonADName = "pdcDoneCancelButtons";
      String LowerGridADName = "InternalTransportGrid";
      String StatusADName = "PdcStatusFG";
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");
      
      // Define AD field names, do NOT use capitals or special characters here
      // These Fields are used to Fill the form after post with Data again.
      String BarcodeADName = "barcode";
      String UserIDADName = "internaltransportuserid";
      String WorkstepIDADName = "transportworkstepid";
      
      // Initialize global structure
      Scripthelper script = new Scripthelper(); // Injects Javascript, hidden fields, etc into the generated html
      Formhelper fh = new Formhelper();         // Injects the styles of fields, grids, etc
      String strOutput = "" ;                   // Resulting html output
      String strSkeleton = "";                  // Structure of the servlet
      String strToolbar = "";                   // Toolbar
      String strPdcInfobar = "";                // Infobar
      String strHeaderFG = "";                  // Header fieldgroup (defined in AD)
      String strUpperGrid = "";                 // Upper grid (defined in AD)
      String strButtonsFG = "";                 // Button fieldgroup (defined in AD)
      String strLowerGrid = "";                 // Lower grid (defined in AD)
      String strStatusFG = "";                  // Status fieldgroup (defined in AD)
      
      // Initialize fieldproviders - they provide data for the grids
      FieldProvider[] upperGridData;    // Data for the upper grid
      FieldProvider[] lowerGridData;    // Data for the lower grid
      
      // Initialize DB dialogue datafield
      PdcCommonData[] data;
      
      // Loading global session variables
      String GlobalUserID = vars.getSessionValue("pdcUserID");
      String GlobalWorkstepID = vars.getSessionValue("pdcWorkStepID");
      String GlobalConsumptionID = vars.getSessionValue("pdcConsumptionID");
      
              
      // Initialize local session variables with user input
      // This is used  to Fill the form  with Data.
      setLocalSessionVariable(vars, UserIDADName);
      setLocalSessionVariable(vars, WorkstepIDADName);
      // Default Status
      vars.setSessionValue("PDCSTATUS","OK");
      
      // Initialize Infobar helper variables
      String InfobarPrefix = "<span style=\"font-size: 32pt; color: #000000;\">";
      String InfobarText = "";
      String InfobarSuffix = "</span>";
      String Infobar = "";
      
      // The Command Issued in the Form
      String BcCommand =vars.getCommand();
      
      // NAVIGATION Between the PDC Servlets
      //Setting SESSION History 
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.internallogistic.ad_forms/InternalTransportOutbound.html"))){
        vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
        strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }
      // DEFAULT-Command means that we come from another Servlet
      if (BcCommand.equals("DEFAULT")) {
         // In case of this servlet it can only be called from PdcMainDialogue.
         // We begin with the provided Status Message
      }
      // Business logic Begins here ###############################################################
      // Local Vars
      String strProductid="";   
      String strIdentifier=vars.getStringParameter("inp" + BarcodeADName);
      // The Scanner Issued the POST of the Form
      if (BcCommand.equals("SAVE_NEW_NEW")) {
        if (!vars.getStringParameter("inp" + BarcodeADName).isEmpty()) {
          // Determine What kind of Barcode was scanned.
          // We can determine PRODUCT, CONTROL, LOCATOR, WORKSTEP, EMPLOYEE
          // Serial Number can not be determined, it is dependent on Product or Transaction or Workstep
          // A serial Number can be the same on different Products.
          data = PdcCommonData.selectbarcode(this, vars.getStringParameter("inp" + BarcodeADName),vars.getRole());
          // In this Servlet CONTROL, EMPLOYEE or WORKSTEP or SERIALNUMBER can be scanned,
          // The First found will be used...
          String bctype="UNKNOWN";
          String bcid="";
          for (int i=0;i<data.length;i++){
            if (data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("WORKSTEP")||data[i].type.equals("SERIALNUMBER")) {
              bcid=data[i].id;  
              bctype=data[i].type;
              break;
            }             
          }         
          if (bctype.equals("EMPLOYEE")) {
            if (GlobalConsumptionID.isEmpty()){
              setLocalSessionVariable(vars, UserIDADName, bcid);
              GlobalUserID=bcid;
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
            } else{
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
            }
            
          } else if (bctype.equals("WORKSTEP")) {
            if  (GlobalConsumptionID.isEmpty()){
              setLocalSessionVariable(vars, WorkstepIDADName, bcid);
              GlobalWorkstepID=bcid;
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
              
            } else{
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
            }
            
          } else if (bctype.equals("CONTROL")) {
            if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC"))
              BcCommand = "CANCEL";
            else if (bcid.equals("8521E358B73444A6A999C55CBCCACC75"))
              BcCommand = "NEXT";
            else if (bcid.equals("B28DAF284EA249C48F932C98F211F257"))
              BcCommand = "DONE";
            else {
              vars.setSessionValue("PDCSTATUS", "ERROR");
              vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
            }
          }
          else if (bctype.equals("UNKNOWN")||bctype.equals("SERIALNUMBER")) {
         // Assume a serial Number was scanned....
            strProductid=SerialNumberData.getProductIdFromSerialATWorkstepReceivingLocator(this,strIdentifier, GlobalWorkstepID);
            if (strProductid!=null)
              BcCommand = "NEXT";
            else {
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
            }
            
          } 
          else {
            vars.setSessionValue("PDCSTATUS", "ERROR");
            vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
          }
        } else { // Barcode is Empty - Assume Keyboard Operation - Read  input Fields          
          GlobalUserID=getLocalSessionVariable(vars, UserIDADName);
          GlobalWorkstepID=getLocalSessionVariable(vars, WorkstepIDADName);
        }
      }
      // AUTOMATIC DEFAULT ACTION when Identifier was scanned.
      // OR the Button NEXT was pressed (in this Case the Identifier must be in the Barcode Field
      // Save the Data and SET Response Ready for NEXT Scan in this Transaction.
      if (BcCommand.equals("NEXT")) {
        if (getLocalSessionVariable(vars, WorkstepIDADName).equals("")||
            getLocalSessionVariable(vars, UserIDADName).equals("")){
          
          vars.setSessionValue("PDCSTATUS","ERROR");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_MustSetTransportAndUser",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
        } else { 
          // Data Is Ready -> Save the data
          Connection conn=this.getConnection();
          if (GlobalConsumptionID.equals("")) {
            GlobalConsumptionID = UtilsData.getUUID(this);
            PdcMaterialConsumptionData.insertConsumption(
                this,
                GlobalConsumptionID,
                vars.getClient(),
                vars.getOrg(),
                vars.getUser(),
                PdcCommonData.getProductionOrderFromWorkstep(this,GlobalWorkstepID),
                GlobalWorkstepID,null);
            vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
          }
          
            String retval=InternalLogisticData.ils_addSerialLine2InternalConsumptionWithWorkstepLocator(this, strProductid, strIdentifier, GlobalConsumptionID,GlobalUserID);
            
            if (retval.equals("ParameterMissing"))
              vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, retval,vars.getLanguage()));
          
        }
      }
      // Commit (Activate) this Transaction and go back to the Main Screen
      if (BcCommand.equals("DONE")) {
          OBError mymess=null;
          boolean iserror=false;
          if (!GlobalConsumptionID.equals("")) {
            // Start internal Consumption Post Process directly
            ProcessUtils.startProcessDirectly(GlobalConsumptionID, "800131", vars, this); 
            // PdcCommonData.doConsumptionPost(this, strConsumptionid);
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MaterialGotSucessful",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
            // If the Process brings an error, stay in this servlet and diplay the message to the user
            mymess=vars.getMessage(getServletInfo());
            if (mymess!=null) {
              if (mymess.getType().equals("Error")) {
                iserror=true;
                vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",mymess.getMessage());
              }
            }
          } else {
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NoData",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
          }
          if (! iserror)
            response.sendRedirect(strDireccion + strpdcFormerDialogue);
      }
     // Abort (Delete) this Transaction and go back to the Main Screen
      if (BcCommand.equals("CANCEL")) {
        Connection conn=this.getConnection();
        PdcCommonData.deleteAllMaterialLines(this, GlobalConsumptionID);
        PdcCommonData.deleteMaterialTransaction( this, GlobalConsumptionID);
        conn.close();
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
        response.sendRedirect(strDireccion + strpdcFormerDialogue);
      }
      // Business logic ENDS here ##############################################################
      
      
      
      // Setting global session variables
      vars.setSessionValue("pdcUserID", GlobalUserID);
      vars.setSessionValue("pdcWorkStepID", GlobalWorkstepID);
      vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      
      
      // Building the User Interface............
      // Setting the InfoBar with the appropriate message
      if (getLocalSessionVariable(vars, UserIDADName) == "") {
        InfobarText = Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage());
      } else if (getLocalSessionVariable(vars, WorkstepIDADName) == "") {
        InfobarText = Utility.messageBD(this, "pdc_ScanWorkstep",vars.getLanguage());
      } else
        InfobarText = Utility.messageBD(this, "pdc_ScanIdentifier",vars.getLanguage());
      // Load grid structure
      EditableGrid uppergrid = new EditableGrid(UpperGridADName, vars, this);  // Load upper grid structure from AD (use AD name)
      upperGridData = InternalLogisticData.selectupperOutbound(this, vars.getLanguage(), GlobalWorkstepID,GlobalConsumptionID);   // Load upper grid date with language for translation
      strUpperGrid = uppergrid.printGrid(this, vars, script, upperGridData);                    // Generate upper grid html code
      
      EditableGrid lowergrid = new EditableGrid(LowerGridADName, vars, this);  // Load lower grid structure from AD (use AD name)
      
      // Load grid data - requires valid xsql file
      lowerGridData =InternalLogisticData.selectlowerOutbound(this, vars.getLanguage(),vars.getSessionValue("pdcWorkStepID"), vars.getSessionValue("pdcConsumptionID"));   // Load lower grid date with language for translation
      
      // Generate servlet skeleton html code
      strToolbar = FormhelperData.getFormToolbar(this, this.getClass().getName());      
      //Window Tabs (Default Declaration)
      WindowTabs tabs;                  //The Servlet Name generated automatically
      tabs = new WindowTabs(this, vars, this.getClass().getName());// Load toolbar ID
      strSkeleton = ConfigureFrameWindow.doConfigure(this, vars, "UserID", null, "Internal Transport Outbound", strToolbar, "NONE", tabs);   // Generate skeleton
       
      // Generate Infobar
      Infobar = InfobarPrefix + InfobarText + InfobarSuffix;
      
      // Generate servlet elements html code
      strPdcInfobar = fh.prepareInfobar(this, vars, script, Infobar, "");                       // Generate infobar html code
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, HeaderADName, null, false);        // Generate header html code
    
      strButtonsFG = fh.prepareFieldgroup(this, vars, script, ButtonADName, null, false);       // Generate buttons html code
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      strStatusFG = PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, StatusADName, null, false);        // Generate status html code
          
      // Manual injections - both grids with defined height and scrollbar
      strUpperGrid = Replace.replace(strUpperGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
      strUpperGrid = Replace.replace(strUpperGrid, "</TABLE>","</TABLE>\n</DIV>");
      strLowerGrid = Replace.replace(strLowerGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
      strLowerGrid = Replace.replace(strLowerGrid, "</TABLE>","</TABLE>\n</DIV>");
      
      // Fit all the content together
      strOutput = Replace.replace(strSkeleton, "@CONTENT@", strPdcInfobar + strHeaderFG + strUpperGrid + strButtonsFG + strLowerGrid + strStatusFG);
      
      // Script operations
      script.addHiddenfield("inpadOrgId", vars.getOrg());
      script.addHiddenShortcut("linkButtonSave_New"); // Adds shortcut for save & new
      script.enableshortcuts("EDITION");              // Enable shortcut for the servlet
      
      // Generating final html code including scripts
      strOutput = script.doScript(strOutput, "", this, vars);
      
      // Generate response
      response.setContentType("text/html; charset=UTF-8");
      PrintWriter out = response.getWriter();
      out.println(strOutput);
      out.close();
    }
    catch (Exception e) { 
      log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
      e.printStackTrace();
      throw new ServletException(e);
    }  
 }

  public String getServletInfo() {
    return this.getClass().getName();
  }
  
  public void setLocalSessionVariable(VariablesSecureApp vars, String ADName) {
    vars.setSessionValue(getServletInfo() + "|" + ADName, vars.getStringParameter("inp" + ADName));
  }
  
  public void setLocalSessionVariable(VariablesSecureApp vars, String ADName, String Value) {
    vars.setSessionValue(getServletInfo() + "|" + ADName, Value);
  }
  
  public String getLocalSessionVariable(VariablesSecureApp vars, String ADName) {
    return vars.getSessionValue(getServletInfo() + "|" + ADName);
  }
  
  public void deleteLocalSessionVariable(VariablesSecureApp vars, String ADName) {
    vars.removeSessionValue(getServletInfo() + "|" + ADName);
  }
}

