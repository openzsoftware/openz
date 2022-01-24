create table zsi_project(
projectvalue_key  character varying(250),
name character varying(250)
);
  
copy zsi_project from '/tmp/Project.csv' CSV DELIMITER as ',' HEADER ;

CREATE or replace FUNCTION  i_import_project() RETURNS varchar
AS $_$
DECLARE

v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_count numeric;
v_cmd varchar;
v_masterproduct varchar;
v_u numeric:=0;
v_i numeric:=0;
v_cur RECORD;
v_date Date;
v_pricelist varchar;
v_requid varchar;
v_seq numeric;
v_product varchar;
v_line numeric:=0;
v_uom varchar;
BEGIN
    for v_cur in (select
                    get_uuid() as C_PROJECT_ID,v_client as AD_CLIENT_ID,(select ad_org_id from ad_org where ad_org_id!='0' limit 1) as AD_ORG_ID,projectvalue_key as VALUE,'' as DESCRIPTION,
                     'S' as PROJECTCATEGORY, 'OP' as PROJECTSTATUS,name
                            from  zsi_project)
        LOOP
            if (select count(*) from c_project where value=v_cur.VALUE)=0 then
                insert into c_project (
                        C_PROJECT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,
                        VALUE, NAME, DESCRIPTION,  PROJECTCATEGORY,  PROJECTSTATUS,c_currency_id)
                values (
                        v_cur.C_PROJECT_ID, v_cur.AD_CLIENT_ID, v_cur.AD_ORG_ID, '0', '0',
                        v_cur.VALUE,v_cur.name, v_cur.DESCRIPTION,
                        v_cur.PROJECTCATEGORY,  v_cur.PROJECTSTATUS ,'102');
            end if;
        END LOOP; 
        return 'OK';
END;
$_$  LANGUAGE 'plpgsql';
