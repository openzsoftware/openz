package org.openz.controller.businessprocess;

import org.openbravo.base.secureApp.DefaultOptionsData;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessLogger;
import org.openbravo.service.db.DalBaseProcess;
import org.openz.util.ProcessUtils;
import org.openz.webservice.client.statistics.GetNumUsers;
import org.quartz.JobExecutionException;

public class getSubscriptionBG extends DalBaseProcess {

	  private ProcessLogger logger;

	  public void doExecute(ProcessBundle bundle) throws Exception {

	    logger = bundle.getLogger();
	    ConnectionProvider conn =null;
	    logger.log("Starting getSubscriptionBG.\n");
	    try {
	    	conn =bundle.getConnection();
		    int numof = GetNumUsers.checkAndGo(DefaultOptionsData.getMainOrg(conn), conn);
	        
	        logger.log("getSubscriptionBG. Successfully finished\n");
	    } catch (Exception e) {
	      // catch any possible exception and throw it as a Quartz
	      // JobExecutionException
	      logger.log(e.getMessage());
	      throw new JobExecutionException(e.getMessage(), e);
	    }finally {
	        try {
	            conn.destroy();
	          } catch(Exception ignore){
	            ignore.printStackTrace();
	          }
	    }
	  }

	}