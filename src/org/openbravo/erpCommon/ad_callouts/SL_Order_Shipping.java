/*
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 */
package org.openbravo.erpCommon.ad_callouts;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.*;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.xmlEngine.XmlDocument;

public class SL_Order_Shipping extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  private static final BigDecimal ZERO = new BigDecimal(0.0);
  
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strChanged = vars.getStringParameter("inpLastFieldChanged");
      if (strChanged.equals("inpmProductId"))
      {
          if (log4j.isDebugEnabled())
            log4j.debug("CHANGED: " + strChanged);
          String strMProductID = vars.getStringParameter("inpmProductId");
          String strMPriceListID = vars.getStringParameter("inpmPricelistId");
          String strQty = vars.getStringParameter("inpqty");
          String strBpartner = vars.getStringParameter("inpcBpartnerId");
          String strDateordered = vars.getStringParameter("inpdateordered");
          String strCcurrencyId = vars.getStringParameter("inpcCurrencyId");
          String strTabId = vars.getStringParameter("inpTabId");
          // If qty is not set, assume 1
          if (strQty.equals(""))
            strQty="1";
          try {
            printPage(response, vars, strMProductID,strMPriceListID,strQty,strBpartner,strDateordered ,strCcurrencyId,strTabId);
          } catch (ServletException ex) {
            pageErrorCallOut(response);
          }
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars,
      String strMProductID,String strMPriceListID,String strQty,String strBpartner,String strDateordered ,String strCcurrencyId,String strTabId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();
    
    String strPriceActual = SLOrderProductData.getOffersPriceDirect(this, strDateordered,
                                               strBpartner, strMProductID, 
                                               SLOrderProductData.getProductPrice(this, strMProductID,
                                               SLOrderPriceListData.getPriceListVersion(this, strMPriceListID, strDateordered)), 
                                               strQty, strMPriceListID,strCcurrencyId);
    BigDecimal priceActual = (strPriceActual.equals("") ? ZERO : (new BigDecimal(strPriceActual))).setScale(
          2, RoundingMode.HALF_UP);
    BigDecimal qty = (strQty.equals("") ? ZERO : (new BigDecimal(strQty))).setScale(
        2, RoundingMode.HALF_UP);

    //BigDecimal freightamt = priceActual.multiply(qty);
    BigDecimal freightamt =priceActual;
    StringBuffer resultado = new StringBuffer();

    resultado.append("var calloutName='SL_Order_Shipping';\n\n");
    resultado.append("var respuesta = new Array(");

    resultado.append("new Array(\"inpfreightamt\", \"" + freightamt.toString() + "\"),");
    resultado.append("new Array(\"inpqty\", \"" + strQty + "\")\n");

    resultado.append(");\n");

    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }
}
