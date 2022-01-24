/* ---------------------------------------------------------------------------------------




Read Only Views representing data for anylysis Purposes







--------------------------------------------------------------------------------------------*/

select zsse_DropView ('c_project_order_overview');
create or replace view c_project_order_overview as
select
  c_order_id as c_project_order_overview_id,
  c_order_id,
  c_bpartner_id,
  c_bpartner_location_id,
  m_pricelist_id,
  iscompletelyinvoiced,
  c_doctype_id,
  issotrx,
  case when issotrx='Y' then totallines else 0 end as salestotallines,
  case when issotrx='N' then totallines else 0 end as purchasetotallines,
  case when issotrx='Y' then invoicedamt  else 0 end as salesinvoicedamt,
  case when issotrx='N' then invoicedamt  else 0 end as purchaseinvoicedamt,
  description,
  ad_org_id,
  ad_client_id,
  isactive,
  created,
  createdby,
  updated,
  updatedby,
  c_project_id,
  (select name from c_bpartner where c_bpartner_id=b.c_bpartner_id) as bpname,
  documentnote::varchar(2000)
  from  (select ad_client_id,issotrx,c_order_id,c_bpartner_id,c_bpartner_location_id,m_pricelist_id,iscompletelyinvoiced,c_doctype_id,
                sum(totallines) as totallines,isactive,invoicedamt,description,ad_org_id,created,createdby,updated,updatedby,c_project_id,
                (select ix.documentno||(case when ilx.description is not null then '-'||ilx.description when ilx.description is null and ix.description is not null then '-'||ix.description else '' end) from c_order ix,c_orderline ilx where 
                 ix.c_order_id=ilx.c_order_id and ilx.line=10 and ix.c_order_id=a.c_order_id limit 1) as documentnote
        from
            (select i.ad_client_id,i.issotrx,i.c_order_id,i.c_bpartner_id,i.c_bpartner_location_id,i.m_pricelist_id,i.iscompletelyinvoiced,i.c_doctype_id,
                    case when i.istaxincluded='Y' then 
                                sum(case when (select rate from c_tax where c_tax_id=il.c_tax_id)>0 then
                                    round(c_currency_convert(il.linegrossamt,i.c_currency_id,act.c_currency_id,i.dateacct) - c_currency_convert(il.linegrossamt,i.c_currency_id,act.c_currency_id,i.dateacct)/(1+100/(select rate from c_tax where c_tax_id=il.c_tax_id)),2) else
                                    c_currency_convert(il.linegrossamt,i.c_currency_id,act.c_currency_id,i.dateacct) end) else
                                sum(c_currency_convert(il.linenetamt,i.c_currency_id,act.c_currency_id,i.dateacct)) end as totallines,
                    i.isactive,c_currency_convert(i.invoicedamt,i.c_currency_id,act.c_currency_id,i.dateacct) as invoicedamt,
                    i.description,i.ad_org_id,i.created,
                    i.createdby,i.updated,i.updatedby,il.c_project_id
            from c_order i,c_orderline il,c_project p,ad_org_acctschema oas,c_acctschema act
            where i.c_order_id=il.c_order_id and
                    il.c_project_id =p.c_project_id and p.ad_org_id=oas.ad_org_id and oas.c_acctschema_id=act.c_acctschema_id and
                    i.docstatus='CO' and ad_get_docbasetype(i.c_doctype_id) in ('SOO','POO') group by il.c_project_id,il.c_tax_id,act.c_currency_id,
                    i.ad_client_id,i.issotrx,i.c_order_id,i.c_bpartner_id,i.c_bpartner_location_id,i.m_pricelist_id,i.iscompletelyinvoiced,i.c_doctype_id,i.istaxincluded,
                    i.isactive,i.description,i.ad_org_id,i.created,i.createdby,i.updated,i.updatedby,i.invoicedamt) a
        group by a.ad_client_id,a.issotrx,a.c_order_id,a.c_bpartner_id,a.c_bpartner_location_id,a.m_pricelist_id,a.iscompletelyinvoiced,a.c_doctype_id,
                 a.isactive,a.invoicedamt,a.description,a.ad_org_id,a.created,a.createdby,a.updated,a.updatedby,a.c_project_id) b;
       
