CREATE OR REPLACE FUNCTION c_yearperiods(pinstance_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/*************************************************************************
  * The contents of this file are subject to the Compiere Public
  * License 1.1 ("License"); You may not use this file except in
  * compliance with the License. You may obtain a copy of the License in
  * the legal folder of your Openbravo installation.
  * Software distributed under the License is distributed on an
  * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  * implied. See the License for the specific language governing rights
  * and limitations under the License.
  * The Original Code is  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
  * parts created by ComPiere are Copyright (C) ComPiere, Inc.;
  * All Rights Reserved.
  * Contributor(s): Openbravo SL
  * Contributions are Copyright (C) 2001-2009 Openbravo, S.L.
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: C_YearPeriods.sql,v 1.2 2002/05/22 02:48:28 jjanke Exp $
  ***
  * Title: Create missing standard periods for Year_ID
  * Description:
  ************************************************************************/
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    v_Year_ID VARCHAR(32); --OBTG:VARCHAR2--
    --
    v_NextNo VARCHAR(32); --OBTG:VARCHAR2--
    v_MonthNo NUMERIC;
    v_StartDate TIMESTAMP;
    Test NUMERIC;
    v_ResultStr VARCHAR(300) ;
    --  C_Year Variables
    v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Calendar_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Year_Str VARCHAR(20) ;
    v_User_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_year_num NUMERIC;
  BEGIN
    --  Update AD_PInstance
    --  DBMS_OUTPUT.PUT_LINE('Updating PInstance - Processing');
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID,
        p.ParameterName,
        p.P_String,
        p.P_Number,
        p.P_Date
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Year_ID:=Cur_Parameter.Record_ID;
    END LOOP; -- Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Year_ID ;
    --  Get C_Year Record
    RAISE NOTICE '%','Get Year info' ;
    v_ResultStr:='YearNotFound';
    SELECT AD_Client_ID,
      AD_Org_ID,
      C_Calendar_ID,
      Year,
      UpdatedBy
    INTO v_Client_ID,
      v_Org_ID,
      v_Calendar_ID,
      v_Year_Str,
      v_User_ID
    FROM C_Year
    WHERE C_Year_ID=v_Year_ID;
    -- Check the format
    RAISE NOTICE '%','Checking format' ;
    v_ResultStr:='Year not numeric: '||v_Year_Str;
    BEGIN
    SELECT TO_NUMBER(v_Year_Str) INTO v_year_num FROM DUAL;
     -- Postgres hack
     IF (v_year_num IS NULL OR v_year_num<=0) THEN
      RAISE EXCEPTION '%', '@NotValidNumber@'; --OBTG:-20000--
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION '%', '@NotValidNumber@'; --OBTG:-20000--
    END;
    --  Start Date
    RAISE NOTICE '%','Calculating start date' ;
    v_ResultStr:='Year not numeric: '||v_Year_Str;
    SELECT TO_DATE('1/1/'||v_Year_Str, 'MM/DD/YYYY') INTO v_StartDate FROM DUAL;
    RAISE NOTICE '%','Start: '||v_StartDate ;
    -- Loop to all months and add missing periods
    FOR v_MonthNo IN 1..12
    LOOP
      --  Do we have the month already:1
      --      DBMS_OUTPUT.PUT_LINE('Checking Month No: '||v_MonthNo);
      v_ResultStr:='Checking Month '||v_MonthNo;
      SELECT MAX(PeriodNo)
      INTO Test
      FROM C_Period
      WHERE C_Year_ID=v_Year_ID
        AND PeriodNo=v_MonthNo;
      IF Test IS NULL THEN
        -- get new v_NextNo
        SELECT * INTO  v_NextNo FROM AD_Sequence_Next('C_Period', v_Year_ID) ;
        --          DBMS_OUTPUT.PUT_LINE('Adding Period ID: '||v_NextNo);
        INSERT
        INTO C_Period
          (
            C_Period_ID, AD_Client_ID, AD_Org_ID, IsActive,
            Created, CreatedBy, Updated, UpdatedBy,
            C_Year_ID, PeriodNo, StartDate, PeriodType,enddate,
            Name
          )
          VALUES
          (
            v_NextNo, v_Client_ID, v_Org_ID, 'Y',
            TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID,
            v_Year_ID, v_MonthNo, TO_DATE(ADD_MONTHS(v_StartDate, v_MonthNo-1)), 'S',TO_DATE(ADD_MONTHS(v_StartDate, v_MonthNo))-1,
                (SELECT SUBSTR(name, 1,3) || '-' || SUBSTR(year,3,2) FROM AD_MONTH, C_YEAR WHERE TO_NUMBER(value)=v_MonthNo AND c_year_id=v_Year_ID)
           );
        RAISE NOTICE '%','Month Added' ;
      END IF;
    END LOOP;
    --  Update AD_PInstance
    ---- <<END_PROCEDURE>>
    --  DBMS_OUTPUT.PUT_LINE('Updating PInstance - Finished');
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 1, NULL) ;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  --      DBMS_OUTPUT.PUT_LINE('No Data Found Exception');
  v_ResultStr:= '@ERROR=' || SQLERRM;
  PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ; $_$;


