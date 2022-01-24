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
* @fileoverview Used only in FrameOcultoMultilinea.html as part of the 
* master-detail window that enables rapid data entry without the 
* Header-Lines window structure.
*/

function submitArray(parameters, frmForm, strAction, strTarget)
{
	var form = document.forms[0];
	if (strAction==null)
		strAction = "ACTUALIZAR";
	form.setAttribute("action",frmForm);
	form.setAttribute("method","POST");
	form.setAttribute("target","_self");
	form.setAttribute("name", "frmFrameOculto");
	var hiddenInput = document.createElement("INPUT");
	hiddenInput.setAttribute("name", "Command");
	hiddenInput.setAttribute("value", strAction);
	hiddenInput.setAttribute("type","hidden");
	form.appendChild(hiddenInput);
  if (strTarget!=null && strTarget!="") {
    hiddenInput = document.createElement("INPUT");
    hiddenInput.setAttribute("name", "target");
    hiddenInput.setAttribute("value", strTarget);
    hiddenInput.setAttribute("type","hidden");
    form.appendChild(hiddenInput);
  }
  var total = parameters.length;
	for (var i=0;i<total;i++)
	{
		hiddenInput = document.createElement("INPUT");
		hiddenInput.setAttribute("name", parameters[i][0]);
		hiddenInput.setAttribute("value", parameters[i][1]);
		hiddenInput.setAttribute("type","hidden");
		form.appendChild(hiddenInput);
	}
	form.submit();
}

function devolverResultados()
{
  var frm = document.forms[0];
  var target;
  if (!frm.targetFrame || !frm.targetFrame.value) target = parent.frameMultilinea;
  else target = eval(frm.targetFrame.value);//target = parent.frames[frm.targetFrame.value];
  if (target) {
    if (respuesta!=null) {
      if (respuestaNew!=null) target.filtrarRespuesta(respuesta, respuestaNew);
      else target.filtrarRespuesta(respuesta);
    }
  }
}
