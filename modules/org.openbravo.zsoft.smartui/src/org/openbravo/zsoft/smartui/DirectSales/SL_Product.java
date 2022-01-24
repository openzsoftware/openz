/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.openbravo.zsoft.smartui.DirectSales;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.controller.callouts.CalloutData;
import org.openz.controller.callouts.CalloutStructure;
import org.openz.view.SelectBoxhelper;

public class SL_Product extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strProductID = vars.getStringParameter("inpmProductId"); 
      String strChanged = vars.getStringParameter("inpLastFieldChanged");

      // New Callout Structure
      CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
      
      try {
        String strUomID = CalloutData.getUomIdOfProduct(this, strProductID);
        String strPrice = CalloutData.getPriceOfProduct(this, strProductID);
        if (strChanged.equals("inpmProductId")&& ! strUomID.equals("")){
          callout.appendComboTable("inpcUomId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "C_UOM_ID",null,null,"",false), strUomID);
          //callout.appendNumeric("inppriceactual", strPrice);
        }
        
        if (strChanged.equals("inppriceactual")){
          String price=vars.getNumericParameter("inppriceactual");
          if (Float.parseFloat(price)>0)
            callout.appendMessage("directpurchaseevenue", this, vars);
          else
            callout.appendMessage("OK", this, vars);
        } 

        
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
