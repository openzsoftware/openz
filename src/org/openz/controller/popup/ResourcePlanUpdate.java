package org.openz.controller.popup;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.utils.Replace;
import org.openz.util.SessionUtils;
import org.openz.view.EditableGrid;
import org.openz.view.Formhelper;
import org.openz.view.Scripthelper;
import org.openz.view.templates.*;

public class ResourcePlanUpdate extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  
  
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }
  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
  ServletException {
    // Initialize global structure
    VariablesSecureApp vars = new VariablesSecureApp(request);
    Scripthelper script = new Scripthelper(); // Injects Javascript, hidden fields, etc into the generated html
    script.enableshortcuts("POPUP");
    String js= "function submitThisPage(command) { \n" +
               "     submitCommandForm(command, true, null, '', '_self');\n" +
              // "     window.onunload = reloadOpener;\n" +
              // "     setTimeout(function(){top.close();},8000);\n" +
               "     return true;\n" +
               "}\n" +
               "function submitThisPageNoClose(command) { \n" +
                 "     submitCommandForm(command, true, null, '', '_self');\n" +
                 "     return true;\n" +
                 "}\n" ;
    script.addJScript(js);
    Formhelper fh = new Formhelper();         // Injects the styles of fields, grids, etc
    String strOutput = "" ;                   // Resulting html output
    String strHeaderFG = "";                  // Header fieldgroup (defined in AD)
    String strGrid="";
    String strActionButtons="";               // Bottom Fieldgroup (defined in AD)
    String strProjecttaskId = vars.getSessionValue(this.getClass().getName() + "|c_projecttask_id");
    String strDateFrom = vars.getStringParameter("inpdatefrom");
    String strDateTo = vars.getStringParameter("inpdateto");
    String strResourceID=vars.getGlobalVariable("inpProcessId", this.getClass().getName() + "|ResourceId", "");
    FieldProvider[] GridData;
    EditableGrid grid ;
    String isEmployee=ResourcePlanUpdateData.isEmployee(myPool, strResourceID);
    if (vars.commandIn("DIRECT")) {
      strProjecttaskId = ResourcePlanUpdateData.selectPTaskId(this, vars.getStringParameter("inpProcessId"));
      vars.setSessionValue(this.getClass().getName() + "|c_projecttask_id",strProjecttaskId);
      strDateFrom = ResourcePlanUpdateData.selectPTaskDateFrom(this, vars.getJavaDateFormat(), strProjecttaskId);
      vars.setSessionValue(this.getClass().getName() + "|DateFrom",strDateFrom);
      strDateTo = ResourcePlanUpdateData.selectPTaskDateTo(this,vars.getJavaDateFormat(), strProjecttaskId);
      vars.setSessionValue(this.getClass().getName() + "|DateTo",strDateTo);
      vars.setMessage(this.getClass().getName(),null);
    }
    if (vars.commandIn("SAVE")) {
     if (! strDateTo.equals(vars.getSessionValue(this.getClass().getName() + "|DateTo")) || ! strDateFrom.equals(vars.getSessionValue(this.getClass().getName() + "|DateFrom")))
       ResourcePlanUpdateData.updateTaskDates(this, strProjecttaskId, strDateFrom, vars.getSqlDateFormat(), strDateTo);
     Vector <String> retval;
     try {
       if (isEmployee.equals("Y")) {
         grid = new EditableGrid("ResourcePlanUpdateHRGrid", vars, this);
         retval=grid.getSelectedIds(this, vars, "zspm_ptaskhrplan_id");
       }else {
         grid = new EditableGrid("ResourcePlanUpdateMachineGrid", vars, this);
         retval=grid.getSelectedIds(this, vars, "zspm_ptaskmachineplan_id");
       }
       String strHRPId,strQty,strdatefrom,strdateto,strresourceId,strcostuom,strptaskid;
       for (int i = 0; i < retval.size(); i++) {
         strHRPId=retval.elementAt(i);
         strQty=grid.getValue(this, vars, strHRPId, "quantity");
         strdatefrom=grid.getValue(this, vars, strHRPId, "datefrom");
         strdateto=grid.getValue(this, vars, strHRPId, "dateto");
         if (isEmployee.equals("Y"))
           strresourceId=grid.getValue(this, vars, strHRPId, "employee_id");
         else
           strresourceId=grid.getValue(this, vars, strHRPId, "ma_machine_id");
         strcostuom=grid.getValue(this, vars, strHRPId, "costuom");
         strptaskid=grid.getValue(this, vars, strHRPId, "c_projecttask_id");
         ResourcePlanUpdateData.updateOrInsert(this, strHRPId,strptaskid, strresourceId, strdatefrom,vars.getSqlDateFormat(), strdateto, vars.getUser(),null, strcostuom, strQty);
       }
       
     }
     catch (Exception e) { 
         log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
         e.printStackTrace();
         throw new ServletException(e);
     }
    }
    if (vars.commandIn("DELETE")) {
      Vector <String> retval;
      String strselectedID;
      try {
        if (isEmployee.equals("Y")) {
          grid = new EditableGrid("ResourcePlanUpdateHRGrid", vars, this);
          retval=grid.getSelectedIds(this, vars, "zspm_ptaskhrplan_id");
        }else {
          grid = new EditableGrid("ResourcePlanUpdateMachineGrid", vars, this);
          retval=grid.getSelectedIds(this, vars, "zspm_ptaskmachineplan_id");
        }    
        for (int i = 0; i < retval.size(); i++) {
          strselectedID=retval.elementAt(i);
          ResourcePlanUpdateData.delete(this,strselectedID);
        }
      }
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        throw new ServletException(e);
      }
      
    }
    if (vars.commandIn("DELETE") || vars.commandIn("SAVE")) {
      script.addOnload("window.opener.delstash();");
      script.addOnload(" window.onunload = reloadOpener;");
      script.addOnload("top.close();");
      try {
        strOutput = ConfigurePopup.doConfigure(this,vars,script,"Resource Plan Update","");
        strOutput=Replace.replace(strOutput, "@CONTENT@",  "");
        strOutput = script.doScript(strOutput, "",this,vars);
      }
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        throw new ServletException(e);
    }
    }
    if (vars.commandIn("DIRECT")||vars.commandIn("NEW")) {
      // Build The GUI INIT by AD
      try {
        
        script.addHiddenfield("inpadOrgId", vars.getOrg());
        script.addOnload("window.opener.delstash();");
        if (isEmployee.equals("Y")) {
          String strEmp=ResourcePlanUpdateData.getEmployee(this, strResourceID);
          grid = new EditableGrid("ResourcePlanUpdateHRGrid", vars, this);
          if (vars.commandIn("NEW"))
            GridData=ResourcePlanUpdateData.selectempnew(this, strProjecttaskId);
          else
            GridData=ResourcePlanUpdateData.selectemp(this, strProjecttaskId);
        } else {
          grid = new EditableGrid("ResourcePlanUpdateMachineGrid", vars, this);
          String strMa=ResourcePlanUpdateData.getMachine(this, strResourceID);
          if (vars.commandIn("NEW"))
            GridData=ResourcePlanUpdateData.selectmachinenew(this, strProjecttaskId);
          else
            GridData=ResourcePlanUpdateData.selectmachine(this, strProjecttaskId);
        }
        strGrid=grid.printGrid(this, vars, script, GridData);
        strHeaderFG=fh.prepareFieldgroup(this, vars, script, "ResourcePlanUpdateHeaderFG", null,false);
        strActionButtons=fh.prepareFieldgroup(this, vars, script, "ResourcePlanUpdateActionButtons", null,false);
        strOutput = ConfigurePopup.doConfigure(this,vars,script,"Resource Plan Update","buttonOK");
            //ConfigureSelectionPopup.doConfigure(this,vars,"Employee",null,"buttonSearch",false,"../org.openbravo.zsoft.smartui.Employee/PersonalDataC9B028F8723040C8A2BE9C26E125FA22_Relation.html" );
            //ConfigurePopup.doConfigure(this,vars,script,"Resource Plan Update","buttonOK");
        strOutput=Replace.replace(strOutput, "@CONTENT@",  strHeaderFG + strGrid + strActionButtons);
        strOutput = script.doScript(strOutput, "",this,vars);
      }
      catch (Exception e) { 
          log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
          e.printStackTrace();
          throw new ServletException(e);
      }
    }
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(strOutput);
    out.close(); 
  }
  private void removePageSessionVariables(VariablesSecureApp vars) {
    SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "name");
    SessionUtils.deleteLocalSessionVariable(getServletInfo(),vars, "value");
  }
  public String getServletInfo() {
    return this.getClass().getName();
  } 
}
