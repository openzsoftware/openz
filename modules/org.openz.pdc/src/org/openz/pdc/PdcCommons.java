package org.openz.pdc;

import java.io.IOException;
import java.sql.Connection;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openz.pdc.controller.DoProductionData;
import org.openz.pdc.controller.PdcCommonData;
import org.openz.pdc.controller.PdcMaterialConsumptionData;
import org.openz.pdc.controller.PdcMaterialReturnData;
import org.openz.pdc.controller.SerialNumberData;
import org.openz.pdc.controller.TimeFeedbackData;
import org.openz.util.FormatUtils;
import org.openz.util.ProcessUtils;
import org.openz.util.UtilsData;

public class PdcCommons {
    
public static String getQtyIncrement(String qtyIn, String productId, String GlobalConsumptionID, HttpSecureAppServlet con) 
            throws ServletException, IOException {
    //if (qty.isEmpty())
    //	qty=PdcMaterialReturnData.getRetQty(this, bcid ,GlobalConsumptionID, snrbnr, GlobalWorkstepID);
    if (qtyIn.isEmpty()) {// Increment an multpl. scan on same Product by one
        if (PdcMaterialConsumptionData.getQtyInTrx(con, GlobalConsumptionID, productId).isEmpty())    
        return "1";
        else {
        Float fq=Float.parseFloat(PdcMaterialConsumptionData.getQtyInTrx(con, GlobalConsumptionID, productId)) + 1;
        return fq.toString();
        }
    } else
        return qtyIn;
}

public static void setWorkstepVars(String newWorkstepID,String newProductID,String snrbnr, VariablesSecureApp vars,HttpSecureAppServlet con) 
        throws ServletException, IOException {
	vars.removeSessionValue( con.getServletInfo() + "|plannedserialorbatch");
	vars.removeSessionValue("pdcAssemblySerialOrBatchNO");
	if (!FormatUtils.isNix(newWorkstepID)) {
	  String product=PdcCommonData.getProductFromWorkstep(con, newWorkstepID);
	  if (product==null)
		  product=PdcCommonData.getProductFromDurchreicheWorkstep(con, newWorkstepID);
	  if (product==null)
		  throw new ServletException("Kein Artikel gefunden");
	  vars.setSessionValue("pdcAssemblyProductID",product);
	  vars.setSessionValue("PDCWORKSTEPID",newWorkstepID);
	  if (!product.isEmpty() && PdcCommonData.isSerialOrBatch(con,  product).equals("Y"))
		  vars.setSessionValue("ISSNRBNR","Y");
	  else
		  vars.removeSessionValue("ISSNRBNR");
	}
	if (!FormatUtils.isNix(newProductID)&&FormatUtils.isNix(snrbnr)&&FormatUtils.isNix(newWorkstepID)) {
		String workstep=PdcCommonData.getWorkstepFromProduct(con, newProductID);
		if (! FormatUtils.isNix(workstep)) {
		  vars.setSessionValue("PDCWORKSTEPID",workstep);   
      	  vars.setSessionValue("pdcAssemblyProductID",newProductID);
      	  if (PdcCommonData.isSerialOrBatch(con,  newProductID).equals("Y"))
      		  vars.setSessionValue("ISSNRBNR","Y");
      	else
  		  vars.removeSessionValue("ISSNRBNR");
		}
	}
    if (!FormatUtils.isNix(newProductID)&& !FormatUtils.isNix(snrbnr) && FormatUtils.isNix(newWorkstepID)) {
    	String workstep=PdcCommonData.getWorkstepFromKombi(con, newProductID, snrbnr);
        if (! FormatUtils.isNix(workstep))  {   
      	  vars.setSessionValue("pdcAssemblyProductID",newProductID);
          vars.setSessionValue("pdcAssemblySerialOrBatchNO",snrbnr);
          vars.setSessionValue("PDCWORKSTEPID",workstep);  
          vars.setSessionValue("ISSNRBNR","Y");
          // Given Serial as PalinText or snr_planedserials_v_id
          // snrbnr is always plain and setr as var
    	  vars.setSessionValue( con.getServletInfo() + "|plannedserialorbatch",snrbnr);
    	  // For Dropdowns (not Consumption) The view ID is set    	  
          if (!con.getClass().getName().contains("PdcMaterialConsumption")) {
        	  String vId=PdcCommonData.getPlannedSerialVIdfromsnr(con, snrbnr, workstep);
        	  if (FormatUtils.isNix(vId))
        		  vars.removeSessionValue( con.getServletInfo() + "|plannedserialorbatch");
        	  else
        		  vars.setSessionValue( con.getServletInfo() + "|plannedserialorbatchno",vId);
          }  
        }
	}
	  
	  
}


public void InternalConsumptionNext(String GlobalWorkstepID, String PdcUserID, String strpdcFormerDialogue, 
                                    String GlobalLocatorID,String snrbnr, String WorkstepIDADName,String QuantityADName, String ProductID,
                                    VariablesSecureApp vars,HttpServletResponse response ,HttpSecureAppServlet con) 
        throws ServletException, IOException {
    String GlobalConsumptionID=vars.getSessionValue("pdcConsumptionID");
    String QuantityAD=con.getLocalSessionVariable(vars, QuantityADName);
    String WorkstepID=GlobalWorkstepID;
    if (!FormatUtils.isNix(WorkstepID))
    	  if (PdcCommonData.isWorkstepClosed(con, WorkstepID).equals("Y")) {
    		vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "WorkStepClosed",vars.getLanguage()));
            return ;
    	  }
    if (FormatUtils.isNix(GlobalLocatorID)||FormatUtils.isNix(ProductID)||FormatUtils.isNix(QuantityAD)||FormatUtils.isNix(WorkstepID)||FormatUtils.isNix(PdcUserID)){         
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_MustSetProductQtyAndLocator",vars.getLanguage()));
            } else { 
            if (GlobalConsumptionID.equals("")) {
                GlobalConsumptionID = UtilsData.getUUID(con);
                if (con.getServletInfo().contains("PdcMaterialReturn"))
                    PdcMaterialReturnData.insertConsumption(con, GlobalConsumptionID, vars.getClient(),vars.getOrg(), PdcUserID,PdcCommonData.getProductionOrderFromWorkstep(con,WorkstepID),WorkstepID,vars.getSessionValue("pdcAssemblySerialOrBatchNO"));
                else
                    PdcMaterialConsumptionData.insertConsumption(con, GlobalConsumptionID, vars.getClient(),vars.getOrg(), PdcUserID,PdcCommonData.getProductionOrderFromWorkstep(con,WorkstepID),WorkstepID,vars.getSessionValue("pdcAssemblySerialOrBatchNO"));
                vars.setSessionValue("pdcConsumptionID", GlobalConsumptionID);
            }
                // Check if KOMBI Code was Scanned...
                String bnr=null;
                String snr=null;
                if (!snrbnr.isEmpty()) { // Add Serial / Batch from KOMBI
                if (PdcCommonData.isSerial(con, ProductID).equals("Y"))
                    snr=snrbnr;
                else
                    bnr=snrbnr;
                }
                // Check if Value Updates a line or deletes a line
                String sameline=PdcCommonData.getIDWhenScannedSameLine(con, GlobalConsumptionID, ProductID, GlobalLocatorID);
                if (sameline==null) sameline="";
                String qty=QuantityAD;
                Float fq=Float.parseFloat(qty);
                // Qty > 0 and new line
                if (sameline.equals("") && fq>0) {
                PdcCommonData.insertMaterialLine(con, vars.getClient(), vars.getOrg(), 
                        PdcUserID,GlobalConsumptionID,GlobalLocatorID,ProductID,
                    PdcCommonData.getNextLineFromConsumption(con, GlobalConsumptionID),
                    qty,PdcCommonData.getProductStdUOM(con, ProductID),PdcCommonData.getProductionOrderFromWorkstep(con,con.getLocalSessionVariable(vars, WorkstepIDADName)),
                    con.getLocalSessionVariable(vars, WorkstepIDADName));
                if (snrbnr.isEmpty() && PdcCommonData.isbatchorserialnumber(con, GlobalConsumptionID).equals("Y")){
                    vars.setSessionValue("PDCSTATUS","OK");
                    vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_TransactionPreparedSerialNumberNecessary",vars.getLanguage()));
                    vars.setSessionValue("PDCINVOKESERIAL","DONE");
                    //second layer
                    if (strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMainDialogue.html")){
                            vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/PdcMaterialConsumption.html");
                            strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
                    }
                    response.sendRedirect(con.strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");
                }
                if (!snrbnr.isEmpty()) { // Add Serial / Batch from KOMBI
                    if (snr!=null)
                        qty="1";
                    sameline=PdcCommonData.getIDWhenScannedSameLine(con, GlobalConsumptionID, ProductID, GlobalLocatorID);
                    SerialNumberData.insertSerialLine(con, vars.getClient(), vars.getOrg(), PdcUserID, sameline, qty, bnr, snr);
                }
                vars.setSessionValue("PDCSTATUS","OK");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_ProductScannedCorrectly",vars.getLanguage()));
                }
                else if (fq>0) {
                // Checks for KOMBI
                String userTypedQty=vars.getNumericParameter("inp" + QuantityADName);
                String currsnrbnrqty=SerialNumberData.getCurrentBatchOrSerialQtys(con, sameline);
                Float userQty=null;
                Float currQty=null;
                if (currsnrbnrqty!=null && ! currsnrbnrqty.isEmpty())
                    currQty=Float.parseFloat(currsnrbnrqty);
                if (userTypedQty!=null && ! userTypedQty.isEmpty())
                    userQty=Float.parseFloat(userTypedQty);
                // Seriennummern: Seriennummer hinzufügen / entfernen wenn schon ex., Menge Entnahme entsprechen hochzählen/runterzählen. Eingabe der Menge wird bei Kombi-Barcodes mit Seriennummer ignoriert.
                // CNR: Nutzer gibt Menge ein: CNR-Menge setzen, CNR der menge zuordnen
                // CNR: Nutzer gibt keine Menge ein: Vorh CNR's entfernen, Neue CNR der kompletten Entnahme-Menge zuordnen
                // CNR: Die Entnahmemenge bei CNR's kann nur beim ersten Scan des Artikels angegeben werden.
                // CNR: Entnahmemengen-Korrektur: 0 Eingeben, Artikel-Kombi Scannen, Entnahmemenge Eingeben, Artikel-Kombi Scannen
                // CNR-Aufteilung: Menge<Entnahmemenge Eingeben, ertsen KOMBI noch mal scannen  (CNR wird der Menge zugeordnet), Dann Mengeneingabe, nächste CNR usw.
                if (snr!=null) {
                    if (SerialNumberData.snrExists(con, snr, sameline).equals("Y")) {
                        SerialNumberData.deleteSerialLine(con, sameline, null, snr);
                        SerialNumberData.decrementCurrentMovementQty(con,null, sameline);
                        String lineqty=SerialNumberData.getCurrentMovementQty(con, sameline);
                        Float flq=Float.parseFloat(lineqty);
                        if (flq<=0) 
                            PdcCommonData.deleteMaterialLine(con, sameline);
                    } else {
                    	String mvqty=SerialNumberData.getCurrentMovementQty(con, sameline);
                    	if (FormatUtils.isNix(mvqty))
                    		mvqty="0";
                    	String snrbnrqty=SerialNumberData.getCurrentBatchOrSerialQtys(con, sameline);
                    	if (FormatUtils.isNix(snrbnrqty))
                    		snrbnrqty="0";
                    	if (Float.parseFloat(mvqty)==Float.parseFloat(snrbnrqty))
                    		SerialNumberData.incrementCurrentMovementQty(con, null,sameline);
                        SerialNumberData.insertSerialLine(con, vars.getClient(), vars.getOrg(), PdcUserID, sameline, "1", bnr, snr);
                    }
                } else if(bnr!=null) {
                    String currqty=SerialNumberData.getBatchQty(con, sameline, bnr);
                    if (userQty!=null) {
                        if (currqty!=null)
                            SerialNumberData.deleteSerialLine(con, sameline, bnr, null);
                        String allqty=SerialNumberData.getCurrentMovementQty(con, sameline);
                        Float allq=Float.parseFloat(allqty);
                        String bqty=SerialNumberData.getCurrentBatchOrSerialQtys(con, sameline);
                        if (FormatUtils.isNix(bqty))
                        	bqty="0";
                        Float bq=Float.parseFloat(bqty);
                    	Float uq=   userQty+bq;
                        if (uq > allq) {
                        	PdcCommonData.updateMaterialLine( con,  uq.toString(),sameline);	
                        }
                        SerialNumberData.insertSerialLine(con, vars.getClient(), vars.getOrg(), PdcUserID, sameline, qty, bnr, snr);
                    } else {
                        String allqty=SerialNumberData.getCurrentMovementQty(con, sameline);
                        SerialNumberData.deleteAllSerialLine(con, sameline);
                        SerialNumberData.insertSerialLine(con, vars.getClient(), vars.getOrg(), PdcUserID, sameline, allqty, bnr, snr);
                    }
                } else // Non SNR/BNR
                    // Update existing Line with new QTY ( On BATCH this is only DONE on insert)
                    PdcCommonData.updateMaterialLine( con,  qty,sameline);
                vars.setSessionValue("PDCSTATUS","OK");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_ProductQtyUpdated",vars.getLanguage()));
                }
                else {
                // Delete line (QTY<=0)
                PdcCommonData.deleteMaterialLine(con, sameline);
                vars.setSessionValue("PDCSTATUS","OK");
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_ProductLineDeletedQtyZERO",vars.getLanguage()));
                }
            }
}


