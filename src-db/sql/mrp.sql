

select zsse_dropfunction('mrp_check_planningmethod');

CREATE OR REPLACE FUNCTION mrp_check_planningmethod (
  p_planningmethod_id VARCHAR,
  p_type VARCHAR
)
RETURNS NUMERIC AS
/*
  SELECT Mrp_Check_Planningmethod(
    '6192C3D3F32B457DB600EF61BD47E6A3', -- 'PO' --  COALESCE(po.MRP_PlanningMethod_ID, p.MRP_PlanningMethod_ID),
    'SO', TO_NUMBER(COALESCE(null, to_timestamp('2012-06-02', 'yyyy-mm-dd')) - to_timestamp('2012-05-30', 'yyyy-mm-dd')), 2)
    */
$body$
 DECLARE
  v_Days_Aux NUMERIC:= 0;
  v_Return NUMERIC:= -1;
BEGIN
    SELECT pml.weighting
    INTO v_Return
    FROM mrp_planningmethodline pml
    WHERE pml.mrp_planningmethod_id = p_PlanningMethod_ID
    AND pml.inouttrxtype = p_Type;
 -- duration due to calendar-days, non-working-days not considered
 --  raise notice 'mrp_check_planningmethod: id=%, type=%, days=%, timehorizon=%, v_result=% Info:% verbl:%', p_planningmethod_id, p_type, p_Days,
 --                p_timehorizon, COALESCE(v_Return, -1),
 --                CASE COALESCE(v_Return, -1) WHEN 1 THEN 'sofort bestellen' ELSE 'später bestellen' END AS info, v_Days_Aux - p_TimeHorizon AS verbl;
    RETURN COALESCE(v_Return, -1); --  -1=not within p_TimeHorizon
EXCEPTION
  WHEN OTHERS THEN
    RETURN -1;
END ;
$body$
LANGUAGE 'plpgsql'
COST 100;



CREATE OR REPLACE FUNCTION mrp_purchase_run(p_pinstance_id character varying) RETURNS void
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
* Contributor(s):  ______________________________________.
************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR:=''; --OBTG:VARCHAR2--
  v_Message VARCHAR:=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_User_ID VARCHAR(32):='0'; --OBTG:VARCHAR2--
  v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Planner_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Product_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Product_Category_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_BPartner_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_BP_Group_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Vendor_ID   VARCHAR(32); --OBTG:varchar2--
  v_TimeHorizon NUMERIC;
  v_PlanningDate TIMESTAMP;
  v_SecurityMargin NUMERIC;
  v_warehouse varchar;
  v_cur record;
  FINISH_PROCESS BOOLEAN DEFAULT FALSE;
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
  BEGIN
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    if (select count(*) from  AD_Process_Run r ,ad_process_request rq WHERE r.ad_process_request_id=rq.ad_process_request_id 
               and rq.AD_Process_ID ='800164' and r.Status='PRC')>1 then
        RAISE EXCEPTION '%' ,'@ProcessExecutes@';
    end if;
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
      v_User_ID:=Cur_Parameter.AD_User_ID;
    END LOOP; -- Get Parameter

    SELECT AD_Client_ID, AD_Org_ID, MRP_Planner_ID, M_Product_ID, M_Product_Category_ID, C_BPartner_ID,
         C_BP_Group_ID, TimeHorizon, SecurityMargin, datedoc, Vendor_ID,m_warehouse_id
    INTO v_Client_ID, v_Org_ID, v_Planner_ID, v_Product_ID, v_Product_Category_ID, v_BPartner_ID,
         v_BP_Group_ID, v_TimeHorizon, v_SecurityMargin, v_PlanningDate, v_Vendor_ID,v_warehouse
    FROM MRP_RUN_PURCHASE
    WHERE MRP_RUN_PURCHASE_ID=V_Record_ID;

    PERFORM MRP_RUN_INITIALIZE(v_User_ID, v_Org_ID, v_Client_ID, v_Record_ID, v_Planner_ID, v_Product_ID,
                       v_Product_Category_ID, v_BPartner_ID, v_BP_Group_ID, v_Vendor_ID, v_TimeHorizon,
                       v_PlanningDate,v_warehouse);
    --RAISE NOTICE '%','MRP_PURCHASE_INIT done.: ';
    PERFORM MRP_PURCHASEPLAN(v_User_ID, v_Org_ID, v_Client_ID, v_Record_ID, v_Planner_ID, v_Vendor_ID, v_TimeHorizon,
                    v_PlanningDate, v_SecurityMargin,v_warehouse);
    for v_cur in (select distinct m_product_id from MRP_RUN_PURCHASELINE where inouttrxtype='PP' and c_bpartner_id is null and MRP_RUN_PURCHASE_id=v_Record_ID)
    LOOP
        if v_message!='' then v_Message:=v_Message||','; end if;
        v_Message:=v_Message||(select value from m_product where m_product_id=v_cur.m_product_id);        
    END LOOP;
    if v_message!='' then
        v_message:='@productwithoutpurchase@'||': '||v_Message;
    else 
        v_Message:='@purchaselistcreated@';
    end if;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  RAISE WARNING '%','MRP_PURCHASE_RUN exception: ' || v_ResultStr ;
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE WARNING '%',v_ResultStr ;
  -- ROLLBACK;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
--  RETURN;
END ; $_$;



select zsse_dropfunction('mrp_run_initialize');

