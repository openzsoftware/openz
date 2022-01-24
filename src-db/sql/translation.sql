
--
-- Name: ad_element_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_element_trg() RETURNS trigger
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
    * Insert AD_Element Trigger
    *  for Translation
    * Update AD_Element Trigger
    *  synchronize Column
    *  synchronize PrintInfo
    *  reset Translation flag
    ************************************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- Insert AD_Element Trigger
  IF TG_OP = 'INSERT' THEN
        INSERT
        INTO AD_Element_Trl
          (
            AD_Element_Trl_ID, AD_Element_ID, AD_Language, AD_Client_ID,
            AD_Org_ID, IsActive, Created,
            CreatedBy, Updated, UpdatedBy,
            Name, PrintName, Description,
            Help, PO_Name, PO_PrintName,
            PO_Description, PO_Help, IsTranslated
          )
        SELECT get_uuid(), new.AD_Element_ID,
          AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
          new.IsActive, new.Created, new.CreatedBy,
          new.Updated, new.UpdatedBy, new.Name,
          new.PrintName, new.Description, new.Help,
          new.PO_Name, new.PO_PrintName, new.PO_Description,
          new.PO_Help,  'N'
        FROM AD_Language, AD_Module M
              WHERE AD_Language.IsActive='Y'
                AND IsSystemLanguage='Y'
                AND isonly4format='N'
                AND M.AD_Module_ID = new.AD_Module_ID
                AND M.AD_Language != AD_Language.AD_Language;
 END IF;
 IF TG_OP = 'UPDATE'  THEN
      UPDATE AD_Field
            SET NAME = NEW.NAME,
                Description = NEW.Description,
                HELP = NEW.HELP
          WHERE  AD_Field_ID IN (
                  SELECT F.AD_Field_ID
                    FROM AD_Field F, AD_Column C, AD_Module M
                    WHERE F.AD_Column_ID = C.AD_Column_ID
                      AND C.AD_Element_ID = NEW.AD_Element_ID
                      AND F.IsCentrallyMaintained = 'Y'
                      AND M.aD_Module_id = f.ad_module_id)
          AND exists (SELECT 1 from ad_module m
                  where m.ad_module_id=ad_field.ad_module_id
                  and m.isindevelopment='Y');

      update AD_Element_Trl set Name=new.Name,PrintName=new.PrintName where AD_Element_id=new.AD_Element_id and istranslated='N';

      UPDATE AD_Process_Para
         SET NAME = NEW.NAME,
             Description = NEW.Description,
             HELP = NEW.HELP
      WHERE  AD_Process_Para_ID IN (
               SELECT f.AD_Process_Para_ID
                 FROM AD_Process_Para f, AD_Process p, ad_module m
               WHERE  f.AD_Element_ID = NEW.AD_Element_ID
                  AND f.IsCentrallyMaintained = 'Y'
                  and p.ad_process_id = f.ad_process_id
                  and m.ad_module_id = p.ad_module_id)
      AND exists (SELECT 1 from ad_module m, ad_process p
                   where m.ad_module_id=p.ad_module_id
                   and p.ad_process_id = ad_process_para.ad_process_id
                   and m.isindevelopment='Y');        
 END IF;
-- UPDATING
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;


ALTER FUNCTION public.ad_element_trg() OWNER TO tad;

--
-- Name: ad_alertrule_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_alertrule_trg() RETURNS trigger
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
****************************************************************************************************************************************************
*/
      --TYPE RECORD IS REFCURSOR;
      Cur_Role RECORD;
      recipient_ID VARCHAR(32); --OBTG:VARCHAR2--
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;



    IF TG_OP = 'INSERT' THEN
      -- insert translations
      INSERT INTO AD_AlertRule_Trl
        (
          AD_AlertRule_Trl_ID, AD_AlertRule_ID, AD_Language, AD_Client_ID,
          AD_Org_ID, IsActive, Created,
          CreatedBy, Updated, UpdatedBy,
          Name, IsTranslated
        )
      SELECT
        get_uuid(), new.AD_AlertRule_ID, AD_Language, new.AD_Client_ID,
        new.AD_Org_ID, new.IsActive, new.Created,
        new.CreatedBy, new.Updated, new.UpdatedBy,
        new.Name, 'N'
      FROM AD_Language
      WHERE IsActive='Y'
        AND IsSystemLanguage='Y'
        AND isonly4format='N';
   END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;





CREATE OR REPLACE FUNCTION at_command_trg() RETURNS trigger
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
****************************************************************************************************************************************************
*/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- Insert AT_Command Trigger
    --  for Translation
    IF TG_OP = 'INSERT'
    THEN
          --  Create Translation Row
        INSERT
        INTO AT_Command_Trl
          (
            AT_Command_Trl_ID, AT_Command_ID, AD_LANGUAGE, AD_Client_ID,
            AD_Org_ID, IsActive, Created,
            CreatedBy, Updated, UpdatedBy,
            Name, Description, ArgHelp1,
            ArgHelp2, ArgHelp3, IsTranslated
          )
        SELECT get_uuid(), NEW.AT_Command_ID,
          AD_LANGUAGE, NEW.AD_Client_ID, NEW.AD_Org_ID,
          NEW.IsActive, NEW.Created, NEW.CreatedBy,
          NEW.Updated, NEW.UpdatedBy, NEW.Name,
          NEW.Description, NEW.ArgHelp1, NEW.ArgHelp2,
          NEW.ArgHelp3,  'N'
        FROM AD_LANGUAGE
        WHERE IsActive='Y'
          AND IsSystemLanguage='Y'
          AND isonly4format='N';
   END IF;
   -- Inserting
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.at_command_trg() OWNER TO tad;

--
-- Name: ad_workflow_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_workflow_trg() RETURNS trigger
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
    */
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- Insert AD_Workflow Trigger
    --  for Translation
    --  Access
    IF TG_OP = 'INSERT'
    THEN
        --  Create Translation Row
        INSERT
        INTO AD_Workflow_Trl
          (
            AD_Workflow_Trl_ID, AD_Workflow_ID, AD_Language, AD_Client_ID,
            AD_Org_ID, IsActive, Created,
            CreatedBy, Updated, UpdatedBy,
            Name, Description, Help,
            IsTranslated
          )
        SELECT get_uuid(), new.AD_Workflow_ID,
          AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
          new.IsActive, new.Created, new.CreatedBy,
          new.Updated, new.UpdatedBy, new.Name,
          new.Description, new.Help, 'N'
        FROM AD_Language, AD_Module M
        WHERE AD_Language.IsActive='Y'
           AND IsSystemLanguage='Y'
           AND isonly4format='N'
           AND M.AD_Module_ID = new.AD_Module_ID
           AND M.AD_Language != AD_Language.AD_Language;
        -- Access for all
        INSERT
        INTO AD_WorkFlow_Access
          ( 
            AD_WorkFlow_ID, AD_Role_ID, AD_Client_ID,
            AD_Org_ID, IsActive, Created,
            CreatedBy, Updated, UpdatedBy,
            IsReadWrite, AD_WorkFlow_Access_ID
          )
        SELECT new.AD_WorkFlow_ID,
          r.AD_Role_ID, r.AD_CLIENT_ID, r.AD_ORG_ID,
          'Y', TO_DATE(NOW()), '0',
          TO_DATE(NOW()), '0', 'Y', get_uuid()
        FROM AD_Role r
        WHERE isManual='N';
   END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;
ALTER FUNCTION public.ad_workflow_trg() OWNER TO tad;






