package org.openz.controller.popup;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.LocalizationUtils;
import org.openz.util.SessionUtils;
import org.openz.view.EditableGrid;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.*;

public class CreateDocumentfromSO extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  
  
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }
  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
  ServletException {
    // Initialize global structure
    VariablesSecureApp vars = new VariablesSecureApp(request);
    Scripthelper script = new Scripthelper(); // Injects Javascript, hidden fields, etc into the generated html
    script.enableshortcuts("POPUP");
    String js= "function submitThisPage(command) { \n" +
               "     submitCommandForm(command, true, null, '', '_self');\n" +
              // "     window.onunload = reloadOpener;\n" +
              // "     setTimeout(function(){top.close();},8000);\n" +
               "     return true;\n" +
               "}\n" ;
    script.addJScript(js);
    Formhelper fh = new Formhelper();         // Builder for Fieldgroups
    String strOutput = "" ;                   // Resulting html output
    String strHeaderFG = "";                  // Header fieldgroup (defined in AD CreateDocumentfromSOHeaderFG)
    String strGrid="";						  // Grid in AD : CreateDocumentfromSOGrid
    String strActionButtons="";               // Bottom Fieldgroup (defined in AD CreateDocumentfromSOActionBtns)
    

    FieldProvider[] GridData;
    EditableGrid grid ;						  // Builder for Grids
    String strSODocumentID;
    if (vars.commandIn("DEFAULT")) {
      vars.setMessage(this.getClass().getName(),null);
      strSODocumentID=SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "c_order_id");
      vars.setSessionValue(getServletInfo() + "issotrx", "N");
    }
    // Creating Document
    if (vars.commandIn("SAVE")) {
     Vector <String> retval;
     try {
     Connection conn=this.getTransactionConnection();
     try {
    	 strSODocumentID=vars.getSessionValue(getServletInfo() + "|c_order_id");
    	 String targetDType = vars.getStringParameter("inpdoctype");
    	 OBError msg = new OBError();
    	 // Create from Purchase
    	 if (targetDType.equals("QUOTATION")||targetDType.equals("ORDERPO")) {
    		 String mess=CreateDocumentfromSOData.CreateDocumentFromOrderPO(this,  targetDType, strSODocumentID, vars.getUser()); 
    		 msg=Utility.translateError(this, vars,vars.getLanguage(),mess);
    		 msg.setTitle("OK");
    		 msg.setType("SUCCESS");
    		 vars.setMessage("294", msg);
    	 } 
    	 // Create from Sale
    	 if (targetDType.equals("PROPOSAL")||targetDType.equals("ORDER")||targetDType.equals("PROFORMA")) {
    		 String mess=CreateDocumentfromSOData.CreateDocumentFromOrder0(this,  targetDType, strSODocumentID, vars.getUser()); 
    		 msg=Utility.translateError(this, vars,vars.getLanguage(),mess);
    		 msg.setTitle("OK");
    		 msg.setType("SUCCESS");
    		 vars.setMessage("186", msg);
    	 } 
    	 if (targetDType.equals("POOFFER")||targetDType.equals("POORDER")) {
         	grid = new EditableGrid("CreateDocumentfromSOGrid", vars, this);
         	retval=grid.getSelectedIds(this, vars, "c_orderline_id");
         	String bpartnerID;
         	Vector <String> bpartners=new Vector <String> ();
         	if (targetDType.equals("POORDER")) {
         		bpartnerID= vars.getStringParameter("inpcBpartnerId");
         		bpartners.add(bpartnerID);
         	} else 
         		bpartners=vars.getListFromInString(vars.getInStringParameter("inpbpartners"));
         	String strLiknks2Doc="";
         	for (int ii = 0; ii < bpartners.size(); ii++) {			
         	   String docID=CreateDocumentfromSOData.c_createDocumentHeaderFromSO(conn, this, strSODocumentID, targetDType, 
         			  bpartners.elementAt(ii), vars.getUser());
         	   strLiknks2Doc=strLiknks2Doc + CreateDocumentfromSOData.getLink(conn,this, docID) + " ";
		       for (int i = 0; i < retval.size(); i++) {
		    	   String strID=retval.elementAt(i);
		           String strQty=grid.getValue(this, vars, strID, "qtyordered");
		           String strDscr=grid.getValue(this, vars, strID, "description");
		           String re=CreateDocumentfromSOData.c_createDocumentLineFromSO(conn, this, docID,strDscr ,strQty , strID);	   
		       }
		       if (vars.getSessionValue("P|ACTIVATEPODOCUMENTAFTERCREATEFROMSO").equals("Y"))
		           CreateDocumentfromSOData.postNewDocument(conn, this, docID);
         	}
         	conn.commit();
         	msg=Utility.translateError(this, vars,vars.getLanguage(),"@PurchaseDocumentsCreated@ : " + strLiknks2Doc);
   		    msg.setTitle("OK");
   		    msg.setType("SUCCESS");
   		    vars.setMessage("186", msg);
    	 }
    	 conn.close();
     }
     catch (Exception e) { 
         log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
         e.printStackTrace();
         try {conn.rollback();conn.close();} catch (Exception ign) {}
         throw new ServletException(e);
     } 
     } catch (Exception e) { throw new ServletException(e);}
    }
    // Closing the Popup
    if (vars.commandIn("SAVE")) {
      script.addOnload("window.opener.delstash();");
      script.addOnload(" window.onunload = reloadOpener;");
      script.addOnload("top.close();");
      try {
        strOutput = ConfigurePopup.doConfigure(this,vars,script,"CreateDocumentfromSO","");
        strOutput=Replace.replace(strOutput, "@CONTENT@",  "");
        strOutput = script.doScript(strOutput, "",this,vars);
      }
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        throw new ServletException(e);
      }
    }
    if (vars.commandIn("DEFAULT")||vars.commandIn("NEW")) {
      // Build The GUI INIT by AD
      try {
        script.addOnload("window.opener.delstash();");
        strSODocumentID=vars.getSessionValue(getServletInfo() + "|c_order_id");
        grid = new EditableGrid("CreateDocumentfromSOGrid", vars, this);
        if (CreateDocumentfromSOData.issotrx(this, strSODocumentID).equals("Y")) {
        	strHeaderFG=fh.prepareFieldgroup(this, vars, script, "CreateDocumentfromSOHeaderFG", null,false);
        	// Select Data from SO Document
            GridData=CreateDocumentfromSOData.select(this, strSODocumentID);
            strGrid=grid.printGrid(this, vars, script, GridData);
        } else
        	strHeaderFG=fh.prepareFieldgroup(this, vars, script, "CreateDocumentfromPOHeaderFG", null,false);
        strActionButtons=fh.prepareFieldgroup(this, vars, script, "CreateDocumentfromSOActionBtns", null,false);
        strOutput = ConfigurePopup.doConfigure(this,vars,script,"CreateDocumentfromSO","buttonOK");
        strOutput=Replace.replace(strOutput, "@CONTENT@",  strHeaderFG + strGrid + strActionButtons);
        strOutput = script.doScript(strOutput, "",this,vars);
      }
      catch (Exception e) { 
          log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
          e.printStackTrace();
          throw new ServletException(e);
      }
    }
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(strOutput);
    out.close(); 
  }
 

  public String getServletInfo() {
    return this.getClass().getName();
  } 
}
