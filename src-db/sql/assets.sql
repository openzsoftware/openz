CREATE OR REPLACE FUNCTION a_asset_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 

/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

  --TYPE RECORD IS REFCURSOR;
  v_Acct_ID VARCHAR(32); --OBTG:VARCHAR2--
  Cur_Defaults RECORD;

BEGIN

    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  if new.assettype in ('OA','RE') and new.A_Asset_Group_ID is not null then
      --  Default Accounts for all AcctSchema
      IF(TG_OP = 'INSERT') THEN
        FOR Cur_Defaults IN (SELECT *
                            FROM A_Asset_Group_Acct d1
                            WHERE d1.A_Asset_Group_ID=new.A_Asset_Group_ID
                            AND EXISTS
                                  (
                                  SELECT 1
                                  FROM AD_Org_AcctSchema
                                  WHERE (AD_IsOrgIncluded(AD_Org_ID, new.AD_ORG_ID, new.AD_Client_ID)<>-1 OR AD_IsOrgIncluded(new.AD_ORG_ID, AD_Org_ID, new.AD_Client_ID)<>-1)
                                  AND IsActive = 'Y'
                                  AND AD_Org_AcctSchema.C_AcctSchema_ID = d1.C_AcctSchema_ID
                                  )
                AND d1.AD_CLIENT_ID = new.AD_Client_ID
                            ) LOOP

          SELECT * INTO  v_Acct_ID FROM Ad_Sequence_Next('A_Asset_Acct', Cur_Defaults.AD_Client_ID) ;
          INSERT
          INTO A_ASSET_ACCT
            (
              A_ASSET_ACCT_ID,
              A_ASSET_ID, C_ACCTSCHEMA_ID, AD_CLIENT_ID,
              AD_ORG_ID, ISACTIVE, CREATED,
              CREATEDBY, UPDATED, UPDATEDBY,
              A_DEPRECIATION_ACCT, A_ACCUMDEPRECIATION_ACCT, A_DISPOSAL_LOSS,
              A_DISPOSAL_GAIN
            )
            VALUES
            (
              get_uuid(),
              new.A_Asset_ID, Cur_Defaults.C_AcctSchema_ID, new.AD_Client_ID,
              new.AD_Org_ID,  'Y', TO_DATE(NOW()),
              new.CreatedBy, TO_DATE(NOW()), new.UpdatedBy,
              Cur_Defaults.A_DEPRECIATION_ACCT, Cur_Defaults.A_ACCUMDEPRECIATION_ACCT, Cur_Defaults.A_DISPOSAL_LOSS,
              Cur_Defaults.A_DISPOSAL_LOSS
            )
            ;
          END LOOP;
      ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE A_ASSET_ACCT SET AD_ORG_ID = new.AD_ORG_ID
        WHERE A_ASSET_ID = new.A_ASSET_ID;
      END IF;
  elsif new.assettype in ('OA','RE') and new.A_Asset_Group_ID is null then
      RAISE EXCEPTION '%', ' An  asset of this type needs an asset category';
  end if; 
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

EXCEPTION
WHEN DATA_EXCEPTION THEN
  RAISE EXCEPTION '%', 'The asset group for this asset has no accounts' ; --OBTG:-20008--
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.a_asset_trg() OWNER TO tad;



