package org.openz.view;
/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import org.openz.util.*;
import org.openz.view.templates.*;
import org.openbravo.data.FieldProvider;
import java.util.*;
import org.openz.model.*;

import javax.servlet.ServletException;

import org.openbravo.utils.FormatUtilities;
import org.openbravo.utils.Replace;
import org.openbravo.data.Sqlc;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;


public class Formhelper{
  private Vector <ComboDatastore> combodatastore;
  class ComboDatastore { 
    public String columnName;
    public String fpIdColumn;
    public FieldProvider[] data;
  }
  
  
  public Formhelper(){
    combodatastore=new Vector<ComboDatastore>();
  }
  
  public void addcombodata(FieldProvider[] fielddata, String fieldname, String fieldProviderIDColumn){
    ComboDatastore ds=new ComboDatastore();
    ds.data=fielddata;
    ds.columnName=fieldname;
    ds.fpIdColumn=fieldProviderIDColumn;
    combodatastore.add(ds);
  }
  
  private String idValue;
  private String keyFieldname;
 
  
  public  String prepareFieldgroup(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String refname, FieldProvider fielddata, Boolean auditfields)  throws Exception {
    String refid=GridData.getReferenceID(servlet, refname);
    script.addHiddenfield("inpadRefFieldcolumnId", refid);
    String refcolcount=FormhelperData.getReferenceColumns(servlet, refid);
    FormhelperData[] data = FormhelperData.select(servlet, refid);
    return fieldgroupProcessor(servlet,vars,script,data,fielddata,refcolcount,auditfields,false,false,"",true,null,false,false);
  }
  
  public  String prepareFieldgroup(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String refname, FieldProvider fielddata, Boolean auditfields,FieldProvider customfielddata)  throws Exception {
	    String refid=GridData.getReferenceID(servlet, refname);
	    script.addHiddenfield("inpadRefFieldcolumnId", refid);
	    String refcolcount=FormhelperData.getReferenceColumns(servlet, refid);
	    FormhelperData[] data = FormhelperData.select(servlet, refid);
	    return fieldgroupProcessor(servlet,vars,script,data,fielddata,refcolcount,auditfields,false,false,"",true,customfielddata,false,false);
	  }
  
  public  String prepareFieldgroup(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String refname, FieldProvider fielddata, Boolean auditfields,FieldProvider customfielddata,Boolean readonly, Boolean listbased)  throws Exception {
	    String refid=GridData.getReferenceID(servlet, refname);
	    script.addHiddenfield("inpadRefFieldcolumnId", refid);
	    String refcolcount=FormhelperData.getReferenceColumns(servlet, refid);
	    FormhelperData[] data = FormhelperData.select(servlet, refid);
	    return fieldgroupProcessor(servlet,vars,script,data,fielddata,refcolcount,auditfields,readonly,false,"",true,customfielddata,false,listbased);
	  }
  
  public  String prepareFieldgroupRO(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String refname, FieldProvider fielddata, Boolean auditfields,FieldProvider customfielddata)  throws Exception {
	    String refid=GridData.getReferenceID(servlet, refname);
	    script.addHiddenfield("inpadRefFieldcolumnId", refid);
	    String refcolcount=FormhelperData.getReferenceColumns(servlet, refid);
	    FormhelperData[] data = FormhelperData.select(servlet, refid);
	    return fieldgroupProcessor(servlet,vars,script,data,fielddata,refcolcount,auditfields,true,false,"",true,customfielddata,false,false);
	  }
  
  public  String prepareProcessParameters(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String adProcessId)  throws Exception { 
    String refcolcount="4";
    FormhelperData[] data = FormhelperData.selectProcessParameter(servlet, vars.getLanguage(), adProcessId);
    return fieldgroupProcessor(servlet,vars,script,data,null,refcolcount,false,false,false,"",false,null,true,false);
   }
  
  public  String prepareTabFields(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String adTabId, FieldProvider fielddata, Boolean auditfields)  throws Exception { 
    String refcolcount="6";
    FormhelperData[] data = FormhelperData.selectTabFields(servlet, vars.getLanguage(), adTabId);
    String strTableID=CrudOperationsData.getTableIDFromTab(servlet, adTabId);
    keyFieldname=CrudOperationsData.getIdColumnFromTable(servlet,  strTableID);
    idValue=fielddata.getField(keyFieldname);
    CustomFieldData customfields= new CustomFieldData();
    customfields.select(servlet,idValue , adTabId, keyFieldname);
    if (CrudOperationsData.isView(servlet, adTabId).equals("Y"))
      customfields=null;
    return fieldgroupProcessor(servlet,vars,script,data,fielddata,refcolcount,true,false,false,"",true,customfields,false,false);
   }
  
