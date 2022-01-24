

CREATE or replace FUNCTION bpl_getinvoicedamt(p_bpartner_Id varchar, p_startdate timestamp,p_quarter varchar) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_interval interval:=0;
v_enddate timestamp;
v_retval numeric;
BEGIN 
   v_enddate:=zssi_getLastDayOfQuarter(p_startdate,p_quarter);
   -- No Values for Future Quarters
   if (v_enddate - INTERVAL '3 month' + INTERVAL '1 day') > now() then
       return 0;
   end if; 
   select sum(case cdt.docbasetype when 'ARI' then i.totallines when 'ARC' then i.totallines*-1 else 0 end) into v_retval 
          from c_invoice i,c_doctype cdt 
          where cdt.c_doctype_id=i.c_doctype_id and
                i.docstatus='CO' and i.issotrx='Y' and
                i.c_bpartner_id=p_bpartner_Id and
               i.dateacct between p_startdate and v_enddate;
               -- Patch 1196 : i.dateinvoiced to dateacct;
   return coalesce(v_retval,0);
END; $_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION bpl_getorderedamt(p_bpartner_Id varchar, p_startdate timestamp,p_quarter varchar) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_interval interval:=0;
v_enddate timestamp;
v_orderval numeric;
v_invoiceval numeric;
v_ignoreresidueval numeric;
v_datefrom timestamp:='-infinity';
v_curr varchar;
BEGIN 
   v_enddate:=zssi_getLastDayOfQuarter(p_startdate,p_quarter);
   -- No Values for Future Quarters
   if (v_enddate - INTERVAL '3 month' + INTERVAL '1 day') > now() then
       return 0;
   end if; 
   select c_currency_id into v_curr from ad_client where ad_client_id='C726FEC915A54A0995C568555DA5BB3C';
   -- Auftragsbestand= Wert der Auftragszeile - Wert der Rechnungen zu dieser Zeilen
   -- Es zählen alle Auftrags-Zeilen, deren Wert > als der Fakturierte Wert ist und die im AWZ nicht Restschuld Befreit sind.
   select sum((case when zssi_getOrderLineValueByPeriod(ol.c_orderline_id,v_curr,v_datefrom,v_enddate)-zssi_getinvoicedamt4orderlineByPeriod(ol.c_orderline_id,v_curr,v_datefrom,v_enddate)<0 then 0 
                   else zssi_getOrderLineValueByPeriod(ol.c_orderline_id,v_curr,v_datefrom,v_enddate)-zssi_getinvoicedamt4orderlineByPeriod(ol.c_orderline_id,v_curr,v_datefrom,v_enddate) end ) *
              (case when coalesce(ol.ignoreresiduedate,v_enddate + INTERVAL '1 day') <= v_enddate then 0 else 1 end)) into v_orderval from c_order o ,c_orderline ol
          where ol.c_order_id=o.c_order_id and
                ad_get_docbasetype(o.c_doctype_id)='SOO' and
                o.docstatus='CO' and o.issotrx='Y' and
                o.c_bpartner_id=p_bpartner_Id and
                ol.dateordered <=  v_enddate; 
   /*
   -- Ordered AMT
   select sum(zssi_getOrderLineValueByPeriod(ol.c_orderline_id,v_datefrom,v_enddate)) into v_orderval from c_order o ,c_orderline ol
          where ol.c_order_id=o.c_order_id and
                ad_get_docbasetype(o.c_doctype_id)='SOO' and
                o.docstatus='CO' and o.issotrx='Y' and
                o.c_bpartner_id=p_bpartner_Id and
                ol.dateordered <=  v_enddate; 
   --Invoiced AMT on orders (If ignoresidue was set, it must be set in the future of enddate)
   select sum(zssi_getinvoicedamt4orderlineByPeriod(ol.c_orderline_id,v_datefrom,v_enddate)) into v_invoiceval
         from c_order o ,c_orderline ol
          where ol.c_order_id=o.c_order_id and
                ad_get_docbasetype(o.c_doctype_id)='SOO' and
                o.docstatus='CO' and o.issotrx='Y' and
                o.c_bpartner_id=p_bpartner_Id and
                ol.dateordered <=  v_enddate; 
   --Ignore Residue  AMT on orders, if it was set in the past of enddate
   select sum((case ol.lineNetAmt when 0 then ol.linegrossamt else ol.lineNetAmt end)-ol.invoicedamt) into v_ignoreresidueval from c_order o ,c_orderline ol
          where ol.c_order_id=o.c_order_id and
                ad_get_docbasetype(o.c_doctype_id)='SOO' and
                coalesce(ol.ignoreresiduedate,v_enddate + INTERVAL '1 day') <= v_enddate and
                o.docstatus='CO' and o.issotrx='Y' and
                o.c_bpartner_id=p_bpartner_Id and
                ol.dateordered <=  v_enddate; 
--coalesce(v_ignoreresidueval,0)
   return coalesce(v_orderval,0)-coalesce(v_invoiceval,0)-coalesce(v_ignoreresidueval,0);
*/
   return coalesce(v_orderval,0);
