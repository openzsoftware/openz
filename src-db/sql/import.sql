select zsse_DropView ('i_pricelist_v');
CREATE OR REPLACE VIeW i_pricelist_v as
select pp.M_PRICELIST_VERSION_ID||pp.M_PRODUCT_ID||coalesce(pp.C_UOM_ID,'') as i_pricelist_v_id,
 pp.M_PRICELIST_VERSION_ID,
 p.value,
 p.name,
 p.AD_CLIENT_ID,
 pp.AD_ORG_ID,
 pp.CREATEDBY,
 pp.created,
 pp.UPDATEDBY,
 pp.updated,
 pp.isactive,
 pp.PRICELIST,
 pp.PRICESTD,
 pp.PRICELIMIT,
 pp.C_UOM_ID,
 (SELECT PO.C_BPARTNER_ID FROM M_PRODUCT_PO po  WHERE po.m_product_id=p.M_Product_ID and PO.isactive='Y'  and po.iscurrentvendor='Y' and PO.AD_ORG_ID in ('0',pp.ad_org_id) ORDER BY COALESCE(po.qualityrating,0) DESC, updated DESC LIMIT 1) as c_bpartner_id,
 (SELECT PO.pricepo FROM M_PRODUCT_PO po  WHERE po.m_product_id=p.M_Product_ID and PO.isactive='Y'  and po.iscurrentvendor='Y' and PO.AD_ORG_ID in ('0',pp.ad_org_id) ORDER BY COALESCE(po.qualityrating,0) DESC, updated DESC LIMIT 1) as pricepo
 from m_productprice pp,m_product p where p.m_product_id=pp.m_product_id;


CREATE or replace FUNCTION  i_import_pricelist(p_filename varchar,p_user varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_org character varying;
v_pversion character varying;
v_productid varchar;
v_cuom_id varchar;
v_cur2 RECORD;
v_cmd varchar;
v_i numeric:=0;
BEGIN
 if p_filename is null then return 'ERROR'; end if;
  delete from i_productpriceimport;
  -- Datei in Tabelle
  v_cmd := 'COPY i_productpriceimport  FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER ;';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);

    for v_cur2 in (select * from i_productpriceimport)
    LOOP
        select m_product_id into v_productid from m_product where value=v_cur2.productvalue_key;
        select m_pricelist_version_id,ad_org_id into v_pversion,v_org from m_pricelist_version where name=v_cur2.pricelistversion_key;
        select c_uom_id into v_cuom_id from c_uom where name = v_cur2.c_uom_id;
        if(v_cuom_id is null) then
            select c_uom_id into v_cuom_id from c_uom_trl where name = v_cur2.c_uom_id limit 1;
        end if;
        if(v_cuom_id is null and v_cur2.c_uom_id is not null) then
            raise exception '%', '@UOMNotFound@: ' || v_cur2.c_uom_id;
        end if;
        if v_pversion is null  or v_productid is null then
            raise exception '%', 'No Data Found for Pricelist:'||coalesce(v_cur2.pricelistversion_key,'NULL')||' and Product: '||coalesce(v_cur2.productvalue_key,'NULL');
        end if;
        delete from m_productprice where m_product_id=v_productid and m_pricelist_version_id=v_pversion and coalesce(c_uom_id,'')=coalesce(v_cuom_id,'');
        insert into m_productprice (m_productprice_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, m_product_ID, m_pricelist_version_id,
                               isactive, pricelist, pricestd, pricelimit, C_UOM_ID)
               values(get_uuid(), ad_client, v_org,now(), p_user,now(), p_user,v_productid, v_pversion,
                      'Y', to_number(v_cur2.pricelist), to_number(v_cur2.pricestd), to_number(v_cur2.pricelimit), v_cuom_id);
        v_i:=v_i+1;
    END LOOP;
    return v_i||' Positionen in Preisliste importiert';  
END;
$_$  LANGUAGE 'plpgsql';


    
select zsse_DropView ('i_product_v');
CREATE OR REPLACE VIeW i_product_v as
select M_PRODUCT_ID as i_product_v_id,
 AD_CLIENT_ID,
 AD_ORG_ID,
 CREATEDBY,
 created,
 UPDATEDBY,
 updated,
 isactive,
 imageurl ,
 value ,
 name ,
  descriptionurl ,
   upc ,
 description ,
 documentnote ,
 c_uom_id ,
 isstocked ,
 m_product_category_id ,
 volume ,
 weight ,
 shelfwidth ,
 shelfheight ,
 shelfdepth ,
 unitsperpallet ,
 discontinued ,
 discontinuedby ,
 producttype ,
 m_attributeset_id ,
 m_locator_id ,
  ispurchased ,
 issold ,
 isbom ,
 calculated ,
 production ,
 c_tax_id ,
 typeofproduct ,
 isserviceitem ,
 isconsumable ,
 issparepart ,
 isfreightproduct ,
 issetitem ,
 isserialtracking ,
 isbatchtracking ,
 cusomstarifno ,
 c_country_id ,
 basepriceunit ,
 basepricemultiplicator,
 manufacturer,
 manufacturernumber,
 customerproducttext
 from m_product;

 
