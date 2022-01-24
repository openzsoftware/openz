 
select zsse_DropView ('tsrv_feedback_v');
create or replace view tsrv_feedback_v as
 select
 zspm_ptaskfeedback_id AS tsrv_feedback_v_id,
 ad_client_id,
 ad_org_id,
 isactive,
 created,
 createdby,
 updated,
 updatedby,
 c_project_id,
 c_projecttask_id,
 c_calendarevent_id,
 ad_user_id as employee_id,
 ma_machine_id,
 description,
 workdate,
 hour_from,
 hour_to,
 actualcostamount,
 c_salary_category_id,
 hours,
 breaktime,
 paidbreaktime,
 traveltime,
 specialtime as timeunderhelmet,
 specialtime2 as timeunderhelmet2,
 specialtime3,
 special4,
 special5,
 triggeramt as triggeramt,
 overtimehours,nighthours,issaturday,issunday,isholiday,workdate_to
 from zspm_ptaskfeedback;
 
create or replace rule tsrv_feedback_delete as
on delete to tsrv_feedback_v do instead
delete from zspm_ptaskfeedback where
       zspm_ptaskfeedback_id = old.tsrv_feedback_v_id;

       
create or replace rule tsrv_feedback_insert as
on insert to tsrv_feedback_v do instead 
    insert into zspm_ptaskfeedback(zspm_ptaskfeedback_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, c_project_id, c_projecttask_id, c_calendarevent_id, ad_user_id, ma_machine_id,
                description, workdate, hour_from, hour_to, c_salary_category_id, hours, breaktime, paidbreaktime, traveltime, specialtime, specialtime2,specialtime3, triggeramt,workdate_to,
                issaturday,issunday,isholiday,special4,special5) 
    values
            (new.tsrv_feedback_v_id,new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby, new.c_project_id, new.c_projecttask_id, new.c_calendarevent_id, new.employee_id, new.ma_machine_id,
             new.description, new.workdate, new.hour_from, new.hour_to, new.c_salary_category_id, new.hours, new.breaktime, new.paidbreaktime, new.traveltime,new.timeunderhelmet,new.timeunderhelmet2,coalesce(new.specialtime3,0),new.triggeramt,new.workdate_to,
             new.issaturday,new.issunday,new.isholiday,new.special4,new.special5);

             
create or replace rule tsrv_feedback_update as
on update to tsrv_feedback_v do instead 
      update zspm_ptaskfeedback set
        ad_org_id=new.ad_org_id,
        isactive=new.isactive,
        updated=new.updated,
        updatedby=new.updatedby,
        c_project_id=new.c_project_id,
        c_projecttask_id=new.c_projecttask_id,
        c_calendarevent_id=new.c_calendarevent_id,
        ad_user_id=new.employee_id,
        ma_machine_id=new.ma_machine_id,
        description=new.description,
        workdate=new.workdate,
        hour_from=new.hour_from,
        hour_to=new.hour_to,
        c_salary_category_id=new.c_salary_category_id,
        hours=new.hours,
        breaktime=new.breaktime,
	paidbreaktime=new.paidbreaktime,
        traveltime=new.traveltime,
        specialtime =new.timeunderhelmet,
        specialtime2 =new.timeunderhelmet2,
        specialtime3 =coalesce(new.specialtime3,0),
        triggeramt = new.triggeramt,
        workdate_to=new.workdate_to,
        issaturday=new.issaturday,
        issunday =new.issunday,
        isholiday =new.isholiday,
        special4=new.special4,
        special5=new.special5
where zspm_ptaskfeedback_id=new.tsrv_feedback_v_id;



  
CREATE OR REPLACE FUNCTION zspm_standardFeedbacklineFilter()
  RETURNS timestamp AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Sets the Standard Filter for Task Feedback Line from the TIMEFEEDBACKTHRESHHOLD

