
SELECT zsse_DropView ('ils_inout_v');                            
 CREATE OR REPLACE VIEW ils_inout_v AS                            
 SELECT                                                           
         m_inout.m_inout_id AS ils_inout_v_id,                      
         m_inout.ad_client_id AS ad_client_id,                    
         m_inout.ad_org_id AS ad_org_id,                          
         m_inout.isactive AS isactive,                            
         m_inout.created AS created,                              
         m_inout.createdby AS createdby,                          
         m_inout.updated AS updated,                              
         m_inout.updatedby AS updatedby,                          
         m_inout.issotrx AS issotrx,                              
         m_inout.documentno AS documentno,                        
         m_inout.docaction AS docaction,                          
         m_inout.docstatus AS docstatus,                          
         m_inout.c_order_id AS c_order_id,
         m_inout.c_doctype_id AS c_doctype_id,                    
         m_inout.description AS description,    
         m_inout.processing as processing,
         m_inout.processed as processed,
         m_inout.movementtype AS movementtype,                    
         m_inout.movementdate AS movementdate,  
         m_inout.islogistic   AS islogistic,
         m_inout.m_shipper_id AS m_shipper_id,                    
         m_inout.c_project_id AS c_project_id,                    
         m_inout.a_asset_id AS a_asset_id,                        
         m_inout.c_projecttask_id AS c_projecttask_id,
         m_inout.m_warehouse_id
 FROM m_inout;  
 SELECT zsse_DropView ('ils_consumption_overview_v');                            
 CREATE OR REPLACE VIEW ils_consumption_overview_v AS                            
 SELECT  
-- data to show
	 a.description as oe,
	 l.createdby as ad_user_id,
	 a.supervisor_id as supervisor_id,
	 c.movementdate as movementdate,
	 l.m_product_id as m_product_id,
	 l.movementqty as movementqty,
	 coalesce(m_get_product_cost(l.m_product_id,c.movementdate,null,c.ad_org_id),0.0) as costs,
	 (movementqty*coalesce(m_get_product_cost(l.m_product_id,c.movementdate,null,c.ad_org_id),0.0)) as costtotal,
	 l.m_internal_consumptionline_id as m_internal_consumptionline_id,
	 c.movementtype as movementtype,	 
