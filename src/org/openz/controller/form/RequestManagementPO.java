package org.openz.controller.form;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.utils.Replace;
import org.openz.util.LocalizationUtils;
import org.openz.util.UtilsData;
import org.openz.view.EditableGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFrameWindow;

public class RequestManagementPO extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,ServletException {
        VariablesSecureApp vars = new VariablesSecureApp(request);
        Scripthelper script = new Scripthelper(); // Injects Javascript, hidden fields, etc into the generated html
        Formhelper fh = new Formhelper();         // Builder for Fieldgroups
        String strOutput = "" ;                   // Resulting html output
        String strHeaderFG = "";                  // Header fieldgroup (defined in AD CreateDocumentfromSOHeaderFG)
        String strGrid="";						  // Grid in AD : CreateDocumentfromSOGrid
        String strActionButtons="";               // Bottom Fieldgroup (defined in AD CreateDocumentfromSOActionBtns)
        FieldProvider[] GridData;
        EditableGrid grid ;			
        OBError msg = new OBError();
        msg.setType("SUCCESS");
        response.setContentType("text/html; charset=UTF-8");
        // Updating Sales Offers/Orders and PO-Requests   
        if (vars.commandIn("SAVE")||vars.commandIn("CREATEPO")||vars.commandIn("CREATEDR")) {
             Vector <String> retval;
             try {
             Connection conn=this.getTransactionConnection();
             try {
            	 grid = new EditableGrid("RequstManagementPOGrid", vars, this);
            	 retval=grid.getSelectedIds(null, vars, "c_order_id");
            	 for (int i = 0; i < retval.size(); i++) {
            		 String poreference =grid.getValue(this, vars, retval.elementAt(i), "poreference");
            		 String currency =grid.getValue(this, vars, retval.elementAt(i), "currencypo");
            		 RequestManagementPOData.updateDocAction(conn,this, "RE", retval.elementAt(i));
            		 RequestManagementPOData.postAction(conn, this, retval.elementAt(i));
            		 RequestManagementPOData.updatePOHeader(conn, this, poreference,currency, retval.elementAt(i));
            	 }
            	 retval=grid.getSelectedIds(null, vars, "c_orderline_id");
            	 for (int i = 0; i < retval.size(); i++) {
            		 String soorderline=grid.getValue(this, vars, retval.elementAt(i), "soorderlineid");
            		 String description = grid.getValue(this, vars, retval.elementAt(i), "description");
            		 String auxfield1 = grid.getValue(this, vars, retval.elementAt(i), "auxfield1");
            		 String scheddeliverydatepo=  LocalizationUtils.convDateString2SQL(grid.getValue(this, vars, retval.elementAt(i), "scheddeliverydatePO"), this, vars);
            		 String scheddeliverydateso=  LocalizationUtils.convDateString2SQL(grid.getValue(this, vars, retval.elementAt(i), "scheddeliverydateSO"), this, vars);
            		 String qtyordered= grid.getValue(this, vars, retval.elementAt(i), "qtyordered");
            		 String poprice= grid.getValue(this, vars, retval.elementAt(i), "poprice");
            		 String discount =  grid.getValue(this, vars, retval.elementAt(i), "discount");
            		 String stdprice = grid.getValue(this, vars, retval.elementAt(i), "popricestd");
            		 if (discount.isEmpty()||new BigDecimal(discount).compareTo(new BigDecimal("0"))==0) {
            			if (Float.valueOf(stdprice)>0 && Float.valueOf(poprice)==0)
            				poprice=stdprice;
            			if (Float.valueOf(poprice)>0 && Float.valueOf(stdprice)==0)
            				stdprice=poprice;
            			if (Float.valueOf(poprice)>0 && Float.valueOf(stdprice)>0 && Float.valueOf(poprice) < Float.valueOf(stdprice)) 
            				discount = String.valueOf(100-Float.valueOf(poprice)*100/Float.valueOf(stdprice));
            			if (discount.isEmpty())
            				 discount="0";
            		 }            			 
            		 String connectedsoline= grid.getValue(this, vars, retval.elementAt(i), "connectedsoline");
            		 String isoptional= grid.getValue(this, vars, retval.elementAt(i), "isoptional");
            		 RequestManagementPOData.updatePO(conn, this, description, auxfield1, scheddeliverydatepo, qtyordered, poprice, stdprice, discount, retval.elementAt(i));
            		 String soprice = grid.getValue(this, vars, retval.elementAt(i), "soprice");
            		 RequestManagementPOData.updateSO(conn,this, retval.elementAt(i), soorderline, soprice, isoptional,scheddeliverydateso,vars.getUser(),description,connectedsoline);
            	 }
            	 retval=grid.getSelectedIds(null, vars, "c_order_id");
            	 for (int i = 0; i < retval.size(); i++) {
            		 RequestManagementPOData.updateDocAction(conn,this, "CO", retval.elementAt(i));
            		 RequestManagementPOData.postAction(conn, this, retval.elementAt(i));
            	 }
            	 conn.commit();
            	 conn.close();
            	 msg.setTitle("OK");
            	 msg.setMessage(LocalizationUtils.getMessageText(this, "OrderlineUpdatedSucessfully", vars.getLanguage()));
            	 vars.setMessage(this.getClass().getName(), msg);
             }
             catch (Exception e) { 
                 log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
                 e.printStackTrace();
                 try {conn.rollback();conn.close();} catch (Exception ign) {}
                 throw new ServletException(e);
             } 
             } catch (Exception e) { throw new ServletException(e);}
    }
    // Creating PO-Documents    
    if (vars.commandIn("CREATEPO")||vars.commandIn("CREATEDR")) {
         Vector <String> retval;
         try {
         Connection conn=this.getTransactionConnection();
         try {
        	 grid = new EditableGrid("RequstManagementPOGrid", vars, this);
        	 retval=grid.getSelectedIds(null, vars, "c_orderline_id");
        	 String selDocument="";
        	 String thisDocument="";
        	 String docID="";
        	 String msgtxt="";
        	 String soorderline="";
        	 for (int i = 0; i < retval.size(); i++) {			
        	   selDocument=  RequestManagementPOData.getOrderId(this, retval.elementAt(i));
        	   if (!selDocument.equals(thisDocument)) {
        		   if (!docID.isEmpty()) {
        			   RequestManagementPOData.postAction(conn, this, docID);
        			   RequestManagementPOData.checkPOOffersAndCloseFromSO(conn, this, soorderline,vars.getUser());
        		   }
        		   thisDocument=selDocument;
        		   soorderline=grid.getValue(this, vars, retval.elementAt(i), "soorderlineid");
           	   	   docID=RequestManagementPOData.c_createDocumentHeaderFromPO(conn, this, thisDocument, vars.commandIn("CREATEPO")?"POORDER":"DROPSHIP" , vars.getUser(),soorderline);
           	   	   msgtxt=msgtxt + RequestManagementPOData.getDocumentMsg(conn,this, docID);
        	   }
  		           String re=RequestManagementPOData.c_createDocumentLineFromPO(conn, this, docID, retval.elementAt(i));
  		     }
        	 if (!docID.isEmpty()) {
        	   if (UtilsData.getOrgConfigOption(this, "poactiveafterpurchaserun", vars.getOrg()).equals("Y"))
        		   RequestManagementPOData.postAction(conn, this, docID);
  			   RequestManagementPOData.checkPOOffersAndCloseFromSO(conn, this, soorderline,vars.getUser());
        	 }
        	 conn.commit();
        	 conn.close();
        	 msg.setTitle("OK");
        	 msgtxt=LocalizationUtils.getMessageText(this, "PurchaseDocumentsCreated", vars.getLanguage()) + msgtxt;
        	 msg.setMessage(msgtxt);
        	 vars.setMessage(this.getClass().getName(), msg);
         }
         catch (Exception e) { 
             log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
             e.printStackTrace();
             try {conn.rollback();conn.close();} catch (Exception ign) {}
             throw new ServletException(e);
         } 
         } catch (Exception e) { throw new ServletException(e);}
    }
   // Closing PO-Documents    
    if (vars.commandIn("CLOSEPOO")) {
         Vector <String> retval;
         try {
         Connection conn=this.getTransactionConnection();
         try {
        	 grid = new EditableGrid("RequstManagementPOGrid", vars, this);
        	 retval=grid.getSelectedIds(null, vars, "c_order_id");
        	 for (int i = 0; i < retval.size(); i++) {
        		 RequestManagementPOData.closePOO(conn, this, vars.getUser(),retval.elementAt(i));
        	 }
        	 conn.commit();
        	 conn.close();
        	 msg.setTitle("OK");
        	 msg.setMessage(LocalizationUtils.getMessageText(this, "RequestsClosed", vars.getLanguage()));
        	 vars.setMessage(this.getClass().getName(), msg);
         }
         catch (Exception e) { 
             log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
             e.printStackTrace();
             try {conn.rollback();conn.close();} catch (Exception ign) {}
             throw new ServletException(e);
         } 
         } catch (Exception e) { throw new ServletException(e);}
    }
    