CREATE OR REPLACE FUNCTION mrp_run_initialize(p_user_id character varying, p_org_id character varying, p_client_id character varying, p_run character varying, p_planner_id character varying, p_product_id character varying, p_product_category_id character varying, p_bpartner_id character varying, p_bp_group_id character varying, p_vendor_id character varying, pp_timehorizon numeric, p_planningdate timestamp without time zone,p_Warehouse_ID varchar) RETURNS void
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
* Contributions: Do not collect data From m_product. We use m_product_org
*                Take Datepo, if Datepromised is empty
*                Truncate Dates, hours don't make sense in planning (Prevents planning with Dates in the same day)
*                Added MULTIORG
@TODO : Truncate Date in PR, Forcasts etc. , too
****************************************************************************************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(4000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(4000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure

  v_Count NUMERIC;
  v_Aux_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_ParentLine VARCHAR(32); --OBTG:VARCHAR2--

  FINISH_PROCESS BOOLEAN DEFAULT FALSE;
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
  Cur_Product RECORD;
  Cur_OrderLine RECORD;
  Cur_Stock RECORD;
  Cur_SalesForeCast RECORD;
  Cur_RequisitionLine RECORD;
  p_timehorizon numeric;
  v_scheddeliverydate DATE;
  v_refdate DATE;
  v_daysbetweenplandateandnow numeric;
  v_cur record;
  v_correction numeric;
BEGIN
  BEGIN --BODY
    -- Get Parameters
    if (select count(*) from mrp_run_purchaseline where mrp_run_purchase_id=p_run and  isapproved='Y')>0 then
            RAISE EXCEPTION '%' ,'@ApprpovedLinesFound@';
    end if;
    delete from mrp_run_purchaseline where mrp_run_purchase_id=p_run;
    FOR Cur_Product IN (SELECT p.M_Product_ID,
                        COALESCE(po.MRP_PlanningMethod_ID, 
                                 (select MRP_PlanningMethod_ID from MRP_PlanningMethod where isstandard='Y' and isactive='Y' limit 1)) AS MRP_PlanningMethod_ID
                        FROM M_PRODUCT p LEFT JOIN ( select m_product_id,MRP_PLANNER_ID,MRP_PlanningMethod_ID from M_PRODUCT_ORG  where
                                                                       AD_ORG_ID = p_Org_ID
                                                                       AND isvendorreceiptlocator = 'Y' and isactive='Y'
                                                                       AND case when p_Warehouse_ID IS NULL then 1=1 else 
                                                                       m_locator_id in (select m_locator_id from m_locator where m_warehouse_id=p_Warehouse_ID) end
                                                                       LIMIT 1) po ON p.M_PRODUCT_ID = po.M_PRODUCT_ID
                        WHERE (p_product_ID IS NULL OR p.M_PRODUCT_ID = p_Product_ID)
                          AND p.isactive = 'Y'
                          AND (p_Product_Category_ID IS NULL OR p.M_PRODUCT_CATEGORY_ID = p_Product_Category_ID)
                          AND (p_Planner_ID IS NULL OR COALESCE(po.MRP_PLANNER_ID, p.MRP_Planner_ID) = p_Planner_ID)
                          AND p.AD_ORG_ID in ('0',p_org_id)
                          AND p.AD_Client_ID = p_Client_ID
                          AND (p.production='N' or (
                               p.production='Y' and not exists (select 0 from m_product_org ogg where ogg.AD_ORG_ID = p_Org_ID and ogg.m_product_id=p.m_product_id and ogg.isactive='Y' and ogg.isproduction='Y')
                               and  exists (select 0 from m_product_org ogg where ogg.AD_ORG_ID = p_Org_ID and ogg.m_product_id=p.m_product_id and ogg.isactive='Y' and ogg.isproduction='N')))
                          and p.ISPURCHASED = 'Y' and p.isstocked='Y'
                          AND (p_Vendor_ID IS NULL
                               OR EXISTS (SELECT 1
                                          FROM M_PRODUCT_PO
                                          WHERE M_PRODUCT_PO.M_PRODUCT_ID = p.M_PRODUCT_ID
                                            AND M_PRODUCT_PO.C_BPARTNER_ID = p_Vendor_ID
                                            AND M_PRODUCT_PO.ISCURRENTVENDOR = 'Y'
                                            AND M_PRODUCT_PO.ISACTIVE = 'Y'
                                            AND M_PRODUCT_PO.AD_ORG_ID in ('0',p_org_id)
                                          ))
                          AND (p_Warehouse_ID IS NULL
                               OR EXISTS (SELECT 1
                                          FROM M_PRODUCT_ORG org
                                          WHERE org.M_PRODUCT_ID = p.M_PRODUCT_ID
                                            AND org.m_locator_id in (select m_locator_id from m_locator where m_warehouse_id=p_Warehouse_ID)
                                            AND org.isvendorreceiptlocator = 'Y'
                                            AND org.ISACTIVE = 'Y'
                                          ))
                          AND (p_BPartner_ID IS NULL
                               OR EXISTS (SELECT 1
                                          FROM C_ORDER o, C_ORDERLINE ol
                                          WHERE o.C_ORDER_ID = ol.C_ORDER_ID
                                            AND o.C_BPARTNER_ID = p_BPartner_ID
                                            AND o.IsSOTrx = 'Y'
                                            AND o.docstatus='CO'
                                            AND ol.deliverycomplete='N'
                                            AND Mrp_Check_Planningmethod(COALESCE(po.MRP_PlanningMethod_ID, p.MRP_PlanningMethod_ID),'SO') <> -1
                                            AND o.AD_ORG_ID in ('0',p_org_id)
                               )
                               OR EXISTS (SELECT 1
                                          FROM MRP_SALESFORECAST sf, MRP_SALESFORECASTLINE sfl
                                          WHERE sf.MRP_SALESFORECAST_ID = sfl.MRP_SALESFORECAST_ID
                                            AND sf.IsActive = 'Y'
                                            AND sf.C_BPARTNER_ID = p_BPartner_ID
                                            AND Mrp_Check_Planningmethod(COALESCE(po.MRP_PlanningMethod_ID, p.MRP_PlanningMethod_ID),'SF') <> -1
                                            AND sf.AD_ORG_ID in ('0',p_org_id)
                              ))
                          AND (p_BP_Group_ID IS NULL
                               OR EXISTS(SELECT 1
                                         FROM C_ORDER o, C_ORDERLINE ol, C_BPARTNER bp
                                         WHERE o.C_ORDER_ID = ol.C_ORDER_ID
                                           AND o.C_BPartner_ID = bp.C_BPartner_ID
                                           AND o.IsSOTrx = 'Y'
                                           AND bp.C_BP_Group_ID = p_BP_Group_ID
                                           AND o.docstatus='CO'
                                           AND ol.deliverycomplete='N'
                                           AND Mrp_Check_Planningmethod(COALESCE(po.MRP_PlanningMethod_ID, p.MRP_PlanningMethod_ID),'SO') <> -1
                                           AND o.AD_ORG_ID in ('0',p_org_id)
                                )
                                OR EXISTS (SELECT 1
                                           FROM MRP_SALESFORECAST sf, MRP_SALESFORECASTLINE sfl, C_BPARTNER bp
                                           WHERE sf.MRP_SALESFORECAST_ID = sfl.MRP_SALESFORECAST_ID
                                             AND sf.IsActive = 'Y'
                                             AND sf.C_BPartner_ID = bp.C_BPartner_ID
                                             AND bp.C_BP_Group_ID = p_BP_Group_ID
                                             AND Mrp_Check_Planningmethod(COALESCE(po.MRP_PlanningMethod_ID, p.MRP_PlanningMethod_ID),'SF') <> -1
                                             AND sf.AD_ORG_ID in ('0',p_org_id)
                              ))
      ) LOOP

        --raise notice '%','LOOPING'||Cur_Product.STOCKMIN||'ÜÜÜÜÜ'||Cur_Product.QtyOnHand||'######'||zssi_getproductname(Cur_Product.M_Product_ID,'de_DE');
        SELECT COUNT(*) INTO v_Count FROM MRP_RUN_PURCHASELINE  WHERE M_PRODUCT_ID = Cur_Product.M_Product_ID   AND MRP_RUN_PURCHASE_ID = p_Run   AND inouttrxtype = 'MS';
        IF (v_Count = 0) THEN -- First time on this product
          v_ResultStr := 'Inserting stock lines product: ' || Cur_Product.M_Product_ID;
          --raise notice '%','huhuhu'||Cur_Product.QtyOnHand||p_PlanningDate||p_org_id;
          for cur_Stock in (select sum(COALESCE(pog.STOCKMIN, 0)) as STOCKMIN,sum(COALESCE(pog.qtyoptimal, 0)) as qtyoptimal, pog.m_attributesetinstance_id 
                                  from M_PRODUCT_ORG pog where Cur_Product.M_PRODUCT_ID = pog.M_PRODUCT_ID and pog.AD_ORG_ID = p_Org_ID and pog.isactive='Y' and
                                  case when p_Warehouse_ID IS NULL then 1=1 else pog.m_locator_id in (select m_locator_id from m_locator where m_warehouse_id= p_Warehouse_ID) end
                                  group by pog.m_attributesetinstance_id)
          LOOP
            SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(cur_Stock.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run, Cur_Product.M_Product_ID, (-1 * cur_Stock.STOCKMIN),  'MS',  NULL, NULL, NULL, NULL,p_PlanningDate,  NULL,p_Warehouse_ID);
            if cur_Stock.qtyoptimal>0 then
                SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(cur_Stock.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run, Cur_Product.M_Product_ID, (-1 * (cur_Stock.qtyoptimal-cur_Stock.STOCKMIN)),  'OS',  NULL, NULL, NULL, NULL,p_PlanningDate,  NULL,p_Warehouse_ID);
            end if;
          END LOOP;
          for cur_Stock in (select SUM(d.qtyonhand) as qtyonhand,case when m_attributesetinstance_id='0' then null else m_attributesetinstance_id end as m_attributesetinstance_id
                                                    FROM M_STORAGE_DETAIL d,m_locator l,m_warehouse w
                                                    WHERE d.m_locator_id=l.m_locator_id and l.m_warehouse_id=w.m_warehouse_id and w.isblocked='N' and l.AD_ORG_ID in (p_org_id,'0') and
                                                          case when p_Warehouse_ID IS NULL then 1=1 else l.m_warehouse_id=p_Warehouse_ID end
                                                          and d.m_product_id=Cur_Product.M_PRODUCT_ID
                                                    GROUP BY M_Product_ID,m_attributesetinstance_id)
          LOOP
            SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(cur_Stock.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run, Cur_Product.M_Product_ID, cur_Stock.QtyOnHand,  'ST',  NULL, NULL, NULL, NULL,p_PlanningDate,   NULL,p_Warehouse_ID);
          END LOOP;
        v_ResultStr := 'Inserting Order lines product: ' || Cur_Product.M_Product_ID;

        FOR Cur_OrderLine IN (SELECT * from mrp_inoutplan_v 
                                   where documenttype in ('SOO','POO')
                                   AND M_Product_ID = Cur_Product.M_Product_ID
                                   AND Mrp_Check_Planningmethod(Cur_Product.MRP_PlanningMethod_ID,(CASE documenttype WHEN 'SOO' THEN 'SO' ELSE 'PO' END))<>-1
                                   AND AD_ORG_ID=p_org_id
                                   AND case when p_Warehouse_ID IS NULL then 1=1 else m_warehouse_id= p_Warehouse_ID end
          ) LOOP
               SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(Cur_OrderLine.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run, Cur_Product.M_Product_ID, Cur_OrderLine.movementqty, (CASE Cur_OrderLine.documenttype WHEN 'SOO' THEN 'SO' ELSE 'PO' END), Cur_OrderLine.C_OrderLine_ID, NULL, NULL, NULL,  Cur_OrderLine.planneddate, NULL,p_Warehouse_ID);
         END LOOP;
         -- Inserting Production Requirements
          FOR Cur_OrderLine IN (SELECT * from mrp_inoutplan_v 
                                       where  documenttype = 'PCONS'
                                       AND M_Product_ID = Cur_Product.M_Product_ID
                                       AND Mrp_Check_Planningmethod(Cur_Product.MRP_PlanningMethod_ID,'WR')<>-1
                                       AND AD_ORG_ID=p_org_id
                                       AND case when p_Warehouse_ID IS NULL then 1=1 else m_warehouse_id= p_Warehouse_ID end
          ) LOOP
               SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(Cur_OrderLine.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run, Cur_Product.M_Product_ID, Cur_OrderLine.movementqty,'WR', NULL,Cur_OrderLine.c_projecttask_id, NULL, NULL,  Cur_OrderLine.planneddate, NULL,p_Warehouse_ID);
         END LOOP; 

          v_ResultStr := 'Inserting Sales forecast for product: ' || Cur_Product.M_Product_ID;
          FOR Cur_SalesForeCast IN (SELECT sfl.MRP_SALESFORECASTLINE_ID, GREATEST(sfl.DatePlanned, p_Planningdate) AS DatePlanned,
                                          -1*sfl.qty AS qty
                                     FROM MRP_SALESFORECAST sf, MRP_SALESFORECASTLINE sfl
                                     WHERE sf.MRP_SALESFORECAST_ID = sfl.MRP_SALESFORECAST_ID
                                       AND (sf.IsActive = 'Y' AND sfl.Isactive = 'Y')
                                       AND sfl.M_Product_ID = Cur_Product.M_Product_ID
                                       AND Mrp_Check_Planningmethod(Cur_Product.MRP_PlanningMethod_ID,'SF') <> -1
                                       AND sf.AD_ORG_ID in ('0',p_org_id)
          ) LOOP
            SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(null, p_Org_ID, p_User_ID, p_Run, Cur_Product.M_Product_ID, Cur_SalesForeCast.Qty,  'SF', NULL, NULL, Cur_SalesForeCast.MRP_SALESFORECASTLINE_ID, NULL, Cur_SalesForeCast.DatePlanned,  NULL,p_Warehouse_ID);
          END LOOP;

            v_ResultStr := 'Inserting Requisition lines for product: ' || Cur_Product.M_Product_ID;
            FOR Cur_RequisitionLine IN (SELECT r.M_RequisitionLine_ID, (-1)*(r.qty-r.orderedqty) AS qty,r.NeedByDate AS DATEPLANNED,r.m_attributesetinstance_id
                                          FROM M_REQUISITIONLINE r, M_REQUISITION rr
                                         WHERE r.isActive = 'Y'
                                           AND r.M_REQUISITION_ID = rr.M_REQUISITION_ID
                                           AND rr.DOCSTATUS = 'CO'
                                           AND r.REQSTATUS = 'O'
                                           AND r.LOCKEDBY is null
                                           AND Mrp_Check_Planningmethod(Cur_Product.MRP_PlanningMethod_ID,'MF') <> -1
                                           AND r.M_Product_ID = Cur_Product.M_Product_ID
                                           AND rr.AD_ORG_ID in ('0',p_org_id)
            ) LOOP
              SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(Cur_OrderLine.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run, Cur_Product.M_Product_ID, Cur_RequisitionLine.qty, 'MF', NULL, NULL, NULL, Cur_RequisitionLine.M_RequisitionLine_ID,  Cur_RequisitionLine.DatePlanned,  NULL,p_Warehouse_ID);
              UPDATE M_REQUISITIONLINE
              SET LOCKEDBY = p_User_ID,
                  LOCKDATE = TO_DATE(NOW()),
                  LOCKQTY = Cur_RequisitionLine.qty,
                  LOCKCAUSE = 'P'
              WHERE M_REQUISITIONLINE_ID = Cur_RequisitionLine.M_RequisitionLine_ID;
            END LOOP;
        END IF; -- v_Count = 0
    END LOOP;
    if (pp_timehorizon>0) then
     for v_cur in (select distinct m_product_id,m_attributesetinstance_id from  MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_id=p_Run)
     LOOP
        --raise notice '%','Planning TIME HORIZON'||zssi_getproductname(v_cur.M_Product_ID,'de_DE');
        v_daysbetweenplandateandnow:=trunc(p_planningdate)-trunc(now());
        v_refdate:= to_date(mrp_getsheddeliverydate4vendorProduct(null,v_cur.M_Product_ID,p_org_id,null,null),'dd.mm.yyyy');
        p_timehorizon:=zssi_NumofWorkdays2CaleandarDaysFromGivenDate(pp_timehorizon,p_org_id,v_refdate) ;
        select v_refdate + p_timehorizon + v_daysbetweenplandateandnow into v_scheddeliverydate;
        select sum(qty) into v_correction from MRP_RUN_PURCHASELINE where mrp_run_purchase_id=p_run and m_product_id=v_cur.M_Product_ID 
                        and coalesce(m_attributesetinstance_id,'')=coalesce(v_cur.m_attributesetinstance_id,'') and planneddate>v_scheddeliverydate and planneddate>p_planningdate;
        delete from MRP_RUN_PURCHASELINE where mrp_run_purchase_id=p_run and m_product_id=v_cur.M_Product_ID 
                        and coalesce(m_attributesetinstance_id,'')=coalesce(v_cur.m_attributesetinstance_id,'') and planneddate>v_scheddeliverydate and planneddate>p_planningdate;
        if coalesce(v_correction,0) > 0 then -- Positiv -> Zugang in der Zukunft. Dieser Zugang führt zu Bestand.
                        SELECT * INTO  v_Aux_ID FROM Mrp_Run_Insertlines(v_cur.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run, v_cur.M_Product_ID, v_correction, 'TA', NULL, NULL, NULL,NULL,  to_date('01.01.9999','dd.mm.yyyy'),  NULL,p_Warehouse_ID);
        end if;
     END LOOP;
    end if;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  RAISE WARNING '%','MRP_RUN_INITIALIZE exception: ' || v_ResultStr;
  RAISE EXCEPTION '%', SQLERRM;
--  RETURN;
END ; $_$;


CREATE OR REPLACE FUNCTION mrp_run_purchaseline_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'DELETE' THEN 
      UPDATE M_REQUISITIONLINE
              SET LOCKEDBY =null, LOCKDATE = null, LOCKQTY = null, LOCKCAUSE = null
              WHERE M_REQUISITIONLINE_ID = old.M_REQUISITIONLINE_ID and (select r.docstatus from m_requisition r,m_requisitionline l
                                                                             where r.m_requisition_id=l.m_requisition_id and l.M_REQUISITIONLINE_ID = old.M_REQUISITIONLINE_ID)='CO';
   END IF;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_droptrigger('mrp_run_purchaseline_trg','mrp_run_purchaseline');

CREATE TRIGGER mrp_run_purchaseline_trg
  AFTER DELETE
  ON mrp_run_purchaseline
  FOR EACH ROW
  EXECUTE PROCEDURE mrp_run_purchaseline_trg();

select zsse_dropfunction('mrp_purchaseplan');
CREATE OR REPLACE FUNCTION mrp_purchaseplan (
  p_user_id varchar,
  p_org_id varchar,
  p_client_id varchar,
  p_run_id varchar,
  p_planner_id varchar,         -- nicht verwendet
  p_vendor_id varchar,          -- nicht verwendet
  p_timehorizon numeric,        -- nicht verwendet
  p_planningdate timestamp,     -- nicht verwendet
  p_securitymargin numeric,
  p_warehouse varchar
)
RETURNS void AS
$body$
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
* Contributions: 0-Values are not there: Use coalesce, if no line
                 RULEZ: Only from m_product_org:
                        Capacity
                        qtymin: only a Multiplicator, if ismultipleofminimumqty = 'Y'
                        qtystd: Normal qty to order

                 Muliti-ORG: Each Organization may Purchase at different Partners
                 Qualityrating is being evaluated now.
@TODO:  Be aware of second UOM! - so things in m_product_org are evaluated on Purchasing"!
****************************************************************************************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR:=''; --OBTG:VARCHAR2--
  v_Message VARCHAR:=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure

  v_Aux_New VARCHAR(32); --OBTG:VARCHAR2--

  v_scheddeliverydate DATE;
  v_neededQty_New NUMERIC;
  v_Qty_New NUMERIC;
  v_Qty_Old NUMERIC;
  v_plannedorderdate_new TIMESTAMP;
  v_planneddate_new TIMESTAMP;
  v_planneddate_old TIMESTAMP;
  v_vendor character varying;
  v_uom character varying;
  v_manufacturer character varying;
  v_productPoId varchar;

  FINISH_PROCESS BOOLEAN DEFAULT FALSE;
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
  Cur_PlanProduct RECORD;
  Cur_Lines RECORD;
  v_ismultipleofminimumqty CHAR;
  v_qtymin  NUMERIC;
  v_qtystd  NUMERIC;
  v_DELAYMIN NUMERIC;
  v_price numeric;
  v_pricelistID varchar;
  v_daysbetweenplandateandnow numeric;
  v_auxQty numeric;
  v_NeededQtyInTimeNOStock numeric;
  v_NeededQtyInTimeWITHStock numeric;
  v_QtyStockMin numeric;
  v_NeededQtyInFuture numeric;
  v_framecontract varchar;
  v_prodUOM varchar;
  v_2nduom varchar;
  v_2ndqty numeric;
  v_alldemand numeric;
  v_thisdemand numeric;
  v_correction numeric;
  v_correction2 numeric;
  v_manuno varchar;
  v_frameqty numeric;
  v_frameqtyleft numeric;
  v_frameqty2buy numeric;
  v_isfirstneed varchar;
  v_cur record;
BEGIN
  BEGIN --BODY
    v_ResultStr := 'Purchase mrp'; 
    select isfirstneed into v_isfirstneed from mrp_run_purchase where mrp_run_purchase_id=p_Run_ID;
    FOR Cur_PlanProduct IN (
        SELECT MRP_RUN_PURCHASELINE.M_PRODUCT_ID,MRP_RUN_PURCHASELINE.AD_ORG_ID,MRP_RUN_PURCHASE.m_warehouse_id,MRP_RUN_PURCHASELINE.m_attributesetinstance_id
        FROM MRP_RUN_PURCHASELINE,
             M_PRODUCT ,MRP_RUN_PURCHASE
        WHERE  MRP_RUN_PURCHASE.MRP_RUN_PURCHASE_ID = p_Run_ID
          AND M_PRODUCT.M_PRODUCT_ID = MRP_RUN_PURCHASELINE.M_PRODUCT_ID
          AND M_PRODUCT.ISPURCHASED = 'Y'
          AND MRP_RUN_PURCHASE.MRP_RUN_PURCHASE_ID=MRP_RUN_PURCHASELINE.MRP_RUN_PURCHASE_ID
      GROUP BY MRP_RUN_PURCHASELINE.AD_ORG_ID,MRP_RUN_PURCHASE.m_warehouse_id,MRP_RUN_PURCHASELINE.M_PRODUCT_ID,mrp_run_purchaseline.m_attributesetinstance_id
    ) LOOP
    -- Gruppenwechsel Produkt/Artikel verarbeiten,
        -- Mit möglichem Lieferdatum und nachfolgenden, bestehenen EK-Aufträgen abgleichen 
        -- Select Vendor with best rating.
        SELECT PO.C_BPARTNER_ID,   coalesce(qtystd,0),   ismultipleofminimumqty, coalesce(order_min,0), coalesce(deliverytime_promised,1) as deliverytime_promised,pricepo,c_uom_id,m_manufacturer_id,manufacturernumber,m_product_po_id -- qtytype
        INTO           v_vendor, v_qtystd, v_ismultipleofminimumqty,  v_qtymin, v_DELAYMIN, v_price  ,v_uom,v_manufacturer , v_manuno,  v_productPoId        -- v_qtytype
        FROM M_PRODUCT_PO po
        WHERE po.m_product_id=Cur_PlanProduct.M_Product_ID and PO.isactive='Y'  and po.iscurrentvendor='Y' and PO.AD_ORG_ID in ('0',p_org_id)
        ORDER BY COALESCE(po.qualityrating,0) DESC, updated DESC LIMIT 1;
        -- Bei Auslaufartikeln wird der Lieferant nicht gezogen.
        if (select count(*) from m_product_po where m_product_po_id=v_productPoId and coalesce(discontinued,'N')='Y' and coalesce(discontinuedby,trunc(now()))<=trunc(now()))>0 then
            v_productPoId :=null;
            v_vendor :=null;
            v_qtystd :=null;
            v_ismultipleofminimumqty :=null;
            v_qtymin :=null;
            v_DELAYMIN :=null;
            v_price :=null;
            v_uom :=null;
            v_manufacturer :=null;
            v_manuno :=null;
        end if;
        -- Calculate with po_id only when menufacturer is set
        if v_manufacturer is null and v_manuno is null then
                v_productPoId :=null;
        end if;
        select po_pricelist_id into v_pricelistID from c_bpartner where c_bpartner_id=v_vendor;
        -- alle bisherigen (außer opt. Lagerbestand!!) Datensaetze (mrp_run_purchaseline) zu einem Produkt/Artikel verarbeiten:
        select sum(qty) into  v_neededQty_New from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID and inouttrxtype!='OS' 
                        and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'');
        -- Select next possible Delivery Date for Product
        v_daysbetweenplandateandnow:=trunc(p_planningdate)-trunc(now());
        -- Das Datum für die Kalkulation der Lieferungen ist das größere von mögl. nächsten Lieferdatum und kleinstes Datum mit Untermenge.
        select to_date(mrp_getsheddeliverydate4vendorProduct(v_vendor,Cur_PlanProduct.M_PRODUCT_ID,p_org_id,v_uom,v_productPoId ),'dd.mm.yyyy')  + v_daysbetweenplandateandnow 
               into v_scheddeliverydate;
        select greatest(min(trunc(planneddate)) , v_scheddeliverydate) into v_scheddeliverydate from mrp_inoutplan_v where m_product_id=Cur_PlanProduct.M_PRODUCT_ID and ad_org_id=Cur_PlanProduct.ad_org_id 
                   and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'') and
                   case when Cur_PlanProduct.m_warehouse_id is not null then m_warehouse_id=Cur_PlanProduct.m_warehouse_id else 1=1 end and estimated_stock_qty<0;
        -- Spätere Lieferungen decken den aktuellen Bedarf ggf. nicht..
        select sum(qty) into    v_NeededQtyInTimeNOStock from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID
                                             and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                                             and planneddate<=v_scheddeliverydate and inouttrxtype not in ('IQ','OS','MS','SF','ST');
                                           -- and planneddate<=v_scheddeliverydate and inouttrxtype not in ('IQ','OS','MS','SF');
        -- The System should Plan the greatest of all data or demand till next possible delivery
        v_correction:=0;
        if   v_NeededQtyInTimeNOStock< v_neededQty_New then
            -- Hier folgen Lieferungen noch am oder nach dem jetzt zu beliefernden Datum.
            -- Wir schauen, ob der Gesamtbedarf oder der im Zeitpunkt liegende Bedarf kleiner ist. Der kleinere wäre ggf. zu beschaffen.
            -- Eventuell müssen wir zu diesem Zeitpunkt wir auch an den Lagerbedarf denken und diesen auch beschaffen. So gleicht man auch z.B. spontane Lagerentnahmen aus.
            -- Wir schauen, ob der Gesamtbedarf in der Zukunft bestehende Lagermengen konsumiert oder schon den Lager-Bedarf auffüllt. Wenn Lagerbedarfe schon gedeckt sind, beschaffen wir nur den tatsächlichen Bedarf.             
            select sum(qty) into  v_NeededQtyInFuture from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID
                                             and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                                             and (inouttrxtype  in ('IQ','MS','SF','ST') or planneddate>v_scheddeliverydate);
             select sum(qty) into  v_QtyStockMin from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID
                                        and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                                        and inouttrxtype ='MS';
            if v_NeededQtyInFuture>=v_QtyStockMin then -- Lager kann konsumiert werden, keine Beschaffung von Lagerbedarfen notwendig
                    select sum(qty) into    v_NeededQtyInTimeWITHStock from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID
                                             and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                                             and planneddate<=v_scheddeliverydate and inouttrxtype not in ('IQ','OS','MS','SF');
                                            -- raise exception '%',v_NeededQtyInTimeWITHStock||'#'||v_neededQty_New||'#'|| v_NeededQtyInFuture;
                    select least(sum(qty),  v_NeededQtyInTimeWITHStock) into  v_neededQty_New from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID
                                            and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'');
            end if;        
        else 
             -- Nur wenn keine Folgenden Lieferungen sind, Optimalen Lagerbestand auffüllen
              select sum(qty) into  v_correction from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID 
                                                        and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                                                        and inouttrxtype='OS'; 
        end if;
        --raise notice '%','RUUUUUUUN'||v_neededQty_New||'---'||coalesce(v_correction,0)||'---'||v_NeededQtyInTimeNOStock||'---'||Cur_PlanProduct.M_PRODUCT_ID;
        IF (v_neededQty_New >= 0) THEN   
            -- Kein Einkauf notwendig! - Dann interessiert der  opt. Lagerbestand nicht.  
            delete from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID  and M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID and inouttrxtype='OS'
                                                        and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'');
        END IF;
        if v_isfirstneed='Y' and (v_neededQty_New < 0) then
        -- Nur ersten Bedarf bestellen.
                select sum(qty) into v_correction2 from MRP_RUN_PURCHASELINE where mrp_run_purchase_id=p_Run_ID and m_product_id=Cur_PlanProduct.M_Product_ID 
                                                    and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                                                    and planneddate>v_scheddeliverydate and planneddate>p_planningdate
                and planneddate > (select min(planneddate) from MRP_RUN_PURCHASELINE where mrp_run_purchase_id=p_Run_ID and m_product_id=Cur_PlanProduct.M_Product_ID and inouttrxtype  in ('WR','SO','MF'));
                if coalesce(v_correction2,0)<>0 then
                    SELECT * INTO  v_Aux_New FROM Mrp_Run_Insertlines(Cur_PlanProduct.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run_ID, Cur_PlanProduct.M_Product_ID, v_correction2 *(-1), 'TA', NULL, NULL, NULL,NULL, to_date('01.01.9999','dd.mm.yyyy'),  NULL,Cur_PlanProduct.m_Warehouse_ID);
                end if;
                v_neededQty_New:=v_neededQty_New + (coalesce(v_correction2,0) *(-1));
        end if;
        IF (v_neededQty_New < 0) THEN            
            -- Einkauf notwendig! - Dann füllen wir das Lager mit opt. Lagerbestand auf.  
            v_neededQty_New:=v_neededQty_New+coalesce(v_correction,0);
            if v_neededQty_New < 0 then
                --raise exception '%', 'Date:'||v_scheddeliverydate||'-QTY-'||v_neededQty_New||'VEND:'||v_vendor;
                -- Plan a later delivery date, if this is possible according to demands and possible delivery date of vendor.
                select coalesce(sum(qty),0) into v_auxQty from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID and 
                                              M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID and inouttrxtype='ST'
                                              and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'');
                v_planneddate_new:=v_scheddeliverydate;
                for Cur_Lines in (select sum(qty) as qty,planneddate from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = p_Run_ID and 
                                              M_PRODUCT_ID=Cur_PlanProduct.M_PRODUCT_ID 
                                              and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                                              and inouttrxtype not in ('ST','OS','MS') group by planneddate order by planneddate)
                LOOP
                    v_auxQty:=v_auxQty+Cur_Lines.qty;
                    if v_auxQty<0 then
                        v_planneddate_new:=Cur_Lines.planneddate;
                        --raise exception '%', 'MIN!'||Cur_Lines.planneddate;
                        exit;
                    end if;
                END LOOP;
                -- 2ND UOM
                select c_uom_id into  v_prodUOM from m_product where m_product_id=Cur_PlanProduct.M_Product_ID;
                if v_prodUOM!=coalesce(v_uom,v_prodUOM) then
                    -- Order in 2nd UOM
                    select m_product_uom_id into v_2nduom from m_product_uom where m_product_id=Cur_PlanProduct.M_Product_ID and c_uom_id=v_uom;
                    SELECT floor(c_uom_convert(v_neededQty_New ,v_prodUOM,v_uom,'NO')) into v_2ndqty;
                    v_Qty_New:=v_2ndqty;
                else
                   v_2ndqty:=null;
                   v_2nduom:=null;
                   v_Qty_New:=v_neededQty_New;
                end if;    
                v_Qty_New := GREATEST(v_Qty_New*-1, v_qtystd);
                --raise notice '%','UUUUUUUUUUU--'||p_Run_ID||'--'||Cur_PlanProduct.M_PRODUCT_ID||'---'||coalesce(v_planneddate_new,now()-10000)||coalesce(v_vendor,'______NOVVVV')||'-----'||coalesce(v_neededQty_New);
                v_Qty_New := GREATEST(v_Qty_New, COALESCE(v_qtymin,0)); -- MH
                -- Plan with latest possible delivery Date., If Vendor can deliver to that date, Otherwise Plan with the Lead Time of the Vendor
                If v_scheddeliverydate > v_planneddate_new then
                    v_planneddate_new:=v_scheddeliverydate;
                end if;
                -- SZ corrected multiplication
                --IF (v_qtytype = 'M' and coalesce(v_qtymin,0)!=0) THEN --Multiple lot qty
                IF (v_ismultipleofminimumqty = 'Y' AND COALESCE(v_qtymin,0)!=0) THEN --Multiple lot qty
                v_Qty_New := CEIL(v_Qty_New/v_qtymin)*v_qtymin;
                END IF;
                if v_2ndqty is not null then
                    v_2ndqty:=v_Qty_New;
                    SELECT c_uom_convert(v_2ndqty ,v_uom,v_prodUOM,'Y') into v_Qty_New;
                end if;
                -- Calculate the Total Demand in this Purchase run
                select sum(qty)*-1 into v_alldemand from MRP_RUN_PURCHASELINE where inouttrxtype not in ('PP','IQ','OS','MS','SF','TA') and MRP_RUN_PURCHASE_ID = p_Run_ID
                       and m_product_id=Cur_PlanProduct.M_Product_ID
                       and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'');
                select sum(qty)*-1 into v_auxQty from MRP_RUN_PURCHASELINE where inouttrxtype not in ('PP','IQ','OS','MS','SF') and MRP_RUN_PURCHASE_ID = p_Run_ID
                       and m_product_id=Cur_PlanProduct.M_Product_ID 
                       and coalesce(m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                       and planneddate<=v_Planneddate_new;
                if v_auxQty>v_alldemand then
                    v_alldemand:=v_auxQty;
                end if;
                if (v_alldemand<0) then
                    v_alldemand:=0;
                end if;
                v_thisdemand:=(v_neededQty_New)*-1;
                if v_thisdemand>v_alldemand then
                    v_thisdemand:=v_alldemand;
                end if;
                -- Get Offers Price
                v_price:=M_Get_Offers_Price(v_Planneddate_new,v_vendor,Cur_PlanProduct.M_Product_ID,v_Qty_New, v_pricelistID,'N',null,'N',null,v_uom,v_productPoId,Cur_PlanProduct.m_attributesetinstance_id);
                v_frameqty:=0;
                -- Be aware of Frame Contracts
                for v_cur in (select ol.c_orderline_id, ol.qtyordered-coalesce(ol.calloffqty,0) as qtyleft
                       from c_orderline ol,c_order o where ol.c_order_id=o.c_order_id and o.c_doctype_id= '56913A519BA94EB59DAE5BF9A82F5F7D' 
                       and o.docstatus='CO' and ol.m_product_id=Cur_PlanProduct.M_Product_ID and o.c_bpartner_id=v_vendor 
                       and coalesce(ol.m_attributesetinstance_id,'')=coalesce(Cur_PlanProduct.m_attributesetinstance_id,'')
                       and ol.qtyordered-coalesce(ol.calloffqty,0) >= 0 and o.contractdate <= v_Planneddate_new and o.enddate >= v_Planneddate_new order by o.contractdate)
                LOOP
                       v_framecontract:=v_cur.c_orderline_id;
                       v_frameqtyleft:=v_cur.qtyleft;
                        if v_frameqtyleft>= v_Qty_New-v_frameqty then v_frameqty2buy:=v_Qty_New-v_frameqty; else   v_frameqty2buy:=   v_frameqtyleft;  end if;
                        v_frameqty:=v_frameqty + v_frameqty2buy;
                        SELECT * INTO  v_Aux_New FROM Mrp_Run_Insertlines(Cur_PlanProduct.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run_ID, Cur_PlanProduct.M_Product_ID, v_frameqty2buy,'PP',  NULL, NULL, NULL, NULL,v_Planneddate_new, v_vendor,p_warehouse);
                        update mrp_run_purchaseline set neededqty = qty,pricelist=v_price,framecontractline=v_framecontract,totaldemand=v_alldemand,thisdemand=v_thisdemand,
                                                        m_product_po_id=v_productPoId,c_uom_id=v_prodUOM,m_product_uom_id=v_2nduom,
                                                        quantityorder=v_2ndqty where mrp_run_purchaseline_id=v_Aux_New; 
                END LOOP;               
                -- 'PP' : 'Bestell-Vorschlag'
                -- Wenn Kein Frame Contract benutzt wurde: Normaler EK ggf. über Restmenge
                if v_frameqty<v_Qty_New then
                        SELECT * INTO  v_Aux_New FROM Mrp_Run_Insertlines(Cur_PlanProduct.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run_ID, Cur_PlanProduct.M_Product_ID, v_Qty_New-v_frameqty,'PP',  NULL, NULL, NULL, NULL,v_Planneddate_new, v_vendor,p_warehouse);
                        update mrp_run_purchaseline set neededqty = qty,pricelist=v_price,totaldemand=v_alldemand,thisdemand=v_thisdemand,
                                                        m_product_po_id=v_productPoId,c_uom_id=v_prodUOM,m_product_uom_id=v_2nduom,
                                                        quantityorder=v_2ndqty where mrp_run_purchaseline_id=v_Aux_New; 
                end if;
                -- MH: finally insert additional line, if qty is adjusted according std-qty or min-qty by purchase default
                IF (v_Qty_New != v_neededQty_New) THEN
                    SELECT * INTO  v_Aux_New FROM Mrp_Run_Insertlines(Cur_PlanProduct.m_attributesetinstance_id, p_Org_ID, p_User_ID, p_Run_ID, Cur_PlanProduct.M_Product_ID, -(v_Qty_New + v_neededQty_New), 'IQ',NULL, NULL, NULL, NULL,v_Planneddate_new, v_vendor,p_warehouse);
                END IF;
            END IF;
          END IF;  

    END LOOP;
    PERFORM mrp_purchaseplan_userexit(p_run_id);
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%','MRP_PURCHASEPLAN exception: ' || v_ResultStr;
  RAISE EXCEPTION '%', SQLERRM;
--  RETURN;
END ;
$body$
LANGUAGE 'plpgsql'
COST 100;

-- User Exit to MRP_PURCHASEPLAN
CREATE or replace FUNCTION mrp_purchaseplan_userexit(p_run_id varchar) RETURNS VOID
AS $_$
DECLARE
BEGIN
  
END;
$_$  LANGUAGE 'plpgsql';


select zsse_dropfunction('mrp_run_insertlines');

CREATE OR REPLACE FUNCTION mrp_run_insertlines(p_attributesetinstance_id character varying, p_org_id character varying, p_user_id character varying, p_runID varchar, p_product_id character varying, p_qty numeric, p_inouttrxtype character, p_orderline_id character varying, p_projecttask_id character varying, p_salesforecastline_id character varying, p_requisitionline_id character varying,  p_planneddate timestamp without time zone, p_vendor_id character varying,p_warehouse_id varchar, OUT p_line_id character varying) RETURNS character varying
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
* Contributions: Don't insert 0 - Values
****************************************************************************************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR:=''; --OBTG:VARCHAR2--
  v_plannedorderdate timestamp;
  v_Client_ID varchar:='C726FEC915A54A0995C568555DA5BB3C';
  v_descr varchar;
  v_vpvnr varchar;
BEGIN
  BEGIN --BODY
    v_ResultStr := 'Inserting run lines';
    --raise notice '%', 'BEFInsert';
    If coalesce(p_Qty,0)!=0  then
          select description into v_descr from m_product where m_product_id=p_product_id;
          select vendorproductno into v_vpvnr  from m_product_po where m_product_id=p_product_id and c_bpartner_id=p_vendor_id limit 1;
          select datedoc into v_plannedorderdate from mrp_run_purchase where mrp_run_purchase_id=p_runID;
          SELECT * INTO  p_Line_ID FROM Ad_Sequence_Next('MRP_Run_PurchaseLine', p_User_ID);
          
          INSERT INTO MRP_RUN_PURCHASELINE (
            MRP_RUN_PURCHASELINE_ID,mrp_run_purchase_id,
            AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
            M_PRODUCT_ID, QTY,  PLANNEDDATE, PLANNEDORDERDATE, INOUTTRXTYPE,neededqty,
            C_ORDERLINE_ID, C_PROJECTTASK_ID, MRP_SALESFORECASTLINE_ID, M_REQUISITIONLINE_ID, ISCOMPLETED, C_BPARTNER_ID,m_warehouse_id,m_attributesetinstance_id,
            description,vendorproductno,
            leadtime,
            demanddate)
          VALUES (
            p_Line_ID,p_runID,
            v_Client_ID, p_Org_ID, 'Y', TO_DATE(NOW()), p_User_ID, TO_DATE(NOW()), p_User_ID,
            p_Product_ID, p_Qty,  p_PlannedDate, v_plannedorderdate, p_InOutTrxType,0,
            p_OrderLine_ID, p_projecttask_ID, p_SalesForecastLine_ID, p_RequisitionLine_ID, 'N', p_vendor_Id,p_warehouse_id,p_attributesetinstance_id,
            v_descr,v_vpvnr,
            case when p_InOutTrxType = 'PP' then
              (select deliverytime_promised from m_product_po po where
                      po.m_product_id = p_Product_ID
                  and po.isactive = 'Y'
                  and po.iscurrentvendor = 'Y'
                  and po.ad_org_id in ('0', p_Org_ID)
                  order by po.qualityrating desc nulls last, po.updated limit 1
              )
            else null end,
            case when p_InOutTrxType = 'PP' then
              (select planneddate from mrp_inoutplan_v io where
                      io.m_product_id = p_Product_ID
                  and io.isactive = 'Y'
                  and io.ad_org_id in ('0', p_Org_ID)
                  and io.estimated_stock_qty < 0
                  order by planneddate asc limit 1
              )
            else null end
          );
          --raise notice '%',p_runID||'AIIIIIIIIII'||p_Line_ID;
    end if;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%','MRP_RUN_INSERTLINES exception: ' || v_ResultStr ;
  RAISE EXCEPTION '%', SQLERRM;
--  RETURN;
END ; $_$;



CREATE OR REPLACE FUNCTION mrp_purchaseorder (
  p_pinstance_id varchar
)
RETURNS void AS
$body$
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
 Contributions: Price List in Purchasing are not useful - Removed.
                We take the price from m_product_po 
                Take the standard Quantity on ordering (not minimum)
                Do not substract acual stock qty
                Do order in ORDER Qty if it is in purchasing
*************************************************************************************************************************************************/ 
  v_ResultStr VARCHAR:=''; --OBTG:VARCHAR2--
  v_Message VARCHAR:=' Orders: '; --OBTG:VARCHAR2--
  v_Result NUMERIC:= 1;
  v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_User_ID VARCHAR(32):='0'; --OBTG:VARCHAR2--
  v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Org_ID VARCHAR(32); --OBTG:VARCHAR2--


  v_COrder_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_COrderLine_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_DocumentNo VARCHAR(60); --OBTG:NVARCHAR2--
  v_created BOOLEAN := FALSE;
  FINISH_PROCESS BOOLEAN DEFAULT FALSE;

  v_M_Warehouse_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Description character varying; --OBTG:nvarchar2--
  v_Description2 character varying; 
  v_DateDoc TIMESTAMP;
  v_PriceList NUMERIC;
  v_PriceActual NUMERIC;
  v_PriceLimit NUMERIC;
  LastCBPartner_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_Line NUMERIC;
  v_CDocTypeID VARCHAR(32); --OBTG:varchar2--
  v_BPartner_Location_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_BillTo_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_PriceListVersion NUMERIC;
  v_PriceStd NUMERIC;
  v_TaxId VARCHAR(32); --OBTG:varchar2--
  v_ProductName VARCHAR(90); --OBTG:NVARCHAR2--

  v_Count NUMERIC;
  v_orderuom character varying;
  v_prodUOM  character varying;
  v_orderqty NUMERIC;
  v_stdqty  NUMERIC;
  v_qty  NUMERIC;
  v_prec  NUMERIC;
  v_vendorpnumber character varying;
--v_qtytype character varying;
  v_ismultipleofminimumqty CHAR;
  v_order_min NUMERIC;
  v_conversion NUMERIC;

  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    Cur_workproposal RECORD;
    v_novendordefined varchar;
  -- Call Offs
  v_isFramecontract varchar:='N';
  v_2nduom varchar;
  p_org_id varchar;
  v_framecontract varchar;
  v_sheddate date;
  BEGIN
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    if (select count(*) from  AD_Process_Run r ,ad_process_request rq WHERE r.ad_process_request_id=rq.ad_process_request_id 
               and rq.AD_Process_ID ='800163' and r.Status='PRC')>1 then
        RAISE EXCEPTION '%' ,'@ProcessExecutes@';
    end if;
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID, i.AD_User_ID, i.AD_Client_ID, i.AD_Org_ID,
        p.ParameterName, p.P_String, p.P_Number, p.P_Date
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Record_ID:=Cur_Parameter.Record_ID;
      v_User_ID:=Cur_Parameter.AD_User_ID;
      v_Client_ID := Cur_Parameter.AD_Client_ID;
      p_org_id := Cur_Parameter.ad_org_id;
      IF(Cur_Parameter.ParameterName='M_Warehouse_ID') THEN
        v_M_Warehouse_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  M_Warehouse_ID=' || v_M_Warehouse_ID;
      END IF;
    END LOOP; -- Get Parameter
    -- Delete not approved lines if Workflow is active...
    if  c_getconfigoption('mrpapprovalworkflow',p_org_id)='Y' then
            delete from MRP_RUN_PURCHASELINE where MRP_RUN_PURCHASE_ID = v_Record_ID and INOUTTRXTYPE = 'PP' and  isapproved='N';
    end if;       
    SELECT COALESCE(TO_CHAR(DESCRIPTION), ' '), DateDoc, AD_Org_ID
      INTO v_Description2, v_DateDoc, v_Org_ID
     FROM MRP_RUN_PURCHASE
     WHERE MRP_RUN_PURCHASE_ID = v_Record_ID;
    -- You need to have vendor information in order to purchase
    select b.value||'-'||b.name into v_novendordefined from c_bpartner b,MRP_RUN_PURCHASELINE p 
    where  p.MRP_RUN_PURCHASE_ID = v_Record_ID and b.po_pricelist_id is null
           AND INOUTTRXTYPE = 'PP'
           AND p.C_OrderLine_ID IS NULL
           AND p.C_Bpartner_ID = b.C_BPartner_ID limit 1;
    if v_novendordefined is not null then
        raise exception '%','No Purchase Settings found for vendor: '||v_novendordefined;
    end if;
    FOR Cur_workproposal IN (
      SELECT rp.*, bp.PO_PRICELIST_ID, pl.C_Currency_ID,
             BP.PAYMENTRULEPO as paymentrule, BP.PO_PAYMENTTERM_ID AS C_PAYMENTTERM_ID,
             bp.DeliveryViaRule,p.C_UOM_ID as puom,
             ol.c_order_id as framecontract
      FROM MRP_RUN_PURCHASELINE rp left join c_orderline ol on ol.c_orderline_id=rp.framecontractline,
           C_BPartner bp,
           M_PriceList pl,
           M_Product p
      WHERE rp.MRP_RUN_PURCHASE_ID = v_Record_ID
        AND INOUTTRXTYPE = 'PP'
        AND rp.C_OrderLine_ID IS NULL
        AND rp.C_Bpartner_ID = bp.C_BPartner_ID
        AND pl.M_PriceList_ID = bp.PO_PRICELIST_ID
        AND p.M_Product_ID = rp.M_Product_ID
      ORDER BY rp.C_BPartner_ID,rp.framecontractline,rp.PLANNEDDATE
      ) LOOP
      v_ResultStr:='Create Purchase Order';

      if (v_COrder_Id is null) or (Cur_workproposal.C_BPartner_ID!=LastCBPartner_ID) 
         or (v_isFramecontract='N' and Cur_workproposal.framecontractline is not null)
         or (v_isFramecontract='Y' and (Cur_workproposal.framecontractline is null or Cur_workproposal.framecontract!=coalesce(v_framecontract,'')))
      then --new header
        v_Line := 0;
        if v_COrder_Id is not null and  c_getconfigoption('poactiveafterpurchaserun',p_org_id)='Y' then
                perform c_order_post1(null,v_COrder_Id);
        end if;
        SELECT * INTO  v_COrder_ID FROM Ad_Sequence_Next('C_Order', v_Client_ID);
        v_DocumentNo := NULL;
        -- Use Frame Contract Calloff, if applicable
        v_framecontract:=Cur_workproposal.framecontract;
        if Cur_workproposal.framecontractline is null then
            v_CDocTypeID := AD_Get_DocType(v_Client_ID, v_Org_ID,'POO',NULL);
            v_isFramecontract:='N';
        else
            v_CDocTypeID := '5EED1EFB8BDD4C0491ECCFD7395DA446';
            v_isFramecontract:='Y';
        end if;
        SELECT * INTO  v_DocumentNo FROM AD_Sequence_DocType(v_CDocTypeID, v_Org_ID, 'Y') ;
        IF(v_DocumentNo IS NULL) THEN
          SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('DocumentNo_C_Order', v_Org_ID, 'Y') ;
        END IF;


        SELECT MIN(C_BPARTNER_LOCATION_ID)
        INTO v_BPartner_Location_ID
        FROM C_BPARTNER_LOCATION
        WHERE ISACTIVE='Y'
          AND ISSHIPTO='Y'
          AND C_BPARTNER_ID=Cur_workproposal.C_BPARTNER_ID;

        SELECT MIN(C_BPARTNER_LOCATION_ID)
        INTO v_BillTo_ID
        FROM C_BPARTNER_LOCATION
        WHERE ISACTIVE='Y'
          AND ISBILLTO='Y'
          AND C_BPARTNER_ID=Cur_workproposal.C_BPARTNER_ID;

        INSERT INTO C_Order
          (C_ORDER_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
           CREATED, CREATEDBY, UPDATED, UPDATEDBY,
           ISSOTRX, DOCUMENTNO, DOCSTATUS, DOCACTION, PROCESSING,
           C_DOCTYPE_ID,C_DOCTYPETARGET_ID, DESCRIPTION,
           DATEORDERED, DATEACCT, C_BPARTNER_ID, BILLTO_ID,
           C_BPARTNER_LOCATION_ID, C_CURRENCY_ID, PAYMENTRULE, C_PAYMENTTERM_ID,
           INVOICERULE, DELIVERYRULE, FREIGHTCOSTRULE, DELIVERYVIARULE,
           PRIORITYRULE, TOTALLINES, GRANDTOTAL,
           M_WAREHOUSE_ID, M_PRICELIST_ID, ISTAXINCLUDED, DATEPROMISED,scheddeliverydate)
        VALUES
         (v_COrder_ID, v_Client_ID, v_Org_ID,'Y',
         TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID,
         'N', v_DocumentNo,  'DR', 'CO','N',
          v_CDocTypeID, v_CDocTypeID, v_Description2,
          v_DateDoc,v_DateDoc, Cur_workproposal.C_BPartner_ID,v_BillTo_ID,
          v_BPartner_Location_ID, Cur_workproposal.C_Currency_ID, Cur_workproposal.paymentrule, Cur_workproposal.C_PAYMENTTERM_ID,
          'D', 'A', 'I',COALESCE(Cur_workproposal.DeliveryViaRule,'D'),
          '5',0,0,
          coalesce(Cur_workproposal.m_warehouse_id,v_M_Warehouse_ID), Cur_workproposal.PO_PRICELIST_ID, 'N', Cur_workproposal.PLANNEDDATE,Cur_workproposal.PLANNEDDATE
          );
          -- SZ Sucess Message:
          v_Message:=v_Message||'  '||zsse_htmlLinkDirectKey('../PurchaseOrder/Header_Relation.html',v_COrder_ID,v_DocumentNo);
      end if; --header
      LastCBPartner_ID := Cur_workproposal.C_BPartner_ID;

      v_Line := v_Line + 10;
      SELECT * INTO  v_COrderLine_ID FROM Ad_Sequence_Next('C_OrderLine', v_Client_ID);
      -- SZ: In Purchasing take the Price from m_product_po
      -- SZ: Take the standard Quantity on ordering (not minimum)
      --          Do not substract acual stock qty
      --          Do order in ORDER Qty if it is in purchasing
      v_ResultStr:='Get order line data';
      select c_uom_id into v_2nduom from m_product_uom where m_product_uom_id=Cur_workproposal.M_Product_uom_ID; 
      SELECT count(*) INTO v_Count
      FROM m_product_po
       WHERE M_Product_ID = Cur_workproposal.M_Product_ID and c_bpartner_id=Cur_workproposal.C_BPartner_ID
        AND IsActive= 'Y' and iscurrentvendor='Y';
      IF (v_count > 0) THEN
        SELECT PriceList, Pricepo as PriceStd,
               M_Get_Offers_Price(v_DateDoc,Cur_workproposal.C_BPartner_ID,Cur_workproposal.M_Product_ID,coalesce(Cur_workproposal.quantityorder,Cur_workproposal.QTY), Cur_workproposal.PO_PRICELIST_ID,'N',null,'N',null,v_2nduom,Cur_workproposal.m_product_po_id, Cur_workproposal.m_attributesetinstance_id,v_Org_ID),
               Pricepo as PriceLimit,
               qtystd,c_uom_id,vendorproductno, ismultipleofminimumqty, order_min -- qtytype
          INTO v_PriceList, v_PriceStd, v_PriceActual, v_PriceLimit,v_stdqty,v_orderuom ,v_vendorpnumber, v_ismultipleofminimumqty, v_order_min -- v_qtytype
        FROM M_PRODUCT_PO po
            WHERE po.m_product_id=Cur_workproposal.M_Product_ID and PO.isactive='Y'  and po.iscurrentvendor='Y' and PO.AD_ORG_ID in ('0',v_Org_ID)
            ORDER BY COALESCE(po.qualityrating,0) DESC, updated DESC LIMIT 1;
        -- SZ end
      ELSE
        SELECT NAME INTO v_ProductName
        FROM M_PRODUCT
        WHERE M_PRODUCT_ID = Cur_workproposal.M_Product_ID;
        v_Result := 0;
        v_Message := '@PriceNotFound@ ' || v_ProductName;
        RAISE EXCEPTION '%', v_Message; --OBTG:-20000--
      END IF;
      -- SZ: Get the Tax from Product
      v_TaxID :=zsfi_GetTax(v_BPartner_Location_ID,Cur_workproposal.M_Product_ID,v_Org_ID) ;
      v_qty:=  Cur_workproposal.neededqty;
      select c_uom_id into  v_prodUOM from m_product where m_product_id=Cur_workproposal.M_Product_ID;
      /*
      -- SZ Do order in ORDER Qty if it is in purchasing
      -- 2ndary UOM must be supplied if applicable
      v_orderqty := null;
      if coalesce(v_orderuom,v_prodUOM)!=v_prodUOM then
         SELECT MULTIPLYRATE into v_conversion FROM C_UOM_CONVERSION WHERE C_UOM_ID = Cur_workproposal.C_UOM_ID AND C_UOM_TO_ID = v_orderuom;
         if v_conversion is null then 
            SELECT dividerate into v_conversion FROM C_UOM_CONVERSION WHERE C_UOM_ID = v_orderuom AND C_UOM_TO_ID = Cur_workproposal.C_UOM_ID; 
         end if;
         if coalesce(v_conversion,0)!=0 then
            v_orderqty := v_qty*v_conversion;
            v_orderqty := GREATEST(v_orderqty,v_stdqty);
          --IF (v_qtytype = 'M' and coalesce(v_order_min,0)!=0) THEN --Multiple lot qty
            IF (v_ismultipleofminimumqty = 'Y' and coalesce(v_order_min,0)!=0) THEN --Multiple lot qty
              v_orderqty := CEIL(v_orderqty/v_order_min)*v_order_min;
            END IF;
            select stdprecision into v_prec from c_uom where c_uom_id=v_orderuom;
            v_orderqty:=round(v_orderqty,v_prec);
            v_qty:=v_orderqty/v_conversion;
            select stdprecision into v_prec from c_uom where c_uom_id=v_prodUOM;
            v_qty:=round(v_qty,v_prec);
            select m_product_uom_id into v_orderuom from m_product_uom where m_product_id=Cur_workproposal.m_product_id and C_UOM_ID=v_orderuom;
         else
            v_orderqty := null;
         end if;
       end if;
       */
      -- SZ build Description:
      --select zssi_getText('zssi_vendorproductno',coalesce(default_ad_language,'de_DE'))||vendorproductno||E'\r\n'||documentnote into v_Description from m_product,ad_user where ad_user_id=v_User_ID and m_product_id=Cur_workproposal.M_Product_ID;
      v_Description:=zspr_getproductdocnoteCpyText(Cur_workproposal.ad_org_id,Cur_workproposal.m_product_id,Cur_workproposal.C_BPartner_ID,(select c_uom_id from m_product_uom where m_product_uom_id=Cur_workproposal.m_product_uom_id));
      v_ResultStr:='Insert order line';
      if v_PriceList is null or v_PriceStd is null or v_PriceActual is null then
        raise exception '%','Artikel:'||(select value from m_product where m_product_id=Cur_workproposal.M_Product_ID)||' Einkaufspreise (Artikel||Einkauf) nicht richtig gepflegt';
      end if;
      INSERT INTO C_OrderLine
        (C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
         CREATED, CREATEDBY, UPDATED, UPDATEDBY,
         C_ORDER_ID, LINE, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID,
         DATEORDERED, DATEPROMISED, DESCRIPTION, M_PRODUCT_ID,
         M_WAREHOUSE_ID, C_UOM_ID, QTYORDERED, C_CURRENCY_ID,
         PRICELIST, PRICEACTUAL, PRICELIMIT,
         PRICESTD,scheddeliverydate,
         C_TAX_ID,quantityorder,m_product_uom_id,m_product_po_id,orderlineselfjoin,m_attributesetinstance_id)
     VALUES
      (v_COrderLine_ID,v_Client_ID, v_Org_ID,'Y',
       TO_DATE(NOW()), v_User_ID, TO_DATE(NOW()), v_User_ID,
       v_COrder_ID, v_Line, Cur_workproposal.C_BPartner_ID, v_BPartner_Location_ID,
       v_DateDoc, Cur_workproposal.PLANNEDDATE, v_Description, Cur_workproposal.M_Product_ID,
       coalesce(Cur_workproposal.m_warehouse_id,v_M_Warehouse_ID), coalesce(Cur_workproposal.C_UOM_ID,Cur_workproposal.puom), v_qty, Cur_workproposal.C_Currency_ID,
       v_PriceList, v_PriceActual, v_PriceLimit,
       v_PriceStd, Cur_workproposal.PLANNEDDATE,
       v_TaxID,Cur_workproposal.quantityorder,Cur_workproposal.m_product_uom_id,Cur_workproposal.m_product_po_id,
       Cur_workproposal.framecontractline,Cur_workproposal.m_attributesetinstance_id
      );

      UPDATE MRP_RUN_PURCHASELINE
        SET C_OrderLine_ID = v_COrderLine_ID
      WHERE MRP_RUN_PURCHASELINE_ID = Cur_workproposal.MRP_RUN_PURCHASELINE_ID;
    END LOOP;
    -- Adjust Shed. Del. Date and Inv. Date
    select trunc(min(scheddeliverydate)) into  v_sheddate from c_orderline where c_order_id=v_COrder_ID;
    if v_sheddate is not null then
        update c_order set DATEPROMISED=v_sheddate,scheddeliverydate=v_sheddate where c_order_id=v_COrder_ID;
    end if;
    if v_COrder_Id is not null and  c_getconfigoption('poactiveafterpurchaserun',p_org_id)='Y' then
                perform c_order_post1(null,v_COrder_Id);
    end if;
  v_ResultStr :='Set requisition lines as planned';
  UPDATE M_RequisitionLine
  SET REQSTATUS = 'P'
  WHERE M_RequisitionLine_ID IN (SELECT M_RequisitionLine_ID
                                 FROM MRP_RUN_PURCHASELINE
                                 WHERE MRP_RUN_PURCHASE_ID = v_Record_ID
                                   AND INOUTTRXTYPE = 'MF');

  UPDATE M_Requisition
  SET DocStatus = 'CL'
  WHERE M_Requisition_ID IN (SELECT M_Requisition_ID
                            FROM M_RequisitionLine
                            WHERE M_RequisitionLine_ID IN (SELECT M_RequisitionLine_ID
                                                          FROM MRP_RUN_PURCHASELINE
                                                          WHERE MRP_RUN_PURCHASE_ID = v_Record_ID
                                                            AND INOUTTRXTYPE = 'MF'))
    AND NOT EXISTS (SELECT 1
                    FROM M_RequisitionLine rl
                    WHERE rl.REQSTATUS = 'O'
                      AND rl.M_Requisition_ID = M_Requisition.M_Requisition_ID);
  END;--BODY
  update MRP_RUN_PURCHASE set launchpo='Y' where MRP_RUN_PURCHASE_ID = v_Record_ID;
  IF(p_PInstance_ID IS NOT NULL) THEN
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, substr(v_Message,1,2000)) ;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  RAISE NOTICE '%','MRP_PURCHASEORDER exception: ' || v_ResultStr ;
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  -- ROLLBACK;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
--  RETURN;
END ;
$body$
LANGUAGE 'plpgsql'
COST 100;

