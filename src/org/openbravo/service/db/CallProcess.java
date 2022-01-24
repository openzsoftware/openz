/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html 
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License. 
 * The Original Code is Openbravo ERP. 
 * The Initial Developer of the Original Code is Openbravo SL 
 * All portions are Copyright (C) 2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.service.db;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.Map;
import java.util.Properties;

import org.hibernate.criterion.Expression;
import org.openbravo.base.exception.OBException;
import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.service.OBCriteria;
import org.openbravo.dal.service.OBDal;
import org.openbravo.model.ad.process.Parameter;
import org.openbravo.model.ad.process.ProcessInstance;

/**
 * This class is a service class to call a stored procedure using a set of parameters.
 * 
 * The {@link ProcessInstance} result is returned.
 * 
 * @see ProcessInstance
 * @see org.openbravo.model.ad.ui.Process
 * @see Parameter
 * 
 * @author mtaal
 */
public class CallProcess {

  private static CallProcess instance = new CallProcess();

  public static synchronized CallProcess getInstance() {
    return instance;
  }

  public static synchronized void setInstance(CallProcess instance) {
    CallProcess.instance = instance;
  }

  /**
   * Calls a process with the specified name. The recordID and parameters can be null. Parameters
   * are translated into {@link Parameter} instances.
   * 
   * @param processName
   *          the name of the stored procedure, must exist in the database, see
   *          {@link org.openbravo.model.ad.ui.Process#getProcedure()}.
   * @param recordID
   *          the recordID will be set in the {@link ProcessInstance}, see
   *          {@link ProcessInstance#getRecordID()}
   * @param parameters
   *          are translated into process parameters
   * @return the created instance with the result ({@link ProcessInstance#getResult()}) or error (
   *         {@link ProcessInstance#getErrorMsg()})
   */
  public ProcessInstance call(String processName, String recordID, Map<String, String> parameters) {
    final OBCriteria<org.openbravo.model.ad.ui.Process> processCriteria = OBDal.getInstance()
        .createCriteria(org.openbravo.model.ad.ui.Process.class);
    processCriteria.add(Expression.eq(org.openbravo.model.ad.ui.Process.PROPERTY_PROCEDURENAME,
        processName));
    if (processCriteria.list().size() != 1) {
      throw new OBException("No process or more than one process found using procedurename "
          + processName);

    }
    return call(processCriteria.list().get(0), recordID, parameters);
  }

  /**
   * Calls a process. The recordID and parameters can be null. Parameters are translated into
   * {@link Parameter} instances.
   * 
   * @param process
   *          the process to execute
   * @param recordID
   *          the recordID will be set in the {@link ProcessInstance}, see
   *          {@link ProcessInstance#getRecordID()}
   * @param parameters
   *          are translated into process parameters
   * @return the created instance with the result ({@link ProcessInstance#getResult()}) or error (
   *         {@link ProcessInstance#getErrorMsg()})
   */
  public ProcessInstance call(org.openbravo.model.ad.ui.Process process, String recordID,
      Map<String, String> parameters) {

    final boolean currentAdminMode = OBContext.getOBContext().setInAdministratorMode(true);
    try {
      // Create the pInstance
      final ProcessInstance pInstance = OBProvider.getInstance().get(ProcessInstance.class);
      // sets its process
      pInstance.setProcess(process);
      // must be set to true
      pInstance.setActive(true);
      if (recordID != null) {
        pInstance.setRecord(recordID);
      } else {
        pInstance.setRecord("0");
      }

      // get the user from the context
      pInstance.setUser(OBContext.getOBContext().getUser());

      // now create the parameters and set their values
      if (parameters != null) {
        int index = 0;
        for (String key : parameters.keySet()) {
          index++;
          final String value = parameters.get(key);
          final Parameter parameter = OBProvider.getInstance().get(Parameter.class);
          parameter.setSeqNo(index + "");
          parameter.setParameterName(key);
          parameter.setString(value);

          // set both sides of the bidirectional association
          pInstance.getADParameterList().add(parameter);
          parameter.setPInstance(pInstance);
        }
      }

      // persist to the db
      OBDal.getInstance().save(pInstance);

      // flush, this gives pInstance an ID
      OBDal.getInstance().flush();

      // call the SP
      try {
        // first get a connection
        final Connection connection = OBDal.getInstance().getConnection();
        // connection.createStatement().execute("CALL M_InOut_Create0(?)");

        final Properties obProps = OBPropertiesProvider.getInstance().getOpenbravoProperties();
        final PreparedStatement ps;
        if (obProps.getProperty("bbdd.rdbms") != null
            && obProps.getProperty("bbdd.rdbms").equals("POSTGRE")) {
          ps = connection.prepareStatement("SELECT * FROM " + process.getProcedureName() + "(?)");
        } else {
          ps = connection.prepareStatement(" CALL " + process.getProcedureName() + "(?)");
        }

        ps.setString(1, pInstance.getId());
        ps.execute();
      } catch (Exception e) {
        throw new IllegalStateException(e);
      }

      // refresh the pInstance as the SP has changed it
      OBDal.getInstance().getSession().refresh(pInstance);
      return pInstance;
    } finally {
      OBContext.getOBContext().setInAdministratorMode(currentAdminMode);
    }
  }
}
