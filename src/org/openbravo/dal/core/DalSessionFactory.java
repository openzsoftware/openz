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

package org.openbravo.dal.core;

import java.io.Serializable;
import java.sql.Connection;
import java.util.Map;
import java.util.Set;

import javax.naming.NamingException;
import javax.naming.Reference;

import org.hibernate.HibernateException;
import org.hibernate.Interceptor;
import org.hibernate.SessionFactory;
import org.hibernate.StatelessSession;
import org.hibernate.classic.Session;
import org.hibernate.engine.FilterDefinition;
import org.hibernate.metadata.ClassMetadata;
import org.hibernate.metadata.CollectionMetadata;
import org.hibernate.stat.Statistics;
import org.openbravo.base.session.SessionFactoryController;

/**
 * The DalSessionFactory directly delegates all calls to a real SessionFactory except for the calls
 * to open a session in that case an extra action is done to set session information in the database
 * (and then the call is forwarded to the 'real' SessionFactory).
 * 
 * @author mtaal
 * @see SessionFactoryController
 */

public class DalSessionFactory implements SessionFactory {

  private static final long serialVersionUID = 1L;

  private SessionFactory delegateSessionFactory;

  /**
   * NOTE: Openbravo requires normal application code to use the DalSessionFactory and not the real
   * underlying Hibernate SessionFactory.
   * 
   * @return the underlying real sessionfactory
   */
  protected SessionFactory getDelegateSessionFactory() {
    return delegateSessionFactory;
  }

  public void setDelegateSessionFactory(SessionFactory delegateSessionFactory) {
    this.delegateSessionFactory = delegateSessionFactory;
  }

  public void close() throws HibernateException {
    delegateSessionFactory.close();
  }

  @SuppressWarnings("unchecked")
  public void evict(Class persistentClass, Serializable id) throws HibernateException {
    delegateSessionFactory.evict(persistentClass, id);
  }

  @SuppressWarnings("unchecked")
  public void evict(Class persistentClass) throws HibernateException {
    delegateSessionFactory.evict(persistentClass);
  }

  public void evictCollection(String roleName, Serializable id) throws HibernateException {
    delegateSessionFactory.evictCollection(roleName, id);
  }

  public void evictCollection(String roleName) throws HibernateException {
    delegateSessionFactory.evictCollection(roleName);
  }

  public void evictEntity(String entityName, Serializable id) throws HibernateException {
    delegateSessionFactory.evictEntity(entityName, id);
  }

  public void evictEntity(String entityName) throws HibernateException {
    delegateSessionFactory.evictEntity(entityName);
  }

  public void evictQueries() throws HibernateException {
    delegateSessionFactory.evictQueries();
  }

  public void evictQueries(String cacheRegion) throws HibernateException {
    delegateSessionFactory.evictQueries(cacheRegion);
  }

  @SuppressWarnings("unchecked")
  public Map getAllClassMetadata() throws HibernateException {
    return delegateSessionFactory.getAllClassMetadata();
  }

  @SuppressWarnings("unchecked")
  public Map getAllCollectionMetadata() throws HibernateException {
    return delegateSessionFactory.getAllCollectionMetadata();
  }

  @SuppressWarnings("unchecked")
  public ClassMetadata getClassMetadata(Class persistentClass) throws HibernateException {
    return delegateSessionFactory.getClassMetadata(persistentClass);
  }

  public ClassMetadata getClassMetadata(String entityName) throws HibernateException {
    return delegateSessionFactory.getClassMetadata(entityName);
  }

  public CollectionMetadata getCollectionMetadata(String roleName) throws HibernateException {
    return delegateSessionFactory.getCollectionMetadata(roleName);
  }

  public Session getCurrentSession() throws HibernateException {
    return delegateSessionFactory.getCurrentSession();
  }

  @SuppressWarnings("unchecked")
  public Set getDefinedFilterNames() {
    return delegateSessionFactory.getDefinedFilterNames();
  }

  public FilterDefinition getFilterDefinition(String filterName) throws HibernateException {
    return delegateSessionFactory.getFilterDefinition(filterName);
  }

  public Reference getReference() throws NamingException {
    return delegateSessionFactory.getReference();
  }

  public Statistics getStatistics() {
    return delegateSessionFactory.getStatistics();
  }

  public boolean isClosed() {
    return delegateSessionFactory.isClosed();
  }

  /**
   * Note method sets user session information in the database and opens a connection for this.
   */
  public Session openSession() throws HibernateException {
    final Session session = delegateSessionFactory.openSession();
    // ((SessionImplementor)session).connection()
    return session;
  }

  /**
   * Note method sets user session information in the database and opens a connection for this.
   */
  public Session openSession(Connection connection, Interceptor interceptor) {
    final Session session = delegateSessionFactory.openSession(connection, interceptor);
    // ((SessionImplementor)session).connection()
    return session;
  }

  /**
   * Note method sets user session information in the database and opens a connection for this.
   */
  public Session openSession(Connection connection) {
    final Session session = delegateSessionFactory.openSession(connection);
    // ((SessionImplementor)session).connection()
    return session;
  }

  /**
   * Note method sets user session information in the database and opens a connection for this.
   */
  public Session openSession(Interceptor interceptor) throws HibernateException {
    final Session session = delegateSessionFactory.openSession(interceptor);
    // ((SessionImplementor)session).connection()
    return session;
  }

  /**
   * Note method sets user session information in the database and opens a connection for this.
   */
  public StatelessSession openStatelessSession() {
    final StatelessSession session = delegateSessionFactory.openStatelessSession();
    // ((SessionImplementor)session).connection()
    return session;
  }

  /**
   * Note method sets user session information in the database and opens a connection for this.
   */
  public StatelessSession openStatelessSession(Connection connection) {
    final StatelessSession session = delegateSessionFactory.openStatelessSession(connection);
    // ((SessionImplementor)session).connection()
    return session;
  }
}