--
-- Name: ad_window_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_window_trg() RETURNS trigger
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
    * $Id: AD_Window_Trg.sql,v 1.2 2002/08/26 05:23:32 jjanke Exp $
    ***
    * Title: Window Changes
    * Description:
    *   - Transaltion
    *   - Sync Name (Workflow, Menu)
    *   - Active State (Menu)
    ************************************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- Insert AD_Window Trigger
    --  for Translation
    --  Access
    IF TG_OP = 'INSERT'
    THEN
          --  Create Translation Row
        INSERT
        INTO AD_Window_Trl
          (
            AD_Window_Trl_ID, AD_Window_ID, AD_Language, AD_Client_ID,
            AD_Org_ID, IsActive, Created,
            CreatedBy, Updated, UpdatedBy,
            Name, Description, Help,
            IsTranslated
          )
        SELECT get_uuid(), new.AD_Window_ID,
          AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
          new.IsActive, new.Created, new.CreatedBy,
          new.Updated, new.UpdatedBy, new.Name,
          new.Description, new.Help, 'N'
        FROM AD_Language, AD_Module M
        WHERE AD_Language.IsActive='Y'
          AND IsSystemLanguage='Y'
          AND isonly4format='N'
          AND M.AD_Module_ID = new.AD_Module_ID
          AND M.AD_Language != AD_Language.AD_Language;
        -- Access for all
        INSERT
        INTO AD_Window_Access
          (
            AD_Window_Access_ID, AD_Window_ID, AD_Role_ID, AD_Client_ID,
            AD_Org_ID, IsActive, Created,
            CreatedBy, Updated, UpdatedBy,
            IsReadWrite
          )
        SELECT DISTINCT get_uuid(), new.AD_Window_ID,
          r.AD_Role_ID, r.AD_CLIENT_ID, r.AD_ORG_ID,
          'Y', TO_DATE(NOW()), '0',
          TO_DATE(NOW()), '0',  'Y'
        FROM AD_Role r
        WHERE isManual='N';
   END IF;
 -- Inserting
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.ad_window_trg() OWNER TO tad;






CREATE OR REPLACE FUNCTION ad_textinterfaces_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $BODY$ DECLARE 

/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
*/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Insert AD_TEXTINTERFACES Trigger
  --  for Translation
  IF TG_OP = 'INSERT'
  THEN
    --  Create Translation Row
    INSERT INTO AD_TEXTINTERFACES_TRL
                (AD_TEXTINTERFACES_TRL_ID, AD_TEXTINTERFACES_ID, AD_LANGUAGE, AD_CLIENT_ID, AD_ORG_ID,
                 ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, TEXT,
                 ISTRANSLATED)
      SELECT get_uuid(), NEW.AD_TEXTINTERFACES_ID, AD_LANGUAGE.AD_LANGUAGE, NEW.AD_CLIENT_ID,
             NEW.AD_ORG_ID, NEW.ISACTIVE, NEW.CREATED, NEW.CREATEDBY,
             NEW.UPDATED, NEW.UPDATEDBY, NEW.TEXT, 'N'
        FROM AD_Language, AD_Module M
        WHERE AD_Language.IsActive='Y'
        AND IsSystemLanguage='Y'
        AND isonly4format='N'
        AND M.AD_Module_ID = new.AD_Module_ID
        AND M.AD_Language != AD_Language.AD_Language;
  END IF;
-- Updating

IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $BODY$;
ALTER FUNCTION ad_textinterfaces_trg() OWNER TO tad;

--
-- Name: ad_wf_node_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_wf_node_trg() RETURNS trigger
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
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    */
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- Insert AD_WF_Node Trigger
    --  for Translation
    IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO AD_WF_Node_Trl
    (
      AD_WF_Node_Trl_ID, AD_WF_Node_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      Name, Description, Help,
      IsTranslated
    )
  SELECT get_uuid(), new.AD_WF_Node_ID,
    AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy, new.Name,
    new.Description, new.Help, 'N'
  FROM AD_Language, AD_Module M, AD_Workflow w
  WHERE AD_Language.IsActive='Y'
    AND IsSystemLanguage='Y'
    AND isonly4format='N'
    and w.ad_workflow_id = new.AD_Workflow_ID
    AND M.AD_Module_ID = w.AD_Module_ID
    AND M.AD_Language != AD_Language.AD_Language;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;


ALTER FUNCTION public.ad_wf_node_trg() OWNER TO tad;


--
-- Name: ad_task_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_task_trg() RETURNS trigger
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
    * Insert Translation
    */
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO AD_Task_Trl
    (
      AD_Task_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      Name, Description, IsTranslated
    )
  SELECT new.AD_Task_ID,
    AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy, new.Name,
    new.Description,  'N'
  FROM AD_Language
  WHERE IsActive='Y'
    AND IsSystemLanguage='Y'
    AND isonly4format='N';
 END IF;
 -- Inserting
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.ad_task_trg() OWNER TO tad;





CREATE OR REPLACE FUNCTION ad_tab_trg() RETURNS trigger
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
    *************************************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


   --Check tab name starts with a upper case letter
   IF (not (substr(new.Name,1,1) between 'A' and 'Z')) THEN
     RAISE EXCEPTION '%', '@TabName1stCharUpper@' ; --OBTG:-20000--
   END IF;

    -- Insert AD_Tab Trigger
    --  for Translation
    IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
        INSERT
        INTO AD_Tab_Trl
          (
            AD_Tab_Trl_ID, AD_Tab_ID, AD_Language, AD_Client_ID,
            AD_Org_ID, IsActive, Created,
            CreatedBy, Updated, UpdatedBy,
            Name, Description, Help,
            IsTranslated
          )
        SELECT get_uuid(), new.AD_Tab_ID,
          AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
          new.IsActive, new.Created, new.CreatedBy,
          new.Updated, new.UpdatedBy, new.Name,
          new.Description, new.Help, 'N'
        FROM AD_Language, AD_Module M
        WHERE AD_Language.IsActive='Y'
          AND IsSystemLanguage='Y'
          AND isonly4format='N'
          AND M.AD_Module_ID = new.AD_Module_ID
          AND M.AD_Language != AD_Language.AD_Language;
    END IF;
 -- Inserting
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.ad_tab_trg() OWNER TO tad;


--
-- Name: ad_reference_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_reference_trg() RETURNS trigger
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
* Specifically, this derivative work is based upon the following Compiere
* file and version.
*************************************************************************
*/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Insert AD_Reference Trigger
  --  for Translation
  IF TG_OP = 'INSERT'
  THEN
    --  Create Translation Row
    INSERT INTO AD_Reference_Trl
                ( AD_Reference_Trl_ID, AD_Reference_ID, AD_Language, AD_Client_ID, AD_Org_ID,
                 IsActive, Created, CreatedBy, Updated, UpdatedBy, NAME,
                 Description, HELP, IsTranslated)
      SELECT get_uuid(), NEW.AD_Reference_ID, AD_Language.AD_Language, NEW.AD_Client_ID,
             NEW.AD_Org_ID, NEW.IsActive, NEW.Created, NEW.CreatedBy,
             NEW.Updated, NEW.UpdatedBy, NEW.NAME, NEW.Description,
             NEW.HELP, 'N'
        FROM AD_Language, AD_Module M
       WHERE AD_Language.IsActive = 'Y' AND IsSystemLanguage = 'Y' AND isonly4format='N'
        AND M.AD_Module_ID = new.AD_Module_ID
       AND M.AD_Language != AD_Language.AD_Language;
  END IF;

-- Inserting
-- AD_Reference update trigger
--  synchronize name,...
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


ALTER FUNCTION public.ad_reference_trg() OWNER TO tad;





