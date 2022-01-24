package org.openz.timeservice;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openz.controller.callouts.CalloutStructure;
import org.openz.view.SelectBoxhelper;

public class TSTimefeedbackMachCO extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strUserID = vars.getStringParameter("inpemployeeId");
      String strProjectID = vars.getStringParameter("inpcProjectId");  // request-variable      
      String strChanged = vars.getStringParameter("inpLastFieldChanged");

      // New Callout Structure
      CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
      
      try {
        
       
        if (strChanged.equals("inpcProjectId") && ! strProjectID.equals("")){
          String strDefaultValue=TimeserviceData.getProjectEndDate(this, vars.getLanguage(), strProjectID);
          callout.appendString("inpworkdate", strDefaultValue);
         
        } 
        
       
     
        


           // callout.appendMessage("NoLocationNoTaxCalculated", this, vars);

        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println(callout.returnCalloutAppFrame());
        out.close();
      } catch (Exception ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }




}
