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
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.*;

public class Warning  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
      Scripthelper script= new Scripthelper();
      response.setContentType("text/html; charset=UTF-8");

      try{        
        String strwarningfg=""; //Navigation Fieldgroup (Barcode Field and Buttons)
        
        String strmsg = Utility.messageBD(this, "SC_warning",vars.getLanguage());
        
        

        String strback = vars.getSessionValue("back");
        
        
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output
        
        String strinfo = "<div class=\"info\" style=\"margin: 2% 0 0 33%;font-size: 1.3vw; color:#404040;\">"
        		+ "<p>" + strmsg + "</p>"
        		+ "</div>";

        String strcancelbtn = "<a style=\"" + 
        		"	background-color:#900202;\n" + 
        		"	display:inline-block;\n" + 
        		"	cursor:pointer;\n" + 
        		"	color:#ffffff;\n" + 
        		"	font-family:Arial;\n" + 
        		"	font-size:20px;\n" + 
        		"	font-weight:bold;\n" + 
        		"	padding:6px 12px;\n" +
        		"	margin: 0 0 0 0.5%;\n" +
        		"	text-decoration:none;\"onclick=\"submitCommandForm('CANCEL', true, null, null, '_self')\">Ja. Ich bin mir sicher.</a>";

        if (vars.commandIn("CANCEL")){
        	Integer data = SysconfigData.updateSTDServlet(this, "32BB190E7B4846E8AA0F1847BD4444BE");
        	if (data!= null){
            	
            }
        	data = SysconfigData.updateSTDMenuServlet(this, "32BB190E7B4846E8AA0F1847BD4444BE");
        	if (data!= null){
            	
            }
        	
        	data = SysconfigData.insertPreference(this, vars.getClient(), vars.getOrg());
                	if (data!= null){
                		
                    }
        	response.sendRedirect(strDireccion + "/org.openz.sysconfig.ad_forms/CancelLogout.html");
        }
        
        String strreturnbtn = "<a style=\"" + 
        		"	background-color:#1b4106;\n" + 
        		"	display:inline-block;\n" + 
        		"	cursor:pointer;\n" + 
        		"	color:#ffffff;\n" + 
        		"	font-family:Arial;\n" + 
        		"	font-size:20px;\n" + 
        		"	font-weight:bold;\n" + 
        		"	padding:6px 12px;\n" +
        		"	margin: 0 0 0 33%;\n" +
        		"	text-decoration:none;\"onclick=\"submitCommandForm('DONE', true, null, null, '_self')\">Nein. Ich möchte fortfahren.</a>";
        
        if (vars.commandIn("DONE")){
        	response.sendRedirect(strDireccion + strback);
        }
        
        //Declaring the toolbar (Default no toolbar)
        String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
        
        //Window Tabs (Default Declaration)
        WindowTabs tabs;                  //The Servlet Name generated automatically
        tabs = new WindowTabs(this, vars, this.getClass().getName());
        
        //Configuring the Structure                                                   Title of Site  Toolbar  
        strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inpwarning",null, "Initial Warning",strToolbar,"NONE",tabs);
       
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();
        
        //Saving the Fieldgroups into Variables
        //Navigation Fieldgroup
        strwarningfg=fh.prepareFieldgroup(this, vars, script, "SC_warning_fg", null,false);
        
        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",strwarningfg + strinfo + strreturnbtn + strcancelbtn);
        
        // Enable Shortcuts
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");
        
        script.addJScript("function funcOutput(){"
        		+ "document.getElementsByClassName(\'Output\')[0].style.margin = \"2% 0 0 32.9%\";"
        		+ "document.getElementsByClassName(\'Form_Table\')[0].style.margin = \"0 0 0 32.2%\";"
        		+ "document.getElementById(\"donetd\").style.margin = \"0% 0% 0% -70%\";"
        		+ "document.getElementById(\"canceltd\").style.margin = \"0% 0% 0% -113%\";"
        		+ "};");
        
        script.addOnload("funcOutput();");
        
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

