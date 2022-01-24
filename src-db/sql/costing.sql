
 
  
CREATE OR REPLACE FUNCTION c_currency_convert(p_amount numeric, p_curfrom_id character varying, p_curto_id character varying, p_convdate timestamp without time zone) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$ DECLARE 
BEGIN
RETURN C_CURRENCY_CONVERT ($1, $2, $3, $4, 'S', 'C726FEC915A54A0995C568555DA5BB3C', '0');
END
; $_$; 
  
/*****************************************************+


Functions to Retrieve COSTS for Machines, Salarys

and Indirect Costs



*****************************************************/
CREATE or replace FUNCTION zsco_get_costcenter_cost(p_Costcenter_id character varying, p_fromdate timestamp with time zone,p_todate timestamp with time zone, p_orgid character varying) RETURNS numeric
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
Get Costcenter Costs
*****************************************************/
  v_MacctCost     NUMERIC;
  v_InvoiceCost     NUMERIC;
  BEGIN
    
    IF(p_Costcenter_id IS NULL) THEN
      RETURN 0;
    END IF;
   
    -- Select the valid Cost: Purchase Invoices, not Voided, 
    select sum(case when ad_get_docbasetype(i.c_doctype_id)='APC' then
                case when i.isgrossinvoice='Y' and t.rate>0 then round(il.linegrossamt-il.linegrossamt/(1+100/t.rate),2)*-1 else case when  i.isgrossinvoice='Y' and t.rate=0 then coalesce(il.linegrossamt,0)*-1 else  coalesce(il.linenetamt,0)*-1 end end else
                case when i.isgrossinvoice='Y' and t.rate>0 then round(il.linegrossamt-il.linegrossamt/(1+100/t.rate),2) else case when  i.isgrossinvoice='Y' and t.rate=0 then coalesce(il.linegrossamt,0) else coalesce(il.linenetamt,0) end end end) into v_InvoiceCost 
                                                   from c_invoiceline il,c_invoice i,c_tax t,a_asset a where a.a_asset_id=il.a_asset_id and t.c_tax_id=il.c_tax_id 
                                                   and i.c_invoice_id=il.c_invoice_id and i.issotrx='N' and i.docstatus in ('CO','CL') 
                                                   and case coalesce(p_orgid,'0') when '0' then 1=1 else i.ad_org_id=p_orgid end
                                                   and coalesce(p_fromdate,'-infinity'::timestamp)<=i.dateinvoiced and coalesce(p_todate,'infinity'::timestamp)>=i.dateinvoiced
                                                   and il.a_asset_id=p_Costcenter_id
                                                   and a.iscostcenter='Y'
                                                   and ad_get_docbasetype(i.c_doctype_id) in ('API','APC') ;
       
    select sum(coalesce(round(case when ml.isgross='N' or t.rate=0 then ml.amt*case when ml.isdr2cr='Y' then 1 else -1 end else 
                   case when ml.isdr2cr='Y' then 1 else -1 end * (ml.amt-ml.amt/(1+100/t.rate)) end,2),0)) into v_MacctCost 
                                                   from zsfi_macctline ml,zsfi_manualacct m,c_tax t,a_asset a  where m.zsfi_manualacct_id=ml.zsfi_manualacct_id
                                                   and ml.a_asset_id=a.a_asset_id and t.c_tax_id=ml.c_tax_id 
                                                   and ml.glstatus = 'PO' and ml.a_asset_id= p_Costcenter_id
                                                   and case coalesce(p_orgid,'0') when '0' then 1=1 else ml.ad_org_id=p_orgid end
                                                   and coalesce(p_fromdate,'-infinity'::timestamp)<=ml.acctdate and coalesce(p_todate,'infinity'::timestamp)>=ml.acctdate;
    RETURN coalesce(v_MacctCost,0)+coalesce(v_InvoiceCost,0);
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction ('zsco_get_salary_cost');
CREATE or replace FUNCTION zsco_get_salary_cost(p_Salary_Category_id varchar, p_movementdate timestamp with time zone, p_costuom varchar,p_org varchar, p_cost out numeric ,p_specialtime1 out numeric ,p_specialtime2 out numeric ,p_specialtime3 out numeric) RETURNS RECORD
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
Get Work Costs from costing table 
*****************************************************/
  v_Cost     RECORD;
  v_count numeric;
BEGIN
    
    IF(p_Salary_Category_id IS NULL) THEN
      RETURN;
    END IF;
    IF(p_MovementDate IS NULL) THEN
      RETURN;
    END IF;
    
    -- Select the valid Cost, Default is UOM Hour
    select count(*) into v_count from c_salary_category_cost where c_salary_category_id=p_Salary_Category_id  
                                 and datefrom<=p_movementdate and coalesce(p_costuom,'H')= costuom and ad_org_id= p_org ;
    if v_count > 0 then
      select coalesce(cost,0),  coalesce(special1,0),      coalesce(special2,0),coalesce(special3,0) into p_cost, p_specialtime1, p_specialtime2 ,p_specialtime3
             from c_salary_category_cost where c_salary_category_id=p_Salary_Category_id  and datefrom<=p_movementdate and coalesce(p_costuom,'H')= costuom 
                  and ad_org_id= p_org order by datefrom desc LIMIT 1;
    else
      select coalesce(cost,0),  coalesce(special1,0),      coalesce(special2,0),coalesce(special3,0) into p_cost, p_specialtime1, p_specialtime2 ,p_specialtime3
             from c_salary_category_cost where c_salary_category_id=p_Salary_Category_id  and datefrom<=p_movementdate and coalesce(p_costuom,'H')= costuom 
             and ad_org_id='0'   order by datefrom desc LIMIT 1;
    end if;
    if p_cost is null then
       p_cost:=0;
    end if;
    if p_specialtime1 is null then
       p_specialtime1:=0;
    end if;
    if p_specialtime2 is null then
       p_specialtime2:=0;
    end if;
    if p_specialtime3 is null then
       p_specialtime3:=0;
    end if;
    RETURN;
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction ('zsco_get_machine_cost');
CREATE or replace FUNCTION zsco_get_machine_cost(p_ma_machine_id character varying, p_movementdate timestamp with time zone, p_costuom character varying,p_org varchar) RETURNS numeric
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
Get Machine Costs from costing table 
*****************************************************/
  v_Cost     NUMERIC;
  v_count numeric;
  BEGIN
    
    IF(p_ma_machine_id IS NULL) THEN
      RETURN 0;
    END IF;
    IF(p_MovementDate IS NULL) THEN
      RETURN 0;
    END IF;
       select count(*) into v_count from ma_machine_cost where ma_machine_id=p_ma_machine_id  and validfrom<=p_movementdate and coalesce(p_costuom,'H')= costuom 
                                    and isactive='Y' and ad_org_id=p_org;
       if v_count > 0 then 
        -- Select the valid Cost, Default is UOM Hour
        select cost into v_Cost from ma_machine_cost where ma_machine_id=p_ma_machine_id  and validfrom<=p_movementdate and coalesce(p_costuom,'H')= costuom 
                                    and isactive='Y'  and ad_org_id=p_org order by validfrom desc LIMIT 1;
       else
        select cost into v_Cost from ma_machine_cost where ma_machine_id=p_ma_machine_id  and validfrom<=p_movementdate and coalesce(p_costuom,'H')= costuom 
                                    and isactive='Y'  and ad_org_id='0' order by validfrom desc LIMIT 1;
       end if;

    if v_Cost is null then      
        RAISE EXCEPTION '%', '@zspm_NotCostApplies@';
    end if;
    RETURN v_cost;
END;
$_$  LANGUAGE 'plpgsql';

select zsse_dropfunction ('zsco_get_indirect_cost_percent');
CREATE OR REPLACE FUNCTION zsco_get_indirect_cost_percent(p_projecttask_id character varying)
  RETURNS numeric AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* D. Heuduk 04/2016
* 
****************************************************************************************************************************************************

Calculation of indirect costs with Projecttask costs. Else 0

******************************************************************************************************************************/
v_return numeric:= 0;
v_emp numeric;
v_mac numeric;
v_mat numeric;
v_exp numeric;
v_ven numeric;
v_ind numeric;
BEGIN
   
   Select coalesce(expensesplan,0),coalesce(externalserviceplan,0),coalesce(materialcostplan,0),coalesce(servcostplan,0),coalesce(machinecostplan,0), coalesce(indirectcostplan,0) into v_exp,v_ven,v_mat,v_emp,v_mac,v_ind from  c_projecttask where c_projecttask_id=p_projecttask_id;
   if (v_emp+v_mac+v_mat+v_exp+v_ven)=0 then 
    v_return:=0;
    else
   v_return:=(v_ind)/(v_emp+v_mac+v_mat+v_exp+v_ven);
   end if;
   v_return:=round(v_return,2)*100;
   Return v_return;
   
END;  $BODY$   LANGUAGE 'plpgsql' VOLATILE  COST 100;


select zsse_dropfunction ('zsco_get_indirect_cost');

