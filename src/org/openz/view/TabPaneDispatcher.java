package org.openz.view;

import java.sql.Connection;

import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.utils.Replace;
import org.openz.util.UtilsData;

public class TabPaneDispatcher implements ManualTabPane{

	@Override
	public String getFormEdit(HttpSecureAppServlet servlet, VariablesSecureApp vars, FieldProvider data,
			WindowTabs tabs, HttpServletResponse response, ToolBar stdtoolbart) throws Exception {
		String strtab=vars.getStringParameter("inpTabId");
		String fromWindow=vars.getStringParameter("inpwindowId");	
		String srv=servlet.getServletInfo();
		setHistoryRelation(vars);
		srv=srv.replace("Servlet ", "").replace(". This was made by Wad constructor", "");
	    vars.setSessionValue(strtab + "|" + srv + ".view", "RELATION");
		// To WindowID=A2BEBB9B07564D2AAA372B4CB2D01165 (Prod. Order)
	    // Arbeitsgänge(Übersichten)
		if (fromWindow.equals("687E0E7367AE4F54B14B92A60DC46D05")||fromWindow.equals("5B4232EDDDD54CBF9FF4B0A869BBFBF6")) {	
			String workstep=vars.getSessionValue(fromWindow + "|Zssm_Workstep_V_ID");
		    vars.setSessionValue("A2BEBB9B07564D2AAA372B4CB2D01165|Zssm_Workstep_V_ID", workstep);
		    String parent=UtilsData.getParentID(servlet,  "zssm_productionorder_v","Zssm_Workstep_V", workstep);
		    vars.setSessionValue("A2BEBB9B07564D2AAA372B4CB2D01165||zssm_productionorder_v_id", parent);		    
		    response.sendRedirect(servlet.strDireccion + "/org.openbravo.zsoft.serprod.ProductionOrder/WorkSteps035860BB9D4F4D08878CED2F371D7201_Edition.html");      		
	
		}
		return null;
	}

	@Override
	public void setFormSave(HttpSecureAppServlet servlet, VariablesSecureApp vars, FieldProvider data, Connection con)
			throws Exception {
		// TODO Auto-generated method stub
		
	}

	 private void setHistoryRelation(VariablesSecureApp vars) {
	      final String sufix = vars.getSessionValue("reqHistory.current", "0");
	      String rq=vars.getSessionValue("reqHistory.path" + sufix);
	      rq.replace("Edition", "Relation");
	      vars.setSessionValue("reqHistory.path" + sufix, rq);
	      vars.setSessionValue("reqHistory.command" + sufix, "RELATION");
	   }


}
