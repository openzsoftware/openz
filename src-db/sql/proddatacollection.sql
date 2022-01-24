/* ProdDataCollection.sql */

SELECT zsse_DropView ('pdc_barcode_v');
CREATE VIEW pdc_barcode_v AS
  SELECT bp.value::varchar(200) AS barcode, 'EMPLOYEE' AS type, u.ad_user_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM ad_user u, c_bpartner bp
  WHERE 1=1
   AND bp.c_bpartner_id = u.c_bpartner_id
   AND bp.isemployee = 'Y'
 UNION
  SELECT l.value::varchar(200) AS barcode, 'LOCATOR' AS type, l.m_locator_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM m_locator l
 UNION
  SELECT p.value::varchar(200) AS barcode, 'PRODUCT' AS type, p.m_product_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM m_product p
 UNION
  SELECT ws.value::varchar(200) AS barcode, 'WORKSTEP' AS type, ws.c_projecttask_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM c_projecttask ws, c_project pro WHERE ws.c_project_id = pro.c_project_id and pro.projectcategory = 'PRO'
 UNION
  SELECT e.columnname::varchar(200) AS barcode, 'CONTROL' AS type, e.ad_element_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM ad_element e WHERE e.ad_module_id = '000CDBE191604F5A835A3EC3213719E8' AND description like 'CODE-128-code action%'
 UNION 
  SELECT e.columnname::varchar(200) AS barcode, 'CALCULATION' AS type, e.ad_element_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM ad_element e WHERE e.ad_module_id = '000CDBE191604F5A835A3EC3213719E8' AND description='scan calc'
 UNION
  SELECT l.serialnumber::varchar(200) AS barcode, 'SERIALNUMBER' AS type, l.snr_masterdata_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM snr_masterdata l
 UNION
  SELECT l.batchnumber::varchar(200) AS barcode, 'BATCHNUMBER' AS type, l.snr_batchmasterdata_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight
  FROM snr_batchmasterdata l;

CREATE OR REPLACE FUNCTION pdc_getDataIdFromScan(p_value VARCHAR)
RETURNS SETOF pdc_barcode_v -- value, type, id, mess, ad_message_value
AS $body$
-- SELECT * FROM pdc_getDataIdFromScan('xxxx');
-- SELECT * FROM pdc_getDataIdFromScan('9783939316800');     -- employee
-- SELECT * FROM pdc_getDataIdFromScan('Elektronik');        -- locator
-- SELECT * FROM pdc_getDataIdFromScan('Elektronik-2');
-- SELECT * FROM pdc_getDataIdFromScan('730192IAIEUF0005');  -- product
-- SELECT * FROM pdc_getDataIdFromScan('9783826604935');     -- workstep
-- SELECT * FROM pdc_getDataIdFromScan('bc cancel');         -- SBC_1_Abbrechen
-- SELECT * FROM pdc_getDataIdFromScan('bc next');           -- SBC_2_Naechster
-- SELECT * FROM pdc_getDataIdFromScan('bc readz');          -- SBC_3_Fertig
DECLARE
  v_message  VARCHAR;
  y INTEGER := 0;
  y_cmd VARCHAR := '';

  v_pdc_barcode_v  pdc_barcode_v%ROWTYPE;
  v_resultSet RECORD;
  v_count INTEGER;
  v_cur record;
  v_type VARCHAR;
  v_id VARCHAR;
  v_mess VARCHAR;
  v_serial varchar;
  v_batch varchar;
  v_serialid varchar;
  v_batchid varchar;
  v_product varchar;
  v_prodvalue varchar;
  v_snrorbtchvalue varchar;
  v_btchvalue varchar;
  v_weight varchar;
BEGIN
  BEGIN
    if instr(p_value,'|')>0 and c_getconfigoption('kombibarcode','0')='Y' then
        select SPLIT_PART(p_value, '|', 1) into v_prodvalue; -- 1St Part always Product Value
        select SPLIT_PART(p_value, '|', 2) into v_snrorbtchvalue;-- 2nd Part (Serial or Batch)
        select SPLIT_PART(p_value, '|', 3) into v_btchvalue;-- 3rd Part 
        select SPLIT_PART(p_value, '|', 4) into v_weight;-- 4th Part 
        select isserialtracking,isbatchtracking,m_product_id  into v_serial,v_batch,v_product from m_product where value=v_prodvalue;
        -- Serial always in 2nd Part.
        if coalesce(v_serial,'')='Y' then
           select snr.snr_masterdata_id
                  into v_serialid from snr_masterdata snr,m_product p where p.m_product_id=snr.m_product_id and p.m_product_id=v_product
                                             and snr.serialnumber=v_snrorbtchvalue;
        end if;
        -- Batch in old Barcodes also in 2nd Part
        if v_batch='Y' and v_btchvalue=''  then
           select snr.snr_batchmasterdata_id into v_batchid from snr_batchmasterdata snr,m_product p where p.m_product_id=snr.m_product_id and p.m_product_id=v_product
                                             and snr.batchnumber=v_snrorbtchvalue;
        end if;
        -- Batch in New Barcodes 3rd Part
        if v_batch='Y' and v_btchvalue!=''  then   
            select snr.snr_batchmasterdata_id into v_batchid from snr_batchmasterdata snr,m_product p where p.m_product_id=snr.m_product_id and p.m_product_id=v_product
                                             and snr.batchnumber=v_btchvalue;
        end if;
        if v_product is not null then
            v_pdc_barcode_v.barcode := p_value;
            v_pdc_barcode_v.type := 'KOMBI';
            v_pdc_barcode_v.id := v_product;
            v_pdc_barcode_v.snrmasterdata_id := v_serialid;
            v_pdc_barcode_v.batchmasterdata_id := v_batchid;
            if v_weight!='' then
                begin
                    v_pdc_barcode_v.weight:=to_number(v_weight);
                exception
                WHEN OTHERS THEN
                   v_pdc_barcode_v.weight:=null;
                end;
            end if;
            y :=1;
            RETURN NEXT v_pdc_barcode_v;
        end if;       
    else
        FOR v_resultSet IN
        (SELECT * FROM pdc_barcode_v bc  WHERE bc.barcode = p_value)
        LOOP
        y := y + 1;
        RETURN NEXT v_resultSet;
        END LOOP;
    end if;
    --RAISE NOTICE 'value=% y=%', p_value, y;

    IF (y = 0) THEN
      SELECT * FROM pdc_barcode_v INTO v_pdc_barcode_v LIMIT 1; -- ROWTYPE
      v_pdc_barcode_v.barcode := '';
      v_pdc_barcode_v.type := 'UNKNOWN';
      v_pdc_barcode_v.id := '';
      v_pdc_barcode_v.snrmasterdata_id := '';
      v_pdc_barcode_v.batchmasterdata_id := '';
      RETURN NEXT v_pdc_barcode_v;
    END IF;
