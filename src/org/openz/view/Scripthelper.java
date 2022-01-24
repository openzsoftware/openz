package org.openz.view;
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
import java.io.IOException;
import org.openbravo.utils.Replace;
import org.openz.util.*;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.utils.Replace;
import org.openbravo.data.Sqlc;
import org.openbravo.erpCommon.utility.*;

public class Scripthelper {
  private String additionalvalidate="";
  private String additionalonload="";
  private String hiddenfields="";
  private String displaylogic="";
  private String onload="";
  private String jsvars="";
  private String pagescript="";
  private String buscadorAceptar="";
  private String buscadorReset="";
  private String focf="";
  private String buscadorFields="";
  private String buscadorEmptyFields="";
  private Boolean isMultipart = false;
  public Boolean buscadorIsDirect = false;
  
  public void addSearchButtonConfig(HttpSecureAppServlet servlet,String fieldname,String referencename) throws Exception{
    String keyelement="keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"openSearch(null, null, '..@HTMLMAPPING@', null, false, 'frmMain', 'inp@NAME@', 'inp@NAME@_DES', document.frmMain.inp@NAME@_DES.value, 'inpIDValue', document.frmMain.inp@NAME@.value, 'WindowID', inputValue(document.frmMain.inpwindowId), 'inpAD_Org_ID', inputValue(document.frmMain.inpadOrgId),'Command', 'KEY');\", \"inp@NAME@_DES\" , \"null\");\n";
    String mapping = Replace.replace(keyelement,"@HTMLMAPPING@",UtilsData.getHTMLMapping4REFName(servlet,referencename));
    additionalonload=additionalonload +
      "      " + Replace.replace(mapping, "@NAME@", fieldname);
  }
  
  public void addSearchButtonConfigTextField(HttpSecureAppServlet servlet,String fieldname,String actionscript) throws Exception{
	    String keyelement="keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"document.frmMain.inpLastFieldChanged.value='inp@NAME@';" + actionscript + ";\", \"inp@NAME@\" , \"null\");\n";
	    additionalonload=additionalonload +
	      "      " + Replace.replace(keyelement, "@NAME@", fieldname);
  }
  
  public void enableshortcuts(String type){
    if (type.equals("EDITION"))
      additionalonload=additionalonload + "enableShortcuts('edition');";
    if (type.equals("RELATION"))
      additionalonload=additionalonload + "enableShortcuts('relation');";
    if (type.equals("POPUP"))
      additionalonload=additionalonload + "enableShortcuts('popup');";
   
  }
  public void setPopupSize(String width,String height){
    additionalonload=additionalonload + "window.resizeTo(" + width + "," + height + ");";  
  }
  
  public void setMultipart(Boolean multipart){
    this.isMultipart=multipart;
  }
  
  public void addSubmitPagePageSripts(){
    if (isMultipart) {
      pagescript= pagescript + "<script language=\"JavaScript\" type=\"text/javascript\">\n" +
          "function submitThisPage(strCommand) {\n" +
          "     if (validate()){\n" +
          "       cmd = document.getElementById('Command');\n" +
          "       cmd.value = strCommand;\n" +
          "       form = document.forms[0];\n" +
          "       form.submit();\n" +
          "       }\n" +
          " return true;\n" +
          "}</script>\n" ;
    }
    else  
    pagescript= pagescript + "<script language=\"JavaScript\" type=\"text/javascript\">\n" +
        "function submitThisPage(strCommand) {\n" +
        "     if (validate()) {\n" +
        "       submitFormGetParams(strCommand, action, getParamsScript(document.forms[0]));\n" +
        "       setProcessingMode('popup', true);}\n" +
        " return true;\n" +
        "}\n" +
        "function submitThisPageJasper() {\n" +
        "  if (validate()) { \n" +
        "    var parameters = addArrayValue(parameters, \"scrollbars\", \"1\");\n" +
        "    openPopUp('../utility/PrintJR.html', 'JREPORT' + document.forms[0].inpadProcessId.value, null, null, null, null, false, null, true, false, parameters);\n" +
        "    setProcessingMode('popup', false);\n" +
        "  }\n" +
        "  return true;\n" +
        "}</script>";
  }
  
