/*__________| PDC - Material Consumption |_________________________________________________
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

public class PdcMaterialConsumption extends HttpSecureAppServlet {
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
      PdcMaterialConsumptionData[] data;
      // Loading global session variables
      String PdcUserID = vars.getSessionValue("pdcUserID");
      String GlobalWorkstepID = vars.getSessionValue("pdcWorkStepID");
      setLocalSessionVariable(vars, WorkstepIDADName,GlobalWorkstepID);
      String GlobalLocatorID = vars.getSessionValue("pdcLocatorID");
      String GlobalConsumptionID = vars.getSessionValue("pdcConsumptionID");
      // Commons
      PdcCommons commons = new PdcCommons();
      // Serial or Batch ONLY From KOMBI Barcode
      String snrbnr="";
      String BcCommand = "";
      //setting History
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
   // Starting...
   try {
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMaterialConsumption.html"))){
      	vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
      	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }              
      // Look if we come from serial Number Tracking...
      String commandserial=vars.getSessionValue("PDCINVOKESERIAL");
      vars.removeSessionValue("PDCINVOKESERIAL");
      if (!commandserial.isEmpty()) {
          comingserial="Y";
      } else {
          setLocalSessionVariable(vars, "pdcproductionquantity", vars.getNumericParameter("inppdcproductionquantity"));
          setLocalSessionVariable(vars,"plannedserialorbatch", vars.getStringParameter("inpplannedserialorbatch"));
          if (!vars.getStringParameter("inpplannedserialorbatch").isEmpty())
        	  vars.setSessionValue("pdcAssemblySerialOrBatchNO",getLocalSessionVariable(vars,"plannedserialorbatch")); // If Input Changes, Propagate to global var
          if (PdcMaterialConsumptionData.isSerielProduced(this, getLocalSessionVariable(vars,"plannedserialorbatch"), GlobalWorkstepID).equals("Y"))
        	  if (!(vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")))
        	  throw new ServletException("@plannedserialisproduced@");
      }
      // Getting Workstep
      if (vars.getStringParameter("inp" + WorkstepIDADName).equals("")) {
        setLocalSessionVariable(vars, WorkstepIDADName, GlobalWorkstepID); 
        if (!vars.getSessionValue("pdcWorkstepFromMain").isEmpty()) {  // Comming from Main Servlet
        	setLocalSessionVariable(vars, WorkstepIDADName,vars.getSessionValue("pdcWorkstepFromMain"));
      		vars.removeSessionValue("pdcWorkstepFromMain");
      		BcCommand = "ALLPOSITIONS";
            GlobalWorkstepID = getLocalSessionVariable(vars, WorkstepIDADName);
            setQtsSer(GlobalWorkstepID,vars);
            setLocalSessionVariable(vars, "plannedserialorbatch", vars.getSessionValue("pdcAssemblySerialOrBatchNO"));
        }
      } else {
    	if (GlobalWorkstepID.isEmpty()||
    			(vars.getSessionValue("pdcConsumptionID").isEmpty()
    			 && !GlobalWorkstepID.equals(vars.getStringParameter("inp" + WorkstepIDADName)))) {// Workstep selected via dropdown
      	  BcCommand = "ALLPOSITIONS";
      	  setLocalSessionVariable(vars, WorkstepIDADName);
          GlobalWorkstepID = getLocalSessionVariable(vars, WorkstepIDADName);
          PdcCommons.setWorkstepVars(GlobalWorkstepID,null,null, vars,this);
          setQtsSer(GlobalWorkstepID,vars);
    	} 
      }
      
      
      // Business logic
      if (vars.commandIn("DEFAULT")) {
        if (GlobalWorkstepID.isEmpty()) {
        	deleteLocalSessionVariable(vars, "pdcproductionquantity");
        	vars.removeSessionValue("pdcAssemblyProductID"); 
        }
      }
      if (vars.commandIn("SAVE_NEW_NEW")) {
    	  vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_DataSelected",vars.getLanguage()));  
        if (!vars.getStringParameter("inp" + BarcodeADName).isEmpty()) {
          data = PdcMaterialConsumptionData.selectbarcode(this, vars.getStringParameter("inp" + BarcodeADName),vars.getRole());
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
            if  (GlobalConsumptionID.isEmpty()){
              PdcUserID=bcid;
              vars.setSessionValue("pdcUserID", PdcUserID);
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
        		if (bctype.equals("PRODUCT"))
        			workstep=PdcCommonData.getWorkstepFromProduct4Consumption(this, bcid);
        		if (bctype.equals("KOMBI"))
        			workstep=PdcCommonData.getWorkstepFromKombi4Consumption(this, bcid,snrbnr);
                if ( workstep!=null && ! workstep.isEmpty()) {
	        		setLocalSessionVariable(vars, WorkstepIDADName, workstep);
	                GlobalWorkstepID=workstep;
	                PdcCommons.setWorkstepVars(null,bcid,snrbnr, vars,this);
	                setQtsSer(GlobalWorkstepID,vars);
	                BcCommand = "ALLPOSITIONS";
	                vars.setSessionValue("pdcAssemblyProductID",bcid);  
	                vars.setSessionValue("PDCSTATUS","OK");
		            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
                } else {
                	vars.setSessionValue("PDCSTATUS", "ERROR");
                    vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
                }
        	} else {
	            setLocalSessionVariable(vars, ProductIDADName, bcid);
	            if (GlobalLocatorID.isEmpty()) {
	            	String locator=PdcMaterialConsumptionData.getLocator(this, GlobalConsumptionID, GlobalWorkstepID, bcid);
	        		if (locator!=null && !locator.isEmpty()){
	        			GlobalLocatorID=  locator;
	        		}
	            }
	            String qty=vars.getNumericParameter("inp" + QuantityADName);
	            qty=PdcCommons.getQtyIncrement(qty, bcid, GlobalConsumptionID, this);
	            setLocalSessionVariable(vars, QuantityADName,qty);
	            if (!GlobalLocatorID.isEmpty()) {
	            	String assproduct=PdcCommonData.getProductFromDurchreicheWorkstep(this,  GlobalWorkstepID);
	            	if (assproduct!=null && assproduct.equals(bcid) && bctype.equals("KOMBI") && vars.getSessionValue( this.getServletInfo() + "|plannedserialorbatch").isEmpty() && UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y"))
	            		vars.setSessionValue( this.getServletInfo() + "|plannedserialorbatch",snrbnr);
	            	BcCommand = "NEXT";
	                vars.setSessionValue("PDCSTATUS","OK");
	                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));
	            } else {
	            	vars.setSessionValue("PDCSTATUS","ERROR");
	                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanLocator",vars.getLanguage()));
	            }
	            
        	}  
          } else if (bctype.equals("WORKSTEP")) {
            if  (GlobalConsumptionID.isEmpty()){
              setLocalSessionVariable(vars, WorkstepIDADName, bcid);
              GlobalWorkstepID=bcid;
              PdcCommons.setWorkstepVars(GlobalWorkstepID,null,null, vars,this);
              setQtsSer(GlobalWorkstepID,vars);
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
      } // SAVE_NEW_NEW
      if (vars.commandIn("ALLPOSITIONS")||BcCommand.equals("ALLPOSITIONS")){
    	if (UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y") && getLocalSessionVariable(vars,"plannedserialorbatch").isEmpty() && vars.getSessionValue("ISSNRBNR").equals("Y")) {
			  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_PlannedSerialNumberNecessary",vars.getLanguage()));
    	} else if (getLocalSessionVariable(vars, WorkstepIDADName).equals("")||
        		PdcUserID.isEmpty()){          
        	if (PdcUserID.isEmpty())
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()));
        	else
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanWorkstep",vars.getLanguage()));
        } else { 
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT","");
          upperGridData = PdcMaterialConsumptionData.selectupper(this, vars.getLanguage(),getLocalSessionVariable(vars, "pdcproductionquantity"),vars.getSessionValue("pdcAssemblySerialOrBatchNO"),GlobalConsumptionID, getLocalSessionVariable(vars, WorkstepIDADName));
          if (GlobalConsumptionID.equals("") && upperGridData.length>0
                  && !(PdcMaterialConsumptionData.getProduceContinuously(this, GlobalWorkstepID).equals("Y") && getLocalSessionVariable(vars, "pdcproductionquantity").equals(""))) {
            GlobalConsumptionID = UtilsData.getUUID(this);
            PdcMaterialConsumptionData.insertConsumption(
                this,
                GlobalConsumptionID,
                vars.getClient(),
                vars.getOrg(),
                PdcUserID,
                PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, WorkstepIDADName)),
                getLocalSessionVariable(vars, WorkstepIDADName),getLocalSessionVariable(vars, "plannedserialorbatch"));
              vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
	          for (int i=0;i<upperGridData.length;i++){
	            if (upperGridData[i].getField("pdcmaterialconsumptionlocator").isEmpty()) {
	              vars.setSessionValue("PDCSTATUS","ERROR");
	              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MustSetProductQtyAndLocator",vars.getLanguage()));
	            } else {
	              // Impl. Partly Production
	              String qty;
	              //if (!getLocalSessionVariable(vars, "pdcproductionquantity").equals(PdcCommonData.getQtyLeftFromWorkstep(this, GlobalWorkstepID))) {
	            	if (PdcCommonData.isProducedSerial(this, GlobalWorkstepID, getLocalSessionVariable(vars, "plannedserialorbatch")).equals("Y"))
	            	  qty="";
	            	else {
	            	  qty= PdcMaterialConsumptionData.getQtyPartly(this, upperGridData[i].getField("pdcmaterialconsumptionplannedqty") , GlobalWorkstepID, upperGridData[i].getField("m_product_id"), upperGridData[i].getField("m_locator_id"));
	            	  if (!getLocalSessionVariable(vars, "plannedserialorbatch").isEmpty()  && ! FormatUtils.isNix(qty)) {
	            		  String rq=PdcMaterialReturnData.getRetQty(this, upperGridData[i].getField("m_product_id"),GlobalConsumptionID,GlobalWorkstepID,getLocalSessionVariable(vars, "plannedserialorbatch"));
	            		  if (! FormatUtils.isNix(rq)) {
	            			  Float qtyf = Float.parseFloat(qty);
	            			  Float serq = Float.parseFloat(rq);
	            			  Float bq=qtyf-serq;
	            			  if (bq<=0)
	            				  qty="";
	            			  else
	            				  qty=bq.toString();  
	            		  }
	            	  }
	            	}
	              //}else 
	              //	  qty=PdcMaterialConsumptionData.getQty(this, GlobalConsumptionID, GlobalWorkstepID, upperGridData[i].getField("m_product_id"), upperGridData[i].getField("m_locator_id"));
	              if (! qty.isEmpty()) {
	                if (new BigDecimal(qty).compareTo(BigDecimal.ZERO)==1) {
	                  PdcCommonData.insertMaterialLine( this, vars.getClient(), vars.getOrg(), 
	                		  PdcUserID,GlobalConsumptionID,upperGridData[i].getField("m_locator_id"),upperGridData[i].getField("m_product_id"),
	                    PdcCommonData.getNextLineFromConsumption(this, GlobalConsumptionID),
	                    qty,
	                    PdcCommonData.getProductStdUOM(this, upperGridData[i].getField("m_product_id")),
	                    PdcCommonData.getProductionOrderFromWorkstep(this,getLocalSessionVariable(vars, WorkstepIDADName)),
	                    getLocalSessionVariable(vars, WorkstepIDADName));
	                }
	            }
	            }
	          }
          } else {
          	PdcCommonData.deleteAllMaterialLines(this,GlobalConsumptionID);
          	PdcCommonData.deleteMaterialTransaction(this,GlobalConsumptionID);
          	vars.removeSessionValue("pdcConsumptionID");
          }
        }
      }
      if ((vars.commandIn("PRODUCTION")||vars.commandIn("REJECT")) && qtySerOK(vars,GlobalWorkstepID)) {
    	  Connection con=this.getTransactionConnection();	
    	  try {
	    	  // Start internal Consumption Post Process directly - Process Internal Consumption
	    	  if (TimeFeedbackData.isWorstepStarted(this, GlobalWorkstepID).equals("N")) {
	              TimeFeedbackData.beginWorkstepNoMat(con,this, GlobalWorkstepID, PdcUserID, vars.getOrg());
	          }
	    	  String psnrbnr=getLocalSessionVariable(vars,"plannedserialorbatch");
	          if (!FormatUtils.isNix(psnrbnr))
	          	PdcCommonData.updateSnrBnr(con,this, psnrbnr, GlobalConsumptionID);
	          if (!FormatUtils.isNix(vars.getNumericParameter("inppdcproductionquantity")) && Float.parseFloat(DoProductionData.getOpenQTY(this, GlobalWorkstepID)) <
	        		  Float.parseFloat(vars.getNumericParameter("inppdcproductionquantity")))
	          {	
	        	  vars.setSessionValue("PDCSTATUS","ERROR");
	        	  vars.setSessionValue("PDCSTATUSTEXT","Menge > möglicher Menge");
	          } else {
		          //ProcessUtils.startProcessDirectly(GlobalConsumptionID, "800131", vars, this); 
	        	  PdcCommonData.doConsumptionPost(con,this,GlobalConsumptionID);
	        	  String msgtext=UtilsData.getProcessResultWC(con,this, GlobalConsumptionID);
    			  if (msgtext.startsWith("ERROR")) 
    				  throw new ServletException(msgtext.replaceFirst("ERROR@", ""));
    			  else {
			    	  String ptrxID=commons.prepareProduction(vars,null,GlobalWorkstepID,null,PdcUserID,getLocalSessionVariable(vars, ProductIDADName),vars.getSessionValue("pdcLocatorID"),this,con);
			    	  if (!FormatUtils.isNix(ptrxID)) {
			    		  vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
			    		  String rejectmsg="";
			    		  if (vars.commandIn("REJECT"))
			    			  rejectmsg=PdcCommonData.doRejection(con, this, ptrxID, vars.getLanguage());
			    		  commons.finishProduction(response, ptrxID,GlobalWorkstepID, BcCommand,PdcUserID,vars,this,con);
			    		  strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
			    		  if (!rejectmsg.isEmpty())
			    			  vars.setSessionValue("PDCSTATUSTEXT",rejectmsg);
			    	  } 
		          }
	          }
	          if (vars.getSessionValue("PDCSTATUS").equals("ERROR"))
	        	  con.rollback();
	          else
	        	  con.commit();
	    	  con.close();
	    	  // Autoprint bei vordef. SNR/CNR
	    	  if (!FormatUtils.isNix(psnrbnr) && !vars.getSessionValue("PDCSTATUS").equals("ERROR") && PdcCommonData.isConsumptionAutoprint(this, GlobalWorkstepID).equals("Y"))
	    		  vars.setSessionValue("AUTOPRINTASSEMBLYINPDC", "Y");
	      } catch (Exception e) { 
	    	  con.rollback();
	    	  try {con.close();}catch (Exception ign) {}
	    	  e.printStackTrace();
	    	  throw (e);
      }
      }
      if (vars.commandIn("NEXT")||BcCommand.equals("NEXT")) {
    	  
    	  commons.InternalConsumptionNext(GlobalWorkstepID, PdcUserID, strpdcFormerDialogue,
                  GlobalLocatorID,snrbnr,WorkstepIDADName,QuantityADName,getLocalSessionVariable(vars, ProductIDADName), vars,response ,this);
    	  GlobalConsumptionID=vars.getSessionValue("pdcConsumptionID");
      }
      
      if (vars.commandIn("DONE")||BcCommand.equals("DONE")) {
          if(PdcMaterialConsumptionData.getPdconlyreceivecomplete(this, vars.getOrg()).equals("Y")) {
              // es dürfen nur genau die Materialien für die eingebene zu produzierende Menge entnommen werden
              // upper grid ist nicht leer -> zu wenig entnommen
              upperGridData = PdcMaterialConsumptionData.selectupper(this, vars.getLanguage(),getLocalSessionVariable(vars, "pdcproductionquantity"),vars.getSessionValue("pdcAssemblySerialOrBatchNO"),GlobalConsumptionID, getLocalSessionVariable(vars, WorkstepIDADName));
              if(upperGridData.length > 0) {
                  throw new ServletException(Utility.messageBD(this, "pdc_consumtionCompleteError" ,vars.getLanguage()));
              }
              lowerGridData = PdcMaterialConsumptionData.selectlower(this, vars.getLanguage(),GlobalConsumptionID);
              for(FieldProvider fp : lowerGridData) {
                  // entnommene Menge != zu produzierende Menge * Menge an Materialien für einen Artikel -> zu viel entnommen
                  if(Float.parseFloat(fp.getField("pdcmaterialconsumptionreceivedqty")) != (Float.parseFloat(getLocalSessionVariable(vars,"pdcproductionquantity")) * Float.parseFloat(PdcMaterialConsumptionData.getQtyForOne(this, GlobalWorkstepID, fp.getField("m_product_id"))))) {
                      throw new ServletException(Utility.messageBD(this, "pdc_consumtionCompleteError" ,vars.getLanguage()));
                  }
              }
          }
		  if (qtySerOK(vars,GlobalWorkstepID)) {
			  commons.setInternalConsumptionDone(GlobalConsumptionID,GlobalWorkstepID, PdcUserID,strpdcFormerDialogue,"/org.openz.pdc.ad_forms/PdcMaterialConsumption.html",vars, response ,this);
			  // Autoprint bei vordef. SNR/CNR
	    	  if (!FormatUtils.isNix(getLocalSessionVariable(vars,"plannedserialorbatch")) && 
	    			  !vars.getSessionValue("PDCSTATUS").equals("ERROR") && 
	    			  PdcCommonData.isConsumptionAutoprint(this, GlobalWorkstepID).equals("Y"))
	    		  vars.setSessionValue("AUTOPRINTASSEMBLYINPDC", "Y");
		  }
      }
      
      if (vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")) {
        PdcCommonData.deleteAllMaterialLines( this, GlobalConsumptionID);
        PdcCommonData.deleteMaterialTransaction( this, GlobalConsumptionID);
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
        deleteLocalSessionVariable(vars,ProductIDADName);
        deleteLocalSessionVariable(vars,QuantityADName);
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
      String InfobarPrefix = "<span style=\"font-size: 20pt; color: #000000;\">" + Utility.messageBD(this, "pdc_Consumption",vars.getLanguage()) + "<br />";
      String InfobarText = "";
      String InfobarSuffix = "</span>";
      String Infobar = "";
      
      if (PdcUserID.isEmpty()) {
        InfobarText = Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage());
      }else if (getLocalSessionVariable(vars, WorkstepIDADName) == "") {
        InfobarText = Utility.messageBD(this, "pdc_ScanWorkstep",vars.getLanguage());
      }else if(PdcMaterialConsumptionData.countupper(this,GlobalConsumptionID,GlobalWorkstepID) != null && !PdcMaterialConsumptionData.countupper(this,GlobalConsumptionID,GlobalWorkstepID).isEmpty()) {
    	  if (GlobalLocatorID.isEmpty()) 
          	InfobarText = Utility.messageBD(this, "pdc_ScanLocator",vars.getLanguage());
    	  else
    		InfobarText = Utility.messageBD(this, "pdc_ScanProduct",vars.getLanguage());
      } else if (PdcMaterialConsumptionData.countlower(this,GlobalConsumptionID) != null && !PdcMaterialConsumptionData.countlower(this,GlobalConsumptionID).isEmpty())
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
      if (!PdcUserID.isEmpty())
    	  Infobar2 =Infobar2 +Utility.messageBD(this, "zssm_barcode_entity_employee",vars.getLanguage()) +": " + PdcCommonData.getEmployee(this, PdcUserID);
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
      // Simplified Production
      if (!GlobalWorkstepID.isEmpty()) {
    	  String test=PdcCommonData.isWorkstepSimplyfied(this, GlobalWorkstepID,GlobalConsumptionID);
    	  if (test!=null && !test.equals("N")) {
    		  vars.setSessionValue("pdcAssemblySimplyfied","Y");
    		  setLocalSessionVariable(vars, "pdcproductionquantity", test);
    		  // Ausschuss
    		  if (PdcCommonData.isTestingWorkstep(this, GlobalWorkstepID).equals("Y"))
    			  vars.setSessionValue("pdcIsTestingWorkstep","Y");
    	  } else {
    		  vars.setSessionValue("pdcAssemblySimplyfied","N");
    		  vars.setSessionValue("pdcIsTestingWorkstep","N");
    	  }
      }
      //vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
      
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      // Load grid structure
      EditableGrid uppergrid = new EditableGrid("PdcMaterialConsumptionUpperGrid", vars, this);  // Load upper grid structure from AD (use AD name)
      upperGridData = PdcMaterialConsumptionData.selectupper(this, vars.getLanguage(),getLocalSessionVariable(vars, "pdcproductionquantity"),vars.getSessionValue("pdcAssemblySerialOrBatchNO"),GlobalConsumptionID, getLocalSessionVariable(vars, WorkstepIDADName));   // Load upper grid date with language for translation
      strUpperGrid = uppergrid.printGrid(this, vars, script, upperGridData);                    // Generate upper grid html code
      
      
      EditableGrid lowergrid = new EditableGrid("PdcMaterialConsumptionLowerGrid", vars, this);  // Load lower grid structure from AD (use AD name)
      lowerGridData = PdcMaterialConsumptionData.selectlower(this, vars.getLanguage(),GlobalConsumptionID);
      //lowerGridData = PdcMaterialReturnData.selectlower(this, vars.getLanguage(),GlobalConsumptionID);
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      // Generate servlet skeleton html code
      strToolbar="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID",strToolbar, "Material Consumption", "", "REMOVED", null,"true");   // Generate skeleton
      if (comingserial.equals("Y")) {
    	  InfobarText = Utility.messageBD(this, "pdc_ScanProductCompleted",vars.getLanguage()); 
      	  comingserial="";
      };      
      // Prevent Softkeys on Mobile Devices
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
      
      // Generate servlet elements html code
      strPdcInfobar = ConfigureInfobar.doConfigure2Rows(this, vars, script, Infobar, Infobar2);                    // Generate infobar html code
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, "PdcMaterialConsumptionHeader", null, false);        // Generate header html code
      strButtonsFG = fh.prepareFieldgroup(this, vars, script, "PdcMaterialConsumptionButtons", null, false);       // Generate buttons html code
   // Settings for dummy focus...
      strButtonsFG=MobileHelper.addDummyFocus(strButtonsFG);
      strStatusFG = PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, "PdcStatusFG", null, false);        // Generate status html code
          
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

  private void setQtsSer(String workstepID,VariablesSecureApp vars) throws ServletException {
	  String prodId=PdcCommonData.getProductFromWorkstep(this, workstepID);
	  if (prodId!=null && PdcCommonData.isserialtracking(this, prodId).equals("Y") && UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y")) {
		  setLocalSessionVariable(vars, "pdcproductionquantity", "1");
		  vars.setSessionValue("QTYROPROD", "Y");
	  } else {
	      // dont set production quantity when produce continouosly is checked
	      if(PdcMaterialConsumptionData.getProduceContinuously(this, workstepID).equals("Y")) {
	          setLocalSessionVariable(vars, "pdcproductionquantity", "");
	      }else {
	          setLocalSessionVariable(vars, "pdcproductionquantity", PdcCommonData.getQtyLeftFromWorkstep(this, workstepID));
	      }
		  vars.setSessionValue("QTYROPROD", "N");
	  }
	  if (prodId!=null && PdcCommonData.isSerialOrBatch(this,  prodId).equals("Y"))
		  vars.setSessionValue("ISSNRBNR","Y");
  }
  
private Boolean qtySerOK (VariablesSecureApp vars,String workstepID)  throws ServletException {
	if (UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y") && getLocalSessionVariable(vars,"plannedserialorbatch").isEmpty() && 
			vars.getSessionValue("ISSNRBNR").equals("Y") && DoProductionData.isMovingWorkstep(this, workstepID).equals("N")) {
		  vars.setSessionValue("PDCSTATUS","ERROR");
		  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_PlannedSerialNumberNecessary",vars.getLanguage()));
		  return false;
	} else if (UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y") && !getLocalSessionVariable(vars,"plannedserialorbatch").isEmpty() && 
			vars.getSessionValue("ISSNRBNR").equals("Y") && DoProductionData.isMovingWorkstep(this, workstepID).equals("N")) {
		if (PdcMaterialConsumptionData.isPlannedSerialInThisWorkstepOK(this,workstepID,getLocalSessionVariable(vars,"plannedserialorbatch")).equals("OK"))
			return true;
		else
			throw new ServletException(Utility.messageBD(this, "pdc_plannedsnrotherworkstep" ,vars.getLanguage())+ PdcMaterialConsumptionData.isPlannedSerialInThisWorkstepOK(this,workstepID,getLocalSessionVariable(vars,"plannedserialorbatch")));
	} else
		return true;
}

  
  
  
  public String getServletInfo() {
    return this.getClass().getName();
  }
  

}