/*
    ELSEIF (y = 1) THEN
      RETURN NEXT v_resultSet;

    ELSEIF (y > 1) THEN
 -- SELECT * FROM pdc_getDataIdFromScan('Elektron%');
      FOR v_resultSet IN
        (SELECT * FROM pdc_barcode_v v WHERE v.barcode LIKE p_value || '%') -- ROWTYPE
      LOOP
        v_resultSet.type := 'UNDEFINED';
        v_resultSet.mess := '@zssm_ResultSetAmbiguous@' || ' : ''' || v_resultSet.type || '''';
        RETURN NEXT v_resultSet;
        EXIT;
      END LOOP;
    END IF;
*/
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC: pdc_getDataIdFromScan()' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION pdc_isbatchorserialnumber (
  p_consumption_id varchar
)
RETURNS char AS
$body$
/*
Iteriert durch alle Zeilen der Materialentnahme. 
Stellt fest, ob Serien oder Chargennummer erforderlich. 
Zieht die bereits erfassten seriennummern ab
Wenn ein Produkt mit SNR oder CNR gefunden: RETURN 'Y', sonst 'N'
*/
-- SELECT * FROM pdc_isBatchOrSerialnumber('500A31314EEA4CFAA207B9DA07ECB67F'); -- m_internal_consumption_id
DECLARE
  v_isBatchOrSerial CHAR := 'N';
  v_message VARCHAR;
  v_snr numeric;
  v_qty numeric;
BEGIN
  BEGIN
    
    SELECT sum(micl.movementqty) into v_qty
    FROM m_internal_consumptionline micl , m_product p
    WHERE micl.m_product_id = p.m_product_id
       AND ( (p.isbatchtracking = 'Y') OR (p.isserialtracking = 'Y') )
       AND micl.m_internal_consumption_id = p_consumption_id;
   SELECT sum(coalesce(snr.quantity,0)) into v_snr
   FROM m_internal_consumptionline micl ,snr_internal_consumptionline snr , m_product p
      WHERE snr.m_internal_consumptionline_id=micl.m_internal_consumptionline_id and micl.m_product_id = p.m_product_id
       AND ( (p.isbatchtracking = 'Y') OR (p.isserialtracking = 'Y') )
       AND micl.m_internal_consumption_id = p_consumption_id;
    if (coalesce(v_qty,0)-coalesce(v_snr,0))!=0 THEN 
        v_isBatchOrSerial := 'Y';
    END IF;
    RETURN v_isBatchOrSerial;
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC: pdc_isBatchOrSerialnumber()' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION pdc_getSerialOrBatchType(
  p_value VARCHAR,
  p_product_id VARCHAR
 )
RETURNS VARCHAR -- BATCH, SERIAL, NONE
AS $body$
/*
Funktion: pdc_getSerialOrBatchType(value,m_product_id) return varchar
Testen in snr_serialnumbertracking, ob der Eintrag als lotnumber oder serialnumber fuer das produkt vorhanden ist. 
Wenn lotnumber: Return 'BATCH', wenn serialnumber return 'SERIAL', wenn nix return 'NONE'
*/
-- SELECT * FROM pdc_getSerialOrBatchType('324342', 'F2EC9FF85DB34C8A964DFD17B915449E'); -- barcode, m_product_id
DECLARE
  v_SerialOrBatchType VARCHAR := 'NONE';
  v_message VARCHAR;
BEGIN
  BEGIN
    SELECT
    CASE WHEN (NOT isempty(snr.serialnumber)) THEN 'SERIAL'
         WHEN (NOT isempty(snr.lotnumber)) THEN 'BATCH' 
         ELSE 'NONE'
    END AS number
    INTO v_SerialOrBatchType
--      , p.m_product_id, p.value, p.name, p.isserialtracking, p.isbatchtracking, p.upc, snr.lotnumber, snr.serialnumber
--      , snr.*
    FROM snr_serialnumbertracking snr
    WHERE  snr.m_product_id = p_product_id
     AND (snr.serialnumber = p_value OR snr.lotnumber = p_value)
    LIMIT 1;
    
    RETURN COALESCE(v_SerialOrBatchType, 'NONE');
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC: pdc_getDataIdFromScan()' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION pdc_getProductIdFromSerialOrBatchNumber(
  p_value VARCHAR,
  p_consumption_ID VARCHAR
 )
RETURNS VARCHAR -- m_product_id
/*
Funktion: pdc_getProductIdFromSerialOrBatchNumber(value, consumptionID) RETURNS VARCHAR
Als Value kann eine Seriennummer oder eine Chargennummer gescannt worden sein.
Iteration in m_internal_consumptionline zu der o.a. consumptionId.
Abfrage, ob m_product_id snr oder chargennummer hat. 
Abfrage, in m_product ob zu m_product_id isserialtracking='Y' oder isbatchtracking='Y'
Wenn ja:
Pruefen, ob ein Eintrag der Seriennummer oder Chargennummer in snr_serialnumbertracking existiert.
Wenn ja, product_id merken, iteration weiterfuehren
Wenn 1 m_product_id gefunden: RETURN m_product_id.
Wenn >1 gefunden RETURN: NOSINGLEPRODUCT
Wenn 0 gefunden RETURN: UNDEFINED
*/
AS $body$
DECLARE
  y INTEGER := 0;
  v_message  VARCHAR;
  v_ProductIdFromSerialOrBatchNumber VARCHAR := 'UNDEFINED';
  v_resultSet RECORD;
  v_undefined VARCHAR := 'UNDEFINED';
  v_noSingleProduct VARCHAR := 'NOSINGLEPRODUCT';
BEGIN
  BEGIN
    FOR v_resultSet IN (
     SELECT
   --   p.m_product_id, p.value, p.name, p.isserialtracking, p.isbatchtracking, p.upc -- , snr.lotnumber, snr.serialnumber
   -- , micl.m_internal_consumption_id, micl.m_internal_consumptionline_id
       distinct snr.m_product_id
   -- , snr.lotnumber, snr.serialnumber
   -- , micl.*
   
      FROM m_internal_consumptionline micl, m_product p
      , snr_serialnumbertracking snr
      WHERE micl.m_product_id = p.m_product_id
       AND snr.m_product_id = p.m_product_id
       AND ( (p.isbatchtracking = 'Y') OR (p.isserialtracking = 'Y') )      -- m_product
       AND snr.m_product_id = micl.m_product_id
       AND (snr.serialnumber = p_value OR snr.lotnumber = p_value )        -- barcode = '324342'
       AND micl.m_internal_consumption_id = p_consumption_id -- '13030CE3B5AE467BAC62B9419AD82DD3', '500A31314EEA4CFAA207B9DA07ECB67F'
     ) 
    LOOP
      y := y + 1;
      IF (y = 1) THEN 
        v_ProductIdFromSerialOrBatchNumber := v_resultSet.m_product_id;
      END IF;
    END LOOP;
 -- RAISE NOTICE 'value=% y=%', p_value, y;

    IF (y = 0) THEN
   -- SELECT * FROM pdc_getProductIdFromSerialOrBatchNumber('3 24342', '13030CE3B5AE467BAC62B9419AD82DD3');
      RETURN v_undefined; -- type := 'UNKNOWN', mess := '@zssm_EmptyResultSet@'

    ELSEIF (y = 1) THEN
   -- SELECT * FROM pdc_getProductIdFromSerialOrBatchNumber('324342', '13030CE3B5AE467BAC62B9419AD82DD3');
      RETURN v_ProductIdFromSerialOrBatchNumber;

    ELSEIF (y > 1) THEN
      RETURN v_noSingleProduct; -- type := 'UNDEFINED', mess := '@zssm_ResultSetAmbiguous@'
    END IF;

  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC: pdc_getProductIdFromSerialOrBatchNumber()' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';


