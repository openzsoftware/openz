




/*****************************************************+


Functions for WEB Services

UPDATE-RULES:

Return-Value: 'UPDATED' -> Updates Existing Rec.
              'ERR'     -> ERROR
          All Others    -> Inserted, Return-Value is the new ID  

*****************************************************/


select zsse_dropfunction ('zsse_updateCustomer');
CREATE or replace FUNCTION zsse_updateCustomer(p_customer_Id character varying,p_value character varying,p_name character varying,p_user character varying, p_org character varying,p_bpgroup character varying) RETURNS character varying
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
Updates or Inserts  Business-Partner (Customer)
*****************************************************/
-- Simple Types
v_message character varying :='ERR';
v_client character varying;
v_uid character varying;
v_lang character varying;
v_bpgroup character varying;
v_user character varying;
v_count integer;
BEGIN 
    select ad_user_id into v_user from ad_user where username=p_user;
    if v_user is not null then
        select c_bp_group_id  into v_bpgroup from c_bp_group where ad_org_id in ('0',p_org) and isactive='Y' and value=p_bpgroup LIMIT 1; 
        if v_bpgroup is null then
            select c_bp_group_id  into v_bpgroup from c_bp_group where ad_org_id in ('0',p_org) and isactive='Y' and isdefault='Y' LIMIT 1; 
        end if;
        if p_customer_Id is not null then
          select count(*) into v_count from c_bpartner where c_bpartner_id=p_customer_Id;
          if v_count=1 then
              update c_bpartner set updatedby=v_user,updated=now(),value=p_value,name=p_name,c_bp_group_id=coalesce(v_bpgroup,c_bp_group_id) where c_bpartner_id=p_customer_Id;
              v_message:='UPDATED';
          end if;
        else
            if (p_org is not null and v_user is not null and p_value is not null and p_name is not null) then
              v_uid:=get_uuid();
              select ad_client_id,ad_language into v_client,v_lang from ad_client where ad_client_id!='0';
              insert into c_bpartner(C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY, VALUE, NAME, C_BP_GROUP_ID, ISCUSTOMER, AD_LANGUAGE,so_creditlimit)
                    values(v_uid,v_client,p_org,v_user,v_user,p_value,p_name,v_bpgroup,'Y',v_lang,500000);
              v_message:=v_uid;
            end if;
        end if;
    else
        v_message:='ERR: WRONG USER or ORG ID while Updating Adress'; 
    end if;
    return  v_message;
END;
$_$  LANGUAGE 'plpgsql';
     

