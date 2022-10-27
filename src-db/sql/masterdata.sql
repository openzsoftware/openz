CREATE OR REPLACE FUNCTION ad_org_trg() RETURNS trigger LANGUAGE plpgsql
    AS $_$ DECLARE 

  /*************************************************************************
  * The contents of this file are subject to the Compiere Public
  * License 1.1 ("License"); You may not use this file except in
  * compliance with the License. You may obtain a copy of the License in
  * the legal folder of your Openbravo installation.
  * Software distributed under the License is distributed on an
  * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  * implied. See the License for the specific language governing rights
  * and limitations under the License.
  * The Original Code is  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
  * parts created by ComPiere are Copyright (C) ComPiere, Inc.;
  * All Rights Reserved.
  * Contributor(s): Openbravo SL, OpenZ Software GmbH
  * Contributions are Copyright (C) 2001-2009 Openbravo, S.L., 2020 OpenZ Software GmbH
  * 
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  * 
  *************************************************************************/
  v_xTree_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_xParent_ID VARCHAR(32); --OBTG:VARCHAR2--
  --TYPE RECORD IS REFCURSOR;
    CUR_PeriodControl RECORD;
  
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF(TG_OP = 'INSERT') THEN
    -- Add to all roles of the client (Only System Admin Role)
    INSERT
    INTO AD_Role_OrgAccess
      (
        AD_Role_OrgAccess_ID, AD_Role_ID, AD_Client_ID, AD_Org_ID,
        IsActive, Created, CreatedBy,
        Updated, UpdatedBy
      )
    SELECT get_uuid(), AD_Role_ID, new.AD_Client_ID, new.AD_Org_ID,
       'Y', TO_DATE(NOW()), new.CreatedBy,
      TO_DATE(NOW()), new.CreatedBy
    FROM AD_Role
    WHERE AD_Client_ID=new.AD_Client_ID and ad_role_id ='32BB190E7B4846E8AA0F1847BD4444BE'
      AND IsManual='N';
      
    --  Create TreeNode --
    --  get AD_Tree_ID + ParentID
    SELECT c.AD_Tree_Org_ID,
      n.Node_ID
    INTO v_xTree_ID,
      v_xParent_ID
    FROM AD_ClientInfo c,
      AD_TreeNode n
    WHERE c.AD_Tree_Org_ID=n.AD_Tree_ID
      AND n.Parent_ID IS NULL
      AND c.AD_Client_ID=new.AD_Client_ID;
    -- DBMS_OUTPUT.PUT_LINE('Tree='||v_xTree_ID||'  Node='||:new.AD_Org_ID||'  Parent='||v_xParent_ID);
    --  Insert into TreeNode
    INSERT
    INTO AD_TreeNode
      (
        ad_treeNode_Id, AD_Client_ID, AD_Org_ID, IsActive,
        Created, CreatedBy, Updated,
        UpdatedBy, AD_Tree_ID, Node_ID,
        Parent_ID, SeqNo
      )
      VALUES
      (
        get_uuid(), new.AD_Client_ID, new.AD_Org_ID, new.IsActive,
        new.Created, new.CreatedBy, new.Updated,
        new.UpdatedBy, v_xTree_ID, new.AD_Org_ID,
        v_xParent_ID,(
        CASE new.IsSummary
          WHEN 'Y'
          THEN 100
          ELSE 999
        END
        )
      )
      ;
    -- Summary Nodes first
    -- Org Info
    INSERT
    INTO AD_OrgInfo
      (
        AD_Org_ID, AD_Client_ID, IsActive,
        Created, CreatedBy, Updated,
        UpdatedBy, C_Location_ID, Duns,
        TaxID
      )
      VALUES
      (
        new.AD_Org_ID, new.AD_Client_ID, 'Y',
        TO_DATE(NOW()), new.CreatedBy, TO_DATE(NOW()),
        new.CreatedBy, NULL, '?',
         '?'
      )
      ;
        
  ELSIF(TG_OP = 'DELETE') THEN
    --  Delete TreeNode --
    --  get AD_Tree_ID
    SELECT c.AD_Tree_Org_ID
    INTO v_xTree_ID
    FROM AD_ClientInfo c
    WHERE c.AD_Client_ID=old.AD_Client_ID;
    DELETE
    FROM AD_TREENODE
    WHERE AD_CLIENT_ID=old.AD_Client_ID
      AND AD_Tree_ID=v_xTree_ID
      AND Node_ID=old.AD_Org_ID;     
  END IF;
  -- Deleting
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

EXCEPTION
WHEN DATA_EXCEPTION THEN
  RAISE EXCEPTION '%', 'AD_Org InsertTrigger Error: No ClientInfo or parent TreeNode' ; --OBTG:-20014--
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;



select zsse_DropView ('ad_user_isactiveirrelevant_v');

CREATE OR REPLACE VIEW ad_user_isactiveirrelevant_v as
select ad_user_id,ad_user_id as ad_user_isactiveirrelevant_v_id, AD_CLIENT_ID, AD_ORG_ID, created,CREATEDBY, updated,UPDATEDBY,  NAME, DESCRIPTION , c_bpartner_id, 'Y'::character(1) as isactive from ad_user;



select zsse_DropView ('c_bpartneremployee_view');

CREATE OR REPLACE VIEW c_bpartneremployee_view AS 
            select c_bpartner.C_BPARTNER_ID as c_bpartneremployee_view_id,c_bpartner.C_BPARTNER_ID as C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED,ISACTIVE,UPDATED,CREATEDBY, UPDATEDBY, VALUE, NAME, DESCRIPTION, C_BP_GROUP_ID, ISEMPLOYEE, ISSALESREP, REFERENCENO, AD_LANGUAGE,
                   TAXID, ISTAXEXEMPT, C_GREETING_ID, ISWORKER, COUNTRY, CITY, ZIPCODE, ISPROJECTMANAGER, ISPROCUREMENTMANAGER, APPROVALAMT, ISAPPROVER, ISPRAPPROVER, ISPAYMENTAPPROVER,c_salary_category_id,rating,c_bp_employee.a_asset_id,
                   isinresourceplan, 'N'::character(1) as isSummary, c_bpartner.ad_image_id, c_bpartner.imageurl,c_bpartner.c_project_id
            from   c_bpartner left join c_bp_employee on c_bpartner.c_bpartner_id = c_bp_employee.c_bpartner_id
            where ISEMPLOYEE='Y';

CREATE OR REPLACE RULE c_bpartneremployee_view_insert AS
        ON INSERT TO c_bpartneremployee_view DO INSTEAD 
        (INSERT INTO c_bpartner (C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, VALUE, NAME, DESCRIPTION, C_BP_GROUP_ID, ISEMPLOYEE, ISSALESREP, REFERENCENO, AD_LANGUAGE, TAXID, ISTAXEXEMPT, C_GREETING_ID, ISWORKER,isinresourceplan,
                   COUNTRY, CITY, ZIPCODE, ISPROJECTMANAGER, ISPROCUREMENTMANAGER, APPROVALAMT, ISAPPROVER, ISPRAPPROVER, ISPAYMENTAPPROVER,c_salary_category_id,rating,ad_image_id,imageurl,c_project_id)
        VALUES (new.C_BPARTNER_ID, new.AD_CLIENT_ID, new.AD_ORG_ID, new.CREATEDBY, new.UPDATEDBY, new.VALUE, new.NAME, new.DESCRIPTION, new.C_BP_GROUP_ID, 'Y', new.ISSALESREP, 
                   new.REFERENCENO, new.AD_LANGUAGE, new.TAXID, new.ISTAXEXEMPT, new.C_GREETING_ID, new.ISWORKER,new.isinresourceplan,
                   new.COUNTRY, new.CITY, new.ZIPCODE, new.ISPROJECTMANAGER, new.ISPROCUREMENTMANAGER, new.APPROVALAMT, new.ISAPPROVER, new.ISPRAPPROVER, new.ISPAYMENTAPPROVER,new.c_salary_category_id,new.rating,new.ad_image_id,new.imageurl,new.c_project_id);    
        INSERT INTO c_bp_employee(c_bpartner_id, a_asset_id)
        VALUES (new.C_BPARTNER_ID, new.a_asset_id));

CREATE OR REPLACE RULE c_bpartneremployee_view_update AS
        ON UPDATE TO c_bpartneremployee_view DO INSTEAD 
        (UPDATE c_bpartner SET 
                AD_CLIENT_ID=new.AD_CLIENT_ID, 
                AD_ORG_ID=new.AD_ORG_ID,
                UPDATEDBY=new.UPDATEDBY, 
                VALUE=new.VALUE, 
                NAME=new.NAME, 
                DESCRIPTION=new.DESCRIPTION, C_BP_GROUP_ID=new.C_BP_GROUP_ID, isinresourceplan=new.isinresourceplan,
                ISSALESREP=new.ISSALESREP, REFERENCENO=new.REFERENCENO, AD_LANGUAGE=new.AD_LANGUAGE, TAXID=new.TAXID, ISTAXEXEMPT=new.ISTAXEXEMPT,ISWORKER=new.ISWORKER,
                COUNTRY=new.COUNTRY, CITY=new.CITY, ZIPCODE=new.ZIPCODE, ISPROJECTMANAGER=new.ISPROJECTMANAGER, ISPROCUREMENTMANAGER=new.ISPROCUREMENTMANAGER, APPROVALAMT=new.APPROVALAMT, ISAPPROVER=new.ISAPPROVER,
                ISPRAPPROVER=new.ISPRAPPROVER,ISPAYMENTAPPROVER= new.ISPAYMENTAPPROVER,c_salary_category_id=new.c_salary_category_id,rating=new.rating,
                isactive=new.isactive,
                ad_image_id=new.ad_image_id,imageurl=new.imageurl,c_project_id=new.c_project_id
               where C_BPARTNER_ID=new.C_BPARTNER_ID;
        UPDATE c_bp_employee SET
        A_ASSET_ID=new.A_ASSET_ID 
        where C_BPARTNER_ID=new.C_BPARTNER_ID);

CREATE OR REPLACE RULE c_bpartneremployee_view_delete AS
        ON DELETE TO c_bpartneremployee_view DO INSTEAD 
        (DELETE FROM c_bp_employee
		  WHERE c_bpartner_id = old.C_BPARTNER_ID;
        DELETE FROM c_bpartner
        WHERE c_bpartner_id = old.C_BPARTNER_ID);


CREATE OR REPLACE FUNCTION zssi_getNewProductEan(p_org character varying)
  RETURNS character varying AS
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
Part of Smartprefs
Default-Product EAN
*****************************************************/
v_return               character varying:='';
BEGIN
  if c_getconfigoption('autoproducteansequence', p_org)='Y' then
     select Ad_Sequence_Doc('Product EAN', p_org, 'Y') into v_return;
  end if;
RETURN v_return;

END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE  COST 100;


CREATE OR REPLACE FUNCTION zssi_getNewBPartnerValue(p_org character varying)
  RETURNS character varying AS
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
Part of Smartprefs
Default-Product Value
*****************************************************/
v_return               character varying:='';
BEGIN
  if c_getconfigoption('autobpartnervaluesequence', p_org)='Y' then
     select Ad_Sequence_Doc('BPartner Value', p_org, 'Y') into v_return;
  end if;
RETURN v_return;

END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE  COST 100;


