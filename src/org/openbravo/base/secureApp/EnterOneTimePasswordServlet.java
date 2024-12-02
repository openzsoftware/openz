package org.openbravo.base.secureApp;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.erpCommon.ad_forms.Role;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.utils.Replace;
import org.openz.util.SessionUtils;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigurePopup;

public class EnterOneTimePasswordServlet extends HttpSecureAppServlet {

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
    String adUserID="";

    if (vars.commandIn("SAVE")) {
      try {
        String unhashedpassword = vars.getStringParameter("inppassword");
        // & and + forbidden -> space triggers error message
        unhashedpassword = unhashedpassword.replaceAll("&", " ").replaceAll("\\+", " ");
        final String adOrgID = vars.getOrg();
        final String language = vars.getLanguage();
        final String adUserId_loggedin = vars.getUser();
        adUserID = vars.getSessionValue(getServletInfo() + "|ad_user_id");

        Role.validatePasswordOnlyAllowedCharacters(myPool, adOrgID, language, unhashedpassword);
        
        MfaSendOneTimePasswordData.setOneTimePassword(myPool, FormatUtilities.sha1Base64(unhashedpassword), adUserId_loggedin, adUserID);
        MfaSendOneTimePasswordData.setOneTimePasswordEnteredManually(myPool, adUserId_loggedin, adUserID);
        SeguridadData.resetNormalPassword(myPool, adUserId_loggedin, adUserID);
        
        message = Utility.messageBD(this, "PasswordChanged", vars.getLanguage());
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
      if(adUserID.isEmpty()) {
          adUserID = SessionUtils.readInputAndSetLocalSessionVariable(getServletInfo(),vars, "ad_user_id");
      }
      strOutput = ConfigurePopup.doConfigure(this,vars,script,"MFA_Enter_One_Time_Password","password");
      
      strHeaderFG=fh.prepareFieldgroup(this, vars, script,"EnterOneTimePasswordServletFG", null, false); 
      strActionButtons=fh.prepareFieldgroup(this, vars, script,"EnterOneTimePasswordServletFGAction", null, false); 
      
      if (message!=null)
        script.addMessage(this, vars, Utility.translateError(myPool, vars, vars.getLanguage(), message));
      
     
     // Replace Filter,GRID and Actionbuttons in Skeleton 
      strOutput = Replace.replace(strOutput, "@CONTENT@", strHeaderFG + strActionButtons);
      strOutput = script.doScript(strOutput, "",this,vars);
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
