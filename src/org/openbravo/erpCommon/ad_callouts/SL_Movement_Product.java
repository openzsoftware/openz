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
package org.openbravo.erpCommon.ad_callouts;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.controller.callouts.CalloutStructure;
import org.openz.view.SelectBoxhelper;

public class SL_Movement_Product extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strChanged = vars.getStringParameter("inpLastFieldChanged");
      if (log4j.isDebugEnabled())
        log4j.debug("CHANGED: " + strChanged);     
      String strLocator = vars.getStringParameter("inpmProductId_LOC");
      String strQty = vars.getNumericParameter("inpmProductId_QTY");
      String strUOM = vars.getStringParameter("inpmProductId_UOM");
      String strAttribute = vars.getStringParameter("inpmProductId_ATR");
      //String strQtyOrder = vars.getNumericParameter("inpmProductId_PQTY");
      String strQtyOrder = "";
      //String strPUOM = vars.getStringParameter("inpmProductId_PUOM");
      String strPUOM = "";
      String strMProductID = vars.getStringParameter("inpmProductId");
      String strWindowId = vars.getStringParameter("inpwindowId");
      String strIsSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
      String strWharehouse = Utility.getContext(this, vars, "#M_Warehouse_ID", strWindowId);
      String strTabId = vars.getStringParameter("inpTabId");

      try {
        printPage(response, vars, strChanged, strMProductID, strLocator, strQty, strUOM,
            strAttribute, strQtyOrder, strPUOM, strIsSOTrx, strWharehouse, strTabId);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strChanged,
      String strMProductID, String strLocator, String strQty, String strUOM, String strAttribute,
      String strQtyOrder, String strPUOM, String strIsSOTrx, String strWharehouse, String strTabId)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );

    try {
      if (strChanged.equals("inpmProductId")&& ! strUOM.equals("")){
        callout.appendComboTable("inpcUomId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "C_UOM_ID",null,null,"",false), strUOM);
        callout.appendString("inpmLocatorId", strLocator);
        callout.appendString("inpmLocatorId_DES", LocatorComboData.selectLocatorName(this, vars.getLanguage(), strLocator));
        callout.appendNumeric("inpmovementqty", strQty);
      }
    
 
       // callout.appendMessage("NoLocationNoTaxCalculated", this, vars);

    
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(callout.returnCalloutAppFrame());
    out.close();
    
    } catch (Exception ex) {
      pageErrorCallOut(response);
    }
  
  }
}
