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
* @fileoverview Used only in InvoiceVendorMultiline_Lines.html form as part of 
* the master-detail window that enables rapid data entry without the 
* Header-Lines window structure.
*/

var gId="name"; //Atributo para identificar los elementos
var gBoton = "Editable"; //Valor del atributo para el Div del Botón
var gFila = "Fila"; //Valor del atributo para el Tag que marca la fila
var frmFormulario; //Página o Servlet a la que debe ir el oculto
var gTargetFrame; //Target del frame al que debe ir el oculto
var gHiddenFrame = "frameOculto"; //Target donde se encuentra el frame oculto
var gColorSeleccionado = "#C0C0C0"; //Color de la fila Seleccionada
var gColorNormal = "#FFFFFF"; //Color de las Filas no Seleccionadas
var gValorCampo = null; //Contiene el valor de un campo antes de ser modificado

var gFilaActual=null; //Fila en la que nos encontramos actualmente
var gUltimoCampo=null; //Campo en el que estábamos antes de abandonar esta ventana
var fila=null; //Variable global que guarda la fila en la que nos encontramos
var parametros = new Array(); //Array en el que se guardan los parámetros a enviar
var gBolEnviandoFila=false; //Flag para no permiter que se envien datos repetidos
var gBolBloqueado=false; //Flag para evitar que el usuario envíe datos antes de comprobar los anteriores

/*  MANEJADORES DE EVENTOS  */
var gBolEvtActivarLinea = false; //Si se debe disparar el evento activar línea
var gBolEvtEnviarLinea = false; //Si se debe disparar el evento enviar línea
var gBolEvtCambiarLinea = false; //Si se debe disparar el evento cambiar datos en la linea
var gBolEvtAntesDeFiltrarRespuesta = false; //Si se debe dispara el evento antes de filtrar la respuesta
var gBolEvtAntesDeBorrar = false; //Si se debe dispara el evento antes de borrar la línea
var gBolEvtAntesDeActualizar = false; //Si se debe dispara el evento antes de actualizar un cambio
var gBolEvtAntesDeNuevo = false; //Si se debe dispara el evento antes de añadir la nueva línea
var gBolEvtErrorEnRespuesta = false; //Si se debe dispara el evento al producirse un error en la respuesta
var gBolEvtDespuesDeNuevo = false; //Si se debe dispara el evento después de añadir la nueva línea
var gBolEvtCambiarCampo = false; //Si se debe disparar el evento después de modificar un campo

var gIsAutoInsertRows = false; //Si se deben insertar nuevas filas automáticamente
var gIsDeleteableRows = true; //Si se permite la eliminación de filas
var gActivateTabJump = false; //Si se permite la función de salto entre diferentes frames

/*VARIABLES DE LA BUSQUEDA*/
var gBuscarPorBusqueda=null;
var gValorBusqueda=null;
var gNodoBusqueda=null;

//Comprueba que el campo exista como objeto
function esCampo(campo)
{
	if (campo==null) return false;
	if (campo.name==null) return false;
	return true;
}

function seleccionarCampo(nodo) {
  if (!esCampo(nodo)) return false;
  nodo.focus();
  if (nodo.type && (nodo.type == "text" || nodo.type == "password"))
		nodo.select();
}

function esCampoInput(nodo) {
  var valor=false;
  if (nodo.type) {
    switch (nodo.type)
    {
    case "select-multiple" :
    case "select-one":
    case "text":
    case "password":
    case "checkbox":
    case "radio": valor=true;
                  break;
    default:  valor=false;
    }
  }
  return valor;
}

function valorCampo(nodo) {
  var valor=null;
  switch (nodo.type)
  {
  case "select-multiple" :
  case "select-one":  if (nodo.selectedIndex!=-1) {
                        valor = nodo.options[nodo.selectedIndex].value;
                      }
                      break;
  case "text":
  case "password":  valor=nodo.value;
                    break;
  case "checkbox":
  case "radio":   valor = (nodo.checked)?"-1":"0";
                  break;
  default:  return null;
  }
  if (valor==null) {
    valor="";
  }
  return valor;
}

