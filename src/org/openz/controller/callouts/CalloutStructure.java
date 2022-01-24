package org.openz.controller.callouts;
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

import org.openbravo.utils.FormatUtilities;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;

public class CalloutStructure {
     private XmlDocument xmlDocument;
     private StringBuffer resultado = new StringBuffer();
     
     public CalloutStructure(HttpSecureAppServlet servlet, String calloutname){
       xmlDocument = servlet.xmlEngine.readXmlTemplate(
           "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();
       resultado.append("var calloutName='"+ calloutname + "';\n\n");
       resultado.append("var respuesta = new Array(");
     }
     
     public void appendString(String name,String value){
       resultado.append("new Array(\"" + name + "\", "+ (value.equals("") ?  "\"": "\"" + FormatUtilities.replaceJS(value)) + "\"),");
     }
     
     public void appendNumeric(String name,String value){
       resultado.append("new Array(\"" + name + "\", " + (value.equals("") ? "\"\"" : value) + "),");
     }
     
     
     
     public void appendMessage(String value,HttpSecureAppServlet servlet,VariablesSecureApp vars){
       String message = Utility.messageBD(servlet, value, vars.getLanguage());
       if (message.equals(""))
         message=value;
       resultado.append("new Array('MESSAGE', \""
           + FormatUtilities.replaceJS(message) + "\"),\n");
     }
     /**
      * Gets a  Combo to the Callout
      * 
      * @param name
      *          Name of Field in Form (inp....) - Convention
      * @param combolist
      *          Data to Load in the Combo
      * @param currentId
      *          String with the Current ID - Value
      *          Special Function: "none" - Selects no Value
      *                            "first" - Selects first value
      *          This parameter must not be null 
      */
     public void appendComboTable(String name,FieldProvider[] combolist, String currentId){

       resultado.append(" new Array(\"" + name + "\", ");
       if (combolist != null && combolist.length > 0) {
         resultado.append("new Array(");
         String cnotnull;
         for (int i = 0; i < combolist.length; i++) {
           resultado.append("new Array(\"" + combolist[i].getField("id") + "\", \""
               + FormatUtilities.replaceJS(combolist[i].getField("name")) + "\", \""
               + ((currentId.equals("first") && i == 0)||currentId.equals(combolist[i].getField("id")) ? "true" : "false") + "\")");
           if (i < combolist.length - 1)
             resultado.append(",\n");
         }
         resultado.append("\n)");
       } else
         resultado.append("null");
       resultado.append("\n),");
     }
     
     public String returnCalloutAppFrame(){
       String retval;
       resultado.append("new Array(\"EXECUTE\", \"displayLogic();\")\n");

       resultado.append(");");
       xmlDocument.setParameter("array", resultado.toString());
       xmlDocument.setParameter("frameName", "appFrame");
       retval=xmlDocument.print();
       return retval;
     }
     public String returnCalloutMainFrame(){
       String retval;
       resultado.append("new Array(\"EXECUTE\", \"displayLogic();\")\n");

       resultado.append(");");
       xmlDocument.setParameter("array", resultado.toString());
       xmlDocument.setParameter("frameName", "mainframe");
       xmlDocument.setParameter("frameName1", "mainframe");
       retval=xmlDocument.print();
       return retval;
     }
     
}
