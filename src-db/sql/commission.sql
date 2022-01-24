CREATE OR REPLACE FUNCTION c_commission_processrun (p_pinstance_id varchar) RETURNS void 
LANGUAGE plpgsql AS $body$
 DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/

   v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
   v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
   -- Parameter
   --TYPE RECORD IS REFCURSOR;
   Cur_Parameter RECORD;
   v_cur RECORD;
   
   --
   --
   v_EndDate TIMESTAMP;
   v_BeginDate TIMESTAMP;
   v_org VARCHAR;
   v_processId VARCHAR;
   v_runId VARCHAR; 
   commissionPid varchar:='123'; -- c_commission_process (To be started)
   invoicePid varchar:='166'; -- C_CommissionRun_Process (To be started)
   v_i numeric:=0;
  BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL); -- c_commission_processrun
    if (select count(*) from  AD_Process_Run r ,ad_process_request rq WHERE r.ad_process_request_id=rq.ad_process_request_id 
               and rq.AD_Process_ID ='5DBF91A35D1E4100A0FDE7B96DB523C5' and r.Status='PRC')>1 then
        RAISE EXCEPTION '%' ,'@ProcessExecutes@';
    end if;
  BEGIN --BODY
    -- Get Parameters
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
      IF(Cur_Parameter.ParameterName='EndDate') THEN
        v_EndDate:=Cur_Parameter.P_Date;
      ELSIF (Cur_Parameter.ParameterName='BeginDate') THEN
        v_BeginDate:=Cur_Parameter.P_Date;
      ELSIF (Cur_Parameter.ParameterName='AdOrgId') THEN
        v_org:=Cur_Parameter.P_String;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName;
      END IF;
    END LOOP; -- Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID;
    /**
    * Select all Commissions
    */
    for v_cur in (select c.C_Commission_ID from c_commission c,c_bpartner b where b.c_bpartner_id=c.c_bpartner_id and c.isactive='Y' and b.isactive='Y'  and c.ad_org_id=v_org)
    LOOP
        select get_uuid() into v_processId;
        -- Perform c_commission_process 
        insert into AD_PINSTANCE (AD_PINSTANCE_ID, AD_PROCESS_ID, RECORD_ID, ISPROCESSING, AD_USER_ID, RESULT, ERRORMSG, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY)
        values(v_processId,commissionPid,v_cur.C_Commission_ID,'N','0',null,null,'C726FEC915A54A0995C568555DA5BB3C','0','0','0');
        insert into AD_PINSTANCE_PARA(ad_pinstance_para_id, ad_pinstance_id, seqno, parametername , p_string, p_date , AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY)
            select get_uuid(),v_processId,seqno, parametername , p_string, p_date , AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY 
            from AD_PInstance_Para where AD_PINSTANCE_ID=p_PInstance_ID and parametername!='AdOrgId';
        PERFORM c_commission_process (v_processId);
        if (select coalesce(RESULT,0) from ad_pinstance where ad_pinstance_id= v_processId)!=1 then
            select coalesce(errormsg,'Error in c_commission_process') into v_Message from ad_pinstance where ad_pinstance_id= v_processId;
            PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message);
            RETURN;
        end if;
    END LOOP;
    for v_cur in (select C_CommissionRun_ID from c_commissionRun where c_invoice_id is null and ad_org_id=v_org)
    LOOP
        -- Perform C_CommissionRun_Process
        select get_uuid() into v_processId;
        --RAISE NOTICE '%','MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM-'||v_cur.C_Commission_ID||coalesce(v_runId,'-NIX!');
        insert into AD_PINSTANCE (AD_PINSTANCE_ID, AD_PROCESS_ID, RECORD_ID, ISPROCESSING, AD_USER_ID, RESULT, ERRORMSG, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY)
        values(v_processId,invoicePid,v_cur.C_CommissionRun_ID,'N','0',null,null,'C726FEC915A54A0995C568555DA5BB3C','0','0','0');
        insert into AD_PINSTANCE_PARA(ad_pinstance_para_id, ad_pinstance_id, seqno, parametername , p_string, p_date , AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY)
            select get_uuid(),v_processId,seqno, parametername , p_string, p_date , AD_CLIENT_ID, AD_ORG_ID, CREATEDBY,UPDATEDBY 
            from AD_PInstance_Para where AD_PINSTANCE_ID=p_PInstance_ID and parametername!='AdOrgId';
        PERFORM c_commissionrun_process(v_processId);
        if (select coalesce(RESULT,0) from ad_pinstance where ad_pinstance_id= v_processId)!=1 then
            select coalesce(errormsg,'Error in Commission Invoice Process') into v_Message from ad_pinstance where ad_pinstance_id= v_processId;
            PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message);
            RETURN;
        end if;
        v_i:=v_i+1;
        v_Message:=v_i||' Provisionsabrechnungen erstellt.';
    END LOOP;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message);
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_Message:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_Message;
  -- ROLLBACK;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_Message);
  RETURN;
END; $body$;





CREATE OR REPLACE FUNCTION c_commission_process (p_pinstance_id varchar) RETURNS void 
LANGUAGE plpgsql AS $body$
 DECLARE
