package org.openz.pdc.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessRunner;
import org.openbravo.utils.Replace;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openbravo.data.FResponse;
import org.openz.pdc.PdcCommons;
import org.openz.pdc.PdcStoreInventoryData;
import org.openz.util.*;


import org.openbravo.base.ConfigParameters;

public class TimeFeedback  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;


    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
    	VariablesSecureApp vars = new VariablesSecureApp(request);      
 
      
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
        String strStatusFG = "";                  // Status fieldgroup (defined in AD)
        String feedbackresult="";
        String workstep="";
        String employee="";
        String description="";
        String BcCommand = "";
        
     try {
        // Default: MSG: Sucessful
    	vars.setSessionValue("PDCSTATUS","OK");
        //vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage()));
    	vars.removeSessionValue("PDCSTATUSTEXT");
        // Default
        if (vars.commandIn("DEFAULT")) {
        	removesessvars(vars);
        }
        workstep=vars.getSessionValue("pdcWorkstepID");
        employee=vars.getSessionValue("pdcEmployeeID");
        if (employee.isEmpty()) {
        	if (PdcCommonData.isEmployeeLoggedIn(this, vars.getUser()).equals("Y")) {
        		employee=vars.getUser();
        		setEmpstatus(vars,employee);  	          
        	}
        }
        if (!employee.isEmpty())
        	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "Employee",vars.getLanguage()) +": " + TimeFeedbackData.getEmployee(this, employee,vars.getLanguage()));
        if (vars.commandIn("RESET") && PdcCommonData.hasMenu(this, vars.getRole()).equals("Y")){
    		response.sendRedirect(strDireccion + "/security/Menu.html");
    	}
        // Buttons
        if (vars.commandIn("COMING"))
      	  BcCommand = "COMING"; 
        if (vars.commandIn("LEAVING"))
      	  BcCommand = "LEAVING"; 
        if (vars.commandIn("PROJECT"))
        	  BcCommand = "PROJECT"; 
        // Callout
        if (vars.commandIn("LOADWORKSTEP")) {
          workstep=vars.getStringParameter("inpcProjecttaskId");
      	  vars.setSessionValue("pdcWorkstepID",workstep);
        }
        // Read Description Field
  	    description=vars.getStringParameter("inppdcmaterialconsumptiondescription");
        // Read Barcode
        if (vars.commandIn("SAVE_NEW_NEW")) {
      	  // REad Barcode
      	  PdcCommonData bar=PdcCommons.getBarcode(this, vars);
      	  String bctype=bar.type;
      	  String bcid=bar.id;
      	  String barcode=bar.barcode;
            
            //Time Feedback not applicable
            if (bctype.equals("CONTROL")||bctype.equals("KOMBI")||bctype.equals("LOCATOR")||bctype.equals("BATCHNUMBER")||bctype.equals("SERIALNUMBER")||bctype.equals("PRODUCT")){
          	  vars.setSessionValue("PDCSTATUS","WARNING");
          	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"\r\n"+barcode);                    
            } else if (bctype.equals("EMPLOYEE")) {
          		  vars.setSessionValue("pdcEmployeeID",bcid);         		  
  	              employee=vars.getSessionValue("pdcEmployeeID");
  	              BcCommand = "EMPLOYEE";
  	              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "Employee",vars.getLanguage()) +": " + TimeFeedbackData.getEmployee(this, employee,vars.getLanguage()));
  	              setEmpstatus(vars,employee);  	              	         
            } else if (bctype.equals("WORKSTEP")) {
            	vars.setSessionValue("pdcWorkstepID",bcid);
            	workstep=bcid; 
            } else if (bctype.equals("UNKNOWN")) {
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode);
              
            } 
        }
        Date now=new Date();
        String tst=FormatUtils.date2sqltimestamp(now, vars);
        if (BcCommand.equals("COMING")) {
        	if (employee.isEmpty()) {
        		vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()));
        	} else {
        		feedbackresult=TimeFeedbackData.setTimeFeedback(this, vars.getOrg(), workstep, employee, tst,"dd-MM-yyyy HH24:mi:ss", "COMING",description,vars.getLanguage());
        		//vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_coming",vars.getLanguage())+": " + TimeFeedbackData.getEmployee(this, employee) + getPrjMsg(vars) +": "+ UtilsData.getTimestamp(this, vars.getSessionValue("#AD_SQLDATETIMEFORMAT")));
        		vars.setSessionValue("PDCSTATUSTEXT",feedbackresult +": "+ UtilsData.getTimestamp(this, vars.getSessionValue("#AD_SQLDATETIMEFORMAT")));
        		removesessvars(vars);
        	}
        }
        
        if (BcCommand.equals("LEAVING")) {
            if (employee.isEmpty()) {
            	vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()));
        	} else {
        		feedbackresult=TimeFeedbackData.setTimeFeedback(this, vars.getOrg(), workstep, employee, tst,"dd-MM-yyyy HH24:mi:ss", "LEAVING",description,vars.getLanguage());
        		//vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_leaving",vars.getLanguage())+": " + TimeFeedbackData.getEmployee(this, employee) + getPrjMsg(vars)+": "+ UtilsData.getTimestamp(this, vars.getSessionValue("#AD_SQLDATETIMEFORMAT")));
        		vars.setSessionValue("PDCSTATUSTEXT",feedbackresult +": "+ UtilsData.getTimestamp(this, vars.getSessionValue("#AD_SQLDATETIMEFORMAT")));
        		removesessvars(vars);
        	}
        }
        
        if (vars.commandIn("PROJECT")) {
        	if (employee.isEmpty()) {
            	vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()));
        	} else {
        		feedbackresult=TimeFeedbackData.setTimeFeedback(this, vars.getOrg(), workstep, employee, tst,"dd-MM-yyyy HH24:mi:ss", "PROJECT",description,vars.getLanguage());  
	        	//vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_project",vars.getLanguage()) +": " + TimeFeedbackData.getWorkstep(this, workstep) + " (" +TimeFeedbackData.getEmployee(this, employee) + ")"+": "+ UtilsData.getTimestamp(this, vars.getSessionValue("#AD_SQLDATETIMEFORMAT")));
        		vars.setSessionValue("PDCSTATUSTEXT",feedbackresult +": "+ UtilsData.getTimestamp(this, vars.getSessionValue("#AD_SQLDATETIMEFORMAT")));
        		removesessvars(vars);
        	}
        }
      }
      // Present Errors on the User Screen
      catch (Exception e) { 
      	e.printStackTrace();
      	vars.setSessionValue("PDCSTATUS","ERROR");
  	    vars.setSessionValue("PDCSTATUSTEXT",Utility.translateError(this, vars,vars.getLanguage(),e.getMessage()).getMessage());
  	    removesessvars(vars);
      } 
      try {
        // Prepare the GUI
    	// Terminal Mode or Login..
    	if (PdcCommonData.isEmployeeLoggedIn(this, vars.getUser()).equals("Y")) {
      		employee=vars.getUser();
      		setEmpstatus(vars,employee);  	          
      	}
        // Initialize Infobar helper variables
        String InfobarPrefix = "<span style=\"font-size: 20pt; color: #000000;\">";
        String InfobarText="";
        InfobarText = Utility.messageBD(this, "pdc_Timefeedback",vars.getLanguage()) + "<br />";
        String InfobarSuffix = "</span>";
        String Infobar = "";
        String Infobar2 = "";
        if (!feedbackresult.isEmpty())
        	Infobar2 =Infobar2 + "<br />" + feedbackresult;
        if (!workstep.isEmpty()) {
      	  Infobar2 =Infobar2 + "<br />" + Utility.messageBD(this, "Project",vars.getLanguage())  +": " + TimeFeedbackData.getWorkstep(this, workstep);
 
        }    
        // Get InfoBar Text
        if (employee.isEmpty())   
          InfobarText = InfobarText + Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage());
        else
      	  InfobarText = InfobarText + Utility.messageBD(this, "pdc_commingleavingProject",vars.getLanguage());
        // Generate Infobar
        Infobar = InfobarPrefix + InfobarText + InfobarSuffix;
        //strPdcInfobar = fh.prepareInfobar(this, vars, script, Infobar, "");                       // Generate infobar html code
        strPdcInfobar = ConfigureInfobar.doConfigure2Rows(this, vars, script, Infobar, Infobar2);   
        
   
        
        // GUI Settings Responsive for Mobile Devises
        // Prevent Softkeys on Mobile Devices (Field is Readonly and programmatically set). Field dummyfocusfield must exist (see MobileHelper.addDummyFocus)
        script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
        script.addHiddenfieldWithID("forcefocusfield", "pdcmaterialconsumptionbarcode"); // Force Focus after Numpad to given Field
        // Set Session Value for Mobiles (Android Systems) - Effect is that the new Numpad is loaded
        // Upright Screen Zoomes200%
    	MobileHelper.setMobileMode(request, vars, script);
        
        // Generate servlet skeleton html code
        strQuit="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
        strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID",strQuit, "Time Feedback", "", "REMOVED", null,"true");   // Generate skeleton
        // Reload Session instead of Backward Button
        if (vars.getSessionValue("PDCFORMERDIALOGUE").isEmpty())
        	strSkeleton = Replace.replace(strSkeleton, "goToPreviousPage(); return false;", "submitCommandForm('RESET', true, null,'../org.openz.pdc.ad_forms/TimeFeedback.html', 'appFrame', false, true);return false;");    
        
        
        // Generate servlet elements html code
        // FG with data
        TimeFeedbackData[] dta = TimeFeedbackData.initialize(this);
        dta[0].cProjecttaskId=workstep;
        dta[0].decription=description;
        strHeaderFG = fh.prepareFieldgroup(this, vars, script, "PdcTimeFeedbackHeader", dta[0], false);        // Generate header html code
        // crAction adds RETURN and TAB to Barcode field -> Triggers SAVE_NEW
        
      	strHeaderFG=MobileHelper.addcrActionBarcode(strHeaderFG);
      	// On Upright Screens Hide Barcode Field (Prevents Focus and Mobile Soft Keypad)
      	strHeaderFG=MobileHelper.hideActionBarcode(strHeaderFG);
        // Settings for dummy focus...
        strHeaderFG=MobileHelper.addDummyFocus(strHeaderFG);

        strStatusFG = PdcStatusBar.getStatusBarAPP(request,this, vars, script);       // Generate status html code (With Request is Mobile Aware..)
            
     
        // Fit all the content together
        strOutput = Replace.replace(strSkeleton, "@CONTENT@", MobileHelper.addMobileCSS(request,strPdcInfobar + strHeaderFG +  strStatusFG));
        
        // Script operations
        script.addHiddenfield("inpadOrgId", vars.getOrg());
        script.addHiddenShortcut("linkButtonSave_New"); // Adds shortcut for save & new
        script.enableshortcuts("EDITION");              // Enable shortcut for the servlet
        script.addOnload("setFocusOnField('pdcmaterialconsumptionbarcode', 5000);");
        
        // Refresh after 5 sec. after action was displayed
        Integer iv=5000;
        if (BcCommand.equals("EMPLOYEE"))
        	iv=30000;
        if (BcCommand.equals("COMING")||BcCommand.equals("LEAVING")||BcCommand.equals("PROJECT")||BcCommand.equals("EMPLOYEE"))
        	script.addOnload("setTimeout(function(){submitCommandForm('DEFAULT', false, null, '../org.openz.pdc.ad_forms/TimeFeedback.html', '_self', null, true);}," + iv.toString() + ");");        
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
    private void removesessvars(VariablesSecureApp vars)  throws ServletException {
    	vars.removeSessionValue("pdcWorkstepID");
    	vars.removeSessionValue("pdcEmployeeID");
    	vars.setSessionValue("pdcIscoming","N");
    	vars.setSessionValue("pdcLeaving","N");
    	vars.setSessionValue("pdcProject","N");
    }
    
    private void setEmpstatus(VariablesSecureApp vars, String employee) throws ServletException {
    	if (TimeFeedbackData.getEmployeeStatusLeaving(this, employee).equals("Y")) {
          	vars.setSessionValue("pdcLeaving","Y");
          	vars.setSessionValue("pdcIscoming","N");
          	vars.setSessionValue("pdcProject","Y");
            } else {
          	vars.setSessionValue("pdcLeaving","N");
          	vars.setSessionValue("pdcIscoming","Y");
          	vars.setSessionValue("pdcProject","N");
            }
    }
    
    private String getPrjMsg(VariablesSecureApp vars) throws ServletException {
    	if (vars.getSessionValue("pdcWorkstepID").isEmpty())
    		return "";
    	else
    	return " (" + TimeFeedbackData.getWorkstep(this,vars.getSessionValue("pdcWorkstepID")) + ")";
    }
    
    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

