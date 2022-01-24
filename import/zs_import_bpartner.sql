 
CREATE or replace FUNCTION  zsi_bpartnerimport(p_deleteexisting character varying) RETURNS void
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_org character varying;
v_bpid character varying;
v_bpgroup character varying;
v_goc character varying;
v_lang character varying;
v_greeting character varying;
v_locid character varying;
v_country character varying;
v_tax character varying;
v_salesregion character varying;
v_countryneme character varying;

v_invoiceschedule character varying;
v_pricelist character varying;
v_paymentterm character varying;
v_user character varying;
v_ishead character varying;
v_temp varchar;

v_count numeric;
v_cur RECORD;
v_cur2 RECORD;

BEGIN

  for v_cur in (select distinct * from zsi_bpartner) 
  LOOP
    select ad_org_id into v_org from ad_org where value= case when v_cur.Org_key='*' then '0' else v_cur.Org_key end;
    select C_BP_GROUP_ID into v_bpgroup from c_BP_GROUP where value=v_cur.BPGroup_key and case when v_cur.Org_key='*' then ad_org_id='0' else ad_org_id=v_org end;
    if v_bpgroup is null then
         select C_BP_GROUP_ID into v_bpgroup from c_BP_GROUP where value=v_cur.BPGroup_key;
    end if;
    select zssi_groupofcompanies_id into v_goc from zssi_groupofcompanies where name=v_cur.groupofcompanies_key and case when v_cur.Org_key='*' then ad_org_id='0' else ad_org_id=v_org end;
    select ad_language_id into v_lang from ad_language where ad_language=v_cur.Language_key;
    select c_bpartner_id into v_bpid from c_bpartner where value=v_cur.value and ad_org_id=v_org;
    if v_bpid is null then
        select get_uuid() into v_bpid;
        --RAISE NOTICE '%','Updatin'||v_cur.BPGroup_key||'___'||v_cur.Org_key||coalesce(v_org,'------')||'----'||coalesce(v_bpgroup,'#####');
        insert into c_bpartner(C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                            VALUE, NAME, NAME2, DESCRIPTION, isactive,issaleslead,referenceno,rating,owncodeatpartnersite, C_BP_GROUP_ID, ad_language,zssi_groupofcompanies_id,  URL)
                        values(v_bpid,ad_client,v_org,now(),creator,now(),creator,
                               v_cur.value,v_cur.NAME,v_cur.NAME2,v_cur.DESCRIPTION,v_cur.isactive,v_cur.issaleslead,v_cur.referenceno,v_cur.rating,v_cur.owncodeatpartnersite,v_bpgroup,v_cur.Language_key,v_goc,v_cur.URL);
        if (select count(*) from zsi_bp_location where bp_value_key=v_cur.value)>0 then
            select count(*) into v_count from C_BPARTNER_LOCATION where name='Standard -  - Deutschland' and c_bpartner_id=v_bpid;
                    if v_count=1 then 
                       -- Forget the automatically created entry
                       select C_LOCATION_id into v_temp from C_BPARTNER_LOCATION where name='Standard -  - Deutschland' and c_bpartner_id=v_bpid;
                       update C_BPARTNER set C_LOCATION_id=null where c_bpartner_id=v_bpid;
                       delete  from C_BPARTNER_LOCATION where name='Standard -  - Deutschland' and c_bpartner_id=v_bpid;
                       delete from c_location where c_location_id=v_temp;
                    end if;
        end if;
    else
       update c_bpartner set NAME=v_cur.NAME, NAME2=v_cur.NAME2, DESCRIPTION=v_cur.DESCRIPTION, isactive=v_cur.isactive,issaleslead=v_cur.issaleslead,referenceno=v_cur.referenceno,
                             rating=v_cur.rating,owncodeatpartnersite=v_cur.owncodeatpartnersite, C_BP_GROUP_ID=v_bpgroup, ad_language=v_cur.Language_key,zssi_groupofcompanies_id=v_goc,URL=v_cur.URL
                         where  c_bpartner_id=v_bpid;
    end if;
    if coalesce(p_deleteexisting,'N')='Y' then
       delete from ad_user where c_bpartner_id=v_bpid;
       delete from c_bpartner_location where c_bpartner_id=v_bpid;
       delete from c_bp_bankaccount where c_bpartner_id=v_bpid;
    end if;
    for v_cur2 in (select * from zsi_bp_contact where bp_value_key=v_cur.value)
    LOOP
        select c_greeting_id into v_greeting from c_greeting where name=v_cur2.greeting_key;
        insert into ad_user (ad_user_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,C_BPARTNER_ID,
                               c_greeting_id,firstname,lastname,name,birthday,title,email,phone2,phone,fax,description,comments,isactive)
               values(get_uuid(),ad_client,v_org,now(),creator,now(),creator,v_bpid,
                      v_greeting,v_cur2.firstname,v_cur2.lastname,v_cur2.name,to_date(v_cur2.birthday,'DD-MM-YYYY'),v_cur2.title,v_cur2.email,v_cur2.phone2,v_cur2.phone,v_cur2.fax,v_cur2.description,v_cur2.comments,v_cur2.isactive);
    END LOOP;
    for v_cur2 in (select * from zsi_bp_location where bp_value_key=v_cur.value)
    LOOP
        select get_uuid() into v_locid;
        select c_country_id into v_country from c_country where countrycode=coalesce(v_cur2.country_key,'DE');
        select name into v_countryneme  from c_country where c_country_id=v_country;
        select c_tax_id into v_tax from c_tax where name=v_cur2.tax_key;
        select c_salesregion_id into v_salesregion from c_salesregion where value=v_cur2.salesregion_key;
        select count(*) into v_count from c_bpartner_location where c_bpartner_id=v_bpid and isheadquarter='Y';
        if v_count=1 then v_ishead:='N'; else v_ishead:='Y'; end if;
        --RAISE NOTICE '%','Loc'||v_cur2.country_key;
        insert into c_location(c_location_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                               address1,address2,postal,city,c_country_id)
               values (v_locid,ad_client,v_org,now(),creator,now(),creator,
                       v_cur2.address1,v_cur2.address2,v_cur2.postal,v_cur2.city,v_country);
        insert into c_bpartner_location(c_bpartner_location_id,c_location_id,c_bpartner_id,c_tax_id,c_salesregion_id,deviant_bp_name,
                                        AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                        phone,phone2,fax,isshipto,isbillto,isremitto,istaxlocation,isheadquarter,uidnumber,name)
               values(get_uuid(),v_locid,v_bpid,v_tax,v_salesregion,substr(v_cur2.deviantbpartnername,1,60),ad_client,v_org,now(),creator,now(),creator,
                      v_cur2.phone,v_cur2.phone2,v_cur2.fax,v_cur2.isshipto,v_cur2.isbillto,v_cur2.isremitto,v_cur2.istaxlocation,v_ishead,v_cur2.uidnumber,
                      substr(coalesce(v_countryneme,'')||','||coalesce(v_cur2.city,'')||','||coalesce(v_cur2.address1,''),1,60));
    END LOOP;
    select c_invoiceschedule_id into v_invoiceschedule from c_invoiceschedule where  name=(select invoiceschedule_key from zsi_bp_customer where bp_value_key=v_cur.value);
    select m_pricelist_id into v_pricelist from m_pricelist where  name=(select pricelist_key from zsi_bp_customer where bp_value_key=v_cur.value);
    select c_paymentterm_id into v_paymentterm from  c_paymentterm where  value=(select paymentterm_key from zsi_bp_customer where bp_value_key=v_cur.value);
    select c_bpartner_id into v_user from ad_user  where name=(select salesrep_key from zsi_bp_customer where bp_value_key=v_cur.value);
    -- Update customer
    update c_bpartner set iscustomer=cc.iscustomer,invoicerule=cc.invoicerule,c_invoiceschedule_id=v_invoiceschedule,invoicegrouping=cc.invoicegrouping,deliveryrule=cc.deliveryrule,deliveryviarule=cc.deliveryviarule,m_pricelist_id=v_pricelist,
                          paymentrule=cc.paymentrule,c_paymentterm_id=v_paymentterm,salesrep_id=v_user,so_creditlimit=to_number(cc.so_creditlimit),fixmonthday=to_number(cc.fixmonthday),fixmonthday2=to_number(cc.fixmonthday2),fixmonthday3=to_number(cc.fixmonthday3)
                      from (select iscustomer,invoicerule,'000000000000000' as invoicegrouping,deliveryrule,deliveryviarule,paymentrule,so_creditlimit,fixmonthday,fixmonthday2,fixmonthday3 
                            from zsi_bp_customer 
                            where bp_value_key=v_cur.value) cc
                      where c_bpartner.c_bpartner_id=v_bpid;
    select m_pricelist_id into v_pricelist from m_pricelist  where  name=(select po_pricelist_key from zsi_bp_vendor where bp_value_key=v_cur.value);
    select c_paymentterm_id into v_paymentterm from c_paymentterm where  value=(select po_paymentterm_key from zsi_bp_vendor where bp_value_key=v_cur.value);
    --Update Vendor
    update c_bpartner set isvendor=cc.isvendor,paymentrulepo=cc.paymentrulepo,po_paymentterm_id =v_paymentterm,po_pricelist_id=v_pricelist,po_fixmonthday=to_number(cc.po_fixmonthday),po_fixmonthday2=to_number(cc.po_fixmonthday2),po_fixmonthday3=to_number(cc.po_fixmonthday3)
                      from (select isvendor,paymentrulepo,po_fixmonthday,po_fixmonthday2,po_fixmonthday3
                            from zsi_bp_vendor 
                            where bp_value_key=v_cur.value) cc
                      where c_bpartner.c_bpartner_id=v_bpid;
    --
    for v_cur2 in (select * from zsi_bp_bank where bp_value_key=v_cur.value)
    LOOP
        select c_country_id into v_country from c_country where countrycode=coalesce(v_cur2.country_key,'DE');
        insert into c_bp_bankaccount (c_bp_bankaccount_id,c_bpartner_id,c_country_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                                     isactive,accountno,showaccountno,a_zip,iban,showiban,swiftcode,bank_name,a_name)
                    values(get_uuid(),v_bpid,v_country,ad_client,v_org,now(),creator,now(),creator,
                           v_cur2.isactive,v_cur2.accountno,v_cur2.showaccountno,v_cur2.routingno,v_cur2.iban,v_cur2.showiban,v_cur2.swiftcode,v_cur2.bank_name,v_cur2.a_name);
    END LOOP;
  END LOOP;          
