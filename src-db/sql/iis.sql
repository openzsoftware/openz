/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Published 2013 Stefan Zimmermann.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Custom MODULE


****************************************************/


CREATE or replace FUNCTION iis_ldapimport (p_filename VARCHAR)  RETURNS VARCHAR
AS $body_$
DECLARE
  v_cur RECORD;
 
  v_anzLines INTEGER := 0;
  v_cmd VARCHAR := '';
  v_message VARCHAR := '';
  v_count numeric;
  v_bpid varchar;
  v_locid varchar;
  v_aduser varchar;
  --- HARD CODED VALUES:
  v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
  v_user varchar:='0';
  -- ON INstance
  /*
  v_org varchar:='1AF9E07685234E0A9FEC1D9B58A4876B';
  v_bpgroup varchar:='51E4D07825D34B32AA7F38084DD24B1F';
  -- Auslieferstellen (Warenlager ID)
  v_shipNUE varchar:='1FA4C25664384D6C8B4913DDFD99A2CE';
  v_shipFUE varchar:='D7B769236D854C6586E6DED0741AE4D6';
  v_shipERL varchar:='EDC636380F3548828312715864ACF6B7';
  -- EMail Role
  v_alertrole varchar:='8D8B2DCAA1F14836A90F4871FA278B3F';
  */
  v_org varchar:='D828C1DEDCA74CB09E90C1A194BE6A80';
  v_bpgroup varchar:='00EAF957DDD740608EB5B85AAA2B5930';
  -- Auslieferstellen (Warenlager ID)
  v_shipNUE varchar:='AF0A6DA9C3E844569DE386E8FF23CD67';
  v_shipFUE varchar:='7D94F186661244CEBDF329A3D63B6C97';
  v_shipERL varchar:='78FEAE4E173D4C7E93278D4BD2F78E96';
  -- EMail Role
  v_alertrole varchar:='87142B3C7BD44569B1E74C66BA387EE5';
BEGIN

    perform zsse_droptable ('iis_ldapimport');
    RAISE NOTICE 'CREATE TABLE iis_ldapimport';
    -- DROP TABLE I_Primanota;
    CREATE TABLE iis_ldapimport (
      enumber varchar(40),
      location varchar(3),
      email varchar(259),
      name varchar(60),
      kuerzel varchar(40),
      oe varchar(40)
    );
 

-- Kopfsatz kopieren
  v_cmd := 'COPY iis_ldapimport FROM ''' || p_filename ||'''  CSV DELIMITER as '||chr(39)||';'||chr(39)||' HEADER ';
  RAISE NOTICE '%', v_cmd;
  EXECUTE(v_cmd);

  
  for v_cur in (select * from  iis_ldapimport)
  LOOP
    -- Mitarbeiter
    select count(*) into v_count from c_bpartner where referenceno=v_cur.enumber;
    if v_count>0 then
        select c_bpartner_id into v_bpid from c_bpartner where  referenceno=v_cur.enumber;
        select ad_user_id into v_aduser from ad_user where c_bpartner_id=v_bpid;
        update c_bpartner set  updated=now(),updatedby='0',name=v_cur.name,description='Org. Einheit:'||v_cur.oe||' , Kürzel: '||v_cur.kuerzel where c_bpartner_id=v_bpid;
        update ad_user set  updated=now(),updatedby='0',
			    description=v_cur.oe,
                           name=substr(v_cur.name,1,60-length(v_cur.kuerzel)-length(v_cur.location)-2)||'-'||v_cur.kuerzel||'-'||v_cur.location,
                           email=v_cur.email where c_bpartner_id=v_bpid;
    else
        select get_uuid() into v_bpid;
        select get_uuid() into v_aduser;
        INSERT INTO c_bpartner (C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, VALUE, NAME, C_BP_GROUP_ID, ISEMPLOYEE,AD_LANGUAGE,Referenceno,description)
            VALUES (v_bpid,v_client , v_org,v_user,v_user,v_cur.enumber,v_cur.name, v_bpgroup,'Y','de_DE',v_cur.enumber, 'Org. Einheit:'||v_cur.oe||' , Kürzel: '||v_cur.kuerzel);    
        INSERT INTO c_bp_employee(c_bpartner_id) VALUES (v_bpid);
        -- Delete default entry created thriugh zssi_bpartner_trg 
        DELETE FROM ad_USER where C_BPARTNER_ID=v_bpid;
        -- Create User entry
        INSERT INTO ad_user (C_BPARTNER_ID,ad_user_id, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,NAME,description,email,enumber)
            VALUES (v_bpid,v_aduser,v_client , v_org,v_user,v_user,
                    substr(v_cur.name,1,60-length(v_cur.kuerzel)-length(v_cur.location)-2)||'-'||v_cur.kuerzel||'-'||v_cur.location,
                    v_cur.oe,
                    v_cur.email,v_cur.enumber);    
    end if;
    delete from m_warehouse_shipper where c_bpartner_id=v_bpid;
    --delete from ad_alertrecipient where ad_alertrule_id='B2D681ABC2004BF3B879D4D1120101DE';
    if v_cur.location='FUE' then
        v_locid=v_shipFUE;
    end if;
    if   v_cur.location='NUE' then
        v_locid=v_shipNUE;
    end if;
    if   v_cur.location not in ('FUE','NUE') then
        v_locid=v_shipERL;
    end if;
    insert into m_warehouse_shipper (m_warehouse_shipper_id,C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,m_warehouse_id)
            VALUES (get_uuid(),v_bpid,v_client , v_org,v_user,v_user,v_locid);
    select count(*) into v_count from ad_user_roles where ad_user_id=v_aduser and ad_role_id=v_alertrole;
    if v_count=0 then
        insert into ad_user_roles(ad_user_roles_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,ad_role_id,ad_user_id)
               VALUES(get_uuid(),v_client , v_org,v_user,v_user,v_alertrole,v_aduser);
    end if;
    --insert into ad_alertrecipient(ad_alertrecipient_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,ad_role_id,ad_alertrule_id,sendemail,ad_user_id)
    --      VALUES (get_uuid(),v_client , v_org,v_user,v_user,v_alertrole,'B2D681ABC2004BF3B879D4D1120101DE','Y',v_aduser);
                                  
  END LOOP;
 
  SELECT COUNT(*) INTO v_anzLines FROM iis_ldapimport;
  v_message := 'SUCCESS - '  || v_anzLines || ' Datensätze importiert';
  RAISE NOTICE '%', v_message;

  RETURN v_message;
END;
$body_$
LANGUAGE 'plpgsql';


 CREATE OR REPLACE FUNCTION iis_update_kontakperson(p_value character varying, status character) RETURNS character varying
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
update snr_masterdata set sending=status where snr_masterdata.snr_masterdata_id=p_value;
   return 'OK';
END; $_$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION iis_sendserial_contact(p_pinstance_id character varying)
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
Deactivates Alert in next cycle
Checks
*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_Org    character varying;
v_message character varying:='Success';

BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID,i.ad_org_id into v_Record_ID, v_User,v_Org from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    
    select iis_update_kontakperson(v_Record_ID,'Y') into v_Message;
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N',1 , v_Message) ;
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
ALTER FUNCTION iis_sendserial_contact(character varying) OWNER TO tad;