/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): 2012-04-12 M.Hinrichs created
***************************************************************************************************************************************************
Part of SEPA-Export (remittance)
*****************************************************/
-- \..\sepa.sql

-- Verbindung Tabelle zu Triggerfunktion loeschen (Trigger-Objekt bleibt erhalten)
SELECT zsse_droptrigger('zsfi_sepa_export_data_trg', 'zsfi_sepa_export_data');
SELECT zsse_droptrigger('zsfi_sepa_export_dataline_01_trg', 'zsfi_sepa_export_dataline');
SELECT zsse_droptrigger('zsfi_sepa_export_dataline_02_trg', 'zsfi_sepa_export_dataline');

CREATE OR REPLACE FUNCTION zsfi_sepa_export_data_trg ()
RETURNS trigger AS
$BODY$
DECLARE
  v_glStatus   CHARACTER VARYING;
  v_bic        CHARACTER VARYING;
  v_GrpHdr_Nm  CHARACTER VARYING;
BEGIN
  IF AD_isTriggerEnabled() = 'N' THEN
    IF TG_OP = 'DELETE' THEN  RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;
  
  IF (TG_OP = 'INSERT') THEN
    delete from zsfi_sepa_export_dataline;
    delete from zsfi_sepa_export_data;
    SELECT cln.name
    INTO v_GrpHdr_Nm
    FROM ad_client cln, ad_org org
    WHERE 1=1
     AND cln.ad_client_id = org.ad_client_id
     AND cln.ad_client_id = new.ad_client_id;

    NEW.GrpHdr_Nm      := v_GrpHdr_Nm;
    NEW.grphdr_credttm:=REPLACE((SELECT to_char(now(), 'YYYY-MM-DD#HH24:MI:SS')),'#','T');
--  NEW.GrpHdr_NbOfTxs := 0;   -- DEFAULT=0
--  NEW.GrpHdr_CtrlSum := 0;   -- DEFAULT=0
  END IF;
  /*
  IF (TG_OP = 'UPDATE') OR (TG_OP = 'INSERT') THEN
    SELECT glstatus INTO v_glStatus FROM zsfi_sepa_export_data WHERE zsfi_sepa_export_data_id = NEW.zsfi_sepa_export_data_id;
    IF (TG_OP = 'UPDATE') THEN
       -- Cancelling Lines with a process is allowed on Posted Lines
       IF (NEW.glstatus = 'CA' AND OLD.glstatus = 'PO') THEN
          v_glStatus = 'OP';
       END IF;
    END IF;
  END IF;
  IF (TG_OP = 'DELETE') THEN
     SELECT glstatus INTO v_glStatus FROM zsfi_sepa_export_data WHERE zsfi_sepa_export_data_id = old.zsfi_sepa_export_data_id;
  END IF;
  */
  IF v_glStatus <> 'OP' then
      RAISE EXCEPTION '%', '@zsfi_NotOpenMacct@' ; -- ??
      RETURN OLD;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE COST 100;

CREATE TRIGGER zsfi_sepa_export_data_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON zsfi_sepa_export_data FOR EACH ROW
  EXECUTE PROCEDURE zsfi_sepa_export_data_trg();


CREATE OR REPLACE FUNCTION zsfi_sepa_export_dataline_01_trg ()
RETURNS trigger AS
$BODY$
DECLARE
  v_glStatus             CHARACTER VARYING;

  v_PmtInf_Dbtr_Nm       CHARACTER VARYING;
  v_PmtInf_DbtrAcct_IBAN CHARACTER VARYING;
  v_PmtInf_DbtrAgt_BIC   CHARACTER VARYING;

  v_NbOfTxs              NUMERIC;
  v_CtrlSum              NUMERIC;

  v_CdtrAgt_BIC          CHARACTER VARYING;
  v_Cdtr_Nm              CHARACTER VARYING;
  v_CdtrAcct_IBAN        CHARACTER VARYING;
  v_count numeric;
  v_curr varchar;
BEGIN
  IF AD_isTriggerEnabled() = 'N' THEN
    IF TG_OP = 'DELETE' THEN  RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT') THEN
   -- Daten fuer Auftraggeber ermitteln
   SELECT
     -- cln.ad_client_id,
     zssi_cleanasciistring(org.name) AS Dbtr_Nm, bacc.iban AS DbtrAcct_IBAN, c_bank.swiftcode AS DbtrAgt_BIC,c.iso_code
    INTO  v_PmtInf_Dbtr_Nm,   v_PmtInf_DbtrAcct_IBAN,            v_PmtInf_DbtrAgt_BIC,v_curr
    FROM  ad_org org, c_bank, c_bankaccount bacc,c_currency c
    WHERE bacc.c_bank_id = c_bank.c_bank_id
     AND bacc.c_currency_id=c.c_currency_id
     AND bacc.c_bankaccount_id = new.c_bankaccount_id   -- 'SEPA_C_BANKACCOUNT_ID_0000000000'
     AND org.ad_org_id = new.ad_org_id;           -- 'C726FEC915A54A0995C568555DA5BB3C'

    IF isEmpty(v_PmtInf_Dbtr_Nm) THEN
      RAISE EXCEPTION '%', 'Name fuer Auftraggeber (' || (select name from c_bank,c_bankaccount where c_bank.c_bank_id=c_bankaccount.c_bank_id limit 1) || ') nicht gefunden.';
    END IF;
    IF isEmpty(v_PmtInf_DbtrAcct_IBAN) THEN
      RAISE EXCEPTION '%', 'IBAN fuer Auftraggeber (' ||  v_PmtInf_Dbtr_Nm||', Bank: '|| (select name from c_bank,c_bankaccount where c_bank.c_bank_id=c_bankaccount.c_bank_id limit 1) || ') nicht gefunden.';
    END IF;
    IF isEmpty(v_PmtInf_DbtrAgt_BIC) THEN
      RAISE EXCEPTION '%', 'BIC fuer Auftraggeber (' ||  v_PmtInf_Dbtr_Nm||', Bank: '|| (select name from c_bank,c_bankaccount where c_bank.c_bank_id=c_bankaccount.c_bank_id limit 1)  || ') nicht gefunden.';
    END IF;

    -- Daten fuer Ueberweisungs-Empfaenger ermitteln
    SELECT
   -- bpacc.c_bp_bankaccount_id, bp.c_bpartner_id,
       bpacc.swiftcode,   zssi_cleanasciistring(coalesce(bpacc.a_name,bp.name)),      bpacc.iban
    INTO v_CdtrAgt_BIC, v_Cdtr_Nm, v_CdtrAcct_IBAN
    FROM c_bp_bankaccount bpacc, c_bpartner bp
    WHERE 1=1
     AND bpacc.c_bpartner_id = bp.c_bpartner_id
     AND bpacc.c_bp_bankaccount_id = new.c_bp_bankaccount_id;  -- 'SEPA_c_bp_bankaccount_id_0000002';

    IF isEmpty(new.c_bp_bankaccount_id) THEN
      RAISE EXCEPTION '%', 'Keine Bankverbindung fuer Ueberweisungs-Empfaenger vorhanden.';
    END IF;
    IF isEmpty(v_CdtrAgt_BIC) THEN
      RAISE EXCEPTION '%', 'BIC fuer Ueberweisungs-Empfaenger ' || COALESCE(v_Cdtr_Nm, 'Ueberweisungs-Empfaenger') || ' nicht gefunden.';
    END IF;
    IF isEmpty(v_Cdtr_Nm) THEN
      RAISE EXCEPTION '%', 'Name fuer Ueberweisungs-Empfaenger ' || COALESCE(v_Cdtr_Nm, 'Ueberweisungs-Empfaenger') || ' nicht gefunden.';
    END IF;
    IF isEmpty(v_CdtrAcct_IBAN) THEN
      RAISE EXCEPTION '%', 'IBAN-Konto fuer Ueberweisungs-Empfaenger ' || COALESCE(v_Cdtr_Nm, 'Ueberweisungs-Empfaenger') || ' nicht gefunden.';
    END IF;

    NEW.PmtInf_Dbtr_Nm       := v_PmtInf_Dbtr_Nm;
    NEW.PmtInf_DbtrAcct_IBAN := v_PmtInf_DbtrAcct_IBAN;
    NEW.PmtInf_DbtrAgt_BIC   := v_PmtInf_DbtrAgt_BIC;
    NEW.CdtrAgt_BIC          := v_CdtrAgt_BIC;
    NEW.Cdtr_Nm              := v_Cdtr_Nm;
    NEW.CdtrAcct_IBAN        := v_CdtrAcct_IBAN;
    NEW.currencyISO          := v_curr;
  END IF;

  /*
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
    SELECT glstatus INTO v_glStatus FROM zsfi_sepa_export_dataline WHERE zsfi_sepa_export_dataline_id = NEW.zsfi_sepa_export_dataline_id;
    IF (TG_OP = 'UPDATE') THEN
       -- Cancelling Lines with a process is allowed on Posted Lines
       IF (NEW.glstatus = 'CA' AND OLD.glstatus = 'PO') THEN
          v_glStatus = 'OP';
       END IF;
    END IF;
  END IF;
  */
  IF (TG_OP = 'DELETE') THEN
     SELECT glstatus INTO v_glStatus FROM zsfi_sepa_export_dataline WHERE zsfi_sepa_export_dataline_id = old.zsfi_sepa_export_dataline_id;
  END IF;
  IF v_glStatus <> 'OP' then
      RAISE EXCEPTION '%', '@zsfi_NotOpenMacct@' ; -- ??
      RETURN OLD;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE COST 100;