C857DA48B0FE48CA9FB12D4CC8C99223 -> Time feedback Window

*/
v_isonlyown varchar;
v_houstosee numeric;
BEGIN
   
     select to_number(value) into v_houstosee from ad_preference where attribute='TIMEFEEDBACKTHRESHHOLD' and ad_window_id='C857DA48B0FE48CA9FB12D4CC8C99223';
     return now()-(coalesce(v_houstosee,480)/24);
   
END ; $BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;

  

        
CREATE OR REPLACE FUNCTION zspm_ptaskfeedback_trg (
)
RETURNS trigger AS
-- BEFORE INSERT OR UPDATE 
$body$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
DECLARE 
 v_cur record;
 v_fbl zspm_ptaskfeedbackline%rowtype;
 v_uid varchar;
BEGIN
 -- INSERT OR UPDATE
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
  IF TG_OP in ('UPDATE','DELETE') then
    delete from zspm_ptaskfeedbackline where zspm_ptaskfeedback_id=old.zspm_ptaskfeedback_id;
  end if;
  IF TG_OP in ('INSERT','UPDATE') then
    for v_cur in (select workdate from c_workcalender where workdate between new.workdate and coalesce(new.workdate_to,new.workdate))
    LOOP 
            v_uid:=get_uuid();
            v_fbl.zspm_ptaskfeedbackline_id:=v_uid;
            v_fbl.zspm_ptaskfeedback_id:=new.zspm_ptaskfeedback_id;
            v_fbl.ad_client_id:=new.ad_client_id;
            v_fbl.ad_org_id:=new.ad_org_id;
            v_fbl.isactive:=new. isactive;
            v_fbl.created:=new.created;
            v_fbl.createdby:=new.createdby;
            v_fbl.updated:=new.updated;
            v_fbl.updatedby:=new.updatedby;
            v_fbl.c_project_id:=new.c_project_id;
            v_fbl.c_projecttask_id:=new.c_projecttask_id;
            v_fbl.ad_user_id:=new.ad_user_id;
            v_fbl.ma_machine_id :=new.ma_machine_id;
            v_fbl.description:=new.description;
            v_fbl.workdate:=v_cur.workdate;
            v_fbl.hour_from :=new.hour_from;
            v_fbl.hour_to:=new.hour_to;
            v_fbl.actualcostamount:=new.actualcostamount;
            v_fbl.isprocessed :=new.isprocessed;
            v_fbl.c_salary_category_id:=new.c_salary_category_id;
            v_fbl.hours  :=new.hours;             
            v_fbl.url:=new.url;
            v_fbl.dayhours :=new.dayhours;
            v_fbl.c_calendarevent_id:=new.c_calendarevent_id;
            v_fbl.breaktime :=new.breaktime; 
            v_fbl.paidbreaktime :=new.paidbreaktime;
            v_fbl.traveltime:=new.traveltime;
            v_fbl.specialtime  :=new.specialtime;
            v_fbl.costuom:=new.costuom;
            v_fbl.specialtime2 :=new.specialtime2;
            v_fbl.specialtime3 :=new.specialtime3;
            v_fbl.triggeramt :=new.triggeramt;
            v_fbl.billable:=new.billable;   
            v_fbl.workdate_to:=new.workdate_to;
            v_fbl.special4:=new.special4;
            v_fbl.special5:=new.special5;
            insert into zspm_ptaskfeedbackline select v_fbl.*;
            select * into v_fbl from zspm_ptaskfeedbackline where zspm_ptaskfeedbackline_id=v_uid;
    END LOOP;
    if new.workdate_to is null then 
        new.isholiday:=v_fbl.isholiday;
        new.issunday:=v_fbl.issunday;
        new.issaturday:=v_fbl.issaturday;
        new.nighthours:=v_fbl.nighthours;
        new.overtimehours:=v_fbl.overtimehours;
        new.hours:=v_fbl.hours;
        new.actualcostamount:=v_fbl.actualcostamount;
    else
        if new.isholiday='N' then
            delete from zspm_ptaskfeedbackline where zspm_ptaskfeedback_id = new.zspm_ptaskfeedback_id and isholiday='Y';
        end if;
        if new.issunday='N' then
            delete from zspm_ptaskfeedbackline where zspm_ptaskfeedback_id = new.zspm_ptaskfeedback_id and issunday='Y';
        end if;
        if new.issaturday='N' then
            delete from zspm_ptaskfeedbackline where zspm_ptaskfeedback_id = new.zspm_ptaskfeedback_id and issaturday='Y';
        end if;
        if (select count(*) from zspm_ptaskfeedbackline where zspm_ptaskfeedback_id = new.zspm_ptaskfeedback_id)>0 then
            select sum(actualcostamount),sum(hours),sum(overtimehours),sum(nighthours) 
                into new.actualcostamount,new.hours,new.overtimehours,new.nighthours
            from zspm_ptaskfeedbackline where zspm_ptaskfeedback_id = new.zspm_ptaskfeedback_id; 
        end if;
    end if;
  end if;
  IF TG_OP = 'DELETE' then
    RETURN OLD;
  else
    RETURN NEW;
  end if;