CREATE or replace FUNCTION zsco_get_indirect_cost(p_ma_indcost_id character varying, p_movementdate timestamp with time zone, p_costuom character varying,
                                                  p_projecttask_id varchar,p_planorfact varchar,p_product_id varchar,
                                                  p_empcost OUT numeric,p_matcost OUT numeric, p_machinecost out numeric,p_vendorcost out numeric, p_extservicecost out numeric) RETURNS  RECORD
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
Get Indirect Costs from costing table 
*****************************************************/
v_cost record;
v_cur record;
v_bomamt numeric;
v_expenseamt numeric;
v_extserviceamt  numeric;
v_invoicecost numeric;
v_glcost numeric;
v_taskdate timestamp;
v_curr varchar;
  BEGIN
    select coalesce(coalesce(pt.startdate,p.startdate),trunc(now()))  into v_taskdate from c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id and pt.c_projecttask_id=p_projecttask_id;
    select a.c_currency_id into v_curr from ad_org_acctschema oa,c_acctschema a,c_project p,c_projecttask pt where oa.c_acctschema_id=a.c_acctschema_id 
    and oa.ad_org_id=p.ad_org_id and p.c_project_id=pt.c_project_id and pt.c_projecttask_id=p_projecttask_id;
    for v_cost in ( select cv.ma_indirect_cost_value_id,coalesce(cv.empcost,0) as a,coalesce(cv.machinecost,0) as b,coalesce(cv.materialcost,0) as c,coalesce(cv.vendorcost,0) as d,coalesce(cv.extservicecost,0) as e
                    from ma_indirect_cost_value cv,ma_indirect_cost c where c.ma_indirect_cost_id=cv.ma_indirect_cost_id and
                    c.isactive='Y' and c.cost_type='S' and c.ma_indirect_cost_id=p_ma_indcost_id  
                    and cv.datefrom<=v_taskdate and coalesce(p_costuom,'H')= cv.cost_uom and cv.isactive='Y'
                    order by  cv.datefrom desc LIMIT 1)
    LOOP
        if coalesce(p_planorfact,'Ä')='plan' and coalesce(p_costuom,'H')='P' and p_projecttask_id is not null then
            select sum(plannedamt)*v_cost.c/100 into v_bomamt from zspm_projecttaskbom where c_projecttask_id=p_projecttask_id  and isactive='Y'
                   and not exists (select 0 from ma_indirect_cost_value_product where  ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id and m_product_id=zspm_projecttaskbom.m_product_id);                 
            for v_cur in (select pv.cost,sum(bom.plannedamt) as plannedamt,pv.m_product_id from ma_indirect_cost_value_product pv,zspm_projecttaskbom bom 
                          where bom.c_projecttask_id=p_projecttask_id and pv.m_product_id=bom.m_product_id and pv.ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id
                          group by pv.m_product_id,pv.cost)
            LOOP
                if p_product_id is null then 
                    v_bomamt:=coalesce(v_bomamt,0)+v_cur.plannedamt*v_cur.cost/100;
                else
                    if v_cur.m_product_id=p_product_id then
                        p_vendorcost:=coalesce(p_vendorcost,0)+round(coalesce(v_cur.plannedamt,0)*v_cur.cost/100,2);
                        RETURN;
                    end if;
                end if;
            END LOOP;
            select sum(case when coalesce(pc.isexternalservice,'N')='N' then plannedamt else 0 end)*v_cost.d/100,
                   sum(case when coalesce(pc.isexternalservice,'N')='Y' then plannedamt else 0 end)*v_cost.e/100
                   into v_expenseamt,v_extserviceamt 
                   from C_projecttaskexpenseplan ep left join m_product p on p.m_product_id=ep.m_product_id
                                                    left join m_product_category pc on pc.m_product_category_id=p.m_product_category_id
                   where ep.c_projecttask_id=p_projecttask_id  and ep.isactive='Y'
                   and not exists (select 0 from ma_indirect_cost_value_product where  ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id and m_product_id=ep.m_product_id);
            --Einzelartikel immer   v_expenseamt      (Keine Berücksichigung von Fremdleistung)
            for v_cur in (select pv.cost,sum(ex.plannedamt) as plannedamt,pv.m_product_id from ma_indirect_cost_value_product pv,C_projecttaskexpenseplan ex
                          where ex.c_projecttask_id=p_projecttask_id and pv.m_product_id=ex.m_product_id and pv.ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id
                          group by pv.m_product_id,pv.cost)
            LOOP
                if p_product_id is null then 
                    v_expenseamt:=coalesce( v_expenseamt,0)+v_cur.plannedamt*v_cur.cost/100;
                else
                    if v_cur.m_product_id=p_product_id then
                        p_vendorcost:=round(coalesce(v_cur.plannedamt,0)*v_cur.cost/100,2);
                        RETURN;
                    end if;
                end if;
            END LOOP;
            v_extserviceamt:=coalesce(v_extserviceamt,0);
            v_expenseamt:=coalesce( v_expenseamt,0);
            v_bomamt:=coalesce(v_bomamt,0);
        end if;
        if coalesce(p_planorfact,'Ä')='fact' and coalesce(p_costuom,'H')='P' and p_projecttask_id is not null then
            select sum(case when coalesce(pc.isexternalservice,'N')='N' then (case when ad_get_docbasetype(c_invoice.c_doctype_id)='APC' then 
                                case when c_invoice.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)-c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)/(1+100/t.rate),2)*-1 else case when isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct),0)*-1 else coalesce(c_currency_convert(linenetamt,c_currency_id,v_curr,dateacct),0)*-1 end end else 
                                case when c_invoice.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)-c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)/(1+100/t.rate),2) else case when isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct),0) else coalesce(c_currency_convert(linenetamt,c_currency_id,v_curr,dateacct),0) end end end)*v_cost.d/100 else 0 end) ,
                   sum(case when coalesce(pc.isexternalservice,'N')='Y' then (case when ad_get_docbasetype(c_invoice.c_doctype_id)='APC' then 
                                case when c_invoice.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)-c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)/(1+100/t.rate),2)*-1 else case when isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct),0)*-1 else coalesce(c_currency_convert(linenetamt,c_currency_id,v_curr,dateacct),0)*-1 end end else 
                                case when c_invoice.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)-c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)/(1+100/t.rate),2) else case when isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct),0) else coalesce(c_currency_convert(linenetamt,c_currency_id,v_curr,dateacct),0) end end end)*v_cost.e/100 else 0 end)  
                                into v_invoicecost,v_extserviceamt
                                from c_invoice ,c_invoiceline
                                left join m_product on c_invoiceline.m_product_id=m_product.m_product_id 
                                left join m_product_category pc on m_product.m_product_category_id=pc.m_product_category_id ,c_tax t
                                where c_invoice.c_invoice_id=c_invoiceline.c_invoice_id and   c_invoiceline.c_projecttask_id=p_projecttask_id and  t.c_tax_id=c_invoiceline.c_tax_id and
                                case  coalesce(c_invoiceline.m_product_id,'') when '' then 1=1 else (m_product.producttype='S' or (m_product.producttype='I' and m_product.isstocked='N')) end 
                                and c_invoice.docstatus = 'CO' and c_invoice.issotrx='N' and ad_get_docbasetype(c_invoice.c_doctype_id) in ('API','APC')
                                and not exists (select 0 from ma_indirect_cost_value_product where  ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id and m_product_id=c_invoiceline.m_product_id);   
                                
            -- Manual Accounting      Keine Berücksichigung von Fremdleistung               
            select coalesce(sum(round(case when ml.isgross='N' or t.rate=0 then ml.amt*case when ml.isdr2cr='Y' then 1 else -1 end else case when ml.isdr2cr='Y' then 1 else -1 end * ml.amt-ml.amt/(1+100/t.rate) end,2)),0)
                                                                                                     into v_glcost from zsfi_macctline ml, zsfi_manualacct mic,c_tax t 
                                                                                                     where  ml.c_projecttask_id=p_projecttask_id and
                                                                                                     t.c_tax_id=ml.c_tax_id and
                                                                                                     mic.zsfi_manualacct_id=ml.zsfi_manualacct_id and 
                                                                                                     mic.glstatus='PO';                     
             --Einzelartikel immer   v_invoicecost   (Keine Berücksichigung von Fremdleistung)
            for v_cur in (select pv.cost,pv.m_product_id,
                                 sum(case when ad_get_docbasetype(c_invoice.c_doctype_id)='APC' then 
                                 case when c_invoice.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)-c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)/(1+100/t.rate),2)*-1 else case when isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct),0)*-1 else coalesce(c_currency_convert(linenetamt,c_currency_id,v_curr,dateacct),0)*-1 end end else 
                                 case when c_invoice.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)-c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct)/(1+100/t.rate),2) else case when isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,c_currency_id,v_curr,dateacct),0) else coalesce(c_currency_convert(linenetamt,c_currency_id,v_curr,dateacct),0) end end end)
                                 as invcost
                                 from c_invoice ,c_invoiceline
                                 left join m_product on c_invoiceline.m_product_id=m_product.m_product_id ,
                                 ma_indirect_cost_value_product pv,c_tax t
                                where c_invoice.c_invoice_id=c_invoiceline.c_invoice_id and   c_invoiceline.c_projecttask_id=p_projecttask_id and  t.c_tax_id=c_invoiceline.c_tax_id and
                                case  coalesce(c_invoiceline.m_product_id,'') when '' then 1=1 else (m_product.producttype='S' or (m_product.producttype='I' and m_product.isstocked='N')) end 
                                and c_invoice.docstatus = 'CO' and c_invoice.issotrx='N' and ad_get_docbasetype(c_invoice.c_doctype_id) in ('API','APC')
                                and c_invoiceline.m_product_id=pv.m_product_id and pv.ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id
                                group by pv.m_product_id,pv.cost)
            LOOP
                if p_product_id is null then 
                    v_invoicecost:=coalesce(v_invoicecost,0)+v_cur.invcost*v_cur.cost/100;
                else
                    if v_cur.m_product_id=p_product_id then
                        p_vendorcost:=round(coalesce(v_cur.invcost,0)*v_cur.cost/100,2);
                        RETURN;
                    end if;
                end if;
            END LOOP;
            select sum(coalesce(actualcosamount,0))*v_cost.c/100 into v_bomamt from zspm_projecttaskbom where c_projecttask_id=p_projecttask_id
                   and not exists (select 0 from ma_indirect_cost_value_product where  ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id and m_product_id=zspm_projecttaskbom.m_product_id);
            for v_cur in (select pv.m_product_id,pv.cost,sum(coalesce(bom.actualcosamount,0)) as actualcosamount from ma_indirect_cost_value_product pv,zspm_projecttaskbom bom 
                          where bom.c_projecttask_id=p_projecttask_id and pv.m_product_id=bom.m_product_id and pv.ma_indirect_cost_value_id=v_cost.ma_indirect_cost_value_id
                          group by pv.m_product_id,pv.cost)
            LOOP
                if p_product_id is null then 
                    v_bomamt:=coalesce(v_bomamt,0)+v_cur.actualcosamount*v_cur.cost/100;
                else
                    if v_cur.m_product_id=p_product_id then
                        p_vendorcost:=round(coalesce(v_cur.actualcosamount,0)*v_cur.cost/100,2);
                        RETURN;
                    end if;
                end if;
            END LOOP;
            v_invoicecost:=coalesce(v_invoicecost,0);
            v_extserviceamt:=coalesce(v_extserviceamt,0);
            v_glcost:=coalesce(v_glcost*v_cost.d/100,0);
            v_expenseamt:=v_glcost+v_invoicecost;
            v_bomamt:=coalesce(v_bomamt,0);
        end if;              
        if p_product_id is null or p_product_id='NOPRODUCTS' then
            p_empcost:=v_cost.a;
            p_matcost:=round(v_bomamt,2);
            p_machinecost:=v_cost.b;
            p_vendorcost:=round(v_expenseamt,2);
            p_extservicecost:=round(v_extserviceamt,2);
            RETURN;
        end if;
    END LOOP;
    p_empcost:=0;
    p_matcost:=0;
    p_machinecost:=0;
    p_vendorcost:=0;
    RETURN;
