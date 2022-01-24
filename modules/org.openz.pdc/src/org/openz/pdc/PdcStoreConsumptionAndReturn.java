/*__________| PDC - Material Consumption |_________________________________________________
 * The contents of this file are subject to the Mozilla Public License Version 1.1
 * Copyright:           OpenZ
 * Author:              Frank.Wohlers@OpenZ.de          (2013)
 * Contributor(s):      Danny.Heuduk@OpenZ.de           (2013)
 *_________________________________________________________________________| MPL1.1 |___fw_*/

package org.openz.pdc;

import java.io.IOException;
import java.io.PrintWriter;

import java.sql.*;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;


import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;

import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.UtilsData;

import org.openz.view.Formhelper;
import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.util.*;
import java.math.BigDecimal;
import org.openz.pdc.controller.*;

public class PdcStoreConsumptionAndReturn extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  String Complete="";
  String Current="";
  Integer CompleteTrx=0;
  Integer CurrentTrx=0;
  String snr="";
  String bnr="";
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);      

      // Serial Invocation Indicator
      String comingserial="";
    
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");

      // Initialize global structure
      Scripthelper script = new Scripthelper(); // Injects Javascript, hidden fields, etc into the generated html
      Formhelper fh = new Formhelper();         // Injects the styles of fields, grids, etc
      String strOutput = "" ;                   // Resulting html output
      String strSkeleton = "";                  // Structure of the servlet
      String strQuit = "";                      // Toolbar Quit Button
      String strPdcInfobar = "";                // Infobar
      String strHeaderFG = "";                  // Header fieldgroup (defined in AD)
      String strUpperGrid = "";                 // Upper grid (defined in AD)
      String strButtonsFG = "";                 // Button fieldgroup (defined in AD)
      String strLowerGrid = "";                 // Lower grid (defined in AD)
      String strStatusFG = "";                  // Status fieldgroup (defined in AD)

      // Initialize fieldproviders - they provide data for the grids
      FieldProvider[] upperGridData;    // Data for the upper grid
      FieldProvider[] lowerGridData;    // Data for the lower grid
      // weight of goods in trx
      String weight="";
      // Initialize DB dialogue datafield
      PdcMaterialConsumptionData[] data;      
      // Loading global session variables
      String GlobalUserID = vars.getUser();
      String GlobalWorkstepID = vars.getSessionValue("pdcWorkStepID");
      String GlobalLocatorID = vars.getSessionValue("pdcLocatorID");
      String GlobalConsumptionID = vars.getSessionValue("pdcConsumptionID");
   try {
      //setting History
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/ad_forms/PdcStoreConsumptionAndReturn.html"))){
      	vars.setSessionValue("PDCFORMERDIALOGUE","/ad_forms/PDCStoreMainDialoge.html");
      	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }
              
      if (vars.getStringParameter("inppdcmaterialconsumptionworkstepid").equals("")) {
        setLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid", GlobalWorkstepID);
      } else {
        setLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid");
        vars.setSessionValue("PDCWORKSTEPID",getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid"));
        GlobalWorkstepID = getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid");
      }
      
      String BcCommand = "";
      
      // Business logic
       if (vars.commandIn("DEFAULTRELOCATE")||vars.commandIn("DEFAULTCONSUME")||vars.commandIn("DEFAULTRETURN")||vars.commandIn("DEFAULT")) {
    	// Load USECASE 
    	   setLocalSessionVariable(vars, "isrelocate","N");
    	if (vars.commandIn("DEFAULTCONSUME")||vars.commandIn("DEFAULTRELOCATE"))
    	   setLocalSessionVariable(vars, "pdcdirection","D-");
    	if (vars.commandIn("DEFAULTRETURN"))
    	   setLocalSessionVariable(vars, "pdcdirection","D+");
    	if (vars.commandIn("DEFAULTRELOCATE"))
    		setLocalSessionVariable(vars, "isrelocate","Y");
        // Look if we come from serial Number Tracking...
        String commandserial=vars.getSessionValue("PDCINVOKESERIAL");
        vars.removeSessionValue("PDCINVOKESERIAL");
        if (!commandserial.isEmpty()) {
          comingserial="Y";
        }
      }
      if (vars.commandIn("SAVE_NEW_NEW")) {
    	  // Read Description Field
    	  String dscr=vars.getStringParameter("inppdcmaterialconsumptiondescription");
    	  setLocalSessionVariable(vars, "pdcmaterialconsumptiondescription",dscr);  
    	  // REad Barcode
    	  String barcode=vars.getStringParameter("inppdcmaterialconsumptionbarcode");
          data = PdcMaterialConsumptionData.selectbarcode(this, barcode);
          // In this Servlet CONTROL, EMPLOYEE or PRODUCT or CALCULATION, LOCATOR, WORKSTEP can be scanned,
          // The First found will be used...
          String bctype="UNKNOWN";
          String bcid="";
          for (int i=0;i<data.length;i++){
            if (data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("PRODUCT")||data[i].type.equals("CALCULATION")||data[i].type.equals("LOCATOR")||data[i].type.equals("WORKSTEP")||data[i].type.equals("KOMBI")) {
              bcid=data[i].id;  
              bctype=data[i].type;
              weight=data[i].weight;
              break;
            }             
          }         
          //Time Feedback mot applicable
          if (bctype.equals("EMPLOYEE")||bcid.equals("872C3C326AB64D1EBABDD49A1E138136")){
        	  vars.setSessionValue("PDCSTATUS","WARNING");
        	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"\r\n"+barcode);       
              
          } else if (bctype.equals("LOCATOR")) {
              setLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid", bcid);
              GlobalLocatorID=  bcid;   
              vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);
          } else if (bctype.equals("PRODUCT")&&! getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty()) {
        	  String qty=vars.getNumericParameter("inppdcmaterialconsumptionquantity");
              if (qty.isEmpty())
                qty="1";
              // Increment an multpl. scan on same Product
              String tt=getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid");
              if (getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").equals(bcid)&&!getLocalSessionVariable(vars, "quantity").isEmpty()&&vars.getNumericParameter("inppdcmaterialconsumptionquantity").isEmpty()) {
            		Integer qu=Integer.parseInt(getLocalSessionVariable(vars, "quantity")) +  1;
            		qty=qu.toString();
              }
              setLocalSessionVariable(vars, "quantity",qty);  
              setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", bcid);
            BcCommand = "NEXT";
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);          
          } else if (bctype.equals("KOMBI")&&! getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty()) {
        	  String[] kombi=barcode.split("\\|");
              setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", bcid);
              setLocalSessionVariable(vars, "pdcmaterialconsumptionserial", kombi[1]);
              if (kombi.length>2)
            	  setLocalSessionVariable(vars, "pdcmaterialconsumptionbatch", kombi[2]);
              String qty=vars.getNumericParameter("inppdcmaterialconsumptionquantity");
              if (qty.isEmpty())
                qty="1";
              setLocalSessionVariable(vars, "quantity",qty);
              BcCommand = "KOMBINEXT";
              vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);          
          } else if (bctype.equals("WORKSTEP")) {
            if  (GlobalConsumptionID.isEmpty()){
              setLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid", bcid);
              GlobalWorkstepID=bcid;
              vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);
              
            } else{
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"-"+barcode);
            }
            
          } else if (bctype.equals("CONTROL")) {
            if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC"))
              BcCommand = "CANCEL";
            else if (bcid.equals("8521E358B73444A6A999C55CBCCACC75"))
              BcCommand = "NEXT";
            else if (bcid.equals("B28DAF284EA249C48F932C98F211F257"))
              BcCommand = "DONE";
            else {
              vars.setSessionValue("PDCSTATUS", "WARNING");
              vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage()));
            }
          }          
          else if (bctype.equals("UNKNOWN")) {
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode);
            
          } 
      }
 
      if (vars.commandIn("NEXT")||BcCommand.equals("NEXT")||BcCommand.equals("KOMBINEXT")) {
        if (getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").equals("")||
            getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").equals("")){         
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MustSetProductQtyAndLocator",vars.getLanguage()));
        } else { 
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ProductScannedCorrectly",vars.getLanguage()));
          if (GlobalConsumptionID.equals("")) {
            GlobalConsumptionID = UtilsData.getUUID(this);
            PdcMaterialConsumptionReturnData.insertConsumption(
                this,
                GlobalConsumptionID,
                vars.getClient(),
                vars.getOrg(),
                vars.getUser(),
                getLocalSessionVariable(vars, "pdcmaterialconsumptiondescription"),
                PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid")),
                getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid"),
                getLocalSessionVariable(vars, "pdcdirection"));
            vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
           } else
        	   PdcMaterialConsumptionReturnData.updateConsumption( this, getLocalSessionVariable(vars, "pdcmaterialconsumptiondescription"), GlobalConsumptionID);
            // On Serial Numbers - Get TRX Locator from SNR Masterdata
            String trxlocator="";
            if (!getLocalSessionVariable(vars, "pdcmaterialconsumptionserial").isEmpty() && getLocalSessionVariable(vars, "pdcdirection").equals("D-"))
            	trxlocator=SerialNumberData.getLocatorIdFromSerialAndProduct(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionserial"), getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"));
            if (trxlocator==null || trxlocator.isEmpty())
            	trxlocator=getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid");
            // Check if Value Updates a line or deletes a line          
            String sameline=PdcCommonData.getIDWhenScannedSameLine(this, GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), trxlocator);
            if (sameline==null) sameline="";
            // Qty > 0 and new line
            if (sameline.equals("") && new BigDecimal(getLocalSessionVariable(vars, "quantity").replace(",", "")).compareTo(BigDecimal.ZERO)==1) {
              if(getLocalSessionVariable(vars, "isrelocate").equals("Y") && getLocalSessionVariable(vars, "pdcmaterialconsumptionserial").isEmpty()) {
            	  vars.setSessionValue("PDCSTATUS","ERROR");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_relocationonlyserial",vars.getLanguage()));
              } else {
	              String lineUuid=UtilsData.getUUID(this);
	              PdcMaterialConsumptionReturnData.insertMaterialLine( this, lineUuid,vars.getClient(), vars.getOrg(), 
	                  vars.getUser(),GlobalConsumptionID,trxlocator,getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"),
	                  PdcCommonData.getNextLineFromConsumption(this, GlobalConsumptionID),
	                  getLocalSessionVariable(vars, "quantity"),PdcCommonData.getProductStdUOM(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")),PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid")),
	                  getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid"),weight);
	              if (PdcCommonData.isbatchorserialnumber(this, GlobalConsumptionID).equals("Y")&& !BcCommand.equals("KOMBINEXT")){
	                vars.setSessionValue("PDCSTATUS","OK");
	                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionPreparedSerialNumberNecessary",vars.getLanguage()));
	                vars.setSessionValue("PDCINVOKESERIAL","DONE");
	                //second layer
	                vars.setSessionValue("PDCFORMERDIALOGUE","/ad_forms/PdcStoreConsumptionAndReturn.html");
	                strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
	                response.sendRedirect(strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");
	              } 
	              if (BcCommand.equals("KOMBINEXT")) {
	            	  String type=SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"));
	            	  String qty="";
	            	  bnr="";
	            	  snr="";
	            	  if (type.equals("SERIAL")||type.equals("BOTH")) {
	            		  qty="1";
	            		  snr=getLocalSessionVariable(vars, "pdcmaterialconsumptionserial");
	            		  bnr=getLocalSessionVariable(vars, "pdcmaterialconsumptionbatch");  
	            	  } if (type.equals("BATCH")) {
	            		  qty=getLocalSessionVariable(vars, "quantity");
	            		  bnr=getLocalSessionVariable(vars, "pdcmaterialconsumptionbatch");  
	            		  if (bnr.isEmpty())
	            			  bnr= getLocalSessionVariable(vars, "pdcmaterialconsumptionserial");
	            	  }
	            	  if (!type.equals("NONE"))
	            		  try {
	            			  PdcMaterialConsumptionReturnData.insertSerialLine(this,vars.getClient(), vars.getOrg(), vars.getUser(), 
	            			  lineUuid, qty, bnr, snr);
	            		  } catch (Exception e) { 
	            			  PdcCommonData.deleteMaterialLine( this, lineUuid);
	            			  vars.setSessionValue("PDCSTATUS","ERROR");
	            			  if (e.getMessage().contains("@snr_serialknownbutnotstocked@"))
	            				  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "snr_serialknownbutnotstocked",vars.getLanguage()));
	            			  else
	            				  vars.setSessionValue("PDCSTATUSTEXT",Utility.translateError(this, vars,vars.getLanguage(),e.getMessage()).getMessage());
	            		  }
	              }
              }
            }
            else if (new BigDecimal(getLocalSessionVariable(vars, "quantity")).compareTo(BigDecimal.ZERO)==1) {
              String type=SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"));
              String qty=getLocalSessionVariable(vars, "quantity");
        	  bnr=getLocalSessionVariable(vars, "pdcmaterialconsumptionbatch");  
        	  snr=getLocalSessionVariable(vars, "pdcmaterialconsumptionserial");
        	  vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ProductQtyUpdated",vars.getLanguage()));
              // Update existing Line with new QTY
              if (type.equals("BATCH")||type.equals("NONE")) {
            	  PdcCommonData.updateMaterialLine( this,  qty,sameline);
            	  if (type.equals("BATCH")) {
            		  if (bnr.isEmpty())
            			  bnr= getLocalSessionVariable(vars, "pdcmaterialconsumptionserial");
            		  SerialNumberData.deleteAllSerialLine(this, sameline);
            		  PdcMaterialConsumptionReturnData.insertSerialLine(this,vars.getClient(), vars.getOrg(), vars.getUser(), 
            				  sameline, qty, bnr, null);
            	  }            		  
              }
              if (type.equals("SERIAL")||type.equals("BOTH")) {
            	  qty="1";
            	  if (SerialNumberData.snrExists(myPool, snr, sameline).equals("Y")) {
	            	  if (Integer.parseInt(SerialNumberData.getQtyByConsumptionLineID(this, sameline))==1) {
	            		  PdcCommonData.deleteMaterialLine( this, sameline);
	            	  } else  {
	            		  SerialNumberData.deleteSerialLine(this, sameline, null, snr);
	            		  SerialNumberData.decrementCurrentMovementQty(this, weight,sameline);
	            	  }
            	  } else {
            		  SerialNumberData.incrementCurrentMovementQty(this, weight,sameline);
            		  try {
            			  PdcMaterialConsumptionReturnData.insertSerialLine(this,vars.getClient(), vars.getOrg(), vars.getUser(), 
            				  sameline, qty, bnr, snr);
            		  } catch (Exception e) { 
            			  SerialNumberData.decrementCurrentMovementQty(this, weight,sameline);
            			  vars.setSessionValue("PDCSTATUS","ERROR");
            			  if (e.getMessage().contains("@snr_serialknownbutnotstocked@"))
            				  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "snr_serialknownbutnotstocked",vars.getLanguage()));
            			  else
            				  vars.setSessionValue("PDCSTATUSTEXT",Utility.translateError(this, vars,vars.getLanguage(),e.getMessage()).getMessage());
            		  }
            	  }
            		  
              }             
              
            }
            else {
              // Delete line (QTY<=0) 
              PdcCommonData.deleteMaterialLine( this, sameline);
              vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ProductLineDeletedQtyZERO",vars.getLanguage()));
            }
          
          //deleteLocalSessionVariable(vars,"pdcmaterialconsumptionproductid");
          //deleteLocalSessionVariable(vars,"quantity");
          deleteLocalSessionVariable(vars,"pdcmaterialconsumptionserial");
          deleteLocalSessionVariable(vars,"pdcmaterialconsumptionbatch");
          
        }
      }
      
      if (vars.commandIn("DONE")||BcCommand.equals("DONE")) {
        if (PdcCommonData.isbatchorserialnumber(this, GlobalConsumptionID).equals("N")){
          OBError mymess=null;
          boolean iserror=false;
          String msgtext="\n";
          if (!GlobalConsumptionID.equals("")) {
        	// On Relocation Create Return TRX from given Consume TRX
        	String relocateTRX="";
            // Start internal Consumption Post Process directly - Process Internal Consumption
            ProcessUtils.startProcessDirectly(GlobalConsumptionID, "800131", vars, this); 
            if (getLocalSessionVariable(vars, "isrelocate").equals("Y")) {
            	mymess=vars.getMessage(getServletInfo());
                if (mymess!=null) {
                	if (!mymess.getType().equals("Error"))
                		// Process Return for Relocation if Consumption was successful..
                		relocateTRX=PdcMaterialConsumptionReturnData.copyConsumption2Return(this, GlobalConsumptionID, GlobalLocatorID, GlobalUserID);
                		ProcessUtils.startProcessDirectly(relocateTRX, "800131", vars, this); 
                }
            }
            // PdcCommonData.doConsumptionPost(this, strConsumptionid);
            vars.setSessionValue("PDCSTATUS","OK");
            if (getLocalSessionVariable(vars, "pdcdirection").equals("D-"))
            	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MatSucessful",vars.getLanguage())+msgtext);
            else
            	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_RetSucessful",vars.getLanguage())+msgtext);
            if (getLocalSessionVariable(vars, "isrelocate").equals("Y")) 
            	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_RelocationSucessful",vars.getLanguage())+msgtext);
            deleteLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid");
            deleteLocalSessionVariable(vars, "pdcmaterialconsumptionproductid");
            deleteLocalSessionVariable(vars, "pdcmaterialconsumptiondescription");
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
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NoData",vars.getLanguage()));
          }
          if (! iserror)
            response.sendRedirect(strDireccion + strpdcFormerDialogue);
        } else {
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionPreparedSerialNumberNecessary",vars.getLanguage()));
          vars.setSessionValue("PDCINVOKESERIAL","DONE");
          //second layer
          vars.setSessionValue("PDCFORMERDIALOGUE","/ad_forms/PdcStoreConsumptionAndReturn.html");
          response.sendRedirect(strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");
        }
      }
      
      if (vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")) {
        PdcCommonData.deleteAllMaterialLines( this, GlobalConsumptionID);
        PdcCommonData.deleteMaterialTransaction( this, GlobalConsumptionID);
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
        deleteLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid");
        deleteLocalSessionVariable(vars, "pdcmaterialconsumptionproductid");
        deleteLocalSessionVariable(vars, "pdcmaterialconsumptiondescription");
        response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
      }
    }
    // Present Errors on the User Screen
    catch (Exception e) { 
    	vars.setSessionValue("PDCSTATUS","ERROR");
	    vars.setSessionValue("PDCSTATUSTEXT",Utility.translateError(this, vars,vars.getLanguage(),e.getMessage()).getMessage());
    } 
    try {
      // Initialize Infobar helper variables
      String InfobarPrefix = "<span style=\"font-size: 20pt; color: #000000;\">";
      String InfobarText="";
      if (getLocalSessionVariable(vars, "pdcdirection").equals("D-"))
    	  if (getLocalSessionVariable(vars, "isrelocate").equals("Y"))
    		  InfobarText = Utility.messageBD(this, "pdc_Relocation",vars.getLanguage()) + "<br />";
    	  else
      	  InfobarText = Utility.messageBD(this, "pdc_Consumption",vars.getLanguage()) + "<br />";
      else
    	  InfobarText = Utility.messageBD(this, "pdc_Return",vars.getLanguage()) + "<br />";
      String InfobarSuffix = "</span>";
      String Infobar = "";
      String Infobar2 = "<span style=\"font-size: 14pt; color: #000000;\">";
      if (!snr.isEmpty())
    	  snr= " Snr:" + snr + (weight.isEmpty() ?"":"(" + weight + "kg)"); 
      if (!bnr.isEmpty())
    	  bnr= " Cnr:" + bnr;
      if (!getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty())
    	  if (getLocalSessionVariable(vars, "isrelocate").equals("Y"))
    		  Infobar2 =Infobar2 +Utility.messageBD(this, "pdc_materialrelocator",vars.getLanguage()) +": " + PdcCommonData.getLocator(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid"));
    	  else
    		  Infobar2 =Infobar2 +Utility.messageBD(this, "pdcmaterialconsumptionlocator",vars.getLanguage()) +": " + PdcCommonData.getLocator(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid"));
      if (!getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").isEmpty()) {
    	  Infobar2 =Infobar2 + "<br />" + Utility.messageBD(this, "Product",vars.getLanguage())  +": " + PdcCommonData.getProduct(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), vars.getLanguage());
    	  Infobar2 =Infobar2 + "<br />" + (snr.isEmpty()?(LocalizationUtils.getElementTextByElementName(this, "Quantity", vars.getLanguage())+" :" + getLocalSessionVariable(vars, "quantity")):"") + snr + bnr;
      }    
      // Get InfoBar Text
      if (getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty())   
        InfobarText = InfobarText + Utility.messageBD(this, "pdc_ScanLocatorIC",vars.getLanguage());
      else
    	  InfobarText = InfobarText + Utility.messageBD(this, "pdc_ScanProductIC",vars.getLanguage());
      // Generate Infobar
      Infobar = InfobarPrefix + InfobarText + InfobarSuffix;
      //strPdcInfobar = fh.prepareInfobar(this, vars, script, Infobar, "");                       // Generate infobar html code
      strPdcInfobar = ConfigureInfobar.doConfigure2Rows(this, vars, script, Infobar, Infobar2);   
      
      // Setting global session variables
      vars.setSessionValue("pdcUserID", GlobalUserID);
      vars.setSessionValue("pdcWorkStepID", GlobalWorkstepID);
      vars.setSessionValue("pdcLocatorID", GlobalLocatorID);
      //vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
      
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      
      // GUI Settings Responsive for Mobile Devises
      // Prevent Softkeys on Mobile Devices (Field is Readonly and programmatically set). Field dummyfocusfield must exist (see MobileHelper.addDummyFocus)
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
      script.addHiddenfieldWithID("forcefocusfield", "pdcmaterialconsumptionbarcode"); // Force Focus after Numpad to given Field
      EditableGrid lowergrid;
      // Set Session Value for Mobiles (Android Systems) - Effect is that the new Numpad is loaded
      // Upright Screen Zoomes200%
      if (MobileHelper.isMobile(request)) 
    	  MobileHelper.setMobileMode(request, vars, script);
      if (MobileHelper.isScreenUpright(vars)) // Upright : Smaller Grid
      	lowergrid = new EditableGrid("PdcMaterialConsumptionReturnGridMobile", vars, this);  // Load lower grid structure from AD (use AD name)
       else 
        // Load grid structure
        lowergrid = new EditableGrid("PdcMaterialConsumptionReturnGrid", vars, this);  // Load lower grid structure from AD (use AD name)
      lowerGridData = PdcMaterialConsumptionData.selectlower(this, vars.getLanguage(),GlobalConsumptionID);
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      // Generate servlet skeleton html code
      strQuit="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID",strQuit, "Material Consumption", "", "REMOVED", null,"true");   // Generate skeleton
      if (comingserial.equals("Y")) {
    	  InfobarText = Utility.messageBD(this, "pdc_ScanProductCompletedC",vars.getLanguage()); 
      	  comingserial="";
      };                 
      
      
      // Generate servlet elements html code
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, "PdcMaterialConsumptionReturnHeader", null, false);        // Generate header html code
      // crAction adds RETURN and TAB to Barcode field -> Triggers SAVE_NEW
      
      if (MobileHelper.isMobile(request)) {
    	  strHeaderFG=MobileHelper.addcrActionBarcode(strHeaderFG);
    	  // On Upright Screens Hide Barcode Field (Prevents Focus and Mobile Soft Keypad)
    	  if (MobileHelper.isScreenUpright(vars))
    		  strHeaderFG=MobileHelper.hideActionBarcode(strHeaderFG);
      }
      // Settings for dummy focus...
      strHeaderFG=MobileHelper.addDummyFocus(strHeaderFG);

      strStatusFG = PdcStatusBar.getStatusBar(request,this, vars, script);       // Generate status html code (With Request is Mobile Aware..)
          
      // Manual injections - both grids with defined height and scrollbar
      strLowerGrid = Replace.replace(strLowerGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
      strLowerGrid = Replace.replace(strLowerGrid, "</TABLE>","</TABLE>\n</DIV>");
      
      // Fit all the content together
      strOutput = Replace.replace(strSkeleton, "@CONTENT@", MobileHelper.addMobileCSS(request,strPdcInfobar + strHeaderFG + strLowerGrid + strStatusFG));
      
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

