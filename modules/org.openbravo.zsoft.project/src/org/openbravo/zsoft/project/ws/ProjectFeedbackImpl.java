/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.openbravo.zsoft.project.ws;



import java.util.Date;
import java.text.SimpleDateFormat;


import org.zsoft.ecommerce.WebService;
import org.apache.log4j.Logger;
import org.openbravo.zsoft.project.ws.ProjectData;
import org.openbravo.zsoft.project.ws.PhaseData;
import org.openbravo.zsoft.project.ws.TaskData;
import org.openbravo.zsoft.project.ws.EmployeeData;

public class ProjectFeedbackImpl extends WebService implements org.openbravo.zsoft.project.ws.ProjectFeedback {
  private static Logger log4j = Logger.getLogger(ProjectFeedbackImpl.class);
 
  
 public Project[] getProjects(String clientId, String username, String password)
  {
    Project[] projects = null;
    Phase[] phases=null;
    Task[] tasks=null;
    if (!access(username, password,clientId)) {
      if (log4j.isDebugEnabled())
        log4j.debug("Access denied for user: " + username);
      return null;
    }
    try {

      ProjectData[] data = ProjectData.select(pool);

      projects = new Project[data.length];

      for (int i = 0; i < data.length; i++) {
        projects[i] = new Project();
        projects[i].setId(data[i].id);
        projects[i].setName(data[i].name);
        projects[i].setKeyvalue(data[i].value);
        PhaseData[] pdata = PhaseData.select(pool, data[i].id);
        phases = new Phase[pdata.length];
        for (int j = 0; j < pdata.length; j++) {
          phases[j]= new Phase();
          phases[j].setId(pdata[j].id);
          phases[j].setName(pdata[j].name);
          TaskData[] tdata = TaskData.select(pool,pdata[j].id);
          tasks = new Task[tdata.length];
          for (int k = 0; k < tdata.length; k++) {
            tasks[k] = new Task();
            tasks[k].setId(tdata[k].id);
            tasks[k].setName(tdata[k].name);
          }
          phases[j].setTasks(tasks);
        }
        projects[i].setPhases(phases);
      }
    } catch (Exception e) {
      log4j.error(e.getMessage());
    } finally {
      destroyPool();
    }
    return projects;
  }
    

public Employee[] getEmployees(String clientId, String username, String password)
{
   Employee[] employees = null;
   if (!access(username, password,clientId)) {
     if (log4j.isDebugEnabled())
       log4j.debug("Access denied for user: " + username);
     return null;
   }
   try {

     EmployeeData[] data = EmployeeData.select(pool);
     employees = new Employee[data.length];
     for (int i = 0; i < data.length; i++) {
       employees[i] = new Employee();
       employees[i].setId(data[i].id);
       employees[i].setName(data[i].name);
       employees[i].setEnumber(data[i].enumber);
     }
    
   } catch (Exception e) {
     log4j.error(e.getMessage());
   } finally {
     destroyPool();
   }
   return employees;
  }
  
public String giveFeedback(String employeeID, Date workdate,String projectID, String PhaseID, String taskID, Date hour_from, Date hour_to, String username, String password)
{
  String updated = "ERR";
  String errm="OK";
  String strdate=new SimpleDateFormat("dd.MM.yyyy").format(workdate);
  String strfrom=new SimpleDateFormat("dd.MM.yyyy-HH:mm").format(hour_from);
  String strto=new SimpleDateFormat("dd.MM.yyyy-HH:mm").format(hour_to);
  try {
      String orgID = ProjectData.selectorg4proj(pool, projectID);
      if (!access(username, password,orgID)) {
        if (log4j.isDebugEnabled())
          log4j.debug("Access denied for user: " + username);
        destroyPool();
        return null;
      }
      
      updated = ProjectData.giveFeedback(pool, employeeID, strdate, projectID, PhaseID, taskID, strfrom, strto);
  } catch (Exception e) {
    errm=e.getMessage();
    log4j.error(errm);
  } finally {
    destroyPool();
  }
  if (updated.equals("ERR")) {
    return "ERROR: Update Failed: Database Error." + errm;
  } else {
    return "Feedback Successful" + updated;
  }
}

  
}