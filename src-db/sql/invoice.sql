CREATE OR REPLACE FUNCTION c_invline_chk_restrictions_trg() RETURNS trigger LANGUAGE plpgsql
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
* 
***************************************************************************************************************************************************

Creditcard Payment doctype 3CC248B45xxx can change orderline_id in a processed doument
*/
  v_Processed VARCHAR(60) ;
  v_C_INVOICE_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  v_Prec NUMERIC:=2;
  v_Currency     VARCHAR(32); --OBTG:VARCHAR2--
  v_doctype varchar;
  v_count numeric;  
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  -- Reverse Charge only on net pricelist
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    select count(*) into v_count from m_pricelist p,c_invoice i  where i.c_invoice_id=new.c_invoice_id and i.m_pricelist_id=p.m_pricelist_id and  p.istaxincluded='Y';
    if v_count>0 then
        select count(*) into v_count from c_tax t where t.c_tax_id=new.c_tax_id and t.reversecharge='Y';
        if v_count>0 then
            raise exception '%','@grosspricelistnoreversecharge@';
        end if;
    end if;
  END IF;
  -- UOM check
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        if (new.quantityorder is null and new.m_product_uom_id is not null) or (new.quantityorder is not null and new.m_product_uom_id is  null) then
            raise exception '%','@secondUOMRequiresQTY@';
        end if;
  END IF;
  IF TG_OP = 'INSERT' THEN
    v_C_INVOICE_ID:=NEW.C_INVOICE_ID;
  ELSE
    v_C_INVOICE_ID:=OLD.C_INVOICE_ID;
  END IF;
  SELECT PROCESSED,
    C_CURRENCY_ID,c_doctype_id
  INTO v_Processed,v_Currency,v_doctype
  FROM C_INVOICE
  WHERE C_INVOICE_ID=v_C_INVOICE_ID;
  IF TG_OP = 'UPDATE' THEN
    IF(v_Processed='Y' AND ((COALESCE(OLD.M_PRODUCT_ID, '0') <> COALESCE(NEW.M_PRODUCT_ID, '0'))
      OR(COALESCE(OLD.QTYINVOICED, 0) <> COALESCE(NEW.QTYINVOICED, 0))
      --OR(COALESCE(old.LINE, 0) <> COALESCE(NEW.LINE, 0))
      OR(COALESCE(OLD.PRICELIST, 0) <> COALESCE(NEW.PRICELIST, 0))
      OR(COALESCE(OLD.PRICEACTUAL, 0) <> COALESCE(NEW.PRICEACTUAL, 0))
      --OR(COALESCE(OLD.PRICELIMIT, 0) <> COALESCE(NEW.PRICELIMIT, 0))
      OR(COALESCE(OLD.LINENETAMT, 0) <> COALESCE(NEW.LINENETAMT, 0))
      OR(COALESCE(OLD.C_CHARGE_ID, '0') <> COALESCE(NEW.C_CHARGE_ID, '0'))
      OR(COALESCE(OLD.CHARGEAMT, 0) <> COALESCE(NEW.CHARGEAMT, 0))
      OR(COALESCE(OLD.C_UOM_ID, '0') <> COALESCE(NEW.C_UOM_ID, '0'))
      OR(COALESCE(OLD.C_TAX_ID, '0') <> COALESCE(NEW.C_TAX_ID, '0'))
      OR(COALESCE(OLD.TAXAMT, 0) <> COALESCE(NEW.TAXAMT, 0))
      OR(COALESCE(OLD.M_ATTRIBUTESETINSTANCE_ID, '0') <> COALESCE(NEW.M_ATTRIBUTESETINSTANCE_ID, '0'))
      OR(COALESCE(OLD.QUANTITYORDER, 0) <> COALESCE(NEW.QUANTITYORDER, 0))
      OR(COALESCE(OLD.C_ORDERLINE_ID, '0') <> COALESCE(NEW.C_ORDERLINE_ID, '0') and v_doctype!= '3CC248B45ED8440B9CAB57337D26BA56')
      OR(COALESCE(OLD.M_PRODUCT_UOM_ID, '0') <> COALESCE(NEW.M_PRODUCT_UOM_ID, '0'))
      OR(COALESCE(OLD.AD_ORG_ID, '0') <> COALESCE(NEW.AD_ORG_ID, '0'))
      OR(COALESCE(OLD.AD_CLIENT_ID, '0') <> COALESCE(NEW.AD_CLIENT_ID, '0'))
      )) THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  END IF;
  IF((TG_OP = 'DELETE' OR TG_OP = 'INSERT') AND v_Processed='Y') THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
  -- Rounds linenetAmt and ChargeAmt
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    SELECT STDPRECISION
    INTO v_Prec
    FROM C_CURRENCY
    WHERE C_CURRENCY_ID=v_Currency;
    NEW.LineNetAmt:=ROUND(NEW.LineNetAmt, v_Prec) ;
    NEW.ChargeAmt:=ROUND(NEW.ChargeAmt, v_Prec) ;
  END IF;
  -- Sauberer Umgang mit Projektzuordnung
  if (TG_OP = 'UPDATE') then
      if coalesce(new.c_project_id, '0') != coalesce(old.c_project_id, '0') and new.c_project_id is null then
         new.c_projecttask_id:=null;
      end if;
  end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;$_$;


CREATE OR REPLACE FUNCTION  zssi_invoiceline_trg()
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
Part of Smartprefs
Calculates TAX,NET and GROSSAMOUNT on INVOICELINES
Updates TAX and Invoice-Header with GROSSAMOUNT and NETAMOUNT, TAX
Calculates, Creates and Deletes c_invoice_tax
All Price-Calculations on Invoices are done here!!!!!!!!
Trigger overrides Calculations done by SLInvoiceAmt.java
and c_invoice_create - Function 
Replaces c_invoiceline_trg
Same calculations on ordrs are done in c_orderline_trg
*****************************************************/

 v_linegrossamt    NUMERIC;
 v_linenetamt      NUMERIC;
 v_linetaxamt      NUMERIC; 
 v_taxrate         NUMERIC;
 v_newTaxBaseAmt   NUMERIC;
 v_taxAmt          NUMERIC;
 v_NetAmt          NUMERIC;
 v_GrossAmt        NUMERIC;
 v_exists          NUMERIC;
 v_Processed       CHAR(1);
 v_IsGross         CHAR(1);
 v_currency        VARCHAR(32);
 v_ID              VARCHAR(32);
 v_UOM_ID          VARCHAR(32);
 v_cur_line        RECORD; 
 v_old_tax_id      VARCHAR(32);
 v_reversetax      CHAR(1);
 v_reverseTaxAmt   NUMERIC;
 v_uom_conversion  NUMERIC;
 v_price           NUMERIC;
 v_qty             NUMERIC;   

BEGIN
  -- Checks, if sonething has to be Done, else Return from Trigger
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
  IF (TG_OP = 'UPDATE') THEN
      IF NOT(COALESCE(old.QtyInvoiced,0) <> COALESCE(NEW.QtyInvoiced,0)
        OR COALESCE(old.LineNetAmt,0) <> COALESCE(NEW.LineNetAmt,0)
        OR COALESCE(old.LineGrossAmt,0) <> COALESCE(NEW.LineGrossAmt,0)
        OR COALESCE(old.LineTaxAmt,0) <> COALESCE(NEW.LineTaxAmt,0)
        OR COALESCE(old.priceactual,0) <> COALESCE(NEW.priceactual,0)
        OR COALESCE(old.M_Product_ID,'0') <> COALESCE(NEW.M_Product_ID,'0')
        OR COALESCE(old.C_Tax_ID,'0') <> COALESCE(NEW.C_Tax_ID,'0')
        OR COALESCE(old.C_Uom_ID,'0') <> COALESCE(NEW.C_Uom_ID,'0'))
      THEN
         RETURN NEW;
      END IF;
  END IF;
 -- CHACK Coccect UOM, Get ID
 IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
     IF (NEW.M_PRODUCT_ID IS NOT NULL) THEN
       SELECT C_UOM_ID INTO v_UOM_ID FROM M_PRODUCT WHERE M_PRODUCT_ID=NEW.M_PRODUCT_ID;
       IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
           IF (NEW.M_INOUTLINE_ID IS NOT NULL) THEN
              SELECT C_UOM_ID INTO v_UOM_ID FROM M_INOUTLINE WHERE M_INOUTLINE_ID = NEW.M_INOUTLINE_ID;
              IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
                  RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
              END IF;
           ELSIF (NEW.C_ORDERLINE_ID IS NOT NULL) THEN
                SELECT C_UOM_ID INTO v_UOM_ID FROM C_ORDERLINE WHERE C_ORDERLINE_ID = NEW.C_ORDERLINE_ID;
                IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
                     RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
                END IF;
           ELSE
                RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
           END IF;
       END IF;
     END IF;
     v_ID := NEW.C_Invoice_ID;
 ELSE
     v_ID := OLD.C_Invoice_ID;
 END IF;
 -- ReadOnly Check
 SELECT  processed
   INTO v_Processed
 FROM C_INVOICE
 WHERE C_Invoice_ID=v_ID;
 IF(v_Processed = 'N') THEN
    -- Actions on Delete: HEADEER and TAX: Subtract old Amounts on delete
    IF (TG_OP = 'DELETE') THEN
          select c_currency_id into v_currency from c_invoice where c_invoice_id=old.c_invoice_id;
          select IsTaxIncluded into v_IsGross from m_pricelist where m_pricelist_id=(select m_pricelist_id from c_invoice where c_invoice_id=old.c_invoice_id);
          for v_cur_line in (select distinct(c_tax_id) from c_invoiceline where c_invoice_id=old.c_invoice_id and c_invoiceline_id!=old.c_invoiceline_id
                             UNION select old.c_tax_id as c_tax_id from dual)
          LOOP
              select case v_IsGross when 'N' then coalesce(sum(linenetamt),0) else coalesce(sum(linegrossamt),0) end into v_newTaxBaseAmt
                      from c_invoiceline 
                      where c_invoice_id=old.c_invoice_id and c_invoiceline_id!=old.c_invoiceline_id and c_tax_id=v_cur_line.c_tax_id;
              -- Recalculate the TAX
              select rate,reversecharge into v_taxrate,v_reversetax from c_tax where c_tax_id=v_cur_line.c_tax_id; 
              v_reverseTaxAmt:=0;
              if v_taxrate!=0 then
                   if v_IsGross='N' then
                      v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt*(v_taxrate/100),v_currency,NULL);
                   else 
                      v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt-v_newTaxBaseAmt/(1+(v_taxrate/100)),v_currency,NULL);
                      v_newTaxBaseAmt:=v_newTaxBaseAmt-v_TaxAmt;
                   end if;
                   if v_reversetax='Y' then
                        v_reverseTaxAmt:=v_TaxAmt;
                        v_TaxAmt:=0;
                   end if;
              else
                   v_TaxAmt=0;
              end if;
              IF (v_newTaxBaseAmt!=0) THEN
                  UPDATE  C_INVOICETAX
                    SET TaxBaseAmt = v_newTaxBaseAmt, TaxAmt=v_taxAmt, reversetaxamt=v_reverseTaxAmt
                  WHERE C_Invoice_ID = OLD.C_Invoice_ID
                      AND C_Tax_ID = v_cur_line.C_Tax_ID AND Recalculate='Y';
              ELSE
                  DELETE from C_INVOICETAX where C_Invoice_ID = OLD.C_Invoice_ID
                      AND C_Tax_ID = v_cur_line.C_Tax_ID AND Recalculate='Y';
              END IF;
           END LOOP;
           -- Building SUMS for Header
           if v_IsGross='N' then 
                  select  coalesce(sum(linenetamt),0) into v_NetAmt from c_invoiceline where c_invoice_id=old.c_invoice_id and c_invoiceline_id!=old.c_invoiceline_id;
                  select coalesce(sum(taxamt),0) into v_GrossAmt from c_invoicetax  where c_invoice_id=old.c_invoice_id;
                  v_GrossAmt:=v_GrossAmt+v_NetAmt;
           else
                  select  coalesce(sum(linegrossamt),0) into v_GrossAmt from c_invoiceline where c_invoice_id=old.c_invoice_id and c_invoiceline_id!=old.c_invoiceline_id;
                  select coalesce(sum(taxamt),0) into v_NetAmt from c_invoicetax  where c_invoice_id=old.c_invoice_id;
                  v_NetAmt:=v_GrossAmt-v_NetAmt;
           end if;
    END IF;
    -- Actions on Insert or Update
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        select c_currency_id into v_currency from c_invoice where c_invoice_id=new.c_invoice_id;
        -- CALCULATE THE ACTUAL LINE
        -- If it Is Grossproce, we see in the Pricelist
        select IsTaxIncluded into v_IsGross from m_pricelist where m_pricelist_id=(select m_pricelist_id from c_invoice where c_invoice_id=new.c_invoice_id);
        new.isgrossprice:=v_IsGross;
        -- On LINE-LEVEL: Set linenetamt, linegrossamt, linetaxamt
        If new.qtyinvoiced!=0 and new.priceactual!=0 and new.c_tax_id is not null THEN
                select rate,reversecharge into v_taxrate,v_reversetax from c_tax where c_tax_id=new.c_tax_id;
                 --If we order in Secondary OUM, Price applies to OrderQTY not to qtyOrdered
                -- Be aware of 2nd UOM
                if new.m_product_uom_id is not null and coalesce(new.quantityorder,0)!=0 then
                   v_qty:=new.quantityorder;
                else
                   v_qty:=new.qtyinvoiced;
                end if;   
                
                if v_IsGross='Y' then
                    v_linegrossamt:=C_Currency_Round(v_qty*new.priceactual,v_currency,NULL);
                    v_linenetamt:=0;
                else
                    v_linenetamt:=C_Currency_Round(v_qty*new.priceactual,v_currency,NULL);
                    v_linegrossamt:=0;
                end if;
                new.linenetamt:=v_linenetamt + new.pricefluctuation;
                new.linegrossamt:=v_linegrossamt;
                --new.linetaxamt:=new.linegrossamt-new.linenetamt;
                --perform logg('Updating line: '||new.c_invoiceline_id||' ,NET: '||to_char(new.linenetamt,'999D9999999999')||' ,GROS: '||to_char(new.linegrossamt,'999D9999999999')||' ,TAX: '||to_char(new.linetaxamt,'999D9999999999'));
        else
               --new.linetaxamt:=0;
               new.linenetamt:=0;
               new.linegrossamt:=0;
        end if;
        -- Line-Calculations DONE
        -- Proceedung with TAX
        -- Notice change of Tax in Line
        v_old_tax_id:=new.c_tax_id;
        if (TG_OP = 'UPDATE') THEN if old.c_tax_id!=new.c_tax_id then v_old_tax_id:=old.c_tax_id; end if; end if;
        -- Build the cursor
        for v_cur_line in (select distinct(c_tax_id) as c_tax_id from c_invoiceline where c_invoice_id=new.c_invoice_id and c_invoiceline_id!=new.c_invoiceline_id 
                                  UNION select new.c_tax_id as c_tax_id from dual union select v_old_tax_id as c_tax_id from dual)
        LOOP
              select case v_IsGross when 'Y' then  coalesce(sum(linegrossamt),0) else coalesce(sum(linenetamt),0) end into v_newTaxBaseAmt
                      from c_invoiceline 
                      where c_invoice_id=new.c_invoice_id 
                      and c_invoiceline_id!=new.c_invoiceline_id and c_tax_id=v_cur_line.c_tax_id;
              -- recalculate TAX
              if v_cur_line.c_tax_id=new.c_tax_id then
                  if v_IsGross='Y' then v_newTaxBaseAmt:= v_newTaxBaseAmt+new.linegrossamt; end if;
                  if v_IsGross='N' then v_newTaxBaseAmt:= v_newTaxBaseAmt+new.linenetamt;  end if;
              end if;
              -- Recalculate the TAX
              select rate,reversecharge into v_taxrate,v_reversetax from c_tax where c_tax_id=v_cur_line.c_tax_id;
              v_reverseTaxAmt:=0;
              if v_taxrate!=0 then
                     if v_IsGross='N' then 
                        v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt*(v_taxrate/100),v_currency,NULL);                       
                     else
                        v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt-v_newTaxBaseAmt/(1+(v_taxrate/100)),v_currency,NULL);
                        v_newTaxBaseAmt:=v_newTaxBaseAmt-v_TaxAmt;
                     end if;
                     if v_reversetax='Y' then
                        v_reverseTaxAmt:=v_TaxAmt;
                        v_TaxAmt:=0;
                     end if;
              else
                  v_TaxAmt=0;
              end if;
              -- Are there TAX-Lines?
              SELECT  count(*) into v_exists
                      FROM  C_INVOICETAX
                      WHERE C_Invoice_ID = NEW.C_Invoice_ID
                      AND C_Tax_ID = v_cur_line.C_Tax_ID
                      AND Recalculate='Y';
              -- Update, If TAXline Exists
              IF (v_exists>0) and v_newTaxBaseAmt!=0 THEN                     
                       UPDATE  C_INVOICETAX
                               SET TaxBaseAmt = v_newTaxBaseAmt, TaxAmt= v_TaxAmt, reversetaxamt=v_reverseTaxAmt
                               WHERE C_Invoice_ID=NEW.C_Invoice_ID
                               AND C_Tax_ID=v_cur_line.C_Tax_ID
                               AND Recalculate='Y';
              -- Delete if No Tax is there anymore
              ELSIF  (v_exists>0) and v_newTaxBaseAmt=0 THEN   
                       DELETE from C_INVOICETAX where C_Invoice_ID = NEW.C_Invoice_ID
                              AND C_Tax_ID = v_cur_line.C_Tax_ID AND Recalculate='Y'; 
              -- Insert new TAX Line
              ELSE
                        INSERT INTO C_INVOICETAX
                               (C_InvoiceTax_ID, AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated, UpdatedBy,
                                C_Invoice_ID, C_Tax_ID, TaxBaseAmt, TaxAmt,reverseTaxAmt, Recalculate)
                        VALUES
                               (get_uuid(), NEW.AD_Client_ID, NEW.AD_Org_ID, 'Y', TO_DATE(NOW()), NEW.UpdatedBy, TO_DATE(NOW()), NEW.UpdatedBy,
                                NEW.C_Invoice_ID, v_cur_line.C_Tax_ID,v_newTaxBaseAmt , v_TaxAmt,v_reverseTaxAmt, 'Y');
              END IF;
        END LOOP;
        -- Building SUMS for Header
        if v_IsGross='N' then 
            select  coalesce(sum(linenetamt),0) into v_NetAmt from c_invoiceline where c_invoice_id=new.c_invoice_id and c_invoiceline_id!=new.c_invoiceline_id;
            v_NetAmt:=v_NetAmt+new.linenetamt;
            select coalesce(sum(taxamt),0) into v_GrossAmt from c_invoicetax  where c_invoice_id=new.c_invoice_id;
            v_GrossAmt:=v_GrossAmt+v_NetAmt;
        else
            select  coalesce(sum(linegrossamt),0) into v_GrossAmt from c_invoiceline where c_invoice_id=new.c_invoice_id and c_invoiceline_id!=new.c_invoiceline_id;
            v_GrossAmt:=v_GrossAmt+new.linegrossamt;
            select coalesce(sum(taxamt),0) into v_NetAmt from c_invoicetax  where c_invoice_id=new.c_invoice_id;
            v_NetAmt:=v_GrossAmt-v_NetAmt;
        end if;
    -- Insert or Update    
    END IF;
    --perform logg('Current Header: '||new.c_invoice_id||' ,TNET: '||to_char(v_t,'999D9999999999')||' ,TGROS: '||to_char(v_g,'999D9999999999'));
    -- Update Header
    UPDATE  C_INVOICE
      SET TotalLines = v_NetAmt,
      GrandTotal = v_GrossAmt
    WHERE C_Invoice_ID = v_ID;
    --perform logg('Updating Header: '||new.c_invoice_id||' ,DNET: '||to_char(v_deltaNetAmt,'999D9999999999')||' ,DGROS: '||to_char(v_deltaGrossamt,'999D9999999999'));
 -- processed=N
 end if; 
 IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_invoiceline_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION c_invoice_create_userexit(v_invoice_id varchar)
  RETURNS varchar AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***********************************************************************************************+*****************************************
User-Exit for c_invoice_create
**/
DECLARE
v_return varchar:='';
BEGIN

RETURN v_return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
--
-- Function: c_invoice_create(character varying, character varying)

-- DROP FUNCTION c_invoice_create(character varying, character varying);

