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
import org.openz.pdc.controller.PdcStatusBar;
import org.openz.pdc.controller.SerialNumberData;
import org.openz.util.*;
import org.openz.view.EditableGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFrameWindow;

public class Inventory extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);      
    // Define AD fieldgroup names
    String HeaderADName = "InventoryHeader";
    String AdditionfieldsADName = "InventoryAdditionFields";
    String ButtonADName = "pdcNextDoneCancelButtons";
    String LowerGridADName = "InventoryLowerGrid";
    String StatusADName = "PdcStatusFG";
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
    String strButtonsFG = "";                 // Button fieldgroup (defined in AD)
    String strLowerGrid = "";                 // Lower grid (defined in AD)
    String strStatusFG = "";                  // Status fieldgroup (defined in AD)
    
    // Initialize fieldproviders - they provide data for the grids
    FieldProvider[] lowerGridData;    // Data for the lower grid
    // The Command Issued in the Form
    String BcCommand =vars.getCommand();
    // For Determin the Barvcode Type
    PdcCommonData[] data;
    // Indoicate the State of servlet
    String strServletState="";
    // Initialize Infobar helper variables
    String InfobarPrefix = "<span style=\"font-size: 32pt; color: #000000;\">";
    String InfobarText = "";
    String InfobarSuffix = "</span>";
    String Infobar = "";
    // Init Call
    if (BcCommand.equals("DEFAULT")) {
      // In case of this servlet it can only be called from PdcMainDialogue.
      // We begin with the provided Status Message
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars,"pdcInventoryID");
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars,"SNR_Masterdata_ID");
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars,"ilsNewSerialNoInventory");
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "ad_user_id"); // Empfänger 
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "m_product_id");
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "model"); //Artikelbezeichnung / Gerätetext
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "orderreference");    // Ticketnr. / Bestell-ID
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "identifier3"); // Internal Inventory Number
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "identifier2"); // Serial Number of Vendor
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "externaltrackingno"); // SIGMA-Auftragsnr.
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "remark"); // Bemerkung (Finanzierung)
      SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "vendor"); // Lieferant
    }
 
    // Loading session variables
    String strInventoryID = SessionUtils.getLocalSessionVariable(getServletInfo(),vars,"pdcInventoryID");
    String strSourceSerialID = SessionUtils.getLocalSessionVariable(getServletInfo(),vars,"SNR_Masterdata_ID");
    String strNewSerialNo = SessionUtils.getLocalSessionVariable(getServletInfo(),vars,"ilsNewSerialNoInventory");
    // Read Form Input Values and set Session Vars
    String strUserid=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "ad_user_id"); // Empfänger 
    String strBarcode=SessionUtils.readInput(vars, "barcode");
    String strProductid= SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "m_product_id");
    String strModel= SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "model"); //Artikelbezeichnung / Gerätetext
    String strOrder= SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "orderreference");    // Ticketnr. / Bestell-ID
    String strIdentifier3= SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "identifier3"); // Internal Inventory Number
    String strIdentifier2= SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "identifier2"); // Serial Number of Vendor
    String strExternaltrackingno= SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "externaltrackingno"); // SIGMA-Auftragsnr.
    String strRemark=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "remark"); // Bemerkung (Finanzierung)
    String strVendor=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "vendor"); // Lieferant
    // Default Status
    vars.setSessionValue("PDCSTATUS","OK");
       
    
    // NAVIGATION Between the PDC Servlets
    //Setting SESSION History 
    String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
    if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.internallogistic.ad_forms/Inventory.html"))){
      vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
      strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
    }
    // DEFAULT-Command means that we come from another Servlet
    
    
    // Business logic Begins here ###############################################################
    //
    // The Scanner Issued the POST of the Form
    
    if (BcCommand.equals("SAVE_NEW_NEW") && !strBarcode.isEmpty()) {
        // Determine What kind of Barcode was scanned.
        // We can determine PRODUCT, CONTROL, LOCATOR, WORKSTEP, EMPLOYEE
        // Serial Number can not be determined, it is dependent on Product or Transaction or Workstep
        // A serial Number can be the same on different Products.
        data = PdcCommonData.selectbarcode(this,SessionUtils.readInput(vars, "barcode") );
        // In this Servlet CONTROL, EMPLOYEE or PRODUCT or SERIALNUMBER can be scanned,
        // The First found will be used...
        String bctype="UNKNOWN";
        String bcid="";
        for (int i=0;i<data.length;i++){
          if (data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("PRODUCT")||data[i].type.equals("SERIALNUMBER")) {
            bcid=data[i].id;  
            bctype=data[i].type;
            break;
          }             
        }         
        if (bctype.equals("EMPLOYEE")) {
            strUserid=bcid;
            SessionUtils.setLocalSessionVariable(getServletInfo(),vars, "ad_user_id",strUserid);
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        }
        else if (bctype.equals("CONTROL")) {
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
        
        else if (bctype.equals("PRODUCT")) {
          strProductid=bcid;
          SessionUtils.setLocalSessionVariable(getServletInfo(),vars, "m_product_id",strProductid);
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));       
        }
        else if (bctype.equals("UNKNOWN")) {
          if (strNewSerialNo.isEmpty() && ! strSourceSerialID.equals("")) {
            strNewSerialNo=SessionUtils.readInput(vars, "barcode");
            SessionUtils.setLocalSessionVariable(getServletInfo(),vars,"ilsNewSerialNoInventory",strNewSerialNo);
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_newserialassigned",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));       
          } else {
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          }
        }
        else if (bctype.equals("SERIALNUMBER") && strSourceSerialID.isEmpty()) {
          strSourceSerialID=bcid;
          SessionUtils.setLocalSessionVariable(getServletInfo(),vars,"SNR_Masterdata_ID",strSourceSerialID);
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));       
        
        }
        else  {
          vars.setSessionValue("PDCSTATUS", "ERROR");
          vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          
        } 
      }
    try {
      // AUTOMATIC DEFAULT ACTION when Identifier was scanned.
      // OR the Button NEXT was pressed (in this Case the Identifier must be in the Barcode Field
      // Save the Data and SET Response Ready for NEXT Scan in this Transaction.
      if (BcCommand.equals("NEXT")) {
        if (strProductid.isEmpty()||strSourceSerialID.isEmpty()||strNewSerialNo.isEmpty()){          
          vars.setSessionValue("PDCSTATUS","ERROR");
          //vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_MustSetUserProductLocator",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_MustSetProductSourceSerialAndSIGMA",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        } else { 
          // Data Is Ready -> Save the data
          if (strInventoryID.equals("")) {
            strInventoryID = UtilsData.getUUID(this);
            SessionUtils.setLocalSessionVariable(getServletInfo(),vars,"pdcInventoryID",strInventoryID);
          }
          InventoryData.insertTempInventory(this, strInventoryID,vars.getOrg(),vars.getUser(),strProductid, strUserid,strNewSerialNo,strSourceSerialID,strRemark,strVendor,strModel,strIdentifier2,strIdentifier3,strOrder,strExternaltrackingno);
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars,"ilsNewSerialNoInventory");
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "ad_user_id"); // Empfänger 
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "m_product_id");
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "model"); //Artikelbezeichnung / Gerätetext
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "orderreference");    // Ticketnr. / Bestell-ID
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "identifier3"); // Internal Inventory Number
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "identifier2"); // Serial Number of Vendor
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "externaltrackingno"); // SIGMA-Auftragsnr.
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "remark"); // Bemerkung (Finanzierung)
          SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "vendor"); // Lieferant
          strNewSerialNo="";
          // Status
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "iis_NewInventoryAdded",vars.getLanguage()));
        }
      }
      // Commit (Activate) this Transaction and go back to the Main Screen
      if (BcCommand.equals("DONE")) {
          if (strInventoryID.equals("")){          
            vars.setSessionValue("PDCSTATUS","ERROR");
            //vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_MustSetUserProductLocator",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_MustSetProductSourceSerialAndSIGMA",vars.getLanguage()));
          } else { 
            InventoryData.postTempInventory(this, strInventoryID);
            //String strLink="<a href=\"#\" onclick=\"submitCommandFormParameter('DIRECT',inpSnrMaterdataId,'"+strSourceSerialID+"', false, document.frmMain, '/org.zsoft.serial.SerialNumberTracking/SerialNumbersA5789BF6B4F84FF4B77AACC9D3CBD2E7_Edition.html', null, false, true);return false;\" class=\"LabelLink\">Inventar</a>";
            strNewSerialNo=InventoryData.getSerialFromID(this, strInventoryID);
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "ils_inventorycreatedSucessfully",vars.getLanguage())+"\r\n"+strNewSerialNo);
            response.sendRedirect(strDireccion + strpdcFormerDialogue);
          }
      }
      // Abort (Delete) this Transaction and go back to the Main Screen
      if (BcCommand.equals("CANCEL")) {
        InventoryData.deleteTempInventory(this, strInventoryID);
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage())+"\r\n"+SessionUtils.readInput(vars, "barcode"));
        response.sendRedirect(strDireccion + strpdcFormerDialogue);
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
    // Determin the State of the Servlet
    if (strSourceSerialID.isEmpty()) {
      // The First Dialogue shown is the one that scans the source ID
      InfobarText = Utility.messageBD(this, "ils_INVScanSourcePackage",vars.getLanguage());
      strServletState="SMALLGUI";
    } else if (strNewSerialNo.isEmpty()) {
        // The First Dialogue shown is the one that scans the source ID
        InfobarText = Utility.messageBD(this, "ils_INVScanInventoryNumber",vars.getLanguage());
        strServletState="SMALLGUI";
    } else if (strProductid.isEmpty()) {
      // The First Dialogue shown is the one that scans the source ID
      InfobarText = Utility.messageBD(this, "ils_INVScanProduct",vars.getLanguage());
      strServletState="FULLGUI";
    } else {
      // The First Dialogue shown is the one that scans the source ID
      InfobarText = Utility.messageBD(this, "ils_INVFillRestOfData",vars.getLanguage());
      strServletState="FULLGUI";
    }
      
    
    try {
     // Building the GUI
      //
      // Business logic ENDS here ##############################################################
      
      
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      
      
      // Building the User Interface............
      
      // Load grid structure
      EditableGrid lowergrid = new EditableGrid(LowerGridADName, vars, this);  // Load lower grid structure from AD (use AD name)
      
      // Load grid data - requires valid xsql file
      lowerGridData = InventoryData.selectLowerGrid(this, strInventoryID);  // Load lower grid date with language for translation
      
      // Generate servlet skeleton html code
      strToolbar = FormhelperData.getFormToolbar(this, this.getClass().getName());      
      //Window Tabs (Default Declaration)
      WindowTabs tabs;                  //The Servlet Name generated automatically
      tabs = new WindowTabs(this, vars, this.getClass().getName());// Load toolbar ID
      strSkeleton = ConfigureFrameWindow.doConfigure(this, vars, "UserID", null, "Inventory", strToolbar, "NONE", tabs);   // Generate skeleton
       
      // Generate Infobar
      Infobar = InfobarPrefix + InfobarText + InfobarSuffix;
      
      // Generate servlet elements html code
      strPdcInfobar = fh.prepareInfobar(this, vars, script, Infobar, "");                       // Generate infobar html code
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, HeaderADName, null, false);        // Generate header html code
      if (strServletState.equals("FULLGUI"))
        strHeaderFG = strHeaderFG + fh.prepareFieldgroup(this, vars, script, AdditionfieldsADName, null, false); 
      strButtonsFG = fh.prepareFieldgroup(this, vars, script, ButtonADName, null, false);       // Generate buttons html code
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      strStatusFG = PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, StatusADName, null, false);        // Generate status html code
          
      // Manual injections - both grids with defined height and scrollbar
     
      strLowerGrid = Replace.replace(strLowerGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
      strLowerGrid = Replace.replace(strLowerGrid, "</TABLE>","</TABLE>\n</DIV>");
      
      // Fit all the content together
      strOutput = Replace.replace(strSkeleton, "@CONTENT@", strPdcInfobar + strHeaderFG  + strButtonsFG + strLowerGrid + strStatusFG);
      
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