select zsse_DropView ('c_project_invoice_overview');
create or replace view c_project_invoice_overview as
select
  c_invoice_id as c_project_invoice_overview_id,
  c_invoice_id,
  zsfi_macctline_id::text,
  c_bpartner_id,
  c_bpartner_location_id,
  m_pricelist_id,
  ispaid,
  c_doctype_id,
  issotrx,
  case when issotrx='Y' then totallines else 0 end as salestotallines,
  case when issotrx='N' then totallines else 0 end as purchasetotallines,
  case when issotrx='Y' then case when totalpaidquot<>0 then round(totallines*totalpaidquot,2) else 0 end  else 0 end as salestotalpaid,
  case when issotrx='N' then case when totalpaidquot<>0 then round(totallines*totalpaidquot,2) else 0 end  else 0 end as purchasetotalpaid,
  description,
  ad_org_id,
  ad_client_id,
  isactive,
  created,
  createdby,
  updated,
  updatedby,
  c_project_id,
  (select name from c_bpartner where c_bpartner_id=b.c_bpartner_id) as bpname,
  documentnote::varchar(2000)
  from  (select ad_client_id,issotrx,c_invoice_id,null as zsfi_macctline_id,c_bpartner_id,c_bpartner_location_id,m_pricelist_id,ispaid,c_doctype_id,
                sum(totallines) as totallines,isactive,totalpaidquot,description,ad_org_id,created,createdby,updated,updatedby,c_project_id,
                (select ix.documentno||coalesce('-'||ix.description,'')||string_agg((case when ilx.description is not null then '-'||ilx.description  else '' end),'-') from c_invoice ix,c_invoiceline ilx where 
                 ix.c_invoice_id=ilx.c_invoice_id and ilx.c_project_id=a.c_project_id and ix.c_invoice_id=a.c_invoice_id group by ix.documentno,ix.description limit 1) as documentnote
        from
            (select i.ad_client_id,i.issotrx,i.c_invoice_id,i.c_bpartner_id,i.c_bpartner_location_id,i.m_pricelist_id,i.ispaid,i.c_doctype_id,
                    case when i.isgrossinvoice='Y' then 
                                sum(case when (select rate from c_tax where c_tax_id=il.c_tax_id)>0 then
                                    round(c_currency_convert(il.linegrossamt,i.c_currency_id,act.c_currency_id,i.dateacct) - c_currency_convert(il.linegrossamt,i.c_currency_id,act.c_currency_id,i.dateacct)/(1+100/(select rate from c_tax where c_tax_id=il.c_tax_id)),2) else
                                    c_currency_convert(il.linegrossamt,i.c_currency_id,act.c_currency_id,i.dateacct) end) else
                                sum(c_currency_convert(il.linenetamt,i.c_currency_id,act.c_currency_id,i.dateacct)) end 
                                * case when ad_get_docbasetype(i.c_doctype_id) in ('ARC','APC') then -1 else 1 end as totallines,
                    i.isactive,
                     case when i.totalpaid<>0 and i.grandtotal<>0 then   c_currency_convert(i.totalpaid,i.c_currency_id,act.c_currency_id,i.dateacct) / c_currency_convert(i.grandtotal * case when ad_get_docbasetype(i.c_doctype_id) in ('ARC','APC') then -1 else 1 end ,i.c_currency_id,act.c_currency_id,i.dateacct) else 0 end as totalpaidquot,
                    i.description,i.ad_org_id,i.created,
                    i.createdby,i.updated,i.updatedby,il.c_project_id
            from c_invoice i,c_invoiceline il,c_project p,ad_org_acctschema oas,c_acctschema act
            where i.c_invoice_id=il.c_invoice_id and i.c_doctype_id!='CCFE32E992B74157975E675458B844D1' and
                    il.c_project_id =p.c_project_id and p.ad_org_id=oas.ad_org_id and oas.c_acctschema_id=act.c_acctschema_id and
                    i.docstatus='CO' group by il.c_project_id,il.c_tax_id,act.c_currency_id,
                    i.ad_client_id,i.issotrx,i.c_invoice_id,i.c_bpartner_id,i.c_bpartner_location_id,i.m_pricelist_id,i.ispaid,i.c_doctype_id,i.isgrossinvoice,
                    i.isactive,i.description,i.ad_org_id,i.created,i.createdby,i.updated,i.updatedby,i.totalpaid,i.totallines) a
        group by a.ad_client_id,a.issotrx,a.c_invoice_id,a.c_bpartner_id,a.c_bpartner_location_id,a.m_pricelist_id,a.ispaid,a.c_doctype_id,
                 a.isactive,a.totalpaidquot,a.description,a.ad_org_id,a.created,a.createdby,a.updated,a.updatedby,a.c_project_id) b
UNION
select
  ml.zsfi_macctline_id as c_project_invoice_overview_id,
  null as c_invoice_id,
  ml.zsfi_macctline_id,
  null as c_bpartner_id,
  null as c_bpartner_location_id,
  null as m_pricelist_id,
  'Y' as ispaid,
  '8345D47F584B4C50A9CBC46B20E4C73A' as c_doctype_id,
  'N' as issotrx,
  0  as salestotallines,
  coalesce(round(case when ml.isgross='N' or t.rate=0 then ml.amt*case when ml.isdr2cr='Y' then 1 else -1 end else 
                   case when ml.isdr2cr='Y' then 1 else -1 end * ml.amt-ml.amt/(1+100/t.rate) end,2),0)  purchasetotallines,
  0 salestotalpaid,
  coalesce(round(case when ml.isgross='N' or t.rate=0 then ml.amt*case when ml.isdr2cr='Y' then 1 else -1 end else 
                   case when ml.isdr2cr='Y' then 1 else -1 end * ml.amt-ml.amt/(1+100/t.rate) end,2),0)  purchasetotalpaid,
  ml.description,
  ml.ad_org_id,
  ml.ad_client_id,
  ml.isactive,
  ml.created,
  ml.createdby,
  ml.updated,
  ml.updatedby,
  ml.c_project_id,
  null as bpname,
  mic.documentno||'-'||ml.line||'-'||ml.description as documentnote
from zsfi_macctline ml, zsfi_manualacct mic,c_tax t,c_project p
where ml.c_project_id=p.c_project_id and t.c_tax_id=ml.c_tax_id and mic.zsfi_manualacct_id=ml.zsfi_manualacct_id and mic.glstatus='PO' ;     
       
       
       
select zsse_DropView ('m_product_not_puchaseble_overview');
create or replace view m_product_not_puchaseble_overview as     
select 
m.m_product_id as m_product_not_puchaseble_overview_id,
m.m_product_id ,
m.m_product_category_id,
ad_org_id,
 m.ad_client_id,
 m.isactive,
 m.created,
 m.createdby,
 m.updated,
 m.updatedby
from m_product m 
where m.ispurchased='Y' and m.production='N' and m.isactive='Y' and
not exists (select 0 from m_product_po po where po.m_product_id=m.m_product_id and po.isactive='Y' and po.iscurrentvendor='Y');





select zsse_DropView ('m_pricelist_overview');

create or replace view m_pricelist_overview as     
select
    p.m_productprice_id as m_pricelist_overview_id,
    pv.validfrom,
    pl.m_pricelist_id,
    p.m_product_id ,
    p.ad_client_id  ,
    p.ad_org_id   ,
    p.isactive       ,
    p.created       ,
    p.createdby   ,
    p.updated      ,
    p.updatedby      ,
    p.pricelist      ,
    p.pricestd        ,
    p.pricelimit  
from m_pricelist pl,m_pricelist_version pv,m_productprice p where
     pl.m_pricelist_id=pv.m_pricelist_id and pv.m_pricelist_version_id=p.m_pricelist_version_id ;


     
        
