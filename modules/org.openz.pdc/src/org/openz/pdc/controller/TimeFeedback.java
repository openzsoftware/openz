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
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.FormatUtils;
import org.openz.util.LocalizationUtils;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openbravo.data.FResponse;
import org.openz.util.*;


import org.openbravo.base.ConfigParameters;

public class TimeFeedback  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");
     
      try{
          vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
          vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
        // Get and Set Session Variables here
        //Getting
        String strpdcWorkstepID=vars.getStringParameter("inpworkstep");
        String strpdcUserID=vars.getStringParameter("inpemployee");
        String strBarcode=vars.getStringParameter("inpbarcode");
        String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
        if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/TimeFeedback.html"))){
        	vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
        	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
        }
        if (strpdcWorkstepID.equals(""))
          strpdcWorkstepID=vars.getSessionValue("PDCWORKSTEPID");
        if (strpdcUserID.equals(""))
          strpdcUserID=vars.getSessionValue("pdcUserID");
        
     // Evaluate Barcode Field - Determin if it is a command
        String bcCommand=""; // Command issued via Barcode
        if (vars.commandIn("SAVE_NEW_NEW")){
        // Analyze Scanned Barcode..
          String strbarcodetype="";
          if (!strBarcode.isEmpty()) {
            PdcCommonData[] data  = PdcCommonData.selectbarcode(this, strBarcode);
            // In this Servlet CONTROL, EMPLOYEE or WORKSTEP can be scanned,
            // The First found will be used...
            String bctype="UNKNOWN";
            String bcid="";
            for (int i=0;i<data.length;i++){
              if (data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("WORKSTEP")) {
                bcid=data[i].id;  
                bctype=data[i].type;
                break;
              }             
            }         
            //Scannes a User
            if (bctype.equals("EMPLOYEE")){
                vars.setSessionValue("pdcStatus", "OK");
                //vars.setSessionValue("pdcStatustext", "Barcode: Mitarbeiter");
                vars.setSessionValue("pdcStatustext", "Barcode: "+ LocalizationUtils.getElementTextByElementName(this,bctype,vars.getLanguage())+"-"+vars.getStringParameter("inpbarcode"));
                strpdcUserID=bcid;
            }
            // Scanned a Control Barcode
            else if (bctype.equals("CONTROL")){
              if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC")) // Cancel
                bcCommand="CANCEL";
              else if (bcid.equals("B28DAF284EA249C48F932C98F211F257")) // Ready (Finished)
                bcCommand="DONE";
              else {
                vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"-"+vars.getStringParameter("inpbarcode"));
              }
             
            } else if (bctype.equals("WORKSTEP")){
                vars.setSessionValue("pdcStatus", "OK");
                //vars.setSessionValue("pdcStatustext", "Barcode: Assembly");
                vars.setSessionValue("pdcStatustext", "Barcode: "+ LocalizationUtils.getElementTextByElementName(this,bctype,vars.getLanguage())+"-"+vars.getStringParameter("inpbarcode"));
                strpdcWorkstepID=bcid;
            }  else if (bctype.equals("UNKNOWN")){
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+vars.getStringParameter("inpbarcode"));
            }  else {
              vars.setSessionValue("PDCSTATUS","ERROR");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"-"+vars.getStringParameter("inpbarcode"));
            }
          } // Empty Barcode
        } else { // command not save_new_new
          if (vars.commandIn("DEFAULT")) {
            // Look if we come from serial Number Tracking...
            String commandserial=vars.getSessionValue("PDCINVOKESERIAL");
            vars.removeSessionValue("PDCINVOKESERIAL");
            if (!commandserial.isEmpty()) {
                // Commit Serial Transaction
                String GlobalConsumptionID=vars.getSessionValue("pdcConsumptionID");
                ProcessUtils.startProcessDirectly(GlobalConsumptionID, "800131", vars, this); 
                // PdcCommonData.doConsumptionPost(this, strConsumptionid);
                vars.setSessionValue("PDCSTATUS","OK");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_MaterialGotSucessful",vars.getLanguage()));
                response.sendRedirect(strDireccion + strpdcFormerDialogue);
            } else {
              commandserial=vars.getSessionValue("PDCINVOKECONSUMPTION");
              vars.removeSessionValue("PDCINVOKECONSUMPTION");
              if (!commandserial.isEmpty()) 
                response.sendRedirect(strDireccion + strpdcFormerDialogue);
              
            }
              bcCommand=vars.getCommand();
          } else {
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage()));
            bcCommand=vars.getCommand();
          }
        }
        if(strpdcWorkstepID.isEmpty()){
          String temp=TimeFeedbackData.getOpenWorkstep(this, strpdcUserID);
          if(!temp.isEmpty())
            strpdcWorkstepID=temp;
        }
        //Setting 
        vars.setSessionValue("PDCWORKSTEPID",strpdcWorkstepID);
        vars.setSessionValue(getServletInfo() + "|" + "workstep",strpdcWorkstepID);
        vars.setSessionValue("pdcUserID",strpdcUserID);
        vars.setSessionValue(getServletInfo() + "|" + "Employee",strpdcUserID);
        
        if (bcCommand.equals("DONE")){
          String message = "";
          boolean redirect=false;
          if (strpdcWorkstepID.isEmpty()||strpdcUserID.isEmpty())
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NoData",vars.getLanguage()));
          else {
           if (TimeFeedbackData.isWorstepStarted(this, strpdcWorkstepID).equals("N")) {
             TimeFeedbackData[] res=TimeFeedbackData.beginWorkstepNoMat(this, strpdcWorkstepID, strpdcUserID, vars.getOrg());
             if (res.length>0){
               String msgtext=Replace.replace(res[0].outMessagetext,"@","");
               // Material received comletely
               if (!res[0].outCreatedid.isEmpty() && msgtext.contains("zssm_MaterialReceivedCompleteInWorkstep")) {
                 msgtext="zssm_MaterialReceivedCompleteInWorkstep";
                 message=Utility.messageBD(this, "pdc_workstepstartedautomatically",vars.getLanguage()) + "   " + Utility.messageBD(this, msgtext,vars.getLanguage());
               }
               // Material received comletely / Serial Numbers necessary
               else if (!res[0].outCreatedid.isEmpty() && msgtext.contains("zssm_MaterialReceivedSerialRegistrationNeccessary")){
                 vars.setSessionValue("pdcConsumptionID", res[0].outCreatedid);
                 vars.setSessionValue("PDCINVOKESERIAL","SERIAL");
                 vars.setSessionValue("PDCSTATUS","OK");
                 vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_workstepstartedautomatically",vars.getLanguage()) + "   " +
                     Utility.messageBD(this, "zssm_MaterialReceivedSerialRegistrationNeccessary",vars.getLanguage()));
               //Second Layer settings
                 if (strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMainDialogue.html")){
              	   vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/TimeFeedback.html");
              	   strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
                 }
                 redirect=true;
                 response.sendRedirect(strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");
               // Manual Stock Transaction requred
               } else if (res[0].outCreatedid.isEmpty() && (msgtext.contains("zssm_ManualStockTransactionRequred")
                   ||msgtext.contains("zssm_materialNotCompleteRequireManualStockTransaction")
                   ||msgtext.contains("zssm_workstepStartedWithManualStockTransaction"))){
                 vars.setSessionValue("PDCSTATUS","OK");
                 vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_workstepstartedautomatically",vars.getLanguage()) + "   " +
                     Utility.messageBD(this, msgtext,vars.getLanguage()));
                 //Second Layer settings
                 if (strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMainDialogue.html")){
                	   vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/TimeFeedback.html");
                	   strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
                   }
                 redirect=true;
                 vars.setSessionValue("PDCINVOKECONSUMPTION","CONSUMPTION");
                 //response.sendRedirect(strDireccion + "/org.openz.pdc.ad_forms/PdcMaterialConsumption.html");   
               } else if (res[0].outCreatedid.isEmpty() && (msgtext.contains("zssm_NoStockTransactionNeededAllMaterialGot"))){
                 msgtext="zssm_NoStockTransactionNeededAllMaterialGot";
                 message=Utility.messageBD(this, "pdc_workstepstartedautomatically",vars.getLanguage()) + "   " + Utility.messageBD(this, msgtext,vars.getLanguage());
               }
               else
                 message=res[0].outMessagetext;
             } else {
               vars.setSessionValue("PDCSTATUS","ERROR");
               message="Error creating Material receipt";
             }
           } 
           if (TimeFeedbackData.isWorstepStarted(this, strpdcWorkstepID).equals("Y"))  {
             Date now=new Date();
             String temp=TimeFeedbackData.getOpenWorkstep(this, strpdcUserID);
             if (!temp.isEmpty() && !temp.equals(strpdcWorkstepID))
               TimeFeedbackData.setTimeFeedback(this, vars.getOrg(), temp, strpdcUserID, FormatUtils.date2sqltimestamp(now, vars),"dd-MM-yyyy HH24:mi:ss");
             TimeFeedbackData.setTimeFeedback(this, vars.getOrg(), strpdcWorkstepID, strpdcUserID, FormatUtils.date2sqltimestamp(now, vars),"dd-MM-yyyy HH24:mi:ss");
             if (!redirect){
               vars.setSessionValue("PDCSTATUS","OK");
               vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_timefeedbachdone",vars.getLanguage())+ "   " + message);
               response.sendRedirect(strDireccion + strpdcFormerDialogue);
             }
             
           }
          }   
        }
        if (bcCommand.equals("CANCEL")){
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
          response.sendRedirect(strDireccion + strpdcFormerDialogue);
        }
        //To set Inputboxes etc use 
        //set                     the docname          fieldname without inp    content/value
        //vars.setSessionValue(this.getClass().getName() + "|Statustext", "content of the Field");
        // Initialize Global Structues
        String strPdcInfobar=""; //Area for further Information of the Servlet
        
        Scripthelper script= new Scripthelper();
        script.addHiddenfield("inpadOrgId", vars.getOrg());
        script.addHiddenShortcut("linkButtonSave_New"); // Adds shortcut for save & new
        script.enableshortcuts("EDITION");              // Enable shortcut for the servlet
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
        
        // Loading the Data for the grid - requires valid xsql Files
        //loading the upper grid  with language parameter                                             
        upperGridData = TimeFeedbackData.selectupper(this,strpdcUserID);
        //loading the lower grid  with language parameter
        lowerGridData = TimeFeedbackData.selectlower(this,strpdcUserID);
        // Build the User Interface.
        // Load Upper Grid from AD                  Enter here the name of the grid
        EditableGrid uppergrid = new EditableGrid("PDCTimeFeedbackUpperGrid",vars,this);
        //save the grid in variable
        strUpperGrid=uppergrid.printGrid(this, vars, script, upperGridData);
        //User or Workstep Info
        if ((strpdcUserID.equals(""))&&(strpdcWorkstepID.equals(""))){
            //Declaration of the Infobar                         Text inside the Infobar
            strPdcInfobar=fh.prepareInfobar(this, vars, script,  Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()),"font-size: 32pt; color: #000000;");
            }
        if ((strpdcUserID.equals(""))&&(!strpdcWorkstepID.equals(""))){
            //Declaration of the Infobar                         Text inside the Infobar
            strPdcInfobar=fh.prepareInfobar(this, vars, script,  Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()),"font-size: 32pt; color: #000000;");
        }
        if ((!strpdcUserID.equals(""))&&(strpdcWorkstepID.equals(""))){
          //Declaration of the Infobar                         Text inside the Infobar
          strPdcInfobar=fh.prepareInfobar(this, vars, script,  Utility.messageBD(this, "pdc_ScanWorkstep",vars.getLanguage()),"font-size: 32pt; color: #000000;");
        }
        if ((!strpdcUserID.equals(""))&&(!strpdcWorkstepID.equals(""))){
            //Declaration of the Infobar                         Text inside the Infobar
            strPdcInfobar=fh.prepareInfobar(this, vars, script,  Utility.messageBD(this, "pdc_ScanCompleteTF",vars.getLanguage()),"font-size: 32pt; color: #000000;");
        }
        	
   /*     if ((strpdcUserID.equals(""))&&(strpdcWorkstepID.equals(""))){
            //Declaration of the Infobar                         Text inside the Infobar
            strPdcInfobar=fh.prepareInfobar(null, vars, script,  Utility.messageBD(this, "pdc_ScanUser",vars.getLanguage()),"");
            }*/
        // Prepare the Fieldgroups from AD                    Name of the Fieldgroup
        vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
        vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
        //Fieldgroups below are Default for PDC
        //Header Fieldgroup
        strHeaderFG=fh.prepareFieldgroup(this, vars, script, "PdcTimeFeedbackHeader", null,false);
        strHeaderFG=Replace.replace(strHeaderFG, "5ACEF6CF329D4BC09C05FCE78775454C","530C8BFD91D14C319EFC04813849A4A0");
        //Button Fieldgroup
        strButtonsFG=fh.prepareFieldgroup(this, vars, script, "PdcButtonsFG", null,false);
        //Status Fieldgroup
        strStatusFG=PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, "PdcStatusFG", null,false);
        // Loading the Lower Grid from AD          Name of lower grid  
        EditableGrid lowergrid = new EditableGrid("PDCTimeFeedbackLowerGrid",vars,this);
        //saving the lower grid in variable
        strLowerGrid=lowergrid.printGrid(this, vars, script, lowerGridData);
        // Load Form-Skeleton 

        //Defining the toolbar default no toolbar
        String strToolbar="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
         //Loading the structure                                                       Name of the Servlet              
        strSkeleton = ConfigureFrameWindow.doConfigureApp(this,vars,"inpbarcode",strToolbar, "Time Feedback","","REMOVED",null,"true");
        // Prevent Softkeys on Mobile Devices
        script.addOnload("setTimeout(function(){document.getElementById(\"barcode\").focus();fieldReadonlySettings('barcode', false);},50);");
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
         throw new ServletException(e);
 
       }  
 }
    
    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

