package org.zsoft.ecommerce.order.client.attends.response;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.security.KeyStore;
import java.util.List;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.Unmarshaller;

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.zsoft.ecommerce.FilePollingAPI;
import org.zsoft.ecommerce.OrderStatusData;
import org.zsoft.ecommerce.WebServicesData;

import com.github.sardine.DavResource;
import com.github.sardine.Sardine;
import com.github.sardine.impl.SardineImpl;

public class PollingAttends implements FilePollingAPI{
  
  // TODO remove with Java 8
  @Override
  public void fetchAndProcess(ConnectionProvider conn, VariablesSecureApp vars, String baseDesignPath, String filePath) {}
  
  public void fetchAndProcess(ConnectionProvider conn,String apikey,String secret,String shop) throws Exception {
    //get file via WebDav
    //Sardine sardine = SardineFactory.begin();
    // Write Files to disk
    final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
    final File toDir = new File(fileDir + "/" + "attends");
    if (!toDir.exists())
      toDir.mkdirs();
    final File sndDir = new File(fileDir + "/" + "attends/received");
    if (!sndDir.exists())
      sndDir.mkdirs();
    String fname="";
   // receive files via WebDav
    WebServicesData[] wsd=WebServicesData.selectShopCredentials(conn, shop);
    if (wsd.length==0) {
      throw new Exception("The shop is not defined.");
    }
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
    @SuppressWarnings( "deprecation" )
    final org.apache.http.conn.ssl.SSLSocketFactory socketFactory = new org.apache.http.conn.ssl.SSLSocketFactory(keyStore);              

    Sardine sardine = new SardineImpl() {
        @Override
        @SuppressWarnings( "deprecation" )
        protected org.apache.http.conn.ssl.SSLSocketFactory createDefaultSecureSocketFactory() {
            return socketFactory;
        }           
    };
    sardine.setCredentials(wsd[0].apikey,wsd[0].secret);
    List<DavResource> resources = sardine.list(wsd[0].url + "/" );
    for (DavResource res : resources)
    {
      if (!res.isDirectory() && (res.getName().startsWith("0032")||res.getName().startsWith("0033")||res.getName().startsWith("0031"))) {
         String url=wsd[0].url + "/" +res.getName();
         fname=res.getName();
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
       if (res.getName().startsWith("0032")){
         JAXBContext context = JAXBContext.newInstance(Sv97daten.class);
         Unmarshaller um = context.createUnmarshaller();
         Sv97daten sv97= (Sv97daten) um.unmarshal(new FileReader(outputFile));
         Best[] bstar=sv97.getSv97best().getBest();
        
         for (int i=0;i<bstar.length;i++) {
           String strAttendsNr=bstar[i].getAuftragnrsic();
           String strDocNo=bstar[i].getAuftragnr();
           String strOrderID=OrderStatusData.getPurchaseOrderIDByDocumentno(conn, strDocNo);
           String strStatusId=OrderStatusData.getStatusIDByOrder(conn,strOrderID);
           String strDateDeliver=bstar[i].getLieferdatum();
           OrderStatusData.updateOrderStatus(conn, "PROCESSING ORDER WAITING SHIPMENT", "Attends Auftragsnummer:" + strAttendsNr + ". Vor. Lieferdatum:" + strDateDeliver,"n/a","n/a",null,strStatusId);
         }
         Dhl[] ablar=sv97.getSv97dhl().getDhl();
         for (int i=0;i<ablar.length;i++) {
           String strShipper=ablar[i].getPaketdienst();
           if (strShipper.equals("3"))
             strShipper="DPD";
           else 
             strShipper="DHL";
           String strTracking=ablar[i].getDhlnr();
           String strDocNo=ablar[i].getAuftragnr();
           String strOrderID=OrderStatusData.getPurchaseOrderIDByDocumentno(conn, strDocNo);
           String strStatusId=OrderStatusData.getStatusIDByOrder(conn,strOrderID);
           if (strTracking!=null && ! strTracking.isEmpty())
             OrderStatusData.updateOrderStatus(conn, "GOODS IN TRANSIT", ".",strTracking,strShipper,null,strStatusId);
         }
       } 
       if (res.getName().startsWith("0033")) {
         JAXBContext context = JAXBContext.newInstance(Sv97datenU.class);
         Unmarshaller um = context.createUnmarshaller();
         Sv97datenU sv97= (Sv97datenU) um.unmarshal(new FileReader(outputFile));
         String strTracking=sv97.getSv97image().getImage().getDhlnr();
         String strDocNo=sv97.getSv97image().getImage().getAuftragnr();
         String dateDeliver=sv97.getSv97image().getImage().getLieferdatum_dhl();
         dateDeliver=dateDeliver.substring(8,10) + "." + dateDeliver.substring(5,7) + "." +dateDeliver.substring(0,4);
         String strOrderID=OrderStatusData.getPurchaseOrderIDByDocumentno(conn, strDocNo);
         String strShipper=sv97.getSv97image().getImage().getPaketdienst();
         if (strShipper.equals("3"))
           strShipper="DPD";
         else 
           strShipper="DHL";
         
         String strStatusId=OrderStatusData.getStatusIDByOrder(conn,strOrderID);
         OrderStatusData.updateOrderStatus(conn, "DELIVERY COMPLETED", ".",strTracking,strShipper,dateDeliver,strStatusId);
       }
       if (res.getName().startsWith("0031")) {
         JAXBContext context = JAXBContext.newInstance(Sv97datenE.class);
         Unmarshaller um = context.createUnmarshaller();
         Sv97datenE sv97= (Sv97datenE) um.unmarshal(new FileReader(outputFile));
         try {
           String strDocNo=sv97.getSv97fehler().getFehler().getAuftragnr();
           String strOrderID=OrderStatusData.getPurchaseOrderIDByDocumentno(conn, strDocNo);        
           String strStatusId=OrderStatusData.getStatusIDByOrder(conn,strOrderID);
           OrderStatusData.updateOrderStatus(conn, "ERROR",sv97.getSv97fehler().getFehler().getFehlermeldung() ,"","","",strStatusId);
         } catch (Exception e) {
           String strDocNo=sv97.getSv97best().getBest()[0].getAuftragnr();
           String strOrderID=OrderStatusData.getPurchaseOrderIDByDocumentno(conn, strDocNo);        
           String strStatusId=OrderStatusData.getStatusIDByOrder(conn,strOrderID);
           OrderStatusData.updateOrderStatus(conn, "PROCESSING ORDER","Nrsic:"+sv97.getSv97best().getBest()[0].getAuftragnrsic(),"","","",strStatusId);
         }
         
       }
         sardine.delete(url);
      }
         
    }
  }
}