/***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Martin Hinrichs, 12/2011, info@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Zimmermann-Software
*
****************************************************************************************************************************************************/
  -- Logistice
   v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
   v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
   v_Record_ID VARCHAR(32); --OBTG:VARCHAR2--
   -- Parameter
   --TYPE RECORD IS REFCURSOR;
   Cur_Parameter RECORD;
  
   --
   v_AD_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
   v_AD_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
   v_Name VARCHAR; --OBTG:VARCHAR2--
   v_Currency VARCHAR(10); --OBTG:VARCHAR2--
   v_FrequencyType VARCHAR(60);
   v_DocBasisType VARCHAR(60);
   v_ListDetails VARCHAR(60);
   v_SalesRep_ID VARCHAR(32); --OBTG:VARCHAR2--
   --
   v_EndDate TIMESTAMP;
   v_BeginDate TIMESTAMP;
   v_C_CommissionRun_ID VARCHAR(32); --OBTG:VARCHAR2--
   v_NextNo VARCHAR(32); --OBTG:VARCHAR2--
   v_DocumentNo VARCHAR(40);
   v_count numeric;
   v_C_CommissionAmt_ID VARCHAR(32);
   CUR_CLine RECORD;
   TYPE_Ref REFCURSOR;
   v_rc TYPE_REF%TYPE;
      --
   v_Cmd VARCHAR:=''; --OBTG:VARCHAR2--
   v_C_Currency_ID C_CommissionDetail.C_Currency_ID%TYPE;
   v_Amt C_CommissionDetail.ActualAmt%TYPE;
   v_Qty C_CommissionDetail.ActualQty%TYPE;
   v_C_OrderLine_ID VARCHAR(32); --OBTG:VARCHAR2--
   v_C_InvoiceLine_ID VARCHAR(32); --OBTG:VARCHAR2--
   v_Reference C_CommissionDetail.Reference%TYPE;
   v_Info C_CommissionDetail.Info%TYPE;
   v_additionalcommissionpercent numeric;
   v_agencyfee numeric;
   v_agencyfeeinstructure varchar;
   v_linecount numeric:=0;
   v_org2 varchar;
  BEGIN
    --  Update AD_PInstance
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL);
  BEGIN --BODY
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID,i.ad_org_id,
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
      v_org2:=Cur_Parameter.ad_org_ID;
      IF(Cur_Parameter.ParameterName='EndDate') THEN
        v_EndDate:=Cur_Parameter.P_Date;
      ELSIF (Cur_Parameter.ParameterName='BeginDate') THEN
        v_BeginDate:=Cur_Parameter.P_Date;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName;
      END IF;
    END LOOP; -- Get Parameter
    /**
    * Create Header + Determine TIMESTAMP Range
    */
    v_ResultStr:='ReadingRecord';
    SELECT AD_Client_ID,
      AD_Org_ID,
      Name,
      FrequencyType,
      DocBasisType,
      ListDetails,
      C_BPartner_ID
    INTO v_AD_Client_ID,
      v_AD_Org_ID,
      v_Name,
      v_FrequencyType,
      v_DocBasisType,
      v_ListDetails,
      v_SalesRep_ID
    FROM C_Commission
    WHERE C_Commission_ID=v_Record_ID;
    --
    SELECT ISO_Code
    INTO v_Currency
    FROM C_Currency cur,
      C_Commission com
    WHERE cur.C_Currency_ID=com.C_Currency_ID
      AND com.C_Commission_ID=v_Record_ID;
    --
    v_ResultStr:='CalculatingHeader';
    if v_AD_Org_ID='0' then
        v_AD_Org_ID:=v_org2;
        if v_AD_Org_ID='0' then
            raise exception '%','@YouNeedToBeLoggedInWithOrganization@';
        end if;
    end if;
    if (select iscommission from ad_user where c_bpartner_id=v_SalesRep_ID)='N' then
        PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, 'Commission on User is not approved-No Commision created');
        RETURN;
    end if;
    
    select C_CommissionRun_ID into v_C_CommissionRun_ID from C_CommissionRun where c_invoice_id is null and C_Commission_ID=v_Record_ID;
    if v_C_CommissionRun_ID is null then
        --
        -- Name 01-Jan-2000 - 31-Jan-2001 - USD
        v_Name:=v_Name ||' - ' ||(select name from c_bpartner where c_bpartner_id=v_SalesRep_ID)||' - '|| coalesce(TO_CHAR(v_EndDate),to_char(trunc(now()))) || ' - ' || v_Currency;
        SELECT * INTO  v_C_CommissionRun_ID FROM AD_Sequence_Next('C_CommissionRun', v_AD_Client_ID);
        SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('DocumentNo_C_CommissionRun', v_AD_Org_ID, 'Y');
        RAISE NOTICE '%','Create: ' || v_DocumentNo || ' - ' || v_Name;
        v_ResultStr:='InsertingHeader';
        INSERT
        INTO C_CommissionRun
        (
            C_CommissionRun_ID, C_Commission_ID, AD_Client_ID, AD_Org_ID,
            IsActive, Created, CreatedBy, Updated,
            UpdatedBy, DocumentNo, Description, StartDate,
            GrandTotal, Processing, Processed
        )
        VALUES
        (
            v_C_CommissionRun_ID, v_Record_ID, v_AD_Client_ID, v_AD_Org_ID,
            'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
            '0', v_DocumentNo, v_Name, TO_DATE(NOW()),
            0, 'N', 'N'
        )
        ;
    end if;
    --
    v_count:=0;
    v_ResultStr:='Update Record';
    UPDATE C_Commission
      SET DateLastRun=TO_DATE(NOW())
    WHERE C_Commission_ID=v_Record_ID;
    /**
    * Calculate Lines
    */
      FOR CUR_CLine IN
        (   SELECT c.ad_org_id as Org_ID,b.m_product_category_id , b.m_product_id , b.c_bp_group_id , b.c_bpartner_id , b.c_salesregion_id,b.C_CommissionLine_id,
            b.highlevelcategory,b.commissionorders from (
            select m_product_category_id , m_product_id , c_bp_group_id , c_bpartner_id , c_salesregion_id,max(coalesce(salesvolumefrom,0)) as volume,
            c_commission_id,commissionorders
            FROM C_CommissionLine  WHERE C_Commission_ID=v_Record_ID AND IsActive='Y' AND isshareofturnover='N' AND
            ConvertedTurnover>=coalesce(salesvolumefrom,0) 
            group by c_commission_id,m_product_category_id , m_product_id , c_bp_group_id , c_bpartner_id , c_salesregion_id,commissionorders) a,C_CommissionLine b, c_commission c
            where a.c_commission_id=b.c_commission_id and a.c_commission_id=c.c_commission_id
                  and coalesce(a.m_product_category_id,'')=coalesce(b.m_product_category_id,'') 
                  and coalesce(a.m_product_id,'') =coalesce(b.m_product_id ,'') 
                  and coalesce(a.c_bp_group_id,'') =coalesce(b.c_bp_group_id,'') 
                  and coalesce(a.c_bpartner_id,'') =coalesce(b.c_bpartner_id ,'') 
                  and coalesce(a.c_salesregion_id,'') =coalesce(b.c_salesregion_id ,'') 
                  and coalesce(b.salesvolumefrom,0)=a.volume
        )
      LOOP
        
          
        -- DBMS_OUTPUT.PUT_LINE('- ' || CUR_CLine.Line);
        v_ResultStr:='AssemblingDynSQL';
        -- Receipt Basis
        -- Only Subscriptioon Orders have agencyfee (on the first line), but at least one interval must be paid
        IF(v_DocBasisType='R') THEN
          v_Cmd:='SELECT h.C_Currency_ID, case when ad_get_docbasetype(h.c_doctype_id)= ''SOO'' then '
            || ' case when ast.ca_assetsstocked_id is null then case when (select IsTaxIncluded from m_pricelist where m_pricelist_id=h.m_pricelist_id)=''N'' then l.linenetamt else coalesce(l.linegrossamt,0) end '
            || ' else coalesce(ast.amt,0)+coalesce(ast.chargeamt,0)+coalesce(ast.stockcharge,0) end else 0 end  as LineNetAmt,'
            || 'ast.qty, h.additionalcommissionpercent, '
            || 'case when h.c_doctype_id=''ABE2033C7A74499A9750346A83DE3307'' then coalesce(h.agencyfee,0)  else 0 end as agencyfee,'
            || 'h.agencyfeeinstructure,'
            || 'l.C_OrderLine_ID, NULL, h.DocumentNo, substr(COALESCE(ast.description,l.Description),1,60) '
            || ' FROM C_Order h, C_OrderLine l left join  ca_assetsstocked ast on ast.c_orderline_id=l.c_orderline_id  '
            || '                and lower(ast.description) not like ''%rabatt%''  and lower(ast.description) not like ''%anteil%'''
            || ' WHERE h.C_Order_ID = l.C_Order_ID '
            || ' AND h.DocStatus IN (''CL'',''CO'')'
            || ' AND (ad_get_docbasetype(h.c_doctype_id)= ''SOO'' OR h.c_doctype_id=''ABE2033C7A74499A9750346A83DE3307'')'
            || ' and h.totalpaid>0 '
            || ' AND h.AD_Client_ID = '':1'''
            || ' AND h.transactiondate is not null '
            || ' AND h.transactiondate >= to_date('''||to_char(coalesce(v_BeginDate,now()-10000))||''')'
            || ' AND h.transactiondate <= to_date('':3'')'
            || ' AND case when h.c_doctype_id=''6C8EA6FFBB2B4ACBA0542BA4F833C499'' then 1=1 else h.iscommissionapproved = ''Y'' end' 
            || ' AND h.iscommissionrejected= ''N'''
            || ' AND  case when h.c_doctype_id=''ABE2033C7A74499A9750346A83DE3307'' then l.M_Product_ID=(select m_product_id  from m_product where value=''VM'') else EXISTS (select 0 from C_invoiceline il where il.c_orderline_id=l.c_orderline_id)  end'
            || ' AND NOT EXISTS (select 0 from C_CommissionDetail d,c_commissionamt a,C_CommissionRun r '
            || '                 where d.c_orderline_id=l.c_orderline_id and a.c_commissionamt_id=d.c_commissionamt_id and a.c_commissionrun_id=r.C_CommissionRun_id '
            || '                 and case when h.c_doctype_id=''ABE2033C7A74499A9750346A83DE3307'' then 1=1 else '
            || '                     (r.C_CommissionRun_id!='''||v_C_CommissionRun_ID||''' or a.c_commissionline_id='''||CUR_CLine.C_CommissionLine_id||''') end)';
          -- Invoice Basis
        ELSIF(v_DocBasisType='I') THEN
            v_Cmd:='SELECT h.C_Currency_ID, l.LineNetAmt, l.QtyInvoiced, 0 as additionalcommissionpercent, 0 as agencyfee,''N'' as agencyfeeinstructure,'
            || 'NULL, l.C_InvoiceLine_ID, h.DocumentNo, substr(COALESCE(prd.Name,l.Description),1,60) '
            || 'FROM C_Invoice h, C_InvoiceLine l LEFT JOIN M_Product prd ON l.M_Product_ID = prd.M_Product_ID '
            || 'WHERE h.C_Invoice_ID = l.C_Invoice_ID'
            || ' AND h.DocStatus IN (''CL'',''CO'')'
            || ' AND h.ISSOTRX = ''Y'''
            || ' AND h.AD_Client_ID = '':1'''
            || ' AND h.DateInvoiced >= to_date('''||to_char(coalesce(v_BeginDate,now()-10000))||''')'
            || ' AND h.DateInvoiced <= to_date('':3'')'
            || ' AND NOT EXISTS (select 0 from C_CommissionDetail d,c_commissionamt a,C_CommissionRun r '
            || '                 where d.c_orderline_id=l.c_orderline_id and a.c_commissionamt_id=d.c_commissionamt_id and a.c_commissionrun_id=r.C_CommissionRun_id '
            || '                 and case when h.c_doctype_id=''ABE2033C7A74499A9750346A83DE3307'' then 1=1 else '
            || '                     (r.C_CommissionRun_id!='''||v_C_CommissionRun_ID||''' or a.c_commissionline_id='''||CUR_CLine.C_CommissionLine_id||''') end)';
          -- Order Basis (O)
        ELSE
            v_Cmd:='SELECT h.C_Currency_ID, case when ad_get_docbasetype(h.c_doctype_id)= ''SOO'' then case when (select IsTaxIncluded from m_pricelist where m_pricelist_id=h.m_pricelist_id)=''N'' then l.linenetamt else coalesce(l.linegrossamt,0) end else 0 end as LineNetAmt,'
            || 'l.QtyOrdered, h.additionalcommissionpercent, coalesce(h.agencyfee,0) as agencyfee,h.agencyfeeinstructure,'
            || 'l.C_OrderLine_ID, NULL, h.DocumentNo, substr(COALESCE(prd.Name,l.Description),1,60) '
            || 'FROM C_Order h, C_OrderLine l LEFT JOIN M_Product prd ON l.M_Product_ID = prd.M_Product_ID '
            || 'WHERE h.C_Order_ID = l.C_Order_ID'
            || ' AND h.DocStatus IN (''CL'',''CO'')'
            || ' AND ad_get_docbasetype(h.c_doctype_id)= ''SOO'' '
            || ' AND h.AD_Client_ID = '':1'''
            || ' AND h.DateOrdered >= to_date('''||to_char(coalesce(v_BeginDate,now()-10000))||''')'
            || ' AND h.DateOrdered <= to_date('':3'')'
            || ' AND h.iscommissionapproved = ''Y'''
            || ' AND h.iscommissionrejected= ''N'''
            || ' AND NOT EXISTS (select 0 from C_CommissionDetail d,c_commissionamt a,C_CommissionRun r '
            || '                 where d.c_orderline_id=l.c_orderline_id and a.c_commissionamt_id=d.c_commissionamt_id and a.c_commissionrun_id=r.C_CommissionRun_id '
            || '                 and case when h.c_doctype_id=''ABE2033C7A74499A9750346A83DE3307'' then 1=1 else '
            || '                     (r.C_CommissionRun_id!='''||v_C_CommissionRun_ID||''' or a.c_commissionline_id='''||CUR_CLine.C_CommissionLine_id||''') end)';
        END IF;
        -- CommissionOrders/Invoices
        IF(CUR_CLine.CommissionOrders='Y') THEN
          v_Cmd:=v_Cmd || ' AND h.SalesRep_ID = (SELECT AD_User_ID FROM AD_User WHERE C_BPartner_ID=''' || v_SalesRep_ID || ''')';
        END IF;
        -- Organization
        IF(CUR_CLine.Org_ID!='0') THEN
          v_Cmd:=v_Cmd || ' AND h.AD_Org_ID=''' || CUR_CLine.Org_ID || '''';
        END IF;
        -- BPartner
        IF(CUR_CLine.C_BPartner_ID IS NOT NULL) THEN
          v_Cmd:=v_Cmd || ' AND h.C_BPartner_ID=''' || CUR_CLine.C_BPartner_ID || '''';
        END IF;
        -- BPartner Group
        IF(CUR_CLine.C_BP_Group_ID IS NOT NULL) THEN
          v_Cmd:=v_Cmd || ' AND h.C_BPartner_ID IN'  || '(SELECT C_BPartner_ID FROM C_BPartner WHERE C_BP_Group_ID=''' || CUR_CLine.C_BP_Group_ID || ''')';
        END IF;
        -- Sales Region
        IF(CUR_CLine.C_SalesRegion_ID IS NOT NULL) THEN
          --v_Cmd:=v_Cmd || ' AND h.C_BPartner_Location_ID IN '  || '(SELECT C_BPartner_Location_ID FROM C_BPartner_Location WHERE C_SalesRegion_ID=''' || CUR_CLine.C_SalesRegion_ID || ''')';
          v_Cmd:=v_Cmd || ' AND h.C_SalesRegion_ID=''' ||CUR_CLine.C_SalesRegion_ID ||'''';
        END IF;
        -- Product
        IF(CUR_CLine.M_Product_ID IS NOT NULL) THEN
          if v_DocBasisType='R' then
            v_Cmd:=v_Cmd || ' AND case when h.c_doctype_id!=''ABE2033C7A74499A9750346A83DE3307'' then coalesce(ast.m_product_id,l.M_Product_ID)=''' || CUR_CLine.M_Product_ID || ''' else 1=1 end ';
          else
            v_Cmd:=v_Cmd || ' AND case when h.c_doctype_id!=''ABE2033C7A74499A9750346A83DE3307'' then l.M_Product_ID=''' || CUR_CLine.M_Product_ID || ''' else 1=1 end ';
          end if;
        END IF;
        -- Product Category
        IF(CUR_CLine.M_Product_Category_ID IS NOT NULL) THEN
          if v_DocBasisType='R' then
            v_Cmd:=v_Cmd || ' AND case when h.c_doctype_id!=''ABE2033C7A74499A9750346A83DE3307'' then  coalesce(ast.m_product_id,l.M_Product_ID) IN '  || '(SELECT M_Product_ID FROM M_Product WHERE M_Product_Category_ID=''' || CUR_CLine.M_Product_Category_ID ||''') else 1=1 end ';
          else
            v_Cmd:=v_Cmd || ' AND case when h.c_doctype_id!=''ABE2033C7A74499A9750346A83DE3307'' then  l.M_Product_ID IN '  || '(SELECT M_Product_ID FROM M_Product WHERE M_Product_Category_ID=''' || CUR_CLine.M_Product_Category_ID ||''') else 1=1 end ';
          end if;
        END IF;
        -- High-Level Product Category
        IF(CUR_CLine.highlevelcategory IS NOT NULL) THEN
          if v_DocBasisType!='R' then
            v_Cmd:=v_Cmd || ' AND case when h.c_doctype_id!=''ABE2033C7A74499A9750346A83DE3307'' then  l.M_Product_ID IN '  || '(SELECT M_Product_ID FROM M_Product WHERE M_Product_Category_ID in (select m_product_category_id from m_product_category where value like ''' || CUR_CLine.highlevelcategory ||'%'')) else 1=1 end ';
          end if;
        END IF;
        -- Grouping
        IF(v_ListDetails<>'Y') THEN
          v_Cmd:=v_Cmd || ' GROUP BY h.C_Currency_ID';
        END IF;
        --
        -- DBMS_OUTPUT.PUT_LINE('- ' || CUR_CLine.Line || ' SQL=' || SUBSTR(v_Cmd, 1, 200));
        -- DBMS_OUTPUT.PUT_LINE(SUBSTR(v_Cmd, 200,200));
        -- DBMS_OUTPUT.PUT_LINE(SUBSTR(v_Cmd, 400));
        --
        v_ResultStr:='OpenDynCursor';
        SELECT REPLACE(REPLACE(v_Cmd, ':1', to_char(v_AD_Client_ID)), ':3', to_char(coalesce(v_EndDate,trunc(now()+10000)))) INTO v_Cmd FROM DUAL;
       -- raise notice '%',v_cmd;
       -- raise exception '%','RAUS!'||v_cmd;
        v_C_CommissionAmt_ID:=null;
        OPEN  v_rc  FOR EXECUTE  v_Cmd;
        LOOP
          v_ResultStr:='FetchingData';
          FETCH v_rc INTO v_C_Currency_ID,
          v_Amt,
          v_Qty,
          v_additionalcommissionpercent,v_agencyfee,v_agencyfeeinstructure,
          v_C_OrderLine_ID,
          v_C_InvoiceLine_ID,
          v_Reference,
          v_Info;
          EXIT WHEN  NOT FOUND; --OBTG:v_rc--
          --
          v_ResultStr:='InsertingAmt';
          if (select count(*) from C_CommissionAmt where C_CommissionAmt_id=coalesce(v_C_CommissionAmt_ID,''))=0 then
                -- For every Commission Line create empty Amt line (updated by Detail)
                v_C_CommissionAmt_ID:=get_uuid();
                INSERT
                INTO C_CommissionAmt
                (
                    C_CommissionAmt_ID, C_CommissionRun_ID, C_CommissionLine_ID, AD_Client_ID,
                    AD_Org_ID, IsActive, Created, CreatedBy, Updated,
                    UpdatedBy, ConvertedAmt, ActualQty, CommissionAmt
                )
                VALUES
                (
                    v_C_CommissionAmt_ID, v_C_CommissionRun_ID, CUR_CLine.C_CommissionLine_ID, v_AD_Client_ID,
                    v_AD_Org_ID, 'Y', TO_DATE(NOW()), '0',
                    TO_DATE(NOW()), '0', 0, 0,
                    0
                ); -- Calculation done by Trigger
          end if;
          v_ResultStr:='InsertingDetail';
          SELECT * INTO  v_NextNo FROM AD_Sequence_Next('C_CommissionDetail', v_AD_Client_ID);
          INSERT
          INTO C_CommissionDetail
            (
              C_CommissionDetail_ID, C_CommissionAmt_ID, AD_Client_ID, AD_Org_ID,
              IsActive, Created, CreatedBy, Updated,
              UpdatedBy, C_Currency_ID, ActualAmt, ConvertedAmt,
              ActualQty,
              C_OrderLine_ID, C_InvoiceLine_ID, Reference, Info,additionalcommissionpercent,agencyfee,agencyfeeinstructure
            )
            VALUES
            (
              v_NextNo, v_C_CommissionAmt_ID, v_AD_Client_ID, v_AD_Org_ID,
               'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
              '0', v_C_Currency_ID, v_Amt, 0,
              v_Qty, -- Conversion done by Trigger
              v_C_OrderLine_ID, v_C_InvoiceLine_ID, v_Reference, v_Info,v_additionalcommissionpercent,v_agencyfee,v_agencyfeeinstructure
            )
            ;
           if (select commissionamt from C_CommissionDetail where C_CommissionDetail_id=v_NextNo)>0 then
                    v_count:=v_count + 1 ; 
           else
                    delete from C_CommissionDetail where C_CommissionDetail_id=v_NextNo;
           end if;
            v_linecount:=1;
          --
          -- DBMS_OUTPUT.PUT_LINE('  ' || v_Reference || ' - ' || v_Amt || ' - ' || v_Qty);
        END LOOP;
        CLOSE v_rc;
        if v_linecount=0 then
            delete from C_CommissionAmt where C_CommissionAmt_ID=v_C_CommissionAmt_ID;
        end if;
        v_linecount:=0;
        --
      END LOOP; -- For every Commission Line
    if v_count>0 then
        v_Message:='@CommissionRun@ = ' || v_DocumentNo || ' - ' || v_Name;
        PERFORM mlm_createdependentCommissions(v_C_CommissionRun_ID,to_date(v_EndDate));
    else
        select count(*) into v_count from C_CommissionAmt a,C_CommissionDetail d 
                        where d.C_CommissionAmt_id=a.C_CommissionAmt_id
                        and a.C_CommissionRun_id=v_C_CommissionRun_ID;
        if v_count=0 then
            delete from C_CommissionRun where C_CommissionRun_ID=v_C_CommissionRun_ID;
            RAISE NOTICE '%','Delete: ' || ' - ' || v_Name;
            v_Message:='@CommissionRun@ = 0';
        else
            v_Message:='@CommissionRun@ exists - No lines Created';
        end if;
    end if;
    ---- <<FINISH_PROCESS>>
     -- Call User Exit Function
    select  v_message||c_commission_process_userexit(v_C_CommissionRun_ID) into v_message;
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 1, v_Message);
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr;
  -- ROLLBACK;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr);
  RETURN;
