package org.openz.controller.form;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;


import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.utils.Replace;
import org.openz.util.LocalizationUtils;
import org.openz.view.EditableGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFrameWindow;


public class GeneralLedgerJournalEditable extends HttpSecureAppServlet {
	private static final long serialVersionUID = 1L;
	
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,ServletException {
	VariablesSecureApp vars = new VariablesSecureApp(request);
    Scripthelper script= new Scripthelper();
    response.setContentType("text/html; charset=UTF-8");
    OBError myMessage = new OBError();
    String strMestxt="";
	String strOutput="";
	Connection conn = null;
	try {
		// Save Action
		if (vars.commandIn("SAVE")) {
            conn= this.getTransactionConnection();
            Vector <String> selectedids;
            EditableGrid grid = new EditableGrid("GeneralLedgerEditGrid", vars, this);
            selectedids=grid.getSelectedIds(null, vars, "fact_acct_id");
            for (int i = 0; i < selectedids.size(); i++) {
            	String newacct=grid.getValue(this, vars, selectedids.elementAt(i), "c_validcombination_id");
            	newacct=GeneralLedgerJournalEditableData.getAccountFromValidcombination(this, newacct);
            	if (GeneralLedgerJournalEditableData.isPeriodOpen(this, selectedids.elementAt(i)).equals("Y")) {
            		GeneralLedgerJournalEditableData.update(conn, this, newacct, vars.getLanguage(),selectedids.elementAt(i));
            	} else
            		throw new Exception("PeriodNotAvailable");
            }
            strMestxt=selectedids.size() + " " + LocalizationUtils.getMessageText(this, "RowsUpdated", vars.getLanguage());
            releaseCommitConnection(conn);
            
		}
		// Build the GUI
        //Delete the SessionVariables
    	if (vars.commandIn("FIND"))
    	    removeSessionValues(vars);
    	// Filter
        String strdatefrom =vars.getDateParameterGlobalVariable("inpdatefrom", this.getClass().getName() + "|datefrom", "",this);
        String strdateto = vars.getDateParameterGlobalVariable("inpdateto", this.getClass().getName() + "|dateto", "",this);
        String strOrgid=vars.getGlobalVariable("inporganization", this.getClass().getName() + "|organization", vars.getOrg());
        String strDoctypeId=vars.getGlobalVariable("inpdocumenttype", this.getClass().getName() + "|documenttype", "");
        String strAcctSchemaId=vars.getGlobalVariable("inpaccountingschema", this.getClass().getName() + "|accountingschema", "");
        String strText=vars.getGlobalVariable("inptext", this.getClass().getName() + "|text", "");
        String strDescription=vars.getGlobalVariable("inpdescription", this.getClass().getName() + "|description", "");
        String strSiscatrdPmts=vars.getGlobalVariable("inpdiscardpayments", this.getClass().getName() + "|discardpayments", "N");
        String strAccts=vars.getGlobalVariable("inpaccount", this.getClass().getName() + "|account", "");
        
    	//Declaring the toolbar (Default no toolbar)
        String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
        //Window Tabs (Default Declaration)
        WindowTabs tabs;                  //The Servlet Name generated automatically
        tabs = new WindowTabs(this, vars, this.getClass().getName());
        //Configuring the Structure                                                   Title of Site  Toolbar  
        String strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inpdatefrom",null, "General Ledger Journal",strToolbar,"NONE",tabs);

        // Load Grid Data
        String strGrid="";
        EditableGrid grid = new EditableGrid("GeneralLedgerEditGrid", vars, this);
        if (!(strdatefrom.isEmpty()&&strdateto.isEmpty()&&strOrgid.isEmpty()&&strDoctypeId.isEmpty()&&strAcctSchemaId.isEmpty()&& strAccts.isEmpty())) {
        	GeneralLedgerJournalEditableData[] data = GeneralLedgerJournalEditableData.select(this, vars.getLanguage(),
        			strdatefrom, strdateto, strDoctypeId, strAcctSchemaId, strText, strDescription,
        			strAccts, strOrgid, strSiscatrdPmts, vars.getUserOrg());
        	strGrid=grid.printGrid(this, vars, script, data);
        }
        //Declaration of the Infobar                         Text inside the Infobar
        //Saving the Fieldgroups into Variables

        // Fieldgroup
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();
        String strFG=fh.prepareFieldgroup(this, vars, script, "GeneralLedgerJournalFilter", null,false);
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",strFG+strGrid);
        // After Changes ask the user for discarding them or remain on the site
        script.addHiddenfieldWithID("enabledautosave", "N");
        script.addHiddenfieldWithID("adOrgId",strOrgid);
        //Creating the Output
        script.addOnload("setProcessingMode('window', false);");
        script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('FIND', true, null, null, '_self');\",\"inpaccount\",\"null\");");
        script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('FIND', true, null, null, '_self');\",\"inpdatefrom\",\"null\");");
        script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('FIND', true, null, null, '_self');\",\"inpdateto\",\"null\");");
        script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('FIND', true, null, null, '_self');\",\"inptext\",\"null\");");
        script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('FIND', true, null, null, '_self');\",\"inpdescription\",\"null\");");
        // Adding MSG
        if (!strMestxt.isEmpty()) {
        	myMessage=vars.getMessage(this.getClass().getName());
        	if (myMessage==null) {
        		myMessage=new OBError();
        		myMessage.setType("SUCCESS");
        		myMessage.setTitle("OK");
        		myMessage.setMessage(strMestxt);
        	} else
        		myMessage.setMessage(	strMestxt + "</br>" + myMessage.getMessage());
        	script.addMessage(this, vars, myMessage);
        }
        strOutput = script.doScript(strOutput, "",this,vars);
		//Sending the Output
	    PrintWriter out = response.getWriter();
	    out.println(strOutput);
	    out.close();

	} catch (Exception e) { 
	        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
	        e.printStackTrace();
	        try {
	            releaseRollbackConnection(conn);
	        } catch (final Exception ignored) { }
	        throw new ServletException(e);
	}    
  }
  
  private void removeSessionValues(VariablesSecureApp vars) { //Removing the Sessionvariables
    vars.removeSessionValue(this.getClass().getName() + "|organization"); 
    vars.removeSessionValue( this.getClass().getName() + "|datefrom");
    vars.removeSessionValue(this.getClass().getName() + "|dateto");
    vars.removeSessionValue(this.getClass().getName() + "|documenttype");
    vars.removeSessionValue(this.getClass().getName() + "|accountingschema");
    vars.removeSessionValue(this.getClass().getName() + "|text");
    vars.removeSessionValue(this.getClass().getName() + "|description");
    vars.removeSessionValue(this.getClass().getName() + "|discardpayments");
    vars.removeSessionValue(this.getClass().getName() + "|account");
  }
}
