drop table  zsi_keytab;
drop table  zsi_bpartner;
drop table  zsi_bp_contact;
drop table  zsi_bp_location;
drop table  zsi_bp_customer;
drop table  zsi_bp_bank;
drop table  zsi_bp_vendor;

drop table  zsi_product;
drop table  zsi_productbom;
drop table  zsi_productpo;
drop table  zsi_productorg;
drop table  zsi_productprice;
drop table  zsi_productuom;
drop table  zsi_producttrl;
drop table  zsi_productcalculation;

drop function zsi_checkdata();


select zsse_dropfunction('zsi_bpartnerimport');


CREATE TABLE zsi_keytab
(
  keycolumname character varying(250),
  target_table character varying(250),
  target_column character varying(250)
)
WITH (
  OIDS=TRUE);

-- copy (select * from zsi_keytab) to '/tmp/keytab.sql';
copy zsi_keytab from '/tmp/keytab.sql';


create table zsi_product (value character varying(250),
name character varying(250),
name2 character varying(250),
org_key character varying(250),
upc character varying(250),
description character varying(2000),
documentnote character varying(2000),
pcategory_key character varying(250),
producttype character varying(250),
uom_key character varying(250),
salesrep_key character varying(250),
typeofproduct character varying(250),
isserialtracking character varying(250),
isbatchtracking character varying(250),
weight character varying(250),
volume character varying(250),
shelfwidth character varying(250),
shelfheight character varying(250),
shelfdepth character varying(250),
unitsperpallet character varying(250),
locator_key character varying(250),
isstocked character varying(250),
isserviceitem character varying(250),
issparepart character varying(250),
isconsumable character varying(250),
production character varying(250),
isbom character varying(250),
ispurchased character varying(250),
issold character varying(250),
tax_key character varying(250),
imageurl character varying(250),
descriptionurl character varying(250),
attributeset_key character varying(250),
manufacturer character varying(250),
manufacturernumber character varying(250)
--customfield1 character varying(250),
--customfield2 character varying(250),
--customfield3 character varying(250),
--customfield4 character varying(250)
);



create table zsi_productbom(productvalue_key character varying(250),
bomproductvalue_key  character varying(250),
line character varying(250),
isactive character varying(250) default 'Y',
bomqty character varying(250),
description character varying(255),
constuctivemeasure character varying(255),
rawmaterial character varying(255));



create table zsi_productpo(productvalue_key character varying(250),
bpartnervalue_key  character varying(250),
org_key character varying(250),
qualityrating character varying(250),
isactive character varying(250) default 'Y',
iscurrentvendor character varying(250),
upc character varying(255),
currency_key  character varying(255),
pricelist character varying(255),
pricepo  character varying(255), 
priceeffective character varying(255),
uom_key  character varying(255),
order_min character varying(255),
deliverytime_promised character varying(255),
vendorproductno character varying(255),
vendorcategory character varying(255),
manufacturer character varying(255),
qtytype character varying(255),
qtystd character varying(255));



create table zsi_productorg(productvalue_key character varying(250),
locator_key character varying(250),
isvendorreceiptlocator character varying(250),
planingmethod_key character varying(250),
capacity character varying(250),
stockmin character varying(250),
qtyoptimal character varying(250),
org_key  character varying(250)
);

create table zsi_productprice(productvalue_key character varying(250),
org_key character varying(250),
pricelistversion_key character varying(250),
isactive character varying(250) default 'Y',
pricelist character varying(250),
pricestd character varying(250),
pricelimit character varying(250)
);

create table zsi_productuom(productvalue_key character varying(250),
uom_key character varying(250)
);


create table zsi_productcalculation(
productvalue_key  character varying(250),
org_key character varying(250),
cost              character varying(250),
costtype          character varying(250),
ismanual          character varying(250),
ispermanent       character varying(250)
);
  
--insert into zsi_productcalculation(productvalue_key,org_key,cost,costtype,ismanual,ispermanent)
--select p.value,'',0,'ST','Y','N' from m_product p where m_bom_qty_onhand(p.m_product_id,'',null)>0 and m_bom_qty_onhand(p.m_product_id,'',null)!=99999 order by p.value;
--copy (select i.productvalue_key,i.org_key,i.cost,i.costtype,i.ismanual,i.ispermanent from zsi_productcalculation i) to '/tmp/ProductCOSTING.csv' CSV DELIMITER as ';' HEADER; 
--CSV DELIMITER as ';' HEADER;



