
select zsse_dropfunction('zsi_ALLproductImport');
select zsse_dropfunction('zsi_productHeaderImport');
select zsse_dropfunction('zsi_productBomImport');
select zsse_dropfunction('zsi_productStockPlanningImport');
select zsse_dropfunction('zsi_productUomImport');
select zsse_dropfunction('zsi_productTrlImport');
select zsse_dropfunction('zsi_ProductPriclistImport');
select zsse_dropfunction('zsi_productPurchasePriceImport');
select zsse_dropfunction('zsi_InventoryImport()');


CREATE or replace FUNCTION  zsi_ALLproductImport(p_deleteexisting character varying) RETURNS void
AS $_$
DECLARE


BEGIN
  PERFORM zsi_productHeaderImport(p_deleteexisting);
  PERFORM zsi_productBomImport();
  PERFORM zsi_productStockPlanningImport();
  PERFORM zsi_productUomImport();
  PERFORM zsi_productTrlImport();
  PERFORM zsi_ProductPriclistImport();
  PERFORM zsi_productPurchasePriceImport();
  PERFORM zsi_productCalculationImport();
END;
$_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION  zsi_productHeaderImport(p_deleteexisting character varying) RETURNS void
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

  for v_cur in (select * from zsi_product) 
  LOOP
    select ad_org_id into v_org from ad_org where value= case when v_cur.Org_key='*' then '0' else v_cur.Org_key end;
    select m_product_category_id into v_pcategory from m_product_category where value=v_cur.pcategory_key;
    select c_uom_id into v_uom from c_uom where x12de355=v_cur.uom_key;
    select ad_user_id into v_user from ad_user  where name=v_cur.salesrep_key;
    select m_locator_id into v_locator from m_locator where value= v_cur.locator_key;
    select m_attributeset_id into v_attset from m_attributeset where name=v_cur.attributeset_key;
    select m_product_id into v_productid from m_product where value=v_cur.value;
    select c_tax_id into v_tax from c_tax where name=v_cur.tax_key;
    RAISE NOTICE '%','PR:'||v_cur.value;
    if v_productid is null then
        select get_uuid() into v_productid;
        insert into m_product(m_product_ID,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,value,
                    name,upc,description,documentnote,m_product_category_id,typeofproduct,c_uom_id,salesrep_id,producttype,isserialtracking,isbatchtracking,
                    weight,volume,shelfwidth,shelfheight,shelfdepth,unitsperpallet,m_locator_id,isstocked,isserviceitem,issparepart,
                    production,isbom,ispurchased,issold,c_tax_id,imageurl,descriptionurl,m_attributeset_id,isconsumable,manufacturer,manufacturernumber)
        values(v_productid,ad_client,v_org,now(),creator,now(),creator,v_cur.value,
              v_cur.name,v_cur.upc,replace(v_cur.description,'||',chr(13)),replace(v_cur.documentnote,'||',chr(13)),v_pcategory,v_cur.typeofproduct,v_uom,v_user,v_cur.producttype,v_cur.isserialtracking,v_cur.isbatchtracking,
              to_number(v_cur.weight),to_number(v_cur.volume),to_number(v_cur.shelfwidth),to_number(v_cur.shelfheight),to_number(v_cur.shelfdepth),to_number(v_cur.unitsperpallet),v_locator,v_cur.isstocked,v_cur.isserviceitem,v_cur.issparepart,
              v_cur.production,v_cur.isbom,v_cur.ispurchased,v_cur.issold,v_tax,v_cur.imageurl,v_cur.descriptionurl,v_attset,v_cur.isconsumable,v_cur.manufacturer,v_cur.manufacturernumber);
    else
           
       update m_product set  UPDATED=now(),UPDATEDBY=creator,name=v_cur.name,upc=v_cur.upc,description=replace(v_cur.description,'||',chr(13)),documentnote=replace(v_cur.documentnote,'||',chr(13)),m_product_category_id=v_pcategory,
                    typeofproduct=v_cur.typeofproduct,c_uom_id=v_uom,salesrep_id=v_user,producttype=v_cur.producttype,
                    weight= to_number(v_cur.weight),volume= to_number(v_cur.volume),shelfwidth= to_number(v_cur.shelfwidth),shelfheight= to_number(v_cur.shelfheight),shelfdepth= to_number(v_cur.shelfdepth),unitsperpallet= to_number(v_cur.unitsperpallet),m_locator_id=v_locator,
                    isstocked=v_cur.isstocked,isserviceitem=v_cur.isserviceitem,issparepart=v_cur.issparepart,isconsumable=v_cur.isconsumable,
                    production=v_cur.production,isbom=v_cur.isbom,ispurchased=v_cur.ispurchased,issold=v_cur.issold,c_tax_id=v_tax,imageurl=v_cur.imageurl,descriptionurl=v_cur.descriptionurl,m_attributeset_id=v_attset,
                    manufacturer=v_cur.manufacturer,manufacturernumber=v_cur.manufacturernumber,isserialtracking=v_cur.isserialtracking,isbatchtracking=v_cur.isbatchtracking
              where m_product_id=v_productid;
    end if;
    if coalesce(p_deleteexisting,'N')='Y' then
       delete from m_product_bom where m_product_id=v_productid;
       delete from m_product_po where m_product_id=v_productid;
       delete from m_product_org where m_product_id=v_productid;
       delete from m_productprice where m_product_id=v_productid;
       delete from m_product_uom where m_product_id=v_productid;
       delete from m_product_trl where m_product_id=v_productid;       
    end if;
  END LOOP;          
