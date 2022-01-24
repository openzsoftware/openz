/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
*************************************************************************************************************************************************** 
*/ 
 
/**
 * 
 * 
 *  Generally Used Functions
 * 
 * 
 * 
*/
function getElementsByClassName(classname){
 var all_obj=new Array();
 var ret_obj=new Array();
 var teststr;  
 var j=0;
          var all_obj,ret_obj=new Array(),teststr;  
          if(document.all)all_obj=document.all;  
          else if(document.getElementsByTagName && !document.all)all_obj=document.getElementsByTagName("*");  
          for(i=0;i<all_obj.length;i++)  
          {  
            if(all_obj[i].className.indexOf(classname)!=-1)  
            {  
              teststr=","+all_obj[i].className.split(" ").join(",")+",";  
              if(teststr.indexOf("," +classname + ",")!=-1)  
              {  
                ret_obj[j]=all_obj[i];
                j=j+1;
              }
            }
          }
  return ret_obj;
}

/** 
 * Links direct to another servlet
 * uses Hidden Field inpDirectKey, fills in The key
 * Then changes the Name of the Hidden field and Posts the Form to the Servlet
 * 
*/
function submitCommandChangingName(key, url, recordName){
       document.getElementById("inpDirectKey").name = recordName;
       submitCommandFormParameter('DIRECT', document.getElementById("inpDirectKey"), key, false, document.frmMain, url, null, false, true);
}   

/** 
 * Links direct from a popup to another servlet
 * calculated appropriate url
 * 
*/
function getmainfrompopup(id, idcolumn, destpath){
        //id-->uuid  idcolumn-->inpcProjecttaskId destpath-->/org.openbravo...
        var locpath=content.location.href;
        destpath=destpath+"?Command=EDIT&"+idcolumn+"="+id;
        locpath=locpath.replace("ad_actionButton/ActionButton_Responser.html",destpath);
        top.close();
        window.open(locpath, 'appFrame');
        return true;
}
/** 
 * Validates all mandantory Fields in a form
 * 
 * 
*/
function validateMandantoryFields(){
  var all_obj=document.getElementsByTagName("INPUT");
  for(i=0;i<all_obj.length;i++)  {
      if (all_obj[i].required && (all_obj[i].value==null || all_obj[i].value=="")) {
            setWindowElementFocus(all_obj[i]);
            showJSMessage(1);
            return false;
      }
  } 
  var all_obj=document.getElementsByTagName("SELECT");
  for(i=0;i<all_obj.length;i++)  {
      if (all_obj[i].required && (all_obj[i].value==null || all_obj[i].value=="")) {
            setWindowElementFocus(all_obj[i]);
            showJSMessage(1);
            return false;
      }
  }
  return true;    
}

               
/* Funktion für Checkbox - Value ändern N=checked Y=unchecked */
 function yn(id){
	 if (id.value=="N"){id.value="Y"}			//Wenn der Value der Checkbox "N" ist, "Y" hineinschreiben
	 else {id.value="N";}					//sonst "N" hineinschreiben	
 }

 /* Funktion für Inputboxen - Prüfen ob sinnvolle Zahl */
 function isaNumber(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);	
} 