END; $body$;

-- User Exit to c_commission_process
CREATE or replace FUNCTION c_commission_process_userexit(p_C_CommissionRun_ID varchar) RETURNS varchar
AS $_$
DECLARE
  BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_commissiondetail_trg() RETURNS trigger
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
    * Contributor(s): Openbravo SL, OpenZ
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
    * Contributions OpenZ, Stefan Zimmermann 2014
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * Update Commission Amount Line
    * Convert Amount to Commission Currrency
    */
  v_C_Currency_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_ConvDate TIMESTAMP;
  v_AmtMultiplier numeric;
  v_QtySubtract numeric;
  v_AmtSubtract numeric;
  v_QtyMultiplier numeric;
  v_IsPositiveOnly varchar;
  v_Result numeric;
  v_partner varchar;
  v_commissionline_id varchar;
  v_commission_id  varchar;
  v_product_category_id varchar;
  v_product_id varchar;
  v_bp_group_id varchar;
  v_bpartner_id varchar;
  v_salesregion_id varchar;
  v_commissionrun_id varchar;
  v_agencyfee numeric;
  v_iscommissionInPrice varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    select c.c_bpartner_id,a.c_commissionline_id,r.c_commissionrun_id
           into v_partner,v_commissionline_id,v_commissionrun_id  from c_commission c,c_commissionrun r,c_commissionamt a
           where r.c_commission_id=c.c_commission_id 
           and new.c_commissionamt_id=a.c_commissionamt_id and r.c_commissionrun_id=a.c_commissionrun_id;
  else
    select c.c_bpartner_id,a.c_commissionline_id,r.c_commissionrun_id
           into v_partner,v_commissionline_id,v_commissionrun_id  from c_commission c,c_commissionrun r,c_commissionamt a
           where r.c_commission_id=c.c_commission_id 
           and old.c_commissionamt_id=a.c_commissionamt_id and r.c_commissionrun_id=a.c_commissionrun_id;
    
  end if;
  IF(TG_OP = 'DELETE' or TG_OP = 'UPDATE') THEN
    if old.isstructurecommission='N' then
        -- Set Total Turnover on Emplaoyy
        update c_bpartner set salesvolume = coalesce(salesvolume,0)- coalesce(old.ConvertedAmt,0) where c_bpartner_id=v_partner;
        
        select c_commission_id,  coalesce(m_product_category_id,'') ,  coalesce(m_product_id,''),  coalesce(c_bp_group_id,''),
            coalesce(c_bpartner_id,'') , coalesce(c_salesregion_id,'') 
        into v_commission_id,  v_product_category_id ,  v_product_id,  v_bp_group_id,  v_bpartner_id ,  v_salesregion_id 
        from c_commissionline where c_commissionline_id=v_commissionline_id;
        
        update c_commissionline set ConvertedTurnover = ConvertedTurnover - coalesce(old.ConvertedAmt,0)  where 
            c_commission_id= v_commission_id and  coalesce(m_product_category_id,'') =v_product_category_id
            and coalesce(m_product_id,'')=v_product_id and   coalesce(c_bp_group_id,'')=v_bp_group_id and   
            coalesce(c_bpartner_id,'')=v_bpartner_id and   coalesce(c_salesregion_id,'')= v_salesregion_id;
    end if;
  END IF;
  IF(TG_OP = 'UPDATE' ) THEN
    -- DBMS_OUTPUT.PUT_LINE('C_CommissionDetail_Trg - Subtract');
    -- Subtract old Amount/Qty from Amount
    UPDATE C_CommissionAmt
      SET ConvertedAmt=ConvertedAmt - old.ConvertedAmt,
      ActualQty=ActualQty - old.ActualQty,
      commissionamt=commissionamt - old.CommissionAmt
    WHERE C_CommissionAmt_ID=old.C_CommissionAmt_ID;
    
    UPDATE C_CommissionRun
      SET GrandTotal=GrandTotal -  old.CommissionAmt
    WHERE C_CommissionRun_ID=v_commissionrun_id;
    
    
  END IF;
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    -- DBMS_OUTPUT.PUT_LINE('C_CommissionDetail_Trg - Get Info');
    -- Get Info From CommissionRun
    SELECT cr.StartDate,
      c.C_Currency_ID
    INTO v_ConvDate,
      v_C_Currency_ID
    FROM C_Commission c,
      C_CommissionRun cr,
      C_CommissionAmt ca
    WHERE ca.C_CommissionAmt_ID=new.C_CommissionAmt_ID
      AND cr.C_CommissionRun_ID=ca.C_CommissionRun_ID
      AND cr.C_Commission_ID=c.C_Commission_ID;
    -- On Shareovers the percent is given in the field new.additionalcommissionpercent.
    -- The Turnover neans that the Conmmistion is always on the  complete Value of the Orderline/Invoiceline
    if new.isshareofturnover='Y' then
        if new.c_orderline_id is not null then
            new.ActualAmt:=(select coalesce(linenetamt,linegrossamt) from c_orderline where c_orderline_id=new.c_orderline_id);
        end if;
        if new.c_invoiceline_id is not null then
            new.ActualAmt:=(select coalesce(linenetamt,linegrossamt) from c_invoiceline where c_invoiceline_id=new.c_invoiceline_id);
        end if;
        v_AmtMultiplier:=0;
    end if;
    -- Convert
    new.ConvertedAmt:=C_Currency_Convert(new.ActualAmt, new.C_Currency_ID, v_C_Currency_ID, v_ConvDate, 'S', new.AD_Client_ID, new.AD_Org_ID) ;
    -- Add new Amount/Qty to Amount
    -- DBMS_OUTPUT.PUT_LINE('C_CommissionDetail_Trg - Add');
    SELECT AmtSubtract,
      AmtMultiplier,
      QtySubtract,
      QtyMultiplier,
      IsPositiveOnly,
      iscommissioninprice
    INTO v_AmtSubtract,
      v_AmtMultiplier,
      v_QtySubtract,
      v_QtyMultiplier,
      v_IsPositiveOnly,
      v_iscommissionInPrice
    FROM C_CommissionLine
    WHERE C_CommissionLine_ID=(select C_CommissionLine_ID from c_commissionamt where c_commissionamt_id=new.C_CommissionAmt_ID);
    
    if v_iscommissionInPrice='Y' then
        v_Result :=((new.ConvertedAmt - v_AmtSubtract) * (v_AmtMultiplier+new.additionalcommissionpercent-coalesce(new.percentinstructure,0)))
                                                           /(100 + (v_AmtMultiplier+new.additionalcommissionpercent-coalesce(new.percentinstructure,0)));
    else
        v_Result :=(new.ConvertedAmt - v_AmtSubtract) * ((v_AmtMultiplier+new.additionalcommissionpercent-coalesce(new.percentinstructure,0))/100);
    end if;
    IF(v_IsPositiveOnly='Y' AND v_Result < 0) THEN
      v_Result:=0;
    END IF;
    IF coalesce(new.agencyfee,0)!=0  then
        v_Result :=v_Result + C_Currency_Convert(new.agencyfee, new.C_Currency_ID, v_C_Currency_ID, v_ConvDate, 'S', new.AD_Client_ID, new.AD_Org_ID) ;
    END IF;
    new.CommissionAmt:=v_Result;  
    new.actualqty:=v_AmtMultiplier;
    UPDATE C_CommissionAmt
      SET ConvertedAmt=ConvertedAmt + new.ConvertedAmt,
      commissionamt=commissionamt + new.CommissionAmt,
      ActualQty=(select count(*) from c_commissiondetail where C_CommissionAmt_ID=new.C_CommissionAmt_ID)
    WHERE C_CommissionAmt_ID=new.C_CommissionAmt_ID;
    
    UPDATE C_CommissionRun
      SET GrandTotal=GrandTotal + new.CommissionAmt
    WHERE C_CommissionRun_ID=v_commissionrun_id;
    
    
    if new.isstructurecommission='N' then
        -- Set Total Turnover on Emplaoyy
        update c_bpartner set salesvolume = coalesce(salesvolume,0) + coalesce(new.ConvertedAmt,0) where c_bpartner_id=v_partner;
        
        select c_commission_id,  coalesce(m_product_category_id,'') ,  coalesce(m_product_id,''),  coalesce(c_bp_group_id,''),
            coalesce(c_bpartner_id,'') , coalesce(c_salesregion_id,'') 
        into v_commission_id,  v_product_category_id ,  v_product_id,  v_bp_group_id,  v_bpartner_id ,  v_salesregion_id 
        from c_commissionline where c_commissionline_id=v_commissionline_id;
        
        update c_commissionline set ConvertedTurnover = ConvertedTurnover + coalesce(new.ConvertedAmt,0)  where 
            c_commission_id= v_commission_id and  coalesce(m_product_category_id,'') =v_product_category_id
            and coalesce(m_product_id,'')=v_product_id and   coalesce(c_bp_group_id,'')=v_bp_group_id and   
            coalesce(c_bpartner_id,'')=v_bpartner_id and   coalesce(c_salesregion_id,'')= v_salesregion_id;
    end if;
  END IF;
  -- Prevent Delete if Invoice exists
  IF TG_OP = 'DELETE' THEN 
    if (select count(*) from  c_commissionamt a,c_commissionrun r where r.c_commissionrun_id=a.c_commissionrun_id 
                      and a.c_commissionamt_id=old.c_commissionamt_id and r.c_invoice_id is not null)>0 then
     raise exception '%','@nodeletepossible@'||' Invoice exists';
    end if;
  ELSE
    if (select count(*) from  c_commissionamt a,c_commissionrun r where r.c_commissionrun_id=a.c_commissionrun_id 
                      and a.c_commissionamt_id=new.c_commissionamt_id and r.c_invoice_id is not null)>0 then
     raise exception '%','@nodeletepossible@'||' Invoice exists';
    end if;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;

