package org.zsoft.ecommerce.order.client.emporium.request;

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
import org.zsoft.ecommerce.order.client.SenderData;
import org.zsoft.ecommerce.order.client.attends.request.Position;
import org.zsoft.ecommerce.order.client.sangro.request.Positionen;
import org.zsoft.ecommerce.order.client.sangro.request.TransferFile;

import com.github.sardine.Sardine;
import com.github.sardine.impl.SardineImpl;

public class OrderEmporium implements OrderClientAPIRequest{
	  
	  public void processOrder(String porder, ConnectionProvider conn) throws Exception {
	    
	    String shop=OrderData.selectRemoteShopId(conn, porder);  
	    OrderData[] data = OrderData.select(conn, porder);
	    SenderData[] Senderdata = SenderData.select(conn, porder);
	    String dropship=OrderData.selectDropShipCustomerOrder(conn, porder);
	    JAXBContext context = JAXBContext.newInstance(Htgaovorder.class);
	    Htgaovorder htga=new Htgaovorder();
	    
	    
	    
	    if (data.length > 0 ) { 
	      //Order Header EMPORIUM
	    	OrderEntry oe = new OrderEntry();       
        	      oe.setRecord_type1("00");
        	      oe.setSource(Senderdata[0].name); //Fixed | customer name
        	      oe.setBoeker("STP"); // internal boeker code 
        	      oe.setKenmerk(data[0].documentno);//Dynamic field | your order number
        	      oe.setControle_code("CUS_"+data[0].documentno);//Dynamic field | starting with three letters and an underscore (e.g. CUS_) followed by your order number
        	      oe.setRecord_type2("10");
                      oe.setDocument_type("V");//Fixed
                      oe.setHaal_breng("B");//Fixed
                      oe.setHb_datum(data[0].dorder);//Dynamic field | Order | Date of order (DDMMYYYY)
                      oe.setHb_tijd(data[0].torder);//Dynamic field | Order | Time of order (HHMM)
                      oe.setBudu("");//Internal BUDU code
                      oe.setCompany_id(Senderdata[0].value);//Internal company code
                      oe.setExterne_reeks("");//Leave this field empty if not discussed/agreed
                      oe.setKlantnummer("Klantnummer");//Internal customer code
                      oe.setDiverse_jn_velden("Diverses");//Field is mandatory, but the content is optional (usually left blank)
                      
                      
               //Order Relatie EMPORIUM
	        Htgaovrelatie hr=new Htgaovrelatie();
	        CustomerData[] delivery = CustomerData.select(conn, porder);
	        CustomerData[] invoice = CustomerData.selectinvoicedata(conn, porder);
	        if (delivery.length > 0 ) { 
	          if (invoice.length > 0 ) {
	              hr.setOrdernr(data[0].documentno);//Dynamic field | same order number as in row 7 
	              hr.setOrder_barcode("");
	              hr.setNaam(delivery[0].bpname);//Fixed | Headquarters | name of the business partner
	              hr.setNaam_2("");//Fixed | Headquarters | field is mandatory, but the content is optional (usually left blank)
	              hr.setStraat(delivery[0].address1);//Fixed | Headquarters | address of the business partner
	              hr.setPostcode(delivery[0].postal);//Fixed | Headquarters | postal code of the business partner
	              hr.setPlaats(delivery[0].city);//Fixed | Headquarters | city of the business partner
	              hr.setValuta("EUR");//Fixed | Currency | standard EUR
	              hr.setLandcode(delivery[0].country);//Fixed | Headquarters | country code (DE = Germany)
	              hr.setBetalingsconditie("D14");//
	              hr.setTelefoonnummer(delivery[0].phone);//Fixed | Commerce | phone number for inquiries
	              hr.setEmail(delivery[0].email);//Fixed | Commerce | e-mail address for inquiries
	              hr.setF_naam(invoice[0].bpname);//Fixed | Invoice | invoice company name
	              hr.setF_naam_2("");//Fixed | Invoice | field is mandatory, but the content is optional. E.g. 'Attn. Finance department'
	              hr.setF_straat(invoice[0].address1);//Fixed | Invoice | address
	              hr.setF_postcode(invoice[0].postal);// Fixed | Invoice | postal code
	              hr.setF_plaats(invoice[0].city);//Fixed | Invoice | city
	              hr.setF_landcode(invoice[0].country);//Fixed | Invoice | country code (DE = Germany)
	              hr.setDummy("");//
	              hr.setA_naam(delivery[0].bpname);//Dynamic field | Consumer | Name
	              hr.setA_naam_2("");//Dynamic field | Consumer | (content is optional) e.g. Attn.
	              hr.setA_straat(delivery[0].address1);// Dynamic field | Consumer | Address for delivery
	              hr.setA_postcode(delivery[0].postal);//Dynamic field | Consumer | Postal code for delivery
	              hr.setA_plaats(delivery[0].city);//Dynamic field | Consumer | City for delivery
	              hr.setA_landcode(delivery[0].country);//Dynamic field | Consumer | Country code for delivery (DE = Germany) 
	              hr.setServicepunt_code("servicepunt");//
	        }}
	             //Orderregel
	              OrderlineData[] lines=OrderlineData.select(conn, porder);
                      OrderlinesEmporium ole = new OrderlinesEmporium();
                      Htgaovorderregel[] horar = new Htgaovorderregel[lines.length];
                      Htgaovorderregel hor = new Htgaovorderregel();
	              for (int i=0;i<lines.length;i++){
	                 hor = new Htgaovorderregel();
	              hor.setRecord_type("");//Field is mandatory, but the content is optional (usually left blank)
	              hor.setProductnummer(lines[i].product);//Dynamic field | Order | Product number as presented in stock-list
	              hor.setPartijnummer("");//Leave this field empty if not discussed/agreed
	              hor.setAantal_besteld(lines[i].qtyordered);//Dynamic field | Order | Quantity
	              hor.setExtern_productnummer("");//Leave this field empty if not discussed/agreed
	              hor.setMagazijn("");//Leave this field empty if not discussed/agreed
	              hor.setValuta("EUR");//Currency, default is EUR
	              horar[i]=hor;
              
	      }
	              
                      ole.setHtgaovorderregel(horar);
                      oe.setHtgaovrelatie(hr);
                      oe.setOrderlines(ole);
	              htga.setOrder(oe);
	                     
	              

	    }
	    StringWriter xmlOutput = new StringWriter();
	    Marshaller margie = context.createMarshaller();
	    margie.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);
	    //margie.setProperty(Marshaller.JAXB_ENCODING, "ISO-8859-15");
	    margie.marshal(htga, xmlOutput);
	    // Create File
	    final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
	    final File toDir = new File(fileDir + "/" + "emporium");
	    if (!toDir.exists())
	      toDir.mkdirs();
	    final File sndDir = new File(fileDir + "/" + "emporium/sent");
	    if (!sndDir.exists())
	      sndDir.mkdirs();
	    String fname="emporiumOrder-" + data[0].documentno + "-" + UtilsData.getFilenameTimestamp(conn) +".xml";
	    final File outputFile = new File(sndDir, fname);
	    try {
	      FileWriter out = new FileWriter(outputFile);
	      out.write(xmlOutput.toString());
	      out.flush();
	      out.close();
	      FileInputStream in = new FileInputStream(outputFile);
	      // Send file via WebDav
	     // Sardine sardine = SardineFactory.begin();
	      
	      String deployDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("tomcat.path");
	      String  keyStoreFilename = "";
	      if (deployDir.equals("xxx")) {
	        deployDir= System.getenv("OPENZ_GITOSS") ;
	        keyStoreFilename = deployDir + "/modules/org.openz.xmlapi/src/org/openz/xmlapi/transfair.jks";
	      }
	      else
	        keyStoreFilename = deployDir + "/modules/org.openz.xmlapi/src/org/openz/xmlapi/transfair.jks";
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
	        //outputFile.delete();
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
	      //outputFile.delete();
	      throw new Exception("Exception in Order Emporium: " + e.getMessage()); 
	    }
	  }

}
