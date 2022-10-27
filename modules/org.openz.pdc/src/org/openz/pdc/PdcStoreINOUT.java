

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

public class PdcStoreINOUT extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);      
      String usecase;  // Mode of Scan (FULL means Full Scan, SERIAL only Batch and Serials)
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
      String strsnrbnr="";
      // Loading global session variables
      String GlobalUserID = vars.getUser();
      String GlobalINOUTID = getLocalSessionVariable(vars, "pdcinouttrx");
      // Initialize fieldproviders - they provide data for the grids
      FieldProvider[] lowerGridData;    // Data for the lower grid
     
      //setting History
      String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      if ((strpdcFormerDialogue.equals(""))||(strpdcFormerDialogue.equals("/ad_forms/PdcStoreConsumptionAndReturn.html"))){
      	vars.setSessionValue("PDCFORMERDIALOGUE","/ad_forms/PDCStoreMainDialoge.html");
      	strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
      }
      String BcCommand = "";
      // Usecase
      if (UtilsData.getOrgConfigOption(this, "PDCINOUTFULLSCAN", vars.getOrg()).equals("Y"))
			usecase="FULL";	
      else
    	  usecase="SERIAL";  
 try {      
      // Business logic default
       if (vars.commandIn("DEFAULTDELIVER")||vars.commandIn("DEFAULTRECEIPT")) {
    	removeSessionVars(vars);
    	GlobalINOUTID =PdcINOUTData.getTrxPicking(this, GlobalUserID);
    	if (!FormatUtils.isNix(GlobalINOUTID))
    		setLocalSessionVariable(vars, "pdcinouttrx",GlobalINOUTID);
    	// Load USECASE 
    	if (vars.commandIn("DEFAULTDELIVER"))
    	   setLocalSessionVariable(vars, "pdcdirection","C-");
    	if (vars.commandIn("DEFAULTRECEIPT"))
    	   setLocalSessionVariable(vars, "pdcdirection","V+");
      }     
      String PdcDirection=getLocalSessionVariable(vars,"pdcdirection");
      // Processing Scan..
      if (vars.commandIn("SAVE_NEW_NEW")) {
    	  // REad Barcode
    	  PdcCommonData bar=PdcCommons.getBarcode(this, vars);
    	  String bctype=bar.type;
    	  String bcid=bar.id;
    	  String barcode=bar.barcode;
    	  // Default: MSG: Sucessful
    	  vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_sucessful",vars.getLanguage())+"-"+barcode);
          // Get/Set TRX
    	  if (getLocalSessionVariable(vars, "pdcinouttrx").isEmpty()) {
    		  // Zuerst Warenbewegung wählen
    		  String dscr=vars.getStringParameter("inppdcinouttrx");
    		  if (dscr.isEmpty()) {
    			  vars.setSessionValue("PDCSTATUS","ERROR");
    			  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_settrxfirst",vars.getLanguage()));
    			  bctype="ERROR";
    		  } else {
    			  setLocalSessionVariable(vars, "pdcinouttrx",dscr);
    			  GlobalINOUTID=dscr;	
    			  PdcINOUTData.setTrxPicking(this,  GlobalUserID,GlobalINOUTID);
    			  bctype="IOTRX";
    		  }
    	  }
          //Time Feedback/Employee not applicable
          if (bctype.equals("EMPLOYEE")||bcid.equals("872C3C326AB64D1EBABDD49A1E138136")||bctype.equals("WORKSTEP")){
        	  vars.setSessionValue("PDCSTATUS","WARNING");
        	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage())+"\r\n"+barcode);       
              
          } else if (bctype.equals("LOCATOR")) {
        	  if (!PdcCommonData.inventoryRunning(this, bcid).equals("0"))
            	  throw new Exception(Utility.messageBD(this, "RunningInventory",vars.getLanguage()));
        	  // Nur bei Wareneingang dynamische Zuweisung möglich Aber nur ein Lagerort pro Arikel
        	  if (PdcDirection.equals("V+")) {
        		  String lineID=PdcINOUTData.getFirstLineID(this, GlobalINOUTID, usecase, vars.getSessionValue("pdcinoutfirstline"));
        		  PdcINOUTData.setLocatorInOutLine(this, bcid,lineID);
        		  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_locatorchanged",vars.getLanguage())+"-"+barcode);
        	  } else {
        		  vars.setSessionValue("PDCSTATUS","WARNING");
            	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "cannotchangelocator",vars.getLanguage())+"\r\n"+barcode);    
        	  }
   
          } else if (bctype.equals("PRODUCT")  && usecase.equals("FULL")) {
    		  String qty=bar.qty; 
    		// 	Erste Zeile mit Artikel, die noch nicht abgearbeitet ist finden, wenn alle Fertig, einfach erste Zeile mit Artikel
    		  String inoutLineId=PdcINOUTData.getInOutLinefromProduct(this, GlobalINOUTID, bcid); 
    		  // Diese Zeile als zu bearbeiten setzen (bleibt oben, wenn etwas offen bleibt)
    		  vars.setSessionValue("pdcinoutfirstline",inoutLineId);
    		  if (FormatUtils.isNix(inoutLineId)) {
    			  vars.setSessionValue("PDCSTATUS","WARNING");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "NoDataSelected",vars.getLanguage())+"\r\n"+barcode); 
    		  } else if (qty.isEmpty()?PdcINOUTData.isMorePickingIncrement(this, inoutLineId).equals("Y"):PdcINOUTData.isMorePicking(this, qty, inoutLineId).equals("Y")){
    			  vars.setSessionValue("PDCSTATUS","ERROR");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_cannotpickmore",vars.getLanguage())+"\r\n"+barcode);    			  
    		  } else {
    			  setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", bcid);
    			  if (PdcINOUTData.getSnrBnr4ProductFromLine(this, inoutLineId).equals("NN")) {
	        		  if (!FormatUtils.isNix(qty) && Integer.parseInt(qty)==0)	{        			
	        			  PdcINOUTData.updateInOutLine(this,GlobalUserID, "0","0", inoutLineId);  // Delete Control Count Scans
	        			  PdcINOUTData.deleteSnrLinesOnInoutline(this, inoutLineId);
	        		  }
	    			  if (qty.isEmpty()) {
	    				  PdcINOUTData.incrementInOutLine(this,GlobalUserID, null, inoutLineId); // Increment Qty
	        		  } else {
	        			  PdcINOUTData.updateInOutLine(this, GlobalUserID,qty, null, inoutLineId);// Update Qty (Bis zur vorgegebenen Menge)
	        		  }
    		      }
    		  }
          } else if (bctype.equals("KOMBI")) {        	  
        	  String lineID;
        	  if (getLocalSessionVariable(vars, "pdcdirection").equals("C-"))
        		// SNR/BNR muß am vorgegebenen Lagerort vorhanden sein (WB Kunde)
        		lineID=PdcINOUTData.getInOutLinefromKombi(this, GlobalINOUTID, bcid, bar.serialnumber,bar.lotnumber);
        	  else
        		  lineID=PdcINOUTData.getInOutLinefromProduct(this, GlobalINOUTID, bcid);  
        	  vars.setSessionValue("pdcinoutfirstline",lineID);
        	  if (FormatUtils.isNix(lineID)) {
        		  vars.setSessionValue("PDCSTATUS","WARNING");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ItemNotInTRX",vars.getLanguage())+"\r\n"+barcode);
        	  } else {
        		  setLocalSessionVariable(vars, "pdcmaterialconsumptionproductid", bcid);        		  
        		  updateSnrQtys(vars,lineID,GlobalUserID, bar.qty, bar.lotnumber, bar.serialnumber);
        		  strsnrbnr=InfoBarHelper.getSnrBnrStr(this, vars, bar.serialnumber, bar.lotnumber, bar.qty, bar.weight);
        	  }
          } else if (bctype.equals("SERIALNUMBER") && getLocalSessionVariable(vars, "pdcdirection").equals("C-") &&
        		     PdcINOUTData.isFirstProductSerial(this,barcode, GlobalINOUTID, usecase, vars.getSessionValue("pdcinoutfirstline")).equals("Y") ) {
        	  // SNR, WB Kunde: Nur SNR Eintragen (Mengen setzen und Zeile definieren erfolgt mit Scan Artikelbarcode)
        	  String lineID=PdcINOUTData.getFirstLineID(this, GlobalINOUTID, usecase, vars.getSessionValue("pdcinoutfirstline"));
        	  String product=PdcINOUTData.getProductFromLine(this, lineID);
        	  String btch=PdcINOUTData.getBtchNoFromProductAndSerial(this, product, barcode);
        	  updateSnrQtys(vars,lineID,GlobalUserID, bar.qty, btch, barcode); 
        	  strsnrbnr=InfoBarHelper.getSnrBnrStr(this, vars, barcode, null,null,null);
          } else if (bctype.equals("BATCHNUMBER") && getLocalSessionVariable(vars, "pdcdirection").equals("C-") &&
     		     PdcINOUTData.isFirstProductBatch(this,barcode, GlobalINOUTID, usecase, vars.getSessionValue("pdcinoutfirstline")).equals("Y") ) {
        	  // Charge, WB Kunde: Nur Charge Eintragen (Mengen setzen und Zeile definieren erfolgt mit Scan Artikelbarcode)
        	  String lineID=PdcINOUTData.getFirstLineID(this, GlobalINOUTID, usecase, vars.getSessionValue("pdcinoutfirstline"));
        	  updateSnrQtys(vars,lineID,GlobalUserID, bar.qty, barcode, null); 
        	  strsnrbnr=InfoBarHelper.getSnrBnrStr(this, vars, null, barcode, bar.qty.isEmpty()?"1":bar.qty,null);
          } else if ((bctype.equals("UNKNOWN")||bctype.equals("BATCHNUMBER")||bctype.equals("SERIALNUMBER"))  && getLocalSessionVariable(vars, "pdcdirection").equals("V+")){
        	  //  Zeile und Artikelmange definieren erfolgt mit Scan Artikelbarcode 
        	  String lineID=PdcINOUTData.getFirstLineID(this, GlobalINOUTID, usecase, vars.getSessionValue("pdcinoutfirstline"));
        	  String sb=PdcINOUTData.getSnrBnr4ProductFromLine(this, lineID);
        	  if (sb.equals("YY")) {
        		  vars.setSessionValue("PDCSTATUS","ERROR");
            	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcnotapplicable",vars.getLanguage()) + "Snr+Cnr");       
        	  } else if (sb.equals("NN")) {
        		  vars.setSessionValue("PDCSTATUS","ERROR");
              	  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode); 
        	  } else if (sb.equals("YN")) {
        		  updateSnrQtys(vars,lineID,GlobalUserID, "1", null, barcode); 
        		  strsnrbnr=InfoBarHelper.getSnrBnrStr(this, vars, barcode, null,null,null);
        	  } else if (sb.equals("NY")) {
        		  updateSnrQtys(vars,lineID,GlobalUserID, bar.qty, barcode, null); 
        		  strsnrbnr=InfoBarHelper.getSnrBnrStr(this, vars, null, barcode,null,null);
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
          else  {
        	if (!barcode.isEmpty()) {
        		vars.setSessionValue("PDCSTATUS","ERROR");
            	vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_bcunknown",vars.getLanguage())+"-"+barcode);   
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
            
            // If the Process brings an error, stay in this servlet and diplay the message to the user
            mymess=vars.getMessage(getServletInfo());
            if (mymess!=null) {
              if (mymess.getType().equals("Error")) {
                iserror=true;
                vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",mymess.getMessage());
              }
              vars.setMessage(getServletInfo(), null);
            }
          } else {
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_NoData",vars.getLanguage()));
          }
          if (! iserror) {
        	  removeSessionVars(vars);
        	  response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
          }   
      }
      
      if (vars.commandIn("CANCEL")||BcCommand.equals("CANCEL")) {
    	PdcINOUTData.deleteAllSnrLines(this, GlobalINOUTID);
    	PdcINOUTData.resetPickCounts(this, GlobalINOUTID);
    	PdcINOUTData.resetTrxPicking(this, GlobalUserID,GlobalINOUTID);
    	removeSessionVars(vars);
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_TransactionAborted",vars.getLanguage()));        
        response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
      }
      if (vars.commandIn("PAUSE")) {      	
      	  removeSessionVars(vars);
          vars.setSessionValue("PDCSTATUS","OK");
          vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_pause",vars.getLanguage()));        
          response.sendRedirect(strDireccion + "/ad_forms/PDCStoreMainDialoge.html");
        }
    }
    // Present Errors on the User Screen
    catch (Exception e) { 
    	e.printStackTrace();
    	vars.setSessionValue("PDCSTATUS","ERROR");
	    vars.setSessionValue("PDCSTATUSTEXT",Utility.translateError(this, vars,vars.getLanguage(),e.getMessage()).getMessage());
    } 
    try {
      // Start Building GUI
      EditableGrid lowergrid;
      lowergrid = new EditableGrid("PdcINOUTGridMobile", vars, this);  // Load lower grid structure from AD (use AD name)
      lowerGridData = PdcINOUTData.select(this, vars.getLanguage(),GlobalINOUTID,usecase,vars.getSessionValue("pdcinoutfirstline"));
      strLowerGrid = lowergrid.printGrid(this, vars, script, lowerGridData);                    // Generate lower grid html code
      // Info Bar
      String big1,big2,small1="",small2="",small3="";
      if (getLocalSessionVariable(vars, "pdcdirection").equals("C-"))
    	  big1 = Utility.messageBD(this, "pdc_Customer",vars.getLanguage()) ;
      else
    	  big1 = Utility.messageBD(this, "pdc_vendor",vars.getLanguage()) ;
      if (!FormatUtils.isNix(GlobalINOUTID) && (lowerGridData.length==0 || lowerGridData[0].getField("todos").equals("READY")))
    	  big2=Utility.messageBD(this, "pdc_ScanComplete",vars.getLanguage());
      else
    	  if (FormatUtils.isNix(GlobalINOUTID)) {
	          big2 =  Utility.messageBD(this, "pdc_settrxfirst",vars.getLanguage());
    	  } else {
    		  big2=Utility.messageBD(this, "pdc_ScanyellowItem",vars.getLanguage());
    	  }      
	  if (!FormatUtils.isNix(GlobalINOUTID))
		  small1=PdcINOUTData.getDocno(this, GlobalINOUTID)+" : " +PdcINOUTData.getTotal(this, vars.getLanguage(),GlobalINOUTID);
      if (!getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid").isEmpty())
    	  small2 = Utility.messageBD(this, "Product",vars.getLanguage())  +": " + PdcCommonData.getProduct(this, getLocalSessionVariable(vars, "pdcmaterialconsumptionproductid"), vars.getLanguage());
      small3=strsnrbnr;
      strPdcInfobar=InfoBarHelper.upperInfoBarApp(this, vars, script, big1, big2, small1, small2, small3);
      // Set Status Session Vars
      vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
      vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
      
      // Generate servlet skeleton html code
      strQuit="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
      strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "UserID",strQuit, "VendorCustomerMovements", "", "REMOVED", null,"true");   // Generate skeleton
      // Generate Header FG
      strHeaderFG = fh.prepareFieldgroup(this, vars, script, "PdcMINOUTHeader", null, false);        // Generate header html code      
      // Generate status html code
      strStatusFG = PdcStatusBar.getStatusBarAPP(request,this, vars, script);       
      // On Error display Status in Upper screen
      if (! vars.getSessionValue("PDCSTATUS").equals("OK")) {
    	  strPdcInfobar= strPdcInfobar + strStatusFG;
    	  strStatusFG="";
      }
      //    
      // Responsive Settings for Mobile Scanner Devices
      strHeaderFG=MobileHelper.setMobileModeAndScanActionBarcode(request, vars, script, strHeaderFG);
      
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

  private void updateSnrQtys(VariablesSecureApp vars,String lineID,String GlobalUserID, String qty, String btch, String snr) throws ServletException{
	  String mvmtqty=PdcINOUTData.getMvMtQtyFromLine(this, lineID);
	  String qtys=PdcINOUTData.getSerialLineQtys(this, lineID);
	  // Gewicht geht halt noch nicht....
	  if (qtys.isEmpty())
		  qtys="0";
	  if (!FormatUtils.isNix(snr)) {		  
		  // SNR immer eine Zeile pro Item, Doppelscans ohne Aktion
		  if (FormatUtils.isNix(PdcINOUTData.getSerialLine(this, lineID, snr))) {
			  // Über-Menge ablehnen
			  if (Integer.parseInt(mvmtqty)<Integer.parseInt(qtys)+1) {
				  vars.setSessionValue("PDCSTATUS","WARNING");
                  vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_tooManyItems",vars.getLanguage()));
			  } else 
				  PdcINOUTData.insertSerialLine(this, lineID, GlobalUserID, "1", btch, snr);	  
		  }	else { 
			  // Vorh. SNR Löschen bei Eingabe=0
			  if (!FormatUtils.isNix(qty) && Integer.parseInt(qty)==0)
				  PdcINOUTData.deleteSerialLine(this, lineID, snr);
			  else {
				  vars.setSessionValue("PDCSTATUS","WARNING");
	              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_DoubleScan",vars.getLanguage()));
			  }
		  }
		  qtys=PdcINOUTData.getSerialLineQtys(this, lineID);
		  if (qtys.isEmpty())
			  qtys="0";
		  PdcINOUTData.updateInOutLine(this, GlobalUserID,qtys, null, lineID);// Update Qty			
	  } else if (FormatUtils.isNix(snr)&& !FormatUtils.isNix(btch)) {			  
		  // Über-Menge ablehnen
		  boolean overqty=false;
		  if (FormatUtils.isNix(qty)) { // increment
			  if (Double.parseDouble(mvmtqty)<Double.parseDouble(qtys)+1.0)
				  overqty=true;  
		  } else {
			  String btchqty=PdcINOUTData.getLotQty(this, lineID, btch);
			  if (FormatUtils.isNix(btchqty)) 
				  btchqty="0";
			  Double btqty=Double.parseDouble(btchqty);
			  Double newqty=Double.parseDouble(qty);
			  if (Double.parseDouble(mvmtqty)<Double.parseDouble(qtys)+(newqty-btqty))
				  overqty=true; 
		  }
		  if (overqty) {
			  vars.setSessionValue("PDCSTATUS","WARNING");
              vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_tooManyItems",vars.getLanguage()));
		  } else {
			  // Chargen: Menge 0 Löschen
			  if (!FormatUtils.isNix(qty) && Integer.parseInt(qty)==0)	{
				  PdcINOUTData.deleteBtchLine(this, lineID, btch);				 
			  }  
			  // Ohne Mengenangabe: Inkrement
			  if (FormatUtils.isNix(qty)) {
				  String btchqty=PdcINOUTData.getLotQty(this, lineID, btch);
				  if (FormatUtils.isNix(btchqty)) 
					  PdcINOUTData.insertSerialLine(this, lineID, GlobalUserID, "1", btch, null);
				  else
					  PdcINOUTData.incrementBtchLine(this, lineID,btch);
			  // Mit Mengenangabe: Setzen der Menge
			  } if (!FormatUtils.isNix(qty) && Double.parseDouble(qty)>0.0) {            			  
				  PdcINOUTData.deleteBtchLine(this, lineID, btch);
				  PdcINOUTData.insertSerialLine(this, lineID, GlobalUserID, qty, btch, null);
			  }
			  String actqty=PdcINOUTData.getSerialLineQtys(this, lineID);
			  if (actqty.isEmpty())
				  actqty="0";
			  PdcINOUTData.updateInOutLine(this, GlobalUserID, actqty, null, lineID);
		  }
	  }
	  return;
  }
  private void removeSessionVars(VariablesSecureApp vars) {
	  deleteLocalSessionVariable(vars,"pdcdirection");
	  deleteLocalSessionVariable(vars, "pdcmaterialconsumptionproductid");
      vars.removeSessionValue("pdcinoutfirstline");
      deleteLocalSessionVariable(vars, "pdcinouttrx");
  }
  
  public String getServletInfo() {
    return this.getClass().getName();
  }
  
  
}

