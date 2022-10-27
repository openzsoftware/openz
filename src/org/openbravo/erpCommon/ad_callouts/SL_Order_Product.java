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
import java.math.*;

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
import org.openz.view.SelectBoxhelper;


public class SL_Order_Product extends ProductTextHelper {
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
      String strUOM = vars.getStringParameter("inpmProductId_UOM");
      String strPriceList = vars.getNumericParameter("inpmProductId_PLIST");
      String strPriceStd = vars.getNumericParameter("inpmProductId_PSTD");
      String strPriceLimit = vars.getNumericParameter("inpmProductId_PLIM");
      String strCurrency = vars.getStringParameter("inpmProductId_CURR");
      String strQty = vars.getNumericParameter("inpqtyordered");
      String strPriceListVersionID = vars.getStringParameter("inpmProductId_PLIV");

      String strCBpartnerID = vars.getStringParameter("inpcBpartnerId");
      String strMProductID = vars.getStringParameter("inpmProductId");
      String strCBPartnerLocationID = vars.getStringParameter("inpcBpartnerLocationId");
      String strDateOrdered = vars.getStringParameter("inpdateordered");
      String strADOrgID = vars.getStringParameter("inpadOrgId");
      String strMWarehouseID = vars.getStringParameter("inpmWarehouseId");
      String strMProductPOID = vars.getStringParameter("inpmProductPoId");
      String str2ndUom = vars.getStringParameter("inpmProductUomId");
      String str2ndUomQty = vars.getNumericParameter("inpquantityorder");
      String strCOrderId = vars.getStringParameter("inpcOrderId");
      if (strCOrderId.equals(""))
        strCOrderId = vars.getStringParameter("inpcSubscriptionintervalViewId");
      String strWindowId = vars.getStringParameter("inpwindowId");
      String strIsSOTrx = Utility.getContext(this, vars, "isSOTrx", strWindowId);
      String strTabId = vars.getStringParameter("inpTabId");
      String cancelPriceAd = vars.getStringParameter("inpcancelpricead");
      String strLang = vars.getLanguage();
      
      vars.removeSessionValue("MESSAGE_PROD");
      vars.removeSessionValue("MESSAGE_PROD_TEXT");
      vars.removeSessionValue("MESSAGE_AMT");
      vars.removeSessionValue("MESSAGE_AMT_TEXT");
      
      try {
        printPage(response, vars, strChanged, 
            strUOM, strPriceList, strPriceStd, strPriceLimit, strCurrency,
            strMProductID, strCBPartnerLocationID, strDateOrdered, strADOrgID, strMWarehouseID,
            strCOrderId, strWindowId, strIsSOTrx, strCBpartnerID, strTabId, strQty, cancelPriceAd, strLang,
            strPriceListVersionID,strMProductPOID,str2ndUom,str2ndUomQty);
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strChanged, 
      String strUOM,
      String strPriceList, String strPriceStd, String strPriceLimit, String strCurrency,
      String strMProductID, String strCBPartnerLocationID, String strDateOrdered,
      String strADOrgID, String strMWarehouseID, String strCOrderId, String strWindowId,
      String strIsSOTrx, String strCBpartnerID, String strTabId, String strQty, String cancelPriceAd, String strLang, 
      String strPriceListVersionID,String strMProductPOID,String str2ndUom,String str2ndUomQty)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();

    String messageBuffer = "";
    String strPriceActual = "";
    String strPositionText = "";
    String actualqty;
    if (str2ndUom!= null && !str2ndUom.isEmpty())
      actualqty=str2ndUomQty;
    else
      actualqty=strQty;
    BigDecimal qtyOrdered = (actualqty.equals("") ? ZERO : new BigDecimal(actualqty));    
    SLOrderAmtData[] data = SLOrderAmtData.select(this, strCOrderId);
    String strPrecision = "0", strPricePrecision = "0";
    if (data != null && data.length > 0) {
      strPrecision = data[0].stdprecision.equals("") ? "0" : data[0].stdprecision;
      strPricePrecision = data[0].priceprecision.equals("") ? "0" : data[0].priceprecision;
    }
    int StdPrecision = Integer.valueOf(strPrecision).intValue();
    int PricePrecision = Integer.valueOf(strPricePrecision).intValue();
    StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='SL_Order_Product';\n\n");
    resultado.append("var respuesta = new Array(");
    
