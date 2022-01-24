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

package org.openbravo.dal.core;

import static org.openbravo.model.ad.system.Client.PROPERTY_ORG;
import static org.openbravo.model.common.enterprise.Organization.PROPERTY_CLIENT;
import static org.openbravo.model.common.enterprise.Organization.PROPERTY_UPDATED;
import static org.openbravo.model.common.enterprise.Organization.PROPERTY_UPDATEDBY;

import java.io.Serializable;
import java.sql.SQLException;
import java.util.Date;
import java.util.Iterator;

import org.apache.log4j.Logger;
import org.hibernate.EmptyInterceptor;
import org.hibernate.proxy.HibernateProxy;
import org.hibernate.type.Type;
import org.openbravo.base.exception.OBException;
import org.openbravo.base.exception.OBSecurityException;
import org.openbravo.base.model.Entity;
import org.openbravo.base.model.Property;
import org.openbravo.base.structure.BaseOBObject;
import org.openbravo.base.structure.ClientEnabled;
import org.openbravo.base.structure.OrganizationEnabled;
import org.openbravo.base.structure.Traceable;
import org.openbravo.dal.security.SecurityChecker;
import org.openbravo.model.ad.access.User;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.common.enterprise.Organization;

/**
 * This interceptor is used by Hibernate as a kind of save, update and delete event listener. This
 * event listener catches save or update events to set the client and organization and the
 * updated/created fields. In addition security checks are performed.
 * 
 * @author mtaal
 */

public class OBInterceptor extends EmptyInterceptor {
  private static final Logger log = Logger.getLogger(OBInterceptor.class);

  private static final long serialVersionUID = 1L;

  /**
   * Determines if the object is transient (==new and not yet persisted in Hibernate).
   * 
   * @param entity
   *          the object for which it is determined if it is new
   * @return true if the object has a null id or has been explicitly set to being new (@see
   *         BaseOBObject#isNewOBObject()}, returns false otherwise.
   */
  @Override
  public Boolean isTransient(Object entity) {
    // special case, if the id is set but it was explicitly
    // set to new then return new
    if (entity instanceof BaseOBObject) {
      final BaseOBObject bob = (BaseOBObject) entity;
      if (bob.getId() != null && bob.isNewOBObject()) {
        return Boolean.valueOf(true);
      }
    }
    // let hibernate do the rest
    return null;
  }

  /**
   * Performs security checks, is the user present in the {@link OBContext} allowed to delete this
   * entity and is the entity deletable (@see {@link Entity#isDeletable()}.
   * 
   * @param entity
   *          the business object which is deleted
   * @param id
   *          the id of the entity
   * @param state
   *          the value of the properties
   * @param propertyNames
   *          the name of the properties of the entity
   * @param types
   *          the hibernate type definition of the properties
   * 
   * @see BaseOBObject
   * @see Entity
   * @see Property
   */
  @Override
  public void onDelete(Object entity, Serializable id, Object[] state, String[] propertyNames,
      Type[] types) {
    SecurityChecker.getInstance().checkDeleteAllowed(entity);
  }

  /**
   * Is called when the entity object is dirty (a value of a property has changed) and the state of
   * the object is about to be flushed to the database using sql update statements. This method
   * updates the audit info fields (updated, updatedBy) and performs security checks.
   * 
   * @param entity
   *          the business object which is deleted
   * @param id
   *          the id of the entity
   * @param currentState
   *          the current value of the properties
   * @param previousState
   *          the previous value of the properties, i.e. the values when the entity was loaded from
   *          the database
   * @param propertyNames
   *          the name of the properties of the entity
   * @param types
   *          the hibernate type definition of the properties
   * @return true if the state of the object has changed, this is the case when the entity has audit
   *         info because the updated/updatedBy properties are updated here, false is returned in
   *         other cases
   */
  @Override
  public boolean onFlushDirty(Object entity, Serializable id, Object[] currentState,
      Object[] previousState, String[] propertyNames, Type[] types) {

    // this can happen when someone has set the id of an object but has not set the
    // new object to true
    if (previousState == null) {
      log
          .warn("The object "
              + entity
              + " is detected as not new (is its id != null?) but it does not have a current state in the database. "
              + "This can happen when the id is set but not setNewObject(true); has been called.");
      return false;
    }
    // disabled for now, checks are all done when a property is set
    // if (entity instanceof BaseOBObject) {
    // ((BaseOBObject) entity).validate();
    // }

    doEvent(entity, currentState, propertyNames);

    checkReferencedOrganizations(entity, currentState, previousState, propertyNames);

    if (entity instanceof Traceable || entity instanceof ClientEnabled
        || entity instanceof OrganizationEnabled) {
      return true;
    }
    return false;
  }