SELECT zsse_dropfunction('pdc_snrtodeliver');
CREATE OR REPLACE FUNCTION pdc_snrtodeliver(
  p_consumption_id VARCHAR,
  OUT product_id VARCHAR,
  OUT qty NUMERIC,
  OUT isSerialtracking CHAR(1),
  OUT isBatchtracking CHAR(1),
  OUT lotNumber VARCHAR,
  OUT isCreated CHAR(1),
  OUT locator_id VARCHAR,
  OUT internal_consumptionline_id VARCHAR,
  OUT inoutline_id VARCHAR
 )
RETURNS SETOF record -- prd, qty, isSrlTrk, isBtchTrk, lot, isCrt
AS $body$
/*
Funktion pdc_snrtodeliver(consumption id in) returns setof
produkt,menge,snrErforderlich,ChargenummerErforderlich,AktuelleChargennummer,NeuvergabeProduziert.
Ermittelt die noch zu bearbeitenden Produkte fuer Seriennummern bzw. Chargennummern-Erfassung.

Ermittlung Menge: Menge aus internal_consumptionline abzueglich Mengen aus snr_consumptionline.
Das ergibt die noch zu bearbeitende Menge.

AktuelleChargennummer ist nur bei Produkten mit SNR und Chargennummer gefuellt,
wenn bereits eine Chargennummer erfasst wurde, aber noch Seriennummern zu erfassen sind.
Hierzu den juengsten Datensatz aus snr_internal_consumptionline fuer dieses Produkt heranziehen.
*/
DECLARE
  y INTEGER := 0;
  z INTEGER := 0;
  v_message  VARCHAR;
  v_resultSet RECORD;
BEGIN
  BEGIN
--  RAISE NOTICE 'p_consumption_id=%', p_consumption_id;
    FOR v_resultSet IN
     (select a.value,a.m_product_id, a.movementqty, a.description, a.m_locator_id,a.m_internal_consumptionline_id , a.name, a.isserialtracking, a.isbatchtracking,a.snricl_quantity,a.tracking from 
      (SELECT p.value,
        icl.m_product_id, icl.movementqty, icl.description, icl.m_locator_id,icl.m_internal_consumptionline_id
      , p.name, p.isserialtracking, p.isbatchtracking
      , COALESCE((SELECT SUM(snricl.quantity) FROM snr_internal_consumptionline snricl WHERE snricl.m_internal_consumptionline_id = icl.m_internal_consumptionline_id),0) AS snricl_quantity
      , CASE WHEN ( (p.isbatchtracking = 'Y') AND (p.isserialtracking = 'Y') ) THEN 'Y'
             ELSE                                                                   'N' END AS tracking
      FROM m_internal_consumptionline icl, m_product p
      WHERE icl.m_product_id = p.m_product_id
       AND (p.isserialtracking = 'Y' OR p.isbatchtracking = 'Y' )
       AND icl.m_internal_consumption_id = p_consumption_id
      UNION
      SELECT p.value,
        icl.m_product_id, icl.movementqty, icl.description, icl.m_locator_id,icl.m_inoutline_id as m_internal_consumptionline_id
      , p.name, p.isserialtracking, p.isbatchtracking
      , COALESCE((SELECT SUM(snricl.quantity) FROM snr_minoutline snricl WHERE snricl.m_inoutline_id = icl.m_inoutline_id),0) AS snricl_quantity
      , CASE WHEN ( (p.isbatchtracking = 'Y') AND (p.isserialtracking = 'Y') ) THEN 'Y'
             ELSE                                                                   'N' END AS tracking
      FROM m_inoutline icl, m_product p
      WHERE icl.m_product_id = p.m_product_id
       AND (p.isserialtracking = 'Y' OR p.isbatchtracking = 'Y' )
       AND icl.m_inout_id = p_consumption_id) a
       order by value
     )
    LOOP
      y := y + 1;
   -- RAISE NOTICE '  y=%, icl.movementqty=%, snricl_quantity=%', y, v_resultSet.movementqty, v_resultSet.snricl_quantity;
   -- RAISE NOTICE '  tracking=%', v_resultSet.tracking;

    -- OUT-Parameter-Felder belegen
  -- RAISE NOTICE 'v_resultSet.movementqty=%, v_resultSet.snricl_quantity=%', v_resultSet.movementqty, v_resultSet.snricl_quantity;
    IF ( (v_resultSet.movementqty - v_resultSet.snricl_quantity) <> 0) THEN
      z := z + 1;
      product_id := v_resultSet.m_product_id;
      qty := (v_resultSet.movementqty - v_resultSet.snricl_quantity);
      isSerialtracking := v_resultSet.isSerialtracking;
      isBatchtracking := v_resultSet.isBatchtracking;
      locator_id:=v_resultSet.m_locator_id;
      internal_consumptionline_id:=v_resultSet.m_internal_consumptionline_id;
      lotNumber :=
       (SELECT snrcl4lot.lotnumber
        FROM snr_internal_consumptionline snrcl4lot
        WHERE snrcl4lot.m_internal_consumptionline_id = p_consumption_id -- '9966C9ABD3664D0FA52908CD92990E49' -- '13030CE3B5AE467BAC62B9419AD82DD3'
        ORDER BY snrcl4lot.updated DESC LIMIT 1
        );
      isCreated := COALESCE(
       (SELECT
          CASE WHEN (ic.movementtype = 'P+') THEN 'Y' ELSE 'N' END AS GeneratedByProduction_ŃewProducedMaterial
        FROM m_internal_consumption ic WHERE ic.m_internal_consumption_id = p_consumption_id -- '13030CE3B5AE467BAC62B9419AD82DD3')
       ), 'N');

      RETURN NEXT; -- SETOF prd, qty, isSrlTrk, isBtchTrk, lot, isCrt: record zurueckgeben
     END IF;

    END LOOP;

--  RAISE NOTICE 'finished=%', 'pdc_snrtodeliver()';
--  RAISE NOTICE '% candidates found, % records returned', y, z;
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC: pdc_snrtodeliver()' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';


SELECT zsse_dropfunction('pdc_getopenworkstep');
CREATE OR REPLACE FUNCTION pdc_getopenworkstep(
  p_userID VARCHAR
 )