select zsse_dropfunction('mrp_getpo_qty');
CREATE OR REPLACE FUNCTION mrp_getpo_qty (
  p_product_id    VARCHAR,
  p_bpartner_id   VARCHAR,
  p_qty           NUMERIC,
  p_UomId         varchar,
  p_MProductPOID varchar
)
RETURNS NUMERIC AS
$body$
DECLARE
  v_mpo_m_product_po_id CHARACTER VARYING;
  v_mpo_qtystd NUMERIC;
  v_mpo_order_min NUMERIC;
  v_mpo_ismultipleofminimumqty CHAR := 'N';
  v_mrp_qty NUMERIC := 0;
  v_result NUMERIC := COALESCE(p_qty,0); -- Eingangswert wird Rueckgabewert, wenn keine Daten im Einkauf hinterlegt, 0=Menge lt. Einkauf ermitteln
BEGIN
 -- bei negativen Bestellmengen bzw. Bestellmengen=0 werden Standard- bzw. Mindest-Bestellmengen nicht bruecksichtigt
  IF ( COALESCE(p_qty, 0) >= 0 ) THEN -- kein negativen Bestellmengen (bei neg. BestellMenge beachte: a) CEIL(-2.0 / 20.0)= 0; b) -2.0/20.0= -0,1, CEIL(2.0 / 20.0)=1
    SELECT mpo.m_product_po_id, COALESCE(mpo.qtystd, 0), COALESCE(mpo.order_min, 0), COALESCE(mpo.ismultipleofminimumqty, 'N')
    INTO v_mpo_m_product_po_id, v_mpo_qtystd, v_mpo_order_min, v_mpo_ismultipleofminimumqty
    FROM m_product_po mpo WHERE mpo.m_product_id = p_product_id AND mpo.c_bpartner_id = p_bpartner_id
    and case when p_UomId is not null then mpo.c_uom_id=p_UomId else mpo.c_uom_id is null end 
    and case when p_MProductPOID is not null then mpo.m_product_po_Id=p_MProductPOID else m_manufacturer_id is null and  manufacturernumber is null end
    order by qualityrating desc limit 1;

    IF (v_mpo_m_product_po_id IS NOT NULL) THEN -- Einkauf (m_product_po) gefunden
      v_result := GREATEST( COALESCE(v_mpo_order_min,0), COALESCE(v_mpo_qtystd,0) ); --  'Standard Bestellmenge' bzw. 'Mindest-Bestellmenge' uebernehmen
      RAISE NOTICE 'order_min:% qtystd:% v_mpo_ismultipleofminimumqty:% v_result:%', v_mpo_order_min, v_mpo_qtystd, v_mpo_ismultipleofminimumqty, v_result;
      v_result := GREATEST(p_qty, v_result); -- 'tats. Bestellmenge' bzw. Mindestbestellmenge
      IF ( (v_mpo_ismultipleofminimumqty = 'Y') AND (v_mpo_order_min > 0) ) THEN  -- Vielfaches der Mindestbestellmenge angegeben
        v_result := CEIL(v_result / v_mpo_order_min) * v_mpo_order_min; -- FieldType=NUMERIC, p_qty=nicht negativ
        RAISE NOTICE 'Bestellung aufgrund Standardbestellmengen benötigt: % -> % x % => % ', p_qty, to_char(CEIL(p_qty / v_mpo_order_min)), v_mpo_order_min, trim(to_char(v_result));
      END IF;
    END IF;

  END IF;
  RETURN v_result;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;