CREATE OR REPLACE FUNCTION ad_ref_list_trg() RETURNS trigger
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
    * $Id: AD_Ref_List_Trg.sql,v 1.2 2003/02/18 03:33:22 jjanke Exp $
    ***
    * Title: Ref List Translation
    * Description:
    ************************************************************************/
    v_aux NUMERIC;    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  --In case the value is in a different module than its reference check the value
  --starts with that module's dbprefix or in case it is a value for skins list
  --it starts with the module's java package.
  SELECT count(*)
    INTO v_Aux
    FROM AD_REFERENCE R
   WHERE R.AD_REFERENCE_ID = new.AD_REFERENCE_ID
     AND R.AD_MODULE_ID != new.AD_Module_ID
     AND NOT EXISTS (SELECT 1 
                      FROM AD_MODULE_DBPREFIX P
                      WHERE P.AD_MODULE_ID = new.AD_Module_ID 
                      AND instr(upper(new.value), upper(P.name)||'_') = 1)
     AND NOT (new.AD_REFERENCE_ID = '800102'
             AND EXISTS (SELECT 1
                           FROM AD_MODULE M2
                          WHERE M2.AD_MODULE_ID = NEW.AD_MODULE_ID
                          AND instr(upper(new.VALUE), upper(M2.JAVAPACKAGE))=1));
  
  IF v_Aux != 0 THEN
    RAISE EXCEPTION '%', '@ListValueDBPrefix@' ; --OBTG:-20000--
  END IF;
  


    -- Insert AD_Ref_List Trigger
    --  for Translation
    IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
          INSERT
          INTO AD_Ref_List_Trl
            (
              AD_Ref_List_Trl_ID, AD_Ref_List_ID, AD_Language, AD_Client_ID,
              AD_Org_ID, IsActive, Created,
              CreatedBy, Updated, UpdatedBy,
              Name, Description, IsTranslated
            )
          SELECT get_uuid(), new.AD_Ref_List_ID,
            AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
            new.IsActive, new.Created, new.CreatedBy,
            new.Updated, new.UpdatedBy, new.Name,
            new.Description,  'N'
          FROM AD_Language, AD_Module M, ad_reference r
          WHERE AD_Language.IsActive='Y'
            AND AD_Language.IsSystemLanguage='Y'
            AND AD_Language.isonly4format='N'
            AND M.AD_Module_ID = r.AD_Module_ID
            and r.ad_reference_id = new.ad_reference_id
            AND M.AD_Language != AD_Language.AD_Language;
        END IF;
 -- Inserting
 
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.ad_ref_list_trg() OWNER TO tad;

--
-- Name: ad_process_trl_trg(); Type: FUNCTION; Schema: public; Owner: tad
--




CREATE OR REPLACE FUNCTION ad_process_trg() RETURNS trigger
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
* $Id: AD_Process_Trg.sql,v 1.3 2002/09/16 04:14:40 jjanke Exp $
***
* Title: Process Trigger
* Description:
*   Synchronize Names and Translation
*   Sync IsActive with Menu / Field
************************************************************************/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Insert AD_Process Trigger
  --  for Translation
  --  add Access
  IF TG_OP = 'INSERT'
  THEN
    --  Create Translation Row
    INSERT INTO AD_Process_Trl
                (AD_Process_Trl_ID, AD_Process_ID, AD_Language, AD_Client_ID, AD_Org_ID,
                 IsActive, Created, CreatedBy, Updated, UpdatedBy, NAME,
                 Description, HELP, IsTranslated)
      SELECT get_uuid(), NEW.AD_Process_ID, AD_Language.AD_Language, NEW.AD_Client_ID,
             NEW.AD_Org_ID, NEW.IsActive, NEW.Created, NEW.CreatedBy,
             NEW.Updated, NEW.UpdatedBy, NEW.NAME, NEW.Description,
             NEW.HELP, 'N'
        FROM AD_Language, ad_module m
       WHERE AD_Language.IsActive = 'Y' AND IsSystemLanguage = 'Y' AND isonly4format='N'
       and m.ad_module_id = new.ad_module_id
       and m.ad_language != AD_Language.AD_Language;

    -- Add Access for all Roles
    INSERT INTO AD_Process_Access
                (AD_Process_Access_ID, AD_Process_ID, AD_Role_ID, AD_Client_ID, AD_Org_ID,
                 IsActive, Created, CreatedBy, Updated, UpdatedBy,
                 IsReadWrite)
      SELECT get_uuid(), NEW.AD_Process_ID, r.AD_Role_ID, r.AD_CLIENT_ID, r.AD_ORG_ID,
             'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()), '0', 'Y'
        FROM AD_Role r
       where isManual='N';
  END IF;



IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.ad_process_trg() OWNER TO tad;






CREATE OR REPLACE FUNCTION ad_message_trg() RETURNS trigger
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
* $Id: AD_Message_Trg.sql,v 1.2 2002/05/11 04:32:33 jjanke Exp $
***
* Title: Message Translation
* Description:
************************************************************************/
 v_aux NUMERIC;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF new.AD_Module_ID != '0' THEN
    SELECT COUNT(*)
      INTO v_Aux
      FROM AD_MODULE_DBPREFIX
     WHERE AD_MODULE_ID = new.AD_Module_ID
       AND (instr(upper(new.value), upper(name)||'_') = 1
          OR instr(upper(new.value), 'EM_'||upper(name)||'_') = 1);
    
    IF v_Aux = 0 THEN
      RAISE EXCEPTION '%', 'Messages must start with its module DB prefix' ; --OBTG:-20536--
    END IF;
  END IF;

  -- Insert AD_Ref_List Trigger
  --  for Translation
  IF TG_OP = 'INSERT'
  THEN
    INSERT INTO AD_Message_Trl
                (AD_Message_Trl_ID, AD_Message_ID, AD_Language, AD_Client_ID, AD_Org_ID,
                 IsActive, Created, CreatedBy, Updated, UpdatedBy, MsgText,
                 MsgTip, IsTranslated)
      SELECT get_uuid(), NEW.AD_Message_ID, AD_Language.AD_Language, NEW.AD_Client_ID,
             NEW.AD_Org_ID, NEW.IsActive, NEW.Created, NEW.CreatedBy,
             NEW.Updated, NEW.UpdatedBy, NEW.MsgText, NEW.MsgTip, 'N'
        FROM AD_Language, aD_Module m
       WHERE AD_Language.IsActive = 'Y' AND IsSystemLanguage = 'Y' AND isonly4format='N'
       and m.ad_module_id = new.ad_module_id
       and m.ad_language != AD_Language.AD_Language;
  END IF;

-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;


ALTER FUNCTION public.ad_message_trg() OWNER TO tad;



