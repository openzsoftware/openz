
  
CREATE OR REPLACE FUNCTION ad_datatype_guiengine_template_mapping(p_datatype_id varchar)
  RETURNS varchar AS
$BODY$ DECLARE 
    v_return varchar;
begin
     -- mapping
     /*
     select name,value from ad_ref_list where ad_reference_id=(select ad_reference_id from ad_reference where name='Field Template types');
         name         |        value               ad_reference_id          
----------------------+----------------------
 RADIOBUTTON          | RADIOBUTTON
 NOEDIT_TEXTBOX       | NOEDIT_TEXTBOX
 EURO                 | EURO                           | Amount           | 12
 CHECKBOX             | CHECKBOX                       | YesNo            | 20
 LISTSORTER           | LISTSORTER
 FIELDGROUP           | FIELDGROUP
 URL                  | URL                            | Link             | 800101
 TEXTAREA_EDIT_SIMPLE | TEXTAREA_EDIT_SIMPLE           | Text             | 14
 INTEGER              | INTEGER                        | Integer          | 11
 MULTISELECTOR        | MULTISELECTOR
 POPUPSEARCH          | POPUPSEARCH                    | Search           | 30
 TEXT                 | TEXT                           | String           | 10
 EMPTYLINE            | EMPTYLINE
 REFCOMBO             | REFCOMBO                       TableDir,Table,List 17, 18, 19
 LISTSORTER_SIMPLE    | LISTSORTER_SIMPLE
 BUTTON               | BUTTON                         | Button           | 28
 PRICE                | PRICE                          | Price            | 800008
 DATE                 | DATE                           | Date             | 15
 IMAGE                | IMAGE                          | Image BLOB       | 4AA6C3BE9D3B4D84A3B80489505A23E5
 LABEL                | LABEL
 TEXTAREA_EDIT_ADV    | TEXTAREA_EDIT_ADV
 DECIMAL              | DECIMAL                        | Quantity         | 29
 Binary                                                                   | 23
 ID                                                                       | 13
 
(22 rows)
*/
  select  case  p_datatype_id when '12'      then 'EURO' 
                              when '20'      then 'CHECKBOX'
                              when '800101'  then 'URL'
                              when '14'      then 'NOEDIT_TEXTBOX'
                              when '11'     then  'INTEGER'
                              when '30'     then  'POPUPSEARCH'
                              when '10'     then  'TEXT'
                              when '28'     then 'BUTTON'
                              when '800008' then 'PRICE'
                              when '15'     then 'DATE'
                              when '4AA6C3BE9D3B4D84A3B80489505A23E5' then 'IMAGE'
                              when '22' then 'DECIMAL'
                              when '17' then 'REFCOMBO'
                              when '18' then 'REFCOMBO'
                              when '19' then 'REFCOMBO'
                              when '13' then 'IDFIELD'
                              when '35' then 'PATTRIBUTE'
                              when '24' then 'TIME'
                              when '16' then 'DATETIME'
                              
                              
          end into v_return;
  return v_return;
end;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
CREATE OR REPLACE FUNCTION ad_guiengine_reference_mapping(p_AD_Reference_Value_ID varchar,p_ad_table_id varchar, p_template varchar)
  RETURNS varchar AS
$BODY$ DECLARE 
    v_return varchar;
    v_count numeric;
begin
/*
  select  case  p_datatype_id when '12'      then 'EURO' 
                              when '20'      then 'CHECKBOX'
                              when '800101'  then 'URL'
                              when '14'      then 'NOEDIT_TEXTBOX'
                              when '11'     then  'INTEGER'
                              when '30'     then  'POPUPSEARCH'
                              when '10'     then  'TEXT'
                              when '28'     then 'BUTTON'
                              when '800008' then 'PRICE'
                              when '15'     then 'DATE'
                              when '4AA6C3BE9D3B4D84A3B80489505A23E5' then 'IMAGE'
                              when '22' then 'DECIMAL'
                              when '17' then 'REFCOMBO' -- List
                              when '18' then 'REFCOMBO' -- Table
                              when '19' then 'REFCOMBO' -- Table dir
                              when '13' then 'IDFIELD'
                              when '35' then 'PATTRIBUTE'
                              when '24' then 'TIME'
                              
                              
          end into v_return;
*/
-- SEARCH
   if p_template='POPUPSEARCH' then
        select count(*) into v_count from ad_reference where AD_Reference_id=p_AD_Reference_Value_ID and validationtype='S';
        if v_count>0 then 
           v_return:='30';
        end if;
   end if;
-- TABLE DIRECT
   if p_template='REFCOMBO' then
        select count(*) into v_count from ad_table where ad_table_id=p_ad_table_id;
        if v_count>0 or (p_AD_Reference_Value_ID='19' and p_ad_table_id is null) then 
           v_return:='19';
        end if;
   end if;
-- TABLE 
   if p_template='REFCOMBO' then
        select count(*) into v_count from ad_reference where  AD_Reference_id=p_AD_Reference_Value_ID and validationtype='T';
        if v_count>0 then 
           v_return:='18';
        end if;
   end if;
-- List
   if p_template='REFCOMBO' then
        select count(*) into v_count from ad_reference where AD_Reference_id=p_AD_Reference_Value_ID and validationtype='L';
        if v_count>0 then 
           v_return:='17';
        end if;
   end if;
-- OTHER
  if v_return is null then
    select  case p_template when 'EURO'  then '12' 
                              when 'CHECKBOX'      then '20'
                              when  'URL' then '800101'
                              when 'NOEDIT_TEXTBOX'      then '14'
                              when 'INTEGER'     then  '11'
                              when 'TEXT'   then  '10'  
                              when 'BUTTON'     then '28'
                              when 'PRICE' then '800008'
                              when  'DATE'    then '15'
                              when 'IMAGE' then '4AA6C3BE9D3B4D84A3B80489505A23E5'
                              when 'DECIMAL' then '22'
                              when 'IDFIELD' then '13'
                              when 'PATTRIBUTE' then '35'
                              when 'TIME' then '24'
                              when 'DATETIME' then '16'
      end into v_return;
  end if;
  return coalesce(v_return,'10');
end;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE OR REPLACE FUNCTION ad_process_para_reference_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
Prevents deletion of Main DOCTYPES
*****************************************************/
v_return varchar;        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    select  case  new.template when 'EURO'      then '12'
                              when 'INTEGER'     then  '12'                              
                              when 'PRICE' then '800008'
                              when 'DATE'     then '15'
                              when  'DECIMAL' then '22'
                              when 'TIME' then '24'
                              when 'CHECKBOX' then '20'
                              else '10'
                              
          end into v_return;
  new.ad_reference_id:=v_return;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('ad_process_para_reference_trg','ad_process_para');

