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

package org.openbravo.base.session;

import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.openbravo.base.exception.OBException;
import org.openbravo.base.util.Check;

/**
 * This class implements a central location where the Openbravo.properties are read and made
 * available for the rest of the application.
 * 
 * @author mtaal
 */
public class OBPropertiesProvider {
  private final Logger log = Logger.getLogger(OBPropertiesProvider.class);

  private Properties obProperties = null;

  private static OBPropertiesProvider instance = new OBPropertiesProvider();

  public static synchronized OBPropertiesProvider getInstance() {
    return instance;
  }

  public static synchronized void setInstance(OBPropertiesProvider instance) {
    OBPropertiesProvider.instance = instance;
  }

  public Properties getOpenbravoProperties() {
    return obProperties;
  }

  public void setProperties(InputStream is) {
    Check.isNull(obProperties, "Openbravo properties have already been set");
    log.debug("Setting openbravo.properties through input stream");
    obProperties = new Properties();
    try {
      obProperties.load(is);
      is.close();
    } catch (final Exception e) {
      throw new OBException(e);
    }
  }

  public void setProperties(Properties props) {
    Check.isNull(obProperties, "Openbravo properties have already been set");
    log.debug("Setting openbravo.properties through properties");
    obProperties = new Properties();
    obProperties.putAll(props);
  }

  public void setProperties(String fileLocation) {
    // Check.isNull(obProperties,
    // "Openbravo properties have already been set");
    log.debug("Setting openbravo.properties through a file");
    obProperties = new Properties();
    try {
      final FileInputStream fis = new FileInputStream(fileLocation);
      obProperties.load(fis);
      fis.close();
    } catch (final Exception e) {
      throw new OBException(e);
    }
  }
}