CREATE OR REPLACE FUNCTION zssi_product_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Default-Price (and Costs) for Items
*****************************************************/
v_prlist_id               character varying;
v_version_id              character varying;
v_cur                     record;
v_cur2                     record;
v_guid                    varchar;
v_sc                      varchar:='';
v_i numeric;
v_master varchar;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  IF (TG_OP = 'INSERT') THEN
    -- Sandard-Cost =0     
      insert into m_costing (M_COSTING_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,  M_PRODUCT_ID, DATEFROM, DATETO, ISMANUAL, PRICE,  COSTTYPE,  COST)
             values(get_uuid(),new.AD_Client_ID, new.AD_Org_ID, now(), new.CREATEDBY, now(), new.UPDATEDBY, new.M_PRODUCT_ID,now(),to_date('01.01.9999','dd.mm.yyyy'),'N',0,'ST',0);
  END IF; 
  IF (TG_OP = 'UPDATE') THEN
    IF (new.value!=old.value or new.name!=old.name) THEN
      for v_cur in (select * from zssm_workstep_prp_v where m_product_id=new.m_product_id) 
      LOOP
          if new.value!=old.value then
                UPDATE zssm_workstep_prp_v set value=substr(replace(value,old.value,new.value),1,40) where  zssm_workstep_prp_v_id=v_cur.zssm_workstep_prp_v_id;            
          else
                UPDATE zssm_workstep_prp_v set name=substr(replace(name,old.name,new.name),1,60)  where  zssm_workstep_prp_v_id=v_cur.zssm_workstep_prp_v_id; 
          end if;
          for v_cur2 in (select * from Zssm_Productionplan_Task_V where zssm_workstep_prp_v_id=v_cur.zssm_workstep_prp_v_id)
          LOOP
            if new.value!=old.value then
                UPDATE zssm_productionplan_v set value=substr(replace(value,old.value,new.value),1,40) where zssm_productionplan_v_id=v_cur2.zssm_productionplan_v_id;            
            else
                UPDATE zssm_productionplan_v set name=substr(replace(name,old.name,new.name),1,60) where zssm_productionplan_v_id=v_cur2.zssm_productionplan_v_id;  
            end if;
          END LOOP;
      END LOOP;
    END IF;
    IF (coalesce(new.imageurl,'')!=coalesce(old.imageurl,'') or coalesce(new.ad_image_id,'')!=coalesce(old.ad_image_id,'')) then
        update zse_image_product set url=new.imageurl,ad_image_id=new.ad_image_id,updated=now() where zse_product_shop_id in 
               (select zse_product_shop_id from zse_product_shop  where m_product_id=new.m_product_id) and  
               coalesce(url,'')=coalesce(old.imageurl,'') and
               coalesce(ad_image_id,'')=coalesce(old.ad_image_id,'');
    end if;
    IF (new.name!=old.name or coalesce(new.description,'')!=coalesce(old.description,'') or coalesce(new.documentnote,'')!=coalesce(old.documentnote,'')) then
        update zse_product_shop set updated=now(),TITLE=new.name,  fullTITLE=new.name,content=new.description,description=new.documentnote where
               m_product_id=new.m_product_id and ismaster='Y' and 
               coalesce(TITLE,'')=coalesce(old.name,'') and
               coalesce(fullTITLE,'')=coalesce(old.name,'') and
               coalesce(content,'')=coalesce(old.description,'') and
               coalesce(description,'')=coalesce(old.documentnote,'');
    end if;
 END IF; -- UPDATE
  -- Auto generate Base Assembly
  if new.typeofproduct in ('CD','SA','AS','UA')  and new.isactive='Y' and 
     new.discontinued='N' and new.production='Y' and c_getconfigoption('createdefaultplanandworkstep',new.ad_org_id)='Y' then
     -- Alte Logik erhalten (Generiere P-Plan nach hauptmaske-Lagerort)
         if (select count(*) from zssm_workstep_prp_v where m_product_id=new.m_product_id)=0 and (select count(*) from m_product_org where m_product_id=new.m_product_id and isactive='Y' and isproduction='Y')=0 then
            if new.m_locator_id is not null then
                insert into zssm_workstep_prp_v(zssm_workstep_v_id,  ad_client_id,  
                        ad_org_id,   
                        created,  createdby,  updated,  updatedby,  seqno,  value,  name,  description,  m_product_id,  assembly,
                        qty,  issuing_locator,  receiving_locator,  setuptime,  timeperpiece,  isautotriggered,  isautogeneratedplan, startonlywithcompletematerial,  forcematerialscan)
                values (get_uuid(),new.ad_client_id,  
                    coalesce((select ad_org_id from m_locator where m_locator_id=new.m_locator_id),(select ad_org_id from ad_org where ad_org_id!='0' order by created limit 1)),
                    now(),new.createdby,now(),new.updatedby,10,new.value,substr(new.name,1,60),new.description,new.m_product_id,'Y',
                    1,new.m_locator_id,new.m_locator_id,0,1,'N','Y','N','N');
                -- Generate the right BOM
                update m_product_bom set updated=updated where m_product_id=new.m_product_id;
            end if;
         else -- Produktionpläne nach Einstellung Lagerplanung generieren.
            for v_cur in (select o.*  from m_product_org o where o.m_product_id=new.m_product_id  and o.isactive='Y' and o.isproduction='Y'
                          and not exists (select 0 from zssm_workstep_prp_v v where v.m_product_id=o.m_product_id and v.issuing_locator=o.m_locator_id and v.receiving_locator=o.m_locator_id))
            LOOP
                if (select count(*) from c_project where value=new.value)!=0 then
                    select '-'||shortcut into v_sc from ad_org where ad_org_id=v_cur.ad_org_id;
                    v_i:=1;
                    while ((select count(*) from c_project where value=new.value||v_sc) !=0)
                    LOOP
                        select '-'||shortcut||'-'||v_i into v_sc from ad_org where ad_org_id=v_cur.ad_org_id;
                        v_i:=v_i+1;
                    END LOOP;
                end if;
                insert into zssm_workstep_prp_v(zssm_workstep_v_id,  ad_client_id,  
                        ad_org_id,   
                        created,  createdby,  updated,  updatedby,  seqno,  value,  name,  description,  m_product_id,  assembly,
                        qty,  issuing_locator,  receiving_locator,  setuptime,  timeperpiece,  isautotriggered,  isautogeneratedplan, startonlywithcompletematerial,  forcematerialscan)
                values (get_uuid(),new.ad_client_id,  
                    v_cur.ad_org_id,
                    now(),new.createdby,now(),new.updatedby,10,new.value||v_sc,substr(new.name,1,60),new.description,new.m_product_id,'Y',
                    1,v_cur.m_locator_id,v_cur.m_locator_id,0,1,'N','Y','N','N');
                -- Generate the right BOM
                update m_product_bom set updated=updated where m_product_id=new.m_product_id;
                v_sc:='';
            END LOOP;
         end if;
  end if; -- Auto generate Base Assembly  END
  -- ECommerce-Settings
  IF (TG_OP = 'UPDATE') THEN
    if (new.m_product_category_id!=old.m_product_category_id) then
        delete from zse_product_shop where m_product_id=new.m_product_id and zse_shop_id in (select zse_shop_id from m_product_category_shop where m_product_category_id=old.m_product_category_id);
    end if;
    if new.issold='N' then
        delete from zse_product_shop where m_product_id=new.m_product_id;
    end if;
  END IF;
  IF (TG_OP = 'INSERT') OR  (TG_OP = 'UPDATE') THEN
    if (select count(*) from m_product_category_shop where m_product_category_id=new.m_product_category_id and new.issold='Y')>0 then
        for v_cur in (select * from m_product_category_shop where m_product_category_id=new.m_product_category_id
                      and not exists (select 0 from zse_product_shop s where s.zse_shop_id=m_product_category_shop.zse_shop_id and s.m_product_id=new.m_product_id)) 
        LOOP
            select get_uuid() into v_guid;
            select case when count(*)=0 then 'Y' else 'N' end into v_master from zse_product_shop where m_product_id=new.m_product_id and ismaster='Y';
            insert into zse_product_shop (zse_product_shop_id, ad_client_id, ad_org_id, created,  createdby,  updated,  updatedby, zse_shop_id, m_product_id,ismaster)
            values (v_guid,new.ad_client_id, new.ad_org_id, new.created,  new.createdby,  new.updated,  new.updatedby, v_cur.zse_shop_id,new.m_product_id,v_master);
            for v_cur2 in (select distinct mc.zse_webshopcategory_id from m_product_category_shopcategory mc,zse_webshopcategory wc where wc.zse_webshopcategory_id=mc.zse_webshopcategory_id 
                          and wc.zse_shop_id=v_cur.zse_shop_id and mc.m_product_category_id=new.m_product_category_id) 
            LOOP
                insert into zse_webshopcategory_product(zse_webshopcategory_product_id, ad_client_id, ad_org_id, created,  createdby,  updated,  updatedby, zse_webshopcategory_id,zse_shop_id,zse_product_shop_id)
                values (get_uuid(),new.ad_client_id, new.ad_org_id, new.created,  new.createdby,  new.updated,  new.updatedby, v_cur2.zse_webshopcategory_id,v_cur.zse_shop_id,v_guid);
            END LOOP;
            for v_cur2 in (select distinct mc.zse_tag_id from m_product_category_shoptag mc,zse_tag wc where wc.zse_tag_id=mc.zse_tag_id 
                          and wc.zse_shop_id=v_cur.zse_shop_id and mc.m_product_category_id=new.m_product_category_id) 
            LOOP
                insert into zse_tag_product(zse_tag_product_id, ad_client_id, ad_org_id, created,  createdby,  updated,  updatedby, zse_tag_id,zse_shop_id,zse_product_shop_id)
                values (get_uuid(),new.ad_client_id, new.ad_org_id, new.created,  new.createdby,  new.updated,  new.updatedby, v_cur2.zse_tag_id,v_cur.zse_shop_id,v_guid);
            END LOOP;
        END LOOP;
    end if;
  END IF;
RETURN NEW;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
select zsse_droptrigger('zssi_product_trg','m_product');

CREATE TRIGGER zssi_product_trg
  AFTER INSERT OR UPDATE 
  ON m_product
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_product_trg();
  
CREATE OR REPLACE FUNCTION m_product_locatordescription_userexit(p_m_product_id varchar)
  RETURNS varchar AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***********************************************************************************************+*****************************************
User-Exit to Extend Description of in out candidate view individually
**/
DECLARE
v_return varchar:='';
BEGIN
RETURN coalesce(v_return,'');
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION m_product_trl_bef_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Default-Price (and Costs) for Items
*****************************************************/
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  new.istranslated:='Y';
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
select zsse_droptrigger('m_product_trl_bef_trg','m_product_trl');

CREATE TRIGGER m_product_trl_bef_trg
  BEFORE INSERT OR UPDATE 
  ON m_product_trl
  FOR EACH ROW
  EXECUTE PROCEDURE m_product_trl_bef_trg();  
  
CREATE OR REPLACE FUNCTION m_product_trl_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Default-Price (and Costs) for Items
*****************************************************/
v_prlist_id               character varying;
v_version_id              character varying;
v_cur RECORD;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  for v_cur in (select zse_product_shop_id from zse_product_shop where m_product_id=new.m_product_id and ismaster='Y')
  LOOP
    IF (TG_OP = 'INSERT') or (TG_OP = 'UPDATE') THEN
        if (select count(*) from zse_product_shop_trl where zse_product_shop_id=v_cur.zse_product_shop_id and ad_language=new.ad_language)=0 then
            insert into zse_product_shop_trl(zse_product_shop_trl_id, ad_client_id, ad_org_id, createdby, updatedby, zse_product_shop_id,
                                             ad_language, title, fulltitle, content, description, istranslated)
            values(get_uuid(),new.ad_client_id, new.ad_org_id, new.createdby, new.updatedby,v_cur.zse_product_shop_id,
                   new.ad_language,new.name,new.name,new.description,new.documentnote,new.istranslated);

        end if;
    END IF; 
    IF (TG_OP = 'UPDATE')  THEN       
        IF (select count(*) from zse_product_shop_trl where zse_product_shop_id=v_cur.zse_product_shop_id and ad_language=new.ad_language and
                            coalesce(TITLE,'')=coalesce(old.name,'') and  
                            coalesce(fullTITLE,'')=coalesce(old.name,'') and 
                            coalesce(content,'')=coalesce(old.description,'') and
                            coalesce(description,'')=coalesce(old.documentnote,''))=1 
        then
            update zse_product_shop_trl set updated=now(),updatedby=new.updatedby,TITLE=new.name,  fullTITLE=new.name,content=new.description,
                                            description=new.documentnote where
                                        zse_product_shop_id=v_cur.zse_product_shop_id and ad_language=new.ad_language;    
               
        end if;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
