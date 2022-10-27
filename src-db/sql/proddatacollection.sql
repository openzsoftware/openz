/* ProdDataCollection.sql */

SELECT zsse_DropView ('pdc_barcode_v');
CREATE VIEW pdc_barcode_v AS
  SELECT 'D' as ord,bp.value::varchar(200) AS barcode, 'EMPLOYEE' AS type, u.ad_user_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM ad_user u, c_bpartner bp
  WHERE 1=1
   AND bp.c_bpartner_id = u.c_bpartner_id
   AND bp.isemployee = 'Y' and bp.isactive='Y' and u.isactive='Y'
 UNION
  SELECT 'A' as ord,l.value::varchar(200) AS barcode, 'LOCATOR' AS type, l.m_locator_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM m_locator l where l.isactive='Y'
 UNION
 -- SELECT 'B' as ord,p.value::varchar(200) AS barcode, 'PRODUCT' AS type, p.m_product_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
 -- FROM m_product p where p.isactive='Y'
 --UNION
 SELECT 'C' as ord,coalesce(ws.value,pro.value||'-'||ws.name)::varchar(200) AS barcode, 'WORKSTEP' AS type, ws.c_projecttask_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM c_projecttask ws, c_project pro 
  WHERE ws.c_project_id = pro.c_project_id and pro.projectcategory != 'PRP'
 UNION
  SELECT 'E' as ord,e.columnname::varchar(200) AS barcode, 'CONTROL' AS type, e.ad_element_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM ad_element e WHERE e.ad_module_id = '000CDBE191604F5A835A3EC3213719E8' AND description like 'CODE-128-code action%'
 UNION 
  SELECT 'H' as ord,e.columnname::varchar(200) AS barcode, 'CALCULATION' AS type, e.ad_element_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM ad_element e WHERE e.ad_module_id = '000CDBE191604F5A835A3EC3213719E8' AND description='scan calc'
 UNION
  SELECT 'F' as ord,l.serialnumber::varchar(200) AS barcode, 'SERIALNUMBER' AS type, l.snr_masterdata_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM snr_masterdata l
 UNION
  SELECT 'G' as ord,l.batchnumber::varchar(200) AS barcode, 'BATCHNUMBER' AS type, l.snr_batchmasterdata_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM snr_batchmasterdata l
 UNION
  SELECT 'I' as ord,l.documentno::varchar(200) AS barcode, case when l.issotrx='Y' then 'SHIPMENT' else 'RECEIPT' end AS type, l.m_inout_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
  FROM m_inout l;

CREATE OR REPLACE FUNCTION pdc_getDataIdFromScan(p_value VARCHAR)
RETURNS SETOF pdc_barcode_v -- value, type, id, mess, ad_message_value
AS $body$
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
  v_snrvalue varchar;
  v_btchvalue varchar;
  v_weight varchar;
BEGIN
  BEGIN
    if instr(p_value,'|')>0 and c_getconfigoption('kombibarcode','0')='Y' then
        select SPLIT_PART(p_value, '|', 1) into v_prodvalue; -- 1St Part always Product Value
        select SPLIT_PART(p_value, '|', 2) into v_snrorbtchvalue;-- 2nd Part (Serial or Batch)
        select SPLIT_PART(p_value, '|', 3) into v_btchvalue;-- 3rd Part 
        select SPLIT_PART(p_value, '|', 4) into v_weight;-- 4th Part 
        select isserialtracking,isbatchtracking,m_product_id  into v_serial,v_batch,v_product from m_product where value=v_prodvalue and isactive='Y';
        -- Serial always in 2nd Part.
        if coalesce(v_serial,'')='Y' then
           select snr.snr_masterdata_id
                  into v_serialid from snr_masterdata snr,m_product p where p.m_product_id=snr.m_product_id and p.m_product_id=v_product
                                             and snr.serialnumber=v_snrorbtchvalue;
           v_snrvalue:=v_snrorbtchvalue;
        end if;        
        -- Batch in New Barcodes 3rd Part
        if v_batch='Y' and v_btchvalue!=''  then   
            select snr.snr_batchmasterdata_id into v_batchid from snr_batchmasterdata snr,m_product p where p.m_product_id=snr.m_product_id and p.m_product_id=v_product
                                             and snr.batchnumber=v_btchvalue;
        end if;
        -- Batch in old Barcodes also in 2nd Part
        if v_batch='Y' and v_btchvalue=''  then
           select snr.snr_batchmasterdata_id into v_batchid from snr_batchmasterdata snr,m_product p where p.m_product_id=snr.m_product_id and p.m_product_id=v_product
                                             and snr.batchnumber=v_snrorbtchvalue;
           v_btchvalue:=v_snrorbtchvalue;
        end if;
        if v_product is not null then
            v_pdc_barcode_v.barcode := p_value;
            v_pdc_barcode_v.type := 'KOMBI';
            v_pdc_barcode_v.id := v_product;
            v_pdc_barcode_v.snrmasterdata_id := v_serialid;
            v_pdc_barcode_v.batchmasterdata_id := v_batchid;
            v_pdc_barcode_v.serialnumber:=v_snrvalue;
            v_pdc_barcode_v.lotnumber:=v_btchvalue;
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
        SELECT 'B' as ord,p.value::varchar(200) AS barcode, 'PRODUCT' AS type, p.m_product_id AS id, '' AS snrmasterdata_id,'' as batchmasterdata_id,null::numeric as weight,null::varchar(200) AS serialnumber,null::varchar(200) AS lotnumber
                   into v_pdc_barcode_v
        FROM m_product p where p.isactive='Y' and (p.value=p_value or p.upc=p_value);
        if v_pdc_barcode_v.type is not null then
            v_pdc_barcode_v.barcode := p_value;
            RETURN NEXT v_pdc_barcode_v;
            y := y + 1;
        else
            FOR v_resultSet IN
            (SELECT * FROM pdc_barcode_v bc  WHERE bc.barcode = p_value order by ord)
            LOOP
            y := y + 1;
            RETURN NEXT v_resultSet;
            END LOOP;
        end if;
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
  v_tmpsnr numeric;
  v_qty numeric;
BEGIN
  BEGIN
    if (select count(*) from m_internal_consumption where m_internal_consumption_id=p_consumption_id and relocationtrx='S')>0 then
        -- Seriel Relocation always OK
        return 'N';
    end if;
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
    select count(*) into v_tmpsnr from pdc_tempitems where m_internal_consumption_id = p_consumption_id;
    if (coalesce(v_qty,0)-(coalesce(v_snr,0) + coalesce(v_tmpsnr,0)))!=0 THEN 
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

-- For Task Feedback...
select zsse_dropview('zspm_workstepdropdown_v');
CREATE OR REPLACE VIEW zspm_workstepdropdown_v AS
SELECT pt.c_projecttask_id as zspm_workstepdropdown_v_id,p.ad_org_id,p.ad_client_id,p.updated,p.updatedby,p.created,p.createdby,'Y'::character as isactive, 
       p.name||'-'||pt.name as name,pt.c_projecttask_id,p.projectstatus
FROM c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id and p.projectstatus in ('OP','OR') and pt.iscomplete='N' and pt.istaskcancelled='N' and p.ishidden='N'
     and pt.taskbegun='Y' and pt.feedbackfinished='N' and not exists (select 0 from c_bpartner b where b.c_project_id=p.c_project_id);


select zsse_DropFunction ('pdc_settimefeedback');
CREATE OR REPLACE FUNCTION pdc_settimefeedback (p_org_id varchar, p_workstep_id varchar, p_user_id varchar, p_timestamp timestamp,p_command varchar,p_description varchar,p_lang varchar)
RETURNS varchar AS
$body$
DECLARE

  v_message  VARCHAR:='';
  v_prj varchar;
  v_prt varchar;
  v_tprj varchar; -- Reines Zeiterfassungsprojekt
  v_tprt varchar;
  v_description varchar;
  v_timestamp_now timestamp:=now();
  v_timestamp timestamp:='0001-01-01 00:00:00 BC'::timestamp   -- nur ab Stunden speichern, Tag ist immer 01.01.0001 -> Einheitlich mit Datum aus der GUI
                         + (extract(hour from v_timestamp_now)) * interval '1 hour'
                         + (extract(minute from v_timestamp_now)) * interval '1 minute'
                         + (extract(second from v_timestamp_now)) * interval '1 second';