RETURNS VARCHAR -- workstep_id
/*
Funktion: pdc_getopenworkstep(userID in) RETURNS VARCHAR
Ermittelt zu einem User den Workstep, an dem dieser aktuell angemeldet ist.
ERmittlung aus zspm_ptaskfeedbackline fuer die userID, hour_from not null, hour_to=null.
Wenn kein DS gefunden: return '';
*/
AS $body$
-- SELECT * FROM pdc_getopenworkstep('0'); -- p_userID
DECLARE
  v_message VARCHAR;
BEGIN
  BEGIN
    RETURN COALESCE(
     (SELECT fbl.c_projecttask_id
      FROM zspm_ptaskfeedbackline fbl
      WHERE ( ( (fbl.hour_from IS NOT NULL) AND (fbl.hour_to IS NULL) )
      AND fbl.ad_user_id = p_userID))
      , '') LIMIT 1;
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC: pdc_getopenworkstep('''|| p_userID || ''')' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';

select zsse_DropFunction ('pdc_settimefeedback');
CREATE OR REPLACE FUNCTION pdc_settimefeedback (
  p_org_id varchar,
  p_workstep_id varchar,
  p_user_id varchar,
  p_timestamp timestamp
)
RETURNS varchar AS
$body$
DECLARE
  y INTEGER := 0;
  v_message  VARCHAR;
  v_zspm_ptaskfeedbackline zspm_ptaskfeedbackline%ROWTYPE;
  v_zssm_workstep_v  zssm_workstep_v%ROWTYPE;
  v_c_project_id     VARCHAR;
  v_gui_mess         VARCHAR;      -- dyn. erweiterbares Array
  v_g                INTEGER := -1;
  v_recordCount      INTEGER;
  v_timestamp timestamp:=now();
BEGIN
  IF (p_org_id IS NULL) THEN
    RETURN ''; -- wg XSQL
  END IF;
  IF (p_timestamp IS NOT NULL) THEN
    v_timestamp := p_timestamp;
  END IF;
-- SELECT pdc_settimefeedback('AE3637495E9E4EBFA7E766FE9B97893A', 'E4169A63B193416F88D91905D4776B55', '3F1FCD828F544C89BDB948EB43575BE3', now()::timestamp); -- 'Zusammenbau PC-System'
-- SELECT pdc_settimefeedback('AE3637495E9E4EBFA7E766FE9B97893A', 'F9211A1C7EA449DA999DFE024C22B7BF', '3F1FCD828F544C89BDB948EB43575BE3', NULL); -- 'Allgemein'
-- SELECT pdc_settimefeedback('AE3637495E9E4EBFA7E766FE9B97893A', 'C2A0D112FE234BB08183087B0B331FF7', '3F1FCD828F544C89BDB948EB43575BE3', NULL); -- 'PRP'

-- get workstep according to productionorder (PRO)
  SELECT pdc_ws.* FROM zssm_workstep_v pdc_ws, zssm_productionorder_v pdc_pro  -- projectCategory = 'PRO' only
  INTO v_zssm_workstep_v  -- ROWTYPE
  WHERE 1=1
   AND pdc_ws.zssm_productionorder_v_id = pdc_pro.zssm_productionorder_v_id
   AND pdc_ws.zssm_workstep_v_id = p_workstep_ID;  -- 'E4169A63B193416F88D91905D4776B55';

 -- restrictions
  IF (v_zssm_workstep_v.zssm_workstep_v_id IS NULL) OR (v_zssm_workstep_v.zssm_productionorder_v_id IS NULL) THEN
    RAISE EXCEPTION '%', '@zssm_WorkstepNotFound@'; -- PRO
  ELSE
    v_c_project_id := v_zssm_workstep_v.zssm_productionorder_v_id; --  zspm_ptaskfeedbackline.c_project_id NOT NULL;
  END IF;

 -- select first record to be updated / by limit
  SELECT * FROM zspm_ptaskfeedbackline fbl INTO v_zspm_ptaskfeedbackline
  WHERE 1=1
   AND fbl.c_projecttask_id = p_workstep_ID
   AND fbl.ad_user_id = p_user_ID
  ORDER BY fbl.hour_to DESC LIMIT 1; -- select record (hour_to IS NULL) first
 --
  v_gui_mess:='NO Data found';
  IF (v_zspm_ptaskfeedbackline.zspm_ptaskfeedbackline_id IS NULL) -- no record found in table zspm_ptaskfeedbackline
  OR   (v_zspm_ptaskfeedbackline.hour_to IS NOT NULL)             -- one record to be finished
   THEN
   -- first timefeedback onto this workstep
    INSERT INTO zspm_ptaskfeedbackline (
     -- (v_zssm_workstep_v.taskbegun = 'Y') : managed by trigger
      zspm_ptaskfeedbackline_id,
      ad_client_id,
      ad_org_id,
      createdby,
      updatedby,
      c_project_id,
      c_projecttask_id,
      ad_user_id,
      workdate,
      hour_from,
      hour_to
    )
    VALUES (
      get_uuid(),
      'C726FEC915A54A0995C568555DA5BB3C', --  ad_client_id VARCHAR(32) NOT NULL,
      p_org_ID,                           --  ad_org_id VARCHAR(32) NOT NULL,
      p_user_id,          --  createdby VARCHAR(32) NOT NULL,
      p_user_id,          --  updatedby VARCHAR(32) NOT NULL,
      v_c_project_id,     -- c_project_id VARCHAR(32) NOT NULL,
      p_workstep_ID,      -- c_projecttask_id VARCHAR(32) NOT NULL,
      p_user_id,          -- ad_user_id VARCHAR(32),
      TRUNC(v_timestamp), -- workdate TIMESTAMP WITHOUT TIME ZONE NOT NULL,
      v_timestamp,        -- hour_from TIMESTAMP WITHOUT TIME ZONE,
      NULL                -- hour_to TIMESTAMP WITHOUT TIME ZONE
  --, isprocessed:='Y'    -- set by trigger zspm_ptaskfeedbackline_trg
    );
    v_g := (v_g + 1);
    v_gui_mess := '@TimeFeedbackAdded@';
 -- RAISE NOTICE '%', v_gui_mess[v_g];
  ELSEIF (     (v_zspm_ptaskfeedbackline.zspm_ptaskfeedbackline_id IS NOT NULL) -- record found for update
           AND (v_zspm_ptaskfeedbackline.hour_from IS NOT NULL)
           AND (v_zspm_ptaskfeedbackline.hour_to   IS NULL) ) THEN
    UPDATE zspm_ptaskfeedbackline fbl SET
      hour_to = v_timestamp,
      updatedby = p_user_id,
      updated = now()
    WHERE 1=1
     AND fbl.ad_user_id = p_user_ID
     AND fbl.hour_to IS NULL
     AND fbl.c_projecttask_id = p_workstep_ID;

    v_g := (v_g + 1);
    v_gui_mess := '@TimeFeedbackFinished@';
  END IF;