CREATE OR REPLACE FUNCTION c_period_process(p_pinstance_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/*************************************************************************
  * The contents of this file are subject to the Compiere Public
  * License 1.1 ("License"); You may not use this file except in
  * compliance with the License. You may obtain a copy of the License in
  * the legal folder of your Openbravo installation.
  * Software distributed under the License is distributed on an
  * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  * implied. See the License for the specific language governing rights
  * and limitations under the License.
  * The Original Code is  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
  * parts created by ComPiere are Copyright (C) ComPiere, Inc.;
  * All Rights Reserved.
  * Contributor(s): Openbravo SL
  * Contributions are Copyright (C) 2001-2009 Openbravo, S.L.
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: C_Period_Process.sql,v 1.2 2002/05/22 02:48:28 jjanke Exp $
  ***
  * Title: Opens/Closes all PeriodControl for a C_Period
  * Description:
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Record_ID_Log VARCHAR(32); --OBTG:VARCHAR2--
  v_Count NUMERIC:=0;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Document RECORD;
  
  -- Parameter Variables
  p_Organization C_PeriodControl_Log.AD_Org_ID%TYPE;
  p_IsRecursive C_PeriodControl_Log.IsRecursive%TYPE;
  p_Calendar C_PeriodControl_Log.C_Calendar_ID%TYPE;
  p_Year C_PeriodControl_Log.C_Year_ID%TYPE;
  p_YearName C_Year.Year%TYPE;
  p_PeriodID varchar;
  p_DocBaseType C_PeriodControl_Log.DocBaseType%TYPE;
  p_PeriodAction C_PeriodControl_Log.PeriodAction%TYPE;
  p_Processing C_PeriodControl_Log.Processing%TYPE;
  v_AD_Client_ID C_PeriodControl_Log.AD_Client_ID%TYPE;
  v_status varchar;
  v_startdate date;
  v_year  varchar;
BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
 
BEGIN
    -- Get Parameters
    SELECT Record_ID
    INTO v_Record_ID_Log
    FROM AD_PInstance
    WHERE AD_PInstance_ID=p_PInstance_ID;
    
    SELECT L.AD_Client_ID, L.AD_Org_ID, L.C_Calendar_ID, L.ISRecursive, L.C_Year_ID, C_Year.Year, L.periodno as c_period_id, L.DocBaseType, L.PeriodAction, L.Processing
    INTO v_AD_Client_ID, p_Organization, p_Calendar, p_IsRecursive, p_Year, p_YearName, p_PeriodID, p_DocBaseType, p_PeriodAction, p_Processing
    FROM C_PeriodControl_Log L, C_Year
    WHERE L.C_PeriodControl_Log_ID=v_Record_ID_Log AND C_Year.C_Year_Id = L.C_Year_Id;
    
    select startdate,c_year_id into v_startdate,v_year from c_period where C_PERIOD_ID =p_PeriodID;
    
    IF (p_Processing='N') THEN 
      
      UPDATE C_PeriodControl_Log
      SET Processing='Y'
      WHERE C_PeriodControl_Log_ID=v_Record_ID_Log;   
      -- Action: Open if not permanently closed
      IF(p_PeriodAction='O') THEN
              
        IF (p_IsRecursive='N') THEN
          FOR Cur_Document IN
            (SELECT C_PERIODCONTROL_ID
              FROM C_PERIODCONTROL, C_PERIOD 
              WHERE C_PERIODCONTROL.C_PERIOD_ID=C_PERIOD.C_PERIOD_ID 
              AND C_PERIOD.C_PERIOD_ID=p_PeriodID
              AND C_PERIODCONTROL.AD_Org_ID=p_Organization
              AND C_PERIODCONTROL.DocBaseType LIKE COALESCE(p_DocBaseType, '%')
            )
          LOOP
            v_Record_ID:=Cur_Document.C_PERIODCONTROL_ID;
            select PeriodStatus into v_status from C_PeriodControl WHERE C_PeriodControl_ID=v_Record_ID;
            if coalesce(v_status,'x')='P' then
                raise exception '%', '@cannotmodifyclosedperiod@';
            end if;
            UPDATE C_PeriodControl
              SET PeriodStatus='O'
            WHERE C_PeriodControl_ID=v_Record_ID
              AND PeriodStatus<>'P';
          END LOOP;
          
        ELSIF (p_IsRecursive='Y') THEN
          FOR Cur_Document IN
            (SELECT C_PERIODCONTROL_ID
              FROM C_PERIODCONTROL, C_PERIOD 
              WHERE C_PERIODCONTROL.C_PERIOD_ID=C_PERIOD.C_PERIOD_ID 
             AND C_PERIOD.C_PERIOD_ID in (select c_period_id from c_period where c_year_id=v_year and periodtype='S' and startdate<=v_startdate)
              AND C_PERIODCONTROL.AD_Org_ID IN (SELECT AD_Org_ID
                                                FROM AD_Org 
                                                WHERE AD_ISORGINCLUDED(ad_org.ad_org_id, p_Organization, ad_org.ad_client_id)<>-1)
              AND C_PERIODCONTROL.DocBaseType LIKE COALESCE(p_DocBaseType, '%')
            )
          LOOP
            v_Record_ID:=Cur_Document.C_PERIODCONTROL_ID;    
            select PeriodStatus into v_status from C_PeriodControl WHERE C_PeriodControl_ID=v_Record_ID;
            if coalesce(v_status,'x')='P' then
                raise exception '%', '@cannotmodifyclosedperiod@';
            end if;
            UPDATE C_PeriodControl
              SET PeriodStatus='O'
            WHERE C_PeriodControl_ID=v_Record_ID
              AND PeriodStatus<>'P';
          END LOOP;
        END IF;
        
        -- Action: Close if not permanently closed
      ELSIF(p_PeriodAction='C') THEN
       
        IF (p_IsRecursive='Y') THEN
         FOR Cur_Document IN
            (SELECT C_PERIODCONTROL_ID
              FROM C_PERIODCONTROL, C_PERIOD 
              WHERE C_PERIODCONTROL.C_PERIOD_ID=C_PERIOD.C_PERIOD_ID 
              AND C_PERIOD.C_PERIOD_ID in (select c_period_id from c_period where c_year_id=v_year and periodtype='S' and startdate<=v_startdate)
              AND C_PERIODCONTROL.AD_Org_ID IN (SELECT AD_Org_ID
                                                FROM AD_Org 
                                                WHERE AD_ISORGINCLUDED(ad_org.ad_org_id, p_Organization, ad_org.ad_client_id)<>-1)
              AND C_PERIODCONTROL.DocBaseType LIKE COALESCE(p_DocBaseType, '%')
            )
          LOOP
            v_Record_ID:=Cur_Document.C_PERIODCONTROL_ID;   
            select PeriodStatus into v_status from C_PeriodControl WHERE C_PeriodControl_ID=v_Record_ID;
            if coalesce(v_status,'x')='P' then
                raise exception '%', '@cannotmodifyclosedperiod@';
            end if;
            UPDATE C_PeriodControl
              SET PeriodStatus='C'
            WHERE C_PeriodControl_ID=v_Record_ID
              AND PeriodStatus<>'P';
          END LOOP;
       ELSIF (p_IsRecursive='N') THEN
        FOR Cur_Document IN
            (SELECT C_PERIODCONTROL_ID
              FROM C_PERIODCONTROL, C_PERIOD 
              WHERE C_PERIODCONTROL.C_PERIOD_ID=C_PERIOD.C_PERIOD_ID 
              AND C_PERIOD.C_PERIOD_ID=p_PeriodID
              AND C_PERIODCONTROL.AD_Org_ID=p_Organization
              AND C_PERIODCONTROL.DocBaseType LIKE COALESCE(p_DocBaseType, '%')
            )
          LOOP
            v_Record_ID:=Cur_Document.C_PERIODCONTROL_ID;      
            select PeriodStatus into v_status from C_PeriodControl WHERE C_PeriodControl_ID=v_Record_ID;
            if coalesce(v_status,'x')='P' then
                raise exception '%', '@cannotmodifyclosedperiod@';
            end if;
            UPDATE C_PeriodControl
              SET PeriodStatus='C'
            WHERE C_PeriodControl_ID=v_Record_ID
              AND PeriodStatus<>'P';
          END LOOP;
       
       END IF;
        -- Action: Permanently Close
      ELSIF(p_PeriodAction='P') THEN
       IF (p_IsRecursive='Y') THEN
        FOR Cur_Document IN
            (SELECT C_PERIODCONTROL_ID
              FROM C_PERIODCONTROL, C_PERIOD 
              WHERE C_PERIODCONTROL.C_PERIOD_ID=C_PERIOD.C_PERIOD_ID 
             AND C_PERIOD.C_PERIOD_ID in (select c_period_id from c_period where c_year_id=v_year and periodtype='S' and startdate<=v_startdate)
              AND C_PERIODCONTROL.AD_Org_ID IN (SELECT AD_Org_ID
                                                FROM AD_Org 
                                                WHERE AD_ISORGINCLUDED(ad_org.ad_org_id, p_Organization, ad_org.ad_client_id)<>-1)
              AND C_PERIODCONTROL.DocBaseType LIKE COALESCE(p_DocBaseType, '%')
            )
          LOOP
            v_Record_ID:=Cur_Document.C_PERIODCONTROL_ID;
            select PeriodStatus into v_status from C_PeriodControl WHERE C_PeriodControl_ID=v_Record_ID;
            if coalesce(v_status,'x')='P' then
                raise exception '%', '@cannotmodifyclosedperiod@';
            end if;
            UPDATE C_PeriodControl  SET PeriodStatus='P'  WHERE C_PeriodControl_ID=v_Record_ID;
          END LOOP;
       ELSIF (p_IsRecursive='N') THEN
        FOR Cur_Document IN
            (SELECT C_PERIODCONTROL_ID
              FROM C_PERIODCONTROL, C_PERIOD 
              WHERE C_PERIODCONTROL.C_PERIOD_ID=C_PERIOD.C_PERIOD_ID 
              AND C_PERIOD.C_PERIOD_ID=p_PeriodID
              AND C_PERIODCONTROL.AD_Org_ID=p_Organization
              AND C_PERIODCONTROL.DocBaseType LIKE COALESCE(p_DocBaseType, '%')
            )
          LOOP
            v_Record_ID:=Cur_Document.C_PERIODCONTROL_ID;
            select PeriodStatus into v_status from C_PeriodControl WHERE C_PeriodControl_ID=v_Record_ID;
            if coalesce(v_status,'x')='P' then
                raise exception '%', '@cannotmodifyclosedperiod@';
            end if;
            UPDATE C_PeriodControl  SET PeriodStatus='P'  WHERE C_PeriodControl_ID=v_Record_ID;
          END LOOP;
       END IF;
      END IF;
      
      
      ---- <<FINISH_PROCESS>>
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
      -- Update C_PeriodControl_Log
      UPDATE C_PeriodControl_Log
      SET Processing='N', Processed='Y'
      WHERE C_PeriodControl_Log_ID=v_Record_ID_Log;     
      
    ELSE
      RAISE EXCEPTION '%', '@OtherProcessActive@'; --OBTG:-20000--
    END IF;
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
END ; $_$;


--
-- Name: fact_acct_reset(character varying); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION fact_acct_reset(p_pinstance_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/*************************************************************************
  * The contents of this file are subject to the Compiere Public
  * License 1.1 ("License"); You may not use this file except in
  * compliance with the License. You may obtain a copy of the License in
  * the legal folder of your Openbravo installation.
  * Software distributed under the License is distributed on an
  * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  * implied. See the License for the specific language governing rights
  * and limitations under the License.
  * The Original Code is  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
  * parts created by ComPiere are Copyright (C) ComPiere, Inc.;
   * All Rights Reserved.
  * Contributor(s): Openbravo SL, Stefan Zimmermann (2011)
  * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
  * Contributions are Copyright (C) 2011 Stefan Zimmermann
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: Fact_Acct_Reset.sql,v 1.4 2003/01/27 06:22:11 jjanke Exp $
  ***
  * Title: Reset Posting Records
  * Description:
  *   Delete Records in Fact_Acct or
  *   Reset Posted
  *   for AD_Client_ID and AD_Table_ID
  *SZ: BUGFIX : Always RESET Accounting Entrys - Otherwise there is CAOS in the GL !
  *    Be aware of Periods and take Time - Parameters
  *    Nearly REWRITTEN Function
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure 1=OK
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_AD_User_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_AD_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_TableName VARCHAR(48):=''; --OBTG:VARCHAR2--
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    v_AD_Client_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_AD_Table_ID VARCHAR(32) ; --OBTG:VARCHAR2--
     
    v_Updated NUMERIC(10):=0;
    v_Deleted NUMERIC(10):=0;
    v_Cmd VARCHAR(2000):=''; --OBTG:VARCHAR2--
    v_rowcount NUMERIC;


    v_openperiod NUMERIC;
    v_datefrom DATE;
    v_dateto DATE;
    Cur_Fact_Acct RECORD;
    v_cur record;
    v_factgroup character varying;
 BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Get Parameters
    v_ResultStr:='ReadingParameters';

    FOR Cur_Parameter IN
      (SELECT i.Record_ID,
        i.AD_User_ID,
        p.ParameterName,
        p.P_String,
        p.P_Number,
        p.P_Date
      FROM AD_PINSTANCE i
      LEFT JOIN AD_PINSTANCE_PARA p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Record_ID:=Cur_Parameter.Record_ID;
      v_AD_User_ID:=Cur_Parameter.AD_User_ID;
      IF(Cur_Parameter.ParameterName='AD_Client_ID') THEN
        v_AD_Client_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  AD_Client_ID=' || v_AD_Client_ID ;
      ELSIF(Cur_Parameter.ParameterName='AD_Table_ID') THEN
        v_AD_Table_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  AD_Table_ID=' || v_AD_Table_ID ;
      ELSIF(Cur_Parameter.ParameterName='DATEFROM') THEN
        v_datefrom:=Cur_Parameter.P_Date;
        RAISE NOTICE '%','  DATEFROM=' || v_datefrom ;
      ELSIF(Cur_Parameter.ParameterName='DATETO') THEN
        v_dateto:=Cur_Parameter.P_Date;
        RAISE NOTICE '%','  DATETO=' || v_dateto ;
      ELSIF(Cur_Parameter.ParameterName='AD_Org_ID') THEN
        v_AD_Org_ID:=Cur_Parameter.P_String;
        IF (v_AD_Org_ID IS NULL) THEN
          v_AD_Org_ID:='0';
        END IF;
        RAISE NOTICE '%','  AD_ORG_ID=' || v_AD_Org_ID ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; -- Get Parameter

    
    -- Get AD_Org_ID from the document header (useful when the process is executed from a document)
    IF (v_AD_Table_ID IS NOT NULL AND v_Record_ID IS NOT NULL AND v_Record_ID!='0') THEN
        SELECT TableName
        INTO v_TableName
        FROM AD_Table
        WHERE AD_Table_ID=v_AD_Table_ID;
        IF (v_Record_ID!='0') THEN
         EXECUTE
          'SELECT AD_Org_ID
          FROM ' ||  v_TableName || '
          WHERE ' || v_TableName || '_ID =''' || v_Record_ID || ''' AND AD_CLIENT_ID =''' || v_AD_Client_ID || ''' '
          INTO v_AD_Org_ID;
        END IF;
    END IF;

    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
   -- Fact_Acct_Rest - Finish_Process Extension Point
    RAISE NOTICE '%','AD_Client_ID=' || v_AD_Client_ID || ', AD_Table_ID=' || v_AD_Table_ID || ' ' || v_TableName ;
          -- Update Table
    v_ResultStr:='ResetTable:' || v_TableName;
    -- SZ delete only in Opened Periods!!!!!
    select count(*) into v_openperiod from c_periodcontrol_v where ad_client_id=v_AD_Client_ID and ad_org_id=v_AD_Org_ID
                        and isactive='Y' and periodstatus='O' ;
    -- Tests If open period exists
    if v_openperiod=0 then
            v_ResultStr:='@ERROR=@zspr_NoOpenPeriod@';
            RAISE EXCEPTION '%', '@zspr_NoOpenPeriod@' ;
            return;
    end if;
   
    --SZ: BUGFIX : Always RESET Accounting Entrys - Otherwise there is CAOS in the GL !
    -- Manual Accounting will not be resetted Automatically
    FOR Cur_Fact_Acct IN (
        SELECT DISTINCT f.Record_ID,f.ad_client_id,f.dateacct,f.ad_org_id,f.docbasetype,f.ad_table_id
        FROM FACT_ACCT f,c_periodcontrol_v v
        WHERE case when v_AD_Table_ID  is null then 1=1 else f.AD_TABLE_ID=v_AD_Table_ID end
        and v.c_period_id=f.c_period_id and v.ad_client_id=f.ad_client_id and v.ad_org_id=f.ad_org_id and v. isactive='Y' and v.periodstatus='O'  and f.docbasetype=v.docbasetype
        AND   f.ad_org_id=v_AD_Org_ID
        AND f.ad_client_id=v_AD_Client_ID
        AND case when v_datefrom is null then 1=1 else f.dateacct>=v_datefrom end
        AND case when v_dateto is null then 1=1 else f.dateacct<=v_dateto end 
        AND case when v_Record_ID is null then  1=1 when v_Record_ID='0' then 1=1 else f.record_id=v_Record_ID end
        AND f.AD_TABLE_ID!='4AF9D81E51A04F2B987CD91AA9EE99F4'
        ) LOOP
        v_ResultStr:='DeleteFact';
        
        -- SZ Delete the FACTS
        select TableName into v_TableName FROM AD_Table  WHERE AD_Table_ID=Cur_Fact_Acct.ad_table_id;
        v_Cmd:='UPDATE ' || v_TableName  || ' SET Posted=''N'', Processing=''N'' WHERE AD_Client_ID='''  || v_AD_Client_ID
                || ''' AND (Posted<>''N'' OR Posted IS NULL OR Processing<>''N'' OR Processing IS NULL) AND '   ||
                v_TableName||'_ID = '''||Cur_Fact_Acct.Record_ID||'''';
        -- DBMS_OUTPUT.PUT_LINE('  executing: ' || v_Cmd);
        EXECUTE v_Cmd;
        GET DIAGNOSTICS v_rowcount:=ROW_COUNT;
        v_Updated:=v_Updated + v_rowcount;
        RAISE NOTICE '%','  updated=' || v_rowcount ;
        for v_cur in (select FACT_ACCT_GROUP_ID FROM FACT_ACCT  WHERE AD_TABLE_ID=Cur_Fact_Acct.AD_Table_ID  AND Record_ID=Cur_Fact_Acct.Record_ID)
        LOOP
            -- Delete Fact
            DELETE FROM FACT_ACCT  WHERE FACT_ACCT_GROUP_ID=v_cur.FACT_ACCT_GROUP_ID;
            GET DIAGNOSTICS v_rowcount:=ROW_COUNT;
            v_Deleted:=v_Deleted + v_rowcount;
            RAISE NOTICE '%','  deleted=' || v_rowcount ; 
        END LOOP;
    END LOOP;
    --
    -- Summary info
    v_Message:='@UnpostedDocuments@ = ' || v_Updated || ', @DeletedEntries@ = ' || v_Deleted;
    --||'OR:'||v_AD_Org_ID||'-Cl:'||v_AD_Client_ID||'R:'||coalesce(v_Record_ID,'NOREC')||'-T:'||coalesce(v_AD_Table_ID,'NOTAB')||v_ResultStr||coalesce(v_datefrom,now()+1000)||coalesce(v_dateto,now()+100);
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  if v_ResultStr!='@ERROR=@zspr_NoOpenPeriod@' then  
      v_ResultStr:= '@ERROR=' || SQLERRM;
  end if;
  RAISE NOTICE '%',v_ResultStr ;
  -- ROLLBACK;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ; $_$;



/*****************************************************+
Stefan Zimmermann, 10/2010, stefan@zimmermann-software.de



   Implementation of BWA Reporting
   




*****************************************************/
CREATE OR REPLACE FUNCTION zspr_child_bwap(node character varying) RETURNS setof zspr_bwaprefs
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Finance
Allows to implement Self-Joins (Like CONNECT TO in ORACLE)
*****************************************************/
i integer;
temp1 character varying;
temp2 character varying;
retval zspr_bwaprefs%rowtype;
--cur_node RECORD;
weiter character varying:='Y';
BEGIN 
    temp2:='select *  from zspr_bwaprefs where parentpref in ('||chr(39)||node||chr(39)||')';
    WHILE weiter='Y'
    LOOP
        weiter:='N';
        for retval in execute temp2
        loop
         if retval.isparent='Y' then 
             if temp1 is null then
                temp1:=chr(39)||retval.zspr_bwaprefs_id||chr(39);
             else
                temp1:=chr(39)||retval.zspr_bwaprefs_id||chr(39)||','||temp1; 
             end if;
             weiter:='Y';
         end if;
         return next retval;
        end loop;
        temp2:='select *  from zspr_bwaprefs where parentpref in ('||temp1||')';
        temp1:= null;
     end loop;
END;
$_$  LANGUAGE 'plpgsql';
     
CREATE OR REPLACE FUNCTION zsfi_bwainit(bwaheader_id character varying,date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying) RETURNS varchar
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Sub-Fuction for BWA-Report
Gets the Total of a specific BWA (All Accounts defined in it)
Part of Finance
*****************************************************/
v_cur RECORD;
v_cur2 RECORD;
v_cur3 RECORD;
v_sum numeric:=0;
v_sum_faktura numeric;
v_sum_nofaktura numeric;
v_sum_orderamt numeric;
v_runratefaktura numeric;
v_runratenofaktura   numeric;
v_runrateorder numeric;
v_ford numeric;
v_verb numeric;
v_return numeric:=0;
v_adddays INTERVAL;
v_vj varchar:='N';
v_i numeric:=0;
v_acctmatch character varying;
v_acctschema varchar;
BEGIN 

if (SELECT count(*) from information_schema.tables where table_name='bwacalculation')=0 then
    create temporary table bwacalculation(
        c_acctschema_id varchar(32),
        ACCTVALUE varchar(32),
        account_id varchar(32),
        summe numeric,
        lastyear varchar(1),
        ad_org_id varchar(32),
        accountsign varchar(32)
    )  ON COMMIT DROP ;
else
    truncate table bwacalculation;
end if; 
    for v_cur2 in (select  zspr_bwaprefs_id from zspr_bwaprefs where  parentpref is null and zspr_bwaheader_id=bwaheader_id)
    LOOP
       for  v_cur in (select * from zspr_child_bwap(v_cur2.zspr_bwaprefs_id) union 
                      select * from zspr_bwaprefs where zspr_bwaprefs_id =v_cur2.zspr_bwaprefs_id
                      and not exists (select 0  from zspr_bwaprefs where parentpref=v_cur2.zspr_bwaprefs_id))
       LOOP
          FOR v_i IN 1..2 LOOP
            if v_i=1 then
               v_vj:='N'; 
               v_adddays:= INTERVAL  '0 YEAR';
            else
               v_vj:='Y'; 
               v_adddays:= INTERVAL  '1 YEAR';
            end if;
            for v_cur3 in (select CASE WHEN v_cur.isasset='N' THEN (SUM(fact_acct.AMTACCTDR)-SUM(fact_acct.AMTACCTCR)) 
                                              ELSE (SUM(fact_acct.AMTACCTCR)-SUM(fact_acct.AMTACCTDR)) END as summe,
                           fact_acct.c_acctschema_id,fact_acct.ACCTVALUE,fact_acct.account_id,v.accountsign
                    from fact_acct,zspr_bwaprefacct bwaprefacct,c_elementvalue v where 
                          not exists(select 0 from bwacalculation where bwacalculation.account_id=fact_acct.account_id and bwacalculation.lastyear=v_vj) and
                          CASE when v_org!='0' then fact_acct.ad_org_id=v_org else 1=1 END 
                          and v_cur.isactive='Y'  
                          and v.c_elementvalue_id=fact_acct.account_id
                          and bwaprefacct.zspr_bwaprefs_id=v_cur.zspr_bwaprefs_id 
                          and fact_acct.ACCTVALUE like replace(bwaprefacct.acctmatch,'*','%')
                          and case when instr(bwaprefacct.acctmatch,'*')>0 then v.accountsign in ('F','E') else  v.accountsign not in ('F','E') end
                          and bwaprefacct.c_acctschema_id=fact_acct.c_acctschema_id
                          and trunc(fact_acct.dateacct)+v_adddays between CASE when v_cur.sumfrombeginning='Y' then to_date('10.10.1900','dd.mm.yyyy') else trunc(date_from) END and trunc(date_to)
                          group by fact_acct.c_acctschema_id,fact_acct.ACCTVALUE,fact_acct.account_id,v.accountsign)
            LOOP
               if (select count(*) from bwacalculation where account_id=v_cur3.account_id and lastyear=v_vj)=0 then
                insert into bwacalculation (c_acctschema_id,ACCTVALUE,account_id,summe,lastyear,ad_org_id,accountsign) 
                values (v_cur3.c_acctschema_id,v_cur3.ACCTVALUE,v_cur3.account_id,v_cur3.summe,v_vj,v_org,v_cur3.accountsign);
                v_acctschema:=v_cur3.c_acctschema_id;
               end if;
            END LOOP;
            for v_cur3 in (select 0 as summe,v_acctschema as c_acctschema_id,c_elementvalue.value as ACCTVALUE,c_elementvalue.c_elementvalue_id as account_id,c_elementvalue.accountsign
                                    from c_elementvalue,zspr_bwaprefacct bwaprefacct ,zsfi_budget,zsfi_budgetperiod,c_period where 
                                    not exists(select 0 from bwacalculation where bwacalculation.account_id=c_elementvalue.c_elementvalue_id and bwacalculation.lastyear=v_vj) and
                                    c_elementvalue.c_elementvalue_id=zsfi_budget.c_elementvalue_id and zsfi_budgetperiod.zsfi_budget_id=zsfi_budget.zsfi_budget_id and zsfi_budgetperiod.c_period_id=c_period.c_period_id
                                    and CASE when v_org!='0' then zsfi_budget.ad_org_id=v_org else 1=1 END 
                                    and v_cur.isactive='Y'  
                                    and bwaprefacct.zspr_bwaprefs_id=v_cur.zspr_bwaprefs_id 
                                     and c_elementvalue.value like replace(bwaprefacct.acctmatch,'*','%')
                                     and case when instr(bwaprefacct.acctmatch,'*')>0 then c_elementvalue.accountsign in ('F','E') else  c_elementvalue.accountsign not in ('F','E') end
                                     and bwaprefacct.c_acctschema_id=v_acctschema
                                     and trunc(c_period.startdate)+v_adddays >= trunc(date_from) and   trunc(c_period.enddate)+v_adddays <= trunc(date_to)
                                     group by c_elementvalue.value,c_elementvalue.c_elementvalue_id,c_elementvalue.accountsign)
             LOOP
                if (select count(*) from bwacalculation where account_id=v_cur3.account_id and lastyear=v_vj)=0 then
                    insert into bwacalculation (c_acctschema_id,ACCTVALUE,account_id,summe,lastyear,ad_org_id,accountsign) 
                    values (v_cur3.c_acctschema_id,v_cur3.ACCTVALUE,v_cur3.account_id,v_cur3.summe,v_vj,v_org,v_cur3.accountsign);
                end if;
             END LOOP;
          END LOOP;
       END LOOP;
    END LOOP;    
 return 'OK';
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsfi_getbwasum(bwapref_id character varying,date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying,isVJ character varying) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Sub-Fuction for BWA-Report
Gets the Total of a specific BWA (All Accounts defined in it)
Part of Finance
*****************************************************/
v_cur RECORD;
v_cur2 RECORD;
v_cur3 RECORD;
v_sum numeric:=0;
v_sum_faktura numeric;
v_sum_nofaktura numeric;
v_sum_orderamt numeric;
v_runratefaktura numeric;
v_runratenofaktura   numeric;
v_runrateorder numeric;
v_ford numeric;
v_verb numeric;
v_return numeric:=0;
v_adddays numeric;
v_acctmatch character varying;
v_revsum numeric:=0;
BEGIN 

      if isVJ='Y' then v_adddays:=365; else v_adddays:=0; end if; 
      for v_cur in (select * from zspr_child_bwap(bwapref_id) union select * from zspr_bwaprefs where zspr_bwaprefs_id =bwapref_id)
      LOOP
        if v_cur.isparent='N' then
            for v_cur2 in (select coalesce(ca.summe,0) as summe  from bwacalculation ca, zspr_bwaprefacct bwaprefacct,c_elementvalue v 
                                             where  bwaprefacct.zspr_bwaprefs_id=v_cur.zspr_bwaprefs_id 
                                             and v.c_elementvalue_id=ca.account_id
                                             and ca.ACCTVALUE like replace(bwaprefacct.acctmatch,'*','%')
                                             and case when instr(bwaprefacct.acctmatch,'*')>0 then v.accountsign in ('F','E') else  v.accountsign not in ('F','E') end
                                             and bwaprefacct.c_acctschema_id=ca.c_acctschema_id
                                             and ca.lastyear=isVJ)
            LOOP
                v_sum:=v_cur2.summe;
                if (v_cur.allwowonlynegative='Y' and v_sum<0) or (v_cur.allwowonlypositive='Y' and v_sum>0) 
                    or (v_cur.allwowonlypositive='N' and v_cur.allwowonlynegative='N') then
                    v_return:=v_return+coalesce(v_sum,0);
                end if;
            end LOOP;
         end if;
      END LOOP;
      if (select count(*) from ZSPR_Bwaprefs where ZSPR_Bwaprefs_id=bwapref_id and addreversechargeasrevenue='Y')>0 then
        select sum(f.amtacctdr-f.amtacctcr) into v_revsum
            from fact_acct f,c_elementvalue v
            where v.c_elementvalue_id=f.account_id and
                  f.fact_acct_group_id in (select fact_acct_group_id from fact_acct where 
                                                  case when isVJ='N' then dateacct between date_from and date_to else dateacct between date_from -interval '1 year' and date_to-interval '1 year' end
                   and c_tax_id in (select c_tax_id from c_tax where reversecharge='Y') and 
                   case when v_org!='0' then ad_org_id=v_org else 1=1 end)
            and (case when v.c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' then v.value like '16%' else v.value like '33%' end or v.accountsign ='F');
      end if;
      return coalesce(v_return+coalesce(v_revsum,0),0);
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsfi_getfooterbwasum(bwapref_id character varying,date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying,isVJ character varying) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Sub-Fuction for BWA-Report
Gets the Total of a specific BWA (All Accounts defined in it)
Part of Finance
*****************************************************/

v_issuminfooter character varying;
BEGIN 
      select issuminfooter into v_issuminfooter from zspr_bwaprefs where zspr_bwaprefs_id =bwapref_id;
      if v_issuminfooter='Y' then 
         return zsfi_getbwasum(bwapref_id,date_from,date_to, v_org,isVJ); 
      else 
         return 0; 
      end if; 
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zsfi_getfooterbwabsum(bwapref_id character varying,date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying,isVJ character varying) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Sub-Fuction for BWA-Report
Gets the Total of a specific BWA (All Accounts defined in it)
Part of Finance
*****************************************************/

v_issuminfooter character varying;
BEGIN 
      select issuminfooter into v_issuminfooter from zspr_bwaprefs where zspr_bwaprefs_id =bwapref_id;
      if v_issuminfooter='Y' then 
         return zsfi_getbbudgetsum(bwapref_id,date_from,date_to, v_org,isVJ); 
      else 
         return 0; 
      end if; 
END;
$_$  LANGUAGE 'plpgsql';





CREATE OR REPLACE FUNCTION zsfi_getacctsum(bwapref_id character varying,p_acct character varying, date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying,isVJ character varying) RETURNS numeric
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Sub-Fuction for BWA-Report
Gets the Total of a specific Account
Part of Finance
*****************************************************/
v_cur RECORD;
v_sum numeric:=0;
v_return numeric:=0;
v_adddays numeric;
BEGIN   
      if isVJ='Y' then v_adddays:=365; else v_adddays:=0; end if; 
      for v_cur in (select * from zspr_bwaprefs where zspr_bwaprefs_id =bwapref_id)
      LOOP
           
                 select ca.summe into v_sum from bwacalculation ca where ca.account_id= p_acct and
                        case  when v_cur.allwowonlynegative='Y' then ca.summe<0 else 1=1 END and
                        case  when v_cur.allwowonlypositive='Y' then ca.summe>0 else 1=1 END
                        and ca.lastyear=isVJ;

            v_return:=v_return+coalesce(v_sum,0);
      END LOOP;
      return coalesce(v_return,0);
END;
$_$  LANGUAGE 'plpgsql';


SELECT zsse_dropfunction ('zspr_get_bwastatus'); 
CREATE OR REPLACE FUNCTION zspr_get_bwastatus(date_from timestamp without time zone,date_to timestamp without time zone, v_org character varying,v_lang varchar) RETURNS character varying
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Finance
Status: vorläufig: wenn nicht alle periode entgültig geschlossen
*****************************************************/
v_count numeric;
BEGIN 
   select count(*) into v_count from C_PeriodControl_V where case when v_org ='0' or v_org is null then 1=1 else ad_org_id=v_org end and startdate between date_to and date_from and enddate between date_to and date_from  and periodstatus!='P';
   if v_count!=0 then
      return zssi_getText('bwastatustemp',v_lang);
   else
      return  zssi_getText('bwastatustemp',v_lang);
   end if;
END;
$_$  LANGUAGE 'plpgsql';
     
CREATE OR REPLACE FUNCTION zsfi_getbalancebegindate (
  p_org         VARCHAR,   -- ad_org_id
  p_acct        VARCHAR,   -- fact_acct
  p_date_from   TIMESTAMP  -- 'YYYY-MM-DD'
)
RETURNS DATE AS
$body$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): 2012-02-21 MaHinrichs: selection p_org_id, factaccttype, isactive
***************************************************************************************************************************************************
Gets the Total of an account to a specific Time
*****************************************************/
  v_count numeric;
  v_Total numeric;
  v_startcurryear DATE;
  v_accounttype VARCHAR(60); -- c_elementvalue.accounttype(60)
BEGIN
  --Saldo für Sachkonto ermitteln
  --A=Asset/Aktiva/Anlagen, E=Expense/Kosten, L=Liability/Passiva/Schulden, O=Owners Equity/Eigenkapital, R=Revenue/Ertrag
  SELECT TRIM(accounttype) INTO v_accounttype FROM c_elementvalue WHERE c_elementvalue_id = p_acct AND accounttype in ('A','L','O', 'E', 'R');
  -- Automatische 0 - Saldo für Aufwand und Ertrag bei Geschäftsjahresbeginn
  select p.startdate into v_startcurryear FROM c_periodcontrol pc, c_period p, c_year y where pc.c_period_id = p.c_period_id AND p.c_year_id = y.c_year_id
               and pc.ad_org_id=p_org  and y.year=extract (year from p_date_from)::text order by   p.startdate limit 1;
               
  if  v_accounttype IN ('E','R') then 
    return coalesce(v_startcurryear,to_date('01.01'|| to_char(p_date_from,'YYYY') ,'dd.mm.yyyy')); 
  else 
    return  to_date ('01.01.0001','dd.mm.yyyy'); 
  end if;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE;


CREATE OR REPLACE FUNCTION public.zsfi_getbalanceattime (
  p_org         VARCHAR,   -- ad_org_id
  p_schema      VARCHAR,   -- c_acctschema
  p_acct        VARCHAR,   -- fact_acct
  p_date_from   TIMESTAMP  -- 'YYYY-MM-DD'
)
RETURNS numeric AS
$body$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): 2012-02-21 MaHinrichs: selection p_org_id, factaccttype, isactive
***************************************************************************************************************************************************
Gets the Total of an account to a specific Time
*****************************************************/
  v_count numeric;
  v_Total numeric;
  v_startcurryear timestamp;
  v_accounttype VARCHAR(60); -- c_elementvalue.accounttype(60)
BEGIN
  --Saldo für Sachkonto ermitteln
  --A=Asset/Aktiva/Anlagen, E=Expense/Kosten, L=Liability/Passiva/Schulden, O=Owners Equity/Eigenkapital, R=Revenue/Ertrag
  SELECT TRIM(accounttype) INTO v_accounttype FROM c_elementvalue WHERE c_elementvalue_id = p_acct AND accounttype in ('A','L','O', 'E', 'R');
  -- Automatische 0 - Saldo für Aufwand und Ertrag bei Geschäftsjahresbeginn
  select p.startdate into v_startcurryear FROM c_periodcontrol pc, c_period p, c_year y where pc.c_period_id = p.c_period_id AND p.c_year_id = y.c_year_id
               and pc.ad_org_id=p_org  and y.year=extract (year from p_date_from)::text order by   p.startdate limit 1;
  SELECT sum( (CASE WHEN v_accounttype IN ('A', 'E') THEN f.amtacctcr ELSE f.amtacctdr END) - (CASE WHEN v_accounttype IN ('A', 'E') THEN f.amtacctdr ELSE f.amtacctcr END) )
  INTO v_Total
  FROM fact_acct f
  WHERE
       f.account_id = p_acct
   AND f.dateacct < p_date_from
   AND case when v_accounttype IN ('E','R') then f.dateacct>=v_startcurryear else 1=1 end
   AND f.ad_org_id = p_org
   AND f.c_acctschema_id = p_schema
   AND f.factaccttype <> 'R'
   AND f.factaccttype <> 'C'
   AND f.isactive = 'Y';
  RETURN COALESCE(v_Total,0);
END;
$body$
LANGUAGE 'plpgsql' VOLATILE;

CREATE OR REPLACE FUNCTION public.zsfi_GetBalanceAmount (
  p_org         VARCHAR,   -- ad_org_id
  p_schema      VARCHAR,   -- c_acctschema
  p_acct        VARCHAR,   -- fact_acct
  p_date_from   TIMESTAMP, -- 'YYYY-MM-DD'
  p_date_until  TIMESTAMP  -- 'YYYY-MM-DD'
)
RETURNS NUMERIC AS
$body$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): 2012-02-20 MaHinrichs source file created
***************************************************************************************************************************************************
*****************************************************/
  v_accounttype VARCHAR(60); -- c_elementvalue.accounttype(60)
  v_Total NUMERIC := 0;
BEGIN
--A=Asset/Aktiva/Anlagen, E=Expense/Kosten (GuV), L=Liability/Passiva/Schulden, O=Owners Equity/Eigenkapital, R=Revenue/Ertrag (GuV)
  SELECT TRIM(accounttype) INTO v_accounttype FROM c_elementvalue WHERE c_elementvalue_id=p_acct AND accounttype in ('A','L','O', 'E', 'R');
  IF (v_accounttype IS NOT NULL) THEN
    SELECT sum( (CASE WHEN v_accounttype IN ('A', 'E') THEN f.amtacctcr ELSE f.amtacctdr END) - (CASE WHEN v_accounttype IN ('A', 'E') THEN f.amtacctdr ELSE f.amtacctcr END) ) INTO v_Total -- (CASE WHEN a IS NULL THEN '' ELSE   END)
    FROM fact_acct f
    WHERE
         f.account_id = p_acct
     AND f.dateacct BETWEEN p_date_from AND p_date_until
     AND f.ad_org_id = p_org
     AND f.c_acctschema_id = p_schema
     AND f.factaccttype <> 'R'
     AND f.factaccttype <> 'C'
     AND f.isactive = 'Y';
    v_Total := COALESCE(v_Total,0);
    RETURN COALESCE(v_Total,0);
  ELSE
    RETURN (0); -- (M) Saldenvorträge etc.
  END IF;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE;

CREATE OR REPLACE FUNCTION zsfi_insertparentbwas()
  RETURNS character varying AS
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
  Part of finance
  Purpose: BWA's set correct accounts for Parent/Sums
Update Parent- when Accounts in Child are added