END;
$_$  LANGUAGE 'plpgsql';




CREATE or replace FUNCTION  zsi_bpcustomerimport() RETURNS void
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_org character varying;
v_bpid character varying;
v_bpgroup character varying;
v_goc character varying;
v_lang character varying;
v_greeting character varying;
v_locid character varying;
v_country character varying;
v_tax character varying;
v_salesregion character varying;
v_countryneme character varying;

v_invoiceschedule character varying;
v_pricelist character varying;
v_paymentterm character varying;
v_user character varying;
v_ishead character varying;
v_temp varchar;

v_count numeric;
v_cur RECORD;
v_cur2 RECORD;

BEGIN
 for v_cur in (select * from c_bpartner where exists (select 0 from zsi_bp_customer where zsi_bp_customer.bp_value_key=c_bpartner.value))
    LOOP
    select c_bpartner_id into v_bpid from c_bpartner where value=v_cur.value ;
   select c_invoiceschedule_id into v_invoiceschedule from c_invoiceschedule where  name=(select invoiceschedule_key from zsi_bp_customer where bp_value_key=v_cur.value);
    select m_pricelist_id into v_pricelist from m_pricelist where  name=(select pricelist_key from zsi_bp_customer where bp_value_key=v_cur.value);
    select c_paymentterm_id into v_paymentterm from  c_paymentterm where  value=(select paymentterm_key from zsi_bp_customer where bp_value_key=v_cur.value);
    select c_bpartner_id into v_user from ad_user  where name=(select salesrep_key from zsi_bp_customer where bp_value_key=v_cur.value);
    -- Update customer
    update c_bpartner set iscustomer=cc.iscustomer,invoicerule=cc.invoicerule,c_invoiceschedule_id=v_invoiceschedule,invoicegrouping=cc.invoicegrouping,deliveryrule=cc.deliveryrule,deliveryviarule=cc.deliveryviarule,m_pricelist_id=v_pricelist,
                          paymentrule=cc.paymentrule,c_paymentterm_id=v_paymentterm,salesrep_id=v_user,so_creditlimit=to_number(cc.so_creditlimit),fixmonthday=to_number(cc.fixmonthday),fixmonthday2=to_number(cc.fixmonthday2),fixmonthday3=to_number(cc.fixmonthday3)
                      from (select iscustomer,invoicerule,'000000000000000' as invoicegrouping,deliveryrule,deliveryviarule,paymentrule,so_creditlimit,fixmonthday,fixmonthday2,fixmonthday3 
                            from zsi_bp_customer 
                            where bp_value_key=v_cur.value) cc
                      where c_bpartner.c_bpartner_id=v_bpid;
    select m_pricelist_id into v_pricelist from m_pricelist  where  name=(select po_pricelist_key from zsi_bp_vendor where bp_value_key=v_cur.value);
    select c_paymentterm_id into v_paymentterm from c_paymentterm where  value=(select po_paymentterm_key from zsi_bp_vendor where bp_value_key=v_cur.value);
    --Update Vendor
    update c_bpartner set isvendor=cc.isvendor,paymentrulepo=cc.paymentrulepo,po_paymentterm_id =v_paymentterm,po_pricelist_id=v_pricelist,po_fixmonthday=to_number(cc.po_fixmonthday),po_fixmonthday2=to_number(cc.po_fixmonthday2),po_fixmonthday3=to_number(cc.po_fixmonthday3)
                      from (select isvendor,paymentrulepo,po_fixmonthday,po_fixmonthday2,po_fixmonthday3
                            from zsi_bp_vendor 
                            where bp_value_key=v_cur.value) cc
                      where c_bpartner.c_bpartner_id=v_bpid;

  END LOOP;          
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION  zsi_cleanstdloc() RETURNS varchar
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_org character varying;
v_bpid character varying;
v_bpgroup character varying;
v_goc character varying;
v_lang character varying;
v_greeting character varying;
v_locid character varying;
v_country character varying;
v_tax character varying;
v_salesregion character varying;
v_countryneme character varying;