function comprobarCambios(campoDelFoco) {
	if (!esCampo(campoDelFoco)) return false;
	var nd=buscarPadre(campoDelFoco, gId, gFila);
  var bolEnviado=true;
  gUltimoCampo = campoDelFoco.name;
  gValorCampo = valorCampo(campoDelFoco);
  if (gBolBloqueado) {
    nd=buscarHijo(gFilaActual, "name", campoDelFoco.name);
    seleccionarCampo(nd);
    return false;
  }
  
  gBolBloqueado=true;
	if (nd!=null)
	{
		/* Solo para el caso de que se haya cambiado de fila.
		   Cambiamos el color del fondo de la fila anterior y mandamos guardar los cambios
		   (si se han producido), a la vez que ocultamos la imagen de editando
		*/
		if (gFilaActual != null && nd != gFilaActual) {
      bolEnviado=deseleccionarFila();
			if (!bolEnviado) {
        nd=buscarHijo(gFilaActual, "name", campoDelFoco.name);
        seleccionarCampo(nd);
      }
    }

		/* Siempre que se cambie de fila y cuando no estábamos en ninguna fila anteriormente.
		   Cambiamos el color de la fila en la que estamos actualmente, mostramos la imagen de
		   editando y guardamos esta fila como la actual
		*/
		if (bolEnviado && (gFilaActual == null || nd != gFilaActual))
		{
			if (gBolEvtActivarLinea)
			{
				if (!alActivarLinea(campoDelFoco, nd)) {
          gBolBloqueado=false;
					return false;
        }
			}
			gFilaActual = nd;
			if (document.layers)
				nd.bgColor = gColorSeleccionado;
			else
				nd.style.backgroundColor = gColorSeleccionado;
			nd = buscarHijo(nd,gId,gBoton);
			if(nd!=null)
				nd.style.visibility = "visible";
		}
	}
	else {
		bolEnviado=deseleccionarFila();
    if (!bolEnviado) {
      nd=buscarHijo(gFilaActual, "name", campoDelFoco.name);
      seleccionarCampo(nd);
    }
  }
	
	//Seleccionamos todo el campo para el caso de los textbox.
	if (bolEnviado && (campoDelFoco.type == "text" || campoDelFoco.type == "password"))
		campoDelFoco.select();
  gBolBloqueado=false;
	return true;
}

/* Se encarga de marcar la fila completa con el color indicado, a la vez que desmarca la anterior y
   establece esta fila como la actual, tras mandar a guardar los cambios realizados en la anterior.
*/
function seleccionarFila(campoDelFoco, noEnviarFila)
{
  if (noEnviarFila == null) noEnviarFila=false;
	if (!esCampo(campoDelFoco)) return false;
	var nd=buscarPadre(campoDelFoco, gId, gFila);
  var bolEnviado=true;
  gUltimoCampo = campoDelFoco.name;
  gValorCampo = valorCampo(campoDelFoco);
  if (gBolBloqueado) {
    nd=buscarHijo(gFilaActual, "name", campoDelFoco.name);
    seleccionarCampo(nd);
    return false;
  }
  
  gBolBloqueado=true;
	if (nd!=null)
	{
		/* Solo para el caso de que se haya cambiado de fila.
		   Cambiamos el color del fondo de la fila anterior y mandamos guardar los cambios
		   (si se han producido), a la vez que ocultamos la imagen de editando
		*/
		if (gFilaActual != null && nd != gFilaActual) {
      bolEnviado=deseleccionarFila();
			if (!bolEnviado) {
        nd=buscarHijo(gFilaActual, "name", campoDelFoco.name);
        seleccionarCampo(nd);
      }
    }

		/* Siempre que se cambie de fila y cuando no estábamos en ninguna fila anteriormente.
		   Cambiamos el color de la fila en la que estamos actualmente, mostramos la imagen de
		   editando y guardamos esta fila como la actual
		*/
		if (bolEnviado && (gFilaActual == null || nd != gFilaActual))
		{
			if (gBolEvtActivarLinea)
			{
				if (!alActivarLinea(campoDelFoco, nd)) {
          gBolBloqueado=false;
					return false;
        }
			}
			gFilaActual = nd;
			if (document.layers)
				nd.bgColor = gColorSeleccionado;
			else
				nd.style.backgroundColor = gColorSeleccionado;
			nd = buscarHijo(nd,gId,gBoton);
			if(nd!=null)
				nd.style.visibility = "visible";
		}
	}
	else {
		bolEnviado=deseleccionarFila();
    if (!bolEnviado) {
      nd=buscarHijo(gFilaActual, "name", campoDelFoco.name);
      seleccionarCampo(nd);
    }
  }
	
	//Seleccionamos todo el campo para el caso de los textbox.
	if (bolEnviado && (campoDelFoco.type == "text" || campoDelFoco.type == "password"))
		campoDelFoco.select();
  gBolBloqueado=false;
	return true;
}