select zsse_dropfunction ('zsse_updateAddress');
CREATE or replace FUNCTION zsse_updateAddress(p_customer_Id character varying,p_user character varying, p_address1 character varying,p_address2 character varying,p_city character varying,p_postal character varying,
                                              p_country character varying,p_isbillto character varying, p_isshipto character varying,p_uidnumber character varying ,p_locationId character varying) RETURNS character varying
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
Updates or Inserts Business-Partner-Adresses
*****************************************************/
-- Simple Types
v_message character varying :='ERR';
v_uid character varying;
v_client character varying;
v_org character varying;
v_country character varying;
v_count integer; 
v_stadr  character varying:='N';
v_user character varying;
v_temp varchar;
BEGIN 
    select ad_user_id into v_user from ad_user where username=p_user;
    if v_user is not null then 
        select c_country_id into v_country from c_country where countrycode=p_country;
        if v_country is not null then
            if p_locationId is not null then
                select count(*) into v_count from c_location where c_location_id=p_locationId;
                if v_count=1 then
                    update c_location set updatedby=v_user,updated=now(),ADDRESS1=p_address1,ADDRESS2=p_address2,CITY=p_city,POSTAL=p_postal,C_COUNTRY_ID=v_country where C_LOCATION_ID=p_locationId;
                    update c_bpartner_location set updated=now(),updatedby=v_user,isbillto=p_isbillto,isshipto=p_isshipto,uidnumber=p_uidnumber where C_LOCATION_ID=p_locationId and C_BPARTNER_ID=p_customer_Id;
                    v_message:='UPDATED';
                end if;
            else
                select count(*) into v_count from c_bpartner where c_bpartner_id=p_customer_Id;
                if v_count=1 then
                    select count(*) into v_count from C_BPARTNER_LOCATION where name like 'Standard -  -%' and c_bpartner_id=p_customer_Id;
                    if v_count=1 then 
                       -- Forget the automatically created entry
                       select C_LOCATION_id into v_temp from C_BPARTNER_LOCATION where name like 'Standard -  -%' and c_bpartner_id=p_customer_Id;
                       update C_BPARTNER set C_LOCATION_id=null where c_bpartner_id=p_customer_Id;
                       delete  from C_BPARTNER_LOCATION where name like 'Standard -  -%' and c_bpartner_id=p_customer_Id;
                       delete from c_location where c_location_id=v_temp;
                       v_stadr:='Y';
                    end if;
                    v_uid:=get_uuid();
                    select ad_client_id,ad_org_id into v_client,v_org from c_bpartner where c_bpartner_id=p_customer_Id;
                    insert into C_LOCATION (C_LOCATION_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,  UPDATEDBY, ADDRESS1, ADDRESS2, CITY, POSTAL, C_COUNTRY_ID)
                            values (v_uid,v_client,v_org,v_user,v_user,p_address1,p_address2,p_city,p_postal,v_country);
                    insert into C_BPARTNER_LOCATION(C_BPARTNER_LOCATION_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,C_LOCATION_ID,C_BPARTNER_ID,
                                                    isheadquarter,isbillto,isshipto,uidnumber)
                            values(get_uuid(),v_client,v_org,v_user,v_user,v_uid,p_customer_Id,v_stadr,p_isbillto,p_isshipto,p_uidnumber);
                    v_message:=v_uid;
                end if; 
            end if;
        end if;
    else
       v_message:='ERR: WRONG USER or ORG ID while Updating Adress'; 
    end if;
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';
     


CREATE or replace FUNCTION zsse_updateContacts(p_customer_Id character varying,p_user character varying,p_firstName character varying,p_lastName character varying,p_name character varying, p_email character varying,p_phone character varying,p_phone2 character varying ,p_fax character varying,p_greeting character varying,p_contactId character varying) RETURNS character varying
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
Updates or Inserts Business-Partner-Adresses
*****************************************************/
-- Simple Types
v_message character varying :='ERR';
v_uid character varying;
v_client character varying;
v_org character varying;
v_country character varying;
v_count integer; 
v_user character varying;
v_greeting character varying;
BEGIN 
    select ad_user_id into v_user from ad_user where username=p_user;
    select c_greeting_id into v_greeting from c_greeting where greeting=p_greeting;
    if v_user is not null then 
        if p_contactId  is not null then
            select count(*) into v_count from ad_user where ad_user_id=p_contactId;
            if v_count=1 then
                update ad_user set updatedby=v_user,updated=now(),firstname =p_firstName,lastName=p_lastName,name=p_name,email=p_email,phone=p_phone,phone2=p_phone2,fax=p_fax ,
                                   c_greeting_id=v_greeting where ad_user_id=p_contactId;
                v_message:='UPDATED';
            end if;
        else
            select count(*) into v_count from c_bpartner where c_bpartner_id=p_customer_Id;
            if v_count=1 then
                  v_uid:=get_uuid();
                  select ad_client_id,ad_org_id into v_client,v_org from c_bpartner where c_bpartner_id=p_customer_Id;
                  insert into ad_user (AD_USER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, EMAIL, C_BPARTNER_ID, PHONE, PHONE2, FAX, FIRSTNAME, LASTNAME,NAME,c_greeting_id)
                        values (v_uid,v_client,v_org,v_user,v_user,p_email,p_customer_Id,p_phone,p_phone2,p_fax,p_firstName,p_lastName,p_name,v_greeting);
                  v_message:=v_uid;
            end if; 
        end if;
    end if;
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';
     
alter FUNCTION zsse_updateContacts(p_customer_Id character varying,p_user character varying,p_firstName character varying,p_lastName character varying,p_name character varying, p_email character varying,p_phone character varying,p_phone2 character varying ,p_fax character varying,p_greeting character varying,p_contactId character varying)  owner to tad; 

