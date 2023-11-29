/* productioncontrol.sql */
 
   
SELECT zsse_dropfunction('zssm_beginworkstep');

CREATE OR REPLACE FUNCTION zssm_beginworkstep(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Overload for Process Scheduler

*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='';
v_Org   character varying;
v_conumption_id character varying;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID,i.ad_org_id into v_Record_ID, v_User,v_Org from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    select out_messagetext, out_createdId into v_message,v_conumption_id from zssm_beginworkstep(v_Record_ID,v_User,v_Org,'Y');
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1 , v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  IF(p_pinstance_id IS NOT NULL) THEN
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  ELSE
    RAISE EXCEPTION '%', SQLERRM;
  END IF;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
  
  
  
  
CREATE OR REPLACE FUNCTION zssm_beginworkstep(p_workstep character varying, p_user character varying,p_org character varying, p_getmaterial varchar,OUT out_messagetext character varying, OUT out_createdId character varying)
  RETURNS setof record AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 Begins a TASK (Gets Material From Stock)
Checks
*****************************************************/
v_proj    character varying;
v_stat    character varying;
v_count   numeric;

v_taskresp    character varying;
v_ismanager   character varying;
v_startonlywithcompletemat character varying;
v_forcematerialscan character varying;

BEGIN
if p_workstep is not null then
    out_messagetext:='';
    select c_project_id,startonlywithcompletematerial,forcematerialscan into v_proj,v_startonlywithcompletemat,v_forcematerialscan from c_projecttask where c_projecttask_id=p_workstep;
    
    -- Is Project started?
    select projectstatus into v_stat from c_project where c_project_id=v_proj;
    if v_stat!='OR' then
       RAISE EXCEPTION '%', '@zspm_DoNotTaskWhenProjectNotReady@';
    end if;
    -- Are all  Tasks, this task is dependent on closed
    -- 
    if NOT zssm_is_dependendtasks_complete(p_workstep) then
        RAISE EXCEPTION '%', '@zssm_DependentsNotReadyCannotStart@';
    end if;
    -- all Materail needed musrt be available.
    if NOT zssm_is_material_complete(p_workstep) and v_startonlywithcompletemat='Y' then
       RAISE EXCEPTION '%', '@zssm_MaterialNotAvailabelCannotStart@';
    end if;
    if p_getmaterial='Y' then
        if zssm_is_material_complete(p_workstep) then
            -- Get all Material from Inventory
            select  out_message,out_internalconsumption_id into out_messagetext,out_createdId from zssm_GetMaterialIntoWorkstep(p_workstep,p_User);
        else
            out_messagetext:='@zssm_materialNotCompleteRequireManualStockTransaction@';
        end if;
    else
             out_messagetext:='@zssm_workstepStartedWithManualStockTransaction@';
    end if;
    --
    update c_projecttask set taskbegun='Y',started=now(),updated=now(),updatedby=p_user where c_projecttask_id=p_workstep;
    --
end if;
    return next;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;





CREATE OR REPLACE FUNCTION zssm_endworkstep(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Projects, Ends a TASK (Sends Material To Stock)
Checks
*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='';
v_project    character varying;
v_count   numeric;
v_Org   character varying;
v_isassemble varchar;
Cur_Parameter record;
v_qty numeric;
v_qty_orig  numeric;
v_rejectremaining varchar;
v_remaininglocator varchar;
v_DocumentNo varchar;
v_Serial varchar;
v_Line numeric:=0;
v_uid varchar;
v_lineUUId varchar;
v_issuelocator varchar;
v_reclocator varchar;
v_qtyprocessed numeric;
v_isserial boolean:=false;
v_product varchar;
v_uom varchar;
v_client varchar;
v_cur record;
v_cur2 record;
v_cur3 record;
v_cur4 record;
v_dependent varchar;
v_stockrotation varchar;
v_orig_qty numeric;
v_orig_prod numeric;
v_snrline snr_internal_consumptionline%rowtype;
v_batch   varchar;
v_closetask varchar;
v_proj varchar;
v_cat varchar;
v_warehouse varchar;
v_locator varchar;
v_ismanager varchar;
v_isworker varchar;
v_notrx varchar:='N';
v_snrmstr varchar;
v_btchmstr varchar;
v_currbomid varchar;
v_isvendorsupply varchar;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID,i.ad_org_id,i.ad_client_id into v_Record_ID, v_User,v_Org,v_client from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
       v_Org:='0';
       v_client:='C726FEC915A54A0995C568555DA5BB3C';
       v_rejectremaining:='N';
       v_closetask := 'Y';
       select qty into v_qty from c_projecttask where c_projecttask_id=v_Record_ID;
    else
        v_message := '';
        FOR Cur_Parameter IN
          (SELECT para.*
           FROM ad_pinstance pi, ad_pinstance_Para para
           WHERE 1=1
            AND pi.ad_pinstance_ID = para.ad_pinstance_ID
            AND pi.ad_pinstance_ID = p_pinstance_ID
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('qtyreturned') ) THEN
            v_qty := Cur_Parameter.p_number;
          END IF;
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('rejectremaining') ) THEN
            v_rejectremaining := Cur_Parameter.p_string;
          END IF;
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('closetask') ) THEN
            v_closetask := Cur_Parameter.p_string;
          END IF;
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('m_locator_id') ) THEN
            v_remaininglocator := Cur_Parameter.p_string;
          END IF;
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('nomaterialtrx') ) THEN
            v_notrx := Cur_Parameter.p_string;
          END IF;
        END LOOP; -- Get Parameter
        RAISE NOTICE '%','Updating pinstance - Processing ' || p_pinstance_ID;
    end if;
    select c_project_id,assembly,m_product_id,issuing_locator,qty into v_project,v_isassemble,v_product,v_issuelocator,v_qty_orig from c_projecttask where c_projecttask_id=v_Record_ID;
    select p.c_project_id,p.projectcategory,p.m_warehouse_id into v_proj, v_cat,v_warehouse from c_projecttask pt,c_project p where pt.c_project_id=p.c_project_id and pt.c_projecttask_id=v_Record_ID; 
    -- Determin Stock Locator for Project-Production
    if v_cat ='P' and v_product is not null then 
        if v_warehouse is null then
            select m_warehouse_id into v_warehouse from m_warehouse where ad_org_id in ('0',v_org) and isactive='Y' and isshipper='N' and isblocked='N' order by created  limit 1;
        end if;
        select p.m_locator_id into v_locator from m_product p,m_locator l where l.m_locator_id=p.m_locator_id and l.m_warehouse_id=v_warehouse and l.isactive='Y' and p.m_product_id=v_product;
        if v_locator is null then
            select p.m_locator_id into v_locator from m_product_org p,m_locator l where l.m_locator_id=p.m_locator_id and l.m_warehouse_id=v_warehouse and l.isactive='Y' 
            and p.m_product_id=v_product and p.isproduction='Y' and p.isactive='Y';
        end if;
        if v_locator is null then
            RAISE EXCEPTION '%', '@NoLocator4ProdTransactionFound@';
        end if;
        -- Transaction Locator
        v_issuelocator:=v_locator;
        -- Workflow ?
        if c_getconfigoption('projectmangerworkflow',v_Org)='Y' then 
            -- Only Task Responsible or Project Manager can do this
            select bp.isprojectmanager,bp.isworker into v_ismanager,v_isworker from c_bpartner bp,ad_user ad where ad.c_bpartner_id=bp.c_bpartner_id and ad.ad_user_id=v_User;
            if NOT (coalesce(v_ismanager,'N')='Y' or (coalesce(v_isworker,'N')='Y' and 
                                                    (select responsible_id from c_project where c_project_id=v_proj)=v_User)) then
                RAISE EXCEPTION '%', '@zspm_OnlyManagerUser@';
            end if;
        end if;
    end if;
    
    --
    -- Some Checks before...
    select qty,qtyproduced,case when v_Org='0' then ad_org_id else v_Org end,supply2vendor  into v_orig_qty,v_orig_prod,v_Org,v_isvendorsupply from c_projecttask where c_projecttask_id=v_Record_ID;
    if v_orig_qty=0 then v_orig_qty:=1; end if;
    select count(*) into v_Count from zspm_projecttaskbom where c_projecttask_id=v_Record_ID and (quantity/v_orig_qty)*(v_orig_prod+v_qty)>abs(qtyreceived);
    if v_count>0 then
       RAISE EXCEPTION '%', '@zssm_NotAllMaterialinWorkstepChangeQtys@';
    end if;
    --select count(*) into v_Count from  zspm_ptaskfeedbackline where c_projecttask_id=v_Record_ID and isprocessed='Y';
    --if v_count=0 then
    --   RAISE EXCEPTION '%', '@zssm_NoFeedbackCannotFinish@';
    --end if;
    /*
    select cl.M_INTERNAL_CONSUMPTIONLINE_ID,c.documentno into v_Uid,v_DocumentNo from M_INTERNAL_CONSUMPTION c,M_INTERNAL_CONSUMPTIONLINE cl 
           where c.processed='N' and cl.M_INTERNAL_CONSUMPTION_ID = c.M_INTERNAL_CONSUMPTION_ID and cl.c_projecttask_id=v_Record_ID LIMIT 1;
    if v_Uid is not null then
          RAISE EXCEPTION '%','@DraftExistsCannotGenerate@ :' || zsse_htmlLinkDirectKey('../InternalMaterialMovements/Lines_Relation.html',v_Uid,v_DocumentNo);
    end if;
    */
    -- Prepare Transaction Document
    select ad_sequence_doc('Production',v_org,'Y') into v_DocumentNo;
    select get_uuid() into v_uid;
    -- Is Assembly-Task
    if v_isassemble ='Y' and v_cat in ('P','PRO') then
        select count(*) into v_count from M_INTERNAL_CONSUMPTION c,M_INTERNAL_CONSUMPTIONLINE cl 
           where c.processed='N' and cl.M_INTERNAL_CONSUMPTION_ID = c.M_INTERNAL_CONSUMPTION_ID and cl.c_projecttask_id=v_Record_ID and MOVEMENTTYPE='P+';
        if v_count>0 then
                RAISE EXCEPTION '%', '@zssm_ProductionMovementInDraftExists@';
        end if;
        select sum(cl.MOVEMENTQTY) into v_qtyprocessed from M_INTERNAL_CONSUMPTION c,M_INTERNAL_CONSUMPTIONLINE cl 
           where c.processed='Y' and cl.M_INTERNAL_CONSUMPTION_ID = c.M_INTERNAL_CONSUMPTION_ID and cl.c_projecttask_id=v_Record_ID and MOVEMENTTYPE='P+';
        if v_qtyprocessed is null then
           v_qtyprocessed:=0;
        end if;
        if v_qty=0 then
           v_Message:=v_Message||'@zssm_NoProdPlusTransactionNecessary@';
        else
              if v_issuelocator is null then
                  RAISE EXCEPTION '%', '@NoLocatorDefined4StockTransaction@';
              end if;    
              if v_qtyprocessed+v_qty>v_qty_orig then
                 v_Message:=v_Message||'@zssm_NoProdPlusTransactionPossibleQtyIncorrect@';
              else
                    -- 1st the qty Produced - Transaction.
                    insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                NAME, DESCRIPTION, MOVEMENTDATE,dateacct, C_PROJECT_ID, C_PROJECTTASK_ID,  MOVEMENTTYPE,DOCUMENTNO)
                           values(v_uid,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                                  'Production-Process','Generated by Production->Ńew Produced Material',now(),now(),v_project, v_Record_ID,'P+',v_DocumentNo);
                    v_Line:=10;
                    v_lineUUId:=get_uuid();
                    select c_uom_id,isserialtracking,isbatchtracking into v_uom,v_serial,v_batch from m_product where m_product_id=v_product;
                    insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                                  M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID)
                                    values (v_lineUUId,v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid,
                                          v_issuelocator,v_product,v_Line,v_qty,'Generated by Production->Ńew Produced Material',v_uom,v_project, v_Record_ID);
                    -- seruial Number Tracking?
                    if v_serial='Y'  or v_batch='Y' then
                       v_isserial:=true;
                       v_Message:=v_Message||'<br />@zssm_MaterialSendToStockSerialRegistrationNeccessary@'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/Lines_Relation.html',v_lineUUId,'Serial Number Tracking');
                    else
                     if (select c_getconfigoption('activateinternalconsumptionauto',v_Org))='Y' then
                       PERFORM m_internal_consumption_post(v_uid);
                     end if;
                       v_Message:=v_Message||'<br />@zssm_MaterialSendToStockSucessfully@'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/InternalMaterialMovements_Relation.html',v_uid,v_DocumentNo);
                    end if;
              end if;
         end if;
     elseif v_cat = 'PRO' then-- No assembly. (Durchreicher)
       v_qtyprocessed:=0;
       if (select sum(qtyreceived) from zspm_projecttaskbom where c_projecttask_id=v_Record_ID)=0 or v_qty=0 then
           v_Message:=v_Message||'<br />@zssm_NoStockTransactionNeeded@';
       else
             -- 1st the qty Release - Transaction.
             insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                NAME, DESCRIPTION, MOVEMENTDATE,dateacct, C_PROJECT_ID, C_PROJECTTASK_ID,  MOVEMENTTYPE,DOCUMENTNO)
                           values(v_uid,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                                  'Production-Process','Generated by PDC ->Send produced Material on Stock',now(),now(),v_project, v_Record_ID,'D+',v_DocumentNo);
             v_Line:=10;
             -- Durchreicher
             for v_cur in (select qtyreceived as qty,m_product_id,issuing_locator,zspm_projecttaskbom_id  from zspm_projecttaskbom where c_projecttask_id=v_Record_ID 
                          order by line limit 1)
             LOOP
                -- uom
                select c_uom_id,isserialtracking,isbatchtracking into v_uom,v_serial,v_batch from m_product where m_product_id=v_cur.m_product_id;
                -- Locator
                if v_cur.issuing_locator is null then
                        RAISE EXCEPTION '%', '@NoLocatorDefined4StockTransaction@';
                end if;
                v_lineUUId:=get_uuid();
                if coalesce(v_cur.qty,0)>0 then
                    insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                                M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID,zspm_projecttaskbom_id)
                        values (v_lineUUId,v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid,
                                        v_cur.issuing_locator,v_cur.M_Product_ID,v_Line,v_cur.qty,'Generated by PDC ->Send produced Material on Stock',v_uom,v_project, v_Record_ID,v_cur.zspm_projecttaskbom_id);
                    -- serial Number Tracking?
                    if (v_serial='Y'  or v_batch='Y') and v_notrx='N' then
                        v_isserial:=true;
                        v_Message:=v_Message||'<br />'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/Lines_Relation.html',v_lineUUId,'Serial Number Tracking');
                    end if;   
                    v_Line:=v_Line+10;
                    if v_isvendorsupply='Y' and (v_serial='Y'  or v_batch='Y') then -- Updates only the BOM  / No Material transaction --> Beistellung per Lieferschein
                        -- TRX is deleted after Updating BOM-> Produced Mat is not given to store
                        if (select sum(quantity) from SNR_Serialnumbertracking where m_product_id=v_cur.m_product_id and C_PROJECT_ID=v_project and movementtype='P+')=v_cur.qty and 
                           (select iscomplete from c_projecttask where c_projecttask_id=(select distinct s.c_projecttask_id from SNR_Serialnumbertracking s where s.m_product_id=v_cur.m_product_id and 
                                   s.C_PROJECT_ID=v_project and s.movementtype='P+' limit 1))='Y'
                           then
                            for v_cur2 in (select sum(quantity) as qty,case when coalesce(serialnumber,'')!='' then serialnumber else null end as serialnumber,
                                                  case when coalesce(lotnumber,'')!='' then lotnumber else null end as lotnumber
                                                  from SNR_Serialnumbertracking where m_product_id=v_cur.m_product_id and C_PROJECT_ID=v_project 
                                                  and movementtype='P+' group by serialnumber,lotnumber)
                            LOOP
                                select  snr_masterdata_id into v_snrmstr from snr_masterdata  where m_product_id=v_cur.m_product_id and serialnumber=v_cur2.serialnumber;
                                select  snr_batchmasterdata_id into v_btchmstr from snr_batchmasterdata where m_product_id=v_cur.m_product_id and batchnumber=v_cur2.lotnumber;
                                for v_cur3 in (select * from zspm_projecttaskbom where c_projecttask_id=v_Record_ID and m_product_id!=v_cur.m_product_id) 
                                LOOP
                                    select snr_currentbom_id into v_currbomid from snr_currentbom where (snr_masterdata_id=coalesce(v_snrmstr,'') or snr_batchmasterdata_id=coalesce(v_snrmstr,coalesce(v_btchmstr,''))) and m_product_id=v_cur3.m_product_id;
                                    if v_currbomid is null then
                                        select get_uuid() into v_currbomid;
                                        insert into snr_currentbom(snr_currentbom_id , snr_masterdata_id, snr_batchmasterdata_id, ad_client_id, ad_org_id , isactive , createdby, updatedby , m_product_id, qty)
                                        values (v_currbomid,v_snrmstr,v_btchmstr,v_client,v_org,'Y',v_user,v_user, v_cur3.m_product_id, round(v_cur3.qtyreceived/v_cur.qty,3));
                                    else
                                        update snr_currentbom set qty=qty+(round(v_cur3.qtyreceived/v_cur.qty,3)) where snr_currentbom_id=v_currbomid;
                                    end if;
                                    for v_cur4 in (select s.snr_masterdata_id,s.snr_batchmasterdata_id,s.quantity from snr_minoutline s,m_inoutline l,m_inout m where
                                                          s.m_inoutline_id=l.m_inoutline_id and l.m_inout_id=m.m_inout_id and m.docstatus='CO' and l.c_projecttask_id= v_Record_ID and
                                                          l.m_product_id=v_cur3.m_product_id)
                                    LOOP
                                        insert into snr_currentbom_serials(snr_currentbom_serials_id , snr_currentbom_v_id, snr_batchcurrentbom_v_id, snr_masterdata_id ,ad_client_id, ad_org_id , isactive , createdby, updatedby ,snr_batchmasterdata_id,qty) 
                                        values(get_uuid(),v_currbomid, v_currbomid,v_cur4.snr_masterdata_id,v_client,v_org,'Y',v_user,v_user,v_cur4.snr_batchmasterdata_id,v_cur4.quantity);
                                    END LOOP;
                                END LOOP;
                            END LOOP;                            
                        else
                            raise exception '%','@zssm_materialQtysNotFitting@';  -- Immer alles auf einmal...
                        end if;                        
                    end if;
                    if v_notrx='Y' then
                        delete from M_INTERNAL_CONSUMPTIONLINE where M_INTERNAL_CONSUMPTIONLINE_ID=v_lineUUId;
                        delete from M_INTERNAL_CONSUMPTION where  M_INTERNAL_CONSUMPTION_id=v_uid;
                        update zspm_projecttaskbom set quantity=0,qtyreceived=0 where c_projecttask_id=v_Record_ID and m_product_id=v_cur.m_product_id;
                        update c_projecttask set qtyproduced=v_cur.qty,iscomplete='Y',PERCENTDONE=100,ended=now() where c_projecttask_id=v_Record_ID;
                    end if;
                end if;
             END LOOP;   
             if v_isserial=true then
                  v_Message:=v_Message||'@zssm_MaterialReturnSerialRegistrationNeccessary@';
             else
                if (select c_getconfigoption('activateinternalconsumptionauto',v_Org))='Y' and v_notrx='N' then
                    PERFORM m_internal_consumption_post(v_uid);
                end if;
                if v_notrx='N' then
                    v_Message:=v_Message||'<br />@zssm_MaterialSendToStockSucessfully@'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/InternalMaterialMovements_Relation.html',v_uid,v_DocumentNo);
                else
                    v_Message:=v_Message||'<br />@zssm_BOMAdditionNoTrx@';
                end if;
             end if;
        end if; --NoProdPlusTransactionNeeded@
     end if; --Assembly / no Assembly
     --
     -- 2nd Return Remaining Material
     if v_isassemble='Y' and v_remaininglocator is not null and v_rejectremaining='Y' and v_qtyprocessed+v_qty<v_qty_orig and (select sum(qtyreceived) from zspm_projecttaskbom where c_projecttask_id=v_Record_ID)!=0 then
           if v_isserial=true then
                v_Message:=v_Message||'@zssm_MaterialReturnOnlyAfterSerialRegistration@';
           else
                 -- Prepare Transaction Document
                 select ad_sequence_doc('Production',v_org,'Y') into v_DocumentNo;
                 select get_uuid() into v_uid;
                 insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                NAME, DESCRIPTION, MOVEMENTDATE,dateacct, C_PROJECT_ID, C_PROJECTTASK_ID,  MOVEMENTTYPE,DOCUMENTNO)
                           values(v_uid,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                                  'Production-Process','Generated by Production-> Return Material',now(),now(),v_project, v_Record_ID,'D+',v_DocumentNo);
                 for v_cur in (select case when v_isassemble='N' then qtyreceived else trunc(qtyreceived-((quantity/v_orig_qty)*(v_orig_prod+v_qty)),3) end as qty,m_product_id,issuing_locator,zspm_projecttaskbom_id  from zspm_projecttaskbom where c_projecttask_id=v_Record_ID)
                 LOOP
                    -- uom
                    select c_uom_id,isserialtracking,isbatchtracking into v_uom,v_serial,v_batch from m_product where m_product_id=v_cur.m_product_id;
                    v_lineUUId:=get_uuid();
                    if v_cur.qty>0 then
                      --raise notice '%',v_cur.qty||'#'||(select name from m_product where m_product_id=v_cur.m_product_id);
                      insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                            M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID,zspm_projecttaskbom_id)
                       values (v_lineUUId,v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid,
                                    v_remaininglocator,v_cur.M_Product_ID,v_Line,v_cur.qty,'Generated by Production->-> Return Material',v_uom,v_project, v_Record_ID,v_cur.zspm_projecttaskbom_id); 
                      -- seruial Number Tracking?
                      if v_serial='Y'  or v_batch='Y' then
                        v_isserial:=true;
                        v_Message:=v_Message||'<br />'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/Lines_Relation.html',v_lineUUId,'Serial Number Tracking');
                      end if;   
                      v_Line:=v_Line+10;
                    end if;
                 END LOOP; 
           end if;
           if v_isserial=true then
            v_Message:=v_Message||'@zssm_MaterialReturnSerialRegistrationNeccessary@';
           else
             if (select count(*) from M_INTERNAL_CONSUMPTIONLINE where M_INTERNAL_CONSUMPTION_ID=v_uid)>0 then
                if (select c_getconfigoption('activateinternalconsumptionauto',v_Org))='Y' then
                    PERFORM m_internal_consumption_post(v_uid);
                end if;
                v_Message:=v_Message||'<br />@zssm_MaterialReturnToStockSucessfully@'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/InternalMaterialMovements_Relation.html',v_uid,v_DocumentNo);
             else
                delete from M_INTERNAL_CONSUMPTION where M_INTERNAL_CONSUMPTION_ID=v_uid;
                v_Message:=v_Message||'<br />@zssm_NoStockTransactionNeeded@';
             end if;
            end if;
     end if; --Return Remaining Material 
     /*
     -- 3rd Stock Rotation
     -- Without Stock Rotation, this Material is fully automatically consumed by the next workstep.
     -- test if stockrotation necessary
     select count(*) into v_count from zspm_projecttaskdep where dependsontask=v_Record_ID;
     if v_count=1 then
          select c_projecttask_id,stockrotation into v_dependent,v_stockrotation from zspm_projecttaskdep where dependsontask=v_Record_ID;
     else
       v_stockrotation:='Y';
     end if;
     if v_stockrotation='N' and v_isserial=false then
            --
            --
            select ad_sequence_doc('Production',v_org,'Y') into v_DocumentNo;
            select get_uuid() into v_uid;
            -- 1st the Mat. Consumption - Transaction.
            insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                NAME, DESCRIPTION, MOVEMENTDATE,dateacct, C_PROJECT_ID, C_PROJECTTASK_ID,  MOVEMENTTYPE,DOCUMENTNO)
                           values(v_uid,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                                  'Production-Process','Generated by Production->Get Material from Stock',now(),now(),v_project, v_dependent,'D-',v_DocumentNo);
             v_Line:=10;
             
             for v_cur in (select l.MOVEMENTQTY as qty,l.M_PRODUCT_ID,l.C_UOM_ID, l.C_PROJECT_ID, l.C_PROJECTTASK_ID ,l.M_INTERNAL_CONSUMPTIONLINE_ID,l.m_locator_id
                                  from M_INTERNAL_CONSUMPTIONLINE l, m_internal_consumption i 
                                  where i.m_internal_consumption_id=l.m_internal_consumption_id
                                        and l.C_PROJECTTASK_ID=v_Record_ID and l.M_LOCATOR_ID=v_issuelocator and i.processed='Y' and i.movementtype in ('D+','P+'))
             LOOP
                 v_lineUUId:=get_uuid();
                 insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                            M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID)
                       values (v_lineUUId,v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid,
                                    v_cur.m_locator_id,v_cur.M_Product_ID,v_Line,v_cur.qty,'Generated by Production->Get Material from Stock',v_cur.C_UOM_ID,v_cur.C_PROJECT_ID, v_dependent); 
                 v_Line:=v_Line + 10;
                 for v_cur2 in (select * from snr_internal_consumptionline s where M_INTERNAL_CONSUMPTIONLINE_ID=v_cur.M_INTERNAL_CONSUMPTIONLINE_ID)
                   LOOP
                        select * into v_snrline from snr_internal_consumptionline where snr_internal_consumptionline_id=v_cur2.snr_internal_consumptionline_id;
                        v_snrline.snr_internal_consumptionline_id=get_uuid();
                        v_snrline.M_INTERNAL_CONSUMPTIONLINE_ID=v_lineUUId;
                        insert into snr_internal_consumptionline select v_snrline.*;
                   END LOOP;
             END LOOP;
             if v_Line>10 then
                    PERFORM m_internal_consumption_post(v_uid);
                    v_Message:=v_Message||'<br />@zssm_MaterialBookedAutomatictoNextWorkstep@'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/InternalMaterialMovements_Relation.html',v_uid,v_DocumentNo);
             else
                delete from M_INTERNAL_CONSUMPTION where M_INTERNAL_CONSUMPTION_ID=v_uid;
             end if;
     end if; -- stockrotation
     */
    if  v_closetask='Y' then
          update c_projecttask set iscomplete='Y',PERCENTDONE=100,ended=now() where c_projecttask_id=v_Record_ID;
    end if;
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1 , v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;




  
CREATE OR REPLACE FUNCTION zssm_closeworkstep(p_workstep character varying, p_user character varying,p_language varchar)
  RETURNS varchar AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 Ends a TASK (for Use With Scanner)
 Closes Workorder if all Tasks ended
 End Time Feedback, if exists
