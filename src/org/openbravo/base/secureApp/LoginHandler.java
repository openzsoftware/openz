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
import org.openbravo.model.ad.module.Module;
import org.openbravo.model.ad.system.Client;
import org.openbravo.model.ad.system.SystemInformation;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.FormatUtils;

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

    // Empty session
    req.getSession(true).setAttribute("#Authenticated_user", null);
    // Permanent Login
    if (!vars.getStringParameter("permsession").equals("")) {
    	String stpermsession=vars.getStringParameter("permsession");
    	String userid=SeguridadData.getPermsessinUser(myPool, stpermsession);
    	// Kein Eintrag mehr: Cook Löschen
    	if (FormatUtils.isNix(userid) || SeguridadData.checkBanSecure(myPool, userid).equals("BANNED")) {
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
	      final String strUserAuth = LoginUtils.getValidUserId(myPool, strUser, strPass);
	      final String userNotBanned = SeguridadData.checkBanSecure(myPool, strUserAuth);
	      String failureMessage;
	      if (strUserAuth != null && userNotBanned.equals("OK")) {
	        req.getSession(true).setAttribute("#Authenticated_user", strUserAuth);
	        req.getSession(true).setAttribute("#ScreenY", vars.getStringParameter("ScreenY"));
	        req.getSession(true).setAttribute("#ScreenX", vars.getStringParameter("ScreenX"));
	        String t=vars.getStringParameter("ScreenX");
	        String b=vars.getStringParameter("permsession");
	        // If Prmsession: Set Cokkie
	        if (! FormatUtils.isNix(SeguridadData.getUserPermsessin(myPool, strUserAuth))) {
	        	String prmsession=SeguridadData.getUserPermsessin(myPool, strUserAuth);
	        	Cookie kk=new Cookie("permsession", prmsession);
	        	kk.setMaxAge(2147483647); //permanent
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
