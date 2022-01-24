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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.hibernate.Query;
import org.hibernate.ScrollMode;
import org.hibernate.ScrollableResults;
import org.hibernate.Session;
import org.openbravo.base.exception.OBException;
import org.openbravo.base.model.Entity;
import org.openbravo.base.structure.BaseOBObject;
import org.openbravo.base.util.Check;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.core.SessionHandler;

/**
 * The OBQuery supports querying in the Data Access Layer with free-format (HQL) where and order by
 * clauses. The OBQuery automatically adds applicable client and organization filters and handles
 * joining of entities for orderby clauses.
 * 
 * @see OBCriteria
 * @see OBDal
 * @author mtaal
 */

public class OBQuery<E extends BaseOBObject> {
  private static final Logger log = Logger.getLogger(OBQuery.class);

  private String whereAndOrderBy;
  private Entity entity;
  private List<Object> parameters;
  private Map<String, Object> namedParameters;
  private boolean filterOnReadableOrganizations = true;
  private boolean filterOnReadableClients = true;
  private boolean filterOnActive = true;
  private int firstResult = -1;
  private int maxResult = -1;

  // package visible
  OBQuery() {
  }

  /**
   * Queries the database using the where clauses and addition active, client and organization
   * filters. The order in the list is determined by order by clause.
   * 
   * @return list of objects retrieved from the database
   */
  @SuppressWarnings("unchecked")
  public List<E> list() {
    return createQuery().list();
  }

  /**
   * Queries the database using the where clauses and addition active, client and organization
   * filters. The order in the list is determined by order by clause. Returns an iterator over the
   * data.
   * 
   * @return iterator which walks over the list of objects in the db
   */
  @SuppressWarnings("unchecked")
  public Iterator<E> iterate() {
    return createQuery().iterate();
  }

  /**
   * Makes it possible to get a {@link ScrollableResults} from the underlying Query object.
   * 
   * @param scrollMode
   *          the scroll mode to be used
   * @return the scrollable results which can be scrolled in the direction supported by the
   *         scrollMode
   */
  public ScrollableResults scroll(ScrollMode scrollMode) {
    return createQuery().scroll(scrollMode);
  }

  /**
   * Counts the number of objects in the database on the basis of the whereclause of the query.
   * 
   * @return the number of objects in the database taking into account the where and orderby clause
   */
  public int count() {
    final Query qry = getSession().createQuery(
        "select count(*) " + stripOrderBy(createQueryString()));
    setParameters(qry);
    return ((Number) qry.uniqueResult()).intValue();
  }

  private String stripOrderBy(String qryStr) {
    if (qryStr.toLowerCase().indexOf("order by") != -1) {
      return qryStr.substring(0, qryStr.toLowerCase().indexOf("order by"));
    }
    return qryStr;
  }

  /**
   * Creates a Hibernate Query object using the whereclause and extra filters (for readable
   * organizations etc.).
   * 
   * @return a new Hibernate Query object
   */
  public Query createQuery() {
    final String qryStr = createQueryString();
    try {
      final Query qry = getSession().createQuery(qryStr);
      setParameters(qry);
      if (firstResult > -1) {
        qry.setFirstResult(firstResult);
      }
      if (maxResult > -1) {
        qry.setMaxResults(maxResult);
      }
      return qry;
    } catch (final Exception e) {
      throw new OBException("Exception when creating query " + qryStr, e);
    }
  }

