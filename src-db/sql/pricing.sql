SELECT zsse_dropview('m_offer_v');
CREATE VIEW m_offer_v
AS
SELECT
  mo.m_offer_id AS m_offer_v_id,
  mo.m_offer_id,
  mo.m_product_po_id,
  mo.ad_client_id,
  mo.ad_org_id,
  mo.isactive,
  mo.created,
  mo.createdby,
  mo.updated,
  mo.updatedby,
  mo.name,
  mo.priority,
  mo.addamt,
  mo.discount,
  mo.fixed,
  mo.datefrom,
  mo.dateto,
  mo.bpartner_selection,
  mo.bp_group_selection,
  mo.product_selection,
  mo.prod_cat_selection,
  mo.description,
  mo.pricelist_selection,
  mo.qty_from,
  mo.qty_to,
  mo.issalesoffer,
  mo.directpurchasecalc,
  mob.c_bpartner_id,
  mop.m_product_id,
  mop.c_uom_id,
  mop.m_attributesetinstance_id,
  mop.graterequal,
  mop.lessequal,
  po.m_manufacturer_id,
  po.manufacturernumber
FROM m_offer mo
   LEFT JOIN m_offer_bpartner mob ON mob.m_offer_id = mo.m_offer_id
   LEFT JOIN m_offer_product mop ON mop.m_offer_id = mo.m_offer_id
  LEFT JOIN m_product_po po ON mop.m_product_po_id = po.m_product_po_id ;

CREATE RULE m_offer_v_delete AS ON DELETE TO public.m_offer_v
DO INSTEAD (
DELETE FROM m_offer
  WHERE m_offer.m_offer_id = old.m_offer_id;
);

CREATE RULE m_offer_v_insert AS ON INSERT TO public.m_offer_v
DO INSTEAD (
 INSERT INTO m_offer (
   m_offer_id, m_product_po_id,ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   name, priority, addamt, discount,
   fixed, datefrom, dateto,
   bpartner_selection, bp_group_selection, product_selection, prod_cat_selection,
   description, pricelist_selection, qty_from, qty_to, issalesoffer, directpurchasecalc)
  VALUES (
   new.m_offer_id, new.m_product_po_id,new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   new.name,
   COALESCE(new.priority, 0), COALESCE(new.addamt, 0), COALESCE(new.discount, 0),
   new.fixed, trunc(COALESCE(new.datefrom, now())), trunc(new.dateto),
   'N', 'Y', 'N', 'Y',
   new.description, 'Y', new.qty_from, new.qty_to, 'N', new.directpurchasecalc);
 INSERT INTO m_offer_bpartner (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_bpartner_id, c_bpartner_id)
  VALUES (
   new.m_offer_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.c_bpartner_id);
 INSERT INTO m_offer_product (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_product_id, m_product_id,c_uom_id,m_product_po_id,m_attributesetinstance_id,graterequal,lessequal)
  VALUES (
   new.m_offer_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.m_product_id,new.c_uom_id,case when new.m_manufacturer_id is not null or new.manufacturernumber is not null then new.m_product_po_id else null end,new.m_attributesetinstance_id,new.graterequal,new.lessequal);
);

CREATE RULE m_offer_v_update AS ON UPDATE TO public.m_offer_v
DO INSTEAD (
 UPDATE m_offer SET
   m_offer_id = new.m_offer_id, m_product_po_id=new.m_product_po_id,ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id,
   isactive = new.isactive, created = new.created, createdby = new.createdby, updated = new.updated, updatedby = new.updatedby,
   name = new.name, priority = new.priority, addamt = new.addamt, discount = new.discount,
   fixed = NEW.fixed, datefrom = trunc(new.datefrom), dateto = trunc(new.dateto),
   bpartner_selection = 'N', bp_group_selection = 'Y', product_selection = 'N', prod_cat_selection = 'Y',
   description = new.description, pricelist_selection = 'Y', qty_from = new.qty_from, qty_to = new.qty_to,
   issalesoffer = 'N', directpurchasecalc = new.directpurchasecalc
  WHERE m_offer.m_offer_id = new.m_offer_id;
 UPDATE m_offer_product SET
   m_offer_id = new.m_offer_id, ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id,
   isactive = new.isactive, created = new.created, createdby = new.createdby, updated = new.updated, updatedby = new.updatedby,
   m_product_id = new.m_product_id,c_uom_id=new.c_uom_id,
   m_product_po_id=case when new.m_manufacturer_id is not null or new.manufacturernumber is not null then new.m_product_po_id else null end,
   m_attributesetinstance_id=new.m_attributesetinstance_id,
   graterequal=new.graterequal,lessequal=new.lessequal
  WHERE m_offer_product.m_offer_id = new.m_offer_id AND m_offer_product.m_product_id = new.m_product_id;
 UPDATE m_offer_bpartner SET m_offer_id = new.m_offer_id, ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id,
   isactive = new.isactive, created = new.created, createdby = new.createdby, updated = new.updated, updatedby = new.updatedby,
   c_bpartner_id = new.c_bpartner_id
  WHERE m_offer_bpartner.m_offer_id = new.m_offer_id AND m_offer_bpartner.c_bpartner_id = new.c_bpartner_id;
);