  public  String prepareTabFieldsRO(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String adTabId, FieldProvider fielddata, Boolean auditfields)  throws Exception { 
    String refcolcount="6";
    FormhelperData[] data = FormhelperData.selectTabFields(servlet, vars.getLanguage(), adTabId);
    String strTableID=CrudOperationsData.getTableIDFromTab(servlet, adTabId);
    keyFieldname=CrudOperationsData.getIdColumnFromTable(servlet,  strTableID);
    idValue=fielddata.getField(keyFieldname);
    CustomFieldData customfields= new CustomFieldData();
    customfields.select(servlet,idValue , adTabId, keyFieldname);
    if (CrudOperationsData.isView(servlet, adTabId).equals("Y"))
      customfields=null;
    return fieldgroupProcessor(servlet,vars,script,data,fielddata,refcolcount,true,true,false,"",true,customfields,false,false);
   }
  
  public  String prepareBuscadorFields(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String adTabId, String isdirectfilter)  throws Exception { 
    String refcolcount;
    
    String strWindowId = vars.getSessionValue("Buscador.inpWindowId");
    String strShowAudit = Utility.getContext(servlet, vars, "ShowAudit", strWindowId);
    FormhelperData[] data = FormhelperData.ad_selecttabBuscadorFields(servlet, vars.getLanguage(),adTabId,strShowAudit,isdirectfilter);
    if (isdirectfilter.equals("Y")) {
    	if (data.length*2 < 10)
    		refcolcount="10";
    	else if (data.length*2 >20)
    		refcolcount="20";
    	else
    		refcolcount=Integer.toString(data.length*2);
    }else
    	refcolcount="4";
    return fieldgroupProcessor(servlet,vars,script,data,null,refcolcount,true,false,true,adTabId,false,null,false,false);
   }
  
  
  public  String TabGetFirstFocusField(HttpSecureAppServlet servlet,String adTabId)  throws Exception { 
    
    return FormhelperData.getFocusField(servlet, adTabId);
   }
  public static boolean isTabReadOnly(HttpSecureAppServlet servlet,VariablesSecureApp vars,String tabId)  {
    try {
    String test=SelectBoxhelperData.isTabReadOnly(servlet, tabId);
    if (test.equals("RO"))
      return true;
    else
      return false;
    } catch (Exception ex) {
      return false;
    }
  }  
  
 
  private String fieldgroupProcessor(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,FormhelperData[] data,FieldProvider fielddata, String refcolcount,Boolean auditfields, Boolean globalreadonly,Boolean isBuscador,String buscadorTabId,Boolean createWithLinks, FieldProvider customfielddata, Boolean isProcess, Boolean isListBased)  throws Exception    {
      String fieldvalue1="";
      String onchangeevent="";
      String fieldvalue2="";
      String fieldgroupid="";
      int totalcols=0;
      StringBuilder strTableCells= new StringBuilder(250000);
      int colsused=1000;
      Boolean isfirst=true;
      String tooltip="";
      String strTableStructure=ConfigureTableStructure.doConfigure(servlet,vars,refcolcount,"100%" ,"Main");
      String textelement="";
    for (int i = 0; i < data.length; i++){
      // First get the Fields Value
      fieldvalue1="";
      fieldvalue2="";
      tooltip="";
      // Get Values from field Provider
      if (fielddata!=null){
        try {
          fieldvalue1=fielddata.getField(data[i].name);
          fieldvalue2=fielddata.getField(data[i].name2);
           // get Tooltip
          tooltip=fielddata.getField("TOOLTIP" + data[i].name);
          if (tooltip==null)
            if (! (data[i].template.equals("PASSWORD") || data[i].template.equals("CHECKBOX") || data[i].template.equals("PATTRIBUTE") || data[i].template.equals("MULTISELECTOR") || data[i].template.equals("POPUPSEARCH")|| data[i].template.equals("REFCOMBO")|| data[i].template.equals("IMAGE")|| data[i].template.equals("LISTSORTER")|| data[i].template.equals("LISTSORTER_SIMPLE")))
            tooltip=fieldvalue1;
          if (fieldvalue1==null) {
            if (customfielddata!=null && !servlet.getCommandtype().equals("NEW"))
              fieldvalue1=customfielddata.getField(data[i].name);
            if (customfielddata!=null && servlet.getCommandtype().equals("NEW"))
              fieldvalue1=FormDisplayLogic.getFieldDefaultValue(servlet, vars, data[i].adRefFieldcolumnId);
            if (fieldvalue1==null) 
              fieldvalue1="";
          }
          if (fieldvalue2==null)
            fieldvalue2="";
        } catch (Exception e) {
          throw new Exception("The Field " + data[i].name + " is not implemented in the model. You have to compile it into the model.");
        }
      } 
      //Colorizit
      
      String datastyle=data[i].style;
      if (datastyle.startsWith("@SQL="))
        datastyle=FormDisplayLogic.getSQLValueByStatement(servlet, vars, data[i].style,idValue,keyFieldname);
      // Implements the Display Logic.
      Boolean readonly = true;
      if (isBuscador)
        readonly = false;
      Boolean newfieldgroup = false;
      String visblelogic;
      if (isBuscador)
        visblelogic =FormDisplayLogic.fieldVisibleLogic(servlet, vars, script, data[i].adRefFieldcolumnId,fieldvalue1,false);
      else
        visblelogic =FormDisplayLogic.fieldVisibleLogic(servlet, vars, script, data[i].adRefFieldcolumnId,fieldvalue1,true);
      if (! globalreadonly && ! visblelogic.equals("HIDDEN") && ! isBuscador) {
         readonly =FormDisplayLogic.fieldReadOnlyLogic(servlet, vars, script, data[i].adRefFieldcolumnId,true);
      }
      Boolean required;
      if (isBuscador || readonly || visblelogic.equals("HIDDEN"))
        required= false;
      else
        required= FormDisplayLogic.fieldMandantoryLogic(servlet, vars, script, data[i].adRefFieldcolumnId,true);
      
      if (visblelogic.equals("DONOTGENERATE")) 
        data[i].template="DONOTGENERATE";
      // Used for Buscador
      if (isBuscador && ! data[i].template.equals("DONOTGENERATE")){
        String value=vars.getSessionValue(buscadorTabId + "|param" + data[i].name);
        if (data[i].template.equals("TEXT") && value.isEmpty())
          value="%";
        if (servlet.getWindowId().isEmpty())
        	vars.setSessionValue(servlet.getClass().getName() + "|" + data[i].name, value);
        else
        	vars.setSessionValue(servlet.getWindowId() + "|" + data[i].name, value);
        script.addBuscador(servlet, vars, data[i].name, data[i].template);
      }
      // Genarate a new Table ROW on the Form, evtl. with fieldgroup
      if (!data[i].template.equals("DONOTGENERATE") &&
          (colsused >= Integer.parseInt(refcolcount) || data[i].islinebreak.equals("Y") || isfirst)){
        colsused=0;
        // get the fieldgroup
        if (! data[i].fieldgroupid.isEmpty() && ! data[i].fieldgroupid.equals(fieldgroupid)  ) {
          fieldgroupid=data[i].fieldgroupid;
          newfieldgroup=true;
          if (! isfirst ) 
            strTableCells=strTableCells.append("</tr>");
          if (FormhelperData.isFieldgrouphidden(servlet, fieldgroupid).equals("Y"))
            script.addOnload("zeige('" + data[i].fieldgroupid + "');");
          strTableCells=strTableCells.append(ConfigureFieldgroup.doConfigure(servlet,vars,script,FormhelperData.getFieldgroupname(servlet, fieldgroupid),refcolcount, LocalizationUtils.getFieldgroupText(servlet, fieldgroupid, vars.getLanguage()),fieldgroupid));
        } else
          newfieldgroup=false;
        if (! isfirst && ! newfieldgroup)
          strTableCells=strTableCells.append("</tr>");
        if (! fieldgroupid.isEmpty())
          strTableCells=strTableCells.append("<tr style=\"display: table-row;\" class=\"" + fieldgroupid + "\">");
        else
          strTableCells=strTableCells.append("<tr>");
        isfirst=false;
      } // Table ROW
      //
      // Get the Element or the Transalation Text
      if (data[i].translation.isEmpty())
        textelement=data[i].adElementId;
      else
        textelement=data[i].translation;
      onchangeevent= data[i].onchangeevent==null ? "" : data[i].onchangeevent;
      if (FormDisplayLogic.triggersComboReload(servlet,data[i].adRefFieldcolumnId ))
          onchangeevent="reloadCombos(this.name);" + onchangeevent  ;
      
      if (fielddata==null) {
        if (!servlet.getCommandtype().equals("NEW") || isBuscador){
          // If no data found, maybe there is something stored in the session....
          // Used esp. for setting Filters
          if (!servlet.getWindowId().equals(""))
            fieldvalue1=vars.getSessionValue(servlet.getWindowId() + "|" + data[i].name);
          else
            fieldvalue1=vars.getSessionValue(servlet.getClass().getName() + "|" + data[i].name);
        }
        if ((servlet.getCommandtype().equals("NEW") || isProcess) && !  isBuscador)
          // Get the Default Value
          fieldvalue1=FormDisplayLogic.getFieldDefaultValue(servlet, vars, data[i].adRefFieldcolumnId);
      }
      // Fires Callout on NEW 
      /*
      if (! data[i].template.equals("DONOTGENERATE") && servlet.getCommandtype().equals("NEW") && ! readonly && !fieldvalue1.isEmpty()) {
        OBError oe = vars.getMessage(servlet.getTabId());
        if (oe==null)
          script.addOnload("updateOnChange(frm.inp" + Sqlc.TransformaNombreColumna(data[i].name) + ");");
      }
      */
       // script.addOnload("frm." + Sqlc.TransformaNombreColumna(data[i].name) + ".onchange();");
      // Implements The Fields Structure
      totalcols=Integer.parseInt(data[i].colstotal)+Integer.parseInt(data[i].leadingemptycols);
      colsused=colsused+totalcols;
      if (data[i].template.equals("IDFIELD")){
        script.addHiddenfield("inp" + Sqlc.TransformaNombreColumna(data[i].name),fieldvalue1);
        script.addHiddenfield("inpKeyName","inp" + Sqlc.TransformaNombreColumna(data[i].name));
      }
      
      if (data[i].template.equals("BUTTON") && ! isListBased){
        strTableCells=strTableCells.append(ConfigureButton.doConfigure(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), readonly, data[i].buttonclass, data[i].referenceurl.replace("@PATH@", servlet.strDireccion), fieldvalue1,textelement, onchangeevent));
      }
      if (data[i].template.equals("CHECKBOX")){
        strTableCells=strTableCells.append(ConfigureCheckbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),  onchangeevent, "Y",fieldvalue1.equals("Y") ? true : false, readonly, tooltip,textelement,isListBased));
      }
      if (data[i].template.equals("PATTRIBUTE")){
        strTableCells=strTableCells.append(ConfigurePAttribute.doConfigure(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly,  fieldvalue1, onchangeevent,tooltip,textelement,isListBased));
      }
      if (data[i].template.equals("CAROUSEL")){
          strTableCells=strTableCells.append(ConfigureCarusel.doConfigure(servlet, vars,script,fieldvalue1,data,fielddata ));
        }
      if (data[i].template.equals("DATE")){
        strTableCells=strTableCells.append(ConfigureDatebox.doConfigure(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly,  fieldvalue1, onchangeevent,tooltip,textelement,datastyle,isListBased));
        if (data[i].referenceurl!= null && !data[i].referenceurl.isEmpty())
        	script.addSearchButtonConfigTextField(servlet, data[i].name, data[i].referenceurl);
      }
      if (data[i].template.equals("TIME")){                                                                                                                                                                                                                                                                                                    
        strTableCells=strTableCells.append(ConfigureTimebox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, onchangeevent ,fieldvalue1,tooltip,textelement,isListBased));
      }
      if (data[i].template.equals("DECIMAL") || data[i].template.equals("EURO") || data[i].template.equals("INTEGER") || data[i].template.equals("PRICE") ||
    		  data[i].template.equals("SQLFIELDDECIMAL") || data[i].template.equals("SQLFIELDEURO") || data[i].template.equals("SQLFIELDINTEGER") || data[i].template.equals("SQLFIELDPRICE")){
    	if ( data[i].template.startsWith("SQLFIELD") && ! isBuscador)  {
    		fieldvalue1=FormDisplayLogic.getSQLField(servlet,vars,data[i].adRefFieldcolumnId,idValue,keyFieldname);
    		readonly=true;
    		required=false;
    	}
        strTableCells=strTableCells.append(ConfigureNumberbox.doConfigure(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), Integer.parseInt(data[i].maxlength), required, readonly, onchangeevent,data[i].template, fieldvalue1, tooltip,textelement,datastyle,isListBased,isBuscador,Integer.parseInt(refcolcount)));
      }
      if (data[i].template.equals("FIELDGROUP")){
        strTableCells=strTableCells.append(ConfigureFieldgroup.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),data[i].colstotal, "",""));
      }
      
      if (data[i].template.equals("MULTISELECTOR")){
        FieldProvider[] fp=null;
        String fpidcol="ID";
        
        
        String refName=GridData.getReferenceName(servlet, data[i].fieldreference);
        addselectorhiddenfields(servlet,script,data[i].fieldreference);
        strTableCells=strTableCells.append(ConfigureMultiSelector.doConfigure(servlet, vars,script, data[i].name, Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly,  refName,fieldvalue1,tooltip,textelement,onchangeevent));
      }
      if (data[i].template.equals("POPUPSEARCH")){
        String refName=GridData.getReferenceName(servlet, data[i].fieldreference);
        addselectorhiddenfields(servlet,script,data[i].fieldreference);
        String fname=Sqlc.TransformaNombreColumna(data[i].name) ;
        if (createWithLinks)
          strTableCells=strTableCells.append(ConfigurePopupSelectBox.doConfigureLink(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly,  refName, fieldvalue1,  onchangeevent, tooltip,data[i].fieldreference,textelement,isListBased,isBuscador));
        else
          strTableCells=strTableCells.append(ConfigurePopupSelectBox.doConfigureNoLink(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly,  refName, fieldvalue1,  onchangeevent, tooltip,data[i].fieldreference,textelement,isListBased,isBuscador,Integer.parseInt(refcolcount)));
        if (isProcess) {
          Replace.replace(strTableCells, "'inp" +fname + "_DES', document." + fname + ".inp" + fname + "_DES.value,","");
          Replace.replace(strTableCells, "'inpadOrgId', document.frmMain.inpadOrgId.value);","'inpadOrgId', inputValue(document.frmMain.inpadOrgId));");
        }
        if (isBuscador && fieldvalue1.isEmpty()) {
        	String value=vars.getSessionValue(buscadorTabId + "|param" + data[i].name + "_DES");
        	if (value.isEmpty()) value="%";
        	Replace.replace(strTableCells, "id=\"" + fname + "_DES\" value=\"\"" , "id=\"" + fname + "_DES\" value=\"" + value +"\"" );
        }
      }
      if (data[i].template.equals("RADIOBUTTON")){
        FormhelperData[] datar = FormhelperData.selectRadiogroup(servlet,data[i].adRefFieldcolumnId);
        for (int k = 0; k < Integer.parseInt(data[i].leadingemptycols); k++) {
          strTableCells=strTableCells.append("<td class=\"leadingemptycol\"></td>");
        }
        Boolean checked=false;
        String value="";
        for (int j = 0; j < datar.length; j++){
          value=fieldvalue1;
          if (value.equals(datar[j].name))
            checked=true;
          else
            checked=false;
          strTableCells=strTableCells.append(ConfigureRadioButton.doConfigure(servlet, vars,script,datar[j].name, Sqlc.TransformaNombreColumna(data[i].name), checked, readonly, onchangeevent, "" ,textelement));
        } 
      }
      if (data[i].template.equals("REFCOMBO")){
        FieldProvider[] fp=null;
        String fpidcol="ID";
        for (int j = 0; j < combodatastore.size(); j++){
          if (combodatastore.elementAt(j).columnName.equals(data[i].name)){
            fp= combodatastore.elementAt(j).data;
            if (combodatastore.elementAt(j).fpIdColumn!=null)
              fpidcol=combodatastore.elementAt(j).fpIdColumn;
          }
        }
        String tableID="";
        if (fp==null && !data[i].fieldreference.isEmpty()) {
          fp=SelectBoxhelper.getReferenceDataByRefName(servlet, vars, GridData.getReferenceName(servlet, data[i].fieldreference),data[i].adValRuleId,fielddata,fieldvalue1,readonly);
          tableID=SelectBoxhelperData.getReferenceTableIDByRefID(servlet, data[i].fieldreference);
        }
        if (fp==null && !data[i].adTableId.isEmpty()) {
          fp=SelectBoxhelper.getReferenceDataByRefName(servlet, vars, GridData.getKeyColumnbyTable(servlet, data[i].adTableId),data[i].adValRuleId,fielddata,fieldvalue1,readonly);
          tableID=data[i].adTableId;
        }
        if (createWithLinks)
          strTableCells=strTableCells.append(ConfigureSelectBox.doConfigureLink(servlet, vars, script,  Sqlc.TransformaNombreColumna(data[i].name), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly, onchangeevent, fieldvalue1, fp, fpidcol,tooltip,data[i].includesemptyitem.equals("Y") ? true : false, data[i].fieldreference , tableID,textelement,isListBased,datastyle));
        else
          strTableCells=strTableCells.append(ConfigureSelectBox.doConfigureNoLink(servlet, vars, script,  Sqlc.TransformaNombreColumna(data[i].name), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly, onchangeevent, fieldvalue1, fp, fpidcol,tooltip,data[i].includesemptyitem.equals("Y") ? true : false, data[i].fieldreference , tableID,textelement,isListBased,datastyle));
      }
      if (data[i].template.equals("LISTSORTER")){
        FieldProvider[] fp1=null;
        FieldProvider[] fp2=null;
        String fpidcol1="ID";
        String fpidcol2="ID";
        for (int j = 0; j < combodatastore.size(); j++){
          if (combodatastore.elementAt(j).columnName.equals(data[i].name)){
            fp1= combodatastore.elementAt(j).data;
            if (combodatastore.elementAt(j).fpIdColumn!=null)
              fpidcol1=combodatastore.elementAt(j).fpIdColumn;
          }
          if (combodatastore.elementAt(j).columnName.equals(data[i].name2)){
            fp2= combodatastore.elementAt(j).data;
            if (combodatastore.elementAt(j).fpIdColumn!=null)
              fpidcol2=combodatastore.elementAt(j).fpIdColumn;
          }
        }
        
        strTableCells=strTableCells.append(ConfigureListSorter.doConfigure(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name), Sqlc.TransformaNombreColumna(data[i].name2), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), fieldvalue1, fieldvalue2, fp1,fpidcol1, fp2,fpidcol2, readonly, "",tooltip,textelement));
      }
      if (data[i].template.equals("LISTSORTER_SIMPLE")){
        FieldProvider[] fp1=null;
        FieldProvider[] fp2=null;
        String fpidcol1="ID";
        String fpidcol2="ID";
        for (int j = 0; j < combodatastore.size(); j++){
          if (combodatastore.elementAt(j).columnName.equals(data[i].name)){
            fp1= combodatastore.elementAt(j).data;
            if (combodatastore.elementAt(j).fpIdColumn!=null)
              fpidcol1=combodatastore.elementAt(j).fpIdColumn;
          }
          if (combodatastore.elementAt(j).columnName.equals(data[i].name2)){
            fp2= combodatastore.elementAt(j).data;
            if (combodatastore.elementAt(j).fpIdColumn!=null)
              fpidcol2=combodatastore.elementAt(j).fpIdColumn;
          }
        }
        strTableCells=strTableCells.append(ConfigureListSorterSimple.doConfigure(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name), Sqlc.TransformaNombreColumna(data[i].name2), Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), fieldvalue1, fieldvalue2, fp1,fpidcol1, fp2,fpidcol2, readonly, "",tooltip,textelement));
      }
      if (data[i].template.equals("TEXT") || (data[i].template.equals("SQLFIELD") &&  isBuscador) || data[i].template.equals("DATETIME")){
        strTableCells=strTableCells.append(ConfigureTextbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, data[i].template.equals("DATETIME") ? true : readonly, onchangeevent ,fieldvalue1,tooltip,textelement, datastyle,isListBased));
        if (data[i].referenceurl!= null && !data[i].referenceurl.isEmpty())
        	script.addSearchButtonConfigTextField(servlet, data[i].name, data[i].referenceurl);
      }
      if (data[i].template.equals("TEXT_NOLABEL")) {
    	  strTableCells=strTableCells.append(ConfigureTextbox.doConfigureNoLabel(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, data[i].template.equals("DATETIME") ? true : readonly, onchangeevent ,fieldvalue1,tooltip,textelement, datastyle,isListBased));
      }
      if (data[i].template.equals("SQLFIELD") && ! isBuscador){
        fieldvalue1=FormDisplayLogic.getSQLField(servlet,vars,data[i].adRefFieldcolumnId,idValue,keyFieldname);
        strTableCells=strTableCells.append(ConfigureTextbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, true, onchangeevent ,fieldvalue1,tooltip,textelement, datastyle,isListBased));
      }
      if (data[i].template.equals("PASSWORDTEXT")){
        strTableCells=strTableCells.append(ConfigureTextboxPwd.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, onchangeevent ,fieldvalue1,tooltip,textelement));
      }
      if (data[i].template.equals("FILE")){
        strTableCells=strTableCells.append(ConfigureFileUpload.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),tooltip,textelement));
        script.setMultipart(true);
        script.addHiddenfieldWithID("Command", "");
      }
      if (data[i].template.equals("PASSWORD")){
        strTableCells=strTableCells.append(ConfigurePassword.doConfigure(servlet, vars,script, data[i].name,Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal), required, readonly,  fieldvalue1, onchangeevent,tooltip,textelement));
      }
      if (data[i].template.equals("LABEL")){
        strTableCells=strTableCells.append(ConfigureLabel.doConfigure(servlet, vars, Sqlc.TransformaNombreColumna(data[i].name), "Label_ContentCell",fieldvalue1,textelement,Integer.parseInt(data[i].colstotal),datastyle));
      }
      if (data[i].template.equals("IMAGE")){
    	  if (isListBased)
    		  strTableCells=strTableCells.append(ConfigureImage.doConfigureGrid(servlet,vars,script,data[i].name, Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, fieldvalue1,null,tooltip, null));
    	  else
    		  strTableCells=strTableCells.append(ConfigureImage.doConfigure(servlet,vars,script,data[i].name,Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, onchangeevent ,fieldvalue1,tooltip, datastyle,textelement));
      }
      if (isListBased && (data[i].template.equals("NOEDIT_TEXTBOX")||data[i].template.equals("URL")||data[i].template.equals("TEXTAREA_EDIT_SIMPLE")||data[i].template.equals("TEXTAREA_EDIT_ADV"))) {
    	  strTableCells=strTableCells.append(ConfigureTextbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, onchangeevent ,fieldvalue1,tooltip,textelement, datastyle,isListBased));
      } else {
	      if (data[i].template.equals("NOEDIT_TEXTBOX")){
	          strTableCells=strTableCells.append(ConfigureTextarea.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, "" ,fieldvalue1,tooltip, datastyle,textelement));
	        }
	      if (data[i].template.equals("URL")){
	        strTableCells=strTableCells.append(ConfigureUrlbox.doConfigure(servlet, vars,script, Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength), required, readonly,  fieldvalue1, onchangeevent,tooltip,textelement));
	      }
	      if (data[i].template.equals("TEXTAREA_EDIT_SIMPLE")){
	        strTableCells=strTableCells.append(ConfigureTextareaEditableSimple.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, onchangeevent ,fieldvalue1,tooltip, datastyle,textelement));
	      }
	      if (data[i].template.equals("TEXTAREA_EDIT_ADV")){
	        strTableCells=strTableCells.append(ConfigureTextareaEditableAdvanced.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna(data[i].name),Integer.parseInt(data[i].leadingemptycols), Integer.parseInt(data[i].colstotal),Integer.parseInt(data[i].maxlength),required, readonly, onchangeevent ,fieldvalue1,tooltip, datastyle,textelement));
	      }
 
     }
     if (data[i].template.equals("EMPTYLINE")){
        if (! isfirst)
          strTableCells=strTableCells.append("</tr>");
        strTableCells=strTableCells.append("<tr><td class=\"emptyrow\">&nbsp;</td></tr>\n<tr>");
      }
     FieldProvider[] fdata=new FieldProvider[1];
     fdata[0]=fielddata;
     if ((data[i].template.equals("NESTEDGRID") || data[i].template.equals("NESTEDFIELDGROUP")) && ! data[i].defaultvalue.isEmpty()){
    	 fdata=FormDisplayLogic.getSQLStatementData(servlet, vars, data[i].defaultvalue,idValue,keyFieldname);
     }
     if (data[i].template.equals("NESTEDGRID")) {
    	 EditableGrid nestedGrid= new EditableGrid(data[i].name, vars, servlet,isListBased);
    	 String strGrid=nestedGrid.printGrid(servlet, vars, script, fdata);
    	 String sty= data[i].style.isEmpty() ? "width:100%" : data[i].style;
    	 strGrid=Replace.replace(strGrid,"<TABLE cellspacing=\"0\" class=\"DataGrid_Table","<TABLE style=\"" + sty +"\" cellspacing=\"0\" class=\"DataGrid_Table");
    	 StringBuilder strItem=ConfigureListBasedEntry.doConfigure(servlet, vars, script, Sqlc.TransformaNombreColumna(data[i].name), null, strGrid, true, Integer.parseInt(data[i].colstotal)+1, null,null);
         strTableCells=strTableCells.append(strItem);
     }
     if (data[i].template.equals("NESTEDFIELDGROUP")) {
    	 Formhelper fh=new Formhelper();
    	 String strNested=fh.prepareFieldgroup(servlet,vars,script,data[i].name, fdata[0], false,customfielddata,readonly, isListBased) ; 	
    	 strNested=Replace.replace(strNested,"<table cellspacing=\"0\" cellpadding=\"0\" class=\"Form_Table\"","<table cellspacing=\"0\" cellpadding=\"0\" style=\"width:100%\"");
    	 StringBuilder strItem=ConfigureListBasedEntry.doConfigure(servlet, vars, script, Sqlc.TransformaNombreColumna(data[i].name), null, strNested, true, Integer.parseInt(data[i].colstotal)+1, null,null);
         strTableCells=strTableCells.append(strItem);
     }
    }
    if (auditfields && fielddata!=null){
      strTableCells=strTableCells.append(ConfigureFieldgroup.doConfigure(servlet,vars,script,"audit",refcolcount, "Audit",""));
      strTableCells=strTableCells.append("<tr class=\"auditfieldclass\" style=\"display: table-row;\">");
      strTableCells=strTableCells.append(ConfigureTextbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna("created"),0, 2,250,false, true, "" ,fielddata.getField("created"),"","","",isListBased));
      strTableCells=strTableCells.append(ConfigureTextbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna("createdby"),1, 2,250,false, true, "" ,fielddata.getField("createdbyr"),"","","",isListBased));
      strTableCells=strTableCells.append("</tr><tr class=\"auditfieldclass2\" style=\"display: table-row;\">");
      strTableCells=strTableCells.append(ConfigureTextbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna("updated"),0, 2,250,false, true, "" ,fielddata.getField("updated"),"","","",isListBased));
      strTableCells=strTableCells.append(ConfigureTextbox.doConfigure(servlet,vars,script,Sqlc.TransformaNombreColumna("updatedby"),1, 2,250,false, true, "" ,fielddata.getField("updatedbyr"),"","","",isListBased));
      String logic="if (strShowAudit == 'Y'){\n"; 
      logic=logic +"         fieldDisplaySettings('audit', true);\n";
      logic=logic +"         setclassdidplaymode(\"auditfieldclass\",true);\n";
      logic=logic +"         setclassdidplaymode(\"auditfieldclass2\",true);\n";
      logic=logic+"     } else {\n";
      
      logic=logic +"         fieldDisplaySettings('audit', false);";
      logic=logic +"         setclassdidplaymode(\"auditfieldclass\",false);\n";
      logic=logic +"         setclassdidplaymode(\"auditfieldclass2\",false);\n";
      logic=logic +"}\n";
      script.addDisplayLogic(logic);

    }
    if (!strTableCells.toString().isEmpty()) {
        strTableCells=strTableCells.append("</tr>");
        strTableStructure = strTableStructure.replace("@CONTENT@", strTableCells.toString());
        return strTableStructure;   
    } else
      return "";
  }
  // End Of Fieldgroup Procesor
  
  
  private void addselectorhiddenfields(HttpSecureAppServlet servlet,Scripthelper script,String selectorRefID)  throws Exception    {
    FormhelperData[] datar = FormhelperData.getHiddenSelectorColumns(servlet, selectorRefID);
    for (int i=0;i<datar.length; i++){
      String hiddefield="inp" + Sqlc.TransformaNombreColumna(datar[i].selectorcolumnname) + datar[i].selectorcolumnsuffix;
      script.addHiddenfield(hiddefield, "");
    }
  }
  public static String getTabAccessLevel(HttpSecureAppServlet servlet,VariablesSecureApp vars,String tabId) throws Exception {
    return SelectBoxhelperData.getTabAccessLevel(servlet, tabId);
  }  
  public static String prepareToolbar(HttpSecureAppServlet servlet,VariablesSecureApp vars,String toolbarID) throws Exception{
    
    String msg="";
    String toolbar="<table class=\"Main_ContentPane_ToolBar Main_ToolBar_bg\" id=\"tdToolBar\"><tr>\n";
    final String directory= servlet.strBasePath; 
    String sep="<td class=\"Main_ToolBar_Separator_cell\" ><img src=\"../web/images/blank.gif\" class=\"Main_ToolBar_Separator\"></td>\n";
    String linkeditems=FileUtils.readFile("ToolbarLinkedItems.xml",directory + "/src-loc/design/org/openz/view/templates/");
    String sql = "SELECT toolbaritem,codesnippet,message from ad_toolbaritems where ad_toolbar_id = '" + toolbarID + "' order by seqno";
    Connection conn = servlet.getConnection();
    Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,ResultSet.CONCUR_READ_ONLY);
    ResultSet res = stmt.executeQuery(sql);
    while (res.next()) {
      if (res.getString("toolbaritem").equals("SEPERATOR"))
        toolbar=toolbar+sep;
      if (res.getString("toolbaritem").equals("LINKEDITEMS"))
        toolbar=toolbar+linkeditems;
      if (!res.getString("toolbaritem").equals("SEPERATOR") && !res.getString("toolbaritem").equals("LINKEDITEMS")) {
        msg=LocalizationUtils.getMessageText(servlet,res.getString("message") , vars.getLanguage());
        toolbar=toolbar+Replace.replace(res.getString("codesnippet"), "@MESSAGE@", msg);
      }
    }
    conn.close();
    return toolbar + " </tr>\n</table>";
  }
  
  public String prepareInfobar(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String infomessage, String additionalstyle) throws Exception{
      
        String infobar=ConfigureInfobar.doConfigure(servlet,vars,script, infomessage, additionalstyle);
        return infobar;
      }
  /**
   * Adds a DIV to the APP Frame
   * 
   * @param formcontent (APP Frame)
   * @param divhtml (Content for the new DIV) 
   * @param id (Id of DIV)
   * @param strTop
   * @param strLeft
   * @param strWitdh
   * @param strHeight
   * @param strstyle (Overrides top.. with own style)
   */
  public static String addDIV(String formcontent,String divhtml, String id,String strTop, String strLeft,String strWitdh, String strHeight,String strstyle) throws Exception{
	  String mstyle="";
	  String rdiv="<div id=\"" + id + "\" @STYLE@> @DIVHTML@ </div>";
	  if (!FormatUtils.isNix(strstyle))
		  mstyle=strstyle;
	  if (!FormatUtils.isNix(strTop)&& !FormatUtils.isNix(strLeft)&& !FormatUtils.isNix(strWitdh)&& !FormatUtils.isNix(strHeight))
		  mstyle="style=\"position: fixed; overflow: auto; top: "+ strTop +"; left: "+strLeft +  "; width: "+ strWitdh +"; height: "+strHeight +";\"";
	  rdiv=Replace.replace(rdiv,"@STYLE@", mstyle);	  
	  rdiv=Replace.replace(rdiv,"@DIVHTML@", divhtml);	  
      String strcontent=Replace.replace(formcontent, "</FORM>","</FORM>" + rdiv  );	  
      return strcontent;
  }
  
  public void setKeyFieldname(String _keyfieldname){
	  keyFieldname=_keyfieldname;
  }
  public void setIdValue(String _idvalue){
	  idValue=_idvalue;
  }
 
 }