Checks
*****************************************************/
v_proj    character varying;
v_count   numeric;
v_category  varchar;
v_message varchar:='ERROR';
BEGIN
if (select count(*) from c_projecttask where c_projecttask_id=p_workstep)=1 then
    v_message:=zssi_getText('pdc_WokstepClosed',p_language);
    select t.c_project_id,p.projectcategory into v_proj,v_category from c_projecttask t,c_project p where t.c_project_id=p.c_project_id and t.c_projecttask_id=p_workstep;
    update c_projecttask set iscomplete='Y',ended=now(),updated=now(),updatedby=p_user where c_projecttask_id=p_workstep;
    select count(*) into v_count from c_projecttask where c_project_id=v_proj and iscomplete='N';
    -- Close Workorder too
    if v_count=0 and v_category='PRO' then
        update c_project set projectstatus='CL' where c_project_id=v_proj;
        v_message:=v_message||'-'||zssi_getText('zssm_workorderclosedautomatically',p_language);
    end if;
    -- End Time Feedback, if there
    
     SELECT count(*) into v_count FROM zspm_ptaskfeedbackline fbl  WHERE fbl.c_projecttask_id = p_workstep and fbl.hour_to is null;
    if v_count>0 and v_category='PRO' then
     UPDATE zspm_ptaskfeedbackline fbl SET hour_to = now(), updatedby = p_user,updated = now() WHERE  fbl.c_projecttask_id = p_workstep and fbl.hour_to is null;
      v_message:=v_message||'-'||zssi_getText('TimeFeedbackFinished',p_language);
    end if;