SELECT zsse_dropview('m_offerplist_v');
CREATE VIEW m_offerplist_v
AS
SELECT
  mo.m_offer_id AS m_offerplist_v_id,
  mo.m_offer_id,
  mo.m_productprice_id,
  mo.ad_client_id,
  mo.ad_org_id,
  mo.isactive,
  mo.created,
  mo.createdby,
  mo.updated,
  mo.updatedby,
  mo.name,
  mo.priority,
  mo.addamt,
  mo.discount,
  mo.fixed,
  mo.datefrom,
  mo.dateto,
  mo.bpartner_selection,
  mo.bp_group_selection,
  mo.product_selection,
  mo.prod_cat_selection,
  mo.description,
  mo.pricelist_selection,
  mo.qty_from,
  mo.qty_to,
  mo.issalesoffer,
  mo.directpurchasecalc,
  mob.m_pricelist_id,
  mop.m_product_id,
  mop.c_uom_id,
  mop.m_attributesetinstance_id,
  mop.graterequal,
  mop.lessequal
FROM m_offer mo
   LEFT JOIN m_offer_pricelist mob ON mob.m_offer_id = mo.m_offer_id
   LEFT JOIN m_offer_product mop ON mop.m_offer_id = mo.m_offer_id;

CREATE RULE m_offerplist_v_delete AS ON DELETE TO public.m_offerplist_v
DO INSTEAD (
DELETE FROM m_offer
  WHERE m_offer.m_offer_id = old.m_offer_id;
);

CREATE RULE m_offerplist_v_insert AS ON INSERT TO public.m_offerplist_v
DO INSTEAD (
 INSERT INTO m_offer (
   m_offer_id, m_productprice_id,ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   name, priority, addamt, discount,
   fixed, datefrom, dateto,
   bpartner_selection, bp_group_selection, product_selection, prod_cat_selection,
   description, pricelist_selection, qty_from, qty_to, issalesoffer, directpurchasecalc)
  VALUES (
   new.m_offerplist_v_id,new.m_productprice_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   new.name,
   COALESCE(new.priority, 0), COALESCE(new.addamt, 0), COALESCE(new.discount, 0),
   new.fixed, trunc(COALESCE(new.datefrom, now())), trunc(new.dateto),
   'Y', 'Y', 'N', 'Y',
   new.description, 'N', new.qty_from, new.qty_to, 'Y', new.directpurchasecalc);
 INSERT INTO m_offer_pricelist (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_pricelist_id, m_pricelist_id)
  VALUES (
   new.m_offerplist_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.m_pricelist_id);
 INSERT INTO m_offer_product (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_product_id, m_product_id,c_uom_id,m_attributesetinstance_id,graterequal,lessequal)
  VALUES (
   new.m_offerplist_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.m_product_id,new.c_uom_id,new.m_attributesetinstance_id,new.graterequal,new.lessequal);
);

CREATE RULE m_offerplist_v_update AS ON UPDATE TO public.m_offerplist_v
DO INSTEAD (
 UPDATE m_offer SET
   m_offer_id = new.m_offer_id,m_productprice_id=new.m_productprice_id, ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id,
   isactive = new.isactive, created = new.created, createdby = new.createdby, updated = new.updated, updatedby = new.updatedby,
   name = new.name, priority = new.priority, addamt = new.addamt, discount = new.discount,
   fixed = NEW.fixed, datefrom = trunc(new.datefrom), dateto = trunc(new.dateto),
   bpartner_selection = 'Y', bp_group_selection = 'Y', product_selection = 'N', prod_cat_selection = 'Y',
   description = new.description, pricelist_selection = 'N', qty_from = new.qty_from, qty_to = new.qty_to,
   issalesoffer = 'Y', directpurchasecalc = new.directpurchasecalc
  WHERE m_offer.m_offer_id = new.m_offer_id;
  UPDATE  m_offer_product set c_uom_id=new.c_uom_id,m_attributesetinstance_id=new.m_attributesetinstance_id ,graterequal=new.graterequal,lessequal=new.lessequal
  WHERE m_offer_id = new.m_offer_id and m_product_id=new.m_product_id;
);