*****************************************************/
v_weiter              character varying;
v_parent              character varying;
v_current             character varying;
v_cur                 RECORD;
BEGIN
  delete from zspr_bwaprefacct where exists(select 0 from zspr_bwaprefs where zspr_bwaprefs.zspr_bwaprefs_id=zspr_bwaprefacct.zspr_bwaprefs_id and zspr_bwaprefs.isparent='Y');
  for v_cur in (select * from zspr_bwaprefs where isparent='N' and isactive='Y') 
  LOOP 
      if v_cur.parentpref is not null then
          v_current:=v_cur.parentpref;
          v_weiter:='Y';
          WHILE v_weiter='Y'
          LOOP
              -- Insert Parent
              insert into zspr_bwaprefacct(ZSPR_BWAPREFACCT_ID, ZSPR_BWAPREFS_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, ACCTMATCH,c_acctschema_id)
                 select get_uuid(),v_current,v_cur.AD_CLIENT_ID, v_cur.AD_ORG_ID, v_cur.ISACTIVE, v_cur.CREATED, v_cur.CREATEDBY, v_cur.UPDATED, v_cur.UPDATEDBY,acctmatch,c_acctschema_id
                 from zspr_bwaprefacct where ZSPR_BWAPREFS_ID=v_cur.ZSPR_BWAPREFS_ID;
              -- More Parents??
              select parentpref into v_parent from zspr_bwaprefs where zspr_bwaprefs_id=v_current;
              if v_parent is not null then
                 v_current:=v_parent; 
              else
                 v_weiter:='N';
              end if;
           END LOOP;
      end if;    
   END LOOP;
RETURN 'OK';
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION zsfi_insertparentbwas(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_message character varying:='OK - Process finished';
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Call the Proc
    perform zsfi_insertparentbwas();
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



/*****************************************************+
Stefan Zimmermann, 10/2010, stefan@zimmermann-software.de



   Implementation of Manual Accounting
   
   Accounting BATCH



*****************************************************/

CREATE OR REPLACE FUNCTION zsfi_macctline_trg()
  RETURNS trigger AS
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
Part of Financials
Status-Checks for Manual Accounting
*****************************************************/
v_temp              character varying;
v_nogo              character varying:='N';

BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  
  if (TG_OP = 'UPDATE') or (TG_OP = 'INSERT') then 
    select glstatus into v_temp from zsfi_manualacct where zsfi_manualacct_id=new.zsfi_manualacct_id;
    if (TG_OP = 'UPDATE') then
       -- Canelling Lines with a process is allowed on Posted Lines
       if (new.glstatus='CA' and old.glstatus='PO') then
          v_temp='OP';
       end if;
    end if;
  end if;
  if (TG_OP = 'DELETE') then
     select glstatus into v_temp from zsfi_manualacct where zsfi_manualacct_id=old.zsfi_manualacct_id;
  end if;
  -- Sauberer Umgang mit Projektzuordnung
  if (TG_OP = 'UPDATE') then
      if coalesce(new.c_project_id, '0') != coalesce(old.c_project_id, '0') and new.c_project_id is null then
         new.c_projecttask_id:=null;
      end if;
  end if;
  if v_temp!='OP' then
      RAISE EXCEPTION '%', '@zsfi_NotOpenMacct@' ;
      return OLD;
  end if; 
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_macctline_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_manualacct_trg()
  RETURNS trigger AS
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
Part of Financials
Hotfix: Status-Checks for Manual Accounting
*****************************************************/
v_temp              character varying;
v_nogo              character varying:='N';

BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF; 
  if (old.glstatus!='OP') then
      RAISE EXCEPTION '%', '@zsfi_NotOpenMacct@' ;
      return OLD;
  end if; 
RETURN OLD;  
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_manualacct_trg() OWNER TO tad;




CREATE OR REPLACE FUNCTION zspr_macct_post(p_pinstance_id character varying)
  RETURNS void AS
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
  Part of finance
  Purpose: Manual accounting. Post GL/Journal
  *****************************************************/
  -- General CONSTs
  v_acctshema character varying;
  v_period character varying;
  v_glcat character varying;
  v_table_id character varying :='4AF9D81E51A04F2B987CD91AA9EE99F4'; --zsfi_manualacct
  v_currency character varying;
  v_docbasetype character varying := 'GLJ';
  v_postingtype character varying := 'A';
  -- Line- Calculation-Vars
  v_seqno numeric:=0;
  v_taxrate numeric;
  v_taxamt numeric;
  v_netamt numeric;
  v_grossamt numeric;
  v_cramt numeric;
  v_dramt numeric;
  -- Accounts for Tax
  v_taxdebtacct character varying;
  v_taxcredacct character varying;
  -- Actually booked account - with description and value
  v_acct character varying;
  v_acct_val character varying;
  v_acct_desc character varying;
  -- Tax
  v_tax_id character varying := null; 
  -- SOPO: Sales or Purcase: B=Both, S=Sales, P=Purchase
  v_sopotax  character varying;
  v_reversecharge  character varying;
  -- Internal vars
  v_count numeric;
  v_i numeric;
  v_temp character varying;
  v_temp2 character varying;
  -- mgmt Vars
  v_Message character varying;
  v_User character varying;
  -- Header Vars
  v_Record character varying;
  v_Org character varying;
  v_Client character varying;
  v_acctdate DATE;
  v_doc character varying;
  -- Lines
  v_cur_line zsfi_macctline%rowtype;
  -- CheckSums
  v_checksumDR numeric:=0;
  v_checksumCR numeric:=0;
  v_prjcur record;
BEGIN
  RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
  v_Message:='PInstanceNotFound';
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL);
  -- Get Parameter
  SELECT i.Record_ID, i.AD_User_ID into v_Record, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
  if v_Record is null then
    v_Record:=p_PInstance_ID;
    v_user:='0';
  end if;
  v_Message:='PInstanceUpdated:'||v_Record;
  -- Load fixed values
  select acctdate, ad_org_id,ad_client_id,documentno into v_acctdate,v_Org,v_Client,v_doc from zsfi_manualacct where zsfi_manualacct_id=v_Record;
  select c_acctschema_id into v_acctshema from ad_org_acctschema where ad_org_id=v_Org and ad_client_id=v_Client;
  select c_currency_id into v_currency from c_acctschema where c_acctschema_id=v_acctshema;  
  select count(*) into v_count from c_periodcontrol_v where ad_client_id=v_Client and ad_org_id=v_Org and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=v_acctdate and enddate>=v_acctdate;
  -- Tests
  if v_count!=1 then
   RAISE EXCEPTION '%', '@zspr_NoOpenPeriod@' ;
   return;
  end if;
  select c_period_id into v_period from c_periodcontrol_v where ad_client_id=v_Client and ad_org_id=v_Org and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=v_acctdate and enddate>=v_acctdate;
  select count(*) into v_count from gl_category where ad_client_id=v_Client and ad_org_id in (v_Org,'0') and isactive='Y' and categorytype='M' and isdefault='Y';
  if v_count!=1 then
   RAISE EXCEPTION '%', '@zspr_NoGLCATfound@' ;
   return;
  end if;
  -- Check if there are lines document does
  if (select count(*) from  zsfi_macctline where zsfi_manualacct_id = v_Record)=0 then
          RAISE EXCEPTION '%', '@NoLinesInDoc@';
  END IF; 
  select gl_category_id into v_glcat from gl_category where ad_client_id=v_Client and ad_org_id in (v_Org,'0') and isactive='Y' and categorytype='M' and isdefault='Y';
  -- Load the Lines
  for v_cur_line in (select * from zsfi_macctline where zsfi_manualacct_id=v_Record)
  LOOP
      select count(*) into v_count from c_periodcontrol_v where ad_client_id=v_Client and ad_org_id=v_Org and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=v_cur_line.acctdate and enddate>=v_cur_line.acctdate;
      -- Tests
      if v_count!=1 then
         RAISE EXCEPTION '%', '@zspr_NoOpenPeriod@' ||' - '||to_char(v_cur_line.acctdate,'dd.mm.yyyy');
         return;
      end if;
      select c_period_id into v_period from c_periodcontrol_v where ad_client_id=v_Client and ad_org_id=v_Org and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=v_cur_line.acctdate and enddate>=v_cur_line.acctdate;
      v_seqno:=0;
      select count(*) into v_count from c_tax_acct where c_tax_id=v_cur_line.C_Tax_ID and isactive='Y' and c_acctschema_id=v_acctshema;
      if v_count!=1 then
        RAISE EXCEPTION '%', '@zspr_NoTaxACCTfound@' ;
        return;
      end if;  
      if v_cur_line.amt=0 then 
        RAISE EXCEPTION '%', '@zsfi_AmountIsNull@' ;
        return;
      end if;  
      -- Select TAX-Accounts
      select t_credit_acct,t_due_acct into v_temp,v_temp2 from c_tax_acct where c_tax_id=v_cur_line.C_Tax_ID and isactive='Y' and c_acctschema_id=v_acctshema;
      select c_elementvalue.c_elementvalue_id into v_taxdebtacct from c_elementvalue,c_validcombination where c_elementvalue.c_elementvalue_id=c_validcombination.account_id and c_validcombination.c_validcombination_id=v_temp2;
      select c_elementvalue.c_elementvalue_id into v_taxcredacct from c_elementvalue,c_validcombination where c_elementvalue.c_elementvalue_id=c_validcombination.account_id and c_validcombination.c_validcombination_id=v_temp;
      -- calculate TAX
      select rate,sopotype,reversecharge into v_taxrate,v_sopotax,v_reversecharge from c_tax where c_tax_id=v_cur_line.C_Tax_ID;
      if v_taxrate!=0 and v_reversecharge='N' then
         if v_cur_line.isgross='Y' then
            v_netamt:=C_Currency_Round((v_cur_line.amt/(1+(v_taxrate/100))),v_currency,null);
            v_taxamt:=v_cur_line.amt-v_netamt;
            v_grossamt:=v_cur_line.amt;
         else
            v_netamt:=v_cur_line.amt;
            v_taxamt:=C_Currency_Round(v_cur_line.amt*(v_taxrate/100),v_currency,null);
            v_grossamt:=v_netamt+v_taxamt;
         end if;
      else
         if v_reversecharge='Y' and v_taxrate!=0 then 
            v_taxamt:=C_Currency_Round(v_cur_line.amt*(v_taxrate/100),v_currency,null);
         else
            v_taxamt:=0;
         end if;
         v_grossamt:=v_cur_line.amt;
         v_netamt:=v_cur_line.amt;
      end if;
      -- Do the Posting:
      -- If we have taxamt, 3 fact_accts are produced, else 2 lines.
      -- isdr2cr: Normally = 'N' => Books from credit to debit (On acctcr Amount is booked as amtacctcr, On acctdr Amount is booked as  amtacctdr, Tax as debit) (Soll an Haben)
      -- isdr2cr = 'Y' => Books from debit to credit (On acctcr Amount is booked as amtacctdr, On acctdr Amount is booked as  amtacctcr, Tax as credit) (Haben an Soll)
      if v_taxamt!=0 then 
          if v_reversecharge='N' then v_count:=3; else v_count:=4; end if;
      else
          v_count:=2;
      end if;
      FOR v_i IN 1..v_count LOOP
        v_seqno:=v_seqno+10;
        v_tax_id:=null;
        -- first: Source-Account (Contains evtl. tax)
        if v_i=1 then 
            v_acct:=v_cur_line.acctcr; 
            if v_cur_line.isdr2cr='N' then
              v_cramt:=v_grossamt;
              v_dramt:=0;
            else
              v_cramt:=0;
              v_dramt:=v_grossamt;
            end if;
        end if;
        -- next: destination-Account
        if v_i=2 then 
            v_acct:=v_cur_line.acctdr; 
            if v_cur_line.isdr2cr='N' then
              v_dramt:=v_netamt;
              v_cramt:=0;
            else
              v_dramt:=0;
              v_cramt:=v_netamt; 
            end if;
        end if;
        -- last: tax-Accounts
        if v_i>=3 then 
            if v_taxamt!=0 then v_tax_id:=v_cur_line.c_tax_id; else v_tax_id:=null; end if;
            if ((v_cur_line.isdr2cr='N' and v_i=3) or (v_cur_line.isdr2cr='Y' and v_i=4)) then 
              v_acct:=v_taxdebtacct; 
              v_dramt:= v_taxamt;
              v_cramt:=0;
            end if;
            if ((v_cur_line.isdr2cr='Y' and v_i=3) or (v_cur_line.isdr2cr='N' and v_i=4)) then
              v_acct:=v_taxcredacct;  
              v_cramt:= v_taxamt;
              v_dramt:=0;
            end if;
        end if;
        select name,value into v_acct_desc,v_acct_val from c_elementvalue where c_elementvalue_id=v_acct;
        -- Create the Act-Acct
        insert into fact_acct(FACT_ACCT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, C_ACCTSCHEMA_ID,
                              ACCOUNT_ID, DATETRX, DATEACCT, C_PERIOD_ID, AD_TABLE_ID, RECORD_ID, GL_CATEGORY_ID, C_TAX_ID, POSTINGTYPE,
                              C_CURRENCY_ID, 
                               AMTSOURCECR,  AMTSOURCEDR, AMTACCTCR, AMTACCTDR, 
                              DESCRIPTION, FACT_ACCT_GROUP_ID, SEQNO, DOCBASETYPE,
                              ACCTVALUE, ACCTDESCRIPTION,m_product_id,c_project_id,a_asset_id)
                    values(get_UUID(),v_Client,v_Org,'Y',now(),v_User,now(),v_User,v_acctshema,
                            v_acct,now(),v_cur_line.acctdate,v_period,v_table_id, v_cur_line.zsfi_macctline_id,v_glcat, v_tax_id, v_postingtype,
                            v_currency, 
                            v_cramt, v_dramt,v_cramt, v_dramt,
                            substr('J: '||v_doc||' # '||v_cur_line.description,1,255),v_cur_line.zsfi_macctline_id,v_seqno,v_docbasetype,
                            v_acct_val,v_acct_desc,v_cur_line.m_product_id,v_cur_line.c_project_id,v_cur_line.a_asset_id);

         v_checksumDR :=   v_checksumDR +  v_dramt;
         v_checksumCR :=   v_checksumCR +  v_cramt;
      END LOOP; 
      -- Debit And Credit - Sums must be equal
      if v_checksumDR!=v_checksumCR then
        RAISE EXCEPTION '%', '@zsfi_ManualAcctNotBalanced@ -  CSDR: '||to_char(v_checksumDR)||':CSCR:'||to_char(v_checksumCR)||':NET:'||to_char(v_netamt)||':TAX:'||to_char(v_taxamt)||':GR:'||to_char(v_grossamt)||'Text:'||v_cur_line.description;
        return;
      end if;  
  -- Lines
  END LOOP;
  -- Finishing-Update  Header and Lines
  --glstatus OP=open, CA=cancelled, PO=posted
  update zsfi_macctline set glstatus='PO',updated=now(),updatedby=v_User where zsfi_manualacct_id=v_Record;
  update zsfi_manualacct set glstatus='PO',updated=now(),updatedby=v_User where zsfi_manualacct_id=v_Record;
  -- Schedule Update Project Status Process
  for v_prjcur in (select c_project_id from zsfi_macctline where zsfi_manualacct_id=v_Record and c_project_id is not null)
  LOOP
      perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
  END LOOP;
  v_Message:='@zsfi_macct_sucess@';
  RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
    RAISE NOTICE '%',v_Message ;
     v_Message:= '@ERROR=' || SQLERRM;
      RAISE NOTICE '%', v_Message;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message);
      RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zspr_macct_post(p_pinstance_id character varying) OWNER TO tad;



CREATE OR REPLACE FUNCTION zspr_macct_cancel(p_pinstance_id character varying)
  RETURNS void AS
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
  Part of finance
  Purpose: Manual accounting, Cancel GL/Journal
  *****************************************************/
  -- mgmt Vars
  v_Message character varying;
  v_User character varying;
  v_Record character varying;
  v_table_id character varying:='4AF9D81E51A04F2B987CD91AA9EE99F4'; -- zsfi_manualacct
  -- Lines
  -- Lines
  v_cur_line zsfi_macctline%rowtype;
  v_prjcur record;
BEGIN
  RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
  v_Message:='PInstanceNotFound';
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL);
  -- Get Parameter
  SELECT i.Record_ID, i.AD_User_ID into v_Record, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
  v_Message:='PInstanceUpdated:'||v_Record;
  for v_cur_line in (select * from zsfi_macctline where zsfi_manualacct_id=v_Record and glstatus='PO')
  LOOP
     PERFORM zsfi_generic_cancel(v_cur_line.zsfi_macctline_id, v_table_id,v_User);
  END LOOP;
  --glstatus OP=open, CA=cancelled, PO=posted
  update zsfi_manualacct set glstatus='CA',updated=now(),updatedby=v_User where zsfi_manualacct_id=v_Record;
  update zsfi_macctline set glstatus='CA',updated=now(),updatedby=v_User where zsfi_manualacct_id=v_Record and glstatus='PO';
  v_Message:='@zsfi_macct_CA_sucess@';
  RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
  -- Schedule Update Project Status Process
  for v_prjcur in (select c_project_id from zsfi_macctline where zsfi_manualacct_id=v_Record and c_project_id is not null)
  LOOP
      perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
  END LOOP;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
    RAISE NOTICE '%',v_Message ;
     v_Message:= '@ERROR=' || SQLERRM;
      RAISE NOTICE '%', v_Message;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message);
      RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zspr_macct_cancel(p_pinstance_id character varying) OWNER TO tad;

CREATE OR REPLACE FUNCTION zspr_macct_cancelline(p_pinstance_id character varying)
  RETURNS void AS
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
  Part of finance
  Purpose: Manual accounting, Cancel single Line
  *****************************************************/
  -- mgmt Vars
  v_Message character varying;
  v_User character varying;
  -- Header Vars
  v_Record character varying;
  v_table_id character varying:='4AF9D81E51A04F2B987CD91AA9EE99F4';
  -- Lines
  v_cur_line fact_acct%rowtype;
  v_prjcur record;
BEGIN
  RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
  v_Message:='PInstanceNotFound';
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL);
  -- Get Parameter
  SELECT i.Record_ID, i.AD_User_ID into v_Record, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
  v_Message:='PInstanceUpdated:'||v_Record;
  -- Cancel-Run
  PERFORM zsfi_generic_cancel(v_Record, v_table_id,v_User);
  --glstatus OP=open, CA=cancelled, PO=posted
  update zsfi_macctline set glstatus='CA',updated=now(),updatedby=v_User where zsfi_macctline_id=v_Record;
  v_Message:='@zsfi_macct_CAL_sucess@';
  RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
  -- Schedule Update Project Status Process
  for v_prjcur in (select c_project_id from zsfi_macctline where zsfi_manualacct_id=v_Record and c_project_id is not null)
  LOOP
      perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
  END LOOP;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
    RAISE NOTICE '%',v_Message ;
     v_Message:= '@ERROR=' || SQLERRM;
      RAISE NOTICE '%', v_Message;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message);
      RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zspr_macct_cancelline(p_pinstance_id character varying) OWNER TO tad;



CREATE OR REPLACE FUNCTION zspr_macct_unpost(p_pinstance_id character varying)
  RETURNS void AS
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
  Part of finance
  Purpose: Manual accounting UNPOST
  *****************************************************/
  -- mgmt Vars
  v_Message character varying;
  v_User character varying;
  v_Record character varying;
  v_table_id character varying:='4AF9D81E51A04F2B987CD91AA9EE99F4';
  -- Header
  v_org  character varying;
  v_client  character varying;
  -- Lines
  v_cur_line zsfi_macctline%rowtype;
  v_prjcur record;
  v_acctdate timestamp;
  v_count numeric;
BEGIN
  RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
  v_Message:='PInstanceNotFound';
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL);
  -- Get Parameter
  SELECT i.Record_ID, i.AD_User_ID into v_Record, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
  if v_Record is null then
    v_Record:=p_PInstance_ID;
    v_user:='0';
  end if;
  v_Message:='PInstanceUpdated:'||v_Record;
  -- Load values
  select ad_client_id,ad_org_id,acctdate into v_client, v_Org,v_acctdate from zsfi_manualacct where zsfi_manualacct_id=v_Record;
   select count(*) into v_count from c_periodcontrol_v where ad_client_id=v_Client and ad_org_id=v_Org and isactive='Y' and periodstatus='O' and 
   docbasetype='GLJ' and startdate<=v_acctdate and enddate>=v_acctdate;
  -- Tests
  if v_count!=1 then
   RAISE EXCEPTION '%', '@zspr_NoOpenPeriod@' ;
   return;
  end if;
  for v_cur_line in (select * from zsfi_macctline where zsfi_manualacct_id=v_Record)
  LOOP
      -- Delete accounting Lines
      delete from fact_acct where record_id=v_cur_line.zsfi_macctline_id and ad_org_id=v_Org and ad_client_id=v_client and ad_table_id=v_table_id;
  ENd LOOP;
  --glstatus OP=open, CA=cancelled, PO=posted
  update zsfi_manualacct set glstatus='OP',updated=now(),updatedby=v_User where zsfi_manualacct_id=v_Record;
  update zsfi_macctline set glstatus='OP',updated=now(),updatedby=v_User where zsfi_manualacct_id=v_Record;
  v_Message:='@zsfi_macct_UPO_sucess@';
  RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
  -- Schedule Update Project Status Process
  for v_prjcur in (select c_project_id from zsfi_macctline where zsfi_manualacct_id=v_Record and c_project_id is not null)
  LOOP
      perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
  END LOOP;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
  RETURN;
EXCEPTION
WHEN OTHERS THEN
    RAISE NOTICE '%',v_Message ;
     v_Message:= '@ERROR=' || SQLERRM;
      RAISE NOTICE '%', v_Message;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message);
      RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;





CREATE OR REPLACE FUNCTION zsfi_generic_cancel(v_Record character varying, v_table_id character varying, v_User character varying)
  RETURNS void AS
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
  Part of finance
  Purpose: Manual accounting - Generic CANCEL
  *****************************************************/
  -- Lines
  v_cur RECORD;
  v_cur_line RECORD;
  -- Internal vars
  v_count numeric;
  -- New Group ID
  v_uid character varying;
