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
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.poc.EmailManager;
import javax.mail.Session;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.utils.FormatUtilities;
import org.openz.util.FormatUtils;
import org.openbravo.database.ConnectionProvider;



public class Mfa_SendOneTimePassword implements org.openbravo.scheduling.Process {
  private static final Logger log = Logger.getLogger(Mfa_SendOneTimePassword.class);

  public void execute(ProcessBundle bundle) throws Exception {

    log.debug("Starting Mfa_SendOneTimePassword.\n");
    try {
      // For Background process execution at system level

      ConnectionProvider connp = bundle.getConnection();

      final String adUserID = (String) bundle.getParams().get("AD_User_ID");
      final String adUserId_loggedin = bundle.getContext().getUser();
      final String adClientID = bundle.getContext().getClient();
      final String adOrgID = bundle.getContext().getOrganization();
      String url = MfaSendOneTimePasswordData.getUrl(connp, adClientID);
      if(FormatUtils.isNix(url)) {
          url = bundle.vars.getSessionValue("#ACTUALURLCONTEXT#");
      }
      String username = "";
      String email_to = "";
      String email_from = "";
      String email_body = "";
      String email_subject = "";
      String oneTimePassword = LoginUtils.createOneTimePassword();

      EmailManager em = new EmailManager();
      Session sess = em.newMailSession(connp, adClientID, adOrgID);

      // get username
      username = MfaSendOneTimePasswordData.getUsername(connp, adUserID);
      if(username.isEmpty()) {
          throw new Exception ("@mfa_ErrorNoUsername@");
      }

      // get email receiver
      email_to = MfaEmailCodeData.getReceiverEmail(connp, adUserID);
      if(email_to.isEmpty()) {
          throw new Exception ("@mfa_ErrorNoEmail@");
      }

      // get email sender
      email_from = MfaEmailCodeData.getSenderEmail(connp, adClientID);

      email_subject = MfaSendOneTimePasswordData.getEmailSubject(connp, adUserID);
      email_body = MfaSendOneTimePasswordData.getEmailBody(connp, adUserID);
      email_body = email_body.replaceAll("@password@", oneTimePassword).replaceAll("@url@", url);

      if(MfaEmailCodeData.isSendingAllowed(connp, adUserID).equals("f")) {
          throw new Exception("@mfa_ErrorSendOnlyOnePerMinute@");
      }
      
      try {
          em.sendSimpleEmail(sess, email_from, email_to, "", email_subject, email_body, "");
      }catch (Exception e) {
          throw new Exception ("@mfa_ErrorEmailFailed@" + " " + e.getMessage());
      }

      // save pw in otp column, reset "normal" pw to null
      MfaSendOneTimePasswordData.setOneTimePassword(connp, FormatUtilities.sha1Base64(oneTimePassword), adUserId_loggedin, adUserID);
      SeguridadData.resetNormalPassword(connp, adUserId_loggedin, adUserID);

      log.debug("Mfa_SendOneTimePassword finished with: Success \n");


      final OBError msg = new OBError();
      msg.setType("Success");
      msg.setMessage("@mfa_oneTimePasswordSent@");

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