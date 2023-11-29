/*__________| PDC - Inventory |_________________________________________________
 * The contents of this file are subject to the Mozilla Public License Version 1.1
 * Copyright:           OpenZ Software GmbH
 * Author:              stefan.zimmermann@OpenZ.de          (2022)
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
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessRunner;
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

public class PdcStoreInventory extends HttpSecureAppServlet {
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

      // Initialize fieldproviders - they provide data for the grids
      FieldProvider[] lowerGridData;    // Data for the lower grid
   
      // Loading global session variables
      String GlobalLocatorID = vars.getSessionValue("pdcLocatorID");
      String GlobalInventoryID = vars.getSessionValue("pdcInventoryID");
      // Globals for this class
      String weight="";
      String qty="";
      String productId="";
      String serialNo="";
      String BatchNo="";
   try {
      //setting History
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/ad_forms/PdcStoreInventory.html"))){
      	vars.setSessionValue("PDCFORMERDIALOGUE","/ad_forms/PDCStoreMainDialoge.html");
      	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }
      String BcCommand = "";
      // Buttons
      if (vars.commandIn("DONE"))
    	  BcCommand = "DONE"; 
      if (vars.commandIn("CANCEL"))
    	  BcCommand = "CANCEL"; 
    	  
      // Read Barcode
      if (vars.commandIn("SAVE_NEW_NEW")) {
    	  // Read Description Field
    	  String dscr=vars.getStringParameter("inppdcmaterialconsumptiondescription");
    	  setLocalSessionVariable(vars, "pdcmaterialconsumptiondescription",dscr);  
    	  // REad Barcode
    	  PdcCommonData bar=PdcCommons.getBarcode(this, vars);
    	  String bctype=bar.type;
    	  String bcid=bar.id;
    	  String barcode=bar.barcode;
    	  if (vars.getSessionValue("P|KOMBIBARCODEMANDATORY").equals("Y") && (
    			  bctype.equals("PRODUCT")||bctype.equals("UNKNOWN")||bctype.equals("BATCHNUMBER")||bctype.equals("SERIALNUMBER")))
    	  {
    		  if (bctype.equals("UNKNOWN"))
    			  throw new Exception(Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+barcode);
    		  else
    			  throw new Exception(Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+barcode);
    	  }    			  
    	  // Default: MSG: Sucessful
    	  vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);
          if (GlobalLocatorID.isEmpty() && (bctype.equals("PRODUCT")||bctype.equals("KOMBI"))) {
        	  vars.setSessionValue("PDCSTATUS","WARNING");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanLocatorIC",vars.getLanguage()));
          }
          //Time Feedback mot applicable
          if (bctype.equals("EMPLOYEE")||bcid.equals("872C3C326AB64D1EBABDD49A1E138136")||bctype.equals("WORKSTEP")){
        	  vars.setSessionValue("PDCSTATUS","WARNING");
        	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"\r\n"+barcode);                    
          } else if (bctype.equals("LOCATOR")) {
        	  if (vars.getSessionValue("pdcLocatorID").isEmpty()) {        		 
        		  vars.setSessionValue("pdcLocatorID",bcid);
	              GlobalLocatorID=  bcid;  
	              BcCommand = "INIT"; 
        	  }else {
        		  vars.setSessionValue("PDCSTATUS","WARNING");
            	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "cannotchangelocator",vars.getLanguage())+"\r\n"+barcode);    
        	  }
          } else if (bctype.equals("PRODUCT")&& ! GlobalLocatorID.isEmpty()) {
        	productId=bcid;
        	qty=bar.qty;
        	if (qty.isEmpty())
                qty="1";              
              if (!qty.equals("0") && !SerialNumberData.pdc_getSerialBatchType4product(this, bcid).equals("NONE"))
            	  qty="1";
        	// Serial
            if (PdcCommonData.isSerialOrBatch(this, productId).equals("Y"))
              setLocalSessionVariable(vars, "pdcinventoryproductid", bcid);
            else {
            	BcCommand = "NEXT";
            	deleteLocalSessionVariable(vars, "pdcinventoryproductid");
            }
          } else if (bctype.equals("KOMBI")&& ! GlobalLocatorID.isEmpty()) {
        	productId=bcid;
          	qty=bar.qty;
          	weight=bar.weight;
          	serialNo=bar.serialnumber;
          	BatchNo=bar.lotnumber;
            BcCommand = "KOMBINEXT";  
            if (vars.getSessionValue("P|WEIGHTMANDATORY").equals("Y") && FormatUtils.isNix(weight))
      		  throw new Exception(Utility.messageBD(this, "Gewicht fehlt.",vars.getLanguage()));
            if (PdcCommonData.isSerialOrBatch(this, productId).equals("Y"))
                setLocalSessionVariable(vars, "pdcinventoryproductid", bcid);
              else 
              	deleteLocalSessionVariable(vars, "pdcinventoryproductid");
          } else if (bctype.equals("CONTROL")) {
            if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC"))
              BcCommand = "CANCEL";
            else if (bcid.equals("B28DAF284EA249C48F932C98F211F257"))
              BcCommand = "DONE";
            else {
              vars.setSessionValue("PDCSTATUS", "WARNING");
              vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage()));
            }
          }          
          else if (bctype.equals("UNKNOWN")) {
        	if (!getLocalSessionVariable(vars, "pdcinventoryproductid").equals("")
        			&& !SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcinventoryproductid")).equals("NONE")
        			&& !SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcinventoryproductid")).equals("BOTH")
        			&& !barcode.contains("|")) // Nur bei passendem Artikel neue BNR/CNR aufnehmen
        	{
        		vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_newBnrSnrAssigned", vars.getLanguage()));
        		if (SerialNumberData.pdc_getSerialBatchType4product(this, getLocalSessionVariable(vars, "pdcinventoryproductid")).equals("SERIAL"))
        			bctype="SERIALNUMBER";
        		else // Batch
        			bctype="BATCHNUMBER";
        	} else {
        		vars.setSessionValue("PDCSTATUS","ERROR");
        		vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode);
        	}
          } 
          if (bctype.equals("BATCHNUMBER")) {
        	  productId=getLocalSessionVariable(vars, "pdcinventoryproductid"); 
        	  if (productId.isEmpty()) {
        		  vars.setSessionValue("PDCSTATUS", "WARNING");
                  vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage()));
        	  } else {
	        	  BatchNo=barcode;
	        	  qty=bar.qty;
	          	  if (qty.isEmpty())
	                  qty="1";    
	          	  BcCommand = "NEXT";
        	  }
          }
          if (bctype.equals("SERIALNUMBER")) {
        	  productId=getLocalSessionVariable(vars, "pdcinventoryproductid"); 
        	  if (productId.isEmpty()) {
        		  vars.setSessionValue("PDCSTATUS", "WARNING");
                  vars.setSessionValue("PDCSTATUSTEXT", Utility.messageBD(this, "pdc_bcnotapplicable", vars.getLanguage()));
        	  } else {
	        	  serialNo=barcode;
	        	  qty=bar.qty;
	          	  if (!qty.equals("0"))
	                  qty="1";     
	          	  BcCommand = "NEXT";
        	  }
          }
      }
      if (BcCommand.equals("INIT")) {
    	  deleteLocalSessionVariable(vars, "pdcinventoryproductid");
    	  if (!FormatUtils.isNix(PdcStoreInventoryData.runningInventory(this, GlobalLocatorID,vars.getUser()))) {
    		  GlobalInventoryID = PdcStoreInventoryData.runningInventory(this, GlobalLocatorID,vars.getUser());
    		  vars.setSessionValue("pdcInventoryID", GlobalInventoryID);
    		  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_inventorycontinue",vars.getLanguage()));
    	  } else {
    		  // No other Inventory Running?
    		  if (!PdcCommonData.inventoryRunning(this, GlobalLocatorID).equals("0"))
            	  throw new Exception(Utility.messageBD(this, "RunningInventory",vars.getLanguage()));
	          //INVENTORY Trx erstellen 
	    	  GlobalInventoryID = PdcStoreInventoryData.init(this, GlobalLocatorID, vars.getUser(), vars.getOrg());
	          vars.setSessionValue("pdcInventoryID", GlobalInventoryID);
	          String pinstance = SequenceIdData.getUUID();
	          PInstanceProcessData.insertPInstance(this, pinstance, "105", GlobalInventoryID, "N", vars.getUser(), vars.getClient(), vars.getOrg());
	          PInstanceProcessData.insertPInstanceParam(this, pinstance, "5", "M_Locator_ID", GlobalLocatorID, vars.getClient(), vars.getOrg(), vars.getUser());
	          PInstanceProcessData.insertPInstanceParam(this, pinstance, "30", "regularization", "N", vars.getClient(), vars.getOrg(), vars.getUser());
	          ProcessBundle bundle = ProcessBundle.pinstance(pinstance, vars, this);
	          new ProcessRunner(bundle).execute(this);
	          PInstanceProcessData[] pinstanceData = PInstanceProcessData.select(this, pinstance);
	          OBError mymess = Utility.getProcessInstanceMessage(this, vars, pinstanceData);
	          //mymess=vars.getMessage(getServletInfo());
	          vars.removeMessage(getServletInfo());
	          if (mymess!=null) {
	            if (mymess.getType().equals("Error")) {
	              vars.setSessionValue("PDCSTATUS","ERROR");
	              vars.setSessionValue("PDCSTATUSTEXT",mymess.getMessage());
	            }
	          }
	          PdcStoreInventoryData.updateoninit(this, GlobalInventoryID, vars.getUser());
    	  }
      }
      if (BcCommand.equals("NEXT")||BcCommand.equals("KOMBINEXT")) {
        if (GlobalLocatorID.isEmpty()){         
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MustSetProductQtyAndLocator",vars.getLanguage()));
        } else { 
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ProductScannedCorrectly",vars.getLanguage()));
          if (Float.parseFloat(qty)>1 && Float.parseFloat(PdcStoreInventoryData.getQtyCount(this, BatchNo, GlobalInventoryID, productId, GlobalLocatorID))>0 )
        	  throw new Exception(Utility.messageBD(this, "ProductIsCounted",vars.getLanguage()));
          PdcStoreInventoryData.updateline(this, GlobalInventoryID, GlobalLocatorID,productId, qty);
          PdcStoreInventoryData.lineSNRBNRUpdate(this, GlobalInventoryID, productId, qty, weight, serialNo, BatchNo);
        }
      }
      
      if (BcCommand.equals("DONE")) {
          OBError mymess=null;
          boolean iserror=false;
          String msgtext="\n";
          if (!GlobalInventoryID.equals("")) {       	
            // Start Inventory Post Process directly 
            ProcessUtils.startProcessDirectly(GlobalInventoryID, "107", vars, this); 
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_InventorySucessful",vars.getLanguage())+msgtext);
            mymess=vars.getMessage(getServletInfo());
            vars.removeMessage(getServletInfo());
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
          if (! iserror) {
        	  vars.removeSessionValue("pdcLocatorID");
              vars.removeSessionValue("pdcInventoryID");
              response.sendRedirect(strDireccion + strpdcFormerDialogue);
              return;
          }
        
      }
      
      if (vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")) {
    	//DELETE TRX
    	PdcStoreInventoryData.delete(this, GlobalInventoryID);
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
        vars.removeSessionValue("pdcLocatorID");
        vars.removeSessionValue("pdcInventoryID");
        response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
        return;
      }
      if (vars.commandIn("PAUSE")) {      	
    	  vars.removeSessionValue("pdcLocatorID");
          vars.removeSessionValue("pdcInventoryID");
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_pause",vars.getLanguage()));        
          response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
          return;
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
      big1=	Utility.messageBD(this, "pdc_Inventory",vars.getLanguage());
      if (GlobalLocatorID.isEmpty())   
    	  big2=Utility.messageBD(this, "pdc_ScanLocatorIC",vars.getLanguage());
      else if (!getLocalSessionVariable(vars, "pdcinventoryproductid").isEmpty())
    	  big2=Utility.messageBD(this, "pdc_ScanSNRBNR",vars.getLanguage());
      else 
    	  big2=Utility.messageBD(this, "pdc_ScanProductIC",vars.getLanguage());
      if (!GlobalLocatorID.isEmpty())
    	  small1=Utility.messageBD(this, "pdcmaterialconsumptionlocator",vars.getLanguage()) +": " + PdcCommonData.getLocator(this, GlobalLocatorID)+PdcStoreInventoryData.getSumUp(this, vars.getLanguage(),GlobalInventoryID);
      if (!productId.isEmpty()) {
    	  small2=Utility.messageBD(this, "Product",vars.getLanguage())  +": " + PdcCommonData.getProduct(this, productId, vars.getLanguage());
    	  small3=InfoBarHelper.getSnrBnrStr(this, vars, serialNo, BatchNo, qty, weight);
      }	
      strPdcInfobar=InfoBarHelper.upperInfoBarApp(this, vars, script, big1, big2, small1, small2, small3); 
          
      // GUI Settings Responsive for Mobile Devises
      // Prevent Softkeys on Mobile Devices (Field is Readonly and programmatically set). Field dummyfocusfield must exist (see MobileHelper.addDummyFocus)
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
      script.addHiddenfieldWithID("forcefocusfield", "pdcmaterialconsumptionbarcode"); // Force Focus after Numpad to given Field
      EditableGrid lowergrid;
      // Set Session Value for Mobiles (Android Systems) - Effect is that the new Numpad is loaded
      // Upright Screen Zoomes200%
      if (MobileHelper.isMobile(request)) 
    	  MobileHelper.setMobileMode(request, vars, script);
      lowergrid = new EditableGrid("PdcInventoryGrid", vars, this);  // Load lower grid structure from AD (use AD name)
      lowerGridData = PdcStoreInventoryData.select(this, vars.getLanguage(),productId, GlobalInventoryID);
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      // Generate servlet skeleton html code
      strQuit="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID",strQuit, "Material Consumption", "", "REMOVED", null,"true");   // Generate skeleton                          
      
      // Generate servlet elements html code
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, "PdcInventoryHeader", null, false);        // Generate header html code
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

  public String getServletInfo() {
    return this.getClass().getName();
  }
  
  
}

