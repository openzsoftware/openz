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

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.PAttributeSet;
import org.openbravo.erpCommon.businessUtility.PAttributeSetData;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.controller.callouts.CalloutStructure;
import org.openz.view.SelectBoxhelper;


public class SL_Invoice_Product extends ProductTextHelper {
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
      String strUOM = vars.getStringParameter("inpmProductId_UOM");
      String strPriceList = vars.getStringParameter("inpmProductId_PLIST");
      String strPriceStd = vars.getStringParameter("inpmProductId_PSTD");
      String strPriceLimit = vars.getStringParameter("inpmProductId_PLIM");
      String strCurrency = vars.getStringParameter("inpmProductId_CURR");
      String strQty = vars.getNumericParameter("inpqtyinvoiced");
      String strPriceListVersionID = vars.getStringParameter("inpmProductId_PLIV");

      String strMProductID = vars.getStringParameter("inpmProductId");
      String strADOrgID = vars.getStringParameter("inpadOrgId");
      String strCInvoiceID = vars.getStringParameter("inpcInvoiceId");
      String strWindowId = vars.getStringParameter("inpwindowId");
      String strIsSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
      String strWharehouse = Utility.getContext(this, vars, "#M_Warehouse_ID", strWindowId);
      String strTabId = vars.getStringParameter("inpTabId");
      String strLang = vars.getLanguage();
      String strCBpartnerID = vars.getStringParameter("inpcBpartnerId");

      try {
        printPage(response, vars, strUOM, strPriceList, strPriceStd, strPriceLimit, strCurrency,
            strMProductID, strADOrgID, strCInvoiceID, strIsSOTrx, strWharehouse, strTabId, strQty, strLang,strCBpartnerID,strPriceListVersionID);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strUOM,
      String strPriceList, String strPriceStd, String strPriceLimit, String strCurrency,
      String strMProductID, String strADOrgID, String strCInvoiceID, String strIsSOTrx,
      String strWharehouse, String strTabId, String strQty, String strLang, String strCBpartnerID, String strPriceListVersionID) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();

    String strPriceActual = "";
    String strPositionText = "";
    
    if (!strMProductID.equals("")) {
      SLOrderProductData[] dataInvoice = SLOrderProductData.selectInvoice(this, strCInvoiceID);

      if (log4j.isDebugEnabled())
        log4j.debug("get Offers date: " + dataInvoice[0].dateinvoiced + " partner:"
            + dataInvoice[0].cBpartnerId + " prod:" + strMProductID + " std:"
            + strPriceStd.replace("\"", ""));
   // SZ Purchase-Price from m_product_po
      if (strIsSOTrx.equals("N")){
        strPriceStd=SLOrderAmtData.getPricestdAmt(this, strMProductID,  (strPriceListVersionID.isEmpty() ? dataInvoice[0].mPricelistId : strPriceListVersionID),
            null,null,strCBpartnerID);
        //strPriceStd=SLOrderProductData.getPurchasePricePo(this, strMProductID, strCBpartnerID, strCurrency);
      }
      strPriceActual = SLOrderProductData.getOffersPriceInvoice(this, dataInvoice[0].dateinvoiced,
          dataInvoice[0].cBpartnerId, strMProductID, strQty,
          (strPriceListVersionID.isEmpty() ? dataInvoice[0].mPricelistId : strPriceListVersionID), null,null,dataInvoice[0].adOrgId,dataInvoice[0].id);
      if (log4j.isDebugEnabled())
        log4j.debug("get Offers price:" + strPriceActual);
      // SZ added Position Text
      strPositionText = this.getDocumentText(strMProductID, strCBpartnerID, strIsSOTrx, strADOrgID,strLang);
      dataInvoice = null;
    }
    // New Callout Structure
    CalloutStructure callout= new CalloutStructure(this,"SL_Invoice_Product");
    //callout.appendString("inpcUomId", strUOM);
    try {
      if (!strUOM.isEmpty()) {
        FieldProvider[] fp = SelectBoxhelper.getReferenceDataByRefName(this, vars, "c_uom_id", null,null, strUOM, true);
        callout.appendComboTable("inpcUomId", fp, strUOM);
      }
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    callout.appendNumeric("inppricelist", strPriceList);
    callout.appendNumeric("inppricelimit",strPriceLimit);
    callout.appendString("inpdescription", strPositionText);
    callout.appendNumeric("inppricestd",strPriceStd);
    callout.appendNumeric("inppriceactual",strPriceActual);

    if (strPriceActual.equals(""))
      strPriceActual = strPriceStd;
    
    PAttributeSetData[] dataPAttr = PAttributeSetData.selectProductAttr(this, strMProductID);
    if (dataPAttr != null && dataPAttr.length > 0) {
      PAttributeSetData[] data2 = PAttributeSetData.select(this, dataPAttr[0].mAttributesetId);
      if (PAttributeSet.isInstanceAttributeSet(data2)) {
        callout.appendString("inpmAttributesetinstanceId","");
        callout.appendString("inpmAttributesetinstanceId_R","");
       
      } else {
        callout.appendString("inpmAttributesetinstanceId",dataPAttr[0].mAttributesetinstanceId);
        callout.appendString("inpmAttributesetinstanceId_R",dataPAttr[0].description);
      }
    }
    String strHasSecondaryUOM = SLOrderProductData.hasSecondaryUOM(this, strMProductID);
    callout.appendString("strHASSECONDUOM",strHasSecondaryUOM);
    callout.appendString("inpcCurrencyId",strCurrency);
    
    //SZ:  Tax is now yet related to Products by the following rules:
    //Get TAX from Product, BP-Location, Product, Product-Category or default (Organization)
    String strCTaxID ="";
    strCTaxID = SLInvoiceTaxData.selectTax(this,strCInvoiceID,strMProductID);
    if (!strCTaxID.equals(""))
      callout.appendString("inpcTaxId",strCTaxID);
    else
      if (!strMProductID.equals("")) 
    	  callout.appendMessage("NoLocationNoTaxCalculated", this, vars);
    FieldProvider[] tld = null;
    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLE", "", "M_Product_UOM",
          "", Utility.getContext(this, vars, "#AccessibleOrgTree", "SLOrderProduct"), Utility
              .getContext(this, vars, "#User_Client", "SLOrderProduct"), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, "SLOrderProduct", "");
      tld = comboTableData.select(false);
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
    callout.appendComboTable("inpmProductUomId", tld,"first");
   

    
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(callout.returnCalloutAppFrame());
    out.close();
  }
}