BEGIN
  if p_org_id is null then return 'COMPILE'; end if;
  if p_description is not null and p_description!='' then 
    v_description:=p_description;
  end if;
  -- Reines Zeiterfassungsprojekt (Komen/Gehen)
  select  b.c_project_id into v_tprj from c_bpartner b,ad_user u where u.c_bpartner_id=b.c_bpartner_id and u.ad_user_id=p_user_id;
  select c_projecttask_id into v_tprt from c_projecttask where c_project_id=v_tprj and taskbegun='Y' and feedbackfinished='N' and iscomplete='N' and istaskcancelled='N' order by seqno limit 1;
  -- Arbeitsprojekt
  if p_workstep_id is not null and p_workstep_id!=coalesce(v_tprt,'') then
    select c_project_id into v_prj from c_projecttask where c_projecttask_id=p_workstep_id;
    v_prt:=p_workstep_id;
  end if; 
  if v_prt is null and v_tprt is null then
    raise exception '%','Kein Projekt gefunden. Zeitrückmeldung nicht möglich.';
  end if;
  -- Arbeisprojekt wird immer zurückgemeldet, sofern angegeben.
  if v_prt is not null then 
    IF (SELECT count(*) from zspm_ptaskfeedbackline where ad_user_id=p_user_id and hour_from is not null and hour_to is null and c_projecttask_id = v_prt and createdbytimefeedbackapp = 'Y')=0  and p_command!='LEAVING' THEN
        -- Projekt anmelden
        INSERT INTO zspm_ptaskfeedbackline (
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
            hour_to,
            description,
            createdbytimefeedbackapp
        )
        VALUES (
            get_uuid(),
            'C726FEC915A54A0995C568555DA5BB3C', --  ad_client_id VARCHAR(32) NOT NULL,
            p_org_ID,                           --  ad_org_id VARCHAR(32) NOT NULL,
            p_user_id,          --  createdby VARCHAR(32) NOT NULL,
            p_user_id,          --  updatedby VARCHAR(32) NOT NULL,
            v_prj,     -- c_project_id VARCHAR(32) NOT NULL,
            v_prt,      -- c_projecttask_id VARCHAR(32) NOT NULL,
            p_user_id,          -- ad_user_id VARCHAR(32),
            TRUNC(v_timestamp_now), -- workdate TIMESTAMP WITHOUT TIME ZONE NOT NULL,
            v_timestamp,        -- hour_from TIMESTAMP WITHOUT TIME ZONE,
            NULL ,               -- hour_to TIMESTAMP WITHOUT TIME ZONE,
            v_description,
            'Y'                  -- createdbytimefeedbackapp character(1) not null default 'N'
        );
        -- Evtl anderes offenes Projekt abmelden
        UPDATE zspm_ptaskfeedbackline fbl SET
            hour_to = v_timestamp,
            updatedby = p_user_id,
            updated = now(),
            description=coalesce(v_description,description) 
        WHERE fbl.ad_user_id = p_user_ID
            AND fbl.hour_to IS NULL
            AND fbl.c_projecttask_id != v_prt
            AND fbl.c_projecttask_id != coalesce(v_tprt,'')
            AND createdbytimefeedbackapp = 'Y'; -- nur projekte abmelden, die über app angemeldet wurden
            v_message:='Aufgabe Beginn';
    ELSE -- Projekt abmelden
        UPDATE zspm_ptaskfeedbackline fbl SET
        hour_to = v_timestamp,
        updatedby = p_user_id,
        updated = now(),
        description=coalesce(v_description,description) 
        WHERE fbl.ad_user_id = p_user_ID
        AND fbl.hour_to IS NULL
        AND case when p_command='LEAVING' and v_tprt is null then 1=1 else fbl.c_projecttask_id = v_prt end
        AND createdbytimefeedbackapp = 'Y'; -- nur projekte abmelden, die über app angemeldet wurden
        if p_command='LEAVING' then
            v_message:='Arbeitszeit Ende';
        else
            v_message:='Aufgabe Ende';
        end if;
    END IF;
  END IF;
  if v_tprt is not null then 
    -- Zeiterfassungsprojekt rückmelden
    if p_command='COMING' then
        if (SELECT count(*) from zspm_ptaskfeedbackline where ad_user_id=p_user_id and hour_from is not null and hour_to is null and c_projecttask_id = v_tprt and createdbytimefeedbackapp = 'Y')>0 then
            raise exception '%','Zeit läuft bereits-Anmeldung nicht möglich.';
        else
            INSERT INTO zspm_ptaskfeedbackline (
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
            hour_to,
            description,
            createdbytimefeedbackapp
            )
            VALUES (
            get_uuid(),
            'C726FEC915A54A0995C568555DA5BB3C', --  ad_client_id VARCHAR(32) NOT NULL,
            p_org_ID,                           --  ad_org_id VARCHAR(32) NOT NULL,
            p_user_id,          --  createdby VARCHAR(32) NOT NULL,
            p_user_id,          --  updatedby VARCHAR(32) NOT NULL,
            v_tprj,     -- c_project_id VARCHAR(32) NOT NULL,
            v_tprt,      -- c_projecttask_id VARCHAR(32) NOT NULL,
            p_user_id,          -- ad_user_id VARCHAR(32),
            TRUNC(v_timestamp_now), -- workdate TIMESTAMP WITHOUT TIME ZONE NOT NULL,
            v_timestamp,        -- hour_from TIMESTAMP WITHOUT TIME ZONE,
            NULL,                -- hour_to TIMESTAMP WITHOUT TIME ZONE,
            v_description,
            'Y'                  -- createdbytimefeedbackapp character(1) not null default 'N'
            );
            if v_message !='' then
                v_message:='Arbeitszeit/Aufgabe Beginn';
            else
                v_message:='Arbeitszeit Beginn';
            end if;
        end if;
    end if;
    if p_command='LEAVING' then
        if (SELECT count(*) from zspm_ptaskfeedbackline where ad_user_id=p_user_id and hour_from is not null and hour_to is null and c_projecttask_id = v_tprt and createdbytimefeedbackapp = 'Y')=0 then
            raise exception '%','Nicht angemeldet-Abmeldung nicht möglich.';
        else
           -- zuerst möglichen Arbeitsschritt schließen, erst dann Zeiterfassungsprojekt
           UPDATE zspm_ptaskfeedbackline fbl SET
                hour_to = v_timestamp,
                updatedby = p_user_id,
                updated = now(),
                description=coalesce(v_description,description)
            WHERE fbl.ad_user_id = p_user_ID
            AND fbl.hour_to IS NULL
            AND fbl.createdbytimefeedbackapp = 'Y'
            AND fbl.c_projecttask_id != v_tprt; -- nicht Zeiterfassungsprojekt
            UPDATE zspm_ptaskfeedbackline fbl SET
                hour_to = v_timestamp,
                updatedby = p_user_id,
                updated = now(),
                description=coalesce(v_description,description)
            WHERE fbl.ad_user_id = p_user_ID
            AND fbl.hour_to IS NULL
            AND fbl.createdbytimefeedbackapp = 'Y';
            v_message:='Arbeitszeit Ende';
        end if;
     end if;
  end if;
  return v_message;
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


CREATE OR REPLACE FUNCTION pdc_getStrictBATCHPossibleQty(p_workstepid VARCHAR,p_plannedBtchNo VARCHAR) RETURNS numeric
AS $body$
DECLARE
  v_cur RECORD;
  v_count INTEGER;

  v_receivedqty numeric;
  v_producedqty numeric;
  v_oneqty numeric;
  v_plannedqty numeric;
  v_possibleqty numeric;