CREATE TRIGGER ad_process_para_reference_trg
  BEFORE INSERT OR UPDATE
  ON ad_process_para FOR EACH ROW
  EXECUTE PROCEDURE ad_process_para_reference_trg();
  
 
select zsse_dropfunction('ad_getcustomcolumns');
CREATE OR REPLACE FUNCTION ad_getcustomcolumns(p_tab_id character varying,pType  out varchar,PName out varchar)
RETURNS SETOF RECORD AS
$BODY$ DECLARE 
v_cur record;
v_ref varchar;
v_name varchar;
v_view varchar:='N';
BEGIN
    if (select count(*) from INFORMATION_SCHEMA.views,ad_table,ad_tab where ad_tab.ad_table_id=ad_table.ad_table_id and INFORMATION_SCHEMA.views.table_name=ad_table.tablename and ad_tab.ad_tab_id = p_tab_id)>0 then
        v_view:='Y';
    end if;
    for v_cur in (select ad_customcolumn_id from ad_customfield where ad_tab_id = p_tab_id and v_view='N')
    LOOP
        select ad_reference_id,columnname into v_ref,v_name from ad_customcolumn where ad_customcolumn_id=v_cur.ad_customcolumn_id;
        if v_ref='15' then
           pType:='TIMESTAMP';
        else
            if v_ref='12' then
                pType:='NUMERIC';
            else
                pType:='STRING';
            end if;
        end if;
        PName:=v_name;
        RETURN NEXT;
    END LOOP;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  


select zsse_dropfunction('ad_gridSelectFromGroup');
CREATE OR REPLACE FUNCTION ad_gridSelectFromGroup(p_group_id character varying,p_autoheader character varying, pad_element_id out varchar,pad_reference_id out varchar,
                                                  pAD_REF_GROUP_ID out varchar,pAD_REF_GRIDCOLUMN_ID out varchar,
                                                  pname out varchar,pTEMPLATE out varchar,pREFERENCEURL out varchar,ponchangeevent out varchar,
                                                  pcolreference out varchar,pAD_TABLE_ID out varchar,pCOLSPAN out numeric,pMAXLENGTH out numeric,pREQUIRED out varchar,
                                                  pREADONLY out varchar,pISSECONDHEADER out varchar,pISINHEADER out varchar,pISSPLITGROUP out varchar,
                                                  pincludesemptyitem out varchar,pLine out numeric,pdynamiccolssql out varchar, pstyle out varchar,preadonlylogic out varchar)