END;
$_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION zsco_get_indirect_costPercentFromPlan(p_projecttask_id character varying, p_type varchar) RETURNS  numeric
AS $_$
DECLARE
v_cur record;
v_return numeric:=0;
v_taskdate timestamp;
v_percent numeric;
BEGIN
/* PARAMS WILL BE 
HR FOR EMPLOYEES
MA FOR MACHINES/EQUIPMENT
EX FOR EXPENSES

OUT PARAM WILL BE 1.00
*/
select coalesce(coalesce(pt.startdate,p.startdate),trunc(now()))  into v_taskdate from c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id 
                and pt.c_projecttask_id=p_projecttask_id;
for v_cur in (select ma_indirect_cost_id from zspm_ptaskindcostplan where c_projecttask_id=p_projecttask_id)
            loop
                select case when p_type='HR' then cv.empcost 
                            when p_type='MA' then cv.machinecost
                            when p_type='EX' then cv.vendorcost
                            when p_type='MAT' then cv.materialcost else 0 end into v_percent from ma_indirect_cost_value cv, ma_indirect_cost c where cv.ma_indirect_cost_id=c.ma_indirect_cost_id
                       and c.ma_indirect_cost_id=v_cur.ma_indirect_cost_id and cv.datefrom<=v_taskdate and cv.cost_uom='P' and cv.isactive='Y'
                       and c.isactive='Y' and c.cost_type in ('M','S') order by datefrom desc LIMIT 1;
                if coalesce(v_percent,0)>0 then
                    v_percent:=(v_percent/100)+1;
                    v_return:=v_return+v_percent;
                end if;
            end loop;
return v_return;
END;
$_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION zsco_prod_offerpricestdplist(p_org_id character varying, p_bpartner character varying, p_product character varying,p_qty character varying) RETURNS character varying
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
Get From Standard Sales Pricelist the Offer Price for a specific Product, Partner and QTY
ONLY SALES!
*****************************************************/
  v_plvid   character varying;
  v_pl   character varying;
  v_price numeric;
  BEGIN
   select M_PRICELIST_ID into v_pl from c_bpartner where c_bpartner_id=p_bpartner;
   SELECT M_PRICELIST_VERSION_ID  INTO v_plvid  FROM M_PRICELIST_VERSION
          WHERE M_PRICELIST_ID=v_pl and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=v_pl and VALIDFROM<=TO_DATE(NOW())); 
   -- Default, if none found
   if v_pl is null then
        SELECT M_PRICELIST_VERSION_ID  INTO v_plvid  FROM M_PRICELIST_VERSION
                WHERE M_PRICELIST_ID IN    (SELECT M_PRICELIST_ID    FROM M_PRICELIST    WHERE ISDEFAULT = 'Y'  AND AD_ORG_ID in ('0', p_org_id) and issopricelist='Y' AND ISACTIVE = 'Y')
                AND VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   
                                          WHERE M_PRICELIST_ID IN   (SELECT M_PRICELIST_ID    FROM M_PRICELIST    WHERE ISDEFAULT = 'Y'  AND AD_ORG_ID in ('0', p_org_id) and issopricelist='Y' AND ISACTIVE = 'Y')
                                          AND VALIDFROM <= TO_DATE(NOW()) 
                                  );
        select  M_PRICELIST_ID into v_pl from M_PRICELIST_VERSION where M_PRICELIST_VERSION_ID=v_plvid;
   end if;
   -- Get actual Price
   v_price:=m_get_offers_price(to_date(now()),p_bpartner,p_product,null,to_number(p_qty),v_pl);
   RETURN to_char(coalesce(v_price,0));
END;
$_$  LANGUAGE 'plpgsql';



-- DROP FUNCTION m_get_offers_price(timestamp without time zone, character varying, character varying, numeric, numeric, character varying);
select zsse_dropfunction('m_get_offers_price');
CREATE OR REPLACE FUNCTION m_get_offers_price(p_date timestamp without time zone, p_bpartner_id character varying, p_product_id character varying, p_pricestd numeric, p_qty numeric, p_pricelist character varying)
  RETURNS numeric AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/*
 
        
p_pricestd is irrelevant.
Overloaded Function
******************************************************************************************************************************/
BEGIN
   return m_get_offers_price(p_date , p_bpartner_id , p_product_id ,  p_qty , p_pricelist);
END;  $BODY$   LANGUAGE 'plpgsql' VOLATILE  COST 100;

CREATE OR REPLACE FUNCTION m_get_offers_price(p_date timestamp without time zone, p_bpartner_id character varying, p_product_id character varying, p_qty numeric, p_pricelist character varying)
  RETURNS numeric AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************

Overloaded Function

Normal Call in all Purchase/Sales Actions-

Implementation of m_get_offers_price was extended with direct Fetch of PO-Purchase - Price for calculation Sales-Price

******************************************************************************************************************************/
BEGIN
   return m_get_offers_price(p_date , p_bpartner_id , p_product_id ,  p_qty , p_pricelist,'N',null);
END;  $BODY$   LANGUAGE 'plpgsql' VOLATILE  COST 100;

CREATE OR REPLACE FUNCTION m_get_offers_price(p_date timestamp without time zone, p_bpartner_id character varying, p_product_id character varying, p_qty numeric, p_pricelist character varying, p_directpurchasecalc  character varying,p_poprice numeric)
  RETURNS numeric AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************

Overloaded Function

Implementation of m_get_offers_price was extended with gross purchase prices for direct Fetch of PO-Purchase - Price for calculation Sales-Price

Implementation of Attributes was extended - S. Zimmermann, 07/2016

******************************************************************************************************************************/
BEGIN
   return m_get_offers_price(p_date , p_bpartner_id , p_product_id ,  p_qty , p_pricelist, p_directpurchasecalc, p_poprice, 'N', null);
END;  $BODY$   LANGUAGE 'plpgsql' VOLATILE  COST 100;

CREATE OR REPLACE FUNCTION m_get_offers_price(p_date timestamp without time zone, p_bpartner_id character varying, p_product_id character varying, p_qty numeric, p_pricelist character varying, p_directpurchasecalc  character varying, p_poprice numeric, p_isgrossprice character varying, p_tax_id character varying)
  RETURNS numeric AS
$BODY$ 
BEGIN
    return  m_get_offers_price(p_date , p_bpartner_id , p_product_id , p_qty , p_pricelist , p_directpurchasecalc , p_poprice , p_isgrossprice , p_tax_id,null,null);
END ; 
$BODY$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION m_get_offers_price(p_date timestamp without time zone, p_bpartner_id character varying, p_product_id character varying, p_qty numeric, p_pricelist character varying, p_directpurchasecalc  character varying, p_poprice numeric, p_isgrossprice character varying, p_tax_id character varying, p_uom_id varchar,p_MProductPOID varchar)
  RETURNS numeric AS
$BODY$ 
BEGIN
    return  m_get_offers_price(p_date , p_bpartner_id , p_product_id , p_qty , p_pricelist , p_directpurchasecalc , p_poprice , p_isgrossprice , p_tax_id,p_uom_id,p_MProductPOID,null);
END ; 
$BODY$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION m_get_offers_price(p_date timestamp without time zone, p_bpartner_id character varying, p_product_id character varying, p_qty numeric, p_pricelist character varying, p_directpurchasecalc  character varying, p_poprice numeric, p_isgrossprice character varying, p_tax_id character varying, p_uom_id varchar,p_MProductPOID varchar,p_attributesetinstance_id varchar)
  RETURNS numeric AS
$BODY$ 
BEGIN
    return  m_get_offers_price(p_date , p_bpartner_id , p_product_id , p_qty , p_pricelist , p_directpurchasecalc , p_poprice , p_isgrossprice , p_tax_id,p_uom_id,p_MProductPOID,p_attributesetinstance_id,null);
