CREATE OR REPLACE FUNCTION zspm_generateservices2invoice(p_pinstance_id varchar)
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
v_Record_ID  varchar;
v_User    varchar;
v_message varchar:='';
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
                                    v_order:=zsse_createOrderHeader(v_org,v_user,v_partner,v_rule,'D',null,null,'INTERNAL',null);
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
 
select zsse_dropfunction('m_generateinoutcustomer');
CREATE OR REPLACE FUNCTION m_generateinoutcustomer( v_bpartner varchar, v_datefrom varchar,v_dateto varchar,v_docno varchar,v_project varchar, v_warehouse varchar,v_orgl varchar,v_userorg varchar,v_productlist varchar,v_typeofproduct varchar,v_productcategory varchar,v_option varchar,v_combined varchar,v_partly varchar,v_dateformat varchar,v_lang varchar,
                           ad_client_id OUT varchar, ad_org_id OUT varchar, c_order_id OUT varchar, a_asset_id OUT varchar, c_orderline_id OUT varchar, c_project_id OUT varchar, c_projecttask_id OUT varchar, m_shipper_id OUT varchar, salesrep_id OUT varchar, c_doctype_id OUT varchar, scheddeliverydate out varchar,
                           c_bpartner_id OUT varchar,   businesspartner OUT varchar, m_locator_id OUT varchar,documentno OUT varchar, projectname OUT varchar,  doctypename OUT varchar, dateordered OUT varchar, datepromised OUT varchar, shipper_name OUT varchar, salesrepname OUT varchar, totallines OUT varchar, grandtotal OUT varchar,
                           line OUT varchar,  product_name OUT varchar,  qtyordered OUT varchar, qtydelivered OUT varchar, qtyavailable OUT varchar,qty2deliver OUT varchar, description OUT varchar,  completed OUT varchar,m_attributesetinstance_id OUT varchar,
                           SequenceNO out Numeric,SequenceNO2 out Numeric,m_product_id OUT varchar)
RETURNS SETOF RECORD AS
$BODY$ 
DECLARE
    v_cur1 RECORD;
    v_cur2 RECORD;
    v_seq numeric:=1;
    v_product varchar;
    v_org varchar;
    v_uorg varchar;
    v_todo numeric;
    v_wecan varchar;
    v_reserved numeric;
    v_qoh numeric;
    v_loc varchar;
    v_setprd varchar;
    v_setdelivery numeric;
    v_ordline varchar;
    v_returned varchar:='N';
