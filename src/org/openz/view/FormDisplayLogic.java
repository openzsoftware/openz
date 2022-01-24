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
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.openbravo.database.ConnectionProvider;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import javax.servlet.ServletException;
import javax.ws.rs.ClientErrorException;

import org.openbravo.zsoft.smartui.Smartprefs;
import org.openbravo.utils.Replace;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.Sqlc;
import org.openz.model.GenericFieldProviderData;
import org.openz.util.FormatUtils;

public class FormDisplayLogic {
  
    public static boolean triggersComboReload(ConnectionProvider conn,String fieldId) throws ServletException {
      if (FormDisplayLogicData.triggersComboReload(conn, fieldId).equals("Y"))
          return true;
      else
        return false;
    }
    public static String getTabFieldDisplayLogic(ConnectionProvider conn,String p_tab_id, String p_role_id) throws ServletException {
      return FormDisplayLogicData.getlogic4tab(conn, p_tab_id, p_role_id);
    }
    
    
    public static String fieldVisibleLogic(HttpSecureAppServlet servlet,VariablesSecureApp vars, Scripthelper script,String adFieldId,String value, Boolean addscriptlogic )  throws Exception {
      /* If VISIBLE: The field is always visible
       * If HIDDEN: The field is always hidden : Means in FORMS It is generated, The place is filled, but not shown. In grids the field is not generated.
       * Over ALL RULE: If a field in the ..Instance-Tables have active='N' - It is not generated at all(DONOTGENERATE). In a Grid: If displayed is N, the Field is not generated
       *                If a field has Displayed='N' - (Instance specific or not) The value is genarated as hidden field in the header - No visible Field is generated on the form - So no place on the Form is used.
       *                All other rules are using the space on the Form. The Over ALL RULE cannot be overwritten.
       *                
       * Display Logic special rules (not yet implemented on Grids):
       * Field Display Logic is overwritten By
       * Fieldinstance Display Logic - If Visible: visible, if hidden: Hidden, If none and Display Logic is given: Evaluate Logic - Overwritten By
       * Role-Tabfield-Access
       * 
       */
      String fieldname=FormDisplayLogicData.fieldGetName(servlet, adFieldId);
      String visiblelogic=FormDisplayLogicData.getFieldVisibleLogic(servlet, adFieldId, vars.getRole());
      if (visiblelogic.equals("VISIBLE"))
        return "VISIBLE";
      if (visiblelogic.equals("DONOTGENERATE"))
        return "DONOTGENERATE";
      if (visiblelogic.equals("HIDDEN")||visiblelogic.equals("HIDDENNUMERIC")) {
        if (script!=null && addscriptlogic) {
          if (visiblelogic.equals("HIDDENNUMERIC"))
            script.addHiddenfield("inp" + Sqlc.TransformaNombreColumna(fieldname.toLowerCase()), FormatUtils.formatNumber(value,vars,"priceEdition"));
          if (visiblelogic.equals("HIDDEN"))
            script.addHiddenfield("inp" + Sqlc.TransformaNombreColumna(fieldname.toLowerCase()), value);
          return "DONOTGENERATE";
        } else
          return "HIDDEN";
      }
      if (! visiblelogic.equals("VISIBLE") && ! visiblelogic.equals("HIDDEN") && ! visiblelogic.equals("DONOTGENERATE")) {
        // Evaluate Complex Logic
        String logic=evaluateLogicTrue(servlet,vars,script,visiblelogic,adFieldId);
        logic=logic+"         fieldDisplaySettings('"+ Sqlc.TransformaNombreColumna(fieldname.toLowerCase()) + "', true);\n";
        logic=logic+"     } else {\n         fieldDisplaySettings('"+ Sqlc.TransformaNombreColumna(fieldname.toLowerCase())  + "', false);\n     }\n";
        if (addscriptlogic)
          script.addDisplayLogic(logic);
      }
      return "VISIBLE";
    }
    
