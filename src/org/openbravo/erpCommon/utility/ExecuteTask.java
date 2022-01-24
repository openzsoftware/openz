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
package org.openbravo.erpCommon.utility;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.xmlEngine.XmlDocument;

public class ExecuteTask extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strTaskId = vars.getGlobalVariable("inpadTaskId", "ExecuteTask|taskId");
      printPageDefault(response, vars, strTaskId);
    } else if (vars.commandIn("EXECUTE")) {
      String strTaskId = vars.getGlobalVariable("inpadTaskId", "ExecuteTask|taskId");
      ExecuteTaskData[] data = null;
      if (vars.getLanguage().equals("en_US")) {
        data = ExecuteTaskData.select(this, strTaskId);
      } else {
        data = ExecuteTaskData.selectTrl(this, vars.getLanguage(), strTaskId);
      }
      if (data == null || data.length == 0)
        throw new ServletException("Task not found: " + strTaskId);
      if (!hasGeneralAccess(vars, "T", strTaskId)) {
        bdError(request, response, "AccessTableNoView", vars.getLanguage());
        return;
      }

      String command = Utility.parseTranslation(this, vars, vars.getLanguage(), data[0].osCommand);
      String taskinstance = SequenceIdData.getUUID();
      ExecuteTaskData.insert(this, taskinstance, vars.getClient(), vars.getOrg(), vars.getUser(),
          strTaskId);
      executeCommand(response, vars, data[0].name, command);
    } else if (vars.commandIn("EXECUTE_CMD")) {
      String command = vars.getGlobalVariable("inpCommandText", "ExecuteTask|commandtext");
      // The permissions of the tasks executor must be checked
      command = Utility.parseTranslation(this, vars, vars.getLanguage(), command);
      executeCommand(response, vars, command, command);
    } else
      pageError(response);
  }

  private void printPageDefault(HttpServletResponse response, VariablesSecureApp vars,
      String strTaskId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Default");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/utility/TaskDefault").createXmlDocument();
    xmlDocument.setParameter("taskId", strTaskId);

    out.println(xmlDocument.print());
    out.close();
  }

  private void executeCommand(HttpServletResponse response, VariablesSecureApp vars, String Tittle,
      String command) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Default");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();

    out.println("<html>");
    out.println("<head>");
    out.println("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">");
    out.println("<title>Aviso</title>");
    out.println("<link REL=\"stylesheet\" TYPE=\"text/css\" HREF=\"" + strDireccion + "/web/skins/"
        + vars.getTheme() + "/Popup/Popup.css\" TITLE=\"Style\">");
    out.println("<script language=\"JavaScript\" type=\"text/javascript\" src=\"" + strDireccion
        + "/web/js/mensaje.js\"></script>");
    out.println("<script language=\"JavaScript\" type=\"text/javascript\" src=\"" + strDireccion
        + "/web/js/utils.js\"></script>");
    out.println("<script language=\"JavaScript\" type=\"text/javascript\">  defaultLang = \""
        + vars.getLanguage() + "\";</script>");
    out.println("</head>");
    out.println("<body>");
    out.println("<form name=\"form1\" method=\"post\" action=\"ExecuteTask.html\">");
    out.println("<div class=\"Popup_ContentPane_CircleLogo\">");
    out.println("  <div class=\"Popup_WindowLogo\">");
    out.println("    <img class=\"Popup_WindowLogo_Icon Popup_WindowLogo_Icon_task\" src=\""
        + strDireccion + "/web/images/blank.gif\" border=0/></img>");
    out.println("  </div>");
    out.println("</div>");
    out.println("");
    out.println("<table cellspacing=\"0\" cellpadding=\"0\" width=\"100%\">");
    out.println("");
    out.println("  <tr>");
    out.println("    <td>");
    out
        .println("      <table cellspacing=\"0\" cellpadding=\"0\" class=\"Popup_ContentPane_NavBar\">");
    out.println("        <tr class=\"Popup_NavBar_bg\"><td></td>");
    out.println("          <td class=\"Popup_NavBar_separator_cell\"></td>");
    out.println("          <td class=\"Popup_NavBar_bg_logo_left\"></td>");
    out
        .println("          <td class=\"Popup_NavBar_bg_logo\" width=\"1\" onclick=\"openNewBrowser('http://www.OpenZ.com', 'OpenZ');return false;\"><img src=\""
            + strDireccion
            + "/web/images/blank.gif\" alt=\"OpenZ\" title=\"OpenZ\" border=\"0\" id=\"openbravoLogo\" class=\"Main_NavBar_logo_openz\" /></td>");
    out.println("          <td class=\"Popup_NavBar_bg_logo_right\"></td>");
    out.println("          <td class=\"Popup_NavBar_Popup_title_cell\"><span>" + Tittle
        + "</span></td>");
    out.println("          <td class=\"Popup_NavBar_bg_logo_left\"></td>");
    out
        .println("          <td class=\"Popup_NavBar_bg_logo\" width=\"1\" onclick=\"openNewBrowser('http://www.openbravo.com', 'Openbravo');return false;\"><img src=\""
            + strDireccion
            + "/web/images/blank.gif\" alt=\"Openbravo\" title=\"Openbravo\" border=\"0\" id=\"openbravoLogo\" class=\"Popup_NavBar_logo\" /></td>");
    out.println("          <td class=\"Popup_NavBar_bg_logo_right\"></td>");
    out.println("          <td class=\"Popup_NavBar_separator_cell\"></td>");
    out.println("        </tr>");
    out.println("      </table>");
    out.println("    </td>");
    out.println("  </tr>");
    out.println("");
    out.println("  <tr>");
    out.println("    <td>");
    out
        .println("      <table cellspacing=\"0\" cellpadding=\"0\" class=\"Popup_ContentPane_SeparatorBar\">");
    out.println("        <tr>");
    out.println("          <td class=\"Popup_SeparatorBar_bg\"></td>");
    out.println("        </tr>");
    out.println("      </table>");
    out.println("    </td>");
    out.println("  </tr>");
    out.println("");
    out.println("  <tr>");
    out.println("    <td>");
    out
        .println("      <table cellspacing=\"0\" cellpadding=\"0\" class=\"Popup_ContentPane_InfoBar\">");
    out.println("        <tr>");
    out.println("          <td class=\"Popup_InfoBar_Icon_cell\"><img src=\"" + strDireccion
        + "/web/images/blank.gif\" border=\"0\" class=\"Popup_InfoBar_Icon_info\" /></td>");
    out.println("          <td class=\"Popup_InfoBar_text_table\">");
    out.println("            <table>");
    out.println("              <tr>");
    out.println("                <td class=\"Popup_InfoBar_text\" id=\"processMessage\">"
        + Utility.messageBD(this, "Processing", vars.getLanguage()) + "</td>");
    out.println("              </tr>");
    out.println("            </table>");
    out.println("          </td>");
    out.println("        </tr>");
    out.println("      </table>");
    out.println("    </td>");
    out.println("  </tr>");
    out.println("");
    out.println("  <tr>");
    out.println("    <td>");
    out.println("      <div class=\"Popup_ContentPane_Client\" style=\"overflow: auto;\">");
    out
        .println("        <table cellspacing=\"0\" cellpadding=\"0\" class=\"Popup_Client_TablePopup\">");
    out.println("");
    out.println("          <tr>");
    out.println("");
    out.println("            <td class=\"TableEdition_FourCells_width\">");
    out.flush();
    out.println("             <p class=\"Regular_Paragraph\">");
    executeCommandTask(out, vars, command);
    out.println("             </p>");
    out.println("            </td>");
    out.println("          </tr>");
    out.println("");
    out.println("        </table>");
    out.println("      </div>");
    out.println("    </td>");
    out.println("  </tr>");
    out.println("</table>");
    out
        .println("<script language=\"JavaScript\" type=\"text/javascript\">layer('processMessage', '"
            + Utility.messageBD(this, "ProcessOK", vars.getLanguage())
            + "', true, false);</script>");
    out.println("</form>");
    out.println("</body>");
    out.println("</html>");
    out.close();
  }

  private void executeCommandTask(PrintWriter out, VariablesSecureApp vars, String cmd)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("ExecuteTask.executeCommand: " + cmd);
    if (cmd == null || cmd.equals("")) {
      out.println(Utility.messageBD(this, "EmptyCommand", vars.getLanguage()));
      return;
    }
    // if(m_task != null && m_task.isAlive()) m_task.interrupt();
    Task m_task = new Task(cmd);
    m_task.start();
    do {
      try {
        Thread.sleep(500L);
      } catch (InterruptedException ioe) {
        log4j.error("ExecuteTask.executeCommand: " + ioe);
      }
      if (!m_task.getOut().toString().equals(""))
        out.println("<span>" + m_task.getOut().toString() + "</span><br>");
      if (!m_task.getErr().toString().equals(""))
        out.println("<span class=\"error\">" + m_task.getErr().toString() + "</span><br>");
      out.flush();
    } while (m_task.isAlive());
    if (log4j.isDebugEnabled())
      log4j.debug("ExecuteTask.executeCommand - done");
  }

  public String getServletInfo() {
    return "Task executorServlet";
  } // end of getServletInfo() method
}
