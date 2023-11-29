/**************************************************************************************************************************************+

BOM Implementation 

* Explode BOM's
* Checks

***************************************************************************************************************************************/
select zsse_dropfunction('zsmf_mproductbomexplode');
CREATE or replace FUNCTION zsmf_mproductbomexplode(assembly_in varchar,p_bomproductid out varchar,p_assemblyproductid out varchar,p_value out varchar,p_name out varchar,p_qty out numeric,p_poslevel out varchar) RETURNS setof record
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2021 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Explodes a complete BOM

*****************************************************/
DECLARE
-- Simple Types
v_cur  RECORD;

BEGIN
   FOR v_cur in (WITH RECURSIVE temp1 (m_productbom_id, m_product_id, bomqty) AS (
                    SELECT m_product_bom.m_productbom_id, m_product_bom.m_product_id, m_product_bom.bomqty,'1-'|| lpad(to_char(m_product_bom.line),5,'0') as poslevel
                        FROM m_product_bom WHERE m_product_bom.m_product_id=assembly_in
                    union
                    select T2.m_productbom_id, T2.m_product_id, T2.bomqty,temp1.POSLEVEL ||'-'|| lpad(to_char(T2.line),5,'0') as poslevel
                        FROM m_product_bom T2 INNER JOIN temp1 ON temp1.m_productbom_id=T2.m_product_id)
                select temp1.m_productbom_id as BOMPRODUCTID, temp1.m_product_id as ASSEMBLYID,
                m_product.value as value,
                m_product.name as name,
                temp1.bomqty as bomqty,
                temp1.poslevel
                from temp1,m_product where m_product.m_product_id=temp1.m_productbom_id)
    LOOP
      p_bomproductid:=v_cur.BOMPRODUCTID;
      p_assemblyproductid:=v_cur.ASSEMBLYID;
      p_value:=v_cur.value;
      p_name:=v_cur.name;
      p_qty:=v_cur.bomqty;
      p_poslevel:=v_cur.poslevel;
      RETURN NEXT; 
   END LOOP; 
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION zsmf_product_bom_trg()
  RETURNS trigger AS
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
Part of Manufacturing
BOM
Reset Verification flag of parent
BOM-Modifications only on a not ready4production Product 
Set Business Partner and Value of Product
Always Trigger Verification, if any changes are made
*****************************************************/
v_issetready character varying;
v_value  character varying;
v_bpartner     character varying;     
v_type     character varying;    
v_ntype     character varying;
v_set     character varying;
v_setofbom     character varying;
v_cur record;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  IF(TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
      if new.bomqty<0 then
          RAISE EXCEPTION '%', 'Menge muss > 0 sein!';
      end if;
      select substr(name,1,40),c_bpartner_id into v_value,v_bpartner from m_product where m_product.m_product_id=NEW.M_ProductBOM_ID;
      new.product_value:=v_value;
      new.c_bpartner_id:=v_bpartner;
      select typeofproduct,issetitem into v_type,v_setofbom from m_product where m_product_id=NEW.M_Product_ID;
      select typeofproduct into v_ntype  from m_product where m_product_id=NEW.M_ProductBOM_ID;
      select issetitem into v_set  from m_product where m_product_id=NEW.M_ProductBOM_ID;
      -- Sub-Assemblys may not contain other assemblys
      if (v_type='UA' and v_ntype in ('SA','AS'))  then
           RAISE EXCEPTION '%', '@zsmf_SubAssemblysMayNotContainOtherAssemblys@';
      end if;
      if v_set='Y' then
           RAISE EXCEPTION '%', '@SetItemsMayNotBePartOfBOM@';
      end if;
      if v_setofbom='Y' and (select isserialtracking||isbatchtracking from m_product where m_product_id=NEW.M_ProductBOM_ID)!='NN' then
        RAISE EXCEPTION '%', '@SerialsmayNotBePartOfSets@';
      end if;
  end if;
  IF(TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
      select setready4production into v_issetready from m_product where m_product_id=new.m_product_id;
      if v_issetready='Y' then
          RAISE EXCEPTION '%', '@zsmf_NoModificationsOnReadyProductBOM@';
      -- DEPRECATED else
          --  Always Trigger Verification, if any changes are made
          -- Verification will build a new bomtree
          --UPDATE M_Product SET IsVerified='N' WHERE M_Product_ID=new.M_Product_ID AND IsVerified='Y';
          -- Update all dependents BOMs
          --for v_cur in (select distinct m_product_id from m_product_bom where  m_productbom_id=new.m_product_id and  m_product_id!=new.m_product_id)
          --LOOP
          --  UPDATE M_Product SET IsVerified='N' WHERE M_Product_ID=v_cur.m_product_id AND IsVerified='Y';
          --END LOOP;
      end if;
 END IF;
 IF TG_OP = 'DELETE' THEN 
   select setready4production into v_issetready from m_product where m_product_id=old.m_product_id;
   if v_issetready='Y' then
          RAISE EXCEPTION '%', '@zsmf_NoModificationsOnReadyProductBOM@';
   end if;
   RETURN OLD; 
 ELSE 
   RETURN NEW; 
 END IF; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
  
  /**************************************************************************************************************************************+


ELR BOM HELPER FUNCTIONS - For - BOM - Reports




***************************************************************************************************************************************/

CREATE OR REPLACE FUNCTION elr_getchildcount(p_product_id character varying)
  RETURNS character varying AS
$BODY$DECLARE
v_return character varying;
BEGIN
      select count(*) into v_return from m_product_bom where m_product_id=p_product_id;
	if v_return!='0' then v_return:='11'; end if;
        if v_return='0' then v_return:='00'; end if;
RETURN v_return;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
select zsse_dropfunction('elr_getproductuomdiv');
CREATE OR REPLACE FUNCTION elr_getproductuomdiv(v_product varchar,p_orgid varchar)
  RETURNS numeric AS $BODY$
DECLARE
  v_return numeric;
BEGIN
      -- UOM Umrechnung bei EK-Preisen in BOM Report
      select uom.dividerate into v_return from c_uom_conversion uom, m_product_uom p where uom.c_uom_id = p.c_uom_id and p.m_product_id=v_product;
      -- Bei Baugruppen, Endprod. - Wenn Produziert wird, ist EK nicht anzusetzen
      if (select count(*) from m_product where m_product_id=v_product and typeofproduct in ('AS','CD') and production='Y')>0 then
        return null;
      end if;
      if v_return is null then 
          return 1;
      end if;
RETURN v_return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
 
 
CREATE OR REPLACE FUNCTION elr_getlevelmultiplier(v_product varchar,v_path varchar,v_qty numeric)
  RETURNS numeric AS
$BODY$

DECLARE
v_calc numeric;
BEGIN
    if ( select count(*) from m_product where m_product_id=v_product and typeofproduct in ('AS','CD') and production='Y')>0 then
        select bomqty into v_calc from bomcalc where v_path = bompath;
        if v_calc is null and v_qty>1 then
            insert into bomcalc (bompath,bomqty) values (v_path,v_qty);
        end if;
        return 1;
    else
        select sum(bomqty) into v_calc from bomcalc where v_path like bompath||'%' ;
    end if;
    return coalesce(v_calc,1);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION elr_initbomcalc() RETURNS numeric AS $BODY$
DECLARE
BEGIN
    perform zsse_droptable ('bomcalc');
    create temporary table bomcalc(
        bompath character varying(2000),
        bomqty numeric
    ) ON COMMIT DROP;
RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
 
 

/**************************************************************************************************************************************+


Product Enhancements for Manufacturing Implementation 

* Ready for Production Process
* Checks on Requirements for Product
* SET setready4production: 

- Product Read Only Attributes (in GUI)
- Attachments not modifyable
- Copy Product - Process available
- Copy Attachments to Production Order




***************************************************************************************************************************************/
 
CREATE OR REPLACE FUNCTION zsmf_setready4production(p_PInstance_ID character varying) RETURNS void
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
Part of Manufacturing
Set a Product ready for Production
*****************************************************/
v_message character varying:='Success';
v_Record_ID  character varying;
v_User    character varying;
v_bom    character varying;
v_bomvery    character varying;
v_locator    character varying;
v_count numeric;
BEGIN 
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    -- Restrictions
    select isbom,isverified,coalesce(m_locator_id,'N') into v_bom,v_bomvery,v_locator from m_product where m_product_id=v_Record_ID;
    if (v_bomvery='N') then
        RAISE EXCEPTION '%', '@zsmf_NoBomVeryfieNoReady4Prod@';
    end if;
    if v_locator='N' then
       RAISE EXCEPTION '%', '@zsmf_MustHaveLocatorNoReady4Prod@';
    end if;
    -- Not ready for Prod. Items in BOM?
    select count(*) into v_count from m_product where  m_product.setready4production='N' and m_product.typeofproduct in ('CD','SA','AS','UA') and m_product_id in (select m_productbom_id from m_product_bom where m_product_id =v_Record_ID);
    if v_count>0 then
       RAISE EXCEPTION '%', '@zsmf_BOMHasAssemlyNotReady4Prod@';
    end if;
    -- Corrections on BOM, If meanwhile Sub-Assemblys have been modified..-> Fire Trigger - Trigger will build a new bomtree
    UPDATE m_product_bom set updated=now() where m_product_bom_id=(select max(m_product_bom_id) from m_product_bom where M_Product_ID=v_Record_ID);
    -- Set it ready..
    update m_product set setready4production='Y',isverified='Y' where m_product_id=v_Record_ID;
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




CREATE OR REPLACE FUNCTION zsmf_product_trg()
  RETURNS trigger AS
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
Part of Manufacturing
BOM
  a ready4production Product must have a locator 
*****************************************************/
   v_isready character varying;
   v_cur RECORD;     
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  IF(TG_OP = 'UPDATE') THEN
      If new.m_locator_id is null and (new.setready4production='Y' or new.issetitem='Y') then 
        RAISE EXCEPTION '%', '@zsmf_AReadyProductBOMmustHaveLocator@';
      end if;
      if new.typeofproduct in ('CD','SA','AS','UA') and coalesce(new.cutoff,0)!=0 then
         RAISE EXCEPTION '%', '@zsmf_CutoffOnlyOnStandardProducts@';
      end if;
      if (new.isstocked='N' or new.producttype='S') and ((select count(*) from m_storage_detail where m_product_id=new.m_product_id and QtyOnHand!=0)>0) then
         RAISE EXCEPTION '%', '@CannotChangeStockedProduct@';
      end if;
      If old.typeofproduct not in ('CD','SA','AS','UA') and new.typeofproduct in ('CD','AS','SA','UA') then
         for v_cur in (select m_product_id  from m_product_bom where m_productbom_id= new.m_product_id)
         LOOP
           select setready4production into v_isready from m_product where m_product_id=v_cur.m_product_id;
           if v_isready='Y' then
              RAISE EXCEPTION '%', '@zsmf_CannotChangeTypeIsUsedInProd@';
           end if;
         END LOOP;
      end if;
      if coalesce(old.m_locator_id,'')!=new.m_locator_id and new.m_locator_id is not null and (select count(*) from m_product_org where m_product_id=new.m_product_id)=0 then
        -- Update Production BOMs
        update zspm_projecttaskbom set issuing_locator=new.m_locator_id,receiving_locator=new.m_locator_id where m_product_id=new.m_product_id 
            and c_projecttask_id in (select c_projecttask_id from c_projecttask where c_project_id is null);
        -- Update Worksteps
        if new.production='Y' then
            update zssm_workstep_prp_v set issuing_locator=new.m_locator_id,receiving_locator=new.m_locator_id where m_product_id=new.m_product_id;
      end if;
     end if;
  end if;
  RETURN NEW;  
END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 


CREATE OR REPLACE FUNCTION zsmf_c_file_trg()
  RETURNS trigger AS
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
Part of Manufacturing
BOM
A ready4production Product must not be modiofied
Attachments must be preserved. 
*****************************************************/
v_issetready character varying:='N';      
v_message character varying;
v_suffix varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
   --Get Message with correct Language
    select zssi_getText('zsmf_NoModificationsOnReadyProduct','de_DE') into v_message;
   if TG_OP = 'DELETE' THEN 
         if  old.ad_table_id='208' then
             select setready4production into v_issetready from m_product where m_product_id=old.ad_record_id;
         end if;
   else
         if  new.ad_table_id='208' then
             select setready4production into v_issetready from m_product where m_product_id=new.ad_record_id;
         end if;
   end if;  
   if v_issetready='Y' then
             RAISE EXCEPTION '%', v_message;
   end if;
   -- 21-07 - Map to Correct Datatype automatically
   IF TG_OP = 'INSERT' THEN 
     v_suffix:=coalesce(lower(substr(new.name,length(new.name)-3,4)),'');
     if instr(v_suffix,'.')=0 then
        v_suffix:=coalesce(lower(substr(new.name,length(new.name)-4,5)),'');
     end if;
     if v_suffix='.ods' then
        new.c_datatype_id:='06594D68EF324AAE8794E5E2BFF1AD3B'; -- OpenOffice
     end if;
     if v_suffix='.txt' then
        new.c_datatype_id:='100';
     end if;
     if v_suffix='.xls' or v_suffix='.xlsx' then
        new.c_datatype_id:='101';
     end if;
     if v_suffix='.pdf' then
        new.c_datatype_id:='103';
     end if;
     if v_suffix='.doc' or v_suffix='.docx' then
        new.c_datatype_id:='104';
     end if;
     if v_suffix in ('.ppt','.pptx','pptm') then
        new.c_datatype_id:='105';
     end if;
     if v_suffix='.zip' then
        new.c_datatype_id:='107';
     end if;
     if v_suffix in ('.jpg','.jpeg') then
        new.c_datatype_id:='108';
     end if;
     if v_suffix in ('.gif','.giff') then
        new.c_datatype_id:='109';
     end if;
     if v_suffix='.odt' then
        new.c_datatype_id:='5EDEA8C0B417462B9BC11283AE0BB3A5';
     end if;
     if v_suffix in ('.tif','.tiff') then
        new.c_datatype_id:='800000';
     end if;
     if v_suffix='.rtf' then
        new.c_datatype_id:='800003';
     end if;
     if v_suffix='.odp' then
        new.c_datatype_id:='946957127C74449B8C62319189F9DED6';
     end if;
     if v_suffix='.dwg' then
        new.c_datatype_id:='9A4AF5CEEBB2425C8C2571F34AD1A6ED';
     end if;
     if v_suffix='.png' then
        new.c_datatype_id:='B97C7AA16C5443BCAC95A3FE9CEF3B76';
     end if;
   END IF;
   IF TG_OP = 'DELETE' THEN 
      RETURN OLD; 
   ELSE 
      RETURN NEW; 
   END IF; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100; 


CREATE OR REPLACE FUNCTION zsmf_copyproduct (
  p_product_id varchar,
  p_newkey varchar,
  p_newname varchar,
  p_user varchar,
  v_uid varchar
)
RETURNS varchar AS
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
***************************************************************************************************************************************************
Part of Manufacturing
Copy a Product
*****************************************************/

  v_count                 NUMERIC;
  v_now                   TIMESTAMP := now();

  v_message               VARCHAR := '';
  v_link                  VARCHAR;
 -- record buffer declaration
  v_product               m_product%ROWTYPE;
  v_product_trl           m_product_trl%ROWTYPE;
  v_product_trl_2         m_product_trl%ROWTYPE;
  v_product_bom           m_product_bom%ROWTYPE; -- 2 Bill of Materials / Stueckliste
  v_substitute            m_substitute%ROWTYPE; -- 3 Substitute / Ersatzartikel
  v_product_po            m_product_po%ROWTYPE; -- 4 Purchasing / Einkauf
  -- Trigger zssi_product_trg: INSERT m_costing / Kalkulation
  -- Trigger m_product_trg:    INSERT / UPDATE m_product_trl
  v_product_org           m_product_org%ROWTYPE; -- 5 Org Specific / Lagerplanung
  v_productprice          m_productprice%ROWTYPE; -- 6 Price / Preis
  v_product_uom           m_product_uom%ROWTYPE; -- UOM / Einheit
  v_product_acct          m_product_acct%ROWTYPE; -- Accouting / Kontierung

BEGIN
  IF ( isempty(p_product_id) ) THEN
    RAISE EXCEPTION '% % % ',  '@InvalidArguments@', 'p_product_id', COALESCE(p_product_id, ''); -- GOTO EXCEPTION
  END IF;
  IF ( isempty(p_newkey) and (select c_getconfigoption('autoproductvaluesequence',(select ad_org_id from m_product where m_product_id=p_product_id)))='N') THEN
    RAISE EXCEPTION '% % % ',  '@InvalidArguments@', 'p_newkey', COALESCE(p_newkey	, ''); -- GOTO EXCEPTION
  END IF;
  if (isempty(p_newkey) and (select c_getconfigoption('autoproductvaluesequence',(select ad_org_id from m_product where m_product_id=p_product_id)))='Y') THEN
    select zssi_getNewProductValue((select ad_org_id from m_product where m_product_id=p_product_id)) into p_newkey;
  END IF;
  IF ( isempty(p_newname) ) THEN
    RAISE EXCEPTION '% % % ', '@InvalidArguments@', 'p_newname', COALESCE(p_newname, ''); -- GOTO EXCEPTION
  END IF;
  IF ( isempty(v_uid) ) THEN
    RAISE EXCEPTION '% % % ',  '@InvalidArguments@', 'v_uid', COALESCE(v_uid, ''); -- GOTO EXCEPTION
  END IF;

  select count(*) into v_count from m_product where m_product_id = p_product_id;
  if (v_count > 0) then
    select count(*) into v_count from m_product where value=p_newkey;
    if (v_count > 0) then
      RAISE EXCEPTION '%', '@zsse_SearchKeyOrNameTwice@' || ' ' || p_newkey || ', ' || p_newname; -- @zsse_DatasetTwice@
    end if;

 -- part 1.A/09: m_product
    SELECT * INTO v_product FROM m_product WHERE m_product_id = p_product_id; -- read record into rowtype-buffer
    IF isempty(v_product.m_product_id) THEN
      RAISE EXCEPTION '%', '@ProductIdNotFound@'; -- GOTO EXCEPTION
    END IF;
    -- Unique changes before insert, all other changes after inserting, because of triggers
    v_product.m_product_id := v_uid;
    v_product.created := v_now;
    v_product.createdby := p_user;
    v_product.updated := v_now;
    v_product.updatedby := p_user;
    v_product.value := p_newkey; -- Search Key / unique name required
    v_product.name := p_newname;
    v_product.isVerified := 'N';          -- reset
    v_product.setReady4Production := 'N'; -- reset relevant to zsmf_product_bom_trg()

   -- insert via %rowtype
    INSERT INTO m_product SELECT v_product.*; -- %rowtype / (trg: INSERT INTO m_costing, trg: INSERT INTO m_product_trl)

-- part 1.B/09: m_product_trl / Uebersetzung

    FOR v_product_trl IN (SELECT * FROM m_product_trl WHERE m_product_trl.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_product_trl.m_product_id := v_uid;
      v_product_trl.created := v_now;
      v_product_trl.createdby := p_user;
      v_product_trl.updated := v_now;
      v_product_trl.updatedby := p_user;

     -- a: add i.e chinese, if language is not system-language and translation not inserted by trigger
      IF (NOT EXISTS
        (SELECT 1 FROM m_product_trl trl
         WHERE trl.m_product_id = v_product_trl.m_product_id
           AND trl.ad_language = v_product_trl.ad_language)) THEN

        v_product_trl.m_product_trl_id := get_uuid();
        INSERT INTO m_product_trl SELECT v_product_trl.*; -- %rowtype
      ELSE
     -- b: update generated translations inserted by trigger with original translations
        UPDATE m_product_trl SET
              name = v_product_trl.name,
              documentnote = v_product_trl.documentnote,
              description = v_product_trl.description
        WHERE
              m_product_trl.m_product_id = v_uid
          AND m_product_trl.ad_language = v_product_trl.ad_language; -- Systemsprache
      END IF;
    END LOOP;

-- part 2/09: m_product_bom / Stueckliste
    FOR v_product_bom IN (SELECT * FROM m_product_bom WHERE m_product_bom.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_product_bom.m_product_bom_id := get_uuid();
      v_product_bom.m_product_id := v_uid;
      v_product_bom.created := v_now;
      v_product_bom.createdby := p_user;
      v_product_bom.updated := v_now;
      v_product_bom.updatedby := p_user;
      INSERT INTO m_product_bom SELECT v_product_bom.*; -- %rowtype
    END LOOP;

-- part 3/09: Substitute / Ersatzartikel
    FOR v_substitute IN (SELECT * FROM m_substitute WHERE m_substitute.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_substitute.m_substitute_id := get_uuid();
      v_substitute.m_product_id := v_uid;
      v_substitute.created := v_now;
      v_substitute.createdby := p_user;
      v_substitute.updated := v_now;
      v_substitute.updatedby := p_user;
      INSERT INTO m_substitute SELECT v_substitute.*; -- %rowtype
    END LOOP;

-- part 7/09: UOM / Einheit
    FOR v_product_uom IN (SELECT * FROM m_product_uom WHERE m_product_uom.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_product_uom.m_product_uom_id := get_uuid();
      v_product_uom.m_product_id := v_uid;
      v_product_uom.created := v_now;
      v_product_uom.createdby := p_user;
      v_product_uom.updated := v_now;
      v_product_uom.updatedby := p_user;
      INSERT INTO m_product_uom SELECT v_product_uom.*; -- %rowtype
    END LOOP;    
    
-- part 4/09: Purchasing / Einkauf
    FOR v_product_po IN (SELECT * FROM m_product_po WHERE m_product_po.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_product_po.m_product_po_id := get_uuid();
      v_product_po.m_product_id := v_uid;
      v_product_po.created := v_now;
      v_product_po.createdby := p_user;
      v_product_po.updated := v_now;
      v_product_po.updatedby := p_user;
      INSERT INTO m_product_po SELECT v_product_po.*; -- %rowtype / (trg: update m_product set c_bpartner_id=v_vendor, vendorproductno=v_vproductno)
    END LOOP;

-- part 5/09: Org Specific / Lagerplanung
    FOR v_product_org IN (SELECT * FROM m_product_org WHERE m_product_org.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_product_org.m_product_org_id := get_uuid();
      v_product_org.m_product_id := v_uid;
      v_product_org.created := v_now;
      v_product_org.createdby := p_user;
      v_product_org.updated := v_now;
      v_product_org.updatedby := p_user;
      INSERT INTO m_product_org SELECT v_product_org.*; -- %rowtype
    END LOOP;

-- part 6/09: Price / Preis
    FOR v_productprice IN (SELECT * FROM m_productprice WHERE m_productprice.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_productprice.m_productprice_id := get_uuid();
      v_productprice.m_product_id := v_uid;
      v_productprice.created := v_now;
      v_productprice.createdby := p_user;
      v_productprice.updated := v_now;
      v_productprice.updatedby := p_user;
      INSERT INTO m_productprice SELECT v_productprice.*; -- %rowtype / UNIQUE (m_pricelist_version_id, m_product_id)
    END LOOP;

-- part 8/09: Accouting / Kontierung
    FOR v_product_acct IN (SELECT * FROM m_product_acct WHERE m_product_acct.m_product_id = p_product_id) -- %rowtype-buffer;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_product_acct.m_product_acct_id := get_uuid();
      v_product_acct.m_product_id := v_uid;
      v_product_acct.created := v_now;
      v_product_acct.createdby := p_user;
      v_product_acct.updated := v_now;
      v_product_acct.updatedby := p_user;
      INSERT INTO m_product_acct SELECT v_product_acct.*; -- %rowtype
    END LOOP;

 -- part 9/09: finally update for inserted record / excecute update-trigger: UPDATE m_product_trl SET name = new.name
    UPDATE m_product SET buttonCopyItem = 'Y' WHERE m_product.m_product_id = v_uid; -- set button as used, just for documentation
 -- enhance return-parameter with link to copied record
    v_message = '@zsse_SuccessfullCopyProduct@' || ': ' || p_newname; -- vgl. ad_message
    v_link := (SELECT zsse_htmldirectlink('../Product/Product_Relation.html', 'document.frmMain.inpmProductId', v_uid, p_newname));
    v_message := v_message  || '</br>' || v_link;
  ELSE
     RAISE EXCEPTION '%', '@zsse_DataNotExists@';
  END if;
  ---- <<FINISH_PROCESS>>
  --  Update AD_PInstance
  RAISE NOTICE '%','Copy Product - Finished ok: ' || p_newname ;
  v_message:=v_message||zsmf_copyproductionplanfromproduct(p_product_id, v_uid, p_user);
  RETURN 'SUCCESS' || ' ' || v_message;
EXCEPTION
    WHEN OTHERS then
       RETURN SQLERRM;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsmf_copyproductfiles(p_fromproduct_id character varying, p_toproductid character varying, p_user character varying) RETURNS character varying
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
Copy a Product - File Entrys in C_File
*****************************************************/

v_count numeric;
BEGIN 
    select count(*) into v_count from m_product where m_product_id=p_fromproduct_id;
    if v_count>0 then
          insert into c_file (C_FILE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, NAME, C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID, AD_RECORD_ID)
                 select get_uuid(),AD_CLIENT_ID,AD_ORG_ID, ISACTIVE, now(),p_user,now(),p_user,NAME,C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID,p_toproductid
                 from c_file where AD_RECORD_ID=p_fromproduct_id;
    else
       RAISE EXCEPTION '%', '@zsse_DataNotExists@';
    end if;
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Copy Product - Files Finished';
    return 'SUCCESS';
EXCEPTION
    WHEN OTHERS then
       return SQLERRM;        
END;
$_$  LANGUAGE 'plpgsql';
     
CREATE OR REPLACE FUNCTION zsmf_copyDocsToProdOrder(p_pinstance_id character varying, p_dirin OUT varchar,p_dirout OUT varchar, p_filename OUT character varying) RETURNS setof record
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2021 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Copy Attachments to Production Order
*****************************************************/
v_user varchar;
v_org  varchar;
v_client varchar;
v_count numeric;
v_i numeric:=1;
v_attributeset varchar;
v_attributevalue varchar;
v_cur record;
v_cur2 record;
v_cur3 record;
BEGIN 
    select createdby,ad_org_id,ad_client_id into v_user,v_org,v_client from zssm_productionrun where pinstance=p_pinstance_id;
    if c_getconfigoption('copydocstoprodorder',v_org)='Y' then
        for v_cur in (select * from zssm_productionrun where pinstance=p_pinstance_id and c_project_id is not null)
        LOOP
            v_count:=10;
            --Product Attachments 208
            if v_cur.m_product_id is not null then
                for v_cur2 in (select * from c_file where AD_TABLE_ID='208' and AD_RECORD_ID=v_cur.m_product_id and ISACTIVE='Y' order by SEQNO)
                LOOP
                    insert into c_file (C_FILE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, NAME, C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID, AD_RECORD_ID)
                    values (get_uuid(),v_client,v_org, v_cur2.ISACTIVE, now(),v_user,now(),v_user,v_cur2.NAME,v_cur2.C_DATATYPE_ID, v_count, v_cur2.TEXT, '32854A6CD107446F88172D884020C26E',v_cur.c_project_id);
                    p_dirin:='208-'||v_cur2.AD_RECORD_ID||'/';
                    p_filename:=v_cur2.NAME;
                    p_dirout:='32854A6CD107446F88172D884020C26E-'||v_cur.c_project_id||'/';
                    v_count:=v_count+10;
                    return next;
                END LOOP;
            end if;
            --Attribute Attachments 558
            if v_cur.m_attributesetinstance_id is not null then
                select m_attributeset_id into v_attributeset from m_attributesetinstance where m_attributesetinstance_id=v_cur.m_attributesetinstance_id;
                for v_cur3 in (select m_attribute_id  from m_attributeuse where m_attributeset_id=v_attributeset order by seqno)
                LOOP
                    select  m_attributevalue_id into v_attributevalue from m_attributevalue where m_attribute_id=v_cur3.m_attribute_id and name=m_attributesetgetInstanceValue(v_cur.m_attributesetinstance_id,v_i);
                    v_i:=v_i+1;
                    for v_cur2 in (select * from c_file where AD_TABLE_ID='558' and AD_RECORD_ID=v_attributevalue and ISACTIVE='Y' order by SEQNO)
                    LOOP
                        insert into c_file (C_FILE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, NAME, C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID, AD_RECORD_ID)
                        values (get_uuid(),v_client,v_org, v_cur2.ISACTIVE, now(),v_user,now(),v_user,v_cur2.NAME,v_cur2.C_DATATYPE_ID, v_count, v_cur2.TEXT, '32854A6CD107446F88172D884020C26E',v_cur.c_project_id);
                        p_dirin:='558-'||v_cur2.AD_RECORD_ID||'/';
                        p_filename:=v_cur2.NAME;
                        p_dirout:='32854A6CD107446F88172D884020C26E-'||v_cur.c_project_id||'/';
                        v_count:=v_count+10;
                        return next;
                    END LOOP; 
                END LOOP;
            end if;
            -- Base Workstep Attachments 530C8BFD91D14C319EFC04813849A4A0
            if v_cur.productionplan_id is not null then
                for v_cur3 in (select c_projecttask_id from zssm_productionplan_task_v where zssm_productionplan_v_id=v_cur.productionplan_id)
                LOOP
                    for v_cur2 in (select * from c_file where AD_TABLE_ID='530C8BFD91D14C319EFC04813849A4A0' and AD_RECORD_ID=v_cur3.c_projecttask_id and ISACTIVE='Y' order by SEQNO)
                    LOOP
                        insert into c_file (C_FILE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, NAME, C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID, AD_RECORD_ID)
                        values (get_uuid(),v_client,v_org, v_cur2.ISACTIVE, now(),v_user,now(),v_user,v_cur2.NAME,v_cur2.C_DATATYPE_ID, v_count, v_cur2.TEXT, '32854A6CD107446F88172D884020C26E',v_cur.c_project_id);
                        p_dirin:='530C8BFD91D14C319EFC04813849A4A0-'||v_cur2.AD_RECORD_ID||'/';
                        p_filename:=v_cur2.NAME;
                        p_dirout:='32854A6CD107446F88172D884020C26E-'||v_cur.c_project_id||'/';
                        v_count:=v_count+10;
                        return next;
                    END LOOP; 
                END LOOP;
            end if;
        END LOOP;
    end if;
END;
$_$  LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION zsmf_copyproductionplanfromproduct(p_fromproduct_id character varying, p_toproductid character varying, p_user character varying) RETURNS character varying
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Copy a Product - File Entrys in C_File
*****************************************************/
v_now timestamp without time zone;
v_count numeric;
v_cur_prj c_project%ROWTYPE;
v_cur RECORD;
v_cur_tasktab zssm_productionplan_task%ROWTYPE;
v_cur_pt c_projecttask%ROWTYPE;
v_cur_hr zspm_ptaskhrplan%ROWTYPE;
v_cur_ma zspm_ptaskmachineplan%ROWTYPE;
v_cur_td zssm_Ptasktechdoc%ROWTYPE;
v_cur_dep zssm_productionplan_taskdep%ROWTYPE;
v_cur_bom zspm_projecttaskbom%ROWTYPE;
v_name varchar;
v_value varchar;
v_oname varchar;
v_ovalue varchar;
v_prp varchar;
v_prt varchar;
v_bom varchar;
v_mdep varchar;
BEGIN 
    select count(*) into v_count from m_product where m_product_id=p_toproductid;
    if v_count=0 then
        RAISE EXCEPTION '%', '@zsse_DataNotExists@';
    end if;
    select value,name into v_value,v_name  from m_product where m_product_id=p_toproductid and typeofproduct in ('CD','AS','UA','SA') and isactive='Y' and isstocked='Y' and producttype='I';    
    if v_value is null then
        return '';
    end if;
    v_now:=now();
    select value,name into v_ovalue,v_oname from m_product where m_product_id=p_fromproduct_id;
    -- Neuen Produktionsplan erstellen-Nur wenn der Artikel Output eines Produktionsplanes ist..
    for v_cur in (select a.* from ad_org o,zssm_getproductionplanofproduct(p_fromproduct_id,o.ad_org_id) a)
    LOOP
         -- Load Rowtype
        select * into v_cur_prj from c_project where c_project_id=v_cur.c_project_id;
        if c_getconfigoption('createdefaultplanandworkstep',v_cur_prj.ad_org_id)='Y' then
            return '';
        end if;
        -- Genetrate new Plan
        v_prp:=v_cur_prj.c_project_id;
        v_cur_prj.c_project_id:=get_uuid();
        v_cur_prj.created := v_now;
        v_cur_prj.createdby := p_user;
        v_cur_prj.updated := v_now;
        v_cur_prj.updatedby := p_user;
        v_cur_prj.name:=replace(v_cur_prj.name,v_oname,v_name);
        v_count:=1;
        WHILE (select count(*) from c_project where projectcategory='PRP' and name=v_cur_prj.name)>0
        LOOP
            if v_count=1 then 
                v_cur_prj.name:=v_cur_prj.name ||'-'||v_count;
            else
                v_cur_prj.name:=replace(v_cur_prj.name,'-'||to_char(v_count-1),'-'||v_count);
            end if;
            v_count:=v_count+1;
        END LOOP;
        v_cur_prj.value:=replace(v_cur_prj.value,v_ovalue,v_value);
        v_count:=1;
        WHILE (select count(*) from c_project where projectcategory='PRP' and value=v_cur_prj.value)>0
        LOOP
            if v_count=1 then 
                v_cur_prj.value:=v_cur_prj.value ||'-'||v_count;
            else
                v_cur_prj.value:=replace(v_cur_prj.value,'-'||to_char(v_count-1),'-'||v_count);
            end if;
            v_count:=v_count+1;
        END LOOP;
        INSERT INTO c_project SELECT v_cur_prj.*; -- %rowtype
        for v_cur_pt in (select * from c_projecttask where assembly='Y' and c_project_id is null and m_product_id=p_fromproduct_id and exists
                             (select 0 from zssm_productionplan_task t where t.c_projecttask_id=c_projecttask.c_projecttask_id and t.c_project_id=v_prp)
                         union
                         select * from c_projecttask where assembly='N' and c_project_id is null and exists
                             (select 0 from zssm_productionplan_task t where t.c_projecttask_id=c_projecttask.c_projecttask_id and t.c_project_id=v_prp)
                             and exists (select 0 from zspm_projecttaskbom bom where bom.c_projecttask_id=c_projecttask.c_projecttask_id and bom.m_product_id=p_fromproduct_id)
                        )
        LOOP
            -- Genetrate new Base Workstep
            v_prt:=v_cur_pt.c_projecttask_id;
            v_cur_pt.c_projecttask_id:=get_uuid();
            v_cur_pt.created := v_now;
            v_cur_pt.createdby := p_user;
            v_cur_pt.updated := v_now;
            v_cur_pt.updatedby := p_user;
            v_cur_pt.name:=replace(v_cur_pt.name,v_oname,v_name);
            v_cur_pt.isautogeneratedplan:='N';
            v_count:=1;
            WHILE (select count(*) from c_projecttask where c_project_id is null and name=v_cur_pt.name)>0
            LOOP
                if v_count=1 then 
                    v_cur_pt.name:=v_cur_pt.name ||'-'||v_count;
                else
                    v_cur_pt.name:=replace(v_cur_pt.name,'-'||to_char(v_count-1),'-'||v_count);
                end if;
                v_count:=v_count+1;
            END LOOP;
            v_cur_pt.value:=replace(v_cur_pt.value,v_ovalue,v_value);
            v_count:=1;
            WHILE (select count(*) from  c_projecttask where c_project_id is null and value=v_cur_pt.value)>0
            LOOP
                if v_count=1 then 
                    v_cur_pt.value:=v_cur_pt.value ||'-'||v_count;
                else
                    v_cur_pt.value:=replace(v_cur_pt.value,'-'||to_char(v_count-1),'-'||v_count);
                end if;
                v_count:=v_count+1;
            END LOOP;
            if v_cur_pt.assembly='Y' then
                v_cur_pt.m_product_id:=p_toproductid;
            end if;
            INSERT INTO c_projecttask SELECT v_cur_pt.*; -- %rowtype
            -- Add the New Task to new Plan
            FOR v_cur_tasktab in (select * from zssm_productionplan_task where c_project_id=v_prp)
            LOOP
                v_cur_tasktab.copyidbak:=v_cur_tasktab.zssm_productionplan_task_id;
                v_cur_tasktab.zssm_productionplan_task_id:=get_uuid();
                v_cur_tasktab.c_project_id=v_cur_prj.c_project_id;
                v_cur_tasktab.created := v_now;
                v_cur_tasktab.createdby := p_user;
                v_cur_tasktab.updated := v_now;
                v_cur_tasktab.updatedby := p_user;
                -- Umhängen der zu Produzierenden Task
                if v_cur_tasktab.c_projecttask_id=v_prt then
                    v_cur_tasktab.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                    INSERT INTO zssm_productionplan_task SELECT v_cur_tasktab.*; -- %rowtype
                end if;     
            END LOOP;
            -- Create bom
            FOR v_cur_bom in (select * from zspm_projecttaskbom where c_projecttask_id=v_prt)
            LOOP
                v_cur_bom.zspm_projecttaskbom_id:=get_uuid();
                v_cur_bom.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                v_cur_bom.created := v_now;
                v_cur_bom.createdby := p_user;
                v_cur_bom.updated := v_now;
                v_cur_bom.updatedby := p_user;
                if v_cur_bom.m_product_id=p_fromproduct_id then
                    v_cur_bom.m_product_id:=p_toproductid;
                end if;
                INSERT INTO zspm_projecttaskbom SELECT v_cur_bom.*; -- %rowtype
            END LOOP;
            FOR v_cur_hr in (select * from zspm_ptaskhrplan where c_projecttask_id=v_prt)
            LOOP
                v_cur_hr.zspm_ptaskhrplan_id:=get_uuid();
                v_cur_hr.created := v_now;
                v_cur_hr.createdby := p_user;
                v_cur_hr.updated := v_now;
                v_cur_hr.updatedby := p_user;
                v_cur_hr.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                INSERT INTO zspm_ptaskhrplan  SELECT v_cur_hr.*; -- %rowtype
            END LOOP;
            FOR v_cur_ma in (select * from zspm_ptaskmachineplan where c_projecttask_id=v_prt)
            LOOP
                v_cur_ma.zspm_ptaskmachineplan_id:=get_uuid();
                v_cur_ma.created := v_now;
                v_cur_ma.createdby := p_user;
                v_cur_ma.updated := v_now;
                v_cur_ma.updatedby := p_user;
                v_cur_ma.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                INSERT INTO zspm_ptaskmachineplan  SELECT v_cur_ma.*; -- %rowtype
            END LOOP;
            FOR v_cur_td in (select * from zssm_Ptasktechdoc where c_projecttask_id=v_prt)
            LOOP
                v_cur_td.zssm_Ptasktechdoc_id:=get_uuid();
                v_cur_td.created := v_now;
                v_cur_td.createdby := p_user;
                v_cur_td.updated := v_now;
                v_cur_td.updatedby := p_user;
                v_cur_td.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                INSERT INTO zssm_Ptasktechdoc  SELECT v_cur_td.*; -- %rowtype
            END LOOP;
        END LOOP; -- Workstep Created
        -- Add remaining Tasks to new Plan
        FOR v_cur_tasktab in (select * from zssm_productionplan_task where c_project_id=v_prp and not exists
                              (select 0 from zssm_productionplan_task tt where c_project_id=v_cur_prj.c_project_id and tt.copyidbak=zssm_productionplan_task.zssm_productionplan_task_id))
        LOOP
            v_cur_tasktab.copyidbak:=v_cur_tasktab.zssm_productionplan_task_id;
            v_cur_tasktab.zssm_productionplan_task_id:=get_uuid();
            v_cur_tasktab.c_project_id=v_cur_prj.c_project_id;
            v_cur_tasktab.created := v_now;
            v_cur_tasktab.createdby := p_user;
            v_cur_tasktab.updated := v_now;
            v_cur_tasktab.updatedby := p_user;
            -- Umhängen der zu Produzierenden Task
            INSERT INTO zssm_productionplan_task SELECT v_cur_tasktab.*; -- %rowtype
        END LOOP;
        -- Generate Dependencies for the new Plan
        delete from zssm_productionplan_taskdep where c_project_id=v_cur_prj.c_project_id;
        FOR v_cur_dep in (select * from zssm_productionplan_taskdep where c_project_id=v_prp)
        LOOP
            v_cur_dep.zssm_productionplan_taskdep_id:=get_uuid();
            v_cur_dep.c_project_id:=v_cur_prj.c_project_id;
            v_cur_dep.created := v_now;
            v_cur_dep.createdby := p_user;
            v_cur_dep.updated := v_now;
            v_cur_dep.updatedby := p_user;
            select zssm_productionplan_task_id into v_mdep from zssm_productionplan_task where c_project_id=v_cur_prj.c_project_id and copyidbak=v_cur_dep.zssm_productionplan_task_id;
            v_cur_dep.zssm_productionplan_task_id:=v_mdep;
            select zssm_productionplan_task_id into v_mdep from zssm_productionplan_task where c_project_id=v_cur_prj.c_project_id and copyidbak=v_cur_dep.dependsontask;
            v_cur_dep.dependsontask:=v_mdep;
            -- Umhängen auf neue Tasks
            INSERT INTO zssm_productionplan_taskdep SELECT v_cur_dep.*; -- %rowtype
        END LOOP;
    END LOOP;
    -- Nur Base-Workstep, wenn der Artikel nicht Output eines Produktionsplanes ist
    for v_cur_pt in (select * from c_projecttask where assembly='Y' and c_project_id is null and m_product_id=p_fromproduct_id and 
                         (select count(*) from ad_org o,zssm_getproductionplanofproduct(p_fromproduct_id,o.ad_org_id) a) = 0
                    )
        LOOP
            if c_getconfigoption('createdefaultplanandworkstep',v_cur_pt.ad_org_id)='Y' then
                return '';
            end if;
            -- Genetrate new Base Workstep
            v_prt:=v_cur_pt.c_projecttask_id;
            v_cur_pt.c_projecttask_id:=get_uuid();
            v_cur_pt.created := v_now;
            v_cur_pt.createdby := p_user;
            v_cur_pt.updated := v_now;
            v_cur_pt.updatedby := p_user;
            v_cur_pt.name:=replace(v_cur_pt.name,v_oname,v_name);
            v_cur_pt.isautogeneratedplan:='N';
            v_count:=1;
            WHILE (select count(*) from c_projecttask where c_project_id is null and name=v_cur_pt.name)>0
            LOOP
                if v_count=1 then 
                    v_cur_pt.name:=v_cur_pt.name ||'-'||v_count;
                else
                    v_cur_pt.name:=replace(v_cur_pt.name,'-'||to_char(v_count-1),'-'||v_count);
                end if;
                v_count:=v_count+1;
            END LOOP;
            v_cur_pt.value:=replace(v_cur_pt.value,v_ovalue,v_value);
            v_count:=1;
            WHILE (select count(*) from  c_projecttask where c_project_id is null and value=v_cur_pt.value)>0
            LOOP
                if v_count=1 then 
                    v_cur_pt.value:=v_cur_pt.value ||'-'||v_count;
                else
                    v_cur_pt.value:=replace(v_cur_pt.value,'-'||to_char(v_count-1),'-'||v_count);
                end if;
                v_count:=v_count+1;
            END LOOP;
            if v_cur_pt.assembly='Y' then
                v_cur_pt.m_product_id:=p_toproductid;
            end if;
            INSERT INTO c_projecttask SELECT v_cur_pt.*; -- %rowtype
            -- Add the New Task to new Plan
            FOR v_cur_tasktab in (select * from zssm_productionplan_task where c_project_id=v_prp)
            LOOP
                v_cur_tasktab.copyidbak:=v_cur_tasktab.zssm_productionplan_task_id;
                v_cur_tasktab.zssm_productionplan_task_id:=get_uuid();
                v_cur_tasktab.c_project_id=v_cur_prj.c_project_id;
                v_cur_tasktab.created := v_now;
                v_cur_tasktab.createdby := p_user;
                v_cur_tasktab.updated := v_now;
                v_cur_tasktab.updatedby := p_user;
                -- Umhängen der zu Produzierenden Task
                if v_cur_tasktab.c_projecttask_id=v_prt then
                    v_cur_tasktab.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                    INSERT INTO zssm_productionplan_task SELECT v_cur_tasktab.*; -- %rowtype
                end if;     
            END LOOP;
            -- Create bom
            FOR v_cur_bom in (select * from zspm_projecttaskbom where c_projecttask_id=v_prt)
            LOOP
                v_cur_bom.zspm_projecttaskbom_id:=get_uuid();
                v_cur_bom.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                v_cur_bom.created := v_now;
                v_cur_bom.createdby := p_user;
                v_cur_bom.updated := v_now;
                v_cur_bom.updatedby := p_user;
                if v_cur_bom.m_product_id=p_fromproduct_id then
                    v_cur_bom.m_product_id:=p_toproductid;
                end if;
                INSERT INTO zspm_projecttaskbom SELECT v_cur_bom.*; -- %rowtype
            END LOOP;
            FOR v_cur_hr in (select * from zspm_ptaskhrplan where c_projecttask_id=v_prt)
            LOOP
                v_cur_hr.zspm_ptaskhrplan_id:=get_uuid();
                v_cur_hr.created := v_now;
                v_cur_hr.createdby := p_user;
                v_cur_hr.updated := v_now;
                v_cur_hr.updatedby := p_user;
                v_cur_hr.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                INSERT INTO zspm_ptaskhrplan  SELECT v_cur_hr.*; -- %rowtype
            END LOOP;
            FOR v_cur_ma in (select * from zspm_ptaskmachineplan where c_projecttask_id=v_prt)
            LOOP
                v_cur_ma.zspm_ptaskmachineplan_id:=get_uuid();
                v_cur_ma.created := v_now;
                v_cur_ma.createdby := p_user;
                v_cur_ma.updated := v_now;
                v_cur_ma.updatedby := p_user;
                v_cur_ma.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                INSERT INTO zspm_ptaskmachineplan  SELECT v_cur_ma.*; -- %rowtype
            END LOOP;
            FOR v_cur_td in (select * from zssm_Ptasktechdoc where c_projecttask_id=v_prt)
            LOOP
                v_cur_td.zssm_Ptasktechdoc_id:=get_uuid();
                v_cur_td.created := v_now;
                v_cur_td.createdby := p_user;
                v_cur_td.updated := v_now;
                v_cur_td.updatedby := p_user;
                v_cur_td.c_projecttask_id:=v_cur_pt.c_projecttask_id;
                INSERT INTO zssm_Ptasktechdoc  SELECT v_cur_td.*; -- %rowtype
            END LOOP;
        END LOOP; -- Workstep Created
    RAISE NOTICE '%','Copy Product - Productionplan Finished';
    return '  @ProductionplanCopydone@';
END;
$_$  LANGUAGE 'plpgsql';


/**************************************************************************************************************************************+

Manufactring


Project Implementation

* Material Management Impementation









***************************************************************************************************************************************/
CREATE or replace FUNCTION zsmf_CheckProductBOMRecursive(p_product character varying,p_bomProduct varchar) returns VOID
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
*****************************************************/
v_cur record;
v_cur2 record;
v_count numeric;
BEGIN
  -- All Worksteps that produce the actual BOM Product
  for v_cur in (select c_projecttask_id,value from c_projecttask where c_project_id is null and m_product_id=p_bomProduct)
  LOOP
    for v_cur2 in (select m_product_id from zspm_projecttaskbom where c_projecttask_id=v_cur.c_projecttask_id)
    LOOP
        --The Product in the BOM of a workstep that produces actual BOM Product is The Product that is Produced in Actual Workstep. This is a recursion!
        IF v_cur2.m_product_id=p_product then
             RAISE EXCEPTION '%', '@zsmf_BOMHasRecoursion@'||zssi_getproductname(v_cur2.m_product_id,'de_DE')||'-Workstep:'||v_cur.value;
        END IF;
        PERFORM zsmf_CheckProductBOMRecursive(p_Product,v_cur2.m_product_id);
    END LOOP;
  END LOOP;
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
  
CREATE OR REPLACE FUNCTION zsmf_projecttaskbom_trg ()
RETURNS trigger AS
$body$
 DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): MH
***************************************************************************************************************************************************
Restriction-Trigger for Production BOM
*****************************************************/
v_count numeric;
v_isrec varchar;
v_isclosed varchar;
v_pcategory varchar;
v_product varchar;
v_value varchar;
v_calcdate timestamp without time zone;
BEGIN
-- RAISE EXCEPTION '% = %', TG_NAME, TG_OP;
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;

  IF TG_OP = 'DELETE' then
	if old.qtyreserved!=0 or old.qtyreceived!=0 or old.qtyinrequisition!=0 then
		RAISE EXCEPTION '%', 'Material wurde bereits geplant. Erst Materialreservierungen/Bedarfe/Entnahmen stornieren. Dann kann hier geloescht werden.';
	end if;
  end if; 
  
  IF TG_OP != 'DELETE' then
      select coalesce(coalesce(p.startdate,pt.startdate),trunc(now()))  into v_calcdate from c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id and pt.c_projecttask_id=new.c_projecttask_id;
      if new.directship is null then new.directship:='N'; end if;
      if new.consumption is null then new.consumption:='N'; end if;
      select count(*) into v_count from m_product where (isactive!='Y' or Producttype!='I') and m_product_id=new.m_product_id;
      if v_count!=0 then
         RAISE EXCEPTION '%', '@zsmf_InPlanMatOnlyActiveStockedItems@:'||(select value from m_product where  m_product_id=new.m_product_id);
      end if;
      select count(*) into v_count from zspm_projecttaskbom where c_projecttask_id=new.c_projecttask_id and zspm_projecttaskbom_id!=new.zspm_projecttaskbom_id and m_product_id=new.m_product_id;
      if v_count!=0 then
          raise exception '%', '@duplicatelinenumber@ in '||coalesce((select value||'-'||name from m_product where m_product_id=new.m_product_id),'#')||' Pos: '||coalesce(to_char(new.line),'#');
      end if; 
      select m_product_id,name into v_product,v_value from c_projecttask where c_projecttask_id=new.c_projecttask_id and assembly='Y';
      if coalesce(v_product,'')=new.m_product_id then
         RAISE EXCEPTION '%', '@zsmf_BOMHasRecoursion@ in Workstep:'||v_value;
      end if;
      PERFORM zsmf_CheckProductBOMRecursive(v_product,new.m_product_id);
      -- Calculate actual planned amt
      if new.isreturnafteruse='N' then
        new.plannedamt:=coalesce(m_get_product_cost(new.m_product_id,v_calcdate,null,new.ad_org_id)*new.quantity,0);
      else
         new.plannedamt:=0;
      end if;
      select count(*) into v_count from snr_masterdata snr,ma_machine m where m.snr_masterdata_id=snr.snr_masterdata_id
                      and m.ismovedinprojects='Y' and snr.m_product_id=new.m_product_id;
      if v_count>0 then
        if new.description!='Generated by Production->Get Machine from Stock' or new.quantity!=0 or new.isreturnafteruse!='Y' or new.planrequisition='Y' then
            RAISE EXCEPTION '%', '@zsmf_CannotmodifyMachineProducts@';
        end if;
      end if;
                      
      IF (TG_OP = 'UPDATE') THEN 
        /*
        SELECT COUNT(*) INTO v_count FROM c_projecttask WHERE IsMaterialDisposed='Y' AND c_projecttask_id = NEW.c_projecttask_id;
        IF old.qtyinrequisition>0 AND NEW.qtyinrequisition=old.qtyinrequisition AND NEW.qtyreceived=old.qtyreceived AND (v_count != 0) THEN
            RAISE EXCEPTION '%', 'Material wurde bereits geplant. Erst Bedarfe stornieren. Dann kann hier editiert werden.';
        END IF;
        */  
        if old.m_requisitionline_id is not null and new.m_requisitionline_id is null then
            new.qtyinrequisition:=0;
        end if;
        if new.m_requisitionline_id is not null and new.planrequisition='N' then
            --raise exception '%' , 'Bedarfsanforderung bereits erstellt. Erst Bedarfsanforderung löschen'; 
            new.planrequisition='Y';
        end if;
        if new.m_requisitionline_id is null and new.planrequisition='Y' and new.qtyreceived>=new.quantity then
            --Keine BANF mehr notwendig
            new.planrequisition='N';
        end if;
        SELECT t.istaskcancelled,t.iscomplete,p.projectcategory INTO v_isrec,v_isclosed,v_pcategory 
        FROM c_projecttask t,c_project p where p.c_project_id=t.c_project_id and c_projecttask_id=new.c_projecttask_id;
        IF (v_isrec = 'Y') OR (v_isclosed = 'Y')  THEN
          if (abs(NEW.qtyreceived) > abs(OLD.qtyreceived)) or new.m_product_id!=old.m_product_id or new.m_locator_id!=old.m_locator_id or
            new.issuing_locator!=old.issuing_locator or new.receiving_locator!=old.receiving_locator or old.quantity !=new.quantity or new.isreturnafteruse!=old.isreturnafteruse
          then 
            RAISE EXCEPTION '%','@zspm_OnLyReturnsAreAllowedOnClosedWorksteps@';
          end if;
        END IF;
      END IF; -- TG_OP = 'UPDATE'
      RETURN NEW;
  end if; 
END;
$body$
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION zsmf_createproductionbom(p_pinstance_id character varying)
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
Part of Manufacturing
Creates a Production-BOM for a specific Product
Checks
*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_org  character varying;
v_client  character varying;
v_product character varying;
v_pwareh character varying;
v_qty numeric;
v_warehouse character varying;
v_type character varying;
v_ptype character varying;
v_isstocked character varying;
v_prod character varying;
v_message  character varying:= 'Materialplanung erstellt.';
v_ualist character varying;
v_qtyua numeric:=1;
v_i numeric:=1;
v_cutoff numeric;
v_count numeric;
v_prec numeric;
v_tmpwh varchar;
-- Define Dynamic Cursor
v_sql character varying;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_rlocator varchar;
v_ilocator varchar;
v_locator varchar;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    -- Select Assembly-Product
    --Check if Project-Warehouse and Product Warehouse are identical!!!!!!!!!
    select c_project.m_warehouse_id into v_warehouse
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=v_Record_ID;
    
    select m_product.m_product_id,m_locator.m_warehouse_id,c_projecttask.qty,c_projecttask.ad_client_id,c_projecttask.ad_org_id,c_projecttask.issuing_locator,c_projecttask.receiving_locator
          into v_product,v_pwareh,v_qty,v_client,v_org,v_ilocator,v_rlocator from m_product,c_projecttask,m_locator where 
                                                          c_projecttask.m_product_id=m_product.m_product_id and m_product.m_locator_id=m_locator.m_locator_id and c_projecttask_id=v_Record_ID;
    select m_warehouse_id into v_tmpwh from m_product_org,m_locator where m_locator.m_locator_id=m_product_org.m_locator_id and m_product_id=v_product and m_warehouse_id=v_warehouse limit 1;
    if v_tmpwh is not null then 
        v_pwareh:=v_tmpwh;
    end if;
    if v_warehouse!=v_pwareh and (select c_project_id from c_projecttask where c_projecttask_id=v_Record_ID) is not null then
       RAISE EXCEPTION '%', '@zsmf_ProductWareHouseAndProjectWarehouseDiffer@';
    end if;
    if v_product is null then 
        RAISE EXCEPTION '%', 'No Product or no Locator found.';
    end if;

    -- If we have multiple lines of the same material in this Production-BOM
    -- This material is combined together in one line
    -- Buiding BOM ist strictly bound in Matching Products.... (Ticket 10240)
    for v_cur in (select M_PRODUCTbom_ID as M_PRODUCT_ID,string_agg(constuctivemeasure,';') as constuctivemeasure,string_agg(rawmaterial,';') as rawmaterial, min(line) as line,sum(bomqty) as quantity 
                  from m_product_bom where M_PRODUCT_ID = v_product group by M_PRODUCTbom_ID)
    LOOP
         select coalesce(p.cutoff,0),p.producttype,c_uom.stdprecision into v_cutoff,v_ptype,v_prec 
                from c_uom, m_product p where p.c_uom_id=c_uom.c_uom_id and p.m_product_id=v_cur.M_PRODUCT_ID;
         select  m_locator_id into v_locator from m_product where m_product_id=v_cur.m_product_id;
         if v_ptype='I' then 
            if (select count(*) from zspm_projecttaskbom where C_PROJECTTASK_ID = v_Record_ID and m_product_id=v_cur.m_product_id)=0 then
                insert into zspm_projecttaskbom(ZSPM_PROJECTTASKBOM_ID, C_PROJECTTASK_ID, AD_CLIENT_ID, AD_ORG_ID,CREATEDBY, updatedby, M_PRODUCT_ID, 
                            QTY_PLAN,cutoff,quantity,constuctivemeasure,rawmaterial,line,issuing_locator,receiving_locator)
                values (get_uuid(),v_Record_ID,v_client,v_org,v_user,v_user,v_cur.m_product_id,v_cur.quantity,v_cutoff,round(v_cur.quantity*coalesce(v_qty,1),v_prec),v_cur.constuctivemeasure,v_cur.rawmaterial,v_cur.line,
                       coalesce(v_ilocator,v_locator),coalesce(v_rlocator,v_locator)
                );
            else
                update zspm_projecttaskbom set M_PRODUCT_ID=v_cur.M_PRODUCT_ID, QTY_PLAN=v_cur.quantity , quantity=round(v_cur.quantity*coalesce(v_qty,1),v_prec) , constuctivemeasure=v_cur.constuctivemeasure , 
                       rawmaterial = v_cur.rawmaterial,issuing_locator=coalesce(v_ilocator,v_locator),receiving_locator=coalesce(v_rlocator,v_locator)
                where C_PROJECTTASK_ID = v_Record_ID and  m_product_id=v_cur.m_product_id;
            end if;
         end if;
    END LOOP;
    -- Delete Deleted Lines...
    delete from zspm_projecttaskbom where C_PROJECTTASK_ID = v_Record_ID and qtyreserved=0 and qtyreceived=0 and qtyinrequisition=0 
           and m_requisitionline_id is null and c_orderline_id is null and c_salesorderline_id is null
           and not exists (select 0 from m_product_bom b where b.M_PRODUCTbom_ID=zspm_projecttaskbom.m_product_id and b.m_product_id=v_product);
    update zspm_projecttaskbom set QTY_PLAN=0, quantity=0 where C_PROJECTTASK_ID = v_Record_ID and (qtyreserved!=0 or qtyreceived!=0 or qtyinrequisition!=0 
           or m_requisitionline_id is not null or c_orderline_id is not null or c_salesorderline_id is not null)
           and not exists (select 0 from m_product_bom b where b.M_PRODUCTbom_ID=zspm_projecttaskbom.m_product_id and b.m_product_id=v_product);
    --perform zsmf_preplanmaterial(v_Record_ID,v_User);
    select  v_message||zsmf_createproductionbom_userexit(v_Record_ID,v_User) into v_message;
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
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

-- User Exit to  zsmf_createproductionbom
CREATE or replace FUNCTION zsmf_createproductionbom_userexit(p_projecttask_id varchar,p_user varchar) RETURNS varchar
AS $_$
DECLARE
  BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsmf_preplanmaterialprocess(p_pinstance_id character varying)
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
Part of Manufacturing
Copy Items from Task to Internal-Consumption
  Only Items that where Requested by Requisition and are on stock yet.
*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message  character varying:= 'Materialplanung erstellt.';

BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    perform zsmf_preplanmaterial(v_Record_ID,v_User);
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
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


CREATE OR REPLACE FUNCTION zsmf_preplanmaterial(p_PROJECTTASK_ID character varying,p_user character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
v_qtyavail numeric;
v_cur RECORD;
v_cur2 RECORD;
v_locator character varying;
v_warehouse  character varying;
v_first  character varying:='Ä';
v_rest numeric:=0;
v_qty numeric;
v_uom character varying;
v_planlocator varchar;
v_isstocked varchar;
BEGIN
   select c_project.m_warehouse_id,c_projecttask.ismaterialdisposed into v_warehouse,v_planlocator
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=p_PROJECTTASK_ID;
   for v_cur in (select * from zspm_projecttaskbom where C_PROJECTTASK_ID =p_PROJECTTASK_ID and m_requisitionline_id is null)
   LOOP
        -- 1st strategy: Get mat from default locator
        select m_locator_id,c_uom_id,isstocked into v_locator,v_uom,v_isstocked from m_product where m_product_id=v_cur.m_product_id;
        if (select count(*) from m_locator where m_locator_id=v_locator and m_warehouse_id=v_warehouse)=0 then
            select m_product_org.m_locator_id into v_locator from m_product_org,m_locator where m_locator.m_locator_id=m_product_org.m_locator_id and m_product_id=v_cur.m_product_id and m_warehouse_id=v_warehouse limit 1;
        end if;
        select coalesce(QTYONHAND,0) as qtyavail into v_qtyavail from m_storage_detail where m_product_id=v_cur.m_product_id and C_UOM_ID=v_uom and 
                                                            m_locator_id = v_locator;
        if v_cur.quantity-v_cur.qtyreserved-v_cur.qtyreceived <= coalesce(v_qtyavail,0) and
           (select m_warehouse_id from m_locator where m_locator_id=v_locator) = v_warehouse and
           (select qty_available from zspm_projecttaskbom_view where zspm_projecttaskbom_view_id=v_cur.zspm_projecttaskbom_id)>=v_cur.quantity-v_cur.qtyreserved-v_cur.qtyreceived and
           (v_cur.quantity-v_cur.qtyreserved-v_cur.qtyreceived)>0
        then
           -- everything fine
           update zspm_projecttaskbom set m_locator_id=v_locator, planrequisition='N' where zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id;
        else
        -- 2nd strategy: Always get from fullest stocks (minimize lines in Planning) 
            v_rest:=v_cur.quantity-v_cur.qtyreserved-v_cur.qtyreceived;
            v_first:='Y';
            if v_rest>0 and (select qty_available from zspm_projecttaskbom_view where zspm_projecttaskbom_view_id=v_cur.zspm_projecttaskbom_id)>=v_rest then
                for v_cur2 in (select coalesce(QTYONHAND,0) as qtyavail,m_locator_id  from m_storage_detail where m_product_id=v_cur.m_product_id and C_UOM_ID=v_uom and 
                                                                m_locator_id in (select m_locator_id from m_locator where m_warehouse_id=v_warehouse)
                                                                and coalesce(QTYONHAND,0) >0
                                                                order by qtyavail desc)
                LOOP
                    select least(v_cur2.qtyavail,(select qty_available from zspm_projecttaskbom_view where zspm_projecttaskbom_view_id=v_cur.zspm_projecttaskbom_id)) into v_qtyavail;
                    if v_rest<=v_qtyavail then 
                        v_qty:=v_rest; 
                        v_rest:=0;
                    else 
                        v_qty:=v_qtyavail;
                        v_rest:=v_rest-v_qtyavail;
                    end if;
                    if v_first='Y' then 
                    update zspm_projecttaskbom set m_locator_id=v_cur2.m_locator_id,quantity=v_qty, planrequisition='N' where zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id; 
                    v_first:='N';
                    else
                    insert into zspm_projecttaskbom(ZSPM_PROJECTTASKBOM_ID, C_PROJECTTASK_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, 
                                                    M_PRODUCT_ID, QTY_PLAN,cutoff,quantity,constuctivemeasure,rawmaterial,m_locator_id)
                    values (get_uuid(),p_PROJECTTASK_ID,v_cur.ad_client_id,v_cur.ad_org_id,'Y',now(),p_user,now(),p_user,
                                v_cur.m_product_id,v_cur.QTY_PLAN,v_cur.cutoff,v_qty,v_cur.constuctivemeasure,v_cur.rawmaterial,v_cur2.m_locator_id);
                    end if;
                    if v_rest=0 then
                    exit;
                    end if;
                END LOOP;
            end if; -- Qty Available
            -- Rest in Req.
            /*
            if v_rest!=0 and v_first='N' then
                insert into zspm_projecttaskbom(ZSPM_PROJECTTASKBOM_ID, C_PROJECTTASK_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, 
                                                   M_PRODUCT_ID, QTY_PLAN,cutoff,quantity,constuctivemeasure,rawmaterial,planrequisition)
                   values (get_uuid(),p_PROJECTTASK_ID,v_cur.ad_client_id,v_cur.ad_org_id,'Y',now(),p_user,now(),p_user,
                             v_cur.m_product_id,v_cur.QTY_PLAN,v_cur.cutoff,v_rest,v_cur.constuctivemeasure,v_cur.rawmaterial,'Y');
            end if;
            */
            if v_rest>0 and v_first='Y' and v_planlocator='N' then
                update zspm_projecttaskbom set planrequisition='Y',m_locator_id=null where zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id; 
            end if;
            if (v_rest>0 and v_first='Y' and v_planlocator='Y')  or v_isstocked='N'  then
                select m_locator_id into v_locator  from m_product where m_product_id=v_cur.m_product_id and m_locator_id in (select m_locator_id from m_locator where m_warehouse_id=v_warehouse);
                if v_locator is null then
                    select m_locator_id into v_locator  from m_product_org where  m_product_id=v_cur.m_product_id and isactive='Y' and m_locator_id in (select m_locator_id from m_locator where m_warehouse_id=v_warehouse) limit 1;
                end if;
                update zspm_projecttaskbom set planrequisition='N',m_locator_id=v_locator where zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id;
            end if;
        end if;          
   END LOOP;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zsmf_getlocatorWithStock(p_projecttask_id varchar,p_product_ID character varying)
  RETURNS varchar AS
$BODY$ 
DECLARE 
v_qtyavail numeric;
v_qtyinstock numeric;
v_warehouse varchar;
v_locator varchar;
v_locator2 varchar;
v_uom     varchar;
BEGIN
    select c_project.m_warehouse_id into v_warehouse
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=p_PROJECTTASK_ID;
    select m_locator_id,c_uom_id into v_locator,v_uom from m_product where m_product_id=p_product_ID;
    -- First take the standard Locator
    select coalesce(QTYONHAND,0) as qtyavail into v_qtyavail from m_storage_detail 
                                                                                 where m_product_id=p_product_ID and C_UOM_ID=v_uom and 
                                                                                       m_locator_id = v_locator;
    -- Second any Locator in the warehouse.
    select coalesce(QTYONHAND,0) as qtyinstock,m_locator_id into v_qtyinstock,v_locator2 from m_storage_detail where m_product_id=p_product_ID and C_UOM_ID=v_uom and 
                                                            m_locator_id in (select m_locator_id from m_locator where m_warehouse_id=v_warehouse)
                                                            and coalesce(QTYONHAND,0) >0
                                                            order by v_qtyinstock desc limit 1;
    --. Test which one to use.                                                        
    if  coalesce(v_qtyavail,0)>0 and
       (select m_warehouse_id from m_locator where m_locator_id=v_locator) = v_warehouse then
             return v_locator;
    elsif coalesce(v_qtyinstock,0)>0 then
             return v_locator2;
    else
             return null;
    end if;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION zsmf_disposematerial(p_pinstance_id character varying)
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
Part of Projects, Dispose the complete BOM of the Task in Inventory (Obsolete)
                  Creates PR's if necessary - Only Purpose: Creation of Requisitions
Checks
*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='@RequisitionWithoutLines@';
v_cur     RECORD;
v_qtyonhand numeric;
v_count numeric;
v_warehouse character varying;
v_locator character varying;
v_uom character varying;
v_att character varying;
v_vendor character varying;
v_pricelist character varying;
v_description character varying;
v_price numeric;
v_project character varying;
v_isreqheader character varying:='N';
v_typeofproduct character varying;
v_isproduction character varying;
v_requid  character varying;
v_needdate timestamp without time zone;
v_line numeric:=10;
v_seq character varying;
v_lang character varying;
v_pstatus character varying;
v_vendorproductno character varying;
v_isoutsource character varying;
v_qty2reserve numeric:=0;
v_qty2requisition numeric:=0;
v_reqlineuuid varchar;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    -- Language for Messages
    select default_ad_language into v_lang from ad_user where ad_user_id=v_User;
    select c_project.m_warehouse_id,c_project.c_project_id,coalesce(c_projecttask.startdate,trunc(now())),c_project.projectstatus into v_warehouse,v_project ,v_needdate,v_pstatus
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=v_Record_ID;
    if v_pstatus!='OR'  then
         RAISE EXCEPTION '%', '@zsmf_YouNeedtoStrtProjectToPlanMat@';
    end if;
    if v_warehouse is null then
         RAISE EXCEPTION '%', '@zsmf_YouNeedaWarehousetoPlanMat@';
    end if;
    select outsourcing into v_isoutsource  from c_projecttask where c_projecttask.c_projecttask_id=v_Record_ID;
    select count(*) into v_count from zspm_projecttaskbom where c_projecttask_id=v_Record_ID;
    if v_count=0 and v_isoutsource='N' then
       RAISE EXCEPTION '%', '@zsmf_NoBomNoMatPlan@';
    end if;
 
    -- Plan REQUISITIONS
    for v_cur in (select * from zspm_projecttaskbom where zspm_projecttaskbom.c_projecttask_id=v_Record_ID and quantity>0 and planrequisition='Y' and m_requisitionline_id is null)
    LOOP
         -- Need Requisition
            v_qty2requisition:=v_cur.quantity-v_cur.qtyreserved-v_cur.qtyreceived;
            --RAISE NOTICE '%','Requisition:'||v_cur.m_product_id||',qty:'||v_cur.quantity||',Onhand:'||v_qtyonhand||',U:'||v_User;
            -- If assembly: Test If it is produced by a step  in this Project and In Time, Otherwise No Disposition Possible
            -- Outsourced Assemblys may get in requisition
         
            -- Take standad vendor from m_product_po, if none, take any vendor.
            select c_bpartner_id,pricepo,vendorproductno into v_vendor,v_price,v_vendorproductno from m_product_po  where m_product_id=v_cur.m_product_id  and isactive='Y' and iscurrentvendor='Y' 
                   order by qualityrating desc limit 1;
            if v_vendor is null then
                 select c_bpartner_id,pricepo,vendorproductno into v_vendor,v_price,v_vendorproductno from m_product_po  where m_product_id=v_cur.m_product_id  and isactive='Y'   limit 1;
            end if;
            select po_pricelist_id into v_pricelist from c_bpartner where c_bpartner_id=v_vendor;
            select c_uom_id into v_uom from m_product where m_product_id=v_cur.m_product_id;
            if v_pricelist is null then 
                 select m_pricelist_id into v_pricelist from m_pricelist where issopricelist='N' and isactive='Y' order by isdefault desc limit 1;
            end if;
            -- If not on Stock and no Assembly -> Open an PR
            if v_isreqheader='N' then
                -- Create requisition
                select ad_sequence_doc('DocumentNo_M_Requisition',v_cur.ad_org_ID,'Y') into v_seq from dual;
                select get_uuid() into v_requid from dual;
                insert into m_requisition(M_REQUISITION_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, DESCRIPTION, DOCUMENTNO, C_PROJECT_ID, C_PROJECTTASK_ID, ad_user_id,m_pricelist_id)
                      values (v_requid,v_cur.ad_client_ID, v_cur.ad_Org_ID, 'Y', now(),v_User,now(),v_User,zssi_getText('zsmf_GeneratedByPlanning', v_lang),v_seq,v_project,v_Record_ID, v_user,v_pricelist);
                v_isreqheader:='Y';
                v_Message:='@CreatedRequisition@: '|| zsse_htmlLinkDirectKey('../Requisition/Header_Relation.html',v_requid,v_seq)||' erstellt.</br>';
            end if;
            -- Take the Vendors Product no. and Product Descripotion
            select documentnote into v_description from m_product where m_product_id=v_cur.m_product_id;
            if v_vendorproductno is not null and v_description is not null then
              v_description:=zssi_getText('zssi_vendorproductno',v_lang)||' '||v_vendorproductno||chr(10)||v_description;
            elsif v_vendorproductno is not null and v_description is null then
              v_description:=zssi_getText('zssi_vendorproductno',v_lang)||' '||v_vendorproductno;
            else
              v_description:='';
            end if;
            --
            select get_uuid() into v_reqlineuuid;
            insert into m_requisitionline (M_REQUISITIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_REQUISITION_ID, M_PRODUCT_ID, QTY, C_UOM_ID, DESCRIPTION, 
                        internalnotes,
                        NEEDBYDATE, LINE, C_PROJECT_ID, C_PROJECTTASK_ID,c_bpartner_id,priceactual,m_pricelist_id,zspm_projecttaskbom_id,linenetamt)
                      values(v_reqlineuuid,v_cur.ad_client_ID, v_cur.ad_Org_ID,now(),v_User,now(),v_User,v_requid,v_cur.m_product_id,v_qty2requisition,v_uom,v_description,
                              zssi_getText('zsmf_GeneratedByPlanning', v_lang),
                              coalesce(v_cur.date_plan,v_needdate),v_line,v_project,v_Record_ID,v_vendor,v_price,v_pricelist,v_cur.zspm_projecttaskbom_id, v_qty2requisition*v_price);
            v_line:=v_line+10;
            if v_isoutsource='N' then 
                update zspm_projecttaskbom set m_requisitionline_id=v_reqlineuuid,qtyinrequisition=qtyinrequisition+v_qty2requisition,updated=now(),updatedby=v_user where zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id;
            end if;
      END LOOP;
	  UPDATE m_requisition set totalLines=(SELECT COALESCE(SUM(linenetamt),0) FROM m_requisitionline WHERE m_requisition_id = v_requid) where m_requisition_id = v_requid;

    if  v_isreqheader='Y' then
       -- close Req
      PERFORM m_requisition_post(v_requid);
      -- Set Task as disposed
      --update c_projecttask set ismaterialdisposed='Y' where c_projecttask_id=v_Record_ID;
      --v_Message:=v_Message||'Um direkt in den Material-Einkauf zu gelangen, klicken Sie hier:'||zsse_htmlLinkDirectKey('../ad_forms/RequisitionToOrder.html',v_User,'Bedarf einkaufen');
    end if;
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  


CREATE OR REPLACE FUNCTION zsmf_undisposematerial(p_pinstance_id character varying)
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
Part of Projects, UnDispose the complete BOM of the Task in Inventory
                  Voids PR's if necessary
Checks
*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='';
v_cur     RECORD;
v_count numeric;
v_warehouse  character varying;
v_project character varying;
v_lang character varying;
v_cancelreq character varying:='N';
v_cannotcancelreq character varying:='N';
v_cancelmat character varying:='N';
v_uom character varying;
v_somthingdone character varying:='N';
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    select default_ad_language into v_lang from ad_user where ad_user_id=v_User;
    select c_project.m_warehouse_id,c_project.c_project_id into v_warehouse,v_project 
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=v_Record_ID;
    -- undispose mat.
    select count(*) into v_count from zspm_projecttaskbom where c_projecttask_id=v_Record_ID and m_requisitionline_id is not null;
    
    if coalesce(v_count,0)>0 then
       -- Req exists, Lines not Ordered
       for v_cur in (select distinct m_requisition.m_requisition_id,m_requisition.documentno,m_requisitionline.m_product_id,m_requisitionline.zspm_projecttaskbom_id from m_requisitionline,m_requisition where m_requisition.m_requisition_id=m_requisitionline.m_requisition_id 
                                                                 and m_requisitionline.c_project_id=v_project 
                                                                 and m_requisitionline.c_projecttask_id=v_Record_ID
                                                                 and m_requisition.docstatus='CO'
                                                                 and not exists (select 0 from m_requisitionorder where m_requisitionorder.m_requisitionline_id = m_requisitionline.m_requisitionline_id))
       LOOP
       -- Cancel not Ordered Req's
          -- PERFORM m_requisition_post(v_cur.m_requisition_id);
          update m_requisition set processed='N',docstatus='DR' where m_requisition_id=v_cur.m_requisition_id;
          delete from m_requisitionline where m_requisition_id=v_cur.m_requisition_id;
          delete from m_requisition   where m_requisition_id=v_cur.m_requisition_id;
          if v_cancelreq='N' then 
             v_message:=zssi_getText('zsmf_CancelledReq', v_lang);
             v_cancelreq:='Y';
          else 
             v_message:=v_message||',';
          end if;
          if instr(v_message,v_cur.documentno)=0 then v_message:=v_message||v_cur.documentno; end if;
          update zspm_projecttaskbom set qtyinrequisition=0 where zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id;
          v_somthingdone:='Y';
       END LOOP;
       -- Req exists, Lines Ordered
       for v_cur in (select distinct m_requisition.m_requisition_id,m_requisition.documentno from m_requisitionline,m_requisition where m_requisition.m_requisition_id=m_requisitionline.m_requisition_id 
                                                                 and m_requisitionline.c_project_id=v_project 
                                                                 and m_requisitionline.c_projecttask_id=v_Record_ID
                                                                 and exists (select 0 from m_requisitionorder where m_requisitionorder.m_requisitionline_id = m_requisitionline.m_requisitionline_id))
       LOOP
       -- Cannot Cancel Ordered Req's
          if v_cannotcancelreq='N' then 
             if v_message!='' then
                v_message:=v_message||'</br>';
             end if;
             v_message:=zssi_getText('zsmf_CannotCancelledReq', v_lang);
             v_cancelreq:='Y';
          else 
             v_message:=v_message||',';
          end if;
          if instr(v_message,v_cur.documentno)=0 then v_message:=v_message||v_cur.documentno; end if;
       END LOOP;
    END IF; -- Req's exists
    
      -- Set Task as undisposed
     -- update c_projecttask set ismaterialdisposed='N' where c_projecttask_id=v_Record_ID;
   -- else
   --   v_Message:=v_message||'Die Materialplanung kann nicht storniert werden. Alle Positionen wurde bereits geliefert bzw. bestellt.';
   -- end if;
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message);
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
ALTER FUNCTION zsmf_undisposematerial(character varying) OWNER TO tad;





select zsse_dropfunction('zsmf_GetMaterialFromStock');
CREATE OR REPLACE FUNCTION zsmf_GetMaterialFromStock(v_projecttaskid character varying, v_user varchar) RETURNS varchar
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
Part of Manufactring

*****************************************************/
v_warehouse  character varying;
v_project  character varying;
v_locator  character varying;
v_client   character varying;
v_org      character varying;
v_cur      RECORD;
v_uom      character varying;
v_Message  character varying:='';
v_Result   numeric:=0;
v_Count    numeric;
v_qtyinconsum numeric;
v_qtyreturned numeric;
v_Line     numeric:=0;
v_Uid      character varying;
v_serial   varchar;
v_batch   varchar;
v_lineUUId varchar;
v_isserial boolean:=false;
v_DocumentNo varchar;
v_qtyOnHand numeric;
BEGIN 
     select c_project.m_warehouse_id,c_project.c_project_id,c_project.ad_client_id,c_project.ad_org_id into v_warehouse,v_project,v_client, v_org
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=v_projecttaskid;
    -- Eventually update Material Plan before Starting Transaction
    if (select c_getconfigoption('projectmatpanautowhengetmat',v_Org))='Y' then
       PERFORM zsmf_preplanmaterial(v_projecttaskid,v_user);
    end if;
    -- Prepare Material Consumption
    --select count(*) into v_Count from zspm_projecttaskbom where c_projecttask_id=v_projecttaskid and quantity>qtyreceived and m_locator_id is not null and planrequisition='N' and qtyinrequisition=0;
    --if v_count>0 then
        select get_uuid() into v_uid;
        select ad_sequence_doc('Production',v_org,'Y') into v_DocumentNo;
        insert into M_INTERNAL_CONSUMPTION(M_INTERNAL_CONSUMPTION_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                    NAME, DESCRIPTION, MOVEMENTDATE,dateacct, C_PROJECT_ID, C_PROJECTTASK_ID,  MOVEMENTTYPE,DOCUMENTNO)
               values(v_uid,v_client,v_Org,NOW(), v_User, NOW(),v_User,
                      'Production-Process','Generated by Production->Get Material from Stock',now(),now(),v_project, v_projecttaskid,'D-',v_DocumentNo);
    --end if;
    -- Select all Reserved Material and all Assemblys goin into this Task
    for v_cur in (select * from zspm_projecttaskbom where c_projecttask_id=v_projecttaskid and quantity>qtyreceived and m_locator_id is not null and planrequisition='N' and qtyinrequisition=0)
    LOOP      
        -- uom
        select c_uom_id,isserialtracking,isbatchtracking into v_uom,v_serial,v_batch from m_product where m_product_id=v_cur.m_product_id;
        select m_bom_qty_onhand(v_cur.m_product_id,null,v_cur.m_locator_id) into v_qtyOnHand;
        if v_qtyOnHand>0 then
            v_Line:=v_Line+10;
            select get_uuid() into v_lineUUId;
            insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                            M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID,zspm_projecttaskbom_id)
                values (v_lineUUId,v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid,
                    v_cur.m_locator_id,v_cur.M_Product_ID,v_Line,least(v_qtyOnHand,(v_cur.quantity-v_cur.qtyreceived)),'Generated by Production->Get Material from Stock',v_uom,v_project, v_projecttaskid,v_cur.zspm_projecttaskbom_id);
            -- seruial Number Tracking?
            if v_serial='Y' or v_batch='Y' then
                v_isserial:=true;
                v_message:=v_message||zsse_htmlLinkDirectKey('../InternalMaterialMovements/Lines_Relation.html',v_lineUUId,'Serial Number Tracking')||'<br />';
            end if;
        end if;
        --if (select allownegativestock from ad_clientinfo where ad_client_id=v_cur.ad_client_id)='N' then
        --    if (select m_bom_qty_onhand(v_cur.m_product_id,null,v_cur.m_locator_id)) < (v_cur.quantity-v_cur.qtyreceived) then
        --        raise exception '%', '@NotEnoughStocked@';
        --    end if;
        --end if;
    END LOOP;
    -- Take movable Machines into Workstep, if configured - First generate Messages for machines we cannot get....
    for v_cur in (select distinct snr.m_product_id,m.name,snr.serialnumber ,snr.m_locator_id,snr.c_projecttask_id
                      from zspm_ptaskmachineplan p,ma_machine m left join snr_masterdata snr on snr.snr_masterdata_id=m.snr_masterdata_id
                      where p.ma_machine_id=m.ma_machine_id and p.c_projecttask_id=v_projecttaskid and m.ismovedinprojects='Y')
    LOOP
        if v_cur.serialnumber is null then
             RAISE EXCEPTION '%', '@zspm_NoMachineTransactionPossibleSNRNeeded@'||v_cur.name;
            
        elsif v_cur.m_locator_id is null and coalesce(v_cur.c_projecttask_id,'') != v_projecttaskid then
             RAISE EXCEPTION '%', '@zspm_NoMachineTransactionPossibleMachineIsNotHere@'||v_cur.name||'-'||v_cur.serialnumber;
        elsif  v_cur.m_locator_id is not null then
            v_Line:=v_Line+10;
            select c_uom_id,isserialtracking,isbatchtracking into v_uom,v_serial,v_batch from m_product where m_product_id=v_cur.m_product_id;
            select get_uuid() into v_lineUUId;
            insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID,zspm_projecttaskbom_id)
                    values (v_lineUUId,v_client,v_Org,NOW(), v_User, NOW(),v_User,v_uid,
                        v_cur.m_locator_id,v_cur.M_Product_ID,v_Line,1,'Generated by Production->Get Machine from Stock',v_uom,v_project, v_projecttaskid,null);
            insert into snr_INTERNAL_CONSUMPTIONLINE(snr_internal_consumptionline_id, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTIONLINE_ID,serialnumber)
                    values (get_uuid(),v_client,v_Org,NOW(), v_User, NOW(),v_User,v_lineUUId,v_cur.serialnumber);
        end if; 
    END LOOP;   
    -- no lines? - delete
    if v_Line=0 then
       delete from M_INTERNAL_CONSUMPTION where M_INTERNAL_CONSUMPTION_ID=v_uid;
       v_message:='@zssm_NoStockTransactionNeededAllMaterialGot@';
    else
       if v_isserial then
          v_message:=v_message||'@zssm_MaterialReceivedSerialRegistrationNeccessary@';
       else
          if (select c_getconfigoption('activateinternalconsumptionauto',v_Org))='Y' then
                PERFORM m_internal_consumption_post(v_uid);
                select result,errormsg into v_result, v_message from ad_pinstance where ad_pinstance_id=v_uid;          
                if v_result!=1 then
                    RAISE EXCEPTION '%',v_message ;
                end if;
          end if;
          v_message:='@zssm_MaterialReceivedCompleteInWorkstep@'||zsse_htmlLinkDirectKey('../InternalMaterialMovements/InternalMaterialMovements_Relation.html',v_uid,v_DocumentNo);
       end if;
    end if;
    RETURN v_message;
END;
$_$  LANGUAGE 'plpgsql';
       
CREATE OR REPLACE FUNCTION zsmf_GetMaterialFromStockService(p_pinstance_id character varying) RETURNS void
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
Part of Manufactring

*****************************************************/

v_Message  character varying:='';
v_projecttaskid varchar;
v_User varchar;
BEGIN 
     --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_projecttaskid, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_projecttaskid is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_projecttaskid:=p_PInstance_ID;
       select updatedby into v_User from c_projecttask where c_projecttask_id=v_projecttaskid;
    end if;
     select zsmf_GetMaterialFromStock(v_projecttaskid,v_User) into v_message;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1 , v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END;
$_$  LANGUAGE 'plpgsql';

     


CREATE OR REPLACE FUNCTION zsmf_cpItemFromTask(p_pinstance_id character varying)
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
Part of Manufacturing
Copy Items from Task to Internal-Consumption
  Only Items that where Requested by Requisition and are on stock yet.
*****************************************************/
v_Record_ID  character varying;
v_ProjecttaskID character varying;
v_User    character varying;
v_org  character varying;
v_client  character varying;
v_qty numeric;
v_warehouse character varying;
v_project character varying;
v_message  character varying:= 'Success';
v_qtyonhand numeric;
v_line numeric;
v_prod character varying;
v_locator character varying;
v_uom character varying;
v_recqty numeric;
-- RECORD
v_cur record;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID,i.ad_client_id,i.ad_org_id into v_Record_ID, v_User,v_client,v_org from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    select c_projecttask_id into v_ProjecttaskID from m_internal_consumption where m_internal_consumption_id=v_Record_ID;
    select c_project.m_warehouse_id,c_project.c_project_id into v_warehouse,v_project
           from c_project,c_projecttask 
           where c_project.c_project_id=c_projecttask.c_project_id and c_projecttask.c_projecttask_id=v_ProjecttaskID;
    -- Get the Line
    select max(line) into v_line from M_INTERNAL_CONSUMPTIONLINE where M_INTERNAL_CONSUMPTION_ID=v_Record_ID;
    if v_line is null then v_line:=10; end if;
    -- See if there is mat to fetch...
    for v_cur in (select * from zspm_projecttaskbom where c_projecttask_id=v_ProjecttaskID  and qtyreceived<quantity)
    loop
      select c_uom_id into v_uom from m_product where m_product_id=v_cur.m_product_id;
        --Get Stock QTY
      select coalesce(QTYONHAND,0)-coalesce(preqtyonhand,0) as qtyavail,m_locator_id into v_qtyonhand,v_locator from m_storage_detail where m_product_id=v_cur.m_product_id and C_UOM_ID=v_uom and 
                                                            m_locator_id in (select m_locator_id from m_locator where M_WAREHOUSE_ID=v_warehouse) and
                                                            coalesce(QTYONHAND,0)-coalesce(preqtyonhand,0) >= 0 LIMIT 1;
      if v_qtyonhand >0 then
          if v_qtyonhand>v_cur.quantity-v_cur.qtyreceived then
               v_recqty:=v_cur.quantity-v_cur.qtyreceived;
          else
               v_recqty:=v_qtyonhand;
          end if;
          delete  from M_INTERNAL_CONSUMPTIONLINE  where M_INTERNAL_CONSUMPTION_ID=v_Record_ID and C_PROJECT_ID= v_project and C_PROJECTTASK_ID=v_cur.c_projecttask_id and M_PRODUCT_ID=v_cur.m_product_id;
          insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                  M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID)
                  values (get_uuid(),v_client,v_org,NOW(), v_User, NOW(),v_User,v_Record_ID,
                          v_locator,v_cur.m_product_id,v_line,v_recqty,'Projektaufgabe: Material aus Materialplanung',v_uom,v_project, v_cur.c_projecttask_id);
          v_line:=v_line+10;
          select name into v_prod from m_product where m_product_id=v_cur.m_product_id;
          v_message:=v_message||', '||v_prod||':'||v_cur.quantity;
      end if;
    END LOOP;
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
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
ALTER FUNCTION zsmf_cpItemFromTask(character varying) OWNER TO tad;




CREATE OR REPLACE FUNCTION zsmf_mintconsumption_trg()
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
Restriction-Trigger for Internal-Consumption
*****************************************************/
DECLARE
    v_snrs numeric;
    v_bomplan numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
  IF TG_OP != 'DELETE' then
      -- on Consumption for palnned serials, not more then we plan to produce...
      /*
      if new.movementtype='D-' and new.plannedserialnumber is not null and new.c_projecttask_id is not null and TG_OP = 'INSERT' then
        select qty into v_bomplan from c_projecttask where c_projecttask_id=new.c_projecttask_id and assembly='Y';
        if v_bomplan>0 and 
            (select count(*) from m_internal_consumption where c_projecttask_id=new.c_projecttask_id and m_internal_consumption_id!=new.m_internal_consumption_id and plannedserialnumber=new.plannedserialnumber)=0 
        then
            select count(distinct plannedserialnumber) into v_snrs from m_internal_consumption where c_projecttask_id=new.c_projecttask_id and m_internal_consumption_id!=new.m_internal_consumption_id;

            if v_snrs+1>v_bomplan then
               RAISE EXCEPTION '%', round(v_bomplan,0)||' @toomanypannedserials@'; 
            end if;
        end if;
      end if;
      */
      if TG_OP = 'UPDATE' then
         if old.processing!=new.processing or old.processed!=new.processed or old.posted!=new.posted then
            RETURN NEW;
         end if;
      end if;
      if new.processed='Y' or new.posted='Y' then
          RAISE EXCEPTION '%', 'Document processed/posted' ; 
      end if;
      RETURN NEW;
  else
      if old.processed='Y' or old.posted='Y' then
          RAISE EXCEPTION '%', 'Document processed/posted' ; 
      end if;
      RETURN OLD;
  end if; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
CREATE OR REPLACE FUNCTION zsmf_mintconsumptionline_trg()
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
Trigger for Internal-Consumption
Performs Reservation Cancelling
On Production Transaction this is not done! 
*****************************************************/
v_posted character varying;
v_processed character varying;
v_movementtype  character varying;
V_STOCKED       NUMERIC;
v_MOVEMENTQTY   NUMERIC;
v_QUANTITYORDER NUMERIC;
v_batchQty      NUMERIC;
v_batchno varchar;
v_cur RECORD;
v_plannedsnr varchar;
v_prj varchar;
v_prd varchar;
v_prodtsk varchar;
v_qty numeric;
v_rc snr_internal_consumptionline%rowtype;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
  IF TG_OP != 'DELETE' then
      select processed,posted into v_processed,v_posted from m_internal_consumption where m_internal_consumption_id=new.m_internal_consumption_id;
      if v_posted='Y' or v_processed='Y' then
          IF TG_OP = 'UPDATE' then
           if coalesce(old.reinvoicedby_id,'n') = coalesce(new.reinvoicedby_id,'n') and coalesce(old.zspm_projecttaskbom_id,'n') = coalesce(new.zspm_projecttaskbom_id,'n') then
              RAISE EXCEPTION '%', 'Document processed/posted' ; 
           end if;
          end if;
          if TG_OP = 'INSERT' then
             RAISE EXCEPTION '%', 'Document processed/posted' ; 
          end if;
          RETURN NEW;
      end if;
  else
      select processed,posted into v_processed,v_posted from m_internal_consumption where m_internal_consumption_id=old.m_internal_consumption_id;
      if v_posted='Y' or v_processed='Y' then
          RAISE EXCEPTION '%', 'Document processed/posted' ;
          RETURN OLD; 
      end if;
  end if; 
  -- Passing Workstep (Durchreiche AG mit SNR/CNR Verfolgung) -> Geplante SNR in Zeile einfügen
  IF TG_OP = 'INSERT' then 
    select m.plannedserialnumber,ml.c_project_id,ml.m_product_id,ml.movementqty into v_plannedsnr,v_prj,v_prd,v_qty from m_internal_consumption m,m_internal_consumptionline ml,c_project p,c_projecttask pt 
        where m.m_internal_consumption_id=ml.m_internal_consumption_id and ml.c_projecttask_id=pt.c_projecttask_id and p.c_project_id=pt.c_project_id 
        and p.projectcategory='PRO' and m.movementtype='D-' and pt.assembly='N' and ml.m_internal_consumptionline_id=new.m_internal_consumptionline_id; -- Durchreicher mit SNR/CNR (Entnahme)
    if v_plannedsnr is not null and (select count(*) from c_projecttask where c_project_id=v_prj and assembly='Y' and m_product_id=v_prd)=1 then -- Prod-Task existiert für Artikel
        select c_projecttask_id into v_prodtsk from c_projecttask where c_project_id=v_prj and assembly='Y' and m_product_id=v_prd;
        -- Wurde SNR Produziert?
        select snr.* into v_rc from snr_internal_consumptionline snr,m_internal_consumptionline l,m_internal_consumption m where l.m_internal_consumptionline_id=snr.m_internal_consumptionline_id and 
               l.m_internal_consumption_id=m.m_internal_consumption_id and l.c_project_id=v_prj and m.movementtype='P+' and m.processed='Y' and m.plannedserialnumber=v_plannedsnr limit 1;
        if v_rc.snr_internal_consumptionline_id is not null then
            if (select sum(snr.quantity) from snr_internal_consumptionline snr,m_internal_consumptionline l,m_internal_consumption m where l.m_internal_consumptionline_id=snr.m_internal_consumptionline_id and 
                           l.m_internal_consumption_id=m.m_internal_consumption_id and m.c_projecttask_id=new.c_projecttask_id  and m.processed='Y' and m.plannedserialnumber=v_plannedsnr and m.movementtype='D+' 
                           and m.description='Generated by PDC ->Send produced Material on Stock')>=
                   (select sum(snr.quantity) from snr_internal_consumptionline snr,m_internal_consumptionline l,m_internal_consumption m where l.m_internal_consumptionline_id=snr.m_internal_consumptionline_id and 
                           l.m_internal_consumption_id=m.m_internal_consumption_id and l.c_project_id=v_prj and m.movementtype='P+' and m.processed='Y' and m.plannedserialnumber=v_plannedsnr)        
            then
                RAISE EXCEPTION '%', '@plannedserialisproduced@';
            else
                v_rc.snr_internal_consumptionline_id:=get_uuid();
                v_rc.createdby:=new.createdby;
                v_rc.updatedby:=new.updatedby;
                v_rc.created:=new.created;
                v_rc.updated:=new.updated;
                v_rc.ad_org_id:=new.ad_org_id;
                v_rc.m_internal_consumptionline_id:=new.m_internal_consumptionline_id;
                v_rc.quantity:=v_qty;
                insert into snr_internal_consumptionline select v_rc.*; 
            end if;   
        else
           RAISE EXCEPTION '%', '@ThisItemWasNotProducedHere@' ; 
        end if;
    end if;
  END IF;
  --
  -- Batch Control with FIFO
  IF TG_OP = 'INSERT' then
    if (select isbatchtracking from M_PRODUCT   WHERE M_Product_ID=NEW.M_PRODUCT_ID)='Y' and
        (select c_getconfigoption('batchcontrolfifo',new.ad_org_id))='Y' 
    then
        if (select movementtype from M_Internal_Consumption where M_Internal_Consumption_id=new.M_Internal_Consumption_ID)='D-' then
            v_batchQty:=0;
            -- Load Batch No into Table
            for v_cur in (select l.qtyonhand,m.batchnumber from snr_batchlocator l,snr_batchmasterdata m where m.snr_batchmasterdata_id=l.snr_batchmasterdata_id
                                and l.m_locator_id=new.m_locator_id and m.m_product_id=new.m_product_id and l.qtyonhand>0 order by l.created)
            LOOP
                if v_batchQty<new.movementqty then
                insert into snr_internal_consumptionline(snr_internal_consumptionline_id,m_internal_consumptionline_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,quantity,lotnumber)
                    values(get_uuid(),new.m_internal_consumptionline_id,'C726FEC915A54A0995C568555DA5BB3C',new.ad_org_id,new.CREATEDBY, new.UPDATEDBY,
                    least(v_cur.qtyonhand,new.movementqty-v_batchQty),v_cur.batchnumber);
                    v_batchQty:=v_batchQty+least(v_cur.qtyonhand,new.movementqty-v_batchQty);
                end if;
            END LOOP;
         end if;
         if (select movementtype from M_Internal_Consumption where M_Internal_Consumption_id=new.M_Internal_Consumption_ID)='D+' then
            for v_cur in (select s.quantity,s.lotnumber,l.movementqty,l.m_product_id from snr_internal_consumptionline s,m_Internal_Consumptionline l,m_Internal_Consumption m where 
                           s.m_Internal_Consumptionline_id=l.m_Internal_Consumptionline_id and l.m_Internal_Consumption_id=m.m_Internal_Consumption_id
                           and l.c_projecttask_id=new.c_projecttask_id and l.m_product_id=new.m_product_id 
                           and m.m_Internal_Consumption_id=
                           (select m_Internal_Consumption_id from m_Internal_Consumption where c_projecttask_id=new.c_projecttask_id and processed='Y' and movementtype='D-' order by created desc limit 1)
                           order by l.m_product_id)
            LOOP
                if v_cur.m_product_id=new.m_product_id and v_cur.movementqty=new.movementqty then
                insert into snr_internal_consumptionline(snr_internal_consumptionline_id,m_internal_consumptionline_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,quantity,lotnumber)
                    values(get_uuid(),new.m_internal_consumptionline_id,'C726FEC915A54A0995C568555DA5BB3C',new.ad_org_id,new.CREATEDBY, new.UPDATEDBY,
                    v_cur.quantity,v_cur.lotnumber);
                end if;
            END LOOP;
         end if;
    end if;
    if (select isbatchtracking from M_PRODUCT   WHERE M_Product_ID=NEW.M_PRODUCT_ID)='Y' and
        (select c_getconfigoption('autoselectlotnumberprod',new.ad_org_id))='Y' and
        (select movementtype from M_Internal_Consumption where M_Internal_Consumption_id=new.M_Internal_Consumption_ID)='P+'
    then
        if c_getconfigoption('cnrdin', new.ad_org_id)='Y'  then
             v_batchno:=zssi_cnrcodex(trunc(now()));
        else
             select p_documentno into v_batchno from ad_sequence_doc('Batchnumber',new.ad_org_id,'Y');
        end if;
        insert into snr_internal_consumptionline(snr_internal_consumptionline_id,m_internal_consumptionline_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,quantity,lotnumber)
                   values(get_uuid(),new.m_internal_consumptionline_id,'C726FEC915A54A0995C568555DA5BB3C',new.ad_org_id,new.CREATEDBY, new.UPDATEDBY,
                   new.movementqty,v_batchno);
    end if;
  END IF;
  --
  -- Updating inventory
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    SELECT COUNT(*) INTO V_STOCKED  FROM M_PRODUCT  WHERE M_Product_ID=OLD.M_PRODUCT_ID  AND IsStocked='Y'  AND ProductType='I';
    select movementtype into v_movementtype from M_Internal_Consumption where M_Internal_Consumption_id=old.M_Internal_Consumption_ID;
    IF V_STOCKED > 0   THEN
      v_MOVEMENTQTY:= case v_movementtype when 'D-' then OLD.MOVEMENTQTY else OLD.MOVEMENTQTY*-1 end;
      v_QUANTITYORDER:= case v_movementtype when 'D-' then OLD.QUANTITYORDER else OLD.QUANTITYORDER*-1 end;
      PERFORM M_UPDATE_INVENTORY(OLD.weight, OLD.AD_ORG_ID, OLD.UPDATEDBY, OLD.M_PRODUCT_ID, OLD.M_LOCATOR_ID, OLD.M_ATTRIBUTESETINSTANCE_ID, OLD.C_UOM_ID, OLD.M_PRODUCT_UOM_ID, NULL, NULL, NULL, v_MOVEMENTQTY, v_QUANTITYORDER) ;
    END IF;
    If TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  END IF;
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    SELECT COUNT(*)  INTO V_STOCKED   FROM M_PRODUCT   WHERE M_Product_ID=NEW.M_PRODUCT_ID  AND IsStocked='Y'  AND ProductType='I';
    select movementtype into v_movementtype from M_Internal_Consumption where M_Internal_Consumption_id=new.M_Internal_Consumption_ID;
    IF V_STOCKED > 0  THEN
      v_MOVEMENTQTY:= case v_movementtype when 'D-' then NEW.MOVEMENTQTY*-1 else NEW.MOVEMENTQTY end;
      v_QUANTITYORDER:= case v_movementtype when 'D-' then NEW.QUANTITYORDER*-1 else NEW.QUANTITYORDER end;
      PERFORM M_UPDATE_INVENTORY(NEW.weight, NEW.AD_ORG_ID, NEW.UPDATEDBY, NEW.M_PRODUCT_ID, NEW.M_LOCATOR_ID, NEW.M_ATTRIBUTESETINSTANCE_ID, NEW.C_UOM_ID, NEW.M_PRODUCT_UOM_ID, NULL, NULL, NULL, v_MOVEMENTQTY, v_QUANTITYORDER) ;
    END IF;
    RETURN NEW;
  END IF;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