v_invoiceschedule character varying;
v_pricelist character varying;
v_paymentterm character varying;
v_user character varying;
v_ishead character varying;
v_temp varchar;
v_i numeric:=0;
v_count numeric;
v_cur RECORD;
v_cur2 RECORD;

BEGIN

  for v_cur in (select * from c_bpartner) 
  LOOP
    
        if (select count(*) from C_BPARTNER_LOCATION where c_bpartner_id=v_cur.c_bpartner_id)>0 then
            select count(*) into v_count from C_BPARTNER_LOCATION where name='Standard -  - Deutschland' and c_bpartner_id=v_cur.c_bpartner_id;
                    if v_count=1 then 
                       -- Forget the automatically created entry
                       select C_LOCATION_id into v_temp from C_BPARTNER_LOCATION where name='Standard -  - Deutschland' and c_bpartner_id=v_cur.c_bpartner_id;
                       update C_BPARTNER set C_LOCATION_id=null where c_bpartner_id=v_cur.c_bpartner_id;
                       delete  from C_BPARTNER_LOCATION where name='Standard -  - Deutschland' and c_bpartner_id=v_cur.c_bpartner_id;
                       delete from c_location where c_location_id=v_temp;
                       v_i:=v_i+1;
                    end if;
        end if;
  END LOOP; 
  return v_i;
END;
$_$  LANGUAGE 'plpgsql';