--
-- Name: a_amortization_process(character varying); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION a_amortization_process(p_pinstance_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 07/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/
-- SZ: Added Voidind of Document
--
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_AD_User_ID VARCHAR(32):='0'; --OBTG:VARCHAR2--
  v_PROCESSED VARCHAR(60):='N'; --OBTG:VARCHAR2--
  v_POSTED VARCHAR(60):='Y'; --OBTG:VARCHAR2--
  v_is_included NUMERIC:=0;
  v_AD_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_date TIMESTAMP;
  v_name character varying;
  v_available_period NUMERIC:=0; 
  v_is_ready AD_Org.IsReady%TYPE;
  v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
  v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
  v_org_bule_id AD_Org.AD_Org_ID%TYPE;
  FINISH_PROCESS BOOLEAN DEFAULT FALSE;
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
 
  BEGIN
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID, i.AD_User_ID, p.ParameterName, p.P_String, p.P_Number, p.P_Date
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Record_ID:=Cur_Parameter.Record_ID;
      v_AD_User_ID:=Cur_Parameter.AD_User_ID;
    END LOOP; -- Get Parameter
    SELECT PROCESSED, POSTED, AD_Org_ID, DateAcct,name
    INTO v_PROCESSED, v_POSTED, v_AD_Org_ID, v_date,v_name
    FROM A_AMORTIZATION
    WHERE A_AMORTIZATION_ID=V_Record_ID;
    -- Do not process cancelled Docs
    IF(v_PROCESSED='VO' or (v_PROCESSED='Y' and instr(v_name,'Cancel')>0)) then
         RAISE EXCEPTION '%', 'Document processed/posted' ;
    END IF;
    IF(v_PROCESSED='Y' AND v_POSTED='N') THEN
      --UnProcess amortization
      v_ResultStr:='ProcessAmortization';
      UPDATE A_Amortization
        SET Processed='N', TotalAmortization=
        (SELECT sum(C_Currency_Convert(AmortizationAmt, C_Currency_ID, A_Amortization.C_Currency_ID, TO_DATE(NOW()), 'S'))
        FROM A_AmortizationLine
        WHERE A_Amortization_ID=A_Amortization.A_Amortization_ID
        )
      WHERE A_Amortization_ID=V_Record_ID;
    ELSIF(v_PROCESSED='N') THEN
      -- Check the header belongs to a organization where transactions are posible and ready to use
      SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
      INTO v_is_ready, v_is_tr_allow
      FROM A_Amortization, AD_Org, AD_OrgType
      WHERE AD_Org.AD_Org_ID=A_Amortization.AD_Org_ID
      AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
      AND A_Amortization.A_Amortization_ID=V_Record_ID;
      IF (v_is_ready='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
      END IF;
      IF (v_is_tr_allow='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
      END IF;    
      
      -- Check the document does not have elements of different business unit or legal entities.
      SELECT AD_ORG_CHK_DOCUMENTS('A_AMORTIZATION', 'A_AMORTIZATIONLINE', V_Record_ID, 'A_AMORTIZATION_ID', 'A_AMORTIZATION_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
         RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;
      -- Check if there are lines document does
      if (select count(*) from  A_AMORTIZATIONLINE where A_AMORTIZATION_id=V_Record_ID)=0 then
          RAISE EXCEPTION '%', '@NoLinesInDoc@';
      END IF;
      -- Check the period control is opened (only if it is legal entity with accounting)
      -- Gets the BU or LE of the document
      SELECT AD_GET_DOC_LE_BU('A_AMORTIZATION', V_Record_ID, 'A_AMORTIZATION_ID', 'LE')
      INTO v_org_bule_id
      FROM DUAL;
      
      SELECT AD_OrgType.IsAcctLegalEntity
      INTO v_isacctle
      FROM AD_OrgType, AD_Org
      WHERE AD_Org.AD_OrgType_ID = AD_OrgType.AD_OrgType_ID
      AND AD_Org.AD_Org_ID=v_org_bule_id;
      
      IF (v_isacctle='Y') THEN
        SELECT C_CHK_OPEN_PERIOD(v_AD_Org_ID, v_date, 'AMZ', NULL) 
        INTO v_available_period
        FROM DUAL;
        
        IF (v_available_period<>1) THEN
          RAISE EXCEPTION '%', '@PeriodNotAvailable@'; --OBTG:-20000--
        END IF;
      END IF;
      
       
      --Process amortization    
      v_ResultStr:='ProcessAmortization';
      UPDATE A_Amortization
        SET Processed='Y', TotalAmortization=
        (SELECT sum(C_Currency_Convert(AmortizationAmt, C_Currency_ID, A_Amortization.C_Currency_ID, TO_DATE(NOW()), 'S'))
        FROM A_AmortizationLine
        WHERE A_Amortization_ID=A_Amortization.A_Amortization_ID
        )
      WHERE A_Amortization_ID=V_Record_ID;
    ELSIF(v_Posted='Y') THEN
      -- Void the Document
      PERFORM core_voidAssetAmortization(V_Record_ID,v_AD_User_ID);
      --RAISE EXCEPTION '%', '@AmortizationDocumentPosted@' ; --OBTG:-20000--
    END IF;
    IF(FINISH_PROCESS=false) THEN
      --Calculating Depreciated value
      v_ResultStr:='CalculatingDepreciatedValue';
      UPDATE a_asset
        SET DepreciatedValue=
        (SELECT sum(AMORTIZATIONAMT)
        FROM a_amortizationline al, a_amortization am
        WHERE a_asset.a_asset_id=al.a_asset_id
          AND al.A_Amortization_ID=am.A_Amortization_ID
          AND coalesce(am.processed, 'N')='Y'
        )
      WHERE exists
        (SELECT 1
        FROM a_amortizationline al, a_amortization am
        WHERE a_asset.a_asset_id=al.a_asset_id
          AND al.A_Amortization_ID=am.A_Amortization_ID
          AND am.A_Amortization_ID=V_Record_ID);
      UPDATE a_asset
        SET IsFullyDepreciated='Y'
      WHERE COALESCE(AmortizationValueAmt, -1)=COALESCE(DepreciatedValue, -2) ;
    END IF;
    ---- <<FINISH_PROCESS>>
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
    ELSE
      RAISE NOTICE '%','Finished ' || v_Message ;
    END IF;
    -- Commented by cromero 19102006 -- COMMIT;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  -- ROLLBACK;
  IF(p_PInstance_ID IS NOT NULL) THEN
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  END IF;
--  RAISE EXCEPTION '%', v_ResultStr ; --OBTG:-20100--
--  RETURN;
END ; $_$;


ALTER FUNCTION public.a_amortization_process(p_pinstance_id character varying) OWNER TO tad;

--
-- Name: a_amortization_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION a_amortization_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 07/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/
    /*************************************************************************
    * Added Voiding Document
    ************************************************************************/
    v_DateNull TIMESTAMP := TO_DATE('31-12-9999','DD-MM-YYYY');
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- If invoice is processed, is not allowed to change C_BPartner
    IF TG_OP = 'UPDATE'
    THEN  if((OLD.Processed='Y'
    OR OLD.Posted='Y' OR OLD.Processed='VO')
    AND (  COALESCE(old.NAME, '')!=COALESCE(new.NAME, '')
    OR COALESCE(old.DESCRIPTION, '')!=COALESCE(new.DESCRIPTION, '')
    OR COALESCE(old.DATEACCT, v_DateNull)!=COALESCE(new.DATEACCT, v_DateNull)
    OR COALESCE(old.STARTDATE, v_DateNull)!=COALESCE(new.STARTDATE, v_DateNull)
    OR COALESCE(old.ENDDATE, v_DateNull)!=COALESCE(new.ENDDATE, v_DateNull)
    OR COALESCE(old.C_PROJECT_ID, '0')!=COALESCE(new.C_PROJECT_ID, '0')
    OR COALESCE(old.C_CAMPAIGN_ID, '0')!=COALESCE(new.C_CAMPAIGN_ID, '0')
    OR COALESCE(old.C_ACTIVITY_ID, '0')!=COALESCE(new.C_ACTIVITY_ID, '0')
    OR COALESCE(old.USER1_ID, '0')!=COALESCE(new.USER1_ID, '0')
    OR COALESCE(old.USER2_ID, '0')!=COALESCE(new.USER2_ID, '0')
    OR COALESCE(old.C_CURRENCY_ID, '0')!=COALESCE(new.C_CURRENCY_ID, '0')
    OR COALESCE(old.TOTALAMORTIZATION, 0)!=COALESCE(new.TOTALAMORTIZATION, 0)
    OR COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0')
    OR COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0') ))
    THEN  RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
 end if;
 END IF;
 IF(TG_OP = 'INSERT') THEN
  IF(NEW.PROCESSED='Y') THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
 END IF;
 IF(TG_OP = 'DELETE') THEN
  IF(old.PROCESSED='Y' OR OLD.Processed='VO') THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
 END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


ALTER FUNCTION public.a_amortization_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION core_voidAssetAmortization(p_amortization_id character varying, p_userid character varying) returns void
LANGUAGE plpgsql AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Core-Processes
 
***************************************************************************************************/
v_cur             RECORD;

v_status character varying;
v_count numeric;
v_docno character varying;
v_uid  character varying;
BEGIN
    -- Get new Doc No
    select name,get_uuid() into v_docno,v_uid from a_Amortization where a_Amortization_id=p_amortization_id;
    update a_Amortization set processed='N',posted='N'  where a_Amortization_id=p_amortization_id;
    update a_Amortization set name=v_docno||' - Cancelled',processed='VO',POSTED='Y' where a_Amortization_id=p_amortization_id;
    INSERT INTO A_AMORTIZATION
                  (
                  A_AMORTIZATION_ID, DATEACCT, AD_CLIENT_ID, AD_ORG_ID,
                  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                  STARTDATE,ENDDATE,
                  NAME, C_CURRENCY_ID
                  )
                   (SELECT v_uid, trunc(now()), AD_CLIENT_ID, AD_ORG_ID,now(),p_userid,now(),p_userid,STARTDATE,ENDDATE, v_docno||' - Cancelling Doc.'  ,C_CURRENCY_ID
                    from A_AMORTIZATION where A_AMORTIZATION_ID=p_amortization_id);
   INSERT INTO A_AMORTIZATIONLINE
                  (
                    A_AMORTIZATION_ID, A_AMORTIZATIONLINE_ID, A_ASSET_ID, AD_CLIENT_ID,
                    AD_ORG_ID, CREATEDBY, UPDATEDBY, AMORTIZATION_PERCENTAGE, AMORTIZATIONAMT, C_CURRENCY_ID,
                    LINE
                  )
                  (SELECT v_uid,get_uuid(),A_ASSET_ID, AD_CLIENT_ID,
                    AD_ORG_ID, p_userid,p_userid,AMORTIZATION_PERCENTAGE, AMORTIZATIONAMT*-1, C_CURRENCY_ID,
                    LINE from A_AMORTIZATIONLINE where A_AMORTIZATION_ID=p_amortization_id);
   update a_Amortization set Processed='Y', TotalAmortization=
        (SELECT sum(C_Currency_Convert(AmortizationAmt, C_Currency_ID, A_Amortization.C_Currency_ID, TO_DATE(NOW()), 'S'))
        FROM A_AmortizationLine
        WHERE A_Amortization_ID=A_Amortization.A_Amortization_ID
        )
      WHERE A_Amortization_ID=v_uid;
END;
$BODY$;








CREATE OR REPLACE FUNCTION a_asset_post(p_pinstance_id character varying, p_asset_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/*************************************************************************
* The contents of this file are subject to the Openbravo  Public  License
* Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this
* file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html
* Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
* License for the specific  language  governing  rights  and  limitations
* under the License.
* The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL
* All portions are Copyright (C) 2001-2008 Openbravo SL
* All Rights Reserved.
* Contributor(s):  ______________________________________.
************************************************************************/

--  Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; --  Success
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    --  Record Info
    v_count NUMERIC;
    v_UpdatedBy A_ASSET.UpdatedBy%TYPE;
    v_Processing A_ASSET.Processing%TYPE;
    v_Processed A_ASSET.Processed%TYPE;
    v_DateAcct TIMESTAMP;
    v_DocumentNo A_ASSET.DocumentNo%TYPE;
    BPartner_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_ACCTVALUEAMT NUMERIC;
    v_AD_CLIENT_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AD_ORG_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AD_USER_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AMORTIZATIONENDDATE TIMESTAMP;
    v_AMORTIZATIONSTARTDATE TIMESTAMP;
    v_AMORTIZATIONTYPE VARCHAR(60) ; --OBTG:VARCHAR2--
    v_AMORTIZATIONVALUEAMT NUMERIC;
    v_AMORTIZATIONPERCENTAGE NUMERIC;
    v_ASSETDEPRECIATIONDATE TIMESTAMP;
    v_ASSETVALUEAMT NUMERIC;
    v_C_CURRENCY_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_CREATEDBY VARCHAR(32); --OBTG:varchar2--
    v_ISDEPRECIATED CHAR(1) ;
    v_RESIDUALASSETVALUEAMT NUMERIC;
    v_USELIFEMONTHS NUMERIC;
    V_MONTHS NUMERIC;
    v_USELIFEYEARS NUMERIC;
    v_ASSETSCHEDULE VARCHAR(60) ; --OBTG:VARCHAR2--
    v_TOTAL_DAYS NUMERIC;
    v_THIS_YEAR_DAYS NUMERIC;
    v_BEGINING_DATE TIMESTAMP;
    v_ENDING_DATE TIMESTAMP;
    v_AUXAMT NUMERIC;
    v_AMORTIZATIONAMT NUMERIC;
    v_NEW_AMORTIZATION VARCHAR(32); --OBTG:VARCHAR2--
    v_LINE NUMERIC;
    v_AMORTIZATIONLINE VARCHAR(32); --OBTG:varchar2--
    v_FIRST_DAY_DATE TIMESTAMP;
    v_LAST_DAY_DATE TIMESTAMP;
    v_PERCENTAGE NUMERIC;
    v_AMOUNT NUMERIC;
    v_CURRENCY_ID VARCHAR(32); --OBTG:VARCHAR2--
    FINISH_PROCESS BOOLEAN:=false;
    v_DepreciatedLines NUMERIC;
    v_DepreciatedPlan NUMERIC;
    v_depreciatedValue NUMERIC;
    v_Period NUMERIC;
    v_DEPRECIATEDPREVIOUSAMT NUMERIC;
    v_AMORTIZATIONCALCTYPE VARCHAR(60) ; --OBTG:VARCHAR2--
    v_PercentageGeneral NUMERIC;
    v_TotalAmt NUMERIC;
    v_Currency_Pre NUMERIC:= 0;
    v_Inserted NUMERIC:= 0;
    finish boolean;
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      v_ResultStr:='PInstanceNotFound';
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
      --  Get Parameters
      v_ResultStr:='ReadingParameters';
      FOR Cur_Parameter IN
        (SELECT i.Record_ID, i.AD_User_ID, p.ParameterName, p.P_String, p.P_Number, p.P_Date
        FROM AD_PInstance i
        LEFT JOIN AD_PInstance_Para p
          ON i.AD_PInstance_ID=p.AD_PInstance_ID
        WHERE i.AD_PInstance_ID=p_PInstance_ID
        ORDER BY p.SeqNo
        )
      LOOP
        v_Record_ID:=Cur_Parameter.Record_ID;
      END LOOP; --  Get Parameter
      RAISE NOTICE '%','  v_Record_ID=' || v_Record_ID ;
    ELSE
      RAISE NOTICE '%','--<<A_Aset_Post>>' ;
      v_Record_ID:=p_Asset_ID;
    END IF;
  BEGIN --BODY
    /**
    *  Read Asset
    */
    v_ResultStr:='ReadingAsset';
    -- we Delete the not Posted Lines
      delete from A_AmortizationLine al
        WHERE A_Asset_ID=V_Record_ID  AND exists (select 0 from A_Amortization a where a.A_Amortization_ID=al.A_Amortization_Id and a.posted='N');
      delete from A_Amortization a where not exists (select 0 from A_Amortizationline al  where a.A_Amortization_ID=al.A_Amortization_Id);
      -- if Posted Lines are more than the New No Of Cycles - Such a change is not allowed
      if (select count(*) from  A_AmortizationLine al, A_Amortization am WHERE A_Asset_ID=V_Record_ID  AND am.A_Amortization_ID=al.A_Amortization_ID) >= 
          (case when v_AMORTIZATIONCALCTYPE='PE' then 100/v_AMORTIZATIONPERCENTAGE else coalesce(v_USELIFEMONTHS,v_USELIFEYEARS) end) then
          raise EXCEPTION '%', '@PeriodsDontMatch@' ;
      end if;
    --Updating DepreciatedPlan
    UPDATE a_asset
      SET DepreciatedPlan=
      (SELECT coalesce(sum(AmortizationAmt), 0)
      FROM A_AmortizationLine
      WHERE A_asset_ID=v_Record_ID
      )
    WHERE a_Asset_ID=v_Record_ID;
    SELECT ACCTVALUEAMT, AD_CLIENT_ID, AD_ORG_ID, AD_USER_ID, AMORTIZATIONENDDATE, AMORTIZATIONSTARTDATE, AMORTIZATIONTYPE, AMORTIZATIONVALUEAMT, ANNUALAMORTIZATIONPERCENTAGE, ASSETDEPRECIATIONDATE, ASSETVALUEAMT, C_CURRENCY_ID, CREATEDBY, ISDEPRECIATED, PROCESSING, RESIDUALASSETVALUEAMT, USELIFEMONTHS, USELIFEYEARS, ASSETSCHEDULE, PROCESSED, C_CURRENCY_ID, depreciatedPlan, COALESCE(depreciatedValue,0), COALESCE(DEPRECIATEDPREVIOUSAMT,0), AMORTIZATIONCALCTYPE
    INTO v_ACCTVALUEAMT, v_AD_CLIENT_ID, v_AD_ORG_ID, v_AD_USER_ID, v_AMORTIZATIONENDDATE, v_AMORTIZATIONSTARTDATE, v_AMORTIZATIONTYPE, v_AMORTIZATIONVALUEAMT, v_AMORTIZATIONPERCENTAGE, v_ASSETDEPRECIATIONDATE, v_ASSETVALUEAMT, v_C_CURRENCY_ID, v_CREATEDBY, v_ISDEPRECIATED, v_PROCESSING, v_RESIDUALASSETVALUEAMT, v_USELIFEMONTHS, v_USELIFEYEARS, v_ASSETSCHEDULE, v_PROCESSED, v_CURRENCY_ID, v_DepreciatedPlan, v_depreciatedValue, v_DEPRECIATEDPREVIOUSAMT, v_AMORTIZATIONCALCTYPE
    FROM A_ASSET
    WHERE A_ASSET_ID=v_Record_ID;
    RAISE NOTICE '%','A_Asset_ID=' || v_Record_ID || ' - AMORTIZATIONTYPE=' || v_AMORTIZATIONTYPE ;
    -- Restrictions...
    IF COALESCE(v_AMORTIZATIONVALUEAMT, 0)<=0 THEN
     RAISE EXCEPTION '%', '@AmountNotDefined@' ; --OBTG:-20000--
    END IF;
    IF v_AMORTIZATIONCALCTYPE='PE' AND v_AMORTIZATIONPERCENTAGE IS NULL THEN
      RAISE EXCEPTION '%', '@PercentageNotDefined@' ; --OBTG:-20000--
    END IF;
    IF v_AMORTIZATIONCALCTYPE!='PE' AND((v_ASSETSCHEDULE!='YE' AND v_USELIFEMONTHS IS NULL) OR(v_ASSETSCHEDULE='YE' AND v_USELIFEYEARS IS NULL)) THEN
      RAISE EXCEPTION '%', '@PeriodNotDefined@' ; --OBTG:-20000--
    END IF;
    IF v_AMORTIZATIONSTARTDATE IS NULL THEN
      RAISE EXCEPTION '%', '@StartDateNotDefined@' ; --OBTG:-20000--
    END IF;
    IF(v_Processing='Y') THEN
      RAISE EXCEPTION '%', '@OtherProcessActive@' ; --OBTG:-20000--
    END IF;
    IF (v_C_CURRENCY_ID IS NULL) THEN
      RAISE EXCEPTION '%', '@"C_CURRENCY_ID" IS NOT NULL@' ; --OBTG:-20000--
    END IF;
    /**************************************************************************
    *  Start Processing ------------------------------------------------------
    *************************************************************************/
    IF(NOT FINISH_PROCESS) THEN
      v_ResultStr:='LockingAsset';   
      UPDATE A_ASSET  SET Processing='Y'  WHERE A_ASSET_ID=v_Record_ID;   
      --we calculate the already completed number of cycles
      SELECT count(*)
      INTO v_DepreciatedLines
      FROM A_AmortizationLine al, A_Amortization am
      WHERE A_Asset_ID=V_Record_ID  AND am.A_Amortization_ID=al.A_Amortization_ID;
      --we get the standard precision for the selected currency
      SELECT STDPRECISION
      INTO v_Currency_Pre
      FROM C_CURRENCY
      WHERE C_CURRENCY_ID = v_C_CURRENCY_ID;
      
      IF(v_AMORTIZATIONTYPE='LI') THEN
        IF(v_ASSETSCHEDULE='YE' OR v_AMORTIZATIONCALCTYPE='PE') THEN
          if v_USELIFEYEARS=v_DepreciatedLines then
            FINISH_PROCESS:=true;
          end if;
          IF(NOT FINISH_PROCESS) THEN
            if v_DepreciatedLines>0 then
              SELECT to_number(to_char(max(startdate), 'YYYY')) - to_number(to_char(min(endDate), 'YYYY'))
              INTO v_Period
              FROM a_amortization am, a_amortizationline al
              WHERE al.a_amortization_id=am.a_amortization_id  AND al.a_asset_id=V_Record_ID;
              if(v_DepreciatedLines<>v_Period) and(v_DepreciatedLines<>(v_Period+1)) then
                RAISE EXCEPTION '%', '@PeriodsDontMatch@' ; --OBTG:-20000--
              end if;
            end if;
          END IF; --FINISH_PROCESS
          IF(NOT FINISH_PROCESS) THEN
            if v_AMORTIZATIONCALCTYPE='PE' then
              v_PercentageGeneral:=v_AMORTIZATIONPERCENTAGE;
              v_UseLifeYears:=trunc(100/v_PercentageGeneral) ;
            else
              --  v_PercentageGeneral := 100 / v_USELIFEYEARS;
              v_PercentageGeneral:=((v_AMORTIZATIONVALUEAMT-v_DEPRECIATEDPREVIOUSAMT-v_depreciatedPlan) *100/v_AMORTIZATIONVALUEAMT) /(v_USELIFEYEARS-v_DepreciatedLines) ;
              SELECT to_number(TO_DATE(ADD_MONTHS(v_AMORTIZATIONSTARTDATE, 12*v_USELIFEYEARS)) - v_AMORTIZATIONSTARTDATE)
              INTO v_TOTAL_DAYS
              FROM DUAL;
            end if;
            v_AMORTIZATIONVALUEAMT:=v_AMORTIZATIONVALUEAMT-v_DEPRECIATEDPREVIOUSAMT;
            v_Count:=coalesce(v_depreciatedLines, 0) +1;
            v_BEGINING_DATE:=v_AMORTIZATIONSTARTDATE;
            v_FIRST_DAY_DATE:=TO_DATE('01-01-' || TO_CHAR(v_AMORTIZATIONSTARTDATE, 'YYYY'), 'DD-MM-YYYY') ;
            v_LAST_DAY_DATE:=TO_DATE('31-12-' || TO_CHAR(v_AMORTIZATIONSTARTDATE, 'YYYY'), 'DD-MM-YYYY') ;
            if v_Count>1 then
              v_BEGINING_DATE:=TO_DATE('31-12-' || to_char(TO_number(to_char(v_BEGINING_DATE, 'yyyy')) +v_Count-1), 'DD-MM-YYYY') ;
              v_USELIFEYEARS:=v_USELIFEYEARS+1;
            end if;
            v_AUXAMT:=0;
            v_PERCENTAGE:=0;
            v_TotalAmt:=coalesce(v_DepreciatedPlan, 0) ;
            finish:=false;
            WHILE not finish
            LOOP
              IF(v_COUNT=1 AND to_number(v_BEGINING_DATE-v_FIRST_DAY_DATE)<>0) THEN
                v_Percentage:=to_number(to_number(TO_DATE('31-12-'||to_char(v_AMORTIZATIONSTARTDATE, 'YYYY'), 'DD-MM-YYYY') -v_AMORTIZATIONSTARTDATE) /(TO_DATE('31-12-'||to_char(v_AMORTIZATIONSTARTDATE, 'YYYY'), 'DD-MM-YYYY') -TO_DATE('01-01-'||to_char(v_AMORTIZATIONSTARTDATE, 'YYYY'), 'DD-MM-YYYY'))) * v_PercentageGeneral;
                v_USELIFEYEARS:=v_USELIFEYEARS+1;
              ELSE
                v_Percentage:=v_PercentageGeneral;
              END IF;
              v_COUNT:=v_COUNT + 1;
              v_ENDING_DATE:=TO_DATE('31-12-' ||TO_CHAR(v_BEGINING_DATE, 'YYYY'), 'DD-MM-YYYY') ;
              SELECT COALESCE(MAX(A_AMORTIZATION_ID), '-1')
              INTO v_NEW_AMORTIZATION
              FROM A_AMORTIZATION
              WHERE STARTDATE<=v_ENDING_DATE  AND ENDDATE>=v_ENDING_DATE  AND AD_CLIENT_ID=v_AD_CLIENT_ID  AND PROCESSED='N' AND AD_Org_ID=v_AD_ORG_ID;
              IF(v_NEW_AMORTIZATION='-1') THEN
                SELECT * INTO  v_NEW_AMORTIZATION FROM Ad_Sequence_Next('A_Amortization', '1000000') ;
                INSERT
                INTO A_AMORTIZATION
                  (
                    A_AMORTIZATION_ID, DATEACCT, AD_CLIENT_ID, AD_ORG_ID,
                  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                  ENDDATE,
                  ISACTIVE, NAME, POSTED,
                  PROCESSED, PROCESSING, STARTDATE, C_CURRENCY_ID
                  )
                  VALUES
                  (v_NEW_AMORTIZATION, v_ENDING_DATE, v_AD_CLIENT_ID, v_AD_ORG_ID,
                  TO_DATE(NOW()), v_CREATEDBY, TO_DATE(NOW()), v_CREATEDBY,
                  LAST_DAY(TO_DATE('01-' || TO_CHAR(v_ENDING_DATE, 'MM') || '-'|| TO_CHAR(v_ENDING_DATE, 'YYYY'),'DD-MM-YYYY')),
                  'Y', TO_CHAR(v_ENDING_DATE, 'YYYY')||'-'|| TO_CHAR(v_ENDING_DATE, 'MM'), 'N',
                  'N', 'N',
                  TO_DATE('01-' || TO_CHAR(v_ENDING_DATE, 'MM') || '-' || TO_CHAR(v_ENDING_DATE, 'YYYY'),'DD-MM-YYYY'), v_CURRENCY_ID);
              END IF;
              SELECT COALESCE(MAX(LINE), 0) +10
              INTO v_LINE
              FROM A_AMORTIZATIONLINE
              WHERE A_AMORTIZATION_ID=v_NEW_AMORTIZATION;
              IF((((v_AMORTIZATIONVALUEAMT+v_DEPRECIATEDPREVIOUSAMT) *v_PERCENTAGE/100)>(v_AMORTIZATIONVALUEAMT -v_TotalAmt))OR(v_Inserted+1>=v_USELIFEYEARS)) THEN
                SELECT COALESCE(SUM(AMORTIZATIONAMT),0), COALESCE(SUM(AMORTIZATION_PERCENTAGE),0)
                INTO v_AMOUNT, v_PERCENTAGE
                FROM A_AMORTIZATIONLINE
                WHERE A_ASSET_ID=v_Record_ID;
                v_AMOUNT:=v_AMORTIZATIONVALUEAMT - v_AMOUNT;
                v_PERCENTAGE:=v_AMOUNT*100/(v_AMORTIZATIONVALUEAMT+v_DEPRECIATEDPREVIOUSAMT) ;
                finish:=true;
              ELSE
                v_AMOUNT:=(v_AMORTIZATIONVALUEAMT+ v_DEPRECIATEDPREVIOUSAMT) *v_PERCENTAGE/100;
              END IF;
              if v_percentage>0 then
                SELECT * INTO  v_AMORTIZATIONLINE FROM Ad_Sequence_Next('A_Amortizationline', '1000000') ;
                INSERT
                INTO A_AMORTIZATIONLINE
                  (
                    A_AMORTIZATION_ID, A_AMORTIZATIONLINE_ID, A_ASSET_ID, AD_CLIENT_ID,
                    AD_ORG_ID, CREATED, CREATEDBY, UPDATED,
                    UPDATEDBY, AMORTIZATION_PERCENTAGE, AMORTIZATIONAMT, C_CURRENCY_ID,
                    ISACTIVE, LINE
                  )
                  VALUES
                  (v_NEW_AMORTIZATION, v_AMORTIZATIONLINE, v_Record_ID, v_AD_CLIENT_ID, v_AD_ORG_ID, TO_DATE(NOW()), v_CREATEDBY, TO_DATE(NOW()), v_CREATEDBY, ROUND(v_PERCENTAGE,v_Currency_Pre), ROUND(v_AMOUNT,v_Currency_Pre), v_C_CURRENCY_ID, 'Y', v_LINE) ;
                 v_Inserted := v_Inserted +1;
              end if;
              v_BEGINING_DATE:=TO_DATE('31-12-' || TO_CHAR(v_BEGINING_DATE, 'yyyy'), 'DD-MM-YYYY') + 1;
              v_TotalAmt:=v_TotalAmt + v_Amount;
            END LOOP;
            FINISH_process:=TRUE;
          END IF; --FINISH_PROCESS
        END IF;
        IF(NOT FINISH_PROCESS) THEN
          IF(v_ASSETSCHEDULE='MO') THEN
            if v_USELIFEMonths=v_DepreciatedLines then
              FINISH_PROCESS:=true;
            end if;
          END IF; --FINISH_PROCESS
          IF(NOT FINISH_PROCESS) THEN
            if v_DepreciatedLines>0 then
              SELECT trunc(months_Between(max(startdate), min(endDate))) +1
              INTO v_Period
              FROM a_amortization am, a_amortizationline al
              WHERE al.a_amortization_id=am.a_amortization_id  AND al.a_asset_id=V_Record_ID;
              if(v_DepreciatedLines<>v_Period) and(v_DepreciatedLines<>(v_Period+1)) then
                RAISE EXCEPTION '%', '@PeriodsDontMatch@' ; --OBTG:-20000--
              end if;
            end if;
          END IF; --FINISH_PROCESS
          IF(NOT FINISH_PROCESS) THEN
            v_AMORTIZATIONVALUEAMT:=v_AMORTIZATIONVALUEAMT-v_DEPRECIATEDPREVIOUSAMT;
            if v_AMORTIZATIONCALCTYPE='PE' then
              v_PercentageGeneral:=v_AMORTIZATIONPERCENTAGE/12;
              v_UseLifeMonths:=trunc(100/v_AMORTIZATIONPERCENTAGE*12) ;
            else
              --  v_PercentageGeneral := 100 / v_USELIFEYEARS;
              v_UseLifeYears:=v_UseLifeMonths/12;
              if (v_assetschedule = 'MO') then 
                v_PercentageGeneral:=(((v_AMORTIZATIONVALUEAMT-v_depreciatedPlan) *100/v_AMORTIZATIONVALUEAMT) /(v_USELIFEYEARS*12-v_DepreciatedLines));
              else 
                v_PercentageGeneral:=(((v_AMORTIZATIONVALUEAMT-v_depreciatedPlan) *100/v_AMORTIZATIONVALUEAMT) /(v_USELIFEYEARS-v_DepreciatedLines)) /12;
              end if;
              SELECT to_number(TO_DATE(ADD_MONTHS(v_AMORTIZATIONSTARTDATE, 12*v_USELIFEYEARS)) - TO_DATE(v_AMORTIZATIONSTARTDATE))
              INTO v_TOTAL_DAYS
              FROM DUAL;
            end if;
            v_Count:=coalesce(v_depreciatedLines, 0) +1;
            v_BEGINING_DATE:=v_AMORTIZATIONSTARTDATE;
            v_FIRST_DAY_DATE:=TO_DATE('01-'|| TO_CHAR(v_AMORTIZATIONSTARTDATE, 'MM') || '-' || TO_CHAR(v_AMORTIZATIONSTARTDATE, 'YYYY'), 'DD-MM-YYYY') ;
            v_LAST_DAY_DATE:=TO_DATE('31-12-'|| TO_CHAR(v_AMORTIZATIONSTARTDATE, 'YYYY'), 'DD-MM-YYYY') ;
            if v_Count>1 then
              v_BEGINING_DATE:=TO_DATE(ADD_MONTHS(LAST_DAY(TO_DATE('01-' || TO_CHAR(v_BEGINING_DATE, 'MM') || '-' || TO_CHAR(v_BEGINING_DATE, 'yyyy'), 'DD-MM-YYYY')), v_DepreciatedLines)) ;
              v_USELIFEMonths:=v_USELIFEMonths+1;
            end if;
            v_AUXAMT:=0;
            v_PERCENTAGE:=0;
            v_TotalAmt:=coalesce(v_DepreciatedPlan, 0) ;
            finish:=false;
            while not finish
            loop
              IF(v_COUNT=1 AND to_number(v_BEGINING_DATE-v_FIRST_DAY_DATE)<>0) THEN
                v_Percentage:=to_number(to_number(last_day(v_BEGINING_DATE) -v_BEGINING_DATE)) / (trunc((last_day(v_BEGINING_DATE) -(TO_DATE('01-'||to_char(TO_DATE(v_BEGINING_DATE), 'MM-YYYY'), 'DD-MM-YYYY')))) +1) * v_PercentageGeneral;
                v_USELIFEMONTHS:=v_USELIFEMONTHS+1;
              ELSE
                v_Percentage:=v_PercentageGeneral;
              END IF;
              v_COUNT:=v_COUNT + 1;
              SELECT COALESCE(MAX(A_AMORTIZATION_ID), '-1')
              INTO v_NEW_AMORTIZATION
              FROM A_AMORTIZATION
              WHERE STARTDATE<=v_BEGINING_DATE  AND ENDDATE>=v_BEGINING_DATE  AND AD_CLIENT_ID=v_AD_CLIENT_ID  AND PROCESSED='N' AND AD_Org_ID=v_AD_ORG_ID;
              v_ENDING_DATE:= LAST_DAY(TO_DATE('01-' || TO_CHAR(v_BEGINING_DATE, 'MM') || '-' || TO_CHAR(v_BEGINING_DATE, 'yyyy'), 'DD-MM-YYYY')) ;
              IF(v_NEW_AMORTIZATION='-1') THEN
                SELECT * INTO  v_NEW_AMORTIZATION FROM Ad_Sequence_Next('A_Amortization', '1000000') ;
                INSERT
                INTO A_AMORTIZATION
                  (
                    A_AMORTIZATION_ID, DATEACCT, AD_CLIENT_ID, AD_ORG_ID,
                    CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                    ENDDATE, ISACTIVE, NAME, POSTED,
                    PROCESSED, PROCESSING, STARTDATE, C_Currency_ID
                  )
                  VALUES
                  (v_NEW_AMORTIZATION, v_ENDING_DATE, v_AD_CLIENT_ID, v_AD_ORG_ID, TO_DATE(NOW()), v_CREATEDBY, TO_DATE(NOW()), v_CREATEDBY, 
                   LAST_DAY(TO_DATE('01-' || TO_CHAR(v_BEGINING_DATE, 'MM') || '-' || TO_CHAR(v_BEGINING_DATE, 'yyyy'), 'DD-MM-YYYY')), 'Y', 
                   TO_CHAR(v_ENDING_DATE, 'YYYY')||'-'|| TO_CHAR(v_ENDING_DATE, 'MM'), 
                   'N', 'N', 'N', 
                   TO_DATE('01-' || TO_CHAR(v_BEGINING_DATE, 'MM') || '-' || TO_CHAR(v_BEGINING_DATE, 'yyyy'), 'DD-MM-YYYY'), v_CURRENCY_ID) ;
              END IF;
              SELECT COALESCE(MAX(LINE), 0) +10
              INTO v_LINE
              FROM A_AMORTIZATIONLINE
              WHERE A_AMORTIZATION_ID=v_NEW_AMORTIZATION;
              SELECT COALESCE(COUNT(A_AMORTIZATIONLINE_ID),0), COALESCE(MAX(A_ASSET.USELIFEMONTHS),1)
              INTO v_Inserted, V_MONTHS
              FROM A_AMORTIZATIONLINE, A_ASSET
              WHERE A_AMORTIZATIONLINE.A_ASSET_ID = A_ASSET.A_ASSET_ID
              AND A_ASSET.A_ASSET_ID=v_Record_ID;              
              IF(((v_AMORTIZATIONVALUEAMT*v_PERCENTAGE/100)>(v_AMORTIZATIONVALUEAMT-v_TotalAmt))OR(v_Inserted+1>=v_USELIFEMONTHS) OR(v_Inserted>0 AND mod(v_Inserted+1,V_MONTHS)=0 AND TO_NUMBER(TO_CHAR(v_AMORTIZATIONSTARTDATE,'DD'))=1)) THEN
                SELECT COALESCE(SUM(AMORTIZATIONAMT),0), COALESCE(SUM(AMORTIZATION_PERCENTAGE),0)
                INTO v_AMOUNT, v_PERCENTAGE
                FROM A_AMORTIZATIONLINE
                WHERE A_ASSET_ID=v_Record_ID;
                v_AMOUNT := v_AMORTIZATIONVALUEAMT - v_AMOUNT;
                v_PERCENTAGE:=100 - v_PERCENTAGE;
                finish:=true;
              ELSE v_AMOUNT:=v_AMORTIZATIONVALUEAMT*v_PERCENTAGE/100;
              end if;
              IF(v_AMOUNT>0) THEN
                SELECT * INTO  v_AMORTIZATIONLINE FROM Ad_Sequence_Next('A_Amortizationline', '1000000');
                INSERT
                INTO A_AMORTIZATIONLINE
                  (
                    A_AMORTIZATION_ID, A_AMORTIZATIONLINE_ID, A_ASSET_ID, AD_CLIENT_ID,
                    AD_ORG_ID, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                    AMORTIZATION_PERCENTAGE, AMORTIZATIONAMT, C_CURRENCY_ID, ISACTIVE, LINE
                  )
                  VALUES
                  (v_NEW_AMORTIZATION, v_AMORTIZATIONLINE, v_Record_ID, v_AD_CLIENT_ID, 
                   v_AD_ORG_ID, TO_DATE(NOW()), v_CREATEDBY, TO_DATE(NOW()), v_CREATEDBY, 
                   ROUND(v_PERCENTAGE,v_Currency_Pre), ROUND(v_AMOUNT,v_Currency_Pre), v_C_CURRENCY_ID, 'Y', v_LINE) ;
                 v_Inserted := v_Inserted +1;
                v_BEGINING_DATE:=TO_DATE(ADD_MONTHS(LAST_DAY(TO_DATE('01-' || TO_CHAR(v_BEGINING_DATE, 'MM') || '-' || TO_CHAR(v_BEGINING_DATE, 'yyyy'), 'DD-MM-YYYY')), 1) );
                v_TotalAmt:=v_TotalAmt + v_Amount;
              END IF;
            END LOOP;
          END IF; --FINISH_PROCESS
        END IF;
      END IF;
    END IF; --FINISH_PROCESS
    IF(FINISH_PROCESS) THEN
      UPDATE A_ASSET SET PROCESSED='Y', PROCESSING='N'  WHERE A_ASSET_ID=v_Record_ID;
      --Updating DepreciatedPlan
      UPDATE a_asset
        SET DepreciatedPlan=
        (SELECT sum(AmortizationAmt)
        FROM A_AmortizationLine
        WHERE A_asset_ID=v_Record_ID
        )
      WHERE a_Asset_ID=v_Record_ID;
    END IF; --FINISH_PROCESS
    ---- <<FINISH_PROCESS>>
    v_ResultStr:='UnLockingAsset';
    UPDATE A_ASSET
      SET Processing='N', Updated=TO_DATE(NOW()), UpdatedBy=v_CREATEDBY
    WHERE A_Asset_ID=v_Record_ID;
    -- Commented by cromero 19102006 IF(p_PInstance_ID IS NOT NULL) THEN
    -- Commented by cromero 19102006   -- COMMIT;
    -- Commented by cromero 19102006 END IF;

    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, v_CREATEDBY, 'N', v_Result, v_Message) ;
    ELSE
      RAISE NOTICE '%','--<<A_Asset_Post finished>> ' || v_Message ;
    END IF;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  IF(p_PInstance_ID IS NOT NULL) THEN
    -- ROLLBACK;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  ELSE
    RAISE EXCEPTION '%', SQLERRM;
  END IF;
  -- RAISE EXCEPTION '%', v_ResultStr ; --OBTG:-20100--
-- Commented by cromero 19102006 RETURN;
END ; $_$;


CREATE OR REPLACE FUNCTION a_get_AmortizationenddateOrAlternative(p_asset_id character varying) returns timestamp without time zone
LANGUAGE plpgsql AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
***************************************************************************************************/
v_returnValue timestamp without time zone := null;
v_amortizationstartdate timestamp without time zone;
v_amortizationenddate timestamp without time zone;
v_amortizationcalctype character varying;
v_assetschedule character varying;
v_month numeric;
v_year numeric;
v_intervalString character varying := null;
BEGIN

    
    select amortizationstartdate, amortizationenddate, assetschedule, uselifemonths, uselifeyears, amortizationcalctype
	into v_amortizationstartdate, v_amortizationenddate, v_assetschedule, v_month, v_year, v_amortizationcalctype
	from a_asset 
	where a_asset_id = p_asset_id;


    IF(v_amortizationenddate is not null) THEN
	RETURN v_amortizationenddate; 
    END IF;

    IF(v_amortizationcalctype = 'TI') THEN
	v_returnValue := a_calc_IntervalString(v_amortizationstartdate, v_assetschedule, v_year, v_month);

    ELSIF(v_amortizationcalctype = 'PE') THEN
	select amt.dateacct into v_returnValue from a_asset aa, a_amortizationline aal, a_amortization amt where aa.a_asset_id = aal.a_asset_id AND aal.a_amortization_id = amt.a_amortization_id AND aa.a_asset_id = p_asset_id order by amt.dateacct desc;

    END IF;

    RETURN v_returnValue;
END;
$BODY$;


CREATE OR REPLACE FUNCTION a_calc_IntervalString(p_amortizationstartdate timestamp without time zone, p_assetschedule character varying, p_year numeric, p_month numeric) returns timestamp without time zone
LANGUAGE plpgsql AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
***************************************************************************************************/
v_returnValue timestamp without time zone := null;
v_amortizationenddate timestamp without time zone;
v_intervalString character varying := null;
BEGIN

    
    IF(p_year is not null AND p_assetschedule = 'YE') THEN
	v_intervalString := (p_year - 1) || ' years';

    ELSIF(p_month is not null AND p_assetschedule = 'MO') THEN
	v_intervalString := (p_month - 1) || ' months';

    END IF;


    IF(p_year is not null AND v_intervalString is null) THEN
	v_intervalString := (p_year - 1) || ' years';

    ELSIF(p_month is not null AND v_intervalString is null) THEN
	v_intervalString := (p_month - 1) || ' months';

    END IF;


    IF(v_intervalString is not null) THEN
	v_returnValue := p_amortizationstartdate + v_intervalString::interval;
    END IF;

    RETURN v_returnValue;
END;
$BODY$;