select zsse_dropfunction('mrp_getpurchseleadtime');  
CREATE or replace FUNCTION mrp_getpurchseleadtime(p_product_id varchar,p_quickest varchar)  RETURNS numeric
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************


*****************************************************/
DECLARE
  v_leadtime numeric;
BEGIN
    if p_quickest='N' then
        -- select the Best vendor
        SELECT po.deliverytime_promised
                INTO v_leadtime
                FROM M_PRODUCT_PO po
                WHERE po.m_product_id=p_product_id and PO.iscurrentvendor='Y' 
                ORDER BY COALESCE(po.qualityrating,0) desc  LIMIT 1;
    else
         SELECT po.deliverytime_promised
                INTO v_leadtime
                FROM M_PRODUCT_PO po
                WHERE po.m_product_id=p_product_id and PO.iscurrentvendor='Y' 
                ORDER BY COALESCE(po.deliverytime_promised,0)  LIMIT 1;
    end if;
    return v_leadtime;
END ; $_$ LANGUAGE 'plpgsql';





select zsse_dropfunction('mrp_getpo_qtystd');
CREATE OR REPLACE FUNCTION mrp_getpo_qtystd (
  p_product_id    VARCHAR,
  p_bpartner_id   VARCHAR,
  p_UomId         varchar,
  p_MProductPOID varchar
)
RETURNS NUMERIC AS
$body$
DECLARE
  v_mpo_m_product_po_id CHARACTER VARYING;
  v_mpo_qtystd NUMERIC;
  v_result NUMERIC := 0;
