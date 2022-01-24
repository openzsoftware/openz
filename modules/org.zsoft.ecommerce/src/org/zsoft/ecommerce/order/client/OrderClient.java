package org.zsoft.ecommerce.order.client;


import java.math.BigDecimal;
import java.net.URL;
import java.sql.Connection;

import java.text.SimpleDateFormat;


import org.apache.log4j.Logger;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openz.util.LocalizationUtils;
import org.zsoft.ecommerce.OrderStatusData;



public class OrderClient implements org.openbravo.scheduling.Process {
	private static final Logger log = Logger.getLogger(OrderClient.class);
	protected static String sqlDateFormat = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("dateFormat.java");
	ConnectionProvider pool;
	 public void execute(ProcessBundle bundle)   throws Exception {

		 try {
		    log.debug("Starting OrderClient.execute(..) \n");
		  
		    final OBError msg = new OBError();
		    String Lang=bundle.vars.getLanguage();
		    final String porder = (String) bundle.getParams().get("C_Order_ID");    
		    final ConnectionProvider conn =bundle.getConnection();
		    String ecomyn=OrderData.ecommerced(conn,porder);
		    Boolean ok=true;
		    if (ecomyn.equals("Y")){
	                     msg.setType("Error");
	                     msg.setMessage(LocalizationUtils.getMessageText(conn, "eorderecommerced",Lang));
	                     msg.setTitle("Error");
	                     bundle.setResult(msg);
	                     ok=false;
	                     
	            }
		    if (OrderData.selectRemoteAPI(conn,porder ).equals("SANGRO") && ok) {
		      Object obj=Class.forName("org.zsoft.ecommerce.order.client.sangro.request.OrderSangro").getConstructor().newInstance();
		      OrderClientAPIRequest or=(OrderClientAPIRequest) obj;
		      or.processOrder(porder,conn);
		      msg.setType("Success");
	              msg.setTitle("Success");
	              msg.setMessage(LocalizationUtils.getMessageText(conn, "eordercomplete",Lang));	                   
	              bundle.setResult(msg);
		    }
                    if (OrderData.selectRemoteAPI(conn,porder ).equals("ATTENDS") && ok) {
                      Object obj=Class.forName("org.zsoft.ecommerce.order.client.attends.request.OrderAttends").getConstructor().newInstance();
                      OrderClientAPIRequest or=(OrderClientAPIRequest) obj;
                      or.processOrder(porder,conn);
                      msg.setType("Success");
                      msg.setTitle("Success");
                      msg.setMessage(LocalizationUtils.getMessageText(conn, "eordercomplete",Lang));                       
                      bundle.setResult(msg);
                    }
                    if (OrderData.selectRemoteAPI(conn,porder ).equals("EMPORIUM") && ok) {
                      Object obj=Class.forName("org.zsoft.ecommerce.order.client.emporium.request.OrderEmporium").getConstructor().newInstance();
                      OrderClientAPIRequest or=(OrderClientAPIRequest) obj;
                      or.processOrder(porder,conn);
                      msg.setType("Success");
                      msg.setTitle("Success");
                      msg.setMessage(LocalizationUtils.getMessageText(conn, "eordercomplete",Lang));                       
                      bundle.setResult(msg);
                    }
		    if (OrderData.selectRemoteAPI(conn,porder ).equals("SOAP") && ok) {  
		 	 String strorg=OrderData.selectRemoteOrgID(conn, porder);//Remote ORG id
		 	 String strbPartner=OrderData.selectRemoteBPartnerID(conn, porder); // Remote BPartner ID
			 
			 //String wsuserpw="I/Np5SD5OEr5BbC3rtxm2iWMxjg=";   
		 	 String wsusername=OrderData.selectRemoteShopUserName(conn, porder);
		 	 if ( wsusername==null ||  wsusername.isEmpty())
		 	  wsusername="wsuser";
		 	 String wsuserpw=OrderData.selectWSpw(conn,wsusername);
		 	 
		 	 String urlstring=OrderData.selectUrl(conn,porder);
		 	 // Always use the newest Service, tthe naming V100 is hisorical where it all began....
			    URL url = new URL(urlstring+"/services/OrderServiceV200");
			   // URL url = new URL(OrderData.selectUrl(conn,porder));
		                 if (strorg.equals("0")){
		                     msg.setType("Error");
		                     msg.setMessage(LocalizationUtils.getMessageText(conn, "eordernoorg",Lang));
		                     msg.setTitle("Error");
		                     bundle.setResult(msg);
		                     
		                   }	    
		   if (wsuserpw==null||wsuserpw.equals("")){
	                     msg.setType("Error");
	                     msg.setMessage(LocalizationUtils.getMessageText(conn, "eorderuserpwempty",Lang));
	                     msg.setTitle("Error");
	                     bundle.setResult(msg);
	                     
	                   }
		   else{
		    // Get SQL Prepared..eorderuserpwempty
  
		    OrderServiceV100submitOrder(strorg,strbPartner,porder,wsusername,wsuserpw,url,conn);
		    msg.setType("Success");
		    msg.setTitle("Success");
		    msg.setMessage(LocalizationUtils.getMessageText(conn, "eordercomplete",Lang)+OrderData.selectporeference(conn,porder));}
		    
		    bundle.setResult(msg);
		    }
		   }finally {
			    log.debug("OrderClient.execute(..) finished\n");
			   
			   } }
  
static void OrderServiceV100getOrder(String org, String user, String pw, String orderID, URL url,Connection connection,ConnectionProvider conn, String order2) throws Exception {
	org.zsoft.ecommerce.order.client.OrderServiceV200SoapBindingStub binding;

  try {
      binding = (org.zsoft.ecommerce.order.client.OrderServiceV200SoapBindingStub)
                    new org.zsoft.ecommerce.order.client.OrderServiceV200ServiceLocator().getOrderServiceV200(url);
  
  
      binding.setTimeout(60000);
      org.zsoft.ecommerce.order.client.OrderV200 value = null;
      value = binding.getOrder(org, user, pw, orderID);
    System.out.println(value.getCOrderId());
    System.out.println(value.getDocumentno());
    OrderData.InsertPoReference(conn,value.getDocumentno(),order2); 
    String shop=OrderData.selectRemoteShopId(conn, order2);
    OrderStatusData.insertOrderStatusNew(conn, org, shop, value.getDocumentno(), value.getDocumentno(), order2, "ORDER SENT", "", "N");
    
  }
 
  catch (javax.xml.rpc.ServiceException jre) {
      if(jre.getLinkedCause()!=null)
          jre.getLinkedCause().printStackTrace();

  } 
}
  static void OrderServiceV100submitOrder(String org,String strbPartner, String order, String user, String pw, URL url,ConnectionProvider conn) throws Exception {
		org.zsoft.ecommerce.order.client.OrderServiceV200SoapBindingStub binding;
	  final Logger log4j = Logger.getLogger(OrderClient.class);
	  Connection trnscon=conn.getTransactionConnection();
	  
	  try {
	      binding = (org.zsoft.ecommerce.order.client.OrderServiceV200SoapBindingStub)
	                    new org.zsoft.ecommerce.order.client.OrderServiceV200ServiceLocator().getOrderServiceV200(url);
	  
	      binding.setTimeout(60000);
	      OrderV200 order2submit = new OrderV200();
	      SimpleDateFormat sdf= new SimpleDateFormat(sqlDateFormat);
	      // Hier Order Objekt füllen
              try {

                  OrderData[] data = OrderData.select(conn, order);
                  if (data.length > 0) {
                	  order2submit.setCOrderId(data[0].cOrderId);
                	  order2submit.setDocumentno(data[0].documentno);
                	  //order2submit.setDocumentno("101010101");
                	  order2submit.setDocstatus(data[0].docstatus);
                	  order2submit.setIsdelivered(data[0].isdelivered);
                	  order2submit.setIsinvoiced(data[0].isinvoiced);
                	  //order2submit.setCBpartnerId(data[0].cBpartnerId);
                	  order2submit.setCBpartnerId(strbPartner);
                	  //order2submit.setCBpartnerLocationId(data[0].cBpartnerLocationId);
                	 // order2submit.setCBpartnerLocationId("1FD0EF505E864633A507E842CEDCEC0D");
                	  //order2submit.setPaymentrule(data[0].paymentrule);
                	  order2submit.setPaymentrule("Invoice");
                	  order2submit.setDeliveryviarule(data[0].deliveryviarule);
                    // Get the lines
                    OrderlineData[] data2 = OrderlineData.select(conn,  order);
                    OrderlineV200[] orderlines = new OrderlineV200[data2.length];
                    for (int i = 0; i < orderlines.length; i++) {
                      orderlines[i] = new OrderlineV200();
                      orderlines[i].setCOrderlineId(data2[i].cOrderlineId);
                      orderlines[i].setCOrderId(data2[i].cOrderId);
                      orderlines[i].setLine(new BigDecimal(data2[i].line));
                      if (!data2[i].datepromised.equals(""))
                           orderlines[i].setDatepromised(sdf.parse(data2[i].datepromised));
                      if (!data2[i].datedelivered.equals(""))
                           orderlines[i].setDatedelivered(sdf.parse(data2[i].datedelivered));
                      if (!data2[i].dateinvoiced.equals(""))
                           orderlines[i].setDateinvoiced(sdf.parse(data2[i].dateinvoiced));
                      orderlines[i].setDescription(data2[i].description);
                     orderlines[i].setMProductId(data2[i].product);
                      orderlines[i].setQtyordered(new BigDecimal(data2[i].qtyordered));
                      orderlines[i].setQtydelivered(new BigDecimal(data2[i].qtydelivered));
                      orderlines[i].setQtyinvoiced(new BigDecimal(data2[i].qtyinvoiced));
                      orderlines[i].setPriceactual(new BigDecimal(data2[i].priceactual));
                      orderlines[i].setMAttributesetinstanceId(data2[i].mAttributesetinstanceId);
                    }
                    order2submit.setOrderlines(orderlines);
                  }  
                
              
              } catch (Exception e) {
                  log4j.error(e.getMessage());
                  throw new Exception("Exception in Webservice: " + e.getMessage()); 
                } finally {
                	if (log4j.isDebugEnabled())
                	      log4j.debug("destroy");
                	  
                }   
  
	      OrderResponse value ;
	            
	      // Und Tschüss!    
	      
              value = binding.submitOrder(org, user, pw, order2submit);
                     
          //    System.out.println(value.getCOrderId());	
              OrderServiceV100getOrder(org,user,pw,value.getCOrderId(),url,trnscon,conn,order);
            
	  }
	  catch (javax.xml.rpc.ServiceException jre) {
	      if(jre.getLinkedCause()!=null)
	          jre.getLinkedCause().printStackTrace();}

	  }}

		
		    
		    
		  
		

  // Time out after a minute


  // Test operation
  
  
  // TBD - validate results