END ; 
$BODY$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION m_get_offers_price(p_date timestamp without time zone, p_bpartner_id character varying, p_product_id character varying, p_qty numeric, p_pricelist character varying, p_directpurchasecalc  character varying, p_poprice numeric, p_isgrossprice character varying, p_tax_id character varying, p_uom_id varchar,p_MProductPOID varchar,p_attributesetinstance_id varchar,p_orgid varchar)
  RETURNS numeric AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/*
 Contributions: Purchasing: Get from m_product_po - Get the Proce from the Vendor provided first-Then take this 
         price and go through offers table
         Implementation of m_get_offers_price was extended with direct Fetch of PO-Purchase - Price for calculation Sales-Price
         In this case p_pricelist is useless and  p_poprice is used direct for calculation.
         In all other cases p_pricelist (ID of Pricelist or Version) is Mandantory and p_poprice is not used.
 
******************************************************************************************************************************/
    v_Price NUMERIC;
    Cur_Offer RECORD;
    v_issoPL   character varying:='N';
    v_currency character varying;
    v_plvid  character varying;
    v_plist  character varying;
    v_orgid  character varying;
    v_cutomproduct varchar;
    v_taxincl varchar;
    v_customplv varchar;
    v_purcur varchar;
  BEGIN
    
    if coalesce(p_directpurchasecalc,'N')='N' then
            -- Get the Relevant Sales-Pricelist-Standard-Price or PO-Standard-Price for normal Calculation
            -- First check if Paranmeter p_pricelist is the Pricelist-Version
            SELECT M_PRICELIST_VERSION_ID,M_PRICELIST_ID into v_plvid,v_plist from M_PRICELIST_VERSION where M_PRICELIST_VERSION_ID=p_pricelist;
            if v_plvid is null then
            -- p_pricelist is the  Pricelist itself - Select the relevant Version
                SELECT M_PRICELIST_VERSION_ID,M_PRICELIST_ID  INTO v_plvid,v_plist  FROM M_PRICELIST_VERSION
                        WHERE M_PRICELIST_ID=p_pricelist and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=p_pricelist and VALIDFROM<=TO_DATE(coalesce(p_date,now()))); 
            END if;
            if p_orgid is null then 
                select ad_org_id into v_orgid from m_pricelist where m_pricelist_id=v_plist;
            else
                v_orgid:=p_orgid;
            end if;
            SELECT issopricelist,c_currency_id,istaxincluded into v_issoPL,v_currency , v_taxincl from m_pricelist where m_pricelist_id=v_plist;
            -- Select Sales Price or Purchase Price
            if v_issoPL='Y' then
                -- Determin if this is an Offer of Customer Specific Products - In This case the Pricelist of the offer will be used.
                select iscustomerpricelist into v_cutomproduct from c_bpartner where c_bpartner_id=p_bpartner_id;
                if v_cutomproduct='Y' then
                    -- Gett the correct Price List , if applicable
                    select pv.M_PRICELIST_VERSION_id into v_customplv from m_productprice pp,m_pricelist_version pv ,m_pricelist p,m_offer_pricelist op,m_offer_bpartner bp,m_offer o
                                        where pp.m_pricelist_version_id = pv.m_pricelist_version_id 
                                        and p.m_pricelist_id=pv.m_pricelist_id
                                        and pp.m_product_id=p_product_id
                                        and op.m_pricelist_id=pv.m_pricelist_id
                                        and op.m_offer_id=o.m_offer_id
                                        and bp.m_offer_id=o.m_offer_id
                                        and bp.c_bpartner_id=p_bpartner_id
                                        and o.issalesoffer='Y'
                                        and p.c_currency_id=v_currency
                                        and p.istaxincluded=v_taxincl
                                        and p.issopricelist='Y'
                                        and pv.m_pricelist_id=op.m_pricelist_id 
                                        and  pv.VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=p.m_pricelist_id and VALIDFROM<=TO_DATE(now()))
                                        LIMIT 1;
                    if v_customplv is not null then
                        v_plvid:=v_customplv;
                        select m_pricelist_id into v_plist from m_pricelist_version where m_pricelist_version_id=v_plvid;
                    end if;
                end if;
                --RAISE NOTICE '%',p_product_id||'#'|| v_plvid||'#'||coalesce(p_uom_id,'uom');
                v_Price := m_bom_pricestd(p_product_id, v_plvid,p_uom_id,null);
            else
               v_Price := m_bom_pricestd(p_product_id, v_plvid,p_uom_id,p_MProductPOID,p_bpartner_id);
            end if;
    ELSIF coalesce(p_directpurchasecalc,'N')='Y' then
		IF p_isgrossprice = 'N'  THEN
		    -- Take Supplied PO-Purchase - Price for calculation of Sales-Price directly
			v_Price :=  coalesce(p_poprice,0);
		ELSE
			-- Take net PO-Price directly, calculate net price for further recharge, rounding errors unavoidable
			v_Price := coalesce(p_poprice,0) / ((select rate from c_tax where c_tax_id = p_tax_id)/100 + 1);
		END IF;
		v_issoPL := 'Y';
    END IF;
    --RAISE NOTICE '%',v_issoPL||'Cursor: '||coalesce(v_plist,'np')||'-'||coalesce(p_directpurchasecalc,'N')||'-'||coalesce(p_BPartner_ID,'NB')||'-'||coalesce(p_Product_ID,'NPP')||'#'||coalesce(p_uom_ID,'NUOM')||'-'||coalesce(p_MProductPOID,'NMMM')||coalesce(v_Price,0);
    if v_Price is null or v_Price=0 then 
           v_Price := 0;
          -- RETURN v_Price;
    end if;
    FOR Cur_Offer IN
      (SELECT M_OFFER_ID,PRIORITY,directpurchasecalc
      FROM M_OFFER
      WHERE trunc(p_Date) BETWEEN DATEFROM AND COALESCE(DATETO, TO_DATE('31-12-9999', 'DD-MM-YYYY'))
        AND IsActive = 'Y'
        AND issalesoffer = v_issoPL
        AND ad_org_id in ('0',v_orgid)
        AND case when coalesce (p_directpurchasecalc,'N')='Y' then directpurchasecalc = coalesce (p_directpurchasecalc,'N') else 1=1 end
        AND (p_Qty >= COALESCE(Qty_From,0) OR Qty_From IS NULL)
        AND (p_Qty <= COALESCE(Qty_To,0) OR Qty_To IS NULL)
        AND ((PRICELIST_SELECTION='Y' AND NOT EXISTS (SELECT 1 FROM M_OFFER_PRICELIST
           WHERE M_OFFER_ID=M_OFFER.M_OFFER_ID
           AND M_PRICELIST_ID = v_plist))
            OR (PRICELIST_SELECTION='N' AND EXISTS(SELECT 1 FROM M_OFFER_PRICELIST
                WHERE M_OFFER_ID = M_OFFER.M_OFFER_ID
                AND M_PRICELIST_ID = v_plist)))
        AND((BPARTNER_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM M_OFFER_BPARTNER
        WHERE M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND C_BPARTNER_ID = p_BPartner_ID
        ))
        OR(BPARTNER_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM M_OFFER_BPARTNER
        WHERE M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND C_BPARTNER_ID = p_BPartner_ID
        )))
        AND((BP_GROUP_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM C_BPARTNER B,
          M_OFFER_BP_GROUP OB
        WHERE OB.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND B.C_BPARTNER_ID = p_BPartner_ID
          AND OB.C_BP_GROUP_ID = B.C_BP_GROUP_ID
        ))
        OR(BP_GROUP_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM C_BPARTNER B,
          M_OFFER_BP_GROUP OB
        WHERE OB.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND B.C_BPARTNER_ID = p_BPartner_ID
          AND OB.C_BP_GROUP_ID = B.C_BP_GROUP_ID
        )))
        AND((PRODUCT_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM M_OFFER_PRODUCT p
        WHERE p.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND case when p_uom_id is not null then p_uom_id=p.c_uom_id else p.c_uom_id is null end
          AND case when p_MProductPOID is not null then p_MProductPOID=p.m_product_po_id else p.m_product_po_id is null end
          AND (p.m_attributesetinstance_id is null or ((select count(*) from m_attributeinstance a,m_attributeinstance b where 
                                                     a.m_attributesetinstance_id=p.m_attributesetinstance_id and 
                                                     b.m_attributesetinstance_id=p_attributesetinstance_id and
                                                     a.m_attribute_id=b.m_attribute_id and
                                                     a.value is not null and
                                                     case when p.graterequal='Y' then to_number(b.value)>=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='Y' then to_number(b.value)<=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='N' and p.graterequal='N' then b.value=a.value else 1=1 end) =
                                                     (select count(*) from m_attributeinstance a where a.m_attributesetinstance_id=p.m_attributesetinstance_id and a.value is not null)
                                                     ))                                         
          AND p.M_PRODUCT_ID = p_Product_ID
        ))
        OR(PRODUCT_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM M_OFFER_PRODUCT p
        WHERE p.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND case when p_uom_id is not null then p_uom_id=p.c_uom_id else p.c_uom_id is null end
          AND case when p_MProductPOID is not null then p_MProductPOID=p.m_product_po_id else p.m_product_po_id is null end
          AND (p.m_attributesetinstance_id is null or ((select count(*) from m_attributeinstance a,m_attributeinstance b where 
                                                     a.m_attributesetinstance_id=p.m_attributesetinstance_id and 
                                                     b.m_attributesetinstance_id=p_attributesetinstance_id and
                                                     a.m_attribute_id=b.m_attribute_id and
                                                     a.value is not null and
                                                     case when p.graterequal='Y' then to_number(b.value)>=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='Y' then to_number(b.value)<=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='N' and p.graterequal='N' then b.value=a.value else 1=1 end) =
                                                     (select count(*) from m_attributeinstance a where a.m_attributesetinstance_id=p.m_attributesetinstance_id and a.value is not null)
                                                     ))                                         
          AND p.M_PRODUCT_ID = p_Product_ID
        )))
        AND((PROD_CAT_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM M_PRODUCT P,
          M_OFFER_PROD_CAT OP
        WHERE OP.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND P.M_PRODUCT_ID = p_Product_ID
          AND OP.M_PRODUCT_CATEGORY_ID = P.M_PRODUCT_CATEGORY_ID
        ))
        OR(PROD_CAT_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM M_PRODUCT P,
          M_OFFER_PROD_CAT OP
        WHERE OP.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND P.M_PRODUCT_ID = p_Product_ID
          AND OP.M_PRODUCT_CATEGORY_ID = P.M_PRODUCT_CATEGORY_ID
        )))
      ORDER BY PRIORITY desc
      )
    LOOP
      RAISE NOTICE '%','Offer: '||coalesce(v_Price,0)||'-'||Cur_Offer.M_Offer_ID||'-'||coalesce(p_uom_id,'uom');
      if Cur_Offer.directpurchasecalc='Y' and coalesce(p_directpurchasecalc,'N')='N' and p_poprice is null and p_tax_id is null then
        select pricepo,c_currency_id,ad_org_id into v_Price,v_purcur  from m_product_po po where m_product_id=p_Product_ID  and PO.iscurrentvendor='Y' and case when v_orgid!='0' then PO.AD_ORG_ID in ('0',v_orgid) else 1=1 end
                  and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null end 
                  and case when p_MProductPOID is not null then po.m_product_po_id=p_MProductPOID  else 1=1  end 
                 order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
        if v_purcur is null then 
            select c_currency_id into v_purcur from ad_org_acctschema,c_acctschema where ad_org_acctschema.c_acctschema_id=c_acctschema.c_acctschema_id and case when v_orgid!='0' then ad_org_acctschema.ad_org_id=v_orgid else 1=1 end limit 1;
        end if;    
        v_Price := Round(C_Currency_Convert(v_Price, v_purcur, v_currency, trunc(now())),2);   
      end if;
      v_Price := M_Get_Offer_Price(Cur_Offer.M_Offer_ID, v_Price) ;
      if coalesce(Cur_Offer.PRIORITY,0)<100 then
        exit;
      end if;
    END LOOP;
    RETURN v_Price;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN v_Price;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_orderline_trg2() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
    /*************************************************************************
    * The contents of this file are subject to the Openbravo  Public  License
    * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
    * Version 1.1  with a permitted attribution clause; you may not  use this
    * file except in compliance with the License. You  may  obtain  a copy of
    * the License at http://www.openbravo.com/legal/license.html
    * Software distributed under the License  is  distributed  on  an "AS IS"
    * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
    * License for the specific  language  governing  rights  and  limitations
    * under the License.
    * The Original Code is Openbravo ERP.
    * The Initial Developer of the Original Code is Openbravo SL
    * All portions are Copyright (C) 2001-2006 Openbravo SL
    * All Rights Reserved.
    * Contributor(s):  ______________________________________.
    ************************************************************************/

   --TYPE RECORD IS REFCURSOR;
   Cur_Offer RECORD;

  v_OrderLine_Offer_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_lineno NUMERIC:=0;
  v_Price NUMERIC;
  v_PriceNew NUMERIC;
  v_Amt NUMERIC;
  v_BPartner_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Order_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Insert BOOLEAN :=FALSE;
  v_Precision NUMERIC;
  v_PriceList_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_dordered timestamp without time zone;
   v_uom varchar; 
   v_issoPL varchar;
   v_purcur varchar;
   v_currency character varying;
   v_orgid varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;



 IF TG_OP = 'UPDATE' THEN
  IF ((NEW.DateOrdered != OLD.DateOrdered)
     OR (COALESCE(NEW.PriceActual,0) != COALESCE(OLD.PriceActual,0))
     OR (COALESCE(NEW.PriceList,0) != COALESCE(OLD.PriceList,0))
     OR (COALESCE(NEW.M_Product_ID,'0') != COALESCE(OLD.M_Product_ID,'0'))
     OR (COALESCE(NEW.M_attributesetinstance_ID,'0') != COALESCE(OLD.M_attributesetinstance_ID,'0'))
  OR (COALESCE(NEW.QtyOrdered,0) != COALESCE(OLD.QtyOrdered,0)))
 THEN
  DELETE FROM C_ORDERLINE_OFFER
  WHERE C_OrderLine_ID = NEW.C_OrderLine_ID;
   v_Insert := TRUE;
 END IF;
 END IF;

 IF TG_OP = 'INSERT' OR v_Insert THEN
   SELECT C_BPartner_ID, PricePrecision, M_PriceList_ID,dateordered,issotrx,c.C_Currency_ID,o.ad_org_id
     INTO v_BPartner_ID, v_Precision, v_PriceList_ID,v_dordered,v_issoPL,v_currency,v_orgid
     FROM C_ORDER o,
          C_CURRENCY c
    WHERE C_Order_ID = NEW.C_Order_ID
      AND o.C_Currency_ID = c.C_Currency_ID;
   select c_uom_id into v_uom from m_product_uom where m_product_uom_id=new.m_product_uom_id;
  --Get the new "std" price from the Actual price (if actual price is the std price they will be equal)
  
   if v_issoPL='Y' then
       v_Price := m_bom_pricestd(new.m_product_id, v_PriceList_ID, v_uom, null);
   else
        v_Price := m_bom_pricestd(new.m_product_id, v_PriceList_ID, v_uom, new.m_product_po_id,v_BPartner_ID);
   end if;
   if v_Price is null then 
           v_Price := 0;
   end if;