CREATE OR REPLACE FUNCTION ad_menu_trg() RETURNS trigger
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
  *************************************************************************/



  v_xTree_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_xParent_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_NextNo     VARCHAR(32); --OBTG:VARCHAR2--
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Insert AD_Menu Trigger
  --  for Translation
  --  and TreeNode
  IF TG_OP = 'INSERT' THEN
    --  Create Translation Row
    INSERT
    INTO AD_Menu_Trl
      (
        AD_Menu_Trl_ID, AD_Menu_ID, AD_Language, AD_Client_ID,
        AD_Org_ID, IsActive, Created,
        CreatedBy, Updated, UpdatedBy,
        Name, Description, IsTranslated
      )
    SELECT get_uuid(), new.AD_Menu_ID,
      AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
      new.IsActive, new.Created, new.CreatedBy,
      new.Updated, new.UpdatedBy, new.Name,
      new.Description,
       'N'
    FROM AD_Language, ad_module m
    WHERE AD_Language.IsActive='Y'
      AND IsSystemLanguage='Y' AND isonly4format='N'
      and m.ad_module_id = new.ad_module_id
    and m.ad_language != AD_Language.AD_Language;
    --  Create TreeNode --
    --  get AD_Tree_ID + ParentID
    SELECT c.AD_Tree_Menu_ID,
      n.Node_ID
    INTO v_xTree_ID,
      v_xParent_ID
    FROM AD_ClientInfo c,
      AD_TreeNode n
      -- AD_TreeNodeMM n
    WHERE c.AD_Tree_Menu_ID=n.AD_Tree_ID
      AND n.Parent_ID IS NULL
      AND c.AD_Client_ID=new.AD_Client_ID;
    --  DBMS_OUTPUT.PUT_LINE('Tree='||v_xTree_ID||'  Node='||:new.AD_Menu_ID||'  Parent='||v_xParent_ID);
    --  Insert into TreeNode
    INSERT
    INTO AD_TreeNode
      -- AD_TreeNodeMM
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
        new.UpdatedBy, v_xTree_ID, new.AD_Menu_ID,
        v_xParent_ID,(
        CASE new.IsSummary
          WHEN 'Y'
          THEN 100
          ELSE 999
        END
        )
      )
      ;
    -- Summary Nodes first
  END IF;
  -- Inserting
  -- AD_Ref_List update trigger
  --  synchronize name,...
  IF TG_OP = 'UPDATE' THEN
    IF(COALESCE(old.Name, '.') <> COALESCE(NEW.Name, '.')
   OR COALESCE(old.Description, '.') <> COALESCE(NEW.Description, '.')
   OR COALESCE(old.IsActive, '.') <> COALESCE(NEW.IsActive, '.'))
  THEN
      IF(old.IsActive!=new.IsActive) THEN
        --  get AD_Tree_ID + ParentID
        SELECT c.AD_Tree_Menu_ID,
          n.Node_ID
        INTO v_xTree_ID,
          v_xParent_ID
        FROM AD_ClientInfo c,
          AD_TreeNode n
          -- AD_TreeNodeMM n
        WHERE c.AD_Tree_Menu_ID=n.AD_Tree_ID
          AND n.Parent_ID IS NULL
          AND c.AD_Client_ID=new.AD_Client_ID;
        -- Update
        UPDATE AD_TreeNode
          -- AD_TreeNodeMM
          SET IsActive=new.IsActive
        WHERE AD_Tree_ID=v_xTree_ID
          AND Node_ID=new.AD_Menu_ID;
      END IF;
    END IF;
  END IF;
  -- Updating
  IF TG_OP = 'DELETE' THEN
    --  Delete TreeNode
    --  get AD_Tree_ID, AD_Menu_ID
    SELECT c.AD_Tree_Menu_ID
      INTO v_xTree_ID
      FROM AD_ClientInfo c,
        AD_TreeNode n
      WHERE c.AD_Tree_Menu_ID=n.AD_Tree_ID
        AND n.Parent_ID IS NULL
        AND c.AD_Client_ID=old.AD_Client_ID;
    --Assign children to principal node
    UPDATE AD_Treenode
      SET Parent_ID='0'
    WHERE AD_Tree_ID=v_xTree_ID
      AND Parent_ID=old.AD_Menu_ID;
    --Delete node
    DELETE
      FROM AD_Treenode
      WHERE AD_Client_ID=old.AD_Client_ID
        AND AD_Tree_ID=v_xTree_ID
        AND Node_ID=old.AD_Menu_ID;
  END IF;
  -- Deleting
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

EXCEPTION
WHEN DATA_EXCEPTION THEN
  RAISE EXCEPTION '%', 'AD_Menu InsertTrigger Error: No ClientInfo or parent TreeNode' ; --OBTG:-20005--
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.ad_menu_trg() OWNER TO tad;

--
-- Name: ad_form_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_form_trg() RETURNS trigger
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
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * Insert AD_Form Trigger
    *  for Translation
    *  Access
    */
        
    aux NUMERIC;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

   IF TG_OP = 'INSERT'
    THEN
  INSERT
  INTO AD_Form_Trl
    (
      AD_Form_Trl_ID, AD_Form_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      Name, Description, Help,
      IsTranslated
    )
  SELECT get_uuid(), new.AD_Form_ID,
    AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy, new.Name,
    new.Description, new.Help, 'N'
  FROM AD_Language, AD_Module M
  WHERE AD_Language.IsActive='Y'
    AND IsSystemLanguage='Y' AND isonly4format='N'
    and m.ad_module_id = new.ad_module_id
    and m.ad_language != AD_Language.AD_Language;
  -- Access for all
  INSERT
  INTO AD_Form_Access
    (
      AD_Form_Access_ID, AD_Form_ID, AD_Role_ID, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      IsReadWrite
    )
  SELECT get_uuid(), new.AD_Form_ID,
    r.AD_Role_ID,  r.AD_CLIENT_ID, r.AD_ORG_ID,
     'Y', TO_DATE(NOW()), '0',
    TO_DATE(NOW()), '0',  'Y'
  FROM AD_Role r
  where ismanual = 'N';
 END IF;
 -- Inserting
 -- AD_Form update trigger
 --  synchronize name,... with Field if not centrally maintained
 /*
 select count(*)
   into aux
   from ad_module
  where ad_module_id = new.ad_module_id
    and new.classname like javapackage||'.%';
    
  if aux = 0 then
    RAISE EXCEPTION '%', '@JavaClassNotInModulePackage@'; --OBTG:-20000--
  end if;
*/
  -- Deleting
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
 
END; $_$;

--
-- Name: ad_fieldgroup_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_fieldgroup_trg() RETURNS trigger
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
    * Insert AD_Menu Trigger
    *  for Translation
    */
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

   IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO AD_FieldGroup_Trl
    (
      AD_FieldGroup_Trl_ID, AD_FieldGroup_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      Name, IsTranslated
    )
  SELECT get_uuid(), new.AD_FieldGroup_ID,
    AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy, new.Name,
     'N'
  FROM AD_Language, ad_module m
  WHERE AD_Language.IsActive='Y'
    AND IsSystemLanguage='Y' AND isonly4format='N'
     and m.ad_module_id = new.ad_module_id
        and m.ad_language != AD_Language.AD_Language;
 END IF;
 
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


ALTER FUNCTION public.ad_fieldgroup_trg() OWNER TO tad;

--
-- Name: ad_element_trl_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_element_trl_trg() RETURNS trigger
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
* Specifically, this derivative work is based upon the following Compiere
* file and version.
*************************************************************************
* $Id: AD_Element_Trl_Trg.sql,v 1.4 2002/11/08 05:42:01 jjanke Exp $
***
* Title: AD_Element_Trl update trigger
* Description:
*   Synchronize name,... with  Field if centrally maintained
************************************************************************/
    devTemplate numeric;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE m,ad_element me,ad_element_trl met
   WHERE m.ad_module_id=me.ad_module_id and me.ad_element_id=met.ad_element_id and IsInDevelopment = 'Y';
     
    
  if  devTemplate=0 then  
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT' OR TG_OP = 'DELETE') THEN
        RAISE EXCEPTION '%', 'Cannot update an object in a module not in developement and without an active template'; --OBTG:-20532--
    END IF;
  ENd IF;
  
  
  IF TG_OP = 'UPDATE'
  THEN
      -- Field
      UPDATE AD_Field_Trl
         SET NAME = NEW.NAME,
             Description = NEW.Description,
             HELP = NEW.HELP,
             IsTranslated = NEW.IsTranslated
      WHERE  AD_Language = NEW.AD_Language
         AND AD_Field_v_ID IN (
               SELECT F.AD_Field_ID
                 FROM AD_Field F, AD_Column C, AD_Module M
                WHERE F.AD_Column_ID = C.AD_Column_ID
                  AND C.AD_Element_ID = NEW.AD_Element_ID
                  AND F.IsCentrallyMaintained = 'Y'
                  AND M.aD_Module_id = f.ad_module_id
                  and m.AD_Language != new.AD_Language);
                  
      -- Parameter
      UPDATE AD_Process_Para_Trl
         SET NAME = NEW.NAME,
             Description = NEW.Description,
             HELP = NEW.HELP,
             IsTranslated = NEW.IsTranslated
      WHERE  AD_Language = NEW.AD_Language
         AND AD_Process_Para_ID IN (
               SELECT f.AD_Process_Para_ID
                 FROM AD_Process_Para f, AD_Process p, ad_module m
               WHERE  f.AD_Element_ID = NEW.AD_Element_ID
                  AND f.IsCentrallyMaintained = 'Y'
                  and p.ad_process_id = f.ad_process_id
                  and m.ad_module_id = p.ad_module_id
                  and m.ad_language != NEW.AD_Language);
                 
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


