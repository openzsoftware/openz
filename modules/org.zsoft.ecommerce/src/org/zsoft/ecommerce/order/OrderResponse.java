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
package org.zsoft.ecommerce.order;
import org.zsoft.ecommerce.*;

public class OrderResponse {
  private String  cOrderId;
  
  public String getCOrderId() {
       return cOrderId;
  }
 
  public void setCOrderId(String pcOrderId) {
       cOrderId = pcOrderId;
  }
 
    private String  documentno;
 
  public String getDocumentno() {
       return documentno;
  }
 
  public void setDocumentno(String pdocumentno) {
       documentno = pdocumentno;
  }
 
    private String  docstatus;
 
  public String getDocstatus() {
       return docstatus;
  }
 
  public void setDocstatus(String pdocstatus) {
       docstatus = pdocstatus;
  }
  private String  message;
  
  public String getMessage() {
       return message;
  }
 
  public void setMessage(String pmessage) {
       message = pmessage;
  }
 
}