-- update timefeedback: this user, other worksteps, not finished
  SELECT COUNT(*) FROM zspm_ptaskfeedbackline fbl
  INTO v_recordCount
  WHERE 1=1
   AND fbl.ad_user_id = p_user_ID
   AND fbl.hour_to IS NULL
   AND fbl.c_projecttask_id <> p_workstep_ID;

  IF (v_recordCount >= 1) THEN
    UPDATE zspm_ptaskfeedbackline fbl SET
      hour_to = v_timestamp,
      updatedby = p_user_id,
      updated = now()
    WHERE 1=1
     AND fbl.ad_user_id = p_user_ID
     AND fbl.hour_to IS NULL
     AND fbl.c_projecttask_id <> p_workstep_ID;

    v_g := (v_g + 1);
    v_gui_mess := '@TimeFeedbackFinished@';
  END IF;
  RETURN v_gui_mess;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC: pdc_settimefeedback()' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_PFeedbackUpperGrid(p_workstepid VARCHAR,p_pconsumptionid VARCHAR,p_dconsumptionid VARCHAR, out wsbomid varchar,out outtype varchar, out issuing_locator_out varchar, out m_product_id_out varchar, out returnquantity numeric)RETURNS SETOF RECORD
AS $body$
DECLARE
  v_cur RECORD;
  v_count INTEGER;
  v_goalqty numeric;
  v_producedqty numeric;
  v_plannedqty numeric;
  v_oneqty numeric;
  v_possibleqty numeric:=0;
  v_consumed numeric;
  v_leftqty numeric;
  v_prec numeric;
  v_product varchar;
  v_intransaction numeric;
  i integer;
  v_issuingloc varchar; 
BEGIN
  select count(*) into v_count from c_projecttask pt where pt.c_projecttask_id=p_workstepid and pt.assembly='Y' and pt.m_product_id is not null;
  if v_count=1 then --assembling Workstep.
     select trunc(qtyproduced),trunc(qty),m_product_id ,issuing_locator into v_producedqty,v_plannedqty,v_product,v_issuingloc from c_projecttask where c_projecttask_id=p_workstepid;
     -- 1st assume all production is possible.
     v_possibleqty:=v_plannedqty-v_producedqty;
     -- How many Items can be produced??
     FOR v_cur IN (select zspm_projecttaskbom_id as zspm_projecttaskbom_id,qtyreceived as qtyreceived,quantity as quantity,m_product_id 
                   from zspm_projecttaskbom where c_projecttask_id=p_workstepid)
     LOOP
        select uom.stdprecision into v_prec from zspm_projecttaskbom bom,m_product p,c_uom uom where uom.c_uom_id=p.c_uom_id and p.m_product_id=bom.m_product_id and bom.zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id;
        v_oneqty:=v_cur.quantity / (case coalesce(v_plannedqty,1) when 0 then 1 else coalesce(v_plannedqty,1) end);
        v_consumed:=v_oneqty*v_producedqty;
        v_leftqty:=v_cur.qtyreceived-v_consumed;
        v_goalqty:=v_oneqty*(v_possibleqty);
        if (v_goalqty>v_leftqty) then
          FOR i IN 0..v_possibleqty LOOP
            v_goalqty:=v_oneqty*i;
            if v_goalqty>v_leftqty then
              v_possibleqty:=i-1;
              EXIT;
            end if;
          END LOOP;
        end if;
     END LOOP;
     -- Offer Possible Production - minus All scanned Production
     select coalesce(sum(movementqty),0) into v_intransaction from m_internal_consumptionline where m_internal_consumption_id=p_pconsumptionid and m_product_id=v_product;
     if v_possibleqty-v_intransaction>0 then
        wsbomid:=get_uuid();
        outtype:='PROD';
        issuing_locator_out:=v_issuingloc;
        m_product_id_out:=v_product;
        returnquantity:=v_possibleqty-v_intransaction;
        if returnquantity>0 then
                RETURN NEXT;
        end if;
     end if;
    -- Offer Rest Material, That cannot be completely built up to the assembly
    FOR v_cur IN (select max(zspm_projecttaskbom_id) as zspm_projecttaskbom_id,sum(qtyreceived) as qtyreceived,sum(quantity) as quantity,m_product_id,issuing_locator 
                  from zspm_projecttaskbom where c_projecttask_id=p_workstepid and consumption='N' group by m_product_id,issuing_locator)
    LOOP
        select uom.stdprecision into v_prec from zspm_projecttaskbom bom,m_product p,c_uom uom where uom.c_uom_id=p.c_uom_id and p.m_product_id=bom.m_product_id and bom.zspm_projecttaskbom_id=v_cur.zspm_projecttaskbom_id;
        v_oneqty:=v_cur.quantity / (case coalesce(v_plannedqty,1) when 0 then 1 else coalesce(v_plannedqty,1) end);
        v_consumed:=v_oneqty*(v_producedqty+v_possibleqty);
        v_leftqty:=v_cur.qtyreceived-v_consumed;
        select coalesce(sum(movementqty),0) into v_intransaction from m_internal_consumptionline where m_internal_consumption_id=p_dconsumptionid and m_product_id=v_cur.m_product_id;
        if (v_leftqty-v_intransaction>0) then
            outtype:='MAT';
            wsbomid:=get_uuid();
            issuing_locator_out:=v_cur.issuing_locator;
            m_product_id_out:=v_cur.m_product_id;
            returnquantity:=v_leftqty-v_intransaction;
            if returnquantity>0 then
                RETURN NEXT;
            end if;
        end if;
    END LOOP;
  else -- not assembing workstep
    -- Only in other Workstep produced Item (FIRST ITEM OF THE BOM) shall leave Workstep
    FOR v_cur IN (select qtyreceived,m_product_id,issuing_locator 
                  from zspm_projecttaskbom where c_projecttask_id=p_workstepid order by line limit 1) 
    LOOP
      if coalesce(v_cur.qtyreceived,0)>0 then
        outtype:='PROD';
        select issuing_locator into v_issuingloc from c_projecttask where c_projecttask_id=p_workstepid;
        issuing_locator_out:=v_issuingloc;
        m_product_id_out:=v_cur.m_product_id;
        select coalesce(sum(movementqty),0) into v_intransaction from m_internal_consumptionline where m_internal_consumption_id=p_pconsumptionid and m_product_id=v_cur.m_product_id;
        returnquantity:=v_cur.qtyreceived-v_intransaction;
        if returnquantity>0 then
            RETURN NEXT;
        end if;
      end if;
    END LOOP;
  end if;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_isProductionPlannedSerialPossible(p_workstepid VARCHAR,p_plannedserial varchar) RETURNS varchar
AS $body$
DECLARE
  v_cur RECORD;
  v_count INTEGER;

  v_receivedqty numeric;
  v_oneqty numeric;
 v_plannedqty numeric;
