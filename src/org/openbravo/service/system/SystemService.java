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

package org.openbravo.service.system;

import java.util.Date;
import java.util.List;

import org.apache.ddlutils.model.Database;
import org.apache.log4j.Logger;
import org.hibernate.criterion.Expression;
import org.openbravo.base.model.Entity;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.model.Property;
import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.provider.OBSingleton;
import org.openbravo.base.structure.BaseOBObject;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.core.SessionHandler;
import org.openbravo.dal.core.TriggerHandler;
import org.openbravo.dal.service.OBCriteria;
import org.openbravo.dal.service.OBDal;
import org.openbravo.model.ad.module.Module;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.ad.system.ClientInformation;
import org.openbravo.model.common.enterprise.Organization;
import org.openbravo.service.system.SystemValidationResult.SystemValidationType;

/**
 * Provides utility like services.
 * 
 * @author Martin Taal
 */
public class SystemService implements OBSingleton {
  private static SystemService instance;

  public static synchronized SystemService getInstance() {
    if (instance == null) {
      instance = OBProvider.getInstance().get(SystemService.class);
    }
    return instance;
  }

  public static synchronized void setInstance(SystemService instance) {
    SystemService.instance = instance;
  }

  /**
   * Returns true if for a certain class there are objects which have changed.
   * 
   * @param clzs
   *          the type of objects which are checked
   * @param afterDate
   *          the timestamp to check
   * @return true if there is an object in the database which changed since afterDate, false
   *         otherwise
   */
  public boolean hasChanged(Class<?>[] clzs, Date afterDate) {
    for (Class<?> clz : clzs) {
      @SuppressWarnings("unchecked")
      final OBCriteria<?> obc = OBDal.getInstance().createCriteria((Class<BaseOBObject>) clz);
      obc.add(Expression.gt(Organization.PROPERTY_UPDATED, afterDate));
      // todo: count is slower than exists, is exists possible?
      if (obc.count() > 0) {
        return true;
      }
    }
    return false;
  }

  /**
   * Validates a specific module, checks the javapackage, dependency on core etc. The database
   * changes of the module are not checked. This is a separate task.
   * 
   * @param module
   *          the module to validate
   * @param database
   *          the database to read the dbschema from
   * @return the validation result
   */
  public SystemValidationResult validateModule(Module module, Database database) {
    final ModuleValidator moduleValidator = new ModuleValidator();
    moduleValidator.setValidateModule(module);
    return moduleValidator.validate();
  }

  /**
   * Validates the database for a specific module.
   * 
   * @param module
   *          the module to validate
   * @param database
   *          the database to read the dbschema from
   * @return the validation result
   */
  public SystemValidationResult validateDatabase(Module module, Database database) {
    final DatabaseValidator databaseValidator = new DatabaseValidator();
    databaseValidator.setValidateModule(module);
    databaseValidator.setDatabase(database);
    databaseValidator.setDbsmExecution(true);
    return databaseValidator.validate();
  }

  /**
   * Prints the validation result grouped by validation type to the log.
   * 
   * @param log
   *          the log to which the validation result is printed
   * @param result
   *          the validation result containing both errors and warning
   * @return the errors are returned as a string
   */
  public String logValidationResult(Logger log, SystemValidationResult result) {
    for (SystemValidationType validationType : result.getWarnings().keySet()) {
      log.warn("\n");
      log.warn("+++++++++++++++++++++++++++++++++++++++++++++++++++");
      log.warn("Warnings for Validation type: " + validationType);
      log.warn("+++++++++++++++++++++++++++++++++++++++++++++++++++");
      final List<String> warnings = result.getWarnings().get(validationType);
      for (String warning : warnings) {
        log.warn(warning);
      }
    }

    final StringBuilder sb = new StringBuilder();
    for (SystemValidationType validationType : result.getErrors().keySet()) {
      sb.append("\n");
      sb.append("\n+++++++++++++++++++++++++++++++++++++++++++++++++++");
      sb.append("\nErrors for Validation type: " + validationType);
      sb.append("\n+++++++++++++++++++++++++++++++++++++++++++++++++++");
      final List<String> errors = result.getErrors().get(validationType);
      for (String err : errors) {
        sb.append("\n");
        sb.append(err);
      }
    }
    log.error(sb.toString());
    return sb.toString();
  }

