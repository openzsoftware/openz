CREATE OR REPLACE FUNCTION m_requisition_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/*************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): 2012.01.13 MaHinrichs : new field "totallines"
************************************************************************/
  v_DocStatus VARCHAR(60);
   v_n NUMERIC;  
BEGIN
-- BEFORE INSERT OR UPDATE OR DELETE 
  -- Check Duplicate Document Numbers
  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
       select count(*) into v_n from m_requisition where documentno=new.documentno and m_requisition_id!=new.m_requisition_id;
       if v_n>0 then
          RAISE EXCEPTION '%', '@DuplicateDocNo@' ;
       end if;
  END IF;
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_DocStatus := new.DocStatus;
  ELSE
    v_DocStatus := old.DocStatus;
  END IF;

  IF v_DocStatus = 'CO' AND NOT TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION '%', 'Document processed/posted'; --OBTG:-20501--
  END IF;

  IF (v_DocStatus in ( 'CO','CL') AND TG_OP = 'UPDATE') THEN
    IF ((COALESCE(old.DocumentNo, '.') <> COALESCE(new.DocumentNo,'.'))
       OR (COALESCE(old.C_BPartner_ID, '0') <> COALESCE(new.C_BPartner_ID, '0'))
       OR (COALESCE(old.M_PriceList_ID, '0') <> COALESCE(new.M_PriceList_ID, '0'))
       OR (COALESCE(old.C_Currency_ID, '0') <> COALESCE(new.C_Currency_ID, '0'))
       OR (COALESCE(old.AD_User_ID, '0') <> COALESCE(new.AD_User_ID, '0'))) THEN
      RAISE EXCEPTION '%', 'Document processed/posted'; --OBTG:-20501--
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; 
$_$;

CREATE OR REPLACE FUNCTION m_requisition_post(p_pinstance_id character varying)
  RETURNS void AS
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
 Contributions: Universal Use-Pinstance as RecordID when not found
******************************************************************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_User VARCHAR(32):='0'; --OBTG:VARCHAR2--
  v_DocAction VARCHAR(60); --OBTG:VARCHAR2--
  v_DocStatus VARCHAR(60); --OBTG:VARCHAR2--
  v_Aux NUMERIC;
  v_appramt NUMERIC;
  v_isworkflow character varying;
  v_org character varying;
  v_amt  NUMERIC;

  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    Cur_RequisitionLine RECORD;