CREATE OR REPLACE FUNCTION c_commissionamt_trg() RETURNS trigger
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
    * Contributor(s): Openbravo SL, OpenZ
    * Contributions are Copyright (C) 2001-2008 Openbravo, S.L.
    * Contributions OpenZ, 2014
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * Update Header GrandTotal
    * Convert Amount to Commission Currrency
    * Calculate Commission Amount
    */
  v_AmtSubtract NUMERIC;
  v_AmtMultiplier  NUMERIC;
  v_QtySubtract    NUMERIC;
  v_QtyMultiplier  NUMERIC;
  v_IsPositiveOnly CHAR(1) ;
  --
  v_Result NUMERIC;
  v_partner varchar;
  v_commission_id  varchar;
  v_product_category_id varchar;
  v_product_id varchar;
  v_bp_group_id varchar;
  v_bpartner_id varchar;
  v_salesregion_id varchar;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

  

  IF TG_OP = 'DELETE' THEN 
    if (select count(*) from c_commissionrun r where r.C_CommissionRun_ID=old.C_CommissionRun_ID
                        and r.c_invoice_id is not null)>0 then
     raise exception '%','@nodeletepossible@'||' Invoice exists';
    end if;
    delete from c_commissiondetail where c_commissionamt_id=old.c_commissionamt_id;
  ELSE
    if (select count(*) from c_commissionrun r where r.C_CommissionRun_ID=new.C_CommissionRun_ID
                        and r.c_invoice_id is not null)>0 then
     raise exception '%','@nodeletepossible@'||' Invoice exists';
    end if;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;

