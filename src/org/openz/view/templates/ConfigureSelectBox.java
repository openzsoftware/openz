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
import org.openz.util.FormatUtils;
import org.openbravo.data.FieldProvider;
import org.openz.view.SelectBoxhelper;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openz.view.Scripthelper;

public class ConfigureSelectBox{
 
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String callout,String currentvalue, FieldProvider[] data,  String dataIDField,String tooltip, Boolean firstitemempty,String elementId,Boolean isListBased,String Style) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,required,readonly,callout,currentvalue, data,  dataIDField,"",false, "",tooltip,firstitemempty,null,null,false,elementId,isListBased,Style);
  }
  public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String callout,String currentvalue, FieldProvider[] data,  String dataIDField,String tooltip, Boolean firstitemempty,String elementId,String Style) throws Exception{
	    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,required,readonly,callout,currentvalue, data,  dataIDField,"",false, "",tooltip,firstitemempty,null,null,false,elementId,false, Style);
	  }
  public static StringBuilder doConfigureLink(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String callout,String currentvalue, FieldProvider[] data,  String dataIDField,String tooltip, Boolean firstitemempty, String adReferenceId, String adTableId,String elementId,Boolean isListBased, String Style) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,required,readonly,callout,currentvalue, data,  dataIDField,"",false, "",tooltip,firstitemempty,adReferenceId,adTableId,true,elementId,isListBased,Style);
  }
  public static StringBuilder doConfigureNoLink(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String callout,String currentvalue, FieldProvider[] data,  String dataIDField,String tooltip, Boolean firstitemempty, String adReferenceId, String adTableId,String elementId,Boolean isListBased, String Style) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, leadingemptycols,colstotal,required,readonly,callout,currentvalue, data,  dataIDField,"",false, "",tooltip,firstitemempty,adReferenceId,adTableId,false,elementId,isListBased,Style);
  }
  public static StringBuilder doConfigureGrid(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int colspan,boolean required,boolean readonly,String callout,String currentvalue, FieldProvider[] data,  String jssettings, String tooltip, Boolean firstitemempty,Boolean isListBased,String Style) throws Exception{
    return doConfigureAll(servlet,vars,script,fieldname, 0,colspan+1,required,readonly,callout,currentvalue, data,  "ID","",true, "",tooltip,firstitemempty,null,null,false,"",isListBased,Style);
  }
  
  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, int leadingemptycols,int colstotal,boolean required,boolean readonly,String callout,String currentvalue, FieldProvider[] data,  String dataIDField,String labeltext,boolean isGrid, String jssettings,String title, Boolean firstitemempty, String adReferenceId,String adTableId,Boolean link,String elementId,Boolean isListBased, String Style) throws Exception{
    StringBuilder retval= new StringBuilder();
    String datasection="";
    String isselected="";
    if (jssettings==null)
      jssettings="";
    final String directory= servlet.strBasePath;
    String selecteditem = "";
    String stdJSSettings = jssettings;
    if (jssettings.equals(""))
      stdJSSettings =  "onfocus=\"isGridFocused = false;\" onkeypress=\"changeToEditingMode('onkeypress');\" onchange=\"changeToEditingMode('onchange', this);logChanges(this); @CALLOUT@ displayLogic();return true;\"";
    for (int i = 0; i < leadingemptycols; i++) {
      retval=retval.append("<td class=\"leadingcolselectbox"+i+"\"></td>");
    }
    if (currentvalue!=null && ! currentvalue.equals("%"))
        selecteditem=currentvalue;
    if (isListBased) {
    	String targetvalue=SelectBoxhelper.getSelectedFromfields(data,dataIDField.equals("") ?  fieldname: dataIDField,selecteditem);
    	if (selecteditem.isEmpty()) targetvalue="";
	    retval=retval.append(ConfigureListBasedEntry.doConfigure(servlet,vars,script,fieldname,elementId,targetvalue,isGrid,colstotal,callout,Style));
	    return retval;
    }
    if (! isGrid)
      if (link)
        retval=retval.append(ConfigureLabel.doConfigureLink(servlet,vars,fieldname,"Label_ContentCell",labeltext,adReferenceId,adTableId,elementId,""));
      else
        retval=retval.append(ConfigureLabel.doConfigure(servlet,vars,fieldname,"Label_ContentCell",labeltext,elementId,""));
    Object template =  servlet.getServletContext().getAttribute("selectBoxTEMPLATE");
    if (template==null) {
      template = new String(FileUtils.readFile("SelectBox.xml", directory + "/src-loc/design/org/openz/view/templates/"));
      servlet.getServletContext().setAttribute("selectBoxTEMPLATE", template);
    }
    retval=retval.append(template.toString());
    Replace.replace(retval, "@JSSETTINGS@",stdJSSettings);
    if (isGrid)
      Replace.replace(retval, "@CONTENTCELLCLASS@","DataGrid_Content");
    else
      Replace.replace(retval, "@CONTENTCELLCLASS@","Form_ContentCell");
    Replace.replace(retval, "@CLASS@","inputWidth");
    Replace.replace(retval, "@FIELDNAME@", fieldname);
    Replace.replace(retval, "@STYLE@", Style);
    Replace.replace(retval, "@NUMCOLS@", Integer.toString(colstotal-1));
    Replace.replace(retval, "@CALLOUT@", callout);
    Replace.replace(retval, "@TITLE@", title);
    if (required){
      Replace.replace(retval, "@REQUIRED@", "ComboKey");
      Replace.replace(retval, "@REQUIREDTAG@", "required=\"true\"");
    } else {
      Replace.replace(retval, "@REQUIREDTAG@", "");
      if (readonly)
        Replace.replace(retval, "@REQUIRED@", "ComboKeyReadOnly");
      else
        Replace.replace(retval, "@REQUIRED@", "Combo");
    }
    if (readonly)
      Replace.replace(retval, "@READONLY@", "readonly=\"true\" disabled=\"true\"");
    else
      Replace.replace(retval, "@READONLY@", "");
    datasection=SelectBoxhelper.fields2option(data,dataIDField.equals("") ?  fieldname: dataIDField,selecteditem,firstitemempty,readonly);
    Replace.replace(retval, "@DATA@",datasection);
    
    return retval;
  }
    
}