function deseleccionarFila(noEnviarFila)
{
	if (gFilaActual == null) return false;
  if (noEnviarFila == null) noEnviarFila=false;

  if (gBolEnviandoFila) return false;
	if (!noEnviarFila) enviarFila();
  if (document.layers)
    gFilaActual.bgColor = gColorNormal;
  else
    gFilaActual.style.backgroundColor = gColorNormal;
  var nd1=buscarHijo(gFilaActual, gId, gBoton);
  if (nd1!=null)
    nd1.style.visibility = "hidden";
  gFilaActual=null;
  return true;
}

function borrarOptions(combo)
{
	child = combo.firstChild;
	while(child!=null)
	{
		combo.removeChild(child)
		child = combo.firstChild;
	}
}


/*Se encarga de mostrar el botón de guardar cambios para la fila del elemento que se le pase,
que es el input sobre el que se está efectuando un cambio*/
function marcarFila(campoCambiado)
{
	if (!esCampo(campoCambiado)) return false;
	var nd=buscarPadre(campoCambiado, gId, gFila);
	if (nd!=null)
	{
    if (gBolEvtCambiarCampo) {
      if (!alCambiarCampo(campoCambiado, nd)) return false;
    }
		if (gBolEvtCambiarLinea)
		{
			if (!alCambiarLinea(campoCambiado, nd))
				return false;
		}
    if (gBolEnviandoFila || gBolBloqueado) {
      if (gValorCampo!=null)
        ponerTexto(campoCambiado, gValorCampo);
      return false;
    } else {
		  fila = nd;
    }
	}
	return true;
}

/* Recorre el arbol DOM hacia arriba (de hijo a padre) desde el elemento indicado en nodo, con
el fin de buscar un nodo que tenga un atributo id cuyo valor sea valor*/
function buscarPadre(nodo, id, valor)
{
	if (nodo!=null && nodo.getAttribute) 
	{
		var v = nodo.getAttribute(id);
		if (v!=null && v==valor)
    		return nodo;
		else
			return buscarPadre(nodo.parentNode, id, valor);
    }
	else
		return null;
}

/*	Recorre los elementos del mismo nivel, comenzando desde el que se le pasa, hasta encontrar
	otro elemento siguiente que tenga un identificador con el valor indicado. Esta función sirve
	para evitar los problemas entre Navegadores, ya que, por ejemplo, Netscape trata las tablas
	de tal forma que entre TR y TR hay un elemento de Texto, mientras que para IE no
*/
function buscarSiguiente(nodo, id, valor)
{
	nodo = nodo.nextSibling;
	while (nodo != null)
	{
		if (nodo.getAttribute)
		{
			var v = nodo.getAttribute(id);
			if (v!=null && v==valor)
				return nodo;
		}
		nodo = nodo.nextSibling;
	}
	return null;
}

/*	Recorre los elementos del mismo nivel, comenzando desde el que se le pasa, hasta encontrar
	otro elemento anterior que tenga un identificador con el valor indicado. Esta función sirve
	para evitar los problemas entre Navegadores, ya que, por ejemplo, Netscape trata las tablas
	de tal forma que entre TR y TR hay un elemento de Texto, mientras que para IE no
*/
function buscarAnterior(nodo, id, valor)
{
	nodo = nodo.previousSibling;
	while (nodo != null)
	{
		if (nodo.getAttribute)
		{
			var v = nodo.getAttribute(id);
			if (v!=null && v==valor)
				return nodo;
		}
		nodo = nodo.previousSibling;
	}
	return null;
}

/*Recorre el arbol DOM hacia abajo (de padre a hijos) desde el elemento indicado en nodo, con el
fin de localizar el nodo que tenga un atributo id cuyo valor sea valor*/
function buscarHijo(nodo, id, valor)
{
	var resultado = null;
	if (nodo!=null && nodo.getAttribute) 
	{
		var v = nodo.getAttribute(id);
		if (v!=null && v==valor)
    		return nodo;
		var child = nodo.firstChild;
		while (child != null)
		{
			resultado = buscarHijo(child, id, valor);
			if (resultado!=null)
				return resultado;
			child = child.nextSibling;
		}
    }
	return null;
}

function esModelo(nodo)
{
	if (nodo==null) return false;
	var ndModelo = buscarHijo(nodo, "name", "Modelo");
	return (ndModelo!=null);
}

