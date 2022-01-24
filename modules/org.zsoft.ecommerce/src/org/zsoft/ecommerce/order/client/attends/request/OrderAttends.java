package org.zsoft.ecommerce.order.client.attends.request;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.StringWriter;
import java.security.KeyStore;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.Marshaller;

import org.apache.commons.io.IOUtils;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.openz.util.UtilsData;
import org.zsoft.ecommerce.FilePollingServiceData;
import org.zsoft.ecommerce.OrderStatusData;
import org.zsoft.ecommerce.WebServicesData;
import org.zsoft.ecommerce.order.client.CustomerData;
import org.zsoft.ecommerce.order.client.OrderClientAPIRequest;
import org.zsoft.ecommerce.order.client.OrderData;
import org.zsoft.ecommerce.order.client.OrderlineData;

import com.github.sardine.Sardine;
import com.github.sardine.impl.SardineImpl;

public class OrderAttends  implements OrderClientAPIRequest{
  
  public void processOrder(String porder, ConnectionProvider conn) throws Exception {
    
    String shop=OrderData.selectRemoteShopId(conn, porder);  
    OrderData[] data = OrderData.select(conn, porder);
    String dropship=OrderData.selectDropShipCustomerOrder(conn, porder);
    JAXBContext context = JAXBContext.newInstance(Sv97daten.class);
    Sv97daten sv97=new Sv97daten();
    CustomerData[] cust = CustomerData.select(conn, dropship);
    if (data.length > 0 ) {     
      Sv97kopf kpf97 = new Sv97kopf();     
      Kopf kpf = new Kopf();     
      kpf.setAuftragnr(data[0].documentno);
      kpf.setBemerkung(data[0].description);
      kpf.setTeillieferung("1");
      kpf.setVersand("1");
      if (!data[0].sddami.isEmpty())
        kpf.setLiefertermin(data[0].sddami + " 00:00:00");
      if (cust.length>0) {
       kpf.setKdname1(cust[0].bpname);
       kpf.setKdort(cust[0].city);
       kpf.setKdplz(cust[0].postal);
       kpf.setKdstrasse(cust[0].address1);
      }
      else {
        AttendsData[] ats=AttendsData.select(conn,  porder);
        kpf.setKdname1(ats[0].name);
        kpf.setKdort(ats[0].city);
        kpf.setKdplz(ats[0].postal);
        kpf.setKdstrasse(ats[0].address1);
      }
      OrderlineData[] lines=OrderlineData.select(conn, porder);
      Sv97position svps=new Sv97position();
      Position[] posar= new Position[lines.length];
      for (int i=0;i<lines.length;i++){
        Position pos=new Position();
        pos.setAuftragnr(data[0].documentno);
        pos.setEan(lines[i].ean);
        pos.setMenge(lines[i].qtyordered);
        posar[i]=pos;
      }
      svps.setPosition(posar);
      kpf97.setKopf(kpf);
      sv97.setSv97kopf(kpf97);
      sv97.setSv97position(svps);
    }
    StringWriter xmlOutput = new StringWriter();
    Marshaller margie = context.createMarshaller();
    margie.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);
    //margie.setProperty(Marshaller.JAXB_ENCODING, "ISO-8859-15");
    margie.marshal(sv97, xmlOutput);
    // Create File
    final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
    final File toDir = new File(fileDir + "/" + "attends");
    if (!toDir.exists())
      toDir.mkdirs();
    final File sndDir = new File(fileDir + "/" + "attends/sent");
    if (!sndDir.exists())
      sndDir.mkdirs();
    String fname="0030_attendsOrder-" + data[0].documentno + "-" + UtilsData.getFilenameTimestamp(conn) +".xml";
    final File outputFile = new File(sndDir, fname);
    try {
      FileWriter out = new FileWriter(outputFile);
      out.write(FilePollingServiceData.textwithHtmlEscapes(conn, xmlOutput.toString()));
      out.flush();
      out.close();
      FileInputStream in = new FileInputStream(outputFile);
      // Send file via WebDav
     // Sardine sardine = SardineFactory.begin();
      
      String deployDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("tomcat.path");
      String  keyStoreFilename = "";
      if (deployDir.equals("xxx")) {
        deployDir= System.getenv("OPENZ_GITOSS") ;
        keyStoreFilename = deployDir + "/modules/org.zsoft.ecommerce/src/org/zsoft/ecommerce/order/client/attends/attends.jks";
      }
      else
        keyStoreFilename = deployDir + "/src-loc/design/org/zsoft/ecommerce/order/client/attends/attends.jks";
      File keystoreFile = new File(keyStoreFilename);
      FileInputStream fis = new FileInputStream(keystoreFile);        
      KeyStore keyStore = KeyStore.getInstance(KeyStore.getDefaultType()); // JKS
      keyStore.load(fis, null); 
      @SuppressWarnings("deprecation")
      final org.apache.http.conn.ssl.SSLSocketFactory socketFactory = new org.apache.http.conn.ssl.SSLSocketFactory(keyStore);              

      Sardine sardine = new SardineImpl() {
          @Override
          @SuppressWarnings("deprecation")
          protected org.apache.http.conn.ssl.SSLSocketFactory createDefaultSecureSocketFactory() {
              return socketFactory;
          }           
      };
      
      
      WebServicesData[] wsd=WebServicesData.selectShopCredentials(conn, shop);
      if (wsd.length==0) {
        in.close();
        outputFile.delete();
        throw new Exception("The shop is not defined.");
      }
      sardine.setCredentials(wsd[0].apikey,wsd[0].secret);
      byte[] bytes = IOUtils.toByteArray(in);
      sardine.put(wsd[0].url + "/" + fname, bytes);
      in.close();
      // Status Record
      OrderStatusData.insertOrderStatusNew(conn, data[0].adOrgId, shop,"n/a", data[0].documentno, porder, "ORDER FILE SENT",fname , "N");
      OrderData.InsertPoReference(conn, null, porder);
    } catch (Exception e) {
      outputFile.delete();
      throw new Exception("Exception in Order Attends: " + e.getMessage()); 
    }
  }
}
