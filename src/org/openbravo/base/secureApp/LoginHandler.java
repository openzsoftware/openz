/*
 ************************************************************************************
 * Copyright (C) 2001-2009 Openbravo S.L.
 * Licensed under the Apache Software License version 2.0
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to  in writing,  software  distributed
 * under the License is distributed  on  an  "AS IS"  BASIS,  WITHOUT  WARRANTIES  OR
 * CONDITIONS OF ANY KIND, either  express  or  implied.  See  the  License  for  the
 * specific language governing permissions and limitations under the License.
 ************************************************************************************
 */
package org.openbravo.base.secureApp;

import java.io.IOException;
import java.io.PrintWriter;

import javax.mail.Session;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.HttpBaseServlet;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.service.OBDal;
import org.openbravo.erpCommon.security.SessionLoginData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.erpCommon.utility.poc.EmailManager;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.ad.system.SystemInformation;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.FormatUtils;
import org.openz.util.UtilsData;

public class LoginHandler extends HttpBaseServlet {
  private static final long serialVersionUID = 1L;
  private String strServletPorDefecto;

  @Override
  public void init(ServletConfig config) {
    super.init(config);
    strServletPorDefecto = config.getServletContext().getInitParameter("DefaultServlet");
  }

  @Override
  public void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException,
      ServletException {

    if (log4j.isDebugEnabled()) {
      log4j.debug("start doPost");
    }
    final VariablesSecureApp vars = new VariablesSecureApp(req);

    if(vars.commandIn("LINKTORESET")) {
        res.sendRedirect(res.encodeRedirectURL(strDireccion + "/security/Login_ResetPassword.html"));
        return;
    } else if(vars.commandIn("BACKTOLOGIN")) {
        res.sendRedirect(res.encodeRedirectURL(strDireccion + "/security/Login_FS.html"));
        return;
    } else if(vars.commandIn("RESET")) {
        final String strUser = vars.getStringParameter("user");
        final String strEmail = vars.getStringParameter("email");
        
        if(!strUser.isEmpty()) {
            final String adUserId = SeguridadData.getuserID(this, strUser);
            final String userEmail = SeguridadData.getUserEmail(this, adUserId);
            final String adClientId = SeguridadData.getUserClient(this, adUserId);
            final String adOrgId = SeguridadData.getUserOrg(this, adUserId);
            final String url = vars.getSessionValue("#ACTUALURLCONTEXT#");

            if(!adUserId.equals("-1") && userEmail.isEmpty()) {
                // reset not possible without email -> contact administrator
                String language = SeguridadData.getUserDefaultLanguage(this, adUserId);
                String errorMessage = Utility.messageBD(this, "mfa_pwResetFailureNoEmailMessage",language);
                String errorTitle = Utility.messageBD(this, "mfa_pwResetFailureNoEmailTitle",language);
                goToRetry(res, vars, errorMessage, errorTitle, "Error", "../security/Login_FS.html");
                return;
            } else {
                if(!adUserId.equals("-1")
                        && MfaEmailCodeData.isSendingAllowed(this, adUserId).equals("t")
                        && SeguridadData.checkBanSecure(myPool, adUserId).equals("OK")) {
                    if(strEmail.equalsIgnoreCase(userEmail)) {
                        EmailManager em = new EmailManager();
                        Session sess;

                        String email_to = strEmail;
                        String email_from = MfaEmailCodeData.getSenderEmail(this, adClientId);
                        String email_body = "";
                        String email_subject = "";
                        String oneTimePassword = LoginUtils.createOneTimePassword();

                        email_subject = MfaSendOneTimePasswordData.getEmailSubject(this, adUserId);
                        email_body = MfaSendOneTimePasswordData.getEmailBodyPWReset(this, adUserId);
                        email_body = email_body.replaceAll("@password@", oneTimePassword).replaceAll("@url@", url);

                        try {
                            sess = em.newMailSession(this, adClientId, adOrgId);
                            em.sendSimpleEmail(sess, email_from, email_to, "", email_subject, email_body, "");
                        }catch (Exception e) {
                            String language = SeguridadData.getUserDefaultLanguage(this, adUserId);
                            String errorMessage = Utility.messageBD(this, "mfa_pwResetFailureErrorSendingEmailMessage",language);
                            String errorTitle = Utility.messageBD(this, "mfa_pwResetFailureErrorSendingEmailTitle",language);
                            goToRetry(res, vars, errorMessage, errorTitle, "Error", "../security/Login_ResetPassword.html");
                            return;
                        }

                        // save pw in otp culumn, normal password is still usable
                        MfaSendOneTimePasswordData.setOneTimePassword(this, FormatUtilities.sha1Base64(oneTimePassword), adUserId, adUserId);
                    } else {
                        SeguridadData.recordFailedLogin(myPool, adUserId);
                    }
                }
            }
        }
        
        res.sendRedirect(res.encodeRedirectURL(strDireccion + "/security/Login_ResetPasswordConfirm.html"));
        return;
    }

    // Empty session
    req.getSession(true).setAttribute("#Authenticated_user", null);
    // Permanent Login
    if (!vars.getStringParameter("permsession").equals("")) {
        boolean adUserSettingsPermsession = true;
        String stpermsession=vars.getStringParameter("permsession");
        String userid=SeguridadData.getPermsessinUser(myPool, stpermsession); // legacy support for old non hashed permsession cookies
        if(FormatUtils.isNix(userid)) {
            userid=SeguridadData.getPermsessinUser(myPool, FormatUtilities.sha1Base64(stpermsession));
        }
        if(FormatUtils.isNix(userid)) { // adUser Settings permsession overrides keep logged in checkbox/cookie (MFAPermsession)
            userid = SeguridadData.getMFAPermsessinUser(this, FormatUtilities.sha1Base64(stpermsession));
            adUserSettingsPermsession = false;
        }
    	// Kein Eintrag mehr: Cook Löschen
        if (FormatUtils.isNix(userid)
                || (adUserSettingsPermsession && SeguridadData.getUserPermsessionCheck(this, userid).equals("N")) // permsession cookie AND not allowed
                || (!adUserSettingsPermsession && SeguridadData.isKeepLoggedInActivatedForUser(this, userid).equals("N")) // keep me logged in cookie AND not allowed
                || SeguridadData.checkBanSecure(myPool, userid).equals("BANNED")) {
    		Cookie[] cooks=req.getCookies();
    	    if (cooks!=null) {
               for (int i=0;i<cooks.length;i++) {
                   if (cooks[i].getName().equals("permsession")) {
                       cooks[i].setMaxAge(0);
                       cooks[i].setPath(req.getContextPath());
                       res.addCookie(cooks[i]);
                   }
               }
    	    }
    	    res.sendRedirect(strDireccion + "/security/Login_F1.html");
    	} else {
    		req.getSession(true).setAttribute("#Authenticated_user", userid);
	        req.getSession(true).setAttribute("#ScreenY", vars.getStringParameter("ScreenY"));
	        req.getSession(true).setAttribute("#ScreenX", vars.getStringParameter("ScreenX"));
	        checkLicenseAndGo(res, vars, userid);
    	}
    		
    } else { // Normal Login
	    if (vars.getStringParameter("user").equals("")) {
	      res.sendRedirect(res.encodeRedirectURL(strDireccion + "/security/Login_F1.html"));
	    } else {
	      final String strUser = vars.getRequiredStringParameter("user");
	      final String strPass = vars.getStringParameter("password");
	      final String strKeepLoggedIn = vars.getStringParameter("keepLoggedIn");
	      final String strUserAuth = LoginUtils.getValidUserId(myPool, strUser, strPass);
	      final String userNotBanned = SeguridadData.checkBanSecure(myPool, strUserAuth);
	      String failureMessage;
	      if (strUserAuth != null && userNotBanned.equals("OK")) {
	        req.getSession(true).setAttribute("#Authenticated_user", strUserAuth);
	        req.getSession(true).setAttribute("#ScreenY", vars.getStringParameter("ScreenY"));
	        req.getSession(true).setAttribute("#ScreenX", vars.getStringParameter("ScreenX"));
	        String t=vars.getStringParameter("ScreenX");
	        String b=vars.getStringParameter("permsession");
            // If Prmsession: Set Cookie
            // permsession in adUser Settings -> permanent
	        String prmsession_check = SeguridadData.getUserPermsessionCheck(this, strUserAuth);
            if (prmsession_check.equals("Y")
                    || (strKeepLoggedIn.equals("on") && SeguridadData.isKeepLoggedInActivatedForUser(this, strUserAuth).equals("Y"))) {
                String prmsession = UtilsData.getUUID(this);
                int cookieMaxAge = 2147483647; //permanent
                if (prmsession_check.equals("Y")) {
                    SeguridadData.setUserPermsession(this, FormatUtilities.sha1Base64(prmsession), strUserAuth, strUserAuth);
                } else {
                    String prmsession_id = UtilsData.getUUID(this);
                    final String userClient = SeguridadData.getUserClient(this, strUserAuth);
                    final String userOrg = SeguridadData.getUserOrg(this, strUserAuth);
                    // +12 hours so the cookie does not expire during working day
                    cookieMaxAge = (Math.round(Float.parseFloat(MfaEmailCodeData.getKeepMeLoggedInCookieLifetime(this, userOrg))) * 24 + 12) * 60 * 60; //to seconds
                    SeguridadData.setMFAPermsession(this, prmsession_id, String.valueOf(cookieMaxAge), userClient, userOrg, strUserAuth, strUserAuth, strUserAuth, FormatUtilities.sha1Base64(prmsession));
                } 
                Cookie kk=new Cookie("permsession", prmsession);
                kk.setMaxAge(cookieMaxAge);
                String strcon=req.getContextPath();
                kk.setPath(strcon);
                res.addCookie(kk);
            }
	        checkLicenseAndGo(res, vars, strUserAuth);
	      } else {
	        Client systemClient = OBDal.getInstance().get(Client.class, "0");
	        // SZ implemented BANs on failed Logins 
	        String struser = SeguridadData.getuserID(myPool, strUser);
	        if (struser != null && !struser.equals("-1")) 
	          SeguridadData.recordFailedLogin(myPool, struser);
	        String lang;
	        try {
	          lang=systemClient.getLanguage().getLanguage();
	        } catch (Exception e) {
	          lang="en_US";         
	        }
	        String failureTitle = Utility.messageBD(this, "IDENTIFICATION_FAILURE_TITLE", lang);
	        if (SeguridadData.checkBanSecure(myPool, struser).equals("BANNED"))
	          failureMessage = Utility.messageBD(this, "IDENTIFICATION_USERBAN_MSG", lang);
	        else
	          failureMessage = Utility.messageBD(this, "IDENTIFICATION_FAILURE_MSG", lang);
	        goToRetry(res, vars, failureMessage, failureTitle, "Error", "../security/Login_FS.html");
	      }
	    }
  	} 
  }