/* Funktion: Input als Zahl aufbereiten */
 function str2numberFormat(strInput){
    var decSeparator = getGlobalDecSeparator();
    var groupSeparator = getGlobalGroupSeparator();
    var strOutput=strInput;
    strOutput=strOutput.replace(groupSeparator,"");
    strOutput=strOutput.replace(decSeparator,".");
    return strOutput;
}
/* Funktion: Input als Zahl aufbereiten 
 frmat : euroEdition, qtyEdition,priceEdition, integerEdition */
 function number2strFormat(strInput,frmat){
    var decSeparator = getGlobalDecSeparator();
    var groupSeparator = getGlobalGroupSeparator();
    var groupInterval = getGlobalGroupInterval();
    var maskNumeric = formatNameToMask(frmat);
    var formattedValue = returnCalcToFormatted(strInput, maskNumeric, decSeparator, groupSeparator, groupInterval);
    return formattedValue;
}
/** 
 * Funktion zeigen und verstecken von  irgendwas über classname
 * 
 * DEPRECATED 
 * DELETE when genarateinvoicemanually is replaced by Openz GUI Engine
 * 
 */
 /* Funktion für Inputboxen - Produkt bilden von Inputbox Menge und Inputbox Preis in Betrag zusätzlich beschränken auf 4 Nachkommastellen Warnmeldung bei keiner Zahl Punkte und Kommas anpassen*/
 function dyncalcsum(key){
       calcsum(key,"SumCalc","PriceNetVal","Qtyordered");
    	
}
/** 
 * Funktion zeigen und verstecken von  irgendwas über classname
 * 
 * DEPRECATED 
 * DELETE when genarateinvoicemanually is replaced by Openz GUI Engine
 * 
 */
 /* Funktion für Inputboxen -  bilden von Inputbox Betrag durch Inputbox Menge gleich Preis  zusätzlich beschränken auf 4 Nachkommastellen Warnmeldung bei keiner Zahl Punkte und Kommas anpassen*/
 function dyncalcprice(key){
	calcprice(key,"SumCalc","PriceNetVal","Qtyordered");
	
 	
}

 /* Funktion für Inputboxen - Produkt bilden von Inputbox Menge und Inputbox Preis in Betrag zusätzlich beschränken auf 4 Nachkommastellen Warnmeldung bei keiner Zahl Punkte und Kommas anpassen*/
 function calcsum(key,sumfield,pricefield,qtyfield){
        var frm = document.frmMain;
        var sum = frm.elements["inp" + sumfield + key].value;       //Summenfeld (name=inpSumCalc+orderlineid)
        sum=sum.replace(',', '.');                              //Kommatar mit Punkten tauschen bei der Summe
        var price = frm.elements["inp" + pricefield + key].value; //Preisfeld (name=inpPriceNetVal+orderlineid)
        price=price.replace(',', '.');                          //Kommatar mit Punkten tauschen beim Preisfeld
        var qty = frm.elements["inp" + qtyfield + key].value;    //Mengenfeld (name=inpQtyordered+orderlineid)
        qty=qty.replace(',', '.');                              //Kommatar mit Punkten tauschen beim Mengenfeld
                
        if(isaNumber(qty) && isaNumber(price)) {                //Prüfen ob Mengenfeld und Preisfeld eine sinnvolle Zahl sind
                var sumshort=(qty)*(price);                     //Berechnung des Produkts Menge x Preis
                sum= (sumshort.toFixed(4));                     //Kürzen des Summenergebnisses auf vier Nachkommastellen
                sum=sum.replace('.', ',');      
                frm.elements["inp" + sumfield + key].value=sum;     //Summenfeld befüllen
        }else {                                                 //Falls Menge UND Preis keine sinnvolle Zahl sind Fehlermeldung ausgeben
                                        }
        
}

 /* Funktion für Inputboxen -  bilden von Inputbox Betrag durch Inputbox Menge gleich Preis  zusätzlich beschränken auf 4 Nachkommastellen Warnmeldung bei keiner Zahl Punkte und Kommas anpassen*/
 function calcprice(key,sumfield,pricefield,qtyfield){
        var frm = document.frmMain;
        var sum = frm.elements["inp" + sumfield + key].value;       //Summenfeld (name=inpSumCalc+orderlineid)
        sum=sum.replace(',', '.');                              //Kommatar mit Punkten tauschen bei der Summe
        var price = frm.elements["inp" + pricefield + key].value;  //Preisfeld (name=inpPriceNetVal+orderlineid)
        price=price.replace(',', '.');                          //Kommatar mit Punkten tauschen beim Preisfeld
        var qty = frm.elements["inp" + qtyfield + key].value;    //Mengenfeld (name=inpQtyordered+orderlineid)
        qty=qty.replace(',', '.');                              //Kommatar mit Punkten tauschen beim Mengenfeld
        
        if(isaNumber(qty) && isaNumber(sum)) {                  //Prüfen ob Mengenfeld und Summenfeld eine sinnvolle Zahl sind
                var sumshort=(sum)/(qty);                       //Quotient aus Summe / Menge um Stückpreis zu bestimmen
                price=(sumshort.toFixed(4));                    //Kürzen des Stückpreises auf vier Nachkommastellen
                price=price.replace('.', ',');  
                frm.elements["inp" + pricefield + key].value=price;//Preisfeld befüllen
        }else {                                                 //Falls Menge UND Summe keine sinnvolle Zahl sind Fehlermeldung ausgeben
                        }
        
        
}

 /* Funktion für Inputboxen - %-Wert bilden von Inputbox, %-Feld . Wert in outputbox setzen. zusätzlich beschränken auf 4 Nachkommastellen Warnmeldung bei keiner Zahl Punkte und Kommas anpassen*/
 function calcpercx(key,infield,percfield,outfield,addorsub){
        var frm = document.frmMain;
        var inp = frm.elements["inp" + infield + key].value;       //Summenfeld (name=inpSumCalc+orderlineid)
        inp=inp.replace(',', '.');                              //Kommatar mit Punkten tauschen bei der Summe
        var perc = frm.elements["inp" + percfield + key].value; //Preisfeld (name=inpPriceNetVal+orderlineid)
        perc=perc.replace(',', '.');                          //Kommatar mit Punkten tauschen beim Preisfeld
            
        if(isaNumber(inp) && isaNumber(perc)) {                //Prüfen ob Mengenfeld und Preisfeld eine sinnvolle Zahl sind
                var sumshort;
                if (addorsub=="add")
                    sumshort=Number((inp*perc)/100) + Number(inp);                     //Berechnung des Produkts Menge x Preis
                else
                    sumshort=Number(inp) - Number((inp*perc)/100);  
                var ergt= (sumshort.toFixed(2));                     //Kürzen des Summenergebnisses auf vier Nachkommastellen
                var ergt=ergt.replace('.', ',');      
                frm.elements["inp" + outfield + key].value=ergt;     //Summenfeld befüllen
        }else {                                                 //Falls Menge UND Preis keine sinnvolle Zahl sind Fehlermeldung ausgeben
                                        }
        
}
/* Overload for Compat.*/
function calcperc(key,infield,percfield,outfield){
    return calcpercx(key,infield,percfield,outfield,"add");
}

