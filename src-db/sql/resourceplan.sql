
select zsse_dropfunction('zssi_resourceplan_reportdata');


CREATE OR REPLACE FUNCTION zssi_resourceplan_header(p_date_from timestamp, p_date_to timestamp)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_return character varying:='';
v_pretext character varying:='<td class="DataGrid_Body_Cell DataGrid_Body_LineNoCell" style="-moz-user-select: none; width: 60px;">Employee/Date</td>';
v_posttext character varying:='</th>';
counter2 integer := 1;
BEGIN
for  v_cur in (select workdate from c_workcalender where workdate between p_date_from AND  p_date_to)
loop
counter2 := counter2 +1;
 if v_return!=' ' then v_return:=v_return||'</th><th id="date'||counter2||'" class="DataGrid_Header_Cell" onclick="cclass(''status'||counter2||''')">'; end if;
  --v_return := v_return||to_char(v_cur.workdate,'DD.MM.YYYY');
    v_return := v_return||to_char(v_cur.workdate,'DD.MM.YYYY "KW:" WW');
  end loop;
RETURN v_pretext||v_return||v_posttext;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

    CREATE OR REPLACE FUNCTION zssi_resourceplan_headerfix(p_date_from timestamp, p_date_to timestamp)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_today character varying:='';
v_styletoday character varying:='';
v_return character varying:='';
v_pretext character varying:='';
v_posttext character varying:='</div></div>';
counter2 integer := 1;
counterpos integer:=45;
widthcount integer :=0;

BEGIN
v_today:=to_char(now(),'DD.MM.YYYY');
for  v_cur in (select workdate from c_workcalender where workdate between p_date_from AND  p_date_to)
loop
if to_char(v_cur.workdate,'DD.MM.YYYY')=v_today then v_styletoday:='background-image:none !important; background-color:#d98e20;';
elsif  zssi_checkifholiday(to_timestamp(v_cur.workdate))='Y' then v_styletoday:='background-image:none !important;background-color:#808080;';
elsif  to_char(v_cur.workdate,'d')='1' then v_styletoday:='background-image:none !important;background-color:#808080;';
elsif  to_char(v_cur.workdate,'d')='7' then v_styletoday:='background-image:none !important;background-color:#808080;';
else v_styletoday:='';
end if;
counter2 := counter2 +1;
 if v_return!=' ' then v_return:=v_return||'<div class="xtFRCell" style="top:0px;width:82px;height:31px;position:relative;float:left;"><table class="xtCellTbl" style="height:31px;width:87px;"><tbody><tr><th style="text-align:center;font-weight:lighter;'||v_styletoday||'" id="date'||counter2||'" class="DataGrid_Header_Cell" onclick="cclass(''status'||counter2||''')">';
 end if;
  --v_return := v_return||to_char(v_cur.workdate,'DD.MM.YYYY');
    v_return := v_return||to_char(v_cur.workdate,'DD.MM.YYYY&nbsp;<br/>"KW:" WW ')||'</th></tr></tbody></table></div>';
  end loop;
  widthcount:=(counter2*82+100);
