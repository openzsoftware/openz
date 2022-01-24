package org.openbravo.erpCommon.ad_process;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.SessionUtils;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureDataGrid;
import org.openz.view.templates.ConfigurePopup;
import org.openz.view.templates.ConfigureSelectionPopup;

public class BPartnerFastEntryProcess extends HttpSecureAppServlet {

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
    Formhelper fh = new Formhelper();         // Injects the styles of fields, grids, etc
    String strOutput = "" ;                   // Resulting html output
    String strHeaderFG = "";                  // Header fieldgroup (defined in AD)
    String strGrid="";
    String strActionButtons="";               // Bottom Fieldgroup (defined in AD)
    Boolean reload=false;
    String message=null ;
    String bpartner=vars.getStringParameter("inpcBpartnerId");
    if (bpartner.isEmpty()) {
      String value=vars.getStringParameter("inpvalue");
      bpartner=BPartnerFastEntryProcessData.selectPartnerIDfromValue(myPool, value);
      if (bpartner==null || bpartner.isEmpty()) 
        bpartner=vars.getSessionValue(getServletInfo() + "|cBpartnerId");
      else
        vars.setSessionValue(getServletInfo() + "|cBpartnerId", bpartner);
    }
    String emp=BPartnerFastEntryProcessData.selectEmployeefromBP(myPool, bpartner);
    if (vars.commandIn("SAVE")) {
      try {
        String strvalue=vars.getStringParameter("inpvalue");
        String strname=vars.getStringParameter("inpname");
        String strc_bp_group_id=vars.getStringParameter("inpcBpGroupId");
        String strurl=vars.getStringParameter("inpurl");
        String strsalesrep_id=vars.getStringParameter("inpsalesrepId");
        //String strIscustomer=vars.getStringParameter("inpiscustomer",getServletInfo() + "|iscustomer","");
        String strpaymentrule=vars.getStringParameter("inppaymentrule");
        String strpaymentterm=vars.getStringParameter("inpcPaymenttermId");
        String strIscustomer=vars.getStringParameter("inpiscustomer", "N");
        String strIsvendor=vars.getStringParameter("inpisvendor", "N");
        String strincoterms=vars.getStringParameter("inpcIncotermsId");
        String straddress1=vars.getStringParameter("inpaddress1");
        String straddress2=vars.getStringParameter("inpaddress2");
        String strcity=vars.getStringParameter("inpcity");
        String strpostal=vars.getStringParameter("inppostal");
        String strc_country_id=vars.getStringParameter("inpcCountryId");
        String struidnumber=vars.getStringParameter("inpuidnumber");
        String strc_tax_id=vars.getStringParameter("inpcTaxId");
        String strp_address12=vars.getStringParameter("inppAddress12");
        String strp_address22=vars.getStringParameter("inppAddress22");
        String strp_city2=vars.getStringParameter("inppCity2");
        String strp_postal2=vars.getStringParameter("inppPostal2");
        String strp_country_id2=vars.getStringParameter("inppCountryId2");
        String strfirstname=vars.getStringParameter("inpfirstname");
        String strlastname=vars.getStringParameter("inplastname");
        String strtitle=vars.getStringParameter("inptitle");
        String strc_greeting_id=vars.getStringParameter("inpcGreetingId");
        String stremail=vars.getStringParameter("inpemail");
        String strphone=vars.getStringParameter("inpphone");
        String strphone2=vars.getStringParameter("inpphone2");
        String strbank_name=vars.getStringParameter("inpbankName");
        String striban=vars.getStringParameter("inpiban");
        String strswiftcode=vars.getStringParameter("inpswiftcode");
        // Save Data
        BPartnerFastEntryProcessData.selectUpdate(myPool, bpartner, vars.getUser(), strvalue, strname, strc_bp_group_id,
            strurl, strsalesrep_id, straddress1, straddress2, strcity, strpostal, strc_country_id, 
            struidnumber, strc_tax_id, strp_address12, strp_address22, strp_city2, strp_postal2, strp_country_id2, 
            strfirstname, strlastname, strtitle, strc_greeting_id, stremail, strphone, strphone2, 
            strIscustomer,strIsvendor,emp,strpaymentrule,strpaymentterm,strincoterms);
        // Bank#
        BPartnerFastEntryProcessData.selectUpdateBank(myPool, bpartner, vars.getUser(),strbank_name, striban,strswiftcode); 
        
        
        message = Utility.messageBD(this, "BPARTNERUPD_SUCESS", vars.getLanguage());
        advisePopUpRefresh(request, response, "SUCCESS", "Process Request", message);
      } catch (Exception e) {
        log4j.error("Error in: " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        message=e.getMessage();
        reload=true;
      }
    }
    if (vars.getCommand().equals("DEFAULT")||reload) {
    try {
      strOutput = ConfigurePopup.doConfigure(this,vars,script,"FastEntry","firstname");
      
      BPartnerFastEntryProcessData[] data=BPartnerFastEntryProcessData.select(myPool,bpartner);
      strHeaderFG=fh.prepareFieldgroup(this, vars, script,"BPartnerFastEntryFG", data[0], false); 
      strActionButtons=fh.prepareFieldgroup(this, vars, script,"BPartnerFastEntryFGAction", null, false); 
      
      if (message!=null)
        script.addMessage(this, vars, Utility.translateError(myPool, vars, vars.getLanguage(), message));
      
     
     // Replace Filter,GRID and Actionbuttons in Skeleton 
      strOutput = Replace.replace(strOutput, "@CONTENT@", strHeaderFG + strActionButtons);
      strOutput = script.doScript(strOutput, "",this,vars);
     // strOutput=Replace.replace(strOutput,"ActionButton_Responser.html", "BPartnerFastEntryProcess.html");
     // Focus on Employees
     if (emp.equals("Y")) 
       strOutput=Replace.replace(strOutput,"setWindowElementFocus('firstname', 'id');","setWindowElementFocus('value', 'id');");
      response.setContentType("text/html; charset=UTF-8");
      PrintWriter out = response.getWriter();
      out.println(strOutput);
      out.close();

   
    }
    catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        throw new ServletException(e);
    }}
    
    
  }
 
  public String getServletInfo() {
    return this.getClass().getName();
  } 
}