  /**
   * Is called when a new entity object is persisted in the database. This method sets the audit
   * info fields (created/createdBy/updated/updatedBy) and performs several security checks.
   * 
   * @param entity
   *          the business object which is deleted
   * @param id
   *          the id of the entity
   * @param currentState
   *          the current value of the properties
   * @param propertyNames
   *          the name of the properties of the entity
   * @param types
   *          the hibernate type definition of the properties
   * @return true if the state of the object has changed, this is the case when the entity has audit
   *         info because the updated/updatedBy properties are updated here, false is returned in
   *         other cases
   */
  @Override
  public boolean onSave(Object entity, Serializable id, Object[] currentState,
      String[] propertyNames, Type[] types) {
    // disabled for now, checks are all done when a property is set
    // if (entity instanceof BaseOBObject) {
    // ((BaseOBObject) entity).validate();
    // }

    doEvent(entity, currentState, propertyNames);

    // audit info fields
    if (entity instanceof Traceable || entity instanceof ClientEnabled
        || entity instanceof OrganizationEnabled) {
      return true;
    }
    return false;
  }

  private void checkReferencedOrganizations(Object entity, Object[] currentState,
      Object[] previousState, String[] propertyNames) {
    if (!(entity instanceof OrganizationEnabled)) {
      return;
    }
    final Organization o1 = ((OrganizationEnabled) entity).getOrganization();
    final OBContext obContext = OBContext.getOBContext();
    final BaseOBObject bob = (BaseOBObject) entity;
    boolean isNew = bob.getId() == null || bob.isNewOBObject();

    // check if the organization of the current object has changed, if so
    // then check all references
    if (!isNew) {
      for (int i = 0; i < currentState.length; i++) {
        if (propertyNames[i].equals(PROPERTY_ORG)) {
          if (currentState[i] != previousState[i]) {
            isNew = true;
            break;
          }
        }
      }
    }

    for (int i = 0; i < currentState.length; i++) {
      // TODO maybe use equals
      if ((isNew || currentState[i] != previousState[i])
          && !(currentState[i] instanceof Organization)
          && (currentState[i] instanceof BaseOBObject || currentState[i] instanceof HibernateProxy)
          && currentState[i] instanceof OrganizationEnabled) {
        // get the organization from the current state
        final OrganizationEnabled oe = (OrganizationEnabled) currentState[i];
        final Organization o2 = oe.getOrganization();

        if (!obContext.getOrganizationStructureProvider(o1.getClient().getId()).isInNaturalTree(o1,
            o2)) {
          throw new OBSecurityException("Entity " + bob.getIdentifier() + " ("
              + bob.getEntityName() + ") with organization " + o1.getIdentifier()
              + " references an entity " + ((BaseOBObject) currentState[i]).getIdentifier()
              + " through its property " + propertyNames[i] + " but this referenced entity"
              + " belongs to an organization " + o2.getIdentifier()
              + " which is not part of the natural tree of " + o1.getIdentifier());
        }
      }
    }
  }