SELECT zsse_dropview('m_offerbpartner_v');
CREATE VIEW m_offerbpartner_v
AS
SELECT
  mo.m_offer_id AS m_offerbpartner_v_id,
  mo.m_offer_id,
  mo.ad_client_id,
  mo.ad_org_id,
  mo.isactive,
  mo.created,
  mo.createdby,
  mo.updated,
  mo.updatedby,
  mo.name,
  mo.priority,
  mo.addamt,
  mo.discount,
  mo.fixed,
  mo.datefrom,
  mo.dateto,
  mo.bpartner_selection,
  mo.bp_group_selection,
  mo.product_selection,
  mo.prod_cat_selection,
  mo.description,
  mo.pricelist_selection,
  mo.qty_from,
  mo.qty_to,
  mob.c_bpartner_id,
  mop.m_product_id,
  mop.c_uom_id,
  mop.m_attributesetinstance_id,
  mop.graterequal,
  mop.lessequal,
  mopp.m_pricelist_id,
  cat.m_product_category_id
FROM m_offer_bpartner mob,m_offer mo
   LEFT JOIN m_offer_prod_cat cat ON cat.m_offer_id = mo.m_offer_id
   LEFT JOIN m_offer_product mop ON mop.m_offer_id = mo.m_offer_id
   LEFT JOIN m_offer_pricelist mopp ON mopp.m_offer_id = mo.m_offer_id
WHERE  mob.m_offer_id = mo.m_offer_id;

CREATE RULE m_offerbpartner_v_delete AS ON DELETE TO public.m_offerbpartner_v
DO INSTEAD (
DELETE FROM m_offer
  WHERE m_offer.m_offer_id = old.m_offer_id;
);

CREATE RULE m_offerbpartner_v_insert AS ON INSERT TO public.m_offerbpartner_v
DO INSTEAD (
 INSERT INTO m_offer (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   name, priority, addamt, discount,
   fixed, datefrom, dateto,
   bpartner_selection, bp_group_selection, product_selection, prod_cat_selection,
    pricelist_selection,description, qty_from, qty_to, issalesoffer, directpurchasecalc)
  VALUES (
   new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   new.name,
   COALESCE(new.priority, 0), COALESCE(new.addamt, 0), COALESCE(new.discount, 0),
   new.fixed, trunc(COALESCE(new.datefrom, now())), trunc(new.dateto),
   'N', 'Y', 
   case when new.m_product_id is not null then 'N' else 'Y' end, 
   case when new.m_product_category_id is not null then 'N' else 'Y' end, 
   case when new.m_pricelist_id is not null then 'N' else 'Y' end, 
   new.description, new.qty_from, new.qty_to, 'Y','N');
 INSERT INTO m_offer_bpartner (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_bpartner_id, c_bpartner_id)
  VALUES (
   new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.c_bpartner_id);
);
CREATE RULE m_offerbpartner_v_insertpl AS ON INSERT TO public.m_offerbpartner_v where new.m_pricelist_id is not null
DO ALSO (
    INSERT INTO m_offer_pricelist (
    m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
    m_offer_pricelist_id, m_pricelist_id)
    VALUES (
    new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
    get_uuid(), new.m_pricelist_id);
);

CREATE RULE m_offerbpartner_v_insertpc AS ON INSERT TO public.m_offerbpartner_v where new.m_product_category_id is not null
DO ALSO (
    INSERT INTO m_offer_prod_cat (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_prod_cat_id,m_product_category_id)
  VALUES (
   new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.m_product_category_id);
);
CREATE RULE m_offerbpartner_v_insertprod AS ON INSERT TO public.m_offerbpartner_v where new.m_product_id is not null
DO ALSO (
   INSERT INTO m_offer_product (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_product_id, m_product_id,c_uom_id,m_attributesetinstance_id,graterequal,lessequal)
  VALUES (
   new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.m_product_id,new.c_uom_id,new.m_attributesetinstance_id,new.graterequal,new.lessequal);
);


