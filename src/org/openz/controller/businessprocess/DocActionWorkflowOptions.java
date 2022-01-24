/*
***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************
 */
package org.openz.controller.businessprocess;

import java.util.Vector;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.VariablesSecureApp;
import javax.servlet.ServletException;
import org.openbravo.data.FieldProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.SQLReturnObject;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;

public class DocActionWorkflowOptions {
  static Logger log4j = Logger.getLogger(DocActionWorkflowOptions.class);

  public static FieldProvider[] docAction(ConnectionProvider conn, VariablesSecureApp vars,
      String strDocAction, String strReference, String strDocStatus, String strProcessing,
      String strTable, String key) throws ServletException {
  FieldProvider[] ld = null;
  if (log4j.isDebugEnabled())
    log4j.debug("DocAction - generating combo elements for table: " + strTable
        + " - actual status: " + strDocStatus);
  try {
    /*
    ComboTableData comboTableData = new ComboTableData(vars, conn, "LIST", "DocAction",
        strReference, "", Utility.getContext(conn, vars, "#AccessibleOrgTree",
            "ActionButtonUtility"), Utility.getContext(conn, vars, "#User_Client",
            "ActionButtonUtility"), 0);
    Utility.fillSQLParameters(conn, vars, null, comboTableData, "ActionButtonUtility", "");
    ld = comboTableData.select(false);
    */
    ComboTableDataWrapper comboTableData = new ComboTableDataWrapper(conn,vars,"All_Document Action","");
    ld = comboTableData.select(false);
    comboTableData = null;
  
  SQLReturnObject[] data = null;
  // Take the complete List first, random Table - Then go to specific Tables
  // This is the complete LOGIC of Processing Documents in OpenZ
  if (ld != null) {
    Vector<Object> v = new Vector<Object>();
    SQLReturnObject data1 = new SQLReturnObject();
    // Documents that are In Process may be reactivated.
    if (!strProcessing.equals("") && strProcessing.equals("Y") && !strTable.equals("E5A34E9B2AE84350B2B1E5A3FE61EFBA")) {
      data1 = new SQLReturnObject();
      data1.setData("ID", "XL");
      v.addElement(data1);
    }
    String strUser = vars.getUser();
    //Order Document Workflow
    //
    if (strTable.equals("259") || strTable.equals("E5A34E9B2AE84350B2B1E5A3FE61EFBA")) { // C_Order or c_subscriptioninterval_view
        if (strDocStatus.equals("DR")) {
          data1 = new SQLReturnObject();
          data1.setData("ID", "PR");
          v.addElement(data1);
          data1 = new SQLReturnObject();
          data1.setData("ID", "CO");
          v.addElement(data1);
          data1 = new SQLReturnObject();
          data1.setData("ID", "VO");
          v.addElement(data1);
        }       
        if (strDocStatus.equals("IP")) {
          data1 = new SQLReturnObject();
          data1.setData("ID", "CO");
          v.addElement(data1);
          data1 = new SQLReturnObject();
          data1.setData("ID", "VO");
          v.addElement(data1);
        } else if (strDocStatus.equals("CO")) {
          data1 = new SQLReturnObject();
          data1.setData("ID", "RE");
          v.addElement(data1);
          data1 = new SQLReturnObject();
          data1.setData("ID", "VO");
          v.addElement(data1);
          if (DocActionWorkflowData.getDoctypeFromOrder(conn, key).equals("8CF74AC370B04133B54C44A12E084749")) {
          // Request for Quotation (Anfrage PO) can be closed
        	  data1 = new SQLReturnObject();
        	  data1.setData("ID", "CL");
        	  v.addElement(data1);
          }
        }
    //Invoice Document Workflow
    //
    } else if (strTable.equals("318") || strTable.equals("EE67F42B5F284C228D381E8511024DA5")) { // C_Invoice
      if (strDocStatus.equals("DR")) { //Draft
        
        if (DocActionWorkflowData.isPOProjectworkflow(conn, key, strUser).equals("Y")){
          data1 = new SQLReturnObject();
          data1.setData("ID", "AP");
          v.addElement(data1);
        }
        else{
          data1 = new SQLReturnObject();
          data1.setData("ID", "CO");
          v.addElement(data1);
        }
        
        data1 = new SQLReturnObject();
        data1.setData("ID", "VO");
        v.addElement(data1);
      }
      if (strDocStatus.equals("CO")) { //Completed
        data1 = new SQLReturnObject();
        data1.setData("ID", "RC");
        v.addElement(data1);
        data1 = new SQLReturnObject();
        data1.setData("ID", "RE");
        v.addElement(data1);
      }
      if (strDocStatus.equals("IP")) { //In Process
        if (DocActionWorkflowData.hasApproverRights(conn, key, strUser).equals("Y")){
          data1 = new SQLReturnObject();
          data1.setData("ID", "RJ");
          v.addElement(data1);
          data1 = new SQLReturnObject();
          data1.setData("ID", "CO");
          v.addElement(data1);
        }
      }
      if (strDocStatus.equals("NA")) { //Rejected
        data1 = new SQLReturnObject();
        data1.setData("ID", "RE");
        v.addElement(data1);
      }
    //Material IN Out Document Workflow
    //
    } else if (strTable.equals("319")||strTable.equals("B75206D568364642A5E6B8EE5F565E32")||
        strTable.equals("028C435C1C944E67A28816E7F54AC5DE")) { // M_InOut, ils_inout_v, ils_inoutpackage_v
      if (strDocStatus.equals("DR")) {
        data1 = new SQLReturnObject();
        data1.setData("ID", "CO");
        v.addElement(data1);
      }
      if (strDocStatus.equals("CO")) {
        data1 = new SQLReturnObject();
        data1.setData("ID", "RC");
        v.addElement(data1);
      }
    //Requisition  Document Workflow
    //
    } else if (strTable.equals("800212")) { // M_Requisition
      if (strDocStatus.equals("DR")) {
        data1 = new SQLReturnObject();
        data1.setData("ID", "CO");
        v.addElement(data1);
      }       
      if (strDocStatus.equals("CO")) {
        data1 = new SQLReturnObject();
        data1.setData("ID", "RE");
        v.addElement(data1);
        data1 = new SQLReturnObject();
        data1.setData("ID", "CL");
        v.addElement(data1);
      }
      // All other Dokuments -> allow from Draft to Void and Active ; Allow from Active to Void and Draft
      }  else {
    	  if (strDocStatus.equals("DR")) {
              data1 = new SQLReturnObject();
              data1.setData("ID", "CO");
              v.addElement(data1);
              data1 = new SQLReturnObject();
              data1.setData("ID", "VO");
              v.addElement(data1);
            }       
           if (strDocStatus.equals("CO")) {
              data1 = new SQLReturnObject();
              data1.setData("ID", "RE");
              v.addElement(data1);
              data1 = new SQLReturnObject();
              data1.setData("ID", "VO");
              v.addElement(data1);
           }
      }

      data = new SQLReturnObject[v.size()];
      v.copyInto(data);
      if (log4j.isDebugEnabled())
        log4j.debug("DocAction - total combo elements: " + data.length);
      for (int i = 0; i < data.length; i++) {
        if (log4j.isDebugEnabled())
          log4j.debug("DocAction - Element: " + i + " - ID: " + data[i].getField("ID"));
        for (int j = 0; j < ld.length; j++) {
          if (data[i].getField("ID").equals(ld[j].getField("ID"))) {
            data[i].setData("NAME", ld[j].getField("NAME"));
            data[i].setData("DESCRIPTION", ld[j].getField("DESCRIPTION"));
            break;
          }
        }
      }
    }
    return data;
    } catch (Exception e) {
      throw new ServletException(e);
    }
  }

}
