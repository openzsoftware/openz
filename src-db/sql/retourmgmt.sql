CREATE or replace FUNCTION m_retour_management_post(p_PInstance_ID character varying) RETURNS void
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Direct Sales Implementation
*/
-- Simple Types
v_message character varying:='OK';
v_client  character varying;
v_org  character varying;
v_user  character varying;
v_count numeric:=0;
v_Record_ID  character varying;
v_processed character varying;
v_posid character varying;
v_retloc varchar;
v_loc varchar;
v_type varchar;
v_product varchar;
v_attrsetinsatnce varchar;
v_qty numeric;
v_DocumentNo varchar;
v_uid varchar;
v_uid2 varchar;
v_uom varchar;
BEGIN 
    -- Set Proceccing...
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Select ident Data
    select ad_user_id,ad_org_id,ad_client_id,Record_ID into v_user,v_org,v_client,v_Record_ID from ad_pinstance where ad_pinstance_id=p_PInstance_ID;
    if v_Record_ID is null then
             v_Record_ID:=p_PInstance_ID;
             select ad_user_id,ad_org_id,ad_client_id  into v_user,v_org,v_client  from m_retour_management  where m_retour_management_id=v_Record_ID;
    end if;
    select ad_client_id,ad_org_id,locatorretoure,m_locator_id,retourtype,m_product_id,m_attributesetinstance_id,qty 
                 into v_client,v_org,v_retloc,v_loc,v_type,v_product,v_attrsetinsatnce,v_qty from m_retour_management  where m_retour_management_id=v_Record_ID;
   select c_uom_id into v_uom from m_product where m_product_id=v_product;
    if v_type='WAREHOUSE' then -- Internal Consumption From v_loc 
            select ad_sequence_doc('Production',v_org,'Y') into v_DocumentNo;
            select get_uuid() into v_uid;
            insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                 NAME, DESCRIPTION, MOVEMENTDATE,dateacct,  MOVEMENTTYPE,DOCUMENTNO)
                     values(v_uid,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                      'Retoure-Abgang','Generierter Abgang Retoure',trunc(now()),trunc(now()),'D-',v_DocumentNo);
            insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                            M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, m_attributesetinstance_id)
                    values (get_uuid(),v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid,
                    v_loc,v_product,10,v_qty,'Retoure-Abgang',v_uom,v_attrsetinsatnce);
            PERFORM m_internal_consumption_post(v_uid);
    end if;
    if v_type in ('WAREHOUSE','CUSTOMER')  then -- Internal Consumption (+) To v_retloc
            select ad_sequence_doc('Production',v_org,'Y') into v_DocumentNo;
            select get_uuid() into v_uid2;
            insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                 NAME, DESCRIPTION, MOVEMENTDATE,dateacct,  MOVEMENTTYPE,DOCUMENTNO)
                     values(v_uid2,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                      'Retoure-Zugang','Generierter Zugang Retoure',trunc(now()),trunc(now()),'D+',v_DocumentNo);
            insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                            M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, m_attributesetinstance_id)
                    values (get_uuid(),v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid2,
                    v_retloc,v_product,10,v_qty,'Retoure-Zugang',v_uom,v_attrsetinsatnce);
            PERFORM m_internal_consumption_post(v_uid2);
    end if;
    update m_retour_management set docstatus='CO',m_internal_consumption_id= v_uid ,retoureintcons=v_uid2 where m_retour_management_id=v_Record_ID;
    
    -- Finishing    
    -- 1=success
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_message);
    return;
EXCEPTION
    WHEN OTHERS then
       v_message:= '@ERROR=' || SQLERRM;   
       --ROLLBACK;
       -- 0=failed
       PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
       return;
END;
$_$  LANGUAGE 'plpgsql';
 
CREATE or replace FUNCTION m_retour_management_cancel(p_PInstance_ID character varying) RETURNS void
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Direct Sales Implementation
*/
-- Simple Types
v_message character varying:='OK';
v_client  character varying;
v_org  character varying;
v_user  character varying;
v_mint1 varchar;
v_mint2 varchar;
v_Record_ID  character varying;
BEGIN 
    -- Set Proceccing...
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Select ident Data
    select ad_user_id,ad_org_id,ad_client_id,Record_ID into v_user,v_org,v_client,v_Record_ID from ad_pinstance where ad_pinstance_id=p_PInstance_ID;
    if v_Record_ID is null then
             v_Record_ID:=p_PInstance_ID;
             select ad_user_id,ad_org_id,ad_client_id  into v_user,v_org,v_client  from m_retour_management  where m_retour_management_id=v_Record_ID;
    end if;
    select retoureintcons,m_internal_consumption_id
                 into v_mint1,v_mint2 from m_retour_management  where m_retour_management_id=v_Record_ID;
     if v_mint1 is not null then
             PERFORM m_internal_consumption_cancel(v_mint1,v_user);
     end if;
     if v_mint2 is not null then
             PERFORM m_internal_consumption_cancel(v_mint2,v_user);
     end if;
     update m_retour_management set docstatus='VO' ,status='STORNO' where m_retour_management_id=v_Record_ID; 
    -- Finishing    
    -- 1=success
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_message);
    return;
EXCEPTION
    WHEN OTHERS then
       v_message:= '@ERROR=' || SQLERRM;   
       --ROLLBACK;
       -- 0=failed
       PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
       return;
END;
$_$  LANGUAGE 'plpgsql';