function calcpercsub(key,infield,percfield,outfield){
    return calcpercx(key,infield,percfield,outfield,"sub");
}

/* Funktion für Inputboxen - Auf dem Header wird ein Wert angegeben, der sich in eine Box in die Zeilen überträgt, Für die eigene Gruppen ID */
function gridHeaderValue2Lines(thisGroupid, infield, outfields,calctype,calcfield1, calcfield2, calcfield3){
        var frm = document.frmMain;
        var all_obj = new Array(); 
        var myobjval = frm.elements["inp" + infield + thisGroupid].value; 
        // GO down, if this is a group checkbox
        all_obj=document.getElementsByTagName("INPUT"); 
        for(i=0;i<all_obj.length;i++)  
        {  
            if (all_obj[i].getAttribute("parentId")==thisGroupid)  {
                  var idval=all_obj[i].id;
                  if (calctype=='date') {
                      if (myobjval.substring(myobjval.length - 3, myobjval.length -2)=="-")
                          myobjval=myobjval.substring(0,myobjval.length - 3) + "-20" + myobjval.substring(myobjval.length - 2, myobjval.length);
                  }    
                  frm.elements["inp" + outfields + idval].value=myobjval;
                  if (frm.elements["inp" + outfields + idval].type=="checkbox") {
                      if (myobjval=="Y")
                          frm.elements["inp" + outfields + idval].checked=true;
                      else
                          frm.elements["inp" + outfields + idval].checked=false;
                  }
                  if (calctype=='calcperc') {
                      calcperc(idval,calcfield1, calcfield2, calcfield3);
                  }
                  if (calctype=='calcpercsub') {
                      calcpercsub(idval,calcfield1, calcfield2, calcfield3);
                  }
                  if (calctype=='calcprice') {
                      calcprice(idval,calcfield1, calcfield2, calcfield3);
                  }
                  if (calctype=='calcsum') {
                      calcsum(idval,calcfield1, calcfield2, calcfield3);
                  }
            }
        }
}


 /** 
  * Funktion Verfügbare Menge überprüfen
  * Wenn Eingabemenge > verfügbar  ---> Warnmeldung
  * Multi Usable Sum calculation
  * Available has to be bigger or equals
  * key @groupid@
  */
 
 function checkavailable(key, editfield, maxfield){
	 var frm = document.frmMain;
	 var maxfield=(maxfield + key);
	 var editfield=(editfield + key);
	 var userLang = (navigator.language) ? navigator.language : navigator.userLanguage; 
	 var available=parseFloat(frm.elements[maxfield].value);
	 //alert(available);
	 var request=parseFloat(frm.elements[editfield].value);
	 if(request<=available){}else{
               if (userLang=='de-DE')
                 {var messagetxt=confirm('Fehler!\nDer eingegebene Wert ist höher als der verfügbare.\nWert auf Maximum setzen?');}
               else{var messagetxt=confirm('Error!\nThe entered value is greater than the available value.\nSet value to the max?');}
               if (messagetxt==true){frm.elements[editfield].value=available}
		 
		 }
 }
/** 
 * Funktion zeigen und verstecken von  irgendwas über classname
 * 
 * DEPRECATED 
 * DELETE when genarateinvoicemanually is replaced by Openz GUI Engine
 * 
 */
function zeigen(names){                                         //zeigen des Elements mit classname 
          var all_obj,ret_obj=new Array(),teststr;  
          if(document.all)all_obj=document.all;  
          else if(document.getElementsByTagName && !document.all)all_obj=document.getElementsByTagName("*");  
          for(i=0;i<all_obj.length;i++)  
          {  
            if(all_obj[i].className.indexOf(names)!=-1)  
            {  
              teststr=","+all_obj[i].className.split(" ").join(",")+",";  
              if(teststr.indexOf(","+names+",")!=-1)  
              {  
                      if(all_obj[i].style.display != "none"){ 
                  all_obj[i].style.display="none"; 
                        } 
                        else all_obj[i].style.display="block";              
              }  
            }  
          } 
 }


 
 
 
