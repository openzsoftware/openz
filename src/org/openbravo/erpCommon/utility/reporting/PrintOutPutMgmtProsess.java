package org.openbravo.erpCommon.utility.reporting;

import javax.mail.MessagingException;

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.reporting.printing.OutPutMgmtPrintController;
import org.openbravo.scheduling.Process;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessLogger;
import org.quartz.JobExecutionException;
import org.openbravo.erpCommon.utility.reporting.printing.EmailData;

public class PrintOutPutMgmtProsess implements Process {



	  private static int counter = 1;

	  private ConnectionProvider connection;
	  private ProcessLogger logger;
	  private String basepath;

	  public void execute(ProcessBundle bundle) throws Exception {

	    logger = bundle.getLogger();
	    connection = bundle.getConnection();
	    basepath=bundle.getConfig().prefix;
	    String sessionValuePrefix;
	    VariablesSecureApp vars=bundle.vars;

	    try {
	    	logger.log("Starting PrintOutPutMgmt Backgrouond Process. Loop Orders\n");
	    	OutPutMgmtData[] data=OutPutMgmtData.getOrderInfo(connection);
	    	sessionValuePrefix="PRINTORDERS";
	    	DocumentType documentType = new DocumentType("ORDER","C_ORDER","orders/",null,true,null,"c_getDefaultDocInfo");
	    	for(int i=0;i<data.length;i++) {
	    		OutPutMgmtPrintController prt = new OutPutMgmtPrintController();
	    		final String senderAddress = EmailData.getSenderAddress(connection, vars.getClient(),data[i].adOrgId);
	    		if ("".equals(senderAddress) || senderAddress == null) {
	    			logger.log("ERROR: No sender defined: Please go to client configuration to complete the email configuration\n");
	    		} else {
	    			try {
	    				prt.process(vars, connection,documentType, sessionValuePrefix, data[i].documentId,basepath,data[i].documentbyemail,data[i].cDoctypeId,data[i].adOrgId);
	    				OutPutMgmtData.updateOrderInfo(connection, data[i].documentId);
	    				logger.log("Order processed: " +data[i].ourreference +"\n");
	    			}
	    			catch (final MessagingException exception) {
	    				logger.log("Problems sending EMail: "+data[i].ourreference +":" + exception.getMessage() +"\n");
	    			    }
	    		}
	    	}
	    	logger.log("PrintOutPutMgmt Backgrouond Process finished.");
	    } catch (Exception e) {
	      logger.log("Error:" + e.getMessage());
	      throw new JobExecutionException(e.getMessage(), e);
	    }
	    finally {connection.destroy();}
	  }
}