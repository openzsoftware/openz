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

import java.io.IOException;
import java.io.ObjectOutputStream;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.hibernate.Hibernate;
import org.hibernate.Query;
import org.openbravo.base.exception.OBSecurityException;
import org.openbravo.base.provider.OBNotSingleton;
import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.structure.BaseOBObject;
import org.openbravo.base.util.Check;
import org.openbravo.dal.security.EntityAccessChecker;
import org.openbravo.dal.security.OrganizationStructureProvider;
import org.openbravo.dal.service.OBDal;
import org.openbravo.model.ad.access.Role;
import org.openbravo.model.ad.access.RoleOrganization;
import org.openbravo.model.ad.access.User;
import org.openbravo.model.ad.access.UserRoles;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.ad.system.Language;
import org.openbravo.model.common.enterprise.Organization;

/**
 * Models the context in which Data Access Layer actions are executed. Contains the user, the client
 * and the allowed organizations.
 * 
 * This class contains specific logic to compute the allowed organizations and clients for both read
 * and write access.
 * 
 * The OBContext instance is made available to other threads through the static ThreadLocal and the
 * getInstance method.
 * 
 * The OBContext can be serialized as part of the Tomcat persistent session mechanism.
 * 
 * @author mtaal
 */

// Note the getInstance/setInstance and ThreadLocal pattern should be reviewed
// when using a factory/dependency injection approach.
public class OBContext implements OBNotSingleton {
  private static final Logger log = Logger.getLogger(OBContext.class);

  // private static final String AD_USERID = "#AD_USER_ID";
  // TODO: maybe use authenticated user
  private static final String AUTHENTICATED_USER = "#AD_User_ID";
  private static final String ROLE = "#AD_Role_ID";
  private static final String CLIENT = "#AD_Client_ID";
  private static final String ORG = "#AD_Org_ID";

  private static ThreadLocal<OBContext> instance = new ThreadLocal<OBContext>();

  private static ThreadLocal<OBContext> adminModeSet = new ThreadLocal<OBContext>();

  public static final String CONTEXT_PARAM = "#OBContext";

  private static OBContext adminContext = null;

  /**
   * Sets the context to the 0 (SystemAdmin) user.
   * 
   * Note overwrites the current OBContext! This method should be used in case there is no real user
   * context yet because the user still has to login (for example).
   * 
   * In all other cases use the method {@link #setInAdministratorMode(boolean)}.
   */
  public static void setAdminContext() {
    if (adminContext == null) {
      setOBContext("0", "0", "0", "0");
      adminContext = getOBContext();
    } else {
      setOBContext(adminContext);
    }
  }

  /**
   * Checks if there is a context set. If not then sets the Admin Context. If yes then set the admin
   * mode of the existing context.
   * 
   * @see OBContext#resetAsAdminContext()
   */
  public static void enableAsAdminContext() {
    if (OBContext.getOBContext() == null) {
      OBContext.setAdminContext();
    } else if (OBContext.getOBContext() == adminContext) {
      return;
    } else {
      OBContext.getOBContext().setInAdministratorMode(true);
    }
  }

  /**
   * Sets the context state back. If the current context is the Admin Context then the current
   * context is set to null. In the other cases the method {@link #setInAdministratorMode(boolean)}
   * is called with the parameter false.
   * 
   * @see OBContext#enableAsAdminContext()
   */
  public static void resetAsAdminContext() {
    if (OBContext.getOBContext() == null) {
      return;
    }
    if (OBContext.getOBContext() == adminContext) {
      OBContext.setOBContext((OBContext) null);
    } else {
      OBContext.getOBContext().setInAdministratorMode(false);
    }
  }

  /**
   * Sets the OBContext through the information stored in the http session of the request (mainly
   * the authenticated user). Note will not set the context in the http session if the session is
   * not present.
   * 
   * @param request
   */
  public static synchronized void setOBContext(HttpServletRequest request) {

    final HttpSession session = request.getSession(false);
    OBContext context = null;
    if (session != null) {
      context = (OBContext) session.getAttribute(CONTEXT_PARAM);
    }

    if (context == null) {
      context = new OBContext();
      if (context.setFromRequest(request)) {
        setOBContextInSession(request, context);
        setOBContext(context);
      }
    } else {
      if (!context.isInSync(request)) {
        context.setFromRequest(request);
      }
      setOBContext(context);
    }
  }