BEGIN
  select count(*) into v_count from c_projecttask pt where pt.c_projecttask_id=p_workstepid and pt.assembly='Y';
  if v_count=1 then --assembling Workstep.
     select sum(ml.movementqty) into v_producedqty from m_internal_consumptionline ml,m_internal_consumption m where m.m_internal_consumption_id=ml.m_internal_consumption_id
            and m.processed='Y' and ml.c_projecttask_id=p_workstepid and  m.plannedserialnumber=p_plannedBtchNo
            and m.movementtype ='P+';
     if v_producedqty is null then v_producedqty:=0; end if;
     select trunc(qty) into v_plannedqty from c_projecttask where c_projecttask_id=p_workstepid;
     v_possibleqty:=v_plannedqty-v_producedqty;
     -- Iterating BOM and Consumptions
     FOR v_cur IN (select zspm_projecttaskbom_id as zspm_projecttaskbom_id,qtyreceived as qtyreceived,quantity as quantity,m_product_id 
                   from zspm_projecttaskbom where c_projecttask_id=p_workstepid)
     LOOP
        v_oneqty:=(v_cur.quantity / (case coalesce(v_plannedqty,1) when 0 then 1 else coalesce(v_plannedqty,1) end));
        select sum((case when m.movementtype='D+' then -1 else 1 end)*ml.movementqty) into v_receivedqty from m_internal_consumptionline ml,m_internal_consumption m where m.m_internal_consumption_id=ml.m_internal_consumption_id
            and m.processed='Y' and ml.c_projecttask_id=p_workstepid and ml.m_product_id=v_cur.m_product_id and m.plannedserialnumber=p_plannedBtchNo
            and m.movementtype in ('D+','D-');
            --raise notice '%',v_cur.m_product_id||'#'|| coalesce(v_receivedqty,0)||'#'||
        if (coalesce(v_receivedqty,0)/v_oneqty)<v_possibleqty then
            v_possibleqty:=(coalesce(v_receivedqty,0)/v_oneqty);
        end IF;
     END LOOP;
  else -- Durchreiche 
    select sum((case when m.movementtype='M+' then -1 else 1 end) * snr.quantity) into v_possibleqty from snr_internal_consumptionline snr,m_internal_consumptionline l,m_internal_consumption m where l.m_internal_consumptionline_id=snr.m_internal_consumptionline_id and 
               l.m_internal_consumption_id=m.m_internal_consumption_id and l.c_projecttask_id=p_workstepid  and m.processed='Y' and m.plannedserialnumber=p_plannedBtchNo
               and snr.lotnumber=p_plannedBtchNo;
    if v_producedqty is null then v_producedqty:=0; end if;           
  end if;
  if round(v_possibleqty-v_producedqty,3)=0.000 then
    return null;
  else  
    RETURN v_possibleqty-v_producedqty;
  end if;
END;
$body$
LANGUAGE 'plpgsql';

select zsse_dropfunction('pdc_isProductionPlannedSerialPossible');
CREATE OR REPLACE FUNCTION pdc_isProductionPlannedSerialPossible(p_workstepid VARCHAR,p_plannedserial varchar,p_qtyprod numeric) RETURNS varchar
AS $body$
DECLARE
  v_cur RECORD;
  v_count INTEGER;

  v_receivedqty numeric;
  v_producedqty numeric;
  v_oneqty numeric;
 v_plannedqty numeric;
BEGIN
  select count(*) into v_count from c_projecttask pt where pt.c_projecttask_id=p_workstepid and pt.assembly='Y';
  if v_count=1 then --assembling Workstep.
     select sum(ml.movementqty) into v_producedqty from m_internal_consumptionline ml,m_internal_consumption m where m.m_internal_consumption_id=ml.m_internal_consumption_id
            and m.processed='Y' and ml.c_projecttask_id=p_workstepid and  m.plannedserialnumber=p_plannedserial
            and m.movementtype ='P+';
     if v_producedqty is null then v_producedqty:=0; end if;
     select trunc(qty) into v_plannedqty from c_projecttask where c_projecttask_id=p_workstepid;
     -- On Planned Serials always qty=1 
     FOR v_cur IN (select zspm_projecttaskbom_id as zspm_projecttaskbom_id,qtyreceived as qtyreceived,quantity as quantity,m_product_id 
                   from zspm_projecttaskbom where c_projecttask_id=p_workstepid)
     LOOP
        v_oneqty:=(v_cur.quantity / (case coalesce(v_plannedqty,1) when 0 then 1 else coalesce(v_plannedqty,1) end))*(p_qtyprod+v_producedqty);
        select sum((case when m.movementtype='D+' then -1 else 1 end)*ml.movementqty) into v_receivedqty from m_internal_consumptionline ml,m_internal_consumption m where m.m_internal_consumption_id=ml.m_internal_consumption_id
            and m.processed='Y' and ml.c_projecttask_id=p_workstepid and ml.m_product_id=v_cur.m_product_id and m.plannedserialnumber=p_plannedserial
            and m.movementtype in ('D+','D-');
            --raise notice '%',v_cur.m_product_id||'#'|| coalesce(v_receivedqty,0)||'#'||
        if coalesce(v_receivedqty,0)<v_oneqty then
            RETURN 'N';
        end IF;
     END LOOP;
     RETURN 'Y';
  else -- Durchreiche 
    if (select sum((case when m.movementtype='M+' then -1 else 1 end) * snr.quantity) from snr_internal_consumptionline snr,m_internal_consumptionline l,m_internal_consumption m where l.m_internal_consumptionline_id=snr.m_internal_consumptionline_id and 
               l.m_internal_consumption_id=m.m_internal_consumption_id and l.c_projecttask_id=p_workstepid  and m.processed='Y' and m.plannedserialnumber=p_plannedserial
               and (snr.lotnumber=p_plannedserial or snr.serialnumber=p_plannedserial))>=p_qtyprod
    then
        RETURN 'Y';
    end if;
  end if;
  RETURN 'N';
END;
$body$
LANGUAGE 'plpgsql';

select zsse_dropfunction('pdc_ProductionPlannedSerialQty');
CREATE OR REPLACE FUNCTION pdc_ProductionPlannedSerialQty(p_workstepid VARCHAR,p_plannedserial varchar) RETURNS varchar
AS $body$
DECLARE
  v_cur RECORD;
  v_count INTEGER;

  v_receivedqty numeric;
  v_producedqty numeric;
  v_oneqty numeric;
 v_plannedqty numeric;
 v_possibleqty numeric:=0;
BEGIN
  select count(*) into v_count from c_projecttask pt where pt.c_projecttask_id=p_workstepid and pt.assembly='Y';
  if v_count=1 then --assembling Workstep.
    select sum(ml.movementqty) into v_producedqty from m_internal_consumptionline ml,m_internal_consumption m where m.m_internal_consumption_id=ml.m_internal_consumption_id
            and m.processed='Y' and ml.c_projecttask_id=p_workstepid  and m.plannedserialnumber=p_plannedserial
            and m.movementtype ='P+';
     if v_producedqty is null then v_producedqty:=0; end if;
     select trunc(qty) into v_plannedqty from c_projecttask where c_projecttask_id=p_workstepid;
     -- On Planned Serials always qty=1 
     FOR v_cur IN (select zspm_projecttaskbom_id as zspm_projecttaskbom_id,qtyreceived as qtyreceived,quantity as quantity,m_product_id 
                   from zspm_projecttaskbom where c_projecttask_id=p_workstepid)
     LOOP
        v_oneqty:=(v_cur.quantity / (case coalesce(v_plannedqty,1) when 0 then 1 else coalesce(v_plannedqty,1) end));
        select sum((case when m.movementtype='M+' then -1 else 1 end)*ml.movementqty) into v_receivedqty from m_internal_consumptionline ml,m_internal_consumption m where m.m_internal_consumption_id=ml.m_internal_consumption_id
            and m.processed='Y' and ml.c_projecttask_id=p_workstepid and ml.m_product_id=v_cur.m_product_id and m.plannedserialnumber=p_plannedserial
            and m.movementtype in ('D+','D-');
            --raise notice '%',v_cur.m_product_id||'#'|| coalesce(v_receivedqty,0)||'#'||v_oneqty;
        if coalesce(v_receivedqty/v_oneqty,0)>v_possibleqty then
            v_possibleqty:=coalesce(v_receivedqty/v_oneqty,0);
        end IF;
     END LOOP;
     RETURN  zssi_strnumber(v_possibleqty-v_producedqty,'de_DE');
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
  round(case when t.assembly='N' and zspmwsbom.line=(select min(x.line) from zspm_projecttaskbom x where x.c_projecttask_id=t.c_projecttask_id) then 1 else case when t.qty >0 then zspmwsbom.quantity/t.qty else 0 end end,3) as qtyforone,
  round(case when t.assembly='N' and zspmwsbom.line=(select min(x.line) from zspm_projecttaskbom x where x.c_projecttask_id=t.c_projecttask_id) then t.qty-t.qtyproduced-zspmwsbom.qtyreceived else case when t.qty >0 and t.qtyproduced>0 then zspmwsbom.quantity-zspmwsbom.quantity*(t.qtyproduced/t.qty) else zspmwsbom.quantity end end,3) AS qtyrequired,
  round(case when t.assembly='N' and zspmwsbom.line=(select min(x.line) from zspm_projecttaskbom x where x.c_projecttask_id=t.c_projecttask_id) then zspmwsbom.qtyreceived else case when t.qty >0 and t.qtyproduced>0 then zspmwsbom.qtyreceived-zspmwsbom.quantity*(t.qtyproduced/t.qty) else zspmwsbom.qtyreceived end end,3) as qtyreceived, -- set by trigger or function
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
    and io.docstatus in ('DR','RS') and io.pdcpickinprogress='N' and io.isLogistic = 'N' order by io.documentno;
    
    

