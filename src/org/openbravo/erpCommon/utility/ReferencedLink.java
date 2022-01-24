/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011-2012 Stefan Zimmermann
****************************************************************************************************************************************************

 */
package org.openbravo.erpCommon.utility;

import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

public class ReferencedLink extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {

      String strKeyReferenceColumnName = vars
          .getRequiredStringParameter("inpKeyReferenceColumnName");
      // String strKeyReferenceName =
      // vars.getRequiredStringParameter("inpKeyReferenceName");
      // String strTableId =
      // vars.getRequiredStringParameter("inpTableId");
      String strTableReferenceId = vars.getRequiredStringParameter("inpTableReferenceId");
      String strKeyReferenceId = vars.getStringParameter("inpKeyReferenceId");
      // String strTabId = vars.getStringParameter("inpTabId");
      String strWindowId = vars.getStringParameter("inpwindowId");
      String strTableName = ReferencedLinkData.selectTableName(this, strTableReferenceId);
      String isSOTrx = vars.getSessionValue(strWindowId + "|ISSOTRX");

      if (log4j.isDebugEnabled())
        log4j.debug("strKeyReferenceColumnName:" + strKeyReferenceColumnName
            + " strTableReferenceId:" + strTableReferenceId + " strKeyReferenceId:"
            + strKeyReferenceId + " strWindowId:" + strWindowId + " strTableName:" + strTableName);
      {
       
      }

        String strTableRealReference = strTableReferenceId;
        // SZ Added Labellink Dispatcher
        String evaluatedTabId=ReferencedLinkData.getReferenceLinkTargetTab(this, strTableReferenceId, strKeyReferenceId);
        String tabId;
        if (! evaluatedTabId.equals(""))
          tabId =evaluatedTabId;
        else {
          ReferencedLinkData[] data = ReferencedLinkData.selectWindows(this, strTableRealReference);
          if (data == null || data.length == 0)
            throw new ServletException("Window not found");
  
          strWindowId = data[0].adWindowId;
          if (isSOTrx.equals("N") && !data[0].poWindowId.equals(""))
            strWindowId = data[0].poWindowId;
  
          data = ReferencedLinkData.select(this, strWindowId, strTableReferenceId);
          if (data == null || data.length == 0)
            throw new ServletException("Window not found: " + strWindowId);
          tabId = data[0].adTabId;
          if (strKeyReferenceId.equals("")) {
            data = ReferencedLinkData.selectParent(this, strWindowId);
            if (data == null || data.length == 0)
              throw new ServletException("Window parent not found: " + strWindowId);
            tabId = data[0].adTabId;
          }
        }
      StringBuffer cadena = new StringBuffer();

      cadena.append(Utility.getTabURL(this, tabId, "E"));
      cadena.append("?Command=").append((strKeyReferenceId.equals("") ? "DEFAULT" : "DIRECT"))
          .append("&");
      cadena.append("inpDirectKey").append("=").append(strKeyReferenceId);
      if (log4j.isDebugEnabled())
        log4j.debug(cadena.toString());
      response.sendRedirect(cadena.toString());
    }
    else
      throw new ServletException();
  }

  public String getServletInfo() {
    return "Servlet that presents the referenced links";
  } // end of getServletInfo() method
}