public void setInternalConsumptionDone(String GlobalConsumptionID,String GlobalWorkstepID, String PdcUserID, String strpdcFormerDialogue,String mapping, VariablesSecureApp vars,HttpServletResponse response,HttpSecureAppServlet con ) 
                                        throws ServletException, IOException {
    if (PdcCommonData.isbatchorserialnumber(con, GlobalConsumptionID).equals("N")){
        OBError mymess=null;
        boolean iserror=false;
        String msgtext="\n";
        if (!GlobalConsumptionID.equals("")) {
            if (TimeFeedbackData.isWorstepStarted(con, GlobalWorkstepID).equals("N")) {
            TimeFeedbackData[] res=TimeFeedbackData.beginWorkstepNoMat(con, GlobalWorkstepID, PdcUserID, vars.getOrg());
            if (res.length>0){
                msgtext="-"+Utility.messageBD(con, "WorkStepStarted",vars.getLanguage());
                }
            }
            // Set serisnumber
            String snrbnr=con.getLocalSessionVariable(vars,"plannedserialorbatch");
            if (!FormatUtils.isNix(snrbnr)) {
            	PdcCommonData.updateSnrBnr(con, snrbnr, GlobalConsumptionID);
            	if (PdcMaterialConsumptionData.isSerielProduced(con, snrbnr, GlobalWorkstepID).equals("Y"))
            		  throw new ServletException("@plannedserialisproduced@");
            }
            // Start internal Consumption Post Process directly - Process Internal Consumption
            ProcessUtils.startProcessDirectly(GlobalConsumptionID, "800131", vars, con); 
            // PdcCommonData.doConsumptionPost(con, strConsumptionid);
            vars.setSessionValue("PDCSTATUS","OK");
            if (con.getServletInfo().contains("PdcMaterialReturn"))
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_MaterialReturnSucessful",vars.getLanguage())+msgtext);
            else
                vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_MaterialGotSucessful",vars.getLanguage())+msgtext);
            // If the Process brings an error, stay in this servlet and diplay the message to the user
            mymess=vars.getMessage(con.getServletInfo());
            if (mymess!=null && mymess.getType().equals("Error")) {
                iserror=true;
                vars.setSessionValue("PDCSTATUS","ERROR");
                vars.setSessionValue("PDCSTATUSTEXT",mymess.getMessage());
                vars.removeMessage(con.getServletInfo());
            }
        } else {
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_NoData",vars.getLanguage()));
        }
        if (! iserror)
            response.sendRedirect(con.strDireccion + strpdcFormerDialogue);
        } else {
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_TransactionPreparedSerialNumberNecessary",vars.getLanguage()));
        vars.setSessionValue("PDCINVOKESERIAL","DONE");
        //second layer
        if (strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMainDialogue.html")){
            vars.setSessionValue("PDCFORMERDIALOGUE",mapping);
            strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
        }
        response.sendRedirect(con.strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");
        }
}

public String prepareProduction(VariablesSecureApp vars,String qty, String strpdcWorkstepID, String strProductionid,String strpdcUserID,String strProductID,String strLocatorID,HttpSecureAppServlet con,Connection conn) throws ServletException{
    if (FormatUtils.isNix(strpdcWorkstepID))
        strpdcWorkstepID=vars.getSessionValue("PDCWORKSTEPID");
    if (!FormatUtils.isNix(strpdcWorkstepID))
  	  if (PdcCommonData.isWorkstepClosed(con, strpdcWorkstepID).equals("Y")) {
  		vars.setSessionValue("PDCSTATUS","ERROR");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "WorkStepClosed",vars.getLanguage()));
        return null;
  	  }
    if (FormatUtils.isNix(strProductionid))
        strProductionid="";
    if (FormatUtils.isNix(strpdcUserID))
        strpdcUserID=vars.getSessionValue("pdcUserID");
    String assproduct=strProductID;
    
    if (FormatUtils.isNix(assproduct)) {
    	assproduct=DoProductionData.getAssemblyProductFromWorkstep(con, strpdcWorkstepID);
    	if (FormatUtils.isNix(assproduct))
    		assproduct=PdcCommonData.getProductFromDurchreicheWorkstep(con, strpdcWorkstepID);
    }
    if (FormatUtils.isNix(strLocatorID))
        strLocatorID=DoProductionData.getLocator(con, strpdcWorkstepID);
    String possibQty=DoProductionData.getQty(conn,con, strpdcWorkstepID, strProductionid, "", assproduct,strLocatorID);
    String strQty;
    if (FormatUtils.isNix(possibQty))
    	possibQty="0";
    if (!FormatUtils.isNix(qty))
        strQty=qty;
    else
        strQty=vars.getNumericParameter("inppdcproductionquantity");
    if (FormatUtils.isNix(strQty)||Float.parseFloat(strQty)>Float.parseFloat(possibQty))
    	strQty=possibQty;
    if (PdcCommonData.isserialtracking(con, assproduct).equals("Y") && UtilsData.getOrgConfigOption(con, "serialbomstrict", vars.getOrg()).equals("Y")) { 
    	strQty="1";    	
    }
    if (PdcCommonData.isbatchtracking(con, assproduct).equals("Y") && UtilsData.getOrgConfigOption(con, "serialbomstrict", vars.getOrg()).equals("Y")) {
    	String snrbnr=con.getLocalSessionVariable(vars,"plannedserialorbatch");
    	if (!FormatUtils.isNix(snrbnr)) {
    		String strPQty=DoProductionData.getStrictBATCHPossibleQty(conn,con, strpdcWorkstepID, snrbnr); 
    		if (!FormatUtils.isNix(strPQty)) {
	    		Float pq=Float.parseFloat(strPQty);
	            Float qq=Float.parseFloat(strQty);
	            if (pq<qq) 
	            	strQty=strPQty;  
    		}
    	} else
    		strQty="";
    }
    if (!FormatUtils.isNix(possibQty) && !strQty.isEmpty()) {
        Float pq=Float.parseFloat(possibQty);
        Float qq=Float.parseFloat(strQty);
        if (qq>pq) {
            strQty=null;
            vars.setSessionValue("PDCSTATUS","ERROR");
            vars.setSessionValue("PDCSTATUSTEXT","Menge > möglicher Menge");
            return null;
        }
    // Create a new P+ Transaction, if we have none
    if (! (FormatUtils.isNix(strpdcWorkstepID)||FormatUtils.isNix(strpdcUserID)|| FormatUtils.isNix(strQty)  || FormatUtils.isNix(strLocatorID))) {
    if (strProductionid.isEmpty()) {
        strProductionid=UtilsData.getUUID(con);
        PdcCommonData.insertProduction(conn, con, strProductionid, vars.getClient(), vars.getOrg(), 
                strpdcUserID, PdcCommonData.getProductionOrderFromWorkstep(con,strpdcWorkstepID ),strpdcWorkstepID,vars.getSessionValue("pdcAssemblySerialOrBatchNO"));
        vars.setSessionValue("pdcProductionID", strProductionid);
    }
    PdcCommonData.insertMaterialLine(conn, con, vars.getClient(), vars.getOrg(), 
            strpdcUserID,strProductionid,strLocatorID,assproduct,
            PdcCommonData.getNextLineFromConsumption(conn,con, strProductionid),
            strQty,PdcCommonData.getProductStdUOM(con, assproduct),PdcCommonData.getProductionOrderFromWorkstep(con,strpdcWorkstepID ),
            strpdcWorkstepID);
    } else {
        PdcCommonData.deleteAllMaterialLines(conn,con,strProductionid);
        PdcCommonData.deleteMaterialTransaction(conn,con,strProductionid);
        vars.removeSessionValue("pdcProductionID");
    }
    }
    // Durchreiche Arbeitsgänge
    /*
    if (DoProductionData.isMovingWorkstep(con, strpdcWorkstepID).equals("Y")) {
        String strConsumptionid=UtilsData.getUUID(con);
        PdcCommonData.insertMaterailReturn( con, strConsumptionid, vars.getClient(), vars.getOrg(), 
            strpdcUserID, PdcCommonData.getProductionOrderFromWorkstep(con,strpdcWorkstepID ),strpdcWorkstepID);
        vars.setSessionValue("pdcConsumptionID", strConsumptionid);
        DoProductionData[] data=DoProductionData.getMovingWorkstepProduct(con, strpdcWorkstepID);
        for (int i=0;i<data.length;i++) {
            //strLocatorID=DoProductionData.getMovingWorkstepIssuingLoc(con, strpdcWorkstepID);
            strQty=DoProductionData.getQty(con, strpdcWorkstepID, strProductionid, "", data[i].mProductId,data[i].mLocatorId);
            if (strQty!=null && !strQty.isEmpty()) {   
                PdcCommonData.insertMaterialLine( con, vars.getClient(), vars.getOrg(), 
                        strpdcUserID,strConsumptionid,data[i].mLocatorId,data[i].mProductId,
                        PdcCommonData.getNextLineFromConsumption(con, strConsumptionid),
                        strQty,PdcCommonData.getProductStdUOM(con, data[i].mProductId),PdcCommonData.getProductionOrderFromWorkstep(con,strpdcWorkstepID ),
                        strpdcWorkstepID);
            }
        }
    }
    */
    return strProductionid;
} // end of prepareProduction method



