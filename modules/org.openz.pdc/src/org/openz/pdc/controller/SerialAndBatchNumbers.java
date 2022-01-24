package org.openz.pdc.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;
import java.math.BigDecimal;

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
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openbravo.data.FResponse;
import org.openbravo.erpCommon.utility.OBError;


public class SerialAndBatchNumbers  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");
      //Getting Session Values (Global)
      String strInOutid=vars.getSessionValue("pdcInOutID");
      String strConsumptionid=vars.getSessionValue("pdcConsumptionID");
      if (strConsumptionid.isEmpty())
        strConsumptionid=strInOutid;
      String strProductionid=vars.getSessionValue("pdcProductionID");
      String strpdcWorkstepID=vars.getSessionValue("PDCWORKSTEPID");
      String strpdcUserID=vars.getSessionValue("pdcUserID");
      //setting History
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html"))){
      	vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMainDialogue.html");
      	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }
      // Setting RO values
      vars.setSessionValue(getServletInfo() + "|pdcmaterialconsumptionuserid", strpdcUserID);
      vars.setSessionValue(getServletInfo() + "|pdcmaterialconsumptionworkstepid", strpdcWorkstepID);
      //Getting Session Values (Local)
      String actBatchNumber="";
      String consumptionlineID="";
      String strProductID=vars.getSessionValue(getServletInfo() + "|pdcmaterialconsumptionproductid");
      // State of the servlet. PBATCH PSERIAL DNORMAL ORDEREDSERIAL ORDEREDBATCH or empty
      // PBATCH Production: New Batch No. ;  PSERIAL Production: New Serial No. for the shown Product/Locator
      // DNORMAL: Serial or Batch No. can be scanned, Product and consumptionline is computed.
      // ORDEREDSERIAL, ORDEREDBATCH: Serial or Batch No. for the shown Product/Locator required (Product and consumptionline cannot be  computed).
      String serialServletState=vars.getSessionValue(getServletInfo() + "|serialServletState");
      if (serialServletState.isEmpty())
        serialServletState="DNORMAL";
      // Getting Form Fields
      String strBarcode=vars.getStringParameter("inppdcmaterialconsumptionbarcode");
      String strQty=vars.getNumericParameter("inpquantity");
      String actSerialNumber="";
      
      // Evaluate Barcode Field - Determin if it is a command
      String bcCommand=vars.getCommand(); // Command issued via Barcode
   try{
      if (bcCommand.equals("SAVE_NEW_NEW")){
      // Analyze Scanned Barcode..
        PdcCommonData[] data  = PdcCommonData.selectbarcode(this, strBarcode);
        // In this Servlet CONTROL, EMPLOYEE or PRODUCT or CALCULATION, LOCATOR, WORKSTEP can be scanned,
        // The First found will be used...
        String bctype="UNKNOWN";
        String bcid="";
        for (int i=0;i<data.length;i++){
          if (data[i].type.equals("KOMBI")||data[i].type.equals("CONTROL")||data[i].type.equals("EMPLOYEE")||data[i].type.equals("PRODUCT")||data[i].type.equals("CALCULATION")||data[i].type.equals("LOCATOR")||data[i].type.equals("WORKSTEP")) {
            bcid=data[i].id;  
            bctype=data[i].type;
            if (bctype.equals("KOMBI")) {
        		String[] kombi=strBarcode.split("\\|");  
        		String snrbnr=kombi[1];
        		if (kombi.length>2 && snrbnr.isEmpty())
        			snrbnr=kombi[2];
        		if (!snrbnr.isEmpty())
        			strBarcode=snrbnr;
        	}
            break;
          }             
        }         
        //Scannes a User
        if (bctype.equals("EMPLOYEE")||bctype.equals("WORKSTEP")){
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotchangeuserorworkstep",vars.getLanguage()));
        }
        // Scanned a Control Barcode
        if (bctype.equals("CONTROL")){
          if (bcid.equals("57C99C3D7CB5459BADEC665F78D3D6BC")) // Cancel
            bcCommand="CANCEL";
          else if (bcid.equals("D0F216CC7D9D4EA0A7528744BB8D544C")) // Split Batch No
            bcCommand="BATCHSPLIT";
          else if (bcid.equals("B28DAF284EA249C48F932C98F211F257") ) // Ready (Finished)
            bcCommand="DONE";
          else {
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage()));
          }
         
        } //End of  Control BC 
        if (bctype.equals("PRODUCT")||bctype.equals("LOCATOR")||bctype.equals("CALCULATION") ){
          vars.setSessionValue("PDCSTATUS","ERROR");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage()));
        }
        if (bctype.equals("UNKNOWN")){
          vars.setSessionValue("PDCSTATUS","ERROR");
          String statustext=Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"\r\n"+vars.getStringParameter("inppdcmaterialconsumptionbarcode");
          vars.setSessionValue("PDCSTATUSTEXT",statustext);
        }  
        
        String tmpPId=SerialNumberData.getProductIdFromSerialOrBatchNumber(this, strBarcode, strConsumptionid);
        if ( ! tmpPId.isEmpty() && !tmpPId.equals("NOSINGLEPRODUCT") &&  !tmpPId.equals("UNDEFINED")) {
           // Serial Number Scan on exiting serial Numbers
           if (SerialNumberData.pdc_getSerialOrBatchType(this, strBarcode, tmpPId).equals("SERIAL") && serialServletState.equals("DNORMAL")){
             bcCommand="SERIAL";
             actSerialNumber=strBarcode;
             actBatchNumber=SerialNumberData.pdc_getBatchNoFromSerialNo(this, actSerialNumber,tmpPId);
             strProductID=tmpPId;
             strQty="1";
             consumptionlineID=SerialNumberData.getLineIDByProduct(this, strConsumptionid, strProductID);
             vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_serialnumberscanned",vars.getLanguage()));
           }
           // Batch Number Scan on exiting Batches
           if (SerialNumberData.pdc_getSerialOrBatchType(this, strBarcode, tmpPId).equals("BATCH") && serialServletState.equals("DNORMAL")){
              bcCommand="BATCH";
              actBatchNumber=strBarcode;
              actSerialNumber="";
              strProductID=tmpPId;
              consumptionlineID=SerialNumberData.getLineIDByProduct(this, strConsumptionid, strProductID);
              if (strQty.isEmpty())
                strQty=SerialNumberData.getQtyByConsumptionLineID(this, consumptionlineID);
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_batchnumberscanned",vars.getLanguage())+"\r\n"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
           }
           vars.setSessionValue("PDCSTATUS","OK");
        }
        if (tmpPId.equals("NOSINGLEPRODUCT"))
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_DuplicateBatchinList",vars.getLanguage())+"\r\n"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));

        // Determin if new Batch or Serial Number
        if (serialServletState.equals("PBATCH") && bctype.equals("UNKNOWN")) {
            actBatchNumber=strBarcode; 
            actSerialNumber= "";  
            bcCommand="BATCH";
            consumptionlineID=vars.getSessionValue(getServletInfo() + "|minternalconsumptionlineid");
            if (strQty.isEmpty())
              strQty=SerialNumberData.getQtyByConsumptionLineID(this, consumptionlineID);
            vars.setSessionValue(getServletInfo() + "|actualbatchnumber",actBatchNumber);
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_newbatchnumberassigned",vars.getLanguage())+"\r\n"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
        }
        if (serialServletState.equals("PSERIAL") && bctype.equals("UNKNOWN")) {
          actSerialNumber=strBarcode; 
          actBatchNumber=vars.getSessionValue(getServletInfo() + "|actualbatchnumber");
          bcCommand="SERIAL";
          strQty="1";
          consumptionlineID=vars.getSessionValue(getServletInfo() + "|minternalconsumptionlineid");
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_newserialnumberassigned",vars.getLanguage())+"\r\n"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
        }
        // Ordered Scan of a specific Product (More than one locators)
        if (serialServletState.equals("ORDEREDSERIAL")) {
          consumptionlineID=vars.getSessionValue(getServletInfo() + "|minternalconsumptionlineid");
          actSerialNumber=strBarcode;
          bcCommand="SERIAL";
          strQty="1";
          actBatchNumber=SerialNumberData.pdc_getBatchNoFromSerialNo(this, actSerialNumber,strProductID);
        }
        if (serialServletState.equals("ORDEREDBATCH")) {
          consumptionlineID=vars.getSessionValue(getServletInfo() + "|minternalconsumptionlineid");
          actBatchNumber=strBarcode; 
          bcCommand="BATCH";
        }
      }
    } catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        vars.setSessionValue("PDCSTATUS","ERROR");
        //vars.setSessionValue("PDCSTATUSTEXT","Error in Serial Number Screen");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ErrorOnPage"+getServletInfo(),vars.getLanguage()));
         throw new ServletException(e);
 
   }
   try {
   // Evaluation Barcode Field - END
    
      // Save Data (Serial or Batch No)
      if (bcCommand.equals("BATCH")||bcCommand.equals("SERIAL")){
        if (consumptionlineID!=null){
          //  Not P-Products with Serials and batch where batch was scanned - all other lines are inserted...
          if(! (serialServletState.equals("PBATCH") && bcCommand.equals("BATCH")  && SerialNumberData.pdc_getSerialBatchType4product(this,  strProductID).equals("BOTH"))){
              if (strInOutid.isEmpty())
                SerialNumberData.insertSerialLine(this, vars.getClient(), vars.getOrg(), strpdcUserID, consumptionlineID, strQty, actBatchNumber, actSerialNumber);
              else
                SerialNumberData.insertSerialLineInOut(this, vars.getClient(), vars.getOrg(), strpdcUserID, consumptionlineID, strQty, actBatchNumber, actSerialNumber);
          }
        }
      }
      // On Batch Split (Only Produced Items with Serisl Numbers)
      if ( bcCommand.equals("BATCHSPLIT")){
        if (serialServletState.equals("PSERIAL")){
          actBatchNumber="";
          vars.removeSessionValue(getServletInfo() + "|actualbatchnumber");
          serialServletState="BATCHSPLIT";
        } 
      }
      if (bcCommand.equals("DONE")){
        vars.setSessionValue("PDCINVOKESERIAL","DEFAULT");
        if (! strInOutid.isEmpty()) {
          if (SerialNumberData.pdc_IsInOutDraft(this,strInOutid).equals("Y"))
            SerialNumberData.pdc_InOutPOst(this,strInOutid);
        }
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_SerialorBatchSucessful",vars.getLanguage())); 
        response.sendRedirect(strDireccion + strpdcFormerDialogue);
        vars.removeSessionValue(getServletInfo() + "|serialServletState");
      }
      // On Cancel
      if (bcCommand.equals("CANCEL")) {
        SerialNumberData.delete(getConnection(), this,strConsumptionid);
        SerialNumberData.delete(getConnection(), this,strProductionid);
        SerialNumberData.deleteInOUt(getConnection(), this,strInOutid);
        // If the Mode of servlet was New Seral Scan in D+ Transaction - Remove this mode (set by productionID)
        if (PdcCommonData.getConsumptionMovementType(this, strProductionid).equals("D+")) {
          vars.removeSessionValue("pdcProductionID");
          serialServletState="DNORMAL";
          vars.removeSessionValue(getServletInfo() + "|minternalconsumptionlineid");
          vars.removeSessionValue(getServletInfo() + "|pdcmaterialconsumptionproductid");
          vars.removeSessionValue(getServletInfo() + "|mLocatorId");
        }
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));
        // Tell the Calling servlet, that we have aborted and go back
        // Default is the command with which the caller servlet will work...
        vars.setSessionValue("PDCINVOKESERIAL","DEFAULT");
        response.sendRedirect(strDireccion + strpdcFormerDialogue);
        vars.removeSessionValue(getServletInfo() + "|serialServletState");
        return;
      }
    } catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        vars.setSessionValue("PDCSTATUS","ERROR"); 
        if (e.getMessage().contains("@snr_")){
          OBError temp=Utility.translateError(this, vars, vars.getLanguage(), e.getMessage());
          vars.setSessionValue("PDCSTATUSTEXT",temp.getMessage());
        }else {
          //vars.setSessionValue("PDCSTATUSTEXT","Error in Serial Number Screen");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ErrorOnPage"+"\r\n"+getServletInfo(),vars.getLanguage())+"\r\n"+vars.getStringParameter("inppdcmaterialconsumptionbarcode"));
          throw new ServletException(e);
        }
        bcCommand="DEFAULT";
   }
   try {
      // Delete Private Session Vars
      if(bcCommand.equals("DEFAULT")){
        vars.removeSessionValue(getServletInfo() + "|actualbatchnumber");
        //vars.removeSessionValue(getServletInfo() + "|minternalconsumptionlineid");
        vars.removeSessionValue(getServletInfo() + "|pdcmaterialconsumptionproductid");
        //vars.removeSessionValue(getServletInfo() + "|serialServletState");
       
      }
      // Determin What to do next
      //if (vars.commandIn("SAVE_NEW_NEW")||vars.commandIn("DEFAULT")||vars.commandIn("BATCHSPLIT")){
        SerialNumberData[] data=null;
        if ((! strProductionid.isEmpty()) || ( ! bcCommand.equals("DEFAULT") && strProductID.isEmpty() && PdcCommonData.getConsumptionMovementType(this, strConsumptionid).equals("D+"))){
          // Assign New Serial/Batch Numbers with a D+ Transaction
          if (PdcCommonData.getConsumptionMovementType(this, strConsumptionid).equals("D+")) {
            strProductionid=strConsumptionid;
            vars.setSessionValue("pdcProductionID",strProductionid);
            strConsumptionid="";
          }
          // Open Production Data?
          data=SerialNumberData.selectupper(this, vars.getLanguage(), strProductionid,"");
          if (data.length>=1){
            if (data[0].isbatchtracking.equals("Y") && (serialServletState.equals("DNORMAL")||serialServletState.equals("BATCHSPLIT"))){
                serialServletState="PBATCH";
            }
            else if (data[0].isserialtracking.equals("Y")){
              serialServletState="PSERIAL";
            }
            vars.setSessionValue(getServletInfo() + "|minternalconsumptionlineid",data[0].mInternalConsumptionlineId);
            vars.setSessionValue(getServletInfo() + "|pdcmaterialconsumptionproductid",data[0].mProductId);
          } 
        } else if (! strInOutid.isEmpty()){
            // OpenIn Out Data?
            //TODO Implement Batch and V- Transaction
            data=SerialNumberData.selectupper(this, vars.getLanguage(), strInOutid,"");
            if (data.length>0){
              if (data[0].isserialtracking.equals("Y") && SerialNumberData.isInOutPlus(this, strInOutid).equals("V+")){
                serialServletState="PSERIAL";
                }
              // IN Real we have in OUT - This is no Consumptionline-ID it is an InoutLineID!!
              vars.setSessionValue(getServletInfo() + "|minternalconsumptionlineid",data[0].mInternalConsumptionlineId);
              vars.setSessionValue(getServletInfo() + "|pdcmaterialconsumptionproductid",data[0].mProductId);
            }
        } else 
           serialServletState="";
        // All D - transactions
        if (strProductionid.isEmpty() && strInOutid.isEmpty()){
          data=SerialNumberData.selectSpecificS(myPool, strConsumptionid);
          if (data.length==0){
            serialServletState="DNORMAL";
            vars.removeSessionValue(getServletInfo() + "|minternalconsumptionlineid");
            vars.removeSessionValue(getServletInfo() + "|pdcmaterialconsumptionproductid");
            vars.removeSessionValue(getServletInfo() + "|mLocatorId");
          } else {
            if (SerialNumberData.pdc_getSerialBatchType4product(this,  data[0].mProductId ).equals("BATCH"))
              serialServletState="ORDEREDBATCH";
            else
              serialServletState="ORDEREDSERIAL";
            String tmpPrd=data[0].mProductId;
            data=SerialNumberData.selectupper(this, vars.getLanguage(),"", strConsumptionid);
            for (int i=0;i<data.length;i++){
              if (data[i].mProductId.equals(tmpPrd)){
                vars.setSessionValue(getServletInfo() + "|pdcmaterialconsumptionproductid",data[0].mProductId);
                vars.setSessionValue(getServletInfo() + "|minternalconsumptionlineid",data[0].mInternalConsumptionlineId);
                
              }
            }
          }
        }
        vars.setSessionValue(getServletInfo() + "|serialServletState",serialServletState); 
      // Build the User Interface
      // Initialize Global Structues
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
      // Initialize Infobar helper variables
      String InfobarPrefix = "<span style=\"font-size: 20pt; color: #000000;\">";// + Utility.messageBD(this, "pdc_Serials",vars.getLanguage()) + "<br />";
      String strPdcInfobar = "";
      String InfobarSuffix = "</span>";
      String Infobar = "";
      // Info Bar
      if (serialServletState.equals("PBATCH"))
        strPdcInfobar=Utility.messageBD(this, "pdc_ScanNewBatchonPMat",vars.getLanguage());
      if (serialServletState.equals("PSERIAL"))
        if (! strProductionid.isEmpty())
          strPdcInfobar=Utility.messageBD(this, "pdc_ScanNewSerialonPMat",vars.getLanguage());
        if (! strInOutid.isEmpty())
          strPdcInfobar=Utility.messageBD(this, "pdc_ScanShownProductSerial",vars.getLanguage());
      if (serialServletState.equals("DNORMAL"))
        strPdcInfobar=Utility.messageBD(this, "pdc_ScanSerialorBatch",vars.getLanguage());
      if (serialServletState.equals("ORDEREDSERIAL"))
        strPdcInfobar=Utility.messageBD(this, "pdc_ScanShownProductSerial",vars.getLanguage());
      if (serialServletState.equals("ORDEREDBATCH"))
        strPdcInfobar=Utility.messageBD(this, "pdc_ScanShownProductBatch",vars.getLanguage());
      // Build the User Interface  -- DONE and CANCEL are redirected..
      if (! bcCommand.equals("DONE")&& ! bcCommand.equals("CANCEL")){
        upperGridData = SerialNumberData.selectupper(this,vars.getLanguage(),strProductionid,strConsumptionid);
        lowerGridData = SerialNumberData.selectlower(this,vars.getLanguage(),strProductionid,strConsumptionid);
        if (upperGridData.length==0) {
          strPdcInfobar=Utility.messageBD(this, "pdc_NothingToDo",vars.getLanguage());
          upperGridData = SerialNumberData.set();
          // Return to Calling Servlet (Nothing to do)
          response.sendRedirect(strDireccion + strpdcFormerDialogue);
          vars.removeSessionValue(getServletInfo() + "|serialServletState");
        }
        if (lowerGridData.length==0) 
          lowerGridData = DoProductionData.set();
       
      Infobar = InfobarPrefix + strPdcInfobar + InfobarSuffix; 
      strPdcInfobar = ConfigureInfobar.doConfigure2Rows(this, vars, script, Infobar, "");
      script.addHiddenfield("inpadOrgId", vars.getOrg());
      script.addHiddenShortcut("linkButtonSave_New"); // Adds shortcut for save & new
      script.enableshortcuts("EDITION");              // Enable shortcut for the servlet
      // Prevent Softkeys on Mobile Devices
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      //Header Fieldgroup
      strHeaderFG=fh.prepareFieldgroup(this, vars, script, "pdcSerialHeader", null,false);
      // Settings for dummy focus...
      strHeaderFG=MobileHelper.addDummyFocus(strHeaderFG);
      // Prevent Softkeys on Mobile Devices
      script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
      //Button Fieldgroup
      strButtonsFG=fh.prepareFieldgroup(this, vars, script, "PdcSerialNumbersButtons", null,false);
      //Status Fieldgroup
      strStatusFG=PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, "PdcStatusFG", null,false);
      // Grid Structures
      EditableGrid uppergrid = new EditableGrid("pdc_SerialUpperGrid",vars,this);
      strUpperGrid=uppergrid.printGrid(this, vars, script, upperGridData);
      EditableGrid lowergrid = new EditableGrid("pdc_SerialLowerGrid",vars,this);
      strLowerGrid=lowergrid.printGrid(this, vars, script, lowerGridData);
      //Defining the Structure
      String strToolbar="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this,vars,"inpbarcode",strToolbar,"Serial Number","","REMOVED",null,"true");
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
    }
    catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        vars.setSessionValue("PDCSTATUS","ERROR");
        //vars.setSessionValue("PDCSTATUSTEXT","Error in Serial Number Screen");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ErrorOnPage"+getServletInfo(),vars.getLanguage()));
         throw new ServletException(e);
 
    }  
 }
   
    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

