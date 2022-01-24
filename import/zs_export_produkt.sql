select zsse_dropfunction('zsi_productHeaderExport');


CREATE or replace FUNCTION  zsi_productHeaderExport() RETURNS void
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_org character varying;
v_pcategory character varying;
v_locator character varying;
v_lang character varying;
v_attset character varying;
v_plningmethod character varying;
v_currency character varying;
v_tax character varying;
v_salesregion character varying;
v_productbomid character varying;
v_uom character varying;
v_uom2 character varying;
v_pricelist character varying;
v_pversion character varying;
v_user character varying;
v_productid character varying;
v_bpartnerid character varying;
v_orgspec  character varying;

v_cur RECORD;
v_cur2 RECORD;

BEGIN

  for v_cur in (select * from m_product) 
  LOOP 
        select case when v_cur.ad_org_id='0' then '*' else (select value from ad_org where ad_org_id=v_cur.ad_org_id) end into v_org;
        select value into v_pcategory from m_product_category where m_product_category_id=v_cur.m_product_category_id;
        select name into v_uom from c_uom where c_uom_id=v_cur.c_uom_id;
        select name into v_user from ad_user  where ad_user_id=v_cur.salesrep_id;
        select value into v_locator from m_locator where m_locator_id= v_cur.m_locator_id;
        select name into v_attset from m_attributeset where m_attributeset_id=v_cur.m_attributeset_id;
        select name into v_tax from c_tax where c_tax_id=v_cur.c_tax_id;
        
        insert into zsi_product(VALUE, NAME, ORG_KEY, UPC, DESCRIPTION, DOCUMENTNOTE, PCATEGORY_KEY, PRODUCTTYPE, UOM_KEY, SALESREP_KEY, TYPEOFPRODUCT,
         WEIGHT, VOLUME, SHELFWIDTH, SHELFHEIGHT, SHELFDEPTH, UNITSPERPALLET, LOCATOR_KEY, ISSTOCKED, ISSERVICEITEM, ISSPAREPART, ISCONSUMABLE, PRODUCTION,
         ISBOM, ISPURCHASED, ISSOLD, TAX_KEY, IMAGEURL, DESCRIPTIONURL, ATTRIBUTESET_KEY)
         values(v_cur.value,v_cur.name, v_org,v_cur.upc, v_cur.DESCRIPTION, v_cur.DOCUMENTNOTE,v_pcategory,v_cur.PRODUCTTYPE,v_uom,v_user,v_cur.TYPEOFPRODUCT,
         v_cur.WEIGHT, v_cur.VOLUME, v_cur.SHELFWIDTH, v_cur.SHELFHEIGHT, v_cur.SHELFDEPTH,v_cur.UNITSPERPALLET,v_locator,v_cur.ISSTOCKED,v_cur.ISSERVICEITEM, v_cur.ISSPAREPART, v_cur.ISCONSUMABLE, v_cur.PRODUCTION,
         v_cur.ISBOM, v_cur.ISPURCHASED, v_cur.ISSOLD, v_tax,v_cur.IMAGEURL, v_cur.DESCRIPTIONURL, v_attset);
  END LOOP;          
  copy zsi_product to '/tmp/Product.csv' with CSV DELIMITER as ';' HEADER;
END;
$_$  LANGUAGE 'plpgsql';
 