    if (!strMProductID.equals("")) {
      SLOrderProductData[] dataOrder = SLOrderProductData.select(this, strCOrderId);

      // MH Purchase-Settings (m_product_po)
      // Standard- bzw. Mindest-Bestellmenge aus Einkauf (m_product_po) beruecksichtigen, wenn hinterlegt         
      if (strChanged.equals("inpmProductId")) { // ("inpqtyordered")) {
        BigDecimal qtyPurchase = new BigDecimal(SLOrderAmtData.mrp_getpo_qty(this, strMProductID, dataOrder[0].cBpartnerId, actualqty,str2ndUom,strMProductPOID));
        vars.setSessionValue("QTYPURCHASE_PROD", qtyPurchase.toString());
        if (!actualqty.equals(qtyPurchase.toString())) {

          BigDecimal qtyPurchaseStd = new BigDecimal(SLOrderAmtData.mrp_getpo_qtystd(this, strMProductID, dataOrder[0].cBpartnerId,str2ndUom,strMProductPOID));
          vars.setSessionValue("QTYPURCHASESTD_PROD", qtyPurchaseStd.toString());
          BigDecimal qtyPurchaseMin = new BigDecimal(SLOrderAmtData.mrp_getpo_qtymin(this, strMProductID, dataOrder[0].cBpartnerId,str2ndUom,strMProductPOID));
          vars.setSessionValue("QTYPURCHASEMIN_PROD", qtyPurchaseMin.toString());
          String qtyPurchaseIsMultiple = new String(SLOrderAmtData.mrp_getpo_ismultipleofminimumqty(this, strMProductID, dataOrder[0].cBpartnerId,str2ndUom,strMProductPOID));
          vars.setSessionValue("QTYPURCHASEISMULTIPLE_PROD", qtyPurchaseIsMultiple);
          
          messageBuffer = "ZSMP_PurchaseDefault_PLACEHOLDER,";
        }
      } 
      
      // perform link (used as button)
      if (strChanged.equals("QtyOrdered")) {
        BigDecimal qtyPurchase = new BigDecimal(SLOrderAmtData.mrp_getpo_qty(this, strMProductID, dataOrder[0].cBpartnerId, actualqty,str2ndUom,strMProductPOID));
        vars.setSessionValue("QTYPURCHASE_PROD", qtyPurchase.toString());
        messageBuffer = messageBuffer + "ZSMP_PurchaseDefault_Excec_PLACEHOLDER,";
        
        int stdPrecision = strPrecision.equals("") ? 0 : Integer.valueOf(strPrecision).intValue();
        String strInitUOM = SLInvoiceConversionData.initUOMId(this, str2ndUom);
        String strMultiplyRate;

        strMultiplyRate = SLInvoiceConversionData.divideRate(this, strInitUOM, strUOM);
        if (strInitUOM.equals(strUOM))
          strMultiplyRate = "1";
        if (strMultiplyRate.equals(""))
          strMultiplyRate = SLInvoiceConversionData.multiplyRate(this, strUOM, strInitUOM);
        if (strMultiplyRate.equals("") || strMultiplyRate == null ) {
          strMultiplyRate = "1";
        }
        BigDecimal multiplyRate = new BigDecimal(strMultiplyRate);
        actualqty=qtyPurchase.toString();
        if (!str2ndUom.equals("")) {
          BigDecimal a = qtyPurchase.divide(multiplyRate).setScale(stdPrecision, RoundingMode.HALF_UP);
          resultado.append("new Array(\"inpquantityorder\", " + qtyPurchase.toString() + "),");
          qtyOrdered = a;
        } else
          qtyOrdered = qtyPurchase;
        resultado.append("new Array(\"inpqtyordered\", " + qtyOrdered.toString() + "),"); // [statement required, aendert Eintrag in GUI-Komponente]
        
      }
      
      
     strPriceActual = SLOrderProductData.getOffersPrice(this,dataOrder[0].dateordered,
            dataOrder[0].cBpartnerId, strMProductID,actualqty, dataOrder[0].mPricelistId,str2ndUom,strMProductPOID,null, dataOrder[0].adOrgId,dataOrder[0].id);
      
      // SZ added Position Text
      strPositionText = this.getDocumentText(strMProductID, strCBpartnerID, strIsSOTrx, strADOrgID,strLang,str2ndUom,strMProductPOID);
      dataOrder = null;
    } else {
      strUOM = strPriceList = strPriceLimit = strPriceStd = "";
    }
    
