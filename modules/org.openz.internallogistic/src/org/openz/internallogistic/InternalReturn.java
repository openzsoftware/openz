/*__________| PDC - Material Consumption |_________________________________________________
 * The contents of this file are subject to the Mozilla Public License Version 1.1
 * Copyright:           OpenZ
 * Author:              Frank.Wohlers@OpenZ.de          (2013)
 * Contributor(s):      Danny.Heuduk@OpenZ.de           (2013)
 *_________________________________________________________________________| MPL1.1 |___fw_*/

package org.openz.internallogistic;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;

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
import org.openz.pdc.controller.PdcMaterialReturnData;
import org.openz.pdc.controller.PdcStatusBar;
import org.openz.pdc.controller.SerialNumberData;
import org.openz.util.*;
import org.openz.view.EditableGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFrameWindow;

public class InternalReturn extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);      
    // Define AD fieldgroup names
    String HeaderADName = "InternalConsumptionHeader";
    String UpperGridADName = "InternalConsumptionUpperGridLocator";
    String UpperGridUserADName = "InternalConsumptionUpperGridUser";
    String ButtonADName = "pdcNextDoneCancelButtons";
    String LowerGridADName = "InternalConsumptionLowerGrid";
    String StatusADName = "PdcStatusFG";
    Boolean scanlocator=false;
    if (vars.getOrg().equals("0"))
      throw new ServletException("@needOrg2UseFunction@");
    
    // Define AD field names, do NOT use capitals or special characters here
    // These Fields are used to Fill the form after post with Data again.
   
    
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
    String GlobalConsumptionID = vars.getSessionValue("pdcConsumptionID");
    
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
    if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.internallogistic.ad_forms/InternalReturn.html"))){
      vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
      strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
    }
    // DEFAULT-Command means that we come from another Servlet
    if (BcCommand.equals("DEFAULT")) {
       // In case of this servlet it can only be called from PdcMainDialogue.
       // We begin with the provided Status Message
    }
    // Delete the Scanned unknown Code if no employee is added to that code
    if (! BcCommand.equals("CODE2EMPLOYEE")) 
      SessionUtils.deleteLocalSessionVariable(getServletInfo(), vars, "addcodetoemployee");
    // Business logic Begins here ###############################################################
    // Read Form Input Values
    String strUserid=SessionUtils.readInput(vars, "ad_user_id");
    String strQty=SessionUtils.readInput(vars, "quantity");         
    String strLocatorid=SessionUtils.readInput(vars, "m_locator_id");
    String strProductid=SessionUtils.readInput(vars, "m_product_id");
    String strBarcode=SessionUtils.readInput(vars, "barcode");
    String strSerialnumber="";
    // The Scanner Issued the POST of the Form
    if (BcCommand.equals("SAVE_NEW_NEW")) {
      if (!strBarcode.isEmpty()) {
        // Determine What kind of Barcode was scanned.
        // We can determine PRODUCT, CONTROL, LOCATOR, WORKSTEP, EMPLOYEE
        // Serial Number can not be determined, it is dependent on Product or Transaction or Workstep
        // A serial Number can be the same on different Products.
        data = PdcCommonData.selectbarcode(this,SessionUtils.readInput(vars, "barcode") );
        // In this Servlet CONTROL, EMPLOYEE or WORKSTEP, LOCATOR, PRODUCT and CALCULATION can be scanned,
        // The First found will be used...
        String bctype="UNKNOWN";
        String bcid="";
        for (int i=0;i<data.length;i++){
          if (data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("WORKSTEP")||data[i].type.equals("LOCATOR")||data[i].type.equals("PRODUCT")||data[i].type.equals("CALCULATION")) {
            bcid=data[i].id;  
            bctype=data[i].type;
            break;
          }             
        }         
        
        if (bctype.equals("EMPLOYEE")) {
          if (GlobalConsumptionID.isEmpty()){
            strUserid=bcid;
            GlobalUserID=bcid;
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          } else{
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          }
          
        } else if (bctype.equals("WORKSTEP")) {
          vars.setSessionValue("PDCSTATUS", "ERROR");
          vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          
        } else if (bctype.equals("LOCATOR")) {
          strLocatorid=bcid;
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        } else if (bctype.equals("PRODUCT")) {
          strProductid=bcid;
          strQty="1";
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          
        } else if (bctype.equals("CONTROL")) {
          if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC"))
            BcCommand = "CANCEL";
          else if (bcid.equals("8521E358B73444A6A999C55CBCCACC75"))
            BcCommand = "NEXT";
          else if (bcid.equals("B28DAF284EA249C48F932C98F211F257"))
            BcCommand = "DONE";
          else {
            vars.setSessionValue("PDCSTATUS", "ERROR");
            vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          }
        }
        else if (bctype.equals("CALCULATION")) {
          int scanqty= Integer.parseInt(strBarcode);  
          if (strQty.isEmpty()){
            strQty="0";}
          int qtnow=Integer.parseInt(strQty);
          int qtysum=(qtnow + scanqty);
          strQty=Integer.toString(qtysum);
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        }
        else if (bctype.equals("UNKNOWN")) {
       // Assume a serial Number was scanned....
          if (strLocatorid.isEmpty()){
            strProductid=SerialNumberData.getProductIdFromSerial(this,strBarcode);
            strLocatorid=SerialNumberData.getLocatorIdFromSerialAndProduct(this,strBarcode,strProductid);
            if (strLocatorid.isEmpty()){
              // Not Stocked- SNR can be returned
              scanlocator=true;             
            }
            else {
              strProductid="";
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_serialisstocked",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
            }
          } else {
            strProductid=SerialNumberData.getProductIdFromSerial(this,strBarcode);
            String templocator=SerialNumberData.getLocatorIdFromSerialAndProduct(this,strBarcode,strProductid);
            if (! templocator.isEmpty()){
              strProductid="";
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_serialisstocked",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
            }
          }
          if (strProductid!=null) {
            BcCommand = "NEXT";
            strQty="1";
            strSerialnumber=strBarcode;
          }
          else {
            strProductid="";
            strLocatorid="";
            if (strUserid.isEmpty())
              SessionUtils.setLocalSessionVariable(getServletInfo(), vars, "addcodetoemployee",strBarcode);
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          }
          
        } 
        else {
          vars.setSessionValue("PDCSTATUS", "ERROR");
          vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        }
      }else { // Barcode is Empty - Assume Keyboard Operation . Test if User Changed...         
        if (!GlobalUserID.equals(strUserid)&& !GlobalConsumptionID.isEmpty()){
          strUserid=GlobalUserID;
          vars.setSessionValue("PDCSTATUS","ERROR");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        }  
        GlobalUserID=strUserid;
      }
    }
    try {
      // AUTOMATIC DEFAULT ACTION when Identifier was scanned.
      // OR the Button NEXT was pressed (in this Case the Identifier must be in the Barcode Field
      // Save the Data and SET Response Ready for NEXT Scan in this Transaction.
      if (BcCommand.equals("NEXT")) {
        if (strUserid.isEmpty()||strProductid.isEmpty()||strLocatorid.isEmpty()||strQty.isEmpty()){          
          vars.setSessionValue("PDCSTATUS","ERROR");
          //vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_MustSetUserProductLocator",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MustSetProductQtyAndLocator",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        } else { 
          // Data Is Ready -> Save the data
          Connection conn=this.getConnection();
          if (GlobalConsumptionID.equals("")) {
            GlobalConsumptionID = UtilsData.getUUID(this);
            PdcMaterialReturnData.insertConsumption(
                this,
                GlobalConsumptionID,
                vars.getClient(),
                vars.getOrg(),
                vars.getUser(),
                "",
                "",null);
            vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
          }
          String retval="";
          if (!strSerialnumber.isEmpty())
            retval=InternalLogisticData.ils_addSerialLine2InternalConsumptionInbound(this, strProductid, strSerialnumber, GlobalConsumptionID,strUserid,strLocatorid);
          else
            retval=InternalLogisticData.addLine2InternalConsumption(this, strProductid, strLocatorid,strQty,"", GlobalConsumptionID,strUserid);
          if (retval.equals("ParameterMissing"))
            vars.setSessionValue("PDCSTATUS","ERROR");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, retval,vars.getLanguage()));
            
        }
      }
      // Commit (Activate) this Transaction and go back to the Main Screen
      if (BcCommand.equals("DONE")) {
        if (PdcCommonData.isbatchorserialnumber(this, GlobalConsumptionID).equals("N")){
          OBError mymess=null;
          boolean iserror=false;
          if (!GlobalConsumptionID.equals("")) {
            // Start internal Consumption Post Process directly
            ProcessUtils.startProcessDirectly(GlobalConsumptionID, "800131", vars, this); 
            // PdcCommonData.doConsumptionPost(this, strConsumptionid);
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MaterialReturnSucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
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
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NoData",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          }
          if (! iserror)
            response.sendRedirect(strDireccion + strpdcFormerDialogue);
        } else {
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionPreparedSerialNumberNecessary",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          vars.setSessionValue("PDCINVOKESERIAL","DONE");
          //second layer
          if (strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMainDialogue.html")){
                   vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.internallogistic.ad_forms/InternalReturn.html");
                   strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
           }
          response.sendRedirect(strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");
        }
      }
     // Abort (Delete) this Transaction and go back to the Main Screen
      if (BcCommand.equals("CANCEL")) {
        Connection conn=this.getConnection();
        PdcCommonData.deleteAllMaterialLines( this, GlobalConsumptionID);
        PdcCommonData.deleteMaterialTransaction( this, GlobalConsumptionID);
        conn.close();
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        response.sendRedirect(strDireccion + strpdcFormerDialogue);
      }
      // Add the Scanned code to a User as its Personal ID
      if (BcCommand.equals("CODE2EMPLOYEE")) {
        String empcode=SessionUtils.getLocalSessionVariable(getServletInfo(), vars, "addcodetoemployee");
        SessionUtils.deleteLocalSessionVariable(getServletInfo(), vars, "addcodetoemployee");
        if (! empcode.isEmpty() && ! strUserid.isEmpty()) {
          InternalLogisticData.addCode2Employee(this, empcode, strUserid);
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_AddedCode2Employee",vars.getLanguage())+"\r\n"+empcode);
        }
        else {
          vars.setSessionValue("PDCSTATUS","ERROR");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_CannotAddNoEmployeeSelected",vars.getLanguage()));
        }
      }
    }
    catch (Exception e) { 
      log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
      e.printStackTrace();
      vars.setSessionValue("PDCSTATUS","ERROR"); 
      if (e.getMessage().contains("@snr_")){
        OBError temp=Utility.translateError(this, vars, vars.getLanguage(), e.getMessage());
        vars.setSessionValue("PDCSTATUSTEXT",temp.getMessage());
      }else {
        //vars.setSessionValue("PDCSTATUSTEXT","Error in Serial Number Screen");
    	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ErrorOnPage"+"\r\n"+getServletInfo(),vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
    	  throw new ServletException(e);
      }
      BcCommand="DEFAULT";
    }  
    try {
     // Set the Session and local Vars for filling the GUI
      SessionUtils.setLocalSessionVariable(getServletInfo(),vars, "ad_user_id", strUserid);
      if (BcCommand.equals("NEXT")){
        strQty="";
        //strLocatorid="";
        strProductid="";
      }
      SessionUtils.setLocalSessionVariable(getServletInfo(),vars, "quantity",strQty);  
      SessionUtils.setLocalSessionVariable(getServletInfo(),vars, "m_locator_id", strLocatorid);   
      SessionUtils.setLocalSessionVariable(getServletInfo(),vars, "m_product_id",strProductid);
      //
      // Business logic ENDS here ##############################################################
      
      // Setting global session variables
      vars.setSessionValue("pdcUserID", GlobalUserID);
      vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      
      
      // Building the User Interface............
      // Setting the InfoBar with the appropriate message
      if (strUserid.isEmpty()||strLocatorid.isEmpty()) {
        InfobarText = Utility.messageBD(this, "pdc_ScanUserOrLocator",vars.getLanguage());
        if (! SessionUtils.getLocalSessionVariable(getServletInfo(), vars, "addcodetoemployee").isEmpty())
          InfobarText = Utility.messageBD(this, "pdc_PressAddEmployee",vars.getLanguage());
      } else
        InfobarText = Utility.messageBD(this, "pdc_ScanIdentifier",vars.getLanguage());
      // Load grid structure
      EditableGrid lowergrid = new EditableGrid(LowerGridADName, vars, this);  // Load lower grid structure from AD (use AD name)
      
      // Load grid data - requires valid xsql file
      lowerGridData =InternalLogisticData.selectlowerConsumption(this, vars.getLanguage(),GlobalConsumptionID);   // Load lower grid date with language for translation
      
      // Generate servlet skeleton html code
      strToolbar = FormhelperData.getFormToolbar(this, this.getClass().getName());      
      //Window Tabs (Default Declaration)
      WindowTabs tabs;                  //The Servlet Name generated automatically
      tabs = new WindowTabs(this, vars, this.getClass().getName());// Load toolbar ID
      strSkeleton = ConfigureFrameWindow.doConfigure(this, vars, "Barcode", null, "Internal Return", strToolbar, "NONE", tabs);   // Generate skeleton
       
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
  
 
  }