BEGIN
  select count(*) into v_count from c_projecttask pt where pt.c_projecttask_id=p_workstepid and pt.assembly='Y';
  if v_count=1 then --assembling Workstep.
    select count(*) into v_count from m_internal_consumption where plannedserialnumber=p_plannedserial and movementtype='P+' and processed='Y';
    if v_count>0 then -- Already produced?
        RETURN 'N';
    end if;
     select trunc(qty) into v_plannedqty from c_projecttask where c_projecttask_id=p_workstepid;
     -- On Planned Serials always qty=1 
     FOR v_cur IN (select zspm_projecttaskbom_id as zspm_projecttaskbom_id,qtyreceived as qtyreceived,quantity as quantity,m_product_id 
                   from zspm_projecttaskbom where c_projecttask_id=p_workstepid)
     LOOP
        v_oneqty:=v_cur.quantity / (case coalesce(v_plannedqty,1) when 0 then 1 else coalesce(v_plannedqty,1) end);
        select sum((case when m.movementtype='M+' then -1 else 1 end)*ml.movementqty) into v_receivedqty from m_internal_consumptionline ml,m_internal_consumption m where m.m_internal_consumption_id=ml.m_internal_consumption_id
            and m.processed='Y' and ml.c_projecttask_id=p_workstepid and ml.m_product_id=v_cur.m_product_id and m.plannedserialnumber=p_plannedserial;
            --raise notice '%',v_cur.m_product_id||'#'|| coalesce(v_receivedqty,0)||'#'||
        if coalesce(v_receivedqty,0)<v_oneqty then
            RETURN 'N';
        end IF;
     END LOOP;
     RETURN 'Y';
  end if;
  RETURN 'N';
END;
$body$
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION pdc_bc_btn_cancel() RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_btn_cancel()
  RAISE NOTICE 'pdc_bc_btn_cancel()=''%''', '57C99C3D7CB5459BADEC665F78D3D6BC';
  RETURN '57C99C3D7CB5459BADEC665F78D3D6BC';
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_bc_btn_finish() RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_btn_finish();
  RAISE NOTICE 'pdc_bc_btn_finish=''%''', '48AE377FD5224514A54E9AE666BE5CC7';
  RETURN '48AE377FD5224514A54E9AE666BE5CC7';
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_bc_btn_next() RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_btn_next()
  RAISE NOTICE 'pdc_bc_btn_next()=''%''', '8521E358B73444A6A999C55CBCCACC75';
  RETURN '8521E358B73444A6A999C55CBCCACC75';
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_bc_btn_ready() RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_btn_ready()
  RAISE NOTICE 'pdc_bc_btn_ready()=''%''', 'B28DAF284EA249C48F932C98F211F257';
  RETURN 'B28DAF284EA249C48F932C98F211F257';
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_bc_btn_splitbatch() RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_btn_splitbatch() = 'D0F216CC7D9D4EA0A7528744BB8D544C';
  -- RAISE NOTICE 'pdc_bc_btn_splitbatch=''%''', 'D0F216CC7D9D4EA0A7528744BB8D544C';
  RETURN 'D0F216CC7D9D4EA0A7528744BB8D544C';
END ;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION pdc_bc_dialog_acknowledgement() RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_dialog_acknowledgement () = '56BA860751594541972B4CFF06CB0FC5'
  RAISE NOTICE 'pdc_bc_dialog_acknowledgement=''%''', '56BA860751594541972B4CFF06CB0FC5';
  RETURN '56BA860751594541972B4CFF06CB0FC5';
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_bc_dialog_material_consumption () RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_dialog_material_consumption() 
  RAISE NOTICE 'pdc_bc_dialog_material_consumption=''%''', 'ADA36B3EF12E4E50BC40A88E4233C330';
  RETURN 'ADA36B3EF12E4E50BC40A88E4233C330';
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_bc_dialog_material_return () RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_dialog_material_return ()
  RAISE NOTICE 'pdc_bc_dialog_material_return=''%''', 'EDD4E08D4C324816AE3C1B09155A51A6';
  RETURN 'EDD4E08D4C324816AE3C1B09155A51A6';
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pdc_bc_dialog_timefeedback () RETURNS VARCHAR AS
$body$
BEGIN
  -- SELECT pdc_bc_dialog_timefeedback()
  RAISE NOTICE 'pdc_bc_dialog_timefeedback=''%''', '872C3C326AB64D1EBABDD49A1E138136';
  RETURN '872C3C326AB64D1EBABDD49A1E138136';
END ;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_dropview('pdc_workstepbom_v');
CREATE VIEW pdc_workstepbom_v 
AS
SELECT
  zspmwsbom.zspm_projecttaskbom_id AS pdc_workstepbom_v_id,
  zspmwsbom.zspm_projecttaskbom_id,
  zspmwsbom.c_projecttask_id AS zssm_workstep_v_id,
  zspmwsbom.ad_client_id,
  zspmwsbom.ad_org_id,
  zspmwsbom.isactive,
  zspmwsbom.created,
  zspmwsbom.createdby,
  zspmwsbom.updated,
  zspmwsbom.updatedby,
  zspmwsbom.m_product_id,
  zspmwsbom.line,
  zspmwsbom.quantity,
  case when t.assembly='N' and zspmwsbom.line=10 then 1 else case when t.qty >0 then zspmwsbom.quantity/t.qty else 0 end end as qtyforone,
  case when t.assembly='N' and zspmwsbom.line=10 then t.qty-t.qtyproduced-zspmwsbom.qtyreceived else case when t.qty >0 and t.qtyproduced>0 then zspmwsbom.quantity-zspmwsbom.quantity*(t.qtyproduced/t.qty) else zspmwsbom.quantity end end AS qtyrequired,
  case when t.assembly='N' and zspmwsbom.line=10 then zspmwsbom.qtyreceived else case when t.qty >0 and t.qtyproduced>0 then zspmwsbom.qtyreceived-zspmwsbom.quantity*(t.qtyproduced/t.qty) else zspmwsbom.qtyreceived end end as qtyreceived, -- set by trigger or function
  zspmwsbom.receiving_locator,
  zspmwsbom.issuing_locator,
  zspmwsbom.m_locator_id,
  zspmwsbom.description,
  p.value,
-- zspmwsbom.actualcosamount,
-- zspmwsbom.constuctivemeasure,
-- zspmwsbom.rawmaterial,
-- zspmwsbom.cutoff,
-- zspmwsbom.qty_plan,
-- zspmwsbom.qtyreserved,
-- zspmwsbom.qtyinrequisition,
-- zspmwsbom.date_plan,
-- zspmwsbom.planrequisition,
  m_bom_qty_onhand(zspmwsbom.m_product_id, NULL, zspmwsbom.receiving_locator) AS qty_available
FROM
  zspm_projecttaskbom zspmwsbom,c_projecttask t,m_product p where t.c_projecttask_id=zspmwsbom.c_projecttask_id and zspmwsbom.m_product_id=p.m_product_id ;
  
  
  
  