BEGIN
  --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;

    --BEGIN PRocessing

    SELECT DocAction, DocStatus,ad_org_id INTO v_DocAction, v_DocStatus,v_org
    FROM M_REQUISITION
    WHERE M_REquisition_ID = v_Record_ID;

    v_ResultStr := 'M_Requisition ' || v_Record_ID || ', DocAction=' || v_DocAction || ', DocStatus=' || v_DocStatus;
    RAISE NOTICE '%',v_ResultStr;
    /**
    * Check if requisition has lines
    */
    IF (v_DocAction = 'CO') THEN
      SELECT COUNT(*)
        INTO v_Aux
      FROM M_RequisitionLine
      WHERE M_REQUISITION_ID = v_Record_ID;
      IF v_Aux=0 THEN
        RAISE EXCEPTION '%', '@RequisitionWithoutLines@'; --OBTG:-20000--
      END IF;
    END IF;

    /**
    * Order Closed, Voided or Reversed - No action possible
    */
    IF(v_DocStatus IN('CL', 'VO', 'RE')) THEN
      RAISE EXCEPTION '%', '@AlreadyPosted@' ; --OBTG:-20000--
    ELSIF (v_DocStatus = 'DR') THEN
      IF (v_DocAction = 'CO') THEN
        v_ResultStr := 'Complete the requisition: ' || v_Record_ID;
        -- Check if Requisition Workflow is active and if amt of req is under approval min. amt
        select defaultprapprovalamt,prapprovalworkflow into v_appramt,v_isworkflow from c_orgconfiguration where ad_org_id=v_org;
        if v_isworkflow is null then
            select defaultprapprovalamt,prapprovalworkflow into v_appramt,v_isworkflow from c_orgconfiguration where isstandard='Y';
        end if;
        select sum(linenetamt) into v_amt from m_requisitionline where m_requisition_id=v_Record_ID;
        select count(*) into v_aux  from m_requisitionline where m_requisition_id=v_Record_Id and linenetamt is null;
        if (coalesce(v_amt,99999999999) < coalesce(v_appramt,0)) and coalesce(v_isworkflow,'N')='Y' and v_aux=0 then
            -- Do not have to be approved
            UPDATE M_REQUISITION
            SET DocStatus = 'CO',
                DocAction = 'CL',
                allowdirectpo ='Y'
            WHERE M_REQUISITION_ID = v_Record_ID;
        else
            -- Approve or it has no workflow
            UPDATE M_REQUISITION
            SET DocStatus = 'CO',
                DocAction = 'CL'
            WHERE M_REQUISITION_ID = v_Record_ID;
        end if;
      ELSE
        RAISE EXCEPTION '%', '@ActionNotAllowedHere@'; --OBTG:-20000--
      END IF;
    ELSIF (v_DocStatus = 'CO') THEN
      IF (v_DocAction = 'CL') THEN
        v_ResultStr := 'Close requisition lines';
        FOR Cur_RequisitionLine IN
          (SELECT M_RequisitionLine_ID
           FROM M_RequisitionLine
           WHERE M_Requisition_ID = v_Record_ID
          ) 
        LOOP
          --PERFORM M_REQUISITIONLINE_STATUS(NULL, Cur_RequisitionLine.M_RequisitionLine_ID, v_User);
          update zspm_projecttaskbom set M_REQUISITIONLINE_id=null where M_REQUISITIONLINE_id=Cur_RequisitionLine.M_RequisitionLine_ID;
          update M_RequisitionLine set reqstatus='C', zspm_projecttaskbom_id=null where M_REQUISITIONLINE_id=Cur_RequisitionLine.M_RequisitionLine_ID;
        END LOOP;
        UPDATE M_Requisition SET DocStatus = 'CL',updated=now(),updatedby=v_User where M_Requisition_ID = v_Record_ID;
      ELSIF (v_DocAction = 'RE' ) THEN
        v_ResultStr := 'Reactivate the requisition: ' || v_Record_ID;
        select count(*) into v_Aux from M_REQUISITIONline  WHERE M_REQUISITION_ID = v_Record_ID and lockedby is not null;
        if v_Aux=0 then
            UPDATE M_REQUISITION
            SET DocStatus = 'DR',
                DocAction = 'CO',
                allowdirectpo ='N'
            WHERE M_REQUISITION_ID = v_Record_ID;
        ELSE
            RAISE EXCEPTION '%', '@ActionNotAllowedHere@';
        END IF;
      ELSE
        RAISE EXCEPTION '%', '@ActionNotAllowedHere@'; --OBTG:-20000--
      END IF;
    END IF;
 ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END; 
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION public.m_requisitionline_trg ()
  RETURNS trigger AS
/************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
*************************************************************************************************************************************************/
/*
 Contributions: Added Reference-Fields (asset, Project etc..
*************************************************************************************************************************************************/
$body$
DECLARE 
  v_DocStatus VARCHAR(60);
  v_ReqStatus VARCHAR(60);
  v_OrderedQty NUMERIC;
  
  v_ID         VARCHAR(32);
  v_UOM_ID     VARCHAR(32);
  v_currency   VARCHAR(32);
  v_ReqLineStatus  varchar;
  v_lockedby   varchar;
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;

  IF TG_OP in ( 'INSERT','UPDATE') THEN
    SELECT DocStatus, new.ReqStatus, new.OrderedQty INTO v_DocStatus, v_ReqStatus, v_OrderedQty
    FROM M_Requisition
    WHERE M_Requisition_ID = new.M_Requisition_ID;
  ELSE
    SELECT DocStatus, old.ReqStatus, old.OrderedQty INTO v_DocStatus, v_ReqStatus, v_OrderedQty
    FROM M_Requisition
    WHERE M_Requisition_ID = old.M_Requisition_ID;
  END IF;

  IF (v_DocStatus = 'CL') THEN
    RAISE EXCEPTION '%', '@20527@'; --OBTG:-20527--It is not possible to modify a closed requisition
  END IF;

  IF (v_DocStatus = 'CO' AND TG_OP = 'INSERT') THEN
    RAISE EXCEPTION '%', '@20525@'; --OBTG:-20525--It is not possible insert a new line in a completed requisition
  END IF;

  