RETURNS SETOF RECORD AS
$BODY$ DECLARE 
v_cur record;
BEGIN
 if p_autoheader = 'Y' then
    for v_cur in (SELECT b.AD_REF_GRIDCOLUMN_id,coalesce(i.line,b.line) as line,
                       coalesce(i.ad_element_id,b.ad_element_id) as ad_element_id,b.ad_reference_id as ad_reference_id,b.AD_REF_GROUP_ID,
                       coalesce(i.name,b.NAME) as name,'HEADER' as TEMPLATE,null as REFERENCEURL, null as onchangeevent,
                       null as colreference,null as AD_TABLE_ID,
                       coalesce(i.colspan,b.COLSPAN) as colspan,coalesce(i.maxlength,b.MAXLENGTH) as maxlength,
                       b.REQUIRED,b.READONLY,'N' as ISSECONDHEADER,'Y' as ISINHEADER,'N' as ISSPLITGROUP,b.includesemptyitem,b.dynamiccolssql,null as style,null as readonlylogic
                       from AD_REF_GRIDCOLUMN b
                       left join ad_ref_gridcolumninstance i on i.AD_REF_GRIDCOLUMN_id=b.AD_REF_GRIDCOLUMN_id and i.isactive='Y'
                       where b.AD_REF_GROUP_id= p_group_id  and b.isactive='Y' and coalesce(i.template,b.template)!='DYNAMIC'
                  UNION ALL
                  SELECT b.AD_REF_GRIDCOLUMN_id,coalesce(i.line,b.line) as line,
                       coalesce(i.ad_element_id,b.ad_element_id) as ad_element_id,b.ad_reference_id,b.AD_REF_GROUP_ID,
                       b.NAME as name,coalesce(i.template,b.template) as TEMPLATE,
                       coalesce(i.REFERENCEURL,b.REFERENCEURL) as REFERENCEURL, coalesce(i.onchangeevent,b.onchangeevent) as onchangeevent,
                       coalesce(i.colreference,b.colreference) as colreference,coalesce(i.AD_TABLE_ID,b.AD_TABLE_ID) as AD_TABLE_ID,
                       coalesce(i.colspan,b.COLSPAN) as colspan,coalesce(i.maxlength,b.MAXLENGTH) as maxlength,
                       coalesce(i.REadonly,b.readonly) READONLY ,
                       case when coalesce(i.REQUIRED,b.required)='NON' then b.required else coalesce(i.REQUIRED,b.required) end  as required,
                       'N' as ISSECONDHEADER,'N' as ISINHEADER,'N' as ISSPLITGROUP,
                       case when coalesce(i.includesemptyitem,b.includesemptyitem)='NON' then b.includesemptyitem else coalesce(i.includesemptyitem,b.includesemptyitem) end as includesemptyitem,
                       coalesce(i.dynamiccolssql,b.dynamiccolssql) as dynamiccolssql,
                       coalesce(i.style,b.style) as style,
                       coalesce(i.readonlylogic,b.readonlylogic) as readonlylogic
                       from AD_REF_GRIDCOLUMN b left join ad_ref_gridcolumninstance i on i.AD_REF_GRIDCOLUMN_id=b.AD_REF_GRIDCOLUMN_id and i.isactive='Y'
                       where b.AD_REF_GROUP_id= p_group_id  and b.isactive='Y' )
    LOOP
        pad_element_id:=v_cur.ad_element_id;
        pad_reference_id:=v_cur.ad_reference_id;
        pAD_REF_GROUP_ID:=v_cur.AD_REF_GROUP_ID;
        pAD_REF_GRIDCOLUMN_ID:=v_cur.AD_REF_GRIDCOLUMN_ID;
        pname:=v_cur.name;
       -- pHEADERTEXT:=v_cur.HEADERTEXT;
        pTEMPLATE:=v_cur.TEMPLATE;
        pREFERENCEURL:=v_cur.REFERENCEURL;
        ponchangeevent:=v_cur.onchangeevent;
        pcolreference:=v_cur.colreference;
        pAD_TABLE_ID:=v_cur.AD_TABLE_ID;
        pCOLSPAN:=v_cur.COLSPAN;
        pMAXLENGTH:=v_cur.MAXLENGTH;
        pREQUIRED:=v_cur.REQUIRED;
        pREADONLY:=v_cur.READONLY;
        pISSECONDHEADER:=v_cur.ISSECONDHEADER;
        pISINHEADER:=v_cur.ISINHEADER;
        pISSPLITGROUP:=v_cur.ISSPLITGROUP;
        pincludesemptyitem:=v_cur.includesemptyitem;
        pdynamiccolssql:=v_cur.dynamiccolssql;
        pstyle:=v_cur.style;
        preadonlylogic:=v_cur.readonlylogic;
        pLine:=v_cur.Line;
        RETURN NEXT;
    END LOOP;
  else
    for v_cur in (SELECT b.AD_REF_GRIDCOLUMN_id,coalesce(i.line,b.line) as line,
                       coalesce(i.ad_element_id,b.ad_element_id) as ad_element_id,b.ad_reference_id,b.AD_REF_GROUP_ID,
                       coalesce(i.name,b.NAME) as name,coalesce(i.headertext,b.HEADERTEXT) as headertext,coalesce(i.template,b.template) as TEMPLATE,
                       coalesce(i.REFERENCEURL,b.REFERENCEURL) as REFERENCEURL, coalesce(i.onchangeevent,b.onchangeevent) as onchangeevent,
                       coalesce(i.colreference,b.colreference) as colreference,coalesce(i.AD_TABLE_ID,b.AD_TABLE_ID) as AD_TABLE_ID,
                       coalesce(i.colspan,b.COLSPAN) as colspan,coalesce(i.maxlength,b.MAXLENGTH) as maxlength,
                       coalesce(i.REadonly,b.readonly) READONLY ,
                       case when coalesce(i.REQUIRED,b.required)='NON' then b.required else coalesce(i.REQUIRED,b.required) end  as required,
                       case when coalesce(i.ISSECONDHEADER,b.ISSECONDHEADER)='NON' then b.ISSECONDHEADER else coalesce(i.ISSECONDHEADER,b.ISSECONDHEADER) end as ISSECONDHEADER,
                       case when coalesce(i.ISINHEADER,b.ISINHEADER)='NON' then b.ISINHEADER else coalesce(i.ISINHEADER,b.ISINHEADER) end as ISINHEADER,
                       case when coalesce(i.ISSPLITGROUP,b.ISSPLITGROUP)='NON' then b.ISSPLITGROUP else coalesce(i.ISSPLITGROUP,b.ISSPLITGROUP) end as ISSPLITGROUP,
                       case when coalesce(i.includesemptyitem,b.includesemptyitem)='NON' then b.includesemptyitem else coalesce(i.includesemptyitem,b.includesemptyitem) end as includesemptyitem,
                       coalesce(i.dynamiccolssql,b.dynamiccolssql) as dynamiccolssql,
                       coalesce(i.style,b.style) as style,
                       coalesce(i.readonlylogic,b.readonlylogic) as readonlylogic
                       from AD_REF_GRIDCOLUMN b left join ad_ref_gridcolumninstance i on i.AD_REF_GRIDCOLUMN_id=b.AD_REF_GRIDCOLUMN_id and i.isactive='Y'
                       where b.AD_REF_GROUP_id= p_group_id  and b.isactive='Y')
    LOOP
        pad_element_id:=v_cur.ad_element_id;
        pad_reference_id:=v_cur.ad_reference_id;
        pAD_REF_GROUP_ID:=v_cur.AD_REF_GROUP_ID;
        pAD_REF_GRIDCOLUMN_ID:=v_cur.AD_REF_GRIDCOLUMN_ID;
        pname:=v_cur.name;
        --pHEADERTEXT:=v_cur.HEADERTEXT;
        pTEMPLATE:=v_cur.TEMPLATE;
        pREFERENCEURL:=v_cur.REFERENCEURL;
        ponchangeevent:=v_cur.onchangeevent;
        pcolreference:=v_cur.colreference;
        pAD_TABLE_ID:=v_cur.AD_TABLE_ID;
        pCOLSPAN:=v_cur.COLSPAN;
        pMAXLENGTH:=v_cur.MAXLENGTH;
        pREQUIRED:=v_cur.REQUIRED;
        pREADONLY:=v_cur.READONLY;
        pISSECONDHEADER:=v_cur.ISSECONDHEADER;
        pISINHEADER:=v_cur.ISINHEADER;
        pISSPLITGROUP:=v_cur.ISSPLITGROUP;
        pincludesemptyitem:=v_cur.includesemptyitem;
        pdynamiccolssql:=v_cur.dynamiccolssql;
        pstyle:=v_cur.style;
        preadonlylogic:=v_cur.readonlylogic;
        pLine:=v_cur.Line;
        RETURN NEXT;
    END LOOP;
 end if;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


select zsse_dropfunction('ad_selecttabfields');
CREATE OR REPLACE FUNCTION ad_selecttabfields(in_language varchar,in_tab_id character varying,pad_element_id out varchar,pfieldgroupid out varchar,
                           pfieldreference out varchar,pislinebreak out varchar,pAD_REF_FIELDCOLUMN_ID out varchar,pname out varchar,pname2 out varchar,
                           pTEMPLATE out varchar,pREFERENCEURL out varchar,ponchangeevent out varchar,pAD_TABLE_ID out varchar,pCOLSTOTAL out varchar,
                           pMAXLENGTH out numeric,pleadingemptycols out numeric,pBUTTONCLASS out varchar,ptranslation out varchar,
                           pincludesemptyitem out varchar,pAD_ValRule_ID out varchar,pstyle out varchar,pline out numeric)