select zsse_dropfunction('pdc_insertnewbom');
CREATE or replace FUNCTION pdc_insertnewbom(p_client_id character varying, p_org_id character varying, p_user_id character varying, p_product_id character varying, p_serial character varying, p_locator character varying)  RETURNS character varying
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
OVERLOAD For sheduled Processes
select pdc_insertnewbom('C726FEC915A54A0995C568555DA5BB3C','1AF9E07685234E0A9FEC1D9B58A4876B','DDAA21D11CB04D4D8EC59E39934B27FB','757F8FB81CC24150A7EDE4BC7B7012D9','Funkionstest');
*****************************************************/
v_cur RECORD;
v_check boolean;
v_return character varying :='';
v_mintid character varying := get_uuid();
v_lineid character varying := get_uuid();
BEGIN
--Select exists(select 1 from snr_masterdata where serialnumber=p_serial) into v_check;
--Select CASE WHEN (p_client_id is null or p_client_id='') then 'Client ID missing' WHEN (p_org_id is null or p_org_id='') then 'Org ID missing' WHEN (p_user_id is null or p_user_id='') then 'User ID missing' WHEN (p_product_id is null or p_product_id='') then 'Product ID missing' WHEN (p_serial is null or p_serial ='') then 'Serialnumber is missing' WHEN (exists(select 'f' from snr_masterdata where serialnumber=p_serial and m_product_id=p_product_id)) then 'Serialnumber exists already' when (p_locator is null or p_locator='') then 'Locator is missing' else '' END into v_return;
Select CASE WHEN (p_org_id is null or p_org_id='') then 'Org ID missing' WHEN (p_client_id is null or p_client_id='') then 'Client ID missing' WHEN (p_user_id is null or p_user_id='') then 'User ID missing' WHEN (p_product_id is null or p_product_id='') then 'Product ID missing' WHEN (p_serial is null or p_serial ='') then 'Serialnumber is missing' else '' END into v_return;

if (exists(select 1 from snr_masterdata where serialnumber=p_serial and m_product_id=p_product_id)) then
    raise notice '%','Serialnumber is already in use';
    v_return:='Error: Serialnumber is already in use';
else
        if  (coalesce(p_locator,'') != '' and v_return='') then 
        --Consumption Header
        if    (v_return='') then

            insert into M_INTERNAL_CONSUMPTION(
            M_INTERNAL_CONSUMPTION_ID, 
            AD_CLIENT_ID, 
            AD_ORG_ID,
            ISACTIVE,
            CREATED, 
            CREATEDBY, 
            UPDATED, 
            UPDATEDBY,                    
            NAME, 
            DESCRIPTION, 
            MOVEMENTDATE,
            dateacct, 
            MOVEMENTTYPE,
            DOCUMENTNO)
                    values(
            v_mintid,
            p_client_id,
            p_org_id,
            'Y',
            now(),
            p_user_id,
            now(),
            p_user_id,
            'INITIAL',
            'Generated by PDC-Transaction',
            now(),
            now(),
            'D+',
            ad_sequence_doc('Production',p_org_id,'Y'));
        --Consumption LINE      
            insert into M_INTERNAL_CONSUMPTIONLINE(
            M_INTERNAL_CONSUMPTIONLINE_ID, 
            AD_CLIENT_ID, 
            AD_ORG_ID, 
            CREATED, 
            CREATEDBY, 
            UPDATED, 
            UPDATEDBY, 
            M_INTERNAL_CONSUMPTION_ID,
            M_LOCATOR_ID, 
            M_PRODUCT_ID, 
            LINE, 
            MOVEMENTQTY, 
            DESCRIPTION, 
            C_UOM_ID)
                        values(
            v_lineid,
            p_client_id,
            p_org_id,
            now(),
            p_user_id,
            now(),
            p_user_id,
            v_mintid,
            p_locator,
            p_product_id,
            '10',
            1,
            '',
            (select c_uom_id from m_product where m_product_id=p_product_id));
        --Consumption SNR
            insert into snr_INTERNAL_CONSUMPTIONLINE(
            snr_internal_consumptionline_id, 
            AD_CLIENT_ID, 
            AD_ORG_ID, 
            CREATED, 
            CREATEDBY, 
            UPDATED, 
            UPDATEDBY, 
            M_INTERNAL_CONSUMPTIONLINE_ID,
            serialnumber)
                            values(
            get_uuid(),
            p_client_id,
            p_org_id,
            now(),
            p_user_id,
            now(),
            p_user_id,
            v_lineid,
            p_serial);
        v_return:=v_mintid;
        else

       end if;
       
      elsif (v_return='' and (p_locator is null or p_locator='')) then
       Insert into snr_masterdata
      (snr_masterdata_id, ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,m_product_id,serialnumber,firstseen, m_locator_id)
      (select v_mintid, p_client_id,p_org_id,'Y',now(),p_user_id,now(),p_user_id,p_product_id,p_serial,trunc(now()), coalesce(p_locator,''));

      --v_return:='Serialnumber: '||p_serial;
      v_return:=v_mintid;
      else
      
      v_return:='Error: Duplicate Serialnumber';
      end if;
end if;
      RETURN v_return;
END ; 
$_$ LANGUAGE 'plpgsql';

  
CREATE OR REPLACE FUNCTION pdc_getconfiguredemployeeuser(p_org varchar,p_userid varchar) RETURNS varchar LANGUAGE plpgsql   AS $_$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************
Returns attribute value at sequence from attributeset-Instance
*/
  
BEGIN
    if (select c_getconfigoption('bdeemployeepreselected', p_org))='Y' then
        if (select count(*) from c_bpartner b,ad_user u where u.c_bpartner_id=b.c_bpartner_id and b.isemployee='Y' and u.ad_user_id=p_userid)>0 then
            return p_userid;
        end if;
    end if;
    return '';
END; $_$;



SELECT zsse_DropView ('pdc_inouttrx_v');
CREATE VIEW pdc_inouttrx_v AS
  SELECT io.documentno||'-'||b.value||'-'||b.name||coalesce('-'||o.documentno,'')::varchar(2000) as name,io.m_inout_id as pdc_inouttrx_v_id,io.created,io.createdby,io.updated,io.updatedby,io.isactive,io.movementtype,io.ad_org_id,io.ad_client_id
  from m_inout io left join c_order o on o.c_order_id=io.c_order_id,c_bpartner b where b.c_bpartner_id=io.c_bpartner_id
    and io.docstatus='DR';
    
    
select zsse_dropfunction('m_pdcinoutstyle');
CREATE OR REPLACE FUNCTION  m_pdcinoutstyle(p_inoutline varchar) RETURNS varchar AS
$_$ 
DECLARE
 v_return varchar :='';
 v_inout varchar;
 v_org varchar;
 v_usecase varchar:='';
 v_cur record;