ALTER FUNCTION public.ad_element_trl_trg() OWNER TO tad;










--
-- Name: ad_field_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_field_trg() RETURNS trigger
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
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * Insert AD_Field Trigger
    *  for Translation
    */
        
    v_temp character varying;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  IF TG_OP = 'INSERT'  THEN
          INSERT
          INTO AD_Field_Trl
            (
              AD_Field_Trl_ID, AD_Field_v_ID, AD_Language, AD_Client_ID,
              AD_Org_ID, IsActive, Created,
              CreatedBy, Updated, UpdatedBy,
              Name, Description, Help,
              IsTranslated
            )
          SELECT get_uuid(), new.AD_Field_ID,
            AD_Language.AD_Language, new.AD_Client_ID, new.AD_Org_ID,
            new.IsActive, new.Created, new.CreatedBy,
            new.Updated, new.UpdatedBy, new.Name,
            new.Description, new.Help, 'N'
          FROM AD_Language, ad_module m
          WHERE AD_Language.IsActive='Y'
            AND IsSystemLanguage='Y' AND isonly4format='N'
            and m.ad_module_id = new.ad_module_id
            and m.ad_language != AD_Language.AD_Language;
 END IF;
 
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


ALTER FUNCTION public.ad_field_trg() OWNER TO tad;



--
-- Name: ad_process_para_trg(); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION ad_process_para_trg() RETURNS trigger
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
* $Id: AD_Process_Para_Trg.sql,v 1.3 2002/10/21 04:49:47 jjanke Exp $
***
* Title: Parameter Trigger
* Description:
*   Translation
************************************************************************/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Insert AD_Process_Para Trigger
  --  for Translation
  IF (TG_OP = 'INSERT')
  THEN
    --  Create Translation Row
    INSERT INTO AD_Process_Para_Trl
                (AD_Process_Para_Trl_ID, AD_Process_Para_ID, AD_Language, AD_Client_ID, AD_Org_ID,
                 IsActive, Created, CreatedBy, Updated, UpdatedBy, NAME,
                 Description, HELP, IsTranslated)
      SELECT get_uuid(), NEW.AD_Process_Para_ID, AD_Language.AD_Language, NEW.AD_Client_ID,
             NEW.AD_Org_ID, NEW.IsActive, NEW.Created, NEW.CreatedBy,
             NEW.Updated, NEW.UpdatedBy, NEW.NAME, NEW.Description,
             NEW.HELP, 'N'
        FROM AD_Language, ad_module m, ad_process p
       WHERE AD_Language.IsActive = 'Y' AND IsSystemLanguage = 'Y' AND isonly4format='N'
       AND M.AD_Module_ID = p.AD_Module_ID
       and p.ad_process_id = new.ad_process_id
    AND M.AD_Language != AD_Language.AD_Language;
  END IF;


IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


ALTER FUNCTION public.ad_process_para_trg() OWNER TO tad;







