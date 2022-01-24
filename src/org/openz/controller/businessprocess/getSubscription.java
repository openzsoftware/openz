package org.openz.controller.businessprocess;


import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.DefaultOptionsData;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openz.webservice.client.statistics.GetNumUsers;

public class getSubscription implements org.openbravo.scheduling.Process {
	  private static final Logger log = Logger.getLogger(getSubscription.class);

	  public void execute(ProcessBundle bundle) throws Exception {

		  ConnectionProvider conn =null;

	    log.debug("Starting getSubscription.\n");
	    try {
	      // For Background process execution at system level
	     
	      conn =bundle.getConnection();
	      final OBError msg = new OBError();
	      int numof = GetNumUsers.checkAndGo(DefaultOptionsData.getMainOrg(conn), conn);
	      if (numof>0) {
	        msg.setType("Success");
	        msg.setMessage("@zsse_UsersSubscribed@" + Integer.toString(numof));
	      } else {
	    	  msg.setType("Warning");
		      msg.setMessage("@zsse_NoValidSubsciptionFound@");
	      }
	        msg.setTitle("Done");
	        bundle.setResult(msg);
	      
	    } catch (final Exception e) {
	      log.error(e.getMessage(), e);
	      final OBError msg = new OBError();
	      msg.setType("Error");
	      msg.setMessage(e.getMessage());
	      msg.setTitle("@DoneWithErrors@");
	      bundle.setResult(msg);
	    } finally {
	        try {
	            conn.destroy();
	          } catch(Exception ignore){
	            ignore.printStackTrace();
	          }
	    }     
	  }
}