-- stds
	 l.m_internal_consumptionline_id||l.m_product_id AS ils_consumption_overview_v_id,                      
         c.ad_client_id AS ad_client_id,                    
         c.ad_org_id AS ad_org_id,                          
         c.isactive AS isactive,                            
         c.created AS created,                              
         c.createdby AS createdby,                          
         c.updated AS updated,                              
         c.updatedby AS updatedby
         
         
 FROM m_internal_consumption c, ad_user a, m_internal_consumptionline l 
 where l.m_internal_consumption_id=c.m_internal_consumption_id and a.ad_user_id=l.createdby;  
                                                                  
 CREATE OR REPLACE RULE ils_inout_v_insert AS                     
 ON INSERT TO ils_inout_v DO INSTEAD                              
 INSERT INTO m_inout (                                            
         m_inout_id,                                              
         ad_client_id,                                            
         ad_org_id,                                               
         isactive,                                                
         created,                                                 
         createdby,                                               
         updated,                                                 
         updatedby,                                               
         issotrx,                                                 
         documentno,                                              
         docaction,                                               
         docstatus,                                               
         c_order_id,                           
         c_doctype_id,                                            
         description,                                             
         dateacct,                 
         movementtype,                                            
         movementdate,                                            
         m_warehouse_id,    
         m_shipper_id,                                            
         deliveryrule,        
         c_project_id,                                            
         a_asset_id,                                              
         c_projecttask_id,
         freightcostrule,
         DeliveryViaRule,
         PriorityRule,
         islogistic
 ) VALUES (                                                       
         new.ils_inout_v_id,                                      
         new.ad_client_id,                                        
         new.ad_org_id,                                           
         new.isactive,                                            
         new.created,                                             
         new.createdby,                                           
         new.updated,                                             
         new.updatedby,                                           
         new.issotrx,                                             
         new.documentno,                                          
         new.docaction,                                           
         new.docstatus,                                           
         new.c_order_id,                  
         new.c_doctype_id,                                        
         new.description,                                         
         trunc(now()),
         new.movementtype,                                        
         new.movementdate,                                        
         new.m_warehouse_id,
         new.m_shipper_id,                                        
         'A',
         new.c_project_id,                                        
         new.a_asset_id,                                          
         new.c_projecttask_id,
         'I',
         'D',
         '7',
         'Y');                                   
                                                                  
 CREATE OR REPLACE RULE ils_inout_v_update AS                     
 ON UPDATE TO ils_inout_v DO INSTEAD                              
 UPDATE m_inout SET                                                                            
         ad_client_id = new.ad_client_id,                         
         ad_org_id = new.ad_org_id,                               
         isactive = new.isactive,                                 
         created = new.created,                                   
         createdby = new.createdby,                               
         updated = new.updated,                                   
         updatedby = new.updatedby,                               
         issotrx = new.issotrx,                                   
         documentno = new.documentno,                             
         docaction = new.docaction,                               
         docstatus = new.docstatus,                               
         c_order_id= new.c_order_id,                             
         c_doctype_id = new.c_doctype_id,                         
         description = new.description,                           
       
         movementtype = new.movementtype,                         
         movementdate = new.movementdate,                         
        
         m_shipper_id = new.m_shipper_id,                         
        
         c_project_id = new.c_project_id,                         
         
         a_asset_id = new.a_asset_id,                             
         c_projecttask_id = new.c_projecttask_id                  
 WHERE                                                            
         m_inout.m_inout_id = new.ils_inout_v_id;                     
                                                                  
 CREATE OR REPLACE RULE ils_inout_v_delete AS                     
 ON DELETE TO ils_inout_v DO INSTEAD                              
 DELETE FROM m_inout WHERE                                        
         m_inout.m_inout_id = old.ils_inout_v_id;
         
         
  SELECT zsse_DropView ('ils_inoutline_v');                                  
 CREATE OR REPLACE VIEW ils_inoutline_v AS                                  
 SELECT                                                                     
         m_inoutline.m_inoutline_id AS ils_inoutline_v_id,                                       
         m_inoutline.ad_client_id AS ad_client_id,                          
         m_inoutline.ad_org_id AS ad_org_id,                                
         m_inoutline.isactive AS isactive,                                  
         m_inoutline.created AS created,                                    
         m_inoutline.createdby AS createdby,                                
         m_inoutline.updated AS updated,                                    
         m_inoutline.updatedby AS updatedby,                                
         m_inoutline.line AS line,                                          
         m_inoutline.description AS description,                            
         m_inoutline.m_inout_id AS ils_inout_v_id,                              
         m_inoutline.c_orderline_id AS c_orderline_id,                      
         m_inoutline.m_locator_id AS m_locator_id,                          
         m_inoutline.m_product_id AS m_product_id,                          
         m_inoutline.c_uom_id AS c_uom_id,                                  
         m_inoutline.movementqty AS movementqty,                            
         m_inoutline.isinvoiced AS isinvoiced,                              
         m_inoutline.m_attributesetinstance_id AS m_attributesetinstance_id,   
         m_inoutline.a_asset_id AS a_asset_id,                              
         m_inoutline.c_projecttask_id AS c_projecttask_id,                  
         m_inoutline.c_project_id AS c_project_id,                          
         m_inoutline.ad_user_id AS ad_user_id                               
 FROM m_inoutline;                                                          
                                                                            
 CREATE OR REPLACE RULE ils_inoutline_v_insert AS                           
 ON INSERT TO ils_inoutline_v DO INSTEAD                                    
 INSERT INTO m_inoutline (                                                  
         m_inoutline_id,                                                    
         ad_client_id,                                                      
         ad_org_id,                                                         
         isactive,                                                          
         created,                                                           
         createdby,                                                         
         updated,                                                           
         updatedby,                                                         
         line,                                                              
         description,                                                       
         m_inout_id,                                                        
         c_orderline_id,                                                    
         m_locator_id,                                                      
         m_product_id,                                                      
         c_uom_id,                                                          
         movementqty,                                                       
         isinvoiced,                                                        
         m_attributesetinstance_id,                                                                           
         a_asset_id,                                                        
         c_projecttask_id,                                                  
         c_project_id,                                                      
         ad_user_id                                                         
 ) VALUES (                                                                 
         new.ils_inoutline_v_id,                                            
         new.ad_client_id,                                                  
         new.ad_org_id,                                                     
         new.isactive,                                                      
         new.created,                                                       
         new.createdby,                                                     
         new.updated,                                                       
         new.updatedby,                                                     
         new.line,                                                          
         new.description,                                                   
         new.ils_inout_v_id,                                                    
         new.c_orderline_id,                                                
         new.m_locator_id,                                                  
         new.m_product_id,                                                  
         new.c_uom_id,                                                      
         new.movementqty,                                                   
         new.isinvoiced,                                                    
         new.m_attributesetinstance_id,                                                                                     
         new.a_asset_id,                                                    
         new.c_projecttask_id,                                              
         new.c_project_id,                                                  
         new.ad_user_id);                                                   
                                                                            
 CREATE OR REPLACE RULE ils_inoutline_v_update AS                           
 ON UPDATE TO ils_inoutline_v DO INSTEAD                                    
 UPDATE m_inoutline SET                                                                 
         ad_client_id = new.ad_client_id,                                   
         ad_org_id = new.ad_org_id,                                         
         isactive = new.isactive,                                           
         created = new.created,                                             
         createdby = new.createdby,                                         
         updated = new.updated,                                             
         updatedby = new.updatedby,                                         
         line = new.line,                                                   
         description = new.description,                                     
         m_inout_id = new.ils_inout_v_id,                                       
         c_orderline_id = new.c_orderline_id,                               
         m_locator_id = new.m_locator_id,                                   
         m_product_id = new.m_product_id,                                   
         c_uom_id = new.c_uom_id,                                           
         movementqty = new.movementqty,                                     
         isinvoiced = new.isinvoiced,                                       
         m_attributesetinstance_id = new.m_attributesetinstance_id,          
         a_asset_id = new.a_asset_id,                                       
         c_projecttask_id = new.c_projecttask_id,                           
         c_project_id = new.c_project_id,                                   
         ad_user_id = new.ad_user_id                                        
 WHERE                                                                      
         m_inoutline.m_inoutline_id = new.ils_inoutline_v_id;                   
                                                                            
 CREATE OR REPLACE RULE ils_inoutline_v_delete AS                           
 ON DELETE TO ils_inoutline_v DO INSTEAD                                    
 DELETE FROM m_inoutline WHERE                                              
         m_inoutline.m_inoutline_id = old.ils_inoutline_v_id;

 SELECT zsse_DropView ('ils_snrinoutline_v');                      
 CREATE OR REPLACE VIEW ils_snrinoutline_v AS                      
 SELECT                                                            
         snr_minoutline.snr_minoutline_id AS ils_snrinoutline_v_id,   
         snr_minoutline.ad_client_id AS ad_client_id,              
         snr_minoutline.ad_org_id AS ad_org_id,                    
         snr_minoutline.isactive AS isactive,                      
         snr_minoutline.created AS created,                        
         snr_minoutline.createdby AS createdby,                    
         snr_minoutline.updated AS updated,                        
         snr_minoutline.updatedby AS updatedby,                    
         snr_minoutline.m_inoutline_id AS ils_inoutline_v_id,     
         snr_minoutline.m_inoutline_id AS ils_inoutpackage_v_id,
         snr_minoutline.serialnumber AS serialnumber,              
         snr_minoutline.isunavailable AS isunavailable                         
 FROM snr_minoutline;                                              
                                                                   
 CREATE OR REPLACE RULE ils_snrinoutline_v_insert AS               
 ON INSERT TO ils_snrinoutline_v DO INSTEAD                        
 INSERT INTO snr_minoutline (                                      
         snr_minoutline_id,                                        
         ad_client_id,                                             
         ad_org_id,                                                
         isactive,                                                 
         created,                                                  
         createdby,                                                
         updated,                                                  
         updatedby,                                                
         m_inoutline_id,                                           
         quantity,                                                                      
         serialnumber,                                             
         isunavailable                                                                                      
 ) VALUES (                                                        
         new.ils_snrinoutline_v_id,                                
         new.ad_client_id,                                         
         new.ad_org_id,                                            
         new.isactive,                                             
         new.created,                                              
         new.createdby,                                            
         new.updated,                                              
         new.updatedby,                                            
         case when new.ils_snrinoutline_v_id is not null then new.ils_snrinoutline_v_id else  new.ils_inoutpackage_v_id end,                                       
         1,                                                                                  
         new.serialnumber,                                                                     
         new.isunavailable);                                         
                                                                   
 CREATE OR REPLACE RULE ils_snrinoutline_v_update AS               
 ON UPDATE TO ils_snrinoutline_v DO INSTEAD                        
 UPDATE snr_minoutline SET                                                  
         ad_client_id = new.ad_client_id,                          
         ad_org_id = new.ad_org_id,                                
         isactive = new.isactive,                                  
         created = new.created,                                    
         createdby = new.createdby,                                
         updated = new.updated,                                    
         updatedby = new.updatedby,                                
         m_inoutline_id = new.ils_inoutline_v_id,                               
         serialnumber = new.serialnumber,                                         
         isunavailable = new.isunavailable                       
 WHERE                                                             
         snr_minoutline.snr_minoutline_id = new.ils_snrinoutline_v_id; 
                                                                   
 CREATE OR REPLACE RULE ils_snrinoutline_v_delete AS               
 ON DELETE TO ils_snrinoutline_v DO INSTEAD                        
 DELETE FROM snr_minoutline WHERE                                  
         snr_minoutline.snr_minoutline_id = old.ils_snrinoutline_v_id;
        
         
         