    if (strPriceActual.equals("") || "Y".equals(cancelPriceAd))
      strPriceActual = strPriceStd;
    
    
    
    BigDecimal priceActual = BigDecimal.ZERO;
    priceActual = (strPriceActual.equals("") ? BigDecimal.ZERO : (new BigDecimal(strPriceActual))).setScale(PricePrecision, RoundingMode.HALF_UP);

    
    // Discount...
    if (strPriceList.startsWith("\""))
      strPriceList = strPriceList.substring(1, strPriceList.length() - 1);
    if (strPriceStd.startsWith("\""))
      strPriceStd = strPriceStd.substring(1, strPriceStd.length() - 1);

    BigDecimal priceList = (strPriceList.equals("") ? new BigDecimal(0.0) : new BigDecimal(
        strPriceList));
    if (priceList.scale() > PricePrecision)
    	priceList = priceList.setScale(PricePrecision, RoundingMode.HALF_UP);

    BigDecimal priceStd = (strPriceStd.equals("") ? new BigDecimal(0.0) : new BigDecimal(
        strPriceStd));
    if (priceStd.scale() > PricePrecision)
    	priceStd = priceStd.setScale(PricePrecision, RoundingMode.HALF_UP);

    BigDecimal discount = new BigDecimal(0.0);
    if (priceActual.compareTo(BigDecimal.ZERO) != 0 && priceStd.compareTo(BigDecimal.ZERO) != 0)
    	discount = ((priceStd.subtract(priceActual)).divide(priceStd, 12, RoundingMode.HALF_EVEN)).multiply(new BigDecimal("100"));
    if (discount.scale() > StdPrecision)
        discount = discount.setScale(StdPrecision, RoundingMode.HALF_UP);
    
    //resultado.append("new Array(\"inpcUomId\", \"" + strUOM + "\"),");
    if (!strUOM.isEmpty()) {
      resultado.append("new Array(\"inpcUomId\", ");
      try {
        FieldProvider[] fp = SelectBoxhelper.getReferenceDataByRefName(this, vars, "c_uom_id", null,null, strUOM, true);
        if (fp != null && fp.length > 0) {
          resultado.append("new Array(");
          for (int i = 0; i < fp.length; i++) {
            resultado.append("new Array(\"" + fp[i].getField("id") + "\", \""
                + FormatUtilities.replaceJS(fp[i].getField("name")) + "\", \""
                + (i == 0 ? "true" : "false") + "\")");
            if (i < fp.length - 1)
              resultado.append(",\n");
          }
          resultado.append("\n)");
        } else {
          resultado.append("null");
        }
        resultado.append("\n),");
      }
      catch (Exception ex) {
        throw new ServletException(ex);
      }
    }
    resultado.append("new Array(\"inppricelist\", " + (strPriceList.equals("") ? "\"0\"" : strPriceList) + "),");
    resultado.append("new Array(\"inppricelimit\", " + (strPriceLimit.equals("") ? "\"0\"" : strPriceLimit) + "),");
    resultado.append("new Array(\"inppricestd\", " + (strPriceStd.equals("") ? "\"0\"" : strPriceStd) + "),");
    resultado.append("new Array(\"inppriceactual\", " + (strPriceActual.equals("") ? "\"0\"" : strPriceActual) + "),");
    resultado.append("new Array(\"inpcCurrencyId\", " + (strCurrency.equals("") ? "\"\"" : strCurrency) + "),");
    resultado.append("new Array(\"inpdescription\", " + (strPositionText.equals("") ? "\"" : "\"" + strPositionText) + "\"),");
    resultado.append("new Array(\"inpdiscount\", " + discount.toString() + "),");
    