CREATE OR REPLACE FUNCTION c_invoice_create(IN p_pinstance_id character varying, OUT p_invoice_id character varying, IN p_order_id character varying)
  RETURNS character varying AS
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
 Contributions: Gross-Price
         Removed all Price-Calculations, They are done in 
         zssi_invoiceline_trg 
         Removed Rubbish Stuff (Charge - Lines and Shipment-Reference Lines in Invoice Creation   
         Added Delivery-Rules to invoice     
         Removed Date Calculation. Invoice Date is either a Parameter or now
         p_order_id - Parameter is OBSOLETE!
        @TODO: shipment-assignments from M-INOUT, if there, else From Order
******************************************************************************************************************************/
/*************************************************************************
  * $Id: C_Invoice_Create.sql,v 1.12 2003/08/31 06:49:27 jjanke Exp $
  ***
  * Title: Create Invoice from ORDERs
  * Description:
  * - Based on Invoice Rules create Invoice
  * - Update Order while creating the lines
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR:=''; 
  v_Message VARCHAR:=''; 
  v_messtype numeric:=1;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
 
    v_AD_Org_ID VARCHAR(32):=NULL; 
    v_C_Order_ID VARCHAR(32):=NULL; 
    v_BPartner_ID VARCHAR(32):=NULL; 
    v_Selection VARCHAR(1):='N'; 
   
    v_InvoiceToDate DATE:=NULL;
   
    v_DateInvoiced TIMESTAMP;
    Cur_Order RECORD;
    --
    v_NextNo VARCHAR(32); 
    v_DocType_ID VARCHAR(32);  
    v_DocumentNo VARCHAR(40) ; 
    v_DocSubTypeSO VARCHAR(60) ; 
    --
    v_LineNo NUMERIC:=0;
    v_count NUMERIC:=0;
    Cur_AutomaticInvoice_ISOPEN BOOLEAN:=false;
    Cur_ManualGeneratedLines_ISOPEN BOOLEAN:=false;
    -- SZ Grossprice
    v_isgross character(1);
    v_ismanuallines character(1);
    v_partialAmountFactor NUMERIC:=1;
    v_paymentscheduleamt NUMERIC;
    v_correctiveamt NUMERIC;
    v_NoRecords NUMERIC:=0;
    v_correctivtax VARCHAR(32); 
    v_paymentschedule_id VARCHAR(32); 
    v_draftexists numeric;
    v_ĺinesrecord RECORD;
    v_description character varying;
    v_internalnote character varying;
    v_scheduledtransactiondate timestamp;
    v_prjstartdate  timestamp;
    v_prjenddate  timestamp;
    v_transactionreference character varying;
    v_qty2nduom numeric;
    v_2nduom varchar;
    v_convrate numeric;
    v_tax character varying;
    v_price NUMERIC;
    v_qty NUMERIC;
    v_cur RECORD;
    v_lang varchar;
    vshedmsg varchar;
    v_textshed  varchar;
    v_textinv  varchar;
    v_invoicereceiver varchar;
    v_invoiceadress varchar;
    v_lzstart timestamp:=trunc(now()+100);
    v_lzend timestamp:=trunc(now()+100);
    v_combined varchar:='N';
    v_actualdoc varchar;
    v_orderall varchar;
    v_textpos varchar;
        -- manual edited lines
        DECLARE Cur_ManualGeneratedLines CURSOR (Order_ID VARCHAR)  FOR
           SELECT ol.AD_Client_ID,
          ol.AD_Org_ID,
          ol.c_order_id,
          ol.C_OrderLine_ID,
          gm.Description AS Description,
          ol.M_Product_ID,
          gm.Qty AS pendingqty,
          gm.m_inoutline_id as M_InOutLine_ID,
          ol.PriceList,
          gm.Price as pendingprice,
          gm.ignoreresidue,
          gm.c_generateinvoicemanual_id,
          gm.lineamt,
          gm.pinstance_id,
          gm.createdby,
          trunc(coalesce(gm.dateinvoiced,now())) as dateinvoiced,
          ol.PriceLimit,
          ol.C_Charge_ID,
          ol.ChargeAmt,
          ol.C_UOM_ID,
          ol.priceactual as orderprice,
          ol.qtyordered,
          ol.M_PRODUCT_UOM_ID,
          ol.C_Tax_ID, 
          ol.Line,
          ol.DirectShip,
          ol.PriceStd,
          ol.isonetimeposition,
          ol.pricefluctuation,
          ol.textposition,
          o.contractdate,
          o.enddate,
          o.scheddeliverydate,
          o.poreference,
          o.documentno,
          o.salesrep_id,
          ol.m_attributesetinstance_id,ol.c_project_id,ol.c_projectphase_id,ol.c_projecttask_id,ol.a_asset_id,ol.textposition,ol.ispagebreak,ol.iscombined,ol.ispricesuppressed
        FROM c_orderline ol, c_generateinvoicemanual gm, c_order o where 
             ol.c_orderline_id=gm.c_orderline_id and gm.c_order_id= Order_ID and gm.c_invoiceline_id is null
             and o.c_order_id=ol.c_order_id
             order by o.contractdate,ol.c_order_id,gm.line;
        Next_O_Line BOOLEAN:=FALSE;
        FINISH_PROCESS BOOLEAN:=FALSE;
      BEGIN
        -- Process Parameters
        IF(p_PInstance_ID IS NOT NULL) THEN
          --  Check for serial execution
          RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
          SELECT COUNT(*)
          INTO v_count
          FROM AD_PINSTANCE
          WHERE AD_PROCESS_ID IN
            (SELECT AD_PROCESS_ID FROM AD_PINSTANCE WHERE AD_PInstance_ID=p_PInstance_ID)
            AND IsProcessing='Y'
            AND AD_PInstance_ID<>p_PInstance_ID;
          IF(v_count>0) THEN
            RAISE EXCEPTION '%', '@SerialProcessStillRunning@' ; --OBTG:-20000--
          END IF;
          --  Update AD_PInstance
          RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
          v_ResultStr:='PInstanceNotFound';
          PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
          -- Get Parameters
          v_ResultStr:='ReadingParameters';
          v_C_Order_ID:=NULL;
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
            IF(Cur_Parameter.ParameterName='DateInvoiced') THEN
              v_DateInvoiced:=Cur_Parameter.P_Date;
              RAISE NOTICE '%','  DateInvoiced=' || v_DateInvoiced ;
            ELSIF(Cur_Parameter.ParameterName='InvoiceToDate') THEN
              v_InvoiceToDate:=Cur_Parameter.P_Date;
            ELSIF(Cur_Parameter.ParameterName='AD_Org_ID') THEN
              v_AD_Org_ID:=Cur_Parameter.P_String;
              RAISE NOTICE '%','  AD_Org_ID=' || v_AD_Org_ID ;
            ELSIF(Cur_Parameter.ParameterName='C_Order_ID') THEN
              v_C_Order_ID:=Cur_Parameter.P_String;
              RAISE NOTICE '%','  C_Order_ID=' || v_C_Order_ID ;
            ELSIF(Cur_Parameter.ParameterName='C_BPartner_ID') THEN
              v_BPartner_ID:=Cur_Parameter.P_String;
              RAISE NOTICE '%','  C_BPartner_ID=' || v_BPartner_ID ;
            ELSIF(Cur_Parameter.ParameterName='Selection') THEN
              v_Selection:=Cur_Parameter.P_String;
              RAISE NOTICE '%','  Selection=' || v_Selection ;
            ELSE
              RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
            END IF;
          END LOOP; -- Get Parameter
        ELSE
          RAISE NOTICE '%','--<<C_Invoive_Create>>' ;
          v_C_Order_ID:=p_Order_ID;
          v_InvoiceToDate:=NULL;
          v_BPartner_ID:=NULL;
          v_Selection:='N';
        END IF;
      BEGIN --BODY
        /**
        * Order Loop == all not completely invoiced orders == No Summary ==
        */

         RAISE NOTICE '%','  C_Order_ID=' || coalesce(v_C_Order_ID,'noORDER') || ', BPartner_ID=' || coalesce(v_BPartner_ID,'noPartner') || ', AD_Org_ID=' || coalesce(v_AD_Org_ID,'noOrg')||', selection='||v_Selection;
          -- For all Orders
          -- Normal Order: All not yet fully invoiced lines are selected.
          -- If Subscription Order: all Lines are selected that are not One-Time-Positions or not yet fully invoiced lines.
          FOR Cur_Order IN
            (SELECT *
            FROM C_ORDER o  -- Specific InProgress Order
            WHERE o.c_order_id in (select c_order_id from c_generateinvoicemanual where c_invoiceline_id is null and pinstance_id=p_pinstance_id)
            ORDER BY o.DateOrdered,PriorityRule,
              C_BPartner_ID,
              DocumentNo
            )
          LOOP
            RAISE NOTICE '%','Order ' || Cur_Order.DocumentNo || ', ID=' || Cur_Order.C_Order_ID ;
            -- Test for Combined
            if (SELECT count(*) FROM C_ORDER o WHERE o.c_order_id 
                in (select distinct ol.c_order_id from c_orderline ol,c_generateinvoicemanual gm where gm.c_orderline_id=ol.c_orderline_id and gm.c_order_id= Cur_Order.C_Order_ID and gm.c_invoiceline_id is null))>1 then
                v_combined:='Y';
                v_orderall:=null;
            else
                v_combined:='N';
                v_orderall:=Cur_Order.C_Order_ID;
            end if;
             /**
             * Load Invoice Rules and test if manual lines exists
             * manual lines always have priority
             * Open the lines Cursor
             */
              OPEN Cur_ManualGeneratedLines (Cur_Order.C_Order_ID) ;
              FETCH Cur_ManualGeneratedLines INTO v_ĺinesrecord;
              Cur_ManualGeneratedLines_ISOPEN :=true;
              IF(v_DateInvoiced IS NULL) THEN
                v_DateInvoiced:=v_ĺinesrecord.dateinvoiced;
              end if;
              IF(v_DateInvoiced IS NULL) THEN
                -- SZ: Removed Date Calculation. Invoice Date is either a Parameter or now
                v_DateInvoiced:=now();
              END IF;
              v_DateInvoiced:=trunc(v_DateInvoiced);
              RAISE NOTICE '%','  Invoice Date=' || v_DateInvoiced ;
              /**
              * Create Invoice Header ---------------------------------------
              */
              -- Get Order DocType Info - approved from Invoice DocType
              v_ResultStr:='GetDocTypeInfo - ' || Cur_Order.C_DocType_ID;  
              SELECT od.C_DocTypeInvoice_ID, od.DocSubTypeSO INTO v_DocType_ID, v_DocSubTypeSO  FROM C_DOCTYPE od, C_DOCTYPE ID   WHERE od.C_DocType_ID=Cur_Order.C_DocType_ID  AND od.C_DocTypeInvoice_ID=ID.C_DocType_ID;
              -- The Doctype should be a credit memo on Shipment (Return) / Rücksendung - When using direct invoice after shipping in the order
              select count(*) into v_count from m_inout m,m_inoutline l,c_order o where l.m_inout_id=m.m_inout_id and m.c_doctype_id='2317023F9771481696461C5EAF9A0915' and l.m_inoutline_id=v_ĺinesrecord.m_inoutline_id 
                    and o.c_order_id=v_ĺinesrecord.c_order_id and o.invoicerule='DI';                    
              if v_count>0 then
                    v_DocType_ID:='A4277AD679DF4DD8A9C2BB9F3C2F2C92'; -- Credit Memo (AR)
              end if;
              -- Check, if there is NO Draft INVOICE concerning this ORDERLINE - It schould be activated before!
              select count(*) into v_draftexists from   c_invoiceline il,c_invoice i where il.c_orderline_id =v_ĺinesrecord.c_orderline_id and il.c_invoice_id=i.c_invoice_id and i.docstatus='DR'; 
              if v_draftexists>0 then
                    select i.c_invoice_id,documentno into p_Invoice_ID,v_DocumentNo from   c_invoiceline il,c_invoice i where il.c_orderline_id =v_ĺinesrecord.c_orderline_id and il.c_invoice_id=i.c_invoice_id and i.docstatus='DR'; 
                    if Cur_Order.IsSOTrx='Y' then     
                              v_Message:=v_Message||', '||' Rechnung kann nicht erstellt werden. Es existiert bereits eine Rechnung im Status Entwurf zu diesem Auftrag. Das Dokument muß zuerst verarbeitet werden: ' || zsse_htmldirectlink('../SalesInvoice/Header_Relation.html','document.frmMain.inpcInvoiceId',p_Invoice_ID,v_DocumentNo);
                    else
                              v_Message:=v_Message||', '||' Rechnung kann nicht erstellt werden. Es existiert bereits eine Rechnung im Status Entwurf zu diesem Auftrag. Das Dokument muß zuerst verarbeitet werden: ' || zsse_htmldirectlink('../PurchaseInvoice/Header_Relation.html','document.frmMain.inpcInvoiceId',p_Invoice_ID,v_DocumentNo);
                    end if;
                    delete from c_generateinvoicemanual where c_generateinvoicemanual_id=v_ĺinesrecord.c_generateinvoicemanual_id;
                    CLOSE Cur_ManualGeneratedLines;
              else
                    --
                    -- SZ Grossprice
                    select istaxincluded into v_isgross from m_pricelist where m_pricelist_id=Cur_Order.M_PriceList_ID;
                    -- SZ end
                    SELECT * INTO  p_Invoice_ID FROM Ad_Sequence_Next('C_Invoice', Cur_Order.AD_Client_ID) ;
                    SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(v_DocType_ID, Cur_Order.AD_Org_ID, 'Y') ;
                    IF(v_DocumentNo IS NULL) THEN
                      SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Invoice', Cur_Order.AD_Org_ID, 'Y') ;
                    END IF;
                    --
                    RAISE NOTICE '%','  Invoice_ID=' || p_Invoice_ID || ' DocumentNo=' || v_DocumentNo ;
                    v_ResultStr:='InsertInvoice ' || p_Invoice_ID;
                    select count(*) into v_count from c_order_paymentschedule where c_order_id=Cur_Order.c_order_id and c_invoice_id is null;
                    -- paymentschedule - Automatic Invoice only on  Orderlines if v_count>0
                    if v_count>0  then
                        select c_order_paymentschedule.c_order_paymentschedule_id,c_order_paymentschedule.amount,c_order_paymentschedule.description,c_order_paymentschedule.amount/c_order.totallines
                               into v_paymentschedule_id ,v_paymentscheduleamt,v_description,v_partialAmountFactor from c_order,c_order_paymentschedule 
                               where c_order.c_order_id=c_order_paymentschedule.c_order_id and c_order.c_order_id=Cur_Order.c_order_id
                                     and c_order_paymentschedule.c_invoice_id is null order by c_order_paymentschedule.invoicedate LIMIT 1;
                        RAISE NOTICE '%','Partial Payment: '|| to_char(v_partialAmountFactor) ||' Amount:'|| to_char(v_paymentscheduleamt);
                    else
                        v_partialAmountFactor:=1;
                        v_description:='';
                    end if;
                    -- internal note and sheduled(money)Transactiondate from order
                    select internalnote,schedtransactiondate,transactionreference into v_internalnote,v_scheduledtransactiondate,v_transactionreference from c_order where c_order_id=Cur_Order.C_Order_ID;
                    -- Performance-Period from Project Start and end-Dates 
                    select coalesce(pt.startdate,p.startdate),coalesce(pt.enddate,p.datefinish) into v_prjstartdate,v_prjenddate from c_project p
                           left join c_projecttask pt on p.c_project_id=pt.c_project_id and pt.c_projecttask_id=Cur_Order.c_projecttask_id
                           where p.c_project_id=Cur_Order.c_project_id;      
                    -- If Different Invoice Receiver is selected: Use Different Business Partner and Billto Location ist 1St Invoice Location of this Business Partner
                    if (select c_bpartnerinvreceiver from c_bpartner_location where c_bpartner_location_id=Cur_Order.BillTo_ID) is not null then
                        select c_bpartnerinvreceiver into v_invoicereceiver from c_bpartner_location where c_bpartner_location_id=Cur_Order.BillTo_ID;
                        select c_bpartner_location_id into v_invoiceadress from c_bpartner_location where c_bpartner_id=v_invoicereceiver and isbillto='Y' order by isheadquarter desc , created;
                    else
                         v_invoicereceiver:=null;
                         v_invoiceadress:=null;
                    end if;
                    -- Performance Dates
                    select min(coalesce(coalesce(o.contractdate,o.scheddeliverydate),v_prjstartdate)) into v_lzstart from c_order o,c_orderline ol,c_generateinvoicemanual gm where o.c_order_id=ol.c_order_id and gm.c_orderline_id=ol.c_orderline_id and gm.c_order_id= Cur_Order.C_Order_ID and gm.c_invoiceline_id is null;
                    select max(coalesce(coalesce(o.enddate,o.scheddeliverydate),v_prjenddate)) into v_lzend from c_order o,c_orderline ol,c_generateinvoicemanual gm where o.c_order_id=ol.c_order_id and gm.c_orderline_id=ol.c_orderline_id and gm.c_order_id= Cur_Order.C_Order_ID and gm.c_invoiceline_id is null;
                    if v_lzend is not null and v_lzstart is not null and v_lzend=v_lzstart then v_lzend:=null; end if;
                    -- Create invoice HEADER
                    INSERT
                    INTO C_INVOICE
                      (
                        C_Invoice_ID, C_Order_ID, AD_Client_ID, AD_Org_ID,
                        IsActive, Created, CreatedBy, Updated, UpdatedBy,
                        IsSOTrx, DocumentNo, DocStatus, DocAction,
                        Processing, Processed, C_DocType_ID, C_DocTypeTarget_ID,
                        Description, SalesRep_ID,
                        DateInvoiced,
                        DatePrinted, IsPrinted, DateAcct, TaxDate, 
                        C_PaymentTerm_ID,
                        C_BPartner_ID, C_BPartner_Location_ID, AD_User_ID, POReference, Deliverylocationtext,
                        DateOrdered, IsDiscountPrinted, C_Currency_ID, PaymentRule,
                        C_Charge_ID, ChargeAmt, IsSelfService, TotalLines,
                        GrandTotal, M_PriceList_ID, C_Campaign_ID, 
                        C_Activity_ID, AD_OrgTrx_ID, User1_ID, User2_ID,isgrossinvoice,c_project_id,c_projectphase_id,c_projecttask_id,a_asset_id,deliveryrule,ispaymentshedulesummary,
                        performanceperiodstart,performanceperiodend,internalnote,schedtransactiondate, transactionreference
                      )
                      VALUES
                      (
                        p_Invoice_ID, v_orderall, Cur_Order.AD_Client_ID, Cur_Order.AD_Org_ID,
                        'Y', TO_DATE(NOW()), v_ĺinesrecord.createdby, TO_DATE(NOW()), v_ĺinesrecord.createdby , 
                        Cur_Order.IsSOTrx, v_DocumentNo, 'DR', 'CO', 
                        'N', 'N', v_DocType_ID, v_DocType_ID, 
                        v_description||coalesce(Cur_Order.Description,''), case when v_orderall is not null then Cur_Order.SalesRep_ID else v_ĺinesrecord.salesrep_id end, -- if combined invoice, take salesrep of first order
                        v_DateInvoiced, 
                        NULL, 'N', v_DateInvoiced, v_DateInvoiced, -- DateInvoiced=DateAcct
                        Cur_Order.C_PaymentTerm_ID, coalesce(v_invoicereceiver,Cur_Order.C_BPartner_ID), coalesce(v_invoiceadress,Cur_Order.BillTo_ID), Cur_Order.AD_User_ID,
                        case when (Cur_Order.IsSOTrx='Y' and v_orderall is not null) then Cur_Order.POReference else null end,
                        Cur_Order.deliverylocationtext, Cur_Order.DateOrdered, Cur_Order.IsDiscountPrinted, Cur_Order.C_Currency_ID,
                        Cur_Order.PaymentRule, Cur_Order.C_Charge_ID, Cur_Order.ChargeAmt, Cur_Order.IsSelfService,
                        0, 0, Cur_Order.M_PriceList_ID, Cur_Order.C_Campaign_ID,
                        Cur_Order.C_Activity_ID, Cur_Order.AD_OrgTrx_ID, Cur_Order.User1_ID,
                        Cur_Order.User2_ID, v_isgross, Cur_Order.c_project_id ,Cur_Order.c_projectphase_id ,Cur_Order.c_projecttask_id ,Cur_Order.a_asset_id,Cur_Order.deliveryrule,
                        case v_partialAmountFactor when 1 then 'N' else 'Y' end,
                        v_lzstart,v_lzend,v_internalnote,v_scheduledtransactiondate,v_transactionreference
                      );
                    v_lzstart:=trunc(now()+100);
                    v_lzend :=trunc(now()+100);
                    select ad_language into v_lang from c_bpartner where c_bpartner_id=coalesce(v_invoicereceiver,Cur_Order.C_BPartner_ID);
                    if v_lang is null then
                        select coalesce(ad_language,'de_DE') into v_lang from ad_client where ad_client_id=Cur_Order.AD_Client_ID;
                    end if;
                    -- Update paymentschedule
                    if v_paymentschedule_id is not null then
                              update c_order_paymentschedule set c_invoice_id=p_Invoice_ID where c_order_paymentschedule_id=v_paymentschedule_id;
                              -- Lower Pos in Payment scheduling
                              select textmodulelower into v_textshed from c_order_paymentschedule where c_order_paymentschedule_id=v_paymentschedule_id;
                              if v_textshed is not null then
                                  insert into zssi_invoice_textmodule (ZSSI_invoice_TEXTMODULE_ID, zssi_textmodule_id,C_invoice_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, LINE, ISLOWER, TEXT)
                                  values (get_uuid(),v_textshed,p_Invoice_ID,Cur_Order.AD_Client_ID,Cur_Order.AD_Org_ID,v_ĺinesrecord.createdby,v_ĺinesrecord.createdby,1,'Y',
                                                (select text from zssi_textmodule where zssi_textmodule_id=v_textshed));
                              end if;
                              select zssi_getText('PaymentSheduleInvoiceListing',v_lang) into vshedmsg ;
                              v_textinv:='';
                              for v_cur in (select i.documentno,i.dateinvoiced,i.grandtotal,i.grandtotal-i.totallines as tax, c.iso_code 
                                            from c_invoice i,c_order_paymentschedule p,c_currency c where c.c_currency_id=i.c_currency_id and
                                            p.c_order_id=Cur_Order.C_Order_ID and p.c_invoice_id=i.c_invoice_id and p.c_order_paymentschedule_id!=v_paymentschedule_id
                                            and p.c_invoice_id is not null order by p.invoicedate)
                              LOOP
                                if v_textinv!='' then v_textinv:=v_textinv||chr(13); end if;
                                v_textinv:=v_textinv||replace(replace(replace(replace(replace(vshedmsg,'@DOCUMENTNO@',v_cur.documentno),'@DOCDATE@',zssi_strdate(v_cur.dateinvoiced,v_lang)),'@GRANDTOTAL@',zssi_strNumber(v_cur.grandtotal,v_lang)),'@CURRENCY@',v_cur.iso_code),'@TAX@',zssi_strNumber(v_cur.tax,v_lang));
                              END LOOP;
                              if v_textinv!='' then
                                update c_invoice set description=v_description||chr(13)||v_textinv||coalesce(Cur_Order.Description,'') where c_invoice_id=p_Invoice_ID;
                              end if;
                              v_paymentschedule_id:=null;
                    end if;
                    v_NoRecords:=v_NoRecords + 1;
                    v_LineNo:=0;
                    -- Ierate the Lines
                    WHILE Cur_ManualGeneratedLines_ISOPEN=true 
                    LOOP
                        -- Don't copy zero  lines
                        IF(v_ĺinesrecord.pendingqty=0) THEN
                          RAISE NOTICE '%','- Skip 0 Qty line -' ;
                          Next_O_Line:=TRUE;
                          IF v_ĺinesrecord.ignoreresidue='Y' then
                                -- If ignoresidue was set on a 0-Line - It is set directly in the Order
                                update c_orderline set ignoreresidue=v_ĺinesrecord.ignoreresidue where c_orderline_id=v_ĺinesrecord.c_orderline_id;
                          END IF;
                        END IF;
                        IF(NOT Next_O_Line) THEN
                          --
                          SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('C_InvoiceLine', Cur_Order.C_Order_ID) ;
                          v_LineNo:=v_LineNo + 10;
                          RAISE NOTICE '%','    Line ' || v_ĺinesrecord.Line ;
                          v_ResultStr:='CreateInvoiceLine ';
                          v_qty:=v_ĺinesrecord.pendingqty;
                          -- On manual inserted Lines the Lineamt may be edited (User want this to be fix.). On the Screen Price and QTY are rounded. Rounded Values are written in the database. 
                          -- Recalculation is therefore necessary to reach the desired line amt.
                          -- In those cases we calculate the PriceActual.
                          -- Price Calculation is not applicable, if the user generates a whole Order Line.
                          -- In this Case, the Price is take from the order
                          -- In case of Payment scheduling the Price schould not be calculated. In this case we calculate the Quantity   
                             if (v_ĺinesrecord.qtyordered=v_ĺinesrecord.pendingqty and v_ĺinesrecord.orderprice=v_ĺinesrecord.pendingprice) or v_partialAmountFactor != 1 then
                                 v_price:=v_ĺinesrecord.pendingprice;
                             else
                                 v_price:=v_ĺinesrecord.lineamt/v_ĺinesrecord.pendingqty;
                             end if;
                             -- Payment Scheduling
                             if v_partialAmountFactor != 1 and v_ĺinesrecord.pendingqty!=v_ĺinesrecord.qtyordered and v_ĺinesrecord.pendingprice!=0 then
                                 v_qty:=v_ĺinesrecord.lineamt/v_ĺinesrecord.pendingprice;
                             end if;
                          -- 2nd UOM
                          if v_ĺinesrecord.M_Product_Uom_ID is not null then 
                            select c_uom_id into v_2nduom from m_product_uom where m_product_uom_id=v_ĺinesrecord.M_Product_Uom_ID;
                            v_qty2nduom:=v_qty;
                            SELECT c_uom_convert(v_qty2nduom ,v_2nduom,v_ĺinesrecord.C_UOM_ID,'Y') into v_qty;
                          else
                            v_qty2nduom:=null;
                          end if;
                          -- Combined Invoice / Performance period
                          if v_combined='Y' and v_ĺinesrecord.documentno!=coalesce(v_actualdoc,'#') then
                            v_lzstart:=coalesce(v_ĺinesrecord.contractdate,v_ĺinesrecord.scheddeliverydate);
                            if v_lzstart is null then  v_lzstart:=trunc(now()); end if;
                            v_lzend:= v_ĺinesrecord.enddate;
                            if v_lzend is null then  v_lzend:=trunc(now()+10000); end if;
                            if v_lzend!=trunc(now()+10000) then
                                v_textpos:= zssi_getElementTextByColumname('performanceperiod',v_lang)||' '||zssi_strDate(v_lzstart,v_lang)||' - '||zssi_strDate(v_lzend,v_lang)||', ' || zssi_getElementTextByColumname('DocumentNo',v_lang) || ': ' || v_ĺinesrecord.documentno || case when v_ĺinesrecord.textposition is not null then chr(10)||v_ĺinesrecord.textposition else '' end;
                            end if;
                            if v_lzend=trunc(now()+10000) then
                                v_textpos:= zssi_getElementTextByColumname('performanceperiod',v_lang)||' '||zssi_strDate(v_lzstart,v_lang)|| ', ' || zssi_getElementTextByColumname('DocumentNo',v_lang) || ': ' || v_ĺinesrecord.documentno || case when v_ĺinesrecord.textposition is not null then v_ĺinesrecord.textposition else '' end;                                
                            end if;
                          else
                            v_textpos:=v_ĺinesrecord.textposition;
                          end if;
                          v_actualdoc:=v_ĺinesrecord.documentno;
                          INSERT
                          INTO C_INVOICELINE
                            (
                              C_InvoiceLine_ID, AD_Client_ID, AD_Org_ID, IsActive,
                              Created, CreatedBy, Updated, UpdatedBy,
                              C_Invoice_ID, C_OrderLine_ID, Line,
                              Description, M_Product_ID, QtyInvoiced, PriceList,
                              PriceActual, PriceLimit,  C_Charge_ID,
                              ChargeAmt, C_UOM_ID,
                              C_Tax_ID,  --MODIFIED BY F.IRIAZABAL
                               M_Product_Uom_ID, PriceStd,M_InOutLine_ID,quantityorder,
                              m_attributesetinstance_id,isgrossprice,c_project_id ,c_projectphase_id ,c_projecttask_id ,a_asset_id,pricefluctuation,textposition,ispagebreak,iscombined,ispricesuppressed
                            )
                            VALUES
                            (
                              v_NextNo, v_ĺinesrecord.AD_Client_ID, v_ĺinesrecord.AD_Org_ID, 'Y',
                              TO_DATE(NOW()), v_ĺinesrecord.createdby, TO_DATE(NOW()), v_ĺinesrecord.createdby,
                              p_Invoice_ID, v_ĺinesrecord.C_OrderLine_ID, v_LineNo,
                              v_ĺinesrecord.Description, v_ĺinesrecord.M_Product_ID, v_qty, v_ĺinesrecord.PriceList,
                              v_price, v_ĺinesrecord.PriceLimit, 
                              v_ĺinesrecord.C_Charge_ID,
                              v_ĺinesrecord.ChargeAmt, v_ĺinesrecord.C_UOM_ID,
                              v_ĺinesrecord.C_Tax_ID,  --MODIFIED BY F.IRIAZABAL
                              v_ĺinesrecord.M_Product_Uom_ID, v_ĺinesrecord.PriceStd,v_ĺinesrecord.M_InOutLine_ID,v_qty2nduom,
                              v_ĺinesrecord.m_attributesetinstance_id,v_isgross,v_ĺinesrecord.c_project_id ,v_ĺinesrecord.c_projectphase_id ,
                              v_ĺinesrecord.c_projecttask_id ,v_ĺinesrecord.a_asset_id,v_ĺinesrecord.pricefluctuation,v_textpos,v_ĺinesrecord.ispagebreak,v_ĺinesrecord.iscombined,v_ĺinesrecord.ispricesuppressed

                            )
                            ;
                            -- SZ END
                        END IF;--Next_O_Line
                        ---- <<Next_O_Line>>
                        Next_O_Line:=FALSE;
                        v_ResultStr:='Fetching_OrderLine(*)';
                        -- @TODO test .... Update inoutline, if available??
                        --if v_ĺinesrecord.M_InOutLine_ID is not null then
                        --    update m_inoutline set isinvoiced='Y' where M_InOutLine_ID=v_ĺinesrecord.M_InOutLine_ID;
                        --end if;
                           update c_generateinvoicemanual set C_InvoiceLine_ID=v_NextNo  where c_generateinvoicemanual_id=v_ĺinesrecord.c_generateinvoicemanual_id;

                           FETCH Cur_ManualGeneratedLines INTO v_ĺinesrecord;
                           if NOT FOUND then
                               CLOSE Cur_ManualGeneratedLines;
                               exit;
                           end if;
                    END LOOP; -- Invoice Line from Order Lines
                    
                    -- Close cursor indicting vars.
                    Cur_ManualGeneratedLines_ISOPEN:=false;
                    
                    -- Only Invoices with Lines are making sense...
                    select count(*) into  v_count from  C_INVOICELINE where   C_INVOICE_ID=p_Invoice_ID;
                    if v_count>0 then
                        -- If configured, activate Invoice Directly..
                        if (Cur_Order.IsSOTrx='Y' and c_getconfigoption('activatesoinvoiceautomatically',Cur_Order.ad_org_id)='Y') or (Cur_Order.IsSOTrx='N' and c_getconfigoption('activatepoinvoiceautomatically',Cur_Order.ad_org_id)='Y') then
                              -- Post the generated Invoice
                              PERFORM C_INVOICE_POST(NULL, p_Invoice_ID) ; 
                        end if;  
                        if Cur_Order.IsSOTrx='Y' then     
                              --v_Message:=v_Message||', '||'@InvoiceDocumentno@ ' || zsse_htmldirectlink('../SalesInvoice/Header_Relation.html','document.frmMain.inpcInvoiceId',p_Invoice_ID,v_DocumentNo);
                              v_Message:=v_Message||'<br />'||zsse_htmlLinkDirectKey('../SalesInvoice/Header_Relation.html',p_Invoice_ID,v_DocumentNo)||'<br />';

                        else
                              --v_Message:=v_Message||', '||'@InvoiceDocumentno@ ' || zsse_htmldirectlink('../PurchaseInvoice/Header_Relation.html','document.frmMain.inpcInvoiceId',p_Invoice_ID,v_DocumentNo);
                              v_Message:=v_Message||'<br />'||zsse_htmlLinkDirectKey('../PurchaseInvoice/Header_Relation.html',p_Invoice_ID,v_DocumentNo)||'<br />';
                        end if;
                        if (select count(*) from c_project where c_project_id=Cur_Order.c_project_id and projectstatus='OP')=1 then
                            v_messtype:=2; -- Warning
                            v_Message:=v_Message||'Warnung: Das Projekt hat den Status "offen" und ist noch nicht gestartet worden. Die Rechnung wird trotzdem erstellt:'||(select value from c_project where c_project_id=Cur_Order.c_project_id);
                        end if;
                    else
                        select c_doctype_id,ad_org_id into v_DocType_ID,v_AD_Org_ID from c_invoice  where   C_INVOICE_ID=p_Invoice_ID;
                        delete  from  C_INVOICE where   C_INVOICE_ID=p_Invoice_ID;                        
                        perform ad_sequence_doctype_decrement(v_DocType_ID, v_AD_Org_ID);
                    end if; 
              end if; -- Check, if there is NO Draft INVOICE
          END LOOP; -- Order Loop
 
        ---- <<FINISH_PROCESS>>
        v_Message:='@Created@: ' || v_NoRecords||v_Message;
        IF(p_PInstance_ID IS NOT NULL) THEN
          --  Update AD_PInstance
          RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
          PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_messtype, v_Message) ;
        ELSE
          RAISE NOTICE '%','--<<C_Invoive_Create finished>> ' || v_Message ;
        END IF;

        PERFORM c_invoice_create_userexit(p_Invoice_ID);

        RETURN;
      END; --BODY
    EXCEPTION
    WHEN OTHERS THEN
    RAISE NOTICE '%',v_ResultStr ;
     v_ResultStr:= '@ERROR=' || SQLERRM;
      RAISE NOTICE '%',v_ResultStr ;
      IF(p_PInstance_ID IS NOT NULL) THEN
        -- ROLLBACK;
        PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
      ELSE
        RAISE EXCEPTION '%', SQLERRM;
      END IF;
      p_Invoice_ID:=0; -- Error Indicator
      RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;





