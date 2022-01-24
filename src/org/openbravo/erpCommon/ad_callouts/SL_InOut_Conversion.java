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
* SZ: Added Back Conversion from initUOM to Order UOM
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
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;

public class SL_InOut_Conversion extends HttpSecureAppServlet {
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
      String strUOM = vars.getStringParameter("inpcUomId");
      String strMProductUOMID = vars.getStringParameter("inpmProductUomId");
      String strQuantityOrder  = "";
      String strQuantity="";
      String strTabId = vars.getStringParameter("inpTabId");
      if (strChanged.equals("inpquantityorder")) strQuantityOrder=vars.getNumericParameter("inpquantityorder");
      if (strChanged.equals("inpmovementqty")) strQuantity=vars.getNumericParameter("inpmovementqty");;
      try {
        printPage(response, vars, strUOM, strMProductUOMID, strQuantityOrder,  strQuantity);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strUOM,
      String strMProductUOMID, String strQuantityOrder, String strQuantity) throws IOException,
      ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();
    if (strUOM.startsWith("\""))
      strUOM = strUOM.substring(1, strUOM.length() - 1);
    int stdPrecision = Integer.valueOf(SLInvoiceConversionData.stdPrecision(this, strUOM))
        .intValue();
    String strInitUOM = SLInvoiceConversionData.initUOMId(this, strMProductUOMID);
    String strMultiplyRate;
    String strDivideRate;
    
    if (strInitUOM.equals(strUOM) | strMProductUOMID.equals("")){
      strMultiplyRate = "1";
      strDivideRate ="1";
    }
    else {
        strMultiplyRate = SLInvoiceConversionData.multiplyRate(this, strInitUOM, strUOM);
        strDivideRate = SLInvoiceConversionData.divideRate(this,strInitUOM, strUOM);
        
        if (strMultiplyRate.equals("")) {
          strMultiplyRate = SLInvoiceConversionData.divideRate(this, strUOM, strInitUOM);
          strDivideRate = SLInvoiceConversionData.divideRate(this,strUOM, strInitUOM);
        }
        if (strMultiplyRate.equals("")) {
          strMultiplyRate = "1";
          strDivideRate ="1";
        }
    }
      

    BigDecimal quantity,quantityOrder, movementQty, multiplyRate, divideRate;

    multiplyRate = new BigDecimal(strMultiplyRate);
    divideRate= new BigDecimal(strDivideRate);
    
    StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='SL_InOut_Conversion';\n\n");
    if (strMultiplyRate.equals("1")) {
      resultado.append("var respuesta = null");
    } else {
      resultado.append("var respuesta = new Array(");
      if (!strQuantityOrder.equals("")) {
        quantityOrder = new BigDecimal(strQuantityOrder);
        movementQty = quantityOrder.multiply(multiplyRate);
        if (movementQty.scale() > stdPrecision)
          movementQty = movementQty.setScale(stdPrecision, RoundingMode.HALF_UP);
        resultado.append("new Array(\"inpmovementqty\", " + movementQty.toString() + ")");
      }
      if (!strQuantity.equals("")) {
        quantity = new BigDecimal(strQuantity);
        movementQty = quantity.multiply(divideRate);
        if (movementQty.scale() > stdPrecision)
          movementQty = movementQty.setScale(stdPrecision, RoundingMode.HALF_UP);
        resultado.append("new Array(\"inpquantityorder\", " + movementQty.toString() + ")");
      }
//      if (!strMProductUOMID.equals("")) {
//        if (!strQuantityOrder.equals("") && strMultiplyRate.equals("1"))
//          resultado.append(",");
//        resultado.append("new Array('MESSAGE', \""
//            + FormatUtilities.replaceJS(Utility.messageBD(this, "NoUOMConversion", vars
//                .getLanguage())) + "\")");
//      }
      resultado.append(");");
    }
    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }
}