    //if (strUOM.startsWith("\"")) strUOM=strUOM.substring(1,strUOM.length()-1);
    //String strProductUomId = SLOrderProductData.mProductUomId(this, strMProductID, strCBpartnerID);
    //resultado.append("new Array(\"inpProductUomId\", \"" + strProductUomId + "\"),");
    
    if (!strMProductID.equals("")) {
      PAttributeSetData[] dataPAttr = PAttributeSetData.selectProductAttr(this, strMProductID);
      if (dataPAttr != null && dataPAttr.length > 0) {
        PAttributeSetData[] data2 = PAttributeSetData.select(this, dataPAttr[0].mAttributesetId);
        if (PAttributeSet.isInstanceAttributeSet(data2)) {
          resultado.append("new Array(\"inpmAttributesetinstanceId\", \"\"),");
          resultado.append("new Array(\"inpmAttributesetinstanceId_R\", \"\"),");
        } else {
          resultado.append("new Array(\"inpmAttributesetinstanceId\", \""
              + dataPAttr[0].mAttributesetinstanceId + "\"),");
          resultado.append("new Array(\"inpmAttributesetinstanceId_R\", \""
              + FormatUtilities.replaceJS(dataPAttr[0].description) + "\"),");
        }
      }
    }
    String strIssummaryItem=SLOrderProductData.isSummaryitem(this, strMProductID);
    resultado.append("new Array(\"inpissummaryitem\", " +   "\"" + strIssummaryItem + "\"),");
    /*
    String strDeliveryDate = SLOrderProductData.getSheddeliveryDate4vendorProduct(this, strCBpartnerID, strMProductID);
    if (!strDeliveryDate.isEmpty())
      resultado.append("new Array(\"inpscheddeliverydate\", " +   "\"" + strDeliveryDate + "\"),");
    */
    String strHasSecondaryUOM = SLOrderProductData.hasSecondaryUOM(this, strMProductID);
    resultado.append("new Array(\"strHASSECONDUOM\", " + strHasSecondaryUOM + "),\n");
   
    
    String strCTaxID = "";
    
//    String orgLocationID = SLOrderProductData.getOrgLocationId(this, Utility.getContext(this, vars,
//        "#User_Client", "SLOrderProduct"), "'" + strADOrgID + "'");
//    if (orgLocationID.equals("")) {
//      resultado.append("new Array('MESSAGE', \""
//          + FormatUtilities.replaceJS(Utility.messageBD(this, "NoLocationNoTaxCalculated", vars
//              .getLanguage())) + "\"),\n");
//    } else {
//      SLOrderTaxData[] data = SLOrderTaxData.select(this, strCOrderId);
//      strCTaxID = Tax.get(this, strMProductID, data[0].dateordered, strADOrgID, strMWarehouseID,
//          (data[0].billtoId.equals("") ? strCBPartnerLocationID : data[0].billtoId),
//          strCBPartnerLocationID, data[0].cProjectId, strIsSOTrx.equals("Y"));
//    }
    
