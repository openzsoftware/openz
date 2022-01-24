package org.zsoft.ecommerce.order.client.sangro.request;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.StringWriter;
import java.sql.Connection;
import java.util.Date;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.Marshaller;

import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.scheduling.ProcessBundle;
import org.openz.util.UtilsData;
import org.zsoft.ecommerce.FilePollingServiceData;
import org.zsoft.ecommerce.OrderStatusData;
import org.zsoft.ecommerce.WebServicesData;
import org.zsoft.ecommerce.order.client.CustomerData;
import org.zsoft.ecommerce.order.client.OrderClientAPIRequest;
import org.zsoft.ecommerce.order.client.OrderData;
import org.zsoft.ecommerce.order.client.OrderlineData;

import com.github.sardine.Sardine;
import com.github.sardine.SardineFactory;


public class OrderSangro implements OrderClientAPIRequest{
  public void processOrder(String porder,ConnectionProvider conn) throws Exception {
    String shop=OrderData.selectRemoteShopId(conn, porder);  
    OrderData[] data = OrderData.select(conn, porder);
    String dropship=OrderData.selectDropShipCustomerOrder(conn, porder);
    JAXBContext context = JAXBContext.newInstance(TransferFile.class);
    TransferFile tf=new TransferFile();
    CustomerData[] cust = CustomerData.select(conn, dropship);
    if (data.length > 0 ) {     
      tf.setSangroKundenNummer(OrderData.selectOwnCustromerNoAtVendorSite(conn, porder));
      Bestellungen bstl = new Bestellungen();
      Bestellung[] bstar=new Bestellung[1];
      Bestellung bst = new Bestellung();
      Kommission komm= new Kommission();
      bst.setBelegNummer(data[0].documentno);
      bst.setBemerkung(data[0].description);
      if (cust.length>0) {
        bst.setDirektLieferung("1");
        bst.setVersandArt(cust[0].shippingtype);
        bst.setKundennummerBeimLieferanten(cust[0].value);
        komm.setKundenNummer(cust[0].value);
        komm.setNachname(cust[0].lastname);
        komm.setVorname(cust[0].firstname);
        komm.setName3(cust[0].bpname);
        komm.setOrt(cust[0].city);
        komm.setPLZ(cust[0].postal);
        komm.setStrasse(cust[0].address1);
        komm.setLand(cust[0].countrycode);
        bst.setKommission(komm);
      }
      else
        bst.setDirektLieferung("0");
      OrderlineData[] lines=OrderlineData.select(conn, porder);
      Positionen posl=new Positionen();
      Position[] posar=new Position[lines.length];
      for (int i=0;i<lines.length;i++){
        Position pos=new Position();
        pos.setArtikelnummer(lines[i].product);
        pos.setBezeichnung(lines[i].productname);
        pos.setEAN(lines[i].ean);
        pos.setEinzelpreisRabattiert(lines[i].priceactual);
        pos.setHerstellerartikelnummer(lines[i].manufacturernumber);
        pos.setMenge(lines[i].qtyordered);
        pos.setMengeneinheit(lines[i].uomname);
        pos.setPZN(lines[i].product);
        posar[i]=pos;
      }
      posl.setPosition(posar);
      bst.setPositionen(posl);
      bstar[0]=bst;
      bstl.setBestellung(bstar);
      tf.setBestellungen(bstl);
    }
    StringWriter xmlOutput = new StringWriter();
    Marshaller margie = context.createMarshaller();
    margie.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);
    margie.marshal(tf, xmlOutput);
    // Create File
    final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
    final File toDir = new File(fileDir + "/" + "sangro");
    if (!toDir.exists())
      toDir.mkdirs();
    final File sndDir = new File(fileDir + "/" + "sangro/sent");
    if (!sndDir.exists())
      sndDir.mkdirs();
    String fname="sangroOrder-" + data[0].documentno + "-" + UtilsData.getFilenameTimestamp(conn) +".xml";
    final File outputFile = new File(sndDir, fname);
    try {
      FileWriter out = new FileWriter(outputFile);
      out.write(FilePollingServiceData.textwithHtmlEscapes(conn, xmlOutput.toString()));
      out.flush();
      out.close();
      FileInputStream in = new FileInputStream(outputFile);
      // Send file via WebDav
      Sardine sardine = SardineFactory.begin();
      WebServicesData[] wsd=WebServicesData.selectShopCredentials(conn, shop);
      if (wsd.length==0) {
        in.close();
        outputFile.delete();
        throw new Exception("The shop is not defined.");
      }
      sardine.setCredentials(wsd[0].apikey,wsd[0].secret);
      sardine.put(wsd[0].url + "/an_sangro/" + fname, in);
      in.close();
      // Status Record
      OrderStatusData.insertOrderStatusNew(conn, data[0].adOrgId, shop,"n/a", data[0].documentno, porder, "ORDER FILE SENT",fname , "N");
      OrderData.InsertPoReference(conn, null, porder);
    } catch (Exception e) {
      outputFile.delete();
      throw new Exception("Exception in OrderSangro: " + e.getMessage()); 
    }
  }
  
}
