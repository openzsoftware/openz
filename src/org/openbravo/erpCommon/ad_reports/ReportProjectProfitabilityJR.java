/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
 */
package org.openbravo.erpCommon.ad_reports;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.LocalizationUtils;
import org.openz.util.SessionUtils;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFrameWindow;

public class ReportProjectProfitabilityJR extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    Scripthelper script = new Scripthelper();
    script.addHiddenfield("inpisSOTrxTab", "Y");

    String strCommand=vars.getCommand();

    String strUser=vars.getUser();
    vars.setSessionValue(getServletInfo() + "|isSOTrx", "Y");
    String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
    String strResponsible=vars.getStringParameter("inpresponsibleId");
    try {
      if (ReportProjectProfitabilityData.isUserSupervisor(this, vars.getUser()).equals("N")) 
        vars.setSessionValue(getServletInfo() + "|Responsible_ID",vars.getUser());
    }
      catch (Exception e) { 
      throw new ServletException("Logged in User Needs to be Employee to use this function");
    }
    String strorg=vars.getStringParameter("inpadOrgId");
    String strsalesrep=vars.getInStringParameter("inpsalesrepId");
    String strbpartner=vars.getInStringParameter("inpcBpartnerId");
    String strstatus=vars.getStringParameter("inpstatus");
    String strofferFrom=vars.getDateParameter("inpofferdatefrom",this);
    String strofferTo=vars.getDateParameter("inpofferdateto",this);
    String strorderFrom=vars.getDateParameter("inporderdatefrom",this);
    String strorderTo=vars.getDateParameter("inporderdateto",this);
    String strstartFrom=vars.getDateParameter("inpdatepromisedfrom",this);
    String strstartTo=vars.getDateParameter("inpdatepromisedto",this);
    String strinvoiceFrom=vars.getDateParameter("inpdateinvoicedfrom",this);
    String strinvoiceTo=vars.getDateParameter("inpdateinvoicedto",this);
    

    
    if (strCommand.equals("XLS")||strCommand.equals("PDF")) {
      vars.setSessionValue(getServletInfo() + "|Responsible_ID",strResponsible);
      vars.setSessionValue(getServletInfo() + "|ad_Org_Id",strorg);
      vars.setSessionValue(getServletInfo() + "|status",  strstatus);
      vars.setSessionValue(getServletInfo() + "|offerdatefrom",strofferFrom);  
      vars.setSessionValue(getServletInfo() + "|offerdateto",strofferTo);  
      vars.setSessionValue(getServletInfo() + "|orderdatefrom",strorderFrom);  
      vars.setSessionValue(getServletInfo() + "|orderdateto",strorderTo);  
      vars.setSessionValue(getServletInfo() + "|datepromisedfrom",strstartFrom);  
      vars.setSessionValue(getServletInfo() + "|datepromisedto"   ,strstartTo);  
      vars.setSessionValue(getServletInfo() + "|dateinvoicedFrom"  ,strinvoiceFrom);  
      vars.setSessionValue(getServletInfo() + "|dateinvoicedto"    ,strinvoiceTo);  
      String strReportName="";
      if (strCommand.equals("XLS")){
         strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportProjectProfitability.jrxmlXLS.jrxml";
      }
      else{
         strReportName = "@basedesign@/org/openbravo/erpCommon/ad_reports/ReportProjectProfitability.jrxml";
      }
        
      HashMap<String, Object> parameters = new HashMap<String, Object>();
      String strtitle="";
      try {
        strtitle=LocalizationUtils.getElementTextByElementName(this, "ProjectControllingReport", vars.getLanguage());
        strtitle= strtitle+ "    "+LocalizationUtils.getElementTextByElementName(this, "ad_org_id", vars.getLanguage());
        strtitle= strtitle+ ": "+ ReportProjectProfitabilityData.getSelectedOrg(this, strorg);
      } catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        throw new ServletException(e);
      }
      parameters.put("Subtitle", strtitle);
      String strCur=LocalizationUtils.getGlobalCurSymbol(this);
      parameters.put("CURSYMOL",strCur);
      ReportProjectProfitabilityData[] data = ReportProjectProfitabilityData.select(this,vars.getLanguage(), strorg, strResponsible,  strstatus, strofferFrom, strofferTo, strorderFrom, strorderTo, strstartFrom, strstartTo, strinvoiceFrom, strinvoiceTo,strsalesrep, strbpartner);
      renderJR(vars, response, strReportName, strCommand.toLowerCase(), parameters, data, null);
    
    
    } else {
   
   
    
     try {
        
        String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
        //Window Tabs (Default Declaration)
        WindowTabs tabs;                  //The Servlet Name generated automatically
        tabs = new WindowTabs(this, vars, this.getClass().getName());
        //Configuring the Structure                                                   Title of Site  Toolbar  
        String strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inpmProductId",null, "Project Profibility report",strToolbar,"NONE",tabs);
        Formhelper fh=new Formhelper();
        // Fill Salesrep Multi selector
        if (! strsalesrep.isEmpty()) {
          ReportProjectProfitabilityData[] selSalesrep= ReportProjectProfitabilityData.getSelectedSalesreps(this, strsalesrep);
          fh.addcombodata(selSalesrep, "SalesRep_ID", null);
        }
       // Fill BPartner Multi selector
        if (!  strbpartner.isEmpty()) {
          ReportProjectProfitabilityData[] selBpartner= ReportProjectProfitabilityData.getSelectedBpartner(this, strbpartner);
          fh.addcombodata(selBpartner, "c_bpartner_id", null);
        }
        String strTableStructure=fh.prepareFieldgroup(this, vars, script, "ProjectProfibilityJRFilterFG",null,true);
        strSkeleton=Replace.replace(strSkeleton, "@CONTENT@", strTableStructure );  
        script.addHiddenfieldWithID("enableautosave", "N");

        strSkeleton = script.doScript(strSkeleton, "",this,vars);
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println(strSkeleton);
        out.close(); 
     } catch (Exception e) { 
          log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
          e.printStackTrace();
          throw new ServletException(e);
     }
   } // Command = DEFAULT 
    
 }

  public String getServletInfo() {
    return this.getClass().getName();
  } // end of getServletInfo() method

 
}