CREATE RULE m_offerbpartner_v_update AS ON UPDATE TO public.m_offerbpartner_v
DO INSTEAD (
 UPDATE m_offer SET
   m_offer_id = new.m_offer_id, ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id,
   isactive = new.isactive, created = new.created, createdby = new.createdby, updated = new.updated, updatedby = new.updatedby,
   name = new.name, priority = new.priority, addamt = new.addamt, discount = new.discount,
   fixed = NEW.fixed, datefrom = trunc(new.datefrom), dateto = trunc(new.dateto),
   bpartner_selection = 'N', 
   bp_group_selection = 'Y', 
   product_selection = case when new.m_product_id is not null then 'N' else 'Y' end,
   prod_cat_selection = case when new.m_product_category_id is not null then 'N' else 'Y' end, 
   pricelist_selection = case when new.m_pricelist_id is not null then 'N' else 'Y' end, 
   description = new.description, qty_from = new.qty_from, qty_to = new.qty_to,
   issalesoffer = 'Y'
  WHERE m_offer.m_offer_id = new.m_offer_id;
 UPDATE m_offer_bpartner SET m_offer_id = new.m_offer_id, ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id,
   isactive = new.isactive, created = new.created, createdby = new.createdby, updated = new.updated, updatedby = new.updatedby,
   c_bpartner_id = new.c_bpartner_id
  WHERE m_offer_bpartner.m_offer_id = new.m_offer_id AND m_offer_bpartner.c_bpartner_id = new.c_bpartner_id;
  -- - Pricelist
  delete from m_offer_pricelist  WHERE m_offer_pricelist.m_offer_id = new.m_offer_id AND m_offer_pricelist.m_pricelist_id = old.m_pricelist_id;
  -- Product
  delete from m_offer_product  WHERE m_offer_product.m_offer_id = new.m_offer_id AND m_offer_product.m_product_id = old.m_product_id;
  -- Category
  delete from m_offer_prod_cat  WHERE m_offer_prod_cat.m_offer_id = new.m_offer_id AND m_offer_prod_cat.m_product_category_id=old.m_product_category_id;
  
);



CREATE RULE m_offerbpartner_v_updatepl AS ON UPDATE TO public.m_offerbpartner_v where new.m_pricelist_id is not null
DO ALSO (
    INSERT INTO m_offer_pricelist (
    m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
    m_offer_pricelist_id, m_pricelist_id)
    VALUES (
    new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
    get_uuid(), new.m_pricelist_id);
);

CREATE RULE m_offerbpartner_v_updatepc AS ON UPDATE TO public.m_offerbpartner_v where new.m_product_category_id is not null
DO ALSO (
    INSERT INTO m_offer_prod_cat (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_prod_cat_id,m_product_category_id)
  VALUES (
   new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.m_product_category_id);
);
CREATE RULE m_offerbpartner_v_updateprod AS ON UPDATE TO public.m_offerbpartner_v where new.m_product_id is not null
DO ALSO (
   INSERT INTO m_offer_product (
   m_offer_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
   m_offer_product_id, m_product_id,c_uom_id,m_attributesetinstance_id,graterequal,lessequal)
  VALUES (
   new.m_offerbpartner_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby,
   get_uuid(), new.m_product_id,new.c_uom_id,new.m_attributesetinstance_id,new.graterequal,new.lessequal);
);




create or replace function m_offer_restrictions_trg()
  returns trigger as
$BODY$ declare
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, Danny Heuduk 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

BEGIN
  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
    IF (new.qty_to < new.qty_from) THEN
      RAISE EXCEPTION '%', '@MSGErrorOnQty@';
    END IF;
    if new.issalesoffer='N' and new.directpurchasecalc='Y'  then 
        RAISE EXCEPTION '%', '@datanotlogic@';
    end if;
    if new.discount=100.00 then
        RAISE EXCEPTION '%', '@discount100impossible@';
    end if;
    if (select count(*) from m_offer where m_offer_id!=new.m_offer_id and name=new.name)>0 then
        RAISE EXCEPTION '%', '@duplicatename@';
    end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;
END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_droptrigger('m_offer_restrictions_trg','m_offer');

CREATE TRIGGER m_offer_restrictions_trg
  BEFORE INSERT OR UPDATE 
  ON m_offer
  FOR EACH ROW
  EXECUTE PROCEDURE m_offer_restrictions_trg();

 
