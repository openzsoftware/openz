package org.openz.controller.businessprocess;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.openbravo.database.ConnectionProvider;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessLogger;
import org.openbravo.service.db.DalBaseProcess;
import org.openz.util.ProcessUtils;
import org.openz.webservice.client.statistics.CheckLicenseServiceServiceLocator;
import org.openz.webservice.client.statistics.CheckLicenseServiceSoapBindingStub;
import org.openz.webservice.client.statistics.StatisticsData;
import org.openz.webservice.client.statistics.StatisticsServiceServiceLocator;
import org.openz.webservice.client.statistics.StatisticsServiceSoapBindingStub;
import org.quartz.JobExecutionException;

public class StatisticsBG extends DalBaseProcess {

	  private ProcessLogger logger;

	  public void doExecute(ProcessBundle bundle) throws Exception {

	    logger = bundle.getLogger();
	    ConnectionProvider conn =null;
	    logger.log("Starting Statistics Service.\n");
	    try {
	    	StatisticsServiceSoapBindingStub binding;
			binding = (StatisticsServiceSoapBindingStub)
	                new StatisticsServiceServiceLocator().getStatisticsService();
			binding.setTimeout(60000);
			conn = bundle.getConnection();
			StatisticsData[] data = StatisticsData.select(conn);
			binding.insertStatistics(data[0].orgcount, data[0].orgready, data[0].facts, data[0].orders, data[0].invoices, data[0].inouts, data[0].products, data[0].projects, data[0].bpartners,data[0].crms, data[0].numofusers, data[0].anonyminstancekey);
	        logger.log("Statistics Service. Successfully finished\n");
	    } catch (Exception e) {
	      // catch any possible exception and throw it as a Quartz
	      // JobExecutionException
	      logger.log(e.getMessage());
	      throw new JobExecutionException(e.getMessage(), e);
	    } finally {
	        try {
	            conn.destroy();
	          } catch(Exception ignore){
	            ignore.printStackTrace();
	          }
	    }     

	  }

	}