package org.openz.controller.callouts;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.Sqlc;
import org.openz.view.SelectBoxhelper;

public class ComboReloads extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    // New Callout Structure
    CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
    // Exclude the Triggering field from callout to avoid endless loops
    String excludefield=vars.getCommand().substring(3);
    
      try {
        String popup = vars.getStringParameter("IsPopUpCall");
        String strTabID = vars.getStringParameter("inpTabId");
        String strLastFieldChanged = vars.getStringParameter("inpLastFieldChanged");
        String strProcessID = vars.getStringParameter("inpadProcessId"); 
        String strFieldgroupID = vars.getStringParameter("inpadRefFieldcolumnId");
        String strCurrentValue="";
        String callOutUse="none";
        if (popup.equals("1"))
            callOutUse="POPUP";
        else
         callOutUse="WINDOW";
        String fieldname=vars.getCommand().substring(3);
        if (strLastFieldChanged.equals("inp"+ fieldname)) {
          CalloutData[] data=null;
          if (! strTabID.isEmpty())
            data=CalloutData.getCombos2ReloadFromTab(this, fieldname, strTabID);
          if (! strProcessID.isEmpty())
            data=CalloutData.getCombos2ReloadFromProcess(this, fieldname, strProcessID);
          if (! strFieldgroupID.isEmpty())
            data=CalloutData.getCombos2ReloadFromFieldGroup(this, fieldname, strFieldgroupID);
          for (int i=0;i<data.length;i++){
            if (! Sqlc.TransformaNombreColumna(data[i].columnname).equals(excludefield)) {
               // strCurrentValue=vars.getStringParameter("inp"+Sqlc.TransformaNombreColumna(data[i].columnname));
              callout.appendComboTable("inp"+Sqlc.TransformaNombreColumna(data[i].columnname), SelectBoxhelper.getReferenceDataByRefName(this, vars, data[i].referencename,data[i].adValRuleId,null,strCurrentValue,false),strCurrentValue );
            }
          }
        }
          response.setContentType("text/html; charset=UTF-8");
          PrintWriter out = response.getWriter();
          //String test=callout.returnCalloutAppFrame();
        if (strProcessID.isEmpty()||callOutUse.equals("WINDOW"))
          //out.println(test);
          out.println(callout.returnCalloutAppFrame());
        else
          //callOutUse POPUP
          out.println(callout.returnCalloutMainFrame());
        out.close();
      } catch (Exception ex) {
        pageErrorCallOut(response);
      }
  }

}