select zsse_droptrigger('m_product_trl_trg','m_product_trl');

CREATE TRIGGER m_product_trl_trg
  AFTER INSERT OR UPDATE 
  ON m_product_trl
  FOR EACH ROW
  EXECUTE PROCEDURE m_product_trl_trg();


CREATE OR REPLACE FUNCTION zssi_product_uom_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Second UOM must differ from 1st UOM
*****************************************************/
v_count                   numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  select count(*) into v_count from m_product where m_product_id=new.m_product_id and c_uom_id=new.c_uom_id;
  if v_count>0 then
    RAISE EXCEPTION '%', '@SecondUomNotFirstUOM@';
  END IF;
  if (select c_uom_convert(1, new.c_uom_id, (select c_uom_id from m_product where m_product_id=new.m_product_id),'N')) is null then
     RAISE EXCEPTION '%', '@SecondUomNoConversion@';
  END IF;
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_bpartner_trg2()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
2.nd Trigger: Before Insert
Defaults for : c_paymentterm_id,c_invoiceschedule_id,po_pricelist_id,m_pricelist_id
*****************************************************/
v_payterm                  character varying;
v_isched                   character varying;
v_poplist                  character varying;
v_plist                    character varying;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  IF (TG_OP = 'INSERT') THEN
          -- Set defaults
          select c_paymentterm_id into v_payterm from c_paymentterm where isdefault='Y' and isactive='Y' and ad_org_id in ('0',new.ad_org_id) order by ad_org_id desc limit 1;
          select c_invoiceschedule_id into v_isched from c_invoiceschedule where isdefault='Y' and isactive='Y' and ad_org_id in ('0',new.ad_org_id) order by ad_org_id desc limit 1;
          select m_pricelist_id into v_plist from m_pricelist where isdefault='Y' and isactive='Y' and issopricelist='Y' and ad_org_id in ('0',new.ad_org_id) order by ad_org_id desc limit 1;
          select m_pricelist_id into v_poplist from m_pricelist where isactive='Y' and isdefault='Y' and issopricelist='N' and ad_org_id in ('0',new.ad_org_id) order by ad_org_id desc limit 1;
          new.c_paymentterm_id:=v_payterm;
          new.PO_PaymentTerm_ID:=v_payterm;
          new.c_invoiceschedule_id:=v_isched;
          new.m_pricelist_id:=v_plist;
          new.PO_PriceList_ID:=v_poplist;
          new.PaymentRule:='R';
          new.InvoiceRule:='I';
          new.PaymentRulePO:='R';
          new.Invoicegrouping:='000000000000000';
          new.DeliveryRule:='A';
          new.DeliveryViaRule:='D';
  END IF; 
  IF (TG_OP='UPDATE') THEN
    if new.iscustomer!=old.iscustomer and new.iscustomer='Y' then
        IF ((select count(*) from c_bp_vendor_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
            IF ((select count(*) from c_bp_customer_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
                if c_getconfigoption('createdatevaccount',new.ad_org_id)='Y' then
                    new.value:=zsfi_createaccounts(new.C_BPARTNER_ID , new.ad_org_id, 'C');
                END IF;
            END IF;
        END IF;
    END IF;
    IF new.isvendor!=old.isvendor and new.isvendor='Y' THEN
        IF ((select count(*) from c_bp_customer_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
            IF ((select count(*) from c_bp_vendor_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
                if c_getconfigoption('createdatevaccount',new.ad_org_id)='Y' then
                    new.value:=zsfi_createaccounts(new.C_BPARTNER_ID ,new.ad_org_id, 'V');
                END IF;
            END IF;
        END IF;   
    END IF;
   END IF;
   
 -- # are not allowed in name and searchkey
 IF (NEW.name LIKE '%#%' OR NEW.value LIKE '%#%') THEN
    RAISE EXCEPTION '%', '@invalidcharacter@' || ': #';
 END IF;
   
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_DropTrigger ('zssi_bpartner_trg2','c_bpartner');

CREATE TRIGGER zssi_bpartner_trg2
  BEFORE INSERT OR UPDATE 
  ON c_bpartner
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_bpartner_trg2();

CREATE OR REPLACE FUNCTION zssi_bpartner_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
After insert or update
Default-Address for Business partners (Standard/Germany)
If EMPLOYEE- Only one userin ad-User is allowed
*****************************************************/
v_location_id              character varying;
v_count                    numeric;
v_shop                     character varying;
v_product varchar;
v_org varchar;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  IF (TG_OP = 'INSERT') THEN
      -- Create Default Location
      select get_uuid() into v_location_id from dual;
      insert into c_location(c_location_id, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, ADDRESS1, C_COUNTRY_ID)
        values (v_location_id,new.AD_Client_ID, new.AD_Org_ID, 'Y', now(), new.CREATEDBY, now(), new.UPDATEDBY, 'Standard','101');
      insert into c_bpartner_location (C_BPARTNER_LOCATION_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, NAME, ISBILLTO, ISSHIPTO, ISPAYFROM, ISREMITTO,isheadquarter,  C_BPARTNER_ID, C_LOCATION_ID, ISTAXLOCATION)
            values (get_uuid(),new.AD_Client_ID, new.AD_Org_ID, 'Y', now(), new.CREATEDBY, now(), new.UPDATEDBY, 'Standard','Y','Y','Y','Y','Y',new.C_BPARTNER_ID,v_location_id,'Y');
      -- If Employee
      if new.isemployee='Y' then
        select count(*) into v_count from ad_user,c_bpartner where ad_user.c_bpartner_id=c_bpartner.c_bpartner_id and ad_user.c_bpartner_id=new.c_bpartner_id;
         if v_count=0 then
            -- Create default-Entry in ad_user
            insert into ad_user(AD_USER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME, C_BPARTNER_ID)
                    values(get_uuid(),new.AD_CLIENT_ID,new.AD_ORG_ID,new.CREATEDBY,new.UPDATEDBY,new.name,new.C_BPARTNER_ID);
         end if;
      end if;
      if new.autocreatecommission!='N' then
            select m_product_id into v_product from m_product where name='Provision';
            if v_product is null then 
                RAISE EXCEPTION '%','Sie müssen einen Artikel mit dem Namen Provision anlegen, wenn sie Mitarbeiter in der Vertriebsstruktur anlegen wollen.';  
            end if;
            if new.ad_org_id='0' then
                select ad_org_id into v_org from c_orgconfiguration where isstandard='Y';
            else
                v_org:=new.ad_org_id;
            end if;
            -- Create default-Entry in commission
            insert into c_commission(c_commission_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME, C_BPARTNER_ID,c_currency_id,frequencytype,docbasistype,m_product_id,listdetails)
                   values(get_uuid(),new.AD_CLIENT_ID,v_org,new.CREATEDBY,new.UPDATEDBY,'Provision',new.C_BPARTNER_ID,'102','M',new.autocreatecommission,v_product,'Y');
      end if;
      -- Load ECommerce Preferences
      select count(*) into v_count from ad_module where name='ECommerce' and isactive='Y';
      if v_count=1 then
          select ZSE_SHOP_ID into v_shop from ZSE_SHOP where AD_ORG_ID in ('0',new.ad_org_id) and isactive='Y' order by ad_org_id desc limit 1;
          if v_shop is not null then
              insert into ZSE_ECOMMERCEGRANT (ZSE_ECOMMERCEGRANT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, ZSE_SHOP_ID, C_BPARTNER_ID, PAYMENTMETHOD)
                select get_uuid(),new.AD_CLIENT_ID,new.AD_ORG_ID,new.CREATEDBY,new.UPDATEDBY,v_shop,new.C_BPARTNER_ID,PAYMENTMETHOD from zse_shop_defaultpaymethod where ZSE_SHOP_ID=v_shop and isactive='Y';
          end if;
      end if;
  END IF; 
  IF (TG_OP = 'UPDATE') THEN
      if new.isemployee='Y' then
         select count(*) into v_count from ad_user,c_bpartner where ad_user.c_bpartner_id=c_bpartner.c_bpartner_id and ad_user.c_bpartner_id=new.c_bpartner_id;
         if v_count>1 then
            RAISE EXCEPTION '%', '@zssi_OnlyOneUserOnEmp@';
            return old;
         end if;
         if v_count=0 then
            -- Create default-Entry in ad_user
            insert into ad_user(AD_USER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME, C_BPARTNER_ID)
                   values(get_uuid(),new.AD_CLIENT_ID,new.AD_ORG_ID,new.CREATEDBY,new.UPDATEDBY,new.name,new.C_BPARTNER_ID);
         end if;
      end if;
      -- Propagate ORG-Changes to Subsequent entities
      if new.ad_org_id!=old.ad_org_id then
        update c_bp_bankaccount set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bp_customer_acct set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bp_employee_acct set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bp_salcategory set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bpartner_location set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bpartneremployeecalendarsettings set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bpartneremployeeevent set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bp_vendor_acct set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update c_bp_salcategory set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id;
        update ad_user set ad_org_id=new.ad_org_id where c_bpartner_id = new.c_bpartner_id and ad_org_id=old.ad_org_id;
        -- Trigger RE-Computation of Resource Plan
        update c_project_processstatus set resourceplanrequested='Y';
      end if;
  END IF;  
  IF (TG_OP='INSERT') THEN
    if new.iscustomer='Y' then
        IF ((select count(*) from c_bp_vendor_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
            IF ((select count(*) from c_bp_customer_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
                if c_getconfigoption('createdatevaccount',new.ad_org_id)='Y' then
                    new.value:=zsfi_createaccounts(new.C_BPARTNER_ID , new.ad_org_id, 'C');
                END IF;
            END IF;
        END IF;
    END IF;
    IF  new.isvendor='Y' THEN
        IF ((select count(*) from c_bp_customer_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
            IF ((select count(*) from c_bp_vendor_acct where c_bpartner_id=new.c_bpartner_id)=0) THEN
                if c_getconfigoption('createdatevaccount',new.ad_org_id)='Y' then
                    new.value:=zsfi_createaccounts(new.C_BPARTNER_ID ,new.ad_org_id, 'V');
                END IF;
            END IF;
        END IF;   
    END IF;
   END IF;
RETURN NEW;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION c_bpartner_tree_trg() RETURNS trigger
AS $BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Matserdata
Imlements Business Partner Tree 
Used in Multi Level Marketing
*****************************************************/
v_Tree_ID              character varying;
v_Parent_ID            character varying;
v_exists               numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
  select ad_tree_id into v_Tree_ID from ad_tree where treetype='BP' and isactive='Y';
  select ad_treenode_id into v_Parent_ID from ad_treenode where ad_tree_id=v_Tree_ID and parent_id is null;
  -- only if tree exists
  if v_Tree_ID is not null and v_Parent_ID is not null then
       IF TG_OP in ('INSERT','UPDATE') then
            select count(*) into v_exists from AD_TreeNode where AD_Tree_ID=v_Tree_ID and Node_ID=new.c_bpartner_ID;
            if v_exists =0 and new.isemployee='Y' THEN    
                --  Insert into TreeNode
                INSERT INTO AD_TreeNode
                  (AD_TreeNode_ID, AD_Client_ID, AD_Org_ID,
                  IsActive, Created, CreatedBy, Updated, UpdatedBy,
                  AD_Tree_ID, Node_ID,
                  Parent_ID, SeqNo)
                VALUES
                  (get_uuid(), new.AD_Client_ID, new.AD_Org_ID,
                  new.IsActive, new.Created, new.CreatedBy, new.Updated, new.UpdatedBy,
                  v_Tree_ID, new.c_bpartner_ID,
                  '0', (CASE new.IsSummary WHEN 'Y' THEN 100 ELSE 999 END));    -- Summary Nodes first
            end if;
            if new.isactive='N' then 
                delete from AD_TreeNode where AD_Tree_ID=v_Tree_ID and Node_ID=new.c_bpartner_ID;
            end if;
       else --delete
            delete from AD_TreeNode where AD_Tree_ID=v_Tree_ID and Node_ID=old.c_bpartner_ID;
       end if;
  end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
select zsse_DropTrigger ('c_bpartner_tree_trg','c_bpartner');

CREATE TRIGGER c_bpartner_tree_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON c_bpartner
  FOR EACH ROW
  EXECUTE PROCEDURE c_bpartner_tree_trg();
  
  
CREATE OR REPLACE FUNCTION c_bp_salcategory_trg2() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 


/*************************************************************************
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
* All portions are Copyright (C) 2001-2008 Openbravo SL
* All Rights Reserved.
* Contributor(s):  2020 OpenZ Software GmbH
************************************************************************/
  v_count NUMERIC;
  v_dateFrom TIMESTAMP;
  v_cBPSalCategory VARCHAR(32); --OBTG:varchar2--
   v_bpartner varchar; 
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;




  IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT' )  THEN
    v_bpartner:=new.C_BPARTNER_ID;
  ELSE
    v_bpartner:=old.C_BPARTNER_ID;
  END IF;

    SELECT MAX(DATEFROM)
    INTO v_dateFrom
    FROM C_BP_SALCATEGORY
    WHERE C_BP_SALCATEGORY.C_BPARTNER_ID = v_bpartner;

    v_cBPSalCategory := null;

    SELECT COUNT(*) INTO v_count
    FROM C_BP_SALCATEGORY
    WHERE C_BP_SALCATEGORY.C_BPARTNER_ID = v_bpartner
    AND DATEFROM = v_dateFrom;

    IF (v_count<>0) THEN

      SELECT C_SALARY_CATEGORY_ID INTO v_cBPSalCategory
      FROM C_BP_SALCATEGORY
      WHERE C_BP_SALCATEGORY.C_BPARTNER_ID = v_bpartner
      AND DATEFROM = v_dateFrom;

    END IF;

    UPDATE C_BPARTNER SET
    C_SALARY_CATEGORY_ID = v_cBPSalCategory
    WHERE C_BPARTNER.C_BPARTNER_ID = v_bpartner;


IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

select zsse_DropTrigger ('c_bp_salcategory_trg2','c_bp_salcategory');

CREATE TRIGGER c_bp_salcategory_trg2
  AFTER INSERT OR UPDATE OR DELETE
  ON c_bp_salcategory
  FOR EACH ROW
  EXECUTE PROCEDURE c_bp_salcategory_trg2();

select zsse_DropTrigger ('zssi_aduser_trg','ad_user');
CREATE OR REPLACE FUNCTION zssi_aduser_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - On Insert. Only one user on employees and undefined partner
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from ad_user,c_bpartner where ad_user.c_bpartner_id=c_bpartner.c_bpartner_id and ad_user.c_bpartner_id=new.c_bpartner_id 
  and (c_bpartner.isemployee='Y') and ad_user.ad_user_id!=new.ad_user_id;
  if v_count > 0  then
      RAISE EXCEPTION '%', '@zssi_OnlyOneUserOnEmp@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  

CREATE TRIGGER zssi_aduser_trg
  BEFORE INSERT or UPDATE
  ON ad_user FOR EACH ROW
  EXECUTE PROCEDURE zssi_aduser_trg();

select zsse_DropTrigger ('zssi_adusera_trg','ad_user');
CREATE OR REPLACE FUNCTION zssi_adusera_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - On Insert. Only one user on employees and undefined partner
*****************************************************/
v_count          numeric:=1;
v_cur record;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  if new.password!=old.password or new.isactive!=old.isactive or new.processing='Y' then
    update ad_user set seqno=null,processing='N' where seqno is not null;
    for v_cur in (select * from ad_user a where ad_user_id not in ('0','100','DDAA21D11CB04D4D8EC59E39934B27FB') and a.password is not null and a.isactive ='Y' 
                        and exists (select 0 from ad_user_roles r where r.ad_user_id=a.ad_user_id) order by created)
    LOOP
        update ad_user set seqno=v_count,processing='N' where ad_user_id=v_cur.ad_user_id;
        v_count:=v_count+1;
    END LOOP;
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  

CREATE TRIGGER zssi_adusera_trg
  AFTER UPDATE
  ON ad_user FOR EACH ROW
  EXECUTE PROCEDURE zssi_adusera_trg();
  
select zsse_DropTrigger ('zssi_aduserrolea_trg','ad_user_roles');
CREATE OR REPLACE FUNCTION zssi_aduserrolea_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - On Insert. Only one user on employees and undefined partner
*****************************************************/
v_count          numeric:=1;
v_cur record;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF;
  IF TG_OP = 'DELETE' then
    update ad_user set processing='Y' where ad_user_id=old.ad_user_id ;
    RETURN OLD;
  end if;
  IF TG_OP in ('INSERT','UPDATE') then
    update ad_user set processing='Y' where ad_user_id=new.ad_user_id ;
    RETURN NEW;
  end if;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  

CREATE TRIGGER zssi_aduserrolea_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON ad_user_roles FOR EACH ROW
  EXECUTE PROCEDURE zssi_aduserrolea_trg();



CREATE OR REPLACE FUNCTION zssi_mproductprice_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************/
v_plv varchar;
v_pl  varchar;
v_valid timestamp;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 

       if (TG_OP ='UPDATE') then
        if coalesce(old.c_uom_id,'')!=coalesce(new.c_uom_id,'') then
            update m_offerplist_v set c_uom_id=new.c_uom_id, updated=now(),updatedby=new.updatedby
            where issalesoffer='Y' and m_pricelist_id=(select m_pricelist_id from m_pricelist_version where m_pricelist_version_id=new.m_pricelist_version_id)
            and m_product_id=new.m_product_id
            and case when old.c_uom_id is not null then c_uom_id=old.c_uom_id else c_uom_id is null end;
        end if;
       end if;
       SELECT pv.M_PRICELIST_VERSION_ID,pv.m_pricelist_id,pv.validfrom  into v_plv,v_pl,v_valid FROM M_PRICELIST_VERSION pv,m_pricelist p
                    WHERE p.m_pricelist_id = pv.m_pricelist_id 
                       and p.m_pricelist_id = (select m_pricelist_id from M_PRICELIST_VERSION where M_PRICELIST_VERSION_id=new.M_PRICELIST_VERSION_id) and
                           pv.VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=(select m_pricelist_id from M_PRICELIST_VERSION where M_PRICELIST_VERSION_id=new.M_PRICELIST_VERSION_id))
                    LIMIT 1;
       -- If a Product is in the new PL-Version, update all Offers to that new version
       -- raise notice '%',v_plv||'#'||new.M_PRICELIST_VERSION_ID;
       if v_plv=new.M_PRICELIST_VERSION_ID then
            update m_offer set m_productprice_id=new.m_productprice_id where m_productprice_id in 
                    (select p.m_productprice_id from m_productprice p,M_PRICELIST_VERSION v,m_pricelist pl where p.M_PRICELIST_VERSION_id=v.M_PRICELIST_VERSION_id
                     and v.M_PRICELIST_id=pl.M_PRICELIST_id and pl.M_PRICELIST_id=v_pl and v.M_PRICELIST_VERSION_id!=new.M_PRICELIST_VERSION_ID)
                     and  coalesce(v_valid,trunc(now()))<=coalesce(dateto,trunc(now()));
       end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_DropTrigger ('zssi_mproductprice_trg','m_productprice');

CREATE TRIGGER zssi_mproductprice_trg
  AFTER UPDATE OR INSERT
  ON m_productprice
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_mproductprice_trg();

  
CREATE OR REPLACE FUNCTION zssi_mproductpo_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
On Insert or Update. Set the Latest Vendor and Vendor-Productno. Update Price History
In M_product
*****************************************************/
v_vendor character varying;
v_vproductno character varying;
v_productid character varying;
v_org character varying;
v_youngest timestamp;
v_manufacturer varchar;
v_manuno varchar;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   if (TG_OP = 'UPDATE') then
      v_productid:=new.m_product_id;
      v_org:=new.ad_org_id;
      select max(validfrom) into v_youngest from m_product_po_history where m_product_po_id=new.m_product_po_id;
      if trunc(now())>coalesce(v_youngest,now()-1)  then
        insert into m_product_po_history (M_PRODUCT_PO_HISTORY_ID,M_PRODUCT_PO_ID, M_PRODUCT_ID, C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, 
                                          CREATEDBY, UPDATEDBY, PRICELIST, PRICEPO, PRICELASTPO, QTYPO, VALIDFROM,qualityrating) 
        VALUES (get_uuid(),old.M_PRODUCT_PO_ID, old.M_PRODUCT_ID, old.C_BPARTNER_ID, old.AD_CLIENT_ID, old.AD_ORG_ID, 
                                          old.CREATEDBY, old.UPDATEDBY, old.PRICELIST, old.PRICEPO, old.PRICELASTPO, old.QTYLASTPO, trunc(now()),old.qualityrating);

      else
        update m_product_po_history set updated=now(),updatedby=old.updatedby,PRICELIST=old.PRICELIST,PRICEPO=old.PRICEPO, PRICELASTPO=old.PRICELASTPO, QTYPO=old.QTYLASTPO,qualityrating=old.qualityrating
        where m_product_po_id=old.m_product_po_id and validfrom=v_youngest;
      end if;
      if coalesce(old.c_uom_id,'')!=coalesce(new.c_uom_id,'') then
            update m_offer_v set c_uom_id=new.c_uom_id, updated=now(),updatedby=new.updatedby
            where  m_product_po_id=new.m_product_po_id ;
       end if;
   end if;
   if (TG_OP = 'DELETE') then
      v_productid:=old.m_product_id;
      v_org:=old.ad_org_id;
   end if;
   if (TG_OP = 'INSERT') then
      v_productid:=new.m_product_id;
      v_org:=new.ad_org_id;
   end if;
   -- Select current Vendor
   select PO.C_BPARTNER_ID,po.vendorproductno,m.name,po.manufacturernumber into v_vendor ,v_vproductno,v_manufacturer,v_manuno
                   from M_PRODUCT_PO po left join  m_manufacturer m on m.m_manufacturer_id=po.m_manufacturer_id
                   where po.m_product_id=v_productid and PO.iscurrentvendor='Y' and PO.AD_ORG_ID in ('0',v_org) order by coalesce(po.qualityrating,0) desc,po.updated desc limit 1;
  -- Do the Update
  update m_product set c_bpartner_id=v_vendor, vendorproductno=v_vproductno,
         manufacturer=v_manufacturer,
         manufacturernumber=v_manuno 
  where m_product_id=v_productid;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


drop trigger zssi_mproductpo_trg on m_product_po;

CREATE TRIGGER zssi_mproductpo_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON m_product_po
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_mproductpo_trg();

/**************************************************************************************************************************************+

IMPROVEMENTS - Master-DATA

Database Functions

Reactivate Deactivated Products







***************************************************************************************************************************************/


CREATE OR REPLACE FUNCTION zssi_reactivateitem(p_PInstance_ID character varying) RETURNS void 
AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Process: Reactivate an Item
*****************************************************/
v_message character varying:='Success';
v_Record_ID  character varying;
v_User    character varying;
v_count numeric;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    else
      -- Select Product-ID from parameters
      select P_String into v_Record_ID from AD_PINSTANCE_PARA where ParameterName='m_product_id' and AD_PInstance_ID=p_PInstance_ID;
    end if;--  Update AD_PInstance
    if v_Record_ID is null then
        v_message:='Record not found';
    end if;
    update m_product set isactive='Y',updated=now(),updatedby= v_User where m_product_id=v_Record_ID;
 
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_message);
    return;
EXCEPTION
    WHEN OTHERS then
       v_message:= '@ERROR=' || SQLERRM;   
       --ROLLBACK;
       -- 0=failed
       PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
       return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_reactivateitem(p_PInstance_ID character varying) OWNER TO tad; 




CREATE OR REPLACE FUNCTION zssi_bplocation_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011-2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - Add main Address Searchable to c_bpartner
*****************************************************/
v_count          numeric;
v_country        character varying;
v_countryID      character varying;
v_zip            character varying;
v_city           character varying;
v_adr1           character varying;
v_adr2           character varying;
v_client         character varying;
v_lang         character varying;
v_regId varchar;
 v_region varchar;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN RETURN NEW; END IF; 
  select count(*) into v_count from c_bpartner_location where c_bpartner_id=new.c_bpartner_id and isheadquarter='Y';
  -- Do only allow one heaquarter per business partner
  if (TG_OP = 'INSERT' and v_count>0 and new.isheadquarter='Y') then
      RAISE EXCEPTION '%', '@zssi_OnlyOneHeadinBP@';
  end if; 
  if TG_OP = 'UPDATE' then
      if (v_count>0 and old.isheadquarter='N' and new.isheadquarter='Y') then
         RAISE EXCEPTION '%', '@zssi_OnlyOneHeadinBP@';
      end if;
  end if;
  -- Update the name of the location
  If (new.c_location_id is not null) then    
     select c_country_id,city,postal,address1,address2,c_region_id,ad_client_id into v_countryID,v_city,v_zip,v_adr1,v_adr2,v_regId,v_client from c_location where c_location_id=new.c_location_id;
     select ad_language into v_lang from ad_client where ad_client_id=v_client;
     select name into v_country from c_country_trl where c_country_id=v_countryID and ad_language=v_lang;
      select name into v_region from c_region where c_region_id=v_regId;
     --new.name:=substr(coalesce(v_country,' ')||', '||coalesce(v_zip||' ',' ')||coalesce(v_city,' ')||', '||coalesce(v_adr1,' '),1,60);
     new.name:=(coalesce(new.deviant_bp_name||' - ','')||coalesce(v_adr1||' - ','')||coalesce(v_adr2||' - ','')||coalesce(v_zip||' ','')||coalesce(v_city,'')||' - '||coalesce(v_region,'')||coalesce(v_country,'')); 
     if (new.isheadquarter='Y') then 
          -- support redundant columns in filter dialog
          update c_bpartner set
            country=substr(v_country,1,60),
            city=substr(v_city,1,60),
            zipcode=substr(v_zip,1,10),
            c_location_id = new.c_location_id,
            region = substr(v_region,1,60)
          where c_bpartner_id=new.c_bpartner_id;
     end if;
  end if;
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_bplocation_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION m_product_trg()
  RETURNS trigger AS
$BODY$ DECLARE 

/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/*
 Contributions: Modified wuth new accounting rules. Accounts are not copied anymore 
                Added Freight Products must not be Items 
******************************************************************************************************************************/
    v_xTree_ID                                     VARCHAR(32); --OBTG:varchar2--
    v_xParent_ID                                   VARCHAR(32); --OBTG:varchar2--
    v_ControlNo                                NUMERIC;
BEGIN
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

 IF (TG_OP = 'UPDATE') THEN
    -- Do not allow to de-activate products with OnHand Qty
      IF ((new.IsActive='N' AND old.IsActive='Y') or (new.producttype='S' and old.producttype='I')
           or new.isserialtracking!=old.isserialtracking or new.isbatchtracking!=old.isbatchtracking) THEN
      SELECT  COALESCE(SUM(QtyOnHand), 0) INTO v_ControlNo
      FROM M_Storage_Detail s
      WHERE s.M_Product_ID=new.M_Product_ID;
        IF (v_ControlNo <> 0) THEN
          RAISE EXCEPTION '%', '@CannotChangeStockedProduct@'; --OBTG:-20400--
        END IF;
      END IF;
 END IF;
 -- Restriction on Freight Products and Sets
 IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
     if new.isfreightproduct='Y' and (new.producttype!='S' or new.isstocked!='N') then
        RAISE EXCEPTION '%', '@zssi_FreightMustbeserviceandnotstocked@'; --OBTG:-20400--
     END IF;
     if new.issetitem='Y' and (new.producttype!='I' or new.typeofproduct in ('CD','SA','AS','UA') or new.isstocked!='N' or new.isbom!='Y' or new.ispurchased!='N') then
        RAISE EXCEPTION '%', '@SetmustbeBomButnotbeStocked@'; --OBTG:-20400--
     END IF;
 END IF;
 -- Translations
 IF (TG_OP = 'INSERT') THEN
     --  Create Translation Row
     INSERT INTO M_Product_Trl
         (M_Product_Trl_ID, M_Product_ID, AD_Language, AD_Client_ID, AD_Org_ID,
         IsActive, Created, CreatedBy, Updated, UpdatedBy,
         Name, DocumentNote,description, IsTranslated)
     SELECT get_uuid(), new.M_Product_ID, AD_Language, new.AD_Client_ID, new.AD_Org_ID,
         new.IsActive, new.Created, new.CreatedBy, new.Updated, new.UpdatedBy,
         new.Name, new.DocumentNote,new.description, 'N' FROM  AD_Language
     WHERE IsActive = 'Y' AND IsSystemLanguage = 'Y'
     AND isonly4format='N';
   -- AND EXISTS (SELECT * FROM AD_Client
   --  WHERE AD_Client_ID=new.AD_Client_ID AND IsMultiLingualDocument='Y');
 ELSEIF (TG_OP = 'UPDATE') THEN
   UPDATE m_product_trl
   SET name = new.name, description = new.description, documentnote = new.documentnote,
       Updated=new.Updated, updatedBy=new.UpdatedBy
   WHERE
         m_product_id = new.m_product_id
     AND ad_language = (SELECT ad_language FROM AD_Client
                        WHERE AD_Client_ID=new.AD_Client_ID);
   if (old.production!=new.production and new.production = 'Y') then
        update m_product_bom set updated=new.updated where m_product_id=new.m_product_id;
   end if;
END IF;
RETURN NEW;
END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION zspm_productbom_post_trg()
RETURNS trigger AS
$body$
 -- Synchronize all BASE-Worksteps producing this ITEM
DECLARE
 v_cur RECORD;
 v_cur2 RECORD;
 v_count numeric;
 v_locator varchar;
 v_isprod varchar;
 v_desc varchar;
 v_constrm varchar;
 v_rawmat varchar;
 v_qty numeric;
 v_pos numeric;
 v_ass varchar;
 v_prod varchar;
 v_oldprod varchar;
 v_user varchar;
 v_org varchar;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;

  IF (TG_OP <> 'DELETE') then
    select count(*) into v_count from m_product_bom where m_product_id=new.m_product_id and m_product_bom_id!=new.m_product_bom_id and line=new.line;
    if v_count>=1 then
        raise exception '%', '@duplicatelinenumber@ in :'||coalesce((select value||'-'||name from m_product where m_product_id=new.m_product_id),'#')||' Pos: '||coalesce(to_char(new.line),'#')||'-'||coalesce((select value||'-'||name from m_product where m_product_id=new.m_productbom_id),'#');
    end if;
    v_ass:=new.m_product_id;
    v_prod:=new.m_productbom_id;
    if TG_OP = 'UPDATE' and new.m_productbom_id!=old.m_productbom_id then
        v_oldprod:=old.m_productbom_id;
    else
        v_oldprod:=null;
    end if;
    v_user:=new.updatedby;
    v_org:=new.ad_org_id;
  ELSE
    v_ass:=old.m_product_id;
    v_prod:=old.m_productbom_id;
    v_user:=old.updatedby;
    v_org:=old.ad_org_id;
  END IF;
  if c_getconfigoption('synchronizeworkstepboms',v_org)='Y' then
        select  m_locator_id,production into v_locator,v_isprod from m_product where m_product_id=v_prod;-- Alte Logik beibehalten - Entnahme-Locator von Hauptmaske
        -- All BASE-Worksteps producing this Item
        for v_cur in (select * from c_projecttask where assembly='Y' and c_project_id is null and m_product_id=v_ass)
        LOOP 
            -- Neue Logik: Bei Kaufteilen: Entnahme aus WE-Lager, ORG Spez. 
            if (select count(*) from m_product_org where isproduction='N' and m_product_id=v_prod and isactive='Y' and ad_org_id=v_cur.ad_org_id)>0 then
                -- Geiches Lager wie Prod
                    select  m_locator_id into v_locator from m_product_org where isproduction='N' and m_product_id=v_prod and isactive='Y' and ad_org_id=v_cur.ad_org_id 
                    and m_locator_id in (select m_locator_id from m_locator where m_warehouse_id = (select m_warehouse_id from m_locator where m_locator_id=v_cur.issuing_locator)) 
                    order by isvendorreceiptlocator desc,created limit 1;
                if v_locator is null then
                    select  m_locator_id into v_locator from m_product_org where isproduction='N' and m_product_id=v_prod and isactive='Y' and ad_org_id=v_cur.ad_org_id order by isvendorreceiptlocator desc,created limit 1;
                end if;
            end if;
            -- Neue Logik: Bei Baugruppen: Entnahme aus Produktionlager, ORG Spez. 
            if v_isprod='Y' and (select count(*) from m_product_org where isproduction='Y' and m_product_id=v_prod and isactive='Y' and ad_org_id=v_cur.ad_org_id)>0 then
                select  m_locator_id into v_locator from m_product_org where isproduction='Y' and m_product_id=v_prod and isactive='Y' and ad_org_id=v_cur.ad_org_id 
                and m_locator_id in (select m_locator_id from m_locator where m_warehouse_id = (select m_warehouse_id from m_locator where m_locator_id=v_cur.issuing_locator)) 
                order by created limit 1;
                if v_locator is null then
                    select  m_locator_id into v_locator from m_product_org where isproduction='Y' and m_product_id=v_prod and isactive='Y' and ad_org_id=v_cur.ad_org_id order by created limit 1;
                end if;
            end if;
            -- Zusammenfassen gleicher Materialpositionen.
            -- Generieren der Workstep BOM
            delete from zspm_projecttaskbom where c_projecttask_id=v_cur.c_projecttask_id and m_product_id=coalesce(v_oldprod,v_prod);
            for v_cur2 in (select * from m_product_bom where m_product_id=v_ass and isactive='Y' and m_productbom_id=v_prod and workstepname is null order by line)
            LOOP
                v_desc:=coalesce(v_desc,'')||case when v_pos is not null then '. Pos.'||v_cur2.line||', Qty.'||v_cur2.bomqty||': ' else '' end ||coalesce(v_cur2.description,'');
                v_constrm:=coalesce(v_constrm,'')||case when v_pos is not null then '. Pos.'||v_cur2.line||': ' else '' end ||coalesce(v_cur2.constuctivemeasure,'');
                v_rawmat:=coalesce(v_rawmat,'')||case when v_pos is not null then '. Pos.'||v_cur2.line||': ' else '' end ||coalesce(v_cur2.rawmaterial,'');
                v_qty:=coalesce(v_qty,0)+v_cur2.bomqty;
                if v_pos is null then
                    v_pos:= v_cur2.line;
                end if;
            END LOOP;
            if v_qty is not null then
                INSERT INTO zspm_projecttaskbom (zspm_projecttaskbom_id,isactive, c_projecttask_id, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, 
                    issuing_locator,receiving_locator,
                    quantity,line,description,constuctivemeasure,rawmaterial)
                VALUES (get_uuid(), 'Y',v_cur.c_projecttask_id, v_cur.ad_client_id, v_cur.ad_org_id, v_user, v_user, v_prod, 
                    coalesce(v_locator,v_cur.issuing_locator),coalesce(v_locator,v_cur.receiving_locator),
                    v_qty,v_pos,substr(v_desc,1,2000),substr(v_constrm,1,255),substr(v_rawmat,1,255));
            end if;
            v_qty:=null;
            v_pos:=null;
            v_desc:=null;
            v_constrm:=null;
            v_rawmat:=null;
        END LOOP;
  END IF; -- Config Option
  IF (TG_OP <> 'DELETE') then
    RETURN NEW; 
  ELSE
    RETURN OLD;
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zspm_productbom_post_trg', 'm_product_bom');
CREATE TRIGGER zspm_productbom_post_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON m_product_bom FOR EACH ROW
  EXECUTE PROCEDURE zspm_productbom_post_trg();

 
CREATE OR REPLACE FUNCTION m_product_org_post_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH
Contributor(s): 
**********************************************************************************************************************************************************/

    v_count numeric;
    v_orgfrom character varying;
    v_cur RECORD; 
BEGIN
  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') then
     -- Update Production BOMs
     update zspm_projecttaskbom set issuing_locator=new.m_locator_id,receiving_locator=new.m_locator_id where m_product_id=new.m_product_id 
            and c_projecttask_id in (select c_projecttask_id from c_projecttask where c_project_id is null)
            and issuing_locator in (select m_locator_id from m_locator l where m_warehouse_id in (select m_warehouse_id from m_locator where m_locator_id=new.m_locator_id));
     -- Update Worksteps
     if new.isproduction='Y' then
        update zssm_workstep_prp_v set issuing_locator=new.m_locator_id,receiving_locator=new.m_locator_id where m_product_id=new.m_product_id 
                and issuing_locator in (select m_locator_id from m_locator l where m_warehouse_id in (select m_warehouse_id from m_locator where m_locator_id=new.m_locator_id));
        -- Auto generate Productionplan, if applicable
        update m_product set updated=new.updated where m_product_id=new.m_product_id;
     end if;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


SELECT zsse_droptrigger('m_product_org_post_trg', 'm_product_org');

CREATE TRIGGER m_product_org_post_trg
  AFTER INSERT OR UPDATE
  ON m_product_org
  FOR EACH ROW
  EXECUTE PROCEDURE m_product_org_post_trg();  
  
CREATE OR REPLACE FUNCTION zssi_getNewProductValue(p_org character varying)
  RETURNS character varying AS
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

Ohne hochdrehen der Sequenz - Default Wert auf der Oberfläche

*****************************************************/
v_return               character varying:='';
BEGIN
  if c_getconfigoption('autoproductvaluesequence', p_org)='Y' then
     select Ad_Sequence_Doc('Product Value', p_org, 'N') into v_return;
  end if;
  RETURN v_return;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE  COST 100;
  
  
  
CREATE OR REPLACE FUNCTION m_product_value_trg()
  RETURNS trigger AS
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

Hochdrehen der Sequenz -Erst bei echtem Abspeichen

*****************************************************/
v_isincremented BOOLEAN:=false;
BEGIN
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF; 
    -- Find a free Product Value if Option Configured and a double value was entered
    IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
        IF c_getconfigoption('autoproductvaluesequence',new.ad_org_id)='Y' then
            IF (TG_OP = 'INSERT' and new.value is null) THEN
                select p_documentno into new.value from ad_sequence_doc('Product Value',new.ad_org_id,'N');
            END IF;
            WHILE (select count(*) from m_product where value=new.value and m_product_id!=new.m_product_id)>0 
            LOOP
                select p_documentno into new.value from ad_sequence_doc('Product Value',new.ad_org_id,'Y');
                v_isincremented:=true;
            END LOOP;
            IF (TG_OP = 'INSERT' and v_isincremented=false and  ad_sequence_doc('Product Value',new.ad_org_id,'N')=new.value) THEN
                perform ad_sequence_doc('Product Value',new.ad_org_id,'Y');
            END IF;
        end if;
        if instr(new.value,'|')>0 and c_getconfigoption('kombibarcode','0')='Y' then
            raise exception '%', '@invalidcharacter@'||': |';
        end if;
   END IF;
   
 -- # are not allowed in name and searchkey
 IF (NEW.name LIKE '%#%' OR NEW.value LIKE '%#%') THEN
    RAISE EXCEPTION '%', '@invalidcharacter@' || ': #';
 END IF;
   
RETURN NEW;
END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
select zsse_droptrigger('m_product_value_trg','m_product');

CREATE TRIGGER m_product_value_trg
  BEFORE INSERT OR UPDATE 
  ON m_product
  FOR EACH ROW
  EXECUTE PROCEDURE m_product_value_trg();


CREATE OR REPLACE VIEW c_bpartner_v AS 
 SELECT p.ad_client_id, p.ad_org_id, p.c_bpartner_id, p.value, p.name, p.referenceno, p.so_creditlimit - p.so_creditused AS so_creditavailable, p.so_creditlimit, p.so_creditused, p.iscustomer, p.isvendor, p.actuallifetimevalue AS revenue, c.name AS contact, c.phone, a.postal, a.city, c.email
   FROM c_bpartner p
   LEFT JOIN ad_user c ON p.c_bpartner_id::text = c.c_bpartner_id::text
   LEFT JOIN c_bpartner_location l ON p.c_bpartner_id::text = l.c_bpartner_id::text
   LEFT JOIN c_location a ON l.c_location_id::text = a.c_location_id::text;

   
CREATE OR REPLACE FUNCTION c_uom_conversion_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Second UOM must differ from 1st UOM
*****************************************************/
v_count                   numeric;
BEGIN
    if new.multiplyrate>0 then
        new.dividerate:=1/new.multiplyrate;
    end if;
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

SELECT zsse_droptrigger('c_uom_conversion_trg', 'c_uom_conversion');

CREATE TRIGGER c_uom_conversion_trg
  BEFORE INSERT OR UPDATE 
  ON c_uom_conversion FOR EACH ROW
  EXECUTE PROCEDURE c_uom_conversion_trg();
  
   
CREATE OR REPLACE FUNCTION m_product_po_uom_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Second UOM must differ from 1st UOM


TODO: Remove Trigger - Only temporyry deactivated field.

*****************************************************/
v_count                   numeric;
BEGIN
   if new.c_uom_id is not null then  
    select count(*) into v_count from m_product where m_product_id=new.m_product_id and c_uom_id=new.c_uom_id;
    if v_count>0 then
        RAISE EXCEPTION '%', '@SecondUomNotFirstUOM@';
    END IF; 
    select count(*) into v_count from m_product_uom where m_product_id=new.m_product_id and c_uom_id=new.c_uom_id;
    if v_count=0 then
        insert into m_product_uom(m_product_uom_id, ad_client_id, ad_org_id, createdby, updatedby, c_uom_id, m_product_id)
        values (get_uuid(),new.ad_client_id, new.ad_org_id, new.createdby, new.updatedby, new.c_uom_id, new.m_product_id);
    END IF; 
   end if;
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

SELECT zsse_droptrigger('m_product_po_uom_trg', 'm_product_po');
SELECT zsse_droptrigger('m_product_po_uom_trg', 'm_productprice');
SELECT zsse_droptrigger('m_product_po_uom_trg', 'm_offer_product');

CREATE TRIGGER  m_product_po_uom_trg
  BEFORE INSERT OR UPDATE 
  ON  m_product_po FOR EACH ROW
  EXECUTE PROCEDURE  m_product_po_uom_trg();
  
CREATE TRIGGER  m_product_po_uom_trg
  BEFORE INSERT OR UPDATE 
  ON  m_productprice FOR EACH ROW
  EXECUTE PROCEDURE  m_product_po_uom_trg();
  
CREATE TRIGGER  m_product_po_uom_trg
  BEFORE INSERT OR UPDATE 
  ON  m_offer_product FOR EACH ROW
  EXECUTE PROCEDURE  m_product_po_uom_trg();
  
  
CREATE OR REPLACE FUNCTION m_product_po_chk_restrictions_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
v_count                   numeric;
BEGIN

    select count(*) into v_count from m_product_po where m_product_id=new.m_product_id and c_bpartner_id=new.c_bpartner_id and
           case when new.c_uom_id is not null then c_uom_id=new.c_uom_id else c_uom_id is null end
           and  case when new.m_manufacturer_id is not null then m_manufacturer_id=new.m_manufacturer_id else m_manufacturer_id is null end
           and  case when new.manufacturernumber is not null then manufacturernumber=new.manufacturernumber else manufacturernumber is null end
           and m_product_po_id!=new.m_product_po_id;
    if v_count>0 then
        RAISE EXCEPTION '%', '@ProductUOMManufacturerUnique@';
    END IF; 
    if new.m_manufacturer_id is null and new.manufacturernumber is not null then
            raise exception'%','Herstellernummer ohne Hersteller geht halt nicht...';
    end if;
    
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
SELECT zsse_droptrigger('m_product_po_chk_restrictions_trg', 'm_product_po');  

CREATE TRIGGER  m_product_po_chk_restrictions_trg
  BEFORE INSERT OR UPDATE 
  ON  m_product_po FOR EACH ROW
  EXECUTE PROCEDURE  m_product_po_chk_restrictions_trg();  
  
  
CREATE OR REPLACE FUNCTION m_productprice_chk_restrictions_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
v_count                   numeric;
BEGIN

    select count(*) into v_count from m_productprice where m_product_id=new.m_product_id and m_pricelist_version_id=new.m_pricelist_version_id and
           case when new.c_uom_id is not null then c_uom_id=new.c_uom_id else c_uom_id is null end
           and m_productprice_id!=new.m_productprice_id;
    if v_count>0 then
        RAISE EXCEPTION '%', '@ProductUOMUnique@';
    END IF; 
    
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

SELECT zsse_droptrigger('m_productprice_chk_restrictions_trg', 'm_productprice');
  
CREATE TRIGGER  m_productprice_chk_restrictions_trg
  BEFORE INSERT OR UPDATE 
  ON  m_productprice FOR EACH ROW
  EXECUTE PROCEDURE  m_productprice_chk_restrictions_trg();  
  
CREATE OR REPLACE FUNCTION m_offer_product_chk_restrictions_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
v_count                   numeric;
v_cur record;
BEGIN

    select count(*) into v_count from m_offer_product where m_product_id=new.m_product_id and m_offer_id=new.m_offer_id and
           case when new.c_uom_id is not null then c_uom_id=new.c_uom_id else c_uom_id is null end 
           and  case when new.m_product_po_id is not null then m_product_po_id=new.m_product_po_id else m_product_po_id is null end
           and m_offer_product_id!=new.m_offer_product_id;
    if v_count>0 then
        RAISE EXCEPTION '%', '@ProductUOMUnique@';
    END IF; 
    if new.graterequal='Y' and new.lessequal='Y'  then 
        RAISE EXCEPTION '%', '@datanotlogic@';
    end if;
    -- Only numeric attributes
    if new.graterequal='Y' or new.lessequal='Y'  then 
       if (select count(*) from m_attributeinstance ai,m_attribute aa where aa.m_attribute_id= ai.m_attribute_id and ai.m_attributesetinstance_id=new.m_attributesetinstance_id and aa.isnumeric='N' and ai.value is not null)>0 then
               RAISE EXCEPTION '%', '@onlynumericattributesforthisfunction@';
       end if;
    end if;
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

SELECT zsse_droptrigger('m_offer_product_chk_restrictions_trg', 'm_offer_product');
  
CREATE TRIGGER  m_offer_product_chk_restrictions_trg
  BEFORE INSERT OR UPDATE 
  ON  m_offer_product FOR EACH ROW
  EXECUTE PROCEDURE  m_offer_product_chk_restrictions_trg();  
  
  
  
  
CREATE OR REPLACE FUNCTION ma_machine_type_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - On Insert. Only one user on employees and undefined partner
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  IF (TG_OP = 'UPDATE' ) THEN
    if new.name!=old.name then
        update ma_machine set machinetypename=new.name where ma_machine_type_id=new.ma_machine_type_id;
    end if;
  END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_DropTrigger ('ma_machine_type_trg','ma_machine_type');

CREATE TRIGGER ma_machine_type_trg
  after UPDATE
  ON ma_machine_type FOR EACH ROW
  EXECUTE PROCEDURE ma_machine_type_trg();

CREATE OR REPLACE FUNCTION ma_machine_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - On Insert. Only one user on employees and undefined partner
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  IF (TG_OP != 'DELETE' ) THEN
    new.machinetypename=(select name from ma_machine_type where ma_machine_type_id=new.ma_machine_type_id);   
  END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_DropTrigger ('ma_machine_trg','ma_machine');

CREATE TRIGGER ma_machine_trg
  before UPDATE or INSERT
  ON ma_machine FOR EACH ROW
  EXECUTE PROCEDURE ma_machine_trg();  
  
 
 
CREATE OR REPLACE FUNCTION zssi_isCategorySelectableinWindow(p_windowID character varying,p_categoryID varchar)
  RETURNS character varying AS
$BODY$ DECLARE 
v_test varchar;
BEGIN
  -- Test SElecrtable for Production in PCategory
  select c.isselectableinproduction into v_test from m_product_category c where c.m_product_category_id=p_categoryID;
  if coalesce(v_test,'Y')='N' then
    if p_windowID in (select ad_window_id from ad_window where ad_module_id in (select ad_module_id from ad_module where name in ('Projects','Serial Production'))) then
        return 'N';
    end if;
  end if;
  RETURN 'Y';
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE  COST 100;
     
CREATE OR REPLACE FUNCTION m_manufacturerleadtime_process (p_pinstance_id varchar)  RETURNS void AS
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
Part of Projects, 
Updates Projects, Tasks with actual 
Costs and Schedule Status
Direct call variant (overloaded)
*****************************************************/
v_message character varying:='OK - Process finished';
Cur_Parameter record;
v_manufacturer_id varchar;
v_leadtime numeric;
v_rating numeric;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Call the Proc
     FOR Cur_Parameter IN
          (SELECT para.*
           FROM ad_pinstance pi, ad_pinstance_Para para
           WHERE 1=1
            AND pi.ad_pinstance_ID = para.ad_pinstance_ID
            AND pi.ad_pinstance_ID = p_pinstance_ID
           ORDER BY para.SeqNo
          )
        LOOP        
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('m_manufacturer_id') ) THEN
            v_manufacturer_id := Cur_Parameter.p_string;
          END IF;
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('deliverytimePromised') ) THEN
            v_leadtime := Cur_Parameter.p_number;
          END IF;
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('qualityrating') ) THEN
            v_rating := Cur_Parameter.p_number;
          END IF;
        END LOOP; -- Get Parameter
        update m_product_po set deliverytime_Promised=coalesce(v_leadtime,deliverytime_Promised),qualityrating=coalesce(v_rating,qualityrating) where m_manufacturer_id=v_manufacturer_id;       
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
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




select zsse_DropFunction ('c_Bpartner_getFastEntryData');

CREATE OR REPLACE FUNCTION c_Bpartner_getFastEntryData(i_bpartner_id varchar,OUT p_org_id VARCHAR,
  OUT p_value VARCHAR, OUT p_name VARCHAR, OUT p_bp_group_id VARCHAR, OUT p_url VARCHAR, OUT p_salesrep_id VARCHAR,
  OUT p_LOCATION_ID varchar,OUT p_ADDRESS1 VARCHAR, OUT p_ADDRESS2 VARCHAR,OUT p_CITY varchar,OUT p_POSTAL varchar,OUT P_COUNTRY_ID varchar,OUT p_uidnumber varchar,OUT P_TAX_ID varchar,
  OUT p_LOCATION_ID2 varchar,OUT p_ADDRESS12 VARCHAR, OUT p_ADDRESS22 VARCHAR,OUT p_CITY2 varchar,OUT p_POSTAL2 varchar, OUT P_COUNTRY_ID2 varchar,
  OUT p_FIRSTNAME varchar,OUT p_LASTNAME VARCHAR, OUT p_TITLE VARCHAR,OUT p_GREETING_ID varchar,OUT p_EMAIL varchar,OUT p_PHONE varchar,OUT p_PHONE2 VARCHAR,
  OUT p_BANK_NAME varchar,OUT p_IBAN VARCHAR, OUT p_SWIFTCODE VARCHAR, OUT p_iscustomer VARCHAR,
  OUT p_isvendor VARCHAR,OUT p_isemployee VARCHAR, OUT p_paymentrule  VARCHAR,OUT p_payterm  VARCHAR,OUT p_incoterms VARCHAR
  ) RETURNS SETOF RECORD 
AS $BODY$

DECLARE


v_bplocid varchar;
v_bplocid2  varchar;
v_user varchar;
v_bank varchar;
BEGIN
 select ad_org_id,value,name,c_bp_group_id,url,salesrep_id,case when name='n/a' then 'Y' else iscustomer end as iscustomer,
        isvendor,isemployee,paymentrule,c_paymentterm_id, c_incoterms_id
        into p_org_id,p_value,p_name , p_bp_group_id, p_url, p_salesrep_id,p_iscustomer,p_isvendor,p_isemployee,p_paymentrule,p_payterm,p_incoterms
 from c_bpartner where c_bpartner_id=i_bpartner_id;
 select c_location_id,c_bpartner_location_id,uidnumber,c_tax_id into  p_LOCATION_ID,v_bplocid,p_uidnumber,P_TAX_ID from c_bpartner_location where c_bpartner_id=i_bpartner_id
        and isheadquarter='Y' limit 1;
        
 select ADDRESS1, ADDRESS2, CITY, POSTAL, C_COUNTRY_ID into p_ADDRESS1 , p_ADDRESS2 ,p_CITY,p_POSTAL , P_COUNTRY_ID   
        from c_location where c_location_id=p_LOCATION_ID;
        
 select c_location_id,c_bpartner_location_id into  p_LOCATION_ID2,v_bplocid2 from c_bpartner_location where c_bpartner_id=i_bpartner_id
        and isheadquarter='N' and isshipto='Y'  and isactive='Y' order by created limit 1;
 
 select ADDRESS1, ADDRESS2, CITY, POSTAL, C_COUNTRY_ID into p_ADDRESS12 , p_ADDRESS22 ,p_CITY2,p_POSTAL2 , P_COUNTRY_ID2   
        from c_location where c_location_id=p_LOCATION_ID2;
 
 select ad_user_id into v_user from ad_user where c_bpartner_id=i_bpartner_id order by created limit 1;
 select FIRSTNAME ,LASTNAME , TITLE, c_GREETING_ID ,EMAIL ,PHONE, PHONE2 into p_FIRSTNAME ,p_LASTNAME , p_TITLE, p_GREETING_ID ,p_EMAIL ,p_PHONE, p_PHONE2
        from ad_user where ad_user_id=v_user;
        
 select C_BP_BANKACCOUNT_ID into v_bank from C_BP_BANKACCOUNT where c_bpartner_id=i_bpartner_id order by created limit 1;
 select BANK_NAME,IBAN , SWIFTCODE  into p_BANK_NAME,p_IBAN , p_SWIFTCODE from C_BP_BANKACCOUNT where C_BP_BANKACCOUNT_ID=v_bank;
 
 
 RETURN NEXT;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_DropFunction ('c_Bpartner_updateFastEntryData');  
CREATE OR REPLACE FUNCTION c_Bpartner_updateFastEntryData(i_bpartner_id varchar,i_userid varchar,
  p_value VARCHAR, p_name VARCHAR, p_bp_group_id VARCHAR, p_url VARCHAR, p_salesrep_id VARCHAR,
  p_ADDRESS1 VARCHAR, p_ADDRESS2 VARCHAR,p_CITY varchar,p_POSTAL varchar,P_COUNTRY_ID varchar,p_uidnumber varchar,p_TAX_ID varchar,
  p_ADDRESS12 VARCHAR, p_ADDRESS22 VARCHAR,p_CITY2 varchar,p_POSTAL2 varchar, P_COUNTRY_ID2 varchar,
  p_FIRSTNAME varchar,p_LASTNAME VARCHAR, p_TITLE VARCHAR,p_GREETING_ID varchar,p_EMAIL varchar,p_PHONE varchar,p_PHONE2 VARCHAR,
  p_iscustomer VARCHAR, p_isvendor VARCHAR,p_isemployee VARCHAR, p_paymentrule  VARCHAR,p_payterm  VARCHAR, p_incoterms VARCHAR
  ) RETURNS VARCHAR
AS $BODY$

DECLARE
v_locid varchar;
v_locid2 varchar;
v_bplocid varchar;
v_bplocid2  varchar;
v_user varchar;
v_bank varchar;
v_org varchar;
v_client varchar;
v_ic varchar;
v_country varchar;
BEGIN
 
 select ad_org_id,ad_client_id into v_org,v_client from c_bpartner where c_bpartner_id=i_bpartner_id;
 if v_org is null then
    return 'NULL';
 end if;
 select c_location_id,c_bpartner_location_id into  v_locid,v_bplocid from c_bpartner_location where c_bpartner_id=i_bpartner_id and isheadquarter='Y' limit 1;
 select c_location_id,c_bpartner_location_id into  v_locid2,v_bplocid2 from c_bpartner_location where c_bpartner_id=i_bpartner_id 
        and isheadquarter='N' and isshipto='Y' order by created limit 1;
 select ad_user_id into v_user from ad_user where c_bpartner_id=i_bpartner_id order by created limit 1;

 
 -- Inserts where nothing exists
 if v_bplocid is null then
    v_bplocid:=get_uuid();
    insert into c_bpartner_location(C_BPARTNER_LOCATION_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, C_BPARTNER_ID)
    values (v_bplocid,v_client,v_org,i_userid,i_userid,i_bpartner_id);
 end if;
 if v_locid is null then
    v_locid:=get_uuid();
    insert into c_location(C_LOCATION_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, C_COUNTRY_ID)
    values (v_locid,v_client,v_org,i_userid,i_userid,P_COUNTRY_ID);
 end if;
 if v_bplocid2 is null and P_COUNTRY_ID2 is not null then
    v_bplocid2:=get_uuid();
    insert into c_bpartner_location(C_BPARTNER_LOCATION_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, C_BPARTNER_ID,name)
    values (v_bplocid2,v_client,v_org,i_userid,i_userid,i_bpartner_id,'n/a');
 end if;
 if v_locid2 is null and P_COUNTRY_ID2 is not null then
    v_locid2:=get_uuid();
    insert into c_location(C_LOCATION_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, C_COUNTRY_ID)
    values (v_locid2,v_client,v_org,i_userid,i_userid,P_COUNTRY_ID2);
 end if;
 if v_user is null and (p_FIRSTNAME is not null or p_LASTNAME is not null) then
    v_user:=get_uuid();
    insert into AD_USER(AD_USER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME, C_BPARTNER_ID)
    values (v_user,v_client,v_org,i_userid,i_userid,'N/A',i_bpartner_id);
 end if;
 
 -- Updates
 update c_bpartner set value=p_value,
        name=case when p_name='n/a' then coalesce(p_FIRSTNAME||' ','')||coalesce(p_LASTNAME,'') else p_name end,
        c_bp_group_id=p_bp_group_id, url=p_url,salesrep_id = p_salesrep_id, updated=now(),updatedby=i_userid,iscustomer=p_iscustomer,
        isemployee=p_isemployee,
        issalesrep = case when p_isemployee='Y' then 'Y' else 'N' end,
        isvendor=p_isvendor,
        paymentrule=p_paymentrule,
        c_paymentterm_id=p_payterm,
        c_incoterms_id=p_incoterms
        where c_bpartner_id=i_bpartner_id ;
 update c_bpartner_location set  c_location_id=v_locid,uidnumber=p_uidnumber, c_tax_id=p_TAX_ID,isbillto='Y',
                                 isshipto='Y',updated=now(),updatedby=i_userid where  c_bpartner_location_id=v_bplocid;
 update c_bpartner_location set  c_location_id=v_locid2,isshipto='Y',isbillto='N',updated=now(),updatedby=i_userid where  c_bpartner_location_id=v_bplocid2;
 update c_location set ADDRESS1=p_ADDRESS1,ADDRESS2= p_ADDRESS2 ,CITY=p_CITY,POSTAL=p_POSTAL ,c_COUNTRY_ID=P_COUNTRY_ID ,updated=now(),updatedby=i_userid 
        where c_location_id=v_locid;
 update c_location set ADDRESS1=p_ADDRESS12,ADDRESS2= p_ADDRESS22 ,CITY=p_CITY2,POSTAL=p_POSTAL2 ,c_COUNTRY_ID=P_COUNTRY_ID2 ,updated=now(),updatedby=i_userid 
        where c_location_id=v_locid2;
 update c_bpartner_location set uidnumber=p_uidnumber where c_bpartner_location_id=v_bplocid;
 update c_bpartner_location set updated=updated  where c_bpartner_location_id=v_bplocid2;
 if (p_FIRSTNAME is not null or p_LASTNAME is not null) then 
    update ad_user set isactive='Y',FIRSTNAME=p_FIRSTNAME,LASTNAME=p_LASTNAME, name=coalesce(p_FIRSTNAME||' ','')||coalesce(p_LASTNAME,''),TITLE=p_TITLE ,c_GREETING_ID=p_GREETING_ID,EMAIL=p_EMAIL,PHONE=p_PHONE ,
                    PHONE2=p_PHONE2,updated=now(),updatedby=i_userid 
        where ad_user_id=v_user;
 end if;
 
 RETURN 'OK';
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
select zsse_DropFunction ('c_Bpartner_updateFastEntryDataBank');  
CREATE OR REPLACE FUNCTION c_Bpartner_updateFastEntryDataBank(i_bpartner_id varchar,i_userid varchar,
  p_BANK_NAME varchar,p_IBAN VARCHAR, p_SWIFTCODE VARCHAR
  ) RETURNS VARCHAR
AS $BODY$

DECLARE

v_bank varchar;
v_org varchar;
v_client varchar;
v_ic varchar;
v_country varchar;
BEGIN
 
 select ad_org_id,ad_client_id into v_org,v_client from c_bpartner where c_bpartner_id=i_bpartner_id;
 if v_org is null then
    return 'NULL';
 end if;
 
 select C_BP_BANKACCOUNT_ID into v_bank from C_BP_BANKACCOUNT where c_bpartner_id=i_bpartner_id order by created limit 1;
 v_ic=substr(p_IBAN,1,2);
 select c_country_id into v_country from c_country where countrycode=v_ic;
 
 
 if v_bank is null and (p_IBAN is not null or p_BANK_NAME is not null or p_SWIFTCODE is not null) then
    v_bank:=get_uuid();
    insert into C_BP_BANKACCOUNT(C_BP_BANKACCOUNT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, C_BPARTNER_ID,BANK_NAME, IBAN, SHOWIBAN, SWIFTCODE,c_country_id)
    values (v_bank,v_client,v_org,i_userid,i_userid,i_bpartner_id,p_BANK_NAME,p_IBAN,'Y',p_SWIFTCODE,v_country);
 end if;
 
 -- Updates

 update c_bp_bankaccount set BANK_NAME=p_BANK_NAME,IBAN=p_IBAN , SWIFTCODE=p_SWIFTCODE,updated=now(),updatedby=i_userid,c_country_id=v_country
        where c_bp_bankaccount_id=v_bank;
 RETURN 'OK';
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
  
CREATE OR REPLACE FUNCTION m_attributevalue_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
    
    /*************************************************************************
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
    * Contributor(s):  Stefan Zimmermann, OpenZ, 2016.
    ************************************************************************/

  v_desc     VARCHAR(500); --OBTG:varchar2--
  v_desc_aux VARCHAR(500); --OBTG:varchar2--
  pos        INTEGER;
  --TYPE RECORD IS REFCURSOR;
  CurSetInstance RECORD;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  if instr(COALESCE(New.Name,'.'),'_')>0 or instr(COALESCE(New.value,'.'),'_')>0 then
    raise exception '%', '_ Not allowed';
  end if;
 
  IF COALESCE(New.Name,'.')!=COALESCE(Old.Name,'.') THEN
    UPDATE M_AttributeInstance
       SET Value = New.Name
     WHERE M_AttributeValue_ID = New.M_AttributeValue_ID;

    --Upate Attribute set instance descriptions...
  FOR CurSetInstance IN (select si.description, si.m_attributeset_id, i.m_attribute_id, si.M_AttributeSetInstance_ID
                          from m_attributeinstance i,
                               m_attributesetinstance si
                          where si.m_attributesetinstance_id = i.m_attributesetinstance_id
                          and i.m_attributevalue_id = New.M_AttributeValue_ID) LOOP
         select (case when isSerNo ='Y' then 1 else 0 end)+
                (case when isLot ='Y' then 1 else 0 end)+
                (case when isGuaranteeDate ='Y' then 1 else 0 end)+
                (select count(*)
                   from M_AttributeUse u1
                  where u1.M_AttributeSet_ID = u.M_AttributeSet_ID
                    and u1.seqno<u.seqno) +1
           into pos
           from M_AttributeSet s,
                M_AttributeUse u
          where u.M_Attribute_ID = CurSetInstance.M_Attribute_ID
          and s.M_AttributeSet_ID = CurSetInstance.M_AttributeSet_ID
          and s.m_attributeSet_id = u.m_attributeset_id;

      v_desc := '_'||CurSetInstance.description||'_';
      v_desc:=substr(v_desc,1, instr(v_desc,'_',1,pos))||new.Name||substr(v_desc,instr(v_desc,'_',1,pos+1));
      v_desc:=substr(v_desc,2,length(v_desc)-2);

      UPDATE M_AttributeSetInstance
         SET description = v_desc
       WHERE M_AttributeSetInstance_ID = CurSetInstance.M_AttributeSetInstance_ID;
    END LOOP;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

CREATE OR REPLACE FUNCTION m_attributevaluebef_trg() RETURNS trigger LANGUAGE plpgsql   AS $_$ 
DECLARE 
BEGIN
        IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
        END IF;
        if (select count(*) from m_attribute where isnumeric='Y' and m_attribute_id=new.m_attribute_id)>0 then
            new.value:=to_char(to_number(new.value));
        end if;
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;

select zsse_DropTrigger ('m_attributevaluebef_trg','m_attributevalue');  
CREATE TRIGGER m_attributevaluebef_trg
  BEFORE INSERT or UPDATE
  ON m_attributevalue
  FOR EACH ROW
  EXECUTE PROCEDURE m_attributevaluebef_trg();
 
 
CREATE OR REPLACE FUNCTION m_attributesetgetId(p_decription in varchar,p_attributeset_id in varchar) RETURNS varchar LANGUAGE plpgsql   AS $_$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************
Returns attributeset-Instance from description, if found , otherwise creates attributeset-Instance
*/
    v_instId varchar;
    v_i numeric:=0;
    v_attr varchar;
    v_cur record;
    v_listid varchar;
    v_attrinst varchar;
BEGIN
       SELECT m_attributesetinstance_id     into v_instId    FROM M_AttributeSetInstance         WHERE (upper(description) = upper(p_decription) OR ((description IS NULL) AND (p_decription IS NULL)))
        AND M_AttributeSet_ID = p_attributeset_id;
        if v_instId is not null then
            return v_instId;
        else
           select get_uuid() into v_instId;
            INSERT INTO M_ATTRIBUTESETINSTANCE (M_ATTRIBUTESETINSTANCE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, 
                            UPDATEDBY, M_ATTRIBUTESET_ID,description)     
            VALUES ( v_instId, 'C726FEC915A54A0995C568555DA5BB3C', '0', '0', '0', p_attributeset_id,p_decription);
           for v_cur in (select  regexp_split_to_table(p_decription,E'_') as part)
           LOOP
             if v_cur.part is not null and v_cur.part!='' then
                select m_attribute_id,seqno into v_attr,v_i from m_attributeuse where M_ATTRIBUTESET_ID=p_attributeset_id and seqno>v_i order by seqno limit 1;
                if (select islist from m_attribute where m_attribute_id=v_attr)='Y' then
                        select m_attributevalue_id into v_listid from  m_attributevalue where m_attribute_id=v_attr and name=v_cur.part;
                        if v_listid is null then 
                            raise exception '%','@noAttributeListValueFound@'||coalesce(v_cur.part,'NULL')||'#'||v_attr||'#'||v_i;
                        end if;
                        select m_attributeinstance_id into v_attrinst from m_attributeinstance where  m_attribute_id=v_attr and m_attributevalue_id=v_listid and M_ATTRIBUTESETINSTANCE_ID=v_instId;
                else
                        v_listid:=null;
                        select m_attributeinstance_id into v_attrinst from m_attributeinstance where  m_attribute_id=v_attr and  value=v_cur.part and M_ATTRIBUTESETINSTANCE_ID=v_instId;
                end if;
                if v_attrinst is null then
                        select get_uuid() into v_attrinst;
                        INSERT INTO M_ATTRIBUTEINSTANCE (M_ATTRIBUTEINSTANCE_ID, M_ATTRIBUTESETINSTANCE_ID, M_ATTRIBUTE_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY,UPDATEDBY, M_ATTRIBUTEVALUE_ID, VALUE) 
                        VALUES (v_attrinst,v_instId,v_attr, 'C726FEC915A54A0995C568555DA5BB3C', '0', '0', '0',v_listid,v_cur.part);
                end if;
             end if;
           END LOOP;
           return v_instId;
        end if;
END; $_$;
 
CREATE OR REPLACE FUNCTION m_attributesetgetInstanceValue( p_attributesetinstance_id in varchar,p_sequence in numeric) RETURNS varchar LANGUAGE plpgsql   AS $_$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************
Returns attribute value at sequence from attributeset-Instance
*/
    v_description varchar;
    v_i numeric:=1;
    v_attr varchar;
    v_cur record;
    v_listid varchar;
    v_attrinst varchar;
BEGIN
       SELECT description     into v_description    FROM M_AttributeSetInstance         WHERE M_AttributeSetInstance_id=p_attributesetinstance_id;
        if v_description is null then
            return v_description;
        else
           for v_cur in (select  regexp_split_to_table(v_description,E'_') as part)
           LOOP
             if v_i= p_sequence then 
                    return v_cur.part;
            end if;
            v_i:=v_i+1;
           END LOOP;
           return null;
        end if;
END; $_$;
 
CREATE OR REPLACE FUNCTION m_product_bomhistory_trg()  RETURNS trigger AS
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
   insert into m_product_bom_history(m_product_bom_history_id, line, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, m_productbom_id,bomqty,  bomtype ,
                                     description,constuctivemeasure,rawmaterial,deleted)
   values(get_uuid(),old.line, old.ad_client_id, old.ad_org_id, old.createdby, old.updatedby, old.m_product_id,old.m_productbom_id, old.bomqty,old.bomtype,
          old.description,old.constuctivemeasure,old.rawmaterial,v_isdel);
   IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;  
$BODY$ LANGUAGE 'plpgsql';

  
 select zsse_droptrigger('m_product_bomhistory_trg','m_product_bom'); 
  
  CREATE TRIGGER  m_product_bomhistory_trg
  BEFORE UPDATE OR DELETE
  ON  m_product_bom
  FOR EACH ROW
  EXECUTE PROCEDURE m_product_bomhistory_trg();
    

    
CREATE OR REPLACE FUNCTION c_valueequalsname_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH
Contributor(s): 
**********************************************************************************************************************************************************/
BEGIN
  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') then
     new.value:=new.name;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


SELECT zsse_droptrigger('ad_org_valueequalsname_trg', 'ad_org');

CREATE TRIGGER ad_org_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON ad_org
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
  
SELECT zsse_droptrigger('c_bp_group_valueequalsname_trg', 'c_bp_group');

CREATE TRIGGER c_bp_group_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON c_bp_group
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
  
SELECT zsse_droptrigger('c_paymentterm_valueequalsname_trg', 'c_paymentterm');

CREATE TRIGGER c_paymentterm_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON c_paymentterm
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
  
  
SELECT zsse_droptrigger('m_product_category_valueequalsname_trg', 'm_product_category');

CREATE TRIGGER m_product_category_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON m_product_category
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
  

SELECT zsse_droptrigger('c_campaign_valueequalsname_trg', 'c_campaign');

CREATE TRIGGER c_campaign_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON c_campaign
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
  
 

SELECT zsse_droptrigger('c_salesregion_valueequalsname_trg', 'c_salesregion');

CREATE TRIGGER c_salesregion_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON c_salesregion
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
  
  

SELECT zsse_droptrigger('m_warehouse_valueequalsname_trg', 'm_warehouse');

CREATE TRIGGER m_warehouse_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON m_warehouse
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
  
SELECT zsse_droptrigger('ma_machine_valueequalsname_trg', 'ma_machine');

CREATE TRIGGER ma_machine_valueequalsname_trg
  BEFORE INSERT OR UPDATE
  ON ma_machine
  FOR EACH ROW
  EXECUTE PROCEDURE c_valueequalsname_trg();  
     
  
    