select zsse_dropfunction ('zsse_createOrderHeader');
CREATE or replace FUNCTION zsse_createOrderHeader(p_org_Id character varying,p_user character varying,p_bpartner_Id character varying,p_ec_paymentmethod character varying,p_deliveryviarule character varying,p_location_id  character varying, p_bpcontact_id  character varying, p_shopid varchar,p_locationship2 varchar) RETURNS character varying
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011-2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Creates an Order Header
Returns Order ID, if Successful

This function was extended to a generic funktion to gen. Orders (PO/SO) - Not only for webservices-Also within OZ
1. Use:  p_shopid is a valid zse_shop_id. If null, as preference for the PreferenceType WebshopOrder (SOO) is used in smartinvoiceprefs with shop-id = null else specific for the shop to Determin doctype etc.
               In that case p_ec_paymentmethod is a shop-Payment-method ListRef 'Paymentmethod ECommerce' (8EE47A7F188B4F86936C8AF91A55490A) and has to be mapped to OZ paymentrule List Ref (195) . See Mapping to Paymentrule below.
 
 2. Use: In p_shopid is not a zse_shop_id, BUT a Value of the List PreferenceType Ref-List-ID F2F614C13163411D8EFD805E23037EE0, Field invoicetype in smartinvoiceprefs. In this case Field invoicetype in smartinvoiceprefs is used to determin the doctype_id etc.
               In that Case The Payment method,  is used from the settings in bpartner or invoiceprefs