CREATE TRIGGER zsfi_sepa_export_dataline_01_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON zsfi_sepa_export_dataline FOR EACH ROW
  EXECUTE PROCEDURE zsfi_sepa_export_dataline_01_trg();


CREATE OR REPLACE FUNCTION zsfi_sepa_export_dataline_02_trg ()
RETURNS trigger AS
$BODY$
DECLARE
-- SELECT zsse_droptrigger('zsfi_sepa_export_dataline_02_trg', 'zsfi_sepa_export_dataline');
  v_glStatus             CHARACTER VARYING;
  v_export_data_id       CHARACTER VARYING;
  v_NbOfTxs              NUMERIC;
  v_CtrlSum              NUMERIC;
BEGIN
 -- AFTER-TIGGER: Zaehlen und Aufsummieren aller export_dataline in export_data
  IF AD_isTriggerEnabled() = 'N' THEN
    IF TG_OP = 'DELETE' THEN  RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
    SELECT glstatus, zsfi_sepa_export_data_id
    INTO v_glStatus, v_export_data_id
    FROM zsfi_sepa_export_data WHERE zsfi_sepa_export_data_id = new.zsfi_sepa_export_data_id;
  END IF;

  IF (TG_OP = 'DELETE') THEN
    SELECT glstatus, zsfi_sepa_export_data_id
    INTO v_glStatus, v_export_data_id
    FROM zsfi_sepa_export_data WHERE zsfi_sepa_export_data_id = old.zsfi_sepa_export_data_id;
  END IF;

  IF (v_glStatus <> 'OP') then
      RAISE EXCEPTION '%', '@zsfi_NotOpenMacct@' ; -- ??
      RETURN OLD;
  END IF;

  SELECT
    COUNT(*) AS NbOfTxs, SUM(amt_instdamt) AS CtrlSum
  INTO v_NbOfTxs, v_CtrlSum
  FROM zsfi_sepa_export_dataline dataline WHERE dataline.zsfi_sepa_export_data_id = v_export_data_id;

  UPDATE zsfi_sepa_export_data
  SET
    GrpHdr_NbOfTxs = v_NbOfTxs,
    GrpHdr_CtrlSum = COALESCE(v_CtrlSum, 0)
  WHERE
    zsfi_sepa_export_data.zsfi_sepa_export_data_id = v_export_data_id;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE COST 100;

CREATE TRIGGER zsfi_sepa_export_dataline_02_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON zsfi_sepa_export_dataline FOR EACH ROW
  EXECUTE PROCEDURE zsfi_sepa_export_dataline_02_trg();


CREATE or replace FUNCTION zsfi_sepa_export_remittance (
  p_zsfi_sepa_export_data_id   CHARACTER VARYING             -- 'ZSFI_SEPA_EXPORT_DATA_ID_0000001'
)
RETURNS CHARACTER varying
AS $BODY_$
-- SELECT zsfi_sepa_export_remittance('ZSFI_SEPA_EXPORT_DATA_ID_0000001')      as plresult from dual; -- Stapel-ID fuer Ueberweisung
DECLARE
  v_outputFile     VARCHAR;
  v_outputPath     VARCHAR;
  v_now            TIMESTAMP;      -- Ausfuerungsdatum aus now()
  v_fileDateTime   VARCHAR;        -- Ausfuerungsdatum 'YYYYMMDD_HHMMSS'

  v_MsgId          VARCHAR;        -- generierte Identifikation zur Vermeidung von Doppelverarbeitung bei Kreditinstitut
  v_GrpHdr_CreDtTm VARCHAR;        -- SEPA-Datei Erstellungsdatum
  v_GrpHdr_Nm      VARCHAR;        -- Auftraggeber-Name
  v_DbtrAgt_BIC    VARCHAR;

  i                INTEGER := 0;
  j                INTEGER := 0;
  v_GrpHdr_NbOfTxs INTEGER := 0;
  v_GrpHdr_CtrlSum NUMERIC := 0.00;

  v_cmd            VARCHAR := '';
  v_message        VARCHAR := '';
  v_messArray      VARCHAR[];      -- dyn. erweiterbares Array
  v_anzError       INTEGER := 0;   -- Überschrift für Fehlermeldung = v_messArray[0]

  v_PmtInf         VARCHAR[];
  v_CdtTrfTxInf    VARCHAR[];