END; $_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION bpl_getofferedamt(p_bpartner_Id varchar, p_startdate timestamp,p_quarter varchar) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_interval interval:=0;
v_enddate timestamp;
v_retval numeric;
v_datefrom timestamp:='-infinity';
v_curr varchar;
BEGIN 
   v_enddate:=zssi_getLastDayOfQuarter(p_startdate,p_quarter);
   -- No Values for Future Quarters
   if (v_enddate - INTERVAL '3 month' + INTERVAL '1 day') > now() then
       return 0;
   end if; 
   select c_currency_id into v_curr from ad_client where ad_client_id='C726FEC915A54A0995C568555DA5BB3C';
   -- In Open Proposals, variant don't count(they have orderselfjoin ->Docstatus is Completed
   -- In Closed Proposals, either they are accepted -> (they have orderselfjoin to the order)->Docstatus is Closed
   --                      or they are lost,closed (LO,CL) -> (they only count without orderselfjoin)->Docstatus is Closed
   select sum(zssi_getOrderLineValueByPeriod(ol.c_orderline_id,v_curr,v_datefrom,v_enddate))  into v_retval 
          from c_order o,c_orderline ol
          where ad_get_docbasetype(o.c_doctype_id)='SALESOFFER' and
                o.issotrx='Y' and
                ol.c_order_id=o.c_order_id and
                o.c_bpartner_id=p_bpartner_Id and
                case o.proposalstatus when 'OP' then (o.docstatus='CO' and c_isofferrelevant(o.c_order_id)='Y' ) when 'AC' then (o.docstatus='CL') else  (o.docstatus='CL' and c_isofferrelevant(o.c_order_id)='Y')  end  and
                o.docstatus in ('CO','CL') and
                (o.proposalstatus='OP' or (o.proposalstatus!='OP' and o.updated >= v_enddate)) and
                ol.dateordered <= v_enddate;
   return coalesce(v_retval,0);
END; $_$  LANGUAGE 'plpgsql';





select zsse_DropView ('bpl_salesforecastbase_v');
CREATE OR REPLACE VIEW bpl_salesforecastbase_v AS 
        SELECT  sfc.mrp_salesforecast_id AS bpl_salesforecast_id,
                        bpl_getinvoicedamt(sfc.c_bpartner_id,sfc.startdate,'1Q') as invoicedamtfirstquarter,
                        bpl_getinvoicedamt(sfc.c_bpartner_id,sfc.startdate,'2Q') as invoicedamtsecondquarter,
                        bpl_getinvoicedamt(sfc.c_bpartner_id,sfc.startdate,'3Q') as invoicedamtthirdquarter,
                        bpl_getinvoicedamt(sfc.c_bpartner_id,sfc.startdate,'4Q') as invoicedamtfourthquarter,
                        bpl_getorderedamt(sfc.c_bpartner_id,sfc.startdate,'1Q') as orderedamtfirstquarter,
                        bpl_getorderedamt(sfc.c_bpartner_id,sfc.startdate,'2Q') as orderedamtsecondquarter,
                        bpl_getorderedamt(sfc.c_bpartner_id,sfc.startdate,'3Q') as orderedamtthirdquarter,
                        bpl_getorderedamt(sfc.c_bpartner_id,sfc.startdate,'4Q') as orderedamtfourthquarter,
                        bpl_getofferedamt(sfc.c_bpartner_id,sfc.startdate,'1Q') as offeredamtfirstquarter,
                        bpl_getofferedamt(sfc.c_bpartner_id,sfc.startdate,'2Q') as offeredamtsecondquarter,
                        bpl_getofferedamt(sfc.c_bpartner_id,sfc.startdate,'3Q') as offeredamtthirdquarter,
                        bpl_getofferedamt(sfc.c_bpartner_id,sfc.startdate,'4Q') as offeredamtfourthquarter
        FROM mrp_salesforecast sfc;

select zsse_droptable('bpl_salesforecastbase');

