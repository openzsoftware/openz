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
import org.openz.controller.callouts.CalloutData;
import org.openz.controller.callouts.CalloutStructure;
import org.openz.view.SelectBoxhelper;

public class SL_Internal_Consumption_Product extends ProductTextHelper {
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
      String strProduct = vars.getStringParameter("inpmProductId");
      // String strLocator = vars.getStringParameter("inpmLocatorId");
      String strPLocator = vars.getStringParameter("inpmProductId_LOC");
      String strADOrgID = vars.getStringParameter("inpadOrgId");
      if (strPLocator.isEmpty())
        strPLocator =SLInternalConsumptionProductData.selectStdLocator4Product(this, strProduct, strADOrgID);        
      String strPAttr = vars.getStringParameter("inpmProductId_ATR");
     // String strPQty = vars.getNumericParameter("inpmProductId_PQTY");
      String strPQty = "";
     // String strPUOM = vars.getStringParameter("inpmProductId_PUOM");
      String strPUOM = "";
      String strQty = vars.getNumericParameter("inpmProductId_QTY");
      String strTabId = vars.getStringParameter("inpTabId");
      String strLang = vars.getLanguage();
      

      try {
        printPage(response, vars, strChanged, strProduct, strPLocator, strPAttr, strPQty, strPUOM,
            strQty, strTabId,strLang,strADOrgID);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strChanged,
      String strProduct, String strPLocator, String strPAttr, String strPQty, String strPUOM,
      String strQty, String strTabId,String strLang,String strADOrgID) throws IOException, ServletException {
    
  if (vars.commandIn("DEFAULT")) { 

    // New Callout Structure
    CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
    
    try {
      String strUOM = CalloutData.getUomIdOfProduct(this, strProduct);  
      if (strChanged.equals("inpmProductId")){
        FieldProvider[] fp = SelectBoxhelper.getReferenceDataByRefName(this, vars, "c_uom_id", null,null, strUOM, true);
        callout.appendComboTable("inpcUomId", fp, strUOM);
        if (CalloutData.hasSecondaryUOM(this, strProduct).equals("1")) {
          callout.appendString("strHASSECONDUOM", "1");
          CalloutData data = new CalloutData();
          data.mProductId=strProduct;
          fp = SelectBoxhelper.getReferenceDataByRefName(this, vars, "M_Product_UOM", "",data, "", true);
          callout.appendComboTable("inpmProductUomId", fp, "");
        } else
          callout.appendString("strHASSECONDUOM", "0");
        callout.appendString("mLocatorId_DES", FormatUtilities.replaceJS(SLInternalConsumptionProductData.selectLocator(this,strPLocator)));        
        callout.appendString("inpmLocatorId",  strPLocator);
        callout.appendString("inpmAttributesetinstanceIdId_R",FormatUtilities.replaceJS(SLInOutLineProductData.attribute(this, strPAttr)));
        callout.appendString("inpmAttributesetinstanceId",strPAttr);
      }
      
   
         // callout.appendMessage("NoLocationNoTaxCalculated", this, vars);

      
      response.setContentType("text/html; charset=UTF-8");
      PrintWriter out = response.getWriter();
      out.println(callout.returnCalloutAppFrame());
      out.close();
    } catch (Exception ex) {
      pageErrorCallOut(response);
    }
  } else
    pageError(response);
}
}
