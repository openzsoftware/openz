 
CREATE OR REPLACE FUNCTION zsfi_budget_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/

v_cur record;
v_priodbudget numeric;
v_count numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   if (TG_OP = 'INSERT' or TG_OP = 'UPDATE') then
      if new.ad_org_id='0' then
        raise exception '%', '@OrgZeroNotAllowedHere@';
      end if;
      --if new.budget<=0 then
      --  raise exception '%', '@NeedtoDefineaPositiveBudget@';
      --end if;
   end if;
   if TG_OP = 'UPDATE' then
      
   end if;   
   if (TG_OP = 'INSERT' or TG_OP = 'UPDATE') then
     select count(*) into v_count from c_period where c_year_id=new.c_year_id;
     if v_count>0 and (select count(*) from zsfi_budgetperiod where zsfi_budget_id = new.zsfi_budget_id)=0 then
        v_priodbudget:=new.budget/v_count;
        for v_cur in (select c_period_id,startdate,enddate from c_period where c_year_id=new.c_year_id)
        loop
            insert into zsfi_budgetperiod ( zsfi_budgetperiod_id, zsfi_budget_id, ad_client_id, ad_org_id, createdby, updatedby, c_period_id,datefrom, dateto, budget)
            values (get_uuid(),new.zsfi_budget_id,new.ad_client_id,new.ad_org_id, new.createdby, new.updatedby, v_cur.c_period_id,v_cur.startdate,v_cur.enddate,v_priodbudget);
        end loop;
      end if;
   end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


select zsse_droptrigger('zsfi_budget_trg','zsfi_budget');

CREATE TRIGGER zsfi_budget_trg
  AFTER INSERT or update
  ON zsfi_budget
  FOR EACH ROW
  EXECUTE PROCEDURE zsfi_budget_trg();
  
CREATE OR REPLACE FUNCTION zsfi_budgetperiod_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/

v_cur record;
v_priodbudget numeric;
v_count numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   
    
   if ( TG_OP = 'UPDATE') then
     update zsfi_budget set budget=budget-old.budget+new.budget where zsfi_budget_id=new.zsfi_budget_id;
   end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


select zsse_droptrigger('zsfi_budgetperiod_trg','zsfi_budgetperiod');

CREATE TRIGGER zsfi_budgetperiod_trg
  AFTER update
  ON zsfi_budgetperiod
  FOR EACH ROW
  EXECUTE PROCEDURE zsfi_budgetperiod_trg();
    

CREATE OR REPLACE FUNCTION zsfi_getbbudgetsum(bwapref_id character varying,date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying,isVJ character varying) RETURNS numeric
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
Sub-Fuction for BWA-Report
Gets the Total of a specific BWA (All Accounts defined in it)
Part of Finance
*****************************************************/
v_cur RECORD;
v_sum numeric:=0;
v_sum_faktura numeric;
v_sum_nofaktura numeric;
v_sum_orderamt numeric;
v_runratefaktura numeric;
v_runratenofaktura   numeric;
v_runrateorder numeric;
v_ford numeric;
v_verb numeric;
v_return numeric:=0;
v_adddays numeric;
v_acctmatch character varying;
BEGIN 

      if isVJ='Y' then v_adddays:=365; else v_adddays:=0; end if; 
      for v_cur in (select * from zspr_child_bwap(bwapref_id) union 
                    select * from zspr_bwaprefs where zspr_bwaprefs_id =bwapref_id
                    and not exists (select 0  from zspr_bwaprefs where parentpref=bwapref_id))
      LOOP
        if v_cur.isparent='N' then
           -- Statistical Accounts
                 select summe into v_sum from (
                    select SUM(zsfi_budgetperiod.budget) as summe
                    from zsfi_budgetperiod,zsfi_budget,c_elementvalue,ad_org_acctschema,zspr_bwaprefacct bwaprefacct where 
                          zsfi_budgetperiod.zsfi_budget_id=zsfi_budget.zsfi_budget_id and zsfi_budget.c_elementvalue_id=c_elementvalue.c_elementvalue_id and
                          ad_org_acctschema.ad_org_id=v_org and
                          zsfi_budget.ad_org_id=v_org
                          and v_cur.isactive='Y'  
                          and bwaprefacct.zspr_bwaprefs_id=v_cur.zspr_bwaprefs_id 
                          and c_elementvalue.VALUE like replace(bwaprefacct.acctmatch,'*','%')
                          and case when instr(bwaprefacct.acctmatch,'*')>0 then length(c_elementvalue.VALUE)=5 else length(c_elementvalue.VALUE)=4 end
                          and bwaprefacct.c_acctschema_id=ad_org_acctschema.c_acctschema_id
                          and trunc(zsfi_budgetperiod.datefrom)+v_adddays >= trunc(date_from) and trunc(zsfi_budgetperiod.dateto)+v_adddays <= trunc(date_to) 
                    ) a ;
            v_return:=v_return+coalesce(v_sum,0);
          end if;
      END LOOP;
      return coalesce(v_return,0);
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsfi_getbbudgetsum(bwapref_id character varying,account_id varchar,date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying,isVJ character varying) RETURNS numeric
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
Sub-Fuction for BWA-Report
Gets the Total of a specific BWA (All Accounts defined in it)
Part of Finance
*****************************************************/
v_cur RECORD;
v_sum numeric:=0;
v_sum_faktura numeric;
v_sum_nofaktura numeric;
v_sum_orderamt numeric;
v_runratefaktura numeric;
v_runratenofaktura   numeric;
v_runrateorder numeric;
v_ford numeric;
v_verb numeric;
v_return numeric:=0;
v_adddays numeric;
v_acctmatch character varying;
BEGIN 
      if isVJ='Y' then v_adddays:=365; else v_adddays:=0; end if; 
      for v_cur in (select * from zspr_bwaprefs where zspr_bwaprefs_id =bwapref_id)
      LOOP
        if v_cur.isparent='N' then
           -- Statistical Accounts
                 select summe into v_sum from (
                    select SUM(zsfi_budgetperiod.budget) as summe
                    from zsfi_budgetperiod,zsfi_budget where 
                          zsfi_budgetperiod.zsfi_budget_id=zsfi_budget.zsfi_budget_id and
                          zsfi_budget.c_elementvalue_id=account_id and
                          zsfi_budget.ad_org_id=v_org
                          and v_cur.isactive='Y'  
                          and trunc(zsfi_budgetperiod.datefrom)+v_adddays >= trunc(date_from) and trunc(zsfi_budgetperiod.dateto)+v_adddays <= trunc(date_to) 
                    ) a ;
            v_return:=v_return+coalesce(v_sum,0);
          end if;
      END LOOP;
      return coalesce(v_return,0);
END;
$_$  LANGUAGE 'plpgsql';
