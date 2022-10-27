 

/*****************************************************+
Stefan Zimmermann, 2013, stefan@zimmermann-software.de









  Common Calendar Functions for OrganizationsMaschines and Employees





*****************************************************/
select zsse_dropfunction('c_getemployeeeventCorrelation');

CREATE OR REPLACE FUNCTION c_getemployeeeventCorrelation(p_employee varchar, p_workdate  timestamp without time zone,p_lang varchar,OUT p_correlation varchar,out p_eventname varchar, out p_color varchar, out p_textcolor varchar, out p_whours numeric)
RETURNS SETOF RECORD AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_orgevent varchar;
BEGIN
  if p_employee is not null then
    for v_cur in (select  e.correlation,coalesce(t.name,e.name) as name,e.c_color_id,e.worktime  from C_bpartneremployeeEVENT w, C_CALENDAREVENT e 
                                                                                                 left join C_CALENDAREVENT_trl t on t.C_CALENDAREVENT_id=e.C_CALENDAREVENT_id and t.ad_language=p_lang
                                                                                                 where e.C_CALENDAREVENT_id=w.C_CALENDAREVENT_id and w.c_bpartner_id=p_employee 
                    and e.isactive='Y'  and w.isactive='Y' and (e.correlation is not null or e.c_color_id is not null) and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate
                  order by correlation)
    LOOP
       select htmlnotation, case when istextwhite='Y' then 'white' else 'black' end into p_color,p_textcolor from c_color where c_color_id=v_cur.c_color_id;
       p_correlation:=v_cur.correlation;
       p_eventname:=v_cur.name;
       p_whours:=v_cur.worktime;
       RETURN NEXT;
    END LOOP;
  end if;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
  

CREATE OR REPLACE FUNCTION c_getemployeeevent(p_employee varchar, p_workdate  timestamp without time zone)
RETURNS varchar AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_orgevent varchar;
BEGIN
    for v_cur in (select  e.name as event,w.note  from C_bpartneremployeeEVENT w, C_CALENDAREVENT e where e.C_CALENDAREVENT_id=w.C_CALENDAREVENT_id and w.c_bpartner_id=p_employee 
                    and e.isactive='Y'  and w.isactive='Y'  and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate 
                  order by event)
    LOOP
       if v_return!='' then  v_return:=v_return||'--'; end if;
       v_return:=v_return||v_cur.event||' : '||coalesce(v_cur.note,'');
    END LOOP;
    v_orgevent:=c_getorgevent((select ad_org_id from c_bpartner where c_bpartner_id=p_employee limit 1), p_workdate);
    if v_return!='' and v_orgevent!='' then
        v_orgevent:='--'||v_orgevent;
    end if;
    return substr(v_return||v_orgevent,1,2000);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
  
select zsse_dropfunction('c_getemployeeprojectsplan');
CREATE OR REPLACE FUNCTION c_getemployeeprojectsplan(p_employee varchar, p_workdate  timestamp without time zone, p_withlink varchar,p_PlannedOrStarted varchar,out p_content varchar,out p_color varchar, out p_textcolor varchar)
RETURNS RECORD AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_color varchar:='';
v_color2 varchar:='';
v_textcolor varchar:='';
v_orgevent varchar;
BEGIN
    for v_cur in (select distinct p.name||'-'||pt.name as text, pt.c_projecttask_id,pt.c_color_id from zspm_ptaskhrplan hrp,c_projecttask pt,c_project p,ad_user u where 
                   pt.c_projecttask_id=hrp.c_projecttask_id and p.c_project_id=pt.c_project_id 
                   and case when p_PlannedOrStarted='Planned' then p.projectstatus in ('OP','OR') else  p.projectstatus='OR' end 
                   and pt.istaskcancelled='N' and pt.iscomplete='N'
                   and trunc(p_workdate) >= trunc(coalesce(hrp.datefrom,pt.startdate)) and  
                   trunc(p_workdate) <= trunc(coalesce(hrp.dateto,pt.enddate))
                   and hrp.employee_id=u.ad_user_id and u.c_bpartner_id=p_employee
                   and pt.startdate is not null and pt.enddate is not null)
    LOOP
       select htmlnotation, case when istextwhite='Y' then 'white' else 'black' end into v_color,v_textcolor from c_color where c_color_id=v_cur.c_color_id;
       -- If there is only one Project with Color, return the Color. If there are more then one Projects with Color return RED
       -- If there is one Project with Color and others without, return the color of the Project 
       if v_color is not null and v_color2='' then
        v_color2:=v_color;
       else
        if v_color2!='' then
        v_color2:='redwork';
        v_textcolor:='black';
        else
        v_color2:='';
       end if;
       end if;
       if p_withlink='N' then
            if v_return!='' then  v_return:=v_return||'--'; end if;
            v_return:=v_return||v_cur.text;
       else
         if v_return!='' then  v_return:=v_return||'</br>'; end if;
         v_return:=v_return||zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.project.Projects/ProjectTask490_Edition.html',v_cur.c_projecttask_id,v_cur.text,v_textcolor);
       --
       end if;
    END LOOP;
    if p_withlink='N' then
        p_content:=v_return;
    else
        p_content:=substr(v_return,1,2000);
    end if;
    p_color:=v_color2;
    p_textcolor:=v_textcolor;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
  
  select zsse_dropfunction('c_getemployeeprojectsplan_short');
CREATE OR REPLACE FUNCTION c_getemployeeprojectsplan_short(p_employee varchar, p_workdate  timestamp without time zone, p_withlink varchar,p_PlannedOrStarted varchar,out p_content varchar,out p_color varchar, out p_textcolor varchar)
RETURNS RECORD AS 
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_color varchar:='';
v_color2 varchar:='';
v_textcolor varchar:='';
v_orgevent varchar;
v_temp varchar;
BEGIN
    for v_cur in (select distinct p.name||'-'||pt.name as text, pt.c_projecttask_id,pt.c_color_id,hrp.zspm_ptaskhrplan_id,p.projectcategory from zspm_ptaskhrplan hrp,c_projecttask pt,c_project p,ad_user u where 
                   pt.c_projecttask_id=hrp.c_projecttask_id and p.c_project_id=pt.c_project_id 
                   and case when p_PlannedOrStarted='Planned' then p.projectstatus in ('OP','OR') else  p.projectstatus='OR' end 
                   and pt.istaskcancelled='N' and pt.iscomplete='N'
                   and trunc(p_workdate) >= trunc(coalesce(hrp.datefrom,pt.startdate)) and  
                   trunc(p_workdate) <= trunc(coalesce(hrp.dateto,pt.enddate))
                   and hrp.employee_id=u.ad_user_id and u.c_bpartner_id=p_employee
                   and pt.startdate is not null and pt.enddate is not null)
    LOOP
       select htmlnotation, case when istextwhite='Y' then 'white' else 'black' end into v_color,v_textcolor from c_color where c_color_id=v_cur.c_color_id;
       -- If there is only one Project with Color, return the Color. If there are more then one Projects with Color return RED
       -- If there is one Project with Color and others without, return the color of the Project 
       if v_color is not null and v_color2='' then
        v_color2:=v_color;
       else
        if v_color2!='' then
        v_color2:='redwork';
        v_textcolor:='black';
        else
        v_color2:='';
       end if;
       end if;
       if p_withlink='N' then
            if v_return!='' then  v_return:=v_return||'--'; end if;
            v_return:=v_return||v_cur.text;
       else
         if v_return!='' then  v_return:=v_return||'</br>'; end if;
       
	 if v_cur.projectcategory='PRO' then
		v_temp:='submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||v_cur.zspm_ptaskhrplan_id||chr(39)||', false, document.frmMain, '||chr(39)||'../org.openbravo.zsoft.serprod.ProductionOrder/Activities6F92F616B40C49FD9F2E8DE87216DD55_Edition.html'||chr(39)||', null, false, true)';

	 else 
		v_temp:='submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||v_cur.zspm_ptaskhrplan_id||chr(39)||', false, document.frmMain, '||chr(39)||'../org.openbravo.zsoft.project.Projects/EmployeePlanC80DFFDC5E4E4F219622923DB9C2C760_Edition.html'||chr(39)||', null, false, true)';
	 end if;
      
        
        if v_textcolor='white' then
            v_return:=v_return||'<a title="'||zssi_2html(v_cur.text)||'" href="#" onclick="stashaction(function(){'||v_temp||'},1200)" ondblclick="delstash();openServletNewWindow('||chr(39)||'DIRECT'||chr(39)||',false,'||chr(39)||'../org.openz.controller.popup/ResourcePlanUpdate.html'||chr(39)||','||chr(39)||'Popup'||chr(39)||','||chr(39)||v_cur.zspm_ptaskhrplan_id||chr(39)||',false,500,1000);return false;" class="LabelLink_white">'||'&nbsp;'||v_cur.text||' </a>';
        else
            v_return:=v_return||'<a title="'||zssi_2html(v_cur.text)||'" href="#" onclick="stashaction(function(){'||v_temp||'},1200)" ondblclick="delstash();openServletNewWindow('||chr(39)||'DIRECT'||chr(39)||',false,'||chr(39)||'../org.openz.controller.popup/ResourcePlanUpdate.html'||chr(39)||','||chr(39)||'Popup'||chr(39)||','||chr(39)||v_cur.zspm_ptaskhrplan_id||chr(39)||',false,500,1000);return false;" class="LabelLink_black">'||'&nbsp;'||v_cur.text||' </a>';
        end if;
       end if;
    END LOOP;
    p_content:=v_return;
    p_color:=v_color2;
    p_textcolor:=v_textcolor;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
  
select zsse_dropfunction('c_getemployeeprojectsplanInRange');
CREATE OR REPLACE FUNCTION c_getemployeeprojectsplanInRange(p_employee varchar, p_datefrom  varchar,p_dateto  varchar,p_excludedTask varchar,p_PlannedOrStarted varchar)
RETURNS VARCHAR AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_color varchar:='';
v_color2 varchar:='';
v_textcolor varchar:='';
v_orgevent varchar;
BEGIN
    for v_cur in (select distinct p.name||'-'||pt.name as text, pt.c_projecttask_id,pt.c_color_id from zspm_ptaskhrplan hrp,c_projecttask pt,c_project p,ad_user u where 
                   pt.c_projecttask_id=hrp.c_projecttask_id and p.c_project_id=pt.c_project_id 
                   and case when p_PlannedOrStarted='Planned' then p.projectstatus in ('OP','OR') else  p.projectstatus='OR' end 
                   and pt.istaskcancelled='N' and pt.iscomplete='N'
                   and to_date(p_datefrom,'dd.mm.yyyy') >= trunc(coalesce(hrp.datefrom,coalesce(pt.startdate,now()))) and  
                   to_date(p_dateto,'dd.mm.yyyy') <= trunc(coalesce(hrp.dateto,coalesce(pt.enddate,now())))
                   and hrp.employee_id=u.ad_user_id and u.c_bpartner_id=p_employee
                   and pt.c_projecttask_id!=coalesce(p_excludedTask,''))
    LOOP
            if v_return!='' then  v_return:=v_return||'--'; end if;
            v_return:=v_return||v_cur.text;
    END LOOP;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
  
  