*****************************************************/
-- Simple Types
v_message character varying :='SUCCESS';
v_orderid character varying;
v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_country character varying;
v_count integer; 
v_user character varying;
v_docno character varying;
v_doctypetarget  character varying;
v_payterm  character varying;
v_invrule  character varying;
v_delrule  character varying;
v_warehouse  character varying;
v_pricelist  character varying; 
v_location character varying; 
v_locationship2 character varying; 
v_currency  character varying:='102'; --EUR
v_paymentrule character varying;
v_ec_paymentmethod character varying;
v_usecustomersdefaults character varying;
v_salesrep character varying;
v_so_description character varying;
v_freightcostrule character varying;
v_shipper character varying;
v_incoterms character varying;
v_invrule2 character varying;
v_delrule2 character varying;
v_pricelist2 character varying;
v_payterm2 character varying;
v_freightcostrule2 character varying;
v_paymentrule2 varchar;
v_issotrx varchar:='Y';
BEGIN 
    select ad_user_id into v_user from ad_user where username=p_user;
    if v_user is null then
        select ad_user_id into v_user from ad_user where ad_user_id=p_user;
    end if;
    if v_user is null or v_client is null then v_message:='ERR: WRONG USER or ORG ID'; end if;
    if coalesce(p_shopid,'')!='INTERNAL' and (select seqno from ad_user where ad_user_id=v_user) is null then
        v_message:='ERR: Shop User not Licensed! Single Role eCommerce, Username required!'; 
    end if;
    if coalesce(p_shopid,'')!='INTERNAL' and (select count(*) from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype=p_shopid and isactive='Y')=0 then
        if (select count(*) from ad_user_roles where  ad_user_id=v_user)!=1 then
            v_message:='ERR: Shop User not Licensed! Role eCommerce is required as single User-Role!'; 
        end if;
        if (select count(*) from ad_user_roles where  ad_user_id=v_user and ad_role_id='80B12F63EE224C6CB6975132A3163AAF')!=1 then
            v_message:='ERR: Shop User not Licensed! Role eCommerce required as User-Role !'; 
        end if;
        if (select count(*) from zse_shop where zse_shop_id=p_shopid)=0 and p_shopid is not null then
            v_message:='ERR: You have to define Document preferences to generate a Document of this type!'; 
        end if;
    else
        if coalesce(p_shopid,'')='INTERNAL' then
            p_shopid:=null;
        end if;
    end if;
    select count(*) into v_count from c_bpartner where c_bpartner_Id=p_bpartner_Id;
    if v_count!=1 then v_message:='ERR: BUSINESS Partner does not exist!'; end if;
    -- Get Billto Location
    select c_bpartner_location_id into v_location from C_BPARTNER_LOCATION where C_bpartner_LOCATION_id=p_location_id;
    if p_location_id is not null and v_location is null then
        select c_bpartner_location_id into v_location from C_BPARTNER_LOCATION where C_LOCATION_id=p_location_id and c_bpartner_id=p_bpartner_Id;
    end if;
    if v_location is null then -- DEFAULT
        select c_bpartner_location_id into v_location from c_bpartner_location where c_bpartner_id=p_bpartner_Id and isbillto ='Y'  order by isheadquarter desc limit 1;
        select c_bpartner_location_id into v_locationship2 from c_bpartner_location where c_bpartner_id=p_bpartner_Id and isshipto='Y'  order by isheadquarter desc limit 1;
    end if;
    -- Get Shipto Location
    if (select count(*) from  c_bpartner_location where c_bpartner_location_id=p_locationship2 and isshipto='Y')>0 then
        v_locationship2:=p_locationship2;
    end if;
    if v_locationship2 is null then    v_locationship2:=v_location; end if;
    if  (v_location is null or v_locationship2 is null) and substr(v_message,1,3)!='ERR'   then
        v_message:='ERR: LOCATION IS not a Location of Business Partner'; 
    end if;
    if p_shopid is null then 
        select zse_shop_id into p_shopid from zse_shop where ad_user_id = v_user;
    end if;
    select count(*) into v_count  from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype='SSO' and isactive='Y'
           and case when p_shopid is null then  zse_shop_id is null  else zse_shop_id=p_shopid end;
    if v_count=0 then 
         select count(*) into v_count  from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype=coalesce(p_shopid,'null') and isactive='Y';
         if v_count=0  and substr(v_message,1,3)!='ERR'   then   v_message:='ERR: No Preferences Defined for this kind of Document'; end if;
    end if;
    -- Payment-Rule Check - Reference: Paymentmethod ECommerce
    select count(*) into v_count  from ad_ref_list where ad_reference_id='8EE47A7F188B4F86936C8AF91A55490A' and name=p_ec_paymentmethod;
    if  v_count!=1 then 
        select count(*) into v_count  from ad_ref_list where ad_reference_id='8EE47A7F188B4F86936C8AF91A55490A' and value=p_ec_paymentmethod;
        if  v_count!=1 then 
                select count(*) into v_count  from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype=coalesce(p_shopid,'null') and isactive='Y';
                if  v_count=0 and substr(v_message,1,3)!='ERR'  then  v_message:='ERR: Invalid Payment Rule:'||p_ec_paymentmethod;  end if;
        end if;
    end if;
    select count(*) into v_count  from ad_user where ad_user_id=p_bpcontact_id and c_bpartner_Id=p_bpartner_Id;
    if  v_count!=1 and  p_bpcontact_id is not null  and substr(v_message,1,3)!='ERR'   then v_message:='ERR: Contact Person of Business Partner not Found';  end if;
    if p_deliveryviarule  not in ('D','P')  and substr(v_message,1,3)!='ERR'   then v_message:='ERR: Invalid Delivery via Rule'; end if;
    if substr(v_message,1,3)!='ERR' then 
         if (select count(*)   from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype=coalesce(p_shopid,'null') and isactive='Y')=0 then
                 -- Mapping to Paymentrule
                 select value into v_ec_paymentmethod  from ad_ref_list where ad_reference_id='8EE47A7F188B4F86936C8AF91A55490A' and name=p_ec_paymentmethod;
                 if v_ec_paymentmethod is null then
                    select value into v_ec_paymentmethod  from ad_ref_list where ad_reference_id='8EE47A7F188B4F86936C8AF91A55490A' and value=p_ec_paymentmethod;
                 end if;
                 -- Kredit-Card and Paypal
                 if v_ec_paymentmethod in ('A','M','PP','V','EC') then v_paymentrule:='K'; end if;
                 -- Bank Collection
                 if v_ec_paymentmethod in ('BC','BCM') then  v_paymentrule:='P'; end if;
                 -- Prepaid, Invoice
                 if v_ec_paymentmethod in ('P','I') then  v_paymentrule:='R'; end if;
                 -- Cash on delivery
                 if v_ec_paymentmethod in ('C')  then  v_paymentrule:='COD'; end if;
                 -- Cash
                 if v_ec_paymentmethod in ('B')  then  v_paymentrule:='B'; end if;
         end if;
         --   
         v_orderid:=get_uuid();
         
         --Get Correct warehouse in multishop-environments
         -- Get Preferences
         if (select count(*)  from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype=coalesce(p_shopid,'null') and isactive='Y')>0 then -- shopId is PreferenceTypeof SmartinvoicePrefs
                select m_warehouse_id,invoicerule, deliveryrule, m_pricelist_id, c_paymentterm_id, freightcostrule, m_shipper_id, c_incoterms_id,c_doctype_id,usecustomersdefaults,paymentrule
                into v_warehouse,v_invrule, v_delrule, v_pricelist, v_payterm, v_freightcostrule, v_shipper, v_incoterms, v_doctypetarget,v_usecustomersdefaults,v_paymentrule
                 from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype=p_shopid and isactive='Y' order by ad_org_id desc limit 1 ;
         else -- shopId is null or real Shop
                -- Preload document prefs
                select m_warehouse_id,invoicerule, deliveryrule, m_pricelist_id, c_paymentterm_id, freightcostrule, m_shipper_id, c_incoterms_id,c_doctype_id,usecustomersdefaults
                into v_warehouse,v_invrule, v_delrule, v_pricelist, v_payterm, v_freightcostrule, v_shipper, v_incoterms, v_doctypetarget,v_usecustomersdefaults
                from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',p_org_Id) and invoicetype='SSO' 
                and  case when p_shopid is null then zse_shop_id is null else zse_shop_id=p_shopid end and isactive='Y' order by ad_org_id desc limit 1 ;
                 if v_warehouse is null then
                    select m_warehouse_id into v_warehouse from zse_warehouse_shop LIMIT 1;
                 end if;
         end if;       
       -- sales or purchase...
       select issotrx into v_issotrx from c_doctype where c_doctype_id=v_doctypetarget; 
        -- Overload with customer prefs
        if v_usecustomersdefaults='Y' then
                select invoicerule, deliveryrule,
                case when v_issotrx='Y' then m_pricelist_id else po_pricelist_id end, 
                case when v_issotrx='Y' then  c_paymentterm_id else po_paymentterm_id end, 
                salesrep_id, so_description, paymentrule
                into v_invrule2, v_delrule2, v_pricelist2, v_payterm2, v_salesrep, v_so_description,v_paymentrule2
                from c_bpartner where c_bpartner_id=p_bpartner_Id;
                select ad_user_id into v_salesrep from ad_user where v_salesrep=c_bpartner_id;
        end if;          
        -- Set defaults preventing "not null"
        if v_payterm2 is null then
                if v_payterm is null then
                        select c_paymentterm_id into v_payterm from c_paymentterm LIMIT 1;
                end if;
        else
                v_payterm:=v_payterm2;
        end if;
        if v_pricelist2 is null then
                if v_pricelist is null then
                        select m_pricelist_id into v_pricelist from m_pricelist where m_pricelist.issopricelist='Y' LIMIT 1;
                end if;
        else
                v_pricelist:=v_pricelist2;      
        end if;
        if v_delrule2 is null then
                if v_delrule is null then
                        v_delrule:='R';
                end if;
        else
                v_delrule:=v_delrule2;
        end if;
        if v_invrule2 is null then
                if v_invrule is null then
                        v_invrule:='A';
                end if;
        else
                v_invrule:=v_invrule2;
        end if;          
        if v_freightcostrule2 is null then
                if v_freightcostrule is null then
                        v_freightcostrule:='C';
                end if;
        else
                v_freightcostrule:=v_freightcostrule2;
        end if;          
        -- Delivery Rule in Case of Prepaid will be After Receipt (R), Invoice-Rule Immediately (I)
        if v_ec_paymentmethod='P' then 
            v_delrule:='R';
            v_invrule:='I'; 
        end if;
        if v_paymentrule2 is not null then v_paymentrule:=v_paymentrule2; end if;
        if v_paymentrule is null then RAISE EXCEPTION '%', 'Parameter Error-Invalid Payment Rule'; end if;
         -- Get new DocData
         select ad_sequence_doctype(v_doctypetarget,p_org_Id,'Y') into v_docno from dual;
         RAISE NOTICE '%','Creating WEBSHOP-Order: '||coalesce(v_doctypetarget,'no Target Doctype')||coalesce(v_docno,'no Doc no.')||coalesce(v_warehouse,'no WH.');
         -- Create Order Header
         
        select c_currency_id into v_currency from m_pricelist where m_pricelist_id=v_pricelist;
        INSERT INTO C_Order
          (C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATEDBY, UPDATEDBY,
           ISSOTRX, DOCUMENTNO, DOCSTATUS, DOCACTION, PROCESSING, C_DOCTYPE_ID,C_DOCTYPETARGET_ID,
           DATEORDERED, DATEACCT, C_BPARTNER_ID, BILLTO_ID, C_BPARTNER_LOCATION_ID, C_CURRENCY_ID, PAYMENTRULE, C_PAYMENTTERM_ID,AD_USER_ID,
           INVOICERULE, DELIVERYRULE, DELIVERYVIARULE, M_WAREHOUSE_ID, M_PRICELIST_ID,istaxincluded,freightcostrule,priorityrule, m_shipper_id, c_incoterms_id, salesrep_id, description)
         VALUES
           (v_orderid, v_Client, p_org_Id,'Y',v_user,v_user,
           v_issotrx , v_docno,  'DR', 'CO','N','0',v_doctypetarget,
            trunc(now()),trunc(now()),p_bpartner_Id,v_location,v_locationship2,v_currency,v_paymentrule,v_payterm,p_bpcontact_id,
            v_invrule,v_delrule,p_deliveryviarule,v_warehouse,v_pricelist,'N',v_freightcostrule,'5', v_shipper, v_incoterms, v_salesrep, v_so_description);
         v_message:=v_orderid;
    end if;
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction ('zsse_changeOrder2FullfillmentWarehouse');
CREATE or replace FUNCTION zsse_changeOrder2FullfillmentWarehouse(p_order_Id varchar,p_channel varchar,p_shopId varchar) RETURNS character varying
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
***************************************************************************************************************************************************/
-- Simple Types
v_message character varying :='SUCCESS';