CREATE OR REPLACE FUNCTION  pdc_inoutIscomplete(p_inoutId varchar) RETURNS varchar AS
$_$ 
DECLARE
 v_return varchar :='TRUE';
 v_inout varchar;
 v_org varchar;
 v_usecase varchar:='';
 v_cur record;
BEGIN
    if p_inoutId is null or p_inoutId='' then return 'FALSE'; end if;
    for v_cur in (select * from m_inoutline where m_inout_id=p_inoutId)
    LOOP
        if v_cur.qtycontrolcount!=v_cur.movementqty then
            return 'FALSE';
        end if;
        if (SELECT p.isserialtracking||p.isbatchtracking from m_inoutline l,m_product p where l.m_inoutline_id=v_cur.m_inoutline_id and p.m_product_id =l.m_product_id)!='NN' then
            if (select sum(quantity) from snr_minoutline where m_inoutline_id=v_cur.m_inoutline_id)!=v_cur.movementqty then
                return 'FALSE';
            end if;
        end if;
    END LOOP;
    RETURN 'Y';
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
      
    for v_cur in (select m_inventory_id from m_inventory where name like '%PDC->%' and  processed='N')  
    loop 
        delete from m_inventoryline where m_inventory_id=v_cur.m_inventory_id;     
        delete from m_inventory where m_inventory_id=v_cur.m_inventory_id;     
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
v_ass varchar;
BEGIN   
    select qtyproduced,case when qty is null then 1 when qty=0 then 1 else qty end,assembly into v_prodqty,v_planqty,v_ass from c_projecttask where c_projecttask_id=p_workstepId;
    if v_ass='N' and (select m_product_id from pdc_workstepbom_v where zssm_workstep_v_id=p_workstepId order by line limit 1)=p_product_id then --- Durchreiche AG
      if p_snrbnr is null or p_snrbnr='' then -- Workstep-Level Calculation
        select sum(case when m.movementtype='D+' then -1 else 1 end * ml.movementqty) into v_qtyreceived from m_internal_consumptionline ml,m_internal_consumption m
            where m.m_internal_consumption_id=ml.m_internal_consumption_id and m.c_projecttask_id=p_workstepId and ml.m_product_id=p_product_id
                  and m.processed='Y' and m.movementtype in ('D+','D-');        
      else
        select sum(case when m.movementtype='D+' then -1 else 1 end * ml.movementqty) into v_qtyreceived from m_internal_consumptionline ml,m_internal_consumption m
            where m.m_internal_consumption_id=ml.m_internal_consumption_id and m.c_projecttask_id=p_workstepId and ml.m_product_id=p_product_id
                  and m.processed='Y' and m.plannedserialnumber=p_snrbnr and m.movementtype in ('D+','D-');
      end if;
      return coalesce(v_qtyreceived,0);
    end if;
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


select zsse_dropfunction('pdc_isTrxPossible');
CREATE OR REPLACE FUNCTION  pdc_isTrxPossible(p_consumptionId varchar,p_locatorId varchar,p_mProductId varchar,p_qty numeric, p_lang varchar) RETURNS varchar AS
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
    v_intrx numeric;
    v_stocked numeric;
BEGIN   
    select sum( qtyonhand) into v_stocked from m_storage_detail where m_product_id=p_mProductId and m_locator_id=p_locatorId;
    select sum(movementqty) into v_intrx from m_internal_consumptionline where m_product_id=p_mProductId and m_locator_id=p_locatorId and m_internal_consumption_id=p_consumptionId;
    if coalesce(v_stocked,0) < (case when p_qty=1 then (coalesce(v_intrx,0)+1) else p_qty end) then
        RETURN zssi_getText('underStock', p_lang)||coalesce(v_stocked,0)||')';
    else
        RETURN 'TRUE';
    end if;
END ; $_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_isSnrBnrTrxPossible');
CREATE OR REPLACE FUNCTION  pdc_isSnrBnrTrxPossible(p_locatorId varchar,p_mProductId varchar,p_qty numeric, p_snr varchar, p_btch varchar,p_lang varchar) RETURNS varchar AS
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
    v_intrx numeric;
    v_stocked numeric;
    v_isin  varchar;
BEGIN   
    if p_snr is not null and p_snr!='' then
        if (select count(*) from snr_masterdata where m_product_id=p_mProductId and serialnumber=p_snr and m_locator_id=p_locatorId)=0 then
            select l.value into v_isin from snr_masterdata s,m_locator l where s.m_product_id=p_mProductId and s.serialnumber=p_snr and s.m_locator_id=l.m_locator_id;
            RETURN zssi_getText('underStockSNR', p_lang)||coalesce('(In:'||v_isin||')','');
        end if;
    end if;
    if p_btch is not null and p_btch!='' then
        select bl.qtyonhand into v_intrx from snr_batchmasterdata b,snr_batchlocator bl where bl.snr_batchmasterdata_id=b.snr_batchmasterdata_id
                   and b.m_product_id=p_mProductId and b.batchnumber=p_btch and bl.m_locator_id=p_locatorId;
        if v_intrx is null then v_intrx:=0; end if;
        if v_intrx<p_qty then
            RETURN zssi_getText('underStockBNR', p_lang)||coalesce(v_intrx,0)||')';
        end if;
    end if;
    RETURN 'TRUE';
END ; $_$ LANGUAGE plpgsql;


select zsse_dropfunction('pdc_isRelocationPossible');
CREATE OR REPLACE FUNCTION  pdc_isRelocationPossible(p_consumptionId varchar,p_returnId varchar) RETURNS varchar AS
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
    v_return varchar:='Y';
    v_cur record;
    v_retqty numeric;
    v_tmpqty numeric;
BEGIN   
    for v_cur in (select sum(movementqty) as qty,m_product_id from m_internal_consumptionline where m_internal_consumption_id=p_consumptionId group by m_product_id)
    LOOP
        select sum(movementqty) into v_retqty from m_internal_consumptionline where m_internal_consumption_id=p_returnId and m_product_id=v_cur.m_product_id  group by m_product_id;
        if coalesce(v_retqty,0)!=v_cur.qty then
            v_return:='N';
        end if;
    END LOOP;
    for v_cur in (select sum(s.quantity) as qty,s.serialnumber,s.lotnumber,l.m_product_id from snr_internal_consumptionline s,m_internal_consumptionline l 
                  where s.m_internal_consumptionline_id =l.m_internal_consumptionline_id and l.m_internal_consumption_id=p_consumptionId group by l.m_product_id,s.serialnumber,s.lotnumber)
    LOOP
        select sum(s.quantity)  into v_retqty from snr_internal_consumptionline s,m_internal_consumptionline l 
                  where s.m_internal_consumptionline_id =l.m_internal_consumptionline_id and l.m_internal_consumption_id=p_returnId and m_product_id=v_cur.m_product_id
                        and coalesce(v_cur.serialnumber,'')=coalesce(s.serialnumber,'') and  coalesce(v_cur.lotnumber,'')=coalesce(s.lotnumber,'');
        select sum(1) into v_tmpqty from pdc_tempitems where m_internal_consumption_id=p_returnId and m_product_id=v_cur.m_product_id and coalesce(v_cur.serialnumber,'')=coalesce(serialnumber,'');
        if coalesce(v_retqty,0)+coalesce(v_tmpqty,0)!=v_cur.qty then
           v_return:='N';
        end if; 
    END LOOP;
    RETURN v_return;
END ; $_$ LANGUAGE plpgsql;



select zsse_dropfunction('pdc_relocationCorrect');
CREATE OR REPLACE FUNCTION  pdc_relocationCorrect(p_consumptionId varchar,p_returnId varchar,p_productID varchar,p_qty numeric,p_snr varchar,p_bnr varchar) RETURNS varchar AS
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
    v_return varchar:='Y';
    v_cur record;
    v_psum numeric;
    v_rsum numeric;
    v_tsum numeric;
