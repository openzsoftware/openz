/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Stefan Zimmermann.
***************************************************************************************************************************************************
*/
package org.openbravo.base.secureApp;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Random;

import javax.mail.Session;
import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.tools.ant.taskdefs.SendEmail;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.erpCommon.utility.poc.EmailManager;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.utils.Replace;
import org.openz.util.UtilsData;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.*;

public class Mfa_EmailCode  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
      Scripthelper script= new Scripthelper();
      response.setContentType("text/html; charset=UTF-8");

      try{
        String strmfacode = vars.getStringParameter("inpemailcode");
        
        //Initializing the Fieldgroups
        String strnamefg=""; //Navigation Fieldgroup
        
        String strmsg = Utility.messageBD(this, "Mfa_EmailCodeHeader",vars.getLanguage());
        String strinfo = "<div class=\"info\" style=\"margin: 1% 0 0 33%;font-size: 15pt; color:#404040;\">"
                + "<p>" + strmsg + "</p>"
                + "</div>";
        
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output
        
        final String adClientID = vars.getSessionValue("#AD_CLIENT_ID");
        final String adOrgID = vars.getSessionValue("#AD_ORG_ID");
        final String adUserID = vars.getSessionValue("#AD_USER_ID");
        
        
        
        // if cookie redirect to logout to prevent new code entry
        Cookie[] cooks=request.getCookies();
        if (cooks!=null) {
            for (int i=0;i<cooks.length;i++) {
                if (cooks[i].getName().equals("MFA_Cookie") && MfaEmailCodeData.validateCookie(this, FormatUtilities.sha1Base64(cooks[i].getValue()), adUserID)) {
                    vars.setSessionValue("MFA_LOGOUT_REASON", "EmailCode");
                    response.sendRedirect(strDireccion + "/org.openbravo.base.secureApp.ad_forms/Mfa_Logout.html");
                }
            }
        }
        
        // user banned -> logout reset mfa code
        if(SeguridadData.checkBanSecure(this, adUserID).equals("BANNED")) {
            MfaEmailCodeData.resetMFACode(this, adUserID, adUserID);
            logout(request, response);
        } else if(vars.commandIn("CONFIRM")) {
            if(!strmfacode.isEmpty() && MfaEmailCodeData.getMfaCode(this, adUserID).equals(FormatUtilities.sha1Base64(strmfacode))) {
                String uuid = UtilsData.getUUID(this);
                String hash = UtilsData.getUUID(this);
                Cookie kk = new Cookie("MFA_Cookie", hash);
                hash = FormatUtilities.sha1Base64(hash);
                // +12 hours so the cookie does not expire during working day
                int lifetime = (Math.round(Float.parseFloat(MfaEmailCodeData.getCookieLifetime(this, adOrgID))) * 24 + 12) * 60 * 60; //to seconds
                kk.setMaxAge(lifetime);
                String strcon=request.getContextPath();
                kk.setPath(strcon);
                response.addCookie(kk);
                
                MfaEmailCodeData.setCookie(this, uuid, hash, String.valueOf(lifetime), adClientID, adOrgID, adUserID, adUserID, adUserID);
                MfaEmailCodeData.resetMFACode(this, adUserID, adUserID);
                vars.setSessionValue("MFA_LOGOUT_REASON", "EmailCode");
                response.sendRedirect(strDireccion + "/org.openbravo.base.secureApp.ad_forms/Mfa_Logout.html");
            } else {
                if(!strmfacode.isEmpty()) {
                    SeguridadData.recordFailedLogin(this, adUserID);
                }
                if(SeguridadData.checkBanSecure(this, adUserID).equals("BANNED")) {
                    throw new Exception ("@mfa_user_banned@");
                }
                throw new Exception ("@mfa_CodeMismatch@");
            }
        } else if(vars.commandIn("SEND")) {
            sendEmail(adClientID, adOrgID, adUserID, vars);
            response.sendRedirect(strDireccion + "/org.openbravo.base.secureApp.ad_forms/Mfa_EmailCode.html");
        } else {
            // only on first load and no email send in the last 60 seconds
            if(vars.getSessionValue("EmailCodeFirstLoad", "true").equals("true")
                    && MfaEmailCodeData.isSendingAllowed(this, adUserID).equals("t")) {
                sendEmail(adClientID, adOrgID, adUserID, vars);
                vars.setSessionValue("EmailCodeFirstLoad", "false");
                response.sendRedirect(strDireccion + "/org.openbravo.base.secureApp.ad_forms/Mfa_EmailCode.html");   
            }
        }
        
        StringBuilder confirmBtn = ConfigureButton.doConfigure(this, vars, script, "confirm", 0, 1, false, "confirm", "submitCommandForm('CONFIRM', true, null, null, '_self') ", "", "82EFC338061140A9B4F5BBC9C3E77F67"); //confirm
        StringBuilder sendBtn = ConfigureButton.doConfigure(this, vars, script, "send", 0, 1, false, "send", "submitCommandForm('SEND', true, null, null, '_self') ", "", "DBD7519580C84F87B45814B27C4DC949"); //send email
        
        String strOwnBtn = "<table class=\"ownbtn\">"
        		+ "<tr class=\"ownbtn1\">" + confirmBtn.toString().replaceAll("type=\"button\"", "type=\"submit\"") + "</tr>" // confirm button on enter
        		+ "<tr class=\"ownbtn2\">" + sendBtn + "</tr>"
        		+ "</table>";
              
        //Configuring the Structure                                                   Title of Site  Toolbar  
        strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "inpmfacode", null, "MFA Email Code", "", "REMOVED", null, "true");
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();
        
        //Saving the Fieldgroups into Variables
        //Navigation Fieldgroup
        strnamefg=fh.prepareFieldgroup(this, vars, script, "Mfa_EmailCode_fg", null,false);
        
        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@", strnamefg + strOwnBtn + strinfo);
        
        // Enable Shortcuts
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");

        script.addJScript("function funcName(){"
                + "document.getElementsByClassName(\'Form_Table\')[0].style.margin = \"2% 0 0 15%\";"
                + "document.getElementsByClassName(\'Label\')[0].style.fontSize = \"15pt\";"
                + "document.getElementsByClassName(\'Celltable\')[0].style.width = \"500px\";"
                + "document.getElementById(\"emailcode\").style.height = \"26px\";"
                + "document.getElementById(\"emailcode\").style.fontSize = \"15pt\";"
                + "document.getElementsByClassName(\"ownBtn\")[0].style.margin = \"10px 0% 0% 32.1%\";"
                + "document.getElementById(\"sendtd\").style.margin = \"-24% 0% 0% 300%\";"
                + "document.getElementById(\"send\").style.width = \"130px\";"
                + "document.getElementById(\"buttonBack\").remove();"
                + "};");
        
        script.addOnload("funcName();");
        
        //Creating the Output
        strOutput = script.doScript(strOutput, "",this,vars);
        
        //Sending the Output
          PrintWriter out = response.getWriter();
          out.println(strOutput);
          out.close();
      }
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        throw new ServletException(e);
      }
}
    
    private void sendEmail(String adClientID, String adOrgID, String adUserID, VariablesSecureApp vars) throws Exception {
        EmailManager em = new EmailManager();
        Session sess = em.newMailSession(this, adClientID, adOrgID);
        
        if(MfaEmailCodeData.isSendingAllowed(this, adUserID).equals("f")) {
            throw new Exception("@mfa_ErrorSendOnlyOnePerMinute@");
        }
        
        // get email receiver
        String email_to = MfaEmailCodeData.getReceiverEmail(this, adUserID);
        if(email_to.isEmpty()) {
            throw new Exception ("@mfa_ErrorNoEmail@");
        }

        // get email sender
        String email_from = MfaEmailCodeData.getSenderEmail(this, adClientID);

        Random rand = new Random();
        String verificationCode = "";
        for(int i = 0; i < 6; i++) {
            verificationCode = verificationCode + rand.nextInt(10);
        }
        
        String emailSubject = Utility.messageBD(this, "mfa_verificationCodeEmailSubject",vars.getLanguage());
        String emailBody = Utility.messageBD(this, "mfa_verificationCodeEmailBody",vars.getLanguage()).replaceAll("@CODE@", verificationCode);
        
        try {
            em.sendSimpleEmail(sess, email_from, email_to, "", emailSubject, emailBody, "");
        }catch (Exception e) {
            throw new Exception ("@mfa_ErrorEmailFailed@" + " " + e.getMessage());
        }
        
        MfaEmailCodeData.setVerificationCode(this, FormatUtilities.sha1Base64(verificationCode), adUserID, adUserID);     
    }

    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