end if;
return v_message;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
-- User Exit to m_inout_post
CREATE or replace FUNCTION zssm_supply2vendoractivation(p_minout_id varchar) RETURNS varchar
AS $_$
DECLARE
BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';

  
  
SELECT zsse_droptrigger('zssm_attrconsumptionline_trg', 'm_internal_consumptionline');
CREATE OR REPLACE FUNCTION zssm_attrconsumptionline_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.

Inserts Attributes for Produced Items
*******************************************************************************************************************************************/

BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
  -- Produktion
  if (select count(*) from m_internal_consumption where m_internal_consumption_id=new.m_internal_consumption_id and movementtype='P+')=1 and
     (select count(*)  from c_projecttask where c_projecttask_id=new.c_projecttask_id and m_attributesetinstance_id is not null and assembly='Y')=1 
  then
       select m_attributesetinstance_id into new.m_attributesetinstance_id from c_projecttask where c_projecttask_id=new.c_projecttask_id;
  end if;
  -- Passing Workstep
  if (select count(*) from zspm_projecttaskbom b where b.c_projecttask_id=new.c_projecttask_id and b.m_product_id=new.m_product_id and 
                      b.m_attributesetinstance_id is not null)=1 and
      (select count(*)  from c_projecttask where c_projecttask_id=new.c_projecttask_id and assembly='N')=1 
  then
       select m_attributesetinstance_id into new.m_attributesetinstance_id from zspm_projecttaskbom where c_projecttask_id=new.c_projecttask_id and m_product_id=new.m_product_id;
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE TRIGGER zssm_attrconsumptionline_trg
  BEFORE INSERT
  ON m_internal_consumptionline FOR EACH ROW
  EXECUTE PROCEDURE zssm_attrconsumptionline_trg();
  