/*
  IF (v_ReqStatus <> 'O') THEN
    RAISE EXCEPTION '%', '@20520@'; --OBTG:-20520--It is not possible to modify closed or cancelled requisition lines
  END IF;
*/
  IF (TG_OP = 'DELETE' AND v_OrderedQty <> 0 )THEN
    RAISE EXCEPTION '%', '@20521@'; --OBTG:-20521--It is not possible to delete a requisition line with associated purchase order lines
  END IF;
  
  -- Get ID
  IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    SELECT c_currency_id INTO v_currency FROM m_requisition WHERE m_requisition_id=new.m_requisition_id;
    IF NEW.c_currency_id != v_currency THEN
      RAISE EXCEPTION '%', '@zssi_OnlyOneCurrencyInDocument@';
    END IF;
    IF (NEW.m_product_id IS NOT NULL) THEN
      SELECT C_UOM_ID INTO v_UOM_ID FROM M_PRODUCT WHERE m_product_id=NEW.m_product_id;
      IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.c_uom_id,'0')) THEN
        RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)';
      END IF;
    END IF;
    v_ID := new.m_requisition_id;
  ELSE
   v_ID := old.m_requisition_id;
  END IF;
 
  IF TG_OP = 'UPDATE' THEN
    select OrderedQty,ReqStatus,lockedby into v_OrderedQty,v_ReqLineStatus,v_lockedby  from m_requisitionline where m_requisition_id=new.m_requisition_id;
    if v_DocStatus = 'CO' and (v_OrderedQty>0 or v_ReqLineStatus!='O' or v_lockedby is not null) then
        IF ((COALESCE(old.M_Requisition_ID, '0') <> COALESCE(new.M_Requisition_ID,'0'))
        OR (COALESCE(old.M_Product_ID, '-1') <> COALESCE(new.M_Product_ID, '-1'))
        OR (COALESCE(old.M_PriceList_ID, '-1') <> COALESCE(new.M_PriceList_ID, '-1'))
        OR (COALESCE(old.C_Currency_ID, '-1') <> COALESCE(new.C_Currency_ID, '-1'))
        OR (COALESCE(old.Qty, -1) <> COALESCE(new.Qty, -1))
        OR (COALESCE(old.PriceList, -1) <> COALESCE(new.PriceList, -1))
        OR (COALESCE(old.PriceActual, -1) <> COALESCE(new.PriceActual, -1 ))
        OR (COALESCE(old.Discount, -1) <> COALESCE(new.Discount, -1 ))
        OR (COALESCE(old.LineNetAmt, -1) <> COALESCE(new.LineNetAmt, -1 ))
        OR (COALESCE(old.C_BPartner_ID, '0') <> COALESCE(new.C_BPartner_ID, '0' ))
        OR (COALESCE(old.C_UOM_ID, '0') <> COALESCE(new.C_UOM_ID, '0' ))
        OR (COALESCE(old.M_Product_UOM_ID, '0') <> COALESCE(new.M_Product_UOM_ID, '0' ))
        OR (COALESCE(old.QuantityOrder, -1) <> COALESCE(new.QuantityOrder, -1 ))
        OR (COALESCE(old.M_AttributeSetInstance_ID, '-1') <> COALESCE(new.M_AttributeSetInstance_ID, '-1' ))
        OR (COALESCE(old.NeedByDate, TO_DATE('01-01-1900', 'DD-MM-YYYY')) <> COALESCE(new.NeedByDate, TO_DATE('01-01-1900', 'DD-MM-YYYY'))))
        OR (COALESCE(old.C_PROJECT_ID, '-1') <> COALESCE(new.C_PROJECT_ID, '-1'))
        OR (COALESCE(old.C_Projectphase_ID, '-1') <> COALESCE(new.C_Projectphase_ID, '-1'))
        OR (COALESCE(old.C_Projecttask_ID, '-1') <> COALESCE(new.C_Projecttask_ID, '-1'))
        OR (COALESCE(old.A_ASSET_ID, '-1') <> COALESCE(new.A_ASSET_ID, '-1')) THEN
            IF (v_DocStatus = 'CO') THEN
                RAISE EXCEPTION '%', 'It is not possible to modify a requisition line when the requisition is completed'; --OBTG:-20522--
            ELSIF (v_OrderedQty <> 0 ) THEN
                RAISE EXCEPTION '%', 'It is not possible to modify a requisition line when it has associated purchase order lines'; --OBTG:-20523--
            END IF;
            IF (v_ReqStatus = 'P') THEN
                RAISE EXCEPTION '%', '@20526@'; --OBTG:-20526--It is not possible to modify planned requisition lines
            END IF;
        END IF;
    end if;
  END IF;
  
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$body$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION public.m_requisitionline_trg2 (
)
RETURNS trigger AS
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, 02/2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2012 Stefan Zimmermann
****************************************************************************************************************************************************
  UPDATE m_requisition.totallines : SUM(netamt) FROM m_requisitionlines
