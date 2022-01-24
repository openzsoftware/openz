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


public class ProjectRessourcesPlan implements ManualTabPane{

  public String getFormEdit(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,WindowTabs tabs,HttpServletResponse response,ToolBar stdtoolbar) throws Exception{
    String toolbarid=FormhelperData.getTabEditionToolbar(servlet,servlet.getClass().getName());
    Scripthelper script = new Scripthelper();
    PTaskEmployeesData[] GridData;
    PTaskEquipmentData[] GridData2;
    PTaskExpensesData[] GridData3;
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
        
        grid = new EditableGrid("PTaskEmployeeGrid", vars, servlet);
        retval=grid.getSelectedIds(servlet, vars, "zspm_ptaskhrplan_id");

        //Strings for Employees
        String strDescription,strHRPId,strCategory,strQty,strPlannedUser,strovertimehours,strnighthours,strsaturday,strsunday,strholiday,strspecialtime1,strspecialtime2,strtriggeramt,strdatefrom,strdateto;
        
        //EMPLOYEE Stuff
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          String strDesc=grid.getValue(servlet, vars, strHRPId, "description");
          strCategory=grid.getValue(servlet, vars, strHRPId, "c_salary_category_id");
          if (strCategory.isEmpty()) {
            
            msg=Utility.messageBD(servlet, "needSalaRyCategoryToPlanResource",vars.getLanguage());
            msgType="ERROR";
            msgHeader="Error";
          }
          String strHours=grid.getValue(servlet, vars, strHRPId, "hours");
          String strShifts=grid.getValue(servlet, vars, strHRPId, "shifts");
          String strHoursTotal=grid.getValue(servlet, vars, strHRPId, "quantity");
          String triggerday=grid.getValue(servlet, vars, strHRPId, "triggerday");
          strtriggeramt=grid.getValue(servlet, vars, strHRPId, "triggeramt");
          String stremployeeAmt=grid.getValue(servlet, vars, strHRPId, "employee_amt");
          if (!strCategory.isEmpty()) {
            // INsert or Update?
            if (PTaskEmployeesData.isExistingID(servlet, strHRPId).equals("0"))
              PTaskEmployeesData.insert( servlet, strHRPId,strOrgid, strProjecttaskid,strUser, strCategory, strHours,strDesc,strShifts,strHoursTotal,triggerday,strtriggeramt,stremployeeAmt);
            else
              PTaskEmployeesData.update( servlet,strUser, strCategory, strHours, strDesc,
                  strShifts,strHoursTotal,triggerday,strtriggeramt,stremployeeAmt,strHRPId);
            if (msg.isEmpty()){              
              msg=Utility.messageBD(servlet, "CalculationUpdated",vars.getLanguage());
            }
          }
        }
        //EQUIPMENT Stuff
//        //Strings for Equipment
        grid = new EditableGrid("PTaskEquipmentGrid", vars, servlet);
        retval=grid.getSelectedIds(servlet, vars, "zspm_ptaskmachineplan_id");

        String strMachine,strMachSeqNo, strEQId, strMachLine,strMachQty, strQtyMachine, strCostUOM, strMachCalcQty, strplannedAmt;
        for (int i = 0; i < retval.size(); i++) {
          strEQId=retval.elementAt(i); 
          strMachine=grid.getValue(servlet, vars, strEQId, "machine");
          strMachSeqNo=grid.getValue(servlet, vars, strEQId, "seqno");
          strMachQty=grid.getValue(servlet, vars, strEQId, "machine_qty");
          strCostUOM=grid.getValue(servlet, vars, strEQId, "costuom");
          strMachCalcQty=grid.getValue(servlet, vars, strEQId, "calculated_qty");
          strQtyMachine=grid.getValue(servlet, vars, strEQId, "qty");
          strplannedAmt=grid.getValue(servlet, vars, strEQId, "total");
          if(strMachine==null )
            strMachine="";
          if (strMachine!=""){
            // INsert or Update?
            if (PTaskEquipmentData.isExistingID(servlet, strEQId).equals("0"))
              PTaskEquipmentData.insert(servlet, strEQId,strProjecttaskid, strClientId, strOrgid, strUser, strMachine,strQtyMachine, strMachCalcQty, strMachQty, strCostUOM);
            else
              PTaskEquipmentData.update(servlet,strMachine, strMachQty, strCostUOM, strMachCalcQty, strQtyMachine,strEQId);
            if (msg.isEmpty()){              
              msg=Utility.messageBD(servlet, "CalculationUpdated",vars.getLanguage());
            }
          
        } }
        grid = new EditableGrid("PTaskExpensesGrid", vars, servlet);
        retval=grid.getSelectedIds(servlet, vars, "c_projecttaskexpenseplan_id");
        //Strings for Expenses
        String strExpenseplanID,strEXId, strLine, plannedAmt="0", strProduct,strDesc, strCalcQty, strCost, strExSeqno;
        