BEGIN   
    if coalesce(p_consumptionId,'')='' or  coalesce(p_returnId,'')='' or coalesce(p_consumptionId,'')=coalesce(p_returnId,'') then
        if p_consumptionId is not null and p_returnId is not null  and (coalesce(p_snr,'')!='' or coalesce(p_bnr,'')!='') then
             select sum(s.quantity) into v_psum from snr_internal_consumptionline s,m_internal_consumptionline l where s.m_internal_consumptionline_id =l.m_internal_consumptionline_id 
                and l.m_internal_consumption_id=p_consumptionId and l.m_product_id=p_productID and coalesce(p_snr,'')=coalesce(s.serialnumber,'')  and  coalesce(p_bnr,coalesce(s.lotnumber,''))=coalesce(s.lotnumber,'');
             if coalesce(v_psum,0)=0 then
                -- snr/bnr nicht entnommen
                return 'N';
             end if;
        end if;
        RETURN v_return;
    end if;
    select sum(movementqty) into v_psum from m_internal_consumptionline where m_internal_consumption_id=p_consumptionId and m_product_id=p_productID;
    select sum(movementqty) into v_rsum from m_internal_consumptionline where m_internal_consumption_id=p_returnId and m_product_id=p_productID;
    if v_psum is null then v_psum:=0; end if;
    if coalesce(v_psum,0)<p_qty then
        v_return:='N';
    end if;
    if p_qty=1 and coalesce(v_psum,0)<coalesce(v_rsum,0)+1 and coalesce(p_bnr,'')='' and coalesce(p_snr,'')='' then
        v_return:='N';
    end if;
    if coalesce(p_snr,'')!='' or coalesce(p_bnr,'')!='' then
        select sum(s.quantity) into v_psum from snr_internal_consumptionline s,m_internal_consumptionline l where s.m_internal_consumptionline_id =l.m_internal_consumptionline_id 
                and l.m_internal_consumption_id=p_consumptionId and l.m_product_id=p_productID and coalesce(p_snr,'')=coalesce(s.serialnumber,'')  and  coalesce(p_bnr,coalesce(s.lotnumber,''))=coalesce(s.lotnumber,'');
        if v_psum is null then v_psum:=0; end if;
        select sum(s.quantity) into v_rsum from snr_internal_consumptionline s,m_internal_consumptionline l where s.m_internal_consumptionline_id =l.m_internal_consumptionline_id 
                and l.m_internal_consumption_id=p_returnId and l.m_product_id=p_productID and coalesce(p_snr,'')=coalesce(s.serialnumber,'')  and  coalesce(p_bnr,coalesce(s.lotnumber,''))=coalesce(s.lotnumber,'');
        select sum(1) into v_tsum from pdc_tempitems where m_internal_consumption_id=p_returnId and m_product_id=p_productID and coalesce(p_snr,'')=coalesce(serialnumber,'');
        if v_rsum is null then v_rsum:=0; end if;
        v_rsum:=v_rsum+coalesce(v_tsum,0);
        if v_psum<p_qty then
            --raise exception '%',v_psum||'#'||p_qty;
            v_return:='N';
        end if;   
        if p_qty=1 and v_rsum>0 and coalesce(v_psum,0)<coalesce(v_rsum,0)+1 then
            v_return:='N';
        end if; 
        
    end if;
    RETURN v_return;
END ; $_$ LANGUAGE plpgsql;


select zsse_dropfunction('pdc_InternalConsumptionSNRBNRRequired');
CREATE OR REPLACE FUNCTION  pdc_InternalConsumptionSNRBNRRequired(p_internalconsumption varchar,p_productId varchar,p_locatorId varchar) RETURNS varchar AS
$_$ 
DECLARE
 v_return varchar :='FALSE';
 v_lineId varchar;
BEGIN
    SELECT  M_INTERNAL_CONSUMPTIONLINE_ID into v_lineId from M_INTERNAL_CONSUMPTIONLINE where M_INTERNAL_CONSUMPTION_ID=p_internalconsumption and m_product_id = p_productId and  m_locator_id=p_locatorId; 
    if v_lineId is not null and (select p.isserialtracking||p.isbatchtracking from m_product p,m_internal_consumptionline l where p.m_product_id=l.m_product_id and l.m_internal_consumptionline_id=v_lineId)!='NN' then
        if (select movementqty from m_internal_consumptionline where m_internal_consumptionline_id=v_lineId) !=
           coalesce((select sum(snr.quantity) from snr_internal_consumptionline snr where snr.m_internal_consumptionline_id=v_lineId),0)
        then            
             v_return:='TRUE'; -- rot
        end if;
    end if;
    RETURN v_return;
END;
$_$ LANGUAGE plpgsql;


select zsse_dropfunction('pdc_InternalConsumptionlineSNRBNRUpdate');
CREATE OR REPLACE FUNCTION  pdc_InternalConsumptionlineSNRBNRUpdate(p_LineId varchar,p_user_id varchar,p_qty numeric,p_snr varchar,p_bnr varchar,p_lang varchar,p_weight numeric) RETURNS varchar AS
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
  v_prod varchar;
  v_btch varchar;
  v_btchno varchar;
  v_sn   varchar;
  v_otherbqty numeric;
  v_qty numeric;
  v_tmpqty numeric;
  v_client varchar;
  v_org varchar;
  v_user varchar;
  v_locator varchar;
  v_product varchar;
  v_conumption varchar;
  v_mvmTyp varchar;
  v_reloctype  varchar;
BEGIN   
    if p_LineId is null then return 'COMPILE'; end if;
    select l.updatedby,l.ad_client_id,l.ad_org_id,l.m_product_id,p.isserialtracking,p.isbatchtracking,l.m_internal_consumption_id into v_user,v_client,v_org,v_prod,v_btch,v_sn,v_conumption
           from m_internal_consumptionline l,m_product p where p.m_product_id=l.m_product_id and l.m_internal_consumptionline_id=p_LineId;
    select movementtype,relocationtrx into v_mvmTyp,v_reloctype from m_internal_consumption where m_internal_consumption_id=v_conumption;
    if p_qty=0 then
            delete from snr_internal_consumptionline where m_internal_consumptionline_id=p_LineId and case when coalesce(p_snr,'')!='' then serialnumber=p_snr else lotnumber=p_bnr end;
            select sum(quantity) into v_qty from snr_internal_consumptionline where m_internal_consumptionline_id=p_LineId;
            if v_qty is null then v_qty:=1; end if;
            update m_internal_consumptionline set movementqty=v_qty,weight=weight-p_weight where m_internal_consumptionline_id=p_LineId;
    else
        if v_mvmTyp='D-' then
            select m_locator_id ,m_product_id into v_locator,v_product from m_internal_consumptionline where m_internal_consumptionline_id=p_LineId;
            if p_qty=1 and coalesce(p_snr,'')='' and coalesce(p_bnr,'')!='' then 
                select sum(quantity) into v_otherbqty from snr_internal_consumptionline where m_internal_consumptionline_id=p_LineId and lotnumber=p_bnr;
            end if;
            if v_otherbqty is null then v_otherbqty:=0; end if;
            if pdc_isSnrBnrTrxPossible(v_locator,v_product,p_qty+v_otherbqty, p_snr,p_bnr,p_lang)!='TRUE' then
                raise exception '%',pdc_isSnrBnrTrxPossible(v_locator,v_product,p_qty+v_otherbqty, p_snr,p_bnr,p_lang);
            end if;
        end if;
        if coalesce(p_snr,'')!='' then
            select b.batchnumber into v_btchno from snr_batchmasterdata b,snr_masterdata s where s.m_product_id=v_prod and s.serialnumber=p_snr and s.snr_batchmasterdata_id=b.snr_batchmasterdata_id;
            if (select count(*) from snr_internal_consumptionline where m_internal_consumptionline_id=p_LineId and serialnumber=p_snr)>0 then
                raise exception '%','@doublescan@';
            else
                select sum(quantity) into v_qty from snr_internal_consumptionline where m_internal_consumptionline_id=p_LineId;
                select sum(1) into v_tmpqty from pdc_tempitems where m_internal_consumptionline_id=p_LineId;                
                v_qty:=coalesce(v_tmpqty,0)+coalesce(v_qty,0)+1;                            
                update m_internal_consumptionline set movementqty=v_qty,weight=coalesce(weight,0)+p_weight  where m_internal_consumptionline_id=p_LineId;
                -- on Relocations with stocked Serials-> Save in TMP Items
                select m_product_id into v_product from m_internal_consumptionline where m_internal_consumptionline_id=p_LineId;
                select m_locator_id  into v_locator from snr_masterdata where m_product_id=v_product and serialnumber=p_snr;
                if v_mvmTyp='D+' and v_reloctype='R' and v_locator is not null then
                    select m_locator_id ,m_product_id into v_locator,v_product from m_internal_consumptionline where m_internal_consumptionline_id=p_LineId;
                    if (select count(*) from pdc_tempitems where m_internal_consumptionline_id=p_LineId and serialnumber=p_snr)>0 then
                        raise exception '%','@doublescan@';
                    end if;
                    insert into pdc_tempitems ( pdc_tempitems_id, ad_client_id, ad_org_id, createdby, updatedby, m_internal_consumption_id,m_internal_consumptionline_id, m_product_id,serialnumber,m_locator_id)
                               values(get_uuid(),v_client,v_org,v_user,v_user,v_conumption,p_LineId,v_product,p_snr,v_locator);
                else
                    insert into snr_internal_consumptionline(snr_internal_consumptionline_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY,  UPDATEDBY, M_INTERNAL_CONSUMPTIONLINE_ID, 
                                                  quantity,lotnumber,serialnumber)
                    values (get_uuid(),v_client,v_org,v_user,v_user,p_LineId,1,v_btchno,p_snr);
                end if;
            end if;
        end if;
        if coalesce(p_snr,'')='' and coalesce(p_bnr,'')!='' then
            if p_qty=1 then --increment
                select sum(quantity)+1 into v_qty from snr_internal_consumptionline where m_internal_consumptionline_id=p_LineId;
                if v_qty is null then v_qty:=1; end if;
                update m_internal_consumptionline set movementqty=v_qty,weight=coalesce(weight,0)+p_weight  where m_internal_consumptionline_id=p_LineId;
            else
                select sum(quantity) into v_otherbqty from snr_internal_consumptionline where m_internal_consumptionline_id=p_LineId and lotnumber!=p_bnr;
                if v_otherbqty is null then v_otherbqty:=0; end if;
                update m_internal_consumptionline set movementqty=p_qty+v_otherbqty,weight=coalesce(weight,0)+p_weight  where m_internal_consumptionline_id=p_LineId;
            end if;    
            if (select count(*) from  snr_internal_consumptionline where M_INTERNAL_CONSUMPTIONLINE_ID=p_LineId and lotnumber=p_bnr)=0 then
                insert into snr_internal_consumptionline(snr_internal_consumptionline_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY,  UPDATEDBY, M_INTERNAL_CONSUMPTIONLINE_ID, 
                                                  quantity,lotnumber,serialnumber)
                values (get_uuid(),v_client,v_org,v_user,v_user,p_LineId,p_qty,p_bnr,null);
            else
                update snr_internal_consumptionline set quantity=case when p_qty=1 then quantity+1 else p_qty end where m_internal_consumptionline_id=p_LineId and lotnumber=p_bnr;
            end if;
        end if;
    end if;
    return 'OK';
