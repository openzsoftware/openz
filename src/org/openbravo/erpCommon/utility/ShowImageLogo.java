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

import org.openbravo.base.HttpBaseServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.service.OBDal;
import org.openbravo.model.ad.system.ClientInformation;
import org.openbravo.model.ad.system.SystemInformation;
import org.openbravo.model.ad.utility.Image;
import org.openbravo.model.common.enterprise.Organization;
import org.openbravo.utils.FileUtility;

/**
 * 
 * This utility class implements a servlet that shows an image stored in database
 * 
 */
public class ShowImageLogo extends HttpBaseServlet {

  private static final long serialVersionUID = 1L;

  /**
   * Receiving an id parameter it looks in database for the image with that id and displays it
   */
  public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    String logo = vars.getStringParameter("logo");
    if (logo == null || logo.equals(""))
      return;

    OBContext.enableAsAdminContext();
    try {
      Image img = null;
      if (logo.equals("yourcompanylogin")) {
        img = OBDal.getInstance().get(SystemInformation.class, "0").getYourCompanyLoginImage();
      } else if (logo.equals("youritservicelogin")) {
        img = OBDal.getInstance().get(SystemInformation.class, "0").getYourItServiceLoginImage();
      } else if (logo.equals("yourcompanymenu")) {
        img = OBDal.getInstance().get(ClientInformation.class,
            OBContext.getOBContext().getCurrentClient().getId()).getYourCompanyMenuImage();
        if (img == null)
          img = OBDal.getInstance().get(SystemInformation.class, "0").getYourCompanyMenuImage();
      } else if (logo.equals("yourcompanybig")) {
        img = OBDal.getInstance().get(ClientInformation.class,
            OBContext.getOBContext().getCurrentClient().getId()).getYourCompanyBigImage();
        if (img == null)
          img = OBDal.getInstance().get(SystemInformation.class, "0").getYourCompanyBigImage();
      } else if (logo.equals("yourcompanydoc")) {
        String orgId = vars.getStringParameter("orgId");
        if (orgId != null && !orgId.equals("")) {
          Organization org = OBDal.getInstance().get(Organization.class, orgId);
          img = org.getOrganizationInformationList().get(0).getYourCompanyDocumentImage();
        }
        if (img == null)
          img = OBDal.getInstance().get(SystemInformation.class, "0").getYourCompanyDocumentImage();
      } else
        return;
      byte[] imageBytes = null;
      if (img != null) {
        imageBytes = img.getBinaryData();
        OutputStream out = response.getOutputStream();
        response.setContentLength(imageBytes.length);
        out.write(imageBytes);
        out.close();
      } else {
        String imagePath = null;
        if (logo.equals("yourcompanylogin")) {
          imagePath = "web/images/CompanyLogo_big.png";
        } else if (logo.equals("youritservicelogin")) {
          imagePath = "web/images/SupportLogo_big.png";
        } else if (logo.equals("yourcompanymenu")) {
          imagePath = "web/images/CompanyLogo_small.png";
        } else if (logo.equals("yourcompanybig")) {
          imagePath = "web/skins/ltr/OpenZND/Login/logoopenz.png";
        } else if (logo.equals("yourcompanydoc")) {
          imagePath = "web/images/CompanyLogo_big.png";
        }
        if (imagePath == null) {
          // If there is not image to show return blank.gif
          imagePath = "web/images/blank.gif";
        }

        FileUtility f = new FileUtility(this.globalParameters.prefix, imagePath, false, true);
        f.dumpFile(response.getOutputStream());
        response.getOutputStream().flush();
        response.getOutputStream().close();
      }

    } finally {
      OBContext.resetAsAdminContext();
    }
  }
}