        for (int i = 0; i < retval.size(); i++) {
          strEXId=retval.elementAt(i);
          strProduct=grid.getValue(servlet, vars, strEXId, "product");
          strDesc=grid.getValue(servlet, vars, strEXId, "description");
          strCalcQty=grid.getValue(servlet, vars, strEXId, "qty");
          strCost=grid.getValue(servlet, vars, strEXId, "cost");
          strExSeqno=grid.getValue(servlet, vars, strEXId, "seqno");
          // INsert or Update?

            if (PTaskExpensesData.isExistingID(servlet, strEXId).equals("0"))
              PTaskExpensesData.insert(servlet, strEXId,strProjecttaskid,strExSeqno, plannedAmt, strClientId, strOrgid, strUser, strProduct,strDesc, strCalcQty, strCost);
            else
              PTaskExpensesData.update(servlet,strProduct, strDesc, strCalcQty, strCost, strEXId);
            if (msg.isEmpty()){              
              msg=Utility.messageBD(servlet, "CalculationUpdated",vars.getLanguage());
          }
          
        } 
        
      }  
    
//DELETATION
      if (strCommand.equals("DELETE")) {
        String strHRPId;
        grid = new EditableGrid("PTaskEmployeeGrid", vars, servlet);
        retval=grid.getSelectedIds(servlet, vars, "zspm_ptaskhrplan_id");
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          PTaskEmployeesData.delete( servlet, strHRPId);
          msg=Utility.messageBD(servlet, "CalculationUpdated",vars.getLanguage());
        }
        grid = new EditableGrid("PTaskEquipmentGrid", vars, servlet);
        retval=grid.getSelectedIds(null, vars, "zspm_ptaskmachineplan_id");
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          PTaskEquipmentData.delete(servlet, strHRPId);
          msg=Utility.messageBD(servlet, "CalculationUpdated",vars.getLanguage());
        }
        grid = new EditableGrid("PTaskExpensesGrid", vars, servlet);
        retval=grid.getSelectedIds(null, vars, "c_projecttaskexpenseplan_id");
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          PTaskExpensesData.delete(servlet, strHRPId);
          msg=Utility.messageBD(servlet, "CalculationUpdated",vars.getLanguage());
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
    
    grid = new EditableGrid("PTaskEmployeeGrid", vars, servlet);
    GridData=PTaskEmployeesData.selectnew(servlet, strProjecttaskid);
    String strGrid = grid.printGrid(servlet, vars, script, GridData); 
    
    grid = new EditableGrid("PTaskEquipmentGrid", vars, servlet);
    GridData2=PTaskEquipmentData.selectnew(servlet, strProjecttaskid);    
    String strGrid2 = grid.printGrid(servlet, vars, script, GridData2);
    
    grid = new EditableGrid("PTaskExpensesGrid", vars, servlet);
    GridData3=PTaskExpensesData.selectnew(servlet, strProjecttaskid);  
    String strGrid3= grid.printGrid(servlet, vars, script, GridData3);
    
    String strTableStructure=fh.prepareFieldgroup(servlet, vars, script, "PTaskCalculationHeaderFG",null,true);
    PTaskEmployeesData[] empdata= PTaskEmployeesData.getSums(servlet,strProjecttaskid);
    String strSumEmployees=fh.prepareFieldgroup(servlet, vars, script, "SumEmployeesFG",empdata[0],true);
    PTaskEquipmentData[] equdata=PTaskEquipmentData.getSums(servlet,strProjecttaskid);
    String strSumEquipment=fh.prepareFieldgroup(servlet, vars, script, "SumEquipmentFG",equdata[0],true);
    PTaskExpensesData[] expdata=PTaskExpensesData.getSums(servlet,strProjecttaskid);
    String strSumExpenses=fh.prepareFieldgroup(servlet, vars, script, "SumExpensesFG",expdata[0],true);
    strSkeleton=Replace.replace(strSkeleton, "@CONTENT@", strTableStructure + strGrid + "<br>"+strSumEmployees+strGrid2+strSumEquipment+"<br>"+strGrid3+strSumExpenses+"<br>");  
    strSkeleton=Replace.replace(strSkeleton, "<tr class=\"DUMMYFG_CLASS\" style=\"display: table-row;\">", "<tr class=\"DUMMYFG_CLASS\" style=\"display: none;\">");
    script.addHiddenfieldWithID("enabledautosave", "N");
    strSkeleton = script.doScript(strSkeleton, "",servlet,vars);
    return strSkeleton;
  }
  public void setFormSave(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,Connection con){
	  
  }
}
