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
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.controller.callouts.CalloutStructure;

public class SL_Order_Amt  extends ProductTextHelper  {
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
      String strQtyOrdered = vars.getNumericParameter("inpqtyordered");
      String strPriceActual = vars.getNumericParameter("inppriceactual");
      String strDiscount = vars.getNumericParameter("inpdiscount");
      String strPriceLimit = vars.getNumericParameter("inppricelimit");
      String strPriceList = vars.getNumericParameter("inppricelist");
      String strPriceStd = vars.getNumericParameter("inppricestd");
      String strCOrderId = vars.getStringParameter("inpcOrderId");
      String strProduct = vars.getStringParameter("inpmProductId");
      String strUOM = vars.getStringParameter("inpcUomId");
      String strOrderProductUOM = vars.getStringParameter("inpmProductUomId");
      String strOrderUOM= SLOrderProductData.getUOMProduct(myPool, strOrderProductUOM);
      String strOrderQTY = vars.getNumericParameter("inpquantityorder");
      String strMProductPOID = vars.getStringParameter("inpmProductPoId");
      String strAttribute = vars.getStringParameter("inpmAttributesetinstanceId");
      String strTabId = vars.getStringParameter("inpTabId");
      String strWindowId = vars.getStringParameter("inpwindowId");
      // SZ added order-UOM and Pricelimit
      String strQty = vars.getNumericParameter("inpqtyordered");
      String cancelPriceAd = vars.getStringParameter("inpcancelpricead");
      String strMPricelistId = vars.getSessionValue(strWindowId + "|m_Pricelist_Id");
      String strOptional = vars.getStringParameter("isoptional");
      