END ; $_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_tempItems2Relocation');
CREATE OR REPLACE FUNCTION  pdc_tempItems2Relocation(p_internalconsumption varchar) RETURNS varchar AS
$_$ 
DECLARE
 v_cur record;
 v_btchno varchar;
BEGIN
    if p_internalconsumption is null then return 'COMPILE'; end if;
    for v_cur in (select * from pdc_tempitems where m_internal_consumption_id=p_internalconsumption)
    LOOP
        select b.batchnumber into v_btchno from snr_batchmasterdata b,snr_masterdata s where s.m_product_id=v_cur.m_product_id and s.serialnumber= v_cur.serialnumber and s.snr_batchmasterdata_id=b.snr_batchmasterdata_id;
        insert into snr_internal_consumptionline(snr_internal_consumptionline_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY,  UPDATEDBY, M_INTERNAL_CONSUMPTIONLINE_ID, 
                                                  quantity,lotnumber,serialnumber)
                    values (get_uuid(),v_cur.ad_client_id,v_cur.ad_org_id,v_cur.createdby,v_cur.createdby,v_cur.m_internal_consumptionline_id,1,v_btchno,v_cur.serialnumber);
    END LOOP;
    RETURN 'OK';
END;
$_$ LANGUAGE plpgsql;


select zsse_dropfunction('pdc_InventoryCreate');
CREATE OR REPLACE FUNCTION  pdc_InventoryCreate(p_locatorId varchar,p_UserId varchar,p_OrgId varchar) RETURNS varchar AS
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
    v_name varchar;
    v_trxuuid varchar;
    v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
    v_wh varchar;
    v_intrx numeric;
    v_stocked numeric;
    v_locator varchar;
BEGIN   
    if p_locatorId is null then return 'COMPILE'; end if;
    v_trxuuid:=get_uuid();
    select m_warehouse_id,value into v_wh,v_locator from m_locator where m_locator_id=p_locatorId;
    select to_char(now(),'YYYY-MM-DD')||'-'||count(*)+1||' PDC-> '||v_locator into v_name from m_inventory where movementdate=trunc(now());
    insert into m_inventory (m_inventory_id, ad_client_id, ad_org_id, createdby, updatedby, name,  m_warehouse_id, movementdate)
    values (v_trxuuid,v_client,p_OrgId,p_UserId,p_UserId,v_name,v_wh,trunc(now()));
    return v_trxuuid;
END ; $_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_InventoryUpdate');
CREATE OR REPLACE FUNCTION  pdc_InventoryUpdate(p_InventoryId varchar,p_user_id varchar) RETURNS varchar AS
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
  v_cur record;
  v_wht numeric;
BEGIN   
    if p_InventoryId is null then return 'COMPILE'; end if;
    update m_inventoryline set qtycount=0,weight=0 where m_inventory_id=p_InventoryId;
    delete from m_inventoryline where m_inventory_id=p_InventoryId and qtybook =0;
    for v_cur in (select * from m_inventoryline where m_inventory_id=p_InventoryId)
    LOOP
        select sum(weight) into v_wht from m_storage_detail where m_locator_id=v_cur.m_locator_id and m_product_id=v_cur.m_product_id and 
            coalesce(m_attributesetinstance_id,'')=coalesce(v_cur.m_attributesetinstance_id,'');
        update m_inventoryline set weightbook=v_wht,createdby=p_user_id,updatedby=p_user_id where m_inventoryline_id=v_cur.m_inventoryline_id;
        delete from snr_inventoryline where  m_inventoryline_id=v_cur.m_inventoryline_id;
    END LOOP;
    return 'OK';
END ; $_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_InventoryUpdateLine');
CREATE OR REPLACE FUNCTION  pdc_InventoryUpdateLine(p_InventoryId varchar,p_locator_id varchar,p_product_id varchar,p_attrsetInstId varchar,p_qtycount numeric) RETURNS varchar AS
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
  v_qty numeric;
  v_invklineId varchar;
  v_isbatch varchar;
  v_isser varchar;
  v_ad_org_id varchar;
  v_ad_client_id varchar;
  v_createdby  varchar;
  v_line numeric;
  v_uom     varchar;
  v_batchqty numeric;
BEGIN   
    if p_InventoryId is null then return 'COMPILE'; end if;
    if p_qtycount is null then p_qtycount:=1; end if;
    select m_inventoryline_id,ad_org_id,ad_client_id,createdby into v_invklineId ,v_ad_org_id,v_ad_client_id,v_createdby 
           from m_inventoryline where m_inventory_id=p_InventoryId and m_product_id=p_product_id
           and  coalesce(m_attributesetinstance_id,'0')=coalesce(p_attrsetInstId,'0');
    select isserialtracking,isbatchtracking,c_uom_id into v_isser,v_isbatch,v_uom from m_product where m_product_id=p_product_id;
    if v_invklineId is null then 
        v_invklineId:=get_uuid();
        select max(line)+10,max(ad_client_id),max(ad_org_id),max(createdby) into v_line,v_ad_client_id,v_ad_org_id,v_createdby 
               from M_InventoryLine where m_inventory_id=p_InventoryId;
        if v_line is null then
            v_line:=10;
            select ad_client_id,ad_org_id,createdby into v_ad_client_id,v_ad_org_id,v_createdby 
               from M_Inventory where m_inventory_id=p_InventoryId;
        end if;
        INSERT INTO M_InventoryLine( M_InventoryLine_ID, Line, AD_Client_ID, AD_Org_ID,CreatedBy, UpdatedBy, M_Inventory_ID, M_Locator_ID, M_ATTRIBUTESETINSTANCE_ID, M_Product_ID,
              QtyBook, QtyCount, C_UOM_ID)
        VALUES(v_invklineId,v_line,v_ad_client_id,v_ad_org_id,v_createdby,v_createdby,p_InventoryId,p_locator_id,p_attrsetInstId,p_product_id,0,0,v_uom);
    end if;
    -- Batch and Serials are teated in pdc_InventorylineSNRBNRUpdate
    if v_isser='N' and v_isbatch='N' then 
        if p_qtycount=1 then -- increment
            select qtycount+p_qtycount into v_qty from  m_inventoryline where m_inventoryline_id=v_invklineId;
        end if;
        if p_qtycount<>1 or v_qty is null then
            v_qty:=p_qtycount;
        end if;
        update m_inventoryline set updated=now(),qtycount=coalesce(v_qty,qtycount) where m_inventoryline_id=v_invklineId;
    end if;
    return 'OK';