BEGIN
  SELECT mpo.m_product_po_id, mpo.qtystd
  INTO v_mpo_m_product_po_id, v_mpo_qtystd
  FROM m_product_po mpo WHERE mpo.m_product_id = p_product_id AND mpo.c_bpartner_id = p_bpartner_id
  and case when p_UomId is not null then mpo.c_uom_id=p_UomId else mpo.c_uom_id is null end 
 and case when p_MProductPOID is not null then mpo.m_product_po_Id=p_MProductPOID else m_manufacturer_id is null and  manufacturernumber is null end
 order by qualityrating desc limit 1;

  IF (v_mpo_m_product_po_id IS NOT NULL) THEN
    v_result := COALESCE(v_mpo_qtystd, 0); -- default=0, order_min could be available
    RAISE NOTICE 'v_mpo_qtystd:% v_result:%', v_mpo_qtystd, v_result;
  END IF;
  RETURN v_result;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

select zsse_dropfunction('mrp_getpo_qtymin');
CREATE OR REPLACE FUNCTION mrp_getpo_qtymin (
  p_product_id    VARCHAR,
  p_bpartner_id   VARCHAR,
  p_UomId         varchar,
  p_MProductPOID varchar
)
RETURNS NUMERIC AS
-- SELECT mrp_getpo_qtymin('A8E55EE655304D2A827785E1275ECCAD', '72286E776B2C4383AD11E886EE6C3BB0') AS mrp_getpo_qtymin;
$body$
DECLARE
  v_mpo_m_product_po_id CHARACTER VARYING;
  v_order_min NUMERIC;
  v_result NUMERIC := 0;
