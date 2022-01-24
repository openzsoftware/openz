package org.zsoft.ecommerce.order.client.sangro.response;

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

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.openz.util.UtilsData;
import org.zsoft.ecommerce.FilePollingAPI;
import org.zsoft.ecommerce.OrderStatusData;
import org.zsoft.ecommerce.WebServicesData;

import com.github.sardine.DavResource;
import com.github.sardine.Sardine;
import com.github.sardine.SardineFactory;

public class PollingSangro implements FilePollingAPI{

  // TODO remove with Java 8
  @Override
  public void fetchAndProcess(ConnectionProvider conn, VariablesSecureApp vars, String baseDesignPath, String filePath) {}		

  public void fetchAndProcess(ConnectionProvider conn,String apikey,String secret,String shop) throws Exception {
    //get file via WebDav
    Sardine sardine = SardineFactory.begin();
    // Write Files to disk
    final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
    final File toDir = new File(fileDir + "/" + "sangro");
    if (!toDir.exists())
      toDir.mkdirs();
    final File sndDir = new File(fileDir + "/" + "sangro/received");
    if (!sndDir.exists())
      sndDir.mkdirs();
    String fname="";
   // receive files via WebDav
    WebServicesData[] wsd=WebServicesData.selectShopCredentials(conn, shop);
    if (wsd.length==0) {
      throw new Exception("The shop is not defined.");
    }
    sardine.setCredentials(wsd[0].apikey,wsd[0].secret);
    List<DavResource> resources = sardine.list(wsd[0].url + "/von_sangro/" );
    for (DavResource res : resources)
    {
      if (!res.isDirectory()) {
         String url=wsd[0].url + "/von_sangro/" +res.getName();
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

         JAXBContext context = JAXBContext.newInstance(TransferFile.class);
         Unmarshaller um = context.createUnmarshaller();
         TransferFile tf= (TransferFile) um.unmarshal(new FileReader(outputFile));
         Bestellung[] bstar=tf.getBestellungen().getBestellung();
         if (bstar!=null) {
           for (int i=0;i<bstar.length;i++) {
             String strShipper="";
             String strTracking="";
             try {
               strShipper=bstar[i].getSpedition().getName();
               strTracking=bstar[i].getSpedition().getReferenznummer();
             } catch (final Exception ex) {
               strShipper="n/a";
               strTracking="n/a";
             }
             String strDocNo=bstar[i].getBestellreferenz().substring(2);
             String strBelegNo=bstar[i].getBelegNummer();
             String strOrderID=OrderStatusData.getPurchaseOrderIDByDocumentno(conn, strDocNo);
             String strStatusId=OrderStatusData.getStatusIDByOrder(conn,strOrderID);
             OrderStatusData.updateOrderStatus(conn, "GOODS IN TRANSIT", "",strTracking,strShipper,null,strStatusId);
           }
         }
         ABL[] ablar=tf.getBestellungen().getABL();
         if (ablar!=null) {
           for (int i=0;i<ablar.length;i++) {
             String strShipper=ablar[i].getSpedtion().getName();
             String strTracking=ablar[i].getSpedtion().getReferenznummer();
             String dateDeliver=ablar[i].getZustelldatum();
             String strBelegNo=ablar[i].getBelegNummer();
             String strDocNo=ablar[i].getBestellreferenz().substring(2);
             String strOrderID=OrderStatusData.getPurchaseOrderIDByDocumentno(conn, strDocNo);
             String strStatusId=OrderStatusData.getStatusIDByOrder(conn,strOrderID);
             OrderStatusData.updateOrderStatus(conn, "DELIVERY COMPLETED", "",strTracking,strShipper,dateDeliver,strStatusId);
           }
         }
         sardine.delete(url);
      }
         
    }
  }
}
