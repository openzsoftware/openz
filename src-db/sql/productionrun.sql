

select zsse_DropFunction('zssm_workhours2workcalendardaybackward');
CREATE OR REPLACE FUNCTION zssm_workhours2workcalendardaybackward(datestart timestamp,v_workhours numeric,v_org varchar,v_precise varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours


*****************************************************/


v_cur record;
v_hours numeric:=0;
v_datehours numeric:=0;
v_workhoursbegunonstart numeric;
v_begintime timestamp;
BEGIN
    if v_precise='Y' then
        select c_getorgworkbegintime(v_org, trunc(datestart)) into v_begintime;
        v_workhoursbegunonstart:= extract(hour from datestart) - extract(hour from v_begintime);
        if v_workhoursbegunonstart<0 then 
            v_workhoursbegunonstart:=0;
        end if;
        for v_cur in (select worktime,workdate from c_workcalender  where workdate <= datestart order by workdate desc)
        LOOP
            v_datehours:=coalesce(c_getorgworktime(v_org,v_cur.workdate),v_cur.worktime);
            if v_hours+v_datehours >= v_workhours then
            return v_cur.workdate;
            else
            v_hours:=v_hours+v_datehours;
            end if;
        END LOOP;
    end if;
    return datestart-trunc(v_workhours/5.7);
END;
$_$  LANGUAGE 'plpgsql';

select zsse_DropFunction('zssm_workhours2workcalendardayforward');
CREATE OR REPLACE FUNCTION zssm_workhours2workcalendardayforward(datestart timestamp,v_workhours numeric,v_org varchar,v_precise varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours


*****************************************************/


v_cur record;
v_hours numeric:=0;
v_datehours numeric:=0;
v_workhoursbegunonstart numeric;
v_begintime timestamp;
BEGIN
    if v_precise='Y' then
        select c_getorgworkbegintime(v_org, trunc(datestart)) into v_begintime;
        v_workhoursbegunonstart:= extract(hour from datestart) - extract(hour from v_begintime);
        if v_workhoursbegunonstart<0 then 
            v_workhoursbegunonstart:=0;
        end if;
        for v_cur in (select worktime,workdate from c_workcalender  where workdate >= datestart order by workdate)
        LOOP
            v_datehours:=coalesce(c_getorgworktime(v_org,v_cur.workdate),v_cur.worktime);
            if v_hours+v_datehours >= v_workhours then
            return v_cur.workdate;
            else
            v_hours:=v_hours+v_datehours;
            end if;
        END LOOP;
    end if;
    return datestart-trunc(v_workhours/5.7);
END;
$_$  LANGUAGE 'plpgsql';


select zsse_DropFunction ('zssm_getassemblyproductionworkhours');
CREATE OR REPLACE FUNCTION zssm_getassemblyproductionworkhours(dateneeded timestamp,p_productid varchar,v_qty numeric,v_org varchar,v_precise varchar) RETURNS numeric
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly.

Calculates working - hours, Returns Timestamp to start

DO NOT USE IF YOU ARE NOT SHURE THAT A CORRECT PRODUCT, That has a valid Production Plan is Supplied

*****************************************************/

v_tp numeric:=0; -- Time Production (Gesamtzeit Kompletter Durchlauf)
v_trz numeric; -- Setuptime (Rüstzeit)
v_tst numeric; -- Time per Piece (Stückzeit)
v_tpvl  numeric:=0; --Time Production (Iterationsschritt)
v_plan varchar;
v_wh varchar;
v_cur record;
v_count numeric;
v_EstStock numeric;
v_pleadtime numeric:=0; -- Purchase Time (Global)
v_gleadtime numeric:=0; --  Purchase Time Temp Table
v_tpvlt numeric; -- Purchase Time (Local) or BOM Production Time (Local BOM)
v_avgwt numeric;
BEGIN
    --raise notice '%','----------------------------------------------------------------------------------Calculating Product:'||zssi_getproductname(p_productid,'de_DE')||' - Qty:'||v_qty;
    -- TODO: Get a valid Plan for the desired Organization.
    -- At the moment, the first valid default plan is taken
    select a.p_warehouse,a.p_planid,a.p_setuptime/60,a.p_timeperpiece/60,a.p_ad_org_id
           into v_wh,v_plan,v_trz,v_tst
           from zssm_getworkstepandwarehouse(p_productid,v_org) a;
    --if mrp_estimated_stockqty(p_productid,v_wh,trunc(dateneeded))>=v_qty then
    --        return now();
    --end if;
    -- time formula (in hours)
    v_tp:=(v_trz+v_qty*v_tst+v_tpvl);
    if v_plan is null then
     raise exception '%','No Production Plan found for Product: '||zssi_getproductnamewithvalue(p_productid,'de_DE');
    end if;
    --raise notice '%','TPstart:'||v_tp||'-Plan:'||v_plan;
    -- Loop through BOM
    for v_cur in (select b.m_product_id,sum(b.quantity) as quantity,p.production from zspm_projecttaskbom b,m_product p where b.m_product_id=p.m_product_id and b.c_projecttask_id in  
                         (select c_projecttask_id from zssm_productionplan_task_v where zssm_productionplan_v_id=v_plan)
                         group by b.m_product_id,p.production order by p.production desc)
    LOOP
      -- Keine Zeit kalkulieren -> Artikel wird in diesem Plan mit produziert (Kalk ist dann auf dem Prd-AG für den Artikel)
      if (select count(*) from c_projecttask where assembly='Y' and m_product_id=v_cur.m_product_id and 
            c_projecttask_id in (select c_projecttask_id from zssm_productionplan_task_v where zssm_productionplan_v_id=v_plan))=0
      then
        -- On Hand?
        v_EstStock:=mrp_estimated_stockqty(v_cur.m_product_id,v_wh, trunc(zssm_workhours2workcalendardaybackward(dateneeded,v_tp,v_org,v_precise)));
        --if v_cur.m_product_id='798A448E359A435687D6F08602B21B4E' then
        --    perform logg('--PR--'||(select value||'#'||name from m_product where m_product_id=v_cur.m_product_id)||'--QTY--'||v_EstStock||'--NEEDQTY--'||v_cur.quantity*v_qty||'---DT---'||dateneeded);
        --end if;
        --raise notice '%','in BOM - P:'||v_cur.production||' Prod:'||zssi_getproductname(v_cur.m_product_id,'de_DE')||' Stock:'||v_EstStock||' Need:'||v_cur.quantity*v_qty||' Date:'||dateneeded;
        if v_EstStock<v_cur.quantity*v_qty then
            if v_cur.production='N' or 
               ((select count(*) from m_product_org ogg where ogg.isactive='Y' and ogg.m_product_id=v_cur.m_product_id and ogg.ad_org_id=v_org and ogg.isproduction='Y')=0 and
                (select count(*) from m_product_org ogg where ogg.isactive='Y' and ogg.m_product_id=v_cur.m_product_id and ogg.ad_org_id=v_org and ogg.isproduction='N')>0) 
            then
                -- Average Work Time in ORG
                select (worktimemonday+worktimetuesday+worktimewednesday+worktimethursday+worktimefriday)/5 into v_avgwt from c_workcalendarsettings where ad_org_id=v_org;
                -- Purchasing (best Rated)
                SELECT coalesce(deliverytime_promised,1)*coalesce(v_avgwt,8) into v_tpvlt FROM M_PRODUCT_PO po
                                                                    WHERE po.m_product_id=v_cur.M_Product_ID and PO.iscurrentvendor='Y' and PO.AD_ORG_ID in ('0',v_org)
                                                                    ORDER BY COALESCE(po.qualityrating,0) DESC, updated DESC LIMIT 1;
                /*
                if zssm_workhours2workcalendardaybackward(dateneeded,v_tp+v_tpvlt,v_org,v_precise)< to_timestamp(now()) then
                    -- Purchasing (Quickest)
                    SELECT coalesce(deliverytime_promised,1)*8 into v_tpvlt FROM M_PRODUCT_PO po
                                                                    WHERE po.m_product_id=v_cur.M_Product_ID and PO.iscurrentvendor='Y' and PO.AD_ORG_ID in ('0',v_org)
                                                                    ORDER BY COALESCE(po.deliverytime_promised,1) DESC, updated DESC LIMIT 1;
                end if;
                */
                if v_tpvlt is null then
                    RAISE EXCEPTION '%','@zssm_nopurchasedefined4product@'||zssi_getproductnamewithvalue(v_cur.m_product_id,'de_DE');
                end if;
                --raise notice '%','PurchseTime:'||v_tpvlt;
                --if v_pleadtime < v_tpvlt then 
                    --v_pleadtime:=v_tpvlt; 
                    --v_tpvlt:=v_tpvlt-v_pleadtime;
                    --v_pleadtime:=v_pleadtime+v_tpvlt;
                    select leadtime into v_gleadtime from calcu limit 1;
                    if v_gleadtime is not null then
                        if v_gleadtime < v_tpvlt then
                            delete from calcu;
                            insert into calcu (leadtime) values (v_tpvlt);
                            v_pleadtime:=v_tpvlt;
                        else
                            v_pleadtime:=0;
                        end if;
                    end if;
                    --raise notice '%', 'Add PURCHASE LeadTime:'||v_tpvlt||'---------------------------------------------------------Purchase Lead Time is now:'||v_pleadtime;  
              -- else
                   -- v_tpvlt:=0;
               -- end if;
            else -- Production ITEM - RECURSIVE CALL
                -- Produced in same plan?
                select count(*) into v_count from zssm_productionplan_task_v where zssm_productionplan_v_id=v_plan and assembly='Y' and m_product_id=v_cur.m_product_id;
                if v_count=0 then
                    -- Production in another Plan - Call me Recursive
                    v_tpvlt:=zssm_getassemblyproductionworkhours(zssm_workhours2workcalendardaybackward(dateneeded,v_tp,v_org,v_precise),v_cur.m_product_id,v_cur.quantity*v_qty-v_EstStock,v_org,v_precise);
                    --raise notice '%','-----------------'||zssi_getproductname(p_productid,'de_DE')||'PrOductiontime -------------------------------------------ITERATION:'||v_tpvlt;
                else
                    v_tpvlt:=0;
                end if;
            end if;
            if v_tpvl<v_tpvlt then
                    v_tpvl:=v_tpvlt;
            end if;
            v_tp:=(v_trz+v_qty*v_tst+v_tpvl);
        end if; --On Hand
      end if; -- Keine Zeit kalkulieren
    END LOOP;
   -- raise notice '%','SUM of TIMES:'||v_tp+v_pleadtime;
    RETURN v_tp+v_pleadtime;
END;
$_$  LANGUAGE 'plpgsql';

select zsse_DropFunction('zssm_getFastestProductionDoneDate');

CREATE OR REPLACE FUNCTION zssm_getFastestProductionDoneDate(p_productid varchar,p_qty numeric,p_org varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours

DO NOT USE IF YOU ARE NOT SHURE THAT A CORRECT PRODUCT, That has a valid Production Plan is Supplied

*****************************************************/

v_beginproductiondate timestamp;
v_estdeliverydate timestamp;
v_days interval;
v_wh varchar;
v_qty numeric;
v_count numeric;
v_trz numeric;
v_tst numeric;
v_hourstest numeric;
v_cur record;
v_mvdate timestamp;
v_mmv varchar:='N';
BEGIN
        --v_qty:=p_qty;
        select  p_movementqtyOut into v_qty from zssm_getrequiredqty(p_productid,p_qty,p_org);
        select a.p_setuptime/60,a.p_timeperpiece/60 into v_trz,v_tst from zssm_getworkstepandwarehouse(p_productid,p_org) a;
        v_hourstest:=(v_trz+v_qty*v_tst); -- Reine Produktionszeit
        v_beginproductiondate:=now()-1;
        v_estdeliverydate:=trunc(now());
        WHILE v_beginproductiondate<trunc(now())
        LOOP            
            v_beginproductiondate:=zssm_getlatestproductionstart(p_productid,v_qty,v_estdeliverydate,p_org);
            if v_mmv='N' then
                -- Strategie MIN-Zeitraum: immer die nächste Materialbewegung eines Stücklistebnartikels prüfen.
                -- Da könnte Mat kommen, das wir schneller fertig werden. (Prüf-Zeitraum auf auf MAX-Zeitraum einfgeschränkt)
                for v_cur in (select distinct pb.stockdate from mrp_inoutplanbase pb, zsmf_mproductbomexplode(p_productid) bom where bom.p_bomproductid=pb.m_product_id 
                            and pb.stockdate >=  v_beginproductiondate and pb.stockdate< v_estdeliverydate+ (trunc(now())-v_beginproductiondate) order by pb.stockdate)
                LOOP
                    --raise notice '%','XXXXXXXXX----'||v_cur.stockdate||'##############'||v_beginproductiondate;
                    if zssm_workhours2workcalendardayforward(v_cur.stockdate,v_hourstest,p_org ,'Y')>v_estdeliverydate then
                        v_mmv:='Y';
                        --raise notice '%','VH###'||v_estdeliverydate;
                        v_estdeliverydate:=zssm_workhours2workcalendardayforward(v_cur.stockdate,v_hourstest,p_org ,'Y');
                        --raise notice '%','NH----'||v_estdeliverydate;
                    end if;
                END LOOP;
            end if;
            if v_mmv='N' or v_beginproductiondate<trunc(now()) then
                if v_mmv!='X' then
                    -- Datum wieder auf Anfang, Strategie MAX-Zeitraum
                    v_beginproductiondate:=now()-1;
                    v_estdeliverydate:=trunc(now());
                    v_beginproductiondate:=zssm_getlatestproductionstart(p_productid,v_qty,v_estdeliverydate,p_org);
                    v_mmv:='X';
                end if;
                v_estdeliverydate:=v_estdeliverydate+ (trunc(now())-v_beginproductiondate); -- MAX-Zeitraum zw. Ziel und Beginn (Ohne zu beachten, ob Mat-Bewegungen darin liegen) - Die wurden oben geprüft...
            end if;
            --v_estdeliverydate:=v_estdeliverydate+1;
            --raise notice '%','BEG:'||v_beginproductiondate||'  -  END:'||v_estdeliverydate;
        END LOOP;
       -- v_days:=to_timestamp(now())-v_estdeliverydate;
       -- RETURN to_timestamp(now()) + v_days;
       RETURN v_estdeliverydate;
END;
$_$  LANGUAGE 'plpgsql';

select zsse_dropfunction('zssm_getfastestdeliverydate');
CREATE OR REPLACE FUNCTION zssm_getfastestdeliverydate(p_productid varchar,p_qty numeric,p_warehouse varchar,p_attrs varchar,p_org varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours


*****************************************************/

v_estdeliverydate timestamp;
v_estdeliverydateplan  timestamp;
v_count numeric;
--v_org varchar;
BEGIN
        --perform logg(p_productid||'--WH--'||p_warehouse||'--QTY--'||coalesce(p_qty,0));
        --select ad_org_id into v_org from m_warehouse where m_warehouse_id=p_warehouse;
        -- 1.st test Stock QTY
        if (select SUM(qtyonhand)-SUM(qtyoutflow) from zssi_onhanqty where m_product_id=p_productid and m_warehouse_id=p_warehouse
                   and coalesce(m_attributesetinstance_id,'0')=coalesce(p_attrs,'0')) >= p_qty 
        then
            return trunc(now());
        end if;
        -- 2. Test Planned Movements
        select min(stockdate) into v_estdeliverydateplan from mrp_inoutplanbase where m_product_id=p_productid and m_warehouse_id=p_warehouse and coalesce(m_attributesetinstance_id,'0')=coalesce(p_attrs,'0') 
               and estimated_stock_qty >= p_qty;
        -- If there is a date with desired qty, test if any transaction later requires a qty that under-runs needed qty
        if v_estdeliverydateplan is not null then
            select count(*) into v_count from mrp_inoutplanbase where m_product_id=p_productid and m_warehouse_id=p_warehouse and coalesce(m_attributesetinstance_id,'0')=coalesce(p_attrs,'0') 
                   and estimated_stock_qty < p_qty and stockdate>=v_estdeliverydate;
            if v_count!=0 then
                v_estdeliverydateplan := null;
            end if;
        end if;
        -- 3. Production?
        --if zssm_getproductionplanIDofproduct(p_productid)!='' then
        if (select production from m_product where m_product_id=p_productid)='Y' and 
            ((select count(*) from m_product_org where m_product_id=p_productid and isactive='Y')=0 or (select count(*) from m_product_org where m_product_id=p_productid and ad_org_id=p_org and isproduction='Y'  and isactive='Y')>0)  then
            v_estdeliverydate := zssm_getFastestProductionDoneDate(p_productid,p_qty,p_org);
            -- On Production, we move the Delivery-Date to the next Workdate
            v_estdeliverydate := v_estdeliverydate + zssi_NumofWorkdays2CaleandarDaysFromGivenDate(1,p_org,v_estdeliverydate);
        else
            -- OR Buy Product
            if length(mrp_getsheddeliverydate4vendorProduct(null,p_productid,p_org,null,null))>0 then
                v_estdeliverydate := to_timestamp(to_timestamp(mrp_getsheddeliverydate4vendorProduct(null,p_productid,p_org,null,null),'DD-MM-YYYY'));
            else
                -- Sets ausschliessen
                if (select count(*) from m_product where m_product_id=p_productid and issetitem='N')=1 then
                    raise exception '%', 'Kein Einkaufdatensatz vorhanden (Lagerplanung Einkauf in Ihrer Organisation geplant? / Artikel-Unterreiter Einkauf prüfen):'||(select value from m_product where m_product_id=p_productid);
                end if;
            end if;
        end if;
        -- Return the Fastest Possible Date of delivery....
        if v_estdeliverydateplan is not null and v_estdeliverydate is not null then
            if v_estdeliverydateplan < v_estdeliverydate then
                if v_estdeliverydateplan < trunc(now()) then
                    return trunc(now());
                else
                    return v_estdeliverydateplan;
                end if;
            else
                return v_estdeliverydate;
            end if;
        end if;
        return coalesce(v_estdeliverydateplan,v_estdeliverydate);
END;
$_$  LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION zssm_getfastestdeliverydate(p_orderline_id varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours


*****************************************************/

v_qty numeric;
v_product varchar;
v_warehouse varchar;
v_issotrx varchar;
v_partner varchar;
v_puom varchar;
v_uom varchar;
v_manufac varchar;
v_org varchar;
v_time varchar;
v_attrs varchar;
BEGIN
    select o.issotrx,ol.m_product_id,o.m_warehouse_id,ol.qtyordered,o.c_bpartner_id,ol.m_product_uom_id,ol.m_product_po_id,o.ad_org_id,ol.m_attributesetinstance_id
           into v_issotrx,v_product,v_warehouse,v_qty,v_partner,v_puom,v_manufac,v_org,v_attrs
           from c_order o,c_orderline ol where o.c_order_id=ol.c_order_id and ol.c_orderline_id=p_orderline_id;
    if v_puom is not null then
        select c_uom_id into v_uom from m_product_uom where m_product_uom_id=v_puom;
    end if;
    if v_issotrx='Y' then
        RETURN zssm_getfastestdeliverydate(v_product,v_qty,v_warehouse,v_attrs,v_org) ;
    else
        --raise notice '%',v_partner||'#'||v_product||'#'||v_org||'#'||v_uom||'#'||v_manufac;
        v_time:=mrp_getsheddeliverydate4vendorProduct(v_partner,v_product,v_org,v_uom,v_manufac);
        if length(v_time)>0 then
           return to_timestamp(to_timestamp(v_time,'DD-MM-YYYY')); 
        end if;       
    end if;
    return null;
END;
$_$  LANGUAGE 'plpgsql';



select zsse_dropfunction('zssm_getlatestproductionstart');
CREATE OR REPLACE FUNCTION zssm_getlatestproductionstart(p_productid varchar,p_qty numeric,deliverydate timestamp,p_org varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours

DO NOT USE IF YOU ARE NOT SHURE THAT A CORRECT PRODUCT, That has a valid Production Plan is Supplied

*****************************************************/


v_cur record;
v_hours numeric:=-1;
v_hourstest numeric:=0;
v_wh varchar;
v_startdate timestamp;
v_qty numeric;
BEGIN
    perform zsse_droptable ('calcu');
    create temporary table calcu(
    leadtime  numeric  not null
    )  ON COMMIT DROP;
    --truncate table calcu;
    -- Test as if today delivery
    select  p_movementqtyOut into v_qty from zssm_getrequiredqty(p_productid,p_qty,p_org);
    v_hourstest:=zssm_getassemblyproductionworkhours(deliverydate,p_productid,v_qty,p_org,'Y');
    --raise notice '%','Hours:'||v_hourstest;
     v_startdate:=zssm_workhours2workcalendardaybackward(deliverydate,v_hourstest,p_org,'Y');
    RETURN v_startdate;
END;
$_$  LANGUAGE 'plpgsql';

select zsse_dropfunction('zssm_getquickestproductionstart');
CREATE OR REPLACE FUNCTION zssm_getquickestproductionstart(p_productid varchar,p_qty numeric,p_org varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours

DO NOT USE IF YOU ARE NOT SHURE THAT A CORRECT PRODUCT, That has a valid Production Plan is Supplied

*****************************************************/
v_fastestdeliverydate timestamp;
v_startdate timestamp;
v_qty numeric;
BEGIN
    if p_productid is null then 
          return null;
    end if;
   -- v_qty:=p_qty;
    select  p_movementqtyOut into v_qty from zssm_getrequiredqty(p_productid,p_qty,p_org);
    v_fastestdeliverydate:=zssm_getFastestProductionDoneDate(p_productid,v_qty,p_org);
    v_startdate:=zssm_getlatestproductionstart(p_productid,v_qty,v_fastestdeliverydate,p_org );
    RETURN v_startdate;
END;
$_$  LANGUAGE 'plpgsql';



select zsse_DropFunction('zssm_getlatestproductionstartWoRecursion');
CREATE OR REPLACE FUNCTION zssm_getlatestproductionstartWoRecursion(p_productid varchar,p_qty numeric,deliverydate timestamp,p_org varchar) RETURNS timestamp
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours

DO NOT USE IF YOU ARE NOT SHURE THAT A CORRECT PRODUCT, That has a valid Production Plan is Supplied

*****************************************************/


v_cur record;
v_hours numeric:=0;
v_hourstest numeric:=0;
v_wh varchar;
v_startdate timestamp;
v_trz numeric;
v_tst numeric;
v_qty numeric;
BEGIN
    select a.p_setuptime/60,a.p_timeperpiece/60
           into v_trz,v_tst
           from zssm_getworkstepandwarehouse(p_productid,p_org) a;
    -- time formula (in hours)
    select  p_movementqtyOut into v_qty from zssm_getrequiredqty(p_productid,p_qty,p_org);
    v_hourstest:=(v_trz+v_qty*v_tst);
    
    v_startdate:=zssm_workhours2workcalendardaybackward(deliverydate,v_hourstest,p_org,'Y');
    
    RETURN v_startdate;
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zssm_getpruncausetext(p_orderline_id varchar,p_projecttask_id varchar) RETURNS varchar
AS $_$
DECLARE 
v_tasktext varchar:='';
v_ordertext varchar:='';
BEGIN
    if p_projecttask_id is not null then
        select case when coalesce(triggerreason,'')!='' then coalesce(triggerreason,'')||'-'||coalesce(name,'') else coalesce(triggerreason,'')||coalesce(name,'') end into v_tasktext from c_projecttask where c_projecttask_id=p_projecttask_id;
    end if;
    if p_orderline_id is not null then
        select 'Order:'||o.documentno||'-'||ol.line into v_ordertext from c_order o,c_orderline ol where o.c_order_id=ol.c_order_id and ol.c_orderline_id=p_orderline_id;
        v_tasktext:='';
    end if;
    RETURN substr(v_ordertext||v_tasktext,1,2000);
END;
$_$  LANGUAGE 'plpgsql';

select zsse_DropFunction('zssm_getprunreadonly');
CREATE OR REPLACE FUNCTION zssm_getprunreadonly(p_orderline_id varchar,p_projecttask_id varchar,p_product_id varchar) RETURNS varchar
AS $_$
DECLARE 
v_tasktext varchar:='';
v_prod varchar;
BEGIN
    select zssm_getpruncausetext(p_orderline_id,p_projecttask_id) into v_tasktext;
    --raise notice '%',v_tasktext;
    --select m_product_id into v_prod from c_orderline where c_orderline_id=p_orderline_id;
    --if v_prod is null then
    --         select m_product_id into v_prod from c_projecttask where c_projecttask_id=p_projecttask_id;
    --end if;
    --raise notice '%',v_prod;
    if (select count(*) from c_projecttask where  iscomplete='N' and istaskcancelled='N' and m_product_id=p_product_id and triggerreason like '%'||v_tasktext||'%')>0  then
        return 'Y';
    else
       return 'N';
    end if;
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zssm_updateproductionrequired()
  RETURNS void AS
$BODY$ 
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
Part of Projects, 
Updates Projects, Tasks with actual 
Costs and Schedule Status
Direct call variant (overloaded)
*****************************************************/
BEGIN
    -- Call the Proc
    delete from  zssm_productionrequireddates;
    insert into zssm_productionrequireddates select v.zssm_productionrequired_v_id, 
           zssm_getlatestproductionstart(v.m_product_id,v.movementqty,v.needbydate,v.ad_org_id) as dependentstartdate
    from zssm_productionrequired_v v;
    RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION zssm_updateproductionrequired(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
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
Part of Projects, 
Updates Projects, Tasks with actual 
Costs and Schedule Status
Direct call variant (overloaded)
*****************************************************/
v_message character varying:='OK';
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Call the Proc
    PERFORM zssm_updateproductionrequired();
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

SELECT zsse_droptrigger('zssm_manualproduction_trg', 'zssm_manualproduction');

CREATE OR REPLACE FUNCTION zssm_manualproduction_trg() RETURNS trigger AS
$body$
 DECLARE 
 v_production numeric;
 v_qty numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
    new.planneddate:=zssm_getFastestProductionDoneDate(new.m_product_id,new.qty,new.ad_org_id);
    ---new.lateststartdate:=zssm_getquickestproductionstart(new.m_product_id,new.qty,new.ad_org_id);
    new.lateststartdate:=zssm_getlatestproductionstartWoRecursion(new.m_product_id,new.qty,new.planneddate,new.ad_org_id);
    
    --insert into zssm_productionrequireddates (zssm_productionrequired_v_id,dependentstartdate) 
    --values (new.zssm_manualproduction_id,zssm_getlatestproductionstart(new.m_product_id,new.qty,new.planneddate,new.ad_org_id));
  if (select count(*) from zssm_unproducableitems_v where m_product_id=new.m_product_id)>0 then 
    raise exception '%','Unproducable Item, View unproduzierbare Güter prüfen';
  end if;
  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END ;
$body$
LANGUAGE 'plpgsql';


CREATE TRIGGER zssm_manualproduction_trg
  BEFORE INSERT
  ON zssm_manualproduction FOR EACH ROW
  EXECUTE PROCEDURE zssm_manualproduction_trg();
  
  
SELECT zsse_droptrigger('zssm_productionrun_trg', 'zssm_productionrun');

CREATE OR REPLACE FUNCTION zssm_productionrun_trg() RETURNS trigger AS
$body$
 DECLARE 
 v_production numeric;
 v_qty numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  if new.cause='Manual Entry' or new.cause='Manueller Eintrag' then
    new.cause:=new.cause||'-'||AD_Sequence_Doc('DocumentNo_M_Production', null, 'Y') ;
  end if;
  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END ;
$body$
LANGUAGE 'plpgsql';


CREATE TRIGGER zssm_productionrun_trg
  BEFORE INSERT
  ON zssm_productionrun FOR EACH ROW
  EXECUTE PROCEDURE zssm_productionrun_trg();



select zsse_DropFunction('zssm_DoesProductHaveValidPlanRecursive');  
CREATE or replace FUNCTION zssm_DoesProductHaveValidPlanRecursive(pzssm_productionplan_v_id OUT character varying,pcause OUT varchar,pm_product_id OUT varchar) returns SETOF RECORD
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
*****************************************************/
v_cur record;
v_count numeric;
BEGIN
    for v_cur in (select null as zssm_unproducableitems_v_id,'Product has no valid Plan' as cause,p.m_product_id
                       from m_product p where p.production='Y' and p.isactive='Y' and 
                       not exists (select 0 from zssm_productionplan_task_v tv,c_project pr where pr.c_project_id=tv.zssm_productionplan_v_id
                        and tv.m_product_id=p.m_product_id and tv.assembly='Y' and tv.isactive='Y' 
                        and pr.isactive='Y' and pr.projectstatus='OR' and pr.projectcategory = 'PRP'))
    loop
        pzssm_productionplan_v_id:=v_cur.zssm_unproducableitems_v_id;
        pcause:=v_cur.cause;
        pm_product_id:=v_cur.m_product_id;
        RETURN NEXT;
    end loop;
    for v_cur in (select tv.m_product_id,tv.timeperpiece+tv.setuptime as timeplanned,tv.zssm_productionplan_v_id, tv.issuing_locator as ptil,tv.receiving_locator as ptrl
                         from zssm_productionplan_task_v tv where
                         tv.issuing_locator is null or tv.receiving_locator is null or tv.timeperpiece+tv.setuptime =0)
    loop
         pzssm_productionplan_v_id:=v_cur.zssm_productionplan_v_id;
         pm_product_id:=v_cur.m_product_id;
        if v_cur.ptil is null or v_cur.ptrl is null then
            pcause:='Workstep has no locator defined';
        end if;
        if v_cur.timeplanned=0 then
            pcause:='Workstep does not have a production time defined';
        end if;
        RETURN NEXT;
    end loop;
    for v_cur in (select tv.m_product_id,bom.m_product_id,tv.zssm_productionplan_v_id,p.value||'-'||p.name as prod
                         from zssm_productionplan_task_v tv,zspm_projecttaskbom bom,m_product p  where
                         tv.c_projecttask_id=bom.c_projecttask_id and p.m_product_id=bom.m_product_id and 
                         (p.isactive='N' or (p.production='N' and p.ispurchased='N')))
    loop
       --  Artikel wird in diesem Plan mit produziert. Solche Artikel brauchen keinen eigenen P-Plan und können i.d.R auch nicht eingekauft werden.
      if (select count(*) from c_projecttask where assembly='Y' and m_product_id=v_cur.m_product_id and 
            c_projecttask_id in (select c_projecttask_id from zssm_productionplan_task_v where zssm_productionplan_v_id=v_cur.zssm_productionplan_v_id))=0
      then
         pzssm_productionplan_v_id:=v_cur.zssm_productionplan_v_id;
         pm_product_id:=v_cur.m_product_id;
         pcause:='Product not active or has no Purchasing or Production Data'||v_cur.prod;
        RETURN NEXT;
      end if;
    end loop;
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  

select zsse_DropFunction ('zssm_getrequiredqty');
CREATE OR REPLACE FUNCTION zssm_getrequiredqty(p_productid IN varchar,p_movementqtyIn IN numeric,p_org in varchar,p_movementqtyOut OUT numeric,p_lotetxt OUT VARCHAR)  RETURNS  RECORD
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2015.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours


*****************************************************/
v_workstepid varchar;
v_multi varchar;
v_mini numeric;

BEGIN
    
    select p_mimimumqty,p_multipleofmimimumqty into v_mini,v_multi from zssm_getworkstepandwarehouse(p_productid,p_org);
    --
    p_lotetxt:='';
    p_movementqtyOut:=p_movementqtyIn;
    if coalesce(v_mini,0)>0 then
       if  v_multi ='N' then
          if v_mini>p_movementqtyIn then
            p_movementqtyOut:=v_mini;
            p_lotetxt:=' Los:'||v_mini;
          else
            p_movementqtyOut:=p_movementqtyIn;
          end if;
       else
          p_movementqtyOut := CEIL(p_movementqtyIn/v_mini)*v_mini;
          p_lotetxt:=' Los:'||p_movementqtyOut||'/'||v_mini;
       end if;
    end if;
    RETURN ;
END;
$_$  LANGUAGE 'plpgsql';

  
   
select zsse_DropView ('zssm_unproducableitems_v');
CREATE OR REPLACE VIEW zssm_unproducableitems_v AS
SELECT
  p.ad_org_id,
  p.ad_client_id,
  p.updated,
  p.updatedby,
  p.created,
  p.createdby,
  'Y'::character as isactive,
  p.m_product_id as zssm_unproducableitems_v_id,
  p.m_product_id,
  vx.pzssm_productionplan_v_id  as zssm_productionplan_v_id,
  vx.pcause as cause
FROM m_product p,zssm_DoesProductHaveValidPlanRecursive() vx where vx.pm_product_id=p.m_product_id;





-- Not Avoidable cross-script dependency to mrp.sql. AND Serialproduction.sql
-- mrp_inoutplan_v_id is in MRP.sql
-- After Running MRP.sql or serialproduction.sql this Script has to be run!
select zsse_DropView ('zssm_productionrequired_v');
CREATE OR REPLACE VIEW zssm_productionrequired_v AS
SELECT a.ad_org_id,a.ad_client_id,a.updated,a.updatedby,a.created,a.createdby,'Y'::text as isactive,
       a.zssm_productionrequired_v_id,a.m_product_id,a.value, a.pname,a.needbydate,a.lateststartdate,t.dependentstartdate,
       (select p_lotetxt from zssm_getrequiredqty(a.m_product_id,a.movementqty,a.ad_org_id))::varchar(60) as  lottext,
       a.requiredqty,
       a.cause ,a.currOnhandQty,
       (select p_movementqtyOut from zssm_getrequiredqty(a.m_product_id,a.movementqty,a.ad_org_id))::numeric as movementqty,
       a.causetext,a.readonly,a.m_attributesetinstance_id
FROM
(SELECT
  v.ad_org_id,
  v.ad_client_id,
  v.updated,
  v.updatedby,
  v.created,
  v.createdby,
  v.zssm_manualproduction_id as zssm_productionrequired_v_id,
  v.m_product_id,
  p.value,
  m_bom_qty_onhand(v.m_product_id, v.m_warehouse_id,null,v.m_attributesetinstance_id) as currOnhandQty,
  v.qty as movementqty,
  p.value||'-'||zssi_getproductname(v.m_product_id,'de_DE') as pname,
  v.planneddate as needbydate,
  v.lateststartdate,
  v.qty as requiredqty,
  'MANUAL' as cause ,
  'MANUAL' as causetext,
  'N' as readonly,
  v.m_attributesetinstance_id
FROM zssm_manualproduction v
     , m_product p 
where p.m_product_id=v.m_product_id and p.isactive='Y' and p.production='Y' 
      and not exists (select 0 from zssm_unproducableitems_v where m_product_id=p.m_product_id)
UNION
SELECT
  v.ad_org_id,
  v.ad_client_id,
  v.updated,
  v.updatedby,
  v.created,
  v.createdby,
  v.mrp_inoutplan_v_id as zssm_productionrequired_v_id,
  v.m_product_id,
  p.value,
  m_bom_qty_onhand(v.m_product_id, v.m_warehouse_id,null,v.m_attributesetinstance_id) as currOnhandQty,
  v.movementqty*(-1) as movementqty,
  p.value||'-'||zssi_getproductname(v.m_product_id,'de_DE') as pname,
  v.planneddate as needbydate,
  zssm_getlatestproductionstartWoRecursion(v.m_product_id,v.movementqty*(-1),v.planneddate,v.ad_org_id) as lateststartdate,
  v.estimated_stock_qty*(-1)  as requiredqty,
  zssi_getorderlinelink(v.c_orderline_id)||zssi_getptasklink(v.c_projecttask_id) as cause ,
  zssm_getpruncausetext(v.c_orderline_id,v.c_projecttask_id) as causetext,
  zssm_getprunreadonly(v.c_orderline_id,v.c_projecttask_id,v.m_product_id) as readonly,
  v.m_attributesetinstance_id
FROM mrp_inoutplan_v v, m_product p 
where p.m_product_id=v.m_product_id and p.isactive='Y' and p.production='Y' and v.estimated_stock_qty<0 and v.documenttype not in ('PROD','FRAMESO')
      --and zssm_getproductionplanIDofproduct(p.m_product_id)=pr.c_project_id and pr.isautotriggered='N'
      and (not exists (select 0 from m_product_org og where og.m_product_id=p.m_product_id  and og.isactive='Y') or exists (select 0 from m_product_org ogg where ogg.m_product_id=p.m_product_id and ogg.ad_org_id=v.ad_org_id and ogg.isproduction='Y' and ogg.isactive='Y' ))
      and not exists (select 0 from zssm_unproducableitems_v where m_product_id=p.m_product_id)
UNION
SELECT
  po.ad_org_id,
  po.ad_client_id,
  po.updated,
  po.updatedby,
  po.created,
  po.createdby,
  po.M_PRODUCT_ORG_id as zssm_productionrequired_v_id,
  po.m_product_id,
  p.value,
  m_bom_qty_onhand(po.m_product_id, ml.m_warehouse_id,null,po.m_attributesetinstance_id) as currOnhandQty,
  m_bom_qty_onhand(po.m_product_id, ml.m_warehouse_id,null,po.m_attributesetinstance_id)*(-1)+coalesce(po.qtyoptimal,coalesce(po.STOCKMIN,0)) as movementqty,
  p.value||'-'||zssi_getproductname(po.m_product_id,'de_DE') as pname,
  zssm_getFastestProductionDoneDate(po.m_product_id,m_bom_qty_onhand(po.m_product_id, null, po.m_locator_id)*(-1)+coalesce(po.qtyoptimal,coalesce(po.STOCKMIN,0)),po.ad_org_id) as needbydate,
  zssm_getlatestproductionstartWoRecursion(po.m_product_id,m_bom_qty_onhand(po.m_product_id, null, po.m_locator_id)*(-1)+coalesce(po.qtyoptimal,coalesce(po.STOCKMIN,0)),
                                zssm_getFastestProductionDoneDate(po.m_product_id,m_bom_qty_onhand(po.m_product_id, null, po.m_locator_id)*(-1)+coalesce(po.qtyoptimal,coalesce(po.STOCKMIN,0)),po.ad_org_id),po.ad_org_id) as lateststartdate,
  --m_bom_qty_onhand(po.m_product_id, null, po.m_locator_id)*(-1)+coalesce(po.qtyoptimal,coalesce(po.qtyoptimal,coalesce(po.STOCKMIN,0))) as requiredqty,
  null as  requiredqty,
  'STOCKMIN'  as cause ,
  'STOCKMIN'  as causetext ,
  'N' as readonly,
  po.m_attributesetinstance_id
FROM M_PRODUCT_ORG po ,m_product p,m_locator ml
                      where p.m_product_id=po.m_product_id and po.m_locator_id=ml.m_locator_id
                      and coalesce((select max(coalesce(v.estimated_stock_qty,0)) from mrp_inoutplan_v v where v.m_product_id=po.m_product_id and coalesce(v.m_attributesetinstance_id,'0')=coalesce(po.m_attributesetinstance_id,'0')  
                                                         and v.m_warehouse_id=(select m_warehouse_id from m_locator where m_locator_id=po.m_locator_id)),-99999999999)
                      <coalesce(po.qtyoptimal,coalesce(po.STOCKMIN,0)) 
                      --and not exists (select 0 from mrp_inoutplan_v v where v.m_product_id=po.m_product_id and v.estimated_stock_qty>=m_bom_qty_onhand(po.m_product_id, null, po.m_locator_id)*(-1)+coalesce(po.qtyoptimal,coalesce(po.STOCKMIN,0))) 
                      and not exists (select 0 from zssm_unproducableitems_v where m_product_id=p.m_product_id)
                      and po.isproduction='Y'  and po.isactive='Y'
                      and m_bom_qty_onhand(po.m_product_id, null, po.m_locator_id,po.m_attributesetinstance_id)-coalesce(po.STOCKMIN,0)<0
                      and p.isactive='Y' and p.production='Y') A 
left join zssm_productionrequireddates t on t.zssm_productionrequired_v_id=a.zssm_productionrequired_v_id;
                     

-- User Exit to c_order_post1
CREATE or replace FUNCTION zssm_productionrun_userexit(p_project_id varchar) RETURNS varchar
AS $_$
DECLARE
  BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';


select zsse_DropFunction ('zssm_productionrun');
CREATE OR REPLACE FUNCTION zssm_productionrun(p_pinstance_id character varying) RETURNS varchar AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Overload for Process Scheduler

*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='';
v_Org   character varying;
v_ProductionPlan_id varchar;
v_ProductionOrder_id    VARCHAR; 
v_sequence VARCHAR;
v_ProductionOrderValue VARCHAR;
v_ProductionOrderName VARCHAR;
v_isauto varchar;
v_startdate timestamp;
v_enddate timestamp;
v_hoursinrecursion numeric:=0;
v_cur RECORD;
v_cause varchar;
v_locator varchar;
v_reclocator varchar;
v_reclocator2 varchar;
v_type varchar;
v_cur2 RECORD;
BEGIN
    if p_pinstance_id is null then
        return 'COMPILE';
    end if;
    --raise notice '%',  'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC##################################################################CALLL!';
    select createdby,ad_org_id into v_user,v_org from zssm_productionrun where pinstance=p_pinstance_id and requiredqty>0 and c_project_id is null limit 1;
    for v_cur in (select * from zssm_productionrun where c_project_id is null and pinstance=p_pinstance_id and requiredqty>0 and c_project_id is null)
    LOOP
         --raise notice '%',  '##################################################################BEGINRUN';
         -- Start Date
         v_startdate:=v_cur.needbydate;
         v_enddate:=v_cur.enddate;
         --zssm_getlatestproductionstart(v_cur.m_product_id,v_cur.requiredqty,v_cur.needbydate);
         -- Select PLAN to execute
         v_ProductionOrder_id := get_uuid();
         v_ProductionPlan_id:=v_cur.productionplan_id;
         -- Create Name and Value Automatically 
         v_sequence:= Ad_Sequence_Doc('DocumentNo_C_Project', v_org,'Y');
         select value,name into v_ProductionOrderValue,v_ProductionOrderName from  c_project where c_project_id=v_ProductionPlan_id;
         v_ProductionOrderValue:=substr(v_ProductionOrderValue,1,40-length(v_sequence))||v_sequence;
         -- Create Production ORDER
         v_message := v_message || (SELECT zssm_Copy_ProductionPlan2Project (v_ProductionPlan_id, v_ProductionOrder_id, v_ProductionOrderValue, v_ProductionOrderName, v_startdate,v_cur.requiredqty, v_User, v_cur.m_product_id)); -- 
         --raise notice '%',  'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXENDCOPY';
         perform zssm_calcBOMAttributions(v_ProductionOrder_id,v_cur.m_product_id,v_cur.m_attributesetinstance_id);
         v_message := v_message || '</br>' || zsse_htmldirectlink('../org.openbravo.zsoft.serprod.ProductionOrder/ProductionOrderCF6D6BC0255A47DFBD4FF6F8BEBA0C71_Relation.html','zssmProductionorderVId',v_ProductionOrder_id,v_ProductionOrderName)|| '</br>';
         update zssm_productionrun set c_project_id= v_ProductionOrder_id where zssm_productionrun_id=v_cur.zssm_productionrun_id;
         update c_projecttask set triggerreason=v_cur.cause where c_project_id= v_ProductionOrder_id;
         v_cause:=v_cur.cause;
         select m_locator_id,typeofproduct into v_reclocator,v_type from m_product where m_product_id=v_cur.m_product_id;
         -- if configured, set the Locators from Product Data, not from Base-Workstep
         -- Bildet Verkettungen bei automatischer Auslösung.
         -- Der Entnahme-Lagerort einer Baugruppe in der BOM ist der Rückgabe(Produktions-Lagerort) einer Aufgabe die zuvor produziert wurde
         -- Die Lagerorte für Entnahme/Rückgabe im Kopf UND in der BOM berechnen sich vollständig aus den Artikel-Daten (Lagerort)
         if c_getconfigoption('productionlocatorfromproductdata',v_cur.ad_org_id)='Y' and v_reclocator is not null then
            update c_projecttask set receiving_locator = v_reclocator, issuing_locator = v_reclocator where c_project_id= v_ProductionOrder_id and m_product_id=v_cur.m_product_id;
            for v_cur2 in (select * from  zspm_projecttaskbom where c_projecttask_id in (select c_projecttask_id from c_projecttask where c_project_id= v_ProductionOrder_id 
                           and m_product_id=v_cur.m_product_id))
            LOOP
                select m_locator_id,typeofproduct into v_reclocator2,v_type from m_product where m_product_id=v_cur2.m_product_id;
                update zspm_projecttaskbom set receiving_locator = case when v_type='ST' then v_reclocator2 else v_reclocator end, 
                       issuing_locator = case when v_type='ST' then v_reclocator2 else v_reclocator end 
                       --issuing_locator =  coalesce(v_cur.issuing_locator,v_reclocator)
                       where zspm_projecttaskbom_id=v_cur2.zspm_projecttaskbom_id;
            END LOOP;
            -- Update Worksteps issuing-locator with receiving-locator value from the last product.
            update c_projecttask set issuing_locator=coalesce(v_cur.issuing_locator,v_reclocator) where c_project_id= v_ProductionOrder_id;
            -- Select the receiving locator of current product in order to Update the following products issuing locator.
            --select min(receiving_locator) into v_locator from c_projecttask where c_project_id= v_ProductionOrder_id  and m_product_id=v_cur.m_product_id;
         end if;
         -- Die Lagerorte reiner BOM-Positionen berechnen sich aus den Artikeldaten.
         -- Bei zusammengesetzten Produktionsplänen berechnen sie sich bei im Plan produzierten BG aus den vorangegangenen AG
         if c_getconfigoption('Bomlocatorfromproductdata',v_cur.ad_org_id)='Y' then
            for v_cur2 in (select * from  zspm_projecttaskbom where c_projecttask_id in (select c_projecttask_id from c_projecttask where c_project_id= v_ProductionOrder_id))
            LOOP
                select m_locator_id,typeofproduct into v_reclocator2,v_type from m_product where m_product_id=v_cur2.m_product_id;
                if (select count(*) from c_projecttask where assembly='Y' and m_product_id=v_cur2.m_product_id and c_project_id= v_ProductionOrder_id)=0 then 
                     -- In diesem Plan benötigtes Material (ST.-Art und BG, die nicht im Plan produziert werden) werden am Lagerort des Artikels entnommen und zurückgegeben.
                    update zspm_projecttaskbom set receiving_locator = v_reclocator2,  
                       issuing_locator =  v_reclocator2 
                       where zspm_projecttaskbom_id=v_cur2.zspm_projecttaskbom_id;
                else  -- In diesem Plan produzierte Baugruppen werden bei MAT-Rückgabe da zurückgegeben, wo diese herkommen. Dazu dient der Entnahme Lagerort der aktuellen Aufgabe
                    select receiving_locator into v_reclocator2 from c_projecttask where c_projecttask_id=v_cur2.c_projecttask_id;
                    update zspm_projecttaskbom set   
                       issuing_locator =  v_reclocator2,receiving_locator=v_reclocator2
                     where zspm_projecttaskbom_id=v_cur2.zspm_projecttaskbom_id;  
                end if;
            END LOOP;
         end if;
         if c_getconfigoption('BomIssuinglocatorIdentical2workstep',v_cur.ad_org_id)='Y' then
                -- Set All BOM-Psitions issuing-locator to issuing-locator of the Task
                update zspm_projecttaskbom set issuing_locator =coalesce(v_cur.issuing_locator,v_reclocator)  where c_projecttask_id in (select c_projecttask_id from c_projecttask where c_project_id= v_ProductionOrder_id 
                            and m_product_id=v_cur.m_product_id);
         end if;
         update c_projecttask set startdate=null where startdate<v_startdate and c_project_id= v_ProductionOrder_id;
         update c_projecttask set enddate=null where  enddate>v_enddate and c_project_id= v_ProductionOrder_id;
         update c_project set datefinish=v_enddate, startdate=v_startdate,description=substr(v_cur.cause||coalesce(description,''),1,2000) where c_project_id= v_ProductionOrder_id;
         update c_projecttask set startdate=v_startdate where startdate is null and c_project_id= v_ProductionOrder_id;
         update c_projecttask set enddate=v_enddate where  enddate is null and c_project_id= v_ProductionOrder_id;
         if v_startdate=v_enddate then 
                 select round(sum((timeplanned+setuptime)/60),0)+coalesce(v_cur.hoursinrecursion,0)  into v_hoursinrecursion from c_projecttask where c_project_id= v_ProductionOrder_id;
         end if;        
         --PERFORM zspm_beginproject(v_ProductionOrder_id); 
         update c_project set projectstatus='OR' where c_project_id=v_ProductionOrder_id;
         --raise notice '%',  'UPDDDDDDDDDDDDDDDDDDDDDDDDDDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXENDCOPY';
         perform mrp_inoutplanupdate('FORCE');     
         --raise notice '%',  'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFENDRUN';
         v_message:=v_message|| zssm_productionrun_userexit(v_ProductionOrder_id);  
    END LOOP;
    
    -- Iterate for auto-triggered Production Orders
    for v_cur in (select  v.c_projecttask_id,v.m_product_id, (select p_movementqtyOut from zssm_getrequiredqty(v.m_product_id,v.estimated_stock_qty*(-1),v.ad_org_id))::numeric   as requiredqty,v.planneddate as needbydate,
                  zssm_getpruncausetext(v.c_orderline_id,v.c_projecttask_id) as causetext
                  FROM mrp_inoutplan_v v , m_product p 
                  where p.m_product_id=v.m_product_id and p.isactive='Y' and p.production='Y' and v.estimated_stock_qty<0 and v.c_projecttask_id is not null
                  and not exists (select 0 from  zssm_productionrun where pinstance=p_pinstance_id and m_product_id=v.m_product_id)
                  and exists(select 0 from zssm_productionplan_task_v tv,c_project p 
                       where p.c_project_id=tv.zssm_productionplan_v_id
                        and tv.m_product_id=v.m_product_id and tv.assembly='Y' and tv.isactive='Y' and p.isautotriggered='Y'
                        and p.isactive='Y' and p.projectstatus='OR' and p.projectcategory = 'PRP')
                  order by length(zssm_getpruncausetext(v.c_orderline_id,v.c_projecttask_id)) desc
                  )
    LOOP 
            ---select isautotriggered into v_isauto from c_project where c_project_id=zssm_getproductionplanIDofproduct(v_cur.m_product_id); 
            --raise notice '%',  '################'||(select value from m_product where m_product_id=v_cur.m_product_id)||'#'||v_isauto||'#CT#'||v_cur.causetext||'#CC#'||v_cause;
            --if v_isauto='Y'  and (v_cur.causetext like v_cause||'%' or  v_cause  like  v_cur.causetext||'%') then
            if (v_cur.causetext like v_cause||'%' or  v_cause  like  v_cur.causetext||'%') then
                -- Select the receiving locator of current (demanding) product in order to Update the following products issuing locator.
                select receiving_locator into v_locator from c_projecttask where c_projecttask_id=v_cur.c_projecttask_id;
                v_startdate:=zssm_getlatestproductionstartWoRecursion(v_cur.m_product_id,v_cur.requiredqty,v_cur.needbydate,v_org);
                if v_cur.needbydate=v_startdate and v_hoursinrecursion>0  then
                        v_startdate:=zssm_workhours2workcalendardaybackward(v_startdate,v_hoursinrecursion,v_org,'Y');
                end if;
                if v_cur.needbydate!=v_startdate then
                         v_hoursinrecursion:=0;  
                end if;  
                select zssm_productionplan_v_id into v_ProductionPlan_id from zssm_getproductionplanofproduct(v_cur.m_product_id,v_Org) limit 1;
                insert into zssm_productionrun(zssm_productionrun_id,ad_client_id,ad_org_id,createdby, updatedby,
                            requiredqty,needbydate,m_product_id, isautotriggered,pinstance,cause,enddate,hoursinrecursion,issuing_locator,productionplan_id)
                    VALUES (get_uuid(),'C726FEC915A54A0995C568555DA5BB3C',v_Org,v_user,v_user,
                            v_cur.requiredqty,v_startdate,v_cur.m_product_id,'Y',p_pinstance_id,v_cur.CAUSETEXT,v_cur.needbydate, v_hoursinrecursion,v_locator,v_ProductionPlan_id);
                --PERFORM  zssm_productionrun(p_pinstance_id);  
                EXIT;
            end if;
    END LOOP;
    --perform mrp_inoutplanupdate('FORCE');
    RETURN v_Message;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
  
select zsse_DropFunction ('zssm_calcBOMAttributions');
CREATE OR REPLACE FUNCTION zssm_calcBOMAttributions(p_porder_id varchar,p_product_id varchar,p_attrsetinstance_id varchar) RETURNS void AS
$BODY$ 
DECLARE 
    v_line numeric;
    v_cur record;
    v_cur2 record;
    v_i numeric;
    v_attributeset varchar;
    v_value varchar;
    v_locator varchar;
    v_prdval varchar;
    v_attrbinst varchar;
    v_task               c_projecttask%ROWTYPE;
BEGIN
    if p_product_id is null then 
        return;
    end if;
    select * into v_task from c_projecttask where c_project_id=p_porder_id and assembly='Y' and m_product_id=p_product_id limit 1;
    update c_projecttask set m_attributesetinstance_id=p_attrsetinstance_id where c_projecttask_id=v_task.c_projecttask_id;
    update c_project set note=note||coalesce(chr(10)||(select description from m_attributesetinstance where m_attributesetinstance_id=p_attrsetinstance_id),'') where c_project_id=p_porder_id;
    select m_attributeset_id into v_attributeset from m_attributesetinstance where m_attributesetinstance_id=p_attrsetinstance_id;
    v_i:=1;
    for v_cur in (select m_attribute_id  from m_attributeuse where m_attributeset_id=v_attributeset order by seqno)
    LOOP
        select  m_attributevalue_id into v_value from m_attributevalue where m_attribute_id=v_cur.m_attribute_id and name=m_attributesetgetInstanceValue(p_attrsetinstance_id,v_i);
        v_i:=v_i+1;
        for v_cur2 in (select * from m_attributevaluebom where m_attributevalue_id=v_value)
        LOOP
            select m_locator_id into v_locator from m_product_org where m_product_id=v_cur2.m_product_id and ad_org_id=v_task.ad_org_id and (isvendorreceiptlocator='Y' or isproduction='Y') and isactive='Y';
            if v_locator is null then
                select m_locator_id into v_locator from m_product where m_product_id=v_cur2.m_product_id;
            end if;
            if (select count(*) from zspm_projecttaskbom where c_projecttask_id=v_task.c_projecttask_id and line=v_cur2.line)>0 then
                if v_cur2.m_product_id is not null  and v_cur2.quantity>0 then
                    update zspm_projecttaskbom set m_product_id=v_cur2.m_product_id,quantity=v_task.qty*v_cur2.quantity,description=v_cur2.description , issuing_locator=v_locator,receiving_locator=v_locator
                           where c_projecttask_id=v_task.c_projecttask_id and line=v_cur2.line;
                else
                    delete from  zspm_projecttaskbom where c_projecttask_id=v_task.c_projecttask_id and line=v_cur2.line;
                end if;
            else
                if v_cur2.m_product_id is not null and v_cur2.quantity>0 then
                    insert into zspm_projecttaskbom( zspm_projecttaskbom_id, c_projecttask_id, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, quantity, description,date_plan, line,
                                issuing_locator,receiving_locator)
                    values (get_uuid(),v_task.c_projecttask_id,v_task.ad_client_id, v_task.ad_org_id, v_task.createdby, v_task.updatedby,
                            v_cur2.m_product_id,v_cur2.quantity*v_task.qty,v_cur2.description,v_task.startdate,v_cur2.line,v_locator,v_locator);
                end if;
            end if;
        END LOOP;
    END LOOP;
    -- AG mit Dyn. Stückliste
    -- Dyn. Stücklistenteile werden dem AG über Namensgleichheit zugewiesen
    for v_cur in (select * from c_projecttask where c_project_id=p_porder_id)
    LOOP
        -- Dyn. Durchreichen (Erste Pos. Stkl. ist zu produzierendes Gut) 
        if v_cur.assembly='N' then
            select m_product_id,m_attributesetinstance_id into v_prdval,v_attrbinst from c_projecttask where c_project_id=p_porder_id and seqno<v_cur.seqno and m_product_id is not null and assembly='Y' order by seqno desc limit 1;
            select count(*) into v_line from  zspm_projecttaskbom where c_projecttask_id=v_cur.c_projecttask_id and m_product_id=v_prdval;
            if v_line=0 and v_prdval is not null then
                select min(line) into v_line from zspm_projecttaskbom where c_projecttask_id=v_cur.c_projecttask_id;
                if v_line is null then v_line:=10; end if;
                v_line:=v_line-10;
                insert into zspm_projecttaskbom( zspm_projecttaskbom_id, c_projecttask_id, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, quantity, date_plan, line,
                                issuing_locator,receiving_locator,m_attributesetinstance_id,isreturnafteruse)
                    values (get_uuid(),v_cur.c_projecttask_id,v_task.ad_client_id, v_cur.ad_org_id, v_task.createdby, v_task.updatedby,
                            v_prdval,v_task.qty,v_cur.startdate,v_line,v_cur.issuing_locator,v_cur.receiving_locator,v_attrbinst,'Y');
            end if;
        end if;
        -- Weitere Positionen direkt aus der Stückliste es Artikels (Namenangabe Arbeitsgang)
        for v_cur2 in (select * from m_product_bom where m_product_id=p_product_id)
        LOOP
            if v_cur2.workstepname=v_cur.name then
                select max(line) into v_line from zspm_projecttaskbom where c_projecttask_id=v_cur.c_projecttask_id;
                v_line:=coalesce(v_line,0)+10;
                select m_locator_id into v_locator from m_product_org where m_product_id=v_cur2.m_productbom_id and ad_org_id=v_cur.ad_org_id and (isvendorreceiptlocator='Y' or isproduction='Y') and isactive='Y';
                if v_locator is null then
                    select m_locator_id into v_locator from m_product where m_product_id=v_cur2.m_productbom_id;
                end if;
                if (select count(*) from zspm_projecttaskbom where c_projecttask_id=v_cur.c_projecttask_id and m_product_id=v_cur2.m_productbom_id)>0 then
                    update zspm_projecttaskbom set quantity=quantity + v_task.qty*v_cur2.bomqty  where c_projecttask_id=v_cur.c_projecttask_id and m_product_id=v_cur2.m_productbom_id;
                else
                    insert into zspm_projecttaskbom( zspm_projecttaskbom_id, c_projecttask_id, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, quantity, date_plan, line,
                                issuing_locator,receiving_locator)
                    values (get_uuid(),v_cur.c_projecttask_id,v_task.ad_client_id, v_cur.ad_org_id, v_task.createdby, v_task.updatedby,
                            v_cur2.m_productbom_id,v_cur2.bomqty*v_task.qty,v_cur.startdate,v_line,v_locator,v_locator);
                end if;
            end if;
        END LOOP;        
    END LOOP;
END ; $BODY$ LANGUAGE 'plpgsql' VOLATILE  COST 100;