select zsse_dropview ('c_order_productcategory_v');
create or replace view c_order_productcategory_v as
select
      ol.c_orderline_id||o.c_order_id as c_order_productcategory_v_id,
      ol.c_orderline_id,
      o.c_order_id,
      o.ad_client_id,
      o.ad_org_id,
      ol.isactive,
      ol.created,
      ol.createdby,
      ol.updated,
      ol.updatedby,
      o.billto_id,
      ol.line,
      o.name,
      o.documentno,
      o.dateordered,
      o.docstatus,
      o.internalnote,
      o.c_bpartner_id,
      o.c_bpartner_location_id,
      o.poreference,
      bpl.c_salesregion_id,
      o.ad_user_id,
      o.salesrep_id,
      p.m_product_category_id,
      p.typeofproduct,
      p.c_uom_id,
      p.value,
      p.name as productname,
      ol.m_product_id,
      ol.qtyordered,
      ol.qtydelivered,   
      max(mi.movementdate) as datedelivered,
      string_agg(coalesce(snr.serialnumber,'')||coalesce(snr.lotnumber,''),', ') as snrbatchesdelivered,
      string_agg(ml.value,', ') as locatorvalue,
      m_bom_qty_onhand(ol.m_product_id,o.m_warehouse_id) as qtyavailable,
      o.deliverycomplete,
      bp.iscustomer,
      bp.isvendor
      from c_order o, c_orderline ol left join m_inoutline mil on mil.c_orderline_id=ol.c_orderline_id
                                     left join m_locator ml on ml.m_locator_id=mil.m_locator_id
                                     left join m_inout mi on mil.m_inout_id=mi.m_inout_id and mi.docstatus='CO' and mi.movementtype in ('V+','C-')
                                     left join snr_minoutline snr on snr.m_inoutline_id=mil.m_inoutline_id
        ,m_product p, c_bpartner bp ,c_bpartner_location bpl
        where o.c_order_id=ol.c_order_id and ol.m_product_id=p.m_product_id and o.c_bpartner_id=bp.c_bpartner_id and o.c_bpartner_location_id=bpl.c_bpartner_location_id
      group by ol.c_orderline_id,o.c_order_id,o.ad_client_id,o.ad_org_id,ol.isactive,ol.created,ol.createdby,ol.updated,ol.updatedby,o.billto_id,
               ol.line,o.name,o.documentno,o.dateordered,o.docstatus,o.internalnote,o.c_bpartner_id,o.c_bpartner_location_id,bpl.c_salesregion_id,
               o.ad_user_id,o.salesrep_id,p.m_product_category_id,p.typeofproduct,p.c_uom_id,p.name,p.value,ol.m_product_id,ol.qtyordered,ol.qtydelivered,   
               o.m_warehouse_id,o.deliverycomplete,bp.iscustomer,bp.isvendor;
        
        
        
select zsse_dropview ('c_projectinvoicedates_v');
create or replace view c_projectinvoicedates_v as
select 
 p.c_project_id,
 p.c_project_id as c_projectinvoicedates_v_id,
 p.ad_client_id,
 p.ad_org_id,
 p.isactive,
 p.created,
 p.createdby,
 p.updated,
 p.updatedby,
 p.value,
 p.name,
 p.description,
 p.note,
 p.issummary,
 p.ad_user_id,
 p.c_bpartner_id,
 p.c_bpartner_location_id,
 p.poreference,
 p.c_paymentterm_id,
 p.c_currency_id,
 p.createtemppricelist,
 p.m_pricelist_version_id,
 p.c_campaign_id,
 p.iscommitment,
 p.plannedamt,
 p.plannedqty,
 p.plannedmarginamt,
 p.committedamt,
 p.datecontract,
 p.datefinish,
 p.generateto,
 p.processed,
 p.salesrep_id,
 p.copyfrom,
 p.c_projecttype_id,
 p.committedqty,
 p.invoicedamt,
 p.invoicedqty,
 p.projectbalanceamt,
 p.c_phase_id,
 p.c_projectphase_id,
 p.iscommitceiling,
 p.m_warehouse_id,
 p.projectcategory,
 p.processing,
 p.publicprivate,
 p.projectstatus,
 p.projectkind,
 p.projectphase,
 p.generateorder,
 p.changeprojectstatus,
 p.c_location_id,
 p.m_pricelist_id,
 p.paymentrule,
 p.invoice_toproject,
 p.plannedpoamt,
 p.lastplannedproposaldate,
 p.document_copies,
 p.accountno,
 p.expexpenses,
 p.expmargin,
 p.expreinvoicing,
 p.responsible_id,
 p.servcost,
 p.servmargin,
 p.servrevenue,
 p.setprojecttype,
 p.startdate,
 p.a_asset_id,
 p.schedulestatus,
 p.actualcostamount,
 p.percentdoneyet,
 p.estimatedamt,
 p.qtyofproduct,
 p.m_product_id,
 p.closeproject,
 p.materialcost,
 p.indirectcost,
 p.machinecost,
 p.expenses,
 p.reopenproject,
 p.isdefault,
 p.timeperpiece,
 p.setuptime,
 p.isautotriggered,
 p.plannedmarginpercent,
 p.marginamt,
 p.marginpercent,
 p.materialcostplan,
 p.indirectcostplan,
 p.machinecostplan,
 p.servcostplan,
 p.expensesplan,
 p.externalserviceplan,
 p.externalservice,
 p.ishidden,
 p.ma_machine_id,
 p.istaskssametime,
 zspm_getprojectfirstinvoicedate(p.c_project_id) as firstinvoicedate,
 zspm_getprojectlastinvoicedate(p.c_project_id) as lastinvoicedate
 from c_project p where exists (select 0 from c_invoice where docstatus='CO' and ad_get_docbasetype(c_doctype_id)='ARI' and c_project_id=p.c_project_id);

 
CREATE OR REPLACE FUNCTION zssi_getpartnersum(p_bpartner_id varchar,amountopen numeric) returns numeric AS $_$
DECLARE
    v_partner varchar;
    v_sum numeric;
BEGIN
    if (SELECT count(*) from information_schema.tables where table_name='partnersum')=0 then
        create temporary table partnersum(
            summe numeric,
            c_bpartner_id varchar(32)
        )  ON COMMIT DROP ;
    end if;
    select c_bpartner_id into v_partner from partnersum limit 1;
    if v_partner is null then
        insert into partnersum(c_bpartner_id,summe) values (p_bpartner_id,0);
    end if;
    select c_bpartner_id,summe into v_partner,v_sum from partnersum limit 1;
    if v_partner!=p_bpartner_id then
       delete from partnersum;
       insert into partnersum(c_bpartner_id,summe) values (p_bpartner_id,0);
       v_sum:=0;
    end if;
    update partnersum set summe=summe+amountopen;
    return v_sum + amountopen;
END; 
$_$ LANGUAGE plpgsql VOLATILE COST 100;



 
 
