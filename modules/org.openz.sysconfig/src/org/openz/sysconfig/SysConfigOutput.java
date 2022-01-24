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

public class SysConfigOutput  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
      Scripthelper script= new Scripthelper();
      response.setContentType("text/html; charset=UTF-8");

      try{
        //Initializing the Fieldgroups
        String strsysconfigoutputfg=""; //Navigation Fieldgroup (Barcode Field and Buttons)

        String strmsg = Utility.messageBD(this, "SC_sysconfigoutput",vars.getLanguage());
        
        //Initializing the Template Structure
        String strSkeleton=""; //Structure
        String strOutput ="" ; //The html-code as Output

        String strback = "/org.openz.sysconfig.ad_forms/SysConfigOutput.html";
        
        String strname = vars.getSessionValue("name");
        String strlanguage = vars.getSessionValue("language");
        String stremail = vars.getSessionValue("email");
        String straddress = vars.getSessionValue("address");
        String strpostalcode = vars.getSessionValue("postalcode");
        String strcity = vars.getSessionValue("city");
        String strcountry = vars.getSessionValue("country");
        String strcalendar = vars.getSessionValue("calendar");
        String stracctschema = vars.getSessionValue("acctschema");
        String strcurrency = vars.getSessionValue("currency");
        String strtax = vars.getSessionValue("tax");
        String strtaxincluded = vars.getSessionValue("taxincluded");
        
        String sLanguage = SysconfigData.selectLanguage(this, strlanguage);
        
        String sCountry = SysconfigData.selectCountry(this, strcountry);
        
        String sCalendar = SysconfigData.selectCalendar(this, strcalendar);
        
        String sAcctschema = SysconfigData.selectAcctschema(this, stracctschema);
        
        String sCurrency = SysconfigData.selectCurrency(this, strcurrency);
        
        String sTax = SysconfigData.selectTax(this, strtax);
        
        String sTaxincluded;
        
        if(strtaxincluded.equals("Y")) {
        	sTaxincluded="Ja";
        } else {
        	sTaxincluded="Nein";
        }

        String strsysconfigoutput = "<table class=\"Output\" style=\"font-size: 15pt;\">" + 
        		"            <tr><td>Name:</td><td></td><td>" + strname + "</td></tr>" + 
        		"            <tr><td>Email:</td><td></td><td>" + stremail + "</td></tr>" + 
        		"            <tr><td>Sprache:</td><td></td><td>" + sLanguage + "</td></tr>" + 
        		"            <tr><td>Adresse:</td><td></td><td>" + straddress + " - " + strpostalcode + " " + strcity + " - " + sCountry + "</td></tr>" + 
        		"            <tr><td>Buchungsperioden:</td><td></td><td>" + sCalendar + "</td></tr>" + 
        		"            <tr><td>Kontierungsschema:</td><td></td><td>" + sAcctschema + "</td></tr>" + 
        		"            <tr><td>Währung:</td><td></td><td>" + sCurrency + "</td></tr>" + 
        		"            <tr><td>Steuersatz:</td><td></td><td>" + sTax + "</td></tr>" + 
        		"            <tr><td>Incl. Steuer:</td><td></td><td>" + sTaxincluded + "</td></tr>" + 
        		"        </table>";
        
        
        if (vars.commandIn("DONE")){
            String data = SysconfigData.orgCreate(this, strname, strlanguage, stremail, straddress, strpostalcode, strcity, strcountry, strcalendar, stracctschema, strtax, strcurrency, strtaxincluded);
            if (data != null){
            	
            }
            response.sendRedirect(strDireccion + "/org.openz.sysconfig.ad_forms/Logout.html");
        }

        if (vars.commandIn("LAST")){
        	response.sendRedirect(strDireccion + "/org.openz.sysconfig.ad_forms/Tax.html");
        }
        
        if (vars.commandIn("CANCEL")){
        	response.sendRedirect(strDireccion + "/org.openz.sysconfig.ad_forms/Warning.html");
        	vars.setSessionValue("back", strback);
        }
		
        String strokname = vars.getSessionValue("okname");
        String strokemail = vars.getSessionValue("okemail");
        String stroklanguage = vars.getSessionValue("oklanguage");
        String strokaddress = vars.getSessionValue("okaddress");
        String strokcalendar = vars.getSessionValue("okcalendar");
        String strokacctschema = vars.getSessionValue("okacctschema");
        String strokcurrency = vars.getSessionValue("okcurrency");
        String stroktax = vars.getSessionValue("oktax");
        
        String strbreadcrump = "<table style=\"margin: 0% 10px -9% 0%;text-align: left;float: right;color: #606060;font-size: 9pt;\">"
        		+ "<tr><td>" + strokname + "</td><td>Firmenname</td></tr>"
        		+ "<tr><td>" + strokemail + "</td><td>Email</td></tr>"
        		+ "<tr><td>" + stroklanguage + "</td><td>Sprache</td></tr>"
        		+ "<tr><td>" + strokaddress + "</td><td>Adresse</td></tr>"
        		+ "<tr><td>" + strokcalendar + "</td><td>Buchungsperioden</td></tr>"
        		+ "<tr><td>" + strokacctschema + "</td><td>Kontierungsschema</td></tr>"
        		+ "<tr><td>" + strokcurrency + "</td><td>Währung</td></tr>"
        		+ "<tr><td>" + stroktax + "</td><td>Steuer</td></tr>"
        		+ "<tr style=\"color: black\"><td>→</td><td>Zusammenfassung</td></tr>"
        		+ "</table>";
        
        
        
        StringBuilder lastBtn = ConfigureButton.doConfigure(this, vars, script, "last", 0, 1, false, "last", "submitCommandForm('LAST', true, null, null, '_self') ", "", "CE353471CEBF4FE98DF9D1C0F16BA294");
        StringBuilder doneBtn = ConfigureButton.doConfigure(this, vars, script, "done", 0, 1, false, "done", "submitCommandForm('DONE', true, null, null, '_self') ", "", "97099B8D6F964677B62D9DB702F3ADCD");
        StringBuilder cancelBtn = ConfigureButton.doConfigure(this, vars, script, "cancel", 0, 1, false, "cancel", "submitCommandForm('CANCEL', true, null, null, '_self') ", "", "E1D2DCDC38B74C60807C51E918E76C3A");
        
        if (strname.equals("") || stremail.equals("") || straddress.equals("") || strpostalcode.equals("") || strcity.equals("")){
//        	doneBtn = new StringBuilder("&nbsp;");
        	doneBtn = ConfigureButton.doConfigure(this, vars, script, "done", 0, 1, true, "done", "submitCommandForm('DONE', true, null, null, '_self') ", "", "97099B8D6F964677B62D9DB702F3ADCD");
        	strmsg = "<b>Anlegen der Organisation nicht möglich.<br></b>"
        			+ "Bitte füllen Sie alle Felder aus.";
        }
        
        String strinfo = "<div class=\"info\" style=\"margin: -2% 0 0 33%;font-size: 1.3vw; color:#404040;\">"
        		+ "<p>" + strmsg + "</p>"
        		+ "</div>";
        
        String strOwnBtn = "<table class=\"ownbtn\">"
        		+ "<tr class=\"ownbtn1\">" + doneBtn + "</tr>"
        		+ "<tr class=\"ownbtn2\">" + lastBtn + "</tr>"
        		+ "<tr class=\"ownbtn3\">" + cancelBtn + "</tr>"
        		+ "</table>";

        //Declaring the toolbar (Default no toolbar)
        String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
        
        //Window Tabs (Default Declaration)
        WindowTabs tabs;                  //The Servlet Name generated automatically
        tabs = new WindowTabs(this, vars, this.getClass().getName());
        
        //Configuring the Structure                                                   Title of Site  Toolbar  
        strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inpsysconfigoutput",null, "Initial SysConfigOutput",strToolbar,"NONE",tabs);
       
        //Calling the Formhelper to Configure the Data inside the Servlet
        Formhelper fh=new Formhelper();

        //Saving the Fieldgroups into Variables
        //Navigation Fieldgroup
        strsysconfigoutputfg=fh.prepareFieldgroup(this, vars, script, "SC_sysconfigoutput_fg", null,false);

        //Generating the html output - Replacing the @Content@ with called areas in this case INFOBAR, NAVIGATION, STATUS
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",strbreadcrump + strsysconfigoutput + strsysconfigoutputfg + strOwnBtn + strinfo);
        
        // Enable Shortcuts
        script.addHiddenShortcut("linkButtonSave_New");
        script.enableshortcuts("EDITION");
        
        script.addJScript("function funcOutput(){"
        		+ "document.getElementsByClassName(\'Output\')[0].style.margin = \"2% 0 0 32.9%\";"
        		+ "document.getElementsByClassName(\"ownBtn\")[0].style.margin = \"0% 0% 0% 32.1%\";"
        		+ "document.getElementById(\"lasttd\").style.margin = \"-26% 0% 0% 93%\";"
        		+ "document.getElementById(\"last\").style.width = \"120px\";"
        		+ "document.getElementById(\"canceltd\").style.margin = \"-48% 0% 0% 325%\";"
        		+ "document.getElementById(\"cancel\").style.width = \"120px\";"
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