-- Version : 2.6.00.0030
--
-- Name: m_inout_createinvoice(character varying); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION m_inout_createinvoice(p_pinstance_id character varying) RETURNS void
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
  * $Id: M_InOut_CreateInvoice.sql,v 1.7 2003/07/22 05:41:27 jjanke Exp $
  ***
  * Title: Create Invoice from Shipment
  * Description:
  * SZ: QTY in ORDER Qty if it is 2nd UOM
  *     @TODO: Ext.: Take Shipment-Assignments from M-Inout, if there
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    v_M_PriceList_Version_ID VARCHAR(32); --OBTG:VARCHAR2--
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
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
      FROM AD_PINSTANCE i
      LEFT JOIN AD_PINSTANCE_PARA p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Record_ID:=Cur_Parameter.Record_ID;
      IF(Cur_Parameter.ParameterName='M_PriceList_Version_ID') THEN
        v_M_PriceList_Version_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  M_PriceList_Version_ID=' || v_M_PriceList_Version_ID ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; -- Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    DECLARE
      Cur_Shipment RECORD;
      Cur_ShipmentLines RECORD;
      --
      v_Invoice_ID VARCHAR(32) ; --OBTG:VARCHAR2--
      v_NextNo VARCHAR(32) ; --OBTG:VARCHAR2--
      v_DocType_ID VARCHAR(32) ; --OBTG:VARCHAR2--
      v_InvoiceNo NUMERIC(10) ;
      v_DocumentNo C_INVOICE.DocumentNo%TYPE;
      v_IsDiscountPrinted CHAR(1) ;
      v_PaymentRule CHAR(1) ;
      v_C_PaymentTerm_ID VARCHAR(32) ; --OBTG:VARCHAR2--
      v_C_Currency_ID VARCHAR(32) ; --OBTG:VARCHAR2--
      v_M_PriceList_ID VARCHAR(32) ; --OBTG:VARCHAR2--
      --
      v_C_UOM_ID VARCHAR(32) ; --OBTG:VARCHAR2--
      v_C_Tax_ID VARCHAR(32) ; --OBTG:VARCHAR2--
      v_PriceList NUMERIC;
      v_PriceActual NUMERIC;
      v_PriceLimit NUMERIC;
      --
      v_LineNetAmt NUMERIC;
      v_TotalNet NUMERIC;
      v_asset character varying;
      v_project  character varying;
      -- v_Offer_ID       varchar2(32);
    BEGIN
      FOR CUR_Shipment IN
        (SELECT *  FROM M_INOUT  WHERE M_InOut_ID=v_Record_ID)
      LOOP -- Just to have all variables
        v_DocumentNo:=NULL;
        DECLARE
          Cur_CInvoiceCInvLine RECORD;
        BEGIN
          v_ResultStr:='Check Invoice exists';
          FOR Cur_CInvoiceCInvLine IN
            (SELECT i.DocumentNo,
              i.C_Invoice_ID
            FROM C_INVOICE i,
              C_INVOICELINE il,
              M_INOUTLINE iol
            WHERE i.C_Invoice_ID=il.C_Invoice_ID
              AND il.M_InOutLine_ID=iol.M_InOutLine_ID
              AND iol.M_InOut_ID=CUR_Shipment.M_InOut_ID
            )
          LOOP
            v_DocumentNo:=Cur_CInvoiceCInvLine.DocumentNo;
            v_Invoice_ID:=Cur_CInvoiceCInvLine.C_Invoice_ID;
            EXIT;
          END LOOP;
        EXCEPTION
        WHEN OTHERS THEN
          NULL;
        END;
        -- We have an Invoice
        IF(v_DocumentNo IS NOT NULL) THEN
          v_Message:='@ShipmentCreateDocAlreadyExists@ = '  || v_DocumentNo || ' (' || v_Invoice_ID || ')';
          RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
          -- Shipment must be complete
        ELSIF(CUR_Shipment.DocStatus NOT IN('CO', 'CL')) THEN
          v_Message:='@ShipmentCreateDocNotCompleted@';
          RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
          -- Create Invoice from Shipment
        ELSE
          v_ResultStr:='GetBPartnerInfo'; -- P=OnCredit
          SELECT IsDiscountPrinted,(
            CASE WHEN PaymentRulePO IS NULL THEN 'P' ELSE PaymentRulePO
            END
            ),
            PO_PaymentTerm_ID
          INTO v_IsDiscountPrinted,
            v_PaymentRule,
            v_C_PaymentTerm_ID
          FROM C_BPARTNER
          WHERE C_BPartner_ID=CUR_Shipment.C_BPartner_ID;
          -- Get PaymentTerms
          IF(v_C_PaymentTerm_ID IS NULL) THEN
            v_ResultStr:='GetPaymentTerm'; -- let it fail if no unique record
            v_Message:='@NoPaymentTerm@';
            DECLARE
              Cur_CPayTerm RECORD;
            BEGIN
              FOR Cur_CPayTerm IN
                (SELECT C_PaymentTerm_ID
                FROM C_PAYMENTTERM
                WHERE AD_Client_ID=CUR_Shipment.AD_Client_ID
                ORDER BY IsDefault DESC,
                  NetDays ASC
                )
              LOOP
                v_C_PaymentTerm_ID:=Cur_CPayTerm.C_PaymentTerm_ID;
                EXIT;
              END LOOP;
            END;
          END IF;
          --
          IF(CUR_Shipment.C_Order_ID IS NOT NULL) THEN
            v_ResultStr:='GetCurrencyInfo-Order';
            SELECT C_Currency_ID,
              M_PriceList_ID
            INTO v_C_Currency_ID,
              v_M_PriceList_ID
            FROM C_ORDER
            WHERE C_Order_ID=CUR_Shipment.C_Order_ID;
          ELSE
            v_ResultStr:='GetCurrencyInfo-PL';
            SELECT pl.C_Currency_ID,
              pl.M_PriceList_ID
            INTO v_C_Currency_ID,
              v_M_PriceList_ID
            FROM M_PRICELIST pl,
              M_PRICELIST_VERSION plv
            WHERE pl.M_PriceList_ID=plv.M_PriceList_ID
              AND M_PriceList_Version_ID=v_M_PriceList_Version_ID;
          END IF;
          --
          v_ResultStr:='GetDocTypeInfo';
          v_DocType_ID:=Ad_Get_Doctype(CUR_Shipment.AD_Client_ID, CUR_Shipment.AD_Org_ID, 'API') ;
          --
          SELECT * INTO  v_Invoice_ID FROM Ad_Sequence_Next('C_Invoice', CUR_Shipment.AD_Client_ID) ;
          SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(v_DocType_ID, CUR_Shipment.AD_Org_ID, 'Y') ;
          IF(v_DocumentNo IS NULL) THEN
            SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Invoice', CUR_Shipment.AD_Org_ID, 'Y') ;
          END IF;
          IF(v_DocumentNo IS NULL) THEN
            v_DocumentNo:=CUR_Shipment.DocumentNo; --  use the Receipt
          END IF;
          --
          RAISE NOTICE '%','  Invoice_ID=' || v_Invoice_ID || ' DocumentNo=' || v_DocumentNo ;
          v_ResultStr:='InsertInvoice ' || v_Invoice_ID;
          v_Message:='@DocumentNo@ = ' || v_DocumentNo;
          INSERT
          INTO C_INVOICE
            (
              C_Invoice_ID, C_Order_ID, AD_Client_ID, AD_Org_ID,
              IsActive, Created, CreatedBy, Updated,
              UpdatedBy, IsSOTrx, DocumentNo, DocStatus,
              DocAction, Processing, Processed, C_DocType_ID,
              C_DocTypeTarget_ID, Description, SalesRep_ID, 
              DateInvoiced, DatePrinted, IsPrinted, TaxDate,
              DateAcct, C_PaymentTerm_ID, C_BPartner_ID, C_BPartner_Location_ID, Deliverylocationtext,
              AD_User_ID, POReference, DateOrdered, IsDiscountPrinted,
              C_Currency_ID, PaymentRule, C_Charge_ID, ChargeAmt,
              TotalLines, GrandTotal, M_PriceList_ID, C_Campaign_ID,
              C_Project_ID, C_Activity_ID, AD_OrgTrx_ID, User1_ID,
              User2_ID
            )
            VALUES
            (
              v_Invoice_ID, CUR_Shipment.C_Order_ID, CUR_Shipment.AD_Client_ID, CUR_Shipment.AD_Org_ID,
               'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
              '0', 'N', v_DocumentNo, 'DR',
               'CO', 'N', 'N', v_DocType_ID,
              v_DocType_ID, CUR_Shipment.Description, CUR_Shipment.salesrep_id, 
              TO_DATE(NOW()), NULL, 'N', TO_DATE(NOW()),
              TO_DATE(NOW()), v_C_PaymentTerm_ID, CUR_Shipment.C_BPartner_ID, CUR_Shipment.C_BPartner_Location_ID,CUR_Shipment.Deliverylocationtext,
              CUR_Shipment.AD_User_ID, NULL, CUR_Shipment.DateOrdered, v_IsDiscountPrinted,
              v_C_Currency_ID, v_PaymentRule, NULL, 0,
              0, 0, v_M_PriceList_ID, CUR_Shipment.C_Campaign_ID,
              CUR_Shipment.C_Project_ID, CUR_Shipment.C_Activity_ID, CUR_Shipment.AD_OrgTrx_ID, CUR_Shipment.User1_ID,
              CUR_Shipment.User2_ID
            )
            ;
          -- Lines
          v_TotalNet:=0;
          FOR CUR_ShipmentLines IN
            (SELECT *  FROM M_INOUTLINE  WHERE M_InOut_ID=v_Record_ID)
          LOOP
            -- Get Price
            IF(CUR_ShipmentLines.C_OrderLine_ID IS NOT NULL) THEN
              v_ResultStr:='GettingPrice-Order';
              SELECT COALESCE(MAX(PriceList), 0),
                COALESCE(MAX(PriceActual), 0),
                COALESCE(MAX(PriceLimit), 0),
                COALESCE(MAX(CUR_ShipmentLines.movementqty*priceactual),0),
                MAX(c_tax_id),
                max(a_asset_id),max(c_project_id)
              INTO v_PriceList,
                v_PriceActual,
                v_PriceLimit,
                v_LineNetAmt,
                v_c_Tax_ID,v_asset ,v_project
              FROM C_ORDERLINE
              WHERE C_OrderLine_ID=CUR_ShipmentLines.C_OrderLine_ID;
            ELSE
              v_ResultStr:='GettingPrice-PList';
              SELECT COALESCE(MAX(PriceList), 0),
                COALESCE(MAX(PriceStd), 0),
                COALESCE(MAX(PriceLimit), 0)
              INTO v_PriceList,
                v_PriceActual,
                v_PriceLimit
              FROM M_PRODUCTPRICE
              WHERE M_Product_ID=CUR_ShipmentLines.M_Product_ID
                AND M_PriceList_Version_ID=v_M_PriceList_Version_ID;
              --v_C_Tax_ID:=C_Gettax(CUR_ShipmentLines.M_Product_ID, CUR_Shipment.MovementDate, CUR_Shipment.AD_Org_ID, CUR_Shipment.M_Warehouse_ID, CUR_Shipment.C_BPartner_Location_ID, CUR_Shipment.C_BPartner_Location_ID, CUR_Shipment.C_Project_ID, 'N') ;
              v_C_Tax_ID := zsfi_GetTax(CUR_Shipment.C_BPartner_Location_ID, CUR_ShipmentLines.M_Product_ID, CUR_Shipment.AD_Org_ID);
             v_PriceActual:=M_Get_Offers_Price(TO_DATE(NOW()), CUR_Shipment.C_BPartner_ID, CUR_ShipmentLines.M_Product_ID, null, CUR_ShipmentLines.MovementQty, v_M_PriceList_ID);
            v_LineNetAmt:=ROUND(M_Get_Offers_Price(TO_DATE(NOW()), CUR_Shipment.C_BPartner_ID, CUR_ShipmentLines.M_Product_ID, null, CUR_ShipmentLines.MovementQty, v_M_PriceList_ID) *CUR_ShipmentLines.MovementQty, 2) ;
            END IF;
            -- Get UOM + Tax -- VERY simplified, but should work in most cases
            v_ResultStr:='NoUOM+Tax';
            SELECT C_UOM_ID
            INTO v_C_UOM_ID
            FROM M_PRODUCT
            WHERE M_Product_ID=CUR_ShipmentLines.M_Product_ID;
            -- v_UOM_ID, v_Tax_ID
            v_ResultStr:='InsertInvoiceLine';
            SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('C_InvoiceLine', CUR_Shipment.C_Order_ID) ;
            INSERT
            INTO C_INVOICELINE
              (
                C_InvoiceLine_ID, AD_Client_ID, AD_Org_ID, IsActive,
                Created, CreatedBy, Updated, UpdatedBy,
                C_Invoice_ID, C_OrderLine_ID, M_InOutLine_ID, Line,
                Description, M_Product_ID, QtyInvoiced, PriceList,
                PriceActual, PriceLimit, LineNetAmt, C_Charge_ID,
                ChargeAmt, C_UOM_ID,
                C_Tax_ID,  --MODIFIED BY F.IRIAZABAL
                QuantityOrder, M_Product_Uom_ID, PriceStd,  a_asset_id,c_project_id
              )
              VALUES
              (
                v_NextNo, CUR_Shipment.AD_Client_ID, CUR_ShipmentLines.AD_Org_ID, 'Y',
                TO_DATE(NOW()), '100', TO_DATE(NOW()), '0', -- LineTrigger reqirement
                v_Invoice_ID, CUR_ShipmentLines.C_OrderLine_ID, CUR_ShipmentLines.M_InOutLine_ID, CUR_ShipmentLines.Line,
                CUR_ShipmentLines.Description, CUR_ShipmentLines.M_Product_ID, coalesce(CUR_ShipmentLines.quantityorder,CUR_ShipmentLines.MovementQty), v_PriceList,
                v_PriceActual, v_PriceLimit, v_LineNetAmt, NULL,
                0, v_C_UOM_ID,
                v_C_Tax_ID,  --MODIFIED BY F.IRIAZABAL
                CUR_ShipmentLines.QuantityOrder, CUR_ShipmentLines.M_Product_Uom_ID, v_PriceActual,
                v_asset ,v_project
              )
              ;
            v_TotalNet:=v_TotalNet + v_LineNetAmt;
          END LOOP; -- ShipLines
        END IF;
      END LOOP; -- All Shipments
    END;
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
  -- ROLLBACK;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ; $_$;


ALTER FUNCTION public.m_inout_createinvoice(p_pinstance_id character varying) OWNER TO tad;



CREATE OR REPLACE FUNCTION c_invoice_post(p_pinstance_id character varying, p_invoice_id character varying)
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

/* Contributions: Removed all Price-Calculations (They are done in zssi_invoiceline_trg()
         BUXFIX: Prevents Rounding-Errors.
         Withholding and DP_Management removed
         For better understandable code

01/2011: BUGFIX: Set Voided Invoices as Paid (They remained in Open Items List)
         
*************************************************************************************************************************************************************/
/*************************************************************************
  * $Id: C_Invoice_Post.sql,v 1.32 2003/07/22 05:41:27 jjanke Exp $
  ***
  * Title:  Post single Invoice
  * Description:
  *  Actions: COmplete, APprove, Reverse Correction, Void
  *
  * OpenItem Amount:
  *  - C_BPartner.SO_CreditUsed is increased
  * - if C_CashLine entry is created
  *  - C_Cash_Post creates C_Allocation
  *   - C_Allocation_Trg decreases C_BPartner.SO_CreditUsed
  *
  ************************************************************************/

  -- Logistice
  v_ResultStr VARCHAR(2000):=''; 
  v_Message VARCHAR(2000):=''; 
  v_Record_ID VARCHAR(32); 
  v_Result NUMERIC:=1; -- Success
  v_TOTAL NUMERIC;
  v_C_Settlement_Cancel_ID VARCHAR(32); 
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;

    Cur_line RECORD;
    -- Record Info
    v_Client_ID VARCHAR(32); 
    v_Org_ID VARCHAR(32); 
    v_UpdatedBy C_INVOICE.UpdatedBy%TYPE;
    v_Processing C_INVOICE.Processing%TYPE;
    v_Processed C_INVOICE.Processed%TYPE;
    v_DocAction C_INVOICE.DocAction%TYPE;
    v_DocStatus C_INVOICE.DocStatus%TYPE;
    v_DoctypeReversed_ID VARCHAR(32); 
    v_DocType_ID VARCHAR(32); 
    v_DocTypeTarget_ID VARCHAR(32); 
    v_PaymentRule C_INVOICE.PaymentRule%TYPE;
    v_PaymentTerm C_INVOICE.C_PaymentTerm_ID%TYPE;
    v_Order_ID VARCHAR(32); 
    v_DateAcct TIMESTAMP;
    v_DateInvoiced TIMESTAMP;
    v_DocumentNo C_INVOICE.DocumentNo%TYPE;
    v_BPartner_ID VARCHAR(32); 
    v_BPartner_User_ID VARCHAR(32); 
    v_IsSOTrx C_INVOICE.IsSOTrx%TYPE;
    v_Posted C_INVOICE.Posted%TYPE;
  --Added by P.SAROBE
  v_documentno_Settlement VARCHAR(40); 
  v_dateSettlement TIMESTAMP;
  v_Cancel_Processed CHAR(1);
  v_nameBankstatement VARCHAR (60); 
  v_dateBankstatement TIMESTAMP;
  v_nameCash VARCHAR (60); 
  v_dateCash TIMESTAMP;
  v_Bankstatementline_ID VARCHAR(32); 
  v_Debtpayment_ID VARCHAR(32); 
  v_CashLine_ID VARCHAR(32); 
  v_ispaid CHAR(1);
  v_Settlement_Cancel_ID VARCHAR(32); 
  --Finish added by P.Sarobe
    --
    v_GrandTotal NUMERIC:=0;
    v_TotalLines NUMERIC:=0;
    v_Currency_ID VARCHAR(32); 
    v_Multiplier NUMERIC:=1; --Correction of Business Partner Monetary Values on Credit Memos (AR) and AP Invoices 
    v_reverse NUMERIC:=1; -- Correction of qtyinvoiced on Credit Memos (AR)
    v_MultiplierARC NUMERIC:=1; -- Correction of Payments on Credit Memos (AR and AP)
    v_Amount NUMERIC:=0;--CashLine amount
    --
    v_RInvoice_ID VARCHAR(32); 
    v_RDocumentNo C_INVOICE.DocumentNo%TYPE;
    v_NextNo VARCHAR(32); 
    v_count NUMERIC;
    V_InvoiceLines_count NUMERIC;
    v_AD_Org_ID VARCHAR(32); 
    v_orderid character varying;
    v_POReference character varying;
    --
    v_SettlementDocType_ID VARCHAR(32) ; 
    v_SDocumentNo C_SETTLEMENT.DocumentNo%TYPE;
    v_settlementID VARCHAR(32):=NULL; --OBTG:varchar2--
    --
    v_FirstSales C_BPARTNER.FirstSale%TYPE;
    v_REInOutStatus M_INOUT.DocStatus%TYPE;
    v_RECount NUMERIC:=0;
    v_REDateInvoiced TIMESTAMP;
    v_REtotalQtyInvoiced NUMERIC:=0;
    v_REdeliveredQty NUMERIC:=0;
    --
    v_CumDiscount NUMERIC;
    v_OldCumDiscount NUMERIC;
    v_InvoiceLineSeqNo NUMERIC;
    v_InvoiceLine VARCHAR(32); 
    v_Discount NUMERIC;
    v_Line NUMERIC;
    v_InvoiceDiscount NUMERIC;
    v_C_Project_ID VARCHAR(32); 
    v_acctAmount NUMERIC;
    v_realAmount NUMERIC;
    v_partialAmount NUMERIC;
    Cur_InvoiceLine RECORD;
    Cur_Discount RECORD;
    Cur_CInvoiceDiscount RECORD;
    Cur_TaxDiscount RECORD;
    Cur_ReactivateInvoiceLine RECORD;
    Cur_LastContact RECORD;
    FINISH_PROCESS BOOLEAN:=FALSE;
    END_PROCESSING BOOLEAN:=FALSE;
    V_Aux NUMERIC;
    v_TargetDocBaseType C_DOCTYPE.DocBaseType%TYPE;
    v_is_included NUMERIC:=0;
    v_available_period NUMERIC:=0;
    v_is_ready AD_Org.IsReady%TYPE;
    v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
    v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
    v_org_bule_id AD_Org.AD_Org_ID%TYPE;
    
    v_PeriodStartDate TIMESTAMP;
    v_PeriodEndDate TIMESTAMP;
    v_DocNo_Org_ID AD_Sequence.AD_Org_ID%TYPE;
    v_DocBaseType C_DOCTYPE.DocBaseType%TYPE;
    v_cur RECORD;
    v_description varchar;
    v_prjcur record;
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
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
        v_UpdatedBy:=Cur_Parameter.AD_User_ID;
      END LOOP; -- Get Parameter
      RAISE NOTICE '%','  v_Record_ID=' || v_Record_ID ;
    ELSE
      RAISE NOTICE '%','--<<C_Invoive_Post>>' ;
      v_Record_ID:=p_Invoice_ID;
      select updatedby into v_UpdatedBy from c_invoice where c_invoice_id=v_Record_ID;
    END IF;
  BEGIN --BODY
/*****************************************************+





   
   Start of CHECKS
  
   
*****************************************************/
 SELECT C_INVOICE.ISSOTRX INTO v_IsSOTrx FROM C_INVOICE WHERE C_INVOICE_ID = v_Record_ID;
 IF (v_IsSOTrx = 'N') THEN
  FOR Cur_line IN
     (SELECT C_INVOICELINE.C_InvoiceLine_ID,C_INVOICELINE.LinenetAmt FROM C_INVOICELINE WHERE C_Invoice_ID = v_Record_ID
      )
      LOOP
        SELECT SUM(Amt) INTO v_acctAmount FROM C_INVOICELINE_ACCTDIMENSION  WHERE C_InvoiceLine_ID = Cur_line.C_InvoiceLine_ID;
        IF (v_acctAmount <> Cur_line.LinenetAmt) THEN
          v_Message:='@QuantitiesNotMatch@';
                RAISE EXCEPTION '%', '@QuantitiesNotMatch@' ; --OBTG:-20000--
        END IF;
      END LOOP;
 END IF;
    /**
    * Read Invoice
    */
    v_ResultStr:='ReadingInvoice';
    SELECT Processing, Processed, DocAction, DocStatus,
      C_DocType_ID, C_DocTypeTarget_ID,
      PaymentRule, C_PaymentTerm_ID, DateAcct, DateInvoiced,
      AD_Client_ID, AD_Org_ID,  DocumentNo,
      C_Order_ID, IsSOTrx, C_BPartner_ID, AD_User_ID,
      C_Currency_ID, AD_Org_ID, POReference, Posted,
      c_Project_Id
    INTO v_Processing, v_Processed, v_DocAction, v_DocStatus,
      v_DocType_ID, v_DocTypeTarget_ID,
      v_PaymentRule, v_PaymentTerm, v_DateAcct, v_DateInvoiced,
      v_Client_ID, v_Org_ID,  v_DocumentNo,
      v_Order_ID, v_IsSOTrx, v_BPartner_ID, v_BPartner_User_ID,
      v_Currency_ID, v_AD_Org_ID, v_POReference, v_Posted,
      v_C_Project_Id
    FROM C_INVOICE
    WHERE C_Invoice_ID=v_Record_ID  FOR UPDATE;
    RAISE NOTICE '%','Invoice_ID=' || v_Record_ID ||', DocAction=' || v_DocAction || ', DocStatus=' || v_DocStatus || ', DocType_ID=' || v_DocType_ID || ', DocTypeTarget_ID=' || v_DocTypeTarget_ID ;
    /**
    * Invoice Voided, Closed, or Reversed - No Action
    */
    IF(v_DocStatus IN('VO', 'CL', 'RE')) THEN
      RAISE EXCEPTION '%', '@AlreadyPosted@'; --OBTG:-20000--
    END IF;
    -- Processing of Proforma Invoice
    if v_DocType_ID='CCFE32E992B74157975E675458B844D1' then
        IF((v_DocStatus='DR' AND v_DocAction='CO')) THEN
            update c_invoice set posted='Y',processed='Y',docstatus='CO',docaction='RE' where c_invoice_id=v_Record_ID;
        end if;
        IF((v_DocStatus='CO' AND v_DocAction='RE')) THEN
             update c_invoice set posted='N',processed='N',docstatus='DR',docaction='CO' where c_invoice_id=v_Record_ID;
        end if;
        IF((v_DocStatus='CO' AND v_DocAction='VO')) THEN
            update c_invoice set posted='Y',processed='Y',docstatus='VO',docaction='VO' where c_invoice_id=v_Record_ID;
        end if;
        IF(p_PInstance_ID IS NOT NULL) THEN
                PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, v_UpdatedBy, 'N', v_Result, v_Message) ;
        end if;
        return;
    end if;
    --Allow to complete an invoice only in these cases:
    --* There are invoice lines
    --* There are tax lines
    --* There are both invoice and tax lines 
    IF((v_DocStatus='DR' AND v_DocAction='CO')) THEN
          SELECT COUNT(*)
          INTO V_InvoiceLines_count
          FROM C_INVOICE
          WHERE C_INVOICE_ID=v_Record_ID 
          AND (EXISTS (SELECT 1 FROM C_INVOICELINE WHERE C_INVOICE_ID=v_Record_ID)
                           OR EXISTS (SELECT 1 FROM C_INVOICETAX  WHERE C_INVOICE_ID=v_Record_ID));
          IF V_InvoiceLines_count=0 THEN
            RAISE EXCEPTION '%', '@InvoicesNeedLines@'; --OBTG:-20000--
          END IF;
          /*
          * Avoids repeating the same documentno for the same organization tree within the same fiscal year
          */
          SELECT PERIODSTARTDATE, PERIODENDDATE
            INTO v_PeriodStartDate, v_PeriodEndDate
            FROM (SELECT Y.C_CALENDAR_ID, Y.C_YEAR_ID,
                    MIN(P.STARTDATE) AS PERIODSTARTDATE, MAX(P.ENDDATE) AS PERIODENDDATE
                    FROM C_YEAR Y, C_PERIOD P
                    WHERE Y.C_YEAR_ID = P.C_YEAR_ID
                    AND Y.ISACTIVE = 'Y'
                    AND P.ISACTIVE = 'Y'
                    AND Y.C_CALENDAR_ID = (SELECT O.C_CALENDAR_ID 
                                            FROM AD_ORG O
                                            WHERE AD_ORG_ID = AD_ORG_GETCALENDAROWNER(v_Org_ID))
                    GROUP BY Y.C_CALENDAR_ID, Y.C_YEAR_ID) A
            WHERE PERIODSTARTDATE <= v_DateInvoiced
            AND PERIODENDDATE+1 > v_DateInvoiced ;
          IF (v_PeriodStartDate IS NOT NULL AND v_PeriodEndDate IS NOT NULL) THEN
            SELECT D.AD_ORG_ID   
              INTO v_DocNo_Org_ID
              FROM C_DOCTYPE D
              WHERE D.C_DOCTYPE_ID = v_DocTypeTarget_ID ;
            
              SELECT COUNT(*)
              INTO v_count
              FROM C_INVOICE I
              WHERE I.DOCUMENTNO = v_DocumentNo
                  AND I.C_DOCTYPETARGET_ID = v_DocTypeTarget_ID
                  AND I.DATEINVOICED >= v_PeriodStartDate
                  AND I.DATEINVOICED < v_PeriodEndDate+1 
                  AND I.C_INVOICE_ID <> v_Record_ID 
                  AND AD_ISORGINCLUDED(I.AD_ORG_ID, v_DocNo_Org_ID, I.AD_CLIENT_ID) <> -1
                  AND I.AD_CLIENT_ID = v_Client_ID ;
              IF (v_count<>0) THEN
                RAISE EXCEPTION '%', '@DifferentDocumentNo@' ; --OBTG:-20000--
              END IF;
          END IF;
    END IF;    
    /**
    * Unlock
    */
    IF(v_DocAction='XL') THEN
      UPDATE C_INVOICE
        SET Processing='N',
        DocAction='--',
        Updated=TO_DATE(NOW())
      WHERE C_Invoice_ID=v_Record_ID;
      FINISH_PROCESS:=TRUE;
    END IF;
    IF(NOT FINISH_PROCESS) THEN
      IF(v_Processing='Y') THEN
        RAISE EXCEPTION '%', '@OtherProcessActive@'; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
      /**
      * already Everything done
      */
      IF(v_Processed='Y' AND (v_DocAction NOT IN('RC', 'RE','RJ','CO') OR v_DocStatus NOT IN('CO', 'IP','NA'))) THEN
           RAISE EXCEPTION '%', '@AlreadyPosted@'; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    
       -- SZ Tax-Register - We don't use -> deleted
    
    IF(NOT FINISH_PROCESS) THEN
      /**
      * Void if Document not processed
      */
      IF(v_DocAction='VO' AND v_DocStatus NOT IN('CO', 'RE')) THEN
        SELECT COUNT(*) INTO v_Aux FROM C_DEBT_PAYMENT WHERE C_Invoice_ID = v_Record_ID;
        IF V_Aux>0 THEN
            RAISE EXCEPTION '%', '@InvoiceWithManualDP@'; --OBTG:-20000--
        ELSE
          -- Reset Lines to 0
          UPDATE C_INVOICELINE
            SET QtyInvoiced=0,
            LineNetAmt=0
          WHERE C_Invoice_ID=v_Record_ID;
          --
          UPDATE C_INVOICE
            SET DocStatus='VO',
            DocAction='--',
            Processed='Y',
            Updated=TO_DATE(NOW())
          WHERE C_Invoice_ID=v_Record_ID;
          -- paymentschedule - If Invoice Voided - Void scheduling, too
          update c_order_paymentschedule set c_invoice_id=null where c_invoice_id=v_Record_ID;
          --
        END IF;
        FINISH_PROCESS:=TRUE;
      END IF;
      -- Check Doctype
      SELECT COUNT(*) INTO v_Count FROM C_INVOICE C,  C_DOCTYPE   WHERE C_DOCTYPE.DocBaseType IN ('ARI', 'API','ARC','APC')
            AND C_DOCTYPE.IsSOTrx=C.ISSOTRX
            AND Ad_Isorgincluded(C.AD_Org_ID,C_DOCTYPE.AD_Org_ID, C.AD_Client_ID) <> -1
            AND C.C_DOCTYPETARGET_ID = C_DOCTYPE.C_DOCTYPE_ID
            AND C.C_INVOICE_ID = V_RECORD_ID;
      IF v_Count=0 THEN
          RAISE EXCEPTION '%', '@NotCorrectOrgDoctypeInvoice@'; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(v_DocAction in ('RC','RE') AND v_DocStatus='CO') THEN -- Voiding and Re-Opening is not Psible, when Active Payments exists
          SELECT COUNT(*), MAX(C_DEBT_PAYMENT_ID)
            INTO v_RECount, v_Debtpayment_ID
            FROM C_DEBT_PAYMENT
            WHERE C_DEBT_PAYMENT.C_Invoice_ID=v_Record_ID
            AND C_Debt_Payment_Status(C_Settlement_Cancel_ID, Cancel_Processed, C_DEBT_PAYMENT.Generate_Processed, IsPaid, IsValid, C_Cashline_ID, C_BankstatementLine_ID)<>'P'
            AND C_ORDER_ID IS NULL;
          IF(v_RECount<>0) THEN
              --Added by P.Sarobe. New messages
              SELECT c_Bankstatementline_Id, c_cashline_id, c_settlement_cancel_id, ispaid, cancel_processed
              INTO v_Bankstatementline_ID, v_CashLine_ID, v_Settlement_Cancel_ID, v_ispaid, v_Cancel_Processed
              FROM C_DEBT_PAYMENT WHERE C_Debt_Payment_ID = v_Debtpayment_ID;
              IF v_Bankstatementline_ID IS NOT NULL THEN
                      SELECT C_BANKSTATEMENT.NAME, C_BANKSTATEMENT.STATEMENTDATE
                          INTO v_nameBankstatement, v_dateBankstatement
                          FROM C_BANKSTATEMENT, C_BANKSTATEMENTLINE
                          WHERE C_BANKSTATEMENT.C_BANKSTATEMENT_ID = C_BANKSTATEMENTLINE.C_BANKSTATEMENT_ID
                          AND C_BANKSTATEMENTLINE.C_BANKSTATEMENTLINE_ID = v_Bankstatementline_ID;
                      RAISE EXCEPTION '%', '@ManagedDebtPaymentInvoiceBank@'||v_nameBankstatement||' '||'@Bydate@'||v_dateBankstatement ; --OBTG:-20000--
              END IF;
              IF v_CashLine_ID IS NOT NULL THEN
                      SELECT C_CASH.NAME, C_CASH.STATEMENTDATE
                        INTO v_nameCash, v_dateCash
                        FROM C_CASH, C_CASHLINE
                        WHERE C_CASH.C_CASH_ID = C_CASHLINE.C_CASH_ID
                        AND C_CASHLINE.C_CASHLINE_ID = v_CashLine_ID;
                      RAISE EXCEPTION '%', '@ManagedDebtPaymentInvoiceCash@'||v_nameCash||' '||'@Bydate@'||v_dateCash ; --OBTG:-20000--
              END IF;
              IF v_Cancel_Processed='Y' AND v_ispaid='N' THEN
                    SELECT documentno, datetrx
                      INTO v_documentno_Settlement, v_dateSettlement
                      FROM C_SETTLEMENT
                      WHERE C_SETTLEMENT_ID = v_Settlement_Cancel_ID;
                    RAISE EXCEPTION '%', '@ManagedDebtPaymentOrderCancel@'||v_documentno_Settlement||' '||'@Bydate@'||v_dateSettlement ; --OBTG:-20000--
              END IF;
            END IF; -- Count
       END IF; -- Dochaction
