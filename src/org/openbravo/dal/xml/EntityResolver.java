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

package org.openbravo.dal.xml;

import static org.openbravo.model.ad.system.Client.PROPERTY_ORG;
import static org.openbravo.model.common.enterprise.Organization.PROPERTY_CLIENT;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.hibernate.criterion.Expression;
import org.openbravo.base.model.AccessLevel;
import org.openbravo.base.model.Entity;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.model.Property;
import org.openbravo.base.model.UniqueConstraint;
import org.openbravo.base.provider.OBNotSingleton;
import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.structure.BaseOBObject;
import org.openbravo.base.util.Check;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.security.OrganizationStructureProvider;
import org.openbravo.dal.service.OBCriteria;
import org.openbravo.dal.service.OBDal;
import org.openbravo.model.ad.datamodel.Table;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.ad.utility.ReferenceDataStore;
import org.openbravo.model.common.enterprise.Organization;
import org.openbravo.model.common.plm.AttributeSet;
import org.openbravo.model.common.plm.AttributeSetInstance;

/**
 * The entity resolver will resolve an entity name and id to a business object. The resolver will
 * first try to find the business object in the database in the accessible clients and organizations
 * using the id and the content of the mapping table (AD_REF_DATA_LOADED table). If not found then
 * unique constraints are used to find matching objects in the database. If then still no existing
 * object is found then a new object is created and based on the accesslevel of the Entity the
 * client and organization are set.
 * 
 * @author mtaal
 */

public class EntityResolver implements OBNotSingleton {

  /**
   * The resolving mode determines how the EntityResolver should response if no existing object can
   * be found for a certain entity name and id.
   * <p/>
   * ALLOW_NOT_EXIST (the default) will allow a not-yet existing object and will create a new one.
   * MUST_EXIST will result in an EntityNotFoundException if the object can not be found in the
   * database.
   */
  public enum ResolvingMode {
    ALLOW_NOT_EXIST, MUST_EXIST
  }

  public static EntityResolver getInstance() {
    return OBProvider.getInstance().get(EntityResolver.class);
  }

  // keeps track of the mapping from id's to objects
  private Map<Object, BaseOBObject> data = new HashMap<Object, BaseOBObject>();
  private Map<BaseOBObject, String> objectOriginalIdMapping = new HashMap<BaseOBObject, String>();
  private Client clientZero;
  private Organization organizationZero;
  private String[] zeroOrgTree = new String[] { "0" };
  private Client client;
  private Organization organization;
  private String[] orgNaturalTree;
  private String[] orgIdTree;
  private ResolvingMode resolvingMode = ResolvingMode.ALLOW_NOT_EXIST;

  private OrganizationStructureProvider organizationStructureProvider;

  private boolean optionCreateReferencedIfNotFound = true;

  void clear() {
    data.clear();
    objectOriginalIdMapping.clear();
  }

  /**
   * Searches for an entity using the entityname and the id, first the internal cache is searched
   * and then the database. Depending if the entity is searched for as a reference or as a main
   * object (in the root of the xml) the search is differs. If no existing object can be found then
   * new one is created..
   * 
   * @param entityName
   *          the name of the entity searched for
   * @param id
   *          the id, can be null
   * @param referenced
   *          if the entity is searched because it is refered to or if it is in the root of the xml
   * @return an existing or a new entity
   */
  // searches for a previous entity with the same id or an id retrieved from
  // the ad_ref_data_loaded table. The resolving takes into account different
  // access levels and
  public BaseOBObject resolve(String entityName, String id, boolean referenced) {

    Check.isNotNull(client, "Client should not be null");
    Check.isNotNull(organization, "Org should not be null");

    final Entity entity = ModelProvider.getInstance().getEntity(entityName);

    BaseOBObject result = null;
    // note id can be null if someone did not care to add it in a manual
    // xml file
    if (id != null) {
      result = data.get(getKey(entityName, id));
      if (result != null) {
        return result;
      }

      result = searchInstance(entity, id);
    }

    if (result != null) {
      // found, cache it for future use
      data.put(getKey(entityName, id), result);
    } else {
      if (referenced && !isOptionCreateReferencedIfNotFound()) {
        throw new EntityNotFoundException("Entity " + entityName + " with id " + id + " not found");
      }
      if (resolvingMode == ResolvingMode.MUST_EXIST) {
        throw new EntityNotFoundException("Entity " + entityName + " with id " + id + " not found");
      }

      // not found create a new one
      result = (BaseOBObject) OBProvider.getInstance().get(entityName);

      if (id != null) {
        // keep the relation so that ad_ref_data_loaded can be filled
        // later
        objectOriginalIdMapping.put(result, id);

        // check if we can keep the id for this one
        if (!OBDal.getInstance().exists(entityName, id)) {
          result.setId(id);
        }
        // force new
        result.setNewOBObject(true);

        // keep it here so it can be found later
        data.put(getKey(entityName, id), result);
      }

      setClientOrganization(result);
    }
    return result;
  }

