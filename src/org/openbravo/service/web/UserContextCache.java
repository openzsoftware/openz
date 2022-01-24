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

package org.openbravo.service.web;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.provider.OBSingleton;
import org.openbravo.dal.core.OBContext;

/**
 * The main purpose of the user context cache is to support session-less http requests without a
 * large performance hit. With a session-less http request every request needs to log in. This can
 * be comparatively heavy as for each request a new {@link OBContext} is created.
 * <p/>
 * The user context cache takes care of storing a cache of user contexts (on user id) which are
 * re-used when a web-service call is done. Note that the OBContext which is cached can be re-used
 * by multiple threads at the same time.
 * 
 * @see OBContext
 * 
 * @author mtaal
 */

public class UserContextCache implements OBSingleton {

  private final long EXPIRES_IN = 1000 * 60 * 30;

  private static UserContextCache instance;

  public static synchronized UserContextCache getInstance() {
    if (instance == null) {
      instance = OBProvider.getInstance().get(UserContextCache.class);
    }
    return instance;
  }

  public static synchronized void setInstance(UserContextCache instance) {
    UserContextCache.instance = instance;
  }

  private Map<String, CacheEntry> cache = new ConcurrentHashMap<String, CacheEntry>();

  /**
   * Searches the ContextCache for an OBContext. If none is found a new one is created and placed in
   * the cache.
   * 
   * 
   * @param userId
   *          the user for which an OBContext is required
   * @return the OBContext object
   * 
   * @see OBContext
   */
  public OBContext getCreateOBContext(String userId) {
    CacheEntry ce = cache.get(userId);
    purgeCache();
    if (ce != null) {
      ce.setLastUsed(System.currentTimeMillis());
      return ce.getObContext();
    }
    final OBContext obContext = OBContext.createOBContext(userId);
    ce = new CacheEntry();
    ce.setLastUsed(System.currentTimeMillis());
    ce.setObContext(obContext);
    ce.setUserId(userId);
    cache.put(userId, ce);
    return obContext;
  }

  private void purgeCache() {
    final List<CacheEntry> toRemove = new ArrayList<CacheEntry>();
    for (final CacheEntry ce : cache.values()) {
      if (ce.hasExpired()) {
        toRemove.add(ce);
      }
    }
    for (final CacheEntry ce : toRemove) {
      cache.remove(ce.getUserId());
    }
  }

  class CacheEntry {
    private OBContext obContext;
    private long lastUsed;
    private String userId;

    public boolean hasExpired() {
      return getLastUsed() < (System.currentTimeMillis() - EXPIRES_IN);
    }

    public OBContext getObContext() {
      return obContext;
    }

    public void setObContext(OBContext obContext) {
      this.obContext = obContext;
    }

    public long getLastUsed() {
      return lastUsed;
    }

    public void setLastUsed(long lastUsed) {
      this.lastUsed = lastUsed;
    }

    public String getUserId() {
      return userId;
    }

    public void setUserId(String userId) {
      this.userId = userId;
    }

  }

}