/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.openbravo.base.secureApp;


import org.apache.log4j.Logger;
import org.openbravo.erpCommon.ad_forms.Role;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.database.ConnectionProvider;



public class EnterPassword implements org.openbravo.scheduling.Process {
  private static final Logger log = Logger.getLogger(EnterPassword.class);

  public void execute(ProcessBundle bundle) throws Exception {

    log.debug("Starting EnterPassword.\n");

    try {
        final String unhashedPW = bundle.getParams().get("password").toString();

        ConnectionProvider connp = bundle.getConnection();
        final String adUserID = (String) bundle.getParams().get("AD_User_ID");
        final String adUserId_loggedin = bundle.getContext().getUser();
        final String adOrgID = bundle.getContext().getOrganization();
        final String language = bundle.getContext().getLanguage();

        Role.validatePasswordOnlyAllowedCharacters(connp, adOrgID, language, unhashedPW);

        MfaChangePasswordData.setPassword(connp, FormatUtilities.sha1Base64(unhashedPW), adUserId_loggedin, adUserID);
        SeguridadData.resetOTPassword(connp, adUserId_loggedin, adUserID);

        log.debug("EnterPassword finished with: Success \n");

        final OBError msg = new OBError();
        msg.setType("Success");
        msg.setMessage("@PasswordChanged@");
        msg.setTitle("Done");
        bundle.setResult(msg);

    } catch (final Exception e) {
      log.error(e.getMessage(), e);
      final OBError msg = new OBError();
      msg.setType("Error");
      msg.setMessage(e.getMessage());
      msg.setTitle("@DoneWithErrors@");
      bundle.setResult(msg);
    }

  }

}