/** 
 * 
 * 
 * 
 *   DISPLAY , READONLY, MANDANTORY Functions
 * 
 * 
 */
  

/**
 * Sets a Display mode of an Field (true or false)
*/
function fieldDisplaySettings(fieldname, display) {
  var obj = getStyle(fieldname + "td");
  if (obj!=null) {
        if (display) obj.display="";
        else obj.display="none";
  }
  obj = getStyle(fieldname + "tdx");
  if (obj!=null) {
        if (display) obj.display="";
        else {
            if ( checkBrowser().indexOf("Chrom")==-1)
                obj.display="table-column";
            else
                obj.display="none";
        }
  }
  obj = getStyle(fieldname + "lbltd");
  if (obj!=null) {
        if (display) obj.display="";
        else obj.display="none";
  }

if ( checkBrowser().indexOf("Chrom")==-1){
  obj = document.getElementById(fieldname + "lbltdx");
  if (obj!=null) {
       if (display) {
           obj.colSpan="1";
           obj.display="";
       }
        else {
            var clsp=document.getElementById(fieldname + "tdx").colSpan;
            if (clsp>2)
                clsp=2;
            obj.colSpan=clsp;
            obj.display="table-column";
        }
  }
} else {
    obj = document.getElementById(fieldname + "lbltdx");
    //getStyle(fieldname + "lbltdx");
    if (obj!=null) {
       if (display) {
           obj.colSpan="1";
           obj.display="";
       }
        else {
            var clsp=document.getElementById(fieldname + "tdx").colSpan+1;
            if (clsp>3)
                clsp=3;
            obj.colSpan=clsp;
            obj.display="none";
        }
    }
}
 
  // Used for Groups of Objects (Radio Groups etc..)
  var all_obj=getElementsByClassName(fieldname);
  for(i=0;i<all_obj.length;i++)  
  {
       if (display) all_obj[i].style.visibility = "visible";
        else all_obj[i].style.visibility = "collapse";
  } 
  return true;
}

/**
 * Sets READONLY mode of an Field (true or false)
*/
function fieldReadonlySettings(fieldname, readonly) {
  var obj = document.getElementById("link" + fieldname);
  if (obj!=null && readonly) {
        obj.display="none";
        obj.style.visibility = "collapse"; 
  }
  if (obj!=null && ! readonly) {
        obj.display="";
        obj.style.visibility = "visible"; 
  }
  var obj = document.getElementById(fieldname);
  if (obj!=null && readonly) {
         obj.readOnly=true;
         //obj.disabled=true;
         if ('options' in obj || obj.onclick) // select Box or Button
             obj.disabled=true;
         if (obj.className.indexOf("readonly")==-1) obj.className = obj.className + " readonly";
         if (obj.className.indexOf("cellreadonly")==-1) obj.className = obj.className + " cellreadonly";
         if (obj.className.indexOf("ButtonLink")!=-1 && obj.className.indexOf("ButtonLink_hover")==-1) obj.className = obj.className + " ButtonLink_hover";
         if (obj.className.indexOf("Combo")!=-1 && obj.className.indexOf("ComboKey")==-1 && obj.className.indexOf("ComboReadOnly")==-1) obj.className =  obj.className.replace("Combo","ComboReadOnly");
         if (obj.className.indexOf("ComboKey")!=-1 && obj.className.indexOf("ComboKeyReadOnly")==-1 ) obj.className =  obj.className.replace("ComboKey","ComboKeyReadOnly");
  }
  if (obj!=null && ! readonly) {
        obj.readOnly=false;
        obj.disabled=false;
        if (obj.className.indexOf("cellreadonly")!=-1)  obj.className = obj.className.replace("cellreadonly"," ");
        if (obj.className.indexOf("readonly")!=-1) obj.className = obj.className.replace("readonly"," ");
        if (obj.className.indexOf("ButtonLink_hover")!=-1) obj.className = obj.className.replace("ButtonLink_hover"," ");
        if (obj.className.indexOf("Combo")!=-1 && obj.className.indexOf("ComboKey")==-1) obj.className = obj.className.replace("ComboReadOnly","Combo");
        if (obj.className.indexOf("ComboKey")!=-1) obj.className = obj.className.replace("ComboKeyReadOnly","ComboKey");
  }
  var obj = document.getElementById(fieldname + "_DES");
  if (obj!=null && readonly && obj.className.indexOf("attrsetinstance")==-1) {
         obj.readOnly=true;
         //obj.disabled=true;
         if ('options' in obj || obj.onclick) // select Box or Button
             obj.disabled=true;
         if (obj.className.indexOf("readonly")==-1) obj.className = obj.className + " readonly";
         if (obj.className.indexOf("cellreadonly")==-1) obj.className = obj.className + " cellreadonly";
  }
  if (obj!=null && ! readonly  && obj.className.indexOf("attrsetinstance")==-1) {
        obj.readOnly=false;
        obj.disabled=false;
        if (obj.className.indexOf("cellreadonly")!=-1)  obj.className = obj.className.replace("cellreadonly"," ");
        if (obj.className.indexOf("readonly")!=-1) obj.className = obj.className.replace("readonly"," ");
  }
  // Used for Groups of Objects (Radio Groups etc..)
  var all_obj=getElementsByClassName(fieldname);
  for(i=0;i<all_obj.length;i++)  
  {
       if (readonly){
             all_obj[i].readOnly=true;
             all_obj[i].disabled=true;
       }else{
             all_obj[i].readOnly=false;
             all_obj[i].disabled=false;
       }
  }                     
  return true;
}