CREATE OR REPLACE FUNCTION c_commissionrun_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 OpenZ Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF TG_OP = 'DELETE' THEN 
    if old.c_invoice_id is not null then
     raise exception '%','@nodeletepossible@'||' Invoice exists';
    end if;
    delete from  c_commissiondetail 
    where c_commissionamt_id in (select c_commissionamt_id from c_commissionamt where c_commissionrun_id=old.c_commissionrun_id);
    delete from c_commissionamt where c_commissionrun_id=old.c_commissionrun_id;
  ELSE
    if (new.c_invoice_id is not null) then
     raise exception '%','@nodeletepossible@'||' Invoice exists';
    end if;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('c_commissionrun_trg','c_commissionrun');

CREATE TRIGGER c_commissionrun_trg
  BEFORE  DELETE
  ON c_commissionrun
  FOR EACH ROW
  EXECUTE PROCEDURE c_commissionrun_trg();

CREATE OR REPLACE FUNCTION c_commissionrun_process(p_pinstance_id character varying) RETURNS void
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
* Contributor(s): Martin Hinrichs, 2011-12-20, info@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Zimmermann-Software
*
****************************************************************************************************************************************************/
 -- Logistice
  v_ResultStr     VARCHAR(2000) := ''; --OBTG:VARCHAR2--
  v_Message     VARCHAR(2000) := ''; --OBTG:VARCHAR2--
  v_Record_ID      VARCHAR(32); --OBTG:varchar2--
  v_Result      NUMERIC(10) := 1; -- Success
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
  Cur_Parameter RECORD;
  -- Parameter Variables

  CUR_ComRun RECORD;
  --
  v_C_DocType_ID     VARCHAR(32); --OBTG:varchar2--
  v_C_Invoice_ID     VARCHAR(32); --OBTG:varchar2--
  v_NextNo      VARCHAR(32); --OBTG:VARCHAR2--
  v_DocumentNo     VARCHAR(40); --OBTG:VARCHAR2--
  v_SalesRep_ID     VARCHAR(32); --OBTG:varchar2--
  --
  v_C_BPartner_ID     VARCHAR(32); --OBTG:varchar2--
  v_C_BPartner_Location_ID  VARCHAR(32); --OBTG:varchar2--

  v_C_COMMISSION_Orgid      VARCHAR(32);  -- 2011-12-20
  v_AD_PINSTANCE_CreatedBy  VARCHAR(32);  -- 2011-12-20
  v_now                     TIMESTAMP;     -- 2011-12-20

  v_partnername VARCHAR(100); --OBTG:VARCHAR2--
  v_C_PaymentTerm_ID    VARCHAR(32); --OBTG:varchar2--
  v_C_Currency_ID     VARCHAR(32); --OBTG:varchar2--
  v_PaymentRule     VARCHAR(60);
  v_M_PriceList_ID    VARCHAR(32); --OBTG:varchar2--
  v_POReference     VARCHAR(20); --OBTG:varchar2--
  v_Product_ID     VARCHAR(32); --OBTG:varchar2--
  v_Tax_ID      VARCHAR(32); --OBTG:varchar2--
  v_UOM_ID      VARCHAR(32); --OBTG:varchar2--
  v_IsDiscountPrinted    CHAR(1);
  v_CommissionName VARCHAR(60);
  v_userid varchar;
  FINISH_PROCESS BOOLEAN := false;