  public void addJScript(String jsFunction){
    pagescript= pagescript + "<script language=\"JavaScript\" type=\"text/javascript\">\n" +
        jsFunction +
        "</script>";
  }
  public void addPreload(String preload){
	    pagescript= pagescript + preload ;
	        
	  }
  
  public void addmultiselected(String element){
    additionalvalidate=additionalvalidate +
      "          markCheckedAllElements(frm.inp" + element +");\n";
  }
  private void addTabServletItems(HttpSecureAppServlet servlet,VariablesSecureApp vars) throws Exception {
    String keycolumname=FormhelperData.getKeyColumnName(servlet, servlet.getClass().getName());
    String mapping=FormhelperData.getMappingRelation(servlet, servlet.getClass().getName());
    if (mapping==null)
       mapping=FormhelperData.getMapping(servlet, servlet.getClass().getName());
    String tableid=FormhelperData.getTableId(servlet, servlet.getClass().getName());
    if (tableid!=null)
      addHiddenfield("inpTableId", tableid);
    if (keycolumname!=null){
      addHiddenfield("inpkeyColumnId",keycolumname);
      addHiddenfield("inpKeyName","inp" + Sqlc.TransformaNombreColumna(keycolumname));
    }
    if (mapping!=null)
      addHiddenfield("mappingName",mapping);
    addHiddenfield("inpwindowId",servlet.getWindowId().equals("") ? servlet.getClass().getName() : servlet.getWindowId());
    addHiddenfield("inpTabId",servlet.getTabId());
    addHiddenfield("inpCommandType",servlet.getCommandtype());
    addHiddenfield("updatedTimestamp",servlet.getUpdatedtimestamp());
    //hiddenfields=hiddenfields + "<INPUT type=\"hidden\" name=\"inpParentKeyColumn\" id=\"parent\" value=\"" + servlet.getKeyparent() + "\">\n";
    hiddenfields=hiddenfields + "<INPUT type=\"hidden\" name=\"inpParentOrganization\" id=\"parentOrg\" value=\"" + servlet.getOrgparent() + "\">\n"; 
    addJSVar("strShowAudit",Utility.getContext(servlet, vars, "ShowAudit", servlet.getWindowId()));
  }
  public void addHiddenfield(String element, String value){
    if (!hiddenfields.contains("<INPUT type=\"hidden\" name=\""+ element + "\" value=\"" + value + "\">\n"))
    hiddenfields=hiddenfields + "<INPUT type=\"hidden\" name=\""+ element + "\" value=\"" + value + "\">\n";
  }
  public void addHiddenfieldWithID(String element, String value){
    if (!hiddenfields.contains(element))
    hiddenfields=hiddenfields + "<INPUT type=\"hidden\" id=\""+ element + "\" name=\"inp"+ element + "\" value=\"" + value + "\">\n";
  }
  public void addHiddencontainer(String element, String value, String id){
	   hiddenfields=hiddenfields + "<INPUT type=\"hidden\" name=\""+ element + "\" id=\""+ id + "\" value=\"" + value + "\">\n";  
  }
  public void addHiddenShortcut(String buttonid){
    hiddenfields=hiddenfields + "<a id=\"" + buttonid + "\" onclick=\"submitCommandForm('SAVE_NEW_NEW', true, null, '', '_self', true, false);return false;\" href=\"#\"></a>\n";
  }
  public void addJSVar(String varname, String value){
    jsvars=jsvars+" var " + varname + "=\"" + value + "\";\n"; 
  }
  public void addDisplayLogic(String logicelement){
    displaylogic=displaylogic + "     " + logicelement + "\n";
  }
  public void addOnload(String logicelement){
    onload=onload + "     " + logicelement + "\n";
  }
  
  /**
   * Adds a Message to a Servlet
   * 
   * @param servlet
   * @param vars 
   * @param msgType: ERROR SUCCESS INFO WARNING
   * @param msgTitle
   * @param msgText
   * 
   */
  public void addMessage(HttpSecureAppServlet servlet,VariablesSecureApp vars,String msgType,String msgTitle, String msgText){
    OBError myMessage = new OBError();
    myMessage.setType(msgType);
    myMessage.setTitle(msgTitle);
    myMessage.setMessage(msgText);
    vars.setMessage(servlet.getClass().getName(), myMessage);
  }
  /**
   * Adds a Message to a Servlet (2nd Constructor)
   * 
   * @param servlet
   * @param vars 
   * @param msg: OBError
   * 
   */
  public void addMessage(HttpSecureAppServlet servlet,VariablesSecureApp vars,OBError myMessage){
    vars.setMessage(servlet.getClass().getName(), myMessage);
  }
  