CREATE or replace FUNCTION  i_import_product(p_filename varchar,p_user varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE
-- Crazy dynamical import format stuff...
v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_org character varying;
v_pversion character varying;
v_productid varchar;
v_pcat varchar;
v_cur2 RECORD;
v_cur RECORD;
v_fieldlist varchar:='';
v_cmd varchar:='';
v_i numeric:=0;
v_ii numeric:=0;
v_uom varchar;
v_type varchar;
v_ptype varchar;
v_locat varchar;
v_country varchar;
v_tax varchar;
v_bpuom varchar;
v_lang varchar;
v_ResultStr varchar;
v_fieldscontainer varchar;
v_isactive varchar;
v_isstocked varchar;
BEGIN
    if p_filename is null then return 'ERROR'; end if;
    perform zsse_droptable ('i_productimport');
    -- Dynamisches allozieren der Felder
    -- Format anziehen (TAB: Export Product)
    for v_cur in (select pname,pad_ref_fieldcolumn_id from ad_selecttabfields('DE_de','2B0EEFDD3CA54CB5B6F49CE7963D829D') order by pline)
    LOOP
        if ad_fieldGetVisibleLogic(v_cur.pad_ref_fieldcolumn_id,'')='VISIBLE'  then         
            if v_cmd='' then v_cmd := 'create temporary table i_productimport('; else v_cmd := v_cmd ||' , ';  end if;
            if v_cur.pname not in ('AD_Org_ID','Value','Name','M_Product_Category_ID','Typeofproduct','C_Uom_ID','Producttype','C_Country_ID','C_Tax_ID','Basepriceunit','M_Locator_ID','xapi_parentproduct','xapi_parentproductvalue','xapi_attributeset','xapi_attributesetinstance') then
                if v_fieldlist!='' then v_fieldlist:=v_fieldlist||','; end if;
                if (select data_type from information_schema.columns where table_name='m_product' and column_name=lower(v_cur.pname))='numeric' then
                    v_fieldlist:=v_fieldlist||v_cur.pname||'=to_number(a.'||v_cur.pname||')';
                elseif (select data_type from information_schema.columns where table_name='m_product' and column_name=lower(v_cur.pname))='timestamp without time zone' then
                    v_fieldlist:=v_fieldlist||v_cur.pname||'=to_date(a.'||v_cur.pname||')';
                else
                    v_fieldlist:=v_fieldlist||v_cur.pname||'=a.'||v_cur.pname;
                end if;
            end if;
            v_cmd := v_cmd ||v_cur.pname||' text';
        end if;
    END LOOP;
    v_cmd := v_cmd ||' )  ON COMMIT DROP';
    EXECUTE(v_cmd);
    v_fieldscontainer:=v_cmd;
    -- Datei in Tabelle
    v_cmd := 'COPY i_productimport  FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER ;';
    EXECUTE(v_cmd);
    v_cmd := 'alter table i_productimport add column idds character varying(32) not null default get_uuid()';
    EXECUTE(v_cmd);
    select ad_language into v_lang from ad_client  where ad_client_id=v_client;    
    for v_cur2 in (select * from i_productimport)
    LOOP
        /*
        Checks for Mandatory Fields  
        */
        select ad_org_id into v_org from ad_org where name=v_cur2.ad_org_id;
        if v_cur2.ad_org_id='*' then v_org:='0'; end if;
        if v_org is null then
            raise exception '%', 'Organization not Found:'||v_cur2.ad_org_id;
        end if;
        select m_product_id into v_productid from m_product where value=v_cur2.value and ad_org_id in ('0',v_org);
        select m_product_category_id into v_pcat from m_product_category where name=v_cur2.m_product_category_id;        
        if v_pcat is null then
            raise exception '%', 'Product Category not Found:'||v_cur2.m_product_category_id;
        end if;
        select value into v_type from ad_ref_list where ad_reference_id='D3CE5ED8E56C43E19FA09D10B616BCAA' and name=v_cur2.typeofproduct;
        if  v_type is null then
            select a.value into v_type from ad_ref_list_trl t, ad_ref_list a where t.ad_language = 'de_DE' and a.ad_reference_id='D3CE5ED8E56C43E19FA09D10B616BCAA' and t.name=v_cur2.typeofproduct and t.ad_ref_list_id = a.ad_ref_list_id;
        end if;
        if  v_type is null then
            select ad_ref_listinstance.value into v_type from ad_ref_listinstance,ad_ref_list where ad_ref_list.ad_ref_list_id=ad_ref_listinstance.ad_ref_list_id and 
            ad_ref_list.ad_reference_id='D3CE5ED8E56C43E19FA09D10B616BCAA' and ad_ref_listinstance.name=v_cur2.typeofproduct;
        end if;
        if  v_type is null then
            select ad_ref_listinstance_trl.value into v_type from ad_ref_listinstance_trl,ad_ref_listinstance,ad_ref_list where 
             ad_ref_list.ad_ref_list_id=ad_ref_listinstance.ad_ref_list_id and ad_ref_listinstance_trl.ad_ref_listinstance_id=ad_ref_listinstance.ad_ref_listinstance_id
             and ad_ref_list.ad_reference_id='D3CE5ED8E56C43E19FA09D10B616BCAA' and ad_ref_listinstance_trl.name=v_cur2.typeofproduct limit 1;
        end if;
        if  v_type is null then
            raise exception '%', 'Product Type not Found - :'||v_cur2.typeofproduct;
        end if;
        select c_uom_id into v_uom from c_uom where name=v_cur2.c_uom_id;
        if  v_uom is null then
            select c_uom_id into v_uom from c_uom_trl where ad_language = 'en_US' and name=v_cur2.c_uom_id; 
        end if;
        if  v_uom is null then
            select c_uom_id into v_uom from c_uom_trl where ad_language = v_lang and name=v_cur2.c_uom_id; 
        end if;
        if  v_uom is null then
            raise exception '%', 'Unit of Measure not Found:'||v_cur2.c_uom_id;
        end if;
        select value into v_ptype from ad_ref_list where ad_reference_id='270' and name=v_cur2.producttype;
        if  v_ptype is null then
            select a.value into v_ptype from ad_ref_list_trl t, ad_ref_list a where t.ad_language = 'en_US' and a.ad_reference_id='270' and t.name=v_cur2.producttype and t.ad_ref_list_id = a.ad_ref_list_id;
        end if;
        if  v_ptype is null then
           select a.value into v_ptype from ad_ref_list_trl t, ad_ref_list a where t.ad_language = v_lang and a.ad_reference_id='270' and t.name=v_cur2.producttype and t.ad_ref_list_id = a.ad_ref_list_id;
        end if;
        if  v_ptype is null then
            raise exception '%', 'Type of Product not Found:'||v_cur2.producttype;
        end if;
        BEGIN -- try catch mandatory field isstocked
            select coalesce(v_cur2.isstocked, 'Y') into v_isstocked;
        EXCEPTION
            -- field not in record
            WHEN OTHERS THEN
                v_isstocked := 'Y';
        END;
        BEGIN -- try catch mandatory field isactive
            select coalesce(v_cur2.isactive, 'Y') into v_isactive;
        EXCEPTION
            -- field not in record
            WHEN OTHERS THEN
                v_isactive := 'Y';
        END;
        /*
        Checks for NON Mandatory Fields  
        */
        select m_locator_id into v_locat from m_locator where value=v_cur2.m_locator_id limit 1;
        if instr(v_fieldscontainer,'C_Country_ID')>0 then
            select c_country_id into v_country from c_country where name=v_cur2.c_country_id;
            if  v_country is null then
                select c_country_id into v_country from c_country_trl where name=v_cur2.c_country_id limit 1;
            end if;
        end if;
        if instr(v_fieldscontainer,'C_Tax_ID')>0 then
            if v_cur2.c_tax_id is not null then
                select c_tax_id into v_tax from c_tax where name=v_cur2.c_tax_id;
                if  v_tax is null then
                    select c_tax_id into v_tax from c_tax_trl where ad_language = 'en_US' and name=v_cur2.c_tax_id;
                end if;
                if  v_tax is null then
                    select c_tax_id into v_tax from c_tax_trl where ad_language = v_lang and name=v_cur2.c_tax_id;
                end if;
            end if;
        end if;
        if instr(v_fieldscontainer,'Basepriceunit')>0 then 
            if v_cur2.basepriceunit is not null then
                select c_uom_id into v_bpuom from c_uom where name=v_cur2.basepriceunit;
                if  v_bpuom is null then
                    select c_uom_id into v_bpuom from c_uom_trl where ad_language = 'en_US' and name=v_cur2.basepriceunit;
                end if;
                if  v_bpuom is null then
                    select c_uom_id into v_bpuom from c_uom_trl where ad_language = v_lang and name=v_cur2.basepriceunit;
                end if;
            end if;
        end if;
        v_ResultStr:=v_cur2.value;
        v_i:=v_i+1;
        if v_productid is null then
            v_productid:=get_uuid();
            insert into m_product(ad_org_id ,  value , name ,  m_product_category_id ,typeofproduct , c_uom_id ,  producttype , c_country_id, c_tax_id , basepriceunit,m_locator_id,
                                  CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_ID,ad_client_id, isactive, isstocked)
                        values   (v_org, v_cur2.value , v_cur2.name ,v_pcat,v_type,v_uom,v_ptype,v_country , v_tax , v_bpuom,v_locat,
                                  now(),p_user,now(),p_user,v_productid,v_client, v_isactive, v_isstocked);
            v_ii:=v_ii+1;
        else
            update m_product set ad_org_id=v_org , value =v_cur2.value, name =v_cur2.name,  m_product_category_id =v_pcat,
                                  typeofproduct=v_type ,   producttype=v_ptype , c_country_id =v_country, c_tax_id=v_tax ,basepriceunit =v_bpuom,m_locator_id= v_locat,
                                  updated=now(),updatedby=p_user  where m_product_id=v_productid;
           -- UOM not read only?
           -- -> no transactions or orders with this product
           if (select is_product_unit_read_only(v_productid, 'IMPORT')) = 'N' then
             update m_product set c_uom_id=v_uom  where m_product_id=v_productid;
           end if;
        end if;        
        update i_productimport set idds=v_productid where idds=v_cur2.idds;
        -- Dynamic Update rest of fields
        -- one update per product to catch and display errors
        v_cmd := 'update m_product set '||v_fieldlist||' from i_productimport a where a.idds=m_product.m_product_id and a.idds='''|| v_productid ||'''';       
        RAISE notice '%', v_cmd;
        EXECUTE(v_cmd);
    
        -- for xml api, fields only active with module
        if(exists(select * from ad_module where name='OpenZ-XML-API' and version_label>'3.8.20.506') and (select isactive='Y' from ad_module where name='OpenZ-XML-API')) then
          -- xapi fields, fieldname != tablename -> Daten müssen erst ermittelt werden
          update m_product set xapi_parentproduct=(select m_product_id from m_product where value = v_cur2.xapi_parentproductvalue),
            xapi_attributeset=(select m_attributeset_id from m_attributeset where name = v_cur2.xapi_attributeset),
            xapi_attributesetinstance=(select i.m_attributesetinstance_id from m_attributesetinstance i,m_attributeset a where a.m_attributeset_id=i.m_attributeset_id and a.name=v_cur2.xapi_attributeset and i.description = v_cur2.xapi_attributesetinstance),
            xapi_parentproductvalue=v_cur2.xapi_parentproductvalue
            where m_product_id = v_productid;
        end if;
    END LOOP;
    return v_i||' Artikel importiert, davon '||v_ii||' neu angelegt';  
EXCEPTION
    WHEN OTHERS THEN
        v_ResultStr:='Artikel: '||coalesce(v_ResultStr,'-')|| ' @ERROR=' || SQLERRM;
        raise exception '%',v_ResultStr;
        
END;
$_$  LANGUAGE 'plpgsql';




select zsse_DropView ('i_product_po_v');
CREATE OR REPLACE VIeW i_product_po_v as
select po.M_PRODUCT_ID||po.c_bpartner_id||coalesce(po.c_uom_id,'')||coalesce(po.m_manufacturer_id,'')||coalesce(po.manufacturernumber,'') as i_product_po_v_id,
po.AD_CLIENT_ID,
 po.AD_ORG_ID,
 po.CREATEDBY,
 po.created,
 po.UPDATEDBY,
 po.updated,
 po.isactive,
 p.value,
 p.name,
 (select value from c_bpartner where c_bpartner_id=po.c_bpartner_id) as bpvalue,
 zssi_getbpname(po.c_bpartner_id) as bpname,
 po.qualityrating,
 po.iscurrentvendor,
  po.upc,
   po.c_currency_id,
 po.c_uom_id,
 po.pricelist,
 po.pricepo,
 po.pricelastpo,
 po.pricelastinv,
  po.deliverytime_promised,
 po.vendorproductno,
 po.vendorcategory,
  po.m_manufacturer_id,
   po.manufacturernumber,
 po.discontinued,
 po.discontinuedby,
  po.qtystd,
 po.order_min,
 po.ismultipleofminimumqty from m_product_po po,m_product p where p.m_product_id=po.m_product_id;
 
 

 
CREATE or replace FUNCTION  i_import_product_po(p_filename varchar,p_user varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_org character varying;
v_pversion character varying;
v_productid varchar;
v_productpoid  varchar;
v_bpartner varchar;
v_cur2 RECORD;
v_cmd varchar;
v_i numeric:=0;
v_ii numeric:=0;
v_uom varchar;
v_currency varchar;
v_manufacturer varchar;
v_manufacturernumber varchar;
v_locat varchar;
v_country varchar;
v_tax varchar;
v_bpuom varchar;
v_lang varchar;
BEGIN
 if p_filename is null then return 'ERROR'; end if;
  delete from i_product_poimport;
  -- Datei in Tabelle
  v_cmd := 'COPY i_product_poimport  FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER ;';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
 
    select ad_language into v_lang from ad_client  where ad_client_id=v_client;
    
    for v_cur2 in (select * from i_product_poimport)
    LOOP
        select m_product_id into v_productid from m_product where value=v_cur2.m_product_id;
        
        if v_productid is null then
            raise exception '%', 'Product not Found:'||v_cur2.m_product_id;
        end if;
        select c_bpartner_id into v_bpartner from c_bpartner where name=v_cur2.bpname and value=v_cur2.bpvalue limit 1;
        if v_bpartner is null then
            select c_bpartner_id into v_bpartner from c_bpartner where value=v_cur2.bpvalue limit 1;
            if v_bpartner is null then
                raise exception '%', 'Business partner not Found:'||v_cur2.bpvalue;
            end if;
        end if;
        select ad_org_id into v_org from m_product where  m_product_id=v_productid;
       -- if v_cur2.ad_org_id='*' then v_org:='0'; end if;
        if v_org is null then
            raise exception '%', 'Organization not Found:';
        end if;

        --if  v_currency is null then
        --    raise exception '%', 'Product Type not Found:'||v_cur2.typeofproduct;
        --end if;
        if v_cur2.c_uom_id is not null then 
            select c_uom_id into v_uom from c_uom where name=v_cur2.c_uom_id;
            if  v_uom is null then
               select c_uom_id into v_uom from c_uom_trl where ad_language = 'en_US' and name=v_cur2.c_uom_id; 
            end if;
            if  v_uom is null then
               select c_uom_id into v_uom from c_uom_trl where ad_language = v_lang and name=v_cur2.c_uom_id; 
            end if;
        end if;
         --  raise notice '%', 'Unit of Measure not Found:'||v_uom||'#'||zssi_getproductname(v_productid,'de_DE')||'#'||v_bpartner;
        --end if;
        select m_manufacturer_id into v_manufacturer from m_manufacturer where  name=v_cur2.m_manufacturer_id;
        v_manufacturernumber:=v_cur2.manufacturernumber;
        --if  v_manufacturer is null then
        --    raise exception '%', 'Type of Product not Found:'||v_cur2.typeofproduct;
        --end if;
        select c_currency_id into v_currency from c_currency where iso_code=v_cur2.c_currency_id;
        
        select m_product_po_id into v_productpoid from m_product_po where m_product_id=v_productid and c_bpartner_id= v_bpartner
                                    and case when v_uom is not null then c_uom_id=v_uom else 1=1 end 
                                    and case when v_cur2.manufacturernumber is not null then manufacturernumber=v_cur2.manufacturernumber  else 1=1 end 
                                    and case when v_manufacturer is not null then m_manufacturer_id=v_manufacturer else 1=1 end; 
        
        
        v_i:=v_i+1;
        if v_productpoid is null then
            insert into m_product_po (ad_org_id, m_product_id, c_bpartner_id, qualityrating, iscurrentvendor,  upc,   c_currency_id, c_uom_id, pricelist,
                                      pricepo,   deliverytime_promised, vendorproductno, vendorcategory,  m_manufacturer_id,
                                      manufacturernumber, discontinued, discontinuedby,  qtystd, order_min, ismultipleofminimumqty,
                                      CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_product_po_id,ad_client_id)
                             values  (v_org, v_productid, v_bpartner, to_number(v_cur2.qualityrating), v_cur2.iscurrentvendor,  v_cur2.upc,  v_currency,v_uom, to_number(v_cur2.pricelist),
                                      to_number(v_cur2.pricepo),   to_number(v_cur2.deliverytime_promised), v_cur2.vendorproductno, v_cur2.vendorcategory,  v_manufacturer,
                                      v_cur2.manufacturernumber, v_cur2.discontinued, to_date(v_cur2.discontinuedby),  to_number(v_cur2.qtystd), to_number(v_cur2.order_min), v_cur2.ismultipleofminimumqty,
                                      now(),p_user,now(),p_user,get_uuid(),v_client);
            v_ii:=v_ii+1;
           -- raise notice '%', 'Unit of Measure not Found:'||v_uom||'#'||zssi_getproductname(v_productid,'de_DE')||'#'||v_bpartner||'#Insert'||v_ii;
        else
       -- raise notice '%', 'Unit of Measure not Found:'||v_uom||'#'||zssi_getproductname(v_productid,'de_DE')||'#'||v_bpartner||'#Update'||v_ii;
            update m_product_po set ad_org_id=v_org,qualityrating=to_number(v_cur2.qualityrating), iscurrentvendor=v_cur2.iscurrentvendor,  upc=v_cur2.upc,   c_currency_id=v_currency, pricelist=to_number(v_cur2.pricelist),
                                      pricepo=to_number(v_cur2.pricepo),   deliverytime_promised=to_number(v_cur2.deliverytime_promised), vendorproductno=v_cur2.vendorproductno, vendorcategory=v_cur2.vendorcategory,  
                                      manufacturernumber=v_cur2.manufacturernumber, discontinued=v_cur2.discontinued, discontinuedby=to_date(v_cur2.discontinuedby),  qtystd=to_number(v_cur2.qtystd), order_min=to_number(v_cur2.order_min), ismultipleofminimumqty=v_cur2.ismultipleofminimumqty,
                                      UPDATEDBY=p_user,updated=now() 
                                where m_product_po_id=v_productpoid;
        end if;
        if v_uom is not null then
            if (select count(*) from m_product_uom where m_product_id=v_productid and c_uom_id= v_uom)=0 then
                insert into m_product_uom (ad_org_id, m_product_id,c_uom_id,m_product_uom_id,CREATED, CREATEDBY, UPDATED, UPDATEDBY,ad_client_id)
                       values(v_org, v_productid, v_uom,get_uuid(),now(),p_user,now(),p_user,v_client);
            end if;
        end if;
    v_uom:=null;
    v_manufacturer:=null;
    
    END LOOP;
    return v_i||' Lieferanten-Artikel importiert, davon '||v_ii||' Datensätze neu angelegt';  
END;
$_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION  i_import_account(p_filename varchar,p_elementid varchar, p_withupdate varchar) RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_org character varying:='0';
v_account character varying;
v_cur2 RECORD;
 v_element c_elementvalue%ROWTYPE;
v_i numeric:=0;
v_count numeric;
v_cmd varchar;
v_oname varchar;
BEGIN
 if p_filename is null then return 'ERROR'; end if;
 create temporary table i_elementvalue as select * from c_elementvalue where c_element_id='';
  
  -- Datei in Tabelle
  v_cmd := 'COPY i_elementvalue  FROM ''/tmp/' || p_filename ||''' CSV DELIMITER as '||chr(39)||';'||chr(39)||' HEADER ;';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
 
    update i_elementvalue set c_element_id=p_elementid;
    if (select count(*) from c_element where c_element_id=p_elementid)=0 then
        return 'Konenrahmen existiert nicht';
    end if;
    update i_elementvalue set c_elementvalue_id=get_uuid();
    update i_elementvalue set value=lpad(value,4,'0') where length(value)<4;
    update c_elementvalue  set value=lpad(value,4,'0') where length(value)<4 and c_element_id= p_elementid;
    for v_cur2 in (select * from i_elementvalue )
    LOOP
       select c_elementvalue_id,name into v_account,v_oname from c_elementvalue where c_element_id= p_elementid and value=v_cur2.value;
       select * from i_elementvalue  into  v_element where  c_elementvalue_id=v_cur2.c_elementvalue_id;
       if v_account is null then
          insert into c_elementvalue select v_element.*;
       else
        if p_withupdate='Y' then
          update c_elementvalue set name=v_cur2.name,description=v_cur2.description where c_element_id= p_elementid and value=v_cur2.value;
        end if;
       end if;
       v_i:=v_i+1;
    END LOOP;
    drop table i_elementvalue;
    return v_i||' Konten  importiert.';  
END;
$_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION  i_import_accounttrl(p_filename varchar) RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_org character varying:='0';
v_account character varying;
v_cur2 RECORD;
v_i numeric:=0;
v_count numeric;
v_cmd varchar;
v_oname varchar;
BEGIN
 if p_filename is null then return 'ERROR'; end if;
  delete from i_accounttrlimport;
  -- Datei in Tabelle
  v_cmd := 'COPY i_accounttrlimport  FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||';'||chr(39)||' HEADER ;';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
 
    
    update i_accounttrlimport set accountno=lpad(accountno,4,'0') where length(accountno)<4;
    for v_cur2 in (select * from i_accounttrlimport)
    LOOP
       select c_elementvalue_id,name into v_account,v_oname from c_elementvalue where c_element_id=v_cur2.elementid_key and value=v_cur2.accountno;
       if v_account is not null then
        if (select count(*) from c_elementvalue_trl where c_elementvalue_id=v_account and ad_language=v_cur2.language and name!=v_oname)=0 then
            delete from C_ElementValue_Trl where C_ElementValue_ID=v_account and AD_Language=v_cur2.language;
            INSERT INTO C_ElementValue_Trl( C_ElementValue_Trl_ID, C_ElementValue_ID, AD_Language, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy, Name, IsTranslated)
            values (get_uuid(),v_account,v_cur2.language,v_client,v_org,'100','100',v_cur2.accounttext,'Y');
            v_i:=v_i+1;
        end if;
       end if;
    END LOOP;
    return v_i||' Konten Übersetzungen importiert.';  
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION  i_import_bwaprefstrl(p_filename varchar) RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_org character varying:='0';
v_account character varying;
v_cur2 RECORD;
v_i numeric:=0;
v_count numeric;
v_cmd varchar;
v_oname varchar;
BEGIN
 if p_filename is null then return 'ERROR'; end if;
  delete from i_bwaprefstrlimport;
  -- Datei in Tabelle
  v_cmd := 'COPY i_bwaprefstrlimport  FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||';'||chr(39)||' HEADER ;';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
 
    if (select count(*) from zspr_bwaheader_trl where zspr_bwaheader_id='C91138D2EACC49A1809391E8159668AB' and ad_language='en_US')=0 and
        (select count(*) from zspr_bwaheader where zspr_bwaheader_id='C91138D2EACC49A1809391E8159668AB')=1 then
        INSERT INTO zspr_bwaheader_trl( zspr_bwaheader_trl_ID, zspr_bwaheader_ID, AD_Language, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy,
                    Name,headertext,subheadertext,footertext)
            values (get_uuid(),'C91138D2EACC49A1809391E8159668AB','en_US',v_client,v_org,'100','100',
                    'Assets','Provisional report assets (beta)',':','Sum assets');
    end if;
    if (select count(*) from zspr_bwaheader_trl where zspr_bwaheader_id='17C2A9EC04F64FAD8593E5FD762F2390' and ad_language='en_US')=0 and
        (select count(*) from zspr_bwaheader where zspr_bwaheader_id='17C2A9EC04F64FAD8593E5FD762F2390')=1 then
        INSERT INTO zspr_bwaheader_trl( zspr_bwaheader_trl_ID, zspr_bwaheader_ID, AD_Language, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy,
                    Name,headertext,subheadertext,footertext)
            values (get_uuid(),'17C2A9EC04F64FAD8593E5FD762F2390','en_US',v_client,v_org,'100','100',
                    'Liabilities and Shareholders’ Equity','Provisional report Liabilities and Shareholders’ Equity (beta)',':','Sum ');
    end if;
    if (select count(*) from zspr_bwaheader_trl where zspr_bwaheader_id='4B316936DD0F4C6E9E83CFDC642C3868' and ad_language='en_US')=0 and
        (select count(*) from zspr_bwaheader where zspr_bwaheader_id='4B316936DD0F4C6E9E83CFDC642C3868')=1 then
        INSERT INTO zspr_bwaheader_trl( zspr_bwaheader_trl_ID, zspr_bwaheader_ID, AD_Language, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy,
                    Name,headertext,subheadertext,footertext)
            values (get_uuid(),'4B316936DD0F4C6E9E83CFDC642C3868','en_US',v_client,v_org,'100','100',
                    'Profit and Loss Account (short version)','Profit and Loss Account',':','Annual profit / loss');
    end if;
    if (select count(*) from zspr_bwaheader_trl where zspr_bwaheader_id='7E29B8CED9B34DA1A9879750BB728AFA' and ad_language='en_US')=0 and
        (select count(*) from zspr_bwaheader where zspr_bwaheader_id='7E29B8CED9B34DA1A9879750BB728AFA')=1 then
        INSERT INTO zspr_bwaheader_trl( zspr_bwaheader_trl_ID, zspr_bwaheader_ID, AD_Language, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy,
                    Name,headertext,subheadertext,footertext)
            values (get_uuid(),'7E29B8CED9B34DA1A9879750BB728AFA','en_US',v_client,v_org,'100','100',
                    'Profit and Loss Account','Profit and Loss Account',':','Annual profit / loss');
    end if;
    if (select count(*) from zspr_bwaheader_trl where zspr_bwaheader_id='E9CBD78C18504A0AA7A9161E95DF3ADC' and ad_language='en_US')=0 and
        (select count(*) from zspr_bwaheader where zspr_bwaheader_id='E9CBD78C18504A0AA7A9161E95DF3ADC')=1 then
        INSERT INTO zspr_bwaheader_trl( zspr_bwaheader_trl_ID, zspr_bwaheader_ID, AD_Language, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy,
                    Name,headertext,subheadertext,footertext)
            values (get_uuid(),'E9CBD78C18504A0AA7A9161E95DF3ADC','en_US',v_client,v_org,'100','100',
                    'Turnover Tax','Turnover Tax',':','To discharge (+) / excess (-)');
    end if;
    for v_cur2 in (select * from i_bwaprefstrlimport)
    LOOP
       select zspr_bwaprefs_id,name into v_account,v_oname from zspr_bwaprefs where zspr_bwaheader_id=v_cur2.bwaheaderid_key and name=v_cur2.accounttext;
       if v_account is not null then
        if (select count(*) from zspr_bwaprefs_trl where zspr_bwaprefs_id=v_account and ad_language=v_cur2.language and name!=v_oname)=0 then
            delete from zspr_bwaprefs_trl where zspr_bwaprefs_id=v_account and ad_language=v_cur2.language;
            INSERT INTO zspr_bwaprefs_trl( zspr_bwaprefs_trl_ID, zspr_bwaprefs_id, AD_Language, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy, Name, IsTranslated)
            values (get_uuid(),v_account,v_cur2.language,v_client,v_org,'100','100',v_cur2.accounttext_trl,'Y');
            v_i:=v_i+1;
        end if;
       end if;
    END LOOP;
    return v_i||' Konten Übersetzungen importiert.';  
END;
$_$  LANGUAGE 'plpgsql';

--New Overview for Product Translation Imports

select zsse_DropView ('i_product_trl_v');
CREATE OR REPLACE VIeW i_product_trl_v as
select  t.M_PRODUCT_ID as m_product_id,
        t.m_product_trl_id as i_product_trl_v_id,
        t.m_product_trl_id as m_product_trl_id,
        t.ad_org_id as ad_org_id,
        p.value as value,
        t.name as name,
        t.description as description,
        t.documentnote as documentnote,
        ad_language as ad_language, 
        t.isactive as isactive,
        t.CREATEDBY, t.created, t.UPDATEDBY, t.updated,t.ad_client_id
        from m_product p left join m_product_trl t on t.m_product_id=p.m_product_id;
        
        
CREATE or replace FUNCTION  i_import_producttrl(p_filename varchar,p_user varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_masterproduct character varying;
v_trlproduct character varying;
v_newproduct character varying;
v_org character varying;
v_value character varying;
v_name character varying;
v_description character varying;
v_documentnote character varying;
v_lang character varying;
v_isactive character;
v_cur2 RECORD;
v_i numeric:=0;
v_u numeric:=0;
v_count numeric;
v_cmd varchar;

BEGIN
 if p_filename is null then return 'ERROR'; end if;
  delete from i_producttrlimport;
  -- Datei in Tabelle
  v_cmd := 'COPY i_producttrlimport (Value,Name,Description,Documentnote,AD_Language) FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER ;';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
    for v_cur2 in (select * from i_producttrlimport)
    LOOP
       
v_masterproduct:=(select m_product_id from m_product where value=v_cur2.value);
v_trlproduct:=(select m_product_trl_id from m_product_trl where m_product_id=v_masterproduct and ad_language=v_cur2.ad_language);
v_org:='0';
v_name:=coalesce(v_cur2.name,'');
v_description:=coalesce(v_cur2.description,'');
v_documentnote:=coalesce(v_cur2.documentnote,'');
v_lang:=v_cur2.ad_language;
v_isactive:='Y';
       if (v_trlproduct is null ) then
            v_newproduct:=get_uuid();
            Insert into m_product_trl (
            m_product_trl_id,
            m_product_id,
            ad_language,
            ad_client_id,
            ad_org_id,
            isactive,
            created,
            createdBy,
            updated,
            updatedby,
            name,
            documentnote,
            IsTranslated,
            description)
            values(
            v_newproduct,
            v_masterproduct,
            v_lang,
            v_client,
            v_org,
            v_isactive,
            now(),
            p_user,
            now(),
            p_user,
            v_name,
            coalesce(v_documentnote,''),
            'Y',
            coalesce(v_description,''));
            v_i:=v_i+1;
       else
            update m_product_trl set updated=now(),updatedby=p_user,isactive=v_isactive,name=v_name,documentnote=v_documentnote,description=v_description,ad_org_id=v_org where m_product_trl_id=v_trlproduct and ad_language=v_lang;
            v_u:=v_u+1;
        end if;
    END LOOP;
    return v_i||' Artikelübersetzungen eingefügt. '||v_u||' Artikelübersetzungen aktualisiert.';  
END;
$_$  LANGUAGE 'plpgsql';

select zsse_DropView ('i_costing_v');
CREATE OR REPLACE VIeW i_costing_v as

  select a.m_product_id as m_product_id,a.datefrom as datefrom,(select value from m_product where m_product_id=a.m_product_id) as value,
        (select name from m_product where m_product_id=a.m_product_id) as name, m_costing_id as i_costing_v_id , cast('Y' as character(1)) as isactive,ad_org_id,ad_client_id,m_costing_id,
        created,createdby,updated,updatedby,ismanual,ispermanent,cost,isproduction,costtype 
      from m_costing, 
      (select m_product_id,max(datefrom) as datefrom from m_costing group by m_product_id) a
      where m_costing.m_product_id=a.m_product_id and a.datefrom=m_costing.datefrom;
      
CREATE or replace FUNCTION  i_import_costing(p_filename varchar,p_user varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_count numeric;
v_cmd varchar;
v_cost varchar;
v_masterproduct varchar;
v_u numeric:=0;
v_i numeric:=0;
v_cur2 RECORD;
v_date Date;
v_cost_id varchar;
BEGIN
 if p_filename is null then return 'ERROR'; end if;
  delete from i_import_costing;
  -- Datei in Tabelle
  v_cmd := 'COPY i_import_costing (Org,productvalue,ProductName,costtype,datefrom,cost, production, ismanual, ispermanent) FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER ;';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
    for v_cur2 in (select * from i_import_costing)
    LOOP
       
    v_masterproduct:=(select m_product_id from m_product where ltrim(rtrim(value))=ltrim(rtrim(v_cur2.productvalue)) and ad_org_id in ((select ad_org_id from ad_org where name =v_cur2.Org),'0'));
    if v_masterproduct is not null then 
        select m_costing_id into v_cost_id from m_costing where M_PRODUCT_ID=v_masterproduct and DATETO =
                                                         (select max(DATETO) from m_costing where M_PRODUCT_ID=v_masterproduct );
		    update m_costing set DATETO=to_date(v_cur2.datefrom)-1 where m_costing_id=v_cost_id;

		    Insert into m_costing (
		    m_costing_id,
		    created,
		    createdby,
		    updated,
		    updatedby,
		    ad_client_id,
		    ad_org_id,
		    m_product_id,
		    datefrom,
		    dateto,
		    ismanual,
		    costtype,
		    ispermanent,
		    cost,
		    isproduction)
		    values(
		    get_uuid(),
		    now(),
		    p_user,
		    now(),
		    p_user,
		    v_client,
		    (select ad_org_id from ad_org where name =v_cur2.Org),
		    v_masterproduct,
		    to_date(v_cur2.datefrom),
		    to_date('01-01-9999','dd.mm.yyyy'),
		    v_cur2.ismanual,
		    v_cur2.costtype,
		    v_cur2.ispermanent,
		    to_number(v_cur2.cost),
		    v_cur2.production);

		    v_i:=v_i+1; 
           	v_u:=v_u+1;
    end if;
    END LOOP;
    return v_i||' Datensätze in Kalkulation eingefügt und '||v_u||' Datensätze aktualisiert.';  
END;
$_$  LANGUAGE 'plpgsql';

/*
create table i_import_costing(
Org character varying(250),
ProductName character varying(250),
productvalue character varying(250),
price character varying(250),
cost character varying(250),
costtype character varying(250),
datefrom character varying(250),
dateto character varying(250),
qty character varying(250),
production character varying(250),
ismanual character varying(250),
ispermanent character varying(250),
isactive character varying(250)
);*/


select zsse_DropView ('i_requisition_v');
CREATE OR REPLACE VIeW i_requisition_v as
select t.ad_org_id as i_requisition_v_id,t.ad_org_id,
'#'::varchar(40) as value,0::numeric as qty,
t.isactive as isactive,
t.CREATEDBY, t.created, t.UPDATEDBY, t.updated,t.ad_client_id from ad_org t limit 1;


CREATE or replace FUNCTION  i_import_requisition(p_filename varchar,p_user varchar, p_orgid varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_count numeric;
v_cmd varchar;
v_masterproduct varchar;
v_u numeric:=0;
v_i numeric:=0;
v_cur2 RECORD;
v_date Date;
v_pricelist varchar;
v_requid varchar;
v_seq numeric;
v_product varchar;
v_line numeric:=0;
v_uom varchar;
BEGIN
 if p_filename is null then return 'ERROR'; end if;
  delete from i_import_requisition;
  -- Datei in Tabelle
  v_cmd := 'COPY i_import_requisition (value, qty) FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||';';
  --RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
    if (select count(*) from i_import_requisition where exists(select 0 from m_product p where p.value=i_import_requisition.value))>0 then
        v_requid:=get_uuid();
        select ad_sequence_doc('DocumentNo_M_Requisition',p_orgid,'Y') into v_seq from dual;
        select m_pricelist_id into v_pricelist from m_pricelist where isdefault='Y' and issopricelist='N' and ad_org_id in ('0',p_orgid) limit 1;
        if v_pricelist is null then
            raise exception '%','No default sales pricelist defined';
        end if;
        insert into m_requisition(M_REQUISITION_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, DESCRIPTION, DOCUMENTNO, C_PROJECT_ID, C_PROJECTTASK_ID, ad_user_id,m_pricelist_id)
                      values (v_requid,v_client, p_orgid, 'Y', now(),p_user,now(),p_user,'Imported Requisition',v_seq,null,null, p_user,v_pricelist);
        for v_cur2 in (select * from i_import_requisition)
        LOOP
            select m_product_id,c_uom_id into v_product,v_uom from m_product where value=v_cur2.value;
            v_line:=v_line+10;
            insert into m_requisitionline (M_REQUISITIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_REQUISITION_ID, M_PRODUCT_ID, QTY, NEEDBYDATE, LINE,c_uom_id)
                      values(get_uuid(),v_client, p_orgid,now(),p_user,now(),p_user,v_requid,v_product,to_number(v_cur2.qty),trunc(now()),v_line,v_uom);
        END LOOP;
        --return 'BANF importiert: '|| zsse_htmlLinkDirectKey('../Requisition/Header_Relation.html',v_requid,to_char(v_seq));
        --return 'BANF importiert: '|| zsse_htmldirectlinkWithDummyField('../Requisition/Header_Relation.html','reqdum',v_requid,to_char(v_seq))||' erstellt.</br>';
        return 'BANF importiert: '|| zsse_htmldirectlink('../Requisition/Header_Relation.html', 'document.frmImport.inpmRequisitionId', v_requid, to_char(v_seq))||'<Input type="hidden" name="inpmRequisitionId" value="'||v_requid || '">';
    else
        return 'Es wurden keine Daten übernommen (Achten Sie darauf, das die Artikel-Suchschlüssel existieren)';
    end if; 
END;
$_$  LANGUAGE 'plpgsql';



select zsse_DropView ('i_product_bom_v');
CREATE OR REPLACE VIeW i_product_bom_v as
select  m_product_bom_id as i_product_bom_v_id,
bom.AD_CLIENT_ID,
 bom.AD_ORG_ID,
 bom.CREATEDBY,
 bom.created,
 bom.UPDATEDBY,
 bom.updated,
 bom.isactive,
 pp.value as assembly,
 p.value,
 p.name,
 bom.line,
 bom.bomqty,
 bom.description,
 bom.constuctivemeasure,
 bom.rawmaterial,
 bom.workstepname,
 bom.isconsumable
 from m_product_bom bom,m_product p,m_product pp where p.m_product_id=bom.m_productbom_id and pp.m_product_id=bom.m_product_id;
 
 
CREATE or replace FUNCTION  i_import_bom(p_filename varchar,p_user varchar, p_orgid varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE
-- Crazy dynamical import format stuff...
v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_count numeric:=0;
v_cmd varchar:='';
v_fieldlist varchar:='';
v_hasline varchar:='N';
v_u numeric:=0;
v_i numeric:=0;
v_cur RECORD;
v_date Date;
v_org varchar;
v_requid varchar;
v_seq numeric;
v_product varchar;
v_assembly varchar;
v_ds varchar;
v_line numeric:=0;
v_uom varchar;
v_categ varchar;
currentAssemply varchar:='';
BEGIN
  if p_filename is null then return 'ERROR'; end if;
  perform zsse_droptable ('i_bom');
  -- Format anziehen (TAB: Export BOM)
  for v_cur in (select pname,pad_ref_fieldcolumn_id from ad_selecttabfields('DE_de','A50150A1955B4333A8D37A5262D6250D') order by pline)
  LOOP
    if ad_fieldGetVisibleLogic(v_cur.pad_ref_fieldcolumn_id,'')='VISIBLE'  then         
        if v_cur.pname='Line' then v_hasline:='Y'; end if;
        if v_cmd='' then v_cmd := 'create temporary table i_bom('; else v_cmd := v_cmd ||' , ';  end if;
        if v_cur.pname not in ('Assembly','Value','Name','Line') then
            if v_fieldlist!='' then v_fieldlist:=v_fieldlist||','; end if;
            if (select data_type from information_schema.columns where table_name='m_product_bom' and column_name=lower(v_cur.pname))='numeric' then
                v_fieldlist:=v_fieldlist||v_cur.pname||'=to_number(a.'||v_cur.pname||')';
            elseif (select data_type from information_schema.columns where table_name='m_product_bom' and column_name=lower(v_cur.pname))='timestamp without time zone' then
                v_fieldlist:=v_fieldlist||v_cur.pname||'=to_date(a.'||v_cur.pname||')';
            else
                v_fieldlist:=v_fieldlist||v_cur.pname||'=a.'||v_cur.pname;
            end if;
        end if;
        v_cmd := v_cmd ||v_cur.pname||' text';
    end if;
  END LOOP;
  v_cmd := v_cmd ||' )  ON COMMIT DROP';
  EXECUTE(v_cmd);
  RAISE notice '%', v_cmd;
  RAISE notice '%', v_fieldlist;
  -- Datei in Tabelle
  v_cmd := 'COPY i_bom FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER;';
  EXECUTE(v_cmd);
  v_cmd := 'alter table i_bom add column idds character varying(32) not null default get_uuid()';
  EXECUTE(v_cmd);
  if (select count(*) from i_bom)=0 then
        return 'Es wurden keine Daten übernommen.';
  end if;
  select m_product_category_id into v_categ from m_product_category where isactive='Y' order by isdefault desc limit 1;
  select c_uom_id into v_uom from c_uom  where isactive='Y' order by isdefault desc limit 1;
  for v_cur in (select * from i_bom order by assembly) 
  LOOP
        if (select count(*) from m_product where value=v_cur.assembly)=0 then
            return 'Baugruppe existiert nicht: '||v_cur.assembly;
        end if;
        if v_cur.assembly!=currentAssemply then
            select m_product_id,ad_org_id into v_assembly,v_org from m_product where value=v_cur.assembly;
            currentAssemply:=v_cur.assembly;
            -- Delete old BOM if assembly changes
            delete from m_product_bom where m_product_id=v_assembly;
        end if;
        v_requid:=get_uuid();
        v_i:=v_i+1;
        if v_hasline='N' then 
            v_count:=v_count+10;
        else 
            v_count:=to_number(v_cur.line);
        end if;
        if (select count(*) from m_product where value=v_cur.Value)=0 then
            v_product:=get_uuid();
            if v_cur.name is not null then
                insert into m_product (ad_client_id,ad_org_id,createdby,updatedby,
                                       m_product_category_id,c_uom_id,
                                       issold,ispurchased,value,name,m_product_id)
                values(v_client,p_orgid,p_user,p_user,v_categ,v_uom,'N','Y',v_cur.Value,v_cur.name,v_product);
            else
               return 'Artikel existiert nicht: '||coalesce(v_cur.Value,'NULL');
            end if;
        end if;
        v_ds:=get_uuid();
        select m_product_id into v_product from m_product where value=v_cur.Value;
        -- WRITE new BOM Position
        insert into m_product_bom (ad_client_id,ad_org_id,createdby,updatedby,m_product_id,m_productbom_id,line,m_product_bom_id)
        values(v_client,v_org,p_user,p_user,v_assembly,v_product,v_count,v_ds);
        update i_bom set idds=v_ds where idds=v_cur.idds;
    END LOOP;
    v_cmd := 'update m_product_bom set '||v_fieldlist||' from i_bom a where a.idds=m_product_bom.m_product_bom_id';
    RAISE notice '%', v_cmd;
    EXECUTE(v_cmd);
    return v_i||' Stücklistenpositionen importiert.';
END;
$_$  LANGUAGE 'plpgsql';



select zsse_DropView ('i_offer_v');
CREATE OR REPLACE VIeW i_offer_v as
select coalesce(b.m_offer_bpartner_id,'')||coalesce(p.m_offer_product_id,'') as i_offer_v_id,
 o.AD_CLIENT_ID,
 o.AD_ORG_ID,
 o.CREATEDBY,
 o.created,
 o.UPDATEDBY,
 o.updated,
 o.isactive,
 o.priority,
 o.addamt,
 o.discount,
 o.fixed,
 o.datefrom,
 o.dateto,
 o.qty_from,
 o.qty_to,
 o.issalesoffer,
 o.name,
 o.description,
 o.directpurchasecalc,
 bb.value as bpartner,
 bb.name as bpartnername,
 pp.value as product,
 pp.name as productname,
 i.description as attribute,
 p.graterequal,
 p.lessequal,
 pl.name as pricelistname
 from m_offer o left join m_offer_bpartner b on b.m_offer_id=o.m_offer_id
                left join c_bpartner bb on bb.c_bpartner_id=b.c_bpartner_id
                left join m_offer_product p on p.m_offer_id=o.m_offer_id
                left join m_product pp on p.m_product_id=pp.m_product_id
                left join m_attributesetinstance i on i.m_attributesetinstance_id=p.m_attributesetinstance_id
                left join m_offer_pricelist l on p.m_offer_id=l.m_offer_id
                left join m_pricelist pl on pl.m_pricelist_id=l.m_pricelist_id
 where o.isactive='Y' and (b.m_offer_bpartner_id is not null or p.m_offer_product_id is not null);
 
 
CREATE or replace FUNCTION  i_import_offer(p_filename varchar,p_user varchar, p_orgid varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE
-- Crazy dynamical import format stuff...
v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_count numeric:=0;
v_cmd varchar:='';
v_fieldlist varchar:='';
v_hasline varchar:='N';
v_u numeric:=0;
v_i numeric:=0;
v_cur RECORD;
v_date Date;
v_org varchar;
v_requid varchar;
v_seq numeric;
v_product varchar;
v_ds varchar;
v_line numeric:=0;
v_uom varchar;
v_categ varchar;
v_attrset varchar;
v_attrinstanc varchar; 
v_partner varchar;
v_pricelist varchar;
currentAssemply varchar:='';
v_poid varchar;
v_ppId varchar;
BEGIN
  if p_filename is null then return 'ERROR'; end if;
  perform zsse_droptable ('i_offer');
  -- Format anziehen (TAB: Export Offer)
  for v_cur in (select pname,pad_ref_fieldcolumn_id from ad_selecttabfields('DE_de','D9EC7D7425BB40269228E4FFE0D51B2E') order by pline)
  LOOP
    if ad_fieldGetVisibleLogic(v_cur.pad_ref_fieldcolumn_id,'')='VISIBLE'  then       
        if v_cmd='' then
            v_cmd:='create temporary table i_offer(';
        else
            v_cmd := v_cmd ||', ';
        end if;
        v_cmd := v_cmd ||v_cur.pname||' text';
    end if;
  END LOOP;
  v_cmd := v_cmd ||' )  ON COMMIT DROP';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
  -- Datei in Tabelle
  v_cmd := 'COPY i_offer FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER;';
  EXECUTE(v_cmd);
  if (select count(*) from i_offer)=0 then
        return 'Es wurden keine Daten übernommen.';
  end if;
  for v_cur in (select * from i_offer order by name,product,bpartner) 
  LOOP
        if v_cur.product is not null and (select count(*) from m_product where value=v_cur.product)!=1 then
            return 'Artikel existiert nicht: '||v_cur.product;
        end if;
        if v_cur.bpartner is not null and (select count(*) from c_bpartner where value=v_cur.bpartner)!=1 then
            return 'Geschäftspartner existiert nicht: '||v_cur.bpartner;
        end if;
        select m_product_id,m_Attributeset_Id into v_product , v_attrset from m_product where value=v_cur.product;
        if v_cur.attribute is not null then
            v_attrinstanc:=m_attributesetgetId(v_cur.attribute,v_attrset) ;
        end if;
        begin
            select c_bpartner_id into v_partner from c_bpartner where value=v_cur.bpartner;
        exception
        when others then null;
        end;
        begin
            select m_pricelist_id into v_pricelist from m_pricelist where name=v_cur.pricelistname;
        exception
        when others then null;
        end;
        select ad_org_id into v_org from ad_org where name=v_cur.ad_org_id;
        if v_org is null then
            return 'Organisation existiert nicht'||coalesce(v_cur.ad_org_id,'NULL');
        end if;
        -- Create or Update Offer
        if v_cur.name!=currentAssemply then
            select m_offer_id into v_requid from m_offer where name=v_cur.name;
            if v_requid is not null then
                delete from m_offer_product where m_offer_id=v_requid;
                delete from m_offer_bpartner where m_offer_id=v_requid;
                update m_offer set  AD_ORG_ID= v_org, CREATEDBY=p_user, UPDATEDBY=p_user,updated=now(),  isactive=v_cur.isactive, priority=to_number(coalesce(v_cur.priority,'0')), addamt=to_number(coalesce(v_cur.addamt,'0')), discount=to_number(coalesce(v_cur.discount,'0')), fixed=to_number(v_cur.fixed), 
                                    datefrom=to_date(v_cur.datefrom), dateto=to_date(v_cur.dateto), qty_from=to_number(v_cur.qty_from), qty_to=to_number(v_cur.qty_to), issalesoffer=v_cur.issalesoffer, description=v_cur.description, 
                                    directpurchasecalc=v_cur.directpurchasecalc,bp_group_selection='Y', prod_cat_selection='Y',pricelist_selection='Y',
                                    product_selection=case when v_product is not null then 'N' else 'Y' end,bpartner_selection=case when v_partner is not null then 'N' else 'Y' end
                               where m_offer_id=v_requid;
            else
                v_requid:=get_uuid();
                insert into m_offer(m_offer_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  isactive, priority, addamt, discount, fixed, datefrom, dateto, qty_from, qty_to,
                                    issalesoffer, name, description, directpurchasecalc,bp_group_selection, prod_cat_selection,pricelist_selection,product_selection,bpartner_selection)
                            values(v_requid,v_client, v_org,p_user,p_user,v_cur.isactive, to_number(coalesce(v_cur.priority,'0')), to_number(coalesce(v_cur.addamt,'0')), to_number(coalesce(v_cur.discount,'0')), to_number(v_cur.fixed), to_date(v_cur.datefrom), to_date(v_cur.dateto), to_number(v_cur.qty_from), to_number(v_cur.qty_to),
                                    v_cur.issalesoffer, v_cur.name, v_cur.description, v_cur.directpurchasecalc,'Y','Y','Y',
                                    case when v_product is not null then 'N' else 'Y' end,case when v_partner is not null then 'N' else 'Y' end);
            end if;
            currentAssemply:=v_cur.name;
            v_i:=v_i+1;
        end if;
        -- Create Product Entry
        if v_product is not null  and (select count(*) from m_offer_product where m_offer_id=v_requid and m_product_id=v_product and case when v_attrinstanc is not null then m_attributesetinstance_id=v_attrinstanc else 1=1 end)=0 then
            insert into m_offer_product(m_offer_product_id,m_offer_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  isactive,m_product_id,m_attributesetinstance_id)
                        values(get_uuid(),v_requid,v_client, v_org,p_user,p_user,v_cur.isactive,v_product,v_attrinstanc);
        end if;
        -- Create BParner entry (POTRX)       
        if v_partner is not null then
            if (select count(*) from m_offer_bpartner where m_offer_id=v_requid and c_bpartner_id=v_partner)=0 then
                insert into m_offer_bpartner(m_offer_bpartner_id,m_offer_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  isactive,c_bpartner_id)
                   values(get_uuid(),v_requid,v_client, v_org,p_user,p_user,v_cur.isactive,v_partner);
            end if;       
            -- ProductPO ID
            select m_product_po_id into v_poid from m_product_po where c_bpartner_id=v_partner and m_product_id=v_product and m_manufacturer_id is null and c_uom_id is null limit 1;
            update  m_offer set m_product_po_id=v_poid where  m_offer_id=v_requid;
        end if;
        -- Product PRICE (SOTRX)
        if v_pricelist is not null  then
            if (select count(*) from m_offer_pricelist where m_offer_id=v_requid and m_pricelist_id=v_pricelist)=0 then 
              insert into m_offer_pricelist(m_offer_pricelist_id,m_offer_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  isactive,m_pricelist_id)
                   values(get_uuid(),v_requid,v_client, v_org,p_user,p_user,v_cur.isactive,v_pricelist);    
            end if;
            -- Product Price ID
            select m_productprice_id into v_ppId from m_productprice where m_product_id=v_product  and c_uom_id is null 
                   and m_pricelist_version_id=(select m_pricelist_version_id from m_pricelist_version where m_pricelist_id=v_pricelist order by validfrom desc limit 1);
            update  m_offer set m_productprice_id=v_ppId,pricelist_Selection='N' where  m_offer_id=v_requid;
        end if;
    END LOOP;
    return v_i||' Preisgestaltungen importiert.';
END;
$_$  LANGUAGE 'plpgsql';

select zsse_DropView ('i_productionplan_v');
CREATE OR REPLACE VIeW i_productionplan_v as
select coalesce(pt.c_projecttask_id,'')||coalesce(hr.zspm_ptaskhrplan_id,'')||coalesce(pm.zspm_ptaskmachineplan_id,'') as i_productionplan_v_id,
 p.c_project_id,
 p.AD_CLIENT_ID,
 p.AD_ORG_ID,
 p.CREATEDBY,
 p.created,
 p.UPDATEDBY,
 p.updated,
 p.isactive,
 p.isdefault,
 p.isautotriggered,
 p.value,
 p.name,
 p.description,
 p.note,
 p.responsible_Id,
 pptv.zssm_productionplan_task_id,
 pptv.sortno,
 pt.c_projecttask_id,
 pt.value as workstepsearchkey,
 pt.name as workstepname,
 pt.description as workstepdescription,
 pt.assembly,
 pt.m_Product_Id,
 pp.value as Product,
 pp.name as Productname,
 pt.forcematerialscan,
 pt.startonlywithcompletematerial,
 pt.receiving_locator,
 pt.issuing_locator,
 pt.timeperpiece,
 pt.setuptime,
 pt.mimimumqty,
 pt.multipleofmimimumqty,
 pt.c_Color_Id,
 hr.zspm_ptaskhrplan_id,
 hr.c_Salary_Category_Id,
 hr.averageduration,
 hr.durationunit,
 pm.zspm_ptaskmachineplan_id,
 pm.ma_Machine_Id,
 pm.averageduration as machineaverageduration,
 pm.durationunit as machinedurationunit,
 pt.simplyfiedmanufacturing,
 pt.producecontinuously as producecontinuously,
 pt.istestingworkstep as istestingworkstep
 from c_project p left join zssm_productionplan_task pptv on pptv.c_project_id=p.c_project_id
                  left join c_projecttask pt on pptv.c_projecttask_id=pt.c_projecttask_id
                  left join zspm_ptaskhrplan hr on hr.c_projecttask_id=pt.c_projecttask_id
                  left join zspm_ptaskmachineplan pm on pm.c_projecttask_id=pt.c_projecttask_id
                  left join m_product pp on pt.m_Product_Id=pp.m_Product_Id
 where p.isactive='Y' and p.projectcategory='PRP';
 
 
 
CREATE or replace FUNCTION  i_import_productionplan(p_filename varchar,p_user varchar, p_orgid varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE
-- Crazy dynamical import format stuff...
v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_count numeric:=0;
v_cmd varchar:='';
v_fieldlist varchar:='';
v_hasline varchar:='N';
v_u numeric:=0;
v_i numeric:=0;
v_cur RECORD;
v_cur2 RECORD;
v_date Date;
v_org varchar;
v_requid varchar;
v_ptid varchar;
v_currentptask varchar:='';
v_seq numeric;
v_product varchar;
v_prdval varchar;
v_recloc varchar;
v_issloc varchar;
v_color varchar;
v_salcat varchar;
v_maschine varchar;
v_ds varchar;
v_line numeric:=0;
v_uom varchar;
v_categ varchar;
v_attrset varchar;
v_attrinstanc varchar; 
v_partner varchar;
currentAssemply varchar:='';
BEGIN
  if p_filename is null then return 'ERROR'; end if;
  perform zsse_droptable ('i_productionplan');
  perform zsse_droptable ('i_imported_projects');
  -- Format anziehen (TAB: Export Offer)
  for v_cur in (select pname,pad_ref_fieldcolumn_id from ad_selecttabfields('DE_de','D6537489B493481598CBF4181B062785') order by pline)
  LOOP
    if ad_fieldGetVisibleLogic(v_cur.pad_ref_fieldcolumn_id,'')='VISIBLE'  then      
        if v_cmd='' then
            v_cmd:='create temporary table i_productionplan(';
        else
            v_cmd := v_cmd ||', ';
        end if;
        v_cmd := v_cmd ||v_cur.pname||' text';
    end if;
  END LOOP;
  v_cmd := v_cmd ||' )  ON COMMIT DROP';
  RAISE notice '%', v_cmd;
  EXECUTE(v_cmd);
  -- Datei in Tabelle
  v_cmd := 'COPY i_productionplan FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER;';
  EXECUTE(v_cmd);
  v_cmd := 'create temporary table i_imported_projects(c_project_id text, isautotriggered text, numofprojecttasks numeric, last_c_projecttask_id text) ON COMMIT DROP;';
  raise notice '%', v_cmd;
  EXECUTE(v_cmd);
  if (select count(*) from i_productionplan)=0 then
        return 'Es wurden keine Daten übernommen.';
  end if;
  
  EXECUTE('ALTER TABLE c_projecttask DISABLE TRIGGER zssm_productionplan_generate_trg;');
  
  for v_cur in (select * from i_productionplan order by value,Workstepsearchkey,Sortno) 
  LOOP
        if v_cur.product is not null and (select count(*) from m_product where value=v_cur.product and typeofproduct in ('AS','CD'))!=1 then
            raise exception '%','Artikel existiert nicht oder keine Baugruppe : '||v_cur.product;
        end if;
        select ad_org_id into v_org from ad_org where name=v_cur.ad_org_id;
        if v_org is null or v_org='0' then
            raise exception '%','Organisation existiert nicht (oder nicht erlaubt) '||coalesce(v_cur.ad_org_id,'NULL');
        end if;
        v_product:=null;
        select ad_user_id into v_partner from ad_user  where name=v_cur.responsible_Id;
        if (select count(*) from m_product where value=v_cur.product and typeofproduct in ('AS','CD'))=1 then
            select m_product_id into v_product from m_product where value=v_cur.product and typeofproduct in ('AS','CD');
        end if;
        if (select count(*) from m_locator where value=v_cur.receiving_locator)=1 then
            select m_locator_id into v_recloc from m_locator where value=v_cur.receiving_locator;
        end if;
        if (select count(*) from m_locator where value=v_cur.issuing_locator)=1 then
            select m_locator_id into v_issloc from m_locator where value=v_cur.issuing_locator;
        end if;
        if (select count(*) from c_color where name=v_cur.c_color_id)=1 then
            select c_color_id into v_color from c_color where name=v_cur.c_color_id;
        end if;
        select ma_Machine_Id into v_maschine from ma_machine where name=v_cur.ma_Machine_Id;
        select c_Salary_Category_Id into v_salcat from c_Salary_Category where name=v_cur.c_Salary_Category_Id;
        -- Create or Update Plan
        if v_cur.value!=currentAssemply then
            select c_project_id into v_requid from c_project where value=v_cur.value;
            if v_requid is not null then            
                delete from zssm_productionplan_task where c_project_id=v_requid;
                delete from c_project where c_project_id=v_requid;
           end if;
                v_requid:=get_uuid();
                insert into c_project(c_project_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  isactive, isdefault,isautotriggered,value,name,description,note,responsible_id,projectcategory,c_currency_id)
                            values(v_requid,v_client,v_org,p_user,p_user,v_cur.isactive, v_cur.isdefault,'N',v_cur.value,v_cur.name,v_cur.description,v_cur.note,v_partner,'PRP','102');
                INSERT INTO i_imported_projects(c_project_id, isautotriggered) VALUES(v_requid, v_cur.isautotriggered);
            
            currentAssemply:=v_cur.value;
            v_i:=v_i+1;
        end if;
        -- Create or Update Workstep
        if v_cur.workstepsearchkey!=v_currentptask then
             select c_projecttask_id into v_ptid from c_projecttask where value=v_cur.workstepsearchkey and c_project_id is null;
             if v_ptid is not null then
                update c_projecttask set AD_ORG_ID=v_org, CREATEDBY=p_user, UPDATEDBY=p_user,updated=now(), name=v_cur.workstepname,description=v_cur.workstepdescription,assembly=v_cur.assembly,
                                         m_product_id=v_product,startonlywithcompletematerial=v_cur.startonlywithcompletematerial,receiving_locator=v_recloc,
                                         issuing_locator=v_issloc,timeperpiece=to_number(coalesce(v_cur.timeperpiece,'0')),setuptime=to_number(coalesce(v_cur.setuptime,'0')),mimimumqty=to_number(coalesce(v_cur.mimimumqty,'0')),
                                         multipleofmimimumqty=v_cur.multipleofmimimumqty,c_Color_Id=v_color,isautogeneratedplan='N',simplyfiedmanufacturing=v_cur.simplyfiedmanufacturing, producecontinuously=v_cur.producecontinuously,
                                         istestingworkstep = v_cur.istestingworkstep
                        where  c_projecttask_id=v_ptid;
                delete from zspm_ptaskhrplan where c_projecttask_id=v_ptid;
                delete from zspm_ptaskmachineplan  where c_projecttask_id=v_ptid;
                delete from zspm_projecttaskbom  where c_projecttask_id=v_ptid; 
             else
                v_ptid:=get_uuid();
                insert into c_projecttask(c_projecttask_id,ad_client_id,AD_ORG_ID, CREATEDBY, UPDATEDBY, name,value,description,assembly,m_product_id,startonlywithcompletematerial,
                                         receiving_locator,issuing_locator,timeperpiece,setuptime,mimimumqty,multipleofmimimumqty,c_Color_Id,isautogeneratedplan,
                                         simplyfiedmanufacturing,qty,producecontinuously,istestingworkstep)
                       values(v_ptid,v_client,v_org,p_user,p_user,v_cur.workstepname,v_cur.Workstepsearchkey,v_cur.workstepdescription,v_cur.assembly,v_product,v_cur.startonlywithcompletematerial,
                                         v_recloc,v_issloc,to_number(coalesce(v_cur.timeperpiece,'0')),to_number(coalesce(v_cur.setuptime,'0')),to_number(coalesce(v_cur.mimimumqty,'0')),v_cur.multipleofmimimumqty,v_color,'N',
                                         v_cur.simplyfiedmanufacturing,1,v_cur.producecontinuously,v_cur.istestingworkstep);
             end if;
             
             UPDATE i_imported_projects SET last_c_projecttask_id = v_ptid, numofprojecttasks = 
                 CASE
                     WHEN numofprojecttasks IS NULL THEN 1
                     ELSE numofprojecttasks + 1
                 END
             WHERE i_imported_projects.c_project_id=v_requid;
             
             -- Write a new BOM
             if v_product is not null then
               if  c_getconfigoption('synchronizeworkstepboms',v_org)='Y'  then
                for v_cur2 in (select m_productbom_id,sum(bomqty) as bomqty,min(line) as line from m_product_bom where m_product_id=v_product and  workstepname is null group by m_productbom_id)
                LOOP
                     insert into zspm_projecttaskbom(zspm_projecttaskbom_id,ad_client_id,AD_ORG_ID, CREATEDBY, UPDATEDBY,c_projecttask_id,m_product_id,quantity,line,issuing_locator,receiving_locator)
                       values(get_uuid(),v_client,v_org,p_user,p_user,v_ptid,
                       v_cur2.m_productbom_id,v_cur2.bomqty,v_cur2.line,v_issloc,v_recloc);
                END LOOP;
               end if;
             else
                -- Durchreiche-Workstep                
                select product into v_prdval from i_productionplan where value=currentAssemply and to_number(coalesce(sortno,'0'))<to_number(coalesce(v_cur.sortno,'0')) and product is not null and assembly='Y' order by sortno desc limit 1;
                select m_product_id into v_product from m_product where value=v_prdval;
                --if v_product is not null then
                --    insert into zspm_projecttaskbom(zspm_projecttaskbom_id,ad_client_id,AD_ORG_ID, CREATEDBY, UPDATEDBY,c_projecttask_id,m_product_id,quantity,line,issuing_locator,receiving_locator)
                --       values(get_uuid(),v_client,v_org,p_user,p_user,v_ptid,v_product,1,10,v_issloc,v_recloc);
                --end if;                
             end if;
             -- Add Workstep to Plan
             insert into zssm_productionplan_task(zssm_productionplan_task_id,ad_client_id,AD_ORG_ID, CREATEDBY, UPDATEDBY,c_project_id,c_projecttask_id,sortno)
                    values(get_uuid(),v_client,v_org,p_user,p_user,v_requid,v_ptid,to_number(coalesce(v_cur.sortno,'0')));
             v_currentptask:=v_cur.workstepsearchkey;
        end if;
        -- Work Plan and Machines
        if v_salcat is not null and (select count(*) from zspm_ptaskhrplan where c_projecttask_id=v_ptid and c_Salary_Category_id=v_salcat)=0 then
            insert into zspm_ptaskhrplan(zspm_ptaskhrplan_id,c_projecttask_id,ad_client_id,AD_ORG_ID, CREATEDBY, UPDATEDBY,c_Salary_Category_Id,averageduration,durationunit)
                   values(get_uuid(),v_ptid,v_client,v_org,p_user,p_user,v_salcat,to_number(coalesce(v_cur.averageduration,'0')),v_cur.durationunit);
        end if;
        if v_maschine is not null and (select count(*) from zspm_ptaskmachineplan where c_projecttask_id=v_ptid and ma_machine_id=v_maschine)=0 then
            insert into zspm_ptaskmachineplan(zspm_ptaskmachineplan_id,c_projecttask_id,ad_client_id,AD_ORG_ID, CREATEDBY, UPDATEDBY,ma_Machine_Id,averageduration,durationunit)
                   values(get_uuid(),v_ptid,v_client,v_org,p_user,p_user,v_maschine,to_number(coalesce(v_cur.machineaverageduration,'0')),v_cur.machinedurationunit);
        end if;
        
    END LOOP;
    EXECUTE('ALTER TABLE c_projecttask ENABLE TRIGGER zssm_productionplan_generate_trg;');
    
    FOR v_cur IN (SELECT * FROM i_imported_projects)
    LOOP
        IF(v_cur.isautotriggered='Y' AND v_cur.numofprojecttasks=1) THEN
            UPDATE c_project SET isautotriggered='Y' WHERE c_project_id=v_cur.c_project_id;
            UPDATE c_projecttask SET isautotriggered='Y', isautogeneratedplan='Y' WHERE c_projecttask_id=v_cur.last_c_projecttask_id;
        END IF;
        
        PERFORM zssm_activateplan(v_cur.c_project_id);
    END LOOP;
    
    FOR v_cur IN (SELECT * FROM i_imported_projects)
    LOOP
        IF((SELECT projectstatus FROM c_project WHERE c_project_id=v_cur.c_project_id) is NULL) THEN
            RAISE EXCEPTION 'Produktionsplan % konnte nicht aktiviert werden.', (SELECT name FROM c_project WHERE c_project_id=v_cur.c_project_id);
        END IF;
    END LOOP;
    
    return v_i||' Produktionspläne importiert.';
    
EXCEPTION
    WHEN OTHERS THEN
        EXECUTE('ALTER TABLE c_projecttask ENABLE TRIGGER zssm_productionplan_generate_trg;');
        raise exception '%',' @ERROR=' || SQLERRM;
END;
$_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION  i_import_erp2go_invoicing(p_filename varchar,p_user varchar, p_orgid varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE
BEGIN
    return '';
END;
$_$  LANGUAGE 'plpgsql';


select zsse_DropView ('i_inventory_v');
CREATE OR REPLACE VIeW i_inventory_v as
select
il.m_inventoryline_id as i_inventory_v_id,
il.AD_CLIENT_ID,
il.AD_ORG_ID,
il.CREATEDBY,
il.created,
il.UPDATEDBY,
il.updated,
il.isactive,
i.name as inventory_name,
il.m_locator_id,
il.description,
il.m_attributesetinstance_id,
il.value,
il.name,
il.qtycount
from m_inventoryline il left join m_inventory i on i.m_inventory_id = il.m_inventory_id
where i.processed = 'N';

CREATE or replace FUNCTION i_import_inventory(p_filename varchar,p_user varchar, p_org_id varchar, p_delimiter varchar) RETURNS varchar
AS $_$
DECLARE
-- Crazy dynamical import format stuff...
v_cur RECORD;
v_cmd varchar:='';
 
v_org varchar;
v_warehouse varchar;
v_locator varchar;
v_inventory varchar;
v_product varchar;
v_i numeric:=0;
v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_uom varchar;
v_attribute varchar;
v_qtybook numeric;
v_lang varchar;
BEGIN
    if p_filename is null then return 'ERROR'; end if;
    -- Dynamisches allozieren der Felder
    -- Format anziehen (TAB: Export Physical Inventory)
    perform zsse_droptable ('i_import_inventory');
    -- Format anziehen (TAB: Export Offer)
    for v_cur in (select pname,pad_ref_fieldcolumn_id from ad_selecttabfields('DE_de','BC03487707374AC1973A812133F73359') order by pline)
    LOOP
      if ad_fieldGetVisibleLogic(v_cur.pad_ref_fieldcolumn_id,'')='VISIBLE' then
          if v_cmd='' then
              v_cmd:='create temporary table i_import_inventory(';
          else
              v_cmd := v_cmd ||', ';
          end if;
          v_cmd := v_cmd ||v_cur.pname||' text';
      end if;
    END LOOP;
    v_cmd := v_cmd ||' )  ON COMMIT DROP';
    RAISE notice '%', v_cmd;
    EXECUTE(v_cmd);
    -- Datei in Tabelle
    v_cmd := 'COPY i_import_inventory FROM ''' || p_filename ||''' CSV DELIMITER as '||chr(39)||p_delimiter||chr(39)||' HEADER ;';
    EXECUTE(v_cmd);
    v_cmd := 'alter table i_import_inventory add column idds character varying(32) not null default get_uuid()';
    EXECUTE(v_cmd);
    select ad_language into v_lang from ad_client  where ad_client_id=v_client;

    if (select count(distinct inventory_name) from i_import_inventory)!=1 then
        raise exception '%','Es kann nur eine Inventur importiert werden';
    end if;

    for v_cur in (select * from i_import_inventory)
    LOOP
        -- Pflichtfelder
        v_inventory:=null;
        select m_inventory_id into v_inventory from m_inventory where m_inventory.name = v_cur.inventory_name and m_inventory.processed = 'N';
        if v_inventory is null then
            raise exception '%','Inventur nicht geöffnet: '||v_cur.inventory_name;
        end if;
        v_org:=null;
        select ad_org_id into v_org from m_inventory where m_inventory_id=v_inventory;
        if v_org is null or v_org='0' then
            raise exception '%','Organisation existiert nicht (oder nicht erlaubt) '||coalesce(v_cur.ad_org_id,'NULL');
        end if;
        v_warehouse:=null;
        select m_warehouse_id into v_warehouse from m_inventory where m_inventory_id = v_inventory;
        if v_warehouse is null then
            raise exception '%','Lager nicht gefunden: '||v_cur.m_warehouse_id;
        end if;
        v_locator:=null;
        if (select count(*) from m_locator where value=v_cur.m_locator_id)=1 then
            select m_locator_id into v_locator from m_locator where value=v_cur.m_locator_id;
        end if;
        if v_locator is null then
            raise exception '%','Lagerort nicht gefunden: '||v_cur.m_locator_id;
        end if;
        v_product:=null;
        if (select count(*) from m_product where value=v_cur.value)=1 then
            select m_product_id into v_product from m_product where value=v_cur.value;
        end if;
        if v_product is null then
            raise exception '%','Artikel nicht gefunden: '||v_cur.value;
        end if;
        if v_cur.qtycount is null then
            raise exception '%','Gezählte Menge nicht angegeben: ' || v_cur.value;
        end if;

        -- weitere Felder
        v_uom:=null;
        select c_uom_id into v_uom from m_product where m_product_id = v_product;
        v_attribute:=null;
        select m_attributesetinstance_id into v_attribute from m_attributesetinstance where description = v_cur.m_attributesetinstance_id and isactive = 'Y'
                                                                                       and m_attributeset_id = (select m_attributeset_id from m_product where m_product_id = v_product);
        if v_attribute is null and v_cur.m_attributesetinstance_id is not null then
            raise exception '%','Attribut im System unbekannt: ' || v_cur.m_attributesetinstance_id || ' für Artikel ' || v_cur.value;
        end if;
        v_qtybook:=null;
        select qtyonhand into v_qtybook from zssi_onhanqty where m_product_id = v_product and m_locator_id = v_locator;

        -- delete all inventorylines from current inventory
        delete from m_inventoryline where m_inventory_id = v_inventory and v_i = 0; -- only on first loop
        -- insert new imported inventorylines
        insert into m_inventoryline (m_inventoryline_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
                                     m_inventory_id, m_locator_id, m_product_id, line, qtycount, description, m_attributesetinstance_id, c_uom_id, value, name, qtybook)
                             values (v_cur.idds, v_client, v_org, 'Y', now(), p_user, now(), p_user,
                                     v_inventory, v_locator, v_product, 10*(v_i+1), coalesce(v_qtybook,0), v_cur.description, v_attribute, v_uom, v_cur.value, v_cur.name, coalesce(v_qtybook,0));
        -- insert with qtycount = qtybook and update qtycount
        -- prevents errors with snr/bnr
        update m_inventoryline set qtycount = coalesce(to_number(v_cur.qtycount),0) where m_inventoryline_id = v_cur.idds;

        v_i := v_i + 1;

    END LOOP;
    return v_i||' Inventurzeilen importiert';
EXCEPTION
    WHEN OTHERS THEN
        raise exception '%',' @ERROR=' || SQLERRM;
END;
$_$  LANGUAGE 'plpgsql';