BEGIN
  --  Update AD_PInstance
  RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID;
  v_ResultStr := 'PInstanceNotFound';
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL);
      -- p_pinstance_id varchar, p_ad_user_id varchar, p_isprocessing char, p_result numeric, p_message varchar

  SELECT Updated, updatedBy INTO v_now, v_AD_PINSTANCE_CreatedBy
  FROM ad_pinstance pi
  WHERE pi.AD_PInstance_ID = p_PInstance_ID;

  BEGIN --BODY
    -- Get Parameters
    v_ResultStr := 'ReadingParameters';
    FOR Cur_Parameter IN (
      SELECT
        i.Record_ID, i.UpdatedBy,
        p.ParameterName, p.P_String, p.P_Number, p.P_Date
      FROM AD_PINSTANCE i
        LEFT JOIN AD_PINSTANCE_PARA p ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo)
    LOOP
      v_Record_ID := Cur_Parameter.Record_ID;
      -- IF (Cur_Parameter.ParameterName = 'xx') THEN
      --  xx := Cur_Parameter.P_String;
      --  DBMS_OUTPUT.PUT_LINE('  xx=' || xx);
      -- ELSE
      --  DBMS_OUTPUT.PUT_LINE('*** Unknown Parameter=' || Cur_Parameter.ParameterName);
      --  END IF;
    END LOOP; -- Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID;

    FOR CUR_ComRun IN (
     SELECT *
     FROM C_COMMISSIONRUN
     WHERE C_CommissionRun_ID = v_Record_ID)
    LOOP

    -- Create Header
    v_ResultStr := 'GetDocTypeInfo';
    v_C_DocType_ID := Ad_Get_DocType(CUR_ComRun.AD_Client_ID,CUR_ComRun.AD_Org_ID, 'API');
    v_C_COMMISSION_Orgid := CUR_ComRun.AD_Org_ID; -- 2011-12-20

    DECLARE Cur_Data RECORD;
      BEGIN
        FOR Cur_Data IN (
          SELECT com.Name, com.C_Currency_ID, com.C_BPartner_ID, pl.C_BPartner_Location_ID,
            PaymentRulePO, PO_PaymentTerm_ID, PO_PriceList_ID,
            POReference, IsDiscountPrinted, p.SalesRep_ID, com.M_Product_ID, C_UOM_ID, p.name as bpartnername
         FROM  C_BPARTNER p, C_COMMISSION com
           LEFT JOIN C_BPARTNER_LOCATION pl ON com.C_BPartner_ID = pl.C_BPartner_ID
           LEFT JOIN M_Product prd ON com.M_Product_ID = prd.M_Product_ID
         WHERE com.C_Commission_ID = CUR_ComRun.C_Commission_ID
           AND com.C_BPartner_ID = p.C_BPartner_ID)
        LOOP
          v_CommissionName:=Cur_Data.Name;
          v_C_Currency_ID:=Cur_Data.C_Currency_ID;
          v_C_BPartner_ID:=Cur_Data.C_BPartner_ID;
          if (select count(*) from ad_user where c_bpartner_id=v_C_BPartner_ID)=1 then
            select ad_user_id into v_userid from ad_user where c_bpartner_id=v_C_BPartner_ID;
          end if;
          v_C_BPartner_Location_ID:=Cur_Data.C_BPartner_Location_ID;
          v_PaymentRule:=Cur_Data.PaymentRulePO;
          v_C_PaymentTerm_ID:=Cur_Data.PO_PaymentTerm_ID;
          v_M_PriceList_ID:=Cur_Data.PO_PriceList_ID;
          v_POReference:=Cur_Data.POReference;
          v_IsDiscountPrinted:=Cur_Data.IsDiscountPrinted;
          v_SalesRep_ID:=Cur_Data.SalesRep_ID;
          v_Product_ID:=Cur_Data.M_Product_ID;
          v_UOM_ID:=Cur_Data.C_UOM_ID;
          v_partnername:=Cur_Data.bpartnername;
          EXIT;
       END LOOP;
      END;
      --
      IF (v_PaymentRule IS NULL) THEN
       v_PaymentRule := 'P';
      END IF;
      IF (v_IsDiscountPrinted IS NULL) THEN
       v_IsDiscountPrinted := 'N';
      END IF;
      IF (v_Product_ID IS NULL) THEN
         RAISE EXCEPTION '%', '@Commission@ '||v_CommissionName||' @InvoicedProductNotdefined@'; --OBTG:-20000--
      END IF;
      IF (v_C_BPartner_Location_ID IS NULL) THEN
         RAISE EXCEPTION '%', '@ThebusinessPartner@ '||v_partnername||' @ShiptoNotdefined@'; --OBTG:-20000--
      END IF;
      IF (v_C_PaymentTerm_ID IS NULL) THEN
         RAISE EXCEPTION '%', '@ThebusinessPartner@ '||v_partnername||' @PaymenttermNotdefined@'; --OBTG:-20000--
      END IF;
      IF (v_M_PriceList_ID IS NULL) THEN
       RAISE EXCEPTION '%', '@ThebusinessPartner@ '||v_partnername||' @PricelistNotdefined@'; --OBTG:-20000--
      END IF;

      IF (NOT FINISH_PROCESS) THEN
      --
        v_ResultStr := 'GetDocSequenceInfo';
        SELECT * INTO  v_C_Invoice_ID FROM Ad_Sequence_Next('C_Invoice', CUR_ComRun.AD_Client_ID);

        SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(v_C_DocType_ID, CUR_ComRun.AD_Org_ID, 'Y');
        IF (v_DocumentNo IS NULL) THEN
          SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Invoice', CUR_ComRun.AD_Org_ID, 'Y');
        END IF;
        IF (v_DocumentNo IS NULL) THEN
         v_DocumentNo := CUR_ComRun.DocumentNo;
        END IF;
        --
        RAISE NOTICE '%','  Invoice_ID=' || v_C_Invoice_ID || ' DocumentNo=' || v_DocumentNo;
        --
        v_ResultStr := 'InsertInvoice ' || v_C_Invoice_ID;
        INSERT INTO C_INVOICE
         (C_Invoice_ID, C_Order_ID,
          AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated, UpdatedBy,
          IsSOTrx, DocumentNo, DocStatus, DocAction, Processing, Processed,
          C_DocType_ID, C_DocTypeTarget_ID, Description,
          SalesRep_ID,
          DateInvoiced, DatePrinted, IsPrinted, DateAcct, TaxDate,
          C_PaymentTerm_ID, C_BPartner_ID, C_BPartner_Location_ID, AD_User_ID,
          POReference, DateOrdered, IsDiscountPrinted,
          C_Currency_ID, PaymentRule, C_Charge_ID, ChargeAmt,
          TotalLines, GrandTotal,
          M_PriceList_ID, C_Campaign_ID, C_Project_ID, C_Activity_ID)
        VALUES
         (v_C_Invoice_ID, NULL,
         -- CUR_ComRun.AD_Client_ID, CUR_ComRun.AD_Org_ID, 'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
         CUR_ComRun.AD_Client_ID, CUR_ComRun.AD_Org_ID, 'Y', v_now, v_AD_PINSTANCE_CreatedBy, TO_DATE(NOW()), '0',
         'N', v_DocumentNo, 'DR', 'CO', 'N', 'N',
         v_C_DocType_ID, v_C_DocType_ID, CUR_ComRun.Description,
         v_SalesRep_ID,
         trunc(CUR_ComRun.Updated), NULL, 'N', trunc(CUR_ComRun.Updated), trunc(CUR_ComRun.Updated), -- DateInvoiced=DateAcct
         v_C_PaymentTerm_ID, v_C_BPartner_ID, v_C_BPartner_Location_ID, v_userid,
         v_POReference, trunc(CUR_ComRun.Updated), v_IsDiscountPrinted,
         v_C_Currency_ID, v_PaymentRule, NULL, 0,
         0, 0,
         v_M_PriceList_ID, NULL, NULL, NULL);

        -- One line with Total (TODO: Tax, UOM)
        -- v_Tax_ID := C_Gettax (v_Product_ID,CUR_ComRun.Updated,CUR_ComRun.AD_Org_ID,NULL,v_C_BPartner_Location_ID,v_C_BPartner_Location_ID,NULL,'N');
        v_Tax_ID := zsfi_GetTax(v_C_BPartner_Location_ID, v_Product_ID, v_C_COMMISSION_Orgid); -- v_bplocid, v_product_id, v_orgid);

        v_ResultStr := 'InsertLine';
        SELECT * INTO  v_NextNo FROM Ad_Sequence_Next('C_InvoiceLine', CUR_ComRun.AD_Client_ID);
        INSERT INTO C_INVOICELINE
         (C_InvoiceLine_ID,
         AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated, UpdatedBy,
         C_Invoice_ID, C_OrderLine_ID, M_InOutLine_ID,
         Line, Description,
         M_Product_ID, QtyInvoiced, PriceList, PriceActual, PriceLimit, LineNetAmt,
         C_Charge_ID, ChargeAmt, C_UOM_ID, C_Tax_ID
         --MODIFIED BY F.IRIAZABAL
         , QUANTITYORDER, M_PRODUCT_UOM_ID,
         PriceStd, M_Offer_ID)
        VALUES
         (v_NextNo,
         -- CUR_ComRun.AD_Client_ID, CUR_ComRun.AD_Org_ID, 'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()), '0',
         CUR_ComRun.AD_Client_ID, CUR_ComRun.AD_Org_ID, 'Y', TO_DATE(NOW()), v_AD_PINSTANCE_CreatedBy, TO_DATE(NOW()), '0',
         v_C_Invoice_ID, NULL, NULL,
         10, NULL,
         v_Product_ID, 1, CUR_ComRun.GrandTotal, CUR_ComRun.GrandTotal, CUR_ComRun.GrandTotal, CUR_ComRun.GrandTotal,
         NULL, 0, v_UOM_ID, v_Tax_ID
         --MODIFIED BY F.IRIAZABAL
         , NULL, NULL,
         CUR_ComRun.GrandTotal, NULL);

        UPDATE C_CommissionRun
          SET C_Invoice_ID = v_C_Invoice_ID
          WHERE C_CommissionRun_ID = v_Record_ID;
        if c_getconfigoption('activatepoinvoiceautomatically', CUR_ComRun.AD_Org_ID)  ='Y' then
            PERFORM c_invoice_post(null,v_C_Invoice_ID);
        end if;
      END IF;--FINISH_PROCESS
      v_Message := '@InvoiceDocumentno@ ' || v_DocumentNo;
    END LOOP;--FINISH_PROCESS


    -- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message);
      RETURN;

  END; --BODY
  EXCEPTION
  WHEN OTHERS THEN
    v_ResultStr:= '@ERROR=' || SQLERRM;
    RAISE NOTICE '%',v_ResultStr;
    -- ROLLBACK;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr);

  RETURN;
END; $_$;

CREATE OR REPLACE FUNCTION mlm_createdependentCommissions(v_CommissionRunId character varying, p_enddate timestamp without time zone)
  RETURNS void AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
 */
  -- Lines
  v_cur RECORD;
  v_cur_line RECORD;
  v_curMLM RECORD;
  v_cur_insline RECORD;
  v_salesrep varchar;
  -- Internal vars
  v_count numeric;
  -- New Group ID
  v_uid character varying;
  v_Name varchar;
  v_C_CommissionRun_ID varchar;
  v_DocumentNo varchar;
  v_AD_Org_ID varchar;
  v_currency varchar;
  v_AD_Client_ID varchar:='C726FEC915A54A0995C568555DA5BB3C';
  v_C_CommissionAmt_ID varchar;
  v_commissionlineId varchar;
  v_docbasetype varchar;
  v_isnew varchar:='N';
  v_commission varchar;
  v_percentinstructure numeric;
  v_tempstructure numeric;
  v_initstructure numeric;
  v_shareofturnoverpartner varchar;
  v_shareofturnovercommission varchar;
  v_shareofturnovercommissionline varchar;
  v_shareofturnoverpercent numeric;
  v_highestagencyfee numeric;