***************************************************************************************************************************************************/
$body$
DECLARE
  v_ID         VARCHAR(32);
  v_NetAmt     NUMERIC;
BEGIN

  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  -- Building SUMS for Header
  IF ((TG_OP = 'UPDATE') OR (TG_OP = 'INSERT')) THEN
    v_ID := new.m_requisition_id;
  ELSE     
    v_ID := old.m_requisition_id;
  END IF;
  SELECT COALESCE(SUM(linenetamt),0) INTO v_NetAmt FROM m_requisitionline WHERE m_requisition_id = v_ID;

  IF (v_ID IS NOT NULL) THEN
    UPDATE m_requisition
      SET totalLines = v_NetAmt
    WHERE m_requisition_id = v_ID;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;

END;
$body$
LANGUAGE 'plpgsql'  VOLATILE
COST 100;

select zsse_droptrigger('m_requisitionline_trg2','m_requisitionline');

CREATE TRIGGER m_requisitionline_trg2
  AFTER INSERT OR UPDATE OR DELETE
  ON public.m_requisitionline FOR EACH ROW
  EXECUTE PROCEDURE public.m_requisitionline_trg2();
  

CREATE OR REPLACE FUNCTION m_requisitionorder_trg() RETURNS trigger
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
* Contributor(s): Stefan Zimmermann, 02/2015, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2015 Stefan Zimmermann
****************************************************************************************************************************************************

***************************************************************************************************************************************************/
    v_DocStatus VARCHAR(60);
    v_ReqStatus VARCHAR(60);
    v_Count     NUMERIC;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;



IF TG_OP = 'INSERT' THEN
  SELECT DocStatus INTO v_DocStatus
  FROM M_Requisition, M_RequisitionLine
  WHERE M_REquisitionLine_ID = new.M_RequisitionLine_ID
    AND M_Requisition.M_Requisition_ID = M_RequisitionLine.M_Requisition_ID;
ELSE
  SELECT DocStatus INTO v_DocStatus
  FROM M_Requisition, M_RequisitionLine
  WHERE M_REquisitionLine_ID = old.M_RequisitionLine_ID
    AND M_Requisition.M_Requisition_ID = M_RequisitionLine.M_Requisition_ID;
END IF;

IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
  SELECT COUNT(*) INTO v_Count
  FROM M_REQUISITIONLINE A, C_ORDERLINE B
  WHERE A.M_REQUISITIONLINE_ID = new.M_REQUISITIONLINE_ID
    AND B.C_ORDERLINE_ID = new.C_ORDERLINE_ID
    AND A.M_PRODUCT_ID = B.M_PRODUCT_ID;
  IF (v_Count = 0) THEN
    RAISE EXCEPTION '%', 'Different products'; --OBTG:-20524--
  END IF;
END IF;
IF (TG_OP != 'DELETE') THEN
    IF ((v_DocStatus <> 'CO') OR (v_ReqStatus <> 'O')) THEN
    RAISE EXCEPTION '%', 'Document processed/posted'; --OBTG:-20501--
    END IF;
ELSE
    UPDATE M_Requisition SET DocStatus = 'CO' where M_Requisition_id=(select m_requisition_id from m_requisitionline where M_REQUISITIONLINE_ID = old.M_REQUISITIONLINE_ID);
    UPDATE M_Requisitionline set ReqStatus = 'O' where M_REQUISITIONLINE_ID = old.M_REQUISITIONLINE_ID;
END IF;

IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
  UPDATE M_REQUISITIONLINE
  SET ORDEREDQTY = COALESCE(ORDEREDQTY,0) - OLD.QTY
  WHERE M_REQUISITIONLINE_ID = OLD.M_REQUISITIONLINE_ID;
END IF;
IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
  UPDATE M_REQUISITIONLINE
  SET ORDEREDQTY = COALESCE(ORDEREDQTY,0) + NEW.QTY
  WHERE M_REQUISITIONLINE_ID = NEW.M_REQUISITIONLINE_ID;
END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;
 