  String createQueryString() {
    final OBContext obContext = OBContext.getOBContext();
    final Entity e = getEntity();

    // split the orderby and where
    final String qryStr = getWhereAndOrderBy();
    final String orderByClause;
    String whereClause;
    final int orderByIndex = qryStr.toLowerCase().indexOf("order by");
    if (orderByIndex != -1) {
      whereClause = qryStr.substring(0, orderByIndex);
      orderByClause = qryStr.substring(orderByIndex);
    } else {
      whereClause = qryStr;
      orderByClause = "";
    }

    // strip the where, is added later
    if (whereClause.trim().toLowerCase().startsWith("where")) {
      final int whereIndex = whereClause.toLowerCase().indexOf("where");
      if (whereIndex != -1) {
        whereClause = whereClause.substring(1 + whereIndex + "where".length());
      }
    }

    // the query can start with an alias to support joins
    // 
    String alias = null;
    // this is a space on purpose
    String prefix = " ";
    if (whereClause.toLowerCase().trim().startsWith("as")) {
      // strip the as
      final String strippedWhereClause = whereClause.toLowerCase().trim().substring(2).trim();
      // get the next space
      final int index = strippedWhereClause.indexOf(" ");
      alias = strippedWhereClause.substring(0, index);
      prefix = alias + ".";
    }

    // The following if is there because the clauses which are added should
    // all be and-ed. Special cases which need to be handled:
    // left join a left join b where a.id is not null or b.id is not null
    // id='0' and exists (from ADModelObject as mo where mo.id=id)
    // id='0'
    boolean addWhereClause = true;
    if (whereClause.trim().length() > 0) {
      if (!whereClause.toLowerCase().contains("where")) {
        // simple case: id='0's
        whereClause = " where (" + whereClause + ")";
        addWhereClause = false;
      } else {
        // check if the where is before
        final int fromIndex = whereClause.toLowerCase().indexOf("from");
        int whereIndex = -1;
        if (fromIndex == -1) {
          // already there and no from
          // now find the place where to put the brackets
          // case: left join a left join b where a.id is not null or
          // b.id is not null

          whereIndex = whereClause.toLowerCase().indexOf("where");
          Check.isTrue(whereIndex != -1, "Where not found in string: " + whereClause);
        } else {
          // example: id='0' and exists (from ADModelObject as mo
          // where mo.id=id)
          // example: left join x where id='0' and x.id=id and exists
          // (from ADModelObject as mo where mo.id=id)

          // check if the whereClause is before the first from
          whereIndex = whereClause.toLowerCase().substring(0, fromIndex).indexOf("where");
        }

        if (whereIndex != -1) {
          // example: left join x where id='0' and x.id=id and exists
          // (from ADModelObject as mo where mo.id=id)
          addWhereClause = false;
          // now put the ( at the correct place
          final int endOfWhere = whereIndex + "where".length();
          whereClause = whereClause.substring(0, endOfWhere) + " ("
              + whereClause.substring(endOfWhere) + ")";
        } else { // no whereclause before the from
          // example: id='0' and exists (from ADModelObject as mo
          // where mo.id=id)
          whereClause = " where (" + whereClause + ")";
          addWhereClause = false;
        }
      }
    }
    if (!OBContext.getOBContext().isInAdministratorMode()) {
      OBContext.getOBContext().getEntityAccessChecker().checkReadable(e);
    }

    if (isFilterOnReadableOrganization() && e.isOrganizationPartOfKey()) {
      whereClause = (addWhereClause ? " where " : "") + addAnd(whereClause) + prefix
          + "id.organization.id " + createInClause(obContext.getReadableOrganizations());
      if (addWhereClause) {
        addWhereClause = false;
      }
    } else if (isFilterOnReadableOrganization() && e.isOrganizationEnabled()) {
      whereClause = (addWhereClause ? " where " : "") + addAnd(whereClause) + prefix
          + "organization.id " + createInClause(obContext.getReadableOrganizations());
      if (addWhereClause) {
        addWhereClause = false;
      }
    }

    if (isFilterOnReadableClients() && getEntity().isClientEnabled()) {
      whereClause = (addWhereClause ? " where " : "") + addAnd(whereClause) + prefix + "client.id "
          + createInClause(obContext.getReadableClients());
      if (addWhereClause) {
        addWhereClause = false;
      }
    }

    if (isFilterOnActive() && e.isActiveEnabled()) {
      whereClause = (addWhereClause ? " where " : "") + addAnd(whereClause) + prefix
          + "active='Y' ";
      if (addWhereClause) {
        addWhereClause = false;
      }
    }

    // now determine the join
    // final StringBuilder join = new StringBuilder();
    // if (orderByClause.length() > 0) {
    // // strip the order by
    // final int orderBy = orderByClause.toLowerCase().indexOf("order by");
    // final String clauses = orderByClause.substring(1 + orderBy
    // + "order by".length());
    // for (String part : clauses.split(",")) {
    // part = part.trim();
    // // now just get the dotted part, only support one for now
    // int firstIndexOf = part.indexOf(".");
    // if (firstIndexOf != -1) {
    // // get the second one
    // int secondIndexOf = part.indexOf(".", firstIndexOf + 1);
    // if (secondIndexOf != -1) {
    // join.append(" left join e."
    // + part.substring(1 + firstIndexOf,
    // secondIndexOf));
    // }
    // }
    // }
    // join.append(" ");
    // }

    final String result;
    if (alias != null) {
      result = "select " + alias + " from " + getEntity().getName() + " " + whereClause
          + orderByClause;
    } else {
      result = "from " + getEntity().getName() + " " + whereClause + orderByClause;
    }
    log.debug("Created query string " + result);
    return result;
  }

