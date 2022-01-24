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

  public class TSTimeFeedbackCO  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void init(ServletConfig config) {
      super.init(config);
      boolHist = false;
    }

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      if (vars.commandIn("DEFAULT")) {
        String strProjectID = vars.getStringParameter("inpcProjectId"); 
        String strProjecttaskID = vars.getStringParameter("inpcProjecttaskId");
        String strChanged = vars.getStringParameter("inpLastFieldChanged");
        String strTab = vars.getStringParameter("inpTabId");
        String strWindow = vars.getStringParameter("inpwindowId");
        String strEmp=vars.getStringParameter("inpemployeeId");
        
        // New Callout Structure
        CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
        
        try {
            String strDefaultValue=null;
            
            if (strChanged.equals("inpadOrgId")) {
              callout.appendComboTable("inpcProjectId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "C_Project Open in Org",null,null,"",false), "first");
              if (strWindow.equals("82ED989E0C8746D4A95A7034F2895E0E")) // Work Feedback
                callout.appendComboTable("inpemployeeId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "AD_User - Employee",null,null,"",false), "first");
            }
            if (strChanged.equals("inpcProjecttaskId")) {
              if (strWindow.equals("A5D5CE0CDB8E414F8A7A107B96C4ABA8")) {// Machine Feedback
                strDefaultValue=TimeserviceData.getPTaskEndDate(this, vars.getLanguage(), strProjecttaskID);
                callout.appendString("inpworkdate", strDefaultValue);
              }
            }
            if (strChanged.equals("inpemployeeId")) {
              if (strWindow.equals("82ED989E0C8746D4A95A7034F2895E0E")) {// Work Feedback
                strDefaultValue=TimeserviceData.getSalaryCategoryOfEmp(this, strEmp);
                if (strDefaultValue==null || strDefaultValue.isEmpty())
                  strDefaultValue="none";
                //Generally Applied Cost - Validation
                callout.appendComboTable("inpcSalaryCategoryId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "C_Salary_Category_ID","8E82686D03B1479DB7A37922841D1A3E",null,null,false), strDefaultValue);
              }
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