/*****************************************************+





   
   END of CHECKS
  
   
*****************************************************/
    IF(NOT FINISH_PROCESS) THEN
      /**************************************************************************
      * Start Processing ------------------------------------------------------
      *************************************************************************/
      v_ResultStr:='LockingInvoice';
      BEGIN -- FOR COMMIT
        UPDATE C_INVOICE  SET Processing='Y'  WHERE C_Invoice_ID=v_Record_ID;
        -- Now, needs to go to END_PROCESSING to unlock    
      EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION '%','DATA_EXCEPTION';
      END;--FOR  COMMIT
      
      BEGIN -- FOR COMMIT
        -- Set org lines like the headear
        UPDATE C_INVOICELINE SET AD_ORG_ID = (SELECT AD_ORG_ID FROM C_INVOICE WHERE C_INVOICE_ID = v_Record_ID) WHERE C_INVOICE_ID = v_Record_ID;
    
/*****************************************************+





   
  Voiding (Storno)
  
   
*****************************************************/
        /**
        * Reverse Correction requires completes invoice ========================
        */
        IF(v_DocAction='RC' AND v_DocStatus='CO') THEN
            
            v_ResultStr:='ReverseCorrection';
            -- Copy Invoice with reverese Quantities (or Amounts)
            SELECT * INTO  v_RInvoice_ID FROM Ad_Sequence_Next('C_Invoice', v_Record_ID) ;
            -- Select doctype for reversed doc
            SELECT COALESCE(C_DOCTYPE_REVERSED_ID, C_DOCTYPE_ID) INTO v_DoctypeReversed_ID FROM C_DOCTYPE WHERE C_DOCTYPE_ID=v_DocType_ID;
            -- new docNo
            SELECT * INTO  v_RDocumentNo FROM Ad_Sequence_Doctype(v_DoctypeReversed_ID, v_Org_ID, 'Y') ;
            IF(v_RDocumentNo IS NULL) THEN
              SELECT * INTO  v_RDocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Invoice', v_Org_ID, 'Y') ;
            END IF;
            v_Message:='@ReversedBy@: ' || zsse_htmlLinkDirectKey('../SalesInvoice/Header_Relation.html', v_RInvoice_ID, v_RDocumentNo) || '</br>';
            RAISE NOTICE '%','Reversal Invoice_ID=' || v_RInvoice_ID || ' DocumentNo=' || v_RDocumentNo ;
            v_ResultStr:='InsertInvoice ID=' || v_RInvoice_ID;
            -- Don't copy C_Payment_ID or C_CashLine_ID
            /**************************************************************************
            * SZ: Removed all Price-Calculations (They are done in zssi_invoiceline_trg()
            * Do not insert  TotalLines, GrandTotal
            ************************************************************************/
            INSERT
            INTO C_INVOICE
              (
                C_Invoice_ID, C_Order_ID, AD_Client_ID, AD_Org_ID,
                IsActive, Created, CreatedBy, Updated,
                UpdatedBy, IsSOTrx, DocumentNo, DocStatus,
                DocAction, Processing, Processed, C_DocType_ID,
                C_DocTypeTarget_ID, Description, SalesRep_ID,
                DateInvoiced, DatePrinted, IsPrinted, TaxDate,
                DateAcct, C_PaymentTerm_ID, C_BPartner_ID, C_BPartner_Location_ID,
                AD_User_ID, POReference, DateOrdered, IsDiscountPrinted,
                C_Currency_ID, PaymentRule, C_Charge_ID, ChargeAmt,
                M_PriceList_ID, C_Campaign_ID,
                C_Project_ID, C_Activity_ID, AD_OrgTrx_ID, User1_ID,
                User2_ID,isgrossinvoice
              )
            SELECT v_RInvoice_ID, C_Order_ID, AD_Client_ID, AD_Org_ID,
              IsActive, TO_DATE(NOW()), v_UpdatedBy, TO_DATE(NOW()),
              v_UpdatedBy, IsSOTrx, v_RDocumentNo, 'DR',
                'CO', 'N', 'N', v_DoctypeReversed_ID,
              v_DoctypeReversed_ID, '(*R*: ' || DocumentNo || ') ' || Description, SalesRep_ID,
              trunc(NOW()), NULL, 'N', trunc(NOW()),
              trunc(NOW()), C_PaymentTerm_ID, C_BPartner_ID, C_BPartner_Location_ID,
              AD_User_ID, '*R*: ' || DocumentNo, DateOrdered, IsDiscountPrinted,
              C_Currency_ID, PaymentRule, C_Charge_ID, ChargeAmt * -1,
              M_PriceList_ID, C_Campaign_ID,
              C_Project_ID, C_Activity_ID, AD_OrgTrx_ID, User1_ID,
              User2_ID,isgrossinvoice
            FROM C_INVOICE
            WHERE C_Invoice_ID=v_Record_ID;
            -- Create Reversed invoice relation
            INSERT
            INTO C_Invoice_Reverse
              (
                C_Invoice_Reverse_ID,AD_Client_ID, AD_Org_ID,
                IsActive, Created, CreatedBy, Updated,
                UpdatedBy, C_Invoice_ID, Reversed_C_Invoice_ID
              )
            SELECT get_uuid(), AD_Client_ID, AD_Org_ID,
                'Y', TO_DATE(NOW()), v_UpdatedBy, TO_DATE(NOW()),
                v_UpdatedBy, v_RInvoice_ID, C_Invoice_ID
            FROM C_INVOICE
            WHERE C_Invoice_ID=v_Record_ID;
            --
            -- Create Reversal Invoice Lines
            FOR Cur_InvoiceLine IN
              (SELECT * FROM C_INVOICELINE WHERE C_Invoice_ID=v_Record_ID  ORDER BY Line)
            LOOP
              /**************************************************************************
              * SZ: Removed all Price-Calculations (They are done in zssi_invoiceline_trg()
              * Do not insert  Linenetamt, BUT: insert isgrossprice
              ************************************************************************/
              SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('C_InvoiceLine', v_Record_ID) ;
              INSERT
              INTO C_INVOICELINE
                (
                  C_InvoiceLine_ID, AD_Client_ID, AD_Org_ID, IsActive,
                  Created, CreatedBy, Updated, UpdatedBy,
                  C_Invoice_ID, C_OrderLine_ID, M_InOutLine_ID, Line,
                  Description, M_Product_ID, QtyInvoiced, PriceList,M_Product_uom_id,quantityorder,
                  PriceActual, C_Charge_ID, ChargeAmt,
                  C_UOM_ID, C_Tax_ID, PriceStd,isgrossprice,pricefluctuation,m_attributesetinstance_id)
                VALUES
                (
                  v_NextNo, Cur_InvoiceLine.AD_Client_ID, Cur_InvoiceLine.AD_Org_ID, 'Y',
                  TO_DATE(NOW()), v_UpdatedBy, TO_DATE(NOW()), v_UpdatedBy,
                  v_RInvoice_ID, Cur_InvoiceLine.C_OrderLine_ID, Cur_InvoiceLine.M_InoutLine_ID, Cur_InvoiceLine.Line,
                    '*R*: ' || Cur_InvoiceLine.Description, Cur_InvoiceLine.M_Product_ID, Cur_InvoiceLine.QtyInvoiced * -1, Cur_InvoiceLine.PriceList,Cur_InvoiceLine.M_Product_uom_id,Cur_InvoiceLine.quantityorder*-1,
                  Cur_InvoiceLine.PriceActual, Cur_InvoiceLine.C_Charge_ID, Cur_InvoiceLine.ChargeAmt * -1,
                  Cur_InvoiceLine.C_UOM_ID, Cur_InvoiceLine.C_Tax_ID, Cur_InvoiceLine.PriceStd,Cur_InvoiceLine.isgrossprice,Cur_InvoiceLine.pricefluctuation * -1,Cur_InvoiceLine.m_attributesetinstance_id)
                ;
                update m_inoutline set isinvoiced='N' where m_inoutline_id=Cur_InvoiceLine.m_inoutline_id;
                update c_invoiceline set reinvoicedby_id=null where reinvoicedby_id=Cur_InvoiceLine.c_invoiceline_id;
            END LOOP; -- Create Reversal Invoice Lines
            -- Void ORIGINAL Invoice
            -- SZ: set s paid
            UPDATE C_INVOICE
              SET DocStatus='VO', -- it IS reversed
              Description=COALESCE(TO_CHAR(Description), '') || ' (*R* -> ' || v_RDocumentNo || ')',
              DocAction='--',
              Processed='Y',
              ispaid='Y',
              Updated=TO_DATE(NOW()),
              updatedby=v_UpdatedBy
            WHERE C_Invoice_ID=v_Record_ID;
            -- paymentschedule - If Invoice Voided - Void scheduling, too
            update c_order_paymentschedule set c_invoice_id=null where c_invoice_id=v_Record_ID;
            update c_orderline set ignoreresidue='N' where c_orderline_id=Cur_InvoiceLine.C_OrderLine_ID;
            -- Post Reversal
            PERFORM C_INVOICE_POST(NULL, v_RInvoice_ID) ;
            -- VOID the CLOSED Reverse INVOICE (Prevents any Modifications e.g. Voiding again)
             -- SZ: set s paid
            UPDATE C_INVOICE
              SET DocStatus='VO', -- the reversal transaction
              DocAction='--',
              Processed='Y',
              ispaid='Y'
            WHERE C_Invoice_ID=v_RInvoice_ID;
            -- If Payments from both invoices are pending (No Payments yet), create a new settlement and cancel them
            SELECT COUNT(*) INTO v_count FROM C_DEBT_PAYMENT dp
            WHERE C_Debt_Payment_Status(dp.C_Settlement_Cancel_ID, dp.Cancel_Processed, dp.Generate_Processed, dp.IsPaid, dp.IsValid, dp.C_CashLine_ID, dp.C_BankStatementLine_ID)<>'P'
                        AND(dp.C_Invoice_ID=v_Record_ID
                        OR dp.C_Invoice_ID=v_RInvoice_ID) ;
            -- To cancel, the sum of amounts should be 0
            IF(v_count=0) THEN
              SELECT SUM(AMOUNT) INTO v_count FROM C_DEBT_PAYMENT dp WHERE dp.C_Invoice_ID=v_Record_ID OR dp.C_Invoice_ID=v_RInvoice_ID;
              IF(v_count=0) THEN
                v_SettlementDocType_ID:=Ad_Get_Doctype(v_Client_ID, v_AD_Org_ID, TO_CHAR('STT')) ;
                SELECT * INTO  v_settlementID FROM Ad_Sequence_Next('C_Settlement', v_Record_ID) ;
                SELECT * INTO  v_SDocumentNo FROM Ad_Sequence_Doctype(v_SettlementDocType_ID, v_AD_Org_ID, 'Y') ;
                IF(v_SDocumentNo IS NULL) THEN
                  SELECT * INTO  v_SDocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Settlement', v_AD_Org_ID, 'Y') ;
                END IF;
                INSERT
                INTO C_SETTLEMENT
                  (
                    C_SETTLEMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
                    CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                    DOCUMENTNO, DATETRX, DATEACCT, SETTLEMENTTYPE,
                    C_DOCTYPE_ID, PROCESSING, PROCESSED, POSTED,
                    C_CURRENCY_ID, C_PROJECT_ID, C_CAMPAIGN_ID, C_ACTIVITY_ID,
                    USER1_ID, USER2_ID, CREATEFROM, ISGENERATED
                  )
                SELECT v_settlementID, AD_Client_ID, AD_Org_ID, 'Y',
                  TO_DATE(NOW()), UpdatedBy, TO_DATE(NOW()), UpdatedBy,
                  '*RE*'||v_SDocumentNo, TRUNC(TO_DATE(NOW())), TRUNC(TO_DATE(NOW())), 'C',
                  v_SettlementDocType_ID, 'N', 'N', 'N',
                  C_Currency_ID, C_PROJECT_ID, C_CAMPAIGN_ID, C_ACTIVITY_ID,
                  USER1_ID, USER2_ID, 'N', 'Y'
                FROM C_INVOICE
                WHERE C_Invoice_ID=v_Record_ID;
                UPDATE C_DEBT_PAYMENT
                  SET C_Settlement_Cancel_id=v_settlementID, UPDATED=TO_DATE(NOW()), UPDATEDBY=v_UpdatedBy
                WHERE C_DEBT_PAYMENT.C_Invoice_ID=v_Record_ID
                  OR C_DEBT_PAYMENT.C_Invoice_ID=v_RInvoice_ID;
                PERFORM C_SETTLEMENT_POST(NULL, v_settlementID) ;
              END IF;
            END IF;
            END_PROCESSING:=TRUE;
          END IF;
        EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION '%',SQLERRM;
      END; -- FOR COMMIT
    END IF;--FINISH_PROCESS
/*****************************************************+





   
  Voiding END

  
  
   
*****************************************************/
      IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
        /**************************************************************************
        * Credit Multiplier (Used in BP-Statistic and REACTIVATION
        *************************************************************************/
        -- Is it a Credit Memo - Or AP Invoice
        SELECT DocBaseType
        INTO v_DocBaseType
        FROM C_DOCTYPE
        WHERE C_DocType_ID=v_DocType_ID;
        IF(v_DocBaseType IN('ARC', 'API')) THEN
          v_Multiplier:=-1;
        END IF;
      END IF;--FINISH_PROCESS
      IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
        /************************************************************************
        * Actions allowed: Reactivate
        * Modified by Jon Alegria
        */
/*****************************************************+





   
  REACTIVATE COMPLETED Invoice

  
  
   
*****************************************************/
        IF(v_DocAction='RE' and v_DocStatus='CO') THEN
          
          IF(NOT END_PROCESSING) THEN
            IF(v_Posted='Y') THEN
              RAISE EXCEPTION '%', '@InvoiceDocumentPosted@'; --OBTG:-20000--
            END IF;
          END IF;--END_PROCESSING
          
          IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
            -- Pending undo not Stocked BOM's
            -- Undo BP Statictis
            --Undo first sale
            SELECT MIN(DateAcct)
            INTO v_FirstSales
            FROM C_INVOICE
            WHERE C_Invoice_ID<>v_Record_ID
              AND C_BPartner_ID=v_BPartner_ID;
            UPDATE C_BPARTNER  SET FirstSale=v_FirstSales  WHERE C_BPartner_ID=v_BPartner_ID;
            -- Undo Last contact
            FOR Cur_LastContact IN
              (SELECT Updated,
                DocumentNo,
                Ad_User_ID
              FROM C_INVOICE
              WHERE C_Invoice_ID<>v_Record_ID
                AND Ad_User_ID=v_BPartner_User_ID
              ORDER BY Updated DESC
              )
            LOOP
              UPDATE AD_USER
                SET LastContact=Cur_LastContact.Updated,
                LastResult=Cur_LastContact.DocumentNo
              WHERE AD_User_ID=Cur_LastContact.Ad_User_ID;
              EXIT;
            END LOOP;
             
            FOR Cur_ReactivateInvoiceLine IN
                (SELECT l.C_InvoiceLine_ID,
                  l.C_Orderline_ID,
                  l.M_InoutLine_ID,
                  l.QtyInvoiced,
                  l.linenetamt,
                  l.linegrossamt,
                  i.c_order_id
                FROM C_INVOICELINE l, c_invoice i
                WHERE l.c_invoice_id=i.c_invoice_id and i.C_Invoice_ID=v_Record_ID
                )
            LOOP
                -- Update M Inout
                IF(Cur_ReactivateInvoiceLine.M_InOutLine_ID IS NOT NULL) THEN
                  SELECT m.DOCSTATUS
                  INTO v_REInOutStatus
                  FROM M_INOUT m,
                    M_INOUTLINE ml
                  WHERE M.M_InOut_ID=ml.M_InOut_ID
                    AND ml.M_InOutLine_ID=Cur_ReactivateInvoiceLine.M_InOutLine_ID;
                  IF(v_REInOutStatus<>'RE') THEN
                    SELECT COALESCE(SUM(C_INVOICELINE.QTYINVOICED), 0)
                    INTO v_REtotalQtyInvoiced
                    FROM C_INVOICELINE,
                      C_INVOICE
                    WHERE C_INVOICE.C_Invoice_ID=C_INVOICELINE.C_Invoice_ID
                      AND C_INVOICE.Processed='Y'
                      AND C_INVOICELINE.M_InOutLine_ID=Cur_ReactivateInvoiceLine.M_InOutLine_ID;
                    v_REtotalQtyInvoiced:=v_REtotalQtyInvoiced - Cur_ReactivateInvoiceLine.QtyInvoiced;
                    SELECT MovementQty
                    INTO v_REdeliveredQty
                    FROM M_INOUTLINE
                    WHERE M_InOutLine_ID=Cur_ReactivateInvoiceLine.M_InOutLine_ID;
                    UPDATE M_INOUTLINE
                      SET IsInvoiced=(
                      CASE v_REtotalQtyInvoiced
                        WHEN 0
                        THEN 'N'
                        ELSE 'Y'
                      END
                      )
                    WHERE M_InOutLine_ID=Cur_ReactivateInvoiceLine.M_InOutLine_ID;
                  END IF;
                END IF;
                -- Update Order
                IF(Cur_ReactivateInvoiceLine.C_OrderLine_ID IS NOT NULL) THEN
                  SELECT MAX(C_INVOICE.DateInvoiced)
                  INTO v_REDateInvoiced
                  FROM C_INVOICE,
                    C_INVOICELINE
                  WHERE C_INVOICE.C_Invoice_ID=C_INVOICELINE.C_INVOICE_ID
                    AND C_INVOICELINE.C_ORDERLINE_ID=Cur_ReactivateInvoiceLine.C_ORDERLINE_ID
                    AND C_INVOICELINE.C_InvoiceLine_ID<>Cur_ReactivateInvoiceLine.C_InvoiceLine_ID;
                  -- Reverse QTY on Credit Memos (AR) / AP
                  if (SELECT DocBaseType FROM C_DOCTYPE  WHERE C_DocType_ID=v_DocType_ID) in ('ARC','APC') then
                      v_reverse:=-1;
                  end if;
                  -- Reverse Invoiced QTY          
                  -- Reset Ignore Rest. Due
                  UPDATE C_ORDERLINE
                      SET QtyInvoiced=QtyInvoiced - Cur_ReactivateInvoiceLine.QtyInvoiced*v_reverse,
                        invoicedamt=invoicedamt - (case Cur_ReactivateInvoiceLine.linenetamt when 0 then Cur_ReactivateInvoiceLine.linegrossamt else Cur_ReactivateInvoiceLine.linenetamt end) * v_reverse,
                        ignoreresidue='N',
                        DateInvoiced=v_REDateInvoiced
                      WHERE C_ORDERLINE.C_OrderLine_ID=Cur_ReactivateInvoiceLine.C_OrderLine_ID;
                  select c_order_id into v_orderid from C_ORDERLINE WHERE C_OrderLine_ID=Cur_ReactivateInvoiceLine.C_OrderLine_ID;
                else
                    v_orderid:=Cur_ReactivateInvoiceLine.C_Order_ID;
                end if;
                IF(v_orderid IS NOT NULL) THEN
                     UPDATE C_ORDER set invoicedamt = invoicedamt - (case Cur_ReactivateInvoiceLine.linenetamt when 0 then Cur_ReactivateInvoiceLine.linegrossamt else Cur_ReactivateInvoiceLine.linenetamt end) * v_reverse
                      WHERE C_ORDER_ID=v_orderid;
                END IF;
            END LOOP;
            -- In the header of the Order, Set the Invoiced Amt.
            
            IF(v_IsSOTrx='N') THEN
              DELETE
              FROM M_MATCHPO
              WHERE C_InvoiceLine_ID IN
                (SELECT C_InvoiceLine_ID FROM C_INVOICELINE WHERE C_Invoice_ID=v_Record_ID)
                ;
              DELETE
              FROM M_MATCHINV
              WHERE C_InvoiceLine_ID IN
                (SELECT C_InvoiceLine_ID FROM C_INVOICELINE WHERE C_Invoice_ID=v_Record_ID);
            ELSE
               -- Undo revenue and credit limit
              UPDATE C_BPARTNER
                SET ActualLifeTimeValue=ActualLifeTimeValue -(v_Multiplier *  C_Base_Convert(v_GrandTotal, v_Currency_ID, v_Client_ID, v_DateAcct, v_Org_ID))
              WHERE C_BPartner_ID=v_BPartner_ID;
            END IF;
            UPDATE C_INVOICE
              SET Processed='N',
              DocStatus='DR',
              DocAction='CO'
            WHERE C_Invoice_Id=v_Record_ID;
            --Delete automatically created records ...
            DELETE
            FROM C_CASHLINE
            WHERE ISGENERATED='Y'
              AND C_DEBT_PAYMENT_ID IN
              (SELECT C_DEBT_PAYMENT_ID FROM C_DEBT_PAYMENT WHERE C_INVOICE_ID=v_Record_ID)
              AND C_CASH_ID IN
              (SELECT C_CASH_ID FROM C_CASH WHERE PROCESSED='N')
              ;
            -- Updates the debt-payments of the cash, to make them not to point to the invoice
            UPDATE C_DEBT_PAYMENT
              SET C_INVOICE_ID=NULL
            WHERE C_Invoice_ID=v_Record_ID
              AND C_Order_ID IS NOT NULL;
            DELETE
            FROM C_DEBT_PAYMENT
            WHERE C_Invoice_ID=v_Record_ID
              AND COALESCE(IsAutomaticGenerated, 'Y')='Y'
              AND C_ORDER_ID IS NULL;
            UPDATE C_DEBT_PAYMENT
              SET IsValid='N'
            WHERE C_Invoice_ID=v_Record_ID
              AND COALESCE(IsAutomaticGenerated, 'Y')='N'
              AND C_ORDER_ID IS NULL;
            IF(v_IsSOTrx='Y') THEN
                PERFORM C_BP_SOCREDITUSED_REFRESH(v_BPartner_ID) ;
            END IF;
            END_PROCESSING:=TRUE;
          END IF;--END_PROCESSING
        END IF;
/*****************************************************+





   
  REACTIVATE COMPLETED END

  
  
   
*****************************************************/
      END IF;--FINISH_PROCESS
      IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
        /**************************************************************************
        * Actions allowed: COmplete, APprove, Reject, Reopen
        */
        IF v_DocAction not in ('CO','AP','RJ','RE') THEN
            v_Message:='@ActionNotAllowedHere@ (I-' || v_DocAction || ')';
            RAISE EXCEPTION '%', v_Message ; --OBTG:-20000--
            END_PROCESSING:=TRUE;
        END IF;
        IF(v_DocStatus not in ('IP','NA','DR')) THEN
            RAISE EXCEPTION '%', '@NotCompletedInvoice@'; --OBTG:-20000--
        END IF;