BEGIN
  SELECT mpo.m_product_po_id, mpo.order_min
  INTO v_mpo_m_product_po_id, v_order_min
  FROM m_product_po mpo WHERE mpo.m_product_id = p_product_id AND mpo.c_bpartner_id = p_bpartner_id
  and case when p_UomId is not null then mpo.c_uom_id=p_UomId else mpo.c_uom_id is null end 
  and case when p_MProductPOID is not null then mpo.m_product_po_Id=p_MProductPOID else m_manufacturer_id is null and  manufacturernumber is null end
  order by qualityrating desc limit 1;

  IF (v_mpo_m_product_po_id IS NOT NULL) THEN
    v_result := COALESCE(v_order_min, 0); -- default=0, QtyStd could be available
  END IF;
  RETURN v_result;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;


select zsse_dropfunction('mrp_getpo_ismultipleofminimumqty');

CREATE OR REPLACE FUNCTION mrp_getpo_ismultipleofminimumqty (
  p_product_id    VARCHAR,
  p_bpartner_id   VARCHAR,
  p_UomId         varchar,
  p_MProductPOID varchar
)
RETURNS CHAR AS
-- SELECT mrp_getpo_ismultipleofminimumqty('A8E55EE655304D2A827785E1275ECCAD', '72286E776B2C4383AD11E886EE6C3BB0') AS mrp_getpo_ismultipleofminimumqty;
$body$
DECLARE
  v_mpo_m_product_po_id CHARACTER VARYING;
  v_ismultipleofminimumqty CHAR;
  v_result CHAR := 'N';
BEGIN
  SELECT mpo.m_product_po_id, mpo.ismultipleofminimumqty
  INTO v_mpo_m_product_po_id, v_ismultipleofminimumqty
  FROM m_product_po mpo WHERE mpo.m_product_id = p_product_id AND mpo.c_bpartner_id = p_bpartner_id
  and case when p_UomId is not null then mpo.c_uom_id=p_UomId else 1=1 end
  and case when p_MProductPOID is not null then mpo.m_product_po_Id=p_MProductPOID else m_manufacturer_id is null and  manufacturernumber is null end
  order by qualityrating desc limit 1;

  IF (v_mpo_m_product_po_id IS NOT NULL) THEN
    v_result := COALESCE(v_ismultipleofminimumqty, 'N');
  END IF;
  RETURN v_result;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

select zsse_dropfunction('mrp_getpo_minimpositionvalue');
CREATE OR REPLACE FUNCTION mrp_getpo_minimpositionvalue (
  p_product_id    VARCHAR,
  p_bpartner_id   VARCHAR,
  p_UomId         varchar,
  p_MProductPOID varchar
)
RETURNS NUMERIC AS
$body$
DECLARE
  v_mpo_m_product_po_id CHARACTER VARYING;
  v_mpo_minimpositionvalue NUMERIC;
  v_result NUMERIC := 0;
BEGIN
  SELECT mpo.m_product_po_id, mpo.minimpositionvalue
  INTO v_mpo_m_product_po_id, v_mpo_minimpositionvalue
  FROM m_product_po mpo WHERE mpo.m_product_id = p_product_id AND mpo.c_bpartner_id = p_bpartner_id
  and case when p_UomId is not null then mpo.c_uom_id=p_UomId else mpo.c_uom_id is null end 
 and case when p_MProductPOID is not null then mpo.m_product_po_Id=p_MProductPOID else m_manufacturer_id is null and  manufacturernumber is null end
 order by qualityrating desc limit 1;

  IF (v_mpo_m_product_po_id IS NOT NULL) THEN
    v_result := COALESCE(v_mpo_minimpositionvalue, 0); -- default=0, order_min could be available
  END IF;
  RETURN v_result;
END;
$body$
LANGUAGE 'plpgsql'
COST 100;

CREATE or replace FUNCTION mrp_estimated_stockqty(p_productid character varying,p_warehouse_id character varying, p_date date) RETURNS numeric
AS $_$
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
DECLARE
-- Simple Types
v_purchase  numeric:=0;
v_sales  numeric:=0;
v_consumption numeric;
v_production numeric;
v_currstock numeric;
BEGIN
  -- Planned Purchase
  select sum(ol.qtyordered-ol.qtydelivered)  into v_purchase
         from c_order o,c_orderline ol,m_product m  
         where o.c_order_id=ol.c_order_id  and ol.m_product_id=p_productid and  ol.m_product_id=m.m_product_id and  o.m_warehouse_id=p_warehouse_id
         and  ad_get_docbasetype(o.c_doctype_id)  = 'POO'  
         and  ol.deliverycomplete='N' and m.producttype='I'  and m.isstocked='Y' 
         and  o.docstatus='CO' and trunc(coalesce(ol.scheddeliverydate,now()))<=p_date
         and (ol.qtyordered-ol.qtydelivered) > 0;
  -- Planned Sales
  select sum(ol.qtyordered-ol.qtydelivered)  into v_sales
         from c_order o,c_orderline ol,m_product m  
         where o.c_order_id=ol.c_order_id  and ol.m_product_id=p_productid and  ol.m_product_id=m.m_product_id and o.m_warehouse_id=p_warehouse_id 
         and ad_get_docbasetype(o.c_doctype_id)  = 'SOO' 
         and ol.deliverycomplete='N' and m.producttype='I' and m.isstocked='Y'  
         and o.docstatus='CO' and trunc(coalesce(ol.scheddeliverydate,now()))<=p_date
         and (ol.qtyordered-ol.qtydelivered) > 0;

  -- Current Onhand QTY's
  select sum(s.qtyonhand) into v_currstock 
         from m_storage_detail s 
         where s.m_locator_id in (select m_locator_id from m_locator where m_warehouse_id =p_warehouse_id and isactive='Y') 
         and s.m_product_id=  p_productid;
  -- Planned Production
  -- Production-Projects or Production Orders, Must be started, Task not cancelled and not complete, Order have assembly, Production Project has different locator 
  select  sum(qty-qtyproduced)  into v_production  
          from c_projecttask p,c_project pr ,m_product m
          where p.c_project_id=pr.c_project_id and p.m_product_id=p_productid and p.m_product_id=m.m_product_id
          and m.producttype='I' and m.isstocked='Y'
          and pr.projectcategory in ('P','PRO') 
          and pr.projectstatus='OR' 
          and p.iscomplete='N' and p.istaskcancelled='N'
          and (p.qty-p.qtyproduced)>0 
          and case when pr.projectcategory='PRO' then p.assembly='Y' else 1=1 end 
          and trunc(coalesce(p.enddate,now()))<=p_date  
          and case when pr.projectcategory='PRO' then p.issuing_locator else m.m_locator_id end in (select m_locator_id from m_locator where m_warehouse_id =p_warehouse_id); 
  -- Planned Cosumption
  -- Production-Projects or Production Orders or Service Projects. All Must be started, Task not cancelled and not complete, Order have assembly, Production Project has different locator 
  select  sum(bom.quantity-bom.qtyreceived)  into v_consumption  
          from zspm_projecttaskbom bom, c_projecttask p,c_project pr ,m_product m
          where p.c_project_id=pr.c_project_id and p.c_projecttask_id=bom.c_projecttask_id and bom.m_product_id=  p_productid and bom.m_product_id=m.m_product_id
          and m.producttype='I' and m.isstocked='Y'
          and pr.projectcategory in ('PRO','P','S','M')
          and pr.projectstatus='OR' 
          and p.iscomplete='N' and p.istaskcancelled='N' 
          and (bom.quantity-bom.qtyreceived)>0
          and bom.isreturnafteruse='N' 
          and trunc(coalesce(coalesce(case when pr.projectcategory='PRO' then p.startdate else bom.date_plan end,p.startdate),now()))<=p_date 
          and case when pr.projectcategory='PRO' then bom.receiving_locator else bom.m_locator_id end in (select m_locator_id from m_locator where m_warehouse_id =p_warehouse_id);
  return coalesce(v_currstock,0)+coalesce(v_purchase,0)-coalesce(v_sales,0)-coalesce(v_consumption,0)+coalesce(v_production,0);