END ; $_$ LANGUAGE plpgsql;


select zsse_dropfunction('pdc_InventorylineSNRBNRUpdate');
CREATE OR REPLACE FUNCTION  pdc_InventorylineSNRBNRUpdate(p_InventoryId varchar,p_product_id varchar,p_qtycount numeric,p_weight numeric,p_snr varchar,p_bnr varchar) RETURNS varchar AS
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
  v_qty numeric;
  v_invklineId varchar;
  v_isbatch varchar;
  v_isser varchar;
  v_wht numeric;
  v_ad_org_id varchar;
  v_ad_client_id varchar;
  v_createdby  varchar;
  v_line numeric;
  v_uom     varchar;
  v_batchqty numeric;
  v_prod varchar;
  v_snrmaster varchar;
BEGIN   
    if p_InventoryId is null then return 'COMPILE'; end if;
    if p_weight=0 then p_weight:=null; end if;
    if p_qtycount is null then p_qtycount:=1; end if;
    select m_inventoryline_id,ad_org_id,ad_client_id,createdby,m_product_id into v_invklineId ,v_ad_org_id,v_ad_client_id,v_createdby,v_prod 
           from m_inventoryline where m_inventory_id=p_InventoryId and m_product_id=p_product_id;
    select isserialtracking,isbatchtracking,c_uom_id into v_isser,v_isbatch,v_uom from m_product where m_product_id=p_product_id;
    if v_invklineId is null then 
        raise exception '%','No Line, But serial??';
    end if;
    if coalesce((select value from ad_preference where attribute='WEIGHTMANDATORY'),'N')='Y' and  coalesce(p_weight,0)=0  then
        raise exception '%','No Weight!';
    end if;
    -- Qty=0 : Delete Batch/SNR
    if p_qtycount=0 then
        delete from snr_inventoryline where m_inventoryline_id=v_invklineId and case when coalesce(p_snr,'')!='' then serialnumber=p_snr else lotnumber=p_bnr end;
        select sum(quantity) into v_qty from snr_inventoryline where m_inventoryline_id=v_invklineId;
        if v_qty is null then v_qty:=0; end if;
        update m_inventoryline set qtycount=v_qty,updated=now(),weight=weight-p_weight  where m_inventoryline_id=v_invklineId;
    end if;
    -- Double Serial
    if v_isser='Y' and p_qtycount>0 and (select count(*) from snr_inventoryline where m_inventoryline_id=v_invklineId and serialnumber=p_snr)!=0 then
        raise exception '%','@doublescan@';
    end if;
    -- on batch: If Qty=1 -> Increment same Batch
    -- on batch: If Qty>1 -> Set Qty on this Batch
    v_batchqty:=0;
    if v_isbatch='Y' and v_isser='N' and p_qtycount>0 then
        if p_qtycount>1 then
            delete from snr_inventoryline where m_inventoryline_id=v_invklineId and lotnumber=p_bnr;
            v_wht:=p_weight;
        end if;
        select sum(quantity) into v_qty from snr_inventoryline where  m_inventoryline_id= v_invklineId;
        if p_qtycount=1 then -- increment
            select sum(quantity) into v_batchqty from snr_inventoryline where m_inventoryline_id=v_invklineId and lotnumber=p_bnr;
            if v_batchqty is null then v_batchqty:=0; end if;
            select weight+p_weight into v_wht from m_inventoryline where m_inventoryline_id=v_invklineId;
            if v_wht is null then v_wht:=p_weight; end if;
        end if;
        delete from snr_inventoryline where m_inventoryline_id=v_invklineId and lotnumber=p_bnr;
        v_qty:=coalesce(v_qty,0)+p_qtycount;
    end if;
    if v_isser='Y' and p_qtycount>0 and (select count(*) from snr_inventoryline where m_inventoryline_id=v_invklineId and serialnumber=p_snr)=0 then
        select weight+p_weight into v_wht from m_inventoryline where m_inventoryline_id=v_invklineId;
        if v_wht is null then v_wht:=p_weight; end if;
        select sum(quantity) into v_qty from snr_inventoryline where  m_inventoryline_id= v_invklineId;
        v_qty:=coalesce(v_qty,0)+1;
        if p_bnr is null and v_isbatch='Y' then -- Batch from Masterdata..
            select b.batchnumber into p_bnr from snr_batchmasterdata b,snr_masterdata s where s.m_product_id=v_prod and s.serialnumber=p_snr and s.snr_batchmasterdata_id=b.snr_batchmasterdata_id;
        end if;
        select snr_masterdata_id into v_snrmaster from snr_masterdata  where m_product_id=v_prod and serialnumber=p_snr and weight is null;
        if v_snrmaster is not null then
            update snr_masterdata set weight=p_weight where snr_masterdata_id=v_snrmaster;
        end if;
    end if;
    if v_isbatch='Y' or v_isser='Y' and p_qtycount>0 then
        update m_inventoryline set updated=now(),qtycount=coalesce(v_qty,qtycount),weight=v_wht where m_inventoryline_id=v_invklineId;  
        if (p_snr is not null and (select count(*) from snr_inventoryline where m_inventoryline_id=v_invklineId and serialnumber=p_snr)=0)
           or (p_bnr is not null and p_snr is null and (select count(*) from snr_inventoryline where m_inventoryline_id=v_invklineId and lotnumber=p_bnr)=0)
        then
            insert into snr_inventoryline(snr_inventoryline_id,AD_Client_ID, AD_Org_ID,  CreatedBy,  UpdatedBy,m_inventoryline_id,quantity,lotnumber,serialnumber)
                values(get_uuid(),v_ad_client_id,v_ad_org_id,v_createdby,v_createdby,v_invklineId,p_qtycount+v_batchqty,p_bnr,p_snr);
        end if;
    end if;
    return 'OK';
END ; $_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_InventoryDelete');
CREATE OR REPLACE FUNCTION  pdc_InventoryDelete(p_InventoryId varchar) RETURNS varchar AS
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
  v_cur record;
  v_wht numeric;
BEGIN   
    if p_InventoryId is null then return 'COMPILE'; end if;
    delete from m_inventoryline where m_inventory_id=p_InventoryId;
    delete from m_inventory where m_inventory_id=p_InventoryId;
    return 'OK';
END ; $_$ LANGUAGE plpgsql;


select zsse_dropfunction('m_pdcinventorystyle');
CREATE OR REPLACE FUNCTION  m_pdcinventorystyle(p_inventoryline varchar,p_firstproduct varchar) RETURNS varchar AS
$_$ 
DECLARE
 v_return varchar :='';
 v_qtycount numeric;
 v_qtybook numeric;
 v_qtysnr numeric;
 v_snrbtch varchar;
 v_product varchar;
BEGIN
    
    select p.isserialtracking||p.isbatchtracking as snrbtch,l.qtybook,l.qtycount,sum(snr.quantity),p.m_product_id into v_snrbtch,v_qtybook,v_qtycount,v_qtysnr, v_product
                                from m_product p,m_inventoryline l
                                left join snr_inventoryline snr on l.m_inventoryline_id=snr.m_inventoryline_id 
            where p.m_product_id=l.m_product_id and l.m_inventoryline_id=p_inventoryline
            group by p.m_product_id,p.isserialtracking,p.isbatchtracking,l.qtybook,l.qtycount;
    --
    if v_qtybook=v_qtycount and (case when v_snrbtch='NN' then 1=1 else coalesce(v_qtysnr,0)=v_qtycount end) then
        v_return:=' color:black; background-color:#a4fcae;'; --grün (Mengen korrekt)
    end if;
    if v_qtybook>v_qtycount  then
        v_return:=' color:black; background-color:#ffa8a8;'; -- rot (Untermenge oder noch nicht gezählt)
    end if;
    if p_firstproduct=v_product and (case when v_snrbtch='NN' then 1=0 else coalesce(v_qtysnr,v_qtycount)<v_qtybook end) then
        v_return:=' color:black; background-color:#b3dee6;'; -- blau (Snr zu Zählen)
    end if;
    if v_qtybook=0 or v_qtybook<v_qtycount then
        v_return:=' color:black; background-color:#ffeca6;';  -- gelb (In Zählliste nicht vorh. oder Übermenge)
    end if;
    RETURN v_return;
END;
$_$ LANGUAGE plpgsql;


select zsse_dropfunction('m_pdcconsumptionstyle');
CREATE OR REPLACE FUNCTION  m_pdcconsumptionstyle(p_internalconsumptionline varchar) RETURNS varchar AS
$_$ 
DECLARE
 v_return varchar :='';
 v_inout varchar;
 v_org varchar;
 v_usecase varchar:='';
 v_cur record;