  /**
   * Sets the passed OBContext in the http session. Will not set it if the passed context is the
   * admin context or if the http session is invalidated.
   * 
   * @param request
   *          the http request used to get the http session
   * @param context
   *          the context which will be stored in the session
   */
  public static void setOBContextInSession(HttpServletRequest request, OBContext context) {
    final HttpSession session = request.getSession(false);
    if (session == null) {
      // this can happen at logout, then the session is invalidated
      return;
    }
    if (context != null && context == adminContext) {
      log
          .warn("Trying to set the admin context in the session, "
              + "this means that the context has not been reset correctly in a finally block."
              + " When using the admin context it should always be removed in a finally block by the application");
      return;
    }
    session.setAttribute(CONTEXT_PARAM, context);
  }

  /**
   * Creates the context using the userId and sets it in the thread (as a ThreadLocal). The user
   * denoted by the userId will be automatically logged in.
   * 
   * @param userId
   *          the id of the user (as present in the database)
   */
  public static void setOBContext(String userId) {
    setOBContext(userId, null, null, null);
  }

  /**
   * Creates the context using the userId, roleId, clientId, orgId and sets it in the thread (as
   * ThreadLocal).
   * 
   * @param userId
   *          the id of the user
   * @param roleId
   *          the id of the role under which the user is currently working
   * @param clientId
   *          the id of the user's client
   * @param orgId
   *          the ud of the user's organization
   */
  public static void setOBContext(String userId, String roleId, String clientId, String orgId) {
    final OBContext context = OBProvider.getInstance().get(OBContext.class);
    setOBContext((OBContext) null);
    context.initialize(userId, roleId, clientId, orgId);
    setOBContext(context);
  }

  /**
   * Creates the context without setting the context in the thread.
   * 
   * @param userId
   *          the user used for creating the context
   * @return the created context
   */
  public static OBContext createOBContext(String userId) {
    final OBContext context = new OBContext();
    context.initialize(userId);
    return context;
  }

  /**
   * Set the context in the thread, this context will then be used by the Data Access Layer
   * internals.
   * 
   * @param obContext
   *          the context to set in the thread
   */
  public static void setOBContext(OBContext obContext) {
    // if (obContext != null && instance.get() != null)
    // throw new ArgumentException("OBContext already set");
    instance.set(obContext);

    // nullify the admin context
    adminModeSet.set(null);
  }

  /**
   * Returns the OBContext currently set in the thread. Will return null if no context was set.
   * 
   * @return the context in the thread, null if none present
   */
  public static OBContext getOBContext() {
    final OBContext localContext = instance.get();
    if (localContext != null && localContext.isSerialized()) {
      localContext.initializeFromSerializedState();
    }
    return localContext;
  }

  private Client currentClient;
  private Organization currentOrganization;
  private Role role;
  private User user;
  private Language language;
  private List<Organization> organizationList;
  private String[] readableOrganizations;
  private String[] readableClients;
  private Set<String> writableOrganizations;
  private String userLevel;
  private Map<String, OrganizationStructureProvider> organizationStructureProviderByClient;
  private EntityAccessChecker entityAccessChecker;

  // the "0" user is the administrator
  private boolean isAdministrator;
  private boolean isInitialized = false;

  private Set<String> additionalWritableOrganizations = new HashSet<String>();

  // support storing the context in a persistent tomcat session
  private String serializedUserId;
  private boolean serialized = false;

  public String getUserLevel() {
    return userLevel;
  }

  public void setUserLevel(String userLevel) {
    this.userLevel = userLevel.trim();
  }

  /**
   * Computes the clients allowed for read access using the user level and the client of the role.
   * 
   * @param role
   *          the role used to initialize the readable clients
   */
  public void setReadableClients(Role role) {
    if (getUserLevel().equals("S")) {
      readableClients = new String[] { "0" };
    } else if (role.getClient().getId().equals("0")) {
      readableClients = new String[] { "0" };
    } else {
      readableClients = new String[] { role.getClient().getId(), "0" };
    }
  }

