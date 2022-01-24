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
 * All portions are Copyright (C) 2008 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.dal.service;

import java.sql.Connection;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;
import org.hibernate.Session;
import org.hibernate.criterion.Expression;
import org.hibernate.engine.SessionImplementor;
import org.openbravo.base.model.Entity;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.model.Property;
import org.openbravo.base.model.UniqueConstraint;
import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.provider.OBSingleton;
import org.openbravo.base.structure.BaseOBObject;
import org.openbravo.base.structure.ClientEnabled;
import org.openbravo.base.structure.OrganizationEnabled;
import org.openbravo.dal.core.DalUtil;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.core.SessionHandler;
import org.openbravo.dal.security.SecurityChecker;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.common.enterprise.Organization;

/**
 * The OBDal class offers the main external access to the Data Access Layer. The variety of data
 * access methods are provided such as save, get, query, remove, etc.
 * 
 * @see OBCriteria
 * @see OBQuery
 * 
 * @author mtaal
 */
// TODO: add methods to return a sorted list based on the identifier of an
// object
// TODO: re-check singleton pattern when a new factory/dependency injection
// approach is implemented.
public class OBDal implements OBSingleton {
  private static final Logger log = Logger.getLogger(OBDal.class);

  private static OBDal instance;

  /**
   * @return the singleton instance of the OBDal service
   */
  public static OBDal getInstance() {
    if (instance == null) {
      instance = OBProvider.getInstance().get(OBDal.class);
    }
    return instance;
  }

  /**
   * Returns the connection used by the hibernate session.
   * 
   * Note: flushes the hibernate session before returning the connection.
   * 
   * @return the current database connection
   * @see #flush()
   */
  public Connection getConnection() {
    // before returning a connection always flush all other hibernate actions
    // to the database.
    flush();
    return ((SessionImplementor) SessionHandler.getInstance().getSession()).connection();
  }

  /**
   * @return the current hibernate session
   */
  public Session getSession() {
    return SessionHandler.getInstance().getSession();
  }

  /**
   * Commits the transaction and closes session.
   */
  public void commitAndClose() {
    if (SessionHandler.isSessionHandlerPresent()) {
      SessionHandler.getInstance().commitAndClose();
    }
  }

  /**
   * Rolls back the transaction and closes the session.
   */
  public void rollbackAndClose() {
    SessionHandler.getInstance().rollback();
  }

  /**
   * Flushes the current state to the database.
   */
  public void flush() {
    SessionHandler.getInstance().getSession().flush();
  }

  /**
   * Sets the client and organization of the object (if not set) and persists the object in the
   * database.
   * 
   * @param obj
   *          the object to persist
   */
  public void save(Object obj) {
    // set client organization has to be done here before checking write
    // access
    // not the most nice to do
    // TODO: add checking if setClientOrganization is really necessary
    // TODO: log using entityName
    log.debug("Saving object " + obj.getClass().getName());
    setClientOrganization(obj);
    if (!OBContext.getOBContext().isInAdministratorMode()) {
      if (obj instanceof BaseOBObject) {
        OBContext.getOBContext().getEntityAccessChecker().checkWritable(
            ((BaseOBObject) obj).getEntity());
      }
      SecurityChecker.getInstance().checkWriteAccess(obj);
    }
    SessionHandler.getInstance().save(obj);
  }

  /**
   * Removes the object from the database.
   * 
   * @param obj
   *          the object to be removed
   */
  public void remove(Object obj) {
    // TODO: add checking if setClientOrganization is really necessary
    // TODO: log using entityName
    log.debug("Removing object " + obj.getClass().getName());
    SecurityChecker.getInstance().checkDeleteAllowed(obj);
    SessionHandler.getInstance().delete(obj);
  }

  /**
   * Retrieves an object from the database using the class and id.
   * 
   * @param clazz
   *          the type of object to search for
   * @param id
   *          the id of the object
   * @return the object, or null if none found
   */
  public <T extends Object> T get(Class<T> clazz, Object id) {
    checkReadAccess(clazz);
    return SessionHandler.getInstance().find(clazz, id);
  }