BEGIN
  v_messArray[v_anzError] := 'SQL: SELECT zsfi_sepa_export_remittance(' || '''' || p_zsfi_sepa_export_data_id || ''')';

  v_now := now();
  v_GrpHdr_CreDtTm := REPLACE((SELECT to_char(v_now, 'YYYY-MM-DD#HH24:MI:SSZ')),'#','T');  -- StarMoney50 mit ending-'Z'
  v_fileDateTime := (SELECT to_char(v_now, 'YYYYMMDD_HH24MISS'));                      --'YYYYMMDD_HH24MISS'

  TRUNCATE TABLE zsfi_sepa_export_xml;

  -- Kopfdaten <GrpHdr> ermitteln
  SELECT
    GrpHdr_MsgId,   GrpHdr_NbOfTxs,   GrpHdr_CtrlSum, TRIM(SUBSTR(GrpHdr_Nm, 1, 70))
  INTO   v_MsgId, v_GrpHdr_NbOfTxs, v_GrpHdr_CtrlSum,           v_GrpHdr_Nm
  FROM zsfi_sepa_export_data sepadata
  WHERE 1=1
   AND sepadata.zsfi_sepa_export_data_id = p_zsfi_sepa_export_data_id
   AND sepadata.glstatus = 'OP'        -- '/tmp/sepa_export_remittance.xml' noch nicht erstellt
   AND sepadata.documentno IS NULL;    -- Dokument-Nummer noch nicht generiert

  v_outputPath:='/tmp/';
  v_outputFile := 'SEPA_CT_' || 'V27_' || v_fileDateTime || '.xml';

  IF (isempty(v_MsgId)) THEN
    v_message := 'Tabelle ''zsfi_sepa_export_data_v'': Feld ''GrpHdr_MsgId'' fuer Auftraggeber ist leer';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_GrpHdr_CreDtTm)) THEN
    v_message := 'Erstellungsdatum (GrpHdr_CreDtTm) für SEPA-Ueberweisungen konnte nicht generiert werden';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (v_GrpHdr_NbOfTxs = 0) THEN
    v_message := 'Tabelle ''zsfi_sepa_export_dataline'': Keine Datenzeilen (Ueberweisungen) gefunden';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (v_GrpHdr_CtrlSum = 0) THEN
    v_message := 'Tabelle ''zsfi_sepa_export_dataline'': Summe der Ueberweisungen ist 0,00';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
--IF (isempty(v_dbtracct_bic)) THEN
--  v_message := 'Tabelle ''zsfi_sepa_export_data_v'': Feld ''BIC'' fuer Auftraggeber ist leer';
--  v_anzError := v_anzError + 1;
--  v_messArray[v_anzError] := v_message;
--END IF;
  IF (isempty(v_GrpHdr_Nm)) THEN
    v_message := 'Tabelle ''zsfi_sepa_export_data_v'': Feld ''Name'' fuer Auftraggeber ist leer';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_fileDateTime)) THEN
    v_message := 'Zeitstempel für SEPA-Ueberweisungen konnte nicht generiert werden ';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_outputFile)) THEN
    v_message := 'Dateiname für SEPA-Ueberweisungen konnte nicht generiert werden';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;

  -- wenn noch kein Fehler in gefunden
  IF (v_anzError = 0) THEN
    -- Ausgabe CCT Credit Transfer Initiation urn:iso:std:iso:20022:tech:xsd:pain.001.002.03 pain.001.002.03.xsd
    -- 001=ISO
    -- 002=mittleren Nummernblock der Namespaces und Namen der Schemadateien
    -- 03=Credit Transfer Initiation: Ueberweisungen / Gutschriften an Kreditoren
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<?xml version="1.0" encoding="UTF-8"?>');
   --INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.003.03" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.001.003.03 pain.001.003.03.xsd">');
   INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.003.03">');