BEGIN

    select m_inout_id,ad_org_id into v_inout,v_org from m_inoutline where m_inoutline_id=p_inoutline;
    if c_getconfigoption('PDCINOUTFULLSCAN',v_org)='N' then
        v_usecase:='SERIAL';
    end if;
    for v_cur in (select a.m_inoutline_id,row_number() over() as linecnt,a.todos,a.pdcproduct,a.pdclocator,a.movementqty as pdcqty,a.m_product_id,a.isserialtracking,a.isbatchtracking from
            (Select f.m_inoutline_id,p.m_product_id,p.isserialtracking,p.isbatchtracking,
            case when (p.isserialtracking='Y' or  p.isbatchtracking='Y') and coalesce(sum(snr.quantity),0)!=f.movementqty then 'TODO' else 'READY' end as todos,
            '' AS pdcproduct,
            l.value as pdclocator,f.movementqty
            from m_product p,m_inoutline f left join  m_locator l on  f.m_locator_id=l.m_locator_id
                                                left join snr_minoutline snr on f.m_inoutline_id=snr.m_inoutline_id
            where f.m_inout_id=v_inout
            and p.m_product_id=f.m_product_id 
            and case when v_usecase = 'SERIAL' then isserialtracking='Y' or isbatchtracking='Y' else 1=1 end
            group by f.m_inoutline_id,f.m_product_id,p.isserialtracking, p.isbatchtracking,f.movementqty,l.value,p.m_product_id
            order by case when (p.isserialtracking='N' and  p.isbatchtracking='N') or coalesce(sum(snr.quantity),0)=f.movementqty then f.line+1000 else f.line end) a
        order by linecnt)
    LOOP
        if v_cur.m_inoutline_id=p_inoutline then
            if v_cur.todos='TODO' and v_cur.linecnt=1 then
                v_return:=' color:black; background-color:#ffff00;';
            end if;
            if v_cur.todos='TODO' and v_cur.linecnt>1 then
                v_return:='';
            end if;
            if v_cur.todos='READY'  then
                v_return:=' color:black; background-color:#006600;'; 
            end if;
            RETURN v_return;
        end if;
    END LOOP;
    RETURN v_return;
END;
$_$ LANGUAGE plpgsql;



select zsse_dropfunction('pdc_internalconsumptionclean');
CREATE OR REPLACE FUNCTION  pdc_internalconsumptionclean() RETURNS varchar AS
$_$ 
DECLARE                                                                                                                                                       
/***************************************************************************************************************************************************          
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in                          
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html                                                  
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the                   
License for the specific language governing rights and limitations under the License.                                                                         
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)                                       
Contributor(s): ______________________________________.                                                                                                       
***************************************************************************************************************************************************           
OVERLOAD For sheduled Processes                                                                                                                               
*****************************************************/                                                                                                        
v_cur RECORD;                                                                                                                                                 
BEGIN                                                                                                                                                         
    for v_cur in (select m_internal_consumption_id from m_internal_consumption 
                            where (name='Production-Process' or name like '%Generated by PDC%') and      
                                processed='N' )  
    loop 
        delete from snr_internal_consumptionline where m_internal_consumptionline_id in (select m_internal_consumptionline_id from m_internal_consumptionline 
                                                                                        where m_internal_consumption_id=v_cur.m_internal_consumption_id); 
        delete from m_internal_consumptionline where m_internal_consumption_id=v_cur.m_internal_consumption_id;     
        delete from m_internal_consumption where m_internal_consumption_id=v_cur.m_internal_consumption_id;    
    end loop;   
    return 'Internal Consumptions cleaned Up';  
END ; 

$_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_getReturnQtyBomProduct');
CREATE OR REPLACE FUNCTION  pdc_getReturnQtyBomProduct(p_workstepId varchar,p_product_id varchar,p_snrbnr varchar) RETURNS numeric AS
$_$ 
DECLARE                                                                                                                                                       
/***************************************************************************************************************************************************          
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in                          
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html                                                  
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the                   
License for the specific language governing rights and limitations under the License.                                                                         
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)                                       
Contributor(s): ______________________________________.                                                                                                       
***************************************************************************************************************************************************           
                                                                                                            
*****************************************************/                                                                                                        
v_cur RECORD;        
v_qtyfor1 numeric;
v_prodqty numeric;
v_planqty numeric;
v_qtyreceived numeric;
BEGIN   
    select qtyproduced,case when qty is null then 1 when qty=0 then 1 else qty end into v_prodqty,v_planqty from c_projecttask where c_projecttask_id=p_workstepId;
        select bom.quantity/v_planqty ,qtyreceived into v_qtyfor1,v_qtyreceived from zspm_projecttaskbom bom,c_projecttask  t where t.c_projecttask_id=bom.c_projecttask_id 
            and bom.m_product_id=p_product_id and t.c_projecttask_id=p_workstepId;
    if p_snrbnr is null or p_snrbnr='' then -- Workstep-Level Calculation
        return to_char(v_qtyreceived - v_qtyfor1*v_prodqty);
    else -- Material TRX Calculation
       if (select count(*) from  m_internal_consumption where c_projecttask_id=p_workstepId and processed='Y' and movementtype='P+' and plannedserialnumber=p_snrbnr)>0 then
            return '0';
       end if;
       select sum(case when m.movementtype='D+' then -1 else 1 end * ml.movementqty) into v_qtyreceived from m_internal_consumptionline ml,m_internal_consumption m
            where m.m_internal_consumption_id=ml.m_internal_consumption_id and m.c_projecttask_id=p_workstepId and ml.m_product_id=p_product_id
                  and m.processed='Y' and m.plannedserialnumber=p_snrbnr and m.movementtype in ('D+','D-');
       select sum(ml.movementqty) into v_prodqty from m_internal_consumptionline ml,m_internal_consumption m
            where m.m_internal_consumption_id=ml.m_internal_consumption_id and m.c_projecttask_id=p_workstepId and ml.m_product_id=p_product_id
                  and m.processed='Y' and m.plannedserialnumber=p_snrbnr and m.movementtype='P+';
       if (coalesce(v_qtyreceived,0)-coalesce(v_prodqty,0))>0 then
            return coalesce(v_qtyreceived,0)-coalesce(v_prodqty,0);
       else
            return '0';
       end if;
    end if;
END ; $_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_adjustpassingworkstepqtys');
CREATE OR REPLACE FUNCTION  pdc_adjustpassingworkstepqtys(p_workstep varchar,p_qty numeric,p_consumption_id varchar) RETURNS varchar AS
$_$ 
DECLARE                                                                                                                                                       
/***************************************************************************************************************************************************          
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in                          
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html                                                  
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the                   
License for the specific language governing rights and limitations under the License.                                                                         
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)                                       
Contributor(s): ______________________________________.                                                                                                       
***************************************************************************************************************************************************           
OVERLOAD For sheduled Processes                                                                                                                               
*****************************************************/                                                                                                        
v_bom varchar;                                                                                                                                               
BEGIN                                                                                                                                                         
    if (select assembly from c_projecttask where c_projecttask_id=p_workstep)='N' then
    if (select m_product_id from c_projecttask where c_projecttask_id=p_workstep) is null then
            select zspm_projecttaskbom_id into v_bom  from zspm_projecttaskbom where  c_projecttask_id=p_workstep order by line limit 1;
            update zspm_projecttaskbom set quantity=quantity-p_qty  where zspm_projecttaskbom_id=v_bom;
            update m_internal_consumption set movementtype='D+' where m_internal_consumption_id=p_consumption_id;
            update c_projecttask set qtyproduced=qtyproduced+p_qty where c_projecttask_id=p_workstep;
            return 'Passing Worksteps Qtys adjusted';  
    end if;
    end if;
    return 'NO Passing Worksteps';  
END ; 
$_$ LANGUAGE plpgsql;
