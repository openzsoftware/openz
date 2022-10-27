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
import org.openz.view.Formhelper;
import org.openz.view.InfoBarHelper;
import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.util.*;
import java.math.BigDecimal;
import org.openz.pdc.controller.*;

public class PdcStoreConsumptionAndReturn extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  
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
      String strLowerGrid = "";                 // Lower grid (defined in AD)
      String strStatusFG = "";                  // Status fieldgroup (defined in AD)
      String snr="";
      String bnr="";

      // Initialize fieldproviders - they provide data for the grids
      FieldProvider[] lowerGridData;    // Data for the lower grid
      // weight of goods in trx
      String weight="";
      // Initialize DB dialogue datafield
      PdcMaterialConsumptionData[] data;      
      // Loading global session variables
      String GlobalUserID = vars.getUser();
      String GlobalWorkstepID = vars.getSessionValue("pdcWorkStepID");
      String GlobalLocatorID = getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid");
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
       if (vars.commandIn("DEFAULTRELOCATE")||vars.commandIn("DEFAULTCONSUME")||vars.commandIn("DEFAULTRETURN")||vars.commandIn("DEFAULT")||vars.commandIn("DEFAULTRELOCATEFROM")) {
    	removeSessionVars(vars); 
    	// Saved Session-Get USECASE and load Data
 	    GlobalConsumptionID = PdcMaterialConsumptionReturnData.runningConsumption(this, GlobalUserID);	// Load Oldest saved Trx
 	    if (!FormatUtils.isNix(GlobalConsumptionID)) {
 	    	vars.setSessionValue("PDCSTATUS","OK");
 	    	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_continuetrx",vars.getLanguage()));
 	    	if (PdcMaterialConsumptionReturnData.TrxRelocationType(this, GlobalConsumptionID).equals("N")) {
 	    		if (PdcMaterialConsumptionReturnData.TrxType(this, GlobalConsumptionID).equals("D-"))
 	    			setLocalSessionVariable(vars, "pdcdirection","D-");
 	    		else
 	    			setLocalSessionVariable(vars, "pdcdirection","D+");
 	    	}
 	    	if (PdcMaterialConsumptionReturnData.TrxRelocationType(this, GlobalConsumptionID).equals("S")) {
 	    		setLocalSessionVariable(vars, "isrelocate","Y");
 	    		setLocalSessionVariable(vars, "pdcdirection","D-");
 	    	}
 	    	if (PdcMaterialConsumptionReturnData.TrxRelocationType(this, GlobalConsumptionID).equals("R")) { // R
 	    		setLocalSessionVariable(vars, "isrelocatefrom","Y");
 	    		setLocalSessionVariable(vars, "pdcdirection","D-");
 	    		if (!FormatUtils.isNix(PdcMaterialConsumptionReturnData.runningRelocationReturn(this, GlobalUserID))) { 
 	    			setLocalSessionVariable(vars, "pdcmaterialConsumptionFromID",GlobalConsumptionID);
 	    			GlobalConsumptionID=PdcMaterialConsumptionReturnData.runningRelocationReturn(this, GlobalUserID);
 	    			setLocalSessionVariable(vars, "pdcdirection","D+");
 	    		} 	    			
 	    	}
 	    	GlobalLocatorID = PdcMaterialConsumptionReturnData.getLocatorFromrunningConsumption(this, GlobalConsumptionID);
 	    	vars.setSessionValue("pdcConsumptionID",GlobalConsumptionID);
 	    	setLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid",GlobalLocatorID);
	    } else {
	 	    // Not Saved: Load Empty USECASE
	    	if (vars.commandIn("DEFAULTCONSUME")||vars.commandIn("DEFAULTRELOCATE")||vars.commandIn("DEFAULTRELOCATEFROM")) 
	    	   setLocalSessionVariable(vars, "pdcdirection","D-");
	    	if (vars.commandIn("DEFAULTRETURN")) 
	    	   setLocalSessionVariable(vars, "pdcdirection","D+");
	    	if (vars.commandIn("DEFAULTRELOCATE"))
	    		setLocalSessionVariable(vars, "isrelocate","Y");
	    	if (vars.commandIn("DEFAULTRELOCATEFROM"))
	    		setLocalSessionVariable(vars, "isrelocatefrom","Y");
	    }
      }
      if (vars.commandIn("SAVE_NEW_NEW")) {
    	  // Read Description Field
    	  String dscr=vars.getStringParameter("inppdcmaterialconsumptiondescription");
    	  setLocalSessionVariable(vars, "pdcmaterialconsumptiondescription",dscr);  
    	  // REad Barcode
    	  PdcCommonData bar=PdcCommons.getBarcode(this, vars);
    	  String bctype=bar.type;
    	  String bcid=bar.id;
    	  String barcode=bar.barcode;
    	  weight=bar.weight;
    	  snr=bar.serialnumber;
    	  bnr=bar.lotnumber;
    	  if (vars.getSessionValue("P|KOMBIBARCODEMANDATORY").equals("Y") && (
    			  bctype.equals("PRODUCT")||bctype.equals("UNKNOWN")||bctype.equals("BATCHNUMBER")||bctype.equals("SERIALNUMBER")))
    	  {
    		  if (bctype.equals("UNKNOWN"))
    			  throw new Exception(Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+barcode);
    		  else
    			  throw new Exception(Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+barcode);
    	  }
    	  if (vars.getSessionValue("P|WEIGHTMANDATORY").equals("Y") && bctype.equals("KOMBI") && FormatUtils.isNix(weight))
    		  throw new Exception(Utility.messageBD(this, "Gewicht fehlt.",vars.getLanguage()));
    	  vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode); 
          //Time Feedback mot applicable
          if (bctype.equals("EMPLOYEE")||bcid.equals("872C3C326AB64D1EBABDD49A1E138136")||
        		  ((bctype.equals("SERIALNUMBER")||bctype.equals("BATCHNUMBER")) && getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").isEmpty())
        	  ){
        	  vars.setSessionValue("PDCSTATUS","WARNING");
        	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"\r\n"+barcode);       
              
          } else if (bctype.equals("LOCATOR")) {
              setLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid", bcid);
              GlobalLocatorID=  bcid;   
              if (!PdcCommonData.inventoryRunning(this, GlobalLocatorID).equals("0"))
            	  throw new Exception(Utility.messageBD(this, "RunningInventory",vars.getLanguage()));
              
          } else if (bctype.equals("PRODUCT")&&! getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty()) {
        	  String qty=vars.getNumericParameter("inppdcmaterialconsumptionquantity");
              if (qty.isEmpty())
                qty="1";              
              if (!qty.equals("0") && !SerialNumberData.pdc_getSerialBatchType4product(this, bcid).equals("NONE"))
            	  qty="1";
              setLocalSessionVariable(vars, "quantity",qty);  
              setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", bcid);
            BcCommand = "NEXT";
            
          }  else if (bctype.equals("KOMBI")&&! getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty()) {
              setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", bcid);
              String qty=vars.getNumericParameter("inppdcmaterialconsumptionquantity");
              if (qty.isEmpty())
                qty="1";
              String type=SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"));
              if ((type.equals("SERIAL")||type.equals("BOTH"))&& !qty.equals("0")) 
        		  qty="1";	
              setLocalSessionVariable(vars, "quantity",qty);
              BcCommand = "KOMBINEXT";        
          } else if (bctype.equals("WORKSTEP")) {
            if  (GlobalConsumptionID.isEmpty()){
              setLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid", bcid);
              GlobalWorkstepID=bcid;             
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
        	if (getLocalSessionVariable(vars, "pdcdirection").equals("D+") && !getLocalSessionVariable(vars, "isrelocate").equals("Y") && !getLocalSessionVariable(vars, "isrelocatefrom").equals("Y")
        		&& !getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").equals("")
        		&& !SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")).equals("NONE")
        		&& !SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")).equals("BOTH")
        		&& !barcode.contains("|")) // Nur bei Rückgabe neue BNR/CNR aufnehmen
            {        		
        		vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_newBnrSnrAssigned", vars.getLanguage()));
        		if (SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")).equals("SERIAL"))
        			bctype="SERIALNUMBER";
        		else // Batch
        			bctype="BATCHNUMBER";
        	} else {	
        		vars.setSessionValue("PDCSTATUS","ERROR");
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode);
        	}
          }  if (bctype.equals("BATCHNUMBER") && !getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").isEmpty()) {  
        	  // Line must exists (Product Scan first..)
        	  String sameline=PdcCommonData.getIDWhenScannedSameLine(this, GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid"));
        	  String qty=vars.getNumericParameter("inppdcmaterialconsumptionquantity");
              if (qty.isEmpty())
                qty="1";
              if (FormatUtils.isNix(sameline)|| !SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")).equals("BATCH")
            		  ||PdcMaterialConsumptionReturnData.IsRelocationCorrect(this, getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"),GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), qty, "",barcode).equals("N")) {
            	  vars.setSessionValue("PDCSTATUS", "WARNING");
                  vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+barcode);
              } else {
            	  PdcMaterialConsumptionReturnData.lineSNRBNRUpdate(this, sameline, GlobalUserID, qty, "", barcode, vars.getLanguage(),weight);
            	  bnr=barcode;
              }
            	        
          } if (bctype.equals("SERIALNUMBER") && !getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").isEmpty()) {  
        	  String sameline=PdcCommonData.getIDWhenScannedSameLine(this, GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid"));
        	  String qty=vars.getNumericParameter("inppdcmaterialconsumptionquantity");
        	  if (!qty.equals("0"))
        		  qty="1"; 
        	  if (FormatUtils.isNix(sameline)|| SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")).equals("NONE")
        			                         || SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")).equals("BATCH")
        			                         || PdcMaterialConsumptionReturnData.IsRelocationCorrect(this, getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"),GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), qty,barcode,"").equals("N")) {
            	  vars.setSessionValue("PDCSTATUS", "WARNING");
                  vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+barcode);
              } else {
            	  PdcMaterialConsumptionReturnData.lineSNRBNRUpdate(this, sameline, GlobalUserID, qty, barcode, "", vars.getLanguage(),weight);
            	  snr=barcode;
              }
          }
      
 
      if (BcCommand.equals("NEXT")||BcCommand.equals("KOMBINEXT")) {
        if (getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").equals("")||
            getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").equals("")||
            PdcMaterialConsumptionReturnData.IsRelocationCorrect(this, getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"),GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), getLocalSessionVariable(vars, "quantity"),snr,bnr).equals("N")){         
          vars.setSessionValue("PDCSTATUS","ERROR");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage()));
        } else { 
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ProductScannedCorrectly",vars.getLanguage()));
          //Umlagern
          if (getLocalSessionVariable(vars, "isrelocatefrom").equals("Y") && !GlobalConsumptionID.isEmpty()  && !getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID").isEmpty()
        		  && GlobalConsumptionID.equals(getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"))) {
        	  GlobalConsumptionID="";  
        	  setLocalSessionVariable(vars, "pdcdirection","D+");
          }
          // Neu
          if (GlobalConsumptionID.equals("")) {
            GlobalConsumptionID = UtilsData.getUUID(this);
            String rdoc=PdcMaterialConsumptionReturnData.getRDocNum(this, getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"));
            PdcMaterialConsumptionReturnData.insertConsumption(
                this,
                GlobalConsumptionID,
                vars.getClient(),
                vars.getOrg(),
                vars.getUser(),
                getLocalSessionVariable(vars, "pdcmaterialconsumptiondescription"),
                PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid")),
                getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid"),
                getLocalSessionVariable(vars, "pdcdirection"),rdoc,
                getLocalSessionVariable(vars, "isrelocatefrom").equals("Y")?"R":getLocalSessionVariable(vars, "isrelocate").equals("Y")?"S":"N");
            vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
           } else
        	   PdcMaterialConsumptionReturnData.updateConsumption( this, getLocalSessionVariable(vars, "pdcmaterialconsumptiondescription"), GlobalConsumptionID);

            // On Serial Numbers - Get TRX Locator from SNR Masterdata
            String trxlocator="";
            if (!snr.isEmpty() && getLocalSessionVariable(vars, "pdcdirection").equals("D-"))
            	trxlocator=SerialNumberData.getLocatorIdFromSerialAndProduct(this, snr, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"));
            if (trxlocator==null || trxlocator.isEmpty())
            	trxlocator=getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid");
          
            // Check if Value Updates a line or deletes a line          
            String sameline=PdcCommonData.getIDWhenScannedSameLine(this, GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), trxlocator);
            if (sameline==null) sameline="";
            // Check if on D- : qtyonhand OK?
            if (getLocalSessionVariable(vars, "pdcdirection").equals("D-") && !getLocalSessionVariable(vars, "isrelocate").equals("Y")) {
            	String istrxOk=PdcMaterialConsumptionReturnData.isTrxOnStock(this, GlobalConsumptionID, trxlocator, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), getLocalSessionVariable(vars, "quantity"), vars.getLanguage());
            	if (!istrxOk.equals("TRUE")) {
            		throw new Exception (istrxOk);
            	}
            }
            // Qty > 0 and new line
            if (sameline.equals("") && new BigDecimal(getLocalSessionVariable(vars, "quantity").replace(",", "")).compareTo(BigDecimal.ZERO)==1) {
              if(getLocalSessionVariable(vars, "isrelocate").equals("Y") && snr.isEmpty()) {
            	  vars.setSessionValue("PDCSTATUS","ERROR");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_relocationonlyserial",vars.getLanguage()));
              } else {
	              String lineUuid=UtilsData.getUUID(this);
	              PdcMaterialConsumptionReturnData.insertMaterialLine( this, lineUuid,vars.getClient(), vars.getOrg(), 
	                  vars.getUser(),GlobalConsumptionID,trxlocator,getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"),
	                  PdcCommonData.getNextLineFromConsumption(this, GlobalConsumptionID),
	                  getLocalSessionVariable(vars, "quantity"),PdcCommonData.getProductStdUOM(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")),PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid")),
	                  getLocalSessionVariable(vars, "pdcmaterialconsumptionworkstepid"));
	              
	              // Snr's/Bnr'
	              if (BcCommand.equals("KOMBINEXT")) {
	            		  try {
	            			  PdcMaterialConsumptionReturnData.lineSNRBNRUpdate(this, lineUuid, GlobalUserID, getLocalSessionVariable(vars, "quantity"), snr, bnr, vars.getLanguage(),weight);
	            		  } catch (Exception e) { 
	            			  PdcCommonData.deleteMaterialLine( this, lineUuid);
	            			  // Relocate: Accepts 
	            			  if (getLocalSessionVariable(vars, "isrelocate").equals("Y")&& !e.getMessage().contains("@doublescan@")) {
	            				  if (PdcMaterialConsumptionReturnData.TempItemExists(this, GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"),snr).equals("N"))
	            					  PdcMaterialConsumptionReturnData.insertSerialTempItem(this, vars.getClient(), vars.getOrg(), vars.getUser(), GlobalConsumptionID,getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), snr,weight,trxlocator,null);
	            				  else
	            					  throw new Exception ("@doublescan@"); 
	            			  } else {            				  
		            			  // Consumption denies
		            			  vars.setSessionValue("PDCSTATUS","ERROR");
		            			  vars.setSessionValue("PDCSTATUSTEXT",Utility.translateError(this, vars,vars.getLanguage(),e.getMessage()).getMessage());
	            			  }
	            		  }
	              }
              }
            }
            else if (new BigDecimal(getLocalSessionVariable(vars, "quantity")).compareTo(BigDecimal.ZERO)==1) {   // >0
              String type=SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"));
              String qty=getLocalSessionVariable(vars, "quantity");
        	  vars.setSessionValue("PDCSTATUS","OK");
        	  if (type.equals("NONE")) 
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ProductQtyUpdated",vars.getLanguage()));
        	  if (!type.equals("NONE")&&BcCommand.equals("NEXT"))
        		  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_scanSNRBNRToUpdateQty",vars.getLanguage()));
              // Update existing Line with new QTY
              if (type.equals("NONE")) {
            	  PdcMaterialConsumptionReturnData.updateMaterialLine( this,  qty,sameline);
              } else {
            	  try {
            		  PdcMaterialConsumptionReturnData.lineSNRBNRUpdate(this, sameline, GlobalUserID, qty, snr, bnr, vars.getLanguage(),weight);
            	  } catch (Exception e) { 
            		// Relocate: Accepts 
        			  if (getLocalSessionVariable(vars, "isrelocate").equals("Y")&& !e.getMessage().contains("@doublescan@")) {
        				  if (PdcMaterialConsumptionReturnData.TempItemExists(this, GlobalConsumptionID,getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), snr).equals("N"))
        					  PdcMaterialConsumptionReturnData.insertSerialTempItem(this, vars.getClient(), vars.getOrg(), vars.getUser(), GlobalConsumptionID,getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), snr,weight,trxlocator,sameline);
        				  else
        					  throw new Exception ("@doublescan@"); 
        			  } else {            				  
            			  // Consumption denies
            			  vars.setSessionValue("PDCSTATUS","ERROR");
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
        } // qty and locattor
      }  // Next - Kombinext
      } // Save New
      
      if (vars.commandIn("DONE")||BcCommand.equals("DONE")) {
    	String msgtext="";	
        String relocateTRX="";
    	if (getLocalSessionVariable(vars, "isrelocatefrom").equals("Y") && GlobalConsumptionID.equals(getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID")) && !GlobalLocatorID.isEmpty()) {
    		// RelocateFrom to only one  Return Locator. Behaves like Relocate
    		setLocalSessionVariable(vars, "isrelocate","Y");
    		deleteLocalSessionVariable(vars, "isrelocatefrom");
    	} 
    	if (getLocalSessionVariable(vars, "isrelocatefrom").equals("Y") && !GlobalConsumptionID.equals(getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"))
    			&& PdcMaterialConsumptionReturnData.pdc_isRelocationPossible(this, getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"),GlobalConsumptionID).equals("Y")) {
    		// Relocate From (many Locators): Consumption and REturn schould contain same Products/Qty's/Serials
    		relocateTRX=GlobalConsumptionID;
    		GlobalConsumptionID=getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID");
    	}
        if (PdcCommonData.isbatchorserialnumber(this, GlobalConsumptionID).equals("N")&& !GlobalConsumptionID.isEmpty() && !PdcMaterialConsumptionReturnData.countlower(this, GlobalConsumptionID).equals("0")
        		&& !GlobalLocatorID.isEmpty() && (getLocalSessionVariable(vars, "isrelocatefrom").isEmpty() || !relocateTRX.isEmpty()) ){
          Connection con=this.getTransactionConnection();	
          try {
        	  if (!PdcMaterialConsumptionReturnData.countlines(this, GlobalConsumptionID).equals("0")) {
        		  PdcMaterialConsumptionReturnData.executeConsumptionPost(con, this, GlobalConsumptionID);
        		  msgtext=UtilsData.getProcessResultWC(con,this, GlobalConsumptionID);
        		  if (msgtext.startsWith("ERROR"))
        			  throw new Exception(msgtext.replaceFirst("ERROR", ""));
        	  }
        	  if (getLocalSessionVariable(vars, "isrelocate").equals("Y")) {
        		  relocateTRX=PdcMaterialConsumptionReturnData.copyConsumption2Return(con,this, GlobalConsumptionID, GlobalLocatorID, GlobalUserID);
        		  if (!relocateTRX.equals("STORNO")) {
        			  PdcMaterialConsumptionReturnData.executeConsumptionPost(con, this, relocateTRX);
        			  msgtext=UtilsData.getProcessResultWC(con,this, relocateTRX);
        			  if (msgtext.startsWith("ERROR"))
                		  throw new Exception(msgtext.replaceFirst("ERROR", ""));
        		  }
        	  }
        	  if (getLocalSessionVariable(vars, "isrelocatefrom").equals("Y")) {
        		  PdcMaterialConsumptionReturnData.pdc_tempItems2Relocation(con, this, relocateTRX);
        		  PdcMaterialConsumptionReturnData.executeConsumptionPost(con, this, relocateTRX);
        		  msgtext=UtilsData.getProcessResultWC(con,this, relocateTRX);
    			  if (msgtext.startsWith("ERROR"))
            		  throw new Exception(msgtext.replaceFirst("ERROR", ""));
        	  }
        	  if (PdcMaterialConsumptionReturnData.countlines(this, GlobalConsumptionID).equals("0"))
        		  PdcMaterialConsumptionReturnData.deleteConsumption(con,this, GlobalConsumptionID);
        	  con.commit();
        	  con.close();
          } catch (Exception e) { 
        	  con.rollback();
        	  try {con.close();}catch (Exception ign) {}
        	  e.printStackTrace();
        	  throw (e);
          }
          // PdcCommonData.doConsumptionPost(this, strConsumptionid);
          vars.setSessionValue("PDCSTATUS","OK");
          if (getLocalSessionVariable(vars, "pdcdirection").equals("D-"))
          	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MatSucessful",vars.getLanguage())+msgtext);
          else
           	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_RetSucessful",vars.getLanguage())+msgtext);
          if (getLocalSessionVariable(vars, "isrelocate").equals("Y")) 
           	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_RelocationSucessful",vars.getLanguage())+msgtext);
          removeSessionVars(vars);
          response.sendRedirect(strDireccion + strpdcFormerDialogue);
          return;
        } else {
        	if (!PdcCommonData.isbatchorserialnumber(this, GlobalConsumptionID).equals("N")) {
        		vars.setSessionValue("PDCSTATUS","ERROR");
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_SNRBNRNecessary",vars.getLanguage()));
        	} else if (getLocalSessionVariable(vars, "isrelocatefrom").equals("Y") && !GlobalConsumptionID.equals(getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"))
    			&& PdcMaterialConsumptionReturnData.pdc_isRelocationPossible(this,getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"), GlobalConsumptionID).equals("N")) {
        		vars.setSessionValue("PDCSTATUS","ERROR");
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_relocationQtyMismatch",vars.getLanguage()));
        	}
        	else {        		
        			vars.setSessionValue("PDCSTATUS","OK");
        			vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NoData",vars.getLanguage()));
        	}
        }
      }
      
      if (vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")) {
        PdcCommonData.deleteAllMaterialLines( this, GlobalConsumptionID);
        PdcCommonData.deleteMaterialTransaction( this, GlobalConsumptionID);
        PdcCommonData.deleteAllMaterialLines( this, getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"));
        PdcCommonData.deleteMaterialTransaction( this, getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"));
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
        removeSessionVars(vars);
        GlobalWorkstepID="";
        GlobalLocatorID="";
        response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
        return;
      }
      if (vars.commandIn("PAUSE")) {      	
      	  removeSessionVars(vars);
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_pause",vars.getLanguage()));        
          response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
          return;
      }
      if (vars.commandIn("RELOCATETO")) {      	
    	  removeSessionVars(vars);
    	  setLocalSessionVariable(vars, "pdcmaterialConsumptionFromID",GlobalConsumptionID);
    	  setLocalSessionVariable(vars, "isrelocatefrom","Y");
    	  vars.setSessionValue("pdcConsumptionID",GlobalConsumptionID);
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_materialrelocator",vars.getLanguage()));                  
      }
    }
    // Present Errors on the User Screen
    catch (Exception e) { 
    	e.printStackTrace();
    	vars.setSessionValue("PDCSTATUS","ERROR");
	    vars.setSessionValue("PDCSTATUSTEXT",Utility.translateError(this, vars,vars.getLanguage(),e.getMessage()).getMessage());
    } 
    try {
      // Prepare the GUI
      // Initialize Infobar
      String big1,big2="",small1="",small2="",small3="";
      if (getLocalSessionVariable(vars, "isrelocate").equals("Y"))
    	  big1=Utility.messageBD(this, "pdc_Relocation",vars.getLanguage());
      else if (getLocalSessionVariable(vars, "isrelocatefrom").equals("Y"))
    	  big1=Utility.messageBD(this, "pdc_Relocatefrom",vars.getLanguage());
      else if (getLocalSessionVariable(vars, "pdcdirection").equals("D-"))
    	  big1=Utility.messageBD(this, "pdc_Consumption",vars.getLanguage());
      else
    	  big1=Utility.messageBD(this, "pdc_Return",vars.getLanguage());
      if (getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty())
    	  big2=Utility.messageBD(this, "pdc_ScanLocatorIC",vars.getLanguage());      
      if (!getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty())
    	  big2=Utility.messageBD(this, "pdc_ScanProductIC",vars.getLanguage());
      if (PdcMaterialConsumptionReturnData.isSNRBNRequired(this, GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid")).equals("TRUE"))
    	  big2=Utility.messageBD(this, "pdc_ScanSNRBNR",vars.getLanguage());
      if (!getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty())
    	  if (getLocalSessionVariable(vars, "isrelocate").equals("Y")||
    			  (getLocalSessionVariable(vars, "isrelocatefrom").equals("Y")&& ! getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID").isEmpty()))
    		  small1= Utility.messageBD(this, "pdc_materialrelocator",vars.getLanguage()) +": " + PdcCommonData.getLocator(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid"))+ ": " + PdcCommonData.getSumUp(this, vars.getLanguage(),GlobalConsumptionID);
    	  else
    		  small1= Utility.messageBD(this, "pdcmaterialconsumptionlocator",vars.getLanguage()) +": " + PdcCommonData.getLocator(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid"))+ ": " + PdcCommonData.getSumUp(this, vars.getLanguage(),GlobalConsumptionID);
      if (!getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").isEmpty()) {
    	  small2=Utility.messageBD(this, "Product",vars.getLanguage())  +": " + PdcCommonData.getProduct(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), vars.getLanguage());
    	  small3=InfoBarHelper.getSnrBnrStr(this, vars, snr, bnr, PdcMaterialConsumptionReturnData.getProductQTY(this, vars.getLanguage(), GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid")), weight);
    	  //small3=(snr.isEmpty()&&(bnr.isEmpty())?(LocalizationUtils.getElementTextByElementName(this, "Quantity", vars.getLanguage())+": " + PdcMaterialConsumptionReturnData.getProductQTY(this, vars.getLanguage(), GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"))):"SN/CN: ") + snr + bnr;
      }
      strPdcInfobar=InfoBarHelper.upperInfoBarApp(this, vars, script, big1, big2, small1, small2, small3);
      // Setting global session variables
      vars.setSessionValue("pdcWorkStepID", GlobalWorkstepID);
      //vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
      
      // GUI Settings Responsive for Mobile Devises
      // Prevent Softkeys on Mobile Devices (Field is Readonly and programmatically set). Field dummyfocusfield must exist (see MobileHelper.addDummyFocus)
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
      script.addHiddenfieldWithID("forcefocusfield", "pdcmaterialconsumptionbarcode"); // Force Focus after Numpad to given Field
      EditableGrid lowergrid;
      // Set Session Value for Mobiles (Android Systems) - Effect is that the new Numpad is loaded
      // Upright Screen Zoomes200%
      if (MobileHelper.isMobile(request)) 
    	  MobileHelper.setMobileMode(request, vars, script);
      // Load grid structure
      if (getLocalSessionVariable(vars, "isrelocate").equals("Y"))  
    	lowergrid = new EditableGrid("PdcMaterialConsumptionReturnGridReduced", vars, this);  // Load lower grid structure from AD (use AD name)
       else 
        lowergrid = new EditableGrid("PdcMaterialConsumptionReturnGrid", vars, this);  // Load lower grid structure from AD (use AD name)
      String sameline=PdcCommonData.getIDWhenScannedSameLine(this, GlobalConsumptionID, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid"));
      if (sameline==null) sameline="";
      // Umlagern
      if (!FormatUtils.isNix(GlobalConsumptionID) && getLocalSessionVariable(vars, "isrelocatefrom").equals("Y") && 
    		  !GlobalConsumptionID.equals(getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"))  && !getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID").isEmpty())
    	lowerGridData = PdcMaterialConsumptionReturnData.selectrelocate(this, vars.getLanguage(), GlobalConsumptionID, sameline,getLocalSessionVariable(vars, "pdcmaterialConsumptionFromID"));
      else 
        lowerGridData = PdcMaterialConsumptionReturnData.select(this, vars.getLanguage(),sameline,GlobalConsumptionID);
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      // Generate servlet skeleton html code
      strQuit="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID",strQuit, "Material Consumption", "", "REMOVED", null,"true");   // Generate skeleton     
      
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

      strStatusFG = PdcStatusBar.getStatusBarAPP(request,this, vars, script);       // Generate status html code (With Request is Mobile Aware..)
      // On Error display Status in Upper screen
      if (! vars.getSessionValue("PDCSTATUS").equals("OK")) {
    	  strPdcInfobar= strPdcInfobar + strStatusFG;
    	  strStatusFG="";
      }
          
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
  
  
  private void removeSessionVars(VariablesSecureApp vars) {
	  deleteLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid");
      deleteLocalSessionVariable(vars, "pdcmaterialconsumptionproductid");
      deleteLocalSessionVariable(vars, "pdcmaterialconsumptiondescription");
      deleteLocalSessionVariable(vars,"pdcmaterialconsumptionserial");
      deleteLocalSessionVariable(vars,"pdcmaterialconsumptionbatch");
      deleteLocalSessionVariable(vars,"pdcmaterialConsumptionFromID");
      deleteLocalSessionVariable(vars, "isrelocate");
      deleteLocalSessionVariable(vars, "isrelocatefrom");
      vars.removeSessionValue("pdcConsumptionID");
  }
  
  public String getServletInfo() {
    return this.getClass().getName();
  }
  
  
}

