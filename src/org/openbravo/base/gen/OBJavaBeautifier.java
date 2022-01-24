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

import org.hybridlabs.source.beautifier.CharacterSequence;
import org.hybridlabs.source.formatter.JavaImportBeautifier;

/**
 * Sets the user.home system variable to the source.path/temp directory. This so that the hybridlabs
 * beautifier creates its preferences directory in the correct location.
 * 
 * @author Martin Taal
 */

public class OBJavaBeautifier extends JavaImportBeautifier {

  @Override
  public void beautify(CharacterSequence characterSequence) {
    final String userHome = System.getProperty("user.home");
    // final String sourcePath = OBPropertiesProvider.getInstance()
    // .getOpenbravoProperties().getProperty("source.path");
    // Check.isNotNull(sourcePath,
    // "The source.path parameter is not defined "
    // + "in Openbravo.properties");
    final String sourcePath = GenerateEntitiesTask.getBasePath();
    final File tempDir = new File(sourcePath, "../temp");
    if (!tempDir.exists()) {
      tempDir.mkdirs();
    }
    try {
      System.setProperty("user.home", tempDir.getAbsolutePath());
      super.beautify(characterSequence);
    } finally {
      System.setProperty("user.home", userHome);
    }
  }

}
