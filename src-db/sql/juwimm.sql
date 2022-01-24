SELECT zsse_DropView ('juwimm_orderstatus_controlling_v');
-- SELECT * FROM juwimm_orderstatus_controlling_v;
CREATE OR REPLACE VIEW juwimm_orderstatus_controlling_v
AS
-- SELECT zsse_dropview('juwimm_orderstatus_controlling_v');
-- SELECT * FROM juwimm_orderstatus_controlling_v;
SELECT
  ord.c_order_id AS juwimm_orderstatus_controlling_v_id,
  ord.c_order_id AS c_order_id,
  ord.ad_client_id AS ad_client_id,
  ord.ad_org_id AS ad_org_id,
  ord.issotrx AS issotrx,
  ord.documentno AS documentno,
  ord.docstatus AS docstatus,
  ord.docaction AS docaction,
  ord.c_bpartner_id,
  ord.salesrep_id,
  ord.name,
  ord.iscompletelyinvoiced,
-- LEFT JOIN c_project
  ord.c_project_id,
  prj.value AS project_value,
  prj.name AS project_name,
  ord.totallines,
  ord.ad_user_id,
-- INNER JOIN juwimm_orderstatus
  ost.created,
  ost.createdby,
  ost.updated,
  ost.updatedby,
  ost.isactive,
--
  ost.juwimm_completion,
  ost.juwimm_time,
  ost.juwimm_resources,
  ost.juwimm_budget,
  ost.juwimm_team_id,
  ost.juwimm_plannedgolive,
  ost.juwimm_estgolive,
  ost.juwimm_nextimpdate,
  ost.juwimm_plannedstart,
  ost.juwimm_eststart,
  ost.juwimm_plannedend,
  ost.juwimm_estend,
  ost.juwimm_ouputremarks,
  ost.juwimm_lastaction,
  ost.juwimm_nextaction,
  ost.juwimm_issues,
  ost.juwimm_decisions
FROM
  c_order ord
  LEFT JOIN c_project prj ON prj.c_project_id = ord.c_project_id
  LEFT JOIN juwimm_orderstatus ost ON ost.c_order_id = ord.c_order_id
  WHERE ord.c_doctype_id = '5D5792C53FBA46E2988653B6DC9FE5B4';
-- WHERE ord.c_order_id = ost.c_order_id;


CREATE OR REPLACE FUNCTION juwimm_orderstatus_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_count numeric;
v_pref varchar;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'INSERT' THEN 
       select count(*) into v_count from juwimm_orderstatus where c_order_id=new.c_order_id;
       if v_count>=1 then  
          raise exception '%', '@zssi_OnlyOneDS@';
       end if;
   end if;
   IF TG_OP = 'DELETE' then 
      raise exception '%', '@DeleteError@';
   END IF;
   IF TG_OP = 'UPDATE' then 
      select count(*) into v_count from ad_user u,ad_role r,ad_preference_access pa,ad_preference p,ad_user_roles ur
                                   where p.attribute='JUWIORDERSTATUSADMIN' and p.ad_preference_id=pa.ad_preference_id and
                                         pa.ad_role_id=r.ad_role_id and ur.ad_role_id=r.ad_role_id and ur.ad_user_id=new.updatedby;
      if v_count=0 then
         if old.juwimm_plannedgolive!=new.juwimm_plannedgolive or
            old.juwimm_plannedstart!=new.juwimm_plannedstart or
            old.juwimm_ms1planneddate!=new.juwimm_ms1planneddate or
            old.juwimm_ms2planneddate!=new.juwimm_ms2planneddate or
            old.juwimm_ms3planneddate!=new.juwimm_ms3planneddate or
            old.juwimm_ms4planneddate!=new.juwimm_ms4planneddate or
            old.juwimm_ms5planneddate!=new.juwimm_ms5planneddate or
            old.juwimm_ms6planneddate!=new.juwimm_ms6planneddate or
            old.juwimm_ms7planneddate!=new.juwimm_ms7planneddate or
            old.juwimm_plannedend!=new.juwimm_plannedend 
          then
               raise exception '%', 'Planned Dates können nicht verändert werden. Nur ein System Administrator kann dies tun.';
          end if;
      end if;
   END IF;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


select zsse_droptrigger('juwimm_orderstatus_trg','juwimm_orderstatus');

CREATE TRIGGER juwimm_orderstatus_trg
  BEFORE INSERT OR DELETE OR UPDATE
  ON juwimm_orderstatus
  FOR EACH ROW
  EXECUTE PROCEDURE juwimm_orderstatus_trg();

