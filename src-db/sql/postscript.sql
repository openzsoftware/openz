-- Nicht mehr vorhandene Zugriffe Löschen (Übergeordnetes Item gelöscht)
DELETE FROM ad_process_access WHERE NOT EXISTS (SELECT 0 FROM ad_process WHERE ad_process.ad_process_id=ad_process_access.ad_process_id);
DELETE FROM ad_task_access WHERE NOT EXISTS (SELECT 0 FROM ad_task WHERE ad_task.ad_task_id=ad_task_access.ad_task_id);
DELETE FROM ad_form_access WHERE NOT EXISTS (SELECT 0 FROM ad_form WHERE ad_form.ad_form_id=ad_form_access.ad_form_id);
DELETE FROM ad_table_access WHERE NOT EXISTS (SELECT 0 FROM ad_table WHERE ad_table.ad_table_id=ad_table_access.ad_table_id);
DELETE FROM ad_role_tabaccess WHERE NOT EXISTS (SELECT 0 FROM ad_tab WHERE ad_tab.ad_tab_id=ad_role_tabaccess.ad_tab_id);
DELETE FROM ad_role_tabaccess_field WHERE NOT EXISTS (SELECT 0 FROM ad_field WHERE ad_field.ad_field_id=ad_role_tabaccess_field.ad_field_id);
DELETE FROM ad_window_access WHERE NOT EXISTS (SELECT 0 FROM ad_window WHERE ad_window.ad_window_id=ad_window_access.ad_window_id);
DELETE FROM ad_workflow_access WHERE  not exists (SELECT 0 FROM ad_workflow WHERE ad_workflow.ad_workflow_id=ad_workflow_access.ad_workflow_id);
DELETE FROM ad_pinstance  WHERE NOT EXISTS (SELECT 0 FROM ad_process WHERE ad_process.ad_process_id=ad_pinstance.ad_process_id);
DELETE FROM ad_process_request  WHERE NOT EXISTS (SELECT 0 FROM ad_process WHERE ad_process.ad_process_id=ad_process_request.ad_process_id);
DELETE FROM ad_process_scheduling WHERE NOT EXISTS (SELECT 0 FROM ad_process WHERE ad_process.ad_process_id=ad_process_scheduling.ad_process_id);
DELETE FROM ad_alertrule where not exists(select 0 from ad_tab where ad_tab.ad_tab_id=ad_alertrule.ad_tab_id) and ad_alertrule.ad_tab_id is not null;
DELETE FROM c_file where NOT EXISTS (SELECT 0 FROM ad_table WHERE ad_table.ad_table_id=c_file.ad_table_id);
update ad_user set default_ad_role_id =null where not exists (select 0 from ad_role where ad_role_id=default_ad_role_id) and default_ad_role_id is not null;
update ad_role set ad_tree_menu_id=null where not exists (select 0 from ad_tree where ad_tree_id=ad_tree_menu_id) and ad_tree_menu_id is not null;

ALTER TABLE ad_role enable TRIGGER ALL;