--   :new.PriceStd := v_Price;


   FOR Cur_Offer IN (SELECT M_OFFER_ID,PRIORITY,directpurchasecalc
      FROM M_OFFER
      WHERE trunc(v_dordered) BETWEEN DATEFROM AND COALESCE(DATETO, TO_DATE('31-12-9999', 'DD-MM-YYYY'))
        AND IsActive = 'Y'
        AND issalesoffer =  (SELECT issopricelist from m_pricelist where m_pricelist_id=v_PriceList_ID)
        AND ad_org_id in ('0',new.ad_org_id)
        AND (coalesce(new.quantityorder,new.qtyordered) >= COALESCE(Qty_From,0) OR Qty_From IS NULL)
        AND (coalesce(new.quantityorder,new.qtyordered) <= COALESCE(Qty_To,0) OR Qty_To IS NULL)
        AND ((PRICELIST_SELECTION='Y' AND NOT EXISTS (SELECT 1 FROM M_OFFER_PRICELIST
           WHERE M_OFFER_ID=M_OFFER.M_OFFER_ID
           AND M_PRICELIST_ID = v_PriceList_ID))
            OR (PRICELIST_SELECTION='N' AND EXISTS(SELECT 1 FROM M_OFFER_PRICELIST
                WHERE M_OFFER_ID = M_OFFER.M_OFFER_ID
                AND M_PRICELIST_ID = v_PriceList_ID)))
        AND((BPARTNER_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM M_OFFER_BPARTNER
        WHERE M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND C_BPARTNER_ID = v_BPartner_ID
        ))
        OR(BPARTNER_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM M_OFFER_BPARTNER
        WHERE M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND C_BPARTNER_ID = v_BPartner_ID
        )))
        AND((BP_GROUP_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM C_BPARTNER B,
          M_OFFER_BP_GROUP OB
        WHERE OB.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND B.C_BPARTNER_ID = v_BPartner_ID
          AND OB.C_BP_GROUP_ID = B.C_BP_GROUP_ID
        ))
        OR(BP_GROUP_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM C_BPARTNER B,
          M_OFFER_BP_GROUP OB
        WHERE OB.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND B.C_BPARTNER_ID = v_BPartner_ID
          AND OB.C_BP_GROUP_ID = B.C_BP_GROUP_ID
        )))
        AND((PRODUCT_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM M_OFFER_PRODUCT p
        WHERE p.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND case when v_uom is not null then v_uom=p.c_uom_id else p.c_uom_id is null end
          AND case when new.m_product_po_id is not null then new.m_product_po_id=p.m_product_po_id else p.m_product_po_id is null end
          AND (p.m_attributesetinstance_id is null or ((select count(*) from m_attributeinstance a,m_attributeinstance b where 
                                                     a.m_attributesetinstance_id=p.m_attributesetinstance_id and 
                                                     b.m_attributesetinstance_id=new.m_attributesetinstance_id and
                                                     a.m_attribute_id=b.m_attribute_id and
                                                     a.value is not null and
                                                     case when p.graterequal='Y' then to_number(b.value)>=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='Y' then to_number(b.value)<=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='N' and p.graterequal='N' then b.value=a.value else 1=1 end) =
                                                     (select count(*) from m_attributeinstance a where a.m_attributesetinstance_id=p.m_attributesetinstance_id and a.value is not null)
                                                     ))                                         
          AND p.M_PRODUCT_ID = new.m_Product_ID
        ))
        OR(PRODUCT_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM M_OFFER_PRODUCT p
        WHERE p.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND case when v_uom is not null then v_uom=p.c_uom_id else p.c_uom_id is null end
          AND case when new.m_product_po_id is not null then new.m_product_po_id=p.m_product_po_id else p.m_product_po_id is null end
          AND (p.m_attributesetinstance_id is null or ((select count(*) from m_attributeinstance a,m_attributeinstance b where 
                                                     a.m_attributesetinstance_id=p.m_attributesetinstance_id and 
                                                     b.m_attributesetinstance_id=new.m_attributesetinstance_id and
                                                     a.m_attribute_id=b.m_attribute_id and
                                                     a.value is not null and
                                                     case when p.graterequal='Y' then to_number(b.value)>=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='Y' then to_number(b.value)<=to_number(a.value) else 1=1 end and
                                                     case when p.lessequal='N' and p.graterequal='N' then b.value=a.value else 1=1 end) =
                                                     (select count(*) from m_attributeinstance a where a.m_attributesetinstance_id=p.m_attributesetinstance_id and a.value is not null)
                                                     ))                                         
          AND p.M_PRODUCT_ID = new.m_Product_ID
        )))
        AND((PROD_CAT_SELECTION = 'Y'
        AND NOT EXISTS
        (SELECT 1
        FROM M_PRODUCT P,
          M_OFFER_PROD_CAT OP
        WHERE OP.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND P.M_PRODUCT_ID = new.m_Product_ID
          AND OP.M_PRODUCT_CATEGORY_ID = P.M_PRODUCT_CATEGORY_ID
        ))
        OR(PROD_CAT_SELECTION = 'N'
        AND EXISTS
        (SELECT 1
        FROM M_PRODUCT P,
          M_OFFER_PROD_CAT OP
        WHERE OP.M_OFFER_ID = M_OFFER.M_OFFER_ID
          AND P.M_PRODUCT_ID = new.m_Product_ID
          AND OP.M_PRODUCT_CATEGORY_ID = P.M_PRODUCT_CATEGORY_ID
        )))
      ORDER BY PRIORITY desc) 
   LOOP
        SELECT * INTO  v_OrderLine_Offer_ID FROM Ad_Sequence_Next('C_OrderLine_Offer', NEW.AD_Client_ID);
        v_lineno := v_lineno + 10;
        if Cur_Offer.directpurchasecalc='Y'  then
            select pricepo,c_currency_id,ad_org_id into v_Price,v_purcur  from m_product_po po where m_product_id=new.m_Product_ID  and PO.iscurrentvendor='Y' and case when v_orgid!='0' then PO.AD_ORG_ID in ('0',v_orgid) else 1=1 end
                  and case when v_uom is not null then coalesce(c_uom_id,'null')=v_uom else c_uom_id is null end 
                   and case when new.m_product_po_id is not null then po.m_product_po_id=new.m_product_po_id  else 1=1 end 
                 order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
            if v_purcur is null then 
                select c_currency_id into v_purcur from ad_org_acctschema,c_acctschema where ad_org_acctschema.c_acctschema_id=c_acctschema.c_acctschema_id and case when v_orgid!='0' then ad_org_acctschema.ad_org_id=v_orgid else 1=1 end limit 1;
            end if;    
            v_Price := Round(C_Currency_Convert(v_Price, v_purcur, v_currency, trunc(now())),2);   
        end if;
        v_PriceNew := M_Get_Offer_Price(Cur_Offer.M_Offer_ID, v_Price);
        v_Amt := v_Price - v_PriceNew;

        IF (NEW.CANCELPRICEAD='N')
            THEN
            INSERT INTO C_ORDERLINE_OFFER
                (C_ORDERLINE_OFFER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
                CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                C_ORDERLINE_ID, LINE, M_OFFER_ID, PRICEOFFER, AMTOFFER)
            VALUES
                (v_OrderLine_Offer_ID, NEW.AD_Client_ID, NEW.AD_Org_ID, NEW.IsActive,
                TO_DATE(NOW()),NEW.CreatedBy, TO_DATE(NOW()),NEW.UpdatedBy,
            NEW.C_OrderLine_ID, v_lineno, Cur_Offer.M_Offer_Id, coalesce(ROUND(v_Price,v_Precision),0), coalesce(ROUND(v_Amt,v_Precision),0));
            v_Price := v_PriceNew;
        END IF;
        if coalesce(Cur_Offer.PRIORITY,0)<100 then
            exit;
        end if;
  END LOOP;
 END IF;

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;
-- Function: m_bom_pricestd(character varying, character varying)

-- DROP FUNCTION m_bom_pricestd(character varying, character varying);
select zsse_dropfunction('m_bom_pricestd');
CREATE OR REPLACE FUNCTION m_bom_pricestd(p_product_id character varying, p_pricelist character varying)
  RETURNS numeric AS