/*****************************************************+





   
  COMPLETE

  
  
   
*****************************************************/
        IF(v_DocAction='CO') THEN
          -- Check the header belongs to a organization where transactions are posible and ready to use
          SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
          INTO v_is_ready, v_is_tr_allow
          FROM C_INVOICE, AD_Org, AD_OrgType
          WHERE AD_Org.AD_Org_ID=C_INVOICE.AD_Org_ID
          AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
          AND C_INVOICE.C_INVOICE_ID=v_Record_ID;
          IF (v_is_ready='N') THEN
            RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
          END IF;
          IF (v_is_tr_allow='N') THEN
            RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
          END IF;

          SELECT AD_ORG_CHK_DOCUMENTS('C_INVOICE', 'C_INVOICELINE', v_Record_ID, 'C_INVOICE_ID', 'C_INVOICE_ID') INTO v_is_included FROM dual;
          IF (v_is_included=-1) THEN
            RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
          END IF;
          SELECT COUNT(*), MAX(M.line)
          INTO v_Count, v_line
          FROM c_invoiceline M,
            M_Product P,M_ATTRIBUTESET a
          WHERE M.M_PRODUCT_ID=P.M_PRODUCT_ID AND P.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id and a.ismandatory='Y'
            AND COALESCE(M.M_ATTRIBUTESETINSTANCE_ID, '0') = '0'
            AND ad_get_docbasetype(v_DocTypeTarget_ID)  in ('ARI','API','ARC','APC')
          AND M.c_invoice_ID=v_Record_ID;
          IF v_Count<>0 THEN
              RAISE EXCEPTION '%', '@Inline@ '||v_line||' '||'@productWithoutAttributeSet@' ; --OBTG:-20000--
          END IF;
          -- Check the period control is opened (only if it is legal entity with accounting)
          -- Gets the BU or LE of the document
          SELECT AD_GET_DOC_LE_BU('C_INVOICE', v_Record_ID, 'C_INVOICE_ID', 'LE')
          INTO v_org_bule_id
          FROM DUAL;
          
          SELECT AD_OrgType.IsAcctLegalEntity
          INTO v_isacctle
          FROM AD_OrgType, AD_Org
          WHERE AD_Org.AD_OrgType_ID = AD_OrgType.AD_OrgType_ID
          AND AD_Org.AD_Org_ID=v_org_bule_id;
          
          IF (v_isacctle='Y') THEN              
            SELECT C_CHK_OPEN_PERIOD(v_AD_Org_ID, v_DateAcct, NULL, v_DocTypeTarget_ID) 
            INTO v_available_period
            FROM DUAL;
            
            IF (v_available_period<>1) THEN
              RAISE EXCEPTION '%', '@PeriodNotAvailable@'; --OBTG:-20000--
            END IF;
          END IF;

          SELECT COUNT(*)
          INTO v_count
          FROM C_INVOICE c,
            C_BPARTNER bp
          WHERE c.C_BPARTNER_ID=bp.C_BPARTNER_ID
            AND Ad_Isorgincluded(c.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1
            AND c.C_Invoice_ID=v_Record_ID;
          IF v_count>0 THEN
            RAISE EXCEPTION '%', '@NotCorrectOrgBpartnerInvoice@' ; --OBTG:-20000--
          END IF;
          IF(NOT FINISH_PROCESS) THEN
              -- Setting Target Doctype
              v_ResultStr:='UpdateDocType';
              UPDATE C_INVOICE
                SET C_DocType_ID=C_DocTypeTarget_ID
              WHERE C_Invoice_ID=v_Record_ID;
              v_DocType_ID:=v_DocTypeTarget_ID;
          END IF;--FINISH_PROCESS
        END IF; -- DocAction COMPLETE

/*****************************************************+





   
  CLOSE END

  
  Next: APPROVE, Reject, Reopen
   
*****************************************************/

        IF(v_DocAction in ('AP','RJ','RE')) THEN
          -- Finish up -------------------------------------------------------------
            UPDATE C_INVOICE
              SET 
              C_DocType_ID=C_DocTypeTarget_ID,
              DocStatus= case when v_DocAction='AP' then 'IP' when v_DocAction='RJ' then 'NA' when v_DocAction='RE' then 'DR' end,
              Processed= case when v_DocAction='RE' then 'N' else 'Y' end,
              DocAction= case when v_DocAction='AP' then 'AP' when v_DocAction='RJ' then 'RE' when v_DocAction='RE' then 'CO' end,
              Processing='N',
              Updated=TO_DATE(NOW())
            WHERE C_Invoice_ID=v_Record_ID;
              END_PROCESSING:=TRUE;
              FINISH_PROCESS:=TRUE;
        END IF; -- Approve
      END IF;--FINISH_PROCESS
/*****************************************************+





   
  APPROVE Reject, Reopen END

  
  
   
*****************************************************/

-- Select Amts from the Invoice.
      SELECT TotalLines,GrandTotal INTO v_TotalLines,v_GrandTotal from C_INVOICE where C_Invoice_ID=v_Record_ID;
/**************************************************************************
       Update BP Statistics
*************************************************************************/
      IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
        v_ResultStr:='Updating BPartners';
        -- First Sale
        UPDATE C_BPARTNER
          SET FirstSale=v_DateAcct
        WHERE C_BPartner_ID=v_BPartner_ID
          AND FirstSale IS NULL;
        -- Last Contact, Result
        UPDATE AD_USER
          SET LastContact=TO_DATE(NOW()),
          LastResult=v_DocumentNo
        WHERE AD_User_ID=v_BPartner_User_ID;
        -- Update total revenue and credit limit
        -- It is reversed in C_Allocation_Trg
        IF(v_IsSOTrx='Y') THEN
          UPDATE C_BPARTNER
            SET ActualLifeTimeValue=ActualLifeTimeValue +(v_Multiplier *  C_Base_Convert(v_GrandTotal, v_Currency_ID, v_Client_ID, v_DateAcct, v_Org_ID))
          WHERE C_BPartner_ID=v_BPartner_ID;
        END IF;
      END IF;--FINISH_PROCESS
      IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
/**************************************************************************



Matching



*************************************************************************/
        v_ResultStr:='Matching';
        IF(v_IsSOTrx='N') THEN
          DECLARE
            -- Invoice-Receipt Match
            Cur_ILines_Receipt RECORD;
            -- Invoice-PO Match
            Cur_ILines_PO RECORD;
            v_Qty NUMERIC;
            v_MatchInv_ID VARCHAR(32) ; 
            v_MatchPO_ID VARCHAR(32) ; 
          BEGIN
            v_ResultStr:='MatchInv-Receipt';
            FOR Cur_ILines_Receipt IN
              (SELECT il.AD_Client_ID,
                il.AD_Org_ID,
                il.C_InvoiceLine_ID,
                ml.M_InOutLine_ID,
                ml.M_Product_ID,
                ml.MovementQty,
                il.QtyInvoiced,
                i.DateAcct
              FROM C_INVOICELINE il
              INNER JOIN M_INOUTLINE ml
                ON(il.M_InOutLine_ID=ml.M_InOutLine_ID)
              INNER JOIN C_INVOICE i
                ON(il.C_Invoice_ID=i.C_Invoice_ID)
              WHERE il.M_Product_ID=ml.M_Product_ID
                AND il.C_Invoice_ID=v_Record_ID
              )
            LOOP
              -- The min qty. Modified by Ismael Ciordia
              --v_Qty := Cur_ILines_Receipt.MovementQty;
              --IF (ABS(Cur_ILines_Receipt.MovementQty) > ABS(Cur_ILines_Receipt.QtyInvoiced)) THEN
              v_Qty:=Cur_ILines_Receipt.QtyInvoiced;
              --END IF;
              SELECT * INTO  v_MatchInv_ID FROM Ad_Sequence_Next('M_MatchInv', Cur_ILines_Receipt.AD_Org_ID) ;
              v_ResultStr:='InsertMatchInv ' || v_MatchInv_ID;
              RAISE NOTICE '%','  M_MatchInv_ID=' || v_MatchInv_ID || ' - ' || v_Qty ;
              INSERT
              INTO M_MATCHINV
                (
                  M_MatchInv_ID, AD_Client_ID, AD_Org_ID, IsActive,
                  Created, CreatedBy, Updated, UpdatedBy,
                  M_InOutLine_ID, C_InvoiceLine_ID, M_Product_ID, DateTrx,
                  Qty, Processing, Processed, Posted
                )
                VALUES
                (
                  v_MatchInv_ID, Cur_ILines_Receipt.AD_Client_ID, Cur_ILines_Receipt.AD_Org_ID, 'Y',
                  TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
                  Cur_ILines_Receipt.M_InOutLine_ID, Cur_ILines_Receipt.C_InvoiceLine_ID, Cur_ILines_Receipt.M_Product_ID, Cur_ILines_Receipt.DateAcct,
                  v_Qty, 'N', 'Y', 'N'
                )
                ;
            END LOOP;
            v_ResultStr:='MatchInv-PO';
            FOR Cur_ILines_PO IN
              (SELECT il.AD_Client_ID,
                il.AD_Org_ID,
                il.C_InvoiceLine_ID,
                ol.C_OrderLine_ID,
                ol.M_Product_ID,
                ol.C_Charge_ID,
                ol.QtyOrdered,
                il.QtyInvoiced,
                i.DateAcct
              FROM C_INVOICELINE il
              INNER JOIN C_ORDERLINE ol
                ON(il.C_OrderLine_ID=ol.C_OrderLine_ID)
              INNER JOIN C_INVOICE i
                ON(il.C_Invoice_ID=i.C_Invoice_ID)
              WHERE(il.M_Product_ID=ol.M_Product_ID
                OR il.C_Charge_ID=ol.C_Charge_ID)
                AND il.C_Invoice_ID=v_Record_ID
              )
            LOOP
              -- The min qty. Modified by Ismael Ciordia
              --v_Qty := Cur_ILines_PO.QtyOrdered;
              --IF (ABS(Cur_ILines_PO.QtyOrdered) > ABS(Cur_ILines_PO.QtyInvoiced)) THEN
              v_Qty:=Cur_ILines_PO.QtyInvoiced;
              --END IF;
              SELECT * INTO  v_MatchPO_ID FROM Ad_Sequence_Next('M_MatchPO', Cur_ILines_PO.AD_Org_ID) ;
              v_ResultStr:='InsertMatchPO ' || v_MatchPO_ID;
              RAISE NOTICE '%','  M_MatchPO_ID=' || v_MatchPO_ID || ' - ' || v_Qty ;
              INSERT
              INTO M_MATCHPO
                (
                  M_MatchPO_ID, AD_Client_ID, AD_Org_ID, IsActive,
                  Created, CreatedBy, Updated, UpdatedBy,
                  C_OrderLine_ID, M_InOutLine_ID, C_InvoiceLine_ID, M_Product_ID,
                  DateTrx, Qty, Processing, Processed,
                  Posted
                )
                VALUES
                (
                  v_MatchPO_ID, Cur_ILines_PO.AD_Client_ID, Cur_ILines_PO.AD_Org_ID, 'Y',
                  TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
                  Cur_ILines_PO.C_OrderLine_ID, NULL, Cur_ILines_PO.C_InvoiceLine_ID, Cur_ILines_PO.M_Product_ID,
                  Cur_ILines_PO.DateAcct, v_Qty, 'N', 'Y',
                   'N'
                )
                ;
            END LOOP;
          END;
        END if; --Purchase Transaction
        DECLARE
            CurLines RECORD;
            p_DateInvoiced TIMESTAMP;
            v_totalQtyInvoiced NUMERIC;
            v_ODocumentNo C_ORDER.DocumentNo%TYPE;
            v_NewPendingToInvoice NUMERIC;            
            v_deliveredQty NUMERIC;
            v_inOutStatus VARCHAR(60) ; 
            v_ignoreresidue character;
           
        BEGIN
            SELECT DateInvoiced
            INTO p_DateInvoiced
            FROM C_INVOICE
            WHERE C_Invoice_ID=v_Record_ID;
            FOR CurLines IN
              (SELECT l.C_OrderLine_ID,l.QtyInvoiced,l.linenetamt,l.linegrossamt,l.M_InOutLine_ID,l.line,i.c_order_id ,l.c_invoiceline_id
                      FROM C_INVOICELINE l, c_invoice i  WHERE i.c_invoice_id=l.c_invoice_id and i.C_INVOICE_ID=v_Record_ID  ORDER BY line)
            LOOP
              -- Update INOUT- Mark as Invoiced
              IF(CurLines.M_InOutLine_ID IS NOT NULL) THEN
                SELECT m.DOCSTATUS
                INTO v_inOutStatus
                FROM M_INOUT m,
                  M_INOUTLINE ml
                WHERE M.M_InOut_ID=ml.M_InOut_ID
                  AND ml.M_InOutLine_ID=CurLines.M_InOutLine_ID;
                IF(v_inOutStatus<>'RE') THEN
                  SELECT COALESCE(SUM(C_INVOICELINE.QTYINVOICED), 0)
                  INTO v_totalQtyInvoiced
                  FROM C_INVOICELINE,
                    C_INVOICE
                  WHERE C_INVOICE.C_Invoice_ID=C_INVOICELINE.C_Invoice_ID
                    AND C_INVOICE.Processed='Y'
                    AND C_INVOICELINE.M_InOutLine_ID=CurLines.M_InOutLine_ID;
                  v_totalQtyInvoiced:=v_totalQtyInvoiced + CurLines.QtyInvoiced;
                  SELECT MovementQty
                  INTO v_deliveredQty
                  FROM M_INOUTLINE
                  WHERE M_InOutLine_ID=CurLines.M_InOutLine_ID;
                  UPDATE M_INOUTLINE
                    SET IsInvoiced=(
                    CASE v_totalQtyInvoiced
                      WHEN 0
                      THEN 'N'
                      ELSE 'Y'
                    END
                    )
                  WHERE M_InOutLine_ID=CurLines.M_InOutLine_ID;
                END IF;
              END IF;
              -- Reverse QTY on Credit Memos (AR/AP)
              if (SELECT DocBaseType FROM C_DOCTYPE  WHERE C_DocType_ID=v_DocType_ID) in ('ARC','APC') then
                   v_reverse:=-1;
              end if;
              -- Update Orderlines
              IF CurLines.C_OrderLine_ID IS NOT NULL THEN
                  select ignoreresidue into v_ignoreresidue from  c_generateinvoicemanual where c_invoiceline_id=CurLines.c_invoiceline_id;
                  -- SZ Update orderline
                  UPDATE C_ORDERLINE
                  SET QtyInvoiced= QtyInvoiced + CurLines.QtyInvoiced*v_reverse,
                  invoicedamt=invoicedamt + (case CurLines.linenetamt when 0 then CurLines.linegrossamt else CurLines.linenetamt end) * v_reverse,
                  DateInvoiced=p_DateInvoiced,
                  ignoreresidue= case v_reverse when -1 then 'N' else coalesce(v_ignoreresidue,'N') end
                  WHERE C_OrderLine_ID=CurLines.C_OrderLine_ID;
                  select c_order_id into v_orderid from C_ORDERLINE WHERE C_OrderLine_ID=CurLines.C_OrderLine_ID;
              else
                  v_orderid:=CurLines.C_Order_ID;
              end if;
              IF(v_orderid IS NOT NULL) THEN
                     UPDATE C_ORDER set invoicedamt=invoicedamt + (case CurLines.linenetamt when 0 then CurLines.linegrossamt else CurLines.linenetamt end) * v_reverse
                      WHERE C_ORDER_ID=v_orderid;
              END IF;
              
            END LOOP;
        END;
      END IF;--FINISH_PROCESS
/**************************************************************************


Matching END



*************************************************************************/



/**************************************************************************


 CREATE PAYMENTS



*************************************************************************/
      IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
        -- Modified by Ismael Ciordia
        -- Generate C_Debt_Payment linked to this invoice
        -- SZ Nearly Reimplemented...
        DECLARE
          v_totalCash NUMERIC:=0;
          v_processed CHAR(1):='N';
          v_debtPaymentID VARCHAR(32) ; --OBTG:varchar2--
          v_amount NUMERIC;
          v_cashBook VARCHAR(32) ; 
          v_bankAccount VARCHAR(32) ; 
          v_cash VARCHAR(32) ; 
          v_IsoCode C_CURRENCY.ISO_CODE%TYPE;
          v_CashLine VARCHAR(32) ; 
          v_line NUMERIC ;
          v_BPartnerName C_BPARTNER.NAME%TYPE;
          v_GenDP_Org VARCHAR(32); 
        BEGIN
          v_ResultStr:='Generating C_Debt_Payment';
          UPDATE C_DEBT_PAYMENT
            SET C_INVOICE_ID=v_Record_ID
          WHERE EXISTS
            (SELECT 1
            FROM C_ORDERLINE ol,
              C_INVOICELINE il
            WHERE ol.C_ORDERLINE_ID=il.C_ORDERLINE_ID
              AND il.C_INVOICE_ID=v_Record_ID
              AND ol.C_ORDER_ID=C_DEBT_PAYMENT.C_ORDER_ID
            )
            AND C_INVOICE_ID IS NULL;
          UPDATE C_DEBT_PAYMENT
            SET IsValid='Y'
          WHERE C_INVOICE_ID=v_Record_ID
            AND IsValid!='Y';

          -- Is it a Credit Memo:4 - Negative-Amt's
          SELECT DocBaseType
          INTO v_TargetDocBaseType
          FROM C_DOCTYPE
          WHERE C_DocType_ID=v_DocTypeTarget_ID;
          -- Credit Memos have Reverse Payment
          IF v_TargetDocBaseType in ('ARC','APC') THEN
            v_MultiplierARC:=-1;
          END IF;

          --Sums debt payments from the order and the ones that have been inserted manually, added by ALO
          SELECT COALESCE(SUM(C_Currency_Round(C_Currency_Convert((Amount + WriteOffAmt)*v_MultiplierARC, C_Currency_ID, v_Currency_ID, v_DateInvoiced, NULL, v_Client_ID, v_Org_ID), v_Currency_ID, NULL)), 0)
          INTO v_totalCash
          FROM C_DEBT_PAYMENT_V dp
          WHERE C_INVOICE_ID=v_Record_ID;
          --Insert C_Debt_Payment if GrandTotal - v_totalCash <> 0;
          IF(v_GrandTotal<>v_totalCash) THEN
            DECLARE
              CUR_PAYMENTS RECORD;
              v_plannedDate TIMESTAMP;
              v_pendingAmount NUMERIC;
              v_paymentAmount NUMERIC;
              v_GenDebt_PaymentID VARCHAR(32); --OBTG:varchar2--
              v_SettlementDocTypeID VARCHAR(32) ; --OBTG:varchar2--
              v_settlement_ID VARCHAR(32) ; 
              v_CB_Curr VARCHAR(32) ; 
              v_SDocument_No C_SETTLEMENT.DocumentNo%TYPE;
            BEGIN
              IF v_IsSOTrx ='Y' THEN
                v_pendingAmount:=v_GrandTotal - v_totalCash;
              ELSE
                v_pendingAmount:=v_GrandTotal + v_totalCash;
              END IF;
              FOR CUR_PAYMENTS IN
                (SELECT LINE,
                  PERCENTAGE,
                  ONREMAINDER,
                  EXCLUDETAX,
                  COALESCE(PAYMENTRULE, v_PaymentRule) AS PAYMENTRULE,
                  FIXMONTHDAY,
                  FIXMONTHDAY2,
                  FIXMONTHDAY3,
                  NETDAYS,
                  FIXMONTHOFFSET,
                  NETDAY,
                  ISNEXTBUSINESSDAY
                FROM C_PAYMENTTERMLINE
                WHERE C_PAYMENTTERM_ID=v_PaymentTerm
                UNION
                  -- Header of paymentTerm is processed at last
                SELECT 9999 AS LINE,
                  100 AS PERCENTAGE,
                   'Y' AS ONREMAINDER,
                   'N' AS EXCLUDETAX,
                  v_PaymentRule AS PAYMENTRULE,
                  FIXMONTHDAY,
                  FIXMONTHDAY2,
                  FIXMONTHDAY3,
                  NETDAYS,
                  FIXMONTHOFFSET,
                  NETDAY,
                  ISNEXTBUSINESSDAY
                FROM C_PAYMENTTERM
                WHERE C_PAYMENTTERM_ID=v_PaymentTerm
                ORDER BY LINE
                )
              LOOP
                IF(CUR_PAYMENTS.PaymentRule IN('B', 'C')) THEN
                  SELECT MAX(C_CashBook_ID)
                  INTO v_cashBook
                  FROM C_CASHBOOK
                  WHERE AD_Client_ID=v_Client_ID
                    AND isActive='Y'
                    AND isDefault='Y'
                    AND AD_IsOrgIncluded(v_ad_org_id,AD_ORG_ID, AD_Client_ID)<>-1;
                  IF v_cashBook IS NULL THEN
                      RAISE EXCEPTION '%', '@NoDefaultCashBook@'; --OBTG:-20000--
                  END IF;
                  v_bankAccount:=NULL;
                ELSE
                  SELECT COALESCE((
                    CASE v_IsSOTrx
                      WHEN 'Y'
                      THEN SO_BankAccount_ID
                      ELSE PO_BankAccount_ID
                    END
                    ),
                    (SELECT MAX(C_BankAccount_ID)
                    FROM C_BANKACCOUNT
                    WHERE AD_Client_ID=v_Client_ID
                      AND AD_IsOrgIncluded(v_ad_org_id,AD_ORG_ID, AD_Client_ID)<>-1
                      AND isDefault='Y'
                    )
                    )
                  INTO v_bankAccount
                  FROM C_BPARTNER
                  WHERE c_BPartner_ID=v_BPartner_ID;
                  v_cashBook:=NULL;
                END IF;
                select schedtransactiondate into v_plannedDate from c_invoice where c_invoice_id=v_Record_ID;
                if v_plannedDate is null then
                      v_plannedDate:=C_Paymentduedate(v_BPartner_ID, v_IsSOTrx, CUR_PAYMENTS.FixMonthDay, CUR_PAYMENTS.FixMonthDay2, CUR_PAYMENTS.FixMonthDay3, CUR_PAYMENTS.NetDays, CUR_PAYMENTS.FixMonthOffset, CUR_PAYMENTS.NetDay, CUR_PAYMENTS.IsNextbusinessday, v_DateInvoiced) ;
                end if;
                SELECT COALESCE(SUM(C_DEBT_PAYMENT_V.AMOUNT),0) INTO v_partialAmount
                FROM C_DEBT_PAYMENT_V, C_DEBT_PAYMENT
                WHERE C_DEBT_PAYMENT_V.C_INVOICE_ID = V_RECORD_ID
                AND C_DEBT_PAYMENT_V.C_DEBT_PAYMENT_ID = C_DEBT_PAYMENT.C_DEBT_PAYMENT_ID
                AND ISAUTOMATICGENERATED='N';
                IF(CUR_PAYMENTS.EXCLUDETAX='Y') THEN
                  -- if excludeTax = 'Y', percentage is aplied on the TotalLines
                  v_paymentAmount:=C_Currency_Round((v_TotalLines-v_partialAmount) *CUR_PAYMENTS.PERCENTAGE/100, v_Currency_ID, NULL) ;
                ELSIF(CUR_PAYMENTS.ONREMAINDER='N') THEN
                  -- if onRemainder = 'N', percentage is aplied on the GrandTotal
                  v_paymentAmount:=C_Currency_Round((v_GrandTotal-v_partialAmount) *CUR_PAYMENTS.PERCENTAGE/100, v_Currency_ID, NULL) ;
                ELSE
                  v_paymentAmount:=C_Currency_Round((v_pendingAmount) *CUR_PAYMENTS.PERCENTAGE/100, v_Currency_ID, NULL) ;
                END IF;
                v_pendingAmount:=v_pendingAmount - v_paymentAmount;
                SELECT * INTO  v_debtPaymentID FROM Ad_Sequence_Next('C_Debt_Payment', v_Record_ID) ;
                INSERT
                INTO C_DEBT_PAYMENT
                  (
                    C_DEBT_PAYMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
                    CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                    ISRECEIPT, C_SETTLEMENT_CANCEL_ID, C_SETTLEMENT_GENERATE_ID, DESCRIPTION,
                    C_INVOICE_ID, C_BPARTNER_ID, C_CURRENCY_ID, C_CASHLINE_ID,
                    C_BANKACCOUNT_ID, C_CASHBOOK_ID, PAYMENTRULE, ISPAID,
                    AMOUNT, WRITEOFFAMT, DATEPLANNED, ISMANUAL,
                    ISVALID, C_BANKSTATEMENTLINE_ID, CHANGESETTLEMENTCANCEL, CANCEL_PROCESSED,
                    GENERATE_PROCESSED, c_project_id, status, status_initial
                  )
                  VALUES
                  (v_debtPaymentID, v_Client_ID, v_Org_ID, 'Y',
                    TO_DATE(NOW()), v_UpdatedBy, TO_DATE(NOW()), v_UpdatedBy,
                    v_IsSOTrx, NULL, NULL, '* ' || v_DocumentNo || ' * (' || COALESCE(TO_CHAR(v_BPartnerName) ,'') ||( CASE WHEN v_POReference IS NULL THEN '' ELSE ' .Ref:'||TO_CHAR(v_POReference) END) || ' )',
                    v_Record_ID, v_BPartner_ID, v_Currency_ID, NULL,
                    v_bankAccount, v_cashBook, CUR_PAYMENTS.PaymentRule, 'N',
                    C_Currency_Round((v_paymentamount *v_multiplierarc), v_Currency_ID, NULL), 0, v_plannedDate, 'N',
                    'Y', NULL, 'N', 'N',
                    'N', v_C_Project_Id, 'DE', 'DE');
                --AL
                --Looking for autogenerated debt-payments
                -- SZ removed join in remittance
                SELECT MAX(c_Debt_Payment_Id), MAX(ad_Org_ID)
                INTO v_GenDebt_PaymentID, v_GenDP_Org
                FROM C_DEBT_PAYMENT DP
                WHERE C_BPartner_ID=v_BPartner_ID
                  AND C_Debt_Payment_Status(C_Settlement_Cancel_ID, Cancel_Processed, Generate_Processed, IsPaid, IsValid, C_Cashline_ID, C_BankstatementLine_ID)='P'
                  AND(-1) *Amount=v_paymentAmount
                  AND c_currency_ID=v_Currency_ID
                  AND C_SETTLEMENT_GENERATE_ID IS NOT NULL
                  AND Ad_Isorgincluded(v_ad_Org_id, dp.ad_org_id,v_Client_ID) != -1
                  AND ad_client_id = v_Client_ID
                  AND EXISTS (SELECT 1
                                FROM C_SETTLEMENT S
                               WHERE DP.C_SETTLEMENT_GENERATE_ID = S.C_Settlement_ID
                                 AND IsGenerated = 'Y');
/*
                IF v_GenDebt_PaymentID IS NOT NULL THEN
                  v_SettlementDocTypeID:=Ad_Get_Doctype(v_Client_ID, v_GenDP_Org, TO_CHAR('STT')) ;
                  SELECT * INTO  v_settlement_ID FROM Ad_Sequence_Next('C_Settlement', v_Record_ID) ;
                  SELECT * INTO  v_SDocument_No FROM Ad_Sequence_Doctype(v_SettlementDocTypeID, v_GenDP_Org, 'Y') ;
                  IF(v_SDocument_No IS NULL) THEN
                    SELECT * INTO  v_SDocument_No FROM Ad_Sequence_Doc('DocumentNo_C_Settlement', v_GenDP_Org, 'Y') ;
                  END IF;
                  INSERT
                  INTO C_SETTLEMENT
                    (
                      C_SETTLEMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
                      CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                      DOCUMENTNO, DATETRX, DATEACCT, SETTLEMENTTYPE,
                      C_DOCTYPE_ID, PROCESSING, PROCESSED, POSTED,
                      C_CURRENCY_ID, ISGENERATED
                    )
                    --, C_PROJECT_ID, C_CAMPAIGN_ID,
                    --C_ACTIVITY_ID, USER1_ID, USER2_ID, CREATEFROM)
                    VALUES
                    (
                      v_Settlement_ID, v_Client_ID, v_GenDP_Org, 'Y',
                      TO_DATE(NOW()), v_UpdatedBy, TO_DATE(NOW()), v_UpdatedBy,
                      '*C*'||v_SDocument_No, TRUNC(TO_DATE(NOW())), TRUNC(TO_DATE(NOW())), 'C',
                      v_SettlementDocTypeID, 'N', 'N', 'N',
                      v_Currency_ID, 'Y'
                    )
                    ;
                  UPDATE C_DEBT_PAYMENT
                    SET C_Settlement_Cancel_Id=v_Settlement_ID,
                    Updated=TO_DATE(NOW()),
                    UpdatedBy=v_UpdatedBy
                  WHERE c_Debt_Payment_ID IN(v_genDebt_PaymentID, v_debtPaymentID) ;
                  PERFORM C_SETTLEMENT_POST(NULL, v_Settlement_ID) ;
                END IF;
*/                
                --If Invoice.paymentRule = 'B', insert de cashline de tipo efecto apuntando al efecto
                IF(v_cashBook IS NOT NULL AND CUR_PAYMENTS.PaymentRule='B') THEN
                  SELECT MAX(C.C_CASH_ID)
                  INTO v_Cash
                  FROM C_CASH C
                  WHERE C.C_CASHBOOK_ID=v_cashBook
                    AND TRUNC(C.DATEACCT)=TRUNC(v_DateAcct)
                    AND C.PROCESSED='N';

         SELECT C_CURRENCY_ID
           INTO v_CB_Curr
           FROM C_CASHBOOK
         WHERE C_CASHBOOK_ID = v_cashBook;

                  IF(v_Cash IS NULL) THEN
                    v_ResultStr:='Creating C_Cash';
                    SELECT ISO_CODE
                    INTO v_IsoCode
                    FROM C_CURRENCY
                    WHERE C_Currency_ID=v_CB_Curr;
                    SELECT * INTO  v_Cash FROM Ad_Sequence_Next('C_Cash', v_Record_ID) ;
                    INSERT
                    INTO C_CASH (
                        C_Cash_ID, AD_Client_ID, AD_Org_ID, IsActive,
                        Created, CreatedBy, Updated, UpdatedBy,
                        C_CashBook_ID, NAME, StatementDate, DateAcct,
                        BeginningBalance, EndingBalance, StatementDifference, Processing,
                        Processed, Posted )
                      VALUES (v_Cash, v_Client_ID, v_Org_ID, 'Y',
                        TO_DATE(NOW()), v_UpdatedBy, TO_DATE(NOW()), v_UpdatedBy,
                        v_cashBook, (TO_CHAR(v_DateAcct, 'YYYY-MM-DD') || ' ' || v_IsoCode), v_DateAcct, v_DateAcct,
                        0, 0, 0, 'N',
                         'N', 'N');
                  END IF; -- v_Cash IS NULL
                  v_ResultStr:='Creating C_CashLine';
                  SELECT * INTO  v_CashLine FROM Ad_Sequence_Next('C_CashLine', v_Record_ID) ;
                  SELECT COALESCE(MAX(LINE), 0) + 10
                  INTO v_line
                  FROM C_CASHLINE
                  WHERE C_CASH_ID=v_Cash;





                                SELECT SUM(AMOUNT) INTO v_Amount
                                FROM C_DEBT_PAYMENT_V
                                WHERE C_INVOICE_ID = v_Record_ID;
                                select description into v_description from c_invoiceline where c_invoice_id=v_Record_ID order by line limit 1;
                                INSERT
                                INTO C_CASHLINE
                                (
                                C_CashLine_ID, AD_Client_ID, AD_Org_ID, IsActive,
                                Created, CreatedBy, Updated, UpdatedBy,
                                C_Cash_ID, C_Debt_Payment_ID, Line, Description,
                                Amount, CashType, C_Currency_ID, DiscountAmt,
                                WriteOffAmt, IsGenerated
                                )
                                VALUES
                                (
                                v_CashLine, v_Client_ID, v_Org_ID, 'Y',
                                TO_DATE(TO_DATE(NOW())), v_UpdatedBy, TO_DATE(TO_DATE(NOW())), v_UpdatedBy,
                                v_Cash, v_debtPaymentID, v_line, coalesce(v_BPartnerName||'-','')||coalesce(v_description,''),
                                v_Amount, 'P', v_Currency_ID, 0,
                                0, 'Y'
                                )
                                ;

                END IF; -- v_cashBook IS NOT NULL
              END LOOP;
            END;
          END IF; -- v_GrandTotal <> v_totalCash
        END;
        IF(NOT FINISH_PROCESS AND v_IsSOTrx='Y') THEN
          PERFORM C_BP_SOCREDITUSED_REFRESH(v_BPartner_ID) ;
        END IF;
      END IF;--FINISH_PROCESS
/**************************************************************************


  PAYMENTS END



*************************************************************************/
      IF(NOT FINISH_PROCESS AND NOT END_PROCESSING) THEN
        -- Finish up -------------------------------------------------------------
        UPDATE C_INVOICE
          SET DocStatus='CO',
          Processed='Y',
          DocAction='RE',
          Updated=TO_DATE(NOW())
        WHERE C_Invoice_ID=v_Record_ID;
      END IF;--FINISH_PROCESS
      IF(NOT FINISH_PROCESS) THEN
        -- End Processing --------------------------------------------------------
        ---- <<END_PROCESSING>>
        v_ResultStr:='UnLockingInvoice';
        UPDATE C_INVOICE
          SET Processing='N',
          Updated=TO_DATE(NOW()),
          UpdatedBy=v_UpdatedBy
        WHERE C_Invoice_ID=v_Record_ID;
        -- Commented by cromero 19102006 IF(p_PInstance_ID IS NOT NULL) THEN
        -- Commented by cromero 19102006   -- COMMIT;
        -- Commented by cromero 19102006 END IF;
      END IF;--FINISH_PROCESS

    
    -- Call User Exit Function
    select  v_message||c_invoice_post_userexit(v_Record_ID) into v_message;
---- <<FINISH_PROCESS>>
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, v_UpdatedBy, 'N', v_Result, v_Message) ;
    ELSE
      RAISE NOTICE '%','--<<C_Invoive_Post finished>> ' || v_Message ;
    END IF;
    -- Schedule Update Project Status Process
    for v_prjcur in (select c_project_id from c_invoiceline where c_invoice_id=v_Record_ID and c_project_id is not null)
    LOOP
        perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
    END LOOP;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%',v_ResultStr ;
     v_ResultStr:= '@ERROR=' || SQLERRM;
      RAISE NOTICE '%',v_ResultStr ;
      IF(p_PInstance_ID IS NOT NULL) THEN
        -- ROLLBACK;
        PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
      ELSE
        RAISE EXCEPTION '%', SQLERRM;
      END IF;
  -- Commented by cromero 19102006 RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_invoice_post(character varying, character varying) OWNER TO tad;
 
 
