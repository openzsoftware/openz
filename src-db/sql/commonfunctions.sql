/* commonfunctions.sql */

/*****************************************************+

Document Type Management

*****************************************************/

CREATE OR REPLACE FUNCTION ad_get_doctype(p_clientid character varying, p_orgid character varying, p_docbasetype character varying, p_docsubtypeso character) RETURNS character varying
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
  v_DocTypeId VARCHAR(32) ; --OBTG:varchar2--
  BEGIN
      SELECT C_DocType_ID into v_DocTypeId
      FROM C_DOCTYPE
      WHERE DOCBASETYPE=p_DocBaseType
        AND ISACTIVE='Y' AND coalesce(DOCSUBTYPESO,'null')=coalesce(p_DocSubTypeSO,'null')
        AND AD_Client_Id=p_ClientId
        AND AD_ISORGINCLUDED(p_OrgId, AD_Org_ID, p_ClientId) <> -1
      ORDER BY IsDefault desc LIMIT 1;
    RETURN v_DocTypeId;
END ; $_$;


CREATE OR REPLACE FUNCTION ad_get_docbasetype( p_doctypeID character varying) RETURNS character varying
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
* Contributor(s): Stefan Zimmermann, 07/2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/
  v_DocTypeId VARCHAR(32) ; --OBTG:varchar2--
  BEGIN
      SELECT docbasetype into v_DocTypeId
      FROM C_DOCTYPE
      WHERE c_doctype_id=p_doctypeID;
    RETURN v_DocTypeId;
END ; $_$;

CREATE OR REPLACE FUNCTION c_password_create(plength numeric) RETURNS character varying LANGUAGE plpgsql AS $_$ DECLARE 
  v_return varchar:='';
  v_i numeric;
  randd integer;
  BEGIN
     for v_i in 0..coalesce(plength,10) LOOP
         randd:=trunc((random()) * (122-48) + 48);
         if randd=0 then randd=48; end if;
         v_return:=v_return||chr(randd);    
     end LOOP;
    RETURN v_return;
END ; $_$;

CREATE OR REPLACE FUNCTION c_password_createprocess(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Overload for Process Scheduler

*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='';
v_password varchar;
Cur_Parameter record;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID  into v_Record_ID from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    else
        v_message := '';
        FOR Cur_Parameter IN
          (SELECT para.*
           FROM ad_pinstance pi, ad_pinstance_Para para
           WHERE 1=1
            AND pi.ad_pinstance_ID = para.ad_pinstance_ID
            AND pi.ad_pinstance_ID = p_pinstance_ID
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('password') ) THEN
            v_password := Cur_Parameter.p_string;
          END IF;
           
        END LOOP; -- Get Parameter
        RAISE NOTICE '%','Updating pinstance - Processing ' || p_pinstance_ID;
    end if;
    update ad_user set auxtext3= v_password where ad_user_id=v_Record_ID;
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1 , v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  IF(p_pinstance_id IS NOT NULL) THEN
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  ELSE
    RAISE EXCEPTION '%', SQLERRM;
  END IF;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION ad_get_defaultDocTypeTemplate(p_doctypeID character varying, p_org_id character varying) RETURNS character varying
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
* Contributor(s): Stefan Zimmermann, 07/2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/
  v_DocTempId VARCHAR(32) ; --OBTG:varchar2--
  BEGIN
      SELECT c_poc_doctype_template_id into v_DocTempId FROM C_POC_DOCTYPE_TEMPLATE    WHERE c_doctype_id=p_doctypeID and ad_org_id=p_org_id and isdefault='Y';
      if v_DocTempId is null then
         SELECT c_poc_doctype_template_id into v_DocTempId FROM C_POC_DOCTYPE_TEMPLATE    WHERE c_doctype_id=p_doctypeID and ad_org_id='0' and isdefault='Y';
      end if;
      if v_DocTempId is null then
         SELECT c_poc_doctype_template_id into v_DocTempId FROM C_POC_DOCTYPE_TEMPLATE    WHERE c_doctype_id=p_doctypeID and ad_org_id=p_org_id;
      end if;
      if v_DocTempId is null then
        SELECT c_poc_doctype_template_id into v_DocTempId FROM C_POC_DOCTYPE_TEMPLATE    WHERE c_doctype_id=p_doctypeID and ad_org_id='0';
      end if;
    RETURN v_DocTempId;
END ; $_$;

CREATE OR REPLACE FUNCTION ad_get_doctypename(p_doctypeid character varying, p_lang character varying)
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
***************************************************************************************************************************************************/
  v_Docname VARCHAR; --OBTG:varchar2--
  BEGIN
     select COALESCE(dttrl.Name, dt.Name)  into v_Docname
      FROM C_DOCTYPE dt left join c_doctype_trl dttrl on dt.c_doctype_id=dttrl.c_doctype_id 
            WHERE dttrl.ad_language=p_lang and
            dt.c_doctype_id=p_doctypeID;
    RETURN v_Docname;
END ; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_nodelete_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
Prevents deletion of Main DOCTYPES
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
 -- Do not delete 
 IF TG_OP = 'DELETE' THEN
     raise exception '@nodeletepossible@';
 END IF;
 
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

CREATE OR REPLACE FUNCTION c_doctyperestrict_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
Prevents deletion of Main DOCTYPES
*****************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
 -- Do not delete 
 IF TG_OP = 'DELETE' THEN
     raise exception '@nodeletepossible@';
 END IF;
 IF TG_OP = 'UPDATE' THEN
    if old.name in  ('Project','Projecttask','Employee') and old.name!=new.name then
        raise exception 'Changing Name on this Item is not Possible';
    end if;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('c_doctyperestrict_trg','c_doctype');

CREATE TRIGGER c_doctyperestrict_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON c_doctype FOR EACH ROW
  EXECUTE PROCEDURE c_doctyperestrict_trg();
  
CREATE OR REPLACE FUNCTION c_PocConfigurationResrict_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2021 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
****************************************************************************************************************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
 IF TG_OP = 'INSERT' THEN
    new.ad_org_id:='0';
    if (select count(*) from c_Poc_Configuration where ad_client_id=new.ad_client_id)>0 then
        raise exception 'Only one Record allowed here...';
    end if;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('c_PocConfigurationResrict_trg','c_Poc_Configuration');

CREATE TRIGGER c_PocConfigurationResrict_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON c_Poc_Configuration FOR EACH ROW
  EXECUTE PROCEDURE c_PocConfigurationResrict_trg();
  
  
select zsse_DropFunction ('ad_sequence_doctype');
CREATE OR REPLACE FUNCTION ad_sequence_doctype(p_doctype_id character varying, p_ad_org_id character varying, p_update_next character, OUT p_documentno character varying) RETURNS character varying
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
  * Contributor(s): Stefan Zimmermann, 2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2012 Stefan Zimmermann
  * Contributions are Copyright (C) 2001-2009 Openbravo, S.L.
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: AD_Sequence_DocType.sql,v 1.9 2003/08/06 06:51:27 jjanke Exp $
  ***
  * Title: Get the next DocumentNo of Document Type
  * Description:
  *  store in parameter p_DocumentNo
  *  If ID < 1000000, use System Doc Sequence
  *  If no Document Sequence is defined, return null !
  *   Use AD_Sequence_Doc('DocumentNo_myTable',.. to get it directly
  ************************************************************************/
  v_NextNo VARCHAR(32); --OBTG:VARCHAR2--

  v_Sequence_ID VARCHAR(32):=NULL; --OBTG:VARCHAR2--
  v_Prefix VARCHAR(30) ; --OBTG:VARCHAR2--
  v_Suffix VARCHAR(30) ; --OBTG:VARCHAR2--
  v_table varchar;
  v_count numeric;
  v_sql character varying;
  TYPE_Ref REFCURSOR;
  v_cursor TYPE_Ref%TYPE;
  v_cur RECORD;
BEGIN
  -- Is a document Sequence defined and valid
BEGIN
  SELECT DocNoSequence_ID
  INTO v_Sequence_ID
  FROM C_DocType
  WHERE C_DocType_ID=p_DocType_ID -- parameter
    AND IsDocNoControlled='Y'  AND IsActive='Y';
EXCEPTION
WHEN OTHERS THEN
  NULL;
END;
IF(v_Sequence_ID IS NULL) THEN -- No Sequence Number
  p_DocumentNo:= NULL; -- Return NULL
  RAISE NOTICE '%','[AD_Sequence_DocType: not found - C_DocType_ID=' || p_DocType_ID || ']' ;
  RETURN;
END IF;
-- If AD_Sequence_Org exist: Get sequence from there
select count(*) into v_count from C_DocType d, AD_Sequence_org s
    WHERE d.C_DocType_ID=p_DocType_ID and d.DocNoSequence_ID=s.AD_Sequence_id 
          AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y' and s.ad_org_id=p_ad_org_id;

if v_count>0 then
        -- Get the numbers
        SELECT s.AD_Sequence_ID, s.CurrentNext, s.Prefix, s.Suffix,(select tablename from ad_table where ad_table_id=d.ad_table_id) as tablename
        INTO v_Sequence_ID, v_NextNo, v_Prefix, v_Suffix,v_table
        FROM  C_DocType d , AD_Sequence_org s 
        WHERE d.C_DocType_ID=p_DocType_Id 
          AND d.DocNoSequence_ID=s.AD_Sequence_ID  AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y' AND s.ad_org_id=p_ad_org_id; 
        IF p_Update_Next='Y' THEN
          UPDATE AD_Sequence_org s
            SET CurrentNext=CurrentNext + IncrementNo
          WHERE AD_Sequence_ID=v_Sequence_ID  AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y' AND s.ad_org_id=p_ad_org_id;
        END IF;
else
      -- Get the numbers
      SELECT s.AD_Sequence_ID, s.CurrentNext, s.Prefix, s.Suffix,(select tablename from ad_table where ad_table_id=d.ad_table_id) as tablename
      INTO v_Sequence_ID, v_NextNo, v_Prefix, v_Suffix,v_table
      FROM C_DocType d , AD_Sequence s
      WHERE d.C_DocType_ID=p_DocType_ID
        AND d.DocNoSequence_ID=s.AD_Sequence_ID  AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y'; --OBTG: OF CurrentNext--

        IF p_Update_Next='Y' THEN
          UPDATE AD_Sequence
            SET CurrentNext=CurrentNext + IncrementNo
          WHERE AD_Sequence_ID=v_Sequence_ID;
        END IF;
end if;
  -- Determin, if Docno exists
  if v_table is not null and p_update_next='Y' then
    BEGIN
        v_sql:='select count(*) as isexits from '||v_table||' where documentno='||chr(39)||COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '')||chr(39);
        OPEN v_cursor FOR EXECUTE v_sql;
        LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            if v_cur.isexits>0 then
                -- Recursive call till Free Docno Found.
                select * into p_DocumentNo FROM Ad_Sequence_Doctype(p_doctype_id, p_ad_org_id ,'Y') ;
            else
                p_DocumentNo:=COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '') ;
            end if;
        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        p_DocumentNo:=COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '');
    END;
  else
    p_DocumentNo:=COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '') ;
  end if;