function rellenarValorCombo(nodo, datos) {
  if (nodo==null || datos==null) return false;
  var total = nodo.options.length;
  for (var i = 0;i<total;i++) {
    nodo.options[i].selected = (nodo.options[i].value==datos);
  }
  return true;
}


function eliminarFila(_parametros, borrarCombo, nodo, tipo)
{
  if (nodo==null) return false;
	deseleccionarFila(true);
	var i=0;
	if (nodo==null)
		nodo = fila;
	if (nodo==null) return false;
	if ((tipo!=null && tipo==1) || esModelo(nodo))
	{
		limpiarNodo(nodo);
		var ndObjetos = null;
    if (borrarCombo != null)
		{
      var total = borrarCombo.length;
			for (i = 0;i<total;i++)
			{
				ndObjetos = buscarHijo(nodo, "name", borrarCombo[i]);
				if (ndObjetos!=null)
					borrarOptions(ndObjetos);
			}
		}
    borrarValores(nodo);
		if (_parametros != null)
		{
      var total = _parametros.length;
			for (i = 0;i<total;i++)
			{
				ndObjetos = buscarHijo(nodo, "name", _parametros[i][0]);
				if (ndObjetos!=null)
				{
					if (ndObjetos.type) {
            if (ndObjetos.type.indexOf("select")!=-1) rellenarValorCombo(ndObjetos, _parametros[i][1]);
            else if (ndObjetos.type == "checkbox" || ndObjetos.type == "radio") ndObjetos.checked = (ndObjetos.value==_parametros[i][1]);
            else ponerTexto(ndObjetos, _parametros[i][1]);
          } else if (_parametros[i].length==2) ponerTexto(ndObjetos, _parametros[i][1]);
          else ndObjetos.setAttribute(_parametros[i][1], _parametros[i][2]);
				}
			}
		}
	}
	else
	{
		nodo.parentNode.removeChild(nodo);
	}
	return true;
}

function borrarFila(campo)
{
	var nodo = buscarPadre(campo, gId, gFila);
	if (nodo==null) return false;
	fila = nodo;
	enviarFila("DELETE");
}

function buscarPrimerElementoFila(fila) {
  if (fila==null) fila=gFilaActual;
  if (fila!=null) return buscarPrimerElemento(fila);
  return null;
}

function buscarPrimerElemento(nodo) {
  if (esCampoInput(nodo)) {
    return nodo;
	} else {
    var child = nodo.firstChild;
    nodo = null;
    while (child != null && nodo==null) {
      nodo=buscarPrimerElemento(child);
      child = child.nextSibling;
    }
  }
  return nodo;
}

function buscarUltimoElementoFila(fila) {
  if (fila==null) fila=gFilaActual;
  if (fila!=null) return buscarUltimoElemento(fila);
  return null;
}

function buscarUltimoElemento(nodo) {
  var ultimo_nodo = null;
  if (esCampoInput(nodo)) {
    ultimo_nodo = nodo;
	}
  var child = nodo.firstChild;
  while (child != null) {
    nodo=buscarPrimerElemento(child);
    if (nodo!=null) ultimo_nodo = nodo;
    child = child.nextSibling;
  }
  return ultimo_nodo;
}

function borrarValores(nodo)
{
	if (nodo.type) {
		if (nodo.type == "checkbox" || nodo.type == "radio") nodo.checked=false;
		else if (nodo.type.indexOf("select")!=-1) rellenarValorCombo(nodo, "");
    else nodo.value = "";
  }
	var child = nodo.firstChild;
	while (child != null)
	{
		borrarValores(child);
		child = child.nextSibling;
	}
	return true;
}

/*El nodo es la fila en la que se encuentran los input que queremos localizar y esta función recorre
toda la fila en busca de esos input para cargarlos en un array*/
function cargarArray(nodo,n)
{
	if (nodo.type) 
	{
		if (nodo.type.indexOf("checkbox")!=-1 || nodo.type.indexOf("radio")!=-1)
		{
			parametros[n++] = new Array(nodo.name, (nodo.checked)?nodo.value:"");
		}
		else if (nodo.value)
		{
			parametros[n++] = new Array(nodo.name, nodo.value);
		}
    }
	var child = nodo.firstChild;
	while (child != null)
	{
		n=cargarArray(child,n);
		child = child.nextSibling;
	}
	return n;
}