-- User Exit to c_invoice_post
CREATE or replace FUNCTION c_invoice_post_userexit(p_invoice_id varchar) RETURNS varchar
AS $_$
DECLARE
  BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_invoice_trg() RETURNS trigger
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
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011-2017 Stefan Zimmermann
***************************************************************************************************************************************************/
   v_n NUMERIC; 
   v_count NUMERIC; 
   v_IsGross varchar;
   v_cur_line record;
   v_iscalcenabled varchar;
   v_dummy numeric;
   v_uom varchar;
   v_salesregion                     varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
    IF TG_OP = 'INSERT' THEN
        new.c_doctype_id=new.c_doctypetarget_id;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        if old.c_doctypetarget_id!=new.c_doctypetarget_id then
            new.c_doctype_id=new.c_doctypetarget_id;
        end if;
    END IF;
    -- Currency of Pricelist=currency of Invoice
    IF TG_OP = 'INSERT' THEN
        select c_currency_id into new.c_currency_id from m_pricelist where m_pricelist_id=new.m_pricelist_id;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        if new.m_pricelist_id!=old.m_pricelist_id then
            select c_currency_id into new.c_currency_id from m_pricelist where m_pricelist_id=new.m_pricelist_id;
        end if;
    END IF;
    -- Proforma Invoice always is posted
    IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
       if new.docstatus in ('CO','VO') and new.c_doctype_id='CCFE32E992B74157975E675458B844D1' then
         new.posted='Y';
       end if;
    end if;
    -- Check Duplicate Document Numbers
    IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
       select count(*) into v_n from c_invoice where documentno=new.documentno and c_doctype_id=new.c_doctype_id and c_invoice_id!=new.c_invoice_id;
       if v_n>0 then
          RAISE EXCEPTION '%', '@DuplicateDocNo@' ;
       end if;
       -- Get EMail setting
        select isinvoicebyemail,c_salesregion_id into new.isinvoicebyemail,v_salesregion from c_bpartner_location where c_bpartner_location_id=new.c_bpartner_location_id;
        -- Implementing Sales Region.
        if TG_OP = 'INSERT' and new.c_salesregion_id is null then
            new.c_salesregion_id:=v_salesregion;
        end if;
        if TG_OP = 'UPDATE'  then
            if new.c_bpartner_location_id!=old.c_bpartner_location_id and coalesce(new.c_salesregion_id,'')=coalesce(old.c_salesregion_id,'') then
                new.c_salesregion_id:=v_salesregion;
            end if;
        end if;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF (COALESCE(OLD.C_BPartner_ID, '0')!=COALESCE(NEW.C_BPartner_ID, '0')) OR (COALESCE(OLD.M_PriceList_ID,'0') != COALESCE(NEW.M_PriceList_ID,'0'))
            OR OLD.ad_org_ID != NEW.ad_org_ID  THEN
        SELECT COUNT(*)
            INTO v_count
            FROM C_invoiceline
        WHERE C_invoice_ID = NEW.C_invoice_ID;
        IF v_count>0 THEN
            RAISE EXCEPTION '%', '@existingLines@' ; --OBTG:-20502--@existingLines@
        END IF;
        END IF;
    END IF;
     -- Set Checkbox for Gross Invoice Handling
    IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
       select IsTaxIncluded into v_IsGross from m_pricelist where m_pricelist_id=new.m_pricelist_id;
       if v_IsGross is not null then
            new.isgrossinvoice:=v_IsGross;
            /*
            if v_IsGross='Y' and ad_get_docbasetype(new.c_doctype_id) not in ('API','ARI') and new.c_doctype_id != '0' then
                RAISE EXCEPTION '%', 'Gross Invoice is not allowed for this Document Type.' ;
            end if;
            */
       end if;
       if ad_get_docbasetype(new.c_doctypetarget_id) = ('API')  then
            if (select count(*) from c_invoice where c_bpartner_id=new.c_bpartner_id and poreference=new.poreference and 
                       c_doctypetarget_id=new.c_doctypetarget_id and c_invoice_id!=new.c_invoice_id)>0 then 
                RAISE EXCEPTION '%', '@DuplicateDocNoREF@' ;
            end if;
       end if;
    END IF;
    -- If invoice is processed, is not allowed to change C_BPartner
    IF TG_OP = 'UPDATE' THEN  

            IF(OLD.Processed='Y'
                    AND ((COALESCE(OLD.C_BPartner_ID, '0') <> COALESCE(NEW.C_BPartner_ID, '0'))
                    OR(COALESCE(OLD.DOCUMENTNO, '.') <> COALESCE(NEW.DOCUMENTNO, '.'))
                    OR(COALESCE(OLD.C_DOCTYPE_ID, '0') <> COALESCE(NEW.C_DOCTYPE_ID, '0'))
                    OR(COALESCE(OLD.C_DOCTYPETARGET_ID, '0') <> COALESCE(NEW.C_DOCTYPETARGET_ID, '0'))
                    OR(COALESCE(OLD.DATEINVOICED, TO_DATE('31-12-9999', 'DD-MM-YYYY')) <> COALESCE(NEW.DATEINVOICED, TO_DATE('31-12-9999', 'DD-MM-YYYY')))
                    OR(COALESCE(OLD.C_BPARTNER_LOCATION_ID, '0') <> COALESCE(NEW.C_BPARTNER_LOCATION_ID, '0'))
                    OR(COALESCE(OLD.PAYMENTRULE, '.') <> COALESCE(NEW.PAYMENTRULE, '.'))
                    OR(COALESCE(OLD.C_PAYMENTTERM_ID, '0') <> COALESCE(NEW.C_PAYMENTTERM_ID, '0'))
                    OR(COALESCE(OLD.C_CHARGE_ID, '0') <> COALESCE(NEW.C_CHARGE_ID, '0'))
                    OR(COALESCE(OLD.CHARGEAMT, 0) <> COALESCE(NEW.CHARGEAMT, 0))
                    OR(COALESCE(OLD.M_PRICELIST_ID, '0') <> COALESCE(NEW.M_PRICELIST_ID, '0'))
                    OR(COALESCE(OLD.AD_USER_ID, '0') <> COALESCE(NEW.AD_USER_ID, '0'))
                    OR(COALESCE(OLD.AD_ORGTRX_ID, '0') <> COALESCE(NEW.AD_ORGTRX_ID, '0'))
                    OR(COALESCE(OLD.USER1_ID, '0') <> COALESCE(NEW.USER1_ID, '0'))
                    OR(COALESCE(OLD.USER2_ID, '0') <> COALESCE(NEW.USER2_ID, '0'))
                    OR(COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
                    OR(COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0'))))
                    THEN  
			IF(old.docstatus = 'VO' AND (COALESCE(OLD.PAYMENTRULE, '.') <> COALESCE(NEW.PAYMENTRULE, '.')))
				THEN	-- allow this case
			ELSE
				RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
			END IF; 
            END IF;

    IF (COALESCE(OLD.C_BPartner_ID, '0')!=COALESCE(NEW.C_BPartner_ID, '0')) OR (COALESCE(OLD.M_PriceList_ID,'0') != COALESCE(NEW.M_PriceList_ID,'0'))  THEN
      SELECT COUNT(*)
        INTO v_n
        FROM C_INVOICELINE
       WHERE C_Invoice_ID = NEW.C_Invoice_ID;

       IF v_n>0 THEN
         RAISE EXCEPTION '%', '@existingLines@' ; --OBTG:-20502--@existingLines@
       END IF;
     END IF;
     -- Get EMail setting
     IF (old.c_bpartner_location_id!=new.c_bpartner_location_id) then
             select isinvoicebyemail into new.isinvoicebyemail from c_bpartner_location where c_bpartner_location_id=new.c_bpartner_location_id;
     end if;

   IF(OLD.Posted='Y' AND ((COALESCE(OLD.DATEACCT,  TO_DATE('31-12-9999', 'DD-MM-YYYY')) <> COALESCE(NEW.DATEACCT, TO_DATE('31-12-9999', 'DD-MM-YYYY'))) OR(COALESCE(OLD.C_CAMPAIGN_ID, '0') <> COALESCE(NEW.C_CAMPAIGN_ID, '0'))  OR(COALESCE(OLD.C_ACTIVITY_ID, '0') <> COALESCE(NEW.C_ACTIVITY_ID, '0')))) THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
   END IF;
  END IF;
  IF(TG_OP = 'INSERT') THEN
   IF(NEW.PROCESSED='Y') THEN
     RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
   END IF;
  END IF;
  IF(TG_OP = 'DELETE') THEN
   IF(OLD.PROCESSED='Y') THEN
     RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
   END IF;
  END IF;
  if (TG_OP = 'UPDATE' and (new.c_paymentterm_id!=old.c_paymentterm_id or new.DateInvoiced!=old.DateInvoiced)) or TG_OP = 'INSERT' then
    select C_Paymentduedate(new.c_bpartner_id, new.IsSOTrx, FixMonthDay, FixMonthDay2, FixMonthDay3, NetDays, FixMonthOffset, NetDay, IsNextbusinessday, new.DateInvoiced) 
           into new.schedtransactiondate  FROM C_PAYMENTTERM where c_paymentterm_id=new.c_paymentterm_id;
  end if;
  
  IF TG_OP = 'UPDATE' then
    -- Eintrag in Artikel/Einkauf
    if new.processed='Y' and old.processed!='Y' and new.issotrx='N' then
      for v_cur_line in (select i.*,ol.m_product_po_id from c_invoiceline i left join c_orderline ol on ol.c_orderline_id=i.c_orderline_id where i.c_invoice_id=new.c_invoice_id)
      LOOP
        select calculated into v_iscalcenabled from m_product where m_product_id=v_cur_line.m_product_id;
        select c_uom_id into v_uom from m_product_uom where m_product_uom_id=v_cur_line.m_product_uom_id;
        if v_iscalcenabled='Y' then 
            select count(*) into v_dummy from m_product_po where C_BPARTNER_ID=new.C_BPARTNER_ID and m_product_id=v_cur_line.m_product_id
            and case when v_cur_line.m_product_uom_id is not null then c_uom_id=v_uom else c_uom_id is null end
            and case when v_cur_line.m_product_po_id is not null then m_product_po_id=v_cur_line.m_product_po_id else 1=1 end;
            if v_dummy>0 then
                update m_product_po set pricelastinv=  v_cur_line.priceactual
                        where  C_BPARTNER_ID=new.C_BPARTNER_ID and m_product_id=v_cur_line.m_product_id
                        and case when v_cur_line.m_product_uom_id is not null then c_uom_id=v_uom else c_uom_id is null end
                        and case when v_cur_line.m_product_po_id is not null then m_product_po_id=v_cur_line.m_product_po_id else 1=1 end;
            else
                insert into m_product_po(M_PRODUCT_PO_ID,M_PRODUCT_ID, C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, ISCURRENTVENDOR, C_CURRENCY_ID,PRICELIST, PRICEPO,
                                        PRICEEFFECTIVE, PRICELASTINV,c_uom_id)
                            values (get_uuid(),v_cur_line.m_product_id,new.C_BPARTNER_ID,new.AD_CLIENT_ID,new.AD_ORG_ID,'Y',now(),new.CREATEDBY,now(),new.UPDATEDBY,'Y',new.C_CURRENCY_ID,v_cur_line.pricelist,v_cur_line.priceactual,
                                        now(),v_cur_line.priceactual,v_uom);
            end if;
        end if;
      END LOOP;
    end if;   
  END IF;
  IF TG_OP = 'UPDATE' then
        -- Sauberer Umgang mit Projektzuordnung
        if coalesce(new.c_project_id, '0') != coalesce(old.c_project_id, '0') and new.c_project_id is null then
            new.c_projecttask_id:=null;
        end if;
        -- SZ: If Project or Asset changed: Propagate to lines
        if  coalesce(new.c_project_id,'0')!=coalesce(old.c_project_id,'0') or coalesce(new.a_asset_id,'0')!=coalesce(old.a_asset_id,'0') then
            update c_invoiceline set c_project_id=new.c_project_id,c_projecttask_id=new.c_projecttask_id,a_asset_id=new.a_asset_id where c_invoice_id=new.c_invoice_id;
        end if;
       -- SZ: If schedtransactiondate changes, propagate to Payments
       if coalesce(new.schedtransactiondate,new.updated)!=coalesce(old.schedtransactiondate,new.updated) then
            update c_debt_payment set dateplanned=new.schedtransactiondate where c_invoice_id=new.c_invoice_id and c_settlement_cancel_id is null;
       end if;
  END IF;
  -- Handle outstanding amount
    if TG_OP = 'UPDATE' then
    -- If invoice gets completed, fill outstanding amount
            if (new.docstatus = 'CO') then
                    new.outstandingamt := new.grandtotal;
            end if;
    -- If invoice gets reactivated, closed or voided set outstanding amount to 0
            if (new.docstatus = 'VO' or new.docstatus = 'CL' or new.docstatus = 'DR') then
                    new.outstandingamt := 0;
            end if;
    end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


CREATE OR REPLACE FUNCTION c_invoice_trg2() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************

Gets predefined Textmodules into Invoice

*****************************************************/

    v_count numeric;
    v_orgfrom character varying;
    v_cur RECORD; 
    v_cur2 RECORD;
    v_adre varchar;
    v_lang varchar;
BEGIN
    
 
 IF(TG_OP = 'INSERT') then
     --Take Textmodule either from Org=0 or current organization 
     for v_cur in (select * from zssi_textmodule where c_doctype_id=new.c_doctypetarget_id and ad_org_id in ('0',new.ad_org_id) and isactive='Y' and isautoadd='Y' and 
                                            coalesce(c_bpartner_id,new.c_bpartner_id)=new.c_bpartner_id order by islower,position )
     LOOP
        -- Get predefined Textmodules into Order
        insert into zssi_invoice_textmodule (ZSSI_invoice_TEXTMODULE_ID, zssi_textmodule_id,C_invoice_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, LINE, ISLOWER, TEXT)
               values (get_uuid(),v_cur.zssi_textmodule_id,new.c_invoice_id,new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,v_cur.position,v_cur.islower,v_cur.text);
     END LOOP;
     select max(line) into v_count from zssi_invoice_textmodule where c_invoice_id=new.c_invoice_id;
     if (new.c_order_id is not null) then
        FOR v_cur2 in (select * from zssi_order_textmodule where (c_order_id=new.c_order_id AND zssi_textmodule_id is null) or (c_order_id=new.c_order_id and zssi_textmodule_id is not null and ismodified='Y'))
        LOOP
            insert into zssi_invoice_textmodule (ZSSI_invoice_TEXTMODULE_ID, zssi_textmodule_id,C_invoice_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, LINE, ISLOWER, TEXT,ismodified)
                values (get_uuid(),v_cur2.zssi_textmodule_id,new.c_invoice_id,new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,coalesce(v_count,0)+v_cur2.line,v_cur2.islower,v_cur2.text,
                case when v_cur2.zssi_textmodule_id is null then 'N' else 'Y' end);
        END LOOP;
     end if;
  end if; --Inserting 
  IF(TG_OP = 'UPDATE') then
    if new.ispaid!=old.ispaid or new.docstatus!=old.docstatus or old.totalpaid!=new.totalpaid then
        PERFORM zse_invoice_ecommercestatus(new.c_invoice_id);
    end if;
  end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


drop trigger c_invoice_trg2 on c_invoice;

CREATE TRIGGER c_invoice_trg2
  AFTER INSERT OR UPDATE
  ON c_invoice
  FOR EACH ROW
  EXECUTE PROCEDURE c_invoice_trg2();



CREATE or replace FUNCTION c_isinvoicecandidate(p_order_id character varying) returns character varying
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
***************************************************************************************************************************************************

*****************************************************/
  v_rule character varying;
  v_freq character varying;
  v_invfreq character varying;
  v_doctype character varying;
  v_yearly_month character varying;
  v_weekly_day character varying;
  v_monthly_day numeric;
  v_quarterly_month character varying;
  v_invdate timestamp without time zone;
  v_enddate timestamp without time zone;
  v_lastdate timestamp without time zone;
  v_day  numeric;
  v_addlast  numeric;
  v_isscheduledcustomer  character varying;
  v_draftexists  numeric:=0;
  v_isinvoiceafterfirstcycle character varying;
  v_compare   numeric;
  v_compare2   numeric;
BEGIN 
  select c_order.invoicefrequence,c_order.contractdate,c_order.enddate,c_order.c_doctype_id,c_order.invoicerule,coalesce(c_invoiceschedule.invoicefrequency,'D'),coalesce(c_invoiceschedule.invoiceday,1),
          yearly_month,weekly_day,monthly_day,quarterly_month,isinvoiceafterfirstcycle
         into v_invfreq,v_invdate,v_enddate,v_doctype,v_rule,v_freq,v_day,v_yearly_month,v_weekly_day,v_monthly_day,v_quarterly_month,v_isinvoiceafterfirstcycle from c_order,c_bpartner,c_invoiceschedule where 
           c_order.c_bpartner_id=c_bpartner.c_bpartner_id and c_bpartner.c_invoiceschedule_id=c_invoiceschedule.c_invoiceschedule_id
           and c_order_id=p_order_id;
  -- sales Order/Purchase Order
  if ad_get_docbasetype(v_doctype) in ('SOO','POO')  then
      -- Payment sheduling on Orders Beats all other Criteria
      select count(*) into v_compare2 from c_order_paymentschedule where C_Order_ID=p_order_id;
      if v_compare2>0 then
          select count(*) into v_compare2 from c_order_paymentschedule where C_Order_ID=p_order_id and c_invoice_id is null and trunc(invoicedate)<=trunc(now());
          if v_compare2>0 then return 'Y'; else return 'N'; end if;       
      end if; 
      -- Over All Criteria - > Is there something to Invoice?
      ---- Criteria for Selection is: Only Lines that have Date Promised > now. and have qty Ordered > Qty Invoiced or  Amount Ordered > Amount Invoiced and are not closed manually
      select count(*) into v_compare from c_orderline ol
                WHERE coalesce(ol.datepromised,now()-1)<now()
                  AND (ol.QtyOrdered-ol.QtyInvoiced > 0 or  (case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end) - ol.invoicedamt > 0)
                  and ol.ignoreresidue='N'
                  AND ol.C_Order_ID=p_order_id;
      -- Do not Invoice
      if v_rule = 'N' then return 'N'; end if;
      -- Immediate Fits only Over All Criteria
      if v_rule = 'I' then
            -- select count(*) into v_draftexists from   c_invoiceline il,c_invoice i where il.c_orderline_id in (select c_orderline_id from c_orderline where c_order_id=p_order_id) and il.c_invoice_id=i.c_invoice_id and i.docstatus='DR'; 
            if v_compare>0 and v_draftexists=0 then return 'Y'; else return 'N'; end if;
      end if;
      -- Order Complete, Like Immediate but: Additionally all lines must be delivered completely
      if v_rule = 'O' then
            select sum(case when deliverycomplete='Y' then 0 else case when qtyordered - qtydelivered<= 0 then 0 else 1 end end) into v_compare2 from c_orderline where c_order_id=p_order_id;
            -- select count(*) into v_draftexists from   c_invoiceline il,c_invoice i where il.c_orderline_id in (select c_orderline_id from c_orderline where c_order_id=p_order_id) and il.c_invoice_id=i.c_invoice_id and i.docstatus='DR';          
            if v_compare>0 and v_compare2=0 and v_draftexists=0 then return 'Y'; else return 'N'; end if;
      end if;
      -- After delivery. Only deliverys are invoiced, no matter how often/how much
      if v_rule in ('D','DI') then
            -- only deliveries, no returns.
            select count(*) into v_compare2 from m_inoutline iol,m_inout io where io.m_inout_id=iol.m_inout_id and io.c_doctype_id not in ('2317023F9771481696461C5EAF9A0915','2E1E735AA91A49F8BC7181D31B09B370') 
                            and c_orderline_id in (select c_orderline_id from c_orderline where c_order_id=p_order_id) and isinvoiced='N';
            if v_compare2>0 then return 'Y'; else return 'N'; end if;
      end if;
      -- After delivery sheduling.Only deliverys are invoiced, no matter how often/how much
      if v_rule = 'S' then
            -- Something delivered, not invoiced
            -- only deliveries, no returns.
            select count(*) into v_compare2 from m_inoutline iol,m_inout io where io.m_inout_id=iol.m_inout_id and io.c_doctype_id not in ('2317023F9771481696461C5EAF9A0915','2E1E735AA91A49F8BC7181D31B09B370') 
                            and c_orderline_id in (select c_orderline_id from c_orderline where c_order_id=p_order_id) and isinvoiced='N';
            if v_compare2>0 then
                  -- daily
                  if v_freq='D' then  return 'Y'; end if;
                  -- Weekly, on spec. day of week
                  if v_freq='W' then  
                        if (SELECT EXTRACT(DOW from now()))>=v_day then 
                              select (EXTRACT(DOW from now())-v_day)-7 into v_compare;
                              if (select count(*) from c_invoice where c_order_id=p_order_id and dateinvoiced>=trunc(now())-v_compare )=0 then return 'Y'; else return 'N'; end if;
                        end if;
                  end if;
                  -- Mothly, on spec. day of month
                  if v_freq='M' then  
                        if (SELECT EXTRACT(DAY from now()))>=v_day then 
                              select (EXTRACT(DAY from now())-v_day)-30.5 into v_compare;
                              if (select count(*) from c_invoice where c_order_id=p_order_id and dateinvoiced>=trunc(now())-v_compare )=0 then return 'Y'; else return 'N'; end if;
                        end if;
                  end if;
                  -- quarter, on spec. day of month of quarter
                  if v_freq='Q' then  
                        if (SELECT EXTRACT(DAY from now()))>=v_day then 
                              select (EXTRACT(DAY from now())-v_day)-91.5 into v_compare;
                              if (select count(*) from c_invoice where c_order_id=p_order_id and dateinvoiced>=trunc(now())-v_compare )=0 then return 'Y'; else return 'N'; end if;
                        end if;
                  end if;
            end if;
      end if;
  -- sales order
  end if;
  return 'N'; 
END;
$_$  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


  
CREATE OR REPLACE FUNCTION zssi_notinvoicedlines4orderline(p_orderline_id character varying,p_pendingorall character varying,p_qtyorlineamtorprice character varying,p_inoutline_id character varying, p_bydate timestamp without time zone)
  RETURNS numeric AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
  v_amt2invoice numeric:=0;
  v_count numeric:=0;
  v_qty numeric;
  v_invrule character varying;
  v_doctype character varying;
  v_order_id character varying;
  v_partialAmountFactor numeric;
  v_invoicedamt numeric;
  v_priceactual numeric;
BEGIN
  select c_order.c_doctype_id,c_order.c_order_id,invoicerule into v_doctype,v_order_id,v_invrule from c_order,c_orderline where c_order.c_order_id=c_orderline.c_order_id and c_orderline.c_orderline_id=p_orderline_id;
  if ad_get_docbasetype(v_doctype) in ('SOO','POO') then
      select count(*) into v_count from c_order_paymentschedule where c_order_id=v_order_id and c_invoice_id is null;
      -- paymentschedule - Automatic Invoice only on  Orderlines if v_count>0
      if v_count>0 and p_pendingorall='PENDING' then
            select case coalesce(c_order.totallines,0) when 0 then 1 else c_order_paymentschedule.amount/c_order.totallines end 
                  into v_partialAmountFactor from c_order_paymentschedule,c_order
                  where c_order.c_order_id=c_order_paymentschedule.c_order_id
                        and c_order_paymentschedule.c_order_id=v_order_id
                        and c_order_paymentschedule.c_invoice_id is null order by c_order_paymentschedule.invoicedate LIMIT 1;
      else
            v_partialAmountFactor:=1;
      end if;
      if v_partialAmountFactor=1 then -- Normal Order
            select (case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end)-ol.invoicedamt, 
                    case when ol.M_Product_UOM_ID is null then ol.qtyordered-ol.qtyinvoiced else
                    C_Uom_Convert(ol.qtyordered-ol.qtyinvoiced, ol.C_UOM_ID, (select c_uom_id from m_product_uom where m_product_uom_id=ol.M_Product_UOM_ID), 'Y') end,
                    ol.priceactual,ol.invoicedamt 
                  into v_amt2invoice,v_qty,v_priceactual,v_invoicedamt
                  FROM C_ORDERLINE ol
                  WHERE coalesce(ol.datepromised,trunc(now()))<=trunc(p_bydate)
                  AND  (ol.QtyOrdered-ol.QtyInvoiced > 0 or  (case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end) - ol.invoicedamt > 0)
                  and ol.ignoreresidue='N'
                  AND ol.C_Orderline_id=p_orderline_id;
      else -- Paymentschedule
            select (case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end),
                  coalesce(ol.quantityorder,ol.qtyordered) ,ol.priceactual,ol.invoicedamt into v_amt2invoice,v_qty,v_priceactual,v_invoicedamt
                  FROM C_ORDERLINE ol
                  WHERE ol.ignoreresidue='N'
                  AND ol.C_Orderline_id=p_orderline_id;
      end if;

      if coalesce(v_amt2invoice,-1)<0 and (select c_orderline.linenetamt from c_orderline where c_orderline.c_orderline_id = p_orderline_id)>0 then 
	  v_amt2invoice:=0; 
      elsif coalesce(v_amt2invoice,-1)>0 and (select c_orderline.linenetamt from c_orderline where c_orderline.c_orderline_id = p_orderline_id)<0 then
	  v_amt2invoice:=0;
      end if;-- Already more Amount invoiced than the Amount of Orderline

      if coalesce(v_qty,-1)<=0 then v_qty:=1; end if; -- In case of more Quantity Invoiced than ordered: Set Quantity=1
      if p_pendingorall='ALL' and p_qtyorlineamtorprice='LINEAMT' then 
            return coalesce(v_amt2invoice,0);  
      elsif p_pendingorall='ALL' and p_qtyorlineamtorprice='PRICE' then 
           return coalesce(v_amt2invoice/(case coalesce(v_qty,0) when 0 then 1 else v_qty end),0);  
      elsif p_pendingorall='ALL' and p_qtyorlineamtorprice='QTY' then  
            return coalesce(v_qty,0);
      elsif p_pendingorall='PENDING' and v_invrule='I' and  p_qtyorlineamtorprice='LINEAMT' then
            return coalesce(v_amt2invoice*v_partialAmountFactor,0);
      elsif p_pendingorall='PENDING' and v_invrule='I' and  p_qtyorlineamtorprice='PRICE' then
            if v_invoicedamt=0 then
               return v_priceactual;
            else
               return coalesce(v_amt2invoice/(case coalesce(v_qty,0) when 0 then 1 else v_qty end),0);  
            end if;
      elsif p_pendingorall='PENDING' and v_invrule='I' and p_qtyorlineamtorprice='QTY' then
            return coalesce(v_qty*v_partialAmountFactor,0);
      end if;
      if p_pendingorall='PENDING' and v_invrule in ('D','O','S','DI') then
              --select sl.movementqty*ol.priceactual,sl.movementqty,ol.priceactual into v_amt2invoice,v_qty, v_priceactual
              
              select CASE WHEN sl.M_Product_UOM_ID is null then (sl.movementqty*ol.priceactual) else (sl.quantityorder*ol.priceactual) end,
              case when sl.M_Product_UOM_ID is null then sl.movementqty else sl.quantityorder end,
                    ol.priceactual into v_amt2invoice,v_qty, v_priceactual
              FROM M_INOUT s, M_INOUTLINE sl,C_ORDERLINE ol,c_order o
              WHERE o.c_order_id=ol.c_order_id and sl.C_OrderLine_ID=ol.C_OrderLine_ID 
                AND s.M_InOut_ID = sl.M_InOut_ID
                and o.invoicerule in ('D','O','S','DI') and o.DocStatus = 'CO'  and coalesce(ol.datepromised,trunc(now()))<=trunc(p_bydate)
                and ol.ignoreresidue='N'
                AND s.DocStatus = 'CO'
                AND sl.IsInvoiced='N'
                AND ol.C_Orderline_id=p_orderline_id
                AND sl.m_inoutline_id=p_inoutline_id;
            if p_qtyorlineamtorprice='QTY' then 
             return coalesce(v_qty,0); 
            elsif p_qtyorlineamtorprice='LINEAMT' then
             return coalesce(v_amt2invoice,0);  
            elsif p_qtyorlineamtorprice='PRICE' then
             return v_priceactual;
            end if; 
      end if;
  end if;
  return 0;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE OR REPLACE FUNCTION zssi_notinvoicedlines4orderline(p_orderline_id character varying,p_pendingorall character varying,p_qtyorlineamtorprice character varying,p_inoutline_id character varying)
  RETURNS numeric AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2020 OpenZ Software GmbH
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Overload, used in Generete Invoice Manual trx

*****************************************************/
BEGIN
  return zssi_notinvoicedlines4orderline(p_orderline_id ,p_pendingorall ,p_qtyorlineamtorprice ,p_inoutline_id ,trunc(now()));
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_isorderline2invoiceByNowOrGenerally(p_orderline_id character varying,p_isByNow character varying)
  RETURNS character varying AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
  v_amt2invoice numeric:=0;
  v_count numeric:=0;
  v_qty numeric;
  v_invrule character varying;
  v_doctype character varying;
  v_ignoreresidue character varying;
  v_isonetimeposition  character varying;
  v_order_id character varying;
  v_datepromised timestamp without time zone;
  v_QtyOrdered numeric;
  v_QtyDelivered numeric;
  v_QtyInvoiced numeric;
  v_linenetamt  numeric;
  v_linegrossamt numeric;
  v_invoicedamt numeric;
  v_contractdate timestamp without time zone;
  v_amt numeric;
  v_compare numeric;
  v_bpartner varchar;
  v_freq character varying;
  v_day numeric;
  v_compare2 numeric;
BEGIN

      select o.c_order_id,o.c_doctype_id,o.invoicerule,o.c_bpartner_id,ol.isonetimeposition,ol.ignoreresidue,ol.QtyOrdered,ol.QtyInvoiced,ol.linenetamt,ol.linegrossamt,ol.invoicedamt,ol.datepromised, o.contractdate, ol.QtyDelivered
            into v_order_id,v_doctype,v_invrule,v_bpartner ,v_isonetimeposition,v_ignoreresidue,v_QtyOrdered,v_QtyInvoiced,v_linenetamt,v_linegrossamt,v_invoicedamt,v_datepromised, v_contractdate,v_QtyDelivered
      from c_order o,c_orderline  ol where o.c_order_id=ol.c_order_id and ol.c_orderline_id=p_orderline_id;
      select count(*) into v_count from c_order_paymentschedule where c_order_id=v_order_id and c_invoice_id is null;
      select coalesce(c_invoiceschedule.invoicefrequency,'D'),coalesce(c_invoiceschedule.invoiceday,1) into v_freq,v_day from c_invoiceschedule,c_bpartner where c_bpartner.c_bpartner_id=v_bpartner and
             c_bpartner.c_invoiceschedule_id=c_invoiceschedule.c_invoiceschedule_id;
      if ad_get_docbasetype(v_doctype) in ('POO','SOO') then 
            -- If p_isByNow is set , the date to invoice must be evaluated. This is used by Invoice-Candidate.
            -- If p_isByNow is not set , this Function determines, if there is generally something to invoice on this orderline, at any date.
            if p_isByNow='N' then
               v_datepromised:=null;
            end if;
            -- Do not Invoice By Rule
            if v_invrule = 'N' then return 'N'; end if;
            -- Immediate Rule 
            if v_invrule='I' then
                  -- paymentschedule - Automatic Invoice only on all Orderlines if v_count>0
                  -- In paymentschedule, the Date of Paymewnt is tested..
                  if v_count>0 then
                        -- Payment sheduling on Orders Beats all other Criteria
                        select count(*) into v_compare from c_order_paymentschedule where C_Order_ID=v_order_id and c_invoice_id is null and trunc(invoicedate)<=
                                        case when p_isByNow='N' then TIMESTAMP 'infinity' else trunc(now()) end;
                        if v_compare>0 then return 'Y'; else return 'N'; end if;       
                  else
                      if v_linenetamt=0 then
                        v_amt:= v_linegrossamt;
                      else 
                        v_amt:= v_linenetamt;
                      end if;
                      -- Bei negativen Orderlines umgekehrt rechnen
                      if v_amt<0 then
                         v_amt:=v_amt*-1;
                         v_invoicedamt:=v_invoicedamt*-1;
                      end if;
                      if v_ignoreresidue='N' and (v_QtyOrdered-v_QtyInvoiced > 0 or  v_amt - v_invoicedamt > 0) and coalesce(v_datepromised,now()-1)<now() then
                             return 'Y';
                      end if;
                  end if;
            -- After delivery , oder Complete and Customer Scheduling 
            elsif v_invrule in ('D','O','S','DI') then
                  -- Test if generally Invoiceing expected
                  if p_isByNow='N' then
                     -- Bei negativen Orderlines umgekehrt rechnen
                      if v_linenetamt=0 then
                        v_amt:= v_linegrossamt;
                      else 
                        v_amt:= v_linenetamt;
                      end if;
                      if v_amt<0 then
                         v_amt:=v_amt*-1;
                         v_invoicedamt:=v_invoicedamt*-1;
                      end if;
                      if v_ignoreresidue='N' and (v_QtyOrdered-v_QtyInvoiced > 0 or  v_amt - v_invoicedamt > 0)  then
                             return 'Y';
                      end if;
                  end if;
                  -- Time Sheduling and Completeness is Sotred out before Testing Criteria below on the Line
                  if v_invrule = 'O' then
                        select sum(case when deliverycomplete='Y' then 0 else case when qtyordered - qtydelivered<= 0 then 0 else 1 end end) 
                        into v_compare2 from c_orderline where c_order_id=(select c_order_id from c_orderline where c_orderline_id=p_orderline_id);
                        if v_linenetamt=0 then
                            v_amt:= v_linegrossamt;
                        else 
                            v_amt:= v_linenetamt;
                        end if;
                        -- Bei negativen Orderlines umgekehrt rechnen
                        if v_amt<0 then
                            v_amt:=v_amt*-1;
                            v_invoicedamt:=v_invoicedamt*-1;
                        end if;
                        if v_compare2=0 and v_ignoreresidue='N' and (v_QtyOrdered-v_QtyInvoiced > 0 or  v_amt - v_invoicedamt > 0)  then -- and coalesce(v_datepromised,now()-1)<now() (Sammelrechnung/Datumsfilter)
                                return 'Y';
                        else
                                return 'N';
                        end if;
                  end if;
                  -- After delivery sheduling.Only deliverys are invoiced, no matter how often/how much
                  if v_invrule = 'S' and v_freq!='D' then
                    -- Weekly, on spec. day of week
                    if v_freq='W' then  
                            if (SELECT EXTRACT(DOW from now()))>=v_day then 
                                select (EXTRACT(DOW from now())-v_day)-7 into v_compare;
                                if (select count(*) from c_invoice where c_order_id=p_order_id and dateinvoiced>=trunc(now())-v_compare )!=0 then return 'N'; end if;
                            end if;
                    end if;
                    -- Mothly, on spec. day of month
                    if v_freq='M' then  
                            if (SELECT EXTRACT(DAY from now()))>=v_day then 
                                select (EXTRACT(DAY from now())-v_day)-30.5 into v_compare;
                                if (select count(*) from c_invoice where c_order_id=p_order_id and dateinvoiced>=trunc(now())-v_compare )!=0 then return 'N'; end if;
                            end if;
                    end if;
                    -- quarter, on spec. day of month of quarter
                    if v_freq='Q' then  
                            if (SELECT EXTRACT(DAY from now()))>=v_day then 
                                select (EXTRACT(DAY from now())-v_day)-91.5 into v_compare;
                                if (select count(*) from c_invoice where c_order_id=p_order_id and dateinvoiced>=trunc(now())-v_compare )!=0 then return 'N'; end if;
                            end if;
                    end if;
                 -- Ruile S
                 end if;
                  -- After sorting Out Scheduling - INOUT is Tested if there is something to Invoice
                  select count(*) into v_count 
                    FROM M_INOUT s, M_INOUTLINE sl,C_ORDERLINE ol,c_order o
                    WHERE o.c_order_id=ol.c_order_id and sl.C_OrderLine_ID=ol.C_OrderLine_ID 
                      AND s.M_InOut_ID = sl.M_InOut_ID
                      --and coalesce(v_datepromised,now()-1)<now() (Sammelrechnung/Datumsfilter)
                      and ol.ignoreresidue='N'
                      AND s.DocStatus = 'CO'
                      AND sl.IsInvoiced='N'
                      AND s.c_doctype_id not in ('2317023F9771481696461C5EAF9A0915','2E1E735AA91A49F8BC7181D31B09B370')  --Only Deliverys, No Returns
                      AND ol.c_orderline_id=p_orderline_id;
                  if v_count>0 then
                        return 'Y';
                  end if;
            -- InvRule
            end if;
       -- DoBasetype
       end if;
  return 'N';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_isorderline2invoice(p_orderline_id character varying, p_datefrom varchar,p_dateto varchar)
  RETURNS character varying AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2020 OpenZ Software GmbH
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Overload, used in Generete Invoice Manual trx

*****************************************************/
BEGIN
  if p_datefrom is null and p_dateto is null then
    return c_isorderline2invoiceByNowOrGenerally(p_orderline_id,'Y');
  else
    return c_isorderline2invoiceByNowOrGenerally(p_orderline_id,'N');
  end if;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_isorderline2invoice(p_orderline_id character varying)
  RETURNS character varying AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/

BEGIN
  return c_isorderline2invoiceByNowOrGenerally(p_orderline_id,'Y');
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION c_isorderCompletelyInvoiced(p_order_id character varying)
  RETURNS character varying AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
v_cur record;
v_is2invoice character varying;
v_doctype character varying;
v_doctypeID character varying;
BEGIN
  select c_doctype_ID into v_doctypeID from c_order where c_order_id=p_order_id;
  select docbasetype into v_doctype from c_doctype where c_doctype_id=v_doctypeID;
  if v_doctypeID in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then
	return (
		select 	coalesce(min(c_order.iscompletelyinvoiced), 'N') 
		from 	c_order 
		where 	c_order.orderselfjoin = p_order_id and 
				c_order.docstatus = 'CO'
	);
  end if;
  if v_doctype not in ('SOO','POO') then                                                                                                
      return 'N' ;                                                                                                                        
  end if;     
  for v_cur in (select c_orderline_id from c_orderline where c_order_id=p_order_id)
  LOOP
      v_is2invoice:=c_isorderline2invoiceByNowOrGenerally(v_cur.c_orderline_id,'N');
      exit when v_is2invoice='Y';
  END LOOP;
  if v_is2invoice='Y' then
        return 'N' ;
  else
        return 'Y' ;
  end if;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_orderinvoicerule(p_order_id character varying)
  RETURNS character varying AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
v_retval varchar;
BEGIN
  select invoicerule into v_retval from c_order where c_order_id=p_order_id;
  return v_retval;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



select zsse_DropView ('c_invoice_candidate_v');

CREATE VIEW c_invoice_candidate_v AS 
 SELECT sq.ad_client_id, sq.ad_org_id, sq.c_bpartner_id, sq.c_order_id, sq.documentno, sq.dateordered, sq.c_doctype_id, sq.amountlines, sq.notinvoicedlines, sq.datepromised,
         sq.notinvoicedqty,sq.term, sq.pendinglines, sq.pendingqty, sq.qtyordered, sq.qtydelivered,sq.issotrx
 FROM (SELECT o.ad_client_id, o.ad_org_id, o.c_bpartner_id, o.c_order_id, o.documentno, o.dateordered, o.c_doctype_id, o.issotrx,
              o.totallines  AS amountlines, 
              sum(zssi_notinvoicedlines4orderline(l.c_orderline_id,'ALL','LINEAMT',sl.m_inoutline_id)) AS notinvoicedlines,
              sum(zssi_notinvoicedlines4orderline(l.c_orderline_id,'ALL','QTY',sl.m_inoutline_id)) AS notinvoicedqty, 
              o.invoicerule AS term, coalesce(o.datepromised,now()) as datepromised,
              sum(zssi_notinvoicedlines4orderline(l.c_orderline_id,'PENDING','LINEAMT',sl.m_inoutline_id)) AS pendinglines, 
              sum(zssi_notinvoicedlines4orderline(l.c_orderline_id,'PENDING','QTY',sl.m_inoutline_id)) AS pendingqty, 
              sum(l.qtyordered) AS qtyordered, sum(l.qtydelivered) AS qtydelivered, o.m_pricelist_id, o.c_currency_id
           FROM c_order o,c_orderline l left join m_inoutline sl on sl.C_OrderLine_ID=l.C_OrderLine_ID AND sl.IsInvoiced='N' and c_orderinvoicerule(l.c_order_id) in ('D','O','S','DI')
                                        left join m_inout s on s.M_InOut_ID = sl.M_InOut_ID AND s.DocStatus = 'CO'
           WHERE  o.c_order_id = l.c_order_id
                and o.iscompletelyinvoiced='N'
                and c_isinvoicecandidate(o.c_order_id)='Y' and o.docstatus  = 'CO' 
  GROUP BY o.ad_client_id, o.ad_org_id, o.c_bpartner_id, o.c_order_id, o.documentno, o.datepromised,o.dateordered, o.c_doctype_id, o.issotrx, o.totallines, o.completeordervalue,o.invoicedamt,o.grandtotal, o.invoicerule, o.m_pricelist_id, o.c_currency_id
  ) sq;

CREATE OR REPLACE FUNCTION zssi_notinvoicedAmt4order(p_order_id character varying,p_pendingorall character varying)
  RETURNS numeric AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
  v_amt2invoice numeric:=0;
  v_count numeric:=0;
  v_qty numeric;
  v_invrule character varying;
  v_doctype character varying;
  v_order_id character varying;
  v_partialAmountFactor numeric;
  v_invoicedamt numeric;
  v_priceactual numeric;
BEGIN
  select c_order.c_doctype_id,c_order.c_order_id,invoicerule into v_doctype,v_order_id,v_invrule from c_order where c_order.c_order_id=p_order_id;
  if ad_get_docbasetype(v_doctype) in ('SOO','POO') then
      select count(*) into v_count from c_order_paymentschedule where c_order_id=v_order_id and c_invoice_id is null;
      -- paymentschedule - Automatic Invoice only on  Orderlines if v_count>0
      if v_count>0 and p_pendingorall='PENDING' then
            select case coalesce(c_order.totallines,0) when 0 then 1 else c_order_paymentschedule.amount/c_order.totallines end 
                  into v_partialAmountFactor from c_order_paymentschedule,c_order
                  where c_order.c_order_id=c_order_paymentschedule.c_order_id
                        and c_order_paymentschedule.c_order_id=v_order_id
                        and c_order_paymentschedule.c_invoice_id is null order by c_order_paymentschedule.invoicedate LIMIT 1;
      else
            v_partialAmountFactor:=1;
      end if;
      if v_partialAmountFactor=1 then -- Normal Order
            select sum((case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end)-ol.invoicedamt), sum(ol.invoicedamt) 
                  into v_amt2invoice,v_invoicedamt
                  FROM C_ORDERLINE ol
                  WHERE case when p_pendingorall='PENDING' then trunc(coalesce(ol.datepromised,now()))<=trunc(now()) else 1=1 end
                  AND  (ol.QtyOrdered-ol.QtyInvoiced > 0 or  (case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end) - ol.invoicedamt > 0)
                  and ol.ignoreresidue='N'
                  AND ol.C_Order_id=p_order_id;
      else -- Paymentschedule
            select sum((case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end)),
                  sum(ol.invoicedamt) into v_amt2invoice,v_qty,v_invoicedamt
                  FROM C_ORDERLINE ol
                  WHERE ol.ignoreresidue='N'
                  AND ol.C_Order_id=p_order_id;
      end if;

      if coalesce(v_amt2invoice,-1)<0 and (select c_order.totallines from c_order where c_order.c_order_id = p_order_id)>0 then 
          v_amt2invoice:=0; 
      elsif coalesce(v_amt2invoice,-1)>0 and (select c_order.totallines from c_order where c_order.c_order_id = p_order_id)<0 then
          v_amt2invoice:=0;
      end if;-- Already more Amount invoiced than the Amount of Orderline

      
      if p_pendingorall='ALL'  then 
            return coalesce(v_amt2invoice,0);      
      elsif p_pendingorall='PENDING'  then
            if v_invrule='I' then
                return coalesce(v_amt2invoice*v_partialAmountFactor,0);
            elsif v_invrule in ('D','O','S','DI') then
                select sum(sl.movementqty*ol.priceactual) into v_amt2invoice
                FROM M_INOUT s, M_INOUTLINE sl,C_ORDERLINE ol,c_order o
                WHERE o.c_order_id=ol.c_order_id and sl.C_OrderLine_ID=ol.C_OrderLine_ID 
                    AND s.M_InOut_ID = sl.M_InOut_ID
                    and o.invoicerule in ('D','O','S','DI') and o.DocStatus = 'CO'  and trunc(coalesce(ol.datepromised,now()))<=trunc(now())
                    and ol.ignoreresidue='N'
                    AND s.DocStatus = 'CO'
                    AND sl.IsInvoiced='N'
                    AND o.C_Order_id=p_order_id;
                return coalesce(v_amt2invoice,0);  
            end if;
      end if;
  -- Doctype
  end if;
  return 0;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION m_invoice_candidate_descr_userexit(v_orderline_id varchar)
  RETURNS varchar AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***********************************************************************************************+*****************************************
User-Exit to Extend Description of invoice candidate view individually
**/
DECLARE
v_return varchar:='';
BEGIN
   
RETURN v_return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION c_invoice_candidate_project_userexit(v_order_id varchar)
  RETURNS varchar AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2021 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
***********************************************************************************************+*****************************************
User-Exit to Extend Project-Field in HEADER  of invoice candidate view individually
This Function provides the Standard-OpenZ-Representation of Projekt-Descrition
Ca be extended or Changed in Individual Customizatuions
**/
DECLARE
v_return varchar:='';
v_pid varchar;
v_aid varchar;
BEGIN
   select c_project_id,a_asset_id into v_pid ,v_aid from c_order where c_order_id=v_order_id;
   if v_pid is not null or v_aid is not null then
    v_return:=zssi_getprojectorcostcentername(v_pid,v_aid);
   end if;
RETURN v_return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select zsse_DropView ('c_invoice_candidate_lines_v');
-- Invoice Candidate LINES Order Lines or Shipment-Lines 
-- GENERAL Criteria for Selection is: Only Lines that have Date Promised > now. and have qty Ordered > Qty Invoiced or  Amount Ordered > Amount Invoiced and are not closed manually
-- Orderline is selected when Invoice Rule immediate and Order not manually edited
-- Shipment Lines are selected when  Invoice Rule  afer delivery (sheduled,complete or each shipment)
CREATE VIEW c_invoice_candidate_lines_v AS 
      SELECT ol.AD_Client_ID,
          ol.AD_Org_ID,
          ol.C_OrderLine_ID,
          case when coalesce(pc.printvpnumberondocs,'N')='Y' then coalesce(( select po.vendorproductno||'   ' from m_product_po po, c_orderline olc,c_order o where po.m_product_id=olc.m_product_id 
                                          and case when olc.m_product_uom_id is not null then po.c_uom_id=(select c_uom_id from m_product_uom where m_product_uom_id=olc.m_product_uom_id) else po.c_uom_id is null end
                                          and case when olc.m_product_po_id is not null then po.m_product_po_id= olc.m_product_po_id else  po.m_manufacturer_id is null and po.manufacturernumber is null end
                                          and ol.c_orderline_id=olc.c_orderline_id and o.c_order_id=olc.c_order_id and o.c_bpartner_id=po.c_bpartner_id AND po.vendorproductno is not null
          ),'') else '' end || coalesce(ol.Description,'')||coalesce(m_invoice_candidate_descr_userexit(ol.c_orderline_id),'') AS Description,
          ol.M_Product_ID,
          coalesce(ol.quantityorder,ol.Qtyordered) as Qtyordered,
          ol.QtyInvoiced,
          ol.qtydelivered,
          ol.PriceList,
          ol.linenetamt,
          ol.linegrossamt,
          ol.invoicedamt,
          ol.PriceActual,
          ol.ignoreresidue,
          ol.PriceLimit,
          ol.C_Charge_ID,
          ol.ChargeAmt,
          ol.C_UOM_ID,
          ol.M_PRODUCT_UOM_ID,
          ol.quantityorder,
          ol.C_Tax_ID, 
          ol.Line,
          ol.DirectShip,
          ol.PriceStd,
          ol.isonetimeposition,
          case ol.linenetamt when 0 then ol.linegrossamt else ol.linenetamt end as lineprice,
          ol.m_attributesetinstance_id,ol.c_project_id,ol.c_projectphase_id,ol.c_projecttask_id,ol.a_asset_id,
          o.issotrx,
          o.c_order_id,
          o.totallines  AS amountlines, 
          o.c_doctype_id,
          trunc(coalesce((select invoicedate from c_order_paymentschedule where c_order_id=ol.c_order_id and c_invoice_id is null order by invoicedate limit 1), coalesce(ol.datepromised,now()))) as datepromised,
          o.dateordered,
          o.invoicerule AS term,
          o.documentno,
          o.c_bpartner_id,
          c_invoice_candidate_project_userexit(o.c_order_id) as project,
          sl.m_inoutline_id,
          sl.MovementQty,
          s.M_InOut_ID,
          coalesce(s.c_doctype_id,'null') m_inout_doctype_id
      FROM C_ORDERLINE ol left join m_inoutline sl on sl.C_OrderLine_ID=ol.C_OrderLine_ID AND sl.IsInvoiced='N' and c_orderinvoicerule(ol.c_order_id) in ('D','O','S','DI')
                          left join m_inout s on s.M_InOut_ID = sl.M_InOut_ID AND s.DocStatus = 'CO',
           c_order o left join Zspr_Printinfo pc on pc.ad_org_id=o.ad_org_id
      WHERE o.c_order_id=ol.c_order_id
        AND o.docstatus='CO' and o.iscompletelyinvoiced='N';

select zsse_dropfunction('c_invoice_candidate_combinedselect');
CREATE OR REPLACE FUNCTION c_invoice_candidate_combinedselect(p_isotrx varchar,p_datefrom varchar,p_dateto varchar,p_bpartner_id varchar,p_documentno varchar,p_orgid varchar,
        p_bpartner_id_out out varchar,p_notinvoicedlines out numeric,p_pendinglines out numeric,p_amountlines out numeric,
        p_dateordered out date,p_datepromised out date, p_ad_org_id  out varchar, p_C_DocType_ID out varchar,p_term out varchar, p_order_id out varchar) RETURNS SETOF RECORD
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is OpenZ Software GmbH
First Published in 2020.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/
v_pend numeric;
v_notinvoiced numeric;
BEGIN
    if (SELECT count(*) from information_schema.tables where table_name='invtrxcalc')=0 then
        create temporary table invtrxcalc(
            notinvoicedlines numeric,
            pendinglines numeric,
            amountlines numeric,
            c_bpartner_id varchar(32),
            dateordered date,
            datepromised date,
            ad_org_id varchar(32),
            C_DocType_ID varchar(32),
            invoicerule varchar(32),
            c_order_id varchar(32)
        )   ON COMMIT DROP;
    end if;
    if (select count(*) from invtrxcalc where c_bpartner_id=p_bpartner_id)>0 then
        select amountlines, pendinglines,notinvoicedlines,dateordered,datepromised,ad_org_id ,C_DocType_ID,invoicerule,c_order_id
               into p_amountlines,p_pendinglines,p_notinvoicedlines,p_dateordered,p_datepromised,p_ad_org_id ,p_C_DocType_ID,p_term,p_order_id from invtrxcalc where c_bpartner_id=p_bpartner_id;
        p_bpartner_id_out:=p_bpartner_id ;
        
    else
     SELECT sum(case when icl.linenetamt=0 then icl.linegrossamt else icl.linenetamt end) as amountlines,sum(case when icl.linenetamt=0 then icl.linegrossamt else icl.linenetamt end - icl.invoicedamt) as pend,
           sum(case when icl.linenetamt=0 then icl.linegrossamt else icl.linenetamt end - icl.invoicedamt) as notinvoiced, p_bpartner_id,
           min(icl.dateordered) as dateordered,min(icl.datepromised) as datepromised,min(icl.ad_org_id) as ad_org_id,min(icl.C_DocType_ID),min(term),min(c_order_id)
        into p_amountlines,p_pendinglines,p_notinvoicedlines,p_bpartner_id_out,p_dateordered,p_datepromised,p_ad_org_id,p_C_DocType_ID,p_term,p_order_id
        from c_invoice_candidate_lines_v icl
        where c_isorderline2invoice(icl.c_orderline_id,p_datefrom,p_dateto)='Y'
         AND icl.issotrx =p_isotrx
         AND coalesce(icl.m_inout_doctype_id,'') not in ('2317023F9771481696461C5EAF9A0915','2E1E735AA91A49F8BC7181D31B09B370') 
         AND case when p_datefrom is not null then icl.datepromised >= TO_DATE(p_datefrom) else 1=1 end
         AND case when p_dateto is not null then icl.datepromised <= TO_DATE(p_dateto) else 1=1 end
         AND case when p_documentno is not null then icl.documentno like p_documentno else 1=1 end
         AND case when p_bpartner_id  is not null then icl.c_bpartner_id = p_bpartner_id else 1=1 end
         AND ad_org_id= p_orgid; 
      insert into invtrxcalc(amountlines, pendinglines,notinvoicedlines,c_bpartner_id,dateordered,datepromised,ad_org_id,C_DocType_ID,invoicerule,c_order_id) 
             values (p_amountlines,p_pendinglines,p_notinvoicedlines,p_bpartner_id,p_dateordered,p_datepromised,p_ad_org_id,p_C_DocType_ID,p_term,p_order_id);
    end if;
    return next;
END;
$_$  LANGUAGE 'plpgsql';        
        


CREATE OR REPLACE FUNCTION c_create_pinvoice_from_outs(p_pinstance_id character varying) RETURNS void
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
***************************************************************************************************************************************************/
  /*************************************************************************
  * Description:
  * - Create purchase invoice from sales shipments and inventory movements
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    v_DateFrom TIMESTAMP;
    v_DateTo TIMESTAMP;
    v_Warehouse_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_BPartner_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_ReferenceNo  character varying;
    v_DateInvoiced TIMESTAMP;
    v_User_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    --
    v_Project_ID VARCHAR(32):='0'; --OBTG:VARCHAR2--
    v_Doctype_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_Invoice_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_DocumentNo VARCHAR(60) ; --OBTG:NVARCHAR2--
    v_PaymentRule VARCHAR(60) ;
    v_PaymentTerm_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_Currency_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_IsTaxIncluded CHAR(1) ;
    v_NoRecords NUMERIC:=0;
    v_InvoiceLine_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_auxQty NUMERIC;
    v_auxQtyTotal NUMERIC;
    v_line NUMERIC;
    v_priceList NUMERIC;
    v_priceActual NUMERIC;
    v_priceLimit NUMERIC;
    v_Tax_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_BPLocation_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    -- Outs: shipments and inventory movements
    Cur_Outs RECORD;
    -- Pend: orderlines-inoutlines not invoiced
    Cur_Pend RECORD;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
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
        p.P_Date,
        i.UpdatedBy
      FROM AD_PINSTANCE i
      LEFT JOIN AD_PINSTANCE_PARA p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_User_ID:=Cur_Parameter.UpdatedBy;
      IF(Cur_Parameter.ParameterName='DateFrom') THEN
        v_DateFrom:=Cur_Parameter.P_Date;
        RAISE NOTICE '%','  DateFrom=' || v_DateFrom ;
      ELSIF(Cur_Parameter.ParameterName='DateTo') THEN
        v_DateTo:=Cur_Parameter.P_Date;
        RAISE NOTICE '%','  DateTo=' || v_DateTo ;
      ELSIF(Cur_Parameter.ParameterName='M_Warehouse_ID') THEN
        v_Warehouse_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  M_Warehouse_ID=' || v_Warehouse_ID ;
      ELSIF(Cur_Parameter.ParameterName='C_BPartner_ID') THEN
        v_BPartner_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  C_BPartner_ID=' || v_BPartner_ID ;
      ELSIF(Cur_Parameter.ParameterName='ReferenceNo') THEN
        v_ReferenceNo:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  ReferenceNo=' || v_ReferenceNo ;
      ELSIF(Cur_Parameter.ParameterName='DateInvoiced') THEN
        v_DateInvoiced:=Cur_Parameter.P_Date;
        RAISE NOTICE '%','  DateInvoiced=' || v_DateInvoiced ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; -- Get Parameter
    FOR Cur_Outs IN
      (SELECT s.AD_Client_ID,
        s.AD_Org_ID,
        p.C_Project_ID,
        pv.M_PriceList_ID,
        sl.M_Product_ID,
        sl.MovementQty,
        sl.C_UOM_ID,
        sl.M_AttributeSetInstance_ID,
        sl.quantityOrder,
        sl.M_Product_UOM_ID
      FROM M_INOUT s,
        M_INOUTLINE sl,
        C_PROJECT p,
        C_PROJECT_VENDOR pv,
        M_LOCATOR l
      WHERE s.M_InOut_ID=sl.M_InOut_ID
        AND s.C_Project_ID=p.C_Project_ID
        AND p.C_Project_ID=pv.C_Project_ID
        AND sl.M_Locator_ID=l.M_Locator_ID
        AND s.IsSOTrx='Y'
        AND s.MovementDate>=v_DateFrom
        AND s.MovementDate<v_DateTo + 1
        AND l.M_Warehouse_ID=v_Warehouse_ID
        AND pv.C_BPartner_ID=v_BPartner_ID
        AND sl.MovementQty<>0
      UNION ALL
      SELECT s.AD_Client_ID,
        s.AD_Org_ID,
        p.C_Project_ID,
        pv.M_PriceList_ID,
        sl.M_Product_ID,
        sl.MovementQty,
        sl.C_UOM_ID,
        sl.M_AttributeSetInstance_ID,
        sl.quantityOrder,
        sl.M_Product_UOM_ID
      FROM M_MOVEMENT s,
        M_MOVEMENTLINE sl,
        C_PROJECT p,
        C_PROJECT_VENDOR pv,
        M_LOCATOR l
      WHERE s.M_Movement_ID=sl.M_Movement_ID
        AND s.C_Project_ID=p.C_Project_ID
        AND p.C_Project_ID=pv.C_Project_ID
        AND sl.M_Locator_ID=l.M_Locator_ID
        AND s.MovementDate>=v_DateFrom
        AND s.MovementDate<v_DateTo + 1
        AND l.M_Warehouse_ID=v_Warehouse_ID
        AND pv.C_BPartner_ID=v_BPartner_ID
        AND sl.MovementQty<>0
      ORDER BY C_Project_ID,
        M_Product_ID,
        C_UOM_ID,
        M_Product_UOM_ID
      )
    LOOP
      v_BPLocation_ID:=C_Getbplocationid(v_BPartner_ID, 'B') ;
      IF(v_Project_ID<>Cur_Outs.C_Project_ID) THEN
        v_NoRecords:=v_NoRecords + 1;
        v_Project_ID:=Cur_Outs.C_Project_ID;
        v_line:=0;
        v_DocType_ID:=Ad_Get_Doctype(Cur_Outs.AD_Client_ID, Cur_Outs.AD_Org_ID, 'API') ;
        --
        SELECT * INTO  v_Invoice_ID FROM Ad_Sequence_Next('C_Invoice', Cur_Outs.AD_Client_ID) ;
        SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(v_DocType_ID, Cur_Outs.AD_Org_ID, 'Y') ;
        IF(v_DocumentNo IS NULL) THEN
          SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Invoice', Cur_Outs.AD_Org_ID, 'Y') ;
        END IF;
        SELECT PAYMENTRULEPO,
          PO_PAYMENTTERM_ID
        INTO v_PaymentRule,
          v_PaymentTerm_ID
        FROM C_BPARTNER
        WHERE C_BPartner_ID=v_BPartner_ID;
        SELECT C_Currency_ID,
          IsTaxIncluded
        INTO v_Currency_ID,
          v_IsTaxIncluded
        FROM M_PRICELIST
        WHERE M_PriceList_ID=Cur_Outs.M_PriceList_ID;
        --
        RAISE NOTICE '%','  Invoice_ID=' || v_Invoice_ID || ' DocumentNo=' || v_DocumentNo ;
        v_ResultStr:='InsertInvoice ' || v_Invoice_ID;
        INSERT
        INTO C_INVOICE
          (
            C_INVOICE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
            CREATED, CREATEDBY, UPDATED, UPDATEDBY,
            ISSOTRX, DOCUMENTNO, DOCSTATUS, DOCACTION,
            PROCESSING, PROCESSED, POSTED, C_DOCTYPE_ID,
            C_DOCTYPETARGET_ID, C_ORDER_ID, DESCRIPTION,
            ISPRINTED, SALESREP_ID, DATEINVOICED, TAXDATE,
            DATEPRINTED, DATEACCT, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID,
            POREFERENCE, ISDISCOUNTPRINTED, DATEORDERED, C_CURRENCY_ID,
            PAYMENTRULE, C_PAYMENTTERM_ID, C_CHARGE_ID, CHARGEAMT,
            TOTALLINES, GRANDTOTAL, M_PRICELIST_ID, ISTAXINCLUDED,
            C_CAMPAIGN_ID, C_PROJECT_ID, C_ACTIVITY_ID,
            CREATEFROM, GENERATETO, AD_USER_ID,
            COPYFROM, ISSELFSERVICE
          )
          VALUES
          (
            v_Invoice_ID, Cur_Outs.AD_Client_ID, Cur_Outs.AD_Org_ID, 'Y',
            TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID,
             'N', v_DocumentNo, 'DR', 'CO',
             'N', 'N', 'N', '0',
            v_DocType_ID, NULL, NULL,
            'N', NULL, v_DateInvoiced, v_DateInvoiced,
            NULL, v_DateInvoiced, v_BPartner_ID, v_BPLocation_ID,
            v_ReferenceNo, 'Y', NULL, v_Currency_ID,
            v_PaymentRule, v_PaymentTerm_ID, NULL, 0,
            0, 0, Cur_Outs.M_PriceList_ID, v_IsTaxIncluded,
            NULL, v_Project_ID, NULL,
             'N', 'N', NULL,
             'N', 'N'
          )
          ;
      END IF;
      v_auxQtyTotal:=0;
      SELECT MAX(PRICELIST), MAX(PRICESTD),  MAX(PRICELIMIT)
      INTO v_priceList, v_priceActual,  v_priceLimit
      FROM M_PRODUCTPRICE
      WHERE M_PriceList_Version_ID=
        (SELECT MIN(M_PriceList_Version_ID)
        FROM M_PRICELIST_VERSION
        WHERE M_PriceList_ID=Cur_Outs.M_PriceList_ID
        )
        AND M_Product_ID=Cur_Outs.M_Product_ID;
      --v_Tax_ID:=C_Gettax(Cur_Outs.M_Product_ID, v_DateInvoiced, Cur_Outs.AD_Org_ID, v_Warehouse_ID, v_BPLocation_ID, v_BPLocation_ID, v_Project_ID, 'N') ;
      v_Tax_ID := zsfi_GetTax( v_BPLocation_ID, Cur_Outs.M_Product_ID, Cur_Outs.AD_Org_ID);
      FOR Cur_Pend IN
        (SELECT dl.M_INOUTLINE_ID,
          ol.C_ORDERLINE_ID,
          (dl.MovementQty - COALESCE(A.QTY, 0)) AS qty
        FROM M_INOUTLINE dl
        LEFT JOIN C_ORDERLINE ol
          ON dl.C_OrderLine_ID=ol.C_OrderLine_ID
        LEFT JOIN C_ORDER o
          ON ol.C_Order_ID=o.C_Order_ID
        LEFT JOIN
          (SELECT M_InOutLine_ID,
            COALESCE(SUM(QTY), 0) AS QTY
          FROM M_MATCHINV
          WHERE C_InvoiceLine_ID IS NOT NULL
          GROUP BY M_InOutLine_ID
          )
          A
          ON dl.M_InOutLine_ID=A.M_InOutLine_ID,
          M_INOUT d
        WHERE d.M_InOut_ID=dl.M_InOut_ID
          AND d.IsSOTrx='N'
          AND dl.MovementQty<>COALESCE(A.QTY, 0)
          AND d.C_BPartner_ID=v_BPartner_ID
          AND dl.M_Product_ID=Cur_Outs.M_Product_ID
          AND(dl.M_ATTRIBUTESETInstance_ID=Cur_Outs.M_AttributeSetInstance_ID
          OR Cur_Outs.M_AttributeSetInstance_ID IS NULL)
        ORDER BY d.MOVEMENTDATE,
          d.M_InOut_ID
        )
      LOOP
        v_auxQty:=LEAST(Cur_Outs.MovementQty-v_auxQtyTotal, Cur_Pend.qty) ;
        v_auxQtyTotal:=v_auxQtyTotal + v_auxQty;
        v_line:=v_line + 10;
        SELECT * INTO  v_InvoiceLine_ID FROM Ad_Sequence_Next('C_InvoiceLine', Cur_Outs.AD_Client_ID) ;
        INSERT
        INTO C_INVOICELINE
          (
            C_INVOICELINE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
            CREATED, CREATEDBY, UPDATED, UPDATEDBY,
            C_INVOICE_ID, C_ORDERLINE_ID, M_INOUTLINE_ID, LINE,
            DESCRIPTION, M_PRODUCT_ID, QTYINVOICED,
   PRICELIST, PRICEACTUAL,
   PRICELIMIT, LINENETAMT,
   C_CHARGE_ID, CHARGEAMT, C_UOM_ID, C_TAX_ID, S_RESOURCEASSIGNMENT_ID,
            TAXAMT, M_ATTRIBUTESETINSTANCE_ID, ISDESCRIPTION,
            QUANTITYORDER, M_PRODUCT_UOM_ID, PriceStd
          )
          VALUES
          (
            v_InvoiceLine_ID, Cur_Outs.AD_Client_ID, Cur_Outs.AD_Org_ID, 'Y',
            TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID,
            v_Invoice_ID, Cur_Pend.C_OrderLine_ID, Cur_Pend.M_InOutLine_ID,
            v_line, NULL, Cur_Outs.M_Product_ID, v_auxQty,
            v_priceList, M_Get_Offers_Price(v_DateInvoiced, v_BPartner_ID, Cur_Outs.M_Product_ID, v_priceActual, v_auxQty, Cur_Outs.M_PriceList_ID),
   v_priceLimit, ROUND(M_Get_Offers_Price(v_DateInvoiced, v_BPartner_ID, Cur_Outs.M_Product_ID, v_priceActual, v_auxQty, Cur_Outs.M_PriceList_ID) *v_auxQty, 2),
            NULL, 0, Cur_Outs.C_UOM_ID, v_Tax_ID, NULL,
            0, Cur_Outs.M_AttributeSetInstance_ID, 'N',
            Cur_Outs.quantityOrder*(v_auxQty/Cur_Outs.MovementQty), Cur_Outs.M_Product_UOM_ID, v_priceActual
          )
          ;
        IF(v_auxQtyTotal>=Cur_Outs.MovementQty) THEN
          EXIT;
        END IF;
      END LOOP;
      IF(v_auxQtyTotal<Cur_Outs.MovementQty) THEN
        v_line:=v_line + 10;
        v_auxQty:=Cur_Outs.MovementQty - v_auxQtyTotal;
        SELECT * INTO  v_InvoiceLine_ID FROM Ad_Sequence_Next('C_InvoiceLine', Cur_Outs.AD_Client_ID) ;
        INSERT
        INTO C_INVOICELINE
          (
            C_INVOICELINE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
            CREATED, CREATEDBY, UPDATED, UPDATEDBY,
            C_INVOICE_ID, C_ORDERLINE_ID, M_INOUTLINE_ID, LINE,
            DESCRIPTION, M_PRODUCT_ID, QTYINVOICED, PRICELIST,
            PRICEACTUAL, PRICELIMIT,
   LINENETAMT, C_CHARGE_ID,
            CHARGEAMT, C_UOM_ID, C_TAX_ID, S_RESOURCEASSIGNMENT_ID,
            TAXAMT, M_ATTRIBUTESETINSTANCE_ID, ISDESCRIPTION,
            QUANTITYORDER, M_PRODUCT_UOM_ID, PriceStd
          )
          VALUES
          (
            v_InvoiceLine_ID, Cur_Outs.AD_Client_ID, Cur_Outs.AD_Org_ID, 'Y',
            TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID,
            v_Invoice_ID, NULL, NULL, v_line,
            NULL, Cur_Outs.M_Product_ID, v_auxQty, v_priceList,
            M_Get_Offers_Price(v_DateInvoiced, v_BPartner_ID, Cur_Outs.M_Product_ID, v_priceActual, v_auxQty, Cur_Outs.M_PriceList_ID), v_priceLimit,
   ROUND(M_Get_Offers_Price(v_DateInvoiced, v_BPartner_ID, Cur_Outs.M_Product_ID, v_priceActual, v_auxQty, Cur_Outs.M_PriceList_ID) *v_auxQty, 2), NULL,
            0, Cur_Outs.C_UOM_ID, v_Tax_ID, NULL,
            0, Cur_Outs.M_AttributeSetInstance_ID, 'N',
            Cur_Outs.quantityOrder*(v_auxQty/Cur_Outs.MovementQty), Cur_Outs.M_Product_UOM_ID, v_priceActual
          )
          ;
      END IF;
    END LOOP;
    ---- <<FINISH_PROCESS>>
    v_Message:=v_Message || '@Created@: ' || v_NoRecords;
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message) ;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_Message ;
  -- ROLLBACK;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message) ;
END ; $_$;



/*------------------------------------------------------

Found in DB, not implemented in scripts ... FW

*/------------------------------------------------------
select zsse_DropView ('c_invoice_v');
CREATE OR REPLACE VIEW c_invoice_v AS 
SELECT 
	i.c_invoice_id, 
	i.ad_client_id, 
	i.ad_org_id, 
	i.isactive, 
	i.created, 
	i.createdby, 
	i.updated, 
	i.updatedby, 
	i.issotrx, 
	i.documentno, 
	i.docstatus, 
	i.docaction, 
	i.processing, 
	i.processed, 
	i.c_doctype_id, 
	i.c_doctypetarget_id, 
	i.c_order_id, 
	i.description, 
	i.salesrep_id, 
	i.dateinvoiced, 
	i.dateprinted, 
	i.dateacct, 
	i.c_bpartner_id, 
	i.c_bpartner_location_id, 
	i.ad_user_id, 
	i.poreference, 
	i.dateordered, 
	i.c_currency_id,
	i.paymentrule,
	i.c_paymentterm_id, 
	i.c_charge_id, 
	i.m_pricelist_id, 
	i.c_campaign_id, 
	i.c_project_id, 
	i.c_activity_id, 
	i.isprinted, 
	i.isdiscountprinted, 
	CASE
		WHEN substr(d.docbasetype, 3) = 'C' THEN i.chargeamt * (-1)::numeric
		ELSE i.chargeamt
	END AS chargeamt, 
	CASE
		WHEN substr(d.docbasetype, 3) = 'C' THEN i.totallines * (-1)::numeric
		ELSE i.totallines
	END AS totallines, 
	CASE
		WHEN substr(d.docbasetype, 3) = 'C' THEN i.grandtotal * (-1)::numeric
		ELSE i.grandtotal
	END AS grandtotal, 
	CASE
		WHEN substr(d.docbasetype, 3) = 'C' THEN (-1)
		ELSE 1
	END AS multiplier, 
	CASE
		WHEN substr(d.docbasetype, 2, 1) = 'P' THEN (-1)
		ELSE 1
	END AS multiplierap, d.docbasetype
FROM c_invoice i
JOIN c_doctype d ON i.c_doctype_id = d.c_doctype_id;

select zsse_DropView ('c_invoice_header_v');
CREATE OR REPLACE VIEW c_invoice_header_v AS 
 SELECT i.ad_client_id, i.ad_org_id, i.isactive, i.created, i.createdby, i.updated, i.updatedby, to_char('en_US') AS ad_language, i.c_invoice_id, i.issotrx, i.documentno, i.docstatus, i.c_doctype_id, i.c_bpartner_id, bp.value AS bpvalue, oi.c_location_id AS org_location_id, oi.taxid, dt.printname AS documenttype, dt.documentnote AS documenttypenote, i.c_order_id, i.salesrep_id, COALESCE(ubp.name, u.name) AS salesrep_name, i.dateinvoiced, bpg.name AS bpgreeting, bp.name, bp.name2, bpcg.name AS bpcontactgreeting, bpc.title, NULLIF(bpc.name, bp.name) AS contactname, bpl.c_location_id, bp.referenceno, i.description, i.poreference, i.dateordered, i.c_currency_id, pt.name AS paymentterm, pt.documentnote AS paymenttermnote, i.c_charge_id, i.chargeamt, i.totallines, i.grandtotal, i.m_pricelist_id, i.istaxincluded, i.c_campaign_id, i.c_project_id, i.c_activity_id
   FROM c_invoice i
   JOIN c_doctype dt ON i.c_doctype_id = dt.c_doctype_id
   JOIN c_paymentterm pt ON i.c_paymentterm_id = pt.c_paymentterm_id
   JOIN c_bpartner bp ON i.c_bpartner_id = bp.c_bpartner_id
   LEFT JOIN c_greeting bpg ON bp.c_greeting_id = bpg.c_greeting_id
   JOIN c_bpartner_location bpl ON i.c_bpartner_location_id = bpl.c_bpartner_location_id
   LEFT JOIN ad_user bpc ON i.ad_user_id = bpc.ad_user_id
   LEFT JOIN c_greeting bpcg ON bpc.c_greeting_id = bpcg.c_greeting_id
   JOIN ad_orginfo oi ON i.ad_org_id = oi.ad_org_id
   LEFT JOIN ad_user u ON i.salesrep_id = u.ad_user_id
   LEFT JOIN c_bpartner ubp ON u.c_bpartner_id = ubp.c_bpartner_id;

select zsse_DropView ('c_invoice_header_vt');
CREATE OR REPLACE VIEW c_invoice_header_vt AS 
 SELECT i.ad_client_id, i.ad_org_id, i.isactive, i.created, i.createdby, i.updated, i.updatedby, dt.ad_language, i.c_invoice_id, i.issotrx, i.documentno, i.docstatus, i.c_doctype_id, i.c_bpartner_id, bp.value AS bpvalue, oi.c_location_id AS org_location_id, oi.taxid, dt.printname AS documenttype, dt.documentnote AS documenttypenote, i.c_order_id, i.salesrep_id, COALESCE(ubp.name, u.name) AS salesrep_name, i.dateinvoiced, bpg.name AS bpgreeting, bp.name, bp.name2, bpcg.name AS bpcontactgreeting, bpc.title, NULLIF(bpc.name, bp.name) AS contactname, bpl.c_location_id, bp.referenceno, i.description, i.poreference, i.dateordered, i.c_currency_id, pt.name AS paymentterm, pt.documentnote AS paymenttermnote, i.c_charge_id, i.chargeamt, i.totallines, i.grandtotal, i.m_pricelist_id, i.istaxincluded, i.c_campaign_id, i.c_project_id, i.c_activity_id
   FROM c_invoice i
   JOIN c_doctype_trl dt ON i.c_doctype_id = dt.c_doctype_id
   JOIN c_paymentterm_trl pt ON i.c_paymentterm_id = pt.c_paymentterm_id AND dt.ad_language = pt.ad_language
   JOIN c_bpartner bp ON i.c_bpartner_id = bp.c_bpartner_id
   LEFT JOIN c_greeting_trl bpg ON bp.c_greeting_id = bpg.c_greeting_id AND dt.ad_language = bpg.ad_language
   JOIN c_bpartner_location bpl ON i.c_bpartner_location_id = bpl.c_bpartner_location_id
   LEFT JOIN ad_user bpc ON i.ad_user_id = bpc.ad_user_id
   LEFT JOIN c_greeting_trl bpcg ON bpc.c_greeting_id = bpcg.c_greeting_id AND dt.ad_language = bpcg.ad_language
   JOIN ad_orginfo oi ON i.ad_org_id = oi.ad_org_id
   LEFT JOIN ad_user u ON i.salesrep_id = u.ad_user_id
   LEFT JOIN c_bpartner ubp ON u.c_bpartner_id = ubp.c_bpartner_id;


   
CREATE OR REPLACE FUNCTION c_subscriptionInvoiceRun(p_pinstance_id character varying)
RETURNS void AS
$BODY$ 
DECLARE 
    v_Message varchar:='';
    v_currentBPId varchar:='';
    v_C_Invoice_ID varchar;
    v_currentORDERId varchar:='';
    v_currentLocId varchar:='';
    v_currentPLId varchar:='';
    v_currency varchar;
    v_payterm varchar;
    v_paymentrule varchar;
    v_DocumentNo varchar;
    v_User varchar;
    v_C_DOCTYPE_ID varchar:='45A90145C74C44ECB48AC772B05487CA'; -- Rechnung
    v_count numeric:=0;
    v_lines numeric;
    v_cur RECORD;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ; --c_subscriptionInvoiceRun
    if (select count(*) from  AD_Process_Run r ,ad_process_request rq WHERE r.ad_process_request_id=rq.ad_process_request_id 
               and rq.AD_Process_ID ='F876F44542E74B19AB8F123F025EBFBF' and r.Status='PRC')>1 then
        RAISE EXCEPTION '%' ,'@ProcessExecutes@';
    end if;
    SELECT  i.AD_User_ID into v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    
    for v_cur in (SELECT v.AD_Client_ID,v.AD_Org_ID,v.C_OrderLine_ID,v.M_Product_ID,v.Qtyordered,coalesce(o.contractdate,o.scheddeliverydate) as performanceperiodstart,
                  o.enddate as performanceperiodend,o.c_project_id as headprj,o.c_projecttask_id as headpt,o.poreference,
                  o.salesrep_Id ,o.ad_user_id,o.internalnote,o.description,l.textposition,v.description as ldescription,
                  v.PriceList,v.PriceActual,v.C_UOM_ID,v.C_Tax_ID,v.Line,v.PriceStd,v.m_attributesetinstance_id,l.c_project_id,l.c_projecttask_id,v.c_order_id,
                  v.c_doctype_id, v.datepromised, v.dateordered,v.documentno,v.c_bpartner_id, v.pendingamt,  v.pendingqty,  v.pendingprice 
                 from c_invoice_candidate_lines_v v,c_order o,c_orderline l where v.c_order_id=o.c_order_id and v.c_orderline_id=l.c_orderline_id and
                 v.c_doctype_id='6C8EA6FFBB2B4ACBA0542BA4F833C499' order by v.c_bpartner_id,v.c_order_id,v.line)
    LOOP
        if  v_currentBPId!=v_cur.c_bpartner_id or v_currentORDERId!= v_cur.c_order_id
        then
                if v_lines>0 and v_C_Invoice_ID is not null then
                    PERFORM C_INVOICE_POST(NULL, v_C_Invoice_ID) ; 
                end if;
                if v_lines=0 and v_C_Invoice_ID is not null then
                    delete from c_invoice where c_invoice_id= v_C_Invoice_ID ; 
                    v_count:=v_count-1;
                end if;
                v_C_Invoice_ID:=get_uuid();
                v_count:=v_count+1;
                v_currentBPId:=v_cur.c_bpartner_id;
                v_currentORDERId:=v_cur.c_order_id;
                select m_pricelist_id,c_currency_id,billto_id,c_paymentterm_id,PaymentRule into v_currentPLId,v_currency,v_currentLocId,v_payterm,v_paymentrule
                       from c_order where c_order_id=v_cur.c_order_id;
                SELECT * INTO  v_DocumentNo FROM AD_Sequence_DocType(v_C_DOCTYPE_ID, v_cur.ad_Org_ID, 'Y') ;
                IF(v_DocumentNo IS NULL) THEN
                    SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('DocumentNo_C_Invoice', v_Org_ID, 'Y') ;
                END IF;
                INSERT INTO C_INVOICE
                (C_Invoice_ID,
                AD_Client_ID, AD_Org_ID,  CreatedBy,  UpdatedBy,
                IsSOTrx, DocumentNo, DocStatus, DocAction, Processing, Processed,
                C_DocType_ID, C_DocTypeTarget_ID, 
                 DateInvoiced,  DateAcct, 
                C_PaymentTerm_ID, C_BPartner_ID, C_BPartner_Location_ID, 
                DateOrdered, C_Currency_ID, PaymentRule,  M_PriceList_ID,c_order_id,
                performanceperiodstart,performanceperiodend,c_project_id,c_projecttask_id,salesrep_Id ,ad_user_id,internalnote,description,poreference)
                VALUES
                (v_C_Invoice_ID, v_cur.ad_client_id,
                v_cur.ad_Org_ID, v_User,v_User,
                'Y', v_DocumentNo, 'DR', 'CO', 'N', 'N',
                v_C_DocType_ID, v_C_DocType_ID, 
                trunc(now()),trunc(now()), v_payterm,v_cur.c_bpartner_id,v_currentLocId,
                trunc(now()),v_currency,v_paymentrule,
                v_currentPLId,v_cur.c_order_id,
                v_cur.performanceperiodstart,v_cur.performanceperiodend,v_cur.headprj,v_cur.headpt,v_cur.salesrep_Id ,v_cur.ad_user_id,v_cur.internalnote,v_cur.description,v_cur.poreference);
                v_lines:=0;
        end if;
        v_lines:=v_lines+10;
        INSERT INTO C_INVOICELINE
                (C_InvoiceLine_ID,c_orderline_id,
                AD_Client_ID, AD_Org_ID,  CreatedBy,  UpdatedBy,
                C_Invoice_ID, 
                Line, Description,
                M_Product_ID, QtyInvoiced, PriceList, PriceActual,  C_UOM_ID, C_Tax_ID, textposition,c_project_id,c_projecttask_id)
            VALUES
                (get_uuid(),v_cur.C_OrderLine_ID,
                v_cur.ad_client_id,v_cur.ad_Org_ID, v_User,v_User,
                v_C_Invoice_ID,v_lines,
                v_cur.ldescription,
                v_cur.m_product_id,v_cur.pendingqty,v_cur.pendingprice,v_cur.pendingprice,v_cur.c_UOM_ID, v_cur.c_Tax_ID,v_cur.textposition,
                v_cur.c_project_id,v_cur.c_projecttask_id);
    ENd LOOP;
    if v_lines>0 and v_C_Invoice_ID is not null then
          PERFORM C_INVOICE_POST(NULL, v_C_Invoice_ID) ; 
    end if;
    if v_lines=0 and v_C_Invoice_ID is not null then
        delete from c_invoice where c_invoice_id= v_C_Invoice_ID ; 
    end if;
    v_Message:=coalesce(v_count,0)||' Abo-Rechnungen erstellt. Sie finden die Rechnungen unter Vertrieb / Rechnungen an Kunden.';
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

  

CREATE OR REPLACE FUNCTION c_generateinvoicemanual_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*****************************************************/
v_count          numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  IF (TG_OP = 'INSERT' ) THEN
     SELECT * INTO  new.line FROM AD_Sequence_Doc('DocumentNo_I_Invoice', '0', 'Y');
  END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_DropTrigger ('c_generateinvoicemanual_trg','c_generateinvoicemanual');

CREATE TRIGGER c_generateinvoicemanual_trg
  before INSERT
  ON c_generateinvoicemanual FOR EACH ROW
  EXECUTE PROCEDURE c_generateinvoicemanual_trg();
  
  
CREATE or replace FUNCTION einv_getXtypeUBLXML(v_invoice_id character varying,v_lang character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020 OpenZ Software GmbH All Rights Reserved.
Contributor(s): ______________________________________.
Replaces Column description in Rpt_Productionreport.jrxml -> Subreport RptStd_PTasks.jrxml
***************************************************************************************************************************************************/
DECLARE

BEGIN
RETURN '';
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100; 


  
/* DRUCKAUSGABE FÜR SAMMELRECHNUNGEN */  
  
CREATE OR REPLACE FUNCTION get_OrdNoBP_for_c_invoice_print(v_invoice_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
Called in Application Dictionary || Reference  || Reference Invoice List || Reference List || OrdNoBP

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*****************************************************/
v_return_val varchar;

BEGIN
  -- old:
  -- @SQL=SELECT CASE WHEN (C_INVOICE.POREFERENCE is null) THEN C_ORDER.DOCUMENTNO ELSE C_INVOICE.POREFERENCE END from C_INVOICE LEFT JOIN C_ORDER on c_invoice.c_order_id=c_order.c_order_id  WHERE C_INVOICE.C_INVOICE_ID = #ID#

  -- first priority poreference
  SELECT poreference INTO v_return_val FROM c_invoice WHERE c_invoice_id = v_invoice_id;
  -- second priority documentno
  IF(v_return_val IS NULL) THEN
      SELECT documentno INTO v_return_val FROM c_order WHERE c_order_id = (
         SELECT c_order_id FROM c_invoice WHERE c_invoice_id = v_invoice_id
      );
  END IF;
  -- still null means combined invoice
  -- third priority documentno of the first line/order of the invoice
  -- add dots for multiple orders in invoice
  IF(v_return_val IS NULL) THEN
      SELECT documentno INTO v_return_val FROM c_order WHERE c_order_id = (
        SELECT c_order_id FROM c_orderline WHERE c_orderline_id = (
          SELECT c_orderline_id FROM c_invoiceline WHERE c_invoice_id = v_invoice_id AND c_orderline_id IS NOT NULL ORDER BY line LIMIT 1
        )
      );
      v_return_val := v_return_val || ', ...';
  END IF;

  -- else empty
  IF(v_return_val IS NULL) THEN
      v_return_val := '';
  END IF;

  return v_return_val;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION get_Contact_for_c_invoice_print(v_invoice_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
Called in Application Dictionary || Reference  || Reference Invoice List || Reference List || Contact

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*****************************************************/
v_return_val varchar;

BEGIN
  -- old:
  -- @SQL=SELECT u.name from ad_user u,c_invoice m where m.salesrep_id=u.ad_user_id and m.c_invoice_id=#ID#
  SELECT u.name INTO v_return_val from ad_user u,c_invoice m where m.salesrep_id=u.ad_user_id and m.c_invoice_id=v_invoice_id;
  -- 1St Order of Invoice
  IF(v_return_val IS NULL) THEN
      SELECT u.name  INTO v_return_val from c_order o,ad_user u where o.salesrep_id=u.ad_user_id and o.c_order_id = (
        SELECT c_order_id FROM c_orderline WHERE c_orderline_id = (
          SELECT c_orderline_id FROM c_invoiceline WHERE c_invoice_id = v_invoice_id AND c_orderline_id IS NOT NULL ORDER BY line LIMIT 1
        ));
  ENd IF;
  -- else empty
  IF(v_return_val IS NULL) THEN
      v_return_val := '';
  END IF;

  return v_return_val;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION get_Phone_for_c_invoice_print(v_invoice_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
Called in Application Dictionary || Reference  || Reference Invoice List || Reference List || Phone

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*****************************************************/
v_return_val varchar;

BEGIN
  -- old:
  -- @SQL=SELECT zssi_getuserphone(C_INVOICE.salesrep_id) from C_INVOICE where C_INVOICE.C_INVOICE_ID = #ID#
  SELECT zssi_getuserphone(u.ad_user_id) INTO v_return_val from ad_user u,c_invoice m where m.salesrep_id=u.ad_user_id and m.c_invoice_id=v_invoice_id;
  -- 1St Order of Invoice
  IF(v_return_val IS NULL) THEN
      SELECT zssi_getuserphone(u.ad_user_id)  INTO v_return_val from c_order o,ad_user u where o.salesrep_id=u.ad_user_id and o.c_order_id = (
        SELECT c_order_id FROM c_orderline WHERE c_orderline_id = (
          SELECT c_orderline_id FROM c_invoiceline WHERE c_invoice_id = v_invoice_id AND c_orderline_id IS NOT NULL ORDER BY line LIMIT 1
        ));
  ENd IF;
  -- else empty
  IF(v_return_val IS NULL) THEN
      v_return_val := '';
  END IF;

  return v_return_val;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION get_Email_for_c_invoice_print(v_invoice_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
Called in Application Dictionary || Reference  || Reference Invoice List || Reference List || Email

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*****************************************************/
v_return_val varchar;

BEGIN
  -- old:
  -- @SQL=SELECT zssi_getuseremail(C_INVOICE.salesrep_id) from C_INVOICE where C_INVOICE.C_INVOICE_ID = #ID#
  SELECT zssi_getuseremail(u.ad_user_id) INTO v_return_val from ad_user u,c_invoice m where m.salesrep_id=u.ad_user_id and m.c_invoice_id=v_invoice_id;
  -- 1St Order of Invoice
  IF(v_return_val IS NULL) THEN
      SELECT zssi_getuseremail(u.ad_user_id)  INTO v_return_val from c_order o,ad_user u where o.salesrep_id=u.ad_user_id and o.c_order_id = (
        SELECT c_order_id FROM c_orderline WHERE c_orderline_id = (
          SELECT c_orderline_id FROM c_invoiceline WHERE c_invoice_id = v_invoice_id AND c_orderline_id IS NOT NULL ORDER BY line LIMIT 1
        ));
  ENd IF;
  -- else empty
  IF(v_return_val IS NULL) THEN
      v_return_val := '';
  END IF;

  return v_return_val;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION get_Ordname_for_c_invoice_print(v_invoice_id character varying)
  RETURNS character varying AS
$BODY$ DECLARE
/***************************************************************************************************************************************************
Called in Application Dictionary || Reference  || Reference Invoice List || Reference List || Name (Ord)

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
**************************************************************************************************************************************************
*****************************************************/
v_return_val varchar;

BEGIN
  -- old:
  -- @SQL=select COALESCE(C_ORDER.NAME,'') from C_INVOICE LEFT JOIN C_ORDER ON C_ORDER.C_ORDER_ID = C_INVOICE.C_ORDER_ID WHERE C_INVOICE.C_INVOICE_ID = #ID#
  SELECT o.name INTO v_return_val from c_invoice m,c_order o where m.c_order_id=o.c_order_id and m.c_invoice_id=v_invoice_id;
  -- 1St Order of Invoice
  IF(v_return_val IS NULL) THEN
      SELECT o.name INTO v_return_val from c_order o where o.c_order_id = (
        SELECT c_order_id FROM c_orderline WHERE c_orderline_id = (
          SELECT c_orderline_id FROM c_invoiceline WHERE c_invoice_id = v_invoice_id AND c_orderline_id IS NOT NULL ORDER BY line LIMIT 1
        ));
  ENd IF;
  -- else empty
  IF(v_return_val IS NULL) THEN
      v_return_val := '';
  END IF;

  return v_return_val;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
/* DRUCKAUSGABE FÜR SAMMELRECHNUNGEN ENDE*/ 