RETURNS SETOF RECORD AS
$BODY$ DECLARE 
v_cur record;
v_indset record;
v_count numeric;
v_breakcount numeric:=0;
v_onchangeevent varchar;
v_colsum numeric:=0;
v_nextcolsameline varchar;
v_nextcolsamelineInd varchar;
v_nextcolcount varchar;
v_icreated date;
BEGIN
  for v_cur in (SELECT f.ad_fieldgroup_id ,c.ad_element_id, c.columnname as NAME,'' as NAME2,
                (select case when mo.MappingName is null then null else 'reloadCallout(this.name,'||chr(39)||'..'||mo.MappingName||chr(39)||');' end from ad_model_object_mapping mo, ad_model_object m,ad_callout co where co.ad_callout_id=coalesce(f.ad_callout_id,c.ad_callout_id) and co.ad_callout_id=m.ad_callout_id and mo.ad_model_object_id=m.ad_model_object_id limit 1) as ONCHANGEEVENT, 
                coalesce(i.line,f.seqno) as LINE,
                case when f.fieldreference is null and f.tablereference is null then c.AD_Val_Rule_ID else f.validationrule end as ad_val_rule_id,
                f.issameline as islinebreak,f.includesemptyitem, f.ad_field_v_id as AD_REF_FIELDCOLUMN_ID, c.ad_reference_value_id as ad_reference_id,
                case when c.isencrypted='Y' then 'PASSWORD'::varchar else coalesce(f.template,ad_datatype_guiengine_template_mapping(c.AD_REFERENCE_ID)) end as TEMPLATE, 
                coalesce(f.buttonclass,'process'::varchar) as buttonclass, 
                f.onchangeevent as cutomoncangeevent,
                case when lower(c.columnname)='createfrom' then 'logClick(document.getElementById('||chr(39)||c.columnname||chr(39)||'));openServletNewWindow('||chr(39)||'BUTTONCreateFrom'||chr(39)||', true, '||chr(39)||replace(replace(replace(replace(replace(t.name,' ',''),'-',''),')',''),'(',''),'/','')||
                                                                       case when t.ad_module_id='0' then '' else t.ad_tab_id end 
                                               ||'_Edition.html'|| chr(39)||', '||chr(39)||'BUTTON'||chr(39)||', null, true, 800, 1000)'
                     when lower(c.columnname)='posted' then 'logClick(document.getElementById('||chr(39)||c.columnname||chr(39)||'));openServletNewWindow('||chr(39)||'BUTTONPosted'||chr(39)||', true, '||chr(39)||replace(replace(replace(replace(replace(t.name,' ',''),'-',''),')',''),'(',''),'/','')||
                                                                       case when t.ad_module_id='0' then '' else t.ad_tab_id end 
                                               ||'_Edition.html'|| chr(39)||', '||chr(39)||'BUTTON'||chr(39)||', null, true, 800, 1000)'
                else
                    case when p.isdirectservletcall='N' then 
                        case when p.uipattern='S' then 'logClick(document.getElementById('||chr(39)||c.columnname||chr(39)||'));openServletNewWindow('||chr(39)||'BUTTON'||c.columnname||p.ad_process_id||chr(39)||', true, '||chr(39)||replace(replace(replace(replace(replace(t.name,' ',''),'-',''),')',''),'(',''),'/','')||
                                                                            case when t.ad_module_id='0' then '' else t.ad_tab_id end 
                                                    ||'_Edition.html'|| chr(39)||', '||chr(39)||'BUTTON'||chr(39)||', null, true, 800, 1000)'
                                                else 'logClick(document.getElementById('||chr(39)||c.columnname||chr(39)||'));openServletNewWindow('||chr(39)||'DEFAULT'||chr(39)||', true, '||chr(39)||'..'||mo.MappingName||chr(39)||', '||chr(39)||'BUTTON'||chr(39)||', '||chr(39)||p.ad_process_id||chr(39)||', true,800, 1000)' 
                        end 
                    else
                        'submitCommandForm('||chr(39)||'DEFAULT'||chr(39)||', true,null, '||chr(39)||'..'||mo.MappingName||chr(39)||', '||chr(39)||'appFrame'||chr(39)||', false, true)' 
                    end
                end as REFERENCEURL, 
                coalesce(f.fieldreference,case when f.tablereference is null then c.ad_reference_value_id else null end) as FIELDREFERENCE, 
                case when c.AD_REFERENCE_ID='19' and f.tablereference is null then (SELECT ad_table_id from ad_table where lower(tablename)=lower(substr(c.columnname,1,length(c.columnname)-3))) 
                     else f.tablereference end as AD_TABLE_ID, 
                f.COLSTOTAL, 
                coalesce(f.maxlength,c.fieldlength) as MAXLENGTH, f.style as STYLE,
                zssi_getTabFieldTextByID(f.ad_field_v_id,in_language) as translation
                from ad_tab t,ad_column_v c   left join ad_field_v f on f.ad_column_v_id=c.ad_column_v_id
                                            left join ad_process p on coalesce(f.ad_process_id,c.ad_process_id)=p.ad_process_id
                                            left join ad_model_object mm on p.ad_process_id=mm.ad_process_id and mm.ad_model_object_id = (select x1.ad_model_object_id from ad_model_object x1 where x1.ad_process_id=p.ad_process_id order by isdefault desc limit 1)
                                            left join ad_model_object_mapping mo on mo.ad_model_object_id=mm.ad_model_object_id and mo.ad_model_object_mapping_id = (select x2.ad_model_object_mapping_id from ad_model_object_mapping x2 where x2.ad_model_object_id=mm.ad_model_object_id order by isdefault desc limit 1)
                                            left join ad_fieldinstance i on f.ad_field_v_id=i.ad_field_v_id
                where  t.ad_tab_id=f.ad_tab_id and t.AD_tab_ID = in_tab_id
                and c.isactive='Y'
                and f.isactive='Y'
                and c.ad_reference_id!='23' order by coalesce(i.line,f.seqno))
  LOOP
    select count(*) into v_count from ad_fieldinstance where AD_field_v_ID=v_cur.AD_REF_FIELDCOLUMN_ID;
    if v_count=1 then
        for v_indset in  (select *   from  ad_fieldinstance where AD_field_v_ID=v_cur.AD_REF_FIELDCOLUMN_ID)
        LOOP
            pfieldgroupid:=coalesce(v_indset.ad_fieldgroup_id,v_cur.ad_fieldgroup_id);
            pfieldreference:=coalesce(v_indset.fieldreference,v_cur.fieldreference);
            pislinebreak:=case when coalesce(v_indset.issameline,v_cur.islinebreak)='NON' then v_cur.islinebreak else coalesce(v_indset.issameline,v_cur.islinebreak) end;
            pTEMPLATE:=coalesce(v_indset.template,v_cur.template);
            pREFERENCEURL:=coalesce(v_indset.REFERENCEURL,v_cur.REFERENCEURL);
            if v_indset.ad_callout_id is not null then
                select 'reloadCallout(this.name,'||chr(39)||'..'||mo.MappingName||chr(39)||');' into v_onchangeevent from ad_model_object_mapping mo, ad_model_object m,ad_callout co 
                       where co.ad_callout_id=v_indset.ad_callout_id and co.ad_callout_id=m.ad_callout_id and mo.ad_model_object_id=m.ad_model_object_id;
            end if;
            ponchangeevent:=coalesce(v_indset.onchangeevent,'')||coalesce(v_onchangeevent,coalesce(v_cur.cutomoncangeevent,'')||coalesce(v_cur.onchangeevent,''));
            if ponchangeevent='' then
                ponchangeevent:=null;
            end if;
            v_onchangeevent:=null;
            pAD_TABLE_ID:=coalesce(v_indset.AD_TABLE_ID,v_cur.AD_TABLE_ID);
            pCOLSTOTAL:=coalesce(v_indset.COLSTOTAL,v_cur.COLSTOTAL);
            pMAXLENGTH:=coalesce(v_indset.MAXLENGTH,v_cur.MAXLENGTH);
            pBUTTONCLASS:=coalesce(v_indset.BUTTONCLASS,v_cur.BUTTONCLASS);
            pincludesemptyitem:=case when coalesce(v_indset.includesemptyitem,v_cur.includesemptyitem)='NON' then v_cur.includesemptyitem else coalesce(v_indset.includesemptyitem,v_cur.includesemptyitem) end;
            pAD_ValRule_ID:=coalesce(v_indset.AD_Val_Rule_ID,case when v_indset.fieldreference is null and v_indset.AD_TABLE_ID is null then v_cur.AD_Val_Rule_ID else null end);
            pstyle:=coalesce(v_indset.style,v_cur.style);
        end loop;
    else
        pfieldgroupid:=v_cur.ad_fieldgroup_id;
        pfieldreference:=v_cur.fieldreference;
        pislinebreak:=v_cur.islinebreak;
        pTEMPLATE:=v_cur.template;
        pREFERENCEURL:=v_cur.REFERENCEURL;
        /*
        if lower(v_cur.name)='createfrom' then
            ponchangeevent:=logClick(document.getElementById('CreateFrom')); openServletNewWindow('BUTTONCreateFrom', true, 'GoodsMovementVendor_Edition.html', 'BUTTON', null, true,600, 900);
        if lower(v_cur.name)='posted' then
        */
        ponchangeevent:=coalesce(v_cur.cutomoncangeevent,'')||coalesce(v_cur.onchangeevent,'');
        if ponchangeevent='' then
                ponchangeevent:=null;
        end if;
        pAD_TABLE_ID:=v_cur.AD_TABLE_ID;
        pCOLSTOTAL:=v_cur.COLSTOTAL;
        pMAXLENGTH:=v_cur.MAXLENGTH;
        pBUTTONCLASS:=v_cur.BUTTONCLASS;
        pincludesemptyitem:=v_cur.includesemptyitem;
        pAD_ValRule_ID:=v_cur.AD_Val_Rule_ID;
        pstyle:=v_cur.style;
    end if;
    pline:=v_cur.line;
    -- Umkehrung - issameline wird angehakt, linebreak=n
    if pislinebreak='Y' then 
        pislinebreak:='N';
    else
        pislinebreak:='Y';
    end if;
     pleadingemptycols:=0;
    -- Determin Leading Empty Cols (We have 6 Columns- 2nd field needs leading of 1 If  1st field has 2 columns and no 3rd field with 2 columns follows) 
     if v_colsum = 2  then -- First field has 2 columns - we are in the 2nd field of a line
            select ad_field_v.issameline,ad_fieldinstance.issameline,coalesce(ad_fieldinstance.colstotal,ad_field_v.colstotal),coalesce(trunc(ad_fieldinstance.created),trunc(now())) 
                   into v_nextcolsameline,v_nextcolsamelineInd,v_nextcolcount,v_icreated
                              from ad_field_v left join ad_fieldinstance on ad_fieldinstance.ad_field_v_id=ad_field_v.ad_field_v_id
                               where ad_tab_id=in_tab_id and  coalesce(ad_fieldinstance.line,ad_field_v.seqno)>pline 
                               order by coalesce(ad_fieldinstance.line,ad_field_v.seqno)  limit 1;
            -- After the current 2-column field anoter field  with 2 columns may folow. In this cace we do not need a leading empty col.
            -- Prop. Fix in Whereclause
            -- and (case when coalesce(ad_fieldinstance.visiblesetting,'NON')='VISIBLE' then 'Y' when coalesce(ad_fieldinstance.visiblesetting,'NON')='HIDDEN' then 'N' else ad_field_v.isdisplayed end) = 'Y'  
            -- Ticket 11221
            if  ((coalesce(v_nextcolsamelineInd,v_nextcolsameline)='Y')  and to_number(pCOLSTOTAL)=2 and to_number(v_nextcolcount)=2 and v_icreated>=to_date('26.09.2023','dd.mm.yyyy')) or
                ((v_nextcolsameline='Y'  or v_nextcolsamelineInd='Y')  and to_number(pCOLSTOTAL)=2 and to_number(v_nextcolcount)=2 and v_icreated<to_date('26.09.2023','dd.mm.yyyy')) then
                     null;
            else
                pleadingemptycols:=1;
                v_colsum:=v_colsum+1;
            end if;
    end if;
   
    v_colsum:=to_number(pCOLSTOTAL)+ v_colsum;
    if pislinebreak='Y' or v_colsum>6 then
             pleadingemptycols:=0;
             v_colsum:=to_number(pCOLSTOTAL);
             pislinebreak:='Y';         
    end if;
    pname:=v_cur.name;
    pname2:=v_cur.name2;
    ptranslation:=v_cur.translation;
    pAD_REF_FIELDCOLUMN_ID:=v_cur.AD_REF_FIELDCOLUMN_ID;
    RETURN NEXT;
  END LOOP;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  