/* 2012-12-04 MaHinrichs */
CREATE OR REPLACE FUNCTION  m_offer_dependent_delete_trg ()
RETURNS trigger AS
$body$
DECLARE
BEGIN
  IF (TG_OP = 'DELETE') THEN
    IF (SELECT COUNT(*) FROM c_orderline_offer olo WHERE olo.m_offer_id = OLD.m_offer_id) > 0 THEN 
      RAISE EXCEPTION '%.  (%)', '@DeleteErrorDependent@', 'Linked Items';
    END IF;
  END IF;
  
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('m_offer_dependent_delete_trg', 'm_offer');
CREATE TRIGGER m_offer_dependent_delete_trg
  BEFORE DELETE
  ON m_offer FOR EACH ROW 
  EXECUTE PROCEDURE  m_offer_dependent_delete_trg();
  
 


CREATE OR REPLACE FUNCTION m_offerpartnerproducts(i_bpartner_id varchar,i_pricelistversion varchar,OUT p_Product_ID VARCHAR,
  OUT p_PriceList numeric, OUT p_PriceStd NUMERIC,OUT p_PriceLimit numeric) RETURNS SETOF RECORD 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_cur  RECORD;
v_cur2  RECORD;
v_count numeric;

BEGIN
     for v_cur2 in (select o.m_offer_id from m_offer o,m_offer_bpartner bp where o.issalesoffer='Y' and bp.m_offer_id=o.m_offer_id and 
                                                                             bp.c_bpartner_id=i_bpartner_id)
     LOOP
      for v_cur in (select op.m_product_id, null as m_pricelist_version_id from m_offer_product op where op.m_offer_id=v_cur2.m_offer_id
                    UNION
                    select m_product_id, null as m_pricelist_version_id from m_product where issold='Y' and m_product_category_id in (select m_product_category_id from m_offer_prod_cat where  m_offer_prod_cat.m_offer_id=v_cur2.m_offer_id)
                    UNION
                    select pp.m_product_id,pv.m_pricelist_version_id from m_productprice pp,m_pricelist_version pv ,m_offer_pricelist op
                                        where pp.m_pricelist_version_id = pv.m_pricelist_version_id 
                                        and pv.m_pricelist_id=op.m_pricelist_id and op.m_offer_id=v_cur2.m_offer_id
                                        and  pv.VALIDFROM =    (SELECT max(VALIDFROM) FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=pv.m_pricelist_id and VALIDFROM<=TO_DATE(now()))
                   )
                      
      LOOP
        -- m_get_offers_price(trunc(now()),i_bpartner_id,v_cur.m_product_id,1,i_pricelistversion)
        select v_cur.m_product_id,m_bom_pricestd(v_cur.m_product_id,coalesce(v_cur.m_pricelist_version_id,i_pricelistversion)),
               m_bom_pricelist(v_cur.m_product_id,coalesce(v_cur.m_pricelist_version_id,i_pricelistversion)),
               m_bom_pricelimit(v_cur.m_product_id,coalesce(v_cur.m_pricelist_version_id,i_pricelistversion))
        into p_Product_ID,p_PriceStd,p_PriceList,p_PriceLimit
        from dual;
        return next;
      END LOOP; -- Alle selektierten Projekte
    END LOOP;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;


CREATE OR REPLACE FUNCTION m_offerpartnerpricelist(i_order_id varchar,i_productId varchar) RETURNS VARCHAR
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE

v_return varchar;
v_custom varchar;
BEGIN
     SELECT pv.M_PRICELIST_VERSION_ID  into v_return FROM M_PRICELIST_VERSION pv,c_order o 
                    WHERE o.m_pricelist_id = pv.m_pricelist_id and
                    o.c_order_id=i_order_id and  pv.VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=o.m_pricelist_id and VALIDFROM<=o.dateordered)
                    LIMIT 1;
     -- Test if Custom Pricelist
     select pv.m_pricelist_version_id into v_custom from m_productprice pp,m_pricelist_version pv ,m_offer_pricelist op,m_offer o,m_offer_bpartner bp
                                        where pp.m_pricelist_version_id = pv.m_pricelist_version_id 
                                        and pv.m_pricelist_id=op.m_pricelist_id and 
                                        o.m_offer_id=op.m_offer_id and
                                        o.issalesoffer='Y' and bp.m_offer_id=o.m_offer_id
                                        and pp.m_product_id=i_productId
                                        and bp.c_bpartner_id=(select c_bpartner_id from c_order where c_order_id=i_order_id and issotrx='Y')
                                        and  pv.VALIDFROM =    (SELECT max(VALIDFROM) FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=pv.m_pricelist_id and VALIDFROM<=TO_DATE(now()))
                                        LIMIT 1;
                      
     if v_custom is not null then
        return v_custom;
     else
        return v_return;
     end if;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;