BEGIN

    perform zsse_droptable ('availItems');
    create temporary table availItems(
        m_product_id character varying(32)  not null,
        m_locator_id character varying(32)  not null,
        m_warehouse_id  character varying(32)  not null,
        m_attributesetinstance_id character varying(32),
        qtyonhand numeric  not null,
        seqno numeric not null
    )  ON COMMIT DROP;
    
    perform zsse_droptable ('setItems');
    create temporary table setItems(
        m_product_id character varying(32)  not null,
        m_warehouse_id  character varying(32)  not null,
        qtyonhand numeric  not null
    )  ON COMMIT DROP;
    
    v_product:=replace(replace(replace(v_productlist,'(',''),')',''),chr(39),'');
    v_org:=replace(v_orgl,chr(39),'');
    v_uorg:=replace(v_userorg,chr(39),'');
    -- Lieferbare Pos. nach Prio UND Lieferbare Pos. nach Lagerort
    for v_cur1 in (select v.ad_client_id,v.ad_org_id,v.m_warehouse_id,v.m_attributesetinstance_id,v.description,v.c_orderline_id,v.scheddeliverydate,v.documentno,v.line,v.c_bpartner_id,
                         v.c_order_id,v.a_asset_id,v.c_project_id,v.c_projecttask_id,v.m_shipper_id,v.salesrep_id,v.c_doctype_id,v.datepromised,v.shipper_name,
                         v.totallines,v.grandtotal,v.qtyordered,v.qtydelivered,v.qtyavailable,p.issetitem,
                         v.qty2deliver,
                         bom.bomqty,
                         p.m_product_id,bom.m_productbom_id,
                         b.name as businesspartner,o.priorityrule,o.dateordered,o.created,p.value 
                         from m_inout_candidate_v v,c_order o,c_bpartner b,m_product p
                              left join m_product_bom bom on bom.m_product_id=p.m_product_id and p.issetitem='Y'
                         where o.c_order_id=v.c_order_id  and o.c_bpartner_id=b.c_bpartner_id and v.m_product_id=p.m_product_id
                         and (exists(select 0 from m_storage_detail d,m_locator l, m_warehouse w where l.m_locator_id=d.m_locator_id and v.m_product_id=d.m_product_id and d.qtyonhand>0  
                                      and l.m_warehouse_id=o.m_warehouse_id
                                      and coalesce(v.m_attributesetinstance_id,'0')=coalesce(d.m_attributesetinstance_id,'0') and w.m_warehouse_id=l.m_warehouse_id and w.isblocked='N')
                                or (p.issetitem='Y' and m_bom_qty_onhand(p.m_product_id,o.m_warehouse_id,null, null)>0))
                         and case when coalesce(v_bpartner,'')='' then 1=1 else v.C_BPARTNER_ID=v_bpartner end
                         and case when coalesce(v_datefrom,'')='' then 1=1 else v.scheddeliverydate >= TO_DATE(v_datefrom) end
                         and case when coalesce(v_dateto,'')='' then 1=1 else v.scheddeliverydate <= TO_DATE(v_dateto) end
                         and case when coalesce(v_docno,'')='' then 1=1 else  v.documentno like v_docno end
                         and case when coalesce(v_project,'')='' then 1=1 else  v.c_project_id like v_project end 
                         and case when coalesce(v_warehouse,'')='' then 1=1 else v.m_warehouse_id = v_warehouse end
                         and case when coalesce(v_org,'')='' then 1=1 else v.ad_org_id =v_org end
                         and case when coalesce(v_product,'')='' then 1=1 else v.m_product_id= ANY(string_to_array(v_product,',')) end
                         and case when coalesce(v_typeofproduct,'')='' then 1=1 else v.typeofproduct = v_typeofproduct end
                         and case when coalesce(v_productcategory,'')='' then 1=1 else v.m_product_category_id = v_productcategory end
                         and v.ad_org_id= ANY(string_to_array(v_uorg,','))
                         and v.issotrx = 'Y'
                         order by o.priorityrule,o.dateordered,o.documentno, case when c_getconfigoption('sortgeneratelinesbyproduct',o.ad_org_id)='Y' then p.value end, v.line )
    LOOP 
        -- Correction of SET Items
        if v_setprd is not null and v_cur1.c_orderline_id!=coalesce(v_ordline,v_cur1.c_orderline_id) and v_returned='Y' then
                update setItems  set qtyonhand=qtyonhand-LEAST(qtyonhand,v_setdelivery) where setItems.m_product_id=v_setprd;
                v_returned:='N';
        end if;
        if v_cur1.issetitem='Y' then
            v_setprd:=v_cur1.m_product_id;
            v_setdelivery:=v_cur1.qty2deliver;
            v_ordline:=v_cur1.c_orderline_id;
        else
            v_setprd:=null;
            v_setdelivery:=null;
            v_ordline:=null;
        end if;
        --raise notice '%', 'L';
        if (select count(*) from  availItems a where a.m_product_id=coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id) and coalesce(a.m_attributesetinstance_id,'0')=coalesce(v_cur1.m_attributesetinstance_id,'0'))=0 then
            for v_cur2 in (select m.qtyonhand,m.m_locator_id from m_storage_detail m,m_locator l,m_product p
                              where l.m_locator_id=m.m_locator_id and m.m_product_id=coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id) and coalesce(m.m_attributesetinstance_id,'0')=coalesce(v_cur1.m_attributesetinstance_id,'0')
                              and l.m_warehouse_id=v_cur1.m_warehouse_id and p.m_product_id=m.m_product_id
                              order by l.priorityno,l.x,l.y,l.z,p.value)
            LOOP
                -- Reserved
                select il.movementqty into v_reserved from m_inoutline il,m_inout i where i.m_inout_id=il.m_inout_id and i.docstatus='RS' and il.m_locator_id=v_cur2.m_locator_id and il.m_product_id=coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id)
                       and coalesce(v_cur1.m_attributesetinstance_id,'0')=coalesce(il.m_attributesetinstance_id,'0');
                if v_reserved is null then v_reserved:=0; end if;
                if v_cur2.qtyonhand-v_reserved>0 then                     
                    insert into availItems(m_product_id,m_locator_id,m_warehouse_id,m_attributesetinstance_id,qtyonhand,seqno) 
                        values (coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id),v_cur2.m_locator_id,v_cur1.m_warehouse_id,v_cur1.m_attributesetinstance_id,v_cur2.qtyonhand,v_seq);
                    v_seq:=v_seq+1;
                end if;
            END LOOP;
            v_seq:=1; 
        end if;
        v_todo:=v_cur1.qty2deliver;
        -- Correction for sets / Keep sets together / SETs nur Komplett.
        if v_cur1.issetitem='Y' then            
            if (select count(*) from setItems a where a.m_product_id=v_cur1.m_product_id and m_warehouse_id=v_cur1.m_warehouse_id)=0 then
                insert into setItems(m_product_id , m_warehouse_id,qtyonhand) values (v_cur1.m_product_id,v_cur1.m_warehouse_id,m_bom_qty_onhand(v_cur1.m_product_id,v_cur1.m_warehouse_id,null, null));                
            end if;
            v_todo:=LEAST((select a.qtyonhand*v_cur1.bomqty from setItems a where a.m_product_id=v_cur1.m_product_id and m_warehouse_id=v_cur1.m_warehouse_id),v_cur1.qty2deliver*v_cur1.bomqty);
        end if;        
        -- Teil-Lieferung
        if v_partly='N' then
            if (select sum(qtyonhand) from availItems a where a.m_product_id=coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id) and coalesce(a.m_attributesetinstance_id,'0')=coalesce(v_cur1.m_attributesetinstance_id,'0')
                                and a.m_warehouse_id=v_cur1.m_warehouse_id and a.qtyonhand>0) >= v_todo
            then
                v_wecan:='Y';
            else
                v_wecan:='N';
            end if;
            -- Partly-> Only Complete Set
            if v_cur1.issetitem='Y' and v_todo<v_cur1.qty2deliver*v_cur1.bomqty then
                v_wecan:='N';
            end if;
        else
            v_wecan:='Y';
        end if;
        for v_cur2 in (select * from availItems a where a.m_product_id=coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id) and coalesce(a.m_attributesetinstance_id,'0')=coalesce(v_cur1.m_attributesetinstance_id,'0')
                                and a.m_warehouse_id=v_cur1.m_warehouse_id and a.qtyonhand>0 and v_wecan='Y' order by a.seqno)
        LOOP
            if v_todo<=0 then
                exit;
            end if;
            -- immer gleich
            ad_client_id:=v_cur1.ad_client_id;
            ad_org_id:=v_cur1.ad_org_id;
            m_locator_id:=v_cur2.m_locator_id;            
            qty2deliver:=case when (v_cur2.qtyonhand-v_todo)<0 then v_cur2.qtyonhand else v_todo end;   
            --raise notice '%', v_todo;           
            v_todo:=v_todo-to_number(qty2deliver);
            product_name:=zssi_getproductnamewithvalue(coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id),v_lang)||case when v_cur1.issetitem='Y' then '('||(select xp.value from m_product xp where xp.m_product_id=v_cur1.m_product_id)||')' else '' end;
            description:=zssi_html4docs(coalesce(v_cur1.description,''));
            m_attributesetinstance_id:=v_cur1.m_attributesetinstance_id;
            m_product_id:=coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id); -- Relevant for SET Products. This is the actual delivered Product, while in Orderline is the set
            completed:='N';
            -- Lieferbare Pos. nach Lagerort
            if v_option='DELBYLOCATOR' then
                c_order_id:='###';
                c_orderline_id:=v_cur1.c_orderline_id||v_cur2.m_locator_id;
                scheddeliverydate:=to_char(v_cur1.scheddeliverydate,v_dateformat);
                --description:=zssi_html4docs(v_cur1.documentno||'-'||v_cur1.line||coalesce(v_cur1.description,''));
                description:=v_cur1.documentno||'-'||v_cur1.line;
                a_asset_id:='';
                c_project_id:='Div.';
                c_projecttask_id:='Div.';
                c_doctype_id:='Div.';
                c_bpartner_id:='#####';
                businesspartner:='Div.';
                documentno:='Div.';
                projectname:='Div.';
                doctypename:='Div.';
                dateordered:='Div.';
                datepromised:='Div.';
                line:='10';  
                -- Sort only by Locator
                select to_number(lpad(to_char(l.priorityno),3,'0')||lpad(to_char(l.x),3,'0')||lpad(to_char(l.y),3,'0')||lpad(to_char(l.z),3,'0')) into SequenceNO from m_locator l where l.m_locator_id=v_cur2.m_locator_id;   
                SequenceNO2:=0;
            end if;
            -- Lieferbare Pos. nach Prio
            if v_option='DELBYPRIORITY' then           
                -- Sort by Locator 2nd
                select to_number(lpad(to_char(l.priorityno),3,'0')||lpad(to_char(l.x),3,'0')||lpad(to_char(l.y),3,'0')||lpad(to_char(l.z),3,'0')) into SequenceNO2 from m_locator l where l.m_locator_id=v_cur2.m_locator_id;                  
                -- Sammellieferschein
                if v_combined='Y' then
                    -- Sort by Business Partner 1st.
                    select to_number(to_char(b.created,'yymmddhh24miss')) into SequenceNO from c_bpartner b where b.c_bpartner_id= v_cur1.c_bpartner_id;
                    c_order_id:=v_cur1.c_bpartner_id||'#';
                    c_orderline_id:=v_cur1.c_bpartner_id||coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id)||v_cur2.m_locator_id;
                    --c_orderline_id:=v_cur1.c_orderline_id;
                    scheddeliverydate:=to_char(now(),v_dateformat);
                    a_asset_id:='Div.';
                    c_project_id:='Div.';
                    c_projecttask_id:='Div.';
                    c_doctype_id:='Div.';
                    c_bpartner_id:=v_cur1.c_bpartner_id;
                    businesspartner:=v_cur1.businesspartner;
                    documentno:='Div.';
                    projectname:='Div.';
                    doctypename:='Div.';
                    dateordered:='Div.';
                    datepromised:='Div.';      
                    
                else
                    -- Sort by order 1st.
                    SequenceNO:=to_number(v_cur1.priorityrule||to_char(v_cur1.dateordered,'yymmdd')||to_char(v_cur1.created,'hh24miss'));
                    c_order_id:=v_cur1.c_order_id;
                    c_orderline_id:=v_cur1.c_orderline_id||v_cur2.m_locator_id;
                    a_asset_id:=v_cur1.a_asset_id;
                    c_project_id:=v_cur1.c_project_id;
                    c_projecttask_id:=v_cur1.c_projecttask_id;
                    m_shipper_id:=v_cur1.m_shipper_id;
                    salesrep_id:=v_cur1.salesrep_id;
                    c_doctype_id:=v_cur1.c_doctype_id;
                    scheddeliverydate:=to_char(v_cur1.scheddeliverydate,v_dateformat);
                    c_bpartner_id:=v_cur1.c_bpartner_id;
                    businesspartner:=v_cur1.businesspartner;
                    documentno:=v_cur1.documentno;
                    projectname:= zssi_getorderadditionaltext4manualtrx1(v_cur1.c_order_id,v_lang);
                    doctypename:=zssi_getorderadditionaltext4manualtrx2(v_cur1.c_order_id,v_lang);
                    dateordered:=to_char(v_cur1.dateordered,v_dateformat);
                    datepromised:=to_char(v_cur1.datepromised,v_dateformat);
                    shipper_name:=v_cur1.shipper_name;
                    totallines:=v_cur1.totallines;
                    grandtotal:=v_cur1.grandtotal;
                    line:=v_cur1.line;
                    qtyordered :=v_cur1.qtyordered;
                    qtydelivered:=v_cur1.qtydelivered;
                    qtyavailable:=v_cur1.qtyavailable;
                end if;
            end if;
            RETURN NEXT;
            v_returned:='Y';
            update availItems set qtyonhand=case when (availItems.qtyonhand-v_cur1.qty2deliver)<0 then 0 else (availItems.qtyonhand-v_cur1.qty2deliver) end where availItems.m_product_id=coalesce(v_cur1.m_productbom_id,v_cur1.m_product_id) and coalesce(availItems.m_attributesetinstance_id,'0')=coalesce(v_cur2.m_attributesetinstance_id,'0')
                                and availItems.m_locator_id=v_cur2.m_locator_id and availItems.seqno=v_cur2.seqno;            
        END LOOP;        
    END LOOP;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
                  