create table zsi_producttrl(productvalue_key character varying(250),
language_key character varying(250),
name character varying(250),
description character varying(2000),
documentnote character varying(2000),
isactive character varying(250) default 'Y',
istranslated character varying(250));

create table zsi_bpartner (
value character varying(250),
name character varying(250),
Org_key character varying(250),
name2 character varying(250),
description character varying(2000),
isactive character varying(250) default 'Y',
issaleslead character varying(250),
referenceno character varying(250),
rating character varying(250),
owncodeatpartnersite character varying(250),
BPGroup_key character varying(250),
Language_key character varying(250),
groupofcompanies_key character varying(250),
URL character varying(250));


create table zsi_bp_contact (
bp_value_key character varying(250),
greeting_key  character varying(250),
firstname character varying(250),
lastname character varying(250),
name character varying(250),
birthday character varying(250),
title character varying(250),
email character varying(250),
phone character varying(250),
phone2 character varying(250),
fax character varying(250),
description character varying(255),
comments character varying(2000),
isactive  character varying(250) default 'Y');



create table zsi_bp_location (
bp_value_key character varying(250),
deviantbpartnername character varying(250),
isactive  character varying(250) default 'Y',
address1 character varying(250),
address2 character varying(250),
postal character varying(250),
city character varying(250),
country_key character varying(250),
phone character varying(250),
phone2 character varying(250),
fax character varying(250),
isshipto character varying(250),
isbillto character varying(250),
isremitto character varying(250),
ispayfrom character varying(250),
istaxlocation character varying(250),
isheadquarter character varying(250),
uidnumber character varying(250),
tax_key character varying(250),
salesregion_key character varying(250));


create table zsi_bp_customer (
bp_value_key character varying(250),
isactive  character varying(250) default 'Y',
iscustomer character varying(250),
invoicerule character varying(250),
invoiceschedule_key character varying(250),
invoicegrouping character varying(250),
deliveryrule character varying(250),
deliveryviarule character varying(250),
pricelist_key character varying(250),
paymentrule character varying(250),
paymentterm_key character varying(250),
salesrep_key character varying(250),
so_creditlimit character varying(250),
fixmonthday    character varying(250),
fixmonthday2     character varying(250),   
fixmonthday3 character varying(250));

create table zsi_bp_vendor (
bp_value_key character varying(250),
isvendor character varying(250),
paymentrulepo character varying(250),
po_paymentterm_key character varying(250),
po_pricelist_key character varying(250),
po_fixmonthday    character varying(250),
po_fixmonthday2     character varying(250),   
po_fixmonthday3 character varying(250));



create table zsi_bp_bank (
bp_value_key character varying(250),
isactive character varying(250) default 'Y',
accountno character varying(250),
showaccountno character varying(250),
routingno character varying(250),
iban character varying(250),
showiban character varying(250),
swiftcode character varying(250),
country_key character varying(250),
bank_name character varying(250),
a_name character varying(250));

--CREATE table zsi_productchanges (valuenew character varying(250), name character varying(250), valueold character varying(250));



CREATE or replace FUNCTION  zsi_checkdata() RETURNS character varying
AS $_$
DECLARE
i integer;
ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';
v_count numeric;
v_lc     numeric;
v_targettable character varying;
v_targetcol character varying; 
v_sql  character varying; 
v_sql2  character varying;
v_null  character varying;
v_type  character varying;
v_length  character varying;
v_table  character varying;
v_temp  character varying;