  // general event handler does new and update
  protected void doEvent(Object object, Object[] currentState, String[] propertyNames) {
    try {
      // not traceable but still do the security check
      if (!(object instanceof Traceable)) {
        // do a check for writeaccess
        // TODO: the question is if this is the correct
        // location as because of hibernate cascade many things are
        // written.
        SecurityChecker.getInstance().checkWriteAccess(object);
        return;
      }

      final Traceable t = (Traceable) object;
      if (t.getCreatedBy() == null) { // new
        onNew(t, propertyNames, currentState);
      } else {
        onUpdate(t, propertyNames, currentState);
      }
    } catch (Exception e) {
      while (e instanceof SQLException && e != ((SQLException) e).getNextException()) {
        e = ((SQLException) e).getNextException();
      }
      throw new OBException(e);
    }

    // do a check for writeaccess
    // TODO: the question is if this is the correct
    // location as because of hibernate cascade many things are written.
    SecurityChecker.getInstance().checkWriteAccess(object);
  }

  // set created/createdby and the client and organization
  private void onNew(Traceable traceable, String[] propertyNames, Object[] currentState) {
    // note both the currentState and the Traceable t are modified
    // the object t is modified because right after this call a security
    // check is done (see onSave). This is before hibernate can copy
    // the changes from currentState to the object. This happens slighlty later.
    final OBContext obContext = OBContext.getOBContext();
    final User currentUser = obContext.getUser();
    log.debug("OBEvent for new object " + traceable.getClass().getName() + " user "
        + currentUser.getName());

    Client client = null;
    Organization org = null;
    if (traceable instanceof ClientEnabled || traceable instanceof OrganizationEnabled) {
      // reread the client and organization
      client = SessionHandler.getInstance()
          .find(Client.class, obContext.getCurrentClient().getId());
      org = SessionHandler.getInstance().find(Organization.class,
          obContext.getCurrentOrganization().getId());
    }
    final Date currentDate = new Date();
    for (int i = 0; i < propertyNames.length; i++) {
      // TODO: check why this is here, seems strange
      if ("".equals(propertyNames[i])) {
        currentState[i] = currentDate;
      }

      if (PROPERTY_UPDATED.equals(propertyNames[i])) {
        traceable.setUpdated(currentDate);
        currentState[i] = currentDate;
      }
      if (PROPERTY_UPDATEDBY.equals(propertyNames[i])) {
        traceable.setUpdatedBy(currentUser);
        currentState[i] = currentUser;
      }
      if (Organization.PROPERTY_CREATED.equals(propertyNames[i])) {
        traceable.setCreationDate(currentDate);
        currentState[i] = currentDate;
      }
      if (Organization.PROPERTY_CREATEDBY.equals(propertyNames[i])) {
        traceable.setCreatedBy(currentUser);
        currentState[i] = currentUser;
      }
      if (PROPERTY_CLIENT.equals(propertyNames[i]) && currentState[i] == null) {
        ((ClientEnabled) traceable).setClient(client);
        currentState[i] = client;
      }
      if (PROPERTY_ORG.equals(propertyNames[i]) && currentState[i] == null) {
        ((OrganizationEnabled) traceable).setOrganization(org);
        currentState[i] = org;
      }
    }
  }

  // Sets the updated/updatedby
  // TODO: can the client/organization change?
  protected void onUpdate(Traceable t, String[] propertyNames, Object[] currentState) {
    final User currentUser = OBContext.getOBContext().getUser();
    log.debug("OBEvent for updated object " + t.getClass().getName() + " user "
        + currentUser.getName());
    for (int i = 0; i < propertyNames.length; i++) {
      if (PROPERTY_UPDATED.equals(propertyNames[i])) {
        currentState[i] = new Date();
      }
      if (PROPERTY_UPDATEDBY.equals(propertyNames[i])) {
        currentState[i] = currentUser;
      }
    }
  }

  // after flushing an object is not new anymore
  @SuppressWarnings("unchecked")
  public void postFlush(Iterator entities) {
    while (entities.hasNext()) {
      final BaseOBObject bob = (BaseOBObject) entities.next();
      bob.setNewOBObject(false);
    }
  }

}
