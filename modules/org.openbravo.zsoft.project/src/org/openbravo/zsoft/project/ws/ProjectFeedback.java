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

public interface ProjectFeedback {
  public Project[] getProjects(String clientId, String username, String password);

  public Employee[] getEmployees(String clientId, String username, String password);
  
  public String giveFeedback(String employeeID, Date workdate,String projectID, String PhaseID, String taskID, Date hour_from, Date hour_to, String username, String password);

  
}