/*Se le pasa el elemento pinchado y esta función determina cúal es su fila para luego buscar todos
sus inputs y enviarlos en un array el frame oculto para que haga un submit de su formulario*/
function enviarFila(strAccion)
{
  if (fila==null) return false;
  if (gBolEnviandoFila) return false;
  gBolEnviandoFila=true;
	if (strAccion==null)
		strAccion = "SAVE_EDIT";
  parametros = new Array();
	cargarArray(fila,0);
	if (gBolEvtEnviarLinea)
	{
		if (!alEnviarLinea(fila, parametros, strAccion))
		{
			fila = null;
      gBolEnviandoFila=false;
			return false;
		}
	}
	fila=null;
  var frame = eval(gHiddenFrame);
	frame.submitArray(parametros, frmFormulario, strAccion, gTargetFrame);
	return true;
}

/*	Devuelve el texto existente en un nodo dado
*/
function obtenerTexto(nodo)
{
	if (nodo==null) return "";
	if (nodo.data)
		return nodo.data;
	else
		return obtenerTexto(nodo.firstChild);
}

/*	Pone el texto en el campo de que se trate
*/
function ponerTexto(nodo, strTexto)
{
	var i=0;
	if (nodo==null) return false;
	
	if (nodo.type)
	{
		switch (nodo.type)
		{
		case "select-multiple":
		case "select-one":	var total = nodo.options.length;
              for(i=0;i<total;i++)
							{
								if (nodo.options[i].value == strTexto)
									nodo.options[i].selected = true;
								else
									nodo.options[i].selected = false;
							}
							break;
		case "text":
		case "hidden":
		case "password":	nodo.value = strTexto;
							break;
		case "checkbox":
		case "radio":	if (nodo.length==1)
							nodo.checked = (nodo.value==strTexto);
						else
						{
              var total = nodo.length;
							for (i=0;i<total;i++)
							{
								if (nodo[i].value == strTexto)
									nodo.checked = true;
								else
									nodo.checked = false;
							}
						}
						break;
		}
	} 
	else if (nodo.data)
	{
		nodo.data = strTexto;
	}
	else
	  ponerTexto(nodo.firstChild, strTexto);
	return true;
}

/*	Realiza una busqueda a través de las filas de un multilinea, por los campos marcados con
	el valor strIdBusqueda, hasta encontrar el texto strBuscar, devolviendo el nodo de la
	fila en la que los ha encontrado
*/

function buscarTexto(f, strIdBusqueda, strBuscar)
{
	if (f==null) return null;
	var Busqueda = buscarHijo(f, gId, strIdBusqueda);
	if (Busqueda != null)
	{
		if (obtenerTexto(Busqueda).toUpperCase().indexOf(strBuscar.toUpperCase())!=-1)
			return f;
	}
	return buscarTexto(buscarSiguiente(f, gId, gFila), strIdBusqueda, strBuscar);
}

/*	Busca una Fila a partir de un elemento de la misma, pero ha de tratarse de un elemento que la
	identifique de forma única, porque sino devolverá la primera fila que encuentre.
*/
function buscarFila(ndForm, campo, texto)
{
	var nodoFila = buscarHijo(ndForm, "name", campo);
	if (nodoFila==null) return null;
	if (nodoFila.getAttribute("value")==texto)
	{
		return buscarPadre(nodoFila, gId, gFila);
	}
	nodoFila = buscarPadre(nodoFila, gId, gFila);
	return buscarFila(buscarSiguiente(nodoFila, gId, gFila), campo, texto);
}

/*	Realiza una búsqueda en el texto de la página HTML, por los campos marcados con el valor
	strIdBusqueda, y buscando el texto strBuscar. Si lo encuentra pone el foco en el control
	indicado en strCampo
*/

function realizarBusqueda(form, strIdBusqueda, strCampo, strBuscar, primerElemento)
{
  gBuscarPorBusqueda=strIdBusqueda;
  gValorBusqueda=strBuscar;
  var f=null;
  if (primerElemento==null || primerElemento) 
	  f = buscarTexto(form, strIdBusqueda, strBuscar);
  else
    f = buscarTexto(buscarSiguiente(form, gId, gFila), strIdBusqueda, strBuscar)
  gNodoBusqueda=f;
	if (f==null) return false;
	f=buscarHijo(f, "name", strCampo);
	if (f==null) return true;
	f.focus();
	return true;
}