$BODY$ 
BEGIN
    return m_bom_pricestd(p_product_id , p_pricelist , null,null);
END ; 
$BODY$ LANGUAGE 'plpgsql';

-- DROP FUNCTION m_bom_pricestd(character varying, character varying);

CREATE OR REPLACE FUNCTION m_bom_pricestd(p_product_id character varying, p_pricelist character varying, p_uom_id varchar,p_MProductPOID varchar)
  RETURNS numeric AS
$BODY$ 
BEGIN
    return m_bom_pricestd(p_product_id , p_pricelist , p_uom_id,p_MProductPOID,null);
END ; 
$BODY$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION m_bom_pricestd(p_product_id character varying, p_pricelist character varying, p_uom_id varchar,p_MProductPOID varchar, p_bpartner_id varchar)
  RETURNS numeric AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/* Contributions: Purchasing: Get from m_product_po
         Selling: Get from Pricelist
                  If no Price in Pricelist, Price=0
         Removed BOM-Stuff-This is Rubbish
         Get Currency from Pricelist
******************************************************************************************************************************/
  v_Price        NUMERIC;
  v_currency VARCHAR(32); --OBTG:VARCHAR2--
  v_issoPL   character varying;
  v_count numeric;
  v_org character varying;
  v_plvid  character varying;
  v_plist  character varying;
  BEGIN
    -- First check if Paranmeter p_pricelist is the Pricelist-Version
    SELECT M_PRICELIST_VERSION_ID,ad_org_id,M_PRICELIST_ID into v_plvid,v_org,v_plist from M_PRICELIST_VERSION where M_PRICELIST_VERSION_ID=p_pricelist;
    if v_plvid is null then
       -- p_pricelist is the  Pricelist itself - Select the relevant Version
      SELECT M_PRICELIST_VERSION_ID,ad_org_id,M_PRICELIST_ID  INTO v_plvid,v_org,v_plist  FROM M_PRICELIST_VERSION
            WHERE M_PRICELIST_ID=p_pricelist and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=p_pricelist and VALIDFROM<=TO_DATE(NOW())); 
    END if;

    SELECT issopricelist,c_currency_id into v_issoPL, v_currency  from m_pricelist where m_pricelist_id=v_plist;
    
    -- If Sales - Order get price from PriceList directly
    if v_issoPL='Y' then
      SELECT COALESCE(pricestd, 0)
      INTO v_Price
      FROM M_ProductPrice
      WHERE M_PriceList_Version_ID = v_plvid
        AND M_Product_ID = p_Product_ID
        and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null  end 
        order by isstandard desc limit 1;
    else
    -- In PO get Listprice from m_prpoduct PO 
        select pricepo into v_price
                   from M_PRODUCT_PO po 
                   where po.m_product_id=p_product_id and po.c_currency_id=v_currency and PO.iscurrentvendor='Y' and case when v_org!='0' then PO.AD_ORG_ID in ('0',v_org) else 1=1 end 
                   and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null end 
                   AND case when p_MProductPOID is not null then p_MProductPOID=po.m_product_po_id else 1=1 end
                   and case when p_bpartner_id is not null then po.c_bpartner_id=p_bpartner_id  else 1=1 end 
                   order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
        --@TODO: Automatically fill m_product_po - Currency from po-Pricelist or move po-Pricelist to m_product_po
       if v_Price is null then
          select pricepo into v_Price  from m_product_po po where m_product_id=p_product_id and c_currency_id is null  and PO.iscurrentvendor='Y' and case when v_org!='0' then PO.AD_ORG_ID in ('0',v_org) else 1=1 end
                  and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null end 
                   AND case when p_MProductPOID is not null then p_MProductPOID=po.m_product_po_id else 1=1 end
                  and case when p_bpartner_id is not null then po.c_bpartner_id=p_bpartner_id  else 1=1 end 
                 order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
       end if;
    end if;      
    --
    if  v_Price is null then v_Price:=0; end if;
    --RETURN c_currency_round(v_price, v_currency,null);
     RETURN round(v_price, 4);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;




select zsse_dropfunction('m_bom_pricelist');
CREATE OR REPLACE FUNCTION m_bom_pricelist(p_product_id character varying, p_pricelist character varying)
  RETURNS numeric AS
$BODY$ 
BEGIN
    return m_bom_pricelist(p_product_id , p_pricelist , null,null);
END ; 
$BODY$ LANGUAGE 'plpgsql';
-- Function: m_bom_pricelist(character varying, character varying)

-- DROP FUNCTION m_bom_pricelist(character varying, character varying);

CREATE OR REPLACE FUNCTION m_bom_pricelist(p_product_id character varying, p_pricelist character varying,p_uom_id varchar,p_MProductPOID varchar)
  RETURNS numeric AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/* Contributions: Purchasing: Get from m_product_po
         Selling: Get from Pricelist
                  If no Price in Pricelist, Price=0
         Removed BOM-Stuff-This is Rubbish
         Get Currency from Pricelist
******************************************************************************************************************************/
  v_Price        NUMERIC;
  v_currency VARCHAR(32); --OBTG:VARCHAR2--
  v_issoPL   character varying;
  v_count numeric;
  v_org character varying;
  v_plvid  character varying;
  v_plist  character varying;
  BEGIN
    -- First check if Paranmeter p_pricelist is the Pricelist-Version
    SELECT M_PRICELIST_VERSION_ID,ad_org_id,M_PRICELIST_ID into v_plvid,v_org,v_plist from M_PRICELIST_VERSION where M_PRICELIST_VERSION_ID=p_pricelist;
    if v_plvid is null then
       -- p_pricelist is the  Pricelist itself - Select the relevant Version
      SELECT M_PRICELIST_VERSION_ID,ad_org_id,M_PRICELIST_ID  INTO v_plvid,v_org,v_plist  FROM M_PRICELIST_VERSION
            WHERE M_PRICELIST_ID=p_pricelist and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=p_pricelist and VALIDFROM<=TO_DATE(NOW())); 
    END if;

    SELECT issopricelist,c_currency_id into v_issoPL, v_currency  from m_pricelist where m_pricelist_id=v_plist;
    
    -- If Sales - Order get price from PriceList directly
    if v_issoPL='Y' then
      SELECT COALESCE(PriceList, 0)
      INTO v_Price
      FROM M_ProductPrice
      WHERE M_PriceList_Version_ID = v_plvid
        AND M_Product_ID = p_Product_ID
        and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null  end 
        order by isstandard desc limit 1;
    else
    -- In PO get Listprice from m_prpoduct PO 
        select pricelist into v_price
                   from M_PRODUCT_PO po 
                   where po.m_product_id=p_product_id  and po.c_currency_id=v_currency and PO.iscurrentvendor='Y' and case when v_org!='0' then PO.AD_ORG_ID in ('0',v_org) else 1=1 end
                    and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null end 
                   AND case when p_MProductPOID is not null then p_MProductPOID=po.m_product_po_id else 1=1 end
                    order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
         --@TODO: Automatically fill m_product_po - Currency from po-Pricelist or move po-Pricelist to m_product_po
       if v_Price is null then
          select pricelist into v_Price  from m_product_po po where m_product_id=p_product_id and c_currency_id is null and PO.iscurrentvendor='Y' and case when v_org!='0' then PO.AD_ORG_ID in ('0',v_org) else 1=1 end
                 and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null end 
                   AND case when p_MProductPOID is not null then p_MProductPOID=po.m_product_po_id else 1=1 end
                   order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
       end if;
    end if;      
    --
    if  v_Price is null then v_Price:=0; end if;
    --RETURN c_currency_round(v_price, v_currency,null);
    RETURN round(v_price, 4);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



-- Function: m_bom_pricelimit(character varying, character varying)

-- DROP FUNCTION m_bom_pricelimit(character varying, character varying);
select zsse_dropfunction('m_bom_pricelimit');
CREATE OR REPLACE FUNCTION m_bom_pricelimit(p_product_id character varying, p_pricelist character varying)
  RETURNS numeric AS
$BODY$ 
BEGIN
    return m_bom_pricelimit(p_product_id , p_pricelist , null,null);
END ; 
$BODY$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION m_bom_pricelimit(p_product_id character varying, p_pricelist character varying,p_uom_id varchar,p_dummy varchar)
  RETURNS numeric AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/*
 Contributions: Purchasing: Get from m_product_po
         Selling: Get from Pricelist
                  If no Price in Pricelist, Price=0
         Removed BOM-Stuff-This is Rubbish
         Get Currency from Pricelist
******************************************************************************************************************************/
  v_Price        NUMERIC;
  v_currency VARCHAR(32); --OBTG:VARCHAR2--
  v_issoPL   character varying;
  v_plvid  character varying;
  v_plist  character varying;
    --
  BEGIN
    -- First check if Paranmeter p_pricelist is the Pricelist-Version
    SELECT M_PRICELIST_VERSION_ID,M_PRICELIST_ID into v_plvid,v_plist from M_PRICELIST_VERSION where M_PRICELIST_VERSION_ID=p_pricelist;
    if v_plvid is null then
       -- p_pricelist is the  Pricelist itself - Select the relevant Version
      SELECT M_PRICELIST_VERSION_ID,M_PRICELIST_ID  INTO v_plvid,v_plist  FROM M_PRICELIST_VERSION
            WHERE M_PRICELIST_ID=p_pricelist and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=p_pricelist and VALIDFROM<=TO_DATE(NOW())); 
    END if;

    SELECT issopricelist,c_currency_id into v_issoPL, v_currency  from m_pricelist where m_pricelist_id=v_plist;
    
    -- If Sales - Order get price from PriceList directly
    if v_issoPL='Y' then
      SELECT COALESCE(PriceLimit, 0)
      INTO v_Price
      FROM M_ProductPrice
      WHERE M_PriceList_Version_ID = v_plvid
        AND M_Product_ID = p_Product_ID
        and case when p_uom_id is not null then coalesce(c_uom_id,'null')=p_uom_id else c_uom_id is null  end 
        order by isstandard desc limit 1;
    else
    -- In PO a Limit doesn't make sense
       v_Price:=0;
    end if;      
    --
    if  v_Price is null then v_Price:=0; end if;
    --RETURN c_currency_round(v_price, v_currency,null);
     RETURN round(v_price, 4);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;