select zsse_dropfunction('ad_selecttabBuscadorFields');
CREATE OR REPLACE FUNCTION ad_selecttabBuscadorFields(in_language varchar,in_tab_id character varying,in_isaudit varchar,in_directfilter varchar,
                           pfieldreference out varchar,pislinebreak OUT varchar,pAD_REF_FIELDCOLUMN_ID out varchar,pname out varchar,pname2 out varchar,
                           pTEMPLATE out varchar,pAD_TABLE_ID out varchar,pCOLSTOTAL out varchar,
                           pMAXLENGTH out numeric,ptranslation out varchar,
                           pAD_ValRule_ID out varchar,pstyle out varchar,pline out numeric)
RETURNS SETOF RECORD AS
$BODY$ DECLARE 
v_cur record;
v_indset record;
v_count numeric;
v_filter varchar;
v_isdirect varchar;
v_seqaud numeric=100000;
BEGIN
  for v_cur in (SELECT c.columnname as NAME,'' as NAME2,
                f.seqno as LINE,
                c.ad_val_rule_id, f.ad_field_v_id as AD_REF_FIELDCOLUMN_ID, c.ad_reference_value_id as ad_reference_id,
                coalesce(f.template,ad_datatype_guiengine_template_Mapping(c.AD_REFERENCE_ID)) as TEMPLATE, 
                coalesce(f.fieldreference,c.ad_reference_value_id) as FIELDREFERENCE, 
                case when c.AD_REFERENCE_ID='19' and f.tablereference is null then (SELECT ad_table_id from ad_table where lower(tablename)=lower(substr(c.columnname,1,length(c.columnname)-3))) 
                     else f.tablereference end as AD_TABLE_ID, 
                coalesce(f.maxlength,c.fieldlength) as MAXLENGTH,  ''::varchar as STYLE,
                zssi_getTabFieldTextByID(f.ad_field_v_id,in_language) as translation,
                f.isfiltercolumn,f.isdirectfilter
                from ad_tab t,ad_column_v c,ad_field_v f 
                where f.ad_column_v_id=c.ad_column_v_id and t.ad_tab_id=f.ad_tab_id and t.AD_tab_ID = in_tab_id
                and c.isactive='Y'
                and f.isactive='Y'
                and c.ad_reference_id!='23')
  LOOP
    select count(*) into v_count from ad_fieldinstance where AD_field_v_ID=v_cur.AD_REF_FIELDCOLUMN_ID;
    if v_count>0 then
        for v_indset in  (select *   from  ad_fieldinstance where AD_field_v_ID=v_cur.AD_REF_FIELDCOLUMN_ID)
        LOOP
            pfieldreference:=coalesce(v_indset.fieldreference,v_cur.fieldreference);
            pTEMPLATE:=coalesce(v_indset.template,v_cur.template);
            pAD_TABLE_ID:=coalesce(v_indset.AD_TABLE_ID,v_cur.AD_TABLE_ID);            
            pMAXLENGTH:=coalesce(v_indset.MAXLENGTH,v_cur.MAXLENGTH);
            pAD_ValRule_ID:=coalesce(v_indset.AD_Val_Rule_ID,v_cur.AD_Val_Rule_ID);
            pstyle:=coalesce(v_indset.style,v_cur.style);
            pline:=coalesce(v_indset.line,v_cur.line);
            v_filter:=case when v_indset.isfiltercolumn!='NON' then v_indset.isfiltercolumn else v_cur.isfiltercolumn end;
            if in_directfilter='Y' and v_filter='Y' then
                v_isdirect:=case when v_indset.isdirectfilter!='NON' then v_indset.isdirectfilter else v_cur.isdirectfilter end;
                if v_isdirect='N' then
                    v_filter:='N';
                end if;
            end if;
        end loop;
    else
        pfieldreference:=v_cur.fieldreference;
        pTEMPLATE:=v_cur.template;
        pAD_TABLE_ID:=v_cur.AD_TABLE_ID;
        pMAXLENGTH:=v_cur.MAXLENGTH;
        pAD_ValRule_ID:=v_cur.AD_Val_Rule_ID;
        pstyle:=v_cur.style;
        pline:=v_cur.line;
        v_filter:=v_cur.isfiltercolumn;
        if in_directfilter='Y' and v_filter='Y' then
            if v_cur.isdirectfilter='N' then
                v_filter:='N';
            end if;
        end if;
    end if;
    pCOLSTOTAL:=2;
    pname:=v_cur.name;
    pname2:=v_cur.name2;
    ptranslation:=v_cur.translation;
    pAD_REF_FIELDCOLUMN_ID:=v_cur.AD_REF_FIELDCOLUMN_ID;
    if in_directfilter='Y' then
        pislinebreak:='N';  
    else
        pislinebreak:='Y';
    end if;
    if v_filter='Y' then
        if pTEMPLATE='CHECKBOX' then
        pTEMPLATE:='REFCOMBO';
        pfieldreference:='47209D76F3EE4B6D84222C5BDF170AA2'; -- 'Yes/No search box';
        end if;
        if pTEMPLATE in ('DATE','DECIMAL','EURO','INTEGER','PRICE','SQLFIELDDECIMAL','SQLFIELDEURO','SQLFIELDINTEGER','SQLFIELDPRICE') then
            if pTEMPLATE = 'DATE' then
                ptranslation:=v_cur.translation||' '||zssi_getElementTextByColumname('From',in_language);   
            else
                ptranslation:=v_cur.translation||' '||zssi_getElementTextByColumname('FromNum',in_language);   
            end if;
            RETURN NEXT;
            pline:=pline+0.5;
            pname:=v_cur.name||'_f';
            ptranslation:=v_cur.translation||' '||zssi_getElementTextByColumname('To',in_language);
            pislinebreak:='N';
        end if;  
        if pTEMPLATE in ('NOEDIT_TEXTBOX','URL','TEXTAREA_EDIT_SIMPLE','TEXTAREA_EDIT_ADV') then
            pTEMPLATE:='TEXT';
        end if;
        if pTEMPLATE not in ('BUTTON','RADIOBUTTON','LABEL','IMAGE') then
            RETURN NEXT;   
        end if;
     end if;
  END LOOP;
  if in_isaudit='Y' and  in_directfilter='N' then
     for v_cur in (SELECT c.columnname as NAME,'' as NAME2,
                c.ad_val_rule_id, c.ad_column_id as AD_REF_FIELDCOLUMN_ID, 
                c.ad_reference_value_id  as ad_reference_id,
                case when UPPER(c.columnname) in ('CREATEDBY','UPDATEDBY') then 'REFCOMBO' else ad_datatype_guiengine_template_Mapping(c.AD_REFERENCE_ID) end as TEMPLATE, 
                case when UPPER(c.columnname) in ('CREATEDBY','UPDATEDBY') then '2B964358653C45ED9B4D17DF007A8F05' else c.ad_reference_value_id end as FIELDREFERENCE, -- ad user employee 
                case when c.AD_REFERENCE_ID='19'  then (SELECT ad_table_id from ad_table where lower(tablename)=lower(substr(c.columnname,1,length(c.columnname)-3))) 
                     else null end as AD_TABLE_ID, 
                c.fieldlength as MAXLENGTH,  ''::varchar as STYLE,
                zssi_getElementTextByID(c.ad_element_id,in_language) as translation,
                'Y' as isfiltercolumn
                from ad_tab t,ad_column c
                where t.ad_table_id=c.ad_table_id and t.AD_tab_ID = in_tab_id
                and c.isactive='Y'
                and c.isparent='N'
                and c.ad_reference_id!='23'
                and UPPER(c.columnname) in ('CREATED', 'CREATEDBY', 'UPDATED', 'UPDATEDBY')
                order by c.columnname)
      loop
        pfieldreference:=v_cur.fieldreference;
        pTEMPLATE:=v_cur.template;
        pAD_TABLE_ID:=v_cur.AD_TABLE_ID;
        pMAXLENGTH:=v_cur.MAXLENGTH;
        pAD_ValRule_ID:=v_cur.AD_Val_Rule_ID;
        pstyle:=v_cur.style;
        v_seqaud:=v_seqaud+1;
        pline:=v_seqaud;
        v_filter:=v_cur.isfiltercolumn;
        pCOLSTOTAL:=2;
        pname:=v_cur.name;
        pname2:=v_cur.name2;
        ptranslation:=v_cur.translation;
        pAD_REF_FIELDCOLUMN_ID:=v_cur.AD_REF_FIELDCOLUMN_ID;
        pislinebreak:='Y';  
        if v_filter='Y' then
            if pTEMPLATE='CHECKBOX' then
            pTEMPLATE:='REFCOMBO';
            pfieldreference:='47209D76F3EE4B6D84222C5BDF170AA2'; -- 'Yes/No search box';
            end if;
            if pTEMPLATE in ('DATE','DECIMAL','EURO','INTEGER','PRICE') then
                ptranslation:=v_cur.translation||' '||zssi_getElementTextByColumname('From',in_language);   
                RETURN NEXT;
                v_seqaud:=v_seqaud+1;
                pline:=v_seqaud;
                pname:=v_cur.name||'_f';
                ptranslation:=v_cur.translation||' '||zssi_getElementTextByColumname('To',in_language);
                pislinebreak:='N';
            end if;  
            if pTEMPLATE in ('NOEDIT_TEXTBOX','URL','TEXTAREA_EDIT_SIMPLE','TEXTAREA_EDIT_ADV') then
                pTEMPLATE:='TEXT';
            end if;
            if pTEMPLATE not in ('BUTTON','RADIOBUTTON','LABEL','IMAGE') then
                RETURN NEXT;   
            end if;
        end if;
      end loop;
  end if;
  if (select case when coalesce(i.ismaxrowsparam,'') ='Y' then 'Y' when  coalesce(i.ismaxrowsparam,'') ='N' then 'N' else t.ismaxrowsparam end 
             from ad_tab t left join ad_tab_instance i on t.ad_tab_id=i.ad_tab_id where t.ad_tab_id=in_tab_id) ='Y' 
  then
    pTEMPLATE:='INTEGER';
    ptranslation:=zssi_getElementTextByColumname('Maxrowsparam',in_language);
    pname:='maxrowsparam';
    if in_directfilter='Y' then
        pislinebreak:='N';  
    else
        pislinebreak:='Y';
    end if;
    v_filter:='Y';
    pCOLSTOTAL:=2;
    pMAXLENGTH:=4;
    pline:=1000;
    RETURN NEXT;
  end if;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
