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

package org.openbravo.erpCommon.utility;

import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.service.OBDal;
import org.openbravo.model.ad.utility.Image;
import org.openbravo.utils.FileUtility;

/**
 * 
 * This utility class implements a servlet that shows an image stored in database
 * 
 */
public class ShowImage extends HttpSecureAppServlet {

  private static final long serialVersionUID = 1L;

  /**
   * Receiving an id parameter it looks in database for the image with that id and displays it
   */
  public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    boolean adminMode = OBContext.getOBContext().setInAdministratorMode(true);
    try {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      String id = vars.getStringParameter("id");
      Image img = null;
      try {
        img = OBDal.getInstance().get(Image.class, id);
      } catch (Exception e) {
        log4j.error("Could not load image from database", e);
      }

      if (img != null) {
        byte[] imageBytes = img.getBinaryData();
        if (imageBytes != null) {
          OutputStream out = response.getOutputStream();
          response.setContentLength(imageBytes.length);
          out.write(imageBytes);
          out.close();
        }
      } else { // If there is not image to show return blank.gif
    	FileUtility f;
    	// Try c_file
    	String namedFile=null;
    	String spath=null;
    	if (id!=null && ! id.isEmpty()) {
	    	String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
	    	namedFile = ShowImageData.getFileName(this, id);
	    	spath = fileDir + "/" + ShowImageData.getFilePath(this, id) + "/";
    	}
    	if (namedFile!=null && ! namedFile.isEmpty()) {
    		f = new FileUtility(spath, namedFile,false, true);
    	} else {	  
    		f = new FileUtility(this.globalParameters.prefix, "web/images/blank.gif",false, true);
    	}
        f.dumpFile(response.getOutputStream());
        response.getOutputStream().flush();
        response.getOutputStream().close();
      }
    } finally {
      OBContext.getOBContext().setInAdministratorMode(adminMode);
    }
  }
}