CREATE OR REPLACE FUNCTION ad_synchronize(p_pinstance_id character varying) RETURNS void
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
  * $Id: AD_Syncronize.sql,v 1.12 2003/07/26 04:29:44 jjanke Exp $
  ***
  * Title: Syncronize Application Dictionary
  * Description:
  *  Synchronize Elements
  *  Update Column and Field with Names from Element and Process
  *  Update Process Parameters from Elements
  *  Update Workflow Notes from Windows
  *  Update Menu from Window/Form/Process/Task
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):='Success'; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    v_rowcount NUMERIC;
   NextNo VARCHAR(32); --OBTG:varchar2--
      Cur_Column RECORD;
      Cur_Process RECORD;
  BEGIN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
     
      RAISE NOTICE '%','Adding missing Elements' ;
  

      FOR Cur_Column IN
              (SELECT DISTINCT C.ColumnName, C.NAME, C.Description, C.Help, C.AD_Module_ID
              FROM AD_COLUMN c, ad_module m
              WHERE AD_Element_ID IS NULL  
                AND C.AD_MODULE_ID = M.AD_MODULE_ID
                AND m.isindevelopment = 'Y'
                AND NOT EXISTS
                (SELECT 1 FROM AD_ELEMENT e  
                  WHERE UPPER(c.ColumnName)=UPPER(e.ColumnName))
              )
      LOOP
              SELECT * INTO  NextNo FROM Ad_Sequence_Next('AD_Element', '0') ; -- get ID
              INSERT
              INTO AD_ELEMENT
                (
                  AD_ELEMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
                  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                  ColumnName, NAME, PrintName, Description,
                  Help, AD_Module_ID
                )
                VALUES
                (NextNo, '0', '0', 'Y',
                TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
                Cur_Column.ColumnName, Cur_Column.NAME, Cur_Column.NAME, Cur_Column.Description,
                Cur_Column.Help, Cur_Column.AD_Module_ID) ;
              RAISE NOTICE '%','  added ' || Cur_Column.ColumnName ;
              -- COMMIT;
      END LOOP;
      RAISE NOTICE '%','Adding missing Elements on Processes..' ;
      FOR Cur_Process IN
                (SELECT DISTINCT p.ColumnName, p.NAME, p.Description, p.Help, pr.AD_Module_ID
              FROM AD_PROCESS_PARA p, AD_PROCESS pr, AD_MODULE M
              WHERE AD_Element_ID IS NULL  
                AND pr.AD_Process_ID = p.AD_Process_ID
                AND M.AD_MODULE_ID = PR.AD_MODULE_ID
                AND M.ISINDEVELOPMENT = 'Y'
                AND NOT EXISTS
                (SELECT 1 FROM AD_ELEMENT e  
                  WHERE UPPER(p.ColumnName)=UPPER(e.ColumnName))
                )
      LOOP
              INSERT
              INTO AD_ELEMENT
                (
                  AD_ELEMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
                  CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                  ColumnName, NAME, PrintName, Description,
                  Help, AD_Module_ID
                )
                VALUES
                (get_uuid(), '0', '0', 'Y',
                TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
                Cur_Process.ColumnName, Cur_Process.NAME, Cur_Process.NAME, Cur_Process.Description,
                Cur_Process.Help, Cur_Process.AD_Module_ID) ;
              RAISE NOTICE '%','  added ' || Cur_Process.ColumnName ;
              -- COMMIT;
      END LOOP;
    RAISE NOTICE '%','Creating link from Columns to Elements' ;
    --Updates ad_column: element id and name (name is only updated first time)
    --Name is updated with the value in the element regardless the language
    UPDATE AD_COLUMN c
           SET AD_Element_id=(SELECT MAX(AD_Element_ID)
                           FROM AD_ELEMENT e 
                          WHERE UPPER(c.ColumnName)=UPPER(e.ColumnName))
    WHERE AD_Element_ID IS NULL 
      AND EXISTS (SELECT 1 
                    FROM AD_MODULE M
                    WHERE (M.AD_MODULE_ID = C.AD_MODULE_ID
                          AND M.ISINDEVELOPMENT='Y'));
     GET DIAGNOSTICS v_rowcount:=ROW_COUNT;
     RAISE NOTICE '%','Column  rows updated: ' || v_rowcount ;
    --Updates ad_ref_gridcolumn: element id and name (name is only updated first time)
    --Name is updated with the value in the element regardless the language
    UPDATE AD_REF_GRIDCOLUMN c
           SET AD_Element_id=(SELECT MAX(AD_Element_ID)
                           FROM AD_ELEMENT e 
                          WHERE UPPER(c.Name)=UPPER(e.ColumnName))
    WHERE AD_Element_ID IS NULL and exists
    (select 0 FROM AD_ELEMENT e 
                          WHERE UPPER(c.Name)=UPPER(e.ColumnName));
    GET DIAGNOSTICS v_rowcount:=ROW_COUNT;
    RAISE NOTICE '%','Grid Column  rows updated: ' || v_rowcount ;
    --Updates ad_column: element id and name (name is only updated first time)
    --Name is updated with the value in the element regardless the language
    UPDATE ad_ref_fieldcolumn c
           SET AD_Element_id=(SELECT MAX(AD_Element_ID)
                           FROM AD_ELEMENT e 
                          WHERE UPPER(c.Name)=UPPER(e.ColumnName))
    WHERE AD_Element_ID IS NULL and exists
    (select 0 FROM AD_ELEMENT e 
                          WHERE UPPER(c.Name)=UPPER(e.ColumnName));
    
    GET DIAGNOSTICS v_rowcount:=ROW_COUNT;
    RAISE NOTICE '%','Fieldgroup Column  rows updated: ' || v_rowcount ;
    RAISE NOTICE '%','Creating link from Element to Process Para' ;
    UPDATE AD_PROCESS_PARA
          SET AD_Element_id=
          (SELECT MAX(AD_Element_ID)
          FROM AD_ELEMENT e, AD_PROCESS P
          WHERE UPPER(AD_PROCESS_PARA.ColumnName)=UPPER(e.ColumnName)
          AND P.AD_PROCESS_ID = AD_PROCESS_PARA.AD_PROCESS_ID
          )
    WHERE AD_Element_ID IS NULL
     AND EXISTS (SELECT 1 
                   FROM AD_PROCESS P, AD_MODULE M
                  WHERE (P.AD_PROCESS_ID = AD_PROCESS_PARA.AD_PROCESS_ID
                    AND P.AD_MODULE_ID = M.AD_MODULE_ID
                    AND M.ISINDEVELOPMENT = 'Y'));
    GET DIAGNOSTICS v_rowcount:=ROW_COUNT;
    RAISE NOTICE '%','Process  rows updated: ' || v_rowcount ;
    --  Rebuild Translation Items 
    --  Rebuild Translation Items COMPLETE - Only if running manually 
    --if p_PInstance_ID is null then
          RAISE NOTICE '%','Deleting unused Elements' ;
          /*
          DELETE FROM AD_ELEMENT_TRL
          WHERE AD_Element_ID IN
                  (SELECT AD_Element_ID
                  FROM AD_ELEMENT e, AD_MODULE M
                  WHERE M.AD_MODULE_ID = E.AD_MODULE_ID
                    AND m.isindevelopment = 'Y'
                  AND NOT EXISTS
                    (SELECT 1
                    FROM AD_COLUMN c
                    WHERE UPPER(e.ColumnName)=UPPER(c.ColumnName) OR e.AD_Element_ID=c.AD_Element_ID
                    )
                    AND NOT EXISTS
                    (SELECT 1
                    FROM AD_PROCESS_PARA p
                    WHERE UPPER(e.ColumnName)=UPPER(p.ColumnName) OR e.AD_Element_ID=p.AD_Element_ID
                    )
                  );
          */
          DELETE FROM AD_ELEMENT
          WHERE NOT EXISTS
            (SELECT 1
            FROM AD_COLUMN c
            WHERE AD_ELEMENT.AD_Element_ID=c.AD_Element_ID
            )
            AND NOT EXISTS
            (SELECT 1
            FROM AD_PROCESS_PARA p
            WHERE AD_ELEMENT.AD_Element_ID=p.AD_Element_ID
            )
            AND NOT EXISTS
            (SELECT 1
            FROM ad_ref_fieldcolumn p
            WHERE AD_ELEMENT.AD_Element_ID=p.AD_Element_ID
            )
            AND NOT EXISTS
            (SELECT 1
            FROM ad_ref_gridcolumn p
            WHERE AD_ELEMENT.AD_Element_ID=p.AD_Element_ID
            )
            AND EXISTS (SELECT 1 FROM AD_MODULE WHERE AD_MODULE_ID = AD_ELEMENT.AD_MODULE_ID AND ISINDEVELOPMENT ='Y') 
            AND donotdelete='N';
          GET DIAGNOSTICS v_rowcount:=ROW_COUNT;
          RAISE NOTICE '%','  rows deleted: ' || v_rowcount ;
          
          -- COMMIT;
          ---------------------------------------------------------------------------
          -- Columns
          RAISE NOTICE '%','Synchronize Central Maintained Fields' ;
          
          UPDATE AD_Field
            SET NAME = e.NAME,
                Description = e.Description,
                HELP = e.HELP from (select el.NAME, el.Description,el.HELP,c.ad_column_id from ad_element el,ad_column c where c.ad_element_id=el.ad_element_id) e 
                where AD_Field.IsCentrallyMaintained = 'Y' and AD_Field.ad_column_id=e.ad_column_id
                and AD_Field.ad_module_id in (select ad_module_id from ad_module where isindevelopment='Y');
                
          UPDATE AD_Process_Para
           SET NAME = e.NAME,
             Description = e.Description,
             HELP = e.HELP from (select el.NAME, el.Description,el.HELP,el.ad_element_id from ad_element el) e 
                where AD_Process_Para.IsCentrallyMaintained = 'Y' and AD_Process_Para.ad_process_id in 
                (select ad_process_id from ad_process where ad_module_id in (select ad_module_id from ad_module where isindevelopment='Y'))
                and e.ad_element_id=AD_Process_Para.ad_element_id;
                
          --update ad_element set updated=updated;
          RAISE NOTICE '%','Elements updated..' ;
          --update ad_element_trl set updated=updated;
          alter table ad_field_trl disable trigger ad_field_trl_mod_trg;
          UPDATE AD_Field_Trl
          SET NAME = e.NAME,
             Description = e.Description,
             HELP = e.HELP,
             IsTranslated = e.IsTranslated from (select e.NAME ,e.Description, e.HELP, e.IsTranslated,e.ad_language,f.ad_field_id
                                                 from ad_element_trl e,ad_element el,ad_column c ,ad_field f 
                                                 where  c.ad_element_id=el.ad_element_id and e.ad_element_id=el.ad_element_id
                                                 and f.ad_column_id=c.ad_column_id and f.IsCentrallyMaintained = 'Y' and
                                                 f.ad_module_id in (select ad_module_id from ad_module where isindevelopment='Y')) e
             where AD_Field_Trl.AD_Field_v_ID=e.ad_field_id and AD_Field_Trl.AD_Language=e.ad_language;
          alter table ad_field_trl enable trigger ad_field_trl_mod_trg;   
          --
          UPDATE AD_Process_Para_trl
           SET NAME = e.NAME,
             Description = e.Description,
             HELP = e.HELP  ,IsTranslated = e.IsTranslated from 
                  (select e.NAME, e.Description,e.HELP,e.ad_language,e.istranslated,p.ad_process_para_id from ad_element_trl e,ad_element em,AD_Process_Para p
                          where em.ad_element_id=e.ad_element_id and p.IsCentrallyMaintained = 'Y' and p.ad_element_id=em.ad_element_id and p.ad_process_id in
                          (select ad_process_id from ad_process where ad_module_id in (select ad_module_id from ad_module where isindevelopment='Y'))) e 
             where e.ad_process_para_id=AD_Process_Para_trl.ad_process_para_id and e.ad_language=AD_Process_Para_trl.ad_language;
                  
          RAISE NOTICE '%','Elements Translations updated..' ;
          PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_ResultStr);
    --END IF;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  -- ROLLBACK;
  IF(p_PInstance_ID IS NOT NULL) THEN
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  END IF;
  RETURN;