  private String addAnd(String whereClause) {
    if (whereClause.trim().length() > 0) {
      return whereClause + " and ";
    }
    return whereClause;
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

  /**
   * @return the Entity queried by the Query object
   */
  public Entity getEntity() {
    return entity;
  }

  void setEntity(Entity entity) {
    this.entity = entity;
  }

  private void setParameters(Query qry) {
    int pos = 0;
    for (final Object param : getParameters()) {
      if (param instanceof BaseOBObject) {
        qry.setEntity(pos++, param);
      } else {
        qry.setParameter(pos++, param);
      }
    }
    final Map<String, Object> localNamedParameters = getNamedParameters();
    if (localNamedParameters != null) {
      for (final String name : localNamedParameters.keySet()) {
        final Object value = localNamedParameters.get(name);
        if (value instanceof BaseOBObject) {
          qry.setEntity(name, value);
        } else {
          qry.setParameter(name, value);
        }
      }
    }
  }

  /**
   * Controls if the readable organizations should be used as a filter in the query. The default is
   * true.
   * 
   * @return if false then readable organizations are not added as a filter to the query
   */
  public boolean isFilterOnReadableOrganization() {
    return filterOnReadableOrganizations;
  }

  /**
   * Controls if the readable organizations should be used as a filter in the query. The default is
   * true.
   * 
   * @param filterOnReadableOrganizations
   *          if set to false then readable organizations are not added as a filter to the query
   */
  public void setFilterOnReadableOrganization(boolean filterOnReadableOrganizations) {
    this.filterOnReadableOrganizations = filterOnReadableOrganizations;
  }

  /**
   * Controls if the isActive column is used as a filter (isActive == 'Y'). The default is true.
   * 
   * @return if false then isActive is not used as a filter for the query
   */
  public boolean isFilterOnActive() {
    return filterOnActive;
  }

  /**
   * Controls if the isActive column is used as a filter (isActive == 'Y'). The default is true.
   * 
   * @param filterOnActive
   *          if false then isActive is not used as a filter for the query, if true (the default)
   *          then isActive='Y' is added as a filter to the query
   */
  public void setFilterOnActive(boolean filterOnActive) {
    this.filterOnActive = filterOnActive;
  }

  /**
   * @return the where and order by clause used in the query
   */
  public String getWhereAndOrderBy() {
    return whereAndOrderBy;
  }

  /**
   * Sets the where and order by clause in the query.
   * 
   * @param queryString
   *          the where and order by parts of the query
   */
  public void setWhereAndOrderBy(String queryString) {
    if (queryString == null) {
      this.whereAndOrderBy = "";
    } else {
      this.whereAndOrderBy = queryString;
    }
  }

  private Session getSession() {
    return SessionHandler.getInstance().getSession();
  }

  /**
   * @return the parameters used in the query, this is the list of non-named parameters in the query
   */
  public List<Object> getParameters() {
    return parameters;
  }

  /**
   * Set the parameters in this query. These are the non-named parameters.
   * 
   * @param parameters
   *          the parameters which are set in the query without a name (e.g. as :?)
   */
  public void setParameters(List<Object> parameters) {
    if (parameters == null) {
      this.parameters = new ArrayList<Object>();
    } else {
      this.parameters = parameters;
    }
  }

  /**
   * Filter the results on readable clients (@see OBContext#getReadableClients()). The default is
   * true.
   * 
   * @return if true then only objects from readable clients are returned, if false then objects
   *         from all clients are returned
   */
  public boolean isFilterOnReadableClients() {
    return filterOnReadableClients;
  }

  /**
   * Filter the results on readable clients (@see OBContext#getReadableClients()). The default is
   * true.
   * 
   * @param filterOnReadableClients
   *          if true then only objects from readable clients are returned by this Query, if false
   *          then objects from all clients are returned
   */
  public void setFilterOnReadableClients(boolean filterOnReadableClients) {
    this.filterOnReadableClients = filterOnReadableClients;
  }

  /**
   * The named parameters used in the query.
   * 
   * @return the map of named parameters which are being used in the query
   */
  public Map<String, Object> getNamedParameters() {
    return namedParameters;
  }

  /**
   * Set the named parameters used in the query.
   * 
   * @param namedParameters
   *          the list of named parameters (string, value pair)
   */
  public void setNamedParameters(Map<String, Object> namedParameters) {
    this.namedParameters = namedParameters;
  }

  /**
   * Sets one named parameter used in the query.
   * 
   * @param paramName
   *          name of the parameter
   * @param value
   *          value which should be used for this parameter
   */
  public void setNamedParameter(String paramName, Object value) {
    if (this.namedParameters == null) {
      this.namedParameters = new HashMap<String, Object>();
    }
    this.namedParameters.put(paramName, value);
  }

  public int getFirstResult() {
    return firstResult;
  }

  public void setFirstResult(int firstResult) {
    this.firstResult = firstResult;
  }

  public int getMaxResult() {
    return maxResult;
  }

  public void setMaxResult(int maxResult) {
    this.maxResult = maxResult;
  }
}