    public static Boolean fieldReadOnlyLogic(HttpSecureAppServlet servlet,VariablesSecureApp vars, Scripthelper script,String adFieldId , Boolean addScriptLogic)  throws Exception {
      /* If True: The field is always readonly 
       * If false: The field is never readonly 
       * On a GRID , the dynmic Logic is not implemented only role, instance and field can be set as reeadonly or editable.
       * Readonly Logic:
       * Field Readonly Logic overwritten By
       * Field Readonly Y/N overwritten By
       * Fieldinstance Readonly Logic - If Visible: visible, if hidden: Hidden, If None and Display Logic is given: Evaluate Logic - Overwritten By
       * Role-Tabfield-Access
       */
      String rolereadonly=FormDisplayLogicData.isTabReadonly(servlet, vars.getRole(),servlet.getTabId());
      if (rolereadonly!=null){
        if (rolereadonly.equals("TRUE"))
          return true;
      }
      String fieldname=FormDisplayLogicData.fieldGetName(servlet, adFieldId);
      String readonlylogic=FormDisplayLogicData.fieldGetReadonlyLogic(servlet, adFieldId, vars.getRole());
      // NOEDIT can happen on Columne (Editible='N')
      if (readonlylogic.equals("NOEDIT")) {
        if (servlet.getCommandtype().equals("NEW"))
          readonlylogic="EDIT";
        else
          readonlylogic="READONLY";
      }
      if (readonlylogic.equals("READONLY"))
        return true;
      if (readonlylogic.equals("EDIT"))
        return false;
      if (! readonlylogic.equals("READONLY") && ! readonlylogic.equals("EDIT")) {
        // Evaluate Complex Logic
        String logic=evaluateLogicTrue(servlet,vars,script,readonlylogic,adFieldId);
        if (! logic.isEmpty()) {
          logic=logic+"         fieldReadonlySettings('"+ Sqlc.TransformaNombreColumna(fieldname.toLowerCase()) + "', true);\n";
          logic=logic+"     } else {\n         fieldReadonlySettings('"+ Sqlc.TransformaNombreColumna(fieldname.toLowerCase()) + "', false);\n     }\n";
          // logic=logic+ " test();\n } else {test();\n}\n";
          if (addScriptLogic);
            script.addDisplayLogic(logic);
        }
      }
      return false;
    }
    