-- wg StarMoney50 001.001.02
    --INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Document xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.001.003.03 pain.001.003.03.xsd">');
    --INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<pain.001.003.03>');                              -- wg StarMoney50 aktiviert

    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<CstmrCdtTrfInitn>');

   -- 1/3 Credit Transfer Initiation = Group Header
   -- Kenndaten, die für alle Transaktionen innerhalb der SEPA-Nachricht gelten
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<GrpHdr>');

    -- Die <MsgID> in Kombination mit der Kunden-ID oder der Auftraggeber- IBAN kann als Kriterium für die Verhinderung einer
    -- Doppelverarbeitung bei versehentlich doppelt eingereichten Dateien dienen und muss somit für jede neue pain- Nachricht
    -- einen neuen Wert enthalten.
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<MsgId>'   || v_MsgId || '</MsgId>');   -- ZKA 'CCTI/VRNWSW/8c2df6ab9568f240ac9020c'
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<CreDtTm>' || v_GrpHdr_CreDtTm || '</CreDtTm>');  -- YYYY-MM-DDTHH24:MI:SSZ ??
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<NbOfTxs>' || v_GrpHdr_NbOfTxs || '</NbOfTxs>');  -- Anzahl Datenzeilen
    --INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<CtrlSum>' || v_GrpHdr_CtrlSum || '</CtrlSum>');  -- max. zwei Nachkomma-St
    --INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Grpg>GRPD</Grpg>');  -- StarMoney50
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<InitgPty>');                                     -- Auftraggeber
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Nm>'      || v_GrpHdr_Nm || '</Nm>');            -- Empfehlung: nur Name verwendenden
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</InitgPty>');
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</GrpHdr>');

   -- 3/3: Credit Transfer Initiation = Transaction Information 1..n / max:9.999.999
   DECLARE
      CUR_export RECORD;
   BEGIN
      i := 0;
      FOR CUR_export IN (
         SELECT
           d.*,
           PmtInf_PmtInfId,      -- VARCHAR(70) NOT NULL,
           PmtInf_ReqdExctnDt,   -- DATE NOT NULL,
           TRIM(SUBSTR(PmtInf_Dbtr_Nm, 1, 70))       AS PmtInf_Dbtr_Nm,       -- VARCHAR(70) NOT NULL,
           TRIM(SUBSTR(PmtInf_DbtrAcct_IBAN, 1, 34)) AS PmtInf_DbtrAcct_IBAN, -- VARCHAR(34) NOT NULL
           TRIM(SUBSTR(PmtInf_DbtrAgt_BIC, 1, 34))   AS PmtInf_DbtrAgt_BIC,   -- VARCHAR(11) NOT NULL

           TRIM(SUBSTR(PmtId_EndToEndId, 1, 34)) AS PmtId_EndToEndId, -- VARCHAR(34),
           Amt_InstdAmt,         -- NUMERIC(11,2) NOT NULL,
           TRIM(SUBSTR(CdtrAgt_BIC, 1, 11))      AS CdtrAgt_BIC,      -- VARCHAR(11) NOT NULL,
           TRIM(SUBSTR(Cdtr_Nm, 1, 70))          AS Cdtr_Nm,          -- VARCHAR(70) NOT NULL,
           TRIM(SUBSTR(CdtrAcct_IBAN, 1, 34))    AS CdtrAcct_IBAN,    -- VARCHAR(34) NOT NULL,
           TRIM(SUBSTR(replace(RmtInf_Ustrd,'&',' '), 1, 140))    AS RmtInf_Ustrd,      -- VARCHAR(140) NOT NULL,
            dataline.currencyISO
        FROM zsfi_sepa_export_data d, zsfi_sepa_export_dataline dataline
        WHERE 1=1
         AND  d.zsfi_sepa_export_data_id = dataline.zsfi_sepa_export_data_id
         AND  d.zsfi_sepa_export_data_id = p_zsfi_sepa_export_data_id
         AND (dataline.Amt_InstdAmt >= 0.01) AND (dataline.Amt_InstdAmt <= 999999999.99)
   --???      AND  dataline.   = p_abic
        )
   LOOP
        i := i + 1;
        if i=1 then -- Absender-Konto nur 1 mal....
            -- 2/3: Credit Transfer Initiation = Payment Instruction Information 1..n / max:9.999.999
            -- Satz von Angaben (z. B. Auftraggeberkonto, Ausführungstermin), welcher für alle Einzeltransaktionen
            -- gilt. Entspricht einem logischen Sammler innerhalb einer physikalischen Datei.
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<PmtInf>');
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<PmtInfId>' || CUR_export.PmtInf_PmtInfId || '</PmtInfId>'); -- Referenz zur eindeutigen Identifizierung des Sammlers -- CCTI/VRNWSW/9/cf22f9ae9669f2473c078
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<PmtMtd>TRF</PmtMtd>');              -- Zahlungsinstrument, Konstante 'TRF'
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<BtchBookg>true</BtchBookg>');       -- Sammelbuchung='true', Einzelbuchung='false' DB?? wg StarMoney50 deaktiviert
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<NbOfTxs>' || v_GrpHdr_NbOfTxs || '</NbOfTxs>');  -- Anzahl Datenzeilen
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<CtrlSum>' || v_GrpHdr_CtrlSum || '</CtrlSum>');  -- max. zwei Nachkomma-St
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<PmtTpInf>');                        -- wg StarMoney50
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<SvcLvl>');                          -- wg StarMoney50
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Cd>SEPA</Cd>');                     -- wg StarMoney50
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</SvcLvl>');                         -- wg StarMoney50
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</PmtTpInf>');                       -- wg StarMoney50

            -- sofern kein gültger Geschäftstag angegeben wurde, durch das überweisende
            -- Kreditinstitut auf den nächsten Geschäftstag umgesetzt
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<ReqdExctnDt>'|| to_char(CUR_export.PmtInf_ReqdExctnDt, 'YYYY-MM-DD') || '</ReqdExctnDt>'); -- Ausführungstermin

            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Dbtr>'); -- Zahler (Auftraggeber)
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Nm>' ||  CUR_export.PmtInf_Dbtr_Nm || '</Nm>');  -- 'Debtor Name'
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</Dbtr>');

            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<DbtrAcct>');                             -- Konto des Zahlers(Auftraggebers) ??CUR_export.Cdtr_Nm
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Id>');
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<IBAN>' || CUR_export.PmtInf_DbtrAcct_IBAN || '</IBAN>'); --
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</Id>');
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</DbtrAcct>');

            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<DbtrAgt>'); -- Institut des Zahlungspflichtigen
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<FinInstnId>');
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<BIC>' || CUR_export.PmtInf_DbtrAgt_BIC || '</BIC>');
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</FinInstnId>');
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</DbtrAgt>');
            INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<ChrgBr>SLEV</ChrgBr>');   -- ChargeBearer=Entgeltverrechnung, recommended StarMoney50 reaktiviert
         end if;

   -- Empfaenger-Informationen
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<CdtTrfTxInf>');  -- Maximale Anzahl Wiederholungen=9.999.999
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<PmtId>');        -- PaymentIdentificationSEPA
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<EndToEndId>' || CUR_export.PmtId_EndToEndId || '</EndToEndId>'); -- 'OriginatorID1235', 'OriginatorID1234'
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</PmtId>');

      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Amt>');          -- AmountTypeSEPA
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<InstdAmt Ccy="'||CUR_export.currencyISO||'">' || CUR_export.Amt_InstdAmt || '</InstdAmt>'); -- beauftragter Betrag '999.99'
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</Amt>');

      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<CdtrAgt>');  -- BranchAndFinancialInstitutionIdentificationSEPA1
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<FinInstnId>');
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<BIC>' || CUR_export.CdtrAgt_BIC || '</BIC>'); --Business Identifier Code, max 11 Stellen
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</FinInstnId>');
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</CdtrAgt>');

      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Cdtr>'); -- Zahlungsempfaenger
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Nm>' || CUR_export.Cdtr_Nm || '</Nm>'); -- max 70 Stellen
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</Cdtr>');

      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<CdtrAcct>'); -- CashAccountSEPA2
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Id>');
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<IBAN>' || CUR_export.CdtrAcct_IBAN || '</IBAN>'); -- Kreditinstitut des Zahlungsempfängers
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</Id>');
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</CdtrAcct>');

      -- Vermögenswirksame Leistungen : Feldgruppe <Purp><cd></cd></Purp> nicht verwendet, da optional

      -- Verwendungszweck
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<RmtInf>');
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('<Ustrd>' || CUR_export.RmtInf_Ustrd || '</Ustrd>'); -- unstrukturiert
      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</RmtInf>');

      INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</CdtTrfTxInf>');
      
   END LOOP;
   END;
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</PmtInf>');
    --INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</pain.001.003.03>');   -- wg StarMoney50 aktiviert
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</CstmrCdtTrfInitn>');  -- wg StarMoney50 deaktiviert
    INSERT INTO zsfi_sepa_export_xml (daten) VALUES ('</Document>');

    v_cmd := 'COPY (SELECT daten FROM zsfi_sepa_export_xml ORDER BY zsfi_sepa_export_xml_id) TO ' || '''' || v_outputPath||v_outputFile || '''';
    EXECUTE(v_cmd);

    v_message := v_outputFile;
    RAISE NOTICE '%', v_message;
    RETURN v_outputFile;

  END IF; -- (v_anzError = 0)

  -- wenn Fehler gefunden, Exception provozieren für Ausgabe Fehlermeldungen
  IF (v_anzError > 0 ) THEN
    RAISE EXCEPTION '%', 'SEPA-Ueberweisungdatei aufgrund von ' || v_anzError || ' Fehler nicht erstellt.'; -- > Exception-Handling
  ELSE
    v_message := 'SUCCESS - SEPA-Ueberweisungdatei: ' || v_outputFile || ' erstellt ' || ' - ' ||  i || ' Ueberweisung(en) ausgegeben.';
    RAISE NOTICE '%', v_message;
    RETURN v_message;
  END IF;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;

   -- Fehlermeldungen ausgeben
    j := 0;
    LOOP
      IF (v_messArray[j] IS NOT NULL) THEN
        -- RAISE NOTICE '%', v_messArray[j];
        v_message := v_message || '</br>' || v_messArray[j];
      ELSE
        EXIT;
      END IF;
      j := j + 1;
    END LOOP;
    RAISE NOTICE '%', replace(v_message,'</br>',E'\r\n');
--  v_message := '@ERROR=' || SQLERRM;
    RETURN v_message;

END;
$BODY_$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

SELECT zsse_droptrigger('zsfi_sepa_debit_data_trg', 'zsfi_sepa_debit_data');
SELECT zsse_droptrigger('zsfi_sepa_debit_dataline_01_trg', 'zsfi_sepa_debit_dataline');
SELECT zsse_droptrigger('zsfi_sepa_debit_dataline_02_trg', 'zsfi_sepa_debit_dataline');

CREATE OR REPLACE FUNCTION zsfi_sepa_debit_data_trg ()
RETURNS trigger AS
$BODY$
DECLARE
  v_grphdr_InitgPty_Nm CHARACTER VARYING;
  v_pmtinf_CdtrAcct_IBAN CHARACTER VARYING;
  v_pmtinf_CdtrAgt_BIC CHARACTER VARYING;
  v_pmtinf_CdtrSchmeId_id CHARACTER VARYING;
  v_curr varchar;
