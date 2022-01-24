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
 * All portions are Copyright (C) 2001-2006 Openbravo SL
 * All Rights Reserved.
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.ad_reports;

import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.Sqlc;
import org.openbravo.erpCommon.utility.Utility;

public class ReportAcctRedirectUtility extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    if (vars.commandIn("DEFAULT")) {
      String strTableId = vars.getRequiredStringParameter("inpadTableId");
      String strRecordId = vars.getRequiredStringParameter("inprecordId");
      String strDocBaseType = vars.getRequiredStringParameter("inpdocbasetype");
      ReportAcctRedirectUtilityData[] data = ReportAcctRedirectUtilityData.select(this, strTableId,
          strDocBaseType, vars.getClient());
      if (data == null || data.length == 0)
        bdError(request, response, "RecordError", vars.getLanguage());
      else {
        String inputName = "inp" + Sqlc.TransformaNombreColumna(data[0].columnname);

        String strWindowPath = Utility.getTabURL(this, data[0].adTabId, "R");
        if (strWindowPath.equals(""))
          strWindowPath = strDefaultServlet;

        response.sendRedirect(strWindowPath + "?" + "Command=DIRECT&" + inputName + "="
            + strRecordId);
      }
    } else
      pageError(response);
  }

  public String getServletInfo() {
    return "Servlet ReportAcctRedirectUtility";
  } // end of getServletInfo() method
}