BEGIN
    for v_cur in (select distinct fact_acct_group_id from fact_acct where RECORD_ID=v_Record and ad_table_id=v_table_id)
    LOOP
      v_uid:=get_uuid();
      for v_cur_line in (select * from fact_acct where fact_acct_group_id=v_cur.fact_acct_group_id)
      LOOP
        
        select count(*) into v_count from c_periodcontrol_v where ad_client_id=v_cur_line.ad_client_id and ad_org_id=v_cur_line.ad_org_id and isactive='Y' and periodstatus='O' 
                        and docbasetype=v_cur_line.docbasetype and startdate<=v_cur_line.DATEACCT and enddate>=v_cur_line.DATEACCT;
        -- Tests
        if v_count!=1 then
            RAISE EXCEPTION '%', '@zspr_NoOpenPeriod@' ;
            return;
        end if;
        insert into fact_acct(FACT_ACCT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, C_ACCTSCHEMA_ID,
                                  ACCOUNT_ID, DATETRX, DATEACCT, C_PERIOD_ID, AD_TABLE_ID, RECORD_ID, GL_CATEGORY_ID, C_TAX_ID, POSTINGTYPE,
                                  C_CURRENCY_ID, AMTSOURCEDR, AMTSOURCECR, AMTACCTDR, AMTACCTCR, 
                                  DESCRIPTION, FACT_ACCT_GROUP_ID, SEQNO, DOCBASETYPE,
                                  ACCTVALUE, ACCTDESCRIPTION)
                        values(get_UUID(),v_cur_line.ad_client_id,v_cur_line.ad_org_id,'Y',now(),v_User,now(),v_User,v_cur_line.C_ACCTSCHEMA_ID,
                                v_cur_line.ACCOUNT_ID,now(),v_cur_line.DATEACCT,v_cur_line.C_PERIOD_ID,v_cur_line.AD_TABLE_ID, v_cur_line.RECORD_ID,v_cur_line.GL_CATEGORY_ID, v_cur_line.C_TAX_ID,v_cur_line.POSTINGTYPE ,
                                v_cur_line.C_CURRENCY_ID, v_cur_line.AMTSOURCEDR*(-1), v_cur_line.AMTSOURCECR*(-1),v_cur_line.AMTACCTDR*(-1), v_cur_line.AMTACCTCR*(-1),
                                substr('**CA**  '||v_cur_line.description,1,255),v_uid,v_cur_line.SEQNO,v_cur_line.DOCBASETYPE,
                                v_cur_line.ACCTVALUE, v_cur_line.ACCTDESCRIPTION);
      END LOOP;
    END LOOP;
  RETURN;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION  zsfi_generic_cancel(v_Record character varying, v_table_id character varying,v_User character varying) OWNER TO tad;









/*****************************************************+
Stefan Zimmermann, 10/2010, stefan@zimmermann-software.de



   Implementation of Accounting-Scheme
   
   Chart of ACCOUNTS

   In different Organizations

   1. COA and Validcombination 1:1
*****************************************************/
CREATE OR REPLACE FUNCTION zsfi_getorgCurrency(p_orgid varchar)
    RETURNS VARCHAR AS  $BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
   v_currency varchar;
BEGIN
        if p_orgid is null or p_orgid='0' then
            select c_currency_id into v_currency from ad_client where ad_client_id='C726FEC915A54A0995C568555DA5BB3C';
        else
            select a.c_currency_id into v_currency from ad_org_acctschema o,c_acctschema a where o.c_acctschema_id=a.c_acctschema_id and o.ad_org_id=p_orgid;
        end if;
        return v_currency;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
 

CREATE OR REPLACE FUNCTION zsfi_elementvalue_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/

  v_acctschema    VARCHAR(32); 
  v_count numeric;
    
BEGIN    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  -- Insert C_ElementValue Trigger
  --  for Translation
  --  and TreeNode
  IF TG_OP = 'INSERT' THEN
      --  Create Translation Row
      INSERT
      INTO C_ElementValue_Trl
        (
          C_ElementValue_Trl_ID, C_ElementValue_ID, AD_Language, AD_Client_ID,
          AD_Org_ID, IsActive, Created,
          CreatedBy, Updated, UpdatedBy,
          Name, IsTranslated
        )
      SELECT get_uuid(), new.C_ElementValue_ID,
        AD_Language, new.AD_Client_ID, new.AD_Org_ID,
        new.IsActive, new.Created, new.CreatedBy,
        new.Updated, new.UpdatedBy, new.Name,
        'N'
      FROM AD_Language
      WHERE IsActive='Y'
        AND IsSystemLanguage='Y'
        AND isonly4format='N';
   end if;
   IF TG_OP = 'INSERT' or TG_OP = 'UPDATE' THEN
    select C_ACCTSCHEMA_ID into v_acctschema from c_element where c_element_id=new.c_element_id;
    select count(*) into v_count from C_VALIDCOMBINATION where ACCOUNT_ID=new.c_elementvalue_id and C_ACCTSCHEMA_ID=v_acctschema;
    if v_count=0 then
        --Create Combination    
        insert into C_VALIDCOMBINATION (C_VALIDCOMBINATION_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, ALIAS, COMBINATION, DESCRIPTION, ISFULLYQUALIFIED, C_ACCTSCHEMA_ID, ACCOUNT_ID)
                    values (get_uuid(),new.AD_CLIENT_ID ,new.AD_ORG_ID ,'Y' ,now() ,new.CREATEDBY ,now() ,new.UPDATEDBY ,new.value ,new.value||'-'||new.name ,new.name ,'Y' ,v_acctschema ,new.c_elementvalue_id);
    else
        update C_VALIDCOMBINATION set UPDATED=now(),UPDATEDBY=new.UPDATEDBY,ALIAS=new.value,COMBINATION=new.value||'-'||new.name, DESCRIPTION=new.name where ACCOUNT_ID=new.c_elementvalue_id and C_ACCTSCHEMA_ID=v_acctschema;
    end if;
  END IF;
  
  -- C_ElementValue update trigger
  --  synchronize name,...
  IF TG_OP = 'UPDATE' THEN
     UPDATE Fact_Acct SET AcctValue=new.VALUE,AcctDescription=new.DESCRIPTION WHERE Account_ID=new.C_ElementValue_ID;
  END IF;
  
  IF TG_OP = 'DELETE' THEN
      select C_ACCTSCHEMA_ID into v_acctschema from c_element where c_element_id=old.c_element_id;
      delete from C_VALIDCOMBINATION where ACCOUNT_ID=old.c_elementvalue_id and C_ACCTSCHEMA_ID=v_acctschema;
  END IF;

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_elementvalue_trg() OWNER TO tad;















/*****************************************************+
Stefan Zimmermann, 10/2010, stefan@zimmermann-software.de



   Restriction Triggers
   These Triggers guarantee a clean Acct-Scema.
   Rules:
   Only one Acct-Schema for one ORG
   Only one Chart of Accounts for one Acct-Schema
   Only one Set of Accounts/Accounting scheme  for
   Products, Business-Partnbers, Caregories, Assets, Banks, 
   Defaults etc... 
*****************************************************/

CREATE OR REPLACE FUNCTION zsfi_AD_Org_AcctSchema_trg()
RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
   v_count numeric;  
BEGIN    
   select count(*) into v_count from AD_Org_AcctSchema where isactive='Y' and ad_org_id=new.ad_org_id and AD_Org_AcctSchema_id!=new.AD_Org_AcctSchema_id;
   if v_count>0  and new.isactive='Y' then
      RAISE EXCEPTION '%', '@zsfi_OnlyOuneAcctSchema@' ;
   end if;
   RETURN new;
END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
alter FUNCTION zsfi_AD_Org_AcctSchema_trg()   OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_element_trg()
RETURNS trigger AS
$BODY$ DECLARE 
   v_count numeric;  
BEGIN    
   select count(*) into v_count from c_element where isactive='Y' and c_acctschema_id=new.c_acctschema_id and c_element_id!=new.c_element_id;
   if v_count>0 and new.isactive='Y' then
      RAISE EXCEPTION '%', '@zsfi_OnlyOneAcctListOnAcctSchema@' ;
   end if;
   RETURN new;
END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
alter FUNCTION  zsfi_element_trg()  OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_acctschemaelement_trg()
RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
   v_count numeric;  
   v_same character varying;
BEGIN    
   select count(*) into v_count from c_acctschema_element where isactive='Y' and c_acctschema_id=new.c_acctschema_id and c_acctschema_element_id!=new.c_acctschema_element_id;
   if v_count>0 and new.isactive='Y' then
      RAISE EXCEPTION '%', '@zsfi_OnlyOneAcctListOnAcctSchema@';
   end if;
   if coalesce(new.c_element_id,'1')!='1' then
       select c_acctschema_id into v_same from c_element where isactive='Y' and c_element_id=new.c_element_id;
       if v_same!=new.c_acctschema_id then
           RAISE EXCEPTION '%', '@zsfi_elementmustbeSameAcctSchema@';
       end if;
   end if;
   RETURN new;
END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
alter FUNCTION  zsfi_acctschemaelement_trg()  OWNER TO tad;



CREATE OR REPLACE FUNCTION zsfi_custacct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active account on costomer
and Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from c_bp_customer_acct where  c_bpartner_id=new.c_bpartner_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and c_bp_customer_acct_id!=new.c_bp_customer_acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_custacct_trg() OWNER TO tad;



CREATE OR REPLACE FUNCTION zsfi_vendacct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active account on vendor
and Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from c_bp_vendor_acct where c_bpartner_id=new.c_bpartner_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and c_bp_vendor_acct_id!=new.c_bp_vendor_acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_vendacct_trg() OWNER TO tad;



CREATE OR REPLACE FUNCTION zsfi_empacct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active account on employee
and Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from c_bp_employee_acct where  c_bpartner_id=new.c_bpartner_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and c_bp_employee_acct_id!=new.c_bp_employee_acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_empacct_trg() OWNER TO tad;



CREATE OR REPLACE FUNCTION zsfi_BP_GroupAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner Groups - Only one active account on 
and Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from c_BP_Group_Acct where  c_bp_group_id=new.c_bp_group_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and c_bp_group_acct_id!=new.c_bp_group_acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_BP_GroupAcct_trg() OWNER TO tad;



CREATE OR REPLACE FUNCTION zsfi_ProductCategoryAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from M_Product_Category_Acct where  M_Product_Category_id=new.M_Product_Category_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and M_Product_Category_Acct_id!=new.M_Product_Category_Acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_ProductCategoryAcct_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION zsfi_MWarehouseAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from M_Warehouse_Acct where  M_Warehouse_id=new.M_Warehouse_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and M_Warehouse_Acct_id!=new.M_Warehouse_Acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_MWarehouseAcct_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_CBankAccountAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from C_BankAccount_Acct where  C_BankAccount_id=new.C_BankAccount_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and C_BankAccount_Acct_id!=new.C_BankAccount_Acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_CBankAccountAcct_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_CCashBookAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from C_CashBook_Acct where  C_CashBook_id=new.C_CashBook_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and C_CashBook_Acct_id!=new.C_CashBook_Acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_CCashBookAcct_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_CTaxAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from C_Tax_Acct where  C_Tax_id=new.C_Tax_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and C_Tax_Acct_id!=new.C_Tax_Acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_CTaxAcct_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_AAssetAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from A_Asset_Acct where  A_Asset_id=new.A_Asset_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and A_Asset_Acct_id!=new.A_Asset_Acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_AAssetAcct_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION zsfi_AAssetGroupAcct_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from A_Asset_Group_Acct where  A_Asset_Group_id=new.A_Asset_Group_id and isactive='Y' 
                                    and c_acctschema_id=new.c_acctschema_id and A_Asset_Group_Acct_id!=new.A_Asset_Group_Acct_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_AAssetGroupAcct_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION zsfi_CAcctSchemaGL_trg()
  RETURNS trigger AS
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
Part of Finance
Business Partner - Only one active accountset on 
 Accounting-Scheme
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from C_AcctSchema_GL where  C_AcctSchema_id=new.C_AcctSchema_id and isactive='Y' 
                                    and C_AcctSchema_GL_id!=new.C_AcctSchema_GL_id;
  if v_count > 0 and new.isactive='Y' then
      new.isactive='N';
      RAISE EXCEPTION '%', '@zsfi_OnlyOneSetInAS@';
  end if;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_CAcctSchemaGL_trg() OWNER TO tad;

/*****************************************************+
Stefan Zimmermann, 10/2010, stefan@zimmermann-software.de



   Implementation of Accounting-Scheme
   
   RESTRICTION-TRIGGERS END

*****************************************************/














/*****************************************************+
Stefan Zimmermann, 10/2010, stefan@zimmermann-software.de



   Implementation of TAXES
   
  




*****************************************************/

-- Function: c_tax_trg()

-- DROP FUNCTION c_tax_trg();

CREATE OR REPLACE FUNCTION c_tax_trg()
  RETURNS trigger AS
$BODY$ DECLARE 

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

/*
 Contributions: Accounts fpr Produkts must be defined.
       All the rubbish tree things removed
*************************************************************************************************************************************************/
    --TYPE RECORD IS REFCURSOR;
  Cur_Defaults RECORD;
  v_count NUMERIC;
  v_AD_Client_ID VARCHAR(32) := new.AD_Client_ID; 
  v_AD_ORG_ID VARCHAR(32) := new.AD_ORG_ID; 
  v_C_Tax_ID VARCHAR(32) := new.C_Tax_ID; 
  v_CreatedBy VARCHAR(32) := new.CreatedBy; 
  v_UpdatedBy VARCHAR(32) := new.UpdatedBy; 
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


IF (TG_OP = 'INSERT') THEN
    -- Tax Account Defaults
    FOR Cur_Defaults IN
      (
      SELECT *
      FROM C_AcctSchema_Default d
      WHERE d.Ad_Client_Id = new.AD_Client_ID
        AND EXISTS
        (
      SELECT 1 
      FROM AD_Org_AcctSchema
      WHERE (AD_IsOrgIncluded(AD_Org_ID, new.AD_ORG_ID, new.AD_Client_ID)<>-1
          OR AD_IsOrgIncluded(new.AD_ORG_ID, AD_Org_ID, new.AD_Client_ID)<>-1)
      AND IsActive = 'Y'
      AND AD_Org_AcctSchema.C_AcctSchema_ID = d.C_AcctSchema_ID
        )
      )
    LOOP
      INSERT
      INTO C_Tax_Acct
        (
          C_Tax_Acct_ID, C_Tax_ID, C_AcctSchema_ID, AD_Client_ID,
          AD_Org_ID, IsActive, Created,
          CreatedBy, Updated, UpdatedBy,
          T_Due_Acct, T_Liability_Acct, T_Credit_Acct,
          T_Receivables_Acct, T_Expense_Acct, t_p_revenue_acct, t_p_expense_acct
        )
        VALUES
        (
          get_uuid(), new.C_Tax_ID, Cur_Defaults.C_AcctSchema_ID, new.AD_Client_ID,
          new.AD_ORG_ID,  'Y', TO_DATE(NOW()),
          new.CreatedBy, TO_DATE(NOW()), new.UpdatedBy,
          Cur_Defaults.T_Due_Acct, Cur_Defaults.T_Liability_Acct, Cur_Defaults.T_Credit_Acct,
          Cur_Defaults.T_Receivables_Acct, Cur_Defaults.T_Expense_Acct,Cur_Defaults.p_revenue_acct,Cur_Defaults.p_Expense_Acct
        );
    END LOOP;
    --  Create Translation Rows   
    
END IF;
  -- Inserting
IF(TG_OP = 'UPDATE') THEN
    UPDATE C_TAX_ACCT SET AD_ORG_ID = new.AD_ORG_ID
    WHERE C_TAX_ID = new.C_TAX_ID;
    
END IF;

  -- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_tax_trg() OWNER TO tad;


SELECT zsse_dropfunction ('zsfi_GetTax');

CREATE OR REPLACE FUNCTION zsfi_GetTax(v_bplocid in character varying, v_product_id in character varying, v_orgid in character varying) RETURNS CHARACTER VARYING
AS
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
Part of Finance
Given Input: The Business-Partner - Location (SO: ShipTo, PO From Loc)
             The Product, The ORG-Id for Acct-Schema
      Returns: Tax-id
Rules: See below 
*****************************************************/
v_Taxreturn      character varying;
v_pcat            character varying;
BEGIN
    -- Load Product-Category 
    select m_product_category_id into v_pcat from m_product where m_product_id=v_product_id;
    -- Default-Tax, wins if no others defined
    select c_tax_id into v_Taxreturn from AD_Org_AcctSchema where ad_org_id=v_orgid and isactive='Y';
    -- Product-Category ,wins if no tax in product and bp
    select coalesce(c_tax_id,v_Taxreturn) into v_Taxreturn from m_product_category where m_product_category_id=v_pcat;
    -- Product ,wins if no tax in  bp
    select coalesce(c_tax_id,v_Taxreturn) into v_Taxreturn from m_product where m_product_id=v_product_id;
    -- Business-Partner-Location, wins always, if defined
    if v_bplocid is not null then
        select coalesce(c_tax_id,v_Taxreturn) into v_Taxreturn from c_bpartner_location where c_bpartner_location_id=v_bplocid;
    end if;
    RETURN  v_Taxreturn;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION zsfi_GetTax(v_invoiceOrOrderID in character varying,v_product_id in character varying)
RETURNS CHARACTER VARYING
AS
$BODY$ DECLARE 
 v_org   character varying;
 v_bploc character varying;
 v_tax varchar;
BEGIN
  if (select count(*) from  c_invoice where c_invoice_id=v_invoiceOrOrderID)>0 then
    select c_bpartner_location_id,ad_org_id into v_bploc,v_org from c_invoice where c_invoice_id=v_invoiceOrOrderID;
  end if;
  if (select count(*) from  c_order where c_order_id=v_invoiceOrOrderID)>0 then
    select c_tax_id,billto_id,ad_org_id into v_tax,v_bploc,v_org  from c_order where c_order_id=v_invoiceOrOrderID;
    if v_tax is not null then
        return v_tax;
    end if;
  end if;
  return zsfi_GetTax(v_bploc,v_product_id,v_org);
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;




/*****************************************************+
Stefan Zimmermann, 1/2011, stefan@zimmermann-software.de



   Get the specific Accounts for each purpose
   
  




*****************************************************/
CREATE OR REPLACE FUNCTION zsfi_GetBPAccount(v_acctType in character varying, v_bpartner_id in character varying, v_acctschema_id  in character varying) RETURNS CHARACTER VARYING
AS
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
Part of Finance SELECT ACCOUNTS FOR Business-Partner Booking
Given Input: 
             If In Bpartner-Accounting-Table is defined, we Take That
             If Bpartner-Group  defined, we take that
             Otherwise: We get the Account from Acct-Schema
             PARAMs
             Account-Type: 1= Receivable (Revenue), 2= Liability (Expense). 3= Writeoff, 4= Material Receipts 
             
             The Business Partner, The  Acct-Schema
      Returns: Account
***************************************************************************************************/
v_bpgroup         character varying;
v_retacct         character varying;
v_tempacct        character varying;
BEGIN
    -- Load BPartner-Category 
    select c_bp_group_id into v_bpgroup from c_bpartner where c_bpartner_id=v_bpartner_id;   
    -- Acct-Schema wins, if no other defined
    select case v_acctType when '1' then c_receivable_acct
                          when '2' then v_liability_acct
                          when '3' then writeoff_acct
                          when '4' then notinvoicedreceipts_acct
                          when '5' then ar_downpayment_acct
          end
    into v_retacct from c_acctschema_default where c_acctschema_id=v_acctschema_id and isactive='Y';  
    -- Category-acct, wins if no account defined in BPartner
    select case v_acctType when '1' then c_receivable_acct
                          when '2' then v_liability_acct
                          when '3' then writeoff_acct
                          when '4' then notinvoicedreceipts_acct
          end
          into v_tempacct from c_bp_group_acct where c_bp_group_id=v_bpgroup and isactive='Y' and c_acctschema_id=v_acctschema_id;    
    if v_tempacct is not null then v_retacct:=v_tempacct; end if;
    -- Business-Partner wins, if defined
    if v_acctType='1' then
        select c_receivable_acct 
          into v_tempacct from c_bp_customer_acct where c_bpartner_id= v_bpartner_id and isactive='Y' and c_acctschema_id=v_acctschema_id;    
    elsif v_acctType='2' then
        select v_liability_acct 
          into v_tempacct from c_bp_vendor_acct where c_bpartner_id= v_bpartner_id and isactive='Y' and c_acctschema_id=v_acctschema_id;    
    end if;
    if v_tempacct is not null then v_retacct:=v_tempacct; end if;
    RETURN  v_retacct;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zsfi_GetPAccountFromTax(v_acctType in character varying, v_tax_id in character varying, v_org_id  in character varying) RETURNS CHARACTER VARYING
AS
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
Part of Finance SELECT ACCOUNTS FOR PRODUCTS Booking - From TAX Line (Used for GROSS Invoice Booking)

      Returns: Account
***************************************************************************************************/

v_retacct         character varying;
v_acctschema_id varchar;
BEGIN
       select c_acctschema_id into v_acctschema_id from ad_org_acctschema where ad_org_id=v_org_id;
       -- Tax-acct wins, if no other defined
       select case v_acctType when '2' then t_p_expense_acct
                              when '1' then t_p_revenue_acct
              end
       into v_retacct from c_tax_acct where c_tax_id=v_tax_id and isactive='Y' and c_acctschema_id=v_acctschema_id;
    RETURN  v_retacct;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zsfi_GetPExpenseAccountFromInvTaxandFirstProduct(v_InvoiceID in character varying, v_tax_id in character varying, v_org_id  in character varying) RETURNS CHARACTER VARYING
AS
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
Part of Finance SELECT ACCOUNTS FOR PRODUCTS Booking - From TAX Line 

Used ONLY for GROSS Invoice Booking
Only applicable for Purchase Invoices. Sales select account direct from tax.
Selects the First Product Line with the Tax given and selects the Expense Account for it
If none or Accounting-Schema-Default found, the Expense Account is taken from the Tax

      Returns: Account
***************************************************************************************************/

v_retacct         character varying;
v_taxacct varchar;
v_acctschema_id varchar;
v_product varchar;
BEGIN
       select c_acctschema_id into v_acctschema_id from ad_org_acctschema where ad_org_id=v_org_id;
       select m_product_id into v_product from c_invoiceline where c_invoice_id=v_InvoiceID and c_tax_id=v_tax_id order by line limit 1;
       -- The TAX-Account wins, if no Product account defined
       v_taxacct:=zsfi_GetPAccountFromTax('2',v_tax_id,v_org_id);
       -- returns Product account or ACCT-Default-Acct. Cannot find Tax account.
       v_retacct:=zsfi_GetPAccount('2',v_product,v_acctschema_id);
       if v_retacct=(select p_expense_acct from c_acctschema_default where c_acctschema_id=v_acctschema_id and isactive='Y') then
           RETURN  v_taxacct;
       else
           return v_retacct;
       end if;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zsfi_GetPAccount(v_acctType in character varying, v_product_id in character varying, v_acctschema_id  in character varying, v_InvoiceLineid in character varying) RETURNS CHARACTER VARYING
