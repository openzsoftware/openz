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

import org.openbravo.data.FieldProvider;
import org.openbravo.database.ConnectionProvider;

import javax.servlet.ServletException;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openz.view.*;

public class SelectBoxhelper {
  public static String fields2option2(ConnectionProvider connectionProvider, String fieldname,String selecteditem, Boolean emptyitemfirst, Boolean noDataLoad, String keycolumn, String CurrentValue, String Chosenlang){
    String datasection="";
    String isselected="";
    String tablename=keycolumn.substring(0, keycolumn.length()-3);
    if (emptyitemfirst)
        datasection="<OPTION title=\"\" value=\"\"></OPTION>";

      String xdx="0";
   try {
    xdx=SelectBoxhelperData.countFrom(connectionProvider,  tablename,keycolumn, CurrentValue);
   
  } catch (ServletException e) {
    // TODO Auto-generated catch block
    e.printStackTrace();
  }
   try {
    SelectBoxhelperData[] multiarray= SelectBoxhelperData.getdatafromtable(connectionProvider,  tablename,keycolumn, CurrentValue, Chosenlang);
    int foo = Integer.parseInt(xdx);

    for (int i = 0; i < foo; i++) {
      if (multiarray[i].getField("name") != null) {
        if (multiarray[i].getField("name").equalsIgnoreCase(selecteditem))
          isselected="selected";
        else
          isselected="";
          datasection=datasection + "<OPTION title=\"" + multiarray[i].getField("name") + "\"   value=\"" + multiarray[i].getField("idfield") + "\" " + isselected +">" + multiarray[i].getField("name") + "</option>";
        
      }
    }
  
  } catch (ServletException e) {
    // TODO Auto-generated catch block
    e.printStackTrace();
  }
    
   return datasection;
  }
  public static String fields2option(FieldProvider[] data, String fieldname,String selecteditem, Boolean emptyitemfirst, Boolean noDataLoad){
    String datasection="";
    String isselected="";
    if (emptyitemfirst)
        datasection="<OPTION title=\"\" value=\"\"></OPTION>";
    if (data!=null){
      for (int i = 0; i < data.length; i++) {
        if (data[i].getField(fieldname) != null && data[i].getField("name") != null) {
          if (data[i].getField(fieldname).equalsIgnoreCase(selecteditem))
            isselected="selected";
          else
            isselected="";
          if (! noDataLoad)
            datasection=datasection + "<OPTION title=\"" + data[i].getField("name") + "\"  value=\"" + data[i].getField(fieldname) + "\" " + isselected +">" + data[i].getField("name") + "</option>";
          if ( noDataLoad && isselected.equals("selected"))
            datasection=datasection + "<OPTION title=\"" + data[i].getField("name") + "\"   value=\"" + data[i].getField(fieldname) + "\" " + isselected +">" + data[i].getField("name") + "</option>";
        }
      }
    }
   return datasection;
  }
  public static String getSelectedFromfields(FieldProvider[] data, String fieldname,String selecteditem){
	    if (data!=null){
	      for (int i = 0; i < data.length; i++) {
	        if (data[i].getField(fieldname) != null && data[i].getField("name") != null) {
	        	String t=data[i].getField("name");
	        	if (selecteditem!=null && ! selecteditem.isEmpty() && data[i].getField(fieldname).equals(selecteditem))
	        		return data[i].getField("name");
	        }
	      }
	    }
	   return "";
  }
  public static String getSelectorURL(HttpSecureAppServlet servlet,VariablesSecureApp vars,String selector) throws Exception {
     return SelectBoxhelperData.getSelectorURL(servlet, selector);
  }     
  public static String getSelectorICON(HttpSecureAppServlet servlet,VariablesSecureApp vars,String selector) throws Exception {
    return SelectBoxhelperData.getSelectorICON(servlet, selector);
  }     
 
  public static String getSelectorPopupICON(HttpSecureAppServlet servlet,VariablesSecureApp vars,String selector) throws Exception {
    return SelectBoxhelperData.getSelectorPopupICON(servlet, selector);
  }   
  public static String getSelectorValueByID(HttpSecureAppServlet servlet,VariablesSecureApp vars,String selector, String id) throws Exception {
    return SelectBoxhelperData.getSelectorValueByID(servlet, selector, id, vars.getLanguage());
  }  
  public static String getAttributeNameByID(HttpSecureAppServlet servlet,VariablesSecureApp vars, String attrInstanceId) throws Exception {
    return SelectBoxhelperData.getAttributeSetName(servlet, attrInstanceId);
  }   
  public static String getTableValueByID(HttpSecureAppServlet servlet,VariablesSecureApp vars,String tablename, String id) throws Exception {
    return SelectBoxhelperData.getTableValueByID(servlet,tablename, id, vars.getLanguage());
  }   
  /**
   * Gets a  Reference  Combo
   * 
   * @param servlet
   *          Handler for the Servlet (Connection)
   * @param vars
   *          Handler for the session info.
   * @param refname
   *          String with the Name of the  Reference to search.
   *          Must be equally defined in the Data Dictionary.
   *          If you give a Table-id-field (Direct Table Ref - Use the Fieldname from the Database (e.g. ad_user_id)
   * @param validation
   *          String with the ID of the Validation to search. 
   *          Get with 
   *          select ad_val_rule_id from ad_val_rule where name=
   * @param dataset
   *          complete dataset of a  Fieldgroup in a Tab or Process used to evaluate @field@ Parameters in Expressions of where Clause and validations 
   */
  public static FieldProvider[] getReferenceDataByRefName(HttpSecureAppServlet servlet,VariablesSecureApp vars,String refname, String validation,FieldProvider dataset,String currentvalue, Boolean readonly) throws Exception {
    ComboTableDataWrapper cdb=null;
    String windowId=servlet.getWindowId();
    String tabId=servlet.getTabId();
    String whereaddition;
    if (validation==null)
      validation="";
    // all Tables that have an Access Level to Organization only 
    // can Only select a specific ORG, -> Val Rule
    if (! tabId.isEmpty() && validation.isEmpty() && refname.equalsIgnoreCase("ad_org_id")) 
      if (SelectBoxhelperData.getTabAccessLevel(servlet, tabId).equals("1"))
        //AD_Org Trx Security validation
        validation="130";
    if (windowId.isEmpty())
      windowId=servlet.getClass().getName();
    if (SelectBoxhelperData.getReferenceTypeByName(servlet, refname)==null && refname.toLowerCase().endsWith("_id"))
      cdb= new ComboTableDataWrapper(servlet,vars,refname,validation,windowId,currentvalue,"",dataset);
    else if (SelectBoxhelperData.getReferenceTypeByName(servlet, refname).equals("L"))
      cdb= new ComboTableDataWrapper(servlet,vars,refname,currentvalue);
    else if (SelectBoxhelperData.getReferenceTypeByName(servlet, refname).equals("T"))
      cdb= new ComboTableDataWrapper(servlet,vars,refname,validation,windowId,currentvalue,dataset);
    if (! readonly)
      return cdb.select(!vars.getCommand().equals("NEW"));
    else {      
      cdb.addreadonlyIDselect(currentvalue);
      return cdb.select(!vars.getCommand().equals("NEW"));
    }
  }
}