END;
$_$  LANGUAGE 'plpgsql';

--select bomproductvalue_key  from zsi_productbom where not exists (select 0 from m_product where value=bomproductvalue_key);;
-- delete from zsi_productbom where not exists (select 0 from m_product where value=bomproductvalue_key);;

CREATE or replace FUNCTION  zsi_productBomImport() RETURNS void
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
v_count numeric;
v_cur RECORD;
v_cur2 RECORD;

BEGIN
  for v_cur in (select distinct productvalue_key from zsi_productbom)
  LOOP
    select m_product_id,ad_org_id into v_productid,v_org from m_product where value=v_cur.productvalue_key;
    if v_productid is null then
        raise exception '%', 'Product with value: '||v_cur.productvalue_key||' does not exist. Please add the Product before importing BOM';
    end if;
    delete from m_product_bom where m_product_id=v_productid;
    v_count:=0;
    for v_cur2 in (select * from zsi_productbom where productvalue_key=v_cur.productvalue_key)
    LOOP
        if v_cur2.line is null then
            v_count:=v_count+10;
        end if;
        select m_product_id into v_productbomid from m_product where value=v_cur2.bomproductvalue_key;
        if v_productbomid is null then
            raise exception '%', 'BOM-Product with value: '||v_cur2.bomproductvalue_key||' does not exist. Please add the Product before importing BOM';
        end if;
        insert into m_product_bom (m_product_bom_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_ID,m_productbom_id,
                               line,isactive,bomqty,description,constuctivemeasure,rawmaterial)
               values(get_uuid(),ad_client,v_org,now(),creator,now(),creator,v_productid,v_productbomid,
                      coalesce(to_number(v_cur2.line),v_count),v_cur2.isactive, to_number(v_cur2.bomqty),v_cur2.description,v_cur2.constuctivemeasure,v_cur2.rawmaterial);
    END LOOP; 
  END LOOP;
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION  zsi_productStockPlanningImport() RETURNS void
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

    
    for v_cur2 in (select * from zsi_productorg)
    LOOP
        select m_product_id,ad_org_id into v_productid,v_org from m_product where value=v_cur2.productvalue_key;
        delete from m_product_org where m_product_id=v_productid;
        select m_locator_id into v_locator from m_locator where value=v_cur2.locator_key;
        select mrp_planningmethod_id into v_plningmethod from mrp_planningmethod where name=v_cur2.planingmethod_key;
        -- select ad_org_id into v_orgspec from ad_org where value=v_cur2.org_key;
         v_orgspec:=null;
        insert into m_product_org (m_product_org_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_ID,m_locator_id,mrp_planningmethod_id,
                               capacity,stockmin,isvendorreceiptlocator,qtyoptimal,isproduction)
               values(get_uuid(),ad_client,coalesce(v_orgspec,v_org),now(),creator,now(),creator,v_productid,v_locator,v_plningmethod,
                      to_number(v_cur2.capacity),to_number(v_cur2.stockmin),coalesce(v_cur2.isvendorreceiptlocator,'N'),to_number(v_cur2.qtyoptimal),coalesce(v_cur2.isproduction,'N'));
    END LOOP;
   
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION  zsi_productUomImport() RETURNS void
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

 
    for v_cur2 in (select * from zsi_productuom )
    LOOP  
        select m_product_id,ad_org_id into v_productid,v_org from m_product where value=v_cur.productvalue_key;
        delete from m_product_uom where m_product_id=v_productid;
        select c_uom_id into v_uom2 from c_uom where name=v_cur.uom_key;
        -- select ad_org_id into v_orgspec from ad_org where value=v_cur2.org_key;
        v_orgspec:=null;
        delete from m_product_uom where m_product_id=v_productid and c_uom_id=v_uom2;     
        insert into m_product_uom (m_product_uom_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_ID,c_uom_id)
               values(get_uuid(),ad_client,coalesce(v_orgspec,v_org),now(),creator,now(),creator,v_productid,v_uom2);
    END LOOP;
END;
$_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION  zsi_productTrlImport() RETURNS void
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

 
    for v_cur2 in (select * from zsi_producttrl)
    LOOP
        select m_product_id,ad_org_id into v_productid,v_org from m_product where value=v_cur.productvalue_key;
        select ad_language into v_lang from ad_language where ad_language=v_cur2.language_key;
        delete from m_product_trl where m_product_id=v_productid and ad_language=v_cur2.language_key;       
        insert into m_product_trl (m_product_trl_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_ID,ad_language,
                                   name,description,documentnote,isactive,istranslated)
               values(get_uuid(),ad_client,v_org,now(),creator,now(),creator,v_productid,v_lang,
                      v_cur2.name,v_cur2.description,v_cur2.documentnote,v_cur2.isactive,v_cur2.istranslated);
    END LOOP;
         
