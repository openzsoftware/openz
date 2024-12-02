
CREATE OR REPLACE FUNCTION ad_table_import(p_pinstance_id character varying, p_ad_table_id character varying) RETURNS void
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
  * $Id: AD_Table_Import.sql,v 1.8 2003/01/18 05:34:25 jjanke Exp $
  ***
  * Title: Import Table Column Definition
  * Description:
  *   Create Columns of Table not existing as a Dictionary Column
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_AD_User_ID VARCHAR(32):='0'; --OBTG:VARCHAR2--
  v_module_table_id VARCHAR(32); --OBTG:varchar2--
  v_module_id VARCHAR(32); --OBTG:varchar2--
  db_prefix VARCHAR(30); --OBTG:varchar2--
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    --
    Cur_Column RECORD;
    Cur_CommonCols RECORD;
    --
    v_NextNo VARCHAR(32) ; --OBTG:VARCHAR2--
    v_count NUMERIC(10):=0;
    -- Added by Ismael Ciordia
    v_AD_Reference_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AD_Reference_Value_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AD_Val_Rule_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_IsParent CHAR(1):='N';
    v_IsKey CHAR(1):='N';
    v_IsIdentifier CHAR(1):='N';
    v_IsSessionAttr CHAR(1):='N';
    v_IsUpdateable CHAR(1):='Y';
    v_DefaultValue VARCHAR(2000):=''; --OBTG:NVARCHAR2--
    v_SeqNo NUMERIC(10) ;
    v_columnName VARCHAR(40) ; --OBTG:VARCHAR2--
    v_TableName  VARCHAR(40) ; --OBTG:VARCHAR2--
    v_LastColumnName VARCHAR(40) ; --OBTG:VARCHAR2--
    v_varchar2 VARCHAR(32767) ; --OBTG:VARCHAR2--
    v_FieldLength NUMERIC(10) ;
    v_PInstance_Log_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Aux NUMERIC;
    v_missingColumns boolean;
    v_CorrectType CHAR(1):='Y';
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      v_ResultStr:='PInstanceNotFound';
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
      -- Get Parameters
      v_ResultStr:='ReadingParameters';
      FOR Cur_Parameter IN
        (SELECT i.Record_ID, i.AD_User_ID, p.ParameterName, p.P_String, p.P_Number, p.P_Date, p.AD_CLIENT_ID
        FROM AD_PInstance i
        LEFT JOIN AD_PInstance_Para p
          ON i.AD_PInstance_ID=p.AD_PInstance_ID
        WHERE i.AD_PInstance_ID=p_PInstance_ID
        ORDER BY p.SeqNo
        )
      LOOP
        v_Record_ID:=Cur_Parameter.Record_ID;
        v_AD_User_ID:=Cur_Parameter.AD_User_ID;
        v_Client_ID:=Cur_Parameter.AD_CLIENT_ID;
      END LOOP; -- Get Parameter
    ELSE
      v_Record_ID:=p_AD_Table_ID;
    END IF;
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
  BEGIN --BODY
    IF(v_Record_ID IS NOT NULL) THEN
      SELECT COALESCE(MAX(SeqNo), 0) + 10
      INTO v_SeqNo
      FROM AD_Column
      WHERE AD_Table_ID=v_Record_ID;
    ELSE
      v_SeqNo:=0;
    END IF;
    
          
      select p.ad_module_id
        into v_module_table_id
        from ad_table t, ad_package p
      where t.ad_table_id = v_Record_ID
        and t.ad_package_id = p.ad_package_id;
        
    FOR Cur_Column IN
      (SELECT Column_Name, Data_Type, Data_Length, Nullable, AD_Table_ID, -- added by Ismael Ciordia
        uc.DATA_PRECISION, uc.DATA_SCALE, DATA_DEFAULT, Table_Name, uc.COLUMN_ID
      FROM User_Tab_Columns uc, AD_Table t
      WHERE uc.Table_Name=UPPER(t.TableName) AND NOT EXISTS
        (SELECT *
        FROM AD_Table t, AD_Column c
        WHERE t.AD_Table_ID=c.AD_Table_ID  AND uc.Table_Name=UPPER(t.TableName) AND uc.Column_Name=UPPER(c.ColumnName)
        )
        AND(v_Record_ID=t.AD_Table_ID OR v_Record_ID IS NULL) -- added by Ismael Ciordia
      ORDER BY uc.COLUMN_ID
      )
    LOOP
      SELECT * INTO  v_NextNo FROM AD_Sequence_Next('AD_Column', '0') ; -- get ID
      -- Added by Ismael Ciordia
      v_AD_Reference_ID:=NULL;
      v_AD_Reference_Value_ID:=NULL;
      v_AD_Val_Rule_ID:=NULL;
      v_IsParent:='N';
      v_IsKey:='N';
      v_IsIdentifier:='N';
      v_IsSessionAttr:='N';
      v_IsUpdateable:='Y';
      v_varchar2:=Cur_Column.DATA_DEFAULT;
      v_varchar2:=SUBSTR(v_varchar2, 1, 2000) ;
      v_CorrectType:='Y';
      IF(INSTR(v_varchar2, '''')<>0) THEN
        v_varchar2:=SUBSTR(SUBSTR(v_varchar2, 2, 1999), 1, INSTR(SUBSTR(v_varchar2, 2, 1999), '''') -1) ;
      ELSE
        v_varchar2:=TRIM(REPLACE(REPLACE(v_varchar2, REPLACE('now ()',' ',''), '@#Date@'), CHR(10), '')) ;
      END IF;
      v_DefaultValue:=v_varchar2;
      IF(UPPER(Cur_Column.Column_Name)=UPPER(Cur_Column.Table_Name) ||'_ID') THEN --ID column
        v_AD_Reference_ID:=13;
        v_IsKey:='Y';
        v_IsUpdateable:='N';
      ELSIF(UPPER(Cur_Column.Column_Name) IN('AD_CLIENT_ID', 'AD_ORG_ID')) THEN
        v_AD_Reference_ID:=19;
        v_DefaultValue:='@'||Cur_Column.Column_Name||'@';
        v_IsUpdateable:='N';
        v_IsSessionAttr:='Y';
        IF(UPPER(Cur_Column.Column_Name)='AD_CLIENT_ID') THEN
          v_AD_Val_Rule_ID:='103';
        ELSE
          v_AD_Val_Rule_ID:='104';
        END IF;
      ELSIF(UPPER(Cur_Column.Column_Name) IN('UPDATED', 'CREATED')) THEN
        v_AD_Reference_ID:='16';
        v_IsUpdateable:='N';
      ELSIF(UPPER(Cur_Column.Column_Name) IN('UPDATEDBY', 'CREATEDBY')) THEN
        v_AD_Reference_ID:='30';
        v_IsUpdateable:='N';
      ELSIF(UPPER(Cur_Column.Column_Name) IN('NAME')) THEN
        v_IsIdentifier:='Y';
      ELSIF(UPPER(Cur_Column.Column_Name) IN('M_PRODUCT_ID')) THEN
        v_AD_Reference_ID:='30';
        v_AD_Reference_Value_ID:='800060';
      ELSIF(UPPER(Cur_Column.Column_Name) IN ('C_BPARTNER_ID')) THEN 
        v_AD_Reference_ID:='30';
        v_AD_Reference_Value_ID:='800057';
      ELSIF(UPPER(Cur_Column.Column_Name) IN('M_ATTRIBUTESETINSTANCE_ID')) THEN
        v_AD_Reference_ID:='35';
      ELSIF(UPPER(Cur_Column.Column_Name) LIKE '%_LOCATION_ID') THEN
        v_AD_Reference_ID:='30';
        v_AD_Reference_Value_ID:='21';
      ELSIF(UPPER(Cur_Column.Column_Name) LIKE '%_LOCATOR%_ID') THEN
        v_AD_Reference_ID:='30';
        v_AD_Reference_Value_ID:='31';
      ELSIF(UPPER(Cur_Column.Column_Name) LIKE '%_ACCT') THEN
        v_AD_Reference_ID:='30';
        v_AD_Reference_Value_ID:='25';
      ELSIF(UPPER(Cur_Column.Column_Name) LIKE '%_ID') THEN
        v_AD_Reference_ID:='19';
      ELSIF(UPPER(Cur_Column.Column_Name) IN('LINE', 'SEQNO')) THEN
        v_DefaultValue:='@SQL=SELECT COALESCE(MAX('||Cur_Column.Column_Name||'),0)+10 AS DefaultValue FROM '||Cur_Column.Table_Name||' WHERE xxParentColumn=@xxParentColumn@';
      END IF;
      IF(UPPER(v_LastColumnName)='UPDATEDBY' AND UPPER(Cur_Column.Column_Name) LIKE '%_ID') THEN
        v_IsParent:='Y';
        v_IsUpdateable:='N';
      END IF;
      --added by Pablo Sarobe
      IF(Cur_Column.Data_Type IN('VARCHAR2', 'CHAR')) THEN
        v_FieldLength:=Cur_Column.Data_Length;
      ELSIF(Cur_Column.Data_Type IN('NVARCHAR2', 'NCHAR')) THEN
        v_FieldLength:=Cur_Column.Data_Length/2;
      ELSIF(Cur_Column.Data_Type IN('DATE', 'TIMESTAMP')) THEN
        v_FieldLength:=19;
      ELSIF(Cur_Column.Data_Type IN('NUMBER')) THEN
        v_FieldLength:=12;
        --COALESCE(Cur_Column.Data_Precision, 10) +2;
      ELSE
        v_FieldLength:=Cur_Column.Data_Length;
      END IF;
      IF(v_AD_Reference_ID IS NULL) THEN
        IF(Cur_Column.Data_Type IN('CHAR','BPCHAR') AND Cur_Column.Data_Length=1) THEN
          v_AD_Reference_ID:='20';
        ELSIF(Cur_Column.Data_Type IN('VARCHAR', 'VARCHAR2', 'NVARCHAR2', 'CHAR', 'NCHAR') AND Cur_Column.Data_Length=4000) THEN
          v_AD_Reference_ID:='14';
        ELSIF(Cur_Column.Data_Type IN('VARCHAR', 'VARCHAR2', 'NVARCHAR2', 'CHAR', 'NCHAR')) THEN
          v_AD_Reference_ID:='10';
        ELSIF(Cur_Column.Data_Type='NUMBER' AND Cur_Column.DATA_SCALE=0) THEN
          v_AD_Reference_ID:='12';
        ELSIF(Cur_Column.Data_Type='NUMBER' AND UPPER(Cur_Column.Column_Name) LIKE '%AMT%') THEN
          v_AD_Reference_ID:='12';
        ELSIF(Cur_Column.Data_Type='NUMBER' AND UPPER(Cur_Column.Column_Name) LIKE '%QTY%') THEN
          v_AD_Reference_ID:='29';
        ELSIF(Cur_Column.Data_Type='NUMBER') THEN
          v_AD_Reference_ID:='22';
        ELSIF(Cur_Column.Data_Type IN ('DATE', 'TIMESTAMP')) THEN
          v_AD_Reference_ID:='15';
        ELSE
          v_AD_Reference_ID:='10'; -- if not found, use String
          v_CorrectType:='N';
        END IF;
      END IF;
      v_columnName:=InitCap(Cur_Column.Column_Name) ;
      IF(INSTR(v_columnName, '_')<>0 AND INSTR(v_columnName, '_')<5) THEN
        v_columnName:=UPPER(SUBSTR(v_columnName, 1, INSTR(v_columnName, '_'))) ||SUBSTR(v_columnName, INSTR(v_columnName, '_') +1, 40) ;
      END IF;
      IF(v_columnName LIKE '%_Id') THEN
        v_columnName:=SUBSTR(v_columnName, 1, LENGTH(v_columnName) -3) ||'_ID';
      END IF;
      
      --Check if it is necessary to recalculate positions
      SELECT count(*)
        INTO v_Aux
        FROM AD_COLUMN
       WHERE POSITION = Cur_Column.COLUMN_ID;
       
      IF v_Aux!=0 THEN
        UPDATE AD_COLUMN C
           SET POSITION = (SELECT COLUMN_ID
                             FROM USER_TAB_COLUMNS U,
                                  AD_TABLE T
                            WHERE C.AD_TABLE_ID = T.AD_TABLE_ID
                              AND U.TABLE_NAME = UPPER(T.TABLENAME)
                              AND U.COLUMN_NAME = UPPER(C.COLUMNNAME))
         WHERE AD_TABLE_ID = Cur_Column.AD_Table_ID;
      END IF;

      
      IF substr(upper(v_columnName),1,3)='EM_' then
        db_prefix := substr(v_columnName,4,instr(v_columnName,'_',1,2)-4);
        RAISE NOTICE '%','Prefix:'||db_prefix;
        select max(ad_module_id)
          into v_module_id
          from ad_module_dbprefix
         where upper(name) = upper(db_prefix);
          
        if v_module_id is null then
          v_module_id := v_module_table_id;
        end if;
      else
        v_module_id := v_module_table_id;
      end if;
      IF (v_CorrectType='Y') THEN
        RAISE NOTICE '%','Inserting Column:'||v_columnName||' to module:'||v_module_id;
      
        INSERT
        INTO AD_COLUMN
          (
            AD_COLUMN_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
            CREATED, CREATEDBY, UPDATED, UPDATEDBY,
            NAME, COLUMNNAME, AD_TABLE_ID,
            AD_REFERENCE_ID, FIELDLENGTH, ISKEY, ISPARENT,
            ISMANDATORY, ISIDENTIFIER, SEQNO, ISTRANSLATED,
            ISENCRYPTED, ISUPDATEABLE, AD_REFERENCE_VALUE_ID,
            AD_VAL_RULE_ID, DEFAULTVALUE, ISSESSIONATTR, 
            POSITION, aD_module_id
          )
          VALUES
          (v_NextNo, '0', '0', 'Y',
          TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
          v_columnName, v_columnName, Cur_Column.AD_Table_ID,
          v_AD_Reference_ID, v_FieldLength, v_IsKey, v_IsParent,
         'N',
          v_IsIdentifier, v_SeqNo, 'N', 'N', v_IsUpdateable, v_AD_Reference_Value_ID, 
          v_AD_Val_Rule_ID, v_DefaultValue, v_IsSessionAttr,
          Cur_Column.COLUMN_ID, v_module_id);
          --
          v_count:=v_count + 1;
      ELSE
        v_Result :=0;
        v_Message:=v_Message || '@WrongColumnType@: ' ||v_columnName||'. ';
      END IF;
      -- Added by Ismael Ciordia
      v_SeqNo:=v_SeqNo + 10;
      v_LastColumnName:=Cur_Column.Column_Name;
      -- Falta: insert de AD_Element
       RAISE NOTICE '%','adding Table ' || InitCap(Cur_Column.Table_Name) || ' Column ' || InitCap(Cur_Column.Column_Name) ;
      
    END LOOP; --  All new columns
    -- Summary info
    v_Message:=v_Message || '@Created@ = ' || v_count;
    
    
    --Check common columns
    IF (v_Record_ID is not null) THEN
      v_missingColumns := false;
      FOR Cur_CommonCols IN (select columnname
                              from ad_column c
                             where c.ad_table_id = '100'
                               and lower(c.columnname) in ('ad_client_id','ad_org_id','isactive','created','updated','createdby','updatedby')
                               and not exists (select 1 
                                                 from ad_column c1
                                                where c1.ad_table_id = v_Record_ID
                                                 and lower(c1.columnname) = lower(c.columnname))) LOOP
        v_missingColumns := true;
        v_Message := '@MissingCommonColumn@: '||Cur_CommonCols.columnname||'<br/>'||v_Message;
      END LOOP;
      
      select count(*)
        into v_count
        from ad_column c, ad_table t
       where lower(columnname) = lower(t.tablename)||'_id'
         and t.ad_table_id = c.ad_table_id
         and t.ad_table_id = v_Record_ID;
         
        IF v_Count = 0 THEN
          select tablename
            into v_TableName
            from ad_table
            where ad_table_id = v_record_ID;
            
          v_missingColumns := true;
          v_Message := '@MissingPrimaryKeyColumn@: '||v_tablename||'_ID<br/>'||v_Message;
        END IF;
        
        IF (v_MissingColumns) THEN
          v_Result :=0;
          v_Message := '@MissingRequiredColumns@<br/>'|| v_message;
        END IF;
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
--  RETURN;
END ; $_$;







SELECT zsse_DropView ('ad_column_v');
CREATE OR REPLACE VIEW ad_column_v AS
SELECT
 AD_COLUMN_ID as ad_column_v_id,
 AD_CLIENT_ID,
 AD_ORG_ID,
 isactive,
 CREATED,
 CREATEDBY,
 UPDATED,
 UPDATEDBY,
 DESCRIPTION,
 HELP,
 COLUMNNAME,
 AD_TABLE_ID,
 AD_REFERENCE_ID,
 AD_REFERENCE_VALUE_ID,
 AD_VAL_RULE_ID,
 FIELDLENGTH,
 DEFAULTVALUE,
 ISKEY,
 ISPARENT,
 READONLYLOGIC,
 ISIDENTIFIER,
 ISENCRYPTED,
 ISTRANSLATED,
 AD_ELEMENT_ID,
 AD_PROCESS_ID,
 ISSESSIONATTR,
 AD_CALLOUT_ID,
 DEVELOPMENTSTATUS,
 AD_MODULE_ID,
 seqno
from ad_column
union all
select 
 ad_customcolumn_id as ad_column_v_id,
 AD_CLIENT_ID,
 AD_ORG_ID,
 isactive,
 CREATED,
 CREATEDBY,
 UPDATED,
 UPDATEDBY,
null as DESCRIPTION,
null as HELP,
COLUMNNAME,
AD_TABLE_ID,
AD_REFERENCE_ID,
null as AD_REFERENCE_VALUE_ID,
null as AD_VAL_RULE_ID,
FIELDLENGTH,
null as DEFAULTVALUE,
'N'::character as ISKEY,
'N'::character as ISPARENT,
null as READONLYLOGIC,
'N'::character as ISIDENTIFIER,
'N'::character as ISENCRYPTED,
'N'::character as ISTRANSLATED,
null as AD_ELEMENT_ID,
null as AD_PROCESS_ID,
'N'::character as ISSESSIONATTR,
null as AD_CALLOUT_ID,
'RE'::varchar as DEVELOPMENTSTATUS,
AD_MODULE_ID,
null as seqno
from  ad_customcolumn;
 
CREATE OR REPLACE RULE ad_column_v_insert AS
ON INSERT TO ad_column_v DO INSTEAD
INSERT INTO ad_column(
  AD_COLUMN_ID,
 AD_CLIENT_ID,
 AD_ORG_ID,
 isactive,
 CREATED,
 CREATEDBY,
 UPDATED,
 UPDATEDBY,
 DESCRIPTION,
 HELP,
 COLUMNNAME,
 AD_TABLE_ID,
 AD_REFERENCE_ID,
 AD_REFERENCE_VALUE_ID,
 AD_VAL_RULE_ID,
 FIELDLENGTH,
 DEFAULTVALUE,
 ISKEY,
 ISPARENT,
 READONLYLOGIC,
 ISIDENTIFIER,
 ISENCRYPTED,
 ISTRANSLATED,
 AD_ELEMENT_ID,
 AD_PROCESS_ID,
 ISSESSIONATTR,
 AD_CALLOUT_ID,
 DEVELOPMENTSTATUS,
 AD_MODULE_ID,
 seqno
) VALUES ( NEW.ad_column_v_id,
 new.AD_CLIENT_ID,
 new.AD_ORG_ID,
 new.isactive,
 new.created,
 new.CREATEDBY,
 new.updated,
 new.UPDATEDBY,
 new.DESCRIPTION,
 new.HELP,
 new.COLUMNNAME,
 new.AD_TABLE_ID,
 new.AD_REFERENCE_ID,
 new.AD_REFERENCE_VALUE_ID,
 new.AD_VAL_RULE_ID,
 new.FIELDLENGTH,
 new.DEFAULTVALUE,
 new.ISKEY,
 new.ISPARENT,
 new.READONLYLOGIC,
 new.ISIDENTIFIER,
 new.ISENCRYPTED,
 new.ISTRANSLATED,
 new.AD_ELEMENT_ID,
 new.AD_PROCESS_ID,
 new.ISSESSIONATTR,
 new.AD_CALLOUT_ID,
 new.DEVELOPMENTSTATUS,
 new.AD_MODULE_ID,
 new.seqno
  );

CREATE OR REPLACE RULE ad_column_v_update AS
ON UPDATE TO ad_column_v DO INSTEAD
UPDATE ad_column SET
  AD_ORG_ID=new.AD_ORG_ID,
 isactive=new.isactive,
 created=new.created,
 CREATEDBY=new.CREATEDBY,
 updated=new.updated,
 UPDATEDBY=new.UPDATEDBY,
 DESCRIPTION=new.DESCRIPTION,
 HELP=new.HELP,
 COLUMNNAME=new.COLUMNNAME,
 AD_TABLE_ID=new.AD_TABLE_ID,
 AD_REFERENCE_ID=new.AD_REFERENCE_ID,
 AD_REFERENCE_VALUE_ID=new.AD_REFERENCE_VALUE_ID,
 AD_VAL_RULE_ID=new.AD_VAL_RULE_ID,
 FIELDLENGTH=new.FIELDLENGTH,
 DEFAULTVALUE=new.DEFAULTVALUE,
 ISKEY=new.ISKEY,
 ISPARENT=new.ISPARENT,
 READONLYLOGIC=new.READONLYLOGIC,
 ISIDENTIFIER=new.ISIDENTIFIER,
 ISENCRYPTED=new.ISENCRYPTED,
 ISTRANSLATED=new.ISTRANSLATED,
 AD_ELEMENT_ID=new.AD_ELEMENT_ID,
 AD_PROCESS_ID=new.AD_PROCESS_ID,
 ISSESSIONATTR=new.ISSESSIONATTR,
 AD_CALLOUT_ID=new.AD_CALLOUT_ID,
 DEVELOPMENTSTATUS=new.DEVELOPMENTSTATUS,
 AD_MODULE_ID=new.AD_MODULE_ID,
 seqno=new.seqno
WHERE ad_column_id=new.ad_column_v_id;
  

CREATE OR REPLACE RULE ad_column_v_delete AS
ON DELETE TO ad_column_v DO INSTEAD
DELETE FROM ad_column WHERE
  ad_column_id=old.ad_column_v_id;


SELECT zsse_DropView ('ad_field_v');
CREATE OR REPLACE VIEW ad_field_v AS
SELECT
 AD_FIELD_ID as ad_field_v_id,
 AD_CLIENT_ID,
 AD_ORG_ID,
 isactive,
 CREATED,
 CREATEDBY,
 UPDATED,
 UPDATEDBY,
 NAME,
 DESCRIPTION,
 ISCENTRALLYMAINTAINED,
 AD_TAB_ID,
 ad_column_id as ad_column_v_id,
 AD_FIELDGROUP_ID,
 ISDISPLAYED,
 DISPLAYLOGIC,
 DISPLAYLENGTH,
 ISREADONLY,
 SEQNO,
 ISSAMELINE,
 ISFIELDONLY,
 SHOWINRELATION,
 ISFIRSTFOCUSEDFIELD,
 AD_MODULE_ID,
 GRIDSEQNO,
 GRIDLENGTH,
 READONLYLOGIC,
 MANDANTORYLOGIC,
 DEFAULTVALUE,
 AD_CALLOUT_ID,
 AD_PROCESS_ID,
 ISIDENTIFIERCOLUMN,
 ISFILTERCOLUMN,
 FIELDREFERENCE,
 TABLEREFERENCE,
 VALIDATIONRULE,
 REFERENCEURL,
 TEMPLATE,
 MAXLENGTH,
 BUTTONCLASS,
 INCLUDESEMPTYITEM,
 STYLE,
 ONCHANGEEVENT,
 REQUIRED,
 COLSTOTAL,
 isdirectfilter
from ad_field
UNION ALL
SELECT
 ad_customfield_id as ad_field_v_id,
 AD_CLIENT_ID,
 AD_ORG_ID,
 isactive,
 CREATED,
 CREATEDBY,
 UPDATED,
 UPDATEDBY,
 NAME,
null as DESCRIPTION,
 'N'::character as  ISCENTRALLYMAINTAINED,
 AD_TAB_ID,
 ad_customcolumn_id as AD_COLUMN_v_ID,
 null as AD_FIELDGROUP_ID,
 'Y'::character as ISDISPLAYED,
 null as DISPLAYLOGIC,
 DISPLAYLENGTH,
 'N'::character as ISREADONLY,
 SEQNO,
 'N'::character as ISSAMELINE,
 'N'::character as ISFIELDONLY,
 'Y'::character as SHOWINRELATION,
 'N'::character  as ISFIRSTFOCUSEDFIELD,
 AD_MODULE_ID,
 null as GRIDSEQNO,
 GRIDLENGTH,
 null as READONLYLOGIC,
 null as MANDANTORYLOGIC,
 null as DEFAULTVALUE,
 null as AD_CALLOUT_ID,
 null as AD_PROCESS_ID,
 'N'::character as ISIDENTIFIERCOLUMN,
 'N'::character as ISFILTERCOLUMN,
 null as FIELDREFERENCE,
 null as TABLEREFERENCE,
 null as VALIDATIONRULE,
 null as REFERENCEURL,
 null as TEMPLATE,
 null as MAXLENGTH,
 null as BUTTONCLASS,
 'N'::character as INCLUDESEMPTYITEM,
 null as STYLE,
 null as ONCHANGEEVENT,
 'N'::character  as REQUIRED,
 COLSTOTAL,
 'N'::character  as isdirectfilter from ad_customfield;

CREATE OR REPLACE RULE ad_field_v_insert AS
ON INSERT TO ad_field_v DO INSTEAD
INSERT INTO ad_field(
   AD_FIELD_ID,
 AD_CLIENT_ID,
 AD_ORG_ID,
 isactive,
 CREATED,
 CREATEDBY,
 UPDATED,
 UPDATEDBY,
 NAME,
 DESCRIPTION,
 ISCENTRALLYMAINTAINED,
 AD_TAB_ID,
 AD_COLUMN_ID,
 AD_FIELDGROUP_ID,
 ISDISPLAYED,
 DISPLAYLOGIC,
 DISPLAYLENGTH,
 ISREADONLY,
 SEQNO,
 ISSAMELINE,
 ISFIELDONLY,
 SHOWINRELATION,
 ISFIRSTFOCUSEDFIELD,
 AD_MODULE_ID,
 GRIDSEQNO,
 GRIDLENGTH,
 READONLYLOGIC,
 MANDANTORYLOGIC,
 DEFAULTVALUE,
 AD_CALLOUT_ID,
 AD_PROCESS_ID,
 ISIDENTIFIERCOLUMN,
 ISFILTERCOLUMN,
 FIELDREFERENCE,
 TABLEREFERENCE,
 VALIDATIONRULE,
 REFERENCEURL,
 TEMPLATE,
 MAXLENGTH,
 BUTTONCLASS,
 INCLUDESEMPTYITEM,
 STYLE,
 ONCHANGEEVENT,
 REQUIRED,
 COLSTOTAL,
 isdirectfilter
) VALUES ( new.ad_field_v_id,
 new.AD_CLIENT_ID,
 new.AD_ORG_ID,
 new.isactive,
 new.CREATED,
 new.CREATEDBY,
 new.UPDATED,
 new.UPDATEDBY,
 new.NAME,
 new.DESCRIPTION,
 new.ISCENTRALLYMAINTAINED,
 new.AD_TAB_ID,
 new.AD_COLUMN_v_ID,
 new.AD_FIELDGROUP_ID,
 new.ISDISPLAYED,
 new.DISPLAYLOGIC,
 new.DISPLAYLENGTH,
 new.ISREADONLY,
 new.SEQNO,
 new.ISSAMELINE,
 new.ISFIELDONLY,
 new.SHOWINRELATION,
 new.ISFIRSTFOCUSEDFIELD,
 new.AD_MODULE_ID,
 new.GRIDSEQNO,
 new.GRIDLENGTH,
 new.READONLYLOGIC,
 new.MANDANTORYLOGIC,
 new.DEFAULTVALUE,
 new.AD_CALLOUT_ID,
 new.AD_PROCESS_ID,
 new.ISIDENTIFIERCOLUMN,
 new.ISFILTERCOLUMN,
 new.FIELDREFERENCE,
 new.TABLEREFERENCE,
 new.VALIDATIONRULE,
 new.REFERENCEURL,
 new.TEMPLATE,
 new.MAXLENGTH,
 new.BUTTONCLASS,
 new.INCLUDESEMPTYITEM,
 new.STYLE,
 new.ONCHANGEEVENT,
 new.REQUIRED,
 new.COLSTOTAL,
 new.isdirectfilter
  );

CREATE OR REPLACE RULE ad_field_v_update AS
ON UPDATE TO ad_field_v DO INSTEAD
UPDATE ad_field SET
 AD_CLIENT_ID=new.AD_CLIENT_ID,
 AD_ORG_ID=new.AD_ORG_ID,
 isactive=new.isactive,
 CREATED=new.CREATED,
 CREATEDBY=new.CREATEDBY,
 UPDATED=new.UPDATED,
 UPDATEDBY=new.UPDATEDBY,
 NAME=new.NAME,
 DESCRIPTION=new.DESCRIPTION,
 ISCENTRALLYMAINTAINED=new.ISCENTRALLYMAINTAINED,
 AD_TAB_ID=new.AD_TAB_ID,
 AD_COLUMN_ID=new.AD_COLUMN_v_ID,
 AD_FIELDGROUP_ID=new.AD_FIELDGROUP_ID,
 ISDISPLAYED=new.ISDISPLAYED,
 DISPLAYLOGIC=new.DISPLAYLOGIC,
 DISPLAYLENGTH=new.DISPLAYLENGTH,
 ISREADONLY=new.ISREADONLY,
 SEQNO=new.SEQNO,
 ISSAMELINE=new.ISSAMELINE,
 ISFIELDONLY=new.ISFIELDONLY,
 SHOWINRELATION=new.SHOWINRELATION,
 ISFIRSTFOCUSEDFIELD=new.ISFIRSTFOCUSEDFIELD,
 AD_MODULE_ID=new.AD_MODULE_ID,
 GRIDSEQNO=new.GRIDSEQNO,
 GRIDLENGTH=new.GRIDLENGTH,
 READONLYLOGIC=new.READONLYLOGIC,
 MANDANTORYLOGIC=new.MANDANTORYLOGIC,
 DEFAULTVALUE=new.DEFAULTVALUE,
 AD_CALLOUT_ID=new.AD_CALLOUT_ID,
 AD_PROCESS_ID=new.AD_PROCESS_ID,
 ISIDENTIFIERCOLUMN=new.ISIDENTIFIERCOLUMN,
 ISFILTERCOLUMN=new.ISFILTERCOLUMN,
 FIELDREFERENCE=new.FIELDREFERENCE,
 TABLEREFERENCE=new.TABLEREFERENCE,
 VALIDATIONRULE=new.VALIDATIONRULE,
 REFERENCEURL=new.REFERENCEURL,
 TEMPLATE=new.TEMPLATE,
 MAXLENGTH=new.MAXLENGTH,
 BUTTONCLASS=new.BUTTONCLASS,
 INCLUDESEMPTYITEM=new.INCLUDESEMPTYITEM,
 STYLE=new.STYLE,
 ONCHANGEEVENT=new.ONCHANGEEVENT,
 REQUIRED=new.REQUIRED,
 COLSTOTAL=new.COLSTOTAL,
 isdirectfilter=new.isdirectfilter
WHERE AD_FIELD_ID = new.ad_field_v_id;
  

CREATE OR REPLACE RULE ad_field_v_delete AS
ON DELETE TO ad_field_v DO INSTEAD
(
DELETE from ad_field_trl_instance WHERE ad_field_v_id = old.ad_field_v_id;
DELETE FROM ad_field WHERE
 AD_FIELD_ID = old.ad_field_v_id;
);

 
CREATE OR REPLACE FUNCTION ad_createcustomfield(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
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
Part of Projects, 
 Cancel Feedback for Project-Task
*****************************************************/
v_Record_ID varchar;
v_type varchar;
v_length numeric;
v_Message varchar:='Error';

v_table varchar;
v_tablename varchar;
v_org varchar;
v_user varchar;

v_name varchar;
v_count numeric;
v_ddlst varchar;
v_module varchar;
v_reference varchar;
v_uuid varchar;
v_colstotal varchar;
v_cur RECORD;
v_seq numeric;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID,ad_org_id into v_Record_ID,v_org,v_user from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    IF (v_Record_ID IS NOT NULL) then
        FOR v_cur IN (SELECT pi.Record_ID, p.ParameterName,  p.P_String,     p.P_Number,   p.P_Date   
                      FROM AD_PINSTANCE pi, AD_PINSTANCE_PARA p 
                      WHERE pi.AD_PInstance_ID=p.AD_PInstance_ID and pi.AD_PInstance_ID=p_PInstance_ID
        )
      LOOP
        if v_cur.ParameterName='datatype' then v_type:=v_cur.P_String; end if; -- c_project.value
        if v_cur.ParameterName='length' then v_length:=v_cur.P_Number; end if; 
      END LOOP; -- Get Parameter
    END if;
    select ad_table_id,ad_module_id into v_table,v_module from ad_tab where ad_tab_id=v_Record_ID;
    if v_table='114' then
        raise exception '%', 'Creating Custom Column on this table is not possible';
    end if;
    select max(to_number(substr(columnname,12,length(columnname))))+1 into v_count from ad_customcolumn where ad_table_id=v_table;
    select tablename into v_tablename from ad_table where ad_table_id=v_table;
    
    v_name:='customfield'||coalesce(v_count,1);
    if v_length>2000 then
        raise exception 'Length is limited to 2000';
    end if;
    if (v_length is null or v_length=0) and v_type='VARCHAR' then
        raise exception 'You need to give the Length for Character Datatype';
    end if;
    if v_type='TIMESTAMP' then
        v_ddlst:=' TIMESTAMP without time zone';
        v_reference:='15';
        v_colstotal:='2';
        v_length:=10;
    end if;
    if v_type='NUMERIC' then
        v_ddlst:=' NUMERIC';
        v_reference:='12';
        v_colstotal:='2';
        v_length:=20;
    end if;
    if v_type='VARCHAR' then
        v_ddlst:=' VARCHAR('||v_length||')';
        v_reference:='10';
        if v_length<30 then 
            v_colstotal:='2';
        else 
            if v_length>=30 and v_length<60 then 
                v_colstotal:='3';
            else
                v_colstotal:='6';
            end if;
        end if;
    end if;
    select get_uuid() into v_uuid;
    select max(seqno)+10 into v_seq from ad_field_v where ad_tab_id=v_Record_ID;
    if (select count(*) from INFORMATION_SCHEMA.views where table_name=v_tablename)=0 then
        execute 'alter table ' || v_tablename || ' add column '||v_name||v_ddlst;
    end if;
    insert into ad_customcolumn(AD_CUSTOMCOLUMN_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, COLUMNNAME, FIELDLENGTH, AD_REFERENCE_ID, AD_TABLE_ID, AD_MODULE_ID)
    values(v_uuid,'0','0',v_user,v_user,v_name,v_length,v_reference,v_table,v_module);
    insert into ad_customfield(AD_CUSTOMFIELD_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME, AD_TAB_ID, AD_CUSTOMCOLUMN_ID, AD_MODULE_ID,
                               colstotal, gridlength, SEQNO, displaylength )
    values (get_uuid(),'0','0',v_user,v_user,v_name,v_Record_ID,v_uuid,v_module,v_colstotal,v_length,v_seq,v_length);

    v_Message:='Sucess - Column '||v_name||' created';
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

CREATE OR REPLACE FUNCTION ad_dropcustomfield(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
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
Part of Projects, 
 Cancel Feedback for Project-Task
*****************************************************/
v_Record_ID varchar;
v_name varchar;
v_Message varchar:='Error';
v_ccol_id varchar;
v_cfield_id varchar;
v_atblename varchar;
v_table_id varchar;
v_cur RECORD;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID into v_Record_ID from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    IF (v_Record_ID IS NOT NULL) then
        FOR v_cur IN (SELECT pi.Record_ID, p.ParameterName,  p.P_String,     p.P_Number,   p.P_Date   
                      FROM AD_PINSTANCE pi, AD_PINSTANCE_PARA p 
                      WHERE pi.AD_PInstance_ID=p.AD_PInstance_ID and pi.AD_PInstance_ID=p_PInstance_ID
        )
      LOOP
        if v_cur.ParameterName='ad_field_v_id' then v_cfield_id:=v_cur.P_String; end if; -- c_project.value
      END LOOP; -- Get Parameter
    END if;
    select name,ad_customcolumn_id into v_name,v_ccol_id from ad_customfield where ad_customfield_id=v_cfield_id;
    select ad_table_id into v_table_id from ad_customcolumn where ad_customcolumn_id=v_ccol_id;
    if v_table_id='114' then
        raise exception '%', 'Dropping Custom Column on this table is not possible';
    end if;
    select tablename into v_atblename from ad_table where ad_table_id=v_table_id;
    delete from ad_fieldinstance where ad_field_v_id=v_cfield_id;
    DELETE from ad_field_trl_instance WHERE ad_field_v_id = v_cfield_id;
    delete from ad_customcolumn where ad_customcolumn_id=v_ccol_id;
    if (select count(*) from INFORMATION_SCHEMA.views where table_name=v_atblename)=0 then
        execute 'alter table ' || v_atblename || ' drop column '||v_name;
    end if;
    v_Message:='Sucess - Column '||v_name||' dropped';
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
  

CREATE OR REPLACE FUNCTION ad_labellinkdispatcher_mod_trg() RETURNS trigger LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
********************************************************************************************************************************************************************************/
v_count numeric;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    IF TG_OP = 'UPDATE' or TG_OP = 'INSERT' then
         select count(*) into v_count from ad_column where ad_column_id=new.ad_column_v_id and iskey='Y';
         If v_count=0 then
              raise exception '%', 'Dispatching Link is only for Key Columns possible!';
         end if;
         select count(*) into v_count from ad_column a,ad_column b, ad_tab c where c.ad_tab_id=new.ad_tab_id and c.ad_table_id=b.ad_table_id 
               and a.ad_column_id=new.ad_column_v_id and upper(a.columnname)=upper(b.columnname);
         if v_count=0 then
             raise exception 'Dispatching Link not possible: The selected Tab does not contain the column you want to dispatch.';
         end if;  
         if new.linkcondition is not null and (instr(new.linkcondition,'@KEYVALUE@') = 0 or upper(substr(new.linkcondition,1,6))!='SELECT' or  instr(upper(new.linkcondition),'RETVAL') = 0)  then
             raise exception '%', 'Dispatching Link is not possible! Use Plain sql that Returns the string TRUE in the Column RETVAL, if fitting condition. The only fixed Var u  must use is the key value. Indicate This with @KEYVALUE@ ----- EXAMPLE: select case count(*) when 1 then '||chr(39)||'TRUE'||chr(39)||' else '||chr(39)||'FALSE'||chr(39)||' end as retval from a_asset where  a_asset_id='||chr(39)||'@KEYVALUE@'||chr(39);
         end if;
         if new.linkcondition is null and new.isdefault='N'  then
             raise exception '%', 'Dispatching Link is not possible! Use Either sql in Field Linkcondition or define TAB as Default and leave Linkcondition Blank';
         end if;
    end if;
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

select zsse_droptrigger('ad_labellinkdispatcher_mod_trg','ad_labellinkdispatcher');

CREATE TRIGGER ad_labellinkdispatcher_mod_trg
  BEFORE INSERT OR UPDATE 
  ON ad_labellinkdispatcher
  FOR EACH ROW
  EXECUTE PROCEDURE ad_labellinkdispatcher_mod_trg();

CREATE OR REPLACE FUNCTION ad_getParentID(p_parenttablename character varying,p_childtabelname character varying,p_currentvalue character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2021 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur record;
v_sql character varying;
v_result character varying;
BEGIN
      if p_parenttablename is null then
        return 'COMPILE';
      end if;
      v_sql:='select '||p_parenttablename||'_id as retval from '||p_childtabelname||' where '||p_childtabelname||'_id = '|| chr(39)||coalesce(p_currentvalue,'')||chr(39);
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_result:=v_cur.retval;
      END LOOP;
      close v_cursor;
  RETURN v_result;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;  
  
CREATE OR REPLACE FUNCTION ad_getReferenceLinkTargetTab(p_table_id character varying,p_currentvalue character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_count numeric;
v_lopcur RECORD;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_sql character varying;
v_keycolumname character varying;
v_columnid character varying;
v_tablename character varying;
v_default_tab character varying;
v_result character varying;
BEGIN
  select ad_column.ad_column_id into v_columnid from ad_labellinkdispatcher,ad_column where ad_column.ad_column_id=ad_labellinkdispatcher.ad_column_v_id and ad_column.ad_table_id=p_table_id;
  if v_columnid is not null  then
      select columnname,tablename into v_keycolumname,v_tablename from ad_column,ad_table where 
              ad_table.ad_table_id=ad_column.ad_table_id and iskey='Y' and ad_table.ad_table_id=p_table_id;
      v_sql:='select count(*) as retval from '||v_tablename||' where '||v_keycolumname||' = '|| chr(39)||coalesce(p_currentvalue,'')||chr(39);
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_count:=v_cur.retval;
      END LOOP;
      close v_cursor;
      if v_count>0 then
         select ad_tab_id into v_default_tab from ad_labellinkdispatcher  WHERE ad_column_v_id=v_columnid and isactive='Y' and isdefault='Y';
         FOR v_lopcur IN (SELECT * FROM ad_labellinkdispatcher  WHERE ad_column_v_id=v_columnid and isactive='Y' and linkcondition is not null)
         LOOP
            v_sql:=v_lopcur.linkcondition;
            v_sql=replace(v_sql, '@KEYVALUE@',p_currentvalue);
            OPEN v_cursor FOR EXECUTE v_sql;
            LOOP
                  FETCH v_cursor INTO v_cur;
                  EXIT WHEN NOT FOUND;
                  v_result:=v_cur.retval;
            END LOOP;
            close v_cursor;
            if upper(v_result)='TRUE' then
               return v_lopcur.ad_tab_id;
            end if;          
          END LOOP;
       end if;
  end if;
  RETURN v_default_tab;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_ReferenceGetTableID(p_reference character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_reftype character varying;
v_tablename character varying;
v_retval   character varying:='';
BEGIN
  select validationtype into v_reftype from ad_reference where ad_reference_id=p_reference;
  if v_reftype is null then
     -- we assume direct table link
     if substr(upper(p_reference),length(p_reference)-2,length(p_reference))='_ID' then
         v_tablename:=substr(upper(p_reference),1,length(p_reference)-3);
         select ad_table_id into v_retval from ad_table where upper(tablename)=v_tablename;
     end if;
  else
     -- Search
     if v_reftype='S' then
        select  ad_table_id into  v_retval from ad_ref_search where ad_reference_id=p_reference;
     end if;
     -- Table Link
     if v_reftype='T' then
        select  ad_table_id into v_retval from ad_ref_table where ad_reference_id=p_reference;
     end if;
  end if;
  RETURN v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION ad_modobjmapping_mod_trg() RETURNS trigger LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
********************************************************************************************************************************************************************************/
 
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    IF TG_OP = 'UPDATE' or TG_OP = 'INSERT' then
         If new.isdefault='Y' and (select count(*) from ad_model_object_mapping where ad_model_object_id=new.ad_model_object_id and ad_model_object_mapping_id!=new.ad_model_object_mapping_id and isdefault='Y')>0 then
              raise exception 'No Duplicate Default Mapping possible!';
         end if;
    end if;
    
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

CREATE OR REPLACE FUNCTION ad_ref_list_mod_trg() RETURNS trigger LANGUAGE plpgsql    AS $_$ DECLARE 
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
* All portions are Copyright (C) 2008-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): 2018 S.Zimmermann.
************************************************************************/
  devTemplate NUMERIC;
  devModule   CHAR(1);
  cuerrentModuleID  VARCHAR(32); --OBTG:VARCHAR2--
  vAux NUMERIC;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  --Check if trying to move object from module not in dev
  IF (TG_OP = 'UPDATE') THEN
    IF (COALESCE(NEW.AD_Module_ID , '.') != COALESCE(OLD.AD_Module_ID , '.')) THEN
      SELECT COUNT(*) 
        INTO vAux
        FROM AD_MODULE
       WHERE AD_MODULE_ID = old.AD_Module_ID
        AND isindevelopment = 'N';
      IF (vAux!=0) THEN
        RAISE EXCEPTION '%', '@ChangeNotInDevModule@'; --OBTG:-20000--
      END IF;
    END IF;
  END IF;

  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE
   WHERE IsInDevelopment = 'Y'
     AND Type = 'T';
     
  IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    cuerrentModuleID := new.AD_Module_ID;
  ELSE
    cuerrentModuleID := old.AD_Module_ID;
  END IF;
  
  SELECT M.IsInDevelopment
    INTO devModule
    FROM AD_MODULE M
   WHERE M.AD_MODULE_ID = cuerrentModuleID;
     
  IF (TG_OP = 'UPDATE' AND devTemplate=0 AND devModule='N') THEN
    IF (
        COALESCE(NEW.AD_Client_ID , '.') != COALESCE(OLD.AD_Client_ID , '.') OR
        COALESCE(NEW.AD_Org_ID , '.') != COALESCE(OLD.AD_Org_ID , '.') OR
        COALESCE(NEW.IsActive , '.') != COALESCE(OLD.IsActive , '.') OR
        COALESCE(NEW.Value , '.') != COALESCE(OLD.Value , '.') OR
        COALESCE(NEW.Name , '.') != COALESCE(OLD.Name , '.') OR
        COALESCE(NEW.Description , '.') != COALESCE(OLD.Description , '.') OR
        COALESCE(NEW.AD_Reference_ID , '.') != COALESCE(OLD.AD_Reference_ID , '.') 
        ) THEN
      RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
  END IF;
  
  IF ((TG_OP = 'DELETE' OR TG_OP = 'INSERT') AND devModule='N') THEN
    RAISE EXCEPTION '%', 'Cannot insert/delete objects in a module not in development.'; --OBTG:-20533--
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;

CREATE OR REPLACE FUNCTION ad_tab_import(p_pinstance_id character varying, p_ad_tab_id character varying) RETURNS void
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
  * Contributor(s): Openbravo SL, Zimmermann-Software
  * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
  * Contributions are Copyright (C) 2012 Zimmermann-Software
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: AD_Tab_Import.sql,v 1.4 2002/11/18 06:11:18 jjanke Exp $
  ***
  * Title: Import Field Definitions
  * Description:
  *   Import the Fields of the Tab not existing yet
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_AD_User_ID VARCHAR(32):='0'; --OBTG:VARCHAR2--
  v_module_id VARCHAR(32); --OBTG:varchar2--
  v_Aux NUMERIC;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    -- Variables
    Cur_Column RECORD;
    --
    v_NextNo VARCHAR(32) ; --OBTG:VARCHAR2--
    v_AD_Table_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_count NUMERIC(10):=0;
    -- added by Pablo Sarobe
    v_isDisplayed CHAR(1):='Y';
    v_showInRelation CHAR(1):='Y';
    v_isReadOnly CHAR(1):='N';
    v_sameLine CHAR(1):='N';
    v_SeqNo NUMERIC(10) ;
    v_sortNo NUMERIC(10) ;
    v_columnName VARCHAR(40) ; --OBTG:VARCHAR2--
    v_LastColumnName VARCHAR(40) ; --OBTG:VARCHAR2--
    v_DisplayLength NUMERIC(10) ;
    v_PInstance_Log_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      v_ResultStr:='PInstanceNotFound';
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
      -- Get Parameters
      v_ResultStr:='ReadingParameters';
      FOR Cur_Parameter IN
        (SELECT i.Record_ID, i.AD_User_ID, p.ParameterName, p.P_String, p.P_Number, p.P_Date, p.AD_CLIENT_ID
        FROM AD_PInstance i
        LEFT JOIN AD_PInstance_Para p
          ON i.AD_PInstance_ID=p.AD_PInstance_ID
        WHERE i.AD_PInstance_ID=p_PInstance_ID
        ORDER BY p.SeqNo
        )
      LOOP
        v_Record_ID:=Cur_Parameter.Record_ID;
        v_AD_User_ID:=Cur_Parameter.AD_User_ID;
        v_Client_ID:=Cur_Parameter.AD_CLIENT_ID;
      END LOOP; -- Get Parameter
    ELSE
      v_Record_ID:=p_AD_Tab_ID;
    END IF;
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
  BEGIN --BODY
   select ad_module_id
     into v_module_id
     from ad_tab t
    where ad_tab_id = v_Record_ID;
  
  
    SELECT AD_Table_ID
    INTO v_AD_Table_ID
    FROM AD_Tab
    WHERE AD_Tab_ID=v_Record_ID  AND AD_Table_ID!='291'; -- C_BPartner (multiple tabs)
    
    FOR Cur_Column IN(-- added by Pablo Sarobe
    SELECT c.Columnname, c.Name, c.Description, c.AD_Column_ID, c.FieldLength, t.tablename, c.AD_Module_ID
    FROM AD_Column c, AD_Table t
    WHERE NOT EXISTS
      (SELECT *
      FROM AD_Field f
      WHERE c.AD_Column_ID=f.AD_Column_ID  AND c.AD_Table_ID=v_AD_Table_ID  AND f.AD_Tab_ID=v_Record_ID
      )
      AND c.AD_Table_ID=v_AD_Table_ID  AND c.AD_Table_ID=t.AD_Table_ID  -- added by Pablo Sarobe
      AND UPPER(c.Columnname) NOT IN ('CREATED', 'UPDATED', 'CREATEDBY', 'UPDATEDBY') AND c.IsActive='Y')
    LOOP
      SELECT * INTO  v_NextNo FROM AD_Sequence_Next('AD_Field', '0') ; -- get ID
      -- added by Pablo Sarobe
      v_isDisplayed:='Y';
      v_showInRelation:='Y';
      v_isReadOnly:='N';
      v_sameLine:='N';
      v_SeqNo:=0;
      v_sortNo:=NULL;
      v_DisplayLength:=Cur_Column.FieldLength;
      IF(UPPER(Cur_Column.Columnname)=UPPER(Cur_Column.Tablename) ||'_ID') THEN --ID column
        v_isDisplayed:='N';
        v_showInRelation:='N';
        IF(UPPER(Cur_Column.Columnname) IN('M_PRODUCT_ID', 'C_BPARTNER_ID')) THEN
          v_DisplayLength:=40;
        ELSIF(UPPER(Cur_Column.Columnname) IN('C_LOCATION_ID', 'C_BPARTNER_LOCATION_ID')) THEN
          v_DisplayLength:=60;
        END IF;
      ELSIF(UPPER(Cur_Column.Columnname)='AD_CLIENT_ID') THEN
        v_SeqNo:=10;
        v_showInRelation:='N';
      ELSIF(UPPER(Cur_Column.Columnname)='AD_ORG_ID') THEN
        v_SeqNo:=20;
        v_sameLine:='Y';
        v_showInRelation:='N';
      ELSIF(UPPER(Cur_Column.Columnname)='LINENO') THEN
        v_DisplayLength:=5;
      ELSIF(UPPER(Cur_Column.Columnname) IN('VALUE', 'ALIAS', 'SEQNO')) THEN
        v_sortNo:=1;
        IF(UPPER(Cur_Column.Columnname) IN('VALUE')) THEN
          v_DisplayLength:=20;
        END IF;
      END IF;
      IF(UPPER(v_LastColumnName)='UPDATEDBY' AND UPPER(Cur_Column.Columnname) LIKE '%_ID') THEN
        v_isReadOnly:='Y';
      END IF;
      
  
      INSERT
      INTO AD_Field
        (
          ad_field_id, ad_client_id, ad_org_id, isactive,
          created, createdby, updated, updatedby,
          name, description, seqno, AD_Tab_ID,
          AD_Column_ID, DisplayLength, IsCentrallyMaintained,
          isdisplayed, isreadonly, sortno, issameline, showinrelation, ad_module_id,colstotal
        )
        VALUES
        (v_NextNo, '0', '0', 'Y',
        TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
        Cur_Column.Name, Cur_Column.Description, v_SeqNo, v_Record_ID,
        Cur_Column.AD_Column_ID, v_DisplayLength, 'Y', 
        v_isDisplayed, v_isReadOnly, v_sortNo, v_sameLine, v_showInRelation, v_module_id,3) ;
      --
      v_count:=v_count + 1;
      -- Added by Pablo Sarobe
      v_LastColumnName:=Cur_Column.Columnname;

    END LOOP; --  for all columns
    -- Summary info
    v_Message:='@Created@ = ' || v_count;
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

  SELECT AD_TABLE_ID INTO v_AD_TABLE_ID FROM AD_Tab WHERE AD_Tab_ID=v_Record_ID;
  IF (v_AD_Table_ID='291') THEN
    RAISE EXCEPTION '%', v_ResultStr ; --OBTG:-20507--
  END IF;
--  RETURN;
END ; $_$;

CREATE OR REPLACE FUNCTION ad_form_trg2() RETURNS trigger
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
* Contributions: Correct model Object Mapping to Module
****************************************************************************************************************************************************/
  v_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  v_WindowName VARCHAR(60):='ad_forms'; --OBTG:VARCHAR2--
  v_ClassName  AD_MODEL_OBJECT.classname%TYPE;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF(TG_OP = 'UPDATE') THEN
    IF NOT(COALESCE(old.NAME, '.') <> COALESCE(NEW.NAME, '.')
   OR COALESCE(old.IsActive, '.') <> COALESCE(NEW.IsActive, '.')
   OR COALESCE(old.CLASSNAME, '.') <> COALESCE(NEW.CLASSNAME, '.'))
  THEN
      IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  END IF;
  IF (TG_OP = 'UPDATE') THEN
    UPDATE AD_MODEL_OBJECT_MAPPING
    SET ISACTIVE = new.isactive
    WHERE AD_MODEL_OBJECT_ID IN
      (
      SELECT AD_MODEL_OBJECT_ID
      FROM AD_MODEL_OBJECT
      WHERE AD_MODEL_OBJECT.AD_FORM_ID=old.AD_FORM_ID
        AND ACTION='X'
      );
    UPDATE AD_MODEL_OBJECT
    SET ISACTIVE = new.isactive
    WHERE ACTION='X'
      AND AD_MODEL_OBJECT.AD_FORM_ID=OLD.AD_FORM_ID;
  END IF;
  IF(TG_OP = 'DELETE') THEN
    DELETE
    FROM AD_MODEL_OBJECT_MAPPING
    WHERE AD_MODEL_OBJECT_ID IN
      (
      SELECT AD_MODEL_OBJECT_ID
      FROM AD_MODEL_OBJECT
      WHERE AD_MODEL_OBJECT.AD_FORM_ID=old.AD_FORM_ID
        AND ACTION='X'
      )
      ;
    DELETE
    FROM AD_MODEL_OBJECT
    WHERE ACTION='X'
      AND AD_MODEL_OBJECT.AD_FORM_ID=OLD.AD_FORM_ID;
  END IF;
  IF(TG_OP = 'INSERT') THEN
    v_ClassName:=new.CLASSNAME;
    
    --Calculate mapping name
    IF new.AD_Module_ID != '0' THEN
      SELECT javapackage||'.'||v_WindowName
        INTO v_WindowName
        FROM AD_MODULE 
       WHERE AD_Module_ID = new.AD_Module_ID;
    END IF;
    
    v_ID := get_uuid();
    INSERT
    INTO AD_MODEL_OBJECT
      (
        AD_MODEL_OBJECT_ID, AD_CLIENT_ID, AD_ORG_ID,
        ISACTIVE, CREATED, CREATEDBY,
        UPDATED, UPDATEDBY, ACTION,
        AD_FORM_ID, CLASSNAME, ISDEFAULT,ad_module_id
      )
      VALUES
      (
        v_ID, new.AD_CLIENT_ID, new.AD_ORG_ID,
        new.ISACTIVE, TO_DATE(NOW()), new.CREATEDBY,
        TO_DATE(NOW()), new.UPDATEDBY, 'X',
        new.AD_FORM_ID, v_ClassName, 'Y',new.ad_module_id
      )
      ;
    
    INSERT
    INTO AD_MODEL_OBJECT_MAPPING
      (
        AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
        ISACTIVE, CREATED, CREATEDBY,
        UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID,
        MAPPINGNAME, ISDEFAULT
      )
      VALUES
      (
        get_uuid(), new.AD_CLIENT_ID, new.AD_ORG_ID,
        new.ISACTIVE, TO_DATE(NOW()), new.CREATEDBY,
        TO_DATE(NOW()), new.UPDATEDBY, v_ID,
        ('/' || v_WindowName || '/' || AD_MAPPING_FORMAT(NEW.NAME) || '.html'), 'Y'
      )
      ;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

CREATE OR REPLACE FUNCTION ad_callout_trg() RETURNS trigger
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
* Contributions: Correct model Object Mapping to Module
****************************************************************************************************************************************************/
  v_ClassName  VARCHAR(60) ; --OBTG:VARCHAR2--
  v_dir VARCHAR(200); --OBTG:VARCHAR2--
  v_package VARCHAR(200); --OBTG:VARCHAR2--
  v_ID VARCHAR(32); --OBTG:VARCHAR2--
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF(TG_OP = 'UPDATE') THEN
    IF(NOT(COALESCE(old.Name, '.') <> COALESCE(NEW.Name, '.')
   OR COALESCE(old.IsActive, '.') <> COALESCE(NEW.IsActive, '.')))
  THEN
      IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  END IF;

  IF(TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
    IF OLD.ISACTIVE='Y' THEN
      DELETE
      FROM AD_MODEL_OBJECT_MAPPING
      WHERE AD_MODEL_OBJECT_ID IN
        (
        SELECT AD_MODEL_OBJECT_ID
        FROM AD_MODEL_OBJECT
        WHERE AD_MODEL_OBJECT.AD_CALLOUT_ID=old.AD_CALLOUT_ID
          AND ACTION='C'
        )
        ;
      DELETE
      FROM AD_MODEL_OBJECT
      WHERE ACTION='C'
        AND AD_MODEL_OBJECT.AD_CALLOUT_ID=OLD.AD_CALLOUT_ID;
    END IF;
  END IF;
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    IF NEW.ISACTIVE='Y' THEN
      IF NEW.AD_MODULE_ID != '0' THEN
        SELECT JavaPackage
          INTO v_package
          FROM AD_MODULE
        WHERE AD_MODULE_ID = NEW.AD_MODULE_ID;
          v_dir := v_package||'.ad_callouts';
      ELSE
        v_package := 'org.openbravo.erpCommon.ad_callouts';
        v_dir := 'ad_callouts';
      END IF;
    
      v_ClassName:=AD_MAPPING_FORMAT(TO_CHAR(new.NAME)) ;

      v_ID := get_uuid();
      
      INSERT
      INTO AD_MODEL_OBJECT
        (
          AD_MODEL_OBJECT_ID, AD_CLIENT_ID, AD_ORG_ID,
          ISACTIVE, CREATED, CREATEDBY,
          UPDATED, UPDATEDBY, ACTION,
          AD_CALLOUT_ID, CLASSNAME, ISDEFAULT,ad_module_id
        )
        VALUES
        (
          v_ID, new.AD_CLIENT_ID, new.AD_ORG_ID,  'Y',
          TO_DATE(NOW()), new.CREATEDBY, TO_DATE(NOW()),
          new.UPDATEDBY,  'C', new.AD_CALLOUT_ID,
           v_package || '.' || v_ClassName, 'Y',new.ad_module_id
        )
        ;

      INSERT
      INTO AD_MODEL_OBJECT_MAPPING
        (
          AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
          ISACTIVE, CREATED, CREATEDBY,
          UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID,
          MAPPINGNAME, ISDEFAULT
        )
        VALUES
        (
          get_uuid(), new.AD_CLIENT_ID, new.AD_ORG_ID,
           'Y', TO_DATE(NOW()), new.CREATEDBY,
          TO_DATE(NOW()), new.UPDATEDBY, v_ID,
          ('/' || v_dir || '/' || v_ClassName || '.html'), 'Y'
        )
        ;
    END IF;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;




CREATE OR REPLACE FUNCTION ad_reference_trg2() RETURNS trigger
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
* Contributions: Correct model Object Mapping to Module
****************************************************************************************************************************************************/
 v_ID       VARCHAR(32); --OBTG:varchar2--
 v_WindowName     VARCHAR(60):= 'info'; --OBTG:VARCHAR2--
 v_ClassName     VARCHAR(60); --OBTG:VARCHAR2--
 v_JavaPackage VARCHAR(500); --OBTG:varchar2--
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF (TG_OP = 'UPDATE') THEN
    IF NOT((COALESCE(old.NAME,'.')<>COALESCE(NEW.NAME,'.')
   OR COALESCE(old.VALIDATIONTYPE,'.')<>COALESCE(NEW.VALIDATIONTYPE,'.')
   OR COALESCE(old.IsActive,'.')<>COALESCE(NEW.IsActive,'.')))
  THEN
      IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  END IF;

 IF (TG_OP = 'DELETE') THEN
  IF OLD.VALIDATIONTYPE='S' AND OLD.ISACTIVE='Y' THEN
   DELETE FROM AD_MODEL_OBJECT_MAPPING WHERE AD_MODEL_OBJECT_ID IN (
      SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_REFERENCE_ID=old.AD_REFERENCE_ID AND ACTION = 'S');
   DELETE FROM AD_MODEL_OBJECT WHERE ACTION = 'S' AND AD_MODEL_OBJECT.AD_REFERENCE_ID = OLD.AD_REFERENCE_ID;
  END IF;
 END IF;

 IF (TG_OP = 'INSERT') THEN
  IF NEW.VALIDATIONTYPE='S' AND NEW.ISACTIVE='Y' THEN
    IF new.AD_Module_ID != '0' THEN
      SELECT ad_mapping_format(javapackage||'.info')
        INTO v_javapackage
        FROM AD_MODULE 
       WHERE AD_Module_ID = new.AD_Module_ID;
       v_WindowName := v_javapackage;
    ELSE 
      v_javapackage := 'org.openbravo.erpCommon.info';
    END IF;
  
   v_ClassName := AD_MAPPING_FORMAT(TO_CHAR(NEW.NAME));
   v_ID := get_uuid();
   INSERT INTO AD_MODEL_OBJECT (AD_MODEL_OBJECT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY,
   UPDATED, UPDATEDBY, ACTION, AD_REFERENCE_ID, CLASSNAME, ISDEFAULT,ad_module_id)
   VALUES (v_ID, new.AD_CLIENT_ID, new.AD_ORG_ID, 'Y', TO_DATE(NOW()), new.CREATEDBY,
   TO_DATE(NOW()), new.UPDATEDBY, 'S', new.AD_REFERENCE_ID, v_javapackage || '.' || v_ClassName, 'Y',new.ad_module_id);

   INSERT INTO AD_MODEL_OBJECT_MAPPING (AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
   ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID, MAPPINGNAME, ISDEFAULT)
   VALUES (get_uuid(), new.AD_CLIENT_ID, new.AD_ORG_ID, 'Y', TO_DATE(NOW()), new.CREATEDBY,
   TO_DATE(NOW()), new.UPDATEDBY, v_ID, ('/' || v_WindowName || '/' || v_ClassName || '.html'), 'Y');
  END IF;
 END IF;

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;

CREATE OR REPLACE FUNCTION ad_tab_trg2() RETURNS trigger
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
* Contributions: Correct model Object Mapping to Module
****************************************************************************************************************************************************/
 v_ID       VARCHAR(32); --OBTG:varchar2--
 v_ID_MAP      VARCHAR(32); --OBTG:VARCHAR2--
 v_WindowName     VARCHAR(60); --OBTG:VARCHAR2--
 v_ClassName     VARCHAR(60); --OBTG:VARCHAR2--
 v_IsActive      CHAR(1) := 'Y';
 v_Count       NUMERIC(10);
 v_JavaPackage VARCHAR(315); --OBTG:VARCHAR2--
 v_ModuleMapping VARCHAR(315); --OBTG:VARCHAR2--
   
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  IF (TG_OP = 'UPDATE') THEN
   if (new.ad_module_id!=old.ad_module_id) then
      update ad_field set ad_module_id=new.ad_module_id where ad_tab_id=new.ad_tab_id;
   end if;
  END IF;
  IF (TG_OP = 'UPDATE') THEN
    IF NOT((COALESCE(old.NAME,'.')<>COALESCE(NEW.NAME,'.') OR COALESCE(old.IsActive,'.')<>COALESCE(NEW.IsActive,'.'))) THEN
      IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    SELECT W.IsActive, 
           (CASE WHEN M.AD_MODULE_ID ='0' THEN NULL ELSE JavaPackage END)
    INTO v_IsActive, v_JavaPackage
    FROM AD_WINDOW W, AD_MODULE M
    WHERE AD_WINDOW_ID = NEW.AD_WINDOW_ID
     AND W.AD_MODULE_ID = M.AD_MODULE_ID;


    
    IF v_IsActive <> 'Y' THEN
      v_IsActive := NEW.ISACTIVE;
    END IF;

    SELECT AD_MAPPING_FORMAT(TO_CHAR(W.NAME)), 
           AD_MAPPING_FORMAT(TO_CHAR(new.NAME))
    INTO v_WindowName, v_ClassName
    FROM AD_WINDOW W
    WHERE W.AD_WINDOW_ID = new.AD_WINDOW_ID;
    
    --Add tab id to name for non core modules
    IF (new.AD_Module_ID != '0') THEN
      v_ClassName := v_ClassName || new.AD_Tab_ID;
    END IF;
    
    IF v_JavaPackage IS NOT NULL THEN
      v_ModuleMapping := '/'||v_JavaPackage||'.';
      v_JavaPackage := v_JavaPackage||'.'||v_WindowName;
    ELSE
      v_ModuleMapping := '/';
      v_JavaPackage := v_WindowName;
    END IF;


    SELECT COUNT(*) INTO v_Count
    FROM AD_MODEL_OBJECT
    WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W'
    AND CLASSNAME LIKE 'org.openbravo.erpWindows.%';

    IF v_Count > 0 THEN
      SELECT AD_MODEL_OBJECT_ID INTO v_ID
      FROM AD_MODEL_OBJECT
      WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W'
      AND CLASSNAME LIKE 'org.openbravo.erpWindows.%';

      
      UPDATE AD_MODEL_OBJECT
      SET AD_CLIENT_ID = new.AD_CLIENT_ID,
        AD_ORG_ID = new.AD_ORG_ID,
        ISACTIVE = v_IsActive,
        UPDATED = TO_DATE(NOW()),
        UPDATEDBY = new.UPDATEDBY,
        CLASSNAME = 'org.openbravo.erpWindows.' || v_JavaPackage || '.' || v_ClassName
      WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W'
      AND CLASSNAME LIKE 'org.openbravo.erpWindows.%';

    ELSE
      SELECT * INTO  v_ID FROM Ad_Sequence_Next('AD_Model_Object', new.AD_Client_ID);
      INSERT INTO AD_MODEL_OBJECT (AD_MODEL_OBJECT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY,
      UPDATED, UPDATEDBY, ACTION, AD_TAB_ID, CLASSNAME, ISDEFAULT,ad_module_id)
      VALUES (v_ID, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
      TO_DATE(NOW()), new.UPDATEDBY, 'W', new.AD_TAB_ID, 'org.openbravo.erpWindows.' || v_JavaPackage || '.' || v_ClassName, 'Y',new.ad_module_id);

    END IF;

    SELECT COUNT(*) INTO v_Count
    FROM AD_MODEL_OBJECT_MAPPING
    WHERE AD_MODEL_OBJECT_ID IN (
      SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W')
    AND MAPPINGNAME LIKE '%_Relation.html';

    IF v_Count > 0 THEN
      UPDATE AD_MODEL_OBJECT_MAPPING
      SET AD_CLIENT_ID = new.AD_CLIENT_ID,
        AD_ORG_ID = new.AD_ORG_ID,
        ISACTIVE = v_IsActive,
        UPDATED = TO_DATE(NOW()),
        UPDATEDBY = new.UPDATEDBY,
        MAPPINGNAME = (v_ModuleMapping || v_WindowName || '/' || v_ClassName || '_Relation.html')
      WHERE AD_MODEL_OBJECT_ID IN (
        SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W')
      AND MAPPINGNAME LIKE '%_Relation.html';

    ELSE
      SELECT * INTO  v_ID_MAP FROM Ad_Sequence_Next('AD_Model_Object_Mapping', new.AD_Client_ID);
      INSERT INTO AD_MODEL_OBJECT_MAPPING (AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
      ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID, MAPPINGNAME, ISDEFAULT)
      VALUES (v_ID_MAP, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
      TO_DATE(NOW()), new.UPDATEDBY, v_ID, (v_ModuleMapping || '/' || v_WindowName || '/' || v_ClassName || '_Relation.html'), 'Y');

    END IF;

    SELECT COUNT(*) INTO v_Count
    FROM AD_MODEL_OBJECT_MAPPING
    WHERE AD_MODEL_OBJECT_ID IN (
      SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W')
    AND MAPPINGNAME LIKE '%_Edition.html';

    IF v_Count > 0 THEN
      UPDATE AD_MODEL_OBJECT_MAPPING
      SET AD_CLIENT_ID = new.AD_CLIENT_ID,
        AD_ORG_ID = new.AD_ORG_ID,
        ISACTIVE = v_IsActive,
        UPDATED = TO_DATE(NOW()),
        UPDATEDBY = new.UPDATEDBY,
        MAPPINGNAME = (v_ModuleMapping || v_WindowName || '/' || v_ClassName || '_Edition.html')
      WHERE AD_MODEL_OBJECT_ID IN (
        SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W')
      AND MAPPINGNAME LIKE '%_Edition.html';

    ELSE
      SELECT * INTO  v_ID_MAP FROM Ad_Sequence_Next('AD_Model_Object_Mapping', new.AD_Client_ID);
      INSERT INTO AD_MODEL_OBJECT_MAPPING (AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
      ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID, MAPPINGNAME, ISDEFAULT)
      VALUES (v_ID_MAP, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
      TO_DATE(NOW()), new.UPDATEDBY, v_ID, (v_ModuleMapping || v_WindowName || '/' || v_ClassName || '_Edition.html'), 'N');

    END IF;

    SELECT COUNT(*) INTO v_Count
    FROM AD_MODEL_OBJECT_MAPPING
    WHERE AD_MODEL_OBJECT_ID IN (
      SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W')
    AND MAPPINGNAME LIKE '%_Excel.xls';

    IF v_Count > 0 THEN
      UPDATE AD_MODEL_OBJECT_MAPPING
      SET AD_CLIENT_ID = new.AD_CLIENT_ID,
        AD_ORG_ID = new.AD_ORG_ID,
        ISACTIVE = v_IsActive,
        UPDATED = TO_DATE(NOW()),
        UPDATEDBY = new.UPDATEDBY,
        MAPPINGNAME = (v_ModuleMapping  || v_WindowName || '/' || v_ClassName || '_Excel.xls')
      WHERE AD_MODEL_OBJECT_ID IN (
        SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W')
      AND MAPPINGNAME LIKE '%_Excel.xls';

    ELSE
      SELECT * INTO  v_ID_MAP FROM Ad_Sequence_Next('AD_Model_Object_Mapping', new.AD_Client_ID);
      INSERT INTO AD_MODEL_OBJECT_MAPPING (AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
      ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID, MAPPINGNAME, ISDEFAULT)
      VALUES (v_ID_MAP, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
      TO_DATE(NOW()), new.UPDATEDBY, v_ID, (v_ModuleMapping || v_WindowName || '/' || v_ClassName || '_Excel.xls'), 'N');

    END IF;
 END IF; -- Update

 IF (TG_OP = 'DELETE') THEN
  DELETE FROM AD_MODEL_OBJECT_MAPPING WHERE AD_MODEL_OBJECT_ID IN (
      SELECT AD_MODEL_OBJECT_ID FROM AD_MODEL_OBJECT WHERE AD_MODEL_OBJECT.AD_TAB_ID=old.AD_TAB_ID AND ACTION = 'W');
  DELETE FROM AD_MODEL_OBJECT WHERE ACTION = 'W' AND AD_MODEL_OBJECT.AD_TAB_ID = OLD.AD_TAB_ID;
 END IF;

 IF (TG_OP = 'INSERT') THEN
  
      SELECT W.IsActive,  (CASE WHEN M.AD_MODULE_ID ='0' THEN NULL ELSE JavaPackage END)
    INTO v_IsActive, v_JavaPackage
    FROM AD_WINDOW W, AD_MODULE M
    WHERE AD_WINDOW_ID = NEW.AD_WINDOW_ID
     AND W.AD_MODULE_ID = M.AD_MODULE_ID;

  IF v_IsActive <> 'Y' THEN
      v_IsActive := NEW.ISACTIVE;
  END IF;
  SELECT AD_MAPPING_FORMAT(TO_CHAR(W.NAME)), AD_MAPPING_FORMAT(TO_CHAR(new.NAME))
  INTO v_WindowName, v_ClassName
  FROM AD_WINDOW W
  WHERE W.AD_WINDOW_ID = new.AD_WINDOW_ID;
  
  --Add tab id to name for non core modules
  IF (new.AD_Module_ID != '0') THEN
    v_ClassName := v_ClassName || new.AD_Tab_ID;
  END IF;

  IF (v_JavaPackage IS NOT NULL)  THEN
    v_ModuleMapping := '/'||v_JavaPackage||'.';
    v_JavaPackage := v_JavaPackage||'.'||v_WindowName;
  ELSE
    v_JavaPackage := v_WindowName;
    v_ModuleMapping := '/';
  END IF;
    
  SELECT * INTO  v_ID FROM Ad_Sequence_Next('AD_Model_Object', new.AD_Client_ID);
  INSERT INTO AD_MODEL_OBJECT (AD_MODEL_OBJECT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY,
  UPDATED, UPDATEDBY, ACTION, AD_TAB_ID, CLASSNAME, ISDEFAULT,ad_module_id)
  VALUES (v_ID, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
  TO_DATE(NOW()), new.UPDATEDBY, 'W', new.AD_TAB_ID, 'org.openbravo.erpWindows.' || v_JavaPackage || '.' || v_ClassName, 'Y',new.ad_module_id);

  SELECT * INTO  v_ID_MAP FROM Ad_Sequence_Next('AD_Model_Object_Mapping', new.AD_Client_ID);
  INSERT INTO AD_MODEL_OBJECT_MAPPING (AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
  ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID, MAPPINGNAME, ISDEFAULT)
  VALUES (v_ID_MAP, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
  TO_DATE(NOW()), new.UPDATEDBY, v_ID, (v_ModuleMapping || v_WindowName || '/' || v_ClassName || '_Relation.html'), 'Y');

  SELECT * INTO  v_ID_MAP FROM Ad_Sequence_Next('AD_Model_Object_Mapping', new.AD_Client_ID);
  INSERT INTO AD_MODEL_OBJECT_MAPPING (AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
  ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID, MAPPINGNAME, ISDEFAULT)
  VALUES (v_ID_MAP, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
  TO_DATE(NOW()), new.UPDATEDBY, v_ID, (v_ModuleMapping || v_WindowName || '/' || v_ClassName || '_Edition.html'), 'N');

  SELECT * INTO  v_ID_MAP FROM Ad_Sequence_Next('AD_Model_Object_Mapping', new.AD_Client_ID);
  INSERT INTO AD_MODEL_OBJECT_MAPPING (AD_MODEL_OBJECT_MAPPING_ID, AD_CLIENT_ID, AD_ORG_ID,
  ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, AD_MODEL_OBJECT_ID, MAPPINGNAME, ISDEFAULT)
  VALUES (v_ID_MAP, new.AD_CLIENT_ID, new.AD_ORG_ID, v_IsActive, TO_DATE(NOW()), new.CREATEDBY,
  TO_DATE(NOW()), new.UPDATEDBY, v_ID, (v_ModuleMapping || v_WindowName || '/' || v_ClassName || '_Excel.xls'), 'N');

 
 END IF;

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;



CREATE OR REPLACE FUNCTION ad_table_trg() RETURNS trigger LANGUAGE plpgsql AS $_$ DECLARE 
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2014 Stefan Zimmermann
* Contributions: Correct model Object Mapping to Module
****************************************************************************************************************************************************/
  v_Aux NUMERIC;
  cuerrentModuleID  VARCHAR(32); --OBTG:VARCHAR2--
  v_check BOOLEAN;
  v_char char;
    
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN 
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;

  IF (TG_OP = 'INSERT') THEN
    v_check := true;
  END IF;
  
  IF (TG_OP = 'UPDATE') THEN
    v_check := (new.tableName != old.tableName) 
            or (new.Name != old.Name) 
            or (new.AD_Package_ID != old.AD_Package_ID)
            or (new.IsView != old.IsView);
  END IF;
  
  IF v_check THEN
    SELECT M.AD_MODULE_ID
      INTO cuerrentModuleID
      FROM AD_MODULE M, AD_PACKAGE P
     WHERE M.AD_MODULE_ID = P.AD_MODULE_ID
       AND P.AD_PACKAGE_ID = new.AD_Package_ID;
    update ad_column set ad_module_id=cuerrentModuleID where ad_table_id=new.ad_table_id;
   SELECT COUNT(*)
     INTO v_Aux
     FROM (
      SELECT 1      
        FROM AD_MODULE_DBPREFIX P
      WHERE P.AD_MODULE_ID = cuerrentModuleID
        AND instr(upper(new.TableName), upper(name)||'_') = 1
        AND (instr(upper(new.Name), upper(name)||'_') = 1 OR cuerrentModuleID = '0')
      UNION
       SELECT 1
         FROM AD_EXCEPTIONS 
         WHERE ((TYPE='TABLE' AND new.IsView = 'N') or (TYPE='VIEW' AND new.IsView = 'Y'))
         AND UPPER(NAME1)=UPPER(new.Tablename)) AA;
    
     IF v_Aux = 0 THEN
       RAISE EXCEPTION '%', 'Names must start with its module''s DB prefix ' ; --OBTG:-20536--
     END IF;

     --Check Name for illegal characters
     FOR I IN 1..LENGTH(trim(NEW.name)) LOOP
        v_char := substr(trim(NEW.name),i,1);
        IF v_char = ' ' or v_char = '.' or v_char = ',' or v_char='/' THEN
           RAISE EXCEPTION '%', '@NameWithInvalidCharacters@' ; --OBTG:-20635--
        END IF;
     END LOOP;
  END IF;

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;

select zsse_DropTrigger ('ad_table_trg','ad_table');

CREATE TRIGGER ad_table_trg
  AFTER UPDATE
  ON ad_table FOR EACH ROW
  EXECUTE PROCEDURE ad_table_trg();
  
select zsse_DropView ('ad_ref_list_v');

CREATE OR REPLACE VIEW ad_ref_list_v AS 
select ad_ref_list_id,value,name,ad_language,ad_reference_id,isdefault,''::text as description,isactive,seqno from 
         (SELECT ad_ref_list_id, value, name, 'en_US' AS ad_language, ad_reference_id,isdefault,isactive,seqno
           FROM ad_ref_list where not exists (select 0 from ad_ref_listinstance where ad_ref_listinstance.ad_ref_list_id=ad_ref_list.ad_ref_list_id)
          UNION 
          SELECT v1.ad_ref_list_id, v1.value, v2.name AS name, v2.ad_language, v1.ad_reference_id,v1.isdefault,v1.isactive,v1.seqno
            FROM ad_ref_list v1,ad_ref_list_trl v2 
           WHERE v1.ad_ref_list_id::text = v2.ad_ref_list_id::text and v2.ad_language!='en_US'  and
                 not exists (select 0 from ad_ref_listinstance where ad_ref_listinstance.ad_ref_list_id=v1.ad_ref_list_id)
          UNION 
          SELECT max(ad_ref_listinstance_id) as ad_ref_list_id,value, name, 'en_US' AS ad_language, ad_reference_id,isdefault,case ishidden when 'N' then 'Y' else 'N' end as isactive,seqno
           FROM ad_ref_listinstance group by ad_reference_id,value, name,ishidden,isdefault,seqno
          UNION 
          SELECT max(v1.ad_ref_listinstance_id) as ad_ref_list_id,v1.value, v2.name, v2.ad_language, v1.ad_reference_id,v1.isdefault,case v1.ishidden when 'N' then 'Y' else 'N' end as isactive,v1.seqno
            FROM ad_ref_listinstance v1,ad_ref_listinstance_trl v2 
           WHERE v1.ad_ref_listinstance_id::text = v2.ad_ref_listinstance_id::text and v2.ad_language!='en_US' 
                  group by v1.ad_reference_id,v1.value, v1.ishidden,v1.isdefault,v1.seqno,v2.ad_language, v2.name
         ) a order by ad_reference_id,isdefault desc ;

         
select zsse_dropfunction ('ad_getTabFieldDefault');
CREATE OR REPLACE FUNCTION ad_getTabFieldDefault(p_tab_id character varying, p_columnname character varying, p_org varchar)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************


For LIST, Table and Table Direct References 

Returns the Default set on the List ref.

This vcan be defines for each Tab seperately.

*/
v_ref_id  character varying;
v_table_id character varying;
v_tablename varchar;
v_type    character varying;
v_sql varchar;
v_retval   character varying:='';
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
BEGIN
  select ad_reference_value_id  into v_ref_id  from ad_column where upper(columnname)=upper(p_columnname) and ad_table_id = (select ad_table_id from ad_tab where ad_tab_id= p_tab_id);
  select validationtype into v_type from ad_reference where ad_reference_id = v_ref_id;
  if v_type is null then 
    select ad_reference_id into v_type  from ad_column where upper(columnname)=upper(p_columnname) and ad_table_id = (select ad_table_id from ad_tab where ad_tab_id= p_tab_id);
  end if;
  if coalesce(v_type,'null')='L' then
     select value into v_retval from ad_ref_listinstance where ad_reference_id=v_ref_id and isdefault='Y' and ishidden='N' and ad_tab_id=p_tab_id;
     if v_retval is null then
         select value into v_retval from ad_ref_list where ad_reference_id=v_ref_id and isdefault='Y' and isactive='Y' and ad_tab_id=p_tab_id;
     end if;
     if v_retval is null then
         select value into v_retval from ad_ref_list_v where ad_reference_id=v_ref_id and isdefault='Y' and isactive='Y';
     end if;
  end if; 
  if coalesce(v_type,'null') = 'T' then
    select ad_table_id into v_table_id from ad_ref_table where ad_reference_id=v_ref_id;
    select t.tablename into v_tablename from ad_table t,ad_column c where c.ad_table_id=t.ad_table_id and t.ad_table_id=v_table_id and lower(c.columnname)='isdefault';
  end if;
  -- Table Dir
  if coalesce(v_type,'null') = '19' then
    select ad_table_id into v_table_id from ad_table where lower(tablename)=lower(substr(p_columnname,1,length(p_columnname)-3));
    select t.tablename into v_tablename from ad_table t,ad_column c where c.ad_table_id=t.ad_table_id and t.ad_table_id=v_table_id and lower(c.columnname)='isdefault';
  end if;
  if v_tablename is not null then
      v_sql:='select '||v_tablename||'_id as retval from '||v_tablename||' where isdefault = '|| chr(39)||'Y'||chr(39)||' and ad_org_id in ('|| chr(39)||p_org||chr(39)||','|| chr(39)||'0'||chr(39)||' ) limit 1';
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_retval:=v_cur.retval;
      END LOOP;
      close v_cursor;
  end if;
  RETURN v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION ad_fieldGetVisibleLogic(p_field_id character varying,  p_role_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_done varchar:='N';
v_visiblelogic varchar;
v_visiblelogic_instance varchar;
v_tab varchar;
v_count numeric;
v_visiblesettings_rolefield varchar;
v_visiblesettings_role varchar;
v_visiblesettings_instance varchar;
v_isvisible varchar;
v_gridcol varchar;
v_fieldcol varchar;
v_isactive varchar='Y';
v_ppara varchar;
v_template varchar;
BEGIN
  select ad_tab_id into v_tab from ad_field_v where ad_field_v_id=p_field_id;
  select ad_ref_fieldcolumn_id into v_fieldcol from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  select ad_ref_gridcolumn_id into v_gridcol from ad_ref_gridcolumn where ad_ref_gridcolumn_id=p_field_id;
  select ad_process_para_id into v_ppara from ad_process_para where ad_process_para_id=p_field_id;
  -- Is a TAB Field?
   if v_tab is not null then
        -- 1 read Role Settings (Field)
        select af.visiblesetting into v_visiblesettings_rolefield from ad_role_tabaccess a, ad_role_tabaccess_field af 
                                                                                   where a.ad_role_tabaccess_id=af.ad_role_tabaccess_id and 
                                                                                   a.ad_tab_id = v_tab and a.ad_role_id=p_role_id and af.ad_field_id=p_field_id;
        -- 2 read Role Settings (TAB)
        select a.visiblesetting into v_visiblesettings_role from  ad_role_tabaccess a where a.ad_tab_id = v_tab and a.ad_role_id=p_role_id
                                                                                                    and a.isactive='Y';
        -- 3 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select isactive,visiblesetting,displaylogic
               into v_isactive,v_visiblesettings_instance,v_visiblelogic_instance
               from ad_fieldinstance where ad_field_v_id=p_field_id;
        -- 4 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.isdisplayed,f.displaylogic,f.isactive,coalesce(f.template,ad_datatype_guiengine_template_mapping(c.ad_reference_id)) as template
            into v_isvisible,v_visiblelogic,v_isactive,v_template
            from ad_field f,ad_column c where f.ad_column_id=c.ad_column_id and f.ad_field_id=p_field_id;
        
  elsif v_fieldcol is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select isactive,visiblesetting,displaylogic
               into v_isactive,v_visiblesettings_instance,v_visiblelogic_instance
               from ad_ref_fieldcolumninstance where ad_ref_fieldcolumn_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.isdisplayed,f.displaylogic,f.isactive,f.template
            into v_isvisible,v_visiblelogic,v_isactive,v_template
            from ad_ref_fieldcolumn f where f.ad_ref_fieldcolumn_id=p_field_id;
  elsif v_gridcol is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        -- @TODO@ : Implement dynamic logic
        select visiblesetting
               into v_visiblesettings_instance
               from ad_ref_gridcolumninstance where ad_ref_gridcolumn_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic) TBD: Now only isdisplayed woks
        select f.isdisplayed,f.template
            into v_isvisible
            from ad_ref_gridcolumn f where f.ad_ref_gridcolumn_id=p_field_id;
  elsif v_ppara is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select isactive,visiblesetting,displaylogic
               into v_isactive,v_visiblesettings_instance,v_visiblelogic_instance
               from ad_process_para_instance where ad_process_para_id=p_field_id; 
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.isdisplayed,f.displaylogic,f.isactive,f.template
            into v_isvisible,v_visiblelogic,v_isactive,v_template
            from ad_process_para f where f.ad_process_para_id=p_field_id; 
  end if;
  -- Evaluate Global Field settings
  if v_isactive='N' then
      return 'DONOTGENERATE';
  end if;
  --raise notice '%',coalesce(v_template,'x')||(SELECT ad_fieldGetName(p_field_id))||coalesce(v_visiblesettings_rolefield,'NON');
  -- Evaluation of HIDDEN
  -- If the visiblesettings or Y/N-Fields are used: Field is hidden
  -- Evaluate Field of a ROLE
  if coalesce(v_visiblesettings_rolefield,'NON')!='NON' then 
      if v_visiblesettings_rolefield='HIDDEN' and coalesce(v_template,'x') in ('EURO','INTEGER','PRICE','DECIMAL') then
        return 'HIDDENNUMERIC';  
      else
        return  v_visiblesettings_rolefield;
      end if;
  end if;
  -- Evaluate TAB of a ROLE
  if coalesce(v_visiblesettings_role,'NON')!='NON' and  v_done='N' then 
      return v_visiblesettings_role;
  end if;
  -- Evaluate Instance specific Field settings
  if coalesce(v_visiblesettings_instance,'NON')!='NON' and  v_done='N' then 
      if v_visiblesettings_instance='HIDDEN' and coalesce(v_template,'x') in ('EURO','INTEGER','PRICE','DECIMAL') then
        return 'HIDDENNUMERIC';  
      else
        return v_visiblesettings_instance;
      end if;
  end if;
  if  v_isvisible='N' and coalesce(v_template,'x') not in ('EURO','INTEGER','PRICE','DECIMAL') then
    return 'HIDDEN';  
  end if;
  if v_isvisible='N' and coalesce(v_template,'x') in ('EURO','INTEGER','PRICE','DECIMAL') then
    return 'HIDDENNUMERIC';  
  end if;
  -- Continue to evaluate Logic Field
  -- Evaluation of Visible Logic
  if v_visiblelogic_instance is not null then
     return v_visiblelogic_instance;
  end if;
  if v_visiblelogic is not null then
     return v_visiblelogic;
  end if;
  return 'VISIBLE';  
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_fieldGetReadonlyLogic(p_field_id character varying,  p_role_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_done varchar:='N';
v_retval   character varying:='';
v_readonlylogic varchar;
v_readonlylogic_instance varchar;
v_tab varchar;
v_count numeric;
v_editsettings_rolefield  varchar;
v_editsettings_role  varchar;
v_editsettings_instance  varchar;
v_isreadonly varchar;
v_gridcol varchar;
v_fieldcol varchar;
v_ppara varchar;
v_noedit varchar:='Y';
BEGIN
  select ad_tab_id into v_tab from ad_field_v where ad_field_v_id=p_field_id;
  select ad_ref_fieldcolumn_id into v_fieldcol from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  select ad_ref_gridcolumn_id into v_gridcol from ad_ref_gridcolumn where ad_ref_gridcolumn_id=p_field_id;
  select ad_process_para_id into v_ppara from ad_process_para where ad_process_para_id=p_field_id;
  -- Is a TAB Field?
   if v_tab is not null then
        -- 1 read Role Settings (Field)
        select af.editsetting into v_editsettings_rolefield from ad_role_tabaccess a, ad_role_tabaccess_field af 
                                                                                   where a.ad_role_tabaccess_id=af.ad_role_tabaccess_id and 
                                                                                   a.ad_tab_id = v_tab and a.ad_role_id=p_role_id and af.ad_field_id=p_field_id;
        -- 2 read Role Settings (TAB)
        select a.editsetting into v_editsettings_role from  ad_role_tabaccess a where a.ad_tab_id = v_tab and a.ad_role_id=p_role_id;
        -- 3 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select editsetting,readonlylogic
               into v_editsettings_instance,v_readonlylogic_instance
               from ad_fieldinstance where ad_field_v_id=p_field_id;
        -- 4 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.isreadonly,coalesce(f.readonlylogic,c.readonlylogic),c.isupdateable
            into v_isreadonly,v_readonlylogic,v_noedit
            from ad_field f,ad_column c where f.ad_column_id=c.ad_column_id and f.ad_field_id=p_field_id;
  elsif v_fieldcol is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select editsetting,readonlylogic
               into v_editsettings_instance,v_readonlylogic_instance
               from ad_ref_fieldcolumninstance where ad_ref_fieldcolumn_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.readonly,f.readonlylogic
            into v_isreadonly,v_readonlylogic
            from ad_ref_fieldcolumn f where f.ad_ref_fieldcolumn_id=p_field_id;
  elsif v_gridcol is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select editsetting
               into v_editsettings_instance
               from ad_ref_gridcolumninstance where ad_ref_gridcolumn_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.readonly
            into v_isreadonly
            from ad_ref_gridcolumn f where f.ad_ref_gridcolumn_id=p_field_id;
  elsif v_ppara is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select editsetting,readonlylogic
               into v_editsettings_instance,v_readonlylogic_instance
               from ad_process_para_instance where ad_process_para_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.readonly,f.readonlylogic
            into v_isreadonly,v_readonlylogic
            from ad_process_para f where f.ad_process_para_id=p_field_id;
  end if;
  -- Evaluation 
  -- If the visiblesettings or Y/N-Fields are used: Field is hidden
  -- Evaluate Field of a ROLE
  if coalesce(v_editsettings_rolefield,'NON')!='NON' then 
      v_retval:=v_editsettings_rolefield;
      v_done:='Y';
  end if;
  -- Evaluate TAB of a ROLE
  if coalesce(v_editsettings_role,'NON')!='NON' and  v_done='N' then 
      v_retval:=v_editsettings_role;
      v_done:='Y';
  end if;
  -- Evaluate Instance specific Field settings
  if coalesce(v_editsettings_instance,'NON')!='NON' and  v_done='N' then 
      v_retval:=v_editsettings_instance;
      v_done:='Y';
  end if;
  -- Evaluate Global Field settings
  if (v_isreadonly='Y' or v_noedit='N') and  v_done='N' and v_readonlylogic_instance is null then 
      if v_noedit='N' then
        v_retval:='NOEDIT';
      end if;
      if v_isreadonly='Y' then
        v_retval:='READONLY';
      end if;
      v_done:='Y';
  end if;
  -- Continue if no Hidden Field
  if v_done!='Y' then
     -- Evaluation of Visible Logic
     if v_readonlylogic_instance is not null then
        v_retval:=v_readonlylogic_instance;
        v_done:='Y';
     end if;
     if v_readonlylogic is not null and v_done='N' then
        v_retval:=v_readonlylogic;
        v_done:='Y';
     end if;
     if  v_done='N' then
       v_retval:='EDIT';  
     end if;
  end if;
  return v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION ad_fieldGetMandantoryLogic(p_field_id character varying,  p_role_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_done varchar:='N';
v_retval   character varying:='';
v_mandantorylogic varchar;
v_mandantorylogic_instance varchar;
v_tab varchar;
v_count numeric;

v_ismandantory varchar;

v_gridcol varchar;
v_fieldcol varchar;
v_ppara varchar;

BEGIN
  select ad_tab_id into v_tab from ad_field_v where ad_field_v_id=p_field_id;
  select ad_ref_fieldcolumn_id into v_fieldcol from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  select ad_ref_gridcolumn_id into v_gridcol from ad_ref_gridcolumn where ad_ref_gridcolumn_id=p_field_id;
  select ad_process_para_id into v_ppara from ad_process_para where ad_process_para_id=p_field_id;
  -- Is a TAB Field?
   if v_tab is not null then
        
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select mandantorylogic 
               into v_mandantorylogic_instance 
               from ad_fieldinstance where ad_field_v_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.required,f.mandantorylogic
            into v_ismandantory,v_mandantorylogic 
            from ad_field f where  f.ad_field_id=p_field_id;
  elsif v_fieldcol is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select mandantorylogic 
               into v_mandantorylogic_instance 
               from ad_ref_fieldcolumninstance where ad_ref_fieldcolumn_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.required,f.mandantorylogic
            into v_ismandantory,v_mandantorylogic 
            from ad_ref_fieldcolumn f where f.ad_ref_fieldcolumn_id=p_field_id;
  elsif v_gridcol is not null then
        select coalesce(required,'NON') into v_ismandantory from ad_ref_gridcolumninstance where ad_ref_gridcolumn_id=p_field_id;
        if v_ismandantory='NON' then
            -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
            select f.required
            into v_ismandantory
            from ad_ref_gridcolumn f where f.ad_ref_gridcolumn_id=p_field_id;
        end if;
  elsif v_ppara is not null then
        -- 1 read Field-Instance (EDIT- and Visible Settings and Complete Logic)
        select mandantorylogic 
               into v_mandantorylogic_instance 
               from ad_process_para_instance where ad_process_para_id=p_field_id;
        -- 2 read Field (EDIT- and Visible Settings and Complete Logic)
        select f.ismandatory as required,f.mandantorylogic
            into v_ismandantory,v_mandantorylogic 
            from ad_process_para f where f.ad_process_para_id=p_field_id;
  end if;
  -- Evaluation 
  -- Evaluate Instance specific Field settings
  -- Evaluate Global Field settings
  if v_ismandantory='Y'  and  v_mandantorylogic_instance is null then 
      v_retval:='MANDANTORY';
      v_done:='Y';
  end if;
  -- Continue if no Mandantory Field
  if v_done!='Y' then
     -- Evaluation of Visible Logic
     if v_mandantorylogic_instance  is not null then
        v_retval:=v_mandantorylogic_instance;
        v_done:='Y';
     end if;
     if v_mandantorylogic is not null and v_done='N' then
        v_retval:=v_mandantorylogic;
        v_done:='Y';
     end if;
     if  v_done='N' then
       v_retval:='CANBENULL';  
     end if;
  end if;
  return v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_fieldGetDefault(p_field_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_done varchar:='N';
v_retval   character varying:='';

v_default_instance varchar;
v_default varchar;

v_gridcol varchar;
v_fieldcol varchar;
v_tab varchar;
v_ppara varchar;
BEGIN
  select ad_tab_id into v_tab from ad_field_v where ad_field_v_id=p_field_id;
  select ad_ref_fieldcolumn_id into v_fieldcol from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  select ad_ref_gridcolumn_id into v_gridcol from ad_ref_gridcolumn where ad_ref_gridcolumn_id=p_field_id;
  select ad_process_para_id into v_ppara from ad_process_para where ad_process_para_id=p_field_id;
  -- Is a TAB Field?
  if v_tab is not null then
        select defaultvalue into v_default_instance from ad_fieldinstance where ad_field_v_id=p_field_id;
        select defaultvalue into v_default from ad_field f where f.ad_field_id=p_field_id;
        if v_default is null then
           select c.defaultvalue
            into v_default
            from ad_field f,ad_column c where f.ad_column_id=c.ad_column_id and f.ad_field_id=p_field_id;
        end if;
  elsif v_fieldcol is not null then
        select defaultvalue into v_default_instance from ad_ref_fieldcolumninstance where ad_ref_fieldcolumn_id=p_field_id;
        select defaultvalue into v_default from ad_ref_fieldcolumn f where ad_ref_fieldcolumn_id=p_field_id;
  elsif v_gridcol is not null then
        select defaultvalue into v_default_instance from ad_ref_gridcolumninstance where ad_ref_gridcolumn_id=p_field_id;
        select defaultvalue into v_default from ad_ref_gridcolumn f where ad_ref_gridcolumn_id=p_field_id;
  elsif v_ppara is not null then
        select defaultvalue into v_default_instance from ad_process_para_instance where ad_process_para_id=p_field_id;
        select defaultvalue into v_default from ad_process_para where ad_process_para_id=p_field_id;
  end if;
  -- Evaluation 
  -- Evaluate Instance specific Field settings
  -- Evaluate Global Field settings
  if v_default_instance is not null then 
      v_retval:=v_default_instance;
      v_done:='Y';
  end if;
  -- Continue if no Mandantory Field
  if v_done!='Y' then
     -- Evaluation of Visible Logic
     if v_default  is not null then
        v_retval:=v_default;
     end if;
  end if;
  return v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_fieldTriggersComboReload(p_field_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/

v_retval   character varying:='N';

v_count numeric:=0;

v_gridcol varchar;
v_fieldcol varchar;
v_tab varchar;
v_ppara varchar;
BEGIN
  select ad_field_id into v_tab from ad_field where ad_field_id=p_field_id;
  select ad_ref_fieldcolumn_id into v_fieldcol from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  --select ad_ref_gridcolumn_id into v_gridcol from ad_ref_gridcolumn where ad_ref_gridcolumn_id=p_field_id;
  select ad_process_para_id into v_ppara from ad_process_para where ad_process_para_id=p_field_id;
  -- Is a TAB Field?
  if v_tab is not null then
       SELECT 1 into v_count
        FROM AD_FIELD f, 
             AD_COLUMN c   
        WHERE f.AD_COLUMN_ID = c.ad_column_id
        AND (exists (select 0 from ad_ref_table t, AD_FIELD fx, AD_COLUMN cx 
                             where fx.AD_COLUMN_ID = cx.ad_column_id and fx.ad_tab_id = f.ad_tab_id and cx.AD_REFERENCE_VALUE_ID=t.AD_REFERENCE_ID 
                             and instr(upper(t.whereclause),'@'||upper(c.columnname)||'@')>0)
            OR exists (select 0 from ad_val_rule t, AD_FIELD fx, AD_COLUMN cx 
                             where fx.AD_COLUMN_ID = cx.ad_column_id and fx.ad_tab_id = f.ad_tab_id and cx.AD_VAL_RULE_ID = t.AD_VAL_RULE_ID
                             and instr(upper(t.code),'@'||upper(c.columnname)||'@')>0)
            )
        AND upper(c.columnname)!='AD_CLIENT_ID'
        AND case when upper(c.columnname)='AD_ORG_ID' then f.isreadonly='N' else 1=1 end
        AND c.columnname!='IsSOTrx'
        AND f.ad_field_id = p_field_id limit 1;
  elsif v_fieldcol is not null then
        SELECT 1 into v_count
        FROM ad_ref_fieldcolumn c, ad_reference r
        WHERE r.ad_reference_id=c.ad_reference_id  and
            (exists (select 0 from ad_ref_table t, ad_ref_fieldcolumn cx 
                             where cx.ad_reference_id = c.ad_reference_id and cx.fieldreference =t.AD_REFERENCE_ID 
                             and instr(upper(t.whereclause),'@'||upper(c.name)||'@')>0)
            OR exists (select 0 from ad_val_rule t, ad_ref_fieldcolumn cx 
                             where cx.ad_reference_id = c.ad_reference_id  and cx.AD_VAL_RULE_ID = t.AD_VAL_RULE_ID
                             and instr(upper(t.code),'@'||upper(c.name)||'@')>0)
            )
        AND upper(c.name)!='AD_CLIENT_ID'
        AND case when upper(c.name)='AD_ORG_ID' then c.readonly='N' else 1=1 end
        AND c.ad_ref_fieldcolumn_id=p_field_id limit 1;        
  elsif v_ppara is not null then
        SELECT 1 into v_count
        FROM AD_PROCESS_PARA c
        WHERE (exists (select 0 from ad_ref_table t, AD_PROCESS_PARA cx 
                             where cx.ad_process_id = c.ad_process_id and cx.AD_REFERENCE_VALUE_ID=t.AD_REFERENCE_ID 
                             and instr(upper(t.whereclause),'@'||upper(c.columnname)||'@')>0)
            OR exists (select 0 from ad_val_rule t, AD_PROCESS_PARA cx 
                             where cx.ad_process_id = c.ad_process_id  and cx.AD_VAL_RULE_ID = t.AD_VAL_RULE_ID
                             and instr(upper(t.code),'@'||upper(c.columnname)||'@')>0)
            )
        AND upper(c.columnname)!='AD_CLIENT_ID'
        AND case when upper(c.columnname)='AD_ORG_ID' then c.readonly='N' else 1=1 end
        AND c.ad_process_para_id=p_field_id limit 1;
  end if;
  if v_count>0 then 
    v_retval:='Y';
  end if;
  return v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_getListRefDefault(p_field_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_ref_id  character varying;
v_type    character varying;
v_retval   character varying:='';
BEGIN
  select ad_reference_value_id into v_ref_id from ad_column ,ad_field where ad_field.ad_field_id=p_field_id and ad_column.ad_column_id=ad_field.ad_column_id; 
  if v_ref_id is null then 
     select ad_reference_id into v_ref_id from ad_ref_fieldcolumn  where ad_ref_fieldcolumn_id=p_field_id;
  end if;
  if v_ref_id is null then 
     select ad_reference_id into v_ref_id from ad_ref_gridcolumn  where ad_ref_gridcolumn_id=p_field_id;
  end if;
  select validationtype into v_type from ad_reference where ad_reference_id = v_ref_id;
  if coalesce(v_type,'null')='L' then
     select value into v_retval from ad_ref_listinstance where ad_reference_id=v_ref_id and isdefault='Y' and ishidden='N' and ad_tab_id=p_tab_id;
     if v_retval is null then
         select value into v_retval from ad_ref_list where ad_reference_id=v_ref_id and isdefault='Y' and isactive='Y' and ad_tab_id=p_tab_id;
     end if;
     if v_retval is null then
         select value into v_retval from ad_ref_list_v where ad_reference_id=v_ref_id and isdefault='Y' and isactive='Y';
     end if;
  end if; 
  RETURN v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_dropfunction('ad_isFieldInForm');
CREATE OR REPLACE FUNCTION ad_isFieldInForm(p_field_id character varying, p_otherfieldname character varying,p_woPromaryKey varchar)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/

v_tab varchar;
v_exists varchar;
BEGIN
  select c.ad_table_id into v_tab from ad_field_v f,ad_column_v c where c.ad_column_v_id=f.ad_column_v_id and f.ad_field_v_id=p_field_id;
  if v_tab is not null then
     select c.ad_column_v_id into v_exists from ad_column_v c  where ad_table_id=v_tab and upper(columnname)=upper(p_otherfieldname)
            and case when p_woPromaryKey='Y' then c.iskey='N' else 1=1 end;
     if  v_exists is not null then
         return 'Y';
     end if;
  end if;
  select ad_reference_id into v_tab from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  if v_tab is not null then
     select f.ad_ref_fieldcolumn_id into v_exists from ad_ref_fieldcolumn f  where ad_reference_id=v_tab and upper(name)=upper(p_otherfieldname);
     if  v_exists is not null then
         return 'Y';
     end if;
  end if;
  select g.ad_reference_id into v_tab from ad_ref_gridcolumn c,ad_ref_group g where g.ad_ref_group_id=c.ad_ref_group_id and c.ad_ref_gridcolumn_id=p_field_id;
  if v_tab is not null then
      select g.ad_reference_id into v_exists from ad_ref_gridcolumn c,ad_ref_group g where g.ad_ref_group_id=c.ad_ref_group_id and g.ad_reference_id= v_tab and upper(c.name)=upper(p_otherfieldname);
      if  v_exists is not null then
         return 'Y';
      end if;
  end if;
  return 'N';
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_TabGetFirstFocusField(p_tab_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_retval   character varying;

BEGIN
  select coalesce(c.columnname,f.name) into v_retval from ad_field_v f left join ad_column c on f.ad_column_v_id=c.ad_column_id,ad_fieldinstance fi 
         where f.ad_tab_id=p_tab_id 
         and f.ad_field_v_id=fi.ad_field_v_id and fi.isfirstfocusedfield='Y';
  if v_retval is not null then return v_retval; end if;
  select c.columnname into v_retval from ad_field f,ad_column c where f.ad_column_id=c.ad_column_id and f.ad_tab_id=p_tab_id and f.isfirstfocusedfield='Y';
  if v_retval is not null then return v_retval; end if;
  select c.columnname into v_retval from ad_field f,ad_column c where f.ad_column_id=c.ad_column_id and f.ad_tab_id=p_tab_id and 
    f.seqno=(select min(seqno) from ad_field where ad_tab_id=p_tab_id);
  if v_retval is not null then return v_retval; end if;
  return '';
  -- Is a TAB Field?
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION ad_fieldGetName(p_field_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_retval   character varying;

BEGIN
  select coalesce(c.columnname,f.name) into v_retval from ad_field_v f left join ad_column c on f.ad_column_v_id=c.ad_column_id where f.ad_field_v_id=p_field_id;
  if v_retval is not null then return v_retval; end if;
  select name  into v_retval  from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  if v_retval is not null then return v_retval; end if;
  select name  into v_retval  from ad_ref_gridcolumn where ad_ref_gridcolumn_id=p_field_id;
  if v_retval is not null then return v_retval; end if;
  select columnname  into v_retval  from ad_process_para where ad_process_para_id=p_field_id;
  if v_retval is not null then return v_retval; end if;
  return '';
  -- Is a TAB Field?
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_TabFieldgetDatabaseDefault(p_field_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_retval   character varying;
v_column character varying;
v_table  character varying;
BEGIN
  select lower(c.columnname),lower(t.tablename) into v_column,v_table from ad_field f,ad_column c,ad_table t
    where f.ad_column_id=c.ad_column_id
    and c.ad_table_id=t.ad_table_id
    and f.ad_field_id=p_field_id; 
  SELECT case when instr(data_default,':')>0 then substr(data_default,1,instr(data_default,':')-1) else data_default end into v_retval from user_tab_columns 
    where lower(table_name)=v_table and lower(column_name)=v_column;
  --TODO: Implement date end timestamp...
  if instr(v_retval,'now()')>0 or instr(v_retval,'to_timestamp(')>0 then
    return '';
  end if;
  v_retval:=replace(v_retval, chr(39),'');
  return coalesce(v_retval,'');
  -- Is a TAB Field?
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  


CREATE OR REPLACE FUNCTION ad_fieldGetDataType(p_field_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_ref   character varying;
v_tabname   character varying;
v_retval  character varying;
BEGIN
  select r.name into v_ref from ad_field f,ad_column c,ad_reference r where f.ad_column_id=c.ad_column_id  and f.ad_field_id=p_field_id
                                               and c.ad_reference_id=r.ad_reference_id;
  if v_ref is not null then 
    if v_ref in ('Integer','Amount','General Quantity','Price','Quantity','Number') then
       return 'NUMERIC';
    end if;
    if v_ref in ('Date','Time','DateTime') then
       return 'DATE';
    end if;
  end if;
  select template  into v_ref  from ad_ref_fieldcolumn where ad_ref_fieldcolumn_id=p_field_id;
  if v_ref is null then
     select template  into v_ref from ad_ref_gridcolumn where ad_ref_gridcolumn_id=p_field_id;
  end if;
  if v_ref is not null then 
    if v_ref in ('EURO','DECIMAL','INTEGER','PRICE') then
       return 'NUMERIC';
    end if;
    if v_ref in ('DATE') then
       return 'DATE';
    end if;
  end if;
  return 'STRING';
  -- Is a TAB Field?
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION ad_getTabFieldDisplayLogic(p_tab_id character varying,  p_role_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_ref_id  character varying;
v_type    character varying;
v_retval   character varying;
v_cur     RECORD;
fieldlist character varying;
v_editsettings character  varying;
v_visiblesettings character  varying; --HIDDEN , VISIBLE, NON
v_tabeditsettings character  varying; -- EDIT, READONLY, NON
v_tabvisiblesettings character  varying;
v_tabaccess character varying;
v_ad_field  character varying;
v_ishidden character varying;
BEGIN
  v_retval:='function dynamicDisplayFunctions() {';
  -- Role-settings?
  -- On Tab
  select editsetting,visiblesetting,ad_role_tabaccess_id into v_tabeditsettings,v_tabvisiblesettings,v_tabaccess from ad_role_tabaccess where isactive='Y' and ad_role_id= p_role_id and ad_role_tabaccess.ad_tab_id=p_tab_id;
  -- Loop through all fields of the TAB and see if either Role, Tab, Field modifications are there
  for v_cur in (select columnname,ad_field_id from ad_column,ad_field where ad_column.ad_column_id=ad_field.ad_column_id and ad_field.ad_tab_id=p_tab_id)
  LOOP 
    -- Load Field Values from ad_role_tabaccess_field, if exists
    select ad_role_tabaccess_field.editsetting,ad_role_tabaccess_field.visiblesetting into v_editsettings,v_visiblesettings from  ad_role_tabaccess_field,ad_role_tabaccess 
                                                                                    where ad_role_tabaccess.ad_role_tabaccess_id=ad_role_tabaccess_field.ad_role_tabaccess_id 
                                                                                    and ad_role_tabaccess_field.ad_role_tabaccess_id=v_tabaccess and ad_field_id=v_cur.ad_field_id;
    --raise notice '%','Field:||v_cur.columnname||'_TAS:'|| coalesce(v_tabaccess,'TABACCESSISNULL')||'____TES:'||coalesce(v_tabeditsettings,'TESISNULL')||'_______ES:'||coalesce(v_editsettings,'ESISNULL');
    -- PROCESS REadoly Acess
    if coalesce(v_tabeditsettings,'NON')='READONLY' then 
        -- All fields of Tab readonly, except explicit field accesses (Overrides Instance Specific Access)
        if  coalesce(v_editsettings,'NON')='EDIT' then
              v_retval:=v_retval||'readOnlyLogicElement('||chr(39)||v_cur.columnname||chr(39)||',false);';
        else
              v_retval:=v_retval||'readOnlyLogicElement('||chr(39)||v_cur.columnname||chr(39)||',true);';
        end if;
        -- All fields of Tab editmode, except explicit field accesses (Overrides Instance Specific Access)
     elsif coalesce(v_tabeditsettings,'NON')='EDIT' then 
        if  coalesce(v_editsettings,'NON')='READONLY' then
              v_retval:=v_retval||'readOnlyLogicElement('||chr(39)||v_cur.columnname||chr(39)||',true);';
        else
              v_retval:=v_retval||'readOnlyLogicElement('||chr(39)||v_cur.columnname||chr(39)||',false);';
        end if;
     else
        -- Load specific readonly values from Field access or Instance Specific Access (Field Acces overides Instance specific Access)
        if coalesce(v_editsettings,'NON')= 'EDIT' then
              v_retval:=v_retval||'readOnlyLogicElement('||chr(39)||v_cur.columnname||chr(39)||',false);';
        elsif coalesce(v_editsettings,'NON')= 'READONLY' then
              v_retval:=v_retval||'readOnlyLogicElement('||chr(39)||v_cur.columnname||chr(39)||',true);';
        else
           select editsetting into v_editsettings from ad_fieldinstance where ad_field_v_id= v_cur.ad_field_id;
           if coalesce(v_editsettings,'NON')!='NON' and v_editsettings is not null then
              v_retval:=v_retval||'readOnlyLogicElement('||chr(39)||v_cur.columnname||chr(39)||','||case v_editsettings when 'EDIT' then 'false' else 'true' end||');';
           end if;
        end if;
     end if;
     -- Process HIDDEN Fields
     if coalesce(v_tabvisiblesettings,'NON')='HIDDEN' then 
        -- All fields of Tab readonly, except explicit field accesses (Overrides Instance Specific Access)
        if coalesce(v_visiblesettings,'NON')='VISIBLE' then
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp_td'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl_td'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_btt'||chr(39)||',true);';
        else
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp_td'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl_td'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_btt'||chr(39)||',false);';
        end if;
     elsif coalesce(v_tabvisiblesettings,'NON')='VISIBLE' then
        if coalesce(v_visiblesettings,'NON')='HIDDEN' then
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp_td'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl_td'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl'||chr(39)||',false);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_btt'||chr(39)||',false);';
        else
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp_td'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl_td'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl'||chr(39)||',true);';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_btt'||chr(39)||',true);';
        end if;
      else
        -- Load specific readonly values from Field access or Instance Specific Access (Field Acces overides Instance specific Access)
        if coalesce(v_visiblesettings,'NON')!='NON' and v_visiblesettings is not null then
              v_ishidden:=case v_visiblesettings when 'HIDDEN' then 'false' else 'true' end;
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp_td'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl_td'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_btt'||chr(39)||','||v_ishidden||');';
        else
           select visiblesetting into v_visiblesettings from ad_fieldinstance where ad_field_v_id= v_cur.ad_field_id;
           if coalesce(v_visiblesettings,'NON')!='NON' and v_visiblesettings is not null then
              v_ishidden:=case v_visiblesettings when 'HIDDEN' then 'false' else 'true' end;
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp_td'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_inp'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl_td'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_lbl'||chr(39)||','||v_ishidden||');';
              v_retval:=v_retval||'displayLogicElement('||chr(39)||v_cur.columnname||'_btt'||chr(39)||','||v_ishidden||');';
            end if;
         end if;
      end if;
  END LOOP;
  v_retval:=v_retval||'return true;}';
  RETURN v_retval;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION ad_isTabFieldShownInGrid(p_field_id character varying,  p_role_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
****************************************************/
v_visiblesettings character varying;
v_showinrelation character varying;
v_isshown character varying;
v_tab character varying;
v_tabaccess character varying;
BEGIN
  select ad_tab_id into v_tab from ad_field where ad_field_id=p_field_id;
  -- Role-settings?
  -- On Tab
  select visiblesetting,ad_role_tabaccess_id into v_visiblesettings,v_tabaccess from ad_role_tabaccess where isactive='Y' and ad_role_id= p_role_id and ad_role_tabaccess.ad_tab_id=v_tab;
  if coalesce(v_visiblesettings,'NON')!='NON' then
     v_isshown:= case v_visiblesettings when 'HIDDEN' then 'N' else 'Y' end;
  end if;
  -- Load Field Values from ad_role_tabaccess_field, if exists
  select ad_role_tabaccess_field.editsetting,ad_role_tabaccess_field.visiblesetting into v_visiblesettings from  ad_role_tabaccess_field,ad_role_tabaccess 
                                                                                    where ad_role_tabaccess.ad_role_tabaccess_id=ad_role_tabaccess_field.ad_role_tabaccess_id 
                                                                                    and ad_role_tabaccess_field.ad_role_tabaccess_id=v_tabaccess and ad_field_id=p_field_id;
   if coalesce(v_visiblesettings,'NON')!='NON' then
     v_isshown:= case v_visiblesettings when 'HIDDEN' then 'N' else 'Y' end;
   end if;
   -- Role specific the field is visble, but if it is instance specific not shown in Grid, it is likewise not shown.
   if coalesce(v_isshown,'Y')='Y' then
     -- Field Instance settings --- Only select showinrelation, Visblesettings in fieldinstance is only for Edit Mode...
     select showinrelation into v_isshown from ad_fieldinstance where ad_field_v_id= p_field_id;
     if v_isshown is null or v_isshown='NON' then 
             select coalesce(showinrelation,'N') into v_isshown from ad_field_v where ad_field_v_id= p_field_id;
     end if;
   end if;
  RETURN v_isshown;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


SELECT zsse_dropfunction ('ad_tab_copy_convert');
CREATE OR REPLACE FUNCTION ad_tab_copy_convert(p_string character varying, p_len int)
  RETURNS character varying AS
$BODY$
-- ***********************************************************************
-- 11-08-2014 Änderung: Sonderzeichen werden eliminiert
-- SELECT ad_tab_copy_convert('123456', 5) ;   -- "12345"
-- SELECT ad_tab_copy_convert('123456`', 7) ;  -- "123456" 
-- 
-- fruehere Tests daher deaktiviert:
-- SELECT ad_tab_copy_convert(NULL, 5) ;       -- NULL
-- SELECT ad_tab_copy_convert('', 5) ;         -- NULL
-- SELECT ad_tab_copy_convert('123456', 5) ;   -- "1234`"
-- SELECT ad_tab_copy_convert('123456', 6) ;   -- "12345`"
-- SELECT ad_tab_copy_convert('123456', 7) ;   -- "123456`"
-- SELECT ad_tab_copy_convert('123456`', 5) ;  -- "1234`"
-- SELECT ad_tab_copy_convert('123456`', 6) ;  -- "12345`"
-- SELECT ad_tab_copy_convert('123456`', 7) ;  -- "123456`"
-- ***********************************************************************
DECLARE 
    v_string character varying;
    i NUMERIC := 0;
BEGIN
  IF (p_string IS NULL) THEN
 -- SELECT ad_tab_copy_convert(NULL, 60) ;  
    raise notice '%', 'ad_tab_copy_convert(' || 'NULL' || ')' || ', ' || p_len || ')' || '=' || 'NULL';
    RETURN NULL;
  ELSE
    v_string := p_string;
  END IF;
  IF (LENGTH(v_string) >= p_len) then
 -- v_string := SUBSTR(v_string, 1, p_len-1); 
    v_string := SUBSTR(v_string, 1, p_len); -- 11-08-2014 auf max. Laenge lt. Parameter kuerzen
  END IF;
    
  IF (LENGTH(v_string) >= 1) then
    i := INSTR(v_string, '`'); 
    IF (i = 0) THEN 
   -- v_string := v_string || '`'; -- "hallo'"
      v_string := v_string; -- 11-08-2014: unveraendert zurueckgeben 
    ELSE
      i := LEAST(i, p_len);
      IF (LENGTH(v_string) >= 1) THEN 
     -- v_string := SUBSTR(v_string, 1, i-1) || '`';
        v_string := SUBSTR(v_string, 1, i-1); -- 11-08-2014: ohne Sonderzeichen zurueckgeben
      END IF;
    END IF;
   END IF; 
   RAISE NOTICE '%', 'ad_tab_copy_convert(''' || COALESCE(p_string, 'NULL') || ''', ' || p_len || ')' || '=' || '''' || COALESCE(v_string, 'NULL') || '''';
   RETURN v_string;
EXCEPTION
  WHEN OTHERS THEN
    RETURN '** Error FUNCTION ad_tab_copy_convert() **';
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE COST 100; 


  
CREATE OR REPLACE FUNCTION ad_tab_copy(p_pinstance_id character varying)
  RETURNS void AS
$BODY$
-- ***********************************************************************
-- ad_tab_copy - Copy fields of a tab to another (fw)
-- 2014-07-24 mh - fixed: UPDATE ad_field_trl
-- ***********************************************************************
DECLARE
  v_new_tab_id VARCHAR;
  v_old_tab_id VARCHAR;
  v_module_id VARCHAR;
  v_column_id VARCHAR;
  v_field AD_FIELD%ROWTYPE;
  v_field_trl AD_FIELD_TRL%ROWTYPE;
  v_fieldsCount NUMERIC := 0;
  v_nextno VARCHAR;
  v_message VARCHAR := '';
  v_errormsg VARCHAR := '';
  cur_parameter RECORD;
BEGIN
  RAISE NOTICE '%', 'Updating PInstance - Processing ' || p_pinstance_id;
  v_errormsg := 'PInstanceNotFound';
  PERFORM ad_update_pinstance(p_pinstance_id, null, 'Y', null, null);

  BEGIN
    FOR cur_parameter IN (
      SELECT 
        ad_pinstance.record_id, 
        ad_pinstance_para.parametername, 
        ad_pinstance_para.p_string, 
        ad_pinstance_para.p_number, 
        ad_pinstance_para.p_date
      FROM ad_pinstance
      LEFT JOIN ad_pinstance_para ON 
        ad_pinstance.ad_pinstance_id = ad_pinstance_para.ad_pinstance_id
      WHERE 
        ad_pinstance.ad_pinstance_id = p_pinstance_id
      ORDER BY 
        ad_pinstance_para.seqno)
    LOOP
      v_new_tab_id := cur_parameter.record_id;
      IF (cur_parameter.parametername = 'AD_Tab_ID') THEN
        v_old_tab_id := cur_parameter.p_string;
        RAISE NOTICE '%','  AD_Tab_ID = ' || v_old_tab_id  || ' Source AD_Tab_ID';
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter = ' || cur_parameter.parametername;
      END IF;
    END LOOP;
    RAISE NOTICE '%','  Record_ID=' || v_new_tab_id || ' Target AD_Tab_ID';
      
   --****************************************************************************************
   -- Copy process
   --****************************************************************************************
      SELECT ad_module_id INTO v_module_id FROM ad_tab WHERE ad_tab_id = v_new_tab_id;
       
      FOR v_field IN 
        (SELECT * FROM ad_field WHERE ad_tab_id = v_old_tab_id ORDER BY seqno)
      LOOP
        v_nextno := get_uuid();
        
       -- get column_id for target-table 
        SELECT ad_column_id INTO v_column_id FROM ad_column WHERE
          lower(ad_column.columnname) = lower((select columnname from ad_column where ad_column.ad_column_id = v_field.ad_column_id)) and
          ad_column.ad_table_id = (select ad_table_id from ad_tab where ad_tab.ad_tab_id = v_new_tab_id);
        IF (v_column_id is null) THEN
          v_column_id := v_field.ad_column_id;
          v_message := v_message || 'The field - ' || v_field.name || ' - has no fitting column entry in its table.</br>';
        END IF;
     -- list fields to be copied by SeqNo
     --   RAISE NOTICE '%', '  * Copy ' 
     --     || ' No='        || (v_fieldsCount+1)
     --     || ' SeqNo='     || v_field.seqno 
     --     || ' FieldName=''' || v_field.name || ''''
     --     || ' Length='    || LENGTH(v_field.name);
          
        INSERT INTO ad_field(
          ad_field_id, 
          ad_tab_id, 
          ad_client_id, 
          ad_org_id,
          isactive, 
          created, 
          createdby, 
          updated,
          updatedby, 
          name, 
          description, 
          help,
          iscentrallymaintained, 
          ad_column_id, 
          ad_fieldgroup_id, 
          isdisplayed,
          displaylogic, 
          displaylength, 
          isreadonly,
          seqno, 
          sortno, 
          issameline,
          isfieldonly, 
          isencrypted, 
          ad_module_id,
          showinrelation, 
          isfirstfocusedfield, 
          gridseqno, 
          gridlength,
          readonlylogic,
          mandantorylogic,
          defaultvalue,
          ad_callout_id,    
          ad_process_id,
          isidentifiercolumn, 
          isfiltercolumn,
          fieldreference,
          tablereference,
          validationrule,
          referenceurl,
          template,
          maxlength,
          buttonclass,
          includesemptyitem,
          style,
          onchangeevent,
          required,
          colstotal       )
        VALUES(
          v_nextno, 
          v_new_tab_id,
          v_field.ad_client_id,	
          v_field.ad_org_id,
          v_field.isactive, 
          to_date(now()),		
          '0', 				
          to_date(now()),
          '0', 				
          v_field.name, 	
          v_field.description, 
          v_field.help,			
          v_field.iscentrallymaintained,
          v_column_id, 
          v_field.ad_fieldgroup_id, 
          v_field.isdisplayed,		
          v_field.displaylogic, 
          v_field.displaylength,
          v_field.isreadonly,	
          v_field.seqno, 		
          v_field.sortno, 
          v_field.issameline,	
          v_field.isfieldonly, 	
          v_field.isencrypted,		
          v_module_id,
          v_field.showinrelation,
          v_field.isfirstfocusedfield,
          v_field.gridseqno, 	
          v_field.gridlength,
          v_field.readonlylogic,
          v_field.mandantorylogic,
          v_field.defaultvalue,
          v_field.ad_callout_id,    
          v_field.ad_process_id,
          v_field.isidentifiercolumn, 
          v_field.isfiltercolumn,
          v_field.fieldreference,
          v_field.tablereference,
          v_field.validationrule,
          v_field.referenceurl,
          v_field.template,
          v_field.maxlength,
          v_field.buttonclass,
          v_field.includesemptyitem,
          v_field.style,
          v_field.onchangeevent,
          v_field.required,
          v_field.colstotal 
        );
       -- translate several languages for current field 
        FOR v_field_trl IN -- read source translations
          (SELECT * FROM ad_field_trl trl WHERE trl.ad_field_id = v_field.AD_Field_ID)
        LOOP
         -- update target translations inserted by trigger 
          UPDATE ad_field_trl 
          SET 
            name = ad_tab_copy_convert(v_field_trl.name, 60),
            description = ad_tab_copy_convert(v_field_trl.description, 255),
            help = ad_tab_copy_convert(v_field_trl.help, 2000)
          WHERE ad_field_trl.ad_field_v_id = v_nextno AND ad_field_trl.ad_language = v_field_trl.ad_language;
        END LOOP;
        v_fieldsCount := v_fieldsCount + 1;
      END LOOP;
      
    -- finish: update ad_pinstance
      v_message := v_message || '@Copied@=' || v_fieldsCount;
      RAISE NOTICE '%', 'Updating PInstance - Finished ' || v_message;
      PERFORM ad_update_pinstance(p_pinstance_id, null, 'N', 1, v_message);
      RETURN;
  END;
EXCEPTION
 WHEN OTHERS THEN
	v_errormsg := '@ERROR=' || sqlerrm;
	RAISE NOTICE '%', v_errormsg;
	PERFORM ad_update_pinstance(p_pinstance_id, null, 'N', 0, v_errormsg) ;
	RETURN;
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ad_tab_copy(character varying)
  OWNER TO tad;

 
CREATE OR REPLACE FUNCTION ad_module_dependent(p_childmodule_id character varying, p_parentmodule_id character varying) RETURNS character
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
* Contributor(s): Stefan Zimmermann, 02/2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2012 Stefan Zimmermann
* Contributions: Correct model Object Mapping to Module
****************************************************************************************************************************************************/

  v_childVersion     VARCHAR(10);   --OBTG:VARCHAR2--

  --TYPE RECORD IS REFCURSOR;
  Cur_Dependencies RECORD;
BEGIN
  IF p_childModule_ID = p_parentModule_ID or p_childmodule_id='0' THEN
    RETURN 'Y';
  END IF;
  
  SELECT VERSION
    INTO v_childVersion
    FROM AD_Module
   WHERE AD_Module_ID = p_childModule_ID;
  
  FOR Cur_Dependencies IN (SELECT *
                             FROM AD_Module_Dependency
                            WHERE AD_Module_ID = p_parentModule_ID) LOOP
    IF Cur_Dependencies.IsIncluded='N' --Check just dependencies, not inclusions
       AND Cur_Dependencies.AD_Dependent_Module_ID = p_childModule_ID 
       AND ((Cur_Dependencies.endVersion IS NULL AND Cur_Dependencies.startVersion = v_childVersion)
         OR (Cur_Dependencies.endVersion IS NOT NULL AND v_childVersion BETWEEN Cur_Dependencies.startVersion AND Cur_Dependencies.endVersion)) THEN
      RETURN 'Y';
    END IF;
    IF AD_MODULE_DEPENDENT(p_childModule_ID, Cur_Dependencies.AD_Dependent_Module_ID) = 'Y' THEN --check it recursively, to find dependencies in child modules
      RETURN 'Y';
    END IF;
     
  END LOOP;
  RETURN 'N';
  EXCEPTION WHEN OTHERS THEN RETURN 'N';
END ; $_$;



CREATE OR REPLACE FUNCTION ad_generate_java_mapping()
  RETURNS void AS
$BODY$ DECLARE 
Winid character varying :='';
Wname character varying; -- Window Name
Mclass  character varying; -- Module Class
Mname character varying; -- Name of the Tab in the Window
Cname character varying :='org.openbravo.erpWindows.'; -- Fixed class prefix
Modid character varying ;
TabID character varying ; -- Only used in Modules
 v_cur_tabs                ad_tab%rowtype;
v_cur_window  ad_window%rowtype;
begin

for v_cur_window in  (select * from ad_window) 
LOOP
      Winid:=v_cur_window.ad_window_id;
      select AD_MAPPING_FORMAT(name) into Wname from ad_window where ad_window_id=Winid;
      for v_cur_tabs in (select * from ad_tab where ad_window_id=Winid)
        LOOP
          select  case ad_module_id when '0' then '' else javapackage end into Mclass from ad_module where ad_module_id=(select  ad_module_id from ad_window where ad_window_id=Winid);
          select ad_model_object_id into Modid from ad_model_object where isdefault='Y' and ad_tab_id=v_cur_tabs.ad_tab_id;
          Mname:= AD_MAPPING_FORMAT(v_cur_tabs.name);
          select  case ad_module_id when '0' then '' else v_cur_tabs.ad_tab_id end into TabID from ad_module where ad_module_id=v_cur_tabs.ad_module_id;
          update ad_model_object set classname=Cname||case Mclass when '' then '' else Mclass||'.' end||Wname||'.'||Mname||TabID where ad_model_object_id=Modid;
          update ad_model_object_mapping set mappingname='/'||case Mclass when '' then '' else Mclass||'.' end||Wname||'/'||Mname||TabID||'_Relation.html' where mappingname like '%_Relation.html' and ad_model_object_id=Modid;
          update ad_model_object_mapping set mappingname='/'||case Mclass when '' then '' else Mclass||'.' end||Wname||'/'||Mname||TabID||'_Edition.html' where mappingname like '%_Edition.html' and ad_model_object_id=Modid;
          update ad_model_object_mapping set mappingname='/'||case Mclass when '' then '' else Mclass||'.' end||Wname||'/'||Mname||TabID||'_Excel.xls' where mappingname like '%_Excel.xls' and ad_model_object_id=Modid;
        end loop;
end loop;
end;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION ad_window_copy (
  p_pinstance_id varchar
)
RETURNS void AS
$body$
 DECLARE
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    v_AD_Window_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_NextNo_T VARCHAR(32); --OBTG:VARCHAR2--
    v_NextNo_F VARCHAR(32); --OBTG:VARCHAR2--
    v_NoOfTabs NUMERIC:=0;
    v_NoOfFields NUMERIC:=0;
    Cur_Tabs RECORD;
    Cur_Fields ad_field%ROWTYPE; -- Cur_Fields RECORD;
    Winid character varying :='';
    Wname character varying;
    Mclass  character varying;
    Mname character varying;
    Cname character varying :='org.openbravo.erpWindows.';
    Modid character varying ;
    v_MappingTabID character varying ;
    v_mdl_isindevelopment VARCHAR;
    v_mdl_name VARCHAR;
    v_lnk VARCHAR;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
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
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Record_ID:=Cur_Parameter.Record_ID;
      IF(Cur_Parameter.ParameterName='AD_Window_ID') THEN
        v_AD_Window_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  AD_Window_ID=' || v_AD_Window_ID ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; -- Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    v_ResultStr:='GetEntityType';
 raise notice '%','XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

    -- check, if tab/module in development (ad_tab_mod_trg)
    FOR Cur_Tabs IN
      (SELECT tab.ad_module_id, tab.name FROM ad_tab tab WHERE ad_window_id = v_ad_window_id)
    LOOP
      SELECT mdl.name, mdl.isindevelopment INTO v_mdl_name, v_mdl_isindevelopment FROM ad_module mdl WHERE mdl.ad_module_id = Cur_Tabs.ad_module_id; -- SmartUI?
      IF (COALESCE(v_mdl_isindevelopment, 'N') <> 'Y') THEN
        v_lnk := '';
      /* toDo:
        v_lnk := (SELECT zsse_htmldirectlink (
                '../Module/Module_Relation.html', --p_targetwindowurl varchar,
                'document.frmMain.inpadModuleId', -- p_fieldid varchar,
                '2C556DC110134849BF4BB2B657D5B181', --p_key varchar, _Module_ID
                v_mdl_name  -- p_text varchar
                ));
                */
        --  Cannot insert/delete objects in a module not in development.
        RAISE EXCEPTION '%', '@20533@' || ' (' || 'Module=' || '''' || v_mdl_name || '''' || ',' || ' Tab=' || '''' || Cur_Tabs.name || '''' || ')' || '</br>' || v_lnk;
      END IF;
    END LOOP; -- Tab

    -- Record_ID is the Window_ID to copy to
    FOR Cur_Tabs IN
      (SELECT *  FROM AD_Tab  WHERE AD_Window_ID=v_AD_Window_ID)
    LOOP
      select get_uuid() into v_NextNo_T;
      -- Insert
      INSERT
      INTO AD_Tab
        (
          AD_TAB_ID, AD_Window_ID,
          AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
          NAME, DESCRIPTION, HELP, AD_TABLE_ID, TabLevel,
          SEQNO, ISSINGLEROW, ISINFOTAB, ISTRANSLATIONTAB, ISREADONLY,
          AD_COLUMN_ID, HASTREE, WHERECLAUSE, ORDERBYCLAUSE, COMMITWARNING,
          AD_PROCESS_ID, PROCESSING, AD_Module_ID
        )
        VALUES
        (
          v_NextNo_T, v_Record_ID,
          Cur_Tabs.AD_CLIENT_ID, Cur_Tabs.AD_ORG_ID, Cur_Tabs.ISACTIVE, TO_DATE(NOW()), Cur_Tabs.CREATEDBY, TO_DATE(NOW()), Cur_Tabs.UPDATEDBY,
          Cur_Tabs.NAME, Cur_Tabs.DESCRIPTION, Cur_Tabs.HELP, Cur_Tabs.AD_TABLE_ID, Cur_Tabs.TabLevel,
          Cur_Tabs.SEQNO, Cur_Tabs.ISSINGLEROW, Cur_Tabs.ISINFOTAB, Cur_Tabs.ISTRANSLATIONTAB, Cur_Tabs.ISREADONLY,
          Cur_Tabs.AD_COLUMN_ID, Cur_Tabs.HASTREE, Cur_Tabs.WHERECLAUSE, Cur_Tabs.ORDERBYCLAUSE, Cur_Tabs.COMMITWARNING,
          Cur_Tabs.AD_PROCESS_ID, Cur_Tabs.PROCESSING, Cur_Tabs.AD_Module_ID
        )
        ;
      --  Translate
      UPDATE AD_Tab_Trl
        SET Name=
        (SELECT Name
        FROM AD_Tab_Trl s
        WHERE s.AD_Tab_ID=Cur_Tabs.AD_Tab_ID
          AND s.AD_Language=AD_Tab_Trl.AD_Language
        )
        ,
        Description=
        (SELECT Description
        FROM AD_Tab_Trl s
        WHERE s.AD_Tab_ID=Cur_Tabs.AD_Tab_ID
          AND s.AD_Language=AD_Tab_Trl.AD_Language
        )
        ,
        Help=
        (SELECT Help
        FROM AD_Tab_Trl s
        WHERE s.AD_Tab_ID=Cur_Tabs.AD_Tab_ID
          AND s.AD_Language=AD_Tab_Trl.AD_Language
        )
      WHERE AD_Tab_Trl.AD_Tab_ID=v_NextNo_T;
      -- Correct JAVA - Mappings
      select case ad_module_id when '0' then '' else javapackage end into Mclass from ad_module where ad_module_id=(select  ad_module_id from ad_window where ad_window_id=v_Record_ID);
      select ad_model_object_id into Modid from ad_model_object where isdefault='Y' and ad_tab_id=v_NextNo_T;
      Mname:= AD_MAPPING_FORMAT(Cur_Tabs.NAME);
      select AD_MAPPING_FORMAT(name) into Wname from ad_window where ad_window_id=v_Record_ID;
      select  case ad_module_id when '0' then '' else v_NextNo_T end into v_MappingTabID from ad_module where ad_module_id=Cur_Tabs.AD_Module_ID;
      update ad_model_object set classname=Cname||case Mclass when '' then '' else Mclass||'.' end||Wname||'.'||Mname||v_MappingTabID where ad_model_object_id=Modid;
      update ad_model_object_mapping set mappingname='/'||case Mclass when '' then '' else Mclass||'.' end||Wname||'/'||Mname||v_MappingTabID||'_Relation.html' where mappingname like '%_Relation.html' and ad_model_object_id=Modid;
      update ad_model_object_mapping set mappingname='/'||case Mclass when '' then '' else Mclass||'.' end||Wname||'/'||Mname||v_MappingTabID||'_Edition.html' where mappingname like '%_Edition.html' and ad_model_object_id=Modid;
      update ad_model_object_mapping set mappingname='/'||case Mclass when '' then '' else Mclass||'.' end||Wname||'/'||Mname||v_MappingTabID||'_Excel.xls' where mappingname like '%_Excel.xls' and ad_model_object_id=Modid;
      -- copy ad_field
      FOR Cur_Fields IN
        (SELECT *  FROM ad_field  WHERE ad_tab_id=Cur_Tabs.AD_Tab_ID) -- RECORD changed to ROWTYPE
      LOOP
        v_NextNo_F := get_uuid();
        Cur_Fields.ad_field_id := v_NextNo_F;
        Cur_Fields.ad_tab_id := v_NextNo_T;
        Cur_Fields.Created := TO_DATE(NOW());
        Cur_Fields.CreatedBy := '0';
        Cur_Fields.Updated := TO_DATE(NOW());
        Cur_Fields.UpdatedBy := '0';
        -- Insert
        INSERT INTO ad_field VALUES (Cur_Fields.*); -- write rowtype-buffer into db-record

        -- update translation
        UPDATE AD_Field_Trl
          SET Name=
          (SELECT Name
          FROM AD_Field_Trl s
          WHERE s.AD_Field_v_ID=Cur_Fields.AD_Field_ID
            AND s.AD_Language=AD_Field_Trl.AD_Language
          )
          ,
          Description=
          (SELECT Description
          FROM AD_Field_Trl s
          WHERE s.AD_Field_v_ID=Cur_Fields.AD_Field_ID
            AND s.AD_Language=AD_Field_Trl.AD_Language
          )
          ,
          Help=
          (SELECT Help
          FROM AD_Field_Trl s
          WHERE s.AD_Field_v_ID=Cur_Fields.AD_Field_ID
            AND s.AD_Language=AD_Field_Trl.AD_Language
          )
        WHERE AD_Field_Trl.AD_Field_v_ID=v_NextNo_F;
        --
        v_NoOfFields:=v_NoOfFields + 1;
      END LOOP; -- Field
      v_NoOfTabs:=v_NoOfTabs + 1;
    END LOOP; -- Tab
    v_Message:='@Copied@=' || v_NoOfTabs || '/' || v_NoOfFields;
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ad_update_pinstance(p_pinstance_id character varying, p_ad_user_id character varying, p_isprocessing character, p_result numeric, p_message character varying) RETURNS void
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
v_count numeric;
pid varchar:='645271C57F8C4DA4A1F64C7ACE37B101'; -- Message Dumper Process
BEGIN
  --  Update AD_PInstance
--  RAISE NOTICE '%','AD_UPDATE_PINSTANCE' ;
  -- Create a instance if there is none with a dummy process id, just to log messages.
  select count(*) into v_count from AD_PINSTANCE WHERE AD_PInstance_ID=p_PInstance_ID;
  if (v_count=0 and p_isprocessing='N' and  p_message is not null and p_pinstance_id is not null) then
        insert into AD_PINSTANCE (AD_PINSTANCE_ID, AD_PROCESS_ID, RECORD_ID, ISPROCESSING, AD_USER_ID, RESULT, ERRORMSG, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY)
        values(p_pinstance_id,pid,p_pinstance_id,p_isprocessing,'0',p_Result,substr(p_Message,1,20000),'C726FEC915A54A0995C568555DA5BB3C','0','0','0');

  else
    UPDATE AD_PINSTANCE
        SET Updated=TO_DATE(NOW()),
        UpdatedBy=COALESCE(p_AD_User_ID, UpdatedBy),
        IsProcessing=p_IsProcessing,
        Result=p_Result, -- 1=success
        ErrorMsg=substr(p_Message,1,20000)
    WHERE AD_PInstance_ID=p_PInstance_ID;
  end if;
  -- COMMIT;
END ; $_$;


CREATE OR REPLACE FUNCTION ad_get_pinstance_result(p_pinstance_id character varying) RETURNS varchar
LANGUAGE plpgsql AS $_$ 
DECLARE 
    v_count numeric;
    v_return varchar:='OK';
BEGIN
  select RESULT into v_count from AD_PINSTANCE WHERE AD_PInstance_ID=p_PInstance_ID;
  if v_count!=1 then
    select 'ERROR'||coalesce(ERRORMSG,'') into v_return from AD_PINSTANCE WHERE AD_PInstance_ID=p_PInstance_ID;
  end if;
  return v_return;
END ; $_$;


CREATE OR REPLACE FUNCTION ad_column_identifier_ref_sql(p_tableref character varying, p_tablename character varying, p_columnname character varying, p_reference_id character varying, p_reference_value_id character varying) RETURNS character varying
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
***************************************************************************************************************************************************
BUGFIX: If no Key Column found- Still generate executable SQL

*****************************************************/
  v_SQL               VARCHAR:=''; --OBTG:VARCHAR2--
  v_TableDir          VARCHAR; --OBTG:VARCHAR2--
  v_FieldValue        VARCHAR ; --OBTG:VARCHAR2--
  v_FieldDisplay      VARCHAR ; --OBTG:VARCHAR2--
  v_DisplayValue      CHAR(1):='N';
  v_IsTranslated      CHAR(1):='N';
  v_NewTableName      VARCHAR ; --OBTG:VARCHAR2--
  v_NewColumnName     VARCHAR ; --OBTG:VARCHAR2--
  v_NewReference      VARCHAR; --OBTG:VARCHAR2--
  v_NewReferenceValue VARCHAR; --OBTG:VARCHAR2--
  v_KeyReference      VARCHAR; --OBTG:VARCHAR2--
  v_firstColumn       BOOLEAN:=TRUE;
  END_PROCESS         BOOLEAN:=FALSE;
BEGIN
  IF p_Reference_ID='17' THEN -- LIST
    v_SQL:='coalesce ((SELECT NAME FROM AD_REF_LIST_V ';
    v_SQL:=v_SQL || 'WHERE AD_Language=L.AD_LANGUAGE ';
    v_SQL:=v_SQL || 'AND Value=' || p_TableRef||'.'|| p_ColumnName || ' ';
    v_SQL:=v_SQL || 'AND AD_Reference_ID=''' || p_Reference_Value_ID || '''), '''')';
  ELSIF p_Reference_ID='18' THEN -- TABLE
    SELECT ad_table.tablename,
      c1.columnname as keyName,
      c1.ad_reference_id,
      c2.columnname as displayName,
      isvaluedisplayed,
      c2.AD_REFERENCE_ID,
      c2.AD_REFERENCE_VALUE_ID
    INTO v_TableDir,
      v_FieldValue,
      v_KeyReference,
      v_FieldDisplay,
      v_DisplayValue,
      v_NewReference,
      v_NewReferenceValue
    FROM ad_ref_table,
      ad_table,
      ad_column c1,
      ad_column c2
    WHERE ad_ref_table.ad_table_id=ad_table.ad_table_id
      AND ad_ref_table.ad_key=c1.ad_column_id
      AND ad_ref_table.ad_display=c2.ad_column_id
      AND ad_ref_table.ad_reference_id=p_Reference_Value_ID;
    v_SQL:='coalesce ((SELECT ';
    IF v_DisplayValue='Y' THEN
      v_SQL:=v_SQL || 'VALUE || '' - '' || ';
    END IF;
    v_SQL:=v_SQL || AD_COLUMN_IDENTIFIER_REF_SQL(p_TableRef||'T', v_TableDir, v_FieldDisplay, v_NewReference, v_NewReferenceValue) ;
    v_SQL:=v_SQL || ' FROM ' || v_TableDir || ' '||p_TableRef||'T WHERE '||p_TableRef||'T.' || v_FieldValue || '='|| p_TableRef||'.'|| p_ColumnName||'),'''') ';
  ELSIF p_Reference_ID IN('19', '30', '31', '35', '25', '800011', '32') THEN -- SEARCHS
    IF p_Reference_ID='25' THEN
      v_TableDir:='C_ValidCombination';
    ELSIF p_Reference_ID='31' THEN
      v_TableDir:='M_Locator';
    ELSIF p_Reference_ID='800011' THEN
      v_TableDir:='M_Product';
    ELSIF p_Reference_ID='32' THEN
      v_TableDir:='AD_Image';
    ELSE
      v_TableDir:=SUBSTR(p_ColumnName, 1, LENGTH(p_ColumnName) -3) ;
    END IF;
  ELSE
    SELECT c.ISTRANSLATED
    INTO v_IsTranslated
    FROM AD_COLUMN c,
      AD_TABLE t
    WHERE c.AD_TABLE_ID=t.AD_TABLE_ID
      AND UPPER(t.TABLENAME)=UPPER(p_TableName)
      AND UPPER(c.COLUMNNAME)=UPPER(p_ColumnName) ;
    IF v_IsTranslated='Y' THEN
      SELECT MAX(TableName)
      INTO v_NewTableName
      FROM AD_TABLE
      WHERE UPPER(TableName)=UPPER(p_TableName) || '_TRL';
      IF v_NewTableName IS NOT NULL THEN
        SELECT MAX(c.COLUMNNAME)
        INTO v_NewColumnName
        FROM AD_COLUMN c,
          AD_TABLE t
        WHERE c.AD_TABLE_ID=t.AD_TABLE_ID
          AND UPPER(t.TABLENAME)=UPPER(v_NewTableName)
          AND UPPER(c.COLUMNNAME)=UPPER(p_ColumnName) ;
        IF v_NewColumnName IS NOT NULL THEN
          SELECT MAX(COLUMNNAME)
          INTO v_FieldValue
          FROM AD_COLUMN c,
            AD_TABLE t
          WHERE c.AD_TABLE_ID=t.AD_TABLE_ID
            AND UPPER(t.TABLENAME)=UPPER(p_TableName)
            AND(c.ISKEY='Y'
            OR c.ISSECONDARYKEY='Y')
            AND UPPER(c.COLUMNNAME) <> 'AD_LANGUAGE';
          v_SQL:='coalesce ((SELECT COALESCE(TO_CHAR(MAX(' || p_TableRef || 'T.' || v_NewColumnName || ')), TO_CHAR(' || p_TableRef || '.' || p_ColumnName || ')) FROM ' || v_NewTableName || ' ' || p_TableRef || 'T WHERE '|| p_TableRef||'T.' || v_FieldValue || '='|| p_TableRef||'.'|| v_FieldValue || ' AND ' || p_TableRef || 'T.AD_LANGUAGE=L.AD_LANGUAGE), '''') ';
        END IF;
      END IF;
    END IF;
    IF v_SQL IS NULL OR v_SQL='' THEN
      v_SQL:='TO_CHAR(COALESCE(TO_CHAR('||p_TableRef||'.'|| p_ColumnName||'),''''))';
    END IF;
  END IF;
  IF p_Reference_ID IN('19', '32', '30', '31', '35', '25', '800011') THEN
    DECLARE
      v_PartialDisplay VARCHAR(2000) ; --OBTG:VARCHAR2--
      v_KeyName        VARCHAR(50) ; --OBTG:VARCHAR2--
--TYPE RECORD IS REFCURSOR;
      Cur_Columns RECORD;
      Cur_KeyName RECORD;
    BEGIN
      FOR Cur_KeyName IN
        (SELECT c.ColumnName
        FROM AD_Column c,
          AD_Table t
        WHERE c.AD_Table_ID=t.AD_Table_ID
          AND UPPER(t.TableName)=UPPER(v_TableDir)
          AND c.isKey='Y'
        )
      LOOP
        v_KeyName:=Cur_KeyName.ColumnName;
        EXIT;
      END LOOP;
      IF v_KeyName IS NULL THEN
        -- SZ: If no Key Column found- Still generate executable SQL
        v_SQL:='''';
        END_PROCESS:=true;
      END IF;
      IF(NOT END_PROCESS) THEN
        FOR Cur_Columns IN
          (SELECT c.ColumnName,
            c.AD_Reference_ID,
            c.AD_Reference_Value_ID,
            t.TableName
          FROM AD_Column c,
            AD_Table t
          WHERE c.AD_Table_ID=t.AD_Table_ID
            AND UPPER(t.TableName)=UPPER(v_TableDir)
            AND c.isIdentifier='Y'
          ORDER BY c.seqno
          )
        LOOP
          IF v_firstColumn THEN
            v_firstColumn:=FALSE;
          ELSE
            v_SQL:=v_SQL || '||'' - ''||';
          END IF;
          v_SQL:=v_SQL || AD_COLUMN_IDENTIFIER_REF_SQL(p_TableRef||'T', v_TableDir, Cur_Columns.ColumnName, Cur_Columns.AD_Reference_ID, Cur_Columns.AD_Reference_Value_ID) ;
        END LOOP;
        v_SQL:='coalesce ((SELECT ' || v_SQL || ' FROM '|| v_TableDir || ' '||p_TableRef||'T WHERE '||p_TableRef||'T.' || v_KeyName || '='|| p_TableRef||'.'|| p_ColumnName||'), '''') ';
      END IF; --END_PROCESS
    END;
  END IF;
  ---- <<END_PROCESS>>
  RETURN v_SQL;
  /*EXCEPTION
  WHEN OTHERS THEN
  RETURN '**'; */
END ; $_$;


ALTER FUNCTION public.ad_column_identifier_ref_sql(p_tableref character varying, p_tablename character varying, p_columnname character varying, p_reference_id character varying, p_reference_value_id character varying) OWNER TO tad;

--
-- Name: ad_module_dbprefix_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_module_dbprefix_trg() RETURNS trigger
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
* Contributions: Removed Module Registration
****************************************************************************************************************************************************/

  V_Char char;
  v_old_name varchar(60);
  v_type VARCHAR(60); --OBTG:varchar2--
  startsWithLetter boolean;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


   IF v_type = 'T' THEN
     RAISE EXCEPTION '%', '@DBPrefixNotAllowedInTemplate@'; --OBTG:-20000--
   END IF;

   IF (TG_OP = 'UPDATE') THEN
     v_old_name := OLD.NAME;
   END IF;
   
   --Check DB_Prefix
   IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
     startsWithLetter := false;
     FOR I IN 1..LENGTH(new.name) LOOP
       v_char := substr(new.name,i,1);
       IF NOT ((v_char between 'A' and 'Z') 
               or (v_char between '0' and '9'))  THEN
        RAISE EXCEPTION '%', '@20531@' ; --OBTG:-20531--
       END IF;
       IF v_char between 'A' and 'Z' THEN
         startsWithLetter := true;
       END IF;
       IF NOT startsWithLetter THEN
         RAISE EXCEPTION '%', '@20531@' ; --OBTG:-20531--
       END IF;
     END LOOP;
   END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


--
-- Name: ad_module_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_module_trg() RETURNS trigger
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
* Contributions: Removed Module Registration
****************************************************************************************************************************************************/

  V_Char char;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


 --Tranlsation management
 IF TG_OP = 'INSERT' THEN
    --  Create Translation Row
      INSERT INTO AD_Module_Trl
        (
          AD_Module_Trl_ID, AD_Module_ID, AD_Language, AD_Client_ID,
          AD_Org_ID, IsActive, Created,
          CreatedBy, Updated, UpdatedBy,
          Description, Help, License,
          IsTranslated
        )
      SELECT get_uuid(), new.AD_Module_ID, AD_Language, new.AD_Client_ID, 
        new.AD_Org_ID, new.IsActive, new.Created, 
        new.CreatedBy, new.Updated, new.UpdatedBy, 
        new.Description, new.Help, new.License,
        'N'
      FROM AD_Language
      WHERE IsActive='Y'
        AND IsSystemLanguage='Y'
        AND isonly4format='N'
        and (AD_Language.AD_Language != new.ad_language or new.ad_language is null);
 END IF;
 
 IF TG_OP = 'UPDATE' THEN
       
    
    IF(COALESCE(old.License, '.') <> COALESCE(NEW.License, '.')
    OR COALESCE(old.Description, '.') <> COALESCE(NEW.Description, '.')
    OR COALESCE(old.Help, '.') <> COALESCE(NEW.Help, '.'))
    THEN
      UPDATE AD_Module_Trl
        SET IsTranslated='N',
        Updated=TO_DATE(NOW())
      WHERE AD_Module_ID=new.AD_Module_ID;
    END IF;
   END IF;
   -- Versioning
   if new.ad_module_id='0'  and (new.version!=old.version or new.version_label!=old.version_label) then
       update ad_module set version=new.version,version_label=new.version_label where ispartofdistribution='Y' and ad_module_id!='0';
   end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;

CREATE OR REPLACE FUNCTION ad_module_version_trg() RETURNS trigger
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
* Contributor(s): Stefan Zimmermann, 2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2012 Stefan Zimmermann
* Contributions: Removed Module Registration
****************************************************************************************************************************************************/

  v1 VARCHAR(10);
  v2 VARCHAR(10);
  v3 VARCHAR(10);
  vlab VARCHAR(60);
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    IF instr(new.VERSION,'.') <= 0 OR instr(new.VERSION,'.',1,2) <= 0 OR instr(new.VERSION,'.',1,3) > 0 THEN
       RAISE EXCEPTION '%', 'The version has to be formatted like x.y.z where x, y and z are integers.'; --OBTG:-20104--
    END IF;

    v1 := SUBSTR(new.VERSION,1,instr(new.VERSION,'.')-1);
    v2 := SUBSTR(new.VERSION,instr(new.VERSION,'.')+1,instr(new.VERSION,'.',1,2)-instr(new.VERSION,'.')-1);
    v3 := SUBSTR(new.VERSION,instr(new.VERSION,'.',1,2)+1);
    
    IF TRIM(TRANSLATE(v1, '0123456789','')) <> '' OR TRIM(TRANSLATE(v2, '0123456789','')) <> '' OR TRIM(TRANSLATE(v3, '0123456789','')) <> '' THEN
       RAISE EXCEPTION '%', 'The version has to be formatted like x.y.z where x, y and z are integers.'; --OBTG:-20104--
    END IF;
    IF TG_OP = 'INSERT' THEN
          -- Versioning
         if new.ispartofdistribution='Y' then
             select version, version_label into v1,vlab from ad_module where ad_module_id='0';
             new.version=v1;
             new.version_label = vlab;
             new.seqno=0;
         end if;
     end if;
     IF TG_OP = 'UPDATE' THEN
          -- Versioning
         if new.ad_module_id='0' and (old.version!=new.version or coalesce(old.seqno,0)!= coalesce(new.seqno,0)) then
             new.version_label = new.version||'.'||lpad(to_char(coalesce(new.seqno,0)),3,'0');
         end if;
     end if;

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;




CREATE OR REPLACE FUNCTION ad_updateBuildId(p_doexecute character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$ DECLARE

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Updates Build Counter
*****************************************************/
    v_i numeric;
BEGIN
    if p_doexecute='DOEXECUTE' then
          select seqno into v_i from ad_module where ad_module_id='0';
          if v_i=999 then 
             update ad_module set seqno=1 where ad_module_id='0';
          else
             update ad_module set seqno=v_i+1  where ad_module_id='0';
          end if;
    end if;
    return 'OK';
END ; $_$;

CREATE OR REPLACE FUNCTION ad_role_GenerateRole (
  p_pinstance_id  VARCHAR  -- source to copy from
 )
RETURNS VARCHAR -- 'SUCCESS'
AS $body$
-- SELECT ad_role_GenerateRole('role template');  --> neue Rolle generieren
DECLARE
  Cur_Parameter           RECORD;
  v_message               VARCHAR := '';
  v_now                   TIMESTAMP := now();
  v_src_role_id           VARCHAR;
  v_new_role_id           VARCHAR;
  v_ad_role_tabaccess_id  VARCHAR;

  v_Record_ID             VARCHAR;
  v_user_id               VARCHAR;
  v_new_name              VARCHAR;
  v_link                  VARCHAR;

 -- record buffer declaration
  v_role                  ad_role%rowtype;
  v_role_orgaccess        ad_role_orgaccess%rowtype;
  v_user_roles            ad_user_roles%rowtype;
  v_window_access         ad_window_access%rowtype;
  v_process_access        ad_process_access%rowtype;
  v_form_access           ad_form_access%rowtype;
  v_workflow_access       ad_workflow_access%rowtype;
  v_task_access           ad_task_access%rowtype;
  v_preference_access     ad_preference_access%rowtype;
  v_role_tabaccess        ad_role_tabaccess%rowtype;
  v_role_tabaccess_field  ad_role_tabaccess_field%rowtype;

BEGIN
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'Y', NULL, NULL) ; -- 'Y'=processing
      SELECT pi.Record_ID, pi.ad_User_ID
      INTO v_Record_ID, v_user_id
      FROM ad_pinstance pi WHERE pi.ad_PInstance_ID = p_PInstance_ID;
      IF (v_Record_ID IS NULL) then
         RAISE NOTICE '%','Entry for PInstance not found - Using parameter &1=''' || p_PInstance_ID || ''' instead';
         v_src_role_id := p_PInstance_ID;
         v_user_id     := '0';
         v_new_name    := 'GENERATED';
      ELSE
        -- Get Parameters
        v_message := 'ReadingParameters';
        FOR Cur_Parameter IN
          (SELECT para.parametername, para.p_string
           FROM AD_PInstance pi, AD_PInstance_Para para
           WHERE 1=1
            AND pi.AD_PInstance_ID = para.AD_PInstance_ID
            AND pi.AD_PInstance_ID = p_PInstance_ID
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('AD_Role_ID') ) THEN
            v_new_name := Cur_Parameter.p_string;
          END IF;
        END LOOP; -- Get Parameter

        RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID;
        v_src_role_id := v_Record_ID;
      END IF;
    END IF;

 -- plausi
    IF ( isempty(p_PInstance_ID) ) THEN
      RAISE EXCEPTION '%', 'SQL-PROC ad_role_GenerateRole: '|| '@InvalidArguments@'|| ' p_PInstance_ID '|| COALESCE(p_PInstance_ID, '') ; -- GOTO EXCEPTION
    END IF;
    IF ( isempty(v_src_role_id) ) THEN
      RAISE EXCEPTION '%', 'SQL-PROC ad_role_GenerateRole: '|| '@InvalidArguments@'|| ' v_src_role_id= '|| COALESCE(v_src_role_id, ''); -- GOTO EXCEPTION
    END IF;
    IF ( isempty(v_new_name) ) THEN
      v_new_name:= 'GENERATED';
      --RAISE EXCEPTION '%', 'SQL-PROC ad_role_GenerateRole: '||'@InvalidArguments@'|| ' new_Name '||COALESCE(v_new_name, ''); -- GOTO EXCEPTION
    END IF;

 -- part 1/12: ad_role
    v_new_role_id := get_uuid();
 -- v_new_role_id := 'role_copied';
    SELECT * INTO v_role FROM ad_role WHERE ad_role_id = v_src_role_id; -- read template into rowtype-buffer
    IF isempty(v_role.ad_role_id) THEN
      RAISE EXCEPTION '%', '@RoleIdNotFound@'; -- GOTO EXCEPTION
    END IF;

    -- Unique changes before insert, all other changes after inserting, because of triggers
    v_role.ad_role_id := v_new_role_id;
    v_role.created := v_now;
    v_role.createdby := v_user_id;
    v_role.updated := v_now;
    v_role.updatedby := v_user_id;
    v_role.name := v_new_name; -- unique name required
 -- v_role.description := '';
    v_role.ClientList := ''; -- updated via trigger ad_role_orgaccess_trg
    v_role.OrgList := '';    -- updated via trigger ad_role_orgaccess_trg
    v_role.btn_generaterole := 'N';

   -- insert copy of template-ad_role, update ad_role after inserting ad_role_orgaccess
    INSERT INTO ad_role SELECT v_role.*; -- %rowtype

 -- part 2/12: ad_role_orgaccess / Unternhemen
    -- get original data from template
    FOR v_role_orgaccess IN (SELECT * FROM ad_role_orgaccess WHERE ad_role_orgaccess.ad_role_id = v_src_role_id) -- ad_role_orgaccess%rowtype;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_role_orgaccess.ad_role_orgaccess_id := get_uuid();
      v_role_orgaccess.ad_role_id := v_new_role_id;
      v_role_orgaccess.created := v_now;
      v_role_orgaccess.createdby := v_user_id;
      v_role_orgaccess.updated := v_now;
      v_role_orgaccess.updatedby := v_user_id;
      INSERT INTO ad_role_orgaccess SELECT v_role_orgaccess.*; -- %rowtype
    END LOOP;

 -- part 3/12: user_roles / Nutzer
    FOR v_user_roles IN (SELECT * FROM ad_user_roles ur WHERE ur.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_user_roles.ad_user_roles_id := get_uuid();
      v_user_roles.ad_role_id := v_new_role_id;
      v_user_roles.created := v_now;
      v_user_roles.createdby := v_user_id;
      v_user_roles.updated := v_now;
      v_user_roles.updatedby := v_user_id;
      INSERT INTO ad_user_roles SELECT v_user_roles.*; -- %rowtype, Trigger ad_role_orgaccess_trg: UPDATE ad_role.Clientlist, ad_role.OrgList
    END LOOP;

 -- part 4/12: window_access / Fenster
    FOR v_window_access IN (SELECT * FROM ad_window_access wa WHERE wa.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_window_access.ad_window_access_id := get_uuid();
      v_window_access.ad_role_id := v_new_role_id;
      v_window_access.created := v_now;
      v_window_access.createdby := v_user_id;
      v_window_access.updated := v_now;
      v_window_access.updatedby := v_user_id;
      INSERT INTO ad_window_access SELECT v_window_access.*; -- %rowtype
    END LOOP;

 -- part 5/12: process_access / Prozesse
    FOR v_process_access IN (SELECT * FROM ad_process_access pa WHERE pa.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_process_access.ad_process_access_id := get_uuid();
      v_process_access.ad_role_id := v_new_role_id;
      v_process_access.created := v_now;
      v_process_access.createdby := v_user_id;
      v_process_access.updated := v_now;
      v_process_access.updatedby := v_user_id;
      INSERT INTO ad_process_access SELECT v_process_access.*; -- %rowtype
    END LOOP;

 -- part 6/12: ad_form_access / Aktionen
    FOR v_form_access IN (SELECT * FROM ad_form_access fa WHERE fa.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_form_access.ad_form_access_id := get_uuid();
      v_form_access.ad_role_id := v_new_role_id;
      v_form_access.created := v_now;
      v_form_access.createdby := v_user_id;
      v_form_access.updated := v_now;
      v_form_access.updatedby := v_user_id;
      -- check before insert bacause of ad_role trigger
      IF(SELECT COUNT(*) FROM ad_form_access WHERE ad_role_id = v_form_access.ad_role_id AND ad_form_id = v_form_access.ad_form_id) = 0 THEN
        INSERT INTO ad_form_access SELECT v_form_access.*; -- %rowtype
      END IF;
    END LOOP;

 -- part 7/12: ad_workflow_access / Workflows
    FOR v_workflow_access IN (SELECT * FROM ad_workflow_access wfa WHERE wfa.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_workflow_access.ad_workflow_access_id := get_uuid();
      v_workflow_access.ad_role_id := v_new_role_id;
      v_workflow_access.created := v_now;
      v_workflow_access.createdby := v_user_id;
      v_workflow_access.updated := v_now;
      v_workflow_access.updatedby := v_user_id;
      INSERT INTO ad_workflow_access SELECT v_workflow_access.*; -- %rowtype
    END LOOP;

 -- part 8/12: ad_task_access / Aufgaben
    FOR v_task_access IN (SELECT * FROM ad_task_access ta WHERE ta.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_task_access.ad_task_access_id := get_uuid();
      v_task_access.ad_role_id := v_new_role_id;
      v_task_access.created := v_now;
      v_task_access.createdby := v_user_id;
      v_task_access.updated := v_now;
      v_task_access.updatedby := v_user_id;
      INSERT INTO ad_task_access SELECT v_task_access.*; -- %rowtype
    END LOOP;

 -- part 9/12: ad_preference_access / Preferences
    FOR v_preference_access IN (SELECT * FROM ad_preference_access pa WHERE pa.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_preference_access.ad_preference_access_id := get_uuid();
      v_preference_access.ad_role_id := v_new_role_id;
      v_preference_access.created := v_now;
      v_preference_access.createdby := v_user_id;
      v_preference_access.updated := v_now;
      v_preference_access.updatedby := v_user_id;
      INSERT INTO ad_preference_access SELECT v_preference_access.*; -- %rowtype
    END LOOP;

 -- part 10/12: ad_role_tabaccess / Tab Access
    FOR v_role_tabaccess IN (SELECT * FROM ad_role_tabaccess rta WHERE rta.ad_role_id = v_src_role_id) -- %rowtype
    LOOP
      v_ad_role_tabaccess_id := v_role_tabaccess.ad_role_tabaccess_id; -- save key
      v_role_tabaccess.ad_role_tabaccess_id := get_uuid();
      v_role_tabaccess.ad_role_id := v_new_role_id;
      v_role_tabaccess.created := v_now;
      v_role_tabaccess.createdby := v_user_id;
      v_role_tabaccess.updated := v_now;
      v_role_tabaccess.updatedby := v_user_id;
      INSERT INTO ad_role_tabaccess SELECT v_role_tabaccess.*; -- %rowtype

   -- part 11/12: ad_role_tabaccess_field / Field Access
      FOR v_role_tabaccess_field IN (SELECT * FROM ad_role_tabaccess_field rtaf WHERE rtaf.ad_role_tabaccess_id = v_ad_role_tabaccess_id) -- %rowtype
      LOOP
        v_role_tabaccess_field.ad_role_tabaccess_field_id := get_uuid();
        v_role_tabaccess_field.ad_role_tabaccess_id := v_role_tabaccess.ad_role_tabaccess_id;
        v_role_tabaccess_field.created := v_now;
        v_role_tabaccess_field.createdby := v_user_id;
        v_role_tabaccess_field.updated := v_now;
        v_role_tabaccess_field.updatedby := v_user_id;
        INSERT INTO ad_role_tabaccess_field SELECT v_role_tabaccess_field.*; -- %rowtype
     END LOOP;
    END LOOP;

 -- part 12/12: finally update for inserted ad_role / update-trigger, if existent
    UPDATE ad_role SET btn_generaterole = 'Y' WHERE ad_role.ad_role_id = v_new_role_id; -- set button as used, just for documentation

    v_message = '@RoleGenerated@' || ': ' || v_new_name; -- vgl. ad_message
 -- ToDo
 -- v_link := (SELECT zsse_htmldirectlink('../Role/Role_Relation.html', 'document.frmMain.inpadRoleId', v_new_role_id, v_new_name));
 -- v_message := v_message  || '</br>' || v_link || '<Input type="hidden" name="inpadRoleId" value="' || v_new_role_id || '" id="AD_Role_ID">';

    PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'N', 1, v_Message) ; -- NULL=p_ad_user_id, 'N'=isProcessing, 1=success
    RAISE NOTICE '%','Updating PInstance - finished ';

    RETURN v_message;

  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_message := '@ERROR=' || SQLERRM;
  RAISE NOTICE '% %', 'SQL-PROC ad_role_GenerateRole: ', v_message;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

CREATE OR REPLACE FUNCTION ad_role_orgaccess_trg() RETURNS trigger
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
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
    * Contributions OpenZ Software GmbH, 2022
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * $Id: AD_Role_OrgAccess_Trg.sql,v 1.3 2003/05/04 06:46:07 jjanke Exp $
    ***
    * Title: Update AD_Role.OrgList / ClientList
    *  for all Roles as otherwise mutating trigger
    * Description:
    ************************************************************************/
    --TYPE RECORD IS REFCURSOR;
  CUR_Role RECORD;
  Cur_Org RECORD;
  v_ClientList VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_OrgList    VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Client_ID VARCHAR(32):=-1; --OBTG:VARCHAR2--
  v_role varchar;  
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  IF TG_OP = 'DELETE' THEN 
    v_role:=old.ad_role_id;
  ELSE 
    v_role:=new.ad_role_id; 
  END IF; 
  -- For each Role
  FOR CUR_Role IN
    (SELECT *  FROM AD_Role where ad_role_id=v_role )
  LOOP
    v_ClientList:='';
    v_OrgList:='';
    v_Client_ID:=-1;
    -- Assemble Client/OrgList
    FOR Cur_Org IN
      (
      SELECT AD_Client_ID,
        AD_Org_ID
      FROM AD_Role_OrgAccess
      WHERE AD_Role_ID=CUR_Role.AD_Role_ID
        AND IsActive='Y'
      ORDER BY AD_Client_ID,
        AD_Org_ID
      )
    LOOP
      IF(v_Client_ID <> Cur_Org.AD_Client_ID) THEN
        v_Client_ID:=Cur_Org.AD_Client_ID;
        IF(LENGTH(v_ClientList) <> 0) THEN
          v_ClientList:=v_ClientList || ',';
        END IF;
        v_ClientList:=v_ClientList || Cur_Org.AD_Client_ID;
      END IF;
      -- Org
      IF(LENGTH(v_OrgList) <> 0) THEN
        v_OrgList:=v_OrgList || ',';
      END IF;
      v_OrgList:=v_OrgList || Cur_Org.AD_Org_ID;
    END LOOP;
    -- Org
    --
    IF(v_ClientList IS NULL OR LENGTH(v_ClientList)=0) THEN
      v_ClientList:=' ';
    END IF;
    IF(v_OrgList IS NULL OR LENGTH(v_OrgList)=0) THEN
      v_OrgList:=' ';
    END IF;
    RAISE NOTICE '%',CUR_Role.Name || ': Client=' || CUR_Role.ClientList || '->' || v_ClientList || ' - Org= ' || CUR_Role.OrgList || '->' || v_OrgList ;
    -- Update Role
    UPDATE AD_Role
      SET ClientList=v_ClientList,
      OrgList=v_OrgList
    WHERE AD_ROLE.AD_ROLE_ID=CUR_Role.AD_ROLE_ID;
  END LOOP;
  -- Role
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;

select zsse_DropTrigger ('ad_role_orgaccess_trg','ad_role_orgaccess');

CREATE TRIGGER ad_role_orgaccess_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON ad_role_orgaccess FOR EACH ROW
  EXECUTE PROCEDURE ad_role_orgaccess_trg();
  

CREATE OR REPLACE FUNCTION ad_field_mod_trg() RETURNS trigger
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
* All portions are Copyright (C) 2008-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 2016
************************************************************************/
  devTemplate NUMERIC;
  devModule   CHAR(1);
  cuerrentID  VARCHAR(32); --OBTG:VARCHAR2--
  cuerrentModuleID  VARCHAR(32); --OBTG:VARCHAR2--
  vAux NUMERIC;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  --Check if trying to move object from module not in dev
  IF (TG_OP = 'UPDATE') THEN
      SELECT COUNT(*) 
        INTO vAux
        FROM AD_MODULE
       WHERE AD_MODULE_ID = old.AD_Module_ID
        AND isindevelopment = 'N';
      IF (vAux!=0) THEN
        RAISE EXCEPTION '%', '@ChangeNotInDevModule@'; --OBTG:-20000--
      END IF;
  END IF;
  
IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
      SELECT COUNT(*) 
        INTO vAux
        FROM AD_MODULE
       WHERE AD_MODULE_ID = new.AD_Module_ID
        AND isindevelopment = 'N';
      IF (vAux!=0) THEN
        RAISE EXCEPTION '%', '@ChangeNotInDevModule@'; --OBTG:-20000--
      END IF;
  END IF;

 
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


CREATE OR REPLACE FUNCTION ad_menu_trl_mod_trg() 
  RETURNS trigger LANGUAGE 'plpgsql'  AS
$BODY$ DECLARE 

  devTemplate NUMERIC;
 
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 


  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE m,ad_menu me,ad_menu_trl met
   WHERE m.ad_module_id=me.ad_module_id and me.ad_menu_id=met.ad_menu_id and IsInDevelopment = 'Y';
     
    
  if  devTemplate=0 then  
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT' OR TG_OP = 'DELETE') THEN
        RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
  ENd IF;
  
 
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $BODY$ ;

select zsse_DropTrigger ('ad_menu_trl_mod_trg','ad_menu_trl');

CREATE TRIGGER ad_menu_trl_mod_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON ad_menu_trl FOR EACH ROW
  EXECUTE PROCEDURE ad_menu_trl_mod_trg();
 
 

CREATE OR REPLACE FUNCTION ad_field_trl_mod_trg() 
  RETURNS trigger LANGUAGE 'plpgsql'  AS
$BODY$ DECLARE 

  devTemplate NUMERIC;
 
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 


  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE m,ad_field me,ad_field_trl met
   WHERE m.ad_module_id=me.ad_module_id and me.ad_field_id=met.ad_field_id and IsInDevelopment = 'Y';
     
    
  if  devTemplate=0 then  
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT' OR TG_OP = 'DELETE') THEN
        RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
  ENd IF;
  
 
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $BODY$ ;

select zsse_DropTrigger ('ad_field_trl_mod_trg','ad_field_trl');

CREATE TRIGGER ad_field_trl_mod_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON ad_field_trl FOR EACH ROW
  EXECUTE PROCEDURE ad_field_trl_mod_trg();

CREATE OR REPLACE FUNCTION ad_tab_trl_mod_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/
  devTemplate NUMERIC;
 
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 


  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE m,ad_tab me,ad_tab_trl met
   WHERE m.ad_module_id=me.ad_module_id and me.ad_tab_id=met.ad_tab_id and IsInDevelopment = 'Y';
     
    
  if  devTemplate=0 then  
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT' OR TG_OP = 'DELETE') THEN
        RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
  ENd IF;
  
 
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $BODY$ LANGUAGE 'plpgsql' ;

select zsse_DropTrigger ('ad_tab_trl_mod_trg','ad_tab_trl');

CREATE TRIGGER ad_tab_trl_mod_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON ad_tab_trl FOR EACH ROW
  EXECUTE PROCEDURE ad_tab_trl_mod_trg();


CREATE OR REPLACE FUNCTION ad_window_trl_mod_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/
  devTemplate NUMERIC;
 
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 


  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE m,ad_window me,ad_window_trl met
   WHERE m.ad_module_id=me.ad_module_id and me.ad_window_id=met.ad_window_id and IsInDevelopment = 'Y';
     
    
  if  devTemplate=0 then  
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT' OR TG_OP = 'DELETE') THEN
        RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
  ENd IF;
  
 
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $BODY$ LANGUAGE 'plpgsql' ;

select zsse_DropTrigger ('ad_window_trl_mod_trg','ad_window_trl');

CREATE TRIGGER ad_window_trl_mod_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON ad_window_trl FOR EACH ROW
  EXECUTE PROCEDURE ad_window_trl_mod_trg();


CREATE OR REPLACE FUNCTION ad_column_mod_trg()
  RETURNS trigger AS
$BODY$ DECLARE 


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
* All portions are Copyright (C) 2008-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s):  ______________________________________.
************************************************************************/
  devTemplate NUMERIC;
  devModule   CHAR(1);
  cuerrentID  VARCHAR(32); --OBTG:VARCHAR2--
  cuerrentModuleID  VARCHAR(32); --OBTG:VARCHAR2--
  vAux NUMERIC;
   v_refname varchar; 
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE
   WHERE IsInDevelopment = 'Y'
     AND Type = 'T';
     
  --Check if trying to move object from module not in dev
  IF (TG_OP = 'UPDATE') THEN
    IF (COALESCE(NEW.AD_Module_ID , '.') != COALESCE(OLD.AD_Module_ID , '.')) THEN
      SELECT COUNT(*) 
        INTO vAux
        FROM AD_MODULE
       WHERE AD_MODULE_ID = old.AD_Module_ID
        AND isindevelopment = 'N';
      IF (vAux!=0) THEN
        RAISE EXCEPTION '%', '@ChangeNotInDevModule@'; --OBTG:-20000--
      END IF;
    END IF;
  END IF;
     
  IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    new.name=new.columnname;
    cuerrentID := new.AD_Column_ID;
    cuerrentModuleID := new.AD_Module_ID;
  ELSE
    cuerrentID := old.AD_Column_ID;
    cuerrentModuleID := old.AD_Module_ID;
  END IF;
  
  SELECT M.IsInDevelopment
    INTO devModule
    FROM AD_MODULE M
   WHERE M.AD_MODULE_ID = cuerrentModuleID;
     
  IF (TG_OP = 'UPDATE' AND devTemplate=0 AND devModule='N') THEN
    IF (
        COALESCE(NEW.AD_Client_ID , '.') != COALESCE(OLD.AD_Client_ID , '.') OR
        COALESCE(NEW.AD_Org_ID , '.') != COALESCE(OLD.AD_Org_ID , '.') OR
        COALESCE(NEW.IsActive , '.') != COALESCE(OLD.IsActive , '.') OR
        COALESCE(NEW.Name , '.') != COALESCE(OLD.Name , '.') OR
        COALESCE(NEW.Description , '.') != COALESCE(OLD.Description , '.') OR
        COALESCE(NEW.Help , '.') != COALESCE(OLD.Help , '.') OR
        COALESCE(NEW.ColumnName , '.') != COALESCE(OLD.ColumnName , '.') OR
        COALESCE(NEW.AD_Table_ID , '.') != COALESCE(OLD.AD_Table_ID , '.') OR
        COALESCE(NEW.AD_Reference_ID , '.') != COALESCE(OLD.AD_Reference_ID , '.') OR
        COALESCE(NEW.AD_Reference_Value_ID , '.') != COALESCE(OLD.AD_Reference_Value_ID , '.') OR
        COALESCE(NEW.AD_Val_Rule_ID , '.') != COALESCE(OLD.AD_Val_Rule_ID , '.') OR
        COALESCE(NEW.FieldLength , 0) != COALESCE(OLD.FieldLength , 0) OR
        COALESCE(NEW.DefaultValue , '.') != COALESCE(OLD.DefaultValue , '.') OR
        COALESCE(NEW.IsKey , '.') != COALESCE(OLD.IsKey , '.') OR
        COALESCE(NEW.IsParent , '.') != COALESCE(OLD.IsParent , '.') OR
        COALESCE(NEW.IsMandatory , '.') != COALESCE(OLD.IsMandatory , '.') OR
        COALESCE(NEW.IsUpdateable , '.') != COALESCE(OLD.IsUpdateable , '.') OR
        COALESCE(NEW.ReadOnlyLogic , '.') != COALESCE(OLD.ReadOnlyLogic , '.') OR
        COALESCE(NEW.IsIdentifier , '.') != COALESCE(OLD.IsIdentifier , '.') OR
        COALESCE(NEW.SeqNo , 0) != COALESCE(OLD.SeqNo , 0) OR
        COALESCE(NEW.IsTranslated , '.') != COALESCE(OLD.IsTranslated , '.') OR
        COALESCE(NEW.IsEncrypted , '.') != COALESCE(OLD.IsEncrypted , '.') OR
        COALESCE(NEW.Callout , '.') != COALESCE(OLD.Callout , '.') OR
        COALESCE(NEW.VFormat , '.') != COALESCE(OLD.VFormat , '.') OR
        COALESCE(NEW.ValueMin , '.') != COALESCE(OLD.ValueMin , '.') OR
        COALESCE(NEW.ValueMax , '.') != COALESCE(OLD.ValueMax , '.') OR
        COALESCE(NEW.IsSelectionColumn , '.') != COALESCE(OLD.IsSelectionColumn , '.') OR
        COALESCE(NEW.AD_Element_ID , '.') != COALESCE(OLD.AD_Element_ID , '.') OR
        COALESCE(NEW.AD_Process_ID , '.') != COALESCE(OLD.AD_Process_ID , '.') OR
        COALESCE(NEW.IsSessionAttr , '.') != COALESCE(OLD.IsSessionAttr , '.') OR
        COALESCE(NEW.IsSecondaryKey , '.') != COALESCE(OLD.IsSecondaryKey , '.') OR
        COALESCE(NEW.IsDesencryptable , '.') != COALESCE(OLD.IsDesencryptable , '.') OR
        COALESCE(NEW.AD_Callout_ID , '.') != COALESCE(OLD.AD_Callout_ID , '.') OR
        COALESCE(NEW.Developmentstatus , '.') != COALESCE(OLD.Developmentstatus , '.') OR
        COALESCE(NEW.AD_Module_ID , '.') != COALESCE(OLD.AD_Module_ID , '.') OR
        COALESCE(NEW.Position , 0) != COALESCE(OLD.Position , 0) OR
        COALESCE(NEW.IsTransient , '.') != COALESCE(OLD.IsTransient , '.') OR
        COALESCE(NEW.isTransientCondition , '.') != COALESCE(OLD.isTransientCondition , '.') OR
        1=2) THEN
      RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
  END IF;
  IF (TG_OP = 'INSERT' OR  TG_OP = 'UPDATE') THEN -- check multiple reference_id = 'ID' (col.ad_reference_id = '13') not allowed
    IF (TG_OP = 'INSERT' AND (SELECT COUNT(*) FROM ad_column col WHERE col.ad_table_id = new.ad_table_id AND col.ad_reference_id = '13' )=1 and new.ad_reference_id = '13' ) OR
       (TG_OP = 'UPDATE' AND (SELECT COUNT(*) FROM ad_column col WHERE col.ad_table_id = new.ad_table_id AND col.ad_reference_id = '13' )=1 and new.ad_reference_id = '13' and old.ad_reference_id != '13') THEN 
      RAISE EXCEPTION '% %','@SaveErrorNotUnique@', '/ multiple records with ad_column.ad_reference_id=13 (''ID'') not allowed';
    END IF;
    -- The Element on Primary Keys must be of same name than columname 
    If new.iskey='Y' and new.ad_reference_id='13' and new.ad_element_id is not null then
         select columnname into v_refname from ad_element where ad_element_id=new.ad_element_id;
         if upper(v_refname)!=upper(new.columnname) then
                RAISE EXCEPTION '%', 'The Element on Primary Keys must be of same name than columname';
         end if;
    end if;
  END IF;  
  
  IF ((TG_OP = 'DELETE' OR TG_OP = 'INSERT') AND devModule='N') THEN
    RAISE EXCEPTION '%', 'Cannot insert/delete objects in a module not in development.'; --OBTG:-20533--
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ad_element_mod_trg (
)
RETURNS trigger AS
$body$
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
* All portions are Copyright (C) 2008 Openbravo SL
* All Rights Reserved.
* Contributor(s):  ______________________________________.
************************************************************************/
 DECLARE 
  devTemplate NUMERIC;
  devModule   CHAR(1);
  cuerrentID  VARCHAR(32); --OBTG:VARCHAR2--
  cuerrentModuleID  VARCHAR(32); --OBTG:VARCHAR2--
  vAux NUMERIC;
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;

  --Check if trying to move object from module not in dev
  IF (TG_OP = 'UPDATE') THEN
    IF (COALESCE(NEW.AD_Module_ID , '.') != COALESCE(OLD.AD_Module_ID , '.')) THEN
      SELECT COUNT(*) 
        INTO vAux
        FROM AD_MODULE
       WHERE AD_MODULE_ID = old.AD_Module_ID
        AND isindevelopment = 'N';
      IF (vAux!=0) THEN
        RAISE EXCEPTION '%', '@ChangeNotInDevModule@'; --OBTG:-20000--
      END IF;
    END IF;
  END IF;

  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE
   WHERE IsInDevelopment = 'Y'
     AND Type = 'T';
     
  IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    cuerrentID := new.AD_Element_ID;
    cuerrentModuleID := new.AD_Module_ID;
  ELSE
    cuerrentID := old.AD_Element_ID;
    cuerrentModuleID := old.AD_Module_ID;
  END IF;
  
  SELECT M.IsInDevelopment
    INTO devModule
    FROM AD_MODULE M
   WHERE M.AD_MODULE_ID = cuerrentModuleID;
     
  IF (TG_OP = 'UPDATE' AND devTemplate=0 AND devModule='N') THEN
    IF (
        COALESCE(NEW.AD_Client_ID , '.') != COALESCE(OLD.AD_Client_ID , '.') OR
        COALESCE(NEW.AD_Org_ID , '.') != COALESCE(OLD.AD_Org_ID , '.') OR
        COALESCE(NEW.IsActive , '.') != COALESCE(OLD.IsActive , '.') OR
        COALESCE(NEW.ColumnName , '.') != COALESCE(OLD.ColumnName , '.') OR
        COALESCE(NEW.Name , '.') != COALESCE(OLD.Name , '.') OR
        COALESCE(NEW.PrintName , '.') != COALESCE(OLD.PrintName , '.') OR
        COALESCE(NEW.Description , '.') != COALESCE(OLD.Description , '.') OR
        COALESCE(NEW.Help , '.') != COALESCE(OLD.Help , '.') OR
        COALESCE(NEW.PO_Name , '.') != COALESCE(OLD.PO_Name , '.') OR
        COALESCE(NEW.PO_PrintName , '.') != COALESCE(OLD.PO_PrintName , '.') OR
        COALESCE(NEW.PO_Description , '.') != COALESCE(OLD.PO_Description , '.') OR
        COALESCE(NEW.PO_Help , '.') != COALESCE(OLD.PO_Help , '.') OR
        COALESCE(NEW.AD_Module_ID , '.') != COALESCE(OLD.AD_Module_ID , '.') OR
        1=2) THEN
      RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
   
  END IF;
  IF (TG_OP = 'UPDATE') then
    if new.columnname!=old.columnname and (select count(*) from ad_column where ad_element_id=new.ad_element_id and iskey='Y' and ad_reference_id='13')>0 then
         RAISE EXCEPTION '%', 'The Element on Primary Keys must be of same name than columname';
    end if;
  end if;
  IF (TG_OP = 'INSERT') THEN
    IF (devModule = 'N') THEN
      RAISE EXCEPTION '%', 'Cannot INSERT objects in a module not in development.'; --OBTG:-20533--
    END IF;
  END IF; -- (TG_OP = 'INSERT')
  
  IF (TG_OP = 'DELETE') THEN 
    IF (devModule = 'N') THEN
      RAISE EXCEPTION '%', 'Cannot DELETE objects in a module not in development.'; --OBTG:-20533--
    END IF;
    
   -- check plant data collection : barcode 
   -- pdc-dialogs
    IF (OLD.ad_element_id = '872C3C326AB64D1EBABDD49A1E138136') THEN
      RAISE EXCEPTION 'Cannot DELETE record pdc_bc_dialog_timefeedback=''%''', '872C3C326AB64D1EBABDD49A1E138136';
    END IF;
    IF (OLD.ad_element_id = '872C3C326AB64D1EBABDD49A1E138136') THEN
      RAISE EXCEPTION 'Cannot DELETE record pdc_bc_dialog_material_consumption=''%''', '872C3C326AB64D1EBABDD49A1E138136';
    END IF;
    IF (OLD.ad_element_id = 'EDD4E08D4C324816AE3C1B09155A51A6') THEN
      RAISE EXCEPTION 'Cannot DELETE record pdc_bc_dialog_material_return=''%''', 'EDD4E08D4C324816AE3C1B09155A51A6';
    END IF;
    IF (OLD.ad_element_id = '56BA860751594541972B4CFF06CB0FC5') THEN
      RAISE EXCEPTION 'Cannot DELETE record pdc_bc_dialog_acknowledgement=''%''', '56BA860751594541972B4CFF06CB0FC5';
    END IF;
    IF (OLD.ad_element_id = 'D0F216CC7D9D4EA0A7528744BB8D544C') THEN 
      RAISE EXCEPTION 'Cannot DELETE pdc_bc_btn_splitbatch=''%''', 'D0F216CC7D9D4EA0A7528744BB8D544C';
    END IF;
   -- pdc-buttons
    IF (OLD.ad_element_id = '8521E358B73444A6A999C55CBCCACC75') THEN
      RAISE EXCEPTION 'Cannot DELETE pdc_bc_btn_next=''%''', '8521E358B73444A6A999C55CBCCACC75';
    END IF;
    IF (OLD.ad_element_id = 'B28DAF284EA249C48F932C98F211F257') THEN
      RAISE EXCEPTION 'Cannot DELETE pcd_bc_btn_ready=''%''', 'B28DAF284EA249C48F932C98F211F257';
    END IF;
    IF (OLD.ad_element_id = '57C99C3D7CB5459BADEC665F78D3D6BC') THEN
      RAISE EXCEPTION 'Cannot DELETE record pdc_bc_cancel=''%''', '57C99C3D7CB5459BADEC665F78D3D6BC';
    END IF;
    IF (OLD.ad_element_id = '48AE377FD5224514A54E9AE666BE5CC7') THEN
      RAISE EXCEPTION 'Cannot DELETE record pdc_bc_btn_finish=''%''', '48AE377FD5224514A54E9AE666BE5CC7';
    END IF;
  END IF; -- (TG_OP = 'DELETE')
  
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; 
  END IF; 

END;
$body$
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION ad_ref_fieldcolumn_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
BEGIN
    
   
    IF new.ad_table_id is not null and new.fieldreference is not null THEN
       RAISE EXCEPTION '%', 'You can only use a Direct Table Reference or a field Reference Validation'; --OBTG:-20104--
    END IF;

    

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;

SELECT zsse_droptrigger('ad_ref_fieldcolumn_trg', 'ad_ref_fieldcolumn');
CREATE TRIGGER ad_ref_fieldcolumn_trg
   AFTER INSERT OR UPDATE 
  ON ad_ref_fieldcolumn FOR EACH ROW
  EXECUTE PROCEDURE ad_ref_fieldcolumn_trg();
  
CREATE OR REPLACE FUNCTION ad_role_pcategories(p_role in varchar)
  RETURNS varchar AS
    $BODY$ DECLARE 
    v_cur record;
    v_return varchar:='';
    begin
    for v_cur in  (select m_product_category_id from ad_role_productcategoryaccess where ad_role_id=p_role) 
    LOOP
        if v_return!='' then
            v_return:=v_return||' , ';
        end if;
        v_return:=v_return||chr(39)||v_cur.m_product_category_id||chr(39);
    end loop;
    if v_return='' then
        v_return:='(select m_product_category_id from m_product_category)';
    end if;
    return v_return;
end;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE OR REPLACE FUNCTION ad_column_trg2() RETURNS trigger LANGUAGE plpgsql AS $_$ DECLARE 

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
* All portions are Copyright (C) 2008-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s):  S. Zimmermann, 2016______________________________________.
************************************************************************/
  --TYPE RECORD IS REFCURSOR;
  CUR_Clients RECORD;
  v_TableName VARCHAR(40); --OBTG:VARCHAR2--
  v_NextNo VARCHAR(32); --OBTG:VARCHAR2--
  v_Aux NUMERIC;
      
BEGIN

    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;



      SELECT count(*) 
        INTO v_Aux
        FROM AD_TABLE T, 
             AD_PACKAGE M
       WHERE T.AD_TABLE_ID = new.AD_Table_ID
         AND M.AD_PACKAGE_ID = T.AD_PACKAGE_ID
         AND M.AD_MODULE_ID != new.AD_Module_ID
         AND NOT EXISTS (SELECT 1 
                          FROM AD_MODULE_DBPREFIX P
                          WHERE P.AD_MODULE_ID = new.AD_Module_ID 
                          AND instr(upper(new.columnname), upper(P.name)||'_') = 1
                          AND instr(upper(new.name), upper(P.name)||'_') = 1)
         AND NOT EXISTS( SELECT 1
                             FROM AD_EXCEPTIONS, ad_table t
                             WHERE TYPE='COLUMN'
                             AND t.AD_Table_ID = new.AD_Table_ID
                             AND UPPER(NAME2)=UPPER(T.Tablename)
                             AND UPPER(NAME1)=UPPER(new.Columnname));
  
  IF v_Aux != 0 THEN
    RAISE EXCEPTION '%', '@ColumnDBPrefix@' ; --OBTG:-20000--
  END IF;
  
  IF AD_IsJavaWord(new.Name)='Y' THEN
    RAISE EXCEPTION '%', '@NotAllowedColumnName@ "'||new.name||'" @ReservedJavaWord@' ; --OBTG:-20000--
  END IF;
  
  /**
  * Create Sequence for DocumentNo and Value columns
  */
  IF (lower(new.ColumnName) =lower( 'DocumentNo' ) OR lower(new.ColumnName) = lower('Value')) THEN
    SELECT TableName INTO v_TableName
    FROM ad_table
    WHERE ad_table.ad_table_id = new.ad_table_id;
         
    FOR CUR_Clients IN (
      SELECT ad_client_id
      FROM ad_client
      WHERE NOT EXISTS (SELECT 1 FROM ad_sequence WHERE name = 'DocumentNo_' || v_tablename)
        AND ad_client_id <> '0'
    ) LOOP
      SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('AD_Sequence', CUR_Clients.ad_client_id) ;
      INSERT INTO AD_Sequence (
        AD_Sequence_ID, AD_Client_ID, AD_Org_ID, IsActive, 
        Created, CreatedBy, Updated, UpdatedBy,
        Name, Description, 
        VFormat, IsAutoSequence, IncrementNo, 
        StartNo, CurrentNext, CurrentNextSys, 
        IsTableID, Prefix, Suffix, StartNewYear
      ) VALUES (
        v_NextNo, CUR_Clients.ad_client_id, '0', 'Y',
        TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
        'DocumentNo_' || v_TableName,  'DocumentNo/Value for Table ' || v_TableName,
        NULL,  'Y', 1,
        10000000, 10000000, 10000000,
        'N', NULL, NULL, 'N'
      );
    END LOOP;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

CREATE OR REPLACE FUNCTION ad_column_identifier(p_tablename character varying, p_record_id character varying, p_language character varying) RETURNS character varying
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
* All portions are Copyright (C) 2001-2006 Openbravo SL
* All Rights Reserved.
* Contributor(s):  S. Zimmermann, 2016______________________________________.
************************************************************************/
  v_Display VARCHAR ; --OBTG:VARCHAR2--
  v_SQL     VARCHAR:=''; --OBTG:VARCHAR2--
BEGIN
  SELECT REPLACE(REPLACE(SQL_RECORD_IDENTIFIER, ':c_language', '''' || p_Language || ''''), ':c_ID', p_Record_ID)
  INTO v_SQL
  FROM AD_TABLE
  WHERE UPPER(TABLENAME)=UPPER(p_TableName) ;
  EXECUTE v_SQL INTO v_Display;
  /*  IF (p_Language=NULL OR p_Language='' ) THEN
  v_Display:='**';
  END IF;*/
--  -- << END_PROCESS >>
  RETURN v_Display;
EXCEPTION
WHEN OTHERS THEN
  RETURN '**';
END ; $_$;

CREATE OR REPLACE FUNCTION ad_column_identifier_sql(p_tablename character varying) RETURNS character varying
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
* All portions are Copyright (C) 2001-2006 Openbravo SL
* All Rights Reserved.
* Contributor(s):  S. Zimmermann, 2016______________________________________.
************************************************************************/
  v_KeyName     VARCHAR ; --OBTG:VARCHAR2--
  v_Value       VARCHAR ; --OBTG:VARCHAR2--
  v_SQL         VARCHAR:=''; --OBTG:VARCHAR2--
  v_firstColumn BOOLEAN:=TRUE;
  --TYPE RECORD IS REFCURSOR;
    Cur_Columns RECORD;
    Cur_KeyName RECORD;
  BEGIN
    IF p_TableName IS NULL THEN
      RETURN '';
    END IF;
    FOR Cur_KeyName IN

      (SELECT c.ColumnName
      FROM AD_Column c,
        AD_Table t
      WHERE c.AD_Table_ID=t.AD_Table_ID
        AND UPPER(t.TableName)=UPPER(p_TableName)
        AND c.isKey='Y'
      )
    LOOP
      v_KeyName:=Cur_KeyName.ColumnName;
      EXIT;
    END LOOP;
    IF v_KeyName IS NOT NULL THEN
      FOR Cur_Columns IN
        (SELECT c.ColumnName,
          c.AD_Reference_ID,
          c.AD_Reference_Value_ID,
          t.TableName
        FROM AD_Column c,
          AD_Table t
        WHERE c.AD_Table_ID=t.AD_Table_ID
          AND UPPER(t.TableName)=UPPER(p_TableName)
          AND c.isIdentifier='Y'
        ORDER BY c.seqno
        )
      LOOP
        IF v_firstColumn THEN
          v_firstColumn:=FALSE;
        ELSE
          v_SQL:=v_SQL || '||'' - ''||';
        END IF;
        v_SQL:=v_SQL || AD_COLUMN_IDENTIFIER_REF_SQL('T', p_TableName, Cur_Columns.ColumnName, Cur_Columns.AD_Reference_ID, Cur_Columns.AD_Reference_Value_ID) ;
      END LOOP;
      v_SQL:='SELECT ' || v_SQL || ' AS COLUMN_IDENTIFIER FROM (SELECT AD_LANGUAGE FROM AD_LANGUAGE WHERE AD_LANGUAGE=:c_language) L, '|| p_TableName || ' T WHERE ' || v_KeyName || '='||''':c_ID''';
    ELSE
      v_SQL:='**No key found';
    END IF;
--    -- << END_PROCESS >>
    RETURN v_SQL;
EXCEPTION
  WHEN OTHERS THEN
    RETURN '**';
END ; $_$;

CREATE OR REPLACE FUNCTION ad_column_identifier_std(p_tablename character varying, p_record_id character varying) RETURNS character varying
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
* All portions are Copyright (C) 2001-2006 Openbravo SL
* All Rights Reserved.
* Contributor(s):  S. Zimmermann, 2016______________________________________.
************************************************************************/
  v_Display VARCHAR ; --OBTG:VARCHAR2--
  v_Language     VARCHAR:=''; --OBTG:VARCHAR2--
BEGIN
  SELECT coalesce(ad_language,'en_US')
  INTO v_Language
  FROM AD_CLIENT
  WHERE ad_client_id='0' ;

  SELECT AD_COLUMN_IDENTIFIER(p_TableName, p_Record_ID, v_Language ) INTO v_Display FROM DUAL;
  RETURN v_Display;
EXCEPTION
WHEN OTHERS THEN
  RETURN '**';
END ; $_$;



CREATE OR REPLACE FUNCTION ad_getSessionVarsFromTab(p_tab_id varchar,p_keyname varchar,p_idvalue varchar, OUT sessionVarName varchar, OUT sessionVarValue varchar) RETURNS setof RECORD LANGUAGE plpgsql
AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/
v_sql varchar:=''; 
v_cur RECORD;
v_cur2 RECORD;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
BEGIN
         for v_cur in (select * from ad_column where issessionattr='Y' and ad_table_id=(select ad_table_id from ad_tab where ad_tab_id=p_tab_id and lower(columnname)!=lower(p_keyname) and lower(columnname)!='ad_client_id'))
        LOOP
              v_sql:='select '||to_char(v_cur.columnname)||'::text as retval from '||(select tablename from ad_table where ad_table_id=(select ad_table_id from ad_tab where ad_tab_id=p_tab_id))||' where '|| p_keyname||'='||chr(39)||p_idvalue||chr(39);       
             -- raise notice '%' ,v_sql;
              if v_sql is null then
                      raise notice '%', coalesce(p_tab_id,'TAB') ||'#'||coalesce(p_keyname,'KEYNAME')||'#'||coalesce(p_idvalue,'IDVAL');
                      RETURN;
              end if;
              OPEN v_cursor FOR EXECUTE v_sql;
              LOOP
                    FETCH v_cursor INTO v_cur2;
                    EXIT WHEN NOT FOUND;
                    sessionVarValue:=v_cur2.retval;
                    sessionVarName:=v_cur.columnname;
                    RETURN NEXT;
              END LOOP;
              close v_cursor;
          END LOOP;
END ; $_$;

select zsse_droptrigger('ad_tree_trg','ad_tree');
CREATE OR REPLACE FUNCTION ad_tree_trg() RETURNS trigger
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
    * Contributor(s): Openbravo SL, Openz, Stefan Zimmermann, 2017
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
    *
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * Insert AD_Tree Trigger
    *  add Parent TreeNode
    */
  v_NextNo VARCHAR(32); --OBTG:VARCHAR2--
  v_Tree_ID VARCHAR(32); --OBTG:VARCHAR2--
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

IF TG_OP = 'INSERT' THEN 
  --  Insert into TreeNode (Root Node)
  INSERT INTO AD_TreeNode
    (
      AD_TreeNode_ID, AD_Client_ID, AD_Org_ID, IsActive,
      Created, CreatedBy, Updated,
      UpdatedBy, AD_Tree_ID, Node_ID,
      Parent_ID, SeqNo
    )
    VALUES
    (
      get_uuid(), new.AD_Client_ID, new.AD_Org_ID, new.IsActive,
      new.Created, new.CreatedBy, new.Updated,
      new.UpdatedBy, new.AD_Tree_ID, '0',
      NULL, 0
    );
  --  Insert into TreeNodeMM - Copy of Tree ID 10 (Primary Menu)
  IF(new.TREETYPE='MM' and new.isallnodes='Y') THEN
    delete from AD_TreeNode where AD_Tree_ID=new.AD_Tree_ID;
    INSERT INTO AD_TreeNode
    (
      AD_TreeNode_ID, AD_Client_ID, AD_Org_ID, IsActive,
      Created, CreatedBy, Updated,
      UpdatedBy, AD_Tree_ID, Node_ID,
      Parent_ID, SeqNo
    ) select get_uuid(),AD_Client_ID, AD_Org_ID, IsActive,
      Created, CreatedBy, Updated,
      UpdatedBy, new.AD_Tree_ID, Node_ID,
      Parent_ID, SeqNo from ad_treenode where ad_tree_id='10';
  END IF;
END IF;
IF TG_OP = 'DELETE' THEN 
    delete from ad_treenode where ad_tree_id=old.ad_tree_id;
END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

CREATE TRIGGER ad_tree_trg
   AFTER INSERT OR DELETE
  ON ad_tree FOR EACH ROW
  EXECUTE PROCEDURE ad_tree_trg();
  
  
CREATE OR REPLACE FUNCTION ad_org_ready(p_pinstance_id character varying) RETURNS void
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
* All portions are Copyright (C) 2008-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s):  S. Zimmermann, 2019
************************************************************************/
   -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_IsRecursive AD_Org.IsActive%TYPE:='N';
  v_IsAcctLE AD_ORGTYPE.IsAcctLegalEntity%TYPE:='N';
  v_isperiodcontrol AD_Org.IsPeriodControlAllowed%TYPE;
  v_calendar_id AD_Org.C_Calendar_ID%TYPE;

  v_num NUMERIC; 
  --TYPE RECORD IS REFCURSOR;
  Cur_Parameter RECORD;
  CUR_PeriodControl RECORD;
  Cur_Org RECORD;
BEGIN
  RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
  v_ResultStr:='PInstanceNotFound';
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
BEGIN
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
      IF(Cur_Parameter.ParameterName='Cascade') THEN
        v_IsRecursive:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  Cascade=' || v_IsRecursive ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; -- Get Parameter
    
    if v_Record_ID is null then
        v_Record_ID:=p_pinstance_id;
    end if;
    
    v_ResultStr:='Updating Ready Flag';
    IF (v_IsRecursive='Y') THEN
      UPDATE AD_ORG
      SET ISREADY='Y'
      WHERE AD_ISORGINCLUDED(ad_org.ad_org_id, v_Record_ID, ad_org.ad_client_id)<>-1
      AND IsReady='N';      
    ELSE
      UPDATE AD_ORG
      SET ISREADY='Y'
      WHERE AD_ORG_ID=v_Record_ID;
    END IF;
    
    v_ResultStr:='Checking Ready';
    SELECT AD_ORG_CHK_READY(v_Record_ID) INTO v_num FROM DUAL;
    IF (v_num = -1) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'Every ancestor of the organization must be a ready organization'; --OBTG:-20545--
    END IF;
    
    v_ResultStr:='Checking LE';
    SELECT AD_ORGTYPE_ISTRANS_ALLOWED() INTO v_num FROM DUAL;
    IF (v_num <> 1) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'Every organization where transactions are possible must have one and only one ancestor (including itself) that is a legal entity'; --OBTG:-20540--
    END IF;
    
    v_ResultStr:='Checking BU';
    SELECT AD_ORGTYPE_ISLE_ISBU() INTO v_num FROM DUAL;
    IF (v_num > 1) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'Each organization can have one and only one ancestor (including itself) that is a business unit'; --OBTG:-20541--
    ELSIF (v_num = -1) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'A business unit must have one and only one ancestor that is a legal entity'; --OBTG:-20546--
    END IF;
      
    v_ResultStr:='Checking Schemas';
    SELECT AD_ORG_CHK_SCHEMAS() INTO v_num FROM DUAL;
    IF (v_num = -1) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'Every legal entity with accounting must have itself or an ancestor at least an accounting schema attached to it'; --OBTG:-20542--
    END IF;
    
    v_ResultStr:='Checking Calendar';
    SELECT AD_ORG_CHK_CALENDAR() INTO v_num FROM DUAL;
    IF (v_num = -3) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'Every legal entity with accounting must have itself or an ancestor at least a calendar attached to it'; --OBTG:-20537--
    ELSIF (v_num = -2) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'All the organizations that belong to the same legal entity must have a unique calendar'; --OBTG:-20538--
    ELSIF (v_num = -1) THEN
      -- ROLLBACK;
      v_Result:=0;
      RAISE EXCEPTION '%', 'The calendar associated to a legal entity must be unique. So, an organization that is a legal entity must have assigned itself or any ancestor the same calendar'; --OBTG:-20539--
    END IF;
    
    -- Create PeriodControl for the organization
    IF (v_IsRecursive='N') THEN
      SELECT IsPeriodControlAllowed, C_Calendar_ID, AD_Client_ID
      INTO v_isperiodcontrol, v_calendar_id, v_Client_ID
      FROM AD_Org
      WHERE AD_Org_ID=v_Record_ID;
      
      IF ( v_isperiodcontrol = 'Y') THEN
        FOR CUR_PeriodControl IN
        (SELECT Value, a.C_Period_ID as Period
         FROM AD_Ref_List , (select c_period_id
                            from c_period, c_year
                            where c_year.c_year_id= c_period.c_year_id
                            and c_year.c_calendar_id = COALESCE(v_calendar_id,(SELECT C_CALENDAR_ID FROM AD_ORG WHERE AD_ORG_ID = AD_ORG_GETCALENDAROWNER(v_Record_ID)))) a
         WHERE AD_Reference_ID='183'
         ORDER BY 1)
        LOOP
          INSERT
          INTO C_PeriodControl
            (
              C_PeriodControl_ID, AD_Client_ID, AD_Org_ID,
              IsActive, Created, CreatedBy,
              Updated, UpdatedBy, C_Period_ID,
              DocBaseType, PeriodStatus, PeriodAction,
              Processing
            )
            VALUES
            (
              get_uuid(), v_Client_ID, v_Record_ID,
               'Y', TO_DATE(NOW()),  '0',
              TO_DATE(NOW()), '0', CUR_PeriodControl.Period,
              CUR_PeriodControl.Value, 'N', 'N',
              NULL
            )
            ;
        END LOOP;
    END IF;
      
    ELSIF (v_IsRecursive='Y') THEN
      SELECT AD_Client_ID
      INTO v_Client_ID
      FROM AD_Org 
      WHERE AD_Org_ID=v_Record_ID;
    
      FOR Cur_Org IN
        (SELECT AD_Org_ID
        FROM AD_Org A
        WHERE AD_ISORGINCLUDED(AD_Org_ID, v_Record_ID, v_Client_ID)<>-1
        AND IsPeriodControlallowed='Y'
        AND NOT EXISTS (SELECT 1 
                      FROM C_PeriodControl 
                      WHERE C_PeriodControl.AD_Org_ID=A.AD_Org_ID)
        
        )
      LOOP
        FOR CUR_PeriodControl IN
          (SELECT Value, a.C_Period_ID as Period
           FROM AD_Ref_List , (select c_period_id
                              from c_period, c_year
                              where c_year.c_year_id= c_period.c_year_id
                              and c_year.c_calendar_id = (SELECT C_CALENDAR_ID FROM AD_ORG WHERE AD_ORG_ID = AD_ORG_GETCALENDAROWNER(Cur_Org.AD_Org_ID))) a
           WHERE AD_Reference_ID='183'
           ORDER BY 1)
          LOOP
            INSERT
            INTO C_PeriodControl
              (
                C_PeriodControl_ID, AD_Client_ID, AD_Org_ID,
                IsActive, Created, CreatedBy,
                Updated, UpdatedBy, C_Period_ID,
                DocBaseType, PeriodStatus, PeriodAction,
                Processing
              )
              VALUES
              (
                get_uuid(), v_Client_ID, Cur_Org.AD_Org_ID,
                 'Y', TO_DATE(NOW()),  '0',
                TO_DATE(NOW()), '0', CUR_PeriodControl.Period,
                CUR_PeriodControl.Value, 'N', 'N',
                NULL
              )
              ;
          END LOOP;       
      END LOOP;
    END IF;
    
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
    ELSE
      RAISE NOTICE '%','Finished ' || v_Message ;
    END IF;

EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  -- ROLLBACK;
  IF(p_PInstance_ID IS NOT NULL) THEN
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  END IF;
END;
END ; $_$;



  
  
/*
HISTORYCODE in AD_MESSAGE

CREATE OR REPLACE FUNCTION @TABLENAME@_changehistory_trg() 
  RETURNS trigger AS
$BODY$ DECLARE 
v_tabId        varchar:='@TABID@';
v_tablename    varchar:='@TABLENAME@';
v_father       varchar:='@FATHERTABLENAME@';
v_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
v_identyfier         varchar;
v_fatheridentyfier   varchar:='';
v_cur          RECORD;
v_ic  c_changehistory%ROWTYPE;
v_uid varchar;
v_cmd varchar:='';
v_fname varchar;
v_tname varchar;
BEGIN
    
  IF (TG_OP = 'DELETE' ) THEN
    IF coalesce((select value from ad_preference where name='SUSPENDHISTORY'),'N')='Y' then
        RETURN OLD;
    end if;
    v_identyfier:=coalesce(ad_column_identifier_std('@TABLENAME@',old.@TABLENAME@_id),'');
    if v_father!='' then 
        v_fatheridentyfier:=coalesce(ad_column_identifier_std('@FATHERTABLENAME@',old.@FATHERTABLENAME@_id),'');
    end if;
    for v_cur in (select pname,pad_ref_fieldcolumn_id,pfieldreference from ad_selecttabfields('DE_de',v_tabId) order by pline)
    LOOP
        if ad_fieldGetVisibleLogic(v_cur.pad_ref_fieldcolumn_id,'')  not in ('HIDDEN','HIDDENNUMERIC','DONOTGENERATE')   then 
            v_fname:=zssi_getElementTextByColumname(v_cur.pname,(select coalesce(ad_language,'de_DE') from ad_client where ad_client_id=v_client));
            EXECUTE 'select get_uuid() as c_changehistory_id,($1).updatedby as ad_user_id,'||chr(39)||v_client||chr(39)||' as ad_client_id,($1).ad_org_id as ad_org_id,($1).isactive as isactive,now() as created,($1).createdby as createdby,now() as updated,($1).updatedby as updatedby,now() as changetime,'||chr(39)||v_identyfier||chr(39)||' as searchkey,'||chr(39)||v_fatheridentyfier||chr(39)||' as searchkeyfather,'||chr(39)||v_fname||chr(39)||' as fieldname,($1).'||v_cur.pname||' as oldvalue,'||chr(39)||'DELETED'||chr(39)||' as newvalue ,'||chr(39)||v_tabId||chr(39)||' as ad_tab_id ' into v_ic  USING OLD;
            if lower(substr(v_cur.pname,length(v_cur.pname)-2,3))='_id' then
                select t.tablename into v_tname from ad_ref_table tr,ad_table t where tr.ad_table_id=t.ad_table_id and tr.ad_reference_id=v_cur.pfieldreference;
                if v_tname is null then
                    v_tname:=substr(v_cur.pname,1,length(v_cur.pname)-3);
                end if;
                if v_ic.oldvalue is not null then
                    v_ic.oldvalue:=ad_column_identifier_std(v_tname,v_ic.oldvalue);
                end if;
            end if;
            v_ic.ad_user_id:=ad_getduserhist();
            v_ic.updatedby:=ad_getduserhist();
            v_ic.createdby:=ad_getduserhist();
            insert into c_changehistory select v_ic.*;
        end if;
    END LOOP;
  END IF;  
  IF (TG_OP = 'UPDATE' ) THEN
    IF coalesce((select value from ad_preference where name='SUSPENDHISTORY'),'N')='Y' then
        RETURN NEW;
    end if;
    v_identyfier:=ad_column_identifier_std('@TABLENAME@',new.@TABLENAME@_id);
    if v_father!='' then 
        v_fatheridentyfier:=coalesce(ad_column_identifier_std('@FATHERTABLENAME@',new.@FATHERTABLENAME@_id),'');
    end if;
    if lower('@TABLENAME@')='c_location' then
        v_fatheridentyfier:=coalesce(ad_column_identifier_std('c_bpartner',(select c_bpartner_id from c_bpartner_location where c_location_id=new.c_location_id limit 1)),'');
    end if;
    for v_cur in (select pname,pad_ref_fieldcolumn_id,pline,pfieldreference from ad_selecttabfields('DE_de',v_tabId) 
                  @UNION@ order by pline)
    LOOP
        if ad_fieldGetVisibleLogic(v_cur.pad_ref_fieldcolumn_id,'') not in ('HIDDEN','HIDDENNUMERIC','DONOTGENERATE')  then 
            v_fname:=zssi_getElementTextByColumname(v_cur.pname,(select coalesce(ad_language,'de_DE') from ad_client where ad_client_id=v_client));
            --raise exception '%',v_cmd;
            EXECUTE 'select get_uuid() as c_changehistory_id,($1).updatedby as ad_user_id,'||chr(39)||v_client||chr(39)||' as ad_client_id,($1).ad_org_id as ad_org_id,($1).isactive as isactive,now() as created,($1).createdby as createdby,now() as updated,($1).updatedby as updatedby,now() as changetime,'||chr(39)||v_identyfier||chr(39)||' as searchkey,'||chr(39)||v_fatheridentyfier||chr(39)||' as searchkeyfather,'||chr(39)||v_fname||chr(39)||' as fieldname,($2).'||v_cur.pname||' as oldvalue,($1).'||v_cur.pname||' as newvalue ,'||chr(39)||v_tabId||chr(39)||' as ad_tab_id ' into v_ic  USING NEW,OLD;
            if coalesce(v_ic.oldvalue,'')!=coalesce(v_ic.newvalue,'') then
                if lower(substr(v_cur.pname,length(v_cur.pname)-2,3))='_id' then
                    select t.tablename into v_tname from ad_ref_table tr,ad_table t where tr.ad_table_id=t.ad_table_id and tr.ad_reference_id=v_cur.pfieldreference;
                    if v_tname is null then
                        v_tname:=substr(v_cur.pname,1,length(v_cur.pname)-3);
                    end if;
                    if v_ic.oldvalue is not null then
                        v_ic.oldvalue:=ad_column_identifier_std(v_tname,v_ic.oldvalue);
                    end if;
                    if v_ic.newvalue is not null then
                        v_ic.newvalue:=ad_column_identifier_std(v_tname,v_ic.newvalue);
                    end if;
                end if;
                insert into c_changehistory select v_ic.*;
            end if;
        end if;
    END LOOP;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$ LANGUAGE plpgsql;    
  
*/

SELECT zsse_dropfunction('ad_activatehistorytriggers');


CREATE OR REPLACE FUNCTION ad_activatehistorytriggers() RETURNS varchar  AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

History Funktion 

*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='';
v_Org   character varying;
v_cur record;
v_triggercode varchar;
v_father varchar;
v_i numeric:=0;
v_dummy varchar;
v_listofTabs varchar:='';
BEGIN
    for v_cur in (select tb.tablename from ad_tab t ,ad_table tb where tb.ad_table_id=t.ad_table_id)
    LOOP
        select  zsse_DropTrigger (v_cur.tablename||'_changehistory_trg',v_cur.tablename) into v_dummy;
    END LOOP;
   
    for v_cur in (select case when coalesce(i.changehistory,'NON')!='NON' then i.changehistory else t.changehistory end as changehistory,t.ad_tab_id,tb.tablename,t.tablevel,t.seqno,t.ad_window_id 
                    from ad_tab t 
                    left join ad_tab_instance i on i.ad_tab_id=t.ad_tab_id,ad_table tb where tb.ad_table_id=t.ad_table_id)
    LOOP
        if v_cur.changehistory='Y' and (select count(*) from pg_trigger where tgname=v_cur.tablename||'_changehistory_trg')=0 and
           (select count(*) from information_schema.tables where table_name=lower(v_cur.tablename) and  table_type = 'BASE TABLE')=1 
        then
            select msgtext into v_triggercode from ad_message where value='HISTORYCODE';
            v_triggercode:=replace(v_triggercode,'@TABID@',v_cur.ad_tab_id);
            if v_cur.ad_tab_id='220' then
                v_triggercode:=replace(v_triggercode,'@UNION@',' union select pname,pad_ref_fieldcolumn_id,pline,pfieldreference from ad_selecttabfields('||chr(39)||'DE_de'||chr(39)||','||chr(39)||'223'||chr(39)||') union select pname,pad_ref_fieldcolumn_id,pline,pfieldreference from ad_selecttabfields('||chr(39)||'DE_de'||chr(39)||','||chr(39)||'224'||chr(39)||') ');
            else
                v_triggercode:=replace(v_triggercode,'@UNION@','');
            end if;
            v_triggercode:=replace(v_triggercode,'@TABLENAME@',v_cur.tablename);
            if v_cur.tablevel>0 then
                select tb.tablename into v_father from ad_tab t,ad_table tb where t.ad_table_id=tb.ad_table_id and t.ad_window_id=v_cur.ad_window_id 
                and t.tablevel=v_cur.tablevel-1 and t.seqno<v_cur.seqno order by t.seqno desc limit 1;
                if v_father is null then v_father:=''; end if;
            else
                v_father:='';
            end if;
            v_triggercode:=replace(v_triggercode,'@FATHERTABLENAME@',v_father);
            --if v_cur.ad_tab_id='222' then
            --raise notice '%',v_triggercode;
            --raise notice '%','CREATE TRIGGER '||v_cur.tablename||'_changehistory_trg  before UPDATE OR DELETE  ON '||v_cur.tablename||' FOR EACH ROW  EXECUTE PROCEDURE '||v_cur.tablename||'_changehistory_trg()';
            --end if;
            EXECUTE v_triggercode;
            EXECUTE 'CREATE TRIGGER '||v_cur.tablename||'_changehistory_trg  before UPDATE OR DELETE  ON '||v_cur.tablename||' FOR EACH ROW  EXECUTE PROCEDURE '||v_cur.tablename||'_changehistory_trg()';
            v_i:=v_i+1;
            if v_listofTabs!='' then  v_listofTabs:=v_listofTabs || ', '; end if;
            v_listofTabs:=v_listofTabs ||v_cur.tablename;
        end if;
    END LOOP;
    RETURN v_i||' Change History Triggers created on: '||v_listofTabs ;
END ; $BODY$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ad_duserhist(p_user_id varchar) returns varchar AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

History Funktion / Implementing deletee

*****************************************************/
BEGIN
    if p_user_id is not null then
        create temporary table deluhist(
        ad_user_id varchar(32) not null
        )  ON COMMIT DROP;
        insert into  deluhist(ad_user_id) values (p_user_id);
    end if;
    return 'OK';
END ; $BODY$ LANGUAGE plpgsql;
  
CREATE OR REPLACE FUNCTION ad_getduserhist() returns varchar AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

History Funktion  / Implementing delete

*****************************************************/
BEGIN
    return (select ad_user_id from deluhist limit 1);
EXCEPTION
WHEN OTHERS THEN
    RETURN '0';
END ; $BODY$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ad_role_trg()
  RETURNS trigger LANGUAGE plpgsql AS
$_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2024 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
BEGIN
  -- mfa_change_password
  INSERT INTO ad_form_access (ad_form_access_id, ad_form_id, ad_role_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, isreadwrite)
                      VALUES (get_uuid(), '3CB031AF8FB44970B8F4BA700B32CA61', NEW.ad_role_id, NEW.ad_client_id, NEW.ad_org_id, 'Y', NEW.created, NEW.createdby, NEW.updated, NEW.updatedby, 'Y');
  -- mfa_email_code
  INSERT INTO ad_form_access (ad_form_access_id, ad_form_id, ad_role_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, isreadwrite)
                      VALUES (get_uuid(), '6C8E9DB1B51E4D34A754D9E0D4374199', NEW.ad_role_id, NEW.ad_client_id, NEW.ad_org_id, 'Y', NEW.created, NEW.createdby, NEW.updated, NEW.updatedby, 'Y');
  -- mfa_logout
  INSERT INTO ad_form_access (ad_form_access_id, ad_form_id, ad_role_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, isreadwrite)
                      VALUES (get_uuid(), 'F275D9DD482844309E4B3271D18E4C7E', NEW.ad_role_id, NEW.ad_client_id, NEW.ad_org_id, 'Y', NEW.created, NEW.createdby, NEW.updated, NEW.updatedby, 'Y');
  RETURN NEW;
END; $_$;

  
select zsse_droptrigger('ad_role_trg','ad_role');

CREATE TRIGGER ad_role_trg
  AFTER INSERT
  ON ad_role
  FOR EACH ROW
  EXECUTE PROCEDURE ad_role_trg();
