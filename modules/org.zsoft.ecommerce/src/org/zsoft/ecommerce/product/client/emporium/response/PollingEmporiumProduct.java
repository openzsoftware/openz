package org.zsoft.ecommerce.product.client.emporium.response;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.StringWriter;
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
import java.math.BigDecimal;
import java.security.KeyStore;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.Marshaller;

import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.openz.util.UtilsData;
import org.zsoft.ecommerce.*;
import org.zsoft.ecommerce.order.client.OrderData;
import org.zsoft.ecommerce.order.client.emporium.request.Htgaovorder;
import org.zsoft.ecommerce.product.client.emporium.response.*;
import org.zsoft.ecommerce.product.*;
import org.zsoft.ecommerce.product.ProductData;
import com.github.sardine.Sardine;
import com.github.sardine.impl.SardineImpl;
import org.openbravo.base.*;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.List;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.Unmarshaller;

import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;

import org.zsoft.ecommerce.FilePollingAPI;


import com.github.sardine.DavResource;
import com.github.sardine.Sardine;
import com.github.sardine.SardineFactory;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.fop.apps.Driver;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import org.openarchitectureware.debug.communication.Connection;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.database.ConnectionProviderImpl;
import org.openbravo.database.JNDIConnectionProvider;
import org.openbravo.exception.NoConnectionAvailableException;
import org.openbravo.exception.PoolNotFoundException;
import org.openbravo.xmlEngine.XmlEngine;
import org.xml.sax.InputSource;
import org.xml.sax.XMLReader;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

public class PollingEmporiumProduct implements FilePollingAPI{


  // TODO remove with Java 8
  @Override
  public void fetchAndProcess(ConnectionProvider conn, VariablesSecureApp vars, String baseDesignPath, String filePath) {}