AS
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
Part of Finance SELECT ACCOUNTS FOR PRODUCTS Booking
Given Input: 
             If Invoiceline is defined, we assume, that Tax is defined.
             If Tax defined, account may be selected from Tax (Rules below)
             PARAMs
             Account-Type: 1=Revenue, 2= Expense. Corrospondence to Productinfo.java
             Invoiceline
             (gets the the Business-Partner - Location;SO: ShipTo, PO From Loc from Invoice)
             The Product, The  Acct-Schema
      Returns: Account
***************************************************************************************************/
v_Taxid           character varying;
v_bpTaxid         character varying;
v_pcat            character varying;
v_bpartn_loc_id   character varying;
v_retacct         character varying;
v_tempacct        character varying;
BEGIN
    -- Load Product-Category 
    select m_product_category_id into v_pcat from m_product where m_product_id=v_product_id;
    select c_bpartner_location_id into v_bpartn_loc_id from c_invoice where c_invoice_id=(select c_invoice_id from c_invoiceline where c_invoiceline_id=v_InvoiceLineid);
    select c_tax_id into v_bpTaxid from c_bpartner_location where c_bpartner_location_id=v_bpartn_loc_id;
    select c_tax_id into v_Taxid from c_invoiceline where c_invoiceline_id=v_InvoiceLineid;
    -- If no Tax defined
    If v_Taxid is null then
        return zsfi_GetPAccount(v_acctType, v_product_id, v_acctschema_id);
    end if;
    -- Busuness Partner-Tax wins always
    if v_bpTaxid is not null and (
        ((select isrevenueexpensefromproduct from c_tax where c_tax_id=v_bpTaxid)='N' and v_acctType='1') or
        ((select isexpensefromproduct from c_tax where c_tax_id=v_bpTaxid)='N' and v_acctType='2')
        ) then
       select case v_acctType when '2' then t_p_expense_acct 
                              when '1' then t_p_revenue_acct
              end
              into v_retacct from c_tax_acct where c_tax_id=v_bpTaxid and isactive='Y' and c_acctschema_id=v_acctschema_id;
    else
       -- Tax-acct wins, if no other defined
       select case v_acctType when '2' then t_p_expense_acct
                              when '1' then t_p_revenue_acct
              end
       into v_retacct from c_tax_acct where c_tax_id=v_Taxid and isactive='Y' and c_acctschema_id=v_acctschema_id;
       -- If TAX Not Defined - Get from ACCT-Schema-Default
       if v_retacct is null then
          select case v_acctType when '2' then p_expense_acct
                                 when '1' then p_revenue_acct
                 end
          into v_retacct from c_acctschema_default where c_acctschema_id=v_acctschema_id and isactive='Y';  
       end if;
       -- Category-acct, wins if no product defined
       select case v_acctType when '2' then p_expense_acct 
                              when '1' then p_revenue_acct 
              end
              into v_tempacct from m_product_category_acct where m_product_category_id=v_pcat and isactive='Y' and c_acctschema_id=v_acctschema_id;    
       if v_tempacct is not null then v_retacct:=v_tempacct; end if;
       -- Product-acct wins, if defined
       select case v_acctType when '2' then p_expense_acct
                              when '1' then p_revenue_acct 
              end
              into v_tempacct from m_product_acct where m_product_id= v_product_id and isactive='Y' and c_acctschema_id=v_acctschema_id;    
       if v_tempacct is not null then v_retacct:=v_tempacct; end if;
    end if;
    RETURN  v_retacct;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION zsfi_GetPAccount(v_acctType character varying, v_product_id character varying, v_acctschema_id  character varying) RETURNS CHARACTER VARYING
AS
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
Part of Finance      SELECT ACCOUNTS FOR PRODUCTS Booking
Given Input:  Get from Product, Category or Acc-Schema
             
             PARAMs
             Account-Type: 1=Revenue, 2= Expense. Asset = "3";Cost af Goods Sold = "4"; Price Variance (Purchase) = "5";   Price Variance (Sale) = "6";Trade Discount Revenue = "7";Trade Discount Costs  = "8";
                           Corrospondence to Productinfo.java 
             The Product, The  Acct-Schema
             Rules: 
             1. Product, 2. Category, 3. Acct-Schema-Default
      Returns: Account
***************************************************************************************************/

v_pcat            character varying;
v_retacct         character varying;
v_tempacct        character varying;
BEGIN
    -- Load Product-Category 
    select m_product_category_id into v_pcat from m_product where m_product_id=v_product_id;
    -- Acct-Schema wins, if no other defined
    select case v_acctType   when '1' then p_revenue_acct
                             when '2' then p_expense_acct 
                             when '3' then p_asset_acct
                             when '4' then p_cogs_acct
                             when '5' then p_purchasepricevariance_acct
                             when '6' then p_invoicepricevariance_acct 
                             when '7' then p_tradediscountrec_acct 
                             when '8' then p_tradediscountgrant_acct                         
            end  into v_retacct from c_acctschema_default where c_acctschema_id=v_acctschema_id and isactive='Y';  
    

       -- Category-acct, wins if no product defined
       select case v_acctType   when '1' then p_revenue_acct
                             when '2' then p_expense_acct 
                             when '3' then p_asset_acct
                             when '4' then p_cogs_acct
                             when '5' then p_purchasepricevariance_acct
                             when '6' then p_invoicepricevariance_acct 
                             when '7' then p_tradediscountrec_acct 
                             when '8' then p_tradediscountgrant_acct
                        end into v_tempacct from m_product_category_acct where m_product_category_id=v_pcat and isactive='Y' and c_acctschema_id=v_acctschema_id;    
       if v_tempacct is not null then v_retacct:=v_tempacct; end if;
       -- Product-acct wins, if defined
       select case v_acctType   when '1' then p_revenue_acct
                             when '2' then p_expense_acct 
                             when '3' then p_asset_acct
                             when '4' then p_cogs_acct
                             when '5' then p_purchasepricevariance_acct
                             when '6' then p_invoicepricevariance_acct 
                             when '7' then p_tradediscountrec_acct 
                             when '8' then p_tradediscountgrant_acct
                        end into v_tempacct from m_product_acct where m_product_id= v_product_id and isactive='Y' and c_acctschema_id=v_acctschema_id; 
        if v_tempacct is not null then v_retacct:=v_tempacct; end if;
    RETURN  v_retacct;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION zsfi_GetWDAccount(v_acctType character varying, v_invoice_id character varying, v_acctschema_id  character varying) RETURNS CHARACTER VARYING
AS
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
Part of Finance
Given Input: Get Discount or Write-Off Account from Tax or Acct-Schema
             
             PARAMs
             Account-Type: 1=Discount-Granted, 2= Discount-Got = "3"=Writeoff 4=Taxdue(Umsatzsteuer) 5=TaxCredit (Vorsteuer)
                           Corrospondence to Productinfo.java 
             The Tax, The  Acct-Schema
             Rules: 
             1. Tax, 2.  Acct-Schema-Default
      Returns: ValidCombination-ID
***************************************************************************************************/

v_pcat            character varying;
v_retacct         character varying;
v_tempacct        character varying;
v_Tax_id          character varying;
v_count           numeric;
BEGIN 
    -- Load Tax ID 
    select count(distinct c_tax_id) into v_count from c_invoicetax where c_invoice_id=v_invoice_id;
    if v_count=1 then
        select min(c_tax_id) into v_tax_id from c_invoicetax where c_invoice_id=v_invoice_id;
    end if;
    -- Acct-Schema wins, if no other defined
    select case v_acctType   when '1' then ar_discount_acct
                             when '2' then ap_discount_acct
                             when '3' then writeoff_acct     
                             when '4' then t_due_acct 
                             when '5' then t_credit_acct     
            end  into v_retacct from c_acctschema_default where c_acctschema_id=v_acctschema_id and isactive='Y';  
    
    if v_Tax_id is not null then
      -- Tax-acct, wins if defined
      select case v_acctType   when '1' then t_ar_discount_acct
                            when '2' then t_ap_discount_acct 
                            when '3' then t_writeoff_acct
                            when '4' then t_due_acct 
                            when '5' then t_credit_acct    
                        end into v_tempacct from c_tax_acct where c_tax_id=v_tax_id and isactive='Y' and c_acctschema_id=v_acctschema_id;  
      if v_tempacct is not null then v_retacct:=v_tempacct; end if; 
    end if; 
    RETURN  v_retacct;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_GetWDAccount(v_acctType character varying, v_tax_id character varying, v_acctschema_id  character varying)  OWNER TO tad;





/*****************************************************+
Stefan Zimmermann, 1/2011, stefan@zimmermann-software.de



   AUXILLIAR Functions
   
  




*****************************************************/


CREATE OR REPLACE FUNCTION zsfi_GetTaxAmtFromAmt(v_invoice_id character varying, v_amount character varying, v_currency character varying) RETURNS character varying
AS
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
Part of Finance
      Get Tax-Part of Discount or Write-Off Amount given as input            
      Returns:Tax-Amount
***************************************************************************************************/
v_Tax_id          character varying;
v_count           numeric;
v_retamt          numeric;
v_taxrate         numeric;
v_inpamount       numeric;
v_reversetax      character varying;
BEGIN
    v_inpamount:=to_number(v_amount);
    -- Load Tax ID 
    select count(distinct c_tax_id) into v_count from c_invoicetax where c_invoice_id=v_invoice_id;
    if v_count=1 then
        select min(c_tax_id) into v_tax_id from c_invoicetax where c_invoice_id=v_invoice_id;
        select rate,reversecharge into v_taxrate,v_reversetax from c_tax where c_tax_id=v_tax_id;
        if v_reversetax='N' and v_taxrate!=0 then
            v_retamt:=v_inpamount-C_Currency_Round((v_inpamount/(1+(v_taxrate/100))),v_currency,null);
        else
            v_retamt:=0;
        end if;
    end if;    
    RETURN  to_char(v_retamt);
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

ALTER FUNCTION zsfi_GetTaxAmtFromAmt(v_invoice_id character varying, v_amount character varying, v_currency character varying)  OWNER TO tad;














/*****************************************************+
Stefan Zimmermann, 01/2011, stefan@zimmermann-software.de



   Implementation of  Accounting Logic
   
   Internal Consumption

   Purpose: Production 
            Doctype MMP (P+/P-) 
       and  Godds consumption (-)
            Doctype MMP (D-) 
   cancel is not Possible-Same than InOut-Invenory 
   must be kept correct.

*****************************************************/

CREATE OR REPLACE FUNCTION zsfi_postinternalconsumption2gl(p_Record_ID character varying, v_User character varying)
  RETURNS void AS
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
  Part of finance
  Purpose: Manual accounting. Post GL/Journal
  *****************************************************/
  -- General CONSTs
  v_acctshema character varying;
  v_period character varying;
  v_table_id character varying :='800168'; -- m_internal_consumption
  v_ptable_id character varying:='325'; --m_production (is oly a dummy) @TODO: get Posting (p+) otherwise activated. (p-) is triggered through  m_internal_consumption ...  
  v_movetypes character varying;
  v_glcat    character varying :='6DD60A8614B54874B0740C07AC142301';
  v_currency character varying;
  v_docbasetype character varying := 'MMP';
  
  -- Line- Calculation-Vars
  v_amt   numeric;
  v_dramt numeric;
  v_cramt numeric;
  
  -- Actually booked accounts - with description and value
  v_pj_wip_acct character varying;
  v_pj_wip_acct_val character varying;
  v_pj_wip_acct_desc character varying;
  v_w_inventory_acct character varying;
  v_w_inventory_acct_val character varying;
  v_w_inventory_acct_desc character varying;
  v_pj_asset_acct character varying;
  v_pj_asset_acct_val character varying;
  v_pj_asset_acct_desc character varying;
  -- In the FACT
  v_acct character varying;
  v_acct_val  character varying;
  v_acct_desc character varying;
  v_group  character varying;
  -- Internal vars
  v_count numeric;
  v_i numeric;
  v_temp character varying;
  v_temp2 character varying;
  -- mgmt Vars
  v_Message character varying;
  -- Header Vars
  v_Org character varying;
  v_Client character varying;
  v_acctdate DATE;
  v_doc character varying;
  v_movementtype  character varying;
  -- Lines
  v_cur_line RECORD;
  -- CheckSums
  v_checksumDR numeric:=0;
  v_checksumCR numeric:=0;
BEGIN
  -- Load fixed values
  select dateacct, ad_org_id,ad_client_id,documentno,movementtype into v_acctdate,v_Org,v_Client,v_doc,v_movementtype from m_internal_consumption where m_internal_consumption_id=p_Record_ID;
  select c_acctschema_id into v_acctshema from ad_org_acctschema where ad_org_id=v_Org and ad_client_id=v_Client;
  select c_currency_id into v_currency from c_acctschema where c_acctschema_id=v_acctshema;  
  -- Is Accounting activated?
  select count(*) into v_count from c_acctschema_table where C_ACCTSCHEMA_ID=v_acctshema and AD_TABLE_ID=v_table_id and isactive='Y';
  if v_count!=1 then
   return;
  end if;
  -- Is Production + active?
  select count(*) into v_count from c_acctschema_table where C_ACCTSCHEMA_ID=v_acctshema and AD_TABLE_ID=v_ptable_id and isactive='Y';
  if v_count!=1 and v_movementtype='P+' then
     return;
  end if;
  select count(*) into v_count from c_periodcontrol_v where ad_client_id=v_Client and ad_org_id=v_Org and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=v_acctdate and enddate>=v_acctdate;
  -- Tests
  if v_count!=1 then
   RAISE EXCEPTION '%', '@zspr_NoOpenPeriod@' ;
   return;
  end if;
  select c_period_id into v_period from c_periodcontrol_v where ad_client_id=v_Client and ad_org_id=v_Org and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=v_acctdate and enddate>=v_acctdate;
  -- Group the Whole Document
  v_group:=get_uuid();
  -- Load the Lines
  for v_cur_line in (select * from m_internal_consumptionline where m_internal_consumption_id=p_Record_ID)
  LOOP
      -- Get Product Price
      select m_get_product_cost(v_cur_line.m_product_id,v_acctdate,null,v_cur_line.ad_org_id)*v_cur_line.movementqty into v_amt;

     /*****************************************************+
        LOGIC
        P-, D- -> pj_wip_acct:CR       ; w_inventory_acct:DR
        P+     -> w_inventory_acct:CR  ; pj_asset_acct:DR

        Note: pj_asset_acct is really not the asset , it is cost-account.
  
     *****************************************************/ 
      -- Select Accounts
      select pj_wip_acct,pj_asset_acct into v_temp,v_temp2 from c_acctschema_default where ad_org_id=v_Org and isactive='Y' and c_acctschema_id=v_acctshema;
      select ev.c_elementvalue_id,ev.name,ev.value into v_pj_wip_acct, v_pj_wip_acct_desc, v_pj_wip_acct_val from c_elementvalue ev,c_validcombination where ev.c_elementvalue_id=c_validcombination.account_id and c_validcombination.c_validcombination_id=v_temp;
      select ev.c_elementvalue_id,ev.name,ev.value into v_pj_asset_acct, v_pj_asset_acct_desc, v_pj_asset_acct_val from c_elementvalue ev,c_validcombination where ev.c_elementvalue_id=c_validcombination.account_id and c_validcombination.c_validcombination_id=v_temp2;
      -- Get Product Asset Account
      select m_product_category_id into v_temp from m_product where m_product_id=v_cur_line.m_product_id;
      select p_asset_acct into v_temp2 from m_product_category_acct where m_product_category_id=v_temp and c_acctschema_id=v_acctshema;
      if v_temp2 is null then
          -- No Product-Account? - Get Warehouse-Asset-Account
          select m_warehouse_id into v_temp from m_locator where m_locator_id=v_cur_line.m_locator_id;
          select w_inventory_acct into v_temp2 from m_warehouse_acct where m_warehouse_id=v_temp and ad_org_id=v_Org and isactive='Y' and c_acctschema_id=v_acctshema;
      end if;
      -- All accounts selected?
      select ev.c_elementvalue_id,ev.name,ev.value into v_w_inventory_acct, v_w_inventory_acct_desc, v_w_inventory_acct_val from c_elementvalue ev,c_validcombination where ev.c_elementvalue_id=c_validcombination.account_id and c_validcombination.c_validcombination_id=v_temp2;      
      if v_pj_wip_acct is null or v_pj_asset_acct is null or v_w_inventory_acct is null then 
        RAISE EXCEPTION '%', '@zsfi_AccountIsNull@' ;
        return;
      end if;  

      if coalesce(v_amt,0)=0 then 
        RAISE EXCEPTION '%', '@zsfi_AmountIsNull@' ;
        return;
      end if;  
      --
      FOR v_i IN 1..2 LOOP
        -- 1:CR-Account
        -- 2:DR-Account
        if v_movementtype in ('D-','P-') then
           if v_i=1 then
              v_acct:=v_pj_wip_acct;
              v_acct_val:=v_pj_wip_acct_val;
              v_acct_desc:=v_pj_wip_acct_desc;
              v_dramt:=0;
              v_cramt:=v_amt;
           else
              v_acct:=v_w_inventory_acct;
              v_acct_val:=v_w_inventory_acct_val;
              v_acct_desc:=v_w_inventory_acct_desc;
              v_dramt:=v_amt;
              v_cramt:=0;
           end if;
        elsif v_movementtypein ('D+','P+') then
           if v_i=1 then
              v_acct:=v_w_inventory_acct;
              v_acct_val:=v_w_inventory_acct_val;
              v_acct_desc:=v_w_inventory_acct_desc;
              v_dramt:=0;
              v_cramt:=v_amt;
           else
              v_acct:=v_pj_asset_acct;
              v_acct_val:=v_pj_asset_acct_val;
              v_acct_desc:=v_pj_asset_acct_desc;
              v_dramt:=v_amt;
              v_cramt:=0;
           end if;
        else
          RAISE EXCEPTION '%', '@zsfi_IllegalMovementType@' ;
          return;
        end if;  
        -- RAISE NOTICE '%','MT:'||coalesce(v_movementtype,'Ä')||',i:'||v_i||',ACT:'||coalesce(v_acct_desc,'Ä')||'Amt:'||coalesce(v_amt,'-1');
        -- Create the FAct-Acct
        insert into fact_acct(FACT_ACCT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, C_ACCTSCHEMA_ID,
                              ACCOUNT_ID, DATETRX, DATEACCT, C_PERIOD_ID, AD_TABLE_ID, RECORD_ID, GL_CATEGORY_ID, POSTINGTYPE,
                              C_CURRENCY_ID, 
                               AMTSOURCECR,  AMTSOURCEDR, AMTACCTCR, AMTACCTDR, 
                              DESCRIPTION, FACT_ACCT_GROUP_ID, SEQNO, DOCBASETYPE,
                              ACCTVALUE, ACCTDESCRIPTION)
                    values(get_UUID(),v_Client,v_Org,'Y',now(),v_User,now(),v_User,v_acctshema,
                            v_acct,now(),v_acctdate,v_period,v_table_id, v_cur_line.m_internal_consumptionline_id,v_glcat, 'A',
                            v_currency, 
                            v_cramt, v_dramt,v_cramt, v_dramt,
                            substr('I: '||v_doc||' # '||v_cur_line.description,1,255),v_group,v_i,v_docbasetype,
                            v_acct_val,v_acct_desc);

         v_checksumDR :=   v_checksumDR +  v_dramt;
         v_checksumCR :=   v_checksumCR +  v_cramt;
      END LOOP; 
      -- Debit And Credit - Sums must be equal
      if v_checksumDR!=v_checksumCR then
        RAISE EXCEPTION '%', '@zsfi_ManualAcctNotBalanced@ -  CSDR: '||to_char(v_checksumDR)||':CSCR:'||to_char(v_checksumCR)||':NET:'||to_char(v_netamt)||':TAX:'||to_char(v_taxamt)||':GR:'||to_char(v_grossamt)||'Text:'||v_cur_line.description;
        return;
      end if;  
  -- Lines
  END LOOP;
  -- Finishing-Update  Header and Lines
  --glstatus OP=open, CA=cancelled, PO=posted
  update m_internal_consumption set posted='Y',updated=now(),updatedby=v_User where m_internal_consumption_id=p_Record_ID;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zsfi_postinternalconsumption2gl(p_Record_ID character varying, v_User character varying) OWNER TO tad;

/*****************************************************+
Stefan Zimmermann, 1/2011, stefan@zimmermann-software.de



   Implementation of Cash-Discounts
   




*****************************************************/



CREATE OR REPLACE FUNCTION zsfi_getcashdiscount(p_invoice_id character varying, p_amount numeric,p_currency  character varying,p_date character varying) RETURNS numeric
AS
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
Part of Finance
      Returns:Chash-Discount Amount
***************************************************************************************************/
v_ptid            character varying;
v_rate            numeric;
v_reversetax      character varying;
v_invdate         timestamp without time zone;
v_bstdate         timestamp without time zone;
BEGIN
    select c_paymentterm_id,dateinvoiced into v_ptid,v_invdate from c_invoice where c_invoice_id=p_invoice_id;
    v_bstdate:=to_timestamp(p_date,'dd-mm-yyyy');
    --,'dd.mm.yyyy-hh24:mi:ss'
    select percentage into v_rate from zsfi_discount where c_paymentterm_id = v_ptid and netdays >= to_number(v_bstdate-v_invdate) order by netdays limit 1;
    RETURN coalesce(C_Currency_Round(p_amount*(v_rate/100),p_currency,null),0);
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

ALTER FUNCTION zsfi_getcashdiscount(p_invoice_id character varying, p_amount numeric,p_currency  character varying,p_date character varying)  OWNER TO tad;




CREATE OR REPLACE FUNCTION zsfi_paymentmonitor(p_settlement_id character varying) returns void
AS
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
Part of Finance
      Reimplementation of the Old Payment Monitor
      Fix Issue 448: Discounts have a cancel_id on creation, bit are still open (Bankstatement not Processed)
***************************************************************************************************/
v_cur             RECORD;