function inicializarCampo(nodo)
{
	var i=0;
	if (nodo==null) return false;
	if (nodo.data)
		nodo.data = "";
	else if (nodo.type)
	{
		switch (nodo.type)
		{
		case "select-multiple" :
		case "select-one":	var total = nodo.options.length;
              for(i=0;i<total;i++)
								nodo.options[i].selected = false;
							break;
		case "text":	if (nodo.value)
						{
							if (!isNaN(Number(nodo.value)))
								nodo.value="0";
							else
								nodo.value="";
						}
						break;
		case "password":	nodo.value = "";
							break;
		case "checkbox":
		case "radio":	if (nodo.length==1)
							nodo.checked = false;
						else
						{
              var total = nodo.length;
							for (i=0;i<total;i++)
								nodo.checked = false;
						}
						break;
		}
	}
}

function limpiarNodo(nodo)
{
	if (nodo.type) 
		inicializarCampo(nodo);
	var child = nodo.firstChild;
	while (child != null)
	{
		limpiarNodo(child);
		child = child.nextSibling;
	}
	return true;
}

function agregarFila(fila, _parametros, borrarCombo) {
  deseleccionarFila();
  if (gBolEnviandoFila) return null;
  var ndFilaNueva = fila.cloneNode(true);
  var ndRaiz = fila.parentNode;
  if (ndRaiz==null) return null;
  ndRaiz.appendChild(ndFilaNueva);
  if (!eliminarFila(_parametros, borrarCombo, ndFilaNueva, 1)) return null;
  return ndFilaNueva;
}
/*
function nuevaFila(ndForm, parametros, borrarCombo)
{
	deseleccionarFila();
	var i=0;
	var nodo = buscarHijo(ndForm, "name", "Modelo");
	if (nodo==null) return null;
	nodo = buscarPadre(nodo, gId, gFila);
	ndForm = nodo.parentNode;
	var ndFilaNueva = nodo.cloneNode(true);
	if (!eliminarFila(parametros, borrarCombo, ndFilaNueva, 1)) return null;
	nodo = buscarHijo(ndFilaNueva, "name", "Modelo");
	if (nodo!=null)
		nodo.removeAttribute("name");
	ndForm.appendChild(ndFilaNueva);
	return ndFilaNueva;
}
*/
function restaurarValores(arrayValores, nodo)
{
	if (nodo.type!=null) 
	{
		if (nodo.name)
		{
			var strValor = obtenerValor(arrayValores, nodo.name, true)
			if (strValor!=null)
				ponerTexto(nodo, strValor);
		}
    }
	var child = nodo.firstChild;
	while (child != null)
	{
		restaurarValores(arrayValores, child);
		child = child.nextSibling;
	}
	return true;
}

function obtenerValor(arrayValores, strKey, nullable)
{
  if (nullable==null) nullable=false;
	if (arrayValores==null || strKey==null) return (nullable?null:"");
  var total = arrayValores.length;
	for (var i=0;i<total;i++)
		if (arrayValores[i][0]==strKey)
			return arrayValores[i][1];
	return (nullable?null:"");
}

function borrarPruebas() {
  var ndFila1 = buscarAnterior(gFilaActual, gId, gFila);
  if (ndFila1 == null) {
    ndFila1 = buscarSiguiente(gFilaActual, gId, gFila);
  }
  if (ndFila1 != null) {
    ndFila1 = buscarPrimerElementoFila(ndFila1);
    eliminarFila(null, null, gFilaActual);
    seleccionarFila(ndFila1);
  } else { //Es última fila
    ndFila1 = buscarPrimerElementoFila(gFilaActual);
    eliminarFila(null, null, gFilaActual, 1);
    seleccionarFila(ndFila1);
  }
}