END;
$_$ LANGUAGE 'plpgsql' VOLATILE COST 100;


select zsse_DropView ('mrp_inoutplanbase_v');
create or replace view mrp_inoutplanbase_v as
-- Purchase and Sales
select trunc(coalesce(ol.scheddeliverydate,LOCALTIMESTAMP)) as  stockdate,
       ol.c_orderline_id as mrp_inoutplanbase_id,
       null as m_locator_id,
       case when d.docbasetype='POO' and ol.deliverycomplete='N' then ol.qtyordered-ol.qtydelivered else 0 end as qtyordered,
       case when d.docbasetype='SOO' and ol.deliverycomplete='N' then ol.qtyordered-ol.qtydelivered else 0 end as qtyinsale,
       0::numeric AS qtyreserved,
       0::numeric AS qtyincomming,
       0::numeric AS qtyorderedframe,
       0::numeric AS qtyinsaleframe,
       ol.m_product_id,o.m_warehouse_id,ol.c_orderline_id,ol.c_projecttask_id,o.ad_org_id,o.ad_client_id,o.updated, o.updatedby, ol.created, ol.createdby,
       d.docbasetype as documenttype,
       case d.docbasetype when 'POO' then ol.qtyordered-ol.qtydelivered else (ol.qtyordered-ol.qtydelivered)*-1 end as movementqty,o.c_bpartner_id,
       ol.m_attributesetinstance_id
       from c_order o,c_orderline ol,m_product p  ,c_doctype d
       where o.c_doctype_id=d.c_doctype_id 
       and o.c_order_id=ol.c_order_id and ol.m_product_id=p.m_product_id  
       and ol.deliverycomplete='N' and p.isstocked='Y' and p.producttype='I' 
       and d.docbasetype  in ('SOO','POO') and o.docstatus='CO'
       and o.m_warehouse_id in (select m_warehouse_id from m_warehouse where isactive='Y' and isblocked='N')
       and o.deliverycomplete='N'
       and (ol.qtyordered-ol.qtydelivered) > 0 
union all
--  Frame Contracts
select trunc(coalesce(o.enddate,LOCALTIMESTAMP)) as  stockdate,
       ol.c_orderline_id as mrp_inoutplanbase_id,
       null as m_locator_id,
       0::numeric AS qtyordered,
       0::numeric AS qtyinsale,
       0::numeric AS qtyreserved,
       0::numeric AS qtyincomming,
       case when o.c_doctype_id='56913A519BA94EB59DAE5BF9A82F5F7D' then ol.qtyordered-coalesce(ol.calloffqty,0) else 0 end AS qtyorderedframe,
       case when o.c_doctype_id='559A80F2E27742D4B2C476045F5C834F' then ol.qtyordered-coalesce(ol.calloffqty,0)  else 0 end AS qtyinsaleframe,
       ol.m_product_id,o.m_warehouse_id,ol.c_orderline_id,ol.c_projecttask_id,o.ad_org_id,o.ad_client_id,ol.updated, ol.updatedby, ol.created, ol.createdby,
      case when o.c_doctype_id='56913A519BA94EB59DAE5BF9A82F5F7D' then 'FRAMEPO' else 'FRAMESO'  end as documenttype,
       case when o.c_doctype_id='56913A519BA94EB59DAE5BF9A82F5F7D' then ol.qtyordered-coalesce(ol.calloffqty,0) else (ol.qtyordered-coalesce(ol.calloffqty,0))*-1 end as movementqty,o.c_bpartner_id,
       ol.m_attributesetinstance_id
       from c_order o,c_orderline ol,m_product p  
       where o.c_order_id=ol.c_order_id and ol.m_product_id=p.m_product_id  
       and ol.deliverycomplete='N' and p.isstocked='Y' and p.producttype='I' 
       and o.c_doctype_id in ('559A80F2E27742D4B2C476045F5C834F','56913A519BA94EB59DAE5BF9A82F5F7D' ) and o.docstatus='CO'
       and o.m_warehouse_id in (select m_warehouse_id from m_warehouse where isactive='Y' and isblocked='N')
       and (ol.qtyordered-coalesce(ol.calloffqty,0)) > 0 and trunc(now()) between o.contractdate and o.enddate 
union all 
-- Production
select trunc(coalesce(p.enddate,LOCALTIMESTAMP)) as stockdate,
       p.c_projecttask_id as mrp_inoutplanbase_id,
       w.m_locator_id,
       0::numeric AS qtyordered,
       0::numeric AS qtyinsale,
       0::numeric AS qtyreserved,
       p.qty-p.qtyproduced as qtyincomming,
       0::numeric AS qtyorderedframe,
       0::numeric AS qtyinsaleframe,
       p.m_product_id,w.m_warehouse_id, null as c_orderline_id, p.c_projecttask_id,p.ad_org_id,p.ad_client_id,p.updated, p.updatedby, p.created, p.createdby,
       'PROD' as documenttype,
       p.qty-p.qtyproduced as movementqty,null as c_bpartner_id,p.m_attributesetinstance_id
       from c_projecttask p, m_locator w,c_project pr ,m_product m 
        where case when pr.projectcategory='PRO' then p.issuing_locator else (select m_locator_id from m_product where m_product_id=p.m_product_id)  end = w.m_locator_id 
        and p.c_project_id=pr.c_project_id and p.m_product_id=m.m_product_id
        and m.producttype='I' and m.isstocked='Y'
        and pr.projectcategory in ('P','PRO') 
        and pr.projectstatus='OR' 
        and p.iscomplete='N' and p.istaskcancelled='N' 
        and (p.qty-p.qtyproduced)>0 
        and case when pr.projectcategory='PRO' then p.assembly='Y' else 1=1 end
        --and w.m_warehouse_id in (select m_warehouse_id from m_warehouse where isactive='Y' and isblocked='N')
union all 
-- Consumption
select trunc(coalesce(coalesce(case when pr.projectcategory='PRO' then p.startdate else bom.date_plan end,p.startdate),LOCALTIMESTAMP)) as stockdate,
       bom.zspm_projecttaskbom_id as mrp_inoutplanbase_id,
       w.m_locator_id,
       0::numeric AS qtyordered,
       0::numeric AS qtyinsale,
       bom.quantity-bom.qtyreceived as qtyreserved,
       0::numeric AS qtyincomming,
       0::numeric AS qtyorderedframe,
       0::numeric AS qtyinsaleframe,
       bom.m_product_id,w.m_warehouse_id,
       null as c_orderline_id, p.c_projecttask_id,p.ad_org_id,p.ad_client_id,bom.updated, bom.updatedby, p.created, p.createdby,'PCONS' as documenttype,
       (bom.quantity-bom.qtyreceived)*-1 as movementqty,null as c_bpartner_id,null as m_attributesetinstance_id
       from c_projecttask p, m_locator w,zspm_projecttaskbom bom,c_project pr ,m_product m   
        where p.c_project_id=pr.c_project_id 
        and case when pr.projectcategory='PRO' then bom.receiving_locator else bom.m_locator_id end = w.m_locator_id
        and bom.m_product_id=m.m_product_id 
        and bom.c_projecttask_id=p.c_projecttask_id 
        and m.producttype='I' and m.isstocked='Y'
        and pr.projectcategory in ('PRO','P','S','M')
        and pr.projectstatus='OR' 
        and p.iscomplete='N' and p.istaskcancelled='N' 
        and (bom.quantity-bom.qtyreceived)>0
        and bom.isreturnafteruse='N'
        --and w.m_warehouse_id in (select m_warehouse_id from m_warehouse where isactive='Y' and isblocked='N')
;

select zsse_droptable('mrp_inoutplanbase');

create table mrp_inoutplanbase as select 0:: numeric as estimated_stock_qty,* from mrp_inoutplanbase_v;
create index ixolbix on mrp_inoutplanbase(m_product_id,m_warehouse_id,stockdate);

-- Not Avoidable cross-script dependency to productionrun.sql.
-- mrp_inoutplan_v_id deletes zssm_productionrequired_v
-- After Running MRP.sql productionrun.sql Script has to be run!
select zsse_DropView ('mrp_inoutplan_v');
create or replace view mrp_inoutplan_v as
select 
        b.mrp_inoutplanbase_id as mrp_inoutplan_v_id,
        b.ad_org_id,
        b.ad_client_id,
        b.c_bpartner_id,
        b.updated,
        b.updatedby,
        b.created,
        b.createdby,
        'Y'::text as isactive,
        'Y'::text as processing,
        b.estimated_stock_qty, 
        b.documenttype,
        b.c_orderline_id,
        b.c_projecttask_id,
        b.movementqty,
        coalesce(ol.scheddeliverydate,b.stockdate) as planneddate,
        b.m_warehouse_id,
        b.m_product_id,
        b.m_product_id||coalesce(b.m_warehouse_id,'') AS zssi_onhanqty_overview_id,
        p.m_product_category_id,
        p.c_uom_id,
        p.ispurchased,
        p.production,   ol.isapproved,ol.desireddeliverydate,b.m_attributesetinstance_id
from 
        mrp_inoutplanbase b left join c_orderline ol on ol.c_orderline_id=b.c_orderline_id, 
        m_product p 
where
        p.m_product_id=b.m_product_id;
 
select zsse_dropfunction('mrp_getnextincomingDate'); 
CREATE or replace FUNCTION mrp_getnextincomingDate(p_product_id varchar,p_planneddate timestamp,p_estimated_stock_qty numeric,p_attrs varchar)  RETURNS DATE
AS $_$
declare
v_odate date;
v_pdate date;
BEGIN
      select l.scheddeliverydate into v_odate from c_orderline l, c_order o where  o.c_order_id=l.c_order_id and o.DOCSTATUS='CO' and ad_get_docbasetype(o.c_doctype_id)  = 'POO'  
             and coalesce(l.m_attributesetinstance_id,'0')=coalesce(p_attrs,'0')
             and l.m_product_id=p_product_id and l.qtydelivered<l.qtyordered and l.scheddeliverydate > p_planneddate;
      select l.enddate into v_pdate from c_projecttask l,c_project p where l.c_project_id=p.c_project_id and p.projectstatus='OR' and l.assembly='Y' and l.m_product_id=p_product_id 
             and l.qtyproduced<l.qty and l.istaskcancelled='N' and l.iscomplete='N' and l.enddate > p_planneddate
             and coalesce(l.m_attributesetinstance_id,'0')=coalesce(p_attrs,'0');
      return coalesce(v_pdate,v_odate);
END ; $_$ LANGUAGE 'plpgsql';
 
select zsse_DropView ('mrp_criticalitems_v');
create or replace view mrp_criticalitems_v as
select 
        *,mrp_inoutplan_v_id as mrp_criticalitems_v_id,
        mrp_getnextincomingDate(mrp_inoutplan_v.m_product_id,mrp_inoutplan_v.planneddate,mrp_inoutplan_v.estimated_stock_qty,mrp_inoutplan_v.m_attributesetinstance_id) as nextincomingdate,
        mrp_getpurchseleadtime(mrp_inoutplan_v.m_product_id,'N') as stdleadtime,
        mrp_getpurchseleadtime(mrp_inoutplan_v.m_product_id,'Y') as quickestleadtime
from 
        mrp_inoutplan_v
where
       estimated_stock_qty<0;

CREATE OR REPLACE RULE mrp_criticalitems_v_update AS
        ON UPDATE TO mrp_criticalitems_v  DO INSTEAD  
        UPDATE c_orderline SET 
               scheddeliverydate=new.planneddate,
               isapproved=new.isapproved
        WHERE 
                c_orderline_id = new.c_orderline_id;

  
select zsse_dropfunction('mrp_inoutplanupdate');
CREATE or replace FUNCTION mrp_inoutplanupdate()  RETURNS character varying 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
OVERLOAD For sheduled Processes
*****************************************************/

BEGIN
      PERFORM mrp_inoutplanupdate('Y');
      return 'Material Planned';
END ; $_$ LANGUAGE 'plpgsql';

select zsse_droptable('mrp_process_status');
create table mrp_process_status (
    requested                 character(1)                 not null default 'Y'::bpchar,
    running                 character(1)                 not null default 'Y'::bpchar
);
insert into mrp_process_status(requested,running) values ('Y','N');