CREATE OR REPLACE FUNCTION c_getemployeeprojectsworked(p_employee varchar, p_workdate  timestamp without time zone)
RETURNS varchar AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_orgevent varchar;
BEGIN
    for v_cur in (select p.name||'-'||pt.name as text, pt.c_projecttask_id from zspm_ptaskfeedbackline fbl,c_projecttask pt,c_project p,ad_user u where 
                   pt.c_projecttask_id=fbl.c_projecttask_id and p.c_project_id=pt.c_project_id 
                   and fbl.ad_user_id=u.ad_user_id and u.c_bpartner_id=p_employee
                   and trunc(p_workdate) = trunc(fbl.workdate))
    LOOP
       if v_return!='' then  v_return:=v_return||'--'; end if;
       v_return:=v_return||v_cur.text;
       --zsse_htmldirectlinkWithDummyField('/org.openbravo.zsoft.project.Projects/ProjectTask490_Edition.html','inpcProjecttaskId',v_cur.c_projecttask_id,v_cur.text);
    END LOOP;
    
    return substr(v_return,1,2000);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION c_getemployeeworktime(p_employee varchar, p_workdate  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric;
v_user varchar;
BEGIN
   select sum(l.hours) into v_return from zspm_ptaskfeedbackline l,ad_user u where u.ad_user_id=l.ad_user_id and u.c_bpartner_id=p_employee and trunc(l.workdate)=trunc(p_workdate);
   return coalesce(v_return,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_getemployeeworktimeshedule(p_employee varchar, p_workdatefrom  timestamp without time zone,p_workdateto  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric:=0;
v_cur record;
BEGIN
    for v_cur in (select workdate from c_workcalender where trunc(workdate)>=trunc(p_workdatefrom) and trunc(workdate)<=trunc(p_workdateto))
    LOOP
        v_return:=v_return+c_getemployeeworktime(p_employee,v_cur.workdate);
    END LOOP;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
CREATE OR REPLACE FUNCTION c_getemployeepercentplanned(p_employee varchar, p_workdate  timestamp without time zone,p_PlannedOrStarted varchar)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric:=0;
v_cur record;
BEGIN
   select sum(case when pt.c_color_id is null then hrp.planndedpercent else 100 end) into v_return
                   from zspm_ptaskhrplan hrp,c_projecttask pt,ad_user u,c_project p where 
                   pt.c_projecttask_id=hrp.c_projecttask_id
                   and pt.istaskcancelled='N' and pt.iscomplete='N'
                   and pt.c_project_id=p.c_project_id 
                   and case when p_PlannedOrStarted='Planned' then p.projectstatus in ('OP','OR') else  p.projectstatus='OR' end 
                   and trunc(p_workdate) >= trunc(coalesce(hrp.datefrom,pt.startdate)) and  
                   trunc(p_workdate) <= trunc(coalesce(hrp.dateto,pt.enddate))
                   and hrp.employee_id=u.ad_user_id and u.c_bpartner_id=p_employee
                   and pt.startdate is not null and pt.enddate is not null;
   if coalesce(v_return,0) > 999 then
        v_return:=999;
   end if;
   return coalesce(v_return,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100; 
 
 
CREATE OR REPLACE FUNCTION c_getemployeeworktimeNormal(p_employee varchar, p_workdate  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric;
v_dow numeric;
v_org varchar;
v_globalholiday varchar;
v_day varchar;
BEGIN
    select ad_org_id into v_org from c_bpartner where c_bpartner_id=p_employee;
    select extract (DOW from p_workdate) into v_dow;
    if v_dow=1 then
        select worktimemonday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select worktimetuesday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select worktimewednesday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select worktimethursday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select worktimefriday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select worktimesaturday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select worktimesunday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    if v_return is not null then
        return v_return;
    end if;
    if v_dow=1 then
        select worktimemonday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=v_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select worktimetuesday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=v_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select worktimewednesday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=v_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select worktimethursday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=v_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select worktimefriday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=v_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select worktimesaturday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=v_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select worktimesunday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=v_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    if v_return is not null then
        return v_return;
    end if;
    -- On Global Holidays we select the next workday's worktime as Standard Worktime.
    -- This is to do Calculations for Salary of People correkctly - There a holiday counts like norrmal worktime
    select isholiday,dayname into v_globalholiday,v_day from c_workcalender where workdate=p_workdate;
    if v_globalholiday='Y' then 
        select worktime into v_return from c_workcalender where workdate>=p_workdate and isholiday='N' and dayname = v_day order by  workdate limit 1;
    else
        select worktime into v_return from c_workcalender where workdate=p_workdate;
    end if;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_getemployeeworktimeplan(p_employee varchar, p_workdate  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric;
v_dow numeric;
BEGIN
    select worktime into v_return from C_bpartneremployeeEVENT where c_bpartner_id=p_employee and isactive='Y' and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate order by worktime limit 1;
    if v_return is not null then
        return v_return;
    end if;
    select extract (DOW from p_workdate) into v_dow;
    if v_dow=1 then
        select worktimemonday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select worktimetuesday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select worktimewednesday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select worktimethursday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select worktimefriday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select worktimesaturday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select worktimesunday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    if v_return is not null then
        return v_return;
    end if;
    select coalesce(c_getorgworktime((select ad_org_id from c_bpartner where c_bpartner_id=p_employee), p_workdate),worktime) into v_return from c_workcalender where workdate=p_workdate;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_getemployeeworktimesheduleplan(p_employee varchar, p_workdatefrom  timestamp without time zone,p_workdateto  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric:=0;
v_cur record;
BEGIN
    for v_cur in (select workdate from c_workcalender where trunc(workdate)>=trunc(p_workdatefrom) and trunc(workdate)<=trunc(p_workdateto))
    LOOP
        v_return:=v_return+c_getemployeeworktimeplan(p_employee,v_cur.workdate);
    END LOOP;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
   
  
  
CREATE OR REPLACE FUNCTION c_getemployeeworkbegintime(p_employee varchar, p_workdate  timestamp without time zone)
RETURNS timestamp without time zone AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return timestamp without time zone;
v_dow numeric;
BEGIN
    
    select extract (DOW from p_workdate) into v_dow;
    if v_dow=1 then
        select workbegintimemonday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select workbegintimetuesday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select workbegintimewednesday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select workbegintimethursday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select workbegintimefriday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select workbegintimesaturday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select workbegintimesunday into v_return from C_bpartneremployeeCALENDARSETTINGS where c_bpartner_id=p_employee and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    if v_return is null then
        return c_getorgworkbegintime((select ad_org_id from c_bpartner where c_bpartner_id=p_employee), p_workdate);
    end if;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_getOrgEventCorrelation(p_org varchar, p_workdate  timestamp without time zone,p_lang varchar,OUT p_correlation varchar,out p_eventname varchar, out p_color varchar, out p_textcolor varchar)
RETURNS SETOF RECORD AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_orgevent varchar;
v_count numeric:=0;
BEGIN
    for v_cur in (select  e.correlation,coalesce(t.name,e.name) as name,e.c_color_id,e.isholyday  from C_WORKCALENDAREVENT w, C_CALENDAREVENT e 
                                                                         left join C_CALENDAREVENT_trl t on t.C_CALENDAREVENT_id=e.C_CALENDAREVENT_id and t.ad_language=p_lang
                                                                         where e.C_CALENDAREVENT_id=w.C_CALENDAREVENT_id and
                    w.ad_org_id=p_org
                    and e.isactive='Y'  and w.isactive='Y' and (e.correlation is not null or e.c_color_id is not null) and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate
                  order by correlation)
    LOOP
       select htmlnotation, case when istextwhite='Y' then 'white' else 'black' end into p_color,p_textcolor from c_color where c_color_id=v_cur.c_color_id;
       p_correlation:=v_cur.correlation;
       if v_cur.isholyday='Y' then
        p_correlation:='5';
       end if;
       p_eventname:=v_cur.name;
       v_count:=v_count+1;
       RETURN NEXT;
    END LOOP;
    if v_count=0 then
        select isholiday into v_orgevent from C_WORKCALENDeR where workdate=p_workdate;
        if v_orgevent='Y' then
            p_correlation:='5';
            p_eventname:=zssi_getElementTextByColumname('Isholiday',p_lang);
            --p_eventname:='Feiertag';
            RETURN NEXT;
        end if;
    end if;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
    

CREATE OR REPLACE FUNCTION c_getorgevent(p_org varchar, workdate  timestamp without time zone)
RETURNS varchar AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
BEGIN
    for v_cur in (select  e.name as event,w.note from C_WORKCALENDAREVENT w, C_CALENDAREVENT e where e.C_CALENDAREVENT_id=w.C_CALENDAREVENT_id and w.ad_org_id=p_org 
                    and e.isactive='Y' and w.isactive='Y' and datefrom<=workdate and coalesce(dateto,datefrom)>=workdate order by event)
    LOOP
       if v_return!='' then  v_return:=v_return||'--'; end if;
       v_return:=v_return||v_cur.event||' : '||coalesce(v_cur.note,'');
    END LOOP;
    return substr(v_return,1,2000);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;


CREATE OR REPLACE FUNCTION c_getorgworktime(p_org varchar, p_workdate  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric;
v_dow numeric;
BEGIN
    select worktime into v_return from C_WORKCALENDAREVENT where isactive='Y' and ad_org_id=p_org and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate order by worktime limit 1;
    if v_return is not null then
        return v_return;
    end if;
    select extract (DOW from p_workdate) into v_dow;
    if v_dow=1 then
        select worktimemonday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select worktimetuesday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select worktimewednesday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select worktimethursday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select worktimefriday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select worktimesaturday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select worktimesunday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION c_getorgworkbegintime(p_org varchar, p_workdate  timestamp without time zone)
RETURNS timestamp without time zone AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return timestamp without time zone;
v_dow numeric;
BEGIN
    
    select extract (DOW from p_workdate) into v_dow;
    if v_dow=1 then
        select workbegintimemonday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select workbegintimetuesday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select workbegintimewednesday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select workbegintimethursday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select workbegintimefriday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select workbegintimesaturday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select workbegintimesunday into v_return from C_WORKCALENDARSETTINGS where ad_org_id=p_org and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_dropfunction('c_getmachineeventCorrelation');

CREATE OR REPLACE FUNCTION c_getmachineeventCorrelation(p_machine varchar, p_workdate  timestamp without time zone,OUT p_correlation varchar,out p_eventname varchar, out p_color varchar, out p_textcolor varchar)
RETURNS SETOF RECORD AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_orgevent varchar;
BEGIN
  if p_machine is not null then
    for v_cur in (select  e.correlation,e.name,e.c_color_id  from ma_machineevent w, C_CALENDAREVENT e where e.C_CALENDAREVENT_id=w.C_CALENDAREVENT_id and w.ma_machine_id=p_machine
                    and e.isactive='Y'  and w.isactive='Y' and (e.correlation is not null or e.c_color_id is not null) and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate 
                  order by correlation)
    LOOP
       select htmlnotation, case when istextwhite='Y' then 'white' else 'black' end into p_color,p_textcolor from c_color where c_color_id=v_cur.c_color_id;
       p_correlation:=v_cur.correlation;
       p_eventname:=v_cur.name;
       RETURN NEXT;
    END LOOP;
  end if;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
  
  
  
CREATE OR REPLACE FUNCTION c_getmachineevent(p_machine varchar, p_workdate  timestamp without time zone)
RETURNS varchar AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
BEGIN
    for v_cur in (select  e.name as event,w.note from ma_machineEVENT w, C_CALENDAREVENT e where e.C_CALENDAREVENT_id=w.C_CALENDAREVENT_id and w.ma_machine_id=p_machine 
                      and e.isactive='Y' and w.isactive='Y' and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate 
                  order by event)
    LOOP
       if v_return!='' then  v_return:=v_return||'--'; end if;
       v_return:=v_return||v_cur.event||' : '||coalesce(v_cur.note,'');
    END LOOP;
    return substr(v_return,1,2000);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;


select zsse_dropfunction('c_getmachineprojectsplan');
CREATE OR REPLACE FUNCTION c_getmachineprojectsplan(p_machine varchar, p_workdate  timestamp without time zone, p_withlink varchar,p_PlannedOrStarted varchar,out p_content varchar,out p_color varchar, out p_textcolor varchar)
RETURNS RECORD AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_color varchar:='';
v_color2 varchar:='';
v_textcolor varchar:='';
v_orgevent varchar;
BEGIN
    for v_cur in (select distinct  p.name||'-'||pt.name as text, pt.c_projecttask_id,pt.c_color_id from zspm_ptaskmachineplan mpl,c_projecttask pt,c_project p where 
                   pt.c_projecttask_id=mpl.c_projecttask_id and p.c_project_id=pt.c_project_id 
		   and case when p.projectcategory='PRO' then 1=1 else case when p_PlannedOrStarted='Planned' then p.projectstatus in ('OP','OR') else  p.projectstatus='OR' end end 
                   and pt.istaskcancelled='N' and pt.iscomplete='N'
                   and trunc(p_workdate) >= trunc(coalesce(mpl.datefrom,pt.startdate)) and  
                   trunc(p_workdate) <= trunc(coalesce(mpl.dateto,pt.enddate))
                   and mpl.ma_machine_id=p_machine
                   and pt.startdate is not null and pt.enddate is not null)
    LOOP
       select htmlnotation, case when istextwhite='Y' then 'white' else 'black' end into v_color,v_textcolor from c_color where c_color_id=v_cur.c_color_id;
       -- If there is only one Project with Color, return the Color. If there are more then one Projects with Color return RED
       -- If there is one Project with Color and others without, return the color of the Project 
      if v_color is not null and v_color2='' then
        v_color2:=v_color;
       else
        if v_color2!='' then
        v_color2:='redwork';
        v_textcolor:='black';
        else
        v_color2:='';
       end if;
       end if;
       if p_withlink='N' then
            if v_return!='' then  v_return:=v_return||'--'; end if;
            v_return:=v_return||v_cur.text;
       else
         if v_return!='' then  v_return:=v_return||'</br>'; end if;
         v_return:=v_return||zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.project.Projects/ProjectTask490_Edition.html',v_cur.c_projecttask_id,v_cur.text,v_textcolor);
       end if;
    END LOOP;
    p_content:=substr(v_return,1,2000);
    p_color:=v_color2;
    p_textcolor:=v_textcolor;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;

select zsse_dropfunction('c_getmachineprojectsplan_short');
CREATE OR REPLACE FUNCTION c_getmachineprojectsplan_short(p_machine varchar, p_workdate  timestamp without time zone, p_withlink varchar,p_PlannedOrStarted varchar,out p_content varchar,out p_color varchar, out p_textcolor varchar)
RETURNS RECORD AS 
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_color varchar:='';
v_color2 varchar:='';
v_textcolor varchar:='';
v_orgevent varchar;
v_temp varchar;
BEGIN
    for v_cur in (select distinct  p.name||'-'||pt.name as text, pt.c_projecttask_id,pt.c_color_id,mpl.zspm_ptaskmachineplan_id, p.projectcategory
                  from zspm_ptaskmachineplan mpl,c_projecttask pt,c_project p where 
                   pt.c_projecttask_id=mpl.c_projecttask_id and p.c_project_id=pt.c_project_id 
		   and case when p.projectcategory='PRO' then 1=1 else case when p_PlannedOrStarted='Planned' then p.projectstatus in ('OP','OR') else  p.projectstatus='OR' end end 
                   and pt.istaskcancelled='N' and pt.iscomplete='N'
                   and trunc(p_workdate) >= trunc(coalesce(mpl.datefrom,pt.startdate)) and  
                   trunc(p_workdate) <= trunc(coalesce(mpl.dateto,pt.enddate))
                   and mpl.ma_machine_id=p_machine
                   and pt.startdate is not null and pt.enddate is not null)
    LOOP
       select htmlnotation, case when istextwhite='Y' then 'white' else 'black' end into v_color,v_textcolor from c_color where c_color_id=v_cur.c_color_id;
       -- If there is only one Project with Color, return the Color. If there are more then one Projects with Color return RED
       -- If there is one Project with Color and others without, return the color of the Project 
      if v_color is not null and v_color2='' then
        v_color2:=v_color;
       else
        if v_color2!='' then
        v_color2:='redwork';
        v_textcolor:='black';
        else
        v_color2:='';
       end if;
       end if;
       if p_withlink='N' then
            if v_return!='' then  v_return:=v_return||'--'; end if;
            v_return:=v_return||v_cur.text;
       else
         if v_return!='' then  v_return:=v_return||'</br>'; end if;

	 if v_cur.projectcategory='PRO' then

		v_temp:='submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||v_cur.zspm_ptaskmachineplan_id||chr(39)||', false, document.frmMain, '||chr(39)||'../org.openbravo.zsoft.serprod.ProductionOrder/Machines46D441FD4B724358AF4F71971191A331_Relation.html'||chr(39)||', null, false, true)';

	 else 
        	v_temp:='submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||v_cur.zspm_ptaskmachineplan_id||chr(39)||', false, document.frmMain, '||chr(39)||'../org.openbravo.zsoft.project.Projects/MachinePlanD3DA773117B94F868813BCEAA1A667F5_Relation.html'||chr(39)||', null, false, true)';
	 end if;
        
        if v_textcolor='white' then
            v_return:=v_return||'<a title="'||zssi_2html(v_cur.text)||'" href="#" onclick="stashaction(function(){'||v_temp||'},1200)" ondblclick="delstash();openServletNewWindow('||chr(39)||'DIRECT'||chr(39)||',false,'||chr(39)||'../org.openz.controller.popup/ResourcePlanUpdate.html'||chr(39)||','||chr(39)||'Popup'||chr(39)||','||chr(39)||v_cur.zspm_ptaskmachineplan_id||chr(39)||',false,500,1000);return false;" class="LabelLink_white">'||'&nbsp;'||v_cur.text||' </a>';
        else
            v_return:=v_return||'<a title="'||zssi_2html(v_cur.text)||'" href="#" onclick="stashaction(function(){'||v_temp||'},1200)" ondblclick="delstash();openServletNewWindow('||chr(39)||'DIRECT'||chr(39)||',false,'||chr(39)||'../org.openz.controller.popup/ResourcePlanUpdate.html'||chr(39)||','||chr(39)||'Popup'||chr(39)||','||chr(39)||v_cur.zspm_ptaskmachineplan_id||chr(39)||',false,500,1000);return false;" class="LabelLink_black">'||'&nbsp;'||v_cur.text||' </a>';
        end if;
       end if;
    END LOOP;
    p_content:=v_return;
    p_color:=v_color2;
    p_textcolor:=v_textcolor;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;


CREATE OR REPLACE FUNCTION c_getmachineprojectsworked(p_machine varchar, p_workdate  timestamp without time zone)
RETURNS varchar AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/
v_cur record;
v_return varchar:='';
v_orgevent varchar;
BEGIN
    for v_cur in (select p.name||'-'||pt.name as text, pt.c_projecttask_id from zspm_ptaskfeedbackline fbl,c_projecttask pt,c_project p where 
                   pt.c_projecttask_id=fbl.c_projecttask_id and p.c_project_id=pt.c_project_id 
                   and fbl.ma_machine_id=p_machine
                   and trunc(p_workdate) = trunc(fbl.workdate))
    LOOP
       if v_return!='' then  v_return:=v_return||'--'; end if;
       v_return:=v_return||v_cur.text;
       --zsse_htmldirectlinkWithDummyField('/org.openbravo.zsoft.project.Projects/ProjectTask490_Edition.html','inpcProjecttaskId',v_cur.c_projecttask_id,v_cur.text);
    END LOOP;
    
    return substr(v_return,1,2000);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
 
CREATE OR REPLACE FUNCTION c_getmachineworktime(p_machine varchar, p_workdate  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric;
v_user varchar;
BEGIN
   select sum(l.hours) into v_return from zspm_ptaskfeedbackline l where l.ma_machine_id=p_machine and trunc(l.workdate)=trunc(p_workdate);
   return coalesce(v_return,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
CREATE OR REPLACE FUNCTION c_getmachinepercentplanned(p_machine varchar, p_workdate  timestamp without time zone,p_PlannedOrStarted varchar)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric:=0;
v_cur record;
BEGIN
  select sum(case when pt.c_color_id is null and mpl.costuom='H' then mpl.planndedpercent else 100/
              (select count(*) from zspm_ptaskmachineplan mp2 where mp2.ma_machine_id= p_machine and mp2.c_projecttask_id = pt.c_projecttask_id) end) into v_return
                   from zspm_ptaskmachineplan mpl,c_projecttask pt,c_project p where 
                   pt.c_projecttask_id=mpl.c_projecttask_id and mpl.ma_machine_id= p_machine
                   and pt.istaskcancelled='N' and pt.iscomplete='N'
                   and  pt.c_project_id=p.c_project_id
		   and case when p.projectcategory='PRO' then 1=1 else case when p_PlannedOrStarted='Planned' then p.projectstatus in ('OP','OR') else  p.projectstatus='OR' end end 
                   and trunc(p_workdate) >= trunc(coalesce(mpl.datefrom,pt.startdate)) and  
                   trunc(p_workdate) <= trunc(coalesce(mpl.dateto,pt.enddate))
                   and pt.startdate is not null and pt.enddate is not null;
   if coalesce(v_return,0) > 999 then
        v_return:=999;
   end if; 
   return coalesce(v_return,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100; 
  
CREATE OR REPLACE FUNCTION c_getmachineworktimeplan(p_machine varchar, p_workdate  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric;
v_dow numeric;
BEGIN
    select worktime into v_return from ma_machineEVENT where ma_machine_id=p_machine and isactive='Y' and datefrom<=p_workdate and coalesce(dateto,datefrom)>=p_workdate order by worktime limit 1;
    if v_return is not null then
        return v_return;
    end if;
    select extract (DOW from p_workdate) into v_dow;
    if v_dow=1 then
        select worktimemonday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select worktimetuesday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select worktimewednesday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select worktimethursday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select worktimefriday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select worktimesaturday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select worktimesunday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    if v_return is not null then
        return v_return;
    end if;
    select coalesce(c_getorgworktime((select ad_org_id from c_bpartner where c_bpartner_id=p_machine), p_workdate),worktime) into v_return from c_workcalender where workdate=p_workdate;
    return  v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE OR REPLACE FUNCTION c_getmachineworktimesheduleplan(p_machine varchar, p_workdatefrom  timestamp without time zone,p_workdateto  timestamp without time zone)
RETURNS numeric AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return numeric:=0;
v_cur record;
BEGIN
    for v_cur in (select workdate from c_workcalender where trunc(workdate)>=trunc(p_workdatefrom) and trunc(workdate)<=trunc(p_workdateto))
    LOOP
        v_return:=v_return+c_getmachineworktimeplan(p_machine,v_cur.workdate);
    END LOOP;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
     
CREATE OR REPLACE FUNCTION c_getmachineworkbegintime(p_machine varchar, p_workdate  timestamp without time zone)
RETURNS timestamp without time zone AS 
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
 
Central Calender Function - Org Specific

OVERLOADED - Tuning purpose in Production Simulation
 
*****************************************************/

v_return timestamp without time zone;
v_dow numeric;
BEGIN
    
    select extract (DOW from p_workdate) into v_dow;
    if v_dow=1 then
        select workbegintimemonday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=2 then 
        select workbegintimetuesday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=3 then 
         select workbegintimewednesday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=4 then 
         select workbegintimethursday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=5 then 
         select workbegintimefriday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=6 then 
         select workbegintimesaturday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    elsif v_dow=0 then 
         select workbegintimesunday into v_return from ma_machineCALENDARSETTINGS where ma_machine_id=p_machine and isactive='Y' and validfrom<=p_workdate order by validfrom desc;
    end if;
    if v_return is null then
        return c_getorgworkbegintime((select ad_org_id from c_bpartner where c_bpartner_id=p_machine), p_workdate);
    end if;
    return v_return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 

  

  
  
  
   
/*****************************************************+
Stefan Zimmermann, 2013, stefan@zimmermann-software.de









 Calendar Views for Organizations, Maschines and Employees





*****************************************************/

select zsse_dropview('c_orgcalendar_v');
CREATE OR REPLACE VIEW c_orgcalendar_v AS
SELECT w.c_workcalender_id||o.ad_org_id as c_orgcalendar_v_id,o.ad_org_id,o.ad_client_id,o.updated,o.updatedby,o.created,o.createdby,'Y'::character as isactive,
       c_getorgevent(o.ad_org_id,w.workdate) as event,
       coalesce(c_getorgworktime(o.ad_org_id,w.workdate),w.worktime) as worktime, 
       to_char(coalesce(c_getorgworkbegintime(o.ad_org_id,w.workdate),w.workbegintime),'HH24:MI')::character varying as workbegintime,
       w.workdate
FROM c_workcalender w, ad_org o;


--select zsse_dropview('c_employeecalendar_v');
CREATE OR REPLACE VIEW c_employeecalendar_v AS
SELECT w.c_workcalender_id||o.c_bpartner_id as c_employeecalendar_v_id,o.ad_org_id,o.ad_client_id,o.updated,o.updatedby,o.created,o.createdby,'Y'::character as isactive,
       c_getemployeeevent(o.c_bpartner_id,w.workdate) as event,
       coalesce(c_getemployeeworktimeplan(o.c_bpartner_id,w.workdate),w.worktime) as worktimeplan, 
       to_char(coalesce(c_getemployeeworkbegintime(o.c_bpartner_id,w.workdate),w.workbegintime),'HH24:MI')::character varying as workbegintime,
       w.workdate,
       o.c_bpartner_id,
       (select p_content from c_getemployeeprojectsplan(o.c_bpartner_id,w.workdate,'N','Started')) as projectsplan,
       c_getemployeeprojectsworked(o.c_bpartner_id,w.workdate) as projectsworked,
       c_getemployeeworktime(o.c_bpartner_id,w.workdate) as worktime,
       case when coalesce(c_getemployeeworktimeplan(o.c_bpartner_id,w.workdate),w.worktime)=0 then 
            case when c_getemployeeworktime(o.c_bpartner_id,w.workdate)>0 then 999 else 0 end 
       else  (c_getemployeeworktime(o.c_bpartner_id,w.workdate) / coalesce(c_getemployeeworktimeplan(o.c_bpartner_id,w.workdate),w.worktime))*100 end 
       as percentused,
       case when c_getemployeepercentplanned(o.c_bpartner_id,w.workdate,'Started')<999 and coalesce(c_getemployeeworktimeplan(o.c_bpartner_id,w.workdate),w.worktime)=0 then 0 
            else c_getemployeepercentplanned(o.c_bpartner_id,w.workdate,'Started') end as percentplanned
FROM c_workcalender w, c_bpartner o where o.isemployee='Y';


--select zsse_dropview('c_machinecalendar_v');
CREATE OR REPLACE VIEW c_machinecalendar_v AS
SELECT w.c_workcalender_id||o.ma_machine_id as c_machinecalendar_v_id,o.ad_org_id,o.ad_client_id,o.updated,o.updatedby,o.created,o.createdby,'Y'::character as isactive,
       c_getmachineevent(o.ma_machine_id,w.workdate) as event,
       coalesce(c_getmachineworktimeplan(o.ma_machine_id,w.workdate),w.worktime) as worktimeplan, 
       to_char(coalesce(c_getmachineworkbegintime(o.ma_machine_id,w.workdate),w.workbegintime),'HH24:MI')::character varying as workbegintime,
       w.workdate,
       o.ma_machine_id,
       (select p_content from c_getmachineprojectsplan(o.ma_machine_id,w.workdate,'N','Started')) as projectsplan,
       c_getmachineprojectsworked(o.ma_machine_id,w.workdate) as projectsworked,
       c_getmachineworktime(o.ma_machine_id,w.workdate) as worktime,
       case when coalesce(c_getmachineworktimeplan(o.ma_machine_id,w.workdate),w.worktime)=0 then 
            case when c_getmachineworktime(o.ma_machine_id,w.workdate)>0 then 999 else 0 end 
       else  (c_getmachineworktime(o.ma_machine_id,w.workdate) / coalesce(c_getmachineworktimeplan(o.ma_machine_id,w.workdate),w.worktime))*100 end 
       as percentused,
       case when c_getmachinepercentplanned(o.ma_machine_id,w.workdate,'Started')<999 and coalesce(c_getmachineworktimeplan(o.ma_machine_id,w.workdate),w.worktime)=0 then 0 
            else c_getmachinepercentplanned(o.ma_machine_id,w.workdate,'Started') end as percentplanned
FROM c_workcalender w, ma_machine o; 



CREATE OR REPLACE FUNCTION c_aggregateworktimeaccount() 
RETURNS VARCHAR
AS $_$
DECLARE
/*****************************************************+
Stefan Zimmermann, 01/2015, sz@zimmermann-software.de
Aggregates all worktime accounts:

Obacht: date1 in ad user ist Eintritt ins Unternehmen!
*****************************************************/
-- SELECT zsse_logclean();

  v_message character varying;
  v_cur RECORD;
  v_target numeric;
  v_work numeric;
  i integer;
  v_month numeric;
  v_cmpyear numeric;
  v_cmpmonth numeric;
  v_year numeric;
  v_gdate timestamp;
  v_mo character varying;
  v_ye character varying;
BEGIN 
   select now()- interval '6 month' into  v_gdate;
   select  extract (year from v_gdate) into v_year;
   select extract (month from v_gdate) into v_month;
   select  extract (year from now()) into v_cmpyear;
    select extract (month from now()) into v_cmpmonth;
   
   --DELETE FROM c_empworktimeaccount where wyear >= extract (year from now()) -2;
   DELETE FROM c_empworktimeaccount where wyear >=v_year and wmonth>=v_month;
   if v_cmpyear>v_year then
        DELETE FROM c_empworktimeaccount where wyear = v_cmpyear;
   end if;
   
   GET DIAGNOSTICS i := ROW_COUNT; 
   v_message := i || ' Empworktimeaccounts deleted. - ';
        for v_cur in ( select distinct extract (year from wc.workdate) as wyear,
                                   extract (month from wc.workdate) as   wmonth,
                                                                   u.ad_user_id,
                                                                    b.ad_org_id,
                                                                b.c_bpartner_id,
                                                             date_trunc('month',
        to_date('01.'||extract (month from wc.workdate)||'.'||extract (year from wc.workdate),'dd.mm.yyyy' ) ) + interval '1 month' -1 as lastday,
       to_date('01.'||extract (month from wc.workdate)||'.'||extract (year from wc.workdate),'dd.mm.yyyy' ) as firstday,
                                                                        b.value
        from c_workcalender wc,ad_user u,c_bpartner b  
        where u.c_bpartner_id=b.c_bpartner_id and u.isactive='Y' and b.isemployee='Y' and b.isactive='Y' 
        and wc.workdate>= coalesce(u.date1,to_date('01.01.1990','dd.mm.yyyy'))
        and wc.workdate>= (select min (workdate) from zspm_ptaskfeedbackline) and wc.workdate<now()
        and wc.workdate >= v_gdate
        -- and wc.workdate >= to_date('01.01.'||extract (year from now()) -2||',dd.mm.yyyy')
       )
   LOOP     
   v_mo:=substring(to_char(v_cur.wmonth,'09') from 2 for 2);
   v_ye:=to_char(v_cur.wyear,'9999');
   --raise exception '%', length(v_mo);
    select     sum(dtotal) + sum(dpaidbreak),    sum(dsoll) into v_work,    v_target 
    from zssi_getdayset(v_cur.c_bpartner_id,to_char(v_cur.wmonth,'99'),to_char(v_cur.wyear,'9999'),'de_DE');
    insert into c_empworktimeaccount(c_empworktimeaccount_id, 
                                                AD_Client_ID, 
                                                    AD_Org_ID,
                                                    CreatedBy, 
                                                    UpdatedBy,
                                                    ad_user_id,
                                                    wyear,
                                                    wmonth,
                                                    targethours,
                                                    workhours,
                                                    value,
                                                    holiday_entitlement
                                                    )
    values (get_uuid(),'C726FEC915A54A0995C568555DA5BB3C',v_cur.ad_org_id,'0','0',v_cur.ad_user_id, v_cur.wyear, v_cur.wmonth, v_target,v_work,v_cur.value,coalesce(zssi_getHolidayEntitlement(v_cur.c_bpartner_id ,v_mo,v_ye),zssi_calculatevacationaccountbalance(v_cur.c_bpartner_id ,to_char(v_cur.wmonth,'99'),to_char(v_cur.wyear,'9999'))));
    i :=i+1; 
   END LOOP;
   update c_empworktimeaccount set balance=zssi_calculatetimeaccountbalance(ad_user_id,wmonth,wyear)
    where wyear >=v_year and wmonth>=v_month;--wyear >= extract (year from now()) -2;
   if v_cmpyear>v_year then
        update c_empworktimeaccount set balance=zssi_calculatetimeaccountbalance(ad_user_id,wmonth,wyear)
            where wyear =v_cmpyear and wmonth<=v_cmpmonth;
   end if;
 
    -- Finishing
   v_message := 'Aggregate Worktimeaccount finished:' || v_message||' '||i||' Employee Worktime accounts created.';
   RETURN v_message;
END;
$_$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_calendarevent_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
 -- Do not delete 
 IF TG_OP = 'DELETE' THEN
     null;
 END IF;
 IF TG_OP = 'UPDATE' THEN
    null;
 END IF;
 IF TG_OP = 'INSERT' THEN
    if new.worktime is null then
        select worktime,reminder into new.worktime,new.reminder from C_CALENDAREVENT where C_CALENDAREVENT_id=new.C_CALENDAREVENT_id;
    end if;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('c_calendarevent_trg','C_WORKCALENDAREVENT');
select zsse_DropTrigger ('c_calendarevent_trg','C_bpartneremployeeEVENT');
select zsse_DropTrigger ('c_calendarevent_trg','ma_machineEVENT');

CREATE TRIGGER c_calendarevent_trg
  BEFORE INSERT
  ON C_WORKCALENDAREVENT FOR EACH ROW
  EXECUTE PROCEDURE c_calendarevent_trg();
CREATE TRIGGER c_calendarevent_trg
  BEFORE INSERT
  ON C_bpartneremployeeEVENT FOR EACH ROW
  EXECUTE PROCEDURE c_calendarevent_trg();
CREATE TRIGGER c_calendarevent_trg
  BEFORE INSERT
  ON ma_machineEVENT FOR EACH ROW
  EXECUTE PROCEDURE c_calendarevent_trg();
 
 
CREATE OR REPLACE FUNCTION c_calendarResource_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    -- Trigger Complete Aggregation of Resource Plan by Background Process
    update c_project_processstatus set resourceplanrequested='Y';
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


CREATE OR REPLACE FUNCTION c_calendarResourceWC_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    if TG_OP = 'UPDATE'  then 
        update zspm_ptaskhrplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
            and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N'
            and coalesce(pt.startdate,now())<=new.workdate and coalesce(pt.enddate,now())>=new.workdate;
        update zspm_ptaskmachineplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
            and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N'
            and coalesce(pt.startdate,now())<=new.workdate and coalesce(pt.enddate,now())>=new.workdate;
    END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

CREATE OR REPLACE FUNCTION c_calendarResourceWCEVT_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    
    -- Trigger Complete Aggregation of Resource Plan by Background Process
    update c_project_processstatus set resourceplanrequested='Y';
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

CREATE OR REPLACE FUNCTION c_calendarResourceMSET_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    if TG_OP = 'UPDATE' or TG_OP = 'INSERT' then 
        update zspm_ptaskmachineplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
            and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N'
            and hr.ma_machine_id=new.ma_machine_id;
    END IF;
    if TG_OP = 'DELETE'  then 
        update zspm_ptaskmachineplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
            and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N'
            and hr.ma_machine_id=old.ma_machine_id;
    END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

CREATE OR REPLACE FUNCTION c_calendarResourceESET_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    if  TG_OP = 'INSERT' then
        update zspm_ptaskhrplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
                and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N'
                and hr.employee_id=(select ad_user_id from ad_user where c_bpartner_id=new.c_bpartner_id);
    end if;
    if TG_OP = 'UPDATE'  then 
        if old.ad_org_id=new.ad_org_id then
            update zspm_ptaskhrplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
                and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N'
                and hr.employee_id=(select ad_user_id from ad_user where c_bpartner_id=new.c_bpartner_id);
        end if;
    END IF;
    if TG_OP = 'DELETE'  then 
        update zspm_ptaskhrplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
            and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N'
            and hr.employee_id=(select ad_user_id from ad_user where c_bpartner_id=old.c_bpartner_id);
    END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


CREATE OR REPLACE FUNCTION c_EmployeeCalendarResource_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    if TG_OP = 'DELETE' then
        update zspm_ptaskhrplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
           and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N' and employee_id=(select ad_user_id from ad_user where c_bpartner_id=old.c_bpartner_id);
        PERFORM zssi_resourceplanupdate(null,(select ad_user_id from ad_user where c_bpartner_id=old.c_bpartner_id),old.datefrom,old.dateto);
    else
        
        if TG_OP = 'INSERT' then
           update zspm_ptaskhrplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
                and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N' and employee_id=(select ad_user_id from ad_user where c_bpartner_id=new.c_bpartner_id);
           PERFORM zssi_resourceplanupdate(null,(select ad_user_id from ad_user where c_bpartner_id=new.c_bpartner_id),new.datefrom,new.dateto); 
        end if;
        if TG_OP = 'UPDATE' then
           if old.ad_org_id=new.ad_org_id then
                update zspm_ptaskhrplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
                    and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N' and employee_id=(select ad_user_id from ad_user where c_bpartner_id=new.c_bpartner_id);
                PERFORM zssi_resourceplanupdate(null,(select ad_user_id from ad_user where c_bpartner_id=new.c_bpartner_id),least(new.datefrom,old.datefrom),greatest(new.dateto,old.dateto));
           end if;
        end if;
    end if;
    
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

CREATE OR REPLACE FUNCTION c_MachineCalendarResource_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    if TG_OP = 'DELETE' then
        update zspm_ptaskmachineplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
           and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N' and hr.ma_machine_id=old.ma_machine_id;
        PERFORM zssi_resourceplanupdate(old.ma_machine_id,null,old.datefrom,old.dateto);
    else
        update zspm_ptaskmachineplan hr set updated=hr.updated from c_projecttask pt,c_project p where hr.c_projecttask_id=pt.c_projecttask_id and pt.c_project_id=p.c_project_id 
           and p.projectstatus in ('OP','OR') and pt.istaskcancelled='N' and pt.iscomplete='N' and hr.ma_machine_id=new.ma_machine_id;
           if TG_OP = 'INSERT' then
            PERFORM zssi_resourceplanupdate(new.ma_machine_id,null,new.datefrom,new.dateto);
           end if;
           if TG_OP = 'UPDATE' then
            PERFORM zssi_resourceplanupdate(new.ma_machine_id,null,least(new.datefrom,old.datefrom),greatest(new.dateto,old.dateto));
           end if;
    end if;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('c_calendarResource_trg','C_WORKCALENDAREVENT');
select zsse_DropTrigger ('c_calendarResource_trg','C_bpartneremployeeEVENT');
select zsse_DropTrigger ('c_calendarResource_trg','ma_machineEVENT');
select zsse_DropTrigger ('c_calendarResource_trg','ma_machineCALENDARSETTINGS');
select zsse_DropTrigger ('c_calendarResource_trg','C_bpartneremployeeCALENDARSETTINGS');
select zsse_DropTrigger ('c_calendarResource_trg','C_WORKCALENDARSETTINGS');
select zsse_DropTrigger ('c_calendarResource_trg','C_WORKCALENDer');

CREATE TRIGGER c_calendarResource_trg
  after INSERT or update or delete
  ON C_WORKCALENDAREVENT FOR EACH ROW
  EXECUTE PROCEDURE c_calendarResourceWCEVT_trg();
CREATE TRIGGER c_calendarResource_trg
  after INSERT or update or delete
  ON C_bpartneremployeeEVENT FOR EACH ROW
  EXECUTE PROCEDURE c_EmployeeCalendarResource_trg();
CREATE TRIGGER c_calendarResource_trg
  after INSERT or update or delete
  ON ma_machineEVENT FOR EACH ROW
  EXECUTE PROCEDURE c_MachineCalendarResource_trg();
CREATE TRIGGER c_calendarResource_trg
  after INSERT or update or delete
  ON ma_machineCALENDARSETTINGS FOR EACH ROW
  EXECUTE PROCEDURE c_calendarResourceMSET_trg();
CREATE TRIGGER c_calendarResource_trg
  after INSERT or update or delete
  ON C_bpartneremployeeCALENDARSETTINGS FOR EACH ROW
  EXECUTE PROCEDURE c_calendarResourceESET_trg();
CREATE TRIGGER c_calendarResource_trg
  after INSERT or update or delete
  ON C_WORKCALENDARSETTINGS FOR EACH ROW
  EXECUTE PROCEDURE c_calendarResource_trg();
CREATE TRIGGER c_calendarResource_trg
  after INSERT or update or delete
  ON C_WORKCALENDer FOR EACH ROW
  EXECUTE PROCEDURE c_calendarResourceWC_trg();
  
  
CREATE OR REPLACE FUNCTION zspm_ptaskmachineplanResource_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
v_plannedtime numeric;
v_start timestamp;
v_end timestamp;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
 -- Do not delete 
 IF TG_OP = 'DELETE' THEN
     null;
 END IF;
 IF TG_OP = 'UPDATE' THEN
    null;
 END IF;
 IF TG_OP = 'INSERT' or TG_OP = 'UPDATE' THEN
    select coalesce(startdate,trunc(now())),coalesce(enddate,trunc(now())) into v_start,v_end from c_projecttask where c_projecttask_id=new.c_projecttask_id;
    if new.datefrom is not null then
        if trunc(v_start)>trunc(new.datefrom) then
            raise exception '%','@dateoutofrange@';
        end if;
        v_start:=new.datefrom;
    end if;
    if new.dateto is not null then
        if trunc(v_end)<trunc(new.dateto) then
            raise exception '%','@dateoutofrange@';
        end if;
        v_end:=new.dateto;
    end if;
    v_plannedtime:=c_getmachineworktimesheduleplan(new.ma_machine_id,v_start,v_end);
    if v_plannedtime > 0 and new.costuom='H' then
        new.planndedpercent:=(new.quantity/v_plannedtime) * 100;
    else
        if new.costuom!='H' then
            new.planndedpercent:=100;
        else
            new.planndedpercent:=999;
        end if;
    end if;    
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;
  
select zsse_DropTrigger ('zspm_ptaskmachineplanResource_trg','zspm_ptaskmachineplan');    


CREATE TRIGGER zspm_ptaskmachineplanResource_trg
  BEFORE INSERT OR UPDATE
  ON zspm_ptaskmachineplan FOR EACH ROW
  EXECUTE PROCEDURE zspm_ptaskmachineplanResource_trg();
  
CREATE OR REPLACE FUNCTION zspm_ptaskhrplanResource_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
v_plannedtime numeric;
v_bpartner varchar;
v_start timestamp;
v_end timestamp;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
 -- Do not delete 
 IF TG_OP = 'DELETE' THEN
     null;
 END IF;
 IF TG_OP = 'UPDATE' THEN
    null;
 END IF;
 IF TG_OP = 'INSERT' or TG_OP = 'UPDATE' THEN
    select coalesce(startdate,trunc(now())),coalesce(enddate,trunc(now())) into v_start,v_end from c_projecttask where c_projecttask_id=new.c_projecttask_id;
    if new.datefrom is not null then
        if trunc(v_start)>trunc(new.datefrom) then
            raise exception '%','@dateoutofrange@';
        end if;
        v_start:=new.datefrom;
    end if;
    if new.dateto is not null then
        if trunc(v_end)<trunc(new.dateto) then
            raise exception '%','@dateoutofrange@';
        end if;
        v_end:=new.dateto;
    end if;
    select c_bpartner_id into v_bpartner from ad_user  where ad_user_id=new.employee_id;
    v_plannedtime:=c_getemployeeworktimesheduleplan(v_bpartner,v_start,v_end);
    if v_plannedtime > 0 then
        new.planndedpercent:=(new.quantity/v_plannedtime) * 100;
    else
        new.planndedpercent:=999;
    end if;
    
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;
  
select zsse_DropTrigger ('zspm_ptaskhrplanResource_trg','zspm_ptaskhrplan');    


CREATE TRIGGER zspm_ptaskhrplanResource_trg
  BEFORE INSERT OR UPDATE
  ON zspm_ptaskhrplan FOR EACH ROW
  EXECUTE PROCEDURE zspm_ptaskhrplanResource_trg();
  
  
  
  
CREATE OR REPLACE FUNCTION zspm_ptaskResource_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE   
v_cur record;
BEGIN
        -- If Dates have changed, recalculate resource Planning
        IF (TG_OP = 'UPDATE') THEN
            if (coalesce(new.startdate,now()) != coalesce(old.startdate,now())) or (coalesce(new.enddate,now()) != coalesce(old.enddate,now()))
                or (coalesce(new.c_color_id,'') != coalesce(old.c_color_id,'')) then
                update zspm_ptaskhrplan set updated=updated where c_projecttask_id=new.c_projecttask_id and isactive='Y';
                update zspm_ptaskmachineplan set updated=updated where c_projecttask_id=new.c_projecttask_id and isactive='Y';
            end if;
            if old.istaskcancelled!=new.istaskcancelled then
               for v_cur in (select * from zspm_ptaskmachineplan where c_projecttask_id=new.c_projecttask_id)
               LOOP
                    PERFORM zssi_resourceplanupdate(v_cur.ma_machine_id,null,trunc(coalesce(new.startdate,now())),new.enddate);
               END LOOP;
               for v_cur in (select * from zspm_ptaskhrplan where c_projecttask_id=new.c_projecttask_id)
               LOOP
                    PERFORM zssi_resourceplanupdate(null,v_cur.employee_id,trunc(coalesce(new.startdate,now())),new.enddate);
               END LOOP;
            end if;
        end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;
  
select zsse_DropTrigger ('zspm_ptaskResource_trg','c_projecttask');    


CREATE TRIGGER zspm_ptaskResource_trg
  AFTER UPDATE
  ON c_projecttask FOR EACH ROW
  EXECUTE PROCEDURE zspm_ptaskResource_trg();

  
CREATE OR REPLACE FUNCTION c_getworktimeThisdayOvernight(p_fblID varchar, p_norm out numeric,p_over out numeric, p_night out numeric,p_sat out numeric,p_sun out numeric,p_holi out numeric)
RETURNS record AS 
$BODY$ 
DECLARE 
    v_cur record;
    v_workdyhours numeric;
    v_nightendhour timestamp:='0001-01-02 00:00:00 BC'::timestamp;
    v_nb timestamp;
    v_nomalhours numeric;
    v_bpartner varchar;
BEGIN
    p_norm:=0;
    p_over:=0;
    p_night:=0;
    p_sat:=0;
    p_sun:=0;
    p_holi:=0;
    for v_cur in (select * from zspm_ptaskfeedbackline where zspm_ptaskfeedbackline_id=p_fblID)
    LOOP
        v_workdyhours:=(SELECT ((EXTRACT (EPOCH FROM (v_nightendhour - v_cur.hour_from))) / 3600));
        select c_bpartner_id into v_bpartner from ad_user where ad_user_id=v_cur.ad_user_id;
        select c_getemployeeworktimeNormal(v_bpartner,v_cur.workdate) into v_nomalhours;
        select nightbegin into v_nb from c_additionalfees where ad_org_id in ('0',v_cur.ad_org_id) and 
           case when v_cur.ma_machine_id IS NOT NULL then 1=0 else 1=1 end and validfrom <=v_cur.workdate and isactive='Y' order by  ad_org_id desc,validfrom desc limit 1; 
        if v_cur.issaturday='Y' then p_sat:=v_workdyhours; end if;
        if v_cur.issunday='Y' then p_sun:=v_workdyhours; end if;
        if v_cur.isholiday='Y' then p_holi:=v_workdyhours;p_sun:=0; p_sat:=0; end if;
        if v_cur.issaturday='N' and  v_cur.issunday='N' and v_cur.isholiday='N' then
            p_night:=(SELECT ((EXTRACT (EPOCH FROM (v_nightendhour-greatest(v_nb,v_cur.hour_from)))) / 3600));
            p_norm:=(SELECT ((EXTRACT (EPOCH FROM (v_nb-v_cur.hour_from))) / 3600));
            if p_norm<0 then p_norm:=0; end if;
            if p_norm>v_nomalhours then                
                p_over:=p_norm-v_nomalhours;
                p_norm:=v_nomalhours;
            end if;
        end if;
    END LOOP;
    return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION c_getworktimeNEXTDayOvernight(p_fblID varchar, p_norm out numeric,p_over out numeric, p_night out numeric,p_sat out numeric,p_sun out numeric,p_holi out numeric,p_ne out timestamp)
RETURNS record AS 
$BODY$ 
DECLARE 
    v_cur record;
    v_workdyhours numeric;
    v_nightbeginhour timestamp:='0001-01-01 00:00:00 BC'::timestamp;    
    v_nomalhours numeric;
    v_bpartner varchar;
    v_hoursdaybefore numeric;
BEGIN
    p_norm:=0;
    p_over:=0;
    p_night:=0;
    p_sat:=0;
    p_sun:=0;
    p_holi:=0;
    for v_cur in (select * from zspm_ptaskfeedbackline where zspm_ptaskfeedbackline_id=p_fblID)
    LOOP
        v_workdyhours:=(SELECT ((EXTRACT (EPOCH FROM (v_cur.hour_to - v_nightbeginhour))) / 3600));       
        select c_bpartner_id into v_bpartner from ad_user where ad_user_id=v_cur.ad_user_id;
        select c_getemployeeworktimeNormal(v_bpartner,v_cur.workdate+1) into v_nomalhours;
        select nightend into p_ne from c_additionalfees where ad_org_id in ('0',v_cur.ad_org_id) and 
           case when v_cur.ma_machine_id IS NOT NULL then 1=0 else 1=1 end and validfrom <=v_cur.workdate and isactive='Y' order by  ad_org_id desc,validfrom desc limit 1; 
           
        if (select dayname from c_workcalender where trunc(workdate)=trunc(v_cur.workdate+1))='6' then   
           p_sat:=v_workdyhours;
        end if;
        if (select dayname from c_workcalender where trunc(workdate)=trunc(v_cur.workdate+1))='7' then
           p_sun:=v_workdyhours; 
        end if;
        if ((select isholiday from c_workcalender where trunc(workdate)=trunc(v_cur.workdate+1))='Y' or (
                                      select isholyday from C_CALENDAREVENT,C_WORKCALENDAREVENT where C_CALENDAREVENT.C_CALENDAREVENT_id=C_WORKCALENDAREVENT.C_CALENDAREVENT_ID  and C_WORKCALENDAREVENT.ad_org_id=v_cur.ad_org_id
                                      and trunc(v_cur.workdate+1) between datefrom and  coalesce(dateto,datefrom) order by isholyday desc limit 1)='Y')
        then
           p_holi:=v_workdyhours; 
           p_sat:=0;
           p_sun:=0;
        end if;
        if p_sat=0 and p_sun=0 and p_holi=0 then
            p_night:=(SELECT ((EXTRACT (EPOCH FROM (least(p_ne,v_cur.hour_to)-v_nightbeginhour))) / 3600));
            p_norm:=(SELECT ((EXTRACT (EPOCH FROM (v_cur.hour_to-p_ne))) / 3600));
            if p_norm<0 then p_norm:=0; end if;
            select a.p_norm+a.p_over+a.p_night+a.p_sat+a.p_sun+a.p_holi 
                   into v_hoursdaybefore from c_getworktimethisdayOvernight(p_fblID) a;
            if v_hoursdaybefore+p_night+p_norm>v_nomalhours then    
                if v_nomalhours-v_hoursdaybefore-p_night > 0 then
                    p_norm:=v_nomalhours-v_hoursdaybefore-p_night;
                    p_over:=(SELECT ((EXTRACT (EPOCH FROM (v_cur.hour_to-p_ne))) / 3600))-p_norm;
                    if p_over<0 then p_over:=0; end if;
                else
                    p_over:=p_norm;
                    p_norm:=0;
                end if;                
            end if;
        end if;
    END LOOP;
    return;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
select zsse_dropfunction('zssi_getdayset');
CREATE OR REPLACE FUNCTION zssi_getdayset(p_employee character varying, p_month varchar, p_year varchar,p_lang varchar, OUT mday character varying,OUT wdate timestamp without time zone,OUT mm character varying,OUT my character varying, OUT mnum character varying, OUT dfrom timestamp, OUT dto timestamp, OUT dbreak numeric, OUT dpaidbreak numeric, OUT dspec numeric, OUT dspec2 numeric,OUT dspec3 numeric, OUT dtrigger numeric, OUT dspecial4 numeric,OUT dspecial5 numeric, OUT dtravel numeric, OUT dtotal numeric, OUT dnorm numeric, OUT dnight numeric, OUT dsat numeric, OUT dsun numeric, OUT dholi numeric, OUT dover numeric, OUT dvacanc numeric, OUT dill numeric, OUT dsoll numeric, OUT dworkplace varchar)
RETURNS setof record AS
$_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
***************************************************************************************************************************************************
Stundenzettel Funktion
*****************************************************/
DECLARE
v_curcal record;
v_cur record;
v_return character varying:='';
v_dd character varying:='';
v_dn character varying:='';
v_m character varying:='';
v_y character varying:='';
v_event varchar;
v_Empevent varchar;
v_evtWtime numeric;
v_Empevname varchar;
v_OrgEvent varchar;
v_OrgEvname varchar;
v_orgid varchar;
v_time numeric;
v_currdate timestamp:='infinity'::timestamp;
v_userid character varying:='';
v_sm numeric:=to_number(p_month);
v_sy numeric:=to_number(p_year);
v_sdate character varying:=v_sy||'-'||v_sm||'-'||1;
v_edate date := (select last_dayofmonth(to_date(v_sdate, 'YYYY-MM-DD')));
v_bre numeric;
v_ne timestamp; -- Nifght end
BEGIN
SELECT u.ad_user_id,b.ad_org_id into v_userid,v_orgid from ad_user u,c_bpartner b where u.c_bpartner_id=b.c_bpartner_id and b.c_bpartner_id=p_employee;

for v_curcal in (select workdate as datenow from c_workcalender where workdate between to_date(v_sdate,'YYYY-MM-DD') and v_edate order by workdate)
LOOP
select c_getemployeeworktimeNormal(p_employee,v_curcal.datenow) into v_time;
dsoll:=v_time;
for v_cur in (select fbl.zspm_ptaskfeedbackline_id, fbl.workdate, to_char(fbl.workdate,'DY') as vdd,to_char(fbl.workdate,'MONTH') as vm, to_char(fbl.workdate,'YYYY') as vy, to_char(fbl.workdate,'DD') as vdn,p.c_project_id,  fbl.hour_from, fbl.hour_to, fbl.hours, fbl.issunday, fbl.issaturday, fbl.isholiday, fbl.dayhours, fbl.breaktime, fbl.paidbreaktime, fbl.zspm_ptaskfeedbackline_id, fbl.traveltime, fbl.specialtime, fbl.specialtime2,fbl.specialtime3,fbl.triggeramt,fbl.special4,fbl.special5,fbl.overtimehours, fbl.c_projecttask_id, fbl.nighthours, fbl.ad_user_id 
from zspm_ptaskfeedbackline fbl,c_project p where p.c_project_id=fbl.c_project_id and p.timekeeping='Y' and fbl.workdate = v_curcal.datenow and fbl.ad_user_id=v_userid order by fbl.hour_from)
  LOOP
    -- Sollarbeitszeit nur einmal am Tag.
    if v_currdate!=v_curcal.datenow then
        v_currdate:=v_curcal.datenow;
    else
        dsoll:=0;
    end if;
    dnorm:=0;
    dnight:=v_cur.nighthours;
    if v_cur.issunday='Y' or v_cur.issaturday='Y' or v_cur.isholiday='Y' then
        if (v_cur.issunday='Y') then            
            dsun:=v_cur.hours;
            dsat:=0;
            dholi:=0;
        end if;
        if (v_cur.issaturday='Y') then
            dsat:=v_cur.hours;   
            dsun:=0;
            dholi:=0;
        end if;
        if (v_cur.isholiday='Y')then
            dholi:=v_cur.hours;
            dsat:=0;
            dsun:=0;
        end if;
    else
        dsat:=0;
        dsun:=0;
        dholi:=0;
    end if;
    mday:=v_cur.vdd;
    mnum:=v_cur.vdn;
    dfrom:=v_cur.hour_from;
    dto:=v_cur.hour_to;
    dbreak:=coalesce(v_cur.breaktime,0);
    dpaidbreak:=coalesce(v_cur.paidbreaktime,0);
    dspec:=coalesce(v_cur.specialtime,0);
    dspec2:=coalesce(v_cur.specialtime2,0);
    dspec3:=coalesce(v_cur.specialtime3,0);
    dtrigger:=coalesce(v_cur.triggeramt,0);
    dspecial4:=coalesce(v_cur.special4,0);
    dspecial5:=coalesce(v_cur.special5,0);
    dtravel:=coalesce(v_cur.traveltime,0);
    dtotal:=coalesce(v_cur.hours,0);

    -- Feiertage : Da zählt Soll-Arbeitszeit als gesamt, wenn weniger als soll gearbeitet wurde
    if (v_cur.isholiday='Y' and dholi<coalesce(dsoll,0)) then
        dtotal:=coalesce(dsoll,0);
    end if;
    wdate:=v_cur.workdate;
    dover:=v_cur.overtimehours;
    if dsun=0 and dsat=0 and dholi=0 then 
        dnorm:=coalesce(v_cur.hours,0)-v_cur.nighthours-v_cur.overtimehours;
    end if;
    
    if dnorm < 0 then dnorm:=0; end if;
    dvacanc:=0;
    dill:=0;
    mm:=v_cur.vm;
    my:=v_cur.vy;
    select p.value||'-'||p.name into dworkplace from c_project p where p.c_project_id=v_cur.c_project_id;
    
    -- Über Nacht gearbeitet..
    if v_cur.hour_to<v_cur.hour_from then        
        -- Erster Teil der Nacht
        select p_norm,p_over,p_night,p_sat,p_sun,p_holi into dnorm,dover,dnight,dsat,dsun,dholi from c_getworktimeThisdayOvernight(v_cur.zspm_ptaskfeedbackline_id);
        -- Zweiter Teil der Nacht
        select p_norm+dnorm,p_over+dover,p_night+dnight,p_sat+dsat,p_sun+dsun,p_holi+dholi,p_ne into dnorm,dover,dnight,dsat,dsun,dholi,v_ne from c_getworktimeNEXTDayOvernight(v_cur.zspm_ptaskfeedbackline_id); 
        select greatest(dnorm,dnight,dsat,dsun,dholi) into v_bre;
        if dnorm>0 then dnorm:=dnorm-coalesce(v_cur.breaktime,0); elsif dnight=v_bre then dnight:=dnight-coalesce(v_cur.breaktime,0); elsif dsat=v_bre then dsat:=dsat-coalesce(v_cur.breaktime,0); 
           elsif dsun=v_bre then dsun:=dsun-coalesce(v_cur.breaktime,0); elsif dholi=v_bre then dholi:=dholi-coalesce(v_cur.breaktime,0);
        end if;
        -- Nächsten Tag Bez Pause wandert von Nachtschicht auf Überstunden.
        if dpaidbreak>0 and dnight>0 and dsun=0 and dsat=0 and dholi=0 then
            if v_ne<v_cur.hour_to then -- Next Day Normal or Over
                if dover>0 or dnorm=dsoll then
                    dover:=dover+dpaidbreak;
                else
                    dnorm:=dnorm+dpaidbreak;
                end if;
                dnight:=dnight-dpaidbreak;
            end if;
        end if;
        -- An so und sa gilt es als Überstunde , nicht aber an Feiertagen       
        if dpaidbreak>0 and (dsun>0 or dsat>0) then
            dover:=dover+dpaidbreak;
            --if dholi>0 then dholi:=dholi-dpaidbreak; els
            if
               dsun>0 then dsun:=dsun-dpaidbreak; elsif
               dsat>0 then dsat:=dsat-dpaidbreak; 
            end if;            
        end if;
    end if;
    
    
    -- Halbe Tage Urlaub etc...
    select p_correlation,p_eventname,p_whours into v_Empevent,v_Empevname,v_evtWtime from c_getemployeeeventCorrelation(p_employee,v_curcal.datenow,p_lang);
    if (v_Empevent='2' and coalesce(v_evtWtime,0)>0) then
            dvacanc:=coalesce(v_time,0)-coalesce(v_evtWtime,0);
            dtotal:=dtotal + dvacanc;
    end if;
    -- Ganze Tage Urlaub, an denen trotzdem gearbeitet wurde...
    if (v_Empevent='2' and coalesce(v_evtWtime,0)=0) then
            dworkplace:=substr(v_Empevname||'-'||dworkplace,1,60);
            dvacanc:=coalesce(v_time,0);
            dtotal:=coalesce(v_time,0)+coalesce(v_cur.hours,0);
    end if;
    -- Auslöse, Arbeitsstunden bei Krankheit.
    if (v_Empevent='1') then
            dworkplace:=substr(v_Empevname||'-'||dworkplace,1,60);
            dill:=coalesce(v_time,0);
            dtotal:=coalesce(v_time,0)+coalesce(v_cur.hours,0);        
    end if;
    if v_cur.hour_to>=v_cur.hour_from then -- Tagschicht
        -- Bezahlte Pause einer Kategorie zuordnen
        if (0 = dholi AND dholi = dsat AND dsat = dsun) then
            if dnight=0 and dover=0 then
                dnorm:=dnorm + dpaidbreak;
            end if;
            if dover>0 then
                dover := dover + dpaidbreak;
            end if;
            if dnight>0 and dover=0 then
                dnight:= dnight;
            end if;
        else
            if dholi > 0 then 
                if dnight=0 and dover=0 then
                    dholi := dholi + dpaidbreak;
                end if;
                if dover>0 then
                    dover := dover + dpaidbreak;
                end if;
                if dnight>0 and dover=0 then
                    dnight:= dnight;
                end if;
            elsif dsat > 0 and dsun = 0 then 
                dsat := dsat + dpaidbreak;
            elsif dsun > 0 then 
                if dnight=0 and dover=0  then
                    dsun := dsun + dpaidbreak;
                end if;
                if dover>0 then
                    dover := dover + dpaidbreak;
                end if;
                if dnight>0 and dover=0 then
                    dnight:= dnight;
                end if;
            end if;	
        end if;
    end if;
    return next;
  END LOOP;
  
  --- Urlaub, Freizeit, Kalender Events
  select p_correlation,p_eventname,p_whours into v_Empevent,v_Empevname,v_evtWtime from c_getemployeeeventCorrelation(p_employee,v_curcal.datenow,p_lang);
  select p_correlation,p_eventname into v_OrgEvent,v_OrgEvname from c_getOrgeventCorrelation(v_orgid,v_curcal.datenow,p_lang);
  if (select count (*) from zspm_ptaskfeedbackline where workdate = v_curcal.datenow and ad_user_id=v_userid) = 0 then 
    dsat:=0;
    dsun:=0;
    dholi:=0;
    mday:=to_char(v_curcal.datenow,'DY');
    mnum:=to_char(v_curcal.datenow,'DD');
    mm:=to_char(v_curcal.datenow,'MONTH');
    my:=to_char(v_curcal.datenow,'YYYY');
    dfrom:=null;
    dto:=null;
    dbreak:=0;
    dpaidbreak:=0;
    dspec:=0;
    dspec2:=0;
    dspec3:=0;
    dtrigger:=0;
    dspecial4:=0;
    dspecial5:=0;
    dtravel:=0;
    dtotal:=0;
    dnorm:=0;
    wdate:=v_curcal.datenow;
    dnight:=0;
    dover:=0;
    dvacanc:=0;
    dill:=0;
    dworkplace:=null;
    -- If Org Event has Correlation = 5 -HOLIDAY- , It Beats Emp Event (Standard Time counts)
    -- Otherwise Emp Event beats Org Event.
    if coalesce(v_OrgEvent,'x')='5' then
        v_event:='5';
        dworkplace:=v_OrgEvname;
    else
        if v_Empevent is not null then 
            dworkplace:=v_Empevname;   
            v_event:=v_Empevent;
        else
            dworkplace:=v_OrgEvname;   
            v_event:=v_OrgEvent;
        end if;
    end if;
    if (coalesce(v_event,'') != '') then
        
        -- Urlaub
        if (v_event='2') then
            dvacanc:=coalesce(v_time,0)-coalesce(v_evtWtime,0);
            dtotal:=dvacanc;
            -- Bei Urlaub und Krankheit: Wochenenden und Feiertage ausblenden.
            if coalesce(v_time,0)=0 then
                dworkplace:='';
            end if;
        end if;
        -- Krank
        if (v_event='1') then
            dill:=coalesce(v_time,0);
            dtotal:=dill;
            -- Bei Urlaub und Krankheit: Wochenenden und Feiertage ausblenden.
            if coalesce(v_time,0)=0 then
                dworkplace:='';
            end if;
        end if;
        -- Freizeitausgleich
	if (v_event='3') then	
            if coalesce(v_time,0)=0 then
                dworkplace:='';
            end if;
	end if;
        -- Standardstunden Normalarbeitszeit
        if (v_event='4') then
            dnorm:=coalesce(v_time,0);
            dtotal:=dnorm;
        end if;
        -- Feiertag, zählt nur bei Gesamtstunden
        if (v_event='5') then
            dtotal:=coalesce(v_time,0);
        end if;
    end if;
    return next;
   end if;
  END LOOP;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select zsse_dropfunction('zssi_checkifholiday');
CREATE or replace FUNCTION zssi_checkifholiday(p_date timestamp with time zone) RETURNS character varying
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
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_date timestamp without time zone;

BEGIN
v_date:=to_timestamp(p_date);
select isholiday into v_return from c_workcalender where v_date=workdate;
RETURN coalesce(v_return,'N');
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
    select zsse_dropfunction('zssi_checkiforgholiday');
CREATE or replace FUNCTION zssi_checkiforgholiday(p_date timestamp with time zone, p_org character varying) RETURNS character varying
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
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_event character varying;
v_date timestamp without time zone;
v_org character varying:= coalesce(p_org,'0');
BEGIN
v_date:=to_timestamp(p_date);
select C_Calendarevent_ID into v_event from C_workcalendarevent where (v_date between datefrom and dateto or v_date=datefrom) and ad_org_id=v_org;
select isholyday into v_return from c_calendarevent where c_calendarevent_id=v_event;
RETURN coalesce(v_return,'N');
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


  
CREATE or replace FUNCTION zssi_NumofWorkdays2CaleandarDaysFromGivenDate(p_workdays numeric,p_org_id character varying,p_date timestamp) RETURNS numeric
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
*************************************************************************************************************************************************/
DECLARE
  v_workdays numeric;
  v_cur record;
  v_workdayscounter numeric:=0;
  v_calendarcounter numeric:=0;
  v_worktime numeric;
BEGIN
    for v_cur in (select worktime,workdate,isweekend,isholiday from c_workcalender where workdate > trunc(p_date) order by workdate)
    LOOP
        v_worktime:=coalesce(c_getorgworktime(p_org_id,v_cur.workdate),v_cur.worktime);
        if v_worktime>0 and v_cur.isweekend='N' and v_cur.isholiday='N' then
            v_workdayscounter:=v_workdayscounter+1;
            if p_workdays=0 then
                exit;
            end if;
        end if;
        v_calendarcounter:=v_calendarcounter+1;
        if v_workdayscounter=p_workdays then
            exit;
        end if;
    END LOOP;
    return v_calendarcounter;
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;  
  
select zsse_dropfunction('zssi_getusercolor');
CREATE or replace FUNCTION zssi_getusercolor(p_user_id character varying) RETURNS character varying
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
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_user character varying;
BEGIN
v_user:=(select ad_user_id from ad_user where c_bpartner_id=p_user_id);
select htmlnotation into v_return from c_color where c_color_id in (select c_color_id from ad_user where ad_user_id=v_user);
RETURN coalesce(v_return,'#808080');
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
      select zsse_dropfunction('zssi_getmachinecolor');
CREATE or replace FUNCTION zssi_getmachinecolor(p_machine_id character varying) RETURNS character varying
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
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_machine character varying;
BEGIN
select htmlnotation into v_return from c_color where c_color_id in (select c_color_id from ma_machine where ma_machine_id=p_machine_id);
RETURN coalesce(v_return,'#808080');
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE or replace FUNCTION zssi_getworktimeaccountbalance(p_employee_id character varying, p_month varchar, p_year varchar) RETURNS numeric
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/
DECLARE
v_return numeric;
v_user varchar;
BEGIN
select ad_user_id into v_user from ad_user where c_bpartner_id=p_employee_id limit 1;
select balance into v_return from c_empworktimeaccount where ad_user_id=v_user and wyear=to_number(p_year) 
       and  wmonth=to_number(p_month); 
RETURN coalesce(v_return,0);
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
    
  
select zsse_dropfunction('zssi_calculatetimeaccountbalance'); 
CREATE or replace FUNCTION zssi_calculatetimeaccountbalance(p_user_id character varying, p_month numeric, p_year numeric) RETURNS numeric
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/
DECLARE
v_return numeric:=0;
v_zwischen numeric:=0;
v_i numeric;
v_beginbalance numeric;
v_month numeric;
v_year numeric;
v_zuscha numeric;
v_iswcaccount varchar;
BEGIN

    select coalesce(workhourswithoutpaidovertime,0),isworktimeaccountactive into v_zuscha,v_iswcaccount from c_bp_salcategory where 
            c_bpartner_id=(select c_bpartner_id from ad_user where ad_user_id=p_user_id)
            and datefrom<=to_date('01.'||case when p_month<10 then '0'||to_char(p_month) else to_char(p_month) end||'.'||p_year,'dd.mm.yyyy')
            order by datefrom desc limit 1;
    if  v_iswcaccount='N' then
        return 0;
    end if;
        
    select newbalance,wyear,wmonth into v_beginbalance,v_year,v_month from c_empworktimeaccountbalance 
        where c_bpartner_id=(select c_bpartner_id from ad_user where ad_user_id=p_user_id)  and wyear<=p_year 
        and case when wyear=p_year then to_number(wmonth)<=p_month else 1=1 end
        order by wyear desc,wmonth desc limit 1;
        -- raise exception '%',v_beginbalance||'#'||v_year||'#'||v_month;
    if v_beginbalance is null then
        v_beginbalance:=0;
    end if;
    -- Durch die Jahre....
    if coalesce(v_year,2200) < p_year then
        for v_i in v_year..p_year-1
        LOOP
            if v_i=v_year then
                select sum(workhours-v_zuscha)-sum(targethours) into v_zwischen  from c_empworktimeaccount where ad_user_id=p_user_id  and wyear=v_i and wmonth>=coalesce(v_month,0);
            else
                select sum(workhours-v_zuscha)-sum(targethours) into v_zwischen  from c_empworktimeaccount where ad_user_id=p_user_id  and wyear=v_i;
            end if;
            v_return:=v_return+coalesce(v_zwischen,0);
            v_month:=0;
        END LOOP;
    end if;
           
    /*           
    select sum(case when (workhours-targethours-v_zuscha)>=0 then workhours-v_zuscha else workhours end)-sum(targethours) into v_return from c_empworktimeaccount where ad_user_id=p_user_id and wyear<=p_year and wyear>=coalesce(v_year,1900)
        and case when wyear=p_year then wmonth<=p_month and wmonth>=coalesce(v_month,0) else 1=1 end; 
    */
    -- Inclusivstunden immer abziehen...
    /*
    select sum(workhours-v_zuscha)-sum(targethours) into v_return from c_empworktimeaccount where ad_user_id=p_user_id and wyear<=p_year and wyear>=coalesce(v_year,1900)
        and case when wyear=p_year then wmonth<=p_month and wmonth>=coalesce(v_month,0) else 1=1 end; 
    */
    select sum(workhours-v_zuscha)-sum(targethours) into v_zwischen  from c_empworktimeaccount where ad_user_id=p_user_id  and wyear=p_year and wmonth<=p_month and wmonth>=coalesce(v_month,0) ;
    v_return:=v_return+coalesce(v_zwischen,0);
    RETURN coalesce(v_return,0)+v_beginbalance;
END $_$ LANGUAGE plpgsql VOLATILE
COST 100;  
  
  
select zsse_dropfunction('zssi_calculatevacationaccountbalance');   
CREATE or replace FUNCTION zssi_calculatevacationaccountbalance(p_bpartner_id character varying, p_month varchar, p_year varchar) RETURNS numeric
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/
DECLARE
v_return numeric;
v_beginbalance numeric;
v_month numeric;
v_year numeric;
v_zuscha numeric;
v_iswcaccount varchar;
BEGIN


select remaining,wyear,to_number(wmonth) into v_beginbalance,v_year,v_month from c_vacation_account 
       where c_bpartner_id=p_bpartner_id  and wyear<=to_number(p_year) 
       and case when wyear=to_number(p_year) then to_number(wmonth)<=to_number(p_month) else 1=1 end
       order by wyear desc,to_number(wmonth) desc limit 1;
       --raise exception '%',v_beginbalance||'#'||v_year||'#'||v_month;
if v_beginbalance is null then
    v_beginbalance:=0;
end if;
RETURN v_beginbalance;
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;  


CREATE OR REPLACE FUNCTION zssi_checkIfHolidayOrWeekend(p_date timestamp without time zone, p_org character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
**************************************************************************************************************************************************
*/
DECLARE

v_isHolyday character varying;
v_isWeekend character varying;

v_event character varying;
v_org character varying := coalesce(p_org, '0');

BEGIN

  SELECT isholiday, isweekend into v_isHolyday, v_isWeekend from C_workcalender where workdate = p_date::date; 
  if(v_isHolyday = 'Y' OR v_isWeekend = 'Y') then
	return 'Y';

  else
  	select C_Calendarevent_ID into v_event from C_workcalendarevent where (p_date between datefrom and COALESCE(dateto, datefrom) or p_date::date=datefrom::date) and ad_org_id=v_org;
  	select isholyday into v_isHolyday from c_calendarevent where c_calendarevent_id=v_event;
  end if;
	
  return coalesce(v_isHolyday, 'N');

END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssi_countSumOfHolidayDaysTaken(p_bpartner_id character varying, p_firstDayOfSpan timestamp without time zone, p_lastDayOfMonth timestamp without time zone) RETURNS NUMERIC
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
**************************************************************************************************************************************************
*/
DECLARE

v_bpartneremployeeevent c_bpartneremployeeevent%rowtype;
v_yearOfCalculation NUMERIC;
v_datefrom timestamp without time zone;
v_dateto timestamp without time zone;
v_startDate timestamp without time zone;
v_stopDate timestamp without time zone;
v_sumOfHolidayDaysTaken NUMERIC := 0; 

BEGIN

  v_yearOfCalculation := EXTRACT(year from p_lastDayOfMonth);


  -- für jeden Eintrag, der Urlaub und vor dem angegeben Zeitpunkt und wo ein Teil im selben Jahr ist
  FOR v_bpartneremployeeevent IN(SELECT * from c_bpartneremployeeevent cbpe, c_calendarevent cce where cbpe.c_calendarevent_id = cce.c_calendarevent_id AND cce.correlation = '2' AND cce.isemployeecalendar = 'Y' AND cbpe.c_bpartner_id = p_bpartner_id AND datefrom::date <= p_lastDayOfMonth::date AND (EXTRACT(year from datefrom) = v_yearOfCalculation OR EXTRACT(year from dateto) = v_yearOfCalculation))  
	
	LOOP

		v_startDate := (SELECT (CASE WHEN (v_bpartneremployeeevent.datefrom::date > p_firstDayOfSpan::date) THEN v_bpartneremployeeevent.datefrom ELSE p_firstDayOfSpan END));

		v_stopDate = COALESCE(v_bpartneremployeeevent.dateto::date, v_startDate);
		v_stopDate := (SELECT CASE WHEN (v_stopDate::date < p_lastDayOfMonth::date) THEN v_stopDate ELSE p_lastDayOfMonth END);
		

		while(v_startDate::date <= v_stopDate::date) 
		LOOP

			-- Wenn angegebener Tag kein Feier- oder Wochenendstag ist
			if (zssi_checkIfHolidayOrWeekend(v_startDate, v_bpartneremployeeevent.ad_org_id) = 'N') then

				if(COALESCE(v_bpartneremployeeevent.worktime, 0) > 0) then

					v_sumOfHolidayDaysTaken := 0.5 + v_sumOfHolidayDaysTaken;
				else
					v_sumOfHolidayDaysTaken := 1 + v_sumOfHolidayDaysTaken;

				end if;
			end if;

			v_startDate := v_startDate + (INTERVAL '1 day');
		END LOOP;

  END LOOP;

  RETURN v_sumOfHolidayDaysTaken;
END;
$_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION zssi_getHolidayEntitlement(p_bpartner_id character varying, p_month character varying, p_year character varying) RETURNS NUMERIC
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
- Diese Funktion wird von einem Callout aus ausgerufen
- Eingabe-Parameter stammen aus einer Zeile der Tabelle c_vacation_account
*****************************************************/
DECLARE
v_holidayEntitlementForYear NUMERIC;
v_lastDayOfMonth timestamp without time zone;
v_firstDayOfSpan timestamp without time zone;

v_tmpWMonth NUMERIC := 0;
v_remaining NUMERIC := NULL;
v_calculation NUMERIC := 0;
v_lyear varchar;
BEGIN


  	select COALESCE(number4, 0) into v_holidayEntitlementForYear from ad_user where c_bpartner_id = p_bpartner_id; 

	-- Suche nach dem jüngsten remaining-Wert aus dem selben Jahr
	-- an dieser Stelle darf das remaining auf keinen Fall coalesciciert werden
	select remaining, wmonth into v_remaining, v_tmpWMonth from c_vacation_account where c_bpartner_id = p_bpartner_id and wyear = p_year and wmonth::numeric <= p_month::numeric order by wmonth desc limit 1;


	-- Logik wenn kein Eintrag im selben Jahr gefunden wurde
  	if v_remaining is null then

		-- 1. Suche nach dem jüngsten remaining-Wert aus dem vorherigen Jahr 
		--select remaining into v_remaining from c_vacation_account where c_bpartner_id = p_bpartner_id and wyear = (p_year::numeric - 1) order by wmonth desc limit 1;
		--v_remaining := COALESCE(v_remaining, 0);
		if (select count(*) from  c_vacation_account where c_bpartner_id = p_bpartner_id and wyear::numeric<p_year::numeric)=0 then
            v_remaining:=0;
		else
            v_lyear:=to_char((p_year::numeric - 1));
            select zssi_getHolidayEntitlement(p_bpartner_id,'12',v_lyear) into v_remaining;
        end if;
		-- 2. hole den Urlaubsanspruch aus persönliche Daten
		v_calculation := v_remaining + v_holidayEntitlementForYear; 

		-- 3. verrechne den Wert mit den genommenen Urlaubstagen bis zum Ende des aktuellen Monats
		v_lastDayOfMonth := (p_year || '-' || p_month || '-01')::timestamp without time zone + (INTERVAL '1 month - 1 day');
		v_firstDayOfSpan := date_trunc('year', v_lastDayOfMonth);
  		v_remaining := v_calculation - zssi_countSumOfHolidayDaysTaken(p_bpartner_id, v_firstDayOfSpan, v_lastDayOfMonth);


	-- Logik wenn ein Eintrag im selben Jahr gefunden wurde
	else

		-- 1. verrechne den Wert mit den genommen Urlaubstagen von Start(1 Tag des nächsten Monats vom vorletzten Eintrag ausgehend) bis zum Ende des aktuellen Monats
		--raise exception '%',v_tmpWMonth||'#'||p_month||'#'||p_year;
                if  v_tmpWMonth=12 then
                    v_tmpWMonth=0;
                end if;
		v_firstDayOfSpan := (case when v_tmpWMonth=0 then to_char(to_number(p_year)+1) else p_year end|| '-' || (v_tmpWMonth + 1) || '-01')::timestamp without time zone;
		v_lastDayOfMonth := (p_year || '-' || p_month || '-01')::timestamp without time zone + (INTERVAL '1 month - 1 day');
  		v_remaining := v_remaining - zssi_countSumOfHolidayDaysTaken(p_bpartner_id, v_firstDayOfSpan, v_lastDayOfMonth);
	end if;
	
	-- dieser Wert wurde ja schon im vorherigen Eintrag gegen die genommenen Urlaubstage verrechnet
	return v_remaining;
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;  

  
CREATE OR REPLACE FUNCTION zssi_closeopentimefeedbacks() RETURNS VARCHAR -- 'SUCCESS'
AS $body$
DECLARE
    v_hours numeric;
    v_intvl interval;
    v_cur record;
BEGIN
   select to_number(value) into v_hours from ad_preference where attribute='AUTOCLOSETIMEFEEDBACKHOURS';
   if v_hours is null then v_hours:=16; end if;
   v_intvl:= INTERVAL '1 hour';
   for v_cur in (select Zspm_Ptaskfeedbackline_id,ad_user_id,workdate,hour_from,hour_to from Zspm_Ptaskfeedbackline where hour_from is not null and hour_to is null)
   LOOP
        if now()-v_cur.hour_from >= v_intvl then
            update Zspm_Ptaskfeedbackline set hour_to=hour_from+(v_intvl*v_hours),description=coalesce(description,'')||'->AUTOCLOSED' where Zspm_Ptaskfeedbackline_id=v_cur.Zspm_Ptaskfeedbackline_id;
        end if;
   END LOOP;
   RETURN 'OK';
END;
$body$
LANGUAGE 'plpgsql'
COST 100;