  public void addBuscador(HttpSecureAppServlet servlet,VariablesSecureApp vars,String field, String template){
    if (buscadorAceptar.isEmpty()) {
      if ( buscadorIsDirect ) {
    	  focf="inp" + field;
    	  buscadorAceptar="function aceptar(e) {\n" +
    			  "var frm = document.forms[0];\n" +
    		        "var paramsData = new Array();\n" +
    		        "var count = 0;\n" +
    		        "if (e.keyCode!='13') {return true;}\n";
      }else
	      buscadorAceptar="function aceptar() {\n" +
	        "var frm = document.forms[0];\n" +
	        "var paramsData = new Array();\n" +
	        "var count = 0;\n" ;
      buscadorFields= "\"" + Utility.getTabURL(servlet, vars.getSessionValue("Buscador.inpTabId"), "R") +"\"";
    }
    if (buscadorReset.isEmpty()) {
      buscadorReset="function resetfilter() {\n" +
        "var frm = document.forms[0];\n" +
        "var paramsData = new Array();\n" +
        "var count = 0;\n";
      buscadorEmptyFields="\"" + Utility.getTabURL(servlet, vars.getSessionValue("Buscador.inpTabId"), "R") +"\"";
    }
    if (template.equals("REFCOMBO")) {
      buscadorAceptar=buscadorAceptar + "paramsData[count++] = new Array(\"inpParam" + field + "\", ((frm.inp" + Sqlc.TransformaNombreColumna(field) + ".selectedIndex!=-1)?frm.inp" + Sqlc.TransformaNombreColumna(field) + ".options[frm.inp" + Sqlc.TransformaNombreColumna(field) + ".selectedIndex].value:\"\"),\"" + Sqlc.TransformaNombreColumna(field) + "\");\n";
      buscadorFields=buscadorFields + ",\"inpParam" +field + "\", escape((frm.inp" + Sqlc.TransformaNombreColumna(field) + ".selectedIndex!=-1)?frm.inp" + Sqlc.TransformaNombreColumna(field) + ".options[frm.inp" + Sqlc.TransformaNombreColumna(field) + ".selectedIndex].value:\"\")";    
    } else if (template.equals("POPUPSEARCH")) {
    	buscadorAceptar=buscadorAceptar + "paramsData[count++] = new Array(\"inpParam" + field + "\", frm.inp" + Sqlc.TransformaNombreColumna(field) +".value,\"" + Sqlc.TransformaNombreColumna(field) + "\");\n";
    	buscadorAceptar=buscadorAceptar + "paramsData[count++] = new Array(\"inpParam" + field + "_DES\", frm.inp" + Sqlc.TransformaNombreColumna(field) +"_DES.value,\"" + Sqlc.TransformaNombreColumna(field) + "_DES\");\n";
    	buscadorReset=buscadorReset + "paramsData[count++] = new Array(\"inpParam" + field + "_DES\", \"\",\"" + Sqlc.TransformaNombreColumna(field) + "_DES\");\n";
        buscadorFields=buscadorFields + ",\"inpParam" +field + "\", escape(frm.inp" + Sqlc.TransformaNombreColumna(field) + ".value)";    
    }
    else {
      buscadorAceptar=buscadorAceptar + "paramsData[count++] = new Array(\"inpParam" + field + "\", frm.inp" + Sqlc.TransformaNombreColumna(field) +".value,\"" + Sqlc.TransformaNombreColumna(field) + "\");\n";
      buscadorFields=buscadorFields + ",\"inpParam" +field + "\", escape(frm.inp" + Sqlc.TransformaNombreColumna(field) + ".value)";    
    }
    buscadorReset=buscadorReset + "paramsData[count++] = new Array(\"inpParam" + field + "\", \"\",\"" + Sqlc.TransformaNombreColumna(field) + "\");\n";
    buscadorEmptyFields=buscadorEmptyFields + ",\"inpParam" +field + "\", \"\"";
    
  }
  /**
   * Java Script for Filters in Manual Servlets
   * The Function aceptar(event); must be called in field action
   * @param command: Complete JS Command e.g. submitCommandForm('FIND',true,null,null,'_self');
   * 
   */
  public void addFilterAction4ManualServlets(String command){
	    pagescript= pagescript + "<script language=\"JavaScript\" type=\"text/javascript\">\n" +
	        "function aceptar(e) {\n" + 
	        "	  var frm = document.forms[0];\n" + 
	        "	  if (e.keyCode!='13') \n" + 
	        "		  return true;\n" + 
	        "	  else\n" + 
	        "		 "+ command +"\n" + 
	        "  }" +
	        "</script>";
	  }
  