END;
$_$  LANGUAGE 'plpgsql';





CREATE or replace FUNCTION  zsi_ProductPriclistImport() RETURNS void
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_count numeric;
v_line numeric;
v_curr_onhand_qty numeric;
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
v_invuid character varying;
v_wh character varying;

v_cur RECORD;
v_cur2 RECORD;

BEGIN

  
    
    
    for v_cur2 in (select * from zsi_productprice)
    LOOP
        select m_product_id into v_productid from m_product where value=v_cur2.productvalue_key;
        select m_pricelist_version_id,ad_org_id into v_pversion,v_org from m_pricelist_version where name=v_cur2.pricelistversion_key;
        delete from m_productprice where m_product_id=v_productid and m_pricelist_version_id=v_pversion;
        insert into m_productprice (m_productprice_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_ID,m_pricelist_version_id,
                               isactive,pricelist,pricestd ,pricelimit)
               values(get_uuid(),ad_client,v_org,now(),creator,now(),creator,v_productid,v_pversion,
                      v_cur2.isactive,to_number(v_cur2.pricelist),to_number(v_cur2.pricestd) ,to_number(v_cur2.pricelimit));
    END LOOP;
    
  
END;
$_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION  zsi_productPurchasePriceImport() RETURNS void
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_count numeric;
v_line numeric;
v_curr_onhand_qty numeric;
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
v_invuid character varying;
v_wh character varying;

v_cur RECORD;
v_cur2 RECORD;

BEGIN

  
    for v_cur2 in (select * from zsi_productpo)
    LOOP
        select m_product_id,ad_org_id into v_productid,v_org from m_product where value=v_cur2.productvalue_key;
        select c_uom_id into v_uom2 from c_uom where name=v_cur2.uom_key;
        if coalesce(v_uom2,v_uom)=v_uom then v_uom2=null; end if;
        select c_bpartner_id into v_bpartnerid from c_bpartner where value=v_cur2.bpartnervalue_key ;
        select c_currency_id into v_currency from c_currency where iso_code=v_cur2.currency_key;
        delete from m_product_po where c_bpartner_id=v_bpartnerid and m_product_id=v_productid;
        -- PO
        insert into m_product_po(m_product_po_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_ID,c_bpartner_id,c_currency_id,c_uom_id,
                                 qualityrating,isactive,iscurrentvendor,upc,pricelist,priceeffective,order_min,deliverytime_promised,vendorproductno,vendorcategory,m_manufacturer_id,pricepo)
               values (get_uuid(),ad_client,v_org,now(),creator,now(),creator,v_productid,v_bpartnerid,v_currency,v_uom2,
                        to_number(v_cur2.qualityrating),v_cur2.isactive,v_cur2.iscurrentvendor,v_cur2.upc,to_number(v_cur2.pricelist),to_date(v_cur2.priceeffective,'DD.MM.YYYY'),to_number(v_cur2.order_min),to_number(v_cur2.deliverytime_promised),v_cur2.vendorproductno,
                        v_cur2.vendorcategory,v_cur2.manufacturer,to_number(v_cur2.pricepo));
       --update m_costing set DATETO=now() where M_PRODUCT_ID=v_productid and DATETO>now();
       --     insert into m_costing (M_COSTING_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  M_PRODUCT_ID, DATEFROM, DATETO, ISMANUAL, PRICE,  COSTTYPE,  COST)
       --            values(get_uuid(),ad_client,ad_org,creator,creator, v_productid,now(),now()+1440,'N',m_get_purchase_price(v_productid),'ST',m_get_purchase_price(v_productid));
    END LOOP;
    
END;
$_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION  zsi_productCalculationImport() RETURNS void
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_count numeric;
v_line numeric;
v_curr_onhand_qty numeric;
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
v_invuid character varying;
v_wh character varying;

v_cur RECORD;
v_cur2 RECORD;

BEGIN

  
    for v_cur2 in (select * from zsi_productcalculation)
    LOOP
        select m_product_id,ad_org_id into v_productid,v_org from m_product where value=v_cur2.productvalue_key;
        update m_costing set DATETO=now() where M_PRODUCT_ID=v_productid and DATETO>now();
            insert into m_costing (M_COSTING_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  M_PRODUCT_ID, DATEFROM, DATETO, ISMANUAL, ISPERMANENT,  COSTTYPE,  COST)
                   values(get_uuid(),ad_client,v_org,creator,creator, v_productid,now(),to_date('01.01.9999','dd.mm.yyyy'),
                   v_cur2.ISMANUAL, v_cur2.ISPERMANENT,  v_cur2.COSTTYPE,  to_number(v_cur2.COST));
    END LOOP;
    
END;
$_$  LANGUAGE 'plpgsql';