select zsse_dropfunction('ad_selectprocessfields');
CREATE OR REPLACE FUNCTION ad_selectprocessfields(in_language varchar,in_process_id character varying,ptranslation out varchar,
                           pfieldreference out varchar,pislinebreak out varchar,pAD_REF_FIELDCOLUMN_ID out varchar,pname out varchar,pname2 out varchar,
                           pTEMPLATE out varchar,pREFERENCEURL out varchar,ponchangeevent out varchar,pAD_TABLE_ID out varchar,pCOLSTOTAL out varchar,
                           pMAXLENGTH out numeric,pleadingemptycols out numeric,pBUTTONCLASS out varchar,pad_element_id out varchar,
                           pincludesemptyitem out varchar,pAD_ValRule_ID out varchar,pstyle out varchar,pline out numeric)
RETURNS SETOF RECORD AS
$BODY$ DECLARE 
v_cur record;
v_indset record;
v_count numeric;
BEGIN
  for v_cur in (SELECT ad_element_id, columnname as NAME,'' as NAME2, '' as ONCHANGEEVENT, seqno as LINE,
                ad_val_rule_id,'Y' as islinebreak,includesemptyitem, ad_process_para_id as AD_REF_FIELDCOLUMN_ID, ad_reference_value_id as ad_reference_id,
                TEMPLATE, '' as buttonclass, '' as REFERENCEURL, ad_reference_value_id as FIELDREFERENCE, 
                AD_TABLE_ID, 0 as LEADINGEMPTYCOLS, 
                COLSTOTAL, 
                fieldlength as MAXLENGTH,  '' as STYLE,
                zssi_getProcessParamTextByID(ad_process_para_id,in_language) as translation
                from ad_process_para where AD_PROCESS_ID = in_process_id
                and isactive='Y'
                and coalesce(ad_reference_id,'')!='23'
                and coalesce(ad_reference_id,'')!='13')
  LOOP
    select count(*) into v_count from ad_process_para_instance where ad_process_para_ID=v_cur.AD_REF_FIELDCOLUMN_ID;
    if v_count>0 then
        for v_indset in  (select *   from  ad_process_para_instance where ad_process_para_id=v_cur.AD_REF_FIELDCOLUMN_ID)
        LOOP
            pfieldreference:=coalesce(v_indset.ad_reference_value_id,v_cur.fieldreference);           
            pTEMPLATE:=coalesce(v_indset.template,v_cur.template);
            pAD_TABLE_ID:=coalesce(v_indset.AD_TABLE_ID,v_cur.AD_TABLE_ID);
            pCOLSTOTAL:=coalesce(v_indset.COLSTOTAL,v_cur.COLSTOTAL);
            pMAXLENGTH:=coalesce(v_indset.fieldlength,v_cur.MAXLENGTH);
            pincludesemptyitem:=case when v_indset.includesemptyitem!='NON' then v_indset.includesemptyitem else v_cur.includesemptyitem end;
            pAD_ValRule_ID:=coalesce(v_indset.ad_val_rule_id,v_cur.ad_val_rule_id);
            pline:=coalesce(v_indset.seqno,v_cur.line);
        end loop;
    else
        pname:=v_cur.name;
        pname2:=v_cur.name2;
        pfieldreference:=v_cur.fieldreference;
        pTEMPLATE:=v_cur.template;
        pAD_TABLE_ID:=v_cur.AD_TABLE_ID;
        pCOLSTOTAL:=v_cur.COLSTOTAL;
        pMAXLENGTH:=v_cur.MAXLENGTH;
        pincludesemptyitem:=v_cur.includesemptyitem;
        pAD_ValRule_ID:=v_cur.ad_val_rule_id;       
        pline:=v_cur.line;
    end if;
    pislinebreak:='Y';
    pREFERENCEURL:=v_cur.REFERENCEURL;
    pname:=v_cur.name;
    pname2:=v_cur.name2;
    pislinebreak:=v_cur.islinebreak;
    ponchangeevent:=v_cur.onchangeevent;
    pleadingemptycols:=v_cur.leadingemptycols;
    pBUTTONCLASS:=v_cur.BUTTONCLASS;
    pstyle:=v_cur.style;
    ptranslation:=v_cur.translation;
    pAD_REF_FIELDCOLUMN_ID:=v_cur.AD_REF_FIELDCOLUMN_ID;
    RETURN NEXT;
  END LOOP;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



