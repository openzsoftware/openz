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
 * All portions are Copyright (C) 2001-2006 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.utility;

public class OBError {
  private String type = "";
  private String title = "";
  private String message = "";
  private boolean connectionAvailable = true;

  public OBError() {
  }
  /**
   * Adds a Message to a Servlet
   * 
   * @param msgType: ERROR SUCCESS INFO WARNING
   * @param msgTitle
   * @param msgText
   * 
   */
  public OBError(String msgType, String msgTitle, String msgText) {
	  this.setType(msgType);
	  this.setTitle(msgTitle);
	  this.setMessage(msgText);
  }

  /**
   * Adds a Message to a Servlet
   * 
   * @param msgType: ERROR SUCCESS INFO WARNING
   * 
   */
  public void setType(String _data) {
    // Error Success Info Warning
    if (_data == null)
      _data = "";
    this.type = _data;
  }

  public String getType() {
    return ((this.type == null) ? "Hidden" : this.type);
  }

  public void setTitle(String _data) {
    if (_data == null)
      _data = "";
    this.title = _data;
  }

  public String getTitle() {
    return ((this.title == null) ? "" : this.title);
  }

  public void setMessage(String _data) {
    if (_data == null)
      _data = "";
    this.message = _data;
  }

  public String getMessage() {
    return ((this.message == null) ? "" : this.message);
  }

  public void setConnectionAvailable(boolean _data) {
    this.connectionAvailable = _data;
  }

  public boolean isEmpty() {
    return (getTitle().equals("") && getMessage().equals("") && getType().equals(""));
  }

  public void setError(OBError e) {
    setTitle(Utility.formatMessageBDToHtml(e.getTitle()));
    setMessage(Utility.formatMessageBDToHtml(e.getMessage()));
    setType(e.getType());
    setConnectionAvailable(e.isConnectionAvailable());
  }

  public boolean isConnectionAvailable() {
    return this.connectionAvailable;
  }
}