CREATE OR REPLACE FUNCTION m_pricelist_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Default-Price (and Costs) for Items
*****************************************************/
v_prlist_id               character varying;
v_version_id              character varying;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  IF (TG_OP = 'INSERT') THEN
   if new.isdefault='Y' then
    if (select count(*) from m_pricelist where issopricelist=new.issopricelist and isdefault='Y' and ad_org_id=new.ad_org_id)>0 then
        raise exception '%','@standardPricelistIsAlreadySet@';
    end if;
   end if;
  END IF; 
  IF (TG_OP = 'UPDATE') THEN
    if new.isdefault='Y' then
       if (select count(*) from m_pricelist where issopricelist=new.issopricelist and isdefault='Y' and ad_org_id=new.ad_org_id
            and m_pricelist_id!=new.m_pricelist_id)>0 then
            raise exception '%','@standardPricelistIsAlreadySet@';
       end if;
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

  
select zsse_droptrigger('m_pricelist_trg','m_pricelist');

CREATE TRIGGER m_pricelist_trg
  BEFORE INSERT OR UPDATE 
  ON m_pricelist
  FOR EACH ROW
  EXECUTE PROCEDURE m_pricelist_trg();
  
select zsse_dropfunction('m_getSalesPriceByStdPriceListofOrg');
CREATE OR REPLACE FUNCTION m_getSalesPriceByStdPriceListofOrg(p_date timestamp without time zone, p_product_id character varying, p_qty numeric, p_uom_id varchar,p_dummy varchar,p_attributesetinstance_id varchar,p_orgid varchar)
    RETURNS NUMERIC AS  $BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
    v_cur record;
    v_date timestamp:=trunc(now());
    v_vkpl varchar;
    v_isgross varchar;
    v_vcurr varchar;
    v_price numeric;
    v_tax numeric;
BEGIN
    select m_pricelist_id,istaxincluded,c_currency_id into v_vkpl ,v_isgross,v_vcurr from m_pricelist where isdefault='Y' and isactive='Y' and issopricelist='Y' and ad_org_id=coalesce(p_orgid,'0');
    if v_vkpl is null then 
        select m_pricelist_id,istaxincluded,c_currency_id into v_vkpl ,v_isgross,v_vcurr from m_pricelist where isdefault='Y' and isactive='Y' and issopricelist='Y'  limit 1;
    end if;
    v_price:=m_get_offers_price(coalesce(p_date,v_date),null,p_product_id,p_qty,v_vkpl,'N', null, null, null,p_uom_id ,null,p_attributesetinstance_id);
    return v_price;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
 select zsse_dropfunction('m_getNetSalesPriceByStdPriceListofOrg') ;
CREATE OR REPLACE FUNCTION m_getNetSalesPriceByStdPriceListofOrg(p_date timestamp without time zone, p_product_id character varying, p_qty numeric, p_uom_id varchar,p_dummy varchar,p_attributesetinstance_id varchar,p_orgid varchar)
    RETURNS NUMERIC AS  $BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
    v_cur record;
    v_date timestamp:=trunc(now());
    v_vkpl varchar;
    v_isgross varchar;
    v_vcurr varchar;
    v_price numeric;
    v_tax numeric;
BEGIN
   v_price:=m_getSalesPriceByStdPriceListofOrg(p_date, p_product_id , p_qty , p_uom_id,null,p_attributesetinstance_id ,p_orgid );
   select m_pricelist_id,istaxincluded,c_currency_id into v_vkpl ,v_isgross,v_vcurr from m_pricelist where isdefault='Y' and isactive='Y' and issopricelist='Y' and ad_org_id=coalesce(p_orgid,'0');
    select case when reversecharge='Y' then 0 else rate end into v_tax  from c_tax where c_tax_id=zsfi_GetTax(null, p_product_id, coalesce(p_orgid,'0')) ; 
    if v_isgross='Y' and v_tax>0 then
        v_price:=c_currency_round(v_price/(1+(v_tax/100)),v_vcurr,null);
    end if;
    return v_price;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  select zsse_dropfunction('m_getBestRatedPOID');
 CREATE OR REPLACE FUNCTION m_getBestRatedPOID( p_product_id character varying, p_bpartner_id character varying, p_uom_id varchar,p_dummy varchar,p_currency varchar,p_org varchar)
   RETURNS VARCHAR AS  $BODY$ 