  // writable organization is determined as follows
  // 1) if the user has level S or C then they can only write in organization
  // 0
  // 2) in other cases read the organizations from the role
  // only: if user has userlevel O then he/she can not read organization 0
  // Utility.getContext and LoginUtils for current working
  private void setWritableOrganizations(Role role) {
    writableOrganizations = new HashSet<String>();
    final String localUserLevel = getUserLevel();
    if (localUserLevel.contains("S") || localUserLevel.equals("C")) {
      writableOrganizations.add("0"); // force org *
    }

    final List<Organization> os = getOrganizationList(role);
    for (final Organization o : os) {
      writableOrganizations.add(o.getId());
    }

    if (localUserLevel.equals("O")) { // remove *
      writableOrganizations.remove("0");
    }
    writableOrganizations.addAll(additionalWritableOrganizations);
  }

  @SuppressWarnings("unchecked")
  private List<Organization> getOrganizationList(Role thisRole) {
    if (organizationList != null) {
      return organizationList;
    }
    final Query qry = SessionHandler.getInstance().createQuery(
        "select o from " + Organization.class.getName() + " o, " + RoleOrganization.class.getName()
            + " roa where o." + Organization.PROPERTY_ID + "=roa."
            + RoleOrganization.PROPERTY_ORG + "." + Organization.PROPERTY_ID + " and roa."
            + RoleOrganization.PROPERTY_ROLE + "." + Organization.PROPERTY_ID + "='"
            + thisRole.getId() + "' and roa." + RoleOrganization.PROPERTY_ISACTIVE + "='Y' and o."
            + Organization.PROPERTY_ISACTIVE + "='Y'");
    organizationList = qry.list();
    for (final String orgId : additionalWritableOrganizations) {
      final Organization org = OBDal.getInstance().get(Organization.class, orgId);
      if (!organizationList.contains(org)) {
        organizationList.add(org);
      }
    }
    return organizationList;
  }

  @SuppressWarnings("unchecked")
  private List<Organization> getOrganizations(Client client) {
    final Query qry = SessionHandler.getInstance().createQuery(
        "select o from " + Organization.class.getName() + " o where " + "o."
            + Organization.PROPERTY_CLIENT + "=? and o." + Organization.PROPERTY_ISACTIVE + "='Y'");
    qry.setParameter(0, client);
    organizationList = qry.list();
    return organizationList;
  }

  private void setReadableOrganizations(Role role) {
    final List<Organization> os = getOrganizationList(role);
    final Set<String> readableOrgs = new HashSet<String>();
    for (final Organization o : os) {
      readableOrgs.addAll(getOrganizationStructureProvider().getNaturalTree(o.getId()));
      // if zero is an organization then add them all!
      if (o.getId().equals("0")) {
        for (final Organization org : getOrganizations(getCurrentClient())) {
          readableOrgs.add(org.getId());
        }
      }
    }
    readableOrgs.add("0");
    readableOrganizations = new String[readableOrgs.size()];
    int i = 0;
    for (final String s : readableOrgs) {
      readableOrganizations[i++] = s;
    }
  }

  public Client getCurrentClient() {
    return currentClient;
  }

  public void setCurrentClient(Client currentClient) {
    this.currentClient = currentClient;
  }

  public void setCurrentOrganization(Organization currentOrganization) {
    this.currentOrganization = currentOrganization;
  }

  public Language getLanguage() {
    return language;
  }

  public void setLanguage(Language language) {
    this.language = language;
  }

  public Organization getCurrentOrganization() {
    return currentOrganization;
  }

  public void removeWritableOrganization(String orgId) {
    additionalWritableOrganizations.remove(orgId);
  }

  /**
   * Adds a new organization for which write access is allowed.
   * 
   * @param orgId
   *          the id of the additional writable organization
   */
  public void addWritableOrganization(String orgId) {
    additionalWritableOrganizations.add(orgId);
    // nullify will be recomputed at first occasion
    organizationList = null;
    readableOrganizations = null;
    writableOrganizations = null;
  }

