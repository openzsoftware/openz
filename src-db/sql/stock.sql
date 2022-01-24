CREATE OR REPLACE FUNCTION m_inout_trg2() RETURNS trigger
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

Gets predefined Textmodules into Shipments

*****************************************************/

    v_count numeric;
    v_orgfrom character varying;
    v_cur RECORD; 
BEGIN
    
 
 IF(TG_OP = 'INSERT') then
     --Take Textmodule either from Org=0 or current organization 
     for v_cur in (select * from zssi_textmodule where c_doctype_id=new.c_doctype_id and ad_org_id in ('0',new.ad_org_id) and isactive='Y' and isautoadd='Y' and 
                                            coalesce(c_bpartner_id,new.c_bpartner_id)=new.c_bpartner_id order by islower,position )
     LOOP
        -- Get predefined Textmodules into Order
        insert into zssi_minout_textmodule (ZSSI_minout_TEXTMODULE_ID, zssi_textmodule_id,m_inout_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, LINE, ISLOWER, TEXT)
               values (get_uuid(),v_cur.zssi_textmodule_id,new.m_inout_id,new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,v_cur.position,v_cur.islower,v_cur.text);
     END LOOP;
  end if; --Inserting 
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


drop trigger m_inout_trg2 on  m_inout;

CREATE TRIGGER m_inout_trg2
  AFTER INSERT
  ON m_inout
  FOR EACH ROW
  EXECUTE PROCEDURE m_inout_trg2();


-- Version 2.6.02.046
CREATE OR REPLACE FUNCTION m_inout_trg_prov() RETURNS trigger
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

  v_movementType VARCHAR(60) ;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  SELECT(
    CASE isSOTrx
      WHEN 'N'
      THEN 'V+'
      ELSE 'C-'
    END
    )
  INTO v_movementType
  FROM C_DOCTYPE
  WHERE C_DocType_ID=NEW.C_DocType_ID;
  -- On Customer-Returns:
  If NEW.C_DocType_ID='2317023F9771481696461C5EAF9A0915' then
     v_movementType:='C+';
  end if;
  -- Vendor Returns
  If NEW.C_DocType_ID='2E1E735AA91A49F8BC7181D31B09B370' then
   v_movementType:='V-';
  end if;  
  NEW.MOVEMENTTYPE:=v_movementType;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;