DECLARE 
    /***************************************************************************************************************************************************
    The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
    compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
    Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
    License for the specific language governing rights and limitations under the License.
    The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
    Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
    Contributor(s): ______________________________________.
    ***************************************************************************************************************************************************/
   -- Note: You can use the strind 'null' in p_oum_id to find the best rating independent of uom.
   -- To find the best rating independent from manufactrer , use a null value in that field
   -- To find the best rating independent from org, use the string '0' in that field
   -- To find the best rating independent from vendor, use null value in p_bpartner_id
    v_poid varchar;
    v_currency varchar;
    v_uom_id varchar;
BEGIN 
      select zsfi_getorgCurrency(p_org) into v_currency;
      if (select count(*) from m_product_uom where m_product_uom_id=p_uom_id)>0 then
        select c_uom_id into v_uom_id  from m_product_uom where m_product_uom_id=p_uom_id;
      else
        v_uom_id:=p_uom_id;
      end if;
      if coalesce(p_currency,v_currency)=v_currency then p_currency:=null; end if;
      select M_PRODUCT_PO_ID into v_poid
                   from M_PRODUCT_PO po 
                   where po.m_product_id=p_product_id  and PO.iscurrentvendor='Y' and case when p_org!='0' then PO.AD_ORG_ID in ('0',p_org) else 1=1 end 
                   and case when v_uom_id is not null then coalesce(c_uom_id,'null')=v_uom_id else c_uom_id is null end 
                   and case when p_bpartner_id is not null then po.c_bpartner_id=p_bpartner_id  else 1=1 end 
                   and  case when p_currency is not null and p_currency!=v_currency then po.c_currency_id=p_currency  
                                      when p_currency is not null and p_currency=v_currency then (po.c_currency_id=p_currency or po.c_currency_id is null) else 1=1 end 
                   order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
      return v_poid;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
   select zsse_dropfunction('m_getPurchaseCurrencyByBestRatedVendor'); 
CREATE OR REPLACE FUNCTION m_getPurchaseCurrencyByBestRatedVendor(p_product_id character varying, p_uom_id varchar,p_orgid varchar)
   RETURNS VARCHAR AS  $BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
  v_currency varchar;
  v_poid varchar;
BEGIN
   v_poid:=m_getBestRatedPOID( p_product_id,null,p_uom_id,null,null,p_orgid);
   select c_currency_id into v_currency  from m_product_po where m_product_po_id=v_poid;
   if v_currency is null then 
        select zsfi_getorgCurrency(p_orgid) into v_currency;
    end if;
    return v_currency;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_dropfunction('m_getNetPurchasePriceByBestRatedVendor');  
CREATE OR REPLACE FUNCTION m_getNetPurchasePriceByBestRatedVendor(p_date timestamp without time zone, p_product_id character varying, p_qty numeric, p_uom_id varchar,p_dummy varchar,p_attributesetinstance_id varchar,p_orgid varchar)
     RETURNS NUMERIC AS  $BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
    v_cur record;
    v_date timestamp:=trunc(now());
    v_ekpl varchar;
    v_isgross varchar;
    v_vcurr varchar;
    v_price numeric;
    v_tax numeric;
    v_vendor  varchar;
    v_qtystd numeric;
    v_qtymin numeric;
    v_uom varchar;
    v_manufacturer  varchar;
    v_loc varchar;
    v_poid varchar;
    v_mom varchar;
