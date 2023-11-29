/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Stefan Zimmermann.
***************************************************************************************************************************************************
*/
package org.openbravo.base.secureApp;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.*;

public class Mfa_Logout  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
      Scripthelper script= new Scripthelper();
      response.setContentType("text/html; charset=UTF-8");

      try{
        //Initializing the Fieldgroups
        String strlogoutfg=""; //Navigation Fieldgroup (Barcode Field and Buttons)
        
        String strmsg = "";
        if(vars.getSessionValue("MFA_LOGOUT_REASON", "").equals("EmailCode")) {
            strmsg = Utility.messageBD(this, "Mfa_Logout_after_auth",vars.getLanguage());
        }else if(vars.getSessionValue("MFA_LOGOUT_REASON", "").equals("ChangeOTPassword")) {
            strmsg = Utility.messageBD(this, "Mfa_Logout_Changed_Password",vars.getLanguage());
        }
        
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output
        String strButtonsFG="";

        String strinfo = "<div class=\"info\" style=\"margin: 1% 0 0 33%;font-size: 15pt; color:#404040;\">"
        		+ "<p>" + strmsg + "</p>"
        		+ "</div>";

        //Configuring the Structure                                                   Title of Site  Toolbar  
        strSkeleton = ConfigureFrameWindow.doConfigureApp(this, vars, "inplogout", null, "Initial Logout", "", "REMOVED" , null, "true");
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();
        
        //Saving the Fieldgroups into Variables
        //Navigation Fieldgroup
        strlogoutfg=fh.prepareFieldgroup(this, vars, script, "SC_logout_fg", null,false);
        
        //Button Fieldgroup
        strButtonsFG=fh.prepareFieldgroup(this, vars, script, "SC_sysconfigbuttons_fg", null,false);

        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",strlogoutfg + strButtonsFG + strinfo);
        
        // Enable Shortcuts
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");
        
        script.addJScript("function funcName(){"
                + "document.getElementsByClassName(\'Form_Table\')[0].style.margin = \"2% 0 0 29%\";"
                + "document.getElementById(\"logout\").style.margin = \"10px 0% 0% 32.1%\";"
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