    public static Boolean fieldMandantoryLogic(HttpSecureAppServlet servlet,VariablesSecureApp vars, Scripthelper script,String adFieldId, Boolean addScriptLogic )  throws Exception {
      /* If True: The field is always mandantory
       * If false: The field is never mandantory 
       * On a GRID , the dynmic Logic is not implemented only role, instance and field can be set as mandantory or not.
       * Mandantory Logic:
       * Field Mandantory Logic overwritten By
       * Field Mandantory Y/N overwritten By
       * Fieldinstance Mandantory Logic - : Evaluate Logic 
       */
      String fieldname=FormDisplayLogicData.fieldGetName(servlet, adFieldId);
      String mandantorylogic=FormDisplayLogicData.fieldGetMandantoryLogic(servlet, adFieldId, vars.getRole());
      if (mandantorylogic.equals("MANDANTORY"))
        return true;
      if (mandantorylogic.equals("CANBENULL"))
        return false;
      if (! mandantorylogic.equals("MANDANTORY") && ! mandantorylogic.equals("CANBENULL")) {
        // Evaluate Complex Logic
        String logic=evaluateLogicTrue(servlet,vars,script,mandantorylogic,adFieldId);
        logic=logic+"         fieldMandantorySettings('"+  Sqlc.TransformaNombreColumna(fieldname.toLowerCase()) + "', true);\n";
        logic=logic+"     } else {\n         fieldMandantorySettings('"+ Sqlc.TransformaNombreColumna(fieldname.toLowerCase()) + "', false);\n     }\n";
        if (addScriptLogic)
          script.addDisplayLogic(logic);
      }
      return false;
    }
    
    
    public static String getFieldDefaultValue(HttpSecureAppServlet servlet, VariablesSecureApp vars,String adFieldOREGColumnORFGColumnID) throws Exception  {
      /* This Method schall be called when a complete Fieldgroup has no Data.
       * It ececutes the following way:
       * 1. If we are in a Window , maybe smartprefs are set. If so, It returns the Pref found there.
       * 2. If an SQL-Default is set, it is executed and returned.
       * 3. If the default contains a single @xyz@ - Session Var - The session Var is evaluated and returned
       * 4. If none of this, a constant-Value can be in defaultvalue and is returned.
       * 5. If no default-Value is given and the Field is a List Reference, the Default value is Retrieved on the List reference.
       */
      String defaultstmt=FormDisplayLogicData.fieldGetDefault(servlet, adFieldOREGColumnORFGColumnID);
      String retval="";
      String sql="";
      String window= FormDisplayLogicData.fieldGetWindowID(servlet, adFieldOREGColumnORFGColumnID);
      String tabid=FormDisplayLogicData.fieldGetTabID(servlet, adFieldOREGColumnORFGColumnID);
      String fieldname=FormDisplayLogicData.fieldGetName(servlet, adFieldOREGColumnORFGColumnID);
      // 1St Get Default from Smartprefs (Overwrites all other Defaults)
      Smartprefs temp = new Smartprefs();
      if (window!=null)
          retval=temp.getSmartprefs(servlet, vars,fieldname, window);
      if (retval.equals("")){
        if (defaultstmt.startsWith("@SQL=")){
          sql=tokenizeSQL(servlet,vars,defaultstmt.substring(5, defaultstmt.length()),adFieldOREGColumnORFGColumnID);
          retval=GenericFieldProviderData.getSQL(servlet,sql);
          return retval;
        }
      }
      if (retval.equals("")){
          if (defaultstmt.contains("@")) {
              retval=getValue(servlet,vars,defaultstmt);
              if (retval.equals(""))
                retval=getValue(servlet,vars,defaultstmt.replace("'", "").replace("null", ""));
              if (retval.equals(""))
                if (fieldname.equalsIgnoreCase("ad_client_id")||fieldname.equalsIgnoreCase("ad_org_id")||fieldname.equalsIgnoreCase("m_warehouse_id"))
                  retval=vars.getSessionValue("#" + fieldname);
          }
          if (retval.equals("") && ! defaultstmt.contains("@"))
            retval=defaultstmt;
      }
      
      if (retval.equals(""))
        retval=FormDisplayLogicData.getTabFieldListDefault(servlet,tabid,fieldname, vars.getOrg());
      if (retval.equals(""))
        retval=FormDisplayLogicData.getTabFieldDatabaseDefault(servlet,adFieldOREGColumnORFGColumnID);
      if (retval.equals("")) {
        if (fieldname.equalsIgnoreCase("ad_client_id"))
          retval=vars.getClient();
        if (fieldname.equalsIgnoreCase("ad_org_id"))
          retval=vars.getOrg();
        if (fieldname.equalsIgnoreCase("m_warehouse_id"))
          retval=vars.getSessionValue("#" + fieldname);
        if (fieldname.equalsIgnoreCase("c_currency_id"))
          retval=vars.getSessionValue("$" + fieldname);
      }
      // Special Field ISSOTRX must be evaluated against the window of the tab
      if (fieldname.equalsIgnoreCase("issotrx"))
        retval=FormDisplayLogicData.windowGetIsSSOTRX(servlet, window);
      if (fieldname.equalsIgnoreCase("issotrx") || FormDisplayLogicData.isFieldStoredinSession(servlet,adFieldOREGColumnORFGColumnID ).equals("Y"))
        vars.setSessionValue(window + "|" + fieldname, retval);
      return retval;
    }
    
