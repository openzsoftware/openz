CREATE OR REPLACE FUNCTION zssi_c_order_bpzipcode_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers.
***************************************************************************************************************************************************
Part of Smartprefs
ZIP-Code from Location and updates Order - Value in Case of Contract Changes
Updates Order-Value for Subscriptions
*****************************************************/ 
v_location_id                     character varying;
v_bpzipcode                       character varying;
v_comp                            timestamp without time zone:=now();
v_salesregion                     varchar;
BEGIN
        -- Currency of Pricelist=currency of Order
        IF TG_OP = 'INSERT' THEN
            select c_currency_id into new.c_currency_id from m_pricelist where m_pricelist_id=new.m_pricelist_id;
        END IF;
        IF TG_OP = 'UPDATE' THEN
            if new.m_pricelist_id!=old.m_pricelist_id then
                select c_currency_id into new.c_currency_id from m_pricelist where m_pricelist_id=new.m_pricelist_id;
            end if;
        END IF;
        IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') then
                select c_location_id,c_salesregion_id into v_location_id,v_salesregion  from c_bpartner_location where c_bpartner_location.c_bpartner_location_id=new.c_bpartner_location_id;
                select postal into v_bpzipcode from c_location where c_location.c_location_id=v_location_id;
                new.bpzipcode:=substr(v_bpzipcode,1,10);
                --daily charge ONLY on Monthly Subsription Orders
                if coalesce(new.invoicefrequence,'')!=  'MON' then
                    new.subsrdailyratebilling:='N';
                end if;
                -- Implementing Sales Region.
                if TG_OP = 'INSERT' and new.c_salesregion_id is null then
                    new.c_salesregion_id:=v_salesregion;
                end if;
                if TG_OP = 'UPDATE'  then
                    if new.c_bpartner_location_id!=old.c_bpartner_location_id and coalesce(new.c_salesregion_id,'')=coalesce(old.c_salesregion_id,'') then
                        new.c_salesregion_id:=v_salesregion;
                    end if;
                end if;
                -- Restriction on Purchasing -> Always use Invoice-Rule Immediately
                if new.issotrx='N' then
                    new.invoicerule:='I';
                end if;
                If TG_OP = 'INSERT' then
                      new.firstschedinvoicedate:=zssi_getFirstInvoiceDate(new.contractdate,new.yearly_month,new.invoicefrequence,new.weekly_day,new.monthly_day,new.quarterly_month,new.isinvoiceafterfirstcycle);
                      if new.datepromised is not null then
                        new.schedtransactiondate:=C_PaymentduedateByPayterm(new.c_bpartner_id,new.c_paymentterm_id,new.issotrx,new.paymentrule,new.datepromised);
                      end if;
                END IF; 
                If TG_OP = 'UPDATE' then
                   if  new.completeordervalue=old.completeordervalue
                       and (coalesce(new.contractdate,v_comp)!=coalesce(old.contractdate,v_comp)
                            or coalesce(new.invoicefrequence,'X')!=coalesce(old.invoicefrequence,'X')
                            or coalesce(new.enddate,v_comp)!=coalesce(old.enddate,v_comp)
                            or coalesce(new.monthly_day,1)!=coalesce(old.monthly_day,1)
                            or new.isinvoiceafterfirstcycle!=old.isinvoiceafterfirstcycle)
                   then
                        new.completeordervalue:=zssi_getVALUE4orderBySheduleParameters(new.c_order_id ,new.c_doctypetarget_id,new.invoicefrequence,new.contractdate,new.enddate);
                        new.firstschedinvoicedate:=zssi_getFirstInvoiceDate(new.contractdate,new.yearly_month,new.invoicefrequence,new.weekly_day,new.monthly_day,new.quarterly_month,new.isinvoiceafterfirstcycle); 
                   end if;
                   if new.c_paymentterm_id!=old.c_paymentterm_id or coalesce(new.datepromised,trunc(now()))!=coalesce(old.datepromised,trunc(now())) then
                     if new.datepromised is not null then
                        new.schedtransactiondate:=C_PaymentduedateByPayterm(new.c_bpartner_id,new.c_paymentterm_id,new.issotrx,new.paymentrule,new.datepromised);
                     else
                        new.schedtransactiondate:=null;
                     end if;
                   end if;
                end if;
        end if;
RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION zssi_c_order_bpzipcode_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION  c_orderline2_trg() RETURNS trigger
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
/*
 Contributions: 
        Disabled secondary UOM.
        2nd UOM is not transacted to Storage.
        It is only Used on Orders, Invoices and  in InOut-Transactions.
        If deliverycomplete Option is set : All reservations must be cancelled.

Note:   This Trigger Updates Storage Pending and Fires only On Updates when an Item is delivered
*/
  v_QtyReservedSO      NUMERIC;
  v_QtyReservedPO      NUMERIC;
  v_qty                NUMERIC:=0;
  v_qtydelivered       NUMERIC:=0;
  v_issotrx          character varying;
  V_STOCKED          NUMERIC;
  v_count            NUMERIC; 
  v_ordervalue       NUMERIC:=0; 
  v_isdelofservice  character varying;
  v_producttype character varying;
  v_status character varying;
  v_doctype   varchar;
  v_called numeric;
  v_ordered numeric;
  v_begin timestamp;
  v_end timestamp;
  v_pricelist numeric;
  v_priceactual numeric;
  v_pricelimit numeric;
  v_warehouse varchar;
  v_cur RECORD;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  IF(TG_OP = 'DELETE') then
    select c_doctypetarget_id,m_warehouse_id into v_doctype,v_warehouse from c_order where c_order_id=old.c_order_id;
  else
    select c_doctypetarget_id,m_warehouse_id into v_doctype,v_warehouse from c_order where c_order_id=new.c_order_id;
  end if;
  -- Prevent DELIVERY OF SERVICES
  IF(TG_OP = 'INSERT') or (TG_OP = 'UPDATE') THEN
    -- Set Option deliverycomplete, when Item is a service.
     select c_getconfigoption('deliveryofservices',new.ad_org_id) into v_isdelofservice;
     IF(NEW.M_PRODUCT_ID IS NOT NULL) THEN
         select producttype into v_producttype from m_product where m_product.m_product_id = new.M_PRODUCT_ID;
         if v_isdelofservice='N' THEN
             if TG_OP = 'UPDATE' and NEW.M_PRODUCT_ID!=coalesce(OLD.M_PRODUCT_ID,'')  then
                 if  v_producttype='I' then
                    new.deliverycomplete:='N';
                 else
                    new.deliverycomplete:='Y';
                 end if;
             END IF;
             if TG_OP = 'INSERT' and v_producttype!='I' then
                 new.deliverycomplete:='Y';
             END IF; 
         END IF;
     END IF;
     -- On Frame Contract Calloffs the Contract and its qty must be valid
     if v_doctype in ('5EED1EFB8BDD4C0491ECCFD7395DA446','9D7785AF1F0D4C51A0B1DF45F5DC9EE5') then
        if new.orderlineselfjoin is null then
            RAISE EXCEPTION '%', '@FrameCallOffsMustHaveContract@'; 
        end if;
        select coalesce(ol.calloffqty,0) ,ol.qtyordered,o.contractdate,o.enddate,ol.pricelist,ol.priceactual,ol.pricelimit
               into v_called,v_ordered,v_begin,v_end,v_pricelist,v_priceactual,v_pricelimit
               from c_order o,c_orderline ol where ol.c_order_id=o.c_order_id and ol.c_orderline_id=new.orderlineselfjoin;
        if new.scheddeliverydate is not null then
            if coalesce(v_begin,trunc(now())) > new.scheddeliverydate or coalesce(v_end,trunc(now())) < new.scheddeliverydate then
                RAISE EXCEPTION '%', '@FrameContractneedsDate@';  
            end if;
        end if;
        if TG_OP = 'INSERT' then
            if v_ordered-v_called<new.qtyordered then
                RAISE EXCEPTION '%', '@FrameCallOffOutOfRange@';  
            end if;
        end if;
        if TG_OP = 'UPDATE' then
          if new.qtyordered!=old.qtyordered then
            if v_ordered-v_called<new.qtyordered then
                RAISE EXCEPTION '%', '@FrameCallOffOutOfRange@';  
            end if;
          end if;
          -- Überlieferungen bei Rahmenvertrags-Abrufen
          if (old.qtydelivered!=new.qtydelivered) then
            -- Überlieferung (Warenein/ausgang)
            if new.qtydelivered>old.qtydelivered and new.qtydelivered>new.qtyordered then
                update c_orderline set calloffqty=coalesce(calloffqty,0) + (new.qtydelivered - new.qtyordered) where c_orderline_id=new.orderlineselfjoin;
            end if;
            -- Überlieferung (Warenein/ausgang) / STORNO
            if new.qtydelivered<old.qtydelivered and old.qtydelivered>new.qtyordered then
                update c_orderline set calloffqty=coalesce(calloffqty,0) - (old.qtydelivered - new.qtyordered) where c_orderline_id=new.orderlineselfjoin;
            end if;
          end if;
          -- Unterlieferungen bei Rahmenvertrags-Abrufen#
          if (old.deliverycomplete!=new.deliverycomplete and (select docstatus from c_order where c_order_id=new.c_order_id)='CO') then
            if new.deliverycomplete='Y' then
                update c_orderline set calloffqty=coalesce(calloffqty,0) - (new.qtyordered-new.qtydelivered) where c_orderline_id=new.orderlineselfjoin;
            end if;
            if new.deliverycomplete='N' then
                update c_orderline set calloffqty=coalesce(calloffqty,0) + (new.qtyordered-old.qtydelivered) where c_orderline_id=new.orderlineselfjoin;
            end if;
          end if;
          -- Überschreitung der Menge bei überlieferungen ?
          if (select qtyordered-coalesce(calloffqty,0) from c_orderline where c_orderline_id=new.orderlineselfjoin)<0 then
                RAISE EXCEPTION '%', '@FrameCallOffOutOfRange@';  
          end if;
        end if;
        if (select docstatus from c_order where c_order_id=new.c_order_id)='DR' then
            new.priceactual:=v_priceactual;
            new.pricelimit:=v_pricelimit;
            new.pricelist:=v_pricelist;
        end if;
     end if;
     if(c_getconfigoption('framecontractoptional',new.ad_org_id)='N') then
        -- On PO or SO a valid frame contract schould be used
        if ad_get_docbasetype(v_doctype) in ('SOO','POO') and v_doctype not in ('5EED1EFB8BDD4C0491ECCFD7395DA446','9D7785AF1F0D4C51A0B1DF45F5DC9EE5') then
           if (select count(*) from c_orderline ol,c_order o where o.c_order_id=ol.c_order_id and o.contractdate <=now() and o.enddate>=now() and 
                      case when o.issotrx='Y' then o.c_doctype_id= '559A80F2E27742D4B2C476045F5C834F' else  o.c_doctype_id= '56913A519BA94EB59DAE5BF9A82F5F7D' end
                      and o.c_bpartner_id=(select c_bpartner_id from c_order where c_order_id=new.c_order_id)
                      and ol.deliverycomplete='N' and ol.m_product_id=new.m_product_id and o.docstatus='CO' and 
                      coalesce(ol.m_product_po_id,'')= coalesce(new.m_product_po_id,'') and coalesce(ol.m_product_uom_id,'')= coalesce(new.m_product_uom_id,'')) >0 
           then
             if (select docstatus from c_order where c_order_id=new.c_order_id)!='CO' then
               RAISE EXCEPTION '%', '@FrameContractExists@:'||(select name from m_product where m_product_id=new.m_product_id); 
             end if;
           end if;
        end if;
     end if;
  END IF;
  IF(TG_OP = 'UPDATE') THEN
    -- Sauberer Umgang mit Projektzuordnung
    if coalesce(new.c_project_id, '0') != coalesce(old.c_project_id, '0') and new.c_project_id is null then
                    new.c_projecttask_id:=null;
    end if;
    -- Pendings-Update only on active Documents.
    select docstatus into v_status from c_order where c_order_id=new.c_order_id;
    IF(NEW.M_PRODUCT_ID IS NOT NULL) and v_status='CO' THEN
       SELECT COUNT(*) INTO V_STOCKED
        FROM M_PRODUCT
        WHERE M_Product_ID=NEW.M_PRODUCT_ID AND IsStocked='Y' AND ProductType='I';
      IF((old.QtyDelivered <> NEW.QtyDelivered) or old.deliverycomplete != new.deliverycomplete) THEN
        -- Get ID
        if old.QtyDelivered > NEW.QtyDelivered then
           v_qtydelivered:=old.QtyDelivered;
        else
           v_qtydelivered:=new.QtyDelivered;
        end if;
        if old.deliverycomplete != new.deliverycomplete then
          if new.deliverycomplete='Y' then
            v_qty:=(new.qtyordered-v_qtydelivered)*-1;
            new.Qtyreserved:=0;
          else
            v_qty:=new.qtyordered-v_qtydelivered;
            if V_STOCKED > 0 then
                new.Qtyreserved:=new.qtyordered-new.QtyDelivered;
            end if;
          end if;
        end if;
        if old.QtyDelivered <> NEW.QtyDelivered then
           v_qty:=v_qty-(new.qtydelivered - old.qtydelivered) ;
        end if;
        select issotrx into v_issotrx from c_order where c_order_id=new.c_order_id;
        if v_issotrx='Y' then 
           v_QtyReservedSO:= v_qty;
           v_QtyReservedPO:=0;
        else
           v_QtyReservedPO:= v_qty;
           v_QtyReservedSO:=0;
        end if;
        
       
        -- Pendings-Update only on active Documents.
        IF V_STOCKED > 0 THEN
         -- PERFORM M_UPDATE_STORAGE_PENDING(new.AD_Client_ID, new.AD_Org_ID, new.UpdatedBy, new.M_Product_ID, v_warehouse, new.M_AttributeSetInstance_ID, new.C_UOM_ID, null, v_QtyReservedSO, null, v_QtyReservedPO, NULL) ;
        END IF;
      END IF;
    END IF; -- new product not null
  END IF; -- UPDATE
  -- Remove assigned Requisition Lines
  IF(TG_OP = 'DELETE') then
    for v_cur in (select m_requisitionline_id from m_requisitionorder where c_orderline_id=old.c_orderline_id)
    LOOP
        delete from m_requisitionorder where m_requisitionline_id=v_cur.m_requisitionline_id;
        update m_requisition set docstatus='CO' where m_requisition_id=(select m_requisition_id from m_requisitionline where m_requisitionline_id=v_cur.m_requisitionline_id);
        update m_requisitionline set reqstatus='O',lockedby=null,lockqty=null,lockprice=null,lockdate=null,lockcause=null,rejected='N' where m_requisitionline_id=v_cur.m_requisitionline_id;
    END LOOP;
  end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;

drop trigger c_orderline2_trg on c_orderline;

CREATE TRIGGER c_orderline2_trg 
  BEFORE INSERT OR UPDATE OR DELETE
  ON c_orderline
  FOR EACH ROW
  EXECUTE PROCEDURE c_orderline2_trg();


 

CREATE OR REPLACE FUNCTION c_order_post1(p_pinstance_id character varying, p_order_id character varying) RETURNS void
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

/*
 Contributions: 
        Reorganized Code
        Remove Rubbish BOM Breakup
        On Processing (PR) do NOT Reserve Material. Reserve Inventory only on Completing (CO) and Un-Reserve on Reactivate (RE)
        Otherwise Reservation is Done twice
        Closing doesn't make sense - Disabled Otherwise: No Receipt possible while Reservaton still exists
        Removed any! Price-Calculations - These are done trough trigger
        Removed Cashbook entrys - Tey are done trough Invoice on POS-Orders
        Disabled secondary UOM.
        2nd UOM is not transacted to Storage. - It is only Used on Orders, Invoices and  in InOut-Transactions
*************************************************************************************************************************************************/
  -- Logistics
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_orderselfjoin varchar;
  v_User VARCHAR(32); --OBTG:VARCHAR2--
  v_IsProcessing CHAR(1) ;
  v_IsProcessed VARCHAR(60) ;
  v_Result NUMERIC:=1; -- Success
  v_is_included NUMERIC:=0;
  v_is_ready AD_Org.IsReady%TYPE;
  v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    Cur_Order RECORD;
    -- Record Info
    v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Org_Name VARCHAR(60); --OBTG:VARCHAR2--
    v_UpdatedBy VARCHAR(32); --OBTG:VARCHAR2--
    v_DocAction VARCHAR(60) ;
    v_DocStatus VARCHAR(60) ;
    v_InvoiceRule VARCHAR(60) ;
    v_M_Warehouse_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_DocType_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_DocTypeTarget_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_DocSubTypeSO VARCHAR(60) ;
    v_DocSubTypeSOTarget VARCHAR(60) ;
    --
    ToDeliver NUMERIC;
    ToInvoice NUMERIC;
    --
    InOut_ID VARCHAR(32); --OBTG:VARCHAR2--
    Invoice_ID VARCHAR(32); --OBTG:VARCHAR2--
    --Added by P.SAROBE
        v_documentno_Settlement VARCHAR(40); --OBTG:VARCHAR2--
        v_dateSettlement TIMESTAMP;
        v_Cancel_Processed VARCHAR(60);
        v_nameBankstatement VARCHAR (60); --OBTG:VARCHAR2--
        v_dateBankstatement TIMESTAMP;
        v_nameCash VARCHAR (60); --OBTG:VARCHAR2--
        v_dateCash TIMESTAMP;
        v_Bankstatementline_ID VARCHAR(32); --OBTG:VARCHAR2--
        --Finish added by P.Sarobe
    v_CashLine_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_ispaid CHAR(1);
    v_Settlement_Cancel_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Line NUMERIC:=0;
    v_Debtpayment_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_DocumentNo VARCHAR(200) ; --OBTG:VARCHAR2--
    v_Date TIMESTAMP;
    v_count NUMERIC;
    v_isSoTrx CHAR(1) ;
    v_Aux NUMERIC;
    v_c_Bpartner_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_c_currency_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_C_PROJECT_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_PriceList_ID VARCHAR(32); --OBTG:VARCHAR2--
 
    v_CBPartner_ID VARCHAR(32); --OBTG:VARCHAR2--
    rowcount NUMERIC;
    v_Compare NUMERIC;
	-- added by Frank Wohlers
	v_parent_order_id character varying;
	v_new_order_id character varying;
	v_bpartner character varying;
	v_cur record;
	v_cur2 record;
	v_cur3 record;
	v_dummy character varying;
	v_bpartner_location_id character varying;
	v_project_name character varying;
	v_billto_id character varying;
        v_nexpinstance character varying;
	v_updatedocno character varying:='';
	v_prjcur record;

BEGIN
    IF p_PInstance_ID IS  NULL and p_order_id is null THEN
        -- Compile
        return;
    end if;
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
        v_User:=Cur_Parameter.AD_User_ID;
      END LOOP; -- Get Parameter
    ELSE
      v_Record_ID:=p_Order_ID;
      SELECT UPDATEDBY INTO v_User  FROM C_ORDER  WHERE C_ORDER_ID=p_Order_ID;
    END IF;
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
  BEGIN --BODY
    /**
    * Read Order
    */
    v_ResultStr:='ReadingOrder';
    SELECT Processing, Processed, DocAction, DocStatus,
      C_DocType_ID, C_DocTypeTarget_ID, AD_Client_ID,
      AD_Org_ID, UpdatedBy, M_Warehouse_ID, TRUNC(DateOrdered),
      Issotrx, c_Bpartner_Id, c_currency_id, C_PROJECT_ID,
      C_BPartner_ID, M_PriceList_ID, invoicerule,issotrx,orderselfjoin
    INTO v_IsProcessing, v_IsProcessed, v_DocAction, v_DocStatus,
      v_DocType_ID, v_DocTypeTarget_ID, v_Client_ID,
      v_Org_ID, v_UpdatedBy, v_M_Warehouse_ID, v_Date,
      v_isSoTrx, v_c_Bpartner_Id, v_c_currency_id, v_C_PROJECT_ID,
      v_CBPartner_ID, v_PriceList_ID, v_invoicerule,v_issotrx,v_orderselfjoin
    FROM C_ORDER
    WHERE C_Order_ID=v_Record_ID  FOR UPDATE;
    -- Get current DocSubTypeSO
    SELECT DocSubTypeSO
    INTO v_DocSubTypeSO
    FROM C_DOCTYPE
    WHERE C_DocType_ID=v_DocType_ID;
        -- Get the name of the org of the Order. Added by P.Sarobe
        SELECT name INTO v_Org_Name FROM AD_ORG WHERE ad_org_id = v_Org_ID;
    RAISE NOTICE '%','DocAction=' || v_DocAction || ', DocStatus=' || v_DocStatus || ', DocType_ID=' || v_DocType_ID || ', DocTypeTarget_ID=' || v_DocTypeTarget_ID || ', DocSubTypeSO=' || v_DocSubTypeSO ;
    
/************************************************
* Checks
*
*
************************************************/
      -- Check Doctype
      SELECT COUNT(*) INTO v_Count
      FROM C_ORDER C, C_DOCTYPE
      WHERE C_DocType.ad_table_id='259'
            AND C_DocType.IsSOTrx=C.ISSOTRX
            AND AD_ISORGINCLUDED(C.AD_Org_ID,C_DocType.AD_Org_ID, C.AD_Client_ID) <> -1
            AND C.C_DOCTYPETARGET_ID = C_DOCTYPE.C_DOCTYPE_ID
            AND C.C_ORDER_ID = v_Record_ID;
      IF v_Count=0 THEN
         RAISE EXCEPTION '%', '@NotCorrectOrgDoctypeOrder@' ; --OBTG:-20000--
      END IF;
    --if order has lines
    IF (v_DocAction = 'CO') THEN
      SELECT COUNT(*)
        INTO v_Aux
       FROM C_ORDERLINE
       WHERE C_ORDER_ID = v_Record_ID;
       IF v_Aux=0 THEN
         RAISE EXCEPTION '%', '@OrderWithoutLines@'; --OBTG:-20000--
       END IF;
    END IF;
    
    /**
    * Order Closed, Voided or Reversed - No action possible
    */
    IF(v_DocStatus IN ('CL', 'VO', 'RE') ) THEN
      RAISE EXCEPTION '%', '@AlreadyPosted@' ; --OBTG:-20000--
    END IF;
    /**
    * Waiting on Prepayment  can only be closed
    */
    IF(v_DocStatus='WP' AND v_DocAction<>'CL') THEN
      RAISE EXCEPTION '%', '@WaitingPayment@' ; --OBTG:-20000--
    END IF;
    SELECT DocSubTypeSO
    INTO v_DocSubTypeSOTarget
    FROM C_DOCTYPE
    WHERE C_DocType_ID=v_DocTypetarget_ID;
    IF (v_DocSubTypeSOTarget='PR' AND v_invoicerule <> 'I') THEN
      RAISE EXCEPTION '%', '@PrepayMustImmediate@'; --OBTG:-20000--
    END IF;
    /**
    * Unlock AND RETURN
    */
    IF(v_DocAction='XL') THEN
      UPDATE C_ORDER
        SET Processing='N',
        DocAction='--',
        Updated=TO_DATE(NOW())
      WHERE C_Order_ID=v_Record_ID;
      IF(p_PInstance_ID IS NOT NULL) THEN
          --  Update AD_PInstance
          RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
          PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
      END IF;
      RETURN;
    END IF;
    IF(v_IsProcessing='Y') THEN
        RAISE EXCEPTION '%', '@OtherProcessActive@' ; --OBTG:-20000--
    END IF;
/*********************************************************************
* Re-activate AND RETURN
*
*
***********************************************************************/
      IF(v_DocAction='RE') THEN
          IF (v_DocSubTypeSO IN ('WR', 'WP')) THEN
            RAISE EXCEPTION '%', '@ActionNotSupported@'; --OBTG:-20000--
          END IF;
          -- SZ Checks: Do not Reopen, If active invoice or Shipment exists
          -- Checks
          select count(*) into v_count from c_invoiceline l,c_invoice i,c_orderline ol
              where l.c_invoice_id=i.c_invoice_id and l.c_orderline_id=ol.c_orderline_id
                    and ol.c_order_id=v_Record_ID
                    and i.docstatus!='VO';
          if v_count>0 and c_getconfigoption('alloworderchangesafterdelivery',v_Org_ID)='N'  then
              RAISE EXCEPTION '%', '@OrderStillhasActiveInvoice@'; 
          end if;
          select count(*) into v_count from m_inoutline l,m_inout m,c_orderline ol
              where l.m_inout_id=m.m_inout_id and l.c_orderline_id=ol.c_orderline_id
                    and ol.c_order_id=v_Record_ID
                    and m.docstatus!='VO';
          if v_count>0  and c_getconfigoption('alloworderchangesafterdelivery',v_Org_ID)='N' then
              RAISE EXCEPTION '%', '@OrderStillhasActiveShipments@'; 
          end if;
          if v_DocType_ID in ('559A80F2E27742D4B2C476045F5C834F','56913A519BA94EB59DAE5BF9A82F5F7D') then
            -- Reactivation on Frame Contracts with active Call Offs is not possible
            select count(*) into v_count from c_orderline ol, c_order o where o.c_order_id=ol.c_order_id and o.docstatus!='VO' and
                            ol.orderlineselfjoin in (select c_orderline_id from c_orderline where c_order_id = v_Record_ID);
            if v_count>0 and c_getconfigoption('alloworderchangesafterdelivery',v_Org_ID)='N' then
                RAISE EXCEPTION '%', '@FramehasActiveCallOffs@'; 
            end if;
          end if;
          -- On Frame Calloffs the Callof QTY must be resetted
          if v_DocType_ID in ('5EED1EFB8BDD4C0491ECCFD7395DA446','9D7785AF1F0D4C51A0B1DF45F5DC9EE5') then
            -- Set the Called QTY
            for v_cur in (select * from c_orderline where c_order_id = v_Record_ID) 
            LOOP
                update c_orderline set calloffqty=coalesce(calloffqty,0) - v_cur.qtyordered,deliverycomplete='N' where c_orderline_id=v_cur.orderlineselfjoin;
            END LOOP;
          end if;
          --Verify not managed debtPayments added by ALO
                  --Added by P.Sarobe. New messages
          SELECT max(c_debt_payment_id), COUNT(*)
          INTO v_Debtpayment_ID, v_Aux
          FROM C_DEBT_PAYMENT
          WHERE C_Order_ID=v_Record_ID
            AND C_Debt_Payment_Status(C_Settlement_Cancel_ID, Cancel_Processed, Generate_Processed, IsPaid, IsValid, C_CashLine_ID, C_BankStatementLine_ID)!='P';
          IF v_Aux!=0 THEN
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
                          RAISE EXCEPTION '%', '@ManagedDebtPaymentOrderBank@'||v_nameBankstatement||' '||'@Bydate@'||v_dateBankstatement ; --OBTG:-20000--
                            END IF;
                            IF v_CashLine_ID IS NOT NULL THEN
                                  SELECT C_CASH.NAME, C_CASH.STATEMENTDATE
                                  INTO v_nameCash, v_dateCash
                                  FROM C_CASH, C_CASHLINE
                                  WHERE C_CASH.C_CASH_ID = C_CASHLINE.C_CASH_ID
                                  AND C_CASHLINE.C_CASHLINE_ID = v_CashLine_ID;
                          RAISE EXCEPTION '%', '@ManagedDebtPaymentOrderCash@'||v_nameCash||' '||'@Bydate@'||v_dateCash ; --OBTG:-20000--
                            END IF;
                            IF v_Cancel_Processed='Y' AND v_ispaid='N' THEN
                                  SELECT documentno, datetrx
                                  INTO v_documentno_Settlement, v_dateSettlement
                                  FROM C_SETTLEMENT
                                  WHERE C_SETTLEMENT_ID = v_Settlement_Cancel_ID;
                                  RAISE EXCEPTION '%', '@ManagedDebtPaymentOrderCancel@'||v_documentno_Settlement||' '||'@Bydate@'||v_dateSettlement ; --OBTG:-20000--
                            END IF;
          END IF; --v_Aux
          RAISE NOTICE '%','Re-Activating ' || v_DocSubTypeSO || ': ' || v_Record_ID ;
          
          -- Update Order
          v_ResultStr:='ReActivate';
          
          -- SZ: UnDO RESERVATIONS
          PERFORM core_voidOrderReservations(v_Record_ID);
		/*******************************************************************************
		* Reactivate Subscription Suborders
		* Frank Wohlers
		********************************************************************************/
		if v_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then
			perform c_postsuborders(v_record_id, (select docstatus from c_order where c_order_id = v_record_id));
		end if;
          /**
          *   * Re-activate
          */
          UPDATE C_ORDER
              SET DocStatus='DR', -- Draft
              DocAction='CO',
              Processing='N',
              Processed='N',
              generatetemplate='N',
              Updated=TO_DATE(NOW())
            WHERE C_Order_ID=v_Record_ID;
          -- Reverse Direct Shipment 
          UPDATE C_ORDERLINE
              SET QtyDelivered=0
            WHERE DirectShip='Y'
              AND C_Order_ID=v_Record_ID;
          --  Reverse Direct Shipment on DropShip-Lines
          if v_DocType_ID='EE19ABBDB5A94C519DAB11003320FC8E' then
            UPDATE C_ORDERLINE
              SET QtyDelivered=0,DirectShip='N' where c_order_id=v_orderselfjoin and 
                m_product_id in (select m_product_id from c_orderline where c_order_id=v_Record_ID);
            UPDATE c_order set createdropshiporder='N',updatedby=v_UpdatedBy,updated=now() where c_order_id=v_orderselfjoin;
            UPDATE C_ORDERLINE
              SET QtyDelivered=0,DirectShip='N' where c_order_id=v_Record_ID;
          end if;
          --
          select  v_message||c_order_post_userexit(v_Record_ID) into v_message;
          IF(p_PInstance_ID IS NOT NULL) THEN
              --  Update AD_PInstance
              RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
              PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
          END IF;
          -- Schedule Update Project Status Process
          for v_prjcur in (select c_project_id from c_orderline where c_order_id=v_Record_ID and c_project_id is not null)
          LOOP
              perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
          END LOOP;
          RETURN;
      END IF; -- RE Reactivate END
    
/*********************************************************************
* Voiding AND RETURN
*
*
***********************************************************************/
      IF(v_DocAction='VO') THEN
        -- On Frame Calloffs the Callof QTY must be resetted
        if v_DocStatus='CO' and v_DocType_ID in ('5EED1EFB8BDD4C0491ECCFD7395DA446','9D7785AF1F0D4C51A0B1DF45F5DC9EE5') then
            -- Set the Called QTY
            for v_cur in (select * from c_orderline where c_order_id = v_Record_ID) 
            LOOP
                update c_orderline set calloffqty=coalesce(calloffqty,0) - (v_cur.qtyordered-v_cur.qtydelivered),deliverycomplete='N' where c_orderline_id=v_cur.orderlineselfjoin;
            END LOOP;
        end if;
        -- If PO has lines with project, recharge for PO and recharge-workflow is activated
        select count(*) into v_count from c_orderline where c_orderline.c_order_id=v_Record_ID and c_orderline.c_project_id is not null;
        if 	v_DocType_ID in ('B342FD5CA1C64E8BA25A0A6F6C98C7DA') and 
            (c_getconfigoption('reinvoiceprojectexpenses',v_org_id))='Y' and 
            v_count !=0
        then
            -- Create Order (recharge cost) header
            for v_cur in (select distinct c_order.c_order_id, c_order.ad_client_id, c_order.ad_org_id, c_order.createdby, c_order.updatedby,
                        c_order.documentno, c_order.docstatus, c_order.docaction,
                        c_order.c_doctype_id, c_order.c_doctypetarget_id, c_order.description, c_order.salesrep_id,
                        c_order.dateordered, c_order.dateacct, c_project.c_bpartner_id, c_order.c_bpartner_location_id,
                        c_order.c_currency_id, c_bpartner.paymentrule, c_bpartner.c_paymentterm_id, c_bpartner.invoicerule,
                        c_bpartner.deliveryrule, c_order.freightcostrule, c_bpartner.deliveryviarule, c_order.priorityrule,
                        c_order.m_warehouse_id, c_bpartner.m_pricelist_id, c_orderline.c_project_id, c_order.deliverynotes,
                        c_order.c_projecttask_id, c_order.name, c_order.orderselfjoin, c_order.isrecharge
                        from c_order, c_orderline
                        left join c_project on c_orderline.c_project_id=c_project.c_project_id
                        left join c_bpartner on c_project.c_bpartner_id=c_bpartner.c_bpartner_id
                        where 
                            c_order.c_order_id=v_Record_ID and 
                            c_orderline.c_order_id=c_order.c_order_id and 
                            c_orderline.c_project_id is not null)
            loop	
                if ((select count(*) from c_order where 
                    c_order.orderselfjoin=v_cur.c_order_id and 
                    c_order.c_project_id=v_cur.c_project_id and
                    c_order.c_doctype_id='1052C4B77714415C8CF89DEB7B4349A3' and
                    (c_order.docstatus='DR' or c_order.docstatus='CO')) > 0) then
                    for v_cur2 in (select c_order_id, documentno from c_order where 
                        c_order.orderselfjoin=v_cur.c_order_id and
                        c_order.c_project_id=v_cur.c_project_id and
                        c_order.c_doctype_id='1052C4B77714415C8CF89DEB7B4349A3' and
                    (c_order.docstatus='DR' or c_order.docstatus='CO'))
                    loop
                        v_Message:= v_Message || 'Weiterberechnungsauftrag ' || zsse_htmldirectlink('../SalesOrder/Header_Relation.html','document.frmMain.inpcOrderId', v_cur2.c_order_id, v_cur2.documentno) || ' existiert noch und kann nur manuell storniert werden.</br>';		
                    end loop;
                end if;
            end loop;
        end if;
        /*******************************************************************************
        * Delete/Void Subscription Suborders
        * Frank Wohlers
        ********************************************************************************/
        if v_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then
            perform c_postsuborders(v_record_id, (select docstatus from c_order where c_order_id = v_record_id));
            perform c_deletesuborders(v_record_id);
            perform c_postsuborderswithaction (v_record_id, 'VO');
        end if;
        -- VOID MAIN ORDER
        PERFORM core_voidOrder(v_Record_ID);
        select  v_message||c_order_post_userexit(v_Record_ID) into v_message;
        IF(p_PInstance_ID IS NOT NULL) THEN
              --  Update AD_PInstance
              RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
              PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
        END IF;
        -- Schedule Update Project Status Process
        for v_prjcur in (select c_project_id from c_orderline where c_order_id=v_Record_ID and c_project_id is not null)
        LOOP
            perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
        END LOOP;
        -- Remove assigned Requisition Lines
        for v_prjcur in (select ro.m_requisitionline_id from m_requisitionorder ro, c_orderline ol where ol.qtydelivered=0 and ol.c_orderline_id=ro.c_orderline_id and ol.c_order_id=v_Record_ID)
        LOOP
            delete from m_requisitionorder where m_requisitionline_id=v_prjcur.m_requisitionline_id;
            update m_requisition set docstatus='CO' where m_requisition_id=(select m_requisition_id from m_requisitionline where m_requisitionline_id=v_prjcur.m_requisitionline_id);
            update m_requisitionline set reqstatus='O',lockedby=null,lockqty=null,lockprice=null,lockdate=null,lockcause=null,rejected='N' where m_requisitionline_id=v_prjcur.m_requisitionline_id;
        END LOOP;
        RETURN;
      END IF; -- Voiding

-- Set org lines like the headear (AProve, COmplete, PRocess,CLOSE)
      UPDATE C_ORDERLINE
        SET AD_ORG_ID = (SELECT AD_ORG_ID FROM C_ORDER WHERE C_ORDER_ID = v_Record_ID)
      WHERE C_ORDER_ID = v_Record_ID;
/*********************************************************************
* Closing
*
* AND RETURN
***********************************************************************/
      IF(v_DocAction='CL') THEN
        Update c_order set processed='N' WHERE C_Order_ID=v_Record_ID;
        -- Cancel undelivered Items
        IF(v_isSoTrx='Y') THEN --Sales orders
          select sum(qtydelivered)-sum(qtyinvoiced) into v_Compare from C_ORDERLINE WHERE C_Order_ID=v_Record_ID;
          if v_Compare!=0 then
             raise exception '%','@OrderCloseOnlyWhennDeliveredEQInvoiced@';
          end if;
        END IF;
        -- Delete Reservations
        PERFORM core_voidOrderReservations(v_Record_ID);
		/*******************************************************************************
		* Delete/Close Subscription Suborders
		* Frank Wohlers
		********************************************************************************/
		if v_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then
			perform c_postsuborders(v_record_id, (select docstatus from c_order where c_order_id = v_record_id));
			perform c_deletesuborders(v_record_id);
			perform c_postsuborderswithaction (v_record_id, 'CL');
		end if;
        UPDATE C_ORDER
          SET DocStatus='CL',
          DocAction='--',Processing='N',
          Processed='Y',proposalstatus='CL',
          Updated=TO_DATE(NOW())
        WHERE C_Order_ID=v_Record_ID;
        IF(p_PInstance_ID IS NOT NULL) THEN
              --  Update AD_PInstance
              RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
              PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
        END IF;
        -- Schedule Update Project Status Process
        for v_prjcur in (select c_project_id from c_orderline where c_order_id=v_Record_ID and c_project_id is not null)
        LOOP
            perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
        END LOOP;
        RETURN;  
      END IF; -- v_DocAction='CL'
     /**************************************************************************************************+
      * Allowed Actions:  AProve, COmplete, PRocess
      *                   Approve not Implemented
      *
      *
      */
/**************************************************************************
Further Checks on AProve, COmplete, PRocess

*************************************************************************/
        IF NOT (v_DocAction IN('AP', 'CO', 'PR')) THEN
          RAISE EXCEPTION '%', '@ActionNotAllowedHere@' ; --OBTG:-20000--
        END IF;
        -- Check the header belongs to a organization where transactions are posible and ready to use
        SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
        INTO v_is_ready, v_is_tr_allow
        FROM C_ORDER, AD_Org, AD_OrgType
        WHERE AD_Org.AD_Org_ID=C_ORDER.AD_Org_ID
        AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
        AND C_ORDER.C_ORDER_ID=v_Record_ID;
        IF c_getconfigoption('isprojecttaskmandatory',v_Org_ID)='Y' and ad_get_docbasetype(v_DocTypeTarget_ID) in ('SOO','POO') then
           IF (select count(*) from c_orderline where c_order_id=v_Record_ID and c_project_id is not null and c_projecttask_id is null)>0 then
            Raise EXCEPTION '%', '@ProjecttaskisMandatory@';
           END IF;
        end if;
        IF (v_is_ready='N') THEN
          RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
        END IF;
        IF (v_is_tr_allow='N') THEN
          RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
        END IF;
        
        SELECT AD_ORG_CHK_DOCUMENTS('C_ORDER', 'C_ORDERLINE', v_Record_ID, 'C_ORDER_ID', 'C_ORDER_ID') INTO v_is_included FROM dual;
        IF (v_is_included=-1) THEN
          RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
        END IF;

        SELECT COUNT(*), MAX(M.line)
        INTO v_Count, v_line
        FROM c_orderline M,
          M_Product P,M_ATTRIBUTESET a
        WHERE M.M_PRODUCT_ID=P.M_PRODUCT_ID AND P.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id and a.ismandatory='Y'
          AND COALESCE(M.M_ATTRIBUTESETINSTANCE_ID, '0') = '0'
          AND ad_get_docbasetype(v_DocTypeTarget_ID) not in ('NON','POREQUESTOFFER','SALESOFFER')
        AND M.c_order_ID=v_Record_ID;
        IF v_Count<>0 THEN
            RAISE EXCEPTION '%', '@Inline@ '||v_line||' '||'@productWithoutAttributeSet@' ; --OBTG:-20000--
        END IF;
    
        v_ResultStr:='CheckingRestrictions - C_ORDER ORG IS IN C_BPARTNER ORG TREE';
        SELECT COUNT(*) INTO v_count FROM C_ORDER c, C_BPARTNER bp
            WHERE c.C_Order_ID=v_Record_ID
            AND c.C_BPARTNER_ID=bp.C_BPARTNER_ID
            AND Ad_Isorgincluded(c.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1;
        IF v_count>0 THEN
            RAISE EXCEPTION '%', '@NotCorrectOrgBpartnerOrder@' ; --OBTG:-20000--
        END IF;
        
        IF(p_PInstance_ID IS NOT NULL) THEN
          v_ResultStr:='LockingOrder';
          UPDATE C_ORDER  SET Processing='Y'  WHERE C_Order_ID=v_Record_ID;
          -- COMMIT;
        END IF;
        -- Now, needs to go to END_PROCESSING to unlock   
/*******************************************************************************
* Convert to Target DocType
* 
********************************************************************************/
        v_ResultStr:='UpdateDocType';
        UPDATE C_ORDER
          SET C_DocType_ID=v_DocTypeTarget_ID
        WHERE C_Order_ID=v_Record_ID;
        v_DocType_ID:=v_DocTypeTarget_ID;
        select DocSubTypeSO into v_DocSubTypeSO from C_DocType where C_DocType_ID=v_DocType_ID;
/*******************************************************************************
* Setting In Process or Approve
* AND RETURN
********************************************************************************/
        IF(v_DocAction in ('PR','AP')) THEN
            v_ResultStr:='FinishProcessing';
            UPDATE C_ORDER
              SET DocStatus=case v_DocAction when 'PR' then 'IP' else 'AP' end,
              DocAction='CO',
              Processed='N',
              Processing='N',
              Updated=TO_DATE(NOW())
            WHERE C_Order_ID=v_Record_ID;
            -- C_Order_PickList(NULL, v_Record_ID);  -- Print PickList
             IF(p_PInstance_ID IS NOT NULL) THEN
                  --  Update AD_PInstance
                  RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
                  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
             END IF;
             -- Schedule Update Project Status Process
             for v_prjcur in (select c_project_id from c_orderline where c_order_id=v_Record_ID and c_project_id is not null)
             LOOP
                 perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
             END LOOP;
             RETURN;
        END IF;
        -- On Frame Contracts The Dates must be set correctly
        if v_DocType_ID in ('559A80F2E27742D4B2C476045F5C834F','56913A519BA94EB59DAE5BF9A82F5F7D') then
          select count(*) into v_count from c_order where c_order_id=v_Record_ID and (contractdate is  null or enddate is  null or 
                          coalesce(contractdate,now()) > coalesce(enddate,now()));
          if v_count>0 then
              RAISE EXCEPTION '%', '@FrameContractneedsDate@'; 
          end if;
        end if;
        -- On Frame Call-Offs The contract must be set correctly.
        if v_DocType_ID in ('9D7785AF1F0D4C51A0B1DF45F5DC9EE5','5EED1EFB8BDD4C0491ECCFD7395DA446') then
          for v_cur in (select orderlineselfjoin,qtyordered,m_product_id,line from c_orderline where c_order_id=v_Record_ID)
          LOOP
            if v_cur.orderlineselfjoin is null then
               RAISE EXCEPTION '%', '@FrameCallOffsMustHaveContract@'; 
            end if;
            for v_cur2 in (select coalesce(ol.calloffqty,0) as calloff ,ol.qtyordered,o.contractdate,o.enddate ,ol.m_product_id
                from c_order o,c_orderline ol where ol.c_order_id=o.c_order_id and ol.c_orderline_id=v_cur.orderlineselfjoin)
            LOOP
                if coalesce(v_cur2.contractdate,trunc(now()))>v_Date or coalesce(v_cur2.enddate,trunc(now()))<v_Date then
                    RAISE EXCEPTION '%', '@FrameContractneedsDate@';  
                end if;
                if v_cur2.qtyordered-v_cur2.calloff<v_cur.qtyordered then
                    RAISE EXCEPTION '%', '@FrameCallOffOutOfRange@';  
                end if;
                if v_cur.m_product_id!=v_cur2.m_product_id then 
                    RAISE EXCEPTION '%', '@FrameCallOffProductDiffer@'||v_cur.line;  
                end if;
            END LOOP;
          END LOOP;
          -- Set the Called QTY
          for v_cur in (select * from c_orderline where c_order_id = v_Record_ID) 
          LOOP
            update c_orderline set calloffqty=coalesce(calloffqty,0) + v_cur.qtyordered where c_orderline_id=v_cur.orderlineselfjoin;
            if (select qtyordered-coalesce(calloffqty,0) from c_orderline where c_orderline_id=v_cur.orderlineselfjoin)=0 then
                update c_orderline set deliverycomplete='Y' where c_orderline_id=v_cur.orderlineselfjoin;
            end if;
          END LOOP;
        end if;
/**************************************************************************
 * SZ: Reserve Inventory only on Completing (CO) 
  No Reservations,Invoice Creating , Shipments on specific Doctypes
 FROM HERE DocAction is Closing (CO) all other have finish processed
*************************************************************************/
                           -- Proposal, Request for Quotation, Quotation, Subscription Order, Subscription Proposal
    If ad_get_docbasetype(v_DocType_ID) not in ('NON','POREQUESTOFFER','SALESOFFER') then
            DECLARE
              Cur_ResLine RECORD;
              v_QtySO       NUMERIC; -- Reserved
              v_QtyPO       NUMERIC; -- Ordered
            BEGIN
              v_ResultStr := 'ReserveInventory';
              -- For all lines needing reservation
              FOR Cur_ResLine IN (SELECT o.M_Warehouse_ID, l.M_Product_ID, l.M_AttributeSetInstance_ID, l.C_OrderLine_ID,
                    -- Target Level = 0 if DirectShip='Y' 
                    (CASE  WHEN l.DirectShip='Y' or l.deliverycomplete='Y' THEN 0 ELSE l.QtyOrdered END)
                    -l.QtyReserved-l.QtyDelivered AS Qty, 
                    l.QtyReserved, l.QtyDelivered, l.DatePromised, l.C_UOM_ID
                  FROM C_ORDERLINE l, M_PRODUCT p, c_order o
                  WHERE l.C_Order_ID=v_Record_ID and o.c_order_id=l.c_order_id
                    -- Reserve Products (not: services, null products) --
                    AND l.M_Product_ID=p.M_Product_ID
                    AND p.IsStocked='Y' AND p.ProductType='I'
                    -- Target Level = 0 if DirectShip='Y' 
                    AND (CASE  WHEN l.DirectShip='Y' or l.deliverycomplete='Y' THEN 0 ELSE l.QtyOrdered END)
                    -l.QtyReserved-l.QtyDelivered <> 0
                  FOR UPDATE) LOOP
              -- Qty corrected for SO/PO
              IF (v_DocSubTypeSO IS NOT NULL) THEN
                v_QtySO   := Cur_ResLine.Qty;
                v_QtyPO   := 0;
              ELSE -- PO
                v_QtySO := 0;
                v_QtyPO := Cur_ResLine.Qty;
              END IF;
              if v_DocType_ID!='EE19ABBDB5A94C519DAB11003320FC8E' then -- Drop Ship Order
                --PERFORM M_UPDATE_STORAGE_PENDING(v_Client_ID, v_Org_ID, v_UpdatedBy, Cur_ResLine.M_Product_ID, Cur_ResLine.M_Warehouse_ID, Cur_ResLine.M_AttributeSetInstance_ID,
                --      Cur_ResLine.C_UOM_ID, null, v_QtySO, null, v_QtyPO, null);
              end if;
              RAISE NOTICE '%','Reserved Warehouse=' || Cur_ResLine.M_Warehouse_ID || ', Product=' || Cur_ResLine.M_Product_ID || ', Attrib=' || Cur_ResLine.M_AttributeSetInstance_ID || ', Qty=' || v_QtySO || '/' || v_QtyPO;

              -- Update Order Line
              IF (v_DocSubTypeSO IS NOT NULL) THEN
                  UPDATE C_ORDERLINE
                  SET QtyReserved = QtyReserved + v_QtySO
                WHERE C_OrderLine_ID = Cur_ResLine.C_OrderLine_ID;
              END IF;
              GET DIAGNOSTICS  rowcount:=ROW_COUNT;
              IF (rowcount <> 1) THEN
                  IF (p_PInstance_ID IS NOT NULL) THEN
                      v_ResultStr := 'LockingOrder';
                      UPDATE C_ORDER
                        SET Processing = 'N'
                      WHERE C_Order_ID = v_Record_ID;
                      RAISE EXCEPTION '%','DATA_EXCEPTION';
                  END IF;
                  RAISE EXCEPTION '%', 'Did not update Line'; --OBTG:-20011--
              END IF;
              END LOOP; -- For all lines needing reservation
            END; -- Reserve Inventory
 
            /**
            * Deliver Direct Shipments
            */
            v_ResultStr:='NonInventoryDelivery';
            UPDATE C_ORDERLINE
              SET QtyDelivered=QtyOrdered
            WHERE DirectShip='Y'
              AND C_Order_ID=v_Record_ID;
            --  Deliver Direct Shipment on DropShip-Lines
            if v_DocType_ID='EE19ABBDB5A94C519DAB11003320FC8E' then
                UPDATE C_ORDERLINE
                SET QtyDelivered=QtyOrdered,DirectShip='Y' where c_order_id=v_orderselfjoin and 
                m_product_id in (select m_product_id from c_orderline where c_order_id=v_Record_ID);
                UPDATE c_order set createdropshiporder='Y',updatedby=v_UpdatedBy,updated=now() where c_order_id=v_orderselfjoin;
                UPDATE C_ORDERLINE
                SET QtyDelivered=QtyOrdered,DirectShip='Y' where c_order_id=v_Record_ID;
            end if;
            -- Order not invoicable - Doctype triggers - Always completely invoiced
            if v_DocType_ID='B28FD44351C7433EAEA24D55CF8AFFA1' then
                UPDATE C_ORDERLINE set ignoreresidue = 'Y' where c_order_id=v_Record_ID;
            end if;    
           
            /**************************************************************************
            * Will-Call + Walk In Processing (POS-Order)
            * --
            * (W)illCall(I)nvoice - (W)illCall(P)ickup - (W)alkIn(R)eceipt
            * On Credit Order       Warehouse Order      POS-Order
            * --
            *************************************************************************/
            IF(v_DocSubTypeSO IN('WP', 'WR')) THEN
                  /************
                  * Shipment
                  */
                  RAISE NOTICE '%','Create Shipment - ' || v_Record_ID ;
                  v_ResultStr:='CreateShipment';
                  -- Close Order before, otherwise Creation will fail
                  UPDATE C_ORDER
                    SET DocStatus='CO',
                    DocAction='RE',
                    Processed='Y',
                    Processing='Y',
                    Updated=TO_DATE(NOW())
                  WHERE C_Order_ID=v_Record_ID;
                  -- Generate all lines
                  select get_uuid() into v_nexpinstance;
                    insert into c_generateminoutmanual(C_GENERATEMINOUTMANUAL_ID, C_ORDERLINE_ID, C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, QTY, M_LOCATOR_ID,pinstance_id,MovementDate,m_product_id)
                         select get_uuid(),ol.C_ORDERLINE_ID, ol.C_ORDER_ID, ol.AD_CLIENT_ID, ol.AD_ORG_ID, ol.CREATEDBY, ol.UPDATEDBY, ol.qtyordered, 
                                m_gettransactionlocator(ol.m_product_id,o.m_warehouse_id,case when o.c_doctypetarget_id='F2080E63E5F04B4D8B30D8016B0983BB' then 'N' else o.issotrx end,ol.qtyordered),
                                v_nexpinstance,o.dateordered,ol.m_product_id
                         from c_order o,c_orderline ol,m_product p where ol.c_order_id=o.c_order_id and p.m_product_id=ol.m_product_id
                              and case when  c_getconfigoption('deliveryofservices',o.ad_org_id) = 'N' then  p.producttype!='S' else 1=1 end                                          
                              and o.C_Order_ID=v_Record_ID;
                  -- Create Shipment
                  SELECT * INTO  InOut_ID FROM M_Inout_Create(v_nexpinstance, NULL, NULL, 'Y') ; -- Force Delivery

                  RAISE NOTICE '%','  Shipment - ' || InOut_ID ;
                  IF(InOut_ID is null or InOut_ID='0') THEN
                    RAISE EXCEPTION '%', '@InOutCreateFailed@ - '||(select replace(errormsg,'@ERROR=','') from ad_pinstance where ad_pinstance_id=v_nexpinstance); 
                      ELSE
                      SELECT documentno
                      INTO v_DocumentNo
                      FROM M_INOUT
                      WHERE M_INOUT_ID = InOut_ID;
                      v_Message:='@InoutDocumentno@ ' || v_DocumentNo || ' @beenCreated@';
                  END IF;
            END IF; --v_DocSubTypeSO    
            IF(v_DocSubTypeSO IN('WI', 'WR')) THEN
                    /************
                    * Invoice
                    */
                    RAISE NOTICE '%','Create Invoice - ' || v_Record_ID ;
                    select get_uuid() into v_nexpinstance;
                    v_ResultStr:='CreateInvoice';
                    insert into C_GENERATEINVOICEMANUAL (C_GENERATEINVOICEMANUAL_ID, C_ORDERLINE_ID, C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, QTY, PRICE, DESCRIPTION,LINEAMT,pinstance_id,dateinvoiced)
                           select get_uuid(),ol.C_ORDERLINE_ID, ol.C_ORDER_ID, ol.AD_CLIENT_ID, ol.AD_ORG_ID, ol.CREATEDBY, ol.UPDATEDBY, ol.qtyordered, ol.priceactual, ol.DESCRIPTION,ol.linenetamt,v_nexpinstance,o.dateordered
                           from c_order o,c_orderline ol where ol.c_order_id=o.c_order_id and ol.C_Order_ID=v_Record_ID;

                    SELECT * INTO  Invoice_ID FROM C_Invoice_Create(v_nexpinstance, NULL) ;
                    RAISE NOTICE '%','  Invoice - ' || Invoice_ID ;
                    IF(Invoice_ID IS NULL OR Invoice_ID='0') THEN
                      RAISE EXCEPTION '%', '@InvoiceCreateFailed@ - '||(select replace(errormsg,'@ERROR=','') from ad_pinstance where ad_pinstance_id=v_nexpinstance); --OBTG:-20000--
                            ELSE
                            SELECT documentno
                        INTO v_DocumentNo
                        FROM C_INVOICE
                        WHERE C_INVOICE_ID = Invoice_ID;
                        v_Message:=v_Message||' , '||'@InvoiceDocumentno@ ' || v_DocumentNo || ' @invbeenCreated@';
                    END IF;
            END IF;--v_DocSubTypeSO    
        --  Correction for POS-RETURN ORDERs
            if v_DocType_ID='F2080E63E5F04B4D8B30D8016B0983BB' then
                UPDATE C_ORDERLINE
                SET QtyDelivered=QtyOrdered,qtyinvoiced=QtyOrdered,qtyreserved=0,ignoreresidue='Y',deliverycomplete='Y' where c_order_id=v_Record_ID; 
            end if;    
        /**
        * Final Completeness check
        */
        SELECT SUM(QtyOrdered*hex_to_int(C_OrderLine_ID)) -SUM(QtyDelivered*hex_to_int(C_OrderLine_ID)),
          SUM(QtyOrdered*hex_to_int(C_OrderLine_ID)) -SUM(QtyInvoiced*hex_to_int(C_OrderLine_ID))
        INTO ToDeliver,
          ToInvoice
        FROM C_ORDERLINE
        WHERE C_Order_ID=v_Record_ID;
        RAISE NOTICE '%','To deliver - ' || ToDeliver ;
        RAISE NOTICE '%','ToInvoice - ' || ToInvoice ;
        RAISE NOTICE '%','v_DocSubTypeSO - ' || v_DocSubTypeSO ;
        -- Close The Ord
        UPDATE C_ORDER
          SET DocStatus='CO',
          DocAction='RE',
          IsDelivered= case v_DocSubTypeSO when 'WI' then 'Y' when 'WR' then 'Y' else 'N' end,   --  SZ: isdelivered  is deprecated!! All positions eres set automatically to delivered deliverycomplete='Y' is set by trigger.
          IsInvoiced= case v_DocSubTypeSO when 'WI' then 'Y' when  'WR' then 'Y' when 'WP' then 'Y' else 'N' end,
          Processed='Y',
          Processing='N',
          Updated=TO_DATE(NOW())
        WHERE C_Order_ID=v_Record_ID;
        RAISE NOTICE '%','DocAction - ' || v_DocAction ;       
    ELSE -- Close Doctypes Proposal, Quotation ...
		/*******************************************************************************
		* Generate Subscription Suborders
		* Frank Wohlers
		********************************************************************************/
		if v_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then
			perform c_deletesuborders(v_record_id);
			perform c_generatesubscriptionsuborders(v_record_id, (select subscriptionchangedate::date from c_order where c_order_id = v_record_id));
			perform c_postsuborders(v_record_id, (select docstatus from c_order where c_order_id = v_record_id));
		end if;
		
         UPDATE C_ORDER
          SET DocStatus='CO',
          DocAction='RE',
          Processed='Y',
          Processing='N',
          Updated=TO_DATE(NOW())
        WHERE C_Order_ID=v_Record_ID;
    END IF; --V_DOCTYPE_ID 

	
/*******************************************************************************
* Generate Order (recharge cost)
* Frank Wohlers
********************************************************************************/	
	-- If PO has lines with project, recharge for PO and recharge-workflow is activated
	select count(*) into v_count from c_orderline where c_orderline.c_order_id=v_Record_ID and c_orderline.c_project_id is not null;
	if 	v_DocType_ID in ('B342FD5CA1C64E8BA25A0A6F6C98C7DA') and 
		(c_getconfigoption('reinvoiceprojectexpenses',v_org_id))='Y' and 
		v_count !=0 and
		(select isrecharge from c_order where c_order.c_order_id=v_Record_ID)='Y'
	then
		-- Create Order (recharge cost) header
		for v_cur in (select distinct c_order.c_order_id, c_order.ad_client_id, c_order.ad_org_id, c_order.createdby, c_order.updatedby,
						c_order.documentno, c_order.docstatus, c_order.docaction,
						c_order.c_doctype_id, c_order.c_doctypetarget_id, c_order.description, c_order.salesrep_id,
						c_order.dateordered, c_order.dateacct, c_project.c_bpartner_id, c_order.c_bpartner_location_id,
						c_order.c_currency_id, c_bpartner.paymentrule, c_bpartner.c_paymentterm_id, c_bpartner.invoicerule,
						c_bpartner.deliveryrule, c_order.freightcostrule, c_bpartner.deliveryviarule, c_order.priorityrule,
						c_order.m_warehouse_id, c_bpartner.m_pricelist_id, c_orderline.c_project_id, c_order.deliverynotes,
						c_order.c_projecttask_id, c_order.name, c_order.orderselfjoin, c_order.isrecharge,c_order.internalnote
						from c_order, c_orderline
						left join c_project on c_orderline.c_project_id=c_project.c_project_id
						left join c_bpartner on c_project.c_bpartner_id=c_bpartner.c_bpartner_id
						where 
							c_order.c_order_id=v_Record_ID and 
							c_orderline.c_order_id=c_order.c_order_id and 
							c_orderline.c_project_id is not null)
		loop	
			if v_cur.c_bpartner_id is null and v_cur.isrecharge='Y' then
				v_project_name:= (select value from c_project where c_project.c_project_id=v_cur.c_project_id) || ' - ' || (select name from c_project where c_project.c_project_id=v_cur.c_project_id);
				v_Message:= v_Message || 'Für Projekt ' || zsse_htmldirectlink('../org.openbravo.zsoft.project.Projects/ProjectHeader157_Relation.html','document.frmMain.inpcProjectId', v_cur.c_project_id, v_project_name) || ' muss für Weiterberechnungen ein Geschäftspartner angegeben werden.</br>';
			elsif ((select count(*) from c_order where 
				c_order.orderselfjoin=v_cur.c_order_id and 
				c_order.c_project_id=v_cur.c_project_id and
				c_order.c_doctype_id='1052C4B77714415C8CF89DEB7B4349A3' and
				(c_order.docstatus='DR' or c_order.docstatus='CO') and 
				v_cur.isrecharge='Y') > 0) then
				for v_cur2 in (select c_order_id, documentno from c_order where 
					c_order.orderselfjoin=v_cur.c_order_id and
					c_order.c_project_id=v_cur.c_project_id and
					c_order.c_doctype_id='1052C4B77714415C8CF89DEB7B4349A3' and
				(c_order.docstatus='DR' or c_order.docstatus='CO'))
				loop
					v_Message:= v_Message || 'Weiterberechnungsauftrag ' || zsse_htmldirectlink('../SalesOrder/Header_Relation.html','document.frmMain.inpcOrderId', v_cur2.c_order_id, v_cur2.documentno) || ' existiert bereits und kann nur manuell geändert werden.</br>';		
				end loop;
			elsif ((select count(*) from c_order where 
				c_order.orderselfjoin=v_cur.c_order_id and 
				c_order.c_project_id=v_cur.c_project_id and
				c_order.c_doctype_id='1052C4B77714415C8CF89DEB7B4349A3' and
				(c_order.docstatus='DR' or c_order.docstatus='CO') and 
				v_cur.isrecharge='N') > 0) then
				for v_cur2 in (select c_order_id, documentno from c_order where 
					c_order.orderselfjoin=v_cur.c_order_id and
					c_order.c_project_id=v_cur.c_project_id and
					c_order.c_doctype_id='1052C4B77714415C8CF89DEB7B4349A3' and
				(c_order.docstatus='DR' or c_order.docstatus='CO'))
				loop
					v_Message:= v_Message || 'Weiterberechnungsauftrag ' || zsse_htmldirectlink('../SalesOrder/Header_Relation.html','document.frmMain.inpcOrderId', v_cur2.c_order_id, v_cur2.documentno) || ' existiert noch und kann nur manuell storniert werden.</br>';		
				end loop;
			else 
				select (case v_updatedocno when '' then get_uuid() else v_updatedocno end) into v_new_order_id;
				-- Parent order reference
				select orderselfjoin into v_parent_order_id from c_order where c_order_id=v_Record_ID;
				if v_parent_order_id is null then
					v_parent_order_id:=v_Record_ID;
				end if;
				--  Get next document no.
				select * into  v_documentno from ad_sequence_doc('Order (recharged costs)', v_cur.ad_org_id, 'Y') ;
				select c_bpartner_location_id into v_bpartner_location_id from c_bpartner_location where c_bpartner_location.c_bpartner_id=v_cur.c_bpartner_id and c_bpartner_location.isheadquarter='Y';
				select c_bpartner_location_id into v_billto_id from c_bpartner_location where c_bpartner_location.c_bpartner_id=v_cur.c_bpartner_id and c_bpartner_location.isbillto='Y';
				if v_billto_id is null then
					v_billto_id:=v_bpartner_location_id;
				end if;
				INSERT INTO C_Order
				(c_order_id, ad_client_id, ad_org_id, createdby, updatedby,
				documentno, docstatus, docaction,
				c_doctype_id, c_doctypetarget_id, description, salesrep_id,
				dateordered, dateacct, c_bpartner_id, c_bpartner_location_id, billto_id,
				c_currency_id, paymentrule, c_paymentterm_id, invoicerule,
				deliveryrule, freightcostrule, deliveryviarule, priorityrule,
				m_warehouse_id, m_pricelist_id, c_project_id, deliverynotes,
				c_projecttask_id, name, orderselfjoin,internalnote)
				VALUES
				(v_new_order_id, v_cur.ad_client_id, v_cur.ad_org_id, v_user, v_user,
				v_documentno, 'DR', 'CO',
				'1052C4B77714415C8CF89DEB7B4349A3', '1052C4B77714415C8CF89DEB7B4349A3', v_cur.description, v_cur.salesrep_id,
				to_date(now()), to_date(now()), v_cur.c_bpartner_id, v_bpartner_location_id, v_billto_id,
				v_cur.c_currency_id, v_cur.paymentrule, v_cur.c_paymentterm_id, v_cur.invoicerule, 
				v_cur.deliveryrule, v_cur.freightcostrule, v_cur.deliveryviarule, v_cur.priorityrule,
				v_cur.m_warehouse_id, v_cur.m_pricelist_id,	v_cur.c_project_id, v_cur.deliverynotes,
				v_cur.c_projecttask_id, v_cur.name, v_parent_order_id,v_cur.internalnote);
				v_dummy:= c_copyorderlineswithref(v_Record_ID, v_new_order_id, v_user,'Y');
				delete from c_orderline where c_orderline.c_order_id=v_new_order_id and c_orderline.c_project_id!=v_cur.c_project_id;
				v_Message:= v_Message || 'Weiterberechnungsauftrag erzeugt: ' || zsse_htmldirectlink('../SalesOrder/Header_Relation.html','document.frmMain.inpcOrderId', v_new_order_id, v_documentno) || '</br>';
				perform c_order_post1(null, v_new_order_id);
				v_updatedocno:='';
			end if;
		end loop;
	end if;
    -- Call User Exit Function
    select  v_message||c_order_post_userexit(v_Record_ID) into v_message;
    -- Finishing Process
    IF(p_PInstance_ID IS NOT NULL) THEN
        -- On Orders with paymentscheduling a warning schould be raised when payments in sheduling do not match order amount
        select totallines into ToDeliver from c_order where c_order_id=v_Record_ID;
        select sum(amount) into ToInvoice from c_order_paymentschedule where c_order_id=v_Record_ID;
        if ToInvoice is not null then
           if ToInvoice!=ToDeliver then
              v_Message:=v_message||'@ScheduledPaymentDifferFromOrderAmt@';
              v_result:=2;
           end if;
        end if;
        
        --  Update AD_PInstance
        RAISE NOTICE '%','Updating PInstance - Finished - ' || v_Message ;
        PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
    END IF;
    -- Schedule Update Project Status Process
    for v_prjcur in (select c_project_id from c_orderline where c_order_id=v_Record_ID and c_project_id is not null)
    LOOP
       perform zspm_updateprojectstatus(null,v_prjcur.c_project_id);
    END LOOP;
RETURN;
END; --BODY
EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%',v_ResultStr ;
  v_ResultStr:= '@ERROR=' || SQLERRM;
  IF(p_PInstance_ID IS NOT NULL) THEN
    -- ROLLBACK;
    --Inserted by Carlos Romero 062706
    UPDATE C_ORDER  SET Processing='N'  WHERE C_Order_ID=v_Record_ID;
    RAISE NOTICE '%',v_ResultStr ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  ELSE
    RAISE EXCEPTION '%', SQLERRM;
  END IF;
  RETURN;
END ; $_$;


-- User Exit to c_order_post1
CREATE or replace FUNCTION c_order_post_userexit(p_order_id varchar) RETURNS varchar
AS $_$
DECLARE
  BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION c_order_postaction(p_order_id character varying, p_action character varying, p_user character varying)
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
Part of Order Process
    Triggers Processing
*****************************************************/

BEGIN 
    update c_order set docaction=p_action,updatedby=p_user  where c_order_id=p_order_id;
    PERFORM c_order_post1(null, p_order_id);
    RETURN; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION m_requisition_createpo(p_pinstance_id character varying) RETURNS void
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
***************************************************************************************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_User_ID VARCHAR(32):='0'; --OBTG:VARCHAR2--
  v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_sales_rep_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Count NUMERIC;
  v_C_DOCTYPE_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_C_Order_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_DocumentNo VARCHAR(60); --OBTG:NVARCHAR2--
  v_Line NUMERIC;
  v_Vendor_Old VARCHAR(32); --OBTG:VARCHAR2--
  v_PriceList_Old VARCHAR(32); --OBTG:VARCHAR2--
  v_BPartner_Location_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_BillTo_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Currency_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_COrderLine_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_NoRecords NUMERIC:=0;
  v_RequisitionOrder_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_PaymentTerm_ID VARCHAR(32); --OBTG:VARCHAR2--

  v_PriceList NUMERIC;
  v_PriceLimit NUMERIC;
  v_PriceStd NUMERIC;
  v_PriceActual NUMERIC;
  v_Discount NUMERIC;
  v_Tax_ID VARCHAR(32); --OBTG:VARCHAR2--

  p_OrderDate TIMESTAMP;
  p_Vendor_ID VARCHAR(32); --OBTG:VARCHAR2--
  p_PriceList_ID VARCHAR(32); --OBTG:VARCHAR2--
  p_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
  p_Warehouse_ID VARCHAR(32); --OBTG:VARCHAR2--

  --  Parameter
  --TYPE RECORD IS REFCURSOR;
  Cur_Parameter RECORD;
  Cur_Product RECORD;
  Cur_Lines RECORD;
BEGIN
  RAISE NOTICE '%','BEGIN M_REQUISITION_ORDER ' || p_PInstance_ID ;
  v_ResultStr:='PInstanceNotFound';
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;

  BEGIN --BODY
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID, i.AD_User_ID, i.AD_Client_ID, i.AD_Org_ID,
        p.ParameterName, p.P_String, p.P_Number, p.P_Date
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo) LOOP
      IF (Cur_Parameter.ParameterName = 'DateOrdered') THEN
        p_OrderDate := Cur_Parameter.P_Date;
      ELSIF (Cur_Parameter.ParameterName = 'C_BPartner_ID') THEN
        p_Vendor_ID := Cur_Parameter.P_String;
      ELSIF (Cur_Parameter.ParameterName = 'M_PriceList_ID') THEN
        p_PriceList_ID := Cur_Parameter.P_String;
      ELSIF (Cur_Parameter.ParameterName = 'AD_Org_ID') THEN
        p_Org_ID := Cur_Parameter.P_String;
      ELSIF (Cur_Parameter.ParameterName = 'M_Warehouse_ID') THEN
        p_Warehouse_ID := Cur_Parameter.P_String;
      END IF;
      v_Record_ID:=Cur_Parameter.Record_ID;
      v_User_ID:=Cur_Parameter.AD_User_ID;
      v_Client_ID := Cur_Parameter.AD_Client_ID;
    END LOOP; -- Get Parameter

    v_ResultStr := 'Checking vendor';
    IF (p_Vendor_ID IS NULL) THEN
      FOR Cur_Product IN (
          SELECT M_PRODUCT.NAME, M_REQUISITIONLINE.LINE
          FROM M_REQUISITION, M_REQUISITIONLINE, M_PRODUCT
          WHERE M_REQUISITION.M_REQUISITION_ID = M_REQUISITIONLINE.M_REQUISITION_ID
            AND M_REQUISITIONLINE.M_PRODUCT_ID = M_PRODUCT.M_PRODUCT_ID
            AND M_REQUISITION.M_REQUISITION_ID = v_Record_ID
            AND M_REQUISITIONLINE.C_BPARTNER_ID IS NULL
            AND M_REQUISITION.C_BPARTNER_ID IS NULL
            AND NOT EXISTS (SELECT 1
                            FROM M_PRODUCT_PO
                            WHERE M_PRODUCT_PO.M_PRODUCT_ID = M_REQUISITIONLINE.M_PRODUCT_ID
                              AND M_PRODUCT_PO.ISACTIVE = 'Y'
                              AND M_PRODUCT_PO.ISCURRENTVENDOR = 'Y'
                              AND M_PRODUCT_PO.DISCONTINUED = 'N')) LOOP
        v_Message := '@Inline@ ' || Cur_Product.line || ' @ForProduct@ ' || Cur_Product.Name || ' @BPartnerNotFound@';
        RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
      END LOOP;
    END IF;

    v_ResultStr:='Start lines cursor';
    FOR Cur_Lines IN
      (SELECT A.*,
           C_BPARTNER.PAYMENTRULEPO AS PAYMENTRULE, C_BPARTNER.PO_PAYMENTTERM_ID AS C_PAYMENTTERM_ID,
           C_BPARTNER.DELIVERYRULE, C_BPARTNER.DELIVERYVIARULE, C_BPARTNER.C_BPARTNER_ID AS C_BPID
       FROM (SELECT COALESCE(p_Vendor_ID, M_REQUISITIONLINE.C_BPARTNER_ID, M_REQUISITION.C_BPARTNER_ID, PRODUCT_PO.C_BPARTNER_ID) AS VENDOR_ID,
                 COALESCE(p_PriceList_ID, M_REQUISITION.M_PRICELIST_ID) AS PRICELIST_ID,
                 M_REQUISITIONLINE.*
              FROM M_REQUISITION, M_REQUISITIONLINE LEFT JOIN (SELECT MAX(C_BPARTNER_ID) AS C_BPARTNER_ID, M_PRODUCT_ID
                                                               FROM M_PRODUCT_PO
                                                               WHERE ISCURRENTVENDOR = 'Y'
                                                                 AND ISACTIVE = 'Y'
                                                                 AND DISCONTINUED = 'N'
                                                               GROUP BY M_PRODUCT_ID) PRODUCT_PO
                                                              ON M_REQUISITIONLINE.M_PRODUCT_ID = PRODUCT_PO.M_PRODUCT_ID
              WHERE M_REQUISITION.M_REQUISITION_ID = M_REQUISITIONLINE.M_REQUISITION_ID
                AND M_REQUISITION.M_REQUISITION_ID = v_Record_ID
                AND M_REQUISITIONLINE.REQSTATUS = 'O'
                AND NOT (COALESCE(M_REQUISITIONLINE.LOCKEDBY, v_User_ID) <> v_User_ID
                         AND COALESCE(M_REQUISITIONLINE.LOCKDATE, TO_DATE('01-01-1900', 'DD-MM-YYYY')) >= (TO_DATE(NOW())-3))
              ) A, C_BPARTNER
       WHERE A.VENDOR_ID = C_BPARTNER.C_BPARTNER_ID
       ORDER BY A.VENDOR_ID, COALESCE(A.A_PRICELIST_ID, C_BPARTNER.PO_PRICELIST_ID), A.NEEDBYDATE) LOOP
      v_ResultStr:='Line start';

      IF (Cur_Lines.PRICELIST_ID IS NULL ) THEN
        v_Message := '@PriceListVersionNotFound@';
        RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
      END IF;

      IF (v_C_Order_ID IS NULL OR v_Vendor_Old <> Cur_Lines.Vendor_ID OR v_PriceList_Old <> Cur_Lines.PriceList_ID) THEN
        IF (v_C_Order_ID IS NOT NULL) THEN
          v_ResultStr := 'Post Order ' || v_C_Order_ID;
          PERFORM C_ORDER_POST1(null, v_C_Order_ID);
          v_Message := v_Message || ', ' || '@OrderDocumentno@ ' || v_DocumentNo;
        END IF;
        v_ResultStr := 'Create new C_Order';
        v_Vendor_Old := Cur_Lines.Vendor_ID;
        v_PriceList_Old := Cur_Lines.PriceList_ID;
        v_Line := 0;
        v_NoRecords := v_NoRecords +1;
        v_C_Order_ID:=Ad_Sequence_Nextno('C_Order') ;
        v_C_DOCTYPE_ID:=Ad_Get_DocType(v_Client_ID, p_Org_ID, 'POO') ;
        SELECT * INTO  v_DocumentNo FROM AD_Sequence_DocType(v_C_DOCTYPE_ID, p_Org_ID, 'Y') ;
        IF(v_DocumentNo IS NULL) THEN
          SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('DocumentNo_C_Order', p_Org_ID, 'Y') ;
        END IF;
        SELECT MIN(C_BPARTNER_LOCATION_ID) INTO v_BPartner_Location_ID
        FROM C_BPARTNER_LOCATION
        WHERE ISACTIVE='Y'
          AND ISSHIPTO='Y'
          AND C_BPARTNER_ID=Cur_Lines.Vendor_ID;
        SELECT MIN(AD_USER_ID) INTO v_sales_rep_ID
         FROM AD_USER
         WHERE ISACTIVE='Y'
         AND C_BPARTNER_ID=Cur_Lines.Vendor_ID;  
        SELECT MIN(C_BPARTNER_LOCATION_ID) INTO v_BillTo_ID
        FROM C_BPARTNER_LOCATION
        WHERE ISACTIVE='Y'
          AND ISBILLTO='Y'
          AND C_BPARTNER_ID=Cur_Lines.Vendor_ID;

        SELECT C_CURRENCY_ID INTO v_Currency_ID
        FROM M_PRICELIST
        WHERE M_PRICELIST_ID = Cur_Lines.Pricelist_ID;

        IF(Cur_Lines.C_PAYMENTTERM_ID IS NULL) THEN
          SELECT c_paymentterm_id INTO v_PaymentTerm_ID
          FROM c_paymentterm
          WHERE isactive='Y'
            AND isdefault='Y'
            AND AD_Client_ID = v_Client_ID;
        END IF;


        v_ResultStr := 'Insert C_Order id: ' || v_C_Order_ID || ' No.: ' || v_DocumentNo;
        INSERT INTO C_ORDER (
            C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,
            UPDATEDBY, ISSOTRX, DOCUMENTNO, DOCSTATUS,
            DOCACTION, C_DOCTYPE_ID, C_DOCTYPETARGET_ID, DATEORDERED,
            DATEACCT, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID, ISDISCOUNTPRINTED,
            C_CURRENCY_ID, PAYMENTRULE, C_PAYMENTTERM_ID, INVOICERULE,
            DELIVERYRULE, FREIGHTCOSTRULE, DELIVERYVIARULE, PRIORITYRULE,
            TOTALLINES, GRANDTOTAL, M_WAREHOUSE_ID, M_PRICELIST_ID,
            ISTAXINCLUDED, POSTED, PROCESSING, BILLTO_ID,
            AD_USER_ID, COPYFROM, DATEPROMISED
        ) VALUES (
            v_C_Order_ID, v_CLIENT_ID, p_Org_ID, v_User_ID,
            v_User_ID, 'N', v_DocumentNo, 'DR',
             'CO', '0', v_C_DOCTYPE_ID, p_OrderDate,
            p_OrderDate, Cur_Lines.vendor_Id, v_BPartner_Location_ID, 'N',
            v_Currency_ID, COALESCE(Cur_Lines.PAYMENTRULE, 'P'), COALESCE(Cur_Lines.C_PAYMENTTERM_ID, v_PaymentTerm_ID), 'D',
            COALESCE(Cur_Lines.Deliveryrule, 'A'), 'I', 'D', '5',
            0, 0, p_WAREHOUSE_ID, Cur_Lines.PRICELIST_ID,
             'N', 'N', 'N', v_BillTo_ID,
            v_sales_rep_ID, 'N', Cur_Lines.NEEDBYDATE
        );
      END IF;

      v_ResultStr := 'Create C_Order_Line';
      v_Line := v_Line + 10;
      SELECT * INTO  v_COrderLine_ID FROM Ad_Sequence_Next('C_OrderLine', v_Client_ID);
      v_PriceActual:=Cur_Lines.priceactual;
      v_PriceList:=Cur_Lines.priceactual;
      v_PriceLimit:=Cur_Lines.priceactual;
      v_PriceStd:=v_PriceActual;
      v_Discount:=0;
      

      IF (v_PriceActual IS NULL) THEN
        v_Message := '@PriceNotFound@';
        RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
      END IF;
      -- Get Tax
      v_Tax_ID := zsfi_GetTax(v_BillTo_ID, Cur_Lines.M_Product_ID, p_Org_ID);
 
      v_ResultStr:='Insert order line';
      INSERT INTO C_OrderLine (
          C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
          CREATED, CREATEDBY, UPDATED, UPDATEDBY,
          C_ORDER_ID, LINE, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID,
          DATEORDERED, DATEPROMISED, DESCRIPTION, M_PRODUCT_ID,
          M_ATTRIBUTESETINSTANCE_ID,
          M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED, C_CURRENCY_ID,
          PRICELIST, PRICEACTUAL, PRICELIMIT,
          PRICESTD, LINENETAMT, DISCOUNT,
          C_TAX_ID, M_PRODUCT_UOM_ID, QUANTITYORDER,a_asset_id,c_project_id
      ) VALUES (
          v_COrderLine_ID,v_Client_ID, p_Org_ID,'Y',
          TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID,
          v_C_Order_ID, v_Line, Cur_Lines.Vendor_ID, v_BPartner_Location_ID,
          p_OrderDate, Cur_Lines.NEEDBYDATE, Cur_Lines.SUPPLIERNOTES, Cur_Lines.M_Product_ID,
          Cur_Lines.M_AttributeSetInstance_ID,
          p_Warehouse_ID, Cur_Lines.C_UOM_ID, Cur_Lines.QTY - Cur_Lines.ORDEREDQTY, v_Currency_ID,
          v_PriceList, v_PriceActual, v_PriceLimit,
          v_PriceStd, v_PriceActual*(Cur_Lines.QTY - Cur_Lines.ORDEREDQTY),v_Discount,
          v_Tax_ID, Cur_Lines.M_Product_UOM_ID, Cur_Lines.QuantityOrder,Cur_Lines.a_asset_id,Cur_Lines.c_project_id
      );

      SELECT * INTO  v_RequisitionOrder_ID FROM Ad_Sequence_Next('M_RequisitionOrder', v_User_ID);

      INSERT INTO M_REQUISITIONORDER (
        M_REQUISITIONORDER_ID, AD_CLIENT_ID, AD_ORG_ID,
        CREATED, CREATEDBY, UPDATED, UPDATEDBY, ISACTIVE,
        M_REQUISITIONLINE_ID, C_ORDERLINE_ID, QTY
      ) VALUES (
        v_RequisitionOrder_ID, v_Client_ID, p_Org_ID,
        TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID, 'Y',
        Cur_Lines.M_RequisitionLine_ID, v_COrderLine_ID, Cur_Lines.QTY - Cur_Lines.ORDEREDQTY
      );
      PERFORM M_REQUISITIONLINE_STATUS(NULL, Cur_Lines.M_RequisitionLine_ID, v_User_ID);
    END LOOP;

    v_ResultStr := 'Post last Order ' || v_C_Order_ID;
    --PERFORM C_ORDER_POST1(null, v_C_Order_ID);
    v_Message := v_Message || ', ' || '@OrderDocumentno@ ' || v_DocumentNo;





  END; --BODY
  v_Message:='@Created@: ' || v_NoRecords || v_Message;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message);

EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%','M_Requisition_Order error: ' || v_ResultStr;
  IF (p_PInstance_ID IS NOT NULL) THEN
    v_ResultStr:= '@ERROR=' || SQLERRM;
    RAISE NOTICE '%',v_ResultStr ;
    -- ROLLBACK;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr);
  ELSE
    RAISE EXCEPTION '%', SQLERRM;
  END IF;
END ; $_$;


ALTER FUNCTION public.m_requisition_createpo(p_pinstance_id character varying) OWNER TO tad;


-- Version 2.6.02.036
--


CREATE OR REPLACE FUNCTION c_order_trg2() RETURNS trigger
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
* Contributor(s): 
* Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Zimmermann-Software
* Frank Wohlers, 02/2012, fw@zimmermann-software.de (FW) Contributions are Copyright (C) 2012 Zimmermann-Software
***************************************************************************************************************************************************
Allow Updates of Prcelist or Business Partner or Warehouse
Gets predefined Textmodules into Order

*****************************************************/
    v_DateNull TIMESTAMP := TO_DATE('01-01-1900','DD-MM-YYYY');
    
    --TYPE RECORD IS REFCURSOR;
    Cur_Discounts RECORD;
    v_curr character varying;
    v_count numeric;
    v_orgfrom character varying;
    v_cur RECORD; 
	v_totalpaid numeric;
	v_iscompletelyinvoiced character varying;
	v_transactiondate date;
	v_firstschedinvoicedate date;
	v_completeordervalue numeric;
	v_invoicedamt numeric;
	v_grandtotalonetime numeric;
	v_totallinesonetime numeric;
	v_enddate date;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;

  IF(TG_OP = 'UPDATE') THEN  
      IF((COALESCE(old.PaymentRule, '.') <> COALESCE(NEW.PaymentRule, '.')
          OR COALESCE(old.C_PaymentTerm_ID, '0') <> COALESCE(NEW.C_PaymentTerm_ID, '0')
          OR COALESCE(old.DateAcct, v_DateNull) <> COALESCE(NEW.DateAcct, v_DateNull)))
      THEN
              -- Propagate Changes of Payment Info to existing invoices
              UPDATE C_Invoice
                SET PaymentRule=new.PaymentRule,
                C_PaymentTerm_ID=new.C_PaymentTerm_ID,
                DateAcct=new.DateAcct
              WHERE C_Order_ID=new.C_Order_ID
                AND DocStatus NOT IN('RE', 'CL', 'CO') ;
      END IF;
      -- SZ: If changing Doctype and new Doctype is not subscription, onetimeposition in the Lines must be 'N'
      if old.c_doctype_id!=new.c_doctype_id and new.c_doctype_id not in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24','7DE8D4B1B8824D36974E8064BBED5095') then --Subscription Order, Subscription Proposal
         update c_orderline set isonetimeposition ='N' where c_order_id=new.c_order_id and isonetimeposition ='Y';
      end if;
        -- SZ/FW: If B-Partner, Project, Date ordered, Date Promised, Scheduled Delivery Date or Currency changed: Propagate to lines
        if 	
                new.c_bpartner_location_id != old.c_bpartner_location_id or
                new.c_bpartner_id != old.c_bpartner_id or
                new.m_pricelist_id != old.m_pricelist_id or
                coalesce(new.c_project_id, '0') != coalesce(old.c_project_id, '0') or
                coalesce(new.c_projecttask_id, '0') != coalesce(old.c_projecttask_id, '0') or
                coalesce(new.a_asset_id, '0') != coalesce(old.a_asset_id, '0') or
                coalesce(new.scheddeliverydate, new.created) != coalesce(old.scheddeliverydate, new.created) or
                coalesce(new.datepromised, new.created) != coalesce(old.datepromised, new.created) or
                new.dateordered != old.dateordered
        then	
                -- Sauberer Umgang mit Projektzuordnung
                if coalesce(new.c_project_id, '0') != coalesce(old.c_project_id, '0') and new.c_project_id is null then
                    new.c_projecttask_id:=null;
                end if;
                select c_currency_id into v_curr from m_pricelist where m_pricelist_id = new.m_pricelist_id;
                update 	
                        c_orderline ol
                set 	
                        c_bpartner_location_id = new.c_bpartner_location_id, 
                        c_currency_id = v_curr, 
                        c_bpartner_id = new.c_bpartner_id,
                        c_project_id = new.c_project_id,
                        c_projecttask_id = new.c_projecttask_id,
                        a_asset_id = new.a_asset_id, 
                        datepromised = new.datepromised, 
                        scheddeliverydate = new.scheddeliverydate,
                        dateordered = new.dateordered
                where 
                        c_order_id = new.c_order_id and 
                        isonetimeposition = 'N' and
                        (coalesce((select isonetimeposition from c_orderline ol2 where ol2.c_orderline_id = ol.ref_orderline_id), 'N') = 'N');
        end if;
      -- FW: Propagate subscription interval changes to subscription order header
      if
              new.c_doctype_id in ('6C8EA6FFBB2B4ACBA0542BA4F833C499','52C79B0ABF04413DA133B71A3C6157A9')
      then
              select 
                      coalesce(sum(c_order.totalpaid),0),
                      coalesce(min(c_order.iscompletelyinvoiced),'N'),
                      max(c_order.transactiondate),
                      min(c_order.datepromised),
                      coalesce(sum(c_order.totallines),0),
                      coalesce(sum(c_order.invoicedamt),0)
                      --coalesce(sum(c_order.grandtotalonetime),0)
                      --coalesce(sum(c_order.totallinesonetime),0)
                      --max(c_order.enddate)
              into
                      v_totalpaid,
                      v_iscompletelyinvoiced,
                      v_transactiondate,
                      v_firstschedinvoicedate,
                      v_completeordervalue,
                      v_invoicedamt
                      --v_grandtotalonetime
                      --v_totallinesonetime
                      --v_enddate
              from 
                      c_order 
              where 	
                      c_order.orderselfjoin = new.orderselfjoin and
                      c_order.docstatus = 'CO';
              update c_order set
                      totalpaid = v_totalpaid,
                      iscompletelyinvoiced = v_iscompletelyinvoiced,
                      transactiondate = v_transactiondate,
                      firstschedinvoicedate = v_firstschedinvoicedate,
                      completeordervalue = v_completeordervalue,
                      invoicedamt = v_invoicedamt
                      --grandtotalonetime
                      --totallinesonetime
                      --enddate = v_enddate
              where 
                      c_order_id = new.orderselfjoin and 
                      case when  new.c_doctype_id ='6C8EA6FFBB2B4ACBA0542BA4F833C499' then c_order.c_doctype_id = 'ABE2033C7A74499A9750346A83DE3307'
                      else c_order.c_doctype_id = 'EAF34F4237D0488F923F218234509E24' end;
      end if;
  END IF; --UPDATING
  IF(TG_OP = 'INSERT') then
     --Take Textmodule either from Org=0 or current organization 
     for v_cur in (select * from zssi_textmodule where c_doctype_id=new.c_doctypetarget_id and ad_org_id in ('0',new.ad_org_id) and isactive='Y' and isautoadd='Y' and 
                                            coalesce(c_bpartner_id,new.c_bpartner_id)=new.c_bpartner_id order by islower,position )
     LOOP
        -- Get predefined Textmodules into Order
        insert into zssi_order_textmodule (ZSSI_ORDER_TEXTMODULE_ID, zssi_textmodule_id,C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, LINE, ISLOWER, TEXT)
               values (get_uuid(),v_cur.zssi_textmodule_id,new.c_order_id,new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,v_cur.position,v_cur.islower,v_cur.text);
     END LOOP;
   end if; --Inserting 
   IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

CREATE OR REPLACE FUNCTION c_ordline_chk_restrictions_trg()
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
* Contributor(s): Stefan Zimmermann, 02/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2012 Stefan Zimmermann
***************************************************************************************************************************************************/

  v_Processed VARCHAR(60) ;
  v_C_ORDER_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  v_Docaction VARCHAR(60) ;
  v_Docstatus VARCHAR(60);
  v_DocumentNo C_ORDER.DocumentNO%TYPE;
  v_IsSOTrx CHAR(1);
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_count numeric;  
  v_doctype varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  -- Persist Ignore Residue Date for Business Analysis Purposes
  IF TG_OP = 'UPDATE' THEN
     if new.ignoreresidue='Y' and old.ignoreresidue='N' then
         new.ignoreresiduedate := now();
     elsif new.ignoreresidue='N' and old.ignoreresidue='Y' then
         new.ignoreresiduedate := null;
     end if;
  end if;
  -- Reverse Charge only on net pricelist
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    select count(*) into v_count from m_pricelist p,c_order o  where o.c_order_id=new.c_order_id and o.m_pricelist_id=p.m_pricelist_id and  p.istaxincluded='Y';
    if v_count>0 then
        select count(*) into v_count from c_tax t where t.c_tax_id=new.c_tax_id and t.reversecharge='Y';
        if v_count>0 then
            raise exception '%','@grosspricelistnoreversecharge@';
        end if;
    end if;
  END IF;
  -- Manufacturer only in Purchasing
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    select count(*) into v_count from c_order o  where o.c_order_id=new.c_order_id and o.issotrx='Y';
    if v_count>0 then
        new.m_product_po_id:= null;
    end if;
  END IF;
  -- UOM check
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        if (new.quantityorder is null and new.m_product_uom_id is not null) or (new.quantityorder is not null and new.m_product_uom_id is  null) then
            raise exception '%','@secondUOMRequiresQTY@';
        end if;
  END IF;
  IF TG_OP = 'INSERT' THEN
    v_C_ORDER_ID:=NEW.C_ORDER_ID;
  ELSE
    v_C_ORDER_ID:=OLD.C_ORDER_ID;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    IF((COALESCE(old.LINE, 0) <> COALESCE(NEW.LINE, 0) OR COALESCE(old.M_PRODUCT_ID, '0') <> COALESCE(NEW.M_PRODUCT_ID, '0') OR COALESCE(old.QTYORDERED, 0) <> COALESCE(NEW.QTYORDERED, 0) OR COALESCE(old.PRICELIST, 0) <> COALESCE(NEW.PRICELIST, 0) OR COALESCE(old.PRICEACTUAL, 0) <> COALESCE(NEW.PRICEACTUAL, 0) OR COALESCE(old.PRICELIMIT, 0) <> COALESCE(NEW.PRICELIMIT, 0) OR COALESCE(old.LINENETAMT, 0) <> COALESCE(NEW.LINENETAMT, 0) OR COALESCE(old.C_CHARGE_ID, '0') <> COALESCE(NEW.C_CHARGE_ID, '0') OR COALESCE(old.CHARGEAMT, 0) <> COALESCE(NEW.CHARGEAMT, 0) OR COALESCE(old.C_TAX_ID, '0') <> COALESCE(NEW.C_TAX_ID, '0')  OR COALESCE(old.M_ATTRIBUTESETINSTANCE_ID, '0') <> COALESCE(NEW.M_ATTRIBUTESETINSTANCE_ID, '0') OR COALESCE(old.QUANTITYORDER, 0) <> COALESCE(NEW.QUANTITYORDER, 0) OR 
     COALESCE(old.M_PRODUCT_UOM_ID, '0') <> COALESCE(NEW.M_PRODUCT_UOM_ID, '0') or COALESCE(old.isonetimeposition, '0') <> COALESCE(NEW.isonetimeposition, '0')
      OR COALESCE(old.QtyInvoiced, 0) <> COALESCE(NEW.QtyInvoiced, 0))) THEN
      SELECT PROCESSED,
        DOCACTION, DOCSTATUS, DocumentNo, ISSOTRX,c_doctypetarget_id
      INTO v_Processed,
        v_Docaction, v_DocStatus, v_DocumentNo, v_IsSOTrx,v_doctype
      FROM C_ORDER
      WHERE C_ORDER_ID=v_C_ORDER_ID;
      IF((COALESCE(OLD.LINE, 0) <> COALESCE(NEW.LINE, 0))
          OR(COALESCE(OLD.M_PRODUCT_ID, '0') <> COALESCE(NEW.M_PRODUCT_ID, '0'))
          OR((COALESCE(OLD.QTYORDERED, 0) <> COALESCE(NEW.QTYORDERED, 0)) and v_doctype!='CC33ECC618F44A6A8F7FEFBEA942739E') -- Rental Orders can be extended...
          OR(COALESCE(OLD.PRICELIST, 0) <> COALESCE(NEW.PRICELIST, 0))
          OR(COALESCE(OLD.PRICEACTUAL, 0) <> COALESCE(NEW.PRICEACTUAL, 0))
          --OR(COALESCE(OLD.PRICELIMIT, 0) <> COALESCE(NEW.PRICELIMIT, 0))
          OR(COALESCE(OLD.LINENETAMT, 0) <> COALESCE(NEW.LINENETAMT, 0))
          OR(COALESCE(OLD.C_CHARGE_ID, '0') <> COALESCE(NEW.C_CHARGE_ID, '0'))
          OR(COALESCE(OLD.CHARGEAMT, 0) <> COALESCE(NEW.CHARGEAMT, 0))
          OR(COALESCE(OLD.C_TAX_ID, '0') <> COALESCE(NEW.C_TAX_ID, '0'))
          OR(COALESCE(OLD.M_ATTRIBUTESETINSTANCE_ID, '0') <> COALESCE(NEW.M_ATTRIBUTESETINSTANCE_ID, '0'))
          OR((COALESCE(OLD.QUANTITYORDER, 0) <> COALESCE(NEW.QUANTITYORDER, 0)) and v_doctype!='CC33ECC618F44A6A8F7FEFBEA942739E') -- Rental Orders can be extended...
          OR(COALESCE(OLD.M_PRODUCT_UOM_ID, '0') <> COALESCE(NEW.M_PRODUCT_UOM_ID, '0'))
          OR(COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
          OR(COALESCE(old.isonetimeposition, '0') <> COALESCE(NEW.isonetimeposition, '0'))
          OR(COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0'))
        ) THEN
        IF (v_Processed='Y' AND v_Docaction <> 'CL') THEN
          RAISE EXCEPTION '%', '@DocumentProcessedOrPosted@';
          -- For debug: ||NEW.C_TAX_ID||'#'||COALESCE(NEW.M_ATTRIBUTESETINSTANCE_ID, '0')||'#'||COALESCE(NEW.PRICELIST, 0)||'#'||COALESCE(NEW.PRICEACTUAL, 0)||'#'||COALESCE(NEW.PRICELIMIT, 0)||'#'||COALESCE(NEW.LINENETAMT, 0) 
        ELSIF (c_getconfigoption('alloworderchangesafterdelivery',new.AD_ORG_ID)='N'  AND v_DocStatus = 'DR' AND (OLD.QTYDELIVERED <> 0 OR OLD.QTYINVOICED <> 0)) THEN
                  RAISE EXCEPTION '%', '@DeliveredInvoicedOrderline@'; 
        ELSE
                -- Implemented Restrictions on Orders that have changes and are Delivered or Invoiced before.
                If COALESCE(OLD.QTYORDERED, 0) <> COALESCE(NEW.QTYORDERED, 0) and COALESCE(NEW.QTYORDERED, 0)<COALESCE(NEW.QTYDELIVERED, 0) then
                        RAISE EXCEPTION '%', '@cannotChangeQTYorderedLessThenQTYDelivered@'; 
                end if;
                -- For Frame Contracts
                if (select c_doctype_id from c_order where c_order_id=new.c_order_id) in ('559A80F2E27742D4B2C476045F5C834F','56913A519BA94EB59DAE5BF9A82F5F7D') then
                    If COALESCE(OLD.QTYORDERED, 0) <> COALESCE(NEW.QTYORDERED, 0) and COALESCE(NEW.QTYORDERED, 0)<COALESCE(NEW.calloffqty, 0) then
                            RAISE EXCEPTION '%', '@cannotChangeQTYorderedLessThenQTYDelivered@'; 
                    end if;
                    if COALESCE(OLD.M_PRODUCT_ID, '0') <> COALESCE(NEW.M_PRODUCT_ID, '0') and COALESCE(OLD.calloffqty, 0)>0 then
                                 RAISE EXCEPTION '%', '@CannotChangeProductOnDeliveredOrInvoicedLines@'; 
                    end if;
                end if;
                If COALESCE(OLD.QTYORDERED, 0) <> COALESCE(NEW.QTYORDERED, 0) and COALESCE(NEW.QTYORDERED, 0)<COALESCE(NEW.QTYINVOICED, 0) then
                         RAISE EXCEPTION '%', '@cannotChangeQTYorderedLessThenQTYInvoiced@'; 
                end if;
                if    (OLD.QTYDELIVERED <> 0 OR OLD.QTYINVOICED <> 0) then
                        if COALESCE(OLD.M_PRODUCT_ID, '0') <> COALESCE(NEW.M_PRODUCT_ID, '0') then
                                 RAISE EXCEPTION '%', '@CannotChangeProductOnDeliveredOrInvoicedLines@'; 
                        end if;
                         if    (OLD.line <> new.line) then
                                RAISE EXCEPTION '%', '@CannotChangeLineOnDeliveredOrInvoicedLines@'; 
                         end if;
                end if;
        END IF;
    --  ELSIF (v_IsSOTrx = 'Y' AND ABS(new.QtyInvoiced) > ABS(new.QtyOrdered)) THEN
    --    v_Message := '@OrderDocumentno@' || ' ' || v_DocumentNo || ' ' || '@line@' || old.line || '. ';
    --    v_Message := v_Message || '@QtyInvoicedHigherOrdered@';
    --    RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
      END IF;
    END IF;
  END IF;
  IF TG_OP = 'DELETE' THEN
          IF OLD.QTYDELIVERED <> 0 OR OLD.QTYINVOICED <> 0 then
                  RAISE EXCEPTION '%', '@CannotDeleteOnDeliveredOrInvoicedLines@'; 
          end if;
  END IF; 
  IF(TG_OP = 'DELETE' OR TG_OP = 'INSERT') THEN
  SELECT PROCESSED,
    DOCACTION
  INTO v_Processed,
    v_Docaction
  FROM C_ORDER
  WHERE C_ORDER_ID=v_C_ORDER_ID;
    IF (v_Processed='Y') THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION c_order_trg() RETURNS trigger
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
    * $Id: C_Order_Trg.sql,v 1.4 2003/05/30 04:23:38 jjanke Exp $
    ***
    * Title: Order Trigger
    * Description:
    *  Update potentially existing Invoices with Payment Info
    *  Sync Header Changes to Lines
    ************************************************************************/
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  IF(TG_OP = 'UPDATE')
    THEN  IF((COALESCE(old.Description, '.') <> COALESCE(NEW.Description, '.')
    OR COALESCE(old.POReference, '.') <> COALESCE(NEW.POReference, '.')
    OR COALESCE(old.C_BPartner_ID, '0') <> COALESCE(NEW.C_BPartner_ID, '0')
    OR COALESCE(old.C_BPartner_Location_ID, '0') <> COALESCE(NEW.C_BPartner_Location_ID, '0')
    OR COALESCE(old.M_Warehouse_ID, '0') <> COALESCE(NEW.M_Warehouse_ID, '0')
    OR COALESCE(old.M_Shipper_ID, '0') <> COALESCE(NEW.M_Shipper_ID, '0')
    OR COALESCE(old.C_Currency_ID, '0') <> COALESCE(NEW.C_Currency_ID, '0') ))
    THEN
    -- If order is processed, is not allowed to change C_BPartner nor M_WareHouse nor AD_ORG_ID nor AD_CLIENT_ID
    IF(old.Processed='Y'
        AND ( (COALESCE(old.C_BPartner_ID, '0') <> COALESCE(new.C_BPartner_ID, '0'))
                OR (COALESCE(old.M_WareHouse_ID, '0') <> COALESCE(new.M_WareHouse_ID, '0'))
                OR (COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
            OR (COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0'))
        )
    )
    THEN  RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  -- Propagate Description changes
  UPDATE C_Invoice
   SET POReference=new.POReference
  WHERE C_Order_ID=new.C_Order_ID;
  END IF;
 END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;



CREATE OR REPLACE FUNCTION c_order_chk_restrinctions_trg() RETURNS trigger
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
Allow change of Business Partner
Do not check Posted - Is not relevant on Orders.
*****************************************************/
v_DateNull TIMESTAMP := TO_DATE('01-01-1900','DD-MM-YYYY');
v_offprob character varying;
v_count numeric;
v_datepromised character varying;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
  IF TG_OP = 'INSERT' THEN
    new.c_doctype_id=new.c_doctypetarget_id;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    if old.c_doctypetarget_id!=new.c_doctypetarget_id then
        if (select count(*) from c_order where c_order.orderselfjoin = new.c_order_id) > 0 OR
            (select count(*) from c_invoice where c_invoice.c_order_id = new.c_order_id) > 0 OR
            (select count(*) from m_inout where m_inout.c_order_id = new.c_order_id) > 0 
        THEN
            RAISE EXCEPTION '%', '@cannotchangedoctype@';
        END IF;
        new.c_doctype_id=new.c_doctypetarget_id;
    end if;
  END IF;
  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
       select count(*) into v_count from c_order where documentno=new.documentno and c_doctype_id=new.c_doctype_id and c_order_id!=new.c_order_id;
       if v_count>0 then
          -- allow updates on old duplicate orders...
          if TG_OP = 'UPDATE' then
             if new.documentno!=old.documentno or new.c_doctype_id!=old.c_doctype_id then
                      RAISE EXCEPTION '%', '@DuplicateDocNo@' ||new.documentno||'#'||old.documentno;
             end if;
          else
             RAISE EXCEPTION '%', '@DuplicateDocNo@'||new.documentno ;
          end if;
       end if;
       if new.dateacct is null then new.dateacct:=trunc(now()); end if;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    IF  (COALESCE(OLD.M_PriceList_ID,'0') != COALESCE(NEW.M_PriceList_ID,'0'))
         OR OLD.ad_org_ID != NEW.ad_org_ID  THEN
      SELECT COUNT(*)
        INTO v_count
        FROM C_ORDERLINE
       WHERE C_ORDER_ID = NEW.C_ORDER_ID;
       IF v_count>0 THEN
         if new.c_doctypetarget_id='8CF74AC370B04133B54C44A12E084749' then
            -- Request for Quotation (Anfrage PO) can change Currency
            select c_currency_id into new.c_currency_id from m_pricelist where m_pricelist_id = NEW.M_PriceList_ID;
         else
            RAISE EXCEPTION '%', '@existingLines@' ; --OBTG:-20502--@existingLines@
         end if;
       END IF;
     END IF;
  END IF;
  IF TG_OP = 'UPDATE' THEN
          IF old.documentno!=new.documentno and (select count(*) from c_orderline where (qtyinvoiced!=0 or qtydelivered!=0) and c_order_id=new.c_order_id)>0 
             and old.c_doctype_id not in ('ABE2033C7A74499A9750346A83DE3307','6C8EA6FFBB2B4ACBA0542BA4F833C499','EAF34F4237D0488F923F218234509E24','52C79B0ABF04413DA133B71A3C6157A9') -- Subscriptions
          then
                  RAISE EXCEPTION '%', '@DocumentNoCannotBeChangedInvoiceOrDeliveryExists@' ; 
          end if;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    -- Check if on Drop Ship Order the BPartner is Dropshipper
    if new.c_doctype_id='EE19ABBDB5A94C519DAB11003320FC8E' and (select count(*) from c_bpartner where c_bpartner_id=new.c_bpartner_id and isdropshipper='Y')=0 then
            raise exception '%','@bpartnerNoDropshipper@';
    end if;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    IF(OLD.Processed='Y' AND OLD.Docaction <> 'CL'
          AND(
               (COALESCE(OLD.C_BPartner_ID, '0') <> COALESCE(NEW.C_BPartner_ID, '0'))
               OR(COALESCE(OLD.DOCUMENTNO, '.') <> COALESCE(NEW.DOCUMENTNO, '.'))
               OR(COALESCE(OLD.C_DOCTYPE_ID, '0') <> COALESCE(NEW.C_DOCTYPE_ID, '0'))
               OR(COALESCE(OLD.C_DOCTYPETARGET_ID, '0') <> COALESCE(NEW.C_DOCTYPETARGET_ID, '0'))
               OR(COALESCE(TRUNC(OLD.DATEORDERED), v_DateNull) <> COALESCE(TRUNC(NEW.DATEORDERED), v_DateNull))
               OR(COALESCE(OLD.C_BPARTNER_LOCATION_ID, '0') <> COALESCE(NEW.C_BPARTNER_LOCATION_ID, '0'))
               OR(COALESCE(OLD.PAYMENTRULE, '.') <> COALESCE(NEW.PAYMENTRULE, '.'))
               OR(COALESCE(OLD.C_PAYMENTTERM_ID, '0') <> COALESCE(NEW.C_PAYMENTTERM_ID, '0'))
               OR(COALESCE(OLD.C_CHARGE_ID, '0') <> COALESCE(NEW.C_CHARGE_ID, '0'))
               OR(COALESCE(OLD.CHARGEAMT, 0) <> COALESCE(NEW.CHARGEAMT, 0))
               OR ((COALESCE(OLD.TOTALLINES, 0) <> COALESCE(NEW.TOTALLINES, 0)) and new.C_DOCTYPETARGET_ID!='CC33ECC618F44A6A8F7FEFBEA942739E') -- Rental Orders can be extended...
               OR ((COALESCE(OLD.GRANDTOTAL, 0) <> COALESCE(NEW.GRANDTOTAL, 0)) and new.C_DOCTYPETARGET_ID!='CC33ECC618F44A6A8F7FEFBEA942739E')
               OR(COALESCE(OLD.BILLTO_ID, '0') <> COALESCE(NEW.BILLTO_ID, '0'))
               OR(COALESCE(OLD.DELIVERYRULE, '.') <> COALESCE(NEW.DELIVERYRULE, '.'))
               OR(COALESCE(OLD.M_PRICELIST_ID, '0') <> COALESCE(NEW.M_PRICELIST_ID, '0'))
               OR(COALESCE(OLD.AD_ORGTRX_ID, '0') <> COALESCE(NEW.AD_ORGTRX_ID, '0'))
               OR(COALESCE(OLD.USER1_ID, '0') <> COALESCE(NEW.USER1_ID, '0'))
               OR(COALESCE(OLD.M_WAREHOUSE_ID, '0') <> COALESCE(NEW.M_WAREHOUSE_ID, '0'))
               OR(COALESCE(OLD.DROPSHIP_USER_ID, '0') <> COALESCE(NEW.DROPSHIP_USER_ID, '0'))
               OR(COALESCE(OLD.USER2_ID, '0') <> COALESCE(NEW.USER2_ID, '0'))
               OR(COALESCE(OLD.DROPSHIP_BPARTNER_ID, '0') <> COALESCE(NEW.DROPSHIP_BPARTNER_ID, '0'))
               OR(COALESCE(OLD.DROPSHIP_LOCATION_ID, '0') <> COALESCE(NEW.DROPSHIP_LOCATION_ID, '0'))
               OR(COALESCE(OLD.DELIVERYVIARULE, '.') <> COALESCE(NEW.DELIVERYVIARULE, '.'))
               OR(COALESCE(OLD.PRIORITYRULE,'.') <> COALESCE(NEW.PRIORITYRULE, '.'))
               OR(COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
               OR(COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0'))
               OR(COALESCE(old.deliver2projectadress, '0') <> COALESCE(new.deliver2projectadress, '0'))
	       OR((OLD.Processed='Y') AND (OLD.Docstatus ='CO') AND (OLD.c_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24')) AND COALESCE(old.C_PROJECT_ID, '0') <> COALESCE(new.C_PROJECT_ID, '0')) 
	       OR((OLD.Processed='Y') AND (OLD.Docstatus ='CO') AND (OLD.c_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24')) AND COALESCE(old.Salesrep_ID, '0') <> COALESCE(new.Salesrep_ID, '0'))
	    )      )
    THEN
      RAISE EXCEPTION '%', 'Document processed/posted: '||OLD.DOCUMENTNO; --OBTG:-20501--
 
END IF;
    -- Restrictions on PROCESSING
    IF(OLD.Processed='N' AND NEW.Processed='Y') then
       -- If Offer-Propability is obligatory field, do not Process (can be configured..)  On  Doctypes Offer. Proposal , Subscription Proposal
       select c_getconfigoption('offerpropabilitynotnull',NEW.ad_org_id) into v_offprob;
       
       if coalesce(v_offprob,'N')='Y' and (new.estpropability is null or new.name is null) and ad_get_docbasetype(new.c_doctype_id)='SALESOFFER' then
           RAISE EXCEPTION '%', 'Die Auftragswahrscheinlichkeit und der Titel (Name) muss für diesen Dokumententyp angegeben werden. Bitte erst Auftragswahrscheinlichkeit/Name setzen, dann können Sie das Dokument verarbeiten.';
       end if;
	   if coalesce(v_offprob,'N')='Y' and (new.salesrep_id is null or new.name is null or new.name = '') and ad_get_docbasetype(new.c_doctype_id)='SOO' then
           RAISE EXCEPTION '%', 'Der Verkäufer und der Titel (Name) muss für diesen Dokumententyp angegeben werden. Bitte erst Verkäufer/Name setzen, dann können Sie das Dokument verarbeiten.';
       end if;
       -- If Project is obligatory field, do not Process (can be configured..) Does not apply on Offers, Proposals
       select c_getconfigoption('orderprojectnotnull',NEW.ad_org_id) into v_offprob;
       if coalesce(v_offprob,'N')='Y' then
            select count(*) into v_count from c_orderline where c_order_id=new.c_order_id and c_project_id is null and a_asset_id is null;
            if ((new.c_project_id is null and new.a_asset_id is null) or v_count>0)  then
                RAISE EXCEPTION '%', 'Es muß für diesen Dokumententyp ein Projekt angegeben werden. Bitte erst Projekt setzen, dann können Sie das Dokument verarbeiten. Prüfen Sie dabei auch die Zeilen des Auftrages.';
            end if;
       end if;
       -- If DatePromised is obligatory field, do not Update or Insert (can be configured..)
       select c_getconfigoption('datepromisednotnull',NEW.ad_org_id) into v_datepromised;
       -- Applies on Standard Order
       IF coalesce(v_datepromised,'N')='Y' and new.c_doctype_id in ('5D5792C53FBA46E2988653B6DC9FE5B4') THEN
          select count(*) into v_count from c_orderline where c_order_id=new.c_order_id and  DatePromised is null;
          if v_count>0 or new.DatePromised is null then
                RAISE EXCEPTION '%', 'Systemeinstellung: Das voraussichtliche Rechnungsdatum muss für Aufträge angegeben werden. Prüfen Sie dabei auch die Zeilen des Auftrages.';
          end if;
       END IF;
       -- Subscriptions must have either invoicerule 'I' or invoicerule 'D' 
       -- Subscriptions must have a frequence and a start-Date
       if NEW.c_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') and (new.invoicerule not in ('D','I','DI') or new.invoicefrequence is null or new.contractdate is null or new.enddate is null) then
          RAISE EXCEPTION '%', 'Es muß für Abonnements ein Startdatum, ein Enddatum und eine Rechnungsfrequenz angegeben werden. Abonnements müssen die Rechnungsregel "Sofort" oder "Nach Lieferung" haben';
       end if; 
    END IF;  -- Restrictions on PROCESSING
  END IF; -- Updating

 

  IF(TG_OP = 'DELETE') THEN
    IF OLD.Processed='Y' THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  END IF;
  
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;






CREATE OR REPLACE FUNCTION core_voidOrder(p_order_id character varying) returns void
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
Part of Core-Processes
 
***************************************************************************************************/
v_cur             RECORD;
v_status character varying;
v_doctype varchar;
v_salesorder varchar;
v_salesorderline varchar;
v_count numeric;

BEGIN
    -- Checks
    select count(*) into v_count from c_invoiceline l,c_invoice i,c_orderline ol
                    where l.c_invoice_id=i.c_invoice_id and l.c_orderline_id=ol.c_orderline_id
                          and ol.c_order_id=p_order_id
                          and i.docstatus!='VO';
    if v_count>0 then
        RAISE EXCEPTION '%', '@OrderStillhasActiveInvoice@'; 
    end if;
    select count(*) into v_count from m_inoutline l,m_inout m,c_orderline ol
                    where l.m_inout_id=m.m_inout_id and l.c_orderline_id=ol.c_orderline_id
                          and ol.c_order_id=p_order_id
                          and m.docstatus!='VO';
    if v_count>0 then
        RAISE EXCEPTION '%', '@OrderStillhasActiveShipments@'; 
    end if;
    select docstatus,c_doctype_id,orderselfjoin into v_status,v_doctype,v_salesorder from c_order where c_order_id=p_order_id;
    -- Only Closed Orders reserve Inventory
    if v_status in ('CO','CL')  then
      -- Un-Reverse Inventory
      PERFORM core_voidOrderReservations(p_order_id);
    end if;
    -- If a DropShipOrder is Voided, re-set direct delivery in the Sales-Order
    if v_doctype = 'EE19ABBDB5A94C519DAB11003320FC8E' and v_salesorder is not null then
        for v_cur in (select * from c_orderline  where c_order_id=p_order_id) 
        LOOP
            select c_orderline_id into v_salesorderline from c_orderline where c_order_id=v_salesorder and m_product_id=v_cur.m_product_id and qtyordered=v_cur.qtyordered and directship='Y';
            if v_salesorderline is not null then
                update c_orderline set directship='N',qtydelivered=0 where c_orderline_id=v_salesorderline;
            end if;
        END LOOP;
    end if;
    -- Void the Order
    UPDATE C_ORDER
          SET DocStatus='VO',
          DocAction='--',Processing='N',
          Processed='Y',
          Updated=TO_DATE(NOW())
        WHERE C_Order_ID=p_order_id;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



 
CREATE OR REPLACE FUNCTION core_voidOrderReservations(p_order_id  character varying) returns void
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
Part of Core-Processes
 
***************************************************************************************************/
Cur_ResLine RECORD;
v_QtySO NUMERIC; -- Reserved
v_QtyOrderSO NUMERIC;
v_QtyPO NUMERIC; -- Ordered
v_QtyOrderPO NUMERIC;
v_ResultStr character varying;
v_isso character varying;
v_Client_ID character varying;
v_Org_ID character varying;
v_UpdatedBy character varying;
v_doctype character varying;
BEGIN
    -- PO or SO?
    select issotrx,ad_org_id,ad_client_id,updatedby,c_doctype_id into v_isso,v_Org_ID,v_Client_ID,v_UpdatedBy,v_doctype from c_order where c_order_id=p_order_id;
    -- Un-Reverse Inventory
    -- Proposal, Request for Quotation, Quotation, Subscription Order, Subscription Proposal do not Reserve Inventory
    if  ad_get_docbasetype(v_doctype) not in ('NON','POREQUESTOFFER','SALESOFFER') then
            v_ResultStr:='ReserveInventory';
            -- For all lines needing reservation
            FOR Cur_ResLine IN
              (SELECT o.M_Warehouse_ID,
                l.M_Product_ID,
                l.M_AttributeSetInstance_ID,
                l.C_OrderLine_ID,
                -- Target Level = 0 if DirectShip='Y' 
                l.QtyOrdered AS Qty,
                l.QUANTITYORDER,
                l.qtyreserved,
                l.qtydelivered,
                l.C_UOM_ID,
                l.M_PRODUCT_UOM_ID
              FROM C_ORDERLINE l,c_order o,
                M_PRODUCT p
              WHERE l.C_Order_ID=p_order_id and o.c_order_id=l.c_order_id -- Reserve Products (not: services, null products)
                AND l.M_Product_ID=p.M_Product_ID
                AND p.IsStocked='Y'
                AND p.ProductType='I'  FOR UPDATE
              )
            LOOP
              -- Qty corrected for SO/PO
              IF(v_isso='N') THEN
                v_QtySO:=0;
                v_QtyOrderSO:=NULL;
                v_QtyPO:=Cur_ResLine.qtydelivered-Cur_ResLine.qty;
                v_QtyOrderPO:=NULL;
                IF (Cur_ResLine.QtyDelivered=0) THEN
                  v_QtyOrderPO := -Cur_ResLine.QuantityOrder;
                ELSIF Cur_ResLine.M_Product_UOM_ID IS NOT NULL THEN
                  v_QtyOrderPO := -C_Uom_Convert(v_QtyPO, Cur_ResLine.C_UOM_ID, Cur_ResLine.M_Product_UOM_ID, 'Y');
                END IF;
              ELSE
                v_QtySO:=-Cur_ResLine.QtyReserved;
                IF (Cur_ResLine.QtyReserved=Cur_ResLine.Qty) THEN
                  v_QtyOrderSO := -Cur_ResLine.QuantityOrder;
                ELSIF Cur_ResLine.M_Product_UOM_ID IS NOT NULL THEN
                  v_QtyOrderSO := -C_Uom_Convert(v_QtySO, Cur_ResLine.C_UOM_ID, Cur_ResLine.M_Product_UOM_ID, 'Y');
                END IF;
                v_QtyPO:=0;
                v_QtyOrderPO:=NULL;
              END IF;
              --PERFORM M_UPDATE_STORAGE_PENDING(v_Client_ID, v_Org_ID, v_UpdatedBy, Cur_ResLine.M_Product_ID, Cur_ResLine.M_Warehouse_ID, Cur_ResLine.M_AttributeSetInstance_ID, Cur_ResLine.C_UOM_ID, Cur_ResLine.M_PRODUCT_UOM_ID, v_QtySO, v_QtyOrderSO, v_QtyPO, v_QtyOrderPO) ;
            END LOOP;
          -- Set reserved quantity to 0
          UPDATE C_ORDERLINE
          SET QtyReserved = 0
          WHERE c_orderline_id IN (select c_orderline_id
                                   from c_orderline
                                   where c_order_id = p_order_id);
   end if;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;




CREATE OR REPLACE FUNCTION zssi_c_order_trg()
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
Calculate Purchasing Lines COSTs for ITEMS on Purchase (Order)
Only on Purchase Orders (issotrx='N')

NOTICE: Due to Ticket 1405 UOM is set to null in Trigger m_product_po_uom_trg

*****************************************************/

v_cur_line                c_orderline%rowtype;
v_dummy                   numeric;
v_uom                     character varying;
v_iscalcenabled           character varying;
v_poid                    varchar;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  -- Only when really booking the  Order
  if new.processed='Y' and old.processed!='Y' and new.issotrx='N' then
      for v_cur_line in (select * from c_orderline where c_order_id=new.c_order_id)
      LOOP
         IF  v_cur_line.m_product_id is not null then
             select calculated into v_iscalcenabled from m_product where m_product_id=v_cur_line.m_product_id;
             if v_iscalcenabled='Y' then 
                select c_uom_id into v_uom from m_product_uom where m_product_uom_id=v_cur_line.m_product_uom_id;
                select m_product_po_id into v_poid from m_product_po where C_BPARTNER_ID=new.C_BPARTNER_ID and m_product_id=v_cur_line.m_product_id 
                and case when v_cur_line.m_product_uom_id is not null then c_uom_id=v_uom else c_uom_id is null end
                and case when v_cur_line.m_product_po_id is not null then m_product_po_id=v_cur_line.m_product_po_id else 1=1 end;
                
                if v_poid is not null then
                    --update m_product_po set ISCURRENTVENDOR='N' where  m_product_id=v_cur_line.m_product_id;    
                    update m_product_po set UPDATED=now(),UPDATEDBY=new.UPDATEDBY,ISCURRENTVENDOR='Y', C_CURRENCY_ID=new.C_CURRENCY_ID,PRICELIST=v_cur_line.pricelist,
                                        PRICEEFFECTIVE=now(),
				       	PRICELASTPO=  v_cur_line.priceactual,
					QTYLASTPO= CASE WHEN v_cur_line.m_product_uom_id is not null then v_cur_line.quantityorder else v_cur_line.qtyordered END
                          where  m_product_po_id=v_poid;
                else
                  insert into m_product_po(M_PRODUCT_PO_ID,M_PRODUCT_ID, C_BPARTNER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, ISCURRENTVENDOR, C_UOM_ID, C_CURRENCY_ID, PRICELIST, PRICEPO,
                                            PRICEEFFECTIVE, PRICELASTPO, QTYLASTPO)
                              values (get_uuid(),v_cur_line.m_product_id,new.C_BPARTNER_ID,new.AD_CLIENT_ID,new.AD_ORG_ID,'Y',now(),new.CREATEDBY,now(),new.UPDATEDBY,'Y',v_uom,new.C_CURRENCY_ID,v_cur_line.pricelist,v_cur_line.priceactual,
                                            now(),v_cur_line.priceactual,
					    CASE WHEN v_cur_line.m_product_uom_id is not null then v_cur_line.quantityorder else v_cur_line.qtyordered END);
                end if;
             end if;
         END IF;
     END LOOP;
  END IF;
  -- ECommerce Order Status
  if (new.deliverycomplete!=old.deliverycomplete) or (new.docstatus!=old.docstatus)then
    PERFORM zse_order_ecommercestatus(new.c_order_id);
  end if;
  -- Direct Delivery of Material to Project-Adresses
  if (new.processed='Y' and old.processed!='Y' and new.issotrx='N') or (new.processed='N' and old.processed='Y' and new.issotrx='N')then
    PERFORM zspm_dropshipMaterial2projecttask(new.c_order_id,old.processed);
  end if;
RETURN NEW;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_c_order_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION zssi_c_orderfreight_trg()
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
Propagates changes on Freight to the Orderline
Be aware of c_orderline_trg - Prevent endless loop!
*****************************************************/

v_cur_line                c_orderline%rowtype;
v_dummy                   numeric;
v_uom                     character varying;
v_line                    numeric;
v_continue                character varying:='N';
v_plversion               character varying;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;
  if (coalesce(new.freightamt,0)!=0 and not (coalesce(new.m_product_id,'ä')!='ä' and coalesce(new.qty,0)!=0)) then
      RAISE EXCEPTION '%', '@zssi_FreightNeedsProductAndQty@'; --OBTG:-20111--
  END IF;
  IF TG_OP = 'UPDATE' then
    if coalesce(new.freightamt,0)!=coalesce(old.freightamt,0) or coalesce(new.m_product_id,'ä')!=coalesce(old.m_product_id,'ä') or coalesce(new.qty,0)!=coalesce(old.qty,0) 
       or new.freightcostrule!=old.freightcostrule or new.deliveryviarule!=old.deliveryviarule then
      v_continue:='Y';
    end if;
  ELSIF TG_OP = 'INSERT' then
    if coalesce(new.freightamt,0)!=0 and coalesce(new.m_product_id,'ä')!='ä' and coalesce(new.qty,0)!=0 then
      v_continue:='Y';
    end if;
  END IF;
  -- Propagate Tax changes...
  IF TG_OP = 'UPDATE' then
    if coalesce(old.c_tax_id,'')!=coalesce(new.c_tax_id,'') and new.c_tax_id is not null then
        update c_orderline set c_tax_id=new.c_tax_id where c_order_id=new.c_order_id;
    end if;
  end if;
  If TG_OP = 'UPDATE' and v_continue='Y' then
      If old.m_product_id is not null then
         delete from c_orderline where C_ORDER_ID=new.C_ORDER_ID and m_product_id=old.m_product_id;
      end if;
  end if;
  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') and  v_continue='Y' then     
    --select coalesce(max(line),0)+10 into v_line from c_orderline where c_order_id=new.c_order_id;  
    SELECT m_pricelist_version_id  into v_plversion  FROM M_PriceList_version pl  WHERE pl.M_PriceList_ID=new.m_pricelist_id and validfrom <= now() and isactive='Y'  order by validfrom desc; 
    v_line:=9999;
    if new.m_product_id is not null and new.freightcostrule='C'  and coalesce(new.qty,0)>0 and coalesce(new.freightamt,0)>0 then
      insert into c_orderline (
            C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,  UPDATEDBY,
            C_ORDER_ID, LINE, DATEORDERED, M_PRODUCT_ID, c_project_id,
            M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED,
            C_CURRENCY_ID,  PRICEACTUAL, C_TAX_ID,C_BPARTNER_ID, C_BPARTNER_LOCATION_ID, 
            pricelist,pricestd,
            discount)
      values (
            get_uuid(),new.AD_CLIENT_ID,new.AD_ORG_ID,new.CREATEDBY,new.UPDATEDBY,
            new.C_ORDER_ID,v_line,now(),new.m_product_id, new.c_project_id,
            new.m_warehouse_id,(select c_uom_id from m_product where m_product_id=new.m_product_id),new.qty,
            new.c_currency_id,new.freightamt,coalesce(new.c_tax_id,zsfi_GetTax(new.c_bpartner_location_id,new.m_product_id,new.ad_org_id)),new.c_bpartner_id,new.c_bpartner_location_id,
            m_bom_pricelist(new.m_product_id,v_plversion), m_bom_pricestd(new.m_product_id,v_plversion),
            case m_bom_pricestd(new.m_product_id,v_plversion)*100 when 0 then 0 else ROUND((m_bom_pricestd(new.m_product_id,v_plversion) - new.freightamt)/m_bom_pricestd(new.m_product_id,v_plversion)*100,2) end);

    end if;
  end if;
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION c_orderline_trg()
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
 Contributions: Reimplemented-See Invoiceline Trigger
 Fills the Dependent Fields and lines Wiht sums and Prices
 Fixed issue 470
******************************************************************************************************************************/
  --TYPE RECORD IS REFCURSOR;

 v_linegrossamt    NUMERIC;
 v_linenetamt      NUMERIC;
 v_linetaxamt      NUMERIC; 
 v_taxrate         NUMERIC;
 v_newTaxBaseAmt   NUMERIC;
 v_newTaxBaseAmtOneTime   NUMERIC;
 v_reverseTaxAmtOneTime   NUMERIC;
 v_taxAmt          NUMERIC; 
 v_taxAmtOneTime   NUMERIC;
 v_NetAmt          NUMERIC;
 v_GrossAmt        NUMERIC;
 v_NetAmtOneTime   NUMERIC;
 v_GrossAmtOneTime NUMERIC;
 v_exists          NUMERIC;
 v_Processed       CHAR(1);
 v_IsGross         CHAR(1);
 v_currency        VARCHAR(32);
 v_ID              VARCHAR(32);
 v_UOM_ID          VARCHAR(32);
 v_cur_line        RECORD; 
 v_old_tax_id      VARCHAR(32);
 v_IsSOTrx         CHAR(1);
 v_Count           NUMERIC;  
 v_reversetax      CHAR(1);
 v_reverseTaxAmt   NUMERIC;
 v_uom_conversion  NUMERIC;
 v_price           NUMERIC;
 v_qty             NUMERIC;   
 v_doctype         varchar;

BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


IF (TG_OP = 'UPDATE') THEN
    IF NOT(COALESCE(old.M_Product_ID,'0') <> COALESCE(NEW.M_Product_ID,'0')
      OR COALESCE(old.LineNetAmt,0) <> COALESCE(NEW.LineNetAmt,0)
      OR COALESCE(old.LineGrossAmt,0) <> COALESCE(NEW.LineGrossAmt,0)
      OR COALESCE(old.FreightAmt,0) <> COALESCE(NEW.FreightAmt,0)
      OR COALESCE(old.ChargeAmt,0) <> COALESCE(NEW.ChargeAmt,0)
      OR COALESCE(old.C_Tax_ID,'0') <> COALESCE(NEW.C_Tax_ID,'0')
      OR COALESCE(old.C_Uom_ID,'0') <> COALESCE(NEW.C_Uom_ID,'0')
      OR COALESCE(old.qtyOrdered,0) <> COALESCE(NEW.qtyOrdered,0)
      OR COALESCE(old.PriceActual,0) <> COALESCE(NEW.PriceActual,0)
      OR old.pricefluctuationpercent <> NEW.pricefluctuationpercent
      OR new.isonetimeposition!=old.isonetimeposition
      OR new.isoptional!=old.isoptional)
    THEN
       RETURN NEW;
    END IF;
END IF;
 /**
  * Check Product changes = not possible when reservation, invoice or delivery exists
  */
 IF (TG_OP = 'DELETE') THEN
  IF (old.QtyDelivered <> 0 and old.directship='N') THEN
   RAISE EXCEPTION '%', 'Changed Product had Delieveries=' || old.QtyDelivered; --OBTG:-20201--
  ELSIF (old.QtyInvoiced <> 0) THEN
   RAISE EXCEPTION '%', 'Changed Product was Invoiced=' || old.QtyInvoiced; --OBTG:-20202--
  END IF;
 ELSIF (TG_OP = 'UPDATE') THEN
   SELECT issotrx INTO v_IsSOTrx
   FROM c_order
   WHERE c_order_id = old.c_order_id;
   IF (old.M_Product_ID <> NEW.M_Product_ID) THEN
     IF (old.QtyDelivered <> 0 and old.directship='N') THEN
       RAISE EXCEPTION '%', 'Changed Product had Delieveries=' || old.QtyDelivered; --OBTG:-20204--
     ELSIF (old.QtyInvoiced <> 0) THEN
       RAISE EXCEPTION '%', 'Changed Product was Invoiced=' || old.QtyInvoiced; --OBTG:-20205--
     ELSIF (v_IsSOTrx = 'N') THEN
       SELECT count(*) INTO v_Count
       FROM m_inoutline
       WHERE c_orderline_id = old.c_orderline_id;
       IF (v_count > 0) THEN
         RAISE EXCEPTION '%', 'Changed Product has good receipts'; --OBTG:-20206--
       END IF;
     END IF;
   END IF;
 END IF;

 -- Get ID
 IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
     if new.qtyreserved is null then new.qtyreserved:=0; end if;
     if new.priceactual=0 and new.pricestd=0 then  new.discount:=0; end if;
     select c_currency_id into v_currency from c_order where c_order_id=new.c_order_id;
     if new.c_currency_id!=v_currency then
         RAISE EXCEPTION '%', '@zssi_OnlyOneCurrencyInDocument@';
     end if;
     IF (NEW.M_PRODUCT_ID IS NOT NULL) THEN
       SELECT C_UOM_ID INTO v_UOM_ID FROM M_PRODUCT WHERE M_PRODUCT_ID=NEW.M_PRODUCT_ID;
       IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
         RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
       END IF;
     END IF;
  v_ID := new.C_Order_ID;
 ELSE
  v_ID := old.C_Order_ID;
 END IF;

 SELECT processed,c_doctypetarget_id
   INTO v_Processed,v_doctype
 FROM C_Order
 WHERE C_Order_ID=v_ID;


  /**************************************************************************
   * Calculate Tax, etc.
   * Rental Orders can be extended....
   */
IF(v_Processed='N') or (v_doctype='CC33ECC618F44A6A8F7FEFBEA942739E') THEN
    -- Actions on Delete: HEADEER and TAX: Subtract old Amounts on delete
    IF (TG_OP = 'DELETE') THEN
       if old.isoptional='N' then
          select c_currency_id into v_currency from c_order where c_order_id=old.c_order_id;
          select IsTaxIncluded into v_IsGross from m_pricelist where m_pricelist_id=(select m_pricelist_id from c_order where c_order_id=old.c_order_id);
          for v_cur_line in (select distinct(c_tax_id) from c_orderline where c_order_id=old.c_order_id and c_orderline_id!=old.c_orderline_id
                             UNION select old.c_tax_id as c_tax_id from dual)
          LOOP
              select case v_IsGross when 'N' then coalesce(sum(linenetamt),0) else coalesce(sum(linegrossamt),0) end into v_newTaxBaseAmt
                      from c_orderline 
                      where c_order_id=old.c_order_id and c_orderline_id!=old.c_orderline_id and c_tax_id=v_cur_line.c_tax_id and c_orderline.isonetimeposition='N';
              -- One Time Positions
              select case v_IsGross when 'N' then coalesce(sum(linenetamt),0) else coalesce(sum(linegrossamt),0) end into v_newTaxBaseAmtOneTime
                      from c_orderline 
                      where c_order_id=old.c_order_id and c_orderline_id!=old.c_orderline_id and c_tax_id=v_cur_line.c_tax_id and c_orderline.isonetimeposition='Y';
              -- Recalculate the TAX
              select rate,reversecharge into v_taxrate,v_reversetax from c_tax where c_tax_id=v_cur_line.c_tax_id; 
              v_reverseTaxAmt:=0;
              v_reverseTaxAmtOneTime:=0;
              if v_taxrate!=0 then
                   if v_IsGross='N' then
                      v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt*(v_taxrate/100),v_currency,NULL);
                      v_taxAmtOneTime:=C_Currency_Round(v_newTaxBaseAmtOneTime*(v_taxrate/100),v_currency,NULL);
                   else 
                      v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt-v_newTaxBaseAmt/(1+(v_taxrate/100)),v_currency,NULL);
                      v_newTaxBaseAmt:=v_newTaxBaseAmt-v_TaxAmt;
                      v_taxAmtOneTime:=C_Currency_Round(v_newTaxBaseAmtOneTime/(1+(v_taxrate/100)),v_currency,NULL);
                      v_newTaxBaseAmtOneTime:=v_newTaxBaseAmt-v_taxAmtOneTime;
                   end if;
                   if v_reversetax='Y' then
                        v_reverseTaxAmt:=v_TaxAmt;
                        v_reverseTaxAmtOneTime:=v_taxAmtOneTime;
                        v_TaxAmt:=0;
                        v_TaxAmtOneTime:=0;
                   end if;
              else
                   v_TaxAmt=0;
                   v_TaxAmtOneTime:=0;
              end if;
              IF (v_newTaxBaseAmt!=0) THEN
                  UPDATE  C_ORDERTAX
                    SET TaxBaseAmt = v_newTaxBaseAmt, TaxAmt=v_taxAmt, reversetaxamt=v_reverseTaxAmt
                  WHERE c_order_id = OLD.c_order_id
                      AND C_Tax_ID = v_cur_line.C_Tax_ID and isonetimeposition='N';
              ELSE
                  DELETE from C_ORDERTAX where c_order_id = OLD.c_order_id
                      AND C_Tax_ID = v_cur_line.C_Tax_ID and isonetimeposition='N';
              END IF;
              IF (v_newTaxBaseAmtOneTime!=0) THEN
                  UPDATE  C_ORDERTAX
                    SET TaxBaseAmt = v_newTaxBaseAmt, TaxAmt=v_taxAmt, reversetaxamt=v_reverseTaxAmt
                  WHERE c_order_id = OLD.c_order_id
                      AND C_Tax_ID = v_cur_line.C_Tax_ID and isonetimeposition='Y';
              ELSE
                  DELETE from C_ORDERTAX where c_order_id = OLD.c_order_id
                      AND C_Tax_ID = v_cur_line.C_Tax_ID and isonetimeposition='Y';
              END IF;
           END LOOP;
           -- Building SUMS for Header
           if v_IsGross='N' then 
                  select  coalesce(sum(linenetamt),0) into v_NetAmt from c_orderline where c_order_id=old.c_order_id and c_orderline_id!=old.c_orderline_id and isonetimeposition='N';
                  select  coalesce(sum(linenetamt),0) into v_NetAmtOneTime from c_orderline where c_order_id=old.c_order_id and c_orderline_id!=old.c_orderline_id and isonetimeposition='Y';                 
                  select coalesce(sum(taxamt),0) into v_GrossAmt from c_ordertax  where c_order_id=old.c_order_id and isonetimeposition='N';
                  select coalesce(sum(taxamt),0) into v_GrossAmtOneTime from c_ordertax  where c_order_id=old.c_order_id and isonetimeposition='Y';
                  v_GrossAmt:=v_GrossAmt+v_NetAmt;
                  v_GrossAmtOneTime:=v_GrossAmtOneTime+v_NetAmtOneTime;
           else
                  select  coalesce(sum(linegrossamt),0) into v_GrossAmt from c_orderline where c_order_id=old.c_order_id and c_orderline_id!=old.c_orderline_id  and isonetimeposition='N';
                  select  coalesce(sum(linegrossamt),0) into v_GrossAmtOneTime from c_orderline where c_order_id=old.c_order_id and c_orderline_id!=old.c_orderline_id and isonetimeposition='Y'; 
                  select coalesce(sum(taxamt),0) into v_NetAmt from c_ordertax  where c_order_id=old.c_order_id and isonetimeposition='N';
                  select coalesce(sum(taxamt),0) into v_NetAmtOneTime from c_ordertax  where c_order_id=old.c_order_id and isonetimeposition='Y';
                  v_NetAmt:=v_GrossAmt-v_NetAmt;
                  v_NetAmtOneTime:=v_GrossAmtOneTime-v_NetAmtOneTime;
           end if;
       end if;
    END IF; -- DELETE
    -- Actions on Insert or Update
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        select c_currency_id into v_currency from c_order where c_order_id=new.c_order_id;
        -- CALCULATE THE ACTUAL LINE
        -- If it Is Grossproce, we see in the Pricelist
        select IsTaxIncluded into v_IsGross from m_pricelist where m_pricelist_id=(select m_pricelist_id from c_order where c_order_id=new.c_order_id);
        new.isgrossprice:=v_IsGross;
        -- On LINE-LEVEL: Set linenetamt, linegrossamt, linetaxamt
        If new.qtyordered!=0 and new.priceactual!=0 and new.c_tax_id is not null and new.isoptional='N' THEN
                select rate,reversecharge into v_taxrate,v_reversetax from c_tax where c_tax_id=new.c_tax_id;
                --If we order in Secondary OUM, Price applies to OrderQTY not to qtyOrdered
                -- Be aware of 2nd UOM
                if new.m_product_uom_id is not null and coalesce(new.quantityorder,0)!=0 then
                   v_qty:=new.quantityorder;
                else
                   v_qty:=new.qtyordered;
                end if;   
                
                if v_IsGross='Y' then
                    v_linegrossamt:=C_Currency_Round(v_qty*new.priceactual,v_currency,NULL);
                    v_linenetamt:=0;
                else
                    v_linenetamt:=C_Currency_Round(v_qty*new.priceactual,v_currency,NULL);
                    v_linegrossamt:=0;
                end if;
                -- ADD Price Fluctuation Overhead
                new.pricefluctuation:=C_Currency_Round(v_linenetamt*(new.pricefluctuationpercent/100),v_currency,NULL);
                new.linenetamt:=v_linenetamt + new.pricefluctuation;
                new.linegrossamt:=v_linegrossamt;
                --new.linetaxamt:=C_Currency_Round(new.linegrossamt-new.linenetamt,v_currency,NULL);
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
        for v_cur_line in (select distinct(c_tax_id) as c_tax_id from c_orderline where c_order_id=new.c_order_id and c_orderline_id!=new.c_orderline_id 
                                  UNION select new.c_tax_id as c_tax_id from dual union select v_old_tax_id as c_tax_id from dual)
        LOOP
            select case v_IsGross when 'N' then coalesce(sum(linenetamt),0) else coalesce(sum(linegrossamt),0) end into v_newTaxBaseAmt
                      from c_orderline 
                      where c_order_id=new.c_order_id and c_orderline_id!=new.c_orderline_id and c_tax_id=v_cur_line.c_tax_id and c_orderline.isonetimeposition='N' and c_orderline.isoptional='N';
              -- One Time Positions
              select case v_IsGross when 'N' then coalesce(sum(linenetamt),0) else coalesce(sum(linegrossamt),0) end into v_newTaxBaseAmtOneTime
                      from c_orderline 
                      where c_order_id=new.c_order_id and c_orderline_id!=new.c_orderline_id and c_tax_id=v_cur_line.c_tax_id and c_orderline.isonetimeposition='Y'  and c_orderline.isoptional='N';
            -- recalculate TAX
            if v_cur_line.c_tax_id=new.c_tax_id then
                  if v_IsGross='Y' then if new.isonetimeposition='Y' then v_newTaxBaseAmtOneTime:= v_newTaxBaseAmtOneTime+new.linegrossamt; else v_newTaxBaseAmt:= v_newTaxBaseAmt+new.linegrossamt; end if; end if;
                  if v_IsGross='N' then if new.isonetimeposition='Y' then v_newTaxBaseAmtOneTime:= v_newTaxBaseAmtOneTime+new.linenetamt; else v_newTaxBaseAmt:= v_newTaxBaseAmt+new.linenetamt; end if; end if;
            end if;
            -- Recalculate the TAX
            select rate,reversecharge into v_taxrate,v_reversetax from c_tax where c_tax_id=v_cur_line.c_tax_id;
            v_reverseTaxAmt:=0;
            v_reverseTaxAmtOneTime:=0;
            if v_taxrate!=0 then
                     if v_IsGross='N' then 
                        v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt*(v_taxrate/100),v_currency,NULL);       
                        v_TaxAmtOneTime:=C_Currency_Round(v_newTaxBaseAmtOneTime*(v_taxrate/100),v_currency,NULL);                  
                     else

                        v_TaxAmt:=C_Currency_Round(v_newTaxBaseAmt-v_newTaxBaseAmt/(1+(v_taxrate/100)),v_currency,NULL);
                        v_TaxAmtOneTime:=C_Currency_Round(v_newTaxBaseAmtOneTime*(v_taxrate/100),v_currency,NULL);  
                        v_newTaxBaseAmt:=v_newTaxBaseAmt-v_TaxAmt;
                        v_newTaxBaseAmtOneTime:=v_newTaxBaseAmtOneTime-v_TaxAmtOneTime;

                     end if;
                     if v_reversetax='Y' then
                        v_reverseTaxAmt:=v_TaxAmt;
                        v_reverseTaxAmtOneTime:=v_taxAmtOneTime;
                        v_TaxAmt:=0;
                        v_TaxAmtOneTime:=0;
                     end if;
            else
                  v_TaxAmt=0;
                  v_TaxAmtOneTime:=0;
            end if;
                       
              -- Are there TAX-Lines?
              SELECT  count(*) into v_exists
                      FROM  C_ORDERTAX
                      WHERE c_order_id = NEW.c_order_id
                      AND C_Tax_ID = v_cur_line.C_Tax_ID and isonetimeposition='N';
              -- Update, If TAXline Exists
              IF (v_exists>0) and v_newTaxBaseAmt!=0 THEN                     
                       UPDATE  C_ORDERTAX
                               SET TaxBaseAmt = v_newTaxBaseAmt, TaxAmt= v_TaxAmt, reversetaxamt=v_reverseTaxAmt
                               WHERE C_order_ID=NEW.C_order_ID
                               AND C_Tax_ID=v_cur_line.C_Tax_ID;
              -- Delete if No Tax is there anymore
              ELSIF  (v_exists>0) and v_newTaxBaseAmt=0 THEN   
                       DELETE from C_ORDERTAX where C_order_ID = NEW.c_order_id
                              AND C_Tax_ID = v_cur_line.C_Tax_ID; 
              -- Insert new TAX Line
              ELSE
                        INSERT INTO C_ORDERTAX
                               (C_orderTax_ID, AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated, UpdatedBy,
                                c_order_id, C_Tax_ID, TaxBaseAmt, TaxAmt,reverseTaxAmt,isonetimeposition)
                        VALUES
                               (get_uuid(), NEW.AD_Client_ID, NEW.AD_Org_ID, 'Y', TO_DATE(NOW()), NEW.UpdatedBy, TO_DATE(NOW()), NEW.UpdatedBy,
                                NEW.c_order_id, v_cur_line.C_Tax_ID,v_newTaxBaseAmt , v_TaxAmt,v_reverseTaxAmt,'N');
              END IF;
              -- One Time Positions
              -- Are there TAX-Lines?
              SELECT  count(*) into v_exists
                      FROM  C_ORDERTAX
                      WHERE c_order_id = NEW.c_order_id
                      AND C_Tax_ID = v_cur_line.C_Tax_ID and isonetimeposition='Y';
              -- Update, If TAXline Exists
              IF (v_exists>0) and v_newTaxBaseAmtOneTime>0 THEN                     
                       UPDATE  C_ORDERTAX
                               SET TaxBaseAmt = v_newTaxBaseAmtOneTime, TaxAmt= v_TaxAmtOneTime, reversetaxamt=v_reverseTaxAmtOneTime
                               WHERE C_order_ID=NEW.C_order_ID
                               AND C_Tax_ID=v_cur_line.C_Tax_ID and isonetimeposition='Y';
              -- Delete if No Tax is there anymore
              ELSIF  (v_exists>0) and v_newTaxBaseAmtOneTime=0 THEN   
                       DELETE from C_ORDERTAX where C_order_ID = NEW.c_order_id
                              AND C_Tax_ID = v_cur_line.C_Tax_ID and isonetimeposition='Y'; 
              -- Insert new TAX Line
              ELSIF  v_exists=0 and v_newTaxBaseAmtOneTime!=0 then
                        INSERT INTO C_ORDERTAX
                               (C_orderTax_ID, AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated, UpdatedBy,
                                c_order_id, C_Tax_ID, TaxBaseAmt, TaxAmt,reverseTaxAmt,isonetimeposition)
                        VALUES
                               (get_uuid(), NEW.AD_Client_ID, NEW.AD_Org_ID, 'Y', TO_DATE(NOW()), NEW.UpdatedBy, TO_DATE(NOW()), NEW.UpdatedBy,
                                NEW.c_order_id, v_cur_line.C_Tax_ID,v_newTaxBaseAmtOneTime , v_TaxAmtOneTime,v_reverseTaxAmtOneTime,'Y');
              END IF;
        END LOOP;
        -- Building SUMS for Header
        if v_IsGross='N' then 
            select  coalesce(sum(linenetamt),0) into v_NetAmt from c_orderline where c_order_id=new.c_order_id and c_orderline_id!=new.c_orderline_id and isonetimeposition='N'  and isoptional='N';
            select  coalesce(sum(linenetamt),0) into v_NetAmtOneTime from c_orderline where c_order_id=new.c_order_id and c_orderline_id!=new.c_orderline_id and isonetimeposition='Y' and isoptional='N';
            if new.isoptional='N' then
                if new.isonetimeposition='N'   then v_NetAmt:=v_NetAmt+new.linenetamt; else v_NetAmtOneTime:=v_NetAmtOneTime+new.linenetamt; end if;
            end if;
            select coalesce(sum(taxamt),0) into v_GrossAmt from c_ordertax  where c_order_id=new.c_order_id and isonetimeposition='N';
            select coalesce(sum(taxamt),0) into v_GrossAmtOneTime from c_ordertax  where c_order_id=new.c_order_id and isonetimeposition='Y';
            v_GrossAmt:=v_GrossAmt+v_NetAmt;
            v_GrossAmtOneTime:=v_GrossAmtOneTime+v_NetAmtOneTime;
        else
            select  coalesce(sum(linegrossamt),0) into v_GrossAmt from c_orderline where c_order_id=new.c_order_id and c_orderline_id!=new.c_orderline_id  and isonetimeposition='N' and isoptional='N';
            select  coalesce(sum(linegrossamt),0) into v_GrossAmtOneTime from c_orderline where c_order_id=new.c_order_id and c_orderline_id!=new.c_orderline_id and isonetimeposition='Y' and isoptional='N'; 
            if new.isoptional='N' then
                if new.isonetimeposition='N' then v_GrossAmt:=v_GrossAmt+new.linegrossamt; else v_GrossAmtOneTime:=v_GrossAmtOneTime+new.linegrossamt; end if;
            end if;
            select coalesce(sum(taxamt),0) into v_NetAmt from c_ordertax  where c_order_id=new.c_order_id and isonetimeposition='N';
            select coalesce(sum(taxamt),0) into v_NetAmtOneTime from c_ordertax  where c_order_id=new.c_order_id and isonetimeposition='Y';
            v_NetAmt:=v_GrossAmt-v_NetAmt;
            v_NetAmtOneTime:=v_GrossAmtOneTime-v_NetAmtOneTime;
        end if;
    -- Insert or Update    
    END IF;
    --perform logg('Current Header: '||new.c_invoice_id||' ,TNET: '||to_char(v_t,'999D9999999999')||' ,TGROS: '||to_char(v_g,'999D9999999999'));
    -- Update Header (in case of delete optional position, v_NetAmt is null...)
    if v_NetAmt  is not null then
        UPDATE  C_ORDER
        SET TotalLines = v_NetAmt,
        GrandTotal = v_GrossAmt,
        totallinesonetime = v_NetAmtOneTime,
        grandtotalonetime = v_GrossAmtOneTime
        WHERE c_order_id = v_ID;
    end if;
-- Processed
END IF;
IF TG_OP = 'DELETE' THEN
	update c_orderline set ref_orderline_id = null where old.c_orderline_id = ref_orderline_id;
	RETURN OLD; 
ELSE 
	RETURN NEW; 
END IF; 
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

  


CREATE OR REPLACE FUNCTION c_ordertax_trg() RETURNS trigger LANGUAGE plpgsql AS $_$ DECLARE 

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
    * Contributor(s): Openbravo SL, OpenZ, 2016
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L., OpenZ, Inh. S. Zimmermann
    *
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * $Id: C_OrderTax_Trg.sql,v 1.3 2003/01/31 03:03:04 jjanke Exp $
    ***
    * Title: ReadOnly Check
    * Description:
    ************************************************************************/
  v_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_RO         NUMERIC;
  v_Processed  VARCHAR(60) ;
  v_C_ORDER_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  v_Docaction VARCHAR(60) ;
  v_doctype VARCHAR;  
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF TG_OP = 'INSERT' THEN
    v_C_ORDER_ID:=new.C_ORDER_ID;
  ELSE
    v_C_ORDER_ID:=old.C_ORDER_ID;
  END IF;
  SELECT PROCESSED,DOCACTION,c_doctypetarget_id
  INTO v_Processed,v_Docaction,v_doctype
  FROM C_ORDER  WHERE C_ORDER_ID=v_C_ORDER_ID;
  IF TG_OP = 'UPDATE' THEN
    IF(v_Processed='Y' AND v_Docaction <> 'CL'
    AND ((COALESCE(old.TAXBASEAMT, 0) <> COALESCE(new.TAXBASEAMT, 0)  and v_doctype!='CC33ECC618F44A6A8F7FEFBEA942739E') -- Rental Orders can be extended...
    OR((COALESCE(old.TAXAMT, 0) <> COALESCE(new.TAXAMT, 0))   and v_doctype!='CC33ECC618F44A6A8F7FEFBEA942739E')
    OR(COALESCE(old.C_TAX_ID, '0') <> COALESCE(new.C_TAX_ID, '0'))
    OR(COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
    OR(COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0')))) THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  END IF;
  NULL;
  IF((TG_OP = 'DELETE' OR TG_OP = 'INSERT') AND v_Processed='Y' AND v_Docaction <> 'CL') THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;


CREATE OR REPLACE FUNCTION c_changesubsriptionorder(p_Record_ID character varying,p_User character varying)
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
Part of Order Process
     Generates a Subscription Order Change (SO).
*****************************************************/

  v_Message character varying:='ERROR'; 
  v_COrder_ID character varying; 
  v_cur_line  c_orderline%rowtype;
  v_curtm zssi_order_textmodule%rowtype;
  v_cur RECORD;
  v_DocumentNo varchar;
BEGIN 
    select c_subscriptionofferchangeexisting(p_Record_ID,'N') into v_COrder_ID;
    if (select docstatus from c_order where c_order_id=v_COrder_ID)!='CO' or v_COrder_ID ='FALSE' or p_Record_ID is null then
        return 'ERROR: Existing Subscription Order has to be in status active';
    end if;
    update c_order set subscriptionchangedate=(select subscriptionchangedate from c_order o where o.c_order_id=p_Record_ID) where c_order.c_order_id = v_COrder_ID;
    PERFORM c_order_post1(null,v_COrder_ID);
    update c_order set updatedby=p_User, description=a.description,salesrep_id=a.salesrep_id,billto_id=a.billto_id,c_bpartner_location_id=a.c_bpartner_location_id,
                       updated=now(),poreference=a.poreference,paymentrule=a.paymentrule,c_paymentterm_id=a.c_paymentterm_id,invoicerule=a.invoicerule,deliveryrule=a.deliveryrule,
                       freightcostrule=a.freightcostrule,freightamt=a.freightamt,deliveryviarule=a.deliveryviarule,m_shipper_id=a.m_shipper_id,m_warehouse_id=a.m_warehouse_id,
                       m_pricelist_id=a.m_pricelist_id,istaxincluded=a.istaxincluded,c_currency_id=a.c_currency_id,c_project_id=a.c_project_id,ad_user_id=a.ad_user_id,
                       c_incoterms_id=a.c_incoterms_id,incotermsdescription=a.incotermsdescription,c_projecttask_id=a.c_projecttask_id,orderselfjoin=p_Record_ID,
                       enddate=a.enddate,yearly_month=a.yearly_month,weekly_day=a.weekly_day,monthly_day=a.monthly_day,quarterly_month=a.quarterly_month,
                       isinvoiceafterfirstcycle=a.isinvoiceafterfirstcycle,subscriptionchangedate=a.subscriptionchangedate,subsrdailyratebilling=a.subsrdailyratebilling,
                       docaction='CO'
                       from (select * from c_order o where o.c_order_id=p_Record_ID) a where c_order.c_order_id = v_COrder_ID;
    delete from c_orderline where c_order_id=v_COrder_ID and not exists (select 0 from c_orderline aol where aol.line=c_orderline.line and aol.c_order_id=p_Record_ID);
    for v_cur_line in (select * from c_orderline where c_order_id=p_Record_ID)
    LOOP
        if (select count(*) from c_orderline where c_order_id=v_COrder_ID and line=v_cur_line.line)=0 then
            v_cur_line.c_order_id:=v_COrder_ID;
            v_cur_line.c_orderline_id:=get_uuid();
            v_cur_line.createdby:=p_User;
            v_cur_line.updatedby:=p_User;
            insert into c_orderline select v_cur_line.*;
        else
            update c_orderline set updatedby=p_User, updated=now(),description=v_cur_line.description,m_product_id=v_cur_line.m_product_id,c_uom_id=v_cur_line.c_uom_id,
                       qtyordered=v_cur_line.qtyordered,pricelist=v_cur_line.pricelist,
                       priceactual=v_cur_line.priceactual,pricelimit=v_cur_line.pricelimit,discount=v_cur_line.discount,c_tax_id=v_cur_line.c_tax_id,m_attributesetinstance_id=v_cur_line.m_attributesetinstance_id,
                       isdescription=v_cur_line.isdescription,quantityorder=v_cur_line.quantityorder,m_product_uom_id=v_cur_line.m_product_uom_id,pricestd=v_cur_line.pricestd,cancelpricead=v_cur_line.cancelpricead ,
                       c_project_id=v_cur_line.c_project_id,c_projecttask_id=v_cur_line.c_projecttask_id,a_asset_id=v_cur_line.a_asset_id,issummaryitem=v_cur_line.issummaryitem,isonetimeposition=v_cur_line.isonetimeposition,
                       textposition=v_cur_line.textposition,datepromised=v_cur_line.datepromised,scheddeliverydate=v_cur_line.scheddeliverydate
            where c_orderline.c_order_id = v_COrder_ID and c_orderline.line=v_cur_line.line;
        end if;
    END LOOP;
    delete from zssi_order_textmodule where c_order_id=v_COrder_ID;
    for v_curtm in (select * from zssi_order_textmodule where c_order_id=p_Record_ID)
    LOOP
        v_curtm.c_order_id:=v_COrder_ID;
        v_curtm.zssi_order_textmodule_id:=get_uuid();
        v_curtm.createdby:=p_User;
        v_curtm.updatedby:=p_User;
        insert into zssi_order_textmodule select v_curtm.*;
    END LOOP;
    PERFORM c_order_post1(null,v_COrder_ID);
    select documentno into v_DocumentNo from c_order where c_order_id=v_COrder_ID;
    v_Message:=zsse_htmldirectlink('../SalesOrder/Header_Relation.html','document.frmMain.inpcOrderId',v_COrder_ID,v_DocumentNo);
    -- Mark all Variants of this Offer as closed.
    PERFORM c_closeallrelatedoffers(p_Record_ID,p_User);
    -- Mark the Accepted Variant of the Proposal - the link to the ORDER
     update c_order set proposalstatus='AC',docstatus='CL' where c_order_id=p_Record_ID;
    RETURN v_Message; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION c_generateorderfromoffer_userexit(v_order_id varchar, v_Record_ID varchar)
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
User-Exit for c_generateorderfromoffer
**/
DECLARE
v_return varchar:='';
BEGIN
RETURN v_return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select zsse_dropfunction('c_generateorderfromoffer');
CREATE OR REPLACE FUNCTION c_generateorderfromoffer(p_Record_ID character varying,p_targetDocType varchar,p_User character varying)
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
Part of Order Process
     Generates Orders (SO or PO) from Offer or Quotation's
*****************************************************/

  v_Message character varying:='ERROR'; 
  v_COrder_ID character varying; 
  v_Client_ID character varying; 
  v_Org_ID character varying; 
  v_DocumentNo character varying; 
  v_CDocTypeID character varying; 
  v_IssoTrx character varying;
  v_dummy character varying;
  v_proposaldoctype  character varying;
  v_seq varchar;
  v_cur RECORD;
BEGIN 
    -- Create Order Header
    select get_uuid() into v_COrder_ID;
    select issotrx,ad_client_id,ad_org_id,c_doctype_id into v_IssoTrx,v_Client_ID,v_Org_ID,v_proposaldoctype from c_order where c_order_id=p_Record_ID;
    select s.name into v_seq from ad_sequence s,c_doctype d where s.ad_sequence_id=d.docnosequence_id and d.c_doctype_id=p_targetDocType;
    -- Create the Order
    SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc(v_seq, v_Org_ID, 'Y') ;
    v_CDocTypeID :=p_targetDocType;
    -- Always exactly 1 Record, but more efficient code to do it like this...
    for v_cur in (select * from c_order where c_order_id=p_Record_ID)
    LOOP
        v_Client_ID:=v_cur.AD_CLIENT_ID;
        v_Org_ID:=v_cur.AD_ORG_ID;
        INSERT INTO C_Order
              (C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATEDBY,UPDATEDBY,
              ISSOTRX, DOCUMENTNO, DOCSTATUS, DOCACTION, PROCESSING,
              C_DOCTYPE_ID,C_DOCTYPETARGET_ID, DESCRIPTION,deliverynotes,
              DATEORDERED, DATEACCT, C_BPARTNER_ID, BILLTO_ID,
              C_BPARTNER_LOCATION_ID, C_CURRENCY_ID, PAYMENTRULE, C_PAYMENTTERM_ID,
              INVOICERULE, DELIVERYRULE, FREIGHTCOSTRULE, DELIVERYVIARULE,
              PRIORITYRULE,  M_WAREHOUSE_ID, M_PRICELIST_ID, ISTAXINCLUDED, DATEPROMISED, poreference,c_project_id,a_asset_id,ad_user_id,salesrep_id,name,bpzipcode,c_incoterms_id,delivery_location_id,weight,weight_uom,
              m_shipper_id,m_product_id,qty,freightamt,invoicefrequence,enddate,contractdate,
              yearly_month,weekly_day,monthly_day,quarterly_month,isinvoiceafterfirstcycle,internalnote,c_projecttask_id,scheddeliverydate,deliverylocationtext,
              discountcouponcode,c_salesregion_id,subsrdailyratebilling,c_tax_id,orderselfjoin)
            VALUES
              (v_COrder_ID, v_Client_ID, v_Org_ID,v_cur.isactive,p_User, p_User,
              v_cur.issotrx, v_DocumentNo,  'DR', 'CO','N',
              v_CDocTypeID, v_CDocTypeID, 
              v_cur.Description,v_cur.deliverynotes,trunc(now()), trunc(now()), v_cur.C_BPARTNER_ID, v_cur.BILLTO_ID,
              v_cur.C_BPARTNER_LOCATION_ID, v_cur.C_CURRENCY_ID, v_cur.PAYMENTRULE, v_cur.C_PAYMENTTERM_ID,
              v_cur.INVOICERULE, v_cur.DELIVERYRULE, v_cur.FREIGHTCOSTRULE, v_cur.DELIVERYVIARULE,
              v_cur.PRIORITYRULE,  v_cur.M_WAREHOUSE_ID, v_cur.M_PRICELIST_ID, v_cur.ISTAXINCLUDED, v_cur.DATEPROMISED,v_cur.poreference,
              v_cur.c_project_id,v_cur.a_asset_id,v_cur.ad_user_id,v_cur.salesrep_id,v_cur.name,v_cur.bpzipcode,v_cur.c_incoterms_id,v_cur.delivery_location_id,v_cur.weight,v_cur.weight_uom,
              v_cur.m_shipper_id,v_cur.m_product_id,v_cur.qty,v_cur.freightamt,v_cur.invoicefrequence,v_cur.enddate,v_cur.contractdate,
              v_cur.yearly_month,v_cur.weekly_day,v_cur.monthly_day,v_cur.quarterly_month,v_cur.isinvoiceafterfirstcycle,v_cur.internalnote,v_cur.c_projecttask_id,v_cur.scheddeliverydate,
              v_cur.deliverylocationtext,v_cur.discountcouponcode,v_cur.c_salesregion_id,v_cur.subsrdailyratebilling,v_cur.c_tax_id,p_Record_ID);
              -- Refs to Purchase Documents are switched to new Document
              if (select count(*) from c_order where orderselfjoin=v_cur.c_order_id and issotrx='N')>0 then
                update c_order set orderselfjoin=v_COrder_ID where orderselfjoin=v_cur.c_order_id and issotrx='N';
              end if;
    END LOOP;
    -- Create Order Lines
    v_dummy:= c_copyorderlines(p_Record_ID,v_COrder_ID,p_User);
    update c_orderline set isoptional='N' where c_order_id=v_COrder_ID and isoptional='Y';
    v_dummy:= c_copyordertextmodules_offer2order(p_Record_ID,v_COrder_ID,p_User);
    v_Message:=zsse_htmldirectlink('../SalesOrder/Header_Relation.html','document.frmMain.inpcOrderId',v_COrder_ID,v_DocumentNo);
    -- Mark all Variants of this Offer as closed.
    PERFORM c_closeallrelatedoffers(p_Record_ID,p_User);
    -- Mark the Accepted Variant of the Proposal 
    update c_order set generatetemplate='Y',DocStatus='CL',processed='Y',Processing='N',proposalstatus='AC',Updated=now(),updatedby=p_User 
                       where c_order_id=p_Record_ID;
    PERFORM c_generateorderfromoffer_userexit(v_COrder_ID, p_Record_ID);
    RETURN v_Message; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


  
CREATE OR REPLACE FUNCTION c_closeallrelatedoffers(p_order_id character varying, p_user  character varying)
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
Part of Order Process
     Close Proposals
*****************************************************/
  v_parentproposal character varying;
  v_relevantoffer   character varying;
  v_cur record;
BEGIN 
    -- nach unten
    for v_cur in (select c_order_id from c_order where orderselfjoin=p_order_id and DocStatus!='CL' and createdbycopy='N' and
                    ad_get_docbasetype(c_doctype_id) in ('POREQUESTOFFER','SALESOFFER'))
    LOOP
        update c_order set generatetemplate='Y',DocStatus='CL',processed='Y',Processing='N',proposalstatus='CL',Updated=now(),updatedby=p_user 
        where c_order_id=v_cur.c_order_id and DocStatus!='VO';     
        PERFORM c_closeallrelatedoffers(v_cur.c_order_id,p_user);
    END LOOP;
    -- nach oben
    select o.orderselfjoin into v_relevantoffer from c_order o, c_order r where r.c_order_id=o.orderselfjoin and o.c_order_id=p_order_id  and r.DocStatus!='CL'  and
                   o.createdbycopy='N' and r.createdbycopy='N' and ad_get_docbasetype(r.c_doctype_id) in ('POREQUESTOFFER','SALESOFFER');   
    if v_relevantoffer is not null then
        update c_order set generatetemplate='Y',DocStatus='CL',processed='Y',Processing='N',proposalstatus='CL',Updated=now(),updatedby=p_user 
                       where c_order_id=v_relevantoffer and DocStatus!='VO';  
        PERFORM  c_closeallrelatedoffers(v_relevantoffer,p_user);
    end if;
    RETURN ''; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;  
  
CREATE OR REPLACE FUNCTION c_markofferaslost(p_order_id character varying,lostreason  character varying, lostreasontext character varying, p_user  character varying)
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
Part of Order Process
     Marks Proposals as LOST
*****************************************************/
  v_parentproposal character varying;
  v_relevantoffer   character varying;
  v_cur record;
BEGIN 
    -- Ausgangspunkt
    update c_order set generatetemplate='Y',DocStatus='CL',processed='Y',Processing='N',proposalstatus='LO',Updated=now(),updatedby=p_user,
                       lostproposalfixedreason=lostreason,lostproposalreason=lostreasontext where c_order_id=p_order_id;      
    -- nach unten
    for v_cur in (select c_order_id from c_order where orderselfjoin=p_order_id and DocStatus!='CL' and
                    ad_get_docbasetype(c_doctype_id) in ('POREQUESTOFFER','SALESOFFER'))
    LOOP
        update c_order set generatetemplate='Y',DocStatus='CL',processed='Y',Processing='N',proposalstatus='LO',Updated=now(),updatedby=p_user,
                       lostproposalfixedreason=lostreason,lostproposalreason=lostreasontext where c_order_id=v_cur.c_order_id and DocStatus!='VO';     
        PERFORM c_markofferaslost(v_cur.c_order_id,lostreason,lostreasontext,p_user);
    END LOOP;
    -- nach oben
    select o.orderselfjoin into v_relevantoffer from c_order o, c_order r where r.c_order_id=o.orderselfjoin and o.c_order_id=p_order_id  and r.DocStatus!='CL'  and
                   ad_get_docbasetype(r.c_doctype_id) in ('POREQUESTOFFER','SALESOFFER');    
    if v_relevantoffer is not null then
        update c_order set generatetemplate='Y',DocStatus='CL',processed='Y',Processing='N',proposalstatus='LO',Updated=now(),updatedby=p_user,
                       lostproposalfixedreason=lostreason,lostproposalreason=lostreasontext where c_order_id=v_relevantoffer  and DocStatus!='VO';  
        PERFORM c_markofferaslost(v_relevantoffer,lostreason,lostreasontext,p_user);
    end if;
    RETURN ''; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION c_generateoffervariant_userexit(v_offer_id varchar)
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
User-Exit for c_generateoffervariant
**/
DECLARE
v_return varchar:='';
BEGIN
RETURN v_return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_generateoffervariant(p_Record_ID character varying,p_user character varying)
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
Part of Order Process
     Generates a variant from Offer or Quotation's
*****************************************************/
  v_Message character varying:='ERROR'; 
  v_COrder_ID character varying; 
  v_Client_ID character varying; 
  v_Org_ID character varying; 
  v_DocumentNo character varying; 
  v_CDocTypeID character varying; 
  v_IssoTrx character varying;
  v_dummy character varying;
  v_variantsuffix character varying;
  v_cur RECORD;
BEGIN 
    -- Create Order Header
    select get_uuid() into v_COrder_ID;
    update c_order set createdbycopy='N' where c_order_id=p_Record_ID;
    select issotrx,c_doctype_id,ad_client_id,ad_org_id into v_IssoTrx, v_CDocTypeID,v_Client_ID,v_Org_ID from c_order where c_order_id=p_Record_ID;
    select vformat into v_variantsuffix from ad_sequence where ad_sequence_id =(select  docnosequence_id from c_doctype where c_doctype_id=v_CDocTypeID);
    if v_IssoTrx='Y' then
        SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('Proposal', v_Org_ID, 'Y') ;
    else
        SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('Purchase Order', v_Org_ID, 'Y') ;
    end if;   
    -- Always exactly 1 Record, but more efficient code to do it like this...
    -- The Order Self Join always set to the main Document.
    for v_cur in (select * from c_order where c_order_id=p_Record_ID)
    LOOP
        v_Client_ID:=v_cur.AD_CLIENT_ID;
        v_Org_ID:=v_cur.AD_ORG_ID;
        INSERT INTO C_Order
              (C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATEDBY,UPDATEDBY,
              ISSOTRX, DOCUMENTNO, DOCSTATUS, DOCACTION, PROCESSING,
              C_DOCTYPE_ID,C_DOCTYPETARGET_ID, DESCRIPTION,deliverynotes,
              DATEORDERED, DATEACCT, C_BPARTNER_ID, BILLTO_ID,
              C_BPARTNER_LOCATION_ID, C_CURRENCY_ID, PAYMENTRULE, C_PAYMENTTERM_ID,
              INVOICERULE, DELIVERYRULE, FREIGHTCOSTRULE, DELIVERYVIARULE,
              PRIORITYRULE,  M_WAREHOUSE_ID, M_PRICELIST_ID, ISTAXINCLUDED, DATEPROMISED, poreference,c_project_id,a_asset_id,ad_user_id,salesrep_id,name,bpzipcode,c_incoterms_id,delivery_location_id,weight,weight_uom,
              m_shipper_id,m_product_id,qty,freightamt,orderselfjoin,invoicefrequence,enddate,contractdate,
              yearly_month,weekly_day,monthly_day,quarterly_month,isinvoiceafterfirstcycle,internalnote,c_projecttask_id,scheddeliverydate,
              deliverylocationtext,discountcouponcode,c_salesregion_id,subsrdailyratebilling,c_tax_id)
            VALUES
              (v_COrder_ID, v_Client_ID, v_Org_ID,v_cur.isactive,p_User, p_User,
              v_cur.issotrx, v_DocumentNo||coalesce(v_variantsuffix,''),  'DR', 'CO','N',
              v_CDocTypeID, v_CDocTypeID, 
              v_cur.Description,v_cur.deliverynotes,trunc(now()), trunc(now()), v_cur.C_BPARTNER_ID, v_cur.BILLTO_ID,
              v_cur.C_BPARTNER_LOCATION_ID, v_cur.C_CURRENCY_ID, v_cur.PAYMENTRULE, v_cur.C_PAYMENTTERM_ID,
              v_cur.INVOICERULE, v_cur.DELIVERYRULE, v_cur.FREIGHTCOSTRULE, v_cur.DELIVERYVIARULE,
              v_cur.PRIORITYRULE,  v_cur.M_WAREHOUSE_ID, v_cur.M_PRICELIST_ID, v_cur.ISTAXINCLUDED, v_cur.DATEPROMISED,v_cur.poreference,
              v_cur.c_project_id,v_cur.a_asset_id,v_cur.ad_user_id,v_cur.salesrep_id,v_cur.name,v_cur.bpzipcode,v_cur.c_incoterms_id,v_cur.delivery_location_id,v_cur.weight,v_cur.weight_uom,
              v_cur.m_shipper_id,v_cur.m_product_id,v_cur.qty,v_cur.freightamt,p_Record_ID,v_cur.invoicefrequence,v_cur.enddate,v_cur.contractdate,
              v_cur.yearly_month,v_cur.weekly_day,v_cur.monthly_day,v_cur.quarterly_month,v_cur.isinvoiceafterfirstcycle,v_cur.internalnote,v_cur.c_projecttask_id,v_cur.scheddeliverydate,
              v_cur.deliverylocationtext,v_cur.discountcouponcode,v_cur.c_salesregion_id,v_cur.subsrdailyratebilling,v_cur.c_tax_id);
    END LOOP;
    v_dummy:= c_copyorderlines(p_Record_ID,v_COrder_ID,p_User);
    v_dummy:= c_copyordertextmodules(p_Record_ID,v_COrder_ID,p_User);
    v_Message:=zsse_htmldirectlink('../SalesOrder/Header_Relation.html','document.frmMain.inpcOrderId',v_COrder_ID,v_DocumentNo||coalesce(v_variantsuffix,''));
    --  Update AD_PInstance
    PERFORM c_generateoffervariant_userexit(v_COrder_ID);
    RETURN v_Message; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION c_copyordertextmodules (
  p_sourceorder_id varchar,
  p_destorder_id varchar,
  p_user_id varchar
)
RETURNS varchar AS
$body$
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
Part of Order Process
    Copys Orderlines from a given Order
*****************************************************/
  v_i numeric:=0;
  v_cur RECORD;
  v_org_id character varying;
  v_client_id character varying;
  v_dummy character varying;
BEGIN 
    select ad_client_id,ad_org_id into  v_client_id,v_org_id from c_order where c_order_id=p_sourceorder_id;
    --raise notice '%','copyorderlines - Source:'||coalesce(p_sourceorder_id,'0');
    --raise notice '%','copyorderlines - Dest:'||coalesce(p_destorder_id,'0');
    -- Copy the lines from the given Order
    for v_cur in (
      select * from zssi_order_textmodule 
      where (c_order_id=p_sourceorder_id and zssi_textmodule_id is null) or (c_order_id=p_sourceorder_id and zssi_textmodule_id is not null and ismodified='Y'))
    LOOP
         INSERT INTO zssi_order_textmodule
            (ZSSI_ORDER_TEXTMODULE_ID, C_ORDER_ID, ZSSI_TEXTMODULE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATED,CREATEDBY, UPDATED, UPDATEDBY, LINE, ISLOWER, TEXT, ISMODIFIED)
         VALUES
            (get_uuid(),p_destorder_id,v_cur.ZSSI_TEXTMODULE_ID,v_Client_ID, v_Org_ID,now(),p_user_id,now(), p_User_id,v_cur.LINE, v_cur.ISLOWER, v_cur.TEXT,v_cur.ISMODIFIED);
         v_i:=v_i+1;
    END LOOP;
       delete from zssi_order_textmodule where c_order_id=p_destorder_id and
           zssi_textmodule_id in (select zssi_textmodule_id from zssi_order_textmodule where c_order_id=p_destorder_id group by zssi_textmodule_id having count(*)>1)
           and ismodified='N';  
    RETURN to_char(v_i);

END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION c_copyordertextmodules_offer2order ( p_sourceorder_id varchar,  p_destorder_id varchar, p_user_id varchar)
RETURNS varchar AS
$body$
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
Part of Order Process
    Copys Orderlines from a given Order
*****************************************************/
  v_i numeric:=0;
  v_cur RECORD;
  v_org_id character varying;
  v_client_id character varying;
BEGIN 
    select ad_client_id,ad_org_id into  v_client_id,v_org_id from c_order where c_order_id=p_sourceorder_id;
    --raise notice '%','copyorderlines - Source:'||coalesce(p_sourceorder_id,'0');
    --raise notice '%','copyorderlines - Dest:'||coalesce(p_destorder_id,'0');
    -- Copy the lines from the given Order
    for v_cur in (
      select * from zssi_order_textmodule 
      where (c_order_id=p_sourceorder_id and zssi_textmodule_id is null) or (c_order_id=p_sourceorder_id and zssi_textmodule_id is not null and ismodified='Y'))
    LOOP
         INSERT INTO zssi_order_textmodule
            (ZSSI_ORDER_TEXTMODULE_ID, C_ORDER_ID, ZSSI_TEXTMODULE_ID, AD_CLIENT_ID, AD_ORG_ID,CREATED, CREATEDBY,UPDATED, UPDATEDBY, LINE, ISLOWER, TEXT, ISMODIFIED)
         VALUES
            (get_uuid(),p_destorder_id,v_cur.ZSSI_TEXTMODULE_ID,v_Client_ID, v_Org_ID,now(),p_user_id,now(), p_User_id,v_cur.LINE, v_cur.ISLOWER, v_cur.TEXT,v_cur.ISMODIFIED);
         v_i:=v_i+1;
    END LOOP;
    RETURN to_char(v_i); 
END ;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION public.c_copyorderlines (
  p_sourceorder_id varchar,
  p_destorder_id varchar,
  p_user_id varchar
)
RETURNS varchar AS
$body$
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
Part of Order Process
    Copys Orderlines from a given Order
    ONLY for Use in (References are switched)
    Used in  c_generateoffervariant
    And  c_generateorderfromoffer
*****************************************************/

  v_cur RECORD;
  v_cur2 record;
  v_org_id character varying;
  v_client_id character varying;
  v_i numeric:=0;
  v_copy_onetimepositions character varying;
  v_uid character varying;
BEGIN 
    select ad_client_id,ad_org_id into  v_client_id,v_org_id from c_order where c_order_id=p_sourceorder_id;
    -- One Time Position Flag can b3e copied only into Subscriptions and Subscription Proposals.
    select case when c_doctype_id in ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then 'Y'  else 'N' end into v_copy_onetimepositions from c_order where c_order_id=p_destorder_id;
    --raise notice '%','copyorderlines - Source:'||coalesce(p_sourceorder_id,'0');
    --raise notice '%','copyorderlines - Dest:'||coalesce(p_destorder_id,'0');
    -- Copy the lines from the given Order
    for v_cur in (
      select * from c_orderline ol
      LEFT JOIN m_product p 
        ON p.m_product_id = ol.m_product_id 
      where c_order_id=p_sourceorder_id
        AND p.isfreightproduct = 'N')
    LOOP
         v_uid:=get_uuid();
         INSERT INTO C_OrderLine
            (C_ORDER_ID,C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY,
            ISACTIVE,LINE, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID,
            DATEORDERED, DATEPROMISED, DESCRIPTION, M_PRODUCT_ID,
            M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED, C_CURRENCY_ID,
            PRICELIST, PRICEACTUAL, PRICELIMIT,
            PRICESTD,  DISCOUNT,
            C_TAX_ID,quantityorder,m_product_uom_id,c_project_id,a_asset_id,isonetimeposition,scheddeliverydate,m_product_po_id,isoptional,textposition,c_projecttask_id,
            ispagebreak,m_attributesetinstance_id,iscombined,ispricesuppressed)
          VALUES
            (p_destorder_id,v_uid,v_Client_ID, v_Org_ID,p_user_id, p_User_id,
             v_cur.ISACTIVE,v_cur.LINE, v_cur.C_BPARTNER_ID, v_cur.C_BPARTNER_LOCATION_ID,
             v_cur.DATEORDERED, v_cur.DATEPROMISED, v_cur.DESCRIPTION, v_cur.M_PRODUCT_ID,
             v_cur.M_WAREHOUSE_ID, v_cur.C_UOM_ID, v_cur.QTYORDERED, v_cur.C_CURRENCY_ID,
             v_cur.PRICELIST, v_cur.PRICEACTUAL, v_cur.PRICELIMIT,
             v_cur.PRICESTD,  v_cur.DISCOUNT,
             v_cur.C_TAX_ID,v_cur.quantityorder,v_cur.m_product_uom_id,
             v_cur.c_project_id,v_cur.a_asset_id,case v_copy_onetimepositions when 'Y' then v_cur.isonetimeposition else 'N' end,v_cur.scheddeliverydate,v_cur.m_product_po_id,
             v_cur.isoptional,v_cur.textposition,v_cur.c_projecttask_id,v_cur.ispagebreak,v_cur.m_attributesetinstance_id,v_cur.iscombined,v_cur.ispricesuppressed);
         v_i:=v_i+1;
         -- Refs to Purchase Documents are switched to new Document
         for v_cur2 in (select ol.c_orderline_id from c_orderline ol,c_order o where o.c_order_id=ol.c_order_id and o.issotrx='N' and ol.orderlineselfjoin=v_cur.c_orderline_id)
         LOOP
            update c_orderline set orderlineselfjoin=v_uid where  c_orderline_id=v_cur2.c_orderline_id;
         end LOOP;
    END LOOP;
    -- Payment scheduling
    for v_cur in (select * from c_order_paymentschedule where c_order_id=p_sourceorder_id)
    LOOP
         INSERT INTO c_order_paymentschedule
            (C_ORDER_PAYMENTSCHEDULE_ID,C_ORDER_ID,AD_CLIENT_ID,AD_ORG_ID, CREATEDBY,UPDATEDBY, INVOICEDATE, AMOUNT, DESCRIPTION)
          VALUES
            (get_uuid(),p_destorder_id,v_Client_ID, v_Org_ID,p_user_id, p_User_id,
             v_cur.INVOICEDATE,v_cur.AMOUNT, v_cur.DESCRIPTION);
         v_i:=v_i+1;
    END LOOP;
    
    RETURN to_char(v_i); 
END ;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

select zsse_dropfunction('c_copyorderlineswithref');

CREATE OR REPLACE FUNCTION c_copyorderlineswithref (
  p_sourceorder_id varchar,
  p_destorder_id varchar,
  p_user_id varchar,
  p_isrecharge varchar
)
RETURNS varchar AS
$body$
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
Part of Order Process
    Copys Orderlines from a given Order
*****************************************************/

  v_cur RECORD;
  v_cur2 RECORD;
  v_org_id character varying;
  v_client_id character varying;
  v_price numeric;
  v_stdprice numeric;
  v_listprice numeric;
  v_partner varchar;
  v_partner_location_id character varying;
  v_pricelist varchar;
  v_isprodline varchar:='N';
  v_i numeric:=0;
  v_uom varchar;
  v_poid varchar;
  v_manu varchar;
  v_mnu varchar;
  v_curr varchar;
BEGIN 
    select ad_client_id,ad_org_id into  v_client_id,v_org_id from c_order where c_order_id=p_sourceorder_id;
    select c_bpartner_id,m_pricelist_id,c_bpartner_location_id,c_currency_id into v_partner,v_pricelist,v_partner_location_id,v_curr from c_order where c_order_id=p_destorder_id;
    --raise notice '%','copyorderlines - Source:'||coalesce(p_sourceorder_id,'0');
    --raise notice '%','copyorderlines - Dest:'||coalesce(p_destorder_id,'0');
    -- Copy the lines from the given Order
    for v_cur in (
      select * from c_orderline ol
      LEFT JOIN m_product p 
        ON p.m_product_id = ol.m_product_id 
      where c_order_id=p_sourceorder_id
        AND p.isfreightproduct = 'N')
    LOOP
         v_stdprice:=v_cur.PRICESTD;
         v_listprice:=v_cur.PRICELIST;
         -- Recharge 
         if coalesce(p_isrecharge,'N')='Y' then
            --v_price:=m_get_offers_price(v_cur.DATEORDERED,v_partner,v_cur.M_PRODUCT_ID,v_cur.QTYORDERED,null,'Y',v_cur.PRICEACTUAL, v_cur.isgrossprice, v_cur.c_tax_id);
            v_price:=m_get_offers_price(v_cur.DATEORDERED,v_partner,v_cur.M_PRODUCT_ID,v_cur.QTYORDERED,v_pricelist,'Y',v_cur.PRICEACTUAL,v_cur.isgrossprice, v_cur.c_tax_id,v_cur.m_product_uom_id,null);
            v_stdprice:=v_price ;
            v_listprice:=v_price;
         else
            -- Dropshipping
            if coalesce(p_isrecharge,'N')='D' then
                SELECT  c_uom_id into v_uom from m_product_uom where m_product_uom_id=v_cur.m_product_uom_id;
                -- Correct price of Partner
                select pricepo,pricelist, m_product_po_id,m_manufacturer_id,manufacturernumber into v_stdprice,v_listprice,  v_poid ,v_manu,v_mnu  from m_product_po po where m_product_id=v_cur.M_PRODUCT_ID and PO.iscurrentvendor='Y' 
                  and case when v_uom is not null then coalesce(c_uom_id,'null')=v_uom else c_uom_id is null end 
                  and po.c_bpartner_id=v_partner 
                 order by coalesce(po.qualityrating,0) desc,updated desc limit 1;
                if v_manu is  null and v_mnu is null then
                        v_poid:=null;
                end if;
                v_price:=m_get_offers_price(v_cur.DATEORDERED,v_partner,v_cur.M_PRODUCT_ID,v_cur.QTYORDERED,v_pricelist,'N',null,'N',null,v_uom,v_poid);
            else
                v_price:=v_cur.PRICEACTUAL;
                
            end if;
         end if;
         if v_isprodline='N' then
            INSERT INTO C_OrderLine
                (C_ORDER_ID,C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY,
                ISACTIVE,LINE, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID,
                DATEORDERED, DATEPROMISED, DESCRIPTION, M_PRODUCT_ID,
                M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED, C_CURRENCY_ID,
                PRICELIST, PRICEACTUAL, PRICELIMIT,
                PRICESTD,  DISCOUNT,
                C_TAX_ID,quantityorder,m_product_uom_id,c_project_id,a_asset_id,isonetimeposition, ref_orderline_id,scheddeliverydate,m_product_po_id,c_projecttask_id,
                textposition,ispagebreak,m_attributesetinstance_id,isapproved,iscombined,ispricesuppressed)
            VALUES
                (p_destorder_id,get_uuid(),v_Client_ID, v_Org_ID,p_user_id, p_User_id,
                v_cur.ISACTIVE,v_cur.LINE, v_cur.C_BPARTNER_ID, v_cur.C_BPARTNER_LOCATION_ID,
                v_cur.DATEORDERED, v_cur.DATEPROMISED, v_cur.DESCRIPTION, v_cur.M_PRODUCT_ID,
                v_cur.M_WAREHOUSE_ID, v_cur.C_UOM_ID, v_cur.QTYORDERED, v_curr,
                coalesce(v_listprice,0), v_price, v_cur.PRICELIMIT,
                coalesce(v_stdprice,0),  v_cur.DISCOUNT,
                zsfi_GetTax(v_partner_location_id, v_cur.M_PRODUCT_ID, v_org_id),v_cur.quantityorder,v_cur.m_product_uom_id,
                v_cur.c_project_id,v_cur.a_asset_id,v_cur.isonetimeposition, v_cur.c_orderline_id,v_cur.scheddeliverydate,v_poid,v_cur.c_projecttask_id,
                v_cur.textposition,v_cur.ispagebreak,v_cur.m_attributesetinstance_id,v_cur.isapproved,v_cur.iscombined, v_cur.ispricesuppressed);
            v_i:=v_i+1;
          end if;
    END LOOP;
    -- Payment scheduling
    for v_cur in (select * from c_order_paymentschedule where c_order_id=p_sourceorder_id)
    LOOP
         INSERT INTO c_order_paymentschedule
            (C_ORDER_PAYMENTSCHEDULE_ID,C_ORDER_ID,AD_CLIENT_ID,AD_ORG_ID, CREATEDBY,UPDATEDBY, INVOICEDATE, AMOUNT, DESCRIPTION)
          VALUES
            (get_uuid(),p_destorder_id,v_Client_ID, v_Org_ID,p_user_id, p_User_id,
             v_cur.INVOICEDATE,v_cur.AMOUNT, v_cur.DESCRIPTION);
         v_i:=v_i+1;
    END LOOP;
    
    RETURN to_char(v_i); 
END ;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION public.c_copyorderlineswithoutprojectanddatepromised (
  p_sourceorder_id varchar,
  p_destorder_id varchar,
  p_user_id varchar
)
RETURNS varchar AS
$body$
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
Part of Order Process
    Copys Orderlines from a given Order
*****************************************************/

  v_cur RECORD;
  v_org_id character varying;
  v_client_id character varying;
  v_bpartner  character varying;
  v_i numeric:=0;
  v_copy_onetimepositions character varying;
  v_copy_optionalpositions character varying;
  v_project character varying;
  v_datepromised timestamp;
  v_scheddeliverydate timestamp;
  v_dateordered timestamp;
  v_pricelist character varying;
  v_projecttask varchar;
  v_asset varchar;
  v_warehouse varchar;
  v_currency varchar;
  v_location varchar;
  v_isso varchar;
  v_poid varchar;
  v_uom varchar;
BEGIN 
    select case when c_doctype_id in ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then 'Y' else 'N' end,
           case when ad_get_docbasetype(c_doctypetarget_id) = 'SALESOFFER'  then 'Y' else 'N' end,
           ad_client_id,ad_org_id,m_pricelist_id,c_bpartner_id,datepromised,scheddeliverydate,c_project_id,c_projecttask_id,a_asset_id,dateordered,M_WAREHOUSE_ID,
           c_currency_id,c_bpartner_location_id,issotrx
    into  v_copy_onetimepositions,v_copy_optionalpositions,
          v_client_id,v_org_id,v_pricelist,v_bpartner,v_datepromised,v_scheddeliverydate,v_project,v_projecttask,v_asset,v_dateordered,v_warehouse,
          v_currency,v_location,v_isso
    from c_order where c_order_id=p_destorder_id;
    
    --raise notice '%','copyorderlines - Source:'||coalesce(p_sourceorder_id,'0');
    --raise notice '%','copyorderlines - Dest:'||coalesce(p_destorder_id,'0');
    -- Copy the lines from the given Order
    for v_cur in (
      select * from c_orderline ol
      LEFT JOIN m_product p 
        ON p.m_product_id = ol.m_product_id 
      where c_order_id=p_sourceorder_id
        AND p.isfreightproduct = 'N')
    LOOP
          if v_isso='N' then
            select c_uom_id into v_uom from m_product_uom where m_product_uom_id=v_cur.m_product_uom_id;
            v_poid:=m_getBestRatedPOID(v_cur.M_PRODUCT_ID,v_bpartner,v_uom,null,v_currency,v_Org_ID);
            if (select count(*) from m_product_po where m_product_po_id=v_poid and manufacturernumber is null and m_manufacturer_id  is null)>0 then
                    v_poid:=null;
            end if;
         else
                 v_poid:=null;
         end if;
         INSERT INTO C_OrderLine
            (C_ORDER_ID,C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY,
            ISACTIVE,LINE, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID,
            DATEORDERED,  DESCRIPTION, M_PRODUCT_ID,
            M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED, C_CURRENCY_ID,
            PRICELIST, PRICEACTUAL, PRICELIMIT,
            PRICESTD,  DISCOUNT,
            C_TAX_ID,quantityorder,m_product_uom_id,isonetimeposition,c_project_id,datepromised,scheddeliverydate,c_projecttask_id,a_asset_id,m_product_po_id,
            textposition,isoptional,ispagebreak,m_attributesetinstance_id,iscombined,ispricesuppressed)
          VALUES
            (p_destorder_id,get_uuid(),v_Client_ID, v_Org_ID,p_user_id, p_User_id,
             v_cur.ISACTIVE,v_cur.LINE, v_bpartner, v_location,
             v_dateordered,  v_cur.DESCRIPTION, v_cur.M_PRODUCT_ID,
             v_warehouse, v_cur.C_UOM_ID, v_cur.QTYORDERED, v_currency,
             m_bom_pricelist(v_cur.M_PRODUCT_ID,v_pricelist,v_cur.m_product_uom_id,v_poid), 
             m_get_offers_price(v_dateordered, v_bpartner,v_cur.M_PRODUCT_ID,v_cur.QTYORDERED,v_pricelist,'N',null,'N',null,v_cur.m_product_uom_id,v_poid),
             m_bom_pricelimit(v_cur.M_PRODUCT_ID,v_pricelist,v_cur.m_product_uom_id,v_poid), 
             m_bom_pricestd(v_cur.M_PRODUCT_ID,v_pricelist,v_cur.m_product_uom_id,v_poid),  
             round(case when m_bom_pricestd(v_cur.M_PRODUCT_ID,v_pricelist)=0 then 0 else (m_bom_pricestd(v_cur.M_PRODUCT_ID,v_pricelist)-m_get_offers_price(v_dateordered, v_bpartner,v_cur.M_PRODUCT_ID,v_cur.QTYORDERED,v_pricelist))/(m_bom_pricestd(v_cur.M_PRODUCT_ID,v_pricelist)*100) end,2),
             zsfi_GetTax(v_location,v_cur.M_PRODUCT_ID,v_Org_ID),v_cur.quantityorder,v_cur.m_product_uom_id,
             case v_copy_onetimepositions when 'Y' then v_cur.isonetimeposition else 'N' end,v_project,v_datepromised,v_scheddeliverydate,v_projecttask,v_asset,v_poid,
             v_cur.textposition,case when v_copy_optionalpositions='Y' then v_cur.isoptional else 'N' end,v_cur.ispagebreak,v_cur.m_attributesetinstance_id,v_cur.iscombined,v_cur.ispricesuppressed);
         v_i:=v_i+1;
    END LOOP;
    -- Payment scheduling
    for v_cur in (select * from c_order_paymentschedule where c_order_id=p_sourceorder_id)
    LOOP
         INSERT INTO c_order_paymentschedule
            (C_ORDER_PAYMENTSCHEDULE_ID,C_ORDER_ID,AD_CLIENT_ID,AD_ORG_ID, CREATEDBY,UPDATEDBY, INVOICEDATE, AMOUNT, DESCRIPTION)
          VALUES
            (get_uuid(),p_destorder_id,v_Client_ID, v_Org_ID,p_user_id, p_User_id,
             v_cur.INVOICEDATE,v_cur.AMOUNT, v_cur.DESCRIPTION);
         v_i:=v_i+1;
    END LOOP;
    
    RETURN to_char(v_i); 
END ;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION c_orderlineadditems_trg()
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
Propagates changes on Freight to the Orderline
Be aware of c_orderline_trg - Prevent endless loop!
*****************************************************/

v_cur  RECORD;
v_plvid character varying;
v_pl  character varying;
v_bpartner character varying;
v_bplocid  character varying;
v_line numeric;
BEGIN
IF AD_isTriggerEnabled()='N' then RETURN NEW; END IF; 
   if (select issummary from m_product where m_product_id=new.m_product_id)='Y' then
      select c_bpartner_id, m_pricelist_id,c_bpartner_location_id into v_bpartner,v_pl,v_bplocid from c_order where c_order_id=new.c_order_id;
      SELECT M_PRICELIST_VERSION_ID INTO v_plvid  FROM M_PRICELIST_VERSION
          WHERE M_PRICELIST_ID=v_pl and  VALIDFROM =    (SELECT max(VALIDFROM)    FROM M_PRICELIST_VERSION   WHERE M_PRICELIST_ID=v_pl and VALIDFROM<=TO_DATE(NOW())); 
      v_line:=new.line+10;
      for v_cur in
        (select m_product_bom.m_productbom_id as m_product_id,m_product_bom.bomqty as qty,
                m_product.c_uom_id,coalesce(m_product_bom.DESCRIPTION,m_product.DESCRIPTION) as description,
                zsfi_GetTax(v_bplocid,m_product_bom.m_productbom_id,new.ad_org_id) as c_tax_id,
                m_get_offers_price(to_date(now()),v_bpartner,m_product_bom.m_productbom_id,null,m_product_bom.bomqty,v_pl) as priceactual,
                m_bom_pricelist(m_product_bom.m_productbom_id,v_plvid) as pricelist,
                m_bom_pricestd(m_product_bom.m_productbom_id,v_plvid) as pricestd,
                m_bom_pricelimit(m_product_bom.m_productbom_id,v_plvid) as pricelimit,
                round(((m_bom_pricestd(m_product_bom.m_productbom_id,v_plvid)-m_get_offers_price(to_date(now()),v_bpartner,m_product_bom.m_productbom_id,null,m_product_bom.bomqty,v_pl))/case m_bom_pricestd(m_product_bom.m_productbom_id,v_plvid) when 0 then 1 else m_bom_pricestd(m_product_bom.m_productbom_id,v_plvid) end)*100,2) as discount
        from m_product_bom,m_product where
              m_product_bom.m_productbom_id=m_product.m_product_id and
              m_product_bom.m_product_id=new.m_product_id)
       LOOP
              insert into c_orderline( C_ORDERLINE_ID,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, C_ORDER_ID,
                          LINE, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID, DATEORDERED, DATEPROMISED, DESCRIPTION,
                          M_PRODUCT_ID, M_WAREHOUSE_ID, DIRECTSHIP, C_UOM_ID, QTYORDERED, C_CURRENCY_ID, PRICELIST,
                          pricestd,PRICEACTUAL, PRICELIMIT, DISCOUNT, C_TAX_ID, 
                          ISGROSSPRICE, C_PROJECT_ID, C_PROJECTPHASE_ID, C_PROJECTTASK_ID, A_ASSET_ID)     
              values (get_uuid(),new.AD_CLIENT_ID, new.AD_ORG_ID, new.CREATEDBY, new.UPDATEDBY, new.C_ORDER_ID,
                          v_line,v_bpartner,v_bplocid,new.DATEORDERED, new.DATEPROMISED,v_cur.DESCRIPTION,
                          v_cur.M_PRODUCT_ID,new.M_WAREHOUSE_ID, new.DIRECTSHIP,v_cur.C_UOM_ID,v_cur.qty,new.C_CURRENCY_ID,
                          v_cur.PRICELIST,v_cur.pricestd,v_cur.PRICEACTUAL, v_cur.PRICELIMIT, v_cur.DISCOUNT, v_cur.C_TAX_ID, 
                           new.ISGROSSPRICE, new.C_PROJECT_ID, new.C_PROJECTPHASE_ID, new.C_PROJECTTASK_ID, new.A_ASSET_ID);
              v_line:=v_line+10;
       END LOOP;
   end if;    
RETURN NEW;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_orderlineadditems_trg() OWNER TO tad;

drop trigger c_orderlineadditems_trg on c_orderline;

CREATE TRIGGER c_orderlineadditems_trg
  AFTER INSERT
  ON c_orderline
  FOR EACH ROW
  EXECUTE PROCEDURE c_orderlineadditems_trg();
 
 



CREATE OR REPLACE FUNCTION c_order_paymentschedule_trg()
  RETURNS trigger AS
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

v_doctype character varying;
v_invrule character varying;
v_total numeric;
v_tax numeric;
v_text character varying;
v_curr varchar;
v_lang varchar;
v_modtext varchar;
v_cur record;
v_shedtext varchar;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'DELETE' then
       if old.c_invoice_id is not null then
           raise exception 'Der Zahlplan wurde bereits ausgeführt. Löschen nicht möglich, solange eine Rechnung zu diesem Zahlplan existiert.';
       end if;
   else
      select c_doctypetarget_id,invoicerule into v_doctype,v_invrule from c_order where c_order_id=new.c_order_id;
      -- No  paymentschedule on subscriptions....
      if v_doctype  in ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then
            raise exception 'Zahlpläne gibt es für Abonnements nicht. Bitte Zahlungen über Frequenz einstellen.';
      end if;
      if v_invrule !='I' then
            raise exception 'Bei Zahlplänen muß die Rechnungsregel "sofort" eingestellt sein. Bitte ändern Sie die Einstellung und erstellen dann den Zahlplan';
      end if;
      if (select count(distinct c_tax_id) from c_orderline where c_order_id=new.c_order_id)>1 then
        raise exception 'Bei Zahlplänen darf nur eine Steuerart benutzt werden.';
      end if;
      if new.isrevenue='Y' and (select count(*) from c_order_paymentschedule where c_order_id=new.c_order_id and c_order_paymentschedule_id!=new.c_order_paymentschedule_id and isrevenue='Y')>0 then
        raise exception 'Bei Zahlplänen darf nur ein Datensatz mit der Option Verumsatzen erstellt werden.';
      end if;
      if new.invoicedate in (select invoicedate from c_order_paymentschedule where c_order_id=new.c_order_id and c_order_paymentschedule_id!=new.c_order_paymentschedule_id) then
        raise exception 'Zwei Zahlplaneinträge an einem Datum gehen halt nicht..';
      end if;
      select b.ad_language,o.grandtotal,o.grandtotal-o.totallines,c.iso_code into v_lang,v_total, v_tax,v_curr from c_order o,c_currency c, c_bpartner b 
      where o.c_bpartner_id=b.c_bpartner_id and o.c_currency_id=c.c_currency_id and o.c_order_id=new.c_order_id;
      if v_lang is null then
        select coalesce(ad_language,'de_DE') into v_lang from ad_client where ad_client_id=new.ad_client_id;
      end if;
      -- Get Text Modules and Invoice-Summary
      if new.description is null then
                select coalesce(replace(replace(replace(text,'@GRANDTOTAL@',zssi_strNumber(v_total,v_lang)),'@CURRENCY@',v_curr),'@TAX@',zssi_strNumber(v_tax,v_lang)),'') 
                    into v_modtext from zssi_textmodule where zssi_textmodule_id=new.textmoduledescription;
                if v_modtext is not null then
                    new.description:=v_modtext;
                end if;
      end if;
      if new.descriptionline is null then
                select coalesce(replace(replace(replace(text,'@GRANDTOTAL@',zssi_strNumber(v_total,v_lang)),'@CURRENCY@',v_curr),'@TAX@',zssi_strNumber(v_tax,v_lang)),'') 
                    into v_modtext from zssi_textmodule where zssi_textmodule_id=new.textmoduleposition;
                if v_modtext is not null then
                    new.descriptionline:=v_modtext;
                end if;
      end if;
   end if;
        
IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_droptrigger('c_order_paymentschedule_trg','c_order_paymentschedule');

CREATE TRIGGER c_order_paymentschedule_trg
  BEFORE INSERT OR UPDATE or DELETE
  ON c_order_paymentschedule
  FOR EACH ROW
  EXECUTE PROCEDURE c_order_paymentschedule_trg();


CREATE OR REPLACE FUNCTION zssi_getVALUE4ordercomplete(p_order_id character varying)
  RETURNS numeric AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
  v_numberofcycles numeric:=0;
  v_frequence character varying;
  v_doctype character varying;
  v_amt numeric;
  v_amtonetime numeric;
  v_enddate timestamp;
  v_begin timestamp;
  v_contractdate timestamp;
  v_interval interval;
BEGIN
    select c_doctypetarget_id,invoicefrequence,contractdate,enddate into v_doctype,v_frequence,v_contractdate,v_enddate from c_order where c_order_id=p_order_id;
    select coalesce(sum(linenetamt),0) into v_amt from c_orderline where c_order_id=p_order_id and isonetimeposition='N';
    select coalesce(sum(linenetamt),0) into v_amtonetime from c_orderline where c_order_id=p_order_id and isonetimeposition='Y';
    if v_doctype not in  ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24')  then 
       v_numberofcycles:=1;
    else
        select c_getnumberofsubscriptionintervals (p_order_id, trunc(v_contractdate),v_frequence,trunc(v_enddate)) into v_numberofcycles;
    end if;
    return coalesce(v_numberofcycles,0)*coalesce(v_amt,0)+coalesce(v_amtonetime,0);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_getVALUE4orderBySheduleParameters(p_order_id character varying,p_doctype character varying,p_frequence character varying,p_contractdate timestamp,p_enddate timestamp)
  RETURNS numeric AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
  v_numberofcycles numeric:=0;
  v_amt numeric;
  v_amtonetime numeric;
  v_begin timestamp;
  v_interval interval;
BEGIN
    select coalesce(sum(linenetamt),0) into v_amt from c_orderline where c_order_id=p_order_id and isonetimeposition='N';
    select coalesce(sum(linenetamt),0) into v_amtonetime from c_orderline where c_order_id=p_order_id and isonetimeposition='Y';
    if p_doctype not in  ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') then 
       v_numberofcycles:=1;
    else
        select c_getnumberofsubscriptionintervals(p_order_id, trunc(p_contractdate),p_frequence,trunc(p_enddate)) into v_numberofcycles;
    end if;
    return coalesce(v_numberofcycles,0)*coalesce(v_amt,0)+coalesce(v_amtonetime,0);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION  c_orderline_value_trg() RETURNS trigger AS $_$ DECLARE 
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
  v_count            NUMERIC; 
  v_ordervalue       NUMERIC:=0; 
  v_weight numeric;
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;
  IF(TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    -- Update Header (Subscription-Value and evtl. Invoiced Sum)
    select count(*) into v_count from c_order where c_order_id=new.c_order_id and c_doctypetarget_id in ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') ;
    if v_count=1 then
       select zssi_getVALUE4ordercomplete(new.c_order_id) into v_ordervalue;
    end if;
    select sum(coalesce(m_product_weight(p.m_product_id),0)*l.qtyordered) into v_weight from c_orderline l,m_product p where p.m_product_id=l.m_product_id and l.c_order_id=new.c_order_id;
    if TG_OP = 'UPDATE' then
        if old.qtyordered= new.qtyordered and old.m_product_id=new.m_product_id then
            select weight into v_weight from c_order where c_order_id=new.c_order_id;
        end if;
        if (old.deliverycomplete!=new.deliverycomplete) or (old.qtydelivered!=new.qtydelivered) then            
             if old.qtydelivered>new.qtydelivered  then --or (new.deliverycomplete='Y' and old.deliverycomplete='N')
                 update zse_shoporderstatus set status='SHIPMENT RETURNED',updated=now(),deliverycomplete='N',isrefelctiondone='N' where c_order_id=new.c_order_id and issotrx='Y';
            end if;
            if old.qtydelivered<new.qtydelivered  then --or (new.deliverycomplete='N' and old.deliverycomplete='Y')
                update zse_shoporderstatus set status='GOODS IN TRANSIT',updated=now(),isrefelctiondone='N' where c_order_id=new.c_order_id and issotrx='Y';
            end if;
        end if;
    end if;
    update c_order set weight=v_weight,completeordervalue=v_ordervalue,Iscompletelyinvoiced=c_isorderCompletelyInvoiced(new.c_order_id),deliverycomplete=c_isorderCompletelyDelivered(new.c_order_id) where c_order_id=new.c_order_id;
    RETURN NEW;
  END IF;
  IF(TG_OP = 'DELETE' ) THEN
    -- Update Header (Subscription-Value and evtl. Invoiced Sum)
    select count(*) into v_count from c_order where c_order_id=old.c_order_id and c_doctypetarget_id in ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24') ;
    if v_count=1 then
       select zssi_getVALUE4ordercomplete(old.c_order_id) into v_ordervalue;
    end if;
    select sum(coalesce(m_product_weight(p.m_product_id),0)*l.qtyordered) into v_weight from c_orderline l,m_product p where p.m_product_id=l.m_product_id and l.c_order_id=old.c_order_id;
    update c_order set weight=v_weight,completeordervalue=v_ordervalue,Iscompletelyinvoiced=c_isorderCompletelyInvoiced(old.c_order_id),deliverycomplete=c_isorderCompletelyDelivered(old.c_order_id) where c_order_id=old.c_order_id;
    RETURN OLD;
  END IF;
END;
$_$ LANGUAGE plpgsql VOLATILE COST 100;



select zsse_droptrigger('c_orderline_value_trg','c_orderline');

CREATE TRIGGER c_orderline_value_trg
  AFTER INSERT OR UPDATE or DELETE
  ON c_orderline
  FOR EACH ROW
  EXECUTE PROCEDURE c_orderline_value_trg();
 

select zsse_dropfunction('zssi_getOrderLineValueByPeriod');
CREATE OR REPLACE FUNCTION zssi_getOrderLineValueByPeriod(
-- Only for internal Use, called by zssi_getvalue4orderByPeriod and zssi_getvalue4orderlineByPeriod
-- Calculate a subscricption-value (c_orderline) within a given evaluation period (DateFrom, DateUntil)
  p_orderline_id VARCHAR,
  p_currency_id VARCHAR,
  p_dateFrom TIMESTAMP,
  p_dateUntil TIMESTAMP

)
RETURNS NUMERIC AS
$body$
DECLARE
 v_doctype varchar;
 v_order varchar;
 v_onetime varchar;
 v_dateordered TIMESTAMP;
 p_ol_lineNetAmt  NUMERIC;
 p_ol_lineGrossAmt  NUMERIC;
 v_tax varchar;
 v_isgross varchar;
 v_resNetAmt  NUMERIC:=0;
 v_multiply NUMERIC:=1;
 v_ordercurr varchar;
BEGIN
  
  
  select ol.c_tax_id,ol.isgrossprice,o.c_currency_id,o.c_order_id,o.c_doctype_id,o.dateordered,ol.lineNetAmt,ol.linegrossamt,ol.isonetimeposition 
         into v_tax,v_isgross,v_ordercurr,v_order,v_doctype,v_dateordered,p_ol_lineNetAmt,p_ol_lineGrossAmt,v_onetime
         from c_order o,c_orderline ol where o.c_order_id=ol.c_order_id and ol.c_orderline_id=p_orderline_id 
         and ol.isoptional='N' and o.dateordered between p_dateFrom and p_dateUntil;
  if coalesce(ad_get_docbasetype(v_doctype),'NIX') in ('SOO','POO','SALESOFFER','POREQUESTOFFER') then
        -- Subscription Proposal
        if v_doctype='7DE8D4B1B8824D36974E8064BBED5095' and v_onetime='N' then
            v_multiply:=zssi_getNumberOfcycles4Subscription(v_order);
        end if;
        
        select case when v_isgross='Y' then 
                                  case when (select rate from c_tax where c_tax_id=v_tax)>0 then
                                    p_ol_lineGrossAmt- p_ol_lineGrossAmt/(1+100/(select rate from c_tax where c_tax_id=v_tax)) else
                                    p_ol_lineGrossAmt end else
                                p_ol_lineNetAmt end 
        into v_resNetAmt;
        
        v_resNetAmt := v_resNetAmt*v_multiply;
  else
        v_resNetAmt :=0;
  end if;
  RETURN c_currency_convert(v_resNetAmt,v_ordercurr,p_currency_id,v_dateordered); -- cumulated netAmt through determind periods
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE;




CREATE OR REPLACE FUNCTION zssi_getvalue4orderByPeriod(p_order_id character varying,p_currency_id VARCHAR, p_dateFrom TIMESTAMP, p_dateUntil TIMESTAMP)
  RETURNS numeric AS
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
Part of Order Process
    Copys Orderlines from a given Order
*****************************************************/
  v_i numeric:=0;
BEGIN 
    select  sum(zssi_getOrderLineValueByPeriod(c_orderline_id,p_currency_id,p_dateFrom,p_dateUntil)) into v_i from c_orderline where c_order_id=p_order_id;
    RETURN v_i; 
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


select zsse_dropfunction('zssi_getEstInvoiceAmt4orderlineByPeriod');
CREATE OR REPLACE FUNCTION zssi_getEstInvoiceAmt4orderlineByPeriod(p_orderline_id character varying,p_currency_id VARCHAR, p_dateFrom TIMESTAMP, p_dateUntil TIMESTAMP)
  RETURNS numeric AS
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
Part of Order Process
    Copys Orderlines from a given Order
*****************************************************/


  v_value numeric:=0;
  v_invoiced numeric:=0;
  p_ol_lineNetAmt numeric;
  v_count numeric;
  v_ignore varchar;
  v_partialAmountFactor numeric;
  v_curr varchar;
  v_dateordered TIMESTAMP;
BEGIN 
    select case when ol.isgrossprice='Y' then 
            case when (select rate from c_tax where c_tax_id=ol.c_tax_id)>0 then
            ol.linegrossamt- ol.linegrossamt/(1+100/(select rate from c_tax where c_tax_id=ol.c_tax_id)) else
            ol.linegrossamt end else
            ol.linenetamt end 
            * case when ad_get_docbasetype(o.c_doctype_id) in ('ARC','APC') then -1 else 1 end ,
         ol.ignoreresidue,o.c_currency_id,o.dateordered 
         into p_ol_lineNetAmt,v_ignore,v_curr,v_dateordered
         from c_order o,c_orderline ol where o.c_order_id=ol.c_order_id and ol.c_orderline_id=p_orderline_id and coalesce(ol.datepromised,p_dateFrom) between p_dateFrom and p_dateUntil;
    select  zssi_getinvoicedamt4orderlineByPeriod( p_orderline_id,v_curr, '-infinity'::timestamp,p_dateUntil) into v_invoiced;
    if v_ignore='Y' then
       return 0;
    end if;
    -- Payment Scheduling (Issue 1225)
    select count(*) into v_count from c_order_paymentschedule ps 
           where ps.c_order_id=(select c_order_id from c_orderline where c_orderline_id=p_orderline_id)
           and ps.c_invoice_id is null and ps.invoicedate between p_dateFrom and p_dateUntil ;
    -- paymentschedule - Automatic Invoice only on  Orderlines if v_count>0
    if v_count>0 then
            v_invoiced:=0;
            select case when ol.isgrossprice='Y' then 
            case when (select rate from c_tax where c_tax_id=ol.c_tax_id)>0 then
            ol.linegrossamt- ol.linegrossamt/(1+100/(select rate from c_tax where c_tax_id=ol.c_tax_id)) else
            ol.linegrossamt end else
            ol.linenetamt end 
            * case when ad_get_docbasetype(o.c_doctype_id) in ('ARC','APC') then -1 else 1 end 
            into p_ol_lineNetAmt 
            from c_orderline ol,c_order o where o.c_order_id=ol.c_order_id and ol.c_orderline_id=p_orderline_id;
            select case coalesce(c_order.totallines,0) when 0 then 1 else sum(c_order_paymentschedule.amount)/c_order.totallines end 
                  into v_partialAmountFactor from c_order_paymentschedule,c_order
                  where c_order.c_order_id=c_order_paymentschedule.c_order_id
                        and c_order.c_order_id = (select c_order_id from c_orderline where c_orderline_id=p_orderline_id)
                        and c_order_paymentschedule.c_invoice_id is null  and invoicedate between p_dateFrom and p_dateUntil
                  group by c_order.totallines;
    else
            v_partialAmountFactor:=1;
    end if;
    if p_ol_lineNetAmt is null then
        return 0;
    end if;
    -- Überfakturierung nicht ausweisen. (Bei negativen Auftragszeilen, umgekehrt rechnen) 
    if p_ol_lineNetAmt >= 0 and p_ol_lineNetAmt-v_invoiced < 0 then
       return 0;
    end if;
    if p_ol_lineNetAmt < 0 and p_ol_lineNetAmt-v_invoiced > 0 then      
       return 0;
    else
       RETURN c_currency_convert((coalesce(p_ol_lineNetAmt,0)*v_partialAmountFactor)-v_invoiced,v_curr,p_currency_id,v_dateordered); 
    end if;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_dropfunction('zssi_getinvoicedamt4orderlineByPeriod');
CREATE OR REPLACE FUNCTION zssi_getinvoicedamt4orderlineByPeriod(p_orderline_id character varying,p_currency_id VARCHAR, p_dateFrom TIMESTAMP, p_dateUntil TIMESTAMP)
  RETURNS numeric AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
  v_retval numeric:=0;
  v_curr varchar;
  v_dateordered timestamp;
BEGIN
    select o.c_currency_id,o.dateordered into v_curr,v_dateordered
         from c_order o,c_orderline ol where o.c_order_id=ol.c_order_id and ol.c_orderline_id=p_orderline_id;
    select  sum(case when c_invoice.isgrossinvoice='Y' then 
                                  case when (select rate from c_tax where c_tax_id=c_invoiceline.c_tax_id)>0 then
                                    c_invoiceline.linegrossamt- c_invoiceline.linegrossamt/(1+100/(select rate from c_tax where c_tax_id=c_invoiceline.c_tax_id)) else
                                    c_invoiceline.linegrossamt end else
                                c_invoiceline.linenetamt end 
                                * case when ad_get_docbasetype(c_invoice.c_doctype_id) in ('ARC','APC') then -1 else 1 end )
          into v_retval
            from c_invoiceline, c_invoice
            where c_invoiceline.c_invoice_id=c_invoice.c_invoice_id
                    and c_invoiceline.c_orderline_id=p_orderline_id
                    and c_invoice.docstatus = 'CO'
                    and c_invoice.dateinvoiced between p_dateFrom and p_dateUntil;
    return coalesce(v_retval,0);
   
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  
select zsse_dropfunction('zssi_getinvoicedamt4OrderDevidedByLinesByPeriod');
CREATE OR REPLACE FUNCTION zssi_getinvoicedamt4OrderDevidedByLinesByPeriod(p_orderline_id character varying, p_currency_id VARCHAR,p_dateFrom TIMESTAMP, p_dateUntil TIMESTAMP)
  RETURNS numeric AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
***************************************************************************************************************************************************/
  v_retval numeric:=0;
  v_numlines  numeric;
  v_curr varchar;
  v_dateordered TIMESTAMP;
BEGIN
    select c_currency_id,dateordered into v_curr,v_dateordered from c_order where c_order_id=(select c_order_id from c_orderline where c_orderline_id=p_orderline_id);
    select sum(case when c_invoice.isgrossinvoice='Y' then 
                                  case when (select rate from c_tax where c_tax_id=c_invoiceline.c_tax_id)>0 then
                                    c_invoiceline.linegrossamt- c_invoiceline.linegrossamt/(1+100/(select rate from c_tax where c_tax_id=c_invoiceline.c_tax_id)) else
                                    c_invoiceline.linegrossamt end else
                                c_invoiceline.linenetamt end 
                                * case when ad_get_docbasetype(c_invoice.c_doctype_id) in ('ARC','APC') then -1 else 1 end )
          into v_retval
            from c_invoiceline,c_invoice
            where c_invoiceline.c_orderline_id=p_orderline_id and c_invoiceline.c_invoice_id=c_invoice.c_invoice_id
                    and c_invoice.docstatus = 'CO'
                    and c_invoice.dateinvoiced between p_dateFrom and p_dateUntil;
    return c_currency_convert(coalesce(v_retval,0),v_curr,p_currency_id,v_dateordered);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Obsoleted Function  
select zsse_DropFunction('zssi_getPerformanceperiod4thiscycle');


CREATE OR REPLACE FUNCTION zssi_getNumberOfcycles4Subscription(p_order_id character varying)
  RETURNS numeric AS
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

*****************************************************/


  v_doctype character varying;
  v_frequence character varying;
  v_contractdate date;
  v_enddate date;
  v_i NUMERIC:=0;
BEGIN 
    select c_doctype_id,invoicefrequence,contractdate,enddate into v_doctype,v_frequence,v_contractdate,v_enddate from c_order where c_order_id=p_order_id;
    if v_doctype not in ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24')  then 
       return 1;
    else
        select c_getnumberofsubscriptionintervals (p_order_id, v_contractdate,v_frequence,v_enddate) into v_i;
    end if;
    RETURN v_i;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION zssi_getFirstInvoiceDate(contractdate timestamp without time zone,yearly_month character varying,invoicefrequence character varying,
                                                    weekly_day character varying ,monthly_day numeric ,quarterly_month character varying, isinvoiceafterfirstcycle character varying) 
returns timestamp without time zone as
$BODY$ DECLARE 
    v_interval interval;
    v_year numeric;
    v_month numeric;
    v_day numeric; 
    v_i numeric;
BEGIN
    if isinvoiceafterfirstcycle='Y' then
      select case invoicefrequence when 'MON' then INTERVAL '1 months' when 'YEAR' then INTERVAL '1 year' when 'QUARTER' then INTERVAL '3 month' when 'WEEK' then INTERVAL '1 week' end into v_interval;
    else 
      v_interval:=0;
    end if;
    v_year:=extract (year from contractdate);
    v_month:=extract (month from contractdate);
    v_day :=extract (day from contractdate);
    if invoicefrequence='MON' then
       return to_timestamp(to_char(coalesce(monthly_day,v_day))||'.'||to_char(v_month)||'.'||to_char(v_year),'dd.mm.yyyy') + v_interval;
    elsif invoicefrequence='QUARTER' then
       if quarterly_month is not null then
            v_month:=case EXTRACT(QUARTER FROM contractdate) when 1 then 0 when 2 then 3 when 3 then 6 else 9 end + to_number(quarterly_month);
       end if;
       return to_timestamp(to_char(coalesce(monthly_day,v_day))||'.'||to_char(v_month)||'.'||to_char(v_year),'dd.mm.yyyy') + v_interval;
    elsif invoicefrequence='WEEK' then 
       if weekly_day is not null then
           for v_i in 0..6 LOOP
             if extract(dow from contractdate + v_i) = to_number(weekly_day) then
                 return contractdate + v_i + v_interval;
             end if;
           end LOOP;
       else
           return contractdate + v_interval;
       end if;
    elsif invoicefrequence='YEAR' then
      return to_timestamp(to_char(coalesce(monthly_day,v_day))||'.'||to_char(coalesce(to_number(yearly_month),v_month))||'.'||to_char(v_year),'dd.mm.yyyy') + v_interval;
    end if;
    RETURN null;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION zssi_updateordervalues()
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
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************
Updates existing order and orderline values
*****************************************************/
v_doctype_id varchar(32);
v_qtydelivered numeric;
v_qtyinvoiced numeric;
v_invoicedamt numeric;
v_qtyreserved numeric;
v_totalpaid numeric;
v_invoicedamt_order numeric;
v_ispaid character(1);

v_cur RECORD;
BEGIN
        -- Update c_orderline (qtyreserved)
        -- select m_product.name,c_order.documentno,qtyreserved,qtyordered,qtydelivered 
   alter table c_orderline disable trigger user;
        update c_orderline set qtyreserved=qtyordered-qtydelivered where c_orderline_id in (
        select c_orderline_id
        from c_orderline,m_product,c_order 
        where c_order.c_order_id=c_orderline.c_order_id and c_order.docstatus='CO' 
        and m_product.m_product_id=c_orderline.m_product_id and qtyreserved!=qtyordered-qtydelivered and producttype='I' and isstocked='Y'
        and ad_get_docbasetype(c_order.c_doctype_id) in ('SOO','POO')
        );
        update c_orderline set qtyreserved=0 where c_orderline_id in (
        select c_orderline_id
        from c_orderline,m_product,c_order 
        where c_order.c_order_id=c_orderline.c_order_id and c_order.docstatus!='CO' 
        and m_product.m_product_id=c_orderline.m_product_id and producttype='I' and isstocked='Y'
        and ad_get_docbasetype(c_order.c_doctype_id) in ('SOO','POO')
        );
        -- m_storage_pending loeschen
        delete from m_storage_pending;
        -- m_storage_pending neu schreiben anhand der Order-Daten
        insert into m_storage_pending (
                        m_product_id,
                        m_warehouse_id,
                        m_attributesetinstance_id,
                        c_uom_id,
                        m_product_uom_id,
                        qtyreserved,
                        qtyorderreserved,
                        qtyordered,
                        qtyorderordered,
                        ad_client_id,
                        ad_org_id,
                        isactive,
                        created,
                        createdby,
                        updated,
                        updatedby,
                        m_storage_pending_id)
                select
                        c_orderline.m_product_id,
                        c_order.m_warehouse_id,
                        c_orderline.m_attributesetinstance_id,
                        c_orderline.c_uom_id,
                        null as m_product_uom_id,
                        (select sum(case c_order.issotrx when 'Y' then 1 else 0 end * (c_orderline.qtyordered - c_orderline.qtydelivered))) as qtyreserved,
                        null as qtyorderreserved,
                        (select sum(case c_order.issotrx when 'N' then 1 else 0 end * (c_orderline.qtyordered - c_orderline.qtydelivered))) as qtyordered,
                        null as qtyorderordered,
                        c_orderline.ad_client_id,
                        c_orderline.ad_org_id,
                        'Y' as isactive,
                        now() as created,
                        '0' as createdby,
                        now() as updated,
                        '0' as updatedby,
                        get_uuid() as m_storage_pending_id
                from 
                        c_orderline,c_order,m_product 
                where
                    c_orderline.c_order_id=c_order.c_order_id and
                        m_product.m_product_id=c_orderline.m_product_id and
                        m_product.isstocked='Y' and 
                        m_product.producttype='I' and 
                        c_orderline.deliverycomplete='N' and (c_orderline.qtyordered - c_orderline.qtydelivered)>0
                        and c_order.docstatus='CO'
--                         --Change Danny 
                group by
                        c_orderline.m_product_id,
                        c_order.m_warehouse_id,
                        c_orderline.m_attributesetinstance_id,
                        c_orderline.c_uom_id,
                        c_orderline.m_product_uom_id,
                        c_orderline.m_product_uom_id,
                        c_orderline.ad_client_id,
                        c_orderline.ad_org_id;
      alter table c_orderline enable trigger user;
END ; $BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;


select zsse_DropView ('c_subscriptioninterval_view');
create or replace view c_subscriptioninterval_view as 
select	c_order.c_order_id as c_subscriptioninterval_view_id,
		*
from 	c_order
where	c_order.c_doctype_id = '6C8EA6FFBB2B4ACBA0542BA4F833C499';


CREATE OR REPLACE FUNCTION c_generateorderfromtemplate (
  p_template_order_id VARCHAR,  -- source to copy from
  p_user_id VARCHAR
 )
RETURNS VARCHAR -- '@SUCCESS@'
AS $body$
-- called from java-class (no ad_pinstance): CopyOrderTemplateAttService.java
DECLARE
  v_message            VARCHAR := '';
  v_org_id             CHARACTER VARYING;
  v_now                TIMESTAMP := now();

  v_document_no        CHARACTER VARYING;
  v_target_doctype_id  CHARACTER VARYING;

  v_Inc_CurrentNext    CHAR(1) := 'Y';
  v_new_c_order_id     VARCHAR;

  v_order c_order%rowtype;
  v_orderline c_orderline%rowtype;
  v_zssi_order_textmodule zssi_order_textmodule%rowtype;

BEGIN -- 2012-06-21
  BEGIN

 -- part 1/5: c_order
    v_new_c_order_id := get_uuid();
    SELECT * INTO v_order FROM c_order WHERE c_order_id = p_template_order_id; -- read order-template into rowtype-buffer
    IF isempty(v_order.c_order_id) THEN
      RAISE EXCEPTION '%', '@OrderIdNotFound@'; -- GOTO EXCEPTION
    END IF;
    v_target_doctype_id := v_order.c_doctypetarget_id;

    v_document_no := (SELECT ad_sequence_doctype(v_target_doctype_id, v_order.ad_org_id, v_Inc_CurrentNext)); -- out-paramter : v_document_no by reference
    IF isempty(v_document_no) THEN
      RAISE EXCEPTION '%', '@DocumentTypeSequenceNotFound@'; -- GOTO EXCEPTION
    END IF;

    -- Unique changes before insert, all other changes after inserting orderlines, because of triggers
    v_order.orderselfjoin := null; -- v_order.c_order_id:deactivated 2012-06-21: FUNCTION c_generateorderfromoffer(): update c_order set generatetemplate ...where c_order_id=v_parentproposal
    v_order.c_order_id := v_new_c_order_id;
    v_order.created := v_now;
    v_order.createdby := p_user_id;
    v_order.updated := v_now;
    v_order.updatedby := p_user_id;
    v_order.c_doctype_id := v_target_doctype_id;
    v_order.c_doctypetarget_id := v_target_doctype_id;
    v_order.documentno := v_document_no;
    v_order.docstatus := 'DR'; -- draft
    v_order.processing := 'N';
    v_order.processed := 'N';
    v_order.dateordered := TRUNC(v_now);
    v_order.datepromised := NULL;
    v_order.dateacct := TRUNC(v_now); --?
    v_order.salesrep_id := p_user_id; -- lt. Notiz 671 aktiviert
    v_order.totallines := 0;
    v_order.grandtotal := 0;
  --v_order.ad_user_id := NULL; -- uebernehmen Ansprechpartner Auftraggeber
    v_order.qty := NULL;
   -- insert copy of template-order, update c_order after inserting c_orderlines
    INSERT INTO c_order SELECT v_order.*;              -- v_order c_order%rowtype

 -- part 2/5: c_orderlines
    -- get original orderlines from template order
    FOR v_orderline IN (SELECT * FROM c_orderline WHERE c_orderline.c_order_id = p_template_order_id) -- c_orderline%rowtype;
    LOOP
      -- Unique changes before insert, all other changes use update statement because of triggers
      v_orderline.ref_orderline_id := v_orderline.c_orderline_id;
      v_orderline.c_order_id := v_new_c_order_id;
      v_orderline.c_orderline_id := get_uuid();
      v_orderline.created := v_now;
      v_orderline.createdby := p_user_id;
      v_orderline.updated := v_now;
      v_orderline.updatedby := p_user_id;
      v_orderline.dateordered := now();
      v_orderline.datepromised := TRUNC(now());
      v_orderline.datedelivered := NULL;
      v_orderline.dateinvoiced := NULL;
  --  v_orderline.qtyreserved := 0;
  --  v_orderline.qtydelivered := 0;
  --  v_orderline.qtyinvoiced := 0;
      v_orderline.scheddeliverydate := NULL;
      INSERT INTO c_orderline SELECT v_orderline.*;
    END LOOP;

 -- part 3/5: textmodule
    DELETE FROM zssi_order_textmodule txtm WHERE txtm.c_order_id = v_new_c_order_id; -- durch Trigger erzeugte Zeilen loeschen
    FOR v_zssi_order_textmodule IN (SELECT * FROM zssi_order_textmodule txtm WHERE txtm.c_order_id = p_template_order_id) -- %rowtype
    LOOP
      v_zssi_order_textmodule.zssi_order_textmodule_id := get_uuid();
      v_zssi_order_textmodule.c_order_id := v_new_c_order_id;
      v_zssi_order_textmodule.created := v_now;
      v_zssi_order_textmodule.createdby := p_user_id;
      v_zssi_order_textmodule.updated := v_now;
      v_zssi_order_textmodule.updatedby := p_user_id;
      INSERT INTO zssi_order_textmodule SELECT v_zssi_order_textmodule.*;
    END LOOP;

 -- part 4/5: finally update for inserted c_order
    UPDATE c_order SET
    --datepromised = v_invoicedate,
    --contractdate = v_intervalstartdate,
    --enddate = v_intervalenddate - interval '1 day',
      totallinesonetime = 0,
      grandtotalonetime = 0
    WHERE
      c_order.c_order_id = v_new_c_order_id;

 -- part 5/5: finally housekeeping
    v_message = '@GenerateOrderFromTemplate@' || ' ' || v_document_no || ' ' || v_new_c_order_id; -- vgl. ad_message
    v_message := '@SUCCESS@' || ' ' || v_message; -- check structure for return in process class for sqlresult.splitt(" ")
    RAISE NOTICE '%', v_message;
    RETURN v_message;

  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_message := '@ProcessRunError@' || ' ' || SQLERRM || ' ' || 'c_generateorderfromtemplate';
  RAISE NOTICE '%', v_message;
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

/*------------------------------------------------------

Counting of subscription intervals

*/------------------------------------------------------

create or replace function c_getnumberofsubscriptionintervals (p_order_id character varying) returns numeric
as $_$
declare

	v_contractdate date;

begin	
select
	c_order.contractdate
into
	v_contractdate
from 
	c_order
where
	c_order.c_order_id = p_order_id;
return c_getnumberofsubscriptionintervals(p_order_id, v_contractdate);

end;
$_$  language 'plpgsql' volatile
cost 100;

-- SZ: Use Overloaded Function 
create or replace function c_getnumberofsubscriptionintervals (p_order_id character varying, p_startdate date) returns numeric
as $_$
declare

	v_invoicefrequence character varying;
	v_enddate date;
	v_return numeric:=0;

begin	
select
	c_order.invoicefrequence,
	c_order.enddate
into
	v_invoicefrequence,
	v_enddate
from 
	c_order
where
	c_order.c_order_id = p_order_id;
	
select c_getnumberofsubscriptionintervals(p_order_id, p_startdate,v_invoicefrequence,v_enddate) into v_return;

return v_return;
end;
$_$  language 'plpgsql' volatile
cost 100;

-- SZ: Overloaded Function needed in Before Update Trigger on C_Order
create or replace function c_getnumberofsubscriptionintervals (p_order_id character varying, p_startdate date,p_invoicefrequence character varying,p_enddate date ) returns numeric
as $_$
declare

        v_interval interval;
        v_halfintervalindays numeric;
        v_nextdate date;
        v_return numeric:=0;

begin   

v_nextdate := p_startdate;      
select 
        case p_invoicefrequence 
                when 'MON' then interval '1 months' 
                when 'YEAR' then interval '1 year' 
                when 'QUARTER' then interval '3 month' 
                when 'WEEK' then interval '1 week' 
        end 
into v_interval;
select 
        case p_invoicefrequence 
                when 'MON' then  15     -- more than 15 days at the end of subscription -> 1 more full subscription period
                when 'YEAR' then  182   -- more than 182 days at the end of subscription -> 1 more full subscription period
                when 'QUARTER' then 45  -- more than 45 days at the end of subscription -> 1 more full subscription period
                when 'WEEK' then 3              -- more than 3 days at the end of subscription -> 1 more full subscription period
        end 
into v_halfintervalindays;

-- Go forward from contract date in steps of the defined invoice interval and count the steps
-- as long as the next invoice date would be less than half a subscription period in the future.
while (p_enddate - v_nextdate + 1 > v_halfintervalindays) -- "+ 1" because enddate of subscription belongs to subscription
loop
        v_return := v_return + 1;
        v_nextdate := v_nextdate + v_interval;
end loop;

return v_return;
end;
$_$  language 'plpgsql' volatile
cost 100;

/*------------------------------------------------------

Create subscription sub-orders 
for each subscrpition interval 

*/------------------------------------------------------

create or replace function c_generatesubscriptionsuborders (p_order_id character varying) returns void
as $_$
declare
	
	v_contractdate date;
	
begin	
select
	c_order.contractdate
into
	v_contractdate
from 
	c_order
where
	c_order.c_order_id=p_order_id;

perform c_generatesubscriptionsuborders(p_order_id, v_contractdate);
end;
$_$  language 'plpgsql' volatile
  cost 100;

create or replace function c_generatesubscriptionsuborders (p_order_id character varying, p_startdate date) returns void
as $_$
declare

    v_invoicefrequence character varying;
    v_contractdate date;
    v_enddate date;
    v_yearly_month character varying;
    v_quarterly_month character varying;
    v_monthly_day numeric;
    v_weekly_day character varying;
    v_isinvoiceafterfirstcycle character varying;

    v_count numeric:=1;
    v_changecount numeric:=1;
    v_startdate date;
    v_numberofsubscriptionintervals numeric;
    v_interval interval;
    v_intervalstartdate date;
    v_intervalenddate date;
    v_intervalrealstartdate date;
    v_intervalrealenddate date;
    v_invoicedate date;
    v_dateordered date;
    v_nextinvoicedate date;
    v_order c_order%rowtype;
    v_orderline c_orderline%rowtype;
    v_onetimeorderline c_orderline%rowtype;
    v_subscriptionsuborderdocstatus character varying;
    v_order_id character varying;
    v_bpartner_id character varying;
    v_language character varying;
    v_isdailycharge varchar;
    v_docno varchar;
    v_endofIntervals  date;
    v_internalnote varchar;
    v_doctype varchar;
begin	
    select
        c_order.invoicefrequence,
        p_startdate,
        c_order.contractdate,
        c_order.enddate,
        c_order.yearly_month,
        c_order.quarterly_month,
        c_order.monthly_day,
        c_order.weekly_day,
        c_order.isinvoiceafterfirstcycle,
        c_order.c_bpartner_id,
        c_order.subsrdailyratebilling,
        c_order.documentno,
        c_order.internalnote,
        c_order.c_doctype_id,
        coalesce(c_order.subscriptionchangedate,c_order.dateordered)
    into
        v_invoicefrequence,
        v_startdate,
        v_contractdate,
        v_enddate,
        v_yearly_month,
        v_quarterly_month,
        v_monthly_day,
        v_weekly_day,
        v_isinvoiceafterfirstcycle,
        v_bpartner_id,
        v_isdailycharge,
        v_docno,
        v_internalnote,
        v_doctype,
        v_dateordered
    from 
        c_order
    where
        c_order.c_order_id=p_order_id;


    select
        COALESCE(ad_language, 'de_DE')
    into
        v_language
    from
        c_bpartner
    where
        c_bpartner.c_bpartner_id = v_bpartner_id;


    if v_startdate is null then
        v_startdate := v_contractdate;
    end if;
    
    v_interval := c_getsubscriptionfrequence(p_order_id);
    --daily Correction of Interval
    if  v_isdailycharge='Y' then
        v_intervalstartdate:= date_trunc('month',v_startdate);
    else
        v_intervalstartdate := zssi_getintervalstartdatebydate(p_order_id, v_startdate);
    end if;
    v_intervalenddate := v_intervalstartdate + v_interval;

    v_numberofsubscriptionintervals:= c_getnumberofsubscriptionintervals(p_order_id, v_intervalstartdate);
    v_invoicedate := zssi_getfirstinvoicedate(v_intervalstartdate, v_yearly_month, v_invoicefrequence, v_weekly_day, v_monthly_day, v_quarterly_month, v_isinvoiceafterfirstcycle);
    v_nextinvoicedate := v_invoicedate + v_interval;
    
    while exists (select * from c_order where c_order.orderselfjoin = p_order_id and documentno like ('%-' || v_changecount || '-%'))
    loop
        v_changecount := v_changecount + 1;
    end loop;

    --daily charge Versioning Document No.
    --if v_isdailycharge='Y' then
    select * into v_order from c_order where c_order_id = p_order_id;
    if instr(v_order.documentno,'-')>0 then
        update c_order set documentno=substr(documentno,1,instr(documentno,'-'))||v_changecount where c_order_id=p_order_id;
    end if;
    select documentno into v_docno from  c_order  where c_order_id=p_order_id;
    --end if;

    --daily Correction of Intervals
    if v_isdailycharge='Y' then
        v_endofIntervals:=date_trunc('month',v_intervalstartdate)+(v_interval*v_numberofsubscriptionintervals) -  interval '1 day' ;
        if date_trunc('month',v_endofIntervals)!=date_trunc('month',v_enddate) then
            v_numberofsubscriptionintervals:=v_numberofsubscriptionintervals+1;
        end if;
    end if;
    -- Loop through Intervals
    while v_count <= v_numberofsubscriptionintervals
    loop
        --daily ONLY Monthly Orders - All Orders have first and last Day of the Month.
        -- Get original subscription order values
        select * into v_order from c_order where c_order_id = p_order_id;
        -- Unique changes before insert, all other changes after inserting orderlines, because of triggers
        v_order.orderselfjoin := v_order.c_order_id;
        v_order.c_order_id := get_uuid();
        v_order.created := now();
        v_order.updated := now();
        v_order.processing := 'N';
        v_order.c_doctype_id := case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end;
        v_order.c_doctypetarget_id := case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end;
        v_order.documentno := v_docno ||'-' || v_count;
        v_order.transactiondate:=null;
        v_order.contractdate := v_intervalstartdate;
        v_order.enddate := v_intervalenddate - interval '1 day';
        v_order.dateordered:=v_dateordered;
        --daily charge -- Look if Order persists
        if (select count(*) from c_order where c_doctype_id= case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end
                and orderselfjoin= v_order.orderselfjoin and 
                contractdate = greatest(v_intervalstartdate,v_contractdate) and enddate = least(v_intervalenddate - interval '1 day',v_enddate)) >0 then
            select c_order_id,docstatus into v_order.c_order_id,v_order.docstatus from c_order where c_doctype_id= case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end
                and orderselfjoin= v_order.orderselfjoin and 
                contractdate = greatest(v_intervalstartdate,v_contractdate) and enddate = least(v_intervalenddate - interval '1 day',v_enddate);
            update c_order set documentno = v_docno|| '-' || v_count,updated = now() where c_order_id=v_order.c_order_id and docstatus='DR';
            --RAISE exception '%', 'Persist:----------------------------'||v_intervalstartdate||'#'||v_intervalenddate||'#'||v_startdate;
        else
            -- Insert copy of subscription order, changes after inserting orderlines 
            insert into c_order select v_order.*;
            --RAISE exception '%', 'INSERT:----------------------------'||v_intervalstartdate||'#'||v_intervalenddate||'#'||v_startdate;
        end if;
        if v_order.docstatus='DR' then
            -- Get original orderline values for each subscription order
            for v_orderline in (select * from c_orderline where c_orderline.c_order_id = p_order_id)
            loop
                -- Unique changes before insert, all other changes use update statement because of triggers
                v_orderline.ref_orderline_id := v_orderline.c_orderline_id;
                v_orderline.c_order_id := v_order.c_order_id;
                v_orderline.c_orderline_id := get_uuid();
                v_orderline.created := now();
                v_orderline.updated := now();
                v_orderline.c_uom_id := (select c_uom_id from m_product where m_product_id = v_orderline.m_product_id);
                v_orderline.pricelist:=v_orderline.PriceActual;
                -- Handling of one-time-positions without explicit invoice date
                if (v_orderline.isonetimeposition='Y' and v_orderline.datepromised is NULL and v_count = 1)
                    then 
                    v_orderline.datepromised := v_intervalstartdate;
                end if;
                -- Insert copy of orderlines, one-time-positions inserted into sub-order that fits one-time-position invoice date and only if not already handled
                if v_orderline.isonetimeposition = 'N' then-- Subscription position, always insert
                    -- Unchanged Pos. on daily Charge already exists. All others are created        
                    if (select count(*) from c_orderline where c_order_id=v_orderline.c_order_id and c_orderline.ref_orderline_id=v_orderline.ref_orderline_id and 
                            priceactual =v_orderline.priceactual and qtyordered=v_orderline.qtyordered and 
                            line=v_orderline.line and m_product_id=v_orderline.m_product_id)=0
                    then
                        --daily charge
                        if c_getpartlydaysfirst(v_order.orderselfjoin,v_order.c_order_id)>0 then
                            v_orderline.PriceActual:=round((v_orderline.PriceActual/c_daysinmonth(v_intervalstartdate))*c_getpartlydaysfirst(v_order.orderselfjoin,v_order.c_order_id),2);
                        elsif c_getpartlydayslast(v_order.orderselfjoin,v_order.c_order_id)>0 then
                            v_orderline.PriceActual:=round((v_orderline.PriceActual/c_daysinmonth(v_intervalstartdate))*c_getpartlydayslast(v_order.orderselfjoin,v_order.c_order_id),2);
                        elsif c_getpartlydaysleft(v_order.orderselfjoin,v_order.c_order_id)>0 then
                            v_orderline.PriceActual:=round((v_orderline.PriceActual/c_daysinmonth(v_intervalstartdate))*c_getpartlydaysleft(v_order.orderselfjoin,v_order.c_order_id),2);
                        end if;
                        insert into c_orderline select v_orderline.*;
                    end if;
                elsif -- One-time-position, check if this one-time position is already handled in older complete sub-orders 
                    (select count(*) from c_orderline where ref_orderline_id=v_orderline.ref_orderline_id)=0 
                    then 
                    if -- Insert into fitting sub-order
                        (v_orderline.isonetimeposition = 'Y' and v_orderline.datepromised >= v_invoicedate and v_orderline.datepromised < v_nextinvoicedate) or -- Invoice date of one-time-position is in an interval  
                        (v_orderline.isonetimeposition = 'Y' and v_orderline.datepromised < v_invoicedate and v_count = 1) or -- Invoice date of one-time-position before first subscription invoice date
                        (v_orderline.isonetimeposition = 'Y' and v_orderline.datepromised >= v_nextinvoicedate and v_count = v_numberofsubscriptionintervals) -- Invoice date of one-time-position after subscription enddate
                    then
                        insert into c_orderline select v_orderline.*;
                    end if;
                end if;
                -- Update
                update c_orderline set
                    isonetimeposition = 'N'
                where
                    c_orderline.c_orderline_id=v_orderline.c_orderline_id;
                --perform logg('I'||v_orderline.c_orderline_id||'#'||v_orderline.ref_orderline_id||'#'||v_orderline.priceactual||'#'||v_orderline.line||'#'||v_orderline.m_product_id||'#'||v_orderline.isonetimeposition);
            end loop;
        end if;
        --daily charge - shorter period 
        if v_isdailycharge='Y' and date_trunc('month',v_contractdate)= date_trunc('month',v_intervalstartdate) then
            v_intervalrealstartdate :=v_contractdate;
            v_intervalrealenddate :=v_intervalenddate - interval '1 day';
        elseif v_isdailycharge='Y' and date_trunc('month',v_enddate)= date_trunc('month',v_intervalstartdate) then
            v_intervalrealstartdate :=v_intervalstartdate;
            v_intervalrealenddate :=v_enddate;
        else
            v_intervalrealstartdate :=v_intervalstartdate;
            v_intervalrealenddate :=v_intervalenddate - interval '1 day';
        end if;
        -- Updating copies of subscrition order to make them sub-orders for each subscription interval
        update c_order set datepromised = null,scheddeliverydate = null  where c_order.c_order_id=v_order.c_order_id and docstatus='DR';
        update c_order set 
            internalnote = zssi_getElementTextByColumname('Interval', v_language) || ': ' || zssi_strdate(v_intervalrealstartdate, v_language) || ' - ' || zssi_strdate(v_intervalrealenddate , v_language) || E'\r\n' || E'\r\n' || coalesce(v_internalnote,''),
            datepromised = v_invoicedate,
            scheddeliverydate = v_intervalrealstartdate,
            contractdate = v_intervalrealstartdate,
            enddate = v_intervalrealenddate,
            totallinesonetime = 0,
            grandtotalonetime = 0,
            totalpaid = 0,
            invoicedamt = 0
        where 
            c_order.c_order_id=v_order.c_order_id and docstatus='DR';

        -- Prepare next loop
        v_count := v_count + 1;
        v_invoicedate := v_invoicedate + v_interval;
        v_nextinvoicedate := v_invoicedate + v_interval;
        v_intervalstartdate := v_intervalstartdate + v_interval;
        v_intervalenddate := v_intervalstartdate + v_interval;
    end loop;
end;
$_$  language 'plpgsql' volatile
cost 100;

/*------------------------------------------------------

Changing Docstatus of suborders

*/------------------------------------------------------

create or replace function c_postsuborders (p_order_id character varying, p_docstatus character varying) returns void
as $_$
declare

    v_order c_order%rowtype;
    v_orderline c_orderline%rowtype;
    v_changedate date;
    v_doctype varchar;

begin
select subscriptionchangedate,c_doctype_id into v_changedate,v_doctype from c_order where c_order_id = p_order_id;
for v_order in (select * from c_order where c_order.orderselfjoin = p_order_id and 
                                            c_order.c_doctype_id = case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end and
                                            c_order.docstatus = p_docstatus
                                            and case when p_docstatus!='DR' then c_order.enddate > coalesce(v_changedate,'-infinity'::timestamp) else 1=1 end)
loop
    begin
        perform c_order_post1(null, v_order.c_order_id);
    end;
end loop;
end;
$_$  language 'plpgsql' volatile
cost 100;    

create or replace function c_postsuborderswithaction (p_order_id character varying, p_action character varying) returns void
as $_$
declare

    v_order c_order%rowtype;
    v_orderline c_orderline%rowtype;
    v_changedate date;
    v_doctype varchar;
begin
select subscriptionchangedate,c_doctype_id into v_changedate,v_doctype from c_order where c_order_id = p_order_id;
for v_order in (select * from c_order where c_order.orderselfjoin = p_order_id and 
                                            c_order.c_doctype_id = case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end
                                            and c_order.enddate > coalesce(v_changedate,'-infinity'::timestamp))
loop
    begin
        update c_order set docaction = p_action where c_order.c_order_id = v_order.c_order_id;
        perform c_order_post1(null, v_order.c_order_id);
    end;
end loop;
end;
$_$  language 'plpgsql' volatile
cost 100;  

/*------------------------------------------------------

Delete sub-orders in case of re-activating the subscription 

*/------------------------------------------------------

create or replace function c_deletesuborders (p_order_id character varying) returns void
as $_$
declare

    v_order c_order%rowtype;
    v_orderline c_orderline%rowtype;
    v_changedate date;
    v_contractdate date;
    v_nextstartdate date;
    v_days numeric;
    v_mon numeric;
    v_yer numeric;
    v_doctype varchar;
    v_datefrom timestamp without time zone;
    v_dateto timestamp without time zone;
    v_daystoinvoice numeric;
begin
select contractdate ,c_doctype_id into v_contractdate , v_doctype from c_order where c_order_id = p_order_id;
select subscriptionchangedate into v_changedate from c_order where c_order_id = p_order_id;
select subscriptionchangedate into v_nextstartdate from c_order where c_order_id = p_order_id;

    
-- Delete all deleteable sub-Orders
for v_order in (select * from c_order where c_order.orderselfjoin = p_order_id and 
                                            c_order.c_doctype_id = case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end and 
                                            c_order.enddate > coalesce(v_changedate,'-infinity'::timestamp))
loop
    --raise notice '%','#########################################';
    --daily charge
    if c_getpartlydaysgone(p_order_id,v_order.c_order_id)>0 then
        for v_orderline in (select * from c_orderline where c_orderline.c_order_id = v_order.c_order_id order by line, created desc)
        loop
                v_days:=c_daysinmonth(v_changedate);
                -- If this is an Unchanged position in QTY, Product and Price , Calculate for the Days gone in the current month..
                -- If this is an Unchanged position in QTY, Product and Price , leave everything.
                if (select count(*) from c_orderline where c_order_id=p_order_id and c_orderline.c_orderline_id=v_orderline.ref_orderline_id and 
                    priceactual =v_orderline.priceactual and qtyordered=v_orderline.qtyordered and 
                    line=v_orderline.line and m_product_id=v_orderline.m_product_id)=0
                then
                    select trunc(max(desireddeliverydate)) into v_datefrom from c_orderline where c_order_id=v_order.c_order_id and line= v_orderline.line;
                    if v_datefrom is not null then
                        v_daystoinvoice:=c_getpartlydaysgone(p_order_id,v_order.c_order_id) - EXTRACT (DAY FROM v_datefrom);
                        --raise exception '%',v_daystoinvoice||'#'||v_datefrom;
                    else
                        v_daystoinvoice:=c_getpartlydaysgone(p_order_id,v_order.c_order_id);
                    end if;
                    -- Ändern ab 2x dasselbe Datum benutzt -> kein Änderungs-Tage festgestellt -> D.h die Reguläre Zeile ( desireddeliverydate is null) kann gelöscht werden.
                    if v_daystoinvoice!=0 then
                        update c_orderline set desireddeliverydate=v_changedate-1,
                           priceactual=round((pricelist/v_days)*v_daystoinvoice,2) where c_orderline_id = v_orderline.c_orderline_id
                           and desireddeliverydate is null;
                    else
                        delete from c_orderline where c_orderline_id = v_orderline.c_orderline_id and desireddeliverydate is null;
                    end if;
                    --perform logg('UP:'||v_orderline.c_orderline_id||'#'||coalesce(v_days,0)||'#DTI'||coalesce(v_daystoinvoice,0)||'#'||coalesce(v_datefrom,now()-3000));
                end if;
        end loop;
    else
        for v_orderline in (select * from c_orderline where c_orderline.c_order_id = v_order.c_order_id)
        loop
            begin
                delete from c_orderline where 
                    c_orderline.c_orderline_id = v_orderline.c_orderline_id; 
                exception when others then null;
            end;
        end loop;
        begin
            delete from c_order where c_order.c_order_id = v_order.c_order_id;
            exception when others then null;
        end;
    end if;
end loop;
end;
$_$  language 'plpgsql' volatile
  cost 100;  

/*------------------------------------------------------

Calculates No of Days in the current interval p_intervalorder_id 
If changedate on the Subsription is in the current interval the 
no of Days from the first day in interval till changedate are returned

*/------------------------------------------------------

create or replace function c_getpartlydaysgone (p_subsritionorder_id character varying,p_intervalorder_id character varying) returns numeric
as $_$
declare
begin
    return c_getpartlydays(p_subsritionorder_id ,p_intervalorder_id , 'gone');
end;
$_$  language 'plpgsql' volatile cost 100;

/*------------------------------------------------------

Calculates No of Days in the current interval p_intervalorder_id 
If changedate on the Subsription is in the current interval the 
no of Days till the last day in interval from changedate are returned

*/------------------------------------------------------

create or replace function c_getpartlydaysleft (p_subsritionorder_id character varying,p_intervalorder_id character varying) returns numeric
as $_$
declare
begin
    return c_getpartlydays(p_subsritionorder_id ,p_intervalorder_id , 'left');
end;
$_$  language 'plpgsql' volatile cost 100;

create or replace function c_getpartlydays(p_subsritionorder_id character varying,p_intervalorder_id character varying, p_leftorGone varchar) returns numeric
as $_$
declare
    v_changed timestamp without time zone;
    v_ibegin timestamp without time zone;
    v_iend timestamp without time zone;
    v_israte varchar;
begin
    select subscriptionchangedate,subsrdailyratebilling into v_changed,v_israte from c_order where c_order_id=p_subsritionorder_id;
    if v_changed is null or v_israte='N' then
        return 0;
    else
        select contractdate,enddate into v_ibegin,v_iend from  c_order where c_order_id=p_intervalorder_id;
        if v_changed between v_ibegin and v_iend then
            if p_leftorGone='gone' then
                return to_number(v_changed-v_ibegin);
            else
                return to_number(v_iend-v_changed)+1;
            end if;
        else
            return 0;
        end if;
    end if;
end;
$_$  language 'plpgsql' volatile cost 100;


/*------------------------------------------------------

Calculates No of Days in the first interval p_intervalorder_id 
If begindate on the Subsription does not meet the begin date of the 
first interval, the days from begindate in the subscricption till the last date of the first interval are returned.


*/------------------------------------------------------

create or replace function c_getpartlydaysfirst (p_subsritionorder_id character varying,p_intervalorder_id character varying) returns numeric
as $_$
declare
    v_first timestamp without time zone;
    v_ibegin timestamp without time zone;
    v_iend timestamp without time zone;
    v_israte varchar;
begin
    select contractdate,subsrdailyratebilling into v_first,v_israte from c_order  where c_order_id=p_subsritionorder_id;
    select contractdate,enddate into v_ibegin,v_iend from  c_order where c_order_id=p_intervalorder_id;
    if v_first between v_ibegin and v_iend and v_first!= v_ibegin and v_israte='Y' then
        return to_number(v_iend-v_first)+1;
    else
        return 0;
    end if;
end;
$_$  language 'plpgsql' volatile cost 100;

/*------------------------------------------------------

Calculates No of Days in the last interval p_intervalorder_id 
If enddate on the Subsription does not meet the end date of the 
last interval, the days from the begin date of the last interval till the enddate in the subscricption are returned.


*/------------------------------------------------------

create or replace function c_getpartlydayslast (p_subsritionorder_id character varying,p_intervalorder_id character varying) returns numeric
as $_$
declare
    v_last timestamp without time zone;
    v_ibegin timestamp without time zone;
    v_iend timestamp without time zone;
    v_israte varchar;
begin
    select enddate,subsrdailyratebilling into v_last,v_israte from c_order  where c_order_id=p_subsritionorder_id;
    select contractdate,enddate into v_ibegin,v_iend from  c_order where c_order_id=p_intervalorder_id;
    if v_last between v_ibegin and v_iend and v_last!= v_iend and v_israte='Y' then
        return to_number(v_last-v_ibegin)+1;
    else
        return 0;
    end if;
end;
$_$  language 'plpgsql' volatile cost 100;



/*------------------------------------------------------

Get subscription invoicefrequence as interval

*/------------------------------------------------------

create or replace function c_getsubscriptionfrequence (p_order_id character varying) returns interval
as $_$
declare

	v_invoicefrequence character varying;
	v_return interval;

begin
select
	c_order.invoicefrequence
into
	v_invoicefrequence
from 
	c_order
where
	c_order.c_order_id=p_order_id;

select 
	case v_invoicefrequence 
		when 'MON' then interval '1 months' 
		when 'YEAR' then interval '1 year' 
		when 'QUARTER' then interval '3 month' 
		when 'WEEK' then interval '1 week' 
	end 
into v_return;
return v_return;
end;
$_$  language 'plpgsql' volatile
  cost 100;
  
  
create or replace function zssi_getintervalstartdatebydate (p_order_id character varying, p_date date) returns date
as $_$
declare

v_contractdate date;
v_numberofsubscriptionintervals numeric;
v_count numeric :=1;
v_nextstartdate date;
v_return date;
v_doctype varchar;
begin

select
	c_order.contractdate,c_order.c_doctype_id
into
	v_contractdate,v_doctype
from 
	c_order
where
	c_order.c_order_id=p_order_id;

v_numberofsubscriptionintervals := c_getnumberofsubscriptionintervals(p_order_id, v_contractdate);
while v_count <= v_numberofsubscriptionintervals
loop
	if 	p_date >= v_contractdate and p_date < v_contractdate + c_getsubscriptionfrequence (p_order_id)
		then
		v_return := v_contractdate;
	end if;
	v_contractdate := v_contractdate + c_getsubscriptionfrequence (p_order_id);
	v_count := v_count + 1;
end loop;
select 
	coalesce(max(c_order.enddate + interval '1 day'), v_return)
into
	v_nextstartdate
from 
	c_order 
where 	
	c_order.orderselfjoin = p_order_id and 
	c_order.c_doctype_id = case when v_doctype='EAF34F4237D0488F923F218234509E24' then '52C79B0ABF04413DA133B71A3C6157A9' else '6C8EA6FFBB2B4ACBA0542BA4F833C499' end;
--if v_nextstartdate > v_return
--	then
--	v_return := v_nextstartdate + interval '1 day';
--end if;
return v_nextstartdate;
end;
$_$  language 'plpgsql' volatile
  cost 100; 

/*------------------------------------------------------

Interval view and rules

*/------------------------------------------------------
  
select zsse_dropview ('c_subscriptioninterval_view');
create or replace view c_subscriptioninterval_view as 
select	
	c_order.c_order_id as c_subscriptioninterval_view_id,
	c_order.orderselfjoin as c_order_id,
	c_order.ad_client_id as ad_client_id,
	c_order.ad_org_id as ad_org_id,
	c_order.isactive as isactive,
	c_order.created as created,
	c_order.createdby as createdby,
	c_order.updated as updated,
	c_order.updatedby as updatedby,
	c_order.issotrx as issotrx,
	c_order.documentno as documentno,
	c_order.docstatus as docstatus,
	c_order.docaction as docaction,
	c_order.processing as processing,
	c_order.processed as processed,
	c_order.c_doctype_id as c_doctype_id,
	c_order.c_doctypetarget_id as c_doctypetarget_id,
	c_order.description as description,
	c_order.isdelivered as isdelivered, -- SZ:Deprecated!
	c_order.isinvoiced as isinvoiced,
	c_order.isprinted as isprinted,
	c_order.isselected as isselected,
	c_order.salesrep_id as salesrep_id,
	c_order.dateordered  as dateordered,
	c_order.datepromised as datepromised,
	c_order.dateprinted as dateprinted,
	c_order.dateacct as dateacct,
	c_order.c_bpartner_id as c_bpartner_id,
	c_order.billto_id as billto_id,
	c_order.c_bpartner_location_id as c_bpartner_location_id,
	c_order.poreference as poreference, 
	c_order.isdiscountprinted as isdiscountprinted,
	c_order.c_currency_id as c_currency_id,
	c_order.paymentrule as paymentrule,
	c_order.c_paymentterm_id as c_paymentterm_id,
	c_order.invoicerule as invoicerule,
	c_order.deliveryrule as deliveryrule,
	c_order.freightcostrule as freightcostrule,
	c_order.freightamt as freightamt,
	c_order.deliveryviarule as deliveryviarule,
	c_order.m_shipper_id as m_shipper_id,
	c_order.c_charge_id as c_charge_id,
	c_order.chargeamt as chargeamt,
	c_order.priorityrule as priorityrule,
	c_order.totallines as totallines,
	c_order.grandtotal as grandtotal,
	c_order.m_warehouse_id as m_warehouse_id,
	c_order.m_pricelist_id as m_pricelist_id,
	c_order.istaxincluded  as istaxincluded,
	c_order.c_campaign_id as c_campaign_id,
	c_order.c_project_id as c_project_id,
	c_order.c_activity_id as c_activity_id,
	c_order.posted as posted,
	c_order.ad_user_id as ad_user_id,
	c_order.copyfrom as copyfrom,
	c_order.dropship_bpartner_id as dropship_bpartner_id,
	c_order.dropship_location_id as dropship_location_id,
	c_order.dropship_user_id as dropship_user_id,
	c_order.isselfservice as isselfservice,
	c_order.ad_orgtrx_id as ad_orgtrx_id,
	c_order.user1_id as user1_id,
	c_order.user2_id as user2_id,
	c_order.deliverynotes as deliverynotes, 
	c_order.c_incoterms_id as c_incoterms_id,
	c_order.incotermsdescription as incotermsdescription,
	c_order.generatetemplate as generatetemplate,
	c_order.delivery_location_id as delivery_location_id,
	c_order.copyfrompo as copyfrompo,
	c_order.c_bidproject_id as c_bidproject_id,
	c_order.c_projectphase_id as c_projectphase_id,
	c_order.c_projecttask_id as c_projecttask_id,
	c_order.a_asset_id as a_asset_id,
	c_order.m_product_id as m_product_id,
	c_order.weight as weight,
	c_order.qty as qty,
	c_order.weight_uom as weight_uom,
	c_order.bpzipcode as bpzipcode,
	c_order.generateproject as generateproject,
	c_order.closeproject as closeproject,
	c_order.estpropability as estpropability,
	c_order.name as name,
	c_order.proposalstatus  as proposalstatus,
	c_order.orderselfjoin as orderselfjoin,
	c_order.lostproposalreason as lostproposalreason,
	c_order.lostproposalfixedreason as lostproposalfixedreason,
	c_order.invoicefrequence as invoicefrequence,
	c_order.contractdate as contractdate,
	c_order.enddate as enddate,
	c_order.totallinesonetime as totallinesonetime,
	c_order.grandtotalonetime as grandtotalonetime,
	c_order.yearly_month as yearly_month,
	c_order.weekly_day as weekly_day,
	c_order.monthly_day as monthly_day,
	c_order.quarterly_month as quarterly_month,
	c_order.invoicedamt as invoicedamt,
	c_order.completeordervalue as completeordervalue,
	c_order.isinvoiceafterfirstcycle as isinvoiceafterfirstcycle,
	c_order.scheddeliverydate as scheddeliverydate,
	c_order.firstschedinvoicedate as firstschedinvoicedate,
	c_order.schedtransactiondate as schedtransactiondate,
	c_order.transactiondate as transactiondate,
	c_order.iscompletelyinvoiced as iscompletelyinvoiced,
	c_order.totalpaid as totalpaid,
	c_order.ispaid as ispaid,
	c_order.isrecharge as isrecharge,
	c_order.internalnote as internalnote,
	c_order.btncopytemplate as btncopytemplate,
	c_order.deliverycomplete
from 
	c_order
where	
	c_order.c_doctype_id in( '6C8EA6FFBB2B4ACBA0542BA4F833C499','52C79B0ABF04413DA133B71A3C6157A9') or 
	c_order.c_doctypetarget_id in ('6C8EA6FFBB2B4ACBA0542BA4F833C499','52C79B0ABF04413DA133B71A3C6157A9');

create or replace rule c_subscriptioninterval_view_insert as
on insert to c_subscriptioninterval_view do instead
insert into c_order (
	c_order_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	issotrx,
	documentno,
	docstatus,
	docaction,
	processing,
	processed,
	c_doctype_id,
	c_doctypetarget_id,
	description,
	isdelivered,
	isinvoiced,
	isprinted,
	isselected,
	salesrep_id,
	dateordered,
	datepromised,
	dateprinted,
	dateacct,
	c_bpartner_id,
	billto_id,
	c_bpartner_location_id,
	poreference,
	isdiscountprinted,
	c_currency_id,
	paymentrule,
	c_paymentterm_id,
	invoicerule,
	deliveryrule,
	freightcostrule,
	freightamt,
	deliveryviarule,
	m_shipper_id,
	c_charge_id,
	chargeamt,
	priorityrule,
	totallines,
	grandtotal,
	m_warehouse_id,
	m_pricelist_id,
	istaxincluded,
	c_campaign_id,
	c_project_id,
	c_activity_id,
	posted,
	ad_user_id,
	copyfrom,
	dropship_bpartner_id,
	dropship_location_id,
	dropship_user_id,
	isselfservice,
	ad_orgtrx_id,
	user1_id,
	user2_id,
	deliverynotes,
	c_incoterms_id,
	incotermsdescription,
	generatetemplate,
	delivery_location_id,
	copyfrompo,
	c_bidproject_id,
	c_projectphase_id,
	c_projecttask_id,
	a_asset_id,
	m_product_id,
	weight,
	qty,
	weight_uom,
	bpzipcode,
	generateproject,
	closeproject,
	estpropability,
	name,
	proposalstatus,
	orderselfjoin,
	lostproposalreason,
	lostproposalfixedreason,
	invoicefrequence,
	contractdate,
	enddate,
	totallinesonetime,
	grandtotalonetime,
	yearly_month,
	weekly_day,
	monthly_day,
	quarterly_month,
	invoicedamt,
	completeordervalue,
	isinvoiceafterfirstcycle,
	scheddeliverydate,
	firstschedinvoicedate,
	schedtransactiondate,
	transactiondate,
	iscompletelyinvoiced,
	totalpaid,
	ispaid,
	isrecharge,
	internalnote,
	btncopytemplate,
	deliverycomplete) 
 values (
	new.c_subscriptioninterval_view_id,
	new.ad_client_id,
	new.ad_org_id,
	new.isactive,
	new.created,
	new.createdby,
	new.updated,
	new.updatedby,
	new.issotrx,
	new.documentno,
	new.docstatus,
	new.docaction,
	new.processing,
	new.processed,
	new.c_doctype_id,
	new.c_doctypetarget_id,
	new.description,
	new.isdelivered,
	new.isinvoiced,
	new.isprinted,
	new.isselected,
	new.salesrep_id,
	new.dateordered,
	new.datepromised,
	new.dateprinted,
	new.dateacct,
	new.c_bpartner_id,
	new.billto_id,
	new.c_bpartner_location_id,
	new.poreference,
	new.isdiscountprinted,
	new.c_currency_id,
	new.paymentrule,
	new.c_paymentterm_id,
	new.invoicerule,
	new.deliveryrule,
	new.freightcostrule,
	new.freightamt,
	new.deliveryviarule,
	new.m_shipper_id,
	new.c_charge_id,
	new.chargeamt,
	new.priorityrule,
	new.totallines,
	new.grandtotal,
	new.m_warehouse_id,
	new.m_pricelist_id,
	new.istaxincluded,
	new.c_campaign_id,
	new.c_project_id,
	new.c_activity_id,
	new.posted,
	new.ad_user_id,
	new.copyfrom,
	new.dropship_bpartner_id,
	new.dropship_location_id,
	new.dropship_user_id,
	new.isselfservice,
	new.ad_orgtrx_id,
	new.user1_id,
	new.user2_id,
	new.deliverynotes,
	new.c_incoterms_id,
	new.incotermsdescription,
	new.generatetemplate,
	new.delivery_location_id,
	new.copyfrompo,
	new.c_bidproject_id,
	new.c_projectphase_id,
	new.c_projecttask_id,
	new.a_asset_id,
	new.m_product_id,
	new.weight,
	new.qty,
	new.weight_uom,
	new.bpzipcode,
	new.generateproject,
	new.closeproject,
	new.estpropability,
	new.name,
	new.proposalstatus,
	new.c_order_id,
	new.lostproposalreason,
	new.lostproposalfixedreason,
	new.invoicefrequence,
	new.contractdate,
	new.enddate,
	new.totallinesonetime,
	new.grandtotalonetime,
	new.yearly_month,
	new.weekly_day,
	new.monthly_day,
	new.quarterly_month,
	new.invoicedamt,
	new.completeordervalue,
	new.isinvoiceafterfirstcycle,
	new.scheddeliverydate,
	new.firstschedinvoicedate,
	new.schedtransactiondate,
	new.transactiondate,
	new.iscompletelyinvoiced,
	new.totalpaid,
	new.ispaid,
	new.isrecharge,
	new.internalnote,
	coalesce(new.btncopytemplate,'N'),
	new.deliverycomplete);
	
create or replace rule c_subscriptioninterval_view_update as
on update to c_subscriptioninterval_view do instead
update c_order set
	c_order_id = new.c_subscriptioninterval_view_id,
	ad_client_id = new.ad_client_id,
	ad_org_id = new.ad_org_id,
	isactive = new.isactive,
	created = new.created,
	createdby = new.createdby,
	updated = new.updated,
	updatedby = new.updatedby,
	issotrx = new.issotrx,
	documentno = new.documentno,
	docstatus = new.docstatus,
	docaction = new.docaction,
	processing = new.processing,
	processed = new.processed,
	c_doctype_id = new.c_doctype_id,
	c_doctypetarget_id = new.c_doctypetarget_id,
	description = new.description,
	isdelivered = new.isdelivered,
	isinvoiced = new.isinvoiced,
	isprinted = new.isprinted,
	isselected = new.isselected,
	salesrep_id = new.salesrep_id,
	dateordered = new.dateordered,
	datepromised = new.datepromised,
	dateprinted = new.dateprinted,
	dateacct = new.dateacct,
	c_bpartner_id = new.c_bpartner_id,
	billto_id = new.billto_id,
	c_bpartner_location_id = new.c_bpartner_location_id,
	poreference = new.poreference,
	isdiscountprinted = new.isdiscountprinted,
	c_currency_id = new.c_currency_id,
	paymentrule = new.paymentrule,
	c_paymentterm_id = new.c_paymentterm_id,
	invoicerule = new.invoicerule,
	deliveryrule = new.deliveryrule,
	freightcostrule = new.freightcostrule,
	freightamt = new.freightamt,
	deliveryviarule = new.deliveryviarule,
	m_shipper_id = new.m_shipper_id,
	c_charge_id = new.c_charge_id,
	chargeamt = new.chargeamt,
	priorityrule = new.priorityrule,
	totallines = new.totallines,
	grandtotal = new.grandtotal,
	m_warehouse_id = new.m_warehouse_id,
	m_pricelist_id = new.m_pricelist_id,
	istaxincluded = new.istaxincluded,
	c_campaign_id = new.c_campaign_id,
	c_project_id = new.c_project_id,
	c_activity_id = new.c_activity_id,
	posted = new.posted,
	ad_user_id = new.ad_user_id,
	copyfrom = new.copyfrom,
	dropship_bpartner_id = new.dropship_bpartner_id,
	dropship_location_id = new.dropship_location_id,
	dropship_user_id = new.dropship_user_id,
	isselfservice = new.isselfservice,
	ad_orgtrx_id = new.ad_orgtrx_id,
	user1_id = new.user1_id,
	user2_id = new.user2_id,
	deliverynotes = new.deliverynotes,
	c_incoterms_id = new.c_incoterms_id,
	incotermsdescription = new.incotermsdescription,
	generatetemplate = new.generatetemplate,
	delivery_location_id = new.delivery_location_id,
	copyfrompo = new.copyfrompo,
	c_bidproject_id = new.c_bidproject_id,
	c_projectphase_id = new.c_projectphase_id,
	c_projecttask_id = new.c_projecttask_id,
	a_asset_id = new.a_asset_id,
	m_product_id = new.m_product_id,
	weight = new.weight,
	qty = new.qty,
	weight_uom = new.weight_uom,
	bpzipcode = new.bpzipcode,
	generateproject = new.generateproject,
	closeproject = new.closeproject,
	estpropability = new.estpropability,
	name = new.name,
	proposalstatus = new.proposalstatus,
	orderselfjoin = new.orderselfjoin,
	lostproposalreason = new.lostproposalreason,
	lostproposalfixedreason = new.lostproposalfixedreason,
	invoicefrequence = new.invoicefrequence,
	contractdate = new.contractdate,
	enddate = new.enddate,
	totallinesonetime = new.totallinesonetime,
	grandtotalonetime = new.grandtotalonetime,
	yearly_month = new.yearly_month,
	weekly_day = new.weekly_day,
	monthly_day = new.monthly_day,
	quarterly_month = new.quarterly_month,
	invoicedamt = new.invoicedamt,
	completeordervalue = new.completeordervalue,
	isinvoiceafterfirstcycle = new.isinvoiceafterfirstcycle,
	scheddeliverydate = new.scheddeliverydate,
	firstschedinvoicedate = new.firstschedinvoicedate,
	schedtransactiondate = new.schedtransactiondate,
	transactiondate = new.transactiondate,
	iscompletelyinvoiced = new.iscompletelyinvoiced,
	totalpaid = new.totalpaid,
	ispaid = new.ispaid,
	isrecharge = new.isrecharge,
	internalnote = new.internalnote,
	btncopytemplate = new.btncopytemplate,
	deliverycomplete=new.deliverycomplete
where
	c_order.c_order_id = new.c_subscriptioninterval_view_id;

create or replace rule c_subscriptioninterval_view_delete as
on delete to c_subscriptioninterval_view do instead
delete from c_order where
	c_order.c_order_id = old.c_subscriptioninterval_view_id;

/*------------------------------------------------------

Intervallines view and rules

*/------------------------------------------------------

select zsse_dropview ('c_subscriptionintervallines_view');
create or replace view c_subscriptionintervallines_view as
select
	c_orderline.c_orderline_id as c_subscriptionintervallines_view_id,
	c_orderline.c_orderline_id as c_orderline_id,
	c_orderline.ad_client_id as ad_client_id,
	c_orderline.ad_org_id as ad_org_id,
	c_orderline.isactive as isactive,
	c_orderline.created as created,
	c_orderline.createdby as createdby,
	c_orderline.updated as updated,
	c_orderline.updatedby as updatedby,
	c_orderline.c_order_id as c_subscriptioninterval_view_id,
	c_orderline.c_order_id as c_order_id,
	c_orderline.line as line,
	c_orderline.c_bpartner_id as c_bpartner_id,
	c_orderline.c_bpartner_location_id as c_bpartner_location_id,
	c_orderline.dateordered as dateordered,
	c_orderline.datepromised as datepromised,
	c_orderline.datedelivered as datedelivered,
	c_orderline.dateinvoiced as dateinvoiced,
	c_orderline.description as description,
	c_orderline.m_product_id as m_product_id,
	c_orderline.m_warehouse_id as m_warehouse_id,
	c_orderline.directship as directship,
	c_orderline.c_uom_id as c_uom_id,
	c_orderline.qtyordered as qtyordered,
	c_orderline.qtyreserved as qtyreserved,
	c_orderline.qtydelivered as qtydelivered,
	c_orderline.qtyinvoiced as qtyinvoiced,
	c_orderline.m_shipper_id as m_shipper_id,
	c_orderline.c_currency_id as c_currency_id,
	c_orderline.pricelist as pricelist,
	c_orderline.priceactual as priceactual,
	c_orderline.pricelimit as pricelimit,
	c_orderline.linenetamt as linenetamt,
	c_orderline.discount as discount,
	c_orderline.freightamt as freightamt,
	c_orderline.c_charge_id as c_charge_id,
	c_orderline.chargeamt as chargeamt,
	c_orderline.c_tax_id as c_tax_id,
	c_orderline.s_resourceassignment_id as s_resourceassignment_id,
	c_orderline.ref_orderline_id as ref_orderline_id,
	c_orderline.m_attributesetinstance_id as m_attributesetinstance_id,
	c_orderline.quantityorder as quantityorder,
	c_orderline.m_product_uom_id as m_product_uom_id,
	c_orderline.m_offer_id as m_offer_id,
	c_orderline.pricestd as pricestd,
	c_orderline.cancelpricead as cancelpricead,
	c_orderline.linegrossamt as linegrossamt,
	c_orderline.linetaxamt as linetaxamt,
	c_orderline.isgrossprice as isgrossprice,
	c_orderline.c_project_id as c_project_id,
	c_orderline.c_projectphase_id as c_projectphase_id,
	c_orderline.c_projecttask_id as c_projecttask_id,
	c_orderline.a_asset_id as a_asset_id,
	c_orderline.issummaryitem as issummaryitem,
	c_orderline.invoicedamt as invoicedamt,
	c_orderline.ignoreresidue as ignoreresidue,
	c_orderline.scheddeliverydate as scheddeliverydate,
	c_orderline.deliverycomplete,
	c_orderline.desireddeliverydate
from 
	c_orderline
where 
	(select c_doctype_id from c_order where c_order.c_order_id = c_orderline.c_order_id) in ( '6C8EA6FFBB2B4ACBA0542BA4F833C499','52C79B0ABF04413DA133B71A3C6157A9');

create or replace rule c_subscriptionintervallines_view_insert as
on insert to c_subscriptionintervallines_view do instead
insert into c_orderline (
	c_orderline_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	c_order_id,
	line,
	c_bpartner_id,
	c_bpartner_location_id,
	dateordered,
	datepromised,
	datedelivered,
	dateinvoiced,
	description,
	m_product_id,
	m_warehouse_id,
	directship,
	c_uom_id,
	qtyordered,
	qtyreserved,
	qtydelivered,
	qtyinvoiced,
	m_shipper_id,
	c_currency_id,
	pricelist,
	priceactual,
	pricelimit,
	linenetamt,
	discount,
	freightamt,
	c_charge_id,
	chargeamt,
	c_tax_id,
	s_resourceassignment_id,
	ref_orderline_id,
	m_attributesetinstance_id,
	quantityorder,
	m_product_uom_id,
	m_offer_id,
	pricestd,
	cancelpricead,
	linegrossamt,
	linetaxamt,
	isgrossprice,
	c_project_id,
	c_projectphase_id,
	c_projecttask_id,
	a_asset_id,
	issummaryitem,
	invoicedamt,
	ignoreresidue,
	scheddeliverydate,
	deliverycomplete,
	desireddeliverydate) 
 values (
	new.c_subscriptionintervallines_view_id,
	new.ad_client_id,
	new.ad_org_id,
	new.isactive,
	new.created,
	new.createdby,
	new.updated,
	new.updatedby,
	new.c_subscriptioninterval_view_id,
	new.line,
	new.c_bpartner_id,
	new.c_bpartner_location_id,
	(select dateordered from c_order where c_order_id=new.c_subscriptioninterval_view_id),
	new.datepromised,
	new.datedelivered,
	new.dateinvoiced,
	new.description,
	new.m_product_id,
	new.m_warehouse_id,
	new.directship,
	new.c_uom_id,
	new.qtyordered,
	0,
	0,
	0,
	new.m_shipper_id,
	new.c_currency_id,
	new.pricelist,
	new.priceactual,
	0,
	new.linenetamt,
	new.discount,
	0,
	new.c_charge_id,
	new.chargeamt,
	new.c_tax_id,
	new.s_resourceassignment_id,
	new.ref_orderline_id,
	new.m_attributesetinstance_id,
	new.quantityorder,
	new.m_product_uom_id,
	new.m_offer_id,
	new.pricestd,
	new.cancelpricead,
	new.linegrossamt,
	new.linetaxamt,
	new.isgrossprice,
	new.c_project_id,
	new.c_projectphase_id,
	new.c_projecttask_id,
	new.a_asset_id,
	new.issummaryitem,
	new.invoicedamt,
	new.ignoreresidue,
	new.scheddeliverydate,
	new.deliverycomplete,
	new.desireddeliverydate);

create or replace rule c_subscriptionintervallines_view_update as
on update to c_subscriptionintervallines_view do instead
update c_orderline set
	c_orderline_id = new.c_subscriptionintervallines_view_id,
	ad_client_id = new.ad_client_id,
	ad_org_id = new.ad_org_id,
	isactive = new.isactive,
	created = new.created,
	createdby = new.createdby,
	updated = new.updated,
	updatedby = new.updatedby,
	c_order_id = new.c_subscriptioninterval_view_id,
	line = new.line,
	c_bpartner_id = new.c_bpartner_id,
	c_bpartner_location_id = new.c_bpartner_location_id,
	datepromised = new.datepromised,
	datedelivered = new.datedelivered,
	dateinvoiced = new.dateinvoiced,
	description = new.description,
	m_product_id = new.m_product_id,
	m_warehouse_id = new.m_warehouse_id,
	directship = new.directship,
	c_uom_id = new.c_uom_id,
	qtyordered = new.qtyordered,
	m_shipper_id = new.m_shipper_id,
	c_currency_id = new.c_currency_id,
	pricelist = new.pricelist,
	priceactual = new.priceactual,
	linenetamt = new.linenetamt,
	discount = new.discount,
	c_charge_id = new.c_charge_id,
	chargeamt = new.chargeamt,
	c_tax_id = new.c_tax_id,
	s_resourceassignment_id = new.s_resourceassignment_id,
	ref_orderline_id = new.ref_orderline_id,
	m_attributesetinstance_id = new.m_attributesetinstance_id,
	quantityorder = new.quantityorder,
	m_product_uom_id = new.m_product_uom_id,
	m_offer_id = new.m_offer_id,
	pricestd = new.pricestd,
	cancelpricead = new.cancelpricead,
	linegrossamt = new.linegrossamt,
	linetaxamt = new.linetaxamt,
	isgrossprice = new.isgrossprice,
	c_project_id = new.c_project_id,
	c_projectphase_id = new.c_projectphase_id,
	c_projecttask_id = new.c_projecttask_id,
	a_asset_id = new.a_asset_id,
	issummaryitem = new.issummaryitem,
	invoicedamt = new.invoicedamt,
	ignoreresidue = new.ignoreresidue,
	scheddeliverydate = new.scheddeliverydate,
	deliverycomplete=new.deliverycomplete,
	desireddeliverydate=new.desireddeliverydate
where
	c_orderline.c_orderline_id = new.c_subscriptionintervallines_view_id;

create or replace rule c_subscriptionintervallines_view_delete as
on delete to c_subscriptionintervallines_view do instead
delete from c_orderline where
	c_orderline.c_orderline_id = old.c_subscriptionintervallines_view_id;
	
/*------------------------------------------------------

Invoice to order referencing view and rules

*/------------------------------------------------------
	
select zsse_DropView ('c_refinvoicetoorder_view');
create or replace view c_refinvoicetoorder_view as
select
	c_invoice.c_invoice_id as c_refinvoicetoorder_view_id,
	c_invoice.c_invoice_id as c_invoice_id,
	c_invoice.ad_client_id as ad_client_id,
	c_invoice.ad_org_id as ad_org_id,
	c_invoice.isactive as isactive,
	c_invoice.created as created,
	c_invoice.createdby as createdby,
	c_invoice.updated as updated,
	c_invoice.updatedby as updatedby,
	c_invoice.issotrx as issotrx,
	c_invoice.documentno as documentno,
	c_invoice.docstatus as docstatus,
	c_invoice.docaction as docaction,
	c_invoice.processing as processing,
	c_invoice.processed as processed,
	c_invoice.posted as posted,
	c_invoice.c_doctype_id as c_doctype_id,
	c_invoice.c_doctypetarget_id as c_doctypetarget_id,
	c_invoice.c_order_id as c_order_id,
	c_invoice.description as description,
	c_invoice.isprinted as isprinted,
	c_invoice.salesrep_id as salesrep_id,
	c_invoice.dateinvoiced as dateinvoiced,
	c_invoice.dateprinted as dateprinted,
	c_invoice.dateacct as dateacct,
	c_invoice.c_bpartner_id as c_bpartner_id,
	c_invoice.c_bpartner_location_id as c_bpartner_location_id,
	c_invoice.poreference as poreference,
	c_invoice.isdiscountprinted as isdiscountprinted,
	c_invoice.dateordered as dateordered,
	c_invoice.c_currency_id as c_currency_id,
	c_invoice.paymentrule as paymentrule,
	c_invoice.c_paymentterm_id as c_paymentterm_id,
	c_invoice.c_charge_id as c_charge_id,
	c_invoice.chargeamt as chargeamt,
	c_invoice.totallines as totallines,
	c_invoice.grandtotal as grandtotal,
	c_invoice.m_pricelist_id as m_pricelist_id,
	c_invoice.istaxincluded as istaxincluded,
	c_invoice.c_campaign_id as c_campaign_id,
	c_invoice.c_project_id as c_project_id,
	c_invoice.c_activity_id as c_activity_id,
	c_invoice.createfrom as createfrom,
	c_invoice.generateto as generateto,
	c_invoice.ad_user_id as ad_user_id,
	c_invoice.copyfrom as copyfrom,
	c_invoice.isselfservice as isselfservice,
	c_invoice.ad_orgtrx_id as ad_orgtrx_id,
	c_invoice.user1_id as user1_id,
	c_invoice.user2_id as user2_id,
	c_invoice.withholdingamount as withholdingamount,
	c_invoice.taxdate as taxdate,
	c_invoice.c_withholding_id as c_withholding_id,
	c_invoice.ispaid as ispaid,
	c_invoice.totalpaid as totalpaid,
	c_invoice.outstandingamt as outstandingamt,
	c_invoice.daystilldue as daystilldue,
	c_invoice.dueamt as dueamt,
	c_invoice.lastcalculatedondate as lastcalculatedondate,
	c_invoice.updatepaymentmonitor as updatepaymentmonitor,
	c_invoice.isgrossinvoice as isgrossinvoice,
	c_invoice.writeoffamt as writeoffamt,
	c_invoice.discountamt as discountamt,
	c_invoice.c_projectphase_id as c_projectphase_id,
	c_invoice.c_projecttask_id as c_projecttask_id,
	c_invoice.a_asset_id as a_asset_id,
	c_invoice.deliveryrule as deliveryrule,
	c_invoice.btnreinvoiceprojectexpenses as btnreinvoiceprojectexpenses,
	c_invoice.performanceperiodstart as performanceperiodstart,
	c_invoice.performanceperiodend as performanceperiodend,
	c_invoice.ispaymentshedulesummary as ispaymentshedulesummary,
	c_invoice.transactiondate as transactiondate,
	c_invoice.internalnote as internalnote,
	c_invoice.schedtransactiondate as schedtransactiondate 
from 
	c_invoice
left join c_order on c_order.c_order_id = c_invoice.c_order_id
where
	c_invoice.issotrx='Y' and
	(c_order.c_doctype_id = 'ABE2033C7A74499A9750346A83DE3307' or 
	c_invoice.c_order_id is null);
	
create or replace rule c_refinvoicetoorder_view_insert as
on insert to c_refinvoicetoorder_view do instead
insert into c_invoice (
	c_invoice_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	issotrx,
	documentno,
	docstatus,
	docaction,
	processing,
	processed,
	posted,
	c_doctype_id,
	c_doctypetarget_id,
	c_order_id,
	description,
	isprinted,
	salesrep_id,
	dateinvoiced,
	dateprinted,
	dateacct,
	c_bpartner_id,
	c_bpartner_location_id,
	poreference,
	isdiscountprinted,
	dateordered,
	c_currency_id,
	paymentrule,
	c_paymentterm_id,
	c_charge_id,
	chargeamt,
	totallines,
	grandtotal,
	m_pricelist_id,
	istaxincluded,
	c_campaign_id,
	c_project_id,
	c_activity_id,
	createfrom,
	generateto,
	ad_user_id,
	copyfrom,
	isselfservice,
	ad_orgtrx_id,
	user1_id,
	user2_id,
	withholdingamount,
	taxdate,
	c_withholding_id,
	ispaid,
	totalpaid,
	outstandingamt,
	daystilldue,
	dueamt,
	lastcalculatedondate,
	updatepaymentmonitor,
	isgrossinvoice,
	writeoffamt,
	discountamt,
	c_projectphase_id,
	c_projecttask_id,
	a_asset_id,
	deliveryrule,
	btnreinvoiceprojectexpenses,
	performanceperiodstart,
	performanceperiodend,
	ispaymentshedulesummary,
	transactiondate,
	internalnote,
	schedtransactiondate) 
 values (
	new.c_invoice_id,
	new.ad_client_id,
	new.ad_org_id,
	new.isactive,
	new.created,
	new.createdby,
	new.updated,
	new.updatedby,
	new.issotrx,
	new.documentno,
	new.docstatus,
	new.docaction,
	new.processing,
	new.processed,
	new.posted,
	new.c_doctype_id,
	new.c_doctypetarget_id,
	new.c_order_id,
	new.description,
	new.isprinted,
	new.salesrep_id,
	new.dateinvoiced,
	new.dateprinted,
	new.dateacct,
	new.c_bpartner_id,
	new.c_bpartner_location_id,
	new.poreference,
	new.isdiscountprinted,
	new.dateordered,
	new.c_currency_id,
	new.paymentrule,
	new.c_paymentterm_id,
	new.c_charge_id,
	new.chargeamt,
	new.totallines,
	new.grandtotal,
	new.m_pricelist_id,
	new.istaxincluded,
	new.c_campaign_id,
	new.c_project_id,
	new.c_activity_id,
	new.createfrom,
	new.generateto,
	new.ad_user_id,
	new.copyfrom,
	new.isselfservice,
	new.ad_orgtrx_id,
	new.user1_id,
	new.user2_id,
	new.withholdingamount,
	new.taxdate,
	new.c_withholding_id,
	new.ispaid,
	new.totalpaid,
	new.outstandingamt,
	new.daystilldue,
	new.dueamt,
	new.lastcalculatedondate,
	new.updatepaymentmonitor,
	new.isgrossinvoice,
	new.writeoffamt,
	new.discountamt,
	new.c_projectphase_id,
	new.c_projecttask_id,
	new.a_asset_id,
	new.deliveryrule,
	new.btnreinvoiceprojectexpenses,
	new.performanceperiodstart,
	new.performanceperiodend,
	new.ispaymentshedulesummary,
	new.transactiondate,
	new.internalnote,
	new.schedtransactiondate);

create or replace rule c_refinvoicetoorder_view_update as
on update to c_refinvoicetoorder_view do instead
update c_invoice set
	c_invoice_id = new.c_invoice_id,
	ad_client_id = new.ad_client_id,
	ad_org_id = new.ad_org_id,
	isactive = new.isactive,
	created = new.created,
	createdby = new.createdby,
	updated = new.updated,
	updatedby = new.updatedby,
	issotrx = new.issotrx,
	documentno = new.documentno,
	docstatus = new.docstatus,
	docaction = new.docaction,
	processing = new.processing,
	processed = new.processed,
	posted = new.posted,
	c_doctype_id = new.c_doctype_id,
	c_doctypetarget_id = new.c_doctypetarget_id,
	c_order_id = new.c_order_id,
	description = new.description,
	isprinted = new.isprinted,
	salesrep_id = new.salesrep_id,
	dateinvoiced = new.dateinvoiced,
	dateprinted = new.dateprinted,
	dateacct = new.dateacct,
	c_bpartner_id = new.c_bpartner_id,
	c_bpartner_location_id = new.c_bpartner_location_id,
	poreference = new.poreference,
	isdiscountprinted = new.isdiscountprinted,
	dateordered = new.dateordered,
	c_currency_id = new.c_currency_id,
	paymentrule = new.paymentrule,
	c_paymentterm_id = new.c_paymentterm_id,
	c_charge_id = new.c_charge_id,
	chargeamt = new.chargeamt,
	totallines = new.totallines,
	grandtotal = new.grandtotal,
	m_pricelist_id = new.m_pricelist_id,
	istaxincluded = new.istaxincluded,
	c_campaign_id = new.c_campaign_id,
	c_project_id = new.c_project_id,
	c_activity_id = new.c_activity_id,
	createfrom = new.createfrom,
	generateto = new.generateto,
	ad_user_id = new.ad_user_id,
	copyfrom = new.copyfrom,
	isselfservice = new.isselfservice,
	ad_orgtrx_id = new.ad_orgtrx_id,
	user1_id = new.user1_id,
	user2_id = new.user2_id,
	withholdingamount = new.withholdingamount,
	taxdate = new.taxdate,
	c_withholding_id = new.c_withholding_id,
	ispaid = new.ispaid,
	totalpaid = new.totalpaid,
	outstandingamt = new.outstandingamt,
	daystilldue = new.daystilldue,
	dueamt = new.dueamt,
	lastcalculatedondate = new.lastcalculatedondate,
	updatepaymentmonitor = new.updatepaymentmonitor,
	isgrossinvoice = new.isgrossinvoice,
	writeoffamt = new.writeoffamt,
	discountamt = new.discountamt,
	c_projectphase_id = new.c_projectphase_id,
	c_projecttask_id = new.c_projecttask_id,
	a_asset_id = new.a_asset_id,
	deliveryrule = new.deliveryrule,
	btnreinvoiceprojectexpenses = new.btnreinvoiceprojectexpenses,
	performanceperiodstart = new.performanceperiodstart,
	performanceperiodend = new.performanceperiodend,
	ispaymentshedulesummary = new.ispaymentshedulesummary,
	transactiondate = new.transactiondate,
	internalnote = new.internalnote,
	schedtransactiondate = new.schedtransactiondate
where
	c_invoice.c_invoice_id = new.c_invoice_id;


create or replace rule c_refinvoicetoorder_view_delete as
on delete to c_refinvoicetoorder_view do instead
delete from c_invoice where
	c_invoice.c_invoice_id = old.c_invoice_id;

/*------------------------------------------------------

Found in DB, not implemented in scripts ... FW

*/------------------------------------------------------
select zsse_DropView ('c_order_open');
create or replace view c_order_open as 
select 
	c_orderline.ad_client_id, 
	c_orderline.ad_org_id, 
	c_orderline.isactive, 
	c_orderline.created, 
	c_orderline.createdby, 
	c_orderline.updated, 
	c_orderline.updatedby, 
	c_order.c_order_id, 
	c_order.docstatus, 
	c_order.docaction, 
	c_order.c_doctype_id, 
	c_order.salesrep_id, 
	c_order.c_bpartner_id,
	c_order.c_bpartner_location_id, 
	c_order.ad_user_id, 
	c_order.poreference, 
	c_order.c_currency_id, 
	c_order.issotrx, 
	c_orderline.c_orderline_id, 
	c_orderline.dateordered, 
	c_orderline.datepromised, 
	c_orderline.m_product_id, 
	c_orderline.m_warehouse_id, 
	c_orderline.directship, 
	c_orderline.c_uom_id, 
	c_orderline.qtyordered, 
	c_orderline.qtyreserved, 
	c_orderline.qtydelivered, 
	c_orderline.qtyinvoiced, 
	c_orderline.priceactual, 
	c_orderline.qtyordered - c_orderline.qtydelivered as qtytodeliver, 
	c_orderline.qtyordered - c_orderline.qtyinvoiced as qtytoinvoice, 
	(c_orderline.qtyordered - c_orderline.qtyinvoiced) * c_orderline.priceactual as netamttoinvoice
from 
	c_order, 
	c_orderline
where 
	c_order.c_order_id = c_orderline.c_order_id and 
	(c_orderline.qtyordered <> c_orderline.qtydelivered or c_orderline.qtyordered <> c_orderline.qtyinvoiced);
	
select zsse_dropview ('c_order_header_vt');
create or replace view c_order_header_vt as 
select 
	o.ad_client_id, 
	o.ad_org_id, 
	o.isactive, 
	o.created, 
	o.createdby, 
	o.updated, 
	o.updatedby, 
	dt.ad_language, 
	o.c_order_id, 
	o.issotrx, 
	o.documentno, 
	o.docstatus, 
	o.c_doctype_id, 
	o.c_bpartner_id, 
	bp.value as bpvalue, 
	oi.c_location_id as org_location_id, 
	oi.taxid, 
	dt.printname as documenttype, 
	dt.documentnote as documenttypenote, 
	o.salesrep_id, 
	coalesce(ubp.name, u.name) as salesrep_name, 
	o.dateordered, 
	o.datepromised, 
	bpg.name as bpgreeting, 
	bp.name, 
	bp.name2, 
	bpcg.name as bpcontactgreeting, 
	bpc.title, 
	nullif(bpc.name, bp.name) as contactname, 
	bpl.c_location_id, 
	bp.referenceno, 
	o.description, 
	o.poreference, 
	o.c_currency_id, 
	pt.name as paymentterm, 
	pt.documentnote as paymenttermnote, 
	o.c_charge_id, 
	o.chargeamt, 
	o.totallines, 
	o.grandtotal, 
	o.m_pricelist_id, 
	o.istaxincluded, 
	o.c_campaign_id, 
	o.c_project_id, 
	o.c_activity_id, 
	o.m_shipper_id, 
	o.deliveryrule, 
	o.deliveryviarule, 
	o.priorityrule, 
	o.invoicerule
from c_order o
join c_doctype_trl dt on o.c_doctype_id = dt.c_doctype_id
join c_paymentterm_trl pt on o.c_paymentterm_id = pt.c_paymentterm_id and dt.ad_language = pt.ad_language
join c_bpartner bp on o.c_bpartner_id = bp.c_bpartner_id
left join c_greeting_trl bpg on bp.c_greeting_id = bpg.c_greeting_id and dt.ad_language = bpg.ad_language
join c_bpartner_location bpl on o.c_bpartner_location_id = bpl.c_bpartner_location_id
left join ad_user bpc on o.ad_user_id = bpc.ad_user_id
left join c_greeting_trl bpcg on bpc.c_greeting_id = bpcg.c_greeting_id and dt.ad_language = bpcg.ad_language
join ad_orginfo oi on o.ad_org_id = oi.ad_org_id
left join ad_user u on o.salesrep_id = u.ad_user_id
left join c_bpartner ubp on u.c_bpartner_id = ubp.c_bpartner_id;

select zsse_dropview ('c_order_header_v');
create or replace view c_order_header_v as 
select 
	o.ad_client_id, 
	o.ad_org_id, 
	o.isactive, 
	o.created, 
	o.createdby, 
	o.updated, 
	o.updatedby, 
	to_char('en_US') as ad_language, 
	o.c_order_id, o.issotrx, 
	o.documentno, o.docstatus, 
	o.c_doctype_id, 
	o.c_bpartner_id, 
	bp.value as bpvalue, 
	oi.c_location_id as org_location_id, 
	oi.taxid, dt.printname as documenttype, 
	dt.documentnote as documenttypenote, 
	o.salesrep_id, 
	coalesce(ubp.name, u.name) as salesrep_name, 
	o.dateordered, o.datepromised, 
	bpg.name as bpgreeting, 
	bp.name, 
	bp.name2, 
	bpcg.name as bpcontactgreeting, 
	bpc.title, 
	nullif(bpc.name, bp.name) as contactname, 
	bpl.c_location_id, 
	bp.referenceno, 
	o.description, 
	o.poreference, 
	o.c_currency_id, pt.name as paymentterm, 
	pt.documentnote as paymenttermnote, 
	o.c_charge_id, 
	o.chargeamt, 
	o.totallines, 
	o.grandtotal, 
	o.m_pricelist_id, 
	o.istaxincluded, 
	o.c_campaign_id, 
	o.c_project_id, 
	o.c_activity_id, 
	o.m_shipper_id, 
	o.deliveryrule, 
	o.deliveryviarule, 
	o.priorityrule, 
	o.invoicerule
from c_order o
join c_doctype dt on o.c_doctype_id = dt.c_doctype_id
join c_paymentterm pt on o.c_paymentterm_id = pt.c_paymentterm_id
join c_bpartner bp on o.c_bpartner_id = bp.c_bpartner_id
left join c_greeting bpg on bp.c_greeting_id = bpg.c_greeting_id
join c_bpartner_location bpl on o.c_bpartner_location_id = bpl.c_bpartner_location_id
left join ad_user bpc on o.ad_user_id = bpc.ad_user_id
left join c_greeting bpcg on bpc.c_greeting_id = bpcg.c_greeting_id
join ad_orginfo oi on o.ad_org_id = oi.ad_org_id
left join ad_user u on o.salesrep_id = u.ad_user_id
left join c_bpartner ubp on u.c_bpartner_id = ubp.c_bpartner_id;

/*------| Check if offer is relevant (Y/N) |-------------------------------------------*\
	Input: c_order_id
	Output: Y/N
	Description: Check if offer is relevant for reporting. In case of a offer
	with variants only the offer variant with highest estimated propability 
	(estpropability) is relevant. In case of two variants with equal propability
	the offer with the highest value is relevant.
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION c_isofferrelevant (p_order_id character varying)
RETURNS character varying AS $BODY$ 
DECLARE
	v_return character varying := 'Y';
	v_order c_order%rowtype;
	v_parentoffer_id character varying;
	v_estprop numeric;
	v_offervalue numeric;
	v_created timestamp without time zone;
	v_doctype_id character varying;
	v_processed character varying;
BEGIN 
	v_estprop := coalesce((select estpropability from c_order where c_order_id = p_order_id)::numeric, 0);
	v_offervalue := zssi_getvalue4ordercomplete(p_order_id);
	v_created := (select created from c_order where c_order_id = p_order_id);
	v_parentoffer_id := (coalesce((select orderselfjoin from c_order where c_order.c_order_id = p_order_id), p_order_id));
	v_doctype_id := (select c_doctype_id from c_order where c_order_id = p_order_id);
	v_processed := (select processed from c_order where c_order_id = p_order_id);
	-- if offer is part of an offer variant set
	if (v_parentoffer_id is not null and 
		exists(select 1 from c_order where c_order.c_order_id = v_parentoffer_id) and
		ad_get_docbasetype(v_doctype_id) in ('POREQUESTOFFER','SALESOFFER') and
		v_processed = 'Y') then
		-- look at all other variants of the input offer:
		for v_order in (	select * from c_order where
							ad_get_docbasetype(c_order.c_doctype_id) in ('POREQUESTOFFER','SALESOFFER') and -- is an offer
							c_order.processed = 'Y' and -- is not **new**
							(c_order.c_order_id = v_parentoffer_id or -- is the parent offer
							c_order.orderselfjoin = v_parentoffer_id) and -- or is a child offer
							c_order.c_order_id != p_order_id -- is not itsself
						)
		loop
			if 	(coalesce(v_order.estpropability::numeric, 0) > v_estprop) or
				(coalesce(v_order.estpropability::numeric, 0) = v_estprop and zssi_getvalue4ordercomplete(v_order.c_order_id) > v_offervalue) or
				(coalesce(v_order.estpropability::numeric, 0) = v_estprop and zssi_getvalue4ordercomplete(v_order.c_order_id) = v_offervalue and v_order.created > v_created)
			then
				v_return := 'N';
			end if;
		end loop;
	else
		v_return := 'N';
	end if;
	return v_return;
END; 
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Check if offer is relevant (Y/N)  |---------------------------------------\*--

select zsse_droptrigger('c_order_requisition_restriction_trg','c_order');

/*------| Purchase Order from Requisition Restrictions |-------------------------------*\
	Description:
	Restrictions if a Purchase Order is generated from a Requisition.
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION c_order_requisition_restriction_trg ()
RETURNS trigger AS $BODY$ 
DECLARE
	v_orderrequisitionrestriction character varying;
BEGIN
IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END IF;
if tg_op = 'UPDATE' then
	select c_getconfigoption('orderrequisitionrestriction', new.ad_org_id) into v_orderrequisitionrestriction;
	if(
		coalesce(v_orderrequisitionrestriction, 'N') = 'Y' and
		(new.c_doctype_id = 'B342FD5CA1C64E8BA25A0A6F6C98C7DA' or new.c_doctypetarget_id = 'B342FD5CA1C64E8BA25A0A6F6C98C7DA') and
		coalesce(old.salesrep_id, '0') <> coalesce(new.salesrep_id, '0') and
		exists(select 1 from m_requisitionorder where c_orderline_id in(select c_orderline_id from c_orderline where c_orderline.c_order_id = old.c_order_id))
	)then
		raise exception '%', 'Es liegt eine Bedarfsanforderung zu Grunde, der Einkaeufer kann nicht geaendert werden.';
	end if;
end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; 
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Purchase Order from Requisition Restrictions |-----------------------------\*--

CREATE TRIGGER c_order_requisition_restriction_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON c_order
  FOR EACH ROW
  EXECUTE PROCEDURE c_order_requisition_restriction_trg();
  
  
  
  
  
/*------------------------------------------------------

Frame Contract  view and rules

*/------------------------------------------------------

select zsse_dropview ('c_framecontractoverview');
create or replace view c_framecontractoverview as
select
        c_orderline.c_orderline_id as c_framecontractoverview_id,
        c_orderline.c_orderline_id as c_orderline_id,
        c_orderline.ad_client_id as ad_client_id,
        c_orderline.ad_org_id as ad_org_id,
        c_orderline.isactive as isactive,
        c_orderline.created as created,
        c_orderline.createdby as createdby,
        c_orderline.updated as updated,
        c_orderline.updatedby as updatedby,
        c_orderline.c_order_id as c_order_id,
        c_orderline.line as line,
        c_order.c_bpartner_id as c_bpartner_id,
        c_order.c_bpartner_location_id as c_bpartner_location_id,
        c_order.contractdate ,
        c_order.deliverycomplete,
        c_order.docstatus,
        c_order.enddate,
        c_order.documentno,
        c_order.issotrx,
        c_orderline.m_product_id as m_product_id,
        c_order.m_warehouse_id as m_warehouse_id,
        c_orderline.c_uom_id as c_uom_id,
        c_orderline.qtyordered as qtyordered,
        c_orderline.securityqty,
        c_orderline.calloffqty,
        c_orderline.qtyordered-coalesce(c_orderline.calloffqty,0) as qtyleft,
        c_orderline.priceactual as priceactual,
        c_orderline.linenetamt as linenetamt,
        c_orderline.c_project_id as c_project_id,
        c_orderline.c_projecttask_id as c_projecttask_id,
        c_orderline.a_asset_id as a_asset_id,
        c_order.documentno||'-'||(select name from c_bpartner where c_bpartner_id=c_order.c_bpartner_id)||'-'||(select name from m_product where m_product_id=c_orderline.m_product_id) as identdescription
        from 
        c_orderline,c_order
where 
        c_order.c_order_id=c_orderline.c_order_id and c_order.c_doctype_id in ('559A80F2E27742D4B2C476045F5C834F','56913A519BA94EB59DAE5BF9A82F5F7D');

    
select zsse_dropview ('c_framecalloffoverview');
create or replace view c_framecalloffoverview as
select
        c_orderline.c_orderline_id as  c_framecalloffoverview_id,
        c_orderline.c_orderline_id as c_orderline_id,
        c_orderline.orderlineselfjoin as c_framecontractoverview_id,
        c_orderline.ad_client_id as ad_client_id,
        c_orderline.ad_org_id as ad_org_id,
        c_orderline.isactive as isactive,
        c_orderline.created as created,
        c_orderline.createdby as createdby,
        c_orderline.updated as updated,
        c_orderline.updatedby as updatedby,
        c_orderline.c_order_id as c_order_id,
        c_orderline.line as line,
        c_order.dateordered ,
        c_order.deliverycomplete,
        c_order.docstatus,
        c_order.scheddeliverydate,
        c_order.documentno,
        c_order.issotrx,
        c_orderline.m_product_id as m_product_id,
        c_order.m_warehouse_id as m_warehouse_id,
        c_orderline.c_uom_id as c_uom_id,
        c_orderline.qtyordered as qtyordered,
        c_orderline.qtyordered as calloffqty,
        c_orderline.priceactual as priceactual,
        c_orderline.linenetamt as linenetamt,
        c_orderline.c_project_id as c_project_id,
        c_orderline.c_projecttask_id as c_projecttask_id,
        c_orderline.a_asset_id as a_asset_id,
        c_order.documentno||'-'||(select name from c_bpartner where c_bpartner_id=c_order.c_bpartner_id)||'-'||(select name from m_product where m_product_id=c_orderline.m_product_id) as identdescription
        from 
        c_orderline,c_order
where 
        c_order.c_order_id=c_orderline.c_order_id;

        
        

CREATE OR REPLACE FUNCTION c_createdropshiporder(p_pinstance_id character varying) RETURNS void
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.


*****************************************************/

v_Message  character varying:='';
v_cur                c_order%rowtype;
v_Record_ID varchar;
v_User varchar;
Cur_Parameter record;
v_new_order_id varchar;
v_documentno varchar;
v_pricelist varchar;
v_payterm varchar;
v_payrule varchar;
v_currency  varchar;
v_BPartner_Location_ID  varchar;
v_BillTo_ID  varchar;
p_Vendor_ID  varchar;
v_dummy varchar;
v_cur2 record;
v_curr_qty numeric;
BEGIN 
     --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    FOR Cur_Parameter IN
      (SELECT i.Record_ID, i.AD_User_ID, i.AD_Client_ID, i.AD_Org_ID,
        p.ParameterName, p.P_String, p.P_Number, p.P_Date
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo) LOOP
      IF (Cur_Parameter.ParameterName = 'C_BPartner_ID') THEN
        p_Vendor_ID := Cur_Parameter.P_String;
      END IF;
    END LOOP; -- Get Parameter
    -- Create Drop Ship Order
    select * from c_order into v_cur where c_order_id=v_Record_ID;
    v_new_order_id:=get_uuid();
    select p_documentno into  v_documentno from ad_sequence_doctype('EE19ABBDB5A94C519DAB11003320FC8E', v_cur.ad_org_id, 'Y') ;
    select po_pricelist_id,po_paymentterm_id,paymentrulepo into v_pricelist,v_payterm, v_payrule from c_bpartner where c_bpartner_id=p_Vendor_ID;
    select c_currency_id into v_currency from m_pricelist where m_pricelist_id=v_pricelist;
    SELECT MIN(C_BPARTNER_LOCATION_ID) INTO v_BPartner_Location_ID  FROM C_BPARTNER_LOCATION  WHERE ISACTIVE='Y'  AND ISSHIPTO='Y'  AND C_BPARTNER_ID=p_Vendor_ID;
    SELECT MIN(C_BPARTNER_LOCATION_ID) INTO v_BillTo_ID  FROM C_BPARTNER_LOCATION  WHERE ISACTIVE='Y'  AND ISBILLTO='Y'  AND C_BPARTNER_ID=p_Vendor_ID;
   
    INSERT INTO C_Order(c_order_id, ad_client_id, ad_org_id, createdby, updatedby,
                                documentno, docstatus, docaction,
                                c_doctype_id, c_doctypetarget_id, description, salesrep_id,
                                dateordered, dateacct, c_bpartner_id, c_bpartner_location_id, billto_id,
                                c_currency_id, paymentrule, c_paymentterm_id, invoicerule,
                                deliveryrule, freightcostrule, deliveryviarule, priorityrule,
                                m_warehouse_id, m_pricelist_id, c_project_id, deliverynotes,
                                c_projecttask_id, name, orderselfjoin,internalnote,issotrx)
                                VALUES
                                (v_new_order_id, v_cur.ad_client_id, v_cur.ad_org_id, v_user, v_user,
                                v_documentno, 'DR', 'CO',
                                'EE19ABBDB5A94C519DAB11003320FC8E', 'EE19ABBDB5A94C519DAB11003320FC8E', v_cur.description, v_cur.salesrep_id,
                                to_date(now()), to_date(now()), p_Vendor_ID, v_bpartner_location_id, v_billto_id,
                                v_currency, v_payrule, v_payterm, v_cur.invoicerule, 
                                v_cur.deliveryrule, v_cur.freightcostrule, v_cur.deliveryviarule, v_cur.priorityrule,
                                v_cur.m_warehouse_id, v_pricelist,     v_cur.c_project_id, v_cur.deliverynotes,
                                v_cur.c_projecttask_id, v_cur.name, v_cur.c_order_id,v_cur.internalnote,'N');
                                -- Create Order lines
    v_dummy:= c_copyorderlineswithref(v_Record_ID, v_new_order_id, v_user,'D');
    --RAISE NOTICE '%','++++++++++++++++++++++++++++++++'||coalesce(v_dummy,'#####') ;
    -- Delete Lines not provided by this vendor.
    delete from c_orderline where c_orderline.c_order_id=v_new_order_id and not exists
                (select 0 from m_product_po where c_orderline.m_product_id=m_product_po.m_product_id and m_product_po.c_bpartner_id=p_Vendor_ID);    
    delete from c_order_paymentschedule where c_order_id=v_new_order_id;
    -- Correction of Quantities
    for v_cur2 in (select ekl.qtyordered,ekl.ref_orderline_id 
                         from c_order ek,c_orderline ekl where ek.issotrx='N' and ek.orderselfjoin=v_Record_ID and ek.docstatus!='VO' and ekl.c_order_id=ek.c_order_id
                         and ek.c_order_id!=v_new_order_id)
    LOOP
        update c_orderline set qtyordered=qtyordered-v_cur2.qtyordered where c_order_id=v_new_order_id and ref_orderline_id=v_cur2.ref_orderline_id;
    END LOOP;
    delete from c_orderline where qtyordered<=0 and c_order_id=v_new_order_id;
    if (select count(*) from c_orderline where c_order_id=v_new_order_id)>0 then
        if c_getconfigoption('poactiveafterpurchaserun',v_cur.ad_org_id)='Y' then
            perform c_order_post1(null, v_new_order_id);
        end if;
        v_Message:= v_Message || '@DropShipOrderCreated@' || zsse_htmldirectlink('../PurchaseOrder/Header_Relation.html','document.frmMain.inpcOrderId', v_new_order_id, v_documentno) || '</br>';
    else
        delete from c_order where c_order_id=v_new_order_id;
    end if;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1 , v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_message ;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message) ;
  RETURN;
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_getcurrentvendor(p_productid varchar,p_orgid varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_return varchar;
BEGIN
    select c_bpartner_id into v_return from m_product_po po where po.m_product_id=p_productid and ad_org_id in ('0', p_orgid) ORDER BY COALESCE(po.qualityrating,0) DESC, updated DESC LIMIT 1;
RETURN v_return;
END;
$_$  LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION c_ordercandropship(p_orderid varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_return varchar;
BEGIN
    select case when count(*)>0 then 'TRUE' else 'FALSE' end into v_return from c_order o,c_orderline ol where
        o.c_order_id=p_orderid and o.c_order_id=ol.c_order_id and o.docstatus='CO' and ad_get_docbasetype(o.c_doctype_id) = 'SOO' and
        case when ol.directship='N' then  m_isinoutcandidate(ol.c_orderline_id)='Y' else 1=1 end
    and (select isdropshipper from c_bpartner where c_bpartner_id=c_getcurrentvendor(ol.m_product_id,ol.ad_org_id))='Y';
RETURN v_return;
END;
$_$  LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION c_orderhasdropship(p_orderid varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_cur record;
v_ek numeric;
BEGIN
    FOR v_cur in (select ol.c_order_id,ol.c_orderline_id,ol.qtyordered from c_order o,c_orderline ol where
        o.c_order_id=p_orderid and o.c_order_id=ol.c_order_id and o.docstatus='CO' and case when deliveryrule='R' then iscompletelyinvoiced='Y' else '1'='1' end
        and (select isdropshipper from c_bpartner where c_bpartner_id=c_getcurrentvendor(ol.m_product_id,ol.ad_org_id))='Y'
        and case when ol.directship='N' then  m_isinoutcandidate(ol.c_orderline_id)='Y' else 1=1 end)
    LOOP
        select sum(ekl.qtyordered) into v_ek from c_order ek,c_orderline ekl 
                             where ek.issotrx='N' and ek.orderselfjoin=v_cur.c_order_id and ek.docstatus!='VO' and ekl.c_order_id=ek.c_order_id 
                             and ekl.ref_orderline_id =v_cur.c_orderline_id;                         
        if coalesce(v_ek,0) < v_cur.qtyordered  then
            RETURN 'FALSE';
        end if;
    END LOOP;
RETURN 'TRUE';
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_orderdropshippartners(p_orderid varchar, p_bpartner_id OUT varchar, p_dummy OUT varchar) RETURNS SETOF RECORD
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020 OpenZ Software GmbH.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_cur record;
v_ek numeric;
BEGIN
    FOR v_cur in (select ol.c_order_id,ol.c_orderline_id,ol.qtyordered from c_order o,c_orderline ol where
        o.c_order_id=p_orderid and o.c_order_id=ol.c_order_id and o.docstatus='CO' and case when deliveryrule='R' then iscompletelyinvoiced='Y' else '1'='1' end
        and (select isdropshipper from c_bpartner where c_bpartner_id=c_getcurrentvendor(ol.m_product_id,ol.ad_org_id))='Y'
        and case when ol.directship='N' then  m_isinoutcandidate(ol.c_orderline_id)='Y' else 1=1 end)
    LOOP
        select sum(ekl.qtyordered) into v_ek from c_order ek,c_orderline ekl 
                             where ek.issotrx='N' and ek.orderselfjoin=v_cur.c_order_id and ek.docstatus!='VO' and ekl.c_order_id=ek.c_order_id 
                             and ekl.ref_orderline_id =v_cur.c_orderline_id;                         
        if coalesce(v_ek,0) < v_cur.qtyordered  then
            select c_getcurrentvendor(m_product_id,ad_org_id) into p_bpartner_id from c_orderline where c_orderline_id=v_cur.c_orderline_id;
            RETURN NEXT;
        end if;
    END LOOP;
END;
$_$  LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION c_orderneedsfreight(p_orderid varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2015 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_return varchar;
v_freight numeric;
BEGIN
    select freightamounthint into v_freight from c_orgconfiguration where ad_org_id=(select ad_org_id from c_order where c_order_id=p_orderid);
    if v_freight is null then
        select freightamounthint into v_freight from c_orgconfiguration where isactive='Y' and isstandard='Y';
    end if;
    if v_freight=0 then
        return 'N';
    end if;
    if (select count(*) from c_orderline ol,m_product p where p.m_product_id=ol.m_product_id and ol.c_order_id=p_orderid and p.isfreightproduct='Y')=0 then
        if (select grandtotal from c_order where c_order_id=p_orderid)< v_freight and (select grandtotal from c_order where c_order_id=p_orderid) > 0 then
            return 'Y';
        end if;
    end if;
RETURN 'N';
END;
$_$  LANGUAGE 'plpgsql';


select zsse_DropView ('m_product_po_manufacturer_view');
create or replace view m_product_po_manufacturer_view as
select  po.m_product_po_id,po.m_product_po_id as m_product_po_manufacturer_view_id,
 po.ad_client_id, po.ad_org_id, po.updated,po.created,po.isactive,po.createdby,po.updatedby, po.iscurrentvendor,
 po.m_product_id, po.c_bpartner_id,
 po.manufacturernumber, po.m_manufacturer_id,m.name||'-'||coalesce(po.manufacturernumber,'')::varchar(250) as name
 from  m_product_po po, m_manufacturer m where m.m_manufacturer_id=po.m_manufacturer_id and po.iscurrentvendor='Y';

select zsse_DropView ('m_product_po_view');
create or replace view m_product_po_view as
select  po.m_product_po_id as m_product_po_view_id,
 po.ad_client_id, po.ad_org_id, po.updated,po.created,po.isactive,po.createdby,po.updatedby, po.iscurrentvendor,
 po.m_product_id, po.c_bpartner_id,
 (select value||'-'||name from c_bpartner where c_bpartner.c_bpartner_id=po.c_bpartner_id)||
 coalesce((select '-'||name from c_uom where c_uom.c_uom_id=po.c_uom_id),'-')||
 coalesce((select '-'||name from m_manufacturer where m_manufacturer.m_manufacturer_id=po.m_manufacturer_id),'-')||
 coalesce('-'||po.manufacturernumber,'')::varchar(2000) as name
 from  m_product_po po ;
 
 
CREATE OR REPLACE FUNCTION c_createDocumentFromOrder(p_pinstance_id character varying)
  RETURNS void AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019, OpenZ Software GmbH. All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Copy of an Order Back to Create an Offer (process)

*****************************************************/
v_Record_ID  character varying;
v_targetdoc  varchar;
v_User       varchar;
v_message    varchar;
Cur_Parameter record;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID,createdby  into v_Record_ID,v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    -- Get Parameters
    FOR Cur_Parameter IN (SELECT i.Record_ID,p.ParameterName,p.P_String,p.P_Number, p.P_Date FROM AD_PINSTANCE i,AD_PINSTANCE_PARA p where i.AD_PInstance_ID=p.AD_PInstance_ID
                                 AND i.AD_PInstance_ID=p_PInstance_ID  ORDER BY p.SeqNo)
    LOOP
        if Cur_Parameter.ParameterName='c_doctype_id' then
            v_targetdoc:=Cur_Parameter.P_String;
        end if;
    END LOOP; -- Get Parameter
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    v_message:=c_createDocumentFromOrder0(v_targetdoc,v_Record_ID,v_User);
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
    

CREATE OR REPLACE FUNCTION c_createDocumentFromOrder_userexit(v_order_id varchar)
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
User-Exit for c_createDocumentFromOrder0 + c_createDocumentFromOrderPO
**/
DECLARE
v_return varchar:='';
BEGIN
RETURN v_return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_createDocumentFromOrder0(p_targettype varchar, p_srcorder_id varchar, p_user varchar)
  RETURNS varchar AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019, OpenZ Software GmbH. All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Copy of an Order Back to Create an Offer

*****************************************************/
v_message character varying:='';
v_password varchar;
v_cur_line  c_orderline%rowtype;
v_cur c_order%rowtype;
v_icur_line  c_invoiceline%rowtype;
v_icur c_invoice%rowtype;
v_curtm zssi_order_textmodule%rowtype;
v_orderid varchar:=get_uuid();
v_doctype varchar;
v_docno varchar;
v_linkWindow varchar;
v_issotrx varchar;
BEGIN
    if p_srcorder_id is null then return 'NULL'; end if;
    select * into v_cur from c_order where c_order_id=p_srcorder_id;
    select issotrx into v_issotrx from c_doctype where c_doctype_id=v_cur.c_doctype_id;
    if v_issotrx ='N' then
        if p_targettype='PROPOSAL' then
            v_doctype:='8CF74AC370B04133B54C44A12E084749'; -- Request for Quotation
        elsif p_targettype='ORDER' then
            v_doctype:='B342FD5CA1C64E8BA25A0A6F6C98C7DA'; -- Order PO
        else
           raise exception '%' , 'Selection not implemented';
        end if;
        v_linkWindow:='../PurchaseOrder/Header_Relation.html';
    end if;
    if v_issotrx ='Y' then
        if p_targettype='PROPOSAL' or p_targettype='CHANGEORDER' then
                if v_cur.c_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','7DE8D4B1B8824D36974E8064BBED5095') then -- Subscript. Order / Propos.
                    v_doctype:='7DE8D4B1B8824D36974E8064BBED5095'; -- Subscription Proposal
                else
                    v_doctype:='6557A8E827ED40BDAE66E4A78166A839';-- Proposal
                end if;
        elsif p_targettype='ORDER' then
             if v_cur.c_doctype_id in ('ABE2033C7A74499A9750346A83DE3307','7DE8D4B1B8824D36974E8064BBED5095') then  -- Subscript. Order / Propos.
                    v_doctype:='ABE2033C7A74499A9750346A83DE3307'; -- Subscription Order
                else
                    v_doctype:='5D5792C53FBA46E2988653B6DC9FE5B4';-- Standard Order (SO) 
                end if;   
        elseif p_targettype='PROFORMA' then
            v_doctype:='CCFE32E992B74157975E675458B844D1';
        else
             -- Instance spec in Refe: DoctypesFromOrderWithChange and DoctypesFromOrder
            select li.description into v_doctype from AD_Ref_Listinstance li,ad_ref_list l where l.AD_Ref_List_id=li.AD_Ref_List_id and 
                   l.ad_reference_id in ('FD2AF07A654C40E085295748F3F253A5','DA2DEEE7274448F7B0252A18EDD377CF') and  li.value=p_targettype;
            if (select count(*) from c_doctype where c_doctype_id=v_doctype)=0 then
                raise exception '%' , 'Selection not implemented';
            end if;
        end if;
        if p_targettype='PROFORMA' then
            v_linkWindow:='../SalesInvoice/Header_Relation.html';
        else
            v_linkWindow:='../SalesOrder/Header_Relation.html';
        end if;
    end if;
    if p_targettype!='PROFORMA' then
        v_cur.c_doctype_id=v_doctype;
        v_cur.c_doctypetarget_id:=v_doctype;
        select p_documentno into v_docno from ad_sequence_doctype(v_doctype, v_cur.ad_org_id, 'Y') ;
        v_cur.documentno:=v_docno;
        v_cur.docstatus:='DR';
        v_cur.docaction:='CO';
        v_cur.proposalstatus:='OP';
        v_cur.generatetemplate:='N';
        v_cur.processed='N';
        v_cur.dateordered:=trunc(now());
        v_cur.created:=now();
        v_cur.updated:=now();
        v_cur.createdby:=p_user;
        v_cur.updatedby:=p_user;
        v_cur.invoicedamt:=0;
        v_cur.dateacct:=trunc(now());
        v_cur.posted:='N';
        v_cur.iscompletelyinvoiced:='N';
        v_cur.c_order_id:=v_orderid;
        v_cur.totalpaid:=0;
        v_cur.createdbycopy:='Y';
        -- Dokuments in same TRX (SO or PO) schould not have a link to generating Document
        if p_targettype != 'CHANGEORDER' then
            v_cur.orderselfjoin:=null;
        else
            v_cur.orderselfjoin:=p_srcorder_id;
        end if;
        insert into c_order select v_cur.*;
        for v_cur_line in (select * from c_orderline where c_order_id=p_srcorder_id)
        LOOP
            v_cur_line.c_order_id:=v_orderid;
            v_cur_line.c_orderline_id:=get_uuid();
            v_cur_line.createdby:=p_user;
            v_cur_line.updatedby:=p_user;
            v_cur_line.created:=now();
            v_cur_line.updated:=now();
            v_cur_line.qtydelivered:=0;
            v_cur_line.qtyinvoiced:=0;
            v_cur_line.ignoreresidue:='N';
            v_cur_line.ignoreresiduedate:=null;
            v_cur_line.deliverycomplete:='N';
            v_cur_line.orderlineselfjoin:=null;
            v_cur_line.invoicedamt:=0;
            if p_targettype != 'PROPOSAL' or v_issotrx='N' then
                v_cur_line.isoptional:='N';
            end if;
            insert into c_orderline select v_cur_line.*;
        END LOOP;
        delete from zssi_order_textmodule where c_order_id=v_orderid;
        for v_curtm in (select * from zssi_order_textmodule where c_order_id=p_srcorder_id)
        LOOP
            v_curtm.c_order_id:=v_orderid;
            v_curtm.zssi_order_textmodule_id:=get_uuid();
            v_curtm.createdby:=p_user;
            v_curtm.updatedby:=p_user;
            insert into zssi_order_textmodule select v_curtm.*;
        END LOOP;
        v_Message:= v_Message || '@OfferFromOrderCreated@' || zsse_htmldirectlink(v_linkWindow,'document.frmMain.inpcOrderId', v_orderid, v_docno) || '</br>';
    else
       -- Proforma Invoice
       select * from c_invoice into v_icur limit 1;
       v_icur.ad_org_id:=v_cur.ad_org_id;
       v_icur.c_invoice_id:=v_orderid;
       v_icur.createdby:=p_user;
       v_icur.created:=now();
       v_icur.updatedby:=p_user;
       v_icur.updated:=now();
       v_icur.c_doctype_id=v_doctype;
       v_icur.internalnote:=null; --v_cur.internalnote;
       select p_documentno into v_docno from ad_sequence_doctype(v_doctype, v_cur.ad_org_id, 'Y') ;
       v_icur.documentno:=v_docno;
       v_icur.issotrx:=v_cur.issotrx;
       v_icur.docstatus:='DR';
       v_icur.docaction:='CO';
       v_icur.processed:='N';
       v_icur.posted:='N';
       v_icur.c_doctypetarget_id:=v_doctype;
       v_icur.c_order_id:=p_srcorder_id;
       v_icur.description:=v_cur.description;
       v_icur.salesrep_id:=v_cur.salesrep_id;
       v_icur.dateinvoiced:=trunc(now());
       v_icur.dateacct:=trunc(now());
       v_icur.c_bpartner_id:=v_cur.c_bpartner_id;
       v_icur.c_bpartner_location_id:=v_cur.c_bpartner_location_id;
       v_icur.poreference:=v_cur.poreference;
       v_icur.c_currency_id:=v_cur.c_currency_id;
       v_icur.paymentrule:=v_cur.paymentrule;
       v_icur.c_paymentterm_id:=v_cur.c_paymentterm_id;
       v_icur.m_pricelist_id:=v_cur.m_pricelist_id;
       v_icur.c_project_id:=v_cur.c_project_id;
       v_icur.ad_user_id:=v_cur.ad_user_id;
       v_icur.ispaid:='N';
       v_icur.c_projecttask_id:=v_cur.c_projecttask_id;
       v_icur.a_asset_id:=v_cur.a_asset_id;
       v_icur.performanceperiodstart:=null;
       v_icur.performanceperiodend:=null;
       v_icur.schedtransactiondate:=null;
       v_icur.c_dunning_id:=null;
       v_icur.dunningdate:=null;
       v_icur.c_salesregion_id:=v_cur.c_salesregion_id;
       v_icur.transactiondate:=null;
       v_icur.totalpaid:=0;
       v_icur.discountamt:=0;
       v_icur.writeoffamt:=0;
       insert into c_invoice select v_icur.*;
       -- Line
       select * from c_invoiceline into v_icur_line limit 1;
       v_icur_line.createdby:=p_user;
       v_icur_line.created:=now();
       v_icur_line.updatedby:=p_user;
       v_icur_line.updated:=now();
       v_icur_line.c_invoice_id:=v_orderid;
       v_icur_line.ad_org_id:=v_cur.ad_org_id;
       v_icur_line.m_inoutline_id:=null;
       -- Repair Order created Proforma with the Repair Product
       if v_cur.c_doctype_id='053BA9DFD8B54545AF45166B741BAD7C' then -- REpair Order
                v_icur_line.c_invoiceline_id:=get_uuid();
                v_icur_line.c_orderline_id:=null;
                v_icur_line.line:=10;
                v_icur_line.description:=(select description from m_product where m_product_id=v_cur.maintanace_product);
                if v_cur.maintanace_product is null then
                    raise exception '%','@needsmaintananceproduct@';
                end if;
                v_icur_line.m_product_id:=v_cur.maintanace_product;
                v_icur_line.qtyinvoiced:=1;
                v_icur_line.pricelist:=m_get_offers_price(trunc(now()),v_cur.c_bpartner_id,v_cur.maintanace_product,1.0,v_cur.m_pricelist_id);
                v_icur_line.priceactual:=m_get_offers_price(trunc(now()),v_cur.c_bpartner_id,v_cur.maintanace_product,1.0,v_cur.m_pricelist_id);
                v_icur_line.pricelimit:=m_get_offers_price(trunc(now()),v_cur.c_bpartner_id,v_cur.maintanace_product,1.0,v_cur.m_pricelist_id);
                v_icur_line.c_uom_id:=(select c_uom_id from m_product where m_product_id=v_cur.maintanace_product);
                v_icur_line.c_tax_id:=zsfi_GetTax(v_cur.c_bpartner_location_id,v_cur.maintanace_product,v_cur.ad_org_id);
                v_icur_line.m_attributesetinstance_id:=null;
                v_icur_line.quantityorder:=null;
                v_icur_line.m_product_uom_id:=null;
                v_icur_line.isgrossprice:=(select istaxincluded from m_pricelist where m_pricelist_id=v_cur.m_pricelist_id);
                v_icur_line.c_project_id:=v_cur.c_project_id;
                v_icur_line.c_projecttask_id:=v_cur.c_projecttask_id;
                v_icur_line.a_asset_id:=v_cur.a_asset_id;
                v_icur_line.textposition:='N';
                v_icur_line.ispagebreak:='N';
                v_icur_line.iscombined:='N';
                v_icur_line.ispricesuppressed:='N';
                insert into c_invoiceline select v_icur_line.*;
        
       else -- Proforma with all lines of order
        for v_cur_line in (select * from c_orderline where c_order_id=p_srcorder_id)
        LOOP
                v_icur_line.c_invoiceline_id:=get_uuid();
                v_icur_line.c_orderline_id:=v_cur_line.c_orderline_id;
                v_icur_line.line:=v_cur_line.line;
                v_icur_line.description:=v_cur_line.description;
                v_icur_line.m_product_id:=v_cur_line.m_product_id;
                v_icur_line.qtyinvoiced:=v_cur_line.qtyordered;
                v_icur_line.pricelist:=v_cur_line.pricelist;
                v_icur_line.priceactual:=v_cur_line.priceactual;
                v_icur_line.pricelimit:=v_cur_line.pricelimit;
                v_icur_line.c_uom_id:=v_cur_line.c_uom_id;
                v_icur_line.c_tax_id:=v_cur_line.c_tax_id;
                v_icur_line.m_attributesetinstance_id:=v_cur_line.m_attributesetinstance_id;
                v_icur_line.quantityorder:=v_cur_line.quantityorder;
                v_icur_line.m_product_uom_id:=v_cur_line.m_product_uom_id;
                v_icur_line.isgrossprice:=v_cur_line.isgrossprice;
                v_icur_line.c_project_id:=v_cur_line.c_project_id;
                v_icur_line.c_projecttask_id:=v_cur_line.c_projecttask_id;
                v_icur_line.a_asset_id:=v_cur_line.a_asset_id;
                v_icur_line.textposition:=v_cur_line.textposition;
                v_icur_line.ispagebreak:=v_cur_line.ispagebreak;
                v_icur_line.iscombined:=v_cur_line.iscombined;
                v_icur_line.ispricesuppressed:=v_cur_line.ispricesuppressed;
                insert into c_invoiceline select v_icur_line.*;
        END LOOP;
       end if;
       v_Message:= v_Message || '@ProformaCreated@' ||zsse_htmlLinkDirectKey(v_linkWindow, v_orderid,v_docno) || '</br>';
        
    end if;
    PERFORM c_createDocumentFromOrder_userexit(v_orderid);
  RETURN v_Message;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_createDocumentFromOrderPO(p_targettype varchar, p_srcorder_id varchar, p_user varchar)
  RETURNS varchar AS
$BODY$ 
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019, OpenZ Software GmbH. All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Copy of an Order Back to Create an Offer

*****************************************************/
v_message character varying:='';
v_password varchar;
v_cur_line  c_orderline%rowtype;
v_cur c_order%rowtype;
v_icur_line  c_invoiceline%rowtype;
v_icur c_invoice%rowtype;
v_curtm zssi_order_textmodule%rowtype;
v_orderid varchar:=get_uuid();
v_doctype varchar;
v_docno varchar;
v_linkWindow varchar;

BEGIN
    if p_srcorder_id is null then return 'NULL'; end if;
    select * into v_cur from c_order where c_order_id=p_srcorder_id;
    if (select count(*) from c_doctype where c_doctype_id=v_cur.c_doctype_id and issotrx ='N')=1 then
        if p_targettype='QUOTATION' then
            v_doctype:='8CF74AC370B04133B54C44A12E084749'; -- Request for Quotation
        elsif p_targettype='ORDERPO' then
            v_doctype:='B342FD5CA1C64E8BA25A0A6F6C98C7DA'; -- Order PO
        else
            -- Instance spec in Refe: DoctypesFromPOOrder
            select li.description into v_doctype from AD_Ref_Listinstance li,ad_ref_list l where l.AD_Ref_List_id=li.AD_Ref_List_id and 
                   l.ad_reference_id='54DAE887EA0E48F0A8DD6C4DADFFF94F' and  li.value=p_targettype;
            if (select count(*) from c_doctype where c_doctype_id=v_doctype)=0 then
                raise exception '%' , 'Selection not implemented';
            end if;
        end if;
        v_linkWindow:='../PurchaseOrder/Header_Relation.html';
    end if;
    v_cur.c_doctype_id=v_doctype;
    v_cur.c_doctypetarget_id:=v_doctype;
    select p_documentno into v_docno from ad_sequence_doctype(v_doctype, v_cur.ad_org_id, 'Y') ;
    v_cur.documentno:=v_docno;
    v_cur.docstatus:='DR';
    v_cur.docaction:='CO';
    v_cur.proposalstatus:='OP';
    v_cur.generatetemplate:='N';
    v_cur.processed='N';
    v_cur.dateordered:=trunc(now());
    v_cur.createdby:=p_user;
    v_cur.updatedby:=p_user;
    v_cur.invoicedamt:=0;
    v_cur.dateacct:=trunc(now());
    v_cur.posted:='N';
    v_cur.iscompletelyinvoiced:='N';
    v_cur.c_order_id:=v_orderid;
    v_cur.totalpaid:=0;
    v_cur.createdbycopy:='Y';
    -- Dokuments in same TRX (SO or PO) schould not have a link to generating Document
    v_cur.orderselfjoin:=null;
    insert into c_order select v_cur.*;
    for v_cur_line in (select * from c_orderline where c_order_id=p_srcorder_id)
    LOOP
        v_cur_line.c_order_id:=v_orderid;
        v_cur_line.c_orderline_id:=get_uuid();
        v_cur_line.createdby:=p_user;
        v_cur_line.updatedby:=p_user;
        v_cur_line.qtydelivered:=0;
        v_cur_line.qtyinvoiced:=0;
        v_cur_line.invoicedamt:=0;
        v_cur_line.ignoreresidue:='N';
        v_cur_line.ignoreresiduedate:=null;
        v_cur_line.deliverycomplete:='N';
        v_cur_line.orderlineselfjoin:=null;
        v_cur_line.isoptional:='N';
        insert into c_orderline select v_cur_line.*;
    END LOOP;
    delete from zssi_order_textmodule where c_order_id=v_orderid;
    for v_curtm in (select * from zssi_order_textmodule where c_order_id=p_srcorder_id)
    LOOP
        v_curtm.c_order_id:=v_orderid;
        v_curtm.zssi_order_textmodule_id:=get_uuid();
        v_curtm.createdby:=p_user;
        v_curtm.updatedby:=p_user;
        insert into zssi_order_textmodule select v_curtm.*;
    END LOOP;
    v_Message:= v_Message || '@OfferFromOrderCreated@' || zsse_htmldirectlink(v_linkWindow,'document.frmMain.inpcOrderId', v_orderid, v_docno) || '</br>';
    PERFORM c_createDocumentFromOrder_userexit(v_orderid);
  RETURN v_Message;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION c_subscriptionofferchangeexisting(p_orderid varchar,showfield varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019  2019, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_bp varchar;
v_dc varchar;
v_n varchar;
v_osl varchar;
v_cd date;
v_bp2 varchar;
v_dc2 varchar;
v_n2 varchar;
v_doctype varchar;
v_docorigin varchar;
v_orderorigin varchar; 
v_linked varchar;
BEGIN
    select c_bpartner_id,coalesce(to_char(contractdate,'dd.mm.yyyy'),'NON'),coalesce(name,'NON'),orderselfjoin,trunc(subscriptionchangedate) ,c_doctype_id
            into v_bp,v_dc,v_n,v_osl,v_cd,v_doctype from c_order where c_order_id=p_orderid and c_doctype_id in ('7DE8D4B1B8824D36974E8064BBED5095','ABE2033C7A74499A9750346A83DE3307');
    v_linked:=v_osl;
    while v_linked is not null
    LOOP
        select c_bpartner_id,coalesce(to_char(contractdate,'dd.mm.yyyy'),'NON'),coalesce(name,'NON'),c_doctype_id,orderselfjoin,c_order_id
            into v_bp2,v_dc2,v_n2,v_docorigin,v_osl,v_orderorigin from c_order where c_order_id=v_linked;
        if v_docorigin = 'ABE2033C7A74499A9750346A83DE3307' then
            v_linked:=null;
        else
            v_linked:=v_osl;
        end if;
    END LOOP;
    if showfield='Y' then
        if v_doctype = 'ABE2033C7A74499A9750346A83DE3307' then
            return 'TRUE';
        end if;
        if v_bp=v_bp2 and v_dc=v_dc2 and v_n=v_n2 then
            return 'TRUE';
        else
            return 'FALSE';
        end if;
    else
        if v_bp=v_bp2 and v_dc=v_dc2 and v_n=v_n2 and v_cd is not null then
            return v_orderorigin;
        else
            return 'FALSE';
        end if;
    end if;
RETURN 'FALSE';
END;
$_$  LANGUAGE 'plpgsql';



  
CREATE OR REPLACE FUNCTION c_createDocumentHeaderFromSO(p_orderid varchar,p_targettype varchar,p_bpartner varchar,p_user varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
    v_Client varchar:='C726FEC915A54A0995C568555DA5BB3C';
    v_orderid varchar;
    v_docno varchar;
    v_doctypetarget varchar;
    v_currency varchar;
    v_paymentrule varchar;
    v_payterm varchar;
    v_invrule varchar:='I';
    v_delrule varchar:='A';
    v_deliveryviarule varchar:='D';
    v_warehouse varchar;
    v_pricelist varchar;
    v_istaxincluded varchar;
    v_org_Id varchar;
    v_bill2location varchar;
    v_location varchar;
    v_freightcostrule varchar:='I';
    v_incoterms varchar;
    v_prj varchar;
    v_prjt varchar;
BEGIN
    if p_orderid is null then return 'COMPILE'; end if;
    select ad_org_id,m_warehouse_id,c_project_id,c_projecttask_id into v_org_Id, v_warehouse,v_prj,v_prjt from c_order where c_order_id=p_orderid;
    v_orderid:=get_uuid();
    if p_targettype = 'POORDER' then
        v_doctypetarget:='B342FD5CA1C64E8BA25A0A6F6C98C7DA'; -- Order (PO)
    end if;
    if p_targettype = 'POOFFER' then
        v_doctypetarget:='8CF74AC370B04133B54C44A12E084749';--Request for Quotation
    end if;
    select p_documentno into  v_docno from ad_sequence_doctype(v_doctypetarget, v_org_Id, 'Y') ;
    
    select b.po_pricelist_id,b.po_paymentterm_id,b.paymentrulepo, p.c_currency_id , p.istaxincluded,b.c_incoterms_id into v_pricelist,v_payterm,v_paymentrule,v_currency,v_istaxincluded,v_incoterms
    from c_bpartner b, m_pricelist p where p.m_pricelist_id=b.po_pricelist_id and b.c_bpartner_id=p_bpartner;
    if v_pricelist is null then
        select b.m_pricelist_id,b.c_paymentterm_id,b.paymentrule,b.c_incoterms_id,p.c_currency_id , p.istaxincluded into v_pricelist,v_payterm,v_paymentrule,v_incoterms,v_currency,v_istaxincluded
               from zssi_smartinvoiceprefs b,m_pricelist p where p.m_pricelist_id=b.m_pricelist_id and
                     invoicetype = case when p_targettype = 'POORDER' then 'POO' when p_targettype = 'POOFFER' then 'POQ' else 'SSO' end and b.isactive='Y' 
                     and p.isactive='Y' and b.ad_org_id in ('0', v_org_Id)
                     order by b.ad_org_id desc LIMIT 1;
    end if;
    select c_bpartner_location_id into v_bill2location from c_bpartner_location where c_bpartner_id=p_bpartner and isactive='Y' and isbillto='Y' order by isheadquarter desc,created desc limit 1;
    select c_bpartner_location_id into v_location from c_bpartner_location where c_bpartner_id=p_bpartner and isactive='Y' and isshipto='Y' order by isheadquarter desc,created desc limit 1;
	
    INSERT INTO C_Order
          (C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATEDBY, UPDATEDBY,
           ISSOTRX, DOCUMENTNO, DOCSTATUS, DOCACTION, PROCESSING, C_DOCTYPE_ID,C_DOCTYPETARGET_ID,
           DATEORDERED, DATEACCT, C_BPARTNER_ID, BILLTO_ID, C_BPARTNER_LOCATION_ID, C_CURRENCY_ID, PAYMENTRULE, C_PAYMENTTERM_ID,
           INVOICERULE, DELIVERYRULE, DELIVERYVIARULE, M_WAREHOUSE_ID, M_PRICELIST_ID,istaxincluded,freightcostrule,priorityrule,  c_incoterms_id, salesrep_id,orderselfjoin,
           c_project_id,c_projecttask_id)
         VALUES
           (v_orderid, v_Client, v_org_Id,'Y',p_user,p_user,
           'N' , v_docno,  'DR', 'CO','N','0',v_doctypetarget,
            trunc(now()),trunc(now()),p_bpartner,v_bill2location,v_location,v_currency,v_paymentrule,v_payterm,
            v_invrule,v_delrule,v_deliveryviarule,v_warehouse,v_pricelist,v_istaxincluded,v_freightcostrule,'5',  v_incoterms, p_user,p_orderid,
            v_prj,v_prjt);
RETURN v_orderid;
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_createDocumentLineFromSO(p_neworderid varchar,p_description varchar,p_qty varchar,p_sourceorderline_id varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
    v_cur_line                c_orderline%rowtype;
    v_user  varchar;
    v_bpartner varchar;
    v_dtype varchar;
    v_pricelist varchar;
    v_price numeric;
    v_Client varchar:='C726FEC915A54A0995C568555DA5BB3C';
    v_line numeric;
    v_loc varchar;
    v_curr varchar;
    v_wh varchar;
    v_tax varchar;
BEGIN
   if p_neworderid is null then return 'COMPILE'; end if;
   select createdby,c_doctype_id,c_bpartner_id,m_pricelist_id,c_bpartner_location_id,c_currency_id,m_warehouse_id
          into v_user,v_dtype,v_bpartner,v_pricelist,v_loc,v_curr,v_wh from c_order where c_order_id=p_neworderid;
          
   select * into v_cur_line from c_orderline where c_orderline_id=p_sourceorderline_id;
   -- Get Price
   if v_dtype='B342FD5CA1C64E8BA25A0A6F6C98C7DA' then -- PO-Order
        v_price:=m_get_offers_price(trunc(now()),v_bpartner,v_cur_line.m_product_id,v_cur_line.qtyordered,v_pricelist);
   else
        v_price:=0.00;
   end if;
   -- Get Tax
   v_tax:=zsfi_GetTax(v_loc,v_cur_line.m_product_id,v_cur_line.ad_org_id);
   -- Get Line
   select max(line)+10 into v_line from c_orderline where c_order_id=p_neworderid;
   if v_line is null then v_line:=10; end if;
   -- Insert Line
   INSERT INTO C_OrderLine (
          C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID,CREATEDBY, UPDATEDBY,
          C_ORDER_ID, LINE, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID,
          DATEORDERED, DESCRIPTION, M_PRODUCT_ID,
          M_ATTRIBUTESETINSTANCE_ID,
          M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED, C_CURRENCY_ID,
          PRICELIST, PRICEACTUAL,PRICESTD, 
          C_TAX_ID,c_project_id,c_projecttask_id,orderlineselfjoin,auxfield1
      ) VALUES (
         get_uuid(),v_Client,v_cur_line.ad_org_id,v_user,v_user,
         p_neworderid,v_line,v_bpartner,v_loc,
         trunc(now()),p_description,v_cur_line.m_product_id,v_cur_line.M_ATTRIBUTESETINSTANCE_ID,
         v_wh,v_cur_line.c_uom_id,to_number(p_qty),v_curr,v_price,v_price,v_price,
         v_tax,v_cur_line.c_project_id,v_cur_line.c_projecttask_id,v_cur_line.c_orderline_id,v_cur_line.auxfield1
      );
RETURN 'SUCESS';
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction('c_reqMgmtDocAction4POandSO');
CREATE OR REPLACE FUNCTION c_reqMgmtDocAction4POandSO(p_poorderid varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2021, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
    v_sorder varchar;
    v_act    varchar;
   
BEGIN
    -- Sync. Sales and PO (PO cannot be draft at beginning of update)
    select docaction,orderselfjoin into v_act,v_sorder from c_order where c_order_id=p_poorderid;
    if v_sorder is not null then
      if (select docstatus from c_order where c_order_id=p_poorderid)=(select docstatus from c_order where c_order_id=v_sorder and docaction!='RX')  then -- Leave Sale in Draft
        update c_order set docaction=v_act where c_order_id=v_sorder;
        PERFORM c_order_post1(null, v_sorder);
      else
        if (select docaction from c_order where c_order_id=v_sorder)!='RX' then
            update c_order set docaction='RX' where c_order_id=v_sorder;-- Mark sales is already draft
        else
            update c_order set docaction='CO' where c_order_id=v_sorder and docstatus='DR'; -- Set draft sales to get activate button
        end if;
      end if;
    end if;
    PERFORM c_order_post1(null, p_poorderid);
RETURN 'SUCESS';
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction('c_updateSalesLineFromPO');
CREATE OR REPLACE FUNCTION c_updateSalesLineFromPO(p_poorderlineid varchar,p_soorderlineid varchar,p_soprice varchar,p_isoptional varchar,p_deliverydate varchar,p_user varchar,p_description varchar,p_connectsoline varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
    v_order varchar;
    v_product varchar;
    v_ds    varchar;
    v_opt   varchar;
    v_desc  varchar;
    v_aux1  varchar;
    v_olc   c_orderline%rowtype;
    v_i     numeric:=1;
    v_line  numeric;
BEGIN
   if p_poorderlineid is null then return 'COMPILE'; end if;
   --raise exception '%',coalesce(p_soorderlineid,'NULL')||p_isoptional||p_connectsoline ; 
   if p_soorderlineid is null then
        -- Lost reference...
        select o.orderselfjoin,line into v_order,v_line from c_order o,c_orderline ol where ol.c_order_id=o.c_order_id and ol.c_orderline_id=p_poorderlineid;
        select c_orderline_id into p_soorderlineid from c_orderline where c_order_id=v_order and isoptional='N' and m_product_id=(select m_product_id from c_orderline where c_orderline_id=p_poorderlineid) and line=v_line  limit 1;
        if p_soorderlineid is null then
            select c_orderline_id into p_soorderlineid from c_orderline where c_order_id=v_order and isoptional='N' and m_product_id=(select m_product_id from c_orderline where c_orderline_id=p_poorderlineid) limit 1;
        end if;
        if p_soorderlineid is not null then
            update c_orderline set orderlineselfjoin=p_soorderlineid where c_orderline_id=p_poorderlineid;
        end if;
   end if;     
   if p_soorderlineid is null then
       RETURN 'NO REFERENCE FOUND'; 
   end if;  
   select o.c_order_id,o.docstatus,ol.isoptional into v_order,v_ds,v_opt from c_order o,c_orderline ol where ol.c_order_id=o.c_order_id and ol.c_orderline_id=p_soorderlineid;
   select description,auxfield1 into v_desc,v_aux1 from c_orderline where c_orderline_id=p_poorderlineid;
   if v_ds='CO' then
        update c_order set docaction='RE' where c_order_id=v_order;
        perform c_order_post1(null, v_order);
   end if;
   if p_isoptional='Y' and (select count(*) from c_orderline where isdescription='Y' and orderlineselfjoin=p_soorderlineid)=0 
                       and (select count(*) from c_orderline where isoptional='Y' and c_orderline_id=p_soorderlineid)=0 then 
        raise exception '%' , '@FirstOptionalERR@';
   end if;
   if p_isoptional='Y' or p_connectsoline='Y' then
        if p_isoptional='Y' and v_opt ='N' then
                select * into v_olc from c_orderline where c_orderline_id=p_soorderlineid;
                p_soorderlineid:=get_uuid();
                v_olc.c_orderline_id=p_soorderlineid;
                v_olc.created=now();
                v_olc.createdby=p_user;
                while (select count(*) from c_orderline where c_order_id=v_order and line=v_olc.line+v_i)>0 
                LOOP
                    v_i:=v_i+1;
                END LOOP;
                v_olc.line:=v_olc.line+v_i;
                v_olc.isoptional:='Y';
                v_olc.description:=p_description;
                insert into c_orderline select v_olc.*;
                update c_orderline set orderlineselfjoin=p_soorderlineid,description=p_description where c_orderline_id=p_poorderlineid;
        else
                update c_orderline set updated=now(),updatedby=p_user,isoptional=p_isoptional,description=p_description,
                scheddeliverydate=to_date(p_deliverydate,'DD-MM-YYYY'),priceactual=to_number(coalesce(p_soprice,'0')),auxfield1=v_aux1 
                where c_orderline_id=p_soorderlineid;
                if p_isoptional='N' then
                -- isdescription is used to mark a purchase as connected to sales (this field was there before, but has no function)
                update c_orderline set isdescription='N' where orderlineselfjoin=p_soorderlineid;
                update c_orderline set isdescription='Y' where c_orderline_id=p_poorderlineid; 
                else
                update c_orderline set isdescription='N' where c_orderline_id=p_poorderlineid; 
                end if;    
        end if;
   else --  p_isoptional='N' and p_connectsoline='N'
        if v_opt='Y' then
            delete from c_orderline where c_orderline_id=p_soorderlineid;
        end if;
        update c_orderline set isdescription='N' where c_orderline_id=p_poorderlineid;
   end if;
   if v_ds='CO' then
        update c_order set docaction='CO' where c_order_id=v_order;
        perform c_order_post1(null, v_order);
   end if;
RETURN 'SUCESS';
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_createDocumentHeaderFromPO(p_orderid varchar,p_targettype varchar,p_user varchar,p_salesorderlineId varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
    v_Client varchar:='C726FEC915A54A0995C568555DA5BB3C';
    v_doctypetarget varchar;
    v_orderid varchar;
    v_docno varchar;
    v_reforder varchar;
    v_curOrder c_order%rowtype;
BEGIN
    if p_orderid is null then return 'COMPILE'; end if;
    select * into  v_curOrder from c_order where c_order_id=p_orderid;
    v_orderid:=get_uuid();
    if p_targettype = 'POORDER' then
        v_doctypetarget:='B342FD5CA1C64E8BA25A0A6F6C98C7DA'; -- Order (PO)
    end if;
    if p_targettype = 'DROPSHIP' then
        v_doctypetarget:='EE19ABBDB5A94C519DAB11003320FC8E'; -- Drop Ship Order (PO)
        if (select isdropshipper from c_bpartner where c_bpartner_id=v_curOrder.c_bpartner_id)='N' then
            raise exception '%','@bpartnerNoDropshipper@';
        end if;
    end if;
    if p_targettype = 'POOFFER' then
        v_doctypetarget:='8CF74AC370B04133B54C44A12E084749';--Request for Quotation
    end if;
    select p_documentno into  v_docno from ad_sequence_doctype(v_doctypetarget,v_curOrder.ad_org_id , 'Y') ;
    v_curOrder.c_order_id:=v_orderid;
    v_curOrder.documentno:=v_docno;
    v_curOrder.createdby:=p_user;
    v_curOrder.updatedby:=p_user;
    v_curOrder.created:=now();
    v_curOrder.updated:=now();
    v_curOrder.c_doctype_id:=v_doctypetarget;
    v_curOrder.c_doctypetarget_id:=v_doctypetarget;
    v_curOrder.processed:='N';
    v_curOrder.docstatus:='DR';
    v_curOrder.docaction:='CO';
    if p_salesorderlineId is not null then
       select c_order_id into v_reforder from c_orderline where c_orderline_id=p_salesorderlineId;
    else
        v_reforder:=p_orderid;
    end if;
    v_curOrder.orderselfjoin:=v_reforder;
    -- Creating Header
    INSERT INTO C_Order select v_curOrder.*;
  
RETURN v_orderid;
END;
$_$  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION c_createDocumentLineFromPO(p_neworderid varchar,p_sourceorderline_id varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
    v_cur_line                c_orderline%rowtype;
    v_user  varchar;
   
BEGIN
   if p_neworderid is null then return 'COMPILE'; end if;
   select createdby  into v_user from c_order where c_order_id=p_neworderid;
   select * into v_cur_line from c_orderline where c_orderline_id=p_sourceorderline_id;
   v_cur_line.c_orderline_id:=get_uuid();
   v_cur_line.c_order_id=p_neworderid;
   v_cur_line.orderlineselfjoin:=p_sourceorderline_id;
   v_cur_line.createdby:=v_user;
   v_cur_line.created:=now();
   v_cur_line.updatedby:=v_user;
   v_cur_line.updated:=now();
   insert into c_orderline select v_cur_line.*;
RETURN 'SUCESS';
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_checkPOOffersAndCloseFromSO(p_soorderlineId varchar, p_user varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2020, OpenZ Software GmbH. All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
    v_cur record;
    v_testOK varchar;
    v_qty numeric;
    v_qtyREF numeric;
    v_offer2close varchar;
    v_cur2 record;
BEGIN
   -- Alle POOffers auf der Sales Line
   for v_cur in (select distinct pol.c_order_id from c_orderline pol,c_order po where po.c_order_id=pol.c_order_id and po.issotrx='N' and po.docstatus='CO' and 
                 pol.orderlineselfjoin=p_soorderlineId order by pol.c_order_id)
   LOOP
       v_testOK:='OK';
       v_offer2close:=v_cur.c_order_id;
       -- Test the whole offer
       for v_cur2 in (select * from c_orderline where c_order_id=v_cur.c_order_id)
       LOOP
           select qtyordered into v_qty from c_orderline where c_orderline_id=v_cur2.orderlineselfjoin; -- Ordered Qty (SALES)
           --select sum(qtyordered) into v_qtyREF from c_orderline where orderlineselfjoin=v_cur.c_orderline_id; -- Ordered Qty (PURCHASE)
           
           select sum(ool.qtyordered) into v_qtyREF from c_orderline xol,c_order xo , c_orderline ool,c_order oo
                                where xo.c_order_id=xol.c_order_id and xo.c_doctype_id='8CF74AC370B04133B54C44A12E084749' and xo.docstatus in ('CO','CL')
                                      and xol.orderlineselfjoin= v_cur2.orderlineselfjoin
                                      and oo.c_order_id=ool.c_order_id and oo.issotrx='N' and oo.c_doctype_id!='8CF74AC370B04133B54C44A12E084749' 
                                      and oo.docstatus in ('DR','CO') and ool.orderlineselfjoin=xol.c_orderline_id;            
           if coalesce(v_qty,0)>coalesce(v_qtyREF,0) then
                v_testOK:='NOK';
           end if;
       END LOOP;
       if v_testOK='OK' then
            UPDATE C_ORDER  SET DocStatus='CL', DocAction='--',Processing='N',processed='Y',proposalstatus='CL',Updated=TO_DATE(NOW()) , updatedby=p_user WHERE C_Order_ID=v_offer2close;
       end if;
   END LOOP;
RETURN v_testOK;
END;
$_$  LANGUAGE 'plpgsql';