-- Material Cost richtig ermitteln....neu geschrieben
CREATE OR REPLACE FUNCTION m_get_product_cost(p_product_id character varying, p_movementdate timestamp without time zone, p_costtype character, p_org_id character varying)
  RETURNS numeric AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/*
 Contributions:Get material Costs from costing table (Rewritten)
******************************************************************************************************************************/
  v_Cost     NUMERIC;
  v_CostType VARCHAR(60) ; 
  BEGIN
    v_CostType := p_CostType;
    IF(p_Product_ID IS NULL) THEN
      RETURN 0;
    END IF;
    IF(p_MovementDate IS NULL) THEN
      RETURN 0;
    END IF;
    -- select the Real cost only if costtype is set
    if p_costtype is not null then
        select cost into v_Cost from M_COSTING where m_product_id=p_product_id and costtype=p_costtype and p_movementdate between datefrom and dateto and ad_org_id=p_org_id order by created desc LIMIT 1;
        if v_Cost is null then
           -- Try default
           select cost into v_Cost from M_COSTING where m_product_id=p_product_id and costtype=p_costtype and p_movementdate between datefrom and dateto and ad_org_id='0' order by created desc LIMIT 1;
        end if;
    END IF;
    if v_Cost is null then
       -- Select the fist found cost 
       select cost into v_Cost from M_COSTING where m_product_id=p_product_id  and p_movementdate between datefrom and dateto  and ad_org_id=p_org_id order by created desc LIMIT 1;
       if v_Cost is null then
           -- Try default
           select cost into v_Cost from M_COSTING where m_product_id=p_product_id  and p_movementdate between datefrom and dateto  and ad_org_id='0' order by created desc LIMIT 1;
       end if;
    end if;
    if v_Cost is null then
          v_Cost:=0;
    end if;
    RETURN v_cost;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


-- Material Cost richtig ermitteln....neu geschrieben
CREATE OR REPLACE FUNCTION m_updatecostingfromproduction(p_internalconsumption_id character varying, p_user varchar)
  RETURNS void AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Projects and Manufacturing, Ends a TASK (after Material To Stock)
Gets the Costs into Produced Items
*****************************************************/
DECLARE
     v_costoftask numeric;
     v_itemcost numeric;
     v_qty numeric;
     v_qtyproduced numeric;
     v_matcost numeric;
     v_openitems numeric;
     v_correction numeric:=0;
     v_curr_cost numeric;
     v_curr_onhand_qty         numeric;
     v_actual_cost             numeric;
     v_method                  character varying;
     v_cost_id                 character varying;
     v_permanent               character varying;
     
     v_cur record;
BEGIN
    if (select movementtype from m_internal_consumption where m_internal_consumption_id=p_internalconsumption_id)!='P+' then
        return;
    end if;
    FOR v_cur in (select * from m_internal_consumptionline where m_internal_consumption_id=p_internalconsumption_id)
    LOOP
       if v_cur.c_projecttask_id is null then
            EXIT;
       end if; 
       -- Get Cost of this Task itself
       select coalesce(actualcost,0), qty,qtyproduced,coalesce(materialcost,0) into v_costoftask,v_qty,v_qtyproduced,v_matcost from c_projecttask where c_projecttask_id=v_cur.c_projecttask_id;
       select returnquantity into v_openitems from pdc_PFeedbackUpperGrid(v_cur.c_projecttask_id,p_internalconsumption_id,null) where outtype='PROD' limit 1;
       if v_qtyproduced<=0 or v_costoftask<=0 then
            EXIT;
       end if;
       -- Correct Material Cost If Mat for OpenItems is there.
       if coalesce(v_openitems,0)>0 and coalesce(v_matcost,0)> 0 then
            v_correction:=v_matcost-((v_matcost/(v_qtyproduced+v_openitems))*v_openitems);
       end if;
       v_costoftask:=v_costoftask-v_correction;
       v_itemcost:=v_costoftask/v_qtyproduced;
       -- Current-Cost from costing table
       select m_costing_id,ispermanent,COSTTYPE,COST into v_cost_id, v_permanent,   v_method, v_curr_cost from m_costing where M_PRODUCT_ID=v_cur.M_PRODUCT_ID and DATETO =
                                                         (select max(DATETO) from m_costing where M_PRODUCT_ID=v_cur.M_PRODUCT_ID);
        -- Update the Costing-Table
        -- Current onhand Quantities
        select COALESCE(sum(qtyonhand),0) into v_curr_onhand_qty from m_storage_detail where m_product_id=v_cur.M_PRODUCT_ID and ad_org_id=v_cur.ad_org_id;
        -- Calculation of Costs
        if v_method='ST' then
            v_actual_cost:=v_itemcost;
        ELSE 
          IF v_method='AV' THEN
              -- Cost Calculation only Works with Positive Stcks- No minus-qty allowed
              IF (v_curr_onhand_qty-v_cur.movementqty)>0  THEN
                  v_actual_cost:=((v_curr_cost*v_curr_onhand_qty)+(v_itemcost*v_cur.movementqty))/(v_curr_onhand_qty+v_cur.movementqty);
                  --RAISE NOTICE '%','CurCost: '||v_curr_cost||' v_curr_onhand_qty : '||v_curr_onhand_qty||' v_purchase_price: '||v_purchase_price||' v_movementqty: '||v_movementqty||' v_actual_cost: '||v_actual_cost;
              ELSE
                  v_actual_cost:=v_itemcost; 
              END IF;
            END IF;
        END IF;
        IF v_permanent='N' and v_actual_cost>0 then
            update m_costing set DATETO=now() where m_costing_id=v_cost_id;
            insert into m_costing (M_COSTING_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,  M_PRODUCT_ID, DATEFROM, DATETO, ISMANUAL,   COSTTYPE,  COST,isproduction)
                  values(get_uuid(),v_cur.ad_client_id,v_cur.ad_org_id, now(), p_User, now(), p_User, v_cur.m_product_id,now(),to_date('01.01.9999','dd.mm.yyyy'),'N',v_method,v_actual_cost,'Y');
        END IF;
    END LOOP;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  

CREATE OR REPLACE FUNCTION m_updatecosting(p_inout_id varchar, p_orderid varchar,p_invoiceid varchar,p_isreverse varchar)
  RETURNS void AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