    if (vars.commandIn("DEFAULT")|| vars.commandIn("FIND")) {
    	msg = new OBError();
    	vars.setMessage(this.getClass().getName(), msg);
    	if (vars.commandIn("FIND"))
    		removeSessionValues(vars);
    }
    // Build the GUI
    // Filter Vars
    String strpodocno=vars.getGlobalVariable("inppodocno", this.getClass().getName() + "|podocno", "");
    String strvendorId=vars.getGlobalVariable("inpvendorId", this.getClass().getName() + "|vendor_Id", "");
    String strdatefrom =vars.getDateParameterGlobalVariableAndFetchFromSessionIfEmpty("inpdatefrom", this.getClass().getName() + "|datefrom", "",this);
    String strdateto = vars.getDateParameterGlobalVariableAndFetchFromSessionIfEmpty("inpdateto", this.getClass().getName() + "|dateto", "",this);
    String strcProjectId=vars.getGlobalVariable("inpcProjectId", this.getClass().getName() + "|c_project_id", "");
    String strsodocno=vars.getGlobalVariable("inpsodocno", this.getClass().getName() + "|sodocno", "");
    String strcustomerId=vars.getGlobalVariable("inpcustomerId", this.getClass().getName() + "|customer_id", "");
    String strmProductId=vars.getGlobalVariable("inpmProductId", this.getClass().getName() + "|m_product_id", "");
    String stradOrgId=vars.getGlobalVariable("inpadOrgId", this.getClass().getName() + "|ad_org_id", "");
    String strauxfield1=vars.getGlobalVariable("inpauxfield1", this.getClass().getName() + "|auxfield1", "");
    String strauxfield2=vars.getGlobalVariable("inpauxfield2", this.getClass().getName() + "|auxfield2", "");
    String strauxfield3=vars.getGlobalVariable("inpauxfield3", this.getClass().getName() + "|auxfield3", "");
    try {
	    //Get Data
	    grid = new EditableGrid("RequstManagementPOGrid", vars, this);
	    if (!(vars.commandIn("DEFAULT") && UtilsData.getOrgConfigOption(this, "alwaysfilterocreatetrxs", vars.getOrg()).equals("Y"))) {
	    	GridData = RequestManagementPOData.select(this, vars.getLanguage(),vars.getSessionValue("#AD_SqlDateFormat"), vars.getOrg(), vars.getUserOrg(), strpodocno, 
	    			strsodocno, strvendorId, strdatefrom, strdateto, strcProjectId, strcustomerId, strmProductId, stradOrgId);
	    	strGrid=grid.printGrid(this, vars, script, GridData);
	    }
	    strHeaderFG=fh.prepareFieldgroup(this, vars, script, "RequstManagementPOHeaderFG", null,false);
	    strActionButtons=fh.prepareFieldgroup(this, vars, script, "RequstManagementPOButtonFG", null,false);
	    
	     //Declaring the toolbar (Default no toolbar)
	     String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
	     //Window Tabs (Default Declaration)
	     WindowTabs tabs;                  //The Servlet Name generated automatically
	     tabs = new WindowTabs(this, vars, this.getClass().getName());
	     script.addOnload("setProcessingMode('window', false);");
	     //Configuring the Structure                                                   Title of Site  Toolbar  
	     strOutput = ConfigureFrameWindow.doConfigure(this,vars,"inpdatefrom",null, "Request Management PO",strToolbar,"NONE",tabs);	    
         strOutput=Replace.replace(strOutput, "@CONTENT@",  strHeaderFG + strGrid + strActionButtons);
         strOutput = script.doScript(strOutput, "",this,vars);
         //Sending the Output
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
    
    private void removeSessionValues(VariablesSecureApp vars) { //Removing the Sessionvariables
        vars.removeSessionValue(this.getClass().getName() + "|podocno");  
        vars.removeSessionValue( this.getClass().getName() + "|vendor_id");
        vars.removeSessionValue(this.getClass().getName() + "|datefrom");
        vars.removeSessionValue(this.getClass().getName() + "|dateto");
        vars.removeSessionValue(this.getClass().getName() + "|c_project_id");
        vars.removeSessionValue( this.getClass().getName() + "|sodocno");
        vars.removeSessionValue(this.getClass().getName() + "|customer_id");
        vars.removeSessionValue(this.getClass().getName() + "|m_product_id");
        vars.removeSessionValue(this.getClass().getName() + "|ad_org_id");
        vars.removeSessionValue(this.getClass().getName() + "|auxfield1");
        vars.removeSessionValue(this.getClass().getName() + "|auxfield2");
        vars.removeSessionValue(this.getClass().getName() + "|auxfield3");
      }  
}