  private void checkLicenseAndGo(HttpServletResponse res, VariablesSecureApp vars,
      String strUserAuth) throws IOException {
    OBContext.enableAsAdminContext();
    try {
      //ActivationKey ak = new ActivationKey();
      boolean hasSystem = false;

      try {
        hasSystem = SeguridadData.hasSystemRole(this, strUserAuth);
      } catch (Exception ignore) {
        log4j.error(ignore);
      }
      String msgType, action;
      if (hasSystem) {
        msgType = "Warning";
        action = "../security/Menu.html";
      } else {
        msgType = "Error";
        action = "../security/Login_FS.html";
      }

      SystemInformation sysInfo = OBDal.getInstance().get(SystemInformation.class, "0");
      if (sysInfo.getSystemStatus() == null || sysInfo.getSystemStatus().equals("RB70")
          || this.globalParameters.getOBProperty("safe.mode", "false").equalsIgnoreCase("false")) {
        // Last build went fine and tomcat was restarted. We should login as usual
        goToTarget(res, vars);
      } else if (sysInfo.getSystemStatus().equals("RB60")
          || sysInfo.getSystemStatus().equals("RB50")) {
        String msg = Utility.messageBD(myPool, "TOMCAT_NOT_RESTARTED", vars.getLanguage());
        String title = Utility.messageBD(myPool, "TOMCAT_NOT_RESTARTED_TITLE", vars.getLanguage());
        goToRetry(res, vars, msg, title, "Warning", "../security/Menu.html");
      } else {
        String msg = Utility.messageBD(myPool, "LAST_BUILD_FAILED", vars.getLanguage());
        String title = Utility.messageBD(myPool, "LAST_BUILD_FAILED_TITLE", vars.getLanguage());
        goToRetry(res, vars, msg, title, msgType, action);
      }

    } finally {
      OBContext.resetAsAdminContext();
    }

  }