    public static String getSQLField(HttpSecureAppServlet servlet, VariablesSecureApp vars,String adFieldOREGColumnORFGColumnID, String IDValue, String keyFieldname) throws Exception  {
      /* This Method can Complete a Firld Group wth dynamic Data in SQL Form
       * It ececutes the following way:
       * If an SQL-Default is set on a Field of TEMPLATE SQLField, it is executed and returned.
       */
      String retval="";
      String defaultstmt=FormDisplayLogicData.fieldGetDefault(servlet, adFieldOREGColumnORFGColumnID);
      if (defaultstmt.startsWith("@SQL=")){
          defaultstmt=defaultstmt.replaceAll("(?i)@" + keyFieldname + "@", "'" + IDValue + "'") ;
          //defaultstmt=Replace.replace(defaultstmt, "@" + keyFieldname.toLowerCase() + "@" , "'" + IDValue + "'");
          String sql="";
       
          sql=tokenizeSQL(servlet,vars,defaultstmt.substring(5, defaultstmt.length()),adFieldOREGColumnORFGColumnID);
          retval=GenericFieldProviderData.getSQL(servlet,sql);
          return retval;
        }
      return retval;
    }
    
    public static String getSQLValueByStatement(HttpSecureAppServlet servlet, VariablesSecureApp vars,String statement, String IDValue, String keyFieldname) throws Exception  {
        /* This Method can Complete a Firld Group wth dynamic Data in SQL Form
         * It ececutes the following way:
         * If an SQL-Default is set on a Field of TEMPLATE SQLField, it is executed and returned.
         */
        String retval="";
        if (statement.startsWith("@SQL=")){
        	statement=statement.replaceAll("(?i)@" + keyFieldname + "@", "'" + IDValue + "'") ;
        	//statement=Replace.replace(statement, "@" + keyFieldname.toLowerCase() + "@" , "'" + IDValue + "'");
            String sql="";
           
            // 1St Get Default from Smartprefs (Overwrites all other Defaults;
         
            sql=tokenizeSQL(servlet,vars,statement.substring(5, statement.length()),"");
            retval=GenericFieldProviderData.getSQL(servlet,sql);
            return retval;
          }
        return statement;
      }
    
    public static FieldProvider[] getSQLStatementData(HttpSecureAppServlet servlet, VariablesSecureApp vars,String statement, String IDValue, String keyFieldname) throws Exception  {
        /* This Method can Complete a Firld Group wth dynamic Data in SQL Form
         * It ececutes the following way:
         * If an SQL-Default is set on a Field of TEMPLATE SQLField, it is executed and returned.
         */
    	FieldProvider[] retval;
        if (statement.startsWith("@SQL=")){
        	//statement=statement.toLowerCase();
            if (keyFieldname!=null &&  IDValue != null)
            	statement=statement.replaceAll("(?i)@" + keyFieldname + "@", "'" + IDValue + "'") ;
            	//statement=Replace.replace(statement, "@" + keyFieldname.toLowerCase() + "@" , "'" + IDValue + "'");
            String sql="";
           
            // 1St Get Default from Smartprefs (Overwrites all other Defaults;
         
            sql=tokenizeSQL(servlet,vars,statement.substring(5, statement.length()),"");
            // Get the Result set in generic form...
            retval=org.openz.model.GenericFieldProviderData.select(servlet, sql);
            return retval;
          }
        return null;
      }
    
