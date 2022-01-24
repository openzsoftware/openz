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

package org.openbravo.erpCommon.ad_workflow;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.MenuData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.erpCommon.utility.VerticalMenu;
import org.openbravo.xmlEngine.XmlDocument;

public class WorkflowControl extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  @Override
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  @Override
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    final VariablesSecureApp vars = new VariablesSecureApp(request);

    final String strAD_Workflow_ID = vars.getGlobalVariable("inpadWorkflowId",
        "WorkflowControl|adWorkflowId");

    if (!vars.commandIn("DEFAULT") && !hasGeneralAccess(vars, "F", strAD_Workflow_ID)) {
      bdError(request, response, "AccessTableNoView", vars.getLanguage());
      return;
    }

    if (vars.commandIn("DEFAULT")) {
      printPage(response, vars, strAD_Workflow_ID);
    } else if (vars.commandIn("WORKFLOW")) {
      printPageDataSheet(response, vars, strAD_Workflow_ID);
    } else if (vars.commandIn("WORKFLOW_ACTION")) {
      final String strAction = vars.getRequiredStringParameter("inpAction");
      final String strClave = vars.getRequiredStringParameter("inpClave");
      final String strPath = getUrlPath(vars.getLanguage(), strAction, strClave);

      printPageRedirect(response, vars, strPath);
    } else
      pageError(response);
  }

  private void printPageRedirect(HttpServletResponse response, VariablesSecureApp vars,
      String strPath) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print page redirect");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_workflow/WorkflowControl_Redirect").createXmlDocument();

    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("href", strPath);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private String windowIcon(String action) {
    String strIcon = "";
    if (action.equals("W"))
      strIcon = "Popup_Workflow_Button_Icon Popup_Workflow_Button_Icon_childWindows";// Window
    else if (action.equals("X"))
      strIcon = "Popup_Workflow_Button_Icon Popup_Workflow_Button_Icon_childForms";// Form
    else if (action.equals("P"))
      strIcon = "Popup_Workflow_Button_Icon Popup_Workflow_Button_Icon_childProcesses";// Process
    else if (action.equals("T"))
      strIcon = "Popup_Workflow_Button_Icon Popup_Workflow_Button_Icon_childTasks";// Task
    else if (action.equals("R"))
      strIcon = "Popup_Workflow_Button_Icon Popup_Workflow_Button_Icon_childProcesses";// Process
    else if (action.equals("F"))
      strIcon = "Popup_Workflow_Button_Icon Popup_Workflow_Button_Icon_childWorkflows";// WorkFlow
    else
      strIcon = "Popup_Workflow_Button_Icon Popup_Workflow_Button_Icon_childWindows";// Windows
    return strIcon;
  }

  private String getUrlPath(String language, String action, String clave) throws ServletException {
    String strWindow = "", strForm = "", strProcess = "", strTask = "", strWorkflow = "";
    if (action.equals("W"))
      strWindow = clave;
    else if (action.equals("X"))
      strForm = clave;
    else if (action.equals("P"))
      strProcess = clave;
    else if (action.equals("T"))
      strTask = clave;
    else if (action.equals("R"))
      strProcess = clave;
    else if (action.equals("F"))
      strWorkflow = clave;
    else
      return "";

    final MenuData[] menuData = MenuData.selectData(this, language, strWindow, strProcess, strForm,
        strTask, strWorkflow);
    if (menuData == null || menuData.length == 0)
      throw new ServletException("WorkflowControl.getUrlPath() - Error while getting data");

    return VerticalMenu.getUrlStringStatic(strDireccion, menuData[0].name, menuData[0].action,
        menuData[0].classname, menuData[0].mappingname, menuData[0].adWorkflowId,
        menuData[0].adTaskId, menuData[0].adProcessId, "N", "");
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars,
      String strAD_Workflow_ID) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: print page");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_workflow/WorkflowControl_Response").createXmlDocument();

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");

    xmlDocument.setParameter("workflow", strAD_Workflow_ID);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strAD_Workflow_ID) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    WorkflowControlData[] workflowName = null;
    if (vars.getLanguage().equals("en_US")) {
      workflowName = WorkflowControlData.selectWorkflowName(this, strAD_Workflow_ID);
    } else {
      workflowName = WorkflowControlData.selectWorkflowNameTrl(this, vars.getLanguage(),
          strAD_Workflow_ID);
    }
    final String[] discard = { "" };
    if (workflowName == null || workflowName.length == 0 || workflowName[0].help.equals(""))
      discard[0] = new String("fieldWorkflowHelp");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_workflow/WorkflowControl", discard).createXmlDocument();

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("paramLanguage", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());
    if (workflowName != null && workflowName.length > 0) {
      xmlDocument.setParameter("workflowName", workflowName[0].name);
      xmlDocument.setParameter("workflowHelp", workflowName[0].help);
    }
    xmlDocument.setParameter("detail", buildHtml(vars, strAD_Workflow_ID));

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private String buildHtml(VariablesSecureApp vars, String strAD_Workflow_ID)
      throws ServletException {
    final String firstNode = WorkflowControlData.selectFirstNode(this, strAD_Workflow_ID);
    if (firstNode.equals("")) {
      log4j.warn("WorkflowControl.buildHtml() - There're no first node defined for workflow: "
          + strAD_Workflow_ID);
      return "";
    }
    final StringBuffer sb = new StringBuffer();
    WorkflowControlData[] name = null;
    if (vars.getLanguage().equals("en_US"))
      name = WorkflowControlData.selectFirstNodeData(this, firstNode);
    else
      name = WorkflowControlData.selectFirstNodeDataTrl(this, vars.getLanguage(), firstNode);
    sb.append(buildButton(vars, name[0])).append("\n");
    sb.append(buildLevel(vars, firstNode));

    return sb.toString();
  }

  private String buildLevel(VariablesSecureApp vars, String node) throws ServletException {
    WorkflowControlData[] data = null;
    if (vars.getLanguage().equals("en_US"))
      data = WorkflowControlData.select(this, Utility.getContext(this, vars, "#User_Client",
          "WorkflowControl"), Utility.getContext(this, vars, "#AccessibleOrgTree",
          "WorkflowControl"), node);
    else
      data = WorkflowControlData.selectTrl(this, vars.getLanguage(), Utility.getContext(this, vars,
          "#User_Client", "WorkflowControl"), Utility.getContext(this, vars, "#AccessibleOrgTree",
          "WorkflowControl"), node);
    if (data == null || data.length == 0)
      return "";
    final StringBuffer sb = new StringBuffer();
    if (data.length > 1) {
      sb.append("<tr><td colspan=\"2\">\n");
      sb.append("  <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"><tr>");
    }
    for (int i = 0; i < data.length; i++) {
      if (data.length > 1) {
        sb
            .append("<td valign=\"top\"><table cellspacing=\"0\" cellpadding=\"0\" class=\"Popup_Client_TableWorkflow\">\n");
        sb.append("  <tr>\n");
        for (int j = 0; j < 2; j++)
          sb.append("<td class=\"TableEdition_OneCell_width\"></td>\n");
        sb.append("  </tr>\n");
      }
      sb.append(line());
      sb.append(buildButton(vars, data[i])).append("\n");
      sb.append(buildLevel(vars, data[i].adWfNodeId));
      if (data.length > 1) {
        sb.append("</table></td>\n");
      }
    }
    if (data.length > 1) {
      sb.append("</tr></table>\n");
      sb.append("</td></tr>\n");
    }
    return sb.toString();
  }

  private String claveWindow(WorkflowControlData data) {
    if (data.action.equals("W"))
      return data.adWindowId;
    else if (data.action.equals("X"))
      return data.adFormId;
    else if (data.action.equals("P"))
      return data.adProcessId;
    else if (data.action.equals("T"))
      return data.adTaskId;
    else if (data.action.equals("R"))
      return data.adProcessId;
    else if (data.action.equals("F"))
      return data.workflowId;
    else
      return "";
  }

  private String buildButton(VariablesSecureApp vars, WorkflowControlData data)
      throws ServletException {
    final StringBuffer html = new StringBuffer();
    final String strClave = claveWindow(data);
    html.append("<tr>\n");
    html.append("  <td class=\"Popup_Workflow_Button_ContentCell\">\n");
    html
        .append("    <a href=\"#\" class=\"Popup_Workflow_Button\" onmouseout=\"window.status='';return true;\" onmouseover=\"'");
    html.append(data.name).append("';return true;\" onblur=\"this.hideFocus=false\" ");
    html.append(" onClick=\"this.hideFocus=true;callServlet('").append(data.action).append("', '")
        .append(strClave).append("');return false;\">\n");
    html.append("    <img src=\"").append(strReplaceWith).append("/images/blank.gif\" class=\"")
        .append(windowIcon(data.action)).append("\" border=\"0\" title=\"");
    html.append(data.name).append("\"></img></a>\n");
    html.append("</td>\n");
    html.append("<td class=\"Popup_Workflow_text_ContentCell\">\n");
    html.append("  <a href=\"#\" onclick=\"callServlet('").append(data.action).append("', '")
        .append(strClave).append("');");
    html.append("return false;\" onmouseover=\"window.status='").append(data.name).append(
        "';return true;\" ");
    html.append("onmouseout=\"window.status='';return true;\" class=\"Popup_Workflow_text\">");
    html.append(data.name).append("</a>\n");
    html.append("</td>\n");
    html.append("</tr>\n");
    return html.toString();
  }

  private String line() {
    final StringBuffer html = new StringBuffer();
    html.append("<tr>");
    html
        .append(
            "<td class=\"Popup_Workflow_arrow_ContentCell\"><img class=\"Popup_Workflow_arrow\" src=\"")
        .append(strReplaceWith).append("/images/blank.gif\" border=\"0\"></img></td>");
    html.append("<td></td></tr>");
    return html.toString();
  }

  @Override
  public String getServletInfo() {
    return "Servlet WorkflowControl";
  } // end of getServletInfo() method
}
