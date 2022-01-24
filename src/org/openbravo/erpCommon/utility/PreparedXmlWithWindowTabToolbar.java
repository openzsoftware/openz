/*
***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 
Wrapper to Prepare Window and Toolbar in a more comfortable way.

Only one  Constructor, 
 
 */
package org.openbravo.erpCommon.utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.xmlEngine.XmlEngine;

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.base.secureApp.ClassInfoData;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.OBError;

import org.openbravo.erpCommon.businessUtility.WindowTabs;

public class PreparedXmlWithWindowTabToolbar   {
  private XmlDocument xmlDocument;
   public PreparedXmlWithWindowTabToolbar(String url,String filename,String classname,String packagename, 
                                          String discard[],VariablesSecureApp vars,String replacewith,ClassInfoData classinfo, 
                                          ConnectionProvider conn,XmlEngine xmlEngine) throws Exception {
     xmlDocument = new XmlDocument();
     //example: readXmlTemplate("org/openbravo/erpCommon/ad_reports/ReportSalesDimensionalAnalyzeJRFilter"...
     xmlDocument=xmlEngine.readXmlTemplate(url, discard).createXmlDocument();
     // example: new ToolBar(conn,vars.getLanguage(),"ReportSalesDimensionalAnalyzeJRFilter", false, "", "", "", false, "ad_reports", strReplaceWith, false, true);
     ToolBar toolbar =  new ToolBar(conn, vars.getLanguage(),
         filename.substring(0, filename.indexOf(".")), false, "", "", "", false, packagename,
         replacewith, false, true);
     toolbar.prepareSimpleToolBarTemplate();
     xmlDocument.setParameter("toolbar", toolbar.toString());
     toolbar.prepareSimpleToolBarTemplate();
     xmlDocument.setParameter("toolbar", toolbar.toString());
     // example WindowTabs tabs = new WindowTabs(conn, vars,"org.openbravo.erpCommon.ad_reports.ReportSalesDimensionalAnalyzeJR");
     WindowTabs tabs = new WindowTabs(conn, vars,classname);
     xmlDocument.setParameter("parentTabContainer", tabs.parentTabs());
     xmlDocument.setParameter("mainTabContainer", tabs.mainTabs());
     xmlDocument.setParameter("childTabContainer", tabs.childTabs());
     xmlDocument.setParameter("theme", vars.getTheme());
     // filename-example: ReportSalesDimensionalAnalyzeJRFilter.html
     NavigationBar nav = new NavigationBar(conn, vars.getLanguage(),filename, classinfo.id, classinfo.type,
         replacewith, tabs.breadcrumb());
     xmlDocument.setParameter("navigationBar", nav.toString());
     LeftTabsBar lBar = new LeftTabsBar(conn, vars.getLanguage(),filename, replacewith);
     xmlDocument.setParameter("leftTabs", lBar.manualTemplate());
     OBError myMessage = vars.getMessage(classname);
     vars.removeMessage(classname);
     if (myMessage != null) {
       xmlDocument.setParameter("messageType", myMessage.getType());
       xmlDocument.setParameter("messageTitle", myMessage.getTitle());
       xmlDocument.setParameter("messageMessage", myMessage.getMessage());
     }  
     xmlDocument.setParameter("calendar", vars.getLanguage().substring(0, 2));
     xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
     xmlDocument.setParameter("directory", "var baseDirectory = \"" + replacewith + "/\";\n");
   }
   
   public XmlDocument getxmlDocument(){
     return xmlDocument;
   }
}