--
-- Name: m_inout_post(character varying, character varying); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION m_inout_post(p_pinstance_id character varying, p_inout_id character varying) RETURNS void
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
  * $Id: M_InOut_Post.sql,v 1.8 2003/09/05 04:58:06 jjanke Exp $
  ***
  * Title: Post M_InOut_ID
  * Description:
  *  Action: COmplete
  *  - Create Transaction
  *    (only stocked products)
  *  - Update Inventory (QtyReserved, QtyOnHand)
  *    (only stocked products)
  *  - Update OrderLine (QtyDelivered)
  * 
  *  Action: Reverse Correction
  *  - Create Header and lines with negative Quantities (and header amounts)
  *  - Post it
  * SZ: Allow Material Returns.Disabled secondary UOM.
  *     2nd UOM is not transacted to Storage.
  *     It is only Used on Orders, Invoices and  in InOut-Transactions
  *     
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR:=''; --OBTG:VARCHAR2--
  v_Message VARCHAR:=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_User VARCHAR(32); --OBTG:VARCHAR2--
  v_is_included NUMERIC:=0;
  v_DocType_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_available_period NUMERIC:=0;
  v_is_ready AD_Org.IsReady%TYPE;
  v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
  v_DateAcct TIMESTAMP;
  v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
  v_org_bule_id AD_Org.AD_Org_ID%TYPE;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    --
    Cur_InOut RECORD;
    Cur_InOutLine RECORD;
    Cur_Order RECORD;
    v_Cur_Set   RECORD;
    --
    v_Result NUMERIC:=1;
    v_AD_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AD_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_NextNo VARCHAR(32); --OBTG:VARCHAR2--
    v_Qty NUMERIC;
    v_QtyPO NUMERIC;
    v_QtySO NUMERIC;
    
    v_RDocumentNo VARCHAR(40) ; --OBTG:VARCHAR2--
    v_RInOut_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_IsStocked character varying;
    v_IsSet character varying;
    v_DoctypeReversed_ID VARCHAR(32); --OBTG:VARCHAR2--
    --MODIFIED BY F.IRIAZABAL
    v_QtyOrder NUMERIC;
    v_ProductUOM NUMERIC;
    v_BreakDown VARCHAR(60) ; --OBTG:VARCHAR2--
    v_QtyAux NUMERIC;
    v_Count NUMERIC:=0;
    v_Line VARCHAR(10) ; --OBTG:VARCHAR2--
    FINISH_PROCESS BOOLEAN:=false;
    v_Aux NUMERIC;
    v_QtyCompare NUMERIC;
    v_locator character varying;
    v_uom     character varying;
    v_deliverycomplete varchar;
    v_internalDistribution varchar:='';
    v_stockedattribute varchar;
    v_ORDr varchar:='';
    v_invPinstance varchar;
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      v_ResultStr:='PInstanceNotFound';
      -- Get Parameters
      v_ResultStr:='ReadingParameters';
      FOR Cur_Parameter IN
        (SELECT i.Record_ID,
          i.AD_User_ID,
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
        v_User:=Cur_Parameter.AD_User_ID;
      END LOOP; -- Get Parameter
      RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    ELSE
      RAISE NOTICE '%','--<<M_InOut_Post>>' ;
      v_Record_ID:=p_InOut_ID;
      p_PInstance_ID:=p_InOut_ID;
      
      SELECT updatedby 
        INTO v_user
        FROM M_InOut
        WHERE M_InOut_ID=v_Record_ID;
      IF v_user is null THEN
        FINISH_PROCESS:=true;
      END IF;
    END IF;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
        IF(NOT FINISH_PROCESS) THEN
      SELECT AD_Client_ID, AD_Org_ID,  C_DocType_ID, DateAcct
        INTO v_AD_Client_ID, v_AD_Org_ID, v_DocType_ID, v_DateAcct
        FROM M_InOut
        WHERE M_InOut_ID=v_Record_ID;
      SELECT count(*)
      INTO v_Count
      FROM AD_CLIENTINFO
      WHERE AD_CLIENT_ID=v_AD_Client_ID
        AND CHECKINOUTORG='Y';
      IF v_Count>0 THEN
        v_ResultStr:='CheckingRestrictions - M_INOUT ORG IS IN C_BPARTNER ORG TREE';
        SELECT count(*)
        INTO v_Count
        FROM M_InOut m,
          C_BPartner bp
        WHERE m.M_InOut_ID=v_Record_ID
          AND m.C_BPARTNER_ID=bp.C_BPARTNER_ID
          AND AD_IsOrgIncluded(m.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1;
        IF v_Count>0 THEN
          RAISE EXCEPTION '%', '@NotCorrectOrgBpartnerInout@' ; --OBTG:-20000--
        END IF;
      END IF;
     -- Check if there are lines document does
     if (select count(*) from  M_INOUTLINE where M_Inout_ID = v_Record_ID)=0 then
          RAISE EXCEPTION '%', '@NoLinesInDoc@';
     END IF; 
     v_ResultStr:='CheckingRestrictions';
     SELECT COUNT(*)
     INTO v_Count
     FROM C_DocType,
          M_InOut M
     WHERE M_Inout_ID = v_Record_ID
       AND C_DocType.DocBaseType IN ('MMR', 'MMS')
      AND C_DocType.IsSOTrx=M.IsSOTrx
      AND AD_ISORGINCLUDED(m.AD_Org_ID,C_DocType.AD_Org_ID, m.AD_Client_ID) <> -1
       AND M.C_DOCTYPE_ID=C_DocType.C_DOCTYPE_ID;
        IF v_Count=0 THEN
          RAISE EXCEPTION '%', '@NotCorrectOrgDoctypeShipment@' ; --OBTG:-20000--
        END IF;
        SELECT COUNT(*), MAX(M.line)
        INTO v_Count, v_line
        FROM M_InOutLine M,
          M_Product P,M_ATTRIBUTESET a
        WHERE M.M_PRODUCT_ID=P.M_PRODUCT_ID AND P.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id and a.ismandatory='Y'
          AND COALESCE(M.M_ATTRIBUTESETINSTANCE_ID, '0') = '0'
          AND M.M_INOUT_ID=v_Record_ID;
        IF v_Count<>0 THEN
          RAISE EXCEPTION '%', '@Inline@ '||v_line||' '||'@productWithoutAttributeSet@' ; --OBTG:-20000--
        END IF;
        
      -- check inout line instance location
        SELECT COUNT(*), MAX(M.line)
        INTO v_Count, v_Line
        FROM M_InOutLine M,
          M_Product P
        WHERE M.M_InOut_ID=v_Record_ID
          AND M.M_Locator_ID IS NULL
          AND p.m_product_id = m.m_product_id
          AND p.isstocked = 'Y'
          AND p.producttype = 'I';
        IF v_Count <> 0 THEN
          RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@InoutLineWithoutLocator@' ; --OBTG:-20000--
        END IF;   
      
        -- Process Shipments
  
     -- Set org lines like the header
       UPDATE M_INOUTLINE
        SET AD_ORG_ID = (SELECT AD_ORG_ID FROM M_INOUT WHERE M_INOUT_ID = v_Record_ID)
      WHERE M_INOUT_ID = v_Record_ID;
      
      -- Check the header belongs to a organization where transactions are posible and ready to use
      SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
      INTO v_is_ready, v_is_tr_allow
      FROM M_INOUT, AD_Org, AD_OrgType
      WHERE AD_Org.AD_Org_ID=M_INOUT.AD_Org_ID
      AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
      AND M_INOUT.M_INOUT_ID=v_Record_ID;
      IF (v_is_ready='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
      END IF;
      IF (v_is_tr_allow='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
      END IF;
        
      SELECT AD_ORG_CHK_DOCUMENTS('M_INOUT', 'M_INOUTLINE', v_Record_ID, 'M_INOUT_ID', 'M_INOUT_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;
      
      -- Check the period control is opened (only if it is legal entity with accounting)
      -- Gets the BU or LE of the document
      SELECT AD_GET_DOC_LE_BU('M_INOUT', v_Record_ID, 'M_INOUT_ID', 'LE')
      INTO v_org_bule_id
      FROM DUAL;
      
      SELECT AD_OrgType.IsAcctLegalEntity
      INTO v_isacctle
      FROM AD_OrgType, AD_Org
      WHERE AD_Org.AD_OrgType_ID = AD_OrgType.AD_OrgType_ID
      AND AD_Org.AD_Org_ID=v_org_bule_id;
      
      IF (v_isacctle='Y') THEN    
        SELECT C_CHK_OPEN_PERIOD(v_AD_Org_ID, v_DateAcct, NULL, v_DocType_ID) 
        INTO v_available_period
        FROM DUAL;
        
        IF (v_available_period<>1) THEN
          RAISE EXCEPTION '%', '@PeriodNotAvailable@'; --OBTG:-20000--
        END IF;
      END IF;  
  
        FOR Cur_InOut IN
          (SELECT *
          FROM M_INOUT
          WHERE(M_InOut_ID=v_Record_ID
            OR(v_Record_ID IS NULL
            AND DocAction='CO'))
            AND IsActive='Y'  FOR UPDATE
          )
        LOOP
          RAISE NOTICE '%','Shipment_ID=' || Cur_InOut.M_InOut_ID || ', Doc=' || Cur_InOut.DocumentNo || ', Status=' || Cur_InOut.DocStatus || ', Action=' || Cur_InOut.DocAction ;
          v_ResultStr:='HeaderLoop';
/**
* Processing Shipment not processed
*/
    IF(Cur_InOut.Processed='N' AND Cur_InOut.DocStatus='DR' AND Cur_InOut.DocAction='CO') THEN
            -- For all active shipment lines
            v_ResultStr:='HeaderLoop-1';
        SELECT COUNT(*) INTO v_Aux
        FROM M_InOutLine
        WHERE M_InOut_ID = v_Record_ID;
        IF v_Aux=0 THEN
        RAISE EXCEPTION '%', '@ReceiptWithoutLines@'; --OBTG:-20000--
        END IF;
          FOR Cur_InOutLine IN
            (SELECT *
            FROM M_INOUTLINE
            WHERE M_InOut_ID=Cur_InOut.M_InOut_ID
              AND IsActive='Y'  FOR UPDATE
            )
          LOOP
            -- Incomming or Outgoing (+/-) ?
            v_Qty:=Cur_InOutLine.MovementQty;
            --Incoming: Material transaction : movement is + , v_QtySO - (returned)
            IF(SUBSTR(Cur_InOut.MovementType, 2)='-') THEN
              --Outgoing: Material transaction : movement is - , v_QtySO + (delivered)
              v_Qty:=- Cur_InOutLine.MovementQty;
            END IF;
            IF(Cur_InOut.IsSOTrx='N') THEN
              v_QtySO:=0;
              v_QtyPO:= - v_Qty;
            ELSE
              v_QtySO:= - v_Qty;
              v_QtyPO:=0;
            END IF;
            -- Is it a standard stocked product:3
            SELECT p.isstocked,p.issetitem,a.IsStockTracking  INTO v_IsStocked,v_IsSet,v_stockedattribute
            FROM M_PRODUCT p left join M_ATTRIBUTESET a on p.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id
            WHERE p.M_Product_ID=Cur_InOutLine.M_Product_ID
              AND p.ProductType='I';
            -- Create Transaction for stocked product
            IF coalesce(v_IsStocked,'N')='Y' THEN
              v_ResultStr:='CreateTransaction';
              SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('M_Transaction', Cur_InOutLine.AD_Org_ID) ;
              INSERT
              INTO M_TRANSACTION
                (
                  M_Transaction_ID, M_InOutLine_ID, AD_Client_ID, AD_Org_ID,
                  IsActive, Created, CreatedBy, Updated,
                  UpdatedBy, MovementType, M_Locator_ID, M_Product_ID,
                  M_AttributeSetInstance_ID, MovementDate, MovementQty, C_UOM_ID,weight
                )
                VALUES
                (
                  v_NextNo, Cur_InOutLine.M_InOutLine_ID, Cur_InOutLine.AD_Client_ID, Cur_InOutLine.AD_Org_ID,
                   'Y', TO_DATE(NOW()), Cur_InOutLine.UpdatedBy, TO_DATE(NOW()),
                  Cur_InOutLine.UpdatedBy, Cur_InOut.MovementType, Cur_InOutLine.M_Locator_ID, Cur_InOutLine.M_Product_ID,
                  case when coalesce(v_stockedattribute,'N')='Y' then COALESCE(Cur_InOutLine.M_AttributeSetInstance_ID, '0') else '0' end, 
                  Cur_InOut.MovementDate, v_Qty,Cur_InOutLine.C_UOM_ID,Cur_InOutLine.weight
                )
                ;
            END IF;
            IF coalesce(v_IsSet,'N')='Y' then
            -- Material Transaction for SET-Items
            for v_Cur_Set in (select * from m_product_bom where m_product_id=Cur_InOutLine.M_Product_ID)
                LOOP
                  v_ResultStr:='CreateSetItemTransaction';
                  -- Select Locator, If Return from Product, if delivery from stock 
                  -- All Items of the Set are expected to be in the same locator
                  /*
                  if SUBSTR(Cur_InOut.MovementType, 2)='-' then
                      select max(m_locator_id) into v_locator from m_product_org where m_product_id=v_Cur_Set.M_Product_ID and ad_org_id=Cur_InOut.ad_org_id;
                     if v_locator is null then
                        select m_locator_id into v_locator from m_product where m_product_id=v_Cur_Set.M_Product_ID;
                     end if;
                  else
                     select m_locator_id into v_locator from m_storage_detail where m_product_id=v_Cur_Set.m_product_id  and 
                                                            m_locator_id in (select m_locator_id from m_locator where M_WAREHOUSE_ID=Cur_InOut.m_warehouse_id) and
                                                            coalesce(QTYONHAND,0)-coalesce(preqtyonhand,0) >= v_Cur_Set.bomqty*v_Qty LIMIT 1;
                  end if;
                  */
                  SELECT c_uom_id into v_uom from m_product where m_product_id=v_Cur_Set.M_Product_ID;
                  -- Reservation and Transaction is Done siomultanously on SET-Items
                  PERFORM M_UPDATE_INVENTORY(Cur_InOutLine.weight, Cur_InOutLine.AD_ORG_ID, Cur_InOutLine.UPDATEDBY, v_Cur_Set.m_productbom_id, Cur_InOutLine.M_Locator_ID, null, v_uom,NULL, NULL, NULL, NULL,v_Cur_Set.bomqty*v_Qty , NULL);
                  -- Do Transaction for each part of BOM
                  SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('M_Transaction', Cur_InOutLine.AD_Org_ID) ;
                  INSERT
                  INTO M_TRANSACTION
                  (
                        M_Transaction_ID, M_InOutLine_ID, AD_Client_ID, AD_Org_ID,
                        IsActive, Created, CreatedBy, Updated,
                        UpdatedBy, MovementType, M_Locator_ID, M_Product_ID,
                        M_AttributeSetInstance_ID, MovementDate, MovementQty, C_UOM_ID,weight
                  )
                  VALUES
                  (
                        v_NextNo, Cur_InOutLine.M_InOutLine_ID, Cur_InOutLine.AD_Client_ID, Cur_InOutLine.AD_Org_ID,
                        'Y', TO_DATE(NOW()), Cur_InOutLine.UpdatedBy, TO_DATE(NOW()),
                        Cur_InOutLine.UpdatedBy, Cur_InOut.MovementType, Cur_InOutLine.M_Locator_ID, v_Cur_Set.m_productbom_id,
                        '0', Cur_InOut.MovementDate, v_Qty*v_Cur_Set.bomqty,v_uom,(select -1*weight*v_Qty*v_Cur_Set.bomqty from m_product where m_product_id=v_Cur_Set.m_productbom_id)
                  );
                  SELECT * INTO  v_Result, v_Message FROM M_Check_Stock(v_Cur_Set.m_productbom_id, v_AD_Client_ID, v_AD_Org_ID) ;
                  IF v_Result=0 and Cur_InOut.movementtype!='C+' THEN
                        RAISE EXCEPTION '%', v_Message||' '||'@line@'||' '||Cur_InOutLine.line ; --OBTG:-20000--
                  END IF;
                END LOOP;
            END IF; -- Set Items
            -- Create Asset
            IF(Cur_InOutLine.M_Product_ID IS NOT NULL AND Cur_InOut.IsSOTrx='Y') THEN
              PERFORM A_ASSET_CREATE(NULL, Cur_InOutLine.M_InOutLine_ID) ;
            END IF;
            v_ResultStr:='UpdateOrderLine';
            IF(Cur_InOutLine.C_OrderLine_ID IS NOT NULL) THEN
              -- Qty Delivered may not be more than qty ordered
              --select QtyDelivered + v_QtySO -qtyordered into v_QtyCompare from C_ORDERLINE WHERE C_OrderLine_ID=Cur_InOutLine.C_OrderLine_ID;
              --if v_QtyCompare>0 then
              --   raise exception '%', '@QtydeliveredNotBiggerThanQtyOrdered@';
              --end if;
              select case when deliverycomplete='C' then 'N' else deliverycomplete end into  v_deliverycomplete from c_generateminoutmanual where m_inoutline_id=Cur_InOutLine.M_InOutLine_ID;
              -- stocked product
              IF(Cur_InOutLine.M_Product_ID IS NOT NULL AND coalesce(v_IsStocked,'N')='Y') THEN 
                -- Update OrderLine (if C-, Qty is negative)
                UPDATE C_ORDERLINE
                  SET QtyReserved=QtyReserved  - v_QtySO,
                  deliverycomplete=coalesce(v_deliverycomplete,'N'),
                  QtyDelivered=QtyDelivered + v_QtySO - v_QtyPO
                WHERE C_OrderLine_ID=Cur_InOutLine.C_OrderLine_ID;
                -- Products not stocked
              ELSE
                -- Update OrderLine (if C-, Qty is negative)
                UPDATE C_ORDERLINE
                  SET deliverycomplete=coalesce(v_deliverycomplete,'N'),
                  QtyDelivered=QtyDelivered + v_QtySO - v_QtyPO
                WHERE C_OrderLine_ID=Cur_InOutLine.C_OrderLine_ID;
              END IF;
            END IF;
            -- SZ: Allow Material Returns
            IF(Cur_InOutLine.M_Product_ID IS NOT NULL AND coalesce(v_IsStocked,'N')='Y' AND Cur_InOut.movementtype!='C+') THEN
              SELECT * INTO  v_Result, v_Message FROM M_Check_Stock(Cur_InOutLine.M_Product_ID, v_AD_Client_ID, v_AD_Org_ID) ;
              IF v_Result=0 THEN
                            RAISE EXCEPTION '%', v_Message||' '||'@line@'||' '||Cur_InOutLine.line ; --OBTG:-20000--
              END IF;
            END IF;
          END LOOP; -- For all InOut Lines
          /*******************
          * PO Matching
          ******************/
          IF(Cur_InOut.IsSOTrx='N') THEN
            DECLARE
              Cur_SLines RECORD;
              Cur_ILines RECORD;
              v_Qty NUMERIC;
              v_MatchPO_ID VARCHAR(32) ; --OBTG:VARCHAR2--
              v_MatchInv_ID VARCHAR(32) ; --OBTG:VARCHAR2--
            BEGIN
              v_ResultStr:='MatchPO';
              FOR Cur_SLines IN
                (SELECT sl.AD_Client_ID,
                  sl.AD_Org_ID,
                  ol.C_OrderLine_ID,
                  sl.M_InOutLine_ID,
                  sl.M_Product_ID,
                  sl.M_AttributeSetInstance_ID,
                  sl.MovementQty,
                  ol.QtyOrdered
                FROM M_INOUTLINE sl,
                  C_ORDERLINE ol
                WHERE sl.C_OrderLine_ID=ol.C_OrderLine_ID
                  AND sl.M_Product_ID=ol.M_Product_ID  --    AND   sl.M_AttributeSetInstance_ID=ol.M_AttributeSetInstance_ID
                  AND sl.M_InOut_ID=Cur_InOut.M_InOut_ID
                )
              LOOP
                SELECT * INTO  v_MatchPO_ID FROM Ad_Sequence_Next('M_MatchPO', Cur_SLines.AD_Org_ID) ;
                -- The min qty. Modified by Ismael Ciordia
                v_Qty:=Cur_SLines.MovementQty;
                --IF (ABS(Cur_SLines.MovementQty) > ABS(Cur_SLines.QtyOrdered)) THEN
                -- v_Qty := Cur_SLines.QtyOrdered;
                --END IF;
                v_ResultStr:='InsertMatchPO ' || v_MatchPO_ID;
                INSERT
                INTO M_MATCHPO
                  (
                    M_MatchPO_ID, AD_Client_ID, AD_Org_ID, IsActive,
                    Created, CreatedBy, Updated, UpdatedBy,
                    M_InOutLine_ID, C_OrderLine_ID, M_Product_ID, DateTrx,
                    Qty, Processing, Processed, Posted
                  )
                  VALUES
                  (
                    v_MatchPO_ID, Cur_SLines.AD_Client_ID, Cur_SLines.AD_Org_ID, 'Y',
                    TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
                    Cur_SLines.M_InOutLine_ID, Cur_SLines.C_OrderLine_ID, Cur_SLines.M_Product_ID, TO_DATE(NOW()),
                    v_Qty, 'N', 'Y', 'N'
                  )
                  ;
              END LOOP;
              v_ResultStr:='MatchInv';
              FOR Cur_ILines IN
                (SELECT sl.AD_Client_ID,
                  sl.AD_Org_ID,
                  il.C_InvoiceLine_ID,
                  sl.M_InOutLine_ID,
                  sl.M_Product_ID,
                  sl.M_AttributeSetInstance_ID,
                  sl.MovementQty,
                  il.QTYINVOICED
                FROM M_INOUTLINE sl,
                  C_INVOICELINE il
                WHERE sl.M_InOutLine_ID=il.M_InOutLine_ID
                  AND sl.M_InOut_ID=Cur_InOut.M_InOut_ID
                )
              LOOP
                SELECT * INTO  v_MatchInv_ID FROM Ad_Sequence_Next('M_MatchInv', Cur_ILines.AD_Org_ID) ;
                -- The min qty. Modified by Ismael Ciordia
                v_Qty:=Cur_ILines.MovementQty;
                --IF (ABS(Cur_ILines.MovementQty) > ABS(Cur_ILines.QtyInvoiced)) THEN
                -- v_Qty := Cur_ILines.QtyInvoiced;
                --END IF;
                v_ResultStr:='InsertMatchPO ' || v_MatchPO_ID;
                INSERT
                INTO M_MATCHINV
                  (
                    M_MATCHINV_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
                    CREATED, CREATEDBY, UPDATED, UPDATEDBY,
                    M_INOUTLINE_ID, C_INVOICELINE_ID, M_PRODUCT_ID, DATETRX,
                    QTY, PROCESSING, PROCESSED, POSTED
                  )
                  VALUES
                  (
                    v_MatchInv_ID, Cur_ILines.AD_Client_ID, Cur_ILines.AD_Org_ID, 'Y',
                    TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
                    Cur_ILines.M_InOutLine_ID, Cur_ILines.C_InvoiceLine_ID, Cur_ILines.M_Product_ID, TO_DATE(NOW()),
                    v_Qty, 'N', 'Y', 'N'
                  )
                  ;
              END LOOP;
            END;
          ELSE
            v_ResultStr:='Check delivery rule for sales orders';
            v_Message:='';
            FOR Cur_Order IN 
              (SELECT c_order.deliveryrule, m_inoutline.line, c_order.c_order_id,
                      c_order.documentno, c_orderline.line as orderline
               FROM M_InOutLine, C_Orderline, C_Order
               WHERE M_Inoutline.c_orderline_id = c_orderline.c_orderline_id
                 AND c_orderline.c_order_id = c_order.c_order_id
                 AND m_inoutline.m_inout_id = cur_inout.m_inout_id
                 AND ((c_order.deliveryrule = 'O'
                      AND EXISTS (SELECT 1 FROM C_OrderLine ol
                                  WHERE ol.C_Order_ID = C_order.c_order_id
                                    and ol.qtyordered > ol.qtydelivered ))
                      OR (c_order.deliveryrule = 'L' 
                          AND c_orderline.qtyordered > c_orderline.qtydelivered))
               ORDER BY c_order.c_order_id, c_orderline.line) 
            LOOP
              --Order lines not completely delivered with delivery rule O or L
              -- SZ fixed Bug 0000209
              --@TODO : Reverse Corrections are not clean catched (used *R* in Description). 
              IF substr(coalesce(Cur_InOut.Description,''),1,6)!= '(*R*: ' and  Cur_InOut.MovementType in ('C-', 'V+') THEN
                v_Message := COALESCE(v_Message,'') || '@Shipment@' || ' ' || cur_inout.documentno;
                v_Message := v_Message || ' ' || '@line@' || ' ' || cur_order.line || ': ';
                v_Message := v_Message || '@SalesOrderDocumentno@' || cur_order.documentno;
                IF (cur_order.deliveryrule = 'O') THEN
                  v_Message := v_Message || ' ' || '@notCompleteDeliveryRuleOrder@' || '<br>';
                ELSE
                  v_Message := v_Message || ' ' || '@line@' || ' ' || cur_order.orderline;
                  v_Message := v_Message || ' ' || '@notCompleteDeliveryRuleLine@' || '<br>';
                END IF;
              END IF;
            END LOOP;
            IF (v_Message <> '') THEN
              RAISE EXCEPTION '%', v_message; --OBTG:-20000--
            END IF;
          END IF;
          -- Close Shipment
          v_ResultStr:='CloseShipment';
          UPDATE M_INOUT
            SET Processed='Y',
            DocStatus='CO',
            DocAction='RC',
            Updated=TO_DATE(NOW())
          WHERE M_INOUT.M_INOUT_ID=Cur_InOut.M_INOUT_ID;
          --
          -- Apply Costs to Costing Table
          PERFORM m_updatecosting(Cur_InOut.M_INOUT_ID, null,null,'N'); 
          -- Do Automatic Project - Material - Consumption, if Configured
          v_Message := COALESCE(v_Message,'') ||zspm_materialconsumption4project(Cur_InOut.M_INOUT_ID); 
          -- Generate Massage for Internal Distribution of Materail
          if Cur_InOut.movementtype='V+' then
            v_internalDistribution:=ils_getInternalDistributionFromINOUT(Cur_InOut.M_INOUT_ID);
            if v_internalDistribution!='' then
                v_Result:=2;
            end if;
          end if;
          -- Invoice Rule After Shipment Immediate
          if (select count(*) from c_order o,m_inout s where s.m_inout_id=Cur_InOut.M_INOUT_ID and s.c_order_id=o.c_order_id and o.invoicerule='DI')>0 then
            v_invPinstance:=get_uuid();
            FOR Cur_InOutLine IN (SELECT sl.C_ORDERLINE_ID, s.C_ORDER_ID, s.AD_CLIENT_ID, s.AD_ORG_ID,  s.CREATEDBY, s.UPDATEDBY, sl.movementQTY as qty, ol.priceactual as PRICE,sl.M_InOutLine_ID,
                                      sl.m_attributesetinstance_id FROM M_INOUTLINE sl,m_inout s,c_orderline ol WHERE sl.M_InOut_ID=s.M_InOut_ID AND s.M_InOut_ID=Cur_InOut.M_InOut_ID 
                                      and ol.c_orderline_id=sl.c_orderline_id and ol.c_order_id=s.c_order_id order by ol.line)
              LOOP
                INSERT INTO C_GENERATEINVOICEMANUAL(C_GENERATEINVOICEMANUAL_ID, C_ORDERLINE_ID, C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY, QTY, PRICE, LINEAMT,
                IGNORERESIDUE, DESCRIPTION, M_InOutLine_ID,m_attributesetinstance_id,pinstance_id)
                VALUES(get_uuid(), Cur_InOutLine.C_ORDERLINE_ID, Cur_InOutLine.C_ORDER_ID,  Cur_InOutLine.AD_CLIENT_ID, Cur_InOutLine.AD_ORG_ID,  Cur_InOutLine.CREATEDBY, Cur_InOutLine.UPDATEDBY, 
                Cur_InOutLine.QTY, Cur_InOutLine.PRICE, round(Cur_InOutLine.QTY * Cur_InOutLine.PRICE,2), 'N', 
                (select description from c_orderline where c_orderline_id= Cur_InOutLine.C_ORDERLINE_ID),Cur_InOutLine.M_InOutLine_ID,Cur_InOutLine.m_attributesetinstance_id,v_invPinstance);
              END LOOP;
              insert into AD_PINSTANCE (AD_PINSTANCE_ID, AD_PROCESS_ID, RECORD_ID, ISPROCESSING, AD_USER_ID, RESULT, ERRORMSG, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY)
                     values(v_invPinstance,'134','NE','N',Cur_InOutLine.UPDATEDBY,null,null,Cur_InOutLine.AD_CLIENT_ID, Cur_InOutLine.AD_ORG_ID,  Cur_InOutLine.CREATEDBY, Cur_InOutLine.UPDATEDBY);
              insert into AD_PINSTANCE_PARA(ad_pinstance_para_id, ad_pinstance_id, seqno, parametername , p_string,  AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY)
                     values(get_uuid(),v_invPinstance,10,'Selection','Y',Cur_InOutLine.AD_CLIENT_ID, Cur_InOutLine.AD_ORG_ID,  Cur_InOutLine.CREATEDBY, Cur_InOutLine.UPDATEDBY);
              PERFORM C_Invoice_Create0(v_invPinstance);
              if (select result from  ad_pinstance where ad_pinstance_id=v_invPinstance)=1 then
                v_Message := '@ShipmentCreatedInvoice@'||(select errormsg from  ad_pinstance where ad_pinstance_id=v_invPinstance);
              else
                raise exception '%','@Shipment@' ||(select errormsg from  ad_pinstance where ad_pinstance_id=v_invPinstance);
              end if;
          end if;
          -- Not Processed + Complete --
          
/**
* Reverse Correction
*/
    ELSIF(Cur_InOut.DocStatus='CO' AND Cur_InOut.DocAction='RC') THEN
          
          --Check that there isn't any line with an invoice if the order's 
          --invoice rule is after delivery
          select count(*), max(line) into v_count, v_line
          from (
          SELECT m_inoutline.m_inoutline_id, m_inoutline.line
          from m_inoutline, c_order, c_orderline, c_invoiceline, m_inout, c_invoice
          where m_inoutline.c_orderline_id = c_orderline.c_orderline_id
            and c_orderline.c_order_id = c_order.c_order_id
            and c_orderline.c_orderline_id = c_invoiceline.c_orderline_id
            and c_invoiceline.m_inoutline_id=m_inoutline.m_inoutline_id
            and m_inoutline.m_inout_id = m_inout.m_inout_id
            and c_invoiceline.c_invoice_id = c_invoice.c_invoice_id
            and m_inout.m_inout_id = Cur_InOut.m_inout_id
            and m_inout.issotrx = 'Y'
            and c_order.invoicerule in ('D', 'O', 'S','DI')
            and c_invoice.processed='Y'
            and c_invoice.docstatus!='VO'
            and case m_inout.movementtype when 'C-' then c_invoice.c_doctype_id not in (select c_doctype_id  FROM C_DOCTYPE  WHERE DocBaseType='ARC') when 'C+' then c_invoice.c_doctype_id  in (select c_doctype_id  FROM C_DOCTYPE  WHERE DocBaseType='ARC') END
          group by m_inoutline.m_inoutline_id, m_inoutline.line
          having sum(c_invoiceline.qtyinvoiced) <> 0
          ) a;
          IF (v_count > 0 ) THEN
            v_Message := '@InoutDocumentno@' || ': ' || Cur_InOut.DocumentNo || ' ' || '@line@' || ': ' || v_line || '. ';
            v_Message := v_Message || '@VoidShipmentInvoiced@';
            RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
          END IF;
          v_ResultStr:='CreateInOut';
          SELECT COALESCE(C_DOCTYPE_REVERSED_ID, C_DOCTYPE_ID)
          INTO v_DoctypeReversed_ID
          FROM C_DOCTYPE
          WHERE C_DOCTYPE_ID=Cur_InOut.C_DocType_ID;
          SELECT * INTO  v_RInOut_ID FROM Ad_Sequence_Next('M_InOut', Cur_InOut.M_InOut_ID) ; -- Get RInOut_ID
          SELECT * INTO  v_RDocumentNo FROM Ad_Sequence_Doctype(v_DoctypeReversed_ID, Cur_InOut.ad_org_ID, 'Y') ; -- Get RDocumentNo
          IF(v_RDocumentNo IS NULL) THEN
            SELECT * INTO  v_RDocumentNo FROM AD_Sequence_Doc('DocumentNo_M_InOut', Cur_InOut.ad_org_ID, 'Y') ;
          END IF;
          -- Indicate that it is invoiced (i.e. not printed on invoices)
          v_ResultStr:='SetInvoiced';
          UPDATE M_INOUTLINE  SET IsInvoiced='Y'  WHERE M_InOut_ID=Cur_InOut.M_InOut_ID;
          --
          RAISE NOTICE '%','Reverse InOut_ID=' || v_RInOut_ID || ' DocumentNo=' || v_RDocumentNo ;
          v_ResultStr:='InsertInOut Reverse ' || v_RInOut_ID;
          INSERT
          INTO M_INOUT
            (
              M_InOut_ID, C_Order_ID, IsSOTrx, AD_Client_ID,
              AD_Org_ID, IsActive, Created, CreatedBy,
              Updated, UpdatedBy, DocumentNo, C_DocType_ID,
              Description, IsPrinted, MovementType, MovementDate,
              DateAcct, C_BPartner_ID, C_BPartner_Location_ID, AD_User_ID,
              M_Warehouse_ID, POReference, DateOrdered, DeliveryRule,
              FreightCostRule, FreightAmt, C_Project_ID, C_Activity_ID,
              C_Campaign_ID, AD_OrgTrx_ID, User1_ID, User2_ID,
              DeliveryViaRule, M_Shipper_ID, C_Charge_ID, ChargeAmt,
              PriorityRule, DocStatus, DocAction, Processing,
              Processed, ISLOGISTIC, salesrep_id
            )
            VALUES
            (
              v_RInOut_ID, Cur_InOut.C_Order_ID, Cur_InOut.IsSOTrx, Cur_InOut.AD_Client_ID,
              Cur_InOut.AD_Org_ID, 'Y', TO_DATE(NOW()), v_User,
              TO_DATE(NOW()), v_User, v_RDocumentNo, v_DoctypeReversed_ID,
               '(*R*: ' || Cur_InOut.DocumentNo || ') ' || coalesce(Cur_InOut.Description,''), 'N', Cur_InOut.MovementType, Cur_InOut.MovementDate,
              Cur_InOut.DateAcct, Cur_InOut.C_BPartner_ID, Cur_InOut.C_BPartner_Location_ID, Cur_InOut.AD_User_ID,
              Cur_InOut.M_Warehouse_ID, Cur_InOut.POReference, Cur_InOut.DateOrdered, Cur_InOut.DeliveryRule,
              Cur_InOut.FreightCostRule, Cur_InOut.FreightAmt * -1, Cur_InOut.C_Project_ID, Cur_InOut.C_Activity_ID,
              Cur_InOut.C_Campaign_ID, Cur_InOut.AD_OrgTrx_ID, Cur_InOut.User1_ID, Cur_InOut.User2_ID,
              Cur_InOut.DeliveryViaRule, Cur_InOut.M_Shipper_ID, Cur_InOut.C_Charge_ID, Cur_InOut.ChargeAmt * -1,
              Cur_InOut.PriorityRule, 'DR', 'CO', 'N',
               'N', Cur_InOut.islogistic, Cur_InOut.salesrep_id
            )
            ;
          v_ResultStr:='InsertInOutLine';
          FOR Cur_InOutLine IN
            (SELECT *
            FROM M_INOUTLINE
            WHERE M_InOut_ID=Cur_InOut.M_InOut_ID
              AND IsActive='Y'  FOR UPDATE
            )
          LOOP
            -- Create InOut Line
            SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('M_InOutLine', Cur_InOut.M_InOut_ID) ;
            v_ResultStr:='CreateInOutLine';
            INSERT
            INTO M_INOUTLINE
              (
                M_InOutLine_ID, Line, M_InOut_ID, C_OrderLine_ID,
                AD_Client_ID, AD_Org_ID, IsActive, Created,
                CreatedBy, Updated, UpdatedBy, M_Product_ID,
                M_AttributeSetInstance_ID, C_UOM_ID, M_Locator_ID, MovementQty,
                Description, IsInvoiced,  --MODIFIED BY F.IRIAZABAL
                QuantityOrder, M_Product_UOM_ID,c_project_id,c_projecttask_id
              )
              VALUES
              (
                v_NextNo, Cur_InOutLine.Line, v_RInOut_ID, Cur_InOutLine.C_OrderLine_ID,
                Cur_InOut.AD_Client_ID, Cur_InOut.AD_Org_ID, 'Y', TO_DATE(NOW()),
                v_User, TO_DATE(NOW()), v_User, Cur_InOutLine.M_Product_ID,
                Cur_InOutLine.M_AttributeSetInstance_ID, Cur_InOutLine.C_UOM_ID, Cur_InOutLine.M_Locator_ID, Cur_InOutLine.MovementQty * -1,
                 '*R*: ' || coalesce(Cur_InOutLine.Description,''), Cur_InOutLine.IsInvoiced, --MODIFIED BY F.IRIAZABAL
                Cur_InOutLine.QuantityOrder * -1, Cur_InOutLine.M_PRODUCT_UOM_ID,Cur_InOutLine.c_project_id,Cur_InOutLine.c_projecttask_id
              )
              ;
             -- If serial Numbers exists: Create lines
             insert into SNR_MINOUTLINE (SNR_MINOUTLINE_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, M_INOUTLINE_ID, QUANTITY, GUARANTEEDAYS, LOTNUMBER, SERIALNUMBER, RFIDNUMBER, GUARANTEEDATE, ISUNAVAILABLE)
             select get_uuid(),AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, v_NextNo,QUANTITY, GUARANTEEDAYS, LOTNUMBER, SERIALNUMBER, RFIDNUMBER, GUARANTEEDATE, ISUNAVAILABLE
                   from SNR_MINOUTLINE where M_INOUTLINE_ID=Cur_InOutLine.M_INOUTLINE_ID;
          END LOOP;
          -- Close Order
          v_ResultStr:='CloseInOut';
          UPDATE M_INOUT
            SET Description=COALESCE(TO_CHAR(Description), '') || ' (*R*=' || v_RDocumentNo || ')',
            Processed='Y',
            DocStatus='VO', -- it IS reversed
            DocAction='--',
            Updated=TO_DATE(NOW()),
            UpdatedBy=v_User
          WHERE M_INOUT.M_INOUT_ID=Cur_InOut.M_INOUT_ID;
          -- REVERSE Automatic Project - Material - Consumption, if Configured
          PERFORM zspm_reversematerialconsumption4project(Cur_InOut.M_INOUT_ID); 
          -- Post Reversal
          v_ResultStr:='PostReversal';
          PERFORM M_INOUT_POST(NULL, v_RInOut_ID) ;
          select result,ErrorMsg into v_result,v_ResultStr from AD_PINSTANCE where AD_PInstance_ID=v_RInOut_ID;
          if coalesce(v_result,0)=0 then
            raise exception '%','*R*=' || v_RDocumentNo ||': '||v_ResultStr;
          end if;
          -- Indicate as Reversal Transaction
          v_ResultStr:='IndicateReversal';
          UPDATE M_INOUT
            SET Updated=TO_DATE(NOW()),
            UpdatedBy=v_User,
            DocStatus='VO' -- the reversal transaction
          WHERE M_InOut_ID=v_RInOut_ID;
        END IF; -- ReverseCorrection
      END LOOP; -- InOut Header
      /**
      * Transaction End
      */
      v_ResultStr:='Fini';
    END IF; --FINISH_PROCESS
    ---- <<FINISH_PROCESS>>
    -- Do Update the Material Plan with new Stock qty's
    PERFORM mrp_inoutplanupdate(null);
    -- Call User Exit Function
    select  v_message||m_inout_post_userexit(v_Record_ID) into v_message;
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Finished ' || coalesce(v_Message,'') ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_result, coalesce(v_Message,'')||v_internalDistribution) ;
    ELSE
      RAISE NOTICE '%','--<<M_InOut_Post finished>>' ;
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
  RETURN;
END ; $_$;

-- User Exit to m_inout_post
CREATE or replace FUNCTION m_inout_post_userexit(p_minout_id varchar) RETURNS varchar
AS $_$
DECLARE
  BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';

select zsse_dropfunction('m_gettransactionlocator');
CREATE OR REPLACE FUNCTION m_gettransactionlocator(p_product character varying,p_warehouse character varying,p_issotrx character varying,v_qty numeric,p_attributesetinstance_id varchar,p_partialdelivery varchar) 
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
v_plocator character varying;
v_locator character varying;
v_doctypeID character varying;
v_count numeric:=0;
v_cur record;
BEGIN
  -- Purchase or Not Stocked
  if p_issotrx='N' or (select count(*) from m_product where m_product_id=p_product and (isstocked='N' or  producttype ='S'))=1 then
    select p.m_locator_id into v_plocator from m_product_org p,m_locator l where l.m_locator_id=p.m_locator_id and  l.m_warehouse_id=p_warehouse and p.isactive='Y' and  p.isvendorreceiptlocator='Y' and p.m_product_id=p_product;
   if v_plocator is not null then
      return v_plocator;
   end if;
   select p.m_locator_id into v_plocator from m_product p,m_locator l where l.m_locator_id=p.m_locator_id and p.m_product_id=p_product and l.m_warehouse_id=p_warehouse;
   if v_plocator is not null then
      return v_plocator;
   end if;
   select m_locator_id into v_plocator from m_locator where isactive='Y' and isdefault='Y' and m_warehouse_id=p_warehouse;
   return v_plocator;
  end if;
  -- Sales
  if p_issotrx='Y' then
     SELECT s.m_locator_id  into v_plocator FROM M_STORAGE_DETAIL s,m_locator l
            where l.m_locator_id=s.m_locator_id and l.m_warehouse_id = p_warehouse and s.m_product_id=p_product 
            and coalesce(p_attributesetinstance_id,'0')=coalesce(s.m_attributesetinstance_id,'0')
            group by s.m_locator_id,s.m_attributesetinstance_id having sum(s.qtyonhand)>=v_qty order by sum(s.qtyonhand) limit 1;
     if (select issetitem from m_product where m_product_id=p_product)='N' then
        if v_plocator is null and p_partialdelivery='Y' then
            SELECT s.m_locator_id  into v_plocator FROM M_STORAGE_DETAIL s,m_locator l
            where l.m_locator_id=s.m_locator_id and l.m_warehouse_id = p_warehouse and s.m_product_id=p_product 
            and coalesce(p_attributesetinstance_id,'0')=coalesce(s.m_attributesetinstance_id,'0')
            group by s.m_locator_id,s.m_attributesetinstance_id  having sum(s.qtyonhand)>0 order by sum(s.qtyonhand) desc limit 1;
        end if;
        return v_plocator;
     else
        for v_cur in (select l.m_locator_id from m_locator l where  l.m_warehouse_id=p_warehouse and isactive='Y')
        LOOP
        select m_bom_qty_onhand(p_product,p_warehouse,v_cur.m_locator_id) into v_count;
        if v_count>=v_qty then
            return v_cur.m_locator_id;
        end if;
        END LOOP;
     end if;
  end if;
  return null;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION m_gettransactionlocator(p_product character varying,p_warehouse character varying,p_issotrx character varying,v_qty numeric )
  RETURNS character varying AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2019 OpenZ Software GmbH All Rights Reserved.
***************************************************************************************************************************************************/

BEGIN
  RETURN m_gettransactionlocator(p_product,p_warehouse,p_issotrx,v_qty,null,'N');
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION c_isorderCompletelyDelivered(p_order_id character varying)
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
v_doctype character varying;
v_doctypeID character varying;
v_count numeric;
BEGIN
  select c_doctype_ID into v_doctypeID from c_order where c_order_id=p_order_id;
  select docbasetype into v_doctype from c_doctype where c_doctype_id=v_doctypeID;
  -- Function on all orders and frame contracts.
  if v_doctype not in ('SOO','POO') and v_doctypeID not in ('559A80F2E27742D4B2C476045F5C834F','56913A519BA94EB59DAE5BF9A82F5F7D') then
    return 'N' ;
  end if;
  select count(*) into v_count from c_orderline where c_order_id=p_order_id and qtyordered>qtydelivered and deliverycomplete='N';
  if v_count>0 then
    return 'N' ;
  else
    return 'Y' ;
  end if;  
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION m_isinoutcandidate(p_orderline_id character varying)
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

Delivery:
In Out Candidate is whenever in a locator of the Order Warehouse a sufficient onhand QTY is available

Receipt:
In Out Candidate is whenever a good shipment is expected
***************************************************************************************************************************************************/

v_delrule character varying;
v_orderid character varying;
v_qtyordered numeric;
v_qtydelivered numeric;
v_deliverycomplete character varying;
v_product character varying;
v_issotrx character varying;
v_org character varying;
v_client varchar;
v_allownegativestock varchar;
v_warehouse character varying;
v_count numeric;
v_cur record;
v_sheddate timestamp without time zone; 
v_ptype varchar;
BEGIN
  select coalesce(scheddeliverydate,now()),qtyordered,qtydelivered,deliverycomplete,c_order_id,m_product_id,ad_org_id,ad_client_id 
         into v_sheddate,v_qtyordered,v_qtydelivered,v_deliverycomplete,v_orderid,v_product,v_org,v_client from c_orderline where c_orderline_id=p_orderline_id;
  select deliveryrule,issotrx,m_warehouse_id into v_delrule, v_issotrx, v_warehouse from c_order where c_order_id=v_orderid;
  SELECT allownegativestock  INTO  v_allownegativestock  FROM ad_clientinfo where ad_client_id = v_client;
  -- Delivery of Services?
  select producttype into v_ptype from m_product where m_product_id = v_product;
  if c_getconfigoption('deliveryofservices',v_org) = 'N' and v_ptype='S' then
     return 'N';
  end if;
  -- Purchase
  if v_issotrx='N' and v_qtyordered>v_qtydelivered and v_deliverycomplete='N' then 
     return 'Y';
  end if;
  -- sales
  -- Prepaid?
  if v_delrule='R' then
	if (((select iscompletelyinvoiced from c_order where c_order_id = v_orderid) = 'N') or
		(((select iscompletelyinvoiced from c_order where c_order_id = v_orderid) = 'Y') and
		(select count(*) from c_invoice i where i.c_order_id=v_orderid and i.ispaid='N' and docstatus = ('CO') and c_doctype_id!='CCFE32E992B74157975E675458B844D1') > 0)) then
        return 'N';
     end if;
  end if;
  if  v_issotrx='Y' and v_qtyordered>v_qtydelivered and v_deliverycomplete='N'  then
     -- Availability, Prepaid
     if v_delrule in ('A','R') then
          return 'Y';
     end if;
     -- Complete Line
     if v_delrule = 'L' then
         if (m_bom_qty_onhand(v_product, v_warehouse, null) >= v_qtyordered-v_qtydelivered  or v_allownegativestock='Y') then
           return 'Y';
         end if;
     end if;
     -- Complete Order
     if v_delrule = 'O' then
         for v_cur in (select m_product_id,qtyordered,qtydelivered from c_orderline where c_order_id=v_orderid) 
         LOOP
           if m_bom_qty_onhand(v_cur.m_product_id, v_warehouse, null) < v_cur.qtyordered-v_cur.qtydelivered and v_allownegativestock='N' then
               return 'N';
           end if;
         END LOOP;
         return 'Y';
     end if;
  end if;
  return 'N';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
--
--
CREATE OR REPLACE FUNCTION m_inout_candidate_descr_userexit(v_orderline_id varchar)
  RETURNS varchar AS
$BODY$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***********************************************************************************************+*****************************************
User-Exit to Extend Description of in out candidate view individually
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
--
--
--
--
-- M-Inout Generation View
select zsse_DropView ('m_inout_candidate_v');
create or replace view m_inout_candidate_v as 
select 
        o.ad_client_id, 
        o.ad_org_id, 
        o.c_bpartner_id, 
        o.c_order_id, 
        o.documentno, 
        o.dateordered, 
        o.c_doctype_id, 
        l.c_project_id,
        l.c_projecttask_id,
        l.a_asset_id,
        l.m_product_id,
        o.totallines, 
        o.grandtotal,
        l.qtyordered,
        l.qtydelivered,
        l.datepromised,
        coalesce(l.scheddeliverydate,trunc(now())) as scheddeliverydate,
        l.line,
       coalesce(m_inout_candidate_descr_userexit(l.c_orderline_id),'') || case when coalesce(pc.printvpnumberondocs,'N')='Y' then coalesce(( select po.vendorproductno||'  ' from m_product_po po, c_orderline ol,c_order o where po.m_product_id=l.m_product_id 
                                          and case when ol.m_product_uom_id is not null then po.c_uom_id=(select c_uom_id from m_product_uom where m_product_uom_id=ol.m_product_uom_id) else po.c_uom_id is null end
                                          and case when ol.m_product_po_id is not null then po.m_product_po_id= ol.m_product_po_id else  po.m_manufacturer_id is null and po.manufacturernumber is null end
                                          and l.c_orderline_id=ol.c_orderline_id and o.c_order_id=ol.c_order_id and o.c_bpartner_id=po.c_bpartner_id AND po.vendorproductno is not null
      ),'') else '' end ||coalesce(l.description,'')  as description,
        l.qtyordered-l.qtydelivered as qty2deliver,
        l.c_orderline_id,
        o.issotrx,
        p.m_product_category_id,
        p.typeofproduct,
        o.m_shipper_id,
        o.m_warehouse_id,
        bp.name as businesspartner,
        ms.name as shipper_name,
        o.salesrep_id,
        m_bom_qty_onhand(l.m_product_id,o.m_warehouse_id,null) as qtyonhand,
        m_bom_qty_onhand(l.m_product_id,o.m_warehouse_id,null) as qtyavailable,
        l.m_attributesetinstance_id,
        null as m_locator_id
from 
	c_order o left join m_shipper ms on ms.m_shipper_id=o.m_shipper_id left join Zspr_Printinfo pc on pc.ad_org_id=o.ad_org_id,c_orderline l,c_bpartner bp,m_product p
where 
	o.c_order_id = l.c_order_id 
        and o.c_bpartner_id=bp.c_bpartner_id
        and l.m_product_id=p.m_product_id
        and m_isinoutcandidate(l.c_orderline_id)='Y'
        and l.directship = 'N' and l.isoptional = 'N'
        and (o.c_doctype_id in ( select c_doctype.c_doctype_id from c_doctype where c_doctype.docbasetype in ('SOO','POO'))) 
        and o.c_doctype_id not in (select value from ad_preference p where p.attribute like 'EXCLUDEDOCTYPE4SHIPMENT%' and p.ad_org_id in ('0',o.ad_org_id))
        and o.docstatus = 'CO';



select zsse_DropView ('zssi_openshipment');
create view zssi_openshipment as 
select 
        l.c_orderline_id as zssi_openshipment_id, 
        l.ad_client_id, 
        l.ad_org_id, 
        l.isactive, 
        l.created, 
        l.createdby, 
        l.updated, 
        l.updatedby, 
        o.c_bpartner_id, 
        o.documentno, 
        o.description, 
        o.salesrep_id, 
        o.dateordered, 
        o.datepromised, 
        o.poreference,
        l.scheddeliverydate ,
        l.m_product_id, 
        l.c_uom_id, 
        l.qtyordered, 
        l.qtyordered-l.qtydelivered as qtyreserved, 
        l.qtydelivered, 
        l.qtyinvoiced, 
        o.c_order_id,
        (select po.vendorproductno from m_product_po po where po.m_product_id=l.m_product_id 
                                          and case when l.m_product_uom_id is not null then po.c_uom_id=(select c_uom_id from m_product_uom where m_product_uom_id=l.m_product_uom_id) else po.c_uom_id is null end
                                          and case when l.m_product_po_id is not null then po.m_product_po_id= l.m_product_po_id else  po.m_manufacturer_id is null and po.manufacturernumber is null end
                                          and o.c_bpartner_id=po.c_bpartner_id AND po.vendorproductno is not null) as vendorproductno
from 
        c_order o
join 
        c_orderline l on o.c_order_id = l.c_order_id
where 
        o.docstatus = 'CO' and 
        o.isdelivered = 'N' and 
        (o.c_doctype_id in ( select c_doctype.c_doctype_id from c_doctype where c_doctype.docbasetype in ('SOO','POO') )) and 
        l.qtyordered <> l.qtydelivered and l.directship = 'N'::bpchar and l.m_product_id is not null and 
        l.deliverycomplete='N' and
        (o.deliveryrule!='R' or ((select count(*) from c_invoice i where i.c_order_id=o.c_order_id and i.ispaid='Y' and docstatus in ('CO','CL') )=1)) and
        not exists (select 0 from m_inoutline ml,m_inout m where m.m_inout_id=ml.m_inout_id and ml.c_orderline_id=l.c_orderline_id and m.processed='N') and
        ((select producttype from m_product where m_product.m_product_id = l.m_product_id ) != 'S' or
        (select c_getconfigoption('deliveryofservices',o.ad_org_id) = 'Y'));



CREATE OR REPLACE FUNCTION m_inventoryline2_trg() RETURNS trigger
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
v_value character varying;
v_name  character varying;
v_count numeric;
BEGIN

    -- Product weight on insert/update 
    IF TG_OP = 'INSERT' then
        if new.weight is null then
            select weight*new.qtycount into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
    end if;
    IF TG_OP = 'UPDATE' then
        if coalesce(new.weight,0)=coalesce(old.weight,0) and (new.m_product_id!=old.m_product_id or new.qtycount!=old.qtycount) then
            select weight*new.qtycount  into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
    end if;
  
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') then
        if (select m_warehouse_id from m_locator where m_locator_id=new.m_locator_id)!=(select m_warehouse_id from m_inventory where m_inventory_id=new.m_inventory_id) then
            RAISE EXCEPTION '%', '@orgOfLocatorDifferentStockthenTransaction@' ;
        end if;
    end if;
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
    IF (TG_OP != 'DELETE') then
    -- Get name and Value from Product to get Lines searchable
    select value,name into v_value,v_name from m_product where m_product_id=new.m_product_id;
    new.value=v_value;
    new.name=v_name;    
    new.quantityorder := NULL;
    new.m_product_uom_id :=null;
    select count(*) into v_count from m_inventoryline 
    where m_inventory_id=new.m_inventory_id and m_product_id=new.m_product_id and m_locator_id=new.m_locator_id 
            and coalesce(m_attributesetinstance_id,'0')=coalesce(new.m_attributesetinstance_id,'0')
            and m_inventoryline_id!=new.m_inventoryline_id;
    if v_count>0 then
        raise exception '%' , 'Duplicate Line';
    end if;
    end if;


    IF(TG_OP = 'UPDATE') THEN  
        IF NOT((COALESCE(OLD.M_Product_Uom_ID, '0') <> COALESCE(NEW.M_Product_Uom_ID, '0')
            OR COALESCE(OLD.QuantityOrderBook, 0) <> COALESCE(NEW.QuantityOrderBook, 0)))
        THEN  
            IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
        END IF;
    END IF;
    IF(TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    
        IF(NEW.M_Product_Uom_ID IS NOT NULL AND NEW.QuantityOrderBook IS NULL) THEN
            NEW.QuantityOrderBook:=0;
        ELSIF(NEW.M_Product_Uom_ID IS NULL AND NEW.QuantityOrderBook IS NOT NULL) THEN
            NEW.QuantityOrderBook:=NULL;
        END IF;
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;


--
-- Name: m_inventory_listcreate(character varying); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION m_inventory_listcreate(pinstance_id character varying) RETURNS void
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
  * $Id: M_Inventory_ListCreate.sql,v 1.6 2003/06/16 14:40:03 jjanke Exp $
  ***
  * Title: Create Price Inventory Count
  * Description:
  * - get info from Storage.QtyOnHand
  * - if line exist, update it
  * SZ: Bugfix: Do not join in Product-Org - avoid duplicate lines
  ************************************************************************/

  --    Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=0; --    failure
  v_InProcess CHAR(1) ;
  v_Done CHAR(1) ;
  v_NoInserted NUMERIC:=0;
  v_NoUpdated NUMERIC:=0;
  --    Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    --    Parameter Variables
    v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_ProductValue VARCHAR(40) ; --OBTG:VARCHAR2--
    v_Locator_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Product_Category_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_QtyRange VARCHAR(60) ; --OBTG:VARCHAR2--
    v_Regularization VARCHAR(60) ; --OBTG:VARCHAR2--
    v_ABC VARCHAR(60); --OBTG:VARCHAR2--
    --
    v_Warehouse_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    --
    v_NextNo VARCHAR(32); --OBTG:VARCHAR2--
    v_NextLine NUMERIC;
    --    Selection
    Cur_Storage RECORD;
    END_PROCESS BOOLEAN:=false;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing' ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    --    Get Parameters
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
      v_Record_ID:=Cur_Parameter.Record_ID;
      IF(Cur_Parameter.ParameterName='QtyRange') THEN
        v_QtyRange:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  QtyRange=' || v_QtyRange ;
      ELSIF(Cur_Parameter.ParameterName='ProductValue') THEN
        v_ProductValue:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  ProductValue=' || v_ProductValue ;
      ELSIF(Cur_Parameter.ParameterName='regularization') THEN
        v_Regularization:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  Regularization=' || v_Regularization ;
      ELSIF(Cur_Parameter.ParameterName='M_Locator_ID') THEN
        v_Locator_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  M_Locator_ID=' || v_Locator_ID ;
      ELSIF(Cur_Parameter.ParameterName='M_Product_Category_ID') THEN
        v_Product_Category_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  M_Product_Category_ID=' || v_Product_Category_ID ;
      ELSIF(Cur_Parameter.ParameterName='ABC') THEN
        v_ABC:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  ABC=' || v_ABC ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; --    Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    v_ResultStr:='ReadingInventory - (Record not saved)';
  BEGIN
    SELECT Processing,
      Processed,
      AD_Client_ID,
      AD_Org_ID,
      M_Warehouse_ID
    INTO v_InProcess,
      v_Done,
      v_Client_ID,
      v_Org_ID,
      v_Warehouse_ID
    FROM M_Inventory
    WHERE M_Inventory_ID=v_Record_ID;
  EXCEPTION
  WHEN OTHERS THEN
    v_Message:='@SaveErrorRowNotFound@';
    END_PROCESS:=true;
  END;
  IF(NOT END_PROCESS) THEN
    IF(v_InProcess='Y') THEN
      v_Message:='@OtherProcessActive@';
      END_PROCESS:=true;
    END IF;
  END IF;--END_PROCESS
  IF(NOT END_PROCESS) THEN
    IF(v_Done='Y') THEN
      v_Message:='@AlreadyPosted@';
      END_PROCESS:=true;
    END IF;
  END IF;--END_PROCESS
  IF(NOT END_PROCESS) THEN
    v_ResultStr:='Setting ProductValue';
    v_ProductValue:=TRIM(v_ProductValue) ;
    IF(LENGTH(v_ProductValue)=0) THEN
      v_ProductValue:=NULL;
    END IF;
    IF(v_ProductValue IS NOT NULL AND SUBSTR(v_ProductValue, LENGTH(v_ProductValue), 1)<>'%') THEN
      v_ProductValue:=v_ProductValue || '%';
    END IF;
    IF(v_ProductValue IS NOT NULL) THEN
      v_ProductValue:=UPPER(v_ProductValue) ;
    END IF;
    --  Create 0 Storage Records
    IF(v_Regularization = 'Y' and v_QtyRange='=' and v_Locator_ID is null) THEN
      v_ResultStr:='Creating 0 values';
      DECLARE
        Cur_Products RECORD;
        storagesCount NUMERIC:=0;
        p_Storage_ID VARCHAR(32); --OBTG:VARCHAR2--
      BEGIN
        FOR Cur_Products IN
          (SELECT M_Product_ID,
            C_UOM_ID
          FROM M_Product p
          WHERE p.AD_Client_ID=v_Client_ID
            AND IsStocked='Y'
            AND producttype='I'
            AND ISACTIVE='Y'
            AND m_locator_id is not null
            AND NOT EXISTS
            (SELECT *
            FROM M_Storage_Detail s
            WHERE p.M_Product_ID=s.M_Product_ID
              AND s.M_Locator_ID=coalesce(v_Locator_ID,p.m_locator_id)
            )
          )
        LOOP
          SELECT * INTO  p_Storage_ID FROM Ad_Sequence_Next('M_Storage_Detail', v_Client_ID) ;
          INSERT
          INTO M_Storage_Detail
            (
              M_STORAGE_DETAIL_ID, M_PRODUCT_ID, M_LOCATOR_ID, M_ATTRIBUTESETINSTANCE_ID,
              C_UOM_ID, M_PRODUCT_UOM_ID, AD_CLIENT_ID, AD_ORG_ID,
              ISACTIVE, CREATED, CREATEDBY, UPDATED,
              UPDATEDBY, QTYONHAND, QTYORDERONHAND, PREQTYONHAND,
              PREQTYORDERONHAND, DATELASTINVENTORY
            )
            VALUES
            (
              p_Storage_ID, Cur_Products.M_Product_ID, coalesce(v_Locator_ID,(select m_locator_id from m_product where m_product_id=Cur_Products.M_Product_ID)), '0',
              Cur_Products.C_UOM_ID, NULL, v_Client_ID, v_Org_ID,
               'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
              '0', 0, NULL, 0,
              NULL, NULL
            )
            ;
          storagesCount:=storagesCount + 1;
        END LOOP;
        RAISE NOTICE '%','Created 0 Storage Records = '|| storagesCount ;
      END;
    END IF;
  END IF;--END_PROCESS
  IF(NOT END_PROCESS) THEN
    v_ResultStr:='ReadingInventoryLine';
    SELECT COALESCE(MAX(Line)+10, 10) -- BugFix: [1788358] On Inventory the "create count" may repeat line numbers
    INTO v_NextLine
    FROM M_InventoryLine
    WHERE M_Inventory_ID=v_Record_ID;
    FOR Cur_Storage IN
      (SELECT s.M_Product_ID,
        s.M_Locator_ID,
        COALESCE(s.QtyOnHand, 0) AS QtyOnHand,
        (s.QTYORDERONHAND) AS QtyOnHandOrder,
        s.C_UOM_ID,
        s.M_Product_UOM_ID,
        s.M_AttributeSetInstance_ID
      FROM M_Product p
      INNER JOIN M_Storage_Detail s
        ON(s.M_Product_ID=p.M_Product_ID) --SZ: Bugfix: Do not join in Product-Org - avoid duplicate lines
      WHERE p.AD_Client_ID=v_Client_ID  --    only ..
        AND(v_ProductValue IS NULL
        OR UPPER(p.Value) LIKE v_ProductValue)
        AND(v_Locator_ID IS NULL
        OR s.M_Locator_ID=v_Locator_ID)
        AND(v_Warehouse_ID IS NULL
        OR s.M_Locator_ID IN
        (SELECT M_Locator_ID FROM M_Locator WHERE M_Warehouse_ID=v_Warehouse_ID))
        AND(v_Product_Category_ID IS NULL
        OR p.M_Product_Category_ID=v_Product_Category_ID)
        AND p.ISACTIVE='Y'
        AND NOT EXISTS
        (SELECT *
        FROM M_InventoryLine l
        WHERE l.M_Inventory_ID=v_Record_ID
          AND l.M_Product_ID=s.M_Product_ID
          AND l.M_Locator_ID=s.M_Locator_ID
        )
      ORDER BY s.M_Locator_ID,
        p.Value,
        s.Created
      )
    LOOP
      v_ResultStr:='CheckingInventoryLine';
      RAISE NOTICE '%','  QtyRange=' || v_QtyRange || ', OnHand=' || Cur_Storage.QtyOnHand ;
      --
      IF(v_QtyRange IS NULL --  all
        OR(v_QtyRange='>' AND Cur_Storage.QtyOnHand>0) OR(v_QtyRange='<' AND Cur_Storage.QtyOnHand<0) OR(v_QtyRange='=' AND Cur_Storage.QtyOnHand=0) OR(v_QtyRange='N' AND Cur_Storage.QtyOnHand<>0)) THEN
        --    DO we have this record already:1
        SELECT MAX(QtyBook)
        INTO v_NextNo
        FROM M_InventoryLine
        WHERE M_Inventory_ID=v_Record_ID
          AND M_Product_ID=Cur_Storage.M_Product_ID
          AND M_Locator_ID=Cur_Storage.M_Locator_ID
          AND M_AttributeSetInstance_ID=Cur_Storage.M_AttributeSetInstance_ID
          AND C_UOM_ID=Cur_Storage.C_UOM_ID
          AND M_Product_UOM_ID=Cur_Storage.M_Product_UOM_ID;
        --
        RAISE NOTICE '%','  QtyRange=' || v_QtyRange || ', OnHand=' || Cur_Storage.QtyOnHandOrder || ', v_NextNo=' || v_NextNo ;
        IF(v_NextNo IS NULL) THEN
          v_ResultStr:='InsertLine';
          SELECT * INTO  v_NextNo FROM AD_Sequence_Next('M_InventoryLine', v_Client_ID) ;
          INSERT
          INTO M_InventoryLine
            (
              M_InventoryLine_ID, Line, AD_Client_ID, AD_Org_ID,
              IsActive, Created, CreatedBy, Updated,
              UpdatedBy, M_Inventory_ID, M_Locator_ID, M_ATTRIBUTESETINSTANCE_ID,
              M_Product_ID, QtyBook, QtyCount, C_UOM_ID,
              QUANTITYORDER, QUANTITYORDERBOOK, M_Product_UOM_ID
            )
            VALUES
            (
              v_NextNo, v_NextLine, v_Client_ID, v_Org_ID,
               'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
              '0', v_Record_ID, Cur_Storage.M_Locator_ID, Cur_Storage.M_ATTRIBUTESETINSTANCE_ID,
              Cur_Storage.M_Product_ID, Cur_Storage.QtyOnHand,Cur_Storage.QtyOnHand, Cur_Storage.C_UOM_ID,(CASE WHEN Cur_Storage.QtyOnHandOrder IS NULL THEN NULL ELSE Cur_Storage.QtyOnHandOrder END), 
              Cur_Storage.QtyOnHandOrder, Cur_Storage.M_Product_UOM_ID
            )
            ;
          v_NextLine:=v_NextLine + 10;
          v_NoInserted:=v_NoInserted + 1;
        ELSE
          v_ResultStr:='UpdateLine';
          UPDATE M_InventoryLine
            SET QtyBook=Cur_Storage.QtyOnHand,
            QtyCount=Cur_Storage.QtyOnHand,
            C_UOM_ID=Cur_Storage.C_UOM_ID,
            M_AttributeSetInstance_ID=Cur_Storage.M_AttributeSetInstance_ID,
            QUANTITYORDER=Cur_Storage.QtyOnHandOrder,
            QUANTITYORDERBOOK=Cur_Storage.QtyOnHandOrder,
            M_Product_UOM_ID=Cur_Storage.M_Product_UOM_ID,
            Updated=TO_DATE(NOW()),
            UpdatedBy='0'
          WHERE M_Inventory_ID=v_Record_ID
            AND M_Product_ID=Cur_Storage.M_Product_ID
            AND C_UOM_ID=Cur_Storage.C_UOM_ID
            AND M_Product_UOM_ID=Cur_Storage.M_Product_UOM_ID
            AND M_AttributeSetInstance_ID=Cur_Storage.M_AttributeSetInstance_ID
            AND M_Locator_ID=Cur_Storage.M_Locator_ID;
          v_NoUpdated:=v_NoUpdated + 1;
        END IF;
      END IF; --
    END LOOP; --    Cur_Storage
    -- Commented by cromero 19102006 -- COMMIT;
    v_Message:='@Inserted@=' || v_NoInserted || ', @Updated@=' || v_NoUpdated;
    v_Result:=1; --    success
  END IF;--END_PROCESS
  ---- <<END_PROCESS>>
  --  Update AD_PInstance
  RAISE NOTICE '%','Updating PInstance - Finished' ;
  RAISE NOTICE '%',v_Message ;
  PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', v_Result, v_Message) ;
  RETURN;
END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ; $_$;


ALTER FUNCTION public.m_inventory_listcreate(pinstance_id character varying) OWNER TO tad;



-- Version 2.6.00.0032
CREATE OR REPLACE FUNCTION m_update_storage_pending(p_client character varying, p_org character varying, p_user character varying, p_product character varying, p_warehouse character varying, p_attributesetinstance character varying, p_uom character varying, p_product_uom_dummy character varying, p_qtyreserved numeric, p_qtyorderreserved_dummy numeric, p_qtyordered numeric, p_qtyorderordered_dummy numeric) RETURNS void
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
BUGFIX: Deactivate Secondary UOM
Deactivate Secondary UOM -  Inventory schould be working ONLY with 1st UOM

*****************************************************/
  v_cuenta NUMERIC;
  v_Storage_ID VARCHAR(32); --OBTG:VARCHAR2--
BEGIN
  SELECT COUNT(*)
  INTO v_cuenta
  FROM M_STORAGE_PENDING
  WHERE M_PRODUCT_ID=p_product
    AND M_WAREHOUSE_ID=p_warehouse
    AND COALESCE(M_ATTRIBUTESETINSTANCE_ID, '0')=COALESCE(p_attributesetinstance, '0')
    AND C_UOM_ID=p_uom;
  IF(v_cuenta=0) THEN
    SELECT * INTO  v_Storage_ID FROM Ad_Sequence_Next('M_Storage_Pending', p_client) ;

    INSERT
    INTO M_STORAGE_PENDING
      (
        M_STORAGE_PENDING_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
        CREATED, CREATEDBY, UPDATED, UPDATEDBY,
        M_PRODUCT_ID, M_WAREHOUSE_ID, M_ATTRIBUTESETINSTANCE_ID, C_UOM_ID,QTYRESERVED, QTYORDERED
      )
      VALUES
      (
        v_Storage_ID, p_client, p_org, 'Y',
        TO_DATE(NOW()), p_user, TO_DATE(NOW()), p_user,
        p_product, p_warehouse, COALESCE(p_attributesetinstance, '0'), p_uom,COALESCE(p_qtyreserved, 0),COALESCE(p_qtyordered, 0)
      )
      ;
  ELSE
    UPDATE M_STORAGE_PENDING
      SET QTYRESERVED=QTYRESERVED + COALESCE(p_qtyreserved, 0),
      QTYORDERED=QTYORDERED + COALESCE(p_qtyordered, 0),
      AD_CLIENT_ID=p_client,
      AD_ORG_ID=p_org,
      UPDATED=TO_DATE(NOW()),
      UPDATEDBY=p_user
    WHERE M_PRODUCT_ID=p_product
      AND M_WAREHOUSE_ID=p_warehouse
      AND COALESCE(M_ATTRIBUTESETINSTANCE_ID, '0')=COALESCE(p_attributesetinstance, '0')
      AND C_UOM_ID=p_uom;
  END IF;
END ; $_$;



select zsse_dropfunction('m_update_inventory');
CREATE OR REPLACE FUNCTION m_update_inventory(p_weight numeric, p_org character varying, p_user character varying, p_product character varying, p_locator character varying, p_attributesetinstance character varying, p_uom character varying, p_product_uom_dummy character varying, p_qty numeric, p_qtyorder_dummy numeric, p_datelastinventory timestamp without time zone, p_preqty numeric, p_preqtyorder_dummy numeric) RETURNS void
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
BUGFIX: Deactivate Secondary UOM
Deactivate Secondary UOM -  Inventory schould be working ONLY with 1st UOM

*****************************************************/
  v_cuenta NUMERIC;
  v_Storage_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_client varchar:='C726FEC915A54A0995C568555DA5BB3C';
  v_weight numeric;
BEGIN
  -- SZ
  SELECT COUNT(*)
  INTO v_cuenta
  FROM M_STORAGE_DETAIL
  WHERE M_PRODUCT_ID=p_product
    AND M_LOCATOR_ID=p_locator
    AND COALESCE(M_ATTRIBUTESETINSTANCE_ID, '0')=COALESCE(p_attributesetinstance, '0')
    AND C_UOM_ID=p_uom;
  -- implementibng weight
  v_weight:=case when COALESCE(p_qty, 0)<0 then coalesce(p_weight,0)*-1 else coalesce(p_weight,0) end;
  IF(v_cuenta=0) THEN
    SELECT * INTO  v_Storage_ID FROM Ad_Sequence_Next('M_Storage_Detail', v_client) ;
    INSERT
    INTO M_STORAGE_DETAIL
      (
        M_Storage_Detail_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
        CREATED, CREATEDBY, UPDATED, UPDATEDBY,
        M_PRODUCT_ID, M_LOCATOR_ID, M_ATTRIBUTESETINSTANCE_ID, C_UOM_ID,
        QTYONHAND,
        DATELASTINVENTORY,
        PREQTYONHAND,weight
      )
      VALUES
      (
        v_Storage_ID, v_client, p_org, 'Y',
        TO_DATE(NOW()), p_user, TO_DATE(NOW()), p_user,
        p_product, p_locator, COALESCE(p_attributesetinstance, '0'), p_uom,
        COALESCE(p_qty, 0),
        p_datelastinventory,
        COALESCE(p_preqty, 0),
        case when p_qty is not null then case when v_weight<0 then 0 else v_weight end else null end
      )
      ;
  ELSE
    UPDATE M_STORAGE_DETAIL
      SET QTYONHAND=QTYONHAND + COALESCE(p_qty, 0),
      DATELASTINVENTORY=COALESCE(p_datelastinventory, DATELASTINVENTORY),
      PREQTYONHAND=PREQTYONHAND + COALESCE(p_preqty, 0),
      AD_ORG_ID=p_org,
      UPDATED=TO_DATE(NOW()),
      UPDATEDBY=p_user,
      weight= case when p_qty is not null then case when coalesce(weight,0) + v_weight <0 then 0 else coalesce(weight,0) + v_weight end  else weight end
    WHERE M_PRODUCT_ID=p_product
      AND M_LOCATOR_ID=p_locator
      AND COALESCE(M_ATTRIBUTESETINSTANCE_ID, '0')=COALESCE(p_attributesetinstance, '0')
      AND C_UOM_ID=p_uom;
  END IF;
END ; $_$;


CREATE OR REPLACE FUNCTION m_inoutline_trg() RETURNS trigger LANGUAGE plpgsql
AS $_$ DECLARE 
  v_ID          VARCHAR(32); --OBTG:varchar2--
  v_RO    NUMERIC;
  v_movementtype  VARCHAR(2); --OBTG:VARCHAR2--
  v_qty    NUMERIC;
  v_qtyorder   NUMERIC;
  v_qtyold   NUMERIC;
  v_qtyorderold  NUMERIC;
  v_STOCKED   NUMERIC;
  v_UOM_ID    VARCHAR(32); --OBTG:varchar2--
  v_cur record;
  v_cur2 record;
  v_batch varchar;
  v_serial varchar;
  v_batchqty numeric;
  v_snrmasterid varchar;
  counti numeric;
  v_tempin varchar;
  v_tempppp numeric;
/******************************************************************************
 * The contents of this file are subject to the   Compiere License  Version 1.1
 * ("License"); You may not use this file except in compliance with the License
 * You may obtain a copy of the License at http://www.compiere.org/license.html
 * Software distributed under the License is distributed on an  "AS IS"  basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 * The Original Code is                  Compiere  ERP &  Business Solution
 * The Initial Developer of the Original Code is Jorg Janke  and ComPiere, Inc.
 * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke, parts
 * created by ComPiere are Copyright (C) ComPiere, Inc.;   All Rights Reserved.
 * Contributor(s): Openbravo SL, Stefan Zimmermann
 * Contributions are Copyright (C) 2001-2006 Openbravo S.L.
 * Contributions are Copyright (C) 2011 Stefan Zimmermann
 ******************************************************************************/
     
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;

  -- ReadOnly Check
  SELECT  COUNT(*) INTO v_RO  FROM M_InOut WHERE M_InOut_ID=v_ID  AND (Processed='Y' OR Posted='Y');
  IF (v_RO > 0) THEN
    IF (TG_OP = 'INSERT' OR TG_OP = 'DELETE') THEN
            RAISE EXCEPTION '%', 'Document processed/posted'; --OBTG:-20501--
    ELSIF (new.M_Product_ID<>old.M_Product_ID OR new.MovementQty<>old.MovementQty
        OR COALESCE(new.M_AttributeSetInstance_ID, '0') <> COALESCE(old.M_AttributeSetInstance_ID, '0')
        OR COALESCE(new.M_Locator_ID,'-1') <> COALESCE(old.M_Locator_ID,'-1'))
    THEN
            RAISE EXCEPTION '%', 'Document processed/posted'; --OBTG:-20501--
    END IF;
  END IF;-- ReadOnly Check
  -- INSERT Checks and Qtys
  IF (TG_OP = 'INSERT') THEN
    IF (NEW.M_PRODUCT_ID IS NOT NULL) THEN
        SELECT C_UOM_ID INTO v_UOM_ID FROM M_PRODUCT WHERE M_PRODUCT_ID=NEW.M_PRODUCT_ID;
        IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
            IF (NEW.C_ORDERLINE_ID IS NOT NULL) THEN
            SELECT C_UOM_ID INTO v_UOM_ID FROM C_ORDERLINE WHERE C_ORDERLINE_ID = NEW.C_ORDERLINE_ID;
            IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
                    RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
            END IF;
            ELSE
            RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
            END IF;
        END IF;
    END IF;

    v_ID := new.M_InOut_ID;

    SELECT MOVEMENTTYPE INTO v_movementtype
        FROM M_INOUT
        WHERE M_INOUT_ID = NEW.M_INOUT_ID;
    IF v_movementtype in ('C-','V-') THEN
        v_qty := -NEW.MOVEMENTQTY;
      v_qtyorder := -NEW.QUANTITYORDER;
    ELSE
        v_qty := NEW.MOVEMENTQTY;
        v_qtyorder := NEW.QUANTITYORDER;
    END IF;
  END IF; -- INSERT Checks
  IF (TG_OP = 'UPDATE') THEN
    IF (COALESCE(OLD.C_UOM_ID, '0') <> COALESCE(NEW.C_UOM_ID, '0')) THEN
        IF (NEW.M_PRODUCT_ID IS NOT NULL) THEN
            SELECT C_UOM_ID INTO v_UOM_ID FROM M_PRODUCT WHERE M_PRODUCT_ID=NEW.M_PRODUCT_ID;
            IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
                IF (NEW.C_ORDERLINE_ID IS NOT NULL) THEN
                SELECT C_UOM_ID INTO v_UOM_ID FROM C_ORDERLINE WHERE C_ORDERLINE_ID = NEW.C_ORDERLINE_ID;
                    IF (COALESCE(v_UOM_ID,'0') <> COALESCE(NEW.C_UOM_ID,'0')) THEN
                    RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
                    END IF;
                ELSE
                RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)'; --OBTG:-20111--
                END IF;
            END IF;
        END IF;
    END IF; 
    v_ID := new.M_InOut_ID;

    SELECT MOVEMENTTYPE INTO v_movementtype
        FROM M_INOUT
        WHERE M_INOUT_ID = NEW.M_INOUT_ID;
    IF v_movementtype in ('C-','V-') THEN
        v_qty := -NEW.MOVEMENTQTY;
        v_qtyorder := -NEW.QUANTITYORDER;
    ELSE
        v_qty := NEW.MOVEMENTQTY;
        v_qtyorder := NEW.QUANTITYORDER;
    END IF;
  END IF; -- Update Checks


  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    v_ID := old.M_InOut_ID;
    SELECT MOVEMENTTYPE INTO v_movementtype
    FROM M_INOUT
    WHERE M_INOUT_ID = OLD.M_INOUT_ID;
    IF v_movementtype in ('C-','V-') THEN
        v_qtyold := OLD.MOVEMENTQTY;
        v_qtyorderold := OLD.QUANTITYORDER;
    ELSE
        v_qtyold := -OLD.MOVEMENTQTY;
        v_qtyorderold := -OLD.QUANTITYORDER;
    END IF;
  END IF; -- Update - Delete - Old Qtys


 -- UPDATING inventory
 IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
  IF (old.M_PRODUCT_ID IS NOT NULL AND OLD.M_LOCATOR_ID IS NOT NULL) THEN
    SELECT COUNT(*) INTO V_STOCKED FROM M_PRODUCT WHERE M_Product_ID=OLD.M_PRODUCT_ID AND IsStocked = 'Y' AND ProductType = 'I';
    IF V_STOCKED > 0  THEN
        PERFORM M_UPDATE_INVENTORY(OLD.weight, OLD.AD_ORG_ID, OLD.UPDATEDBY, OLD.M_PRODUCT_ID, OLD.M_LOCATOR_ID, OLD.M_ATTRIBUTESETINSTANCE_ID, OLD.C_UOM_ID, OLD.M_PRODUCT_UOM_ID, NULL, NULL, NULL, v_qtyold, v_qtyorderold);
    END IF;
  END IF;
 END IF;
 IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
   IF (NEW.M_PRODUCT_ID IS NOT NULL AND NEW.M_LOCATOR_ID IS NOT NULL) THEN
    SELECT COUNT(*) INTO V_STOCKED FROM M_PRODUCT WHERE M_Product_ID=NEW.M_PRODUCT_ID AND IsStocked = 'Y' AND ProductType = 'I';
    IF V_STOCKED > 0 THEN
        PERFORM M_UPDATE_INVENTORY(NEW.weight, NEW.AD_ORG_ID, NEW.UPDATEDBY, NEW.M_PRODUCT_ID, NEW.M_LOCATOR_ID,NEW.M_ATTRIBUTESETINSTANCE_ID, NEW.C_UOM_ID,NEW.M_PRODUCT_UOM_ID, NULL, NULL, NULL, v_qty, v_qtyorder);
    END IF;
   END IF;
   if new.movementqty<0 and substr(coalesce(new.description,''),1,4)!='*R*:'  then
           RAISE EXCEPTION '%', '@noNegativeQtyInTransaction@'; 
   end if;
 END IF;
 -- Fill serial or Batch Numbers fully automatically, if configured. 
 IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' and (new.m_locator_id!=old.m_locator_id or new.m_product_id!=old.m_product_id or old.movementqty!=new.movementqty)) THEN
    select isserialtracking,isbatchtracking into v_serial,v_batch from m_product where m_product_id=new.m_product_id;
    if c_getconfigoption('autoselectlotnumber',new.ad_org_id)='Y'  and  v_movementtype = ('V+') and v_batch='Y' and v_serial='N' and
        (select coalesce(description,'') from m_inout where m_inout_id=new.m_inout_id) not like '(*R*: %' then
	delete from  snr_minoutline where m_inoutline_id=new.m_inoutline_id; 	    
	v_tempin:= new.m_inoutline_id;
        if (select m_product_uom_id from m_inoutline where m_inoutline_id=new.M_INOUTLINE_ID) is not null then
            FOR counti IN 1..round(new.quantityorder,0)
            loop
                 if counti < new.quantityorder then 
                    insert into snr_minoutline(snr_minoutline_id,AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,m_inoutline_id,quantity,lotnumber )
                    values (get_uuid(),new.AD_CLIENT_ID, new.AD_ORG_ID,  new.CREATEDBY, new.UPDATEDBY,new.m_inoutline_id,round(new.movementqty/new.quantityorder,0),getAutoLotNo(new.ad_org_id, 'N' ,v_tempin)); 
                 else
                    v_batchqty:=new.movementqty-(select coalesce(sum(quantity),0) from snr_minoutline where m_inoutline_id=new.m_inoutline_id);
                    insert into snr_minoutline(snr_minoutline_id,AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,m_inoutline_id,quantity,lotnumber )
                    values (get_uuid(),new.AD_CLIENT_ID, new.AD_ORG_ID,  new.CREATEDBY, new.UPDATEDBY,new.m_inoutline_id,v_batchqty,getAutoLotNo(new.ad_org_id, 'N' ,v_tempin)); 
                 end if;
                 counti:=counti+1;
            end loop;
        else
            insert into snr_minoutline(snr_minoutline_id,AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,m_inoutline_id,quantity,lotnumber )
                    values (get_uuid(),new.AD_CLIENT_ID, new.AD_ORG_ID,  new.CREATEDBY, new.UPDATEDBY,new.m_inoutline_id,new.movementqty,getAutoLotNo(new.ad_org_id, 'N' ,v_tempin)); 
                    counti:=counti+1;
        end if; 
    end if;
	       
    if c_getconfigoption('autoaddbatchandserial2delivery',new.ad_org_id)='Y'  and  v_movementtype = 'C-' and 
       (select coalesce(description,'') from m_inout where m_inout_id=new.m_inout_id) not like '(*R*: %' then
       delete from  snr_minoutline where m_inoutline_id=new.m_inoutline_id;
       v_qty:=0;
       if v_serial='Y' and v_batch='N' then
        for v_cur in (select * from snr_masterdata where m_product_id=new.m_product_id and m_locator_id=new.m_locator_id order by firstseen)
        LOOP
                if v_qty=new.movementqty then
                    exit;
                end if;
                insert into snr_minoutline(snr_minoutline_id,AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,m_inoutline_id,quantity,serialnumber)
                values (get_uuid(),new.AD_CLIENT_ID, new.AD_ORG_ID,  new.CREATEDBY, new.UPDATEDBY,new.m_inoutline_id,1,v_cur.serialnumber);
                v_qty:=v_qty+1;
        END LOOP;
       end if;
       if v_serial='N' and v_batch='Y' then
        for v_cur in (select l.qtyonhand,m.batchnumber from snr_batchlocator l,snr_batchmasterdata m where m.m_product_id=new.m_product_id 
                       and l.m_locator_id=new.m_locator_id and m.snr_batchmasterdata_id=l.snr_batchmasterdata_id and l.qtyonhand>0 order by m.firstseen)
        LOOP
            if v_qty=new.movementqty then
                    exit;
            end if;
            if v_cur.qtyonhand > new.movementqty-v_qty then
                v_batchqty:=new.movementqty-v_qty;
            else
                v_batchqty:=v_cur.qtyonhand;
            end if;
            insert into snr_minoutline(snr_minoutline_id,AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,m_inoutline_id,quantity,lotnumber )
                values (get_uuid(),new.AD_CLIENT_ID, new.AD_ORG_ID,  new.CREATEDBY, new.UPDATEDBY,new.m_inoutline_id,v_batchqty,v_cur.batchnumber);
            v_qty:=v_qty+v_batchqty;
        END LOOP;
       end if;
       if v_serial='Y' and v_batch='Y' then
        for v_cur in (select l.qtyonhand,m.batchnumber,l.snr_batchmasterdata_id from snr_batchlocator l,snr_batchmasterdata m where m.m_product_id=new.m_product_id 
                       and l.m_locator_id=new.m_locator_id and m.snr_batchmasterdata_id=l.snr_batchmasterdata_id order by m.firstseen)
        LOOP           
            for v_cur2 in (select * from snr_masterdata where snr_batchmasterdata_id=v_cur.snr_batchmasterdata_id and m_locator_id=new.m_locator_id)
            LOOP
                if v_qty=new.movementqty then
                    exit;
                end if;
                insert into snr_minoutline(snr_minoutline_id,AD_CLIENT_ID, AD_ORG_ID,  CREATEDBY, UPDATEDBY,m_inoutline_id,quantity,lotnumber, serialnumber)
                    values (get_uuid(),new.AD_CLIENT_ID, new.AD_ORG_ID,  new.CREATEDBY, new.UPDATEDBY,new.m_inoutline_id,1,v_cur.batchnumber,v_cur2.serialnumber);
                v_qty:=v_qty+1;
            END LOOP;
        END LOOP;
       end if;
    end if; -- autoaddbatchandserial2delivery /  autoaddbatchandserialatreceipt
 END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;


ALTER FUNCTION public.m_inoutline_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION m_inout_create(p_pinstance_id character varying, OUT p_inout_id character varying, p_order_id character varying, p_invoice_id character varying, p_forcedelivery character, p_locator_id character varying) RETURNS character varying
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
 Contributions: Bugfix,Accounting-Date must be same Acct-Date than Order ACCT-Date
                Ext.: Take Shipment-Assignments from Order, if there
                Don't create Shipments that have only Freight Products
                Removed Warehouse from Orderline-Cursor (Each Order schoud be Created in One Shipment even if it has different Warehouses)
                Disabled secondary UOM in Mat-Transaction
                2nd UOM is not transacted to Storage. - It is only Used on Orders, Invoices and  in InOut-
                Order ID and Invoice ID are OBSOLETE

For Manual Shipments a new Function was Created - This one is tooo chaotic.
*************************************************************************************************************************************************/



/* *************************************************************************
  * $Id: M_InOut_Create.sql,v 1.17 2003/09/05 04:58:06 jjanke Exp $
  ***
  * Title: Create Shipment from Order
  * Description:
  * Order Loop goes though all open orders, where we would need to ship something
  *  if forced or if there is a line to ship
  *   create InOut document header
  *   for all qualifying order lines
  *    check every locator availability and if qty available
  *     create InOut line
  *
  * Order and reservation is updated when posting
  * as there should not be a delay between creating + posting it
  *
  * For each Warehouse create lines (with exception if Direct Ship's),
  * create also lines for non-stocked, ad_hoc products or comments
  * 
  ************************************************************************/
  -- Logistice
  v_result NUMERIC(1):=1;
  v_Message character varying:=''; --OBTG:VARCHAR2--
  result_String character varying:=''; --OBTG:VARCHAR2--
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    v_allownegativestock CHAR(1);
    v_orderdoc varchar;
    v_NextNo varchar;
   
    v_Record_ID VARCHAR(32):=NULL; --OBTG:VARCHAR2--
    v_Selection VARCHAR(1):='N'; --OBTG:VARCHAR2--
   
    -- Orders to process  - one per warehouse
    Cur_Lines RECORD;
    --
    CREATE_FROM_INVOICE boolean:=false;
    v_DocType_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_DocumentNo VARCHAR(40)='' ; --OBTG:VARCHAR2--
    v_2ndUOMQty NUMERIC;
    v_LocatorQty NUMERIC;
    --
    v_lines NUMERIC:=0;
    v_count NUMERIC:=0;
    Next_Line BOOLEAN:=false;
    FINISH_PROCESS BOOLEAN:=false;
    v_issotrx varchar;
    v_serial varchar;
    v_user varchar;
    v_OrderId varchar:='';
    v_BpartnerId varchar:='';
     v_draftexists numeric:=0;
    v_org varchar;
    v_order_delivered_count numeric:=0;
    v_lineid varchar;
    v_isserial boolean:=false;
    v_batch   varchar;
  BEGIN
    -- Process Parameters
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Chec  k for serial execution
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      SELECT COUNT(*)
      INTO v_count
      FROM AD_PINSTANCE
      WHERE AD_PROCESS_ID IN(SELECT AD_PROCESS_ID FROM AD_PINSTANCE WHERE AD_PInstance_ID=p_PInstance_ID)
        AND IsProcessing='Y'
        AND AD_PInstance_ID<>p_PInstance_ID;
      IF(v_count>0) THEN
        RAISE EXCEPTION '%', '@SerialProcessStillRunning@' ; --OBTG:-20000--
      END IF;
      --  Update AD_PInstance
      RAISE NOTICE '%','M_InOut_Create - Processing ' || p_PInstance_ID ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
      
      FOR Cur_Parameter IN
        (SELECT i.Record_ID, p.ParameterName, p.P_String, p.P_Number, p.P_Date, 
          p.AD_CLIENT_ID, ci.allownegativestock
        FROM AD_ClientInfo ci, AD_PInstance i LEFT JOIN AD_PInstance_Para p ON i.AD_PInstance_ID=p.AD_PInstance_ID
        WHERE i.AD_PInstance_ID=p_PInstance_ID
          AND p.ad_client_id = ci.ad_client_id
        ORDER BY p.SeqNo) LOOP
        v_allownegativestock := cur_parameter.allownegativestock;
        v_Record_ID:=Cur_Parameter.Record_ID;
      END LOOP; -- Get Parameter
      RAISE NOTICE '%','  v_Record_ID=' || v_Record_ID ;
    ELSIF(p_Invoice_ID IS NOT NULL) THEN
      CREATE_FROM_INVOICE:=true;
      SELECT ad_clientinfo.allownegativestock
      INTO  v_allownegativestock
      FROM ad_clientinfo, c_invoice
      where ad_clientinfo.ad_client_id = c_invoice.ad_client_id
      and c_invoice_id = p_invoice_id;
    ELSE
      v_Record_ID:=p_Order_ID;
      RAISE NOTICE '%','--<<M_InOut_Create>> Order_ID=' || v_Record_ID;
      SELECT ad_clientinfo.allownegativestock
      INTO  v_allownegativestock
       FROM ad_clientinfo, c_order
      where ad_clientinfo.ad_client_id = c_order.ad_client_id
      and c_order_id = v_Record_ID;

    END IF;

    
    BEGIN --BODY

      -- Implementing Manual Shipments 
      select count(*) into v_count from c_generateminoutmanual where m_inoutline_id is null and pinstance_id=p_pinstance_id;
      
      IF(v_count>0) THEN
        /**************************************************************************
        * Reimplemented with Generate shipmentsmanual
        *************************************************************************/
        FOR Cur_lines in (SELECT ol.*,  gm.Qty AS pendingqty, gm.deliverycomplete as pendingdeliverycomplete,o.c_bpartner_id,
                                 gm.m_locator_id pendinglocator,gm.c_generateminoutmanual_id,trunc(coalesce(gm.movementdate,now())) as MovementDate
                             FROM c_orderline ol, c_generateminoutmanual gm,c_order o where o.c_order_id=ol.c_order_id and
                                  ol.c_orderline_id=gm.c_orderline_id and gm.m_inoutline_id is null and pinstance_id=p_pinstance_id
                             ORDER By o.c_bpartner_id,gm.c_order_id,ol.line for update)
        LOOP
              -- New shipment
              If (v_OrderId!=Cur_lines.c_order_id and (Cur_lines.pendingdeliverycomplete!='C' or v_OrderId='')) 
                 or (Cur_lines.pendingdeliverycomplete='C' and v_BpartnerId!=Cur_lines.c_bpartner_id) then
                 -- activate just created Transaction.. 
                 if  v_OrderId!='' then 
                       if v_lines=0 and v_draftexists=0 then -- no lines created.
                          delete from M_INOUT where M_InOut_ID=p_InOut_ID;
                          v_order_delivered_count:=v_order_delivered_count-1;
                       else
                             if (v_issotrx='Y'  and v_draftexists=0 and c_getconfigoption('activateshipmentautomatically',v_org)='Y') or (v_issotrx='N' and c_getconfigoption('activatereceiptautomatically',v_org)='Y') then
                                if v_isserial then
                                   v_Message:='@zssm_MaterialReceivedSerialRegistrationNeccessary@'|| v_Message;
                                else
                                   PERFORM M_INOUT_POST(NULL, p_InOut_ID) ;
                                end if;
                             end if;
                             if v_issotrx='Y' and v_draftexists=0 then
                                 v_Message:=v_Message||'@ShipmentCreated@: ' || zsse_htmlLinkDirectKey('../GoodsMovementcustomer/GoodsMovementcustomer_Relation.html',p_InOut_ID,v_DocumentNo)||'<br />';
                             end if;
                             if v_issotrx='N' and v_draftexists=0 then
                                 v_Message:=v_Message||'@ReceiptCreated@: ' || zsse_htmlLinkDirectKey('../GoodsMovementVendor/GoodsMovementVendor_Relation.html',p_InOut_ID,v_DocumentNo)||'<br />';
                             end if;
                       end if;
                 end if;
                 v_OrderId:=Cur_lines.c_order_id;
                 v_BpartnerId:=Cur_lines.c_bpartner_id;
                 SELECT C_DocTypeShipment_ID,c_order.issotrx INTO v_DocType_ID,v_issotrx,v_org FROM C_DOCTYPE,c_order  WHERE C_DOCTYPE.C_DocType_ID=c_order.C_DocType_Id and c_order.c_order_id=Cur_lines.c_order_id;
                 SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(v_DocType_ID, Cur_lines.ad_org_ID, 'Y') ;
                 IF(v_DocumentNo IS NULL) THEN
                    SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_M_InOut', Cur_lines.ad_org_ID, 'Y') ;
                 END IF;
                 select get_uuid() into p_InOut_ID;
                 select updatedby into v_user from c_generateminoutmanual where c_generateminoutmanual_id=Cur_lines.c_generateminoutmanual_id;
                 -- Check if Draft exist.
                 select count(*) into v_draftexists from   m_inoutline il,m_inout i where il.c_orderline_id =Cur_lines.c_orderline_id and il.m_inout_id=i.m_inout_id and i.docstatus='DR'; 
                 if v_draftexists>0 then
                    select i.m_inout_id,documentno into p_InOut_ID,v_DocumentNo from   m_inoutline il,m_inout i where il.c_orderline_id =Cur_lines.c_orderline_id and il.m_inout_id=i.m_inout_id and i.docstatus='DR'; 
                    if v_issotrx='Y' then     
                              v_Message:=v_Message||'@DraftExistsCannotGenerate@ :' || zsse_htmlLinkDirectKey('../GoodsMovementcustomer/GoodsMovementcustomer_Relation.html',p_InOut_ID,v_DocumentNo)||'<br />';
                    else
                              v_Message:=v_Message||'@DraftExistsCannotGenerate@ :' || zsse_htmlLinkDirectKey('../GoodsMovementVendor/GoodsMovementVendor_Relation.html',p_InOut_ID,v_DocumentNo)||'<br />';
                    end if;
                 else
                       -- Create header
                       -- Date Now as DateAcct (Buchungsdatum) movementdate changed from cur_lines.MovementDate to trunc now
                       INSERT INTO M_INOUT
                          (M_InOut_ID, C_Order_ID, IsSOTrx, AD_Client_ID,
                          AD_Org_ID, CreatedBy, UpdatedBy, DocumentNo, C_DocType_ID,
                          Description, MovementType, MovementDate,
                          DateAcct, C_BPartner_ID, C_BPartner_Location_ID, AD_User_ID,
                          M_Warehouse_ID, POReference, DateOrdered, DeliveryRule,
                          FreightCostRule, FreightAmt, 
                          DeliveryViaRule, M_Shipper_ID, PriorityRule, DocStatus, DocAction, Processing,
                          Processed, SALESREP_ID,
                                      a_asset_id,
                                      c_project_id,
                                      c_projecttask_id,
                          DELIVERY_LOCATION_ID,c_incoterms_id,weight,weight_uom,deliverylocationtext,internalnote) 
                       select p_InOut_ID,case when Cur_lines.pendingdeliverycomplete='C' then null else C_Order_ID end as c_order_id, IsSOTrx,Cur_lines.AD_Client_ID,Cur_lines.AD_Org_ID,v_user,v_user,
                               v_DocumentNo,v_DocType_ID,Description,
                               case IsSOTrx when 'Y' then 'C-' else 'V+' end as MovementType,trunc(now()),
                               trunc(now()), C_BPartner_ID, C_BPartner_Location_ID, AD_User_ID,M_Warehouse_ID, POReference, DateOrdered, DeliveryRule,
                               FreightCostRule, FreightAmt, 
                                DeliveryViaRule, M_Shipper_ID, PriorityRule, 'DR', 'CO', 'N',
                               'N', SALESREP_ID, a_asset_id, c_project_id, c_projecttask_id,delivery_location_id,c_incoterms_id,weight,weight_uom,deliverylocationtext,internalnote
                       from c_order where c_order_id=Cur_lines.c_order_id;
                       v_order_delivered_count:=v_order_delivered_count+1;
                 end if;
                 v_lines:=0;
                end if; -- New schipment
                -- Create a Line
                 select isserialtracking,isbatchtracking into v_serial,v_batch from m_product where m_product_id=Cur_lines.m_product_id;
                -- check availability.
                if v_issotrx='Y' then
                      v_LocatorQty:=m_bom_qty_onhand(Cur_lines.m_product_id, null,Cur_lines.pendinglocator);
                      if v_LocatorQty < Cur_lines.pendingqty and v_allownegativestock='N' and p_ForceDelivery='N' then
                         select documentno into v_orderdoc from c_order where c_order_id=Cur_lines.c_order_id;
                         v_Message:=v_Message|| '@Order@: ' ||v_orderdoc||',  @OrderLine@: ' || Cur_lines.Line || ', @ForProduct@ ' || zssi_getproductname(Cur_lines.m_product_id,'de_DE') || ': @notEnoughStock@<br />';
                         Next_Line:=true;
                      end if;
                end if;
                if Next_Line=false and v_draftexists=0 and Cur_lines.pendingqty!=0 then
                   if Cur_lines.m_product_uom_id is not null then
                      v_2ndUOMQty:=Cur_lines.pendingqty*Cur_lines.quantityorder/Cur_lines.qtyordered;
                   else
                      v_2ndUOMQty:=null;
                   end if;
                   v_lines:=v_lines + 10;
                   select get_uuid() into v_lineid;
                   INSERT INTO M_INOUTLINE
                              (M_InOutLine_ID, Line, M_InOut_ID, C_OrderLine_ID,
                              AD_Client_ID, AD_Org_ID, CreatedBy, UpdatedBy, M_Product_ID,
                              C_UOM_ID, M_Locator_ID, MovementQty, Description,
                              IsInvoiced,QuantityOrder, M_Product_Uom_ID,
                                                          a_asset_id,
                                                          c_project_id,
                                                          c_projecttask_id, m_attributesetinstance_id)
                            VALUES
                              (v_lineid, v_lines, p_InOut_ID, Cur_lines.C_OrderLine_ID,
                              Cur_lines.AD_Client_ID, Cur_lines.AD_Org_ID,  v_user,v_user, Cur_lines.M_Product_ID,
                              Cur_lines.C_UOM_ID, Cur_lines.pendinglocator, Cur_lines.pendingqty, Cur_lines.Description,
                              'N',v_2ndUOMQty,Cur_lines.m_product_uom_id,
                                                          Cur_lines.a_asset_id,
                                                          Cur_lines.c_project_id,
                                                          Cur_lines.c_projecttask_id, cur_lines.m_attributesetinstance_id);
                   update c_generateminoutmanual set m_inoutline_id=v_lineid  where c_generateminoutmanual_id=Cur_lines.c_generateminoutmanual_id;
                   if v_serial='Y'  or v_batch='Y' then
                       v_isserial:=true;
                       if v_issotrx='Y' then     
                            v_Message:=v_Message||zsse_htmlLinkDirectKey('../GoodsMovementcustomer/Lines_Relation.html',v_lineid,'Serial Number Tracking')||'<br />';
                       else
                             v_Message:=v_Message||zsse_htmlLinkDirectKey('../GoodsMovementVendor/Lines_Relation.html',v_lineid,'Serial Number Tracking')||'<br />';
                       end if;
                   end if;
                end if; -- next line 
                -- Only on 0-Lines (No line Created) Set Delivery Complete on Order
                -- For all other Lines Delivery Complete is set only after Activating the In-Out Transaction
                if Cur_lines.pendingqty=0 and Cur_lines.pendingdeliverycomplete='Y' then
                     UPDATE C_ORDERLINE SET deliverycomplete='Y' WHERE C_OrderLine_ID=Cur_lines.C_OrderLine_ID;
                end if;
            Next_Line:=false;             
        END LOOP; --Cur_lines
        if v_lines=0 and v_draftexists=0 then -- no lines created.
             delete from M_INOUT where M_InOut_ID=p_InOut_ID;
             v_order_delivered_count:=v_order_delivered_count-1;
        else
          if (v_issotrx='Y' and v_draftexists=0 and c_getconfigoption('activateshipmentautomatically',v_org)='Y') or (v_issotrx='N' and c_getconfigoption('activatereceiptautomatically',v_org)='Y') then
               if v_isserial=true then
                   v_Message:='@zssm_MaterialReceivedSerialRegistrationNeccessary@'|| v_Message;
               else
                   PERFORM M_INOUT_POST(NULL, p_InOut_ID) ;
                   if (select result from ad_pinstance where ad_pinstance_id=p_InOut_ID)=1 then
                        v_Message:=v_Message||(select errormsg from ad_pinstance where ad_pinstance_id=p_InOut_ID);
                   else
                        raise exception '%', (select errormsg from ad_pinstance where ad_pinstance_id=p_InOut_ID);
                   end if;
               end if;
          end if;
          if v_issotrx='Y' and v_draftexists=0 then
             v_Message:=v_Message||'@ShipmentCreated@: ' || zsse_htmlLinkDirectKey('../GoodsMovementcustomer/GoodsMovementcustomer_Relation.html',p_InOut_ID,v_DocumentNo)||'<br />';
          end if;
          if v_issotrx='N' and v_draftexists=0 then
             v_Message:=v_Message||'@ReceiptCreated@: ' || zsse_htmlLinkDirectKey('../GoodsMovementVendor/GoodsMovementVendor_Relation.html',p_InOut_ID,v_DocumentNo)||'<br />';
          end if;
          v_result :=1;
        END IF;
      END IF; -- count>0
      IF (v_order_delivered_count = 0 and v_draftexists=0) THEN
          v_Message := v_Message||'@ZeroOrdersProcessed@';
          v_result :=1;
      END IF;
      /*************************************************************************/
      ---- <<FINISH_PROCESS>>
      IF(p_PInstance_ID IS NOT NULL) THEN
        --  Update AD_PInstance
      
        RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
        PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_result, v_Message) ;
      ELSE
        RAISE NOTICE '%','--<<M_InOut_Create finished>> ' || v_Message;
      END IF;
      --
      RETURN;
    END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_Message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_Message ;
  IF(p_PInstance_ID IS NOT NULL) THEN
    -- ROLLBACK;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message) ;
  ELSE
    RAISE EXCEPTION '%', SQLERRM;
  END IF;
  p_InOut_ID:='0'; -- Error Indicator
  RETURN;
END ; $_$;


ALTER FUNCTION public.m_inout_create(p_pinstance_id character varying, OUT p_inout_id character varying, p_order_id character varying, p_invoice_id character varying, p_forcedelivery character, p_locator_id character varying) OWNER TO tad;

-- Function: m_internal_consumption_post(character varying)

-- DROP FUNCTION m_internal_consumption_post(character varying);

CREATE OR REPLACE FUNCTION m_internal_consumption_post(pinstance_id character varying)
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
* Contributions: Internal Consumption linked to Projects
                 Update BOM of Project-Task if any to indicate that 
                 Material is fetched from stock
**************************************************************************************************************************************************/

  -- Logistice
  v_ResultStr VARCHAR:=''; --OBTG:VARCHAR2--
  v_Message VARCHAR:=''; --OBTG:VARCHAR2--
  v_Message2 VARCHAR:='';
  Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Result NUMERIC:=1;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    v_IsProcessing CHAR(1) ;
    v_IsProcessed VARCHAR(60) ; --OBTG:VARCHAR2--
    v_NoProcessed NUMERIC:=0;
    v_MoveDate TIMESTAMP;
    v_Client_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_User VARCHAR(32); --OBTG:VARCHAR2--
    v_line NUMERIC;
    v_Count NUMERIC:=0;
    END_PROCESS BOOLEAN:=false;
    V_STOCKED       VARCHAR;
    v_type          VARCHAR;
    v_movementtype character varying;
    v_movqty numeric;
    v_resqty numeric;
    v_new_id VARCHAR(32);
    v_product_name character varying;
    v_projecttask_name character varying;
    v_projecttask_name2 character varying;
    v_bom_id varchar;
    v_category varchar;
    Cur_MoveLine RECORD;
    NextNo VARCHAR(32);
    v_stockedattribute varchar;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    -- Get Parameters
    SELECT i.Record_ID, i.AD_User_ID into Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=PInstance_ID;
    if Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || PInstance_ID;
       Record_ID:=PInstance_ID;
       v_User:='0';
    end if;
    RAISE NOTICE '%','  Record_ID=' || Record_ID ;
    -- Check if there are lines document does
     if (select count(*) from  M_Internal_ConsumptionLINE where M_Internal_Consumption_ID = Record_ID)=0 then
          RAISE EXCEPTION '%', '@NoLinesInDoc@';
     END IF; 
    -- Reading Internal_Consumption
    SELECT MovementDate,
      Processing,
      Processed,
      AD_Client_ID,
      AD_Org_ID,
      movementtype
    INTO v_MoveDate,
      v_IsProcessing,
      v_IsProcessed,
      v_Client_ID,
      v_Org_ID,
      v_movementtype
    FROM M_Internal_Consumption
    WHERE M_Internal_Consumption_ID=Record_ID  FOR UPDATE;
    IF(v_IsProcessing='Y') THEN
          RAISE EXCEPTION '%', '@OtherProcessActive@' ; --OBTG:-20000--
    END IF;
    IF(v_IsProcessed='Y') THEN
      RAISE EXCEPTION '%', '@AlreadyPosted@' ; --OBTG:-20000--
    END IF;
    IF(NOT END_PROCESS) THEN
      v_ResultStr:='CheckingRestrictions';
      SELECT COUNT(*), MAX(line)
      INTO v_Count,v_line
      FROM M_Internal_ConsumptionLine M,
          M_Product P,M_ATTRIBUTESET a
        WHERE M.M_PRODUCT_ID=P.M_PRODUCT_ID AND P.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id and a.ismandatory='Y'
          AND COALESCE(M.M_ATTRIBUTESETINSTANCE_ID, '0') = '0'
        AND M.M_Internal_Consumption_ID=Record_ID;
      IF v_Count<>0 THEN
       RAISE EXCEPTION '%', '@Inline@ '||v_line||' '||'@productWithoutAttributeSet@' ; --OBTG:-20000--
      END IF;
    END IF;--END_PROCESS
    IF(NOT END_PROCESS) THEN
      -- Start Processing ------------------------------------------------------
      v_ResultStr:='LockingInternal_Consumption';
      UPDATE M_Internal_Consumption
        SET Processing='Y'
      WHERE M_Internal_Consumption_ID=Record_ID;
      -- Commented by cromero 19102006 -- COMMIT;
      /**
      * Accounting first step
      */
        FOR Cur_MoveLine IN
          (SELECT *
          FROM M_Internal_ConsumptionLine
          WHERE M_Internal_Consumption_ID=Record_ID
          ORDER BY Line
          )
        LOOP
          v_ResultStr:='Transaction for line' || Cur_MoveLine.Line;
          -- Check Stocked Product
          SELECT p.isstocked,p.producttype,a.IsStockTracking  INTO V_STOCKED ,v_type,v_stockedattribute
            FROM M_PRODUCT p left join M_ATTRIBUTESET a on p.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id
            WHERE M_Product_ID=Cur_MoveLine.M_PRODUCT_ID;
	  select name into v_product_name from m_product where m_product.m_product_id=Cur_MoveLine.m_product_id;
	  select name into v_projecttask_name from c_projecttask where c_projecttask.c_projecttask_id=Cur_MoveLine.c_projecttask_id;
	  v_movqty:= case v_movementtype when 'D-' then -1 else 1 end *  Cur_MoveLine.movementqty;
          if V_STOCKED='Y' and v_type='I' then
              -- DO Stock Transaction
              SELECT * INTO  NextNo FROM AD_Sequence_Next('M_Transaction', v_Client_ID);
              INSERT
              INTO M_Transaction
                (
                  M_Transaction_ID, AD_Client_ID, AD_Org_ID, IsActive,
                  Created, CreatedBy, Updated, UpdatedBy,
                  MovementType, M_Locator_ID, M_Product_ID, M_AttributeSetInstance_ID,
                  MovementDate, MovementQty, M_Internal_ConsumptionLine_ID,C_UOM_ID,c_project_id,c_projecttask_id,snr_masterdata_id,weight
                )
                VALUES
                (
                  NextNo, Cur_MoveLine.AD_Client_ID, Cur_MoveLine.AD_Org_ID, 'Y',
                  TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
                  v_movementtype, Cur_MoveLine.M_Locator_ID, Cur_MoveLine.M_Product_ID, 
                  case when coalesce(v_stockedattribute,'N')='Y' then COALESCE(Cur_MoveLine.M_AttributeSetInstance_ID, '0') else '0' end, 
                  v_MoveDate, v_movqty, Cur_MoveLine.M_Internal_ConsumptionLine_ID, Cur_MoveLine.C_UOM_ID, Cur_MoveLine.c_project_id,Cur_MoveLine.c_projecttask_id,
                  Cur_MoveLine.snr_masterdata_id,Cur_MoveLine.weight
                );
              -- TO
              SELECT * INTO  v_Result, v_Message2 FROM M_Check_Stock(Cur_MoveLine.M_Product_ID, v_Client_ID, v_Org_ID) ;
              IF v_Result=0 THEN
					v_Message:=v_Message2;
                    RAISE EXCEPTION '%', v_Message||' '||'@line@'||' '||Cur_MoveLine.line ; --OBTG:-20000--
              END IF;
          END IF;
          -- SZ Update BOM of Project-Task if any to indicate that Material is fetched from stock
          if (Cur_MoveLine.c_projecttask_id is not null and v_type='I') then
                if v_movementtype='P+' then
                    -- Update Produced Quantity
                    update c_projecttask set qtyproduced=qtyproduced+v_movqty where c_projecttask_id=Cur_MoveLine.c_projecttask_id;
                end if;
                select count(*) into v_count from zspm_projecttaskbom where c_projecttask_id=Cur_MoveLine.c_projecttask_id and m_product_id=Cur_MoveLine.m_product_id
                                             and directship='N';
                if v_count=0 and v_movementtype!='P+' then --insert
                    v_bom_id:=get_uuid();
                    -- Look if this is a mashine, that schould be returned after consumption
                    select count(*) into v_count from snr_internal_consumptionline snl,snr_masterdata snr,ma_machine m where m.snr_masterdata_id=snr.snr_masterdata_id
                                                        and snl.serialnumber=snr.serialnumber and m.ismovedinprojects='Y' and snl.m_internal_consumptionline_id=Cur_MoveLine.M_Internal_ConsumptionLine_ID;
                    --                                 
                    insert into zspm_projecttaskbom (zspm_projecttaskbom_id, c_projecttask_id,  ad_client_id, ad_org_id,createdby,updatedby, m_product_id, quantity, description,
                            actualcosamount,qtyreceived, date_plan,isreturnafteruse,m_locator_id,line)
                    values ( v_bom_id, Cur_MoveLine.c_projecttask_id, Cur_MoveLine.ad_client_id,Cur_MoveLine.ad_org_id,v_User, v_User, Cur_MoveLine.m_product_id,
                            0, Cur_MoveLine.description,(m_get_product_cost(Cur_MoveLine.m_product_id, to_date(now()), null, Cur_MoveLine.ad_org_id) * (v_movqty*-1)),
                            v_movqty*-1,to_date(now()),case when v_count=1 then 'Y' else 'N' end,Cur_MoveLine.M_Locator_ID,
                            (select coalesce(max(line)+10,10) from zspm_projecttaskbom where c_projecttask_id=Cur_MoveLine.c_projecttask_id));
                else -- update
                -- Update existing lines. If we have a line (zspm_projecttaskbom_id is not null) we take that.
                -- Otherwise:
                -- Fill up next found line              
                -- Get the Cost on Project, Update QTYs
                if Cur_MoveLine.zspm_projecttaskbom_id is null then
                        select zspm_projecttaskbom_id into v_bom_id from zspm_projecttaskbom where c_projecttask_id=Cur_MoveLine.c_projecttask_id  and m_product_id=Cur_MoveLine.m_product_id limit 1;
                else
                        v_bom_id:=  Cur_MoveLine.zspm_projecttaskbom_id;
                end if;
                if v_movementtype!='P+' then
                        update zspm_projecttaskbom set qtyreceived=qtyreceived-v_movqty,
                                actualcosamount=(m_get_product_cost(Cur_MoveLine.m_product_id,to_date(now()),null,Cur_MoveLine.AD_Org_ID)*(qtyreceived-v_movqty))
                        where zspm_projecttaskbom_id=v_bom_id; 
                        --raise notice '%','--------------------------Ask Cost:'||(select to_char(sum(cost)) from m_costing where m_product_id=Cur_MoveLine.m_product_id);
                end if;
                end if; -- update
                if (v_projecttask_name2!=v_projecttask_name or v_projecttask_name2 is null) then
                        select p.projectcategory into v_category from c_project p,c_projecttask t where p.c_project_id=t.c_project_id and t.c_projecttask_id=  Cur_MoveLine.c_projecttask_id;
                        if v_category in ('P','S','M') then
                                v_Message:=v_Message||'@MaterialConsumption4ProjectCompleted@'|| zsse_htmlLinkDirectKeyGridView('../org.openbravo.zsoft.project.Projects/MaterialDisposition0F6DE779327E4790A3A9A11779D0713D_Relation.html',v_bom_id,v_projecttask_name)||'<br />';
                        end if;
                        if v_category in ('PRO') and v_movementtype!='P+' then
                                v_Message:=v_Message||'@MaterialConsumption4ProductionCompleted@'|| zsse_htmlLinkDirectKeyGridView('../org.openbravo.zsoft.serprod.ProductionOrder/Billofmaterials9D775024A45140F0920B936C14A18527_Relation.html',v_bom_id,v_projecttask_name)||'<br />';
                        end if;
                        if v_category in ('PRO') and v_movementtype='P+' then
                                v_Message:=v_Message||'@Material4ProductionCompleted@'|| zsse_htmlLinkDirectKey('../org.openbravo.zsoft.serprod.ProductionOrder/WorkSteps035860BB9D4F4D08878CED2F371D7201_Relation.html',Cur_MoveLine.c_projecttask_id,v_projecttask_name)||'<br />';
                                if c_getconfigoption('closeworkstepafterproduction',Cur_MoveLine.ad_org_id)='Y' then
                                    update c_projecttask set iscomplete='Y',ended=now() where c_projecttask_id=Cur_MoveLine.c_projecttask_id;
                                end if;
                        end if;
                end if;
                v_projecttask_name2:=v_projecttask_name;
            end if; --projecttask
        END LOOP;
    END IF;--END PROCESS
    IF(NOT END_PROCESS) THEN
      -- End Processing --------------------------------------------------------
      ---- <<END_PROCESSING>>
      v_ResultStr:='UnLockingMovement';
      UPDATE M_Internal_Consumption
        SET Processed='Y'
      WHERE M_Internal_Consumption_ID=Record_ID;
      -- Commented by cromero 19102006 -- COMMIT;
    END IF;--END_PROCESS
    ---- <<END_PROCESS>>
    -- SZ: Do the Accounting-Process for internal Consumption
    PERFORM ZSFI_POSTINTERNALCONSUMPTION2GL(Record_ID,v_User);
    -- Do Update the Material Plan with new Stock qty's
    PERFORM mrp_inoutplanupdate(null);
    -- Update Costing on Produced Items
    PERFORM m_updatecostingfromproduction(Record_ID,v_User);
    -- SZ end
    v_ResultStr:='UnLockingMovement';
    UPDATE M_Internal_Consumption
      SET Processing='N'
    WHERE M_Internal_Consumption_ID=Record_ID;
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message;
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, v_User, 'N', v_Result, v_Message) ;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  -- ROLLBACK;
  UPDATE M_Internal_Consumption
    SET Processing='N'
  WHERE M_Internal_Consumption_ID=Record_ID;
  -- Commented by cromero 19102006 -- COMMIT;
  PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION m_internal_consumption_post(character varying) OWNER TO tad;




CREATE OR REPLACE FUNCTION m_inventoryline_trg() RETURNS trigger LANGUAGE plpgsql AS $_$ DECLARE 
  v_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_RO      NUMERIC;
  V_STOCKED NUMERIC;
  v_serial varchar;
  v_batch varchar;
  v_batchno varchar;
  v_cur  record;
  v_i  numeric:=0;
  v_curr numeric;
  /******************************************************************************
  * The contents of this file are subject to the   Compiere License  Version 1.1
  * ("License"); You may not use this file except in compliance with the License
  * You may obtain a copy of the License at http://www.compiere.org/license.html
  * Software distributed under the License is distributed on an  "AS IS"  basis,
  * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
  * the specific language governing rights and limitations under the License.
  * The Original Code is                  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke  and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke, parts
  * created by ComPiere are Copyright (C) ComPiere, Inc.;   All Rights Reserved.
  * Contributor(s): Openbravo SL, OpenZ, Stefan Zimmermann
  * Contributions are Copyright (C) 2001-2006 Openbravo S.L., 2016 OpenZ
  ******************************************************************************/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Get ID
  IF(TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    v_ID:=NEW.M_Inventory_ID;
  ELSE
    v_ID:=OLD.M_Inventory_ID;
  END IF;
  -- ReadOnly Check
  SELECT COUNT(*)
  INTO v_RO
  FROM M_INVENTORY
  WHERE M_Inventory_ID=v_ID
    AND(Processed='Y'
    OR Posted='Y') ;
  IF(v_RO > 0) THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
  -- Updating inventory
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    SELECT COUNT(*)
    INTO V_STOCKED
    FROM M_PRODUCT
    WHERE M_Product_ID=OLD.M_PRODUCT_ID
      AND IsStocked='Y'
      AND ProductType='I';
    IF V_STOCKED > 0 THEN
      PERFORM M_UPDATE_INVENTORY(OLD.weight, OLD.AD_ORG_ID, OLD.UPDATEDBY, OLD.M_PRODUCT_ID, OLD.M_LOCATOR_ID, OLD.M_ATTRIBUTESETINSTANCE_ID, OLD.C_UOM_ID, OLD.M_PRODUCT_UOM_ID, NULL, NULL, NULL, -(OLD.QTYCOUNT-OLD.QTYBOOK), OLD.QUANTITYORDER) ;
    END IF;
  END IF;
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    SELECT COUNT(*)
    INTO V_STOCKED
    FROM M_PRODUCT
    WHERE M_Product_ID=NEW.M_PRODUCT_ID
      AND IsStocked='Y'
      AND ProductType='I';
    IF V_STOCKED > 0 THEN
      PERFORM M_UPDATE_INVENTORY(NEW.weight, NEW.AD_ORG_ID, NEW.UPDATEDBY, NEW.M_PRODUCT_ID, NEW.M_LOCATOR_ID, NEW.M_ATTRIBUTESETINSTANCE_ID, NEW.C_UOM_ID, NEW.M_PRODUCT_UOM_ID, NULL, NULL, NULL,(NEW.QTYCOUNT-NEW.QTYBOOK),(NEW.QUANTITYORDER-NEW.QUANTITYORDERBOOK)) ;
    ELSE
      RAISE EXCEPTION '%', '@inventoryproducthastobestocked@' ;
    END IF;
  END IF;
  
  IF TG_OP = 'INSERT'  THEN
    select isserialtracking,isbatchtracking into v_serial,v_batch from m_product where m_product_id=new.m_product_id;
    if v_serial='Y' then
        --    select distinct a.snr_batchmasterdata_id,a.serialnumber,b.m_attributesetinstance_id from snr_masterdata a,SNR_Serialnumbertracking b 
        --                       where a.snr_masterdata_id=b.snr_masterdata_id and a.m_product_id=new.m_product_id and a.m_locator_id=new.m_locator_id and coalesce(b.m_attributesetinstance_id,'#')=coalesce(new.m_attributesetinstance_id,'#')
        --                       order by a.serialnumber,b.created desc
        for v_cur in (select a.snr_batchmasterdata_id,a.serialnumber from snr_masterdata a
                       where  a.m_product_id=new.m_product_id and a.m_locator_id=new.m_locator_id
                       order by a.serialnumber desc)
        LOOP
            if v_batch='Y' then 
                select batchnumber  into   v_batchno from snr_batchmasterdata where snr_batchmasterdata_id=v_cur.snr_batchmasterdata_id;
            end if;
            insert into snr_inventoryline(snr_inventoryline_id,AD_Client_ID, AD_Org_ID,  CreatedBy,  UpdatedBy,m_inventoryline_id,quantity,lotnumber,serialnumber)
            values(get_uuid(),new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,new.m_inventoryline_id,1,case when v_batch='Y' then v_batchno else null end,v_cur.serialnumber);
            v_i:=v_i+1;
            if v_i=new.qtybook then
                exit;
            end if;
        END LOOP;
    end if;
    if v_serial='N' and v_batch='Y'  then
       v_i:=0;
        for v_cur in (select * from snr_batchlocator_v where m_product_id=new.m_product_id and m_locator_id=new.m_locator_id and qtyonhand>0)
        LOOP
            if v_cur.qtyonhand+v_i>new.qtybook then
                v_curr:=new.qtybook-v_i;
            else
                v_curr:=v_cur.qtyonhand;
            end if;
            insert into snr_inventoryline(snr_inventoryline_id,AD_Client_ID, AD_Org_ID,  CreatedBy,  UpdatedBy,m_inventoryline_id,quantity,lotnumber)
            values(get_uuid(),new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,new.m_inventoryline_id,v_curr,v_cur.batchnumber);
            v_i:=v_i+v_curr;
            if v_i>= new.qtybook then
                exit;
            end if;
        END LOOP;
    end if;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;



CREATE OR REPLACE FUNCTION m_inventory_post(pinstance_id character varying) RETURNS void
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
  * $Id: M_Inventory_Post.sql,v 1.4 2003/09/05 04:58:06 jjanke Exp $
  ***
  * Title: Physical Inventory Post
  * Description:
  * - Update Storage with correct QtyOnHand
  * - Generate Transcation
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Result NUMERIC:=0; -- failure
  v_User VARCHAR(32); --OBTG:VARCHAR2--
  v_IsProcessing CHAR(1) ;
  v_IsProcessed VARCHAR(60) ; --OBTG:VARCHAR2--
  v_NoProcessed NUMERIC:=0;
  v_is_included NUMERIC:=0;
  v_available_period NUMERIC:=0;
  v_is_ready AD_Org.IsReady%TYPE;
  v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
  v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
  v_org_bule_id AD_Org.AD_Org_ID%TYPE;
  --Added by PSarobe 13062007
  v_line NUMERIC;
  v_Aux NUMERIC;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    Cur_Inventorylines RECORD;
    Cur_Lines RECORD;
    -- Parameter Variables
    v_InvDate TIMESTAMP;
    v_Client_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Count NUMERIC:=0;
    rowcount NUMERIC;
    Cur_InvLine RECORD;
    NextNo VARCHAR(32); 
    v_stockedattribute varchar;
    v_weight numeric;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing' ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    SELECT i.Record_ID,
        i.AD_User_ID into v_Record_ID,v_User
      FROM AD_PInstance i
      WHERE i.AD_PInstance_ID=PInstance_ID;     
    if (select count(*) from M_Inventory  WHERE M_Inventory_ID=v_Record_ID)=0 then
        v_Record_ID:=PInstance_ID;
        v_User:='0';
    end if;
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    v_ResultStr:='ReadingInventory';
    SELECT MovementDate,
      Processing,
      Processed,
      AD_Client_ID,
      AD_Org_ID
    INTO v_InvDate,
      v_IsProcessing,
      v_IsProcessed,
      v_Client_ID,
      v_Org_ID
    FROM M_Inventory
    WHERE M_Inventory_ID=v_Record_ID  FOR UPDATE;
  if v_Org_ID is null then
    RAISE EXCEPTION '%', '@SaveErrorRowNotFound@'||v_Record_ID ; --OBTG:-20000--
  END if;
    IF(v_IsProcessing='Y') THEN
      RAISE EXCEPTION '%', '@OtherProcessActive@' ; --OBTG:-20000--
    END IF;
  IF(v_IsProcessed='Y') THEN
      RAISE EXCEPTION '%', '@AlreadyPosted@' ; --OBTG:-20000--
  END IF;
  --RAISE notice '%', 'xxx'||v_Record_ID||'#'||v_IsProcessed||'#'||(select Processed FROM M_Inventory  WHERE M_Inventory_ID=v_Record_ID);
    v_ResultStr:='CheckingRestrictions';
    SELECT COUNT(*), MAX(M.line)
    INTO v_Count, v_line
    FROM M_InventoryLine M,
          M_Product P,M_ATTRIBUTESET a
        WHERE M.M_PRODUCT_ID=P.M_PRODUCT_ID AND P.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id and a.ismandatory='Y' and a.isstocktracking='Y'
          AND COALESCE(M.M_ATTRIBUTESETINSTANCE_ID, '0') = '0'
      AND M.M_Inventory_ID=v_Record_ID;
    IF v_Count<>0 THEN
      RAISE EXCEPTION '%', '@Inline@ '||v_line||' '||'@productWithoutAttributeSet@' ; --OBTG:-20000--
    END IF;
    SELECT COUNT(*), MAX(M.line)
    INTO v_Count, v_line
    FROM M_InventoryLine M,
          M_Product P,M_ATTRIBUTESET a
        WHERE M.M_PRODUCT_ID=P.M_PRODUCT_ID AND P.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id  and a.isstocktracking='N'
          AND COALESCE(M.M_ATTRIBUTESETINSTANCE_ID, '0') != '0'
      AND M.M_Inventory_ID=v_Record_ID;
    IF v_Count<>0 THEN
      RAISE EXCEPTION '%', '@Inline@ '||v_line||' '||'@inventoryWithoutAttributeSet@' ; --OBTG:-20000--
    END IF;
    -- Check for products in multiple lines
        --Added by PSarobe 13062007
        SELECT MAX(count)
        INTO v_Aux
        FROM (
                 SELECT COUNT(*) as count, il.M_Product_ID, COALESCE(il.M_AttributeSetInstance_ID, '0'), COALESCE(il.M_Product_UOM_ID, '0'), il.M_Locator_ID
                 FROM M_Inventoryline il
                 WHERE il.M_INVENTORY_ID = v_Record_ID
                 GROUP BY il.M_Product_ID, COALESCE(il.M_AttributeSetInstance_ID, '0'), COALESCE(il.M_Product_UOM_ID, '0'), il.M_Locator_ID
                 HAVING COUNT(*)>1) A;
        IF v_Aux <>0 THEN
           FOR Cur_Inventorylines IN (SELECT M_Product_ID, COALESCE(M_AttributeSetInstance_ID, '0') AS Atributte, COALESCE(M_Product_UOM_ID, '0') as ProductUOM, M_Locator_ID
                                                                  FROM M_Inventoryline
                                                                  WHERE M_Inventory_Id=v_Record_ID
                                                                  GROUP BY M_Product_ID, COALESCE(M_AttributeSetInstance_ID, '0'), COALESCE(M_Product_UOM_ID, '0'), M_Locator_ID
                                                                  HAVING COUNT(*)>1) LOOP
                                FOR Cur_Lines IN (SELECT line
                                                                  FROM M_Inventoryline
                                                                  WHERE M_PRODUCT_ID = Cur_Inventorylines.M_Product_ID
                                                                  AND COALESCE(M_AttributeSetInstance_ID, '0') = Cur_Inventorylines.Atributte
                                                                  AND COALESCE(M_Product_UOM_ID, '0') = Cur_Inventorylines.ProductUOM
                                                                  AND M_Locator_ID = Cur_Inventorylines.M_Locator_ID
                                                                  AND M_Inventory_Id=v_Record_ID) LOOP

                                v_Message:=v_Message||Cur_Lines.line||', ';

                                END LOOP;
           RAISE EXCEPTION '%', '@Thelines@'||v_Message||' '||'@sameInventorylines@' ; --OBTG:-20000--
           END LOOP;
        END IF;
 
    -- Start Processing ------------------------------------------------------
    -- Check the header belongs to a organization where transactions are posible and ready to use
    SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
    INTO v_is_ready, v_is_tr_allow
    FROM M_INVENTORY, AD_Org, AD_OrgType
    WHERE AD_Org.AD_Org_ID=M_INVENTORY.AD_Org_ID
    AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
    AND M_INVENTORY.M_INVENTORY_ID=v_Record_ID;
    IF (v_is_ready='N') THEN
      RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
    END IF;
    IF (v_is_tr_allow='N') THEN
      RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
    END IF;
    
    SELECT AD_ORG_CHK_DOCUMENTS('M_INVENTORY', 'M_INVENTORYLINE', v_Record_ID, 'M_INVENTORY_ID', 'M_INVENTORY_ID') INTO v_is_included FROM dual;
    IF (v_is_included=-1) THEN
      RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
    END IF;
    
    -- Check the period control is opened (only if it is legal entity with accounting)
    -- Gets the BU or LE of the document
    SELECT AD_GET_DOC_LE_BU('M_INVENTORY', v_Record_ID, 'M_INVENTORY_ID', 'LE')
    INTO v_org_bule_id
    FROM DUAL;
    
    SELECT AD_OrgType.IsAcctLegalEntity
    INTO v_isacctle
    FROM AD_OrgType, AD_Org
    WHERE AD_Org.AD_OrgType_ID = AD_OrgType.AD_OrgType_ID
    AND AD_Org.AD_Org_ID=v_org_bule_id;
    
    IF (v_isacctle='Y') THEN
      SELECT C_CHK_OPEN_PERIOD(v_Org_ID, v_InvDate, 'MMI', NULL) 
      INTO v_available_period
      FROM DUAL;
      
      IF (v_available_period<>1) THEN
        RAISE EXCEPTION '%', '@PeriodNotAvailable@'; --OBTG:-20000--
      END IF;
    END IF;
    

    v_ResultStr:='LockingInventory';
    UPDATE M_Inventory  SET Processing='Y'  WHERE M_Inventory_ID=v_Record_ID;
    -- Commented by cromero 19102006 -- COMMIT;
    /**
    * Create Transaction
    */
      FOR Cur_InvLine IN
        (SELECT *  FROM M_InventoryLine  WHERE M_Inventory_ID=v_Record_ID  ORDER BY Line)
      LOOP
        SELECT a.IsStockTracking  INTO v_stockedattribute
            FROM M_PRODUCT p left join M_ATTRIBUTESET a on p.M_ATTRIBUTESET_ID = a.M_ATTRIBUTESET_id
            WHERE M_Product_ID=Cur_InvLine.M_PRODUCT_ID;
        SELECT * INTO  NextNo FROM AD_Sequence_Next('M_Transaction', v_Client_ID) ;
        INSERT
        INTO M_Transaction
          (
            M_Transaction_ID, AD_Client_ID, AD_Org_ID, IsActive,
            Created, CreatedBy, Updated, UpdatedBy,
            MovementType, M_Locator_ID, M_Product_ID, M_AttributeSetInstance_ID,
            MovementDate, MovementQty, M_InventoryLine_ID, M_Product_UOM_ID,
            QuantityOrder, C_UOM_ID
          )
          VALUES
          (
            NextNo, Cur_InvLine.AD_Client_ID, Cur_InvLine.AD_Org_ID, 'Y',
            TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
            'I+', Cur_InvLine.M_Locator_ID, Cur_InvLine.M_Product_ID, 
            case when coalesce(v_stockedattribute,'N')='Y' then COALESCE(Cur_InvLine.M_AttributeSetInstance_ID, '0') else '0' end, 
            v_InvDate, Cur_InvLine.QtyCount-COALESCE(Cur_InvLine.QtyBook, 0), Cur_InvLine.M_InventoryLine_ID, Cur_InvLine.M_Product_UOM_ID,
            Cur_InvLine.QuantityOrder-COALESCE(Cur_InvLine.QuantityOrderBook, 0), Cur_InvLine.C_UOM_ID
          )
          ;
        -- implementing weight
         update m_storage_detail set weight=Cur_InvLine.weight where M_Product_ID=Cur_InvLine.M_PRODUCT_ID and M_Locator_ID=Cur_InvLine.M_Locator_ID and 
               coalesce(M_AttributeSetInstance_ID,'0')=case when coalesce(v_stockedattribute,'N')='Y' then COALESCE(Cur_InvLine.M_AttributeSetInstance_ID, '0') else '0' end;
        SELECT * INTO  v_Result, v_Message FROM M_Check_Stock(Cur_InvLine.M_Product_ID, v_Client_ID, v_Org_ID) ;
        IF v_Result=0 THEN
          RAISE EXCEPTION '%', v_Message||' '||'@line@'||' '||coalesce(to_char(Cur_InvLine.line),(select value||'-'||name from m_product where m_product_id=Cur_InvLine.M_Product_ID)) ; --OBTG:-20000--
        END IF;
      END LOOP;
 
    v_Result:=1; -- success
  
    v_ResultStr:='UnLockingInventory';
    UPDATE M_Inventory  SET Processed='Y'  WHERE M_Inventory_ID=v_Record_ID;
    -- Commented by cromero 19102006 -- COMMIT;
  
  -- Do Update the Material Plan with new Stock qty's
  PERFORM mrp_inoutplanupdate(null);
  ---- <<END_PROCESS>>
 
    v_ResultStr:='UnLockingInventory';
    UPDATE M_Inventory
      SET Processing='N',
      Updated=TO_DATE(NOW()),
      UpdatedBy=v_User
    WHERE M_Inventory_ID=v_Record_ID;
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished' ;
    RAISE NOTICE '%',v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, v_User, 'N', v_Result, v_Message) ;
    RETURN;
 

EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  --To be fixed or deprecated
  RAISE NOTICE '%',v_Message ;
  --
  -- ROLLBACK;
  --
  UPDATE M_Inventory
    SET 
    Processing='N'
  WHERE M_Inventory_ID=v_Record_ID;
  PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ; $_$;






-- Function: m_bom_qty_onhand(character varying, character varying, character varying)

-- DROP FUNCTION m_bom_qty_onhand(character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION m_bom_qty_onhand(p_product_id character varying, p_warehouse_id character varying, p_locator_id character varying, p_attributesetinstance_id character varying)
  RETURNS numeric AS
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
 Contributions: If There are Production-Reservations
                The reserved quantity must not be available
                Extended Set-Products
******************************************************************************************************************************/
/*
*************************************************************************
* Return quantity on hand for BOM
*/
    v_myWarehouse_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Quantity NUMERIC:=99999; -- unlimited
    v_IsBOM CHAR(1) ;
    v_IsSet CHAR(1) ;
    v_IsStocked CHAR(1) ;
    v_ProductType VARCHAR(60) ;
    v_ProductQty NUMERIC;
    v_uomprec numeric;
    -- Get BOM Product info
  --TYPE RECORD IS REFCURSOR;
    CUR_BOM RECORD;
    --
  BEGIN
    -- Check Parameters
    v_myWarehouse_ID:=p_Warehouse_ID;
    IF(v_myWarehouse_ID IS NULL and p_locator_id is null) THEN
        RETURN 0;
    END IF;
     -- Get product 
    SELECT p.IsBOM, p.ProductType, p.IsStocked,p.issetitem,u.stdprecision
    INTO v_IsBOM, v_ProductType, v_IsStocked,v_IsSet,v_uomprec
    FROM M_PRODUCT p,c_uom u 
    WHERE M_Product_ID=p_Product_ID and u.c_uom_id=p.c_uom_id;
    -- Unlimited capacity if no item
    IF v_ProductType<>'I' OR (v_IsStocked='N' and v_IsSet='N') THEN
      RETURN v_Quantity;
    END IF;
    -- Get qty
    If v_IsSet='Y' then
          -- Calculate Aval. for Set-Items
          for CUR_BOM in (select * from m_product_bom where m_product_id=p_Product_ID)
          LOOP
             v_ProductQty:=m_bom_qty_onhand(CUR_BOM.m_productbom_id,p_warehouse_id,p_locator_id)/CUR_BOM.bomqty;
             --raise notice '%','Component:'||zssi_getproductname(CUR_BOM.m_productbom_id,null)||'#'||CUR_BOM.bomqty||'#'||v_ProductQty;
             if v_ProductQty<v_Quantity then
                v_Quantity:=v_ProductQty;
             end if;
          END LOOP;
          RETURN round(coalesce(v_Quantity,0),v_uomprec);
  
    else
          IF(p_locator_id IS NULL) THEN
            SELECT COALESCE(SUM(QtyOnHand), 0)
                INTO v_ProductQty
                FROM M_STORAGE_DETAIL s where m_locator_id in (select m_locator_id from m_locator where m_warehouse_ID=p_warehouse_ID) and m_product_id=p_product_id
                                                                             and case when p_attributesetinstance_id is not null then m_attributesetinstance_id=p_attributesetinstance_id else 1=1 end;
            RETURN coalesce(v_ProductQty,0);
          else
            SELECT COALESCE(SUM(QtyOnHand), 0)
                INTO v_ProductQty
                FROM M_STORAGE_DETAIL s where m_locator_id = p_locator_id and m_product_id=p_product_id
                                                                             and case when p_attributesetinstance_id is not null then m_attributesetinstance_id=p_attributesetinstance_id else 1=1 end;
            RETURN coalesce(v_ProductQty,0);
          END IF;
    end if;
  RETURN 0;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

-- Overload for Compat. 
CREATE OR REPLACE FUNCTION m_bom_qty_onhand(p_product_id character varying, p_warehouse_id character varying, p_locator_id character varying)
  RETURNS numeric AS
$BODY$ DECLARE 
BEGIN
        return m_bom_qty_onhand(p_product_id ,p_warehouse_id ,p_locator_id,null);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION m_qty_onhandInTime(p_product_id character varying, p_warehouse_id character varying, p_date date)
  RETURNS numeric AS
$BODY$ DECLARE 
 v_qty numeric;
BEGIN
        select SUM(t.MOVEMENTQTY) into v_QTY FROM M_TRANSACTION t, M_LOCATOR l where t.m_product_id=p_product_id and t.m_locator_id=l.m_locator_id and 
        case when p_warehouse_id is not null then l.m_warehouse_id=p_warehouse_id else 1=1 end and MOVEMENTDATE <= p_date;
        return coalesce(v_qty,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION m_qty_inflow(p_product_id character varying, p_warehouse_id character varying)
  RETURNS numeric AS
$BODY$ DECLARE 
 v_qty numeric;
BEGIN
        select coalesce(SUM(ohq.qtyinflow),0) into v_qty from zssi_onhanqty ohq where m_product_id=p_product_id and m_warehouse_id=p_warehouse_id;
        return coalesce(v_qty,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION m_qty_outflow(p_product_id character varying, p_warehouse_id character varying)
  RETURNS numeric AS
$BODY$ DECLARE 
 v_qty numeric;
BEGIN
        select coalesce(SUM(ohq.qtyoutflow),0) into v_qty from zssi_onhanqty ohq where m_product_id=p_product_id and m_warehouse_id=p_warehouse_id;
        return coalesce(v_qty,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION m_qty_avail(p_product_id character varying, p_warehouse_id character varying)
  RETURNS numeric AS
$BODY$ DECLARE 
 v_qty numeric;
BEGIN
        select coalesce(SUM(qtyonhand)-SUM(qtyoutflow),0)  into v_qty from zssi_onhanqty ohq where m_product_id=p_product_id and m_warehouse_id=p_warehouse_id;
        return coalesce(v_qty,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


-- Wareneingang annulieren wäre schön:
-- Trigger geändert...

CREATE OR REPLACE FUNCTION m_ioline_chk_restrictions_trg() RETURNS trigger
AS $BODY$ 
DECLARE 
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
 Contributions:It schould be possible to undo a material Receipt,When receipt is not posted
******************************************************************************************************************************/
  v_Processed VARCHAR(60) ;
  v_M_INOUT_ID VARCHAR(32) ; 
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF TG_OP = 'INSERT' THEN
    v_M_INOUT_ID:=new.M_INOUT_ID;
  ELSE
    v_M_INOUT_ID:=old.M_INOUT_ID;
  END IF;
  
  SELECT processed  INTO v_Processed FROM M_INOUT WHERE M_INOUT_ID=v_M_INOUT_ID;
  IF TG_OP = 'UPDATE' THEN
    IF(v_Processed='Y' AND ((COALESCE(old.LINE, 0) <> COALESCE(new.LINE, 0))
   OR (COALESCE(old.M_PRODUCT_ID, '0') <> COALESCE(new.M_PRODUCT_ID, '0'))
   OR(COALESCE(old.QUANTITYORDER, 0) <> COALESCE(new.QUANTITYORDER, 0))
   OR(COALESCE(old.M_ATTRIBUTESETINSTANCE_ID, '0') <> COALESCE(new.M_ATTRIBUTESETINSTANCE_ID, '0'))
   OR(COALESCE(old.MOVEMENTQTY, 0) <> COALESCE(new.MOVEMENTQTY, 0))
   OR(COALESCE(old.M_PRODUCT_UOM_ID, '0') <> COALESCE(new.M_PRODUCT_UOM_ID, '0'))
   OR(COALESCE(old.C_ORDERLINE_ID, '0') <> COALESCE(new.C_ORDERLINE_ID, '0'))
   OR(COALESCE(old.M_LOCATOR_ID, '0') <> COALESCE(new.M_LOCATOR_ID, '0'))
   OR(COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
   OR(COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0'))))
  THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  END IF;
  IF((TG_OP = 'DELETE' OR TG_OP = 'INSERT') AND v_Processed='Y') THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
  IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') then
    if (select ad_org_id from m_locator where m_locator_id=new.m_locator_id)!='0' then
        if (select ad_org_id from m_locator where m_locator_id=new.m_locator_id)!=(select ad_org_id from m_inout where m_inout_id=new.m_inout_id) then
            RAISE EXCEPTION '%', '@orgOfLocatorDifferentOrgthenTransaction@' ;
        end if;
    end if;
    if new.m_product_id is null then
        RAISE EXCEPTION '%', '@Need2SupplyProductAndQty@' ;
    end if;
  end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; 
$BODY$  LANGUAGE 'plpgsql' VOLATILE  COST 100;




select zsse_DropView ('zssi_onhanqty');
CREATE  VIEW zssi_onhanqty AS 
SELECT a.m_product_id,
       a.m_warehouse_id,
       a.m_locator_id,
       a.m_attributesetinstance_id,
       a.c_uom_id,
       sum(a.qtyonhand) as qtyonhand,
       sum(a.weight) as weight,
       sum(a.qtyreserved) as qtyreserved,
       sum(a.qtyincomming) as qtyincomming,
       sum(a.qtyordered) as qtyordered,
       sum(a.qtyorderedframe) as qtyorderedframe,
       sum(a.qtyinsale) as qtyinsale,
       sum(a.qtyinsaleframe) as qtyinsaleframe,
       sum(a.qtyincomming)+sum(a.qtyordered) as qtyinflow,
       sum(a.qtyreserved)+sum(a.qtyinsale) as qtyoutflow,
       sum(a.stockmin) as stockmin,
       a.m_product_id||coalesce(a.m_attributesetinstance_id,'')||coalesce(a.m_locator_id,'')||coalesce(a.m_warehouse_id,'') as zssi_onhanqty_id,
       a.ad_client_id,
       (select ad_org_id from m_warehouse where m_warehouse_ID=a.m_warehouse_id) as ad_org_id,
       'Y'::text as isactive,
       now() as created,
       now() as updated,
       '0'::text as createdby,
       '0'::text as updatedby,
       a.m_product_id||coalesce(a.m_attributesetinstance_id,'')||coalesce(a.m_warehouse_id,'') AS zssi_onhanqty_overview_id,
       b.m_product_category_id
FROM (     
        -- On Hand QTY's
        SELECT sd.m_product_id,
                ml.m_warehouse_id,
                sd.m_locator_id,
                case when sd.m_attributesetinstance_id = '0' then null else sd.m_attributesetinstance_id end as m_attributesetinstance_id,
                sd.c_uom_id,
                sd.qtyonhand,
                0::numeric AS  qtyreserved,
                0::numeric AS  qtyincomming,
                0::numeric AS qtyordered,
                0::numeric AS qtyorderedframe,
                0::numeric AS qtyinsale,
                0::numeric AS qtyinsaleframe,
                0::numeric AS stockmin,
                coalesce(sd.weight,0) as weight,
                sd.ad_client_id,
                sd.m_storage_detail_id AS zssi_onhanqty_id
        FROM m_storage_detail sd, m_locator ml
        WHERE ml.m_locator_id = sd.m_locator_id and ml.isactive='Y' 
                   and case when coalesce(sd.m_attributesetinstance_id,'0')!='0' then sd.qtyonhand!=0 else 1=1 end
UNION 
        -- Orders,Frame Contracts,Production,Consumption
        SELECT b.m_product_id,
               b.m_warehouse_id,
               b.m_locator_id,
               case when b.m_attributesetinstance_id = '0' then null else b.m_attributesetinstance_id end as m_attributesetinstance_id,
               p.c_uom_id,
               0::numeric AS qtyonhand,
               b.qtyreserved,
               b.qtyincomming,
               b.qtyordered,
               b.qtyorderedframe,
               b.qtyinsale,
               b.qtyinsaleframe,
               0::numeric AS stockmin,
               0::numeric AS weight,
               'C726FEC915A54A0995C568555DA5BB3C' as ad_client_id,
               b.mrp_inoutplanbase_id AS zssi_onhanqty_id
               from mrp_inoutplanbase b, m_product p
               where b.m_product_id=p.m_product_id
UNION   -- Stock Planning
        SELECT pl.m_product_id,
                w.m_warehouse_id,
                pl.m_locator_id,
                pl.m_attributesetinstance_id,
                p.c_uom_id,
                0::numeric AS  qtyonhand,
                0::numeric AS  qtyreserved,
                0::numeric AS  qtyincomming,
                0::numeric AS qtyordered,
                0::numeric AS qtyorderedframe,
                0::numeric AS qtyinsale,
                0::numeric AS qtyinsaleframe,
                coalesce(pl.stockmin,0) as stockmin,
                0::numeric AS weight,
                p.ad_client_id,
                pl.m_product_org_id AS zssi_onhanqty_id
        FROM m_product_org pl, m_product p, m_locator w 
        WHERE p.m_product_id=pl.m_product_id and  w.m_locator_id=pl.m_locator_id and pl.isactive='Y' 
) A,
 m_product b
WHERE  a.m_product_id=b.m_product_id
       and b.isstocked='Y' and b.producttype='I' and b.isactive='Y'
GROUP BY 
       a.m_product_id,
       a.m_warehouse_id,
       a.m_locator_id,
       a.m_attributesetinstance_id,
       a.c_uom_id,
       a.ad_client_id,
       ad_org_id,
       b.m_product_category_id;


select zsse_DropView ('zssi_onhanqty_overview');
CREATE  VIEW zssi_onhanqty_overview AS 
        SELECT oh.m_product_id,
                oh.m_warehouse_id,
                oh.m_attributesetinstance_id,
                oh.c_uom_id,
                oh.m_product_category_id,
                sum(oh.qtyonhand)as qtyonhand,
                sum(oh.weight) as weight,
                sum(oh.qtyreserved) as qtyreserved,
                sum(oh.qtyincomming)as qtyincomming,
                sum(oh.qtyordered) AS qtyordered,
                sum(oh.qtyorderedframe) AS qtyorderedframe,
                sum(oh.qtyinsale) AS qtyinsale,
                 sum(oh.qtyinsaleframe) AS qtyinsaleframe,
                sum(oh.qtyinflow) as qtyinflow,
                sum(oh.qtyoutflow) as qtyoutflow,
                oh.ad_client_id,
                oh.ad_org_id,
                oh.isactive,
                now() as created,
                now() as updated,
                max(oh.createdby) as createdby,
                max(oh.updatedby) as updatedby,
                p.value as pvalue,c.value pcatvalue,
                p.description,p.documentnote,
                p.issold,
                oh.m_product_id||coalesce(oh.m_attributesetinstance_id,'')||oh.m_warehouse_id AS zssi_onhanqty_overview_id
        FROM zssi_onhanqty oh, m_product p, m_product_category c where c.m_product_category_id=p.m_product_category_id and p.m_product_id=oh.m_product_id
group by oh.m_product_id,oh.m_product_category_id,
                oh.m_warehouse_id,
                oh.m_attributesetinstance_id,
                oh.c_uom_id,
                oh.ad_client_id,
                oh.ad_org_id, 
                oh.isactive,p.value,c.value,p.description,p.documentnote,p.issold;

 -- View to show all quantities ordered, but not needed anymore
 -- Movet to here because of cross-script dependencies.
select zsse_DropView ('mrp_deliveries_unneeded');
create view mrp_deliveries_unneeded as
        select mrp_deliveries_unneeded_id,created,createdby,updated,updatedby,isactive,ad_client_id,ad_org_id,
               c_order_id,line,dateordered,datepromised,datedelivered,m_product_id,qtyordered,qtydelivered,
               c_project_id,c_projecttask_id ,a_asset_id,description,salesrep_id,scheddeliverydate,c_bpartner_id,
               qtyonhand, qtyinflow,qtyoutflow,case when coalesce(order_min,0)>0 then floor (unnededqty/order_min)*order_min else unnededqty end as unnededqty,order_min,qtyoptimal,value
        from (
                        select ol.c_orderline_id as mrp_deliveries_unneeded_id,ol.created,ol.createdby,ol.updated,ol.updatedby,ol.isactive,ol.ad_client_id,ol.ad_org_id,o.m_warehouse_id,
                               ol.c_order_id,ol.line,ol.dateordered,ol.scheddeliverydate as datepromised,ol.datedelivered,ol.m_product_id,ol.qtyordered,ol.qtydelivered,
                               ol.c_project_id,ol.c_projecttask_id ,ol.a_asset_id,ol.description,o.salesrep_id,ol.scheddeliverydate,o.c_bpartner_id,
                               coalesce(ov.qtyonhand,0) as qtyonhand, coalesce(ov.qtyinflow,0) as qtyinflow, coalesce(ov.qtyoutflow,0) as qtyoutflow,  p.value,
                               greatest(coalesce(po.order_min,0),coalesce(po.qtystd,0)) as order_min,coalesce(sum(og.qtyoptimal),0)  as qtyoptimal,
                               -- Lager+Zugang
                               (coalesce(ov.qtyinflow,0) 
                               + coalesce(ov.qtyonhand,0)) 
                               - -- Minus Abgang, wenn Abgang innerhalb Beschaffungszeit+Sicherheitsspanne
                                ( coalesce((select sum(movementqty)*-1 from mrp_inoutplan_v vvv where vvv.m_product_id=ol.m_product_id and vvv.m_warehouse_id=o.m_warehouse_id and coalesce(vvv.m_attributesetinstance_id,'')= coalesce(ol.m_attributesetinstance_id,'') and 
                                                   vvv.documenttype in ('PCONS','SOO') and vvv.planneddate <= (ol.scheddeliverydate +
                                                                                                                           (select to_number(VALUE) from AD_PREFERENCE where ATTRIBUTE ='SUPPLYCHAINSECURITYMARGIN'))),0) 
                                + coalesce(sum(og.qtyoptimal),0)  -- Minus opt. Lagerbestand , Minus Mind. Bestellmengen und VE
                                + case when greatest(coalesce(po.order_min,0),coalesce(po.qtystd,0))>0 and ( (coalesce(ov.qtyinflow,0) + coalesce(ov.qtyonhand,0)) - ( coalesce(ov.qtyoutflow,0)  + coalesce(sum(og.qtyoptimal),0)) )    
                                       <  greatest(coalesce(po.order_min,0),coalesce(po.qtystd,0)) then 9999999999   else 0 end ) as unnededqty                     
                        from  c_order o,c_orderline ol left join m_product_po po on po.m_product_id=ol.m_product_id and po.c_bpartner_id=(select c_bpartner_id from c_order where c_order_id=ol.c_order_id) and 
                                                                                                  case when ol.m_product_uom_id is not null then (select c_uom_id from m_product_uom where m_product_uom_id=ol.m_product_uom_id)=po.c_uom_id else po.c_uom_id is null end and
                                                                                                  coalesce(ol.m_product_po_id,po.m_product_po_id)=po.m_product_po_id
                                                                                   left join m_product_org og on og.ad_org_id=ol.ad_org_id and og.m_product_id=ol.m_product_id and og.isactive='Y'
                                                                                                                 and og.m_locator_id in (select m_locator_id from m_locator where m_warehouse_id=(select m_warehouse_id from c_order where c_order_id=ol.c_order_id))
                                                                                   left join zssi_onhanqty_overview ov on  ov.m_warehouse_id=(select m_warehouse_id from c_order where c_order_id=ol.c_order_id) 
                                                                                                                 and ov.m_product_id=ol.m_product_id and coalesce(ov.m_attributesetinstance_id,'')=coalesce(ol.m_attributesetinstance_id,'') ,
                                     m_product p
                        where o.c_order_id=ol.c_order_id and ol.m_product_id=p.m_product_id  and ol.deliverycomplete='N' and ol.qtyordered>ol.qtydelivered AND ad_get_docbasetype(o.c_DocType_ID) ='POO'   and o.docstatus='CO' and
                                     po.m_product_po_id=(select m_product_po_id from m_product_po ppo where ppo.m_product_id=ol.m_product_id and ppo.c_bpartner_id=(select c_bpartner_id from c_order where c_order_id=ol.c_order_id) and 
                                                                                                  case when ol.m_product_uom_id is not null then (select c_uom_id from m_product_uom where m_product_uom_id=ol.m_product_uom_id)=ppo.c_uom_id else ppo.c_uom_id is null end and
                                                                                                  coalesce(ol.m_product_po_id,ppo.m_product_po_id)=ppo.m_product_po_id order by coalesce(ppo.qualityrating,0) desc,ppo.updated desc limit 1)
                        group by
                        ol.c_orderline_id,ol.created,ol.createdby,ol.updated,ol.updatedby,ol.isactive,ol.ad_client_id,ol.ad_org_id,o.m_warehouse_id,
                               ol.c_order_id,ol.line,ol.dateordered,ol.scheddeliverydate,ol.datedelivered,ol.m_product_id,ol.qtyordered,ol.qtydelivered,
                               ol.c_project_id,ol.c_projecttask_id ,ol.a_asset_id,ol.description,o.salesrep_id,ol.scheddeliverydate,o.c_bpartner_id,
                               ov.qtyonhand, ov.qtyinflow,ov.qtyoutflow,ov.qtyincomming , ov.qtyonhand ,  ov.qtyordered,ov.qtyreserved , ov.qtyinsale,
                               po.order_min,po.qtystd,p.value,po.deliverytime_promised
        ) a where unnededqty > 0 and case when coalesce(order_min,0)>0 then unnededqty/order_min>1 else 1=1 end and not exists (select 0 from mrp_inoutplan_v v where v.m_product_id=a.m_product_id and v.estimated_stock_qty<=a.order_min and v.planneddate=a.datepromised and a.m_warehouse_id=v.m_warehouse_id);
               

                
                
CREATE OR REPLACE FUNCTION M_BOM_Qty_Incomming(p_product_id character varying, p_warehouse_id character varying, p_locator_id character varying)
  RETURNS numeric AS
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
    --
    v_ProductQty numeric:=0;
  BEGIN
    IF(p_locator_id IS NULL and p_warehouse_id is not null) THEN
            SELECT SUM(qtyinflow)
                INTO v_ProductQty
                FROM zssi_onhanqty where m_warehouse_id=p_warehouse_id and m_product_id=p_product_id;
            RETURN coalesce(v_ProductQty,0);
    end if;
    -- This may be only Production (has locator)
    if (p_locator_id IS not NULL) then 
            SELECT SUM(qtyinflow)
                INTO v_ProductQty
                FROM zssi_onhanqty where m_locator_id=p_locator_id and m_product_id=p_product_id;
            RETURN coalesce(v_ProductQty,0);
    END IF;
  RETURN 0;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION M_BOM_Qty_Outgoing(p_product_id character varying, p_warehouse_id character varying, p_locator_id character varying)
  RETURNS numeric AS
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
    --
    v_ProductQty numeric:=0;
  BEGIN
    IF(p_locator_id IS NULL and p_warehouse_id is not null) THEN
            SELECT SUM(qtyoutflow)
                INTO v_ProductQty
                FROM zssi_onhanqty where m_warehouse_id=p_warehouse_id and m_product_id=p_product_id;
            RETURN coalesce(v_ProductQty,0);
    end if;
    -- This may be only Production (has locator)
    if (p_locator_id IS not NULL) then 
            SELECT SUM(qtyoutflow)
                INTO v_ProductQty
                FROM zssi_onhanqty where m_locator_id=p_locator_id and m_product_id=p_product_id;
            RETURN coalesce(v_ProductQty,0);
    END IF;
  RETURN 0;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100; 
  
CREATE OR REPLACE FUNCTION M_BOM_Qty_Available(p_product_id character varying, p_warehouse_id character varying, p_locator_id character varying)
  RETURNS numeric AS
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
    --
    v_ProductQty numeric:=0;
  BEGIN
    IF(p_locator_id IS NULL and p_warehouse_id is not null) THEN
            SELECT SUM(qtyonhand)-SUM(qtyoutflow)
                INTO v_ProductQty
                FROM zssi_onhanqty where m_warehouse_id=p_warehouse_id and m_product_id=p_product_id;
            RETURN coalesce(v_ProductQty,0);
    end if;
    -- This may be only Production (has locator)
    if (p_locator_id IS not NULL) then 
            SELECT SUM(qtyonhand)-SUM(qtyoutflow)
                INTO v_ProductQty
                FROM zssi_onhanqty where m_locator_id=p_locator_id and m_product_id=p_product_id;
            RETURN coalesce(v_ProductQty,0);
    END IF;
  RETURN 0;
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100; 

  
CREATE OR REPLACE FUNCTION M_Qty_AvailableInTime(p_product_id character varying, p_warehouse_id character varying, p_date timestamp without time zone)
  RETURNS numeric AS
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
    --
    v_ProductQty numeric:=0;
  BEGIN
  
    select sum(qtyonhand)-sum(a.qtyreserved+a.qtyinsale)+ sum(a.qtyincomming+a.qtyordered) into v_ProductQty from (
        SELECT sd.m_product_id,
                ml.m_warehouse_id,
                to_date('01.01.1900','dd.mm.yyyy') as stockdate,
                sd.m_locator_id,
                case when sd.m_attributesetinstance_id = '0' then null else sd.m_attributesetinstance_id end as m_attributesetinstance_id,
                sd.c_uom_id,
                sd.qtyonhand,
                0::numeric AS  qtyreserved,
                0::numeric AS  qtyincomming,
                0::numeric AS qtyordered,
                0::numeric AS qtyorderedframe,
                0::numeric AS qtyinsale,
                0::numeric AS qtyinsaleframe,
                0::numeric AS stockmin,
                coalesce(sd.weight,0) as weight,
                sd.ad_client_id,
                sd.m_storage_detail_id AS zssi_onhanqty_id
        FROM m_storage_detail sd, m_locator ml
        WHERE ml.m_locator_id = sd.m_locator_id and ml.isactive='Y' 
                   and case when coalesce(sd.m_attributesetinstance_id,'0')!='0' then sd.qtyonhand!=0 else 1=1 end
UNION 
        -- Orders,Frame Contracts,Production,Consumption
        SELECT b.m_product_id,
               b.m_warehouse_id,
               trunc(b.stockdate) as stockdate,
               b.m_locator_id,
               case when b.m_attributesetinstance_id = '0' then null else b.m_attributesetinstance_id end as m_attributesetinstance_id,
               p.c_uom_id,
               0::numeric AS qtyonhand,
               b.qtyreserved,
               b.qtyincomming,
               b.qtyordered,
               b.qtyorderedframe,
               b.qtyinsale,
               b.qtyinsaleframe,
               0::numeric AS stockmin,
               0::numeric AS weight,
               'C726FEC915A54A0995C568555DA5BB3C' as ad_client_id,
               b.mrp_inoutplanbase_id AS zssi_onhanqty_id
               from mrp_inoutplanbase b, m_product p
               where b.m_product_id=p.m_product_id
) a where m_product_id=p_product_id and m_warehouse_id=p_warehouse_id and stockdate<=trunc(p_date);

  RETURN coalesce(v_ProductQty,0);
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;   
  
select zsse_dropview('zssi_qtyoverview');
CREATE OR REPLACE VIEW zssi_qtyoverview AS 
SELECT 
        ol.c_orderline_id AS zssi_qtyoverview_id, 
        ol.ad_client_id, 
        ol.ad_org_id, 
        ol.isactive, 
        ol.created, 
        ol.createdby, 
        ol.updated, 
        ol.updatedby, 
        ol.c_order_id, 
        ol.line, 
        ol.m_product_id, 
        ol.description, 
        ol.c_uom_id, 
        ol.qtyordered AS qtyorderordered, 
        ol.qtydelivered, ol.qtyreserved AS qtytodeliver, 
        ol.qtyinvoiced, 
        m_bom_qty_onhand(ol.M_Product_ID,o.m_warehouse_id, NULL) as qtyonhand, 
        M_BOM_Qty_Available(ol.M_Product_ID,o.m_warehouse_id, NULL) AS qtyavailable, 
        M_BOM_Qty_Incomming(ol.M_Product_ID,o.m_warehouse_id, NULL)  AS qtyorderedvendor
FROM 
        c_order o, 
        c_orderline ol
WHERE 
        ol.c_order_id = o.c_order_id;

  
  
  
CREATE or replace FUNCTION zssi_get_nextdeliverydate(p_productid character varying,p_orgid character varying,p_warehouseid character varying) RETURNS timestamp without time zone
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

*****************************************************/
DECLARE
-- Simple Types
v_return  timestamp without time zone;
BEGIN
  select c_orderline.datepromised into v_return from c_orderline,c_order where c_order.c_order_id=c_orderline.c_order_id and c_order.issotrx='N' and c_order.m_warehouse_ID=p_warehouseid
         and c_order.processed='Y' and c_order.docstatus='CO' and c_order.ad_org_id=p_orgid and c_orderline.m_product_id=p_productid order by c_orderline.datepromised limit 1;
  return v_return;
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;

CREATE or replace FUNCTION zssi_get_nextdeliveryqty(p_productid character varying,p_orgid character varying,p_warehouseid character varying) RETURNS numeric
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

*****************************************************/
DECLARE
-- Simple Types
v_return numeric;
BEGIN
  select c_orderline.qtyordered into v_return from c_orderline,c_order where c_order.c_order_id=c_orderline.c_order_id and c_order.issotrx='N' and c_order.m_warehouse_ID=p_warehouseid
         and c_order.processed='Y' and c_order.docstatus='CO' and c_order.ad_org_id=p_orgid and c_orderline.m_product_id=p_productid order by c_orderline.datepromised limit 1;
  return v_return;
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;


CREATE OR REPLACE FUNCTION m_get_pareto_abc(p_warehouse_id character varying, p_org_id character varying, p_client_id character varying, p_percentageactual numeric)
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
* Contributor(s): Danny A. Heuduk., 02/2012, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
* 
****************************************************************************************************************************************************/

  v_orgList VARCHAR(4000) ; --OBTG:VARCHAR2--
  VARaCUM NUMERIC:=0;
  VARaCUMB NUMERIC:=0;
  v_limitA NUMERIC:=80;
  v_limitB NUMERIC:=15;
  varComprobadoA NUMERIC:=0;
  varComprobadoB NUMERIC:=0;
  --TYPE RECORD IS REFCURSOR;
  Cur_Cursor RECORD;
BEGIN
  varAcum :=0;
  varComprobadoA := 0;
  for Cur_Cursor in (
   SELECT
  100*SUM(msd.qtyonhand*M_GET_PRODUCT_COST(MSD.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),'AV', p_org_id))/ (select SUM(msd1.qtyonhand*M_GET_PRODUCT_COST(MSD1.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),'AV', p_org_id))
                                                       from M_WAREHOUSE MW1
                                                       LEFT JOIN M_LOCATOR ML1 ON ML1.M_WAREHOUSE_ID=MW1.M_WAREHOUSE_ID
                                                       LEFT JOIN M_STORAGE_DETAIL MSD1 ON ML1.M_LOCATOR_ID=MSD1.M_LOCATOR_ID
                                                       WHERE (p_warehouse_ID IS NULL OR MW1.M_WAREHOUSE_ID=p_warehouse_ID)
                                                       AND (p_org_ID IS NULL OR MW1.AD_ORG_ID=p_org_ID)
                                                       AND (p_client_id IS NULL OR MW1.AD_CLIENT_ID=p_client_id) 
                                                       AND MSD1.QTYONHAND>0) as PERCENTAGE
  FROM
   M_WAREHOUSE MW
     LEFT JOIN M_LOCATOR ML ON ML.M_WAREHOUSE_ID=MW.M_WAREHOUSE_ID
     LEFT JOIN M_STORAGE_DETAIL MSD ON ML.M_LOCATOR_ID=MSD.M_LOCATOR_ID
  WHERE (p_warehouse_ID IS NULL OR MW.M_WAREHOUSE_ID=p_warehouse_ID)
     AND (p_org_ID IS NULL OR MW.AD_ORG_ID=p_org_ID)
     AND (p_client_id IS NULL OR MW.AD_CLIENT_ID=p_client_id)
     AND MSD.QTYONHAND>0
     AND M_GET_PRODUCT_COST(MSD.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),null, p_org_id) IS NOT NULL
     AND M_GET_PRODUCT_COST(MSD.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),null, p_org_id) <> 0
  GROUP BY MSD.M_PRODUCT_ID
  ORDER BY PERCENTAGE DESC) loop
  varAcum := varAcum+Cur_Cursor.percentage;
   if(varComprobadoA=0)then
     if (varAcum>=v_limitA) then
       if (p_percentageactual>=Cur_Cursor.percentage) then
	     return 'A';
       else
         varComprobadoA:=-1;
         varAcumB:=-1*Cur_Cursor.percentage;
       end if;
     end if;
   end if;

  if (varComprobadoA=-1 and varComprobadoB=0) then
  varAcumB:=varAcumB+Cur_Cursor.percentage;
   if (varAcumB>=v_limitB) then
     if (p_percentageactual>=Cur_Cursor.percentage) then return 'B';
	 else varComprobadoB:=-1;
     end if;
   end if;
  end if;

 end loop;
 return 'C';
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION m_get_pareto_abc(character varying, character varying, character varying, numeric) OWNER TO tad;




CREATE OR REPLACE FUNCTION m_matchpo_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 





  v_QtyOrdered NUMERIC;
  v_QtyOrderOrdered NUMERIC;
  v_Product_UOM     VARCHAR(32); --OBTG:VARCHAR2--
  v_UOM             VARCHAR(32); --OBTG:VARCHAR2--
  v_Attribute       VARCHAR(32); --OBTG:VARCHAR2--
  v_Warehouse       VARCHAR(32); --OBTG:VARCHAR2--
  V_STOCKED         NUMERIC;
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
****************************************************************************************************************************************************/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF(TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
    IF OLD.M_INOUTLINE_ID IS NOT NULL THEN
      v_QtyOrdered:=old.qty;
      SELECT o.C_UOM_ID,
        o.M_ATTRIBUTESETINSTANCE_ID,
        o.M_PRODUCT_UOM_ID,
        o.M_WAREHOUSE_ID
      INTO v_UOM,
        v_Attribute,
        v_Product_UOM,
        v_Warehouse
      FROM C_ORDERLINE o
      WHERE o.C_ORDERLINE_ID=old.C_ORDERLINE_ID;
      SELECT l.QUANTITYORDER
      INTO v_QtyOrderOrdered
      FROM M_INOUTLINE l
      WHERE l.M_INOUTLINE_ID=old.M_INOUTLINE_ID;
    END IF;
  END IF;
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    IF NEW.M_INOUTLINE_ID IS NOT NULL THEN
      v_QtyOrdered:=-new.qty;
      SELECT o.C_UOM_ID,
        o.M_ATTRIBUTESETINSTANCE_ID,
        o.M_PRODUCT_UOM_ID,
        o.M_WAREHOUSE_ID
      INTO v_UOM,
        v_Attribute,
        v_Product_UOM,
        v_Warehouse
      FROM C_ORDERLINE o
      WHERE o.C_ORDERLINE_ID=new.C_ORDERLINE_ID;
      SELECT -l.QUANTITYORDER
      INTO v_QtyOrderOrdered
      FROM M_INOUTLINE l
      WHERE l.M_INOUTLINE_ID=new.M_INOUTLINE_ID;
    END IF;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


CREATE OR REPLACE FUNCTION m_update_pareto_product(p_pinstance_id character varying, p_warehouse_id character varying, p_org_id character varying, p_client_id character varying) RETURNS void
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
****************************************************************************************************************************************************/

  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:= 1;
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_exist NUMERIC:=0;
  v_M_Product_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_warehouse_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_org_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_client_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_count_update NUMERIC:= 0;
  v_count_insert NUMERIC:= 0;
  --TYPE RECORD IS REFCURSOR;
  Cur_Cursor RECORD;
  Cur_Parameter RECORD;
  v_AD_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
BEGIN

  IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      v_ResultStr:='PInstanceNotFound';
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
      -- Get Parameters
      v_ResultStr:='ReadingParameters';
      FOR Cur_Parameter IN (SELECT i.Record_ID, i.AD_User_ID, p.ParameterName, p.P_String, p.P_Number, p.P_Date, i.UpdatedBy
                            FROM AD_PINSTANCE i LEFT JOIN AD_PINSTANCE_PARA p ON i.AD_PInstance_ID=p.AD_PInstance_ID
                            WHERE i.AD_PInstance_ID=p_PInstance_ID
                            ORDER BY p.SeqNo) LOOP
        IF (Cur_Parameter.ParameterName = 'm_warehouse_id') THEN
          v_warehouse_ID := Cur_Parameter.P_String;
          RAISE NOTICE '%','  m_warehouse_id=' || v_warehouse_ID ;
        ELSIF (Cur_Parameter.ParameterName = 'ad_org_id') THEN
          v_org_ID := Cur_Parameter.P_String;
          RAISE NOTICE '%','  ad_org_id=' || v_org_ID ;
        ELSIF (Cur_Parameter.ParameterName = 'ad_client_id') THEN
          v_client_ID := Cur_Parameter.P_String;
          RAISE NOTICE '%','  ad_client_id=' || v_client_ID ;
        END IF;
      END LOOP; --Get Parameter

    ELSE
      RAISE NOTICE '%','--<<M_UPDATE_PARETO_PRODUCT>>' ;
      v_warehouse_ID:=p_warehouse_ID;
      v_org_ID:=p_org_ID;
      v_client_ID := p_client_id;
    END IF;
    BEGIN --BODY

  for Cur_Cursor in (
     SELECT M_GET_PARETO_ABC(v_warehouse_ID, AD_ORG_ID, v_client_ID, PERCENTAGE) AS ISABC,
     AD_ORG_ID, AD_CLIENT_ID, M_PRODUCT_ID
     FROM
     (
     SELECT
      100*SUM(MSD.QTYONHAND)*(M_GET_PRODUCT_COST(MSD.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),'AV',MW.ad_org_id)/ (SELECT SUM(msd1.qtyonhand*M_GET_PRODUCT_COST(MSD1.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),'AV',MW1.ad_org_id))
                                                           from M_WAREHOUSE MW1
                                                           LEFT JOIN M_LOCATOR ML1 ON ML1.M_WAREHOUSE_ID=MW1.M_WAREHOUSE_ID
                                                           LEFT JOIN M_STORAGE_DETAIL MSD1 ON ML1.M_LOCATOR_ID=MSD1.M_LOCATOR_ID
                                                           WHERE MSD1.QTYONHAND>0
                                                           AND (v_warehouse_ID IS NULL OR MW1.M_WAREHOUSE_ID = v_warehouse_ID)
                                                           AND (v_org_ID IS NULL OR MW1.AD_ORG_ID = v_org_ID)
                                                           AND (v_client_ID IS NULL OR MW1.AD_CLIENT_ID = v_client_ID)
                                                           ) ) as PERCENTAGE,
      MW.AD_ORG_ID,
      MW.AD_CLIENT_ID,
      MSD.M_PRODUCT_ID
     FROM
     M_WAREHOUSE MW
       LEFT JOIN M_LOCATOR ML ON ML.M_WAREHOUSE_ID=MW.M_WAREHOUSE_ID
       LEFT JOIN M_STORAGE_DETAIL MSD ON ML.M_LOCATOR_ID=MSD.M_LOCATOR_ID
     WHERE (v_warehouse_ID IS NULL OR MW.M_WAREHOUSE_ID = v_warehouse_ID)
       AND (v_org_ID IS NULL OR MW.AD_ORG_ID = v_org_ID)
       AND (v_client_ID IS NULL OR MW.AD_CLIENT_ID = v_client_ID)
       AND MSD.QTYONHAND>0
       AND M_GET_PRODUCT_COST(MSD.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),'AV',mw.ad_org_id) IS NOT NULL
       AND M_GET_PRODUCT_COST(MSD.M_PRODUCT_ID,TO_DATE(TO_DATE(NOW())),'AV',mw.ad_org_id) <> 0
     GROUP BY MW.AD_ORG_ID, MW.AD_CLIENT_ID, MSD.M_PRODUCT_ID
     ) BBB
     ORDER BY PERCENTAGE DESC) loop

     SELECT COUNT(*)
     INTO v_exist
     FROM M_PRODUCT_ORG
     WHERE M_PRODUCT_ID = Cur_Cursor.M_PRODUCT_ID
     AND AD_ORG_ID = Cur_Cursor.AD_ORG_ID;

     IF (v_exist > 0) THEN
       UPDATE M_PRODUCT_ORG SET
       ABC = Cur_Cursor.ISABC
       WHERE M_PRODUCT_ID = Cur_Cursor.M_PRODUCT_ID
       AND AD_ORG_ID = Cur_Cursor.AD_ORG_ID;
       v_count_update := v_count_update + 1;
     ELSE
       SELECT * INTO  v_M_Product_Org_ID FROM AD_Sequence_Next('M_Product_Org', Cur_Cursor.AD_CLIENT_ID) ;
       INSERT INTO M_PRODUCT_ORG (M_PRODUCT_ORG_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, M_PRODUCT_ID, ABC) VALUES
       (v_M_Product_Org_ID, Cur_Cursor.AD_CLIENT_ID, Cur_Cursor.AD_ORG_ID, 'Y', TO_DATE(NOW()), '100', TO_DATE(NOW()), '100', Cur_Cursor.M_PRODUCT_ID, Cur_Cursor.ISABC);
       v_count_insert := v_count_insert + 1;
     END IF;

  end loop;
  v_Message:='@Created@=' || v_count_insert || ', @Updated@=' || v_count_update;
---- <<FINISH_PROCESS>>
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
    ELSE
      RAISE NOTICE '%','--<<M_UPDATE_PARETO_PRODUCT finished>>' ;
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
  RETURN;
END ; $_$;


ALTER FUNCTION public.m_update_pareto_product(p_pinstance_id character varying, p_warehouse_id character varying, p_org_id character varying, p_client_id character varying) OWNER TO tad;

--
-- Name: m_update_pareto_product0(character varying); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION m_update_pareto_product0(pinstance_id character varying) RETURNS void
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
****************************************************************************************************************************************************/
BEGIN
  PERFORM M_UPDATE_PARETO_PRODUCT(PInstance_ID, NULL, NULL, NULL);
END ; $_$;


CREATE OR REPLACE FUNCTION m_inout_chk_restrictions_trg() RETURNS trigger
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
****************************************************************************************************************************************************/
  v_DateNull TIMESTAMP := TO_DATE('01-01-1900', 'DD-MM-YYYY');
  v_n NUMERIC;
     
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  -- Check Duplicate Document Numbers
  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
       select count(*) into v_n from m_inout where documentno=new.documentno and c_doctype_id=new.c_doctype_id and m_inout_id!=new.m_inout_id;
       if v_n>0 then
          RAISE EXCEPTION '%', '@DuplicateDocNo@' ;
       end if;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    IF(old.Processed='Y'
    AND ((COALESCE(old.C_BPartner_ID, '0') <> COALESCE(new.C_BPartner_ID, '0'))
    OR(COALESCE(old.DOCUMENTNO, '.') <> COALESCE(new.DOCUMENTNO, '.'))
    OR(COALESCE(old.C_DOCTYPE_ID, '0') <> COALESCE(new.C_DOCTYPE_ID, '0'))
    OR(COALESCE(old.AD_USER_ID, '0') <> COALESCE(new.AD_USER_ID, '0'))
    OR(COALESCE(old.C_ORDER_ID, '0') <> COALESCE(new.C_ORDER_ID, '0'))
    OR(COALESCE(trunc(old.DATEORDERED), v_DateNull) <> COALESCE(trunc(new.DATEORDERED), v_DateNull))
    OR(COALESCE(trunc(old.MOVEMENTDATE), v_DateNull) <> COALESCE(trunc(new.MOVEMENTDATE), v_DateNull))
    OR(COALESCE(OLD.C_BPARTNER_LOCATION_ID, '0') <> COALESCE(NEW.C_BPARTNER_LOCATION_ID, '0'))
    OR(COALESCE(trunc(old.SHIPDATE), v_DateNull) <> COALESCE(trunc(new.SHIPDATE), v_DateNull))
    OR(COALESCE(old.C_CHARGE_ID, '0') <> COALESCE(new.C_CHARGE_ID, '0'))
    OR(COALESCE(old.CHARGEAMT, 0) <> COALESCE(new.CHARGEAMT, 0))
    OR(COALESCE(old.AD_ORGTRX_ID, '0') <> COALESCE(new.AD_ORGTRX_ID, '0'))
    OR(COALESCE(old.USER1_ID, '0') <> COALESCE(new.USER1_ID, '0'))
    OR(COALESCE(old.M_SHIPPER_ID, '0') <> COALESCE(new.M_SHIPPER_ID, '0'))
    OR(COALESCE(old.SALESREP_ID, '0') <> COALESCE(new.SALESREP_ID, '0'))
    OR(COALESCE(old.M_WAREHOUSE_ID, '0') <> COALESCE(new.M_WAREHOUSE_ID, '0'))
    OR(COALESCE(old.USER2_ID, '0') <> COALESCE(new.USER2_ID, '0'))
    OR(COALESCE(old.DELIVERYRULE, '.') <> COALESCE(new.DELIVERYRULE, '.'))
    OR(COALESCE(old.DELIVERYVIARULE, '.') <> COALESCE(new.DELIVERYVIARULE, '.'))
    OR(COALESCE(old.PRIORITYRULE, '.') <> COALESCE(new.PRIORITYRULE, '.'))
    OR(COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
    OR(COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0')))) THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
    IF(old.Posted='Y' AND ((COALESCE(trunc(old.DATEACCT), v_DateNull) <> COALESCE(trunc(new.DATEACCT), v_DateNull)) OR (COALESCE(trunc(old.MOVEMENTDATE), v_DateNull) <> COALESCE(trunc(new.MOVEMENTDATE), v_DateNull)) OR(COALESCE(old.C_CAMPAIGN_ID, '0') <> COALESCE(new.C_CAMPAIGN_ID, '0'))  OR(COALESCE(old.C_ACTIVITY_ID, '0') <> COALESCE(new.C_ACTIVITY_ID, '0')))) THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  END IF;
  IF(TG_OP = 'DELETE') THEN
    IF(old.Processed='Y') THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  END IF;
  IF(TG_OP = 'INSERT') THEN
    IF(NEW.Processed='Y') THEN
      RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
    END IF;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;

select zsse_droptrigger('m_internal_consumptionlinechkrestictions_trg','m_internal_consumptionline');




CREATE OR REPLACE FUNCTION m_internal_consumptionlinechkrestictions_trg()
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
Trigger for Internal-Consumption
Performs Restriction Check
*****************************************************/
v_movementtype character varying;
v_qtyreceived numeric;
v_bomplan numeric;
v_qtyproduced numeric;
v_qtyplan numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
  
  -- Product weight on insert/update 
  IF TG_OP = 'INSERT' then
        if new.weight is null then
            select weight*new.movementqty into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
  end if;
  IF TG_OP = 'UPDATE' then
        if coalesce(new.weight,0)=coalesce(old.weight,0) and (new.m_product_id!=old.m_product_id or new.movementqty!=old.movementqty) then
            select weight*new.movementqty  into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
  end if;
  
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    
    select movementtype into v_movementtype from M_Internal_Consumption where M_Internal_Consumption_id=new.M_Internal_Consumption_ID;
    if (new.c_projecttask_id is not null and v_movementtype='D+') then
       select sum(qtyreceived),sum(quantity) into v_qtyreceived,v_bomplan from zspm_projecttaskbom where c_projecttask_id=new.c_projecttask_id and m_product_id=new.m_product_id;
       if (v_qtyreceived is null) then v_qtyreceived=0; end if;
       select qty,qtyproduced into v_qtyplan,v_qtyproduced from c_projecttask where c_projecttask_id=new.c_projecttask_id;
       if v_qtyproduced>0 and v_qtyplan>0 then
        v_qtyreceived:=round(v_qtyreceived-v_bomplan*(v_qtyproduced/v_qtyplan),3);
       end if;
       if TG_OP = 'UPDATE' and old.zspm_projecttaskbom_id is not null and new.zspm_projecttaskbom_id is null THEN
        raise notice '%','Delete BOM-Pos. in PTask';
       else
        if new.c_projecttask_id is not null and v_qtyreceived<round(new.movementqty,3) and c_getconfigoption('bringbackmorematerialthanreceived',new.ad_org_id)='N' then
            RAISE EXCEPTION '%', '@zsmf_cannotbringbackmorethanreceived@' ||v_qtyreceived||', R: '||new.movementqty||'#'||(select value from m_product where M_Product_ID=new.m_product_id); 
        end if;
       end if;
    end if;
    if new.movementqty<0 then
           RAISE EXCEPTION '%', '@noNegativeQtyInTransaction@'; 
   end if;
   IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') then
    if (select ad_org_id from m_locator where m_locator_id=new.m_locator_id)!='0' then
        if (select ad_org_id from m_locator where m_locator_id=new.m_locator_id)!=(select ad_org_id from m_internal_consumption where m_internal_consumption_id=new.m_internal_consumption_id) then
            RAISE EXCEPTION '%', '@orgOfLocatorDifferentOrgthenTransaction@' ;
        end if;
    end if;
  end if;
    RETURN NEW;
  END IF;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE TRIGGER m_internal_consumptionlinechkrestictions_trg
  BEFORE INSERT OR UPDATE
  ON m_internal_consumptionline
  FOR EACH ROW
  EXECUTE PROCEDURE m_internal_consumptionlinechkrestictions_trg();
 
 

CREATE OR REPLACE FUNCTION m_deleteOldOpenMatrerialMovements (p_pinstance_id  VARCHAR) RETURNS VARCHAR
AS $body$
DECLARE
  Cur_Parameter           RECORD;
  v_message               VARCHAR := '';
  v_Record_ID             VARCHAR;
  v_user_id               VARCHAR;
  v_days                  NUMERIC;
  v_time                  TIMESTAMP;
BEGIN
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'Y', NULL, NULL) ; -- 'Y'=processing
      SELECT pi.Record_ID, pi.ad_User_ID
      INTO v_Record_ID, v_user_id
      FROM ad_pinstance pi WHERE pi.ad_PInstance_ID = p_PInstance_ID;
      IF (v_Record_ID IS NULL) then
         RAISE NOTICE '%','Entry for PInstance not found - Using parameter &1=''' || p_PInstance_ID || ''' instead';
         v_Record_ID := p_PInstance_ID;
         v_user_id     := '0';
         v_days:=0;
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
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('DAYS') ) THEN
            v_days := Cur_Parameter.p_number;
          END IF;
        END LOOP; -- Get Parameter
      END IF;
    END IF;
    if v_days>0 then
        v_time:=now()-v_days;
    else
        v_time:=now();
    end if;
    delete from m_internal_consumptionline l where exists (select 0 from m_internal_consumption c where c.m_internal_consumption_id=l.m_internal_consumption_id and c.processed='N' and c.created < v_time);
    delete from m_internal_consumption c where c.processed='N' and c.created <  v_time;
    delete from m_inoutline l where exists (select 0 from m_inout c where c.m_inout_id=l.m_inout_id and c.docstatus='DR' and c.created < v_time);
    delete from m_inout c where c.docstatus='DR' and c.created <  v_time;
    
    PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'N', 1, v_Message) ; -- NULL=p_ad_user_id, 'N'=isProcessing, 1=success
    RAISE NOTICE '%','Updating PInstance - finished ';
    v_message:='SUCCESS';
    RETURN v_message;

  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_message := '@ERROR=' || SQLERRM;
  RAISE NOTICE '% %', 'SQL-PROC m_deleteOldOpenMatrerialMovements: ', v_message;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

select zsse_droptrigger('m_product_org_trg','m_product_org');

CREATE OR REPLACE FUNCTION m_product_org_trg() RETURNS trigger
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

Gets predefined Textmodules into Shipments

*****************************************************/

    v_count numeric;
    v_orgfrom character varying;
    v_wh varchar;
    v_owh varchar;
    v_cur RECORD; 
BEGIN
    
 
 IF(TG_OP = 'INSERT' or TG_OP = 'UPDATE') then
     select m_warehouse_id into  v_wh from m_locator where m_locator_id=new.m_locator_id;
     for v_cur in (select * from  m_product_org where ad_org_id=new.ad_org_id and m_product_org_id!=new.m_product_org_id
                                                            and m_product_id=new.m_product_id and coalesce(m_attributesetinstance_id,'')=coalesce(new.m_attributesetinstance_id,''))
     LOOP
        select m_warehouse_id into  v_owh from m_locator where m_locator_id=v_cur.m_locator_id;
        if v_owh=v_wh  then
            if new.isvendorreceiptlocator='Y' and v_cur.isvendorreceiptlocator='Y' then
                    raise exception '%', '@onlyonevendorlocator@';
            end if;
            if new.isproduction='Y' and v_cur.isproduction='Y'   then     
                raise exception '%','@onlyonelocatorProd@';
            end if;
        end if;
    END LOOP;
    if new.isproduction='N' and new.isvendorreceiptlocator='N'   then     
                raise exception '%','@onelocatorPorW@';
    end if;
  end if; --Inserting 
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;




CREATE TRIGGER m_product_org_trg
  BEFORE INSERT OR UPDATE
  ON m_product_org
  FOR EACH ROW
  EXECUTE PROCEDURE m_product_org_trg();

CREATE OR REPLACE FUNCTION m_locator_trg() RETURNS trigger
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

Gets predefined Textmodules into Shipments

*****************************************************/

    v_count numeric;
    v_orgfrom character varying;
    v_cur RECORD; 
BEGIN
    
 
  IF( TG_OP = 'UPDATE') then
     if new.isactive!=old.isactive then
        if new.isactive='N' then
            if (select sum(qtyonhand) from  m_storage_detail where m_locator_id=new.m_locator_id)>0 then
                raise exception '%', '@deactivateLocatorOnlyEmpty@';
            end if;
        end if;
     end if;
  end if; --Updating 
  if (select count(*) from m_locator where m_warehouse_id=new.m_warehouse_id and m_locator_id!=new.m_locator_id and value=new.value)>0 then
      raise exception '%', '@duplicatename@';
  end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


select zsse_droptrigger('m_locator_trg','m_locator');

CREATE TRIGGER m_locator_trg
  BEFORE INSERT OR UPDATE
  ON m_locator
  FOR EACH ROW
  EXECUTE PROCEDURE m_locator_trg();

select zsse_DropView ('m_inout_header_v');  
CREATE VIEW m_inout_header_v AS 
 SELECT io.ad_client_id, io.ad_org_id, io.isactive, io.created, io.createdby, io.updated, io.updatedby, to_char('en_US'::text) AS ad_language, io.m_inout_id, io.issotrx, io.documentno, io.docstatus, io.c_doctype_id, io.c_bpartner_id, bp.value AS bpvalue, oi.c_location_id AS org_location_id, oi.taxid, io.m_warehouse_id, wh.c_location_id AS warehouse_location_id, dt.printname AS documenttype, dt.documentnote AS documenttypenote, io.c_order_id, io.movementdate, io.movementtype, bpg.name AS bpgreeting, bp.name, bp.name2, bpcg.name AS bpcontactgreeting, bpc.title, NULLIF(bpc.name::text, bp.name::text) AS contactname, bpl.c_location_id, bp.referenceno, io.description, io.poreference, io.dateordered, io.m_shipper_id, io.deliveryrule, io.deliveryviarule, io.priorityrule
   FROM m_inout io
   JOIN c_doctype dt ON io.c_doctype_id::text = dt.c_doctype_id::text
   JOIN c_bpartner bp ON io.c_bpartner_id::text = bp.c_bpartner_id::text
   LEFT JOIN c_greeting bpg ON bp.c_greeting_id::text = bpg.c_greeting_id::text
   JOIN c_bpartner_location bpl ON io.c_bpartner_location_id::text = bpl.c_bpartner_location_id::text
   LEFT JOIN ad_user bpc ON io.ad_user_id::text = bpc.ad_user_id::text
   LEFT JOIN c_greeting bpcg ON bpc.c_greeting_id::text = bpcg.c_greeting_id::text
   JOIN ad_orginfo oi ON io.ad_org_id::text = oi.ad_org_id::text
   JOIN m_warehouse wh ON io.m_warehouse_id::text = wh.m_warehouse_id::text;

select zsse_DropView ('m_inout_header_vt');  
CREATE VIEW m_inout_header_vt AS 
 SELECT io.ad_client_id, io.ad_org_id, io.isactive, io.created, io.createdby, io.updated, io.updatedby, dt.ad_language, io.m_inout_id, io.issotrx, io.documentno, io.docstatus, io.c_doctype_id, io.c_bpartner_id, bp.value AS bpvalue, oi.c_location_id AS org_location_id, oi.taxid, io.m_warehouse_id, wh.c_location_id AS warehouse_location_id, dt.printname AS documenttype, dt.documentnote AS documenttypenote, io.c_order_id, io.movementdate, io.movementtype, bpg.name AS bpgreeting, bp.name, bp.name2, bpcg.name AS bpcontactgreeting, bpc.title, NULLIF(bpc.name::text, bp.name::text) AS contactname, bpl.c_location_id, bp.referenceno, io.description, io.poreference, io.dateordered, io.m_shipper_id, io.deliveryrule, io.deliveryviarule, io.priorityrule
   FROM m_inout io
   JOIN c_doctype_trl dt ON io.c_doctype_id::text = dt.c_doctype_id::text
   JOIN c_bpartner bp ON io.c_bpartner_id::text = bp.c_bpartner_id::text
   LEFT JOIN c_greeting_trl bpg ON bp.c_greeting_id::text = bpg.c_greeting_id::text AND dt.ad_language::text = bpg.ad_language::text
   JOIN c_bpartner_location bpl ON io.c_bpartner_location_id::text = bpl.c_bpartner_location_id::text
   LEFT JOIN ad_user bpc ON io.ad_user_id::text = bpc.ad_user_id::text
   LEFT JOIN c_greeting_trl bpcg ON bpc.c_greeting_id::text = bpcg.c_greeting_id::text AND dt.ad_language::text = bpcg.ad_language::text
   JOIN ad_orginfo oi ON io.ad_org_id::text = oi.ad_org_id::text
   JOIN m_warehouse wh ON io.m_warehouse_id::text = wh.m_warehouse_id::text;


   
   
   
CREATE OR REPLACE FUNCTION m_transaction_trg() RETURNS trigger
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
* Contributor(s):  Stefan Zimmermannn, OpenZ, 2016.
************************************************************************/
  v_DATEINVENTORY TIMESTAMP;
  v_UOM_ID VARCHAR ; 
  v_attrstocked VARCHAR;
  v_attrmandat VARCHAR;
  v_ATTRIBUTESETINSTANCE_ID VARCHAR;
  v_Name VARCHAR;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    SELECT M_PRODUCT.C_UOM_ID, M_ATTRIBUTESET.isstocktracking, M_ATTRIBUTESET.ismandatory,M_PRODUCT.name
    INTO v_UOM_ID, v_attrstocked,v_attrmandat, v_name
    FROM M_PRODUCT left join M_ATTRIBUTESET on M_ATTRIBUTESET.M_ATTRIBUTESET_ID=M_PRODUCT.M_ATTRIBUTESET_ID
    WHERE M_PRODUCT.M_PRODUCT_ID=NEW.M_PRODUCT_ID;
    IF(COALESCE(v_UOM_ID, '0') <> COALESCE(NEW.C_UOM_ID, '0')) THEN
      RAISE EXCEPTION '%', 'Unit of Measure mismatch (product/transaction)' ; --OBTG:-20111--
    END IF;
    IF(coalesce(v_attrstocked,'N')='Y' and coalesce(v_attrmandat,'N')='Y'  AND COALESCE(NEW.M_ATTRIBUTESETINSTANCE_ID, '0') = '0') THEN
      RAISE EXCEPTION '%', 'There are some products without attribute: ' || v_Name ; --OBTG:-20112--
    END IF;
    SELECT MAX(MOVEMENTDATE)
    INTO v_DATEINVENTORY
    FROM M_INVENTORY I,
      M_INVENTORYLINE IL
    WHERE I.M_INVENTORY_ID=IL.M_INVENTORY_ID
      AND IL.M_INVENTORYLINE_ID=NEW.M_INVENTORYLINE_ID;
  END IF;
  -- Updating inventory
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    PERFORM M_UPDATE_INVENTORY(OLD.weight, OLD.AD_ORG_ID, OLD.UPDATEDBY, OLD.M_PRODUCT_ID, OLD.M_LOCATOR_ID, OLD.M_ATTRIBUTESETINSTANCE_ID, OLD.C_UOM_ID, OLD.M_PRODUCT_UOM_ID, -OLD.MOVEMENTQTY, -OLD.QUANTITYORDER, NULL, OLD.MOVEMENTQTY, OLD.QUANTITYORDER) ;
  END IF;
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    PERFORM M_UPDATE_INVENTORY(NEW.weight, NEW.AD_ORG_ID, NEW.UPDATEDBY, NEW.M_PRODUCT_ID, NEW.M_LOCATOR_ID, NEW.M_ATTRIBUTESETINSTANCE_ID, NEW.C_UOM_ID, NEW.M_PRODUCT_UOM_ID, NEW.MOVEMENTQTY, NEW.QUANTITYORDER, v_DATEINVENTORY, -NEW.MOVEMENTQTY, -NEW.QUANTITYORDER) ;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;


CREATE OR REPLACE FUNCTION m_internal_consumption_cancel(p_internalconsumption_id varchar,p_user varchar) RETURNS void
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): 
***************************************************************************************************************************************************

Creates a Reverse Consumption for Given Consumption

*****************************************************/

    v_uid  varchar;
    v_uid2  varchar;
    v_cur RECORD; 
    v_cur2 RECORD;
      v_header m_internal_consumption%ROWTYPE;
      v_line m_internal_consumptionline%ROWTYPE;
      v_snr snr_internal_consumptionline%ROWTYPE;
BEGIN
     select * into v_header  from   m_internal_consumption where m_internal_consumption_id=p_internalconsumption_id;
     select get_uuid() into v_uid;
     v_header.m_internal_consumption_id:=v_uid;
     v_header.documentno:= v_header.documentno||'(*R*)';
     v_header.processed:='N';    
     v_header.createdby:=p_user;
     v_header.updatedby:=p_user;
     v_header.created:=now();
     v_header.updated:=now();
     if v_header.movementtype='D+' then v_header.movementtype:='D-'; else  v_header.movementtype:='D+'; end if;
     insert into m_internal_consumption select v_header.*;
     for v_cur in (select * from m_internal_consumptionline where m_internal_consumption_id=p_internalconsumption_id)
     LOOP
             select * into v_line  from m_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id;
             select get_uuid() into v_uid2;
             v_line.m_internal_consumptionline_id:= v_uid2;
             v_line.m_internal_consumption_id:= v_uid;
             v_line.createdby:=p_user;
             v_line.updatedby:=p_user;
             v_line.created:=now();
             v_line.updated:=now();
             insert into m_internal_consumptionline select v_line.*;
             for v_cur2 in (select * from snr_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id)
             LOOP
                     select * into v_snr from snr_internal_consumptionline where snr_internal_consumptionline_id=v_cur2.snr_internal_consumptionline_id;
                     v_snr.snr_internal_consumptionline_id:=get_uuid();
                     v_snr.m_internal_consumptionline_id:= v_uid2;
                     v_snr.createdby:=p_user;
                     v_snr.updatedby:=p_user;
                     v_snr.created:=now();
                     v_snr.updated:=now();
                     insert into snr_internal_consumptionline select v_snr.*;
             END LOOP;
     END LOOP;
     PERFORM m_internal_consumption_post(v_uid);
END ; $_$;

CREATE OR REPLACE FUNCTION m_cancelInternal_consumption(p_internalconsumption_id varchar,p_user varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
BEGIN
     if p_internalconsumption_id is null then return 'COMPILE'; end if;
     PERFORM m_internal_consumption_cancel(p_internalconsumption_id,p_user);
     return 'OK';
END ; $_$;

CREATE OR REPLACE FUNCTION m_createReturnFromInternalConsumption(p_internalconsumption_id varchar,p_locato varchar,p_user varchar) RETURNS varchar
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is OpenZ Software GmbH
Copyright (C) 2021 Stefan Zimmermann All Rights Reserved.
Contributor(s): 
***************************************************************************************************************************************************

Creates a Material Return from Given Consumption 
This is Used for relocation of Goods

*****************************************************/

    v_uid  varchar;
    v_uid2  varchar;
    v_cur RECORD; 
    v_cur2 RECORD;
      v_header m_internal_consumption%ROWTYPE;
      v_line m_internal_consumptionline%ROWTYPE;
      v_snr snr_internal_consumptionline%ROWTYPE;
BEGIN
     if p_internalconsumption_id is null then return 'COMPILE'; end if;
     select * into v_header  from   m_internal_consumption where m_internal_consumption_id=p_internalconsumption_id;
     select get_uuid() into v_uid;
     v_header.m_internal_consumption_id:=v_uid;
     v_header.documentno:= v_header.documentno || 'R';
     v_header.processed:='N';    
     v_header.createdby:=p_user;
     v_header.updatedby:=p_user;
     v_header.created:=now();
     v_header.updated:=now();
     if v_header.movementtype!='D-' then 
        return 'ERROR: Relocation only from Consumption possible';
     end if;
     v_header.movementtype:='D+'; 
     insert into m_internal_consumption select v_header.*;
     for v_cur in (select * from m_internal_consumptionline where m_internal_consumption_id=p_internalconsumption_id)
     LOOP
             select * into v_line  from m_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id;
             select get_uuid() into v_uid2;
             v_line.m_internal_consumptionline_id:= v_uid2;
             v_line.m_internal_consumption_id:= v_uid;
             v_line.createdby:=p_user;
             v_line.updatedby:=p_user;
             v_line.created:=now();
             v_line.updated:=now();
             v_line.m_locator_id:=p_locato;
             insert into m_internal_consumptionline select v_line.*;
             for v_cur2 in (select * from snr_internal_consumptionline where m_internal_consumptionline_id=v_cur.m_internal_consumptionline_id)
             LOOP
                     select * into v_snr from snr_internal_consumptionline where snr_internal_consumptionline_id=v_cur2.snr_internal_consumptionline_id;
                     v_snr.snr_internal_consumptionline_id:=get_uuid();
                     v_snr.m_internal_consumptionline_id:= v_uid2;
                     v_snr.createdby:=p_user;
                     v_snr.updatedby:=p_user;
                     v_snr.created:=now();
                     v_snr.updated:=now();
                     insert into snr_internal_consumptionline select v_snr.*;
             END LOOP;
     END LOOP;
     RETURN v_uid;
END ; $_$;

CREATE OR REPLACE FUNCTION m_generateMaintanaceReceipt4Order (p_pinstance_id  VARCHAR) RETURNS VARCHAR
AS $body$
DECLARE
  v_dtype varchar:='2317023F9771481696461C5EAF9A0915'; -- Shipment (Return) 
  v_message               VARCHAR := '';
BEGIN
  BEGIN
    v_message:=m_generateMaintanaceInOutTrxs (p_pinstance_id,v_dtype ,'C+');
    RETURN v_message;
  END; --BODY
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

CREATE OR REPLACE FUNCTION  m_generateMaintanaceDelivery4Order (p_pinstance_id  VARCHAR) RETURNS VARCHAR
AS $body$
DECLARE
  --v_dtype varchar:='F7C859920B904536A9CCF3A84729AA52'; -- Shipment (MM) 
  v_dtype varchar:='C993D1D33D494B44BA8842110876D417'; --  MM Shipment Indirect 
  v_message               VARCHAR := '';
BEGIN
  BEGIN
    v_message:=m_generateMaintanaceInOutTrxs (p_pinstance_id,v_dtype ,'C-');
    RETURN v_message;
  END; --BODY
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

CREATE OR REPLACE FUNCTION m_generateMaintanaceInOutTrxs (p_pinstance_id  VARCHAR,p_doctype varchar,p_movtype varchar) RETURNS VARCHAR
AS $body$
DECLARE
  Cur_Parameter           RECORD;
  v_message               VARCHAR := '';
  v_Record_ID             VARCHAR;
  v_user               VARCHAR;
  v_cur record;
  v_mioid varchar:=get_uuid();
  v_miolid varchar:=get_uuid();
  v_snr varchar;
  v_descr varchar;
  v_text1 varchar;
  v_text2 varchar;
  v_text3 varchar;
  v_text4 varchar;
  v_text5 varchar;
  v_text6 varchar;
  v_text7 varchar;
  v_text8 varchar;
  v_text9 varchar;
  v_text10 varchar;
  v_num1 numeric;
  v_num2 numeric;
  v_num3 numeric;
  v_num4 numeric;
  v_num5 numeric;
  v_date1 timestamp;
  v_date2 timestamp;
  v_date3 timestamp;
  v_date4 timestamp;
  v_DocumentNo varchar;
  v_isserial varchar;
  v_locator varchar;
  v_uom varchar;
  v_mgtxt varchar;
BEGIN
  BEGIN
    PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'Y', NULL, NULL) ; -- 'Y'=processing
    SELECT pi.Record_ID, pi.ad_User_ID
    INTO v_Record_ID, v_user
    FROM ad_pinstance pi WHERE pi.ad_PInstance_ID = p_PInstance_ID;
    IF (v_Record_ID IS NULL) then
        RAISE NOTICE '%','Entry for PInstance not found - Using parameter &1=''' || p_PInstance_ID || ''' instead';
        v_Record_ID := p_PInstance_ID;
        v_user     := '0';
    ELSE
        -- Get Parameters
        v_message := 'ReadingParameters';
        FOR Cur_Parameter IN
            (SELECT para.parametername, para.p_string, para.p_number, para.p_date
            FROM AD_PInstance pi, AD_PInstance_Para para
            WHERE pi.AD_PInstance_ID = para.AD_PInstance_ID  AND pi.AD_PInstance_ID = p_PInstance_ID  ORDER BY para.SeqNo
            )
        LOOP
            IF  UPPER(Cur_Parameter.parametername) = UPPER('serialnumber')  THEN v_snr := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('Description')  THEN v_descr := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text1')  THEN v_text1 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text2')  THEN v_text2 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text3')  THEN v_text3 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text4')  THEN v_text4 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text5')  THEN v_text5 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text6')  THEN v_text6 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text7')  THEN v_text7 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text8')  THEN v_text8 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text9')  THEN v_text9 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('text10')  THEN v_text10 := Cur_Parameter.p_string; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('num1')  THEN v_num1 := Cur_Parameter.p_number; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('num2')  THEN v_num2 := Cur_Parameter.p_number; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('num3')  THEN v_num3 := Cur_Parameter.p_number; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('num4')  THEN v_num4 := Cur_Parameter.p_number; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('num5')  THEN v_num5 := Cur_Parameter.p_number; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('date1')  THEN v_date1 := Cur_Parameter.p_date; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('date2')  THEN v_date2 := Cur_Parameter.p_date; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('date3')  THEN v_date3 := Cur_Parameter.p_date; END IF;
            IF  UPPER(Cur_Parameter.parametername) = UPPER('date4')  THEN v_date4 := Cur_Parameter.p_date; END IF;
        END LOOP; -- Get Parameter
    END IF;
    select * into v_cur from c_order where c_order_id=v_Record_ID;
    SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(p_doctype, v_cur.ad_org_ID, 'Y') ; -- Get DocumentNo
    select isserialtracking,c_uom_id, m_gettransactionlocator(v_cur.maintanace_product,v_cur.M_Warehouse_ID,case when p_movtype='C+' then 'N' else 'Y' end,1) into v_isserial,v_uom ,v_locator
           from m_product where m_product_id=v_cur.maintanace_product;
    insert INTO M_INOUT
    (
        M_InOut_ID, C_Order_ID, IsSOTrx, AD_Client_ID,AD_Org_ID, IsActive, Description,
        DocumentNo, C_DocType_ID, MovementType, MovementDate, DateAcct, Created, CreatedBy,  Updated, UpdatedBy,
        C_BPartner_ID, C_BPartner_Location_ID, AD_User_ID, M_Warehouse_ID, POReference, DateOrdered, DeliveryRule,
        FreightCostRule, FreightAmt, C_Project_ID, C_projecttask_ID, C_Campaign_ID, qty,
        DeliveryViaRule, M_Shipper_ID,  PriorityRule, salesrep_id,c_incoterms_id, deliverylocationtext,weight,m_product_id,
        DocStatus, DocAction, Processing, Processed,delivery_location_id,weight_uom
    )
    VALUES
    (
        v_mioid,v_cur.C_Order_ID, 'Y', v_cur.AD_Client_ID,v_cur.AD_Org_ID, v_cur.IsActive, v_cur.Description,
        v_DocumentNo, p_doctype, p_movtype, trunc(now()), trunc(now()), now(), v_user,  now(), v_user,
        v_cur.C_BPartner_ID, v_cur.C_BPartner_Location_ID, v_cur.AD_User_ID, v_cur.M_Warehouse_ID, v_cur.POReference, v_cur.DateOrdered, v_cur.DeliveryRule,
        v_cur.FreightCostRule, v_cur.FreightAmt, v_cur.C_Project_ID, v_cur.C_projecttask_ID, v_cur.C_Campaign_ID, v_cur.qty,
        v_cur.DeliveryViaRule, v_cur.M_Shipper_ID,  v_cur.PriorityRule, v_cur.salesrep_id,v_cur.c_incoterms_id, v_cur.deliverylocationtext,v_cur.weight,v_cur.m_product_id,
        'DR','CO','N','N',v_cur.delivery_location_id,v_cur.weight_uom
    );
    insert INTO M_INOUTLINE
    (
        M_InOutLine_ID, Line, M_InOut_ID, 
        AD_Client_ID, AD_Org_ID, IsActive, Created,
        CreatedBy, Updated, UpdatedBy, M_Product_ID,
        M_Locator_ID, MovementQty,
        Description,c_uom_id
    )
    VALUES
    (
       v_miolid,10, v_mioid,v_cur.AD_Client_ID,v_cur.AD_Org_ID, v_cur.IsActive,  now(), v_user,  now(),v_user,
       v_cur.maintanace_product,v_locator,1,v_cur.Description,v_uom
    );
    --raise notice '%',v_isserial||'#'||v_cur.maintanace_product||'#'||v_miolid;
    if v_isserial='Y' then
        if (select count(*) from snr_minoutline where M_InOutLine_ID=v_miolid)=1 -- Liefervorschlag wegen System-Option
        then 
            update snr_minoutline set serialnumber=v_snr,description=v_descr,text1=v_text1,text2=v_text2,text3=v_text3,text4=v_text4,text5=v_text5,num1=v_num1,num2=v_num2,num3=v_num3,
                   num4=v_num4,num5=v_num5,date1=v_date1,date2=v_date2,date3=v_date3,date4=v_date4 where M_InOutLine_ID=v_miolid;
        else
            insert into snr_minoutline (snr_minoutline_id,M_InOutLine_ID,Created, CreatedBy,  Updated, UpdatedBy,AD_Client_ID,AD_Org_ID,
                quantity,serialnumber,description,text1,text2,text3,text4,text5,text6,text7,text8,text9,text10,num1,num2,num3,num4,num5,date1,date2,date3,date4)
            values (get_uuid(),v_miolid,now(), v_user,  now(),v_user,v_cur.AD_Client_ID,v_cur.AD_Org_ID,1,
                    v_snr,v_descr,v_text1,v_text2,v_text3,v_text4,v_text5,v_text6,v_text7,v_text8,v_text9,v_text10,v_num1,v_num2,v_num3,v_num4,v_num5,v_date1,v_date2,v_date3,v_date4);
        end if;
    end if;
    PERFORM M_INOUT_POST(NULL, v_mioid) ;
    if (select result from ad_pinstance where ad_pinstance_id=v_mioid)!=1 then
        raise exception '%', (select errormsg from ad_pinstance where ad_pinstance_id=v_mioid);
    end if;
    if p_movtype='C+' then
        v_mgtxt:='@ReceiptCreated@: ' ;
    else
        v_mgtxt:='@ShipmentCreated@: ';
    end if;
    v_message:=v_mgtxt|| zsse_htmlLinkDirectKey('../GoodsMovementcustomer/GoodsMovementcustomer_Relation.html',v_mioid,v_DocumentNo)||'<br />';
    PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'N', 1, v_message) ; -- NULL=p_ad_user_id, 'N'=isProcessing, 1=success
    RAISE NOTICE '%','Updating PInstance - finished ';
    RETURN v_message;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_message := '@ERROR=' || SQLERRM;
  RAISE NOTICE '% %', 'SQL-PROC m_generateMaintanaceDelivery4Order: ', v_message;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_message);
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;


CREATE OR REPLACE FUNCTION m_movementline_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 

  v_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_RO      NUMERIC;
  V_STOCKED NUMERIC;
  /******************************************************************************
  * The contents of this file are subject to the   Compiere License  Version 1.1
  * ("License"); You may not use this file except in compliance with the License
  * You may obtain a copy of the License at http://www.compiere.org/license.html
  * Software distributed under the License is distributed on an  "AS IS"  basis,
  * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
  * the specific language governing rights and limitations under the License.
  * The Original Code is                  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke  and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke, parts
  * created by ComPiere are Copyright (C) ComPiere, Inc.;   All Rights Reserved.
  * Contributor(s): Openbravo SL
  * Contributions are Copyright (C) 2001-2006 Openbravo S.L.
  ******************************************************************************/
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Get ID
  IF(TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    v_ID:=new.M_Movement_ID;
  ELSE
    v_ID:=old.M_Movement_ID;
  END IF;
  -- ReadOnly Check
  SELECT COUNT(*)
  INTO v_RO
  FROM M_Movement
  WHERE M_Movement_ID=v_ID
    AND(Processed='Y'
    OR Posted='Y') ;
  IF(v_RO > 0) THEN
    RAISE EXCEPTION '%', 'Document processed/posted' ; --OBTG:-20501--
  END IF;
  -- Updating inventory
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    SELECT COUNT(*)
    INTO V_STOCKED
    FROM M_PRODUCT
    WHERE M_Product_ID=OLD.M_PRODUCT_ID
      AND IsStocked='Y'
      AND ProductType='I';
    IF V_STOCKED > 0 THEN
      PERFORM M_UPDATE_INVENTORY(OLD.weight, OLD.AD_ORG_ID, OLD.UPDATEDBY, OLD.M_PRODUCT_ID, OLD.M_LOCATOR_ID, OLD.M_ATTRIBUTESETINSTANCE_ID, OLD.C_UOM_ID, OLD.M_PRODUCT_UOM_ID, NULL, NULL, NULL, OLD.MOVEMENTQTY, OLD.QUANTITYORDER) ;
      PERFORM M_UPDATE_INVENTORY(OLD.weight, OLD.AD_ORG_ID, OLD.UPDATEDBY, OLD.M_PRODUCT_ID, OLD.M_LOCATORTO_ID, OLD.M_ATTRIBUTESETINSTANCE_ID, OLD.C_UOM_ID, OLD.M_PRODUCT_UOM_ID, NULL, NULL, NULL, -OLD.MOVEMENTQTY, -OLD.QUANTITYORDER) ;
    END IF;
  END IF;
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    SELECT COUNT(*)
    INTO V_STOCKED
    FROM M_PRODUCT
    WHERE M_Product_ID=NEW.M_PRODUCT_ID
      AND IsStocked='Y'
      AND ProductType='I';
    IF V_STOCKED > 0 THEN
      PERFORM M_UPDATE_INVENTORY(NEW.weight, NEW.AD_ORG_ID, NEW.UPDATEDBY, NEW.M_PRODUCT_ID, NEW.M_LOCATOR_ID, NEW.M_ATTRIBUTESETINSTANCE_ID, NEW.C_UOM_ID, NEW.M_PRODUCT_UOM_ID, NULL, NULL, NULL, -NEW.MOVEMENTQTY, -NEW.QUANTITYORDER) ;
      PERFORM M_UPDATE_INVENTORY(NEW.weight, NEW.AD_ORG_ID, NEW.UPDATEDBY, NEW.M_PRODUCT_ID, NEW.M_LOCATORTO_ID, NEW.M_ATTRIBUTESETINSTANCE_ID, NEW.C_UOM_ID, NEW.M_PRODUCT_UOM_ID, NULL, NULL, NULL, NEW.MOVEMENTQTY, NEW.QUANTITYORDER) ;
    END IF;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;

CREATE OR REPLACE FUNCTION m_movementline_trg2() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2019 OpenZ Software GmbH  All Rights Reserved.
*****************************************************************************************************************************************/

    v_count numeric;
    v_orgfrom character varying;
    v_cur RECORD; 
    v_batch varchar;
BEGIN
 IF (select processed from m_movement where m_movement_id=new.m_movement_id)='N' then
     if (select  isserialtracking from m_product where m_product_id = new.m_product_id)='Y' and
        (select qtyonhand from m_storage_detail  where m_product_id = new.m_product_id and m_locator_id=new.m_locator_id limit 1)=new.movementqty
     then
        delete from snr_movementline where m_movementline_id=new.m_movementline_id;
        for v_cur in (select * from snr_masterdata where m_product_id = new.m_product_id and  m_locator_id=new.m_locator_id)
        LOOP
            select batchnumber into v_batch from snr_batchmasterdata where snr_batchmasterdata_id=v_cur.snr_batchmasterdata_id ;
            insert into snr_movementline(snr_movementline_id,ad_client_id,ad_org_id,createdby,updatedby,m_movementline_id,quantity,serialnumber,lotnumber)
                        values(get_uuid(),new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,new.m_movementline_id,1,v_cur.serialnumber,v_batch);
        END LOOP;
     end if;
     if (select count(*) from m_product where m_product_id = new.m_product_id and  isbatchtracking='Y' and isserialtracking='N')=1 and
        (select qtyonhand from m_storage_detail  where m_product_id = new.m_product_id and m_locator_id=new.m_locator_id limit 1)=new.movementqty
     then
        delete from snr_movementline where m_movementline_id=new.m_movementline_id;
        for v_cur in (select b.batchnumber,l.qtyonhand from snr_batchmasterdata b,snr_batchlocator l where b.snr_batchmasterdata_id=l.snr_batchmasterdata_id and
                             b.m_product_id = new.m_product_id and  l.m_locator_id=new.m_locator_id and l.qtyonhand>0)
        LOOP
            insert into snr_movementline(snr_movementline_id,ad_client_id,ad_org_id,createdby,updatedby,m_movementline_id,quantity,lotnumber)
                        values(get_uuid(),new.ad_client_id,new.ad_org_id,new.createdby,new.updatedby,new.m_movementline_id,v_cur.qtyonhand,v_cur.batchnumber);
        END LOOP;
     end if;
  end if; --Inserting 
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


select zsse_droptrigger('m_movementline_trg2','m_movementline');

CREATE TRIGGER m_movementline_trg2
  AFTER INSERT OR UPDATE
  ON m_movementline
  FOR EACH ROW
  EXECUTE PROCEDURE m_movementline_trg2();
  

CREATE OR REPLACE FUNCTION m_movementline_trg3() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2020 OpenZ Software GmbH  All Rights Reserved.
*****************************************************************************************************************************************/
BEGIN
  new.c_uom_id := (select c_uom_id from m_product where m_product_id=new.m_product_id);
  
  -- Product weight on insert/update 
  IF TG_OP = 'INSERT' then
        if new.weight is null then
            select weight*new.movementqty into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
  end if;
  IF TG_OP = 'UPDATE' then
        if coalesce(new.weight,0)=coalesce(old.weight,0) and (new.m_product_id!=old.m_product_id or new.movementqty!=old.movementqty) then
            select weight*new.movementqty  into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
  end if;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;


select zsse_droptrigger('m_movementline_trg3','m_movementline');

CREATE TRIGGER m_movementline_trg3
  BEFORE INSERT OR UPDATE
  ON m_movementline
  FOR EACH ROW
  EXECUTE PROCEDURE m_movementline_trg3();
    
--
-- Name: m_movement_post(character varying); Type: FUNCTION; Schema: public; Owner: tad
--

CREATE OR REPLACE FUNCTION m_movement_post(pinstance_id character varying) RETURNS void
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
  * Contributor(s): OpenZ Software GmbH
  * Contributions are Copyright (C) 2020 
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: M_Movement_Post.sql,v 1.3 2003/09/05 04:58:06 jjanke Exp $
  ***
  * Title: Post Movements
  * Description:
  ************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Result NUMERIC:=1;
  --Added by PSarobe 13062007
  v_line NUMERIC;
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    -- Parameter Variables
    v_IsProcessing CHAR(1) ;
    v_IsProcessed VARCHAR(60) ; --OBTG:VARCHAR2--
    v_NoProcessed NUMERIC:=0;
    v_MoveDate TIMESTAMP;
    v_Client_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_p_User VARCHAR(32); --OBTG:VARCHAR2--
    v_Count NUMERIC:=0;
    v_is_included NUMERIC:=0;
    v_available_period NUMERIC:=0;
    v_is_ready AD_Org.IsReady%TYPE;
    v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
    v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
    v_org_bule_id AD_Org.AD_Org_ID%TYPE;
    END_PROCESS BOOLEAN:=false;
    Cur_MoveLine RECORD;
    NextNo VARCHAR(32); --OBTG:varchar2--
BEGIN
    --  Update AD_PInstance
    RAISE notice '%','Updating PInstance - Processing ' || PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'Y', NULL, NULL) ;
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID,
        i.AD_User_ID,
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
      v_Record_ID:=Cur_Parameter.Record_ID;
      v_p_User:=Cur_Parameter.AD_User_ID;
    END LOOP; -- Get Parameter
    if v_Record_ID is null then
        select ad_user_id,record_id into v_p_User,v_Record_ID from ad_pinstance where ad_pinstance_id= PInstance_ID;
    end if;
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    -- Reading Movement
    SELECT MovementDate,
      Processing,
      Processed,
      AD_Client_ID,
      AD_Org_ID
    INTO v_MoveDate,
      v_IsProcessing,
      v_IsProcessed,
      v_Client_ID,
      v_Org_ID
    FROM M_Movement
    WHERE M_Movement_ID=v_Record_ID  FOR UPDATE;
    IF(v_IsProcessing='Y') THEN
      RAISE EXCEPTION '%', '@OtherProcessActive@' ; --OBTG:-20000--
    END IF;
    IF(NOT END_PROCESS) THEN
      IF(v_IsProcessed='Y') THEN
        RAISE EXCEPTION '%', '@AlreadyPosted@' ; --OBTG:-20000--
      END IF;
    END IF;--END_PROCESS
    IF(NOT END_PROCESS) THEN
      v_ResultStr:='CheckingRestrictions';
      SELECT COUNT(*), MAX(M.line)
      INTO v_Count, v_line
      FROM M_MovementLine M,
        M_Product P
      WHERE M.M_PRODUCT_ID=P.M_PRODUCT_ID
        AND P.M_ATTRIBUTESET_ID IS NOT NULL
        AND P.M_ATTRIBUTESETINSTANCE_ID IS NULL
        AND COALESCE(M.M_ATTRIBUTESETINSTANCE_ID, '0') = '0'
        AND M.M_Movement_ID=v_Record_ID;
      IF v_Count<>0 THEN
       RAISE EXCEPTION '%', '@Inline@ '||v_line||' '||'@productWithoutAttributeSet@' ; --OBTG:-20000--
      END IF;
    END IF;--END_PROCESS
    IF(NOT END_PROCESS) THEN
      -- Start Processing ------------------------------------------------------
      -- Check the header belongs to a organization where transactions are posible and ready to use
      SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
      INTO v_is_ready, v_is_tr_allow
      FROM M_MOVEMENT, AD_Org, AD_OrgType
      WHERE AD_Org.AD_Org_ID=M_MOVEMENT.AD_Org_ID
      AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
      AND M_MOVEMENT.M_MOVEMENT_ID=v_Record_ID;
      IF (v_is_ready='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
      END IF;
      IF (v_is_tr_allow='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
      END IF;
      
      SELECT AD_ORG_CHK_DOCUMENTS('M_MOVEMENT', 'M_MOVEMENTLINE', v_Record_ID, 'M_MOVEMENT_ID', 'M_MOVEMENT_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;
      
      -- Check the period control is opened (only if it is legal entity with accounting)
      -- Gets the BU or LE of the document
      SELECT AD_GET_DOC_LE_BU('M_MOVEMENT', v_Record_ID, 'M_MOVEMENT_ID', 'LE')
      INTO v_org_bule_id
      FROM DUAL;
      
      SELECT AD_OrgType.IsAcctLegalEntity
      INTO v_isacctle
      FROM AD_OrgType, AD_Org
      WHERE AD_Org.AD_OrgType_ID = AD_OrgType.AD_OrgType_ID
      AND AD_Org.AD_Org_ID=v_org_bule_id;
      
      IF (v_isacctle='Y') THEN
        SELECT C_CHK_OPEN_PERIOD(v_Org_ID, v_MoveDate, 'MMM', NULL) 
        INTO v_available_period
        FROM DUAL;
        
        IF (v_available_period<>1) THEN
          RAISE EXCEPTION '%', '@PeriodNotAvailable@'; --OBTG:-20000--
        END IF;
      END IF;
          
      
      v_ResultStr:='LockingMovement';
      UPDATE M_Movement  SET Processing='Y'  WHERE M_Movement_ID=v_Record_ID;
      -- Commented by cromero 19102006 -- COMMIT;
      /**
      * Accounting first step
      */

        FOR Cur_MoveLine IN
          (SELECT *  FROM M_MovementLine  WHERE M_Movement_ID=v_Record_ID  ORDER BY Line)
        LOOP
          v_ResultStr:='Transaction for line' || Cur_MoveLine.Line;
          -- FROM
          SELECT * INTO  NextNo FROM AD_Sequence_Next('M_Transaction', v_Client_ID) ;
          INSERT
          INTO M_Transaction
            (
              M_Transaction_ID, AD_Client_ID, AD_Org_ID, IsActive,
              Created, CreatedBy, Updated, UpdatedBy,
              MovementType, M_Locator_ID, M_Product_ID, M_AttributeSetInstance_ID,
              MovementDate, MovementQty, M_MovementLine_ID, M_Product_UOM_ID,
              QuantityOrder, C_UOM_ID,weight
            )
            VALUES
            (
              NextNo, Cur_MoveLine.AD_Client_ID, Cur_MoveLine.AD_Org_ID, 'Y',
              TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
              'M-', Cur_MoveLine.M_Locator_ID, Cur_MoveLine.M_Product_ID, COALESCE(Cur_MoveLine.M_AttributeSetInstance_ID, '0'),
              v_MoveDate, (Cur_MoveLine.MovementQty * -1), Cur_MoveLine.M_MovementLine_ID, Cur_MoveLine.M_Product_UOM_ID,
              (Cur_MoveLine.QuantityOrder * -1), Cur_MoveLine.C_UOM_ID,Cur_MoveLine.weight
            )
            ;
          -- TO
          SELECT * INTO  NextNo FROM AD_Sequence_Next('M_Transaction', v_Client_ID) ;
          INSERT
          INTO M_Transaction
            (
              M_Transaction_ID, AD_Client_ID, AD_Org_ID, IsActive,
              Created, CreatedBy, Updated, UpdatedBy,
              MovementType, M_Locator_ID, M_Product_ID, M_AttributeSetInstance_ID,
              MovementDate, MovementQty, M_MovementLine_ID, M_Product_UOM_ID,
              QuantityOrder, C_UOM_ID,weight
            )
            VALUES
            (
              NextNo, Cur_MoveLine.AD_Client_ID, Cur_MoveLine.AD_Org_ID, 'Y',
              TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
              'M+', Cur_MoveLine.M_LocatorTo_ID, Cur_MoveLine.M_Product_ID, COALESCE(Cur_MoveLine.M_AttributeSetInstance_ID, '0'),
              v_MoveDate, Cur_MoveLine.MovementQty, Cur_MoveLine.M_MovementLine_ID, Cur_MoveLine.M_Product_UOM_ID,
              Cur_MoveLine.QuantityOrder, Cur_MoveLine.C_UOM_ID,Cur_MoveLine.weight
            )
            ;
          SELECT * INTO  v_Result, v_Message FROM M_Check_Stock(Cur_MoveLine.M_Product_ID, v_Client_ID, v_Org_ID) ;
          IF v_Result=0 THEN
			RAISE EXCEPTION '%', v_Message||' '||'@line@'||' '||Cur_MoveLine.line ; --OBTG:-20000--
          END IF;
        END LOOP;
    END IF;--END_PROCESS
    IF(NOT END_PROCESS) THEN
      -- End Processing --------------------------------------------------------
      ---- <<END_PROCESSING>>
      v_ResultStr:='UnLockingMovement';
      UPDATE M_Movement  SET Processed='Y'  WHERE M_Movement_ID=v_Record_ID;
      -- Commented by cromero 19102006 -- COMMIT;
    END IF;--END_PROCESS
    ---- <<END_PROCESS>>
    v_ResultStr:='UnLockingMovement';
    UPDATE M_Movement  SET Processing='N'  WHERE M_Movement_ID=v_Record_ID;
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, v_p_User, 'N', v_Result, v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  -- ROLLBACK;
  UPDATE M_Movement  SET Processing='N'  WHERE M_Movement_ID=v_Record_ID;
  -- Commented by cromero 19102006 -- COMMIT;
  PERFORM AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END ; $_$;