  /**
   * Sets the OBContext using the information stored in the HttpSession
   * 
   * @param request
   *          the http request used to set the OBContext
   * @return false if no user was specified in the session, true otherwise
   */
  public boolean setFromRequest(HttpServletRequest request) {
    final HttpSession session = request.getSession(false);

    if (session == null) {
      // not set
      return false;
    }

    String userId = null;
    for (final Enumeration<?> e = session.getAttributeNames(); e.hasMoreElements();) {
      final String name = (String) e.nextElement();
      if (name.equalsIgnoreCase(AUTHENTICATED_USER)) {
        userId = (String) session.getAttribute(name);
        break;
      }
    }
    if (userId == null) {
      return false; // not yet set
    }
    try {
      return initialize(userId, getSessionValue(request, ROLE), getSessionValue(request, CLIENT),
          getSessionValue(request, ORG));
    } catch (final OBSecurityException e) {
      // remove the authenticated user
      session.setAttribute(AUTHENTICATED_USER, null);
      throw e;
    }
  }

  // the obcontext is located in the session, in tomcat sessions are
  // persisted and its content is serialized. The OBContext contains non-
  // serializable objects (like non-initialized cglib proxies). Therefore
  // before really serializing the obcontext is cleaned out.
  // only the serializedUserId is maintained so that the context can be
  // refreshed after being de-serialized and at the first request
  private void writeObject(ObjectOutputStream out) throws IOException {

    currentClient = null;
    currentOrganization = null;
    role = null;
    user = null;
    language = null;
    organizationList = null;
    readableOrganizations = null;
    readableClients = null;
    writableOrganizations = null;
    userLevel = null;
    organizationStructureProviderByClient = null;
    entityAccessChecker = null;

    isAdministrator = false;
    isInitialized = false;

    serializedUserId = getUser().getId();
    serialized = true;
    out.defaultWriteObject();
  }

  protected void initializeFromSerializedState() {
    initialize(serializedUserId);
    serialized = false;
  }

  // sets the context by reading all user information
  public boolean initialize(String userId) {
    return initialize(userId, null, null, null);
  }

