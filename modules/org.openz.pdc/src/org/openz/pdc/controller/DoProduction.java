package org.openz.pdc.controller;

import java.io.IOException;
import java.io.PrintWriter;


import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.utility.Utility;

import org.openbravo.utils.Replace;

import org.openz.view.Formhelper;

import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.pdc.PdcCommons;
import org.openz.util.FormatUtils;
import org.openz.util.UtilsData;




public class DoProduction  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;
    
   

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
    	    
    	    
      //Define AD field names, do NOT use capitals or special characters here
      final String BarcodeADName = "pdcmaterialconsumptionbarcode";
      final String WorkstepIDADName = "pdcmaterialconsumptionworkstepid";
      // Global vars
      String strpdcWorkstepID;
	  String strLocatorID="";
	  String bcCommand="";
	  String strProductionid;
	  String strpdcUserID;
	  String snrbnr=null; // Serial or Batch No
	  // Initialize Global Structues
      String strPdcInfobar=""; //Area for further Information of the Servlet
      Scripthelper script= new Scripthelper();
      //initialize the grids
      String strUpperGrid ="";
      String strLowerGrid ="";
      //initialize the Fieldgroups
      //Header Fieldgroup
      String strHeaderFG="";
      //Button Fieldgroup
      String strButtonsFG="";
      //Status Fieldgroup
      String strStatusFG="";
      //The Structure of the Servlet
      String strSkeleton="";
      //Html Output of the Servlet
      String strOutput ="" ;
      //Calling the Formhelper to create the Fieldgroups and Grids
      Formhelper fh=new Formhelper();
      //>Setting up the Fieldproviders - they provide Data for the Grids
      //The upper Grid
      FieldProvider[] upperGridData;
      //The lower grid
      FieldProvider[] lowerGridData;
      // Do the Business Logic HERE
      VariablesSecureApp vars = new VariablesSecureApp(request);
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");

      try{
        //Getting Session Values
        strProductionid=vars.getSessionValue("pdcProductionID");
        // Getting Form Fields
        strpdcWorkstepID=vars.getSessionValue("pdcWorkStepID");
        setLocalSessionVariable(vars, WorkstepIDADName,strpdcWorkstepID);
        strpdcUserID=vars.getSessionValue("pdcUserID");
        String strBarcode=vars.getStringParameter("inppdcmaterialconsumptionbarcode");
        // Commons
        PdcCommons commons = new PdcCommons();
        //setting History
        String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
        if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/DoProduction.html"))){
        	vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
        	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
        }
        // Look if we come from serial Number Tracking...
        String commandserial=vars.getSessionValue("PDCINVOKESERIAL");
        vars.removeSessionValue("PDCINVOKESERIAL");
        if (commandserial.isEmpty()) {
            setLocalSessionVariable(vars, "pdcproductionquantity", vars.getNumericParameter("inppdcproductionquantity"));
            setLocalSessionVariable(vars,"plannedserialorbatch", vars.getStringParameter("inpplannedserialorbatch"));
            if (!vars.getStringParameter("inpplannedserialorbatch").isEmpty())
          	  vars.setSessionValue("pdcAssemblySerialOrBatchNO",getLocalSessionVariable(vars,"plannedserialorbatch")); // If Input Changes, Propagate to global var
        }
        // Getting Workstep       
        if (!vars.getStringParameter("inp" + WorkstepIDADName).equals("")) {
  	      if (strpdcWorkstepID.isEmpty()||
  	  			(vars.getSessionValue("pdcProductionID").isEmpty()
  	  			 && !strpdcWorkstepID.equals(vars.getStringParameter("inp" + WorkstepIDADName)))) {// Workstep selected via dropdown
  	    	  setLocalSessionVariable(vars, WorkstepIDADName);
  	          strpdcWorkstepID = getLocalSessionVariable(vars, WorkstepIDADName);
  	          PdcCommons.setWorkstepVars(strpdcWorkstepID,null,null, vars,this);
  	  	  } 
        }
        
        
        if (vars.commandIn("SAVE_NEW_NEW")){
          if (!strBarcode.isEmpty()) {
        	 
            // Analyze Scanned Barcode..
            PdcCommonData[] data  = PdcCommonData.selectbarcode(this, strBarcode);
            // In this Servlet CONTROL, EMPLOYEE or PRODUCT or CALCULATION, LOCATOR, WORKSTEP can be scanned,
            // The First found will be used...
            String bctype="UNKNOWN";
            String bcid="";
            if (data.length>=1) {
                bcid=data[0].id;  
                bctype=data[0].type;
            }                     
            // The Function to Scan Serial and Batch Numbers direct was implemented later.
            // This Servlet does not use it and determins SERIAL and Batches in own querys.
            //TODO: Implement direct scan and determination of Serial and Batch (Will make Servlet more readable)               
            //Scannes a User
            if (bctype.equals("EMPLOYEE")){
              if (strProductionid.isEmpty()) {
                strpdcUserID=bcid;
                vars.setSessionValue("pdcUserID",strpdcUserID);
                vars.setSessionValue("PDCSTATUS","OK");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage()));
              } else {
                vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"-"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
              }
            }  else if (bctype.equals("LOCATOR")){
                strLocatorID=bcid;
                vars.setSessionValue("pdcLocatorID", strLocatorID);
                vars.setSessionValue("PDCSTATUS","OK");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage()));
            } else if (bctype.equals("WORKSTEP")||bctype.equals("KOMBI")||bctype.equals("PRODUCT")){
                if (strProductionid.isEmpty()) {
                  if (bctype.equals("KOMBI")) {
                		String[] kombi=vars.getStringParameter("inp" + BarcodeADName).split("\\|");  
                		snrbnr=kombi[1];
                		PdcCommons.setWorkstepVars(null,bcid,snrbnr, vars,this);
                		if (PdcCommonData.isserialtracking(this, bcid).equals("Y") && UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y")) {
                			  setLocalSessionVariable(vars, "pdcproductionquantity", "1");
                			  vars.setSessionValue("QTYROPROD", "Y");
                		}
                  }
                  if (bctype.equals("WORKSTEP"))
                	  strpdcWorkstepID=bcid;
                  else 
                	  strpdcWorkstepID=PdcCommonData.getWorkstepFromProduct(this, bcid);
                  if (FormatUtils.isNix(strpdcWorkstepID)) {
                	  vars.setSessionValue("PDCSTATUS","ERROR");
                      vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_noworkstepfound",vars.getLanguage())+"-"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
                  } else {
                	  if (FormatUtils.isNix(snrbnr))
                		  PdcCommons.setWorkstepVars(strpdcWorkstepID,null,null, vars,this);
	              	  setLocalSessionVariable(vars, WorkstepIDADName,strpdcWorkstepID);
	              	  commons.prepareProduction(vars,null,strpdcWorkstepID,strProductionid,strpdcUserID,null,vars.getSessionValue("pdcLocatorID"),this);
	              	  bcCommand="ALLPOSITIONS";
	              	  strProductionid=vars.getSessionValue("pdcProductionID");
	              	  vars.setSessionValue("PDCSTATUS","OK");
	                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage()));
                  }
                } else {
                  vars.setSessionValue("PDCSTATUS","ERROR");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage())+"-"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
                }
            } else if (bctype.equals("CONTROL")){// Scanned a Control Barcode
              if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC")) // Cancel
                bcCommand="CANCEL";           
              else if (bcid.equals("B28DAF284EA249C48F932C98F211F257")) // Ready (Finished)
                bcCommand="DONE";
              else if (bcid.equals("48AE377FD5224514A54E9AE666BE5CC7")) // Close Workstep
                bcCommand="CLOSEWS";
              else {
                vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage()));
              }
            } else if (bctype.equals("UNKNOWN")){
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
            } else {
            	  vars.setSessionValue("PDCSTATUS","ERROR");
                  vars.setSessionValue("PDCSTATUSTEXT",bctype+":"+Utility.messageBD(this, "ActionNotSupported",vars.getLanguage())+"-"+vars.getStringParameter("inp" + BarcodeADName));        
            }
          }
       if (bcCommand.isEmpty())
            bcCommand="DEFAULT";
       } else { // command not "SAVE_NEW_NEW
          if (vars.commandIn("DEFAULT")) {
            // Look if we come from serial Number Tracking...
            vars.removeSessionValue("PDCINVOKESERIAL");
          } 
          bcCommand=vars.getCommand();    
        }
        // Evaluate Command
        String InfobarText = "";
        Boolean loadDataOK=false;
        // Determin, if workstep and user is set.
        if (strpdcUserID.isEmpty()) 
            InfobarText = Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage());
        else if (FormatUtils.isNix(strpdcWorkstepID)) 
            InfobarText = Utility.messageBD(this, "pdc_ScanWorkstep",vars.getLanguage());
        else
          loadDataOK=true;
        if (bcCommand.equals("CANCEL")){
            PdcCommonData.deleteAllMaterialLines( this, strProductionid);
            PdcCommonData.deleteMaterialTransaction( this, strProductionid);
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
            response.sendRedirect(strDireccion + strpdcFormerDialogue);
          }
          if (bcCommand.equals("CLOSEWS")||bcCommand.equals("DONE")){
        	if (UtilsData.getOrgConfigOption(this, "serialbomstrict", vars.getOrg()).equals("Y") && getLocalSessionVariable(vars,"plannedserialorbatch").isEmpty() && vars.getSessionValue("ISSNRBNR").equals("Y")) {
    			  vars.setSessionValue("PDCSTATUS","ERROR");
    			  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_PlannedSerialNumberNecessary",vars.getLanguage()));
        	} else
          	commons.finishProduction(response,strProductionid,strpdcWorkstepID,bcCommand,strpdcUserID,vars,this);
          }
          
          if ((bcCommand.equals("DEFAULT")||bcCommand.equals("ALLPOSITIONS")) && loadDataOK){
        	if (vars.commandIn("ALLPOSITIONS")) {
        		if (FormatUtils.isNix(strProductionid)) {
            	  String prod=commons.prepareProduction(vars,null,strpdcWorkstepID,strProductionid,strpdcUserID,null,vars.getSessionValue("pdcLocatorID"),this);
            	  vars.setSessionValue("pdcProductionID",prod);
            	  strProductionid=prod;
        		} else {
        			PdcCommonData.deleteAllMaterialLines( this, strProductionid);
                    PdcCommonData.deleteMaterialTransaction( this, strProductionid);
                    vars.removeSessionValue("pdcProductionID");
        		}
                vars.setSessionValue("PDCSTATUS","OK");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage()));
        	}
            upperGridData = DoProductionData.selectupper(this,vars.getLanguage(),strpdcWorkstepID,strProductionid,"");
            lowerGridData = DoProductionData.selectlower(this,vars.getLanguage(),strProductionid,"");
            EditableGrid lowergrid = new EditableGrid("PdcDoProductionLowerGrid",vars,this);
            strLowerGrid=lowergrid.printGrid(this, vars, script, lowerGridData);
            if (upperGridData.length>0)
              InfobarText=Utility.messageBD(this, "pdc_ProductionScan",vars.getLanguage());
            if (lowerGridData.length>0) 
            	InfobarText=Utility.messageBD(this, "pdc_canfinishproduction",vars.getLanguage());
            if (lowerGridData.length==0 && upperGridData.length==0)
          	  InfobarText=Utility.messageBD(this, "pdc_NothingToDo",vars.getLanguage());
          } else {
            upperGridData = DoProductionData.set();
            lowerGridData = DoProductionData.set();
          }
        
        // Initialize Infobar helper variables
        String InfobarPrefix = "<span style=\"font-size: 20pt; color: #000000;\">" + Utility.messageBD(this, "pdc_production",vars.getLanguage()) + "<br />";
        String InfobarSuffix = "</span>";
        String Infobar = "";
        // Info Bar
        Infobar = InfobarPrefix + InfobarText + InfobarSuffix;
        //
        // Info Bar left Space
        String Infobar2 = "<span style=\"font-size: 12pt; color: #000000;\">";
        if (vars.getSessionValue("PDCSTATUS").equals("ERROR")) 
      	  Infobar2 =Infobar2 +"<span style=\"color:#B40404;\">" + Utility.messageBD(this, "pdcerrorHint",vars.getLanguage()) + "</span><br />";
        if (!strpdcUserID.isEmpty())
      	  Infobar2 =Infobar2 +Utility.messageBD(this, "zssm_barcode_entity_employee",vars.getLanguage()) +": " + PdcCommonData.getEmployee(this, strpdcUserID);
        // Set Assemb. Product
        String productID=PdcCommonData.getProductFromWorkstep(this, strpdcWorkstepID);
        if (productID!=null && ! productID.isEmpty())
      	  Infobar2 =Infobar2 + "<br />" + PdcCommonData.getProduct(this, productID,vars.getLanguage());
        if (!vars.getSessionValue("pdcLocatorID").isEmpty())
      	  Infobar2 =Infobar2 + "<br />" +Utility.messageBD(this, "pdcmaterialconsumptionlocator",vars.getLanguage()) +": " + PdcCommonData.getLocator(this, strLocatorID);
        Infobar2 =Infobar2 + "</span>";  
        strPdcInfobar = ConfigureInfobar.doConfigure2Rows(this, vars, script, Infobar, Infobar2);                    // Generate infobar html code

        // Build the User Interface    
        script.addHiddenfield("inpadOrgId", vars.getOrg());
        script.addHiddenShortcut("linkButtonSave_New"); // Adds shortcut for save & new
        script.enableshortcuts("EDITION");              // Enable shortcut for the servlet
        // Set Status Session Vars
        vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
        vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
        //Header Fieldgroup
        strHeaderFG=fh.prepareFieldgroup(this, vars, script, "PdcDoProductionHeader", null,false);
        // Settings for dummy focus...
        strHeaderFG=MobileHelper.addDummyFocus(strHeaderFG);
        //Button Fieldgroup
        strButtonsFG=fh.prepareFieldgroup(this, vars, script, "PdcDoProductionButtons", null,false);
        //Status Fieldgroup
        strStatusFG=PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, "PdcStatusFG", null,false);
        // Grid Structures
        EditableGrid uppergrid = new EditableGrid("PdcDoProductionUpperGrid",vars,this);
        strUpperGrid=uppergrid.printGrid(this, vars, script, upperGridData);
        EditableGrid lowergrid = new EditableGrid("PdcDoProductionLowerGrid",vars,this);
        strLowerGrid=lowergrid.printGrid(this, vars, script, lowerGridData);
        //Defining the toolbar default no toolbar
        String strToolbar="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
         //Loading the structure                                                       Name of the Servlet   
        strSkeleton = ConfigureFrameWindow.doConfigureApp(this,vars,"inpbarcode",strToolbar,"Production Feedback","","REMOVED",null,"true");
        // Prevent Softkeys on Mobile Devices
        script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");        
        // Fit all the content together to html     optional Infobar  default loading Header Fieldgroup, Upper Grid, Button Fieldgroup, Lower Grid, Status Fieldgroup
        //Make the Grids scrollable with these lines
        //we are going to the old table structure into a scrollable area, if the table is bigger than the provided area
        strUpperGrid=Replace.replace(strUpperGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
        strUpperGrid=Replace.replace(strUpperGrid, "</TABLE>","</TABLE>\n</DIV>");
        strLowerGrid=Replace.replace(strLowerGrid, "<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">","<DIV style=\"height:150px;overflow:auto;\">\n<TABLE cellspacing=\"0\" class=\"DataGrid_Table\">\n"); 
        strLowerGrid=Replace.replace(strLowerGrid, "</TABLE>","</TABLE>\n</DIV>"); 
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",MobileHelper.addMobileCSS(request,strPdcInfobar+ strHeaderFG + strUpperGrid + strButtonsFG + strLowerGrid +  strStatusFG)); 
        //Generating html source


        strOutput = script.doScript(strOutput, "",this,vars);
        // Gerenrate response
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println(strOutput);
        out.close();
      }
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        vars.setSessionValue("PDCSTATUS","ERROR");
        //vars.setSessionValue("PDCSTATUSTEXT","Error in Production Feedback");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ErrorOnPage"+"\r\n"+getServletInfo(),vars.getLanguage()));

         throw new ServletException(e);
 
       }
 }
    
    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
    
  
  
    
  }

