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


public class ProjecttaskHrPlan implements ManualTabPane{

  public String getFormEdit(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,WindowTabs tabs,HttpServletResponse response,ToolBar stdtoolbar) throws Exception{
    String toolbarid=FormhelperData.getTabEditionToolbar(servlet,servlet.getClass().getName());

    Scripthelper script = new Scripthelper();
    ProjecttaskHRPlanData[] GridData;
    String strProjecttaskid=vars.getSessionValue("130|c_projecttask_id");
    String strOrgid=vars.getSessionValue("130|ad_org_id");
    script.addHiddenfield("inpadOrgId", strOrgid);
    String strCommand=vars.getStringParameter("inpCommandType");
    servlet.setCommandtype("");
    String strUser=vars.getUser();
    EditableGrid grid = new EditableGrid("PTaskHRGrid", vars, servlet);  
    String msg="";
    String msgType="SUCCESS";
    String msgHeader="Success";
    String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
    try {
      // SAVE-ACTION
      if (strCommand.equals("SAVE")) {
        Vector <String> retval;

        retval=grid.getSelectedIds(servlet, vars, "zspm_ptaskhrplan_id");
        String strDescription,strHRPId,strCategory,strQty,strPlannedUser,strovertimehours,strnighthours,strsaturday,strsunday,strholiday,strspecialtime1,strspecialtime2,strtriggeramt,strdatefrom,strdateto;
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          strPlannedUser=grid.getValue(servlet, vars, strHRPId, "ad_user_id");
          strCategory=grid.getValue(servlet, vars, strHRPId, "c_salary_category_id");
          if (strCategory.isEmpty())
            strCategory=ProjecttaskHRPlanData.getSalCategory(servlet, strPlannedUser);
          if (strCategory.isEmpty()) {
            String uname=ProjecttaskHRPlanData.getUsername(servlet, strPlannedUser);
            if (uname==null)
              uname="";
            msg=Utility.messageBD(servlet, "needSalaRyCategoryToPlanResource",vars.getLanguage())+ uname;
            msgType="ERROR";
            msgHeader="Error";
          }
          strQty=grid.getValue(servlet, vars, strHRPId, "quantity");
          strovertimehours=grid.getValue(servlet, vars, strHRPId, "overtimehours");
          strnighthours=grid.getValue(servlet, vars, strHRPId, "nighthours");
          strsaturday=grid.getValue(servlet, vars, strHRPId, "saturday");
          strsunday=grid.getValue(servlet, vars, strHRPId, "sunday");
          strholiday=grid.getValue(servlet, vars, strHRPId, "holiday");
          strspecialtime1=grid.getValue(servlet, vars, strHRPId, "specialtime1");
          strspecialtime2=grid.getValue(servlet, vars, strHRPId, "specialtime2");
          strtriggeramt=grid.getValue(servlet, vars, strHRPId, "triggeramt");
          strdatefrom=grid.getValue(servlet, vars, strHRPId, "datefrom");
          strdateto=grid.getValue(servlet, vars, strHRPId, "dateto");
          strDescription=grid.getValue(servlet, vars, strHRPId, "Description");
          if (!strCategory.isEmpty()) {
            // INsert or Update?
            if (ProjecttaskHRPlanData.isExistingID(servlet, strHRPId).equals("0"))
              ProjecttaskHRPlanData.insert( servlet, strHRPId,strOrgid, strProjecttaskid,strUser, strCategory, strQty, strPlannedUser,
                  strovertimehours,strnighthours,strsaturday,strsunday,strholiday,strspecialtime1,strspecialtime2,strtriggeramt,strdatefrom,strDateFormat,strdateto,strDescription);
            else
              ProjecttaskHRPlanData.update( servlet,strUser, strCategory, strQty, strPlannedUser,
                  strovertimehours,strnighthours,strsaturday,strsunday,strholiday,strspecialtime1,strspecialtime2,strtriggeramt,strdatefrom,strDateFormat,strdateto,strDescription,strHRPId);
            if (msg.isEmpty())
              msg=Utility.messageBD(servlet, "HRPlanCreatedSucessfully",vars.getLanguage());
          }
        }   

        
      }  
      // PICKLIST-ACTION
      if (strCommand.equals("PICKLIST")) {
        Vector <String> retval;

        retval=vars.getListFromInString(vars.getInStringParameter("inpemployeelist"));
        String strHRPId,strCategory,strQty,strPlannedUser,strovertimehours,strnighthours,strsaturday,strsunday,strholiday,strspecialtime1,strspecialtime2,strtriggeramt;
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=SequenceIdData.getUUID();
          strPlannedUser=retval.elementAt(i);
          strCategory=ProjecttaskHRPlanData.getSalCategory(servlet, strPlannedUser);
          if (strCategory.isEmpty()) {
            String uname=ProjecttaskHRPlanData.getUsername(servlet, strPlannedUser);
            if (uname==null)
              uname="";
            msg=Utility.messageBD(servlet, "needSalaRyCategoryToPlanResource",vars.getLanguage()) + uname;
            msgType="ERROR";
            msgHeader="Error";
          }
          strQty="0";
          strovertimehours="0";
          strnighthours="0";
          strsaturday="0";
          strsunday="0";
          strholiday="0";
          strspecialtime1="0";
          strspecialtime2="0";
          strtriggeramt="0";
          if (ProjecttaskHRPlanData.isExistingEmployee(servlet, strProjecttaskid,strPlannedUser).equals("0") && !strCategory.isEmpty()) {
            ProjecttaskHRPlanData.insert( servlet, strHRPId,strOrgid, strProjecttaskid,strUser, strCategory, strQty, strPlannedUser,
                strovertimehours,strnighthours,strsaturday,strsunday,strholiday,strspecialtime1,strspecialtime2,strtriggeramt,null,strDateFormat,null,null);
            if (msg.isEmpty())
              msg=Utility.messageBD(servlet, "HRPlanCreatedSucessfully",vars.getLanguage());
          }
          
        }   

      }  
      if (strCommand.equals("DELETE")) {
        String strHRPId;
        Vector <String> retval;

        retval=grid.getSelectedIds(null, vars, "zspm_ptaskhrplan_id");
        for (int i = 0; i < retval.size(); i++) {
          strHRPId=retval.elementAt(i);
          ProjecttaskHRPlanData.delete( servlet, strHRPId);
          msg=Utility.messageBD(servlet, "HRPlanCreatedSucessfully",vars.getLanguage());
        }

      }
    } catch (final ServletException ex) {
      final OBError myError = Utility.translateError(servlet, vars, vars.getLanguage(), ex.getMessage());
      msg=myError.getMessage();
      msgHeader=myError.getTitle();
      msgType=myError.getType();     
      
    }
    // NEW-ACTION OR all OTHER Actions
    if (strCommand.equals("NEW"))
      GridData=ProjecttaskHRPlanData.selectnew(servlet, strProjecttaskid);
    else
      GridData=ProjecttaskHRPlanData.select(servlet, strProjecttaskid);
    String strLeftabsmode=FormhelperData.getLeftTabsMode4Tab(servlet,servlet.getClass().getName());
    if (!msg.equals(""))
      script.addMessage(servlet, vars, msgType, msgHeader,msg);
    String strSkeleton = ConfigureFrameWindow.doConfigureWindowMode(servlet,vars,"description",tabs.breadcrumb(), "Test Form Window",toolbarid,strLeftabsmode,tabs,"_Relation",null);
    Formhelper fh=new Formhelper();
    
    String strGrid = grid.printGrid(servlet, vars, script, GridData); 
    String strTableStructure=fh.prepareFieldgroup(servlet, vars, script, "PtaskHRPlanHeaderFG",null,true);
    strSkeleton=Replace.replace(strSkeleton, "@CONTENT@", strTableStructure + strGrid);  
    script.addHiddenfieldWithID("enabledautosave", "N");
    strSkeleton = script.doScript(strSkeleton, "",servlet,vars);
    return strSkeleton;
  }
  public void setFormSave(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,Connection con){
	  
  }
}