  // sets the context by reading all user information
  public boolean initialize(String userId, String roleId, String clientId, String orgId) {
    String localClientId = clientId;
    final User u = SessionHandler.getInstance().find(User.class, userId);
    if (u == null) {
      return false;
    }
    setInitialized(false);
    setInAdministratorMode(true);
    try {
      setUser(u);
      Hibernate.initialize(getUser().getClient());
      Hibernate.initialize(getUser().getOrg());
      Hibernate.initialize(getUser().getDefaultAdOrg());
      Hibernate.initialize(getUser().getDefaultMWarehouse());
      Hibernate.initialize(getUser().getDefaultAdClient());
      Hibernate.initialize(getUser().getDefaultAdRole());
      Hibernate.initialize(getUser().getDefaultAdLanguage());

      organizationStructureProviderByClient = new HashMap<String, OrganizationStructureProvider>();

      // first take the passed role, if any
      // now check if the default role is active, if not another one needs
      // to be
      // selected.
      if (roleId != null) {
        final Role r = getOne(Role.class, "select r from " + Role.class.getName() + " r where "
            + " r." + Role.PROPERTY_ID + "='" + roleId + "'");
        setRole(r);
      } else if (getUser().getDefaultAdRole() != null && getUser().getDefaultAdRole().isActive()) {
        setRole(getUser().getDefaultAdRole());
      } else {

        final UserRoles ur = getOne(UserRoles.class, "select ur from " + UserRoles.class.getName()
            + " ur where " + " ur." + UserRoles.PROPERTY_USER + "." + User.PROPERTY_ID
            + "='" + u.getId() + "' and ur." + UserRoles.PROPERTY_ISACTIVE + "='Y' and ur."
            + UserRoles.PROPERTY_ROLE + "." + Role.PROPERTY_ISACTIVE + "='Y' order by ur."
            + UserRoles.PROPERTY_ROLE + "." + Role.PROPERTY_ID + " asc", false);
        if (ur == null) {
          throw new OBSecurityException(
              "Your user is not assigned to a Role and it is required to login into Openbravo. Ask the Security Administrator");
        }
        Hibernate.initialize(ur.getRole());
        setRole(ur.getRole());
      }

      Check.isNotNull(getRole(), "Role may not be null");

      if (orgId != null) {
        final Organization o = getOne(Organization.class, "select r from "
            + Organization.class.getName() + " r where " + " r." + Organization.PROPERTY_ID + "='"
            + orgId + "'");
        setCurrentOrganization(o);
      } else if (getUser().getDefaultAdOrg() != null
          && getUser().getDefaultAdOrg().isActive()) {
        setCurrentOrganization(getUser().getDefaultAdOrg());
      } else {
        final RoleOrganization roa = getOne(RoleOrganization.class, "select roa from "
            + RoleOrganization.class.getName() + " roa where roa." + RoleOrganization.PROPERTY_ROLE
            + "." + Organization.PROPERTY_ID + "='" + getRole().getId() + "' and roa."
            + RoleOrganization.PROPERTY_ISACTIVE + "='Y' and roa."
            + RoleOrganization.PROPERTY_ORG + "." + Organization.PROPERTY_ISACTIVE
            + "='Y' order by roa." + RoleOrganization.PROPERTY_ORG + "."
            + Organization.PROPERTY_ID + " desc", false);
        Hibernate.initialize(roa.getOrg());
        setCurrentOrganization(roa.getOrg());

        // if no client id then use the client of the role
        if (localClientId == null) {
          localClientId = roa.getClient().getId();
        }
      }

      Check.isNotNull(getCurrentOrganization(), "Organization may not be null");

      // check that the current organization is actually writable!
      final Set<String> writableOrgs = getWritableOrganizations();
      if (!writableOrgs.contains(getCurrentOrganization().getId())) {
        log.warn("The user " + userId
            + " does not have write access to its current organization repairing that");
        // take the first writableOrganization
        if (writableOrgs.isEmpty()) {
          log.warn("The user " + userId + " does not have any write access to any organization");
        } else {
          setCurrentOrganization(SessionHandler.getInstance().find(Organization.class,
              writableOrgs.iterator().next()));
        }
      }

      if (localClientId != null) {
        final Client c = getOne(Client.class, "select r from " + Client.class.getName()
            + " r where " + " r." + Client.PROPERTY_ID + "='" + localClientId + "'");
        setCurrentClient(c);
      } else if (getUser().getDefaultAdClient() != null && getUser().getDefaultAdClient().isActive()) {
        setCurrentClient(getUser().getDefaultAdClient());
      } else {
        // The HttpSecureAppServlet reads the client after the
        // organization
        // which
        // theoretically can
        // result in a current organization which does not belong to the
        // client
        // other comment, use the client of the organization
        Hibernate.initialize(getCurrentOrganization().getClient());
        setCurrentClient(getCurrentOrganization().getClient());
      }
      Hibernate.initialize(getCurrentClient().getClientInformationList());

      Check.isNotNull(getCurrentClient(), "Client may not be null");
      Check.isTrue(getCurrentClient().isActive(), "Current Client " + getCurrentClient().getName()
          + " is not active!");

      if (getUser().getDefaultAdLanguage() != null && getUser().getDefaultAdLanguage().isActive()) {
        setLanguage(getUser().getDefaultAdLanguage());
      } else {
        final Language l = getOne(Language.class, "select l from " + Language.class.getName()
            + " l where l." + Language.PROPERTY_ISACTIVE + "='Y' order by l." + Language.PROPERTY_ID
            + " asc");
        Hibernate.initialize(l);
        setLanguage(l);
      }

      Check.isNotNull(getLanguage(), "Language may not be null");

      setReadableClients(role);

      // initialize some proxys
      Hibernate.initialize(getCurrentOrganization().getClient());
      Hibernate.initialize(getCurrentClient().getOrg());
      Hibernate.initialize(getRole().getClient());
      Hibernate.initialize(getRole().getOrg());
      Hibernate.initialize(getLanguage().getClient());
      Hibernate.initialize(getLanguage().getOrg());

      // TODO: add logging of all context information
    } finally {
      setInAdministratorMode(false);
      setInitialized(true);
    }
    return true;
  }

  private <T extends Object> T getOne(Class<T> clz, String qryStr) {
    return getOne(clz, qryStr, true);
  }