    public static String evaluateLogicTrue(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String logic,String adFieldId) throws Exception {
      /*
        * RULES for Session-Vars and Form-Fields:
        * @SQL= If the logic begins like that, it is evaluated as SQL (SQL-Staement must return the string TRUE
        * @xyz@ is assumed to be  a Form Field, when it is, the Value of the Field in the Form is evaluated
        * If it is no Field in the Form. a session - Var is assumed. The session Var is evaluated and returned
        * If a session Var is assumed, In HTML a hidden Field is generated. it has the convention 'str<fieldname>' (Case Sensitive)
      */
      String retval="if (";
      int operatorposition=0;
      int beginposition=0;
      int equal=0;
      int unequal=0;
      int greater=0;
      int smaller=0;
      int itemlength=0;
      String leftside="";
      String rightside="";
      String operator="";
      String fieldname="";
      String sql="";
      if (logic.startsWith("@SQL=")){
        sql=tokenizeSQL(servlet,vars,logic.substring(5, logic.length()),adFieldId);
        retval="if ('" + GenericFieldProviderData.getSQL(servlet,sql).toUpperCase() + "'=='TRUE'){\n";
        return retval;
      }
      while (true) {
        equal=logic.indexOf("=", beginposition+1);
        unequal=logic.indexOf("!", beginposition+1);
        greater=logic.indexOf(">", beginposition+1);
        smaller=logic.indexOf("<", beginposition+1);
        if (equal==-1 && unequal==-1 && greater==-1 && smaller==-1)
          break;
        if (equal==-1)
          equal=10000;
        if (unequal==-1)
          unequal=10000;
        if (greater==-1)
          greater=10000;
        if (smaller==-1)
          smaller=10000;
        if (equal<unequal && equal<greater && equal<smaller ) {
          operatorposition=logic.indexOf("=", beginposition+1);
          operator="==";
          leftside=logic.substring(beginposition, operatorposition);
          rightside=logic.substring(operatorposition+1,nextoperatorposition(logic,operatorposition+1)-1);
          itemlength=1+leftside.length()+rightside.length();
        }
        if (unequal<equal && unequal<greater && unequal<smaller ) {
          operatorposition=logic.indexOf("!", beginposition);
          operator="!=";
          leftside=logic.substring(beginposition, operatorposition);
          rightside=logic.substring(operatorposition+1,nextoperatorposition(logic,operatorposition+1)-1);
          itemlength=1+leftside.length()+rightside.length();
        }
        if (greater<equal && greater<unequal && greater<smaller ) {
          operatorposition=logic.indexOf(">", beginposition);
          operator=">";
          itemlength=1;
          leftside=logic.substring(beginposition, operatorposition);
          if (logic.substring(operatorposition+1, 1).equals("=")){
            operator=">=";
            itemlength=2;
            operatorposition=operatorposition++;
          }
          rightside=logic.substring(operatorposition,nextoperatorposition(logic,operatorposition+1)-1);
          itemlength=itemlength+leftside.length()+rightside.length();
        } 
        if (smaller<equal && smaller<unequal && smaller<greater ) {
          operatorposition=logic.indexOf("<", beginposition);
          operator="<";
          itemlength=1;
          leftside=logic.substring(beginposition, operatorposition);
          if (logic.substring(operatorposition+1, 1).equals("=")){
            operator="<=";
            itemlength=2;
            operatorposition=operatorposition++;
          }
          rightside=logic.substring(operatorposition,nextoperatorposition(logic,operatorposition+1)-1);
          itemlength=itemlength+leftside.length()+rightside.length();
        } 
        if (leftside.contains("@")){
          fieldname=leftside.substring(leftside.indexOf("@")+1,leftside.lastIndexOf("@")).replace("#","");
          if (FormDisplayLogicData.isFieldInForm(servlet, adFieldId, fieldname).equals("Y"))
            leftside=leftside.substring(0,leftside.indexOf("@")) + "inputValue(document.frmMain.inp" +Sqlc.TransformaNombreColumna(fieldname.toLowerCase()) + ")" + leftside.substring(leftside.lastIndexOf("@")+1,leftside.length());  
          else{
            leftside=leftside.substring(0,leftside.indexOf("@")) + "inputValue(document.frmMain.str" +fieldname + ")" + leftside.substring(leftside.lastIndexOf("@")+1,leftside.length());  
            script.addHiddenfield("str" + fieldname, getValueByName(servlet,vars,fieldname));
          }
        }
        leftside=Replace.replace(leftside,"&","&&");
        leftside=Replace.replace(leftside,"|","||");
        if (rightside.contains("@")){
          fieldname=rightside.substring(1,leftside.length()-1).replace("#","");
          if (FormDisplayLogicData.isFieldInForm(servlet, adFieldId, fieldname).equals("Y"))
            rightside="inputValue(document.frmMain.inp" +Sqlc.TransformaNombreColumna(fieldname.toLowerCase()) + ")";  
          else{
            rightside="inputValue(document.frmMain.str" +fieldname + ")";  
            script.addHiddenfield("str" + fieldname, getValueByName(servlet,vars,fieldname));
          }
        }
        retval=retval+leftside+operator+rightside;
        beginposition=beginposition+itemlength;
    }
      if ( ! retval.equals("if ("))
        return retval + ") {\n";
      else
        return "";
    }
    
