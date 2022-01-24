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

/**
* @fileoverview Contains the definition for an error handler that captures all
* Javascript errors within any HTML document (DOM) and pops an alert message 
* (variable showErrors must be set to true for that to happen though).
*/

var showErrors = false;

function HandleErrors(aMessage, aURL, aLine, evt) {
  //if (navigator.appName == "Netscape") document.routeEvent(evt);
  if (showErrors) alert("Error: \n" + aMessage + "\n\nURL: \n" + aURL + "\n\n\nLine: " + aLine);
  return true;
}


if (!document.all) document.captureEvents(Event.ONERROR);

window.onerror=HandleErrors;