  /**
   * Returns true if an object (identified by the entityName and id) exists, false otherwise.
   * 
   * @param entityName
   *          the name of the entity
   * @param id
   *          the id used to find the instance
   * @return true if exists, false otherwise
   */
  public boolean exists(String entityName, Object id) {
    return null != SessionHandler.getInstance().find(entityName, id);
  }

  /**
   * Retrieves an object from the database using the entity name and id.
   * 
   * @param entityName
   *          the type of object to search for
   * @param id
   *          the id of the object
   * @return the object, or null if none found
   */
  public BaseOBObject get(String entityName, Object id) {
    checkReadAccess(entityName);
    return SessionHandler.getInstance().find(entityName, id);
  }

  /**
   * Create a OBQuery object using a class and a specific where and order by clause.
   * 
   * @param fromClz
   *          the class to create the query for
   * @param whereOrderByClause
   *          the HQL where and orderby clause
   * @return the query object
   */
  public <T extends BaseOBObject> OBQuery<T> createQuery(Class<T> fromClz, String whereOrderByClause) {
    return createQuery(fromClz, whereOrderByClause, new ArrayList<Object>());
  }

  /**
   * Create a OBQuery object using a class and a specific where and order by clause and a set of
   * parameters which are used in the query.
   * 
   * @param fromClz
   *          the class to create the query for
   * @param whereOrderByClause
   *          the HQL where and orderby clause
   * @param parameters
   *          the parameters to use in the query
   * @return the query object
   */
  public <T extends BaseOBObject> OBQuery<T> createQuery(Class<T> fromClz,
      String whereOrderByClause, List<Object> parameters) {
    checkReadAccess(fromClz);
    final OBQuery<T> obQuery = new OBQuery<T>();
    obQuery.setWhereAndOrderBy(whereOrderByClause);
    obQuery.setEntity(ModelProvider.getInstance().getEntity(fromClz));
    obQuery.setParameters(parameters);
    return obQuery;
  }

  /**
   * Create a OBQuery object using an entity name and a specific where and order by clause.
   * 
   * @param entityName
   *          the type to create the query for
   * @param whereOrderByClause
   *          the HQL where and orderby clause
   * @return the new query object
   */
  public OBQuery<BaseOBObject> createQuery(String entityName, String whereOrderByClause) {
    return createQuery(entityName, whereOrderByClause, new ArrayList<Object>());
  }

  /**
   * Create a OBQuery object using an entity name and a specific where and order by clause and a set
   * of parameters which are used in the query.
   * 
   * @param entityName
   *          the type to create the query for
   * @param whereOrderByClause
   *          the HQL where and orderby clause
   * @param parameters
   *          the parameters to use in the query
   * @return a new instance of {@link OBQuery}.
   */
  public OBQuery<BaseOBObject> createQuery(String entityName, String whereOrderByClause,
      List<Object> parameters) {
    checkReadAccess(entityName);
    final OBQuery<BaseOBObject> obQuery = new OBQuery<BaseOBObject>();
    obQuery.setWhereAndOrderBy(whereOrderByClause);
    obQuery.setEntity(ModelProvider.getInstance().getEntity(entityName));
    obQuery.setParameters(parameters);
    return obQuery;
  }

  /**
   * Creates an OBCriteria object for the specified class.
   * 
   * @param clz
   *          the class used to create the OBCriteria
   * @return a new OBCriteria object
   */
  public <T extends BaseOBObject> OBCriteria<T> createCriteria(Class<T> clz) {
    checkReadAccess(clz);
    final OBCriteria<T> obCriteria = new OBCriteria<T>(clz.getName());
    obCriteria.setEntity(ModelProvider.getInstance().getEntity(clz));
    return obCriteria;
  }

  /**
   * Creates an OBCriteria object for the specified entity.
   * 
   * @param entityName
   *          the type used to create the OBCriteria
   * @return a new OBCriteria object
   */
  public <T extends BaseOBObject> OBCriteria<T> createCriteria(String entityName) {
    checkReadAccess(entityName);
    final OBCriteria<T> obCriteria = new OBCriteria<T>(entityName);
    obCriteria.setEntity(ModelProvider.getInstance().getEntity(entityName));
    return obCriteria;
  }

