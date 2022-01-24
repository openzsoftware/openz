/* 
This script imports data for attributes and attribuevalues

Please adjust target path to the corresponding xls-files.

path: '/home/openz/import/ 
*/

/*Create new attributes*/
CREATE TEMP TABLE tmp_x(
        name                    character varying(64),
        description             character varying(1000),
        isactive                character varying(1),
        ismandatory             character varying(1),
        islist                  character varying(1),
        isnumeric               character varying(1),
        id                      character varying(32),
        ad_client_id            character varying(32),
        ad_org_id               character varying(32),
        createdby               character varying(32)        
);

\copy tmp_x from '/home/openz/import/attributes.csv' Delimiter ';' csv;

UPDATE tmp_x
SET id = get_uuid() where id is null;

UPDATE tmp_x 
SET ad_client_id = (select ad_client_id from m_product where value = '1') where tmp_x.ad_client_id is null;

UPDATE tmp_x
SET ad_org_id = (select ad_org_id from m_product where value = '1') where tmp_x.ad_org_id is null;

UPDATE tmp_x
SET createdby = (select createdby from m_product where value = '1') where tmp_x.createdby is null;

INSERT INTO m_attribute (m_attribute_id,ad_client_id,ad_org_id,createdby,updatedby,name,description,ismandatory,islist,isnumeric)
SELECT id, ad_client_id, ad_org_id, createdby, createdby, name, description, ismandatory, islist, isnumeric FROM tmp_x; 

DROP Table tmp_x;

/*Set attribute values */
CREATE TEMP TABLE tmp_x(
        search                    character varying(64),
        value                    character varying(64),
        name                    character varying(64),
        description             character varying(1000),
        isactive                character varying(1),
        id                      character varying(32),
        att                      character varying(32),
        ad_client_id            character varying(32),
        ad_org_id               character varying(32),
        createdby               character varying(32)        
);

\copy tmp_x from '/home/openz/import/attributevalues.csv' Delimiter ';' csv;

UPDATE tmp_x
SET id = get_uuid() where id is null;

UPDATE tmp_x 
SET ad_client_id = (select ad_client_id from m_product where value = '1') where tmp_x.ad_client_id is null;

UPDATE tmp_x
SET ad_org_id = (select ad_org_id from m_product where value = '1') where tmp_x.ad_org_id is null;

UPDATE tmp_x
SET createdby = (select createdby from m_product where value = '1') where tmp_x.createdby is null;

UPDATE tmp_x
SET att = (select m_attribute_id from m_attribute where name = search fetch first row only);


INSERT INTO m_attributevalue (m_attributevalue_id,ad_client_id,ad_org_id,createdby,updatedby,m_attribute_id,value,name,description)
SELECT id, ad_client_id, ad_org_id, createdby, createdby,  att,value,name,description FROM tmp_x; 

DROP Table tmp_x;
