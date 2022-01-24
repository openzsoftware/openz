package org.openz.timeservice;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openz.controller.callouts.CalloutData;
import org.openz.controller.callouts.CalloutStructure;
import org.openz.view.SelectBoxhelper;

public class TSProjecttaskCO extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strProjectID = vars.getStringParameter("inpcProjectId"); 
      String strChanged = vars.getStringParameter("inpLastFieldChanged");
      String strTab = vars.getStringParameter("inpTabId");
      String strWindow = vars.getStringParameter("inpwindowId");

      // New Callout Structure
      CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
      
      try {
          String strValRule=TimeserviceData.getPTaskValidationNamebyTabId(myPool, strTab);
          String strDefaultValue=null;
          if (strWindow.equals("A7AF6B7EA2A04616BACD889B62835E17")||
              strWindow.equals("181")||
              strWindow.equals("183")) // G/L Batch, Purchase Order, Purchase Invoice
            strDefaultValue=TimeserviceData.getPTaskIdByname(this, strProjectID, "Suppliers");
          if (strWindow.equals("800076")) // Internal Material Movements
            strDefaultValue=TimeserviceData.getPTaskIdByname(this, strProjectID, "Material");
          if (strWindow.equals("82ED989E0C8746D4A95A7034F2895E0E")) // Work Feedback
            strDefaultValue=TimeserviceData.getPTaskIdByname(this, strProjectID, "Personal");
          if (strWindow.equals("A5D5CE0CDB8E414F8A7A107B96C4ABA8")) // Machine Feedback
            strDefaultValue=TimeserviceData.getPTaskIdByname(this, strProjectID, "Equipment");
          if (strDefaultValue!=null)
            callout.appendComboTable("inpcProjecttaskId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "C_PROJECTTASK_ID",strValRule,null,"",false), strDefaultValue);

        
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