BEGIN
  IF AD_isTriggerEnabled() = 'N' THEN
    IF TG_OP = 'DELETE' THEN  RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;
  
  IF (TG_OP = 'INSERT') THEN
    DELETE FROM zsfi_sepa_debit_dataline;
    DELETE FROM zsfi_sepa_debit_data;
  -- get creditor banking information
    SELECT bacc.iban, bacc.cdtrschmeident, bank.swiftcode,c.iso_code
    INTO v_pmtinf_CdtrAcct_IBAN, v_pmtinf_CdtrSchmeId_id, v_pmtinf_CdtrAgt_BIC,v_curr
    FROM c_bankaccount bacc, c_bank bank, c_currency c
    WHERE 1=1
     AND bacc.c_bank_id = bank.c_bank_id
     AND bacc.c_currency_id=c.c_currency_id
     AND bacc.c_bankaccount_id = NEW.c_bankaccount_id; -- '5A53F81AB7F94DDB906FCD491510D487'
     IF (isempty(v_pmtinf_CdtrAcct_IBAN)) THEN
       RAISE EXCEPTION '%', '@sepa_missing_pmtinf_CdtrAcct_IBAN@';
     END IF;
     IF (isempty(v_pmtinf_CdtrSchmeId_id)) THEN
       RAISE EXCEPTION '%', '@sepa_missing_pmtinf_CdtrSchmeId@';
     END IF;
     IF (isempty(v_pmtinf_CdtrAgt_BIC)) THEN
       RAISE EXCEPTION '%', '@sepa_missing_pmtinf_CdtrAgt_BIC@';
     END IF;
     
  -- get creditor name information
    SELECT cln.name
    INTO v_grphdr_InitgPty_Nm
    FROM ad_client cln, ad_org org
    WHERE 1=1
     AND cln.ad_client_id = org.ad_client_id
     AND cln.ad_client_id = new.ad_client_id;

    NEW.grphdr_InitgPty_Nm      := v_grphdr_InitgPty_Nm;
    NEW.grphdr_credttm := REPLACE((SELECT to_char(now(), 'YYYY-MM-DD#HH24:MI:SS')),'#','T');
    IF (NEW.pmtInf_ReqdColltnDt <= now() ) THEN
      NEW.pmtInf_ReqdColltnDt := now() + 2;
    END IF; 
    NEW.pmtinf_CdtrAgt_BIC := v_pmtinf_CdtrAgt_BIC;
    NEW.pmtinf_CdtrAcct_IBAN := v_pmtinf_CdtrAcct_IBAN; 
    NEW.pmtinf_CdtrSchmeId_id := v_pmtinf_CdtrSchmeId_id; -- -- Creditor RefID, Empfaenger Glaeubiger-ID
    NEW.currencyISO          := v_curr;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE COST 100;

CREATE TRIGGER zsfi_sepa_debit_data_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON zsfi_sepa_debit_data FOR EACH ROW
  EXECUTE PROCEDURE zsfi_sepa_debit_data_trg();


SELECT zsse_droptrigger('zsfi_sepa_debit_dataline_01_trg', 'zsfi_sepa_debit_dataline');
CREATE OR REPLACE FUNCTION zsfi_sepa_debit_dataline_01_trg ()
RETURNS trigger AS
$BODY$
DECLARE
-- SELECT zsse_droptrigger('zsfi_sepa_debit_dataline_01_trg', 'zsfi_sepa_debit_dataline');
  v_glStatus              CHARACTER VARYING;

  v_PmtInf_Dbtr_Nm        CHARACTER VARYING;
  v_PmtInf_DbtrAcct_IBAN  CHARACTER VARYING;
  v_PmtInf_DbtrAgt_BIC    CHARACTER VARYING;
  v_bp_bankaccount_id     CHARACTER VARYING;
  v_drctDbtTx_DbtrAgt_BIC CHARACTER VARYING;
  v_drctDbtTx_Dbtr_Nm     CHARACTER VARYING;
  v_drctDbtTx_DbtrAcct_IBAN CHARACTER VARYING;

  v_MndtId                CHARACTER VARYING;
  v_DtOfSgntr             CHARACTER VARYING;
  v_count                 NUMERIC;
