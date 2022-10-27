package org.openz.view.templates;
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

import org.openbravo.utils.Replace;
import org.openz.pdc.controller.PdcCommonData;
import org.openz.util.FileUtils;
import org.openz.util.LocalizationUtils;
import org.openz.view.*;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.*;


public class ConfigureFrameWindow {
 
  public static String doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,  String focusfield, String breadcrumb, String name,  String toolbarId,String leftTabsMode,WindowTabs tabs) throws Exception{
    return doConfigureWindowModeAll(servlet,vars,focusfield,breadcrumb,name,toolbarId,leftTabsMode,tabs,"",null,"false");
  }
  public static String doConfigureApp(HttpSecureAppServlet servlet,VariablesSecureApp vars,  String focusfield, String breadcrumb, String name,  String toolbarId,String leftTabsMode,WindowTabs tabs,String hideframes) throws Exception{
	    return doConfigureWindowModeAll(servlet,vars,focusfield,breadcrumb,name,toolbarId,leftTabsMode,tabs,"",null,hideframes);
	  }
  public static String doConfigureWindowMode(HttpSecureAppServlet servlet,VariablesSecureApp vars,  String focusfield, String breadcrumb, String name,  String toolbarId,String leftTabsMode,WindowTabs tabs, String WindowMode, String toolbarcodehtml) throws Exception{
	  return doConfigureWindowModeAll(servlet,vars,focusfield,breadcrumb,name,toolbarId,leftTabsMode,tabs,WindowMode,toolbarcodehtml,"false");
  }
  private static String doConfigureWindowModeAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,  String focusfield, String breadcrumb, String name,  String toolbarId,String leftTabsMode,WindowTabs tabs, String WindowMode, String toolbarcodehtml, String hideframes) throws Exception{
    StringBuilder retval= new StringBuilder();
    String scriptset="";
    String msgbox=""; 
    String formname=servlet.getClass().getName().substring(servlet.getClass().getName().lastIndexOf(".")+1,servlet.getClass().getName().length())+ WindowMode;
    String theme=vars.getTheme();
    String language=vars.getLanguage();
    String goback=LocalizationUtils.getMessageText(servlet, "GoBack", language);
    String abt=LocalizationUtils.getMessageText(servlet, "About", language);
    String refresh=LocalizationUtils.getMessageText(servlet, "Refresh", language);
    String title=LocalizationUtils.getWindowTitle(servlet, name, vars.getLanguage());
    final String directory= servlet.strBasePath;
    String leftTabsBar="";
    Object template; 
    if (leftTabsMode.equals("EDIT")) {
      template =  servlet.getServletContext().getAttribute("leftTabsEditTEMPLATE");
      if (template==null) {
        template = new String(FileUtils.readFile("LeftTabsEdit.xml", directory + "/src-loc/design/org/openz/view/templates/"));
        servlet.getServletContext().setAttribute("leftTabsEditTEMPLATE", template);
      }
      leftTabsBar=template.toString();
    }
    if (leftTabsMode.equals("RELATION")) {
      template =  servlet.getServletContext().getAttribute("leftTabsGridTEMPLATE");
      if (template==null) {
        template = new String(FileUtils.readFile("LeftTabsGrid.xml", directory + "/src-loc/design/org/openz/view/templates/"));
        servlet.getServletContext().setAttribute("leftTabsGridTEMPLATE", template);
      }
      leftTabsBar=template.toString();
    }
    if (leftTabsMode.equals("NONE")){
      template =  servlet.getServletContext().getAttribute("leftTabsEmptyTEMPLATE");
      if (template==null) {
        template = new String(FileUtils.readFile("LeftTabsEmpty.xml", directory + "/src-loc/design/org/openz/view/templates/"));
        servlet.getServletContext().setAttribute("leftTabsEmptyTEMPLATE", template);
      }
      leftTabsBar=template.toString();
    }
    String toolbar=toolbarcodehtml;
    if (toolbar==null) {
      template =  servlet.getServletContext().getAttribute("toolBarEmptyTEMPLATE");
      if (template==null) {
        template = new String(FileUtils.readFile("ToolBarEmpty.xml", directory + "/src-loc/design/org/openz/view/templates/"));
        servlet.getServletContext().setAttribute("toolBarEmptyTEMPLATE", template);
      }
      toolbar=template.toString();
    }
    if (toolbarId!= null)
      if (!toolbarId.equals(""))
      toolbar=Formhelper.prepareToolbar(servlet, vars, toolbarId);
    template =  servlet.getServletContext().getAttribute("frameWindowTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("FrameWindow.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("frameWindowTEMPLATE", template);
    }
    if (leftTabsMode.equals("REMOVED")) {
    	template =  servlet.getServletContext().getAttribute("frameWindowRemovedTEMPLATE");
        if (template==null) {
        	template = new String(FileUtils.readFile("FrameWindowNoLeftTab.xml", directory + "/src-loc/design/org/openz/view/templates/"));
        	servlet.getServletContext().setAttribute("frameWindowRemovedTEMPLATE", template);
        }
    }
    retval.append(template.toString());
    // On Hide Frames loads only OZ 4.0 Scripts are Loaded (No dojo and other old Libs)
    if (hideframes.equals("true")) {
    	template =  servlet.getServletContext().getAttribute("scriptsetMobileTEMPLATE");
	    if (template==null) {
	      template = new String(FileUtils.readFile("ScriptsetMobile.xml", directory + "/src-loc/design/org/openz/view/templates/"));
	      servlet.getServletContext().setAttribute("scriptsetMobileTEMPLATE", template);
	    }
    } else {
	    template =  servlet.getServletContext().getAttribute("scriptsetTEMPLATE");
	    if (template==null) {
	      template = new String(FileUtils.readFile("Scriptset.xml", directory + "/src-loc/design/org/openz/view/templates/"));
	      servlet.getServletContext().setAttribute("scriptsetTEMPLATE", template);
	    }
    }
    scriptset=template.toString();   
    template =  servlet.getServletContext().getAttribute("messageBoxTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("MessageBox.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("messageBoxTEMPLATE", template);
    }
    msgbox=template.toString();   
    Replace.replace(retval, "@SCRIPTSET@",scriptset);
    Replace.replace(retval, "@LEFTTABSBAR@",leftTabsBar);
    Replace.replace(retval, "@THEME@", theme);
    Replace.replace(retval, "@LANGUAGE@", language);
    Replace.replace(retval, "@FORMNAME@", formname);
    Replace.replace(retval, "@MESSAGEBOX@", msgbox);
    Replace.replace(retval, "@TOOLBAR@", toolbar);
    Replace.replace(retval, "@REFRESHTEXT@", refresh);
    Replace.replace(retval, "@ABOUTTEXT@", abt);
    Replace.replace(retval, "@GOBACKTEXT@", goback);
    String hideme="";
    // Hides all Frames in a Window
    if (hideframes.equals("true"))
    	hideme="menuHide('buttonMenu');return true;";
    Replace.replace(retval, "@HIDDENMODE@", hideme);
    
    String initHiddenFields="";
    String tabPane="";
    if (tabs!=null) {
      String parent= tabs.parentTabs();
      parent=Replace.replace(parent, "<SPAN class=\"tabTitle_elements_text\"></SPAN>","<SPAN class=\"tabTitle_elements_text\">" + title + "></SPAN>");
      String main=  tabs.mainTabs();
      String child= tabs.childTabs();
      tabPane="<TR id=\"paramParentTabContainer\">" + parent + "</TR>";
      tabPane=tabPane+ "<TR id=\"paramMainTabContainer\">" + main + "</TR>";
      tabPane=tabPane+ "<TR id=\"paramChildTabContainer\">" + child + "</TR>";
    } else {
        template =  servlet.getServletContext().getAttribute("tabBarEmptyTEMPLATE");
        if (template==null) {
          template = new String(FileUtils.readFile("TabBarEmpty.xml", directory + "/src-loc/design/org/openz/view/templates/"));
          servlet.getServletContext().setAttribute("tabBarEmptyTEMPLATE", template);
        }
        tabPane=template.toString();   
    }
    Replace.replace(retval, "@TABPANE@", tabPane);
    Replace.replace(retval, "@TITLE@", title);
    Replace.replace(retval, "@INITHIDDENFIELDS@", initHiddenFields);
    String berndthebread=breadcrumb;
    if (breadcrumb==null && tabs!=null){
      berndthebread=tabs.breadcrumb();
    }
    Replace.replace(retval, "@BREADCRUMB@", berndthebread );
    Replace.replace(retval, "@FOCUSFIELD@", focusfield );
    // Auto Logged in APP Mode - Remove Logout and Back, only Refresh is triggered.
    if ( PdcCommonData.isAutologin(servlet, vars.getUser()).equals("Y") && leftTabsMode.equals("REMOVED") && hideframes.equals("true")) {
    	Replace.replace(retval, "openNewBrowser('http://www.openbravo.com', 'Openbravo');", "");
    	Replace.replace(retval, "openNewBrowser('http://openz.de', 'OpenZ');", "");
    }
    return retval.toString();
  }

}