  public void fetchAndProcess(ConnectionProvider conn,String apikey,String secret,String shop) throws Exception {
    //get file via WebDav
    //Sardine sardine = SardineFactory.begin();
    Connection connection=null;
    String  keyStoreFilename = "";
    String deployDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("tomcat.path");
    if (deployDir.equals("xxx")) {
      deployDir= System.getenv("OPENZ_GITOSS") ;
      keyStoreFilename = deployDir + "/modules/org.openz.xmlapi/src/org/openz/xmlapi/transfair.jks";
    }
    else
      keyStoreFilename = deployDir + "/src-loc/design/org/openz/xmlapi/transfair.jks";
    File keystoreFile = new File(keyStoreFilename);
    FileInputStream fis = new FileInputStream(keystoreFile);        
    KeyStore keyStore = KeyStore.getInstance(KeyStore.getDefaultType()); // JKS
    keyStore.load(fis, null); 
    @SuppressWarnings( "deprecation" )
    final org.apache.http.conn.ssl.SSLSocketFactory socketFactory = new org.apache.http.conn.ssl.SSLSocketFactory(keyStore);   
    Sardine sardine = new SardineImpl() {
      @Override
      @SuppressWarnings( "deprecation" )
      protected org.apache.http.conn.ssl.SSLSocketFactory createDefaultSecureSocketFactory() {
          return socketFactory;
      }           
  };
    // Write Files to disk
    final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
    final File toDir = new File(fileDir + "/" + "emporium");
    if (!toDir.exists())
      toDir.mkdirs();
    final File sndDir = new File(fileDir + "/" + "emporium/received");
    if (!sndDir.exists())
      sndDir.mkdirs();
    String fname="";
   // receive files via WebDav
    WebServicesData[] wsd=WebServicesData.selectShopCredentials(conn, shop);
    String aduser =wsd[0].adUserId;
    String org ="0";
    String client =wsd[0].getClient(conn, org);
    
        if (wsd.length==0) {
      throw new Exception("The shop is not defined.");
    }
    sardine.setCredentials(wsd[0].apikey,wsd[0].secret);
    List<DavResource> resources = sardine.list(wsd[0].url  );
    for (DavResource res : resources)
    {
      if (res.isDirectory()) {
         String url=wsd[0].url + "/von_emporium/" + "Stock.xml" ;
         fname=res.getName()+".xml";
         InputStream is= sardine.get(url);
         BufferedReader reader = new BufferedReader(new InputStreamReader(is));
         final File outputFile = new File(sndDir, fname);
         FileOutputStream fos=new FileOutputStream(outputFile);
         String line;
         while ((line = reader.readLine()) != null) {
           fos.write(line.getBytes());
           fos.flush();
       }
         fos.flush();
         fos.close();

         JAXBContext context = JAXBContext.newInstance(StockEntry.class);
         Unmarshaller um = context.createUnmarshaller();
         StockEntry se= (StockEntry) um.unmarshal(new FileReader(outputFile));
         String stock=se.getStock().getDate();
         Product[] products=se.getStock().getProduct();
         String ExistingProduct ="";
         String ExistingProductCategory ="";
         if (stock!=null) {
           
             String strBarcode="";
             String strArticleNumber="";
             String strConcern="";
             String strBrand="";
             String strGender="";
             String strAvailableStock="";
             String strType="";
             String strAssortment="";
             String strBrandLine="";
             String strSort="";
             String strUsedFor="";
             String strVersion="";
             String strEdition="";
             String strColor="";
             String strLength="";
             String strWidth="";
             String strHeight="";
             String strReference="";
             String strWeight="";
             String strWeight_UnitOfMeasure="";
             String strDescription="";
             String strStockType="";
             String strAdditionalProductInformation="";
             String strExternalArticleNumber="";
             String strSuggestedRetailPrice="";
             String strPrice="";
             String strSuggestedSalesPrice="";
             String strCurrency="";
             String strCategory="";
             String strCategoryDescription="";
               String strLanguageCode="";
               String strProductExtendedDescription="";
               String strProductShortDescription="";
               String strProductSortDescription="";
               String strExtendedDescription="";
               
             try {
               for (int i=0;i<products.length;i++){
               strBarcode=products[i].getBarcode();
               strArticleNumber=products[i].getArticleNumber();
               strConcern=products[i].getConcern();
               strBrand=products[i].getBrand();
               strGender=products[i].getAvailableStock();
               strAvailableStock=products[i].getAvailableStock();
               strType=products[i].getType();
               strAssortment=products[i].getAssortment();
               strBrandLine=products[i].getBrandLine();
               strSort=products[i].getSort();
               strUsedFor=products[i].getUsedFor();
               strVersion=products[i].getVersion();
               strEdition=products[i].getEdition();
               strColor=products[i].getColor();
               strLength=products[i].getLength();
               strWidth=products[i].getWidth();
               strHeight=products[i].getHeight();
               strReference=products[i].getReference();
               strWeight=products[i].getWeight();
               strWeight_UnitOfMeasure=products[i].getWeight_UnitOfMeasurement();
               strDescription=products[i].getDescription();
               strStockType=products[i].getStockType();
               strAdditionalProductInformation=products[i].getAdditionalProductInformation();
               strExternalArticleNumber=products[i].getExternalArticleNumber();
               strSuggestedRetailPrice=products[i].getSuggestedRetailPrice();
               strPrice=products[i].getPrice();
               strSuggestedSalesPrice=products[i].getSuggestedSalesPrice();
               strCurrency=products[i].getCurrency();
               strCategory=products[i].getCategory();
               strCategoryDescription=products[i].getCategoryDescription();
               ExistingProduct=ProductData.isExstingProduct(conn, strArticleNumber);
               ExistingProductCategory=ProductData.isExstingCategory(conn, strCategory);
                 if (ExistingProduct==null) {
                   if (ExistingProductCategory==null) {
                     
                     ProductData.insertProductCategory( conn, client,aduser,org,strCategory,strCategory,strCategoryDescription);}
                     ProductData.insertProduct( conn, client,aduser,org,strArticleNumber,strDescription,strWidth,strHeight,strWeight,strDescription,strAdditionalProductInformation,strCategory);
                     ExistingProduct=ProductData.isExstingProduct(conn, strArticleNumber);
                     ProductData.insertPPurchase(conn, client, aduser, org, shop, strPrice, strPrice, strCurrency, ExistingProduct);
                     ProductData.insertSPrice(conn, client, aduser, org, strSuggestedRetailPrice,strSuggestedRetailPrice,strCurrency,ExistingProduct);

                   
                   
                   
                   
                 } else{
                   ProductData.updateProduct( conn, strWidth,strHeight,strWeight,strDescription,strAdditionalProductInformation,ExistingProduct);
                   ProductData.updatePPurchase( conn, strPrice, strPrice,ExistingProduct);
                   ProductData.updateSPrice( conn,strSuggestedRetailPrice,strSuggestedRetailPrice,ExistingProduct);
                 }
                 
                 
                 ProductTranslation [] ptrls =products[i].getProductTranslation();
                   for (int j=0;j<ptrls.length;j++){
                     strLanguageCode=ptrls[j].getLanguageCode();
                     strProductExtendedDescription=ptrls[j].getProductExtendedDescription();
                     strProductShortDescription=ptrls[j].getProductShortDescription();
                     strProductSortDescription=ptrls[j].getProductSortDescription();
                     strExtendedDescription=ptrls[j].getExtendedDescription();
                   }
                   
                   
             }} catch (final Exception ex) {
               strBarcode="n/a";
               strArticleNumber="n/a";
               strConcern="n/a";
               strBrand="n/a";
               strGender="n/a";
               strAvailableStock="n/a";
               strType="n/a";
               strAssortment="n/a";
               strBrandLine="n/a";
               strSort="n/a";
               strUsedFor="n/a";
               strVersion="n/a";
               strEdition="n/a";
               strColor="n/a";
               strLength="n/a";
               strWidth="n/a";
               strHeight="n/a";
               strReference="n/a";
               strWeight="n/a";
               strWeight_UnitOfMeasure="n/a";
               strDescription="n/a";
               strStockType="n/a";
               strAdditionalProductInformation="n/a";
               strExternalArticleNumber="n/a";
               strSuggestedRetailPrice="n/a";
               strCurrency="n/a";
               strPrice="n/a";
               strSuggestedSalesPrice="n/a";
               strCategory="n/a";
               strCategoryDescription="n/a";
               strLanguageCode="n/a";
               strProductExtendedDescription="n/a";
               strProductShortDescription="n/a";
               strProductSortDescription="n/a";
               strExtendedDescription="n/a";
             }

           }
         sardine.delete(url);}
         
      }
         
    }
  }