BEGIN
  select c_commission.c_bpartner_id,c_commission.ad_org_id ,c_commission.docbasistype,shareofturnoverpartner,shareofturnoverpercent
         into v_salesrep,v_AD_Org_ID, v_docbasetype,v_shareofturnoverpartner,v_shareofturnoverpercent
         from c_commission,C_CommissionRun where C_CommissionRun.c_commission_id=c_commission.c_commission_id  
         and C_CommissionRun.C_CommissionRun_id=v_CommissionRunId;
  --RAISE NOTICE '%','createdependentCommissions:' ||v_salesrep;
  -- SHARE of TurnOver
  select c_commission_id into v_shareofturnovercommission from c_commission where c_bpartner_id=v_shareofturnoverpartner and ad_org_id=v_AD_Org_ID;
  if v_shareofturnovercommission is null then
    for v_curMLM in (select p_upperNode from ad_treeGetUpperHierarchy(v_salesrep,'A4503DE852E54D0496D4C066283D121A'))
    LOOP
        select c_commission_id into v_shareofturnovercommission from c_commission where c_bpartner_id=v_curMLM.p_upperNode and ad_org_id=v_AD_Org_ID;
        select shareofturnoverpartner,shareofturnoverpercent into v_shareofturnoverpartner,v_shareofturnoverpercent from c_commission  
               where c_commission_id=v_shareofturnovercommission;
        if v_shareofturnoverpartner is null then 
            v_shareofturnovercommission:=null; 
            v_shareofturnoverpartner:=null;
            v_shareofturnoverpercent:=0;
        else
            select c_commission_id into v_shareofturnovercommission from c_commission where c_bpartner_id=v_shareofturnoverpartner and ad_org_id=v_AD_Org_ID;
            exit;
        end if;
    END LOOP;
  end if;
  --raise notice '%','#############################SOTC'||coalesce(v_shareofturnoverpartner,'null')||'#'||coalesce(v_shareofturnovercommission,'null')||v_AD_Org_ID||'#'||v_docbasetype;
  for v_cur in (select * from C_CommissionAmt where C_CommissionRun_ID=v_CommissionRunId)
  LOOP   
      for v_cur_line in (select * from C_CommissionDetail where C_CommissionAmt_id=v_cur.C_CommissionAmt_id and isstructurecalculated='N')
      LOOP
        -- CALCULATE AGENCY FEES , if IN Structure
        if v_cur_line.agencyfeeinstructure='Y'  then
            -- Select the hihgest Rate in the Commission
            for v_curMLM in (select p_upperNode from ad_treeGetUpperHierarchy(v_salesrep,'A4503DE852E54D0496D4C066283D121A'))
            LOOP
            -- Get the appropriate Line in the actual structure
            select b.AmtMultiplier,a.c_commissionline_id,a.AmtMultiplier into v_initstructure,v_commissionlineId,v_tempstructure
                                from c_commissionline a,c_commissionline b 
                                where b.c_commissionline_id=v_cur.c_commissionline_id
                                and coalesce(a.m_product_category_id,'')=coalesce(b.m_product_category_id,'') 
                                and coalesce(a.m_product_id,'') =coalesce(b.m_product_id ,'') 
                                and coalesce(a.c_bp_group_id,'') =coalesce(b.c_bp_group_id,'') 
                                and coalesce(a.c_bpartner_id,'') =coalesce(b.c_bpartner_id ,'') 
                                and coalesce(a.c_salesregion_id,'') =coalesce(b.c_salesregion_id ,'') 
                                and a.ConvertedTurnover>=coalesce(a.salesvolumefrom,0) 
                                and a.c_commission_id = (select c_commission_id from c_commission where c_bpartner_id = v_curMLM.p_upperNode
                                                                and  ad_org_id = v_AD_Org_ID and docbasistype=v_docbasetype limit 1)
                                order by a.salesvolumefrom;
            END LOOP;
            if (select count(*) from ad_treeGetUpperHierarchy(v_salesrep,'A4503DE852E54D0496D4C066283D121A')) >0  then
                -- Multiply the Original Agency Fee with the Part of actual (Initial) Commission
                v_highestagencyfee:=v_tempstructure;
                if (select count(*) from c_commissionDetail where c_orderline_id=v_cur_line.c_orderline_id)=1 then
                    update c_commissionDetail set agencyfee=round(((agencyfee/v_highestagencyfee) * v_initstructure),2) where C_CommissionDetail_id=v_cur_line.C_CommissionDetail_id;           
                end if;
            end if;
        end if;
        -- CALCULATE SHARE of TURNOVER (Is not applied to Agency Fees)
        if v_shareofturnovercommission is not null and v_cur_line.agencyfee=0 then
            select count(*) into v_count from c_commissionline where c_commission_id=v_shareofturnovercommission and isshareofturnover='Y';
            if v_count=0 then
                insert into c_commissionline(c_commissionline_id,ad_client_id,ad_org_id,updatedby,createdby,c_commission_id,line,description,amtsubtract, amtmultiplier, qtysubtract , qtymultiplier,isshareofturnover)
                values (get_uuid(),v_AD_Client_ID,v_AD_Org_ID,'0','0',v_shareofturnovercommission,999,'Umsatzbeteiligungen',0,0,0,0,'Y');
            end if;
            select c_commissionline_id into v_shareofturnovercommissionline from c_commissionline where c_commission_id=v_shareofturnovercommission and isshareofturnover='Y';
            select C_CommissionRun_ID into v_C_CommissionRun_ID from C_CommissionRun where c_invoice_id is null and C_Commission_ID=v_shareofturnovercommission;
            if v_C_CommissionRun_ID is null then
                select c.ISO_Code,co.name into v_currency,v_name from c_commission co ,c_currency c 
                    where co.c_bpartner_id=v_shareofturnoverpartner and co.ad_org_id=v_AD_Org_ID and co.c_currency_id=c.c_currency_id;
                v_Name:=v_Name ||' - ' ||(select name from c_bpartner where c_bpartner_id=v_shareofturnoverpartner)||' - '|| coalesce(TO_CHAR(p_enddate),to_char(trunc(now())))|| ' - ' || v_Currency;
                SELECT * INTO  v_C_CommissionRun_ID FROM AD_Sequence_Next('C_CommissionRun', v_AD_Client_ID);
                SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('DocumentNo_C_CommissionRun', v_AD_Org_ID, 'Y');
                RAISE NOTICE '%','SHARE----------------------------------createdependentCommissionsCreate: ' || v_DocumentNo || ' - ' || v_Name;
                INSERT
                INTO C_CommissionRun
                (
                    C_CommissionRun_ID, C_Commission_ID, AD_Client_ID, AD_Org_ID,
                    IsActive, Created, CreatedBy, Updated,
                    UpdatedBy, DocumentNo, Description, StartDate,
                    GrandTotal, Processing, Processed
                )
                VALUES
                (
                    v_C_CommissionRun_ID, v_shareofturnovercommission, v_AD_Client_ID, v_AD_Org_ID,
                    'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
                    '0', v_DocumentNo, v_Name, TO_DATE(NOW()),
                    0, 'N', 'N'
                );
                -- The Lines
                FOR v_cur_insline IN (SELECT *  FROM C_CommissionLine  WHERE C_Commission_ID=v_shareofturnovercommission AND IsActive='Y')
                LOOP
                            -- For every Commission Line create empty Amt line (updated by Detail)
                            SELECT * INTO  v_C_CommissionAmt_ID FROM AD_Sequence_Next('C_CommissionAmt', v_AD_Client_ID);
                            INSERT
                            INTO C_CommissionAmt
                            (
                                C_CommissionAmt_ID, C_CommissionRun_ID, C_CommissionLine_ID, AD_Client_ID,
                                AD_Org_ID, IsActive, Created, CreatedBy, Updated,
                                UpdatedBy, ConvertedAmt, ActualQty, CommissionAmt
                            )
                            VALUES
                            (
                                v_C_CommissionAmt_ID, v_C_CommissionRun_ID, v_cur_insline.C_CommissionLine_ID, v_AD_Client_ID,
                                v_AD_Org_ID, 'Y', TO_DATE(NOW()), '0',
                                TO_DATE(NOW()), '0', 0, 0,
                                0
                            ); -- Calculation done by Trigger
                END LOOP;
            end if; -- v_C_CommissionRun_ID is null
            UPDATE C_Commission SET DateLastRun=TO_DATE(NOW())  WHERE C_Commission_ID=v_shareofturnovercommission ;
            FOR v_cur_insline IN (SELECT *  FROM C_CommissionAmt where C_CommissionRun_ID=v_C_CommissionRun_ID and c_commissionline_id=v_shareofturnovercommissionline
                                  and not exists (select 0 from C_CommissionDetail d where  d.C_CommissionAmt_ID=C_CommissionAmt.C_CommissionAmt_id and
                                                    (d.C_OrderLine_ID=v_cur_line.C_OrderLine_ID or d.C_InvoiceLine_ID=v_cur_line.C_InvoiceLine_ID)))
            LOOP
                RAISE NOTICE '%','Creating SHARe of Turnover Commission for:' || v_shareofturnovercommissionline;
                v_uid:=get_uuid();
                INSERT
                INTO C_CommissionDetail
                (C_CommissionDetail_ID, C_CommissionAmt_ID, AD_Client_ID, AD_Org_ID,
                    IsActive, Created, CreatedBy, Updated,
                    UpdatedBy, C_Currency_ID, ActualAmt, ConvertedAmt,
                    ActualQty,
                    C_OrderLine_ID, C_InvoiceLine_ID, Reference, Info,additionalcommissionpercent,isstructurecommission ,isshareofturnover)
                VALUES
                ( v_uid, v_cur_insline.C_CommissionAmt_ID, v_AD_Client_ID, v_AD_Org_ID,
                    'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
                    '0', v_cur_line.C_Currency_ID, v_cur_line.ActualAmt, 0,
                    v_cur_line.ActualQty, -- Conversion done by Trigger
                    v_cur_line.C_OrderLine_ID, v_cur_line.C_InvoiceLine_ID, v_cur_line.Reference, v_cur_line.Info,coalesce(v_shareofturnoverpercent,0),'Y','Y') ;
                if (select commissionamt from C_CommissionDetail where C_CommissionDetail_id=v_uid)=0 then
                    delete from C_CommissionDetail where C_CommissionDetail_id=v_uid;
                end if;
            END LOOP; 
        end if; -- v_shareofturnovercommission is not null 
        v_percentinstructure:=0;
        for v_curMLM in (select p_upperNode from ad_treeGetUpperHierarchy(v_salesrep,'A4503DE852E54D0496D4C066283D121A'))
        LOOP
          -- Get the appropriate Line in the actual structure
          select b.AmtMultiplier,a.c_commissionline_id,a.AmtMultiplier into v_initstructure,v_commissionlineId,v_tempstructure
                               from c_commissionline a,c_commissionline b 
                               where b.c_commissionline_id=v_cur.c_commissionline_id
                               and coalesce(a.m_product_category_id,'')=coalesce(b.m_product_category_id,'') 
                               and coalesce(a.m_product_id,'') =coalesce(b.m_product_id ,'') 
                               and coalesce(a.c_bp_group_id,'') =coalesce(b.c_bp_group_id,'') 
                               and coalesce(a.c_bpartner_id,'') =coalesce(b.c_bpartner_id ,'') 
                               and coalesce(a.c_salesregion_id,'') =coalesce(b.c_salesregion_id ,'') 
                               and a.ConvertedTurnover>=coalesce(a.salesvolumefrom,0) 
                               and a.c_commission_id = (select c_commission_id from c_commission where c_bpartner_id = v_curMLM.p_upperNode
                                                               and  ad_org_id = v_AD_Org_ID and docbasistype=v_docbasetype limit 1)
                               order by a.salesvolumefrom desc;
          if v_commissionlineId is not null then
            if v_percentinstructure=0 then
                v_percentinstructure:=v_initstructure;
            end if;
            -- Check, If Upper Commission RUN exists
            select co.c_commission_id,c.ISO_Code,co.name into v_commission,v_currency,v_name from c_commission co ,c_currency c 
                    where co.c_bpartner_id=v_curMLM.p_upperNode and co.ad_org_id=v_AD_Org_ID and co.c_currency_id=c.c_currency_id;
            select C_CommissionRun_ID into v_C_CommissionRun_ID from C_CommissionRun where c_invoice_id is null and C_Commission_ID=v_commission;
            if v_C_CommissionRun_ID is null then
                -- Create new Commission
                v_isnew:='Y';
                v_Name:=v_Name ||' - ' ||(select name from c_bpartner where c_bpartner_id=v_curMLM.p_upperNode)||' - '|| coalesce(TO_CHAR(p_enddate),to_char(trunc(now()))) || ' - ' || v_Currency;
                SELECT * INTO  v_C_CommissionRun_ID FROM AD_Sequence_Next('C_CommissionRun', v_AD_Client_ID);
                SELECT * INTO  v_DocumentNo FROM AD_Sequence_Doc('DocumentNo_C_CommissionRun', v_AD_Org_ID, 'Y');
                RAISE NOTICE '%','CreatedependentCommissions-Create: ' || v_DocumentNo || ' - ' || v_Name;
                INSERT
                INTO C_CommissionRun
                (
                    C_CommissionRun_ID, C_Commission_ID, AD_Client_ID, AD_Org_ID,
                    IsActive, Created, CreatedBy, Updated,
                    UpdatedBy, DocumentNo, Description, StartDate,
                    GrandTotal, Processing, Processed
                )
                VALUES
                (
                    v_C_CommissionRun_ID, v_commission, v_AD_Client_ID, v_AD_Org_ID,
                    'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
                    '0', v_DocumentNo, v_Name, TO_DATE(NOW()),
                    0, 'N', 'N'
                );
            end if;
            select C_CommissionAmt_ID into v_C_CommissionAmt_ID from C_CommissionAmt where C_CommissionRun_id=v_C_CommissionRun_ID
                   and c_commissionline_id=v_commissionlineId;
            if v_C_CommissionAmt_ID is null then 
                -- Inserting  Lines
                FOR v_cur_insline IN (SELECT *  FROM C_CommissionLine  WHERE C_CommissionLine_id=v_commissionlineId)
                LOOP
                    -- For every Commission Line create empty Amt line (updated by Detail)
                    SELECT * INTO  v_C_CommissionAmt_ID FROM AD_Sequence_Next('C_CommissionAmt', v_AD_Client_ID);
                    INSERT
                    INTO C_CommissionAmt
                    (
                        C_CommissionAmt_ID, C_CommissionRun_ID, C_CommissionLine_ID, AD_Client_ID,
                        AD_Org_ID, IsActive, Created, CreatedBy, Updated,
                        UpdatedBy, ConvertedAmt, ActualQty, CommissionAmt
                    )
                    VALUES
                    (
                        v_C_CommissionAmt_ID, v_C_CommissionRun_ID, v_cur_insline.C_CommissionLine_ID, v_AD_Client_ID,
                        v_AD_Org_ID, 'Y', TO_DATE(NOW()), '0',
                        TO_DATE(NOW()), '0', 0, 0,
                        0
                    ); -- Calculation done by Trigger
                END LOOP;
            end if;    -- v_C_CommissionAmt_ID is null
            
            UPDATE C_Commission SET DateLastRun=TO_DATE(NOW())  WHERE C_Commission_ID=v_commission;
            RAISE NOTICE '%','Creating Structure Commission for:' || v_percentinstructure||'-'||v_commissionlineId;
            v_uid:=get_uuid();
            if (select count(*) from C_CommissionDetail where C_CommissionAmt_ID=v_C_CommissionAmt_ID and 
                                (C_OrderLine_ID=v_cur_line.C_OrderLine_ID or C_InvoiceLine_ID=v_cur_line.C_InvoiceLine_ID))=0 
            then
                INSERT
                    INTO C_CommissionDetail
                    (C_CommissionDetail_ID, C_CommissionAmt_ID, AD_Client_ID, AD_Org_ID,
                        IsActive, Created, CreatedBy, Updated,
                        UpdatedBy, C_Currency_ID, ActualAmt, ConvertedAmt,
                        ActualQty,
                        C_OrderLine_ID, C_InvoiceLine_ID, Reference, Info,percentinstructure,isstructurecommission,agencyfee,agencyfeeinstructure )
                    VALUES
                    ( v_uid, v_C_CommissionAmt_ID, v_AD_Client_ID, v_AD_Org_ID,
                        'Y', TO_DATE(NOW()), '0', TO_DATE(NOW()),
                        '0', v_cur_line.C_Currency_ID, v_cur_line.ActualAmt, 0,
                        v_cur_line.ActualQty, -- Conversion done by Trigger
                        v_cur_line.C_OrderLine_ID, v_cur_line.C_InvoiceLine_ID, v_cur_line.Reference, v_cur_line.Info,v_percentinstructure,'Y',
                        case when  v_cur_line.agencyfeeinstructure = 'Y' then round(((v_cur_line.agencyfee/v_highestagencyfee) * (v_tempstructure-v_percentinstructure)),2) else 0 end,
                        v_cur_line.agencyfeeinstructure) ;
                if (select commissionamt from C_CommissionDetail where C_CommissionDetail_id=v_uid)=0 then
                    delete from C_CommissionDetail where C_CommissionDetail_id=v_uid;
                end if;
            end if;
          end if; -- v_commissionlineId is not null 
          v_percentinstructure:=v_tempstructure;
        END LOOP; -- -- curMLM
        if  v_isnew='Y' and 
            (select count(*) from C_CommissionDetail d,c_commissionamt a  where a.c_commissionamt_id=d.c_commissionamt_id 
                    and a.C_CommissionRun_ID=v_C_CommissionRun_Id)=0
        then
          delete from C_CommissionRun where C_CommissionRun_ID=v_C_CommissionRun_ID;
          RAISE NOTICE '%','No lines Created - Delete: ' || v_DocumentNo || ' - ' || v_Name;
        end if;
        update C_CommissionDetail set isstructurecalculated='Y' where C_CommissionDetail_id=v_cur_line.C_CommissionDetail_id;
      END LOOP; -- v_cur_line
  END LOOP; -- v_cur
  RETURN;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION c_commissionline_trg() RETURNS trigger
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
 v_turn numeric;       
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;
 
 IF TG_OP = 'INSERT' THEN
    select max(ConvertedTurnover) into v_turn from c_commissionline where c_commission_id=new.c_commission_id 
           and coalesce(new.m_product_category_id,'')=coalesce(m_product_category_id,'') 
                               and coalesce(new.m_product_id,'') =coalesce(m_product_id ,'') 
                               and coalesce(new.c_bp_group_id,'') =coalesce(c_bp_group_id,'') 
                               and coalesce(new.c_bpartner_id,'') =coalesce(c_bpartner_id ,'') 
                               and coalesce(new.c_salesregion_id,'') =coalesce(c_salesregion_id ,'') ;
    if v_turn is not null then
        new.ConvertedTurnover:=v_turn;
    end if;
 END IF;
 IF TG_OP = 'UPDATE' THEN
    IF new.ConvertedTurnover!=0 then
        if coalesce(new.m_product_category_id,'')!=coalesce(old.m_product_category_id,'') 
           or coalesce(new.m_product_id,'') !=coalesce(old.m_product_id ,'') 
           or coalesce(new.c_bp_group_id,'') !=coalesce(old.c_bp_group_id,'') 
           or coalesce(new.c_bpartner_id,'') !=coalesce(old.c_bpartner_id ,'') 
           or coalesce(new.c_salesregion_id,'') !=coalesce(old.c_salesregion_id ,'') 
        then
            RAISE exception '%', 'Commission has active Turnover. Cannot change Items';
        end if;
    end if;
 END IF;
-- Updating
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END ; $_$;

select zsse_DropTrigger ('c_commissionline_trg','c_commissionline');

CREATE TRIGGER c_commissionline_trg
  BEFORE INSERT OR UPDATE
  ON c_commissionline FOR EACH ROW
  EXECUTE PROCEDURE c_commissionline_trg();
  
  
  
  
  
  
  
  
  
  

  