select zsse_dropfunction('ad_selectfieldgroupfields');
CREATE OR REPLACE FUNCTION ad_selectfieldgroupfields(in_fieldgroup_id character varying,pad_element_id out varchar,
                           pfieldreference out varchar,pislinebreak out varchar,pAD_REF_FIELDCOLUMN_ID out varchar,pname out varchar,pname2 out varchar,
                           pTEMPLATE out varchar,pREFERENCEURL out varchar,ponchangeevent out varchar,pAD_TABLE_ID out varchar,pCOLSTOTAL out varchar,
                           pMAXLENGTH out numeric,pleadingemptycols out numeric,pBUTTONCLASS out varchar,
                           pincludesemptyitem out varchar,pAD_ValRule_ID out varchar,pstyle out varchar,pline out numeric,pdefaultvalue OUT varchar)
RETURNS SETOF RECORD AS
$BODY$ DECLARE 
v_cur record;
v_indset record;
v_count numeric;
BEGIN
  for v_cur in (SELECT ad_element_id ,  NAME,NAME2, ONCHANGEEVENT, LINE,'' as value,ad_val_rule_id,islinebreak,includesemptyitem,
        AD_REF_FIELDCOLUMN_ID, AD_REFERENCE_ID, TEMPLATE, buttonclass, REFERENCEURL, FIELDREFERENCE, AD_TABLE_ID, LEADINGEMPTYCOLS, COLSTOTAL, MAXLENGTH, STYLE,
        '' as selectorcolumnsuffix,'' as selectorcolumnname,defaultvalue
        from ad_ref_fieldcolumn where AD_REFERENCE_ID = in_fieldgroup_id  and isactive='Y')
  LOOP
    select count(*) into v_count from ad_ref_fieldcolumninstance where AD_REF_FIELDCOLUMN_ID=v_cur.AD_REF_FIELDCOLUMN_ID;
    if v_count>0 then
        for v_indset in  (select *   from  ad_ref_fieldcolumninstance where AD_REF_FIELDCOLUMN_ID=v_cur.AD_REF_FIELDCOLUMN_ID)
        LOOP
            pfieldreference:=coalesce(v_indset.fieldreference,v_cur.fieldreference);
            pislinebreak:=coalesce(v_indset.islinebreak,v_cur.islinebreak);
            pad_element_id:=coalesce(v_indset.ad_element_id,v_cur.ad_element_id);
            pTEMPLATE:=coalesce(v_indset.template,v_cur.template);
            pREFERENCEURL:=coalesce(v_indset.REFERENCEURL,v_cur.REFERENCEURL);
            ponchangeevent:=coalesce(v_indset.onchangeevent,v_cur.onchangeevent);
            pAD_TABLE_ID:=coalesce(v_indset.AD_TABLE_ID,v_cur.AD_TABLE_ID);
            pCOLSTOTAL:=coalesce(v_indset.COLSTOTAL,v_cur.COLSTOTAL);
            pMAXLENGTH:=coalesce(v_indset.MAXLENGTH,v_cur.MAXLENGTH);
            pleadingemptycols:=coalesce(v_indset.leadingemptycols,v_cur.leadingemptycols);
            pBUTTONCLASS:=coalesce(v_indset.BUTTONCLASS,v_cur.BUTTONCLASS);
            pincludesemptyitem:=coalesce(v_indset.includesemptyitem,v_cur.includesemptyitem);
            pAD_ValRule_ID:=coalesce(v_indset.AD_Val_Rule_ID,v_cur.AD_Val_Rule_ID);
            pstyle:=coalesce(v_indset.style,v_cur.style);
            pline:=coalesce(v_indset.line,v_cur.line);
            pdefaultvalue:=coalesce(v_indset.defaultvalue,v_cur.defaultvalue);
        end loop;
        pname:=v_cur.name;
        pname2:=v_cur.name2;
        pAD_REF_FIELDCOLUMN_ID:=v_cur.AD_REF_FIELDCOLUMN_ID;
    else
        pname:=v_cur.name;
        pname2:=v_cur.name2;
        pfieldreference:=v_cur.fieldreference;
        pislinebreak:=v_cur.islinebreak;
        pad_element_id:=v_cur.ad_element_id;
        pTEMPLATE:=v_cur.template;
        pREFERENCEURL:=v_cur.REFERENCEURL;
        ponchangeevent:=v_cur.onchangeevent;
        pAD_TABLE_ID:=v_cur.AD_TABLE_ID;
        pCOLSTOTAL:=v_cur.COLSTOTAL;
        pMAXLENGTH:=v_cur.MAXLENGTH;
        pleadingemptycols:=v_cur.leadingemptycols;
        pBUTTONCLASS:=v_cur.BUTTONCLASS;
        pincludesemptyitem:=v_cur.includesemptyitem;
        pAD_ValRule_ID:=v_cur.AD_Val_Rule_ID;
        pstyle:=v_cur.style;
        pline:=v_cur.line;
        pAD_REF_FIELDCOLUMN_ID:=v_cur.AD_REF_FIELDCOLUMN_ID;
        pdefaultvalue:=v_cur.defaultvalue;
    end if;
    RETURN NEXT;
  END LOOP;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION ad_getcustomtabfields(p_tab_id varchar)  RETURNS varchar AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_cur RECORD;
v_return varchar := '';
BEGIN
  for v_cur in (select name from ad_customfield where ad_tab_id=p_tab_id)
  LOOP
    if v_return!='' then
        v_return:=v_return||',';
    end if;
    v_return:=v_return||v_cur.name;
  END LOOP;
  return v_return;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_IsTabRoleReadonly(p_role_id character varying,p_tab_id character varying)
  RETURNS varchar AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_window  character varying;
v_eds  character varying;
BEGIN
  select ad_window_id into v_window from ad_tab  where ad_tab_id=p_tab_id;
  select editsetting into v_eds from ad_role_tabaccess where ad_tab_id=p_tab_id and ad_role_id=p_role_id;
  if coalesce(v_eds,'NIX')='READONLY' then
    return 'TRUE';
  end if;
  if coalesce(v_eds,'NIX')='EDIT' then
    return 'FALSE';
  end if;
  if (select isreadwrite from ad_window_access where ad_window_id=v_window and ad_role_id=p_role_id)='N' then
    return 'TRUE';
  end if;
  return 'FALSE';
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