v_targetWarehouse character varying;

BEGIN 
    
         select m_warehouse_id into v_targetWarehouse from m_warehouse where isshipper='Y' and substr(p_channel,1,length(shippercode))=shippercode and 
                exists (select 0 from zse_warehouse_shop where zse_warehouse_shop.m_warehouse_id=m_warehouse.m_warehouse_id and zse_shop_id=p_shopId);
         if v_targetWarehouse is not null then
            -- Update Order Header - Set Warehouse and POS-Doctype
            update c_order set m_warehouse_id=v_targetWarehouse,c_doctypetarget_id='A861C268485947AF8C55595A08CA62EE'  where c_order_id=p_order_Id;
         end if;
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';

select zsse_dropfunction ('zsse_ActivateOrder2Fullfillment');
CREATE or replace FUNCTION zsse_ActivateOrder2Fullfillment(p_order_Id varchar) RETURNS character varying
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
***************************************************************************************************************************************************/
-- Simple Types
v_message character varying :='SUCCESS';

v_minout character varying;

BEGIN 
    
    if p_order_Id is not null then
        perform c_order_post1(null, p_order_Id);
        select m_inout_id into v_minout from m_inout where c_order_id = p_order_Id and docstatus='DR';
        if  v_minout is not null then
            if (select count(*) from m_inoutline where m_inout_id=v_minout and m_locator_id is null)>0 then
                raise exception '%','Kein ausreichender Lagerbestand im FBA Lager:'||(select zssi_getproductname(m_product_id,'de_DE') from m_inoutline where m_inout_id=v_minout limit 1);
            end if;
            perform m_inout_post(null, v_minout);
        end if;
    end if;
    
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';

     
select zsse_dropfunction('zsse_createOrderLine');
CREATE or replace FUNCTION zsse_createOrderLine(p_order_Id character varying,p_product_id character varying,p_qty character varying,p_price character varying,p_decription character varying,p_taxId varchar) RETURNS character varying
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
Creates an Order Header
Returns Order ID, if Successful
*****************************************************/
-- Simple Types
v_message character varying :='SUCCESS';
v_client character varying;
v_org character varying;
v_count integer; 
v_line integer ;
v_user character varying;
v_tax  character varying;
v_location character varying;
v_warehouse character varying;
v_uom character varying;
v_currency character varying;
v_bpartner_id character varying;
v_guid varchar;
BEGIN 
    select count(*) into v_count from c_order where c_order_id=p_order_Id;
    if v_count=0 then v_message:='ERR: Order does not exist!'; end if;
    if substr(v_message,1,3)!='ERR' then    
        select c_bpartner_id,C_BPARTNER_LOCATION_ID,CREATEDBY,AD_CLIENT_ID, AD_ORG_ID,m_warehouse_id,c_currency_id into v_bpartner_id,v_location,v_user,v_client,v_org,v_warehouse,v_currency from c_order where c_order_id=p_order_Id;
        select count(*) into v_count from m_product where m_product_id=p_product_id;
        if v_count=0 then
            select count(*) into v_count from m_product where value=p_product_id;
            if v_count=0 then 
               select count(*) into v_count from m_product where upc=p_product_id;
               if v_count=0 then     
                   v_message:='ERR: Product does not exist!'; 
               else
                  select m_product_id into p_product_id from m_product where upc=p_product_id limit 1; 
               end if;
            else
               select m_product_id into p_product_id from m_product where value=p_product_id;
            end if;                
        end if;
        if substr(v_message,1,3)!='ERR' then    
           if (select count(*) from c_tax where c_tax_id=p_taxId)>0  then
            v_tax:=p_taxId;
           else
            select zsfi_GetTax(v_location, p_product_id, v_org) into v_tax from dual;
           end if;
            select C_UOM_ID into v_uom from m_product where m_product_id=p_product_id;
            select coalesce(max(line),0)+10 into v_line from c_orderline where c_order_id=p_order_Id;
            v_guid:=get_uuid();
            insert into c_orderline (C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,
                                    C_ORDER_ID, LINE, DATEORDERED, M_PRODUCT_ID, M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED,
                                    C_CURRENCY_ID,  PRICEACTUAL, C_TAX_ID,c_bpartner_id,c_bpartner_location_id,DESCRIPTION)
                        values(v_guid,v_client,v_org,v_user,v_user,
                            p_order_Id,v_line,now(), p_product_id,v_warehouse,v_uom,to_number(p_qty),
                            v_currency,to_number(p_price),v_tax,v_bpartner_id,v_location,replace(replace(p_decription,'\r\n',chr(10)),'\n',chr(10)));
            v_message:=v_guid;
        end if;
    end if;
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';
     