function filtrarRespuesta(respuesta, respuestaNew)
{
  gBolEnviandoFila=false;
	if (respuesta==null) return false;
	var objFila = null;
	var strCommand = obtenerValor(respuesta, "Command");
	var strForm = obtenerValor(respuesta, "Formulario");
	var frmForm = "";

  if (strForm == "")
    frmForm = document.forms[0];
  else
    frmForm = eval(strForm);
	if (respuesta.length>1)
	{
    frmForm = buscarHijo(frmForm, gId, gFila);
		objFila = buscarFila(frmForm,respuesta[1][0],respuesta[1][1]);
		if (strCommand!="ERROR" && objFila==null) return false;
	}
	
	if (gBolEvtAntesDeFiltrarRespuesta)
		if (!antesDeFiltrarRespuesta(respuesta, objFila))
			return false;
	
	if (strCommand=="REFRESH")
	{
		document.href.src = document.href.src;
		return false;
	}
	else if (strCommand=="DELETE")
	{
		if (gBolEvtAntesDeBorrar)
			if (!antesDeBorrar(respuesta, objFila))
				return false;
    var ndFila1 = buscarAnterior(objFila, gId, gFila);
    if (ndFila1 == null) {
      ndFila1 = buscarSiguiente(objFila, gId, gFila);
    }
    if (ndFila1 != null) {
      ndFila1 = buscarPrimerElementoFila(ndFila1);
      eliminarFila(null, null, objFila);
      seleccionarFila(ndFila1);
    } else { //Es última fila
      ndFila1 = ndFila1 = buscarPrimerElementoFila(objFila);
      eliminarFila(respuestaNew, null, objFila, 1);
      seleccionarFila(ndFila1);
    }
	}
	else if (strCommand=="SAVE_EDIT" || strCommand=="SAVE_NEW")
	{
		if (respuesta.length>1 && gBolEvtAntesDeActualizar) {
			if (!antesDeActualizar(respuesta, objFila)) return false;
    }
    if (strCommand=="SAVE_NEW")
    {
      if (gBolEvtAntesDeNuevo)
        if (!antesDeNuevo(respuestaNew))
          return false;
      objFila = agregarFila(objFila, respuestaNew);
      if (objFila!=null) {
        //gFilaActual = objFila;
        var ndLast = buscarPrimerElementoFila(objFila);
        if (ndLast!=null) {
          gUltimoCampo = ndLast.name;
          seleccionarFila(ndLast, true);
        }
      }
      if (gBolEvtDespuesDeNuevo)
        if (!despuesDeNuevo(respuestaNew))
          return false;
    }
	}
  else if (strCommand=="CAMBIO_PANEL") 
  {
    if (gBolEvtAntesDeActualizar)
			if (!antesDeActualizar(respuesta, objFila))
				return false;
  }
	else if (strCommand=="ERROR")
	{
		if (gBolEvtErrorEnRespuesta)
			if (!errorEnRespuesta(respuesta, objFila))
				return false;
		if (objFila!=null)
			restaurarValores(respuesta, objFila);
		var strMensaje = obtenerValor(respuesta, "MENSAJE_ERROR");
		if (strMensaje!=null)
			alert(strMensaje);
		return false;
	}
	ejecutarRespuesta(respuesta, objFila);
}

function restoreFilaSelected(evt) {
  var target = null;
  if (navigator.appName == "Netscape") {
    document.routeEvent(evt);
    target = evt.target;
  } else {
    evt = event;
    target = evt.srcElement;
  }
  if (gFilaActual==null) {
    setFocusFirstControl();
  } else {
    if (gUltimoCampo!=null && gUltimoCampo!="") {
      var nd = buscarHijo(gFilaActual, "name", gUltimoCampo);
    } else {
      var nd = buscarPrimerElementoFila(gFilaActual);
    }
    if (nd != null && nd.type && nd.type!="hidden") nd.focus();
  }
  return true;
}

function esTeclaInterna(evt, tecla, target) {
  var esInterna = false;
  switch (tecla) {
    case obtainKeyCode("TAB"): 
            esInterna=(!evt.shiftKey && !evt.ctrlKey && !evt.altKey);
            break;
    case obtainKeyCode("ENTER"):
            esInterna=(!evt.shiftKey && !evt.ctrlKey && !evt.altKey);
            break;
    case obtainKeyCode("F7"):
            esInterna = (gIsDeleteableRows && !evt.shiftKey && !evt.ctrlKey && !evt.altKey);
            break;
    case obtainKeyCode("F8"):
            esInterna = (gActivateTabJump && !evt.shiftKey && !evt.ctrlKey && !evt.altKey);
            break;
    case obtainKeyCode("UPARROW"):
            esInterna = ((target.type.indexOf("select")==-1) && (!evt.shiftKey && !evt.ctrlKey && !evt.altKey));
            break;
    case obtainKeyCode("DOWNARROW"):
            esInterna = ((target.type.indexOf("select")==-1) && (!evt.shiftKey && !evt.ctrlKey && !evt.altKey));
            break;
    default:
            esInterna = false;
            break;
  }
  return esInterna;
}

/*	Controla si se ha pulsado las flechas de arriba o abajo para desplazar el control a la
	siguiente línea del multilínea.
*/