/* Funktion Setzen von Sichtbar oder Unsichtbar über classname*/
function setclassdidplaymode(names,visible){                                          //zeigen des Elements mit classname 
         var all_obj,ret_obj=new Array(),teststr;  
         if(document.all)all_obj=document.all;  
         else if(document.getElementsByTagName && !document.all)all_obj=document.getElementsByTagName("*");  
         for(i=0;i<all_obj.length;i++)  
         {  
           if(all_obj[i].className.indexOf(names)!=-1)  
           {  
             teststr=","+all_obj[i].className.split(" ").join(",")+",";  
             if(teststr.indexOf(","+names+",")!=-1)  
             {  
              if(visible){ 
                 all_obj[i].style.display="table-row"; 
              } 
              else all_obj[i].style.display="none";              
             }  
           }  
         } 
}

/**
 * Sets MANDANTORY mode of an Field (true or false)
*/
function fieldMandantorySettings(fieldname, mandantory) {
  var obj = document.getElementById(fieldname);
  if (obj!=null && mandantory) {
        obj.required="required";
        if (obj.className.indexOf("required")==-1)  {
           obj.className = obj.className + " required";
        }
  }
  if (obj!=null && ! mandantory) {
        obj.className = obj.className.replace("required"," ");
        obj.required="";
  }
  var obj = document.getElementById(fieldname + "_DES");
  if (obj!=null && mandantory) {
        obj.required="required";
        if (obj.className.indexOf("required")==-1)  {
           obj.className = obj.className + " required";
        }
  }
  if (obj!=null && ! mandantory) {
        obj.className = obj.className.replace("required"," ");
        obj.required="";
  }
  return true;
}


/**
 * Functions for Editable GRID
 * 
 * 
 * 
*/

/**
 * Toggles a Display mode of a class
 *   If class is Displayed, it hides the class
 *   If class is Hidden, it schows the class
 *   In the Grid, All SubItems hav the ID of Upper ITEMS as Class
*/
function toggleDisplayMode(classname){                                        
          var all_obj=getElementsByClassName(classname);  
          for(i=0;i<all_obj.length;i++)  
          {  
             if(all_obj[i].style.display != "table-row"){ 
                  all_obj[i].style.display = "table-row"; 
             } 
             else {
                  all_obj[i].style.display = "none";   
             }
          }  
}


/**
 * Toggles a Display mode of a class
 *   If class is Displayed, it hides the class
 *   If class is Hidden, it schows the class
 *   In the Grid, All SubItems hav the ID of Upper ITEMS as Class

function toggleDisplayMode(classname){                                        
          var all_obj=getElementsByClassName(classname);  
          for(i=0;i<all_obj.length;i++)  
          {  
             if(all_obj[i].style.visibility != "collapse"){ 
                  all_obj[i].style.visibility = "collapse"; 
             } 
             else {
                  all_obj[i].style.visibility = "visible";   
             }
          }  
}

*/