  protected void setClientOrganization(BaseOBObject bob) {

    setClientOrganizationZero();

    final Entity entity = bob.getEntity();

    // TODO: add warning if the entity is created in a different
    // client/organization than the inputted ones
    // Set the client and organization on the most detailed level
    // looking at the accesslevel of the entity
    Client setClient;
    Organization setOrg;
    if (entity.getAccessLevel() == AccessLevel.SYSTEM) {
      setClient = clientZero;
      setOrg = organizationZero;
    } else if (entity.getAccessLevel() == AccessLevel.SYSTEM_CLIENT) {
      setClient = client;
      setOrg = organizationZero;
    } else if (entity.getAccessLevel() == AccessLevel.CLIENT) {
      setClient = client;
      setOrg = organizationZero;
    } else if (entity.getAccessLevel() == AccessLevel.CLIENT_ORGANIZATION) {
      setClient = client;
      setOrg = organization;
    } else if (entity.getAccessLevel() == AccessLevel.ORGANIZATION) {
      // TODO: is this correct? That it is the same as the previous
      // one?
      setClient = client;
      setOrg = organization;
    } else if (entity.getAccessLevel() == AccessLevel.ALL) {
      setClient = client;
      setOrg = organization;
    } else {
      throw new EntityXMLException("Access level " + entity.getAccessLevel() + " not supported");
    }
    if (entity.isClientEnabled()) {
      bob.setValue(PROPERTY_CLIENT, setClient);
    }
    if (entity.isOrganizationEnabled()) {
      bob.setValue(PROPERTY_ORG, setOrg);
    }

  }

  // search on the basis of the access level of the entity
  protected BaseOBObject searchInstance(Entity entity, String id) {
    final AccessLevel al = entity.getAccessLevel();
    BaseOBObject result = null;
    if (al == AccessLevel.SYSTEM) {
      result = searchSystem(id, entity);
    } else if (al == AccessLevel.SYSTEM_CLIENT) {
      // search client and system
      result = searchClient(id, entity);
      if (result == null) {
        result = searchSystem(id, entity);
      }
    } else if (al == AccessLevel.CLIENT) {
      result = searchClient(id, entity);
    } else if (al == AccessLevel.ORGANIZATION) {
      result = searchClientOrganization(id, entity);
    } else if (al == AccessLevel.CLIENT_ORGANIZATION) {
      // search 2 levels
      result = searchClientOrganization(id, entity);
      if (result == null) {
        result = searchClient(id, entity);
      }
      if (result == null
          && (entity.getName().compareTo(AttributeSetInstance.ENTITY_NAME) == 0 || entity.getName()
              .compareTo(AttributeSet.ENTITY_NAME) == 0)) {
        result = searchSystem(id, entity);
      }
    } else if (al == AccessLevel.ALL) {
      // search all three levels from the bottom
      result = searchClientOrganization(id, entity);
      if (result == null) {
        result = searchClient(id, entity);
      }
      if (result == null) {
        result = searchSystem(id, entity);
      }
    }
    return result;
  }

  public String getOriginalId(BaseOBObject bob) {
    return objectOriginalIdMapping.get(bob);
  }

  protected BaseOBObject searchSystem(String id, Entity entity) {
    return doSearch(id, entity, "0", "0");
  }

  protected BaseOBObject searchClient(String id, Entity entity) {
    return search(id, entity, "0");
  }

  protected BaseOBObject searchClientOrganization(String id, Entity entity) {
    return search(id, entity, organization.getId());
  }

  protected BaseOBObject search(String id, Entity entity, String orgId) {
    // first check if the object was already imported in this level
    // so check if there is a new id available
    final List<String> newIds = getId(id, entity, orgId);
    if (newIds.size() > 0) {
      for (final String newId : newIds) {
        final BaseOBObject result = doSearch(newId, entity, client.getId(), orgId);
        if (result != null) {
          return result;
        }
      }
    }
    return doSearch(id, entity, client.getId(), orgId);
  }

