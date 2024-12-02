CREATE or replace FUNCTION snr_getassembly_snr(p_projecttask character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_conid character varying;
BEGIN
      select snr.serialnumber into v_return from snr_internal_consumptionline snr,m_internal_consumptionline ml,m_internal_consumption m
             where ml.c_projecttask_id=p_projecttask 
                   and snr.m_internal_consumptionline_id=ml.m_internal_consumptionline_id and m.m_internal_consumption_id=ml.m_internal_consumption_id
                   and m.movementtype='P+' and m.processed='Y';
RETURN coalesce(v_return,'');
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;

CREATE or replace FUNCTION snr_getassembly_productid(p_task character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select m_product_id into v_return from c_projecttask where c_projecttask_id=p_task;
RETURN coalesce(v_return,'');
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;


select zsse_DropView ('snr_serialnumbertracking');
CREATE OR REPLACE VIEW snr_serialnumbertracking AS 
 SELECT snr.snr_masterdata_id,snr.snr_batchmasterdata_id,snr.snr_minoutline_id AS snr_serialnumbertracking_id, snr.ad_client_id, snr.ad_org_id, 'Y' as isactive,snr.created, snr.createdby, snr.updated, snr.updatedby, 
        snr.Guaranteedays,case when snr.snr_batchmasterdata_id is not null then coalesce(snr.Lotnumber,'not available') else '' end as Lotnumber,snr.Rfidnumber,
        mol.m_inoutline_id, null as m_internal_consumptionline_id, null as m_inventoryline_id, null as m_movementline_id, mo.m_inout_id, null as m_internal_consumption_id, null as m_inventory_id, null as m_movement_id,
        mo.c_bpartner_id, mo.movementtype, mol.c_orderline_id, mol.m_product_id, mol.m_attributesetinstance_id, mo.movementdate,  snr.guaranteedate, 
        case when snr.snr_masterdata_id is not null then coalesce(snr.serialnumber,'not available') else '' end as serialnumber,snr.description,
        mol.c_project_id,mol.a_asset_id,mol.c_projecttask_id,mol.m_locator_id,sign(mol.movementqty)*snr.quantity as quantity, mo.docstatus,null as assembly_snr,null as assembly_productid,
        null as snr_builtinsnr,
        '':: character(1) as pnamevaluesqlfield ,text1,text2,text3,text4,text5,text6,text7,text8,text9,text10,num1,num2,num3,num4,num5,date1,date2,date3,date4
   FROM m_inout mo, snr_minoutline snr, m_inoutline mol
  WHERE snr.m_inoutline_id::text = mol.m_inoutline_id::text AND mol.m_inout_id::text = mo.m_inout_id::text AND mo.processed::text='Y'
union
 SELECT snr.snr_masterdata_id,snr.snr_batchmasterdata_id,snr.snr_internal_consumptionline_id AS snr_serialnumbertracking_id, snr.ad_client_id, snr.ad_org_id, 'Y' as isactive, snr.created, snr.createdby, snr.updated, snr.updatedby, 
        snr.Guaranteedays,case when snr.snr_batchmasterdata_id is not null then coalesce(snr.Lotnumber,'not available') else '' end  as Lotnumber,snr.Rfidnumber,
        null as m_inoutline_id, mol.m_internal_consumptionline_id, null as m_inventoryline_id, null as m_movementline_id,null as m_inout_id, mo.m_internal_consumption_id, null as m_inventory_id, null as m_movement_id,
        null as c_bpartner_id, mo.movementtype, null as c_orderline_id, mol.m_product_id, mol.m_attributesetinstance_id, mo.movementdate,  snr.guaranteedate, 
        case when snr.snr_masterdata_id is not null then coalesce(snr.serialnumber,'not available') else '' end  as serialnumber,snr.description,
        mol.c_project_id,mol.a_asset_id,mol.c_projecttask_id,mol.m_locator_id,snr.quantity, 'CO' as docstatus,snr_getassembly_snr(mol.c_projecttask_id) as assembly_snr,snr_getassembly_productid(mol.c_projecttask_id) as assembly_productid,
        snr_builtinsnr as snr_builtinsnr,
        '':: character(1) as pnamevaluesqlfield ,snr.text1,snr.text2,text3,text4,text5,text6,text7,text8,text9,text10,num1,num2,num3,num4,num5,date1,date2,date3,date4
   FROM m_internal_consumption mo, m_internal_consumptionline mol, snr_internal_consumptionline snr
  WHERE snr.m_internal_consumptionline_id::text = mol.m_internal_consumptionline_id::text AND mol.m_internal_consumption_id::text = mo.m_internal_consumption_id::text  AND mo.processed::text='Y'
union
 SELECT snr.snr_masterdata_id,snr.snr_batchmasterdata_id,snr.snr_inventoryline_id AS snr_serialnumbertracking_id, snr.ad_client_id, snr.ad_org_id, 'Y' as isactive, snr.created, snr.createdby, snr.updated, snr.updatedby, 
        snr.Guaranteedays,case when snr.snr_batchmasterdata_id is not null then coalesce(snr.Lotnumber,'not available') else '' end as Lotnumber,snr.Rfidnumber,
        null as m_inoutline_id, null as m_internal_consumptionline_id, mol.m_inventoryline_id, null as m_movementline_id,null as m_inout_id, null as m_internal_consumption_id, mo.m_inventory_id, null as m_movement_id,
        null as c_bpartner_id, 'I+' as movementtype, null as c_orderline_id, mol.m_product_id, mol.m_attributesetinstance_id, mo.movementdate,  snr.guaranteedate, 
        case when snr.snr_masterdata_id is not null then coalesce(snr.serialnumber,'not available') else '' end  as serialnumber,snr.description,
        null as c_project_id,null as a_asset_id,null as c_projecttask_id,mol.m_locator_id,snr.quantity, 'CO' as docstatus,null as assembly_snr,null as assembly_productid,
        null as snr_builtinsnr,
        '':: character(1) as pnamevaluesqlfield ,null::text as text1,null::text as text2,null::text as text3,null::text as text4,null::text as text5,null::text as text6,null::text as text7,
        null::text as text8,null::text as text9,null::text as text10,null::numeric as num1,null::numeric as num2,null::numeric as num3,null::numeric as num4,null::numeric as num5,
        null::timestamp as date1,null::timestamp as date2,null::timestamp as date3,null::timestamp as date4
   FROM m_inventory mo, m_inventoryline mol, snr_inventoryline snr
  WHERE snr.m_inventoryline_id::text = mol.m_inventoryline_id::text AND mol.m_inventory_id::text = mo.m_inventory_id::text  AND mo.processed::text='Y'
union
  SELECT snr.snr_masterdata_id,snr.snr_batchmasterdata_id,snr.snr_inventorylinelost_id AS snr_serialnumbertracking_id, snr.ad_client_id, snr.ad_org_id, 'Y' as isactive, snr.created, snr.createdby, snr.updated, snr.updatedby, 
        snr.Guaranteedays,case when snr.snr_batchmasterdata_id is not null then coalesce(snr.Lotnumber,'not available') else '' end  as Lotnumber,snr.Rfidnumber,
        null as m_inoutline_id, null as m_internal_consumptionline_id, mol.m_inventoryline_id, null as m_movementline_id,null as m_inout_id, null as m_internal_consumption_id, mo.m_inventory_id, null as m_movement_id,
        null as c_bpartner_id, 'I+' as movementtype, null as c_orderline_id, mol.m_product_id, mol.m_attributesetinstance_id, mo.movementdate,  snr.guaranteedate, 
        case when snr.snr_masterdata_id is not null then coalesce(snr.serialnumber,'not available') else '' end  as serialnumber,snr.description,
        null as c_project_id,null as a_asset_id,null as c_projecttask_id,mol.m_locator_id,snr.quantity, 'CO' as docstatus,null as assembly_snr,null as assembly_productid,
        null as snr_builtinsnr,
        '':: character(1) as pnamevaluesqlfield ,null::text as text1,null::text as text2,null::text as text3,null::text as text4,null::text as text5,null::text as text6,null::text as text7,
        null::text as text8,null::text as text9,null::text as text10,null::numeric as num1,null::numeric as num2,null::numeric as num3,null::numeric as num4,null::numeric as num5,
        null::timestamp as date1,null::timestamp as date2,null::timestamp as date3,null::timestamp as date4
   FROM m_inventory mo, m_inventoryline mol, snr_inventorylinelost snr
  WHERE snr.m_inventoryline_id::text = mol.m_inventoryline_id::text AND mol.m_inventory_id::text = mo.m_inventory_id::text  AND mo.processed::text='Y'
union
 SELECT snr.snr_masterdata_id,snr.snr_batchmasterdata_id,snr.snr_movementline_id AS snr_serialnumbertracking_id, snr.ad_client_id, snr.ad_org_id, 'Y' as isactive, snr.created, snr.createdby, snr.updated, snr.updatedby, 
        snr.Guaranteedays,case when snr.snr_batchmasterdata_id is not null then coalesce(snr.Lotnumber,'not available') else '' end  as Lotnumber,snr.Rfidnumber,
        null as m_inoutline_id, null as m_internal_consumptionline_id, null as m_inventoryline_id, mol.m_movementline_id,null as m_inout_id, null as m_internal_consumption_id, null as m_inventory_id, mo.m_movement_id,
        null as c_bpartner_id,'M+' as movementtype, null as c_orderline_id, mol.m_product_id, mol.m_attributesetinstance_id, mo.movementdate,  snr.guaranteedate, 
        case when snr.snr_masterdata_id is not null then coalesce(snr.serialnumber,'not available') else '' end  as serialnumber,snr.description,
        null as c_project_id,null as a_asset_id,null as c_projecttask_id,mol.m_locatorto_id as m_locator_id,snr.quantity, 'CO' as docstatus,null as assembly_snr,null as assembly_productid,
        null as snr_builtinsnr,
        '':: character(1) as pnamevaluesqlfield ,null::text as text1,null::text as text2,null::text as text3,null::text as text4,null::text as text5,null::text as text6,null::text as text7,
        null::text as text8,null::text as text9,null::text as text10,null::numeric as num1,null::numeric as num2,null::numeric as num3,null::numeric as num4,null::numeric as num5,
        null::timestamp as date1,null::timestamp as date2,null::timestamp as date3,null::timestamp as date4
   FROM m_movement mo, m_movementline mol, snr_movementline snr
  WHERE snr.m_movementline_id::text = mol.m_movementline_id::text AND mol.m_movement_id::text = mo.m_movement_id::text  AND mo.processed::text='Y';

select zsse_DropView ('snr_batchlocator_v');  
create or replace view snr_batchlocator_v as select bl.snr_batchlocator_id as snr_batchlocator_v_id,bl.*,m.m_product_id,m.batchnumber from snr_batchlocator bl,snr_batchmasterdata m where m.snr_batchmasterdata_id=bl.snr_batchmasterdata_id;

select zsse_DropView ('snr_masterdatadropdown_v');  
create or replace view snr_masterdatadropdown_v as select snr.snr_masterdata_id as snr_masterdatadropdown_v_id,snr.serialnumber,snr.snr_masterdata_id,p.value||'-'||p.name||'-'||snr.serialnumber::text as name,p.m_product_id ,
                                                          snr.updated,snr.updatedby,snr.created,snr.createdby,snr.isactive,snr.ad_org_id,snr.ad_client_id from snr_masterdata snr,m_product p where p.m_product_id=snr.m_product_id;


CREATE OR REPLACE FUNCTION snr_checkline(p_table character varying,p_id character varying) returns character varying
AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

***************************************************************************************************/
v_sql character varying;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;

v_isserial character varying;
v_isbatch character varying;
v_count numeric:=0;
v_qty numeric;
v_double numeric;
v_product character varying;
v_movtype  character varying;
v_locator  character varying;
v_locator2 varchar;
v_exists numeric;
v_name varchar;
v_masterdata varchar;
v_attrset varchar;
v_attrstocked varchar;
BEGIN
    if p_table='inventoryline' then
        select 'IVT',qtycount,m_product_id,m_attributesetinstance_id into v_movtype,v_qty,v_product,v_attrset from m_inventoryline where m_inventoryline_id=p_id;
        select count(*) into v_double from snr_inventoryline s,m_inventoryline l where l.m_inventoryline_id=s.m_inventoryline_id and s.serialnumber is not null 
              and l.m_inventory_id=(select m_inventory_id from m_inventoryline where m_inventoryline_id=p_id)
              group by l.m_product_id,s.serialnumber having count(*)>1 ;
    elsif p_table='inoutline' then
        select a.movementtype,b.movementqty,b.m_product_id,b.m_attributesetinstance_id into v_movtype,v_qty,v_product,v_attrset from m_inoutline b,m_inout a where a.m_inout_id=b.m_inout_id and b.m_inoutline_id=p_id;
        select count(*) into v_double from snr_minoutline s,m_inoutline l where l.m_inoutline_id=s.m_inoutline_id and s.serialnumber is not null 
               and l.m_inout_id=(select m_inout_id from m_inoutline where m_inoutline_id=p_id) 
               group by l.m_product_id,s.serialnumber having count(*)>1 ;
    elsif p_table='internal_consumptionline' then 
        select a.movementtype,b.movementqty,b.m_product_id,b.m_attributesetinstance_id into v_movtype,v_qty,v_product,v_attrset from m_internal_consumptionline b,m_internal_consumption a where 
               a.m_internal_consumption_id=b.m_internal_consumption_id and b.m_internal_consumptionline_id=p_id;        
        select count(*) into v_double from snr_internal_consumptionline s,m_internal_consumptionline l  where l.m_internal_consumptionline_id=s.m_internal_consumptionline_id and s.serialnumber is not null 
               and l.m_internal_consumption_id=(select m_internal_consumption_id from m_internal_consumptionline where m_internal_consumptionline_id=p_id) 
               group by l.m_product_id,s.serialnumber having count(*)>1 ;
    elsif p_table='movementline' then
         select 'MOV',movementqty,m_product_id,m_attributesetinstance_id into v_movtype,v_qty,v_product,v_attrset from  m_movementline where m_movementline_id=p_id;
         select count(*) into v_double from snr_movementline  where m_movementline_id=p_id and serialnumber is not null group by serialnumber having count(*)>1;
         --select count(*) into v_count from snr_movementline  where m_movementline_id=p_id;
         --if v_count>0 then 
         --   return 'Diese Funktion ist noch nicht für die Verarbeitung von Chargen oder Seriennummernn geeignet. Bitte Interne Entnahme/Rückgabe benutzen';
         --end if;
    end if;
    select a.isserialtracking,a.isbatchtracking,a.name,b.isstocktracking into v_isserial,v_isbatch,v_name,v_attrstocked from m_product a left join m_attributeset b on a.m_attributeset_id=b.m_attributeset_id where a.m_product_id=v_product;
    if coalesce(v_isserial,'N')='N' and coalesce(v_isbatch,'N')='N' then 
          return '@snr_producthasnoserialtracking@: '||v_name;
    end if;
   -- Serial Numbers
   if coalesce(v_isserial,'N')='Y' then
        v_sql:='select * from snr_'||case p_table when 'inoutline' then 'minoutline' else p_table end||'  where m_'||p_table||'_id = '||chr(39)||p_id||chr(39);
        OPEN v_cursor FOR EXECUTE v_sql;
        LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            -- Do checks only if not posted. Post-Process sets while posting masterdata ID through trigger snr_checkpost
            if v_cur.snr_masterdata_id is null and v_cur.snr_batchmasterdata_id is null then
                v_count:=v_count+1;
                if v_cur.quantity!=1 then
                return '@snr_qtymustbe1inserial@: '||v_name;
                end if;
                if   v_cur.serialnumber is null  then
                    return '@snr_noserialgiven@: '||v_name;
                end if;
                if coalesce(v_isbatch,'N')='N' and   v_cur.lotnumber is not null then
                    return '@snr_producthasnoserialtracking@: '||v_name;
                end if;
                select count(*) into v_exists from snr_masterdata where serialnumber=v_cur.serialnumber and m_product_id=v_product;
                -- New serial Numbers can only brought by metraial receipt -Transactions (+)
                if (v_movtype in ('D+','C+','M+','P+','V+','I+') and v_qty<0) or (v_movtype in ('MOV','D-','C-','M-','P-','V-')  and v_qty>0) then-- Outgoing TRX
                    -- Serial Number must be already existing
                    if v_exists=0 then
                        return '@snr_serialdoesntexist@: '||v_name;
                    else
                        select m_locator_id,snr_masterdata_id into v_locator,v_masterdata from snr_masterdata where m_product_id=v_product and serialnumber=v_cur.serialnumber;
                        if v_movtype='MOV' then
                            select m_locator_id into v_locator2 from m_movementline where m_movementline_id=v_cur.m_movementline_id;
                            if coalesce(v_locator,'#')!=coalesce(v_locator2,'') then
                                return '@snr_serialknownbutnotstocked@'||v_cur.serialnumber||'@snr_cannotusethisserial@: '||v_name;
                            end if;
                        end if;
                        -- All Outgoing Transactions must be on Stock
                        if (v_movtype in ('D-','C-','M-','P-','V-')  and v_qty>0) or (v_movtype in ('D+','C+','M+','P+','V+','I+') and v_qty<0) then                  
                            if v_locator is null then
                                return '@snr_serialknownbutnotstocked@'||v_cur.serialnumber||'@snr_cannotusethisserial@: '||v_name;
                            end if;
                            -- Attributes on a Serial number must match if stocktracking is active
                            if coalesce(v_attrstocked,'N')='Y' then
                                if (select count(*) from SNR_Serialnumbertracking where snr_masterdata_id=v_masterdata and coalesce(m_attributesetinstance_id,'0')=coalesce(v_attrset,'0'))=0  then
                                    return '@AttributeIsNotCorrectAssigned@: '||v_cur.serialnumber;
                                end if;
                            end if;
                        end if;
                    end if;
                else -- INCOMING TRX
                    if v_exists>0  then
                        select m_locator_id ,snr_masterdata_id into v_locator,v_masterdata from snr_masterdata where m_product_id=v_product and serialnumber=v_cur.serialnumber;
                        -- All Incoming Transactions must not be already on Stock
                        if (v_movtype in ('D+','C+','M+','P+','V+','I+') and v_qty>0) or (v_movtype in ('D-','C-','M-','P-','V-')  and v_qty<0) then                  
                                if v_locator is not null then
                                    return '@snr_isstocked@'||v_cur.serialnumber||'@snr_cannotstockagain@: '||v_name;
                                end if;
                        end if;
                        if v_movtype in ('P+') and v_qty>0 then
                            if v_masterdata is not null and (select count(*) from SNR_Serialnumbertracking where snr_masterdata_id=v_masterdata)>0 then
                              if (select assembly from c_projecttask where c_projecttask_id=(select c_projecttask_id from m_internal_consumptionline where m_internal_consumptionline_id=p_id))='Y' then 
                                return '@snr_isproduced@'||v_cur.serialnumber||'@snr_cannotstockagain@: '||v_name;
                              end if;
                            end if;
                        end if;
                        if v_movtype = 'IVT' then
                            -- Attributes on a Serial number must match if stocktracking is active
                            if coalesce(v_attrstocked,'N')='Y' then
                                if (select count(*) from SNR_Serialnumbertracking where snr_masterdata_id=v_masterdata and coalesce(m_attributesetinstance_id,'0')=coalesce(v_attrset,'0'))=0  then
                                    return '@AttributeIsNotCorrectAssigned@: '||v_cur.serialnumber;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if; -- Post-Process Checks
        END LOOP;
        CLOSE v_cursor; 
        if v_count > abs(v_qty) then 
                return '@snr_moreserialthanneeded@'||to_char(abs(v_qty))||'@snr_getnoofserial@: '||v_name;
        end if;
        if v_double>0 then 
                return '@snr_double@: '||v_name;
        end if;
    end if;
    -- Batch(LOT) Numbers
    if coalesce(v_isbatch,'N')='Y' then
        v_count:=0;
        v_sql:='select * from snr_'||case p_table when 'inoutline' then 'minoutline' else p_table end||'  where m_'||p_table||'_id = '||chr(39)||p_id||chr(39);
        OPEN v_cursor FOR EXECUTE v_sql;
        LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_count:=v_count+v_cur.quantity;
            if v_count > abs(v_qty) then 
                return '@snr_morethanbatchneed@'||to_char(abs(v_qty))||'@snr_products2batch@: '||v_name;
            end if;
            if v_cur.lotnumber is null  then
                return '@snr_nobatchgiven@: '||v_name;
            end if;
            if coalesce(v_isserial,'N')='N' and   v_cur.serialnumber is not null then
                return '@snr_producthasnoserialtracking@: '||v_name;
            end if;
            if v_movtype not in ('V+','P+','IVT','D+','C+','P+','V+','I+')  then
                select count(*) into v_exists from snr_batchmasterdata where batchnumber=v_cur.lotnumber and m_product_id=v_product;
                -- LOT Number must be already existing
                if v_exists=0 then
                    return '@snr_batchdoesntexist@: '||v_name;
                end if;
            else 
               -- LOT numbers cannot be serial numbers for the same Product
               select count(*) into v_exists from snr_masterdata where serialnumber=v_cur.lotnumber and m_product_id=v_product;
               if v_exists!=0 then
                    return '@snr_batchandserialmismatch@: '||v_name;
                end if;
            end if;
        END LOOP;
    end if;
    return 'OK';
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;




CREATE OR REPLACE FUNCTION snr_minoutline_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_processed character varying;
v_return character varying;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP != 'DELETE' THEN 
       select docstatus into v_processed from m_inout where m_inout_id=(select m_inout_id from m_inoutline where m_inoutline_id=new.m_inoutline_id);
       if v_processed='CO' then  
          raise exception '%', '@DocumentProcessed@';
       end if;
       if coalesce(new.serialnumber,'#')=coalesce(new.lotnumber,'x') then
            raise exception '%','@snr_batchandserialmismatch@';
       end if;
       select  snr_checkline('inoutline',new.m_inoutline_id) into v_return;
       if v_return!='OK' then raise exception '%', v_return; end if;
   else
       select docstatus into v_processed from m_inout where m_inout_id=(select m_inout_id from m_inoutline where m_inoutline_id=old.m_inoutline_id);
       if v_processed='CO' then  
          raise exception '%', '@DocumentProcessed@';
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_minoutline_trg','snr_minoutline');

CREATE TRIGGER snr_minoutline_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON snr_minoutline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_minoutline_trg();
 
  
 
CREATE OR REPLACE FUNCTION snr_internal_consumptionline_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_processed character varying;
v_return character varying;
v_qtyreceived numeric;
v_consumption varchar;
v_plannedsnr varchar;
v_task varchar;
v_product varchar;
v_allcalc varchar:='N';
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP != 'DELETE' THEN 
       select processed into v_processed from m_internal_consumption where m_internal_consumption_id=(select m_internal_consumption_id from m_internal_consumptionline where m_internal_consumptionline_id=new.m_internal_consumptionline_id);
       if v_processed='Y' then  
          if TG_OP = 'INSERT' then
            raise exception '%', '@DocumentProcessed@';
          end if;
          if TG_OP = 'UPDATE' then
            if new.isunavailable!=old.isunavailable or
               new.lotnumber!=old.lotnumber or
               new.serialnumber!=old.serialnumber or
               new.rfidnumber!=old.rfidnumber or
               new.quantity!=old.quantity
            then
                raise exception '%', '@DocumentProcessed@';
            end if;
          end if;
       end if;
       if coalesce(new.serialnumber,'#')=coalesce(new.lotnumber,'x') then
            raise exception '%','@snr_batchandserialmismatch@';
       end if;
       select  snr_checkline('internal_consumptionline',new.m_internal_consumptionline_id) into v_return;
       if v_return!='OK' then raise exception '%', v_return; end if;
        -- Check in Production Worksteps: Serials that are not Received cannot be returned.
        if (select count(*) from m_internal_consumptionline l,m_internal_consumption c,c_project p where l.m_internal_consumptionline_id=new.m_internal_consumptionline_id 
                   and l.m_internal_consumption_id=c.m_internal_consumption_id
                   and c.c_project_id=p.c_project_id and c.movementtype='D+' and p.projectcategory='PRO')=1
        then -- Production
             -- load task
             select c.m_internal_consumption_id,c.plannedserialnumber,l.c_projecttask_id,l.m_product_id into v_consumption,v_plannedsnr,v_task,v_product 
                   from m_internal_consumptionline l,m_internal_consumption c
                   where l.m_internal_consumptionline_id=new.m_internal_consumptionline_id 
                   and l.m_internal_consumption_id=c.m_internal_consumption_id;
             -- All Calc?
             if (select count(*) from m_internal_consumption c,c_project p where p.c_project_id=c.c_project_id and p.projectcategory='PRO' and c.c_projecttask_id=v_task and c.plannedserialnumber is null and c.processed='Y')>0 then
                v_allcalc:='Y';                
             end if;
             -- check Snrs
             select sum(rv) into v_qtyreceived from
               (select case when c.movementtype='D+' then (-1) else (1) end * sum(s.quantity) as rv  from m_internal_consumption c,m_internal_consumptionline l, snr_internal_consumptionline s
                 where l.m_internal_consumption_id=c.m_internal_consumption_id and c.c_projecttask_id=v_task and c.m_internal_consumption_id!=v_consumption
                 and s.m_internal_consumptionline_id=l.m_internal_consumptionline_id and coalesce(s.serialnumber,'')=coalesce(new.serialnumber,'') and coalesce(s.lotnumber,'')=coalesce(new.lotnumber,'') 
                 and l.m_product_id=v_product 
                 and case when v_allcalc='N' then coalesce(c.plannedserialnumber,'')=coalesce(v_plannedsnr,'') else 1=1 end
                 and c.processed='Y' and c.movementtype in ('D+','D-')
                 group by c.movementtype) a;
             if (v_qtyreceived is null) then v_qtyreceived=0; end if;  
             if v_qtyreceived<round(new.quantity,3) then
                if NOT ((select supply2vendor||assembly from c_projecttask where c_projecttask_id=v_task)='YN' and  -- Durchreiche-Artikel, Ausnahme : Lieferung Gerät als Beistellung (Hier Rücklieferung zulassen)
                   (select m_product_id from zspm_projecttaskbom where c_projecttask_id=v_task and isreturnafteruse='Y' order by line limit 1)=v_product)
                then
                        RAISE EXCEPTION '%', coalesce('SNR:'||v_plannedsnr,'')||' @zsmf_cannotbringbackmorethanreceived@ ' ||v_qtyreceived||', Snr/Cnr:'||coalesce(new.serialnumber,'')||coalesce(new.lotnumber,'')||'#'||(select value from m_product where M_Product_ID=v_product); 
                end if;
             end if;
        end if;
   else
       select processed into v_processed from m_internal_consumption where m_internal_consumption_id=(select m_internal_consumption_id from m_internal_consumptionline where m_internal_consumptionline_id=old.m_internal_consumptionline_id);
       if v_processed='Y' then  
          raise exception '%', '@DocumentProcessed@';
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_internal_consumptionline_trg','snr_internal_consumptionline');

CREATE TRIGGER snr_internal_consumptionline_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON snr_internal_consumptionline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_internal_consumptionline_trg();
 
CREATE OR REPLACE FUNCTION snr_inventoryline_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_processed character varying;
v_return character varying;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP != 'DELETE' THEN 
       select processed into v_processed from m_inventory where m_inventory_id=(select m_inventory_id from m_inventoryline where m_inventoryline_id=new.m_inventoryline_id);
       if v_processed='Y' then  
          raise exception '%', '@DocumentProcessed@';
       end if;
       select   snr_checkline('inventoryline',new.m_inventoryline_id) into v_return;
       
       if v_return!='OK' then raise exception '%', v_return; end if;
   else
       select processed into v_processed from m_inventory where m_inventory_id=(select m_inventory_id from m_inventoryline where m_inventoryline_id=old.m_inventoryline_id);
       if v_processed='Y' then  
          raise exception '%', '@DocumentProcessed@';
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_inventoryline_trg','snr_inventoryline');

CREATE TRIGGER snr_inventoryline_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON snr_inventoryline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_inventoryline_trg();
 
CREATE OR REPLACE FUNCTION snr_movementline_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_processed character varying;
v_return character varying;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP != 'DELETE' THEN 
       select processed into v_processed from m_movement where m_movement_id=(select m_movement_id from m_movementline where m_movementline_id=new.m_movementline_id);
       if v_processed='Y' then  
          raise exception '%', '@DocumentProcessed@';
       end if;
       select  snr_checkline('movementline',new.m_movementline_id) into v_return;
       if v_return!='OK' then raise exception '%', v_return; end if;
   else
       select processed into v_processed from m_movement where m_movement_id=(select m_movement_id from m_movementline where m_movementline_id=old.m_movementline_id);
       if v_processed='Y' then  
          raise exception '%', '@DocumentProcessed@';
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_movementline_trg','snr_movementline');

CREATE TRIGGER snr_movementline_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON snr_movementline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_movementline_trg();

select zsse_dropfunction('snr_initmasterdata');

CREATE OR REPLACE FUNCTION snr_initmasterdata(p_user varchar,p_org varchar,p_snr varchar,p_product varchar,p_batchno  varchar) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_count numeric;
v_isserial character varying;
v_isbatch character varying;
BEGIN
    select isserialtracking,isbatchtracking into v_isserial,v_isbatch from m_product where m_product_id=p_product;
    select count(*) into v_count  from snr_masterdata where serialnumber=coalesce(p_snr,'not available') and m_product_id=p_product;
    if v_count=0 and v_isserial='Y'  then
       insert into snr_masterdata (snr_masterdata_id,ad_client_id  , ad_org_id , isactive  ,created , createdby , updated, updatedby,
                                   m_product_id  , serialnumber, firstseen, movementdate)
              values(get_uuid(),'C726FEC915A54A0995C568555DA5BB3C'  , p_org , 'Y'  ,now(),p_user, now(),p_user,
                     p_product,coalesce(p_snr,'not available'),trunc(now()),now());
    end if;
    select count(*) into v_count  from snr_batchmasterdata where batchnumber=coalesce(p_batchno,'not available') and m_product_id=p_product;
    if v_count=0 and v_isbatch='Y'  then
       insert into snr_batchmasterdata (snr_batchmasterdata_id,ad_client_id  , ad_org_id , isactive  ,created , createdby , updated, updatedby,
                                   m_product_id  , batchnumber, firstseen)
              values(get_uuid(),'C726FEC915A54A0995C568555DA5BB3C'  , p_org , 'Y'  ,now(),p_user, now(),p_user,
                     p_product,coalesce(p_batchno,'not available'),trunc(now()));
    end if;
    return;
END; $_$;


CREATE OR REPLACE FUNCTION snr_checkpost(p_table character varying,p_id character varying) returns void
AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

***************************************************************************************************/
v_sql character varying;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_snrcur RECORD;
v_isserial character varying;
v_isbatch character varying;
v_type varchar;
v_mdate timestamp;
v_partner varchar;
v_bploc varchar;
v_count numeric:=0;
v_sercount numeric:=0;
v_batchqty numeric:=0;
v_qty numeric;
v_direction varchar;
v_snrmdid varchar;
v_bmdid varchar;
v_locator varchar;
v_masterdata_locator varchar;
v_locatorto varchar;
v_multi numeric;
v_msg varchar;
v_weight numeric;
BEGIN
    v_sql:='select * from m_'||p_table||'line  where m_'||p_table||'_id = '||chr(39)||p_id||chr(39);
    OPEN v_cursor FOR EXECUTE v_sql;
    LOOP
    FETCH v_cursor INTO v_cur;
    EXIT WHEN NOT FOUND;
    v_count:=v_count+1;
    select isserialtracking,isbatchtracking into v_isserial,v_isbatch from m_product where m_product_id=v_cur.m_product_id;
        if p_table='inventory' then
            select abs(qtycount),m_locator_id into v_qty,v_locator from m_inventoryline where m_inventoryline_id=v_cur.m_inventoryline_id;
            select count(*) into v_sercount from snr_inventoryline where m_inventoryline_id=v_cur.m_inventoryline_id;
            select sum(quantity) into v_batchqty from snr_inventoryline where m_inventoryline_id=v_cur.m_inventoryline_id;
            if v_isserial='Y' and v_qty!=v_sercount then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Seriennummern nicht korrekt vergeben. Es sind '||to_char(v_sercount)||' Seriennummern erfasst. Es müssen aber '||v_qty||' Seriennummern erfasst sein.';
            end if;
            if v_isbatch='Y' and v_qty!=coalesce(v_batchqty,0) then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Chargen nicht korrekt zugeordnet. Es sind '||to_char(coalesce(v_batchqty,0))||' Produkte einer Charge zugeordnet. Es müssen aber '||v_qty||' zugeordnet sein.';
            end if;
            if v_isserial='Y' or v_isbatch='Y' then
                v_type:='I+';
                -- Lost Serial Numbers
                insert into snr_inventorylinelost(SNR_INVENTORYLINElost_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, M_INVENTORYLINE_ID, QUANTITY, LOTNUMBER, 
                                            SERIALNUMBER, SNR_MASTERDATA_ID, SNR_BATCHMASTERDATA_ID)
                select get_uuid(),m.AD_CLIENT_ID, m.AD_ORG_ID, v_cur.CREATEDBY, v_cur.UPDATEDBY, v_cur.M_INVENTORYLINE_ID,0,(select b.batchnumber from snr_batchmasterdata b where b.snr_batchmasterdata_id=m.snr_batchmasterdata_id),
                        m.serialnumber, m.SNR_MASTERDATA_ID, m.SNR_BATCHMASTERDATA_ID 
                        from snr_masterdata m where m.m_product_id=v_cur.m_product_id and m.m_locator_id=v_cur.m_locator_id
                        and not exists (select 0 from snr_inventoryline s where  s.M_INVENTORYLINE_ID=v_cur.M_INVENTORYLINE_ID and s.serialnumber=m.serialnumber);
                -- Lost Batch Numbers
                insert into snr_inventorylinelost(SNR_INVENTORYLINElost_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, M_INVENTORYLINE_ID, QUANTITY, LOTNUMBER, 
                                                SNR_BATCHMASTERDATA_ID)
                select get_uuid(),m.AD_CLIENT_ID, m.AD_ORG_ID, v_cur.CREATEDBY, v_cur.UPDATEDBY, v_cur.M_INVENTORYLINE_ID,0,m.batchnumber,
                        m.SNR_BATCHMASTERDATA_ID 
                        from snr_batchmasterdata m,snr_batchlocator l where m.snr_batchmasterdata_id=l.snr_batchmasterdata_id
                            and m.m_product_id=v_cur.m_product_id and l.m_locator_id=v_cur.m_locator_id and l.qtyonhand>0
                            and not exists (select 0 from snr_inventoryline s where  s.M_INVENTORYLINE_ID=v_cur.M_INVENTORYLINE_ID and s.lotnumber=m.batchnumber);
                        
                update snr_masterdata set m_locator_id=null ,movementtype=v_type,m_inventoryline_id=null,c_bpartner_id=null,c_bpartner_location_id=null,c_projecttask_id=null,m_inoutline_id=null,m_internal_consumptionline_id=null,m_movementline_id=null
                where m_product_id=v_cur.m_product_id and m_locator_id=v_cur.m_locator_id;
                update snr_batchlocator set qtyonhand=0 where snr_batchmasterdata_id in (select snr_batchmasterdata_id from snr_batchmasterdata where m_product_id=v_cur.m_product_id)
                        and m_locator_id=v_cur.m_locator_id;
                for v_snrcur in (select * from snr_inventoryline where m_inventoryline_id=v_cur.m_inventoryline_id)
                LOOP
                    PERFORM snr_initmasterdata(v_snrcur.updatedby,v_snrcur.ad_org_id,v_snrcur.serialnumber,v_cur.m_product_id,v_snrcur.lotnumber);
                    
                    select movementdate into v_mdate from m_inventory where m_inventory_id=v_cur.m_inventory_id;
                    select snr_masterdata_id, m_locator_id,weight into v_snrmdid, v_masterdata_locator,v_weight from snr_masterdata where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;

                    -- überprüfe ob die eingetragene Seriennummer überhaupt im Lager der Position liegt (ggf. Korrigieren im Alt-Lagerort)
                    if v_locator != coalesce(v_masterdata_locator,v_locator) then
                        --raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' ist der Lagerort der Seriennummer nicht korrekt zugeordnet. Die Lagerorte der Seriennummer und des Produktes müssen gleich sein.'; 
                        if v_weight is null then
                            select weight into v_weight from m_product where m_product_id=v_cur.m_product_id;
                        end if;
                        update m_storage_detail set weight=weight-v_weight,qtyonhand=qtyonhand-1 where  m_locator_id=v_masterdata_locator and m_product_id=v_cur.m_product_id
                               and coalesce(M_AttributeSetInstance_ID,'0')=coalesce(v_cur.M_AttributeSetInstance_ID,'0');
                    end if;

                    select snr_batchmasterdata_id into v_bmdid from snr_batchmasterdata  where batchnumber=coalesce(v_snrcur.lotnumber,'not available') and m_product_id=v_cur.m_product_id;
                    if v_bmdid is not null and v_snrmdid is not null then
                        update snr_masterdata set snr_batchmasterdata_id=v_bmdid where snr_masterdata_id=v_snrmdid;
                    end if;
                    update snr_inventoryline set snr_masterdata_id = v_snrmdid,snr_batchmasterdata_id=v_bmdid where snr_inventoryline_id=v_snrcur.snr_inventoryline_id;
                    if v_bmdid is not null and (select count(*) from snr_batchlocator where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator)=0 then
                        insert into snr_batchlocator( snr_batchlocator_id,ad_client_id  , ad_org_id ,  createdby , updatedby,m_locator_id,snr_batchmasterdata_id)
                        values (get_uuid(),v_snrcur.ad_client_id  , v_snrcur.ad_org_id ,  v_snrcur.createdby , v_snrcur.updatedby,v_locator,v_bmdid);
                    end if;
                    
                    update snr_batchlocator set qtyonhand=(select sum(quantity) from snr_inventoryline where m_inventoryline_id=v_cur.m_inventoryline_id and snr_batchmasterdata_id=v_bmdid)
                        where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator;
                    update snr_masterdata set isactive='Y',updatedby= v_snrcur.updatedby,ad_org_id=v_snrcur.ad_org_id,updated=now(),
                        movementdate=v_mdate,movementtype=v_type,m_locator_id=v_cur.m_locator_id,m_inventoryline_id=v_cur.m_inventoryline_id,
                        c_bpartner_id=null,c_bpartner_location_id=null,c_projecttask_id=null,m_inoutline_id=null,m_internal_consumptionline_id=null,m_movementline_id=null
                    where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;
                END LOOP;
            end if;
        elsif p_table='inout' then
            select abs(movementqty),m_locator_id into v_qty,v_locator from m_inoutline where m_inoutline_id=v_cur.m_inoutline_id;
            select count(*) into v_sercount from snr_minoutline where m_inoutline_id=v_cur.m_inoutline_id;
            select sum(quantity) into v_batchqty  from snr_minoutline where m_inoutline_id=v_cur.m_inoutline_id;
            if v_isserial='Y' and v_qty!=v_sercount then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Seriennummern nicht korrekt vergeben. Es sind '||to_char(v_sercount)||' Seriennummern erfasst. Es müssen aber '||v_qty||' Seriennummern erfasst sein.';
            end if;
            if v_isbatch='Y' and v_qty!=coalesce(v_batchqty,0) then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Chargen nicht korrekt zugeordnet. Es sind '||to_char(coalesce(v_batchqty,0))||' Produkte einer Charge zugeordnet. Es müssen aber '||v_qty||' zugeordnet sein.';
            end if;
            if v_isserial='Y'  or v_isbatch='Y'  then
                for v_snrcur in (select * from snr_minoutline where m_inoutline_id=v_cur.m_inoutline_id and v_cur.movementqty!=0)
                LOOP
                    PERFORM snr_initmasterdata(v_snrcur.updatedby,v_snrcur.ad_org_id,v_snrcur.serialnumber,v_cur.m_product_id,v_snrcur.lotnumber);
                    select movementdate,movementtype,c_bpartner_id,c_bpartner_location_id into v_mdate,v_type,v_partner,v_bploc from m_inout where m_inout_id=v_cur.m_inout_id;
                    if instr(v_type,'+')>0 and v_cur.movementqty>0 then
                        v_direction:='in';
                    elsif instr(v_type,'+')>0 and v_cur.movementqty<0 then
                        v_direction:='out';
                    elsif instr(v_type,'-')>0 and v_cur.movementqty<0 then
                        v_direction:='in';
                    elsif instr(v_type,'-')>0 and v_cur.movementqty>0 then
                        v_direction:='out';
                    end if;
                    if v_direction='out' then v_multi:=-1; else v_multi:=1; end if;
                    --raise exception '%', v_direction;
                    select snr_masterdata_id, m_locator_id into v_snrmdid, v_masterdata_locator from snr_masterdata where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;
                     -- Zustandsfelder
                    update snr_masterdata set text1=v_snrcur.text1,text2=v_snrcur.text2,text3=v_snrcur.text3,text4=v_snrcur.text4,text5=v_snrcur.text5,text6=v_snrcur.text6,text7=v_snrcur.text7,
                                              text8=v_snrcur.text8,text9=v_snrcur.text9,text10=v_snrcur.text10,num1=v_snrcur.num1,num2=v_snrcur.num2,num3=v_snrcur.num3,
                                              num4=v_snrcur.num4,num5=v_snrcur.num5,date1=v_snrcur.date1,date2=v_snrcur.date2,date3=v_snrcur.date3,date4=v_snrcur.date4
                        where snr_masterdata_id=v_snrmdid;
            -- überprüfe ob die eingetragene Seriennummer überhaupt im Lager der Position liegt
            if v_locator != v_masterdata_locator then
                    raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' ist der Lagerort der Seriennummer nicht korrekt zugeordnet. Die Lagerorte der Seriennummer und des Produktes müssen gleich sein.'; 
            end if;

                    select snr_batchmasterdata_id into v_bmdid from snr_batchmasterdata  where batchnumber=coalesce(v_snrcur.lotnumber,'not available') and m_product_id=v_cur.m_product_id;
                    if v_bmdid is not null and v_snrmdid is not null then
                        update snr_masterdata set snr_batchmasterdata_id=v_bmdid where snr_masterdata_id=v_snrmdid;
                    end if;
                    update snr_minoutline set snr_masterdata_id = v_snrmdid,snr_batchmasterdata_id=v_bmdid where snr_minoutline_id=v_snrcur.snr_minoutline_id;
                    if  v_bmdid is not null and (select count(*) from snr_batchlocator where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator)=0 then
                        insert into snr_batchlocator( snr_batchlocator_id,ad_client_id  , ad_org_id ,  createdby , updatedby,m_locator_id,snr_batchmasterdata_id)
                        values (get_uuid(),v_snrcur.ad_client_id  , v_snrcur.ad_org_id ,  v_snrcur.createdby , v_snrcur.updatedby,v_locator,v_bmdid);
                    end if;
                    update snr_batchlocator set qtyonhand=qtyonhand + (v_snrcur.quantity*v_multi) where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator;
                    update snr_masterdata set isactive='Y',updatedby= v_snrcur.updatedby,ad_org_id=v_snrcur.ad_org_id,updated=now(),
                        movementdate=v_mdate,movementtype=v_type,m_locator_id=case when v_direction='in' then v_cur.m_locator_id else null end,m_inventoryline_id=null,
                        c_bpartner_id=case when v_direction='out' then v_partner else null end,c_bpartner_location_id=case when v_direction='out' then v_bploc else null end,
                        c_projecttask_id=v_cur.c_projecttask_id,m_inoutline_id=v_cur.m_inoutline_id,m_internal_consumptionline_id=null,m_movementline_id=null,
                        ad_user_id=case when v_direction='in' then v_cur.ad_user_id else null end
                    where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;
                END LOOP;
            end if;
        elsif p_table='internal_consumption' then 
            select abs(movementqty),m_locator_id into v_qty,v_locator from m_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id;
            select count(*) into v_sercount from snr_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id;
            select sum(quantity) into v_batchqty from snr_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id;
            if v_isserial='Y' and v_qty!=v_sercount then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Seriennummern nicht korrekt vergeben. Es sind '||to_char(v_sercount)||' Seriennummern erfasst. Es müssen aber '||v_qty||' Seriennummern erfasst sein.';
            end if;
            if v_isbatch='Y' and v_qty!=coalesce(v_batchqty,0) then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Chargen nicht korrekt zugeordnet. Es sind '||to_char(coalesce(v_batchqty,0))||' Produkte einer Charge zugeordnet. Es müssen aber '||v_qty||' zugeordnet sein.';
            end if;
            if v_isserial='Y' or v_isbatch='Y' then
                for v_snrcur in (select * from snr_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id and v_cur.movementqty!=0)
                LOOP
                    PERFORM snr_initmasterdata(v_snrcur.updatedby,v_snrcur.ad_org_id,v_snrcur.serialnumber,v_cur.m_product_id,v_snrcur.lotnumber);
                    select movementdate,movementtype into v_mdate,v_type from m_internal_consumption where m_internal_consumption_id=v_cur.m_internal_consumption_id;
                    if instr(v_type,'+')>0 and v_cur.movementqty>0 then
                        v_direction:='in';
                    elsif instr(v_type,'+')>0 and v_cur.movementqty<0 then
                        v_direction:='out';
                    elsif instr(v_type,'-')>0 and v_cur.movementqty<0 then
                        v_direction:='in';
                    elsif instr(v_type,'-')>0 and v_cur.movementqty>0 then
                        v_direction:='out';
                    end if;
                    if v_direction='out' then v_multi:=-1; else v_multi:=1; end if;
                    --raise exception '%', v_direction;
                    select snr_masterdata_id, m_locator_id into v_snrmdid, v_masterdata_locator from snr_masterdata where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;
                    -- Zustandsfelder
                    update snr_masterdata set text1=v_snrcur.text1,text2=v_snrcur.text2,text3=v_snrcur.text3,text4=v_snrcur.text4,text5=v_snrcur.text5,text6=v_snrcur.text6,text7=v_snrcur.text7,
                                              text8=v_snrcur.text8,text9=v_snrcur.text9,text10=v_snrcur.text10,num1=v_snrcur.num1,num2=v_snrcur.num2,num3=v_snrcur.num3,
                                              num4=v_snrcur.num4,num5=v_snrcur.num5,date1=v_snrcur.date1,date2=v_snrcur.date2,date3=v_snrcur.date3,date4=v_snrcur.date4
                    where snr_masterdata_id=v_snrmdid;
            -- überprüfe ob die eingetragene Seriennummer überhaupt im Lager der Position liegt
            if v_locator != v_masterdata_locator then
                    raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' ist der Lagerort der Seriennummer nicht korrekt zugeordnet. Die Lagerorte der Seriennummer und des Produktes müssen gleich sein.'; 
            end if;

                    select snr_batchmasterdata_id into v_bmdid from snr_batchmasterdata  where batchnumber=coalesce(v_snrcur.lotnumber,'not available') and m_product_id=v_cur.m_product_id;
                    if v_bmdid is not null and v_snrmdid is not null then
                        update snr_masterdata set snr_batchmasterdata_id=v_bmdid where snr_masterdata_id=v_snrmdid;
                    end if;
                    update snr_internal_consumptionline set snr_masterdata_id = v_snrmdid,snr_batchmasterdata_id=v_bmdid where snr_internal_consumptionline_id=v_snrcur.snr_internal_consumptionline_id;
                    if  v_bmdid is not null and (select count(*) from snr_batchlocator where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator)=0 then
                        insert into snr_batchlocator( snr_batchlocator_id,ad_client_id  , ad_org_id ,  createdby , updatedby,m_locator_id,snr_batchmasterdata_id)
                        values (get_uuid(),v_snrcur.ad_client_id  , v_snrcur.ad_org_id ,  v_snrcur.createdby , v_snrcur.updatedby,v_locator,v_bmdid);
                    end if;
                    update snr_batchlocator set qtyonhand=qtyonhand + (v_snrcur.quantity*v_multi) where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator;
                    update snr_masterdata set isactive='Y',updatedby= v_snrcur.updatedby,ad_org_id=v_snrcur.ad_org_id,updated=now(),
                        movementdate=v_mdate,movementtype=v_type,m_locator_id=case when v_direction='in' then v_cur.m_locator_id else null end,m_inventoryline_id=null,
                        c_bpartner_id=null,c_bpartner_location_id=null,
                        c_projecttask_id=v_cur.c_projecttask_id ,m_inoutline_id=null,m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id,m_movementline_id=null
                    where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;
                END LOOP;
            end if;
        elsif p_table='movement' then
            select abs(movementqty),m_locator_id,m_locatorto_id into v_qty,v_locator,v_locatorto from m_movementline where m_movementline_id=v_cur.m_movementline_id;
            select count(*) into v_sercount from snr_movementline where m_movementline_id=v_cur.m_movementline_id;
            select sum(quantity) into v_batchqty from snr_movementline where m_movementline_id=v_cur.m_movementline_id;
            if v_isserial='Y' and v_qty!=v_sercount then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Seriennummern nicht korrekt vergeben. Es sind '||to_char(v_sercount)||' Seriennummern erfasst. Es müssen aber '||v_qty||' Seriennummern erfasst sein.';
            end if;
            if v_isbatch='Y' and v_qty!=coalesce(v_batchqty,0) then
            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' sind die Chargen nicht korrekt zugeordnet. Es sind '||to_char(coalesce(v_batchqty,0))||' Produkte einer Charge zugeordnet. Es müssen aber '||v_qty||' zugeordnet sein.';
            end if;
            if v_isserial='Y' or v_isbatch='Y' then
                for v_snrcur in (select * from snr_movementline where m_movementline_id=v_cur.m_movementline_id)
                LOOP
                    PERFORM snr_initmasterdata(v_snrcur.updatedby,v_snrcur.ad_org_id,v_snrcur.serialnumber,v_cur.m_product_id,v_snrcur.lotnumber);
                    v_type:='M+';
                    if v_isserial='Y' then 
                        select snr_masterdata_id, m_locator_id into v_snrmdid, v_masterdata_locator from snr_masterdata where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;
                        -- überprüfe ob die eingetragene Seriennummer überhaupt im Lager der Position liegt
                        if v_locator != v_masterdata_locator then
                                raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' ist der Lagerort der Seriennummer nicht korrekt zugeordnet. Die Lagerorte der Seriennummer und des Produktes müssen gleich sein.'; 
                        end if;
                    end if;
                    if v_isbatch='Y' then
                        select snr_batchmasterdata_id into v_bmdid from snr_batchmasterdata  where batchnumber=coalesce(v_snrcur.lotnumber,'not available') and m_product_id=v_cur.m_product_id;
                        if v_bmdid is not null and v_snrmdid is not null and v_isserial='Y' then
                            update snr_masterdata set snr_batchmasterdata_id=v_bmdid where snr_masterdata_id=v_snrmdid;
                        end if;
                        if (select count(*) from snr_batchlocator where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator)=0 then
                            insert into snr_batchlocator( snr_batchlocator_id,ad_client_id  , ad_org_id ,  createdby , updatedby,m_locator_id,snr_batchmasterdata_id)
                            values (get_uuid(),v_snrcur.ad_client_id  , v_snrcur.ad_org_id ,  v_snrcur.createdby , v_snrcur.updatedby,v_locator,v_bmdid);
                        end if;
                        if  v_bmdid is not null and (select count(*) from snr_batchlocator where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locatorto )=0 then
                            insert into snr_batchlocator( snr_batchlocator_id,ad_client_id  , ad_org_id ,  createdby , updatedby,m_locator_id,snr_batchmasterdata_id)
                            values (get_uuid(),v_snrcur.ad_client_id  , v_snrcur.ad_org_id ,  v_snrcur.createdby , v_snrcur.updatedby,v_locatorto ,v_bmdid);
                        end if;
                        if (select qtyonhand - v_snrcur.quantity from snr_batchlocator where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator)<0 then
                            raise exception '%', 'In Zeile '||v_cur.line||': Für das Produkt '||zssi_getproductname(v_cur.m_product_id,'de_DE')||' ist die Lagermenge für die Aktion nicht ausreichend.';
                        end if;
                        update snr_batchlocator set qtyonhand=qtyonhand - v_snrcur.quantity where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locator;
                        update snr_batchlocator set qtyonhand=qtyonhand + v_snrcur.quantity where snr_batchmasterdata_id=v_bmdid and m_locator_id=v_locatorto;
                    end if;
                    update snr_movementline set snr_masterdata_id = case when v_isserial='Y' then v_snrmdid else null end,snr_batchmasterdata_id=case when v_isbatch='Y' then v_bmdid else null end 
                           where snr_movementline_id=v_snrcur.snr_movementline_id;
                    select movementdate into v_mdate from m_movement where m_movement_id=v_cur.m_movement_id;
                    update snr_masterdata set isactive='Y',updatedby= v_snrcur.updatedby,ad_org_id=v_snrcur.ad_org_id,updated=now(),
                        movementdate=v_mdate,movementtype=v_type,m_locator_id=v_cur.m_locatorto_id,m_inventoryline_id=null,
                        c_bpartner_id=null,c_bpartner_location_id=null,c_projecttask_id=null,m_inoutline_id=null,m_internal_consumptionline_id=null,m_movementline_id=v_cur.m_movementline_id
                    where serialnumber=coalesce(v_snrcur.serialnumber,'not available') and m_product_id=v_cur.m_product_id;
                END LOOP;
            end if;
        end if;
    END LOOP;
    CLOSE v_cursor;
    -- Stücklisten von Geräten prüfen, bei + Trxes müssen die SNR da raus sein.
    If  instr(coalesce(v_type,''),'+')>0 then
      if p_table='inventory' then
        select count(*),string_agg(s.serialnumber,',') into v_count,v_msg from snr_inventoryline s,m_inventoryline ml, m_inventory m, snr_currentbom_serials bs
               where ml.m_inventory_id=m.m_inventory_id and ml.m_inventoryline_id=s.m_inventoryline_id 
               and bs.snr_masterdata_id=s.snr_masterdata_id and m.m_inventory_id=p_id;
      end if;
      if p_table='inout'  then
        select count(*),string_agg(s.serialnumber,',') into v_count,v_msg from snr_minoutline s,m_inoutline ml, m_inout m , snr_currentbom_serials bs
            where ml.m_inout_id=m.m_inout_id and ml.m_inoutline_id=s.m_inoutline_id 
            and  bs.snr_masterdata_id=s.snr_masterdata_id and m.m_inout_id=p_id and ml.movementqty>0;
      end if;
      if p_table='internal_consumption' then
            select count(*),string_agg(s.serialnumber,',') into v_count,v_msg from snr_internal_consumptionline s,m_internal_consumptionline ml, m_internal_consumption m , snr_currentbom_serials bs
               where ml.m_internal_consumption_id=m.m_internal_consumption_id and ml.m_internal_consumptionline_id=s.m_internal_consumptionline_id
               and  bs.snr_masterdata_id=s.snr_masterdata_id and m.m_internal_consumption_id=p_id and ml.movementqty> 0 and ml.snr_masterdata_id is null;
      end if;
      if (v_count)>0 then
            raise exception '%', '@snr_isinSnrBOM@'||coalesce(v_msg,'SNRNULL!')||'@snr_cannotstockagain@';
      end if;
    end if;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;


CREATE OR REPLACE FUNCTION snr_minout_trg()
RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'UPDATE' THEN
       -- Reservations are not checked
       if new.docstatus='CO' and old.docstatus!='CO' then 
            perform snr_checkpost('inout',new.m_inout_id);
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_minout_trg','m_inout');

CREATE TRIGGER snr_minout_trg
  BEFORE UPDATE
  ON m_inout
  FOR EACH ROW
  EXECUTE PROCEDURE snr_minout_trg();
 
CREATE OR REPLACE FUNCTION snr_internal_consumption_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_cur record;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'UPDATE' THEN
       if new.processed='Y' and old.processed='N' then 
            perform snr_checkpost('internal_consumption',new.m_internal_consumption_id);
            -- Build up current BOM in Serial Masterdata, if Applicable 
            for v_cur in (select m_internal_consumptionline_id from m_internal_consumptionline where m_internal_consumption_id=new.m_internal_consumption_id)
            LOOP
                perform snrUpdateCurrentBom(v_cur.m_internal_consumptionline_id);
            END LOOP;
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_internal_consumption_trg','m_internal_consumption');

CREATE TRIGGER snr_internal_consumption_trg
  BEFORE UPDATE
  ON m_internal_consumption
  FOR EACH ROW
  EXECUTE PROCEDURE snr_internal_consumption_trg();
 
CREATE OR REPLACE FUNCTION snr_inventory_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   
   IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') then
     if (select count(*) from m_inventoryline where m_inventory_id=new.m_inventory_id and m_locator_id not in (select m_locator_id from m_locator where m_warehouse_id=new.m_warehouse_id))>0 then
        RAISE EXCEPTION '%', '@orgOfLocatorDifferentStockthenTransaction@' ;
     end if;
     if (select ad_org_id from m_warehouse where m_warehouse_id=new.m_warehouse_id)!='0' then
        if (select ad_org_id from m_warehouse where m_warehouse_id=new.m_warehouse_id)!=new.ad_org_id then
            RAISE EXCEPTION '%', '@orgOfLocatorDifferentOrgthenTransaction@' ;
        end if;
     end if;
    end if;
   
   IF TG_OP = 'UPDATE' THEN
       if new.processed='Y' and old.processed='N' then 
            perform snr_checkpost('inventory',new.m_inventory_id);
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_inventory_trg','m_inventory');

CREATE TRIGGER snr_inventory_trg
  BEFORE INSERT or UPDATE
  ON m_inventory
  FOR EACH ROW
  EXECUTE PROCEDURE snr_inventory_trg();
 
CREATE OR REPLACE FUNCTION snr_movement_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'UPDATE' THEN
       if new.processed='Y' and old.processed='N' then 
            perform snr_checkpost('movement',new.m_movement_id);
       end if;
   end if;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_movement_trg','m_movement');

CREATE TRIGGER snr_movement_trg
  BEFORE UPDATE
  ON m_movement
  FOR EACH ROW
  EXECUTE PROCEDURE snr_movement_trg();

CREATE or replace FUNCTION snr_correction() RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Only Used by ROLLOUT V76

*****************************************************/
DECLARE
v_return character varying;
v_conid character varying;
v_cur record;
v_cur2 record;
v_qty numeric;
BEGIN
      for v_cur in (select distinct m_product_id,serialnumber,ad_org_id,updatedby,lotnumber from snr_serialnumbertracking)
      LOOP
        PERFORM snr_initmasterdata(v_cur.updatedby,v_cur.ad_org_id,v_cur.serialnumber,v_cur.m_product_id,v_cur.lotnumber);
      END LOOP;
      for v_cur in (select * from snr_masterdata)
      LOOP
        for v_cur2 in (select * from snr_serialnumbertracking snr,m_product p where p.m_product_id=snr.m_product_id and p.isserialtracking='Y'
                       and snr.m_product_id=v_cur.m_product_id and snr.serialnumber=v_cur.serialnumber  and snr.docstatus in ('CO','VO') order by snr.updated desc limit 1)
        LOOP
            if v_cur2.m_inoutline_id is not null then
                select movementqty into v_qty from m_inoutline where m_inoutline_id=v_cur2.m_inoutline_id;
                if instr(v_cur.movementtype,'-')>0  and v_qty>0 then
                    update snr_masterdata set m_locator_id=null,m_internal_consumptionline_id=null,m_inventoryline_id=null,m_movementline_id=null,c_projecttask_id= null, 
                               m_inoutline_id = v_cur2.m_inoutline_id,
                               c_bpartner_id=  v_cur2.c_bpartner_id where  snr_masterdata_id= v_cur.snr_masterdata_id;      
                end if;
                if instr(v_cur.movementtype,'-')>0  and v_qty<0 then
                    update snr_masterdata set m_locator_id=v_cur2.m_locator_id,m_internal_consumptionline_id=null,m_inventoryline_id=null,m_movementline_id=null,c_projecttask_id= null, 
                               m_inoutline_id = v_cur2.m_inoutline_id,
                               c_bpartner_id= null, c_bpartner_location_id= null where  snr_masterdata_id= v_cur.snr_masterdata_id;      
                end if;
                if instr(v_cur.movementtype,'+')>0  and v_qty>0 then
                    update snr_masterdata set m_locator_id=v_cur2.m_locator_id,m_internal_consumptionline_id=null,m_inventoryline_id=null,m_movementline_id=null,c_projecttask_id= null, 
                               m_inoutline_id = v_cur2.m_inoutline_id,
                               c_bpartner_id=  null, c_bpartner_location_id= null where  snr_masterdata_id= v_cur.snr_masterdata_id;      
                end if;
                if instr(v_cur.movementtype,'+')>0  and v_qty<0 then
                    update snr_masterdata set m_locator_id=null,m_internal_consumptionline_id=null,m_inventoryline_id=null,m_movementline_id=null,c_projecttask_id= null, 
                               m_inoutline_id = v_cur2.m_inoutline_id,
                               c_bpartner_id=  v_cur2.c_bpartner_id where  snr_masterdata_id= v_cur.snr_masterdata_id;      
                end if;
            end if;
            if v_cur2.m_internal_consumptionline_id is not null then
                select movementqty into v_qty from m_internal_consumptionline where m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id;
                if instr(v_cur.movementtype,'-')>0  and v_qty>0 then
                    update snr_masterdata set m_locator_id=null,m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id,m_inventoryline_id=null,m_movementline_id=null,
                               c_projecttask_id= v_cur2.c_projecttask_id, 
                               m_inoutline_id = null,
                               c_bpartner_id=  null, c_bpartner_location_id= null where  snr_masterdata_id= v_cur.snr_masterdata_id;    
                end if;
                if instr(v_cur.movementtype,'-')>0  and v_qty<0 then
                    update snr_masterdata set m_locator_id=v_cur2.m_locator_id,m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id,m_inventoryline_id=null,m_movementline_id=null,
                               c_projecttask_id= null, 
                               m_inoutline_id = null,
                               c_bpartner_id=  null, c_bpartner_location_id= null where  snr_masterdata_id= v_cur.snr_masterdata_id;     
                end if;
                if instr(v_cur.movementtype,'+')>0  and v_qty>0 then
                    update snr_masterdata set m_locator_id=v_cur2.m_locator_id,m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id,m_inventoryline_id=null,m_movementline_id=null,
                               c_projecttask_id= null, 
                               m_inoutline_id = null,
                               c_bpartner_id=  null, c_bpartner_location_id= null where  snr_masterdata_id= v_cur.snr_masterdata_id;      
                end if;
                if instr(v_cur.movementtype,'+')>0  and v_qty<0 then
                    update snr_masterdata set m_locator_id=null,m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id,m_inventoryline_id=null,m_movementline_id=null,
                               c_projecttask_id=v_cur2.c_projecttask_id, 
                               m_inoutline_id = null,
                               c_bpartner_id=  null, c_bpartner_location_id= null where  snr_masterdata_id= v_cur.snr_masterdata_id;  
                end if;
            end if;
        END LOOP; 
      END LOOP;
RETURN coalesce('Serial Number Location Correction: DONE');
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;

CREATE or replace FUNCTION snr_batchcorrection() RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Only Used by ROLLOUT V3.08

Obsolete Empty Function (Backward Compat.

select p.name,snr.lotnumber,snr.created,snr.m_inoutline_id,snr.m_internal_consumptionline_id,snr.m_inventoryline_id,snr.docstatus,snr.m_locator_id ,snr.snr_batchmasterdata_id
from snr_serialnumbertracking snr,m_product p where p.m_product_id=snr.m_product_id and p.isbatchtracking='Y'  and not exists
(select 0 from snr_batchmasterdata md where md.snr_batchmasterdata_id=snr.snr_batchmasterdata_id) order by created;

*****************************************************/
DECLARE
BEGIN
RETURN coalesce('Batch Number Location Correction: DONE');
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;


CREATE OR REPLACE FUNCTION snr_batchlocator_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_currqty numeric;
BEGIN
 IF TG_OP = 'INSERT' or  TG_OP = 'UPDATE'  THEN
    if new.qtyonhand<0 then
        RAISE EXCEPTION '%', '@cannotdelivermorethanstocked@:'||(select p.name||' - No.'||b.batchnumber from m_product p,snr_batchmasterdata b
                                                                 where b.snr_batchmasterdata_id=new.snr_batchmasterdata_id and b.m_product_id=p.m_product_id) ;
    end if;
    select sum(qtyonhand) into v_currqty from snr_batchlocator where snr_batchlocator.snr_batchmasterdata_id=new.snr_batchmasterdata_id and snr_batchlocator_id!=new.snr_batchlocator_id;
    update snr_batchmasterdata set qtyonhand=coalesce(v_currqty,0)+new.qtyonhand where snr_batchmasterdata_id=new.snr_batchmasterdata_id;
 END IF;
 if TG_OP = 'DELETE' then
    select sum(qtyonhand) into v_currqty from snr_batchlocator where snr_batchlocator.snr_batchmasterdata_id=old.snr_batchmasterdata_id and snr_batchlocator_id!=old.snr_batchlocator_id;
    update snr_batchmasterdata set qtyonhand=coalesce(v_currqty,0) where snr_batchmasterdata_id=old.snr_batchmasterdata_id;
 end if;
 IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_batchlocator_trg','snr_batchlocator');

CREATE TRIGGER snr_batchlocator_trg
  BEFORE INSERT or DELETE or UPDATE
  ON snr_batchlocator
  FOR EACH ROW
  EXECUTE PROCEDURE snr_batchlocator_trg();
 


CREATE OR REPLACE FUNCTION snr_masterdata_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
    v_attr varchar;
BEGIN
 IF TG_OP = 'INSERT' THEN
    if (select  isserialtracking from m_product where m_product_id=new.m_product_id)='N' then
        raise exception '%', '@ProductNeedsSerialtracking@';
    end if;
    if NEW.movementtype is null then
        NEW.m_locator_id=null;
    end if;
    if NEW.movementtype='P+' and new.c_projecttask_id is not null then
        select m_attributesetinstance_id into v_attr from c_projecttask where c_projecttask_id=new.c_projecttask_id;
        new.m_attributesetinstance_id:=v_attr;
    end if;
 end if;
 IF TG_OP = 'DELETE' THEN
    if old.movementtype is not null then
        raise exception '%', '@deleteofusedserialnumbernotpossible@';
    end if;
 END IF;
 IF TG_OP = 'UPDATE' THEN
    if new.isactive='N' and (new.m_locator_id is not null or new.c_projecttask_id is not null) then
        raise exception '%', '@deleteofusedserialnumbernotpossible@';
    end if;
 END IF;
 IF TG_OP = 'UPDATE' or TG_OP = 'INSERT' THEN
    if instr(new.serialnumber,'|')>0 and c_getconfigoption('kombibarcode','0')='Y' then
        raise exception '%', '@invalidcharacter@'||': |';
    end if;
 end if;
 IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_masterdata_trg','snr_masterdata');

CREATE TRIGGER snr_masterdata_trg
  BEFORE INSERT or DELETE or UPDATE
  ON snr_masterdata
  FOR EACH ROW
  EXECUTE PROCEDURE snr_masterdata_trg();
 
 
CREATE OR REPLACE FUNCTION snr_batchmasterdata_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

BEGIN
 
 IF TG_OP = 'UPDATE' or TG_OP = 'INSERT' THEN
    if instr(new.batchnumber,'|')>0 and c_getconfigoption('kombibarcode','0')='Y' then
        raise exception '%', '@invalidcharacter@'||': |';
    end if;
 end if;
 IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('snr_batchmasterdata_trg','snr_batchmasterdata');

CREATE TRIGGER snr_batchmasterdata_trg
  BEFORE INSERT or DELETE or UPDATE
  ON snr_batchmasterdata
  FOR EACH ROW
  EXECUTE PROCEDURE snr_batchmasterdata_trg();
 
  
 
CREATE OR REPLACE FUNCTION getAutoLotNo(v_org varchar, issotrx varchar,v_minoutline_id varchar, choice varchar)
  RETURNS varchar AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_return varchar;
v_serial varchar;
v_batch varchar;
v_mmdate timestamp with time zone;
v_type varchar;
BEGIN
    -- only Incommin transactions
    if issotrx='N' then
        select p.isserialtracking,p.isbatchtracking  into v_serial,v_batch from m_product p, m_inoutline m where m.m_product_id=p.m_product_id and m.m_inoutline_id = v_minoutline_id;
        select movementdate,movementtype into v_mmdate,v_type from m_inout,m_inoutline where m_inoutline.m_inout_id=m_inout.m_inout_id and m_inoutline.m_inoutline_id=v_minoutline_id;
  --      if c_getconfigoption('autoselectlotnumber', v_org)='Y' and v_serial = 'N' and v_batch='Y'  and v_type='V+' then
        if choice = 'batch' then
            if c_getconfigoption('cnrdin', v_org)='Y'  then
                v_return:=zssi_cnrcodex(v_mmdate);
            else
                select p_documentno into v_return from ad_sequence_doc('Batchnumber',v_org,'Y');
            end if;
        elsif choice = 'serial' then
                select p_documentno into v_return from ad_sequence_doc('Serialnumber',v_org,'Y');
        end if;
    end if;
    return coalesce(v_return,'');
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION getLotQtyLeft(v_minoutline_id varchar)
  RETURNS numeric AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_retval numeric;
v_serial varchar;
v_batch varchar;
BEGIN
    select p.isserialtracking,p.isbatchtracking  into v_serial,v_batch from m_product p, m_inoutline m where m.m_product_id=p.m_product_id and m.m_inoutline_id = v_minoutline_id;
    if v_serial = 'Y' then
        v_retval:=1;
    end if;
    if v_serial = 'N' and v_batch='Y' then 
        select l.movementqty-coalesce(sum(s.quantity),0) into v_retval from m_inoutline l left join snr_minoutline s on s.m_inoutline_id=l.m_inoutline_id where l.m_inoutline_id = v_minoutline_id
        group by l.movementqty;
    end if;
    return coalesce(v_retval,0);
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  


CREATE OR REPLACE FUNCTION getBuiltInSerials(p_snr_curentbom_id varchar)
  RETURNS varchar AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_cur record;
v_retval varchar:='';
BEGIN
    for v_cur in (select serialnumber from snr_masterdata where snr_masterdata_id in 
                         (select snr_masterdata_id from snr_currentbom_serials where snr_currentbom_v_id=p_snr_curentbom_id) )
    LOOP
        if v_retval='' then 
            v_retval:=v_cur.serialnumber;
        else
            v_retval:=v_retval||'-'||v_cur.serialnumber;
        end if;
    END LOOP;
    return v_retval;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;  
  
CREATE OR REPLACE FUNCTION getBuiltInBatches(p_snr_curentbom_id varchar)
  RETURNS varchar AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_cur record;
v_retval varchar:='';
BEGIN
    for v_cur in (select batchnumber from snr_batchmasterdata where snr_batchmasterdata_id in 
                         (select snr_batchmasterdata_id from snr_currentbom_serials where snr_currentbom_v_id=p_snr_curentbom_id)) 
    LOOP
        if v_retval='' then 
            v_retval:=v_cur.batchnumber;
        else
            v_retval:=v_retval||'-'||v_cur.batchnumber;
        end if;
    END LOOP;
    return v_retval;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;  
  

select zsse_DropView ('snr_currentbom_v');
CREATE OR REPLACE VIEW snr_currentbom_v AS 
 SELECT snr_currentbom_id as snr_currentbom_v_id, snr_masterdata_id,line,
         ad_client_id, ad_org_id, 'Y'::character as isactive , created  , createdby , updated,updatedby,
        m_product_id, qty,text1,text2,
        m_get_product_cost(m_product_id,trunc(now()),null,ad_org_id)*qty as cost,
        getBuiltInSerials(snr_currentbom_id) as serials,
        getBuiltInBatches(snr_currentbom_id) as batches
 from snr_currentbom
 where snr_masterdata_id is not null;
 

CREATE OR REPLACE RULE snr_currentbom_v_insert AS
    ON INSERT TO snr_currentbom_v DO INSTEAD  
       INSERT INTO snr_currentbom(snr_currentbom_id, snr_masterdata_id, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, qty,text1,text2) 
       VALUES (new.snr_currentbom_v_id, new.snr_masterdata_id, new.ad_client_id, new.ad_org_id, new.createdby, new.updatedby, new.m_product_id, new.qty,new.text1,new.text2);


CREATE OR REPLACE RULE snr_currentbom_v_update AS
    ON UPDATE TO snr_currentbom_v DO INSTEAD  
    UPDATE snr_currentbom SET snr_masterdata_id=new.snr_masterdata_id, ad_client_id=new.ad_client_id, ad_org_id=new.ad_org_id, createdby=new.createdby, updatedby=new.updatedby, m_product_id=new.m_product_id,
       qty=new.qty,text1=new.text1,text2=new.text2
    WHERE  snr_currentbom_id=new.snr_currentbom_v_id;

CREATE OR REPLACE RULE snr_currentbom_v_delete AS
    ON DELETE TO snr_currentbom_v DO INSTEAD  DELETE FROM snr_currentbom
  WHERE snr_currentbom_id=old.snr_currentbom_v_id;

select zsse_DropView ('snr_builtinserials_v');
CREATE OR REPLACE VIEW snr_builtinserials_v AS 

 SELECT snr_currentbom_serials_id as snr_builtinserials_v_id,
	snr_currentbom_v_id,
	snr_masterdata_id as serial,
	snr_batchmasterdata_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	Qty
 from snr_currentbom_serials
 where snr_masterdata_id is not null;
        

select zsse_DropView ('snr_batchcurrentbom_v');
CREATE OR REPLACE VIEW snr_batchcurrentbom_v AS 
 SELECT snr_currentbom_id as snr_batchcurrentbom_v_id, snr_masterdata_id, snr_batchmasterdata_id,
         ad_client_id, ad_org_id, 'Y'::character as isactive , created  , createdby , updated,updatedby,
        m_product_id, qty,m_get_product_cost(m_product_id,trunc(now()),null,ad_org_id)*qty as cost,
        getBuiltInSerials(snr_currentbom_id) as serials,
        getBuiltInBatches(snr_currentbom_id) as batches
 from snr_currentbom
 where snr_batchmasterdata_id is not null;


select zsse_DropView ('snr_builtinbatches_v');
CREATE OR REPLACE VIEW snr_builtinbatches_v AS 

 SELECT snr_currentbom_serials_id as snr_builtinbatches_v_id,
	snr_batchcurrentbom_v_id,
	snr_masterdata_id,
	snr_batchmasterdata_id as batch,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	Qty
 from snr_currentbom_serials
 where snr_batchmasterdata_id is not null;




CREATE OR REPLACE FUNCTION snrBuiltinCorrection()
  RETURNS void AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.

 Empty Function due to Backwarsd Compat. - In Admin Folder is new one
***************************************************************************************************************************************************
*/

BEGIN
   
    return;
END;
  $BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;
  

CREATE OR REPLACE FUNCTION snrUpdateCurrentBom(p_minconsline_id character varying)
RETURNS void
AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
*/
v_cur record;
v_cur2 record;
v_cur3 record;
v_type varchar;
v_task varchar;
v_user varchar;
v_org varchar;
v_serial varchar;
v_product varchar;
v_batch varchar;
v_currbomid varchar;
v_count numeric;
v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
v_snrmasterdata varchar;
v_btchmasterdata varchar;
v_qty numeric;
v_currentbom_qty numeric;
v_currentbom record;
v_curSubProduct record;
v_text1 varchar;
v_text2 varchar;
v_plannedsnrbnr varchar;
v_prd varchar;
v_dscr varchar;
v_prj varchar;
v_othertaskqty numeric;
v_ptqty numeric:=1;
v_prodqty numeric:=1;
v_allcalc varchar:='N';
v_attribute varchar;
BEGIN 
    -- 1. hole weitere Informationen über diese Position ein 
    select m.movementtype,ml.c_projecttask_id,p.isserialtracking, p.isbatchtracking,ml.movementqty,m.updatedby,m.ad_org_id,m.plannedserialnumber, p.m_product_id, m.description,m.c_project_id
        into v_type,v_task,v_serial,v_batch,v_qty,v_user,v_org,v_plannedsnrbnr , v_prd,v_dscr, v_prj
        from m_internal_consumption m, m_internal_consumptionline ml, m_product p where m.m_internal_consumption_id=ml.m_internal_consumption_id and  p.m_product_id=ml.m_product_id and ml.m_internal_consumptionline_id=p_minconsline_id; 
    -- Alle Mat-Bewegungen für entweder die gegebene SNR/BtchNo oder, wenn einmal keine geplante SNR/BNR verwendet wurde für den ganzen Produktionsauftrag
    if (select count(*) from m_internal_consumption c,c_project p where p.c_project_id=c.c_project_id and p.projectcategory='PRO' and c.c_project_id=v_prj and c.c_projecttask_id=v_task 
        and c.plannedserialnumber is null and c.processed='Y')>0 then
        --select coalesce(qty,1) into v_ptqty from c_projecttask where c_projecttask_id=v_task;
        --select prodqty into v_prodqty from snr_batchmasterdata  where snr_batchmasterdata_id = (select snr_batchmasterdata_id from snr_internal_consumptionline where m_internal_consumptionline_id=p_minconsline_id limit 1);
        if v_prodqty is null then v_prodqty:=1; end if;
        v_allcalc:='Y';
    end if;
    -- Fallunterscheidungen: PROD, BOM Nav, Durchreicher
    -- 2. wenn die Positionen eine Warenbewegung vom Typ Produktion und Serien- bzw. Chargennummer-pflichtig ist 
    if v_type='P+' and (v_serial='Y' or v_batch='Y') and v_qty>0 then 
        select case when qty=0 then 1 else qty end into v_qty from c_projecttask where c_projecttask_id=v_task;
    -- 3. dann iteriere alle Serien/Chargenummer die zu dieser Position passen
        for v_cur in (select snr_masterdata_id, snr_batchmasterdata_id,ad_org_id from snr_internal_consumptionline where m_internal_consumptionline_id=p_minconsline_id)
        loop
        if (select count(*) from snr_currentbom where snr_masterdata_id=v_cur.snr_masterdata_id)>0  OR 
           (select count(*) from snr_currentbom where snr_batchmasterdata_id = v_cur.snr_batchmasterdata_id and c_getconfigoption('serialbomstrict',v_cur.ad_org_id)='Y')>0 then
                raise exception '%','@prodNotPossibleBOMnotEmpty@'||v_cur.snr_masterdata_id;
        end if;
        -- Bei Produktion mit Attributen, Attribut eintragen
        select p.m_attributesetinstance_id into  v_attribute  from  c_projecttask p,m_internal_consumptionline l where l.c_projecttask_id=p.c_projecttask_id and l.m_internal_consumptionline_id=p_minconsline_id;
        if v_attribute is not null then
            update snr_masterdata set m_attributesetinstance_id=v_attribute where snr_masterdata_id=v_cur.snr_masterdata_id;
        end if;        
        -- Produzierte CNR Menge eintragen
        if v_batch='Y' then
            update snr_batchmasterdata set prodqty=qtyonhand where snr_batchmasterdata_id = v_cur.snr_batchmasterdata_id;
        end if;
        -- 4. die Menge eines in der Stückliste enthaltenen Artikels zusammenrechnen -- nur Einträge deren movmenttype 'D-'/'D+' ist zählen,         
        -- Dazu erst mal evtl. vorhandene vorher getätigte Teil-Produktionen bei CNR's löschen (Kommt bei 1:1 Zuordnung nicht  vor.)
        delete from snr_currentbom where snr_batchmasterdata_id = v_cur.snr_batchmasterdata_id;
        for v_curSubProduct  in (select  round(((sum(ml.movementqty*(case when m.movementtype='D+' then -1 else 1 end))/v_ptqty)*v_prodqty),3) as qty,ml.m_product_id
                                    from  m_internal_consumptionline ml,m_internal_consumption m 
                                    where m.m_internal_consumption_id=ml.m_internal_consumption_id
                                    and ml.c_projecttask_id=v_task and m.processed='Y' and m.movementtype in ('D+','D-')
                                    and case when v_allcalc='N' then coalesce(m.plannedserialnumber,'')=coalesce(v_plannedsnrbnr,'') else 1=1 end
                                    group by ml.m_product_id
                                    union
                                    select round(((sum(ml.movementqty)/v_ptqty)*v_prodqty),3) as qty,ml.m_product_id
                                    from m_inout m,m_inoutline ml 
                                    where m.m_inout_id=ml.m_inout_id and m.movementtype='C-' and m.docstatus='CO' and m.c_projecttask_id=v_task
                                    and (select supply2vendor from c_projecttask where c_projecttask_id=v_task)='Y'
                                    group by ml.m_product_id)
                                
        loop            
            -- A. alle Einträge werden neu angelegt
            if v_curSubProduct.qty > 0 then
                -- A5.  Den Artikel in die Stückliste der/s Position/Ober-Artikels mit der berechneten Menge eintragen
                select get_uuid() into v_currbomid;
                insert into snr_currentbom(snr_currentbom_id , snr_masterdata_id, snr_batchmasterdata_id, ad_client_id, ad_org_id , isactive , createdby, updatedby , m_product_id, qty)
                values (v_currbomid,v_cur.snr_masterdata_id,v_cur.snr_batchmasterdata_id,v_client,v_org,'Y',v_user,v_user, v_curSubProduct.m_product_id, v_curSubProduct.qty);
                -- Insert SEERIALS
                for v_cur3 in (select l.snr_masterdata_id,  round(((sum(l.quantity*(case when m.movementtype='D+' then -1 else 1 end))/v_ptqty)*v_prodqty),3) as summed_Quantity, l.snr_batchmasterdata_id 
                                                from snr_internal_consumptionline l, m_internal_consumptionline ml,m_internal_consumption m 
                                                where m.m_internal_consumption_id=ml.m_internal_consumption_id
                                and ml.m_internal_consumptionline_id=l.m_internal_consumptionline_id and ml.m_product_id=v_curSubProduct.m_product_id
                                and ml.c_projecttask_id=v_task and m.processed='Y' and m.movementtype in ('D+','D-')
                                and  case when v_allcalc='N' then coalesce(m.plannedserialnumber,'')=coalesce(v_plannedsnrbnr,'') else 1=1 end
                                group by l.snr_masterdata_id, l.snr_batchmasterdata_id) 
                loop 
                                if v_cur3.summed_Quantity>0 then
                                    -- A8. Serien/Chargennummer-Einträge für die Chargennummer-Stücklisten-Einträge anlegen
                                    insert into snr_currentbom_serials(snr_currentbom_serials_id , snr_currentbom_v_id, snr_batchcurrentbom_v_id, snr_masterdata_id ,ad_client_id, ad_org_id , isactive , createdby, updatedby ,snr_batchmasterdata_id,qty) 
                                    values(get_uuid(),v_currbomid, v_currbomid,v_cur3.snr_masterdata_id,v_client,v_org,'Y',v_user,v_user,v_cur3.snr_batchmasterdata_id,v_cur3.summed_Quantity);
                                    update snr_masterdata set snrselfjoin=v_cur.snr_masterdata_id where snr_masterdata_id=v_cur3.snr_masterdata_id; 
                                end if;
                end loop;
            end if;
        end loop;
        end loop;
    end if;
    if v_type in ('D+','D-') and v_dscr!='Generated by PDC ->Send produced Material on Stock' then -- D+/D-  --> BOM NAV
        -- Einbau/Ausbau BOM Navigation (in consumptionline snr masterdata_id => Feld Verwendet für)
        select ml.snr_masterdata_id,ml.m_product_id, case when v_type='D+' then (-1)*ml.movementqty else ml.movementqty end  ,ml.text1,ml.text2
        into v_snrmasterdata ,v_product,v_qty,v_text1,v_text2
        from m_internal_consumptionline ml where ml.m_internal_consumptionline_id=p_minconsline_id;
        if v_snrmasterdata is  null then
            -- Einbau/Ausbau BOM Navigation Über Projekt (Wartung einer Maschine)
            select m.snr_masterdata_id,ml.m_product_id, case when v_type='D+' then (-1)*ml.movementqty else ml.movementqty end  into v_snrmasterdata ,v_product,v_qty
            from ma_machine m,c_project p,m_internal_consumptionline ml
            where m.ma_machine_id=p.ma_machine_id and p.c_project_id=ml.c_project_id and ml.m_internal_consumptionline_id=p_minconsline_id;
        end if;
        if v_snrmasterdata is  null then
            -- Einbau/Ausbau BOM Navigation Über Projekt (Wartung einer Kunden-Anlage)
            select a.snr_masterdata_id,ml.m_product_id, case when v_type='D+' then (-1)*ml.movementqty else ml.movementqty end  into v_snrmasterdata ,v_product,v_qty
            from a_asset a,c_project p,m_internal_consumptionline ml
            where a.a_asset_id=p.a_asset_id and p.c_project_id=ml.c_project_id and ml.m_internal_consumptionline_id=p_minconsline_id;
        end if;
        if v_snrmasterdata is not null then
            update m_internal_consumptionline set snr_masterdata_id=v_snrmasterdata where m_internal_consumptionline_id=p_minconsline_id and snr_masterdata_id is null;
            if (select m_product_id from snr_masterdata where snr_masterdata_id=v_snrmasterdata)=v_product then
                raise exception '%','@zsmf_BOMHasRecoursion@';
            end if;
            -- Test if Material was BUILT into Assembly (Only D+)
            if c_getconfigoption('bringbackmorematerialthanreceivedsnrbom','0')='N'  and v_type='D+' then
                select qty+v_qty into v_count from snr_currentbom where snr_masterdata_id=v_snrmasterdata and m_product_id=v_product;
                --RAISE EXCEPTION '%', v_count||'#'||v_snrmasterdata||'#'||v_product;
                if v_count is null then v_count:=-1; end if;
                if v_count<0 then
                    RAISE EXCEPTION '%', (select p.value from m_product p,snr_masterdata s where s.m_product_id=p.m_product_id and s.snr_masterdata_id=v_snrmasterdata)||'-'||(select serialnumber from snr_masterdata where snr_masterdata_id=v_snrmasterdata)||':'||'@zsmf_cannotbringbackmorethanreceived@'||' '||(select value from m_product where m_product_id=v_product);
                end if;
                if (select isserialtracking from m_product where m_product_id=v_product)='Y' or (select isbatchtracking from m_product where m_product_id=v_product)='Y' then
                    for v_cur3 in (select b.snr_batchmasterdata_id,s.snr_masterdata_id from m_internal_consumptionline ml,snr_internal_consumptionline l
                                          left join snr_batchmasterdata b on b.m_product_id=v_product and b.batchnumber=l.lotnumber
                                          left join snr_masterdata s on s.m_product_id=v_product and s.serialnumber=l.serialnumber
                                          where ml.m_internal_consumptionline_id=p_minconsline_id and ml.m_internal_consumptionline_id=l.m_internal_consumptionline_id)
                    LOOP
                        select snr_currentbom_id into v_currbomid from snr_currentbom where snr_masterdata_id=v_snrmasterdata and m_product_id=v_product;
                        if (select count(*) from snr_currentbom_serials where snr_currentbom_v_id=v_currbomid 
                                                and (snr_batchmasterdata_id=coalesce(v_cur3.snr_batchmasterdata_id,'') or snr_masterdata_id=coalesce(v_cur3.snr_masterdata_id,'')))=0 then                                     
                            RAISE EXCEPTION '%', (select p.value from m_product p,snr_masterdata s where s.m_product_id=p.m_product_id and s.snr_masterdata_id=v_snrmasterdata)||'-'||(select serialnumber from snr_masterdata where snr_masterdata_id=v_snrmasterdata)||':'||'@zsmf_cannotbringbackmorethanreceived@'||' '||coalesce((select p.value||'-'||s.serialnumber from m_product p,snr_masterdata s where s.snr_masterdata_id=v_cur3.snr_masterdata_id and s.m_product_id=p.m_product_id),'')||coalesce((select p.value||'-'||s.batchnumber from m_product p,snr_batchmasterdata s where s.snr_batchmasterdata_id=v_cur3.snr_batchmasterdata_id and s.m_product_id=p.m_product_id),''); 
                        end if;
                    END LOOP;
                end if;
            end if;
            select count(*) into v_count from snr_currentbom where snr_masterdata_id=v_snrmasterdata and m_product_id=v_product;
            if v_count=0 and v_qty>0 then
                select get_uuid() into v_currbomid;
                insert into snr_currentbom(snr_currentbom_id , snr_masterdata_id, ad_client_id, ad_org_id , isactive , createdby, updatedby , m_product_id, qty,text1,text2 )
                values (v_currbomid,v_snrmasterdata,v_client,v_org,'Y',v_user,v_user,v_product,v_qty,v_text1,v_text2);
                for v_cur3 in (select snr_masterdata_id,quantity,snr_batchmasterdata_id  from snr_internal_consumptionline where m_internal_consumptionline_id=p_minconsline_id)
                LOOP
                    insert into snr_currentbom_serials(snr_currentbom_serials_id , snr_currentbom_v_id, snr_batchcurrentbom_v_id, snr_masterdata_id ,ad_client_id, ad_org_id , isactive , createdby, updatedby ,snr_batchmasterdata_id,qty)
                    values(get_uuid(),v_currbomid,v_currbomid,v_cur3.snr_masterdata_id,v_client,v_org,'Y',v_user,v_user,v_cur3.snr_batchmasterdata_id,v_cur3.quantity);
                    update snr_masterdata set snrselfjoin=v_snrmasterdata where snr_masterdata_id=v_cur3.snr_masterdata_id;
                END LOOP;
            end if;
            if v_count=1 then
                if ((select qty from snr_currentbom where snr_masterdata_id=v_snrmasterdata and m_product_id=v_product)+v_qty)>0 then
                    select snr_currentbom_id into v_currbomid from snr_currentbom where snr_masterdata_id=v_snrmasterdata and m_product_id=v_product;
                    update snr_currentbom set qty=qty+v_qty,text1=v_text1,text2=v_text2 where snr_currentbom_id=v_currbomid;
                    for v_cur3 in (select snr_masterdata_id,quantity,snr_batchmasterdata_id  from snr_internal_consumptionline where m_internal_consumptionline_id=p_minconsline_id)
                    LOOP
                        if v_type='D-' then
                            if v_cur3.snr_masterdata_id is null and v_cur3.snr_batchmasterdata_id is not null 
                               and (select count(*) from snr_currentbom_serials where snr_currentbom_v_id=v_currbomid and snr_batchmasterdata_id=v_cur3.snr_batchmasterdata_id)>0
                            then -- Existing Batches, no SNR -> Increase QTY
                                    update snr_currentbom_serials set qty=qty+v_cur3.quantity  where snr_currentbom_v_id=v_currbomid and snr_batchmasterdata_id=v_cur3.snr_batchmasterdata_id;
                            else -- serials or non ex. Batches
                                insert into snr_currentbom_serials(snr_currentbom_serials_id , snr_currentbom_v_id, snr_batchcurrentbom_v_id, snr_masterdata_id ,ad_client_id, ad_org_id , isactive , createdby, updatedby ,snr_batchmasterdata_id,qty)
                                values(get_uuid(),v_currbomid,v_currbomid,v_cur3.snr_masterdata_id,v_client,v_org,'Y',v_user,v_user,v_cur3.snr_batchmasterdata_id,v_cur3.quantity);
                                update snr_masterdata set snrselfjoin=v_snrmasterdata where snr_masterdata_id=v_cur3.snr_masterdata_id;
                            end if;
                        else                             
                            -- Update BOM Serials/Batches
                            if v_cur3.snr_masterdata_id is null and v_cur3.snr_batchmasterdata_id is not null 
                               and coalesce((select qty-v_cur3.quantity from snr_currentbom_serials where snr_currentbom_v_id=v_currbomid and snr_batchmasterdata_id=v_cur3.snr_batchmasterdata_id),0)>0
                            then -- Existing Batches, no SNR -> DECREASE QTY
                                    update snr_currentbom_serials set qty=qty-v_cur3.quantity  where snr_currentbom_v_id=v_currbomid and snr_batchmasterdata_id=v_cur3.snr_batchmasterdata_id;
                            else -- serials or  Batches without QTY left  (mehrere Chargen, eine ist zu löschen)                          
                                delete from snr_currentbom_serials where (snr_currentbom_v_id=v_currbomid OR snr_batchcurrentbom_v_id=v_currbomid) and (snr_masterdata_id=v_cur3.snr_masterdata_id or snr_batchmasterdata_id=v_cur3.snr_batchmasterdata_id);
                                update snr_masterdata set snrselfjoin=null where snr_masterdata_id=v_cur3.snr_masterdata_id;
                            end if;
                        end if;
                    END LOOP;
                else
                    for v_cur3 in (select snr_masterdata_id,quantity,snr_batchmasterdata_id  from snr_internal_consumptionline where m_internal_consumptionline_id=p_minconsline_id)
                    LOOP
                        update snr_masterdata set snrselfjoin=null where snr_masterdata_id=v_cur3.snr_masterdata_id;
                    END LOOP;
                    delete from snr_currentbom where snr_masterdata_id=v_snrmasterdata and m_product_id=v_product;
                end if;
            end if;
            for v_cur3 in (select snr_masterdata_id,quantity,snr_batchmasterdata_id  from snr_internal_consumptionline where m_internal_consumptionline_id=p_minconsline_id)
            LOOP
                if v_cur3.snr_batchmasterdata_id is not null then
                    update snr_internal_consumptionline set snr_builtinsnr=v_snrmasterdata where snr_batchmasterdata_id=v_cur3.snr_batchmasterdata_id and  m_internal_consumptionline_id=p_minconsline_id;
                end if;
                if v_cur3.snr_masterdata_id is not null then
                    update snr_internal_consumptionline set snr_builtinsnr=v_snrmasterdata where snr_masterdata_id=v_cur3.snr_masterdata_id and  m_internal_consumptionline_id=p_minconsline_id;
                end if;
            END LOOP;
        end if; -- SNR Masterdata not null
    end if; -- BOM NAV D+/D- / not produced
    -- Durchreiche AG: Stückliste ergänzen - Funktion nur bei erster Zeile auslösen (1. Zeile ist Assembly.)
    if v_type='D+' and (v_serial='Y' or v_batch='Y') and (select count(*) from c_projecttask where c_projecttask_id=v_task and assembly='N')>0
       and (SELECT  m_product_id as id from zssm_workstepbom_v  where zssm_workstep_v_id = v_task order by line limit 1) = v_prd
       and v_dscr='Generated by PDC ->Send produced Material on Stock'
    then 
        for v_cur in (select snr_masterdata_id, snr_batchmasterdata_id,ad_org_id from snr_internal_consumptionline where m_internal_consumptionline_id=p_minconsline_id)
        LOOP
            -- 4. die Menge eines in der Stückliste enthaltenen Artikels zusammenrechnen -- nur Einträge deren movmenttype 'D-' ist zählen, der Rest wird erstmal ignoriert
            --select round((quantity/v_qty),4) as qty,m_product_id from zspm_projecttaskbom where c_projecttask_id = v_task
            for v_curSubProduct  in (select  round(((sum(ml.movementqty*(case when m.movementtype='D+' then -1 else 1 end))/v_ptqty)*v_prodqty),3)  as qty,ml.m_product_id
                                    from  m_internal_consumptionline ml,m_internal_consumption m 
                                    where m.m_internal_consumption_id=ml.m_internal_consumption_id
                                    and ml.c_projecttask_id=v_task and m.processed='Y' and m.movementtype in ('D+','D-')
                                    and case when v_allcalc='N' then coalesce(m.plannedserialnumber,'')=coalesce(v_plannedsnrbnr,'') else 1=1 end
                                    and ml.m_product_id!=v_prd
                                    group by ml.m_product_id)
            loop
                -- A. alle Einträge werden neu angelegt
                if v_curSubProduct.qty > 0 then
                    -- A5.  Den Artikel in die Stückliste der/s Position/Ober-Artikels mit der berechneten Menge eintragen
                    select snr_currentbom_id into v_currbomid from snr_currentbom where (snr_masterdata_id=v_cur.snr_masterdata_id or snr_batchmasterdata_id=v_cur.snr_batchmasterdata_id) and m_product_id=v_curSubProduct.m_product_id;
                    if v_currbomid is null then
                        select get_uuid() into v_currbomid;
                        insert into snr_currentbom(snr_currentbom_id , snr_masterdata_id, snr_batchmasterdata_id, ad_client_id, ad_org_id , isactive , createdby, updatedby , m_product_id, qty)
                        values (v_currbomid,v_cur.snr_masterdata_id,v_cur.snr_batchmasterdata_id,v_client,v_org,'Y',v_user,v_user, v_curSubProduct.m_product_id, v_curSubProduct.qty);
                    else
                        select  round(((sum(ml.movementqty*(case when m.movementtype='D+' then -1 else 1 end))/v_ptqty)*v_prodqty),3)  into v_othertaskqty 
                                from  m_internal_consumptionline ml,m_internal_consumption m 
                                    where m.m_internal_consumption_id=ml.m_internal_consumption_id
                                    and ml.c_projecttask_id!=v_task and ml.c_project_id=v_prj and m.processed='Y' and m.movementtype in ('D+','D-')
                                    and case when v_allcalc='N' then coalesce(m.plannedserialnumber,'')=coalesce(v_plannedsnrbnr,'') else 1=1 end
                                    and ml.m_product_id=v_curSubProduct.m_product_id;
                        update snr_currentbom set qty=coalesce(v_othertaskqty+v_curSubProduct.qty,0) where snr_currentbom_id=v_currbomid;
                    end if;
                    -- Insert SERIALS
                    for v_cur3 in (select l.snr_masterdata_id, round(((sum(l.quantity*(case when m.movementtype='D+' then -1 else 1 end))/v_ptqty)*v_prodqty),3)  as summed_Quantity, l.snr_batchmasterdata_id 
                                                    from snr_internal_consumptionline l, m_internal_consumptionline ml,m_internal_consumption m 
                                                    where m.m_internal_consumption_id=ml.m_internal_consumption_id
                                    and ml.m_internal_consumptionline_id=l.m_internal_consumptionline_id and ml.m_product_id=v_curSubProduct.m_product_id
                                    and ml.c_projecttask_id=v_task and m.processed='Y' and m.movementtype in ('D+','D-')
                                    and case when v_allcalc='N' then coalesce(m.plannedserialnumber,'')=coalesce(v_plannedsnrbnr,'') else 1=1 end
                                    group by l.snr_masterdata_id, l.snr_batchmasterdata_id) 
                    loop 
                                    if v_cur3.summed_Quantity>0 then
                                        -- A8. Serien/Chargennummer-Einträge für die Chargennummer-Stücklisten-Einträge anlegen
                                        insert into snr_currentbom_serials(snr_currentbom_serials_id , snr_currentbom_v_id, snr_batchcurrentbom_v_id, snr_masterdata_id ,ad_client_id, ad_org_id , isactive , createdby, updatedby ,snr_batchmasterdata_id,qty) 
                                        values(get_uuid(),v_currbomid, v_currbomid,v_cur3.snr_masterdata_id,v_client,v_org,'Y',v_user,v_user,v_cur3.snr_batchmasterdata_id,v_cur3.summed_Quantity);
                                        update snr_masterdata set snrselfjoin=v_cur.snr_masterdata_id where snr_masterdata_id=v_cur3.snr_masterdata_id; 
                                    end if;
                    end loop;
                end if;
            end loop;
        END LOOP;
    end if; -- Durchreiche AG
    return;
END;
$_$                          
LANGUAGE 'plpgsql' VOLATILE
COST 100;


CREATE or replace FUNCTION snrCheckPlannedSNROK(p_workstep varchar,p_plannedsnr varchar) RETURNS varchar  AS $_$                                                                  
DECLARE
    v_product varchar;
    v_othertask varchar;                                                                                    
BEGIN
    SELECT  m_product_id into v_product from c_projecttask  where c_projecttask_id = p_workstep and assembly='Y';
    select t.value into v_othertask from m_internal_consumption c,c_projecttask t where t.c_projecttask_id=c.c_projecttask_id and t.c_projecttask_id!=p_workstep
                             and c.plannedserialnumber=p_plannedsnr and t.m_product_id=v_product and t.assembly='Y' and t.iscomplete='N';
    if v_othertask is null then
        return 'OK';
    else
        return v_othertask;
    end if;
END;
$_$                          
LANGUAGE 'plpgsql' VOLATILE
COST 100;


CREATE or replace FUNCTION snrIsSerialOrBtchProduced(p_plannedsnr varchar,p_workstep varchar) RETURNS varchar  AS $_$                                                                  
DECLARE
    v_org varchar;
    v_prod varchar;
    v_othertask varchar;
    v_return varchar;
BEGIN
    SELECT  ad_org_id into v_org from c_projecttask  where c_projecttask_id = p_workstep and assembly='Y';
    if v_org is not null then -- Assemblyz
        SELECT case when count(*)>0 then 'Y' else 'N' end into v_return  from m_internal_consumption c,m_internal_consumptionline il,m_product p
        where p.m_product_id=il.m_product_id and il.m_internal_consumption_id=c.m_internal_consumption_id 
              and (p.isserialtracking='Y' or (p.isbatchtracking='Y' and c_getconfigoption('serialbomstrict',v_org)='Y')) -- 1:1 - Charge darf nur einmal produziert werden.
              and c.processed='Y' and c.movementtype='P+'
              and c.plannedserialnumber=p_plannedsnr and c.c_projecttask_id=p_workstep;
    end if;
 -- Durchreiche (Passing Workstep) - Ohne Prüfung
    RETURN v_return;
END;
$_$                          
LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE or replace FUNCTION isSnrBtchProducedCompleteFinish(p_plannedsnr varchar,p_workstep varchar) RETURNS varchar  AS $_$                                                                  
DECLARE
    v_org varchar;
    v_prod varchar;
    v_othertask varchar;
    v_return varchar;
    v_btch varchar;
    v_btchqty numeric:=0;
BEGIN
    SELECT  ad_org_id,m_product_id into v_org,v_prod from c_projecttask  where c_projecttask_id = p_workstep and assembly='Y';
    if v_org is not null then -- Assembly
        select isbatchtracking into v_btch from m_product where m_product_id=v_prod;
        if v_btch='Y' and c_getconfigoption('serialbomstrict',v_org)='Y' then
          v_btchqty=coalesce(pdc_getStrictBATCHPossibleQty(p_workstep,p_plannedsnr),0);
          if v_btchqty>0 then
            delete from snr_currentbom where snr_batchmasterdata_id=(select snr_batchmasterdata_id from snr_batchmasterdata where m_product_id=v_prod and batchnumber=p_plannedsnr);
            return 'N';
          end if;
        end if;
        SELECT case when count(*)>0 then 'Y' else 'N' end into v_return  from m_internal_consumption c,m_internal_consumptionline il,m_product p
        where p.m_product_id=il.m_product_id and il.m_internal_consumption_id=c.m_internal_consumption_id 
              and (p.isserialtracking='Y' or (p.isbatchtracking='Y' and c_getconfigoption('serialbomstrict',v_org)='Y')) -- 1:1 - SNR darf nur einmal produziert werden.
              and c.processed='Y' and c.movementtype='P+'
              and c.plannedserialnumber=p_plannedsnr and c.c_projecttask_id=p_workstep;
    end if;
    RETURN v_return;
END;
$_$                          
LANGUAGE 'plpgsql' VOLATILE
COST 100;


select zsse_DropView ('snr_planedserials_v');
CREATE OR REPLACE VIEW snr_planedserials_v AS 
 SELECT distinct t.c_projecttask_id||c.plannedserialnumber as snr_planedserials_v_id, c.plannedserialnumber as name ,c.c_projecttask_id,
        c.ad_client_id, '0' as ad_org_id, 'Y'::character as isactive , trunc(now()) as created  , '0' as createdby , trunc(now()) as updated,'0' as updatedby
 from m_internal_consumption c,c_projecttask t where t.c_projecttask_id=c.c_projecttask_id  and c.plannedserialnumber is not null;

CREATE or replace FUNCTION zssi_cnrcodex(p_date timestamp with time zone) RETURNS character varying      AS $_$                                                                  
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs                                                                                                                                 
Localozation in Database - The better way                                            
*****************************************************/                
DECLARE
v_year character varying := to_char(p_date,'YY');
v_month character varying := to_char(p_date,'MM');
v_day character varying := to_char(p_date,'DD');
v_count character varying := '001';
v_counting numeric:= 0;
                                                                                                                                                                                      
v_return character varying;                                                                                     
                                                                                                      
BEGIN                                                                              
      select count(*) into v_counting from cnr_sequence where cnrdate=trunc(p_date);
      v_return:=zssi_cnryear(v_year)||zssi_cnrmonth(v_month)||v_day||to_char((v_counting+1),'009');
      v_return:= replace(v_return,' ','');
      if not exists (select cnrbatch from cnr_sequence where cnrbatch=v_return) then
           insert into cnr_sequence values(v_return, trunc(p_date), v_year, v_month, v_day, replace(to_char((v_counting+1),'009'),' ',''), now(), 'Y');
      end if;                    
RETURN v_return;
END;
$_$                          
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


 CREATE or replace FUNCTION zssi_cnrmonth(p_month character varying) RETURNS character varying                                                                                                        AS $_$                                                                  
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs                                                                                                                                 
Localozation in Database - The better way                                            
*****************************************************/                
DECLARE
                                                 
v_return character varying;
                                                
BEGIN                              
      select case when (p_month='01') then '1' 
  when (p_month='02') then '2'                                                                                                                                                     
  when (p_month='03') then '3'                                                                                  
  when (p_month='04') then '4'                                                                        
  when (p_month='05') then '5' 
  when (p_month='06') then '6'                                  
  when (p_month='07') then '7'                                                                     
  when (p_month='08') then '8'  
  when (p_month='09') then '9'                                                                                  
  when (p_month='10') then 'O' 
  when (p_month='11') then 'N' 
  when (p_month='12') then 'D' 

       else '' end into v_return; 
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE or replace FUNCTION zssi_cnryear(p_year character varying) RETURNS character varying                                                                                                        AS $_$                                                                  
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs                                                                                                                                 
Localozation in Database - The better way                                            
*****************************************************/                
DECLARE
                                                 
v_return character varying;
                                                
BEGIN                              
      select case when (p_year='11') then 'B' 
  when (p_year='12') then 'C'                                                                                                                                                    
  when (p_year='13') then 'D'                                                                                 
  when (p_year='14') then 'E'                                                                        
  when (p_year='15') then 'F' 
  when (p_year='16') then 'H'                                  
  when (p_year='17') then 'J'                                                                     
  when (p_year='18') then 'K'  
  when (p_year='19') then 'L'                                                                                  
  when (p_year='20') then 'M' 
  when (p_year='21') then 'N' 
  when (p_year='22') then 'P' 
  when (p_year='23') then 'R' 
  when (p_year='24') then 'S' 
  when (p_year='25') then 'T' 
  when (p_year='26') then 'U' 
  when (p_year='27') then 'V' 
  when (p_year='30') then 'W' 
  when (p_year='31') then 'X' 
  when (p_year='32') then 'A' 
  when (p_year='33') then 'B' 
  when (p_year='34') then 'C' 
  when (p_year='35') then 'D' 
  when (p_year='36') then 'E' 
  when (p_year='37') then 'F' 
  when (p_year='38') then 'H' 
  when (p_year='39') then 'J'
       else '' end into v_return; 
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION snr_minoutline_selectedbatch_trg()  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_processed character varying;
v_return character varying;
BEGIN
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
        IF TG_OP != 'DELETE' THEN 
            IF TG_OP = 'UPDATE'  THEN
                if new.lotnumber!=old.lotnumber  then
                    new.selectedbatch:=null;
                end if;
                if  coalesce(new.selectedbatch,'')!=coalesce(old.selectedbatch,'') and new.lotnumber=old.lotnumber then
                    new.lotnumber:=(select sbm.batchnumber from snr_batchmasterdata sbm,snr_batchlocator sbl where sbl.snr_batchlocator_id=new.selectedbatch and sbm.SNR_BATCHMASTERDATA_ID=sbl.SNR_BATCHMASTERDATA_ID);
                    RAISE NOTICE '%',new.lotnumber||'###'||new.selectedbatch;
                    new.selectedbatch:=null;
                end if;

            END IF;
            IF TG_OP ='INSERT' THEN
                if new.lotnumber is null and new.selectedbatch is not null then
                    new.lotnumber:=(select sbm.batchnumber from snr_batchmasterdata sbm,snr_batchlocator sbl where sbl.snr_batchlocator_id=new.selectedbatch and sbm.SNR_BATCHMASTERDATA_ID=sbl.SNR_BATCHMASTERDATA_ID);
                    new.selectedbatch:=null;
                end if;
                if new.lotnumber is not null and new.selectedbatch is not null then
                    new.lotnumber:=(select sbm.batchnumber from snr_batchmasterdata sbm,snr_batchlocator sbl where sbl.snr_batchlocator_id=new.selectedbatch and sbm.SNR_BATCHMASTERDATA_ID=sbl.SNR_BATCHMASTERDATA_ID);
                    new.selectedbatch:=null;
                end if;
            END IF;
    END IF;
   IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
   
END;

  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION snr_Internal_Consumptionline_selectedbatch_internal_trg()  RETURNS trigger AS
$BODY$ DECLARE 
v_product_id varchar;
v_project_id varchar;
BEGIN
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
	IF TG_OP ='INSERT' THEN
	    -- for a productionrun: products with snr or bnr that do not have a productionplan and are manufactured in THIS productionrun may only be used by the same productionrun
	    select m_product_id, c_project_id into v_product_id, v_project_id from m_internal_consumptionline where m_internal_consumptionline_id = new.m_internal_consumptionline_id;
	    if(
	        -- no productionplan for this product exists
	        (select count(*) from zssm_getproductionplanofproduct(v_product_id, new.ad_org_id)) = 0
	        -- and the product is manufactured in this productionrun
	        and (select count(*) from zssm_workstep_v where isactive = 'Y' and c_project_id = v_project_id and m_product_id = v_product_id) != 0
	        -- and the entered snr/cnr was NOT manufactured in this productionrun already
	        and (select count(*) from m_internal_consumption where isactive = 'Y' and movementtype = 'P+' and c_project_id = v_project_id and (plannedserialnumber = new.lotnumber or plannedserialnumber = new.serialnumber)) = 0
	    ) then
	        raise exception '@notManufacturedInProductionrun@';
	    end if;
	END IF;
   IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


 select zsse_droptrigger('snr_minoutline_selectedbatch_trg','snr_minoutline'); 
  
  CREATE TRIGGER snr_minoutline_selectedbatch_trg
  BEFORE INSERT or DELETE or UPDATE
  ON snr_minoutline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_minoutline_selectedbatch_trg();
  
   select zsse_droptrigger('snr_inventoryline_selectedbatch_trg','snr_inventoryline'); 
  
  CREATE TRIGGER snr_inventoryline_selectedbatch_trg
  BEFORE INSERT or DELETE or UPDATE
  ON snr_inventoryline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_minoutline_selectedbatch_trg();
  
  select zsse_droptrigger('snr_Internal_Consumptionline_selectedbatch_trg','snr_Internal_Consumptionline'); 
  
  CREATE TRIGGER snr_Internal_Consumptionline_selectedbatch_trg
  BEFORE INSERT or DELETE or UPDATE
  ON snr_Internal_Consumptionline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_minoutline_selectedbatch_trg();
  
  select zsse_droptrigger('snr_Internal_Consumptionline_selectedbatch_internal_trg','snr_Internal_Consumptionline'); 
  
  CREATE TRIGGER snr_Internal_Consumptionline_selectedbatch_internal_trg
  BEFORE INSERT or DELETE or UPDATE
  ON snr_Internal_Consumptionline
  FOR EACH ROW
  EXECUTE PROCEDURE snr_Internal_Consumptionline_selectedbatch_internal_trg();
  

  
CREATE OR REPLACE FUNCTION snr_currentbom_trg()  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_line numeric;
BEGIN
   select count(*)*10 into v_line from snr_currentbom where snr_masterdata_id=new.snr_masterdata_id;
   v_line:=v_line+10;
   new.line:=v_line;
   RETURN NEW;
END;  
$BODY$ LANGUAGE 'plpgsql';

  
 select zsse_droptrigger('snr_currentbom_trg','snr_currentbom'); 
  
  CREATE TRIGGER  snr_currentbom_trg
  BEFORE INSERT
  ON  snr_currentbom
  FOR EACH ROW
  EXECUTE PROCEDURE  snr_currentbom_trg();
    
CREATE OR REPLACE FUNCTION snr_currentbomhistory_trg()  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_isdel varchar;
BEGIN
   IF TG_OP = 'DELETE' THEN v_isdel:='Y'; ELSE v_isdel:='N'; END IF;
   if old.snr_masterdata_id is not null then
    insert into snr_currentbom_history(snr_currentbom_history_id, snr_masterdata_id, line, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, qty, deleted, serials, batches)
    values(get_uuid(),old.snr_masterdata_id, old.line, old.ad_client_id, old.ad_org_id, old.createdby, old.updatedby, old.m_product_id, old.qty,v_isdel,
            getBuiltInSerials(old.snr_currentbom_id),getBuiltInBatches(old.snr_currentbom_id));
   end if;
   IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;  
$BODY$ LANGUAGE 'plpgsql';

  
 select zsse_droptrigger('snr_currentbomhistory_trg','snr_currentbom'); 
  
  CREATE TRIGGER  snr_currentbomhistory_trg
  BEFORE UPDATE OR DELETE
  ON  snr_currentbom
  FOR EACH ROW
  EXECUTE PROCEDURE snr_currentbomhistory_trg();
  



CREATE OR REPLACE FUNCTION snr_locatorchange (p_pinstance_id  VARCHAR) RETURNS VARCHAR 
AS $body$
DECLARE
  Cur_Parameter           RECORD;
  v_message               VARCHAR := '';
  v_Record_ID             VARCHAR;
  v_user_id               VARCHAR;
  v_mv         varchar;
  v_mvl        varchar;
  v_new_locator             VARCHAR;
  v_name varchar;
  v_snrrecord snr_masterdata%ROWTYPE;
  v_org varchar;
BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'Y', NULL, NULL) ; -- 'Y'=processing
      SELECT pi.Record_ID, pi.ad_User_ID,pi.ad_org_id
      INTO v_Record_ID, v_user_id,v_org
      FROM ad_pinstance pi WHERE pi.ad_PInstance_ID = p_PInstance_ID;
      IF (v_Record_ID IS NULL) then
         RAISE NOTICE '%','Entry for PInstance not found - Using parameter &1=''' || p_PInstance_ID || ''' instead';
         v_Record_ID := p_PInstance_ID;
         v_user_id     := '0';
      ELSE
        -- Get Parameters
        v_message := 'ReadingParameters';
        FOR Cur_Parameter IN
          (SELECT para.parametername, para.p_string
           FROM AD_PInstance pi, AD_PInstance_Para para
           WHERE 1=1
            AND pi.AD_PInstance_ID = para.AD_PInstance_ID
            AND pi.AD_PInstance_ID = p_PInstance_ID
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('locator_to') ) THEN
            v_new_locator := Cur_Parameter.p_string;
          END IF;
        END LOOP; -- Get Parameter
      END IF;
    END IF;
    if v_org='0' then
        select ad_org_id into v_org from snr_masterdata  where snr_masterdata_id=v_Record_ID;
        if v_org='0' then
            raise exception '%' , '@needOrg2UseFunction@';
        end if;
    end if;
    v_mv:=get_uuid();
    v_mvl:=get_uuid();
    select to_char(now(),'YYYY-MM-DD')||'-'||count(*)+1 into v_name  from m_movement where trunc(created)=trunc(now());
    select * into v_snrrecord from snr_masterdata  where snr_masterdata_id=v_Record_ID;
    if v_snrrecord.m_locator_id is null then
        raise exception '%','@NotEnoughStocked@';
    end if;
    insert into m_movement( m_movement_id, ad_client_id, ad_org_id, createdby, updatedby,name,movementdate) 
            values (v_mv, v_snrrecord.ad_client_id, v_org, v_user_id, v_user_id, v_name, trunc(now()));
    insert into m_movementline(m_movementline_id, ad_client_id, ad_org_id, createdby, updatedby, m_movement_id, m_locator_id, m_locatorto_id, m_product_id, line, movementqty,c_uom_id)
            values(v_mvl,v_snrrecord.ad_client_id,v_org, v_user_id, v_user_id,v_mv,v_snrrecord.m_locator_id,v_new_locator,v_snrrecord.m_product_id,10,1,(select c_uom_id from m_product where m_product_id=v_snrrecord.m_product_id));
    delete from snr_movementline where m_movementline_id=v_mvl;
    insert into snr_movementline(snr_movementline_id, ad_client_id, ad_org_id, createdby, updatedby, m_movementline_id, quantity,  lotnumber, serialnumber)
            values (get_uuid(),v_snrrecord.ad_client_id,v_org, v_user_id, v_user_id,v_mvl,1,(select  batchnumber from snr_batchmasterdata where snr_batchmasterdata_id=v_snrrecord.snr_batchmasterdata_id),v_snrrecord.serialnumber);
    PERFORM AD_UPDATE_PINSTANCE(v_mv, v_user_id, 'N', NULL, 'Starting Movement Post') ;
    perform  m_movement_post(v_mv);
    if coalesce((select result from ad_pinstance where ad_pinstance_id=v_mv),0)!=1 then
        raise exception '%',coalesce((select errormsg from  ad_pinstance where ad_pinstance_id=v_mv),'No Movement Post Process found');
    end if;
    v_message:='SUCCESS';
    PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'N', 1, v_Message) ; -- NULL=p_ad_user_id, 'N'=isProcessing, 1=success
    RETURN v_message;
EXCEPTION
WHEN OTHERS THEN
  v_message := '@ERROR=' || SQLERRM;
  RAISE NOTICE '% %', 'SQL-PROC ad_role_GenerateRole: ', v_message;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

CREATE OR REPLACE FUNCTION snr_attributeselector(p_masterdata_id in varchar)  RETURNS varchar AS
$BODY$ DECLARE 
    v_snrmaster varchar;
    v_btchmaster varchar;
    v_attr varchar;
BEGIN
    select snr_masterdata_id into v_snrmaster from snr_masterdata where snr_masterdata_id=p_masterdata_id;
    if v_snrmaster is not null then
        select m_attributesetinstance_id into v_attr from snr_serialnumbertracking  where snr_masterdata_id=v_snrmaster order by created  limit 1;
    end if;
    select snr_batchmasterdata_id into v_btchmaster from snr_batchmasterdata where snr_batchmasterdata_id=p_masterdata_id;
    if v_btchmaster is not null and v_snrmaster is null then
        select m_attributesetinstance_id into v_attr from snr_serialnumbertracking  where snr_batchmasterdata_id=v_btchmaster order by created limit 1;
    end if;
    return v_attr;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

