/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.openz.bommanagement.bomimport;




import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;

import org.openbravo.erpCommon.businessUtility.TabAttachmentsData;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFileUploadPopup;
import org.openz.view.templates.ConfigurePopup;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;




public class ImportProductBom extends HttpSecureAppServlet {

	  private static final long serialVersionUID = 1L;
	  
	  
	  public void init(ServletConfig config) {
	    super.init(config);
	    boolHist = false;
	  }
	  
	  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
	  ServletException {
		//@TODO
		/*
		* This is a prototype of file Upload Popup in a window TAB
		 * If BOM creation in a product is required, this class has to be finished.
		*/  
	    // Initialize global structure
	    VariablesSecureApp vars = new VariablesSecureApp(request);
	    Scripthelper script = new Scripthelper(); // Injects Javascript, hidden fields, etc into the generated html
	    Formhelper fh = new Formhelper();         // Injects the styles of fields, grids, etc
	    String strOutput = "" ;                   // Resulting html output
	   
	    String strActionButtons="";               // Bottom Fieldgroup (defined in AD)
	    Boolean reload=false;
	    String message=null ;
	  
	    if (vars.commandIn("SAVE")) {
	      try {
	       
	        message = Utility.messageBD(this, "BPARTNERUPD_SUCESS", vars.getLanguage());
	        advisePopUpRefresh(request, response, "SUCCESS", "Process Request", message);
	      } catch (Exception e) {
	        log4j.error("Error in: " + this.getClass().getName() +"\n" + e.getMessage());
	        e.printStackTrace();
	        message=e.getMessage();
	        reload=true;
	      }
	    }
	    if (vars.getCommand().equals("DEFAULT")||reload) {
	    try {
	      
	     // strOutput=Replace.replace(strOutput,"ActionButton_Responser.html", "BPartnerFastEntryProcess.html");
	     // Focus on Employees
	    
	    	strOutput = ConfigureFileUploadPopup.doConfigure(this,vars,script,"BOM Import","firstname","label","key","../ad_process/BOMImportProcess.html","SAVE");
	    	if (message!=null)
	            script.addMessage(this, vars, Utility.translateError(myPool, vars, vars.getLanguage(), message));
	    	strOutput = script.doScript(strOutput, "",this,vars);
	    	response.setContentType("text/html; charset=UTF-8");
	        PrintWriter out = response.getWriter();
	        out.println(strOutput);
	        out.close();
	   
	    }
	    catch (Exception e) { 
	        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
	        e.printStackTrace();
	        throw new ServletException(e);
	    }}
	    
	    
	  }
	 
	  public String getServletInfo() {
	    return this.getClass().getName();
	  } 
	}