  protected BaseOBObject doSearch(String id, Entity entity, String clientId, String orgId) {
    final String[] searchOrgIds = getOrgIds(orgId);
    final OBCriteria<?> obc = OBDal.getInstance().createCriteria(entity.getName());
    obc.setFilterOnActive(false);
    obc.setFilterOnReadableClients(false);
    obc.setFilterOnReadableOrganization(false);
    if (entity.isClientEnabled()) {
      obc.add(Expression.eq(PROPERTY_CLIENT + "." + Organization.PROPERTY_ID, clientId));
    }
    if (entity.isOrganizationEnabled()) {
      // Note the query is for other types than client but the client
      // property names
      // are good standard ones to use
      obc.add(Expression.in(PROPERTY_ORG + "." + Client.PROPERTY_ID, searchOrgIds));
    }
    // same for here
    obc.add(Expression.eq(Organization.PROPERTY_ID, id));
    final List<?> res = obc.list();
    Check.isTrue(res.size() <= 1, "More than one result when searching in " + entity.getName()
        + " with id " + id);
    if (res.size() == 1) {
      return (BaseOBObject) res.get(0);
    }
    return null;
  }

  // get the new id which was created in previous imports
  // note that there is a rare case that when an instance is removed
  // and then re-imported that it occurs multiple times.
  private List<String> getId(String id, Entity entity, String orgId) {
    final String[] searchOrgIds = getOrgIds(orgId);
    final boolean adminMode = OBContext.getOBContext().isInAdministratorMode();
    final boolean prevMode = OBContext.getOBContext().setInAdministratorMode(true);
    try {
      final OBCriteria<ReferenceDataStore> rdlCriteria = OBDal.getInstance().createCriteria(
          ReferenceDataStore.class);
      rdlCriteria.setFilterOnActive(false);
      rdlCriteria.setFilterOnReadableOrganization(false);
      rdlCriteria.setFilterOnReadableClients(false);
      rdlCriteria.add(Expression.eq(ReferenceDataStore.PROPERTY_GENERIC, id));
      rdlCriteria.add(Expression.eq(ReferenceDataStore.PROPERTY_CLIENT + "." + Client.PROPERTY_ID,
          client.getId()));
      rdlCriteria.add(Expression.in(ReferenceDataStore.PROPERTY_ORG + "."
          + Organization.PROPERTY_ID, searchOrgIds));
      rdlCriteria.add(Expression.eq(ReferenceDataStore.PROPERTY_TABLE + "." + Table.PROPERTY_ID,
          entity.getTableId()));
      final List<ReferenceDataStore> rdls = rdlCriteria.list();

      final List<String> result = new ArrayList<String>();
      for (final ReferenceDataStore rdl : rdls) {
        result.add(rdl.getSpecific());
      }
      return result;
    } finally {
      // only set back if the previous was false
      if (!adminMode) {
        OBContext.getOBContext().setInAdministratorMode(prevMode);
      }
    }
  }

  // determines which org ids to look, if 0 then only look zero
  // in other cases look only in the passed orgId if this is not
  // a referenced one, otherwise use the naturaltree
  private String[] getOrgIds(String orgId) {
    final String[] searchOrgIds;
    if (true) {
      if (orgId.equals("0")) {
        searchOrgIds = zeroOrgTree;
      } else {
        searchOrgIds = orgNaturalTree;
      }
    } else {
      searchOrgIds = orgIdTree;
    }
    return searchOrgIds;
  }

  protected void setClientOrganizationZero() {
    if (clientZero != null) {
      return;
    }
    final boolean oldSetting = OBContext.getOBContext().setInAdministratorMode(true);
    try {
      clientZero = OBDal.getInstance().get(Client.class, "0");
      organizationZero = OBDal.getInstance().get(Organization.class, "0");
    } finally {
      OBContext.getOBContext().setInAdministratorMode(oldSetting);
    }
  }

  protected Client getClient() {
    return client;
  }

  protected void setClient(Client client) {
    setClientOrganizationZero();
    organizationStructureProvider = OBProvider.getInstance().get(
        OrganizationStructureProvider.class);
    organizationStructureProvider.setClientId(client.getId());
    this.client = client;
  }

  protected Organization getOrganization() {
    return organization;
  }

