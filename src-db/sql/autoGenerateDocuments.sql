CREATE OR REPLACE FUNCTION zspm_generateservices2invoice(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Overload for Process Scheduler

*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='';
v_datefrom timestamp without time zone;
v_dateto timestamp without time zone;
Cur_Parameter record;

v_cur record;
v_i numeric:=0;
v_order varchar;
v_prevOrder varchar;
v_prevPartner varchar;
v_partner varchar;
v_org varchar;
v_rule varchar;
v_product varchar;
v_sprice numeric;
v_price numeric;
v_pl varchar;
v_qty numeric;
v_text varchar;
v_line varchar;
v_loc varchar;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID  into v_Record_ID from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
   if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    else
        v_message := '';
        FOR Cur_Parameter IN
          (SELECT para.*       FROM ad_pinstance pi, ad_pinstance_Para para        WHERE pi.ad_pinstance_ID = para.ad_pinstance_ID     AND pi.ad_pinstance_ID = p_pinstance_ID      ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('date_from') ) THEN
            v_datefrom := Cur_Parameter.p_date;
          END IF;      
            IF ( UPPER(Cur_Parameter.parametername) = UPPER('date_to') ) THEN
            v_dateto := Cur_Parameter.p_date;
          END IF;        
          v_User:=Cur_Parameter.createdby;
        END LOOP; -- Get Parameter
    end if;
    for v_cur in (select fb.* from zspm_ptaskfeedbackline fb,c_projecttask p where p.c_projecttask_id=fb.c_projecttask_id and p.isinvoicableservice='Y' 
                                         and fb.c_orderline_id is null and fb.workdate between v_datefrom and v_dateto order by fb.c_project_id, fb.workdate)
    LOOP
            v_prevOrder:=v_order;
            v_prevPartner:=v_partner;
            select c_bpartner_id,ad_org_id,c_bpartner_location_id into v_partner,v_org,v_loc  from c_project where c_project_id=v_cur.c_project_id ;
            -- New Order when BPartner changes.
            if coalesce(v_partner,'')!= coalesce(v_prevPartner,'')  then  
                    select c_order_id from c_order into v_order where c_doctype_id = '6C8EA6FFBB2B4ACBA0542BA4F833C499' and c_project_id=v_cur.c_project_id  and c_bpartner_id=v_partner and docstatus='CO'
                                 and not exists (select 0 from c_invoice i where i.c_order_id=c_order.c_order_id and i.docstatus!='VO')
                                 and not exists (select 0  from c_invoiceline il,c_invoice i where i.c_invoice_id=il.c_invoice_id and il.c_orderline_id in 
                                                                                (select x.c_orderline_id from c_orderline x where x.c_order_id=c_order.c_order_id) and i.docstatus!='VO') order by datepromised limit 1;
                    if v_order is null then
                                    select case when  paymentrule='K' then 'A'  
                                                          when   paymentrule='P' then 'BC'
                                                          when   paymentrule='C' then 'COD'
                                                          when   paymentrule='B' then 'B' else 'I'  end
                                      into v_rule  from c_bpartner where c_bpartner_id=v_partner;
                                    v_order:=zsse_createOrderHeader(v_org,v_user,v_partner,v_rule,'D',null,null,null,null);
                                    if (select count(*) from c_bpartner_location where c_bpartner_location_id=coalesce(v_loc,'') and isbillto='Y')>0 then 
                                            update c_order set billto_id=v_loc where c_order_id= v_order;
                                    end if;
                                    if substr(v_order,1,3)='ERR' then
                                            raise exception '%',v_order;
                                    end if;
                    else 
                            perform c_order_postaction(v_order,'RE',v_user);
                    end if;
            end if;
            if coalesce(v_order,'')!= coalesce(v_prevOrder,'') and v_prevOrder is not null then
                    -- Post the Prev Order again
                      perform c_order_postaction(v_prevOrder,'CO',v_user);
            end if;
            select m_pricelist_id into v_pl from c_order where c_order_id=v_order;
            select m_product_id into v_product from c_salary_category where c_salary_category_id=v_cur.c_salary_category_id;
            if v_product is null then
                    raise exception '%','In der Vergütungskategorie muss ein Artikel für die Berechnung hinterlegt sein';
            end if;
            v_sprice:=m_bom_pricestd(v_product,v_pl) ;
            v_text:=to_char(v_cur.workdate,'dd.mm.yyyy')||', ' ||(select name from ad_user where ad_user_id=v_cur.ad_user_id)|| '. Leistung: '|| coalesce(v_cur.description,'');
            if coalesce(v_cur.billable,0)=0 then
                    v_price:=0;
                    v_qty:=v_cur.hours;
                    v_text:=v_text||' Keine Berechnung';
           else
                    v_price:=m_get_offers_price(trunc(now()),v_partner,v_product,null,1,v_pl);
                    v_qty:=v_cur.billable;
                     if v_cur.billable!=coalesce(v_cur.hours,0) then
                            v_text:=v_text||'<br/> Tatsächlicher Aufwand:'||coalesce(v_cur.hours,0)||' h'; 
                     end if;
           end if;
          v_line:=zsse_createOrderLine(v_order,v_product,to_char(v_qty) ,to_char(v_price) ,v_text,null);
           if substr(v_line,1,3)='ERR' then
                            raise exception '%',v_order;
          end if;
          update c_orderline set c_project_id=v_cur.c_project_id,c_projecttask_id=v_cur.c_projecttask_id where c_orderline_id=v_line;
          update zspm_ptaskfeedbackline set c_orderline_id=v_line where zspm_ptaskfeedbackline_id=v_cur.zspm_ptaskfeedbackline_id;
          v_i:=v_i+1;
    END LOOP;
    if v_order is not null then
            perform c_order_postaction(v_order,'CO',v_user);
    end if;
    v_Message:=v_i||' Auftragspositionen aus Zeiterfassung erstellt.';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1 , v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  IF(p_pinstance_id IS NOT NULL) THEN
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  ELSE
    RAISE EXCEPTION '%', SQLERRM;
  END IF;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