    // SZ Get TAX from Product
    strCTaxID = SLOrderTaxData.selectTax(this,strCOrderId,strMProductID);
    if (!strCTaxID.equals(""))
      resultado.append("new Array(\"inpcTaxId\", \"" + strCTaxID + "\"),\n");
    else
      if (!strMProductID.equals("")) { 
	      messageBuffer = messageBuffer + "NoLocationNoTaxCalculated_PLACEHOLDER,";
      }
    FieldProvider[] tld = null;
    if (strIsSOTrx.equals("N")) {
      try {
        // Manufacturer
        resultado.append("new Array(\"inpmProductPoId\", ");
        // ManufacurerInPurchase Validation
        String defaultmanu=SLOrderProductData.selectDefaultManufacturerPO(this, strMProductID, strCBpartnerID, strADOrgID);
        tld =SelectBoxhelper.getReferenceDataByRefName(this, vars, "m_manufacturerInPO", null, null,null , false);  
        if (tld != null && tld.length > 0) {
          resultado.append("new Array(");
          for (int i = 0; i < tld.length; i++) {
            resultado.append("new Array(\"" + tld[i].getField("id") + "\", \""
                + FormatUtilities.replaceJS(tld[i].getField("name")) + "\", \""
                + (tld[i].getField("id").equals(defaultmanu) ? "true" : "false") + "\")");
            if (i < tld.length - 1)
              resultado.append(",\n");
          }
          resultado.append("\n)");
        } else
          resultado.append("null");
        resultado.append("\n),");
      } catch (Exception ex) {
        throw new ServletException(ex);
      }
    }
    
    String frameContractDescription = SLOrderProductData.getFrameContractDescription(this, strCBpartnerID, strMProductID, strUOM);
    if(!frameContractDescription.isEmpty()) {
        vars.setSessionValue("FRAMECONTRACTDESCRIPTION_PROD", frameContractDescription);
        messageBuffer = messageBuffer + "ZSMP_FrameContractExists_PLACEHOLDER,";
    }
    
    
    
    resultado.append("new Array(\"inpmProductUomId\", ");
    // if (strUOM.startsWith("\""))
    // strUOM=strUOM.substring(1,strUOM.length()-1);
    // String strmProductUOMId =
    // SLOrderProductData.strMProductUOMID(this,strMProductID,strUOM);
    
      
      try {
        ComboTableData comboTableData = new ComboTableData(vars, this, "TABLE", "",
            "M_Product_UOM", "", Utility.getContext(this, vars, "#AccessibleOrgTree",
                "SLOrderProduct"),
            Utility.getContext(this, vars, "#User_Client", "SLOrderProduct"), 0);
        Utility.fillSQLParameters(this, vars, null, comboTableData, "SLOrderProduct", "");
        tld = comboTableData.select(false);
        comboTableData = null;
      } catch (Exception ex) {
        throw new ServletException(ex);
      }

      if (tld != null && tld.length > 0) {
        String defaultuom=SLOrderProductData.selectDefault2NdUOM(this, strMProductID, strCBpartnerID, strADOrgID);
        resultado.append("new Array(");
        for (int i = 0; i < tld.length; i++) {
          resultado.append("new Array(\"" + tld[i].getField("id") + "\", \""
              + FormatUtilities.replaceJS(tld[i].getField("name")) + "\", \""
              + (tld[i].getField("id").equals(defaultuom) ? "true" : "false") + "\")");
          if (i < tld.length - 1)
            resultado.append(",\n");
        }
        resultado.append("\n)");
      } else
        resultado.append("null");
      resultado.append("\n),");

    if(vars.getSessionValue("MESSAGE_PROD", "").isEmpty()) {
        vars.setSessionValue("MESSAGE_PROD", messageBuffer);
    } else if (messageBuffer.isEmpty()){
        messageBuffer = vars.getSessionValue("MESSAGE_PROD", "");
    } else {
        String[] sBL = vars.getSessionValue("MESSAGE_PROD", "").split(",");
        String newMessageBuffer = messageBuffer;
        
        for(String s : sBL) {
            if(!newMessageBuffer.contains(s)) {
                newMessageBuffer = newMessageBuffer + s + ",";
            }
        }
        
        messageBuffer = newMessageBuffer;
        vars.setSessionValue("MESSAGE_PROD", messageBuffer);
    }
    
