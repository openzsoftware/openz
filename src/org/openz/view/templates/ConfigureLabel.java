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
import org.openz.util.FileUtils;
import org.openz.util.LocalizationUtils;
import org.openz.view.FormDisplayLogicData;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

public class ConfigureLabel {
 
  
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,String fieldname,String classname,  String labeltext, String elementId,String Style) throws Exception{
    StringBuilder retval= new StringBuilder();
    String text=labeltext;
    
    if (text.equals("")){
      if (elementId.equals(""))
        text = LocalizationUtils.getElementTextByElementName(servlet, fieldname, vars.getLanguage());
      else
        text = LocalizationUtils.getElementTextById(servlet, elementId, vars.getLanguage());
    }
    final String directory= servlet.strBasePath;
    Object template =  servlet.getServletContext().getAttribute("labelTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Label.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("labelTEMPLATE", template);
    }
    retval.append(template.toString());
    Replace.replace(retval, "@LABELTEXT@", text);
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@STYLE@", "");
    Replace.replace(retval, "@CLASS@", classname);
    Replace.replace(retval, "@NUMCOLS@", "1");
    return retval;
  }
  
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,String fieldname,String classname,  String labeltext, String elementId,int colstotal,String Style) throws Exception{
    StringBuilder retval= new StringBuilder();
    String text=labeltext;
    
    if (text.equals("")){
      if (elementId.equals(""))
        text = LocalizationUtils.getElementTextByElementName(servlet, fieldname, vars.getLanguage());
      else
        text = LocalizationUtils.getElementTextById(servlet, elementId, vars.getLanguage());
    }
    final String directory= servlet.strBasePath;
    Object template =  servlet.getServletContext().getAttribute("labelTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Label.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("labelTEMPLATE", template);
    }
    retval.append(template.toString());
    Replace.replace(retval, "@LABELTEXT@", text);
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@CLASS@", classname);
    Replace.replace(retval, "@STYLE@", "");
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal));
    return retval;
  }
  
  public static StringBuilder doConfigureLink(HttpSecureAppServlet servlet,VariablesSecureApp vars,String fieldname,String classname,  String labeltext, String adReferenceId, String adTableID, String elementId,String Style) throws Exception{
    StringBuilder retval= new StringBuilder();
    String text=labeltext;
    String search=fieldname;
    String adTabId="";
    if (adTableID!=null){
      if (adTableID!="")
        adTabId=adTableID;
    } else {
        if (adReferenceId!=null)
          if (adReferenceId!="")
            search=adReferenceId;  
         adTabId=FormDisplayLogicData.ReferenceGetTableID(servlet,search);
      }
    String link ="";
    if (text.equals("")){
      if (elementId.equals(""))
        text = LocalizationUtils.getElementTextByElementName(servlet, fieldname, vars.getLanguage());
      else
        text = LocalizationUtils.getElementTextById(servlet,elementId , vars.getLanguage());
    }
    if (! adTabId.equals("")) {
       link ="<a class=\"LabelLink\" onmouseout=\"return true;\" onmouseover=\"return true;\" onclick=\"sendDirectLink(document.frmMain, '" + fieldname + "', '', '../utility/ReferencedLink.html', document.frmMain.inp" + fieldname + ".value, '" + adTabId + "', '_self', true);return false;\" href=\"#\">";
       link=link + text + "</a>";
    } else
      link=text;
    final String directory= servlet.strBasePath;
    Object template =  servlet.getServletContext().getAttribute("labelTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("Label.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("labelTEMPLATE", template);
    }
    retval.append(template.toString());
    Replace.replace(retval, "@LABELTEXT@", link);
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@CLASS@", classname);
    Replace.replace(retval, "@STYLE@", "");
    Replace.replace(retval, "@NUMCOLS@", "1");
    return retval;
  }
    
}