create table bpl_salesforecastbase as select * from bpl_salesforecastbase_v where bpl_salesforecast_id='ÄÄ';


select zsse_DropView ('bpl_salesforecast');
CREATE OR REPLACE VIEW bpl_salesforecast AS 
        SELECT          sfc.mrp_salesforecast_id AS bpl_salesforecast_id,
                        sfc.ad_client_id,
                        sfc.ad_org_id,
                        sfc.isactive,
                        sfc.created,
                        sfc.createdby,
                        sfc.updated,
                        sfc.updatedby,
                        sfc.c_bpartner_id,
                        sfc.description,
                        sfc.salesrep_id,
                        sfc.ad_user_id,
                        sfc.issotrx,
                        sfc.estpropability,
                        sfc.startdate,
                        sfc.linenetamt,
                        sfc.adjusted_startdate,
                        sfc.adjusted_enddate,
                        sfc.adjusted_amt,
                        sfb.invoicedamtfirstquarter,
                        sfb.invoicedamtsecondquarter,
                        sfb.invoicedamtthirdquarter,
                        sfb.invoicedamtfourthquarter,
                        sfb.orderedamtfirstquarter,
                        sfb.orderedamtsecondquarter,
                        sfb.orderedamtthirdquarter,
                        sfb.orderedamtfourthquarter,
                        sfb.offeredamtfirstquarter,
                        sfb.offeredamtsecondquarter,
                        sfb.offeredamtthirdquarter,
                        sfb.offeredamtfourthquarter,
						c_bpartner.rating
        FROM mrp_salesforecast sfc 
		left join bpl_salesforecastbase sfb on sfc.mrp_salesforecast_id=sfb.bpl_salesforecast_id
		left join c_bpartner on c_bpartner.c_bpartner_id = sfc.c_bpartner_id;


create or replace rule bpl_salesforecast_delete as
on delete to bpl_salesforecast do instead
delete from mrp_salesforecast where
        mrp_salesforecast.mrp_salesforecast_id = old.bpl_salesforecast_id;

create or replace rule bpl_salesforecast_insert as
on insert to bpl_salesforecast do instead 
    insert into mrp_salesforecast (mrp_salesforecast_id,
                        ad_client_id,
                        ad_org_id,
                        isactive,
                        created,
                        createdby,
                        updated,
                        updatedby,
                        c_bpartner_id,
                        description,
                        salesrep_id,
                        ad_user_id,
                        issotrx,
                        estpropability,
                        startdate,
                        linenetamt,
                        adjusted_startdate,
                        adjusted_enddate,
                        adjusted_amt)
    values (get_uuid(),new.ad_client_id,
                        new.ad_org_id,
                        new.isactive,
                        new.created,
                        new.createdby,
                        new.updated,
                        new.updatedby,
                        new.c_bpartner_id,
                        new.description,
                        new.salesrep_id,
                        new.ad_user_id,
                        'Y'::bpchar,
                        new.estpropability,
                        new.startdate,
                        new.linenetamt,
                        new.adjusted_startdate,
                        new.adjusted_enddate,
                        new.adjusted_amt);

create or replace rule bpl_salesforecast_update as
on update to bpl_salesforecast do instead 
      update mrp_salesforecast set
             ad_client_id=new.ad_client_id,
                        ad_org_id=new.ad_org_id,
                        isactive=new.isactive,
                        created=new.created,
                        createdby=new.createdby,
                        updated=new.updated,
                        updatedby=new.updatedby,
                        c_bpartner_id=new.c_bpartner_id,
                        description=new.description,
                        salesrep_id=new.salesrep_id,
                        ad_user_id=new.ad_user_id,
                        issotrx=new.issotrx,
                        estpropability=new.estpropability,
                        startdate=new.startdate,
                        linenetamt=new.linenetamt,
                        adjusted_startdate=new.adjusted_startdate,
                        adjusted_enddate=new.adjusted_enddate,
                        adjusted_amt=new.adjusted_amt
       where mrp_salesforecast_id=new.bpl_salesforecast_id;





CREATE or replace FUNCTION bpl_salesforecastupdate() RETURNS character varying
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

*****************************************************/
DECLARE
-- Simple Types
i integer;
BEGIN
   
      truncate table bpl_salesforecastbase;
      insert into bpl_salesforecastbase select * from bpl_salesforecastbase_v;
      GET DIAGNOSTICS i := ROW_COUNT; 
      return  i || ' Salesforecasts Updated.';
END ; $_$ LANGUAGE 'plpgsql';