select zsse_dropfunction('zsse_createOrderLineWithPrices');
CREATE or replace FUNCTION zsse_createOrderLineWithPrices(p_order_Id character varying,p_product_id character varying,p_qty numeric,p_price numeric,p_listprice numeric,p_stdprice numeric,p_discount numeric,p_decription character varying,p_taxId varchar) RETURNS character varying
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
Creates an Order Header
Returns Order ID, if Successful
*****************************************************/
-- Simple Types
v_message character varying :='SUCCESS';
v_client character varying;
v_org character varying;
v_count integer; 
v_line integer ;
v_user character varying;
v_tax  character varying;
v_location character varying;
v_warehouse character varying;
v_uom character varying;
v_currency character varying;
v_bpartner_id character varying;
v_lineid varchar;
v_pricelistid varchar;
v_offersprice numeric;
BEGIN 
    select count(*) into v_count from c_order where c_order_id=p_order_Id;
    if v_count=0 then v_message:='ERR: Order does not exist!'; end if;
    if substr(v_message,1,3)!='ERR' then    
        select c_bpartner_id,C_BPARTNER_LOCATION_ID,CREATEDBY,AD_CLIENT_ID, AD_ORG_ID,m_warehouse_id,c_currency_id,m_pricelist_id
               into v_bpartner_id,v_location,v_user,v_client,v_org,v_warehouse,v_currency,v_pricelistid from c_order where c_order_id=p_order_Id;
        select count(*) into v_count from m_product where m_product_id=p_product_id;
        if v_count=0 then
            select count(*) into v_count from m_product where value=p_product_id;
            if v_count=0 then 
               select count(*) into v_count from m_product where upc=p_product_id;
               if v_count=0 then     
                   v_message:='ERR: Product does not exist!'; 
               else
                  select m_product_id into p_product_id from m_product where upc=p_product_id limit 1; 
               end if;
            else
               select m_product_id into p_product_id from m_product where value=p_product_id;
            end if;                
        end if;
        if substr(v_message,1,3)!='ERR' then    
            if (select count(*) from c_tax where c_tax_id=p_taxId)>0  then
                v_tax:=p_taxId;
            else
                select zsfi_GetTax(v_location, p_product_id, v_org) into v_tax from dual;
            end if;
            -- Calculate Prices if Parameter null
            v_offersprice:=m_get_offers_price(trunc(now()) , v_bpartner_id , p_product_id ,  p_qty , v_pricelistid);
            if p_price is null then p_price:= v_offersprice;  end if;
            if p_listprice is null then p_listprice:=v_offersprice;  end if;
            if p_stdprice is null then p_stdprice:=v_offersprice;  end if;
           
            v_lineid:=get_uuid();
            select C_UOM_ID into v_uom from m_product where m_product_id=p_product_id;
            select coalesce(max(line),0)+10 into v_line from c_orderline where c_order_id=p_order_Id;
            insert into c_orderline (C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,
                                    C_ORDER_ID, LINE, DATEORDERED, M_PRODUCT_ID, M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED,
                                    C_CURRENCY_ID,  PRICEACTUAL,pricelist,pricestd,discount, C_TAX_ID,c_bpartner_id,c_bpartner_location_id,DESCRIPTION)
                        values(v_lineid,v_client,v_org,v_user,v_user,
                            p_order_Id,v_line,now(), p_product_id,v_warehouse,v_uom,p_qty,
                            v_currency,p_price,p_listprice,p_stdprice,p_discount,v_tax,v_bpartner_id,v_location,p_decription);
            v_message:=v_lineid;
        end if;
    end if;
   return v_lineid;