  /**
   * Retrieves a list of baseOBObjects using the unique-constraints defined for the entity. The
   * passed BaseOBObject and the unique-constraints are used to construct a query searching for
   * matching objects in the database.
   * <p/>
   * Note that multiple unique constraints are used, so therefore the result can be more than one
   * object.
   * 
   * @param obObject
   *          this property values of this obObject is used to find other objects in the database
   *          with the same property values for the unique constraint properties
   * @return a list of objects which match the passed obObject on the unique constraint properties
   * @see Entity#getUniqueConstraints()
   */
  public List<BaseOBObject> findUniqueConstrainedObjects(BaseOBObject obObject) {
    final Entity entity = obObject.getEntity();
    final List<BaseOBObject> result = new ArrayList<BaseOBObject>();
    final Object id = obObject.getId();
    for (final UniqueConstraint uc : entity.getUniqueConstraints()) {
      final OBCriteria<BaseOBObject> criteria = createCriteria(entity.getName());
      if (id != null) {
        criteria.add(Expression.ne("id", id));
      }
      for (final Property p : uc.getProperties()) {
        final Object value = obObject.getValue(p.getName());
        criteria.add(Expression.eq(p.getName(), value));
      }
      final List<BaseOBObject> queryResult = criteria.list();
      // this is not fast, but the list should be small normally
      // if performance becomes a problem then a hashset should
      // be used.
      for (final BaseOBObject queriedObject : queryResult) {
        if (!result.contains(queriedObject)) {
          result.add(queriedObject);
        }
      }
    }

    return result;
  }

  // TODO: this is maybe not the best location for this functionality??
  protected void setClientOrganization(Object o) {
    final OBContext obContext = OBContext.getOBContext();
    if (o instanceof ClientEnabled) {
      final ClientEnabled ce = (ClientEnabled) o;
      // reread the client
      if (ce.getClient() == null) {
        final Client client = SessionHandler.getInstance().find(Client.class,
            obContext.getCurrentClient().getId());
        ce.setClient(client);
      }
    }
    if (o instanceof OrganizationEnabled) {
      final OrganizationEnabled oe = (OrganizationEnabled) o;
      // reread the client and organization
      if (oe.getOrganization() == null) {
        final Organization org = SessionHandler.getInstance().find(Organization.class,
            obContext.getCurrentOrganization().getId());
        oe.setOrganization(org);
      }
    }
  }

  /**
   * Returns an in-clause HQL clause denoting the organizations which are allowed to be read by the
   * current user. The in-clause can be directly used in a HQL. The return string will be for
   * example: in ('1000000', '1000001')
   * 
   * @return an in-clause which can be directly used inside of a HQL clause
   * @see OBContext#getReadableOrganizations()
   */
  public String getReadableOrganizationsInClause() {
    return createInClause(OBContext.getOBContext().getReadableOrganizations());
  }

  /**
   * Returns an in-clause HQL clause denoting the clients which are allowed to be read by the
   * current user. The in-clause can be directly used in a HQL. The return string will be for
   * example: in ('1000000', '1000001')
   * 
   * @return an in-clause which can be directly used inside of a HQL clause
   * @see OBContext#getReadableClients()
   */
  public String getReadableClientsInClause() {
    return createInClause(OBContext.getOBContext().getReadableClients());
  }

  private String createInClause(String[] values) {
    if (values.length == 0) {
      return " in ('') ";
    }
    final StringBuilder sb = new StringBuilder();
    for (final String v : values) {
      if (sb.length() > 0) {
        sb.append(", ");
      }
      sb.append("'" + v + "'");
    }
    return " in (" + sb.toString() + ")";
  }

  private void checkReadAccess(Class<?> clz) {
    checkReadAccess(DalUtil.getEntityName(clz));
  }

  private void checkReadAccess(String entityName) {
    // allow read access to those, otherwise it is really
    // difficult to use querying on these very generic values
    if (entityName.equals(Client.ENTITY_NAME) || entityName.equals(Organization.ENTITY_NAME)) {
      return;
    }
    if (OBContext.getOBContext().isInAdministratorMode()) {
      return;
    }
    final Entity e = ModelProvider.getInstance().getEntity(entityName);
    OBContext.getOBContext().getEntityAccessChecker().checkReadable(e);
  }
}
