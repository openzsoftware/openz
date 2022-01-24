/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 */

package org.zsoft.cockpit;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.erpCommon.utility.LeftTabsBar;
import org.openbravo.erpCommon.utility.NavigationBar;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.dal.core.OBContext;
import org.zsoft.ecommerce.businesspartner.CustomerV2;

public class SalesCockpit extends HttpSecureAppServlet {
	private static final long serialVersionUID = 1L;

	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
		ServletException {
		VariablesSecureApp vars = new VariablesSecureApp(request);
        XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/zsoft/cockpit/SalesCockpit").createXmlDocument();
        xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
        xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
        xmlDocument.setParameter("Theme", vars.getTheme().substring(4));
        ToolBar toolbar = new ToolBar(this, vars.getLanguage(), "ShowSessionPreferences", false, "",
            "", "", false, "ad_forms", strReplaceWith, false, true);
        toolbar.prepareSimpleToolBarTemplate();
        xmlDocument.setParameter("toolbar", toolbar.toString());
		try {
			WindowTabs tabs = new WindowTabs(this, vars,"org.openbravo.erpCommon.ad_forms.ShowSessionPreferences");
			xmlDocument.setParameter("theme", vars.getTheme());
			NavigationBar nav = new NavigationBar(this, vars.getLanguage(),
		    "ShowSessionPreferences.html", classInfo.id, classInfo.type, strReplaceWith, tabs.breadcrumb());
			xmlDocument.setParameter("navigationBar", nav.toString());
			LeftTabsBar lBar = new LeftTabsBar(this, vars.getLanguage(), "ShowSessionPreferences.html", strReplaceWith);
			xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
		} catch (Exception ex) {
		    throw new ServletException(ex);
		}
		{
			OBError myMessage = vars.getMessage("ShowSessionPreferences");
			vars.removeMessage("ShowSessionPreferences");
			if (myMessage != null) {
			      xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
			      xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
			      xmlDocument.setParameter("theme", vars.getTheme());
			}
		}
		SalesCockpitData[] data = SalesCockpitData.select(this);
		String script="function GetChartData(){ " +
		    "var chartData = [" + data[0].turnover.toString() + "," +
		    				      data[0].turnoverRunrate.toString() + "," +
								  data[0].offers.toString() + "," +
								  data[0].orders.toString() + "," +
		                          data[0].ordersRunrate.toString() + "," +
		                          data[0].backorder.toString() + "," +
		                          data[0].backorderRunrate.toString() + "," +
		                          data[0].forecast.toString() + "," +
		                          data[0].payable.toString() + "," +
		                          data[0].receivable.toString() +
		    "];" +
		        "return chartData;" +
		    "}" ;
		xmlDocument.setParameter("getChartData",script);
		response.setContentType("text/html; charset=UTF-8");
	    PrintWriter out = response.getWriter();
	    out.println(xmlDocument.print());
	    out.close();
}
public String getServletInfo() {
	return "Servlet Sales Cockpit";
}
}