    private static int nextoperatorposition(String logic, int beginpos){
     int nextoperatorpos=1000000;
     int  i=logic.indexOf("=", beginpos);
     if (i>-1 && i < nextoperatorpos)
       nextoperatorpos=i;
     i=logic.indexOf("!", beginpos);
     if (i>-1 && i < nextoperatorpos)
       nextoperatorpos=i;
     i=logic.indexOf(">", beginpos);
     if (i>-1 && i < nextoperatorpos)
       nextoperatorpos=i;
     i=logic.indexOf("<", beginpos);
     if (i>-1 && i < nextoperatorpos)
       nextoperatorpos=i;
     i=logic.indexOf("&", beginpos);
     if (i>-1 && i < nextoperatorpos)
       nextoperatorpos=i;
     i=logic.indexOf("|", beginpos);
     if (i>-1 && i < nextoperatorpos)
       nextoperatorpos=i;
     if (nextoperatorpos==1000000)
      nextoperatorpos=logic.length()+1;
     return nextoperatorpos;
    }
    
    private static String getValue(HttpSecureAppServlet servlet,VariablesSecureApp vars,String sessionvar) throws Exception {
      /*
       * Evaluates Session-Vars for a given field ID
       * 1. If we are in a Window, a WindowID|<fieldname> Session Var is tested
       * 2. If it has no Value, a <fullyqualifiedformclassname>|<fieldname> Session Var is tested
       * 3. If it has no Value, a <fieldname> Session Var is tested (completely qualified)
       * 4. If it has no Value, a Preference-Parameter (P|<fieldname>) or P|<WindowID><fieldname> is tested.
       * Session-Vars are Set as Uppercase in the server. in java-code they are not case-sensitive.
      */
      String retval="";
      String windowid=servlet.getWindowId();
      //FormDisplayLogicData.fieldGetWindowID(servlet, fieldid);
      String fieldname=sessionvar.replace("@", "");
      //FormDisplayLogicData.fieldGetName(servlet, fieldid);
      if (!windowid.isEmpty())
        retval=vars.getSessionValue(windowid + "|" + fieldname);
      if (retval.equals(""))
        retval=vars.getSessionValue(servlet.getClass().getName() + "|" + fieldname);
      if (retval.equals(""))
        retval=vars.getSessionValue(fieldname);
      if (retval.equals(""))
        retval=vars.getSessionValue("P" + "|" + windowid + "|"+ fieldname);
      if (retval.equals(""))
        retval=vars.getSessionValue("P" + "|" + fieldname);
    return retval;
    }
    private static String getValueByName(HttpSecureAppServlet servlet,VariablesSecureApp vars,String name) throws Exception {
      /*
       * Evaluates Session-Vars for a given name
       * 1. If we are in a Window, a WindowID|<name> Session Var is tested
       * 2. If it has no Value, a <fullyqualifiedformclassname>|<name> Session Var is tested
       * 3. If it has no Value, a <name> Session Var is tested (completely qualified)
       * 4. If it has no Value, a Preference-Parameter (P|<name>) or P|<WindowID><name> is tested.
       * Session-Vars are Set as Uppercase in the server. in java-code they are not case-sensitive.
      */
      String retval="";
      String windowid=servlet.getWindowId();
      if (windowid!=null)
        retval=vars.getSessionValue(windowid + "|" + name);
      if (retval.equals(""))
        retval=vars.getSessionValue(servlet.getClass().getName() + "|" + name);
      if (retval.equals(""))
        retval=vars.getSessionValue(name);
      if (retval.equals(""))
        retval=vars.getSessionValue("P" + "|" + windowid + "|"+ name);
      if (retval.equals(""))
        retval=vars.getSessionValue("P" + "|" + name);
      if (retval.equals(""))
        retval=vars.getSessionValue("#" + "|" + name);
    return retval;
    }
    
