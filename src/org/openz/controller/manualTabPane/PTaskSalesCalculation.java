package org.openz.controller.manualTabPane;


/*****************************************************************************************************************************************************
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
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletResponse;

import org.openz.view.*;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openz.view.templates.*;
import org.openbravo.utils.Replace;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;


public class PTaskSalesCalculation implements ManualTabPane{

  public String getFormEdit(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,WindowTabs tabs,HttpServletResponse response,ToolBar stdtoolbar) throws Exception{
    String toolbarid=FormhelperData.getTabEditionToolbar(servlet,servlet.getClass().getName());
    Scripthelper script = new Scripthelper();
    PTaskSalesCalculationData[] GridData;
    String strProjecttaskid=vars.getSessionValue("130|c_projecttask_id");
    String strOrgid=vars.getSessionValue("130|ad_org_id");
    script.addHiddenfield("inpadOrgId", strOrgid);
    String strCommand=vars.getStringParameter("inpCommandType");
    servlet.setCommandtype("");
    String strUser=vars.getUser();
    EditableGrid grid;
    Vector <String> retval;
    String strClientId=vars.getClient();
    String msg="";
    String msgType="SUCCESS";
    String msgHeader="Success";
    String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
    
    
    try {
      // SAVE-ACTION
      if (strCommand.equals("SAVE")) {
        
        grid = new EditableGrid("PTaskSalesCalculationGrid", vars, servlet);
        retval=grid.getSelectedIds(servlet, vars, "c_projecttask_id");

        //Strings for Employees
        String strHRPId;
        
        //EMPLOYEE Stuff 
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          String strName=grid.getValue(servlet, vars, strHRPId, "name");
          String strMarginPercent=grid.getValue(servlet, vars, strHRPId, "margin_percent");
          String strShiftQty=grid.getValue(servlet, vars, strHRPId, "shift_qty");
          String strEmployeeQty=grid.getValue(servlet, vars, strHRPId, "employee_qty"); 
          String strtaskCancelled=grid.getValue(servlet, vars, strHRPId, "istaskcancelled");
           
            // INsert or Update?
          //  if (PTaskSalesCalculationData.isExistingID(servlet, strHRPId).equals("0")){
            //  String StrPID=PTaskSalesCalculationData.getProjectID(servlet,strHRPId);
              //PTaskSalesCalculationData.insert( servlet,strOrgid,strUser, StrPID,strHRPId,strName,strMarginPercent,strShiftQty,strEmployeeQty);}
            //else{
             // String StrPID=PTaskSalesCalculationData.getProjectID(servlet,strHRPId);
              PTaskSalesCalculationData.update( servlet,strUser, strMarginPercent,strShiftQty,strEmployeeQty,strtaskCancelled,strHRPId);
            if (msg.isEmpty()){              
              msg=Utility.messageBD(servlet, "SalesCalculationUpdated",vars.getLanguage());
            }
          }
        }

            if (msg.isEmpty()){              
              msg=Utility.messageBD(servlet, "SalesCalculationUpdated",vars.getLanguage());
          }
          
         
        
      
    
//DELETATION
      if (strCommand.equals("DELETE")) {
        String strHRPId;
        grid = new EditableGrid("PTaskSalesCalculationGrid", vars, servlet);
        retval=grid.getSelectedIds(servlet, vars, "c_projecttask_id");
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          PTaskSalesCalculationData.delete( servlet, strHRPId);
          msg=Utility.messageBD(servlet, "SalesCalculationUpdated",vars.getLanguage());
        }
      }
    } catch (final ServletException ex) {
      final OBError myError = Utility.translateError(servlet, vars, vars.getLanguage(), ex.getMessage());
      msg=myError.getMessage();
      msgHeader=myError.getTitle();
      msgType=myError.getType();       
    } 
    // GUI
    String strLeftabsmode=FormhelperData.getLeftTabsMode4Tab(servlet,servlet.getClass().getName());
    if (!msg.equals(""))
      script.addMessage(servlet, vars, msgType, msgHeader,msg);
    String strSkeleton = ConfigureFrameWindow.doConfigureWindowMode(servlet,vars,"description",tabs.breadcrumb(), "Test Form Window",toolbarid,strLeftabsmode,tabs,"_Relation",null);
    Formhelper fh=new Formhelper();
    
    grid = new EditableGrid("PTaskSalesCalculationGrid", vars, servlet);
    GridData=PTaskSalesCalculationData.select(servlet, strProjecttaskid );
    String strGrid = grid.printGrid(servlet, vars, script, GridData); 

    
    String strTableStructure=fh.prepareFieldgroup(servlet, vars, script, "PTaskCalculationSalesHeader",null,true);
    PTaskSalesCalculationData[] salesdata= PTaskSalesCalculationData.getSums(servlet,strProjecttaskid);
    String strSumCalculationSales=fh.prepareFieldgroup(servlet, vars, script, "SumPTaskCalculationFG",salesdata[0],true);
    strSkeleton=Replace.replace(strSkeleton, "@CONTENT@", strTableStructure + strGrid + "<br>"+strSumCalculationSales+"<br>");  
    strSkeleton=Replace.replace(strSkeleton, "display: table-row;", "display:none;");
    script.addHiddenfieldWithID("enabledautosave", "N");
    strSkeleton = script.doScript(strSkeleton, "",servlet,vars);
    return strSkeleton;
  }
  public void setFormSave(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,Connection con){
	  
  }
}