BEGIN
-- BEFORE-TIGGER: Ermittlung der Stammdaten fuer IBAN, BIC, DebtorName
  IF AD_isTriggerEnabled() = 'N' THEN
    IF TG_OP = 'DELETE' THEN  RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT') THEN
    -- Daten fuer Bezogenen ermitteln
    SELECT
       bpacc.swiftcode 
     , replace(zssi_cleanasciistring(coalesce(bpacc.a_name,bp.name)),'&amp;','u.')
     , bpacc.iban
     , bpacc.MndtIdent  -- COALESCE(NULL, 'MndtIdent') AS MndtId
     , bpacc.DtOfSgntr  -- COALESCE(NULL, (SELECT to_char(now(), 'YYYY-MM-DD'))) AS DtOfSgntr
     , bpacc.c_bp_bankaccount_id
    INTO v_drctDbtTx_DbtrAgt_BIC, v_drctDbtTx_Dbtr_Nm, v_drctDbtTx_DbtrAcct_IBAN, v_MndtId, v_DtOfSgntr, v_bp_bankaccount_id
    FROM c_bp_bankaccount bpacc, c_bpartner bp
    WHERE 1=1
     AND bpacc.c_bpartner_id = bp.c_bpartner_id
     AND bpacc.c_bp_bankaccount_id = new.c_bp_bankaccount_id;  -- 'SEPA_c_bp_bankaccount_id_0000002';

    IF isEmpty(v_bp_bankaccount_id) THEN -- 01-08-2014
      RAISE EXCEPTION '% %', 'Keine Bankverbindung fuer Lastschrift-Bezogenen vorhanden.', 'p_bp_bankaccount_id=''' || new.c_bp_bankaccount_id || '''';
    END IF;
    
    IF isEmpty(v_drctDbtTx_DbtrAgt_BIC) THEN
      RAISE EXCEPTION '%', 'BIC fuer ' || COALESCE(v_drctDbtTx_Dbtr_Nm, 'Lastschrift-Bezogenen') || ' nicht gefunden.';
    END IF;
    IF isEmpty(v_drctDbtTx_Dbtr_Nm) THEN
      RAISE EXCEPTION '%', 'Name fuer ' || COALESCE(v_drctDbtTx_Dbtr_Nm, 'Lastschrift-Bezogenen') || ' nicht gefunden.';
    END IF;
    IF isEmpty(v_drctDbtTx_DbtrAcct_IBAN) THEN
      RAISE EXCEPTION '%', 'IBAN fuer ' || COALESCE(v_drctDbtTx_Dbtr_Nm, 'Lastschrift-Bezogenen') || ' nicht gefunden.';
    END IF;
    IF isEmpty(v_MndtId) THEN
      RAISE EXCEPTION '%', 'Mandatsreferenz fuer ' || COALESCE(v_drctDbtTx_Dbtr_Nm, 'Lastschrift-Bezogenen') || ' nicht gefunden.';
    END IF;
    NEW.drctDbtTx_MndtId        := v_MndtId;
    NEW.drctDbtTx_DtOfSgntr     := v_DtOfSgntr;
    NEW.drctDbtTx_Dbtr_Nm       := v_drctDbtTx_Dbtr_Nm;
    NEW.drctDbtTx_DbtrAcct_IBAN := v_drctDbtTx_DbtrAcct_IBAN;
    NEW.drctDbtTx_DbtrAgt_BIC   := v_drctDbtTx_DbtrAgt_BIC;
    select pmtinf_reqdcolltndt into NEW.reqdcolltndt from zsfi_sepa_debit_data where zsfi_sepa_debit_data_id=new.zsfi_sepa_debit_data_id;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE COST 100;

CREATE TRIGGER zsfi_sepa_debit_dataline_01_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON zsfi_sepa_debit_dataline
  FOR EACH ROW
  EXECUTE PROCEDURE zsfi_sepa_debit_dataline_01_trg();

  
SELECT zsse_droptrigger('zsfi_sepa_debit_dataline_02_trg', 'zsfi_sepa_debit_dataline');
CREATE OR REPLACE FUNCTION zsfi_sepa_debit_dataline_02_trg ()
RETURNS trigger AS
$BODY$
DECLARE
-- SELECT zsse_droptrigger('zsfi_sepa_debit_dataline_02_trg', 'zsfi_sepa_debit_dataline');
  v_glStatus             CHARACTER VARYING;
  v_debit_data_id        CHARACTER VARYING;
  v_NbOfTxs              NUMERIC;
  v_CtrlSum              NUMERIC;
  v_updatedBy            CHARACTER VARYING;
BEGIN
 -- AFTER-TRIGGER: Zaehlen und Aufsummieren aller dataline (Detail) in data (Header)
  IF AD_isTriggerEnabled() = 'N' THEN
    IF TG_OP = 'DELETE' THEN  RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
    SELECT glstatus, zsfi_sepa_debit_data_id
    INTO v_glStatus, v_debit_data_id
    FROM zsfi_sepa_debit_data WHERE zsfi_sepa_debit_data_id = NEW.zsfi_sepa_debit_data_id;
    v_updatedBy = NEW.updatedBy;
  END IF;

  IF (TG_OP = 'DELETE') THEN
    SELECT glstatus, zsfi_sepa_debit_data_id
    INTO v_glStatus, v_debit_data_id
    FROM zsfi_sepa_debit_data WHERE zsfi_sepa_debit_data_id = old.zsfi_sepa_debit_data_id;
    v_updatedBy = CURRENT_USER;
  END IF;

  IF (v_glStatus <> 'OP') then
    RAISE EXCEPTION '%', '@zsfi_NotOpenMacct@' ; -- ??
    RETURN OLD;
  END IF;

  SELECT
    COUNT(*) AS NbOfTxs, SUM(drctdbttx_instdamt) AS CtrlSum
  INTO v_NbOfTxs, v_CtrlSum
  FROM zsfi_sepa_debit_dataline dataline WHERE dataline.zsfi_sepa_debit_data_id = v_debit_data_id;

  UPDATE zsfi_sepa_debit_data
  SET
    GrpHdr_NbOfTxs = v_NbOfTxs,
    GrpHdr_CtrlSum = COALESCE(v_CtrlSum, 0),
    updated = now(),
    updatedBy = v_updatedBy
  WHERE
    zsfi_sepa_debit_data.zsfi_sepa_debit_data_id = v_debit_data_id;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE COST 100;

CREATE TRIGGER zsfi_sepa_debit_dataline_02_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON zsfi_sepa_debit_dataline
  FOR EACH ROW
  EXECUTE PROCEDURE zsfi_sepa_debit_dataline_02_trg();


CREATE or replace FUNCTION zsfi_sepa_export_debit (
  p_zsfi_sepa_debit_data_id   CHARACTER VARYING             -- 'ZSFI_SEPA_DEBIT_DATA_01_0000001'
)
RETURNS CHARACTER varying
AS $_$
-- SELECT zsfi_sepa_export_debit('ZSFI_SEPA_DEBIT_DATA_01_0000001') AS plresult FROM dual; -- Stapel-ID fuer Basislastschrift
DECLARE
  v_outputFile     VARCHAR;
  v_outputPath     VARCHAR;
  v_now            TIMESTAMP;      -- Ausfuerungsdatum aus now()
  v_fileDateTime   VARCHAR;        -- Ausfuerungsdatum 'YYYYMMDD_HHMMSS'

  v_GrpHdr_MsgId   VARCHAR;        -- generierte Identifikation zur Vermeidung von Doppelverarbeitung bei Kreditinstitut
  v_GrpHdr_CreDtTm VARCHAR;        -- SEPA-Datei Erstellungsdatum
  v_Grphdr_InitgPty_Nm   VARCHAR;  -- Auftraggeber-Name
  v_Pmtinf_CdtrAgt_BIC   VARCHAR;  -- Auftraggeber-BIC
  v_Pmtinf_CdtrAcct_IBAN VARCHAR;  -- Auftraggeber-IBAN
  v_Pmtinf_Cdtrschmeid_id VARCHAR;  -- Auftraggeber-Glaeubiger-ID
 

  i                INTEGER := 0;
  j                INTEGER := 0;
  v_GrpHdr_NbOfTxs INTEGER := 0;
  v_GrpHdr_CtrlSum NUMERIC := 0.00;

  v_cmd            VARCHAR := '';
  v_message        VARCHAR := '';
  v_messArray      VARCHAR[];      -- dyn. erweiterbares Array
  v_anzError       INTEGER := 0;   -- Überschrift für Fehlermeldung = v_messArray[0]

--  v_PmtInf         VARCHAR[];
--  v_CdtTrfTxInf    VARCHAR[];
BEGIN
  v_messArray[v_anzError] := 'SQL: SELECT zsfi_sepa_export_debit(' || '''' || p_zsfi_sepa_debit_data_id || ''')';

  v_now := now();
  v_GrpHdr_CreDtTm := REPLACE((SELECT to_char(v_now, 'YYYY-MM-DD#HH24:MI:SSZ')),'#','T');  -- StarMoney50 mit ending-'Z'
  v_fileDateTime := (SELECT to_char(v_now, 'YYYYMMDD_HH24MISS')); --'YYYYMMDD_HH24MISS'

  TRUNCATE TABLE zsfi_sepa_debit_xml;

  -- Kopfdaten <GrpHdr> ermitteln
  SELECT
    GrpHdr_MsgId,   GrpHdr_NbOfTxs,   GrpHdr_CtrlSum, TRIM(SUBSTR(grphdr_InitgPty_Nm, 1, 70))
  , pmtinf_cdtragt_BIC, pmtinf_cdtracct_IBAN, pmtinf_cdtrschmeid_id
  INTO   v_GrpHdr_MsgId, v_GrpHdr_NbOfTxs, v_GrpHdr_CtrlSum,           v_Grphdr_InitgPty_Nm
  , v_pmtinf_CdtrAgt_BIC, v_pmtinf_CdtrAcct_IBAN, v_Pmtinf_Cdtrschmeid_id
  FROM zsfi_sepa_debit_data sepadata
  WHERE 1=1
   AND sepadata.zsfi_sepa_debit_data_id = p_zsfi_sepa_debit_data_id
   AND sepadata.glstatus = 'OP'        -- '/tmp/sepa_SSD_V27_....xml' noch nicht erstellt
   AND sepadata.documentno IS NULL;    -- Dokument-Nummer noch nicht generiert

  v_outputPath:='/tmp/';
  v_outputFile := 'SEPA_SDD_' || 'V27_' || v_fileDateTime || '.xml';

  IF (isempty(v_GrpHdr_MsgId)) THEN
    v_message := 'Tabelle ''zsfi_sepa_debit_data'': Feld ''GrpHdr_MsgId'' fuer Auftraggeber ist leer';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_GrpHdr_CreDtTm)) THEN
    v_message := 'Erstellungsdatum (GrpHdr_CreDtTm) für SEPA-Basislastschriften konnte nicht generiert werden';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (v_GrpHdr_NbOfTxs = 0) THEN
    v_message := 'Tabelle ''zsfi_sepa_debit_dataline'': Keine Datenzeilen (Basislastschriften) gefunden';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (v_GrpHdr_CtrlSum = 0) THEN
    v_message := 'Tabelle ''zsfi_sepa_debit_dataline'': Summe der Basislastschriften ist 0,00';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_pmtinf_CdtrAgt_BIC)) THEN
    v_message := 'Tabelle ''zsfi_sepa_debit_data'': Feld ''pmtinf_CdtrAgt_BIC'' fuer Auftraggeber ist leer';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_pmtinf_CdtrAcct_IBAN)) THEN
    v_message := 'Tabelle ''zsfi_sepa_debit_data'': Feld ''pmtinf_CdtrAcct_IBAN'' fuer Auftraggeber ist leer';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_Grphdr_InitgPty_Nm)) THEN
    v_message := 'Tabelle ''zsfi_sepa_debit_data'': Feld ''Name'' fuer Auftraggeber ist leer';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_Pmtinf_Cdtrschmeid_id)) THEN
    v_message := 'Tabelle ''zsfi_sepa_debit_data'': Feld ''Pmtinf_Cdtrschmeid_id / Glaeubiger-ID'' fuer Auftraggeber ist leer';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  
  IF (isempty(v_fileDateTime)) THEN
    v_message := 'Zeitstempel für SEPA-Basislastschriften konnte nicht generiert werden ';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;
  IF (isempty(v_outputFile)) THEN
    v_message := 'Dateiname für SEPA-Basislastschriften konnte nicht generiert werden';
    v_anzError := v_anzError + 1;
    v_messArray[v_anzError] := v_message;
  END IF;

  -- wenn noch kein Fehler in gefunden
  IF (v_anzError = 0) THEN
    -- Ausgabe CDD Basislastschrift urn:iso:std:iso:20022:tech:xsd:pain.008.003.03 pain.008.003.03.xsd
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('<?xml version="1.0" encoding="UTF-8"?>');
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.008.003.02">');
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('<CstmrDrctDbtInitn>');

   -- 1/2 Credit Transfer Initiation = Group Header
   -- Kenndaten, die für alle Transaktionen innerhalb der SEPA-Nachricht gelten
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('<GrpHdr>');
    -- Die <MsgID> in Kombination mit der Kunden-ID oder der Auftraggeber-IBAN kann als Kriterium für die Verhinderung einer
    -- Doppelverarbeitung bei versehentlich doppelt eingereichten Dateien dienen und muss somit für jede neue pain-Nachricht
    -- einen neuen Wert enthalten.
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <MsgId>'   || v_GrpHdr_MsgId || '</MsgId>');
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <CreDtTm>' || v_GrpHdr_CreDtTm || '</CreDtTm>');  -- YYYY-MM-DDTHH24:MI:SSZ
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <NbOfTxs>' || v_GrpHdr_NbOfTxs || '</NbOfTxs>');  -- Anzahl Datenzeilen
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <CtrlSum>' || v_GrpHdr_CtrlSum || '</CtrlSum>');  -- max. zwei Nachkomma-St, optional
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <InitgPty>');                                     -- Auftraggeber
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <Nm>'      || v_Grphdr_InitgPty_Nm || '</Nm>');
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' </InitgPty>');
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('</GrpHdr>');

    DECLARE
      CUR_PmtInf RECORD;
    BEGIN
      i := 0;
      FOR CUR_PmtInf IN (
        SELECT get_uuid() AS PmtInf_PmtInfId
             , COUNT(*) AS PmtInf_NbOfTxs
             , SUM (drctdbttx_instdamt) AS PmtInf_instdamt 
             , lclInstrm AS PmtInf_LclInstrm
             , seqtp AS PmtInf_seqtp
             , reqdcolltndt AS PmtInf_reqdcolltndt
             FROM zsfi_sepa_debit_dataline WHERE zsfi_sepa_debit_data_id = p_zsfi_sepa_debit_data_id 
             GROUP BY seqtp, lclInstrm, reqdcolltndt
      )
      LOOP
     /* 
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <!-- Gruppenwechsel PmtInf:'
                                                          || '  seqtp='     || CUR_PmtInf.PmtInf_seqtp
                                                          || ', lclInstrm=' || CUR_PmtInf.PmtInf_LclInstrm 
                                                          || ', reqdcolltndt=' || to_char(CUR_PmtInf.PmtInf_ReqdColltnDt, 'YYYY-MM-DD')
                                                          || ' -->');          
     */
   -- Ausgabe Daten je Gruppenwechsel Zahlungssaetze
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('<PmtInf>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <PmtInfId>' || CUR_PmtInf.PmtInf_PmtInfId || '</PmtInfId>'); -- Referenz zur eindeutigen Identifizierung des Sammlers -- CCTI/VRNWSW/9/cf22f9ae9669f2473c078
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <PmtMtd>DD</PmtMtd>');               -- Zahlungsinstrument, Konstante 'DD'
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <NbOfTxs>' || CUR_PmtInf.PmtInf_NbOfTxs || '</NbOfTxs>');  -- Anzahl Datenzeilen
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <CtrlSum>' || CUR_PmtInf.PmtInf_instdamt || '</CtrlSum>');  -- max. zwei Nachkomma-St
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <PmtTpInf>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <SvcLvl>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <Cd>SEPA</Cd>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </SvcLvl>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <LclInstrm>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <Cd>' || CUR_PmtInf.PmtInf_LclInstrm || '</Cd>'); -- CORE zeitl.Verhalten: Standard
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </LclInstrm>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <SeqTp>' || CUR_PmtInf.PmtInf_seqtp || '</SeqTp>'); -- 'FRST, RCUR, OOFF, FNAL
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' </PmtTpInf>');                       -- wg StarMoney50
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <ReqdColltnDt>'|| to_char(CUR_PmtInf.PmtInf_ReqdColltnDt, 'YYYY-MM-DD') || '</ReqdColltnDt>'); -- Ausführungstermin
        
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <Cdtr>'); -- Empfaenger (Auftraggeber)
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <Nm>' || v_Grphdr_InitgPty_Nm || '</Nm>');  -- 'Creditor Name' CUR_debit.InitgPty_Nm
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' </Cdtr>');

        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <CdtrAcct>');                             -- Konto des Empfaengers (Auftraggeber, Einreicher)
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <Id>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <IBAN>' || v_pmtinf_CdtrAcct_IBAN || '</IBAN>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </Id>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' </CdtrAcct>');

        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <CdtrAgt>');           -- Institut des Empfaengers (Auftraggeber, Einreicher)
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <FinInstnId>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <BIC>' || v_pmtinf_CdtrAgt_BIC || '</BIC>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </FinInstnId>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' </CdtrAgt>');
        
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <ChrgBr>SLEV</ChrgBr>');   -- ChargeBearer=Entgeltverrechnung, recommended StarMoney50 reaktiviert

        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <CdtrSchmeId>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <Id>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <PrvtId>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('    <Othr>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('     <Id>' || COALESCE(v_Pmtinf_Cdtrschmeid_id, '') || '</Id>'); -- Glaeubiger-ID DE00ZZZ00099999999
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('     <SchmeNm>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('      <Prtry>SEPA</Prtry>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('     </SchmeNm>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('    </Othr>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   </PrvtId>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </Id>');
        INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' </CdtrSchmeId>');

   -- 2/2.1: Credit Transfer Initiation = Transaction Information 1..n / max:9.999.999
    -- Zahlungssaetze zu Gruppenwechsel
      -- 2/2.2: Credit Transfer Initiation = Payment Instruction Information 1..n / max:9.999.999
      -- Satz von Angaben (z. B. Auftraggeberkonto, Ausführungstermin), welcher für alle Einzeltransaktionen
      -- gilt. Entspricht einem logischen Sammler innerhalb einer physikalischen Datei.
    
      -- sofern kein gültiger Geschäftstag angegeben wurde, erolgt automatisch eine
      -- Verlängerung durch Kreditinstitut auf den nächsten Geschäftstag

   -- 2/2.3: Lastschrift-Bezogene (1..n) innerhalb des logischen Sammlers
        DECLARE
          CUR_debit RECORD;
        BEGIN
          i := 0;
          FOR CUR_debit IN (
           SELECT
             d.zsfi_sepa_debit_data_id,
             d.Pmtinf_CdtrSchmeId_Id, -- Creditor RefID, Empfaenger Glaeubiger-ID
             d.PmtInf_PmtInfId,
             d.PmtInf_ReqdColltnDt,
             TRIM(SUBSTR(grphdr_InitgPty_Nm, 1, 70))      AS InitgPty_Nm,   -- VARCHAR(70) NOT NULL,
             TRIM(SUBSTR(pmtinf_CdtrAcct_IBAN, 1, 34))    AS CdtrAcct_IBAN, -- VARCHAR(34) NOT NULL
             TRIM(SUBSTR(pmtinf_CdtrAgt_BIC, 1, 13))      AS CdtrAgt_BIC,   -- VARCHAR(13) NOT NULL
             
             TRIM(SUBSTR(drctDbtTx_EndToEndId, 1, 34))    AS EndToEndId,    -- VARCHAR(34),
             drctDbtTx_InstdAmt                           AS InstdAmt,      -- NUMERIC(11,2) NOT NULL,
             drctDbtTx_MndtId                             AS MndtId,        -- VARCHAR(70) NOT NULL
             drctDbtTx_DtOfSgntr                          AS DtOfSgntr,     -- DATE NOT NULL

             TRIM(SUBSTR(drctDbtTx_DbtrAgt_BIC, 1, 13))   AS DbtrAgt_BIC,   -- VARCHAR(13) NOT NULL,
             TRIM(SUBSTR(drctDbtTx_Dbtr_Nm, 1, 70))       AS Dbtr_Nm,       -- VARCHAR(70) NOT NULL,
             TRIM(SUBSTR(drctDbtTx_DbtrAcct_IBAN, 1, 34)) AS DbtrAcct_IBAN, -- VARCHAR(34) NOT NULL,
             TRIM(SUBSTR(replace(drctDbtTx_RmtInf_Ustrd,'&',' '), 1, 140)) AS RmtInf_Ustrd,   -- VARCHAR(140) NOT NULL,
             d.currencyISO
            FROM 
              zsfi_sepa_debit_data d, 
              zsfi_sepa_debit_dataline dataline
            WHERE 1=1
             AND  d.zsfi_sepa_debit_data_id = dataline.zsfi_sepa_debit_data_id
             AND  d.zsfi_sepa_debit_data_id = p_zsfi_sepa_debit_data_id   -- 'ZSFI_SEPA_DEBIT_DATA_01_0000001'
             AND (dataline.seqtp = CUR_PmtInf.PmtInf_seqtp)               -- 'FRST', 'RCUR'
             AND (dataline.LclInstrm = CUR_PmtInf.PmtInf_LclInstrm)       -- 'CORE'
             AND (dataline.reqdcolltndt = CUR_PmtInf.PmtInf_reqdcolltndt) -- '08-08-2014'
             AND (dataline.drctDbtTx_InstdAmt >= 0.01) AND (dataline.drctDbtTx_InstdAmt <= 999999999.99)
            )
          LOOP
        /*  INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <!-- DrctDbtTxInf Datenzeile für Basislastschrift -->');  */
            i := i + 1; -- Zaehler fuer v_message
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' <DrctDbtTxInf>');  -- Maximale Anzahl Wiederholungen=9.999.999        

            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <PmtId>');        -- PaymentIdentificationSEPA
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <EndToEndId>' || CUR_debit.EndToEndId || '</EndToEndId>'); -- 'OriginatorID1234'
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </PmtId>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <InstdAmt Ccy="'||CUR_debit.currencyISO||'">' || CUR_debit.InstdAmt || '</InstdAmt>'); -- Betrag '6543.14'

            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <DrctDbtTx>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <MndtRltdInf>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('    <MndtId>' || CUR_debit.MndtId || '</MndtId>'); -- 'Other Mandate Id'
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('    <DtOfSgntr>' || CUR_debit.DtOfSgntr || '</DtOfSgntr>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('    <AmdmntInd>false</AmdmntInd>'); -- keine Änderung der Mandat-Referenz
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   </MndtRltdInf>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </DrctDbtTx>');
      
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <DbtrAgt>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <FinInstnId>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('    <BIC>' || CUR_debit.DbtrAgt_BIC || '</BIC>'); --Business Identifier Code, max 13 Stellen
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   </FinInstnId>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </DbtrAgt>');

            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <Dbtr>'); -- Bezogener
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <Nm>' || CUR_debit.Dbtr_Nm || '</Nm>'); -- max 70 Stellen, Other Debtor Name
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </Dbtr>');

            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <DbtrAcct>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <Id>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('    <IBAN>' || CUR_debit.DbtrAcct_IBAN || '</IBAN>'); -- Kreditinstitut des Bezogenen
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   </Id>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </DbtrAcct>');
            -- Verwendungszweck
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  <RmtInf>');
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('   <Ustrd>' || CUR_debit.RmtInf_Ustrd || '</Ustrd>'); -- unstrukturiert
            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('  </RmtInf>');

            INSERT INTO zsfi_sepa_debit_xml (daten) VALUES (' </DrctDbtTxInf>');
          END LOOP;
        END;
      END LOOP;

      INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('</PmtInf>');
    END; -- CUR_PmtInf RECORD;

    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('</CstmrDrctDbtInitn>');
    INSERT INTO zsfi_sepa_debit_xml (daten) VALUES ('</Document>');

    v_cmd := 'COPY (SELECT daten FROM zsfi_sepa_debit_xml ORDER BY zsfi_sepa_debit_xml_id) TO ' || '''' || v_outputPath||v_outputFile || '''';
    EXECUTE(v_cmd);

    v_message := 'SUCCESS - SEPA-Basislastschrift-Datei: ' || v_outputFile || ' erstellt ' || ' - ' ||  i || ' Datenzeilen(n) verarbeitet.';
    RAISE NOTICE '%', v_message;
    
    RETURN v_outputFile; -- alles o.k., SEPA-XML-Dateiname ohne \Pfad\ zurueckgeben
  ELSE --(v_anzError > 0) wenn Fehler gefunden, Exception provozieren für Ausgabe Fehlermeldungen
    RAISE EXCEPTION '%', 'SEPA-Basislastschrift-Datei aufgrund von ' || v_anzError || ' Fehler nicht erstellt.'; -- > Exception-Handling
  END IF; -- (v_anzError = 0)

  -- wenn Fehler gefunden, Exception provozieren für Ausgabe Fehlermeldungen
  IF (v_anzError > 0 ) THEN
    RAISE EXCEPTION '%', 'SEPA-Basislastschrift-Datei aufgrund von ' || v_anzError || ' Fehler nicht erstellt.'; -- > Exception-Handling
  END IF; -- (v_anzError = 0)

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;

   -- Fehlermeldungen ausgeben
    j := 0;
    LOOP
      IF (v_messArray[j] IS NOT NULL) THEN
        -- RAISE NOTICE '%', v_messArray[j];
        v_message := v_message || '</br>' || v_messArray[j];
      ELSE
        EXIT;
      END IF;
      j := j + 1;
    END LOOP;
    RAISE NOTICE '%', replace(v_message,'</br>',E'\r\n');
--  v_message := '@ERROR=' || SQLERRM;
    RETURN v_message;

END;
$_$
LANGUAGE 'plpgsql' VOLATILE
COST 100;