      try {
        
        if (! strProduct.isEmpty() && (strOptional.equals("N")||strOptional.isEmpty())) {
          printPage(response, vars, strChanged, strQtyOrdered, strPriceActual, strDiscount,
            strPriceLimit, strPriceList, strCOrderId, strProduct, strUOM, strAttribute, strTabId,
            strQty, strPriceStd, cancelPriceAd, strOrderUOM, strOrderQTY, strMPricelistId,strMProductPOID);
        } else {
          CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
          
          response.setContentType("text/html; charset=UTF-8");
          PrintWriter out = response.getWriter();
          out.println(callout.returnCalloutAppFrame());
          out.close();
        }
      } catch (ServletException ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strChanged,
      String strQtyOrdered, String strPriceActual, String strDiscount, String strPriceLimit,
      String strPriceList, String strCOrderId, String strProduct, String strUOM,
      String strAttribute, String strTabId, String strQty, String strPriceStd, String cancelPriceAd,
      String strOrderUOM, String strOrderQTY,String strMPricelistId,String strMProductPOID)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled()) {
      log4j.debug("Output: dataSheet");
      log4j.debug("CHANGED:" + strChanged);
    }
    Boolean priomes=false;
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();
    SLOrderAmtData[] data = SLOrderAmtData.select(this, strCOrderId);
    SLOrderStockData[] data1 = SLOrderStockData.select(this, strProduct);
    String strPrecision = "0", strPricePrecision = "0";
    String strStockSecurity = "0";
    String strEnforceAttribute = "N";
    String Issotrx = SLOrderStockData.isSotrx(this, strCOrderId);
    String strStockNoAttribute;
    String strStockAttribute;
    if (data1 != null && data1.length > 0) {
      strStockSecurity = data1[0].stock;
      strEnforceAttribute = data1[0].enforceAttribute;
    }
    // boolean isUnderLimit=false;
    if (data != null && data.length > 0) {
      strPrecision = data[0].stdprecision.equals("") ? "0" : data[0].stdprecision;
      strPricePrecision = data[0].priceprecision.equals("") ? "0" : data[0].priceprecision;
    }
    int StdPrecision = Integer.valueOf(strPrecision).intValue();
    int PricePrecision = Integer.valueOf(strPricePrecision).intValue();

    BigDecimal qtyOrdered, priceActual, discount, priceLimit, priceList, stockSecurity, stockNoAttribute, stockAttribute, resultStock, priceStd, OrderQTY;
    
    stockSecurity = new BigDecimal(strStockSecurity);
    qtyOrdered = (strQtyOrdered.equals("") ? ZERO : new BigDecimal(strQtyOrdered));
    priceActual = (strPriceActual.equals("") ? ZERO : (new BigDecimal(strPriceActual))).setScale(
        PricePrecision, RoundingMode.HALF_UP);
    discount = (strDiscount.equals("") ? ZERO : new BigDecimal(strDiscount));
    priceLimit = (strPriceLimit.equals("") ? ZERO : (new BigDecimal(strPriceLimit))).setScale(
        PricePrecision, RoundingMode.HALF_UP);
    priceList = (strPriceList.equals("") ? ZERO : (new BigDecimal(strPriceList))).setScale(
        PricePrecision, RoundingMode.HALF_UP);
    priceStd = (strPriceStd.equals("") ? ZERO : (new BigDecimal(strPriceStd))).setScale(
        PricePrecision, RoundingMode.HALF_UP);
    OrderQTY = ((strOrderUOM.equals("") | strOrderQTY.equals("")) ? ZERO :   new BigDecimal(strOrderQTY));
    /*
     * if (enforcedLimit) { String strPriceVersion = ""; PriceListVersionComboData[] data1 =
     * PriceListVersionComboData.selectActual(this, data[0].mPricelistId, DateTimeData.today(this));
     * if (data1!=null && data1.length>0) strPriceVersion = data1[0].mPricelistVersionId; BigDecimal
     * lineLimit = new BigDecimal(SLOrderAmtData.selectPriceLimit(this, strPriceVersion,
     * strProduct)); if (lineLimit.floatValue() >priceActual.floatValue()) isUnderLimit=true; }
     */
    // SZ : If we order in Secondary OUM, Price applies to OrderQTY not to qtyOrdered
    //if (OrderQTY.compareTo(ZERO)!=0) qtyOrdered = OrderQTY;
    //
    StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='SL_Order_Amt';\n\n");
    resultado.append("var respuesta = new Array(");


    SLOrderProductData[] dataOrder = SLOrderProductData.select(this, strCOrderId);
   
    // FW: Use discount?
	if (strChanged.equals("inpcancelpricead")) {
		if ("Y".equals(cancelPriceAd)) {
			/* FW: Calculate with Amounts on Screen (not used because of small rounding differences may occur)
			priceActual = (priceActual.divide((new BigDecimal("1")).subtract(discount.divide(new BigDecimal("100"))), 12, RoundingMode.HALF_EVEN));
			if (priceActual.scale() > PricePrecision)
				priceActual = priceActual.setScale(PricePrecision, RoundingMode.HALF_UP);
			resultado.append("new Array(\"inppriceactual\", " + priceActual.toString() + "),");*/
			// FW: Just use standard price
			resultado.append("new Array(\"inppriceactual\", " + priceStd.toString() + "),");
		} else {
			// FW: Calculate price actual again (standard price on screen * discount on screen)
			priceActual = (priceStd.multiply((new BigDecimal("1")).subtract(discount.divide(new BigDecimal("100")))));
			if (priceActual.scale() > PricePrecision)
				priceActual = priceActual.setScale(PricePrecision, RoundingMode.HALF_UP);
			resultado.append("new Array(\"inppriceactual\", " + priceActual.toString() + "),"); 
		}
	}

    

    // perform link (used as button from Product CXallout)
    if (strChanged.equals("QtyOrdered")) {
      BigDecimal qtyPurchase = new BigDecimal(SLOrderAmtData.mrp_getpo_qty(this, strProduct, dataOrder[0].cBpartnerId, OrderQTY.compareTo(BigDecimal.ZERO)==0?qtyOrdered.toString():OrderQTY.toString(),strOrderUOM,strMProductPOID));
      
      resultado.append("new Array('MESSAGE', \"" + "\"),"); // reset Message, reset MessageBox
      resultado.append("new Array('MESSAGE', \"" + FormatUtilities.replaceJS(Utility.messageBD(this, "ZSMP_PurchaseDefault_Excec", vars.getLanguage()) ) + "\"),");
      
      int stdPrecision = strPrecision.equals("") ? 0 : Integer.valueOf(strPrecision).intValue();
      String strInitUOM = SLInvoiceConversionData.initUOMId(this, strOrderUOM);
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
      if (!strOrderUOM.equals("")) {
        BigDecimal a = qtyPurchase.divide(multiplyRate).setScale(stdPrecision, RoundingMode.HALF_UP);
        resultado.append("new Array(\"inpquantityorder\", " + qtyPurchase.toString() + "),");
        qtyOrdered = a;
      } else
        qtyOrdered = qtyPurchase;
      resultado.append("new Array(\"inpqtyordered\", " + qtyOrdered.toString() + "),"); // [statement required, aendert Eintrag in GUI-Komponente]
      priceActual = new BigDecimal(SLOrderProductData.getOffersPrice(this,dataOrder[0].dateordered,
          dataOrder[0].cBpartnerId,strProduct,OrderQTY.compareTo(BigDecimal.ZERO)==0?qtyOrdered.toString():OrderQTY.toString(), dataOrder[0].mPricelistId,strOrderUOM,strMProductPOID,strAttribute,dataOrder[0].adOrgId, dataOrder[0].id)).setScale(PricePrecision, RoundingMode.HALF_UP);
      resultado.append("new Array(\"inppriceactual\", " + priceActual.toString()  + "),");
      
    }
    
    // calculating discount
    if (strChanged.equals("inppriceactual")) {
      if ("Y".equals(cancelPriceAd)) {
        priceActual=priceStd;
        resultado.append("new Array(\"inppriceactual\", " + priceActual.toString() + "),");
      }
      else {
        try {
        if (log4j.isDebugEnabled())
          log4j.debug("pricelist:" + Double.toString(priceList.doubleValue()));
        if (log4j.isDebugEnabled())
          log4j.debug("priceActual:" + Double.toString(priceActual.doubleValue()));
        discount = ((priceStd.subtract(priceActual))
            .divide(priceStd, 12, RoundingMode.HALF_EVEN)).multiply(new BigDecimal("100"));     
        if (log4j.isDebugEnabled())
          log4j.debug("Discount: " + discount.toString());
        if (discount.scale() > StdPrecision)
          discount = discount.setScale(StdPrecision, RoundingMode.HALF_UP);
        }
        catch (Exception ex) {
          discount = ZERO;
        }
        if (log4j.isDebugEnabled())
          log4j.debug("Discount rounded: " + discount.toString());
        resultado.append("new Array(\"inpdiscount\", " + discount.toString() + "),");
      }
    } else if ((strChanged.equals("inpqtyordered") ||strChanged.equals("inpmProductPoId")||strChanged.equals("inpmAttributesetinstanceId")) && !("Y".equals(cancelPriceAd))) { // calculate Actual
        
        priceActual = new BigDecimal(SLOrderProductData.getOffersPrice(this,dataOrder[0].dateordered,
            dataOrder[0].cBpartnerId,strProduct,OrderQTY.compareTo(BigDecimal.ZERO)==0?qtyOrdered.toString():OrderQTY.toString(), dataOrder[0].mPricelistId,strOrderUOM,strMProductPOID,strAttribute,dataOrder[0].adOrgId, dataOrder[0].id)).setScale(PricePrecision, RoundingMode.HALF_UP);
        if (strChanged.equals("inpmProductPoId") && Issotrx.equals("N") ){
          resultado.append("new Array(\"inppricelist\", " + SLOrderAmtData.getPricestdAmt(this, strProduct,  dataOrder[0].mPricelistId, strOrderUOM, strMProductPOID,dataOrder[0].cBpartnerId) + "),");
          resultado.append("new Array(\"inppricestd\", " + SLOrderAmtData.getPricestdAmt(this, strProduct,  dataOrder[0].mPricelistId, strOrderUOM, strMProductPOID,dataOrder[0].cBpartnerId) + "),");
        }
        if (priceActual.scale() > PricePrecision)
          priceActual = priceActual.setScale(PricePrecision, RoundingMode.HALF_UP);
        
       // Standard- bzw. Mindest-Bestellmenge aus Einkauf (m_product_po) beruecksichtigen, wenn hinterlegt     
        if (strChanged.equals("inpqtyordered")||strChanged.equals("inpmProductPoId")) {
          BigDecimal qtyPurchase = new BigDecimal(SLOrderAmtData.mrp_getpo_qty(this, strProduct, dataOrder[0].cBpartnerId, OrderQTY.compareTo(BigDecimal.ZERO)==0?qtyOrdered.toString():OrderQTY.toString(),strOrderUOM,strMProductPOID));
          if (!qtyPurchase.equals(OrderQTY.compareTo(BigDecimal.ZERO)==0?qtyOrdered:OrderQTY)) {
            priomes=true;
            BigDecimal qtyPurchaseStd = new BigDecimal(SLOrderAmtData.mrp_getpo_qtystd(this, strProduct, dataOrder[0].cBpartnerId,strOrderUOM,strMProductPOID));
            BigDecimal qtyPurchaseMin = new BigDecimal(SLOrderAmtData.mrp_getpo_qtymin(this, strProduct, dataOrder[0].cBpartnerId,strOrderUOM,strMProductPOID));
            String qtyPurchaseIsMultiple = new String(SLOrderAmtData.mrp_getpo_ismultipleofminimumqty(this, strProduct, dataOrder[0].cBpartnerId,strOrderUOM,strMProductPOID));
            resultado.append("new Array('MESSAGE', \"" + FormatUtilities.replaceJS
            (
              Utility.messageBD(this, "ZSMP_PurchaseDefault",        vars.getLanguage()) + ":" +  "</br></br>" + 
              Utility.messageBD(this, "ZSMP_PurchaseDefault_QtyStd", vars.getLanguage()) + " = " + qtyPurchaseStd.toString() + "</br>" + 
              Utility.messageBD(this, "ZSMP_PurchaseDefault_QtyMin", vars.getLanguage()) + " = " + qtyPurchaseMin.toString() + "</br>" +
              Utility.messageBD(this, "ZSMP_PurchaseDefault_IsMult", vars.getLanguage()) + " = " + qtyPurchaseIsMultiple.toString() + "</br></br>" +
              Utility.messageBD(this, "ZSMP_PurchaseDefault_Qty",    vars.getLanguage()) + " = " + qtyPurchase.toString() + "  "  + // "</br>" +
              "<input type=\"button\" value=\"Anpassen\" href=\"#\"  style=\"cursor:pointer;\" onclick=\"submitCommandFormParameter('DEFAULT', frmMain.inpLastFieldChanged, 'QtyOrdered', false, null, '../ad_callouts/SL_Order_Amt.html', 'hiddenFrame', null, null, true); return false;\" class=\"LabelLink\">"
            ) + "\"),");
          } else {
            resultado.append("new Array('MESSAGE', \"" + "\"),"); // reset Message, reset MessageBox
          }
        } 
        if (priceActual.compareTo(ZERO)!=0 || Issotrx.equals("N")) {
          if(priceActual.compareTo(new BigDecimal(strPriceActual))!=0 && priomes==false){
              String strPJS=strPriceActual.replace('.',',');
              //Here are the Changes for Notifying Price Changes
              resultado.append("new Array('MESSAGE', \"" + "\"),"); // reset Message, reset MessageBox
              resultado.append("new Array('MESSAGE', \"" + FormatUtilities.replaceJS
                (
                  Utility.messageBD(this, "ZSPM_PriceActual_changed",    vars.getLanguage()) + " = " + strPJS + "  "  + // "</br>" +
                  "<input type=\"button\" value=\"Anpassen\" href=\"#\"  style=\"cursor:pointer;\" onclick=\"PunktKomma("+strPriceActual+");\" class=\"LabelLink\">"
                ) + "\"),");  }
        resultado.append("new Array(\"inppriceactual\", " + priceActual.toString()  + "),");
        }
        
        if (priceStd.compareTo(ZERO)!=0) {
             discount = ((priceStd.subtract(priceActual)).divide(priceStd, 12, RoundingMode.HALF_EVEN)).multiply(new BigDecimal("100"));
             if (discount.scale() > StdPrecision)
               discount = discount.setScale(StdPrecision, RoundingMode.HALF_UP);
             if (log4j.isDebugEnabled())
               log4j.debug("Discount rounded: " + discount.toString());
             resultado.append("new Array(\"inpdiscount\", " + discount.toString() + "),");
        }
        

    } else if (strChanged.equals("inpdiscount")) { // calculate std and actual
      
        // SZ doesn't make sense????
        priceActual = (priceStd).subtract((discount.multiply(priceStd)).divide(new BigDecimal("100")));  
        if (priceActual.scale() > PricePrecision)
          priceActual = priceActual.setScale(PricePrecision, RoundingMode.HALF_UP);
        resultado.append("new Array(\"inppriceactual\", " + priceActual.toString() + "),");
        
    } 
    if (strChanged.equals("inpmProductPoId")||strChanged.equals("inpmProductUomId")) {   
      String strPositionText = this.getDocumentText(strProduct, dataOrder[0].cBpartnerId, Issotrx,dataOrder[0].adOrgId ,vars.getLanguage(),strOrderUOM,strMProductPOID);
      resultado.append("new Array(\"inpdescription\", " + (strPositionText.equals("") ? "\"" : "\"" + strPositionText) + "\"),");
    }
    if (Issotrx.equals("Y")) {
      if (!strStockSecurity.equals("0")) {
        if (qtyOrdered.compareTo(BigDecimal.ZERO) != 0) {
          if (strEnforceAttribute.equals("N")) {
            strStockNoAttribute = SLOrderStockData.totalStockNoAttribute(this, strProduct, strUOM);
            stockNoAttribute = new BigDecimal(strStockNoAttribute);
            resultStock = stockNoAttribute.subtract(qtyOrdered);
            if (stockSecurity.compareTo(resultStock) > 0) {
              resultado.append("new Array('MESSAGE', \""
                  + FormatUtilities.replaceJS(Utility.messageBD(this, "StockLimit", vars
                      .getLanguage())) + "\"),");
            }
          } else {
            if (!strAttribute.equals("") && strAttribute != null) {
              strStockAttribute = SLOrderStockData.totalStockAttribute(this, strProduct, strUOM,
                  strAttribute);
              stockAttribute = new BigDecimal(strStockAttribute);
              resultStock = stockAttribute.subtract(qtyOrdered);
              if (stockSecurity.compareTo(resultStock) > 0) {
                resultado.append("new Array('MESSAGE', \""
                    + FormatUtilities.replaceJS(Utility.messageBD(this, "StockLimit", vars
                        .getLanguage())) + "\"),");
              }
            }
          }
        }
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug(resultado.toString());
    if (!strChanged.equals("inpqtyordered") & Issotrx.equals("Y")) { // Check PriceLimit
      boolean enforced = SLOrderAmtData.listPriceType(this, strMPricelistId);
      // Check Price Limit?
      if (enforced && priceLimit.compareTo(BigDecimal.ZERO) != 0
          && priceActual.compareTo(priceLimit) < 0)
        resultado.append("new Array('MESSAGE', \""
            + Utility.messageBD(this, "UnderLimitPrice", vars.getLanguage()) + "\"),");
    }


    BigDecimal lineNetAmt;
    if (OrderQTY.compareTo(ZERO)!=0) lineNetAmt = OrderQTY.multiply(priceActual);
    else lineNetAmt = qtyOrdered.multiply(priceActual);
    if (lineNetAmt.scale() > StdPrecision)
      lineNetAmt = lineNetAmt.setScale(StdPrecision, RoundingMode.HALF_UP);
    
    // MIn Purchase Val.
    if ((Issotrx.equals("N")&& priomes==false) && (strChanged.equals("QtyOrdered")|| strChanged.equals("inpqtyordered")||strChanged.equals("inpmProductPoId")||strChanged.equals("inpdiscount")|| strChanged.equals("inppriceactual"))) {
    	int minPurchaseval = Integer.valueOf(SLOrderAmtData.mrp_getpo_minimpositionvalue(this, strProduct, dataOrder[0].cBpartnerId,strOrderUOM,strMProductPOID));
    	if (new BigDecimal(minPurchaseval).compareTo(lineNetAmt)>0) {
    		resultado.append("new Array('MESSAGE', \"" + "\"),"); // reset Message, reset MessageBox
    		String mess= Utility.messageBD(this, "MinimumPositionValueUnderrun", vars.getLanguage()) + " " + minPurchaseval +
    				     ",-" + SLOrderPriceListData.select(this, strMPricelistId)[0].cursymbol;
    		resultado.append("new Array('MESSAGE', \"" +  mess + "\"),");
    	}	
    }
    
    resultado.append("new Array(\"inplinenetamt\", " + lineNetAmt.toString() + ")");
    
    resultado.append(");");
    xmlDocument.setParameter("array", resultado.toString());
    xmlDocument.setParameter("frameName", "appFrame");
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }
}
