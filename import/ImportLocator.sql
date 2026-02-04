drop table zsi_locator;
 
create table zsi_locator(
warehouse_key character varying(250),
locator_key character varying(250),
prio  character varying(250),
x character varying(250),
y character varying(250) ,
z character varying(250)
);

copy zsi_locator from '/tmp/Locator.csv' CSV DELIMITER as ';' HEADER ;


CREATE or replace FUNCTION  zsi_LocatorImport() RETURNS void
AS $_$
DECLARE

ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='0';

v_org character varying;
v_locator character varying;
v_count numeric;
v_wh varchar;
v_cur RECORD;
v_cur2 RECORD;
v_anz numeric:=0;
BEGIN
  for v_cur in (select * from zsi_locator)
  LOOP
    select m_warehouse_id,ad_org_id into v_wh,v_org from m_warehouse where name=v_cur.warehouse_key;
    if v_wh is null then
        raise exception '%', 'Nicht vorhanden:'||v_cur.warehouse_key;
    end if;
    select count(*) into v_count from m_locator where m_warehouse_id=v_wh and value=v_cur.locator_key;
    if v_count=0 then
        insert into m_locator (m_locator_id,AD_CLIENT_ID, AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,m_warehouse_ID,value,priorityno,x,y,z)
               values(get_uuid(),ad_client,v_org,now(),creator,now(),creator,v_wh,v_cur.locator_key,to_number(v_cur.prio),to_number(v_cur.x),to_number(v_cur.y),to_number(v_cur.z));
        raise notice '%',v_cur.locator_key;
        v_anz:=v_anz+1;
    end if;
  END LOOP;
  raise notice '%',v_anz||' importiert';
END;
$_$  LANGUAGE 'plpgsql';
