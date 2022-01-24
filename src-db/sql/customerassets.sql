CREATE or replace FUNCTION ca_offerbuyback(bPartnerId varchar,productId varchar,pQty varchar,p_order varchar) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Get From Standard Sales Pricelist the Offer Price for a specific Product, Partner and QTY
ONLY SALES!
*****************************************************/
  
  v_plo   character varying;
  v_pl character varying;
  v_plvid character varying;
  v_price numeric;
  v_factor NUMERIC;
  v_orderdate timestamp;
  BEGIN
  if productId is not null then
    select M_PRICELIST_ID,trunc(dateordered) into v_plo,v_orderdate from c_order where c_order_id=p_order;
    if v_plo is null then
        select M_PRICELIST_ID into v_plo from m_pricelist where isdefault='Y' and issopricelist='N' and isactive ='Y';
    end if;
    if v_plo is null then
        raise exception 'No Pricelist found';
    end if;
    SELECT M_PRICELIST_ID into v_pl from m_pricelist where  issopricelist='Y' and c_currency_id=(select c_currency_id from m_pricelist where m_pricelist_id=v_plo) and isactive='Y' order by isdefault desc limit 1;
    SELECT M_PRICELIST_VERSION_ID INTO v_plvid  FROM M_PRICELIST_VERSION
                    WHERE M_PRICELIST_ID=v_pl and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=v_pl and VALIDFROM<=TO_DATE(coalesce(v_orderdate,NOW()))); 
    SELECT m_bom_pricestd(productId, v_plvid) into v_price;
    select discount into v_factor from m_offer where name='Ankaufsangebot';
    if v_factor is null then 
        insert into m_offer (M_OFFER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME,  ADDAMT, DISCOUNT,  DATEFROM,  BPARTNER_SELECTION, BP_GROUP_SELECTION,
                            PRODUCT_SELECTION, PROD_CAT_SELECTION,  PRICELIST_SELECTION, ISSALESOFFER, DIRECTPURCHASECALC)
        values (get_uuid(),'C726FEC915A54A0995C568555DA5BB3C','0','0','0','Ankaufsangebot',0,0,trunc(now()),'N','N','N','N','N','N','N');
    end if;
    select o.discount into v_factor from m_offer o,m_offer_prod_cat p,m_product mp where o.m_offer_id=p.m_offer_id and 
                           p.m_product_category_id=mp.m_product_category_id and mp.m_product_id=productId and o.name='Ankaufsangebot';
    if v_factor is null then
        v_factor:=10;
    end if;    
    v_price:=v_price/(100+v_factor)*100;
    raise notice '%',v_price||'#'||v_factor;
    --v_price:=v_price-v_price*(v_factor/(100+v_factor));
  end if;
  RETURN round(coalesce(v_price,0),2);
END;
$_$  LANGUAGE 'plpgsql';

select zsse_DropFunction ('ca_assetstockedSetQty_onhand');


select zsse_DropView ('ca_freebulkpositions_v');
create or replace view ca_freebulkpositions_v as
-- Purchase and Sales
select ca_freebulkpositions_v_id,m_warehouse_id,isactive,m_product_id,ad_org_id,ad_client_id,updated, updatedby,created, createdby,c_uom_id,freeqty from
(
  select p.m_product_id||w.m_warehouse_id as ca_freebulkpositions_v_id,w.m_warehouse_id,w.isactive,
       p.m_product_id,w.ad_org_id,w.ad_client_id,p.updated, p.updatedby,p.created, p.createdby,p.c_uom_id,
       round(m_bom_qty_onhand(p.m_product_id,w.m_warehouse_id) - coalesce(sum(ast.actualqty),0),3) as freeqty
       from m_product p left join CA_Assetsstocked ast on ast.m_product_id=p.m_product_id and ast.statusref ='DELIVERED',
            m_warehouse w
       where m_bom_qty_onhand(p.m_product_id,w.m_warehouse_id,null)>0 and 
             coalesce(ast.m_warehouse_id,w.m_warehouse_id)=w.m_warehouse_id and
             p.producttype='I' and p.isserialtracking='N' and p.issetitem='N' and p.isstocked='Y'
       group by  p.m_product_id,w.m_warehouse_id,w.isactive,w.ad_org_id,w.ad_client_id,p.updated, p.updatedby,p.created, p.createdby,p.c_uom_id
) a where freeqty >0;

select zsse_DropView ('ca_overbookedbulkpositions_v');
create or replace view ca_overbookedbulkpositions_v as
-- Purchase and Sales
select * from 
       (select p.m_product_id||w.m_warehouse_id as ca_overbookedbulkpositions_v_id,w.m_warehouse_id,w.isactive,
       p.m_product_id,w.ad_org_id,w.ad_client_id,p.updated, p.updatedby,p.created, p.createdby,p.c_uom_id,
       round((m_bom_qty_onhand(p.m_product_id,w.m_warehouse_id,null) - coalesce(sum(ast.actualqty),0))*-1,3) as overbookedqty
       from m_product p , CA_Assetsstocked ast ,  m_warehouse w
       where ast.m_product_id=p.m_product_id and ast.statusref = 'DELIVERED' and 
             coalesce(ast.m_warehouse_id,w.m_warehouse_id)=w.m_warehouse_id and
             p.producttype='I' and p.isserialtracking='N' 
       group by  p.m_product_id,w.m_warehouse_id,w.isactive,w.ad_org_id,w.ad_client_id,p.updated, p.updatedby,p.created, p.createdby,p.c_uom_id
       ) a where overbookedqty>0;       

