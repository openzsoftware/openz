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
package org.openz.bommanagement.controller;

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
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openz.pdc.controller.PdcStatusBar;
import org.openz.util.*;


public class BOMCreate  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      Vector <String> retval;
      
      Scripthelper script= new Scripthelper();
      script.addHiddenfield("inpadOrgId", vars.getOrg());
      script.addHiddenfield("inpadClientId", vars.getClient());
      response.setContentType("text/html; charset=UTF-8");
      OBError myMessage = new OBError();
      if (vars.getOrg().equals("0"))
        throw new ServletException("@needOrg2UseFunction@");
      // INIT by AD
      try{
        //Delete the SessionVariables
        
        removePageSessionVariables(vars);
        //Local Variables for Template
        //Getting the barcode
       
        String strbarcode = vars.getStringParameter("inpbarcode");
        String userID=vars.getUser();
        String strPdcInfobar=""; //Area for further Information of the Servlet
        //Initializing the Fieldgroups
        vars.setSessionValue(getServletInfo() + "|" +"employee_id",userID );
        String strPdcNavigationFG=""; //Navigation Fieldgroup (Barcode Field and Buttons)
        String strStatusFG="";        //Status Fieldgroup (Statustext and Statusmessage)
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output
        //Important For Insert
        String productId =vars.getStringParameter("inpmProductId");
        String serialno=vars.getStringParameter("inpserialnumber");
        String userId=vars.getStringParameter("inpemployeeId");
        String locatorId=vars.getStringParameter("inpmLocatorId");
        String orgId=vars.getOrg();
        String clientId=vars.getClient();
        //CommandIn Decisions
       
    	String MessageFromBOM="";
        if (vars.commandIn("SAVE_NEW_NEW")){
         MessageFromBOM=BOMCreateData.createInsertion(this,clientId,orgId,userId,productId,serialno,locatorId);
         if (! MessageFromBOM.contains("Error"))
          if (locatorId.isEmpty())    {
           MessageFromBOM="Der Seriennummern-Stammdatensatz wurde erfolgreich angelegt: " + serialno;
           vars.setSessionValue("PDCSTATUSTEXT",MessageFromBOM);
           response.sendRedirect(strDireccion + vars.getSessionValue("PDCFORMERDIALOGUE"));
           return;
         }
         else{
           ProcessUtils.startProcessDirectly(MessageFromBOM, "800131", vars, this);
           vars.setSessionValue("pdcLASTConsumptionID",MessageFromBOM);
           MessageFromBOM= BOMCreateData.serialfromConsumtion(this,MessageFromBOM);
           vars.setSessionValue("PDCSTATUSTEXT", "Der Seriennummern-Stammdatensatz wurde erfolgreich angelegt: " + serialno);
           response.sendRedirect(strDireccion + vars.getSessionValue("PDCFORMERDIALOGUE"));
           return;
         }
        } 
        
        // Set Status Session Vars
        //Declaring the toolbar (Default no toolbar)
        String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
        //Window Tabs (Default Declaration)
        WindowTabs tabs;                  //The Servlet Name generated automatically
        tabs = new WindowTabs(this, vars, this.getClass().getName());
        //Configuring the Structure                                                   Title of Site  Toolbar  
        strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inpmProductId",null, "BOM Creation",strToolbar,"NONE",tabs);
       
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();
        //Declaration of the Infobar                         Text inside the Infobar
        if (MessageFromBOM.equals("Error: Serialnumber is already in use")&&vars.getLanguage().equals("de_DE")){
          MessageFromBOM="Fehler: Die eingegebene Seriennummer existiert bereits."; 
        }
        strPdcInfobar=fh.prepareInfobar(this, vars, script, Utility.messageBD(this, MessageFromBOM,vars.getLanguage()),"font-size: 32pt; color: #000000;");
        //Saving the Fieldgroups into Variables
        //Navigation Fieldgroup
        strPdcNavigationFG=fh.prepareFieldgroup(this, vars, script, "BOMCreate", null,false);
        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",strPdcInfobar+ strPdcNavigationFG);
        // Enable Shortcuts
        
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");
        //Creating the Output
        strOutput = script.doScript(strOutput, "",this,vars);

        
        //Sending the Output
          PrintWriter out = response.getWriter();
          out.println(strOutput);
          out.close();
      }
        
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
         throw new ServletException(e);
 
      } 
}
    
    private void removePageSessionVariables(VariablesSecureApp vars) { //Removing the Sessionvariables
      vars.removeSessionValue("pdcWorkstepID");
      vars.removeSessionValue("pdcTimestamp");
      if (! vars.getSessionValue("pdcConsumptionID").isEmpty())
        vars.setSessionValue("pdcLASTConsumptionID", vars.getSessionValue("pdcConsumptionID"));
      vars.removeSessionValue("pdcConsumptionID");
      vars.removeSessionValue("pdcInOutID");
      vars.removeSessionValue("pdcProductionID");
      vars.removeSessionValue("pdcUserID");
      vars.removeSessionValue("PDCINVOKESERIAL");
      vars.removeSessionValue("PDCINVOKECONSUMPTION");
    }

    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