/*
 Updates the Costing table from Inout Movements or Direct Shipments or Invoices
******************************************************************************************************************************/
    v_Cost     NUMERIC;
    v_CostType VARCHAR(60) ; 
    TYPE_Ref REFCURSOR;
    v_cursor TYPE_Ref%TYPE;
    v_cur_line RECORD;
    v_sql varchar;
    v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
    v_currproduct varchar :='';
    v_org_currency varchar;
    v_purchase_price          numeric;
    v_curr_onhand_qty         numeric;
    v_curr_cost               numeric;
    v_method                  character varying;
    v_uom_conversion          numeric;
    v2nduom                   varchar;
    v_actual_cost             numeric;
    v_movementqty             numeric;
    v_cost_id                 character varying;
    v_permanent               character varying;
    v_isdefault               character varying:='N';
  BEGIN
    
      -- Load Document
      if p_inout_id is not null then
        if (select movementtype from m_inout where m_inout_id=p_inout_id)!='V+' then 
            return;
        else
            v_sql:='select mi.processed,mi.updatedby,miol.movementqty as movementqty,miol.m_product_id,ol.priceactual as price,o.c_currency_id,o.ad_org_id,mi.movementdate,miol.m_inoutline_id,';
            v_sql:=v_sql||' ol.c_orderline_id,null::varchar(32) as c_invoiceline_id,ol.m_product_uom_id,ol.c_uom_id,ol.quantityorder ';
            v_sql:=v_sql||' from m_inout mi,m_inoutline miol,c_orderline ol,c_order o where mi.m_inout_id=miol.m_inout_id and miol.c_orderline_id=ol.c_orderline_id and o.c_order_id=ol.c_order_id and';
            v_sql:=v_sql||' mi.m_inout_id='||chr(39)||p_inout_id||chr(39)||' and miol.m_product_id is not null and miol.movementqty>0 order by miol.m_product_id';
        end if;
      end if;
      if p_orderid is not null then
        if (select count(*) from c_order where c_order_id=p_orderid and issotrx='N')=0 then 
            return;
        else
            v_sql:='select o.processed,o.updatedby,ol.QtyDelivered as movementqty,ol.m_product_id,ol.priceactual as price,o.c_currency_id,o.ad_org_id,o.dateordered as movementdate,';
            v_sql:=v_sql||' null::varchar(32) as m_inoutline_id,ol.c_orderline_id,null::varchar(32) as c_invoiceline_id,ol.m_product_uom_id,ol.c_uom_id,ol.quantityorder ';
            v_sql:=v_sql||' from c_orderline ol,c_order o where o.c_order_id=ol.c_order_id and ol.QtyDelivered>0 and ';
            v_sql:=v_sql||' ol.DirectShip=''Y'' and o.c_order_id='||chr(39)||p_orderid||chr(39)||'  and ol.m_product_id is not null  order by  ol.m_product_id';
        end if;
      end if;
      if p_invoiceid is not null then
         if (select count(*) from c_invoice where c_invoice_id=p_invoiceid and issotrx='N')=0 then 
            return;
        else
            v_sql:='select i.processed,i.updatedby,il.Qtyinvoiced as movementqty,il.m_product_id,il.priceactual as price,i.c_currency_id,i.ad_org_id,i.dateinvoiced as movementdate,';
            v_sql:='il.c_orderline_id,il.m_inoutline_id,il.c_invoiceline_id,il.m_product_uom_id,il.c_uom_id,il.quantityorder ';
            v_sql:=v_sql||' from c_orderline ol,c_invoiceline il,c_invoice i where i.c_invoice_id=il.c_invoice_id and il.c_orderline_id=ol.c_orderline_id and ';
            v_sql:=v_sql||' il.Qtyinvoiced>0 and i.c_invoice_id='||chr(39)||p_invoiceid||chr(39)||'  and il.m_product_id is not null  order by il.m_product_id ';
        end if;
      end if;
      --RAISE NOTICE '%','SQL: '||v_sql;
      --loop lines
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
        FETCH v_cursor INTO v_cur_line;
        EXIT WHEN NOT FOUND;
           -- Get Transction -Org and its Currency
           select c_currency_id into v_org_currency from ad_org_acctschema,c_acctschema where ad_org_acctschema.c_acctschema_id=c_acctschema.c_acctschema_id and ad_org_acctschema.ad_org_id=v_cur_line.ad_org_id;
           -- Get Current Values
           select m_costing_id,ispermanent,COSTTYPE,COST into v_cost_id, v_permanent,   v_method, v_curr_cost from m_costing where M_PRODUCT_ID=v_cur_line.m_product_id  and ad_org_id =v_cur_line.AD_Org_ID and DATETO =
                                                         (select max(DATETO) from m_costing where M_PRODUCT_ID=v_cur_line.m_product_id and ad_org_id =v_cur_line.AD_Org_ID);
           if v_cost_id is null then
              -- Get default
              select m_costing_id,ispermanent,COSTTYPE,COST into v_cost_id, v_permanent,   v_method, v_curr_cost from m_costing where M_PRODUCT_ID=v_cur_line.m_product_id  and ad_org_id ='0' and DATETO =
                                                         (select max(DATETO) from m_costing where M_PRODUCT_ID=v_cur_line.m_product_id and ad_org_id ='0');
              v_isdefault:='Y';
           end if;
           -- Current onhand Quantities
           select COALESCE(sum(qtyonhand),0) into v_curr_onhand_qty from m_storage_detail where m_product_id=v_cur_line.m_product_id  and AD_Org_ID=v_cur_line.AD_Org_ID;
           -- Purchase Price, (Be aware of secondary Order UOM and Order-Currency
           if v_cur_line.m_product_uom_id is not null and coalesce(v_cur_line.quantityorder,0)!=0 then
              select c_uom_id into v2nduom from m_product_uom where m_product_uom_id=v_cur_line.m_product_uom_id;
              v_uom_conversion:=c_uom_convert(1, v2nduom,v_cur_line.c_uom_id, 'Y');
              v_purchase_price:=v_cur_line.price/coalesce(v_uom_conversion,1);
           else
            v_purchase_price:=v_cur_line.price;
           end if; 
           --raise notice '%','####'||coalesce(v_uom_conversion,1)||'#'||coalesce(v_cur_line.m_product_uom_id,'nix')||'#'||coalesce(v_cur_line.quantityorder,0)||'#'||v_purchase_price;
           -- Currency-Conversion
           v_purchase_price:= round(C_Currency_Convert(v_purchase_price, v_cur_line.c_currency_id, v_org_currency, v_cur_line.movementdate, NULL, v_client, v_cur_line.AD_Org_ID), 4);      
           -- If Cancelling the Receipt the movementqty is reversed
           if p_isreverse='Y' then
               v_movementqty:=v_cur_line.movementqty*(-1);
           ELSE
               v_movementqty:=v_cur_line.movementqty;
           END IF;
            -- Calculation
           if v_method='ST' or (select isstocked from m_product where m_product_id=v_cur_line.m_product_id)='N' then
               v_actual_cost:=v_purchase_price;
           ELSE 
              IF v_method='AV' THEN
                  -- v_movementqty was booked before on stock... -minus it
                  if p_orderid is null then
                    v_curr_onhand_qty:=v_curr_onhand_qty-v_movementqty;
                  end if;
                  -- Cost Calculation only Works with Positive Stcks- No minus-qty allowed
                  IF (v_curr_onhand_qty+v_movementqty>0) and v_curr_onhand_qty>=0 THEN
                     v_actual_cost:=((v_curr_cost*v_curr_onhand_qty)+(v_purchase_price*v_movementqty))/(v_curr_onhand_qty+v_movementqty);
                     --RAISE NOTICE '%','ääääääääääääääääääääääääääääääääCurCost: '||v_curr_cost||' v_curr_onhand_qty : '||v_curr_onhand_qty||' v_purchase_price: '||v_purchase_price||' v_movementqty: '||v_movementqty||' v_actual_cost: '||v_actual_cost;
                  ELSE
                      v_actual_cost:=0; 
                  END IF;
               END IF;
            END IF;
            IF v_permanent='N' and v_actual_cost!=0 then              
               if v_currproduct!=v_cur_line.m_product_id and p_invoiceid is null then
                    if v_isdefault='N' then
                        update m_costing set DATETO=now() where m_costing_id=v_cost_id;
                    end if;
                    insert into m_costing (M_COSTING_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,  M_PRODUCT_ID, DATEFROM, DATETO, ISMANUAL, PRICE,  COSTTYPE,  COST, m_inoutline_id,c_invoiceline_id,c_orderline_id)
                        values(get_uuid(),v_client, v_cur_line.AD_Org_ID, now(), v_cur_line.UPDATEDBY, now(), v_cur_line.UPDATEDBY, v_cur_line.m_product_id,trunc(now()),to_date('01.01.9999','dd.mm.yyyy'),'N',v_purchase_price,v_method,v_actual_cost,v_cur_line.m_inoutline_id,v_cur_line.c_invoiceline_id,v_cur_line.c_orderline_id);
                    v_currproduct:=v_cur_line.m_product_id;
                    --RAISE NOTICE '%','ääääääääääääääääääääääääääääääääCurCost: ';
               else
                     update m_costing set  price=v_purchase_price,cost=v_actual_cost ,
                            m_inoutline_id= case when v_cur_line.m_inoutline_id is not null then v_cur_line.m_inoutline_id else m_inoutline_id end,
                            c_invoiceline_id= case when v_cur_line.c_invoiceline_id is not null then v_cur_line.c_invoiceline_id else c_invoiceline_id end,
                            c_orderline_id= case when v_cur_line.c_orderline_id is not null then v_cur_line.c_orderline_id else c_orderline_id end
                     where m_costing_id=v_cost_id;
               end if;
            END IF;
      END LOOP;
    RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


/*****************************************************+





   
  Cost Center (Tree)
  
   
*****************************************************/


CREATE OR REPLACE FUNCTION a_asset_cctree_trg() RETURNS trigger
AS $BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Cosing
Imlements Cost Center Tree
*****************************************************/
v_Tree_ID              character varying;
v_Parent_ID            character varying;
v_exists               numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
  select ad_tree_id into v_Tree_ID from ad_tree where treetype='CC' and isactive='Y';
  select ad_treenode_id into v_Parent_ID from ad_treenode where ad_tree_id=v_Tree_ID and parent_id is null;
  -- only if tree exists
  if v_Tree_ID is not null and v_Parent_ID is not null then
       IF TG_OP in ('INSERT','UPDATE') then
            select count(*) into v_exists from AD_TreeNode where AD_Tree_ID=v_Tree_ID and Node_ID=new.A_ASSET_ID;
            if v_exists =0 THEN    
                --  Insert into TreeNode
                INSERT INTO AD_TreeNode
                  (AD_TreeNode_ID, AD_Client_ID, AD_Org_ID,
                  IsActive, Created, CreatedBy, Updated, UpdatedBy,
                  AD_Tree_ID, Node_ID,
                  Parent_ID, SeqNo)
                VALUES
                  (get_uuid(), new.AD_Client_ID, new.AD_Org_ID,
                  new.IsActive, new.Created, new.CreatedBy, new.Updated, new.UpdatedBy,
                  v_Tree_ID, new.A_ASSET_ID,
                  '0', (CASE new.IsSummary WHEN 'Y' THEN 100 ELSE 999 END));    -- Summary Nodes first
            end if;
       else --delete
            delete from AD_TreeNode where AD_Tree_ID=v_Tree_ID and Node_ID=old.A_ASSET_ID;
       end if;
  end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION a_asset_cctree_trg() OWNER TO tad;

DROP TRIGGER a_asset_cctree_trg ON a_asset;

CREATE TRIGGER a_asset_cctree_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON a_asset
  FOR EACH ROW
  EXECUTE PROCEDURE a_asset_cctree_trg();

  
  select zsse_DropView ('A_ASSET_COSTCENTER_V');
CREATE OR REPLACE VIEW A_ASSET_COSTCENTER_V AS 
select
        il.c_invoiceline_id as a_asset_costcenter_v_id,
	i.ad_client_id, 
	i.ad_org_id, 
	i.isactive, 
	i.created, 
	i.createdby, 
	i.updated, 
	i.updatedby, 
il.a_asset_id,
i.documentno, 
il.m_product_id, 
il.description, 
i.dateinvoiced as dateordered,
il.c_invoiceline_id,
a.value,
null as zsfi_macctline_id,
case when ad_get_docbasetype(i.c_doctype_id)='APC' then
case when i.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct)-c_currency_convert(linegrossamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct)/(1+100/t.rate),2)*-1 else case when  i.isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct),0)*-1 else coalesce(c_currency_convert(linenetamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct),0)*-1 end end else
case when i.isgrossinvoice='Y' and t.rate>0 then round(c_currency_convert(linegrossamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct)-c_currency_convert(linegrossamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct)/(1+100/t.rate),2) else case when  i.isgrossinvoice='Y' and t.rate=0 then coalesce(c_currency_convert(linegrossamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct),0) else  coalesce(c_currency_convert(linenetamt,i.c_currency_id,coalesce(act.c_currency_id,cl.c_currency_id),i.dateacct),0) end end end as amt
from ad_client cl,c_invoice i,c_invoiceline il, c_tax t,a_asset a left join ad_org_acctschema oas on a.ad_org_id=oas.ad_org_id
                                                     left join c_acctschema act on oas.c_acctschema_id=act.c_acctschema_id
where
a.a_asset_id=il.a_asset_id and
cl.ad_client_id='C726FEC915A54A0995C568555DA5BB3C' and
t.c_tax_id=il.c_tax_id and
ad_get_docbasetype(i.c_doctype_id) in ('API','APC') and i.c_invoice_id=il.c_invoice_id 
and i.issotrx='N' and i.docstatus in ('CO','CL') 
union
select    
   ml.zsfi_macctline_id as a_asset_costcenter_v_id,
   ml.ad_client_id, 
        ml.ad_org_id, 
        ml.isactive, 
        ml.created, 
        ml.createdby, 
        ml.updated, 
        ml.updatedby, 
        ml.a_asset_id, 
mic.documentno, 
null as m_product_id, 
   ml.description,   
   ml.acctdate as dateordered, 
null as c_invoiceline_id,
a.value,
ml.zsfi_macctline_id,   
coalesce(round(case when ml.isgross='N' or t.rate=0 then ml.amt*case when ml.isdr2cr='Y' then 1 else -1 end else 
                   case when ml.isdr2cr='Y' then 1 else -1 end * (ml.amt-ml.amt/(1+100/t.rate)) end,2),0) as amt
from zsfi_macctline ml, zsfi_manualacct mic,c_tax t,a_asset a
where ml.a_asset_id=a.a_asset_id and t.c_tax_id=ml.c_tax_id and mic.zsfi_manualacct_id=ml.zsfi_manualacct_id and mic.glstatus='PO';

