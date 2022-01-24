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

package org.openbravo.base.gen;

import java.io.File;

import org.apache.log4j.Logger;
import org.openarchitectureware.workflow.ant.WorkflowAntTask;
import org.openbravo.base.exception.OBException;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.provider.OBConfigFileProvider;
import org.openbravo.base.provider.OBProvider;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.base.util.OBClassLoader;

/**
 * Task generates the entities using OpenArchitectureWare. It initializes the dal/model layer, the
 * rest of the work is done by the superclass.
 * 
 * @author Martin Taal
 */
public class GenerateEntitiesTask extends WorkflowAntTask {
  private static final Logger log = Logger.getLogger(GenerateEntitiesTask.class);

  private static String basePath;
  private String srcGenPath;

  public static String getBasePath() {
    return basePath;
  }

  public static void setBasePath(String basePath) {
    GenerateEntitiesTask.basePath = basePath;
  }

  private String propertiesFile;
  private String providerConfigDirectory;
  private boolean debug;

  public String getPropertiesFile() {
    return propertiesFile;
  }

  public void setPropertiesFile(String propertiesFile) {
    this.propertiesFile = propertiesFile;
  }

  @Override
  public void execute() {

    if (getBasePath() == null) {
      setBasePath(super.getProject().getBaseDir().getAbsolutePath());
    }

    if (!hasChanged()) {
      log.info("Model has not changed since last run, not re-generating entities");
      return;
    }

    if (debug) {
      OBProvider.getInstance().register(OBClassLoader.class,
          OBClassLoader.ClassOBClassLoader.class, false);

      // the beautifier uses the source.path if it is not set
      log.debug("initializating dal layer, getting properties from " + getPropertiesFile());
      OBPropertiesProvider.getInstance().setProperties(getPropertiesFile());

      if (getProviderConfigDirectory() != null) {
        OBConfigFileProvider.getInstance().setFileLocation(getProviderConfigDirectory());
      }

      try {
        ModelProvider.getInstance().getModel();
      } catch (final Exception e) {
        e.printStackTrace(System.err);
        throw new OBException(e);
      }
    }
    super.execute();
  }

  private boolean hasChanged() {
    // first check if there is a directory
    // already in the src-gen
    // if not then regenerate anyhow
    final File modelDir = new File(getSrcGenPath(), "org" + File.separator + "openbravo"
        + File.separator + "model" + File.separator + "ad");
    if (!modelDir.exists()) {
      return true;
    }

    OBProvider.getInstance().register(OBClassLoader.class, OBClassLoader.ClassOBClassLoader.class,
        false);

    // the beautifier uses the source.path if it is not set
    log.debug("initializating dal layer, getting properties from " + getPropertiesFile());
    OBPropertiesProvider.getInstance().setProperties(getPropertiesFile());

    if (getProviderConfigDirectory() != null) {
      OBConfigFileProvider.getInstance().setFileLocation(getProviderConfigDirectory());
    }

    // check if the logic to generate has changed...
    final String sourceDir = getBasePath();
    long lastModifiedPackage = 0;
    lastModifiedPackage = getLastModifiedPackage("org.openbravo.base.model", sourceDir,
        lastModifiedPackage);
    lastModifiedPackage = getLastModifiedPackage("org.openbravo.base.gen", sourceDir,
        lastModifiedPackage);
    lastModifiedPackage = getLastModifiedPackage("org.openbravo.base.structure", sourceDir,
        lastModifiedPackage);

    // check if there is a sourcefile which was updated before the last
    // time the model was created. In this case that sourcefile (and
    // all source files need to be regenerated
    final long lastModelUpdateTime = ModelProvider.getInstance().computeLastUpdateModelTime();
    final long lastModified;
    if (lastModelUpdateTime > lastModifiedPackage) {
      lastModified = lastModelUpdateTime;
    } else {
      lastModified = lastModifiedPackage;
    }
    return isSourceFileUpdatedBeforeModelChange(modelDir, lastModified);
  }

  private boolean isSourceFileUpdatedBeforeModelChange(File file, long modelUpdateTime) {
    if (file.isDirectory()) {
      for (File child : file.listFiles()) {
        if (isSourceFileUpdatedBeforeModelChange(child, modelUpdateTime)) {
          return true;
        }
      }
      return false;
    }
    return file.lastModified() < modelUpdateTime;
  }

  private long getLastModifiedPackage(String pkg, String baseSourcePath, long prevLastModified) {
    final File file = new File(baseSourcePath, pkg.replaceAll("\\.", "/"));
    final long lastModified = getLastModifiedRecursive(file);
    if (lastModified > prevLastModified) {
      return lastModified;
    }
    return prevLastModified;
  }

  private long getLastModifiedRecursive(File file) {
    long lastModified = file.lastModified();
    if (file.isDirectory()) {
      for (File child : file.listFiles()) {
        final long childLastModified = getLastModifiedRecursive(child);
        if (lastModified < childLastModified) {
          lastModified = childLastModified;
        }
      }
    }
    return lastModified;
  }

  public String getProviderConfigDirectory() {
    return providerConfigDirectory;
  }

  public void setProviderConfigDirectory(String providerConfigDirectory) {
    this.providerConfigDirectory = providerConfigDirectory;
  }

  public boolean isDebug() {
    return debug;
  }

  public void setDebug(boolean debug) {
    this.debug = debug;
  }

  public String getSrcGenPath() {
    return srcGenPath;
  }

  public void setSrcGenPath(String srcGenPath) {
    this.srcGenPath = srcGenPath;
  }
}