v_cur RECORD;
v_cur2 RECORD;
v_cur3 RECORD;
TYPE_Ref REFCURSOR;
v_cursor3 TYPE_Ref%TYPE;
v_cursor2 TYPE_Ref%TYPE;
BEGIN 
   -- Some common Updates
   update ZSI_BP_BANK set country_key = (select countrycode from c_country where name=ZSI_BP_BANK.country_key) 
       where country_key not in (select countrycode from c_country);

   update zsi_bp_location set country_key = (select countrycode from c_country where name=zsi_bp_location.country_key) 
       where country_key not in (select countrycode from c_country);
   
   -- Valuelist - Updates and Valuelist Checks
   update zsi_bp_customer set invoicerule = case when invoicerule='Immediate' then 'I' when invoicerule='After Delivery' then 'D'  when invoicerule='Do not invoice' then 'N' when invoicerule='After Order delivered' then 'O'  when invoicerule='Customer Schedule after Delivery' then 'S' end
                          where invoicerule is not null;
   select count(*) into v_count from zsi_bp_customer where coalesce(invoicerule,'I') not in ('I','D','N','O','S');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Invoice Rule(s) in Customer Import';
   end if;
   update zsi_bp_customer set invoicegrouping =  case when invoicegrouping='By customer' then '000000000000000' when invoicegrouping='By project' then '000000000010000' when invoicegrouping='By ship location' then '000010000000000' end
                           where invoicegrouping is not null;
   select count(*) into v_count from zsi_bp_customer where coalesce(invoicegrouping,'000000000000000') not in ('000000000000000','000000000010000','000010000000000');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Invoice Grouping(s) in Customer Import';
   end if;
   update zsi_bp_customer set deliveryviarule =  case when deliveryviarule='Delivery' then 'D' when deliveryviarule='Pickup' then 'P' end
                          where deliveryviarule is not null;
   select count(*) into v_count from zsi_bp_customer where coalesce(deliveryviarule,'P') not in ('D','P');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Delivery Via Rule(s) in Customer Import';
   end if;
   update zsi_bp_customer set deliveryrule =  case when deliveryrule='Availability' then 'A' when deliveryrule='Complete Line' then 'L'  when deliveryrule='Complete Order' then 'O'  when deliveryrule='After Receipt' then 'R' end
                           where deliveryrule is not null;
   select count(*) into v_count from zsi_bp_customer where coalesce(deliveryrule,'R') not in ('A', 'L','O','R');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Delivery Rule(s) in Customer Import';
   end if;
   update zsi_bp_customer set paymentrule =  case  when paymentrule='Bank Remittance' then 'R' when paymentrule='Check' then '2' when paymentrule='Cash' then 'B'  when paymentrule='Cash on Delivery' then 'C'  when paymentrule='Credit Card' then 'K'   when paymentrule='On Credit' then 'P' end
                          where paymentrule is not null;
   select count(*) into v_count from zsi_bp_customer where  coalesce(paymentrule,'2') not in ('B' ,'C', 'K', 'P', 'R','2');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Payment Rule(s) in Customer Import';
   end if;
   update zsi_bp_vendor set paymentrulepo =  case  when paymentrulepo='Bank Remittance' then 'R' when paymentrulepo='Check' then '2' when paymentrulepo='Cash' then 'B'  when paymentrulepo='Cash on Delivery' then 'C'  when paymentrulepo='Credit Card' then 'K'   when paymentrulepo='On Credit' then 'P' end
                        where paymentrulepo is not null;
   select count(*) into v_count from zsi_bp_vendor where  coalesce(paymentrulepo,'2') not in ('B', 'C', 'K', 'P', 'R','2');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Payment Rule(s) in Vendor Import';
   end if;
   update zsi_product  set typeofproduct = case  when typeofproduct ='Assembly' then 'AS' when typeofproduct ='Construction Design' then 'CD' when typeofproduct ='Standard Assembly' then 'SA' when typeofproduct ='Standard' then 'ST'  when typeofproduct ='Sub Assembly' then 'UA'  
                                           else null end where typeofproduct in ('Assembly','Construction Design','Standard Assembly','Standard','Sub Assembly');
   select count(*) into v_count from zsi_product where  coalesce(typeofproduct,'xx') not in ('AS', 'CD', 'EX', 'SA', 'SP', 'ST','UA');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Type(s) of Product  in Product Import';
   end if;
   update zsi_product  set producttype = case when producttype='Item'  then 'I' when producttype='Service'  then 'S' else null end 
                                         where producttype in ('Item','Service');
   select count(*) into v_count from zsi_product where   coalesce(producttype, 'x') not in ('I', 'S');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Product Type(s) in Product Import';
   end if;
   update zsi_productpo  set qtytype = case when qtytype='Exact'  then 'E' when qtytype='Multiple'  then 'M' end
                          where qtytype is not null;
   select count(*) into v_count from zsi_productcalculation where costtype not in ('AV','ST');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid Cost Type(s) in Product Import';
   end if;
                          
   -- Dup's Checks
   select count(*) into v_count from zsi_productpo where   coalesce(qtytype, 'M') not in ('E', 'M');
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||' invalid QuantityType(s) in Product Import';
   end if;
   select count(*) into v_count from zsi_bp_customer group by bp_value_key having count(*)>1;
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||'  More than one Customer entry';
   end if;
   select count(*) into v_count from zsi_bp_vendor group by bp_value_key having count(*)>1;
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||'  More than one Vendor entry';
   end if;
   select count(*) into v_count from zsi_bpartner group by value having count(*)>1;
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||'  More than one Partner entry';
   end if;
   select count(*) into v_count from zsi_product group by value having count(*)>1;
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||'  More than one Product entry';
   end if;
   select count(*) into v_count from m_locator group by value having count(*)>1;
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||'  Locators count>1 ; Edit Value of Locators in OpenZ';
   end if;
   select count(*) into v_count from m_pricelist_version group by name having count(*)>1;
   if v_count>0 then
       RAISE EXCEPTION '%', v_count||'  Pricelist-Versions count>1 ; Edit Name of Pricelist-Versions in OpenZ';
   end if;
   


   for v_cur in (select table_name,column_name from user_tab_columns where lower(table_name) in ('zsi_product','zsi_producttrl','zsi_productbom','zsi_productpo','zsi_productorg','zsi_productuom','zsi_productprice','zsi_inventory','zsi_productcalculation',
    'zsi_bpartner','zsi_bp_contact','zsi_bp_location','zsi_bp_customer','zsi_bp_vendor','zsi_bp_bank'))
   LOOP
       if  lower(v_cur.column_name) like  '%_key' then
            select target_table,target_column into v_targettable,v_targetcol from zsi_keytab where lower(keycolumname)=lower(v_cur.column_name);
             v_sql:='select '||v_cur.column_name||' as key from '||v_cur.table_name;
             --RAISE NOTICE '%','Keycheck_1: '||v_sql;
             OPEN v_cursor2  FOR EXECUTE v_sql;
             LOOP
                    FETCH v_cursor2 INTO v_cur2;
                    EXIT WHEN NOT FOUND;
                    if v_cur2.key is not null and lower(v_cur.column_name) not in ('bp_value_key','bpartnervalue_key','productvalue_key') then
                        v_sql:='select count(*) as schouldbe1 from '||v_targettable||' where '||v_targetcol||'='''||case when v_cur2.key='*' then '0' else v_cur2.key end||'''';
                        RAISE NOTICE '%','Keycheck_2: '||coalesce(v_sql,'NIX!')||coalesce(v_targettable,'TTNIX')||coalesce(v_targetcol,'TNIX')||coalesce(v_cur2.key,'KNIX')||'#'||lower(v_cur.column_name);
                        v_lc:=0;
                        OPEN v_cursor3 FOR EXECUTE v_sql;
                        LOOP
                            --RAISE NOTICE '%','Keycheck_3 :'||coalesce(v_sql,'NIX!');
                            FETCH v_cursor3 INTO v_cur3;
                            v_lc:=v_lc+1;
                            v_count:=0;
                            if coalesce(v_cur3.schouldbe1,0)=0  then
                                if lower(v_cur.column_name) in ('bp_value_key','bpartnervalue_key') then
                                  select count(*) into v_count from zsi_bpartner where value= v_cur2.key;
                                elsif lower(v_cur.column_name) in ('productvalue_key') then
                                  select count(*) into v_count from zsi_product where value=v_cur2.key;
                                end if;
                                if v_count=0 then
                                  RAISE NOTICE '%', 'SQL: '||v_sql;
                                  RAISE EXCEPTION '%', 'Key Column Error: In Table '||v_targettable||', Column '||v_targetcol||' For Value '||v_cur2.key||'; '||coalesce(v_cur3.schouldbe1,0)||' Rows found. Import:'||v_cur.table_name||'; Column:'||v_cur.column_name;
                                end if;
                            end if;
                            EXIT WHEN v_lc=1;
                        END LOOP;
                        CLOSE v_cursor3;
                    end if;
             END LOOP;
             CLOSE v_cursor2;
        else
           select data_type,data_length,nullable,table_name into v_type,v_length,v_null,v_table from user_tab_columns where column_name=v_cur.column_name and lower(table_name) in ('m_product','m_inventory','m_product_trl','m_product_bom','m_product_po','m_product_org','m_product_uom','m_productprice',
                                 'c_bpartner','ad_user','c_bpartner_location','c_bp_bankaccount','m_costing') limit 1;
           if v_type='BPCHAR' then
              if v_null='f' then
                 v_sql:= 'select count(*) as schouldbe0 from '||v_cur.table_name||' where coalesce('||v_cur.column_name||',''X'') not in (''Y'',''N'')';
              else
                 v_sql:=  'select count(*) as schouldbe0 from '||v_cur.table_name||' where '||v_cur.column_name||' not in (''Y'',''N'')';
              end if;
              OPEN v_cursor3 FOR EXECUTE v_sql;
              LOOP
                  FETCH v_cursor3 INTO v_cur3;
                  EXIT WHEN NOT FOUND;
                  if v_cur3.schouldbe0!=0 then
                     RAISE NOTICE '%', 'SQL: '||v_sql;
                     RAISE EXCEPTION '%', v_cur3.schouldbe0||'Datatype-Error: '||v_table||','||v_cur.column_name||' schould be '||v_type||';nullable:'||v_null||' source: '||v_cur.table_name;
                  end if;
              END LOOP;
              CLOSE v_cursor3;
           elsif v_type='VARCHAR' then
              if v_null='f' then
                 v_sql:= 'select count(*) as schouldbe0 from '||v_cur.table_name||' where length('||v_cur.column_name||')>'||v_length||' or '||v_cur.column_name||' is null';
              else
                v_sql:= 'select count(*) as schouldbe0 from '||v_cur.table_name||' where length('||v_cur.column_name||')>'||v_length;
              end if;
              OPEN v_cursor3 FOR EXECUTE v_sql;
              LOOP
                  FETCH v_cursor3 INTO v_cur3;
                  EXIT WHEN NOT FOUND;
                  if v_cur3.schouldbe0!=0 then
                     RAISE NOTICE '%', 'SQL: '||v_sql;
                     RAISE EXCEPTION '%', v_cur3.schouldbe0||'Datatype-Error: '||v_table||','||v_cur.column_name||' schould be '||v_type||';length:'||v_length||';nullable:'||v_null||' source: '||v_cur.table_name;
                  end if;
              END LOOP;
              CLOSE v_cursor3;
           elsif v_type='TIMESTAMP' then
              if v_null='f' then
                 v_sql:= 'select count(*) as schouldbe0 from '||v_cur.table_name||' where to_char(to_date('||v_cur.column_name||',''DD-MM-YYYY''))=''01-01-0001'' or '||v_cur.column_name||' is null';
              else
                v_sql:= 'select count(*) as schouldbe0 from '||v_cur.table_name||' where to_char(to_date('||v_cur.column_name||',''DD-MM-YYYY''))=''01-01-0001''';
              end if;
              OPEN v_cursor3 FOR EXECUTE v_sql;
              LOOP
                  FETCH v_cursor3 INTO v_cur3;
                  EXIT WHEN NOT FOUND;
                  if v_cur3.schouldbe0!=0 then
                     RAISE NOTICE '%', 'SQL: '||v_sql;
                     RAISE EXCEPTION '%', v_cur3.schouldbe0||'Datatype-Error: '||v_table||','||v_cur.column_name||' schould be '||v_type||';length:'||v_length||';nullable:'||v_null||' source: '||v_cur.table_name;
                  end if;
              END LOOP;
              CLOSE v_cursor3;
           elsif v_type='NUMBER' then
              if v_null='f' then
                v_sql:= 'select count(*) as schouldbe0 from '||v_cur.table_name||' where to_number('||v_cur.column_name||') is null';
              else
                v_sql:= 'select count(*) as schouldbe0 from '||v_cur.table_name||' where to_number(coalesce('||v_cur.column_name||',''0'')) is null';
              end if;
              OPEN v_cursor3 FOR EXECUTE v_sql;
              LOOP
                  FETCH v_cursor3 INTO v_cur3;
                  EXIT WHEN NOT FOUND;
                  if v_cur3.schouldbe0!=0 then
                     RAISE NOTICE '%', 'SQL: '||v_sql;
                     RAISE EXCEPTION '%', v_cur3.schouldbe0||'Datatype-Error: '||v_table||','||v_cur.column_name||' schould be '||v_type||';length:'||v_length||';nullable:'||v_null||' source: '||v_cur.table_name;
                  end if;
              END LOOP;
              CLOSE v_cursor3;
           end if;
        end if;
   END LOOP;
     RETURN 'Data Checked ...  OK';
END;
$_$  LANGUAGE 'plpgsql';

     

