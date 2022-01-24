/**************************************************************************************************************************************+



CRM





***************************************************************************************************************************************/
select zsse_dropview('zssi_crm_todos');

CREATE VIEW zssi_crm_todos AS
SELECT nc.zssi_notes4customer_id AS zssi_crm_todos_id, nc.zssi_notes4customer_id, c_b.c_bpartner_id,  crma.name AS typeofcontact, nc.dateofcontact, nc.description, nc.followup, 
        nc.contact_by,
        nc.followup_by ,
        nc.ad_user_id,
        nc.ad_userid_next ,
        nc.ad_client_id, nc.ad_org_id, nc.isactive, nc.created, nc.updated, nc.createdby, nc.updatedby, nc.c_project_id,nc.followup_done, c_b.name, c_b.value,nc.c_campaign_id,nc.zssi_crmactions_id,next_action,
        p.c_user_position_id,d.c_user_department_id,u.phone,u.phone2,u.email,
        nc.volume,nc.estpropability,nc.budget,
        c_b.rating,c_b.c_lineofbusiness_id,
        (select min(xx.dateofcontact) from zssi_notes4customer xx where xx.c_bpartner_id=c_b.c_bpartner_id) as firstcontact, 
        case when nc.followup_Done='N' and nc.followup is not null then check_limit_img3('Y'::varchar, trunc(nc.followup)-to_date('01.01.1900','dd.mm.yyyy'), trunc(now())-to_date('01.01.1900','dd.mm.yyyy'),trunc(now()-10)-to_date('01.01.1900','dd.mm.yyyy')) else null end AS IMAGE 
FROM c_bpartner c_b, zssi_crmactions crma, zssi_notes4customer nc  left join ad_user u on u.ad_user_id=nc.ad_user_id
        left join c_user_position p on p.c_user_position_id=u.c_user_position_id
        left join c_user_department d on d.c_user_department_id=u.c_user_department_id
WHERE nc.zssi_crmactions_id::text = crma.zssi_crmactions_id::text AND c_b.c_bpartner_id::text = nc.c_bpartner_id::text AND  nc.isactive = 'Y'::bpchar;

CREATE OR REPLACE RULE zssi_crm_todos_insert AS                     
ON INSERT TO zssi_crm_todos DO INSTEAD                              
        ( INSERT INTO zssi_notes4customer (
        zssi_notes4customer_id,
        ad_client_id,
        ad_org_id,
        createdby,
        updatedby,
        description,
        followup,
        ad_user_id,
        dateofcontact,
        c_campaign_id,
        followup_done,
        followup_by,
        zssi_crmactions_id,
        contact_by,
        ad_userid_next,
        next_action,
        c_project_id,
        c_bpartner_id,volume,estpropability,budget
)
        VALUES (
        new.zssi_crm_todos_id,
        new.ad_client_id,
        new.ad_org_id,
        new.createdby,
        new.updatedby,
        new.description,
        new.followup,
        new.ad_user_id,
        new.dateofcontact,
        new.c_campaign_id,
        new.followup_done,
        new.followup_by,
        new.zssi_crmactions_id,
        new.contact_by,
        new.ad_userid_next,
        new.next_action,
        new.c_project_id,
        new.c_bpartner_id,
        new.volume,new.estpropability,new.budget
        )
);

CREATE OR REPLACE RULE zssi_crm_todos_update AS                     
ON UPDATE TO zssi_crm_todos DO INSTEAD                              
(       UPDATE zssi_notes4customer SET
        ad_client_id=new.ad_client_id,
        ad_org_id=new.ad_org_id,
        createdby=new.createdby,
        updatedby=new.updatedby,
        updated=now(),
        description=new.description,
        followup=new.followup,
        ad_user_id=new.ad_user_id,
        dateofcontact=new.dateofcontact,
        c_campaign_id=new.c_campaign_id,
        followup_done=new.followup_done,
        followup_by=new.followup_by,
        zssi_crmactions_id=new.zssi_crmactions_id,
        contact_by=new.contact_by,
        ad_userid_next=new.ad_userid_next,
        next_action=new.next_action,
        c_project_id=new.c_project_id,
        volume=new.volume,estpropability=new.estpropability,budget=new.budget
        WHERE  zssi_notes4customer_id=new.zssi_crm_todos_id;
);

CREATE OR REPLACE RULE zssi_crm_todos_delete AS                     
ON DELETE TO zssi_crm_todos DO INSTEAD       
(
        delete from zssi_notes4customer WHERE  zssi_notes4customer_id=old.zssi_crm_todos_id;
); 
                                