EXCEPTION
WHEN DATA_EXCEPTION THEN
  RAISE EXCEPTION '%', '@DocumentTypeSequenceNotFound@' ; --OBTG:-20000--
END ; $_$;

CREATE OR REPLACE FUNCTION ad_getDocNo4DocType(p_doctype_id character varying, p_ad_org_id character varying, p_update_next character) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$ DECLARE 
dummy varchar;
v_return varchar;
BEGIN
    select p_documentno into v_return from ad_sequence_doctype(p_doctype_id, p_ad_org_id, p_update_next);
    return v_return;
END ; $_$;

CREATE OR REPLACE FUNCTION ad_sequence_doctype_decrement(p_doctype_id character varying, p_ad_org_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
  v_Sequence_ID VARCHAR(32):=NULL; --OBTG:VARCHAR2--
  v_count numeric;
BEGIN
    -- Is a document Sequence defined and valid
    SELECT DocNoSequence_ID
    INTO v_Sequence_ID
    FROM C_DocType
    WHERE C_DocType_ID=p_DocType_ID -- parameter
        AND IsDocNoControlled='Y'  AND IsActive='Y';

    IF(v_Sequence_ID IS NULL) THEN -- No Sequence Number 
        RAISE NOTICE '%','[AD_Sequence_DocType: not found - C_DocType_ID=' || p_DocType_ID || ']' ;
        RETURN;
    END IF;
    -- If AD_Sequence_Org exist: Get sequence from there
    select count(*) into v_count from C_DocType d, AD_Sequence_org s
        WHERE d.C_DocType_ID=p_DocType_ID and d.DocNoSequence_ID=s.AD_Sequence_id 
            AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y' and s.ad_org_id=p_ad_org_id;

    if v_count>0 then
            -- Get the numbers
            SELECT s.AD_Sequence_ID
            INTO v_Sequence_ID
            FROM  C_DocType d , AD_Sequence_org s 
            WHERE d.C_DocType_ID=p_DocType_Id 
            AND d.DocNoSequence_ID=s.AD_Sequence_ID  AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y' AND s.ad_org_id=p_ad_org_id; 
            UPDATE AD_Sequence_org s
                SET CurrentNext=CurrentNext - IncrementNo
            WHERE AD_Sequence_ID=v_Sequence_ID  AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y' AND s.ad_org_id=p_ad_org_id;
    else
        -- Get the numbers
        SELECT s.AD_Sequence_ID
        INTO v_Sequence_ID
        FROM C_DocType d , AD_Sequence s
        WHERE d.C_DocType_ID=p_DocType_ID
            AND d.DocNoSequence_ID=s.AD_Sequence_ID  AND s.IsActive='Y'  AND s.IsTableID='N'  AND s.IsAutoSequence='Y'; --OBTG: OF CurrentNext--

            UPDATE AD_Sequence
                SET CurrentNext=CurrentNext - IncrementNo
            WHERE AD_Sequence_ID=v_Sequence_ID;
    end if;
END ; $_$;


select zsse_DropFunction ('ad_sequence_doc');

CREATE OR REPLACE FUNCTION ad_sequence_doc(p_sequencename character varying, p_ad_org_id character varying, p_update_next character, OUT p_documentno character varying) RETURNS character varying
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
  * Contributor(s): Stefan Zimmermann, 2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2012 Stefan Zimmermann
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: AD_Sequence_Doc.sql,v 1.6 2003/08/06 06:51:26 jjanke Exp $
  ***
  * Title: Get the next DocumentNo of TableName
  * Description:
  *  store in parameter p_DocumentNo
  *  if ID < 1000000, use System Doc Sequence
  ************************************************************************/
  v_NextNo VARCHAR(32); --OBTG:VARCHAR2--
  v_NextNoSys NUMERIC;
  v_Prefix VARCHAR(30) ; --OBTG:VARCHAR2--
  v_Suffix VARCHAR(30) ; --OBTG:VARCHAR2--
  v_count numeric;
  v_table varchar;
  v_sql character varying;
  v_orgseq character varying;
  TYPE_Ref REFCURSOR;
  v_cursor TYPE_Ref%TYPE;
  v_cur RECORD;
BEGIN
  -- If AD_Sequence_Org exist: Get sequence from there
  select count(*) into v_count from AD_Sequence a, AD_Sequence_org s
    WHERE a.ad_sequence_id=s.ad_sequence_id and a.Name=p_SequenceName  AND a.IsActive='Y'  AND a.IsTableID='N'  AND a.IsAutoSequence='Y'  and s.ad_org_id=p_ad_org_id;
  
  if v_count>0 then
        SELECT s.CurrentNext, s.Prefix, s.Suffix,substr(a.name,12) as tablename,AD_Sequence_org_id
        INTO v_NextNo, v_Prefix, v_Suffix,v_table,v_orgseq
        from AD_Sequence a, AD_Sequence_org s
    WHERE a.ad_sequence_id=s.ad_sequence_id and a.Name=p_SequenceName  AND a.IsActive='Y'  AND a.IsTableID='N'  AND a.IsAutoSequence='Y'  and s.ad_org_id=p_ad_org_id;

        IF p_Update_Next='Y' THEN
          UPDATE AD_Sequence_org
            SET CurrentNext=CurrentNext + IncrementNo, Updated=TO_DATE(NOW())
          WHERE AD_Sequence_org_id=v_orgseq;
        END IF;
  else
      SELECT CurrentNext, Prefix, Suffix,substr(name,12) as tablename
        INTO v_NextNo, v_Prefix, v_Suffix,v_table
        FROM AD_Sequence
        WHERE Name=p_SequenceName  AND IsActive='Y'  AND IsTableID='N'  AND IsAutoSequence='Y' ; --OBTG: OF CurrentNext--

        IF p_Update_Next='Y' THEN
          UPDATE AD_Sequence
            SET CurrentNext=CurrentNext + IncrementNo, Updated=TO_DATE(NOW())
          WHERE Name=p_SequenceName;
        END IF;
  end if;
  -- Determin, if Docno exists
  if instr(lower(p_sequencename),'documentno_')>0 and p_update_next='Y' then
    BEGIN
        v_sql:='select count(*) as isexits from '||v_table||' where documentno='||chr(39)||COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '')||chr(39);
        raise notice '%', v_sql;
        OPEN v_cursor FOR EXECUTE v_sql;
        LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            if v_cur.isexits>0 then
                -- Recursive call till Free Docno Found.
                select * into p_DocumentNo FROM ad_sequence_doc(p_sequencename, p_ad_org_id , 'Y') ;
            else
                p_DocumentNo:=COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '') ;
            end if;
        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        p_DocumentNo:=COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '');
    END;
  else
    p_DocumentNo:=COALESCE(v_Prefix, '') || v_NextNo || COALESCE(v_Suffix, '') ;
  end if;

EXCEPTION
WHEN DATA_EXCEPTION THEN
  RAISE EXCEPTION '%', '@DocumentSequenceNotFound@' || p_SequenceName ; --OBTG:-20000--
END ; $_$;

CREATE OR REPLACE FUNCTION ad_getNextNoFromSEQ(p_sequencename character varying, p_ad_org_id character varying, p_update_next character) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$ DECLARE 
dummy varchar;
v_return varchar;
BEGIN
    select p_documentno into v_return from ad_sequence_doc(p_sequencename , p_ad_org_id , p_update_next );
    return v_return;
END ; $_$;

CREATE OR REPLACE FUNCTION c_uom_convert(p_qty numeric, p_uomfrom_id character varying, p_uomto_id character varying, p_stdprecision character varying) RETURNS numeric
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
*
* Specifically, this derivative work is based upon the following Compiere
* file and version.
*************************************************************************
* $Id: C_UOM_Convert.sql,v 1.3 2002/10/21 04:49:45 jjanke Exp $
***
* Title: Convert Quantity
* Description:
*  from UOMFrom_ID to UOMTo_ID
*  standard or costing precision based on target UOM
* Test:
*  SELECT C_UOM_Convert (11,101,102, 'Y') FROM DUAL => 1.38
************************************************************************/
  v_Result NUMERIC:= NULL;
  v_Rate NUMERIC:= NULL;
  v_StdPrecision     NUMERIC;
  v_CostingPrecision NUMERIC;
