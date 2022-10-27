/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Stefan Zimmermann.
***************************************************************************************************************************************************
*/
package org.openz.pdc;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.MobileHelper;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.pdc.controller.PdcStatusBar;
import org.openz.util.*;


public class PdcStoreMainDialogue  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
      Scripthelper script= new Scripthelper();
      response.setContentType("text/html; charset=UTF-8");
      OBError myMessage = new OBError();
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");
      // INIT by AD
      try{
        //Delete the SessionVariables       
        removePageSessionVariables(vars);
        vars.setSessionValue("pdcUserID", vars.getUser());
        //Local Variables for Template
        //Getting the barcode
        String strPdcInfobar=""; //Area for further Information of the Servlet
        //Initializing the Fieldgroups
        String strPdcNavigationFG=""; //Navigation Fieldgroup (Barcode Field and Buttons)
        String strStatusFG="";        //Status Fieldgroup (Statustext and Statusmessage)
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output
        //CommandIn Decisions
    	vars.setSessionValue("PDCFORMERDIALOGUE","/ad_forms/PDCStoreMainDialoge.html");
    	
    	if (vars.commandIn("RESET")){
    		response.sendRedirect(strDireccion + "/security/Menu.html");
    	}
        
        // Set Status Session Vars
        vars.setSessionValue(getServletInfo() + "|STATUS",vars.getSessionValue("PDCSTATUS"));
        vars.setSessionValue(getServletInfo() + "|STATUSTEXT",vars.getSessionValue("PDCSTATUSTEXT"));
        //Declaring the toolbar (Default no toolbar)
        String strToolbar="<a class=\"Main_ToolBar_Button\" href=\"#\" onclick=\"menuQuit(); return false;\" onmouseover=\"window.status='Close session';return true;\" onmouseout=\"window.status='';return true;\" id=\"buttonQuit\"><img class=\"Menu_ToolBar_Button_Icon Menu_ToolBar_Button_Icon_logout_white\" src=\"../web/images/blank.gif\" onclick=\"submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;\" alt=\"Close session\" title=\"Close session\"></a>";
        //Window Tabs (Default Declaration)
        //Configuring the Structure                                                   ON Mobiles: Smartphone, Use Zoom
        int xi=Integer.parseInt(vars.getSessionValue("#ScreenX"));
        int yi=Integer.parseInt(vars.getSessionValue("#ScreenY"));
        if (yi>xi)
        	script.addOnload("document.body.style.zoom = \"200%\";");
        strSkeleton = ConfigureFrameWindow.doConfigureApp(this,vars,"inpbarcode",strToolbar, "PDC Main Store Dialogue","","REMOVED",null,"true");
        // Reload Session instead of Backward Button
        strSkeleton = Replace.replace(strSkeleton, "goToPreviousPage(); return false;", "submitCommandForm('RESET', true, null,'../ad_forms/PDCStoreMainDialoge.html', 'appFrame', false, true);return false;");
        strSkeleton = Replace.replace(strSkeleton,"'PdcStoreMainDialogue.html'","'../ad_forms/PDCStoreMainDialoge.html'");
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();
        //Declaration of the Infobar                         Text inside the Infobar 
        // 
        strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, "pdc_ScanInitial",vars.getLanguage()),"font-size: 32pt; color: #000000;");
        //
        // Prevent Softkeys on Mobile Devices
        //script.addOnload("setTimeout(function(){document.getElementById(\"barcode\").focus();fieldReadonlySettings('barcode', false);},50);");
        //Navigation Fieldgroup
        strPdcNavigationFG=fh.prepareFieldgroup(this, vars, script, "PdcStoreNavigationFG", null,false);
        //Status Fieldgroup
        strStatusFG=PdcStatusBar.getStatusBar(this, vars, script);//fh.prepareFieldgroup(this, vars, script, "PdcStatusFG", null,false);
        
        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",MobileHelper.addMobileCSS(request, strPdcInfobar+ strPdcNavigationFG  + strStatusFG));
        // Enable Shortcuts
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");
        //Creating the Output
        strOutput = script.doScript(strOutput, "",this,vars);

        vars.setSessionValue("PDCSTATUS","OK");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_Scan",vars.getLanguage())+"\r\n");

        //Sending the Output
          PrintWriter out = response.getWriter();
          out.println(strOutput);
          out.close();
          vars.removeSessionValue("PDCSTATUSTEXT");
      }
        
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        vars.setSessionValue("PDCSTATUS","ERROR");
        //vars.setSessionValue("PDCSTATUSTEXT","Error in BDE Main Screen");
        vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ErrorOnPage"+getServletInfo(),vars.getLanguage()));

         throw new ServletException(e);
 
      } 
}
    
    private void removePageSessionVariables(VariablesSecureApp vars) { //Removing the Sessionvariables
      vars.removeSessionValue("pdcWorkstepID");
      if (! vars.getSessionValue("pdcConsumptionID").isEmpty())
        vars.setSessionValue("pdcLASTConsumptionID", vars.getSessionValue("pdcConsumptionID"));
      vars.removeSessionValue("pdcConsumptionID");
      vars.removeSessionValue("pdcInOutID");
      vars.removeSessionValue("pdcProductionID");
      vars.removeSessionValue("PDCINVOKESERIAL");
      vars.removeSessionValue("PDCINVOKECONSUMPTION");
      vars.removeSessionValue("pdcTargetLocator");
    }

    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