select zsse_DropView ('ca_freeassets_v');
create or replace view ca_freeassets_v as
-- Purchase and Sales
select snr.snr_masterdata_id as ca_freeassets_v_id,
       snr.m_product_id,snr.ad_org_id,snr.ad_client_id,snr.updated, snr.updatedby, snr.created, snr.createdby,
       snr.serialnumber,snr.m_locator_id,snr.isactive
       from snr_masterdata snr
       where not exists (select 0 from CA_Assetsstocked ast where snr.snr_masterdata_id=ast.snr_masterdata_id and ast.statusref != 'SOLD')
             and snr.m_locator_id is not null
       order by snr.created desc;
 
select zsse_DropView ('ca_lostassets_v');
create or replace view ca_lostassets_v as
-- Purchase and Sales
select snr.snr_masterdata_id as ca_lostassets_v_id,ast.CA_Assetsstocked_id,snr.snr_masterdata_id,
       snr.m_product_id,snr.ad_org_id,snr.ad_client_id,snr.updated, snr.updatedby, snr.created, snr.createdby,
       snr.serialnumber,snr.isactive
       from snr_masterdata snr,CA_Assetsstocked ast  where snr.snr_masterdata_id=ast.snr_masterdata_id and ast.statusref = 'DELIVERED'
            and snr.m_locator_id is null
       order by snr.created desc;
  
 

select zsse_DropView ('ca_customerassets_v');
create or replace view ca_customerassets_v as
select min(ast.ca_assetsstocked_id) as ca_customerassets_v_id,'Y'::bpchar as isactive,
       p.m_product_id,'0' as ad_org_id,'C726FEC915A54A0995C568555DA5BB3C' as ad_client_id,now() as updated, '0' as updatedby,now() as created, '0' as createdby,
       '' as snr_masterdata_id, coalesce(sum(ast.actualqty),0) as qty,ast.c_bpartner_id,
       zssi_getproductname(p.m_product_id,null)||' - Menge: '||coalesce(sum(ast.actualqty),0) as description
       from m_product p , CA_Assetsstocked ast 
       where ast.m_product_id=p.m_product_id  and 
             p.producttype='I' and p.isserialtracking='N' and p.issetitem='N' and ast.statusref='DELIVERED'
       group by  ast.c_bpartner_id,p.m_product_id
UNION
select snr.snr_masterdata_id as ca_customerassets_v_id,ast.isactive,
       snr.m_product_id,snr.ad_org_id,snr.ad_client_id,snr.updated, snr.updatedby, snr.created, snr.createdby,
       snr.snr_masterdata_id,1 as qty,ast.c_bpartner_id,
       zssi_getproductname(snr.m_product_id,null)||' vom '||to_char(ast.dateordered,'dd.mm.yyyy')||' - Menge: 1' as description
       from snr_masterdata snr,CA_Assetsstocked ast where snr.snr_masterdata_id=ast.snr_masterdata_id  and ast.statusref='DELIVERED';
--  - Ankaufwert:'||ca_offerbuyback(ast.c_bpartner_id,snr.m_product_id,'1',null) // Entfernt wegen Tuning
       
CREATE OR REPLACE FUNCTION CA_Assetsstocked_trg() RETURNS trigger
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
v_text varchar;    
v_desc varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    select name into v_text from m_product where m_product_id=new.m_product_id;
    v_desc:=v_text;
    select serialnumber  into v_text from snr_masterdata where snr_masterdata_id=new.snr_masterdata_id;
    if v_text is not null then 
        v_desc:=v_desc||'-'||v_text;
    end if;
    v_text:=to_char(new.dateordered,'dd.mm.yyyy');
    v_desc:=v_desc||' vom '||v_text;
    if new.description is null then
        new.description:= v_desc;
    end if;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('CA_Assetsstocked_trg','CA_Assetsstocked');

CREATE TRIGGER CA_Assetsstocked_trg
  BEFORE INSERT OR UPDATE
  ON CA_Assetsstocked FOR EACH ROW
  EXECUTE PROCEDURE CA_Assetsstocked_trg();
 


CREATE OR REPLACE FUNCTION CA_offer_trg() RETURNS trigger
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
v_text varchar;    
v_count numeric;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF new.name!=old.name and new.name='Ankaufsangebot' then
            RAISE EXCEPTION '%','Der Datensatz für das Ankaufsangebot wird automatisch angelegt. Bitte einmal einen Ankaufsauftrag eingeben. Dann die automatisch erstellte Preisgestaltung ändern. Den Namen nicht ändern.';
        end if;
    END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('CA_offer_trg','M_OFFER');

CREATE TRIGGER CA_offer_trg
  BEFORE INSERT OR UPDATE
  ON M_OFFER FOR EACH ROW
  EXECUTE PROCEDURE CA_offer_trg();
  
  
  
  
  
CREATE or replace FUNCTION ca_getproductfromauxtext(v_auxtext character varying) RETURNS character varying
AS $_$
DECLARE
v_return character varying;
BEGIN
      select m_product_id into v_return from ca_assetsstocked where ca_assetsstocked_id=substr(v_auxtext,1,32);
      if v_return is null then 
          select m_product_id into v_return from snr_masterdata where snr_masterdata_id=v_auxtext;
      end if;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
 