BEGIN
  -- Nothing to do
  IF(p_UOMFrom_ID = p_UOMTo_ID  OR p_UOMFrom_ID IS NULL OR p_UOMTo_ID IS NULL  OR p_Qty IS NULL OR p_Qty = 0) THEN
    RETURN p_Qty;
  END IF;
  -- Get Multiply Rate
  BEGIN
    SELECT MultiplyRate
    INTO v_Rate
    FROM C_UOM_Conversion
    WHERE C_UOM_ID = p_UOMFrom_ID
    AND C_UOM_TO_ID = p_UOMTo_ID;
    -- We have it
    v_Result := p_Qty * v_Rate;
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END;
  -- Get Divide Rate
  IF(v_Result IS NULL) THEN
    BEGIN
      SELECT DivideRate
      INTO v_Rate
      FROM C_UOM_Conversion
      WHERE C_UOM_ID = p_UOMTo_ID
      AND C_UOM_TO_ID = p_UOMFrom_ID;
      -- We have it
      v_Result := p_Qty * v_Rate;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  -- Round
  IF(v_Result IS NOT NULL) THEN
    BEGIN
      SELECT StdPrecision,
        CostingPrecision
      INTO v_StdPrecision,
        v_CostingPrecision
      FROM C_UOM
      WHERE C_UOM_ID = p_UOMTo_ID;
      -- We have a precision
      IF(p_StdPrecision = 'Y') THEN
        v_Result := ROUND(v_Result, v_StdPrecision) ;
      ELSIF (p_StdPrecision = 'NO') THEN
        v_Result := v_Result;
      ELSE
        v_Result := ROUND(v_Result, v_CostingPrecision) ;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
RETURN v_Result;
END ; $_$;


/*****************************************************+



General Support and Utility Functions




*****************************************************/
CREATE or replace FUNCTION zsse_groupcount (p_identifier varchar) returns varchar 
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk_____________________________.
***************************************************************************************************************************************************
Group Count Function
*****************************************************/
v_counter numeric;
v_curval varchar;
BEGIN
  if (select count(*) from pg_class where relname='countu' and relkind='r')=0 then
    create temporary table countu(
    groupnumber  numeric  not null,
    keyvalue varchar(250) not null
    )  ON COMMIT DROP;
    insert into countu(groupnumber,keyvalue) values (1,p_identifier);
    v_counter:=1;
  else 
    select groupnumber,keyvalue into v_counter,v_curval from countu;
    if p_identifier!=v_curval then
        v_counter:=v_counter+1;
        update countu set groupnumber=v_counter,keyvalue=p_identifier;
    end if;
  end if;
  RETURN v_counter;
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE or replace FUNCTION zsse_identifierexists (p_identifier varchar) returns varchar 
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH
Contributor(s): ________________________.
********************************************************************************************************************************************************************************************************/
v_counter numeric;
v_curval varchar;
BEGIN
  if (select count(*) from pg_class where relname='idexist' and relkind='r')=0 then
    create temporary table idexist(
    keyvalue varchar(250) not null
    )  ON COMMIT DROP;
    insert into idexist(keyvalue) values (p_identifier);
    return 'N';
  else 
    if (select count(*) from idexist where keyvalue=p_identifier)>0 then
        return 'Y';
    else
        insert into idexist(keyvalue) values (p_identifier);
        return 'N';
    end if;
  end if;
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE or replace FUNCTION zsse_getmainfrompopup( p_key character varying, p_columnid character varying, p_desturl character varying, p_name character varying) returns character varying
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny Heuduk_____________________________.
***************************************************************************************************************************************************
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN
 
  RETURN '<a href="#" onclick="getmainfrompopup('||chr(39)||p_key||chr(39)||',' ||chr(39)||p_columnid||chr(39)||',' ||chr(39)||p_desturl||chr(39)||');return false;" class="LabelLink">'||p_name||'</a>';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


  