    messageBuffer = messageBuffer
            .replace(",", "")
            .replace("ZSMP_PurchaseDefault_PLACEHOLDER", FormatUtilities.replaceJS
                        (
                          Utility.messageBD(this, "ZSMP_PurchaseDefault",        vars.getLanguage()) + ":" +  "</br></br>" + 
                          Utility.messageBD(this, "ZSMP_PurchaseDefault_QtyStd", vars.getLanguage()) + " = " + vars.getSessionValue("QTYPURCHASESTD_PROD", "") + "</br>" + 
                          Utility.messageBD(this, "ZSMP_PurchaseDefault_QtyMin", vars.getLanguage()) + " = " + vars.getSessionValue("QTYPURCHASEMIN_PROD", "") + "</br>" +
                          Utility.messageBD(this, "ZSMP_PurchaseDefault_IsMult", vars.getLanguage()) + " = " + vars.getSessionValue("QTYPURCHASEISMULTIPLE_PROD", "") + "</br></br>" +
                          Utility.messageBD(this, "ZSMP_PurchaseDefault_Qty",    vars.getLanguage()) + " = " + vars.getSessionValue("QTYPURCHASE_PROD", "") + "  "  + // "</br>" +
                          "<input type=\"button\" value=\""
                          + Utility.messageBD(this, "ZSMP_ButtonReset",        vars.getLanguage())
                          + "\" href=\"#\"  style=\"cursor:pointer;\" onclick=\"submitCommandFormParameter('DEFAULT', frmMain.inpLastFieldChanged, 'QtyOrdered', false, null, '../ad_callouts/SL_Order_Amt.html', 'hiddenFrame', null, null, true); return false;\" class=\"LabelLink\">"
                        ) + "<br>")
            .replace("ZSMP_PurchaseDefault_Excec_PLACEHOLDER", FormatUtilities.replaceJS(Utility.messageBD(this, "ZSMP_PurchaseDefault_Excec", vars.getLanguage())) + "<br>")
            .replace("NoLocationNoTaxCalculated_PLACEHOLDER", FormatUtilities.replaceJS(Utility.messageBD(this, "NoLocationNoTaxCalculated", vars.getLanguage())) + "<br>")
            .replace("ZSMP_FrameContractExists_PLACEHOLDER", FormatUtilities.replaceJS(Utility.messageBD(this, "ZSMP_FrameContractExists", vars.getLanguage())) + " " + vars.getSessionValue("FRAMECONTRACTDESCRIPTION_PROD", "") + "<br>");

    vars.setSessionValue("MESSAGE_PROD_TEXT", messageBuffer);
    resultado.append("new Array('MESSAGE', \"" + "\"),"); // reset Message, reset MessageBox
    resultado.append("new Array('MESSAGE', \"" + messageBuffer + "\"),");
    
    resultado.append("new Array(\"EXECUTE\", \"displayLogic();\")\n");
    // Commented to keep knowledge
    //resultado.append("new Array(\"TINYDESCRIPTION\", \"tinyMCE.get('description').setContent('"+strPositionText+"');\")\n");
    //  resultado.append("new Array(\"TINYDESCRIPTION\", \" +strPositionText +"\"");
   // resultado.append("new Array(\"TINYDESCRIPTION\",\"" + strPositionText + "\")");
      
    // Para posicionar el cursor en el campo de cantidad
    //resultado.append("new Array(\"CURSOR_FIELD\", \"inpqtyordered\")\n");
    //if (!strHasSecondaryUOM.equals("0"))
    //  resultado.append(", new Array(\"CURSOR_FIELD\", \"inpquantityorder\")\n");

    resultado.append(");");
    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }
}