CREATE or replace FUNCTION mrp_inoutplanupdate(p_isexplicit character varying)  RETURNS void 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/
DECLARE
-- Simple Types
v_message character varying:='Success';
v_Record_ID  character varying;
v_User    character varying;
i numeric;
v_cur RECORD;
v_qty numeric;
v_current varchar:='';
BEGIN
      if coalesce(p_isexplicit,'N')='N' 
      then
        if (select requested from mrp_process_status limit 1)='N' then
            update mrp_process_status set requested='Y';
        end if;
        return;
      end if;
      
     -- Update AD_PInstance On Direct Path Execution
     if coalesce(p_isexplicit,'N') not in ('N','Y','FORCE') then
        PERFORM AD_UPDATE_PINSTANCE(p_isexplicit, NULL, 'Y', NULL, NULL) ;
        update mrp_process_status set requested='Y',running ='N';
     end if;
     if coalesce(p_isexplicit,'N')='FORCE' then
        update mrp_process_status set requested='Y';
     end if;
     if  (select requested from mrp_process_status limit 1)='Y'  then
      update  mrp_process_status set running ='Y';
      delete from mrp_inoutplanbase;
      insert into mrp_inoutplanbase select 0 as estimated_stock_qty,* from mrp_inoutplanbase_v;
      GET DIAGNOSTICS i := ROW_COUNT; 
      v_message:=  i || ' Warenbewegungen geplant.';
      for v_cur in (select sum(b.movementqty) as qty, b.m_product_id,b.m_warehouse_id,b.stockdate,coalesce(b.m_attributesetinstance_id,'0') as m_attributesetinstance_id
                           from mrp_inoutplanbase b 
                           group by b.m_product_id,b.m_warehouse_id,coalesce(b.m_attributesetinstance_id,'0'),b.stockdate
                           order by b.m_product_id,b.m_warehouse_id,coalesce(b.m_attributesetinstance_id,'0'),b.stockdate)
      LOOP
         if v_current!=to_char(v_cur.m_product_id||v_cur.m_warehouse_id||v_cur.m_attributesetinstance_id) then
            -- Current Onhand QTY's
            select sum(s.qtyonhand) into v_qty
            from m_storage_detail s 
            where s.m_locator_id in (select m_locator_id from m_locator where m_warehouse_id =v_cur.m_warehouse_id and isactive='Y') 
            and s.m_product_id=  v_cur.m_product_id
            and s.m_attributesetinstance_id=v_cur.m_attributesetinstance_id;
            if v_qty is null then
                v_qty:=0;
            end if;
            v_current:=v_cur.m_product_id||v_cur.m_warehouse_id||v_cur.m_attributesetinstance_id;
         end if;
         v_qty:=v_qty+v_cur.qty;
        --v_qty:= mrp_estimated_stockqty(v_cur.m_product_id,v_cur.m_warehouse_id,v_cur.stockdate);
        update mrp_inoutplanbase b set estimated_stock_qty = v_qty where m_product_id=v_cur.m_product_id and m_warehouse_id=v_cur.m_warehouse_id and stockdate=v_cur.stockdate
               and coalesce(m_attributesetinstance_id,'0')= v_cur.m_attributesetinstance_id;
      END LOOP;
      update  mrp_process_status set running ='N',requested='N';
      if coalesce(p_isexplicit,'N') not in ('N','Y','FORCE') then
        PERFORM AD_UPDATE_PINSTANCE(p_isexplicit, NULL, 'N', 1, v_message);
      end if;
      return;
    end if;
EXCEPTION
    WHEN OTHERS then
       v_message:= '@ERROR=' || SQLERRM;   
       if coalesce(p_isexplicit,'N') not in ('N','Y','FORCE') then
            PERFORM AD_UPDATE_PINSTANCE(p_isexplicit, NULL, 'N', 0, v_message);
       else 
            raise exception '%',v_message;
       end if;
       return;
END ; $_$ LANGUAGE 'plpgsql';

select mrp_inoutplanupdate('FORCE');

CREATE or replace FUNCTION mrp_updateplanline(p_projecttask_id varchar,p_orderline_id varchar)  RETURNS void 
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/
DECLARE
  
BEGIN
      if  p_projecttask_id is not null then
           delete from mrp_inoutplanbase where c_projecttask_id=p_projecttask_id;
           insert into mrp_inoutplanbase select get_uuid()  as mrp_inoutplanbase_id,* from mrp_inoutplanbase_v where c_projecttask_id=p_projecttask_id;
      end if;
      if  p_orderline_id is not null then
           delete from mrp_inoutplanbase where c_orderline_id=p_orderline_id;
           insert into mrp_inoutplanbase select get_uuid()  as mrp_inoutplanbase_id,* from mrp_inoutplanbase_v where c_orderline_id=p_orderline_id;
      end if;
END ; $_$ LANGUAGE 'plpgsql';
  
CREATE OR REPLACE FUNCTION mrp_order_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
  v_cur record;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'UPDATE' THEN 
      -- fire MRP-Trigger only on change of Document status.
      -- fire on Orders 
      -- Do not Fire on Subscription Intervals BUT
      -- Fire on Subscription Orders
      if old.docstatus!=new.docstatus and ((ad_get_docbasetype(new.c_DocType_ID) in ('POO','SOO') 
         and new.c_DocType_ID not in ('6C8EA6FFBB2B4ACBA0542BA4F833C499','52C79B0ABF04413DA133B71A3C6157A9')) or new.c_DocType_ID in ('ABE2033C7A74499A9750346A83DE3307','EAF34F4237D0488F923F218234509E24')) then
        /*
        for v_cur in (select c_orderline_id from c_orderline where c_order_id=new.c_order_id)
        LOOP
            PERFORM  mrp_updateplanline(null,v_cur.c_orderline_id);
        END LOOP;
        */
        
        PERFORM mrp_inoutplanupdate(null);
      end if;
   END IF;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_droptrigger('mrp_order_trg','c_order');

CREATE TRIGGER mrp_order_trg
  AFTER UPDATE
  ON c_order
  FOR EACH ROW
  EXECUTE PROCEDURE mrp_order_trg();

CREATE OR REPLACE FUNCTION mrp_orderline_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
  v_cur record;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'UPDATE' THEN 
      -- fire MRP-Trigger only on change of scheduled delivery date.
      if (coalesce(old.scheddeliverydate,new.created)!=coalesce(new.scheddeliverydate,new.created) 
          or old.deliverycomplete!=new.deliverycomplete or old.DirectShip!=new.directship) and 
         (select docstatus from c_order where c_order_id=new.c_order_id)='CO' then
            --PERFORM  mrp_updateplanline(null,new.c_orderline_id);
            PERFORM mrp_inoutplanupdate(null);
      end if;
   END IF;
   /*
   IF TG_OP = 'DELETE' then 
         --PERFORM  mrp_updateplanline(null,old.c_orderline_id);
         PERFORM mrp_inoutplanupdate(null);
   END IF;
   */
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_droptrigger('mrp_orderline_trg','c_orderline');

CREATE TRIGGER mrp_orderline_trg
  AFTER UPDATE OR DELETE
  ON c_orderline
  FOR EACH ROW
  EXECUTE PROCEDURE mrp_orderline_trg();


CREATE OR REPLACE FUNCTION mrp_projecttask_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'DELETE' THEN 
       PERFORM mrp_inoutplanupdate(null);
      --PERFORM  mrp_updateplanline(old.c_projecttask_id,null);
   ELSE
       if TG_OP = 'UPDATE' THEN 
           if coalesce(new.startdate,now())!= coalesce(old.startdate,now()) or coalesce(new.enddate,now())!= coalesce(old.enddate,now()) or coalesce(new.m_product_id,'')!= coalesce(old.m_product_id,'') or coalesce(old.qty,0)!= coalesce(new.qty,0) or old.qtyproduced!=new.qtyproduced 
           or old.istaskcancelled!=new.istaskcancelled or new.iscomplete !=old.iscomplete then
            PERFORM mrp_inoutplanupdate(null);
           end if;
       else
           PERFORM mrp_inoutplanupdate(null);
       end if;
      --PERFORM  mrp_updateplanline(new.c_projecttask_id,null);
   END IF;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_droptrigger('mrp_projecttaskUPD_trg','c_projecttask');
CREATE TRIGGER mrp_projecttaskUPD_trg
  AFTER UPDATE 
  ON c_projecttask
  FOR EACH ROW
  EXECUTE PROCEDURE mrp_projecttask_trg();
  
select zsse_droptrigger('mrp_projecttask_trg','c_projecttask');
CREATE TRIGGER mrp_projecttask_trg
  AFTER INSERT OR DELETE
  ON c_projecttask
  FOR EACH STATEMENT
  EXECUTE PROCEDURE mrp_projecttask_trg();

  
CREATE OR REPLACE FUNCTION mrp_projecttaskbom_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/

BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 
   IF TG_OP = 'DELETE' THEN 
       PERFORM mrp_inoutplanupdate(null);
      --PERFORM  mrp_updateplanline(old.c_projecttask_id,null);
   ELSE
       if TG_OP = 'UPDATE' THEN 
           if new.m_product_id!= old.m_product_id or old.quantity!= new.quantity  or 
              coalesce(old.m_locator_id,'')!=coalesce(new.m_locator_id,'') or
              coalesce(old.issuing_locator,'')!=coalesce(new.issuing_locator,'') or
              coalesce(old.receiving_locator,'')!=coalesce(new.receiving_locator,'') or
              old.date_plan!=new.date_plan 
           then
            PERFORM mrp_inoutplanupdate(null);
           end if;
       else
           PERFORM mrp_inoutplanupdate(null);
       end if;
      --PERFORM  mrp_updateplanline(new.c_projecttask_id,null);
   END IF;
   IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
    
select zsse_droptrigger('mrp_projecttask_trg','zspm_projecttaskbom');

CREATE TRIGGER mrp_projecttask_trg
  AFTER INSERT  OR DELETE
  ON zspm_projecttaskbom
  FOR EACH STATEMENT
  EXECUTE PROCEDURE mrp_projecttaskbom_trg();  
  
select zsse_droptrigger('mrp_projecttaskUPD_trg','zspm_projecttaskbom');

CREATE TRIGGER mrp_projecttaskUPD_trg
  AFTER  UPDATE 
  ON zspm_projecttaskbom
  FOR EACH ROW
  EXECUTE PROCEDURE mrp_projecttaskbom_trg();  
  
  
  
  
select zsse_dropfunction('mrp_getsheddeliverydate4vendorProduct');  
CREATE or replace FUNCTION mrp_getsheddeliverydate4vendorProduct(p_vendor_id varchar,p_product_id varchar,p_org_id varchar,p_uom_id varchar,p_MProductPOID varchar)  RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

In Purchase all workdays are calculated with 8 workhours.

One day is added by default to mean lead time

*****************************************************/
DECLARE
  v_workdays numeric;
  v_cur record;
  v_workdayscounter numeric;
  v_calendarcounter numeric;
  v_poid varchar;
BEGIN
    if p_vendor_id is null then
        -- select the Best vendor
        SELECT po.M_PRODUCT_PO_id
                INTO v_poid
                FROM M_PRODUCT_PO po
                WHERE po.m_product_id=p_product_id and PO.iscurrentvendor='Y' 
                ORDER BY COALESCE(po.qualityrating,0) desc  LIMIT 1;
    else
        SELECT po.M_PRODUCT_PO_id
                INTO v_poid
                FROM M_PRODUCT_PO po
                WHERE po.m_product_id=p_product_id and PO.iscurrentvendor='Y' 
                and po.c_bpartner_id=p_vendor_id and
                case when p_uom_id is not null then c_uom_id=p_uom_id else c_uom_id is null end and
                case when p_MProductPOID is not null then po.m_product_po_Id=p_MProductPOID else m_manufacturer_id is null and  manufacturernumber is null end
                ORDER BY COALESCE(po.qualityrating,0) desc  LIMIT 1;
    end if;
    select coalesce(deliverytime_promised,0) into  v_workdays from m_product_po where m_product_po_id=v_poid;       
    if v_workdays is not null then
        return to_char(trunc(now())+zssi_NumofWorkdays2CaleandarDaysFromGivenDate(v_workdays,p_org_id,trunc(now())),'DD-MM-YYYY');
    else
        return '';
    end if;
END ; $_$ LANGUAGE 'plpgsql';



  
  
  
CREATE OR REPLACE FUNCTION mrp_orderlineupdatedeliverydate(p_pinstance_id character varying)
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
v_sheddeliverydate timestamp;
v_product varchar;
Cur_Parameter record;
v_result numeric:=1;
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
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('scheddeliverydate') ) THEN
            v_sheddeliverydate := Cur_Parameter.p_date;
          END IF;
        END LOOP; -- Get Parameter
        select p.m_product_id into v_product from c_orderline ol,m_product p where p.m_product_id=ol.m_product_id and p.production='Y' and ol.c_orderline_id=v_Record_ID;
        if (select count(*) from mrp_criticalitems_v where m_product_id=v_product and c_orderline_id!=v_Record_ID and documenttype='SOO')>0 then
            v_Message:='Die Ermittlung des schnellsten Lieferdatums ist unter Vorbehalt. Es gibt noch andere Aufträge, die diesen Artikel beinhalten, die noch nicht für die Produktion eingeplant sind. Bitte Produktionslauf durchführen.';
            v_result:=2;
        end if;
        RAISE NOTICE '%','Updating pinstance - Processing ' || p_pinstance_ID;
    end if;
    update c_orderline set scheddeliverydate=v_sheddeliverydate where c_orderline_id=v_Record_ID;
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_result , v_Message) ;
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