END ; $_$;





CREATE or replace FUNCTION ad_update_customtranslation() RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Localozation in Database - The better way
*****************************************************/
DECLARE
  v_cur RECORD;
BEGIN
  for v_cur in (select * from ad_customtranslation)
  LOOP
        if v_cur.ad_field_id is not null then
              update  ad_field_trl set name= v_cur.name , description=v_cur.description where ad_field_v_id=v_cur.ad_field_id and ad_language=v_cur.ad_language;
        end if;
        if v_cur.ad_window_id is not null then
              update  ad_window_trl set name= v_cur.name , description=v_cur.description where ad_window_id=v_cur.ad_window_id and ad_language=v_cur.ad_language;
        end if;
        if v_cur.ad_tab_id is not null then
              update  ad_tab_trl set name= v_cur.name , description=v_cur.description where ad_tab_id=v_cur.ad_tab_id and ad_language=v_cur.ad_language;
        end if;
        if v_cur.ad_reference_id is not null then
              update  ad_reference_trl set name= v_cur.name , description=v_cur.description where ad_reference_id=v_cur.ad_reference_id and ad_language=v_cur.ad_language;
        end if;        
        if v_cur.ad_ref_list_id is not null then
              update  ad_ref_list_trl set name= v_cur.name , description=v_cur.description where ad_ref_list_id=v_cur.ad_ref_list_id and ad_language=v_cur.ad_language;
        end if;    
        if v_cur.ad_process_para_id is not null then
              update  ad_process_para_trl set name= v_cur.name , description=v_cur.description where ad_process_para_id=v_cur.ad_process_para_id and ad_language=v_cur.ad_language;
        end if;    
        if v_cur.ad_message_id is not null then
              update  ad_message_trl set name= v_cur.name , description=v_cur.description where ad_message_id=v_cur.ad_message_id and ad_language=v_cur.ad_language;
        end if; 
        if v_cur.ad_menu_id is not null then
              update  ad_menu_trl set name= v_cur.name , description=v_cur.description where ad_menu_id=v_cur.ad_menu_id and ad_language=v_cur.ad_language;
        end if; 
        if v_cur.ad_form_id is not null then
              update  ad_form_trl set name= v_cur.name , description=v_cur.description where ad_form_id=v_cur.ad_form_id and ad_language=v_cur.ad_language;
        end if; 
        if v_cur.ad_fieldgroup_id  is not null then
              update  ad_fieldgroup_trl set name= v_cur.name , description=v_cur.description where ad_fieldgroup_id =v_cur.ad_fieldgroup_id  and ad_language=v_cur.ad_language;
        end if; 
        if v_cur.ad_alertrule_id  is not null then
              update  ad_alertrule_trl set name= v_cur.name , description=v_cur.description where ad_alertrule_id =v_cur.ad_alertrule_id  and ad_language=v_cur.ad_language;
        end if; 
  ENd LOOP;
RETURN 'Cutom Translations Updated ..........';

END; $_$  LANGUAGE 'plpgsql' VOLATILE  COST 100;

SELECT zsse_droptrigger('ad_ref_listinstance_trg', 'ad_ref_listinstance');
CREATE OR REPLACE FUNCTION ad_ref_listinstance_trg () RETURNS trigger 
AS $body$
BEGIN

  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  -- Insert AD_Ref_List Trigger
  --  for Translation
  IF TG_OP = 'INSERT'
  THEN
    --  Create Translation Row for each IsSystemLanguage='Y'
    INSERT INTO ad_ref_listinstance_trl (
      ad_ref_listinstance_trl_id, ad_ref_listinstance_id, ad_language,
      ad_client_id, ad_org_id,
      isactive, created, createdby, updated, updatedby,
      name
      )
    SELECT
      get_uuid(), new.ad_ref_listinstance_id, adl.ad_language,
      new.ad_client_id, new.ad_org_id,
      new.isactive, new.created, new.createdby, new.updated, new.updatedby,
      new.name 
    FROM ad_language adl, ad_ref_list rl,  ad_module m, ad_ref_listinstance rli
    WHERE 1=1
      AND adl.IsActive='Y'
      AND adl.IsSystemLanguage='Y' AND adl.isonly4format='N'
      AND adl.ad_language <> m.ad_language
      AND m.ad_module_id = rl.ad_module_id
      AND rl.ad_reference_id = new.ad_reference_id
      AND rl.ad_ref_list_id = new.ad_ref_list_id
      AND rli.ad_ref_listinstance_id = new.ad_ref_listinstance_id;
  END IF;

  -- Deleteting
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;

END;
$body$
LANGUAGE 'plpgsql';

CREATE TRIGGER ad_ref_listinstance_trg
  AFTER INSERT OR UPDATE
  ON public.ad_ref_listinstance FOR EACH ROW
  EXECUTE PROCEDURE public.ad_ref_listinstance_trg();
  
  
  
  
  
SELECT zsse_droptrigger('ad_field_trl_trg', 'ad_field_trl');
CREATE OR REPLACE FUNCTION ad_field_trl_trg() RETURNS trigger 
AS $body$
BEGIN

  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  -- Insert AD_Ref_List Trigger
  --  for Translation
  IF TG_OP = 'INSERT'
  THEN
   new.ad_field_id=new.ad_field_v_id;
  END IF;
  -- Deleteting
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;

END;
$body$
LANGUAGE 'plpgsql';

CREATE TRIGGER ad_field_trl_trg
  BEFORE INSERT
  ON ad_field_trl FOR EACH ROW
  EXECUTE PROCEDURE ad_field_trl_trg();

CREATE OR REPLACE FUNCTION c_country_trg() RETURNS trigger
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
* Contributor(s): , Stefan Zimmermann (2016)
************************************************************************/

BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO C_COUNTRY_Trl
    (
      C_COUNTRY_Trl_ID, C_COUNTRY_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      IsTranslated, Name, Description,
      RegionName, DisplaySequence
    )
  SELECT get_uuid(), new.C_COUNTRY_ID,
    AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy,
    'N', new.Name, new.Description,
    new.RegionName, new.DisplaySequence
  FROM AD_Language
  WHERE IsActive='Y'
    AND IsSystemLanguage='Y'  AND isonly4format='N';
 END IF;
 -- Inserting
 IF TG_OP = 'UPDATE' THEN
  IF(COALESCE(old.Name, '.') <> COALESCE(NEW.Name, '.')
  OR COALESCE(old.Description, '.') <> COALESCE(NEW.Description, '.')
  OR COALESCE(old.RegionName,'.') <> COALESCE(new.RegionName,'.')
  OR COALESCE(old.DisplaySequence,'.') <> COALESCE(new.DisplaySequence,'.')  )
 THEN
    -- Translation
    UPDATE C_COUNTRY_Trl
      SET IsTranslated='N',
      Updated=TO_DATE(NOW())
    WHERE C_COUNTRY_ID=new.C_COUNTRY_ID;
  END IF;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END;  $_$;