/* ---------------------------------------------------------------------------------------




View Drahtverhau rund um Invoice







--------------------------------------------------------------------------------------------*/       
select zsse_dropview ('c_invoice_month');
select zsse_dropview ('c_invoice_prodmonth');
select zsse_dropview ('c_invoice_vendormonth');
select zsse_dropview ('c_invoice_customervendqtr');
select zsse_dropview ('c_invoice_customerprodqtr');
select zsse_dropview ('c_invoice_week');
select zsse_dropview ('c_invoice_prodweek');
select zsse_dropview ('c_invoice_day');
select zsse_dropview ('c_invoiceline_v2');
select zsse_dropview ('c_invoice_v2');

CREATE  VIEW c_invoice_v2 AS 
 SELECT i.c_invoice_id, i.ad_client_id, i.ad_org_id, i.isactive, i.created, i.createdby, i.updated, i.updatedby, i.issotrx, i.documentno, i.docstatus, i.docaction, i.isprinted, i.isdiscountprinted, i.processing, i.processed, i.c_doctype_id, i.c_doctypetarget_id, i.c_order_id, i.description, i.salesrep_id, i.dateinvoiced, i.dateprinted, i.dateacct, i.c_bpartner_id, i.c_bpartner_location_id, i.ad_user_id, b.c_bp_group_id, i.poreference, i.dateordered, i.c_currency_id, i.paymentrule, i.c_paymentterm_id, i.m_pricelist_id, i.c_campaign_id, i.c_project_id, i.c_activity_id, i.c_charge_id, 
        CASE substr(d.docbasetype::text, 3)
            WHEN 'C'::text THEN i.chargeamt * (-1)::numeric
            ELSE i.chargeamt
        END AS chargeamt, 
        CASE substr(d.docbasetype::text, 3)
            WHEN 'C'::text THEN i.totallines * (-1)::numeric
            ELSE i.totallines
        END AS totallines, 
        CASE substr(d.docbasetype::text, 3)
            WHEN 'C'::text THEN i.grandtotal * (-1)::numeric
            ELSE i.grandtotal
        END AS grandtotal, 
        CASE substr(d.docbasetype::text, 3)
            WHEN 'C'::text THEN (-1)
            ELSE 1
        END AS multiplier
   FROM c_invoice i, c_doctype d, c_bpartner b
  WHERE i.c_doctype_id::text = d.c_doctype_id::text AND i.c_bpartner_id::text = b.c_bpartner_id::text;

CREATE OR REPLACE VIEW c_invoiceline_v2 AS 
 SELECT il.ad_client_id, il.ad_org_id, il.c_invoiceline_id, i.c_invoice_id, i.salesrep_id, i.c_bpartner_id, i.c_bp_group_id, il.m_product_id, p.m_product_category_id, i.dateinvoiced, i.dateacct, il.qtyinvoiced * i.multiplier::numeric AS qtyinvoiced, il.pricelist, il.priceactual, il.pricelimit, 
        CASE il.pricelist
            WHEN 0 THEN 0::numeric
            ELSE round((il.pricelist - il.priceactual) / il.pricelist * 100::numeric, 2)
        END AS discount, 
        CASE il.pricelimit
            WHEN 0 THEN 0::numeric
            ELSE round((il.priceactual - il.pricelimit) / il.pricelimit * 100::numeric, 2)
        END AS margin, round(i.multiplier::numeric * il.linenetamt, 2) AS linenetamt, round(i.multiplier::numeric * il.pricelist * il.qtyinvoiced, 2) AS linelistamt, 
        CASE
            WHEN il.pricelimit IS NULL THEN round(i.multiplier::numeric * il.linenetamt, 2)
            ELSE round(i.multiplier::numeric * il.pricelimit * il.qtyinvoiced, 2)
        END AS linelimitamt, round(i.multiplier::numeric * il.pricelist * il.qtyinvoiced - il.linenetamt, 2) AS linediscountamt, 
        CASE
            WHEN il.pricelimit IS NULL THEN 0::numeric
            ELSE round(i.multiplier::numeric * il.linenetamt - il.pricelimit * il.qtyinvoiced, 2)
        END AS lineoverlimitamt
   FROM c_invoice_v2 i, c_invoiceline il, m_product p
  WHERE i.c_invoice_id::text = il.c_invoice_id::text AND il.m_product_id::text = p.m_product_id::text;