  private void goToTarget(HttpServletResponse response, VariablesSecureApp vars) throws IOException {

    final String target = vars.getSessionValue("target");
    if (target.equals("")) {
      response.sendRedirect(strDireccion + "/security/Menu.html");
    } else {
      response.sendRedirect(target);
    }
  }

  private void goToRetry(HttpServletResponse response, VariablesSecureApp vars, String message,
      String title, String msgType, String action) throws IOException {
    String discard[] = { "" };

    if (msgType.equals("Error")) {
      discard[0] = "continueButton";
    } else {
      discard[0] = "backButton";
    }

    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/HtmlErrorLogin", discard).createXmlDocument();

    // pass relevant mesasge to show inside the error page
    try {
		xmlDocument.setParameter("theme", "ltr/" +SessionLoginData.selectDefaultTheme(this));
	} catch (ServletException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
    xmlDocument.setParameter("messageType", msgType);
    xmlDocument.setParameter("action", action);
    xmlDocument.setParameter("messageTitle", title);
    String msg = (message != null && !message.equals("")) ? message
        : "Please enter your username and password.";
    xmlDocument.setParameter("messageMessage", msg.replaceAll("\\\\n", "<br>"));

    response.setContentType("text/html");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    
    out.close();
  }

  @Override
  public String getServletInfo() {
    return "User-login control Servlet";
  } // end of getServletInfo() method
}
