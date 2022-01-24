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
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openz.view.SelectBoxhelper;
import org.openbravo.data.FieldProvider;
import org.openz.view.Scripthelper;

public class ConfigureListSorterSimple {
 
  
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String leftsidefieldname,String rightsidefieldname, int leadingemptycols,int colstotal,String leftcurrentvalue,String rightcurrentvalue,FieldProvider[] leftdata, String leftdataIDField,FieldProvider[] rightdata, String rightdataIDField,boolean readonly,String labelfieldname,String tooltip,String elementId) throws Exception{
    StringBuilder retval= new StringBuilder();
    final String directory= servlet.strBasePath;
    String strinclude=Utility.messageBD(servlet, "JSListSortInclude", vars.getLanguage());
    String strexclude=Utility.messageBD(servlet, "JSListSortExclude", vars.getLanguage());
    String strgoup=Utility.messageBD(servlet, "JSListSortGoUp", vars.getLanguage());
    String strgodown=Utility.messageBD(servlet, "JSListSortGoDown", vars.getLanguage());
    String strleftContent="";
    String strrightContent="";
    String formname="frmMain";
    String labelfield="";
    for (int i = 0; i < leadingemptycols; i++) {
      retval.append("<td class=\"leadingemptycolslistsortersimple\"></td>");
    }
    if (labelfieldname.equals(""))
      labelfield=leftsidefieldname;
    else
      labelfield=labelfieldname;
    retval.append(ConfigureLabel.doConfigure(servlet,vars,labelfield,"TitleCell","",elementId,""));
    Object template =  servlet.getServletContext().getAttribute("listSorterSimpleTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("ListSorterSimple.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("listSorterSimpleTEMPLATE", template);
    }
    retval.append(template.toString());
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));
    strleftContent=SelectBoxhelper.fields2option(leftdata,leftdataIDField.equals("") ?  leftsidefieldname: leftdataIDField,leftcurrentvalue,false,false);
    Replace.replace(retval, "@LEFTSIDECONTENT@", strleftContent);
    strrightContent=SelectBoxhelper.fields2option(rightdata,rightdataIDField.equals("") ? rightsidefieldname : rightdataIDField,rightcurrentvalue,false,false);
    Replace.replace(retval, "@RIGHTSIDECONTENT@", strrightContent);
    Replace.replace(retval, "@RIGHTSIDEFIELDNAME@", rightsidefieldname);
    Replace.replace(retval, "@LEFTSIDEFIELDNAME@", leftsidefieldname);
    Replace.replace(retval, "@INCLUDEMSG@",strinclude);
    Replace.replace(retval, "@EXCLUDEMSG@",strexclude);
    Replace.replace(retval, "@GOUPMSG@",strgoup);
    Replace.replace(retval, "@GODOWNMSG@",strgodown);
    Replace.replace(retval, "@TITLE@", tooltip);
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\" disabled=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    Replace.replace(retval, "@FORMNAME@",formname);
    
    script.addmultiselected(leftsidefieldname);
    script.addmultiselected(rightsidefieldname);
    return retval;
  }
    
}
