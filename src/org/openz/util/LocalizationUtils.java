package org.openz.util;
import javax.servlet.ServletException;

import org.openbravo.base.secureApp.DefaultSessionValuesData;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;

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
public class LocalizationUtils {
  public static String getElementTextByElementName(ConnectionProvider conn,String columnname,String language) throws Exception {
    if (columnname.equals("empty"))
      return "";
    return UtilsData.getElementTextByColumname(conn, columnname, language);
 
  }
  public static String getElementTextById(ConnectionProvider conn,String elementId,String language) throws Exception {
    
    return UtilsData.getElementTextByID(conn, elementId, language);
 
  }
  public static String getMessageText(ConnectionProvider conn,String messagevalue,String language) throws Exception {
    return UtilsData.getMessageText(conn, messagevalue, language);
 
  }
  public static String getWindowTitle(ConnectionProvider conn,String windowname,String language) throws Exception {
    return UtilsData.getWindowText(conn, windowname, language);
 
  }
  public static String getProcessTitle(ConnectionProvider conn,String processId,String language) throws Exception {
    return UtilsData.getProcessDescriptionText(conn, processId, language);
 
  }
  public static String getProcessInfo(ConnectionProvider conn,String processId,String language) throws Exception {
    return UtilsData.getProcessInfoText(conn, processId, language);
 
  }
  public static String getFieldgroupText(ConnectionProvider conn,String fieldgroupId,String language) throws Exception {
    return UtilsData.getFieldgroupText(conn, fieldgroupId, language);
 
  }
  public static String getListTextByValue(ConnectionProvider conn,String listName,String language,String listValue) throws Exception {
    return UtilsData.getListTextByValue(conn, listName, language,listValue);
  }
  public static String getOrgCurSymbol(ConnectionProvider conn,String orgid)  {
   try {
    return UtilsData.getCurSymbolFromOrg(conn, orgid);
   }
   catch (Exception e) { 
      return "";
    }
  }
  public static String getGlobalCurSymbol(ConnectionProvider conn)  {
    try {
     return UtilsData.getGlobalCurSymbol(conn);
    }
    catch (Exception e) { 
       return "";
     }
   }
  public static String convDateString2SQL(String dateparameter, ConnectionProvider conn,VariablesSecureApp vars) throws ServletException {
	    String value = dateparameter;
	    String targetvalue=value;
	    // ISO TIME FORMAT 
	    Boolean isTime=false;
	    if (!value.isEmpty() && value.substring(2, 3).equals(":") && value.substring(5, 6).equals(":") &&  value.length()==8)
	    	isTime=true;
	    if (!value.isEmpty() && !isTime )
	    	targetvalue=DefaultSessionValuesData.selectddatevalue(conn, value, vars.getSessionValue("#AD_SqlDateTimeFormat"), "DD-MM-YYYY");

	    return targetvalue;
}
}