  public static String addTagOption(String tag, String option,String jssettings){
    String retval="";
    String firstpart="";
    String tagcurvalue="";
    String lastpart="";
    if (! jssettings.contains(tag)){
      firstpart=jssettings.substring(0,jssettings.indexOf("<"));
      if (jssettings.indexOf(" ")==0 || (jssettings.indexOf(" ") > jssettings.indexOf(">")))
        firstpart=firstpart+jssettings.substring(jssettings.indexOf("<"),jssettings.indexOf(">"))+ " ";
      else
        firstpart=firstpart+jssettings.substring(jssettings.indexOf("<"),jssettings.indexOf(" ")+1);
      lastpart=jssettings.substring(jssettings.indexOf(firstpart)+firstpart.length());
      retval = firstpart + tag + "=\"" + option + "\" " + lastpart;
    }
    else {
      
      firstpart=jssettings.substring(0,jssettings.indexOf(tag));
      int posoftagbegin=jssettings.indexOf(tag);
      int lenthoftagincl=tag.length()+2;
      int lenthoftagcontent=jssettings.substring(posoftagbegin+lenthoftagincl, jssettings.indexOf("\"",posoftagbegin+ lenthoftagincl)).length();
      lastpart=jssettings.substring(posoftagbegin+lenthoftagincl+lenthoftagcontent+1);
      tagcurvalue=jssettings.substring(posoftagbegin+lenthoftagincl,lenthoftagcontent+posoftagbegin+lenthoftagincl);
      retval = firstpart + tag + "=\"" + tagcurvalue + " " + option + "\" " + lastpart;
    }
    return retval;
  }
  