CREATE OR REPLACE FUNCTION zssm_GetMaterialIntoWorkstep(p_projecttask_id character varying, v_user character varying, OUT out_message character varying, OUT out_internalconsumption_id character varying) RETURNS record
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. Sub Funktion needed When Workstep is started.
Unlike zsmf_GetMaterialFromStock, which works with reservatins, Availability was checked before this Function is executed.
We just get the needed Material from the locator defined in the Wokstep.


*****************************************************/
v_warehouse  character varying;
v_project  character varying;
v_locator  character varying;
v_client   character varying;
v_org      character varying;
v_cur      RECORD;
v_uom      character varying;
v_Result   numeric;
v_Count    numeric;
v_qtyinconsum numeric;
v_qtyreturned numeric;
v_Line     numeric:=0;
v_Uid      character varying;
v_lineUUId varchar;
v_DocumentNo varchar;
v_Serial varchar;
v_isserial boolean:=false;
v_batch   varchar;
BEGIN 
     out_message:='';
     select c_project.m_warehouse_id,c_project.c_project_id,c_project.ad_client_id,c_project.ad_org_id into v_warehouse,v_project,v_client, v_org
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=p_projecttask_id;
    -- Some Checks before...
    /*
    select cl.M_INTERNAL_CONSUMPTIONLINE_ID,c.documentno into v_Uid,v_DocumentNo from M_INTERNAL_CONSUMPTION c,M_INTERNAL_CONSUMPTIONLINE cl 
           where c.processed='N' and cl.M_INTERNAL_CONSUMPTION_ID = c.M_INTERNAL_CONSUMPTION_ID and cl.c_projecttask_id=p_projecttask_id LIMIT 1;
    if v_Uid is not null then
          RAISE EXCEPTION '%','@DraftExistsCannotGenerate@ :' || zsse_htmlLinkDirectKey('../InternalMaterialMovements/Lines_Relation.html',v_inoutid,v_DocumentNo);
    end if;
    */
    -- Prepare Material Consumption, If needed
    select count(*) into v_Count from zspm_projecttaskbom where c_projecttask_id=p_projecttask_id and quantity>qtyreceived;
    if v_count>0 then
        select ad_sequence_doc('Production',v_org,'Y') into v_DocumentNo;
        select get_uuid() into out_internalconsumption_id;
        insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                    NAME, DESCRIPTION, MOVEMENTDATE,dateacct, C_PROJECT_ID, C_PROJECTTASK_ID,  MOVEMENTTYPE,DOCUMENTNO)
               values(out_internalconsumption_id,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                      'Production-Process','Generated by Production->Get Material from Stock',now(),now(),v_project, p_projecttask_id,'D-',v_DocumentNo);
    end if;
    -- Select all Reserved Material and all Assemblys goin into this Task
    for v_cur in (select * from zspm_projecttaskbom where c_projecttask_id=p_projecttask_id and quantity>qtyreceived)
    LOOP      
        if v_cur.quantity>v_cur.qtyreceived then 
              -- uom
              select c_uom_id,isserialtracking,isbatchtracking into v_uom,v_serial,v_batch from m_product where m_product_id=v_cur.m_product_id;
              
              if v_cur.receiving_locator is null then
                  RAISE EXCEPTION '%', '@NoLocatorDefined4StockTransaction@';
              end if;    
              -- Material Consumption Line
              -- only remaining qty.
              v_Line:=v_Line+10;
              v_lineUUId:=get_uuid();
              insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                      M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID,zspm_projecttaskbom_id)
                        values (v_lineUUId,v_client,v_Org,NOW(), v_User, NOW(),v_User,out_internalconsumption_id,
                              v_cur.receiving_locator,v_cur.M_Product_ID,v_Line,v_cur.quantity-v_cur.qtyreceived,'Generated by Production->Get Material from Stock',v_uom,v_project, p_projecttask_id,v_cur.zspm_projecttaskbom_id);
              -- seruial Number Tracking?
              if v_serial='Y'  or v_batch='Y' then
                 v_isserial:=true;
                 out_message:=out_message||zsse_htmlLinkDirectKey('../InternalMaterialMovements/Lines_Relation.html',v_lineUUId,'Serial Number Tracking')||'<br />';
              end if;
        end if;
    END LOOP;
    -- no lines? - delete
    if v_Line=0 then
       delete from M_INTERNAL_CONSUMPTION where M_INTERNAL_CONSUMPTION_ID=out_internalconsumption_id;
       out_message:='@zssm_NoStockTransactionNeededAllMaterialGot@';
    else
       if v_isserial=true then
          out_message:=out_message||'@zssm_MaterialReceivedSerialRegistrationNeccessary@';
       else
          PERFORM m_internal_consumption_post(out_internalconsumption_id);
          out_message:='@zssm_MaterialReceivedCompleteInWorkstep@'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/InternalMaterialMovements_Relation.html',out_internalconsumption_id,v_DocumentNo);
       end if;
    end if;
    return;
