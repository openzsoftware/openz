create table zsi_productprice (
	value character varying(250),
	price numeric
);
copy zsi_productprice from '/tmp/UWprice.csv' CSV DELIMITER as ';';
/*------| UW Service Preis Import |----------------------------------------------------*\
	Function detail description
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zsi_productprice_import()
RETURNS void AS $BODY$ 
DECLARE
	v_cur record;
BEGIN
	for v_cur in (select * from zsi_productprice) loop
		insert into m_productprice(
			m_productprice_id,
			m_pricelist_version_id,
			m_product_id,
			ad_client_id,
			ad_org_id,
			isactive,
			created,
			createdby,
			updated,
			updatedby,
			pricelist,
			pricestd,
			pricelimit)
		values(
			(select get_uuid()),
			(select m_pricelist_version_id from m_pricelist_version where name = '28-12-2012v'),
			(select m_product_id from m_product where value = v_cur.value),
			(select ad_client_id from ad_client where name = 'UW Service'),
			(select ad_org_id from ad_org where value = 'UW Service'),
			'Y',
			now(),
			'0',
			now(),
			'0',
			v_cur.price,
			v_cur.price,
			v_cur.price
		);
	end loop;
END; 
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| UW Service Preis Import |--------------------------------------------------\*--
select zsi_productprice_import();
drop table zsi_productprice;
drop function zsi_productprice_import();


create table zsi_prices(
	value character varying(250),
	first numeric,
	last numeric,
	price numeric
);
copy zsi_prices from '/tmp/UWstaffel.csv' CSV DELIMITER as ';' ;
/*------| UW Service Preis Staffel Import |--------------------------------------------*\
	Function detail description
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zsi_prices_import()
RETURNS void AS $BODY$ 
DECLARE
	v_cur record;
	v_offerid character varying;
BEGIN
	for v_cur in (select * from zsi_prices) loop
		select get_uuid() into v_offerid;
		insert into m_offer(
			m_offer_id,
			ad_client_id,
			ad_org_id,
			isactive,
			created,
			createdby,
			updated,
			updatedby,
			name,
			fixed,
			datefrom,
			bpartner_selection,
			bp_group_selection,
			product_selection,
			prod_cat_selection,
			pricelist_selection,
			qty_from,
			qty_to
		)
		values(
			v_offerid,
			(select ad_client_id from ad_client where name = 'UW Service'),
			(select ad_org_id from ad_org where value = 'UW Service'),
			'Y',
			now(),
			'0',
			now(),
			'0',
			v_cur.value || ' ' || v_cur.first || ' - ' || v_cur.last,
			v_cur.price,
			now(),
			'Y',
			'Y',
			'N',
			'Y',
			'Y',
			v_cur.first,
			v_cur.last	
		);
		
		insert into m_offer_product(
			m_offer_product_id,
			ad_client_id,
			ad_org_id,
			isactive,
			created,
			createdby,
			updated,
			updatedby,
			m_offer_id,
			m_product_id
		)			
		values(
			(select get_uuid()),
			(select ad_client_id from ad_client where name = 'UW Service'),
			(select ad_org_id from ad_org where value = 'UW Service'),
			'Y',
			now(),
			'0',
			now(),
			'0',
			v_offerid,
			(select m_product_id from m_product where value = v_cur.value)
		);
	end loop;
END; 
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| UW Service Preis Staffel Import |------------------------------------------\*--
select zsi_prices_import();
drop table zsi_prices;
drop function zsi_prices_import();



