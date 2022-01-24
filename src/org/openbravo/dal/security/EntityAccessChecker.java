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

package org.openbravo.dal.security;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.hibernate.Query;
import org.openbravo.base.exception.OBSecurityException;
import org.openbravo.base.model.Entity;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.model.Property;
import org.openbravo.base.provider.OBNotSingleton;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.core.SessionHandler;
import org.openbravo.model.ad.access.TableAccess;
import org.openbravo.model.ad.access.WindowAccess;
import org.openbravo.model.ad.ui.Tab;
import org.openbravo.model.ad.ui.Window;

/**
 * This class is responsible for determining the allowed read/write access for a combination of user
 * and Entity. It uses the window-role access information and the window-table relation to determine
 * which tables are readable and writable for a user. If the user has readWrite access to a Window
 * then also the related Table/Entity is writable.
 * <p/>
 * In addition this class implements the concept of derived readable. Any entity refered to from a
 * readable/writable entity is a derived readable. A user may read (but not write) the following
 * properties from a deriver readable entity: id and identifier properties. Access to any other
 * property or changing a property on a derived readable entity results in a OBSecurityException.
 * Derived readable checks are done when a value is retrieved of an object (@see
 * BaseOBObject#get(String)).
 * <p/>
 * This class is used from the {@link SecurityChecker} which combines all entity security checks.
 * 
 * @see Entity
 * @see Property
 * @see SecurityChecker
 * @author mtaal
 */

public class EntityAccessChecker implements OBNotSingleton {

  // Table Access Level:
  // "6";"System/Client"
  // "1";"Organization"
  // "3";"Client/Organization"
  // "4";"System only"
  // "7";"All"

  // User level:
  // "S";"System"
  // " C";"Client"
  // "  O";"Organization"
  // " CO";"Client+Organization"

  private String roleId;

  private Set<Entity> writableEntities = new HashSet<Entity>();

  private Set<Entity> readableEntities = new HashSet<Entity>();
  // the derived readable entities only contains the entities which are
  // derived
  // readable
  // the completely readable entities are present in the readableEntities
  private Set<Entity> derivedReadableEntities = new HashSet<Entity>();
  private Set<Entity> nonReadableEntities = new HashSet<Entity>();
  private boolean isInitialized = false;

  private OBContext obContext;

  /**
   * Reads the windows from the database using the current role of the user. Then it iterates
   * through the windows and tabs to determine which entities are readable/writable for that user.
   * In addition non-readable and derived-readable entities are computed.
   * 
   * @see ModelProvider
   */
  public void initialize() {

    final ModelProvider mp = ModelProvider.getInstance();
    final String userLevel = obContext.getUserLevel();

    // Don't use dal because otherwise we can end up in infinite loops
    final String qryStr = "select wa from " + WindowAccess.class.getName() + " wa where role.id='"
        + getRoleId() + "'";
    final Query qry = SessionHandler.getInstance().createQuery(qryStr);
    @SuppressWarnings("unchecked")
    final List<WindowAccess> was = qry.list();
    for (final WindowAccess wa : was) {
      final Window w = wa.getWindow();
      final boolean writeAccess = wa.isReadWrite();
      // get the ttabs
      final String tfQryStr = "select t from " + Tab.class.getName() + " t where window.id='"
          + w.getId() + "'";
      @SuppressWarnings("unchecked")
      final List<Tab> ts = SessionHandler.getInstance().createQuery(tfQryStr).list();
      for (final Tab t : ts) {
        final String tableName = t.getTable().getTableName();
        final Entity e = mp.getEntityByTableName(tableName);
        if (e == null) { // happens for AD_Client_Info and views
          continue;
        }

        final String accessLevel = t.getTable().getAccessLevel();
        if (!hasCorrectAccessLevel(userLevel, accessLevel)) {
          continue;
        }

        if (writeAccess) {
          writableEntities.add(e);
          readableEntities.add(e);
        } else {
          readableEntities.add(e);
        }
      }
    }

    // and take into account table access
    final String tafQryStr = "select ta from " + TableAccess.class.getName()
        + " ta where role.id='" + getRoleId() + "'";
    @SuppressWarnings("unchecked")
    final List<TableAccess> tas = SessionHandler.getInstance().createQuery(tafQryStr).list();
    for (final TableAccess ta : tas) {
      final String accessLevel = ta.getTable().getAccessLevel();
      if (!hasCorrectAccessLevel(userLevel, accessLevel)) {
        continue;
      }

      final String tableName = ta.getTable().getName();
      final Entity e = mp.getEntityByTableName(tableName);

      if (ta.isExclude()) {
        readableEntities.remove(e);
        writableEntities.remove(e);
        nonReadableEntities.add(e);
      } else if (ta.isReadOnly()) {
        writableEntities.remove(e);
      }
    }

    // and compute the derived readable
    for (final Entity e : readableEntities) {
      for (final Property p : e.getProperties()) {
        if (p.getTargetEntity() != null && !readableEntities.contains(p.getTargetEntity())) {
          derivedReadableEntities.add(p.getTargetEntity());
          addDerivedReadableIdentifierProperties(p.getTargetEntity());
        }
      }
    }

    isInitialized = true;
  }

