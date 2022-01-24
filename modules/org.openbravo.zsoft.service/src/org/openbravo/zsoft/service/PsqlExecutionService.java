/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.openbravo.zsoft.service;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.openbravo.dal.core.OBContext;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessLogger;
import org.openbravo.service.db.DalBaseProcess;
import org.quartz.JobExecutionException;

public class PsqlExecutionService extends DalBaseProcess {

  private ProcessLogger logger;

  public void doExecute(ProcessBundle bundle) throws Exception {

    logger = bundle.getLogger();

    logger.log("Starting PL/SQL Execution Service.\n");
    try {
      
        String proc = null;
        String result = null;
        ConnectionProvider connp = bundle.getConnection();
        Connection conn = connp.getConnection();
        String sql = "select procedurename from ad_process where ad_process_id = '"
            + bundle.getProcessId() + "'";
        // sql = "select 'xau' as procedurename from dual";
        Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
            ResultSet.CONCUR_READ_ONLY);
        ResultSet res = stmt.executeQuery(sql);
        if (res.first())
          proc = res.getString("procedurename");
        stmt.close();
        logger.log("Starting Procedure : " + proc + "\n");
        stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY);
        sql = "select " + proc + "() as plresult from dual";
        res = stmt.executeQuery(sql);
        if (res.first())
          result = res.getString("plresult");
        conn.close();
        logger.log(proc + " finished with:  " + result + "\n");
        logger.log("PL/SQL Execution Service. Successfully finished\n");
    } catch (Exception e) {
      // catch any possible exception and throw it as a Quartz
      // JobExecutionException
      throw new JobExecutionException(e.getMessage(), e);
    }

  }

}