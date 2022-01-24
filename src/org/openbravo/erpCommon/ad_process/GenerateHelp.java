/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html 
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License. 
 * The Original Code is Openbravo ERP. 
 * The Initial Developer of the Original Code is Openbravo SL 
 * All portions are Copyright (C) 2001-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.ad_process;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.ad_actionButton.ActionButtonDefaultData;
import org.openbravo.erpCommon.ad_help.HelpWindow;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;

public class GenerateHelp extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      printPage(response, vars);
    } else if (vars.commandIn("SAVE")) {
      String strWindow = vars.getGlobalVariable("inpadWindowId", "GenerateHelp|windowID");
      String strPath = vars.getRequiredStringParameter("inpPath");
      // new message system
      OBError myMessage = processSave(vars, strWindow, strPath);
      // if (!strMessage.equals(""))
      // vars.setSessionValue("GenerateHelp.message", strMessage);
      vars.setMessage("GenerateHelp", myMessage);
      printPage(response, vars);
    } else
      pageErrorPopUp(response);
  }

  private OBError processSave(VariablesSecureApp vars, String strWindow, String strPath)
      throws IOException {
    OBError myMessage = null;
    myMessage = new OBError();
    myMessage.setTitle("");
    if (log4j.isDebugEnabled())
      log4j.debug("Save: GenerateHelp");
    String strMessage = "";
    try {
      GenerateHelpData[] data = GenerateHelpData.select(this, vars.getLanguage(), strWindow);
      if (data == null || data.length == 0) {
        log4j.error("There're no windows for window: " + strWindow);
        myMessage.setType("Error");
        myMessage.setMessage(Utility.messageBD(this, "ProcessRunError", vars.getLanguage()));
        return myMessage;
        // return Utility.messageBD(this, "ProcessRunError",
        // vars.getLanguage());
      }
      int i = 0;
      for (i = 0; i < data.length; i++)
        generateFile(strPath, data[i].adWindowId + ".html", HelpWindow.generateWindow(this,
            xmlEngine, vars, true, data[i].adWindowId));
      strMessage = Utility.messageBD(this, "Created", vars.getLanguage()) + ": " + i;
    } catch (ServletException e) {
      e.printStackTrace();
      log4j.warn("Rollback in transaction");
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, "ProcessRunError", vars.getLanguage()));
      return myMessage;
      // return Utility.messageBD(this, "ProcessRunError",
      // vars.getLanguage());
    }
    myMessage.setType("Success");
    myMessage.setMessage(strMessage);
    return myMessage;
    // return strMessage;
  }

  private boolean generateFile(String strPath, String strFile, String data) {
    try {
      File fileData = new File(strPath, strFile);
      FileWriter fileWriterData = new FileWriter(fileData);
      PrintWriter printWriterData = new PrintWriter(fileWriterData);
      printWriterData.print(data);
      fileWriterData.close();
    } catch (IOException e) {
      e.printStackTrace();
      log4j.error("Problem of IOExceptio in file: " + strPath + " - " + strFile);
      return false;
    }
    return true;
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: process GenerateHelp");
    ActionButtonDefaultData[] data = null;
    String strHelp = "", strDescription = "", strProcessId = "800071";
    if (vars.getLanguage().equals("en_US"))
      data = ActionButtonDefaultData.select(this, strProcessId);
    else
      data = ActionButtonDefaultData.selectLanguage(this, vars.getLanguage(), strProcessId);
    if (data != null && data.length != 0) {
      strDescription = data[0].description;
      strHelp = data[0].help;
    }
    String[] discard = { "" };
    if (strHelp.equals(""))
      discard[0] = new String("helpDiscard");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_process/GenerateHelp").createXmlDocument();

    ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "GenerateHelp", false, "", "", "",
        false, "ad_process", strReplaceWith, false, true);
    toolbar.prepareSimpleToolBarTemplate();
    xmlDocument.setParameter("toolbar", toolbar.toString());

    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("question", Utility.messageBD(this, "StartProcess?", vars
        .getLanguage()));
    xmlDocument.setParameter("description", strDescription);
    xmlDocument.setParameter("help", strHelp);

    // New interface paramenters
    try {
      WindowTabs tabs = new WindowTabs(this, vars,
          "org.openbravo.erpCommon.ad_process.GenerateHelp");

      xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
      xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
      xmlDocument.setParameter("childTabContainer", tabs.childTabs());
      xmlDocument.setParameter("theme", vars.getTheme());
      NavigationBar nav = new NavigationBar(this, vars.getLanguage(), "GenerateHelp.html",
          classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb());
      xmlDocument.setParameter("navigationBar", nav.toString());
      LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "GenerateHelp.html",
          strReplaceWith);
      xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    {
      OBError myMessage = vars.getMessage("GenerateHelp");
      vars.removeMessage("GenerateHelp");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

    // //----

    /*
     * String strMessage = vars.getSessionValue("GenerateHelp.message"); if (!strMessage.equals(""))
     * { vars.removeSessionValue("GenerateHelp.message"); strMessage = "alert('" +
     * Replace.replace(strMessage, "'", "\'") + "');"; } xmlDocument.setParameter("body",
     * strMessage);
     */
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLEDIR", "AD_Window_ID",
          "", "", Utility.getContext(this, vars, "#AccessibleOrgTree", "GenerateHelp"), Utility
              .getContext(this, vars, "#User_Client", "GenerateHelp"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "GenerateHelp", "");
      xmlDocument.setData("reportAD_Window_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "Servlet GenerateHelp";
  } // end of getServletInfo() method
}