CREATE  VIEW c_invoice_day AS 
 SELECT c_invoiceline_v2.ad_client_id, c_invoiceline_v2.ad_org_id, c_invoiceline_v2.salesrep_id, date_trunc('day'::text, c_invoiceline_v2.dateinvoiced) AS dateinvoiced, sum(c_invoiceline_v2.linenetamt) AS linenetamt, sum(c_invoiceline_v2.linelistamt) AS linelistamt, sum(c_invoiceline_v2.linelimitamt) AS linelimitamt, sum(c_invoiceline_v2.linediscountamt) AS linediscountamt, 
        CASE sum(c_invoiceline_v2.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(c_invoiceline_v2.linelistamt) - sum(c_invoiceline_v2.linenetamt)) / sum(c_invoiceline_v2.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(c_invoiceline_v2.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(c_invoiceline_v2.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(c_invoiceline_v2.linenetamt) - sum(c_invoiceline_v2.lineoverlimitamt)) / sum(c_invoiceline_v2.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit
   FROM c_invoiceline_v2
  GROUP BY c_invoiceline_v2.ad_client_id, c_invoiceline_v2.ad_org_id, c_invoiceline_v2.salesrep_id, date_trunc('day'::text, c_invoiceline_v2.dateinvoiced);


CREATE  VIEW c_invoice_month AS 
 SELECT c_invoiceline_v2.ad_client_id, c_invoiceline_v2.ad_org_id, c_invoiceline_v2.salesrep_id, date_trunc('month'::text, c_invoiceline_v2.dateinvoiced) AS dateinvoiced, sum(c_invoiceline_v2.linenetamt) AS linenetamt, sum(c_invoiceline_v2.linelistamt) AS linelistamt, sum(c_invoiceline_v2.linelimitamt) AS linelimitamt, sum(c_invoiceline_v2.linediscountamt) AS linediscountamt, 
        CASE sum(c_invoiceline_v2.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(c_invoiceline_v2.linelistamt) - sum(c_invoiceline_v2.linenetamt)) / sum(c_invoiceline_v2.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(c_invoiceline_v2.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(c_invoiceline_v2.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(c_invoiceline_v2.linenetamt) - sum(c_invoiceline_v2.lineoverlimitamt)) / sum(c_invoiceline_v2.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit
   FROM c_invoiceline_v2
  GROUP BY c_invoiceline_v2.ad_client_id, c_invoiceline_v2.ad_org_id, c_invoiceline_v2.salesrep_id, date_trunc('month'::text, c_invoiceline_v2.dateinvoiced);

CREATE  VIEW c_invoice_prodmonth AS 
 SELECT il.ad_client_id, il.ad_org_id, il.m_product_category_id, date_trunc('month'::text, il.dateinvoiced) AS dateinvoiced, sum(il.linenetamt) AS linenetamt, sum(il.linelistamt) AS linelistamt, sum(il.linelimitamt) AS linelimitamt, sum(il.linediscountamt) AS linediscountamt, 
        CASE sum(il.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(il.linelistamt) - sum(il.linenetamt)) / sum(il.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(il.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(il.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(il.linenetamt) - sum(il.lineoverlimitamt)) / sum(il.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit, sum(il.qtyinvoiced) AS qtyinvoiced
   FROM c_invoiceline_v2 il
  GROUP BY il.ad_client_id, il.ad_org_id, il.m_product_category_id, date_trunc('month'::text, il.dateinvoiced);

  
CREATE  VIEW c_invoice_vendormonth AS 
 SELECT il.ad_client_id, il.ad_org_id, po.c_bpartner_id, date_trunc('month'::text, il.dateinvoiced) AS dateinvoiced, sum(il.linenetamt) AS linenetamt, sum(il.linelistamt) AS linelistamt, sum(il.linelimitamt) AS linelimitamt, sum(il.linediscountamt) AS linediscountamt, 
        CASE sum(il.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(il.linelistamt) - sum(il.linenetamt)) / sum(il.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(il.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(il.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(il.linenetamt) - sum(il.lineoverlimitamt)) / sum(il.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit, sum(il.qtyinvoiced) AS qtyinvoiced
   FROM c_invoiceline_v2 il, m_product_po po
  WHERE il.m_product_id::text = po.m_product_id::text
  GROUP BY il.ad_client_id, il.ad_org_id, po.c_bpartner_id, date_trunc('month'::text, il.dateinvoiced);

  
CREATE  VIEW c_invoice_customerprodqtr AS 
 SELECT il.ad_client_id, il.ad_org_id, il.c_bpartner_id, il.m_product_category_id, date_trunc('quarter'::text, il.dateinvoiced) AS dateinvoiced, sum(il.linenetamt) AS linenetamt, sum(il.linelistamt) AS linelistamt, sum(il.linelimitamt) AS linelimitamt, sum(il.linediscountamt) AS linediscountamt, 
        CASE sum(il.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(il.linelistamt) - sum(il.linenetamt)) / sum(il.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(il.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(il.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(il.linenetamt) - sum(il.lineoverlimitamt)) / sum(il.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit, sum(il.qtyinvoiced) AS qtyinvoiced
   FROM c_invoiceline_v2 il
  GROUP BY il.ad_client_id, il.ad_org_id, il.c_bpartner_id, il.m_product_category_id, date_trunc('quarter'::text, il.dateinvoiced);

CREATE  VIEW c_invoice_customervendqtr AS 
 SELECT il.ad_client_id, il.ad_org_id, il.c_bpartner_id, po.c_bpartner_id AS vendor_id, date_trunc('quarter'::text, il.dateinvoiced) AS dateinvoiced, sum(il.linenetamt) AS linenetamt, sum(il.linelistamt) AS linelistamt, sum(il.linelimitamt) AS linelimitamt, sum(il.linediscountamt) AS linediscountamt, 
        CASE sum(il.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(il.linelistamt) - sum(il.linenetamt)) / sum(il.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(il.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(il.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(il.linenetamt) - sum(il.lineoverlimitamt)) / sum(il.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit, sum(il.qtyinvoiced) AS qtyinvoiced
   FROM c_invoiceline_v2 il, m_product_po po
  WHERE il.m_product_id::text = po.m_product_id::text
  GROUP BY il.ad_client_id, il.ad_org_id, il.c_bpartner_id, po.c_bpartner_id, date_trunc('quarter'::text, il.dateinvoiced);

CREATE  VIEW c_invoice_week AS 
 SELECT c_invoiceline_v2.ad_client_id, c_invoiceline_v2.ad_org_id, c_invoiceline_v2.salesrep_id, date_trunc('week'::text, c_invoiceline_v2.dateinvoiced) AS dateinvoiced, sum(c_invoiceline_v2.linenetamt) AS linenetamt, sum(c_invoiceline_v2.linelistamt) AS linelistamt, sum(c_invoiceline_v2.linelimitamt) AS linelimitamt, sum(c_invoiceline_v2.linediscountamt) AS linediscountamt, 
        CASE sum(c_invoiceline_v2.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(c_invoiceline_v2.linelistamt) - sum(c_invoiceline_v2.linenetamt)) / sum(c_invoiceline_v2.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(c_invoiceline_v2.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(c_invoiceline_v2.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(c_invoiceline_v2.linenetamt) - sum(c_invoiceline_v2.lineoverlimitamt)) / sum(c_invoiceline_v2.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit
   FROM c_invoiceline_v2
  GROUP BY c_invoiceline_v2.ad_client_id, c_invoiceline_v2.ad_org_id, c_invoiceline_v2.salesrep_id, date_trunc('week'::text, c_invoiceline_v2.dateinvoiced);

CREATE  VIEW c_invoice_prodweek AS 
 SELECT il.ad_client_id, il.ad_org_id, il.m_product_category_id, date_trunc('week'::text, il.dateinvoiced) AS dateinvoiced, sum(il.linenetamt) AS linenetamt, sum(il.linelistamt) AS linelistamt, sum(il.linelimitamt) AS linelimitamt, sum(il.linediscountamt) AS linediscountamt, 
        CASE sum(il.linelistamt)
            WHEN 0 THEN 0::numeric
            ELSE round((sum(il.linelistamt) - sum(il.linenetamt)) / sum(il.linelistamt) * 100::numeric, 2)
        END AS linediscount, sum(il.lineoverlimitamt) AS lineoverlimitamt, 
        CASE sum(il.linenetamt)
            WHEN 0 THEN 0::numeric
            ELSE 100::numeric - round((sum(il.linenetamt) - sum(il.lineoverlimitamt)) / sum(il.linenetamt) * 100::numeric, 2)
        END AS lineoverlimit, sum(il.qtyinvoiced) AS qtyinvoiced
   FROM c_invoiceline_v2 il
  GROUP BY il.ad_client_id, il.ad_org_id, il.m_product_category_id, date_trunc('week'::text, il.dateinvoiced);

-- Only SKR3-SKR4   
select zsse_DropView ('c_europeantrades_sell_v');

create or replace view c_europeantrades_sell_v as     
select
    max(f.fact_acct_group_id) as c_europeantrades_sell_v_id,
    f.ad_client_id  ,
    f.ad_org_id   ,
    'Y'::varchar(1)   as    isactive  ,
    max(f.created)     as   created  ,
    max(f.createdby)   as  createdby ,
    max(f.updated)     as  updated  ,
    max(f.updatedby)    as  updatedby   ,
    sum(f.amtacctcr-f.amtacctdr) as amount,
    f.acctvalue,
    f.uidnumber,
    f.c_bpartner_id,
    f.c_period_id
from fact_acct f,c_elementvalue v,ad_orginfo i left join c_location l on l.c_location_id=i.c_location_id 
                                               left join c_country c on l.c_country_id=c.c_country_id
     where
     i.ad_org_id=f.ad_org_id
     and v.c_elementvalue_id=f.account_id
     and f.uidnumber is not null 
     and coalesce(c.countrycode,'DE')!=substr(f.uidnumber,1,2)
     and (case when v.c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' then v.value like '14%' else v.value like '12%' end or (length(v.value)=5 and substr(v.value,1,1) in ('1','2','3','4','5','6')))    
     group by f.ad_client_id,f.ad_org_id,f.acctvalue,f.uidnumber,f.c_bpartner_id,f.c_period_id;

-- Only SKR3-SKR4     
select zsse_DropView ('c_europeantrades_purchase_v');

create or replace view c_europeantrades_purchase_v as     
select
    max(f.fact_acct_group_id) as c_europeantrades_purchase_v_id,
    f.ad_client_id  ,
    f.ad_org_id   ,
    'Y'::varchar(1)   as    isactive  ,
    max(f.created)     as   created  ,
    max(f.createdby)   as  createdby ,
    max(f.updated)     as  updated  ,
    max(f.updatedby)    as  updatedby   ,
    sum(f.amtacctdr-f.amtacctcr) as amount,
    f.acctvalue,
    f.uidnumber,
    f.c_bpartner_id,
    f.c_period_id
from fact_acct f,c_elementvalue v,ad_orginfo i left join c_location l on l.c_location_id=i.c_location_id 
                                               left join c_country c on l.c_country_id=c.c_country_id
     where
     i.ad_org_id=f.ad_org_id
     and v.c_elementvalue_id=f.account_id
     and f.uidnumber is not null 
     and coalesce(c.countrycode,'DE')!=substr(f.uidnumber,1,2)
     and (case when v.c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' then v.value like '16%' else v.value like '33%' end or (length(v.value)=5 and substr(v.value,1,1) in ('7','8','9')))
     group by f.ad_client_id,f.ad_org_id,f.acctvalue,f.uidnumber,f.c_bpartner_id,f.c_period_id;
   
   
   
 
CREATE OR REPLACE FUNCTION c_getpoprice(p_product_id varchar,p_validfrom timestamp without time zone,p_org_id varchar,p_currency_id varchar) returns numeric AS $_$
DECLARE
    v_refcur varchar;
    v_price numeric;
BEGIN
    select c_currency_id into v_refcur from ad_org_acctschema,c_acctschema where c_acctschema.c_acctschema_id=ad_org_acctschema.c_acctschema_id and ad_org_acctschema.ad_org_id=p_org_id;
    if v_refcur is null then
        select c_currency_id into v_refcur from ad_client where ad_client_id='C726FEC915A54A0995C568555DA5BB3C';
    end if;
    select c_currency_convert(his.pricepo,po.c_currency_id,v_refcur,validfrom) into v_price from m_product_po po, m_product_po_history his 
           join
            (select max(COALESCE(phis.qualityrating,0)) as qualityrating,m_product_po_id
            from m_product_po_history phis
            group by m_product_po_id,validfrom) ppo
            on ppo.m_product_po_id=his.m_product_po_id and ppo.qualityrating=his.qualityrating 
           where 
           po.m_product_po_id=his.m_product_po_id and po.m_product_id=p_product_id and his.validfrom<=p_validfrom limit 1;
    return v_price;
END; 
$_$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION c_getsoprice(p_product_id varchar,p_validfrom timestamp without time zone,p_org_id varchar,p_currency_id varchar) returns numeric AS $_$
DECLARE
    v_refcur varchar;
    v_plvid varchar;
    v_pricelist varchar;
    v_gross varchar;
    v_price numeric;
    v_stdtax varchar;
    v_rate numeric;
BEGIN
    select c_currency_id,c_tax_id into v_refcur,v_stdtax from ad_org_acctschema,c_acctschema where c_acctschema.c_acctschema_id=ad_org_acctschema.c_acctschema_id and ad_org_acctschema.ad_org_id=p_org_id;
    if v_refcur is null then
        select c_currency_id into v_refcur from ad_client where ad_client_id='C726FEC915A54A0995C568555DA5BB3C';
    end if;
    SELECT M_PRICELIST_id,istaxincluded into v_pricelist,v_gross from M_PRICELIST where ad_org_id=p_org_id and isdefault='Y' and issopricelist='Y' and c_currency_id=p_currency_id;
    if v_pricelist is null then
        SELECT M_PRICELIST_id,istaxincluded into v_pricelist,v_gross from M_PRICELIST where isdefault='Y' and issopricelist='Y' and c_currency_id=p_currency_id;
    end if;
    SELECT M_PRICELIST_VERSION_ID  INTO v_plvid  FROM M_PRICELIST_VERSION
            WHERE M_PRICELIST_ID=v_pricelist and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=v_pricelist and VALIDFROM<=p_validfrom); 
    /*
    if p_product_id='AFE99F4A721D471781857C3772CBAA81' and to_char(p_validfrom,'dd.mm.yyyy')= '18.11.2015' then
        raise exception '%',coalesce(v_pricelist,'##')||p_validfrom||coalesce(v_plvid,'YY')||coalesce(p_org_id,'ORG')||coalesce(p_currency_id,'CUR');
    end if;
    */
    select m_bom_pricestd(p_product_id,v_plvid,null,null,null) into v_price;
    if v_gross='Y' then
        select coalesce(coalesce(pc.c_tax_id,pc.c_tax_id),v_stdtax) into v_stdtax  from m_product_category pc,m_product p where pc.m_product_category_id=p.m_product_category_id and p.m_product_id=p_product_id;
        select rate into v_rate from c_tax where c_tax_id=v_stdtax;
        if v_rate>0 then
            v_price:=round(v_price-v_price/(1+100/v_rate),2);
        end if;
    end if;
    select c_currency_convert(v_price,p_currency_id,v_refcur,p_validfrom) into v_price;
    return v_price;
END; 
$_$ LANGUAGE plpgsql;
   
   
select zsse_DropView ('m_purchasesalesprice_overview');

create or replace view m_purchasesalesprice_overview as  
select max(m_purchasesalesprice_overview_id) as m_purchasesalesprice_overview_id,
         m_product_id,validfrom,c_currency_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_uom_id,m_product_category_id,value,
         name,typeofproduct,
         c_getpoprice(m_product_id,validfrom,ad_org_id,c_currency_id) as pricepo,
         c_getsoprice(m_product_id,validfrom,ad_org_id,c_currency_id) as price,
         c_getsoprice(m_product_id,validfrom,ad_org_id,c_currency_id)-c_getpoprice(m_product_id,validfrom,ad_org_id,c_currency_id) as margine,
         case when coalesce(c_getsoprice(m_product_id,validfrom,ad_org_id,c_currency_id),0)>0 then 
             case when c_getsoprice(m_product_id,validfrom,ad_org_id,c_currency_id)-c_getpoprice(m_product_id,validfrom,ad_org_id,c_currency_id)>0 then round(((c_getsoprice(m_product_id,validfrom,ad_org_id,c_currency_id)-c_getpoprice(m_product_id,validfrom,ad_org_id,c_currency_id))/c_getsoprice(m_product_id,validfrom,ad_org_id,c_currency_id))*100,2) 
             else round(((c_getsoprice(m_product_id,validfrom,ad_org_id,c_currency_id)-c_getpoprice(m_product_id,validfrom,ad_org_id,c_currency_id))/c_getpoprice(m_product_id,validfrom,ad_org_id,c_currency_id))*100,2)  end
         else 0 end as Marginpercent
from
(    select
        max(p.m_productprice_id) as m_purchasesalesprice_overview_id,
        trunc(pv.validfrom) as validfrom,
        pl.c_currency_id,
        p.m_product_id ,
        p.ad_client_id  ,
        pl.ad_org_id   ,
        pp.isactive       ,
        pp.created       ,
        pp.createdby   ,
        pp.updated      ,
        pp.updatedby      ,
        pp.c_uom_id,
        pp.m_product_category_id,
        pp.value,
        pp.name,
        pp.typeofproduct
    from m_pricelist pl,m_pricelist_version pv,m_productprice p,m_product pp where
        pp.m_product_id=p.m_product_id and pl.m_pricelist_id=pv.m_pricelist_id and pv.m_pricelist_version_id=p.m_pricelist_version_id and pl.issopricelist='Y'
        and pp.issold='Y' and pp.isactive='Y' and pl.isdefault='Y' and p.c_uom_id is null
        group by pl.c_currency_id,        p.m_product_id ,        p.ad_client_id  ,        pl.ad_org_id   ,        pp.isactive       ,        pp.created       ,        pp.createdby   ,
                 pp.updated      ,        pp.updatedby              ,         pp.c_uom_id,        pp.m_product_category_id,        pp.value,        pp.name,
                 pp.typeofproduct,trunc(pv.validfrom)
    union
    select
        max(his.M_PRODUCT_PO_history_id) as m_purchasesalesprice_overview_id,
        trunc(his.validfrom) as validfrom,
        coalesce(po.c_currency_id,(select c_currency_id from ad_client where ad_client_id=po.ad_client_id)) as c_currency_id,
        po.m_product_id ,
        po.ad_client_id  ,
        po.ad_org_id   ,
        pp.isactive       ,
        pp.created       ,
        pp.createdby   ,
        pp.updated      ,
        pp.updatedby      ,
        coalesce(po.c_uom_id,pp.c_uom_id) as c_uom_id,
        pp.m_product_category_id,
        pp.value,
        pp.name,
        pp.typeofproduct
    from m_product pp, M_PRODUCT_PO po , M_PRODUCT_PO_history his
        join
            (select max(COALESCE(phis.qualityrating,0)) as qualityrating,m_product_po_id
            from m_product_po_history phis
            group by m_product_po_id,validfrom) ppo
            on ppo.m_product_po_id=his.m_product_po_id and ppo.qualityrating=his.qualityrating 
    where 
        pp.m_product_id=po.m_product_id and his.m_product_po_id=po.m_product_po_id and pp.issold='Y' and pp.isactive='Y'
        group by c_currency_id,        po.m_product_id ,        po.ad_client_id  ,        po.ad_org_id   ,        pp.isactive       ,        pp.created       ,        pp.createdby   ,
                 pp.updated      ,        pp.updatedby      ,         coalesce(po.c_uom_id,pp.c_uom_id),        pp.m_product_category_id,        pp.value,        pp.name,
                 pp.typeofproduct,trunc(his.validfrom)
) a
group by m_product_id,validfrom,c_currency_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_uom_id,m_product_category_id,value,
         name,typeofproduct; 
  
select zsse_DropView ('m_purchase4salesContracts_overview');
create or replace view m_purchase4salesContracts_overview as  
     WITH RECURSIVE bomtree (m_productbom_id, m_product_id, bomqty,c_orderline_id) AS (
               SELECT m_product_bom.m_productbom_id, m_product_bom.m_product_id, m_product_bom.bomqty,ol.c_orderline_id
                FROM m_product_bom,c_orderline ol,c_order o WHERE m_product_bom.m_product_id=ol.m_product_id 
                                                            and ol.c_order_id=o.c_order_id  and o.contractdate<=trunc(now()) and o.enddate>=trunc(now()) and o.docstatus='CO' and o.c_doctype_id='559A80F2E27742D4B2C476045F5C834F'
                                                            and (ol.qtyordered-coalesce(ol.calloffqty,0))>0
               union
               select T2.m_productbom_id, T2.m_product_id, T2.bomqty,bomtree.c_orderline_id
                    FROM m_product_bom T2 INNER JOIN bomtree ON(bomtree.m_productbom_id=T2.m_product_id))
     SELECT p.m_product_id as m_purchase4salesContracts_overview_id,
            p.m_product_id,
             string_agg(o.documentno,',') as documentno,
            p.value,
            m_product_po.vendorproductno,
            m_product_po.pricepo,
            sum(ol.qtyordered-coalesce(ol.calloffqty,0))* sum(bomtree.bomqty) as openqty,
            sum(ol.qtyordered-coalesce(ol.calloffqty,0))* sum(bomtree.bomqty) as qtytotal,
            m_product_po.pricepo  *  sum(ol.qtyordered-coalesce(ol.calloffqty,0))* sum(bomtree.bomqty) as nettotal,
            c_currency.cursymbol as cursymbol,
            cbp.name   as vendor,
            m_product_po.deliverytime_promised,
             min(o.contractdate) as contractdate,max(o.enddate) as enddate,
            p.updated,p.updatedby,p.created,p.createdby,p.isactive,p.ad_org_id,p.ad_client_id,
            sum(ov.qtyordered) as qtyordered,sum(ov.qtyorderedframe) as qtyorderedframe,sum(ov.qtyonhand) as qtyonhand
     FROM      
               bomtree,
               m_product p left join m_product_po on p.m_product_id=m_product_po.m_product_id
                           left join zssi_onhanqty_overview ov on ov.m_product_id=p.m_product_id
	       left join c_bpartner cbp on cbp.c_bpartner_id=m_product_po.c_bpartner_id
               left join c_currency on m_product_po.c_currency_id=c_currency.c_currency_id,
               c_order o,c_orderline ol 
     where 
           o.c_order_id=ol.c_order_id and ol.c_orderline_id=bomtree.c_orderline_id and
           bomtree.m_productbom_id=p.m_product_id and p.ispurchased='Y' and p.production='N'
           and m_product_po.m_product_po_id=(select m_product_po_id from m_product_po where p.m_product_id=m_product_po.m_product_id and m_product_po.ad_org_id in  ('0',p.AD_ORG_ID) and iscurrentvendor='Y' order by  coalesce(qualityrating,0) desc,updated desc limit 1 )
     group by p.m_product_id,p.value,m_product_po.vendorproductno,m_product_po.pricepo,c_currency.cursymbol,cbp.name,m_product_po.deliverytime_promised,ov.m_product_id;
                      
                      
select zsse_DropView ('c_project_details_v'); 
CREATE OR REPLACE VIEW public.c_project_details_v AS 
 SELECT pl.ad_client_id,
    pl.ad_org_id,
    pl.isactive,
    pl.created,
    pl.createdby,
    pl.updated,
    pl.updatedby,
    to_char('en_US'::text) AS ad_language,
    pj.c_project_id,
    pl.c_projectline_id,
    pl.line,
    pl.plannedqty,
    pl.plannedprice,
    pl.plannedamt,
    pl.plannedmarginamt,
    pl.committedamt,
    pl.m_product_id,
    COALESCE(p.name, pl.description) AS name,
        CASE
            WHEN p.name IS NOT NULL THEN pl.description
            ELSE NULL::character varying
        END AS description,
    p.documentnote,
    p.upc,
    p.sku,
    p.value AS productvalue,
    pl.m_product_category_id,
    pl.invoicedamt,
    pl.invoicedqty,
    pl.committedqty
   FROM c_projectline pl
     JOIN c_project pj ON pl.c_project_id::text = pj.c_project_id::text
     LEFT JOIN m_product p ON pl.m_product_id::text = p.m_product_id::text
  WHERE pl.isprinted = 'Y'::bpchar;
  
select zsse_DropView ('c_project_details_vt');   
CREATE OR REPLACE VIEW c_project_details_vt AS 
 SELECT pl.ad_client_id,
    pl.ad_org_id,
    pl.isactive,
    pl.created,
    pl.createdby,
    pl.updated,
    pl.updatedby,
    to_char('en_US'::text) AS ad_language,
    pj.c_project_id,
    pl.c_projectline_id,
    pl.line,
    pl.plannedqty,
    pl.plannedprice,
    pl.plannedamt,
    pl.plannedmarginamt,
    pl.committedamt,
    pl.m_product_id,
    COALESCE(p.name, pl.description) AS name,
        CASE
            WHEN p.name IS NOT NULL THEN pl.description
            ELSE NULL::character varying
        END AS description,
    p.documentnote,
    p.upc,
    p.sku,
    p.value AS productvalue,
    pl.m_product_category_id,
    pl.invoicedamt,
    pl.invoicedqty,
    pl.committedqty
   FROM c_projectline pl
     JOIN c_project pj ON pl.c_project_id::text = pj.c_project_id::text
     LEFT JOIN m_product p ON pl.m_product_id::text = p.m_product_id::text
  WHERE pl.isprinted = 'Y'::bpchar;

  
select zsse_DropView ('ad_systemstatistics_v');   
CREATE OR REPLACE VIEW ad_systemstatistics_v AS 
 SELECT ad_client_id,
    ad_org_id,
    isactive,
    created,
    createdby,
    updated,
    updatedby,
    (select count(*) from ad_org where ad_org_id!='0') as orgcount,
    (select case when coalesce(activation_key,'')!='' then 'L' else (select case when count(*)>0 then 'Y' else 'N' end from ad_org  where ad_org_id!='0' and isready='Y') end from ad_system limit 1) as orgready,
    (select reltuples  FROM pg_class WHERE relname = 'fact_acct') as facts,
    (select reltuples  FROM pg_class WHERE relname = 'c_order') as orders,
    (select reltuples  FROM pg_class WHERE relname = 'c_invoice') as invoices,
    (select reltuples  FROM pg_class WHERE relname = 'm_inout') as inouts,
    (select reltuples  FROM pg_class WHERE relname = 'm_product') as products,
    (select reltuples  FROM pg_class WHERE relname = 'c_project') as projects,
    (select reltuples  FROM pg_class WHERE relname = 'c_bpartner') as bpartners,
    (select reltuples  FROM pg_class WHERE relname = 'zssi_notes4customer') as crms,
    (select max(systemid) from ad_systemupdateview) as systemid,
    (select sum(namedusers) from ad_systemupdateview) as numofusers,
    (SELECT instance_key from AD_SYSTEM limit 1) as anonyminstancekey
from ad_client limit 1;
    