/** 
 * Checkbox on Editable Lines in a Grid
 * on check: Checks all childs of this line
 *           Checks also all above parent headers of this line
 * on uncheck: Unchecks all childs of this line
 * 
*/
function gridLineCheckboxClick(thisid){
        var all_obj = new Array(); 
        var myobj = document.getElementById(thisid);
        var isChecked;
        var mygroup;
        // 1.st GO down, if this is a group checkbox
        all_obj=document.getElementsByTagName("INPUT"); 
        for(i=0;i<all_obj.length;i++)  
        {  
            if (all_obj[i].getAttribute("parentId")==thisid)  {
                  all_obj[i].checked=myobj.checked;
                  setTimeout("gridLineCheckboxClick('" + all_obj[i].id + "')", 1); 
            }
        }
        // 2.nt GO up: if any box of this group is checked, all parents must be checked
        while (myobj.getAttribute("parentId")) {
              isChecked=false;
              mygroup = document.getElementsByName(myobj.name);
              myobj=document.getElementById(myobj.getAttribute("parentId"));
              for(i=0;i<mygroup.length;i++)  
              { 
                   if (mygroup[i].checked)
                     isChecked=true;
              }
              if (isChecked) {
                    myobj.checked=true;
              } 
        }
}
function gridOnchangeCheckboxClick(thisid){
    var myobj = document.getElementById(thisid);
    myobj.checked=true;
    gridLineCheckboxClick(thisid);
}
/** 
 * Mandatory Function for Servlets with advanced editors
 * reads iframe and pushes content into textarea and value
 * to readout and write into sql
*/
function getEditorContent(feldname){
	var text = tinyMCE.activeEditor.contentDocument.body.innerHTML;
	text=text.replace("<br data-mce-bogus=\"1\">","");
	document.getElementById(feldname).value=text;
	
	return true;
}

function popupopen(path, name) {
	  var complementosNS4 = ""

		  var strHeight=500;
		  var strWidth=600;
		  var strTop=parseInt((screen.height - strHeight)/2);
		  var strLeft=parseInt((screen.width - strWidth)/2);
		  if (navigator.appName.indexOf("Netscape"))
		    complementosNS4 = "alwaysRaised=1, dependent=1, directories=0, hotkeys=0, menubar=0, ";
		  var complementos = complementosNS4 + "height=" + strHeight + ", width=" + strWidth + ", left=" + strLeft + ", top=" + strTop + ", screenX=" + strLeft + ", screenY=" + strTop + ", location=0, resizable=yes, scrollbars=yes, status=0, toolbar=0, titlebar=0";
		  if (typeof baseDirectory != "undefined") {
		    var winPopUp = window.open(baseDirectory + path, name, complementos);
		  } else {
		    // Deprecated in 2.50, the following code is only for compatibility
		    var winPopUp = window.open(baseDirectory + path, name, complementos);
		  }
		  if (winPopUp!=null) {
		    winPopUp.focus();
		    document.onunload = function(){winPopUp.close();};
		    document.onmousedown = function(){winPopUp.close();};
		  }
		  return winPopUp;
		}

		
function checkBrowser(){
  /**This wonderful Function gets the Browser from a User
   * it will be used as style Switcher --> if checkBrowser()=="Browser" {do something}  change width
   * returns the important browsernames --> Chrome IE Safari Opera and Firefox
   * customized by D.Heuduk
   */
  var nVer = navigator.appVersion;
var nAgt = navigator.userAgent;
var browserName  = navigator.appName;
var fullVersion  = ''+parseFloat(navigator.appVersion); 
var majorVersion = parseInt(navigator.appVersion,10);
var nameOffset,verOffset,ix;

// In Opera, the true version is after "Opera" or after "Version"
if ((verOffset=nAgt.indexOf("Opera"))!=-1) {
 browserName = "Opera";
 fullVersion = nAgt.substring(verOffset+6);
 if ((verOffset=nAgt.indexOf("Version"))!=-1) 
   fullVersion = nAgt.substring(verOffset+8);
}
// In MSIE, the true version is after "MSIE" in userAgent
else if ((verOffset=nAgt.indexOf("MSIE"))!=-1) {
 browserName = "IE";
 fullVersion = nAgt.substring(verOffset+5);
}
// In Chrome, the true version is after "Chrome" 
else if ((verOffset=nAgt.indexOf("Chrom"))!=-1) {
 browserName = "Chrome";
 fullVersion = nAgt.substring(verOffset+7);
}
// In Safari, the true version is after "Safari" or after "Version" 
else if ((verOffset=nAgt.indexOf("Safari"))!=-1) {
 browserName = "Safari";
 fullVersion = nAgt.substring(verOffset+7);
 if ((verOffset=nAgt.indexOf("Version"))!=-1) 
   fullVersion = nAgt.substring(verOffset+8);
}
// In Firefox, the true version is after "Firefox" 
else if ((verOffset=nAgt.indexOf("Firefox"))!=-1) {
 browserName = "Firefox";
 fullVersion = nAgt.substring(verOffset+8);
}
// In most other browsers, "name/version" is at the end of userAgent 
else if ( (nameOffset=nAgt.lastIndexOf(' ')+1) < 
          (verOffset=nAgt.lastIndexOf('/')) ) 
{
 browserName = nAgt.substring(nameOffset,verOffset);
 fullVersion = nAgt.substring(verOffset+1);
 if (browserName.toLowerCase()==browserName.toUpperCase()) {
  browserName = navigator.appName;
 }
}
// trim the fullVersion string at semicolon/space if present
if ((ix=fullVersion.indexOf(";"))!=-1)
   fullVersion=fullVersion.substring(0,ix);
if ((ix=fullVersion.indexOf(" "))!=-1)
   fullVersion=fullVersion.substring(0,ix);

majorVersion = parseInt(''+fullVersion,10);
if (isNaN(majorVersion)) {
 fullVersion  = ''+parseFloat(navigator.appVersion); 
 majorVersion = parseInt(navigator.appVersion,10);
}
return browserName}

