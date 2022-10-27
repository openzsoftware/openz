select zsse_dropfunction('systemconfig'); --Funktion löschen falls vorhanden

CREATE or REPLACE Function systemconfig(p_name character varying, p_lang character varying, p_email character varying, p_address character varying, p_zipcode character varying, p_city character varying, p_country character varying, p_calendar character varying, p_acctschema character varying, p_tax character varying, p_currency character varying, p_taxincluded character varying) RETURNS character varying
AS $_$ 

DECLARE
v_return character varying;
v_clientid character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_userid character varying:='DDAA21D11CB04D4D8EC59E39934B27FB';
v_orgid character varying;
v_pricelistid character varying;
v_yearid character varying;
v_date character varying;
v_year character varying;
v_periodid character varying;
v_periodno character varying;
v_locationid character varying;
v_warehouseid character varying;
v_lang character varying;
v_periodcontrolid character varying;
v_shortcut character varying:=(substr(p_name, 1, 3));
v_periodcount numeric:=0;
BEGIN
    
    v_date:=to_char(now(), 'DD-MM-YYYY'); --Aktuelles Datum in die Variable im Format DD-MM-YYYY schreiben
    v_year:=substr(v_date, 7,4); --Das aktuelle Jahr aus dem aktuellen Datum selektieren

    IF p_name IS null then
        return 'Name nicht angegeben';
    END IF;
    
    IF p_email IS null then
        return 'Email nicht angegeben';
    END IF;
    
    DELETE FROM ad_process_request; --Alle evtl. vorhandenen Prozesse löschen
    
    v_lang:=(SELECT ad_language from ad_language where ad_language_id=p_lang); --Die ausgewählte Sprache selektieren und in die Variable schreiben
    
    UPDATE ad_client SET name=p_name, value=p_name, requestemail=p_email, ad_Language='de_DE' where ad_client_id=v_clientid; --Mandant umbenennen
    
    INSERT INTO ad_org (ad_org_id, ad_client_id, createdby, updatedby, name, value, shortcut, ad_orgtype_id, isperiodcontrolallowed, c_calendar_id)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, p_name, p_name, v_shortcut, '1', 'Y', p_calendar); --Organisation anlegen

    v_orgid:=(SELECT ad_org_id FROM ad_org WHERE name=p_name); --ID von der eben angelegten Organisation selektieren und in die Variable schreiben
    
    INSERT INTO ad_org_acctschema (c_acctschema_id, ad_client_id, createdby, updatedby, ad_org_id, ad_org_acctschema_id, c_tax_id)
    VALUES (p_acctschema, v_clientid, v_userid, v_userid, v_orgid, get_uuid(), p_tax); --Kontierungsschema für die angelegte Organisation
    
    PERFORM ad_org_ready(v_orgid); --Organisation generieren
    
    v_yearid:=(SELECT c_year_id from c_year where year=v_year AND c_calendar_id=p_calendar); --Die ID des aktuellen Jahr selektieren und in die Variable schreiben
    --Wenn vorhanden

    IF v_yearid is NULL then --Abfrage ob das aktuelle Jahr vorhanden ist
        INSERT INTO c_year (c_year_id, ad_client_id, createdby, updatedby, ad_org_id, c_calendar_id, year)
        VALUES (get_uuid(), v_clientid, v_userid, v_userid, '0', p_calendar, v_year); --Anlegen des aktuellen Jahres wenn nicht vorhanden
        
        v_yearid:=(SELECT c_year_id from c_year where year=v_year AND c_calendar_id=p_calendar); --Die ID des aktuellen Jahr selektieren und in die Variable schreiben
        --Wenn nicht vorhanden und angelegt
    END IF;

    IF p_calendar = '6CEEB6AB8019483FBFAF268425053A49' then --Abfrage ob Kalender Monatsweise gewählt
        v_periodcount:=(SELECT count(c_period_id) from c_period where name=to_char(to_date(v_date),'Mon')||'-'||substr(v_year, 3,2)); --Selektieren der Periode aktuelles Jahr und aktueller Monat
        
        IF (v_periodcount=0) then --Abfrage falls Periode nicht vorhanden
            PERFORM c_yearperiods(v_yearid); --Anlegen der Perioden - Monatsweise
            PERFORM c_yearperiods(v_yearid); --Stefan fragen wieso das zweimal ausgeführt werden muss damit die Perioden Monatsweise angelegt werden
        END IF;
    ELSE --Wenn Kalender Jahresweise gewählt
        v_periodcount:=(SELECT count(c_period_id) from c_period where name=v_year); --Selektieren der Periode aktuelles Jahr
        
        IF (v_periodcount=0) then --Abfrage falls Periode nicht vorhanden
            INSERT INTO c_period (c_period_id, ad_client_id, createdby, updatedby, ad_org_id, c_year_id, periodno, name, periodtype, startdate, enddate)
            VALUES (get_uuid(), v_clientid, v_userid, v_userid, '0', v_yearid, to_number(v_year, '9999999999'), v_year, 'S', to_date('01-01-'||v_year,'DD-MM-YYYY'), to_date('31-12-'||v_year,'DD-MM-YYYY')); --Anlegen der Perioden - Jahresweise
        END IF;
    END IF;
    
    IF p_calendar = '353E5C3C74014C8EB3205779F4C2BEE8' then --Abfrage ob Kalender Jahresweise gewählt
        v_periodid:=(SELECT c_period_id from c_period where name=v_year AND periodno=to_number(v_year, '9999999999')); --Selektieren der Perioden-ID - Jahresweise und in die Variable schreiben 
    ELSE --Wenn Kalender Monatsweise gewählt
        v_periodid:=(SELECT c_period_id from c_period where name=to_char(to_date(v_date),'Mon')||'-'||substr(v_year, 3,2)); --Selektieren der Perioden-ID - Jahresweise und in die Variable schreiben
    END IF;
    
    v_periodcontrolid:=get_uuid();
    
    INSERT INTO c_periodcontrol_log (c_periodcontrol_log_id, ad_client_id, createdby, updatedby, ad_org_id, c_calendar_id, isrecursive, c_year_id, periodno, periodaction)
    VALUES (v_periodcontrolid, v_clientid, v_userid, v_userid, v_orgid, p_calendar, 'Y', v_yearid, v_periodid, 'O'); --Öffnen der Buchungsperiode für die angelegte Organisation
    
    PERFORM c_period_process(v_periodcontrolid);
    PERFORM c_period_process(v_periodcontrolid);
    
    INSERT INTO m_pricelist (m_pricelist_id, ad_client_id, createdby, updatedby, ad_org_id, name, istaxincluded, isdefault, issopricelist, c_currency_id)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, 'PL Verkauf'||' '||v_shortcut, p_taxincluded, 'Y', 'Y', p_currency); --Anlegen einer Preisliste Verkauf für die angelegte Organisation

    INSERT INTO m_pricelist (m_pricelist_id, ad_client_id, createdby, updatedby, ad_org_id, name, istaxincluded, isdefault, issopricelist, c_currency_id)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, 'PL Einkauf'||' '||v_shortcut,p_taxincluded, 'N', 'N', p_currency); --Anlegen einer Preisliste Einkauf für die angelegt Organisation
        
    v_pricelistid:=(SELECT m_pricelist_id from m_pricelist where name like '%Verkauf%' AND ad_org_id=v_orgid); --Selektieren der ID der angelegten Preisliste Verkauf
    
    INSERT INTO m_pricelist_version (m_pricelist_version_id, ad_client_id, createdby, updatedby, ad_org_id, m_pricelist_id, name, validfrom)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, v_pricelistid, 'PL Verkauf'||'-'||trunc(now()), trunc(now())); --Anlegen einer Preislisten-Version - Verkauf
    
    v_pricelistid:=(SELECT m_pricelist_id from m_pricelist where name like '%Einkauf%' AND ad_org_id=v_orgid); --Selektieren der ID der angelegten Preisliste Einkauf
    
    INSERT INTO m_pricelist_version (m_pricelist_version_id, ad_client_id, createdby, updatedby, ad_org_id, m_pricelist_id, name, validfrom)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, v_pricelistid, 'PL Einkauf'||'-'||trunc(now()), trunc(now())); --Anlegen einer Preislisten-Version - Einkauf

    INSERT INTO c_bp_group (c_bp_group_id, ad_client_id, createdby, updatedby, ad_org_id, value, name, isdefault)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, 'Allg. Geschäftspartner', 'Allg. Geschäftspartner', 'Y'); --Anlegen einer Geschäftspartnergruppe
    
    INSERT INTO m_product_category (m_product_category_id, ad_client_id, createdby, updatedby, ad_org_id, value, name, isdefault, c_tax_id)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, v_shortcut||' - '||'Standard', v_shortcut||' - '||'Standard', 'Y', p_tax); --Anlegen einer Artikelkategorie
    
    INSERT INTO c_location (c_location_id, ad_client_id, createdby, updatedby, ad_org_id, address1, city, postal, c_country_id)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, p_address, p_city, p_zipcode, p_country); --Anlegen einer Adresse

    v_locationid:=(SELECT c_location_id from c_location where address1=p_address AND ad_org_id=v_orgid); --Selektieren der ID der angelegten Adresse
    
    UPDATE ad_orginfo SET c_location_id=v_locationid, duns='0', taxid='0'; --Anlegen der Adresse in den Organisationsdetails
    
    INSERT INTO m_warehouse (m_warehouse_id, ad_client_id, createdby, updatedby, ad_org_id, name, value, separator, c_location_id)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, v_shortcut||' - '||'Lager', v_shortcut||' - '||'Lager', '*', v_locationid); --Anlegen eines Lagers

    v_warehouseid:=(SELECT m_warehouse_id from m_warehouse where ad_org_id=v_orgid); --Selektieren der ID des angelegten Lagers
    
    INSERT INTO m_locator (m_locator_id, ad_client_id, createdby, updatedby, ad_org_id, m_warehouse_id, value, priorityno, isdefault, x, y, z)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, v_warehouseid, v_shortcut||' - '||'Lagerort', 50, 'Y', '0', '0', '0'); --Anlegen eines Lagers

    INSERT INTO c_poc_configuration (c_poc_configuration_id, ad_client_id, createdby, updatedby, ad_org_id, smtpserver, smtpserveraccount, smtpserverpassword, smtpserversenderaddress, issmtpauthorization, usetls, usessl, isactive, created, updated)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, 'localhost', 'localhost', 'localhost', p_email, 'N', 'N', 'N', 'Y', trunc(now()), trunc(now())); --Anlegen der Email-Einstellungen für den Client

    INSERT INTO zspr_printinfo (zspr_printinfo_id, ad_client_id, createdby, updatedby, ad_org_id, addressheader, address1, address2, footer1)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, p_name, p_address, p_zipcode||' '||p_city, ''); --Anlegen einer Adresse in der Vorbelegung Ausdrucke
    
    INSERT INTO c_orgconfiguration (c_orgconfiguration_id, ad_client_id, createdby, updatedby, ad_org_id, isstandard)
    VALUES (get_uuid(), v_clientid, v_userid, v_userid, v_orgid, 'Y'); --Konfiguration Ausdrucke
    
    IF((SELECT count(*) FROM ad_process_request where ad_process_id='A88F2BE5BD514CDEBAF359D533E2CBF4')=0) then --Abfrage ob Prozess vorhanden
        PERFORM zsse_schedule('zsse_logclean', '4', '1', now(), 'N'); --Einplanen des Prozess falls nicht vorhanden
    END IF;
    
    IF((SELECT count(*) FROM ad_process_request where ad_process_id='BFC6D5DCB87242719FFA80E265C1DB7C')=0) then --Abfrage ob Prozess vorhanden
        PERFORM zsse_schedule('UpdateProjectStatus_BG', '2', '2', now(), 'N'); --Einplanen des Prozess falls nicht vorhanden
    END IF;
    
    IF((SELECT count(*) FROM ad_process_request where ad_process_id='7B0A43D047B640D4B150CA2EBE76466F')=0) then --Abfrage ob Prozess vorhanden
        PERFORM zsse_schedule('InOutPlanUpdate', '2', '2', now(), 'N'); --Einplanen des Prozess falls nicht vorhanden
    END IF;
    
    IF((SELECT count(*) FROM ad_process_request where ad_process_id='800170')=0) then --Abfrage ob Prozess vorhanden
        PERFORM zsse_schedule('AlertProcess', '2', '10', now(), 'N'); --Einplanen des Prozess falls nicht vorhanden
    END IF;
    
    IF((SELECT count(*) FROM ad_process_request where ad_process_id='800064')=0) then --Abfrage ob Prozess vorhanden
        INSERT INTO ad_process_request (ad_process_request_id, ad_client_id, createdby, updatedby, ad_org_id, ad_process_id, timing_option, channel)
        VALUES (get_uuid(), v_clientid, v_userid, v_userid, '0', '800064', 'I', 'Process Scheduler'); --Anlegen des Prozess falls nicht vorhanden
    END IF;
    
    UPDATE ad_role SET targetmain = '' WHERE ad_role_id = '32BB190E7B4846E8AA0F1847BD4444BE';
    UPDATE ad_role SET targetmenu = '' WHERE ad_role_id = '32BB190E7B4846E8AA0F1847BD4444BE';
    
    update c_paymentterm set documentnote=name where documentnote is null;
    update c_paymentterm_trl set documentnote=name where documentnote is null;
    
    v_return:='Ersteinrichtung erfolgreich abgeschlossen';
    
RETURN v_return;
END;
$_$  LANGUAGE 'plpgsql';