RETURN v_pretext||'<div id="xtFzRow" class="xtFzRow" style="width:'||widthcount||'px;height:31px;position:relative;z-Index:10;"><div class="xtFRInner" style="top:0px;height:31px;position:relative;">'||'<div id="xtHead" class="xtFRCell" style="left:-3px;top:0px;width:100px;height:31px;position:relative;float:left;z-Index:100;"><table class="xtCellTbl" style="height:31px;width:109px;"><tbody><tr><th style="text-align:center;font-weight:lighter;" class="DataGrid_Header_Cell">'||'Datum<br>Mitarbeiter'||'</th></tr></tbody></table></div>'||v_return||v_posttext;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  select zsse_dropfunction('zssi_resourceplan_headerfix_small');
CREATE OR REPLACE FUNCTION zssi_resourceplan_headerfix_small(p_date_from timestamp, p_date_to timestamp,p_project varchar, p_org varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_today character varying:='';
v_styletoday character varying:='';
v_return character varying:='';
v_pretext character varying:='';
v_posttext character varying:='</div></div>';
counter2 integer := 1;
counterpos integer:=45;
widthcount integer :=0;
BEGIN
v_today:=to_char(now(),'DD.MM.YYYY');
for  v_cur in (select workdate from (select workdate from c_workcalender where workdate between p_date_from AND  p_date_to and case when coalesce(p_project,'')!='' then 1=2 else 1=1 end
                                     union 
                                     select workdate from c_workcalender,c_project where c_project.c_project_id=p_project and workdate between startdate and datefinish) a
              order by workdate)
loop
if to_char(v_cur.workdate,'DD.MM.YYYY')=v_today then v_styletoday:='background-image:none !important; background-color:#d98e20;';
elsif  zssi_checkifholiday(to_timestamp(v_cur.workdate))='Y' then v_styletoday:='background-image:none !important;background-color:#808080;';
elsif  zssi_checkiforgholiday(to_timestamp(v_cur.workdate),p_org)='Y' then v_styletoday:='background-image:none !important;background-color:#808080;';
elsif  to_char(v_cur.workdate,'d')='1' then v_styletoday:='background-image:none !important;background-color:#808080;';
elsif  to_char(v_cur.workdate,'d')='7' then v_styletoday:='background-image:none !important;background-color:#808080;';
else v_styletoday:='';
end if;
counter2 := counter2 +1;
 if v_return!=' ' then v_return:=v_return||'<div class="xtFRCell" style="left:4px;top:11px;width:100px;height:27px;position:relative;"><table class="xtCellTbl" style="border-spacing:0px !important;border:0px !important;height:28px;width:98px;"><tbody><tr><th style="text-align:center;font-weight:lighter;'||v_styletoday||'" id="date'||counter2||'" class="DataGrid_Header_Cell" onclick="cclass(''status'||counter2||''')">';
 end if;
  --v_return := v_return||to_char(v_cur.workdate,'DD.MM.YYYY');
    v_return := v_return||to_char(v_cur.workdate,'DD.MM.YYYY&nbsp;"KW:" WW ')||'</th></tr></tbody></table></div>';
  end loop;
  widthcount:=(counter2*82+100);
RETURN v_pretext||'<div id="xtFzRow" class="xtFzRow" style="left:2px;height:82px;position:relative;z-Index:15;transform:rotate(-90deg);-webkit-transform:rotate(-90deg);-ms-transform:rotate(-90deg)"><div class="xtFRInner" style="top:-5px;height:82px;position:relative;">'||'<div id="xtHead" class="xtFRCell" style="left:2px;top:-9px;width:100px;height:81px;position:relative;z-Index:100;"><table class="xtCellTbl" style="height:102px;width:103px;"><tbody><tr><th style="text-align:center;font-weight:lighter;transform:rotate(90deg);-webkit-transform:rotate(90deg);-ms-transform:rotate(90deg)" class="DataGrid_Header_Cell">'||'Datum<br>Mitarbeiter'||'</th></tr></tbody></table></div>'||v_return||v_posttext;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select zsse_dropfunction('zssi_resourceplan_wd');

CREATE OR REPLACE FUNCTION zssi_resourceplan_wd(p_date_from timestamp, p_date_to timestamp,p_org varchar,p_planOrStarted varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_curstat RECORD;
v_curname RECORD;
v_return character varying:='';
v_return1 character varying:='';
v_pretext character varying:='<table border="1" class="DataGrid_Header_Table" id="undefined_table_header"><tr>';
v_pretext1 character varying:='<tr>';
v_posttext character varying:='</tr>';
v_posttext1 character varying:='</tbody></table>';
BEGIN
 select (zssi_resourceplan_header(p_date_from,p_date_to)) INTO v_return;
 select (zssi_resourcedates_eo(p_date_from,p_date_to,p_org,p_planOrStarted)) INTO v_return1;

RETURN v_pretext||v_return||v_pretext1||v_return1||v_posttext||v_posttext1;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_resourceplan_wdfix(p_date_from timestamp, p_date_to timestamp,p_org varchar,p_planOrStarted varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_curstat RECORD;
v_curname RECORD;
v_return character varying:='';
v_return1 character varying:='';
v_pretext character varying:='<div class="xtRoot" style="position:absolute;top:56px;left:0px;float:left;">';
v_pretext1 character varying:='';
v_posttext character varying:='';
v_posttext1 character varying:='</div>';
BEGIN
 select (zssi_resourceplan_headerfix(p_date_from,p_date_to)) INTO v_return;
 select (zssi_resourcedates_eofix(p_date_from,p_date_to,p_org,p_planOrStarted)) INTO v_return1;

RETURN v_pretext||v_return||v_pretext1||v_return1||v_posttext||v_posttext1;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
select zsse_dropfunction('zssi_resourceplan_wdfix_small');  
CREATE OR REPLACE FUNCTION zssi_resourceplan_wdfix_small(p_date_from timestamp, p_date_to timestamp,p_org varchar,p_planOrStarted varchar,p_withmachines varchar, p_project varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_curstat RECORD;
v_curname RECORD;
v_return character varying:='';
v_return1 character varying:='';
v_pretext character varying:='<div class="xtRoot" style="position:absolute;top:39px;left:0px;float:left;">';
v_pretext1 character varying:='';
v_posttext character varying:='';
v_posttext1 character varying:='</div>';
BEGIN
 select (zssi_resourceplan_headerfix_small(p_date_from,p_date_to,p_project,p_org)) INTO v_return;
 select (zssi_resourcedates_eofix_small(p_date_from,p_date_to,p_org,p_planOrStarted,p_withmachines,p_project)) INTO v_return1;

RETURN v_pretext||v_return||v_pretext1||v_return1||v_posttext||v_posttext1;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
select zsse_dropfunction('zssi_resourcedates_eo');
CREATE OR REPLACE FUNCTION zssi_resourcedates_eo(p_date_from timestamp, p_date_to timestamp,p_org varchar,p_planOrStarted varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_curstat RECORD;
v_curname RECORD;
v_return character varying:='';
v_return1 character varying:='';
v_pretext character varying:='<tr>';
v_posttext character varying:='</tr>';
counter integer := 0;
counter2 integer := 1;
v_reslink varchar;
BEGIN



for v_curname in (
       select 'BP' as rtype,b.c_bpartner_id as idkey,b.name,bpg.name as sorter from ad_user u, c_bpartner b,c_bp_group bpg 
               where u.c_bpartner_id=b.c_bpartner_id and bpg.c_bp_group_id=b.c_bp_group_id 
               and b.isemployee='Y' and b.isinresourceplan='Y' and b.isactive='Y' and u.isactive='Y' and case when p_org='0' then 1=1 else (b.ad_org_id='0' or  b.ad_org_id= p_org) end
       UNION
       select 'MA' as rtype,m.ma_machine_id as idkey,m.name,coalesce(mpg.name,'') as sorter from ma_machine m left join ma_machine_type mpg on  mpg.ma_machine_type_id=m.ma_machine_type_id
               where  m.isactive='Y' and m.isinresourceplan='Y' and case when p_org='0' then 1=1 else (m.ad_org_id='0' or  m.ad_org_id= p_org) end
       order by rtype,sorter,name
      )
loop
    if v_curname.rtype='BP' then
        for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between p_date_from AND  p_date_to)
        loop 
            counter2 := counter2 + 1;
            v_return1:=v_return1||'<td name="status'||counter2||'" class="DataGrid_Body_Cell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell''" onclick=" ''DataGrid_Body_Cell DataGrid_Body_Cell_selected DataGrid_Body_Cell_clicked''" style="text-align:left;">'||zssi_getresdesign_mul(v_curstat.workdate,v_curname.idkey,null,p_planOrStarted)||'</td>';
        end loop;
    else
       for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between p_date_from AND  p_date_to)
        loop 
            counter2 := counter2 + 1;
            v_return1:=v_return1||'<td name="status'||counter2||'" class="DataGrid_Body_Cell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell''" onclick=" ''DataGrid_Body_Cell DataGrid_Body_Cell_selected DataGrid_Body_Cell_clicked''" style="text-align:left;">'||zssi_getresdesign_mul(v_curstat.workdate,null,v_curname.idkey,p_planOrStarted)||'</td>';
        end loop;
    end if;
    counter := counter + 1;
    if v_curname.rtype='BP' then
        v_reslink:=zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.smartui.Employee/EmployeeA3D0B320B69845B386024B5FF6B1E266_Edition.html',v_curname.idkey,v_curname.name,'white');
    else
        v_reslink:=zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.asset.Machine/Machine800086_Edition.html',v_curname.idkey,v_curname.name,'white');
    end if;
    if ((counter%2)=0) Then
        v_return := v_return||'<tr id="resourceplan'||counter||'" class="DataGrid_Body_Row DataGrid_Body_Row_Even" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even''" ><td class="DataGrid_Body_Cell DataGrid_Body_LineNoCell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell''"style="-moz-user-select: none; width: 60px;">'||v_reslink||'</td>'||v_return1||'</tr>';
        Else
        v_return := v_return||'<tr id="resourceplan'||counter||'" class="DataGrid_Body_Row DataGrid_Body_Row_Odd" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd''"><td class="DataGrid_Body_Cell DataGrid_Body_LineNoCell"  onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell''"style="-moz-user-select: none; width: 60px;">'||v_reslink||'</td>'||v_return1||'</tr>';
    end if;
    v_return1:='';
end loop;    

RETURN v_return||v_posttext;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
select zsse_dropfunction('zssi_resourcedates_eofix');
CREATE OR REPLACE FUNCTION zssi_resourcedates_eofix(p_date_from timestamp, p_date_to timestamp,p_org varchar,p_planOrStarted varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_curstat RECORD;
v_curname RECORD;
--Weekend,holiday,actualday correlation
v_today character varying:='';
v_styletoday character varying:='';
v_usercol character varying:='';
--end
v_return character varying:='';
v_returnname character varying:='';
v_returncon character varying:='';
v_returncon1 character varying:='';
v_return1 character varying:='';
v_pretext character varying:='<tr>';
v_posttext character varying:='</tr>';
counter integer := 0;
countbr integer :=0;
counter2 integer := 1;
countertop integer :=0;
countereasy integer :=0;
widthcount integer :=0;
heightcount integer :=0;
conheight integer :=0;
indheightsingle integer :=0;
indheightsum integer:=0;
v_reslink varchar;
BEGIN
--Weekend,holiday,actualday correlation
v_today:=to_char(now(),'DD.MM.YYYY');
--end

for v_curname in (
       select 'BP' as rtype,b.c_bpartner_id as idkey,b.name,bpg.name as sorter from ad_user u, c_bpartner b,c_bp_group bpg 
               where u.c_bpartner_id=b.c_bpartner_id and bpg.c_bp_group_id=b.c_bp_group_id 
               and b.isemployee='Y' and b.isinresourceplan='Y' and b.isactive='Y' and u.isactive='Y' and case when p_org='0' then 1=1 else (b.ad_org_id='0' or  b.ad_org_id= p_org) end
       UNION
       select 'MA' as rtype,m.ma_machine_id as idkey,m.name,coalesce(mpg.name,'') as sorter from ma_machine m left join ma_machine_type mpg on  mpg.ma_machine_type_id=m.ma_machine_type_id
               where  m.isactive='Y' and m.isinresourceplan='Y' and case when p_org='0' then 1=1 else (m.ad_org_id='0' or  m.ad_org_id= p_org) end
       order by rtype,sorter,name
      )
loop
countereasy := countereasy+1;
countertop:=(countereasy*21)-21;

    if v_curname.rtype='BP' then
        for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between p_date_from AND  p_date_to)
        loop 
        --WHA
        if     to_char(v_curstat.workdate,'DD.MM.YYYY')=v_today then v_styletoday:='background-color:#d98e20;';	
	elsif  zssi_checkifholiday(to_timestamp(v_curstat.workdate))='Y' then v_styletoday:='background-color:#808080;';
	elsif  zssi_checkiforgholiday(to_timestamp(v_curstat.workdate),p_org)='Y' then v_styletoday:='background-color:#808080;';
	elsif  to_char(v_curstat.workdate,'d')='1' then v_styletoday:='background-color:#808080;';
	elsif  to_char(v_curstat.workdate,'d')='7' then v_styletoday:='background-color:#808080;';
	else v_styletoday:='';
	end if;
	--end
            counter2 := counter2 + 1;
            v_returncon1:=zssi_getresdesign_mul(v_curstat.workdate,v_curname.idkey,null,p_planOrStarted);
            v_return1:=v_return1||'<td name="status'||counter2||'" width="80" class="DataGrid_Body_Cell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell''" onclick=" ''DataGrid_Body_Cell DataGrid_Body_Cell_selected DataGrid_Body_Cell_clicked''" style="text-align:left;font-size:7px !important;text-indent:0px !important;padding:0px !important;vertical-align:top !important;'||v_styletoday||'">'||v_returncon1||'</td>';
	    --v_returncon1:=zssi_2html(zssi_getresdesign_content(v_curstat.workdate,v_curname.idkey,null,p_planOrStarted));
	    --SELECT count(*)-1 into countbr  FROM regexp_split_to_table(v_returncon1,E'<br/>');
	    countbr:=((length(v_returncon1)-length(replace(v_returncon1,'LabelLink','')))/9);
IF(countbr=3) then
indheightsingle:=29; 
countbr:=0;
v_returncon:='3';
ELSIF(countbr=4) then                      
 indheightsingle:=38;
 countbr:=0;
 v_returncon:='4';
ELSIF(countbr=5) then
 indheightsingle:=47; 
 countbr:=0;
 v_returncon:='5';
  ELSIF(countbr=2) then                      
 indheightsingle:=29;
 v_returncon:='4';
 countbr:=0;
 ELSIF(countbr=6) then
 indheightsingle:=56; 
 v_returncon:='5';
 countbr:=0;
 ELSIF(countbr=7) then
 indheightsingle:=65; 
 v_returncon:='5';
 countbr:=0;
 ELSIF(countbr=8) then
 indheightsingle:=74; 
 v_returncon:='5';
 countbr:=0;
  ELSIF(countbr=9) then
 indheightsingle:=83; 
 v_returncon:='5';
 countbr:=0;
ELSIF(countbr>=10) then
 indheightsingle:=92; 
  v_returncon:='6';
  countbr:=0;
END IF;
       end loop;
    else
       for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between p_date_from AND  p_date_to)
        loop 
        --WHA
        if     to_char(v_curstat.workdate,'DD.MM.YYYY')=v_today then v_styletoday:='background-color:#d98e20;';	
	elsif  zssi_checkifholiday(to_timestamp(v_curstat.workdate))='Y' then v_styletoday:='background-color:#808080;';
	elsif  zssi_checkiforgholiday(to_timestamp(v_curstat.workdate),p_org)='Y' then v_styletoday:='background-color:#808080;';
	elsif  to_char(v_curstat.workdate,'d')='1' then v_styletoday:='background-color:#808080;';
	elsif  to_char(v_curstat.workdate,'d')='7' then v_styletoday:='background-color:#808080;';
	else v_styletoday:='';
	end if;
	--end
            counter2 := counter2 + 1;
            v_returncon1:=zssi_getresdesign_mul(v_curstat.workdate,null,v_curname.idkey,p_planOrStarted);
            v_return1:=v_return1||'<td name="status'||counter2||'" width="80" class="DataGrid_Body_Cell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell''" onclick=" ''DataGrid_Body_Cell DataGrid_Body_Cell_selected DataGrid_Body_Cell_clicked''" style="text-align:left;font-size:7px !important;text-indent:0px !important;padding:0px !important;vertical-align:top !important;'||v_styletoday||'">'||v_returncon1||'</td>';
	    --v_returncon1:=zssi_2html(zssi_getresdesign_content(v_curstat.workdate,null,v_curname.idkey,p_planOrStarted));
	    --SELECT count(*)-1 into countbr  FROM regexp_split_to_table(v_returncon1,E'<br/>'); 
	   countbr:=((length(v_returncon1)-length(replace(v_returncon1,'LabelLink','')))/9); 
IF(countbr=3) then
indheightsingle:=29; 
v_returncon:='3';
countbr:=0;
ELSIF(countbr=4) then                      
 indheightsingle:=38;
 v_returncon:='4';
 countbr:=0;
 ELSIF(countbr=2) then                      
 indheightsingle:=29;
 v_returncon:='4';
 countbr:=0;
ELSIF(countbr=5) then
 indheightsingle:=47; 
 v_returncon:='5';
 countbr:=0;
 ELSIF(countbr=6) then
 indheightsingle:=56; 
 v_returncon:='5';
 countbr:=0;
 ELSIF(countbr=7) then
 indheightsingle:=65; 
 v_returncon:='5';
 countbr:=0;
 ELSIF(countbr=8) then
 indheightsingle:=74; 
 v_returncon:='5';
 countbr:=0;
  ELSIF(countbr=9) then
 indheightsingle:=83; 
 v_returncon:='5';
 countbr:=0;
ELSIF(countbr>=10) then
 indheightsingle:=92; 
  v_returncon:='6';
  countbr:=0;
END IF;
        end loop;
        
    end if;
    counter := counter + 1;

    widthcount:=round(((counter2/case when counter=0 then 1 else counter end)*83),0);
heightcount:=(counter*21+indheightsum);
conheight:=(counter*20+indheightsum);
if (v_returncon='3') OR (v_returncon='4') OR(v_returncon='5') OR (v_returncon='6')then
indheightsum:=indheightsum+indheightsingle;
else
indheightsingle:=20;
indheightsum:=indheightsum;
end if;
v_returncon:='';

    if v_curname.rtype='BP' then
    v_usercol:= zssi_getusercolor(v_curname.idkey);
        v_reslink:=zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.smartui.Employee/EmployeeA3D0B320B69845B386024B5FF6B1E266_Edition.html',v_curname.idkey,v_curname.name,'white');
    else
     v_usercol:= zssi_getmachinecolor(v_curname.idkey);
        v_reslink:=zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.asset.Machine/Machine800086_Edition.html',v_curname.idkey,v_curname.name,'white');

     end if;
     v_usercol:='background-color:'||v_usercol;
    if ((counter%2)=0) Then

        v_returnname:= v_returnname||'<div class="xtFCCell" style="left:0px;top:'||countertop||'px;height:'||indheightsingle||'px;width:103px;"><table class="xtCellTbl" style="width:108px;height:'||indheightsingle+5||'px;"><tbody>'||'<tr id="resourceplan'||counter||'" class="DataGrid_Body_Row DataGrid_Body_Row_Even" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even''"><td class="DataGrid_Body_Cell DataGrid_Body_LineNoCell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell''"style="-moz-user-select: none; width: 95px; text-indent:0px !important; padding-left:0px !important;'||v_usercol||'">'||v_reslink||'</td></tr></tbody></table></div>';

        v_return := v_return||'<tr id="resourceplan'||counter||v_returncon||'" class="DataGrid_Body_Row DataGrid_Body_Row_Even" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even''" style="height:'||indheightsingle||'px !important;background-image:none !important;">'|| v_return1||'</tr>';
        Else
         v_returnname:= v_returnname||'<div class="xtFCCell" style="left:0px;top:'||countertop||'px;height:'||indheightsingle||'px;width:103px;"><table class="xtCellTbl" style="width:108px;height:'||indheightsingle+5||'px;"><tbody>'||'<tr id="resourceplan'||counter||'" class="DataGrid_Body_Row DataGrid_Body_Row_Odd" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd''"><td class="DataGrid_Body_Cell DataGrid_Body_LineNoCell"  onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell''"style="-moz-user-select: none; width: 95px;text-indent:0px !important; padding-left:0px !important;'||v_usercol||'">'||v_reslink||'</td></tr></tbody></table></div>';

        v_return := v_return||'<tr id="resourceplan'||counter||v_returncon||'" class="DataGrid_Body_Row DataGrid_Body_Row_Odd" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd''" style="height:'||indheightsingle||'px !important;background-image:none !important;">'||v_return1||'</tr>';
    end if;
        v_return1:='';
end loop;    


RETURN '<div id="xtFzCol" class="xtFzCol" style="height:'||heightcount||'px;width:100px;position:relative;left:-3px;z-index:6;top:-1px;"> <div class="xtFCInner" style="left:0px;height:'||heightcount||'px;top:0px;width:100px;position:relative;">'||v_returnname||'</div></div><div class="xtTblCon"  style="float:left;top:33px;left:102px;width:'||widthcount+1||'px;height:'||conheight||'px;position:absolute;"><table id="table1" class="xTable" style="border-spacing:0px !important;"><tbody>'||v_return||'</tbody></table></div>';
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

 select zsse_dropfunction('zssi_resourcedates_eofix_small');
CREATE OR REPLACE FUNCTION zssi_resourcedates_eofix_small(p_date_fromIN timestamp, p_date_toIN timestamp,p_org varchar,p_planOrStarted varchar,p_withmachines varchar,p_project varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_curstat RECORD;
v_curname RECORD;
--Weekend,holiday,actualday correlation
v_today character varying:='';
v_styletoday character varying:='';
v_usercol character varying:='';
--end
v_return character varying:='';
v_returnname character varying:='';
v_returncon character varying:='';
v_returncon1 character varying:='';
v_return1 character varying:='';
v_pretext character varying:='<tr>';
v_posttext character varying:='</tr>';
counter integer := 0;
v_countbr integer :=0;
formercountbr integer :=1; 
counter2 integer := 1;
countertop integer :=0;
countereasy integer :=0;
widthcount integer :=0;
heightcount integer :=0;
conheight integer :=0;
v_indheightsingle integer :=20;
indheightsum integer:=0; 
v_reslink varchar;
v_prerun numeric:=10;
v_zindex numeric;
v_dayoneprerun varchar:='';
dayonecountbr numeric;
p_date_from timestamp;
p_date_to timestamp;
v_postrundays numeric;
BEGIN

--Weekend,holiday,actualday correlation
v_today:=to_char(now(),'DD.MM.YYYY');
--end
if coalesce(p_project,'')='' then
    p_date_from:=p_date_fromIN;
    p_date_to:=p_date_toIN;
else
    select startdate,datefinish into  p_date_from,p_date_to from c_project where c_project_id=p_project;
end if;
for v_curname in (
       select 'BP' as rtype,b.c_bpartner_id as idkey,b.name,bpg.name as sorter from ad_user u, c_bpartner b,c_bp_group bpg 
               where u.c_bpartner_id=b.c_bpartner_id and bpg.c_bp_group_id=b.c_bp_group_id 
               and b.isemployee='Y' and b.isactive='Y' and b.isinresourceplan='Y'  and u.isactive='Y' and case when p_org='0' then 1=1 else (b.ad_org_id='0' or  b.ad_org_id= p_org) end and
               case when coalesce(p_project,'')!='' then 
                      u.ad_user_id in (select hr.employee_id from zspm_ptaskhrplan hr,c_projecttask p where p.c_projecttask_id=hr.c_projecttask_id and p.c_project_id=p_project)
                    else
                      1=1
                    end
       UNION
       select 'MA' as rtype,m.ma_machine_id as idkey,m.name,coalesce(mpg.name,'') as sorter from ma_machine m left join ma_machine_type mpg on  mpg.ma_machine_type_id=m.ma_machine_type_id
               where  m.isactive='Y' and m.isinresourceplan='Y' and case when p_org='0' then 1=1 else (m.ad_org_id='0' or  m.ad_org_id= p_org) end and
               case when coalesce(p_withmachines,'Y')='Y' then 1=1 else 1=2 end and
               case when coalesce(p_project,'')!='' then 
                      m.ma_machine_id in (select pl.ma_machine_id from zspm_ptaskmachineplan pl,c_projecttask p where p.c_projecttask_id=pl.c_projecttask_id and p.c_project_id=p_project)
                    else
                      1=1
                    end
       order by rtype,sorter,name
      )
loop
countereasy := countereasy+1;
countertop:=(countereasy*21)-21;
v_prerun:=9;
    if v_curname.rtype='BP' then
    for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between (p_date_from-9) AND  p_date_to)
    loop 
        select content,countbr,zindex into v_returncon1,v_countbr,v_zindex
            from zssi_resourceplan where resourcedate=v_curstat.workdate and c_bpartner_id=v_curname.idkey 
            and case when p_planOrStarted='Planned' then includesplanned='Y' else includesplanned='N'  end;
        -- Height
        v_countbr:=v_countbr;
        if v_countbr>formercountbr then
            formercountbr:=v_countbr;
        else
            v_countbr:=formercountbr;
        end if;
        -- PRE RUN (9 Days before  Start-Date)
        if v_curstat.workdate<p_date_from then
            if v_returncon1!='' and v_zindex>v_prerun then     
               v_dayoneprerun := replace(v_returncon1,'width:'||v_zindex*27||'px;display:block;position:absolute;','width:'||(v_zindex-v_prerun)*27||'px;display:block;position:absolute;');
               dayonecountbr:=v_countbr;
            end if;
            v_prerun:=v_prerun-1;
        else
            if v_dayoneprerun!='' and v_returncon1 is  null then
                v_returncon1:=v_dayoneprerun;
                v_countbr:=dayonecountbr;
                v_dayoneprerun:='';
            end if;
             -- POST-RUn (9 Days before End)
            if v_curstat.workdate>=p_date_to-9 then
              if v_returncon1 is not null  and v_zindex>EXTRACT( days from p_date_to-v_curstat.workdate)+1 then
               v_postrundays:=EXTRACT( days from p_date_to-v_curstat.workdate)+1;
               v_returncon1 := replace(v_returncon1,'width:'||v_zindex*27||'px;display:block;position:absolute;','width:'||v_postrundays*27||'px;display:block;position:absolute;');
              end if;
            end if;
            --WHA
            if     to_char(v_curstat.workdate,'DD.MM.YYYY')=v_today then v_styletoday:='background-color:#d98e20;';	
            elsif  zssi_checkifholiday(to_timestamp(v_curstat.workdate))='Y' then v_styletoday:='background-color:#808080;';
            elsif  zssi_checkiforgholiday(to_timestamp(v_curstat.workdate),p_org)='Y' then v_styletoday:='background-color:#808080;';
            elsif  to_char(v_curstat.workdate,'d')='1' then v_styletoday:='background-color:#808080;';
            elsif  to_char(v_curstat.workdate,'d')='7' then v_styletoday:='background-color:#808080;';
            else v_styletoday:='';
            end if;
            --end
            counter2 := counter2 + 1;
            --v_returncon1:=zssi_getresdesign_mulshort(v_curstat.workdate,v_curname.idkey,null,p_planOrStarted);
            
            if v_returncon1 is null then 
                v_returncon1:='';
                v_countbr:=0;
            end if;

            v_return1:=v_return1||'<td name="status'||counter2||'" class="DataGrid_Body_Cell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell''" onclick=" ''DataGrid_Body_Cell DataGrid_Body_Cell_selected DataGrid_Body_Cell_clicked''" style="border:0px !important;text-align:left;text-indent:0px !important;padding:0px !important;min-width:27px !important;max-width:27px !important; overflow:visible !important;vertical-align:top !important;'||v_styletoday||'">'||v_returncon1||'</td>';
	    --v_returncon1:=zssi_2html(zssi_getresdesign_content(v_curstat.workdate,null,v_curname.idkey,p_planOrStarted));
            --SELECT count(*)-1 into countbr  FROM regexp_split_to_table(zssi_2html(v_returncon1),E'<br/>'); 
	    --v_countbr:=((length(v_returncon1)-length(replace(v_returncon1,'LabelLink','')))/9);
            
            if v_countbr>=formercountbr then
            formercountbr:=v_countbr;
            else
            v_countbr:=formercountbr;
            end if;
            IF (formercountbr=0) then
            v_indheightsingle:=20; 

            v_returncon:='3';
            ELSIF(formercountbr=1) then
            v_indheightsingle:=20; 

            v_returncon:='3';
            ELSIF(formercountbr=3) then
            v_indheightsingle:=44; 

            v_returncon:='3';
            ELSIF(formercountbr=4) then                      
            v_indheightsingle:=56;

            v_returncon:='4';
            ELSIF(formercountbr=2) then                      
            v_indheightsingle:=32;

            v_returncon:='3';
            ELSIF(formercountbr=5) then
            v_indheightsingle:=69; 

            v_returncon:='5';
            ELSIF(formercountbr=6) then
            v_indheightsingle:=82; 
            v_returncon:='5';

            ELSIF(formercountbr=7) then
            v_indheightsingle:=95; 
            v_returncon:='5';

            ELSIF(v_countbr=8) then
            v_indheightsingle:=108; 
            v_returncon:='5';

            ELSIF(formercountbr=9) then
            v_indheightsingle:=121; 
            v_returncon:='5';

            ELSIF(formercountbr>=10) then
            v_indheightsingle:=134; 
            v_returncon:='6';

            END IF;
       end if; --Pre RUN
-- Business Partner LOOP
    end loop;
    else
       for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between (p_date_from-9) AND  p_date_to)
        loop 
            select content,countbr, zindex into  v_returncon1,v_countbr,v_zindex
                from zssi_resourceplan where resourcedate=v_curstat.workdate and ma_machine_id=v_curname.idkey 
                and case when p_planOrStarted='Planned' then includesplanned='Y' else includesplanned='N' end;
            v_countbr:=v_countbr;
            if v_countbr>formercountbr then
            formercountbr:=v_countbr;
            else
            v_countbr:=formercountbr;
            end if;
            -- PRE RUN (Till Start-Date)
            if v_curstat.workdate<p_date_from then
                if v_returncon1!='' and v_zindex>v_prerun then     
                v_dayoneprerun := replace(v_returncon1,'width:'||v_zindex*27||'px;display:block;position:absolute;','width:'||(v_zindex-v_prerun)*27||'px;display:block;position:absolute;');
                dayonecountbr:=v_countbr;
                end if;
                v_prerun:=v_prerun-1;
            else
               if v_dayoneprerun!='' and v_returncon1 is  null then
                    v_returncon1:=v_dayoneprerun;
                    v_countbr:=dayonecountbr;
                    v_dayoneprerun:='';
               end if;
                -- POST-RUn (9 Days before End)
               if v_curstat.workdate>=p_date_to-9 then
                 if v_returncon1 is not null  and v_zindex>EXTRACT( days from p_date_to-v_curstat.workdate)+1 then
                   v_postrundays:=EXTRACT( days from p_date_to-v_curstat.workdate)+1;
                   v_returncon1 := replace(v_returncon1,'width:'||v_zindex*27||'px;display:block;position:absolute;','width:'||v_postrundays*27||'px;display:block;position:absolute;');
                 end if;
               end if;
                --WHA
                if     to_char(v_curstat.workdate,'DD.MM.YYYY')=v_today then v_styletoday:='background-color:#d98e20;';	
                elsif  zssi_checkifholiday(to_timestamp(v_curstat.workdate))='Y' then v_styletoday:='background-color:#808080;';
                elsif  zssi_checkiforgholiday(to_timestamp(v_curstat.workdate),p_org)='Y' then v_styletoday:='background-color:#808080;';
                elsif  to_char(v_curstat.workdate,'d')='1' then v_styletoday:='background-color:#808080;';
                elsif  to_char(v_curstat.workdate,'d')='7' then v_styletoday:='background-color:#808080;';
                else v_styletoday:='';
                end if;
                --end
                counter2 := counter2 + 1;
                --v_returncon1:=zssi_getresdesign_mulshort(v_curstat.workdate,null,v_curname.idkey,p_planOrStarted);
                
                if v_returncon1 is null then 
                    v_returncon1:='';
                    v_countbr:=0;
                end if;
             

                v_return1:=v_return1||'<td name="status'||counter2||'" class="DataGrid_Body_Cell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell''" onclick=" ''DataGrid_Body_Cell DataGrid_Body_Cell_selected DataGrid_Body_Cell_clicked''" style="border:0px !important;text-align:left;text-indent:0px !important;padding:0px !important;min-width:27px !important;max-width:27px !important; overflow:visible !important;vertical-align:top !important;'||v_styletoday||'">'||v_returncon1||'</td>';
                --v_returncon1:=zssi_2html(zssi_getresdesign_content(v_curstat.workdate,null,v_curname.idkey,p_planOrStarted));
                --SELECT count(*)-1 into countbr  FROM regexp_split_to_table(zssi_2html(v_returncon1),E'<br/>')

                --countbr:=((length(v_returncon1)-length(replace(v_returncon1,'LabelLink','')))/9);
            
            if v_countbr>formercountbr then
            formercountbr:=v_countbr;
            else
            v_countbr:=formercountbr;
            end if;
 IF (formercountbr=0) then
            v_indheightsingle:=20; 

            v_returncon:='3';
            ELSIF(formercountbr=1) then
            v_indheightsingle:=20; 

            v_returncon:='3';
            ELSIF(formercountbr=3) then
            v_indheightsingle:=44; 

            v_returncon:='3';
            ELSIF(formercountbr=4) then                      
            v_indheightsingle:=56;
            formercountbr:=0;
            v_returncon:='4';
            ELSIF(formercountbr=2) then                      
            v_indheightsingle:=32;

            v_returncon:='3';
            ELSIF(formercountbr=5) then
            v_indheightsingle:=69; 

            v_returncon:='5';
            ELSIF(formercountbr=6) then
            v_indheightsingle:=82; 
            v_returncon:='5';

            ELSIF(formercountbr=7) then
            v_indheightsingle:=95; 
            v_returncon:='5';

            ELSIF(formercountbr=8) then
            v_indheightsingle:=108; 
            v_returncon:='5';

            ELSIF(formercountbr=9) then
            v_indheightsingle:=121; 
            v_returncon:='5';

            ELSIF(formercountbr>=10) then
            v_indheightsingle:=134; 
            v_returncon:='6';

            END IF;
          end if;
        -- Machine LOOP
        end loop;        
    end if;
    counter := counter + 1;
    widthcount:=round(((counter2/case when counter=0 then 1 else counter end)*27),0);
heightcount:=(counter*21+indheightsum);
conheight:=(counter*20+indheightsum);
if (v_returncon='3') OR (v_returncon='4') OR(v_returncon='5') OR (v_returncon='6')then
indheightsum:=indheightsum+v_indheightsingle;
else
--v_indheightsingle:=20;
indheightsum:=indheightsum;
end if;
v_returncon:='';
formercountbr:=1;
    if v_curname.rtype='BP' then
     v_usercol:= zssi_getusercolor(v_curname.idkey);
        v_reslink:=zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.smartui.Employee/EmployeeA3D0B320B69845B386024B5FF6B1E266_Edition.html',v_curname.idkey,v_curname.name,'white');
    else
     v_usercol:= zssi_getmachinecolor(v_curname.idkey);
        v_reslink:=zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.asset.Machine/Machine800086_Edition.html',v_curname.idkey,v_curname.name,'white');

     end if;
     v_usercol:='background-color:'||v_usercol;
    if ((counter%2)=0) Then

        v_returnname:= v_returnname||'<div class="xtFCCell" style="left:0px;top:'||countertop||'px;height:'||v_indheightsingle||'px;width:103px;"><table class="xtCellTbl" style="width:103px;height:'||v_indheightsingle+3||'px;"><tbody>'||'<tr id="resourceplan'||counter||'" class="DataGrid_Body_Row DataGrid_Body_Row_Even" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even''" style="height:'||v_indheightsingle+2||'px !important;"><td class="DataGrid_Body_Cell DataGrid_Body_LineNoCell" onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell''"style="-moz-user-select: none; width: 95px; text-indent:0px !important; padding-left:0px !important;'||v_usercol||'">'||v_reslink||'</td></tr></tbody></table></div>';

        v_return := v_return||'<tr id="resourceplan'||counter||v_returncon||'" class="DataGrid_Body_Row DataGrid_Body_Row_Even" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Even''" style="height:'||v_indheightsingle||'px !important;background-image:none !important;">'|| v_return1||'</tr>';
        Else
         v_returnname:= v_returnname||'<div class="xtFCCell" style="left:0px;top:'||countertop||'px;height:'||v_indheightsingle||'px;width:103px;"><table class="xtCellTbl" style="width:103px;height:'||v_indheightsingle+3||'px;"><tbody>'||'<tr id="resourceplan'||counter||'" class="DataGrid_Body_Row DataGrid_Body_Row_Odd" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd''" style="height:'||v_indheightsingle+2||'px !important;"><td class="DataGrid_Body_Cell DataGrid_Body_LineNoCell"  onmouseover="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell DataGrid_Body_Cell_hover''" onmouseout="this.className = ''DataGrid_Body_Cell DataGrid_Body_LineNoCell''"style="-moz-user-select: none; width: 95px;text-indent:0px !important; padding-left:0px !important;'||v_usercol||'">'||v_reslink||'</td></tr></tbody></table></div>';

        v_return := v_return||'<tr id="resourceplan'||v_curname.idkey||v_returncon||'" class="DataGrid_Body_Row DataGrid_Body_Row_Odd" onclick="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd DataGrid_Body_Row_selected''" onmouseout="this.className = ''DataGrid_Body_Row DataGrid_Body_Row_Odd''" style="height:'||v_indheightsingle||'px !important;background-image:none !important;">'||v_return1||'</tr>';
    end if;
        v_return1:='';
end loop;    


RETURN '<div id="xtFzCol" class="xtFzCol" style="height:'||heightcount||'px;width:100px;position:relative;left:-3px;z-index:6"> <div class="xtFCInner" style="left:0px;height:'||heightcount||'px;top:3px;width:100px;position:relative;">'||v_returnname||'</div></div><div id="xtTblConId" class="xtTblCon"  style="float:left;top:87px;left:99px;width:'||widthcount-1||'px;height:'||conheight+2||'px;position:absolute;"><table id="table1" class="xTable" style="border-spacing:0px !important;"><tbody>'||v_return||'</tbody></table></div>';
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100; 
  
select zsse_dropfunction('zssi_getresdesign_mul');
CREATE OR REPLACE FUNCTION zssi_getresdesign_mul(p_workdate timestamp,p_user character varying,p_machine varchar,p_planOrStarted varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseOrder as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_colour varchar:='';
v_textcolor varchar:='';
v_event varchar:='';
v_plannedtime numeric;
v_cellcontent varchar;
v_cur record;
BEGIN

for v_cur in (select p_color,p_eventname, p_textcolor, p_correlation from c_getemployeeeventCorrelation(p_user, p_workdate,'en_US') 
              union all 
              select p_color,p_eventname, p_textcolor,  p_correlation from c_getmachineeventCorrelation(p_machine, p_workdate)
              order by p_correlation desc)
LOOP
    v_colour:=v_cur.p_color;
    v_textcolor:=v_cur.p_textcolor;
    
    if (v_event!='') then
    --v_event:=v_event|||v_cur.p_eventname;
     v_event:=v_event||'<a class="LabelLink_'||coalesce(v_textcolor,'black')||'" href="#" title="'||v_cur.p_eventname||'">'||v_cur.p_eventname||'</a>';
      else
     v_event:=v_event||'<a class="LabelLink_'||coalesce(v_textcolor,'black')||'" href="#" title="'||v_cur.p_eventname||'">'||v_cur.p_eventname||'</a>'||'<br/>';
      end if;
END LOOP;

if coalesce(v_colour,'')='' then
    if p_user is not null then
        -- v_cellcontent := c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted)||v_event;
        select p_content,p_color,p_textcolor into v_cellcontent, v_colour,v_textcolor from c_getemployeeprojectsplan(p_user, p_workdate,'Y',p_planOrStarted);   
    else
        select p_content,p_color,p_textcolor into v_cellcontent, v_colour,v_textcolor from c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted);  
        -- v_cellcontent := c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted)||v_event;   
    end if;    
end if;

if coalesce(v_colour,'')='' then
    if p_user is not null then 
        v_plannedtime:=round(c_getemployeepercentplanned(p_user, p_workdate,p_planOrStarted),0);
    else
        v_plannedtime:=round(c_getmachinepercentplanned(p_machine, p_workdate,p_planOrStarted),0);
    end if;
    if v_plannedtime=0 then 
        v_colour:='whitenoplan';
    elsif v_plannedtime<=90 then
        v_colour:='greenwork';
    elsif v_plannedtime>90 and v_plannedtime<=120 then
        v_colour:='yellowwork';
    elsif v_plannedtime>120 then
        v_colour:='redwork';
    else
	v_colour:='whitenoplan';
    end if;
end if;

if v_cellcontent is null then
    v_cellcontent:='';
end if;

if v_cellcontent='' then
    v_cellcontent:=v_cellcontent||v_event;
else
    v_cellcontent:=v_cellcontent||'<br/>'||v_event;
end if;
v_return := (SELECT CASE 
            WHEN v_colour = 'whitenoplan' THEN ''
	    WHEN v_colour='greenwork' THEN '<span  style="color:white;background-color:#588d58; width:100%;display:block;">'||v_cellcontent||'</span>'
	    WHEN v_colour='yellowwork' THEN '<span  style="color:white;background-color:#bd7b00; width:100%;display:block;" >'||v_cellcontent||'</span>'
	    WHEN v_colour='redwork' THEN '<span  style="color:white;background-color:#f63c45; width:100%;display:block;">'||v_cellcontent||'</span>'
	    ELSE '<span  style="color:'||v_textcolor||';background-color:'||v_colour||';width:100%;display:block;">'||v_cellcontent||'</span>'
       END);
--v_return:='<span style="color:black;">'||v_cellcontent||'-------'||v_colour||'.......'||v_event||'-------'||coalesce(v_plannedtime,999)||'</span>';
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select zsse_dropfunction('zssi_getresdesign_mulshort');
CREATE OR REPLACE FUNCTION zssi_getresdesign_mulshort(p_workdate timestamp,p_user character varying,p_machine varchar,p_planOrStarted varchar,
                                                      OUT p_xcolor varchar,OUT p_cellcontent varchar, OUT p_xtextcolor varchar)
RETURNS RECORD AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseOrder as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_colour varchar:='';
v_textcolor varchar:='';
v_event varchar:='';
v_plannedtime numeric;
v_cellcontent varchar;
v_oldcontent varchar:='';
v_zindex numeric:=10;
v_length numeric :=27;
v_cur record;
BEGIN

for v_cur in (select p_color,p_eventname, p_textcolor, p_correlation from c_getemployeeeventCorrelation(p_user, p_workdate,'en_US') 
              union all 
              select p_color,p_eventname, p_textcolor,  p_correlation from c_getmachineeventCorrelation(p_machine, p_workdate)
              order by p_correlation desc)
LOOP
    v_colour:=v_cur.p_color;
    v_textcolor:=v_cur.p_textcolor;
    if (v_event!='') then
    --v_event:=v_event|||v_cur.p_eventname;
    if p_machine is not null then
     v_event:=v_event||'<a class="LabelLink_'||coalesce(v_textcolor,'black')||'" href="#" title="'||v_cur.p_eventname||'">'||(select ma_Machineevent_Id from ma_machineevent m, c_calendarevent c where c.name=v_cur.p_eventname and p_workdate between m.datefrom and m.dateto and ma_machine_id = p_machine )||'</a>'||'<br>';
     end if; 
      else
     v_event:=v_event||coalesce(coalesce(zsse_htmlLinkDirectKey_notblue_short('../org.openbravo.zsoft.smartui.Employee/CalendarEvents_Relation.html',(select c_bpartneremployeeevent_Id from c_bpartneremployeeevent m, c_calendarevent c where c.name=v_cur.p_eventname and p_workdate between m.datefrom and coalesce(m.dateto,m.datefrom) and c_bpartner_id=p_user limit 1),v_cur.p_eventname,v_cur.p_textcolor),(zsse_htmlLinkDirectKey_notblue('../org.openbravo.zsoft.asset.Machine/CalendarEventsB3BA21DE3A024A3CA849DE67F525341D_Relation.html',(select ma_Machineevent_Id from ma_machineevent m, c_calendarevent c where c.name=v_cur.p_eventname and p_workdate between m.datefrom and coalesce(m.dateto,m.datefrom) and ma_machine_id = p_machine limit 1),v_cur.p_eventname,v_cur.p_textcolor))),'<a class="LabelLink_'||coalesce(v_textcolor,'black')||'" href="#" title="'||v_cur.p_eventname||'">'||v_cur.p_eventname)||'</a><br/>';
      --/org.openbravo.zsoft.asset.Machine/CalendarEventsB3BA21DE3A024A3CA849DE67F525341D_Relation.html /org.openbravo.zsoft.smartui.Employee/CalendarEvents_Relation.html
      end if;
END LOOP;

if coalesce(v_colour,'')='' then
    if p_user is not null then
        -- v_cellcontent := c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted)||v_event;
        select p_content,p_color,p_textcolor into v_cellcontent, v_colour,v_textcolor from c_getemployeeprojectsplan_short(p_user, p_workdate,'Y',p_planOrStarted);   
    else
        select p_content,p_color,p_textcolor into v_cellcontent, v_colour,v_textcolor from c_getmachineprojectsplan_short(p_machine, p_workdate,'Y',p_planOrStarted);  
        -- v_cellcontent := c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted)||v_event;   
    end if;    
end if;

if coalesce(v_colour,'')='' then
    if p_user is not null then 
        v_plannedtime:=round(c_getemployeepercentplanned(p_user, p_workdate,p_planOrStarted),0);
    else
        v_plannedtime:=round(c_getmachinepercentplanned(p_machine, p_workdate,p_planOrStarted),0);
    end if;
    if v_plannedtime=0 then 
        v_colour:='whitenoplan';
    elsif v_plannedtime<=90 then
        v_colour:='greenwork';
    elsif v_plannedtime>90 and v_plannedtime<=120 then
        v_colour:='yellowwork';
    elsif v_plannedtime>120 then
        v_colour:='redwork';
    else
	v_colour:='whitenoplan';
    end if;
end if;

if v_cellcontent is null then
    v_cellcontent:='';
end if;

if v_cellcontent='' then
    v_cellcontent:=v_cellcontent||v_event;
else
    v_cellcontent:=v_cellcontent||'<br/>'||v_event;
end if;
p_cellcontent:=v_cellcontent;
p_xcolor :=v_colour;
p_xtextcolor:=v_textcolor;
RETURN;
--if v_length=1 then
--    raise exception '%', p_workdate||' - '||coalesce(p_user,'')||'-'||coalesce(p_machine,'');
--end if;
--(v_zindex*v_length);

--v_return:='<span style="color:black;">'||v_cellcontent||'-------'||v_colour||'.......'||v_event||'-------'||coalesce(v_plannedtime,999)||'</span>';
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  


select zsse_dropfunction('zssi_getresdesign_content');
CREATE OR REPLACE FUNCTION zssi_getresdesign_content(p_workdate timestamp,p_user character varying,p_machine varchar,p_planOrStarted varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseOrder as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_colour varchar:='';
v_textcolor varchar:='';
v_event varchar:='';
v_plannedtime numeric;
v_cellcontent varchar;
v_cur record;
BEGIN

for v_cur in (select p_color,p_eventname, p_textcolor, p_correlation from c_getemployeeeventCorrelation(p_user, p_workdate,'en_US') 
              union all 
              select p_color,p_eventname, p_textcolor,  p_correlation from c_getmachineeventCorrelation(p_machine, p_workdate)
              order by p_correlation desc)
LOOP
    v_colour:=v_cur.p_color;
    v_textcolor:=v_cur.p_textcolor;
    
    if (v_event!='') then
    --v_event:=v_event|||v_cur.p_eventname;
     v_event:=v_event||v_cur.p_eventname||'<br/>';
      else
     v_event:=v_event||v_cur.p_eventname||'<br/>';
      end if;
END LOOP;

if coalesce(v_colour,'')='' OR v_colour='redwork' then
    if p_user is not null then
        -- v_cellcontent := c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted)||v_event;
        select p_content,p_color,p_textcolor into v_cellcontent, v_colour,v_textcolor from c_getemployeeprojectsplan(p_user, p_workdate,'Y',p_planOrStarted);   
    else
        select p_content,p_color,p_textcolor into v_cellcontent, v_colour,v_textcolor from c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted);  
        -- v_cellcontent := c_getmachineprojectsplan(p_machine, p_workdate,'Y',p_planOrStarted)||v_event;   
    end if;    
end if;

if coalesce(v_colour,'')='' then
    if p_user is not null then 
        v_plannedtime:=c_getemployeepercentplanned(p_user, p_workdate,p_planOrStarted);
    else
        v_plannedtime:=c_getmachinepercentplanned(p_machine, p_workdate,p_planOrStarted);
    end if;
    if v_plannedtime=0 then 
        v_colour:='whitenoplan';
    elsif v_plannedtime<=90 then
        v_colour:='greenwork';
    elsif v_plannedtime>90 and v_plannedtime<=120 then
        v_colour:='yellowwork';
    else
        v_colour:='redwork';
    end if;
end if;

if v_cellcontent is null then
    v_cellcontent:='';
end if;

if v_cellcontent='' then
    v_cellcontent:=v_cellcontent||v_event;
else
    v_cellcontent:=v_cellcontent||'<br/>'||v_event;
end if;
v_return := (SELECT CASE 
            WHEN v_colour = 'whitenoplan' THEN ''
	    WHEN v_colour='greenwork' THEN v_cellcontent
	    WHEN v_colour='yellowwork' THEN v_cellcontent
	    WHEN v_colour='redwork' THEN v_cellcontent
	    ELSE v_cellcontent
       END);
--v_return:='<span style="color:black;">'||v_cellcontent||'-------'||v_colour||'.......'||v_event||'-------'||coalesce(v_plannedtime,999)||'</span>';
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  
CREATE OR REPLACE FUNCTION zssi_resourceplan_reportdatadesign(p_workdate timestamp,p_user character varying,p_machine varchar,p_planOrStarted varchar)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseOrder as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_colour varchar:='';
v_event varchar:='';
v_plannedtime numeric;
v_cellcontent varchar;
v_cur record;
BEGIN
for v_cur in (select p_correlation,p_eventname from c_getemployeeeventCorrelation(p_user, p_workdate) 
              union all 
              select p_correlation,p_eventname from c_getmachineeventCorrelation(p_machine, p_workdate))
LOOP
    if v_cur.p_correlation='3' then 
        v_colour:='freetime';
    elsif v_cur.p_correlation='2' then
        v_colour:='holiday';
    elsif v_cur.p_correlation='1' then
        v_colour:='ill';
    end if;
    v_event:=v_event||v_cur.p_eventname;
END LOOP;

if v_colour='' then
    if p_user is not null then 
        v_plannedtime:=c_getemployeepercentplanned(p_user, p_workdate,p_planOrStarted);
    else
        v_plannedtime:=c_getmachinepercentplanned(p_machine, p_workdate,p_planOrStarted);
    end if;
    if v_plannedtime=0 then 
        v_colour:='whitenoplan';
    elsif v_plannedtime<=90 then
        v_colour:='greenwork';
    elsif v_plannedtime>90 and v_plannedtime<=120 then
        v_colour:='yellowwork';
    else
        v_colour:='redwork';
    end if;
end if;
if p_user is not null then
   v_cellcontent := c_getemployeeprojectsplan(p_user, p_workdate,'N',p_planOrStarted)||v_event;   
else
   v_cellcontent := c_getmachineprojectsplan(p_machine, p_workdate,'N',p_planOrStarted)||v_event;   
end if;    
    
v_return := (SELECT CASE WHEN v_colour = 'whitenoplan' THEN '<span style="color:black;width:100%;display:block;">'||rpad('',32,'_')||'</span>'
	    WHEN v_colour='greenwork' THEN '<span  style="color:white;background-color:#588d58; width:100%;display:block;">'||rpad(v_cellcontent,32,'_')||'</span>'
	    WHEN v_colour='freetime' THEN '<span  style="width:100%;display:block; color:white;background-color:#57aeff">'||rpad(v_cellcontent,32,'_')||'</span>'
	    WHEN v_colour='yellowwork' THEN '<span  style="color:white;background-color:#bd7b00; width:100%;display:block;">'||rpad(v_cellcontent,32,'_')||'</span>'
	    WHEN v_colour='holiday' THEN '<span  style="color:white;background-color:#c957ff; width:100%;display:block;">'||rpad(v_cellcontent,32,'_')||'</span>'
	    WHEN v_colour='redwork' THEN '<span  style="color:white;background-color:#f63c45; width:100%;display:block;">'||rpad(v_cellcontent,32,'_')||'</span>'
	    WHEN v_colour='ill' THEN '<span  style="color:white;background-color:#444544;width:100%;display:block;">'||rpad(v_cellcontent,32,'_')||'</span>'
	    ELSE '<span style="color:black;width:100%;display:block;">'||rpad('',32,'_')||'</span>'
       END);
--v_return:='<span style="color:black;">'||v_cellcontent||'-------'||v_colour||'.......'||v_event||'-------'||coalesce(v_plannedtime,999)||'</span>';
  
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION zssi_resourceplan_reportdata(p_date_from timestamp, p_date_to timestamp)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_curstat RECORD;
v_curname RECORD;
v_return character varying:='';
v_return1 character varying:='';
v_pretext character varying:='';
v_posttext character varying:='<br/>';
counter integer := 0;
counter2 integer := 1;
BEGIN


-- ToDo: ADD Parameters for ORG selection and Planned or Started Projects
for v_curname in (
       select 'BP' as rtype,b.c_bpartner_id as idkey,b.name from ad_user u, c_bpartner b where u.c_bpartner_id=b.c_bpartner_id and b.isemployee='Y' and b.isactive='Y' and u.isactive='Y' 
       UNION
       select 'MA' as rtype,ma_machine_id as idkey,name from ma_machine where isactive='Y' )
loop
    if v_curname.rtype='BP' then
        for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between p_date_from AND  p_date_to)
        loop 
            counter2 := counter2 + 1;
            v_return1:=v_return1||''||zssi_resourceplan_reportdatadesign(v_curstat.workdate,v_curname.idkey,null,'Started')||'|';
        end loop;
    else
        for  v_curstat in (select workdate, dayname, isworkday, isholiday, isweekend from c_workcalender where workdate between p_date_from AND  p_date_to)
        loop 
            counter2 := counter2 + 1;
            v_return1:=v_return1||''||zssi_resourceplan_reportdatadesign(v_curstat.workdate,null,v_curname.idkey,'Started')||'|';
        end loop;
    end if;

    counter := counter + 1;
    if ((counter%2)=0) Then
        v_return := v_return||'|'||rpad(v_curname.name,32,'_')||'|'||v_return1||'<br/>';
        Else
        v_return := v_return||'|'||rpad(v_curname.name,32,'_')||'|'||v_return1||'<br/>';
    end if;
    v_return1:='';
end loop;    

RETURN v_return||v_posttext;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
CREATE OR REPLACE FUNCTION zssi_resourceplan_reportheader(p_date_from timestamp, p_date_to timestamp)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_return character varying:='';
v_pretext character varying:='|'||rpad('Employee/Date',32,'_')||'|';
v_posttext character varying:='<br/><br/>';
counter2 integer := 1;
BEGIN
for  v_cur in (select workdate from c_workcalender where workdate between p_date_from AND  p_date_to)
loop
counter2 := counter2 +1;
 if v_return!=' ' then v_return:=v_return||''; end if;
  v_return := v_return||rpad(to_char(v_cur.workdate,'DD.MM.YYYY'),32,'_')||'|';
end loop;
RETURN v_pretext||v_return||v_posttext;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_resourceplan_reportheader(timestamp, timestamp) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_resourceplan_report(p_date_from timestamp, p_date_to timestamp)
RETURNS character varying AS
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
Part of Smartprefs
Localozation in Database - The better way
Generating Grid like:
Name/Date     ... ... ... ...
*****************************************************/
DECLARE
v_cur RECORD;
v_curstat RECORD;
v_curname RECORD;
v_return character varying:='';
v_return1 character varying:='';
v_pretext character varying:='';
v_pretext1 character varying:='';
v_posttext character varying:='<br/><br/>';
v_posttext1 character varying:='';
BEGIN
 select (zssi_resourceplan_reportheader(p_date_from,p_date_to)) INTO v_return;
 select (zssi_resourceplan_reportdata(p_date_from,p_date_to)) INTO v_return1;

RETURN v_pretext||v_return||v_pretext1||v_return1||v_posttext||v_posttext1;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_resourceplan_report(timestamp, timestamp) OWNER TO tad;

CREATE OR REPLACE FUNCTION c_timesegment(datefrom timestamp without time zone,dateto timestamp without time zone,OUT datebegin timestamp without time zone, OUT dateend timestamp without time zone)
RETURNS setof record AS 
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
 
*****************************************************/
v_cur record;
v_threshhold numeric:=7;
v_i numeric:=1;
BEGIN
 
    for v_cur in (select workdate from c_workcalender where workdate between datefrom and dateto)
    LOOP
        if v_i=1 then
            datebegin:=v_cur.workdate;
        end if;
        if v_i=v_threshhold then
            dateend:=v_cur.workdate;
            v_i:=0;
            return next;
        end if;
        v_i:=v_i+1;
    END LOOP;
    
    if dateend<dateto then
        dateend:=dateto;
        return next;
    end if;
    if to_number(dateto - datefrom)<v_threshhold-1 then
        datebegin:=datefrom;
        dateend:=dateto;
        return next;
    end if;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;




create or replace function zssi_substr_count(v_search character varying,v_searchterm character varying) 
returns integer as 
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): D.Heuduk.
***************************************************************************************************************************************************
 
Casesensitive Search for patterns inside a string
 
*****************************************************/
tsearch character varying:= v_search;
tterm character varying:=v_searchterm;
match integer := 0;
pos integer := 0;
p integer := 0;
px integer := 0;
len1 integer := 0;
len2 integer := 0;
begin
len1 := length(tsearch);
len2 := length(tterm);

if len2 < 1 then
-- empty
return 0;
end if;

px := len1 - len2 + 1;

for p in 1..px loop
if substr(tsearch, p, len2) = tterm then
match := match + 1;
end if;
end loop;
return match;
end; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


  
  
  
  
  
/****************************************************************************************************************************************************

Aggregation Functions
 
*****************************************************/
  
  
CREATE OR REPLACE FUNCTION zssi_resourceplancells(p_colour varchar,p_textcolor varchar, p_zindex numeric,p_cellcontent varchar,p_countbr numeric)
RETURNS varchar AS
$_$ 
DECLARE
v_cells varchar;
v_length numeric;
BEGIN
v_length:=p_zindex*27;
v_cells := (SELECT CASE 
            WHEN p_colour = 'whitenoplan' THEN ''
            WHEN p_colour='greenwork' THEN '<span  style="height:'||p_countbr*13||'px;color:white;background-color:#588d58; width:'||v_length||'px;display:block;position:absolute;overflow:hidden;">'||p_cellcontent||'</span>'
            WHEN p_colour='yellowwork' THEN '<span  style="height:'||p_countbr*13||'px;color:white;background-color:#bd7b00; width:'||v_length||'px;display:block;position:absolute;overflow:hidden;" >'||p_cellcontent||'</span>'
            WHEN p_colour='redwork' THEN '<span  style="height:'||p_countbr*13||'px;color:white;background-color:#f63c45; width:'||v_length||'px;display:block;position:absolute;overflow:hidden;">'||p_cellcontent||'</span>'
            ELSE '<span style="height:'||p_countbr*13||'px;color:'||p_textcolor||';background-color:'||p_colour||';width:'||v_length||'px;display:block;position:absolute;overflow:hidden;">'||p_cellcontent||'</span>'
       END);
return v_cells;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;  


select zsse_dropfunction('zssi_resourceplanaggregareResourceInTime');
CREATE OR REPLACE FUNCTION zssi_resourceplanaggregareResourceInTime(firstevent timestamp,lastevent timestamp,pc_bpartner_id varchar,pma_machine_id varchar,pad_org_id varchar,pisonline varchar)
RETURNS void AS
$_$ 
DECLARE
    datecount timestamp;
    dateendcount timestamp;
    datesituation timestamp;
    datesituationp timestamp;
    v_cells varchar;
    v_countbr numeric;
    v_colour varchar;
    v_textcolor varchar;
    v_cellcontent varchar:='X';
    v_oldplanned varchar:='';
    v_oldstarted varchar:='';
    v_indexplanned numeric;
    v_indexstarted numeric;
    
    started varchar:='N';
    startcontent varchar;
    startcolor varchar;
    starttextcolor varchar;
    startedp varchar:='N';
    startcontentp varchar;
    startcolorp varchar;
    starttextcolorp varchar;
BEGIN
    -- Get the longests status
    datecount:=trunc(firstevent);
    dateendcount:=trunc(lastevent);
    -- Bckwart till we did find something..
    WHILE v_cellcontent!='' LOOP
        select p_cellcontent into v_cellcontent from zssi_getresdesign_mulshort(datecount,pc_bpartner_id,pma_machine_id,'Planned');
        if v_cellcontent!='' then 
            datecount:=datecount-1;
        end if;
    END LOOP;
    -- Forward till we did find something..
    v_cellcontent:='X';
    WHILE v_cellcontent!='' LOOP
        select p_cellcontent into v_cellcontent from zssi_getresdesign_mulshort(dateendcount,pc_bpartner_id,pma_machine_id,'Planned');
        if v_cellcontent!='' then
            dateendcount:=dateendcount+1;
        end if;
    END LOOP;
    -- Only when called from Trigger
    if pisonline='Y' then
        if pc_bpartner_id is not null then
            delete from zssi_resourceplan where resourcedate between datecount and dateendcount and c_bpartner_id=pc_bpartner_id;
        end if;
        if pma_machine_id is not null then
            delete from zssi_resourceplan where resourcedate between datecount and dateendcount and ma_machine_id=pma_machine_id;
        end if;
    end if;
    
    WHILE datecount<= dateendcount LOOP
       select p_xcolor,p_cellcontent,p_xtextcolor into v_colour,v_cellcontent,v_textcolor from zssi_getresdesign_mulshort(datecount,pc_bpartner_id,pma_machine_id,'Planned');
       if v_cellcontent!=v_oldplanned or v_indexplanned=10 then    
          if startedp='Y'  and startcontentp!='' then
              v_countbr:=((length(startcontentp)-length(replace(startcontentp,'LabelLink','')))/9);
              v_cells := zssi_resourceplancells(startcolorp,starttextcolorp, v_indexplanned,startcontentp,v_countbr);
              insert into zssi_resourceplan(zssi_resourceplan_id, content, countbr, resourcedate ,
                                            includesplanned,c_bpartner_id, ma_machine_id,ad_org_id,zindex)
              values( get_uuid(),substr(v_cells,1,4000),v_countbr,datesituationp,'Y',pc_bpartner_id,pma_machine_id,pad_org_id,v_indexplanned);
          end if;
          startedp:='Y';
          v_indexplanned:=1;
          datesituationp:=datecount;
          startcontentp:=v_cellcontent;
          starttextcolorp:=v_textcolor;
          startcolorp:=v_colour;
        else
            v_indexplanned:=v_indexplanned+1;
        end if;
        v_oldplanned:=v_cellcontent;            
        select p_xcolor,p_cellcontent,p_xtextcolor into v_colour,v_cellcontent,v_textcolor from zssi_getresdesign_mulshort(datecount,pc_bpartner_id,pma_machine_id,'Started');
        -- Started Projects   
        if v_cellcontent!=v_oldstarted or v_indexstarted=10 then                
           if started='Y' and startcontent!='' then
              v_countbr:=((length(startcontent)-length(replace(startcontent,'LabelLink','')))/9);
              v_cells := zssi_resourceplancells(startcolor,starttextcolor, v_indexstarted,startcontent,v_countbr);
              insert into zssi_resourceplan(zssi_resourceplan_id, content, countbr, resourcedate ,
                                            includesplanned,c_bpartner_id, ma_machine_id,ad_org_id,zindex)
              values( get_uuid(),substr(v_cells,1,4000),v_countbr,datesituation,'N',pc_bpartner_id,pma_machine_id,pad_org_id,v_indexstarted);
            end if;
            started:='Y';
            v_indexstarted:=1;
            datesituation:=datecount;
            startcontent:=v_cellcontent;
            starttextcolor:=v_textcolor;
            startcolor:=v_colour;
        else
            v_indexstarted:=v_indexstarted+1;
        end if;
        v_oldstarted:=v_cellcontent;            
        datecount:=datecount+1;
    END LOOP;
    if startcontent!='' then
       v_countbr:=((length(startcontent)-length(replace(startcontent,'LabelLink','')))/9);
       v_cells := zssi_resourceplancells(startcolor,starttextcolor, v_indexstarted,startcontent,v_countbr);
       insert into zssi_resourceplan(zssi_resourceplan_id, content, countbr, resourcedate ,
                                            includesplanned,c_bpartner_id, ma_machine_id,ad_org_id,zindex)
       values( get_uuid(),substr(v_cells,1,4000),v_countbr,datesituation,'N',pc_bpartner_id,pma_machine_id,pad_org_id,v_indexstarted);
    end if;
    if startcontentp!='' then
       v_countbr:=((length(startcontentp)-length(replace(startcontentp,'LabelLink','')))/9);
       v_cells := zssi_resourceplancells(startcolorp,starttextcolorp, v_indexplanned,startcontentp,v_countbr);
       insert into zssi_resourceplan(zssi_resourceplan_id, content, countbr, resourcedate ,
                                            includesplanned,c_bpartner_id, ma_machine_id,ad_org_id,zindex)
       values( get_uuid(),substr(v_cells,1,4000),v_countbr,datesituationp,'Y',pc_bpartner_id,pma_machine_id,pad_org_id,v_indexplanned);
    end if;
return;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;  





CREATE OR REPLACE FUNCTION zssi_resourceplanaggregate()
RETURNS void AS
$_$ 
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 
Complete Aggregation USED Only on ROLLOUT to Migrate Data to the new tuned Structure
 
*****************************************************/
    firstevent timestamp:=to_date('01.01.2015','dd.mm.yyyy');
    lastevent  timestamp:=to_date('31.12.2017','dd.mm.yyyy');
    v_cur record;
BEGIN  
delete from zssi_resourceplan;

select min(pt.startdate) from c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id and p.projectstatus in ('OP','OR') into firstevent; 
select max(pt.enddate) from c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id and p.projectstatus in ('OP','OR') into lastevent;
firstevent:=to_date('01.01.'||to_number(to_char(firstevent,'yyyy')));
lastevent:=to_date('31.12.'||to_number(to_char(firstevent,'yyyy')));
--select least((select min(datefrom) from ma_machineevent),(select min(datefrom) from C_bpartneremployeeEVENT),(select min(startdate) from c_projecttask)) into firstevent;  
--select greatest((select max(coalesce(dateto,datefrom)) from ma_machineevent),(select max(coalesce(dateto,datefrom)) from C_bpartneremployeeEVENT),(select max(enddate) from c_projecttask)) into lastevent;
  for v_cur in (select ma_machine_id,null as c_bpartner_id,ad_org_id from ma_machine where isactive='Y' and isinresourceplan='Y'
                union 
                select null as ma_machine_id,c_bpartner_id,ad_org_id from c_bpartner where isemployee='Y' and isactive='Y' and isinresourceplan='Y')
  LOOP
    raise notice '%' ,coalesce((select 'Machine:'||name from ma_machine where ma_machine_id=v_cur.ma_machine_id),'')||coalesce((select 'Employee:'||name from c_bpartner where c_bpartner_id=v_cur.c_bpartner_id),'null');
    PERFORM zssi_resourceplanaggregareResourceInTime(firstevent,lastevent,v_cur.c_bpartner_id,v_cur.ma_machine_id,v_cur.ad_org_id,'N');
  END LOOP;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;  
    
  
CREATE OR REPLACE FUNCTION zssi_resourceplanupdate(p_machine varchar,p_user varchar,p_datefrom timestamp without time zone,p_dateto timestamp without time zone)
RETURNS void AS
$_$ 
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 
Updates or inserts specific Data in the Resource Plan
 
*****************************************************/
    firstevent timestamp:=trunc(p_datefrom);
    lastevent  timestamp:=trunc(coalesce(p_dateto,p_datefrom));
    v_cur record;
BEGIN  
  for v_cur in (select ma_machine_id,null as c_bpartner_id,ad_org_id from ma_machine where isactive='Y' and isinresourceplan='Y' and ma_machine_id=p_machine
                union 
                select null as ma_machine_id,b.c_bpartner_id,b.ad_org_id from c_bpartner b,ad_user u where b.isemployee='Y' and b.isactive='Y' and b.isinresourceplan='Y'
                and b.c_bpartner_id=u.c_bpartner_id and u.ad_user_id=p_user)
  LOOP
  /*
    if v_cur.ma_machine_id is not null then
       delete from zssi_resourceplan where resourcedate between firstevent and lastevent and ma_machine_id=v_cur.ma_machine_id;
    end if;
    if v_cur.c_bpartner_id is not null then
       delete from zssi_resourceplan where resourcedate between firstevent and lastevent and c_bpartner_id=v_cur.c_bpartner_id;
    end if;
  */
    PERFORM zssi_resourceplanaggregareResourceInTime(firstevent,lastevent,v_cur.c_bpartner_id,v_cur.ma_machine_id,v_cur.ad_org_id,'Y');
  END LOOP;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;  
    

CREATE OR REPLACE FUNCTION zssi_resourceplanemp_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
v_datefrom timestamp;
v_dateto timestamp;
BEGIN
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    if TG_OP = 'DELETE' then
       select least(startdate,olddatefrom),greatest(enddate,olddateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=old.c_projecttask_id;
            --if old.datefrom is not null then v_datefrom:=old.datefrom; end if;
            --if old.dateto is not null then v_dateto:=old.dateto; end if;
            PERFORM zssi_resourceplanupdate(null,old.employee_id,trunc(coalesce(v_datefrom,now())),v_dateto);
    end if;
    if TG_OP = 'INSERT' then
            select least(startdate,olddatefrom),greatest(enddate,olddateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=new.c_projecttask_id;
            --if new.datefrom is not null then v_datefrom:=new.datefrom; end if;
            --if new.dateto is not null then v_dateto:=new.dateto; end if;
            PERFORM zssi_resourceplanupdate(null,new.employee_id,trunc(coalesce(v_datefrom,now())),v_dateto);
    end if;
    if TG_OP = 'UPDATE' then
       select least(startdate,olddatefrom),greatest(enddate,olddateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=new.c_projecttask_id;
       if (new.c_projecttask_id!=old.c_projecttask_id) then
            select least(startdate,v_datefrom),greatest(enddate,v_dateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=old.c_projecttask_id;
       end if;
      -- if new.datefrom is not null then v_datefrom:=least(v_datefrom,new.datefrom,old.datefrom); end if;
      -- if new.dateto is not null then v_dateto:=greatest(v_dateto,new.dateto,old.dateto); end if;
       PERFORM zssi_resourceplanupdate(null,new.employee_id,trunc(coalesce(v_datefrom,now())),v_dateto);
       if new.employee_id!=old.employee_id then
            PERFORM zssi_resourceplanupdate(null,old.employee_id,trunc(coalesce(v_datefrom,now())),v_dateto);
       end if;
    end if;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('zssi_resourceplanemp_trg','zspm_ptaskhrplan');

CREATE TRIGGER zssi_resourceplanemp_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON zspm_ptaskhrplan FOR EACH ROW
  EXECUTE PROCEDURE zssi_resourceplanemp_trg();



CREATE OR REPLACE FUNCTION zssi_resourceplanmachine_trg () RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
*****************************************************/
v_datefrom timestamp;
v_dateto timestamp;        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
    if TG_OP = 'DELETE' then
       select least(startdate,olddatefrom),greatest(enddate,olddateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=old.c_projecttask_id;
          --  if old.datefrom is not null then v_datefrom:=old.datefrom; end if;
          --  if old.dateto is not null then v_dateto:=old.dateto; end if;
            PERFORM zssi_resourceplanupdate(old.ma_machine_id,null,trunc(coalesce(v_datefrom,now())),v_dateto);
    end if;
    if TG_OP = 'INSERT' then
            select least(startdate,olddatefrom),greatest(enddate,olddateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=new.c_projecttask_id;
            --if new.datefrom is not null then v_datefrom:=new.datefrom; end if;
            --if new.dateto is not null then v_dateto:=new.dateto; end if;
            PERFORM zssi_resourceplanupdate(new.ma_machine_id,null,trunc(coalesce(v_datefrom,now())),v_dateto);
    end if;
    if TG_OP = 'UPDATE' then
       select least(startdate,olddatefrom),greatest(enddate,olddateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=new.c_projecttask_id;
       if (new.c_projecttask_id!=old.c_projecttask_id) then
            select least(startdate,v_datefrom),greatest(enddate,v_dateto) into v_datefrom,v_dateto from c_projecttask where c_projecttask_id=old.c_projecttask_id;
       end if;
       --if new.datefrom is not null then v_datefrom:=least(v_datefrom,new.datefrom,old.datefrom); end if;
       --if new.dateto is not null then v_dateto:=greatest(v_dateto,new.dateto,old.dateto); end if;
       PERFORM zssi_resourceplanupdate(new.ma_machine_id,null,trunc(coalesce(v_datefrom,now())),v_dateto);
       if new.ma_machine_id!=old.ma_machine_id then
            PERFORM zssi_resourceplanupdate(old.ma_machine_id,null,trunc(coalesce(v_datefrom,now())),v_dateto);
       end if;
    end if;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('zssi_resourceplanmachine_trg','zspm_ptaskmachineplan');

CREATE TRIGGER zssi_resourceplanmachine_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON zspm_ptaskmachineplan FOR EACH ROW
  EXECUTE PROCEDURE zssi_resourceplanmachine_trg();
  
  
select zsse_dropview('zspm_workstepdropdown_v');
CREATE OR REPLACE VIEW zspm_workstepdropdown_v AS
SELECT pt.c_projecttask_id as zspm_workstepdropdown_v_id,p.ad_org_id,p.ad_client_id,p.updated,p.updatedby,p.created,p.createdby,'Y'::character as isactive, 
       p.name||'-'||pt.name as name,pt.c_projecttask_id,p.projectstatus
FROM c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id and p.projectstatus in ('OP','OR') and pt.iscomplete='N' and pt.istaskcancelled='N' and p.ishidden='N';



CREATE OR REPLACE FUNCTION zssi_deleteResourceTaskEntry(p_idvalue varchar)
RETURNS varchar AS
$_$ 
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 
Used from the Popup in Resource Plan to delete a amchine or employee-Entry from a Task
 
*****************************************************/
    v_selectedvalue varchar;
BEGIN  
  select zspm_ptaskhrplan_id into v_selectedvalue from zspm_ptaskhrplan where zspm_ptaskhrplan_id=p_idvalue;
  if v_selectedvalue is not null then
    delete from zspm_ptaskhrplan where zspm_ptaskhrplan_id=p_idvalue;
    return 'OK';
  end if;
  select zspm_ptaskmachineplan_id into v_selectedvalue from zspm_ptaskmachineplan where zspm_ptaskmachineplan_id=p_idvalue;
  if v_selectedvalue is not null then
    delete from zspm_ptaskmachineplan where zspm_ptaskmachineplan_id=p_idvalue;
    return 'OK';
  end if;
  return 'NOTFOUND';
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;  



CREATE OR REPLACE FUNCTION zssi_updateTaskDates(p_taskid varchar, p_datefrom timestamp without time zone,p_dateto timestamp without time zone)
RETURNS varchar AS
$_$ 
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 
Used from the Popup in Resource Plan to delete a amchine or employee-Entry from a Task
 
*****************************************************/
    v_selectedvalue varchar;
    v_projDFrom timestamp;
    v_projDTo   timestamp;
    v_projOd    varchar;
BEGIN  
  select coalesce(p.startdate,p_datefrom),coalesce(p.datefinish,p_dateto),p.c_project_id into v_projDFrom,v_projDTo,v_projOd from c_project p,c_projecttask pt
  where pt.c_projecttask_id=p_taskid and  pt.c_project_id=p.c_project_id;
  if v_projDFrom > p_datefrom then
    update c_project set startdate=p_datefrom where c_project_id=v_projOd;
  end if;
  if v_projDTo < p_dateto then
    update c_project set datefinish=p_dateto where c_project_id=v_projOd;
  end if;
  update c_projecttask set startdate=p_datefrom,enddate=p_dateto where c_projecttask_id=p_taskid;
  return 'OK';
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;  


CREATE OR REPLACE FUNCTION zssi_updateOrInsertResourceTaskEntry(p_planidvalue varchar, p_taskid varchar,p_resourceId varchar, p_datefrom timestamp without time zone,p_dateto timestamp without time zone,p_user varchar,p_salcategory varchar,p_costuom varchar,p_qty numeric)
RETURNS varchar AS
$_$ 
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 
Used from the Popup in Resource Plan to delete a amchine or employee-Entry from a Task
 
*****************************************************/
    v_isEmp varchar;
    v_org varchar;
    v_salary_id varchar:=p_salcategory;
    v_count numeric;
    v_count2 numeric;
BEGIN  
  if p_resourceId is null then
    return 'COMPILE';
  end if;
  IF (p_salcategory IS NULL) THEN
        SELECT min(C_Salary_Category_id) INTO v_salary_id from c_bpartner   WHERE c_bpartner_id =  (select c_bpartner_id from ad_user where ad_user_id=p_resourceId)  AND isactive='Y';
  end if;
  select case when count(*)=1 then 'Y' else 'N' end into v_isEmp from ad_user where ad_user_id=p_resourceId;
  select ad_org_id into v_org from c_projecttask where c_projecttask_id=p_taskid;
  select count(*) into v_count from  zspm_ptaskhrplan where zspm_ptaskhrplan_id=p_planidvalue;
  select count(*) into v_count2 from zspm_ptaskmachineplan where zspm_ptaskmachineplan_id=p_planidvalue;
  -- New Entry
  if v_isEmp='Y' and v_count=0 then
        insert into zspm_ptaskhrplan (zspm_ptaskhrplan_id,ad_client_id,ad_org_id,c_projecttask_id,createdby,updatedby,c_salary_category_id,quantity,employee_id,datefrom,dateto)
        values (p_planidvalue,'C726FEC915A54A0995C568555DA5BB3C',v_org,p_taskid,p_user,p_user,v_salary_id,0,p_resourceId,p_datefrom,p_dateto);
  end if;
  if v_isEmp='N' and v_count2=0 then
        insert into zspm_ptaskmachineplan (zspm_ptaskmachineplan_id,ad_client_id,ad_org_id,c_projecttask_id,createdby,updatedby,quantity,costuom,ma_machine_id,datefrom,dateto)
        values (p_planidvalue,'C726FEC915A54A0995C568555DA5BB3C',v_org,p_taskid,p_user,p_user,p_qty,p_costuom,p_resourceId,p_datefrom,p_dateto);
  end if;
  if v_isEmp='Y' and v_count>0  then
        update zspm_ptaskhrplan set c_projecttask_id=p_taskid,updatedby=p_user,updated=now(),employee_id=p_resourceId,datefrom=p_datefrom,dateto=p_dateto where zspm_ptaskhrplan_id=p_planidvalue;
  end if;
  if v_isEmp='N' and v_count2>0  then
        update zspm_ptaskmachineplan set c_projecttask_id=p_taskid,updatedby=p_user,updated=now(),ma_machine_id=p_resourceId,datefrom=p_datefrom,dateto=p_dateto,quantity=p_qty,costuom=p_costuom
        where zspm_ptaskmachineplan_id=p_planidvalue;
  end if;
  return 'OK';
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;  
