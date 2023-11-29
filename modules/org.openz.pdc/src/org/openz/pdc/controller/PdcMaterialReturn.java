/*__________| PDC - Material Return |_______________________________________________________
 * The contents of this file are subject to the Mozilla Public License Version 1.1
 * Copyright:           OpenZ
 * Author:              Frank.Wohlers@OpenZ.de          (2013)
 * Contributor(s):      Danny.Heuduk@OpenZ.de           (2013)
 *_________________________________________________________________________| MPL1.1 |___fw_*/

package org.openz.pdc.controller;

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
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.pdc.PdcCommons;
import org.openz.util.*;

import java.math.BigDecimal;

public class PdcMaterialReturn extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  
  
  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);   
    //Define AD field names, do NOT use capitals or special characters here
    final String BarcodeADName = "pdcmaterialconsumptionbarcode";
    final String WorkstepIDADName = "pdcmaterialconsumptionworkstepid";
    final String ProductIDADName = "productid";
    final String QuantityADName = "pdcmaterialconsumptionquantity";  
   
      // Define AD fieldgroup names
      String comingserial="";
      String HeaderADName = "PdcMaterialReturnHeader";
      String UpperGridADName = "PdcMaterialReturnUpperGrid";
      String ButtonADName = "PdcMaterialReturnButtons";
      String LowerGridADName = "PdcMaterialReturnLowerGrid";
      // Commons
      PdcCommons commons = new PdcCommons();
      String BcCommand="";
      // Serial or Batch ONLY From KOMBI Barcode
      String snrbnr="";
      // Button hide
      vars.setSessionValue("PDCRETURN", "Y");
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");
  

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
      String GlobalLocatorID = vars.getSessionValue("pdcLocatorID");
   // Starting...
   try {
      setLocalSessionVariable(vars, WorkstepIDADName, GlobalWorkstepID); 
      //setting History
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMaterialReturn.html"))){
      	vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
      	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }
      // Look if we come from serial Number Tracking...
      String commandserial=vars.getSessionValue("PDCINVOKESERIAL");
      vars.removeSessionValue("PDCINVOKESERIAL");
      if (!commandserial.isEmpty()) {
          comingserial="Y";
      } else {
    	  String plannedsnr=PdcCommonData.getPlannedSerial(this, vars.getStringParameter("inpplannedserialorbatchno"));
          setLocalSessionVariable(vars,"plannedserialorbatch", plannedsnr);
          setLocalSessionVariable(vars,"plannedserialorbatchno", vars.getStringParameter("inpplannedserialorbatchno"));
          if (!vars.getStringParameter("inpplannedserialorbatchno").isEmpty())
        	  vars.setSessionValue("pdcAssemblySerialOrBatchNO",getLocalSessionVariable(vars,"plannedserialorbatch")); // If Input Changes, Propagate to global var
      }
      // Getting Workstep       
      if (!vars.getStringParameter("inp" + WorkstepIDADName).equals("")) {
	      if (GlobalWorkstepID.isEmpty()||
	  			(vars.getSessionValue("pdcConsumptionID").isEmpty()
	  			 && !GlobalWorkstepID.equals(vars.getStringParameter("inp" + WorkstepIDADName)))) {// Workstep selected via dropdown
	    	  BcCommand = "ALLPOSITIONS";
	    	  setLocalSessionVariable(vars, WorkstepIDADName);
	    	  PdcCommons.setWorkstepVars(getLocalSessionVariable(vars, WorkstepIDADName),null,null, vars,this);
	          GlobalWorkstepID = getLocalSessionVariable(vars, WorkstepIDADName);
	  	  } 
      }
      setLocalSessionVariable(vars, ProductIDADName);
      setLocalSessionVariable(vars, QuantityADName);
      
      
      // Business logic     
      if (vars.commandIn("SAVE_NEW_NEW")) {
    	vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_DataSelected",vars.getLanguage()));  
        if (!vars.getStringParameter("inp" + BarcodeADName).isEmpty()) {
          data = PdcCommonData.selectbarcode(this, vars.getStringParameter("inp" + BarcodeADName),vars.getRole());
          // In this Servlet CONTROL, EMPLOYEE or PRODUCT or CALCULATION, LOCATOR, WORKSTEP can be scanned,
          // The First found will be used...
          String bctype="UNKNOWN";
          String bcid="";
          if (data.length>=1) {
              bcid=data[0].id;  
              bctype=data[0].type;
              snrbnr=data[0].serialnumber;
              if (FormatUtils.isNix(snrbnr))
            	  snrbnr=data[0].lotnumber;
              if (FormatUtils.isNix(snrbnr))
        	      snrbnr="";
          }             
          if (bctype.equals("EMPLOYEE")) {
            if (GlobalConsumptionID.isEmpty()){
              vars.setSessionValue("pdcUserID",bcid);
              GlobalUserID=bcid;
              vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
            } else{
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
            }

          } else if (bctype.equals("LOCATOR")) {
        	GlobalLocatorID=  bcid;  
            vars.setSessionValue("pdcLocatorID", GlobalLocatorID);
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
           
            
          } else if (bctype.equals("PRODUCT")||bctype.equals("KOMBI")) {        	
        	if (GlobalWorkstepID.isEmpty()) {
          		String workstep="";
          		  if (bctype.equals("KOMBI"))
          			workstep=PdcCommonData.getWorkstepFromKombi(this, bcid, snrbnr);
				  else
					  workstep=PdcCommonData.getWorkstepFromProduct(this, bcid);
                  if ( workstep!=null && ! workstep.isEmpty()) {
  	        		setLocalSessionVariable(vars, WorkstepIDADName, workstep);
  	                GlobalWorkstepID=workstep;
  	                BcCommand = "ALLPOSITIONS";
  	                PdcCommons.setWorkstepVars(null,bcid,snrbnr, vars,this);
  	                vars.setSessionValue("PDCSTATUS","OK");
  		            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
                  } else {
                  	vars.setSessionValue("PDCSTATUS", "ERROR");
                    vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
                  }
          	} else { // Workstep exists
	        	setLocalSessionVariable(vars, ProductIDADName, bcid);
	        	if (GlobalLocatorID.isEmpty()) {
		        	String locator=PdcMaterialReturnData.getLocatorReturn(this, GlobalConsumptionID, GlobalWorkstepID, bcid);
		        	if (locator!=null && !locator.isEmpty()){
		        		GlobalLocatorID=  locator;
		        	}
		        }
	        	String qty=vars.getNumericParameter("inp" + QuantityADName);
	        	qty=PdcCommons.getQtyIncrement(qty, bcid, GlobalConsumptionID,  this);	
	        	setLocalSessionVariable(vars, QuantityADName,qty);
	            if (!GlobalLocatorID.isEmpty()) {
	            	BcCommand = "NEXT";
	                vars.setSessionValue("PDCSTATUS","OK");
	                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
	            } else {
	            	vars.setSessionValue("PDCSTATUS","ERROR");
	                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
	            }
          	}
          } else if (bctype.equals("WORKSTEP")) {
        	  if  (GlobalConsumptionID.isEmpty()){
                  setLocalSessionVariable(vars, WorkstepIDADName, bcid);
                  GlobalWorkstepID=bcid;
                  PdcCommons.setWorkstepVars(GlobalWorkstepID,null,null, vars,this);
                  BcCommand = "ALLPOSITIONS";
                  vars.setSessionValue("PDCSTATUS","OK");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));              
                } else{
                  vars.setSessionValue("PDCSTATUS","ERROR");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
                }
            
          } else if (bctype.equals("CONTROL")) {
            if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC"))
              BcCommand = "CANCEL";
            else if (bcid.equals("8521E358B73444A6A999C55CBCCACC75"))
              BcCommand = "NEXT";
            else if (bcid.equals("B28DAF284EA249C48F932C98F211F257"))
              BcCommand = "DONE";
            else if (bcid.equals("10D3B97A3089447C9A4F04FF792A5246"))
              BcCommand = "ALLPOSITIONS";
            else {
              vars.setSessionValue("PDCSTATUS", "ERROR");
              vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
            }
          }
          else if (bctype.equals("UNKNOWN")) {
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));      
          } else {
        	  vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",bctype+":"+Utility.messageBD(this, "ActionNotSupported",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));        
          }
        }
      }
      if (vars.commandIn("ALLPOSITIONS")||BcCommand.equals("ALLPOSITIONS")){
    	vars.setSessionValue("PDCSTATUS","OK");
    	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage()));
    	if (UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y") && getLocalSessionVariable(vars,"plannedserialorbatch").isEmpty() && vars.getSessionValue("ISSNRBNR").equals("Y")) {
			  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_PlannedSerialNumberNecessary",vars.getLanguage()));			  
    	} else if (getLocalSessionVariable(vars, WorkstepIDADName).equals("")||
        		GlobalUserID.equals("")){
        	if (GlobalUserID.isEmpty())
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()));
        	else
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanWorkstep",vars.getLanguage()));
        } else { 
          upperGridData = PdcMaterialReturnData.selectupper(this, vars.getLanguage(),vars.getSessionValue("pdcAssemblySerialOrBatchNO"),GlobalConsumptionID, getLocalSessionVariable(vars, WorkstepIDADName)); 
          if (GlobalConsumptionID.equals("")&&upperGridData.length>0) {
            GlobalConsumptionID = UtilsData.getUUID(this);
            PdcMaterialReturnData.insertConsumption(
                this,
                GlobalConsumptionID,
                vars.getClient(),
                vars.getOrg(),
                GlobalUserID,
                PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, WorkstepIDADName)),
                getLocalSessionVariable(vars, WorkstepIDADName),vars.getSessionValue("pdcAssemblySerialOrBatchNO"));
            vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
	          for (int i=0;i<upperGridData.length;i++){
	            if (upperGridData[i].getField("pdcmaterialreturnlocator").isEmpty()) {
	              vars.setSessionValue("PDCSTATUS","ERROR");
	              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MustSetProductQtyAndLocator",vars.getLanguage())+"\r\n"+vars.getStringParameter("inp" + BarcodeADName));
	            } else {
	              String qty=PdcMaterialReturnData.getRetQty(this, upperGridData[i].getField("m_product_id"),GlobalConsumptionID,GlobalWorkstepID,vars.getSessionValue("pdcAssemblySerialOrBatchNO") );
	              String t=upperGridData[i].getField("m_product_id");
	              if (! qty.isEmpty()) {
	                if (Float.parseFloat(qty)>0) {
	                  PdcCommonData.insertMaterialLine( this, vars.getClient(), vars.getOrg(), 
	                		  GlobalUserID,GlobalConsumptionID,upperGridData[i].getField("m_locator_id"),upperGridData[i].getField("m_product_id"),
	                    PdcCommonData.getNextLineFromConsumption(this, GlobalConsumptionID),
	                    qty,
	                    PdcCommonData.getProductStdUOM(this, upperGridData[i].getField("m_product_id")),
	                    PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, WorkstepIDADName)),
	                    getLocalSessionVariable(vars, WorkstepIDADName));
	                }	                
	              }
	            }	            
	          }
	          // Rückgabe eines Gerätes -> SNR/BBTCh ggf. aus geplanter SNR vorbelegen
              PdcMaterialReturnData.pdc_addpassingworkstSnrBtchReturn(this,  GlobalWorkstepID, GlobalConsumptionID);
          } else {
              PdcCommonData.deleteAllMaterialLines(this,GlobalConsumptionID);
              PdcCommonData.deleteMaterialTransaction(this,GlobalConsumptionID);
              vars.removeSessionValue("pdcConsumptionID");
          }
        }
      }
      if (vars.commandIn("NEXT")||BcCommand.equals("NEXT")) {
    	  commons.InternalConsumptionNext(GlobalWorkstepID, GlobalUserID, strpdcFormerDialogue, GlobalLocatorID, snrbnr,WorkstepIDADName,QuantityADName,getLocalSessionVariable(vars, ProductIDADName), vars, response, this);
    	  GlobalConsumptionID=vars.getSessionValue("pdcConsumptionID");
      }
      
      if (vars.commandIn("DONE")||BcCommand.equals("DONE")) {
    	  if (UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y") && getLocalSessionVariable(vars,"plannedserialorbatch").isEmpty() && vars.getSessionValue("ISSNRBNR").equals("Y")) {
			  vars.setSessionValue("PDCSTATUS","ERROR");
			  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_PlannedSerialNumberNecessary",vars.getLanguage()));
    	  } else
    	  commons.setInternalConsumptionDone(GlobalConsumptionID,GlobalWorkstepID, GlobalUserID,strpdcFormerDialogue,"/org.openz.pdc.ad_forms/PdcMaterialReturn.html", vars, response ,this);
      }
      
      if (vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")) {
        PdcCommonData.deleteAllMaterialLines( this, GlobalConsumptionID);
        PdcCommonData.deleteMaterialTransaction( this, GlobalConsumptionID);
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
        response.sendRedirect(strDireccion + strpdcFormerDialogue);
      }
      // Present Errors on the User Screen
    } catch (Exception e) { 
    	e.printStackTrace();
    	vars.setSessionValue("PDCSTATUS","ERROR");    	
    	OBError s=new OBError();
    	s=Utility.translateError(this, vars, vars.getLanguage(),e.getMessage());
    	vars.setSessionValue("PDCSTATUSTEXT",s.getMessage());
    }   
    try {
 	   // Build the GUI     
      // Initialize Infobar helper variables
      String InfobarPrefix = "<span style=\"font-size: 20pt; color: #000000;\">" + Utility.messageBD(this, "pdc_Return",vars.getLanguage()) + "<br />";
      String InfobarText = "";
      String InfobarSuffix = "</span>";
      String Infobar = "";
      
      if (GlobalUserID.isEmpty()) {
        InfobarText = Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage());
      }else if (getLocalSessionVariable(vars, WorkstepIDADName) == "") {
        InfobarText = Utility.messageBD(this, "pdc_ScanWorkstep",vars.getLanguage());
      }else if(PdcMaterialReturnData.countupper(this,GlobalConsumptionID,GlobalWorkstepID) != null && !PdcMaterialReturnData.countupper(this,GlobalConsumptionID,GlobalWorkstepID).isEmpty()) {
    	  if (GlobalLocatorID.isEmpty()) 
          	InfobarText = Utility.messageBD(this, "pdc_ScanLocator",vars.getLanguage());
    	  else
    		InfobarText = Utility.messageBD(this, "pdc_ScanProduct",vars.getLanguage());
      } else if (PdcMaterialReturnData.countlower(this,GlobalConsumptionID) != null && !PdcMaterialReturnData.countlower(this,GlobalConsumptionID).isEmpty())
    	  InfobarText = Utility.messageBD(this, "pdc_ScanProductCompleted",vars.getLanguage());  
      else {
    	  if (GlobalLocatorID.isEmpty()) 
            InfobarText = Utility.messageBD(this, "pdc_ScanLocator",vars.getLanguage());
    	  else
            InfobarText = Utility.messageBD(this, "pdc_ScanProduct",vars.getLanguage());
      }
      // Generate Infobar
      Infobar = InfobarPrefix + InfobarText + InfobarSuffix;
      //
      // Info Bar left Space
      String Infobar2 = "<span style=\"font-size: 12pt; color: #000000;\">";
      if (vars.getSessionValue("PDCSTATUS").equals("ERROR")) 
    	  Infobar2 =Infobar2 +"<span style=\"color:#B40404;\">" + Utility.messageBD(this, "pdcerrorHint",vars.getLanguage()) + "</span><br />";
      if (!GlobalUserID.isEmpty())
    	  Infobar2 =Infobar2 +Utility.messageBD(this, "zssm_barcode_entity_employee",vars.getLanguage()) +": " + PdcCommonData.getEmployee(this, GlobalUserID);
      // Set Assemb. Product
      String productID=PdcCommonData.getProductFromWorkstep(this, GlobalWorkstepID);
      if (productID!=null && ! productID.isEmpty())
    	  Infobar2 =Infobar2 + "<br />" + PdcCommonData.getProduct(this, productID,vars.getLanguage());
      if (!vars.getSessionValue("pdcLocatorID").isEmpty())
    	  Infobar2 =Infobar2 + "<br />" +Utility.messageBD(this, "pdcmaterialconsumptionlocator",vars.getLanguage()) +": " + PdcCommonData.getLocator(this, GlobalLocatorID);
      if (!getLocalSessionVariable(vars,ProductIDADName).isEmpty()) {
    	  Infobar2 =Infobar2 + " , " + Utility.messageBD(this, "Product",vars.getLanguage())  +": " + PdcCommonData.getProduct(this, getLocalSessionVariable(vars, ProductIDADName), vars.getLanguage());
    	  Infobar2 =Infobar2 + " , " + LocalizationUtils.getElementTextByElementName(this, "Quantity", vars.getLanguage())+" :" + getLocalSessionVariable(vars, QuantityADName);
      }    
      Infobar2 =Infobar2 + "</span>";    
      deleteLocalSessionVariable(vars,ProductIDADName);
      deleteLocalSessionVariable(vars,QuantityADName);
      // Setting global session variables
      vars.setSessionValue("pdcWorkStepID", GlobalWorkstepID);

      // Load grid structure
      EditableGrid uppergrid = new EditableGrid(UpperGridADName, vars, this);  // Load upper grid structure from AD (use AD name)
      upperGridData = PdcMaterialReturnData.selectupper(this, vars.getLanguage(),vars.getSessionValue("pdcAssemblySerialOrBatchNO"), vars.getSessionValue("pdcConsumptionID"), getLocalSessionVariable(vars, WorkstepIDADName));   // Load upper grid date with language for translation
      strUpperGrid = uppergrid.printGrid(this, vars, script, upperGridData);                    // Generate upper grid html code
      
      EditableGrid lowergrid = new EditableGrid(LowerGridADName, vars, this);  // Load lower grid structure from AD (use AD name)
      
      // Load grid data - requires valid xsql file
      lowerGridData =PdcMaterialReturnData.selectlower(this, vars.getLanguage(), vars.getSessionValue("pdcConsumptionID"));   // Load lower grid date with language for translation
      
      // Generate servlet skeleton html code
      strToolbar="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID", strToolbar, "Material Return", "", "REMOVED", null,"true");   // Generate skeleton
      
      if (comingserial.equals("Y")) {
      	InfobarText = Utility.messageBD(this, "pdc_ScanProductCompleted",vars.getLanguage()); 
      	comingserial="";
      };   
      
      
      // Prevent Softkeys on Mobile Devices
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
      
      // Generate servlet elements html code
      strPdcInfobar = ConfigureInfobar.doConfigure2Rows(this, vars, script, Infobar, Infobar2);                    // Generate infobar html code
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, HeaderADName, null, false);        // Generate header html code
      // Settings for dummy focus...
      strHeaderFG=MobileHelper.addDummyFocus(strHeaderFG);
      strButtonsFG = fh.prepareFieldgroup(this, vars, script, ButtonADName, null, false);       // Generate buttons html code
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      strStatusFG = PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, StatusADName, null, false);        // Generate status html code
          
      // Manual injections - both grids with defined height and scrollbar
      strUpperGrid = Replace.replace(strUpperGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
      strUpperGrid = Replace.replace(strUpperGrid, "</TABLE>","</TABLE>\n</DIV>");
      strLowerGrid = Replace.replace(strLowerGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
      strLowerGrid = Replace.replace(strLowerGrid, "</TABLE>","</TABLE>\n</DIV>");
      
      // Fit all the content together
      strOutput = Replace.replace(strSkeleton, "@CONTENT@", MobileHelper.addMobileCSS(request,strPdcInfobar + strHeaderFG + strUpperGrid + strButtonsFG + strLowerGrid + strStatusFG));
      
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

