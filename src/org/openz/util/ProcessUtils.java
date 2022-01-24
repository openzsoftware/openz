package org.openz.util;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessRunner;
import org.openbravo.utils.Replace;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureButton;
import org.openz.view.templates.ConfigurePopup;
import org.openbravo.erpCommon.utility.OBError;

import java.io.PrintWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.database.ConnectionProvider;

public class ProcessUtils {
  public static void startProcessDirectly(String key,String processid,VariablesSecureApp vars, HttpSecureAppServlet servlet) {
    OBError myMessage = null;
    try {
      String pinstance = UtilsData.getUUID(servlet);
      String strProcessing = vars.getStringParameter("inpprocessing");  
      if (strProcessing.isEmpty())
        strProcessing="N";
      PInstanceProcessData.insertPInstance(servlet, pinstance, processid, key, strProcessing, vars.getUser(), vars.getClient(), vars.getOrg());
      ProcessBundle bundle = ProcessBundle.pinstance(pinstance, vars, servlet);
      new ProcessRunner(bundle).execute(servlet);
      PInstanceProcessData[] pinstanceData = PInstanceProcessData.select(servlet, pinstance);
      myMessage = Utility.getProcessInstanceMessage(servlet, vars, pinstanceData);
    }
    catch (Exception ex) {
        myMessage = Utility.translateError(servlet, vars, vars.getLanguage(), ex.getMessage());
    }
    if (servlet.getTabId().isEmpty())
      vars.setMessage(servlet.getServletInfo(), myMessage);
    else
      vars.setMessage(servlet.getTabId(), myMessage);
  }
  public static String getNumOfParams(ConnectionProvider conn,String processId) throws Exception {
    return UtilsData.getProcessNumOfParams(conn, processId);
 
  }
  
  public static void displayMsgPopupClose(HttpSecureAppServlet servlet,VariablesSecureApp vars,HttpServletRequest request, HttpServletResponse response, String title, OBError msg) throws Exception {
	  Scripthelper script = new Scripthelper();
	  String strSkeleton = ConfigurePopup.doConfigure(servlet,vars,script,title, "buttonok");
	  String strFG="<table cellspacing=\"0\" cellpadding=\"0\" class=\"Form_Table\"> <colgroup span=\"4\"></colgroup><tr><td colspan=\"4\"></td></tr><tr><td></td></tr></table>";
	  String strActionButtons= "<table cellspacing=\"0\" cellpadding=\"0\" class=\"Form_Table\"> <colgroup span=\"4\"></colgroup><tr><td colspan=\"4\"></td></tr><tr>";
	  strActionButtons= strActionButtons + ConfigureButton.doConfigure(servlet,vars,script,"buttonok",2,1,false, "ok", "closeThisPage();", "","");
	  strActionButtons= strActionButtons + "</tr></table>";
      script.enableshortcuts("POPUP");
      String strOutput=Replace.replace(strSkeleton, "@CONTENT@", strFG +strActionButtons); 
      script.addSubmitPagePageSripts();
      if (msg!=null) {
          script.addMessage(servlet, vars, msg);
      }
      strOutput = script.doScript(strOutput, "",servlet,vars);
      response.setContentType("text/html; charset=UTF-8");
      PrintWriter out = response.getWriter();
      out.println(strOutput);
      out.close();
  }
}