public void finishProduction(HttpServletResponse response, String ptrxID,String strpdcWorkstepID,String bcCommand,String strpdcUserID,VariablesSecureApp vars,HttpSecureAppServlet con,Connection conn) throws ServletException, IOException{
    String strpdcFormerDialogue=vars.getSessionValue("PDCFORMERDIALOGUE");
    if (FormatUtils.isNix(strpdcWorkstepID))
        strpdcWorkstepID=vars.getSessionValue("PDCWORKSTEPID");
    if (bcCommand==null)
        bcCommand="DONE";
 // Set serisnumber
    String snrbnr=con.getLocalSessionVariable(vars,"plannedserialorbatch");
    if (!FormatUtils.isNix(snrbnr)) {
    	PdcCommonData.updateSnrBnr(conn,con, snrbnr, ptrxID);
    	String prod=PdcCommonData.getProductFromWorkstep(con, strpdcWorkstepID);
    	String stype=SerialNumberData.pdc_getSerialBatchType4product(con, prod);
    	if (!FormatUtils.isNix(stype)) {
    		String consumptionLineId=PdcCommonData.getIDWhenScannedSameLineWoLocator(conn,con, ptrxID, prod);
    		String qty=PdcCommonData.getlineQtyByProduct(conn,con, ptrxID, prod);
    		String batchno=null;
    		String serialno=null;
    		if (stype.equals("SERIAL"))
    			serialno=snrbnr;
    		if (stype.equals("BATCH"))
    			batchno=snrbnr;
    		SerialNumberData.insertSerialLine(conn,con, vars.getClient(), vars.getOrg(), vars.getUser(), consumptionLineId, qty, batchno, serialno);
    		// Fit qtys to planned serial ?
	    	if (UtilsData.getOrgConfigOption(con, "serialbomstrict", vars.getOrg()).equals("Y")) { 
	        	if (DoProductionData.isProductionPlannedSerialPossible(conn,con, strpdcWorkstepID, snrbnr,qty)
	        			.equals("N")) {
	        		String mxqty=DoProductionData.getProductionPlannedSerialQty(conn,con, strpdcWorkstepID, snrbnr);
	        		vars.setSessionValue("PDCSTATUS","ERROR");
	                vars.setSessionValue("PDCSTATUSTEXT","Entnahme-Menge reicht für Produktion der geplanten SNR/CNR nicht aus:"+snrbnr + "(max. " + mxqty + ")");
	                return;
	        	}		
	        }
	    	if (PdcMaterialConsumptionData.isSerielProduced(con, snrbnr, strpdcWorkstepID).equals("Y"))
      		  throw new ServletException("@plannedserialisproduced@");
	    }
    }
    if (PdcCommonData.isbatchorserialnumber(conn,con, ptrxID).equals("N")){
        String message="";
        OBError mymess=null;
        DoProductionData upperGridData[] = DoProductionData.selectupper(conn,con,vars.getLanguage(),strpdcWorkstepID,ptrxID,"");
        int matleft=upperGridData.length;
        if (!ptrxID.equals("")) {
        //PdcCommonData.doConsumptionPost(con, ptrxID);
        String qtyp=DoProductionData.getQtyProduced(conn,con,vars.getLanguage(), ptrxID);
        String qadj=DoProductionData.adjustPassingworkstepQtys(conn,con, strpdcWorkstepID, qtyp,ptrxID);
        //ProcessUtils.startProcessDirectly(ptrxID, "800131", vars, con);  //  M_Internal_Consumption_Post
        PdcCommonData.doConsumptionPost(conn,con,ptrxID);
        message=UtilsData.getProcessResultWC(conn,con, ptrxID);
        // If the Process brings an error, stay in con servlet and diplay the message to the user
		if (message.startsWith("ERROR")) 
			throw new ServletException(message.replaceFirst("ERROR@", ""));
        String locato=DoProductionData.getLocatorProduced(conn,con, ptrxID);
        message=qtyp + " " + Utility.messageBD(con, "pdc_ProductionTransactionSucessful",vars.getLanguage())+ " In " + locato ;
        if (bcCommand.equals("CLOSEWS")){
            message=message + PdcCommonData.closeWorkstep(conn, con, strpdcWorkstepID,strpdcUserID,vars.getLanguage());
            if (matleft>0)
            	message=message + Utility.messageBD(con, "pdc_MaterialLeftInWokstep",vars.getLanguage());
            else
            	message=message + Utility.messageBD(con, "pdc_NoMaterialLeftInWokstep",vars.getLanguage());
        } else { // DONE
            if (DoProductionData.IsWSFinishedProd(conn,con, strpdcWorkstepID).equals("Y")) 
                    message=message + " " +PdcCommonData.closeWorkstep(conn, con, strpdcWorkstepID,strpdcUserID,vars.getLanguage());
        }
        /*
        if (bcCommand.equals("DONE") && matleft==0 && ! (strConsumptionid.isEmpty() && ptrxID.isEmpty())){
        Connection conn=con.getConnection();
        message=message + PdcCommonData.closeWorkstep(conn, con, strpdcWorkstepID,strpdcUserID,vars.getLanguage());
        conn.close();
        message=message + Utility.messageBD(con, "pdc_WokstepAutoClosed",vars.getLanguage()) ;
        }*/
        if (ptrxID.isEmpty()  && ! bcCommand.equals("CLOSEWS"))
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_NoData",vars.getLanguage()));
        else 
        vars.setSessionValue("PDCSTATUSTEXT",message);
        vars.setSessionValue("PDCSTATUS","OK");
        response.sendRedirect(con.strDireccion + strpdcFormerDialogue);
        }
    } else {
        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(con, "pdc_TransactionPreparedSerialNumberNecessary",vars.getLanguage()));
        vars.setSessionValue("PDCINVOKESERIAL",bcCommand);
        //second layer
        if (strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMainDialogue.html")||
            strpdcFormerDialogue.equals("/org.openz.pdc.ad_forms/PdcMaterialConsumption.html") ){
        vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.pdc.ad_forms/DoProduction.html");
        }
        response.sendRedirect(con.strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");
    }
}
public static PdcCommonData getBarcode(HttpSecureAppServlet con, VariablesSecureApp vars) throws ServletException, IOException {
	PdcCommonData[] data;
	String barcode=vars.getStringParameter("inppdcmaterialconsumptionbarcode");
    data = PdcCommonData.selectbarcode(con, barcode);
    String qty=vars.getNumericParameter("inppdcmaterialconsumptionquantity");
    if (! FormatUtils.isNix(data[0].serialnumber) && ! qty.equals("0"))
      qty="1";
    data[0].qty=qty;
    if (FormatUtils.isNix(data[0].barcode) )
    	data[0].barcode=barcode;    		
	return data[0];
}

}
