/**************************************************************************************************************************************+

Multi - Language and Localizazion 

Database Functions




Text Modules, Messages, Document-Text, Number and Date Localizations









***************************************************************************************************************************************/




/*----------------------------------------------------------------------------------------------







Application Dictionary Text Retrieval Functions






---------------------------------------------------------------------------------------------------*/



CREATE OR REPLACE FUNCTION ad_getFieldText(p_fieldid character varying, p_ad_language character varying) RETURNS character varying
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*/
DECLARE
-- Simple Types
v_return  character varying;
v_id      character varying;
v_otext    character varying;
BEGIN
  select ad_field_v_id,name into v_id,v_otext from ad_field_v where ad_field_v_id=p_fieldid;
  select name into v_return from ad_field_trl_instance where ad_field_v_id=v_id and ad_language=p_ad_language;
  if v_return is null then
        select name into v_return from ad_field_trl where ad_field_v_id=v_id and ad_language=p_ad_language;
  end if;
  if v_return is null then

    if v_otext is not null then
     v_return:= v_otext;
    else
     v_return:= p_fieldid;
    end if;
  end if;
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ad_getFieldGroupText(p_fieldgroupid character varying, p_ad_language character varying) RETURNS character varying
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*/
DECLARE
-- Simple Types
v_return  character varying;
v_id      character varying;
v_otext    character varying;
BEGIN
  select ad_fieldgroup_id,name into v_id,v_otext from ad_fieldgroup where ad_fieldgroup_id=p_fieldgroupid;
  select name into v_return from ad_fieldgroup_trl_instance where ad_fieldgroup_id=v_id and ad_language=p_ad_language;
  if v_return is null then
        select name into v_return from ad_fieldgroup_trl where ad_fieldgroup_id=v_id and ad_language=p_ad_language;
  end if;
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    else
     v_return:= p_fieldgroupid;
    end if;
  end if;
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION zssi_getWindowText(v_objectname character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_id      character varying;
v_otext    character varying;
BEGIN
  if v_return is null then
        select ad_window_id into v_id from ad_window where upper(name)=upper(v_objectname);
        if v_id is not null then
            select name into v_return from ad_window_trl where ad_window_id=v_id and ad_language=lang;
        end if;
  end if;
  if v_return is null then
        select ad_form_id into v_id from ad_form where upper(name)=upper(v_objectname);
        if v_id is not null then
            select name into v_return from ad_form_trl where ad_form_id=v_id and ad_language=lang;
        end if;
  end if;
  if v_return is null then
        select ad_reference_id into v_id from ad_reference where upper(name)=upper(v_objectname);
        if v_id is not null then
            select name into v_return from ad_reference_trl where ad_reference_id=v_id and ad_language=lang;
        end if;
  end if;
  if v_return is null then
        select ad_process_id into v_id from ad_process where upper(name)=upper(v_objectname);
        if v_id is not null then
            select name into v_return from ad_process_trl where ad_process_id=v_id and ad_language=lang;
        end if;
  end if;
RETURN coalesce(v_return,v_objectname);
END;
$_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION zssi_getProcessDescriptionText(v_processId character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_otext    character varying;
BEGIN
  if v_return is null then
        select description into v_return from ad_process_trl where ad_process_id=v_processId and ad_language=lang;
  end if;
  if v_return is null then
        select description into v_return from ad_process where ad_process_id=v_processId;
  end if;
 
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION zssi_getProcessInfoText(v_processId character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_otext    character varying;
BEGIN
  if v_return is null then
        select help into v_return from ad_process_trl where ad_process_id=v_processId and ad_language=lang;
  end if;
  if v_return is null then
        select help into v_return from ad_process where ad_process_id=v_processId;
  end if;
 
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION zssi_getElementTextByColumname(v_dbcolumnname character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_id      character varying;
v_otext    character varying;
BEGIN
  select ad_element_id,name into v_id,v_otext from ad_element where columnname=v_dbcolumnname;
  if v_id is null then
      select ad_element_id,name into v_id,v_otext from ad_element where upper(columnname)=upper(v_dbcolumnname);
  end if;
  if v_id is null then
      select ad_element_id,name into v_id,v_otext from ad_element where replace(columnname,'_','')=replace(v_dbcolumnname,'_','');
  end if;
  if v_id is null then
      select ad_element_id,name into v_id,v_otext from ad_element where upper(replace(columnname,'_',''))=upper(replace(v_dbcolumnname,'_',''));
  end if;
  select name into v_return from ad_element_trl_instance where ad_element_id=v_id and ad_language=lang;
  if v_return is null then
        select name into v_return from ad_element_trl where ad_element_id=v_id and ad_language=lang;
  end if;
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    else
     v_return:= v_dbcolumnname;
    end if;
  end if;
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION zssi_getElementTextByID(v_elementID character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_otext    character varying;
BEGIN
  select name into v_otext from ad_element where ad_element_id=v_elementID;
  if v_otext is null then 
    return v_elementID; 
  end if;
  select name into v_return from ad_element_trl_instance where ad_element_id=v_elementID and ad_language=lang;
  if v_return is null then
        select name into v_return from ad_element_trl where ad_element_id=v_elementID and ad_language=lang;
  end if;
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    end if;
  end if;
RETURN coalesce(v_return,v_elementID);
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION zssi_getListTextByValue(v_RefListName character varying, lang character varying, p_value varchar) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_listID varchar;
v_otext    character varying;
BEGIN
  select l.ad_ref_list_id,l.name into   v_listID,v_otext from ad_ref_list l, ad_reference r 
         where r.ad_reference_id=l.ad_reference_id and r.name=v_RefListName and l.value=p_value ;
  select t.name into v_return from ad_ref_listinstance_trl t,ad_ref_listinstance i 
         where i.ad_ref_listinstance_id=t.ad_ref_listinstance_id and i.ad_ref_list_id=v_listID and ad_language=lang;
  if v_return is null then
        select name into v_return from ad_ref_list_trl where ad_ref_list_id=v_listID and ad_language=lang;
  end if;
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    end if;
  end if;
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION zssi_getProcessParamTextByID(v_Process_ParamID character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_otext    character varying;
BEGIN
  select name into v_otext from ad_process_para_trl where ad_process_para_id=v_Process_ParamID and ad_language=lang;
  
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    end if;
  end if;
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION zssi_getTabFieldTextByID(v_FieldID character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_otext    character varying;
v_cmtext varchar;
BEGIN
  if lang='en_US' then
    select name into v_cmtext from ad_field where ad_field_id=v_FieldID;
  end if;
  select name into v_otext from ad_field_trl where ad_field_v_id=v_FieldID and ad_language=lang;
  select name into v_return from ad_field_trl_instance where ad_field_v_id=v_FieldID and ad_language=lang;
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    end if;
    if v_otext is null and v_cmtext is not null then
     v_return:= v_cmtext;
    end if;
  end if;
RETURN coalesce(v_return,'');
END;
$_$  LANGUAGE 'plpgsql';

CREATE or replace FUNCTION zssi_getText(v_text character varying, lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_id      character varying;
v_otext    character varying;
BEGIN
  select ad_message_id,msgtext into v_id,v_otext from ad_message where value=v_text;
  select msgtext into v_return from ad_message_trl_instance where ad_message_id=v_id and ad_language=lang;
  if v_return is null then
        select msgtext into v_return from ad_message_trl where ad_message_id=v_id and ad_language=lang;
  end if;
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    else
     v_return:= v_text;
    end if;
  end if;
RETURN coalesce(v_return,'');
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN 'No translation for '||text||' found '||' Lang: '||lang;
END;
$_$
  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION ad_message_get(p_value character varying, p_ad_language character varying) RETURNS character varying
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
For compatibility only.
*/
BEGIN
  return zssi_getText(p_value,p_ad_language);
END; $_$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION ad_message_get2(p_value character varying, p_ad_language character varying) RETURNS character varying
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
For compatibility only.
*/
BEGIN
   return zssi_getText(p_value,p_ad_language);
END; $_$ LANGUAGE 'plpgsql';





CREATE or replace FUNCTION zssi_getListRefText(p_adreflistID character varying, p_value character varying,lang character varying) RETURNS character varying
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
-- Simple Types
v_return  character varying;
v_otext    character varying;
BEGIN
  select name into v_return from ad_ref_list_v where ad_reference_id=p_adreflistID and value=p_value  and ad_language=lang;
  select name into v_otext from ad_ref_list_v where ad_reference_id=p_adreflistID and value=p_value  and ad_language='en_US';
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    else
     v_return:= p_value;
    end if;
  end if;
RETURN coalesce(v_return,'');
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN 'No translation for '||text||' found '||' Lang: '||lang;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
  
  CREATE or replace FUNCTION zssi_getSelectorIdentifierByID(v_selector character varying,v_id varchar,lang character varying) RETURNS character varying
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
v_refid varchar;
v_table varchar;
v_tname varchar;
v_return character varying;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
BEGIN
      select ad_reference_id into v_refid from ad_reference where name=v_selector;
      select ad_table_id into v_table from ad_ref_search   where ad_reference_id=v_refid;
      select tablename into v_tname from ad_table where ad_table_id=v_table;
      select ad_column_identifier(v_tname, v_id,lang) into v_return;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
  
  
  
  
/*-----------------------------------







Formatting Functions









--------------------------------------------*/






CREATE or replace FUNCTION zssi_strDate(v_date timestamp, lang character varying) RETURNS character varying
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
Localozation in Database - The better way
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
v_df varchar;
BEGIN
   select coalesce(reportdateformat,dateformat) into v_df from ad_language where ad_language= lang;
   if v_df is null then 
     v_df:= 'DD.MM.YYYY';
    end if;
   RETURN to_char(v_date, v_df);
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE or replace FUNCTION zssi_Input2Number(v_num varchar, lang character varying) RETURNS numeric
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
Returns specific German Localization regardless of the localization of the machine
*****************************************************/
DECLARE
-- Simple Types
v_return  varchar;
v_ds varchar;
v_ts varchar;
BEGIN
  select coalesce(decimalseparator,','),coalesce(thousandseparator,'.') into v_ds,v_ts from ad_language where ad_language= lang;
      --return replace(to_char(v_num,'99999G990D99'),' ','');
      
      v_return:=replace(v_num,v_ds,'X');
      v_return:=replace(v_return,v_ts,'');
      v_return:=replace(v_return,'X','.');
      RETURN to_number(v_return);
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;  


CREATE or replace FUNCTION zssi_strNumber(v_num numeric, lang character varying) RETURNS character varying
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
Returns specific German Localization regardless of the localization of the machine
Führende 0en Bleiben erhalten
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
v_ds varchar;
v_ts varchar;
BEGIN
  select coalesce(decimalseparator,','),coalesce(thousandseparator,'.') into v_ds,v_ts from ad_language where ad_language= lang;
      --return replace(to_char(v_num,'99999G990D99'),' ','');
      v_return:=replace(to_char(v_num, '999,999,999,999,990.99'),' ','');
      v_return:=replace(v_return,'.','X');
      v_return:=replace(v_return,',',v_ts);
      v_return:=replace(v_return,'X',v_ds);
      RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE or replace FUNCTION zssi_strCurrencyNumber(v_num numeric, lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
Overload (Std. 2 Dots)
*****************************************************/
DECLARE

BEGIN
      RETURN zssi_strNumber(v_num, lang) ;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;

  
CREATE or replace FUNCTION zssi_strNumber2(v_num numeric, lang character varying) RETURNS character varying
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
Returns specific German Localization regardless of the localization of the machine
Führende 0en werden weggefiltert
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
v_ds varchar;
v_ts varchar;
BEGIN
  select coalesce(decimalseparator,','),coalesce(thousandseparator,'.') into v_ds,v_ts from ad_language where ad_language= lang;
      --return replace(to_char(v_num,'99999G990D99'),' ','');
      v_return:=replace(to_char(v_num, '999,999,999,990.9999'),' ','');
      v_return:=replace(v_return,'.','X');
      v_return:=replace(v_return,',',v_ts);
      v_return:=replace(v_return,'X',v_ds);
	  if (substring(v_return from (char_length(v_return) -1 )) = '00') then
		v_return:=substring(v_return from 1 for (char_length(v_return) - 2));
	  elsif (substring(v_return from (char_length(v_return))) = '0') then
		v_return:=substring(v_return from 1 for (char_length(v_return) - 1));
	  end if;
      RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE or replace FUNCTION zssi_strPriceNumber(v_num numeric, lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
Overload (Std. 4 Dots)
*****************************************************/
DECLARE

BEGIN
      RETURN zssi_strNumber2(v_num, lang) ;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE or replace FUNCTION zssi_strNumberPrice(v_num numeric, lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Returns specific German Localization regardless of the localization of the machine
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
v_ds varchar;
v_ts varchar;
BEGIN
  select coalesce(decimalseparator,','),coalesce(thousandseparator,'.') into v_ds,v_ts from ad_language where ad_language= lang;
      --return replace(to_char(v_num,'99999G990D99'),' ','');
      v_return:=replace(to_char(v_num, '999,999,999,990.999'),' ','');
      v_return:=replace(v_return,'.','X');
      v_return:=replace(v_return,',',v_ts);
      v_return:=replace(v_return,'X',v_ds);
	  if (substring(v_return from (char_length(v_return) -1 )) = '00') then
		v_return:=substring(v_return from 1 for (char_length(v_return) - 2));
	  elsif (substring(v_return from (char_length(v_return))) = '0') then
		v_return:=substring(v_return from 1 for (char_length(v_return) - 1));
	  end if;
      RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE or replace FUNCTION zssi_strQuantityNumber(v_num numeric, lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
Overload (Std. 3 Dots)
*****************************************************/
DECLARE

BEGIN
      RETURN zssi_strNumberPrice(v_num, lang) ;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
COST 100;
  
select zsse_dropfunction('zssi_strInt');
CREATE or replace FUNCTION zssi_strInt(v_num numeric, lang character varying) RETURNS character varying
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
Localozation in Database - The better way
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
v_ds varchar;
v_ts varchar;
BEGIN
       select coalesce(thousandseparator,'.') into v_ts from ad_language where ad_language= lang;
      return replace(to_char(v_num,'999,999,999,990') ,',',v_ts);
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;







/*---------------------------------------------------------




Text Retrieval Functions






------------------------------------------------------------*/
select zsse_dropfunction('zssi_GetDocText');
CREATE or replace FUNCTION zssi_GetDocText(v_doctype_id character varying, v_lang character varying) RETURNS character varying
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
Get Document-Text from Database
Default Table: c_doctype_trl
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
BEGIN
  select printname into v_return from c_doctype_trl where c_doctype_id =v_doctype_id
         and ad_language=v_lang;
RETURN coalesce(v_return,'');
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN 'No text found';
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_GetDocText(v_doctype_id character varying, v_lang character varying) OWNER TO tad;


select zsse_dropfunction('zssi_GetReportTitle');
CREATE or replace FUNCTION zssi_GetReportTitle(v_printout_config_id character varying, v_doctype_id character varying, v_poc_doctype_id character varying, v_lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt
***************************************************************************************************************************************************
Part of Smartprefs
Get Document-Text from Database
Default Table: c_poc_doctype_template_trl
If c_poc_doctype_template_trl is empty it will use c_doctype_trl instead
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
BEGIN
 
	select templatetrl.reporttitle into v_return 
	from c_poc_doctype_template_trl templatetrl, c_poc_doctype_template template 
		where templatetrl.c_poc_doctype_template_id = template.c_poc_doctype_template_id
		and template.c_printout_config_id = v_printout_config_id
		and templatetrl.c_doctype_id = v_doctype_id
		and templatetrl.ad_language = v_lang
		and templatetrl.c_poc_doctype_template_id = v_poc_doctype_id;
 
	IF (COALESCE(v_return, '') = '') 
		THEN
			select printname into v_return 
			from c_doctype_trl 
				where c_doctype_id = v_doctype_id
				and ad_language = v_lang;
	END IF; 

RETURN coalesce(v_return,'');
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN 'No text found';
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_GetReportTitle(v_printout_config_id character varying, v_doctype_id character varying, v_poc_doctype_id character varying, v_lang character varying) OWNER TO tad;


CREATE or replace FUNCTION zssi_getproductname(v_product character varying,v_lang character varying) RETURNS character varying
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
BEGIN
      select name into v_return from m_product_trl where m_product_id=v_product and ad_language=v_lang  AND COALESCE(istranslated,'N') = 'Y';
      if v_return is null then 
          select name into v_return from m_product where m_product_id=v_product;
      end if;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE or replace FUNCTION zssi_getproductnamewithvalue(v_product character varying,v_lang character varying) RETURNS character varying
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
BEGIN
      select p.value||'-'||t.name into v_return from m_product p,m_product_trl t where t.m_product_id=p.m_product_id and p.m_product_id=v_product and ad_language=v_lang AND COALESCE(istranslated,'N') = 'Y';
      if v_return is null then 
          select value||'-'||name into v_return from m_product where m_product_id=v_product;
      end if;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getproductset_complete');
CREATE or replace FUNCTION zssi_getproductset_complete(v_product character varying, v_lang character varying ) RETURNS character varying
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
v_line character varying;
v_cur record;
BEGIN
  FOR v_cur in (select bomqty as v_bomqty,m_productbom_id as v_bomproduct,description as v_bomdescription from m_product_bom where m_product_id=v_product)
  LOOP
    v_line:=coalesce(v_line,'')||chr(32)||'-'||zssi_strint(to_number(v_cur.v_bomqty),v_lang)||' '||zssi_getproductname(v_cur.v_bomproduct,v_lang)||'<br/>';
  END LOOP;
  return substr(coalesce(v_line,''),1,length(coalesce(v_line,''))-5);
END; $_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  select zsse_dropfunction('zssi_getbankname');
CREATE or replace FUNCTION zssi_getbankname(v_org character varying, v_currency character varying) RETURNS character varying
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
v_line character varying;
v_cur record;
BEGIN 
  v_line:=(SELECT c_bank.name from c_bank, c_bankaccount where c_bankaccount.c_currency_id=v_currency and c_bankaccount.ad_org_id=v_org limit 1);
return v_line;
  END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
    select zsse_dropfunction('zssi_getiban');
CREATE or replace FUNCTION zssi_getiban(v_org character varying, v_currency character varying) RETURNS character varying
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
v_line character varying;
v_cur record;
BEGIN 
  v_line:=(SELECT c_bankaccount.iban from c_bank, c_bankaccount where c_bankaccount.c_currency_id=v_currency and c_bankaccount.ad_org_id=v_org limit 1);
return v_line;
  END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
      select zsse_dropfunction('zssi_getbic');
CREATE or replace FUNCTION zssi_getbic(v_org character varying, v_currency character varying) RETURNS character varying
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
v_line character varying;
v_cur record;
BEGIN 
  v_line:=(SELECT c_bank.swiftcode from c_bank, c_bankaccount where c_bankaccount.c_currency_id=v_currency and c_bankaccount.ad_org_id=v_org limit 1);
return v_line;
  END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
select zsse_dropfunction('zssi_checkifsetproduct');
CREATE or replace FUNCTION zssi_checkifsetproduct(v_product character varying) RETURNS character varying
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
BEGIN
select issetitem into v_return from m_product where m_product_id=v_product;
RETURN coalesce(v_return,'N');
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE or replace FUNCTION zssi_getproductkey(v_product character varying) RETURNS character varying
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
BEGIN
      select value into v_return from m_product where m_product_id=v_product;
     
RETURN coalesce(v_return,'');
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;

select zsse_dropfunction('zssi_getIdentifierFromKey');
CREATE or replace FUNCTION zssi_getIdentifierFromKey(v_keycolumnname character varying,v_value character varying,v_lang varchar) RETURNS character varying
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
v_sql character varying;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_table varchar;
v_tabletrl varchar;
v_selstr varchar:='';
v_tablename varchar;
BEGIN
      v_tablename:=lower(substr(v_keycolumnname,1,length(v_keycolumnname)-3));
      --return AD_COLUMN_IDENTIFIER(v_tablename,v_value,v_lang);
      select ad_table_id into v_table from ad_table where lower(tablename)= v_tablename;
      select ad_table_id into v_tabletrl from ad_table where lower(tablename)= v_tablename||'_trl';
      for v_cur in select columnname,istranslated,ad_datatype_guiengine_template_mapping(ad_reference_id) as datatype from ad_column where ad_table_id=v_table and isidentifier ='Y' order by seqno
      LOOP
         if v_selstr!='' then v_selstr:=v_selstr||'||'||chr(39)||'-'||chr(39)||'||'; end if;
         if v_tabletrl is not null and v_cur.istranslated='Y' then
            if v_cur.datatype not in ('DATE','TIME','DECIMAL','PRICE','INTEGER','EURO') then
                v_selstr:= v_selstr || 'coalesce(trl.'||v_cur.columnname||',t.'||v_cur.columnname||','''')::text';
            end if;
            if v_cur.datatype  in ('DATE','TIME') then
                v_selstr:= v_selstr || 'to_char(coalesce(trl.'||v_cur.columnname||',t.'||v_cur.columnname||',to_date(''01.01.9999'',''dd.mm.yyyy'')),''dd.mm.yyyy'')';
            end if;
            if v_cur.datatype  in ('DECIMAL','PRICE','INTEGER','EURO') then
                v_selstr:= v_selstr || 'to_char(round(coalesce(trl.'||v_cur.columnname||',t.'||v_cur.columnname||',0),2))';
            end if;
         end if;
         if v_tabletrl is not null and v_cur.istranslated='N' then
           if v_cur.datatype not in ('DATE','TIME','DECIMAL','PRICE','INTEGER','EURO') then
                v_selstr:= v_selstr || 'coalesce(t.'||v_cur.columnname||','''')::text';
           end if;
           if v_cur.datatype  in ('DATE','TIME') then
                v_selstr:= v_selstr || 'to_char(coalesce(t.'||v_cur.columnname||'to_date(''01.01.9999'',''dd.mm.yyyy'')),''dd.mm.yyyy'')';
           end if;
           if v_cur.datatype  in ('DECIMAL','PRICE','INTEGER','EURO') then
                v_selstr:= v_selstr || 'to_char(round(coalesce(t.'||v_cur.columnname||',0),2))';
           end if;
         end if;
         if v_tabletrl is  null then
           if v_cur.datatype not in ('DATE','TIME','DECIMAL','PRICE','INTEGER','EURO') then
                v_selstr:= v_selstr || 'coalesce('||v_cur.columnname||','''')::text';
           end if;
           if v_cur.datatype  in ('DATE','TIME') then
                v_selstr:= v_selstr || 'to_char(coalesce('||v_cur.columnname||',to_date(''01.01.9999'',''dd.mm.yyyy'')),''dd.mm.yyyy'')';
           end if;
           if v_cur.datatype  in ('DECIMAL','PRICE','INTEGER','EURO') then
                v_selstr:= v_selstr || 'to_char(round(coalesce('||v_cur.columnname||',0),2))';
           end if;
         end if;
      END LOOP;
      --raise warning '%',v_selstr||'#'||coalesce(v_tablename,'TTT')||'#'||coalesce(v_keycolumnname,'KKK')||'#'||coalesce(v_value,'VVV')||'#'||coalesce(v_lang,'LLL');
      if v_value is null then
        v_value:='';
      end if;
      if v_tabletrl is  null then
        v_sql:='select '||v_selstr||' as retval from '|| v_tablename||' where  '||v_keycolumnname ||' = '||chr(39)||v_value||chr(39);
      else
        v_sql:='select '||v_selstr||' as retval from '|| v_tablename||' t left join '|| v_tablename||'_trl trl on t.'||v_keycolumnname||'=trl.'||v_keycolumnname||' and trl.ad_language='''||v_lang||'''  where  t.'||v_keycolumnname ||' = '||chr(39)||v_value||chr(39);
      end if;
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_return:=v_cur.retval;
      END LOOP;
RETURN coalesce(v_return,'');
EXCEPTION
WHEN OTHERS THEN
    return '';
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;


CREATE OR REPLACE FUNCTION zssi_getusername (p_user_id VARCHAR)
RETURNS VARCHAR AS
$body$
-- SELECT zssi_getusername('B190399E0FC542908B02205D8DD4F577');
-- DECLARE 
BEGIN
  RETURN COALESCE((SELECT ad.name FROM ad_user ad WHERE ad.ad_user_id = p_user_id),'');
END ;
$body$
LANGUAGE 'plpgsql';


CREATE or replace FUNCTION zssi_getusernamecomplete(v_user character varying,lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_prefix character varying;
v_id character varying;
v_title character varying;
BEGIN
      select name,c_greeting_id, title into v_return,v_id,v_title from ad_user where ad_user_id=v_user;
      select name into v_prefix from c_greeting_trl where c_greeting_id=v_id and ad_language=lang;
      if v_prefix is null then 
          select name into v_prefix from c_greeting where c_greeting_id=v_id;
      end if;
      if v_prefix is not null then v_prefix:=v_prefix||' '; end if;
	  if v_title is not null then v_prefix:=v_prefix||v_title||' '; end if;
RETURN coalesce(v_prefix,'')||coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_getusernamecomplete(v_user character varying,lang character varying) OWNER TO tad;


CREATE or replace FUNCTION zssi_getprojectorcostcentername(v_project character varying,v_costcenter character varying) RETURNS character varying
AS $BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select value||' - '||name into v_return from c_project where c_project_id=v_project;
      if v_return is null then 
          select value||' - '||name into v_return from a_asset where a_asset_id=v_costcenter;
      end if;
RETURN coalesce(v_return,'');
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_getprojectorcostcentername(v_project character varying,v_costcenter character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getprojectorcostcentervalue(v_project character varying, v_costcenter character varying)
  RETURNS character varying AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select value into v_return from c_project where c_project_id=v_project;
      if v_return is null then 
          select value into v_return from a_asset where a_asset_id=v_costcenter;
      end if;
RETURN coalesce(v_return,'');
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE or replace FUNCTION zssi_getuom(v_uom character varying,lang character varying) RETURNS character varying
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
BEGIN
      select uomsymbol into v_return from c_uom_trl where c_uom_id=v_uom and ad_language=lang;
      if v_return is null then 
          select uomsymbol into v_return from c_uom where c_uom_id=v_uom;
      end if;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE or replace FUNCTION zssi_getproductuom(v_puom character varying,lang character varying) RETURNS character varying
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
v_id character varying;
BEGIN
      select c_uom_id into v_id from m_product_uom where m_product_uom_id=v_puom;
      select uomsymbol into v_return from c_uom_trl where c_uom_id=v_id and ad_language=lang;
      if v_return is null then 
          select uomsymbol into v_return from c_uom where c_uom_id=v_id;
      end if;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_getproductuom(v_uom character varying,lang character varying) OWNER TO tad;

CREATE or replace FUNCTION zssi_getuserEMail(v_user character varying) RETURNS character varying
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
v_prefix character varying;
v_id character varying;
BEGIN
      select email into v_return from ad_user where ad_user_id=v_user;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_getuserEMail(v_user character varying) OWNER TO tad;

CREATE or replace FUNCTION zssi_getuserPhone(v_user character varying) RETURNS character varying
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
v_prefix character varying;
v_id character varying;
BEGIN
      select phone into v_return from ad_user where ad_user_id=v_user;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_getuserPhone(v_user character varying) OWNER TO tad;


CREATE or replace FUNCTION zssi_getOrgName(v_org character varying) RETURNS character varying
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
Returns Client-Name if Org='0', else Org-Name
*****************************************************/
DECLARE
v_return character varying;

BEGIN
      if v_org in ('0','*') then
         select name into v_return from ad_client where ad_client_id!='0';
      else 
         select name into v_return from ad_org where ad_org_id=v_org;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE or replace FUNCTION zssi_getSepaVWZ(v_invoice character varying,orderno character varying) RETURNS character varying
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
Returns SEPA-Verwendungszweck
*****************************************************/
DECLARE
v_return character varying;

BEGIN
      if orderno='1' then
         select poreference into v_return from c_invoice where c_invoice_id=v_invoice;
         if v_return is not null then
            return rpad('Rechn. '||v_return,35,' ');
         end if;
      end if;
      if orderno='2' then
         select to_char(dateinvoiced) into v_return from c_invoice where c_invoice_id=v_invoice;
         if v_return is not null then
            return rpad('vom  '||v_return,35,' ');
         end if;
      end if;
      if orderno='3' then
         select  owncodeatpartnersite into v_return from c_bpartner where c_bpartner_id=(select c_bpartner_id from c_invoice where c_invoice_id=v_invoice);
         if v_return is not null then
            return rpad('Kunde Nr. '||v_return,35,' ');
         end if;
      end if;
      if orderno='4' then
         select to_char(documentno) into v_return from c_invoice where c_invoice_id=v_invoice;
         if v_return is not null then
            return rpad('OP Nr.  '||v_return,35,' ');
         end if;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


  
CREATE or replace FUNCTION zssi_getOwnCodeAtPartnerSide(v_org character varying,v_bpartner varchar) RETURNS character varying
AS $_$

DECLARE
v_return character varying;

BEGIN
      select owncodeatpartnersite into v_return from c_bpartner_org where ad_org_id=v_org and c_bpartner_id=v_bpartner;
      if v_return is null then 
         select owncodeatpartnersite into v_return from c_bpartner where c_bpartner_id=v_bpartner;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 
  
  
/*-------------------------------------------------------------------------------------------------------------------------------------------------


Special Formatting and Auxillary Functions for Reports etc.




-------------------------------------------------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION zssi_textpatternchange(v_text character varying, v_pattern varchar,v_newpattern varchar)
  RETURNS character varying AS
$BODY$/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
No Multilines
*****************************************************/
DECLARE
v_first character varying;
v_last character varying;

BEGIN
      if instr(v_text,v_pattern)=0 then return v_text; end if;
      v_last:=substr(v_text,1,instr(v_text,v_pattern)-1);
      v_first:=substr(v_text,instr(v_text,v_pattern)+1,length(v_text));
      RETURN v_first||v_newpattern||v_last;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION zssi_nomultiline(v_text character varying)
  RETURNS character varying AS
$BODY$/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
No Multilines
*****************************************************/
DECLARE
v_temp character varying;
v_return character varying;

BEGIN
      select replace(v_text,E'\r\n',' - ') into v_temp;
      select replace(v_temp,'"','`') into v_temp;
      select substring(v_temp , 1, 70) into v_return;
      RETURN v_return;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_shortlength(v_text character varying)
  RETURNS character varying AS
$BODY$
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
Restriction of characters
*****************************************************/
DECLARE
v_temp character varying;
v_return character varying;


BEGIN
      select replace(v_text,'"','`') into v_temp;
      select substring(v_temp , 1, 40) into v_return;
      RETURN v_return;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
CREATE OR REPLACE FUNCTION zssi_limitlength55(v_text character varying)
  RETURNS character varying AS
$BODY$
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
Restriction of characters
*****************************************************/
DECLARE
v_temp character varying;
v_return character varying;


BEGIN
      select replace(v_text,'"','`') into v_temp;
      select substring(v_temp , 1, 40) into v_return;
      RETURN v_return;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_html4docs(v_text character varying)
  RETURNS character varying AS
$BODY$
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
Restriction of characters
*****************************************************/
DECLARE
v_return character varying;
BEGIN
/* Patch 
      select replace(v_text,E'\r\n','<br/>') into v_return;
      select replace(v_return,'"','`') into v_return;
      select replace(v_return,chr(39),'`') into  v_return;
*/

      select replace(v_text,'"','`') into v_return;
      select replace(v_return,chr(39),'`') into  v_return;
	  select replace(v_return, ' < ', ' &lt; ') into v_return;
	  select replace(v_return, ' > ', ' &gt; ') into v_return;
	  select replace(v_return,E'\r\n','<br/>') into v_return;
          select replace(v_return, '<', '&lt;') into v_return;
	  select replace(v_return, '>', '&gt;') into v_return;
/* Replace valid html tags */
	  /* bold tags */
	  select replace(v_return, '&lt;b&gt;', '<b>') into v_return;
	  select replace(v_return, '&lt;/b&gt;', '</b>') into v_return;
	  select replace(v_return, '&lt;B&gt;', '<b>') into v_return;
	  select replace(v_return, '&lt;/B&gt;', '</b>') into v_return;
	  /* preformatted  tags */
	  select replace(v_return, '&lt;pre&gt;', '<pre>') into v_return;
	  select replace(v_return, '&lt;PRE&gt;', '<pre>') into v_return;
	  select replace(v_return, '&lt;/pre&gt;', '</pre>') into v_return;
	  select replace(v_return, '&lt;/PRE&gt;', '</pre>') into v_return;
	  /* Linebreak tags */
	  select replace(v_return, '&lt;br&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;BR&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;/br&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;/BR&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;br/&gt;', chr(10)) into v_return;
	  select replace(v_return, '&lt;BR/&gt;', '<br/>') into v_return;
	  /*  italic tags */
	  select replace(v_return, '&lt;i&gt;', '<i>') into v_return;
	  select replace(v_return, '&lt;I&gt;', '<i>') into v_return;
	  select replace(v_return, '&lt;/i&gt;', '</i>') into v_return;
	  select replace(v_return, '&lt;/I&gt;', '</i>') into v_return;
	  /*  underlined tags */
	  select replace(v_return, '&lt;u&gt;', '<u>') into v_return;
	  select replace(v_return, '&lt;U&gt;', '<u>') into v_return;
	  select replace(v_return, '&lt;/u&gt;', '</u>') into v_return;
	  select replace(v_return, '&lt;/U&gt;', '</u>') into v_return;
	  /* new line tags */
	  select replace(v_return, '&lt;p&gt;', '<p>') into v_return;
	  select replace(v_return, '&lt;P&gt;', '<p>') into v_return;
	  select replace(v_return, '&lt;/p&gt;', '</p>') into v_return;
	  select replace(v_return, '&lt;/P&gt;', '</p>') into v_return;	
	  /*  List tags */
	  select replace(v_return, '&lt;ul&gt;', '<ul>') into v_return;
	  select replace(v_return, '&lt;UL&gt;', '<ul>') into v_return;
	  select replace(v_return, '&lt;/ul&gt;', '</ul>') into v_return;
	  select replace(v_return, '&lt;/UL&gt;', '</ul>') into v_return;
	  select replace(v_return, '&lt;li&gt;', '<li>') into v_return;
	  select replace(v_return, '&lt;LI&gt;', '<li>') into v_return;
	  select replace(v_return, '&lt;/li&gt;', '</li>') into v_return;
	  select replace(v_return, '&lt;/LI&gt;', '</li>') into v_return;
	  /*  New Area tags */
	  select replace(v_return, '&lt;div&gt;', '<div>') into v_return;
	  select replace(v_return, '&lt;DIV&gt;', '<div>') into v_return;
	  select replace(v_return, '&lt;/div&gt;', '</div>') into v_return;
	  select replace(v_return, '&lt;/DIV&gt;', '</div>') into v_return;
	  /*  crossed tags */
	  select replace(v_return, '&lt;s&gt;', '<s>') into v_return;
	  select replace(v_return, '&lt;S&gt;', '<s>') into v_return;
	  select replace(v_return, '&lt;/s&gt;', '</s>') into v_return;
	  select replace(v_return, '&lt;/S&gt;', '</s>') into v_return;	
	  /*  other tags */
	  select replace(v_return, '&lt;dd&gt;', '<dd>') into v_return;
	  select replace(v_return, '&lt;DD&gt;', '<dd>') into v_return;
	  select replace(v_return, '&lt;/dd&gt;', '</dd>') into v_return;
	  select replace(v_return, '&lt;/DD&gt;', '</dd>') into v_return;
	  select replace(v_return, '&lt;sup&gt;', '<sup>') into v_return;
	  select replace(v_return, '&lt;SUP&gt;', '<sup>') into v_return;
	  select replace(v_return, '&lt;/sup&gt;', '</sup>') into v_return;
	  select replace(v_return, '&lt;/SUP&gt;', '</sup>') into v_return;
	  select replace(v_return, '&lt;dt&gt;', '<dt>') into v_return;
	  select replace(v_return, '&lt;DT&gt;', '<dt>') into v_return;
	  select replace(v_return, '&lt;/dt&gt;', '</dt>') into v_return;
	  select replace(v_return, '&lt;/DT&gt;', '</dt>') into v_return;	
	  select replace(v_return, '&lt;dl&gt;', '<dl>') into v_return;
	  select replace(v_return, '&lt;DL&gt;', '<dl>') into v_return;
	  select replace(v_return, '&lt;/dl&gt;', '</dl>') into v_return;
	  select replace(v_return, '&lt;/DL&gt;', '</dl>') into v_return;
	  select replace(v_return, '&lt;sub&gt;', '<sub>') into v_return;
	  select replace(v_return, '&lt;SUB&gt;', '<sub>') into v_return;
	  select replace(v_return, '&lt;/sub&gt;', '</sub>') into v_return;
	  select replace(v_return, '&lt;/SUB&gt;', '</sub>') into v_return;
	  select replace(v_return, '&lt;tt&gt;', '<tt>') into v_return;
	  select replace(v_return, '&lt;TT&gt;', '<tt>') into v_return;
	  select replace(v_return, '&lt;/tt&gt;', '</tt>') into v_return;
	  select replace(v_return, '&lt;/TT&gt;', '</tt>') into v_return;
	  select replace(v_return, '&lt;ol&gt;', '<ol>') into v_return;
	  select replace(v_return, '&lt;OL&gt;', '<ol>') into v_return;
	  select replace(v_return, '&lt;/ol&gt;', '</ol>') into v_return;
	  select replace(v_return, '&lt;/OL&gt;', '</ol>') into v_return;
	  select replace(v_return, '&lt;strong&gt;', '<strong>') into v_return;
	  select replace(v_return, '&lt;STRONG&gt;', '<strong>') into v_return;
	  select replace(v_return, '&lt;/strong&gt;', '</strong>') into v_return;
	  select replace(v_return, '&lt;/STRONG&gt;', '</strong>') into v_return;
	  select replace(v_return, '&lt;code&gt;', '<code>') into v_return;
	  select replace(v_return, '&lt;CODE&gt;', '<code>') into v_return;
	  select replace(v_return, '&lt;/code&gt;', '</code>') into v_return;
	  select replace(v_return, '&lt;/CODE&gt;', '</code>') into v_return;	
	  select replace(v_return, '&lt;var&gt;', '<var>') into v_return;
	  select replace(v_return, '&lt;VAR&gt;', '<var>') into v_return;
	  select replace(v_return, '&lt;/var&gt;', '</var>') into v_return;
	  select replace(v_return, '&lt;/VAR&gt;', '</var>') into v_return;
	  select replace(v_return, '&lt;cite&gt;', '<cite>') into v_return;
	  select replace(v_return, '&lt;CITE&gt;', '<cite>') into v_return;
	  select replace(v_return, '&lt;/cite&gt;', '</cite>') into v_return;
	  select replace(v_return, '&lt;/CITE&gt;', '</cite>') into v_return;
	  select replace(v_return, '&lt;dfn&gt;', '<dfn>') into v_return;
	  select replace(v_return, '&lt;DFN&gt;', '<dfn>') into v_return;
	  select replace(v_return, '&lt;/dfn&gt;', '</dfn>') into v_return;
	  select replace(v_return, '&lt;/DFN&gt;', '</dfn>') into v_return;
	  select replace(v_return, '&lt;abbr&gt;', '<abbr>') into v_return;
	  select replace(v_return, '&lt;ABBR&gt;', '<abbr>') into v_return;
	  select replace(v_return, '&lt;/abbr&gt;', '</abbr>') into v_return;
	  select replace(v_return, '&lt;/ABBR&gt;', '</abbr>') into v_return;
	  select replace(v_return, '&lt;acronym&gt;', '<acronym>') into v_return;
	  select replace(v_return, '&lt;ACRONYM&gt;', '<acronym>') into v_return;
	  select replace(v_return, '&lt;/acronym&gt;', '</acronym>') into v_return;
	  select replace(v_return, '&lt;/ACRONYM&gt;', '</acronym>') into v_return;
	  select replace(v_return, '&lt;h1&gt;', '<h1>') into v_return;
	  select replace(v_return, '&lt;H1&gt;', '<h1>') into v_return;
	  select replace(v_return, '&lt;/h1&gt;', '</h1>') into v_return;
	  select replace(v_return, '&lt;/H1&gt;', '</h1>') into v_return;
      select replace(v_return, '&lt;h2&gt;', '<h2>') into v_return;
	  select replace(v_return, '&lt;H2&gt;', '<h2>') into v_return;
	  select replace(v_return, '&lt;/h2&gt;', '</h2>') into v_return;
	  select replace(v_return, '&lt;/H2&gt;', '</h2>') into v_return;
	  select replace(v_return, '&lt;h3&gt;', '<h3>') into v_return;
	  select replace(v_return, '&lt;H3&gt;', '<h3>') into v_return;
	  select replace(v_return, '&lt;/h3&gt;', '</h3>') into v_return;
	  select replace(v_return, '&lt;/H3&gt;', '</h3>') into v_return;
	  select replace(v_return, '&lt;address&gt;', '<address>') into v_return;
	  select replace(v_return, '&lt;ADDRESS&gt;', '<address>') into v_return;
	  select replace(v_return, '&lt;/address&gt;', '</address>') into v_return;
	  select replace(v_return, '&lt;/ADDRESS&gt;', '</address>') into v_return;
	  select replace(v_return, '&lt;big&gt;', '<big>') into v_return;
	  select replace(v_return, '&lt;BIG&gt;', '<big>') into v_return;
	  select replace(v_return, '&lt;/big&gt;', '</big>') into v_return;
	  select replace(v_return, '&lt;/BIG&gt;', '</big>') into v_return;
	  select replace(v_return, '&lt;small&gt;', '<small>') into v_return;
	  select replace(v_return, '&lt;SMALL&gt;', '<small>') into v_return;
	  select replace(v_return, '&lt;/small&gt;', '</small>') into v_return;
	  select replace(v_return, '&lt;/SMALL&gt;', '</small>') into v_return;
	  select replace(v_return, '&lt;strike&gt;', '<strike>') into v_return;
	  select replace(v_return, '&lt;STRIKE&gt;', '<strike>') into v_return;
	  select replace(v_return, '&lt;/strike&gt;', '</strike>') into v_return;
	  select replace(v_return, '&lt;/STRIKE&gt;', '</strike>') into v_return;
	  select replace(v_return, '&lt;blockquote&gt;', '<blockquote>') into v_return;
	  select replace(v_return, '&lt;BLOCKQUOTE&gt;', '<blockquote>') into v_return;
	  select replace(v_return, '&lt;/blockquote&gt;', '</blockquote>') into v_return;
	  select replace(v_return, '&lt;/BLOCKQUOTE&gt;', '</blockquote>') into v_return;
	  select replace(v_return, '&lt;caption&gt;', '<caption>') into v_return;
	  select replace(v_return, '&lt;CAPTION&gt;', '<caption>') into v_return;
	  select replace(v_return, '&lt;/caption&gt;', '</caption>') into v_return;
	  select replace(v_return, '&lt;/CAPTION&gt;', '</caption>') into v_return;
	  select replace(v_return, '&lt;center&gt;', '<center>') into v_return;
	  select replace(v_return, '&lt;CENTER&gt;', '<center>') into v_return;
	  select replace(v_return, '&lt;/center&gt;', '</center>') into v_return;
	  select replace(v_return, '&lt;/CENTER&gt;', '</center>') into v_return;
	  select replace(v_return, '&lt;del&gt;', '<del>') into v_return;
	  select replace(v_return, '&lt;DEL&gt;', '<del>') into v_return;
	  select replace(v_return, '&lt;/del&gt;', '</del>') into v_return;
	  select replace(v_return, '&lt;/DEL&gt;', '</del>') into v_return;
	  select replace(v_return, '&lt;em&gt;', '<em>') into v_return;
	  select replace(v_return, '&lt;EM&gt;', '<em>') into v_return;
	  select replace(v_return, '&lt;/em&gt;', '</em>') into v_return;
	  select replace(v_return, '&lt;/EM&gt;', '</em>') into v_return;
	  select replace(v_return, '&lt;hr&gt;', '<hr>') into v_return;
	  select replace(v_return, '&lt;HR&gt;', '<hr>') into v_return;
	  select replace(v_return, '&lt;ins&gt;', '<ins>') into v_return;
	  select replace(v_return, '&lt;INS&gt;', '<ins>') into v_return;
	  select replace(v_return, '&lt;/ins&gt;', '</ins>') into v_return;
	  select replace(v_return, '&lt;/INS&gt;', '</ins>') into v_return;	  
	  select replace(v_return, '&lt;kbd&gt;', '<kbd>') into v_return;
	  select replace(v_return, '&lt;KBD&gt;', '<kbd>') into v_return;
	  select replace(v_return, '&lt;/kbd&gt;', '</kbd>') into v_return;
	  select replace(v_return, '&lt;/KBD&gt;', '</kbd>') into v_return;	
	  select replace(v_return, '&lt;samp&gt;', '<samp>') into v_return;
	  select replace(v_return, '&lt;SAMP&gt;', '<samp>') into v_return;
	  select replace(v_return, '&lt;/samp&gt;', '</samp>') into v_return;
	  select replace(v_return, '&lt;/SAMP&gt;', '</samp>') into v_return;	
	  select replace(v_return, '&lt;span&gt;', '<span>') into v_return;
	  select replace(v_return, '&lt;SPAN&gt;', '<span>') into v_return;
	  select replace(v_return, '&lt;/span&gt;', '</span>') into v_return;
	  select replace(v_return, '&lt;/SPAN&gt;', '</span>') into v_return;
	  -- Font size tags
	  select replace(v_return, '&lt;font size=1&gt;', '<font size=1>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=1&gt;', '<font size=1>') into v_return;
	  select replace(v_return, '&lt;font size=2&gt;', '<font size=2>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=2&gt;', '<font size=2>') into v_return;
	  select replace(v_return, '&lt;font size=3&gt;', '<font size=3>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=3&gt;', '<font size=3>') into v_return;
	  select replace(v_return, '&lt;font size=4&gt;', '<font size=4>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=4&gt;', '<font size=4>') into v_return;
	  select replace(v_return, '&lt;font size=5&gt;', '<font size=5>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=5&gt;', '<font size=5>') into v_return;
	  select replace(v_return, '&lt;font size=6&gt;', '<font size=6>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=6&gt;', '<font size=6>') into v_return;
	  select replace(v_return, '&lt;font size=7&gt;', '<font size=7>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=7&gt;', '<font size=7>') into v_return;
	  select replace(v_return, '&lt;font size=8&gt;', '<font size=8>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=8&gt;', '<font size=8>') into v_return;
	  select replace(v_return, '&lt;font size=9&gt;', '<font size=9>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=9&gt;', '<font size=9>') into v_return;
	  select replace(v_return, '&lt;font size=10&gt;', '<font size=10>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=10&gt;', '<font size=10>') into v_return;
	  select replace(v_return, '&lt;/font&gt;', '</font>') into v_return;
	  select replace(v_return, '&lt;/FONT&gt;', '</FONT>') into v_return;
RETURN v_return;

END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE or replace FUNCTION zssi_2HTMLescapes(v_text character varying) RETURNS character varying
AS $_$
DECLARE
    v_return character varying;
BEGIN
  v_return:=v_text;
  if instr(v_return,'&#')=0 then
    select replace(v_return, '&','&#38;') into v_return;
  end if;
  select replace(v_return, '€','&#8364;')  into v_return;
  select replace(v_return, '§','&#182;')  into v_return;
  select replace(v_return, 'ß','&#223;')  into v_return;
  select replace(v_return, 'Ä','&#196;')  into v_return;
  select replace(v_return, 'Ö','&#214;')  into v_return;
  select replace(v_return, 'Ü','&#220;')  into v_return;
  select replace(v_return, 'ä','&#228;')  into v_return; 
  select replace(v_return, 'ö','&#246;')  into v_return;   
  select replace(v_return, 'ü','&#252;')  into v_return; 
  select replace(v_return, '\', '&#92;')  into v_return;
  -- Bei Slash -> Endtags in HTML/XML belassen 
  select replace(v_return, '</', '&<<;')  into v_return;
   -- Die wirklichen Slash ersetzen
  select replace(v_return, '/', '&#47;')  into v_return;
  -- Endtags zurückholen
  select replace(v_return, '&<<;', '</')  into v_return;
  select replace(v_return, '^', '&#94;')  into v_return;
  select replace(v_return, '^', '&#94;')  into v_return;
  
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 

CREATE or replace FUNCTION zssi_tinymce2jsreportsHTML(v_text character varying) RETURNS character varying
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): Julian Brünjes
***************************************************************************************************************************************************
Part of Smartprefs
This FUNCTION translates our Advanced Editor Output into Reportable contents
*****************************************************/
AS $_$
DECLARE
    v_return character varying;
BEGIN
  v_return:=v_text;
    select replace(v_return,'<span>','') into v_return;
  select replace(v_return,'</span>','') into v_return;
  select replace(v_return,'<p>','') into v_return;
  select replace(v_return,'</p>','') into v_return;
  select regexp_replace(v_return, E'[\\r]+','<br/>','g')  into v_return;
  select regexp_replace(v_return, E'font-family:.[^;]*;','','g')  into v_return;
  select replace(v_return, '<strong>','<b>')  into v_return;
  select replace(v_return, '</strong>','</b>')  into v_return;
  select replace(v_return, '<em>','<i>')  into v_return;
  select replace(v_return, '</em>','</i>')  into v_return;
  -- Normal Textfield must have Blanks to express  > or <
  select replace(v_return, ' < ', ' &lt; ') into v_return;
  select replace(v_return, ' > ', ' &gt; ') into v_return;
--RETURN zssi_2HTML(v_return);
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 

  
CREATE or replace FUNCTION zssi_2HTML(v_text character varying) RETURNS character varying
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
 CRLF 2 HTML
*****************************************************/
DECLARE
v_return character varying;

BEGIN
/* Patch 
      select replace(v_text,E'\r\n','<br/>') into v_return;
      select replace(v_return,'"','`') into v_return;
      select replace(v_return,chr(39),'`') into  v_return;
*/

      select replace(v_text,'"','`') into v_return;
      select replace(v_return,chr(39),'`') into  v_return;
	  select replace(v_return, ' < ', ' &lt; ') into v_return;
	  select replace(v_return, ' > ', ' &gt; ') into v_return;
	  select replace(v_return,E'\r\n','<br/>') into v_return;
          select replace(v_return, '<', '&lt;') into v_return;
	  select replace(v_return, '>', '&gt;') into v_return;
/* Replace valid html tags */
	  /* bold tags */
	  select replace(v_return, '&lt;b&gt;', '<b>') into v_return;
	  select replace(v_return, '&lt;/b&gt;', '</b>') into v_return;
	  select replace(v_return, '&lt;B&gt;', '<b>') into v_return;
	  select replace(v_return, '&lt;/B&gt;', '</b>') into v_return;
	  /* preformatted  tags */
	  select replace(v_return, '&lt;pre&gt;', '<pre>') into v_return;
	  select replace(v_return, '&lt;PRE&gt;', '<pre>') into v_return;
	  select replace(v_return, '&lt;/pre&gt;', '</pre>') into v_return;
	  select replace(v_return, '&lt;/PRE&gt;', '</pre>') into v_return;
	  /* Linebreak tags */
	  select replace(v_return, '&lt;br&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;BR&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;/br&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;/BR&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;br/&gt;', '<br/>') into v_return;
	  select replace(v_return, '&lt;BR/&gt;', '<br/>') into v_return;
	  /*  italic tags */
	  select replace(v_return, '&lt;i&gt;', '<i>') into v_return;
	  select replace(v_return, '&lt;I&gt;', '<i>') into v_return;
	  select replace(v_return, '&lt;/i&gt;', '</i>') into v_return;
	  select replace(v_return, '&lt;/I&gt;', '</i>') into v_return;
	  /*  underlined tags */
	  select replace(v_return, '&lt;u&gt;', '<u>') into v_return;
	  select replace(v_return, '&lt;U&gt;', '<u>') into v_return;
	  select replace(v_return, '&lt;/u&gt;', '</u>') into v_return;
	  select replace(v_return, '&lt;/U&gt;', '</u>') into v_return;
	  /* new line tags */
	  select replace(v_return, '&lt;p&gt;', '<p>') into v_return;
	  select replace(v_return, '&lt;P&gt;', '<p>') into v_return;
	  select replace(v_return, '&lt;/p&gt;', '</p>') into v_return;
	  select replace(v_return, '&lt;/P&gt;', '</p>') into v_return;	
	  /*  List tags */
	  select replace(v_return, '&lt;ul&gt;', '<ul>') into v_return;
	  select replace(v_return, '&lt;UL&gt;', '<ul>') into v_return;
	  select replace(v_return, '&lt;/ul&gt;', '</ul>') into v_return;
	  select replace(v_return, '&lt;/UL&gt;', '</ul>') into v_return;
	  select replace(v_return, '&lt;li&gt;', '<li>') into v_return;
	  select replace(v_return, '&lt;LI&gt;', '<li>') into v_return;
	  select replace(v_return, '&lt;/li&gt;', '</li>') into v_return;
	  select replace(v_return, '&lt;/LI&gt;', '</li>') into v_return;
	  /*  New Area tags */
	  select replace(v_return, '&lt;div&gt;', '<div>') into v_return;
	  select replace(v_return, '&lt;DIV&gt;', '<div>') into v_return;
	  select replace(v_return, '&lt;/div&gt;', '</div>') into v_return;
	  select replace(v_return, '&lt;/DIV&gt;', '</div>') into v_return;
	  /*  crossed tags */
	  select replace(v_return, '&lt;s&gt;', '<s>') into v_return;
	  select replace(v_return, '&lt;S&gt;', '<s>') into v_return;
	  select replace(v_return, '&lt;/s&gt;', '</s>') into v_return;
	  select replace(v_return, '&lt;/S&gt;', '</s>') into v_return;	
	  /*  other tags */
	  select replace(v_return, '&lt;dd&gt;', '<dd>') into v_return;
	  select replace(v_return, '&lt;DD&gt;', '<dd>') into v_return;
	  select replace(v_return, '&lt;/dd&gt;', '</dd>') into v_return;
	  select replace(v_return, '&lt;/DD&gt;', '</dd>') into v_return;
	  select replace(v_return, '&lt;sup&gt;', '<sup>') into v_return;
	  select replace(v_return, '&lt;SUP&gt;', '<sup>') into v_return;
	  select replace(v_return, '&lt;/sup&gt;', '</sup>') into v_return;
	  select replace(v_return, '&lt;/SUP&gt;', '</sup>') into v_return;
	  select replace(v_return, '&lt;dt&gt;', '<dt>') into v_return;
	  select replace(v_return, '&lt;DT&gt;', '<dt>') into v_return;
	  select replace(v_return, '&lt;/dt&gt;', '</dt>') into v_return;
	  select replace(v_return, '&lt;/DT&gt;', '</dt>') into v_return;	
	  select replace(v_return, '&lt;dl&gt;', '<dl>') into v_return;
	  select replace(v_return, '&lt;DL&gt;', '<dl>') into v_return;
	  select replace(v_return, '&lt;/dl&gt;', '</dl>') into v_return;
	  select replace(v_return, '&lt;/DL&gt;', '</dl>') into v_return;
	  select replace(v_return, '&lt;sub&gt;', '<sub>') into v_return;
	  select replace(v_return, '&lt;SUB&gt;', '<sub>') into v_return;
	  select replace(v_return, '&lt;/sub&gt;', '</sub>') into v_return;
	  select replace(v_return, '&lt;/SUB&gt;', '</sub>') into v_return;
	  select replace(v_return, '&lt;tt&gt;', '<tt>') into v_return;
	  select replace(v_return, '&lt;TT&gt;', '<tt>') into v_return;
	  select replace(v_return, '&lt;/tt&gt;', '</tt>') into v_return;
	  select replace(v_return, '&lt;/TT&gt;', '</tt>') into v_return;
	  select replace(v_return, '&lt;ol&gt;', '<ol>') into v_return;
	  select replace(v_return, '&lt;OL&gt;', '<ol>') into v_return;
	  select replace(v_return, '&lt;/ol&gt;', '</ol>') into v_return;
	  select replace(v_return, '&lt;/OL&gt;', '</ol>') into v_return;
	  select replace(v_return, '&lt;strong&gt;', '<strong>') into v_return;
	  select replace(v_return, '&lt;STRONG&gt;', '<strong>') into v_return;
	  select replace(v_return, '&lt;/strong&gt;', '</strong>') into v_return;
	  select replace(v_return, '&lt;/STRONG&gt;', '</strong>') into v_return;
	  select replace(v_return, '&lt;code&gt;', '<code>') into v_return;
	  select replace(v_return, '&lt;CODE&gt;', '<code>') into v_return;
	  select replace(v_return, '&lt;/code&gt;', '</code>') into v_return;
	  select replace(v_return, '&lt;/CODE&gt;', '</code>') into v_return;	
	  select replace(v_return, '&lt;var&gt;', '<var>') into v_return;
	  select replace(v_return, '&lt;VAR&gt;', '<var>') into v_return;
	  select replace(v_return, '&lt;/var&gt;', '</var>') into v_return;
	  select replace(v_return, '&lt;/VAR&gt;', '</var>') into v_return;
	  select replace(v_return, '&lt;cite&gt;', '<cite>') into v_return;
	  select replace(v_return, '&lt;CITE&gt;', '<cite>') into v_return;
	  select replace(v_return, '&lt;/cite&gt;', '</cite>') into v_return;
	  select replace(v_return, '&lt;/CITE&gt;', '</cite>') into v_return;
	  select replace(v_return, '&lt;dfn&gt;', '<dfn>') into v_return;
	  select replace(v_return, '&lt;DFN&gt;', '<dfn>') into v_return;
	  select replace(v_return, '&lt;/dfn&gt;', '</dfn>') into v_return;
	  select replace(v_return, '&lt;/DFN&gt;', '</dfn>') into v_return;
	  select replace(v_return, '&lt;abbr&gt;', '<abbr>') into v_return;
	  select replace(v_return, '&lt;ABBR&gt;', '<abbr>') into v_return;
	  select replace(v_return, '&lt;/abbr&gt;', '</abbr>') into v_return;
	  select replace(v_return, '&lt;/ABBR&gt;', '</abbr>') into v_return;
	  select replace(v_return, '&lt;acronym&gt;', '<acronym>') into v_return;
	  select replace(v_return, '&lt;ACRONYM&gt;', '<acronym>') into v_return;
	  select replace(v_return, '&lt;/acronym&gt;', '</acronym>') into v_return;
	  select replace(v_return, '&lt;/ACRONYM&gt;', '</acronym>') into v_return;
	  select replace(v_return, '&lt;h1&gt;', '<h1>') into v_return;
	  select replace(v_return, '&lt;H1&gt;', '<h1>') into v_return;
	  select replace(v_return, '&lt;/h1&gt;', '</h1>') into v_return;
	  select replace(v_return, '&lt;/H1&gt;', '</h1>') into v_return;
      select replace(v_return, '&lt;h2&gt;', '<h2>') into v_return;
	  select replace(v_return, '&lt;H2&gt;', '<h2>') into v_return;
	  select replace(v_return, '&lt;/h2&gt;', '</h2>') into v_return;
	  select replace(v_return, '&lt;/H2&gt;', '</h2>') into v_return;
	  select replace(v_return, '&lt;h3&gt;', '<h3>') into v_return;
	  select replace(v_return, '&lt;H3&gt;', '<h3>') into v_return;
	  select replace(v_return, '&lt;/h3&gt;', '</h3>') into v_return;
	  select replace(v_return, '&lt;/H3&gt;', '</h3>') into v_return;
	  select replace(v_return, '&lt;address&gt;', '<address>') into v_return;
	  select replace(v_return, '&lt;ADDRESS&gt;', '<address>') into v_return;
	  select replace(v_return, '&lt;/address&gt;', '</address>') into v_return;
	  select replace(v_return, '&lt;/ADDRESS&gt;', '</address>') into v_return;
	  select replace(v_return, '&lt;big&gt;', '<big>') into v_return;
	  select replace(v_return, '&lt;BIG&gt;', '<big>') into v_return;
	  select replace(v_return, '&lt;/big&gt;', '</big>') into v_return;
	  select replace(v_return, '&lt;/BIG&gt;', '</big>') into v_return;
	  select replace(v_return, '&lt;small&gt;', '<small>') into v_return;
	  select replace(v_return, '&lt;SMALL&gt;', '<small>') into v_return;
	  select replace(v_return, '&lt;/small&gt;', '</small>') into v_return;
	  select replace(v_return, '&lt;/SMALL&gt;', '</small>') into v_return;
	  select replace(v_return, '&lt;strike&gt;', '<strike>') into v_return;
	  select replace(v_return, '&lt;STRIKE&gt;', '<strike>') into v_return;
	  select replace(v_return, '&lt;/strike&gt;', '</strike>') into v_return;
	  select replace(v_return, '&lt;/STRIKE&gt;', '</strike>') into v_return;
	  select replace(v_return, '&lt;blockquote&gt;', '<blockquote>') into v_return;
	  select replace(v_return, '&lt;BLOCKQUOTE&gt;', '<blockquote>') into v_return;
	  select replace(v_return, '&lt;/blockquote&gt;', '</blockquote>') into v_return;
	  select replace(v_return, '&lt;/BLOCKQUOTE&gt;', '</blockquote>') into v_return;
	  select replace(v_return, '&lt;caption&gt;', '<caption>') into v_return;
	  select replace(v_return, '&lt;CAPTION&gt;', '<caption>') into v_return;
	  select replace(v_return, '&lt;/caption&gt;', '</caption>') into v_return;
	  select replace(v_return, '&lt;/CAPTION&gt;', '</caption>') into v_return;
	  select replace(v_return, '&lt;center&gt;', '<center>') into v_return;
	  select replace(v_return, '&lt;CENTER&gt;', '<center>') into v_return;
	  select replace(v_return, '&lt;/center&gt;', '</center>') into v_return;
	  select replace(v_return, '&lt;/CENTER&gt;', '</center>') into v_return;
	  select replace(v_return, '&lt;del&gt;', '<del>') into v_return;
	  select replace(v_return, '&lt;DEL&gt;', '<del>') into v_return;
	  select replace(v_return, '&lt;/del&gt;', '</del>') into v_return;
	  select replace(v_return, '&lt;/DEL&gt;', '</del>') into v_return;
	  select replace(v_return, '&lt;em&gt;', '<em>') into v_return;
	  select replace(v_return, '&lt;EM&gt;', '<em>') into v_return;
	  select replace(v_return, '&lt;/em&gt;', '</em>') into v_return;
	  select replace(v_return, '&lt;/EM&gt;', '</em>') into v_return;
	  select replace(v_return, '&lt;hr&gt;', '<hr>') into v_return;
	  select replace(v_return, '&lt;HR&gt;', '<hr>') into v_return;
	  select replace(v_return, '&lt;ins&gt;', '<ins>') into v_return;
	  select replace(v_return, '&lt;INS&gt;', '<ins>') into v_return;
	  select replace(v_return, '&lt;/ins&gt;', '</ins>') into v_return;
	  select replace(v_return, '&lt;/INS&gt;', '</ins>') into v_return;	  
	  select replace(v_return, '&lt;kbd&gt;', '<kbd>') into v_return;
	  select replace(v_return, '&lt;KBD&gt;', '<kbd>') into v_return;
	  select replace(v_return, '&lt;/kbd&gt;', '</kbd>') into v_return;
	  select replace(v_return, '&lt;/KBD&gt;', '</kbd>') into v_return;	
	  select replace(v_return, '&lt;samp&gt;', '<samp>') into v_return;
	  select replace(v_return, '&lt;SAMP&gt;', '<samp>') into v_return;
	  select replace(v_return, '&lt;/samp&gt;', '</samp>') into v_return;
	  select replace(v_return, '&lt;/SAMP&gt;', '</samp>') into v_return;	
	  select replace(v_return, '&lt;span&gt;', '<span>') into v_return;
	  select replace(v_return, '&lt;SPAN&gt;', '<span>') into v_return;
	  select replace(v_return, '&lt;/span&gt;', '</span>') into v_return;
	  select replace(v_return, '&lt;/SPAN&gt;', '</span>') into v_return;
	  -- Font size tags
	  select replace(v_return, '&lt;font size=1&gt;', '<font size=1>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=1&gt;', '<font size=1>') into v_return;
	  select replace(v_return, '&lt;font size=2&gt;', '<font size=2>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=2&gt;', '<font size=2>') into v_return;
	  select replace(v_return, '&lt;font size=3&gt;', '<font size=3>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=3&gt;', '<font size=3>') into v_return;
	  select replace(v_return, '&lt;font size=4&gt;', '<font size=4>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=4&gt;', '<font size=4>') into v_return;
	  select replace(v_return, '&lt;font size=5&gt;', '<font size=5>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=5&gt;', '<font size=5>') into v_return;
	  select replace(v_return, '&lt;font size=6&gt;', '<font size=6>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=6&gt;', '<font size=6>') into v_return;
	  select replace(v_return, '&lt;font size=7&gt;', '<font size=7>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=7&gt;', '<font size=7>') into v_return;
	  select replace(v_return, '&lt;font size=8&gt;', '<font size=8>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=8&gt;', '<font size=8>') into v_return;
	  select replace(v_return, '&lt;font size=9&gt;', '<font size=9>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=9&gt;', '<font size=9>') into v_return;
	  select replace(v_return, '&lt;font size=10&gt;', '<font size=10>') into v_return;
	  select replace(v_return, '&lt;FONT SIZE=10&gt;', '<font size=10>') into v_return;
	  select replace(v_return, '&lt;/font&gt;', '</font>') into v_return;
	  select replace(v_return, '&lt;/FONT&gt;', '</FONT>') into v_return;
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION zspr_getproductdocnoteCpyText(p_org_id character varying, p_product_id character varying, p_bpartner_id character varying, p_uom_id varchar)  
RETURNS character varying AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2021 Stefan Zimmermann All Rights Reserved.
Contributor(s): 
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return varchar:='';
v_tmp varchar;
v_doctype varchar;
v_cur record;
BEGIN
    for v_cur in ((select 'proddocnote' as docnote , coalesce(proddesc_ordernum,0) as ordernum  from zspr_printinfo where ad_org_id in ('0',p_org_id) and cpy_Proddocnote2docnote='Y' order by ad_org_id desc limit 1)
                  union
                  (select 'proddesc' as docnote , coalesce(proddocnote_ordernum,0) as ordernum  from zspr_printinfo where ad_org_id in ('0',p_org_id) and cpy_Proddesc2docnote='Y' order by ad_org_id desc limit 1)
                  union
                  (select 'vendpnumber' as docnote ,  coalesce(vendpnumberdn_ordernum,0) as ordernum  from zspr_printinfo where ad_org_id in ('0',p_org_id) and cpy_Vendpnumber2docnote='Y' order by ad_org_id desc limit 1)
                  order by ordernum)
    LOOP
        if v_cur.docnote='proddesc' then
            select description into v_tmp from m_product where m_product_id=p_product_id;
            if v_tmp is not null then 
                v_return:=v_tmp;
            end if;
        end if;
        if v_cur.docnote='proddocnote' then
            SELECT documentnote  into v_tmp  FROM m_product  WHERE m_product_id = p_product_id;
            if v_tmp is not null then 
                if v_return!='' then v_return:=v_return||'<br/>';  end if;
                v_return:=v_return||v_tmp;
            end if;
        end if;
        if v_cur.docnote='vendpnumber' then
            SELECT vendorproductno   into v_tmp 
            FROM m_product_po
            WHERE 
            m_product_id = p_product_id
            AND case when p_bpartner_id is not null then c_bpartner_id = p_bpartner_id else 1=1 end
            and case when p_uom_id is not null then c_uom_id=p_uom_id else 1=1 end
            AND ISACTIVE ='Y' and iscurrentvendor='Y'  
            order by coalesce(qualityrating,0) desc,updated desc  LIMIT 1;
            if v_tmp is not null then 
                if v_return!='' then v_return:=v_return||'<br/>';  end if;
                v_return:=v_return||zssi_getText('zssi_vendorproductno',coalesce((select ad_language from c_bpartner where c_bpartner_id=p_bpartner_id),'de_DE'))||v_tmp;
            end if;
        end if;
    END LOOP;
RETURN v_return;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;  


  
CREATE OR REPLACE FUNCTION zspr_getproductprintouttext(p_docline_id character varying, p_language character varying, p_language2 character varying)
RETURNS character varying AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE

v_doctype character varying;
v_org character varying;
v_bpartner_id character varying;
v_product_id character varying;
v_orderline_id character varying;
v_invoiceline_id character varying;
v_inoutline_id character varying;
v_desc numeric;
v_printattrsbold  character(1);
v_printattrsnewline  character(1);
v_printpnumberbold  character(1);
v_printpnumbernewline  character(1);
v_printpnamebold   character(1);
v_printpnamenewline  character(1);
v_printvendorpnumberbold   character(1);
v_printvendorpnumbernewline  character(1);
v_printdocnotebold  character(1);
v_printdocnotenewline  character(1);
v_printpdescbold  character(1);
v_printpdescnewline  character(1);
v_printordernumberonshipmentbold  character(1);
v_printordernumberonshipmentnewline  character(1);
v_printordernumberoninvoicebold  character(1);
v_printordernumberoninvoicenewline  character(1);
v_printshipmentnumberoninvoicebold  character(1);
v_printshipmentnumberoninvoicenewline  character(1);
v_printshipmentdateoninvoicebold  character(1);
v_printshipmentdateoninvoicenewline  character(1);
v_printmanufacturerdata character(1);
v_manufacturertext varchar;
v_printserialnumberondocs character(1);
v_printsetproductwithbom character(1);
v_prefix character varying:='';
v_suffix character varying:='';
v_temp character varying;
v_temp2 character varying;
v_temp3 character varying;
v_tempinout character varying;
v_cur RECORD;
v_return character varying:='';
v_manu varchar;
v_uom varchar;
v_attrsetinstance varchar;
v_location varchar;
v_foreigncountry varchar:='N';
v_printcustom varchar ;
BEGIN
        select c_doctype, ad_org_id, c_bpartner_id, m_product_id, c_orderline_id, c_invoiceline_id, m_inoutline_id,m_product_po_id,m_product_uom_id,m_attributesetinstance_id,bplocation,dsclen
        into
        v_doctype, v_org, v_bpartner_id, v_product_id, v_orderline_id, v_invoiceline_id, v_inoutline_id,v_manu,v_uom,v_attrsetinstance,v_location,v_desc
        from (select 'order' as c_doctype, c_orderline.ad_org_id, c_order.c_bpartner_id, c_orderline.m_product_id, p_docline_id as c_orderline_id, null as c_invoiceline_id, null as m_inoutline_id,m_product_po_id,m_product_uom_id,c_orderline.m_attributesetinstance_id , coalesce(c_order.delivery_location_id,c_order.c_bpartner_location_id) as bplocation,length(c_orderline.description) as dsclen
        from c_orderline, c_order
        where p_docline_id=c_orderline.c_orderline_id and c_order.c_order_id=c_orderline.c_order_id
        union
        select 'invoice' as c_doctype, c_invoiceline.ad_org_id, c_invoice.c_bpartner_id, c_invoiceline.m_product_id, c_invoiceline.c_orderline_id, p_docline_id as c_invoiceline_id, c_invoiceline.m_inoutline_id,null as m_product_po_id,m_product_uom_id,c_invoiceline.m_attributesetinstance_id,c_invoice.c_bpartner_location_id as bplocation,length(c_invoiceline.description) as dsclen
        from c_invoiceline, c_invoice
        where p_docline_id=c_invoiceline.c_invoiceline_id and c_invoice.c_invoice_id=c_invoiceline.c_invoice_id
        union
        select 'shipment' as c_doctype, m_inoutline.ad_org_id, m_inout.c_bpartner_id, coalesce(m_inoutline.m_setproductid,m_inoutline.m_product_id) as m_product_id, m_inoutline.c_orderline_id, null as c_invoiceline_id, p_docline_id as m_inoutline_id,null as m_product_po_id,m_product_uom_id,m_inoutline.m_attributesetinstance_id,m_inout.c_bpartner_location_id as bplocation,length(m_inoutline.description) as dsclen
        from m_inoutline, m_inout
        where p_docline_id=m_inoutline.m_inoutline_id and m_inout.m_inout_id=m_inoutline.m_inout_id) a;
        select c_uom_id into v_uom from m_product_uom where m_product_uom_id=v_uom;
        if (select l.c_country_id from c_location l,ad_orginfo o where o.c_location_id=l.c_location_id and o.ad_org_id=v_org) !=
        (select l.c_country_id from c_location l,c_bpartner_location b where b.c_location_id=l.c_location_id and b.c_bpartner_location_id=v_location)
        then
            v_foreigncountry:='Y';
        end if;
        --
    select printattrsbold, printattrsnewline, printpnumberbold, printpnumbernewline,
                printpnamebold, printpnamenewline, printvpnumberbold, printvpnumbernewline,
                printdocnotebold, printdocnotenewline, printpdescbold, printpdescnewline,
                printordernumberonshipmentbold, printordernumberonshipmentnewline, printordernumberoninvoicebold, printordernumberoninvoicenewline,
                printshipmentnumberoninvoicebold, printshipmentnumberoninvoicenewline, printshipmentdateoninvoicebold, printshipmentdateoninvoicenewline,printserialnumberondocs,printsetproductwithbom,Printcustominfo, addmanufacturerinfo
    into
                v_printattrsbold, v_printattrsnewline, v_printpnumberbold, v_printpnumbernewline,
                v_printpnamebold, v_printpnamenewline, v_printvendorpnumberbold, v_printvendorpnumbernewline,
                v_printdocnotebold, v_printdocnotenewline, v_printpdescbold, v_printpdescnewline,
                v_printordernumberonshipmentbold, v_printordernumberonshipmentnewline, v_printordernumberoninvoicebold, v_printordernumberoninvoicenewline,
                v_printshipmentnumberoninvoicebold, v_printshipmentnumberoninvoicenewline, v_printshipmentdateoninvoicebold, v_printshipmentdateoninvoicenewline,v_printserialnumberondocs,v_printsetproductwithbom,v_printcustom, v_printmanufacturerdata 
    from zspr_printinfo where ad_org_id in ('0',v_org) order by ad_org_id desc limit 1;
    --
    for v_cur in (select coalesce(attrs_ordernum,210) as ordernum, 'attributes' as field from zspr_printinfo where printattrsondocs='Y' and ad_org_id = v_org
                    union
                    select coalesce(pnumber_ordernum,100) as ordernum, 'productnumber' as field from zspr_printinfo where printpnumberondocs='Y' and ad_org_id = v_org
                    union
                    select coalesce(pname_ordernum,200) as ordernum, 'productname' as field from zspr_printinfo where printpnameondocs='Y' and ad_org_id = v_org
                    union
                    select coalesce(vpnumber_ordernum,110) as ordernum, 'vpnumber' as field from zspr_printinfo where printvpnumberondocs='Y' and ad_org_id = v_org
                    union
                    select coalesce(vpnumber_ordernum,115) as ordernum, 'manunumber' as field from zspr_printinfo where addmanufacturerinfo='Y' and ad_org_id = v_org
                    union
                    select coalesce(docnote_ordernum,230) as ordernum, 'docnote' as field from zspr_printinfo where printdocnoteondocs='Y' and ad_org_id = v_org
                    union
                    select coalesce(pdesc_ordernum,220) as ordernum, 'productdescription' as field from zspr_printinfo where printpdescondocs='Y' and ad_org_id = v_org
                    union
                    select coalesce(pordnoship_ordernum,120) as ordernum, 'ordernoonshipment' as field from zspr_printinfo where printordernumberonshipment='Y' and ad_org_id = v_org and v_doctype = 'shipment'
                    union
                    select coalesce(pserialnumber_ordernum,1000) as ordernum, 'serialnumberondocs' as field from zspr_printinfo where printserialnumberondocs='Y' and ad_org_id = v_org and (v_doctype = 'shipment' or v_doctype = 'invoice' or v_doctype='order')
                    union
                    select  coalesce(pcustominfo_ordernum,1010) as ordernum, 'printcustominfo' as field from zspr_printinfo where printcustominfo='Y' and ad_org_id = v_org and (v_doctype = 'shipment' or v_doctype = 'invoice' or v_doctype='order')
                    union
                    select coalesce(pordnoinv_ordernum, 130) as ordernum, 'ordernooninvoice' as field from zspr_printinfo where printordernumberoninvoice='Y' and ad_org_id = v_org and v_doctype = 'invoice'
                    union
                    select coalesce(pshipnoinv_ordernum,140) as ordernum, 'shipmentnooninvoice' as field from zspr_printinfo where printshipmentnumberoninvoice='Y' and ad_org_id = v_org and v_doctype = 'invoice'
                    union
                    select coalesce(pshipdateinv_ordernum,90) as ordernum, 'shipmentdateoninvoice' as field from zspr_printinfo where printshipmentdateoninvoice='Y' and ad_org_id = v_org and v_doctype = 'invoice'
                order by ordernum)
    loop
                if v_cur.field = 'attributes' and v_attrsetinstance is not null then
                        if v_printattrsbold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printattrsnewline='Y' then 
                            if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                v_prefix:='<br/>'||v_prefix;
                            end if;
                        end if;
                        select replace(description,'_',';') into v_temp from m_attributesetinstance where m_attributesetinstance_id=v_attrsetinstance;
                        if  v_temp is not null and v_temp!='' then
                            v_return:=v_return||v_prefix||v_temp||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
                elsif v_cur.field = 'vpnumber' then
                        if v_printvendorpnumberbold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printvendorpnumbernewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select case when p.vendorproductno is not null then zssi_getText('zssi_vendorproductno',p_language)||p.vendorproductno else '' end                                     
                                into v_temp from m_product_po p left join m_manufacturer m on m.m_manufacturer_id=p.m_manufacturer_id where p.m_product_id=v_product_id and p.c_bpartner_id=v_bpartner_id
                            and case when v_uom is not null then p.c_uom_id=v_uom else  p.c_uom_id is null end and 
                            case when v_manu is not null then p.m_product_po_id=v_manu else p.m_manufacturer_id is null and p.manufacturernumber is null end ;
                        if coalesce(v_temp,'')!='' then
                            v_return:=v_return||v_prefix||coalesce(v_temp,'')||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
                elsif v_cur.field = 'manunumber' then
                            if v_printvendorpnumberbold='Y' then 
                                    v_prefix:='<b>';
                                    v_suffix:='</b>';
                            end if;
                            if v_printvendorpnumbernewline='Y' then
                                    if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                            v_prefix:='<br/>'||v_prefix;
                                    end if;
                            end if;
                            if v_printmanufacturerdata is not null and v_printmanufacturerdata='Y' then
                                select case when p.m_manufacturer_id is not null or p.manufacturernumber is not null then zssi_getText('zssi_manufacturertext',p_language)||coalesce(m.name,'')||'-'||coalesce(p.manufacturernumber,'') else '' end into v_manufacturertext from m_product_po p left join m_manufacturer m on m.m_manufacturer_id=p.m_manufacturer_id where p.m_product_id=v_product_id and p.c_bpartner_id=v_bpartner_id
                                and case when v_uom is not null then p.c_uom_id=v_uom else  p.c_uom_id is null end and 
                                case when v_manu is not null then p.m_product_po_id=v_manu else p.m_manufacturer_id is null and p.manufacturernumber is null end;
                            end if;
                            if coalesce(v_manufacturertext,'')!='' then
                                v_return:=v_return||v_prefix||coalesce(v_manufacturertext,'')||v_suffix;
                            end if;
                            v_prefix:='';
                            v_suffix:='';
                        
                elsif v_cur.field = 'productnumber' then
                        if v_printpnumberbold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printpnumbernewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>' and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select value into v_temp from m_product where m_product_id=v_product_id;
                        if v_temp!='~' then
                            v_return:=v_return||v_prefix||v_temp||' '||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
                elsif v_cur.field = 'productname' then
                        if v_printpnamebold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printpnamenewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        if coalesce(v_printsetproductwithbom,'N')='Y' then
                            if zssi_checkifsetproduct(v_product_id)='Y' then
                                select zssi_getproductname(v_product_id,p_language) into v_temp;
                                select zssi_getproductset_complete(v_product_id,p_language) into v_temp3;
                                v_temp:=v_temp||case when  substr(v_temp,length(v_temp)-4,5)!='<br/>' then '<br/>' else '' end||'<font size=1>'||v_temp3||'</font>';
                            elseif zssi_checkifsetproduct(v_product_id)='N' then
                                select zssi_getproductname(v_product_id,p_language) into v_temp;
                            end if;
                        else
                            select zssi_getproductname(v_product_id,p_language) into v_temp;
                        end if;
                        v_temp2:=v_temp;
                        if p_language2 is not null then
                            if coalesce(v_printsetproductwithbom,'N')='Y' then
                                if zssi_checkifsetproduct(v_product_id)='Y' then
                                    select zssi_getproductname(v_product_id,p_language2) into v_temp2;
                                    select zssi_getproductset_complete(v_product_id,p_language2) into v_temp3;
                                    v_temp2:=v_temp2||case when  substr(v_temp2,length(v_temp2)-4,5)!='<br/>' then '<br/>' else '' end||'<font size=1>'||v_temp3||'</font>';
                                elseif zssi_checkifsetproduct(v_product_id)='N' then
                                    select zssi_getproductname(v_product_id,p_language2) into v_temp2;
                                end if;
                            elseif coalesce(v_printsetproductwithbom,'N')='N' then
                                    select zssi_getproductname(v_product_id,p_language2) into v_temp2;
                            end if;
                        end if;
                        if v_temp!='~' then
                            if (v_temp2!=v_temp and v_temp!='') then
                                    v_return:=v_return||v_prefix||v_temp||' '||case when  substr(v_temp,length(v_temp)-4,5)!='<br/>' then '<br/>' else '' end||v_temp2||' '||v_suffix;
                            elsif v_temp!='' then
                                    v_return:=v_return||v_prefix||v_temp||' '||v_suffix;
                            end if;
                        end if;	
                        v_prefix:='';
                        v_suffix:='';
                elsif v_cur.field = 'docnote' then
                        if v_printdocnotebold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printdocnotenewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select documentnote into v_temp from m_product_trl where m_product_id=v_product_id and ad_language=p_language;
                        if v_temp is null then 
                                select documentnote into v_temp from m_product where m_product_id=v_product_id;
                        end if;
                        v_temp2:=v_temp;
                        if p_language2 is not null then
                                        select documentnote into v_temp from m_product_trl where m_product_id=v_product_id and ad_language=p_language2;
                                        if v_temp is null then 
                                                select documentnote into v_temp from m_product where m_product_id=v_product_id;
                                        end if;
                        end if;
                        if coalesce(v_temp2,'X')!=coalesce(v_temp,'X') and coalesce(v_temp2,'')!='' and coalesce(v_temp,'')!='' then
                                v_return:=v_return||v_prefix||coalesce(v_temp2,'')||' '||'<br/>'||coalesce(v_temp,'')||' '||v_suffix;
                        elsif v_temp is not null and coalesce(v_temp,'')!='' then
                                v_return:=v_return||v_prefix||v_temp||' '||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
                elsif v_cur.field = 'productdescription' then
                        if v_printpdescbold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printpdescnewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select description into v_temp from m_product_trl where m_product_id=v_product_id and ad_language=p_language;
                        if v_temp is null then 
                                select description into v_temp from m_product where m_product_id=v_product_id;
                        end if;
                        v_temp2:=v_temp;
                        if p_language2 is not null then
                                        select description into v_temp from m_product_trl where m_product_id=v_product_id and ad_language=p_language2;
                                        if v_temp is null then 
                                                select description into v_temp from m_product where m_product_id=v_product_id;
                                        end if;
                        end if;
                        if coalesce(v_temp2,'X')!=coalesce(v_temp,'X') and coalesce(v_temp2,'')!='' and coalesce(v_temp,'')!='' then
                                v_return:=v_return||v_prefix||coalesce(v_temp2,'')||case when  substr(coalesce(v_temp2,''),length(coalesce(v_temp2,''))-4,5)!='<br/>' then '<br/>' else '' end||coalesce(v_temp,'')||' '||v_suffix;
                        elsif v_temp is not null and coalesce(v_temp,'')!='' then
                                v_return:=v_return||v_prefix||v_temp||' '||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
                elsif v_cur.field = 'ordernoonshipment' then
                        if v_printordernumberonshipmentbold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printordernumberonshipmentnewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select documentno into v_temp from c_order where c_order.c_order_id=(select c_order_id from c_orderline where c_orderline.c_orderline_id=(select c_orderline_id from m_inoutline where m_inoutline_id=p_docline_id));
                        if v_temp is not null and coalesce(v_temp,'')!='' then
                                v_return:=v_return||v_prefix||ad_message_get2('zssi_printordernumberonshipment', p_language)||' '||v_temp||' '||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
                elsif v_cur.field = 'serialnumberondocs' then
                        if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                            v_prefix:='<br/>'||v_prefix;
                        end if;
                        if zspr_getserialnumbersfrominout(p_docline_id, p_language)!='' then
                            v_return:=v_return||v_prefix||zspr_getserialnumbersfrominout(p_docline_id, p_language);
                        end if;
                        v_prefix:='';
                --elsif v_cur.field = 'printcustominfo' and v_foreigncountry='Y' then
                elsif v_cur.field = 'printcustominfo' then
                        if substr(v_return,length(v_return)-4,5)!='<br/>' and zspr_getcustomstext(v_product_id, p_language)!=''  and v_return!='' then
                            v_prefix:='<br/>'||v_prefix;
                        end if;
                        if zspr_getcustomstext(v_product_id, p_language)!='' then
                            v_return:=v_return||v_prefix||zspr_getcustomstext(v_product_id, p_language);
                        end if;
                        v_prefix:='';
                elsif v_cur.field = 'ordernooninvoice' then
                        if v_printordernumberoninvoicebold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printordernumberoninvoicenewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select documentno into v_temp from c_order where c_order.c_order_id=(select c_order_id from c_orderline where c_orderline.c_orderline_id=(select c_orderline_id from c_invoiceline where c_invoiceline_id=p_docline_id));
                        if v_temp is not null and v_temp!='' then
                                v_return:=v_return||v_prefix||ad_message_get2('zssi_printordernumberoninvoice', p_language)||' '||v_temp||' '||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';                      
        
                elsif v_cur.field = 'shipmentnooninvoice' then
                        if v_printshipmentnumberoninvoicebold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printshipmentnumberoninvoicenewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select documentno into v_temp from m_inout where m_inout.m_inout_id=(select m_inout_id from m_inoutline where m_inoutline.m_inoutline_id=(select m_inoutline_id from c_invoiceline where c_invoiceline_id=p_docline_id));
                        if v_temp is not null and v_temp!='' then
                                v_return:=v_return||v_prefix||ad_message_get2('zssi_printshipmentnumberoninvoice', p_language)||' '||v_temp||' '||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
        
                elsif v_cur.field = 'shipmentdateoninvoice' then
                        if v_printshipmentdateoninvoicebold='Y' then 
                                v_prefix:='<b>';
                                v_suffix:='</b>';
                        end if;
                        if v_printshipmentdateoninvoicenewline='Y' then
                                if substr(v_return,length(v_return)-4,5)!='<br/>'  and v_return!='' then
                                        v_prefix:='<br/>'||v_prefix;
                                end if;
                        end if;
                        select zssi_strdate(movementdate, p_language) into v_temp from m_inout where m_inout.m_inout_id=(select m_inout_id from m_inoutline where m_inoutline.m_inoutline_id=(select m_inoutline_id from c_invoiceline where c_invoiceline_id=p_docline_id));
                        if v_temp is not null and v_temp!='' then
                                v_return:=v_return||v_prefix||ad_message_get2('zssi_printshipmentdateoninvoice', p_language)||' '||v_temp||' '||v_suffix;
                        end if;
                        v_prefix:='';
                        v_suffix:='';
        
                end if;         
    end loop;
    v_return:=v_return||zssi_getframecontracttext(p_docline_id, p_language , p_language2);
    v_return:=v_return||zssi_getpartialdeliverytext(p_docline_id, p_language , p_language2);
    v_return:=v_return||zssi_getsubscriptionfrequencetext(p_docline_id, p_language , p_language2);
    if v_desc>0 and substr(v_return,length(v_return)-4,5)!='<br/>' then v_return:=v_return||'<br/>'; end if;
    if (v_return='' or v_return='<br/>') then
        RETURN '';
    else
        RETURN v_return;
    end if;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION zssi_getsubscriptionfrequencetext(p_docline_id character varying, p_language character varying, p_language2 character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): 
***************************************************************************************************************************************************

*****************************************************/
DECLARE
v_return character varying:='';
v_count numeric;
v_frameline_id character varying;
v_docno character varying;
v_begin timestamp without time zone;
v_end timestamp without time zone;
v_obegin timestamp without time zone;
v_oend timestamp without time zone;
v_change timestamp without time zone;
v_isratebill character varying;
v_isometime character varying;
v_order varchar;
v_iscomplete varchar;
v_line numeric;
v_sorder varchar;
v_curr varchar;
v_cur record;
v_cur2 record;
v_datestr varchar;
v_mon numeric;
v_yer numeric;
v_dd varchar:='N';
v_amt numeric:=-1;
v_price numeric;
v_cdate timestamp without time zone;
v_ddd   timestamp without time zone;
BEGIN
      select o.c_order_id,o.subsrdailyratebilling,coalesce(o.subscriptionchangedate,o.contractdate),o.contractdate,o.enddate,l.isonetimeposition,l.line ,
            case when l.linenetamt=0 then l.linegrossamt else l.linenetamt end 
            into v_order,v_isratebill ,v_change,v_obegin,v_oend,v_isometime ,v_line,v_amt
            from c_order o, c_orderline l 
            where o.c_order_id=l.c_order_id and l.c_orderline_id=p_docline_id  AND l.ispricesuppressed!='Y' AND l.iscombined!='Y';
      select c.cursymbol into v_curr from c_currency c,c_order o where o.c_currency_id=c.c_currency_id and o.c_order_id=v_order;
      if coalesce(v_isratebill,'N')='Y' and coalesce(v_isometime,'N')='N'then
        -- New Comming POsitions:
        /*
        if (select count(*) from c_orderline l,c_order o where  o.c_order_id=l.c_order_id  and l.ref_orderline_id=p_docline_id and o.contractdate>v_change)>0 and
             (select count(*) from c_orderline l,c_order o where  o.c_order_id=l.c_order_id  and l.ref_orderline_id=p_docline_id and o.contractdate<first_dayofmonth(v_change))=0 then
                if v_return!='' then v_return:=v_return||'<br/>'; end if; 
                v_return:=zssi_getText('SubsIntervalDaylirateFrom',p_language)||' '||zssi_strDate(v_change,p_language)||'<br/>'; 
        end if;
        */
        if (select count(*) from (select distinct case when l.linenetamt=0 then l.linegrossamt else l.linenetamt end from c_orderline l where l.ref_orderline_id=p_docline_id) a)>1
            or (select  count(*) from c_order where orderselfjoin=v_order)!=(select  count(*) from c_orderline where ref_orderline_id=p_docline_id)
        then
            v_amt:=-1;
            v_change:=null;
            -- Select all changes on this Line ordered by Intervals.
            for v_cur in (select case when l.linenetamt=0 then l.linegrossamt else l.linenetamt end as amt,l.desireddeliverydate,o.contractdate,o.enddate,o.c_order_id, l.qtyordered, l.c_uom_id, l.priceactual
                        from c_orderline l,c_order o, c_orderline lo where o.c_order_id=l.c_order_id and l.ref_orderline_id=p_docline_id and o.docstatus='CO' and o.iscompletelyinvoiced='N' and l.ref_orderline_id = lo.c_orderline_id
                        order by o.enddate,coalesce(l.desireddeliverydate,'infinity'::timestamp))
            LOOP
                v_begin:=v_cur.contractdate;
                if v_cur.desireddeliverydate is not null then
                    v_begin:=coalesce(v_change+1,v_cur.contractdate);
                    v_change:=v_cur.desireddeliverydate;
                else
                    if v_change is not null then
                        v_begin:=v_change+1;
                        v_change:=null;
                    end if;
                end if;
                if v_cur.amt!=v_amt then
                    if v_return='' then v_return:='<br/>'; end if; 
                    --v_return:=v_return||zssi_getText('SubsIntervalDaylirateFrom',p_language)||' '||zssi_strDate(v_begin,p_language)||': '||zssi_strNumber(v_cur.amt,p_language)||' '||v_curr||'<br/>';    
                     v_return:=v_return||zssi_getText('SubsIntervalDaylirateFrom',p_language)||' '||zssi_strDate(v_begin,p_language)||coalesce('-'||zssi_strDate(v_change,p_language),'')||'<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'||zssi_strNumber(v_cur.amt,p_language)||' '||v_curr||' ' ||
                        '('||v_cur.qtyordered||zssi_getuom(v_cur.c_uom_id,p_language)||' @ '||zssi_strNumber(v_cur.priceactual,p_language)||' '||v_curr||')<br/>';
                end if;
                v_amt:=v_cur.amt;
            END LOOP;
        end if;
      end if;
      -- Teiweise Berecnunhgen.
      select c.cursymbol,iol.desireddeliverydate,iol.pricelist into v_curr,v_cdate,v_price from c_orderline iol,c_order io,c_order o,c_invoiceline il,c_currency c
            where il.c_orderline_id=iol.c_orderline_id and io.c_order_id=iol.c_order_id and o.c_order_id=io.orderselfjoin and c.c_currency_id=o.c_currency_id and
                o.subsrdailyratebilling='Y' and  iol.pricelist != iol.priceactual and il.c_invoiceline_id=p_docline_id;
      if v_price is not null AND v_price != 0 then
        v_return:=v_return||zssi_getText('SubsIntervalMonthlylirate',p_language)||': '||zssi_strNumber(v_price,p_language)||' '||v_curr||'<br/>';    
      end if;
             
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
    
  
CREATE OR REPLACE FUNCTION zssi_getframecontracttext(p_docline_id character varying, p_language character varying, p_language2 character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): 
***************************************************************************************************************************************************

*****************************************************/
DECLARE
v_return character varying:='';
v_count numeric;
v_frameline_id character varying;
v_docno character varying;
v_begin character varying;
v_end character varying;
v_remains character varying;
v_frameqty character varying;

BEGIN
      select orderlineselfjoin into v_frameline_id from c_orderline where c_orderline_id=p_docline_id;
      if v_frameline_id is not null then
            -- Is a Frame-Contract ?
            select count(*) into v_count from c_order o,c_orderline ol where ol.c_orderline_id=v_frameline_id and ol.c_order_id=o.c_order_id and o.c_doctype_id in ('56913A519BA94EB59DAE5BF9A82F5F7D','559A80F2E27742D4B2C476045F5C834F')  and o.docstatus='CO';
            if v_count=1 then
              select o.documentno,coalesce(to_char(o.contractdate,'dd.mm.yyyy'),''), coalesce(to_char(o.enddate,'dd.mm.yyyy'),''),to_char(ol.qtyordered-coalesce(ol.calloffqty,0)),to_char(ol.qtyordered) 
              into v_docno,v_begin,v_end,v_remains,v_frameqty from c_order o,c_orderline ol where ol.c_order_id=o.c_order_id and ol.c_orderline_id=v_frameline_id;
              if p_language='de_DE' then
              v_return:='<br/>Abruf aus Rahmenvertrag Nr.'||v_docno||'<br/>Zeitraum: '||v_begin||' bis '||v_end||'<br/>Vereinbarter Rahmen: '||v_frameqty||'<br/>Nach diesem Abruf verbleibende Menge: '||v_remains;
              else
              v_return:='<br/>Call from frame contract no.'||v_docno||'<br/>Period: '||v_begin||' bis '||v_end||'<br/>Agreed framework: '||v_frameqty||'<br/>Quantity left after this calling: '||v_remains;
              end if;
            end if;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION zssi_getpartialdeliverytext(p_orderline_id character varying, p_language character varying, p_language2 character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): 
***************************************************************************************************************************************************

*****************************************************/
DECLARE
v_return character varying:='';
v_qtydel numeric;
v_qtyorder numeric;
v_puomid varchar;
v_p2uomid varchar;
v_qtyinvoiced numeric;
v_invoicedamt numeric;


BEGIN
      select ol.quantityorder,ol.c_uom_id,(select c_uom_id from m_product_uom where m_product_uom_id=ol.m_product_uom_id),ol.qtydelivered,ol.qtyinvoiced,ol.invoicedamt 
                   into v_qtyorder,v_puomid,v_p2uomid,v_qtydel,v_qtyinvoiced, v_invoicedamt from c_orderline ol,c_order o where o.c_order_id=ol.c_order_id 
                   and ol.c_orderline_id=p_orderline_id  and o.c_doctype_id!='EE19ABBDB5A94C519DAB11003320FC8E'; -- not on Dropships
      if coalesce(v_qtydel,0)>0 then
            -- Is a 2nd UOM?
            if v_p2uomid is not null and coalesce(v_qtyorder,0)>0 then
                    v_qtydel:=C_Uom_Convert(v_qtydel,v_puomid,v_p2uomid, 'Y');
            end if;
            v_return:='<br/>'||zssi_getText('zssiDeliveryExists',p_language) || case when p_language2!=p_language then '/'||zssi_getText('zssiDeliveryExists',p_language2) else '' end ||': '||v_qtydel;
      end if;
      if coalesce(v_qtyinvoiced,0)>0 then
            if v_p2uomid is not null and coalesce(v_qtyorder,0)>0 then
                    v_qtyinvoiced:=C_Uom_Convert(v_qtyinvoiced,v_puomid,v_p2uomid, 'Y');
            end if;
            v_return:= v_return||'<br/>'||zssi_getText('zssiInvoiceExists',p_language) || case when p_language2!=p_language then '/'||zssi_getText('zssiInvoiceExists',p_language2) else '' end ||': '||zssi_strNumber(v_qtyinvoiced,p_language);
            v_return:= v_return||'<br/>'||zssi_getText('zssiInvoiceAmount',p_language) || case when p_language2!=p_language then '/'||zssi_getText('zssiInvoiceAmount',p_language2) else '' end ||': '|| zssi_strNumber(v_invoicedamt,p_language);
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zspr_getcustomstext(p_product_id character varying, p_language character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 Stefan Zimmermann All Rights Reserved.
Contributor(s): 
***************************************************************************************************************************************************

*****************************************************/
DECLARE
v_return character varying:='';
v_ctn varchar;
v_ctr varchar;
BEGIN
     --select p.cusomstarifno, coalesce(t.name,c.name) into v_ctn,v_ctr  from m_product p  left join c_country c on c.c_country_id=p.c_country_id 
     --                                                                   left join c_country_trl t on t.c_country_id=c.c_country_id and t.ad_language= p_language
     --                                                                   where p.m_product_id=p_product_id;
     select p.cusomstarifno, c.countrycode into v_ctn,v_ctr  from m_product p  left join c_country c on c.c_country_id=p.c_country_id 
                                                             where p.m_product_id=p_product_id;                                                                        
     if v_ctn is not null then
        v_return:=zssi_getElementTextByColumname('Cusomstarifno',p_language)||': '||v_ctn;
     end if;
     if v_ctr is not null then
        if v_return!='' then v_return:=v_return||' / '; end if;
        v_return:=v_return||zssi_getElementTextByColumname('origincountry',p_language)||': '||v_ctr;
     end if;
     return v_return;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;  



CREATE OR REPLACE FUNCTION zspr_getserialnumbersfrominout(p_inoutline_id character varying,p_language character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying:='';
v_posttext character varying:=' ';
v_posttext2 character varying:=' ';
v_pretext character varying;
v_pretext2 character varying;
v_orderline varchar;
v_iolines varchar;
v_cur RECORD;
BEGIN
      select ad_message_get2('zssi_serialnumbers', p_language) into v_pretext;
      select zssi_getElementTextByColumname('lotnumber/s',p_language) into v_pretext2;
      -- select zssi_getElementTextByColumname('lotnumber',p_language) into v_pretext2;
      select c_orderline_id into v_orderline from m_inoutline where m_inoutline_id=p_inoutline_id;
      if v_orderline is null then
        v_iolines:=p_inoutline_id;
      else
        select string_agg(m_inoutline_id,',') into v_iolines from m_inoutline where c_orderline_id=v_orderline;
      end if;
      for v_cur in (select serialnumber,lotnumber,quantity from snr_minoutline where m_inoutline_id = ANY(string_to_array(v_iolines,',')))
      LOOP
        if v_posttext!=' ' then
           v_posttext:=v_posttext||', ';
        end if;

        v_posttext:=v_posttext||coalesce(v_cur.serialnumber,' ');

        if v_posttext2!=' ' then
           v_posttext2:=v_posttext2||'; ';
        end if;

        v_posttext2:=v_posttext2||coalesce(v_cur.lotnumber,' ')||' '||zssi_getElementTextByColumname('Amountp',p_language)||': '||coalesce(v_cur.quantity,1);

      END LOOP;

      if v_cur.serialnumber is not null and v_cur.lotnumber is not null then
        v_return:=v_pretext||v_posttext||'<br/>'||v_pretext2||': '||v_posttext2;
      elsif v_cur.serialnumber is not null then
        v_return:=v_pretext||v_posttext;
      elsif v_cur.lotnumber is not null then
        v_return:=v_pretext2||': '||v_posttext2;
      end if; 
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION zssi_getlocationuid(p_location_id character varying,p_delilocation_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
BEGIN
      if p_delilocation_id is not null then
        select uidnumber into v_return from c_bpartner_location where c_bpartner_location_id=p_delilocation_id;
      else
        select uidnumber into v_return from c_bpartner_location where c_bpartner_location_id=p_location_id;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION zssi_getlocationcountrycode(p_location_id character varying, lang character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_country_id character varying;
BEGIN
      select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_location_id;
      select c_country_id into v_country_id from c_location where c_location_id=v_location_id;
      select name into v_return from c_country_trl where c_country_id=v_country_id and ad_language=lang;
      if v_return is null then
          select countrycode into v_return from c_country where c_country_id=v_country_id;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getlocationcountrycode(character varying, character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getlocationpartner(p_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
BEGIN
      select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_location_id;
      select deviant_bp_name into v_return from c_bpartner_location where c_location_id=v_location_id;
     
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getlocationline1');
CREATE OR REPLACE FUNCTION zssi_getlocationline1(p_bpartner_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Robert Schardt.
***************************************************************************************************************************************************



DEPRECATED - Used in OLD Reports, 05/2019 SZ
*****************************************************/
DECLARE
v_return character varying;
v_name varchar;
v_location_id character varying;
BEGIN
      select c_bpartner_location.c_location_id ,coalesce(c_bpartner_location.deviant_bp_name,c_bpartner.name) into v_location_id,v_name from c_bpartner_location,c_bpartner 
        where c_bpartner_location.c_bpartner_id=c_bpartner.c_bpartner_id and c_bpartner_location.c_bpartner_location_id=p_bpartner_location_id;

      select address2 into v_return from c_location where c_location_id=v_location_id;
      if v_return is null then
        return v_name;
      else
        select address1 into v_return from c_location where c_location_id=v_location_id;
      end if;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getlocationline1(character varying) OWNER TO tad;


select zsse_dropfunction('zssi_getlocationline2');
CREATE OR REPLACE FUNCTION zssi_getlocationline2(p_bpartner_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Robert Schardt.
***************************************************************************************************************************************************



DEPRECATED - Used in OLD Reports, 05/2019 SZ
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
BEGIN
      select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_bpartner_location_id;
      select address2 into v_return from c_location where c_location_id=v_location_id;
      if v_return is null then
        select address1 into v_return from c_location where c_location_id=v_location_id;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getlocationline2(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getlocationpostal(p_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************



DEPRECATED - Used in OLD Reports, 05/2019 SZ
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
BEGIN
      select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_location_id;
      select postal into v_return from c_location where c_location_id=v_location_id;
     
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getlocationpostal(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getpostalfromwarehouse(p_warehouse_id character varying,p_onlywhendiffersfromorg  character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************



DEPRECATED - Used in OLD Reports, 05/2019 SZ
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_orgid  character varying;
v_compare1 character varying;
v_compare2  character varying;
BEGIN
      select c_location_id,ad_org_id into v_location_id,v_orgid from m_warehouse where m_warehouse_id=p_warehouse_id;
      select postal into v_return from c_location where c_location_id=v_location_id;
      if coalesce(p_onlywhendiffersfromorg,'N')='Y' then
         select address1 into v_compare1 from c_location where c_location_id=(select c_location_id from ad_orginfo where ad_org_id=v_orgid);
         select address1 into v_compare2  from c_location where c_location_id=v_location_id;
         if coalesce(v_compare1,'x')=coalesce(v_compare2,'y') then
            v_return:=null;
         end if;
      end if;
     
RETURN v_return;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;


select zsse_dropfunction('zssi_getlocationpart');
CREATE OR REPLACE FUNCTION zssi_getlocationpart(p_location_id character varying,p_part numeric,v_lang varchar) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_name varchar;
v_country varchar;
v_part varchar;
v_adresspart varchar;
v_region varchar;
v_indicator numeric;
v_cname varchar;
BEGIN
    
    select c_country_id,c_region_id into v_country,v_region from c_location where c_location_id=p_location_id;
    select count(*) into v_indicator from c_country where c_country_id=v_country and
        (adressformatpart1 is not null or
        adressformatpart2 is not null or
        adressformatpart3 is not null or
        adressformatpart4 is not null);
    if p_part=1 then
        select adressformatpart1 into v_part from c_country where c_country_id=v_country;
        if v_indicator=0 then
            v_part:='@L1@';
        end if;
    end if;
    if p_part=2 then
        select adressformatpart2 into v_part from c_country where c_country_id=v_country;
        if v_indicator=0 then
            v_part:='@L2@';
        end if;
    end if;
    if p_part=3 then
        select adressformatpart3 into v_part from c_country where c_country_id=v_country;
        if v_indicator=0 then
            v_part:='@PC@@CI@';
        end if;
    end if;
    if p_part=4 then
        select adressformatpart4 into v_part from c_country where c_country_id=v_country;
        if v_indicator=0 then
            v_part:='@C@';
        end if;
    end if;
    v_part:=replace(v_part,'|',chr(10));
    if instr(v_part,'@L1@')>0 then
        select replace(address1,'|',chr(10)) into v_adresspart from c_location where c_location_id=p_location_id;
        v_part:=replace(v_part,'@L1@',coalesce(v_adresspart,''));
    end if;
    if instr(v_part,'@L2@')>0 then
        select replace(address2,'|',chr(10)) into v_adresspart from c_location where c_location_id=p_location_id;
        v_part:=replace(v_part,'@L2@',coalesce(v_adresspart,''));
    end if;
    if instr(v_part,'@PC@')>0 then
        select replace(postal,'|',chr(10)) into v_adresspart from c_location where c_location_id=p_location_id;
        v_part:=replace(v_part,'@PC@',coalesce(v_adresspart||' ',''));
    end if;
    if instr(v_part,'@CI@')>0 then
        select replace(city,'|',chr(10)) into v_adresspart from c_location where c_location_id=p_location_id;
        v_part:=replace(v_part,'@CI@',coalesce(v_adresspart,''));
    end if;
    if instr(v_part,'@C@')>0 then
      select t.name into v_adresspart from c_country c,c_country_trl t where c.c_country_id=t.c_country_id and  c.c_country_id=v_country and t.ad_language=c.ad_language;
      if v_adresspart is null then
        select name into v_adresspart from c_country_trl where c_country_id=v_country and ad_language=v_lang;
      end if;
      if v_adresspart is null then
          select name into v_adresspart from c_country where c_country_id=v_country;
      end if;
      v_part:=replace(v_part,'@C@',coalesce(v_adresspart,''));
    end if;
    if instr(v_part,'@R@')>0 then
        select name into v_adresspart from c_region where c_region_id=v_region;
        v_part:=replace(v_part,'@R@',coalesce(v_adresspart,''));
    end if;    
RETURN  v_part;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getlocationline1_new');
CREATE OR REPLACE FUNCTION zssi_getlocationline1_new(p_bpartner_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_name varchar;
v_location_id character varying;
BEGIN
    select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_bpartner_location_id;
    if v_location_id is null then
        v_location_id:=p_bpartner_location_id;
    end if;
    v_return:=zssi_getlocationpart(v_location_id,1,null);
    --select replace(address1,'|',chr(10)) into v_return from c_location where c_location_id=v_location_id;
RETURN  v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getlocationline2_new');
CREATE OR REPLACE FUNCTION zssi_getlocationline2_new(p_bpartner_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
BEGIN
    select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_bpartner_location_id;
    if v_location_id is null then
        v_location_id:=p_bpartner_location_id;
    end if;
    v_return:=zssi_getlocationpart(v_location_id,2,null);
    --select replace(address2,'|',chr(10)) into v_return from c_location where c_location_id=v_location_id;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_getlocationcity(p_location_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
BEGIN
    select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_location_id;
    if v_location_id is null then
        v_location_id:=p_location_id;
    end if;
    
    --select coalesce(postal||' ','')||replace(city,'|',chr(10)) into v_return from c_location where c_location_id=v_location_id;
    v_return:=zssi_getlocationpart(v_location_id,3,null); 
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION zssi_getlocationcountry(p_location_id character varying, lang character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_country_id character varying;
BEGIN
    select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_location_id;
    if v_location_id is null then
        v_location_id:=p_location_id;
    end if;
    v_return:=zssi_getlocationpart(v_location_id,4,lang); 
    --  select c_country_id into v_country_id from c_location where c_location_id=v_location_id;
    --  select name into v_return from c_country_trl where c_country_id=v_country_id and ad_language=lang;
    --  if v_return is null then
    --      select name into v_return from c_country where c_country_id=v_country_id;
    --  end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION zssi_getlocline1fromwarehouse(p_warehouse_id character varying,p_onlywhendiffersfromorg  character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_orgid  character varying;
v_compare1 character varying;
v_compare2  character varying;
BEGIN
      select c_location_id,ad_org_id into v_location_id,v_orgid from m_warehouse where m_warehouse_id=p_warehouse_id;
      select address1 into v_return from c_location where c_location_id=v_location_id;
      if coalesce(p_onlywhendiffersfromorg,'N')='Y' then
         select address1 into v_compare1 from c_location where c_location_id=(select c_location_id from ad_orginfo where ad_org_id=v_orgid);
         select address1 into v_compare2  from c_location where c_location_id=v_location_id;
         if coalesce(v_compare1,'x')=coalesce(v_compare2,'y') then
            v_return:=null;
         end if;
      end if;
      if v_return is not null then
        v_return:=zssi_getlocationline1_new(v_location_id);
      end if;
RETURN v_return;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;



CREATE OR REPLACE FUNCTION zssi_getlocline2fromwarehouse(p_warehouse_id character varying,p_onlywhendiffersfromorg  character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_orgid  character varying;
v_compare1 character varying;
v_compare2  character varying;
BEGIN
      select c_location_id,ad_org_id into v_location_id,v_orgid from m_warehouse where m_warehouse_id=p_warehouse_id;
      select address2 into v_return from c_location where c_location_id=v_location_id;
      if coalesce(p_onlywhendiffersfromorg,'N')='Y' then
         select address1 into v_compare1 from c_location where c_location_id=(select c_location_id from ad_orginfo where ad_org_id=v_orgid);
         select address1 into v_compare2  from c_location where c_location_id=v_location_id;
         if coalesce(v_compare1,'x')=coalesce(v_compare2,'y') then
            v_return:=null;
         end if;
      end if;
      if v_return is not null then
        v_return:=zssi_getlocationline2_new(v_location_id);
      end if;
RETURN v_return;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;

CREATE OR REPLACE FUNCTION zssi_getcityfromwarehouse(p_warehouse_id character varying,p_onlywhendiffersfromorg  character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_orgid  character varying;
v_compare1 character varying;
v_compare2  character varying;
BEGIN
      select c_location_id,ad_org_id into v_location_id,v_orgid from m_warehouse where m_warehouse_id=p_warehouse_id;
      select city into v_return from c_location where c_location_id=v_location_id;
      if coalesce(p_onlywhendiffersfromorg,'N')='Y' then
         select address1 into v_compare1 from c_location where c_location_id=(select c_location_id from ad_orginfo where ad_org_id=v_orgid);
         select address1 into v_compare2  from c_location where c_location_id=v_location_id;
         if coalesce(v_compare1,'x')=coalesce(v_compare2,'y') then
            v_return:=null;
         end if;
      end if;
      if v_return is not null then
        v_return:=zssi_getlocationcity(v_location_id);
      end if;
RETURN v_return;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;

CREATE OR REPLACE FUNCTION zssi_getcountryfromwarehouse(p_warehouse_id character varying, lang character varying,p_onlywhendiffersfromorg  character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_country_id character varying;
v_orgid  character varying;
v_compare1 character varying;
v_compare2  character varying;
BEGIN
      select c_location_id,ad_org_id into v_location_id,v_orgid from m_warehouse where m_warehouse_id=p_warehouse_id;
      select c_country_id into v_country_id from c_location where c_location_id=v_location_id;
      select name into v_return from c_country_trl where c_country_id=v_country_id and ad_language=lang;
      if v_return is null then
          select name into v_return from c_country where c_country_id=v_country_id;
      end if;
      if coalesce(p_onlywhendiffersfromorg,'N')='Y' then
         select address1 into v_compare1 from c_location where c_location_id=(select c_location_id from ad_orginfo where ad_org_id=v_orgid);
         select address1 into v_compare2  from c_location where c_location_id=v_location_id;
         if coalesce(v_compare1,'x')=coalesce(v_compare2,'y') then
            v_return:=null;
         end if;
      end if;
      if v_return is not null then
        v_return:=zssi_getlocationcountry(v_location_id,lang);
      end if;
RETURN v_return;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;






CREATE OR REPLACE FUNCTION zssi_getpaymentterm(p_paymentterm_id character varying, lang character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
-- Translated docnote -> TRL description 
      select coalesce(coalesce(trl.documentnote, c.documentnote),trl.description) into v_return from c_paymentterm_trl trl, c_paymentterm c where trl.c_paymentterm_id=c.c_paymentterm_id and trl.c_paymentterm_id=p_paymentterm_id and ad_language=lang;
-- DocNote --> Description --> Name
      if v_return is null then
         -- select coalesce(coalesce(documentnote,description),name) into v_return from c_paymentterm where c_paymentterm_id=p_paymentterm_id;
      end if;
RETURN zssi_2HTML(v_return);
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION zssi_getlocationeori(p_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select eoriidentification into v_return from c_bpartner_location where c_bpartner_location_id=p_location_id;
     
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getlocationeori(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getincoterms(p_incoterms_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select description into v_return from c_incoterms where c_incoterms_id=p_incoterms_id;    
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getincoterms(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getshipper(p_shipper_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select name into v_return from m_shipper where m_shipper_id=p_shipper_id;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getshipper(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getdeliverymethod(p_deliveryviarule character varying, lang character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_ref_list_id character varying;
BEGIN
      v_return:=zssi_getListRefText('152', p_deliveryviarule,lang);
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getdeliverymethod(p_deliveryviarule character varying, lang character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getpaytermdiscdesc(v_discount_id character varying, lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_temp numeric;
BEGIN
    select netdays into v_temp from zsfi_discount where zsfi_discount_id=v_discount_id;
        if v_temp > 999 then
            if lang='de_DE' then
                        select ('Zahlbarer Betrag') into v_return;
                end if;
                if v_return is null then
                        select ('For payment') into v_return;
                end if;
        end if;
        if v_temp < 1000 then
                if lang='de_DE' then
                        select ('Zahlb. Betrag innerh. von ' || to_char(netdays) || ' Tagen') into v_return from zsfi_discount where zsfi_discount_id=v_discount_id;
                end if;
                if v_return is null then
                        select ('For payment within ' || to_char(netdays) || ' days') into v_return from zsfi_discount where zsfi_discount_id=v_discount_id;
                end if;
        end if;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getpaytermdiscdesc(character varying, character varying) OWNER TO tad;



CREATE OR REPLACE FUNCTION zssi_getpaytermdisc(v_discount_id character varying) RETURNS numeric 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return numeric;
BEGIN
      select percentage into v_return from zsfi_discount where zsfi_discount_id=v_discount_id;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getpaytermdisc(character varying) OWNER TO tad;


CREATE OR REPLACE FUNCTION zssi_getpaymethod(p_paymentrule character varying, p_deliveryrule character varying, lang character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_temp1 character varying;
v_temp2 character varying;
v_ref_list_id character varying;
BEGIN
          select ad_ref_list_id into v_ref_list_id from ad_ref_list where value=p_paymentrule and ad_reference_id='195';
      if (v_ref_list_id is null) then
            select ad_ref_listinstance_id into v_ref_list_id from ad_ref_listinstance where value=p_paymentrule and ad_reference_id='195';
            select name into v_temp1 from ad_ref_listinstance_trl where ad_ref_listinstance_id=v_ref_list_id and ad_language=lang;
      else  
          select name into v_temp1 from ad_ref_list_trl where ad_ref_list_id=v_ref_list_id and ad_language=lang;
      end if;
      if v_temp1 is null then
          select name into v_temp1 from ad_ref_list where value=p_paymentrule and ad_reference_id='195';
      end if;
          if p_deliveryrule = 'R' then
              select ad_ref_list_id into v_ref_list_id from ad_ref_list where value=p_deliveryrule and ad_reference_id='151';      
              select name into v_temp2 from ad_ref_list_trl where ad_ref_list_id=v_ref_list_id and ad_language=lang;
          if v_temp2 is null then
              select name into v_temp2 from ad_ref_list where value=p_deliveryrule and ad_reference_id='151';
          end if;
                  select (v_temp1 || ' / ' || v_temp2) into v_return;
          else 
          select v_temp1 into v_return;   
          end if; 
RETURN zssi_2HTML(v_return);
END; $_$ 
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION zssi_printconf_trg() RETURNS trigger 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - On Insert. Only one user on employees and undefined partner
*****************************************************/
DECLARE 
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from zspr_printinfo where zspr_printinfo.ad_org_id=new.ad_org_id;
  if v_count > 0  then
      RAISE EXCEPTION '%', '@zssi_OnlyOneDS@';
  end if;
  RETURN NEW;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_printconf_trg() OWNER TO tad;

DROP TRIGGER zssi_printconf_trg ON zspr_printinfo;
CREATE TRIGGER zssi_printconf_trg
  BEFORE INSERT
  ON zspr_printinfo
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_printconf_trg();

CREATE or replace FUNCTION zssi_gettax(p_tax_id character varying,lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select taxhint into v_return from c_tax_trl where c_tax_id=p_tax_id and ad_language=lang;
      if v_return is null then 
          select taxhint into v_return from c_tax where c_tax_id=p_tax_id;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_gettax(v_tax_id character varying,lang character varying) OWNER TO tad;

CREATE or replace FUNCTION zssi_gettaxdescription(p_tax_id character varying,lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      select description into v_return from c_tax_trl where c_tax_id=p_tax_id and ad_language=lang;
      if v_return is null then 
          select description into v_return from c_tax where c_tax_id=p_tax_id;
      end if;
RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_gettaxdescription(v_tax_id character varying,lang character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getlocationcountryid(p_location_id character varying, lang character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
BEGIN
      select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_location_id;
      select c_country_id into v_return from c_location where c_location_id=v_location_id;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getlocationcountryid(character varying, character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getexportterm(p_location_id character varying, p_doctype_id character varying, lang character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_location_id character varying;
v_country_id character varying;
v_tradearea_id character varying;
v_isordertext character varying;
v_isshipmentext character varying;
v_isinvoicetext character varying;
BEGIN
      select c_location_id into v_location_id from c_bpartner_location where c_bpartner_location_id=p_location_id;
      select c_country_id into v_country_id from c_location where c_location_id=v_location_id;
          select zssi_tradearea_id into v_tradearea_id from zssi_tradearea_country where c_country_id=v_country_id;
          select isordertext into v_isordertext from zssi_tradearea where zssi_tradearea_id=v_tradearea_id;
          select isshipmentext into v_isshipmentext from zssi_tradearea where zssi_tradearea_id=v_tradearea_id;
          select isinvoicetext into v_isinvoicetext from zssi_tradearea where zssi_tradearea_id=v_tradearea_id;
          if (p_doctype_id='5D5792C53FBA46E2988653B6DC9FE5B4' and v_isordertext='Y') or (p_doctype_id='F7C859920B904536A9CCF3A84729AA52' and v_isshipmentext='Y') or (p_doctype_id='45A90145C74C44ECB48AC772B05487CA' and v_isinvoicetext='Y') then
                select text into v_return from zssi_tradearea_trl where zssi_tradearea_id=v_tradearea_id and ad_language=lang;
                if v_return is null then
                        select text into v_return from zssi_tradearea where zssi_tradearea_id=v_tradearea_id;
                end if;
          end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getexportterm(character varying, character varying, character varying) OWNER TO tad;


/*-------------------------------------------------------------------------------------------------------------------------------------------------


Implementation of Textmodules




-------------------------------------------------------------------------------------------------------------------------------------------------------------*/


CREATE OR REPLACE FUNCTION zspr_getdropshipmentalterttext(p_zse_shoporderstatus_id character varying) RETURNS VARCHAR
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************

Print Open Shipments only on Regular documents (Not Vendor or Customer return) 

*****************************************************/
DECLARE
v_cur record;
v_textval varchar:='';
v_fullname varchar;
v_logistic varchar;
v_tracking varchar;
v_refno varchar;
v_trackingurl varchar;
v_order varchar;
-- c_doctype_id='C993D1D33D494B44BA8842110876D417' : MM shipment indirect
BEGIN
  
  select u.name,soo.poreference,o.c_order_id into v_fullname,v_refno,v_order from ad_user u,c_order o, c_order soo,zse_shoporderstatus z
         where u.ad_user_id=soo.ad_user_id and soo.c_order_id=o.orderselfjoin
         and o.c_order_id=z.c_order_id and z.zse_shoporderstatus_id=p_zse_shoporderstatus_id;
  select trackingno,shipper into v_tracking,v_logistic from  zse_shoporderstatus where zse_shoporderstatus_id=p_zse_shoporderstatus_id;
  select description into v_trackingurl from m_shipper where name=v_logistic;
  
  for v_cur in (select * from zssi_textmodule where c_doctype_id='C993D1D33D494B44BA8842110876D417' and islower='N' order by position)
  LOOP
    v_textval:=v_textval||replace(replace(replace(replace(replace(v_cur.text,'@FULLNAME@',coalesce(v_fullname,'n/a')),'@SHIPPER@',coalesce(v_logistic,'n/a')),'@TRACKINGURL@',coalesce(v_trackingurl,'n/a')),'@TRACKINGNO@',coalesce(v_tracking,'n/a')),'@REFERENCENO@',coalesce(v_refno,'n/a'))||'<br/>';
  END LOOP;
  for v_cur in (select c_orderline.c_orderline_id,c_orderline.m_product_id,c_orderline.qtydelivered,c_orderline.ad_org_id from c_orderline,m_product 
                where m_product.m_product_id=c_orderline.m_product_id and m_product.isfreightproduct='N' and c_order_id=v_order)
  LOOP
    v_textval:=v_textval||v_cur.qtydelivered||'-'||zspr_getproductprintouttext(v_cur.c_orderline_id, 'de_DE', null)||'<br/>';
  END LOOP;
  for v_cur in (select * from zssi_textmodule where c_doctype_id='C993D1D33D494B44BA8842110876D417' and islower='Y' order by position)
  LOOP
    v_textval:=v_textval||replace(replace(replace(replace(replace(v_cur.text,'@FULLNAME@',coalesce(v_fullname,'n/a')),'@SHIPPER@',coalesce(v_logistic,'n/a')),'@TRACKINGURL@',coalesce(v_trackingurl,'n/a')),'@TRACKINGNO@',coalesce(v_tracking,'n/a')),'@REFERENCENO@',coalesce(v_refno,'n/a'))||'<br/>';
  END LOOP;
  return zssi_2HTML(v_textval);      
END;
$_$ LANGUAGE plpgsql VOLATILE;



CREATE OR REPLACE FUNCTION zspr_getshipmentalterttext(p_inout_id character varying) RETURNS VARCHAR
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************

Print Open Shipments only on Regular documents (Not Vendor or Customer return) 

*****************************************************/
DECLARE
v_cur record;
v_textval varchar:='';
v_fullname varchar;
v_logistic varchar;
v_tracking varchar;
v_refno varchar;
v_trackingurl varchar;
-- c_doctype_id='C993D1D33D494B44BA8842110876D417' : MM shipment indirect
BEGIN
  select name into v_fullname from ad_user where ad_user_id=(select ad_user_id from m_inout where m_inout_id=p_inout_id);
  select name,description into v_logistic,v_trackingurl from m_shipper where m_shipper_id=(select m_shipper_id from m_inout where m_inout_id=p_inout_id);
  select trackingno,poreference into v_tracking,v_refno from m_inout where m_inout_id=p_inout_id;
  v_trackingurl:=replace(v_trackingurl,'@TRACKINGNO@',v_tracking);
  for v_cur in (select * from zssi_textmodule where c_doctype_id='C993D1D33D494B44BA8842110876D417' and islower='N' order by position)
  LOOP
    v_textval:=v_textval||replace(replace(replace(replace(replace(v_cur.text,'@FULLNAME@',coalesce(v_fullname,'n/a')),'@SHIPPER@',coalesce(v_logistic,'n/a')),'@TRACKINGURL@',coalesce(v_trackingurl,'n/a')),'@TRACKINGNO@',coalesce(v_tracking,'n/a')),'@REFERENCENO@',coalesce(v_refno,'n/a'))||'<br/>';
  END LOOP;
  for v_cur in (select * from m_inoutline where m_inout_id=p_inout_id)
  LOOP
    v_textval:=v_textval||v_cur.movementqty||' - '||zspr_getproductprintouttext(v_cur.m_inoutline_id, 'de_DE', null)||' - ';
  END LOOP;
  for v_cur in (select * from zssi_textmodule where c_doctype_id='C993D1D33D494B44BA8842110876D417' and islower='Y' order by position)
  LOOP
    v_textval:=v_textval||replace(replace(replace(replace(replace(v_cur.text,'@FULLNAME@',coalesce(v_fullname,'n/a')),'@SHIPPER@',coalesce(v_logistic,'n/a')),'@TRACKINGURL@',coalesce(v_trackingurl,'n/a')),'@TRACKINGNO@',coalesce(v_tracking,'n/a')),'@REFERENCENO@',coalesce(v_refno,'n/a'))||'<br/>';
  END LOOP;
  return zssi_2HTML(v_textval);      
END;
$_$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION zspr_getorderlinesfromshipment(p_inout_id character varying) RETURNS SETOF c_orderline 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************

Print Open Shipments only on Regular documents (Not Vendor or Customer return) 

*****************************************************/
DECLARE
ret_orderline c_orderline%rowtype;
v_inoutline m_inoutline%rowtype;
v_order_id character varying;
v_org_id character varying;
v_movementtype character varying;
BEGIN
        select ad_org_id,movementtype into v_org_id,v_movementtype from m_inout where m_inout.m_inout_id=p_inout_id;
        IF ((select printopenshipments from zspr_printinfo where ad_org_id=v_org_id) = 'Y') and v_movementtype in ('V+','C-') then
                FOR v_inoutline in (select * from m_inoutline where m_inoutline.m_inout_id = p_inout_id)
                LOOP
                        select c_order_id into v_order_id from c_orderline where c_orderline_id=v_inoutline.c_orderline_id;
                        FOR ret_orderline in (select * from c_orderline where c_orderline.c_order_id = v_order_id)
                        LOOP
                                IF (ret_orderline.qtyordered - ret_orderline.qtydelivered != 0) and ret_orderline.c_orderline_id not in (select c_orderline_id from m_inoutline where m_inoutline.m_inout_id=p_inout_id) THEN
                                        RETURN NEXT ret_orderline;
                                END IF;
                        END LOOP;
                END LOOP;
        END IF;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
  
  
CREATE OR REPLACE FUNCTION zspr_getlocatorsfromshipline(p_inout_id varchar,p_orderline_id character varying) RETURNS varchar  LANGUAGE plpgsql AS $_$ 
DECLARE
    retval varchar;
    v_org  varchar;
BEGIN
    select ad_org_id into v_org from m_inout where m_inout_id=p_inout_id;
    if (select printlocatoronshipment from zspr_printinfo where ad_org_id in ('0',v_org) order by ad_org_id desc limit 1)='N' then    
        return '';
    else
       select string_agg(a.value||'('||a.movementqty||')',chr(13)) into retval from 
        ( select l.value,m.movementqty from m_locator l,m_inoutline m where m.m_inout_id=p_inout_id and m.c_orderline_id=p_orderline_id and
           m.m_locator_id=l.m_locator_id order by l.priorityno,l.x,l.y,l.z
        ) a;
       return retval;
    end if;
END ; $_$;


CREATE OR REPLACE FUNCTION zssi_textmodulemod_trg() RETURNS trigger LANGUAGE plpgsql AS $_$ 
BEGIN
    IF (COALESCE(OLD.text,'') != COALESCE(NEW.text,'')) THEN
        new.ismodified='Y';
    END IF;
   return new;
END ; $_$;


drop trigger zssi_order_textmodule_trg on zssi_order_textmodule;

CREATE TRIGGER zssi_order_textmodule_trg
  BEFORE UPDATE
  ON zssi_order_textmodule
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_textmodulemod_trg();


drop trigger zssi_invoice_textmodule_trg on zssi_invoice_textmodule;

CREATE TRIGGER zssi_invoice_textmodule_trg
  BEFORE UPDATE
  ON zssi_invoice_textmodule
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_textmodulemod_trg();

drop trigger zssi_minout_textmodule_trg on zssi_minout_textmodule;

CREATE TRIGGER zssi_minout_textmodule_trg
  BEFORE UPDATE
  ON zssi_minout_textmodule
  FOR EACH ROW
  EXECUTE PROCEDURE zssi_textmodulemod_trg();



CREATE or replace FUNCTION zssi_getTextModuleTranslated(v_textmoduleid character varying,lang character varying) RETURNS character varying
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
Get Text Modules from Database - Get direct and translated
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
v_otext    character varying;

BEGIN
  select text into v_otext from zssi_textmodule where zssi_textmodule_id=v_textmoduleid;
  select text into v_return from zssi_textmodule_trl where zssi_textmodule_id=v_textmoduleid and ad_language=lang;
  if v_return is null then
    if v_otext is not null then
     v_return:= v_otext;
    else
     v_return:= null;
    end if;
  end if;
  
RETURN coalesce(v_return,'');
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;


CREATE or replace FUNCTION zssi_getTextModuleFromDoc(v_record_id character varying,v_recordtype character varying, v_islower character varying,lang character varying) RETURNS character varying
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
Get Text Modules from Database - 
 Individual Textmodules on Orders, Invoices, M-inout
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying:='';
v_recordident    character varying;
v_table  character varying;
v_bottomtext character varying;
v_org varchar;
v_deli_loc varchar;
v_inv_loc varchar;
v_order varchar;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_cursor2 TYPE_Ref%TYPE;
v_cur2 RECORD;
v_docref character varying:='';
v_cusref character varying:='';
v_cusname character varying:='';
v_salman character varying:='';
v_docrefso character varying:='';
v_cusrefso character varying:='';
v_cusnameso character varying:='';
v_salmanso character varying:='';
v_table2 character varying;
v_tempp character varying;
BEGIN
  if v_recordtype='ORDER' then 
      v_table:='zssi_order_textmodule';
      v_table2:='c_order';
      v_recordident:='c_order_id';
  elsif v_recordtype='INVOICE' then 
     v_table:='zssi_invoice_textmodule'; 
     v_table2:='c_invoice';
     v_recordident:='c_invoice_id';
     -- Lieferadresse in Rechnung
     select o.ad_org_id,coalesce(coalesce(o.delivery_location_id,o.c_bpartner_location_id),i.c_bpartner_location_id),i.c_bpartner_location_id,o.c_order_id 
            into v_org,v_deli_loc,v_inv_loc,v_order 
            from c_invoice i,c_order o where o.c_order_id=i.c_order_id and i.c_invoice_id=v_record_id;
     if coalesce((select adddeliverylocation2invoice from zspr_printinfo where ad_org_id=v_org),'N')='Y' and v_islower='N' then
            if coalesce(v_deli_loc,'')!=coalesce(v_inv_loc,'') then
                select '<b>'||zssi_getElementTextByColumname('deliveryadress',lang)||': </b>'||coalesce(bl.deviant_bp_name||', ','')||
                        coalesce(l.address1||', ','')||coalesce(l.address2||', ','')||coalesce(coalesce(l.postal||' ','')||l.city||', ','')||coalesce(coalesce(cctrl.name,cc.name),'') 
                        into v_return
                from c_bpartner_location bl,c_location l 
                     left join c_country cc on l.c_country_id=cc.c_country_id
                     left join c_country_trl cctrl on  cctrl.c_country_id=cc.c_country_id and cctrl.ad_language=lang
                where l.c_location_id=bl.c_location_id and bl.c_bpartner_location_id=v_deli_loc;
            end if;
     end if;
  elsif v_recordtype='SHIPMENT' then 
      v_table:='zssi_minout_textmodule'; 
      v_table2:='m_inout';
      v_recordident:='m_inout_id';
  end if;
  if v_recordtype='ORDER' and v_islower='Y' then 
      select deliverynotes into v_bottomtext from c_order where c_order_id=v_record_id;
      if v_bottomtext is not null then
            if v_return!=''  then v_return:=v_return||E'\r\n'; end if;
            v_return:=v_return||v_bottomtext;
      end if;
  end if;
  OPEN v_cursor FOR EXECUTE 'select * from '||v_table||' where '||v_recordident||'='||chr(39)||v_record_id||chr(39)||' and islower='||chr(39)||v_islower||chr(39)||' order by line';
        LOOP
          FETCH v_cursor INTO v_cur;
          EXIT WHEN NOT FOUND;
          if v_return!='' then v_return:=v_return||E'\r\n'; end if;
          if v_cur.ismodified='Y' or  v_cur.zssi_textmodule_id is null then 
            v_return:=v_return||coalesce(v_cur.text,'');
          else
            v_return:=v_return||zssi_getTextModuleTranslated(v_cur.zssi_textmodule_id,lang);
          end if;
        END LOOP;
  CLOSE v_cursor;
            OPEN v_cursor2 FOR EXECUTE 'select * from ' ||v_table2||' where '||v_recordident||'='||chr(39)||v_record_id||chr(39);
            
            
                FETCH v_cursor2 into v_cur2;
                
              --  raise notice '%', (select coalesce(name,'') from c_bpartner where v_cur2.c_bpartner_id=c_bpartner_id)||'hi';
                
          -- Adding Replacementlogic #3779
            v_cusname:=coalesce((select coalesce(name,'') from ad_user where v_cur2.ad_user_id=ad_user_id),'');
            if(v_cur2.issotrx='N') then
            v_cusref:=COALESCE((select coalesce(Referenceno,(v_cur2.poreference)) from c_bpartner where v_cur2.c_bpartner_id=c_bpartner_id),'');
            else
            v_cusref:=(coalesce(v_cur2.poreference,''));
            end if;
            v_salman:=coalesce((select name from ad_user where v_cur2.salesrep_id=ad_user_id),'');   
            if(v_recordtype='INVOICE') then
            v_docref:=v_cur2.documentno;            
            elsif (v_recordtype='ORDER') then
            v_docref:=v_cur2.documentno; 
            else
            v_docref:=v_cur2.documentno;
            end if;
            if (v_cur2.c_doctype_id='EE19ABBDB5A94C519DAB11003320FC8E') then 
            
                v_salmanso:=(select coalesce(a.name,'') from ad_user a, c_order o where o.c_order_id=v_cur2.orderselfjoin and o.salesrep_id=a.ad_user_id);
                v_cusrefso:=(select coalesce(POREFERENCE,'') from c_order where c_order.c_order_id=v_cur2.orderselfjoin);
                v_docrefso:=(select documentno from c_order where c_order.c_order_id=v_cur2.orderselfjoin);
                v_cusnameso:=(select coalesce(a.name,'') from ad_user a, c_order o where o.c_order_id=v_cur2.orderselfjoin and o.ad_user_id=a.ad_user_id);
                --raise notice '%', coalesce(v_salman,'nüscht')||coalesce(v_cusref,'nüscht')||coalesce(v_cusname,'nüscht')||coalesce(v_docref,'nüscht');
            end if;
            v_return:=replace(v_return,'@cus_ref@',v_cusref);
            v_tempp:=replace(v_return,'@cus_nam@',v_cusname); 
            v_return:=replace(v_tempp,'@our_ref@',v_docref); 
            v_return:=replace(v_return,'@sal_nam@',v_salman); 
            v_return:=replace(v_return,'@dsso_cusref@',v_cusrefso);
            v_tempp:=replace(v_return,'@dsso_cusnam@',v_cusnameso); 
            v_return:=replace(v_tempp,'@dsso_ourref@',v_docrefso); 
            v_return:=replace(v_return,'@dsso_salnam@',v_salmanso);
            
          CLOSE v_cursor2;
RETURN coalesce(v_return,'');
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;

CREATE OR REPLACE FUNCTION zssi_getsubscriptionfrequence(p_order_id character varying, lang character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
v_invoicefrequence character varying;
BEGIN
      select invoicefrequence into v_invoicefrequence from c_order where c_order_id=p_order_id;
	  select zssi_getListRefText('F17BFE71276743BBB6105EE61D9FD666', v_invoicefrequence, lang) into v_return;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getsubscriptionfrequence(character varying, character varying) OWNER TO tad;


CREATE OR REPLACE FUNCTION zssi_getinoutrefs(p_order_id character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Getting all M_INOUTS from an order as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_inout m_inout%rowtype;
BEGIN

for v_inout in (select * from m_inout where m_inout.c_order_id = p_order_id)
loop
  v_return := v_return ||'<a href="#" onclick="submitCommandChangingName('''||v_inout.m_inout_id||''','||''''||'..//GoodsReceipt/Header_Edition.html'''||', '||'''inpmInoutId''); return false;">'||v_inout.documentno||'</a><br />';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getinoutrefs(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getminoutlink(p_inout_id character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Getting all M_INOUTS from an order as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_inout m_inout%rowtype;
BEGIN

for v_inout in (select * from m_inout where m_inout.m_inout_id = p_inout_id)
loop
  v_return := v_return ||'<a href="#" onclick="submitCommandChangingName('''||v_inout.m_inout_id||''','||''''||'..//GoodsReceipt/Header_Edition.html'''||', '||'''inpmInoutId''); return false;">'||v_inout.documentno||'</a><br />';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getminoutlink(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getinvoicelink(p_invoice_id character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseInvoice as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_invoice c_invoice%rowtype;
BEGIN
for v_invoice in (select * from c_invoice where c_invoice.c_invoice_id = p_invoice_id)
loop
  v_return := v_return ||'<a href="#" onclick="submitCommandChangingName('''||v_invoice.c_invoice_id||''','||''''||'..//PurchaseInvoice/Header_Relation.html'''||', '||'''inpcInvoiceId''); return false;">'||v_invoice.documentno||'</a><br />';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getinvoicelink(character varying) OWNER TO tad;


CREATE OR REPLACE FUNCTION zssi_getorderlink(p_order_id character varying) RETURNS character varying 
AS $_$ 
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
v_order c_order%rowtype;
BEGIN
for v_order in (select * from c_order where c_order.c_order_id = p_order_id)
loop
  v_return := v_return ||'<a href="#" onclick="submitCommandChangingName('''||v_order.c_order_id||''','||''''||'..//PurchaseOrder/Header_Edition.html'''||', '||'''inpcOrderId''); return false;">'||v_order.documentno||'</a><br />';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_getorderlinelink(p_orderline_id character varying) RETURNS character varying 
AS $_$ 
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
v_docno varchar;
BEGIN
select documentno into v_docno from c_order where c_order.c_order_id = (select c_order_id from c_orderline where c_orderline_id=p_orderline_id);
v_return := v_return ||'<a class="LabelLink" href="#" onclick="submitCommandChangingName('''||p_orderline_id||''','||''''||'../SalesOrder/Lines_Edition.html'''||', '||'''inpcOrderlineId''); return false;">'||v_docno||'</a>';

RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_getptasklink(p_task_id character varying) RETURNS character varying 
AS $_$ 
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
v_docno varchar;
v_type varchar;
BEGIN
select pt.name,p.projectcategory into v_docno, v_type from c_projecttask pt,c_project p where  p.c_project_id=pt.c_project_id and pt.c_projecttask_id=p_task_id;
if v_type='PRO' then
  v_return := v_return ||'<a class="LabelLink" href="#" onclick="submitCommandChangingName('''||p_task_id||''','||''''||'../org.openbravo.zsoft.serprod.ProductionOrder/WorkSteps035860BB9D4F4D08878CED2F371D7201_Edition.html'''||', '||'''inpzssmWorkstepVId''); return false;">'||v_docno||'</a>';
else
   v_return := v_return ||'<a class="LabelLink" href="#" onclick="submitCommandChangingName('''||p_task_id||''','||''''||'../org.openbravo.zsoft.project.Projects/ProjectTask490_Edition.html'''||', '||'''inpcProjecttaskId''); return false;">'||v_docno||'</a>';
 end if;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_getinvoicelinkhesir(p_invoice_id character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseInvoice as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_invoice c_invoice%rowtype;
BEGIN
for v_invoice in (select * from c_invoice where c_invoice.c_invoice_id = p_invoice_id)
loop
  v_return := v_return ||'<b>'||v_invoice.poreference||'</b>';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getinvoicelinkhesir(character varying) OWNER TO tad;

CREATE or replace FUNCTION zss_genhtmllink(p_targetwindowurl character varying,p_id character varying,p_ltext character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  RETURN '<INPUT type="hidden" name="inpKeyName" value="inpcInvoiceId"><a href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||','||'document.frmMain.inpcInvoiceId'||','||chr(39)||p_id||chr(39)||', false, document.frmMain, '||chr(39)||'../'||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink">'||p_ltext||' </a>';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_getinvoicelinkhepir(p_invoice_id character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseInvoice as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_invoice c_invoice%rowtype;
BEGIN
for v_invoice in (select * from c_invoice where c_invoice.c_invoice_id = p_invoice_id)
loop
  v_return := v_return ||'<b>'||v_invoice.poreference||'</b>';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getinvoicelinkhepir(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getinvoicelinkhesid(p_invoice_id character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseInvoice as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_invoice c_invoice%rowtype;
BEGIN
for v_invoice in (select * from c_invoice where c_invoice.c_invoice_id = p_invoice_id)
loop
  v_return := v_return ||'<b>'||v_invoice.documentno||'</b>';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getinvoicelinkhesid(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getinvoicelinkhepid(p_invoice_id character varying) RETURNS character varying 
AS $_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers, Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseInvoice as Link
*****************************************************/
DECLARE
v_return character varying:='';
v_invoice c_invoice%rowtype;
BEGIN
for v_invoice in (select * from c_invoice where c_invoice.c_invoice_id = p_invoice_id)
loop
  v_return := v_return ||'<b>'||v_invoice.documentno||'</b>';
end loop;

RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getinvoicelinkhepid(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getuserfax(v_user character varying)
  RETURNS character varying AS
$BODY$
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
BEGIN
      select fax into v_return from ad_user where ad_user_id=v_user;
RETURN coalesce(v_return,'');
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getuserfax(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getdelaydesign(milestone numeric)
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

BEGIN
v_return := (SELECT CASE WHEN milestone is null THEN ''
	    WHEN milestone<=4 THEN '<span style="color:white;background-color:green; border-radius:25px;">ok</span>'
	    WHEN milestone<=9 THEN '<span style="border:1px; border-radius:25px; color:white;background-color:#faa61a;">&nbsp;i&nbsp;</span>'
	    ELSE '<span style="color:white;background-color:red; border-radius:25px;">&nbsp;x&nbsp;</span>'
       END);
  
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getdelaydesign(numeric) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getnodelaydesign(milestone numeric)
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

BEGIN
v_return := (SELECT CASE WHEN milestone is null THEN ''
	    WHEN milestone<=4 THEN 'ok'
	    WHEN milestone<=9 THEN '&nbsp;i&nbsp;'
	    ELSE '&nbsp;x&nbsp;'
       END);
  
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getnodelaydesign(numeric) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getoverviewdesign(p_status character varying, p_ref_id character varying)
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

BEGIN
v_return := (SELECT CASE 
	    WHEN p_status= '10' AND p_ref_id = 'BBFB55FDBAA64C0EB46F026460AE8285' THEN '<span style="color:white;background-color:green;border:2px solid; border-radius:25px;">'|| (SELECT zssi_getlistreftext(p_ref_id, p_status, 'de_DE')) ||'</span>'
	    WHEN p_status= 'as planned' AND p_ref_id = '7C374D10EA044BE3B252D6654A7AA5E1' THEN '<span style="color:white;background-color:green;border:2px solid; border-radius:25px;">'||(SELECT zssi_getlistreftext(p_ref_id , p_status, 'de_DE'))||'</span>'
	    WHEN p_status= 'in budget ' AND p_ref_id = '76CDE2B245D44726AE30457453FF622E' THEN '<span style="color:white;background-color:green;border:2px solid; border-radius:25px;">'||(SELECT zssi_getlistreftext(p_ref_id , p_status, 'de_DE'))||'</span>'
	    WHEN p_status=  '20' AND p_ref_id = 'BBFB55FDBAA64C0EB46F026460AE8285'  THEN '<span style="border:1px; border-radius:25px; color:white;background-color:#faa61a;border:2px solid; border-radius:25px;">'||(SELECT zssi_getlistreftext('BBFB55FDBAA64C0EB46F026460AE8285', p_status, 'de_DE')) ||'</span>'
	    WHEN p_status= 'resources' AND p_ref_id = '7C374D10EA044BE3B252D6654A7AA5E1' THEN '<span style="border:1px; border-radius:25px; color:white;background-color:#faa61a; border:2px solid;border-radius:25px;">'||(SELECT zssi_getlistreftext(p_ref_id , p_status, 'de_DE'))||'</span>'
	    WHEN p_status= 'costs' AND p_ref_id = '76CDE2B245D44726AE30457453FF622E' THEN '<span style="border:1px; border-radius:25px; color:white;background-color:#faa61a;border:2px solid; border-radius:25px;">'||(SELECT zssi_getlistreftext(p_ref_id , p_status, 'de_DE'))||'</span>'
	    WHEN p_status= '30' AND p_ref_id = 'BBFB55FDBAA64C0EB46F026460AE8285' THEN '<span style="color:white;background-color:red;border:2px solid; border-radius:25px;">'||(SELECT zssi_getlistreftext('BBFB55FDBAA64C0EB46F026460AE8285', p_status, 'de_DE')) ||'</span>'
	    WHEN p_status= 'crit. resources' AND p_ref_id = '7C374D10EA044BE3B252D6654A7AA5E1' THEN '<span style="color:white;background-color:red;border:2px solid; border-radius:25px;">'||(SELECT zssi_getlistreftext(p_ref_id , p_status, 'de_DE'))||'</span>'
	    WHEN p_status= 'crit. costs' AND p_ref_id = '76CDE2B245D44726AE30457453FF622E' THEN '<span style="color:white;background-color:red;border:2px solid; border-radius:25px;">'||(SELECT zssi_getlistreftext(p_ref_id , p_status, 'de_DE'))||'</span>'
	    ELSE p_status
       END);
  
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getoverviewdesign(character varying, character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_juwiorgshortcut(p_org_id character varying)
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
Juwi Specific Shortcuts
*****************************************************/
DECLARE
v_return character varying:='';

BEGIN
v_return := (SELECT CASE WHEN p_org_id is null THEN ''
	    WHEN p_org_id='AE3637495E9E4EBFA7E766FE9B97893A' THEN 'JMM'
	    WHEN p_org_id='0A42B068B99A48DB90ADA791D0E9F2D4' THEN 'ayeQ'
	    ELSE (select name from ad_org where p_org_id = ad_org_id)
       END);
  
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_juwiorgshortcut(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_docshortcut(p_document_id character varying)
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
Juwi Specific Shortcuts
*****************************************************/
DECLARE
v_return character varying:='';

BEGIN
v_return := (SELECT CASE WHEN p_document_id is null THEN ''
	    WHEN p_document_id = 'B342FD5CA1C64E8BA25A0A6F6C98C7DA' THEN 'PO'
	    WHEN p_document_id = '6557A8E827ED40BDAE66E4A78166A839' THEN 'offer'
	    WHEN p_document_id = '5D5792C53FBA46E2988653B6DC9FE5B4' THEN 'ord'
	    WHEN p_document_id = '45A90145C74C44ECB48AC772B05487CA' THEN 'inv'
	    ELSE (select name from c_doctype where p_document_id = c_doctype_id)
       END);
  
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_docshortcut(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getbpname (p_bpartner_id character varying) RETURNS character varying 
AS $_$ 
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
v_return character varying;
BEGIN
select name into v_return from c_bpartner where c_bpartner_id=p_bpartner_id;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_getbpname(character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zssi_getworkstepname (p_workstep_id VARCHAR)
RETURNS VARCHAR AS
$body$
-- SELECT zssi_getworkstepname('E4169A63B193416F88D91905D4776B55');
-- DECLARE 
BEGIN
  RETURN COALESCE((SELECT pt.name FROM c_projecttask pt WHERE pt.c_projecttask_id = p_workstep_id),'');
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zssi_getinvdoc_link(p_document_id character varying, p_documentno character varying)
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
Juwi Specific Shortcuts
*****************************************************/
DECLARE
v_return character varying:='';

BEGIN
v_return := v_return||'<a id="idfieldCInvoiceId" class="LabelLink_noicon" onmouseout="window.status='''';return true;" onmouseover="window.status=''Attach'';return true;" onclick="openPopUp(''../businessUtility/TabAttachments_FS.html?inpKey='||p_document_id||'&inpEditable=N&inpTabId=290&inpwindowId=183'',''dummy'',400,600,null,null,null,null,null,null,null,null);return false;" href="#"><span>'||p_documentno||' </span>';
  
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  
  
  
CREATE OR REPLACE FUNCTION zssi_getmaterialplandivergencetext(p_task in varchar) 
RETURNS character varying AS
$_$ 
DECLARE
v_return character varying:=chr(13);
v_cur record;
BEGIN
for v_cur in (select 'Abweichung: '||(select rpad(name,60,' ') from m_product where bl.m_product_id=m_product.m_product_id)||': Soll:'|| bl.quantity || ' Ist:'||
                    bl.qtyreceived as val from zspm_projecttaskbom_view bl where bl.c_projecttask_id=p_task
                    and bl.quantity!=bl.qtyreceived)
LOOP
    v_return := v_return||v_cur.val||chr(13);
END LOOP;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  

select zsse_dropfunction('zssi_getmissingqty_complete');
CREATE or replace FUNCTION zssi_getmissingqty_complete() RETURNS character varying
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
Localization in Database - The better way
Get missing qtys
*****************************************************/
DECLARE
v_line character varying;
v_cur record;
v_cur2 record;
v_product_id character varying;

BEGIN
FOR v_cur2 in (select m_product.m_product_id as v_id,sum(coalesce(m_product_org.stockmin,0)) as v_min,
               sum(coalesce(m_product_org.stockmin,0)-m_bom_qty_onhand(m_product.m_product_id,null,m_locator.m_locator_id)) as v_need 
               from m_product_org,m_product, m_locator,m_warehouse 
where m_product_org.isactive='Y' 
and m_product_org.m_product_id=m_product.m_product_id 
and m_product_org.m_locator_id=m_locator.m_locator_id 
and m_locator.m_warehouse_id=m_warehouse.m_warehouse_id 
and coalesce(m_product_org.stockmin,0)>m_bom_qty_onhand(m_product.m_product_id,null,m_locator.m_locator_id)
group by m_product.m_product_id)
LOOP

FOR v_cur in (select m_warehouse.name as v_warehouse,m_product.value||' -'||m_product.name as v_product
from m_product_org,m_product, m_locator,m_warehouse 
where m_product_org.isactive='Y' 
and m_product.m_product_id=v_cur2.v_id
and (v_cur2.v_need)>coalesce((select sum(qtyordered-qtydelivered) from c_orderline, c_order where c_orderline.deliverycomplete='N' and c_order.issotrx='N' and c_order.docstatus='CO' and c_orderline.c_order_id=c_order.c_order_id and c_orderline.m_product_id=v_cur2.v_id and ad_get_docbasetype(c_doctype_id) ='POO' group by c_orderline.m_product_id),0)
and m_product_org.m_product_id=m_product.m_product_id 
and m_product_org.m_locator_id=m_locator.m_locator_id 
and m_locator.m_warehouse_id=m_warehouse.m_warehouse_id 
group by  m_warehouse.name,m_product.value,m_product.name)
  LOOP
  v_line:=coalesce(v_line,'')||'<br/>'||'Artikel '||chr(32)||v_cur.v_product||chr(32)||'in Lager'||chr(32)||v_cur.v_warehouse||chr(32)||'ist der Mindestbestand von'||chr(32)||to_number(v_cur2.v_min)||chr(32)||'um '||chr(32)||to_number(v_cur2.v_need)||chr(32)||'unterschritten.'||'<br/>';
  END LOOP;
  END LOOP;
return v_line;
  END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_checkifmissingqty');
CREATE or replace FUNCTION zssi_checkifmissingqty() RETURNS character varying
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
BEGIN
select zssi_getmissingqty_complete() into v_return;
if (v_return is not null and date_part('hour',now())>=9) then
RETURN coalesce((select c_workcalender_id from c_workcalender where (trunc(workdate)=trunc(now()))) ,'N');
else
RETURN (select c_workcalender_id from c_workcalender where trunc(workdate)=trunc(now()-1));
end if;
END
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE or replace FUNCTION zssi_gettabledata(p_id character varying,p_fieldname character varying,p_table character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Robert Schardt.
***************************************************************************************************************************************************
Get any data you want from any table
Note: 
It makes sense to cast the type of the retval when the query is initialized
because after that type casting of v_cur.retval proved to be very hard to do right.
*****************************************************/
DECLARE
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_sql varchar;
v_retval character varying;
BEGIN
	
	v_sql:='select CAST('||p_fieldname||' as character varying) as retval from '||p_table||' where '||p_table||'_id = '|| chr(39)||p_id||chr(39)||'';
	OPEN v_cursor FOR EXECUTE v_sql;
	LOOP
		FETCH v_cursor INTO v_cur;
		EXIT WHEN NOT FOUND;

		-- Debug
		-- RAISE NOTICE 'Step1: Content of v_cur(%)', v_cur;
		-- RAISE NOTICE 'Step2: Check if expression "v_cur is null" is true: %', (v_cur is null);

		IF(v_cur is null) THEN
			v_retval:='';
		
		ELSE
			v_retval:=v_cur.retval;

		END IF;
	END LOOP;
	close v_cursor;

	-- Debug
	-- RAISE NOTICE 'Step3: Content of v_retval(%)', v_retval;
	RETURN v_retval;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  CREATE or replace FUNCTION zssi_gettabledate(p_id character varying,p_fieldname character varying,p_table character varying) RETURNS timestamp without time zone
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Robert Schardt.
***************************************************************************************************************************************************
Get any date you want from any table 
*****************************************************/
DECLARE
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_sql varchar;
v_retval timestamp without time zone;
BEGIN
        v_sql:='select '||p_fieldname||' as retval from '||p_table||' where '||p_table||'_id = '|| chr(39)||p_id||chr(39)||'';
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_retval:=v_cur.retval;
      END LOOP;
      close v_cursor;
RETURN v_retval;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
   CREATE or replace FUNCTION zssi_gettablenumeric(p_id character varying,p_fieldname character varying,p_table character varying) RETURNS numeric
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk, Robert Schardt.
***************************************************************************************************************************************************
Get any numeric you want from any table 
*****************************************************/
DECLARE
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_sql varchar;
v_retval numeric;
BEGIN
	v_retval:=0;
	v_sql:='select '||p_fieldname||' as retval from '||p_table||' where '||p_table||'_id = '|| chr(39)||p_id||chr(39)||'';
	OPEN v_cursor FOR EXECUTE v_sql;
	LOOP
		FETCH v_cursor INTO v_cur;
		EXIT WHEN NOT FOUND;
		v_retval:=v_cur.retval;
	END LOOP;
	close v_cursor;
RETURN v_retval;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
  
CREATE OR REPLACE FUNCTION zssi_delivery_salesregion(p_delivery_location character varying)
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
Juwi Specific Shortcuts
*****************************************************/
DECLARE
v_return character varying:='';
v_location_id character varying:='';
v_salesregion_id character varying:='';
BEGIN
v_salesregion_id := (SELECT c_salesregion_id from c_bpartner_location where c_bpartner_location_id=p_delivery_location);
if v_salesregion_id is null then v_return:='Kein Vertriebsgebiet angegeben';
else
v_return:=(SELECT name from c_salesregion where c_salesregion_id=v_salesregion_id);
  end if;
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE OR REPLACE FUNCTION zssi_getshortorg(p_org_id character varying)
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
Juwi Specific Shortcuts
*****************************************************/
DECLARE
v_return character varying:='';

BEGIN
v_return:=(SELECT shortcut from ad_org where ad_org_id=p_org_id);
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
 
 
 
  CREATE OR REPLACE FUNCTION c_ignore_accent(v_num numeric) RETURNS character varying AS
$_$ DECLARE 
/*************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
************************************************************************/
BEGIN
  RETURN to_char(v_num);
END ;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  
CREATE OR REPLACE FUNCTION zssi_reportDebtPaymentHeader(p_lang varchar,p_datefrom varchar,p_dateto varchar,p_type varchar,p_org varchar)
RETURNS character varying AS
$_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s):
*********************************************************************************************/
DECLARE
v_return character varying:='';
v_datestr varchar:='';

BEGIN
   if p_datefrom!=''  then
    v_datestr:=' '||lower(zssi_getElementTextByColumname('FromPoT',p_lang))||' '||zssi_strDate(to_date(p_datefrom), p_lang);
   end if;
   if p_dateto!='' then
    v_datestr:=v_datestr||' '||lower(zssi_getElementTextByColumname('To',p_lang))||' '||zssi_strDate(to_date(p_dateto), p_lang);
   end if;
   v_return:= zssi_getElementTextByColumname('Overviewss',p_lang)||' ';
   
   if  p_type='Y' then -- Receipt
     v_return:= v_return||zssi_getElementTextByColumname('debit',p_lang);
   else
     v_return:= v_return||zssi_getElementTextByColumname('liabilities',p_lang);
   end if;
   if instr(p_org,''',''')>0 then
    v_return:=  v_return ||' '||zssi_getElementTextByColumname('AD_Org_ID',p_lang)||' *'||' ';
   else
    v_return:=  v_return || ' '||(select name from ad_org where AD_Org_ID=replace(p_org,chr(39),''))||' ';
   end if;
RETURN v_return||v_datestr;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;


select zsse_dropfunction('checkIfElementsAreEmpty');
CREATE OR REPLACE FUNCTION zssi_checkIfElementsAreEmpty(p_printconfigId VARCHAR(32), p_elementType CHAR(1)) 
	RETURNS  character varying 
	LANGUAGE plpgsql 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Returns 'E' if the default printconfig was not created 
uses zssi_buildDynFromAndWhere_checkIfElementsAreEmpty
uses zssi_buildDynQuery_checkIfElementsAreEmpty
possible elementTypes:
1 = order
2 = invoice
3 = shipment
*****************************************************/
DECLARE
	v_isEmpty character varying;
	v_dynCategory character varying;
	v_dynFromAndWhere character varying;
	v_dynQuery character varying;
BEGIN

	SELECT * FROM zssi_buildDynFromAndWhere_checkIfElementsAreEmpty(p_printconfigid, p_elementtype) into v_dynCategory, v_dynFromAndWhere;


	SELECT zssi_buildDynQuery_checkIfElementsAreEmpty(v_dynCategory, v_dynFromAndWhere) INTO v_dynQuery;
	EXECUTE v_dynQuery INTO v_isEmpty;

	IF (COALESCE(v_isEmpty, '') = '') THEN

		SELECT p_dynFromAndWhere FROM zssi_buildDynFromAndWhere_checkIfElementsAreEmpty(p_printconfigId, '0') INTO v_dynFromAndWhere;

		SELECT zssi_buildDynQuery_checkIfElementsAreEmpty(v_dynCategory, v_dynFromAndWhere) INTO v_dynQuery;
		EXECUTE v_dynQuery INTO v_isEmpty;
	END IF;


	RETURN COALESCE(v_isEmpty, 'E');
END
$_$;


CREATE OR REPLACE FUNCTION zssi_buildDynFromAndWhere_checkIfElementsAreEmpty(p_printconfigId VARCHAR(32), p_elementType CHAR(1), OUT p_dynCategory character varying, OUT p_dynFromAndWhere character varying) 
	LANGUAGE plpgsql 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
builds Dynamic From-And-Where for checkIfElementsAreEmpty 
0 is the default-PrintConfig 
1 is order specific-PrintConfig
2 is invoice specific-PrintConfig
3 is shipment specific-PrintConfig
*****************************************************/
BEGIN
	
	IF p_elementType = '0' THEN

		p_dynCategory := '';
		p_dynFromAndWhere := 'FROM 
					C_PRINTOUT_CONFIG 
				     WHERE ad_org_id = ''0''
					AND isdefault = ''Y''';
		RETURN;


	ELSIF p_elementType = '1' THEN
		p_dynCategory := 'order';

	ELSIF p_elementType = '2' THEN
		p_dynCategory := 'invoice';

	ELSIF p_elementType = '3' THEN
		p_dynCategory := 'shipment';

	END IF;


	p_dynFromAndWhere := 'FROM 
				C_PRINTOUT_CONFIG 
			   WHERE
				c_printout_config.c_printout_config_id = ''' || p_printconfigId || ''''; 
END
$_$;


CREATE OR REPLACE FUNCTION zssi_buildDynQuery_checkIfElementsAreEmpty(p_dynCategory character varying, p_dynFromAndWhere character varying) 
	RETURNS  character varying 
	LANGUAGE plpgsql 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
builds Dynamic Query for checkIfElementsAreEmpty 
*****************************************************/
DECLARE
	v_dynamicQuery character varying;
BEGIN
	

	v_dynamicQuery := '(SELECT
			CASE WHEN 

			(c_printout_config.element1_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element2_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element3_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element4_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element5_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element6_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element7_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element8_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element9_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element10_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element11_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element12_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element13_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element14_' || p_dynCategory || 'ref <> '''') OR
			(c_printout_config.element15_' || p_dynCategory || 'ref <> '''')

			THEN ''N'' 
			ELSE ''Y''
			END ' || p_dynFromAndWhere || 
		' );';


	RETURN v_dynamicQuery;

END
$_$;


CREATE OR REPLACE FUNCTION c_trim(p_str character varying) RETURNS character varying
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
* Contributor(s):  S. Zimmermann, 2016______________________________________.
************************************************************************/
  v_str VARCHAR ; --OBTG:VARCHAR2--
BEGIN
  v_str:=p_str;
  WHILE(INSTR(v_str, '  ', 1, 1) <> 0)
  LOOP
    v_str:=REPLACE(v_str, '  ', ' ') ;
  END LOOP;
  v_str:=LTRIM(RTRIM(v_str)) ;
  RETURN(v_str) ;
END ; $_$;


select zsse_dropfunction('zssi_getReferenceDescriptionFromRefList');
CREATE OR REPLACE FUNCTION zssi_getReferenceDescriptionFromRefList(p_id character varying, p_searchkey varchar, p_language character varying)  RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Robert Schardt (rschardt@openz.de)
Copyright (C) 2017 Robert Schardt All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Searches for the description-text in a ad_ref_list
If the text is a query then execute it
Else try to use the description as a column qualifier of c_order
*****************************************************/
DECLARE
v_dynamicQueryPart character varying;
v_reference_id character varying;
v_description character varying;
v_sqlRegexp character varying := '^[@][sS][qQ][lL][=]';
v_idRegexp character varying := '[#][iI][dD][#]';
v_langRegexp character varying := '[#][lL][aA][nN][gG][#]';
v_query character varying;
v_return character varying;
BEGIN 

	/* falls in der Reference-List-Checkbox nichts ausgewählt ist */
	if(p_searchkey <> '') then

		if ((select count(*) from c_order where c_order_id = p_id) > 0) IS TRUE then
			v_dynamicQueryPart:=' from c_order where c_order_id = ''';
			select ad_reference_id into v_reference_id from ad_reference where name like 'Reference%Order%List';

		elsif ((select count(*) from c_invoice where c_invoice_id = p_id) > 0) IS TRUE then
			v_dynamicQueryPart:=' from c_invoice where c_invoice_id = ''';
			select ad_reference_id into v_reference_id from ad_reference where name like 'Reference%Invoice%List';

		elsif ((select count(*) from m_inout where m_inout_id = p_id) > 0) IS TRUE then
			v_dynamicQueryPart:=' from m_inout where m_inout_id = ''';
			select ad_reference_id into v_reference_id from ad_reference where name like 'Reference%Shipment%List';
		end if;


		select description into v_description from ad_ref_listinstance where ad_reference_id=v_reference_id and value = p_searchkey; 
		if (COALESCE(v_description, '') = '') then
			select description into v_description from ad_ref_list where ad_reference_id=v_reference_id and value = p_searchkey;
		end if;

		
		if (v_description ~ v_sqlRegexp) then
			/* Case: Description starts with @SQL=, execute Query inside description */
			select regexp_replace(v_description, v_sqlRegexp, '') into v_description;
			select regexp_replace(v_description, v_idRegexp, '''' || p_id || '''') into v_description;
			select regexp_replace(v_description, v_langRegexp, '''' || p_language || '''') into v_description;
			select regexp_replace(v_description, v_langRegexp, '''' || p_language || '''') into v_description;
			v_query := v_description;

		else
			/* Case: Description starts not with @SQL=, take column from c_order*/
			/* take order_id and search in c_order for an entry */
			v_query:= 'select ' || v_description || v_dynamicQueryPart || p_id || ''';';

		end if;


		execute v_query into v_return;

	end if;
	RETURN COALESCE(v_return, '');
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction('zssi_getReferenceDescriptionFromDaterefList');
CREATE OR REPLACE FUNCTION zssi_getReferenceDescriptionFromDaterefList(p_id character varying, p_searchkey varchar, p_language character varying)  RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Robert Schardt (rschardt@openz.de)
Copyright (C) 2017 Robert Schardt All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Searches for the description-text in a ad_ref_list
If the text is a query then execute it
Else try to use the description as a column qualifier of c_order
*****************************************************/
DECLARE
v_dynamicQueryPart character varying;
v_reference_id character varying;
v_description character varying;
v_sqlRegexp character varying := '^[@][sS][qQ][lL][=]';
v_idRegexp character varying := '[#][iI][dD][#]';
v_langRegexp character varying := '[#][lL][aA][nN][gG][#]';
v_query character varying;
v_queryResult timestamp without time zone;
v_return character varying;
BEGIN 

	/* falls in der Reference-List-Checkbox nichts ausgewählt ist */
	if(p_searchkey <> '') then

		if ((select count(*) from c_order where c_order_id = p_id) > 0) IS TRUE then
			v_dynamicQueryPart:=' from c_order where c_order_id = ''';
			select ad_reference_id into v_reference_id from ad_reference where name like 'Order%Dateref%List';

		elsif ((select count(*) from c_invoice where c_invoice_id = p_id) > 0) IS TRUE then
			v_dynamicQueryPart:=' from c_invoice where c_invoice_id = ''';
			select ad_reference_id into v_reference_id from ad_reference where name like 'Invoice%Dateref%List';

		elsif ((select count(*) from m_inout where m_inout_id = p_id) > 0) IS TRUE then
			v_dynamicQueryPart:=' from m_inout where m_inout_id = ''';
			select ad_reference_id into v_reference_id from ad_reference where name like 'Shipment%Dateref%List';
		end if;

		select description into v_description from ad_ref_listinstance where ad_reference_id=v_reference_id and value = p_searchkey; 
		if (COALESCE(v_description, '') = '') then
			select description into v_description from ad_ref_list where ad_reference_id=v_reference_id and value = p_searchkey;
		end if;

		if (v_description ~ v_sqlRegexp) then
			/* Case: Description starts with @SQL=, execute Query inside description */
			select regexp_replace(v_description, v_sqlRegexp, '') into v_description;
			select regexp_replace(v_description, v_idRegexp, '''' || p_id || '''') into v_description;
			select regexp_replace(v_description, v_langRegexp, '''' || p_language || '''') into v_description;
			v_query := v_description;

		else
			/* Case: Description starts not with @SQL=, take column from c_order*/
			/* take order_id and search in c_order for an entry */
			v_query:= 'select ' || v_description || v_dynamicQueryPart || p_id || ''';';

		end if;

		execute v_query into v_queryResult;
		select zssi_strdate(v_queryResult, p_language) into v_return; 

	end if;
	RETURN COALESCE(v_return, '');
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction('zssi_getReferenceNameFromRefList');
CREATE OR REPLACE FUNCTION zssi_getReferenceNameFromRefList(p_id character varying, p_searchkey varchar, p_language character varying)  RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Robert Schardt (rschardt@openz.de)
Copyright (C) 2017 Robert Schardt All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Returns Name of ad_ref_list-Entry
*****************************************************/
DECLARE
v_reference_id character varying;
v_name character varying;
v_tmp_name character varying;
v_ref_listinstance_id character varying;
v_ref_list_id character varying;
v_return character varying;
BEGIN 

	/* falls in der Reference-List-Checkbox nichts ausgewählt ist */
	if(p_searchkey <> '') then 

		if ((select count(*) from c_order where c_order_id = p_id) > 0) IS TRUE then
			select ad_reference_id into v_reference_id from ad_reference where name like 'Reference%Order%List';

		elsif ((select count(*) from c_invoice where c_invoice_id = p_id) > 0) IS TRUE then
			select ad_reference_id into v_reference_id from ad_reference where name like 'Reference%Invoice%List';

		elsif ((select count(*) from m_inout where m_inout_id = p_id) > 0) IS TRUE then
			select ad_reference_id into v_reference_id from ad_reference where name like 'Reference%Shipment%List';
		end if;


		select name, ad_ref_list_id, ad_ref_listinstance_id into v_name, v_ref_list_id, v_ref_listinstance_id from ad_ref_listinstance where ad_reference_id=v_reference_id and value = p_searchkey; 

		if (COALESCE(v_ref_listinstance_id, '') <> '') then
			
			/* Sub-Select auf die Übersetzung */
			select name INTO v_tmp_name from ad_ref_listinstance_trl where ad_ref_listinstance_id = v_ref_listinstance_id AND ad_language = p_language;

		else
			select name, ad_ref_list.ad_ref_list_id into v_name, v_ref_list_id from ad_ref_list where ad_reference_id=v_reference_id and value = p_searchkey;
			
			/* Sub-Select auf die Übersetzung */
			select name INTO v_tmp_name from ad_ref_list_trl where ad_ref_list_id = v_ref_list_id AND ad_language = p_language;
 
		end if;

		v_return := COALESCE(v_tmp_name, v_name); 
	
	end if;
	RETURN COALESCE(v_return, '');
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_printout_config_bef_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt
***************************************************************************************************************************************************
*/
v_count numeric;
BEGIN

   IF TG_OP = 'INSERT' then
	
	IF new.isdefault = 'Y' then

		v_count := (select count(*) from c_printout_config where c_printout_config.ad_org_id = new.ad_org_id AND c_printout_config.isdefault = 'Y');

		IF v_count > 0 then
			RETURN NULL;
		END IF;
	
	END IF;

	RETURN new;

   END IF;


   IF TG_OP = 'UPDATE' then
	
	IF (new.isdefault = 'Y') AND (old.isdefault != new.isdefault) then

		v_count := (select count(*) from c_printout_config where c_printout_config.ad_org_id = new.ad_org_id AND c_printout_config.isdefault = 'Y');
	
		IF v_count > 0 then
			RETURN old;
		END IF;

	END IF;

	RETURN new;

   END IF;

END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_DropTrigger ('c_printout_config_bef_insert_trg','c_printout_config');  
CREATE TRIGGER c_printout_config_bef_insert_trg
  before INSERT
  ON c_printout_config
  FOR EACH ROW
  EXECUTE PROCEDURE c_printout_config_bef_trg();
  
select zsse_DropTrigger ('c_printout_config_bef_update_trg','c_printout_config');  
CREATE TRIGGER c_printout_config_bef_update_trg
  before UPDATE
  ON c_printout_config
  FOR EACH ROW
  EXECUTE PROCEDURE c_printout_config_bef_trg();


CREATE OR REPLACE FUNCTION zssi_getbpartnername(p_cbpartner_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      
      select CASE WHEN COALESCE(c_bpartner_location.deviant_bp_name, '') != '' THEN c_bpartner_location.deviant_bp_name	ELSE c_bpartner.name END into v_return from c_bpartner_location left join c_bpartner on c_bpartner_location.c_bpartner_id = c_bpartner.c_bpartner_id where c_bpartner_location.c_bpartner_location_id = p_cbpartner_location_id;
     
RETURN COALESCE(v_return, '');
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getDeliveryLocationText');
CREATE OR REPLACE FUNCTION zssi_getDeliveryLocationText(p_order_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Robert Schardt (rschardt@openz.de)
Copyright (C) 2017 Robert Schardt All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
-- returns the deliverylocationText for order-reports
>>>>>>> release/tmp
-- if c_order = dropshiporder then 
-- 	get the deliverylocation from c_order linked in orderselfjoin 
*****************************************************/
DECLARE
v_order_id character varying;
v_return character varying;
BEGIN 

	
	select CASE WHEN (issotrx = 'N' AND c_doctype_id = 'EE19ABBDB5A94C519DAB11003320FC8E' AND c_order_id != orderselfjoin) THEN orderselfjoin ELSE c_order_id END into v_order_id from c_order where c_order_id = p_order_id;

	if (COALESCE(v_order_id, '') != '') then
		select deliverylocationtext into v_return from c_order where c_order_id = v_order_id;
	end if;

	RETURN COALESCE(v_return, '');
END;
$_$  LANGUAGE 'plpgsql';

 
select zsse_dropfunction('zssi_getDeliveryLocationId');
CREATE OR REPLACE FUNCTION zssi_getDeliveryLocationId(p_order_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Robert Schardt (rschardt@openz.de)
Copyright (C) 2017 Robert Schardt All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
-- returns the deliverylocationId for order-reports
-- if c_order = dropshiporder then 
-- 	get the deliverylocation from c_order linked in orderselfjoin 
*****************************************************/
DECLARE
v_order_id character varying;
v_return character varying;
BEGIN 

	select CASE WHEN (issotrx = 'N' AND c_doctype_id = 'EE19ABBDB5A94C519DAB11003320FC8E' AND c_order_id != orderselfjoin) THEN orderselfjoin ELSE c_order_id END into v_order_id from c_order where c_order_id = p_order_id;

	if (COALESCE(v_order_id, '') != '') then

		-- wenn kein Streckenauftrag dann darf c_bpartner_location_id nicht verwendet werden
		if (v_order_id = p_order_id) then
			select delivery_location_id into v_return from c_order where c_order_id = v_order_id;

		else
			select CASE WHEN delivery_location_id is not null then delivery_location_id else c_bpartner_location_id END into v_return from c_order where c_order_id = v_order_id;
		end if;
	end if;

	RETURN COALESCE(v_return);
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssi_getCustomerNumber(p_order_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Robert Schardt (rschardt@openz.de)
Copyright (C) 2017 Robert Schardt All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
-- returns the customernumber for order-reports
-- if c_order = dropshiporder then 
-- 	get the c_bpartner.value from c_bpartner
*****************************************************/
DECLARE
v_issotrx character varying;
v_doctype_id character varying;

v_order_id character varying;
v_return character varying;
BEGIN 

	select issotrx, c_doctype_id into v_issotrx, v_doctype_id from c_order where c_order_id = p_order_id;

	-- spezialFall Streckenauftrag
	if (v_issotrx = 'N' AND v_doctype_id = 'EE19ABBDB5A94C519DAB11003320FC8E') THEN

		select  orderselfjoin INTO v_order_id from c_order where c_order_id = p_order_id;

		if (COALESCE(v_order_id, '') != '') then

			select cbp.value into v_return from c_order co, c_bpartner cbp where co.c_bpartner_id = cbp.c_bpartner_id AND co.c_order_id = v_order_id;
		end if;

	-- normalFall
	else 
		select (CASE WHEN(C_ORDER.issotrx = 'N') THEN C_BPARTNER.OWNCODEATPARTNERSITE ELSE C_BPARTNER.VALUE END) into v_return from C_ORDER LEFT JOIN C_BPARTNER ON C_ORDER.C_BPARTNER_ID = C_BPARTNER.C_BPARTNER_ID WHERE C_ORDER.C_ORDER_ID = p_order_id; 
	end if;

	RETURN COALESCE(v_return, '');
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssi_getprintcontactname(p_cbpartner_location_id character varying) RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
      
      select printcontactname into v_return from c_bpartner_location left join c_bpartner on c_bpartner_location.c_bpartner_id = c_bpartner.c_bpartner_id where c_bpartner_location.c_bpartner_location_id = p_cbpartner_location_id;
     
RETURN v_return;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select zsse_dropfunction('zssi_getpaymenttermdetail');
CREATE OR REPLACE FUNCTION zssi_getpaymenttermdetail(p_invoice_id character varying, OUT payment_until timestamp without time zone,OUT skonto numeric,OUT skontovalue numeric, OUT paymentvalue numeric, OUT currencysymbol varchar)
RETURNS setof record AS
$_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt 
***************************************************************************************************************************************************
Zahlungskonditionen-Detail Funktion
*****************************************************/
DECLARE
v_curcal record;
v_cur record;
v_return character varying:='';
v_startDate timestamp without time zone;
v_totalSum numeric;
v_totalDays numeric;
v_tmpDate timestamp without time zone;
v_tmpSkontoValue numeric;
v_tmpCur varchar;
v_currency varchar;

BEGIN

SELECT c_invoice.dateinvoiced, c_invoice.grandtotal, c_paymentterm.netdays, c_currency.cursymbol into v_startDate, v_totalSum, v_totalDays, v_currency 
                from c_invoice
                left join c_paymentterm on c_invoice.c_paymentterm_id = c_paymentterm.c_paymentterm_id
                left join c_currency on c_invoice.c_currency_id=c_currency.c_currency_id
                where c_invoice.c_invoice_id=(p_invoice_id);

v_tmpDate := v_startDate;

v_tmpCur := v_currency;
Raise Notice '%', v_tmpCur;

for v_curcal in (select zsfi_discount.netdays as netdays, zsfi_discount.percentage as percentage
                from c_invoice
                left join c_paymentterm on c_invoice.c_paymentterm_id = c_paymentterm.c_paymentterm_id
                left join zsfi_discount on c_paymentterm.c_paymentterm_id = zsfi_discount.c_paymentterm_id
                where c_invoice.c_invoice_id=(p_invoice_id)
		order by zsfi_discount.percentage desc)
LOOP

	v_tmpDate := v_startDate + (v_curcal.netdays || ' day')::interval;
	payment_until := v_tmpDate;
	skonto := v_curcal.percentage;
	skontovalue := (v_totalSum / 100) * v_curcal.percentage;
	paymentvalue := v_totalSum - skontovalue;
    currencysymbol:=v_tmpCur;
    if payment_until is not null then
        RETURN NEXT;
    end if;
END LOOP;

	payment_until := v_startDate + (v_totalDays || ' day')::interval;
	skonto := null; 	
	skontovalue := null;	
	paymentvalue := v_totalSum;
	RETURN NEXT;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getorderlinecombinedsums');
CREATE OR REPLACE FUNCTION zssi_getorderlinecombinedsums(p_order_id character varying, p_line numeric, OUT sum_priceactual numeric, OUT sum_discount numeric,OUT sum_pricestd numeric, OUT sum_linenetamt numeric, OUT sum_linegrossamt numeric, OUT isonlyone VARCHAR(1))
RETURNS RECORD AS
$_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt 
***************************************************************************************************************************************************
Gebe die Summen der priceactual-, discount-, pricestd-, lineamt- und linegrossamt-Spalten
in c_orderline aus
*****************************************************/
DECLARE
v_curcal record;
v_begin_end_counter numeric := 0;
v_entry_counter numeric := 0;
BEGIN

sum_priceactual := 0;
sum_discount := 0;
sum_pricestd := 0;
sum_linenetamt := 0;
sum_linegrossamt := 0;
isonlyone := 'Y';

for v_curcal in (
	select col.iscombined, col.ispricesuppressed, col.priceactual as sum_priceactual, col.discount as sum_discount, col.pricestd as sum_pricestd, col.linenetamt as sum_linenetamt, col.linegrossamt as sum_linegrossamt
	from c_orderline col 
	where col.c_order_id = p_order_id
	AND col.line <= p_line
	ORDER BY col.line desc
)
LOOP


	IF (v_curcal.iscombined = 'Y') THEN
		v_begin_end_counter := v_begin_end_counter + 1;
	END IF;


	IF ((v_curcal.ispricesuppressed = 'N' AND v_curcal.iscombined = 'N') OR (v_begin_end_counter > 1)) THEN
		EXIT;
	END IF;	


	IF (v_entry_counter >= 1) THEN
		isonlyone := 'N';
	END IF;


	IF (v_curcal.ispricesuppressed = 'Y' OR v_curcal.iscombined = 'Y') THEN
		v_entry_counter := v_entry_counter + 1;
	END IF;	


	sum_priceactual := sum_priceactual + v_curcal.sum_priceactual;
	sum_discount := sum_discount + v_curcal.sum_discount;
	sum_pricestd := sum_pricestd + v_curcal.sum_pricestd;
	sum_linenetamt := sum_linenetamt + v_curcal.sum_linenetamt;
	sum_linegrossamt := sum_linegrossamt + v_curcal.sum_linegrossamt;
END LOOP;

	RETURN;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getinvoicelinecombinedsums'); CREATE OR REPLACE FUNCTION zssi_getinvoicelinecombinedsums(p_invoice_id character varying, p_line numeric, OUT sum_priceactual numeric, OUT sum_pricestd numeric, OUT sum_linenetamt numeric, OUT sum_linegrossamt numeric, OUT isonlyone VARCHAR(1))
RETURNS RECORD AS
$_$ 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt 
***************************************************************************************************************************************************
Gebe die Summen der priceactual-, discount-, pricestd-, lineamt- und linegrossamt-Spalten
in c_invoiceline aus
*****************************************************/
DECLARE
v_curcal record;
v_begin_end_counter numeric := 0;
v_entry_counter numeric := 0;
BEGIN

sum_priceactual := 0;
sum_pricestd := 0;
sum_linenetamt := 0;
sum_linegrossamt := 0;
isonlyone := 'Y';

for v_curcal in (
	select col.iscombined, col.ispricesuppressed, col.priceactual as sum_priceactual, col.pricestd as sum_pricestd, col.linenetamt as sum_linenetamt, col.linegrossamt as sum_linegrossamt
	from c_invoiceline col 
	where col.c_invoice_id = p_invoice_id
	AND col.line <= p_line
	ORDER BY col.line desc
)
LOOP


	IF (v_curcal.iscombined = 'Y') THEN
		v_begin_end_counter := v_begin_end_counter + 1;
	END IF;


	IF ((v_curcal.ispricesuppressed = 'N' AND v_curcal.iscombined = 'N') OR (v_begin_end_counter > 1)) THEN
		EXIT;
	END IF;	
	

	IF (v_entry_counter >= 1) THEN
		isonlyone := 'N';
	END IF;


	IF (v_curcal.ispricesuppressed = 'Y' OR v_curcal.iscombined = 'Y') THEN
		v_entry_counter := v_entry_counter + 1;
	END IF;	


	sum_priceactual := sum_priceactual + v_curcal.sum_priceactual;
	sum_pricestd := sum_pricestd + v_curcal.sum_pricestd;
	sum_linenetamt := sum_linenetamt + v_curcal.sum_linenetamt;
	sum_linegrossamt := sum_linegrossamt + v_curcal.sum_linegrossamt;
END LOOP;

	RETURN;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getDeliveryLocation');
CREATE OR REPLACE FUNCTION zssi_getDeliveryLocation(p_order_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Robert Schardt (rschardt@openz.de)
Copyright (C) 2017 Robert Schardt All Rights Reserved.
Contributor(s): ______________________________________.
+***************************************************************************************************************************************************
-- returns the deliverylocation for order-reports
-- if c_order = dropshiporder then 
--     get the deliverylocation from c_order linked in orderselfjoin 
*****************************************************/
DECLARE
v_order_id character varying;
v_return character varying;
BEGIN 

       select CASE WHEN (issotrx = 'N' AND c_doctype_id = 'EE19ABBDB5A94C519DAB11003320FC8E' AND c_order_id != orderselfjoin) THEN orderselfjoin ELSE c_order_id END into v_order_id from c_order where c_order_id = p_order_id;

       if (COALESCE(v_order_id, '') != '') then
               select CASE WHEN co.deliverylocationtext is not null then co.deliverylocationtext else (SELECT cbl.name from c_bpartner_location cbl where cbl.c_bpartner_location_id = (CASE WHEN co.delivery_location_id is not null then co.delivery_location_id else co.c_bpartner_location_id END)) END into v_return from c_order co where c_order_id = v_order_id;
		       end if;
		
		       RETURN COALESCE(v_return, '');
END;
$_$  LANGUAGE 'plpgsql';


CREATE or replace FUNCTION zssi_getorderadditionaltext4manualtrx1(v_order_id character varying,v_lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
Replaces Column projectname in InOutManual
***************************************************************************************************************************************************/
DECLARE
v_return character varying;
BEGIN
      select zssi_getprojectorcostcentername(o.c_project_id,o.a_asset_id) into v_return from c_order o where o.c_order_id=v_order_id;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE or replace FUNCTION zssi_getorderadditionaltext4manualtrx2(v_order_id character varying,v_lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
Replaces Column doctypename in InOutManual
***************************************************************************************************************************************************/
DECLARE
v_return character varying;
BEGIN
      select dttrl.name into v_return from c_order v, c_doctype_trl dttrl where v.c_order_id=v_order_id and dttrl.c_doctype_id=v.c_doctype_id and dttrl.ad_language = v_lang;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE or replace FUNCTION zssi_getDescriptiontext4Workorder(v_ptask_id character varying,v_lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
Replaces Column description in Rpt_Productionreport.jrxml -> Subreport RptStd_PTasks.jrxml
***************************************************************************************************************************************************/
DECLARE
v_return character varying;
v_desc character varying:='';
v_bom varchar:='';
v_ls varchar:='                                                                                                                            ';
v_cur record;
BEGIN
      select coalesce(description,'') into v_desc from c_projecttask where c_projecttask_id=v_ptask_id;
      -- BOM
      for v_cur in (select  zssi_getIdentifierFromKey('m_product_id',b.m_product_id,v_lang) as product,b.quantity,l.value,
                    (select bs.batchnumber from snr_batchmasterdata bs,snr_batchlocator bl where bs.snr_batchmasterdata_id=bl.snr_batchmasterdata_id and bl.snr_batchlocator_id=b.snr_batchmasterdata_id) as bnr
                    from zspm_projecttaskbom b,m_locator l 
                    where l.m_locator_id=b.receiving_locator and b.c_projecttask_id=v_ptask_id order by l.value,b.line)
      LOOP
        if v_bom='' then
            if v_desc!='' then v_desc:=v_desc||'<br/><br/>';  end if;
            v_bom:='<b>'||zssi_getElementTextByColumname('Zspm_Projecttaskbom_ID',v_lang)||':</b><br/>';
        end if;
        --v_bom:=v_bom||substr(v_cur.product||v_ls,1,60)||'('||substr(v_cur.value||')'||v_ls,1,15)||zssi_strNumber(v_cur.quantity,v_lang)||'<br/>';
        v_bom:=v_bom||replace(rpad(zssi_strNumber(v_cur.quantity,v_lang),10,'X'),'X','&nbsp;')||v_cur.product||':     ('||coalesce(v_cur.value,'No Locator')||')'||'<br/>';
        if v_cur.bnr is not null then
            v_bom:=v_bom||replace(rpad('X',14,'X'),'X','&nbsp;')||v_cur.bnr||'<br/>';
        end if;
      END LOOP;
      --v_return:=v_desc||replace(v_bom,' ','&nbsp;');
      -- Testen (select string_agg(name,'<br/>') from m_product)
      v_return:=v_desc||v_bom;
      
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE or replace FUNCTION zssi_getWorkorderTaskHeader(v_ptask_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
DECLARE
v_return character varying;
v_first character varying:='';  
v_i numeric:=1;
v_num numeric;
v_cur record;
BEGIN
      select count(*) into v_num from c_projecttask where c_project_id=(select c_project_id from c_projecttask where c_projecttask_id=v_ptask_id);
      for v_cur in (select value,seqno,c_projecttask_id from c_projecttask where c_project_id=(select c_project_id from c_projecttask where c_projecttask_id=v_ptask_id) order by seqno)
      LOOP
        if v_first='' then
            if v_cur.c_projecttask_id=v_ptask_id then
                if v_num=1 then
                    v_return:=v_cur.value;
                else
                    v_return:=v_cur.value||' (1/'||v_num||')';
                end if;
            end if;
            v_first:=v_cur.value;
        else
            v_i:=v_i+1;
            if v_cur.c_projecttask_id=v_ptask_id then
                v_return:=v_first||' ('||v_i||'/'||v_num||' - '||v_cur.value||')';
            end if;
        end if;
      end LOOP;
RETURN coalesce(v_return,'');
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
