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
package org.zsoft.ecommerce.product;
import java.math.BigDecimal;

import org.apache.log4j.Logger;
import org.zsoft.ecommerce.*;

public class ProductService extends WebService {
  private static Logger log4j = Logger.getLogger(ProductService.class);
     public Product[] getProductsComplete(String orgId, String username, String password) throws Exception  {
         Product[] products=null;
         ProductTranslation[] ptrls =null;
         if (!access(username, password,orgId)) {
           if (log4j.isDebugEnabled())
             log4j.debug("Access denied for user: " + username);
           throw new Exception("Access denied for user: " + username); 
         }
         try {
         ProductData[] data = ProductData.select(pool, orgId);
         products = new Product[data.length];
         String strPrice;
         for (int i = 0; i < data.length; i++) {
           products[i] = new Product();
           products[i].setMProductId(data[i].mProductId);
           products[i].setValue(data[i].value);
           products[i].setName(data[i].name);
           products[i].setEancode(data[i].eancode);
           products[i].setDescription(data[i].description);
           products[i].setDocumentnote(data[i].documentnote);
           products[i].setProductCategoryKey(data[i].productCategoryKey);
           products[i].setUomKey(data[i].uomKey);
           products[i].setIsfreightproduct(data[i].isfreightproduct);
           products[i].setWeight(new BigDecimal(data[i].weight));
           products[i].setImageurl(data[i].imageurl);
           products[i].setDescriptionurl(data[i].descriptionurl);
           products[i].setECommerceCategory(data[i].eccategory);
           products[i].setIsgrossprice(data[i].isgrossprice);
           products[i].setIsorderable(data[i].isorderable);
           products[i].setTaxname(data[i].taxname);
           products[i].setTaxrate(new BigDecimal(data[i].taxrate));
           products[i].setECommercePriority(new BigDecimal(data[i].ecpriority));
           strPrice = ProductData.getProductPrice(pool, orgId,"", data[i].mProductId, "1");
           products[i].setStdprice(new BigDecimal(strPrice));
           ProductTrlData[] trldata = ProductTrlData.select(pool,data[i].mProductId);
           ptrls = new ProductTranslation[trldata.length];
           for (int j = 0; j < trldata.length; j++) {
                 ptrls[j] = new ProductTranslation();
                 ptrls[j].setAdLanguage(trldata[j].adLanguage);
                 ptrls[j].setName(trldata[j].name);
                 ptrls[j].setMProductId(trldata[j].mProductId);
                 ptrls[j].setDescription(trldata[j].description);
                 ptrls[j].setDocnote(trldata[j].documentnote);
           }
           if (trldata.length>0)
               products[i].setTranslations(ptrls);
         }
         } catch (Exception e) {
           log4j.error(e.getMessage());
           throw new Exception("Exception in Webservice: " + e.getMessage()); 
         } finally {
           destroyPool();
         }
         return products;
     }
     public BigDecimal getStockQuantity(String orgId, String username, String password,String mProductId) throws Exception  {
         if (!access(username, password,orgId)) {
           if (log4j.isDebugEnabled())
             log4j.debug("Access denied for user: " + username);
           throw new Exception("Access denied for user: " + username); 
         }
         String strQty=null;
         try {
         strQty = ProductData.getStockQty(pool, mProductId, orgId);
         } catch (Exception e) {
           log4j.error(e.getMessage());
           throw new Exception("Exception in Webservice: " + e.getMessage()); 
         } finally {
           destroyPool();
         }
         if (strQty==null)
           strQty="0";
         return new BigDecimal(strQty);
     }
     public BigDecimal getProductPrice(String orgId, String username, String password,String cBpartnerId,String mProductId, BigDecimal qty) throws Exception {
         if (!access(username, password,orgId)) {
           if (log4j.isDebugEnabled())
             log4j.debug("Access denied for user: " + username);
           throw new Exception("Access denied for user: " + username); 
         }
         String strQty=qty.toString();
         String strPrice = null;
         try {
           strPrice = ProductData.getProductPrice(pool, orgId, cBpartnerId, mProductId, strQty);
           } catch (Exception e) {
             log4j.error(e.getMessage());
             throw new Exception("Exception in Webservice: " + e.getMessage()); 
           } finally {
             destroyPool();
           }
           if (strPrice==null)
             strPrice="0";
           return new BigDecimal(strPrice);
     }
}