END;
$body$
LANGUAGE 'plpgsql';

        
SELECT zsse_droptrigger('zspm_ptaskfeedback_trg', 'zspm_ptaskfeedback');
CREATE TRIGGER zspm_ptaskfeedback_trg
  BEFORE INSERT  OR DELETE OR UPDATE
  ON zspm_ptaskfeedback FOR EACH ROW
  EXECUTE PROCEDURE zspm_ptaskfeedback_trg();

CREATE OR REPLACE FUNCTION zspm_ptaskfeedbackline_trg (
)
RETURNS trigger AS
-- BEFORE INSERT OR UPDATE 
$body$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Projects
CHECKS:
Restriction: 
            Only Responsible Person may take actions as Machine feedback
*****************************************************/
DECLARE 
  v_ismanager   VARCHAR;
  v_count       NUMERIC;
  v_salary_id   VARCHAR;
  v_cost        NUMERIC;
 -- p_cost        NUMERIC;

  v_nightcost       NUMERIC:=0;
  v_overtimecost       NUMERIC:=0;
  v_addfeeId    varchar;
  v_Hours       NUMERIC;
  v_c_projecttask c_projecttask%ROWTYPE;
  v_sp1 numeric:=0;
v_sp2 numeric:=0;
v_sp3 numeric:=0;
v_tr numeric:=0;
  v_cur record;
  v_bpartner varchar;
  v_nomalhours numeric;
  v_midwork numeric;
  v_nightendhour timestamp;
  v_hourfrom  timestamp;
  v_hourto timestamp;
  v_fridytosatday varchar:='N';
  v_overnight varchar:='N';