function controlarTecla(evt)
{
  var total = controlTecla(evt);
  var fieldName = "";
  if (total) {
    if (gFilaActual!=null)
    {
      var tecla = null;
      var target = null;
      if (navigator.appName == "Netscape")
      {
        document.routeEvent(evt);
        tecla = evt.which;
        target = evt.target;
      }
      else
      {
        tecla = event.keyCode;
        target = event.srcElement;
        evt = event;
      }

      if (!(target.type)) { 
        if (arrTeclas!=null && arrTeclas.length>0) 
          return controlTecla(evt);
        else
          return true;
      }
      fieldName = target.name;
      if (!esTeclaInterna(evt, tecla, target)) return true;
      var ndFila=buscarPadre(target, gId, gFila);
      if (ndFila==null) return true;

      if (tecla == obtainKeyCode("UPARROW")) //Subir
      {
        ndFila = buscarAnterior(ndFila, gId, gFila);
        if (ndFila == null)
        {
          ndFila = gFilaActual;
          var ndFila1 = buscarSiguiente(gFilaActual, gId, gFila);
          if (ndFila1 == null)
          {
            fila = gFilaActual;
            enviarFila();
          }
          else
          {
            ndFila1 = buscarHijo(ndFila1, "name", target.name);
            if (ndFila1 != null)
              ndFila1.focus();
          }
          gFilaActual = ndFila;
        }
      }
      else if ((tecla == obtainKeyCode("DOWNARROW") || tecla == obtainKeyCode("ENTER")) && !evt.ctrlKey  && !evt.altKey && !evt.shiftKey) //Bajar
      {
        ndFila = buscarSiguiente(ndFila, gId, gFila);
        if (ndFila == null)
        {
          if (gIsAutoInsertRows) { //Auto inserción de filas
            fila = gFilaActual;
            ndFila = gFilaActual;
            enviarFila("SAVE_NEW");
          } else {
            ndFila = gFilaActual;
            var ndFila1 = buscarAnterior(gFilaActual, gId, gFila);
            if (ndFila1 == null) {
              fila = gFilaActual;
              ndFila1 = gFilaActual;
              enviarFila();
            } else {
              ndFila1 = buscarHijo(ndFila1, "name", target.name);
              if (ndFila1 != null)
                ndFila1.focus();
            }
            gFilaActual = ndFila;
          }
        }
      }
      else if (tecla == obtainKeyCode("TAB") && !evt.shiftKey) //Salir campo
      {
        var ndLast = buscarUltimoElementoFila(ndFila);
        if (ndLast.name==target.name) {
          if (buscarSiguiente(ndFila, gId, gFila)==null) {
            if (gIsAutoInsertRows) { //Auto inserción de filas
              fila = gFilaActual;
              ndFila = gFilaActual;
              enviarFila("SAVE_NEW");
              //var FilaActual = gFilaActual;
              //ndFila = agregarFila(gFilaActual, null, null);
              //ndLast = buscarPrimerElementoFila(ndFila);
              //if (ndLast!=null) fieldName = ndLast.name;
            } else {
              ndFila = gFilaActual;
              var ndFila1 = buscarAnterior(gFilaActual, gId, gFila);
              if (ndFila1 == null) {
                fila = gFilaActual;
                ndFila1 = gFilaActual;
                enviarFila();
              } else {
                ndFila1 = buscarHijo(ndFila1, "name", target.name);
                if (ndFila1 != null)
                  ndFila1.focus();
              }
              gFilaActual = ndFila;
              return true;
            }
          } else return true;
        } else {
          return true;
        }
      }
      else if (tecla == obtainKeyCode("F7") && (!evt.shiftKey && !evt.ctrlKey && !evt.altKey)) //Borrar registro
      {
        fila = gFilaActual;
        enviarFila("DELETE");
        //borrarPruebas();
        ndFila = gFilaActual;
        //fieldName = gUltimoCampo;
      }
      else if (tecla == obtainKeyCode("F8") && (!evt.shiftKey && !evt.ctrlKey && !evt.altKey)) //Cambiar de panel
      {
        fila = gFilaActual;
        enviarFila("CAMBIO_PANEL");
        ndFila = gFilaActual;
        fieldName = gUltimoCampo;
      } else return true;

      ndFila = buscarHijo(ndFila, "name", fieldName);
      if (ndFila == null) return true;
      ndFila.focus();
      evt.returnValue = false;
      evt.cancelBubble = true;
      return false;
    }
  }
	return true;
}

function controlExitLines(evt) {
  return true;
  fila = gFilaActual;
  enviarFila();
}

if (!(document.all))
{
  document.captureEvents(Event.KEYDOWN);
  window.captureEvents(Event.FOCUS);
  window.captureEvents(Event.BLUR);
}
document.onkeydown=controlarTecla;
window.onfocus=restoreFilaSelected;
window.onblur=controlExitLines;