v_rate            numeric;
v_reversetax      character varying;
v_order_id 		  character varying;
v_invdate         timestamp without time zone;
v_bstdate         timestamp without time zone;
BEGIN
    for v_cur in (SELECT DISTINCT(C_DEBT_PAYMENT.C_INVOICE_ID) AS c_invoice_id FROM C_DEBT_PAYMENT WHERE  C_SETTLEMENT_CANCEL_ID= p_settlement_id OR C_SETTLEMENT_GENERATE_ID= p_settlement_id)
    LOOP
      UPDATE C_INVOICE SET  OUTSTANDINGAMT=Q.OUTSTANDINGAMT,TOTALPAID=Q.TOTALPAID,WRITEOFFAMT=Q.WRITEOFFAMT,DISCOUNTAMT=Q.DISCOUNTAMT,ISPAID=Q.ISPAID, transactiondate=trunc(now()) FROM
                (SELECT SUM(OPENAMT) AS OUTSTANDINGAMT,SUM(PAIDAMT) AS TOTALPAID,SUM(WRITEOFFAMT) AS WRITEOFFAMT, SUM(DISCOUNTAMT) AS DISCOUNTAMT, MAX(ISPAID) AS ISPAID FROM 
                        (SELECT 0 AS OPENAMT,SUM(AMOUNT) AS PAIDAMT,0 AS WRITEOFFAMT, 0 AS DISCOUNTAMT, ' ' AS ISPAID FROM C_DEBT_PAYMENT WHERE CANCEL_PROCESSED='Y' 
                                     AND ISPAID='Y' AND ISVALID='Y' AND C_INVOICE_ID = v_cur.C_INVOICE_ID
                         UNION ALL
                         SELECT SUM(AMOUNT) AS OPENAMT,0  AS PAIDAMT,0 AS WRITEOFFAMT, 0 AS DISCOUNTAMT, ' ' AS ISPAID FROM C_DEBT_PAYMENT WHERE CANCEL_PROCESSED='N'  AND ISVALID='Y'
                                AND  C_INVOICE_ID = v_cur.C_INVOICE_ID and (c_settlement_cancel_id is null or discountamt>0)
                         UNION ALL
                         SELECT 0 AS OPENAMT,0  AS PAIDAMT,SUM(WRITEOFFAMT) AS WRITEOFFAMT, SUM(DISCOUNTAMT) AS DISCOUNTAMT, ' ' AS ISPAID  FROM C_DEBT_PAYMENT WHERE CANCEL_PROCESSED='Y' 
                                 AND ISPAID='N' AND ISVALID='Y' AND C_INVOICE_ID =  v_cur.C_INVOICE_ID
                          UNION ALL
                         SELECT 0 AS OPENAMT,0  AS PAIDAMT,0 AS WRITEOFFAMT, 0 AS DISCOUNTAMT, MIN(CANCEL_PROCESSED) AS ISPAID  FROM C_DEBT_PAYMENT WHERE  C_INVOICE_ID =  v_cur.C_INVOICE_ID
                         ) A
                 ) Q
        WHERE C_INVOICE_ID=v_cur.C_INVOICE_ID;
		select c_order_id into v_order_id from c_invoice where c_invoice.c_invoice_id=v_cur.c_invoice_id;
		update c_order set transactiondate=trunc(now()) where c_order.c_order_id = v_order_id;
		update c_order set totalpaid = (select coalesce(SUM(c_invoice.totalpaid),0) from c_invoice where c_invoice.c_order_id=v_order_id) where c_order.c_order_id = v_order_id;
    END LOOP;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_DropView ('fact_acct_view');

create or replace view fact_acct_view as
select  fact_acct.fact_acct_id as fact_acct_view_id,
                fact_acct.ad_client_id,
                fact_acct.ad_org_id,
                fact_acct.isactive,
                fact_acct.created,
                fact_acct.createdby,
                fact_acct.updated,
                fact_acct.updatedby,
                fact_acct.c_acctschema_id,
                fact_acct.account_id,
                fact_acct.datetrx,
                fact_acct.dateacct,
                fact_acct.c_period_id,
                fact_acct.ad_table_id,
                fact_acct.record_id,
                fact_acct.line_id,
                fact_acct.gl_category_id,
                fact_acct.c_tax_id,
                fact_acct.m_locator_id,
                fact_acct.postingtype,
                fact_acct.c_currency_id,
                fact_acct.amtsourcedr,
                fact_acct.amtsourcecr,
                fact_acct.amtacctdr,
                fact_acct.amtacctcr,
                fact_acct.c_uom_id,
                fact_acct.qty,
                fact_acct.m_product_id,                 
                fact_acct.c_bpartner_id,
                fact_acct.ad_orgtrx_id,
                fact_acct.c_locfrom_id,
                fact_acct.c_locto_id,
                fact_acct.c_salesregion_id,
                fact_acct.c_project_id,
                fact_acct.c_campaign_id,
                fact_acct.c_activity_id,
                fact_acct.user1_id,
                fact_acct.user2_id,
                fact_acct.description,
                fact_acct.a_asset_id,
                fact_acct.fact_acct_group_id,
                fact_acct.seqno,
                fact_acct.factaccttype,
                fact_acct.docbasetype,
                fact_acct.acctvalue,
                fact_acct.acctdescription,
                fact_acct.record_id2,
                fact_acct.c_withholding_id,             
                fact_acct.c_doctype_id,
                fact_acct.uidnumber
from fact_acct
union -- 9150 - Turnover - Statistical Account
select  '32E74132DF90466C8E35592E480AF523' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                'ED3D722029254A178FADAA77FCCFFB4C'  as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9150' as acctvalue,
                'Faktuirierter Umsatz' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union -- 9151 - Backorder - Statistical Account
select  '2B2F6E2DEC0B4656A7703A6432862402' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                'E2622C721BE44A8AAA7453231152F56B'  as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9151' as acctvalue,
                'Noch nicht fakturierter Umsatz' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  '2D4A8B552A9F497989D109F021EB6174' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                'ED3D722029254A178FADAF77FCCFFB4C'  as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9152' as acctvalue,
                'Aufträge' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  '9FA76AAA35024BF98C231BEBEEF0E4D1' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                 '259C9D8DEF014B378F6F2815FAD5C62E' as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9153' as acctvalue,
                'Angebote' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  '1EDECA899B26455FB51BD83F22C1D819' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                 'BD3E518F00814221920C6229F6D22C95' as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9154' as acctvalue,
                'Verkaufsprognose' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  '2331E238DEE64A0696AB474D39827A19' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                '10DDDC12DC8447B79751C7AC6BB89293' as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9155' as acctvalue,
                'Forderungen' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  'DF5D9801187145CBAA7ED40453043875' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                'AA574CAD350247CE918559B162FC8F3E' as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9156' as acctvalue,
                'Verbindlichkeiten' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  '24D16D935CB749FBA10DBF8195F763BD' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                '89AF947DBC61434DA7D7F3E050839C01' as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9157' as acctvalue,
                'Fakturierter Umsatz Runrate' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  'AC55F0F34BF9409CB6A7467107EC2A38' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                'BCEE1A6C65D44DDFB5F792CD9C1F0ABB' as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9158' as acctvalue,
                'Noch nicht fakturierter Umsatz Runrate' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id
union
select  'EC98C5B9421B44E6B4690E500F0B6693' as fact_acct_view_id,
                ad_org.ad_client_id,
                ad_org.ad_org_id,
                ad_org.isactive,
                ad_org.created,
                ad_org.createdby,
                ad_org.updated,
                ad_org.updatedby,
                ad_org_acctschema.c_acctschema_id,
                '71A1A23C9B7A41528BDC66FDF9BF4C43' as account_id,
                null as datetrx,
                now() as dateacct,
                null as c_period_id,
                null as ad_table_id,
                null as record_id,
                null as line_id,
                null as gl_category_id,
                null as c_tax_id,
                null as m_locator_id,
                null as postingtype,
                null as c_currency_id,
                null as amtsourcedr,
                null as amtsourcecr,
                0 as amtacctdr,
                0 as amtacctcr,
                null as c_uom_id,
                null as qty,
                null as m_product_id,                   
                null as c_bpartner_id,
                null as ad_orgtrx_id,
                null as c_locfrom_id,
                null as c_locto_id,
                null as c_salesregion_id,
                null as c_project_id,
                null as c_campaign_id,
                null as c_activity_id,
                null as user1_id,
                null as user2_id,
                null as description,
                null as a_asset_id,
                null as fact_acct_group_id,
                null as seqno,
                null as factaccttype,
                null as docbasetype,
                '9159' as acctvalue,
                'Auftraege Runrate' as acctdescription,
                null as record_id2,
                null as c_withholding_id,               
                null as c_doctype_id,
                null as uidnumber
from 
        ad_org, ad_org_acctschema
where 
        ad_org.ad_org_id = ad_org_acctschema.ad_org_id;

select zsse_DropView ('c_debt_payment_v');

CREATE OR REPLACE VIEW c_debt_payment_v AS 
 SELECT c_debt_payment.c_debt_payment_id,
	c_debt_payment.ad_client_id,
	c_debt_payment.ad_org_id,
	c_debt_payment.isactive,
	c_debt_payment.created,
	c_debt_payment.createdby,
	c_debt_payment.updated,
	c_debt_payment.updatedby,
	c_debt_payment.isreceipt,
	c_debt_payment.c_settlement_cancel_id,
	c_debt_payment.c_settlement_generate_id,
	c_debt_payment.description,
	c_debt_payment.c_invoice_id,
	c_debt_payment.c_bpartner_id,
	c_debt_payment.c_currency_id,
	c_debt_payment.c_cashline_id,
	c_debt_payment.c_bankaccount_id,
	c_debt_payment.c_cashbook_id,
	c_debt_payment.paymentrule,
	c_debt_payment.ispaid,
	c_debt_payment.dateplanned,
	c_debt_payment.ismanual,
	c_debt_payment.isvalid,
	c_debt_payment.c_bankstatementline_id,
	c_debt_payment.changesettlementcancel,
	c_debt_payment.cancel_processed,
	c_debt_payment.generate_processed,
	c_debt_payment.c_withholding_id,
	c_debt_payment.withholdingamount,
CASE c_debt_payment.isreceipt
    WHEN 'Y'::bpchar THEN c_debt_payment.amount
    ELSE c_debt_payment.amount * (-1)::numeric
END AS amount, 
CASE c_debt_payment.isreceipt
    WHEN 'Y'::bpchar THEN c_debt_payment.writeoffamt
    ELSE c_debt_payment.writeoffamt * (-1)::numeric
END AS writeoffamt, 
CASE c_debt_payment.isreceipt
    WHEN 'Y'::bpchar THEN c_debt_payment.discountamt
    ELSE c_debt_payment.discountamt * (-1)::numeric
END AS discountamt, 
CASE c_debt_payment.isreceipt
    WHEN 'Y'::bpchar THEN 1
    ELSE (-1)
END AS multiplierap, 
CASE
    WHEN c_debt_payment.c_invoice_id IS NOT NULL THEN c_invoice.dateinvoiced
    WHEN c_debt_payment.c_settlement_generate_id IS NOT NULL THEN c_settlement.datetrx
    ELSE to_date(now())
END AS docdate, c_debt_payment.glitemamt, c_debt_payment.c_order_id, c_debt_payment.status,
	c_debt_payment.isapproved
FROM c_debt_payment
LEFT JOIN c_invoice ON c_debt_payment.c_invoice_id::text = c_invoice.c_invoice_id::text
LEFT JOIN c_settlement ON c_debt_payment.c_settlement_generate_id::text = c_settlement.c_settlement_id::text;


CREATE OR REPLACE FUNCTION c_period_trg2() RETURNS trigger
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
* Contributor(s): Stefan Zimmermann, 02/2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************
    */
    v_count numeric;
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    IF TG_OP = 'DELETE' or TG_OP = 'UPDATE'  THEN 
        select count(*) into v_count from c_periodcontrol where c_period_id=old.c_period_id and periodstatus!='N';
        if v_count>0 then
            if  TG_OP = 'UPDATE'  then
                    if (old.name!=new.name or old.periodno!=new.periodno  or old.c_year_id!=new.c_year_id or old.periodtype!=new.periodtype or old.startdate!=new.startdate) then
                              raise exception '%', '@cannotdeleteUsedperiods@';
                    end if;
                    if (old.enddate!=new.enddate ) then
                            if new.enddate<old.enddate then
                                    select count(*)  into v_count from fact_acct where c_period_id=old.c_period_id and dateacct between new.enddate and old.enddate;
                                     if v_count>0 then
                                             raise exception '%', '@cannotdeleteUsedperiods@';
                                     end if;
                            else
                                    raise exception '%', '@cannotdeleteUsedperiods@';
                            end if;
                    end if;          
            else --delete
                    raise exception '%', '@cannotdeleteUsedperiods@';
            end if;
        end if;
    END IF;
    if  TG_OP = 'UPDATE'  or TG_OP = 'INSERT'  then
            if (select count(*) from c_period where c_year_id=new.c_year_id and c_period_id!=new.c_period_id and (new.startdate between startdate and enddate or new.enddate between startdate and enddate) and periodtype='S')>0 
                 and new.periodtype='S' then
                 raise exception '%', '@noSecondStdperiod@';
             end if; 
    end if;
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;

select zsse_droptrigger('c_period_trg2','c_period');

CREATE TRIGGER c_period_trg2
  BEFORE INSERT OR UPDATE OR DELETE
  ON c_period
  FOR EACH ROW
  EXECUTE PROCEDURE c_period_trg2();

  
 CREATE OR REPLACE FUNCTION c_periodcontrol_log_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
********************************************************************************************************************************************************/
    v_count numeric;
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    IF TG_OP = 'DELETE'  THEN 
        if old.processed='Y' then
            raise exception '%', '@cannotdeleteUsedperiods@';
        end if;
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

select zsse_droptrigger('c_periodcontrol_log_trg','c_periodcontrol_log');

CREATE TRIGGER c_periodcontrol_log_trg
  BEFORE  DELETE
  ON c_periodcontrol_log
  FOR EACH ROW
  EXECUTE PROCEDURE c_periodcontrol_log_trg();

  
  
CREATE OR REPLACE FUNCTION zsfi_fact_error_log_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
-- RESET of ACCOUNTING-ERRORS
    v_sql varchar;       
BEGIN
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    IF TG_OP = 'DELETE' THEN 
        v_sql:='update '||old.tablename||' set posted='||chr(39)||'N'||chr(39)||' where posted='||chr(39)||'E'||chr(39)||' and '||old.tablename||'_id='||chr(39)||old.sourceid||chr(39);
        EXECUTE(v_sql);
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;

select zsse_droptrigger('zsfi_fact_error_log_trg','zsfi_fact_error_log');

CREATE TRIGGER zsfi_fact_error_log_trg
  BEFORE DELETE
  ON zsfi_fact_error_log
  FOR EACH ROW
  EXECUTE PROCEDURE zsfi_fact_error_log_trg();
  
  
  
  
  
  
/**************************************************************************************************


Foreign Currency Functions


***************************************************************************************************/
  