BEGIN
 -- INSERT OR UPDATE
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;

  IF TG_OP = 'DELETE' then
    -- Generated Orderline
    if old.c_orderline_id is not null then
            raise exception '@nodeletepossible@';
    end if;
    perform zspm_updateprojectstatus(null,old.c_project_id);
    RETURN OLD;
  end if;
  IF TG_OP != 'DELETE' then
            select responsible_id into new.responsible_id from c_project where c_project_id=new.c_project_id;
   end if;
  
  SELECT * FROM c_projecttask pt
  INTO v_c_projecttask -- ROWTYPE
  WHERE pt.c_projecttask_id = NEW.c_projecttask_ID;
  
  -- Check Status
  IF (v_c_projecttask.outsourcing <> 'N') THEN
    RAISE EXCEPTION '%', '@zspm_NoTimeFeedbackOnProjecttask_outsourcing@';
  END IF;
  
  if (new.ad_user_id is null and new.ma_machine_id is null) or (new.ad_user_id is not null and new.ma_machine_id is not null) then
     RAISE EXCEPTION '%', '@zspm_SelectUser@';
  end if;
  -- Cost for machines 
  IF  new.ma_machine_id IS NOT NULL THEN
     v_cost:=zsco_get_machine_cost(new.ma_machine_id,new.workdate,new.Costuom,new.ad_org_id); 
     if (v_cost is null) then
        RAISE EXCEPTION '%', '@zspm_NotCostApplies@';
     end if;
  ELSE
     -- cost for humans
     -- if not applied, select it from users - cost
     IF (NEW.c_salary_category_id IS NULL) THEN
    --  RAISE NOTICE 'TG_NAME=''%'', new.ad_user_id=%', TG_NAME, new.ad_user_id; 
        SELECT min(C_Salary_Category_id) 
        INTO v_salary_id from c_bpartner 
        WHERE c_bpartner_id = 
                   (select c_bpartner_id from ad_user where ad_user_id=new.ad_user_id) 
        AND isactive='Y';
        IF (v_salary_id IS NOT NULL) THEN
          NEW.c_salary_category_id := v_salary_id; 
        END IF;
     ELSE
        -- Select the applied cost
        v_salary_id := NEW.c_salary_category_id;
     END IF;
     
     if v_salary_id is not null then
           --select max(cost) into v_cost from c_salary_category_cost where  C_Salary_Category_id=v_salary_id and costuom='H' and datefrom<=new.workdate;
        select p_cost, p_specialtime1, p_specialtime2,p_specialtime3 into v_cost, v_sp1,v_sp2 ,v_sp3 from zsco_get_salary_cost(v_salary_id,new.workdate,'H',v_c_projecttask.ad_org_id);
        
           end if;         
     if (v_salary_id is null) then
        RAISE EXCEPTION '%', '@zspm_NotCostApplies@';
     end if;
        if (v_cost is null) then
        RAISE EXCEPTION '%', '@zspm_NotCostApplies@';
     end if;  
  END IF;
  v_hourfrom:=NEW.hour_from;
  v_hourto:=NEW.hour_to;
  IF (v_hourfrom IS NOT NULL) AND (v_hourto IS NOT NULL) THEN
  -- For date and timestamp values, the number of seconds since 1970-01-01 00:00:00 UTC
    v_Hours := (SELECT ((EXTRACT (EPOCH FROM (v_hourto - v_hourfrom))) / 3600)); -- ::NUMERIC, calculate even leap year
    -- Work around the nicht into the next day....
    if v_Hours < 0 then 
        v_Hours:= (24 + v_Hours);
    end if;
    v_Hours:=v_Hours-coalesce(new.breaktime,0)-coalesce(new.paidbreaktime,0);
    NEW.hours := round(v_Hours, 2); -- 15 min = 0.25 hours
    -- Fist reset all additional fees
    new.issunday:='N';
    new.issaturday:='N';
    new.isholiday:='N';
    new.nighthours:=0;
    new.overtimehours:=0;
    -- Regelarbeitszeit (NUR Personen)
    select c_bpartner_id into v_bpartner from ad_user where ad_user_id=new.ad_user_id;
    select c_getemployeeworktimeNormal(v_bpartner,NEW.workdate) into v_nomalhours;
    -- Additional Fees (Only for Humans...)
    select c_additionalfees_id into v_addfeeId from c_additionalfees where ad_org_id in ('0',new.ad_org_id) and 
           case when new.ma_machine_id IS NOT NULL then 1=0 else 1=1 end and validfrom <=new.workdate and isactive='Y' order by  ad_org_id desc,validfrom desc limit 1; 
    for v_cur in (select  saturday as fee, 'saturday' as ident,nightbegin,nightend,overtimebegin from  c_additionalfees where c_additionalfees_id=v_addfeeId and saturday is not null
                  UNION
                  select  sunday as fee, 'sunday' as ident,nightbegin,nightend,overtimebegin from  c_additionalfees  where c_additionalfees_id=v_addfeeId and sunday is not null
                  UNION
                  select  holiday as fee, 'holiday' as ident,nightbegin,nightend,overtimebegin from  c_additionalfees  where c_additionalfees_id=v_addfeeId and holiday is not null
                  UNION
                  select  night as fee, 'night' as ident,nightbegin,nightend,overtimebegin from  c_additionalfees  where c_additionalfees_id=v_addfeeId and night is not null and nightbegin is not null 
                                                   and nightend is not null
                  UNION
                  select  overtime as fee, 'overtime' as ident,nightbegin,nightend,overtimebegin from  c_additionalfees  where c_additionalfees_id=v_addfeeId and overtime is not null 
                  ORDER BY fee desc)
    LOOP
        -- Night shift Work....
        if v_hourto<v_hourfrom then 
            v_overnight:='Y';
        end if;
        if v_hourfrom<v_cur.nightend then 
            v_hourfrom:=v_hourfrom + INTERVAL '24 hours';
        end if;
        if v_cur.nightend<v_cur.nightbegin then 
            v_cur.nightend:=v_cur.nightend + INTERVAL '24 hours';
        end if;
        if v_hourto<v_hourfrom then 
            v_hourto:=v_hourto + INTERVAL '24 hours';
        end if;
        if v_cur.ident='sunday' and (select dayname from c_workcalender where trunc(workdate)=trunc(new.workdate))='7' then
            new.issunday:='Y';
            v_cost:=round((v_cost*v_cur.fee/100)+v_cost,2);
            -- Includes Monday morning hours :
            -- all the night (and more) ?
            -- Worked to morning
            if v_hourto>=v_cur.nightbegin then 
                if v_hourto>=v_cur.nightend then 
                    new.nighthours:=extract(hour from v_cur.nightend)+extract(minute from v_cur.nightend)/60;
                else
                   -- Worked in next day?
                   if v_overnight='Y' then
                        new.nighthours:= (extract(hour from v_hourto)+extract(minute from v_hourto)/60) ;
                   end if;
                end if;
            end if;
            EXIT;
        elsif v_cur.ident='saturday' and (select dayname from c_workcalender where trunc(workdate)=trunc(new.workdate))='6' then
            new.issaturday:='Y';
            v_cost:=round((v_cost*v_cur.fee/100)+v_cost,2);
            EXIT;
        elsif v_cur.ident='holiday' and ((select isholiday from c_workcalender where trunc(workdate)=trunc(new.workdate))='Y' or (
                                      select isholyday from C_CALENDAREVENT,C_WORKCALENDAREVENT where C_CALENDAREVENT.C_CALENDAREVENT_id=C_WORKCALENDAREVENT.C_CALENDAREVENT_ID  and C_WORKCALENDAREVENT.ad_org_id=new.ad_org_id
                                      and new.workdate between datefrom and  coalesce(dateto,datefrom) order by isholyday desc limit 1)='Y') then
            new.isholiday:='Y';
            v_cost:=round((v_cost*v_cur.fee/100)+v_cost,2);
            EXIT;
        elsif v_cur.ident='night'  then 
        --raise exception '%','NIGHT!';
            -- From night to morning - On Friday
            if (select dayname from c_workcalender where trunc(workdate)=trunc(new.workdate))='5' then 
                -- Worked to next morning -> Saturday add. fee
                -- Worked in next day?
                if v_overnight='Y' then
                    v_nightendhour:='0001-01-02 00:00:00 BC'::timestamp;
                    v_fridytosatday:='Y';
                else
                    v_nightendhour:=v_hourto;
                end if;
                -- From night to morning
                if v_hourfrom>v_cur.nightbegin and v_nightendhour>=v_cur.nightend then
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_hourfrom - v_cur.nightend))) / 3600)) *(-1);
                -- all the night (and more)
                elsif v_hourfrom<=v_cur.nightbegin and v_nightendhour>=v_cur.nightend then
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_cur.nightbegin - v_cur.nightend))) / 3600)) *(-1);
                -- within the night 
                elsif v_hourfrom>=v_cur.nightbegin and v_nightendhour<=v_cur.nightend then
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_nightendhour - v_hourfrom))) / 3600));
                -- from evening to night
                else
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_nightendhour - v_cur.nightbegin))) / 3600));
                end if;
            else -- Monday till Do.
                -- From night to morning
                if v_hourfrom>v_cur.nightbegin and v_hourto>=v_cur.nightend then
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_hourfrom - v_cur.nightend))) / 3600)) *(-1);
                -- all the night (and more)
                elsif v_hourfrom<=v_cur.nightbegin and v_hourto>=v_cur.nightend then
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_cur.nightbegin - v_cur.nightend))) / 3600)) *(-1);
                -- within the night 
                elsif v_hourfrom>=v_cur.nightbegin and v_hourto<=v_cur.nightend then
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_hourto - v_hourfrom))) / 3600));
                -- from evening to night
                else
                    new.nighthours:=(SELECT ((EXTRACT (EPOCH FROM (v_hourto - v_cur.nightbegin))) / 3600));
                end if;
            end if;
            if new.nighthours < 0 then new.nighthours:=0; end if;
            -- Breaktime to Nighthours, if possible....
            -- We calculate the half of the worktime. If this is in the night, we assume braktime during nighthours
            if new.nighthours-coalesce(new.breaktime,0)-coalesce(new.paidbreaktime,0) > 0 then
                v_midwork:=(SELECT ((EXTRACT (EPOCH FROM (v_hourto - v_hourfrom))) / (3600*2)));
                if v_hourfrom+ INTERVAL '1 hours' * v_midwork between v_cur.nightbegin and v_cur.nightend then
                    new.nighthours:=new.nighthours-coalesce(new.breaktime,0)-coalesce(new.paidbreaktime,0);
                end if;
            end if;
            v_nightcost:=round((((v_cost*v_cur.fee/100)+v_cost)*new.nighthours),2);
            --EXIT;
        elsif v_cur.ident='overtime' and (v_Hours>v_nomalhours) and v_fridytosatday='N' then
            new.overtimehours:=v_Hours-v_nomalhours-new.nighthours;
            if new.overtimehours <0 then new.overtimehours:=0; end if;
            v_overtimecost:=round((((v_cost*v_cur.fee/100)+v_cost)*new.overtimehours),2);
            EXIT;
        end if;
    END LOOP;
  ELSEIF NEW.dayhours IS NOT NULL THEN --v_hourfrom IS NOT NULL
    NEW.hours := to_number(NEW.dayhours)*8;
  ELSEIF TG_OP = 'INSERT' AND (NEW.hour_from IS NOT NULL) AND (NEW.hour_to IS NULL) THEN
  -- calculated when Time Begin was set by PDC
    NEW.hours := 0;
  END IF;
  
  IF (NEW.hours IS NOT NULL) THEN
    v_cost := (v_cost * (NEW.hours-new.nighthours-new.overtimehours)) + v_overtimecost + v_nightcost+(coalesce(new.specialtime,0)*v_sp1)+(coalesce(new.specialtime2,0)*v_sp2)+(coalesce(new.specialtime3,0)*v_sp3)+coalesce(new.triggeramt,0)+coalesce(new.special4,0);
  ELSE                                                                                                                                   
    RAISE EXCEPTION '%', '@zspm_NeedToGiveHours4Feedback@';
  END IF;
      
  NEW.actualcostamount := v_cost;
  NEW.isprocessed:='Y';
  perform zspm_updateprojectstatus(null,new.c_project_id);
  RETURN NEW;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zspm_ptaskfeedbackline_trg', 'zspm_ptaskfeedbackline');
