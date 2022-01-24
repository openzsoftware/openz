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
SZ: Added RESET-Button */
package org.openbravo.erpCommon.businessUtility;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Random;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.Sqlc;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.LocalizationUtils;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigurePopup;

public class Buscador extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  private static final int MAX_TEXTBOX_LENGTH = 150;
  private static final int MAX_TEXTBOX_DISPLAY = 30;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      vars.setSessionValue("Buscador.inpTabId", vars.getRequiredStringParameter("inpTabId"));
      vars.setSessionValue("Buscador.inpWindow", vars.getRequiredStringParameter("inpWindow"));
      vars.setSessionValue("Buscador.inpWindowId", vars.getStringParameter("inpWindowId"));
      vars.setSessionValue("Buscador.FilterTrigger", "Y");
      vars.setSessionValue(this.getClass().getName() + "|ad_org_id", vars.getOrg());
      vars.setSessionValue(this.getClass().getName() + "|issotrx", BuscadorData.isSoTrx(this, vars.getStringParameter("inpWindowId")));
      printPageFS(response, vars);
    }

    if (vars.commandIn("FRAME1")) {
      Scripthelper script = new Scripthelper();
      Formhelper fh=new Formhelper();
      try {
      // Re-Implemented through GUI-Engine
      String strTab = vars.getSessionValue("Buscador.inpTabId");
      String name= LocalizationUtils.getElementTextByElementName(this, "Search", vars.getLanguage());  
      String focus=BuscadorData.selectFistFocusedfield(this, vars.getLanguage(),strTab);
      if (focus==null)
        focus="";
      String strSkeleton = ConfigurePopup.doConfigure(this,vars,script,name, Sqlc.TransformaNombreColumna(focus));
      // Prevent Opener Reload
      strSkeleton=Replace.replace(strSkeleton,"window.onunload = reloadOpener;","");
      strSkeleton=Replace.replace(strSkeleton,"onunload=\"pageunload();\"","");
      String strFG="<table cellspacing=\"0\" cellpadding=\"0\" class=\"Form_Table\"> <colgroup span=\"4\"></colgroup><tr><td colspan=\"4\"></td></tr><tr><td></td></tr></table>";
      strFG=strFG + fh.prepareBuscadorFields(this, vars, script,strTab,"N"); 
      String strActionButtons= "</colgroup><tr><td colspan=\"4\"></td></tr><tr>";
      strActionButtons=strActionButtons + fh.prepareFieldgroup(this, vars, script, "BuscadorActionButtonFG", null, false);
      strActionButtons= strActionButtons + "";
      script.enableshortcuts("POPUP");
      String strOutput=Replace.replace(strSkeleton, "@CONTENT@",  strFG +strActionButtons);
      if (BuscadorData.isOrgInFilter(this, vars.getLanguage(),strTab)==null)
        script.addHiddenfieldWithID("adOrgId", vars.getOrg());       
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
      }
      
    }
  }

  private void printPageFS(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {

    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/businessUtility/Buscador_FS").createXmlDocument();

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

 }