/*------| Order & Order Status combined view for xls export |--------------------------*\
	Description: 
	Combined view of c_order and juwimm_orderstatus for exporting to Excel.
*/---------------------------------------------------------------------------------fw--\*
SELECT zsse_DropView ('juwimm_orderstatuscomplete_v');
CREATE OR REPLACE VIEW juwimm_orderstatuscomplete_v AS
SELECT
	c_order.c_order_id AS juwimm_orderstatuscomplete_v_id,
	c_order.c_order_id AS c_order_id,
	c_order.ad_client_id AS ad_client_id,
	c_order.ad_org_id AS ad_org_id,
	c_order.isactive AS isactive,
	c_order.created AS created,
	c_order.createdby AS createdby,
	c_order.updated AS updated,
	c_order.updatedby AS updatedby,
	juwimm_orderstatus.updated AS juwimm_lastupdateon,
	juwimm_orderstatus.updatedby AS juwimm_lastupdateby,
	c_order.issotrx AS issotrx,
	c_order.documentno AS documentno,
	c_order.docstatus AS docstatus,
	c_order.docaction AS docaction,
	c_order.processing AS processing,
	c_order.processed AS processed,
	c_order.c_doctype_id AS c_doctype_id,
	c_order.c_doctypetarget_id AS c_doctypetarget_id,
	c_order.description AS description,
	c_order.isdelivered AS isdelivered,
	c_order.isinvoiced AS isinvoiced,
	c_order.isprinted AS isprinted,
	c_order.isselected AS isselected,
	c_order.salesrep_id AS salesrep_id,
	c_order.dateordered AS dateordered,
	c_order.datepromised AS datepromised,
	c_order.dateprinted AS dateprinted,
	c_order.dateacct AS dateacct,
	c_order.c_bpartner_id AS c_bpartner_id,
	c_order.billto_id AS billto_id,
	c_order.c_bpartner_location_id AS c_bpartner_location_id,
	c_order.poreference AS poreference,
	c_order.isdiscountprinted AS isdiscountprinted,
	c_order.c_currency_id AS c_currency_id,
	c_order.paymentrule AS paymentrule,
	c_order.c_paymentterm_id AS c_paymentterm_id,
	c_order.invoicerule AS invoicerule,
	c_order.deliveryrule AS deliveryrule,
	c_order.freightcostrule AS freightcostrule,
	c_order.freightamt AS freightamt,
	c_order.deliveryviarule AS deliveryviarule,
	c_order.m_shipper_id AS m_shipper_id,
	c_order.c_charge_id AS c_charge_id,
	c_order.chargeamt AS chargeamt,
	c_order.priorityrule AS priorityrule,
	c_order.totallines AS totallines,
	c_order.grandtotal AS grandtotal,
	c_order.m_warehouse_id AS m_warehouse_id,
	c_order.m_pricelist_id AS m_pricelist_id,
	c_order.istaxincluded AS istaxincluded,
	c_order.c_campaign_id AS c_campaign_id,
	c_order.c_project_id AS c_project_id,
	c_order.c_activity_id AS c_activity_id,
	c_order.posted AS posted,
	c_order.ad_user_id AS ad_user_id,
	c_order.copyfrom AS copyfrom,
	c_order.dropship_bpartner_id AS dropship_bpartner_id,
	c_order.dropship_location_id AS dropship_location_id,
	c_order.dropship_user_id AS dropship_user_id,
	c_order.isselfservice AS isselfservice,
	c_order.ad_orgtrx_id AS ad_orgtrx_id,
	c_order.user1_id AS user1_id,
	c_order.user2_id AS user2_id,
	c_order.deliverynotes AS deliverynotes,
	c_order.c_incoterms_id AS c_incoterms_id,
	c_order.incotermsdescription AS incotermsdescription,
	c_order.generatetemplate AS generatetemplate,
	c_order.delivery_location_id AS delivery_location_id,
	c_order.copyfrompo AS copyfrompo,
	c_order.c_bidproject_id AS c_bidproject_id,
	c_order.c_projectphase_id AS c_projectphase_id,
	c_order.c_projecttask_id AS c_projecttask_id,
	c_order.a_asset_id AS a_asset_id,
	c_order.m_product_id AS m_product_id,
	c_order.weight AS weight,
	c_order.qty AS qty,
	c_order.weight_uom AS weight_uom,
	c_order.bpzipcode AS bpzipcode,
	c_order.generateproject AS generateproject,
	c_order.closeproject AS closeproject,
	c_order.estpropability AS estpropability,
	c_order.name AS name,
	c_order.proposalstatus AS proposalstatus,
	c_order.orderselfjoin AS orderselfjoin,
	c_order.lostproposalreason AS lostproposalreason,
	c_order.lostproposalfixedreason AS lostproposalfixedreason,
	c_order.invoicefrequence AS invoicefrequence,
	c_order.contractdate AS contractdate,
	c_order.enddate AS enddate,
	c_order.totallinesonetime AS totallinesonetime,
	c_order.grandtotalonetime AS grandtotalonetime,
	c_order.yearly_month AS yearly_month,
	c_order.weekly_day AS weekly_day,
	c_order.monthly_day AS monthly_day,
	c_order.quarterly_month AS quarterly_month,
	c_order.invoicedamt AS invoicedamt,
	c_order.completeordervalue AS completeordervalue,
	c_order.isinvoiceafterfirstcycle AS isinvoiceafterfirstcycle,
	c_order.scheddeliverydate AS scheddeliverydate,
	c_order.firstschedinvoicedate AS firstschedinvoicedate,
	c_order.schedtransactiondate AS schedtransactiondate,
	c_order.transactiondate AS transactiondate,
	c_order.iscompletelyinvoiced AS iscompletelyinvoiced,
	c_order.totalpaid AS totalpaid,
	c_order.ispaid AS ispaid,
	c_order.isrecharge AS isrecharge,
	c_order.internalnote AS internalnote,
	c_order.btncopytemplate AS btncopytemplate,
	c_order.subscriptionchangedate AS subscriptionchangedate,
	c_order.transactionreference AS transactionreference,
	c_order.deliverycomplete AS deliverycomplete,
	juwimm_orderstatus.juwimm_orderstatus_id AS juwimm_orderstatus_id,
	juwimm_orderstatus.juwimm_projectman AS juwimm_projectman,
	juwimm_orderstatus.juwimm_completion AS juwimm_completion,
	juwimm_orderstatus.juwimm_time AS juwimm_time,
	juwimm_orderstatus.juwimm_resources AS juwimm_resources,
	juwimm_orderstatus.juwimm_budget AS juwimm_budget,
	juwimm_orderstatus.juwimm_team_id AS juwimm_team_id,
	juwimm_orderstatus.juwimm_plannedgolive AS juwimm_plannedgolive,
	juwimm_orderstatus.juwimm_estgolive AS juwimm_estgolive,
	juwimm_orderstatus.juwimm_nextimpdate AS juwimm_nextimpdate,
	juwimm_orderstatus.juwimm_plannedstart AS juwimm_plannedstart,
	juwimm_orderstatus.juwimm_eststart AS juwimm_eststart,
	juwimm_orderstatus.juwimm_milestone1 AS juwimm_milestone1,
	juwimm_orderstatus.juwimm_ms1planneddate AS juwimm_ms1planneddate,
	juwimm_orderstatus.juwimm_ms1estdate AS juwimm_ms1estdate,
	juwimm_orderstatus.juwimm_milestone2 AS juwimm_milestone2,
	juwimm_orderstatus.juwimm_ms2planneddate AS juwimm_ms2planneddate,
	juwimm_orderstatus.juwimm_ms2estdate AS juwimm_ms2estdate,
	juwimm_orderstatus.juwimm_milestone3 AS juwimm_milestone3,
	juwimm_orderstatus.juwimm_ms3planneddate AS juwimm_ms3planneddate,
	juwimm_orderstatus.juwimm_ms3estdate AS juwimm_ms3estdate,
	juwimm_orderstatus.juwimm_milestone4 AS juwimm_milestone4,
	juwimm_orderstatus.juwimm_ms4planneddate AS juwimm_ms4planneddate,
	juwimm_orderstatus.juwimm_ms4estdate AS juwimm_ms4estdate,
	juwimm_orderstatus.juwimm_milestone5 AS juwimm_milestone5,
	juwimm_orderstatus.juwimm_ms5planneddate AS juwimm_ms5planneddate,
	juwimm_orderstatus.juwimm_ms5estdate AS juwimm_ms5estdate,
	juwimm_orderstatus.juwimm_milestone6 AS juwimm_milestone6,
	juwimm_orderstatus.juwimm_ms6planneddate AS juwimm_ms6planneddate,
	juwimm_orderstatus.juwimm_ms6estdate AS juwimm_ms6estdate,
	juwimm_orderstatus.juwimm_milestone7 AS juwimm_milestone7,
	juwimm_orderstatus.juwimm_ms7planneddate AS juwimm_ms7planneddate,
	juwimm_orderstatus.juwimm_ms7estdate AS juwimm_ms7estdate,
	juwimm_orderstatus.juwimm_plannedend AS juwimm_plannedend,
	juwimm_orderstatus.juwimm_estend AS juwimm_estend,
	juwimm_orderstatus.juwimm_ouputremarks AS juwimm_ouputremarks,
	juwimm_orderstatus.juwimm_lastaction AS juwimm_lastaction,
	juwimm_orderstatus.juwimm_nextaction AS juwimm_nextaction,
	juwimm_orderstatus.juwimm_issues AS juwimm_issues,
	juwimm_orderstatus.juwimm_decisions AS juwimm_decisions,
	juwimm_orderstatus.juwimm_description AS juwimm_description
FROM c_order
LEFT JOIN juwimm_orderstatus ON juwimm_orderstatus.c_order_id = c_order.c_order_id
WHERE c_order.c_doctype_id = '5D5792C53FBA46E2988653B6DC9FE5B4';
--*/----| Order & Order Status combined view for xls export |------------------------\*--