  /**
   * Removes all data of a specific {@link Client}, the client is identified by the clientId
   * parameter.
   * 
   * NOTE: this method does not work yet. It is an initial implementation and not yet complete
   * 
   * @param clientId
   *          the id of the client to delete.
   * @deprecated Do not use, is a work in progress
   */
   @Deprecated
  public void removeAllClientData(String clientId) {
    // the idea was/is the following:
    // 0) compute the order of all entities based on their reference, something like the
    // low-level code in BOM computations: the entity nobody refers to has number 0, the
    // rule is that if there are two entities A and B and there is a reference path from A
    // to B (directly or through other entities) using only non-mandatory many-to-one references
    // then: A.referenceNumber < B.referenceNumber
    // Then the entities can be sorted ascending on the referenceNumber
    // the procedure is then:
    // 1) nullify all non-mandatory many-to-ones
    // 2) then remove the objects in order of the entity.referenceNumber
    // currently this does not work yet because step 1 fails because there are constraints
    // defined in the database which means that certain fields are conditionally mandatory.

    final boolean prevMode = OBContext.getOBContext().setInAdministratorMode(true);
    try {
      TriggerHandler.getInstance().disable();
      final Client client = OBDal.getInstance().get(Client.class, clientId);
      for (Entity e : ModelProvider.getInstance().getModel()) {
        if (!e.isClientEnabled()) {
          continue;
        }
        nullifyManyToOnes(e, client);
      }
      OBDal.getInstance().flush();

      for (Entity e : ModelProvider.getInstance().getModel()) {
        if (!e.isClientEnabled()) {
          continue;
        }
        final String hql;
        if (e.getName().equals(ClientInformation.ENTITY_NAME)) {
          hql = "delete " + e.getName() + " where id=:clientId";
        } else {
          hql = "delete " + e.getName() + " where client=:clientId";
        }
        SessionHandler.getInstance().getSession().createQuery(hql).setString("clientId", clientId)
            .executeUpdate();
      }
      OBDal.getInstance().flush();
      TriggerHandler.getInstance().enable();
      OBDal.getInstance().commitAndClose();
    } finally {
      OBContext.getOBContext().setInAdministratorMode(prevMode);
    }
  }

  private void nullifyManyToOnes(Entity e, Client client) {
    final String updatePart = createNullifyNonMandatoryQuery(e);
    if (updatePart == null) {
      return;
    }
    final String hql;
    if (e.getName().equals(ClientInformation.ENTITY_NAME)) {
      hql = updatePart + " where id=:clientId";
    } else {
      hql = updatePart + " where client=:clientId";
    }
    try {
      SessionHandler.getInstance().getSession().createQuery(hql).setString("clientId",
          client.getId()).executeUpdate();
    } catch (IllegalArgumentException ex) {
      // handle a special case, that the entity name or a property name
      // is a reserved hql word.
      if (ex.getMessage().indexOf("node to traverse cannot be null") != -1) {
        // in this case use an inefficient method
        nullifyPerObject(e, client);
      } else {
        throw ex;
      }
    }
  }

  private String createNullifyNonMandatoryQuery(Entity e) {
    final StringBuilder sb = new StringBuilder("update " + e.getClassName() + " e set ");
    boolean doNullifyProperty = false;
    for (Property p : e.getProperties()) {
      if (!p.isPrimitive() && !p.isOneToMany() && !p.isMandatory()) {
        if (doNullifyProperty) {
          sb.append(", ");
        }
        sb.append("e." + p.getName() + " = null");
        doNullifyProperty = true;
      }
    }
    // no property found, don't do update
    if (!doNullifyProperty) {
      return null;
    }
    return sb.toString();
  }

  private void nullifyPerObject(Entity e, Client client) {
    final OBCriteria<BaseOBObject> obc = OBDal.getInstance().createCriteria(e.getName());
    obc.setFilterOnActive(false);
    obc.setFilterOnReadableClients(false);
    obc.setFilterOnReadableOrganization(false);
    obc.add(Expression.eq(Organization.PROPERTY_CLIENT, client));
    for (BaseOBObject bob : obc.list()) {
      for (Property p : e.getProperties()) {
        if (!p.isPrimitive() && !p.isOneToMany() && !p.isMandatory()) {
          bob.set(p.getName(), null);
        }
      }
    }
  }
}
