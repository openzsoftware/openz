

CREATE OR REPLACE FUNCTION zsse_DropFunction (p_function VARCHAR)
  RETURNS VARCHAR AS
$body$
-- SELECT (zsse_DropFunction('zsse_DropFunction')); -- 'DROP FUNCTION zsse_dropfunction (p_function VARCHAR)'
DECLARE
  v_message        VARCHAR;
  v_sql            VARCHAR:='';
  v_i              NUMERIC:=0;

  v_functionName   VARCHAR;
  v_paramsList     VARCHAR;
BEGIN
  v_message := 'DB-Object not found';
  v_functionName := LOWER(p_function);
  BEGIN
    v_message := '';
    IF ( (SELECT COUNT(*) FROM information_schema.routines ir WHERE LOWER(ir.routine_name) = v_functionName) >= 1) THEN

      DECLARE
        CUR_routines RECORD;
      BEGIN
        FOR CUR_routines IN (
          SELECT ir.routine_name, ir.specific_name
          FROM information_schema.routines ir
          WHERE LOWER(ir.routine_name) = v_functionName
          )
        LOOP

          DECLARE
            CUR_parameters RECORD;
          BEGIN
            FOR CUR_parameters IN (
              SELECT
                ir.routine_name,
                ir.specific_name,
                ip.parameter_name, ip.parameter_mode, ip.data_type
              FROM information_schema.routines ir, information_schema.parameters ip
              WHERE 1=1
                AND LOWER(ir.specific_name) = LOWER(ip.specific_name)
                AND LOWER(ir.specific_name) = CUR_routines.specific_name
              )
            LOOP
              v_paramsList := COALESCE(v_paramsList, '(') ||CUR_parameters.parameter_mode || ' ' || CUR_parameters.parameter_name || ' ' || CUR_parameters.data_type || ', ';
            END LOOP;
            v_paramsList := v_paramsList || ')';
            IF ( (v_paramsList IS NOT NULL) AND (LENGTH(v_paramsList) > 0) ) THEN
              v_paramsList := REPLACE(v_paramsList, ', )', ')');
            END IF;
            v_sql := 'DROP FUNCTION ' || v_functionName || ' ' || coalesce(v_paramsList,'()')||' cascade';
            EXECUTE(v_sql);
            v_i:=v_i+1;
            v_message := v_message   || v_sql || ' EXECUTED ---- ';
            v_paramsList :=null;
          END;
        END LOOP;
      END;
      
    --RAISE NOTICE '%', v_sql;
      v_message := v_i||' Function(s) deleted: '||v_message;
      
    ELSE
      v_message := 'INFORMATION: ' || '(Function ''' || v_functionName  || ''' not exists)';
    --RAISE NOTICE '%',v_message;
    END IF;

    RETURN substr(v_message,1,100);
  END;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM || v_sql;
    RAISE NOTICE '%', v_message;
    RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

SELECT zsse_dropfunction('zsse_droptrigger');
CREATE OR REPLACE FUNCTION zsse_droptrigger (
  p_trigger VARCHAR,
  p_table VARCHAR
)
RETURNS VARCHAR AS
$body$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.

****************************************************************************************************************************************************/
  v_message VARCHAR := '';
  v_sql VARCHAR := '';
BEGIN  
   IF ((SELECT COUNT(*) FROM user_triggers WHERE upper(p_table) = table_name AND lower(p_trigger) = lower(trigger_name)) = 1) THEN
     v_sql := 'DROP TRIGGER '|| p_trigger ||' ON '|| p_table;
     EXECUTE(v_sql);
     v_message := 'SUCCESS: ' || v_sql || ' EXECUTED';
   ELSE
     v_message := 'INFORMATION: ' || 'Trigger ' || '''' || p_trigger || '''' || ' ON ' || '''' || p_trigger || '''' ||' not found';       
   END IF;
   RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql';


SELECT zsse_dropfunction('zsse_dropview');
CREATE OR REPLACE FUNCTION zsse_dropview (p_view VARCHAR)
RETURNS VARCHAR AS
-- SELECT zsse_dropfunction('zsse_dropview');
$body$
DECLARE
  v_message    VARCHAR := '';
  v_sql        VARCHAR := '';
BEGIN
  IF ( (SELECT COUNT(*) FROM information_schema.views iv WHERE UPPER(iv.table_name) = UPPER(p_view) ) = 1) THEN
    v_sql := 'DROP VIEW ' || p_view|| ' CASCADE';
    EXECUTE(v_sql);
--  RAISE NOTICE '%', v_sql;
    v_message := 'SUCCESS: ' || v_sql || ' EXECUTED';
  ELSE
    v_message := 'INFORMATION: ' || 'View ''' || p_view  || ''' not found';
--  RAISE NOTICE '%',v_message;
  END IF;
  RETURN v_message;
END;
$body$ LANGUAGE 'plpgsql';

SELECT zsse_dropfunction('zsse_droptable');
CREATE OR REPLACE FUNCTION zsse_droptable (p_table VARCHAR)
RETURNS VARCHAR AS
-- SELECT zsse_dropfunction('zsse_dropview');
$body$
DECLARE
  v_message    VARCHAR := '';
  v_sql        VARCHAR := '';
BEGIN
  IF ( (SELECT COUNT(*) FROM information_schema.tables iv WHERE UPPER(iv.table_name) = UPPER(p_table) ) = 1) THEN
    v_sql := 'DROP TABLE ' || p_table|| ' CASCADE';
    EXECUTE(v_sql);
--  RAISE NOTICE '%', v_sql;
    v_message := 'SUCCESS: ' || v_sql || ' EXECUTED';
  ELSE
    v_message := 'INFORMATION: ' || 'Table ''' || p_table  || ''' not found';
--  RAISE NOTICE '%',v_message;
  END IF;
  RETURN v_message;
END;
$body$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsse_dropcolumn (
  p_table_name varchar,
  p_column_name varchar
)
RETURNS varchar AS
$body$
DECLARE
  v_message    VARCHAR := '';
  v_sql        VARCHAR := '';
BEGIN
  v_message := '';
  IF ( (SELECT COUNT(*) FROM information_schema.columns col WHERE col.table_name = p_table_name AND col.column_name = p_column_name) = 1) THEN
    v_sql := 'ALTER TABLE ' || p_table_name || ' DROP COLUMN ' || p_column_name;
    EXECUTE(v_sql);
    RAISE NOTICE '%', v_sql;
    v_message := v_sql || ' (Success)';
  ELSE
    v_message := '@WARNING=' || 'Column  ' || p_table_name || '.' || p_column_name  || ' not found';
    RAISE NOTICE '%',v_message;
  END IF;
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

CREATE OR REPLACE FUNCTION public.zsse_dropcontraintsafe(
  p_table varchar,
  p_contraint varchar
)
RETURNS void AS
$body$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
******************************************************************************************************************************************************************************************************************************+
Stefan Zimmermann, 04/2012, sz@zimmermann-software.de
Check if Database - Dump is created out of an opensource instance
If ORG-ID exists, there may be customer-Data - Giva warning in that case
*****************************************************************************/
  v_exists numeric;
  v_cmd    VARCHAR;
BEGIN
--RAISE NOTICE 'params: p_table=''%'', p_contraint=''%'' ', p_table, p_contraint; 
  SELECT COUNT(*) INTO v_exists FROM information_schema.table_constraints
  WHERE lower(table_name) = lower(p_table) AND lower(constraint_name) = lower(p_contraint);
  
  IF (v_exists > 0) THEN
    v_cmd := 'ALTER TABLE ' || p_table || ' DROP CONSTRAINT ' || p_contraint;
    EXECUTE v_cmd;
--  RAISE NOTICE 'SUCCESS : %', v_cmd; 
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

-- Nicht mehr vorhandene Zugriffe Löschen (Übergeordnetes Item gelöscht)
select zsse_dropContraintSafe('ad_process_access','ad_process_access_ad_process');
select zsse_dropContraintSafe('ad_task_access','ad_task_access_ad_task');
select zsse_dropContraintSafe('ad_form_access','ad_form_access_ad_form');
select zsse_dropContraintSafe('ad_table_access','ad_table_access_ad_table');
select zsse_dropContraintSafe('ad_role_tabaccess','ad_role_tabaccess_ad_tab');
select zsse_dropContraintSafe('ad_role_tabaccess_field','ad_role_tabaccess_fieldfield');
select zsse_dropContraintSafe('ad_window_access','ad_window_access_ad_window');
select zsse_dropContraintSafe('ad_workflow_access','ad_workflow_access_ad_workflow');
select zsse_dropContraintSafe('ad_role','ad_user_default_ad_role');
select zsse_dropContraintSafe('ad_role','ad_role_ad_tree_menu');

-- AD zu User Tables
ALTER TABLE ad_ep_procedures DROP CONSTRAINT ad_module_adepprocedures;

ALTER TABLE ad_extension_points DROP CONSTRAINT ad_module_adextpoints;

ALTER TABLE ad_dimension DROP CONSTRAINT ad_dimension_ad_process; 

ALTER TABLE ad_pinstance DROP CONSTRAINT ad_pinstance_ad_process;

ALTER TABLE ad_process_request DROP CONSTRAINT ad_process_request_ad_process;

ALTER TABLE ad_process_scheduling DROP CONSTRAINT ad_process_scheduling_ad_proce;

ALTER TABLE ad_preference DROP CONSTRAINT ad_window_preference;

ALTER TABLE  ad_alertrule DROP CONSTRAINT ad_alertrule_ad_tab;

ALTER TABLE ad_changelog DROP CONSTRAINT ad_changelog_ad_column;

ALTER TABLE ad_changelog DROP CONSTRAINT ad_changelog_ad_table;

ALTER TABLE ad_createfact_template DROP CONSTRAINT ad_createfact_template_ad_tabl;

ALTER TABLE  ad_impformat DROP CONSTRAINT ad_impformat_ad_table;

ALTER TABLE  ad_note DROP CONSTRAINT ad_note_ad_table;

ALTER TABLE c_acctschema_table DROP CONSTRAINT ad_table_c_acctschema_table;

ALTER TABLE c_doctype DROP CONSTRAINT c_doctype_ad_table;

ALTER TABLE c_file DROP CONSTRAINT c_file_ad_table;

ALTER TABLE fact_acct DROP CONSTRAINT fact_acct_ad_table;

ALTER TABLE ad_impformat_row DROP CONSTRAINT ad_impformat_row_ad_column;

ALTER TABLE  i_elementvalue DROP CONSTRAINT i_elementvalue_ad_column;

ALTER TABLE ad_note DROP CONSTRAINT ad_note_ad_message;

ALTER TABLE ad_user DROP CONSTRAINT ad_user_default_ad_role;

ALTER TABLE ad_user_roles DROP CONSTRAINT ad_user_roles_ad_role;

ALTER TABLE ad_alert DROP CONSTRAINT ad_alert_ad_role;

ALTER TABLE ad_alertrecipient DROP CONSTRAINT ad_alertrecipient_ad_role;

ALTER TABLE ad_role disable TRIGGER ALL;


-- Newer AD Constraints
select zsse_dropContraintSafe('ad_field','ad_field_adco');
select zsse_dropContraintSafe('ad_field','ad_process_adco');
select zsse_dropContraintSafe('ad_field','adffref');
select zsse_dropContraintSafe('ad_field','adftable');
select zsse_dropContraintSafe('ad_field','adftvalrule');


-- Cross module references
select zsse_dropContraintSafe('ad_field','ad_column_field');
select zsse_dropContraintSafe('ad_column','ad_table_column');
select zsse_dropContraintSafe('ad_field','ad_tab_field');
select zsse_dropContraintSafe('ad_field','ad_field_ad_fieldgroup');


select zsse_dropContraintSafe('ad_customcolumn','adcustcoltable');
select zsse_dropContraintSafe('ad_customcolumn','adcustcolmodule');
select zsse_dropContraintSafe('ad_customcolumn','adcustcolreference');

select zsse_dropContraintSafe('ad_customfield','adcustfieldtab');
select zsse_dropContraintSafe('ad_customfield','adcustfieldmodule');

select zsse_dropContraintSafe('ad_process_para','propara_table');
select zsse_dropContraintSafe('ad_process_para','ad_process_para_ad_reference');
select zsse_dropContraintSafe('ad_process_para','ad_process_para_ad_reference_v');
select zsse_dropContraintSafe('ad_process_para','ad_process_para_ad_val_rule');
select zsse_dropContraintSafe('ad_process_para','ad_process_para_ad_element');

-- Instance-Specific Lists and Fields..
select zsse_dropContraintSafe('ad_ref_listinstance','ad_ref_listinstance_ref');
select zsse_dropContraintSafe('ad_ref_listinstance','ad_ref_listinstance_list');
select zsse_dropContraintSafe('ad_ref_listinstance','ad_reflstin_listwindow');
select zsse_dropContraintSafe('ad_ref_listinstance','ad_reflstin_listtab');

--- Cross-Module-Table-References
select zsse_dropContraintSafe('ad_ref_table','ad_column_reftable_id');
select zsse_dropContraintSafe('ad_ref_table','ad_column_reftable_display');
select zsse_dropContraintSafe('ad_ref_table','ad_ref_table_ad_table');

---Cross Module Column References
select zsse_dropContraintSafe('ad_ref_search','ad_ref_search_ad_column');
select zsse_dropContraintSafe('ad_ref_search','ad_ref_search_ad_table');

--select zsse_dropContraintSafe('ad_fieldinstance','ad_fieldinstance_adfield');
select zsse_dropContraintSafe('ad_fieldinstance','adfinstfref');
select zsse_dropContraintSafe('ad_fieldinstance','adftable');
select zsse_dropContraintSafe('ad_fieldinstance','adftinsvalrule');
select zsse_dropContraintSafe('ad_fieldinstance','ad_fieldinstance_adco');
select zsse_dropContraintSafe('ad_fieldinstance','adfieldinstproc');
select zsse_dropContraintSafe('ad_fieldinstance','adrftfieldgroup');

--select zsse_dropContraintSafe('ad_field_trl_instance','ad_field_trl_instance_field');
select zsse_dropContraintSafe('ad_message_trl_instance','ad_message_trl_instance_message');
select zsse_dropContraintSafe('ad_element_trl_instance','ad_element_trl_instance_elem');
select zsse_dropContraintSafe('ad_fieldgroup_trl_instance','ad_fieldgroup_trl_instance_fg');
select zsse_dropContraintSafe('ad_tab_trl_instance','ad_tab_trl_instance_tab');
select zsse_dropContraintSafe('ad_menu_trl_instance','ad_menu_trl_instance_menu');

select zsse_dropContraintSafe('ad_tab_instance','ad_tab_instance_tab');

select zsse_dropContraintSafe('ad_ref_gridcolumninstance','ad_fieldinstance_gridcolumn');
select zsse_dropContraintSafe('ad_ref_gridcolumninstance','adrgftable');
select zsse_dropContraintSafe('ad_ref_gridcolumninstance','adrdsfftvalrule');
select zsse_dropContraintSafe('ad_ref_gridcolumninstance','adxfrfref');
select zsse_dropContraintSafe('ad_ref_gridcolumninstance','adgrcolinselement');

--- Cross-Module-Table-References
select zsse_dropContraintSafe('ad_ref_gridcolumn','ad_ref_gridcolumn_el');
select zsse_dropContraintSafe('ad_ref_gridcolumn','ad_ref_gridcolumn_table');
select zsse_dropContraintSafe('ad_ref_gridcolumn','ad_valrule_gridcolumn');
select zsse_dropContraintSafe('ad_ref_gridcolumn','ad_ref_gridcolumn_ref2');


select zsse_dropContraintSafe('ad_ref_fieldcolumn','ad_ref_fieldcolumn_el');
select zsse_dropContraintSafe('ad_ref_fieldcolumninstance','ad_fieldinstance_fieldcolumn');
select zsse_dropContraintSafe('ad_ref_fieldcolumninstance','adfrfref');
select zsse_dropContraintSafe('ad_ref_fieldcolumninstance','adrftable');
select zsse_dropContraintSafe('ad_ref_fieldcolumninstance','adrftvalrule');
select zsse_dropContraintSafe('ad_ref_fieldcolumninstance','adrftelement');


select zsse_dropContraintSafe('ad_ref_radiogroup_instance','adrefradioinstance');

select zsse_dropContraintSafe('ad_process_para_instance','ad_process_parainstance_tab');
select zsse_dropContraintSafe('ad_process_para_instance','proparainst_table');
select zsse_dropContraintSafe('ad_process_para_instance','adpparainst_refva');
select zsse_dropContraintSafe('ad_process_para_instance','adpparainst_refvalrule');

select zsse_dropContraintSafe('ad_referenceinstance','ad_referenceinstance_reference');
select zsse_dropContraintSafe('ad_ref_groupinstance','ad_ref_groupinstance_group');

-- Recursive Constraints 
select zsse_dropContraintSafe('ad_workflow','ad_workflow_ad_wf_node');
select zsse_dropContraintSafe('ad_module_sql','ad_module_sql_module');


alter table ad_module_sql alter COLUMN statement type text;