END;
$_$  LANGUAGE 'plpgsql';
     
     

CREATE or replace FUNCTION zsse_commitOrder(p_order_Id character varying) RETURNS character varying
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
Submits an Order if there are lines
Deletes order if there are no lines
*****************************************************/
-- Simple Types
v_message character varying :='SUCCESS';
v_count integer; 
v_direct character varying;

v_client character varying;
v_org character varying;

BEGIN 
    select count(*) into v_count from c_order where c_order_id=p_order_Id;
    if v_count=0 then v_message:='ERR: Order does not exist!'; end if;
    select count(*) into v_count from c_orderline where c_order_id=p_order_Id;
    if v_count=0 then 
        delete from c_order where c_order_id=p_order_Id;
    else
        if substr(v_message,1,3)!='ERR' then  
        select ad_client_id,ad_org_id into v_client,v_org from c_order where c_order_id=p_order_Id;
        --Needs Construction for multiple shops...
        select isautoclosing into v_direct  from zssi_smartinvoiceprefs where ad_client_id=v_client and ad_org_id in ('0',v_org) and invoicetype='SSO' and isactive='Y' order by ad_org_id desc LIMIT 1;   
        if v_direct='Y' then
            -- Create invoice and schipment
            PERFORM C_Order_Post1(null,p_order_Id);
        end if;
        end if;
    end if;
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';
     

 
