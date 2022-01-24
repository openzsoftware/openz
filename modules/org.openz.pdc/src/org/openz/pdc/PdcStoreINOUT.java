

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

public class PdcStoreINOUT extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  String Complete="";
  String Current="";
  Integer CompleteTrx=0;
  Integer CurrentTrx=0;
  Connection conn=null;
  
  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);      
    try {
      conn=this.getConnection();
      
      String usecase="SERIAL";  // Mode of Scan (FULL means Full Scan, SERIAL only Batch and Serials)
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
     
      //setting History
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/ad_forms/PdcStoreConsumptionAndReturn.html"))){
      	vars.setSessionValue("PDCFORMERDIALOGUE","/ad_forms/PDCStoreMainDialoge.html");
      	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }
              
      
      
      String BcCommand = "";
      
      // Business logic / Usecase
       if (vars.commandIn("DEFAULTDELIVER")||vars.commandIn("DEFAULTRECEIPT")||vars.commandIn("DEFAULT")) {
    	deleteLocalSessionVariable(vars, "pdcinouttrx");
    	// Load USECASE 
    	if (vars.commandIn("DEFAULTDELIVER"))
    	   setLocalSessionVariable(vars, "pdcdirection","C-");
    	if (vars.commandIn("DEFAULTRECEIPT"))
    	   setLocalSessionVariable(vars, "pdcdirection","V+");
    	if (UtilsData.getOrgConfigOption(this, "PDCINOUTFULLSCAN", vars.getOrg()).equals("Y"))
    			usecase="FULL";	
      }
      // Loading global session variables
      String GlobalUserID = vars.getUser();
      String GlobalLocatorID = vars.getSessionValue("pdcLocatorID");
      String GlobalINOUTID = getLocalSessionVariable(vars,"pdcinouttrx");
      if (vars.commandIn("SAVE_NEW_NEW")) {
    	  String barcode=vars.getStringParameter("inppdcbarcode");
    	  // REad Barcode
    	  PdcMaterialConsumptionData[] data = PdcMaterialConsumptionData.selectbarcode(this, barcode);
          // In this Servlet CONTROL, EMPLOYEE or PRODUCT or CALCULATION, LOCATOR, WORKSTEP can be scanned,
          // The First found will be used...
          String bctype="UNKNOWN";
          String bcid="";
          for (int i=0;i<data.length;i++){
            if (data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("PRODUCT")||data[i].type.equals("CALCULATION")||data[i].type.equals("LOCATOR")||data[i].type.equals("WORKSTEP")||data[i].type.equals("KOMBI")||data[i].type.equals("SERIALNUMBER")||data[i].type.equals("BATCHNUMBER")) {
              bcid=data[i].id;  
              bctype=data[i].type;
              break;
            }             
          }      
          // Get/Set TRX
    	  if (getLocalSessionVariable(vars, "pdcinouttrx").isEmpty()) {
    		  String dscr=vars.getStringParameter("inppdcinouttrx");
    		  if (dscr.isEmpty()) {
    			  vars.setSessionValue("PDCSTATUS","ERROR");
    			  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_settrxfirst",vars.getLanguage()));
    			  bctype="ERROR";
    		  } else {
    			  setLocalSessionVariable(vars, "pdcinouttrx",dscr);
    			  GlobalINOUTID=dscr;
    		  }
    	  }
          //Time Feedback mot applicable
          if (bctype.equals("EMPLOYEE")||bcid.equals("872C3C326AB64D1EBABDD49A1E138136")){
        	  vars.setSessionValue("PDCSTATUS","WARNING");
        	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"\r\n"+barcode);       
              
          } else if (bctype.equals("LOCATOR") && usecase.equals("FULL")) {
              setLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid", bcid);
              GlobalLocatorID=  bcid;   
              vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);
          } else if (bctype.equals("PRODUCT")&&! getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty()  && usecase.equals("FULL")) {
        	  String qty=vars.getNumericParameter("inppdcquantity");
              if (qty.isEmpty())
                qty="1";
              // Increment an multpl. scan on same Product
              String tt=getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid");
              if (getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").equals(bcid)&&!getLocalSessionVariable(vars, "quantity").isEmpty()&&vars.getNumericParameter("inppdcquantity").isEmpty()) {
            		Integer qu=Integer.parseInt(getLocalSessionVariable(vars, "quantity")) +  1;
            		qty=qu.toString();
              }
              setLocalSessionVariable(vars, "quantity",qty);  
              setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", bcid);
            BcCommand = "NEXT";
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);          
          } else if (bctype.equals("KOMBI")) {
        	  String[] kombi=barcode.split("\\|");
              setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", kombi[0]);
              setLocalSessionVariable(vars, "pdcmaterialconsumptionserial", kombi[1]);
              String qty=vars.getNumericParameter("inppdcquantity");
              if (qty.isEmpty())
                qty="1";
              setLocalSessionVariable(vars, "quantity",qty);
              if (usecase.equals("FULL")&&! getLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid").isEmpty())
            	  BcCommand = "KOMBINEXT";
              else
            	  BcCommand = "SERIALBATCH";
              vars.setSessionValue("PDCSTATUS","OK");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);          
          } else if (bctype.equals("WORKSTEP")) {
        	  vars.setSessionValue("PDCSTATUS","WARNING");
        	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"\r\n"+barcode);           
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
          else if ((bctype.equals("UNKNOWN")||bctype.equals("SERIALNUMBER")||bctype.equals("BATCHNUMBER")) && usecase.equals("SERIAL") && !barcode.isEmpty()) {
        	  if (getLocalSessionVariable(vars, "pdcdirection").equals("C-")&&bctype.equals("UNKNOWN")) {
        		  vars.setSessionValue("PDCSTATUS","ERROR");
        		  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode);
        	  } else {
        		  // Use Case ONLY Serial and Batch Scan
        		  BcCommand = "SERIALBATCH";
        		  setLocalSessionVariable(vars, "pdcmaterialconsumptionserial", barcode);
        		  String qty=vars.getNumericParameter("inppdcquantity");
                  if (qty.isEmpty())
                    qty="1";
                  setLocalSessionVariable(vars, "quantity",qty);  
        	  }
          }
          else if (bctype.equals("UNKNOWN")&& !barcode.isEmpty()) {
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode);
            
          } 
      }
 
      if (vars.commandIn("NEXT")||BcCommand.equals("NEXT")||BcCommand.equals("KOMBINEXT")||BcCommand.equals("SERIALBATCH")) {
        
              if (usecase.equals("SERIAL")) {
            	  PdcINOUTData[] data=PdcINOUTData.select(this, vars.getLanguage(),GlobalINOUTID,usecase );
            	  if (data[0].todos.equals("READY")) {
            		  vars.setSessionValue("PDCSTATUS","OK");
                      vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NothingToDo",vars.getLanguage())); 
            	  } else {
	            	  String product=data[0].mProductId;
	            	  String lineUuid=data[0].mInoutlineId;
	            	  String type=SerialNumberData.pdc_getSerialBatchType4product(this, product);
	            	  String qty;
	            	  String bnr="";
	            	  String snr="";
	            	  if (type.equals("SERIAL")) {
	            		  qty="1";
	            		  snr=getLocalSessionVariable(vars, "pdcmaterialconsumptionserial");
	            	  } else {
	            		  qty=getLocalSessionVariable(vars, "quantity");
	            		  bnr=getLocalSessionVariable(vars, "pdcmaterialconsumptionserial");
	            	  }
	            	  SerialNumberData.insertSerialLineInOut(this,vars.getClient(), vars.getOrg(), vars.getUser(), 
	            			  lineUuid, qty, bnr, snr);
	            	  vars.setSessionValue("PDCSTATUS","OK");
	                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ProductScannedCorrectly",vars.getLanguage())); 
            	  }
              }
      }
      
      if (vars.commandIn("DONE")||BcCommand.equals("DONE")) {
          OBError mymess=null;
          boolean iserror=false;
          String msgtext="\n";
          if (!GlobalINOUTID.equals("")) {
            // Start internal Consumption Post Process directly - Process Internal Consumption
            ProcessUtils.startProcessDirectly(GlobalINOUTID, "109", vars, this); 
            // PdcCommonData.doConsumptionPost(this, strConsumptionid);
            vars.setSessionValue("PDCSTATUS","OK");
            if (getLocalSessionVariable(vars, "pdcdirection").equals("C-"))
            	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_deliverysucessful",vars.getLanguage())+msgtext);
            else //V+
            	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_receiptsucessful",vars.getLanguage())+msgtext);
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
            response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
      }
      
      if (vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")) {
    	if (usecase.equals("SERIAL")) 
    		SerialNumberData.deleteInOUt(conn, this, GlobalINOUTID);
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
        deleteLocalSessionVariable(vars, "pdcmaterialconsumptionlocatorid");
        deleteLocalSessionVariable(vars, "pdcmaterialconsumptionproductid");
        deleteLocalSessionVariable(vars, "pdcmaterialconsumptiondescription");
        deleteLocalSessionVariable(vars, "pdcinouttrx");
        response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
      }
      // Start Building GUI
      EditableGrid lowergrid;
      lowergrid = new EditableGrid("PdcINOUTGridMobile", vars, this);  // Load lower grid structure from AD (use AD name)
      lowerGridData = PdcINOUTData.select(this, vars.getLanguage(),GlobalINOUTID,usecase);
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      // Initialize Infobar helper variables
      String InfobarPrefix = "<span style=\"font-size: 20pt; color: #000000;\">";
      String InfobarText="";
      if (getLocalSessionVariable(vars, "pdcdirection").equals("C-"))
      	  InfobarText = Utility.messageBD(this, "pdc_Customer",vars.getLanguage()) + "<br />";
      else
    	  InfobarText = Utility.messageBD(this, "pdc_vendor",vars.getLanguage()) + "<br />";
      String InfobarSuffix = "</span>";
      String Infobar = "";
      String Infobar2 = "<span style=\"font-size: 12pt; color: #000000;\">";
      // Get InfoBar Text
      if (!GlobalINOUTID.isEmpty() && (lowerGridData.length==0 || lowerGridData[0].getField("todos").equals("READY")))
    	  InfobarText = InfobarText + Utility.messageBD(this, "pdc_ScanComplete",vars.getLanguage());
      else
	      if (GlobalINOUTID.isEmpty())   
	        InfobarText = InfobarText + Utility.messageBD(this, "pdc_settrxfirst",vars.getLanguage());
	      else
	    	InfobarText = InfobarText + Utility.messageBD(this, "pdc_ScanSerialorBatchStore",vars.getLanguage());
      // Generate Infobar
      Infobar = InfobarPrefix + InfobarText + InfobarSuffix;
      //strPdcInfobar = fh.prepareInfobar(this, vars, script, Infobar, "");                       // Generate infobar html code
      strPdcInfobar = ConfigureInfobar.doConfigure2Rows(this, vars, script, Infobar, "");   
   
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      
      // GUI Settings Responsive for Mobile Devises
      // Prevent Softkeys on Mobile Devices (Field is Readonly and programmatically set). Field dummyfocusfield must exist (see MobileHelper.addDummyFocus)
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcbarcode\").focus();fieldReadonlySettings('pdcbarcode', false);},50);");
      script.addHiddenfieldWithID("forcefocusfield", "pdcbarcode"); // Force Focus after Numpad to given Field
      // Set Session Value for Mobiles (Android Systems) - Effect is that the new Numpad is loaded
      if (MobileHelper.isMobile(request))
    	  vars.setSessionValue("#ISMOBILE", "TRUE");
      else
    	  vars.removeSessionValue("#ISMOBILE");
      //ON Mobiles: Smartphone, Use Zoom
      int xi=Integer.parseInt(vars.getSessionValue("#ScreenX"));
      int yi=Integer.parseInt(vars.getSessionValue("#ScreenY"));
      if (yi>xi)
      	script.addOnload("document.body.style.zoom = \"200%\";");
      // Generate servlet skeleton html code
      strQuit="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID",strQuit, "VendorCustomerMovements", "", "REMOVED", null,"true");   // Generate skeleton
      // Generate Header FG
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, "PdcMINOUTHeader", null, false);        // Generate header html code
      strHeaderFG=Replace.replace(strHeaderFG,"id=\"pdcbarcode\" title=\"\" readonly=\"true\" onfocus=\"isGridFocused = false;\" onkeydown=\"changeToEditingMode('onkeydown');\"","id=\"pdcbarcode\" title=\"\" readonly=\"true\" onfocus=\"isGridFocused = false;\" onkeydown=\"crAction(event);\"");
      // Settings for dummy focus...
      strHeaderFG=MobileHelper.addDummyFocus(strHeaderFG);

      strStatusFG = PdcStatusBar.getStatusBar(this, vars, script);       // Generate status html code
          
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
    }  finally{
      try{
      conn.close();
    }catch (Exception ignor) { }}
 }

  public String getServletInfo() {
    return this.getClass().getName();
  }
  
  
}