ALTER TABLE ad_process_access ADD CONSTRAINT ad_process_access_ad_process FOREIGN KEY (ad_process_id)
      REFERENCES ad_process (ad_process_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_task_access ADD CONSTRAINT ad_task_access_ad_task FOREIGN KEY (ad_task_id)
      REFERENCES ad_task (ad_task_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_form_access ADD CONSTRAINT ad_form_access_ad_form FOREIGN KEY (ad_form_id)
      REFERENCES ad_form (ad_form_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_table_access ADD CONSTRAINT ad_table_access_ad_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_role_tabaccess ADD CONSTRAINT ad_role_tabaccess_ad_tab FOREIGN KEY (ad_tab_id)
      REFERENCES ad_tab (ad_tab_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_role_tabaccess_field  ADD CONSTRAINT ad_role_tabaccess_fieldfield FOREIGN KEY (ad_field_id)
      REFERENCES ad_field (ad_field_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_window_access  ADD CONSTRAINT ad_window_access_ad_window FOREIGN KEY (ad_window_id)
      REFERENCES ad_window (ad_window_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_workflow_access  ADD CONSTRAINT ad_workflow_access_ad_workflow FOREIGN KEY (ad_workflow_id)
      REFERENCES ad_workflow (ad_workflow_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

-- AD zu User Tables
ALTER TABLE ad_ep_procedures ADD CONSTRAINT ad_module_adepprocedures FOREIGN KEY (ad_module_id)
      REFERENCES ad_module (ad_module_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;


ALTER TABLE ad_extension_points ADD CONSTRAINT ad_module_adextpoints FOREIGN KEY (ad_module_id)
      REFERENCES ad_module (ad_module_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;


ALTER TABLE ad_dimension ADD CONSTRAINT ad_dimension_ad_process FOREIGN KEY (ad_process_id)
      REFERENCES ad_process (ad_process_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_pinstance ADD CONSTRAINT ad_pinstance_ad_process FOREIGN KEY (ad_process_id)
      REFERENCES ad_process (ad_process_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_process_request ADD CONSTRAINT ad_process_request_ad_process FOREIGN KEY (ad_process_id)
      REFERENCES ad_process (ad_process_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE  ad_process_scheduling ADD CONSTRAINT ad_process_scheduling_ad_proce FOREIGN KEY (ad_process_id)
      REFERENCES ad_process (ad_process_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_preference ADD CONSTRAINT ad_window_preference FOREIGN KEY (ad_window_id)
      REFERENCES ad_window (ad_window_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;


ALTER TABLE ad_alertrule ADD CONSTRAINT ad_alertrule_ad_tab FOREIGN KEY (ad_tab_id)
      REFERENCES ad_tab (ad_tab_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_changelog ADD CONSTRAINT ad_changelog_ad_column FOREIGN KEY (ad_column_id)
      REFERENCES ad_column (ad_column_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_changelog ADD CONSTRAINT ad_changelog_ad_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_createfact_template ADD CONSTRAINT ad_createfact_template_ad_tabl FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE ad_impformat ADD CONSTRAINT ad_impformat_ad_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_note ADD CONSTRAINT ad_note_ad_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE c_acctschema_table ADD CONSTRAINT ad_table_c_acctschema_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE c_doctype ADD CONSTRAINT c_doctype_ad_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE c_file ADD CONSTRAINT c_file_ad_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE fact_acct ADD CONSTRAINT fact_acct_ad_table FOREIGN KEY (ad_table_id)
      REFERENCES ad_table (ad_table_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_impformat_row ADD CONSTRAINT ad_impformat_row_ad_column FOREIGN KEY (ad_column_id)
      REFERENCES ad_column (ad_column_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE i_elementvalue ADD CONSTRAINT i_elementvalue_ad_column FOREIGN KEY (ad_column_id)
      REFERENCES ad_column (ad_column_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_note ADD CONSTRAINT ad_note_ad_message FOREIGN KEY (ad_message_id)
      REFERENCES ad_message (ad_message_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_user ADD CONSTRAINT ad_user_default_ad_role FOREIGN KEY (default_ad_role_id)
      REFERENCES ad_role (ad_role_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;
      
alter table ad_role add constraint ad_role_ad_tree_menu FOREIGN KEY (ad_tree_menu_id) REFERENCES ad_tree(ad_tree_id);

ALTER TABLE  ad_user_roles ADD CONSTRAINT ad_user_roles_ad_role FOREIGN KEY (ad_role_id)
      REFERENCES ad_role (ad_role_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE ad_alert ADD CONSTRAINT ad_alert_ad_role FOREIGN KEY (ad_role_id)
      REFERENCES ad_role (ad_role_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE ad_alertrecipient ADD CONSTRAINT ad_alertrecipient_ad_role FOREIGN KEY (ad_role_id)
      REFERENCES ad_role (ad_role_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

alter table ad_field add constraint ad_field_adco FOREIGN KEY  (ad_callout_id) REFERENCES ad_callout(ad_callout_id);
alter table ad_field add constraint ad_process_adco FOREIGN KEY  (ad_process_id) REFERENCES ad_process(ad_process_id);
alter table ad_field add constraint adffref FOREIGN KEY (fieldreference) REFERENCES ad_reference(ad_reference_id);
alter table ad_field add constraint adftable FOREIGN KEY (tablereference) REFERENCES ad_table(ad_table_id);
delete from ad_field where ad_field.validationrule is not null and not exists (select 0 from ad_val_rule where ad_val_rule.ad_val_rule_id=ad_field.validationrule);
alter table ad_field add constraint adftvalrule FOREIGN KEY (validationrule) REFERENCES ad_val_rule(ad_val_rule_id);
-- Cross module references
delete from ad_field where not exists (select 0 from ad_column where ad_column.ad_column_id=ad_field.ad_column_id);
alter table ad_field add constraint ad_column_field FOREIGN KEY (ad_column_id) REFERENCES ad_column(ad_column_id) DEFERRABLE;
alter table ad_column add constraint ad_table_column FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id) ON DELETE CASCADE;
alter table ad_field add CONSTRAINT ad_tab_field FOREIGN KEY (ad_tab_id) REFERENCES ad_tab(ad_tab_id) ON DELETE CASCADE;
alter TABLE ad_field add CONSTRAINT ad_field_ad_fieldgroup FOREIGN KEY (ad_fieldgroup_id) REFERENCES ad_fieldgroup(ad_fieldgroup_id) DEFERRABLE;


alter table ad_process_para add constraint propara_table FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id);
alter table ad_process_para add constraint ad_process_para_ad_reference FOREIGN KEY (ad_reference_id) REFERENCES ad_reference(ad_reference_id);
alter table ad_process_para add constraint ad_process_para_ad_reference_v FOREIGN KEY (ad_reference_value_id) REFERENCES ad_reference(ad_reference_id);
alter table ad_process_para add constraint ad_process_para_ad_val_rule FOREIGN KEY (ad_val_rule_id) REFERENCES ad_val_rule(ad_val_rule_id);
alter table ad_process_para add constraint ad_process_para_ad_element FOREIGN KEY (ad_element_id) REFERENCES ad_element(ad_element_id);


-- Instance Specific AD-Tables

DELETE FROM ad_ref_listinstance WHERE NOT EXISTS (SELECT 0 FROM ad_reference  WHERE ad_reference.ad_reference_id=ad_ref_listinstance.ad_reference_id);
DELETE FROM ad_ref_listinstance WHERE NOT EXISTS (SELECT 0 FROM ad_ref_list  WHERE ad_ref_list.ad_ref_list_id=ad_ref_listinstance.ad_ref_list_id);
ALTER TABLE ad_ref_listinstance add constraint ad_ref_listinstance_ref  FOREIGN KEY  (ad_reference_id)  REFERENCES ad_reference(ad_reference_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE ad_ref_listinstance add constraint ad_ref_listinstance_list  FOREIGN KEY  (ad_ref_list_id)  REFERENCES ad_ref_list(ad_ref_list_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
DELETE FROM ad_ref_listinstance WHERE ad_window_id is not null and NOT EXISTS (SELECT 0 FROM ad_window  WHERE ad_window.ad_window_id=ad_ref_listinstance.ad_window_id);
alter table ad_ref_listinstance add CONSTRAINT ad_reflstin_listwindow FOREIGN KEY (ad_window_id) REFERENCES ad_window(ad_window_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE SET NULL;
DELETE FROM ad_ref_listinstance WHERE ad_tab_id is not null and NOT EXISTS (SELECT 0 FROM ad_tab  WHERE ad_tab.ad_tab_id=ad_ref_listinstance.ad_tab_id);
alter table ad_ref_listinstance add CONSTRAINT ad_reflstin_listtab FOREIGN KEY (ad_tab_id) REFERENCES ad_tab(ad_tab_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE SET NULL;

--- Cross-Module-Table-References
DELETE FROM ad_ref_table where not exists (select 0 from ad_column where ad_column_id=ad_ref_table.ad_key);
DELETE FROM ad_ref_table where not exists (select 0 from ad_column where ad_column_id=ad_ref_table.ad_display);
DELETE FROM ad_ref_table where not exists (select 0 from ad_table where ad_table_id=ad_ref_table.ad_table_id);
alter table ad_ref_table add CONSTRAINT ad_column_reftable_display FOREIGN KEY (ad_display) REFERENCES ad_column(ad_column_id);
alter table ad_ref_table add CONSTRAINT ad_column_reftable_id  FOREIGN KEY (ad_key) REFERENCES ad_column(ad_column_id);
alter table ad_ref_table add CONSTRAINT ad_ref_table_ad_table FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id);

--- Cross Module Column references
alter table ad_ref_search add constraint ad_ref_search_ad_column FOREIGN KEY (ad_column_id) REFERENCES ad_column(ad_column_id);
alter table ad_ref_search add constraint ad_ref_search_ad_table  FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id);

delete from ad_customcolumn where not exists (select 0 from ad_module where  ad_customcolumn.ad_module_id=ad_module.ad_module_id);
alter table ad_customcolumn add CONSTRAINT adcustcolmodule  FOREIGN KEY (ad_module_id) REFERENCES ad_module(ad_module_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
delete from ad_customcolumn where not exists (select 0 from ad_table where  ad_customcolumn.ad_table_id=ad_table.ad_table_id);
alter table ad_customcolumn add CONSTRAINT adcustcoltable  FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
delete from ad_customcolumn where not exists (select 0 from ad_reference where  ad_reference.ad_reference_id=ad_customcolumn.ad_reference_id);
alter table ad_customcolumn add CONSTRAINT adcustcolreference  FOREIGN KEY (ad_reference_id) REFERENCES ad_reference(ad_reference_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

delete from ad_customfield  where not exists (select 0 from ad_tab where ad_tab.ad_tab_id=ad_customfield.ad_tab_id);
alter table ad_customfield  add CONSTRAINT adcustfieldtab FOREIGN KEY (ad_tab_id) REFERENCES ad_tab(ad_tab_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
delete from ad_customfield  where not exists (select 0 from ad_module where  ad_customfield.ad_module_id=ad_module.ad_module_id);
alter table ad_customfield add CONSTRAINT adcustfieldmodule  FOREIGN KEY (ad_module_id) REFERENCES ad_module(ad_module_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

delete from ad_field_trl_instance  WHERE NOT EXISTS (SELECT 0 FROM ad_field_v  WHERE ad_field_v.ad_field_v_id=ad_field_trl_instance.ad_field_v_id);
--ALTER TABLE ad_field_trl_instance add constraint ad_field_trl_instance_field  FOREIGN KEY  (ad_field_v_id)  REFERENCES ad_field(ad_field_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

delete from ad_message_trl_instance WHERE NOT EXISTS (SELECT 0 FROM ad_message  WHERE ad_message.ad_message_id=ad_message_trl_instance.ad_message_id);
ALTER TABLE ad_message_trl_instance add constraint ad_message_trl_instance_message  FOREIGN KEY  (ad_message_id)  REFERENCES ad_message(ad_message_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

delete from ad_element_trl_instance WHERE NOT EXISTS (SELECT 0 FROM ad_element  WHERE ad_element.ad_element_id=ad_element_trl_instance.ad_element_id);
ALTER TABLE ad_element_trl_instance add constraint ad_element_trl_instance_elem  FOREIGN KEY  (ad_element_id)  REFERENCES ad_element(ad_element_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;


delete from ad_fieldgroup_trl_instance WHERE NOT EXISTS (SELECT 0 FROM ad_fieldgroup  WHERE ad_fieldgroup.ad_fieldgroup_id=ad_fieldgroup_trl_instance.ad_fieldgroup_id);
ALTER TABLE ad_fieldgroup_trl_instance ADD CONSTRAINT ad_fieldgroup_trl_instance_fg FOREIGN KEY  (ad_fieldgroup_id) REFERENCES ad_fieldgroup(ad_fieldgroup_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

delete from ad_tab_trl_instance WHERE NOT EXISTS (SELECT 0 FROM ad_tab  WHERE ad_tab_trl_instance.ad_tab_id=ad_tab.ad_tab_id);
ALTER TABLE ad_tab_trl_instance ADD CONSTRAINT ad_tab_trl_instance_tab FOREIGN KEY  (ad_tab_id) REFERENCES ad_tab(ad_tab_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

delete from ad_menu_trl_instance WHERE NOT EXISTS (SELECT 0 FROM ad_menu  WHERE ad_menu.ad_menu_id=ad_menu_trl_instance.ad_menu_id);
ALTER TABLE ad_menu_trl_instance ADD CONSTRAINT ad_menu_trl_instance_menu FOREIGN KEY  (ad_menu_id) REFERENCES ad_menu(ad_menu_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

DELETE FROM ad_tab_instance WHERE NOT EXISTS (SELECT 0 FROM ad_tab WHERE ad_tab.ad_tab_id=ad_tab_instance.ad_tab_id);
ALTER TABLE ad_tab_instance add constraint ad_tab_instance_tab FOREIGN KEY (ad_tab_id) REFERENCES ad_tab(ad_tab_id) on delete cascade;

DELETE FROM ad_ref_gridcolumninstance WHERE NOT EXISTS (SELECT 0 FROM ad_ref_gridcolumn WHERE ad_ref_gridcolumn.ad_ref_gridcolumn_id=ad_ref_gridcolumninstance.ad_ref_gridcolumn_id);
ALTER TABLE ad_ref_gridcolumninstance ADD CONSTRAINT ad_fieldinstance_gridcolumn FOREIGN KEY  (ad_ref_gridcolumn_id) REFERENCES ad_ref_gridcolumn(ad_ref_gridcolumn_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_gridcolumninstance a set colreference=null where not exists (select 0 from ad_reference b where b.ad_reference_id=a.colreference);
alter table ad_ref_gridcolumninstance add constraint adxfrfref FOREIGN KEY (colreference) REFERENCES ad_reference(ad_reference_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_gridcolumninstance a set ad_table_id=null where not exists (select 0 from ad_table b where b.ad_table_id=a.ad_table_id);
alter table ad_ref_gridcolumninstance add constraint adrgftable FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_gridcolumninstance a set ad_val_rule_id=null where not exists (select 0 from ad_val_rule b where b.ad_val_rule_id=a.ad_val_rule_id);
alter table ad_ref_gridcolumninstance add constraint adrdsfftvalrule FOREIGN KEY (ad_val_rule_id) REFERENCES ad_val_rule(ad_val_rule_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_gridcolumninstance a set ad_element_id=null where not exists (select 0 from ad_element b where b.ad_element_id=a.ad_element_id);
alter table ad_ref_gridcolumninstance add constraint adgrcolinselement FOREIGN KEY (ad_element_id) REFERENCES ad_element(ad_element_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

--- Cross-Module-Table-References
update ad_ref_gridcolumn set ad_element_id=null where not exists (select 0 from ad_element where  ad_element.ad_element_id=ad_ref_gridcolumn.ad_element_id);
alter table ad_ref_gridcolumn add constraint ad_ref_gridcolumn_el FOREIGN KEY (ad_element_id) REFERENCES ad_element(ad_element_id);
update ad_ref_gridcolumn set ad_table_id=null where not exists (select 0 from ad_table where  ad_table.ad_table_id=ad_ref_gridcolumn.ad_table_id);
alter table ad_ref_gridcolumn add constraint ad_ref_gridcolumn_table FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id);
update ad_ref_gridcolumn set ad_val_rule_id=null where not exists (select 0 from ad_val_rule where  ad_val_rule.ad_val_rule_id=ad_ref_gridcolumn.ad_val_rule_id);
alter table ad_ref_gridcolumn add constraint ad_valrule_gridcolumn FOREIGN KEY (ad_val_rule_id) REFERENCES ad_val_rule(ad_val_rule_id);
update ad_ref_gridcolumn set colreference=null  where not exists (select 0 from ad_reference  where ad_reference.ad_reference_id=ad_ref_gridcolumn.colreference);
alter table ad_ref_gridcolumn add constraint  ad_ref_gridcolumn_ref2 FOREIGN KEY (colreference) REFERENCES ad_reference(ad_reference_id);



DELETE FROM ad_fieldinstance  WHERE NOT EXISTS (SELECT 0 FROM ad_field_v  WHERE ad_field_v.ad_field_v_id=ad_fieldinstance.ad_field_v_id);
--ALTER TABLE ad_fieldinstance ADD CONSTRAINT ad_fieldinstance_adfield FOREIGN KEY  (ad_field_id) REFERENCES ad_field(ad_field_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_fieldinstance a set ad_callout_id=null where not exists (select 0 from ad_callout b where b.ad_callout_id=a.ad_callout_id);
alter table ad_fieldinstance add constraint ad_fieldinstance_adco FOREIGN KEY  (ad_callout_id) REFERENCES ad_callout(ad_callout_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_fieldinstance a set ad_process_id=null where not exists (select 0 from ad_process b where b.ad_process_id=a.ad_process_id);
alter table ad_fieldinstance add constraint adfieldinstproc FOREIGN KEY  (ad_process_id) REFERENCES ad_process(ad_process_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_fieldinstance a set fieldreference=null where not exists (select 0 from ad_reference b where b.ad_reference_id=a.fieldreference);
alter table ad_fieldinstance add constraint adfinstfref FOREIGN KEY (fieldreference) REFERENCES ad_reference(ad_reference_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_fieldinstance a set ad_table_id=null where not exists (select 0 from ad_table b where b.ad_table_id=a.ad_table_id);
alter table ad_fieldinstance add constraint adftable FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_fieldinstance a set ad_val_rule_id=null where not exists (select 0 from ad_val_rule b where b.ad_val_rule_id=a.ad_val_rule_id);
alter table ad_fieldinstance add constraint adftinsvalrule FOREIGN KEY (ad_val_rule_id) REFERENCES ad_val_rule(ad_val_rule_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_fieldinstance a set ad_fieldgroup_id=null where not exists (select 0 from ad_fieldgroup b where b.ad_fieldgroup_id=a.ad_fieldgroup_id);
alter table ad_fieldinstance add constraint adrftfieldgroup FOREIGN KEY (ad_fieldgroup_id) REFERENCES ad_fieldgroup(ad_fieldgroup_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

DELETE FROM ad_ref_radiogroup_instance WHERE NOT EXISTS (SELECT 0 FROM ad_ref_radiogroup WHERE ad_ref_radiogroup.ad_ref_radiogroup_id=ad_ref_radiogroup_instance.ad_ref_radiogroup_id);
ALTER TABLE ad_ref_radiogroup_instance add constraint adrefradioinstance FOREIGN KEY (ad_ref_radiogroup_id) REFERENCES ad_ref_radiogroup(ad_ref_radiogroup_id) on delete cascade;


DELETE FROM ad_process_para_instance WHERE NOT EXISTS (SELECT 0 FROM ad_process_para WHERE ad_process_para.ad_process_para_id=ad_process_para_instance.ad_process_para_id);
ALTER TABLE ad_process_para_instance add constraint ad_process_parainstance_tab FOREIGN KEY (ad_process_para_id) REFERENCES ad_process_para(ad_process_para_id) on delete cascade;
update ad_process_para_instance a set ad_table_id=null where not exists (select 0 from ad_table b where b.ad_table_id=a.ad_table_id);
alter table ad_process_para_instance add constraint proparainst_table FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id);
update ad_process_para_instance a set ad_reference_value_id=null where not exists (select 0 from ad_reference b where b.ad_reference_id=a.ad_reference_value_id);
alter table ad_process_para_instance add constraint adpparainst_refva FOREIGN KEY (ad_reference_value_id) REFERENCES ad_reference(ad_reference_id);
update ad_process_para_instance a set ad_val_rule_id=null where not exists (select 0 from ad_val_rule b where b.ad_val_rule_id=a.ad_val_rule_id);
alter table ad_process_para_instance add constraint adpparainst_refvalrule FOREIGN KEY (ad_val_rule_id) REFERENCES ad_val_rule(ad_val_rule_id);


update ad_ref_fieldcolumn set ad_element_id=null WHERE NOT EXISTS (SELECT 0 FROM ad_element where ad_element.ad_element_id=ad_ref_fieldcolumn.ad_element_id) and ad_element_id is not null;
ALTER TABLE  ad_ref_fieldcolumn add constraint ad_ref_fieldcolumn_el FOREIGN KEY (ad_element_id) REFERENCES ad_element(ad_element_id) DEFERRABLE;
DELETE FROM ad_ref_fieldcolumninstance WHERE NOT EXISTS (SELECT 0 FROM ad_ref_fieldcolumn WHERE ad_ref_fieldcolumn.ad_ref_fieldcolumn_id=ad_ref_fieldcolumninstance.ad_ref_fieldcolumn_id);
ALTER TABLE ad_ref_fieldcolumninstance ADD CONSTRAINT ad_fieldinstance_fieldcolumn FOREIGN KEY  (ad_ref_fieldcolumn_id) REFERENCES ad_ref_fieldcolumn(ad_ref_fieldcolumn_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_fieldcolumninstance a set ad_table_id=null where not exists (select 0 from ad_table b where b.ad_table_id=a.ad_table_id);
alter table ad_ref_fieldcolumninstance add constraint adrftable FOREIGN KEY (ad_table_id) REFERENCES ad_table(ad_table_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_fieldcolumninstance a set fieldreference=null where not exists (select 0 from ad_reference b where b.ad_reference_id=a.fieldreference);
alter table ad_ref_fieldcolumninstance add constraint adfrfref FOREIGN KEY (fieldreference) REFERENCES ad_reference(ad_reference_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_fieldcolumninstance a set ad_val_rule_id=null where not exists (select 0 from ad_val_rule b where b.ad_val_rule_id=a.ad_val_rule_id);
alter table ad_ref_fieldcolumninstance add constraint adrftvalrule FOREIGN KEY (ad_val_rule_id) REFERENCES ad_val_rule(ad_val_rule_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
update ad_ref_fieldcolumninstance a set ad_element_id=null where not exists (select 0 from ad_element b where b.ad_element_id=a.ad_element_id);
alter table ad_ref_fieldcolumninstance add constraint adrftelement FOREIGN KEY (ad_element_id) REFERENCES ad_element(ad_element_id)  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;


DELETE FROM ad_referenceinstance WHERE NOT EXISTS (SELECT 0 FROM ad_reference WHERE ad_referenceinstance.ad_referenceinstance_id=ad_referenceinstance.ad_reference_id);
ALTER table ad_referenceinstance add constraint ad_referenceinstance_reference  FOREIGN KEY (ad_reference_id) REFERENCES ad_reference(ad_reference_id) on delete cascade;

DELETE FROM ad_ref_groupinstance WHERE NOT EXISTS (SELECT 0 FROM ad_ref_group WHERE ad_ref_groupinstance.ad_ref_group_id=ad_ref_group.ad_ref_group_id);
ALTER table ad_ref_groupinstance add constraint ad_ref_groupinstance_group  FOREIGN KEY (ad_ref_group_id) REFERENCES ad_ref_group(ad_ref_group_id) on delete cascade;

-- Recursive Constraints 
ALTER TABLE ad_workflow  ADD CONSTRAINT  ad_workflow_ad_wf_node FOREIGN KEY (ad_wf_node_id) REFERENCES ad_wf_node(ad_wf_node_id);
ALTER TABLE ad_module_sql ADD constraint ad_module_sql_module  FOREIGN KEY  (ad_module_id)  REFERENCES ad_module(ad_module_id)   MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;



-- Nachlauf Aktionen
-- Role-ORG-Access reparieren (Zuriffslisten für Session-Variablen)
UPDATE ad_role_orgaccess SET updated=updated;

-- POST Update Actions
update ad_module set isindevelopment='Y';
update ad_role_orgaccess set updated=updated;
--
-- Workaround Textinterfaces
update ad_textinterfaces set isused='Y';
-- Standard  SQL Einstellungen ausführen
select zsse_instancesqlexecute('Y') from dual;
-- Instance-Spezifische  SQL Einstellungen ausführen
select zsse_instancesqlexecute('N') from dual;
-- Alle Module updaten
update ad_module set isindevelopment='N';

-- Individuelle Menues: Gelöschte Einträge entfernen, neue Hinzufügen:

CREATE OR REPLACE FUNCTION ad_syncmenues() RETURNS void LANGUAGE plpgsql
AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/
v_sql varchar:=''; 
v_cur RECORD;
v_cur2 RECORD;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
BEGIN
        for v_cur in (select * from ad_tree where treetype='MM' and ad_tree_id!='10')
        LOOP
                delete from AD_TreeNode where AD_Tree_ID=v_cur.AD_Tree_ID and not exists (select 0 from AD_TreeNode t where t.ad_tree_id='10' and t.node_id=AD_TreeNode.node_id);
                insert into AD_TreeNode (AD_TreeNode_ID, AD_Client_ID, AD_Org_ID, IsActive,      Created, CreatedBy, Updated,      UpdatedBy, AD_Tree_ID, Node_ID, Parent_ID, SeqNo) 
                select get_uuid(),AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated,UpdatedBy, v_cur.AD_Tree_ID, Node_ID,Parent_ID, SeqNo from ad_treenode 
                where ad_tree_id='10' and not exists (select 0 from AD_TreeNode t where t.ad_tree_id=v_cur.AD_Tree_ID and t.node_id=AD_TreeNode.node_id);
        END LOOP;
END ; $_$;

select ad_syncmenues();

CREATE OR REPLACE FUNCTION add_futurefinanceyears() RETURNS void LANGUAGE plpgsql
AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/
v_currentyear character varying;
v_year character varying;
v_count numeric=0;
v_countyears numeric=0;
v_existingyear numeric=0;
v_calendar character varying;
BEGIN
    select c_calendar_id into v_calendar from  c_calendar  where isactive='Y' limit 1;
    v_currentyear:=(to_char(now(),'YYYY'));
    select count(*) into v_countyears from c_year where year=v_currentyear;
    if(to_number(v_countyears)<1) then
        v_year:=v_currentyear;
        raise notice '%' , v_currentyear;
        insert into c_year (c_year_id, ad_client_id, ad_org_id, isactive, created, updated, createdby, updatedby, year, c_calendar_id, description) values (get_uuid(), 'C726FEC915A54A0995C568555DA5BB3C','0','Y',now(),now(),'100','100', v_year, v_calendar,v_year);
        v_count:=v_count+1;
    end if;
    
    v_year:=to_char(to_number(v_currentyear)+1);
    select count(*) into v_countyears from c_year where year=v_year;
    if (to_number(v_countyears)<1) then
        raise notice '%' , v_year;
        insert into c_year (c_year_id, ad_client_id, ad_org_id, isactive, created, updated, createdby, updatedby, year, c_calendar_id, description) values (get_uuid(), 'C726FEC915A54A0995C568555DA5BB3C','0','Y',now(),now(),'100','100', v_year, v_calendar,v_year);
        v_count:=v_count+1;
    end if;
    
    raise notice '%' , v_count;

END ; $_$;

select add_futurefinanceyears();


CREATE OR REPLACE FUNCTION add_financesettings() RETURNS void LANGUAGE plpgsql
AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/
v_currentyear character varying;
v_year character varying;
v_count numeric=0;
v_countyears numeric=0;
v_existingyear numeric=0;
v_calendar character varying;
BEGIN
    if (select count(*) from fact_acct)=0 then
        
    end if;
    raise notice '%' , v_count;
END ; $_$;

select ad_activatehistorytriggers();

update ad_preference set value=coalesce((select releaseno from ad_system),'N') where attribute='SUSPENDHISTORY';
update ad_system set releaseno=null;
