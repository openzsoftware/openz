package org.zsoft.ecommerce.logistic;

import java.math.BigDecimal;
import java.net.URL;
import java.sql.Connection;
import java.sql.Date;
import java.text.SimpleDateFormat;


import org.apache.log4j.Logger;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openz.util.LocalizationUtils;
import org.zsoft.ecommerce.order.client.OrderClientAPIRequest;




public class LogisticClient implements org.openbravo.scheduling.Process {
        private static final Logger log = Logger.getLogger(LogisticClient.class);
        protected static String sqlDateFormat = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("dateFormat.java");
        ConnectionProvider pool;
         public void execute(ProcessBundle bundle)   throws Exception {

                 try {
                    log.debug("Starting LogisticClient.execute(..) \n");
                  
                    final OBError msg = new OBError();
                    final String mInout = (String) bundle.getParams().get("M_InOut_ID");    
                    final ConnectionProvider conn =bundle.getConnection();
                    
                    final String baseurl = bundle.baseurl;
                    Boolean ok=true;

//Which Apo 
                    if (LogisticData.selectRemoteAPI(conn,mInout ).equals("DPD") && ok) {  
                                               
                         Object obj=Class.forName("org.openz.apis.logistic.dpd.DPDOrderClient").getConstructor().newInstance();
                         LogisticClientAPIRequest or=(LogisticClientAPIRequest) obj;
                           
                           or.processInOut(mInout,conn);
                     String filename=mInout+".pdf";
                     
                     
                     String href = baseurl + "/utility/DownloadFile.html?dfile=" + filename + "&fdir=/GoodsMovementCustomer";
                     String link = "<a class=\"Labellink\" href=\"" + href + "\">hier klicken</a>";
                     
                     msg.setMessage("<br/>DPD - Label " + "/tmp/" + filename + " erstellt. Bitte " + link);
                     msg.setTitle("DPD - Label");
                     msg.setType("Success");
                     bundle.setResult(msg);}
                   }finally {
                     log.debug("LogisticClient.execute(..) finished\n");}
                 }
         }
        