    public static String tokenizeSQL(HttpSecureAppServlet servlet,VariablesSecureApp vars,String sql,String fieldid) throws Exception {
      /*
       * Returns the executable SQL from raw form with @-Tags
       * RULES for Session-Vars and Form-Fields:
       * @xyz@ is assumed to be  a Form Field, when it is, the Value of the Field in the Form is evaluated
       * If it is no Field in the Form. a session - Var is assumed. The session Var is evaluated and returned
       * If a session Var is assumed, In HTML a hidden Field is generated. it has the convention 'str<fieldname>' (Case Sensitive)
     */
      String growup="";
      String tokenvalue="";
      int beginposition=0;
      int oldend=0;
      int endposition=-1;
      String token="";
      while (true) {
        oldend=endposition+1;
        beginposition=sql.indexOf("@", oldend);
        if (beginposition==-1) {
          growup=growup+sql.substring(oldend,sql.length());
          break;
        }
        endposition=sql.indexOf("@",beginposition+1);
        token=sql.substring(beginposition+1, endposition);
        if (FormDisplayLogicData.isFieldInFormWOPrimaryKey(servlet, fieldid, token).equals("Y") && ! servlet.getCommandtype().equals("NEW")) {
          //String datatype=FormDisplayLogicData.FieldGetDataType(servlet, fieldid);
          // if (datatype.equals("NUMERIC"))
          // Quicker Code: Try to get a field numeric, if Error, Try to Get it as string.
          try {
            tokenvalue=vars.getNumericParameter("inp" + Sqlc.TransformaNombreColumna(token.toLowerCase()));
          } catch (final Exception e) {
            tokenvalue=vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(token.toLowerCase()));
          }
          if (tokenvalue.isEmpty())
            tokenvalue=getValueByName(servlet,vars,token);
        }
        else{
          tokenvalue=getValueByName(servlet,vars,token);
          if (tokenvalue.isEmpty() && token.equals("CommandType"))
            tokenvalue=vars.getCommand();
        }
        tokenvalue="'" + tokenvalue + "'";
        growup=growup + sql.substring(oldend,beginposition)+tokenvalue;
        tokenvalue="";
      }
      return growup.equals("") ? sql : growup;
    }
    
    
    public static GridData[] getDynamicGridColumns(HttpSecureAppServlet servlet,VariablesSecureApp vars,String sql) throws Exception {

      String testsql=tokenizeSQL(servlet,vars,sql,null);
      
          GridData.set();
      Connection dbcon = servlet.getConnection();
      Statement stmt = dbcon.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
          ResultSet.CONCUR_READ_ONLY);
      ResultSet srs = stmt.executeQuery(testsql);
      int i = 0;
      while (srs.next()) {
        i++;
      }
      GridData[] cols =  new GridData[i];
      srs.first();
      i=0;
      while ((i==0 || srs.next()) && i<cols.length) {
        cols[i]=new GridData();
        cols[i].name=srs.getString("value");
        cols[i].adRefGridcolumnId="DYNAMIC";
        cols[i].template=srs.getString("template");
        cols[i].headertext=srs.getString("name");
        i++;
      }
      dbcon.close();
      
      return cols;
    
  }
    public static int getDynamicGridColCount(HttpSecureAppServlet servlet,VariablesSecureApp vars,String sql) throws Exception {

      String testsql=tokenizeSQL(servlet,vars,sql,null);
      
      Connection dbcon = servlet.getConnection();
      Statement stmt = dbcon.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
          ResultSet.CONCUR_READ_ONLY);
      ResultSet srs = stmt.executeQuery(testsql);
      int i = 0;
      while (srs.next()) {
        i++;
      }     
      return i;
    
  }
}
