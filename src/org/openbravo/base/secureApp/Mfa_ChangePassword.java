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
import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.erpCommon.ad_forms.Role;
import org.openbravo.erpCommon.security.SessionLoginData;
import org.openbravo.utils.FormatUtilities;
import org.openbravo.utils.Replace;
import org.openz.util.UtilsData;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.*;

public class Mfa_ChangePassword  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
      Scripthelper script= new Scripthelper();
      response.setContentType("text/html; charset=UTF-8");

      try{
        String strpassword = vars.getStringParameter("inppassword");
        // illegal characters replace with space to trigger error
        strpassword = strpassword.replaceAll("&", " ").replaceAll("\\+", " ");
        String strpasswordConfirm = vars.getStringParameter("inppasswordconfirm");
        strpasswordConfirm = strpasswordConfirm.replaceAll("&", " ").replaceAll("\\+", " ");
        
        //Initializing the Fieldgroups
        String strnamefg=""; //Navigation Fieldgroup
        
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output
        
        final String adUserId = vars.getSessionValue("#AD_USER_ID");
        final String adOrgId = vars.getSessionValue("#AD_ORG_ID");
        final String adClientId = vars.getSessionValue("#AD_CLIENT_ID");
        final String lang = vars.getLanguage();
        
        String strmsg = Role.getGuidelinesText(this, adOrgId, lang, false);
        String strinfo = "<div class=\"info\" style=\"margin: 1% 0 0 33%;font-size: 15pt; color:#404040;\">"
                        + "<p>" + strmsg + "</p>"
                        + "</div>";

        if(vars.commandIn("CONFIRM")) {
            if(!SessionLoginData.isOneTimePassword(this, adUserId)) {
                vars.setSessionValue("MFA_LOGOUT_REASON", "ChangeOTPassword");
                response.sendRedirect(strDireccion + "/org.openbravo.base.secureApp.ad_forms/Mfa_Logout.html");
            }else if(!strpassword.equals(strpasswordConfirm)) {
                throw new Exception("@Mfa_PasswordMissmatch@");
            }else {
                Role.validatePassword(this, adOrgId, lang, strpassword);
                MfaChangePasswordData.setPassword(this, FormatUtilities.sha1Base64(strpassword), adUserId, adUserId);
                if(DefaultOptionsData.isMFAActivatedForUser(this, adUserId).equals("Y") && MfaChangePasswordData.getIsOTPEnteredManually(this, adUserId).equals("N")) { // if activated AND OTP was not entered manually set cookie
                    String uuid = UtilsData.getUUID(this);
                    String hash = UtilsData.getUUID(this);
                    Cookie kk = new Cookie("MFA_Cookie", hash);
                    hash = FormatUtilities.sha1Base64(hash);
                    // +12 hours so the cookie does not expire during working day
                    int lifetime = (Math.round(Float.parseFloat(MfaEmailCodeData.getCookieLifetime(this, adOrgId))) * 24 + 12) * 60 * 60; //to seconds
                    kk.setMaxAge(lifetime);
                    String strcon=request.getContextPath();
                    kk.setPath(strcon);
                    response.addCookie(kk);
                    
                    MfaEmailCodeData.setCookie(this, uuid, hash, String.valueOf(lifetime), adClientId, adOrgId, adUserId, adUserId, adUserId);
                }
                SeguridadData.resetOTPassword(this, adUserId, adUserId);
                MfaEmailCodeData.resetMFACode(this, adUserId, adUserId);
                vars.setSessionValue("MFA_LOGOUT_REASON", "ChangeOTPassword");
                response.sendRedirect(strDireccion + "/org.openbravo.base.secureApp.ad_forms/Mfa_Logout.html");
            }
        }
        
        // 3454E5088DB54B6ABF3924BF65B054B1 -> Save
        StringBuilder confirmBtn = ConfigureButton.doConfigure(this, vars, script, "confirm", 0, 1, false, "confirm", "submitCommandForm('CONFIRM', true, null, null, '_self') ", "", "3454E5088DB54B6ABF3924BF65B054B1");

        String strOwnBtn = "<table class=\"ownbtn\">"
        		+ "<tr class=\"ownbtn1\">" + confirmBtn.toString().replaceAll("type=\"button\"", "type=\"submit\"") + "</tr>" // confirm button on enter
        		+ "</table>";

        //Configuring the Structure                                                   Title of Site  Toolbar  
        //configureApp -> without left menu
        strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "inppassword", null, "Change Password", "", "REMOVED" , null, "true");
        
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();
        
        //Saving the Fieldgroups into Variables
        //Navigation Fieldgroup
        strnamefg=fh.prepareFieldgroup(this, vars, script, "Mfa_ChangePassword_fg", null,false);
        
        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@", strnamefg + strOwnBtn + strinfo);
        
        // Enable Shortcuts
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");

        script.addJScript("function funcName(){"
                + "document.getElementsByClassName(\'Form_Table\')[0].style.margin = \"2% 0 0 15%\";"
                + "document.getElementsByClassName(\'Label\')[0].style.fontSize = \"15pt\";"
                + "document.getElementsByClassName(\'Label\')[1].style.fontSize = \"15pt\";"
                + "document.getElementsByClassName(\'Label\')[1].style.margin = \"10px 0 0 0\";"
                + "document.getElementsByClassName(\'Celltable\')[0].style.width = \"500px\";"
                + "document.getElementsByClassName(\'Celltable\')[1].style.width = \"500px\";"
                + "document.getElementsByClassName(\'Celltable\')[1].style.margin = \"10px 0 0 0\";"
                + "document.getElementById(\"password\").style.height = \"26px\";"
                + "document.getElementById(\"password\").style.fontSize = \"15pt\";"
                + "document.getElementById(\"passwordconfirm\").style.height = \"26px\";"
                + "document.getElementById(\"passwordconfirm\").style.fontSize = \"15pt\";"
                + "document.getElementsByClassName(\"ownBtn\")[0].style.margin = \"10px 0% 0% 32.1%\";"
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

    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

