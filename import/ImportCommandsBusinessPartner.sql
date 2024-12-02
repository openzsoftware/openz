\i  /tmp/zs_import_create.sql
--\encoding ISO_8859_15
--\encoding UTF-8
copy zsi_bpartner from '/tmp/BPartner.csv' CSV DELIMITER as ';' HEADER ;

--update zsi_bpartner set language_key=a.ad_language from ad_language a  where a.countrycode=zsi_bpartner.language_key;

copy zsi_bp_contact from '/tmp/BP_Contact.csv' CSV DELIMITER as ';' HEADER ;

copy zsi_bp_location from '/tmp/BP_Location.csv' CSV DELIMITER as ';' HEADER ;

copy zsi_bp_customer from '/tmp/BP_Customer.csv' CSV DELIMITER as ';' HEADER ;

copy zsi_bp_bank from '/tmp/BP_Bank.csv' CSV DELIMITER as ';' HEADER ;

copy zsi_bp_vendor from '/tmp/BP_Vendor.csv' CSV DELIMITER as ';' HEADER ;


update  ZSI_BPARTNER  set isactive='Y' where isactive is null;
update  zsi_productbom  set isactive='Y' where isactive is null;
update  zsi_productpo  set isactive='Y' where isactive is null;
update  zsi_productprice  set isactive='Y' where isactive is null;
update  zsi_producttrl  set isactive='Y' where isactive is null;
update  zsi_bpartner  set isactive='Y' where isactive is null;
update  zsi_bp_contact  set isactive='Y' where isactive is null;
update  zsi_bp_location  set isactive='Y' where isactive is null;
update  zsi_bp_customer  set isactive='Y' where isactive is null;
update  zsi_bp_bank  set isactive='Y' where isactive is null;

update ZSI_BPARTNER set name=substr(name,1,60) where length(NAME)>60 or NAME is null;
update zsi_bp_location set postal=substr(postal,1,10) where length(postal)>10;

--delete from zsi_bpartner where value in (select value from zsi_bpartner group by value having count(*)>1) and description is null;

delete from zsi_bp_bank where iban is null and accountno is null;
update zsi_bp_bank set accountno = null where iban is not null;
update zsi_bp_bank set accountno = iban,iban=null where swiftcode is null and iban is not null;
update zsi_bp_bank set showiban='N' where iban is null;
update zsi_bp_bank set showaccountno='Y' where accountno is not null and iban is null;
update zsi_bp_bank set accountno =substr(accountno,1,20),routingno=substr(routingno,1,20);
update zsi_bp_bank set country_key=substr(iban,1,2) where iban is not null;




--update ZSI_BP_VENDOR set ISVENDOR='Y';
--update ZSI_BP_CUSTOMER set ISCUSTOMER='Y';

update ZSI_BP_LOCATION set COUNTRY_KEY=upper(COUNTRY_KEY);

\i /tmp/zs_import_bpartner.sql
update ad_preference set value='Y' where attribute='SUSPENDHISTORY';

select zsi_checkdata() ;

select  zsi_bpartnerimport('Y');

select zsi_cleanstdloc();

update ad_preference set value='N' where attribute='SUSPENDHISTORY';