CREATE OR REPLACE FUNCTION c_currency_rate(p_curfrom_id character varying, p_curto_id character varying, p_convdate timestamp without time zone, p_ratetype character varying, p_client_id character varying, p_org_id character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/*************************************************************************
* The contents of this file are subject to the Compiere Public
* License 1.1 ("License"); You may not use this file except in
* compliance with the License. You may obtain a copy of the License in
* the legal folder of your Openbravo installation.
* Software distributed under the License is distributed on an
* "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
* implied. See the License for the specific language governing rights
* and limitations under the License.
* The Original Code is  Compiere  ERP &  Business Solution
* The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
* Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
* parts created by ComPiere are Copyright (C) ComPiere, Inc.;
* All Rights Reserved.
* Contributor(s): Openbravo SL
* Contributions are Copyright (C) 2001-2009 Openbravo, S.L.
*
* Specifically, this derivative work is based upon the following Compiere
* file and version.
*************************************************************************
* $Id: C_Currency_Rate.sql,v 1.5 2003/03/17 20:32:24 jjanke Exp $
***
* Title: Return Conversion Rate
* Description:
*  from CurrencyFrom_ID to CurrencyTo_ID
*  Returns NULL, if rate not found
* Test
*  SELECT C_Currency_Rate(116, 100, null, null) FROM DUAL; => .647169
************************************************************************/
  -- Currency From variables
  v_cf_IsEuro      char(1);
  -- Triangle
  v_CurrencyFrom VARCHAR(32);
  v_CurrencyTo   VARCHAR(32);
  v_CurrencyEuro VARCHAR(32);
  --
  v_ConvDate TIMESTAMP := TO_DATE(NOW());
  v_RateType VARCHAR(60) := 'S';
  v_Rate     NUMERIC;

  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_ClientName VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_OrgName VARCHAR(2000):=''; --OBTG:VARCHAR2--
  CUR_Rate RECORD;
BEGIN
  -- No Conversion
  IF(p_CurFrom_ID = p_CurTo_ID) THEN
    RETURN 1;
  END IF;
   -- Flexible Rates
  v_CurrencyFrom := p_CurFrom_ID;
  v_CurrencyTo := p_CurTo_ID;
  -- Default Parameter
  IF(p_ConvDate IS NOT NULL) THEN
    v_ConvDate := p_ConvDate;
  END IF;
  IF(p_RateType IS NOT NULL) THEN
    v_RateType := p_RateType;
  END IF;
  IF (v_CurrencyFrom IS NULL OR v_CurrencyTo IS NULL OR v_ConvDate IS NULL) THEN
      RETURN NULL;
  end if;
  
  -- Get Rate
  --TYPE RECORD IS REFCURSOR;
    FOR CUR_Rate IN
      (SELECT MultiplyRate
      FROM C_Conversion_Rate
      WHERE C_Currency_ID = v_CurrencyFrom
        AND C_Currency_ID_To = v_CurrencyTo
        AND ConversionRateType = v_RateType
        AND v_ConvDate BETWEEN ValidFrom AND ValidTo
        AND AD_Org_ID IN ('0', p_Org_ID)
        AND IsActive = 'Y'
      ORDER BY AD_Client_ID DESC,
        AD_Org_ID DESC,
        ValidFrom DESC
      )
    LOOP
      v_Rate := CUR_Rate.MultiplyRate;
      EXIT; -- only first
    END LOOP;
  -- Not found - Change from/to and take Kehrwert ....
  IF(v_Rate IS NULL) THEN
    FOR CUR_Rate IN
      (SELECT 1/MultiplyRate as MultiplyRate
      FROM C_Conversion_Rate
      WHERE C_Currency_ID = v_CurrencyTo
        AND C_Currency_ID_To = v_CurrencyFrom
        AND ConversionRateType = v_RateType
        AND v_ConvDate BETWEEN ValidFrom AND ValidTo
        AND AD_Org_ID IN ('0', p_Org_ID)
        AND IsActive = 'Y'
      ORDER BY AD_Client_ID DESC,
        AD_Org_ID DESC,
        ValidFrom DESC
      )
    LOOP
      v_Rate := CUR_Rate.MultiplyRate;
      EXIT; -- only first
    END LOOP;
  END IF;
   -- Not found - try conversion via EUR for 2 non €-Currencys...
  IF(v_Rate IS NULL) THEN
    FOR CUR_Rate IN
        (SELECT (1/a.MultiplyRate)*b.MultiplyRate AS MultiplyRate
        FROM C_Conversion_Rate a, C_Conversion_Rate b
        WHERE a.ValidFrom = b.ValidFrom
        AND a.C_Currency_ID = '102'
        AND a.C_Currency_ID_To = v_CurrencyFrom
        AND b.C_Currency_ID = '102'
        AND b.C_Currency_ID_To = v_CurrencyTo
        AND a.ConversionRateType = 'S'
        AND b.ConversionRateType = 'S'
        AND v_ConvDate BETWEEN a.ValidFrom AND a.ValidTo
        AND a.AD_Org_ID IN ('0', p_Org_ID)
        AND b.AD_Org_ID IN ('0', p_Org_ID)
        AND b.IsActive = 'Y'
        AND b.IsActive = 'Y'
        ORDER BY a.AD_Client_ID DESC,
        a.AD_Org_ID DESC,
        a.ValidFrom DESC)
    LOOP
        v_Rate := CUR_Rate.MultiplyRate;
        EXIT; -- only first
    END LOOP;
  END IF;
  if (v_Rate IS NULL) THEN
      v_Message:='@NoConversionRate@' || ' ' || C_CURRENCY_ISOSYM(v_CurrencyFrom) || ' '
        || '@to@' || ' ' || C_CURRENCY_ISOSYM(v_CurrencyTo) || ' ' || '@ForDate@' || ' ''' || TO_CHAR(v_ConvDate)
        || ''', ' || '@Client@' || ' ''' || v_ClientName || ''' ' || '@And@' || ' ' || '@ACCS_AD_ORG_ID_D@' || ' ''' || v_OrgName || '''.';
      RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
   END IF;
  -- Currency From was EMU
  RETURN v_Rate;
EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%',SQLERRM ;
  RAISE EXCEPTION '%', SQLERRM;
END ; $_$;
 
  
  
  
CREATE OR REPLACE FUNCTION c_currency_convert(p_amount numeric, p_curfrom_id character varying, p_curto_id character varying, p_convdate timestamp without time zone, p_ratetype character varying, p_client_id character varying, p_org_id character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/*************************************************************************
* The contents of this file are subject to the Compiere Public
* License 1.1 ("License"); You may not use this file except in
* compliance with the License. You may obtain a copy of the License in
* the legal folder of your Openbravo installation.
* Software distributed under the License is distributed on an
* "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
* implied. See the License for the specific language governing rights
* and limitations under the License.
* The Original Code is  Compiere  ERP &  Business Solution
* The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
* Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
* parts created by ComPiere are Copyright (C) ComPiere, Inc.;
* All Rights Reserved.
* Contributor(s): Openbravo SL
* Contributions are Copyright (C) 2001-2009 Openbravo, S.L.
*
* Specifically, this derivative work is based upon the following Compiere
* file and version.
*************************************************************************
* $Id: C_Currency_Convert.sql,v 1.8 2003/03/17 20:32:24 jjanke Exp $
***
* Title: Convert Amount (using IDs)
* Description:
*  from CurrencyFrom_ID to CurrencyTo_ID
*  Returns NULL, if conversion not found
*  Standard Rounding
* Test:
*  SELECT C_Currency_Convert(100,116,100,null,null) FROM DUAL => 64.72
************************************************************************/
  v_Rate NUMERIC;
BEGIN
  -- Return Amount
  IF(p_Amount=0 OR p_CurFrom_ID=p_CurTo_ID) THEN
    RETURN p_Amount;
  END IF;
  -- Get Rate
  v_Rate:=C_Currency_Rate(p_CurFrom_ID, p_CurTo_ID, p_ConvDate, p_RateType, p_Client_ID, p_Org_ID) ;
  IF(v_Rate IS NULL) THEN
    RETURN NULL;
  END IF;
  -- Standard Precision
  RETURN C_Currency_Round(p_Amount * v_Rate, p_CurTo_ID, null) ;
EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%',SQLERRM ;
  RAISE EXCEPTION '%', SQLERRM;
END ; $_$;


CREATE OR REPLACE FUNCTION c_conversion_rate_trg2() RETURNS trigger LANGUAGE plpgsql
AS $_$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann
* 
****************************************************************************************************************************************************/
  v_Count NUMERIC;
       
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


     --check for repeated dates
   select count(*)
    into v_Count
    from c_Conversion_Rate r1,
         c_Conversion_Rate r2
   where trunc(r1.VALIDFROM) = trunc(r2.ValidFrom)
    and r1.C_CURRENCY_ID = r2.C_Currency_ID
    and r1.C_Currency_ID_To = r2.C_Currency_ID_To
    and r1.c_Conversion_Rate_ID != r2.c_Conversion_Rate_ID
    and r1.ad_client_id = r2.ad_client_id;

   if v_Count > 0 then
     RAISE EXCEPTION '%', 'There are different conversion rates with same dates'; --OBTG:-20504--
   end if;



IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END;
$_$;




CREATE OR REPLACE FUNCTION c_acctschema_trg() RETURNS trigger
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
* Contributor(s): Stefan Zimmermann
* 
****************************************************************************************************************************************************/
  cur_tables RECORD;
  v_AcctSchema_Table_ID VARCHAR(32); --OBTG:VARCHAR2--
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  FOR cur_tables IN
    (
    SELECT AD_Table.AD_Table_ID as id,
      (AD_Table.Name)           as name
    FROM AD_Table
    WHERE EXISTS
      (
      SELECT *
      FROM AD_Column c
      WHERE AD_Table.AD_Table_ID=c.AD_Table_ID
        AND c.ColumnName='Posted'
      )
      AND AD_Table.isActive='Y'
    )
  LOOP
    SELECT * INTO  v_AcctSchema_Table_ID FROM AD_Sequence_Next('C_AcctSchema_Table', new.AD_ORG_ID) ;
    INSERT
    INTO C_ACCTSCHEMA_TABLE
      (
        UPDATEDBY, UPDATED, ISACTIVE,
        CREATEDBY, CREATED, C_ACCTSCHEMA_TABLE_ID,
        C_ACCTSCHEMA_ID, AD_TABLE_ID, AD_ORG_ID,
        AD_CLIENT_ID
      )
      VALUES
      (
        new.UPDATEDBY, TO_DATE(NOW()), 'N',
        new.CREATEDBY, TO_DATE(NOW()), v_AcctSchema_Table_ID,
        new.C_ACCTSCHEMA_ID, cur_tables.id, new.AD_ORG_ID,
        new.AD_CLIENT_ID
      )
      ;
  END LOOP;
  
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


SELECT zsse_dropfunction ('zspr_bwaheader_copy'); 
CREATE OR REPLACE FUNCTION zspr_bwaheader_copy (
  p_pinstance_id  VARCHAR  -- source to copy from
 )
RETURNS VARCHAR -- 'SUCCESS'
AS $_$
-- SELECT zspr_bwaheader_copy('7E29B8CED9B34DA1A9879750BB728AFA');  --> neue BWA-Auswertung generieren, GuV
-- delete from zspr_bwaprefacct WHERE createdby = 'tad';  
-- delete from zspr_bwaprefs WHERE createdby = 'tad'; -- 20
-- delete from zspr_bwaheader WHERE createdby = 'tad'; -- 1

-- DELETE from zspr_bwaprefacct where trunc(updated) = to_date('18-08-2014', 'dd-mm-yyyy'); -- 338
-- DELETE from zspr_bwaprefs where trunc(updated) = to_date('18-08-2014', 'dd-mm-yyyy'); -- 22
-- DELETE from zspr_bwaheader where trunc(updated) = to_date('18-08-2014', 'dd-mm-yyyy'); -- 1
DECLARE
  Cur_Parameter           RECORD;
  v_message               VARCHAR := '';
  v_now                   TIMESTAMP := now();
  v_src_bwa_id            VARCHAR;
  v_new_bwa_id            VARCHAR;
  v_zspr_bwaprefs_id      VARCHAR;

  v_Record_ID             VARCHAR;
  v_user_id               VARCHAR;
  v_new_name              VARCHAR;
  v_link                  VARCHAR;

 -- record buffer declaration
  v_zspr_bwaheader        zspr_bwaheader%rowtype;
  v_zspr_bwaprefs         zspr_bwaprefs%rowtype;
  v_zspr_bwaprefacct      zspr_bwaprefacct%rowtype;
  v_newparent varchar;
BEGIN

  BEGIN
    IF(p_pinstance_id IS NOT NULL) THEN
      PERFORM ad_update_pinstance(p_pinstance_id, NULL, 'Y', NULL, NULL) ; -- 'Y'=processing
      SELECT pi.Record_ID, pi.ad_User_ID
      INTO v_Record_ID, v_user_id
      FROM ad_pinstance pi WHERE pi.ad_PInstance_ID = p_pinstance_id;

      IF (v_Record_ID IS NULL) then
        RAISE NOTICE '%','Entry for PInstance not found - Using parameter &1=''' || p_pinstance_id || ''' instead';
        v_src_bwa_id := p_pinstance_id;
        v_user_id     := CURRENT_USER;
        v_new_name    := '<SQL-test>';
      ELSE
        -- Get Parameters
        v_message := 'ReadingParameters';
        FOR Cur_Parameter IN
          (SELECT para.parametername, para.p_string
           FROM AD_PInstance pi, AD_PInstance_Para para
           WHERE 1=1
            AND pi.AD_PInstance_ID = para.AD_PInstance_ID
            AND pi.AD_PInstance_ID = p_pinstance_id
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('name') ) THEN -- durch Dialog-Eingabe
            v_new_name := Cur_Parameter.p_string;
          END IF;
        END LOOP; -- Get Parameter

        RAISE NOTICE '%','Updating PInstance - Processing ' || p_pinstance_id;
        v_src_bwa_id := v_Record_ID;
      END IF;
    END IF;
 -- v_user_id     := CURRENT_USER; -- ?? debug test

 -- plausi
    IF ( isEmpty(p_pinstance_id) ) THEN
      RAISE EXCEPTION '%', 'SQL-PROC zspr_bwaheader_copy: '|| '@InvalidArguments@'|| ' p_pinstance_id '|| COALESCE(p_pinstance_id, '') ; -- GOTO EXCEPTION
    END IF;
    IF ( isEmpty(v_src_bwa_id) ) THEN
      RAISE EXCEPTION '%', 'SQL-PROC zspr_bwaheader_copy: '|| '@InvalidArguments@'|| ' v_src_bwa_id= '|| COALESCE(v_src_bwa_id, ''); -- GOTO EXCEPTION
    END IF;
    IF ( isEmpty(v_new_name) ) THEN
      RAISE EXCEPTION '%', 'SQL-PROC zspr_bwaheader_copy: '||'@InvalidArguments@' || ' new_Name' || COALESCE(v_new_name, ''); -- GOTO EXCEPTION
    END IF;

 -- part 1/4: BWA_header
    v_new_bwa_id := get_uuid();
 -- v_new_bwa_id := 'BWA_copied'; -- debug-test
    SELECT * INTO v_zspr_bwaheader FROM zspr_bwaheader WHERE zspr_bwaheader_id = v_src_bwa_id; -- read template into rowtype-buffer
    IF isEmpty(v_zspr_bwaheader.zspr_bwaheader_id) THEN
      RAISE EXCEPTION '%', '@zspr_bwaheader_NotFound@'; -- GOTO EXCEPTION
    END IF;

   -- set new values before insert
    v_zspr_bwaheader.zspr_bwaheader_id := v_new_bwa_id;
    v_zspr_bwaheader.created := v_now;
    v_zspr_bwaheader.createdby := v_user_id;
    v_zspr_bwaheader.updated := v_now;
    v_zspr_bwaheader.updatedby := v_user_id;
    v_zspr_bwaheader.name := v_new_name; -- unique name required
    INSERT INTO zspr_bwaheader SELECT v_zspr_bwaheader.*; -- %rowtype

 -- part 2/4: zspr_bwaprefs / zspr_bwaprefacct
    FOR v_zspr_bwaprefs IN (SELECT * FROM zspr_bwaprefs prefs WHERE prefs.zspr_bwaheader_id = v_src_bwa_id) -- %rowtype
    LOOP
      v_zspr_bwaprefs.oldprefsidwhencopy:=v_zspr_bwaprefs.zspr_bwaprefs_id;
      v_zspr_bwaprefs_id := v_zspr_bwaprefs.zspr_bwaprefs_id; -- save key
      v_zspr_bwaprefs.zspr_bwaprefs_id := get_uuid();
      v_zspr_bwaprefs.zspr_bwaheader_id := v_new_bwa_id;
      v_zspr_bwaprefs.created := v_now;
      v_zspr_bwaprefs.createdby := v_user_id;
      v_zspr_bwaprefs.updated := v_now;
      v_zspr_bwaprefs.updatedby := v_user_id;
      INSERT INTO zspr_bwaprefs SELECT v_zspr_bwaprefs.*; -- %rowtype
      

   -- sub-part 3/4: zspr_bwaprefacct / Field Access
      FOR v_zspr_bwaprefacct IN (SELECT * FROM zspr_bwaprefacct acct WHERE acct.zspr_bwaprefs_id = v_zspr_bwaprefs_id) -- %rowtype
      LOOP
        v_zspr_bwaprefacct.zspr_bwaprefacct_id := get_uuid();
        v_zspr_bwaprefacct.zspr_bwaprefs_id := v_zspr_bwaprefs.zspr_bwaprefs_id; -- new id byget_uuid()
        v_zspr_bwaprefacct.created := v_now;
        v_zspr_bwaprefacct.createdby := v_user_id;
        v_zspr_bwaprefacct.updated := v_now;
        v_zspr_bwaprefacct.updatedby := v_user_id;
        INSERT INTO zspr_bwaprefacct SELECT v_zspr_bwaprefacct.*; -- %rowtype
     END LOOP;
    END LOOP;
    -- Correction of Selfjoin
    FOR v_zspr_bwaprefs IN (SELECT * FROM zspr_bwaprefs prefs WHERE prefs.zspr_bwaheader_id = v_src_bwa_id and parentpref is not null) -- %rowtype
    LOOP
        select zspr_bwaprefs_id into v_newparent from zspr_bwaprefs where zspr_bwaheader_id=v_new_bwa_id and oldprefsidwhencopy=v_zspr_bwaprefs.parentpref;
        update zspr_bwaprefs set parentpref=v_newparent where zspr_bwaheader_id=v_new_bwa_id and parentpref=v_zspr_bwaprefs.parentpref;
    END LOOP;

 -- part 4/4: finally update for inserted zspr_bwaheader
    UPDATE zspr_bwaheader SET btncopyto = 'Y' WHERE zspr_bwaheader.zspr_bwaheader_id = v_new_bwa_id; -- set button as used, just for documentation

    v_message = '@zspr_bwaheader_copy@' || ': ' || v_new_name; -- vgl. ad_message: german finance
 -- ToDo
 -- v_link := (SELECT zsse_htmldirectlink('../Role/Role_Relation.html', 'document.frmMain.inpad??Id', v_new_bwa_id, v_new_name));
 -- v_message := v_message  || '</br>' || v_link || '<Input type="hidden" name="inpad??Id" value="' || v_new_bwa_id || '" id="zspr_bwaheader_id">';

    PERFORM ad_update_pinstance(p_pinstance_id, NULL, 'N', 1, v_Message) ; -- NULL=p_ad_user_id, 'N'=isProcessing, 1=success
    RAISE NOTICE '%','Updating PInstance - finished ';

    RETURN v_message;

  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := '@ERROR=' || SQLERRM;
  RAISE NOTICE '% %', 'SQL-PROC zspr_bwaheader_copy: ', v_message;
  PERFORM AD_UPDATE_PINSTANCE(p_pinstance_id, NULL, 'N', 0, v_message);
  RETURN v_message;
END;
$_$
LANGUAGE 'plpgsql'
COST 100;


SELECT zsse_dropfunction ('zspr_bwaheader_delete_casc'); 
CREATE OR REPLACE FUNCTION zspr_bwaheader_delete_casc (
  p_pinstance_id  VARCHAR  -- source to be deleted
 )
RETURNS VARCHAR -- 'SUCCESS'
AS $_$
-- SELECT zspr_bwaheader_delete_casc('1F93FACB77E349EEBAE08C352E613C11');  --> neue BWA-Auswertung generieren, GuV
-- select * from zspr_bwaprefs where zspr_bwaheader_id = '1F93FACB77E349EEBAE08C352E613C11';
-- delete from zspr_bwaprefacct WHERE createdby = 'tad';  
-- delete from zspr_bwaprefs WHERE createdby = 'tad'; -- 20
-- delete from zspr_bwaheader WHERE createdby = 'tad'; -- 1

-- DELETE from zspr_bwaprefacct where trunc(updated) = to_date('18-08-2014', 'dd-mm-yyyy'); -- 338
-- DELETE from zspr_bwaprefs where trunc(updated) = to_date('18-08-2014', 'dd-mm-yyyy'); -- 22
-- DELETE from zspr_bwaheader where trunc(updated) = to_date('18-08-2014', 'dd-mm-yyyy'); -- 1
DECLARE
  Cur_Parameter           RECORD;
  v_message               VARCHAR := '';
  v_now                   TIMESTAMP := now();
  v_src_bwa_id            VARCHAR;
  v_old_name              VARCHAR;
  v_YN_option             VARCHAR;

  v_Record_ID             VARCHAR;
  v_user_id               VARCHAR;
  v_link                  VARCHAR;

 -- record buffer declaration
  v_zspr_bwaheader        zspr_bwaheader%rowtype;
  v_zspr_bwaprefs         zspr_bwaprefs%rowtype;
  v_zspr_bwaprefacct      zspr_bwaprefacct%rowtype;

BEGIN

  BEGIN
    IF(p_pinstance_id IS NOT NULL) THEN
      PERFORM ad_update_pinstance(p_pinstance_id, NULL, 'Y', NULL, NULL) ; -- 'Y'=processing
      SELECT pi.Record_ID, pi.ad_User_ID
      INTO v_Record_ID, v_user_id
      FROM ad_pinstance pi WHERE pi.ad_PInstance_ID = p_pinstance_id;

      IF (v_Record_ID IS NULL) then
        RAISE NOTICE '%','Entry for PInstance not found - Using parameter &1=''' || p_pinstance_id || ''' instead';
        v_src_bwa_id := p_pinstance_id;
        v_user_id     := CURRENT_USER;
      ELSE
        -- Get Parameters
        v_message := 'ReadingParameters';
        FOR Cur_Parameter IN
          (SELECT para.parametername, para.p_string
           FROM AD_PInstance pi, AD_PInstance_Para para
           WHERE 1=1
            AND pi.AD_PInstance_ID = para.AD_PInstance_ID
            AND pi.AD_PInstance_ID = p_pinstance_id
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('YN_option') ) THEN -- durch Dialog-Eingabe
            v_YN_option := Cur_Parameter.p_string;
          END IF;
        END LOOP; -- Get Parameter

        RAISE NOTICE '%','Updating PInstance - Processing ' || p_pinstance_id;
        v_src_bwa_id := v_Record_ID;
      END IF;
    END IF;

 -- v_user_id     := CURRENT_USER; --?? debug test

 -- plausi
    IF ( isEmpty(p_pinstance_id) ) THEN
      RAISE EXCEPTION '%', 'SQL-PROC zspr_bwaheader_delete_casc: '|| '@InvalidArguments@'|| ' p_pinstance_id '|| COALESCE(p_pinstance_id, '') ; -- GOTO EXCEPTION
    END IF;
    IF ( isEmpty(v_src_bwa_id) ) THEN
      RAISE EXCEPTION '%', 'SQL-PROC zspr_bwaheader_delete_casc: '|| '@InvalidArguments@'|| ' v_src_bwa_id= '|| COALESCE(v_src_bwa_id, ''); -- GOTO EXCEPTION
    END IF;

 -- part 1/4: BWA_header
 -- v_new_bwa_id := 'BWA_copied'; -- debug-test
    SELECT * INTO v_zspr_bwaheader FROM zspr_bwaheader WHERE zspr_bwaheader_id = v_src_bwa_id; -- read template into rowtype-buffer
    IF isEmpty(v_zspr_bwaheader.zspr_bwaheader_id) THEN
      RAISE EXCEPTION '%', '@zspr_bwaheader_NotFound@'; -- GOTO EXCEPTION
    END IF;
    IF (v_zspr_bwaheader.btncopyto = 'N') THEN
      RAISE EXCEPTION '%', '@zspr_bwaheader_DefaultReportCannotBeDeleted@'; -- GOTO EXCEPTION
    END IF;
    v_old_name := v_zspr_bwaheader.name;

 -- part 2/3: zspr_bwaprefacct
    FOR v_zspr_bwaprefs IN (SELECT * FROM zspr_bwaprefs prefs WHERE prefs.zspr_bwaheader_id = v_zspr_bwaheader.zspr_bwaheader_id) -- %rowtype
    LOOP
      DELETE FROM zspr_bwaprefacct acct WHERE acct.zspr_bwaprefs_id = v_zspr_bwaprefs.zspr_bwaprefs_id;
      RAISE NOTICE 'DELETe % id=% name=%', 'v_zspr_bwaprefs', v_zspr_bwaprefs.zspr_bwaprefs_id, v_zspr_bwaprefs.name; -- GOTO EXCEPTION
    END LOOP;
 -- part 3/4
    DELETE FROM zspr_bwaprefs WHERE zspr_bwaheader_id = v_zspr_bwaheader.zspr_bwaheader_id;
 -- part 4/4
    DELETE FROM zspr_bwaheader WHERE zspr_bwaheader_id = v_zspr_bwaheader.zspr_bwaheader_id;

    v_message = '@zspr_bwaheader_delete_casc@' || ': ' || v_old_name; -- vgl. ad_message: german finance
    PERFORM ad_update_pinstance(p_pinstance_id, NULL, 'N', 1, v_Message) ; -- NULL=p_ad_user_id, 'N'=isProcessing, 1=success
    RAISE NOTICE '%','Updating PInstance - finished ';

    RETURN v_message;
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := '@ERROR=' || SQLERRM;
  RAISE NOTICE '% %', 'SQL-PROC zspr_bwaheader_delete_casc: ', v_message;
  PERFORM AD_UPDATE_PINSTANCE(p_pinstance_id, NULL, 'N', 0, v_message);
  RETURN v_message;
END;
$_$
LANGUAGE 'plpgsql'
COST 100;


SELECT zsse_dropfunction ('zsfi_createaccounts'); 
Create or Replace Function zsfi_createaccounts(p_bpartner_id character varying, p_org_id character varying, cusorven character) RETURNS character varying
AS $_$
declare
v_acctschema_id VARCHAR;
v_seqno VARCHAR;
v_cur VARCHAR;
v_schema VARCHAR;
v_client_id VArchar;
v_acc_id VARCHAR := get_uuid();
v_combid varchar;
BEGIN
      select ad_client_id,c_acctschema_id into v_client_id,v_acctschema_id from ad_org_acctschema where c_acctschema_id in ('ACDCA54677ED496D88AC7AAC0BC4C4DF','B8E0F7780D324C7D863B4B0B670A6429') limit 1;
        IF (cusorven='C') then 
        --Customer
  
            IF (v_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF') then
            --SKR3
                --Platzhalter 
                v_seqno:=ad_sequence_doc('Customer Accounts', p_org_id, 'Y');
                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(p_bpartner_id),zssi_getbpname(p_bpartner_id),'A','E', 'C76385D3874B4775B28CEC5ECBCE1E5B','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF';
                                Insert into c_bp_customer_acct(
                                    c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_customer_acct_id,c_receivable_acct) values
                                    (p_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                        
            END IF;
            IF (v_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429') then
            --SKR4
                --Platzhalter 
                 v_seqno:=ad_sequence_doc('Customer Accounts', p_org_id, 'Y');
                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno, zssi_getbpname(p_bpartner_id),zssi_getbpname(p_bpartner_id),'A','E', 'D871D9715A904125974B545FC0FF0681','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429';
                                Insert into c_bp_customer_acct(
                                    c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_customer_acct_id,c_receivable_acct) values
                                    (p_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                              
            END IF;
        ELSE
        --VENDOR
            IF (v_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF') then
            --SKR3
                --Platzhalter 
                 v_seqno:=ad_sequence_doc('Vendor Accounts', p_org_id, 'Y');
                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(p_bpartner_id),zssi_getbpname(p_bpartner_id),'L','F', 'C76385D3874B4775B28CEC5ECBCE1E5B','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='ACDCA54677ED496D88AC7AAC0BC4C4DF';
                                Insert into c_bp_vendor_acct(
                                            c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_vendor_acct_id,v_liability_acct) values
                                            (p_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                               
            END IF;
            IF (v_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429') then
            --SKR4
                --Platzhalter 
                 v_seqno:=ad_sequence_doc('Vendor Accounts', p_org_id, 'Y');
                Insert into c_elementvalue (
                c_elementvalue_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,VALUE,NAME,DESCRIPTION,accounttype,accountsign,c_element_id,issummary,showelement,showvaluecond,elementlevel,nomanualacct,datevuseauto) values 
                (v_acc_id, v_client_id, p_org_id,'Y',now(),100, now(),100, v_seqno , zssi_getbpname(p_bpartner_id),zssi_getbpname(p_bpartner_id),'L','F', 'D871D9715A904125974B545FC0FF0681','N','Y','A','C','N','N');
                select c_validcombination_id into v_combid from  c_validcombination where account_id=v_acc_id and c_acctschema_id='B8E0F7780D324C7D863B4B0B670A6429';
                                Insert into c_bp_vendor_acct(
                                    c_bpartner_id,c_acctschema_id,ad_Client_id,ad_org_id,isactive,created,createdby,updated,updatedby,c_bp_vendor_acct_id,v_liability_acct) values
                                    (p_bpartner_id,v_acctschema_id,v_client_id,p_org_id,'Y',now(),100,now(),100,get_uuid(),v_combid);
                                
            END IF;        END IF;
            RETURN v_seqno;
END;
$_$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION C_PaymentduedateByPayterm(p_bpartner_id character varying,p_payterm_id character varying,p_issotrx character varying, p_paymentrule character varying, p_date_invoiced timestamp without time zone) RETURNS timestamp
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
********************************************************************************************************************************************************/
CUR_PAYMENTS RECORD;
v_plannedDate TIMESTAMP;
BEGIN 
     
      
      for CUR_PAYMENTS in (SELECT LINE,PERCENTAGE,ONREMAINDER,EXCLUDETAX,COALESCE(PAYMENTRULE, p_paymentrule) AS PAYMENTRULE,
                  FIXMONTHDAY,FIXMONTHDAY2,FIXMONTHDAY3,NETDAYS,FIXMONTHOFFSET,NETDAY,ISNEXTBUSINESSDAY   
                FROM C_PAYMENTTERMLINE  WHERE C_PAYMENTTERM_ID=p_payterm_id
                UNION
                  SELECT 9999 AS LINE,100 AS PERCENTAGE,'Y' AS ONREMAINDER,'N' AS EXCLUDETAX, p_paymentrule AS PAYMENTRULE,
                  FIXMONTHDAY, FIXMONTHDAY2,FIXMONTHDAY3,NETDAYS, FIXMONTHOFFSET,NETDAY,ISNEXTBUSINESSDAY
                FROM C_PAYMENTTERM WHERE C_PAYMENTTERM_ID=p_payterm_id
                ORDER BY LINE)
      LOOP
            v_plannedDate:=C_Paymentduedate(p_bpartner_id, p_issotrx, CUR_PAYMENTS.FixMonthDay, CUR_PAYMENTS.FixMonthDay2, CUR_PAYMENTS.FixMonthDay3, CUR_PAYMENTS.NetDays, CUR_PAYMENTS.FixMonthOffset, CUR_PAYMENTS.NetDay, CUR_PAYMENTS.IsNextbusinessday, p_date_invoiced) ;
            return v_plannedDate;
      END LOOP;
      return v_plannedDate;
END;
$_$  LANGUAGE 'plpgsql';


 
select zsse_dropfunction('zsfi_reversechargerevenue');
CREATE OR REPLACE FUNCTION zsfi_reversechargerevenue(p_org_id varchar,p_bwaprefs_id varchar,pDateFrom timestamp without time zone,pDateTo timestamp without time zone,
                                                     ACCTVALUE out varchar,ACCTDESCRIPTION out varchar,summe out numeric,summevj out numeric)
RETURNS SETOF RECORD AS
$BODY$ DECLARE 
v_cur record;
v_cur2 record;
v_ref varchar;
v_name varchar;
BEGIN
  if (select count(*) from ZSPR_Bwaprefs where ZSPR_Bwaprefs_id=p_bwaprefs_id and addreversechargeasrevenue='Y')>0 then
   for v_cur in (select * from c_tax where reversecharge='Y')
   LOOP
       -- Summe
       select sum(f.amtacctdr-f.amtacctcr) into summe
       from fact_acct f,c_elementvalue v
       where v.c_elementvalue_id=f.account_id and
              f.fact_acct_group_id in (select fact_acct_group_id from fact_acct where dateacct between pDateFrom and pDateTo and c_tax_id=v_cur.c_tax_id and 
                   case when p_org_id!='0' then ad_org_id=p_org_id else 1=1 end)
       and (case when v.c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' then v.value like '16%' else v.value like '33%' end or v.accountsign ='F');
       -- Summe VJ
       select sum(f.amtacctdr-f.amtacctcr) into summevj
       from fact_acct f,c_elementvalue v
       where v.c_elementvalue_id=f.account_id and
               f.fact_acct_group_id in (select fact_acct_group_id from fact_acct where dateacct between pDateFrom - interval '1 year' and pDateTo- interval '1 year'  and c_tax_id=v_cur.c_tax_id and 
                   case when p_org_id!='0' then ad_org_id=p_org_id else 1=1 end)
       and (case when v.c_element_id='C76385D3874B4775B28CEC5ECBCE1E5B' then v.value like '16%' else v.value like '33%' end or v.accountsign ='F');
       if summe is null then summe:=0; end if;
       if summevj is null then summevj:=0; end if;
       ACCTVALUE:=v_cur.name;
       ACCTDESCRIPTION:=v_cur.name||'-'||v_cur.description;
       RETURN NEXT;
    END LOOP;
   end if;    
END;
$BODY$  LANGUAGE 'plpgsql' VOLATILE  COST 100;       


CREATE OR REPLACE FUNCTION zsfi_GetContraAccountsFromFactAcctGroup(v_fact_acct_groupID in character varying,v_account_id in character varying)
RETURNS CHARACTER VARYING
AS
$BODY$ DECLARE 
 v_return   character varying;
 v_bploc character varying;
BEGIN
  select string_agg(distinct acctvalue,',') into v_return from fact_acct where fact_acct_group_id=v_fact_acct_groupID and account_id!=v_account_id;
  return v_return;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
********************************************************************************************************************************************************/  
CREATE OR REPLACE FUNCTION zsfi_BankStmtDownPaymentReceivedAndTaxes(p_bankstatementline_id varchar, p_dateacct varchar, p_user varchar) RETURNS varchar AS
$BODY$ 
DECLARE 
 v_inv varchar;
 v_factgroup varchar;
 v_acct varchar;
 v_acctname varchar;
 v_acctval varchar;
 v_cur record;
 v_newfact_group varchar;
 v_period varchar;
 v_sourceacct varchar;
 v_fact2move  fact_acct%rowtype;
 v_tax varchar;
 v_amtcng numeric;
 v_fergal1 numeric;
 v_fergal2 numeric;
 v_info  varchar;
 v_created timestamp without time zone;
 v_seq numeric:=10;
BEGIN
  select dp.c_invoice_id,bs.description,dp.updated into v_inv,v_info,v_created from c_bankstatementline bs,c_debt_payment dp where dp.c_debt_payment_id=bs.c_debt_payment_id and bs.c_bankstatementline_id=p_bankstatementline_id;
  if v_inv is null then
    return 'NO INVOICE';
  end if;
  if (select count(*) from c_debt_payment where c_invoice_id=v_inv and c_bankstatementline_id is not null and c_bankstatementline_id!=p_bankstatementline_id and updated<v_created)>0 then
    return 'INVOICE ALREADY TAXED';
  end if;
  v_newfact_group:=get_uuid();
  select distinct fact_acct_group_id into v_factgroup from fact_acct where record_id=v_inv and ad_table_id='318';
  -- Priod
  select c_period_id into v_period from c_periodcontrol_v where  ad_org_id=v_fact2move.ad_Org_id and isactive='Y' and periodstatus='O' and 
                       docbasetype=v_fact2move.docbasetype and startdate<=p_dateacct and enddate>=p_dateacct;
  -- Load Tax (Only 1 Tax per document)
  select distinct c_tax_id into v_tax from fact_acct where fact_acct_group_id = v_factgroup and c_tax_id is not null;
  if v_tax is null then
    select max(c_tax_id) into v_tax from c_invoiceline where c_invoice_id=v_inv;
  end if;
  for v_cur in (select * from fact_acct where fact_acct_group_id=v_factgroup)
  LOOP
    v_acct:=null;
    -- Fill in the Data
    select * into v_fact2move from fact_acct where fact_acct_id=v_cur.fact_acct_id;
    v_sourceacct:=v_fact2move.account_id;
    v_fact2move.dateacct:=p_dateacct;
    v_fact2move.datetrx:=p_dateacct;
    v_fact2move.created:=now();
    v_fact2move.updated:=now();
    v_fact2move.fact_acct_group_id:=v_newfact_group;
    v_fact2move.c_period_id:=v_period;
    v_fact2move.docbasetype:='DPC';  -- Down Payment to cash
    --v_fact2move.ad_table_id:=393; 
    --v_fact2move.record_id:=p_bankstatementline_id;
    v_fact2move.ad_table_id:=392; 
    v_fact2move.record_id:=(select c_bankstatement_id from c_bankstatementline where c_bankstatementline_id=p_bankstatementline_id);
    -- Move Tax and Product Lines...
    if v_cur.c_tax_id is not null then
        select v.account_id,e.value,e.name into v_acct,v_acctval,v_acctname from c_tax_acct a,c_validcombination v,c_elementvalue e where e.c_elementvalue_id=v.account_id and 
                            a.t_due_acct=v.c_validcombination_id and a.c_tax_id= v_cur.c_tax_id and a.c_acctschema_id =v_cur.c_acctschema_id;
    end if;
    if v_cur.m_product_id is not null then
        --select v.account_id,e.value,e.name into v_acct,v_acctval,v_acctname  from c_validcombination v,c_elementvalue e  where e.c_elementvalue_id=v.account_id
        --                    and v.c_validcombination_id=zsfi_GetPAccount('1', v_cur.m_product_id, v_cur.c_acctschema_id);
        select v.account_id,e.value,e.name into v_acct,v_acctval,v_acctname from c_tax_acct a,c_validcombination v,c_elementvalue e where e.c_elementvalue_id=v.account_id and 
                            a.t_downpay_acct=v.c_validcombination_id and a.c_tax_id= v_tax and a.c_acctschema_id =v_cur.c_acctschema_id;
    end if;
    if v_acct is not null then
        -- 1nd. To Target (Same Direction...)
        v_fact2move.fact_acct_id:=get_uuid();
        v_fact2move.line_id:=get_uuid();
        v_fact2move.account_id:=v_acct;
        v_fact2move.seqno:=v_seq;
        v_seq:=v_seq+10;
        insert into fact_acct select v_fact2move.*;
        update fact_acct set acctvalue=v_acctval,acctdescription=v_acctname where fact_acct_id=v_fact2move.fact_acct_id;
        -- 2St. From Source (Reverse Direction)
        v_fact2move.fact_acct_id:=get_uuid();
        v_fact2move.account_id:=v_sourceacct;
        v_amtcng:=v_fact2move.amtacctdr;
        v_fact2move.amtacctdr:=v_fact2move.amtacctcr;
        v_fact2move.amtacctcr:=v_amtcng;
        v_amtcng:=v_fact2move.amtsourcedr;
        v_fact2move.amtsourcedr:=v_fact2move.amtsourcecr;
        v_fact2move.amtsourcecr:=v_amtcng;
        v_fact2move.seqno:=v_seq;
        v_seq:=v_seq+10;
        insert into fact_acct select v_fact2move.*;
    end if;
  END LOOP;
  select sum(amtacctdr) into v_fergal1 from fact_acct where fact_acct_group_id=v_newfact_group;
  select sum(amtacctcr) into v_fergal2 from fact_acct where fact_acct_group_id=v_newfact_group;
  if v_fergal1!=v_fergal2 then
    Raise exception '%','Proc zsfi_BankStmtDownPaymentReceivedAndTaxes DR!=CR:'||v_info;
  end if;
  return 'OK';
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
  
  
  
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
********************************************************************************************************************************************************/  

CREATE OR REPLACE FUNCTION zsfi_DownPaymentsToRevenue(p_invoice_id varchar, p_acctshema_id varchar, p_user varchar) RETURNS varchar AS
$BODY$ 
DECLARE 
 v_ord varchar;
 v_tmpact varchar;
 v_downpayacct varchar;
 v_taxacct varchar;
 v_debitacct varchar;
 v_debitacctname varchar;
 v_debitacctval varchar;
 v_acctname varchar;
 v_acctval varchar;
 v_acctrev varchar;
 v_acctnamerev varchar;
 v_acctvalrev varchar;
 v_dateacct timestamp without time zone;
 v_cur record;
 v_cur2 record;
 v_cur3 record;
 v_cur4 record;
 v_newfact_group varchar;
 v_fact2move  fact_acct%rowtype;
 v_fact2move2  fact_acct%rowtype;
 v_tax varchar;
 v_amtcng numeric;
 v_fergal1 numeric;
 v_fergal2 numeric;
 v_info  varchar;
 v_seq numeric;
 v_count numeric;
BEGIN
  if (select count(*) from c_invoice where c_invoice_id=p_invoice_id)=0 then
    return 'NO INVOICE';
  end if;
  select c_order_id into v_ord from c_order_paymentschedule where c_invoice_id =p_invoice_id and isrevenue='Y';
  if v_ord is null then
    return 'NOT to REVENUE';
  end if;
  select count(*) into v_count from fact_acct where record_id=p_invoice_id and docbasetype='DPR';
  if v_count>0 then
    return 'ALREADY DONE';
  end if;
  select dateacct into v_dateacct from c_invoice where c_invoice_id=p_invoice_id;
  for v_cur in (select c_invoice_id from c_order_paymentschedule where c_order_id=v_ord and c_invoice_id is not null and isrevenue='N' and invoicedate<(select invoicedate  from c_order_paymentschedule where c_invoice_id=p_invoice_id))
  LOOP
    select distinct c_tax_id into v_tax from c_invoicetax where c_invoice_id= v_cur.c_invoice_id;
    select zsfi_GetBPAccount('1',c_bpartner_id, p_acctshema_id) into v_tmpact  from c_invoice where c_invoice_id=v_cur.c_invoice_id;
    select account_id into v_debitacct from c_validcombination where c_validcombination_id=v_tmpact;
    select e.value,e.name into v_debitacctval,v_debitacctname from c_elementvalue e where e.c_elementvalue_id=v_debitacct;
    select v.account_id into v_downpayacct from c_tax_acct a,c_validcombination v,c_elementvalue e where e.c_elementvalue_id=v.account_id and 
                            a.t_downpay_acct=v.c_validcombination_id and a.c_tax_id= v_tax and a.c_acctschema_id =p_acctshema_id;
    select v.account_id,e.value,e.name into v_acctrev,v_acctvalrev,v_acctnamerev from c_tax_acct a,c_validcombination v,c_elementvalue e where e.c_elementvalue_id=v.account_id and 
                            a.t_p_revenue_acct=v.c_validcombination_id and a.c_tax_id= v_tax and a.c_acctschema_id =p_acctshema_id;
    select v.account_id into v_taxacct from c_tax_acct a,c_validcombination v,c_elementvalue e where e.c_elementvalue_id=v.account_id and 
                            a.t_due_acct=v.c_validcombination_id and a.c_tax_id= v_tax and a.c_acctschema_id =p_acctshema_id;
    for v_cur2 in (select distinct bsl.c_bankstatement_id from c_debt_payment dp,c_bankstatementline bsl where dp.c_bankstatementline_id=bsl.c_bankstatementline_id and dp.c_invoice_id=v_cur.c_invoice_id
           and dp.c_bankstatementline_id is not null)
    LOOP
        -- Zahlungseingänge der Anzahlungen/Zwischenrechnungen gebucht? Wenn nicht müssen diese Buchungen nachbearbeitet werden
        select count(*) into v_count from fact_acct where record_id=v_cur2.c_bankstatement_id and ad_table_id='392' and account_id=v_downpayacct;
        if v_count=0 then -- Vielleicht kommen die Später, da Bankstatements erst noch gebucht werden....
            insert into fact_acct_tempitems (fact_acct_tempitems_id, ad_client_id, ad_org_id, createdby, updatedby, c_invoice_id,c_acctschema_id,ad_user_id) 
            values (get_uuid(),'C726FEC915A54A0995C568555DA5BB3C','0','0','0',p_invoice_id,p_acctshema_id,p_user);
        end if;
        for v_cur3 in (select distinct fact_acct_group_id from fact_acct where record_id=v_cur2.c_bankstatement_id and ad_table_id='392' and account_id=v_downpayacct)
        LOOP
            v_seq:=10;
            v_newfact_group:=get_uuid();
            for v_cur4 in (select * from fact_acct where fact_acct_group_id=v_cur3.fact_acct_group_id)
            LOOP
                select * into v_fact2move from fact_acct where fact_acct_id=v_cur4.fact_acct_id;
                v_fact2move.ad_table_id='318';
                v_fact2move.record_id=p_invoice_id;
                v_fact2move.created:=now();
                v_fact2move.updated:=now();
                v_fact2move.createdby:=p_user;
                v_fact2move.updatedby:=p_user;
                v_fact2move.fact_acct_group_id:=v_newfact_group;
                v_fact2move.dateacct:=v_dateacct;
                v_fact2move.datetrx:=v_dateacct;
                v_fact2move.docbasetype:='DPR';  -- Down Payment to revenue
                if (v_cur4.account_id=v_taxacct) then
                    -- Tax to Debitor
                    v_fact2move2:=v_fact2move;
                    --1nd rauf auf Deb
                    v_fact2move2.c_tax_id:=null;
                    v_fact2move2.fact_acct_id:=get_uuid();
                    v_fact2move2.seqno:=v_seq;
                    v_seq:=v_seq+10;
                    v_fact2move2.account_id:=v_debitacct;
                    v_fact2move2.acctvalue:=v_debitacctval;
                    v_fact2move2.acctdescription:=v_debitacctname;
                    insert into fact_acct select v_fact2move2.*; 
                    --2nd runter von Deb
                    v_amtcng:=v_fact2move.amtacctdr;
                    v_fact2move2.amtacctdr:=v_fact2move2.amtacctcr;
                    v_fact2move2.amtacctcr:=v_amtcng;
                    v_amtcng:=v_fact2move2.amtsourcedr;
                    v_fact2move2.amtsourcedr:=v_fact2move2.amtsourcecr;
                    v_fact2move2.amtsourcecr:=v_amtcng;
                    v_fact2move2.seqno:=v_seq;
                    v_seq:=v_seq+10;
                    v_fact2move2.fact_acct_id:=get_uuid();
                    insert into fact_acct select v_fact2move2.*; 
                    --3rd Tax runter vom USt 
                    v_amtcng:=v_fact2move.amtacctdr;
                    v_fact2move.amtacctdr:=v_fact2move.amtacctcr;
                    v_fact2move.amtacctcr:=v_amtcng;
                    v_amtcng:=v_fact2move.amtsourcedr;
                    v_fact2move.amtsourcedr:=v_fact2move.amtsourcecr;
                    v_fact2move.amtsourcecr:=v_amtcng;
                    v_fact2move.seqno:=v_seq;
                    v_seq:=v_seq+10;
                    v_fact2move.fact_acct_id:=get_uuid();
                    insert into fact_acct select v_fact2move.*;    
                    --4th rauf auf USt
                    v_amtcng:=v_fact2move.amtacctdr;
                    v_fact2move.amtacctdr:=v_fact2move.amtacctcr;
                    v_fact2move.amtacctcr:=v_amtcng;
                    v_amtcng:=v_fact2move.amtsourcedr;
                    v_fact2move.amtsourcedr:=v_fact2move.amtsourcecr;
                    v_fact2move.amtsourcecr:=v_amtcng;
                    v_fact2move.seqno:=v_seq;
                    v_seq:=v_seq+10;
                    v_fact2move.fact_acct_id:=get_uuid();
                    insert into fact_acct select v_fact2move.*; 
                end if;
                if (v_cur4.account_id=v_downpayacct) then
                    -- Erh Anzahlungen -> Debitor -> Umsatz
                    v_fact2move2:=v_fact2move;
                    --1. Rauf auf Debitor
                    v_fact2move2.fact_acct_id:=get_uuid();
                    v_fact2move2.seqno:=v_seq;
                    v_seq:=v_seq+10;
                    v_fact2move2.account_id:=v_debitacct;
                    v_fact2move2.acctvalue:=v_debitacctval;
                    v_fact2move2.acctdescription:=v_debitacctname;
                    insert into fact_acct select v_fact2move2.*; 
                    --2. Runter von Debitor
                    v_amtcng:=v_fact2move.amtacctdr;
                    v_fact2move2.amtacctdr:=v_fact2move2.amtacctcr;
                    v_fact2move2.amtacctcr:=v_amtcng;
                    v_amtcng:=v_fact2move2.amtsourcedr;
                    v_fact2move2.amtsourcedr:=v_fact2move2.amtsourcecr;
                    v_fact2move2.amtsourcecr:=v_amtcng;
                    v_fact2move2.seqno:=v_seq;
                    v_seq:=v_seq+10;
                    v_fact2move2.fact_acct_id:=get_uuid();
                    insert into fact_acct select v_fact2move2.*; 
                    --3. Runter von Erh. Anzahlungen
                    v_amtcng:=v_fact2move.amtacctdr;
                    v_fact2move.amtacctdr:=v_fact2move.amtacctcr;
                    v_fact2move.amtacctcr:=v_amtcng;
                    v_amtcng:=v_fact2move.amtsourcedr;
                    v_fact2move.amtsourcedr:=v_fact2move.amtsourcecr;
                    v_fact2move.amtsourcecr:=v_amtcng;
                    v_fact2move.seqno:=v_seq;
                    v_seq:=v_seq+10;
                    v_fact2move.fact_acct_id:=get_uuid();
                    insert into fact_acct select v_fact2move.*;    
                    --4. Rauf auf Umsatz
                    v_amtcng:=v_fact2move.amtacctdr;
                    v_fact2move.amtacctdr:=v_fact2move.amtacctcr;
                    v_fact2move.amtacctcr:=v_amtcng;
                    v_amtcng:=v_fact2move.amtsourcedr;
                    v_fact2move.amtsourcedr:=v_fact2move.amtsourcecr;
                    v_fact2move.amtsourcecr:=v_amtcng;
                    v_fact2move.seqno:=v_seq;
                    v_fact2move.account_id:=v_acctrev;
                    v_fact2move.acctvalue:=v_acctvalrev;
                    v_fact2move.acctdescription:=v_acctnamerev;
                    v_seq:=v_seq+10;
                    v_fact2move.fact_acct_id:=get_uuid();
                    insert into fact_acct select v_fact2move.*;    
                end if;
            END LOOP;
            select sum(amtacctdr) into v_fergal1 from fact_acct where fact_acct_group_id=v_newfact_group;
            select sum(amtacctcr) into v_fergal2 from fact_acct where fact_acct_group_id=v_newfact_group;
            if v_fergal1!=v_fergal2 then
                Raise exception '%','Proc zsfi_DownPaymentsToRevenue DR!=CR:'||(select documentno from c_invoice where c_invoice_id=p_invoice_id);
            end if;
        END LOOP;
    END LOOP;
  END LOOP;
  return 'OK';
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE OR REPLACE FUNCTION zsfi_processDownPaymentsTempItems() RETURNS varchar AS
$BODY$ 
DECLARE 
 v_cur record;
 v_return varchar:='NOACTION';
BEGIN
  for v_cur in (select distinct c_invoice_id,c_acctschema_id ,ad_user_id from fact_acct_tempitems)
  LOOP
    select zsfi_DownPaymentsToRevenue(v_cur.c_invoice_id , v_cur.c_acctschema_id , v_cur.ad_user_id) into v_return;
  END LOOP;
  delete from fact_acct_tempitems;
  return v_return;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
********************************************************************************************************************************************************/  

CREATE OR REPLACE FUNCTION zsfi_getBookCurrency(p_org_id varchar) RETURNS varchar AS
$BODY$ 
DECLARE 
 v_Org varchar;
 v_acctshema varchar;
 v_currency varchar;
BEGIN
  if p_org_id is null or p_org_id='0' then
    select systemid into v_Org from ad_systemupdateview;
  else
    v_Org:=p_org_id;
  end if;
  select c_acctschema_id into v_acctshema from ad_org_acctschema where ad_org_id=v_Org;
  select c_currency_id into v_currency from c_acctschema where c_acctschema_id=v_acctshema; 
  return v_currency;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