function resourceplanadjust(){
  /** this piece of code uses the browsernames for style adjustments
   * it reduces the width for any browser but the firefox by 2px if this id exists
   * by D. Heuduk
   */
  var initw=parseInt(document.getElementById("xtTblConId").style.width);
  var calcw=initw-2;
  var exitw=calcw+'px';
  if (document.getElementById("xtTblConId")){
  if (checkBrowser()=="Firefox"){
  }
  else{
    document.getElementById("xtTblConId").style.width=exitw;
  }}else{} 
}

/*Function stashaction
 * Sets given Action which will be started in given time
 * USAGE: stashaction(function(){alert('abc')},3000) 
 */ 
var stashed;
function stashaction(action, intervall){
        delstash();
	stashed=setTimeout(action, intervall);
}
/*Function delstash
 * deletes former defined Action and Intervall
 * USAGE:delstash(stashed)
 */
function delstash(){
	 clearTimeout(stashed);
}

/*Function scrollToPosition
 * Moves the Scrollbar of a div object to position
 * 
 */
function scrollToPosition(objectid,top,left){
         document.getElementById(objectid).scrollLeft=left;
         document.getElementById(objectid).scrollTop=top;
}


	function PunktKomma(x) {
		TextAusgabe = x.toString();
		TextAusgabe = TextAusgabe.replace(".",",");
	document.getElementById('priceactual').value=TextAusgabe;

	}
/*Function getUrlparameter
 * This function is not needed until now, but will have to be used in the future to pass keys or any other data
 * from windows to popups or frames
 * 
 */
function getUrlParameter(par) {

var value='';
var UrlParameter = window.location.search;

if(UrlParameter != "") {
var i = UrlParameter.indexOf(par+"=");
if(i >= 0) {
i = i+par.length+1;
var k = UrlParameter.indexOf("&", i);
if(k < 0) {
k = UrlParameter.length;
}
value = UrlParameter.substring(i, k);
for(i=0; i<value.length; i++) {
if(value.charAt(i) == '+') {
value=value.substring(0, i)+" "+value.substring(i+1,value.length);
}
}
value=unescape(value);
}
}
return value;
}

/*Function setbPartnerNameDefaultCallOut
 * This function is special for business partner fast entry Popup
 * 
 */
function setbPartnerNameDefaultCallOut() {
  if (document.getElementById("name").value==null || document.getElementById("name").value=="") 
    document.getElementById("name").value="n/a";
  if (document.getElementById("value").value==null || document.getElementById("value").value=="") 
    document.getElementById("value").value="n/a";
    //setWindowEditing(true);
    logClick(document.getElementById('isSummary'));
}
/* Function to fill tinyMCE */
function fillthetinyMCE(which, what){
	which=which.substring(3,which.length);
	try {tinyMCE.get(which).setContent(what);}
	catch (ex) {}
}
function fillthetinyMCEdescription(what){
	tinyMCE.get('description').setContent(what);
}


/* Function to Enable App Content Manipulation */
function ozgridplus(fieldname, myid){
  var frm = document.frmMain;  
  var count = frm.elements["inp" + fieldname + myid].value;
  
  var countElement =  frm.elements["inp" + fieldname + myid];
  count++;
  countElement.value=count;
  
  sumselectedcontent();
}

function ozgridminus(fieldname, myid){
  var frm = document.frmMain;  
  var count = frm.elements["inp" + fieldname + myid].value;
  var countElement =  frm.elements["inp" + fieldname + myid];
  
  if (count>0){
  count--;
  countElement.value=count;}
  
  sumselectedcontent();
    
}