BEGIN
    if (select p.isserialtracking||p.isbatchtracking from m_product p,m_internal_consumptionline l where p.m_product_id=l.m_product_id and l.m_internal_consumptionline_id=p_internalconsumptionline)!='NN' then
        if (select movementqty from m_internal_consumptionline where m_internal_consumptionline_id=p_internalconsumptionline) != (
           coalesce((select sum(snr.quantity) from snr_internal_consumptionline snr where snr.m_internal_consumptionline_id=p_internalconsumptionline),0)
           + coalesce((select sum(1) from pdc_tempitems snr where snr.m_internal_consumptionline_id=p_internalconsumptionline),0)
           )
        then
            -- Menge QTY und SNR Qty passen nicht->Rot
             v_return:=' color:black; background-color:#ffa8a8;'; -- rot
        end if;
    end if;
    RETURN v_return;
END;
$_$ LANGUAGE plpgsql;

select zsse_dropfunction('m_pdcinoutstyle');
CREATE OR REPLACE FUNCTION  m_pdcinoutstyle(p_inoutline varchar,p_firstline varchar) RETURNS varchar AS
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
    for v_cur in (select a.m_inoutline_id,row_number() over() as linecnt,a.todos from
                    (Select f.m_inoutline_id,
                            case when (p.isserialtracking='Y' or  p.isbatchtracking='Y') and coalesce(sum(snr.quantity),0)!=f.movementqty then 'TODO' else
                            case when coalesce(f.qtycontrolcount,0)=f.movementqty then 'READY' else case when coalesce(f.qtycontrolcount,0)>f.movementqty then 'OVER' else 'TODO' end end end as todos           
                     from m_product p,  m_locator l ,m_inoutline f left join snr_minoutline snr on f.m_inoutline_id=snr.m_inoutline_id
                     where f.m_inout_id=v_inout
                     and p.m_product_id=f.m_product_id 
                     and f.m_locator_id=l.m_locator_id
                     and case when v_usecase = 'SERIAL' then p.isserialtracking='Y' or p.isbatchtracking='Y' else 1=1 end
                     group by f.m_inoutline_id,f.m_product_id,p.isserialtracking, p.isbatchtracking,f.movementqty,l.value,p.m_product_id,
                                f.weight,f.qtycontrolcount,f.whtcontrol,l.m_locator_id
                     order by case when f.qtycontrolcount=f.movementqty then f.line+1000 else case when coalesce(p_firstline,'')=f.m_inoutline_id then 1 else f.line end end) a
                order by linecnt)
    LOOP
        if v_cur.m_inoutline_id=p_inoutline then
            if v_cur.todos='TODO' and v_cur.linecnt=1 then
                v_return:=' color:black; background-color:#b3dee6;'; -- blau
            end if;
            if v_cur.todos='TODO' and v_cur.linecnt>1 then 
                v_return:=' color:black; background-color:#ffa8a8;'; -- rot
            end if;
            if v_cur.todos='READY'  then
                v_return:=' color:black; background-color:#a4fcae;'; --Grün 
            end if;
            if v_cur.todos='OVER'  then
                v_return:=' color:black; background-color:#ffeca6;'; --Gelb 
            end if;
            RETURN v_return;
        end if;
    END LOOP;
    RETURN v_return;
END;
$_$ LANGUAGE plpgsql;



select zsse_dropfunction('pdc_issimplyfied');
CREATE OR REPLACE FUNCTION  pdc_issimplyfied(p_workstep varchar,p_consumption varchar) RETURNS varchar AS
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
    v_issimple varchar:='N';
    v_issimplemanu varchar;
    v_cur1 record;
    v_cur2 record;
    v_possible numeric:=100000;
    v_oneqty numeric;
    v_mfgqty numeric;
    v_ass varchar;
    v_prd varchar;
BEGIN   
    select qty,assembly into v_mfgqty,v_ass from c_projecttask where c_projecttask_id=p_workstep;
    SELECT  v.simplyfiedmanufacturing into v_issimplemanu from zssm_workstep_v v where v.zssm_workstep_v_id = p_workstep; 
    if v_ass='Y' and v_issimplemanu is null then
        SELECT  p.simplyfiedmanufacturing into v_issimplemanu from m_product p,zssm_workstep_v v where v.m_product_id=p.m_product_id and v.zssm_workstep_v_id = p_workstep; 
    end if;
    if v_ass='N' and v_issimplemanu is null then
         SELECT  p.simplyfiedmanufacturing into v_issimplemanu from m_product p,pdc_workstepbom_v where v.m_product_id=p.m_product_id and zssm_workstep_v_id=p_workstep order by line limit 1;
    end if;
    if coalesce(v_issimplemanu,'N')='Y' then
        if v_ass='Y' then
            for v_cur1 in (select * from pdc_workstepbom_v where zssm_workstep_v_id=p_workstep)
            LOOP
                v_oneqty:=v_cur1.quantity / coalesce(v_mfgqty,1);
                select * into v_cur2 from m_internal_consumptionline where m_internal_consumption_id=p_consumption and m_product_id=v_cur1.m_product_id;
                if v_cur2 is null then 
                    return 'N';
                else
                    v_possible:=floor(least(v_possible,v_cur2.movementqty/v_oneqty));
                end if;
            END LOOP;
            if v_possible>0 and v_possible!=100000 then         
                for v_cur1 in (select * from pdc_workstepbom_v where zssm_workstep_v_id=p_workstep)
                LOOP
                    -- Update auf ganze Geräte bei vereinfachter Prod.
                    v_oneqty:=v_cur1.quantity / coalesce(v_mfgqty,1);
                    select * into v_cur2 from m_internal_consumptionline where m_internal_consumption_id=p_consumption and m_product_id=v_cur1.m_product_id;
                    --raise notice '%',v_oneqty||'#'||v_possible;
                    if (v_cur2.movementqty/(v_possible*v_oneqty))>1 then
                        update m_internal_consumptionline set movementqty=(v_possible*v_oneqty) where m_internal_consumptionline_id=v_cur2.m_internal_consumptionline_id;
                    end if;
                END LOOP;
                v_issimple:=to_char(v_possible);
            else
                v_issimple:='N';
            end if;
        else -- Durchreicher
            SELECT  m_product_id into v_prd from pdc_workstepbom_v where zssm_workstep_v_id=p_workstep order by line limit 1;
            select movementqty into v_possible from m_internal_consumptionline where m_internal_consumption_id=p_consumption and m_product_id=v_prd order by line limit 1;
            if coalesce(v_possible,0)>0 then
               v_issimple:=to_char(v_possible);
            else
                v_issimple:='N';
            end if;
        end if;
    end if;
    return v_issimple;
END ; $_$ LANGUAGE plpgsql;






-- Individualisierbare Zahlen Darstellung in BDE

select zsse_dropfunction('pdc_inoutqtys');
CREATE OR REPLACE FUNCTION  pdc_inoutqtys(p_qtysoll numeric,p_whtsoll numeric,p_qtyist numeric,p_whtist numeric, p_lang varchar) RETURNS varchar AS
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
  
BEGIN   
    return zssi_strNumber(p_qtysoll,p_lang)||'/'||zssi_strNumber(p_qtyist,p_lang);
END ; $_$ LANGUAGE plpgsql;

select zsse_dropfunction('pdc_numfield');
CREATE OR REPLACE FUNCTION  pdc_numfield(p_num numeric,p_wht numeric,p_lang varchar) RETURNS varchar AS
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
  
BEGIN   
    return zssi_strNumber(p_num,p_lang);
END ; $_$ LANGUAGE plpgsql;

-- Open Worksteps...
select zsse_dropview('pdc_openworkstep_v');
CREATE OR REPLACE VIEW pdc_openworkstep_v AS
SELECT pt.c_projecttask_id as pdc_openworkstep_v_id,p.ad_org_id,p.ad_client_id,p.updated,p.updatedby,p.created,p.createdby,'Y'::character as isactive, 
       case when coalesce(pt.value,p.value)=p.value then p.value||' - '||p.name||case when p.name!=coalesce(pt.name,p.name) then ' - '||pt.name else '' end else pt.value||' - '||pt.name||' ('||p.name||' - '||p.value||')' end as name,
       pt.c_projecttask_id,p.projectstatus
FROM c_projecttask pt,c_project p where p.c_project_id=pt.c_project_id and p.projectstatus ='OR' and p.projectcategory='PRO' and pt.iscomplete='N' and pt.istaskcancelled='N';