BEGIN
       -- Get the current vendor
       v_poid:= m_getBestRatedPOID( p_product_id,null,p_uom_id,null,null,p_orgid);
        SELECT PO.C_BPARTNER_ID,   coalesce(qtystd,0),  c_currency_id, coalesce(order_min,0),pricepo,c_uom_id,m_manufacturer_id ,manufacturernumber
        INTO           v_vendor, v_qtystd,v_vcurr,  v_qtymin, v_price  ,v_uom,v_manufacturer   ,     v_mom
        FROM M_PRODUCT_PO po  where m_product_po_id=v_poid;
        if v_vcurr is null then 
            select zsfi_getorgCurrency(p_orgid) into v_vcurr;
        end if;
        -- getting price with ID only with manufacturer 
        if v_manufacturer is null and v_mom is null then
                v_poid:=null;
        end if;
        select p.m_pricelist_id,p.istaxincluded into v_ekpl  ,v_isgross  from c_bpartner b,m_pricelist p where b.po_pricelist_id=p.m_pricelist_id and b.c_bpartner_id=v_vendor and p.c_currency_id=v_vcurr;
        if v_ekpl is null then
            select m_pricelist_id,istaxincluded  into v_ekpl ,v_isgross  from m_pricelist where  isactive='Y' and issopricelist='N' and c_currency_id=v_vcurr limit 1;
        end if;
        select c_bpartner_location_id  into v_loc  from c_bpartner_location where c_bpartner_id = v_vendor and isactive='Y' and isbillto='Y' limit 1 ;
        v_price:=m_get_offers_price(coalesce(p_date,v_date),v_vendor,p_product_id,greatest(p_qty,v_qtymin),v_ekpl,'N', null, null, null,v_uom ,v_poid,p_attributesetinstance_id);
        select case when reversecharge='Y' then 0 else rate end into v_tax  from c_tax where c_tax_id=zsfi_GetTax(v_loc, p_product_id, coalesce(p_orgid,'0')) ; 
        if v_isgross='Y' and v_tax>0 then
            v_price:=c_currency_round(v_price/(1+(v_tax/100)),v_vcurr,null);
        end if;
        return v_price;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
select zsse_dropfunction('m_getNetPurchasePriceByBestRatinginOrgCurrency');   
CREATE OR REPLACE FUNCTION m_getNetPurchasePriceByBestRatinginOrgCurrency(p_date timestamp without time zone, p_product_id character varying, p_qty numeric, p_uom_id varchar,p_dummy varchar,p_attributesetinstance_id varchar,p_orgid varchar)
    RETURNS NUMERIC AS  $BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
    v_vcurr varchar;
     v_Orgvcurr varchar;
     v_convprice numeric;
     v_price numeric;
BEGIN
    select zsfi_getorgCurrency(p_orgid) into v_Orgvcurr;
    select  m_getNetPurchasePriceByBestRatedVendor(p_date , p_product_id , p_qty , p_uom_id ,p_dummy ,p_attributesetinstance_id ,p_orgid) into v_price;
    select m_getPurchaseCurrencyByBestRatedVendor(p_product_id , p_uom_id  ,p_orgid) into v_vcurr;
    v_convprice:=c_currency_convert(v_price,v_vcurr,v_Orgvcurr,p_date);
    return v_price;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
CREATE OR REPLACE FUNCTION m_copypricelistversion(p_PInstance_ID character varying) RETURNS void 
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
v_uid varchar;
v_name varchar;
v_valid date;
v_cur record;
v_xt m_productprice%rowtype;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    FOR v_cur IN
          (SELECT para.* FROM ad_pinstance pi, ad_pinstance_Para para WHERE pi.ad_pinstance_ID = para.ad_pinstance_ID   AND pi.ad_pinstance_ID = p_pinstance_ID
           ORDER BY para.SeqNo)
    LOOP
        IF ( UPPER(v_cur.parametername) = UPPER('validfrom') ) THEN
            v_valid := v_cur.p_date;
        END IF;
        IF ( UPPER(v_cur.parametername) = UPPER('name') ) THEN
            v_name := v_Cur.p_string;
        END IF;
    END LOOP; -- Get Parameter
    if v_name is not null and v_valid is not null then
        v_uid:=get_uuid();
        insert into m_Pricelist_Version(m_pricelist_version_id, ad_client_id, ad_org_id, createdby, updatedby, name, description, m_pricelist_id, validfrom)
        select v_uid,ad_client_id,ad_org_id,v_User,v_User, v_name,description,m_pricelist_id,v_valid from m_Pricelist_Version where m_Pricelist_Version_id=v_Record_ID;
        for v_cur in (select * from m_productprice where m_Pricelist_Version_id=v_Record_ID)
        LOOP
            select * into v_xt from m_productprice where m_productprice_id=v_cur.m_productprice_id;
            v_xt.m_productprice_id:=get_uuid();
            v_xt.m_Pricelist_Version_id:=v_uid; 
            insert into m_productprice  select v_xt.*;
        END LOOP;
     end if;
        
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
