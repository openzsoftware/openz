CREATE or replace FUNCTION zswf_isPOProjectworkflow(p_invoice_Id character varying, p_user_id character varying) RETURNS character varying
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
**************************************************************************************************************************************************

Implements Purchasing Workflow on Projects

Rules: Only applies If Invoice has a Project.
       Only one Priject per Invoice
       Approval-Amt < Invoice Amt
       User is not the Project Manager*/
-- Simple Types
v_count integer; 
v_project character varying;
v_iswf character varying;
v_rep character varying;
v_isso  character varying;
v_org character varying;
v_amt numeric;
v_appamt numeric;

BEGIN 
    
    select totallines,ad_org_id,issotrx into v_amt,v_org,v_isso from c_invoice where c_invoice_id=p_invoice_Id;
    select count(distinct coalesce(c_project_id,'NULL')) into v_count from c_invoiceline  where c_invoice_id=p_invoice_Id;
    select defaultpoapprovalamt,poprojectworkflow into v_appamt,v_iswf from c_orgconfiguration where isactive='Y' and ad_org_id=v_org;
    if v_iswf is null then
            select defaultpoapprovalamt,poprojectworkflow into v_appamt,v_iswf from c_orgconfiguration where  isactive='Y' and isstandard='Y';
        end if;
    -- No workflow?
    if coalesce(v_iswf,'N')='N' or coalesce(v_appamt,9999999999)>v_amt or v_isso='Y' then
       return 'N';
    end if;
    -- If Wokflow, unique Project must match
    if v_count>1  then
        RAISE EXCEPTION '%', '@POProjectworkflowONEProject@' ;
    end if;
    select distinct c_project_id into v_project from c_invoiceline  where c_invoice_id=p_invoice_Id;
    if v_project is null then 
         return 'N';
    end if;
    select responsible_id into v_rep  from c_project where c_project_id=v_project;
    if v_rep=p_user_id then
         return 'N';
    else
         return 'Y';
    end if;
    
END;
$_$  LANGUAGE 'plpgsql'; 

CREATE or replace FUNCTION zswf_hasApproverRights(p_invoice_Id character varying, p_user_id character varying) RETURNS character varying
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
*/
-- Simple Types
v_count integer; 
v_project character varying;
v_isprove character varying;
v_rep character varying;

v_org character varying;
v_amt numeric;
v_appamt numeric;

BEGIN 
    
    select totallines,ad_org_id into v_amt,v_org from c_invoice where c_invoice_id=p_invoice_Id;

    select approvalamt,isapprover into v_appamt,v_isprove from c_bpartner,ad_user where c_bpartner.isemployee='Y' and c_bpartner.isactive='Y' and ad_user.isactive='Y' and ad_user.c_bpartner_id=c_bpartner.c_bpartner_id
           and ad_user.ad_user_id=p_user_id;
    -- General Approver
    if v_appamt>v_amt and v_isprove='Y' then
         return 'Y';
    else
    -- Project Approver
        select count(distinct coalesce(c_project_id,'NULL')) into v_count from c_invoiceline  where c_invoice_id=p_invoice_Id;
        if v_count>1  then
             RAISE EXCEPTION '%', '@POProjectworkflowONEProject@' ;
        end if;
        select distinct c_project_id into v_project from c_invoiceline  where c_invoice_id=p_invoice_Id;
        select responsible_id into v_rep  from c_project where c_project_id=v_project;
        -- Is the Project Manager  
        if v_rep=p_user_id then
            return 'Y';
        else
            return 'N';
        end if;
    end if;  
END;
$_$  LANGUAGE 'plpgsql'; 



CREATE OR REPLACE FUNCTION c_gobnodelteindocuments_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
v_processed character varying;
v_return character varying;
BEGIN

   IF TG_OP = 'DELETE' and c_getconfigoption('gobnodelteindocuments',old.ad_org_id)='Y' THEN 
        raise exception '%','@NoDeletePossibleHere@';
   END IF;
   IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;

  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  select zsse_droptrigger('c_gobnodelteindocuments_trg','m_inout'); 
  
  CREATE TRIGGER c_gobnodelteindocuments_trg
  BEFORE  DELETE
  ON m_inout
  FOR EACH ROW
  EXECUTE PROCEDURE c_gobnodelteindocuments_trg();
  
   select zsse_droptrigger('c_gobnodelteindocuments_trg','c_invoice'); 
  
  CREATE TRIGGER c_gobnodelteindocuments_trg
  BEFORE  DELETE
  ON c_invoice
  FOR EACH ROW
  EXECUTE PROCEDURE c_gobnodelteindocuments_trg();
  
     select zsse_droptrigger('c_gobnodelteindocuments_trg','c_order'); 
  
  CREATE TRIGGER c_gobnodelteindocuments_trg
  BEFORE  DELETE
  ON c_order
  FOR EACH ROW
  EXECUTE PROCEDURE c_gobnodelteindocuments_trg();
  
  