function toggleselected(myid){
  var count=document.getElementById("count" + myid);
  var odbtn = document.getElementById("orderbtn" + myid);
  // alert(parseFloat(count.value.replace(',', '.')));
  if (parseFloat(count.value.replace(',', '.'))==0) {
      count.value="1";
      odbtn.value="ENTFERNEN";
      if(! odbtn.classList.contains('ckd'))
      odbtn.className+=" ckd";
  }else{
      count.value="0";
      odbtn.value="AUSWAHL";
      odbtn.classList.remove('ckd');
  }
  var all_obj=getElementsByClassName("hpfr_input");
  for(i=0;i<all_obj.length;i++){  
     var guid =  all_obj[i].id.replace("count", "");
     //alert(guid + "---" +myid);
     if (guid!=myid) {
         if (document.getElementById("menu" + guid).value=="Y") {
             document.getElementById("count" + guid).value="0";
             odbtn = document.getElementById("orderbtn" + guid);
             odbtn.classList.remove('ckd');
             odbtn.value="AUSWAHL";
         }
     }    
  }
  sumselectedcontent();
}

function sumselectedcontent() { 
        var lines = "";
	var all_obj=getElementsByClassName("hpfr_input");
        var SumCalc=0;
        var isordered=document.getElementById("isOrdered").value;
        var isonload=document.getElementById("isOnLoad");
        for(i=0;i<all_obj.length;i++){  
            var guid =  all_obj[i].id.replace("count", "");
	    var priceobj=document.getElementById("hiddenprice" + guid);
            if (isaNumber(all_obj[i].value.replace(',', '.')) && isaNumber(priceobj.value.replace(',', '.'))){
             if (parseInt(all_obj[i].value.replace(',', '.'))>0) {
                if (lines != ""){lines=lines + "</div>";}
                var su=roundNumber(parseInt(all_obj[i].value.replace(',', '.')) * parseFloat(priceobj.value.replace(',', '.')),2);
                lines=lines + '<div class="hpfr_rdrs_mn">' + parseInt(all_obj[i].value.replace(',', '.')) + " x " +document.getElementById("descr"+ guid).value.substring(0,35) + '</div><div class="hpfr_rdrs_prc1">' + priceobj.value + " €</div>";
                SumCalc=SumCalc + su;
             }
            }
        }
        
        //alert(lines);
        var liste=document.getElementById("hpfr_rdrs_csn");
        liste.innerHTML=lines;
        if (SumCalc==0)
            ges='0,00 €';
        else 
            ges=SumCalc.toFixed(2).replace('.', ',') + " €";
        document.getElementById("hpfr_rdrs_prcttl").innerHTML=ges;
        var odbtn=document.getElementById("orderbtn");
        //alert(oldval);
        if ((SumCalc==0 && isordered=="Y") || (isonload.value=="Y" && isordered=="Y")) {
            if (defaultLang=="de_DE") odbtn.value="ABBESTELLEN"; else odbtn.value="CANCEL ORDER";
            odbtn.setAttribute("onclick","submitCommandForm('CANCEL', true, null,'GetMenu.html', 'appFrame', false, true);return false;");
        }else {
            if (defaultLang=="de_DE") odbtn.value="BESTELLUNG AUFGEBEN"; else odbtn.value="PLACE ORDER";
            odbtn.setAttribute("onclick","submitCommandForm('DONE', true, null,'GetMenu.html', 'appFrame', false, true);return false;");
        }
        //alert(ges);
        isonload.value="N";
        var isover=document.getElementById("isOver").value;
        if (isover=="Y") {
           // alert(odbtn.value);
            odbtn.value="BESTELLENDE ERREICHT";
            if(! odbtn.classList.contains('ckd')){
               odbtn.className+=" ckd";
            }
            odbtn.className+=" dsl";
            odbtn.disabled=true;
        }
return true;
}
	                
// Slideshow start

var slideIndex = 1;
showSlides(slideIndex);

// Next/previous controls
function plusSlides(n) {
  showSlides(slideIndex += n);
}

// Thumbnail image controls
function currentSlide(n) {
  showSlides(slideIndex = n);
}

function showSlides(n) {
  var i;
  var slides = document.getElementsByClassName("mySlides");
  var dots = document.getElementsByClassName("dot");
  if (n > slides.length) {slideIndex = 1} 
  if (n < 1) {slideIndex = slides.length}
  for (i = 0; i < slides.length; i++) {
      slides[i].style.display = "none"; 
  }
  for (i = 0; i < dots.length; i++) {
      dots[i].className = dots[i].className.replace(" active", "");
  }
  if(typeof slides[slideIndex-1] !== 'undefined'){
	  slides[slideIndex-1].style.display = "block";  
	  dots[slideIndex-1].className += " active";
	}
}

// Slideshow end


// Scanner CR abfangen
function crAction(event) {
  if ((event.key=="Enter") || (event.key=="Tab")) {
     executeWindowButton('linkButtonSave_New',true); 
  }
}