select zsse_dropfunction('zssi_crm_getinterests'); 
CREATE or replace FUNCTION zssi_crm_getinterests(v_user_id character varying ) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Looks Like--> - interest A - interest B - etc.
*****************************************************/
DECLARE
v_line character varying;
v_cur record;
v_interest character varying;
BEGIN
FOR v_cur in (select r_interestarea.name as v_interest from  r_interestarea left join r_contactinterest on r_contactinterest.r_interestarea_id=r_interestarea.r_interestarea_id where ad_user_id=v_user_id)
LOOP
--v_line:=coalesce(v_line,'-')||v_cur.v_bomqty||' '||zssi_getproductname(v_cur.v_bomproduct,v_lang)||' '||coalesce(v_cur.v_bomdescription,(select m_product.description from m_product where m_product_id=v_bomproduct))||'<br/>-';
v_line:=coalesce(v_line,'')||chr(32)||'- '||coalesce(v_cur.v_interest,'');
END LOOP;
return v_line;
END;
$_$
LANGUAGE plpgsql VOLATILE
COST 100;





SELECT zsse_DropView ('zssi_crm_bpartner_v');


CREATE OR REPLACE VIEW zssi_crm_bpartner_v AS
            SELECT bp.C_BPartner_ID ||  COALESCE(TO_CHAR(c.ad_user_id), '') || COALESCE(TO_CHAR(l.c_location_id),'')  AS zssi_crm_bpartner_v_id,
            --Standards
                bp.ad_client_id,
                bp.ad_org_id,
                bp.created,
                bp.updated,
                bp.createdby,
                bp.updatedby,
                bp.c_bpartner_id,
                bp.isactive,
                bp.name as name, 
                bp.value, 
                bp.name2,
                bp.c_bp_group_id,
                bp.url,
                bp.rating,bp.c_lineofbusiness_id,
                coalesce(coalesce((select a.c_location_id from c_bpartner_location a where a.c_bpartner_location_id=c.c_bpartner_location_id and a.c_bpartner_id=bp.c_bpartner_id),(select part.c_location_id from c_bpartner_location part where part.c_bpartner_id=bp.c_bpartner_id and part.isheadquarter='Y')),bp.c_location_id) as C_BPartner_Location_ID, 	--Anschrift
                c.name AS Contact, 				      		--Ansprechpartner	
                c.ad_user_id,
                c.email,	
                c.c_greeting_id,
                c.firstname,
                c.lastname,
                c.birthday,
                c.description,
                c.ad_language,
                coalesce(c.phone,bpl.Phone) as phone,		      		--A Telefon
                c.phone2,
                c.fax,
                c.comments,
                coalesce(zssi_crm_getinterests(c.ad_user_id),'') as interests,
                bp.iscustomer,
                bp.isvendor,
                l.address1,
                l.address2,
                l.city,
                l.postal,
                l.c_country_id
                
            FROM 	C_BPARTNER_LOCATION bpl,C_LOCATION l ,
                C_BPARTNER bp 
                left join AD_USER c on bp.c_bpartner_id = c.c_bpartner_id 
                AND c.IsActive ='Y'
            WHERE bp.c_bpartner_id = bpl.c_bpartner_id and 
                bpl.IsActive = 'Y' and 
                case when bp.isemployee='Y' then (bp.iscustomer='Y' or bp.isvendor='Y') else 1=1 end and
                bpl.c_location_id=l.C_Location_ID and 
                                case when c.ad_user_id is not null then case when c.c_bpartner_location_id is not null then c.c_bpartner_location_id=bpl.c_bpartner_location_id else bpl.isheadquarter='Y' end else 1=1 end ;

                                
CREATE OR REPLACE FUNCTION zssi_notes4customer_history_trg()
RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2018 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**********************************************************************************************************************************************/
v_vendor character varying;
v_vproductno character varying;
v_productid character varying;
v_org character varying;
v_youngest timestamp;
v_manufacturer varchar;
v_manuno varchar;
BEGIN
IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
if (TG_OP ='UPDATE') then
    if old.updated<now()-1 then
        insert into zssi_notes4customer_history (zssi_notes4customer_id, ad_client_id, ad_org_id, createdby, updatedby, description, followup, c_bpartner_id, ad_user_id, dateofcontact, c_campaign_id, lead2sale, followup_done, followup_by, zssi_crmactions_id, contact_by, ad_userid_next, next_action, c_project_id, volume, estpropability, budget, zssi_notes4customer_history_id)
        values (old.zssi_notes4customer_id, old.ad_client_id, old.ad_org_id, old.createdby, old.updatedby, old.description, old.followup, old.c_bpartner_id, old.ad_user_id, old.dateofcontact, old.c_campaign_id, old.lead2sale, old.followup_done, old.followup_by, old.zssi_crmactions_id, old.contact_by, old.ad_userid_next, old.next_action, old.c_project_id, old.volume, old.estpropability, old.budget, get_uuid());
    end if;
end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;



select zsse_droptrigger('zssi_notes4customer_history_trg','zssi_notes4customer');

CREATE TRIGGER zssi_notes4customer_history_trg
AFTER UPDATE 
ON zssi_notes4customer
FOR EACH ROW
EXECUTE PROCEDURE zssi_notes4customer_history_trg();