CREATE OR REPLACE FUNCTION c_currency_trg() RETURNS trigger
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
* Contributor(s):  Stefan Zimmermann (2016)
************************************************************************/
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO C_CURRENCY_Trl
    (
      C_CURRENCY_Trl_ID, C_CURRENCY_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      IsTranslated, CurSymbol, Description
    )
  SELECT get_uuid(), new.C_CURRENCY_ID,
    AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy,
    'N', new.CurSymbol, new.Description
  FROM AD_Language
  WHERE IsActive='Y'
    AND IsSystemLanguage='Y'  AND isonly4format='N';
 END IF;
 -- Inserting
 IF TG_OP = 'UPDATE' THEN
  IF(COALESCE(old.CurSymbol, '.') <> COALESCE(NEW.CurSymbol, '.')
  OR COALESCE(old.Description, '.') <> COALESCE(NEW.Description, '.'))
 THEN
    -- Translation
    UPDATE C_CURRENCY_Trl
      SET IsTranslated='N',
      Updated=TO_DATE(NOW())
    WHERE C_CURRENCY_ID=new.C_CURRENCY_ID;
  END IF;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;


CREATE OR REPLACE FUNCTION c_doctype_trg() RETURNS trigger
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
    * Contributor(s): Openbravo SL, Stefan Zimmermann (2016)
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
    * Contributions are Copyright (C) 2016 Stefan Zimmermann
    *
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    */
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- Insert C_DocType Trigger
    --  for Translation
    IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO C_DocType_Trl
    (
      C_DocType_Trl_ID, C_DocType_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      Name, PrintName, DocumentNote,
      IsTranslated
    )
  SELECT get_uuid(), new.C_DocType_ID,
    AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy, new.Name,
    new.PrintName, new.DocumentNote, 'N'
  FROM AD_Language
  WHERE IsActive='Y'
    AND IsSystemLanguage='Y'  AND isonly4format='N';
 END IF;
 -- Inserting
 -- C_DocType update trigger
 --  synchronize name,...
 IF TG_OP = 'UPDATE' THEN
  IF(COALESCE(old.PrintName, '.') <> COALESCE(NEW.PrintName, '.')
  OR COALESCE(old.Name, '.') <> COALESCE(NEW.Name, '.')
  OR COALESCE(old.DocumentNote, '.') <> COALESCE(NEW.DocumentNote, '.'))
 THEN
    UPDATE C_DocType_Trl
      SET IsTranslated='N',
      Name=new.Name,
      PrintName=new.PrintName,
      DocumentNote=new.DocumentNote,
      Updated=TO_DATE(NOW())
    WHERE C_DocType_ID=new.C_DocType_ID;
  END IF;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

CREATE OR REPLACE FUNCTION c_greeting_trg() RETURNS trigger
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
* Contributor(s): Openbravo SL, Stefan Zimmermann(2016)
* Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
*Contributions are Copyright (C) 2016 Stefan Zimmermann
* Specifically, this derivative work is based upon the following Compiere
* file and version.
*************************************************************************
* Insert Translation
*/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF TG_OP = 'INSERT'
  THEN
    --  Create Translation Row
    INSERT INTO C_GREETING_TRL
                (C_GREETING_TRL_ID, C_GREETING_ID, AD_LANGUAGE, AD_CLIENT_ID, AD_ORG_ID,
                 ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, NAME,
                 ISTRANSLATED)
      SELECT get_uuid(), NEW.C_GREETING_ID, AD_LANGUAGE, NEW.AD_CLIENT_ID,
             NEW.AD_ORG_ID, NEW.ISACTIVE, NEW.CREATED, NEW.CREATEDBY,
             NEW.UPDATED, NEW.UPDATEDBY, NEW.NAME, 'N'
        FROM AD_LANGUAGE
       WHERE ISACTIVE = 'Y' AND ISSYSTEMLANGUAGE = 'Y'  AND isonly4format='N';
  END IF;

  -- Inserting
  IF TG_OP = 'UPDATE'
  THEN
    IF COALESCE (OLD.NAME, '.') <> COALESCE (NEW.NAME, '.')
    THEN
      -- Translation
      UPDATE C_GREETING_TRL
         SET ISTRANSLATED = 'N',
             UPDATED = TO_DATE(NOW())
       WHERE C_GREETING_ID = NEW.C_GREETING_ID;
    END IF;
  END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


CREATE OR REPLACE FUNCTION c_paymentterm_trg() RETURNS trigger
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
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L., Stefan Zimmermann(2016)
    *Contributions are Copyright (C) 2016 Stefan Zimmermann
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    */
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    -- Insert C_PaymentTerm Trigger
    --  for Translation
    IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO C_PaymentTerm_Trl
    (
      C_PaymentTerm_Trl_ID, C_PaymentTerm_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      Name, Description, DocumentNote,
      IsTranslated
    )
  SELECT get_uuid(), new.C_PaymentTerm_ID,
    AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy, new.Name,
    new.Description, new.DocumentNote, 'N'
  FROM AD_Language
  WHERE IsActive='Y'
    AND IsSystemLanguage='Y'  AND isonly4format='N';
 END IF;
 -- Inserting
 -- C_PaymentTerm update trigger
 --  synchronize name,...
 IF(TG_OP = 'UPDATE') THEN
  IF((COALESCE(old.DocumentNote, '.') <> COALESCE(NEW.DocumentNote, '.')
  OR COALESCE(old.Name, '.') <> COALESCE(NEW.Name, '.')
  OR COALESCE(old.Description, '.') <> COALESCE(NEW.Description, '.')))
 THEN
    UPDATE C_PaymentTerm_Trl
      SET IsTranslated='N',
      Updated=TO_DATE(NOW())
    WHERE C_PaymentTerm_ID=new.C_PaymentTerm_ID;
  END IF;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

CREATE OR REPLACE FUNCTION c_uom_trg() RETURNS trigger
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
    * Contributor(s): Openbravo SL, Stefan Zimmermann(2016)
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
    * Contributions are Copyright (C) 2016 Stefan Zimmermann
    *
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * $Id: C_UOM_Trg.sql,v 1.2 2002/09/13 06:03:44 jjanke Exp $
    ***
    * Title: UOM Translation
    * Description:
    ************************************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    IF TG_OP = 'INSERT'
    THEN
    --  Create Translation Row
  INSERT
  INTO C_UOM_Trl
    (
      C_UOM_Trl_ID, C_UOM_ID, AD_Language, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy,
      UOMSymbol, Name, Description,
      IsTranslated
    )
  SELECT get_uuid(), new.C_UOM_ID,
    AD_Language, new.AD_Client_ID, new.AD_Org_ID,
    new.IsActive, new.Created, new.CreatedBy,
    new.Updated, new.UpdatedBy, new.UOMSymbol,
    new.Name, new.Description,  'N'
  FROM AD_Language
  WHERE IsActive='Y'
    AND IsSystemLanguage='Y'  AND isonly4format='N';
 END IF;
 -- Inserting
 IF(TG_OP = 'UPDATE') THEN
  IF((COALESCE(old.UOMSymbol, '...') <> COALESCE(NEW.UOMSymbol, '...'))
  OR(COALESCE(old.Name, '.') <> COALESCE(NEW.Name, '.'))
  OR(COALESCE(old.Description, '.') <> COALESCE(NEW.Description, '.')))
 THEN
    -- Translation
    UPDATE C_UOM_Trl
      SET IsTranslated='N',
      Updated=TO_DATE(NOW())
    WHERE C_UOM_ID=new.C_UOM_ID;
  END IF;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;