CREATE OR REPLACE FUNCTION ils_inout_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_partner_id varchar;
v_loc_id varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    if new.c_bpartner_id is null  then
       if new.m_shipper_id is null then
          RAISE EXCEPTION '%', '@ils_selectshipper@';
       else 
          select c_bpartner_id into v_partner_id from m_shipper where m_shipper_id=new.m_shipper_id;
          new.c_bpartner_id := v_partner_id;
          select c_bpartner_location_id into v_loc_id from c_bpartner_location where c_bpartner_id=v_partner_id and isactive='Y' limit 1;
          new. c_bpartner_location_id := v_loc_id;
       end if;
    end if;
    if new. c_bpartner_location_id is null then
        select c_bpartner_location_id into v_loc_id from c_bpartner_location where c_bpartner_id=new.c_bpartner_id and isactive='Y' limit 1;
        new. c_bpartner_location_id := v_loc_id;
    end if;
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

select zsse_droptrigger('ils_inout_trg','m_inout');

CREATE TRIGGER ils_inout_trg
  BEFORE INSERT OR UPDATE
  ON m_inout
  FOR EACH ROW
  EXECUTE PROCEDURE ils_inout_trg();


  
CREATE OR REPLACE FUNCTION ils_getuserlogisticstoragebin(p_user varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_partner_id varchar;
v_loc_id varchar;
v_wh varchar;
BEGIN
    select c_bpartner_id into v_partner_id from ad_user where ad_user_id=p_user;
    select m_warehouse_id into v_wh from m_warehouse_shipper where isactive='Y' and c_bpartner_id=v_partner_id order by seqno limit 1;
    select m_locator_id into v_loc_id from m_locator where isactive='Y' and islogistic='Y' and m_warehouse_id=v_wh limit 1;
    return v_loc_id;
END; $_$;


CREATE OR REPLACE FUNCTION ils_getdescriptionfromvendormovement(p_serialnumber varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_partner_id varchar;
v_shipper_id varchar;
v_shippartner_id varchar;
v_sigmano varchar;
v_description varchar;
BEGIN
    select coalesce(io.description,''),io.c_bpartner_id,io.m_shipper_id,iol.upc into v_description, v_partner_id, v_shipper_id,v_sigmano
    from m_inout io, m_inoutline iol,snr_minoutline snr 
    where io.movementtype='V+' and io.docstatus='CO' and 
          iol.m_inout_id=io.m_inout_id and snr.m_inoutline_id=iol.m_inoutline_id and snr.serialnumber=p_serialnumber;
    select c_bpartner_id into v_shippartner_id from m_shipper where m_shipper_id=v_shipper_id;
    if v_shippartner_id!=v_partner_id then 
       return (select name from c_bpartner where c_bpartner_id=v_partner_id)|| case when v_sigmano is not null then ' mit der Auftrags- / Bestellnummer: '||v_sigmano else '' end;
    end if;
    return v_description|| case when v_sigmano is not null then ' mit der Auftrags- / Bestellnummer: '||v_sigmano else '' end;
END; $_$;

CREATE OR REPLACE FUNCTION ils_getserialsfrompackagereceipt(p_serialnumber varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
***************************************************************************************************************************************************/
v_return varchar;
v_serials record;
v_minoutline varchar;
v_count numeric:=0;
BEGIN
    v_minoutline:=(select iol.m_inoutline_id from m_inout io, m_inoutline iol,snr_minoutline snr 
    where io.movementtype='V+' and io.docstatus='CO' and 
          iol.m_inout_id=io.m_inout_id and snr.m_inoutline_id=iol.m_inoutline_id and snr.serialnumber=p_serialnumber order by snr.created desc limit 1);
    FOR v_serials in (select serialnumber from snr_minoutline where m_inoutline_id=v_minoutline )
        Loop 
            v_count:=v_count+1;
            if(v_count=1) then
            v_return:=v_serials.serialnumber;
            else
            v_return:=v_return||', '||v_serials.serialnumber;
            end if;
        end loop;
    return v_return;
END; $_$;




CREATE OR REPLACE FUNCTION ils_getshipperfromvendormovement(p_serialnumber varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_return varchar;
BEGIN
    select s.name into v_return from m_shipper s,m_inout io, m_inoutline iol,snr_minoutline snr 
    where s.m_shipper_id=io.m_shipper_id and io.movementtype='V+' and io.docstatus='CO' and 
          iol.m_inout_id=io.m_inout_id and snr.m_inoutline_id=iol.m_inoutline_id and snr.serialnumber=p_serialnumber;
    return v_return;
END; $_$;

CREATE OR REPLACE FUNCTION ils_getdirectmail(p_serialnumber varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_return varchar;
BEGIN
    select io.directmail into v_return from m_inout io,m_inoutline iol, snr_minoutline snr 
    where io.movementtype='V+' and io.docstatus='CO' and 
          iol.m_inout_id=io.m_inout_id and snr.m_inoutline_id=iol.m_inoutline_id and snr.serialnumber=p_serialnumber;
    return v_return;
END; $_$;

 
SELECT zsse_DropView ('ils_internaltransport_v');                            
 CREATE OR REPLACE VIEW ils_internaltransport_v AS                             
  SELECT  snr.m_product_id,
          snr.serialnumber,
          zssi_getusername (snr.ad_user_id) as username,
          l1.value as locator_from,
          l1.m_locator_id as locatorid_from,
          snr.ad_user_id,
          l2.m_locator_id as locatorid_to,
          l2.value as locator_to,
          v.c_projecttask_id as workstepid,
          snr.snr_masterdata_id,
          ils_getshipperfromvendormovement(snr.serialnumber) as shipperinfo,
          ils_getdescriptionfromvendormovement(snr.serialnumber) as vendorinfo
        FROM  
          snr_masterdata snr,c_projecttask v ,m_locator l1, m_locator l2
        WHERE v.receiving_locator=snr.m_locator_id  and 
              l1.m_locator_id=v.receiving_locator and l1.islogistic='Y' and
              l2.m_locator_id=v.issuing_locator and l2.islogistic='Y' and
              v.issuing_locator=ils_getuserlogisticstoragebin(snr.ad_user_id) and
              v.receiving_locator!=v.issuing_locator and
              v.c_project_id is not null;
              
SELECT zsse_DropView ('ils_readytopickup_v');                           
CREATE OR REPLACE VIEW ils_readytopickup_v AS                            
SELECT    snr.m_product_id,
          max(snr.serialnumber) as identifiername,
          count(*) as qty,
          b.name as username,
          l1.value as locator,
          l1.m_locator_id as locatorid,
          snr.ad_user_id,
          max(ils_getserialsfrompackagereceipt(snr.serialnumber)) as serials,
          ils_getdescriptionfromvendormovement(snr.serialnumber) as vendorinfo,
          ils_getshipperfromvendormovement(snr.serialnumber) as shipperinfo,
          max(snr.snr_masterdata_id) as recordid
        FROM 
          snr_masterdata snr,
          m_locator l1,
          c_bpartner b,
          ad_user u
        WHERE snr.m_locator_id is not null and l1.m_locator_id=snr.m_locator_id  and
              l1.islogistic='Y' and
              CASE WHEN ils_getdirectmail(snr.serialnumber)='Y' then 1=1 else snr.m_locator_id=ils_getuserlogisticstoragebin(snr.ad_user_id) end and
              b.c_bpartner_id=u.c_bpartner_id and 
              u.ad_user_id=snr.ad_user_id
        GROUP BY snr.ad_user_id,snr.m_product_id,snr.m_locator_id,l1.m_locator_id,l1.value,b.name  , ils_getdescriptionfromvendormovement(snr.serialnumber), ils_getshipperfromvendormovement(snr.serialnumber) ;    




SELECT zsse_DropFunction ('ils_addSerialLine2InternalConsumptionWithWorkstepLocator');      
CREATE OR REPLACE FUNCTION ils_addSerialLine2InternalConsumptionWithWorkstepLocator(p_product_id varchar,p_serialnumber varchar,p_consumption varchar,p_user varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_org varchar;
v_client varchar;

v_return varchar;
v_locator varchar;
v_project varchar;
v_ptask varchar;

BEGIN
    select c.ad_client_id,c.ad_org_id,c.c_project_id,c.c_projecttask_id, case when instr(c.movementtype,'-')>0 then p.receiving_locator else p.issuing_locator end  
           into v_client,v_org,v_project,v_ptask,v_locator
           from m_internal_consumption c,c_projecttask p 
           where c.c_projecttask_id=p.c_projecttask_id and c.m_internal_consumption_id=p_consumption;
   --raise notice '%',v_user||v_client||v_project||v_ptask||v_locator||v_type;
   --raise notice '%',coalesce(v_lineid,'NOL');
    if v_locator is null then
      return  'ParameterMissing';
    end if;
    select ils_addSerialLine2InternalConsumption(p_product_id ,p_serialnumber ,p_consumption,p_user ,v_client ,v_org ,v_project ,v_ptask ,v_locator) into v_return;
    return v_return;
END; $_$;

SELECT zsse_DropFunction ('ils_addSerialLine2InternalConsumptionOutward');  
CREATE OR REPLACE FUNCTION ils_addSerialLine2InternalConsumptionOutward(p_product_id varchar,p_serialnumber varchar,p_consumption varchar,p_user varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_org varchar;
v_client varchar;

v_return varchar;
v_locator varchar;
v_project varchar;
v_ptask varchar;

BEGIN
    select c.ad_client_id,c.ad_org_id,c.c_project_id,c.c_projecttask_id, snr.m_locator_id
           into v_client,v_org,v_project,v_ptask,v_locator
           from m_internal_consumption c,snr_masterdata snr 
           where c.m_internal_consumption_id=p_consumption and snr.serialnumber=p_serialnumber and snr.m_product_id=p_product_id;
    
   --raise notice '%',v_user||v_client||v_locator;
   --raise notice '%',coalesce(v_lineid,'NOL');
    if v_locator is null then
      return  'ParameterMissing';
    end if;
    select ils_addSerialLine2InternalConsumption(p_product_id ,p_serialnumber ,p_consumption,p_user ,v_client ,v_org ,v_project ,v_ptask ,v_locator) into v_return;
    return v_return;
END; $_$;

CREATE OR REPLACE FUNCTION ils_addSerialLine2InternalConsumptionInbound(p_product_id varchar,p_serialnumber varchar,p_consumption varchar,p_user varchar, p_locator varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_org varchar;
v_client varchar;

v_return varchar;
v_locator varchar;
v_project varchar;
v_ptask varchar;

BEGIN
    select c.ad_client_id,c.ad_org_id,c.c_project_id,c.c_projecttask_id, snr.m_locator_id
           into v_client,v_org,v_project,v_ptask,v_locator
           from m_internal_consumption c,snr_masterdata snr 
           where c.m_internal_consumption_id=p_consumption and snr.serialnumber=p_serialnumber and snr.m_product_id=p_product_id;
    
   --raise notice '%',v_user||v_client||v_locator;
   --raise notice '%',coalesce(v_lineid,'NOL');
    if v_locator is not null or v_client is null then
      return  'error: Product Stocked';
    end if;
    select ils_addSerialLine2InternalConsumption(p_product_id ,p_serialnumber ,p_consumption,p_user ,v_client ,v_org ,v_project ,v_ptask ,p_locator) into v_return;
    return v_return;
END; $_$;

CREATE OR REPLACE FUNCTION ils_checkmovement(p_product_id varchar,p_locator varchar,p_qty varchar,p_serialnumber varchar) RETURNS varchar LANGUAGE plpgsql AS $_$ 
DECLARE 
BEGIN
    if (select qtyonhand from m_storage_detail where m_product_id=p_product_id and m_locator_id=p_locator)< to_number(p_qty) then
        RETURN 'NotEnoughStocked';
    end if;
    if p_serialnumber is not null then
        if (select count(*) from snr_masterdata where m_product_id=p_product_id and serialnumber=p_serialnumber and m_locator_id=p_locator)!=1 then
            RETURN 'NotEnoughStocked';
        end if;
    end if;
    return 'OK';
END; $_$;


CREATE OR REPLACE FUNCTION ils_addLine2InternalConsumption(p_product_id varchar,p_locator varchar,p_qty varchar,p_workstep varchar,p_consumption varchar,p_user varchar) RETURNS varchar
LANGUAGE plpgsql
AS $_$ DECLARE 
v_lineid varchar;
v_Line numeric;
v_count numeric;
v_return varchar;
v_org varchar;
v_client varchar;
v_uom varchar;
v_project varchar;
BEGIN
    if p_product_id is null then
     return 'error';
    end if;
    select c_uom_id into v_uom from m_product where m_product_id=p_product_id;
    select c_project_id into v_project from c_projecttask where c_projecttask_id=p_workstep;
    select ad_client_id,ad_org_id into v_client,v_Org  from m_internal_consumption where m_internal_consumption_id=p_consumption;
    select m_internal_consumptionline_id into v_lineid  from m_internal_consumptionline where m_internal_consumption_id=p_consumption and m_product_id=p_product_id;
    -- Does the line exist?
     if v_lineid is not null then -- Updates if there is a line
        if to_number(p_qty)!=0 then
            update  M_INTERNAL_CONSUMPTIONLINE set MOVEMENTQTY=to_number(p_qty) where M_INTERNAL_CONSUMPTIONLINE_ID=v_lineid; 
        else
            delete from M_INTERNAL_CONSUMPTIONLINE  where M_INTERNAL_CONSUMPTIONLINE_ID=v_lineid; 
        end if;
     else   -- inserts if no line
            select get_uuid() into v_lineid;
            select coalesce(max(line),0)+10 into v_Line from M_INTERNAL_CONSUMPTIONLINE where m_internal_consumption_id=p_consumption;
            insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                                M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID)
                        values (v_lineid,v_client,v_Org,NOW(), p_user, NOW(),p_user,p_consumption,
                                        p_locator ,p_product_id,v_Line,to_number(p_qty),'Generated by Internal Logistics',v_uom,v_project,p_workstep);
     end if;
    v_return:='ils_lineadded';
    return v_return;
END; $_$;



CREATE OR REPLACE FUNCTION ils_addSerialLine2InternalConsumption(p_product_id varchar,p_serialnumber varchar,p_consumption varchar,v_user varchar,v_client varchar,v_org varchar,v_project varchar,
                                                                 v_ptask varchar,v_locator varchar) RETURNS varchar
LANGUAGE plpgsql
AS $_$ DECLARE 
v_lineid varchar;
v_Line numeric;
v_count numeric;
v_return varchar;
v_uom varchar;
BEGIN
    select m_internal_consumptionline_id into v_lineid  from m_internal_consumptionline where m_internal_consumption_id=p_consumption and m_product_id=p_product_id;
    select c_uom_id into v_uom from m_product where m_product_id=p_product_id;
    -- Does the line exist?
    select count(*) into v_count from snr_internal_consumptionline where m_internal_consumptionline_id=v_lineid and serialnumber=p_serialnumber;
    -- Serial exest - So delete and decease qty (Release transaction)
    if v_count>0 then
        delete from snr_internal_consumptionline where m_internal_consumptionline_id=v_lineid and serialnumber=p_serialnumber;
        select MOVEMENTQTY into v_count from M_INTERNAL_CONSUMPTIONLINE where M_INTERNAL_CONSUMPTIONLINE_ID=v_lineid;
        if v_count>1 then
            update  M_INTERNAL_CONSUMPTIONLINE set MOVEMENTQTY=MOVEMENTQTY-1 where M_INTERNAL_CONSUMPTIONLINE_ID=v_lineid;
        else
            delete from M_INTERNAL_CONSUMPTIONLINE where M_INTERNAL_CONSUMPTIONLINE_ID=v_lineid;
        end if;
        v_return:='ils_serialreleased';
    else
        update  M_INTERNAL_CONSUMPTIONLINE set MOVEMENTQTY=MOVEMENTQTY+1 where M_INTERNAL_CONSUMPTIONLINE_ID=v_lineid; -- Updates if there is a line
        if v_lineid is null then -- inserts if no line
            select get_uuid() into v_lineid;
            select coalesce(max(line),0)+10 into v_Line from M_INTERNAL_CONSUMPTIONLINE where m_internal_consumption_id=p_consumption;
            insert into M_INTERNAL_CONSUMPTIONLINE(M_INTERNAL_CONSUMPTIONLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTION_ID, 
                                                                M_LOCATOR_ID, M_PRODUCT_ID, LINE, MOVEMENTQTY, DESCRIPTION, C_UOM_ID, C_PROJECT_ID, C_PROJECTTASK_ID)
                        values (v_lineid,v_client,v_Org,NOW(), v_User, NOW(),v_User,p_consumption,
                                        v_locator ,p_product_id,v_Line,1,'Generated by Internal Logistics',v_uom,v_project, v_ptask);
        end if;
        insert into snr_internal_consumptionline (snr_internal_consumptionline_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_INTERNAL_CONSUMPTIONLINE_ID, 
                                                  quantity,serialnumber)
               values (get_uuid(),v_client,v_Org,NOW(), v_User, NOW(),v_User,v_lineid,1,p_serialnumber);
        v_return:='ils_serialadded';
    end if;
    return v_return;
END; $_$;

CREATE OR REPLACE FUNCTION ils_migratesnrflat() RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_return varchar:='';
v_cur RECORD;
BEGIN

  truncate table ils_snrsinoutflat;
  insert into ils_snrsinoutflat(m_inoutline_id,snr_masterdata_id,serialstext) 
  select m_inoutline.m_inoutline_id,
         (select snr.snr_masterdata_id from snr_minoutline sio,snr_masterdata snr 
                  where sio.snr_masterdata_id=snr.snr_masterdata_id and sio.m_inoutline_id=m_inoutline.m_inoutline_id limit 1),
         (select string_agg(serialnumber, ', ') from snr_minoutline where m_inoutline_id=m_inoutline.m_inoutline_id)
  from m_inoutline where exists (select 0 from snr_minoutline sio where sio.m_inoutline_id=m_inoutline.m_inoutline_id);
    return 'Migration ils_snrsinoutflat DONE';
END; $_$;

CREATE OR REPLACE FUNCTION ils_snrinoutline_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_snrs varchar;
v_snrmaster varchar;
v_orderref varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    IF TG_OP = 'DELETE' THEN 
        select string_agg(serialnumber, ', ') into v_snrs from snr_minoutline where m_inoutline_id=old.m_inoutline_id;
        select ils_orderreference into v_orderref from m_inoutline where m_inoutline_id=old.m_inoutline_id;
        select snr_masterdata_id  into v_snrmaster from snr_minoutline where m_inoutline_id=old.m_inoutline_id and snr_masterdata_id is not null limit 1;
        update ils_snrsinoutflat set serialstext=v_snrs,snr_masterdata_id=v_snrmaster where m_inoutline_id=old.m_inoutline_id;
    ELSE
    
        select string_agg(serialnumber, ', ') into v_snrs from snr_minoutline where m_inoutline_id=new.m_inoutline_id;
        select snr_masterdata_id  into v_snrmaster from snr_minoutline where m_inoutline_id=new.m_inoutline_id and snr_masterdata_id is not null limit 1;
        if (select count(*) from ils_snrsinoutflat  where m_inoutline_id=new.m_inoutline_id)>0 then
           update ils_snrsinoutflat set serialstext=substr(v_snrs,1,2000),snr_masterdata_id=v_snrmaster where m_inoutline_id=new.m_inoutline_id; 
        else
           insert into ils_snrsinoutflat(m_inoutline_id,snr_masterdata_id,serialstext) values (new.m_inoutline_id,v_snrmaster,substr(v_snrs,1,2000));
        end if;
    END IF;
    
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

select zsse_droptrigger('ils_snrinoutline_trg','snr_minoutline');

CREATE TRIGGER ils_snrinoutline_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON snr_minoutline
  FOR EACH ROW
  EXECUTE PROCEDURE ils_snrinoutline_trg();
  

  
  
SELECT zsse_DropView ('ils_inoutpackage_v');                            
CREATE OR REPLACE VIEW ils_inoutpackage_v AS                            
SELECT                                                           
         m_inout.m_inout_id AS ils_inoutpackage_v_id,     
         m_inout.m_inout_id,
         m_inout.ad_client_id AS ad_client_id,                    
         m_inout.ad_org_id AS ad_org_id,                          
         m_inout.isactive AS isactive,                            
         m_inout.created AS created,                              
         m_inout.createdby AS createdby,                          
         m_inout.updated AS updated,                              
         m_inout.updatedby AS updatedby,                          
         m_inout.issotrx AS issotrx,
	 m_inout.directmail AS directmail,                              
         m_inout.documentno AS documentno,                        
         m_inout.docaction as docaction,
         m_inout.docstatus AS docstatus,                          
         m_inout.c_order_id AS c_order_id,
         m_inout.c_doctype_id AS c_doctype_id,                    
         m_inout.description AS description,    
         m_inoutline.description as shipmentcontent,
         m_inoutline.upc as sigmano,
         m_inout.processing as processing,
         case when m_inout.c_bpartner_id=(select c_bpartner_id from m_shipper where m_shipper_id=m_inout.m_shipper_id) then null else m_inout.c_bpartner_id end as partner,
         m_inout.processed as processed,
         m_inout.movementtype AS movementtype,                    
         m_inout.movementdate AS movementdate,  
         m_inout.islogistic   AS islogistic,
         m_inout.m_shipper_id AS m_shipper_id,                    
         m_inout.c_project_id AS c_project_id,                    
         m_inout.a_asset_id AS a_asset_id,                        
         m_inout.c_projecttask_id AS c_projecttask_id,
         m_inout.m_warehouse_id,
         m_inoutline.c_orderline_id AS c_orderline_id,   
         m_inoutline.m_inoutline_id,
         m_inoutline.m_locator_id AS m_locator_id,                          
         m_inoutline.m_product_id AS m_product_id,                          
         m_inoutline.c_uom_id AS c_uom_id,                                  
         m_inoutline.movementqty AS movementqty,                            
         m_inoutline.isinvoiced AS isinvoiced,                                 
         m_inoutline.ad_user_id AS ad_user_id,
         flat.serialstext  as serialnumber,
         zssi_getusername(md.updatedby) as snremployee,
         zssi_getusername(m_inout.updatedby) as employee,
         'X'::character as processbutton,
         m_inoutline.ils_ORDERREFERENCE as orderreference
FROM m_inout left join m_inoutline on m_inout.m_inout_id=m_inoutline.m_inout_id 
             left join ils_snrsinoutflat flat on m_inoutline.m_inoutline_id=flat.m_inoutline_id
             left join snr_masterdata md on md.snr_masterdata_id=flat.snr_masterdata_id 
where  m_inout.islogistic='Y' and m_inout.MovementType IN ('V-', 'V+')  
and (select count(*) from m_inoutline where m_inoutline.m_inout_id=m_inout.m_inout_id)<2
and m_inout.created >= now()- INTERVAL '6 MONTH';       



CREATE OR REPLACE RULE ils_inoutpackage_v_insert AS                     
 ON INSERT TO ils_inoutpackage_v DO INSTEAD                              
(
 INSERT INTO m_inout (                                            
         m_inout_id,                                              
         ad_client_id,                                            
         ad_org_id,                                               
         isactive,                                                
         created,                                                 
         createdby,                                               
         updated,                                                 
         updatedby,                                               
         issotrx,
	 directmail,                                                 
         documentno,                                                                                    
         docstatus,                                               
         c_order_id,                           
         c_doctype_id,                                            
         description,                                             
         dateacct,                 
         movementtype,                                            
         movementdate,                                            
         m_warehouse_id,    
         m_shipper_id,                                            
         deliveryrule,        
         c_project_id,                                            
         a_asset_id,                                              
         c_projecttask_id,
         freightcostrule,
         DeliveryViaRule,
         PriorityRule,
         islogistic,
         docaction,
         c_bpartner_id
 ) VALUES (                                                       
         new.ils_inoutpackage_v_id,                                      
         new.ad_client_id,                                        
         new.ad_org_id,                                           
         new.isactive,                                            
         new.created,                                             
         new.createdby,                                           
         new.updated,                                             
         new.updatedby,                                           
         new.issotrx, 
         new.directmail,                                            
         new.documentno,                                                                                 
         new.docstatus,                                           
         new.c_order_id,                  
         new.c_doctype_id,                                        
         new.description,                                         
         trunc(now()),
         'V+',                                        
         new.movementdate,                                        
         new.m_warehouse_id,
         new.m_shipper_id,                                        
         'A',
         new.c_project_id,                                        
         new.a_asset_id,                                          
         new.c_projecttask_id,
         'I',
         'D',
         '7',
         'Y',
         'CO',
         new.partner);
 INSERT INTO m_inoutline (                                                  
         m_inoutline_id,                                                    
         ad_client_id,                                                      
         ad_org_id,                                                         
         isactive,                                                          
         created,                                                           
         createdby,                                                         
         updated,                                                           
         updatedby,                                                         
         line,                                                                                                                   
         m_inout_id,                                                        
         c_orderline_id,                                                    
         m_locator_id,                                                      
         m_product_id,                                                      
         c_uom_id,                                                          
         movementqty,                                                       
         isinvoiced,                                                                                                                 
         a_asset_id,                                                        
         c_projecttask_id,                                                  
         c_project_id,                                                      
         ad_user_id      ,
         description ,
         upc,
         ils_orderreference
 ) VALUES (                                                                 
         new.ils_inoutpackage_v_id,                                            
         new.ad_client_id,                                                  
         new.ad_org_id,                                                     
         new.isactive,                                                      
         new.created,                                                       
         new.createdby,                                                     
         new.updated,                                                       
         new.updatedby,                                                     
         10,                                                                                                          
         new.ils_inoutpackage_v_id,                                                    
         new.c_orderline_id,                                                
         new.m_locator_id,                                                  
         new.m_product_id,                                                  
         new.c_uom_id,                                                      
         new.movementqty,                                                   
         new.isinvoiced,                                                                                                                                      
         new.a_asset_id,                                                    
         new.c_projecttask_id,                                              
         new.c_project_id,                                                  
         new.ad_user_id,
         new.shipmentcontent,
         new.sigmano,
         new.orderreference
         
  );
);                                            
                                                                  

CREATE OR REPLACE RULE ils_inoutpackage_v_update AS                     
ON UPDATE TO ils_inoutpackage_v DO INSTEAD 
(
 UPDATE m_inout SET                                                                            
         ad_client_id = new.ad_client_id,                         
         ad_org_id = new.ad_org_id,                               
         isactive = new.isactive,                                 
         created = new.created,                                   
         createdby = new.createdby,                               
         updated = new.updated,                                   
         updatedby = new.updatedby,                               
         issotrx = new.issotrx,
         directmail = new.directmail,                                   
         documentno = new.documentno,                                             
         docstatus = new.docstatus,                               
         c_order_id= new.c_order_id,   
         c_bpartner_id=new.partner,
         c_doctype_id = new.c_doctype_id,                         
         description = new.description,                                   
         movementdate = new.movementdate,                         
         m_shipper_id = new.m_shipper_id,                         
         c_project_id = new.c_project_id,                            
         a_asset_id = new.a_asset_id,                             
         c_projecttask_id = new.c_projecttask_id      
 WHERE                                                            
         m_inout.m_inout_id = new.ils_inoutpackage_v_id;    
 UPDATE m_inoutline SET                                                                 
         ad_client_id = new.ad_client_id,                                   
         ad_org_id = new.ad_org_id,                                         
         isactive = new.isactive,                                           
         created = new.created,                                             
         createdby = new.createdby,                                         
         updated = new.updated,                                             
         updatedby = new.updatedby,                                                                           
         description = new.shipmentcontent,                                                                          
         c_orderline_id = new.c_orderline_id,                               
         m_locator_id = new.m_locator_id,                                   
         m_product_id = new.m_product_id,                                   
         c_uom_id = new.c_uom_id,                                           
         movementqty = new.movementqty,                                     
         isinvoiced = new.isinvoiced,                                                
         a_asset_id = new.a_asset_id,                                       
         c_projecttask_id = new.c_projecttask_id,                           
         c_project_id = new.c_project_id,                                   
         ad_user_id = new.ad_user_id,
         upc =new.sigmano,
         ils_orderreference=new.orderreference
         
 WHERE                                                                      
         m_inoutline.m_inoutline_id= new.ils_inoutpackage_v_id;  
);
                                                                  
CREATE OR REPLACE RULE ils_inoutpackage_v_delete AS                     
ON DELETE TO ils_inoutpackage_v DO INSTEAD  
(
 DELETE FROM m_inoutline WHERE                                        
         m_inoutline.m_inout_id= old.ils_inoutpackage_v_id; 
 DELETE FROM m_inout WHERE                                        
         m_inout.m_inout_id = old.ils_inoutpackage_v_id;
);         






CREATE OR REPLACE FUNCTION ils_getInternalDistributionFromINOUT(p_inout_id varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_return varchar:='';
v_cur RECORD;
v_cur2 RECORD;
v_product varchar;
BEGIN
    for v_cur in (select m_product_id,ad_org_id from m_inoutline where m_inout_id=p_inout_id)
    LOOP
        for v_cur in (select 'Im Lager '||w.name||' ist im Lagerort '||l.value||' der Mindestbestand für '||p.value||'-'||p.name||' unterschritten.'||
                            'Es müssen '||coalesce(po.stockmin,0)||' am Lager sein. Der Lagerbestand ist:'||m_bom_qty_onhand(p.m_product_id,null,l.m_locator_id) as description
                    from m_product_org po,m_product p, m_locator l,m_warehouse w
                    where po.isactive='Y' and po.m_product_id=p.m_product_id and po.m_locator_id=l.m_locator_id and l.m_warehouse_id=w.m_warehouse_id  
                    and coalesce(po.stockmin,0)>m_bom_qty_onhand(p.m_product_id,null,l.m_locator_id) and po.isvendorreceiptlocator='N'
                    and po.m_product_id=v_cur.m_product_id and po.ad_org_id=v_cur.ad_org_id)
        LOOP
            if length(v_return)>1 then
                v_return:=v_return||'</br>';
            end if;
            v_return:=v_return|| v_cur.description;
        END LOOP;
    END LOOP;
    return v_return;
END; $_$;




CREATE OR REPLACE FUNCTION ils_postTempinventory(p_tempinventory_id varchar) RETURNS varchar LANGUAGE plpgsql AS $_$ DECLARE 
    v_return varchar:='OK';
    v_cur RECORD;
BEGIN
    for v_cur in (select * from ils_tempinventory  where ils_inventory_id=p_tempinventory_id)
    LOOP
        insert into snr_masterdata(SNR_MASTERDATA_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, M_PRODUCT_ID, SERIALNUMBER, FIRSTSEEN,AD_USER_ID,VENDOR, MODEL, IDENTIFIER2, ORDERREFERENCE, EXTERNALTRACKINGNO, 
                                   IDENTIFIER3, SNRSELFJOIN, REMARK)
               values (get_uuid(), v_cur.AD_CLIENT_ID, v_cur.AD_ORG_ID, v_cur.CREATEDBY, v_cur.UPDATEDBY, v_cur.M_PRODUCT_ID, v_cur.SERIALNUMBER, now(),v_cur.AD_USER_ID,v_cur.VENDOR, v_cur.MODEL, v_cur.IDENTIFIER2,
                                   v_cur.ORDERREFERENCE, v_cur.EXTERNALTRACKINGNO, v_cur.IDENTIFIER3, v_cur.SNRSELFJOIN, v_cur.REMARK);

    END LOOP;
    return v_return;
END; $_$;


CREATE OR REPLACE FUNCTION ils_stashusedidentifier() 
RETURNS VARCHAR
AS $_$
DECLARE
/*****************************************************+
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk 08/2016 danny.heuduk@openz.de


Function is used to stash already used identifiers older than 3 months. If they have the Value Packstueck
*****************************************************/

  v_cur RECORD;
  v_datestamp character varying:= to_char(now(),'DDMMYYYY');
  v_id character varying;
  v_message character varying:='';
  i integer:=0;
BEGIN 

    for v_cur in (select s.serialnumber,s.snr_masterdata_id,s.stashed_identifier,s.m_product_id from snr_masterdata s,m_product m where s.m_product_id=m.m_product_id 
                            and m.value='Packstueck'  and s.stashed_identifier is null and s.created<=now()-90)
    Loop
        v_id:=get_uuid();
        update snr_masterdata set stashed_identifier=v_cur.serialnumber, serialnumber=v_id||v_datestamp where snr_masterdata_id=v_cur.snr_masterdata_id;
        i:=i+1;
    end loop;  
    -- Finishing
   v_message := to_char(i)||' Identifier stashed successfully!'||'                                                                                                              '||v_message ;
   RETURN v_message;
END;
$_$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ils_createinternaltransfer(p_consumption character varying, p_targetlocator character varying) 
RETURNS VARCHAR
AS $_$
DECLARE
/*****************************************************+
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk 04/2017 danny.heuduk@openz.de

Function transfers an existing consumption into a new locator
Needed Consumption_id and targetlocator_id
Called from InternalLogisticData
*****************************************************/

  v_cur RECORD;
  v_curli RECORD;
  v_curlsnr RECORD;
  v_id character varying;
  v_linid character varying;
  v_message character varying:='';
  i integer:=0;
BEGIN 

    for v_cur in (select * from m_internal_consumption where m_internal_consumption_id=p_consumption)
    Loop
        v_id:=get_uuid();
            
            insert into M_INTERNAL_CONSUMPTION(
                M_INTERNAL_CONSUMPTION_ID,
                AD_CLIENT_ID,
                AD_ORG_ID,
                CREATED,
                CREATEDBY,
                UPDATED,
                UPDATEDBY,
                NAME,
                DESCRIPTION,
                MOVEMENTDATE, 
                C_PROJECT_ID,
                C_PROJECTTASK_ID,
                MOVEMENTTYPE,
                DOCUMENTNO,
                DATEACCT)
            values(
                v_id,
                v_cur.ad_client_id,
                v_cur.ad_org_id,
                NOW(),
                v_cur.updatedby,
                NOW(),
                v_cur.createdby,
                'Production-Process',
                'Generated by PDC -> Internal Transfer',
                now(),
                v_cur.c_project_id,
                v_cur.c_projecttask_id,
                'D+',
                ad_sequence_doc('Production',v_cur.ad_org_id,'Y'),
                trunc(now()));
            for v_curli in (select * from m_internal_consumptionline where m_internal_consumption_id=v_cur.m_internal_consumption_id)
            LOOP
                v_linid:=get_uuid();
                insert into M_INTERNAL_CONSUMPTIONLINE(
                    M_INTERNAL_CONSUMPTIONLINE_ID,
                    AD_CLIENT_ID,
                    AD_ORG_ID,
                    CREATED,
                    CREATEDBY,
                    UPDATED,
                    UPDATEDBY,
                    M_INTERNAL_CONSUMPTION_ID,
                    M_LOCATOR_ID, 
                    M_PRODUCT_ID,
                    LINE,
                    MOVEMENTQTY,
                    DESCRIPTION,
                    C_UOM_ID,
                    C_PROJECT_ID,
                    C_PROJECTTASK_ID,
                    snr_masterdata_id)
                values (
                    v_linid,
                    v_curli.ad_client_id,
                    v_curli.ad_org_id,
                    NOW(),
                    v_curli.createdby,
                    NOW(),
                    v_curli.updatedby,
                    v_id,
                    p_targetlocator,
                    v_curli.m_product_id,
                    v_curli.line,
                    to_number(v_curli.movementqty),
                    'Generated by Internal Transfer',
                    v_curli.c_uom_id,
                    v_curli.c_project_id,
                    v_curli.c_projecttask_id,
                    v_curli.snr_masterdata_id);
                        
                        
                    for v_curlsnr in (select * from snr_internal_consumptionline where m_internal_consumptionline_id=v_curli.m_internal_consumptionline_id)
                    LOOP
                        insert into snr_internal_consumptionline (
                            snr_internal_consumptionline_id,
                            AD_CLIENT_ID,
                            AD_ORG_ID,
                            CREATED,
                            CREATEDBY,
                            UPDATED,
                            UPDATEDBY,
                            M_INTERNAL_CONSUMPTIONLINE_ID,
                            quantity,
                            serialnumber,
                            lotnumber,
                            snr_masterdata_id,
                            snr_batchmasterdata_id)
                    values (
                            get_uuid(),
                            v_curlsnr.ad_client_id,
                            v_curlsnr.ad_org_id,
                            NOW(),
                            v_curlsnr.createdby,
                            NOW(),
                            v_curlsnr.updatedby,
                            v_linid,
                            v_curlsnr.quantity,
                            v_curlsnr.serialnumber,
                            v_curlsnr.lotnumber,
                            v_curlsnr.snr_masterdata_id,
                            v_curlsnr.snr_batchmasterdata_id);
                    END LOOP;
            END LOOP;
        
        i:=i+1;
    end loop;  
    -- Finishing
   v_message := v_id;
   RETURN v_message;
END;
$_$ LANGUAGE 'plpgsql';
