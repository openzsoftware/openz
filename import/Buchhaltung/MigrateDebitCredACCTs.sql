drop table zsi_debcredaccts ;
create table zsi_debcredaccts (
bpartner_key character varying(250),
name  character varying(250),
creditacct character varying(250),
debitacct  character varying(250)
); 

 
copy zsi_debcredaccts from '/tmp/debitcredidts.csv' CSV DELIMITER as ';' HEADER ;


select bpartner_key from zsi_debcredaccts where not exists(select 0 from c_bpartner b where b.value=zsi_debcredaccts.bpartner_key); 

--delete from c_bp_customer_acct;
--delete from  c_bp_vendor_acct ;


SELECT zsse_dropfunction ('zsi_migrateaccounts'); 
Create or Replace Function zsi_migrateaccounts() RETURNS character varying
AS $_$
declare
v_acctschema_id VARCHAR;
v_seqno VARCHAR;
v_schema VARCHAR;
v_client_id VArchar;
v_acc_id VARCHAR;
v_combid varchar;
v_cur record;
p_org_id varchar:='0';
v_bpartnerid varchar;
BEGIN
      select ad_client_id,c_acctschema_id into v_client_id,v_acctschema_id from ad_org_acctschema limit 1;
      for v_cur in (select * from zsi_debcredaccts)
      LOOP
        select c_bpartner_id into v_bpartnerid from c_bpartner where value=v_cur.bpartner_key;
        if v_bpartnerid is null then
            raise notice '%' ,'Business Partner not exists:'||v_cur.bpartner_key;
        else
            IF v_cur.creditacct is not null then 
            --Customer               
                v_seqno:=v_cur.creditacct;
                v_acc_id:= get_uuid();
                IF (v_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF') then
                  if (select count(*) from c_elementvalue where c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' and value=v_seqno)=0 then
                    --SKR3
                    Insert into c_elementvalue (
                    c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                    (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(v_bpartnerid),zssi_getbpname(v_bpartnerid),'A','E', 'C76385D3874B4775B28CEC5ECBCE1E5B','N','Y','A','C','N','N');
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF';
                  else
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=(select c_elementvalue_id from c_elementvalue where c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' and value=v_seqno);
                  end if;
                  delete from c_bp_customer_acct where c_bpartner_id=v_bpartnerid;
                  Insert into c_bp_customer_acct(
                                        c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_customer_acct_id,c_receivable_acct) values
                                        (v_bpartnerid,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);        
                END IF;
                IF (v_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429')  then
                  if (select count(*) from c_elementvalue where c_element_id='D871D9715A904125974B545FC0FF0681' and value=v_seqno)=0 then
                    --SKR4
                    Insert into c_elementvalue (
                    c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                    (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno, zssi_getbpname(v_bpartnerid),zssi_getbpname(v_bpartnerid),'A','E', 'D871D9715A904125974B545FC0FF0681','N','Y','A','C','N','N');
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429';
                   else
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=(select c_elementvalue_id  from c_elementvalue where c_element_id='D871D9715A904125974B545FC0FF0681' and value=v_seqno);
                   end if;
                   delete from c_bp_customer_acct where c_bpartner_id=v_bpartnerid;
                   Insert into c_bp_customer_acct(
                                        c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_customer_acct_id,c_receivable_acct) values
                                        (v_bpartnerid,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                END IF;
            END IF;
            IF v_cur.debitacct is not null then 
            --VENDOR
                v_seqno:=v_cur.debitacct;
                v_acc_id:= get_uuid();
                IF (v_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF')  then
                  if (select count(*) from c_elementvalue where c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' and value=v_seqno)=0 then
                     --SKR3
                    Insert into c_elementvalue (
                    c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                    (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(v_bpartnerid),zssi_getbpname(v_bpartnerid),'L','F', 'C76385D3874B4775B28CEC5ECBCE1E5B','N','Y','A','C','N','N');
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF';
                  else
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=(select c_elementvalue_id from c_elementvalue where c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' and value=v_seqno);
                  end if;
                  delete from  c_bp_vendor_acct where c_bpartner_id=v_bpartnerid;
                  Insert into c_bp_vendor_acct(
                                                c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_vendor_acct_id,v_liability_acct) values
                                                (v_bpartnerid,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);         
                END IF;
                IF (v_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429')   then
                  if (select count(*)  from c_elementvalue where c_element_id='D871D9715A904125974B545FC0FF0681' and value=v_seqno)=0 then
                    --SKR4
                    Insert into c_elementvalue (
                    c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                    (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(v_bpartnerid),zssi_getbpname(v_bpartnerid),'L','F', 'D871D9715A904125974B545FC0FF0681','N','Y','A','C','N','N');
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429';
                  else
                    select c_validcombination_id into v_combid from  c_validcombination where account_id=(select c_elementvalue_id   from c_elementvalue where c_element_id='D871D9715A904125974B545FC0FF0681' and value=v_seqno);
                  end if;
                   delete from  c_bp_vendor_acct where c_bpartner_id=v_bpartnerid;
                   Insert into c_bp_vendor_acct(
                                        c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_vendor_acct_id,v_liability_acct) values
                                        (v_bpartnerid,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);                 
                END IF;        
            END IF;  
        END IF; -- BP exists
    END LOOP;
    RETURN v_seqno;
END;
$_$
LANGUAGE 'plpgsql';



SELECT zsse_dropfunction ('i_migrateaccountsfromvalue'); 
Create or Replace Function i_migrateaccountsfromvalue() RETURNS character varying
AS $_$
declare
v_acctschema_id VARCHAR;
v_seqno VARCHAR;
v_schema VARCHAR;
v_client_id VArchar;
v_acc_id VARCHAR;
v_combid varchar;
v_cur record;
p_org_id varchar:='0';
BEGIN
      select ad_client_id,c_acctschema_id into v_client_id,v_acctschema_id from ad_org_acctschema limit 1;
      for v_cur in (select case when iscustomer='Y' then 'C'  else 'V' end as  cusorven,c_bpartner_id,value from c_bpartner where  iscustomer='Y' or isvendor='Y' and isactive='Y' 
                              and not exists (select 0 from c_bp_customer_acct where c_bp_customer_acct.c_bpartner_id=c_bpartner.c_bpartner_id)
                              and (value like '1%' or value like '20%' or value like '7%'))
      LOOP
      
        IF (v_cur.cusorven='C') then 
        --Customer
            if length(v_cur.value)=5 and (v_cur.value like '1%' or v_cur.value like '2%' ) then 
                       v_seqno:=v_cur.value;
            else
                      v_seqno:=ad_sequence_doc('Customer Accounts', p_org_id, 'Y');
             end if;
              v_acc_id:= get_uuid();
            IF (v_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF') and not exists (select 0 from c_elementvalue where c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' and value=v_seqno) then
            --SKR3
              
                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(v_cur.c_bpartner_id),zssi_getbpname(v_cur.c_bpartner_id),'A','N', 'C76385D3874B4775B28CEC5ECBCE1E5B','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF';
                                Insert into c_bp_customer_acct(
                                    c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_customer_acct_id,c_receivable_acct) values
                                    (v_cur.c_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                        
            END IF;
            IF (v_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429')  and not exists (select 0 from c_elementvalue where c_element_id='D871D9715A904125974B545FC0FF0681' and value=v_seqno) then
            --SKR4
                --Platzhalter 

                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno, zssi_getbpname(v_cur.c_bpartner_id),zssi_getbpname(v_cur.c_bpartner_id),'A','N', 'D871D9715A904125974B545FC0FF0681','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429';
                                Insert into c_bp_customer_acct(
                                    c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_customer_acct_id,c_receivable_acct) values
                                    (v_cur.c_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                              
            END IF;
        ELSE
        --VENDOR
             if length(v_cur.value)=5 and v_cur.value like '7%' then 
                       v_seqno:=v_cur.value;
            else
                      v_seqno:=ad_sequence_doc('Vendor Accounts', p_org_id, 'Y');
             end if;
              v_acc_id:= get_uuid();
            IF (v_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF')  and not exists (select 0 from c_elementvalue where c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' and value=v_seqno) then
            --SKR3
               
                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(v_cur.c_bpartner_id),zssi_getbpname(v_cur.c_bpartner_id),'L','N', 'C76385D3874B4775B28CEC5ECBCE1E5B','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF';
                                Insert into c_bp_vendor_acct(
                                            c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_vendor_acct_id,v_liability_acct) values
                                            (v_cur.c_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                               
            END IF;
            IF (v_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429')   and not exists (select 0 from c_elementvalue where c_element_id='D871D9715A904125974B545FC0FF0681' and value=v_seqno) then
            --SKR4
                
                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(v_cur.c_bpartner_id),zssi_getbpname(v_cur.c_bpartner_id),'L','N', 'D871D9715A904125974B545FC0FF0681','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429';
                                Insert into c_bp_vendor_acct(
                                    c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_vendor_acct_id,v_liability_acct) values
                                    (v_cur.c_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                                
            END IF;        
             END IF;   
            END LOOP;
            RETURN v_seqno;
END;
$_$
LANGUAGE 'plpgsql';
