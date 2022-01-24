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
import java.math.BigDecimal;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.utils.Replace;

public class SL_Summit extends HttpSecureAppServlet {
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
      if (log4j.isDebugEnabled())
        log4j.debug("CHANGED: " + strChanged);
      String strQty = vars.getNumericParameter("inpqty");
      String strPriceActual = vars.getNumericParameter("inppriceactual");
      String strProduct = vars.getStringParameter("inpmProductId");
      String strTabId = vars.getStringParameter("inpTabId");
      String strDirectsalesId = vars.getStringParameter("inpzssiDirectsalesId");
      if (strDirectsalesId.isEmpty())
        strDirectsalesId = vars.getStringParameter("inpzssiDirectpurchaseId");
      if (strDirectsalesId.isEmpty())
        strDirectsalesId = "dummy";
      try {
        printPage(response, vars, strChanged, strQty, strPriceActual, strProduct, strTabId,
            strDirectsalesId);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  void printPage(HttpServletResponse response, VariablesSecureApp vars, String strChanged,
      String strQty, String strPriceActual, String strProduct, String strTabId,
      String strDirectsalesId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();
    SLSummitData[] data = SLSummitData.select(this, strDirectsalesId);
    BigDecimal qty, priceActual, lineNetAmt, summedLineAmt;
    Integer i = 0;
    String strLinestring = "";
    String strCurQty, strCurAmt, strProductname;
    summedLineAmt = ZERO;
    if (data.length > 0) {
      while (i < data.length) {
        strCurQty = data[i].qty;
        strCurAmt = data[i].priceactual;
        qty = (!Utility.isBigDecimal(strCurQty) ? ZERO : new BigDecimal(strCurQty));
        priceActual = (!Utility.isBigDecimal(strCurAmt) ? ZERO : new BigDecimal(strCurAmt));
        lineNetAmt = priceActual.multiply(qty);
        summedLineAmt = summedLineAmt.add(lineNetAmt);
        strProductname = SLSummitData.selectProduct(this, data[i].mProductId);
        if (strLinestring != "")
          strLinestring = strLinestring + "\\n";
        strLinestring = strLinestring + "Artikel: " + strProductname + ", Anzahl: "
            + String.format("%1$-" + 4 + "s", qty.toString()) + " , Preis: "
            + String.format("%1$-" + 6 + "s", priceActual.toString()) + "€ , Summe: "
            + String.format("%1$-" + 6 + "s", lineNetAmt.toString()) + "€";
        i = i + 1;
      }
    }
    qty = (!Utility.isBigDecimal(strQty) ? ZERO : new BigDecimal(strQty));
    priceActual = (!Utility.isBigDecimal(strPriceActual) ? ZERO : new BigDecimal(strPriceActual));
    lineNetAmt = priceActual.multiply(qty);
    summedLineAmt = summedLineAmt.add(lineNetAmt);
    if (strLinestring != "")
      strLinestring = strLinestring + "\\n";
    strProductname = SLSummitData.selectProduct(this, strProduct);
    strLinestring = strLinestring + "Artikel: " + strProductname + ", Anzahl: "
        + String.format("%1$-" + 4 + "s", qty.toString()) + " , Preis: "
        + String.format("%1$-" + 6 + "s", priceActual.toString()) + "€ , Summe: "
        + String.format("%1$-" + 6 + "s", lineNetAmt.toString()) + "€";
    strLinestring = strLinestring + "\\n Gesamtsumme: " + summedLineAmt.toString() + "€";
    // Update Complete Order
    SLSummitData.updateText(this, Replace.replace(strLinestring, "\\n", "\r"),vars.getClient(),vars.getOrg());
    // Update GUI
    StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='zssiSL_Summit';\n\n");
    resultado.append("var respuesta = new Array(");

    // resultado.append("new Array(\"inptextlines\", " + "HUHU" + "),");
    // resultado.append("new Array(\"inppriceactual\", " + "12" + "),");
    resultado.append("new Array(\"inptextlines\", " + "\"" + strLinestring + "\"" + ")");

    resultado.append(");");
    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());

    out.close();
  }
}