CREATE or replace FUNCTION zsse_sendDirectLinkGridNamed(p_fieldname character varying,p_key character varying,p_tableId character varying, p_text character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  RETURN '<a href="#" onclick="sendDirectLink(document.frmMain, '||chr(39)||p_fieldname||chr(39)||', '||chr(39)||chr(39)||', '||chr(39)||'../utility/ReferencedLink.html'||chr(39)||', '||chr(39)||p_key||chr(39)||', '||chr(39)||p_tableId||chr(39)||', '||chr(39)||'_self'||chr(39)||', true);;return false;" onmouseover="window.status='||chr(39)||'Linkactive'||chr(39)||';return true;" style="" onmouseout="window.status='||chr(39)||chr(39)||';return true;" title="'||p_text||'" class="LabelLink LabelLink_focus">'||p_text||'</a>' ;
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE or replace FUNCTION zsse_htmldirectlink(p_targetwindowurl character varying,p_fieldid character varying,p_key character varying,p_text character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  RETURN '<a href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||','||p_fieldid||','||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_white">'||p_text||' </a>';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE or replace FUNCTION zsse_htmlLinkDirectKey(p_targetwindowurl character varying,p_key character varying,p_text character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  RETURN '<a href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_white">'||p_text||' </a>';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE or replace FUNCTION zsse_htmlLinkDirectKey_notblue_short(p_targetwindowurl character varying,p_key character varying,p_text character varying,p_color varchar) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  --RETURN '<a title="'||zssi_2html(p_text)||'" href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_white">'||p_text||' </a>';

if p_color='white' then
    RETURN '<a title="'||zssi_2html(p_text)||'" href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_white">'||'&nbsp;'||p_text||' </a>';
else
    RETURN '<a title="'||zssi_2html(p_text)||'" href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_black">'||'&nbsp;'||p_text||' </a>';
end if;
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
CREATE or replace FUNCTION zsse_htmlLinkDirectKey_notblue(p_targetwindowurl character varying,p_key character varying,p_text character varying,p_color varchar) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  --RETURN '<a title="'||zssi_2html(p_text)||'" href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_white">'||p_text||' </a>';

if p_color='white' then
    RETURN '<a title="'||zssi_2html(p_text)||'" href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_white">'||rpad(p_text,16,'')||' </a>';
else
    RETURN '<a title="'||zssi_2html(p_text)||'" href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_black">'||rpad(p_text,16,'')||' </a>';
end if;
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE or replace FUNCTION zsse_htmlLinkDirectKeyGridView(p_targetwindowurl character varying,p_key character varying,p_text character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  RETURN '<a href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECTRELATION'||chr(39)||',document.frmMain.inpDirectKey,'||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink">'||p_text||' </a>';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE or replace FUNCTION zsse_htmldirectlinkWithDummyField(p_targetwindowurl character varying,p_fieldid character varying,p_key character varying,p_text character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  RETURN '<INPUT type="hidden" name="'||p_fieldid||'"></INPUT><a href="#" onclick="submitCommandFormParameter('||chr(39)||'DIRECT'||chr(39)||',document.frmMain.'||p_fieldid||','||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink_white">'||p_text||' </a>';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  CREATE or replace FUNCTION zsse_htmldirectlinkWithDummyFieldGrid(p_targetwindowurl character varying,p_fieldid character varying,p_key character varying,p_text character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/

BEGIN 
  
  RETURN '<INPUT type="hidden" name="'||p_fieldid||'"></INPUT><a href="#" onclick="submitCommandFormParameter('||chr(39)||'DEFAULT'||chr(39)||',document.frmMain.'||p_fieldid||','||chr(39)||p_key||chr(39)||', false, document.frmMain, '||chr(39)||p_targetwindowurl||chr(39)||', null, false, true);return false;" class="LabelLink">'||p_text||' </a>';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zsse_addattachmentfile(p_table_id character varying, p_record_id character varying, p_user character varying, p_client character varying,p_org character varying,p_name character varying , p_text character varying) RETURNS character varying
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
Copy a Product - File Entrys in C_File
*****************************************************/

v_seq numeric;
BEGIN 
    select coalesce(max(SEQNO)+10,10) into v_seq from c_file where AD_TABLE_ID=p_table_id and AD_RECORD_ID=p_record_id;
          insert into c_file (C_FILE_ID, AD_CLIENT_ID, AD_ORG_ID,   CREATEDBY, UPDATEDBY, NAME, C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID, AD_RECORD_ID)
                 values(get_uuid(),p_CLIENT,p_ORG, p_user,p_user,p_name,'103', v_seq, p_TEXT, p_table_id,p_record_id);

    return 'SUCCESS';
EXCEPTION
    WHEN OTHERS then
       return SQLERRM;        
END;
$_$  LANGUAGE 'plpgsql';

/*****************************************************+



General Service Fubnctions




*****************************************************/
select zsse_DropView ('ad_process_execution_v');
CREATE OR REPLACE VIEW ad_process_execution_v AS 
 SELECT rn.ad_process_run_id, rn.ad_client_id, rn.ad_org_id, rn.isactive, rn.created, rn.createdby, rn.updated, rn.updatedby, 
   rq.ad_user_id, rn.status, rn.start_time as start_time, rn.end_time as end_time, 
   rn.runtime, rn.log, rn.result, rq.params, rn.report, rq.channel, rq.isrolesecurity, rq.ad_process_id, rn.ad_process_request_id
   FROM ad_process_run rn,ad_process_request rq where rn.ad_process_request_id = rq.ad_process_request_id;        

   
select zsse_DropView ('ad_process_onlineapistatus_v');
CREATE OR REPLACE VIEW ad_process_onlineapistatus_v AS 
 SELECT rn.ad_process_run_id,'90A1262177A645B9BD1D0E21FE889079'::text as ad_process_onlineapistatus_v_id, rn.ad_client_id, rn.ad_org_id, rn.isactive, rn.created, rn.createdby, rn.updated, rn.updatedby, 
   rq.ad_user_id, rn.status, to_char(rn.start_time,'dd.mm.yyyy hh24:mi:ss') as start_time, to_char(rn.end_time,'dd.mm.yyyy hh24:mi:ss') as end_time, 
   rn.runtime, rn.log, rn.result, rq.params, rn.report, rq.channel, rq.isrolesecurity, rq.ad_process_id, rn.ad_process_request_id
   FROM ad_process_run rn,ad_process_request rq where rn.ad_process_request_id = rq.ad_process_request_id
   and rq.ad_process_id='CD7FC6BA9A644CA9A6AD21B974DBF833' order by created desc LIMIT 1;        

   
CREATE or replace FUNCTION zsse_instancesqlexecute(p_setoriginal character varying) returns character varying
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
Execute individual Statements for the Custom Instance
*****************************************************/
 v_cur RECORD;
 v_name character varying;
BEGIN 
  select name into v_name from ad_client where ad_client_id='C726FEC915A54A0995C568555DA5BB3C';
  RAISE NOTICE '%', 'Setting '||case when p_setoriginal='Y' then 'default' else 'Instance specific' end ||' customizing for Client '||v_name; 
  for v_cur in (select * from zsse_executeondeploy where isstandard=p_setoriginal order by seqno)
  LOOP
     EXECUTE v_cur.sqlstmt;
     RAISE NOTICE '%', v_cur.sqlstmt;
  END LOOP;
  RAISE NOTICE '%', 'Execute finished for Client '||v_name; 
  RETURN 'Instance-Specific SQL-Statements Executed.';
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
   

CREATE OR REPLACE FUNCTION zsse_logclean() 
RETURNS VARCHAR
AS $_$
DECLARE
/*****************************************************+
Stefan Zimmermann, 01/2011, sz@zimmermann-software.de
Cleans the Scheduler LOG periodically 
*****************************************************/
-- SELECT zsse_logclean();
  v_message character varying;
  i integer;
BEGIN 
   DELETE FROM ad_note WHERE created < now()-7;
   GET DIAGNOSTICS i := ROW_COUNT; 
   v_message := i || ' Process Notes deleted. - ';
   
   DELETE FROM ad_process_run WHERE (created < now()-20);
   GET DIAGNOSTICS i := ROW_COUNT; 
   v_message := v_message || i || ' Process Runs deleted. - ';
   
   DELETE FROM ad_process_run WHERE ad_process_run.ad_process_request_id in
                              (select ad_process_request_id from ad_process_request 
                                      where ad_process_id in ('7B0A43D047B640D4B150CA2EBE76466F','BFC6D5DCB87242719FFA80E265C1DB7C','CD7FC6BA9A644CA9A6AD21B974DBF833'));
   -- In Out Plan Update, Update Project Status,SeoShopSyncProcess
   GET DIAGNOSTICS i := ROW_COUNT; 
   v_message := v_message || i || '  Material Planning and Project Status Process Logs deleted. - ';
   
   DELETE FROM ad_session sess WHERE (created < now()-5) AND (sess.session_active = 'N');
   GET DIAGNOSTICS i := ROW_COUNT; 
   v_message := v_message || i || ' Session-LOGs deleted';
   
    -- Finishing
   v_message := 'LogClean successful finished:' || v_message;
   RETURN v_message;
END;
$_$ LANGUAGE 'plpgsql';


CREATE or replace FUNCTION zsse_checkbansecure(p_ad_user_id character varying) RETURNS character varying
AS $_$
DECLARE
/*****************************************************+
Stefan Zimmermann, 04/2011, sz@zimmermann-software.de
Security Login Function
Bans a User for 10 minutes , if there where three 
failed Login Tries
*****************************************************/
-- Simple Types
v_message character varying;
v_count numeric;
BEGIN 
   select count(*) into v_count from ZSSE_SECURELOGIN where ad_user_id=p_ad_user_id and created > (now() - INTERVAL '10 minutes');
   if v_count>2 then
        RETURN 'BANNED';
   else
        RETURN 'OK';
   end if;
END;
$_$  LANGUAGE 'plpgsql';    

CREATE or replace FUNCTION zsse_failedlogin(p_ad_user_id character varying) RETURNS character varying
AS $_$
DECLARE
/*****************************************************+
Stefan Zimmermann, 04/2011, sz@zimmermann-software.de
Security Login Function
Records a Failed Login Try
*****************************************************/
BEGIN 
   if p_ad_user_id is not null then
        insert into ZSSE_SECURELOGIN(ZSSE_SECURELOGIN_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, AD_USER_ID)
                         VALUES(get_uuid(),'0','0','0','0',p_ad_user_id);
   end if;
   return 'OK';
END;
$_$  LANGUAGE 'plpgsql';   
 

CREATE or replace FUNCTION zsse_schedule(p_processname character varying,p_frequence character varying, p_value numeric, p_start timestamp with time zone,p_delete character varying) RETURNS character varying
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
Scheduling of Processes
 p_frequence : 1 sec, 2 min, 3 h, 4 days
 p_value: Multiplier. e.g. p_frequence =3, p_value=5 => Every 5 hours
 p_start: Start-Time
 p_delete: If Y then do only delete the Process-Scheduling, if I shedule Process immediately
*****************************************************/
-- Simple Types
v_proc_id character varying;
v_count numeric;
v_start  timestamp with time zone;
v_startdate  timestamp with time zone;
v_message character varying;
v_timestr character varying;
v_interval   character varying;
v_org varchar;
v_option varchar:='S'; --sheduled
v_uid varchar;
BEGIN 
    v_start:=p_start;
    if p_processname is null then
        return 'Compile';
    end if;
    if coalesce(p_delete,'N')='I' then
        v_option:='I'; -- immediately
    end if;
     --select systemid into v_org from ad_systemupdateview limit 1;
     v_org:='0';
    if p_frequence not in ('1','2','3','4') or p_value <=0 then
        RAISE EXCEPTION '%', 'Parameter Error';
    end if;
    select count(*) into v_count from ad_process where value=p_processname;
    if v_count!=1 then
         RAISE EXCEPTION '%', 'Cannot schedule process. Process-count is: '||v_count;
    end if;
    select  case p_frequence when '1' then 'seconds' when '2' then 'minutes' when '3' then 'hours' when '4' then 'days' end into v_interval;
    while coalesce(v_start,now())<now() 
    LOOP
       v_start:=v_start+to_interval(p_value::integer, v_interval);
    END LOOP;
    -- Get Time from Timestamp (Ugly! I did not find a Postgres-Function...)
    if v_start is not null then
        select '0001-01-01 '||substr(to_char(extract(hour from v_start),'00'),2,2)||':'||substr(to_char(extract(minute from v_start),'00'),2,2)||':'||substr(to_char(extract(second from v_start),'00'),2,2)||' BC' into v_timestr;
    end if;
    select ad_process_id into v_proc_id from ad_process where value=p_processname;
    select count(*) into v_count from ad_process_request where ad_process_id=v_proc_id and status='PRC';
    if v_count>0 then
          RAISE EXCEPTION '%', 'Cannot schedule process '||v_proc_id||' is Currently RUNNING!!!!!!!!!!!! ';
    end if;
    if coalesce(p_delete,'N')='Y' then
       delete from ad_process_request where AD_PROCESS_ID=v_proc_id and status in ('SCH','SUC','UNS','MIS');
       v_message:='Scheduling of '||p_processname||' deleted.';
    else
        v_uid:=get_uuid();
        delete from ad_process_request where AD_PROCESS_ID=v_proc_id;-- and status in ('SCH','SUC','UNS','MIS');
        insert into ad_process_request(AD_PROCESS_REQUEST_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                               OB_CONTEXT, 
                               AD_PROCESS_ID, AD_USER_ID, ISROLESECURITY,STATUS, 
                               NEXT_FIRE_TIME, PREVIOUS_FIRE_TIME,start_time,start_date,CHANNEL,TIMING_OPTION, 
                               FREQUENCY,secondly_interval, MINUTELY_INTERVAL, hourly_interval,daily_interval,
                               DAY_MON, DAY_TUE, DAY_WED, DAY_THU, DAY_FRI, DAY_SAT, DAY_SUN,
                               MONTHLY_OPTION, FINISHES, DAILY_OPTION, SCHEDULE, RESCHEDULE, UNSCHEDULE)
        values(v_uid,'C726FEC915A54A0995C568555DA5BB3C',coalesce(v_org,'0'),'Y',now(),'100',now(),'100',
                      '{"org.openbravo.scheduling.ProcessContext":{"user":100,"role":0,"language":"de_DE","theme":"ltr'||chr(92)||'/Default","client":0,"organization":0,"warehouse":"","command":"DEFAULT","userClient":"","userOrganization":"","dbSessionID":"","javaDateFormat":"","jsDateFormat":"","sqlDateFormat":"","accessLevel":"","roleSecurity":true}}',
                       v_proc_id,'100','Y','SCH',
                       null,null,to_timestamp(v_timestr,'yyyy-dd-mm hh24:mi:ss BC'),trunc(v_start),'Process Scheduler',v_option,
                       p_frequence,case p_frequence when '1' then p_value end,case p_frequence when '2' then p_value end,case p_frequence when '3' then p_value end,case p_frequence when '4' then p_value end,
                      'N','N','N','N','N','N','N',
                      'S','N','N','N','N','N');
        v_message:=v_uid;
     end if;     
    return v_message;
END;
$_$  LANGUAGE 'plpgsql';


SELECT zsse_droptrigger('ad_process_request_mod_trg', 'ad_process_request');

CREATE OR REPLACE FUNCTION public.ad_process_request_mod_trg ()
RETURNS TRIGGER AS
$body$
-- MH: implemented with Version 2.6.62.063
DECLARE
-- v_fieldCaption ad_field.name%TYPE := '' ;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT') THEN
    IF upper(new.channel)=UPPER('Process Scheduler') and ((SELECT COUNT(*) FROM ad_process_request req WHERE UPPER(req.channel) = UPPER('Process Scheduler') AND req.ad_process_id = new.ad_process_id) >=1) THEN
   -- v_fieldCaption := COALESCE((SELECT ad_getfieldtext('573D4A317DC3FFC9E040007F01012790', 'de_DE')),''); -- toDo: get language
      RAISE EXCEPTION '%','@SaveErrorNotUnique@'; -- || '''' || v_fieldCaption || '''';
    END IF;
  END IF;
  IF (TG_OP = 'UPDATE') THEN
    IF (old.ad_process_id != new.ad_process_id) THEN
   -- v_fieldCaption := COALESCE((SELECT ad_getfieldtext('573D4A317DC3FFC9E040007F01012790', 'de_DE')),''); -- toDo: get language
      RAISE EXCEPTION '%','@SaveErrorNotUnique@'; -- || '''' || v_fieldCaption || '''';
    END IF;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

CREATE TRIGGER ad_process_request_mod_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON ad_process_request FOR EACH ROW
  EXECUTE PROCEDURE ad_process_request_mod_trg();


CREATE OR REPLACE FUNCTION ad_treenode_mod_trg()
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
******************************************************************************************************************************************************************************************************************************+
Stefan Zimmermann, 2011, sz@zimmermann-software.de
Implements Actions on different Trees
*****************************************************************************/
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; 
  END IF; 
END; $BODY$
  LANGUAGE 'plpgsql';

  
CREATE OR REPLACE FUNCTION ad_treeGetUpperHierarchy(p_nodeId varchar,pTreeId varchar, p_upperNode OUT varchar, xy out varchar) RETURNS setof RECORD
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/

v_nodeId character varying;
v_temp varchar;
--cur_node RECORD;
weiter character varying:='Y';
BEGIN 
    v_nodeId:=p_nodeId;
    WHILE weiter='Y'
    LOOP
        select parent_id into v_temp from ad_treenode where ad_tree_id=pTreeId and node_id=v_nodeId;
        p_upperNode:=v_temp;
        xy:='DUMMY';
        if p_upperNode is not null and p_upperNode!='0' then
            RETURN NEXT;
        else
            weiter='N';
        end if;
        v_nodeId:=p_upperNode;
    end loop;
END;
$_$  LANGUAGE 'plpgsql';

select zsse_dropfunction('ad_treeGetLowerHierarchy');
CREATE OR REPLACE FUNCTION ad_treeGetLowerHierarchy(p_nodeId varchar,pTreeId varchar,p_initlevel in numeric, p_lowerNode OUT varchar, p_level out numeric,p_seq out numeric, p_created out timestamp) RETURNS setof RECORD
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/

v_nodeId character varying;
v_cur RECORD;
v_cur2 record;
v_level numeric;
v_parentnode varchar;
BEGIN 
    v_nodeId:=coalesce(p_nodeId,'0');
    v_level:=p_initlevel+1;
    for v_cur in (select  * from ad_treenode where ad_tree_id=pTreeId and parent_id=v_nodeId order by seqno,created)
    LOOP
        p_lowerNode:=v_cur.node_id;
        p_level:=v_level;
        p_seq:=v_cur.seqno;
        p_created:=v_cur.created;
        v_parentnode:=v_cur.node_id;
        RETURN NEXT;
        for v_cur2 in (select  a.p_lowerNode,a.p_level,a.p_seq,a.p_created from ad_treeGetLowerHierarchy(v_parentnode,pTreeId,v_level) a)
        LOOP
            p_lowerNode:=v_cur2.p_lowerNode;
            p_level:=v_cur2.p_level;
            p_seq:=v_cur2.p_seq;
            p_created:=v_cur2.p_created;
            RETURN NEXT;
        END LOOP;
    END LOOP;
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION ad_addfile(p_table_id character varying, p_recordid character varying, p_user character varying,p_filename varchar,p_org varchar,p_text varchar) RETURNS character varying
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
Copy a Product - File Entrys in C_File
*****************************************************/

v_count numeric;
v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
BEGIN 
    if p_recordid is null or p_table_id is null then
        return 'NORECORD';
    end if;
    select max(SEQNO)+10 into v_count from c_file where AD_TABLE_ID = p_table_id and AD_RECORD_ID=p_recordid;
    if v_count is null then v_count:=10; end if;
    
    insert into c_file (C_FILE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, NAME, C_DATATYPE_ID, SEQNO, TEXT, AD_TABLE_ID, AD_RECORD_ID)
                 values (get_uuid(),v_client,p_org,'Y',now(),p_user,now(),p_user,p_filename,'103',v_count,p_text,p_table_id,p_recordid);
    
    return 'SUCCESS';    
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ad_delfile(p_table_id character varying, p_recordid character varying, p_filename varchar) RETURNS character varying
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
Copy a Product - File Entrys in C_File
*****************************************************/

v_count numeric;
v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
BEGIN 
    
    
    delete from  c_file where ad_table_id=p_table_id and ad_record_id=p_recordid and name=p_filename;
    
    return 'SUCCESS';
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ad_copyimage(p_adimage_id character varying, p_user character varying) RETURNS character varying
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
Copy a Product - File Entrys in C_File
*****************************************************/

v_guid varchar;
v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
BEGIN 
    select get_uuid() into v_guid;
    if p_adimage_id is null then
        return null;
    end if;
    insert into ad_image(ad_image_id, ad_client_id,ad_org_id,  createdby, updatedby, name, imageurl , binarydata)
    select v_guid, ad_client_id,ad_org_id,  p_user,p_user,name, imageurl , binarydata from ad_image where ad_image_id = p_adimage_id;
    
    return v_guid;
END;
$_$  LANGUAGE 'plpgsql';
     

CREATE OR REPLACE FUNCTION c_orgconfiguration_trg() RETURNS trigger
LANGUAGE plpgsql
AS $_$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of CORE
Prevents deletion of Main DOCTYPES
*****************************************************/
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
    update ad_preference set value=new.createprojectfromso where attribute=upper('createprojectfromso');
    update ad_preference set value=new.closeprojectfromso where attribute=upper('closeprojectfromso');
    update ad_preference set value=new.reinvoiceprojectexpenses where attribute=upper('reinvoiceprojectexpenses');
    update ad_preference set value=new.prapprovalworkflow where attribute=upper('prapprovalworkflow');
    update ad_preference set value=new.productvaluereadonly where attribute=upper('productvaluereadonly');
    update ad_preference set value=new.bpartnervaluereadonly where attribute=upper('bpartnervaluereadonly');
    update ad_preference set value=new.docnoreadonly where attribute=upper('docnoreadonly');
    update ad_preference set value=new.projectvaluereadonly where attribute=upper('projectvaluereadonly');
    update ad_preference set value=new.refreshintervall where attribute=upper('refreshinterval');
    update ad_tab_instance set isactive=new.prefedineserials where ad_tab_id='11BDCB38C8AC4A129E843458CEC58AE9';
    if new.prefedineserials='Y' then
        update AD_Ref_Fieldcolumn set isactive='Y' where AD_Ref_Fieldcolumn_id='E572976E95024F388D51F3040EAD6698';
        update AD_Ref_Fieldcolumn set isactive='N' where AD_Ref_Fieldcolumn_id='F929D4568D244B3BA9DDCB9153A1367E';
    end if;
    if new.prefedineserials='N' then
        update AD_Ref_Fieldcolumn set isactive='N' where AD_Ref_Fieldcolumn_id='E572976E95024F388D51F3040EAD6698';
        update AD_Ref_Fieldcolumn set isactive='Y' where AD_Ref_Fieldcolumn_id='F929D4568D244B3BA9DDCB9153A1367E';
    end if;
    -- Updating
    IF TG_OP = 'UPDATE' THEN
        IF NEW.mfacookieduration < 1 OR NEW.mfacookieduration > 366 OR NEW.keeploggedincookieduration < 1 OR NEW.keeploggedincookieduration > 366 THEN
            RAISE EXCEPTION '@MFA_ErrorCookieDurationInvalid@';
        END IF;
        IF NEW.pwreqslength < 1 OR NEW.pwreqslength > 100 THEN
            RAISE EXCEPTION '@passwordRequirementsIllegalLength@';
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

DROP TRIGGER c_orgconfiguration_trg ON c_orgconfiguration;

CREATE TRIGGER c_orgconfiguration_trg
  AFTER INSERT or UPDATE
  ON c_orgconfiguration
  FOR EACH ROW
  EXECUTE PROCEDURE c_orgconfiguration_trg();

/*****************************************************+
Stefan Zimmermann, 2011, stefan@zimmermann-software.de



   General Configuration Options





*****************************************************/



CREATE OR REPLACE FUNCTION c_orgconfigurationbef_trg() RETURNS trigger 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Part of Smartprefs
Business Partner - On Insert. Only one user on employees and undefined partner
*****************************************************/
DECLARE 
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  select count(*) into v_count from c_orgconfiguration where c_orgconfiguration.ad_org_id=new.ad_org_id;
  if v_count > 0  then
      RAISE EXCEPTION '%', '@zssi_OnlyOneDS@';
  end if;
  RETURN NEW;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION c_orgconfigurationbef_trg() OWNER TO tad;

drop trigger c_orgconfigurationbef_trg on c_orgconfiguration;

CREATE TRIGGER c_orgconfigurationbef_trg
  BEFORE INSERT
  ON c_orgconfiguration
  FOR EACH ROW
  EXECUTE PROCEDURE c_orgconfigurationbef_trg();


CREATE or replace FUNCTION c_getconfigoption(p_option character varying, p_org character varying) RETURNS character
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
******************************************************************************************************************************************************************************************************************************+
Stefan Zimmermann, 04/2011, sz@zimmermann-software.de
Check if Database - Dump is created out of an opensource instance
If ORG-ID exists, there may be customer-Data - Giva warning in that case
*****************************************************************************/
v_sql character varying;
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_return character;
BEGIN 
    if coalesce(p_option,'')!='' then
      v_sql:='select '||p_option||' as retval from c_orgconfiguration where isactive='||chr(39)||'Y'||chr(39)||' and ad_org_id='||chr(39)||coalesce(p_org,'0')||chr(39);
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_return:=v_cur.retval;
      END LOOP;
      close v_cursor;
      if v_return is null then
         v_sql:='select '||p_option||' as retval from c_orgconfiguration where isactive='||chr(39)||'Y'||chr(39)||' and isstandard='||chr(39)||'Y'||chr(39);
         OPEN v_cursor FOR EXECUTE v_sql;
         LOOP
                  FETCH v_cursor INTO v_cur;
                  EXIT WHEN NOT FOUND;
                  v_return:=v_cur.retval;
         END LOOP;
         close v_cursor;
      end if;
      if v_return is null then
         select substr(column_default,2,1) into v_return from information_schema.columns where lower(table_name)='c_orgconfiguration' and lower(column_name)=p_option;
      end if;
      return v_return;
    else
        return '';
    end if;
END;
$_$  LANGUAGE 'plpgsql';    



CREATE or replace FUNCTION c_ismfaactivatedforuser(p_user character varying) RETURNS character
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
******************************************************************************************************************************************************************************************************************************/
v_adorgid character varying;
v_adroleid character varying;
BEGIN
    IF(p_user = '0' OR p_user = '100' OR p_user = 'DDAA21D11CB04D4D8EC59E39934B27FB') THEN -- System, OpenZ or Service
        RETURN 'N';
    END IF;
    IF((SELECT mfa_active FROM ad_user WHERE ad_user_id = p_user) = 'N') THEN -- mfa not active for user
        RETURN 'N';
    END IF;
    FOR v_adroleid IN SELECT ad_role_id FROM ad_user_roles WHERE ad_user_id = p_user LOOP -- loop all roles from user
        FOR v_adorgid IN SELECT ad_org_id FROM ad_role_orgaccess WHERE ad_role_id = v_adroleid LOOP -- loop all orgs for each role
            IF(c_getconfigoption('mfaactivated', v_adorgid) = 'Y') THEN
                RETURN 'Y';
            END IF;
        END LOOP;
    END LOOP;
    RETURN 'N';

END;
$_$  LANGUAGE 'plpgsql';  



/*****************************************************+
Stefan Zimmermann, 2011, stefan@zimmermann-software.de









   General Auxilliary Functions





*****************************************************/
CREATE or replace FUNCTION zssi_cleanasciistring(p_strin varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
v_return character varying;
BEGIN
return replace(replace(replace(replace(replace(replace(replace(replace(p_strin,'&','&amp;'),'ß','ss'),'ä','ae'),'ö','oe'),'ü','ue'),'Ä','Ae'),'Ö','Oe'),'Ü','Ue');
END $_$ LANGUAGE plpgsql VOLATILE;
  
CREATE or replace FUNCTION zssi_getLastDayOfQuarter(p_startdate timestamp,p_quarter varchar) RETURNS timestamp
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************

Gives Back the Last Day in a Quarter Beginning from Startdate

p_quarter = 1Q : Last day in the 1st Quarter from startdate
p_quarter = 2Q
p_quarter = 3Q
p_quarter = 4Q: Last day in the fourth Quarter from startdate

*/
v_interval interval:=0;
v_enddate timestamp;
BEGIN 
   if p_quarter='2Q' then v_interval:= INTERVAL '3 month'; elsif p_quarter='3Q' then v_interval:= INTERVAL '6 month'; elsif p_quarter='4Q' then v_interval:= INTERVAL '9 month'; end if;
   v_enddate:=p_startdate + INTERVAL '3 month' + v_interval - INTERVAL '1 day';
   return v_enddate;
END; $_$  LANGUAGE 'plpgsql';


create or replace function c_daysinmonth(p_date timestamp)
returns numeric as
$BODY$
declare 
-- Calculates How many days the given month has.
    datetime_start date := ('01.01.'||extract(year from p_date)::char(4))::date;
    datetime_month date := ('01.'||extract(month from p_date)||'.'||extract(year from p_date))::date;
    cnt numeric;
begin 
  select extract(day from (select (datetime_month + INTERVAL '1 month -1 day'))) into cnt;
  return cnt;
end;
$BODY$
language plpgsql;

CREATE OR REPLACE FUNCTION zssi_isdateinrange(p_datetocheck timestamp with time zone, p_fromdate timestamp with time zone, p_todate timestamp with time zone)
  RETURNS character varying AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************/

  BEGIN
    
    IF((p_datetocheck <= p_todate) AND (p_datetocheck >= p_fromdate)) THEN
      RETURN 'Y';
    END IF;
	RETURN 'N';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_isdateinrange(timestamp with time zone, timestamp with time zone, timestamp with time zone) OWNER TO tad;


  
create or replace function last_dayofmonth(p_date timestamp without time zone)
  returns timestamp without time zone as
  $_$ 
  /***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseOrder as Link
*****************************************************/
  
  DECLARE
  v_return date;
  BEGIN
  v_return := (select (date_trunc('month', p_date + '1 month'::interval) - '1day'::interval)::timestamp without time zone);
  RETURN v_return;
  END;
  $_$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
create or replace function first_dayofmonth(p_date timestamp without time zone)
  returns timestamp without time zone as
  $_$ 
  /***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Danny A. Heuduk.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
Generating PurchaseOrder as Link
*****************************************************/
  
  DECLARE
  v_return date;
  BEGIN
  v_return := (select (date_trunc('month', p_date ))::timestamp without time zone);
  RETURN v_return;
  END;
  $_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION public.isEmpty (
  p_variable VARCHAR
)
RETURNS BOOLEAN AS
$BODY$
BEGIN
  RETURN ( (p_variable IS NULL) OR (LENGTH(p_variable) = 0) );
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;


CREATE OR REPLACE FUNCTION instr(character varying, character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
DECLARE
    pos integer;
BEGIN
    pos:= instr($1, $2, 1);
    RETURN pos;
END;
$_$;



--
-- Name: instr(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION instr(string character varying, string_to_search character varying, beg_index integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
DECLARE
    pos integer NOT NULL DEFAULT 0;
    temp_str varchar;
    beg integer;
    length integer;
    ss_length integer;
BEGIN
    IF ((string IS NULL) OR (string_to_search IS NULL) OR (beg_index IS NULL)) THEN RETURN 0; END IF;
    IF beg_index > 0 THEN
      temp_str := substring(string FROM beg_index);
      pos := position(string_to_search IN temp_str);
      IF pos = 0 THEN
        RETURN 0;
      ELSE
        RETURN pos + beg_index - 1;
      END IF;
    ELSE
      ss_length := char_length(string_to_search);
      length := char_length(string);
      beg := length + beg_index - ss_length + 2;
      WHILE beg > 0 LOOP
        temp_str := substring(string FROM beg FOR ss_length);
        pos := position(string_to_search IN temp_str);
        IF pos > 0 THEN
          RETURN beg;
        END IF;
        beg := beg - 1;
      END LOOP;
      RETURN 0;
    END IF;
END;
$_$;


--
-- Name: instr(character varying, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION instr(string character varying, string_to_search character varying, beg_index integer, occur_index integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
DECLARE
    pos integer NOT NULL DEFAULT 0;
    occur_number integer NOT NULL DEFAULT 0;
    temp_str varchar;
    beg integer;
    i integer;
    length integer;
    ss_length integer; 
BEGIN
    IF ((string IS NULL) OR (string_to_search IS NULL) OR (beg_index IS NULL) OR (occur_index IS NULL)) THEN RETURN 0; END IF;
IF beg_index > 0 THEN
    beg := beg_index;
    temp_str := substring(string FROM beg_index);

    FOR i IN 1..occur_index LOOP
        pos := position(string_to_search IN temp_str);
         IF i = 1 THEN
            beg := beg + pos - 1;
        ELSE
            beg := beg + pos;
        END IF;
         temp_str := substring(string FROM beg + 1);
    END LOOP;          
    IF pos = 0 THEN
        RETURN 0;
    ELSE
        RETURN beg;
    END IF;
ELSE
    ss_length := char_length(string_to_search);
    length := char_length(string);
    beg := length + beg_index - ss_length + 2;
     WHILE beg > 0 LOOP
        temp_str := substring(string FROM beg FOR ss_length);
        pos := position(string_to_search IN temp_str);
         IF pos > 0 THEN
            occur_number := occur_number + 1;
             IF occur_number = occur_index THEN
                RETURN beg;
            END IF;
        END IF;
         beg := beg - 1;
    END LOOP;
     RETURN 0;
END IF; 
END;
$_$;



CREATE or replace FUNCTION zsse_checkopensourceinstance() RETURNS character varying
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
******************************************************************************************************************************************************************************************************************************+
Stefan Zimmermann, 04/2011, sz@zimmermann-software.de
Check if Database - Dump is created out of an opensource instance
If ORG-ID exists, there may be customer-Data - Giva warning in that case
*****************************************************************************/
v_count1 numeric;
v_count2 numeric;
BEGIN 
   select count(*) into v_count1 from ad_org;
   select count(*) into v_count2 from ad_module where iscommercial='Y';
   if v_count1>1 or  v_count2 >0 then
         RAISE EXCEPTION '%', 'WARNING!!!!!!!!     THIS IS NO OPEN SOURCE INSTANCE   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!THIS IS NO OPEN SOURCE INSTANCE  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!THIS IS NO OPEN SOURCE INSTANCE  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
         RETURN 'NO OPENSOURCE INSTANCE   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
   else
        delete from ad_module_sql;
        RETURN 'OK';
   end if;
END;
$_$  LANGUAGE 'plpgsql';    


select zsse_DropView ('ad_systemupdateview');

CREATE VIEW ad_systemupdateview AS 
 select '0'::text as ad_systemupdateview_id,'Y'::character(1) as isactive, '0'::text as ad_org_id,'0'::text as ad_client_id, '0'::text as createdby, now() as created, now() as updated, '0'::text as updatedby,
        count(*)::numeric as namedusers, (select ad_org_id from ad_org where created=(select min(created) from ad_org where ad_org_id!='0')) as systemid,
        (select version_label from ad_module where ad_module_id='0') as version,
        (select licensedusers from ad_system limit 1) as licensedusers,
        (select case when activation_key is not null then 'Enterprise/Cloud' else 'Community' end from ad_system) as openzflavor
        from ad_user a where  a.password is not null and a.isactive ='Y' and ad_user_id not in ('0','100','DDAA21D11CB04D4D8EC59E39934B27FB')
        and exists (select 0 from ad_user_roles r where r.ad_user_id=a.ad_user_id);


        
/*****************************************************+
Stefan Zimmermann, 2011, stefan@zimmermann-software.de









   Auxilliary Data Retrieval Functions Functions
   For Use in Querys





*****************************************************/



CREATE OR REPLACE FUNCTION zsse_CopyAttachmentFile(
  p_source_id  VARCHAR,
  p_target_id  VARCHAR,
  p_user       VARCHAR
) RETURNS VARCHAR
AS $zs$
-- called from java-class (no ad_pinstance): CopyOrderTemplateAttService.java
DECLARE
  v_message  VARCHAR := '';
  v_count    NUMERIC := 0;
  v_c_file   c_file%ROWTYPE;
BEGIN  -- 2012-06-21

  FOR v_c_file IN (
    SELECT * FROM c_file  WHERE ad_record_id = p_source_id ORDER BY seqno
  )
  LOOP
    v_c_file.c_file_id = get_uuid();
    v_c_file.created = NOW();
    v_c_file.createdby = p_user;
    v_c_file.updated = NOW();
    v_c_file.updatedby = p_user;
    v_c_file.ad_record_id = p_target_id;
    INSERT INTO c_file VALUES (v_c_file.*);
    v_count := (v_count + 1);
  END LOOP;
  v_message = '@zsse_CopyAttachmentFile_RecordsCopied@' || ' ' || v_count || ' ' || COALESCE(p_source_id,'') ; -- 'Anzahl kopierter Datens..:'
  RETURN '@SUCCESS@' || ' ' || v_message; -- check structure for return in process class for sqlresult.splitt(" ")
EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ProcessRunError@' || ' ' || SQLERRM || ' ' || 'zsse_CopyAttachmentFile';
    RAISE NOTICE '%s', v_message;
    RETURN v_message;
END;
$zs$
LANGUAGE 'plpgsql';


CREATE or replace FUNCTION ad_updateAlertRule(p_alertrule varchar) RETURNS varchar
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*/

BEGIN 
-- Yet only Debt Payment Approval is updated.
--- @TODO@ Implement Alert-Rule (After rearranging Alertz-Servlet!) - parametr doen't work yet...
      --   if p_alertrule='08ECB61212BC4324AE1B43D40708383C' then
                  update ad_alert set description= 'Zahlung für Dokumentnummer: '||i.documentno||'<br>Betrag: '||i.grandtotal||'<br>Lieferant: '||
                                                    (select name from c_bpartner where i.c_bpartner_id=c_bpartner.c_bpartner_id)||
                                                    '<br>Überweisung von: '||dp.amount||' '||cc.cursymbol||'<br>Geplant am: '||
                                                    zssi_strDate(coalesce(i.schedtransactiondate,i.dateinvoiced),'de_DE')||'<br>'||
                                                    zssi_getinvdoc_link(i.c_invoice_id,'Rechnung - '||i.documentno)
                                                    ||'<br>'||'Genehmigt am:'||zssi_strDate(dp.updated,'de_DE')||' durch '||zssi_getusernamecomplete(dp.updatedby,'de_DE')
                  from c_invoice i,C_DEBT_PAYMENT dp,c_currency cc where    DP.C_INVOICE_ID = I.C_INVOICE_ID
                        and cc.c_currency_id=i.c_currency_id
                        AND DP.IsActive='Y'
                        AND DP.IsValid='Y'
                        AND DP.isapproved ='Y'
                        ANd i.issotrx='N'
                        and ad_alert.referencekey_id=i.c_invoice_id 
                        and ad_alert.ad_alertrule_id='08ECB61212BC4324AE1B43D40708383C'
                        and C_DEBT_PAYMENT_STATUS(DP.C_Settlement_Cancel_ID, DP.CANCEL_PROCESSED, DP.GENERATE_PROCESSED, DP.ISPAID, DP.ISVALID, DP.C_CASHLINE_ID, DP.C_BANKSTATEMENTLINE_ID) = 'P';
        --  end if;
            return 'OK';
END; $_$  LANGUAGE 'plpgsql';



CREATE or replace FUNCTION ad_RoleAccessOnlyOwnData(p_roleId varchar, p_windowID varchar) RETURNS varchar
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2013 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************

Determine if this Role in This Window can see only its own data..

*/
v_return varchar;
BEGIN 
    select seesonlyowndata into v_return from ad_window_access where ad_role_id=p_roleId and ad_window_id=p_windowID;
    return coalesce(v_return,'N');
END; $_$  LANGUAGE 'plpgsql';


  
  
CREATE OR REPLACE FUNCTION c_getDefaultDocInfo(p_tablename character varying, p_idvalue character varying,OUT ad_org_id character varying, OUT  document_id character varying, OUT docstatus  character varying,OUT   docTypeTargetId  character varying, OUT  ourreference  character varying, OUT  cusreference  character varying, OUT  bpartner_id  character varying, OUT  bpartner_language  character varying, OUT  unique_timestamp  character varying, OUT  bpartner_name  character varying, OUT  orga  character varying, OUT  docname  character varying)
  RETURNS setof record AS
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
 
 Default Doc-Info Used in Print-Controller
 
*****************************************************/
v_doctypeid varchar;

BEGIN
if p_tablename='C_PROJECT' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Project';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.value||'-'||p.name,p.poreference,p.c_bpartner_id,
           (select ad_language from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           (select name from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id),
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from c_project p where c_project_id=p_idvalue;
elsif p_tablename='C_PROJECTTASK' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Projecttask';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.name,p.poreference,p.c_bpartner_id,
           (select ad_language from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           (select name from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id),
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from c_project p, c_projecttask pt where pt.c_project_id=p.c_project_id and pt.c_projecttask_id=p_idvalue;
elsif p_tablename='ZSSM_WORKSTEP_V' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Workstep';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.name,p.poreference,p.c_bpartner_id,
           (select ad_language from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           (select name from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id),
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from c_project p, c_projecttask pt where pt.c_project_id=p.c_project_id and pt.c_projecttask_id=p_idvalue;
elsif p_tablename='C_BPARTNEREMPLOYEE_VIEW' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Employee';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,replace(p.name,',',''),'',p.c_bpartner_id,p.ad_language, 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           p.name,
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from C_BPARTNEREMPLOYEE_VIEW p where C_BPARTNEREMPLOYEE_VIEW_id=p_idvalue;
    elsif p_tablename='A_ASSET' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Asset';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,'','','','', 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           p.name,
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from a_asset p where a_asset_id=p_idvalue;
elsif p_tablename='SNR_MASTERDATA' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Serialnumber';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.serialnumber,'','','', 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from SNR_MASTERDATA p where SNR_MASTERDATA_id=p_idvalue;
elsif p_tablename='SNR_BATCHMASTERDATA' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Batchnumber';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.batchnumber,'','','',
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'),
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from SNR_BATCHMASTERDATA p where SNR_BATCHMASTERDATA_id=p_idvalue;
elsif p_tablename='ZSSM_PRODUCTIONORDER_V' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Productionorder';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.name,p.poreference,p.c_bpartner_id,
           (select ad_language from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           (select name from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id),
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from c_project p where c_project_id=p_idvalue;
elsif p_tablename='ZSSM_WORKSTEPACTIVITIES_V' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'WorkstepActivity';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.name,p.poreference,p.c_bpartner_id,
           (select ad_language from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           (select name from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id),
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from c_project p, c_projecttask pt,zspm_ptaskhrplan hr where pt.c_project_id=p.c_project_id 
         and pt.c_projecttask_id=hr. c_projecttask_id and hr.zspm_ptaskhrplan_id=p_idvalue;
elsif p_tablename='C_BPARTNER' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'BusinessPartner';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.name,'',p.c_bpartner_id,
           p.ad_language , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           p.name ,
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from c_bpartner p where p.c_bpartner_id=p_idvalue;
elsif p_tablename='M_REQUISITION' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Requisition';
    select p.ad_org_id,p_idvalue,p.docstatus,v_doctypeid,p.documentno,'',p.c_bpartner_id,
           (select ad_language from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           (select name from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id),
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from m_requisition p where p.m_requisition_id=p_idvalue;
elsif p_tablename='C_CASH' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Cashbook';
    select p.ad_org_id,p_idvalue,p.docstatus,v_doctypeid,p.name,'','',
           'de_DE' , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from c_cash p where p.c_cash_id=p_idvalue;
elsif p_tablename='M_RETOUR_MANAGEMENT' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Retour';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.name,'','',
           'de_DE' , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from M_RETOUR_MANAGEMENT p where p.M_RETOUR_MANAGEMENT_id=p_idvalue;
elsif p_tablename='M_PRODUCT' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Product';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,p.value||'-'||p.name,'','',
           (select ad_language from ad_client b where ad_client_id='C726FEC915A54A0995C568555DA5BB3C') , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from m_product p where m_product_id=p_idvalue;
elsif p_tablename='MRP_CRITICALITEMS_V' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Criticalitems';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,'','','',
           (select ad_language from ad_client b where ad_client_id='C726FEC915A54A0995C568555DA5BB3C') , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from MRP_CRITICALITEMS_V p where MRP_CRITICALITEMS_V_id=p_idvalue;
elsif p_tablename='M_PRODUCT_PO' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Purchasesubtab';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,'','','',
           (select ad_language from ad_client b where ad_client_id='C726FEC915A54A0995C568555DA5BB3C') , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from M_PRODUCT_PO p where M_PRODUCT_PO_id=p_idvalue;
elsif p_tablename='MRP_DELIVERIES_EXPECTED' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'Deliveriesexpected';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,'','','',
           (select ad_language from ad_client b where ad_client_id='C726FEC915A54A0995C568555DA5BB3C') , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from MRP_DELIVERIES_EXPECTED p where MRP_DELIVERIES_EXPECTED_id=p_idvalue;
elsif p_tablename='DUNRUN_HISTORY' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'DunningRun';
    select p.ad_org_id as ad_org_id,p_idvalue,'CO',v_doctypeid,(select value from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) as name,'' as poreference,p.c_bpartner_id,
           (select ad_language from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id) , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           (select name from c_bpartner b where b.c_bpartner_id=p.c_bpartner_id),
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from DUNRUN_HISTORY p where p.DUNRUN_HISTORY_id=p_idvalue;
elsif p_tablename='M_INTERNAL_CONSUMPTION' then
    select c_doctype_id into v_doctypeid from c_doctype where name = 'InternalConsumptionAndReturn';
    select p.ad_org_id,p_idvalue,'CO',v_doctypeid,'','','',
           (select ad_language from ad_client b where ad_client_id='C726FEC915A54A0995C568555DA5BB3C') , 
           to_char(CURRENT_TIMESTAMP, 'YYDDDSSSS'), 
           '',
           zssi_juwiorgshortcut(p.ad_org_id),
           zssi_docshortcut(v_doctypeid)
    into ad_org_id,document_id,docstatus,docTypeTargetId,ourreference,cusreference,bpartner_id,bpartner_language,unique_timestamp,bpartner_name,orga,docname
    from M_INTERNAL_CONSUMPTION p where M_INTERNAL_CONSUMPTION_id=p_idvalue;
else 
    if p_tablename is not null then 
        raise exception '%','This Doctype must be added to the  c_getDefaultDocInfo - Function';
    end if;
end if;
    return next;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION getDocStatus(p_table_id character varying,p_currentvalue character varying)
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
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_sql character varying;
v_keycolumname character varying;
v_columnid character varying;
v_tablename character varying;
v_result character varying;
BEGIN
  if p_table_id is not null then
      select columnname,tablename into v_keycolumname,v_tablename from ad_column,ad_table where 
              ad_table.ad_table_id=ad_column.ad_table_id and iskey='Y' and ad_table.ad_table_id=p_table_id;
      v_sql:='select docstatus from '||v_tablename||' where '||v_keycolumname||' = '|| chr(39)||coalesce(p_currentvalue,'')||chr(39);
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_result:=v_cur.docstatus;
      END LOOP;
      close v_cursor;
  end if;   
  RETURN v_result;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE or replace FUNCTION zssi_countrowsfromtable(p_tablename character varying, p_key character varying,p_in character varying)    RETURNS character varying AS
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
Example== SELECT zssi_countrowsfromtable('m_product','m_product_id','(''4A7491D578CE464988998F1084ECD672'',''785F4E237AB34D4A9723F76E348E3A61'',''556994838CDC4611BB0A2B038B246128'')');
*/
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
v_sql character varying;
v_keycolumname character varying;
v_columnid character varying;
v_tablename character varying;
v_result character varying;
BEGIN
        if p_tablename is not null then
            if p_key is not null then
                if p_in is not null then
      --v_sql:='select count(*) as x from '||p_tablename||' where '||p_key||' in ('|| chr(39)||coalesce(p_in,'')||chr(39)||')';
      v_sql:='select count(*) as x from '||p_tablename||' where '||p_key||' in '||coalesce(p_in,'');
      OPEN v_cursor FOR EXECUTE v_sql;
        LOOP
            FETCH v_cursor INTO v_cur;
            EXIT WHEN NOT FOUND;
            v_result:=v_cur.x;
        END LOOP;
      close v_cursor;
                end if;
            end if;
        end if;   
  
  RETURN coalesce(v_result,'0');
exception when others then
    return '0';
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  SELECT zsse_dropfunction('zssi_getdatafromtable');

  CREATE or replace FUNCTION zssi_getdatafromtable(p_tablename character varying, p_key character varying,p_in character varying, p_lang varchar ,OUT valuefield character varying, OUT namefield character varying,OUT idfield character varying)    RETURNS SETOF record AS
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
Example== SELECT zssi_countrowsfromtable('m_product','m_product_id','(''4A7491D578CE464988998F1084ECD672'',''785F4E237AB34D4A9723F76E348E3A61'',''556994838CDC4611BB0A2B038B246128'')');
*/
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_cur RECORD;
c character varying;
ret_dataline c_orderline%rowtype;
v_sql character varying;
v_keycolumname character varying;
ttt_name character varying :='';
ttt_value character varying :='';
v_columnid character varying;
v_tablename character varying;
v_result character varying;
BEGIN
        if p_tablename is not null then
            if p_key is not null then
                if p_in is not null then
      --v_sql:='select count(*) as x from '||p_tablename||' where '||p_key||' in ('|| chr(39)||coalesce(p_in,'')||chr(39)||')';
v_sql:='select value, zssi_getIdentifierFromKey('''||p_key||''','||p_key||','''||p_lang||''') as name, '||p_key||' as idfield  from '||p_tablename||' where '||p_key||' in '||coalesce(p_in,'');
      for v_cur in EXECUTE (v_sql)
        LOOP
valuefield:=v_cur.value;
namefield:=v_cur.name;
idfield:=v_cur.idfield;
 return next;
        END LOOP;
                end if;
            end if;
        end if;   
  
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


-- Is the unit field for a product be read only?
-- Yes, when there exists a stock transaction or an order of the product
-- Y -> read only
-- N -> editable
select zsse_DropFunction ('is_product_unit_read_only');
CREATE OR REPLACE FUNCTION is_product_unit_read_only(p_product_id varchar, p_command_type varchar)
  RETURNS varchar AS
$BODY$
DECLARE
BEGIN
  -- not a new product and
  -- does a stock transaction exist?
  -- or does an orderline exist?
  IF(
    p_command_type != 'NEW' AND
    (
      (SELECT COUNT(*) FROM m_transaction WHERE m_product_id = p_product_id) != 0
      OR (SELECT COUNT(*) FROM c_orderline WHERE m_product_id = p_product_id) != 0
    )
    ) THEN
      RETURN 'Y';
  END IF;
  RETURN 'N';
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION to_number(text)
-- From Postgres 9.3 on this replace is requred. We assume a german localization in the database
-- Older Versions of Postgres are treated as before
  RETURNS numeric AS
$BODY$
  DECLARE v_version CHARACTER VARYING;
BEGIN
    -- Replace first ',' or '.' from the right with 'x'. This will be interpreted as the decimal point. After that delete all remainding ',' and '.'. Finally replace the 'x' with ','.
    -- 123.456.789,46 -> 123456789,46; 123,456,789.46 -> 123456789,46; 123.456,789.46 -> 123456789,46; 123456789,46 -> 123456789,46
    RETURN to_number(regexp_replace(regexp_replace(reverse(regexp_replace(reverse($1), '(\,|\.)', 'x')), '(\,|\.)', '', 'g'), 'x', ','), 'S99999999999999D999999');
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION isnumeric(text) RETURNS BOOLEAN AS $_$
DECLARE x NUMERIC;
BEGIN
    x = $1::NUMERIC;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$_$ LANGUAGE plpgsql IMMUTABLE;
