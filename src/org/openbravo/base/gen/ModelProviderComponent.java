/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html 
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License. 
 * The Original Code is Openbravo ERP. 
 * The Initial Developer of the Original Code is Openbravo SL 
 * All portions are Copyright (C) 2008 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.base.gen;

import org.openarchitectureware.workflow.WorkflowComponent;
import org.openarchitectureware.workflow.WorkflowContext;
import org.openarchitectureware.workflow.ast.parser.Location;
import org.openarchitectureware.workflow.container.CompositeComponent;
import org.openarchitectureware.workflow.issues.Issues;
import org.openarchitectureware.workflow.monitor.ProgressMonitor;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.base.session.OBPropertiesProvider;

/**
 * Sets the model in the work flow context, so that the generator can pick it up from there.
 * 
 * @author mtaal
 */

public class ModelProviderComponent implements WorkflowComponent {

  private String propFile;

  public void checkConfiguration(Issues arg0) {
  }

  public CompositeComponent getContainer() {
    return null;
  }

  public Location getLocation() {
    return null;
  }

  public void invoke(WorkflowContext wc, ProgressMonitor pm, Issues issues) {
    wc.set("model", ModelProvider.getInstance());
  }

  public void setContainer(CompositeComponent arg0) {
  }

  public void setLocation(Location arg0) {
  }

  public void setPropFile(String propFile) {
    OBPropertiesProvider.getInstance().setProperties(propFile);
    this.propFile = propFile;
  }

  public String getPropFile() {
    return propFile;
  }
}