  /**
   * Checks if a certain user access level and a certain data access level match. Meaning that with
   * a certain user access level it is allowed to view something with a certain data access level.
   * 
   * @param userLevel
   *          the user level as defined in the role of the user
   * @param accessLevel
   *          the data access level defined in the table
   * @return true if access is allowed, false otherwise
   */
  private boolean hasCorrectAccessLevel(String userLevel, String accessLevel) {
    // copied from HttpSecureAppServlet.
    if (accessLevel.equals("4") && userLevel.indexOf("S") == -1) {
      return false;
    } else if (accessLevel.equals("1") && userLevel.indexOf("O") == -1) {
      return false;
    } else if (accessLevel.equals("3")
        && (!(userLevel.indexOf("C") != -1 || userLevel.indexOf("O") != -1))) {
      return false;
    } else if (accessLevel.equals("6")
        && (!(userLevel.indexOf("S") != -1 || userLevel.indexOf("C") != -1))) {
      return false;
    }
    return true;
  }

  /**
   * Dumps the readable, writable, derived readable entities to the System.err outputstream. For
   * debugging purposes.
   */
  public void dump() {
    System.err.println("");
    System.err.println(">>> Readable entities: ");
    System.err.println("");
    dumpSorted(readableEntities);

    System.err.println("");
    System.err.println(">>> Derived Readable entities: ");
    System.err.println("");
    dumpSorted(derivedReadableEntities);

    System.err.println("");
    System.err.println(">>> Writable entities: ");
    System.err.println("");
    dumpSorted(writableEntities);
    System.err.println("");
    System.err.println("");

    final Set<Entity> readableNotWritable = new HashSet<Entity>(readableEntities);
    readableNotWritable.removeAll(writableEntities);

    System.err.println("");
    System.err.println(">>> Readable Not-Writable entities: ");
    System.err.println("");
    dumpSorted(readableNotWritable);
    System.err.println("");
    System.err.println("");

  }

  private void dumpSorted(Set<Entity> set) {
    final List<String> names = new ArrayList<String>();
    for (final Entity e : set) {
      names.add(e.getName());
    }
    Collections.sort(names);
    for (final String n : names) {
      System.err.println(n);
    }
  }

  // a special case whereby an identifier property is again a reference to
  // another entity, then this other entity is also derived readable, etc.
  private void addDerivedReadableIdentifierProperties(Entity entity) {
    for (final Property p : entity.getProperties()) {
      if (p.isIdentifier() && p.getTargetEntity() != null
          && !readableEntities.contains(p.getTargetEntity())) {
        derivedReadableEntities.add(p.getTargetEntity());
        addDerivedReadableIdentifierProperties(p.getTargetEntity());
      }
    }
  }

  /**
   * @param entity
   *          the entity to check
   * @return true if the entity is derived readable for this user, otherwise false is returned.
   */
  public boolean isDerivedReadable(Entity entity) {
    // prevent infinite looping
    if (!isInitialized) {
      return false;
    }

    // false is the allow read reply
    if (obContext.isInAdministratorMode()) {
      return false;
    }
    return derivedReadableEntities.contains(entity);
  }

  /**
   * @param entity
   *          the entity to check
   * @return true if the entity is writable for this user, otherwise false is returned.
   */
  public boolean isWritable(Entity entity) {
    // prevent infinite looping
    if (!isInitialized) {
      return true;
    }

    if (obContext.isInAdministratorMode()) {
      return true;
    }

    if (!writableEntities.contains(entity)) {
      return false;
    }
    return true;
  }

  /**
   * Checks if an entity is writable for this user. If not then a OBSecurityException is thrown.
   * 
   * @param entity
   *          the entity to check
   * @throws OBSecurityException
   */
  public void checkWritable(Entity entity) {
    if (!isWritable(entity)) {
      throw new OBSecurityException("Entity " + entity + " is not writable by this user");
    }
  }

  /**
   * Checks if an entity is readable for this user. If not then a OBSecurityException is thrown.
   * 
   * @param entity
   *          the entity to check
   * @throws OBSecurityException
   */
  public void checkReadable(Entity entity) {
    // prevent infinite looping
    if (!isInitialized) {
      return;
    }

    if (obContext.isInAdministratorMode()) {
      return;
    }

    if (nonReadableEntities.contains(entity)) {
      throw new OBSecurityException("Entity " + entity + " is not readable by this user");
    }

    if (derivedReadableEntities.contains(entity)) {
      return;
    }

    if (!readableEntities.contains(entity)) {
      throw new OBSecurityException("Entity " + entity + " is not readable by the user "
          + obContext.getUser().getId());
    }
  }

  public String getRoleId() {
    return roleId;
  }

  public void setRoleId(String roleId) {
    this.roleId = roleId;
  }

  public OBContext getObContext() {
    return obContext;
  }

  public void setObContext(OBContext obContext) {
    this.obContext = obContext;
  }

  public Set<Entity> getReadableEntities() {
    return readableEntities;
  }

  public Set<Entity> getWritableEntities() {
    return writableEntities;
  }

}