END;
$_$  LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION zssm_activateplan (
  p_pinstance_id varchar
)
RETURNS void AS
$body$
DECLARE 

v_ProductionPlan_id varchar;
v_user_id varchar;
v_message varchar:='ERROR';
v_result numeric:=0;


v_asstime4plan numeric:=0;
v_setuptime4plan numeric:=0;


BEGIN
  --  Update AD_PInstance
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  SELECT pi.Record_ID, pi.ad_User_ID
    INTO v_ProductionPlan_id, v_user_id
    FROM ad_pinstance pi WHERE pi.ad_pinstance_ID = p_pinstance_ID;
    
  if v_ProductionPlan_id is null then 
    v_ProductionPlan_id:=p_pinstance_ID;
    v_user_id:='0';
  end if;

   -- Time Calculation starts with plan entry 
  select sum(t.setuptime), sum(t.timeperpiece) into v_setuptime4plan,v_asstime4plan from zssm_productionplan_task_v t where zssm_productionplan_v_id= v_ProductionPlan_id;

    
  UPDATE c_project SET projectstatus = 'OR',setuptime=v_setuptime4plan,timeperpiece=v_asstime4plan --updated = now(), updatedby = v_user_id: performed by AD_UPDATE_PINSTANCE() !?
  WHERE c_project_id = v_ProductionPlan_id;
  
  v_message := '@zssm_PlanSuccessfullyActivated@';
  v_result := 1;
  RAISE NOTICE 'v_message=''%'' ', v_message;
  
  --  Update AD_PInstance
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_result , v_Message) ;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END ;
$body$
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION zssm_actualizeplan(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Projects, Begins a TASK (Gets Material From Stock)
Checks
*****************************************************/

v_message varchar:= '@SUCCESS@';
v_ProductionPlan_id varchar;
v_user_id varchar;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT pi.Record_ID, pi.ad_User_ID
      INTO v_ProductionPlan_id, v_user_id
      FROM ad_pinstance pi WHERE pi.ad_pinstance_ID = p_pinstance_ID;
    
    update c_project set projectstatus='DR',udated=now(),updatedby=v_user_id where c_project_id=v_ProductionPlan_id;
      
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1 , v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION zssm_close_productionorder(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 2012 Zimmermann_Software */
/* derived from zspm_endproject(p_pinstance_id character varying) */
v_Record_ID  VARCHAR;
v_user_id    VARCHAR;
v_ismanager  VARCHAR;
v_message    VARCHAR := 'Success';
v_currentstatus VARCHAR;
v_count      NUMERIC;
v_cur record;
v_closetask varchar:='N';
BEGIN
    --  Update AD_PInstance
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  SELECT i.Record_ID, i.AD_User_ID 
  INTO v_Record_ID, v_user_id FROM AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
  IF isempty(v_Record_ID) THEN
     RAISE NOTICE '%=''%''','Pinstance not found-Using as RecordID', p_PInstance_ID;
     v_Record_ID := p_PInstance_ID;
     v_user_id := '0';
  else 
        FOR v_cur IN
          (SELECT para.*
           FROM ad_pinstance pi, ad_pinstance_Para para
           WHERE 1=1
            AND pi.ad_pinstance_ID = para.ad_pinstance_ID
            AND pi.ad_pinstance_ID = p_pinstance_ID
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(v_cur.parametername) = UPPER('forceclosews') ) THEN
            v_closetask := v_cur.p_string;
          END IF;
        END LOOP; -- Get Parameter
  END IF;
  if v_closetask='Y' then
    for v_cur in (select c_projecttask_id from c_projecttask where c_project_id=v_Record_ID)
    LOOP
        update c_projecttask set iscomplete='Y' where c_projecttask_id=v_cur.c_projecttask_id;
    END LOOP;
  end if;
  select count(*) into v_count from c_projecttask where c_project_id=v_Record_ID and iscomplete ='N' and Istaskcancelled='N';
  if v_count>0 then
     RAISE EXCEPTION '%', '@zssm_cannotclosePOrderWhenTasksNotClosed@';
  end if;
  update c_project set projectstatus='CL' where c_project_id=v_Record_ID;
   
  ---- <<FINISH_PROCESS>>
  --  Update AD_PInstance
  RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%', v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END ; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION zssm_autoproductionfeedback() 
RETURNS VARCHAR
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
  v_message varchar:='';
  v_qty integer;
  v_cur record;
  v_cur2 record;
  v_check varchar:='';
  v_count numeric:=0;
  v_result numeric;
BEGIN 
   for v_cur in (select pt.* from c_projecttask pt, c_project p where p.c_project_id=pt.c_project_id and p.projectcategory='PRO' 
                  and p.projectstatus='OR' and pt.isautocloseworkstep='Y' and coalesce(pt.enddate,to_date(now()))<=to_date(now()) order by pt.value asc)
   LOOP
        -- Correct QTys, when there is no stock avail.
        while v_check!='OK'
        LOOP
            v_check:='OK';
            select count(*) into v_qty from Zssm_WorkstepBOM_V where zssm_workstep_prp_v_id=v_cur.c_projecttask_id and qty_instock<quantity-qtyreceived;
            If v_qty>0 then
                select qty into v_qty from c_projecttask where c_projecttask_id=v_cur.c_projecttask_id;
                If v_qty>0 then
                    update c_projecttask set qty=qty-1 where c_projecttask_id=v_cur.c_projecttask_id;
                else
                    update Zssm_WorkstepBOM_V set quantity=0 where zssm_workstep_prp_v_id=v_cur.c_projecttask_id;
                end if;
                v_check:='CORRECTIONREQUIRED';
                if instr(v_message,v_cur.value)=0 then
                    v_message:=v_message||' '||v_cur.value||' not enough stock for '||v_qty||' items -';
                end if;
            end if;
        END LOOP;
        -- Do Mat Consumption
        select * into v_cur2 from zssm_beginworkstep(v_cur.c_projecttask_id,v_cur.updatedby,v_cur.ad_org_id,'Y');
        -- Do Production
        perform zssm_endworkstep(v_cur.c_projecttask_id);
        select result,errormsg into v_result, v_message from ad_pinstance where ad_pinstance_id=v_cur.c_projecttask_id;          
        if v_result!=1 then
            RAISE EXCEPTION '%',v_message ;
        end if;
        perform zssm_close_productionorder(v_cur.c_project_id);
        v_count:=v_count+1;
   END LOOP;
   RETURN v_count||' Production Orders processed - '||v_message;
END;
$_$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssm_rejection(p_internalconsumption varchar,v_lang varchar)
  RETURNS varchar AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2023 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 Ausschuß über Sperrlager buchen.
*****************************************************/
v_workorder character varying;
v_locator varchar;
v_org varchar;
v_workstep varchar;
v_qty   numeric;
v_message varchar:=zssi_getText('pdc_NoData',v_lang);
v_locname varchar;
v_cur2 RECORD;
v_cur RECORD;
BEGIN
  for v_cur2 in (select * from m_internal_consumptionline where m_internal_consumption_id=p_internalconsumption)
  LOOP
      select ad_org_id,c_project_id,c_projecttask_id,movementqty into v_org,v_workorder,v_workstep,v_qty from m_internal_consumptionline where m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id;
      select l.m_locator_id,l.value into v_locator,v_locname from m_warehouse w,m_locator l  where w.m_warehouse_id=l.m_warehouse_id and w.isblocked='Y' and w.isactive='Y' and l.isactive='Y' 
                          and l.isdefault='Y' and w.ad_org_id in ('0',v_org) limit 1;
      if v_locator is null then
        raise exception '%', 'No Rejection Locator found';
      end if;
      update m_internal_consumptionline set m_locator_id=v_locator where m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id;
      v_message:=zssi_getText('zsmf_rejection',v_lang)||v_locname;
      for v_cur in (select * from c_projecttask where c_project_id=v_workorder order by seqno)
      LOOP
          update c_projecttask set triggerreason='NACHPRODUKTION-'||replace(coalesce(v_cur.triggerreason,''),'NACHPRODUKTION-',''),qty=qty+v_qty,iscomplete='N' where c_projecttask_id=v_cur.c_projecttask_id;
          if v_cur.c_projecttask_id=v_workstep then
              exit;
          end if;
      END LOOP;
  END LOOP;
return v_message;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  

CREATE OR REPLACE FUNCTION zssm_copyworkstep(
  p_workstep_id varchar,
  p_newkey varchar,
  p_user varchar,
  v_uid varchar)
RETURNS varchar AS
$body$
DECLARE
    v_now TIMESTAMP := now();
    v_message varchar := '';
    Cur_Parameter record;
    v_projecttask c_projecttask%ROWTYPE;
    v_taskhrplan zspm_ptaskhrplan%ROWTYPE;
    v_tasktechdoc zssm_ptasktechdoc%ROWTYPE;
    v_taskmachineplan zspm_ptaskmachineplan%ROWTYPE;
    v_projecttaskbom zspm_projecttaskbom%ROWTYPE;
BEGIN
    -- Kopfdatensatz workstep
    SELECT * INTO v_projecttask FROM c_projecttask WHERE c_projecttask_id = p_workstep_id;
    v_projecttask.c_projecttask_id := v_uid;
    v_projecttask.created := v_now;
    v_projecttask.createdby := p_user;
    v_projecttask.updated := v_now;
    v_projecttask.updatedby := p_user;
    v_projecttask.value := p_newkey;
    INSERT INTO c_projecttask SELECT v_projecttask.*;

    -- activities
    FOR v_taskhrplan IN (SELECT * FROM zspm_ptaskhrplan WHERE c_projecttask_id = p_workstep_id) LOOP
        v_taskhrplan.zspm_ptaskhrplan_id := get_uuid();
        v_taskhrplan.c_projecttask_id := v_projecttask.c_projecttask_id;
        v_taskhrplan.created := v_now;
        v_taskhrplan.createdby := p_user;
        v_taskhrplan.updated := v_now;
        v_taskhrplan.updatedby := p_user;
        INSERT INTO zspm_ptaskhrplan SELECT v_taskhrplan.*;
    END LOOP;

    -- technical documents
    FOR v_tasktechdoc IN (SELECT * FROM zssm_ptasktechdoc WHERE c_projecttask_id = p_workstep_id) LOOP
        v_tasktechdoc.zssm_ptasktechdoc_id := get_uuid();
        v_tasktechdoc.c_projecttask_id := v_projecttask.c_projecttask_id;
        v_tasktechdoc.created := v_now;
        v_tasktechdoc.createdby := p_user;
        v_tasktechdoc.updated := v_now;
        v_tasktechdoc.updatedby := p_user;
        INSERT INTO zssm_ptasktechdoc SELECT v_tasktechdoc.*;
    END LOOP;

    -- machines
    FOR v_taskmachineplan IN (SELECT * FROM zspm_ptaskmachineplan WHERE c_projecttask_id = p_workstep_id) LOOP
        v_taskmachineplan.zspm_ptaskmachineplan_id := get_uuid();
        v_taskmachineplan.c_projecttask_id := v_projecttask.c_projecttask_id;
        v_taskmachineplan.created := v_now;
        v_taskmachineplan.createdby := p_user;
        v_taskmachineplan.updated := v_now;
        v_taskmachineplan.updatedby := p_user;
        INSERT INTO zspm_ptaskmachineplan SELECT v_taskmachineplan.*;
    END LOOP;

    -- bom
    FOR v_projecttaskbom IN (SELECT * FROM zspm_projecttaskbom WHERE c_projecttask_id = p_workstep_id) LOOP
        v_projecttaskbom.zspm_projecttaskbom_id := get_uuid();
        v_projecttaskbom.c_projecttask_id := v_projecttask.c_projecttask_id;
        v_projecttaskbom.created := v_now;
        v_projecttaskbom.createdby := p_user;
        v_projecttaskbom.updated := v_now;
        v_projecttaskbom.updatedby := p_user;
        INSERT INTO zspm_projecttaskbom SELECT v_projecttaskbom.*;
    END LOOP;

    v_message := 'SUCCESS' || ' ' || '@zsse_SuccessfullCopyWorkstep@' || '</br>' || (SELECT zsse_htmldirectlink('../org.openbravo.zsoft.serprod.WorkSteps/WorkStepsECE46D9675A84540808D61E971782779_Relation.html', 'document.frmMain.inpzssmWorkstepPrpVId', v_projecttask.c_projecttask_id, v_projecttask.value));
    RETURN v_message;

EXCEPTION
    WHEN OTHERS then
       RETURN SQLERRM;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssm_copyworkstep_files(
  p_workstep_id varchar,
  p_newworkstep_id varchar,
  p_user varchar)
RETURNS varchar AS
$body$
DECLARE
    v_file c_file%ROWTYPE;
    v_now TIMESTAMP := now();
BEGIN
    FOR v_file IN (SELECT * FROM c_file WHERE ad_record_id = p_workstep_id) LOOP
       v_file.c_file_id := get_uuid();
       v_file.created := v_now;
       v_file.createdby := p_user;
       v_file.updated := v_now;
       v_file.updatedby := p_user;
       v_file.ad_record_id := p_newworkstep_id;
       INSERT INTO c_file SELECT v_file.*;
    END LOOP;

    RETURN 'SUCCESS';
EXCEPTION
    WHEN OTHERS then
       RETURN SQLERRM;
END;
$body$
LANGUAGE 'plpgsql';