  protected void setOrganization(Organization organization) {
    orgIdTree = new String[] { organization.getId() };
    final Set<String> orgs = organizationStructureProvider.getNaturalTree(organization.getId());
    orgNaturalTree = orgs.toArray(new String[orgs.size()]);
    this.organization = organization;
  }

  protected Map<Object, BaseOBObject> getData() {
    return data;
  }

  protected boolean isOptionCreateReferencedIfNotFound() {
    return optionCreateReferencedIfNotFound;
  }

  /**
   * This option controls if referenced objects (through an association) must exist in the database.
   * 
   * @param optionCreateReferencedIfNotFound
   *          if true then referenced objects are allowed to not exist in the database, meaning that
   *          they a new object is created for a reference
   */
  public void setOptionCreateReferencedIfNotFound(boolean optionCreateReferencedIfNotFound) {
    this.optionCreateReferencedIfNotFound = optionCreateReferencedIfNotFound;
  }

  protected ResolvingMode getResolvingMode() {
    return resolvingMode;
  }

  /**
   * @see ResolvingMode
   */
  public void setResolvingMode(ResolvingMode resolvingMode) {
    this.resolvingMode = resolvingMode;
  }

  // queries the database for another object which has the same values
  // for properties which are part of a uniqueconstraint
  // if found a check is done if the object is part of the current
  // installed
  protected BaseOBObject findUniqueConstrainedObject(BaseOBObject obObject) {
    // an existing object should not be able to violate his/her
    // own constraints
    if (!obObject.isNewOBObject()) {
      return null;
    }

    final Entity entity = obObject.getEntity();
    final Object id = obObject.getId();
    for (final UniqueConstraint uc : entity.getUniqueConstraints()) {
      final OBCriteria<BaseOBObject> criteria = OBDal.getInstance()
          .createCriteria(entity.getName());
      if (id != null) {
        criteria.add(Expression.ne("id", id));
      }

      boolean ignoreUniqueConstraint = false;
      for (final Property p : uc.getProperties()) {
        final Object value = obObject.getValue(p.getName());

        // a special check, the property refers to an
        // object which is also new, presumably this object
        // is also added in the import
        // in this case the
        // uniqueconstraint can never fail
        // so move on to the next
        if (value instanceof BaseOBObject && ((BaseOBObject) value).isNewOBObject()) {
          ignoreUniqueConstraint = true;
          break;
        }

        criteria.add(Expression.eq(p.getName(), value));
      }
      if (ignoreUniqueConstraint) {
        continue;
      }

      criteria.setFilterOnActive(false);
      criteria.setFilterOnReadableOrganization(false);
      criteria.setFilterOnReadableClients(false);
      criteria.setMaxResults(1);

      final List<BaseOBObject> queryResult = criteria.list();
      if (queryResult.size() > 0) {

        // check if the found unique match is a valid
        // object to use
        // TODO: this can be made faster by
        // adding client/organization filtering above in
        // the criteria
        final BaseOBObject searchResult = searchInstance(entity, (String) queryResult.get(0)
            .getId());
        if (searchResult == null) {
          // not valid return null
          return null;
        }
        return queryResult.get(0);
      }
    }

    return null;
  }

  protected Client getClientZero() {
    if (clientZero == null) {
      setClientOrganizationZero();
    }
    return clientZero;
  }

  protected Organization getOrganizationZero() {
    if (organizationZero == null) {
      setClientOrganizationZero();
    }
    return organizationZero;
  }

  /**
   * Replace an object in the cache with another one. The new one is then found when using the id of
   * the old one. The id of the previous one can be local to the xml.
   * 
   * @param prevObject
   *          the object current in the data cache
   * @param newObject
   *          the new object which can then be found under the old object
   */
  public void exchangeObjects(BaseOBObject prevObject, BaseOBObject newObject) {
    if (!(prevObject.getId() instanceof String)) {
      // these are never refered to anyway
      return;
    }
    final String id = (String) prevObject.getId();
    if (id == null) {
      // no one will refer to these ones
      return;
    }
    Check.isTrue(prevObject.getEntityName().compareTo(newObject.getEntityName()) == 0,
        "Entity names are different for objects " + prevObject + " and " + newObject);

    data.put(getKey(prevObject.getEntityName(), id), newObject);
  }

  // convenience to prevent using id and entityName in the wrong order
  protected String getKey(String entityName, String id) {
    return entityName + id;
  }
}