CREATE TRIGGER zspm_ptaskfeedbackline_trg
  BEFORE INSERT  OR DELETE OR UPDATE
  ON zspm_ptaskfeedbackline FOR EACH ROW
  EXECUTE PROCEDURE zspm_ptaskfeedbackline_trg();

/*****************************************************+
Stefan Zimmermann, 01/2011, stefan@zimmermann-software.de
   Implementation of Project-Feedback WEBSERVICE
*****************************************************/

CREATE OR REPLACE FUNCTION zspm_giveFeedback(p_employeeID character varying, p_workdate character varying,p_projectID character varying, p_PhaseID character varying, p_taskID character varying, p_hour_from character varying, p_hour_to character varying)
  RETURNS character varying AS
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
Part of Projects, UnDispose the complete BOM of the Task in Inventory
                  Cancel Task - Cancel PR, if open
Checks
*****************************************************/

v_count       numeric;
v_uid         character varying;
v_wdate       timestamp without time zone;
v_from        timestamp without time zone;
v_to          timestamp without time zone;
v_client      character varying;
v_DocumentNo  character varying;
v_org         character varying;
BEGIN
   v_wdate=to_date(p_workdate,'dd.mm.yyyy');
   v_from=to_timestamp(substr(p_hour_from,12,5),'hh24:mi');
   v_to=to_timestamp(substr(p_hour_to,12,5),'hh24:mi');
   v_uid=get_uuid();
   select ad_client_id,ad_org_id into v_client,v_org from c_project where c_project_id=p_projectID;
   if (v_client is not null and v_org is not null) then
      SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_zspm_ptaskfeedback', v_org, 'Y') ;
      insert into ZSPM_PTASKFEEDBACK (ZSPM_PTASKFEEDBACK_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,  UPDATEDBY, DOCUMENTNO, C_PROJECT_ID, C_PROJECTTASK_ID, AD_USER_ID, DESCRIPTION, WORKDATE,ismanual)
              values (v_uid,v_client,v_org,'0','0',v_DocumentNo,p_projectID,p_taskID,p_employeeID,'Generated by External System',v_wdate,'N');
      insert into ZSPM_PTASKFEEDBACKLINE (ZSPM_PTASKFEEDBACKLINE_ID, ZSPM_PTASKFEEDBACK_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, C_PROJECT_ID, C_PROJECTTASK_ID, AD_USER_ID, WORKDATE, HOUR_FROM, HOUR_TO)
              values(get_uuid(),v_uid,v_client,v_org,'0','0',p_projectID,p_taskID,p_employeeID,v_wdate,v_from,v_to);
      PERFORM zspm_processfeedback(v_uid);
      RETURN 'OK: DocumentNo: '||v_DocumentNo;
   else
      RETURN 'ERROR: No Organization';
   END IF; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  



select zsse_DropView ('tsrv_employeeevent_v');
create or replace view tsrv_employeeevent_v as
 select
 e.C_Bpartneremployeeevent_id AS tsrv_employeeevent_v_id,
 e.ad_client_id,
 e.ad_org_id,
 e.isactive,
 e.created,
 e.createdby,
 e.updated,
 e.updatedby,
 e.c_bpartner_id,
 e.datefrom,
 e.dateto,
 e.c_calendarevent_id ,
 e.worktime,
 e.reminder,
 e.note,
 e.isdone,
 u.ad_user_id,
 b.name ,
 ev.name as calendarevent
 from C_Bpartneremployeeevent e,c_bpartner b,ad_user u,C_CALENDAREVENT ev where u.c_bpartner_id=b.c_bpartner_id and b.c_bpartner_id=e.c_bpartner_id 
      and e.C_CALENDAREVENT_id=ev.C_CALENDAREVENT_id and b.isemployee='Y' and b.isactive='Y' and e.isactive='Y';
 