  public static String removeTagOption(String tag, String option,String jssettings){
    String retval="";
    return retval;
  }
  
  
  public String doScript(String structure, String additionalscript, HttpSecureAppServlet servlet,VariablesSecureApp vars) throws Exception{
    String scriptval="";
    String retval="";
    if (! buscadorAceptar.isEmpty() &&  buscadorIsDirect) {
    	buscadorAceptar=buscadorAceptar + "selectFilters(paramsData);\n" +
    			                          "if (document.getElementById(\"buttonSearch\"))\n" +
    			                          "    document.getElementById(\"buttonSearch\").className=\"Main_ToolBar_Button_Icon Main_ToolBar_Button_Icon_SearchFiltered\";\n" +
    			                          "if (document.getElementById(\"buttonSearchFiltered\"))\n" +
    			                          "    document.getElementById(\"buttonSearchFiltered\").className=\"Main_ToolBar_Button_Icon Main_ToolBar_Button_Icon_SearchFiltered\";\n" +
    			                          "return true;\n" +
                                          "}\n";
    }
    if (! buscadorAceptar.isEmpty() && ! buscadorIsDirect) {
      buscadorAceptar=buscadorAceptar + "if (parent.window.opener.selectFilters) parent.window.opener.selectFilters(paramsData);\n" +
                                        "else parent.window.opener.submitFormGetParams(\"SEARCH\"," + buscadorFields + ");\n" +
                                        "if (parent.window.opener.document.getElementById(\"buttonSearch\"))\n" +
                                        "  parent.window.opener.document.getElementById(\"buttonSearch\").className=\"Main_ToolBar_Button_Icon Main_ToolBar_Button_Icon_SearchFiltered\";\n" +
                                        "if (parent.window.opener.document.getElementById(\"buttonSearchFiltered\"))\n" +
                                        "  parent.window.opener.document.getElementById(\"buttonSearchFiltered\").className=\"Main_ToolBar_Button_Icon Main_ToolBar_Button_Icon_SearchFiltered\";\n" +
                                        "parent.window.close();\n" +
                                        "return true;\n" +
                                        "}\n";
    }
    if (! buscadorReset.isEmpty() && ! buscadorIsDirect) {
      buscadorReset = buscadorReset + "if (parent.window.opener.selectFilters) parent.window.opener.selectFilters(paramsData);\n" +
          "else parent.window.opener.submitFormGetParams(\"SEARCH\"," + buscadorEmptyFields + ");\n" +
          "if (parent.window.opener.document.getElementById(\"buttonSearch\"))\n" +
          "  parent.window.opener.document.getElementById(\"buttonSearch\").className=\"Main_ToolBar_Button_Icon Main_ToolBar_Button_Icon_Search\";\n" +
          "if (parent.window.opener.document.getElementById(\"buttonSearchFiltered\"))\n" +
          "  parent.window.opener.document.getElementById(\"buttonSearchFiltered\").className=\"Main_ToolBar_Button_Icon Main_ToolBar_Button_Icon_Search\";\n" +
          "parent.window.close();\n" +
          "return true;\n" +
          "}\n";
    }
    if (buscadorIsDirect){
    	scriptval = "function changeToEditingMode(d) {return false;}\n" +
    		   "function onloadFunctions() {\n" + 
	            onload +
	            "setBrowserAutoComplete(false);\n" +
	            "setWindowElementFocus('" + focf + "', 'id');" +
	            additionalonload + "\n" +
	            "return true;}\n" + 
    			buscadorAceptar +
    			"function displayLogic() {\n" +
                "return true;\n}\n" ;
    } else {
      scriptval = "<script language=\"JavaScript\" type=\"text/javascript\">\n" +
               "         function onloadFunctions() {\n" + 
               "var frm=document.frmMain;\n"  +
               onload +
               "displayLogic();\n" +
               "setCursor(\"default\");\n" +
               additionalonload + "\n" +
               "return true;}\n" +
               "</script>\n" +
               " <script language=\"JavaScript\" type=\"text/javascript\">\n" +
               buscadorAceptar +
               buscadorReset +
               "function validate(action, form, value) {\n"+ 
               "     var frm=document.frmMain;\n" +
               "     if (validateMandantoryFields()) {\n" +
               additionalvalidate + "\n" +
               "            return true;\n" +
               "     }else{\n" +
               "            return false;\n" +
               "     }" +
               "}\n" +
               "function displayLogic() {\n" +
                     displaylogic + "\n" +
               "     return true;\n}\n" +
               "</script>\n";
    }  
    if (additionalscript!=null)
    scriptval=scriptval+additionalscript;
    scriptval=scriptval+pagescript;
    String windowid="";
    if (servlet.getWindowId().equals(""))
      windowid=servlet.getClass().getName();
    else
      windowid=servlet.getWindowId();
    addTabServletItems(servlet,vars);
    retval=Replace.replace(structure, "@ADDITIONALSCRIPTS@", scriptval);
    if (isMultipart)
      retval= Replace.replace(retval,"name=\"frmMain\"", "name=\"frmMain\" enctype=\"multipart/form-data\"");
    retval=Replace.replace(retval, "@HIDDENFIELDS@", hiddenfields);
    retval=Replace.replace(retval, "@JSVARS@", jsvars);
    final OBError myMessage = vars.getMessage(servlet.getClass().getName());
    if (myMessage!=null){
      retval= Replace.replace(retval,"MessageBoxHIDDEN","MessageBox" + myMessage.getType());
      retval= Replace.replace(retval,"messageBoxIDTitle\"></DIV>","messageBoxIDTitle\">" + myMessage.getTitle() + "</DIV>");
      retval= Replace.replace(retval,"messageBoxIDMessage\"></DIV>","messageBoxIDMessage\">" + myMessage.getMessage() + "</DIV>");
      vars.removeMessage(servlet.getClass().getName());
    }
    
    return retval; 
  }
  
    
}
