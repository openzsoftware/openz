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
package org.openz.sysconfig;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.*;

public class Language  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
      Scripthelper script= new Scripthelper();
      response.setContentType("text/html; charset=UTF-8");

      try{
    	String strlanguage = vars.getStringParameter("inplanguage");
    	
    	String strchecklang = vars.getSessionValue("language");
    	
    	if (strchecklang.equals("")) {
    		vars.setSessionValue(getServletInfo() + "|language", "de_DE");
    	}
    	
    	String strback = "/org.openz.sysconfig.ad_forms/Language.html";

        //Initializing the Fieldgroups
        String strlanguagefg=""; //Navigation Fieldgroup (Barcode Field and Buttons)
        
        String strmsg = Utility.messageBD(this, "SC_language",vars.getLanguage());
        
        String stroklanguage="";
        
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output

        vars.setSessionValue("language", strlanguage);

        if (vars.commandIn("NEXT")){
            response.sendRedirect(strDireccion + "/org.openz.sysconfig.ad_forms/Address.html");
            vars.setSessionValue(getServletInfo() + "|language", strlanguage);
            
            if(strlanguage.equals("")) {
            	stroklanguage = "<p style=\"color: red;\">X</p>";
            }else {
            	stroklanguage = "<p style=\"color: green;\">OK</p>";
            }
            
            vars.setSessionValue("oklanguage", stroklanguage);
            vars.setSessionValue(getServletInfo() + "|oklanguage", stroklanguage);
        }
 
        if (vars.commandIn("LAST")){
        	response.sendRedirect(strDireccion + "/org.openz.sysconfig.ad_forms/Email.html");
        	vars.setSessionValue(getServletInfo() + "|language", strlanguage);
        	
        	if(strlanguage.equals("")) {
            	stroklanguage = "<p style=\"color: red;\">X</p>";
            }else {
            	stroklanguage = "<p style=\"color: green;\">OK</p>";
            }
            
            vars.setSessionValue("oklanguage", stroklanguage);
            vars.setSessionValue(getServletInfo() + "|oklanguage", stroklanguage);
        }
        
        if (vars.commandIn("CANCEL")){
        	response.sendRedirect(strDireccion + "/org.openz.sysconfig.ad_forms/Warning.html");
        	vars.setSessionValue("back", strback);
        }
        
        String strokname = vars.getSessionValue("okname");
        String strokemail = vars.getSessionValue("okemail");
        String strokaddress = vars.getSessionValue("okaddress");
        String strokcalendar = vars.getSessionValue("okcalendar");
        String strokacctschema = vars.getSessionValue("okacctschema");
        String strokcurrency = vars.getSessionValue("okcurrency");
        String stroktax = vars.getSessionValue("oktax");
        
        String strbreadcrump = "<table style=\"margin: 0% 10px -9% 0%;text-align: left;float: right;color: #606060;font-size: 9pt;\">"
        		+ "<tr><td>" + strokname + "</td><td>Firmenname</td></tr>"
        		+ "<tr><td>" + strokemail + "</td><td>Email</td></tr>"
        		+ "<tr style=\"color: black\"><td>→</td><td>Sprache</td></tr>"
        		+ "<tr><td>" + strokaddress + "</td><td>Adresse</td></tr>"
        		+ "<tr><td>" + strokcalendar + "</td><td>Buchungsperioden</td></tr>"
        		+ "<tr><td>" + strokacctschema + "</td><td>Kontierungsschema</td></tr>"
        		+ "<tr><td>" + strokcurrency + "</td><td>Währung</td></tr>"
        		+ "<tr><td>" + stroktax + "</td><td>Steuer</td></tr>"
        		+ "<tr><td></td><td>Zusammenfassung</td></tr>"
        		+ "</table>";
        
        String strinfo = "<div class=\"info\" style=\"margin: -2% 0 0 33%;font-size: 1.3vw; color:#404040;\">"
        		+ "<p>" + strmsg + "</p>"
        		+ "</div>";
        
        StringBuilder nextBtn = ConfigureButton.doConfigure(this, vars, script, "next", 0, 1, false, "next", "submitCommandForm('NEXT', true, null, null, '_self') ", "", "9E02640A437D409CBD41E5DC6CE20AC7");
        StringBuilder lastBtn = ConfigureButton.doConfigure(this, vars, script, "last", 0, 1, false, "last", "submitCommandForm('LAST', true, null, null, '_self') ", "", "CE353471CEBF4FE98DF9D1C0F16BA294");
        StringBuilder cancelBtn = ConfigureButton.doConfigure(this, vars, script, "cancel", 0, 1, false, "cancel", "submitCommandForm('CANCEL', true, null, null, '_self') ", "", "E1D2DCDC38B74C60807C51E918E76C3A");

        String strOwnBtn = "<table class=\"ownbtn\">"
        		+ "<tr class=\"ownbtn1\">" + nextBtn + "</tr>"
        		+ "<tr class=\"ownbtn2\">" + lastBtn + "</tr>"
        		+ "<tr class=\"ownbtn3\">" + cancelBtn + "</tr>"
        		+ "</table>";
        
        //Declaring the toolbar (Default no toolbar)
        String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
        
        //Window Tabs (Default Declaration)
        WindowTabs tabs;                  //The Servlet Name generated automatically
        tabs = new WindowTabs(this, vars, this.getClass().getName());
        
        //Configuring the Structure                                                   Title of Site  Toolbar  
        strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inplanguage",null, "Initial Language",strToolbar,"NONE",tabs);
       
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();

        //Saving the Fieldgroups into Variables
        //Navigation Fieldgroup
        strlanguagefg=fh.prepareFieldgroup(this, vars, script, "SC_language_fg", null,false);

        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",strbreadcrump + strlanguagefg + strOwnBtn  + strinfo);
        
        // Enable Shortcuts
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");
        
        script.addJScript("function funcLanguage(){"
        		+ "document.getElementsByClassName(\'Form_Table\')[0].style.margin = \"2% 0 0 -12%\";"
        		+ "document.getElementsByClassName(\'Label\')[0].style.fontSize = \"15pt\";"
        		+ "document.getElementsByClassName(\'Celltable\')[0].style.width = \"500px\";"
        		+ "document.getElementById(\"language\").style.height = \"26px\";"
        		+ "document.getElementById(\"language\").style.fontSize = \"15pt\";"
        		+ "document.getElementsByClassName(\"ownBtn\")[0].style.margin = \"0% 0% 0% 32.1%\";"
        		+ "document.getElementById(\"lasttd\").style.margin = \"-26% 0% 0% 93%\";"
        		+ "document.getElementById(\"last\").style.width = \"120px\";"
        		+ "document.getElementById(\"canceltd\").style.margin = \"-48% 0% 0% 325%\";"
        		+ "document.getElementById(\"cancel\").style.width = \"120px\";"
        		+ "};");
        
        script.addOnload("funcLanguage();");
        
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

