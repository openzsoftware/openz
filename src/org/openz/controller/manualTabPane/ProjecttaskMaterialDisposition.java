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


public class ProjecttaskMaterialDisposition  implements ManualTabPane{

  public String getFormEdit(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,WindowTabs tabs,HttpServletResponse response,ToolBar stdtoolbar) throws Exception{
    String toolbarid=FormhelperData.getTabEditionToolbar(servlet,servlet.getClass().getName());
    Connection conn = null;
    Scripthelper script = new Scripthelper();
    ProjecttaskMaterialDispositionData[] GridData;
    String strProjecttaskid=vars.getSessionValue(vars.getStringParameter("inpwindowId") + "|c_projecttask_id");
    String strOrgid=vars.getSessionValue(vars.getStringParameter("inpwindowId") + "|ad_org_id");
    script.addHiddenfield("inpadOrgId", strOrgid);
    String strCommand=vars.getStringParameter("inpCommandType");
    servlet.setCommandtype("");
    String strUser=vars.getUser();
    EditableGrid grid = new EditableGrid("PTaskMaterialGrid", vars, servlet);  
    String msg="";
    String msgType="SUCCESS";
    String msgHeader="Success";
    String strpvaluefilter="%";
    String strpnamefilter="%";
    try {
      // SAVE-ACTION
      if (strCommand.equals("SAVE")) {
        Vector <String> retval;
        conn= servlet.getTransactionConnection();
        retval=grid.getSelectedIds(servlet, vars, "zspm_projecttaskbom_view_id");
        String strPTBOMId,strLine,strProduct,strLocator,strQty,strIsreturned,strRequisition,strPlanDate;
        for (int i = 0; i < retval.size(); i++) {
          strPTBOMId=retval.elementAt(i);
          strProduct=grid.getValue(servlet, vars, strPTBOMId, "M_Product_ID");
          strLocator=grid.getValue(servlet, vars, strPTBOMId, "M_Locator_ID");
          strQty=grid.getValue(servlet, vars, strPTBOMId, "Quantity");
          strIsreturned=grid.getValue(servlet, vars, strPTBOMId, "isreturnafteruse");
          strRequisition=grid.getValue(servlet, vars, strPTBOMId, "Planrequisition");
          strPlanDate=grid.getValue(servlet, vars, strPTBOMId, "Date_Plan");
          // INsert or Update?
          if (ProjecttaskMaterialDispositionData.isExisting(servlet, strPTBOMId).equals("0")) {
            if (strLocator.isEmpty())
              strLocator=ProjecttaskMaterialDispositionData.getPreferedLocator(servlet, strProjecttaskid, strProduct);
            strLine=ProjecttaskMaterialDispositionData.gfetNextLine(servlet, strProjecttaskid);
            ProjecttaskMaterialDispositionData.insert(conn, servlet, strPTBOMId,strOrgid, strProjecttaskid,strUser, strLine,strLocator,strProduct, strQty, strRequisition,
                strIsreturned,strPlanDate);
          }else
            ProjecttaskMaterialDispositionData.update(conn, servlet, strUser, strLocator,strProduct, strQty, strRequisition,
                strIsreturned,strPlanDate,strPTBOMId);
          if (msg.isEmpty())
            msg=Utility.messageBD(servlet, "MaterialPlanCreatedSucessfully",vars.getLanguage());
        }   
        servlet.releaseCommitConnection(conn);
      }  
      // PICKLIST-ACTION
      if (strCommand.equals("PICKLIST")) {
        Vector <String> retval;
        conn= servlet.getTransactionConnection();
        retval=vars.getListFromInString(vars.getInStringParameter("inpproductlist"));
        String strPTBOMId,strLine,strProduct,strLocator,strQty,strIsreturned,strRequisition,strPlanDate;
        strLine=ProjecttaskMaterialDispositionData.gfetNextLine(servlet, strProjecttaskid);
        for (int i = 0; i < retval.size(); i++) {
          strPTBOMId=SequenceIdData.getUUID();
          strProduct=retval.elementAt(i);
          strQty="1";
          strIsreturned="N";
          strRequisition="N";
          strLocator=ProjecttaskMaterialDispositionData.getPreferedLocator(servlet, strProjecttaskid, strProduct);
          strPlanDate=ProjecttaskMaterialDispositionData.getPalanDate(servlet, strProjecttaskid);
          ProjecttaskMaterialDispositionData.insert(conn, servlet, strPTBOMId,strOrgid, strProjecttaskid,strUser, strLine,strLocator,strProduct, strQty, strRequisition,
              strIsreturned,strPlanDate);
          strLine=Integer.toString(Integer.parseInt(strLine)+10);
          if (msg.isEmpty())
            msg=Utility.messageBD(servlet, "MaterialPlanCreatedSucessfully",vars.getLanguage());
        }   
        servlet.releaseCommitConnection(conn);
        }
      if (strCommand.equals("DELETE")) {
        String strPTBOMId;
        Vector <String> retval;
        conn= servlet.getTransactionConnection();
        retval=grid.getSelectedIds(null, vars, "zspm_projecttaskbom_view_id");
        for (int i = 0; i < retval.size(); i++) {
          strPTBOMId=retval.elementAt(i);
          ProjecttaskMaterialDispositionData.delete(conn, servlet, strPTBOMId);
          msg=Utility.messageBD(servlet, "MaterialPlanCreatedSucessfully",vars.getLanguage());
        }
        servlet.releaseCommitConnection(conn);
      }
      if (strCommand.equals("FILTER")) {
       
      }
    } catch (final ServletException ex) {
        final OBError myError = Utility.translateError(servlet, vars, vars.getLanguage(), ex.getMessage());
        msg=myError.getMessage();
        msgHeader=myError.getTitle();
        msgType=myError.getType();   
        try {
            servlet.releaseRollbackConnection(conn);
        } catch (final Exception ignored) {
        }
    }
    // Set Filter
    strpvaluefilter=vars.getRequestGlobalVariable("inpproductnumber", vars.getStringParameter("inpwindowId") + "|productnumber");
    if (strpvaluefilter.isEmpty())
      strpvaluefilter="%";
    strpnamefilter=vars.getRequestGlobalVariable("inppname", vars.getStringParameter("inpwindowId") + "|pname");
    if (strpnamefilter.isEmpty())
      strpnamefilter="%";
    // NEW-ACTION OR all OTHER Actions
    if (strCommand.equals("NEW"))
      GridData=ProjecttaskMaterialDispositionData.selectnew(servlet,vars.getLanguage(), strProjecttaskid,strpvaluefilter,strpnamefilter);
    else
      GridData=ProjecttaskMaterialDispositionData.select(servlet, vars.getLanguage(),strProjecttaskid,strpvaluefilter,strpnamefilter);
    String strLeftabsmode=FormhelperData.getLeftTabsMode4Tab(servlet,servlet.getClass().getName());
    if (!msg.equals(""))
      script.addMessage(servlet, vars, msgType, msgHeader,msg);
    String strSkeleton = ConfigureFrameWindow.doConfigureWindowMode(servlet,vars,"description",tabs.breadcrumb(), "Test Form Window",toolbarid,strLeftabsmode,tabs,"_Relation",null);
    Formhelper fh=new Formhelper();
    
    String strGrid = grid.printGrid(servlet, vars, script, GridData); 
    String strTableStructure=fh.prepareFieldgroup(servlet, vars, script, "PtaskMatPlanHeaderFG",null,true);
    strSkeleton=Replace.replace(strSkeleton, "@CONTENT@", strTableStructure + strGrid);  
    // Add Search Shortcut
    script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('EDIT', true, null, null, '_self');\",\"inpproductnumber\",\"null\");");
    script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('EDIT', true, null, null, '_self');\",\"inppname\",\"null\");");
    script.addHiddenfieldWithID("enabledautosave", "N");
    strSkeleton = script.doScript(strSkeleton, "",servlet,vars);
    return strSkeleton;
  }
  public void setFormSave(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,Connection con){
	  
  }
}