  @SuppressWarnings("unchecked")
  private <T extends Object> T getOne(Class<T> clz, String qryStr, boolean doCheck) {
    final Query qry = SessionHandler.getInstance().createQuery(qryStr);
    qry.setMaxResults(1);
    final List<?> result = qry.list();
    if (doCheck) {
      Check.isTrue(result.size() == 1, "The query '" + qryStr + "' returned " + result.size()
          + " results while only 1 result was expected");
    }
    if (result.size() == 0) {
      return null;
    }
    return (T) result.get(0);
  }

  public User getUser() {
    return user;
  }

  public void setUser(User user) {
    this.user = user;
  }

  public Role getRole() {
    return role;
  }

  public void setRole(Role role) {
    isAdministrator = ((String) DalUtil.getId(role)).equals("0");
    setUserLevel(role.getUserLevel());
    entityAccessChecker = null;
    writableOrganizations = null;
    readableClients = null;
    readableOrganizations = null;
    this.role = role;
  }

  public OrganizationStructureProvider getOrganizationStructureProvider() {
    return getOrganizationStructureProvider(getCurrentClient().getId());
  }

  public OrganizationStructureProvider getOrganizationStructureProvider(String clientId) {
    OrganizationStructureProvider orgProvider = organizationStructureProviderByClient.get(clientId);

    // create one
    if (orgProvider == null) {
      orgProvider = OBProvider.getInstance().get(OrganizationStructureProvider.class);
      orgProvider.setClientId(clientId);
      organizationStructureProviderByClient.put(clientId, orgProvider);
    }
    return orgProvider;
  }

  public String[] getReadableOrganizations() {
    if (readableOrganizations == null) {
      setReadableOrganizations(getRole());
    }
    return readableOrganizations;
  }

  public Set<String> getWritableOrganizations() {
    if (writableOrganizations == null) {
      setWritableOrganizations(getRole());
    }
    return writableOrganizations;
  }

  public String[] getReadableClients() {
    if (readableClients == null) {
      setReadableClients(getRole());
    }
    return readableClients;
  }

  public EntityAccessChecker getEntityAccessChecker() {
    if (entityAccessChecker == null) {
      entityAccessChecker = OBProvider.getInstance().get(EntityAccessChecker.class);
      // use the DalUtil.getId because it does not resolve hibernate
      // proxies
      entityAccessChecker.setRoleId((String) DalUtil.getId(getRole()));
      entityAccessChecker.setObContext(this);
      entityAccessChecker.initialize();
    }
    return entityAccessChecker;
  }

  public boolean isInAdministratorMode() {
    return adminModeSet.get() != null || isAdministrator;
  }

  public boolean isAdminContext() {
    return this == adminContext;
  }

  public boolean setInAdministratorMode(boolean inAdministratorMode) {
    final boolean prevMode = isInAdministratorMode();
    if (inAdministratorMode) {
      adminModeSet.set(this);
    } else {
      adminModeSet.set(null);
    }
    return prevMode;
  }

  public boolean isInitialized() {
    return isInitialized;
  }

  public void setInitialized(boolean isInitialized) {
    this.isInitialized = isInitialized;
  }

  private boolean isInSync(HttpServletRequest request) {
    if (unequal(request, AUTHENTICATED_USER, getUser())) {
      return false;
    }
    if (unequal(request, ROLE, getRole())) {
      return false;
    }
    if (unequal(request, CLIENT, getCurrentClient())) {
      return false;
    }
    if (unequal(request, ORG, getCurrentOrganization())) {
      return false;
    }
    return true;
  }

  private boolean unequal(HttpServletRequest request, String param, BaseOBObject bob) {
    if (bob == null) {
      return true;
    }
    final String sessionValue = getSessionValue(request, param);
    if (sessionValue == null) {
      return false;
    }
    return !bob.getId().equals(sessionValue);
  }

  private String getSessionValue(HttpServletRequest request, String param) {
    final HttpSession session = request.getSession(false);
    if (session == null) {
      return null;
    }
    return (String) session.getAttribute(param.toUpperCase());
  }

  public boolean isSerialized() {
    return serialized;
  }
}